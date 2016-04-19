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

#import "RLMObjectSchema_Private.hpp"
#import "RLMRealm_Private.h"
#import "RLMSchema_Private.hpp"
#import "RLMUtil.hpp"

#import "schema.hpp"
#import "shared_realm.hpp"

static NSString *const c_RLMRealmConfigurationProperties[] = {
    @"fileURL",
    @"inMemoryIdentifier",
    @"encryptionKey",
    @"readOnly",
    @"schemaVersion",
    @"migrationBlock",
    @"dynamic",
    @"customSchema",
};

static NSString *const c_defaultRealmFileName = @"default.realm";
RLMRealmConfiguration *s_defaultConfiguration;

NSString *RLMRealmPathForFileAndBundleIdentifier(NSString *fileName, NSString *bundleIdentifier) {
#if TARGET_OS_TV
    (void)bundleIdentifier;
    // tvOS prohibits writing to the Documents directory, so we use the Library/Caches directory instead.
    NSString *path = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES)[0];
#elif TARGET_OS_IPHONE
    (void)bundleIdentifier;
    // On iOS the Documents directory isn't user-visible, so put files there
    NSString *path = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
#else
    // On OS X it is, so put files in Application Support. If we aren't running
    // in a sandbox, put it in a subdirectory based on the bundle identifier
    // to avoid accidentally sharing files between applications
    NSString *path = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES)[0];
    if (![[NSProcessInfo processInfo] environment][@"APP_SANDBOX_CONTAINER_ID"]) {
        if (!bundleIdentifier) {
            bundleIdentifier = [NSBundle mainBundle].bundleIdentifier;
        }
        if (!bundleIdentifier) {
            bundleIdentifier = [NSBundle mainBundle].executablePath.lastPathComponent;
        }

        path = [path stringByAppendingPathComponent:bundleIdentifier];

        // create directory
        [[NSFileManager defaultManager] createDirectoryAtPath:path
                                  withIntermediateDirectories:YES
                                                   attributes:nil
                                                        error:nil];
    }
#endif
    return [path stringByAppendingPathComponent:fileName];
}

NSString *RLMRealmPathForFile(NSString *fileName) {
    return RLMRealmPathForFileAndBundleIdentifier(fileName, nil);
}

@implementation RLMRealmConfiguration {
    realm::Realm::Config _config;
}

- (realm::Realm::Config&)config {
    return _config;
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
    @synchronized(c_defaultRealmFileName) {
        if (!s_defaultConfiguration) {
            s_defaultConfiguration = [[RLMRealmConfiguration alloc] init];
        }
    }
    return s_defaultConfiguration;
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
    }

    return self;
}

- (instancetype)copyWithZone:(NSZone *)zone {
    RLMRealmConfiguration *configuration = [[[self class] allocWithZone:zone] init];
    configuration->_config = _config;
    configuration->_dynamic = _dynamic;
    configuration->_migrationBlock = _migrationBlock;
    configuration->_customSchema = _customSchema;
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

static void RLMNSStringToStdString(std::string &out, NSString *in) {
    out.resize([in maximumLengthOfBytesUsingEncoding:NSUTF8StringEncoding]);
    if (out.empty()) {
        return;
    }

    NSUInteger size = out.size();
    [in getBytes:&out[0]
       maxLength:size
      usedLength:&size
        encoding:NSUTF8StringEncoding
         options:0 range:{0, in.length} remainingRange:nullptr];
    out.resize(size);
}

- (NSURL *)fileURL {
    return _config.in_memory ? nil : [NSURL fileURLWithPath:@(_config.path.c_str())];
}

- (void)setFileURL:(NSURL *)fileURL {
    NSString *path = fileURL.path;
    if (path.length == 0) {
        @throw RLMException(@"Realm path must not be empty");
    }

    RLMNSStringToStdString(_config.path, path);
    _config.in_memory = false;
}

- (NSString *)path {
    return self.fileURL.path;
}

- (void)setPath:(NSString *)path {
    self.fileURL = [NSURL fileURLWithPath:path];
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

    RLMNSStringToStdString(_config.path, [NSTemporaryDirectory() stringByAppendingPathComponent:inMemoryIdentifier]);
    _config.in_memory = true;
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
    return _config.read_only;
}

- (void)setReadOnly:(BOOL)readOnly {
    _config.read_only = readOnly;
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

- (NSArray *)objectClasses {
    return [_customSchema.objectSchema valueForKeyPath:@"objectClass"];
}

- (void)setObjectClasses:(NSArray *)objectClasses {
    self.customSchema = [RLMSchema schemaWithObjectClasses:objectClasses];
}

- (void)setDynamic:(bool)dynamic {
    _dynamic = dynamic;
    _config.cache = !dynamic;
}

- (bool)cache {
    return _config.cache;
}

- (void)setCache:(bool)cache {
    _config.cache = cache;
}

- (void)setCustomSchema:(RLMSchema *)customSchema {
    _customSchema = customSchema;
    _config.schema = [_customSchema objectStoreCopy];
}

- (void)setDisableFormatUpgrade:(bool)disableFormatUpgrade
{
    _config.disable_format_upgrade = disableFormatUpgrade;
}

- (bool)disableFormatUpgrade
{
    return _config.disable_format_upgrade;
}

@end

