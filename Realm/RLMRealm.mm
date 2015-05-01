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

#import "RLMArray_Private.hpp"
#import "RLMMigration_Private.h"
#import "RLMObject_Private.h"
#import "RLMObjectSchema_Private.hpp"
#import "RLMObjectStore.h"
#import "RLMQueryUtil.hpp"
#import "RLMRealmUtil.h"
#import "RLMSchema_Private.h"
#import "RLMUpdateChecker.hpp"
#import "RLMUtil.hpp"

#include <sys/sysctl.h>
#include <sys/types.h>

#include <realm/commit_log.hpp>
#include <realm/version.hpp>

using namespace std;
using namespace realm;
using namespace realm::util;

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
static NSMutableDictionary *s_keysPerPath = [NSMutableDictionary new];
static NSData *keyForPath(NSString *path) {
    @synchronized (s_keysPerPath) {
        return s_keysPerPath[path];
    }
}

static void setKeyForPath(NSData *key, NSString *path) {
    @synchronized (s_keysPerPath) {
        if (key) {
            s_keysPerPath[path] = key;
        }
        else {
            [s_keysPerPath removeObjectForKey:path];
        }
    }
}

static void clearKeyCache() {
    @synchronized(s_keysPerPath) {
        [s_keysPerPath removeAllObjects];
    }
}

static NSData *validatedKey(NSData *key) {
    if (key && key.length != 64) {
        @throw RLMException(@"Encryption key must be exactly 64 bytes long");
    }
    return key;
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

    std::unique_ptr<Replication> _replication;
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
            if (readonly) {
                _readGroup = make_unique<Group>(path.UTF8String, static_cast<const char *>(key.bytes));
                _group = _readGroup.get();
            }
            else {
                _replication = realm::makeWriteLogCollector(path.UTF8String, false,
                                                            static_cast<const char *>(key.bytes));
                SharedGroup::DurabilityLevel durability = inMemory ? SharedGroup::durability_MemOnly :
                                                                     SharedGroup::durability_Full;
                _sharedGroup = make_unique<SharedGroup>(*_replication, durability,
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

+ (NSString *)writeablePathForFile:(NSString*)fileName
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
    return [self realmWithPath:[RLMRealm writeablePathForFile:identifier] key:nil
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

    key = validatedKey(key) ?: keyForPath(path);
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
            if (RLMRealmSchemaVersion(realm) == RLMNotVersioned) {
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
                NSError *error = RLMUpdateRealmToSchemaVersion(realm, schemaVersionForPath(path),
                                                               [targetSchema copy], [realm migrationBlock:key]);
                if (error) {
                    RLMSetErrorOrThrow(error, outError);
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
    if (RLMGetAnyCachedRealmForPath(path)) {
        @throw RLMException(@"Cannot set encryption key for Realms that are already open.");
    }

    setKeyForPath(validatedKey(key), path);
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

            LangBindHelper::promote_to_write(*_sharedGroup);

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
            LangBindHelper::rollback_and_continue_as_read(*_sharedGroup);
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

- (void)handleExternalCommit {
    RLMCheckThread(self);
    NSAssert(!_readOnly, @"Read-only realms do not have notifications");
    try {
        if (_sharedGroup->has_changed()) { // Throws
            if (_autorefresh) {
                if (_group) {
                    LangBindHelper::advance_read(*_sharedGroup);
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
                LangBindHelper::advance_read(*_sharedGroup);
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

- (void)addObject:(RLMObject *)object {
    RLMAddObjectToRealm(object, self, RLMCreationOptionsNone);
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

    RLMAddObjectToRealm(object, self, RLMCreationOptionsUpdateOrCreate);
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
    if (NSArray *nsArray = RLMDynamicCast<NSArray>(array)) {
        // for arrays and standalone delete each individually
        for (id obj in nsArray) {
            if ([obj isKindOfClass:RLMObjectBase.class]) {
                RLMDeleteObjectFromRealm(obj, self);
            }
        }
    }
    else if (RLMArray *rlmArray = RLMDynamicCast<RLMArray>(array)) {
        if (self != rlmArray.realm) {
            @throw RLMException(@"Can only delete an object from the Realm it belongs to.");
        }
        // call deleteObjectsFromRealm for our RLMArray
        [rlmArray deleteObjectsFromRealm];
    }
    else if (RLMResults *rlmResults = RLMDynamicCast<RLMResults>(array)) {
        if (self != rlmResults.realm) {
            @throw RLMException(@"Can only delete an object from the Realm it belongs to.");
        }
        // call deleteObjectsFromRealm for our RLMResults
        [rlmResults deleteObjectsFromRealm];
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

+ (void)setDefaultRealmSchemaVersion:(NSUInteger)version withMigrationBlock:(RLMMigrationBlock)block {
    [RLMRealm setSchemaVersion:version forRealmAtPath:[RLMRealm defaultRealmPath] withMigrationBlock:block];
}

+ (void)setSchemaVersion:(NSUInteger)version forRealmAtPath:(NSString *)realmPath withMigrationBlock:(RLMMigrationBlock)block {
    if (RLMGetAnyCachedRealmForPath(realmPath)) {
        @throw RLMException(@"Cannot set schema version for Realms that are already open.");
    }

    @synchronized(s_migrationBlocks) {
        if (block) {
            s_migrationBlocks[realmPath] = block;
        }
        else {
            [s_migrationBlocks removeObjectForKey:realmPath];
        }
        s_schemaVersions[realmPath] = @(version);
    }
}

+ (NSUInteger)schemaVersionAtPath:(NSString *)realmPath error:(NSError **)error {
    return [RLMRealm schemaVersionAtPath:realmPath encryptionKey:nil error:error];
}

+ (NSUInteger)schemaVersionAtPath:(NSString *)realmPath encryptionKey:(NSData *)key error:(NSError **)outError {
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

    return RLMRealmSchemaVersion(realm);
}

+ (NSError *)migrateRealmAtPath:(NSString *)realmPath {
    return [self migrateRealmAtPath:realmPath key:keyForPath(realmPath)];
}

+ (NSError *)migrateRealmAtPath:(NSString *)realmPath encryptionKey:(NSData *)key {
    if (!key) {
        @throw RLMException(@"Encryption key must not be nil");
    }

    return [self migrateRealmAtPath:realmPath key:key];
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

    return RLMUpdateRealmToSchemaVersion(realm, schemaVersionForPath(realmPath), [RLMSchema.sharedSchema copy], [realm migrationBlock:key]);
}

- (RLMObject *)createObject:(NSString *)className withValue:(id)value {
    return (RLMObject *)RLMCreateObjectInRealmWithValue(self, className, value, RLMCreationOptionsNone);
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
