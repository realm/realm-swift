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

#import <Foundation/Foundation.h>

@class RLMObject, RLMArray, RLMRealm, RLMSchema, RLMMigration, RLMNotificationToken;

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

/**
 The RLMSchema used by this RLMRealm.
 */
@property (nonatomic, readonly) RLMSchema *schema;


#pragma mark - Notifications

typedef void(^RLMNotificationBlock)(NSString *notification, RLMRealm *realm);

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

#pragma mark - Transactions

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
 Helper to perform a block within a transaction.
 */
- (void)transactionWithBlock:(void(^)(void))block;

/**
 Update an RLMRealm and outstanding objects to point to the most recent data for this RLMRealm.
 */
- (void)refresh;

/**
 Set to YES to automatically update this Realm when changes happen in other threads.

 If set to NO, you must manually call refresh on the Realm to update it to get the lastest version.
 Notifications are sent immediately when a change is available whether or not the Realm is automatically
 updated.
 
 Defaults to YES on the main thread, NO on all others.
 */
@property (nonatomic) BOOL autorefresh;

#pragma mark - Accessing Objects

/**---------------------------------------------------------------------------------------
 *  @name Adding and Removing Objects from a Realm
 * ---------------------------------------------------------------------------------------
 */
/**
 Adds an object to be persisted it in this Realm.
 
 Once added, this object can be retrieved using the objectsWhere: selectors on RLMRealm and on
 subclasses of RLMObject. When added, all linked (child) objects referenced by this object will
 also be added to the Realm if they are not already in it. If linked objects already belong to a
 different Realm an exception will be thrown.
 
 @param object  Object to be added to this Realm.
 */
- (void)addObject:(RLMObject *)object;

/**
 Adds objects in the given array to be persisted it in this Realm.
 
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

/**
 Delete an NSArray or RLMArray of objects from this Realm.

 @param array  RLMArray or NSArray of RLMObjects to be deleted.
 */
- (void)deleteObjects:(id)array;

#pragma mark - Migrations

/**
 Migration block used to migrate a Realm.
 
 You are required to supply a migration block when trying to open an RLMRealm which has an
 on disk schema different from the schema defined in your object interfaces. When supplying a migration
 block it is your responsibility to enumerate and update any objects which require alteration, and to
 return the new schema version from the migration block.

 @warning   Unsuccessful migrations will throw exceptions. This will happen in the following cases
            - After applying a required migration, the schema version has not increased.
            - A new property is added to an object and not initialized during the migration. You are 
              required to either supply a default value or to manually populate added properties during
              a migration.

 @param migration   RLMMigration object used to perform the migration. The migration object allows
 you to enumerate and alter any existing objects which require migration.
 
 @param oldSchemaVersion    The schema version of the RLMRealm being migrated.
 
 @return    Schema version number for the RLMRealm after completing the migration.
 */
typedef NSUInteger (^RLMMigrationBlock)(RLMMigration *migration, NSUInteger oldSchemaVersion);

/**
 Performs a migration on the default Realm.
 
 Must be called before the default Realm is accessed (otherwise throws). If the
 default Realm is at a version other than <code>version</code>, the migration is applied.
 
 @param block       The block which migrates the Realm to the current version.
 @return            The error that occured while applying the migration if any.

 @see               RLMMigration
 */
+ (NSError *)migrateDefaultRealmWithBlock:(RLMMigrationBlock)block;

/**
 Performs a migration on a Realm at a path.
 
 Must be called before the Realm at <code>realmPath</code> is accessed (otherwise throws).
 If the Realm is at a version other than <code>version</code>, the migration is applied.
 
 @param realmPath   The path of the Realm to migrate.
 @param block       The block which migrates the Realm to the current version.
 @return            The error that occured while applying the migration if any.
 
 @see               RLMMigration
 */
+ (NSError *)migrateRealmAtPath:(NSString *)realmPath withBlock:(RLMMigrationBlock)block;


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
// @param key     The key that identifies the object to be used for future lookups.
//
//-(void)setObject:(RLMObject *)obj forKeyedSubscript:(id <NSCopying>)key;


@end

//
// Notification token - holds onto the realm and the notification block
//
@interface RLMNotificationToken : NSObject
@end
