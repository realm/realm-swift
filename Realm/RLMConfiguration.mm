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

#import "RLMConfiguration_Private.h"
#import "RLMRealm_Private.h"
#import "RLMUtil.hpp"

#include <atomic>

static NSString * const c_RLMConfigurationProperties[] = {
    @"path",
    @"inMemoryIdentifier",
    @"encryptionKey",
    @"readOnly",
    @"schemaVersion",
    @"migrationBlock",
    @"dynamic",
    @"customSchema",
};
static const NSUInteger c_RLMConfigurationPropertiesCount = sizeof(c_RLMConfigurationProperties) / sizeof(NSString *);

typedef NS_ENUM(NSUInteger, RLMConfigurationUsage) {
    RLMConfigurationUsageNone,
    RLMConfigurationUsageConfiguration,
    RLMConfigurationUsagePerPath,
};

static std::atomic<RLMConfigurationUsage> s_configurationUsage;

@implementation RLMConfiguration

RLMConfiguration *s_defaultConfiguration;
static NSString * const c_defaultRealmFileName = @"default.realm";

+ (NSString *)defaultRealmPath
{
    static NSString *defaultRealmPath;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        defaultRealmPath = [[self class] writeablePathForFile:c_defaultRealmFileName];
    });
    return defaultRealmPath;
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

+ (instancetype)defaultConfiguration {
    if (!s_defaultConfiguration) {
        s_defaultConfiguration = [[RLMConfiguration alloc] init];
    }
    return [s_defaultConfiguration copy];
}

+ (void)setDefaultConfiguration:(RLMConfiguration *)configuration {
    if (s_configurationUsage.exchange(RLMConfigurationUsageConfiguration) == RLMConfigurationUsagePerPath) {
        @throw RLMException(@"Cannot set a default configuration after using per-path configuration methods.");
    }
    s_defaultConfiguration = [configuration copy] ?: [[RLMConfiguration alloc] init];
}

+ (void)setDefaultPath:(NSString *)path {
    RLMConfiguration *configuration = [[RLMConfiguration alloc] init];
    configuration.path = path;
    s_defaultConfiguration = configuration;
}

+ (void)resetRealmConfigurationState {
    s_defaultConfiguration = nil;
    s_configurationUsage = RLMConfigurationUsageNone;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.path = [[self class] defaultRealmPath];
    }

    return self;
}

- (instancetype)copyWithZone:(NSZone *)zone {
    RLMConfiguration *configuration = [[[self class] allocWithZone:zone] init];
    for (NSUInteger i = 0; i < c_RLMConfigurationPropertiesCount; i++) {
        NSString *key = c_RLMConfigurationProperties[i];
        [configuration setValue:[self valueForKey:key] forKey:key];
    }
    return configuration;
}

- (NSString *)description {
    NSMutableString *string = [NSMutableString stringWithFormat:@"%@ {\n", self.class];
    for (NSUInteger i = 0; i < c_RLMConfigurationPropertiesCount; i++) {
        NSString *key = c_RLMConfigurationProperties[i];
        NSString *description = [[self valueForKey:key] description];
        description = [description stringByReplacingOccurrencesOfString:@"\n" withString:@"\n\t"];

        [string appendFormat:@"\t%@ = %@;\n", key, description];
    }
    return [string stringByAppendingString:@"}"];
}

- (void)setInMemoryIdentifier:(NSString *)inMemoryIdentifier {
    if ((_inMemoryIdentifier = inMemoryIdentifier)) {
        _path = nil;
    }
}

- (void)setPath:(NSString *)path {
    if ((_path = path)) {
        _inMemoryIdentifier = nil;
    }
}

- (void)setEncryptionKey:(NSData * __nullable)encryptionKey {
    _encryptionKey = RLMRealmValidatedEncryptionKey(encryptionKey);
}

- (void)setSchemaVersion:(uint64_t)schemaVersion {
    if ((_schemaVersion = schemaVersion) == RLMNotVersioned) {
        @throw RLMException([NSString stringWithFormat:@"Cannot set schema version to %llu (RLMNotVersioned)", RLMNotVersioned]);
    }
}

@end

void RLMConfigurationUsePerPath(SEL callingMethod) {
    if (s_configurationUsage.exchange(RLMConfigurationUsagePerPath) == RLMConfigurationUsageConfiguration) {
        @throw RLMException([NSString stringWithFormat:@"Cannot call %@ after setting a default configuration.", NSStringFromSelector(callingMethod)]);
    }
}
