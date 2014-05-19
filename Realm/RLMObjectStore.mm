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
#import "RLMObjectDescriptor.h"
#import "RLMPrivate.hpp"
#import "RLMQueryUtil.h"
#import "RLMUtil.h"

#import <objc/runtime.h>

static NSArray *s_objectClasses;
static NSMapTable *s_tableNamesForClass;

void RLMInitializeObjectStore() {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        // register accessor cache
        RLMAccessorCacheInitialize();

        // setup name mapping for object tables
        s_tableNamesForClass = [NSMapTable mapTableWithKeyOptions:NSPointerFunctionsOpaquePersonality
                                                     valueOptions:NSPointerFunctionsObjectPersonality];
        
        // load object descriptors for all RLMObject subclasses
        unsigned int numClasses;
        Class *classes = objc_copyClassList(&numClasses);
        NSMutableArray *classArray = [NSMutableArray array];
        
        // cache descriptors for all subclasses of RLMObject
        for (unsigned int i = 0; i < numClasses; i++) {
            if (RLMIsSubclass(classes[i], RLMObject.class)) {
                // add to class list
                RLMObjectDescriptor *desc = [RLMObjectDescriptor descriptorForObjectClass:classes[i]];
                [classArray addObject:desc];
                
                // set table name
                NSString *tableName = [@"class_" stringByAppendingString:NSStringFromClass(desc.objectClass)];
                [s_tableNamesForClass setObject:tableName forKey:desc.objectClass];
            }
        }
        s_objectClasses = [classArray copy];
    });
}

// get the table used to store object of objectClass
inline tightdb::TableRef RLMTableForObjectClass(RLMRealm *realm, Class objectClass) {
    NSString *name = [s_tableNamesForClass objectForKey:objectClass];
    return realm.group->get_table(tightdb::StringData(name.UTF8String, name.length));
}

void RLMEnsureRealmTablesExist(RLMRealm *realm) {
    [realm beginWriteTransaction];
    
    // FIXME - support migrations
    // first pass create tables
    for (RLMObjectDescriptor *desc in s_objectClasses) {
        tightdb::TableRef table = RLMTableForObjectClass(realm, desc.objectClass);
    }
    
    // second pass add columns
    for (RLMObjectDescriptor *desc in s_objectClasses) {
        tightdb::TableRef table = RLMTableForObjectClass(realm, desc.objectClass);
        
        if (table->get_column_count() == 0) {
            for (RLMProperty *prop in desc.properties) {
                tightdb::StringData name(prop.name.UTF8String, prop.name.length);
                if (prop.type == RLMPropertyTypeObject) {
//                    tightdb::TableRef linkTable = RLMTableForObjectClass(realm, prop.linkClass);
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
            if (table->get_column_count() != desc.properties.count) {
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
    object.realm = realm;
    object.backingTable = RLMTableForObjectClass(realm, objectClass).get();
    object.objectIndex = object.backingTable->add_empty_row();
    object.backingTableIndex = object.backingTable->get_index_in_parent();
    
    // change object class to insertion accessor
    object_setClass(object, RLMInsertionAccessorClassForObjectClass(objectClass));

    // call our insertion setter to populate all properties in the table
    RLMObjectDescriptor *desc = [RLMObjectDescriptor descriptorForObjectClass:objectClass];
    for (RLMProperty *prop in desc.properties) {
        // InsertionAccessr getter gets object from ivar
        id value = [object valueForKey:prop.name];
        // InsertionAccssor setter inserts into table
        [object setValue:value forKey:prop.name];
    }
    
    // we are in a read transaction so change accessor class to readwrite accessor
    object_setClass(object, RLMAccessorClassForObjectClass(objectClass));
    
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

RLMArray *RLMGetObjects(RLMRealm *realm, Class objectClass, NSPredicate *predicate, id order) {
    // get table for this calss
    RLMArray *array = [[RLMArray alloc] initWithObjectClass:objectClass];
    tightdb::TableRef table = RLMTableForObjectClass(realm, objectClass);
    array.backingTable = table.get();
    array.backingTableIndex = array.backingTable->get_index_in_parent();
    
    // create view from table and predicate
    RLMObjectDescriptor *desc = [RLMObjectDescriptor descriptorForObjectClass:objectClass];
    array.backingQuery = new tightdb::Query(table->where());
    RLMUpdateQueryWithPredicate(array.backingQuery, predicate, desc);
    
    // create view and sort
    tightdb::TableView view = array.backingQuery->find_all();
    RLMUpdateViewWithOrder(view, order, desc);
    array.backingView = view;
    array.realm = realm;
    [realm registerAccessor:array];
    return array;
}

// Create accessor and register with realm
RLMObject *RLMCreateObjectAccessor(RLMRealm *realm, Class objectClass, NSUInteger index) {
    Class accessorClass = RLMAccessorClassForObjectClass(objectClass);
    RLMObject *accessor = [[accessorClass alloc] init];
    accessor.realm = realm;

    tightdb::TableRef table = RLMTableForObjectClass(realm, objectClass);
    accessor.backingTable = table.get();
    accessor.backingTableIndex = table->get_index_in_parent();
    accessor.objectIndex = index;
    accessor.writable = (realm.transactionMode == RLMTransactionModeWrite);
    
    [accessor.realm registerAccessor:accessor];
    return accessor;
}



