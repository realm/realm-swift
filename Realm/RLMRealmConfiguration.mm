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

#import "RLMRealm_Private.h"
#import "RLMSchema_Private.h"
#import "RLMUtil.hpp"

static NSString *const c_RLMRealmConfigurationProperties[] = {
    @"path",
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

NSString *RLMRealmPathForFile(NSString *fileName) {
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

@implementation RLMRealmConfiguration

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
        static NSString *defaultRealmPath = RLMRealmPathForFile(c_defaultRealmFileName);
        self.path = defaultRealmPath;
    }

    return self;
}

- (instancetype)copyWithZone:(NSZone *)zone {
    RLMRealmConfiguration *configuration = [[[self class] allocWithZone:zone] init];
    configuration->_path = _path;
    configuration->_inMemoryIdentifier = _inMemoryIdentifier;
    configuration->_encryptionKey = _encryptionKey;
    configuration->_readOnly = _readOnly;
    configuration->_schemaVersion = _schemaVersion;
    configuration->_migrationBlock = _migrationBlock;
    configuration->_dynamic = _dynamic;
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

- (void)setInMemoryIdentifier:(NSString *)inMemoryIdentifier {
    if (inMemoryIdentifier.length == 0) {
        @throw RLMException(@"In-memory identifier must not be empty");
    }

    _inMemoryIdentifier = [inMemoryIdentifier copy];
    _path = nil;
}

- (void)setPath:(NSString *)path {
    if (path.length == 0) {
        @throw RLMException(@"Realm path must not be empty");
    }

    _path = [path copy];
    _inMemoryIdentifier = nil;
}

- (void)setEncryptionKey:(NSData * __nullable)encryptionKey {
    _encryptionKey = [RLMRealmValidatedEncryptionKey(encryptionKey) copy];
}

- (void)setSchemaVersion:(uint64_t)schemaVersion {
    if ((_schemaVersion = schemaVersion) == RLMNotVersioned) {
        @throw RLMException(@"Cannot set schema version to %llu (RLMNotVersioned)", RLMNotVersioned);
    }
}

- (void)setObjectClasses:(NSArray *)objectClasses {
    _customSchema = [RLMSchema schemaWithObjectClasses:objectClasses];
}

- (NSArray *)objectClasses {
    return [_customSchema.objectSchema valueForKeyPath:@"objectClass"];
}

@end

