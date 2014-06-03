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
@property (nonatomic, readonly) BOOL isReadOnly;

@end

/**---------------------------------------------------------------------------------------
 *  @name Notifications
 *  ---------------------------------------------------------------------------------------
 */
/**
 Notification Block Type
 
 @param notification    The name of the incoming notification.
 @param realm           The realm for which this notification occurred.
 */
typedef void(^RLMNotificationBlock)(NSString *notification, RLMRealm *realm, id context);

@interface RLMRealm (Notifications)
/**
 Add a notification handler for changes in this RLMRealm. 
 
 Both the block and context are held onto as weak references so callers must hold onto
 a reference to the block. When the block is released the notifcation is automatically 
 unregistered.
 
 @param block   A block which is called to process RLMRealm notifications.
 @param context A contexts passed into the notification block.

 */
- (void)addNotificationBlock:(RLMNotificationBlock)block context:(id)context;

@end


/**---------------------------------------------------------------------------------------
 *  @name Writing to a Realm
 *  ---------------------------------------------------------------------------------------
 */
@interface RLMRealm (Transactions)

/**
 Begins a write transaction in an RLMRealm. 
 
 Only one write transaction can be open at a time. Calls to beginWriteTransaction from RLMRealm instances
 in other threads will block until the current write transaction terminates.
 
 In the case writes were made in other threads or processes to other instances of the same realm, the RLMRealm 
 on which beginWriteTransaction is called and all outstanding objects obtained from this RLMRealm are updated to
 the latest Realm version when this method is called.
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
 Notifications are sent immediately when a change is avaiable whether or not the Realm is automatically
 updated.
 
 Defaults to YES on the main thread, NO on all others.
 */
@property (nonatomic) BOOL autorefresh;

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
 */
- (void)deleteObject:(RLMObject *)object;


/**---------------------------------------------------------------------------------------
 *  @name Getting Objects from a Realm
 *  ---------------------------------------------------------------------------------------
 */
/**
 Get all objects of a given type in this Realm.
 
 @param className   The name of the RLMObject subclass to retrieve on eg. <code>MyClass.className</code>.
 
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

@end


/**---------------------------------------------------------------------------------------
 *  @name Named Object Storage and Retrieval
 *  ---------------------------------------------------------------------------------------
 */
/**
 Realm provides a top level key/value store for storing and accessing objects by NSString. This system can be
 extended with the RLMKeyValueStore interface to create nested namespaces as needed.
 */
@interface RLMRealm (NamedObjects)

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

@end


@class RLMSchema;

@interface RLMRealm (Schema)
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


@class RLMMigrationRealm;
typedef void (^RLMMigrationBlock)(RLMMigrationRealm *realm);

@interface RLMRealm (Migrations)
/**---------------------------------------------------------------------------------------
 *  @name Realm Migrations
 *  ---------------------------------------------------------------------------------------
 */
/**
 Performs a migration on the default Realm.
 
 Must be called before the default Realm is accessed (otherwise throws). If the
 default Realm is at a version other than <code>version</code>, the migration is applied.
 
 @param version     The current schema version.
 @param block       The block which migrates the Realm to the current version.
 
 */
 // FIXME: RLMMigrationRealm is not defined yet
 // @see               RLMMigrationRealm
+ (void)ensureSchemaVersion:(NSUInteger)version usingBlock:(RLMMigrationBlock)block;

/**
 Performs a migration on a Realm at a path.
 
 Must be called before the Realm at <code>realmPath</code> is accessed (otherwise throws).
 If the Realm is at a version other than <code>version</code>, the migration is applied.
 
 @param version     The current schema version.
 @param realmPath   The path of the relm to migrate.
 @param block       The block which migrates the Realm to the current version.
 
 */
 // FIXME: RLMMigrationRealm is not defined yet
 // @see               RLMMigrationRealm
+ (void)ensureSchemaVersion:(NSUInteger)version
                     atPath:(NSString *)realmPath
                 usingBlock:(RLMMigrationBlock)block;

@end
