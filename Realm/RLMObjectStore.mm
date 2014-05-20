////////////////////////////////////////////////////////////////////////////
//
// TIGHTDB CONFIDENTIAL
// __________________
//
//  [2011] - [2014] TightDB Inc
//  All Rights Reserved.
//
// NOTICE:  All information contained herein is, and remains
// the property of TightDB Incorporated and its suppliers,
// if any.  The intellectual and technical concepts contained
// herein are proprietary to TightDB Incorporated
// and its suppliers and may be covered by U.S. and Foreign Patents,
// patents in process, and are protected by trade secret or copyright law.
// Dissemination of this information or reproduction of this material
// is strictly forbidden unless prior written permission is obtained
// from TightDB Incorporated.
//
////////////////////////////////////////////////////////////////////////////
#import "RLMObjectStore.h"
#import "RLMSchema.h"
#import "RLMObjectSchema.h"
#import "RLMPrivate.hpp"
#import "RLMQueryUtil.h"
#import "RLMUtil.h"

#import <objc/runtime.h>

RLMSchema *s_currentSchema;

void RLMInitializeObjectStore() {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        // register accessor cache
        RLMAccessorCacheInitialize();

        // get the schema for current object interfaces
        s_currentSchema = [RLMSchema schemaForRuntimeObjects];
    });
}

RLMSchema *RLMSharedSchema() {
    return s_currentSchema;
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
                if (prop.type == RLMPropertyTypeObject) {
//                    tightdb::TableRef linkTable = RLMTableForObjectClass(realm, prop.objectClassName);
//                    table->add_column_link(name, linkTable->get_index_in_parent());
                    @throw [NSException exceptionWithName:@"RLMNotImplementedException"
                                                   reason:@"Links not yest supported" userInfo:nil];
                }
                else {
                    table->add_column((tightdb::DataType)prop.type, name);
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
        @throw [NSException exceptionWithName:@"RLMException" reason:@"Can only add an object to a Realm during a write transaction" userInfo:nil];
    }
    
    // get table and create new row
    Class objectClass = object.class;
    NSString *objectClassName = NSStringFromClass(objectClass);
    object.realm = realm;
    object.backingTable = RLMTableForObjectClass(realm, objectClassName).get();
    object.objectIndex = object.backingTable->add_empty_row();
    object.backingTableIndex = object.backingTable->get_index_in_parent();
    
    // change object class to insertion accessor
    RLMObjectSchema *schema = realm.schema[objectClassName];
    object_setClass(object, RLMInsertionAccessorClassForObjectClass(objectClass, schema));

    // call our insertion setter to populate all properties in the table
    for (RLMProperty *prop in schema.properties) {
        // InsertionAccessr getter gets object from ivar
        id value = [object valueForKey:prop.name];
        // InsertionAccssor setter inserts into table
        [object setValue:value forKey:prop.name];
    }
    
    // we are in a read transaction so change accessor class to readwrite accessor
    object_setClass(object, RLMAccessorClassForObjectClass(objectClass, schema));
    
    // register object with the realm
    [realm registerAccessor:object];
}

void RLMDeleteObjectFromRealm(RLMObject *object) {
    // if last in table delete, otherwise replace with last
    if (object.objectIndex == object.backingTable->size() - 1) {
        object.backingTable->remove(object.objectIndex);
    }
    else {
        object.backingTable->move_last_over(object.objectIndex);
        // FIXME - fix all accessors
    }
}

RLMArray *RLMGetObjects(RLMRealm *realm, NSString *objectClassName, NSPredicate *predicate, id order) {
    // get table for this calss
    RLMArray *array = [[RLMArray alloc] initWithObjectClassName:objectClassName];
    tightdb::TableRef table = RLMTableForObjectClass(realm, objectClassName);
    array.backingTable = table.get();
    array.backingTableIndex = array.backingTable->get_index_in_parent();
    
    // create view from table and predicate
    RLMObjectSchema *schema = realm.schema[objectClassName];
    array.backingQuery = new tightdb::Query(table->where());
    RLMUpdateQueryWithPredicate(array.backingQuery, predicate, schema);
    
    // create view and sort
    tightdb::TableView view = array.backingQuery->find_all();
    RLMUpdateViewWithOrder(view, order, schema);
    array.backingView = view;
    array.realm = realm;
    [realm registerAccessor:array];
    return array;
}

// Create accessor and register with realm
RLMObject *RLMCreateObjectAccessor(RLMRealm *realm, NSString *objectClassName, NSUInteger index) {
    // get object classname to use from the schema
    Class objectClass = [realm.schema objectClassForClassName:objectClassName];
    
    // get acessor fot the object class
    Class accessorClass = RLMAccessorClassForObjectClass(objectClass, realm.schema[objectClassName]);
    RLMObject *accessor = [[accessorClass alloc] init];
    accessor.realm = realm;

    tightdb::TableRef table = RLMTableForObjectClass(realm, objectClassName);
    accessor.backingTable = table.get();
    accessor.backingTableIndex = table->get_index_in_parent();
    accessor.objectIndex = index;
    accessor.writable = (realm.transactionMode == RLMTransactionModeWrite);
    
    [accessor.realm registerAccessor:accessor];
    return accessor;
}



