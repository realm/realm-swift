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
#import "RLMMigration_Private.h"
#import "RLMObjectSchema_Private.hpp"
#import "RLMObjectStore.h"
#import "RLMObject_Private.h"
#import "RLMObject_Private.hpp"
#import "RLMProperty.h"
#import "RLMQueryUtil.hpp"
#import "RLMRealmUtil.h"
#import "RLMSchema_Private.h"
#import "RLMUpdateChecker.hpp"
#import "RLMUtil.hpp"

#include "object_store.hpp"
#include <realm/commit_log.hpp>
#include <realm/disable_sync_to_disk.hpp>
#include <realm/group_shared.hpp>
#include <realm/lang_bind_helper.hpp>
#include <realm/version.hpp>

using namespace std;
using namespace realm;
using namespace realm::util;

void RLMDisableSyncToDisk() {
    realm::disable_sync_to_disk();
}

// Notification Token

@interface RLMNotificationToken ()
@property (nonatomic, strong) RLMRealm *realm;
@property (nonatomic, copy) RLMNotificationBlock block;
@end

@implementation RLMNotificationToken
- (void)dealloc
{
    if (_realm || _block) {
        NSLog(@"RLMNotificationToken released without unregistering a notification. You must hold "
              @"on to the RLMNotificationToken returned from addNotificationBlock and call "
              @"removeNotification: when you no longer wish to recieve RLMRealm notifications.");
    }
}
@end

using namespace std;
using namespace realm;
using namespace realm::util;

//
// Global encryption key cache and validation
//

static bool shouldForciblyDisableEncryption()
{
    static bool disableEncryption = getenv("REALM_DISABLE_ENCRYPTION");
    return disableEncryption;
}

static NSMutableDictionary *s_keysPerPath = [NSMutableDictionary new];
static NSData *keyForPath(NSString *path) {
    if (shouldForciblyDisableEncryption()) {
        return nil;
    }

    @synchronized (s_keysPerPath) {
        return s_keysPerPath[path];
    }
}

static void clearKeyCache() {
    @synchronized(s_keysPerPath) {
        [s_keysPerPath removeAllObjects];
    }
}

static NSData *validatedKey(NSData *key) {
    if (shouldForciblyDisableEncryption()) {
        return nil;
    }

    if (key) {
        if (key.length != 64) {
            @throw RLMException(@"Encryption key must be exactly 64 bytes long");
        }
        if (RLMIsDebuggerAttached()) {
            @throw RLMException(@"Cannot open an encrypted Realm with a debugger attached to the process");
        }
#if TARGET_OS_WATCH
        @throw RLMException(@"Cannot open an encrypted Realm on watchOS.");
#endif
    }

    return key;
}

static void setKeyForPath(NSData *key, NSString *path) {
    key = validatedKey(key);
    @synchronized (s_keysPerPath) {
        if (key) {
            s_keysPerPath[path] = key;
        }
        else {
            [s_keysPerPath removeObjectForKey:path];
        }
    }
}

//
// Schema version and migration blocks
//
static NSMutableDictionary *s_migrationBlocks = [NSMutableDictionary new];
static NSMutableDictionary *s_schemaVersions = [NSMutableDictionary new];

static NSUInteger schemaVersionForPath(NSString *path) {
    @synchronized(s_migrationBlocks) {
        NSNumber *version = s_schemaVersions[path];
        if (version) {
            return [version unsignedIntegerValue];
        }
        return 0;
    }
}

static RLMMigrationBlock migrationBlockForPath(NSString *path) {
    @synchronized(s_migrationBlocks) {
        return s_migrationBlocks[path];
    }
}

static void clearMigrationCache() {
    @synchronized(s_migrationBlocks) {
        [s_migrationBlocks removeAllObjects];
        [s_schemaVersions removeAllObjects];
    }
}

static NSString *s_defaultRealmPath = nil;
static NSString * const c_defaultRealmFileName = @"default.realm";

@implementation RLMRealm {
    // Used for read-write realms
    NSHashTable *_notificationHandlers;

    std::unique_ptr<ClientHistory> _history;
    std::unique_ptr<SharedGroup> _sharedGroup;

    // Used for read-only realms
    std::unique_ptr<Group> _readGroup;

    // Used for both
    Group *_group;
    BOOL _readOnly;
    BOOL _inMemory;
}

+ (BOOL)isCoreDebug {
    return realm::Version::has_feature(realm::feature_Debug);
}

+ (void)initialize {
    static bool initialized;
    if (initialized) {
        return;
    }
    initialized = true;

    RLMCheckForUpdates();
    RLMInstallUncaughtExceptionHandler();
    RLMSendAnalytics();
}

- (instancetype)initWithPath:(NSString *)path key:(NSData *)key readOnly:(BOOL)readonly inMemory:(BOOL)inMemory dynamic:(BOOL)dynamic error:(NSError **)outError {
    self = [super init];
    if (self) {
        _path = path;
        _threadID = pthread_mach_thread_np(pthread_self());
        _notificationHandlers = [NSHashTable hashTableWithOptions:NSPointerFunctionsWeakMemory];
        _readOnly = readonly;
        _inMemory = inMemory;
        _dynamic = dynamic;
        _autorefresh = YES;

        NSError *error = nil;
        try {
            // NOTE: we do these checks here as is this is the first time encryption keys are used
            key = validatedKey(key);

            if (readonly) {
                _readGroup = make_unique<Group>(path.UTF8String, static_cast<const char *>(key.bytes));
                _group = _readGroup.get();
            }
            else {
                _history = realm::make_client_history(path.UTF8String,
                                                      static_cast<const char *>(key.bytes));
                SharedGroup::DurabilityLevel durability = inMemory ? SharedGroup::durability_MemOnly :
                                                                     SharedGroup::durability_Full;
                _sharedGroup = make_unique<SharedGroup>(*_history, durability,
                                                        static_cast<const char *>(key.bytes));
            }
        }
        catch (File::PermissionDenied const& ex) {
            NSString *mode = readonly ? @"read" : @"read-write";
            NSString *additionalMessage = [NSString stringWithFormat:@"Unable to open a realm at path '%@'. Please use a path where your app has %@ permissions.", path, mode];
            NSString *newMessage = [NSString stringWithFormat:@"%s\n%@", ex.what(), additionalMessage];
            error = RLMMakeError(RLMErrorFilePermissionDenied,
                                     File::PermissionDenied(newMessage.UTF8String));
        }
        catch (File::Exists const& ex) {
            error = RLMMakeError(RLMErrorFileExists, ex);
        }
        catch (File::AccessError const& ex) {
            error = RLMMakeError(RLMErrorFileAccessError, ex);
        }
        catch (IncompatibleLockFile const&) {
            NSString *err = @"Realm file is currently open in another process "
                             "which cannot share access with this process. All "
                             "processes sharing a single file must be the same "
                             "architecture. For sharing files between the Realm "
                             "Browser and an iOS simulator, this means that you "
                             "must use a 64-bit simulator.";
            error = [NSError errorWithDomain:RLMErrorDomain
                                        code:RLMErrorIncompatibleLockFile
                                    userInfo:@{NSLocalizedDescriptionKey: err,
                                               @"Error Code": @(RLMErrorIncompatibleLockFile)}];
        }
        catch (exception const& ex) {
            error = RLMMakeError(RLMErrorFail, ex);
        }

        if (error) {
            RLMSetErrorOrThrow(error, outError);
            return nil;
        }

    }
    return self;
}

- (realm::Group *)getOrCreateGroup {
    if (!_group) {
        _group = &const_cast<Group&>(_sharedGroup->begin_read());
    }
    return _group;
}

+ (NSString *)defaultRealmPath
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (!s_defaultRealmPath) {
            s_defaultRealmPath = [RLMRealm writeablePathForFile:c_defaultRealmFileName];
        }
    });
    return s_defaultRealmPath;
}

+ (void)setDefaultRealmPath:(NSString *)defaultRealmPath {
    s_defaultRealmPath = defaultRealmPath;
}

+ (NSString *)writeableTemporaryPathForFile:(NSString *)fileName
{
    return [NSTemporaryDirectory() stringByAppendingPathComponent:fileName];
}

+ (NSString *)writeablePathForFile:(NSString *)fileName
{
#if TARGET_OS_IPHONE
    // On iOS the Documents directory isn't user-visible, so put files there
    NSString *path = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
#else
    // On OS X it is, so put files in Application Support. If we aren't running
    // in a sandbox, put it in a subdirectory based on the bundle identifier
    // to avoid accidentally sharing files between applications
    NSString *path = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES)[0];
    if (![[NSProcessInfo processInfo] environment][@"APP_SANDBOX_CONTAINER_ID"]) {
        NSString *identifier = [[NSBundle mainBundle] bundleIdentifier];
        if ([identifier length] == 0) {
            identifier = [[[NSBundle mainBundle] executablePath] lastPathComponent];
        }
        path = [path stringByAppendingPathComponent:identifier];

        // create directory
        [[NSFileManager defaultManager] createDirectoryAtPath:path
                                  withIntermediateDirectories:YES
                                                   attributes:nil
                                                        error:nil];
    }
#endif
    return [path stringByAppendingPathComponent:fileName];
}

+ (instancetype)defaultRealm
{
    return [RLMRealm realmWithPath:[RLMRealm defaultRealmPath] readOnly:NO error:nil];
}

+ (instancetype)realmWithPath:(NSString *)path
{
    return [self realmWithPath:path readOnly:NO error:nil];
}

+ (instancetype)realmWithPath:(NSString *)path
                     readOnly:(BOOL)readonly
                        error:(NSError **)outError
{
    return [self realmWithPath:path key:nil readOnly:readonly inMemory:NO dynamic:NO schema:nil error:outError];
}

+ (instancetype)inMemoryRealmWithIdentifier:(NSString *)identifier {
    return [self realmWithPath:[RLMRealm writeableTemporaryPathForFile:identifier] key:nil
                      readOnly:NO inMemory:YES dynamic:NO schema:nil error:nil];
}

+ (instancetype)realmWithPath:(NSString *)path
                encryptionKey:(NSData *)key
                     readOnly:(BOOL)readonly
                        error:(NSError **)error
{
    if (!key) {
        @throw RLMException(@"Encryption key must not be nil");
    }

    return [self realmWithPath:path key:key readOnly:readonly inMemory:NO dynamic:NO schema:nil error:error];
}

// ARC tries to eliminate calls to autorelease when the value is then immediately
// returned, but this results in significantly different semantics between debug
// and release builds for RLMRealm, so force it to always autorelease.
static id RLMAutorelease(id value) {
    // +1 __bridge_retained, -1 CFAutorelease
    return value ? (__bridge id)CFAutorelease((__bridge_retained CFTypeRef)value) : nil;
}

+ (instancetype)realmWithPath:(NSString *)path
                          key:(NSData *)key
                     readOnly:(BOOL)readonly
                     inMemory:(BOOL)inMemory
                      dynamic:(BOOL)dynamic
                       schema:(RLMSchema *)customSchema
                        error:(NSError **)outError
{
    if (!path || path.length == 0) {
        @throw RLMException(@"Path is not valid", @{@"path":(path ?: @"nil")});
    }

    if (![NSRunLoop currentRunLoop]) {
        @throw RLMException([NSString stringWithFormat:@"%@ \
                                               can only be called from a thread with a runloop.",
                             NSStringFromSelector(_cmd)]);
    }

    if (customSchema && !dynamic) {
        @throw RLMException(@"Custom schema only supported when using dynamic Realms");
    }

    // try to reuse existing realm first
    RLMRealm *realm = RLMGetThreadLocalCachedRealmForPath(path);
    if (realm) {
        if (realm->_readOnly != readonly) {
            @throw RLMException(@"Realm at path already opened with different read permissions", @{@"path":realm.path});
        }
        if (realm->_inMemory != inMemory) {
            @throw RLMException(@"Realm at path already opened with different inMemory settings", @{@"path":realm.path});
        }
        if (realm->_dynamic != dynamic) {
            @throw RLMException(@"Realm at path already opened with different dynamic settings", @{@"path":realm.path});
        }
        return RLMAutorelease(realm);
    }

    key = key ?: keyForPath(path);
    realm = [[RLMRealm alloc] initWithPath:path key:key readOnly:readonly inMemory:inMemory dynamic:dynamic error:outError];
    if (outError && *outError) {
        return nil;
    }

    // we need to protect the realm cache and accessors cache
    static id initLock = [NSObject new];
    @synchronized(initLock) {
        // create tables, set schema, and create accessors when needed
        if (readonly || (dynamic && !customSchema)) {
            // for readonly realms and dynamic realms without a custom schema just set the schema
            if (realm::ObjectStore::get_schema_version(realm.group) == realm::ObjectStore::NotVersioned) {
                RLMSetErrorOrThrow([NSError errorWithDomain:RLMErrorDomain code:RLMErrorFail userInfo:@{NSLocalizedDescriptionKey:@"Cannot open an uninitialized realm in read-only mode"}], outError);
                return nil;
            }
            RLMSchema *targetSchema = readonly ? [RLMSchema.sharedSchema copy] : [RLMSchema dynamicSchemaFromRealm:realm];
            RLMRealmSetSchema(realm, targetSchema, true);
            RLMRealmCreateAccessors(realm.schema);
        }
        else {
            // check cache for existing cached realms with the same path
            RLMRealm *existingRealm = RLMGetAnyCachedRealmForPath(path);
            if (existingRealm) {
                // if we have a cached realm on another thread, copy without a transaction
                RLMRealmSetSchema(realm, [existingRealm.schema shallowCopy], false);
            }
            else {
                // if we are the first realm at this path, set/align schema or perform migration if needed
                RLMSchema *targetSchema = customSchema ?: RLMSchema.sharedSchema;
                @try {
                    RLMUpdateRealmToSchemaVersion(realm, schemaVersionForPath(path), [targetSchema copy], [realm migrationBlock:key]);
                }
                @catch (NSException *exception) {
                    RLMSetErrorOrThrow(RLMMakeError(exception), outError);
                    return nil;
                }

                RLMRealmCreateAccessors(realm.schema);
            }

            // initializing the schema started a read transaction, so end it
            [realm invalidate];
        }

        if (!dynamic) {
            RLMCacheRealm(realm);
        }
    }

    if (!readonly) {
        realm.notifier = [[RLMNotifier alloc] initWithRealm:realm error:outError];
        if (!realm.notifier) {
            return nil;
        }
    }

    return RLMAutorelease(realm);
}

- (NSError *(^)())migrationBlock:(NSData *)encryptionKey {
    RLMMigrationBlock userBlock = migrationBlockForPath(_path);
    if (userBlock) {
        return ^{
            NSError *error;
            RLMMigration *migration = [[RLMMigration alloc] initWithRealm:self key:encryptionKey error:&error];
            if (error) {
                return error;
            }

            [migration execute:userBlock];
            return error;
        };
    }
    return nil;
}

+ (void)setEncryptionKey:(NSData *)key forRealmsAtPath:(NSString *)path {
    @synchronized (s_keysPerPath) {
        if (RLMGetAnyCachedRealmForPath(path)) {
            NSData *existingKey = keyForPath(path);
            if (!(existingKey == key || [existingKey isEqual:key])) {
                @throw RLMException(@"Cannot set encryption key for Realms that are already open.");
            }
        }

        setKeyForPath(key, path);
    }
}

+ (void)resetRealmState {
    clearMigrationCache();
    clearKeyCache();
    RLMClearRealmCache();
    s_defaultRealmPath = [RLMRealm writeablePathForFile:c_defaultRealmFileName];
}

static void CheckReadWrite(RLMRealm *realm, NSString *msg=@"Cannot write to a read-only Realm") {
    if (realm->_readOnly) {
        @throw RLMException(msg);
    }
}

- (RLMNotificationToken *)addNotificationBlock:(RLMNotificationBlock)block {
    RLMCheckThread(self);
    CheckReadWrite(self, @"Read-only Realms do not change and do not have change notifications");
    if (!block) {
        @throw RLMException(@"The notification block should not be nil");
    }

    RLMNotificationToken *token = [[RLMNotificationToken alloc] init];
    token.realm = self;
    token.block = block;
    [_notificationHandlers addObject:token];
    return token;
}

- (void)removeNotification:(RLMNotificationToken *)token {
    RLMCheckThread(self);
    if (token) {
        [_notificationHandlers removeObject:token];
        token.realm = nil;
        token.block = nil;
    }
}

- (void)sendNotifications:(NSString *)notification {
    NSAssert(!_readOnly, @"Read-only realms do not have notifications");

    // call this realms notification blocks
    for (RLMNotificationToken *token in [_notificationHandlers allObjects]) {
        if (token.block) {
            token.block(notification, self);
        }
    }
}

- (void)beginWriteTransaction {
    CheckReadWrite(self);
    RLMCheckThread(self);

    if (!self.inWriteTransaction) {
        try {
            // if the upgrade to write will move the transaction forward,
            // announce the change after promoting
            bool announce = _sharedGroup->has_changed();

            // begin the read transaction if needed
            [self getOrCreateGroup];

            LangBindHelper::promote_to_write(*_sharedGroup, *_history);

            // update state and make all objects in this realm writable
            _inWriteTransaction = YES;

            if (announce) {
                [self sendNotifications:RLMRealmDidChangeNotification];
            }
        }
        catch (std::exception& ex) {
            // File access errors are treated as exceptions here since they should not occur after the shared
            // group has already been successfully opened on the file and memory mapped. The shared group constructor handles
            // the excepted error related to file access.
            @throw RLMException(ex);
        }
    } else {
        @throw RLMException(@"The Realm is already in a write transaction");
    }
}

- (void)commitWriteTransaction {
    CheckReadWrite(self);
    RLMCheckThread(self);

    if (self.inWriteTransaction) {
        try {
            LangBindHelper::commit_and_continue_as_read(*_sharedGroup);

            // update state and make all objects in this realm read-only
            _inWriteTransaction = NO;

            // notify other realm instances of changes
            [self.notifier notifyOtherRealms];

            // send local notification
            [self sendNotifications:RLMRealmDidChangeNotification];
        }
        catch (std::exception& ex) {
            @throw RLMException(ex);
        }
    } else {
       @throw RLMException(@"Can't commit a non-existing write transaction");
    }
}

- (void)transactionWithBlock:(void(^)(void))block {
    [self beginWriteTransaction];
    block();
    if (_inWriteTransaction) {
        [self commitWriteTransaction];
    }
}

- (void)cancelWriteTransaction {
    CheckReadWrite(self);
    RLMCheckThread(self);

    if (self.inWriteTransaction) {
        try {
            call_with_notifications(_sharedGroup.get(), *_history, _schema, [](auto&&... args) {
                LangBindHelper::rollback_and_continue_as_read(args...);
            });
            _inWriteTransaction = NO;
        }
        catch (std::exception& ex) {
            @throw RLMException(ex);
        }
    } else {
        @throw RLMException(@"Can't cancel a non-existing write transaction");
    }
}

- (void)invalidate {
    RLMCheckThread(self);
    CheckReadWrite(self, @"Cannot invalidate a read-only realm");

    if (_inWriteTransaction) {
        NSLog(@"WARNING: An RLMRealm instance was invalidated during a write "
              "transaction and all pending changes have been rolled back.");
        [self cancelWriteTransaction];
    }
    if (!_group) {
        // Nothing to do if the read transaction hasn't been begun
        return;
    }

    _sharedGroup->end_read();
    _group = nullptr;
    for (RLMObjectSchema *objectSchema in _schema.objectSchema) {
        objectSchema.table = nullptr;
    }
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
- (BOOL)compact
{
    RLMCheckThread(self);
    BOOL compactSucceeded = NO;
    if (!_inWriteTransaction) {
        try {
            for (RLMObjectSchema *objectSchema in _schema.objectSchema) {
                objectSchema.table->optimize();
            }
            _sharedGroup->end_read();
            compactSucceeded = _sharedGroup->compact();
            _sharedGroup->begin_read();
        }
        catch (std::exception& ex) {
            @throw RLMException(ex);
        }
    } else {
        @throw RLMException(@"Can't compact a Realm within a write transaction");
    }
    return compactSucceeded;
}

- (void)dealloc {
    if (_inWriteTransaction) {
        [self cancelWriteTransaction];
        NSLog(@"WARNING: An RLMRealm instance was deallocated during a write transaction and all "
              "pending changes have been rolled back. Make sure to retain a reference to the "
              "RLMRealm for the duration of the write transaction.");
    }
    [_notifier stop];
}

struct ObserverState {
    size_t table;
    size_t row;
    size_t column;
    NSString *key;
    RLMObservationInfo2 *observable;

    bool changed = false;
    bool multipleLinkviewChanges = false;
    NSKeyValueChange linkviewChangeKind = NSKeyValueChangeSetting;
    NSMutableIndexSet *linkviewChangeIndexes;
};

class ModifiedRowParser {
    size_t current_table = 0;
    std::vector<ObserverState>& observers;
    ObserverState *active_linklist = nullptr;

public:
    ModifiedRowParser(std::vector<ObserverState>& observers) : observers(observers) { }

    void parse_complete() {
        for (auto const& o : observers) {
            if (o.row == realm::not_found) {
                if (o.column == realm::npos)
                    for_each(o.observable, [&](auto obj) { [obj willChangeValueForKey:o.key]; });
                else {
                    o.observable->setReturnNil(false);
                    for_each(o.observable, [&](auto obj) { [obj willChangeValueForKey:o.key]; });
                    o.observable->setReturnNil(true);
                    for_each(o.observable, [&](auto obj) { [obj didChangeValueForKey:o.key]; });
                }
            }
            if (!o.changed)
                continue;
            if (!o.linkviewChangeIndexes)
                for_each(o.observable, [&](auto obj) { [obj willChangeValueForKey:o.key]; });
            else {
                for_each(o.observable, [&](auto obj) {
                    [obj willChange:o.linkviewChangeKind valuesAtIndexes:o.linkviewChangeIndexes forKey:o.key];
                });
            }
        }
    }

    // These would require having an observer before schema init
    // Maybe do something here to throw an error when multiple processes have different schemas?
    bool insert_group_level_table(size_t, size_t, StringData) noexcept { return false; }
    bool erase_group_level_table(size_t, size_t) noexcept { return false; }
    bool rename_group_level_table(size_t, StringData) noexcept { return false; }
    bool insert_column(size_t, DataType, StringData, bool) { return false; }
    bool insert_link_column(size_t, DataType, StringData, size_t, size_t) { return false; }
    bool erase_column(size_t) { return false; }
    bool erase_link_column(size_t, size_t, size_t) { return false; }
    bool rename_column(size_t, StringData) { return false; }
    bool add_search_index(size_t) { return false; }
    bool remove_search_index(size_t) { return false; }
    bool add_primary_key(size_t) { return false; }
    bool remove_primary_key() { return false; }
    bool set_link_type(size_t, LinkType) { return false; }

    bool select_table(size_t group_level_ndx, int, const size_t*) noexcept {
        current_table = group_level_ndx;
        return true;
    }

    bool insert_empty_rows(size_t, size_t, size_t, bool) {
        // rows are only inserted at the end, so no need to do anything
        return true;
    }

    bool erase_rows(size_t row_ndx, size_t, size_t last_row_ndx, bool unordered) noexcept {
        for (auto& o : observers) {
            if (o.table == current_table) {
                if (o.row == row_ndx) {
                    o.row = realm::npos;
                    o.changed = false;
                }
                else if (unordered && o.row == last_row_ndx) {
                    o.row = row_ndx;
                }
                else if (!unordered && o.row > row_ndx && o.row != realm::npos) {
                    o.row -= 1;
                }
            }
        }
        return true;
    }

    bool clear_table() noexcept {
        for (auto& o : observers) {
            if (o.table == current_table) {
                o.row = realm::npos;
                o.changed = false;
            }
        }
        return true;
    }

    bool select_link_list(size_t col, size_t row) {
        active_linklist = nullptr;
        for (auto& o : observers) {
            if (o.table == current_table && o.row == row && o.column == col) {
                active_linklist = &o;
                break;
            }
        }
        return true;
    }

    void append_link_list_change(NSKeyValueChange kind, NSUInteger index) {
        if (ObserverState *o = active_linklist) {
            if (o->multipleLinkviewChanges)
                return;
            if (!o->linkviewChangeIndexes) {
                o->linkviewChangeIndexes = [NSMutableIndexSet indexSetWithIndex:index];
                o->linkviewChangeKind = kind;
                o->changed = true;
            }
            else if (o->linkviewChangeKind == kind) {
                if (kind == NSKeyValueChangeRemoval) {
                    NSUInteger i = [o->linkviewChangeIndexes firstIndex];
                    while (i <= index) {
                        ++index;
                        i = [o->linkviewChangeIndexes indexGreaterThanIndex:i];
                    }
                }
                else if (kind == NSKeyValueChangeInsertion) {
                    [o->linkviewChangeIndexes shiftIndexesStartingAtIndex:index by:1];
                }
                [o->linkviewChangeIndexes addIndex:index];
            }
            else {
                o->multipleLinkviewChanges = false;
                o->linkviewChangeIndexes = nil;
            }
        }

    }

    bool link_list_set(size_t index, size_t) {
        append_link_list_change(NSKeyValueChangeReplacement, index);
        return true;
    }

    bool link_list_insert(size_t index, size_t) {
        append_link_list_change(NSKeyValueChangeInsertion, index);
        return true;
    }

    bool link_list_erase(size_t index) {
        append_link_list_change(NSKeyValueChangeRemoval, index);
        return true;
    }

    bool link_list_nullify(size_t index) {
        append_link_list_change(NSKeyValueChangeRemoval, index);
        return true;
    }

    bool link_list_clear() {
        if (ObserverState *o = active_linklist) {
            if (o->multipleLinkviewChanges)
                return true;

            auto range = NSMakeRange(0, o->observable->row.get_linklist(o->column)->size());
            if (!o->linkviewChangeIndexes) {
                o->linkviewChangeIndexes = [NSMutableIndexSet indexSetWithIndexesInRange:range];
                o->linkviewChangeKind = NSKeyValueChangeRemoval;
            }
            else if (o->linkviewChangeKind == NSKeyValueChangeRemoval) {
                // FIXME: not tested
                range.length += [o->linkviewChangeIndexes count];
                [o->linkviewChangeIndexes addIndexesInRange:range];
            }
            // FIXME: clear after insert doesn't need to set multiple
            else {
                o->multipleLinkviewChanges = false;
                o->linkviewChangeIndexes = nil;
            }
            o->changed = true;
        }
        return true;
    }

    bool link_list_move(size_t, size_t) { return true; }

    // Things that just mark the field as modified
    bool set_int(size_t col, size_t row, int_fast64_t) { return mark_dirty(row, col); }
    bool set_bool(size_t col, size_t row, bool) { return mark_dirty(row, col); }
    bool set_float(size_t col, size_t row, float) { return mark_dirty(row, col); }
    bool set_double(size_t col, size_t row, double) { return mark_dirty(row, col); }
    bool set_string(size_t col, size_t row, StringData) { return mark_dirty(row, col); }
    bool set_binary(size_t col, size_t row, BinaryData) { return mark_dirty(row, col); }
    bool set_date_time(size_t col, size_t row, DateTime) { return mark_dirty(row, col); }
    bool set_table(size_t col, size_t row) { return mark_dirty(row, col); }
    bool set_mixed(size_t col, size_t row, const Mixed&) { return mark_dirty(row, col); }
    bool set_link(size_t col, size_t row, size_t) { return mark_dirty(row, col); }
    bool set_null(size_t col, size_t row) { return mark_dirty(row, col); }
    bool nullify_link(size_t col, size_t row) { return mark_dirty(row, col); }

    // Things we don't need to do anything for
    bool select_descriptor(int, const size_t*) { return true; }

    // Things that we don't do in the binding
    bool row_insert_complete() { return false; }
    bool optimize_table() { return false; }
    bool add_int_to_column(size_t, int_fast64_t) { return false; }
    bool insert_int(size_t, size_t, size_t, int_fast64_t) { return false; }
    bool insert_bool(size_t, size_t, size_t, bool) { return false; }
    bool insert_float(size_t, size_t, size_t, float) { return false; }
    bool insert_double(size_t, size_t, size_t, double) { return false; }
    bool insert_string(size_t, size_t, size_t, StringData) { return false; }
    bool insert_binary(size_t, size_t, size_t, BinaryData) { return false; }
    bool insert_date_time(size_t, size_t, size_t, DateTime) { return false; }
    bool insert_table(size_t, size_t, size_t) { return false; }
    bool insert_mixed(size_t, size_t, size_t, const Mixed&) { return false; }
    bool insert_link(size_t, size_t, size_t, size_t) { return false; }
    bool insert_link_list(size_t, size_t, size_t) { return false; }

private:
    bool mark_dirty(size_t row_ndx, size_t col_ndx) {
        for (auto& o : observers) {
            if (o.table == current_table && o.row == row_ndx && o.column == col_ndx) {
                o.changed = true;
            }
        }
        return true;
    }
};

template<typename Func>
static void call_with_notifications(SharedGroup *sg, History &history, RLMSchema *schema, Func&& func) {
    std::vector<ObserverState> observers;
    // all this should maybe be precomputed or cached or something
    for (RLMObjectSchema *objectSchema in schema.objectSchema) {
        for (auto observable : objectSchema->_observedObjects) {
            auto const& row = observable->row;
            if (!row.is_attached()) // FIXME: should maybe try to remove from array on invalidate
                continue;
            observable->setReturnNil(false);
            observers.push_back({
                row.get_table()->get_index_in_group(),
                row.get_index(),
                realm::npos,
                @"invalidated",
                observable});
            for (size_t i = 0; i < objectSchema.properties.count; ++i) {
                observers.push_back({
                    row.get_table()->get_index_in_group(),
                    row.get_index(),
                    i,
                    [objectSchema.properties[i] name],
                    observable});
            }
        }
    }

    if (observers.empty()) {
        func(*sg, history);
        return;
    }

    ModifiedRowParser m(observers);
    func(*sg, history, m);

    for (auto const& o : observers) {
        if (o.row == realm::not_found && o.column == realm::npos) {
            for_each(o.observable, [&](auto obj) { [obj didChangeValueForKey:o.key]; });
        }
        if (!o.changed)
            continue;
        if (!o.linkviewChangeIndexes)
            for_each(o.observable, [&](auto obj) { [obj didChangeValueForKey:o.key]; });
        else {
            for_each(o.observable, [&](auto obj) {
                [obj didChange:o.linkviewChangeKind valuesAtIndexes:o.linkviewChangeIndexes forKey:o.key];
            });
        }
    }
}

static void advance_notify(SharedGroup *sg, History &history, RLMSchema *schema) {
    call_with_notifications(sg, history, schema, [](auto&&... args) {
        LangBindHelper::advance_read(args...);
    });
}

- (void)handleExternalCommit {
    RLMCheckThread(self);
    NSAssert(!_readOnly, @"Read-only realms do not have notifications");
    try {
        if (_sharedGroup->has_changed()) { // Throws
            if (_autorefresh) {
                if (_group) {
                    advance_notify(_sharedGroup.get(), *_history, _schema);
                }
                [self sendNotifications:RLMRealmDidChangeNotification];
            }
            else {
                [self sendNotifications:RLMRealmRefreshRequiredNotification];
            }
        }
    }
    catch (exception &ex) {
        @throw RLMException(ex);
    }
}

- (BOOL)refresh {
    RLMCheckThread(self);
    CheckReadWrite(self, @"Cannot refresh a read-only realm (external modifications to read only realms are not supported)");

    // can't be any new changes if we're in a write transaction
    if (self.inWriteTransaction) {
        return NO;
    }

    try {
        // advance transaction if database has changed
        if (_sharedGroup->has_changed()) { // Throws
            if (_group) {
                advance_notify(_sharedGroup.get(), *_history, _schema);
            }
            else {
                // Create the read transaction
                [self getOrCreateGroup];
            }
            [self sendNotifications:RLMRealmDidChangeNotification];
            return YES;
        }
        return NO;
    }
    catch (exception &ex) {
        @throw RLMException(ex);
    }
}

- (void)addObject:(__unsafe_unretained RLMObject *const)object {
    RLMAddObjectToRealm(object, self, false);
}

- (void)addObjects:(id<NSFastEnumeration>)array {
    for (RLMObject *obj in array) {
        if (![obj isKindOfClass:[RLMObject class]]) {
            NSString *msg = [NSString stringWithFormat:@"Cannot insert objects of type %@ with addObjects:. Only RLMObjects are supported.", NSStringFromClass(obj.class)];
            @throw RLMException(msg);
        }
        [self addObject:obj];
    }
}

- (void)addOrUpdateObject:(RLMObject *)object {
    // verify primary key
    if (!object.objectSchema.primaryKeyProperty) {
        NSString *reason = [NSString stringWithFormat:@"'%@' does not have a primary key and can not be updated", object.objectSchema.className];
        @throw RLMException(reason);
    }

    RLMAddObjectToRealm(object, self, true);
}

- (void)addOrUpdateObjectsFromArray:(id)array {
    for (RLMObject *obj in array) {
        [self addOrUpdateObject:obj];
    }
}

- (void)deleteObject:(RLMObject *)object {
    RLMDeleteObjectFromRealm(object, self);
}

- (void)deleteObjects:(id)array {
    if ([array respondsToSelector:@selector(realm)] && [array respondsToSelector:@selector(deleteObjectsFromRealm)]) {
        if (self != (RLMRealm *)[array realm]) {
            @throw RLMException(@"Can only delete objects from the Realm they belong to.");
        }
        [array deleteObjectsFromRealm];
    }
    else if ([array conformsToProtocol:@protocol(NSFastEnumeration)]) {
        for (id obj in array) {
            if ([obj isKindOfClass:RLMObjectBase.class]) {
                RLMDeleteObjectFromRealm(obj, self);
            }
        }
    }
    else {
        @throw RLMException(@"Invalid array type - container must be an RLMArray, RLMArray, or NSArray of RLMObjects");
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
    RLM_VARARG(predicateFormat, args);
    return [self objects:objectClassName where:predicateFormat args:args];
}

- (RLMResults *)objects:(NSString *)objectClassName where:(NSString *)predicateFormat args:(va_list)args {
    return [self objects:objectClassName withPredicate:[NSPredicate predicateWithFormat:predicateFormat arguments:args]];
}

- (RLMResults *)objects:(NSString *)objectClassName withPredicate:(NSPredicate *)predicate {
    return RLMGetObjects(self, objectClassName, predicate);
}

+ (void)setDefaultRealmSchemaVersion:(uint64_t)version withMigrationBlock:(RLMMigrationBlock)block {
    [RLMRealm setSchemaVersion:version forRealmAtPath:[RLMRealm defaultRealmPath] withMigrationBlock:block];
}

+ (void)setSchemaVersion:(uint64_t)version forRealmAtPath:(NSString *)realmPath withMigrationBlock:(RLMMigrationBlock)block {
    @synchronized(s_migrationBlocks) {
        if (RLMGetAnyCachedRealmForPath(realmPath) && schemaVersionForPath(realmPath) != version) {
            @throw RLMException(@"Cannot set schema version for Realms that are already open.");
        }

        if (version == realm::ObjectStore::NotVersioned) {
            @throw RLMException(@"Cannot set schema version to RLMNotVersioned.");
        }

        if (block) {
            s_migrationBlocks[realmPath] = block;
        }
        else {
            [s_migrationBlocks removeObjectForKey:realmPath];
        }
        s_schemaVersions[realmPath] = @(version);
    }
}

+ (uint64_t)schemaVersionAtPath:(NSString *)realmPath error:(NSError **)error {
    return [RLMRealm schemaVersionAtPath:realmPath encryptionKey:nil error:error];
}

+ (uint64_t)schemaVersionAtPath:(NSString *)realmPath encryptionKey:(NSData *)key error:(NSError **)outError {
    key = validatedKey(key) ?: keyForPath(realmPath);
    RLMRealm *realm = RLMGetThreadLocalCachedRealmForPath(realmPath);
    if (!realm) {
        NSError *error;
        realm = [[RLMRealm alloc] initWithPath:realmPath key:key readOnly:YES inMemory:NO dynamic:YES error:&error];
        if (error) {
            RLMSetErrorOrThrow(error, outError);
            return RLMNotVersioned;
        }
    }

    return realm::ObjectStore::get_schema_version(realm.group);
}

+ (NSError *)migrateRealmAtPath:(NSString *)realmPath {
    return [self migrateRealmAtPath:realmPath key:keyForPath(realmPath)];
}

+ (NSError *)migrateRealmAtPath:(NSString *)realmPath encryptionKey:(NSData *)key {
    if (!key) {
        @throw RLMException(@"Encryption key must not be nil");
    }

    return [self migrateRealmAtPath:realmPath key:validatedKey(key)];
}

+ (NSError *)migrateRealmAtPath:(NSString *)realmPath key:(NSData *)key {
    if (RLMGetAnyCachedRealmForPath(realmPath)) {
        @throw RLMException(@"Cannot migrate Realms that are already open.");
    }

    key = validatedKey(key) ?: keyForPath(realmPath);

    NSError *error;
    RLMRealm *realm = [[RLMRealm alloc] initWithPath:realmPath key:key readOnly:NO inMemory:NO dynamic:YES error:&error];
    if (error)
        return error;

    @try {
        RLMUpdateRealmToSchemaVersion(realm, schemaVersionForPath(realmPath), [RLMSchema.sharedSchema copy], [realm migrationBlock:key]);
    } @catch (NSException *ex) {
        return RLMMakeError(ex);
    }
    return nil;
}

- (RLMObject *)createObject:(NSString *)className withValue:(id)value {
    return (RLMObject *)RLMCreateObjectInRealmWithValue(self, className, value, false);
}

- (BOOL)writeCopyToPath:(NSString *)path key:(NSData *)key error:(NSError **)error {
    key = validatedKey(key) ?: keyForPath(path);

    try {
        self.group->write(path.UTF8String, static_cast<const char *>(key.bytes));
        return YES;
    }
    catch (File::PermissionDenied &ex) {
        if (error) {
            *error = RLMMakeError(RLMErrorFilePermissionDenied, ex);
        }
    }
    catch (File::Exists &ex) {
        if (error) {
            *error = RLMMakeError(RLMErrorFileExists, ex);
        }
    }
    catch (File::AccessError &ex) {
        if (error) {
            *error = RLMMakeError(RLMErrorFileAccessError, ex);
        }
    }
    catch (exception &ex) {
        if (error) {
            *error = RLMMakeError(RLMErrorFail, ex);
        }
    }

    return NO;
}

- (BOOL)writeCopyToPath:(NSString *)path error:(NSError **)error {
    return [self writeCopyToPath:path key:nil error:error];
}

- (BOOL)writeCopyToPath:(NSString *)path encryptionKey:(NSData *)key error:(NSError **)error {
    if (!key) {
        @throw RLMException(@"Encryption key must not be nil");
    }

    return [self writeCopyToPath:path key:key error:error];
}

@end
