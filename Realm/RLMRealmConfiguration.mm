////////////////////////////////////////////////////////////////////////////
//
// Copyright 2015 Realm Inc.
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

#import "RLMRealmConfiguration_Private.h"

#import "RLMEvent.h"
#import "RLMObjectSchema_Private.hpp"
#import "RLMRealm_Private.h"
#import "RLMSchema_Private.hpp"
#import "RLMUtil.hpp"

#import <realm/object-store/schema.hpp>
#import <realm/object-store/shared_realm.hpp>

#if REALM_ENABLE_SYNC
#import "RLMSyncConfiguration_Private.hpp"
#import "RLMUser_Private.hpp"

#import <realm/object-store/sync/sync_manager.hpp>
#import <realm/object-store/util/bson/bson.hpp>
#import <realm/sync/config.hpp>
#else
@class RLMSyncConfiguration;
#endif

static NSString *const c_RLMRealmConfigurationProperties[] = {
    @"fileURL",
    @"inMemoryIdentifier",
    @"encryptionKey",
    @"readOnly",
    @"schemaVersion",
    @"migrationBlock",
    @"deleteRealmIfMigrationNeeded",
    @"shouldCompactOnLaunch",
    @"dynamic",
    @"customSchema",
};

static NSString *const c_defaultRealmFileName = @"default.realm";
RLMRealmConfiguration *s_defaultConfiguration;

NSString *RLMRealmPathForFileAndBundleIdentifier(NSString *fileName, NSString *bundleIdentifier) {
    return [RLMDefaultDirectoryForBundleIdentifier(bundleIdentifier)
            stringByAppendingPathComponent:fileName];
}

NSString *RLMRealmPathForFile(NSString *fileName) {
    static NSString *directory = RLMDefaultDirectoryForBundleIdentifier(nil);
    return [directory stringByAppendingPathComponent:fileName];
}

@implementation RLMRealmConfiguration {
    realm::Realm::Config _config;
    RLMSyncErrorReportingBlock _manualClientResetHandler;
}

- (realm::Realm::Config&)configRef {
    return _config;
}

- (std::string const&)path {
    return _config.path;
}

+ (instancetype)defaultConfiguration {
    return [[self rawDefaultConfiguration] copy];
}

+ (void)setDefaultConfiguration:(RLMRealmConfiguration *)configuration {
    if (!configuration) {
        @throw RLMException(@"Cannot set the default configuration to nil.");
    }
    @synchronized(c_defaultRealmFileName) {
        s_defaultConfiguration = [configuration copy];
    }
}

+ (RLMRealmConfiguration *)rawDefaultConfiguration {
    RLMRealmConfiguration *configuration;
    @synchronized(c_defaultRealmFileName) {
        if (!s_defaultConfiguration) {
            s_defaultConfiguration = [[RLMRealmConfiguration alloc] init];
        }
        configuration = s_defaultConfiguration;
    }
    return configuration;
}

+ (void)resetRealmConfigurationState {
    @synchronized(c_defaultRealmFileName) {
        s_defaultConfiguration = nil;
    }
}

- (instancetype)init {
    self = [super init];
    if (self) {
        static NSURL *defaultRealmURL = [NSURL fileURLWithPath:RLMRealmPathForFile(c_defaultRealmFileName)];
        self.fileURL = defaultRealmURL;
        self.schemaVersion = 0;
        self.cache = YES;
        _config.automatically_handle_backlinks_in_migrations = true;
    }

    return self;
}

- (instancetype)copyWithZone:(NSZone *)zone {
    RLMRealmConfiguration *configuration = [[[self class] allocWithZone:zone] init];
    configuration->_config = _config;
    configuration->_cache = _cache;
    configuration->_dynamic = _dynamic;
    configuration->_migrationBlock = _migrationBlock;
    configuration->_shouldCompactOnLaunch = _shouldCompactOnLaunch;
    configuration->_customSchema = _customSchema;
    configuration->_eventConfiguration = _eventConfiguration;
    configuration->_migrationObjectClass = _migrationObjectClass;
    configuration->_initialSubscriptions = _initialSubscriptions;
    configuration->_rerunOnOpen = _rerunOnOpen;
    return configuration;
}

- (NSString *)description {
    NSMutableString *string = [NSMutableString stringWithFormat:@"%@ {\n", self.class];
    for (NSString *key : c_RLMRealmConfigurationProperties) {
        NSString *description = [[self valueForKey:key] description];
        description = [description stringByReplacingOccurrencesOfString:@"\n" withString:@"\n\t"];

        [string appendFormat:@"\t%@ = %@;\n", key, description];
    }
    return [string stringByAppendingString:@"}"];
}

- (NSURL *)fileURL {
    if (_config.in_memory) {
        return nil;
    }
    return [NSURL fileURLWithPath:@(_config.path.c_str())];
}

- (void)setFileURL:(NSURL *)fileURL {
    NSString *path = fileURL.path;
    if (path.length == 0) {
        @throw RLMException(@"Realm path must not be empty");
    }

    RLMNSStringToStdString(_config.path, path);
    _config.in_memory = false;
}

- (NSString *)inMemoryIdentifier {
    if (!_config.in_memory) {
        return nil;
    }
    return [@(_config.path.c_str()) lastPathComponent];
}

- (void)setInMemoryIdentifier:(NSString *)inMemoryIdentifier {
    if (inMemoryIdentifier.length == 0) {
        @throw RLMException(@"In-memory identifier must not be empty");
    }
    _config.sync_config = nullptr;
    _seedFilePath = nil;

    RLMNSStringToStdString(_config.path, [NSTemporaryDirectory() stringByAppendingPathComponent:inMemoryIdentifier]);
    _config.in_memory = true;
}

- (void)setSeedFilePath:(NSURL *)seedFilePath {
    _seedFilePath = seedFilePath;
    if (_seedFilePath) {
        _config.in_memory = false;
    }
}

- (NSData *)encryptionKey {
    return _config.encryption_key.empty() ? nil : [NSData dataWithBytes:_config.encryption_key.data() length:_config.encryption_key.size()];
}

- (void)setEncryptionKey:(NSData * __nullable)encryptionKey {
    if (NSData *key = RLMRealmValidatedEncryptionKey(encryptionKey)) {
        auto bytes = static_cast<const char *>(key.bytes);
        _config.encryption_key.assign(bytes, bytes + key.length);
    }
    else {
        _config.encryption_key.clear();
    }
}

- (BOOL)readOnly {
    return _config.immutable() || _config.read_only();
}

static bool isSync(realm::Realm::Config const& config) {
#if REALM_ENABLE_SYNC
    return !!config.sync_config;
#endif
    return false;
}

- (void)updateSchemaMode {
    if (self.deleteRealmIfMigrationNeeded) {
        if (isSync(_config)) {
            @throw RLMException(@"Cannot set 'deleteRealmIfMigrationNeeded' when sync is enabled ('syncConfig' is set).");
        }
    }
    else if (self.readOnly) {
        _config.schema_mode = isSync(_config) ? realm::SchemaMode::ReadOnly : realm::SchemaMode::Immutable;
    }
    else if (isSync(_config)) {
        if (_customSchema) {
            _config.schema_mode = realm::SchemaMode::AdditiveExplicit;
        }
        else {
            _config.schema_mode = realm::SchemaMode::AdditiveDiscovered;
        }
    }
    else {
        _config.schema_mode = realm::SchemaMode::Automatic;
    }
}

- (void)setReadOnly:(BOOL)readOnly {
    if (readOnly) {
        if (self.deleteRealmIfMigrationNeeded) {
            @throw RLMException(@"Cannot set `readOnly` when `deleteRealmIfMigrationNeeded` is set.");
        } else if (self.shouldCompactOnLaunch) {
            @throw RLMException(@"Cannot set `readOnly` when `shouldCompactOnLaunch` is set.");
        }
        _config.schema_mode = isSync(_config) ? realm::SchemaMode::ReadOnly : realm::SchemaMode::Immutable;
    }
    else if (self.readOnly) {
        _config.schema_mode = realm::SchemaMode::Automatic;
        [self updateSchemaMode];
    }
}

- (uint64_t)schemaVersion {
    return _config.schema_version;
}

- (void)setSchemaVersion:(uint64_t)schemaVersion {
    if (schemaVersion == RLMNotVersioned) {
        @throw RLMException(@"Cannot set schema version to %llu (RLMNotVersioned)", RLMNotVersioned);
    }
    _config.schema_version = schemaVersion;
}

- (BOOL)deleteRealmIfMigrationNeeded {
    return _config.schema_mode == realm::SchemaMode::SoftResetFile;
}

- (void)setDeleteRealmIfMigrationNeeded:(BOOL)deleteRealmIfMigrationNeeded {
    if (deleteRealmIfMigrationNeeded) {
        if (self.readOnly) {
            @throw RLMException(@"Cannot set `deleteRealmIfMigrationNeeded` when `readOnly` is set.");
        }
        if (isSync(_config)) {
            @throw RLMException(@"Cannot set 'deleteRealmIfMigrationNeeded' when sync is enabled ('syncConfig' is set).");
        }
        _config.schema_mode = realm::SchemaMode::SoftResetFile;
    }
    else if (self.deleteRealmIfMigrationNeeded) {
        _config.schema_mode = realm::SchemaMode::Automatic;
    }
}

- (NSArray *)objectClasses {
    return [_customSchema.objectSchema valueForKeyPath:@"objectClass"];
}

- (void)setObjectClasses:(NSArray *)objectClasses {
    _customSchema = objectClasses ? [RLMSchema schemaWithObjectClasses:objectClasses] : nil;
    [self updateSchemaMode];
}

- (NSUInteger)maximumNumberOfActiveVersions {
    if (_config.max_number_of_active_versions > std::numeric_limits<NSUInteger>::max()) {
        return std::numeric_limits<NSUInteger>::max();
    }
    return static_cast<NSUInteger>(_config.max_number_of_active_versions);
}

- (void)setMaximumNumberOfActiveVersions:(NSUInteger)maximumNumberOfActiveVersions {
    if (maximumNumberOfActiveVersions == 0) {
        _config.max_number_of_active_versions = std::numeric_limits<uint_fast64_t>::max();
    }
    else {
        _config.max_number_of_active_versions = maximumNumberOfActiveVersions;
    }
}

- (void)setDynamic:(bool)dynamic {
    _dynamic = dynamic;
    self.cache = !dynamic;
}

- (bool)disableFormatUpgrade {
    return _config.disable_format_upgrade;
}

- (void)setDisableFormatUpgrade:(bool)disableFormatUpgrade {
    _config.disable_format_upgrade = disableFormatUpgrade;
}

- (realm::SchemaMode)schemaMode {
    return _config.schema_mode;
}

- (void)setSchemaMode:(realm::SchemaMode)mode {
    _config.schema_mode = mode;
}

- (NSString *)pathOnDisk {
    return @(_config.path.c_str());
}

- (void)setShouldCompactOnLaunch:(RLMShouldCompactOnLaunchBlock)shouldCompactOnLaunch {
    if (shouldCompactOnLaunch) {
        if (_config.immutable()) {
            @throw RLMException(@"Cannot set `shouldCompactOnLaunch` when `readOnly` is set.");
        }
        _config.should_compact_on_launch_function = shouldCompactOnLaunch;
    }
    else {
        _config.should_compact_on_launch_function = nullptr;
    }
    _shouldCompactOnLaunch = shouldCompactOnLaunch;
}

- (void)setCustomSchemaWithoutCopying:(RLMSchema *)schema {
    _customSchema = schema;
}

#if REALM_ENABLE_SYNC
- (void)setSyncConfiguration:(RLMSyncConfiguration *)syncConfiguration {
    if (syncConfiguration == nil) {
        _config.sync_config = nullptr;
        return;
    }
    RLMUser *user = syncConfiguration.user;
    if (user.state == RLMUserStateRemoved) {
        @throw RLMException(@"Cannot set a sync configuration which has an errored-out user.");
    }

    NSAssert(user.identifier, @"Cannot call this method on a user that doesn't have an identifier.");
    _config.in_memory = false;
    _config.sync_config = std::make_shared<realm::SyncConfig>(syncConfiguration.rawConfiguration);
    _config.path = syncConfiguration.path;

    // The manual client reset handler doesn't exist on the raw config,
    // so assign it here.
    _manualClientResetHandler = syncConfiguration.manualClientResetHandler;

    [self updateSchemaMode];
}

- (RLMSyncConfiguration *)syncConfiguration {
    if (!_config.sync_config) {
        return nil;
    }
    RLMSyncConfiguration* syncConfig = [[RLMSyncConfiguration alloc] initWithRawConfig:*_config.sync_config path:_config.path];
    syncConfig.manualClientResetHandler = _manualClientResetHandler;
    return syncConfig;
}

#else // REALM_ENABLE_SYNC
- (RLMSyncConfiguration *)syncConfiguration {
    return nil;
}
#endif // REALM_ENABLE_SYNC

- (realm::Realm::Config)config {
    auto config = _config;
    if (config.sync_config) {
        config.sync_config = std::make_shared<realm::SyncConfig>(*config.sync_config);
    }
#if REALM_ENABLE_SYNC
    if (config.sync_config) {
        RLMSetConfigInfoForClientResetCallbacks(*config.sync_config, self);
    }
    if (_eventConfiguration) {
        config.audit_config = [_eventConfiguration auditConfigWithRealmConfiguration:self];
    }
#endif
    return config;
}

@end
