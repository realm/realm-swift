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


#import <Foundation/Foundation.h>

@class RLMObject, RLMArray, RLMRealm, RLMSchema, RLMMigrationRealm, RLMNotificationToken;

typedef void(^RLMNotificationBlock)(NSString *notification, RLMRealm *realm);
typedef void (^RLMMigrationBlock)(RLMMigrationRealm *realm);


@interface RLMRealm : NSObject

/**---------------------------------------------------------------------------------------
 *  @name Creating & Initializing a Realm
 * ---------------------------------------------------------------------------------------
 */
/** 
 Obtains an instance of the default Realm.
 
 RLMRealm instances are reused when this is called multiple times from the same thread. The 
 default RLMRealm is persisted as default.realm under the Documents directory of your Application.
 
 @warning   RLMRealm instances are not thread safe and can not be shared across threads or 
            dispatch queues. You must get a separate RLMRealm instance for each thread and queue.
 
 @return The default RLMRealm instance for the current thread.
 */
+ (instancetype)defaultRealm;

/**
 Obtains an RLMRealm instance persisted at a specific file.
 
 RLMRealm instances are reused when this is called multiple times from the same thread.
 
 @warning   RLMRealm instances are not thread safe and can not be shared across threads or
 dispatch queues. You must get a separate RLMRealm instance for each thread and queue.
 
 @param path Path to the file you want the data saved in.
 
 @return An RLMRealm instance.
 */
+ (instancetype)realmWithPath:(NSString *)path;

/**
 Obtains an RLMRealm instance with persistence to a specific file with options.
 
 @warning   RLMRealm instances are not thread safe and can not be shared across threads or
 dispatch queues. You must get a separate RLMRealm instance for each thread and queue.
 
 @param path        Path to the file you want the data saved in.
 @param readonly    BOOL indicating if this Realm is readonly (must use for readonly files)
 @param error       Pass-by-reference for errors.
 
 @return An RLMRealm instance.
 */
+ (instancetype)realmWithPath:(NSString *)path readOnly:(BOOL)readonly error:(NSError **)error;

/**
 Make the default Realm in-memory only
 
 By default, the default Realm is persisted to disk unless this method is called.
 
 @warning This must be called before any Realm instances are obtained (otherwise throws).
 */
+ (void)useInMemoryDefaultRealm;

/**
 Path to the file where this Realm is persisted.
 */
@property (nonatomic, readonly) NSString *path;

/**
 Indicates if this Realm is read only
 
 @return    Boolean value indicating if this RLMRealm instance is readonly.
 */
@property (nonatomic, readonly, getter = isReadOnly) BOOL readOnly;


#pragma mark -

/**---------------------------------------------------------------------------------------
 *  @name Receiving Notification when a Realm Changes
 * ---------------------------------------------------------------------------------------
 */

/**
 Add a notification handler for changes in this RLMRealm.
 
 The block has the following definition:
 
     typedef void(^RLMNotificationBlock)(NSString *notification, RLMRealm *realm);
 
 It receives the following parameters:
 
 - `NSString` \***notification**:    The name of the incoming notification.
    RLMRealmDidChangeNotification is the only notification currently supported.
 - `RLMRealm` \***realm**:           The realm for which this notification occurred
 
 @param block   A block which is called to process RLMRealm notifications.
 
 @return A token object which can later be passed to removeNotification:.
         to remove this notification.
 */
- (RLMNotificationToken *)addNotificationBlock:(RLMNotificationBlock)block;

/**
 Remove a previously registered notification handler using the token returned
 from addNotificationBlock:
 
 @param notificationToken   The token returned from addNotificationBlock: corresponding
                            to the notification block to remove.
 */
- (void)removeNotification:(RLMNotificationToken *)notificationToken;

#pragma mark -

/**---------------------------------------------------------------------------------------
 *  @name Writing to a Realm
 * ---------------------------------------------------------------------------------------
 */

/**
 Begins a write transaction in an RLMRealm. 
 
 Only one write transaction can be open at a time. Calls to beginWriteTransaction from RLMRealm instances
 in other threads will block until the current write transaction terminates.
 
 In the case writes were made in other threads or processes to other instances of the same realm, the RLMRealm 
 on which beginWriteTransaction is called and all outstanding objects obtained from this RLMRealm are updated to
 the latest Realm version when this method is called (if this happens it will also trigger a notification).
 */
- (void)beginWriteTransaction;

/**
 Commits all writes operations in the current write transaction. 
 
 After this is called the RLMRealm reverts back to being read-only.
 */
- (void)commitWriteTransaction;

/**
 Abandon all write operations in the current write transaction terminating the transaction.
 
 After this is called the RLMRealm reverts back to being read-only.
 */
- (void)rollbackWriteTransaction;

/**
 Update an RLMRealm and oustanding objects to point to the most recent data for this RLMRealm.
 */
- (void)refresh;

/**
 Set to YES to automacially update this Realm when changes happen in other threads.

 If set to NO, you must manually call refresh on the Realm to update it to get the lastest version.
 Notifications are sent immediately when a change is available whether or not the Realm is automatically
 updated.
 
 Defaults to YES on the main thread, NO on all others.
 */
@property (nonatomic) BOOL autorefresh;

#pragma mark -

/**---------------------------------------------------------------------------------------
 *  @name Adding and Removing Objects from a Realm
 * ---------------------------------------------------------------------------------------
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
 */
- (void)deleteObject:(RLMObject *)object;


/**---------------------------------------------------------------------------------------
 *  @name Getting Objects from a Realm
 * ---------------------------------------------------------------------------------------
 */
/**
 Get all objects of a given type in this Realm.
 
 @param className   The name of the RLMObject subclass to retrieve on eg. `MyClass.className`.
 
 @return    An RLMArray of all objects in this realm of the given type.
 
 @see       RLMObject allObjects
 */
- (RLMArray *)allObjects:(NSString *)className;

/**
 Get objects matching the given predicate from the this Realm.
 
 The preferred way to get objects of a single class is to use the class methods on RLMObject.
 
 @param className   The type of objects you are looking for (name of the class).
 @param predicate   The argument can be an NSPredicate, a predicte string, or predicate format string
                    which can accept variable arguments.
 
 @return    An RLMArray of results matching the given predicate.
 
 @see       RLMObject objectsWhere:
 */
- (RLMArray *)objects:(NSString *)className where:(id)predicate, ...;

/**
 Get an ordered array of objects matching the given predicate from the this Realm.
 
 The preferred way to get objects of a single class is to use the class methods on RLMObject.
 
 @param className   The type of objects you are looking for (name of the class).
 @param order       This argument determines how the results are sorted. It can be an NSString containing
                    the property name, or an NSSortDescriptor with the property name and order.
 @param predicate   This argument can be an NSPredicate, a predicte string, or predicate format string
 which can accept variable arguments.
 
 @return    An RLMArray of results matching the predicate ordered by the given order.
 
 @see       RLMObject objectsOrderedBy:where:
 */
- (RLMArray *)objects:(NSString *)className orderedBy:(id)order where:(id)predicate, ...;

#pragma mark -

//---------------------------------------------------------------------------------------
//@name Named Object Storage and Retrieval
//---------------------------------------------------------------------------------------
//
// Realm provides a top level key/value store for storing and accessing objects by NSString.
// This system can be extended with the RLMKeyValueStore interface to create nested
// namespaces as needed.

// Retrieve a persisted object with an NSString.
// 
// @usage RLMObject * object = RLMRealm.defaultRealm[@"name"];
// @param key The NSString used to identify an object
// 
// @return    RLMObject or nil if no object is stored for the given key.
//
//-(id)objectForKeyedSubscript:(id <NSCopying>)key;


// Store an object with an NSString key.
// 
// @usage RLMRealm.defaultRealm[@"name"] = object;
// @param obj     The object to be stored.
// @param key     The key that itentifies the object to be used for future lookups.
//
//-(void)setObject:(RLMObject *)obj forKeyedSubscript:(id <NSCopying>)key;


#pragma mark -

//---------------------------------------------------------------------------------------
// @name Realm and Object Schema
//---------------------------------------------------------------------------------------
//
// Returns the schema used by this realm. This can be used to enumerate and introspect object
// types during migrations for dynamic introspection.
//
@property (nonatomic, readonly) RLMSchema *schema;

//
// The schema version for this Realm.
// 
@property (nonatomic, readonly) NSUInteger schemaVersion;

@end
