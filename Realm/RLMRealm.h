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

@class RLMObject, RLMSchema, RLMMigration, RLMNotificationToken;

@interface RLMRealm : NSObject
/**---------------------------------------------------------------------------------------
 *  @name Creating & Initializing a Realm
 * ---------------------------------------------------------------------------------------
 */
/**
 Obtains an instance of the default Realm.

 The default Realm is used by the `RLMObject` class methods
 which do not take a `RLMRealm` parameter, but is otherwise not special. The
 default Realm is persisted as default.realm under the Documents directory of
 your Application on iOS, and in your application's Application Support
 directory on OS X.

 `RLMRealm` objects are cached internally by Realm, and calling this method
 multiple times on a single thread within a single iteration of the run loop
 will normally return the same `RLMRealm` object. If you specifically want to
 ensure a `RLMRealm` object is destroyed (for example, if you wish to open a
 Realm, check some property, and then possibly delete the Realm file and
 re-open it), place the code which uses the Realm within an `@autoreleasepool
 {}` and ensure you have no other references to it.

 @warning `RLMRealm` instances are not thread safe and can not be shared across
 threads or dispatch queues. You must call this method on each thread you want
 to interact with the Realm on. For dispatch queues, this means that you must
 call it in each block which is dispatched, as a queue is not guaranteed to run
 on a consistent thread.

 @return The default `RLMRealm` instance for the current thread.
 */
+ (instancetype)defaultRealm;

/**
 Obtains an `RLMRealm` instance persisted at a specific file.

 `RLMRealm` objects are cached internally by Realm, and calling this method
 multiple times with the same path on a single thread within a single iteration
 of the run loop on will normally return the same `RLMRealm` object.

 @warning `RLMRealm` instances are not thread safe and can not be shared across
 threads or dispatch queues. You must call this method on each thread you want
 to interact with the Realm on. For dispatch queues, this means that you must
 call it in each block which is dispatched, as a queue is not guaranteed to run
 on a consistent thread.

 @param path Path to the file you want the data saved in.

 @return An `RLMRealm` instance.
 */
+ (instancetype)realmWithPath:(NSString *)path;

/**
 Obtains an `RLMRealm` instance with persistence to a specific file with options.

 Like `realmWithPath`, but with the ability to open read-only realms and get
 errors as a `NSError` out parameter rather than exceptions.

 @warning Read-only Realms do not support changes made to the file while the
 `RLMRealm` exists. This means that you cannot open a Realm as both read-only
 and read-write at the same time. Read-only Realms should normally only be used
 on files which cannot be opened in read-write mode, and not just for enforcing
 correctness in code that should not need to write to the Realm.

 @param path        Path to the file you want the data saved in.
 @param readonly    BOOL indicating if this Realm is read-only (must use for read-only files)
 @param error       If an error occurs, upon return contains an `NSError` object
                    that describes the problem. If you are not interested in
                    possible errors, pass in `NULL`.

 @return An `RLMRealm` instance.
 */
+ (instancetype)realmWithPath:(NSString *)path readOnly:(BOOL)readonly error:(NSError **)error;

/**
 Obtains an `RLMRealm` instance for an un-persisted in-memory Realm. The identifier
 used to create this instance can be used to access the same in-memory Realm from
 multiple threads.

 Because in-memory Realms are not persisted, you must be sure to hold on to a
 reference to the `RLMRealm` object returned from this for as long as you want
 the data to last. Realm's internal cache of `RLMRealm`s will not keep the
 in-memory Realm alive across cycles of the run loop, so without a strong
 reference to the `RLMRealm` a new Realm will be created each time. Note that
 `RLMObject`s, `RLMArray`s, and `RLMResults` that refer to objects persisted in a Realm have a
 strong reference to the relevant `RLMRealm`, as do `RLMNotifcationToken`s.

 @param identifier  A string used to identify a particular in-memory Realm.

 @return An `RLMRealm` instance.
 */
+ (instancetype)inMemoryRealmWithIdentifier:(NSString *)identifier;

/**
 Path to the file where this Realm is persisted.
 */
@property (nonatomic, readonly) NSString *path;

/**
 Indicates if this Realm was opened in read-only mode.
 */
@property (nonatomic, readonly, getter = isReadOnly) BOOL readOnly;

/**
 The RLMSchema used by this RLMRealm.
 */
@property (nonatomic, readonly) RLMSchema *schema;

/**---------------------------------------------------------------------------------------
 *  @name Default Realm Path
 * ---------------------------------------------------------------------------------------
 */
/**
 Returns the location of the default Realm as a string.

 `~/Application Support/{bundle ID}/default.realm` on OS X.

 `default.realm` in your application's documents directory on iOS.

 @return Location of the default Realm.

 @see defaultRealm
 */
+ (NSString *)defaultRealmPath;

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

 - `NSString` \***notification**:    The name of the incoming notification. See
                                     RLMRealmNotification for information on what
                                     notifications are sent.
 - `RLMRealm` \***realm**:           The realm for which this notification occurred

 @param block   A block which is called to process RLMRealm notifications.

 @return A token object which can later be passed to `-removeNotification:`
         to remove this notification.
 */
- (RLMNotificationToken *)addNotificationBlock:(RLMNotificationBlock)block;

/**
 Remove a previously registered notification handler using the token returned
 from `-addNotificationBlock:`

 @param notificationToken   The token returned from `-addNotificationBlock:`
                            corresponding to the notification block to remove.
 */
- (void)removeNotification:(RLMNotificationToken *)notificationToken;

#pragma mark - Transactions

/**---------------------------------------------------------------------------------------
 *  @name Writing to a Realm
 * ---------------------------------------------------------------------------------------
 */

/**
 Begins a write transaction in an `RLMRealm`.

 Only one write transaction can be open at a time. Write transactions cannot be
 nested, and trying to begin a write transaction on a `RLMRealm` which is
 already in a write transaction with throw an exception. Calls to
 `beginWriteTransaction` from `RLMRealm` instances in other threads will block
 until the current write transaction completes.

 Before beginning the write transaction, `beginWriteTransaction` updates the
 `RLMRealm` to the latest Realm version, as if refresh was called, and
 generates notifications if applicable. This has no effect if the `RLMRealm`
 was already up to date.

 It is rarely a good idea to have write transactions span multiple cycles of
 the run loop, but if you do wish to do so you will need to ensure that the
 `RLMRealm` in the write transaction is kept alive until the write transaction
 is committed.
 */
- (void)beginWriteTransaction;

/**
 Commits all writes operations in the current write transaction.

 After this is called the `RLMRealm` reverts back to being read-only.

 Calling this when not in a write transaction will throw an exception.
 */
- (void)commitWriteTransaction;

/**
 Revert all writes made in the current write transaction and end the transaction.

 This rolls back all objects in the Realm to the state they were in at the
 beginning of the write transaction, and then ends the transaction.

 This does not reattach deleted accessors. Any `RLMObject`s which were added to
 the Realm will become deleted objects rather than switching back to standalone
 objects. Given the following code:

     ObjectType *oldObject = [[ObjectType objectsWhere:@"..."] firstObject];
     ObjectType *newObject = [[ObjectType alloc] init];

     [realm beginWriteTransaction];
     [realm addObject:newObject];
     [realm deleteObject:oldObject];
     [realm cancelWriteTransaction];

 Both `oldObject` and `newObject` will return `YES` for `isDeletedFromRealm`,
 but re-running the query which provided `oldObject` will once again return
 the valid object.

 Calling this when not in a write transaction will throw an exception.
 */
- (void)cancelWriteTransaction;

/**
 Helper to perform a block within a transaction.
 */
- (void)transactionWithBlock:(void(^)(void))block;

/**
 Update an `RLMRealm` and outstanding objects to point to the most recent data for this `RLMRealm`.

 @return    Whether the realm had any updates. Note that this may return YES even if no data has actually changed.
 */
- (BOOL)refresh;

/**
 Set to YES to automatically update this Realm when changes happen in other threads.

 If set to YES (the default), changes made on other threads will be reflected
 in this Realm on the next cycle of the run loop after the changes are
 committed.  If set to NO, you must manually call -refresh on the Realm to
 update it to get the latest version.

 Even with this enabled, you can still call -refresh at any time to update the
 Realm before the automatic refresh would occur.

 Notifications are sent when a write transaction is committed whether or not
 this is enabled.

 Disabling this on an `RLMRealm` without any strong references to it will not
 have any effect, and it will switch back to YES the next time the `RLMRealm`
 object is created. This is normally irrelevant as it means that there is
 nothing to refresh (as persisted `RLMObject`s, `RLMArray`s, and `RLMResults` have strong
 references to the containing `RLMRealm`), but it means that setting
 `RLMRealm.defaultRealm.autorefresh = NO` in
 `application:didFinishLaunchingWithOptions:` and only later storing Realm
 objects will not work.

 Defaults to YES.
 */
@property (nonatomic) BOOL autorefresh;

#pragma mark - Accessing Objects

/**---------------------------------------------------------------------------------------
 *  @name Adding and Removing Objects from a Realm
 * ---------------------------------------------------------------------------------------
 */
/**
 Adds an object to be persisted it in this Realm.

 Once added, this object can be retrieved using the `objectsWhere:` selectors
 on `RLMRealm` and on subclasses of `RLMObject`. When added, all linked (child)
 objects referenced by this object will also be added to the Realm if they are
 not already in it. If the object or any linked objects already belong to a
 different Realm an exception will be thrown. Use
 `-[RLMObject createInRealm:withObject]` to insert a copy of a persisted object
 into a different Realm.

 The object to be added cannot have been previously deleted from a Realm (i.e.
 `isDeletedFromRealm`) must be false.

 @param object  Object to be added to this Realm.
 */
- (void)addObject:(RLMObject *)object;

/**
 Adds objects in the given array to be persisted it in this Realm.

 This is the equivalent of `addObject:` except for an array of objects.

 @param array   An enumerable object such as NSArray or RLMResults which contains objects to be added to
                this Realm.

 @see   addObject:
 */
- (void)addObjects:(id<NSFastEnumeration>)array;

/**
 Adds or updates an object to be persisted it in this Realm. The object provided must have a designated
 primary key. If no objects exist in the RLMRealm instance with the same primary key value, the object is
 inserted. Otherwise, the existing object is updated with any changed values.

 As with `addObject:`, the object cannot already be persisted in a different
 Realm. Use `-[RLMObject createOrUpdateInRealm:withObject:]` to copy values to
 a different Realm.

 @param object  Object to be added or updated.
 */
- (void)addOrUpdateObject:(RLMObject *)object;

/**
 Adds or updates objects in the given array to be persisted it in this Realm.

 This is the equivalent of `addOrUpdateObject:` except for an array of objects.

 @param array  `NSArray`, `RLMArray`, or `RLMResults` of `RLMObject`s (or subclasses) to be added to this Realm.

 @see   addOrUpdateObject:
 */
- (void)addOrUpdateObjectsFromArray:(id)array;

/**
 Delete an object from this Realm.

 @param object  Object to be deleted from this Realm.
 */
- (void)deleteObject:(RLMObject *)object;

/**
 Delete an `NSArray`, `RLMArray`, or `RLMResults` of objects from this Realm.

 @param array  `RLMArray`, `NSArray`, or `RLMResults` of `RLMObject`s to be deleted.
 */
- (void)deleteObjects:(id)array;

/**
 Deletes all objects in this Realm.
 */
- (void)deleteAllObjects;


#pragma mark - Migrations

/**
 Migration block used to migrate a Realm.

 @param migration   `RLMMigration` object used to perform the migration. The
                    migration object allows you to enumerate and alter any
                    existing objects which require migration.

 @param oldSchemaVersion    The schema version of the `RLMRealm` being migrated.

 @return    Schema version number for the `RLMRealm` after completing the
            migration. Must be greater than `oldSchemaVersion`.
 */
typedef void (^RLMMigrationBlock)(RLMMigration *migration, NSUInteger oldSchemaVersion);

/**
 Specify a schema version and an associated migration block which is applied when
 opening any Realm with and old schema version.

 Before you can open an existing `RLMRealm` which has a different on-disk schema
 from the schema defined in your object interfaces you must provide a migration 
 block which converts from the disk schema to your current object schema. At the
 minimum your migration block must initialize any properties which were added to
 existing objects without defaults and ensure uniqueness if a primary key
 property is added to an existing object.

 You should call this method before accessing any `RLMRealm` instances which
 require migration. After registering your migration block Realm will call your 
 block automatically as needed.

 @warning Unsuccessful migrations will throw exceptions when the migration block
 is applied. This will happen in the following cases:

 - The migration block was run and returns a schema version which is not higher
   than the previous schema version.
 - A new property without a default was added to an object and not initialized
   during the migration. You are required to either supply a default value or to
   manually populate added properties during a migration.

 @param version     The current schema version.
 @param block       The block which migrates the Realm to the current version.
 @return            The error that occurred while applying the migration, if any.

 @see               RLMMigration
 */
+ (void)setSchemaVersion:(NSUInteger)version withMigrationBlock:(RLMMigrationBlock)block;

/**
 Performs the registered migration block on a Realm at the given path.

 This method is called automatically when opening a Realm for the first time and does
 not need to be called explicitly. You can choose to call this method to control 
 exactly when and how migrations are performed.

 @param realmPath   The path of the Realm to migrate.
 @return            The error that occurred while applying the migration if any.

 @see               RLMMigration
 @see               setSchemaVersion:withMigrationBlock:
 */
+ (NSError *)migrateRealmAtPath:(NSString *)realmPath;

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
// @usage RLMObject *object = RLMRealm.defaultRealm[@"name"];
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
