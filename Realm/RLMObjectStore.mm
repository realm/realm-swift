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

static NSMutableDictionary *s_accessorClassNameCache;
static NSArray *s_objectClasses;
static NSMapTable *s_tableNamesForClass;

inline BOOL RLMIsSubclass(Class class1, Class class2) {
    class1 = class_getSuperclass(class1);
    return RLMIsKindOfclass(class1, class2);
}

void RLMInitializeObjectStore() {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        // setup name mapping for accessor classes
        s_accessorClassNameCache = [NSMutableDictionary dictionary];
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
    for (RLMObjectDescriptor *desc in s_objectClasses) {
        tightdb::TableRef table = RLMTableForObjectClass(realm, desc.objectClass);
        
        // FIXME - support migrations
        if (table->get_column_count() == 0) {
            for (RLMProperty *prop in desc.properties) {
                table->add_column((tightdb::DataType)prop.type, tightdb::StringData(prop.name.UTF8String, prop.name.length));
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

Class RLMAccessorClassForObjectClass(Class objectClass) {
    // if objectClass is RLMRow use it, otherwise use proxy class
    if (!RLMIsKindOfclass(objectClass, RLMObject.class)) {
        @throw [NSException exceptionWithName:@"RLMException" reason:@"objectClass must derive from RLMRow" userInfo:nil];
    }
    
    // see if we have a cached version
    NSString *objectClassName = NSStringFromClass(objectClass);
    if (s_accessorClassNameCache[objectClassName]) {
        return NSClassFromString(s_accessorClassNameCache[objectClassName]);
    }
    
    // create and register proxy class which derives from object class
    NSString *proxyClassName = [@"RLMAccessor_" stringByAppendingString:objectClassName];
    Class proxyClass = objc_allocateClassPair(objectClass, proxyClassName.UTF8String, 0);
    objc_registerClassPair(proxyClass);
    
    // override getters/setters for each propery
    RLMObjectDescriptor *descriptor = [RLMObjectDescriptor descriptorForObjectClass:objectClass];
    for (unsigned int propNum = 0; propNum < descriptor.properties.count; propNum++) {
        RLMProperty *prop = descriptor.properties[propNum];
        [prop addToClass:proxyClass column:propNum];
    }
    
    // set in cache to indiate this proxy class has been created and return
    s_accessorClassNameCache[objectClassName] = proxyClassName;
    return proxyClass;
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
    for (NSString *key in dict) {
        [object setValue:dict[key] forKeyPath:key];
    }
    
    // set the realm and register
    object.realm = realm;
    [realm registerAcessor:object];
}


RLMArray *RLMGetObjects(RLMRealm *realm, Class objectClass, NSPredicate *predicate, id order) {
    // get table for this calss
    tightdb::TableRef table = RLMTableForObjectClass(realm, objectClass);
    
    // create view from table and predicate
    RLMObjectDescriptor *desc = [RLMObjectDescriptor descriptorForObjectClass:objectClass];
    tightdb::Query query = RLMUpdateQueryWithPredicate(table->where(), predicate, desc);
    tightdb::TableView view = query.find_all();
    
    // apply sort order
    RLMUpdateViewWithOrder(view, order, desc);
    
    // create array and populate
    RLMArray *array = [[RLMArray alloc] initWithObjectClass:objectClass];
    array.backingTable = table.get();
    array.backingTableIndex = array.backingTable->get_index_in_parent();
    array.backingView = view;
    
    // FIXME - we need to hold onto query or predicate for searching off of RLMArrays - this crashes now
    //array.backingQuery = query;
    array.realm = realm;
    [realm registerAcessor:array];
    return array;
}



