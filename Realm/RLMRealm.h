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

@class RLMObject, RLMArray, RLMRealm, RLMSchema, RLMMigrationRealm;

typedef void(^RLMNotificationBlock)(NSString *notification, RLMRealm *realm);
typedef void (^RLMMigrationBlock)(RLMMigrationRealm *realm);


@interface RLMRealm : NSObject

/**---------------------------------------------------------------------------------------
 *  @name Creating & Initializing a Realm
 * ---------------------------------------------------------------------------------------
 */
/** 
 Gets an instance of the default RLMRealm.
 
 RLMRealm instances are reused when this is called multiple times from the same thread. The 
 default RLMRealm is persisted as default.realm under the Documents directory of your Application.
 
 @warning  RLMRealm instances are not thread safe and cannot be shared across threads or 
            dispatch queues. You must create a separate RLMRealm instance for each thread and queue.
 
 @return  The default RLMRealm instance for the current thread.
 */
+ (instancetype)defaultRealm;

/**
 Creates an RLMRealm instance and persists it in the specified file.
 
 RLMRealm instances are reused when this is called multiple times from the same thread.
 
 @warning  RLMRealm instances are not thread safe and can not be shared across threads or
 dispatch queues. You must create a separate RLMRealm instance for each thread and queue.
 
 @param path  A path to the file you want the RLMRealm persisted in.
 
 @return  A persisted RLMRealm instance.
 */
+ (instancetype)realmWithPath:(NSString *)path;

/**
 Creates an RLMRealm instance and persists it in the specified file with options.
 
 @warning  RLMRealm instances are not thread safe and can not be shared across threads or
 dispatch queues. You must get a separate RLMRealm instance for each thread and queue.
 
 @param path  Path to the file you want the RLMRealm persisted in.
 @param readonly  BOOL indicating if this RLMRealm is readonly (must use for readonly files)
 @param error  A pass-by-reference for errors.
 
 @exception realm:runloop_exception  Thrown if this method is called from a thread without a runloop

 @return A persisted RLMRealm instance.
 */
+ (instancetype)realmWithPath:(NSString *)path readOnly:(BOOL)readonly error:(NSError **)error;

/**
 Specifies that the default RLMRealm will be persisted in-memory only
 
 The default RLMRealm is persisted to disk unless this method is called.
 
 @warning This must be called before any RLMRealm instances are obtained or an exception will be thrown.

 @exception 
 */
+ (void)useInMemoryDefaultRealm;

/**
 Path to the file where this RLMRealm is persisted.
 */
@property (nonatomic, readonly) NSString *path;

/**
 Indicates if this RLMRealm is read-only
 
 @return    Boolean value indicating if this RLMRealm instance is readonly.
 */
@property (nonatomic, readonly) BOOL isReadOnly;


#pragma mark -

/**---------------------------------------------------------------------------------------
 *  @name Receiving Notification when a Realm Changes
 * ---------------------------------------------------------------------------------------
 */

/**
 Adds a notification handler that will be triggered by changes in this RLMRealm.
 
 The block has the following definition:
 
     typedef void(^RLMNotificationBlock)(NSString *notification, RLMRealm *realm);
 
 It receives the following parameters:
 
 - `NSString` \***notification**:    The name of the incoming notification.
    RLMRealmDidChangeNotification is the only notification currently supported.
 - `RLMRealm` \***realm**:           The realm for which this notification occurred
 
 @param block  The RLMNotificationBlock to be called to process notifications from this RLMRealm. 
 			   RLMRealmDidChangeNotification is the only notification currently supported.
 */
- (void)addNotificationBlock:(RLMNotificationBlock)block;

/**
 Removes a notification handler from this RLMRealm.
 
 The block has the following definition:
 
     typedef void(^RLMNotificationBlock)(NSString *notification, RLMRealm *realm);
 
 It receives the following parameters:
 
 - `NSString` \***notification**:    The name of the incoming notification.
 RLMRealmDidChangeNotification is the only notification currently supported.
 - `RLMRealm` \***realm**:           The realm for which this notification occurred
 
 @param block  The RLMNotificationBlock to remove.
 */
- (void)removeNotificationBlock:(RLMNotificationBlock)block;

#pragma mark -

/**---------------------------------------------------------------------------------------
 *  @name Writing to a Realm
 * ---------------------------------------------------------------------------------------
 */

/**
 Begins a write transaction to an RLMRealm.
 
 Only one write transaction can be open at a time. Calls to beginWriteTransaction from RLMRealm instances
 in other threads will block until the current write transaction terminates.
 
 If writes were made in other threads or processes to other instances of the same RLMRealm, the RLMRealm 
 on which beginWriteTransaction is called and all outstanding objects obtained from this RLMRealm are updated to
 the latest RLMRealm version when this method is called.
 */
- (void)beginWriteTransaction;

/**
 Commits all writes operations from the current write transaction. 
 
 After this is called, the RLMRealm reverts back to being read-only.
 */
- (void)commitWriteTransaction;

/**
 Abandons all write operations in the current write transaction and terminates the transaction.
 
 After this is called, the RLMRealm reverts back to being read-only.
 */
- (void)rollbackWriteTransaction;

/**
 Updates an RLMRealm and all oustanding objects to point to the most recent data for this RLMRealm.
 */
- (void)refresh;

/**
 Set to YES to automacially update this RLMRealm when changes occur in other threads.

 Set to NO to require refresh to be manually called on the RLMRealm to update it to the lastest version.
 
 Notifications are sent immediately when a change is avaiable whether or not the RLMRealm is automatically
 updated.
 
 Defaults to YES on the main thread, and NO on all others.
 */
@property (nonatomic) BOOL autorefresh;

#pragma mark -

/**---------------------------------------------------------------------------------------
 *  @name Adding and Removing Objects from a Realm
 * ---------------------------------------------------------------------------------------
 */
/**
 Adds an object to be persistsed in this RLMRealm.
 
 Once added, this object can be retrieved using the objectsWhere: selectors on RLMRealm and on
 subclasses of RLMObject. Once added, all linked (child) objects referenced by the specified object will
 also be added to the RLMRealm if they are not already in it. If linked objects already belong to a
 different RLMRealm an exception will be thrown.
 
 @param object  An object to be added to this Realm.
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
 
 In the future this method will be used to get an RLMArray with objects of mixed types. For now, you must
 specify an object type in the predicate of the form "Class = className". The preferred way to get objects
 of a single class is to use the class methods on RLMObject.
 
 @param predicate   The argument can be an NSPredicate, a predicte string, or predicate format string 
                    which can accept variable arguments.
 
 @return    An RLMArray of results matching the given predicate.
 
 @see       RLMObject objectsWhere:
 */
- (RLMArray *)objects:(NSString *)className where:(id)predicate, ...;

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
- (RLMArray *)objects:(NSString *)className orderedBy:(id)order where:(id)predicate, ...;

#pragma mark -

/**---------------------------------------------------------------------------------------
 *  @name Named Object Storage and Retrieval
 * ---------------------------------------------------------------------------------------
 */
/**
 Realm provides a top level key/value store for storing and accessing objects by NSString. This system can be
 extended with the RLMKeyValueStore interface to create nested namespaces as needed.
 */

/**
 Retrieve a persisted object with an NSString.
 
 @usage RLMObject * object = RLMRealm.defaultRealm[@"name"];
 @param key The NSString used to identify an object
 
 @return    RLMObject or nil if no object is stored for the given key.
 */
-(id)objectForKeyedSubscript:(id <NSCopying>)key;

/**
 Store an object with an NSString key.
 
 @usage RLMRealm.defaultRealm[@"name"] = object;
 @param obj     The object to be stored.
 @param key     The key that itentifies the object to be used for future lookups.
 */
-(void)setObject:(RLMObject *)obj forKeyedSubscript:(id <NSCopying>)key;


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
