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

#import <tightdb/table.hpp>

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
        for (int i = 0; i < numClasses; i++) {
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
                if (prop.type == RLMTypeLink) {
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
    object.backingTable = RLMTableForObjectClass(realm, object.class).get();
    object.objectIndex = object.backingTable->add_empty_row();
    object.backingTableIndex = object.backingTable->get_index_in_parent();
    
    // FIXME - can optimize by doing direct insersion
    // get all properties
    RLMObjectDescriptor *desc = [RLMObjectDescriptor descriptorForObjectClass:object.class];
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithCapacity:desc.properties.count];
    for (RLMProperty *prop in desc.properties) {
        dict[prop.name] = [object valueForKey:prop.name];
    }
    
    // change object class to accessor class (if not already)
    Class accessorClass = RLMAccessorClassForObjectClass(object.class);
    if (object.class != accessorClass) {
        object_setClass(object, accessorClass);
    }
    
    // FIXME - see last fixme
    // get all properties on the table
    object.realm = realm;
    for (NSString *key in dict) {
        [object setValue:dict[key] forKeyPath:key];
    }
    
    // set the realm and register
    [realm registerAcessor:object];
}

void RLMDeleteObjectFromRealm(RLMObject *object, RLMRealm *realm, bool cascade) {
    // if last in table delete, otherwise replace with last
    if (object.objectIndex == object.backingTable->size() - 1) {
        object.backingTable->remove(object.objectIndex);
    }
    else {
        object.backingTable->move_last_over(object.objectIndex);
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
    [realm registerAcessor:array];
    return array;
}



