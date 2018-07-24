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

#import "RLMRealmConfiguration_Private.hpp"
#import "RLMTestObjects.h"
#import "RLMUtil.hpp"

@interface RealmConfigurationTests : RLMTestCase
@end

@implementation RealmConfigurationTests

#pragma mark - Setter Validation

- (void)testSetPathAndInMemoryIdentifierAreMutuallyExclusive {
    RLMRealmConfiguration *configuration = [[RLMRealmConfiguration alloc] init];

    configuration.inMemoryIdentifier = @"identifier";
    XCTAssertNil(configuration.fileURL);
    XCTAssertEqualObjects(configuration.inMemoryIdentifier, @"identifier");

    configuration.fileURL = [NSURL fileURLWithPath:@"/dev/null"];
    XCTAssertNil(configuration.inMemoryIdentifier);
    XCTAssertEqualObjects(configuration.fileURL.path, @"/dev/null");
}

- (void)testFileURLValidation {
    RLMRealmConfiguration *configuration = [[RLMRealmConfiguration alloc] init];
    XCTAssertThrows(configuration.fileURL = nil);
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

- (void)testCannotSetMutuallyExclusiveProperties {
    RLMRealmConfiguration *configuration = [[RLMRealmConfiguration alloc] init];
    XCTAssertNoThrow(configuration.readOnly = YES);
    XCTAssertNoThrow(configuration.deleteRealmIfMigrationNeeded = NO);
    XCTAssertThrows(configuration.deleteRealmIfMigrationNeeded = YES);
    XCTAssertNoThrow(configuration.readOnly = NO);
    XCTAssertNoThrow(configuration.deleteRealmIfMigrationNeeded = YES);
    XCTAssertNoThrow(configuration.readOnly = NO);
    XCTAssertThrows(configuration.readOnly = YES);
}

#pragma mark - Default Configuration

- (void)testDefaultConfiguration {
    RLMRealmConfiguration *defaultConfiguration = [RLMRealmConfiguration defaultConfiguration];
    XCTAssertEqualObjects(defaultConfiguration.fileURL, RLMDefaultRealmURL());
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
    configuration.fileURL = [NSURL fileURLWithPath:@"/dev/null"];
    [RLMRealmConfiguration setDefaultConfiguration:configuration];
    XCTAssertEqualObjects(RLMRealmConfiguration.defaultConfiguration.fileURL.path, @"/dev/null");
}

- (void)testDefaultConfigurationUsesValueSemantics {
    RLMRealmConfiguration *config = [RLMRealmConfiguration defaultConfiguration];
    config.fileURL = [NSURL fileURLWithPath:@"/dev/null"];
    XCTAssertNotEqualObjects(config.fileURL, RLMRealmConfiguration.defaultConfiguration.fileURL);

    [RLMRealmConfiguration setDefaultConfiguration:config];
    XCTAssertEqualObjects(config.fileURL, RLMRealmConfiguration.defaultConfiguration.fileURL);

    config.fileURL = [NSURL fileURLWithPath:@"/dev/null/foo"];
    XCTAssertNotEqualObjects(config.fileURL, RLMRealmConfiguration.defaultConfiguration.fileURL);
}

- (void)testDefaultRealmUsesDefaultConfiguration {
    RLMRealmConfiguration *config = [RLMRealmConfiguration defaultConfiguration];
    @autoreleasepool { XCTAssertEqualObjects(RLMRealm.defaultRealm.configuration.fileURL, config.fileURL); }

    config.fileURL = RLMTestRealmURL();
    @autoreleasepool { XCTAssertNotEqualObjects(RLMRealm.defaultRealm.configuration.fileURL, config.fileURL); }
    RLMRealmConfiguration.defaultConfiguration = config;
    @autoreleasepool { XCTAssertEqualObjects(RLMRealm.defaultRealm.configuration.fileURL, config.fileURL); }

    config.inMemoryIdentifier = NSUUID.UUID.UUIDString;
    RLMRealmConfiguration.defaultConfiguration = config;
    @autoreleasepool {
        RLMRealm *realm = RLMRealm.defaultRealm;
        NSString *realmPath = @(realm.configuration.config.path.c_str());
        XCTAssertTrue([realmPath hasSuffix:config.inMemoryIdentifier]);
        XCTAssertTrue([realmPath hasPrefix:NSTemporaryDirectory()]);
    }

    config.schemaVersion = 1;
    RLMRealmConfiguration.defaultConfiguration = config;
    @autoreleasepool {
        RLMRealm *realm = RLMRealm.defaultRealm;
        NSString *realmPath = @(realm.configuration.config.path.c_str());
        XCTAssertEqual(1U, [RLMRealm schemaVersionAtURL:[NSURL fileURLWithPath:realmPath] encryptionKey:nil error:nil]);
    }

    config.fileURL = RLMDefaultRealmURL();
    RLMRealmConfiguration.defaultConfiguration = config;

    config.encryptionKey = RLMGenerateKey();
    RLMRealmConfiguration.defaultConfiguration = config;
    @autoreleasepool {
        // Realm with no encryption key already exists from above
        XCTAssertThrows([RLMRealm defaultRealm]);
    }

    [self deleteRealmFileAtURL:config.fileURL];
    // Create and then re-open with same key
    @autoreleasepool { XCTAssertNoThrow([RLMRealm defaultRealm]); }
    @autoreleasepool { XCTAssertNoThrow([RLMRealm defaultRealm]); }

    // Fail to re-open with a different key
    config.encryptionKey = RLMGenerateKey();
    RLMRealmConfiguration.defaultConfiguration = config;
    @autoreleasepool { XCTAssertThrows([RLMRealm defaultRealm]); }

    // Verify that the default realm's migration block is used implicitly
    // when needed
    [self deleteRealmFileAtURL:config.fileURL];
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
