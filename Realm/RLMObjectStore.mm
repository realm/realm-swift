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

// initializer
void RLMInitializeObjectStore() {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        // register accessor cache
        RLMAccessorCacheInitialize();
    });
}

// get the table used to store object of objectClass
inline tightdb::TableRef RLMTableForObjectClass(RLMRealm *realm,
                                                NSString *className,
                                                bool &created) {
    NSString *tableName = realm.schema.tableNamesForClass[className];
    return realm.group->get_table(tableName.UTF8String, created);
}
inline tightdb::TableRef RLMTableForObjectClass(RLMRealm *realm,
                                                NSString *className) {
    bool created;
    NSString *tableName = realm.schema.tableNamesForClass[className];
    return realm.group->get_table(tableName.UTF8String, created);
}

void RLMVerifyAndAlignTableColumns(RLMObjectSchema *tableSchema, RLMObjectSchema *objectSchema) {
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

        // update column on schemaProp
        schemaProp.column = tableProp.column;
    }
}

// create a column for a property in a table
// NOTE: must be called from within write transaction
void RLMCreateColumn(RLMRealm *realm, tightdb::Table *table, RLMProperty *prop) {
    switch (prop.type) {
            // for objects and arrays, we have to specify target table
        case RLMPropertyTypeObject:
        case RLMPropertyTypeArray: {
            tightdb::TableRef linkTable = RLMTableForObjectClass(realm, prop.objectClassName);
            prop.column = table->add_column_link(tightdb::DataType(prop.type), prop.name.UTF8String, *linkTable);
            break;
        }
        default: {
            prop.column = table->add_column((tightdb::DataType)prop.type, prop.name.UTF8String);
            if (prop.attributes & RLMPropertyAttributeIndexed) {
                table->set_index(prop.column);
            }
            break;
        }
    }
}

// NOTE: must be called from within write transaction
bool RLMCreateMissingTables(RLMRealm *realm, RLMSchema *targetSchema, BOOL verifyExisting) {
    bool changed = false;
    for (RLMObjectSchema *objectSchema in targetSchema.objectSchema) {
        bool created;
        tightdb::TableRef table = RLMTableForObjectClass(realm, objectSchema.className, created);
        changed |= created;

        // if columns have already been created, then verify
        if (verifyExisting && table->get_column_count()) {
            RLMObjectSchema *tableSchema = [RLMObjectSchema schemaForTable:table.get() className:objectSchema.className];
            RLMVerifyAndAlignTableColumns(tableSchema, objectSchema);
        }
    }
    return changed;
}

// add missing columns to objects described in targetSchema
// NOTE: must be called from within write transaction
bool RLMAddNewColumnsToSchema(RLMRealm *realm, RLMSchema *targetSchema, BOOL verifyMatching) {
    bool added = false;
    for (RLMObjectSchema *objectSchema in targetSchema.objectSchema) {
        tightdb::TableRef table = RLMTableForObjectClass(realm, objectSchema.className);

        // add columns
        RLMObjectSchema *tableSchema = [RLMObjectSchema schemaForTable:table.get() className:objectSchema.className];
        for (RLMProperty *prop in objectSchema.properties) {
            // add any new properties (new name or different type)
            if (!tableSchema[prop.name] || ![prop isEqualToProperty:tableSchema[prop.name]]) {
                RLMCreateColumn(realm, table.get(), prop);
                added = true;
            }
        }

        // re-verify and align
        if (verifyMatching) {
            RLMObjectSchema *tableSchema = [RLMObjectSchema schemaForTable:table.get() className:objectSchema.className];
            RLMVerifyAndAlignTableColumns(tableSchema, objectSchema);
        }
    }
    return added;
}

// remove old columns in the realm not in targetSchema
// NOTE: must be called from within write transaction
bool RLMRemoveOldColumnsFromSchema(RLMRealm *realm, RLMSchema *targetSchema) {
    bool removed = false;
    for (RLMObjectSchema *objectSchema in targetSchema.objectSchema) {
        tightdb::TableRef table = RLMTableForObjectClass(realm, objectSchema.className);
        RLMObjectSchema *tableSchema = [RLMObjectSchema schemaForTable:table.get() className:objectSchema.className];

        // remove any columns from tableSchema not in final schema
        for (int i = (int)tableSchema.properties.count - 1; i >= 0; i--) {
            RLMProperty *prop = tableSchema.properties[i];
            if (!objectSchema[prop.name] || ![prop isEqualToProperty:objectSchema[prop.name]]) {
                table->remove_column(prop.column);
                removed = true;
            }
        }
    }
    return removed;
}

bool RLMUpdateTables(RLMRealm *realm, RLMSchema *targetSchema) {
    // first pass create missing tables and verify existing
    bool changed = RLMCreateMissingTables(realm, targetSchema, NO);
    
    // second pass add columns to empty tables
    changed = RLMAddNewColumnsToSchema(realm, targetSchema, NO) | changed;
    
    // remove expired columns
    changed = RLMRemoveOldColumnsFromSchema(realm, targetSchema) | changed;
    
    // FIXME - remove deleted objects
    
    // verify
    // FIXME - remove once we are sure the rest of the code actually works properly
    for (RLMObjectSchema *objectSchema in targetSchema.objectSchema) {
        tightdb::TableRef table = RLMTableForObjectClass(realm, objectSchema.className);
        RLMObjectSchema *tableSchema = [RLMObjectSchema schemaForTable:table.get() className:objectSchema.className];
        RLMVerifyAndAlignTableColumns(tableSchema, objectSchema);
    }
    
    // set the new schema on the realm
    realm.schema = targetSchema;
    
    return changed;
}

// verify and create new tables without migration - throws if any existing
// tables are not compatible with on disk schema
void RLMVerifyAndCreateTables(RLMRealm *realm) {
    [realm beginWriteTransaction];
    
    // first pass create missing tables and verify existing
    RLMCreateMissingTables(realm, realm.schema, YES);
    
    // second pass add columns to empty tables
    RLMAddNewColumnsToSchema(realm, realm.schema, YES);

    [realm commitWriteTransaction];
}

inline void RLMVerifyInWriteTransaction(RLMRealm *realm) {
    // if realm is not writable throw
    if (!realm.inWriteTransaction) {
        @throw [NSException exceptionWithName:@"RLMException"
                                       reason:@"Can only add an object to a Realm during a write transaction"
                                     userInfo:nil];
    }
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
    object.RLMObject_schema = schema;
    object.realm = realm;

    // create row in table
    tightdb::TableRef table = RLMTableForObjectClass(realm, objectClassName);
    size_t rowIndex = table->add_empty_row();
    object->_row = (*table)[rowIndex];

    // populate all properties
    for (RLMProperty *prop in schema.properties) {
        // get object from ivar using key value coding
        id value = [object valueForKey:prop.name];
        
        // FIXME: Add condition to check for Mixed once it can support a nil value.
        if (!value && prop.type != RLMPropertyTypeObject) {
            @throw [NSException exceptionWithName:@"RLMException"
                                           reason:[NSString stringWithFormat:@"No value or default value specified for %@ property", prop.name]
                                         userInfo:nil];
        }

        // set in table with out validation
        RLMDynamicSet(object, prop.name, value, NO);
    }

    // switch class to use table backed accessor
    object_setClass(object, RLMAccessorClassForObjectClass(schema.objectClass, schema));
}


RLMObject *RLMCreateObjectInRealmWithValue(RLMRealm *realm, NSString *className, id value) {
    // verify writable
    RLMVerifyInWriteTransaction(realm);

    // create the object
    RLMObjectSchema *schema = realm.schema[className];
    RLMObject *object = [[schema.objectClass alloc] initWithRealm:realm schema:schema defaultValues:NO];

    // get table
    tightdb::TableRef table = RLMTableForObjectClass(realm, className);

    // validate values, create row, and populate
    if ([value isKindOfClass:NSArray.class]) {
        NSArray *array = value;
        RLMValidateArrayAgainstObjectSchema(array, schema);

        // create row
        size_t rowIndex = table->add_empty_row();
        object->_row = (*table)[rowIndex];

        // populate
        NSArray *props = schema.properties;
        for (NSUInteger i = 0; i < array.count; i++) {
            RLMDynamicSet(object, (RLMProperty *)props[i], array[i]);
        }
    }
    else if ([value isKindOfClass:NSDictionary.class]) {
        NSDictionary *dict = RLMValidatedDictionaryForObjectSchema(value, schema);

        // create row
        size_t rowIndex = table->add_empty_row();
        object->_row = (*table)[rowIndex];
        
        // populate
        NSArray *props = schema.properties;
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
    object_setClass(object, RLMAccessorClassForObjectClass(schema.objectClass, schema));

    return object;
}

void RLMDeleteObjectFromRealm(RLMObject *object) {
    RLMVerifyInWriteTransaction(object.realm);

    // move last row to row we are deleting
    object->_row.get_table()->move_last_over(object->_row.get_index());
    // FIXME - fix all accessors
}

RLMArray *RLMGetObjects(RLMRealm *realm, NSString *objectClassName, NSPredicate *predicate, NSString *order) {
    // get table for this calss
    tightdb::TableRef table = RLMTableForObjectClass(realm, objectClassName);
    
    // create view from table and predicate
    RLMObjectSchema *schema = realm.schema[objectClassName];
    tightdb::Query *query = new tightdb::Query(table->where());
    RLMUpdateQueryWithPredicate(query, predicate, schema);
    
    // create view and sort
    tightdb::TableView view = query->find_all();
    RLMUpdateViewWithOrder(view, schema, order, YES);
    
    // create and populate array
    __autoreleasing RLMArray * array = [RLMArrayTableView arrayWithObjectClassName:objectClassName
                                                                             query:query view:view
                                                                             realm:realm];
    return array;
}

// Create accessor and register with realm
RLMObject *RLMCreateObjectAccessor(RLMRealm *realm, NSString *objectClassName, NSUInteger index) {
    // get object classname to use from the schema
    RLMObjectSchema *objectSchema = realm.schema[objectClassName];
    
    // get acessor fot the object class
    Class accessorClass = RLMAccessorClassForObjectClass(objectSchema.objectClass, objectSchema);
    RLMObject *accessor = [[accessorClass alloc] initWithRealm:realm
                                                        schema:realm.schema[objectClassName]
                                                 defaultValues:NO];

    tightdb::TableRef table = RLMTableForObjectClass(realm, objectClassName);
    accessor->_row = (*table)[index];
    return accessor;
}


