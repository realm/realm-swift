////////////////////////////////////////////////////////////////////////////
//
// Copyright 2014 Realm Inc.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//
////////////////////////////////////////////////////////////////////////////

#import "RLMRealm_Private.hpp"
#import "RLMArray_Private.hpp"
#import "RLMSchema_Private.h"
#import "RLMObjectSchema_Private.hpp"
#import "RLMObject_Private.h"
#import "RLMProperty_Private.h"
#import "RLMAccessor.h"
#import "RLMQueryUtil.hpp"
#import "RLMUtil.hpp"

#import <objc/runtime.h>

// get the table used to store object of objectClass
inline tightdb::TableRef RLMTableForObjectClass(RLMRealm *realm,
                                                NSString *className,
                                                bool &created) {
    NSString *tableName = realm.schema.tableNamesForClass[className];
    return realm.group->get_table(tableName.UTF8String, created);
}
inline tightdb::TableRef RLMTableForObjectClass(RLMRealm *realm,
                                                NSString *className) {
    NSString *tableName = realm.schema.tableNamesForClass[className];
    return realm.group->get_table(tableName.UTF8String);
}


void RLMVerifyAndAlignColumns(RLMObjectSchema *tableSchema, RLMObjectSchema *objectSchema) {
    // FIXME - this method should calculate all mismatched columns, and missing/extra columns, and include
    //         all of this information in a single exception
    // FIXME - verify property attributes

    // check count
    if (tableSchema.properties.count != objectSchema.properties.count) {
        @throw [NSException exceptionWithName:@"RLMException"
                                       reason:@"Column count does not match interface - migration required"
                                     userInfo:nil];
    }

    // check to see if properties are the same
    for (RLMProperty *schemaProp in objectSchema.properties) {
        RLMProperty *tableProp = tableSchema[schemaProp.name];
        if (![tableProp.name isEqualToString:schemaProp.name]) {
            @throw [NSException exceptionWithName:@"RLMException"
                                           reason:@"Existing property does not match interface - migration required"
                                         userInfo:@{@"property num": @(tableProp.column),
                                                    @"existing property name": tableProp.name,
                                                    @"new property name": schemaProp.name}];
        }
        if (tableProp.type != schemaProp.type) {
            @throw [NSException exceptionWithName:@"RLMException"
                                           reason:@"Property types do not match - migration required"
                                         userInfo:@{@"property name": tableProp.name,
                                                    @"existing property type": RLMTypeToString(tableProp.type),
                                                    @"new property type": RLMTypeToString(schemaProp.type)}];
        }
        if (tableProp.type == RLMPropertyTypeObject || tableProp.type == RLMPropertyTypeArray) {
            if (![tableProp.objectClassName isEqualToString:schemaProp.objectClassName]) {
                @throw [NSException exceptionWithName:@"RLMException"
                                               reason:@"Property objectClass does not match - migration required"
                                             userInfo:@{@"property name": tableProp.name,
                                                        @"existign objectClass": tableProp.objectClassName,
                                                        @"new property name": schemaProp.objectClassName}];
            }
        }

        // align
        schemaProp.column = tableProp.column;
    }
}


// verify and align all tables in schema
void RLMVerifyAndAlignSchema(RLMSchema *schema) {
    for (RLMObjectSchema *objectSchema in schema.objectSchema) {
        // get table schema
        tightdb::Table &table = *objectSchema->_table;
        RLMObjectSchema *tableSchema = [RLMObjectSchema schemaForTable:&table className:objectSchema.className];

        // verify and align
        RLMVerifyAndAlignColumns(tableSchema, objectSchema);

        // create accessors
        // FIXME - we need to generate different accessors keyed by the hash of the objectSchema (to preserve column ordering)
        //         it's possible to have multiple realms with different on-disk layouts, which requires
        //         us to have multiple accessors for each type/instance combination
        objectSchema.accessorClass = RLMAccessorClassForObjectClass(objectSchema.objectClass, objectSchema);
    }
}


// create a column for a property in a table
// NOTE: must be called from within write transaction
void RLMCreateColumn(RLMRealm *realm, tightdb::Table &table, RLMProperty *prop) {
    switch (prop.type) {
            // for objects and arrays, we have to specify target table
        case RLMPropertyTypeObject:
        case RLMPropertyTypeArray: {
            tightdb::TableRef linkTable = RLMTableForObjectClass(realm, prop.objectClassName);
            prop.column = table.add_column_link(tightdb::DataType(prop.type), prop.name.UTF8String, *linkTable);
            break;
        }
        default: {
            prop.column = table.add_column(tightdb::DataType(prop.type), prop.name.UTF8String);
            if (prop.attributes & RLMPropertyAttributeIndexed) {
                table.set_index(prop.column);
            }
        }
    }
}

// NOTE: must be called from within write transaction
bool RLMCreateMissingTables(RLMRealm *realm) {
    bool changed = false;
    for (RLMObjectSchema *objectSchema in realm.schema.objectSchema) {
        bool created = false;
        tightdb::TableRef table = RLMTableForObjectClass(realm, objectSchema.className, created);
        changed |= created;

        // store the table in this object schema
        objectSchema->_table = move(table);
    }
    return changed;
}

// add missing columns to objects described in targetSchema
// NOTE: must be called from within write transaction
bool RLMAddMissingColumns(RLMRealm *realm) {
    bool added = false;
    for (RLMObjectSchema *objectSchema in realm.schema.objectSchema) {
        // add columns
        RLMObjectSchema *tableSchema = [RLMObjectSchema schemaForTable:objectSchema->_table.get() className:objectSchema.className];
        for (RLMProperty *prop in objectSchema.properties) {
            // add any new properties (new name or different type)
            if (!tableSchema[prop.name] || ![prop isEqualToProperty:tableSchema[prop.name]]) {
                RLMCreateColumn(realm, *objectSchema->_table, prop);
                added = true;
            }
        }
    }
    return added;
}

// remove old columns in the realm not in targetSchema
// NOTE: must be called from within write transaction
bool RLMRemoveExtraColumns(RLMRealm *realm) {
    bool removed = false;
    for (RLMObjectSchema *objectSchema in realm.schema.objectSchema) {
        RLMObjectSchema *tableSchema = [RLMObjectSchema schemaForTable:objectSchema->_table.get() className:objectSchema.className];

        // remove any columns from tableSchema not in final schema
        for (int i = (int)tableSchema.properties.count - 1; i >= 0; i--) {
            RLMProperty *prop = tableSchema.properties[i];
            if (!objectSchema[prop.name] || ![prop isEqualToProperty:objectSchema[prop.name]]) {
                objectSchema->_table->remove_column(prop.column);
                removed = true;
            }
        }
    }
    return removed;
}

bool RLMRealmSetSchema(RLMRealm *realm, RLMSchema *targetSchema, bool migration) {
    // set new schema
    realm.schema = [targetSchema copy];

    // first pass create missing tables and verify existing
    bool changed = RLMCreateMissingTables(realm);

    // if not migrating then verify all non-empty tables
    if (!migration) {
        for (RLMObjectSchema *objectSchema in realm.schema.objectSchema) {
            if (objectSchema->_table->get_column_count()) {
                RLMObjectSchema *tableSchema = [RLMObjectSchema schemaForTable:objectSchema->_table.get()
                                                                     className:objectSchema.className];
                RLMVerifyAndAlignColumns(tableSchema, objectSchema);
            }
        }
    }

    // second pass add columns to empty tables
    changed = RLMAddMissingColumns(realm) || changed;
    
    // remove expired columns
    changed = RLMRemoveExtraColumns(realm) || changed;
    
    // FIXME - remove deleted objects
    
    // align all tables
    RLMVerifyAndAlignSchema(realm.schema);
    
    return changed;
}

inline void RLMVerifyInWriteTransaction(RLMRealm *realm) {
    // if realm is not writable throw
    if (!realm.inWriteTransaction) {
        @throw [NSException exceptionWithName:@"RLMException"
                                       reason:@"Can only add an object to a Realm in a write transaction - call beginWriteTransaction on a RLMRealm instance first."
                                     userInfo:nil];
    }
    RLMCheckThread(realm);
}

void RLMAddObjectToRealm(RLMObject *object, RLMRealm *realm) {
    // if already in the right realm then no-op
    if (object.realm == realm) {
        return;
    }

    // verify writable
    RLMVerifyInWriteTransaction(realm);
    
    // set the realm and schema
    NSString *objectClassName = [object.class className];
    RLMObjectSchema *schema = realm.schema[objectClassName];
    object.objectSchema = schema;
    object.realm = realm;

    // create row in table
    tightdb::Table &table = *schema->_table;
    size_t rowIndex = table.add_empty_row();
    object->_row = table[rowIndex];

    // populate all properties
    for (RLMProperty *prop in schema.properties) {
        // get object from ivar using key value coding
        id value = nil;
        if ([object respondsToSelector:NSSelectorFromString(prop.getterName)]) {
            value = [object valueForKey:prop.getterName];
        }

        // FIXME: Add condition to check for Mixed once it can support a nil value.
        if (!value && prop.type != RLMPropertyTypeObject) {
            @throw [NSException exceptionWithName:@"RLMException"
                                           reason:[NSString stringWithFormat:@"No value or default value specified for %@ property", prop.name]
                                         userInfo:nil];
        }

        // set in table with out validation
        RLMDynamicSet(object, prop, value);
    }

    // switch class to use table backed accessor
    object_setClass(object, schema.accessorClass);
}


RLMObject *RLMCreateObjectInRealmWithValue(RLMRealm *realm, NSString *className, id value) {
    // verify writable
    RLMVerifyInWriteTransaction(realm);

    // create the object
    RLMSchema *schema = realm.schema;
    RLMObjectSchema *objectSchema = schema[className];
    RLMObject *object = [[objectSchema.objectClass alloc] initWithRealm:realm schema:objectSchema defaultValues:NO];

    // validate values, create row, and populate
    if ([value isKindOfClass:NSArray.class]) {
        NSArray *array = RLMValidatedArrayForObjectSchema(value, objectSchema, schema);

        // create row
        tightdb::Table &table = *objectSchema->_table;
        size_t rowIndex = table.add_empty_row();
        object->_row = table[rowIndex];

        // populate
        NSArray *props = objectSchema.properties;
        for (NSUInteger i = 0; i < array.count; i++) {
            RLMDynamicSet(object, (RLMProperty *)props[i], array[i]);
        }
    }
    else if ([value isKindOfClass:NSDictionary.class]) {
        NSDictionary *dict = RLMValidatedDictionaryForObjectSchema(value, objectSchema, schema);

        // create row
        tightdb::Table &table = *objectSchema->_table;
        size_t rowIndex = table.add_empty_row();
        object->_row = table[rowIndex];
        
        // populate
        NSArray *props = objectSchema.properties;
        for (RLMProperty *prop in props) {
            RLMDynamicSet(object, prop, dict[prop.name]);
        }
    }
    else {
        @throw [NSException exceptionWithName:@"RLMException"
                                       reason:@"Values must be provided either as an array or dictionary"
                                     userInfo:nil];
    }

    // switch class to use table backed accessor
    object_setClass(object, objectSchema.accessorClass);

    return object;
}

void RLMDeleteObjectFromRealm(RLMObject *object) {
    RLMVerifyInWriteTransaction(object.realm);

    // move last row to row we are deleting
    object->_row.get_table()->move_last_over(object->_row.get_index());
}

RLMArray *RLMGetObjects(RLMRealm *realm, NSString *objectClassName, NSPredicate *predicate, NSString *order) {
    RLMCheckThread(realm);

    // create view from table and predicate
    RLMObjectSchema *objectSchema = realm.schema[objectClassName];
    tightdb::Query query = objectSchema->_table->where();
    RLMUpdateQueryWithPredicate(&query, predicate, realm.schema, objectSchema);
    
    // create view and sort
    tightdb::TableView view = query.find_all();
    RLMUpdateViewWithOrder(view, objectSchema, order, YES);
    
    // create and populate array
    __autoreleasing RLMArray * array = [RLMArrayTableView arrayWithObjectClassName:objectClassName view:view realm:realm];
    return array;
}

// Create accessor and register with realm
RLMObject *RLMCreateObjectAccessor(RLMRealm *realm, NSString *objectClassName, NSUInteger index) {
    RLMCheckThread(realm);

    RLMObjectSchema *objectSchema = realm.schema[objectClassName];
    
    // get accessor for the object class
    RLMObject *accessor = [[objectSchema.accessorClass alloc] initWithRealm:realm schema:objectSchema defaultValues:NO];
    tightdb::Table &table = *objectSchema->_table;
    accessor->_row = table[index];
    return accessor;
}


