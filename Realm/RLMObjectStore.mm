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
#import "RLMObject_Private.h"
#import "RLMAccessor.h"
#import "RLMQueryUtil.h"
#import "RLMUtil.h"

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
                                                NSString *className) {
    NSString *tableName = realm.schema.tableNamesForClass[className];
    return realm.group->get_table(tightdb::StringData(tableName.UTF8String, tableName.length));
}

void RLMEnsureRealmTablesExist(RLMRealm *realm) {
    [realm beginWriteTransaction];
    
    // FIXME - support migrations
    // first pass create tables
    for (RLMObjectSchema *objectSchema in realm.schema.objectSchema) {
        tightdb::TableRef table = RLMTableForObjectClass(realm, objectSchema.className);
    }
    
    // second pass add columns
    for (RLMObjectSchema *objectSchema in realm.schema.objectSchema) {
        tightdb::TableRef table = RLMTableForObjectClass(realm, objectSchema.className);
        
        if (table->get_column_count() == 0) {
            for (RLMProperty *prop in objectSchema.properties) {
                tightdb::StringData name(prop.name.UTF8String, prop.name.length);
                switch (prop.type) {
                    // for objects and arrays, we have to specify target table
                    case RLMPropertyTypeObject:
                    case RLMPropertyTypeArray: {
                        tightdb::TableRef linkTable = RLMTableForObjectClass(realm, prop.objectClassName);
                        table->add_column_link(tightdb::DataType(prop.type), name, *linkTable);
                        break;
                    }
                    default: {
                    	size_t column = table->add_column((tightdb::DataType)prop.type, name);
                    	if (prop.attributes & RLMPropertyAttributeIndexed) {
                            table->set_index(column);
                        }
                        break;
                    }
                }
            }
        }
        else {
            if (table->get_column_count() != objectSchema.properties.count) {
                [realm rollbackWriteTransaction];
                @throw [NSException exceptionWithName:@"RLMException" reason:@"Column count does not match interface - migration required"
                                             userInfo:nil];
            }
            // FIXME - verify columns match
        }
    }
    [realm commitWriteTransaction];
}

void RLMAddObjectToRealm(RLMObject *object, RLMRealm *realm) {
    // if already in the right realm then no-op
    if (object.realm == realm) {
        return;
    }
    
    // if realm is not writable throw
    if (realm.transactionMode != RLMTransactionModeWrite) {
        @throw [NSException exceptionWithName:@"RLMException"
                                       reason:@"Can only add an object to a Realm during a write transaction"
                                     userInfo:nil];
    }
    
    // get table and create new row
    NSString *objectClassName = object.schema.className;
    object.realm = realm;
    object.schema = realm.schema[objectClassName];
    object.backingTable = RLMTableForObjectClass(realm, objectClassName);
    object.objectIndex = object.backingTable->add_empty_row();
    
    // change object class to insertion accessor
    RLMObjectSchema *schema = realm.schema[objectClassName];
    Class objectClass = NSClassFromString(objectClassName);
    object_setClass(object, RLMInsertionAccessorClassForObjectClass(objectClass, schema));

    // call our insertion setter to populate all properties in the table
    for (RLMProperty *prop in schema.properties) {
        // InsertionAccessr getter gets object from ivar
        id value = [object valueForKey:prop.name];
        
        // FIXME: Add condition to check for Mixed or Object types because they can support a nil value.
        if (value) {
            // InsertionAccssor setter inserts into table
            [object setValue:value forKey:prop.name];
        }
        else {
            @throw [NSException exceptionWithName:@"RLMException"
                                           reason:[NSString stringWithFormat:@"No value or default value specified for %@ property", prop.name]
                                         userInfo:nil];
        }
    }
    
    // we are in a read transaction so change accessor class to readwrite accessor
    object_setClass(object, RLMAccessorClassForObjectClass(objectClass, schema));
    
    // register object with the realm
    [realm registerAccessor:object];
}

void RLMDeleteObjectFromRealm(RLMObject *object) {
    // if realm is not writable throw
    if (object.realm.transactionMode != RLMTransactionModeWrite) {
        @throw [NSException exceptionWithName:@"RLMException" reason:@"Can only delete objects from a Realm during a write transaction" userInfo:nil];
    }
    // move last row to row we are deleting
    object.backingTable->move_last_over(object.objectIndex);
    // FIXME - fix all accessors
}

RLMArray *RLMGetObjects(RLMRealm *realm, NSString *objectClassName, NSPredicate *predicate, id order) {
    // get table for this calss
    tightdb::TableRef table = RLMTableForObjectClass(realm, objectClassName);
    
    // create view from table and predicate
    RLMObjectSchema *schema = realm.schema[objectClassName];
    tightdb::Query *query = new tightdb::Query(table->where());
    RLMUpdateQueryWithPredicate(query, predicate, schema);
    
    // create view and sort
    tightdb::TableView view = query->find_all();
    RLMUpdateViewWithOrder(view, order, schema);
    
    // create and populate array
    return [RLMArrayTableView arrayWithObjectClassName:objectClassName query:query view:view realm:realm];
}

// Create accessor and register with realm
RLMObject *RLMCreateObjectAccessor(RLMRealm *realm, NSString *objectClassName, NSUInteger index) {
    // get object classname to use from the schema
    Class objectClass = [realm.schema objectClassForClassName:objectClassName];
    
    // get acessor fot the object class
    Class accessorClass = RLMAccessorClassForObjectClass(objectClass, realm.schema[objectClassName]);
    RLMObject *accessor = [[accessorClass alloc] initWithRealm:realm
                                                        schema:realm.schema[objectClassName]
                                                 defaultValues:NO];

    tightdb::TableRef table = RLMTableForObjectClass(realm, objectClassName);
    accessor.backingTable = table;
    accessor.objectIndex = index;
    accessor.writable = (realm.transactionMode == RLMTransactionModeWrite);
    
    [accessor.realm registerAccessor:accessor];
    return accessor;
}


