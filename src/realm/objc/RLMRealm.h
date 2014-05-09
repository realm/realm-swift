/*************************************************************************
 *
 * TIGHTDB CONFIDENTIAL
 * __________________
 *
 *  [2011] - [2014] TightDB Inc
 *  All Rights Reserved.
 *
 * NOTICE:  All information contained herein is, and remains
 * the property of TightDB Incorporated and its suppliers,
 * if any.  The intellectual and technical concepts contained
 * herein are proprietary to TightDB Incorporated
 * and its suppliers and may be covered by U.S. and Foreign Patents,
 * patents in process, and are protected by trade secret or copyright law.
 * Dissemination of this information or reproduction of this material
 * is strictly forbidden unless prior written permission is obtained
 * from TightDB Incorporated.
 *
 **************************************************************************/

#import <Foundation/Foundation.h>

@class RLMObject;
@class RLMArray;

@interface RLMRealm : NSObject

/**---------------------------------------------------------------------------------------
 *  @name Creating & Initializing a Realm
 *  ---------------------------------------------------------------------------------------
 */
/** 
 Obtains an instance of the default Realm.
 
 RLMRealm instances are reused when this is called multiple times from the same thread. The 
 default RLMRealm is persisted at `<Application_Home>/Documents/default.realm`.
 
 @warning   RLMRealm instances are not thread safe and can not be shared accross threads or 
            dispatch queues. You must get a separate RLMRealm instance for each thread and queue.
 
 @return The default RLMRealm instance for the current thread.
 */
+ (instancetype)defaultRealm;

/**
 Obtains an RLMRealm instance persisted at a specific file.
 
 RLMRealm instances are reused when this is called multiple times from the same thread.
 
 @warning   RLMRealm instances are not thread safe and can not be shared accross threads or
 dispatch queues. You must get a separate RLMRealm instance for each thread and queue.
 
 @param path Path to the file you want the data saved in.
 
 @return An RLMRealm instance.
 */
+ (instancetype)realmWithPath:(NSString *)path;

/**
 Obtains an RLMRealm instance with persistence to a specific file with options.
 
 @warning   RLMRealm instances are not thread safe and can not be shared accross threads or
 dispatch queues. You must get a separate RLMRealm instance for each thread and queue.
 
 @param path        Path to the file you want the data saved in.
 @param path        BOOL indicating if this realm is readonly (must use for readonly files)
 @param error       Pass-by-reference for errors.
 
 @return An RLMRealm instance.
 */
+ (instancetype)realmWithPath:(NSString *)path readOnly:(BOOL)readonly error:(NSError **)error;

/**
 Sets the path used for the defualt Realm. 
 
 @warning This must be called before any Realm instances are obtained (otherwise throws).
 
 @param path    Path to the file you want the data saved in.
 */
+ (void)setDefaultRealmPath:(NSString *)path;

/**
 Returns the path used by this Realm.
 
 @return    Path to the file where this Realm is persisted.
 */
+ (NSString *)path;

/**
 Set's whether the default Realm is persisted or in-memory only
 
 By default, the default Realm is persisted to disk unless this method is called.
 
 @warning This must be called before any Realm instances are obtained (otherwise throws).
 
 @param shouldPersist   Whether the default Realm should be in-memory only or persisted to disk.
 */
+ (void)setDefaultRealmPersistence:(BOOL)shouldPersist;

/**
 Indicates if this Realm is persisted to disk.
 
 @return    Boolean value indicating if this RLMRealm is persisted.
 */
- (BOOL)isPersisted;

/**
 Indicates if this Realm is read only
 
 @return    Boolean value indicating if this RLMRealm instance is readonly.
 */
- (BOOL)isReadOnly;

@end

/**---------------------------------------------------------------------------------------
 *  @name Notifications
 *  ---------------------------------------------------------------------------------------
 */
/**
 Notification Block Type
 
 @param note    The name of the incoming notification.
 @param realm   The realm for which this notification occurred.
 */
typedef void(^RLMNotificationBlock)(NSString *note, RLMRealm *realm);

@interface RLMRealm (Notifications)
/**
 Add a notification handler for changes in this RLMRealm.
 
 @param block   A block which is called to process RLMRealm notifications. RLMRealmDidChangeNotification is the
 only notification currently supported.
 */
- (void)addNotification:(RLMNotificationBlock)block;

/**
 Remove a previously registered notification handler.
 
 @param block   The block previously passed to addNotification: to remove.
 */
- (void)removeNotification:(RLMNotificationBlock)block;

@end


/**---------------------------------------------------------------------------------------
 *  @name Writing to a Realm
 *  ---------------------------------------------------------------------------------------
 */
typedef void(^RLMWriteBlock)(RLMRealm *realm);

// interface for explicitly managing write transactions and realm refresh
@interface RLMRealm (Transactions)

/**
 Begins a write transaction in an RLMRealm. 
 
 Only one write transaction can be open at a time, and calls to beginWriteTransaction from RLMRealm instances 
 in other threads will block until the open write transaction.
 
 In the case writes were made in other threads or processes to other instances of the same realm, the RLMRealm 
 on which beginWriteTransaction is called and all outstanding objects obtained from this RLMRealm are updated to
 the latest realm version when this method is called.
 */
- (void)beginWriteTransaction;

/**
 Commits all writes operations in the current write transaction. 
 
 After this is called the RLMRealm reverts back to being read-only.
 */
- (void)commitWriteTransaction;

/**
 Abandon all write operations in the current write transaction ending the transaction.
 
 After this is called the RLMRealm reverts back to being read-only.
 */
- (void)rollbackWriteTransaction;

/**
 Update an RLMRealm and oustanding objects to point to the most recent data for this RLMRealm.
 */
- (void)refresh;

/**
 Set to YES to automacially update this realm when changes happen in other threads.

 If set to NO, you must manually call refresh on the realm to update it to get the lastest version.
 Notifications are sent immediately when a change is avaiable whether or not the realm is automatically
 updated.
 
 Defaults to YES on the main thread, NO on all others.
 */
@property (nonatomic) BOOL autorefresh;

/**
 Performs a (blocking) write transaction on the RLMRealm.
 
 @param block   A block containing the write code you want to perform.
 */
- (void)writeUsingBlock:(RLMWriteBlock)block;

@end


@interface RLMRealm (ObjectAccessors)
/**---------------------------------------------------------------------------------------
 *  @name Adding and Removing Objects from a Realm
 *  ---------------------------------------------------------------------------------------
 */
/**
 Adds an object to be persistsed it in this Realm.
 
 Once added, this object can be retrieved using the objectsWhere: selectors on RLMRealm and on
 subclasses of RLMObject. When added, all linked (child) objects referenced by this object will
 also be added to the Realm if they are not already in it. If linked objects already belong to a
 different Realm an exception will be thrown.
 
 @param object  Object to be added to this Realm.
 */
- (void)addObject:(RLMObject *)object;

/**
 Adds objects in the given array to be persistsed it in this Realm.
 
 This is the equivalent of addObject: except for an array of objects.
 
 @param array  NSArray or RLMArray of RLMObjects (or subclasses) to be added to this Realm.
 
 @see   addObject:
 */
- (void)addObjectsFromArray:(id)array;

/**
 Delete an object from this Realm.
 
 @param object  Object to be deleted from this Realm.
 @param cascade BOOL which indicates if child objects linked from object should also be deleted.
                When child objects are deleted, all other links to these objects are nullified.
 */
- (void)deleteObject:(RLMObject *)object cascade:(BOOL)deleteChildren;


/**---------------------------------------------------------------------------------------
 *  @name Getting Objects from a Realm
 *  ---------------------------------------------------------------------------------------
 */
/**
 Get objects matching the given predicate from the this Realm.
 
 In the future this method will be used to get an RLMArray with objects of mixed types. For now, you must
 specify an object type in the predicate of the form "Class = className". The preferred way to get objects
 of a single class is to use the class methods on RLMObject.
 
 @param predicate   The argument can be an NSPredicate, a predicte string, or predicate format string 
                    which can accept variable arguments.
 
 @return    An RLMArray of results matching the given predicate.
 
 @see       RLMObject objectsWhere:
 */
- (RLMArray *)objectsWhere:(id)predicate, ...;

/**
 Get an ordered array of objects matching the given predicate from the this Realm.
 
 In the future this method will be used to get an RLMArray with objects of mixed types. For now, you must
 specify an object type in the predicate of the form "Class = className". The preferred way to get objects
 of a single class is to use the class methods on RLMObject.
 
 @param order       This argument determines how the results are sorted. It can be an NSString containing
                    the property name, or an NSSortDescriptor with the property name and order.
 @param predicate   This argument can be an NSPredicate, a predicte string, or predicate format string
 which can accept variable arguments.
 
 @return    An RLMArray of results matching the predicate ordered by the given order.
 
 @see       RLMObject objectsOrderedBy:where:
 */
- (RLMArray *)objectsOrderedBy:(id)order where:(id)predicate, ...;

@end


/**---------------------------------------------------------------------------------------
 *  @name Named Object Storage and Retrieval
 *  ---------------------------------------------------------------------------------------
 */
/**
 Realm provides a top level key/value store for storing and accessing objects by NSString. This system can be
 exended with the RLMKeyValueStore interface to create nested namespaces as needed.
 */
@interface RLMRealm (NamedObjects)

/**
 Retrive a persisted object with an NSString.
 
 @usage RLMObject * object = RLMRealm.defaultRealm[@"name"];
 @param key The NSString used to identify an object
 
 @return    RLMObject or nil if no object is stored for the given key.
 */
-(id)objectForKeyedSubscript:(id <NSCopying>)key;

/**
 Store an object with an NSString key.
 
 @usage RLMRealm.defaultRealm[@"name"] = object;
 @param obj     The object to be stored.
 @param key     The key taht itentifies the object to be used for future lookups.
 */
-(void)setObject:(RLMObject *)obj forKeyedSubscript:(id <NSCopying>)key;

@end


#import "RLMMigration.h"
@interface RLMRealm (Migrations)
/**---------------------------------------------------------------------------------------
 *  @name Migrations
 *  ---------------------------------------------------------------------------------------
 */
/**
 Sets the object used for migration used to migrate all realms.
 
 Must be called before any Realm instances are retreived (otherwise throws)
 
 @return    Block used for migration.
 
 @see       RLMMigration protocol
 */
+ (void)setMigration:(id<RLMMigration>)block realmVersion:(NSUInteger)version;

@end


