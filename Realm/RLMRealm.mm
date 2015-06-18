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
#import "RLMRealmConfiguration_Private.h"
#import "RLMMigration_Private.h"
#import "RLMObjectSchema_Private.hpp"
#import "RLMProperty_Private.h"
#import "RLMObjectStore.h"
#import "RLMObject_Private.h"
#import "RLMObject_Private.hpp"
#import "RLMObservation.hpp"
#import "RLMProperty.h"
#import "RLMQueryUtil.hpp"
#import "RLMRealmUtil.h"
#import "RLMSchema_Private.h"
#import "RLMUpdateChecker.hpp"
#import "RLMUtil.hpp"

#include "object_store.hpp"
#include "shared_realm.hpp"
#include <realm/commit_log.hpp>
#include <realm/disable_sync_to_disk.hpp>
#include <realm/version.hpp>

using namespace realm;
using util::File;

@interface RLMSchema ()
+ (instancetype)dynamicSchemaFromObjectStoreSchema:(realm::Schema &)objectStoreSchema;
@end

void RLMDisableSyncToDisk() {
    realm::disable_sync_to_disk();
}

// Notification Token

@interface RLMNotificationToken () {
@public
    Realm::NotificationFunction _notification;
}
@end

@implementation RLMNotificationToken
- (void)dealloc
{
    if (_notification) {
        NSLog(@"RLMNotificationToken released without unregistering a notification. You must hold "
              @"on to the RLMNotificationToken returned from addNotificationBlock and call "
              @"removeNotification: when you no longer wish to recieve RLMRealm notifications.");
    }
    _notification.reset();
}
@end

static bool shouldForciblyDisableEncryption()
{
    static bool disableEncryption = getenv("REALM_DISABLE_ENCRYPTION");
    return disableEncryption;
}

NSData *RLMRealmValidatedEncryptionKey(NSData *key) {
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

@implementation RLMRealm {
    NSHashTable *_collectionEnumerators;
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

- (BOOL)isEmpty {
    return realm::ObjectStore::is_empty(self.group);
}

- (void)verifyThread {
    _realm->verify_thread();
}

- (BOOL)inWriteTransaction {
    return _realm->is_in_transaction();
}

- (NSString *)path {
    return @(_realm->config().path.c_str());
}

- (realm::Group *)group {
    return _realm->read_group();
}

- (BOOL)isReadOnly {
    return _realm->config().read_only;
}

-(BOOL)autorefresh {
    return _realm->auto_refresh();
}

- (void)setAutorefresh:(BOOL)autorefresh {
    _realm->set_auto_refresh(autorefresh);
}

+ (NSString *)writeableTemporaryPathForFile:(NSString *)fileName {
    return [NSTemporaryDirectory() stringByAppendingPathComponent:fileName];
}

+ (instancetype)defaultRealm {
    return [RLMRealm realmWithConfiguration:[RLMRealmConfiguration rawDefaultConfiguration] error:nil];
}

+ (instancetype)realmWithPath:(NSString *)path {
    RLMRealmConfiguration *configuration = [[RLMRealmConfiguration alloc] init];
    configuration.path = path;
    return [RLMRealm realmWithConfiguration:configuration error:nil];
}

+ (instancetype)realmWithPath:(NSString *)path
                          key:(NSData *)key
                     readOnly:(BOOL)readonly
                     inMemory:(BOOL)inMemory
                      dynamic:(BOOL)dynamic
                       schema:(RLMSchema *)customSchema
                        error:(NSError **)outError
{
    RLMRealmConfiguration *configuration = [[RLMRealmConfiguration alloc] init];
    if (inMemory) {
        configuration.inMemoryIdentifier = path.lastPathComponent;
    }
    else {
        configuration.path = path;
    }
    configuration.encryptionKey = key;
    configuration.readOnly = readonly;
    configuration.dynamic = dynamic;
    configuration.customSchema = customSchema;
    return [RLMRealm realmWithConfiguration:configuration error:outError];
}

// ARC tries to eliminate calls to autorelease when the value is then immediately
// returned, but this results in significantly different semantics between debug
// and release builds for RLMRealm, so force it to always autorelease.
static id RLMAutorelease(id value) {
    // +1 __bridge_retained, -1 CFAutorelease
    return value ? (__bridge id)CFAutorelease((__bridge_retained CFTypeRef)value) : nil;
}

static void RLMCopyColumnMapping(RLMObjectSchema *targetSchema, const ObjectSchema &tableSchema) {
    REALM_ASSERT_DEBUG(targetSchema.properties.count == tableSchema.properties.size());

    // copy updated column mapping
    for (auto &prop : tableSchema.properties) {
        RLMProperty *targetProp = targetSchema[@(prop.name.c_str())];
        targetProp.column = prop.table_column;
    }

    // re-order properties
    targetSchema.properties = [targetSchema.properties sortedArrayUsingComparator:^NSComparisonResult(RLMProperty *p1, RLMProperty *p2) {
        if (p1.column < p2.column) return NSOrderedAscending;
        if (p1.column > p2.column) return NSOrderedDescending;
        return NSOrderedSame;
    }];
}

static void RLMRealmSetSchemaAndAlign(RLMRealm *realm, RLMSchema *targetSchema) {
    RLMSchema *sharedSchema = [RLMSchema sharedSchema];

    realm.schema = targetSchema;
    for (auto &aligned:*realm->_realm->config().schema) {
        RLMObjectSchema *objectSchema = targetSchema[@(aligned.first.c_str())];
        objectSchema.realm = realm;
        if (RLMObjectSchema *sharedObjectSchema = [sharedSchema schemaForClassName:objectSchema.className]) {
            objectSchema.objectClass = sharedObjectSchema.objectClass;
            objectSchema.isSwiftClass = sharedObjectSchema.isSwiftClass;
            objectSchema.accessorClass = sharedObjectSchema.accessorClass;
            objectSchema.standaloneClass = sharedObjectSchema.standaloneClass;
        }
        RLMCopyColumnMapping(objectSchema, aligned.second);
    }
}

+ (instancetype)realmWithSharedRealm:(SharedRealm)sharedRealm {
    RLMRealm *realm = [RLMRealm new];
    realm->_realm = sharedRealm;
    realm->_dynamic = YES;
    RLMRealmSetSchemaAndAlign(realm, [RLMSchema dynamicSchemaFromObjectStoreSchema:*sharedRealm->config().schema]);

    return RLMAutorelease(realm);
}

+ (SharedRealm)openSharedRealm:(Realm::Config &)config error:(NSError **)outError {
    try {
        return Realm::get_shared_realm(config);
    }
    catch (RealmFileException &ex) {
        switch (ex.kind()) {
            case RealmFileException::Kind::PermissionDenied: {
                NSString *mode = config.read_only ? @"read" : @"read-write";
                NSString *additionalMessage = [NSString stringWithFormat:@"Unable to open a realm at path '%@'. Please use a path where your app has %@ permissions.", @(config.path.c_str()), mode];
                NSString *newMessage = [NSString stringWithFormat:@"%s\n%@", ex.what(), additionalMessage];
                RLMSetErrorOrThrow(RLMMakeError(RLMErrorFilePermissionDenied, File::PermissionDenied(newMessage.UTF8String, "FIXME: ex.get_path()")), outError);
                break;
            }
            case RealmFileException::Kind::IncompatibleLockFile: {
                NSString *err = @"Realm file is currently open in another process "
                                 "which cannot share access with this process. All "
                                 "processes sharing a single file must be the same "
                                 "architecture. For sharing files between the Realm "
                                 "Browser and an iOS simulator, this means that you "
                                 "must use a 64-bit simulator.";
                RLMSetErrorOrThrow(RLMMakeError(RLMErrorIncompatibleLockFile, File::PermissionDenied(err.UTF8String, "FIXME: ex.get_path()")), outError);
                break;
            }
            case RealmFileException::Kind::Exists:
                RLMSetErrorOrThrow(RLMMakeError(RLMErrorFileExists, ex), outError);
                break;
            case RealmFileException::Kind::AccessError:
                RLMSetErrorOrThrow(RLMMakeError(RLMErrorFileAccessError, ex), outError);
                break;
            default:
                RLMSetErrorOrThrow(RLMMakeError(RLMErrorFail, ex), outError);
                break;
        }
        return nullptr;
    }
    catch (std::exception const& ex) {
        RLMSetErrorOrThrow(RLMMakeError(RLMErrorFail, ex), outError);
        return nullptr;
    }
}

static Schema RLMObjectStoreSchemaForRLMSchema(RLMSchema *rlmSchema) {
    Schema schema;
    for (RLMObjectSchema *objectSchema in rlmSchema.objectSchema) {
        ObjectSchema os = objectSchema.objectStoreCopy;
        schema.emplace(os.name, std::move(os));
    }
    return schema;
}

+ (instancetype)realmWithConfiguration:(RLMRealmConfiguration *)configuration error:(NSError **)error {
    NSString *path = configuration.path;
    bool inMemory = false;
    if (configuration.inMemoryIdentifier) {
        inMemory = true;
        path = [RLMRealm writeableTemporaryPathForFile:configuration.inMemoryIdentifier];
    }
    RLMSchema *customSchema = configuration.customSchema;
    bool dynamic = configuration.dynamic;
    bool readOnly = configuration.readOnly;
    NSData *key = configuration.encryptionKey;

    // try to reuse existing realm first
    RLMRealm *realm = RLMGetThreadLocalCachedRealmForPath(path);
    if (realm) {
        if (realm.isReadOnly != readOnly) {
            @throw RLMException(@"Realm at path '%@' already opened with different read permissions", path);
        }
        if (realm->_realm->config().in_memory != inMemory) {
            @throw RLMException(@"Realm at path '%@' already opened with different inMemory settings", path);
        }
        if (realm->_dynamic != dynamic) {
            @throw RLMException(@"Realm at path '%@' already opened with different dynamic settings", path);
        }
//        if (realm->_encryptionKey != key && (!key || ![realm->_encryptionKey isEqualToData:key])) {
//            @throw RLMException(@"Realm at path '%@' already opened with different encryption key", path);
//        }
        return RLMAutorelease(realm);
    }

    realm = [RLMRealm new];
    realm->_dynamic = dynamic;

    realm::Realm::Config config;
    config.path = path.UTF8String;
    config.read_only = readOnly;
    config.in_memory = inMemory;
    if (key) {
        config.encryption_key = std::make_unique<char[]>(key.length);
        memcpy(config.encryption_key.get(), key.bytes, key.length);
    }

    config.migration_function = [=](SharedRealm old_realm, SharedRealm realm) {
        if (RLMMigrationBlock userBlock = configuration.migrationBlock) {
            RLMMigration *migration = [[RLMMigration alloc] initWithRealm:[RLMRealm realmWithSharedRealm:realm]
                                                                 oldRealm:[RLMRealm realmWithSharedRealm:old_realm]];
            [migration execute:userBlock];
        }
    };

    // protects the realm cache and accessors cache
    static id initLock = [NSObject new];
    @synchronized(initLock) {
        realm->_realm = [self openSharedRealm:config error:error];
        if (!realm->_realm) {
            return nil;
        }

        // if we have a cached realm on another thread, copy without a transaction
        if (RLMRealm *cachedRealm = RLMGetAnyCachedRealmForPath(path)) {
            realm.schema = [cachedRealm.schema shallowCopy];
            for (RLMObjectSchema *objectSchema in realm.schema.objectSchema) {
                objectSchema.realm = realm;
            }
        }
        else {
            // set/align schema or perform migration if needed
            uint64_t newVersion = configuration.schemaVersion;
            try {
                RLMSchema *targetSchema = customSchema ?: [RLMSchema.sharedSchema copy];
                Schema schema = RLMObjectStoreSchemaForRLMSchema(targetSchema);
                realm->_realm->update_schema(schema, newVersion);
                RLMRealmSetSchemaAndAlign(realm, targetSchema);
            } catch (const std::exception & exception) {
                RLMSetErrorOrThrow(RLMMakeError(RLMException(exception)), error);
                return nil;
            }
        }

        if (!dynamic) {
            RLMRealmCreateAccessors(realm.schema);
            RLMCacheRealm(realm);
        }
    }

    if (!readOnly) {
        // initializing the schema started a read transaction, so end it
        [realm invalidate];

        realm.notifier = [[RLMNotifier alloc] initWithRealm:realm error:error];
        if (!realm.notifier) {
            return nil;
        }
        __weak RLMNotifier *weakNotifier = realm.notifier;
        realm->_realm->m_external_notifier = std::make_unique<std::function<void()>>([=]() {
            [weakNotifier notifyOtherRealms];
        });
    }

    return RLMAutorelease(realm);
}

+ (void)resetRealmState {
    RLMClearRealmCache();
    realm::Realm::s_global_cache.clear();
    [RLMRealmConfiguration resetRealmConfigurationState];
}

static void CheckReadWrite(RLMRealm *realm, NSString *msg=@"Cannot write to a read-only Realm") {
    if (realm.readOnly) {
        @throw RLMException(@"%@", msg);
    }
}

- (RLMNotificationToken *)addNotificationBlock:(RLMNotificationBlock)block {
    [self verifyThread];
    CheckReadWrite(self, @"Read-only Realms do not change and do not have change notifications");
    if (!block) {
        @throw RLMException(@"The notification block should not be nil");
    }

    RLMNotificationToken *token = [[RLMNotificationToken alloc] init];
    __weak RLMRealm *weakRealm = self;
    token->_notification = token->_notification.make_shared([=](const std::string notification) {
        if (notification == _realm->RefreshRequiredNotification)
            block(RLMRealmRefreshRequiredNotification, weakRealm);
        else
            block(RLMRealmDidChangeNotification, weakRealm);
    });
    _realm->add_notification(token->_notification);
    return token;
}

- (void)removeNotification:(RLMNotificationToken *)token {
    [self verifyThread];
    if (token) {
        _realm->remove_notification(token->_notification);
        token->_notification.reset();
    }
}

- (RLMRealmConfiguration *)configuration {
#if 0
    RLMRealmConfiguration *configuration = [[RLMRealmConfiguration alloc] init];
    configuration.path = self.path;
    configuration.schemaVersion = realm::ObjectStore::get_schema_version(self.group);
    if (_inMemory) {
        configuration.inMemoryIdentifier = [_path lastPathComponent];
    }
    configuration.readOnly = _readOnly;
    configuration.encryptionKey = _encryptionKey;
    configuration.dynamic = _dynamic;
    configuration.customSchema = _schema;
    return configuration;
#endif
    return nil;
}

- (void)beginWriteTransaction {
    try {
        _realm->begin_transaction();
    }
    catch (std::exception &ex) {
        @throw RLMException(ex);
    }

    // notify any collections currently being enumerated that they need
    // to switch to enumerating a copy as the data may change on them
    for (RLMFastEnumerator *enumerator in _collectionEnumerators) {
        [enumerator detach];
    }
    _collectionEnumerators = nil;
}

- (void)commitWriteTransaction {
    [self commitWriteTransaction:nil];
}

- (BOOL)commitWriteTransaction:(NSError **)outError {
    try {
        _realm->commit_transaction();
        return YES;
    }
    catch (std::exception const& ex) {
        RLMSetErrorOrThrow(RLMMakeError(RLMErrorFail, ex), outError);
        return NO;
    }
}

- (void)transactionWithBlock:(void(^)(void))block {
    [self transactionWithBlock:block error:nil];
}

- (BOOL)transactionWithBlock:(void(^)(void))block error:(NSError **)outError {
    [self beginWriteTransaction];
    block();
    if (_realm->is_in_transaction()) {
        return [self commitWriteTransaction:outError];
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
    _realm->invalidate();
    for (RLMObjectSchema *objectSchema in _schema.objectSchema) {
        for (RLMObservationInfo *info : objectSchema->_observedObjects) {
            info->didChange(RLMInvalidatedKey);
        }
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
    return _realm->compact();
}

- (void)dealloc {
    if (_realm) {
        if (_realm->is_in_transaction()) {
            [self cancelWriteTransaction];
            NSLog(@"WARNING: An RLMRealm instance was deallocated during a write transaction and all "
                  "pending changes have been rolled back. Make sure to retain a reference to the "
                  "RLMRealm for the duration of the write transaction.");
        }
        _realm->remove_all_notifications();
    }
    [_notifier stop];
}

- (void)notify {
    _realm->notify();
}

- (BOOL)refresh {
    return _realm->refresh();
}

- (void)cacheTableAccessors {
    for (RLMObjectSchema *objectSchema in _schema.objectSchema) {
        objectSchema.table = ObjectStore::table_for_object_type(_realm->read_group(), objectSchema.className.UTF8String).get();
    }
}

- (void)addObject:(__unsafe_unretained RLMObject *const)object {
    RLMAddObjectToRealm(object, self, false);
}

- (void)addObjects:(id<NSFastEnumeration>)array {
    for (RLMObject *obj in array) {
        if (![obj isKindOfClass:[RLMObject class]]) {
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

- (RLMObject *)objectWithClassName:(NSString *)className forPrimaryKey:(id)primaryKey {
    return RLMGetObject(self, className, primaryKey);
}

+ (uint64_t)schemaVersionAtPath:(NSString *)realmPath error:(NSError **)error {
    return [RLMRealm schemaVersionAtPath:realmPath encryptionKey:nil error:error];
}

+ (uint64_t)schemaVersionAtPath:(NSString *)realmPath encryptionKey:(NSData *)key error:(NSError **)outError {
    key = RLMRealmValidatedEncryptionKey(key);
    RLMRealm *realm = RLMGetThreadLocalCachedRealmForPath(realmPath);
    if (realm) {
        return realm->_realm->config().schema_version;
    }

    try {
        Realm::Config config;
        config.path = realmPath.UTF8String;
//        config.encryption_key = key ? static_cast<const char *>(key.bytes) : StringData();
        uint64_t version = Realm::get_shared_realm(config)->config().schema_version;
        if (version == realm::ObjectStore::NotVersioned) {
            RLMSetErrorOrThrow([NSError errorWithDomain:RLMErrorDomain code:RLMErrorFail userInfo:@{NSLocalizedDescriptionKey:@"Cannot open an uninitialized realm in read-only mode"}], outError);
        }
        return version;
    }
    catch (std::exception &exp) {
        RLMSetErrorOrThrow(RLMMakeError(RLMErrorFail, exp), outError);
        return RLMNotVersioned;
    }
}

+ (NSError *)migrateRealm:(RLMRealmConfiguration *)configuration {
    NSString *realmPath = configuration.path;
    if (RLMGetAnyCachedRealmForPath(realmPath)) {
        @throw RLMException(@"Cannot migrate Realms that are already open.");
    }

    @autoreleasepool {
        NSError *error;
        [RLMRealm realmWithConfiguration:configuration error:&error];
        return error;
    }
}

- (RLMObject *)createObject:(NSString *)className withValue:(id)value {
    return (RLMObject *)RLMCreateObjectInRealmWithValue(self, className, value, false);
}

- (BOOL)writeCopyToPath:(NSString *)path key:(NSData *)key error:(NSError **)error {
    key = RLMRealmValidatedEncryptionKey(key);

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
    catch (std::exception &ex) {
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

- (void)registerEnumerator:(RLMFastEnumerator *)enumerator {
    if (!_collectionEnumerators) {
        _collectionEnumerators = [NSHashTable hashTableWithOptions:NSPointerFunctionsWeakMemory];
    }
    [_collectionEnumerators addObject:enumerator];

}

- (void)unregisterEnumerator:(RLMFastEnumerator *)enumerator {
    [_collectionEnumerators removeObject:enumerator];
}

@end
