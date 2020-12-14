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
#import <Realm/RLMConstants.h>

@class RLMRealmConfiguration, RLMRealm, RLMObject, RLMSchema, RLMMigration, RLMNotificationToken, RLMThreadSafeReference, RLMAsyncOpenTask;

/**
 A callback block for opening Realms asynchronously.

 Returns the Realm if the open was successful, or an error otherwise.
 */
typedef void(^RLMAsyncOpenRealmCallback)(RLMRealm * _Nullable realm, NSError * _Nullable error);

NS_ASSUME_NONNULL_BEGIN

/**
 An `RLMRealm` instance (also referred to as "a Realm") represents a Realm
 database.

 Realms can either be stored on disk (see `+[RLMRealm realmWithURL:]`) or in
 memory (see `RLMRealmConfiguration`).

 `RLMRealm` instances are cached internally, and constructing equivalent `RLMRealm`
 objects (for example, by using the same path or identifier) multiple times on a single thread
 within a single iteration of the run loop will normally return the same
 `RLMRealm` object.

 If you specifically want to ensure an `RLMRealm` instance is
 destroyed (for example, if you wish to open a Realm, check some property, and
 then possibly delete the Realm file and re-open it), place the code which uses
 the Realm within an `@autoreleasepool {}` and ensure you have no other
 strong references to it.

 @warning Non-frozen `RLMRealm` instances are thread-confined and cannot be
 shared across threads or dispatch queues. Trying to do so will cause an
 exception to be thrown. You must call this method on each thread you want to
 interact with the Realm on. For dispatch queues, this means that you must call
 it in each block which is dispatched, as a queue is not guaranteed to run all
 of its blocks on the same thread.
 */

@interface RLMRealm : NSObject

#pragma mark - Creating & Initializing a Realm

/**
 Obtains an instance of the default Realm.

 The default Realm is used by the `RLMObject` class methods
 which do not take an `RLMRealm` parameter, but is otherwise not special. The
 default Realm is persisted as *default.realm* under the *Documents* directory of
 your Application on iOS, in your application's *Application Support*
 directory on macOS, and in the *Cache* directory on tvOS.

 The default Realm is created using the default `RLMRealmConfiguration`, which
 can be changed via `+[RLMRealmConfiguration setDefaultConfiguration:]`.

 @return The default `RLMRealm` instance for the current thread.
 */
+ (instancetype)defaultRealm;

/**
 Obtains an instance of the default Realm bound to the given queue.

 Rather than being confined to the thread they are opened on, queue-bound
 RLMRealms are confined to the given queue. They can be accessed from any
 thread as long as it is from within a block dispatch to the queue, and
 notifications will be delivered to the queue instead of a thread's run loop.

 Realms can only be confined to a serial queue. Queue-confined RLMRealm
 instances can be obtained when not on that queue, but attempting to do
 anything with that instance without first dispatching to the queue will throw
 an incorrect thread exception.

 The default Realm is created using the default `RLMRealmConfiguration`, which
 can be changed via `+[RLMRealmConfiguration setDefaultConfiguration:]`.

 @param queue A serial dispatch queue to confine the Realm to.
 @return The default `RLMRealm` instance for the given queue.
 */
+ (instancetype)defaultRealmForQueue:(dispatch_queue_t)queue;

/**
 Obtains an `RLMRealm` instance with the given configuration.

 @param configuration A configuration object to use when creating the Realm.
 @param error         If an error occurs, upon return contains an `NSError` object
                      that describes the problem. If you are not interested in
                      possible errors, pass in `NULL`.

 @return An `RLMRealm` instance.
 */
+ (nullable instancetype)realmWithConfiguration:(RLMRealmConfiguration *)configuration error:(NSError **)error;

/**
 Obtains an `RLMRealm` instance with the given configuration bound to the given queue.

 Rather than being confined to the thread they are opened on, queue-bound
 RLMRealms are confined to the given queue. They can be accessed from any
 thread as long as it is from within a block dispatch to the queue, and
 notifications will be delivered to the queue instead of a thread's run loop.

 Realms can only be confined to a serial queue. Queue-confined RLMRealm
 instances can be obtained when not on that queue, but attempting to do
 anything with that instance without first dispatching to the queue will throw
 an incorrect thread exception.

 @param configuration A configuration object to use when creating the Realm.
 @param queue         A serial dispatch queue to confine the Realm to.
 @param error         If an error occurs, upon return contains an `NSError` object
                      that describes the problem. If you are not interested in
                      possible errors, pass in `NULL`.

 @return An `RLMRealm` instance.
 */
+ (nullable instancetype)realmWithConfiguration:(RLMRealmConfiguration *)configuration
                                          queue:(nullable dispatch_queue_t)queue
                                          error:(NSError **)error;

/**
 Obtains an `RLMRealm` instance persisted at a specified file URL.

 @param fileURL The local URL of the file the Realm should be saved at.

 @return An `RLMRealm` instance.
 */
+ (instancetype)realmWithURL:(NSURL *)fileURL;

/**
 Asynchronously open a Realm and deliver it to a block on the given queue.

 Opening a Realm asynchronously will perform all work needed to get the Realm to
 a usable state (such as running potentially time-consuming migrations) on a
 background thread before dispatching to the given queue. In addition,
 synchronized Realms wait for all remote content available at the time the
 operation began to be downloaded and available locally.

 The Realm passed to the callback function is confined to the callback queue as
 if `-[RLMRealm realmWithConfiguration:queue:error]` was used.

 @param configuration A configuration object to use when opening the Realm.
 @param callbackQueue The serial dispatch queue on which the callback should be run.
 @param callback      A callback block. If the Realm was successfully opened,
                      it will be passed in as an argument.
                      Otherwise, an `NSError` describing what went wrong will be
                      passed to the block instead.
 */
+ (RLMAsyncOpenTask *)asyncOpenWithConfiguration:(RLMRealmConfiguration *)configuration
                                   callbackQueue:(dispatch_queue_t)callbackQueue
                                        callback:(RLMAsyncOpenRealmCallback)callback;

/**
 The `RLMSchema` used by the Realm.
 */
@property (nonatomic, readonly) RLMSchema *schema;

/**
 Indicates if the Realm is currently engaged in a write transaction.

 @warning   Do not simply check this property and then start a write transaction whenever an object needs to be
            created, updated, or removed. Doing so might cause a large number of write transactions to be created,
            degrading performance. Instead, always prefer performing multiple updates during a single transaction.
 */
@property (nonatomic, readonly) BOOL inWriteTransaction;

/**
 The `RLMRealmConfiguration` object that was used to create this `RLMRealm` instance.
 */
@property (nonatomic, readonly) RLMRealmConfiguration *configuration;

/**
 Indicates if this Realm contains any objects.
 */
@property (nonatomic, readonly) BOOL isEmpty;

/**
 Indicates if this Realm is frozen.

 @see `-[RLMRealm freeze]`
 */
@property (nonatomic, readonly, getter=isFrozen) BOOL frozen;

/**
 Returns a frozen (immutable) snapshot of this Realm.

 A frozen Realm is an immutable snapshot view of a particular version of a
 Realm's data. Unlike normal RLMRealm instances, it does not live-update to
 reflect writes made to the Realm, and can be accessed from any thread. Writing
 to a frozen Realm is not allowed, and attempting to begin a write transaction
 will throw an exception.

 All objects and collections read from a frozen Realm will also be frozen.
 */
- (RLMRealm *)freeze NS_RETURNS_RETAINED;

/**
 Returns a live reference of this Realm.

 All objects and collections read from the returned Realm will no longer be frozen.
 This method will return `self` if it is not already frozen.
 */
- (RLMRealm *)thaw;

#pragma mark - File Management

/**
 Writes a compacted and optionally encrypted copy of the Realm to the given local URL.

 The destination file cannot already exist.

 Note that if this method is called from within a write transaction, the
 *current* data is written, not the data from the point when the previous write
 transaction was committed.

 @param fileURL Local URL to save the Realm to.
 @param key     Optional 64-byte encryption key to encrypt the new file with.
 @param error   If an error occurs, upon return contains an `NSError` object
 that describes the problem. If you are not interested in
 possible errors, pass in `NULL`.

 @return `YES` if the Realm was successfully written to disk, `NO` if an error occurred.
 */
- (BOOL)writeCopyToURL:(NSURL *)fileURL encryptionKey:(nullable NSData *)key error:(NSError **)error;

/**
 Checks if the Realm file for the given configuration exists locally on disk.

 For non-synchronized, non-in-memory Realms, this is equivalent to
 `-[NSFileManager.defaultManager fileExistsAtPath:config.path]`. For
 synchronized Realms, it takes care of computing the actual path on disk based
 on the server, virtual path, and user as is done when opening the Realm.

 @param config A Realm configuration to check the existence of.
 @return YES if the Realm file for the given configuration exists on disk, NO otherwise.
 */
+ (BOOL)fileExistsForConfiguration:(RLMRealmConfiguration *)config;

/**
 Deletes the local Realm file and associated temporary files for the given configuration.

 This deletes the ".realm", ".note" and ".management" files which would be
 created by opening the Realm with the given configuration. It does not delete
 the ".lock" file (which contains no persisted data and is recreated from
 scratch every time the Realm file is opened).

 The Realm must not be currently open on any thread or in another process. If
 it is, this will return NO and report the error RLMErrorAlreadyOpen. Attempting to open
 the Realm on another thread while the deletion is happening will block (and
 then create a new Realm and open that afterwards).

 If the Realm already does not exist this will return `NO` and report the error NSFileNoSuchFileError;

 @param config A Realm configuration identifying the Realm to be deleted.
 @return YES if any files were deleted, NO otherwise.
 */
+ (BOOL)deleteFilesForConfiguration:(RLMRealmConfiguration *)config error:(NSError **)error
 __attribute__((swift_error(nonnull_error)));

#pragma mark - Notifications

/**
 The type of a block to run whenever the data within the Realm is modified.

 @see `-[RLMRealm addNotificationBlock:]`
 */
typedef void (^RLMNotificationBlock)(RLMNotification notification, RLMRealm *realm);

#pragma mark - Receiving Notification when a Realm Changes

/**
 Adds a notification handler for changes in this Realm, and returns a notification token.

 Notification handlers are called after each write transaction is committed,
 either on the current thread or other threads.

 Handler blocks are called on the same thread that they were added on, and may
 only be added on threads which are currently within a run loop. Unless you are
 specifically creating and running a run loop on a background thread, this will
 normally only be the main thread.

 The block has the following definition:

     typedef void(^RLMNotificationBlock)(RLMNotification notification, RLMRealm *realm);

 It receives the following parameters:

 - `NSString` \***notification**:    The name of the incoming notification. See
                                     `RLMRealmNotification` for information on what
                                     notifications are sent.
 - `RLMRealm` \***realm**:           The Realm for which this notification occurred.

 @param block   A block which is called to process Realm notifications.

 @return A token object which must be retained as long as you wish to continue
         receiving change notifications.
 */
- (RLMNotificationToken *)addNotificationBlock:(RLMNotificationBlock)block __attribute__((warn_unused_result));

#pragma mark - Writing to a Realm

/**
 Begins a write transaction on the Realm.

 Only one write transaction can be open at a time for each Realm file. Write
 transactions cannot be nested, and trying to begin a write transaction on a
 Realm which is already in a write transaction will throw an exception. Calls to
 `beginWriteTransaction` from `RLMRealm` instances for the same Realm file in
 other threads or other processes will block until the current write transaction
 completes or is cancelled.

 Before beginning the write transaction, `beginWriteTransaction` updates the
 `RLMRealm` instance to the latest Realm version, as if `refresh` had been
 called, and generates notifications if applicable. This has no effect if the
 Realm was already up to date.

 It is rarely a good idea to have write transactions span multiple cycles of
 the run loop, but if you do wish to do so you will need to ensure that the
 Realm participating in the write transaction is kept alive until the write
 transaction is committed.
 */
- (void)beginWriteTransaction;

/**
 Commits all write operations in the current write transaction, and ends the
 transaction.

 After saving the changes, all notification blocks registered on this specific
 `RLMRealm` instance are invoked synchronously. Notification blocks registered
 on other threads or on collections are invoked asynchronously. If you do not
 want to receive a specific notification for this write tranaction, see
 `commitWriteTransactionWithoutNotifying:error:`.

 This method can fail if there is insufficient disk space available to save the
 writes made, or due to unexpected i/o errors. This version of the method throws
 an exception when errors occur. Use the version with a `NSError` out parameter
 instead if you wish to handle errors.

 @warning This method may only be called during a write transaction.
 */
- (void)commitWriteTransaction NS_SWIFT_UNAVAILABLE("");

/**
 Commits all write operations in the current write transaction, and ends the
 transaction.

 After saving the changes, all notification blocks registered on this specific
 `RLMRealm` instance are invoked synchronously. Notification blocks registered
 on other threads or on collections are invoked asynchronously. If you do not
 want to receive a specific notification for this write tranaction, see
 `commitWriteTransactionWithoutNotifying:error:`.

 This method can fail if there is insufficient disk space available to save the
 writes made, or due to unexpected i/o errors.

 @warning This method may only be called during a write transaction.

 @param error If an error occurs, upon return contains an `NSError` object
              that describes the problem. If you are not interested in
              possible errors, pass in `NULL`.

 @return Whether the transaction succeeded.
 */
- (BOOL)commitWriteTransaction:(NSError **)error;

/**
 Commits all write operations in the current write transaction, without
 notifying specific notification blocks of the changes.

 After saving the changes, all notification blocks registered on this specific
 `RLMRealm` instance are invoked synchronously. Notification blocks registered
 on other threads or on collections are scheduled to be invoked asynchronously.

 You can skip notifiying specific notification blocks about the changes made
 in this write transaction by passing in their associated notification tokens.
 This is primarily useful when the write transaction is saving changes already
 made in the UI and you do not want to have the notification block attempt to
 re-apply the same changes.

 The tokens passed to this method must be for notifications for this specific
 `RLMRealm` instance. Notifications for different threads cannot be skipped
 using this method.

 This method can fail if there is insufficient disk space available to save the
 writes made, or due to unexpected i/o errors.

 @warning This method may only be called during a write transaction.

 @param tokens An array of notification tokens which were returned from adding
               callbacks which you do not want to be notified for the changes
               made in this write transaction.
 @param error If an error occurs, upon return contains an `NSError` object
              that describes the problem. If you are not interested in
              possible errors, pass in `NULL`.

 @return Whether the transaction succeeded.
 */
- (BOOL)commitWriteTransactionWithoutNotifying:(NSArray<RLMNotificationToken *> *)tokens error:(NSError **)error;

/**
 Reverts all writes made during the current write transaction and ends the transaction.

 This rolls back all objects in the Realm to the state they were in at the
 beginning of the write transaction, and then ends the transaction.

 This restores the data for deleted objects, but does not revive invalidated
 object instances. Any `RLMObject`s which were added to the Realm will be
 invalidated rather than becoming unmanaged.
 Given the following code:

     ObjectType *oldObject = [[ObjectType objectsWhere:@"..."] firstObject];
     ObjectType *newObject = [[ObjectType alloc] init];

     [realm beginWriteTransaction];
     [realm addObject:newObject];
     [realm deleteObject:oldObject];
     [realm cancelWriteTransaction];

 Both `oldObject` and `newObject` will return `YES` for `isInvalidated`,
 but re-running the query which provided `oldObject` will once again return
 the valid object.

 KVO observers on any objects which were modified during the transaction will
 be notified about the change back to their initial values, but no other
 notifcations are produced by a cancelled write transaction.

 @warning This method may only be called during a write transaction.
 */
- (void)cancelWriteTransaction;

/**
 Performs actions contained within the given block inside a write transaction.

 @see `[RLMRealm transactionWithoutNotifying:block:error:]`
 */
- (void)transactionWithBlock:(__attribute__((noescape)) void(^)(void))block NS_SWIFT_UNAVAILABLE("");

/**
 Performs actions contained within the given block inside a write transaction.

 @see `[RLMRealm transactionWithoutNotifying:block:error:]`
 */
- (BOOL)transactionWithBlock:(__attribute__((noescape)) void(^)(void))block error:(NSError **)error;

/**
 Performs actions contained within the given block inside a write transaction.

 @see `[RLMRealm transactionWithoutNotifying:block:error:]`
 */
- (void)transactionWithoutNotifying:(NSArray<RLMNotificationToken *> *)tokens block:(__attribute__((noescape)) void(^)(void))block;

/**
 Performs actions contained within the given block inside a write transaction.

 Write transactions cannot be nested, and trying to execute a write transaction
 on a Realm which is already participating in a write transaction will throw an
 exception. Calls to `transactionWithBlock:` from `RLMRealm` instances in other
 threads will block until the current write transaction completes.

 Before beginning the write transaction, `transactionWithBlock:` updates the
 `RLMRealm` instance to the latest Realm version, as if `refresh` had been called, and
 generates notifications if applicable. This has no effect if the Realm
 was already up to date.

 You can skip notifiying specific notification blocks about the changes made
 in this write transaction by passing in their associated notification tokens.
 This is primarily useful when the write transaction is saving changes already
 made in the UI and you do not want to have the notification block attempt to
 re-apply the same changes.

 The tokens passed to this method must be for notifications for this specific
 `RLMRealm` instance. Notifications for different threads cannot be skipped
 using this method.

 @param tokens An array of notification tokens which were returned from adding
               callbacks which you do not want to be notified for the changes
               made in this write transaction.
 @param block The block containing actions to perform.
 @param error If an error occurs, upon return contains an `NSError` object
              that describes the problem. If you are not interested in
              possible errors, pass in `NULL`.

 @return Whether the transaction succeeded.
 */
- (BOOL)transactionWithoutNotifying:(NSArray<RLMNotificationToken *> *)tokens block:(__attribute__((noescape)) void(^)(void))block error:(NSError **)error;

/**
 Updates the Realm and outstanding objects managed by the Realm to point to the
 most recent data.

 If the version of the Realm is actually changed, Realm and collection
 notifications will be sent to reflect the changes. This may take some time, as
 collection notifications are prepared on a background thread. As a result,
 calling this method on the main thread is not advisable.

 @return Whether there were any updates for the Realm. Note that `YES` may be
         returned even if no data actually changed.
 */
- (BOOL)refresh;

/**
 Set this property to `YES` to automatically update this Realm when changes
 happen in other threads.

 If set to `YES` (the default), changes made on other threads will be reflected
 in this Realm on the next cycle of the run loop after the changes are
 committed.  If set to `NO`, you must manually call `-refresh` on the Realm to
 update it to get the latest data.

 Note that by default, background threads do not have an active run loop and you
 will need to manually call `-refresh` in order to update to the latest version,
 even if `autorefresh` is set to `YES`.

 Even with this property enabled, you can still call `-refresh` at any time to
 update the Realm before the automatic refresh would occur.

 Write transactions will still always advance a Realm to the latest version and
 produce local notifications on commit even if autorefresh is disabled.

 Disabling `autorefresh` on a Realm without any strong references to it will not
 have any effect, and `autorefresh` will revert back to `YES` the next time the
 Realm is created. This is normally irrelevant as it means that there is nothing
 to refresh (as managed `RLMObject`s, `RLMArray`s, and `RLMResults` have strong
 references to the Realm that manages them), but it means that setting
 `RLMRealm.defaultRealm.autorefresh = NO` in
 `application:didFinishLaunchingWithOptions:` and only later storing Realm
 objects will not work.

 Defaults to `YES`.
 */
@property (nonatomic) BOOL autorefresh;

/**
 Invalidates all `RLMObject`s, `RLMResults`, `RLMLinkingObjects`, and `RLMArray`s managed by the Realm.

 A Realm holds a read lock on the version of the data accessed by it, so
 that changes made to the Realm on different threads do not modify or delete the
 data seen by this Realm. Calling this method releases the read lock,
 allowing the space used on disk to be reused by later write transactions rather
 than growing the file. This method should be called before performing long
 blocking operations on a background thread on which you previously read data
 from the Realm which you no longer need.

 All `RLMObject`, `RLMResults` and `RLMArray` instances obtained from this
 `RLMRealm` instance on the current thread are invalidated. `RLMObject`s and `RLMArray`s
 cannot be used. `RLMResults` will become empty. The Realm itself remains valid,
 and a new read transaction is implicitly begun the next time data is read from the Realm.

 Calling this method multiple times in a row without reading any data from the
 Realm, or before ever reading any data from the Realm, is a no-op. This method
 may not be called on a read-only Realm.
 */
- (void)invalidate;

#pragma mark - Accessing Objects

/**
 Returns the same object as the one referenced when the `RLMThreadSafeReference` was first created,
 but resolved for the current Realm for this thread. Returns `nil` if this object was deleted after
 the reference was created.

 @param reference The thread-safe reference to the thread-confined object to resolve in this Realm.

 @warning A `RLMThreadSafeReference` object must be resolved at most once.
          Failing to resolve a `RLMThreadSafeReference` will result in the source version of the
          Realm being pinned until the reference is deallocated.
          An exception will be thrown if a reference is resolved more than once.

 @warning Cannot call within a write transaction.

 @note Will refresh this Realm if the source Realm was at a later version than this one.

 @see `+[RLMThreadSafeReference referenceWithThreadConfined:]`
 */
- (nullable id)resolveThreadSafeReference:(RLMThreadSafeReference *)reference
NS_REFINED_FOR_SWIFT;

#pragma mark - Adding and Removing Objects from a Realm

/**
 Adds an object to the Realm.

 Once added, this object is considered to be managed by the Realm. It can be retrieved
 using the `objectsWhere:` selectors on `RLMRealm` and on subclasses of `RLMObject`.

 When added, all child relationships referenced by this object will also be added to
 the Realm if they are not already in it.

 If the object or any related objects are already being managed by a different Realm
 an exception will be thrown. Use `-[RLMObject createInRealm:withObject:]` to insert a copy of a managed object
 into a different Realm.

 The object to be added must be valid and cannot have been previously deleted
 from a Realm (i.e. `isInvalidated` must be `NO`).

 @warning This method may only be called during a write transaction.

 @param object  The object to be added to this Realm.
 */
- (void)addObject:(RLMObject *)object;

/**
 Adds all the objects in a collection to the Realm.

 This is the equivalent of calling `addObject:` for every object in a collection.

 @warning This method may only be called during a write transaction.

 @param objects   An enumerable collection such as `NSArray`, `RLMArray`, or `RLMResults`,
                  containing Realm objects to be added to the Realm.

 @see   `addObject:`
 */
- (void)addObjects:(id<NSFastEnumeration>)objects;

/**
 Adds or updates an existing object into the Realm.

 The object provided must have a designated primary key. If no objects exist in the Realm
 with the same primary key value, the object is inserted. Otherwise, the existing object is
 updated with any changed values.

 As with `addObject:`, the object cannot already be managed by a different
 Realm. Use `-[RLMObject createOrUpdateInRealm:withValue:]` to copy values to
 a different Realm.

 If there is a property or KVC value on `object` whose value is nil, and it corresponds
 to a nullable property on an existing object being updated, that nullable property will
 be set to nil.

 @warning This method may only be called during a write transaction.

 @param object  The object to be added or updated.
 */
- (void)addOrUpdateObject:(RLMObject *)object;

/**
 Adds or updates all the objects in a collection into the Realm.

 This is the equivalent of calling `addOrUpdateObject:` for every object in a collection.

 @warning This method may only be called during a write transaction.

 @param objects  An enumerable collection such as `NSArray`, `RLMArray`, or `RLMResults`,
                 containing Realm objects to be added to or updated within the Realm.

 @see   `addOrUpdateObject:`
 */
- (void)addOrUpdateObjects:(id<NSFastEnumeration>)objects;

/**
 Deletes an object from the Realm. Once the object is deleted it is considered invalidated.

 @warning This method may only be called during a write transaction.

 @param object  The object to be deleted.
 */
- (void)deleteObject:(RLMObject *)object;

/**
 Deletes one or more objects from the Realm.

 This is the equivalent of calling `deleteObject:` for every object in a collection.

 @warning This method may only be called during a write transaction.

 @param objects  An enumerable collection such as `NSArray`, `RLMArray`, or `RLMResults`,
                 containing objects to be deleted from the Realm.

 @see `deleteObject:`
 */
- (void)deleteObjects:(id<NSFastEnumeration>)objects;

/**
 Deletes all objects from the Realm.

 @warning This method may only be called during a write transaction.

 @see `deleteObject:`
 */
- (void)deleteAllObjects;


#pragma mark - Migrations

/**
 The type of a migration block used to migrate a Realm.

 @param migration   A `RLMMigration` object used to perform the migration. The
                    migration object allows you to enumerate and alter any
                    existing objects which require migration.

 @param oldSchemaVersion    The schema version of the Realm being migrated.
 */
typedef void (^RLMMigrationBlock)(RLMMigration *migration, uint64_t oldSchemaVersion);

/**
 Returns the schema version for a Realm at a given local URL.

 @param fileURL Local URL to a Realm file.
 @param key     64-byte key used to encrypt the file, or `nil` if it is unencrypted.
 @param error   If an error occurs, upon return contains an `NSError` object
                that describes the problem. If you are not interested in
                possible errors, pass in `NULL`.

 @return The version of the Realm at `fileURL`, or `RLMNotVersioned` if the version cannot be read.
 */
+ (uint64_t)schemaVersionAtURL:(NSURL *)fileURL encryptionKey:(nullable NSData *)key error:(NSError **)error
NS_REFINED_FOR_SWIFT;

/**
 Performs the given Realm configuration's migration block on a Realm at the given path.

 This method is called automatically when opening a Realm for the first time and does
 not need to be called explicitly. You can choose to call this method to control
 exactly when and how migrations are performed.

 @param configuration The Realm configuration used to open and migrate the Realm.
 @return              The error that occurred while applying the migration, if any.

 @see                 RLMMigration
 */
+ (BOOL)performMigrationForConfiguration:(RLMRealmConfiguration *)configuration error:(NSError **)error;

#pragma mark - Unavailable Methods

/**
 RLMRealm instances are cached internally by Realm and cannot be created directly.

 Use `+[RLMRealm defaultRealm]`, `+[RLMRealm realmWithConfiguration:error:]` or
 `+[RLMRealm realmWithURL]` to obtain a reference to an RLMRealm.
 */
- (instancetype)init __attribute__((unavailable("Use +defaultRealm, +realmWithConfiguration: or +realmWithURL:.")));

/**
 RLMRealm instances are cached internally by Realm and cannot be created directly.

 Use `+[RLMRealm defaultRealm]`, `+[RLMRealm realmWithConfiguration:error:]` or
 `+[RLMRealm realmWithURL]` to obtain a reference to an RLMRealm.
 */
+ (instancetype)new __attribute__((unavailable("Use +defaultRealm, +realmWithConfiguration: or +realmWithURL:.")));

/// :nodoc:
- (void)addOrUpdateObjectsFromArray:(id)array __attribute__((unavailable("Renamed to -addOrUpdateObjects:.")));

@end

// MARK: - RLMNotificationToken

/**
 A token which is returned from methods which subscribe to changes to a Realm.

 Change subscriptions in Realm return an `RLMNotificationToken` instance,
 which can be used to unsubscribe from the changes. You must store a strong
 reference to the token for as long as you want to continue to receive notifications.
 When you wish to stop, call the `-invalidate` method. Notifications are also stopped if
 the token is deallocated.
 */
@interface RLMNotificationToken : NSObject
/// Stops notifications for the change subscription that returned this token.
- (void)invalidate;

/// Stops notifications for the change subscription that returned this token.
- (void)stop __attribute__((unavailable("Renamed to -invalidate."))) NS_REFINED_FOR_SWIFT;
@end

NS_ASSUME_NONNULL_END
