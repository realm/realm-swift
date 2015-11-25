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

#import "RLMTestCase.h"

#import "RLMRealmConfiguration_Private.h"
#import "RLMTestObjects.h"
#import "RLMUtil.hpp"

@interface RealmConfigurationTests : RLMTestCase

@end

@implementation RealmConfigurationTests

#pragma mark - Setter Validation

- (void)testSetPathAndInMemoryIdentifierAreMutuallyExclusive {
    RLMRealmConfiguration *configuration = [[RLMRealmConfiguration alloc] init];

    configuration.inMemoryIdentifier = @"identifier";
    XCTAssertNil(configuration.path);
    XCTAssertEqualObjects(configuration.inMemoryIdentifier, @"identifier");

    configuration.path = @"path";
    XCTAssertNil(configuration.inMemoryIdentifier);
    XCTAssertEqualObjects(configuration.path, @"path");
}

- (void)testPathValidation {
    RLMRealmConfiguration *configuration = [[RLMRealmConfiguration alloc] init];
    XCTAssertThrows(configuration.path = nil);
    XCTAssertThrows(configuration.path = @"");
}

- (void)testEncryptionKeyValidation {
    RLMRealmConfiguration *configuration = [[RLMRealmConfiguration alloc] init];
    XCTAssertNoThrow(configuration.encryptionKey = nil);

    RLMAssertThrowsWithReasonMatching(configuration.encryptionKey = [NSData data], @"Encryption key must be exactly 64 bytes long");

    NSData *key = RLMGenerateKey();
    configuration.encryptionKey = key;
    XCTAssertEqualObjects(configuration.encryptionKey, key);
}

- (void)testSchemaVersionValidation {
    RLMRealmConfiguration *configuration = [[RLMRealmConfiguration alloc] init];

    RLMAssertThrowsWithReasonMatching(configuration.schemaVersion = RLMNotVersioned, @"schema version.*RLMNotVersioned");

    configuration.schemaVersion = 1;
    XCTAssertEqual(configuration.schemaVersion, 1U);

    configuration.schemaVersion = std::numeric_limits<uint64_t>::max() - 1;
    XCTAssertEqual(configuration.schemaVersion, std::numeric_limits<uint64_t>::max() - 1);
}

- (void)testClassSubsetsValidateLinks {
    RLMRealmConfiguration *configuration = [[RLMRealmConfiguration alloc] init];

    XCTAssertThrows(configuration.objectClasses = @[LinkStringObject.class]);
    XCTAssertNoThrow(configuration.objectClasses = (@[LinkStringObject.class, StringObject.class]));

    XCTAssertThrows(configuration.objectClasses = @[CompanyObject.class]);
    XCTAssertNoThrow(configuration.objectClasses = (@[CompanyObject.class, EmployeeObject.class]));
}

#pragma mark - Default Confiugration

- (void)testDefaultConfiguration {
    RLMRealmConfiguration *defaultConfiguration = [RLMRealmConfiguration defaultConfiguration];
    XCTAssertEqualObjects(defaultConfiguration.path, RLMDefaultRealmPath());
    XCTAssertNil(defaultConfiguration.inMemoryIdentifier);
    XCTAssertNil(defaultConfiguration.encryptionKey);
    XCTAssertFalse(defaultConfiguration.readOnly);
    XCTAssertEqual(defaultConfiguration.schemaVersion, 0U);
    XCTAssertNil(defaultConfiguration.migrationBlock);

    // private properties
    XCTAssertFalse(defaultConfiguration.dynamic);
    XCTAssertNil(defaultConfiguration.customSchema);
}

- (void)testSetDefaultConfiguration {
    RLMRealmConfiguration *configuration = [[RLMRealmConfiguration alloc] init];
    configuration.path = @"path";
    [RLMRealmConfiguration setDefaultConfiguration:configuration];
    XCTAssertEqualObjects(RLMRealmConfiguration.defaultConfiguration.path, @"path");
}

- (void)testDefaultConfiugrationUsesValueSemantics {
    RLMRealmConfiguration *config = [RLMRealmConfiguration defaultConfiguration];
    config.path = @"path";
    XCTAssertNotEqualObjects(config.path, RLMRealmConfiguration.defaultConfiguration.path);

    [RLMRealmConfiguration setDefaultConfiguration:config];
    XCTAssertEqualObjects(config.path, RLMRealmConfiguration.defaultConfiguration.path);

    config.path = @"path2";
    XCTAssertNotEqualObjects(config.path, RLMRealmConfiguration.defaultConfiguration.path);
}

- (void)testDefaultRealmUsesDefaultConfiguration {
    RLMRealmConfiguration *config = [RLMRealmConfiguration defaultConfiguration];
    @autoreleasepool { XCTAssertEqualObjects(RLMRealm.defaultRealm.path, config.path); }

    config.path = RLMTestRealmPath();
    @autoreleasepool { XCTAssertNotEqualObjects(RLMRealm.defaultRealm.path, config.path); }
    RLMRealmConfiguration.defaultConfiguration = config;
    @autoreleasepool { XCTAssertEqualObjects(RLMRealm.defaultRealm.path, config.path); }

    config.inMemoryIdentifier = @"default";
    RLMRealmConfiguration.defaultConfiguration = config;
    @autoreleasepool {
        RLMRealm *realm = RLMRealm.defaultRealm;
        XCTAssertTrue([realm.path hasSuffix:@"/default"]);
        XCTAssertTrue([realm.path hasPrefix:NSTemporaryDirectory()]);
    }

    config.schemaVersion = 1;
    RLMRealmConfiguration.defaultConfiguration = config;
    @autoreleasepool {
        RLMRealm *realm = RLMRealm.defaultRealm;
        XCTAssertEqual(1U, [RLMRealm schemaVersionAtPath:realm.path error:nil]);
    }

    config.path = RLMDefaultRealmPath();
    RLMRealmConfiguration.defaultConfiguration = config;

    config.encryptionKey = RLMGenerateKey();
    RLMRealmConfiguration.defaultConfiguration = config;
    @autoreleasepool {
        // Realm with no encryption key already exists from above
        XCTAssertThrows([RLMRealm defaultRealm]);
    }

    [self deleteRealmFileAtPath:config.path];
    // Create and then re-open with same key
    @autoreleasepool { XCTAssertNoThrow([RLMRealm defaultRealm]); }
    @autoreleasepool { XCTAssertNoThrow([RLMRealm defaultRealm]); }

    // Fail to re-open with a different key
    config.encryptionKey = RLMGenerateKey();
    RLMRealmConfiguration.defaultConfiguration = config;
    @autoreleasepool { XCTAssertThrows([RLMRealm defaultRealm]); }

    // Verify that the default realm's migration block is used implicitly
    // when needed
    [self deleteRealmFileAtPath:config.path];
    @autoreleasepool { XCTAssertNoThrow([RLMRealm defaultRealm]); }

    config.schemaVersion = 2;
    __block bool migrationCalled = false;
    config.migrationBlock = ^(RLMMigration *, uint64_t) {
        migrationCalled = true;
    };
    RLMRealmConfiguration.defaultConfiguration = config;

    XCTAssertFalse(migrationCalled);
    @autoreleasepool { XCTAssertNoThrow([RLMRealm defaultRealm]); }
    XCTAssertTrue(migrationCalled);
}

@end
