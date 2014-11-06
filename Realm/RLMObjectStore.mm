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

#import "RLMObjectStore.hpp"
#import "RLMRealm_Private.hpp"
#import "RLMArray_Private.hpp"
#import "RLMObjectSchema_Private.hpp"
#import "RLMObject_Private.h"
#import "RLMProperty_Private.h"
#import "RLMQueryUtil.hpp"
#import "RLMUtil.hpp"

#import <objc/runtime.h>

static void RLMVerifyAndAlignColumns(RLMObjectSchema *tableSchema, RLMObjectSchema *objectSchema) {
    NSMutableArray *properties = [NSMutableArray arrayWithCapacity:objectSchema.properties.count];
    NSMutableArray *exceptionMessages = [NSMutableArray array];

    // check to see if properties are the same
    for (RLMProperty *tableProp in tableSchema.properties) {
        RLMProperty *schemaProp = objectSchema[tableProp.name];
        if (!schemaProp) {
            [exceptionMessages addObject:[NSString stringWithFormat:@"Property '%@' is missing from latest object model.", tableProp.name]];
            continue;
        }
        if (tableProp.type != schemaProp.type) {
            [exceptionMessages addObject:[NSString stringWithFormat:@"Property types for '%@' property do not match. Old type '%@', new type '%@'.",
                                          tableProp.name, RLMTypeToString(tableProp.type), RLMTypeToString(schemaProp.type)]];
            continue;
        }
        if (tableProp.type == RLMPropertyTypeObject || tableProp.type == RLMPropertyTypeArray) {
            if (![tableProp.objectClassName isEqualToString:schemaProp.objectClassName]) {
                [exceptionMessages addObject:[NSString stringWithFormat:@"Target object type for property '%@' does not match. Old type '%@', new type '%@'.",
                                              tableProp.name, tableProp.objectClassName, schemaProp.objectClassName]];
            }
        }
        if (tableProp.isPrimary != schemaProp.isPrimary) {
            if (tableProp.isPrimary) {
                [exceptionMessages addObject:[NSString stringWithFormat:@"Property '%@' is no longer a primary key.", tableProp.name]];
            }
            else {
                [exceptionMessages addObject:[NSString stringWithFormat:@"Property '%@' has been made a primary key.", tableProp.name]];
            }
        }

        // align
        schemaProp.column = tableProp.column;
        [properties addObject:schemaProp];
    }

    // check for new missing properties
    for (RLMProperty *schemaProp in objectSchema.properties) {
        if (!tableSchema[schemaProp.name]) {
            [exceptionMessages addObject:[NSString stringWithFormat:@"Property '%@' has been added to latest object model.", schemaProp.name]];
        }
    }

    // throw if errors
    if (exceptionMessages.count) {
        @throw [NSException exceptionWithName:@"RLMException"
                                       reason:[NSString stringWithFormat:@"Migration is required for object type '%@' due to the following errors:\n- %@",
                                               objectSchema.className, [exceptionMessages componentsJoinedByString:@"\n- "]]
                                     userInfo:nil];
    }
    // ensure the order of the properties matches the column order in the table
    objectSchema.properties = properties;
}

// create a column for a property in a table
// NOTE: must be called from within write transaction
static void RLMCreateColumn(RLMRealm *realm, tightdb::Table &table, RLMProperty *prop) {
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
                // FIXME - support other types
                if (prop.type != RLMPropertyTypeString) {
                    NSLog(@"RLMPropertyAttributeIndexed only supported for 'NSString' properties");
                }
                else {
                    table.add_search_index(prop.column);
                }
            }
        }
    }
}

void RLMRealmSetSchema(RLMRealm *realm, RLMSchema *targetSchema, bool verify) {
    realm.schema = [targetSchema copy];

    for (RLMObjectSchema *objectSchema in realm.schema.objectSchema) {
        // read-only realms may be missing tables entirely
        objectSchema->_table = RLMTableForObjectClass(realm, objectSchema.className);
        if (objectSchema->_table && verify) {
            RLMObjectSchema *tableSchema = [RLMObjectSchema schemaFromTableForClassName:objectSchema.className realm:realm];
            RLMVerifyAndAlignColumns(tableSchema, objectSchema);
        }
        if (!objectSchema.accessorClass) {
            objectSchema.accessorClass = RLMAccessorClassForObjectClass(objectSchema.objectClass, objectSchema);
        }
    }
}

void RLMRealmCreateTables(RLMRealm *realm, RLMSchema *targetSchema, bool updateExisting) {
    realm.schema = [targetSchema copy];

    // first pass to create missing tables
    bool changed = false;
    NSMutableArray *objectSchemaToUpdate = [NSMutableArray array];
    for (RLMObjectSchema *objectSchema in realm.schema.objectSchema) {
        bool created = false;
        objectSchema->_table = RLMTableForObjectClass(realm, objectSchema.className, created);
        changed |= created;

        // we will modify tables for any new objectSchema (table was created) or for all if updateExisting is true
        if (updateExisting || created) {
            [objectSchemaToUpdate addObject:objectSchema];
        }
    }

    // second pass adds/removes columns for objectSchemaToUpdate
    for (RLMObjectSchema *objectSchema in objectSchemaToUpdate) {
        RLMObjectSchema *tableSchema = [RLMObjectSchema schemaFromTableForClassName:objectSchema.className realm:realm];

        // add missing columns
        for (RLMProperty *prop in objectSchema.properties) {
            // add any new properties (new name or different type)
            if (!tableSchema[prop.name] || ![prop isEqualToProperty:tableSchema[prop.name]]) {
                RLMCreateColumn(realm, *objectSchema->_table, prop);
                changed = true;
            }
        }

        // remove extra columns
        for (int i = (int)tableSchema.properties.count - 1; i >= 0; i--) {
            RLMProperty *prop = tableSchema.properties[i];
            if (!objectSchema[prop.name] || ![prop isEqualToProperty:objectSchema[prop.name]]) {
                objectSchema->_table->remove_column(prop.column);
                changed = true;
            }
        }

        // update table metadata
        if (objectSchema.primaryKeyProperty != nil) {
            // if there is a primary key set, check if it is the same as the old key
            if (tableSchema.primaryKeyProperty == nil || ![tableSchema.primaryKeyProperty isEqual:objectSchema.primaryKeyProperty]) {
                RLMRealmSetPrimaryKeyForObjectClass(realm, objectSchema.className, objectSchema.primaryKeyProperty.name);
                changed = true;
            }
        }
        else if (tableSchema.primaryKeyProperty) {
            // there is no primary key, so if thre was one nil out
            RLMRealmSetPrimaryKeyForObjectClass(realm, objectSchema.objectClass, nil);
            changed = true;
        }
    }

    // FIXME - remove deleted tables

    for (RLMObjectSchema *objectSchema in realm.schema.objectSchema) {
        // cache table instances on objectSchema
        objectSchema->_table = RLMTableForObjectClass(realm, objectSchema.className);

        RLMObjectSchema *tableSchema = [RLMObjectSchema schemaFromTableForClassName:objectSchema.className realm:realm];
        RLMVerifyAndAlignColumns(tableSchema, objectSchema);

        // create accessors
        // FIXME - we need to generate different accessors keyed by the hash of the objectSchema (to preserve column ordering)
        //         it's possible to have multiple realms with different on-disk layouts, which requires
        //         us to have multiple accessors for each type/instance combination
        objectSchema.accessorClass = RLMAccessorClassForObjectClass(objectSchema.objectClass, objectSchema);
    }
}

static inline void RLMVerifyInWriteTransaction(RLMRealm *realm) {
    // if realm is not writable throw
    if (!realm.inWriteTransaction) {
        @throw [NSException exceptionWithName:@"RLMException"
                                       reason:@"Can only add an object to a Realm in a write transaction - call beginWriteTransaction on an RLMRealm instance first."
                                     userInfo:nil];
    }
    RLMCheckThread(realm);
}

template<typename F>
static inline NSUInteger RLMCreateOrGetRowForObject(RLMObjectSchema *schema, F primaryValueGetter, RLMSetFlag options, bool &created) {
    // try to get existing row if updating
    size_t rowIndex = tightdb::not_found;
    tightdb::Table &table = *schema->_table;
    RLMProperty *primaryProperty = schema.primaryKeyProperty;
    if ((options & RLMSetFlagUpdateOrCreate) && primaryProperty) {
        // get primary value
        id primaryValue = primaryValueGetter(primaryProperty);
        
        // search for existing object based on primary key type
        if (primaryProperty.type == RLMPropertyTypeString) {
            rowIndex = table.find_first_string(primaryProperty.column, RLMStringDataWithNSString(primaryValue));
        }
        else {
            rowIndex = table.find_first_int(primaryProperty.column, [primaryValue longLongValue]);
        }
    }

    // if no existing, create row
    created = NO;
    if (rowIndex == tightdb::not_found) {
        rowIndex = table.add_empty_row();
        created = YES;
    }

    // get accessor
    return rowIndex;
}

void RLMAddObjectToRealm(RLMObject *object, RLMRealm *realm, RLMSetFlag options) {
    RLMVerifyInWriteTransaction(realm);

    // verify that object is standalone
    if (object.deletedFromRealm) {
        @throw [NSException exceptionWithName:@"RLMException"
                                       reason:@"Adding a deleted object to a Realm is not permitted"
                                     userInfo:nil];
    }
    if (object.realm) {
        if (object.realm == realm) {
            // no-op
            return;
        }
        // for differing realms users must explicitly create the object in the second realm
        @throw [NSException exceptionWithName:@"RLMException"
                                       reason:@"Object is already persisted in a Realm"
                                     userInfo:nil];
    }

    // set the realm and schema
    NSString *objectClassName = object.objectSchema.className;
    RLMObjectSchema *schema = realm.schema[objectClassName];
    object.objectSchema = schema;
    object.realm = realm;

    // get or create row
    bool created;
    auto primaryGetter = [=](RLMProperty *p) { return [object valueForKey:p.getterName]; };
    object->_row = (*schema->_table)[RLMCreateOrGetRowForObject(schema, primaryGetter, options, created)];

    // populate all properties
    for (RLMProperty *prop in schema.properties) {
        // get object from ivar using key value coding
        id value = nil;
        if ([object respondsToSelector:prop.getterSel]) {
            value = [object valueForKey:prop.getterName];
        }

        // FIXME: Add condition to check for Mixed once it can support a nil value.
        if (!value && prop.type != RLMPropertyTypeObject) {
            @throw [NSException exceptionWithName:@"RLMException"
                                           reason:[NSString stringWithFormat:@"No value or default value specified for property '%@' in '%@'",
                                                   prop.name, schema.className]
                                         userInfo:nil];
        }

        // set in table with out validation
        // skip primary key when updating since it doesn't change
        if (created || !prop.isPrimary) {
            RLMDynamicSet(object, prop, value, options | (prop.isPrimary ? RLMSetFlagEnforceUnique : 0));
        }
    }

    // switch class to use table backed accessor
    object_setClass(object, schema.accessorClass);
}


RLMObject *RLMCreateObjectInRealmWithValue(RLMRealm *realm, NSString *className, id value, RLMSetFlag options) {
    // verify writable
    RLMVerifyInWriteTransaction(realm);

    // create the object
    RLMSchema *schema = realm.schema;
    RLMObjectSchema *objectSchema = schema[className];
    RLMObject *object = [[objectSchema.objectClass alloc] initWithRealm:realm schema:objectSchema defaultValues:NO];

    // validate values, create row, and populate
    if (NSArray *array = RLMDynamicCast<NSArray>(value)) {
        array = RLMValidatedArrayForObjectSchema(value, objectSchema, schema);

        // get or create our accessor
        bool created;
        auto primaryGetter = [=](RLMProperty *p) { return array[p.column]; };
        object->_row = (*objectSchema->_table)[RLMCreateOrGetRowForObject(objectSchema, primaryGetter, options, created)];

        // populate
        NSArray *props = objectSchema.properties;
        for (NSUInteger i = 0; i < array.count; i++) {
            RLMProperty *prop = props[i];
            // skip primary key when updating since it doesn't change
            if (created || !prop.isPrimary) {
                RLMDynamicSet(object, prop, array[i],
                              options | RLMSetFlagUpdateOrCreate | (prop.isPrimary ? RLMSetFlagEnforceUnique : 0));
            }
        }
    }
    else {
        // get or create our accessor
        bool created;
        auto primaryGetter = [=](RLMProperty *p) { return [value valueForKey:p.name]; };
        object->_row = (*objectSchema->_table)[RLMCreateOrGetRowForObject(objectSchema, primaryGetter, options, created)];

        // assume dictionary or object with kvc properties
        NSDictionary *dict = RLMValidatedDictionaryForObjectSchema(value, objectSchema, schema, !created);

        // populate
        for (RLMProperty *prop in objectSchema.properties) {
            // skip missing properties and primary key when updating since it doesn't change
            id propValue = dict[prop.name];
            if (propValue && (created || !prop.isPrimary)) {
                RLMDynamicSet(object, prop, propValue,
                              options | RLMSetFlagUpdateOrCreate | (prop.isPrimary ? RLMSetFlagEnforceUnique : 0));
            }
        }
    }

    // switch class to use table backed accessor
    object_setClass(object, objectSchema.accessorClass);

    return object;
}

void RLMDeleteObjectFromRealm(RLMObject *object, RLMRealm *realm) {
    if (realm != object.realm) {
        @throw [NSException exceptionWithName:@"RLMException"
                                       reason:@"Unable to delete an object not persisted in this Realm." userInfo:nil];
    }
    RLMVerifyInWriteTransaction(object.realm);

    // move last row to row we are deleting
    if (object->_row.is_attached()) {
        object->_row.get_table()->move_last_over(object->_row.get_index());
    }

    // set realm to nil
    object.realm = nil;
}

void RLMDeleteAllObjectsFromRealm(RLMRealm *realm) {
    RLMVerifyInWriteTransaction(realm);

    // clear table for each object schema
    for (RLMObjectSchema *objectSchema in realm.schema.objectSchema) {
        objectSchema->_table->clear();
    }
}

RLMResults *RLMGetObjects(RLMRealm *realm, NSString *objectClassName, NSPredicate *predicate) {
    RLMCheckThread(realm);

    // create view from table and predicate
    RLMObjectSchema *objectSchema = realm.schema[objectClassName];
    if (!objectSchema->_table) {
        // read-only realms may be missing tables since we can't add any
        // missing ones on init
        return [RLMEmptyResults emptyResultsWithObjectClassName:objectClassName realm:realm];
    }
    tightdb::Query query = objectSchema->_table->where();
    RLMUpdateQueryWithPredicate(&query, predicate, realm.schema, objectSchema);
    
    // create and populate array
    __autoreleasing RLMResults * results = [RLMResults resultsWithObjectClassName:objectClassName
                                                                            query:std::make_unique<Query>(query)
                                                                            realm:realm];
    return results;
}

id RLMGetObject(RLMRealm *realm, NSString *objectClassName, id key) {
    RLMCheckThread(realm);

    RLMObjectSchema *objectSchema = realm.schema[objectClassName];

    RLMProperty *primaryProperty = objectSchema.primaryKeyProperty;
    if (!primaryProperty) {
        NSString *msg = [NSString stringWithFormat:@"%@ does not have a primary key", objectClassName];
        @throw [NSException exceptionWithName:@"RLMException" reason:msg userInfo:nil];
    }

    if (!objectSchema->_table) {
        // read-only realms may be missing tables since we can't add any
        // missing ones on init
        return nil;
    }

    size_t row = tightdb::not_found;
    if (primaryProperty.type == RLMPropertyTypeString) {
        if (NSString *str = RLMDynamicCast<NSString>(key)) {
            row = objectSchema->_table->find_first_string(primaryProperty.column, RLMStringDataWithNSString(str));
        }
        else {
            @throw [NSException exceptionWithName:@"RLMException"
                                           reason:[NSString stringWithFormat:@"Invalid value '%@' for primary key", key]
                                         userInfo:nil];
        }
    }
    else {
        if (NSNumber *number = RLMDynamicCast<NSNumber>(key)) {
            row = objectSchema->_table->find_first_int(primaryProperty.column, number.longLongValue);
        }
        else {
            @throw [NSException exceptionWithName:@"RLMException"
                                           reason:[NSString stringWithFormat:@"Invalid value '%@' for primary key", key]
                                         userInfo:nil];
        }
    }

    if (row == tightdb::not_found) {
        return nil;
    }

    return RLMCreateObjectAccessor(realm, objectClassName, row);
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

