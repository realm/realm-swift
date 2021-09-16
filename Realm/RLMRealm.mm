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

#import "RLMRealm_Private.hpp"

#import "RLMAnalytics.hpp"
#import "RLMArray_Private.hpp"
#import "RLMDictionary_Private.hpp"
#import "RLMMigration_Private.h"
#import "RLMObject_Private.h"
#import "RLMObject_Private.hpp"
#import "RLMObjectSchema_Private.hpp"
#import "RLMObjectStore.h"
#import "RLMObservation.hpp"
#import "RLMProperty.h"
#import "RLMProperty_Private.h"
#import "RLMQueryUtil.hpp"
#import "RLMRealmConfiguration+Sync.h"
#import "RLMRealmConfiguration_Private.hpp"
#import "RLMRealmUtil.hpp"
#import "RLMSchema_Private.hpp"
#import "RLMSet_Private.hpp"
#import "RLMThreadSafeReference_Private.hpp"
#import "RLMUpdateChecker.hpp"
#import "RLMUtil.hpp"

#import <realm/disable_sync_to_disk.hpp>
#import <realm/object-store/impl/realm_coordinator.hpp>
#import <realm/object-store/object_store.hpp>
#import <realm/object-store/schema.hpp>
#import <realm/object-store/shared_realm.hpp>
#import <realm/object-store/thread_safe_reference.hpp>
#import <realm/object-store/util/scheduler.hpp>
#import <realm/util/scope_exit.hpp>
#import <realm/version.hpp>

#if REALM_ENABLE_SYNC
#import "RLMSyncManager_Private.hpp"
#import "RLMSyncSession_Private.hpp"
#import "RLMSyncUtil_Private.hpp"

#import <realm/object-store/sync/async_open_task.hpp>
#import <realm/object-store/sync/sync_session.hpp>
#endif

using namespace realm;
using util::File;

@interface RLMRealmNotificationToken : RLMNotificationToken
@property (nonatomic, strong) RLMRealm *realm;
@property (nonatomic, copy) RLMNotificationBlock block;
@end

@interface RLMRealm ()
@property (nonatomic, strong) NSHashTable<RLMRealmNotificationToken *> *notificationHandlers;
- (void)sendNotifications:(RLMNotification)notification;
@end

void RLMDisableSyncToDisk() {
    realm::disable_sync_to_disk();
}

static std::atomic<bool> s_set_skip_backup_attribute{true};
void RLMSetSkipBackupAttribute(bool value) {
    s_set_skip_backup_attribute = value;
}

static void RLMAddSkipBackupAttributeToItemAtPath(std::string_view path) {
    [[NSURL fileURLWithPath:@(path.data())] setResourceValue:@YES forKey:NSURLIsExcludedFromBackupKey error:nil];
}

void RLMWaitForRealmToClose(NSString *path) {
    NSString *lockfilePath = [path stringByAppendingString:@".lock"];
    File lockfile(lockfilePath.UTF8String, File::mode_Update);
    lockfile.set_fifo_path([path stringByAppendingString:@".management"].UTF8String, "lock.fifo");
    lockfile.lock_exclusive();
}

BOOL RLMIsRealmCachedAtPath(NSString *path) {
    return RLMGetAnyCachedRealmForPath([path cStringUsingEncoding:NSUTF8StringEncoding]) != nil;
}

@implementation RLMRealmNotificationToken
- (void)invalidate {
    [_realm verifyThread];
    [_realm.notificationHandlers removeObject:self];
    _realm = nil;
    _block = nil;
}

- (void)suppressNextNotification {
    // Temporarily replace the block with one which restores the old block
    // rather than producing a notification.

    // This briefly creates a retain cycle but it's fine because the block will
    // be synchronously called shortly after this method is called. Unlike with
    // collection notifications, this does not have to go through the object
    // store or do fancy things to handle transaction coalescing because it's
    // called synchronously by the obj-c code and not by the object store.
    auto notificationBlock = _block;
    _block = ^(RLMNotification, RLMRealm *) {
        _block = notificationBlock;
    };
}

- (void)dealloc {
    if (_realm || _block) {
        NSLog(@"RLMNotificationToken released without unregistering a notification. You must hold "
              @"on to the RLMNotificationToken returned from addNotificationBlock and call "
              @"-[RLMNotificationToken invalidate] when you no longer wish to receive RLMRealm notifications.");
    }
}
@end

#if !REALM_ENABLE_SYNC
@interface RLMAsyncOpenTask : NSObject
@end
@implementation RLMAsyncOpenTask
@end
#endif

static bool shouldForciblyDisableEncryption() {
    static bool disableEncryption = getenv("REALM_DISABLE_ENCRYPTION");
    return disableEncryption;
}

NSData *RLMRealmValidatedEncryptionKey(NSData *key) {
    if (shouldForciblyDisableEncryption()) {
        return nil;
    }

    if (key && key.length != 64) {
        @throw RLMException(@"Encryption key must be exactly 64 bytes long");
    }

    return key;
}

@implementation RLMRealm {
    std::mutex _collectionEnumeratorMutex;
    NSHashTable<RLMFastEnumerator *> *_collectionEnumerators;
    bool _sendingNotifications;
}

+ (void)initialize {
    static bool initialized;
    if (initialized) {
        return;
    }
    initialized = true;

    RLMCheckForUpdates();
    RLMSendAnalytics();
}

- (instancetype)initPrivate {
    self = [super init];
    return self;
}

- (BOOL)isEmpty {
    return realm::ObjectStore::is_empty(self.group);
}

- (void)verifyThread {
    try {
        _realm->verify_thread();
    }
    catch (std::exception const& e) {
        @throw RLMException(e);
    }
}

- (BOOL)inWriteTransaction {
    return _realm->is_in_transaction();
}

- (realm::Group &)group {
    return _realm->read_group();
}

- (BOOL)autorefresh {
    return _realm->auto_refresh();
}

- (void)setAutorefresh:(BOOL)autorefresh {
    try {
        _realm->set_auto_refresh(autorefresh);
    }
    catch (std::exception const& e) {
        @throw RLMException(e);
    }
}

+ (instancetype)defaultRealm {
    return [RLMRealm realmWithConfiguration:[RLMRealmConfiguration rawDefaultConfiguration] error:nil];
}

+ (instancetype)defaultRealmForQueue:(dispatch_queue_t)queue {
    return [RLMRealm realmWithConfiguration:[RLMRealmConfiguration rawDefaultConfiguration] queue:queue error:nil];
}

+ (instancetype)realmWithURL:(NSURL *)fileURL {
    RLMRealmConfiguration *configuration = [RLMRealmConfiguration defaultConfiguration];
    configuration.fileURL = fileURL;
    return [RLMRealm realmWithConfiguration:configuration error:nil];
}

static dispatch_queue_t s_async_open_queue = dispatch_queue_create("io.realm.asyncOpenDispatchQueue",
                                                                   DISPATCH_QUEUE_CONCURRENT);
void RLMSetAsyncOpenQueue(dispatch_queue_t queue) {
    s_async_open_queue = queue;
}

static RLMAsyncOpenTask *openAsync(RLMRealmConfiguration *configuration, void (^openCompletion)(ThreadSafeReference, std::exception_ptr)) {
    RLMAsyncOpenTask *ret = [RLMAsyncOpenTask new];
    dispatch_async(s_async_open_queue, ^{
        @autoreleasepool {
            Realm::Config& config = configuration.config;
            if (config.sync_config) {
#if REALM_ENABLE_SYNC
                auto task = realm::Realm::get_synchronized_realm(config);
                ret.task = task;
                task->start(openCompletion);
#else
                @throw RLMException(@"Realm was not built with sync enabled");
#endif
            }
            else {
                try {
                    openCompletion(realm::_impl::RealmCoordinator::get_coordinator(config)->get_unbound_realm(), nullptr);
                }
                catch (...) {
                    openCompletion({}, std::current_exception());
                }
            }
        }
    });
    return ret;
}

+ (RLMAsyncOpenTask *)asyncOpenWithConfiguration:(RLMRealmConfiguration *)configuration
                                   callbackQueue:(dispatch_queue_t)callbackQueue
                                        callback:(RLMAsyncOpenRealmCallback)callback {
    return openAsync(configuration, [=](ThreadSafeReference, std::exception_ptr err) {
        @autoreleasepool {
            if (err) {
                try {
                    std::rethrow_exception(err);
                }
                catch (...) {
                    NSError *error;
                    RLMRealmTranslateException(&error);
                    dispatch_async(callbackQueue, ^{
                        callback(nil, error);
                    });
                }
                return;
            }
            dispatch_async(callbackQueue, ^{
                @autoreleasepool {
                    NSError *error;
                    RLMRealm *localRealm = [RLMRealm realmWithConfiguration:configuration
                                                                      queue:callbackQueue
                                                                      error:&error];
                    callback(localRealm, error);
                }
            });
        }
    });
}

+ (RLMAsyncOpenTask *)asyncOpenWithConfiguration:(RLMRealmConfiguration *)configuration
                                        callback:(void (^)(NSError *))callback {
    return openAsync(configuration, [=](ThreadSafeReference, std::exception_ptr err) {
        @autoreleasepool {
            if (err) {
                try {
                    std::rethrow_exception(err);
                }
                catch (...) {
                    NSError *error;
                    RLMRealmTranslateException(&error);
                    callback(error);
                }
                return;
            }
            @autoreleasepool {
                callback(nil);
            }
        }
    });
}

// ARC tries to eliminate calls to autorelease when the value is then immediately
// returned, but this results in significantly different semantics between debug
// and release builds for RLMRealm, so force it to always autorelease.
static id RLMAutorelease(__unsafe_unretained id value) {
    // +1 __bridge_retained, -1 CFAutorelease
    return value ? (__bridge id)CFAutorelease((__bridge_retained CFTypeRef)value) : nil;
}

+ (instancetype)realmWithSharedRealm:(SharedRealm)sharedRealm schema:(RLMSchema *)schema {
    RLMRealm *realm = [[RLMRealm alloc] initPrivate];
    realm->_realm = sharedRealm;
    realm->_dynamic = YES;
    realm->_schema = schema;
    realm->_info = RLMSchemaInfo(realm);
    return RLMAutorelease(realm);
}

REALM_NOINLINE void RLMRealmTranslateException(NSError **error) {
    try {
        throw;
    }
    catch (RealmFileException const& ex) {
        switch (ex.kind()) {
            case RealmFileException::Kind::PermissionDenied:
                RLMSetErrorOrThrow(RLMMakeError(RLMErrorFilePermissionDenied, ex), error);
                break;
            case RealmFileException::Kind::IncompatibleLockFile: {
                NSString *err = @"Realm file is currently open in another process "
                                 "which cannot share access with this process. All "
                                 "processes sharing a single file must be the same "
                                 "architecture. For sharing files between the Realm "
                                 "Browser and an iOS simulator, this means that you "
                                 "must use a 64-bit simulator.";
                RLMSetErrorOrThrow(RLMMakeError(RLMErrorIncompatibleLockFile,
                                                File::PermissionDenied(err.UTF8String, ex.path())), error);
                break;
            }
            case RealmFileException::Kind::NotFound:
                RLMSetErrorOrThrow(RLMMakeError(RLMErrorFileNotFound, ex), error);
                break;
            case RealmFileException::Kind::Exists:
                RLMSetErrorOrThrow(RLMMakeError(RLMErrorFileExists, ex), error);
                break;
            case RealmFileException::Kind::BadHistoryError: {
                NSString *err = @"Realm file's history format is incompatible with the "
                                 "settings in the configuration object being used to open "
                                 "the Realm. Note that Realms configured for sync cannot be "
                                 "opened as non-synced Realms, and vice versa. Otherwise, the "
                                 "file may be corrupt.";
                RLMSetErrorOrThrow(RLMMakeError(RLMErrorFileAccess,
                                                File::AccessError(err.UTF8String, ex.path())), error);
                break;
            }
            case RealmFileException::Kind::AccessError:
                RLMSetErrorOrThrow(RLMMakeError(RLMErrorFileAccess, ex), error);
                break;
            case RealmFileException::Kind::FormatUpgradeRequired:
                RLMSetErrorOrThrow(RLMMakeError(RLMErrorFileFormatUpgradeRequired, ex), error);
                break;
            default:
                RLMSetErrorOrThrow(RLMMakeError(RLMErrorFail, ex), error);
                break;
        }
    }
    catch (AddressSpaceExhausted const &ex) {
        RLMSetErrorOrThrow(RLMMakeError(RLMErrorAddressSpaceExhausted, ex), error);
    }
    catch (SchemaMismatchException const& ex) {
        RLMSetErrorOrThrow(RLMMakeError(RLMErrorSchemaMismatch, ex), error);
    }
    catch (DeleteOnOpenRealmException const& ex) {
        RLMSetErrorOrThrow(RLMMakeError(RLMErrorAlreadyOpen, ex), error);
    }
    catch (std::system_error const& ex) {
        RLMSetErrorOrThrow(RLMMakeError(ex), error);
    }
    catch (const std::exception &exp) {
        RLMSetErrorOrThrow(RLMMakeError(RLMErrorFail, exp), error);
    }
}

+ (instancetype)realmWithConfiguration:(RLMRealmConfiguration *)configuration error:(NSError **)error {
    return [self realmWithConfiguration:configuration queue:nil error:error];
}

+ (instancetype)realmWithConfiguration:(RLMRealmConfiguration *)configuration
                                 queue:(dispatch_queue_t)queue
                                 error:(NSError **)error {
    bool dynamic = configuration.dynamic;
    bool cache = configuration.cache;
    bool readOnly = configuration.readOnly;

    // The main thread and main queue share a cache key of 1 so that they give
    // the same instance. Other Realms are keyed on either the thread or the queue.
    // Note that despite being a void* the cache key is not actually a pointer;
    // this is just an artifact of NSMapTable's strange API.
    void *cacheKey = reinterpret_cast<void *>(1);
    if (queue) {
        if (queue != dispatch_get_main_queue()) {
            cacheKey = (__bridge void *)queue;
        }
    }
    else {
        if (!pthread_main_np()) {
            cacheKey = pthread_self();
        }
    }

    {
        Realm::Config const& config = configuration.config;

        // try to reuse existing realm first
        if (cache || dynamic) {
            if (RLMRealm *realm = RLMGetThreadLocalCachedRealmForPath(config.path, cacheKey)) {
                auto const& old_config = realm->_realm->config();
                if (old_config.immutable() != config.immutable()
                    || old_config.read_only_alternative() != config.read_only_alternative()) {
                    @throw RLMException(@"Realm at path '%s' already opened with different read permissions", config.path.c_str());
                }
                if (old_config.in_memory != config.in_memory) {
                    @throw RLMException(@"Realm at path '%s' already opened with different inMemory settings", config.path.c_str());
                }
                if (realm->_dynamic != dynamic) {
                    @throw RLMException(@"Realm at path '%s' already opened with different dynamic settings", config.path.c_str());
                }
                if (old_config.encryption_key != config.encryption_key) {
                    @throw RLMException(@"Realm at path '%s' already opened with different encryption key", config.path.c_str());
                }
                return RLMAutorelease(realm);
            }
        }
    }

    configuration = [configuration copy];
    Realm::Config& config = configuration.config;

    RLMRealm *realm = [[self alloc] initPrivate];
    realm->_dynamic = dynamic;

    // protects the realm cache and accessors cache
    static std::mutex& initLock = *new std::mutex();
    std::lock_guard<std::mutex> lock(initLock);

    try {
        if (queue) {
            if (queue == dispatch_get_main_queue()) {
                config.scheduler = realm::util::Scheduler::make_runloop(CFRunLoopGetMain());
            }
            else {
                config.scheduler = realm::util::Scheduler::make_dispatch((__bridge void *)queue);
            }
            if (!config.scheduler->is_on_thread()) {
                throw RLMException(@"Realm opened from incorrect dispatch queue.");
            }
        }
        else {
            // If the source config was read from a Realm it may already have a
            // scheduler, and we don't want to reuse it.
            config.scheduler = nullptr;
        }
        realm->_realm = Realm::get_shared_realm(config);
    }
    catch (...) {
        RLMRealmTranslateException(error);
        return nil;
    }

    // if we have a cached realm on another thread we can skip a few steps and
    // just grab its schema
    @autoreleasepool {
        // ensure that cachedRealm doesn't end up in this thread's autorelease pool
        if (auto cachedRealm = RLMGetAnyCachedRealmForPath(config.path)) {
            realm->_realm->set_schema_subset(cachedRealm->_realm->schema());
            realm->_schema = cachedRealm.schema;
            realm->_info = cachedRealm->_info.clone(cachedRealm->_realm->schema(), realm);
        }
    }

    if (realm->_schema) { }
    else if (dynamic) {
        realm->_schema = [RLMSchema dynamicSchemaFromObjectStoreSchema:realm->_realm->schema()];
        realm->_info = RLMSchemaInfo(realm);
    }
    else {
        // set/align schema or perform migration if needed
        RLMSchema *schema = configuration.customSchema ?: RLMSchema.sharedSchema;

        Realm::MigrationFunction migrationFunction;
        auto migrationBlock = configuration.migrationBlock;
        if (migrationBlock && configuration.schemaVersion > 0) {
            migrationFunction = [=](SharedRealm old_realm, SharedRealm realm, Schema& mutableSchema) {
                RLMSchema *oldSchema = [RLMSchema dynamicSchemaFromObjectStoreSchema:old_realm->schema()];
                RLMRealm *oldRealm = [RLMRealm realmWithSharedRealm:old_realm schema:oldSchema];

                // The destination RLMRealm can't just use the schema from the
                // SharedRealm because it doesn't have information about whether or
                // not a class was defined in Swift, which effects how new objects
                // are created
                RLMRealm *newRealm = [RLMRealm realmWithSharedRealm:realm schema:schema.copy];

                [[[RLMMigration alloc] initWithRealm:newRealm oldRealm:oldRealm schema:mutableSchema] execute:migrationBlock];

                oldRealm->_realm = nullptr;
                newRealm->_realm = nullptr;
            };
        }

        try {
            realm->_realm->update_schema(schema.objectStoreCopy, config.schema_version,
                                         std::move(migrationFunction));
        }
        catch (...) {
            RLMRealmTranslateException(error);
            return nil;
        }

        realm->_schema = schema;
        realm->_info = RLMSchemaInfo(realm);
        RLMRealmCreateAccessors(realm.schema);

        if (!readOnly) {
            REALM_ASSERT(!realm->_realm->is_in_read_transaction());

            if (s_set_skip_backup_attribute) {
                RLMAddSkipBackupAttributeToItemAtPath(config.path + ".management");
                RLMAddSkipBackupAttributeToItemAtPath(config.path + ".lock");
                RLMAddSkipBackupAttributeToItemAtPath(config.path + ".note");
            }
        }
    }

    if (cache) {
        RLMCacheRealm(config.path, cacheKey, realm);
    }

    if (!readOnly) {
        realm->_realm->m_binding_context = RLMCreateBindingContext(realm);
        realm->_realm->m_binding_context->realm = realm->_realm;
    }

    return RLMAutorelease(realm);
}

+ (void)resetRealmState {
    RLMClearRealmCache();
    realm::_impl::RealmCoordinator::clear_cache();
    [RLMRealmConfiguration resetRealmConfigurationState];
}

- (void)verifyNotificationsAreSupported:(bool)isCollection {
    [self verifyThread];
    if (_realm->config().immutable()) {
        @throw RLMException(@"Read-only Realms do not change and do not have change notifications.");
    }
    if (_realm->is_frozen()) {
        @throw RLMException(@"Frozen Realms do not change and do not have change notifications.");
    }
    if (!_realm->can_deliver_notifications()) {
        @throw RLMException(@"Can only add notification blocks from within runloops.");
    }
    if (isCollection && _realm->is_in_transaction()) {
        @throw RLMException(@"Cannot register notification blocks from within write transactions.");
    }
}

- (RLMNotificationToken *)addNotificationBlock:(RLMNotificationBlock)block {
    if (!block) {
        @throw RLMException(@"The notification block should not be nil");
    }
    [self verifyNotificationsAreSupported:false];

    _realm->read_group();

    if (!_notificationHandlers) {
        _notificationHandlers = [NSHashTable hashTableWithOptions:NSPointerFunctionsWeakMemory];
    }

    RLMRealmNotificationToken *token = [[RLMRealmNotificationToken alloc] init];
    token.realm = self;
    token.block = block;
    [_notificationHandlers addObject:token];
    return token;
}

- (void)sendNotifications:(RLMNotification)notification {
    NSAssert(!_realm->config().immutable(), @"Read-only realms do not have notifications");
    if (_sendingNotifications) {
        return;
    }
    NSUInteger count = _notificationHandlers.count;
    if (count == 0) {
        return;
    }

    _sendingNotifications = true;
    auto cleanup = realm::util::make_scope_exit([&]() noexcept {
        _sendingNotifications = false;
    });

    // call this realm's notification blocks
    if (count == 1) {
        if (auto block = [_notificationHandlers.anyObject block]) {
            block(notification, self);
        }
    }
    else {
        for (RLMRealmNotificationToken *token in _notificationHandlers.allObjects) {
            if (auto block = token.block) {
                block(notification, self);
            }
        }
    }
}

- (RLMRealmConfiguration *)configuration {
    RLMRealmConfiguration *configuration = [[RLMRealmConfiguration alloc] init];
    configuration.config = _realm->config();
    configuration.dynamic = _dynamic;
    configuration.customSchema = _schema;
    return configuration;
}

- (void)beginWriteTransaction {
    [self beginWriteTransactionWithError:nil];
}

- (BOOL)beginWriteTransactionWithError:(NSError **)error {
    try {
        _realm->begin_transaction();
        return YES;
    }
    catch (...) {
        RLMRealmTranslateException(error);
        return NO;
    }
}

- (void)commitWriteTransaction {
    [self commitWriteTransaction:nil];
}

- (BOOL)commitWriteTransaction:(NSError **)error {
    return [self commitWriteTransactionWithoutNotifying:@[] error:error];
}

- (BOOL)commitWriteTransactionWithoutNotifying:(NSArray<RLMNotificationToken *> *)tokens error:(NSError **)error {
    for (RLMNotificationToken *token in tokens) {
        if (token.realm != self) {
            @throw RLMException(@"Incorrect Realm: only notifications for the Realm being modified can be skipped.");
        }
        [token suppressNextNotification];
    }

    try {
        _realm->commit_transaction();
        return YES;
    }
    catch (...) {
        RLMRealmTranslateException(error);
        return NO;
    }
}

- (void)transactionWithBlock:(__attribute__((noescape)) void(^)(void))block {
    [self transactionWithBlock:block error:nil];
}

- (BOOL)transactionWithBlock:(__attribute__((noescape)) void(^)(void))block error:(NSError **)outError {
    return [self transactionWithoutNotifying:@[] block:block error:outError];
}

- (void)transactionWithoutNotifying:(NSArray<RLMNotificationToken *> *)tokens block:(__attribute__((noescape)) void(^)(void))block {
    [self transactionWithoutNotifying:tokens block:block error:nil];
}

- (BOOL)transactionWithoutNotifying:(NSArray<RLMNotificationToken *> *)tokens block:(__attribute__((noescape)) void(^)(void))block error:(NSError **)error {
    [self beginWriteTransactionWithError:error];
    block();
    if (_realm->is_in_transaction()) {
        return [self commitWriteTransactionWithoutNotifying:tokens error:error];
    }
    return YES;
}

- (void)cancelWriteTransaction {
    try {
        _realm->cancel_transaction();
    }
    catch (std::exception &ex) {
        @throw RLMException(ex);
    }
}

- (void)invalidate {
    if (_realm->is_in_transaction()) {
        NSLog(@"WARNING: An RLMRealm instance was invalidated during a write "
              "transaction and all pending changes have been rolled back.");
    }

    [self detachAllEnumerators];

    for (auto& objectInfo : _info) {
        for (RLMObservationInfo *info : objectInfo.second.observedObjects) {
            info->willChange(RLMInvalidatedKey);
        }
    }

    _realm->invalidate();

    for (auto& objectInfo : _info) {
        for (RLMObservationInfo *info : objectInfo.second.observedObjects) {
            info->didChange(RLMInvalidatedKey);
        }
    }

    if (_realm->is_frozen()) {
        _realm->close();
    }
}

- (nullable id)resolveThreadSafeReference:(RLMThreadSafeReference *)reference {
    return [reference resolveReferenceInRealm:self];
}

/**
 Replaces all string columns in this Realm with a string enumeration column and compacts the
 database file.

 Cannot be called from a write transaction.

 Compaction will not occur if other `RLMRealm` instances exist.

 While compaction is in progress, attempts by other threads or processes to open the database will
 wait.

 Be warned that resource requirements for compaction is proportional to the amount of live data in
 the database.

 Compaction works by writing the database contents to a temporary database file and then replacing
 the database with the temporary one. The name of the temporary file is formed by appending
 `.tmp_compaction_space` to the name of the database.

 @return YES if the compaction succeeded.
 */
- (BOOL)compact {
    // compact() automatically ends the read transaction, but we need to clean
    // up cached state and send invalidated notifications when that happens, so
    // explicitly end it first unless we're in a write transaction (in which
    // case compact() will throw an exception)
    if (!_realm->is_in_transaction()) {
        [self invalidate];
    }

    try {
        return _realm->compact();
    }
    catch (std::exception const& ex) {
        @throw RLMException(ex);
    }
}

- (void)dealloc {
    if (_realm) {
        if (_realm->is_in_transaction()) {
            [self cancelWriteTransaction];
            NSLog(@"WARNING: An RLMRealm instance was deallocated during a write transaction and all "
                  "pending changes have been rolled back. Make sure to retain a reference to the "
                  "RLMRealm for the duration of the write transaction.");
        }
    }
}

- (BOOL)refresh {
    if (_realm->config().immutable()) {
        @throw RLMException(@"Read-only Realms do not change and cannot be refreshed.");
    }
    try {
        return _realm->refresh();
    }
    catch (std::exception const& e) {
        @throw RLMException(e);
    }
}

- (void)addObject:(__unsafe_unretained RLMObject *const)object {
    RLMAddObjectToRealm(object, self, RLMUpdatePolicyError);
}

- (void)addObjects:(id<NSFastEnumeration>)objects {
    for (RLMObject *obj in objects) {
        if (![obj isKindOfClass:RLMObjectBase.class]) {
            @throw RLMException(@"Cannot insert objects of type %@ with addObjects:. Only RLMObjects are supported.",
                                NSStringFromClass(obj.class));
        }
        [self addObject:obj];
    }
}

- (void)addOrUpdateObject:(RLMObject *)object {
    // verify primary key
    if (!object.objectSchema.primaryKeyProperty) {
        @throw RLMException(@"'%@' does not have a primary key and can not be updated", object.objectSchema.className);
    }

    RLMAddObjectToRealm(object, self, RLMUpdatePolicyUpdateAll);
}

- (void)addOrUpdateObjects:(id<NSFastEnumeration>)objects {
    for (RLMObject *obj in objects) {
        if (![obj isKindOfClass:RLMObjectBase.class]) {
            @throw RLMException(@"Cannot add or update objects of type %@ with addOrUpdateObjects:. Only RLMObjects are"
                                " supported.",
                                NSStringFromClass(obj.class));
        }
        [self addOrUpdateObject:obj];
    }
}

- (void)deleteObject:(RLMObject *)object {
    RLMDeleteObjectFromRealm(object, self);
}

- (void)deleteObjects:(id<NSFastEnumeration>)objects {
    id idObjects = objects;
    if ([idObjects respondsToSelector:@selector(realm)]
        && [idObjects respondsToSelector:@selector(deleteObjectsFromRealm)]) {
        if (self != (RLMRealm *)[idObjects realm]) {
            @throw RLMException(@"Can only delete objects from the Realm they belong to.");
        }
        [idObjects deleteObjectsFromRealm];
        return;
    }

    if (auto array = RLMDynamicCast<RLMArray>(objects)) {
        if (array.type != RLMPropertyTypeObject) {
            @throw RLMException(@"Cannot delete objects from RLMArray<%@>: only RLMObjects can be deleted.",
                                RLMTypeToString(array.type));
        }
    }
    else if (auto set = RLMDynamicCast<RLMSet>(objects)) {
        if (set.type != RLMPropertyTypeObject) {
            @throw RLMException(@"Cannot delete objects from RLMSet<%@>: only RLMObjects can be deleted.",
                                RLMTypeToString(set.type));
        }
    }
    else if (auto dictionary = RLMDynamicCast<RLMDictionary>(objects)) {
        if (dictionary.type != RLMPropertyTypeObject) {
            @throw RLMException(@"Cannot delete objects from RLMDictionary of type %@: only RLMObjects can be deleted.",
                                RLMTypeToString(dictionary.type));
        }
        for (RLMObject *obj in dictionary.allValues) {
            RLMDeleteObjectFromRealm(obj, self);
        }
        return;
    }
    for (RLMObject *obj in objects) {
        if (![obj isKindOfClass:RLMObjectBase.class]) {
            @throw RLMException(@"Cannot delete objects of type %@ with deleteObjects:. Only RLMObjects can be deleted.",
                                NSStringFromClass(obj.class));
        }
        RLMDeleteObjectFromRealm(obj, self);
    }
}

- (void)deleteAllObjects {
    RLMDeleteAllObjectsFromRealm(self);
}

- (RLMResults *)allObjects:(NSString *)objectClassName {
    return RLMGetObjects(self, objectClassName, nil);
}

- (RLMResults *)objects:(NSString *)objectClassName where:(NSString *)predicateFormat, ... {
    va_list args;
    va_start(args, predicateFormat);
    RLMResults *results = [self objects:objectClassName where:predicateFormat args:args];
    va_end(args);
    return results;
}

- (RLMResults *)objects:(NSString *)objectClassName where:(NSString *)predicateFormat args:(va_list)args {
    return [self objects:objectClassName withPredicate:[NSPredicate predicateWithFormat:predicateFormat arguments:args]];
}

- (RLMResults *)objects:(NSString *)objectClassName withPredicate:(NSPredicate *)predicate {
    return RLMGetObjects(self, objectClassName, predicate);
}

- (RLMObject *)objectWithClassName:(NSString *)className forPrimaryKey:(id)primaryKey {
    return RLMGetObject(self, className, primaryKey);
}

+ (uint64_t)schemaVersionAtURL:(NSURL *)fileURL encryptionKey:(NSData *)key error:(NSError **)error {
    RLMRealmConfiguration *config = [[RLMRealmConfiguration alloc] init];
    try {
        config.fileURL = fileURL;
        config.encryptionKey = RLMRealmValidatedEncryptionKey(key);

        uint64_t version = Realm::get_schema_version(config.config);
        if (version == realm::ObjectStore::NotVersioned) {
            RLMSetErrorOrThrow([NSError errorWithDomain:RLMErrorDomain code:RLMErrorFail userInfo:@{NSLocalizedDescriptionKey:@"Cannot open an uninitialized realm in read-only mode"}], error);
        }
        return version;
    }
    catch (...) {
        RLMRealmTranslateException(error);
        return RLMNotVersioned;
    }
}

+ (BOOL)performMigrationForConfiguration:(RLMRealmConfiguration *)configuration error:(NSError **)error {
    if (RLMGetAnyCachedRealmForPath(configuration.config.path)) {
        @throw RLMException(@"Cannot migrate Realms that are already open.");
    }

    NSError *localError; // Prevents autorelease
    BOOL success;
    @autoreleasepool {
        success = [RLMRealm realmWithConfiguration:configuration error:&localError] != nil;
    }
    if (!success && error) {
        *error = localError; // Must set outside pool otherwise will free anyway
    }
    return success;
}

- (RLMObject *)createObject:(NSString *)className withValue:(id)value {
    return (RLMObject *)RLMCreateObjectInRealmWithValue(self, className, value, RLMUpdatePolicyError);
}

- (BOOL)writeCopyToURL:(NSURL *)fileURL encryptionKey:(NSData *)key error:(NSError **)error {
    key = RLMRealmValidatedEncryptionKey(key);
    NSString *path = fileURL.path;

    try {
        _realm->write_copy(path.UTF8String, {static_cast<const char *>(key.bytes), key.length});
        return YES;
    }
    catch (...) {
        if (error) {
            RLMRealmTranslateException(error);
        }
        return NO;
    }

    return NO;
}

+ (BOOL)fileExistsForConfiguration:(RLMRealmConfiguration *)config {
    return [NSFileManager.defaultManager fileExistsAtPath:config.pathOnDisk];
}

+ (BOOL)deleteFilesForConfiguration:(RLMRealmConfiguration *)config error:(NSError **)error {
    bool didDeleteAny = false;
    try {
        realm::Realm::delete_files(config.config.path, &didDeleteAny);
        return didDeleteAny;
    }
    catch (realm::util::File::PermissionDenied const& e) {
        if (error) {
            *error = [NSError errorWithDomain:NSCocoaErrorDomain code:NSFileWriteNoPermissionError
                                     userInfo:@{NSLocalizedDescriptionKey: @(e.what()),
                                                NSFilePathErrorKey: @(e.get_path().c_str())}];
        }
        return didDeleteAny;
    }
    catch (...) {
        if (error) {
            RLMRealmTranslateException(error);
        }
        return didDeleteAny;
    }
}

- (BOOL)isFrozen {
    return _realm->is_frozen();
}

- (RLMRealm *)freeze {
    [self verifyThread];
    return self.isFrozen ? self : RLMGetFrozenRealmForSourceRealm(self);
}

- (RLMRealm *)thaw {
    [self verifyThread];
    return self.isFrozen ? [RLMRealm realmWithConfiguration:self.configuration error:nil] : self;
}

- (RLMRealm *)frozenCopy {
    try {
        RLMRealm *realm = [[RLMRealm alloc] initPrivate];
        realm->_realm = _realm->freeze();
        realm->_realm->set_schema_subset(_realm->schema());
        realm->_realm->read_group();
        realm->_dynamic = _dynamic;
        realm->_schema = _schema;
        realm->_info = RLMSchemaInfo(realm);
        return realm;
    }
    catch (std::exception const& e) {
        @throw RLMException(e);
    }
}

- (void)registerEnumerator:(RLMFastEnumerator *)enumerator {
    std::lock_guard lock(_collectionEnumeratorMutex);
    if (!_collectionEnumerators) {
        _collectionEnumerators = [NSHashTable hashTableWithOptions:NSPointerFunctionsWeakMemory];
    }
    [_collectionEnumerators addObject:enumerator];
}

- (void)unregisterEnumerator:(RLMFastEnumerator *)enumerator {
    std::lock_guard lock(_collectionEnumeratorMutex);
    [_collectionEnumerators removeObject:enumerator];
}

- (void)detachAllEnumerators {
    std::lock_guard lock(_collectionEnumeratorMutex);
    for (RLMFastEnumerator *enumerator in _collectionEnumerators) {
        [enumerator detach];
    }
    _collectionEnumerators = nil;
}

@end
