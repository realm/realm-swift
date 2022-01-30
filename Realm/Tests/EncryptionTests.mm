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

#import "RLMObjectSchema_Private.h"
#import "RLMRealmConfiguration_Private.h"
#import "RLMRealm_Private.h"
#import "RLMSchema_Private.h"
#import "RLMUtil.hpp"

@interface EncryptionTests : RLMTestCase
@end

@implementation EncryptionTests

- (RLMRealmConfiguration *)configurationWithKey:(NSData *)key {
    RLMRealmConfiguration *configuration = [[RLMRealmConfiguration alloc] init];
    configuration.fileURL = RLMDefaultRealmURL();
    configuration.encryptionKey = key;
    return configuration;
}

- (RLMRealm *)realmWithKey:(NSData *)key {
    return [RLMRealm realmWithConfiguration:[self configurationWithKey:key] error:nil];
}

#pragma mark - Key validation

- (void)testBadEncryptionKeys {
    XCTAssertThrows([RLMRealm.defaultRealm writeCopyToURL:RLMTestRealmURL() encryptionKey:NSData.data error:nil]);
}

- (void)testValidEncryptionKeys {
    XCTAssertNoThrow([RLMRealm.defaultRealm writeCopyToURL:RLMTestRealmURL() encryptionKey:self.nonLiteralNil error:nil]);
    NSData *key = [[NSMutableData alloc] initWithLength:64];
    XCTAssertNoThrow([RLMRealm.defaultRealm writeCopyToURL:RLMTestRealmURL() encryptionKey:key error:nil]);
}

#pragma mark - realmWithURL:

- (void)testReopenWithSameKeyWorks {
    NSData *key = RLMGenerateKey();
    @autoreleasepool {
        RLMRealm *realm = [self realmWithKey:key];
        [realm transactionWithBlock:^{
            [IntObject createInRealm:realm withValue:@[@1]];
        }];
    }

    @autoreleasepool {
        RLMRealm *realm = [self realmWithKey:key];
        XCTAssertEqual(1U, [IntObject allObjectsInRealm:realm].count);
    }
}

// FIXME: core 10.0.0-alpha.3 does not throw the correct exception for this test
- (void)SKIP_testReopenWithNoKeyThrows {
    NSData *key = RLMGenerateKey();
    @autoreleasepool {
        [self realmWithKey:key];
    }

    @autoreleasepool {
        RLMAssertThrowsWithError([RLMRealm defaultRealm],
                                 @"Unable to open a realm at path",
                                 RLMErrorFileAccess,
                                 @"invalid mnemonic");
    }
}

- (void)testReopenWithWrongKeyThrows {
    @autoreleasepool {
        NSData *key = RLMGenerateKey();
        [self realmWithKey:key];
    }

    @autoreleasepool {
        NSData *key = RLMGenerateKey();
        RLMAssertThrowsWithError([self realmWithKey:key],
                                 @"Unable to open a realm at path",
                                 RLMErrorFileAccess,
                                 @"Realm file decryption failed");
    }
}

- (void)testOpenUnencryptedWithKeyThrows {
    @autoreleasepool {
        [RLMRealm defaultRealm];
    }

    @autoreleasepool {
        NSData *key = RLMGenerateKey();
        // FIXME: Should throw a "Realm file decryption failed" exception
        // https://github.com/realm/realm-swift-private/issues/347
        XCTAssertThrows([self realmWithKey:key]);
        // RLMAssertThrowsWithError([self realmWithKey:key],
        //                          @"Unable to open a realm at path",
        //                          RLMErrorFileAccess,
        //                          @"Realm file decryption failed");
    }
}

- (void)testOpenWithNewKeyWhileAlreadyOpenThrows {
    [self realmWithKey:RLMGenerateKey()];
    RLMAssertThrows([self realmWithKey:RLMGenerateKey()], @"already opened with different encryption key");
}

#pragma mark - writeCopyToURL:

- (void)testWriteCopyToPathWithNoKeyWritesDecrypted {
    NSData *key = RLMGenerateKey();
    @autoreleasepool {
        RLMRealm *realm = [self realmWithKey:key];
        [realm transactionWithBlock:^{
            [IntObject createInRealm:realm withValue:@[@1]];
        }];
        [realm writeCopyToURL:RLMTestRealmURL() encryptionKey:nil error:nil];
    }

    @autoreleasepool {
        RLMRealmConfiguration *config = [self configurationWithKey:nil];
        config.fileURL = RLMTestRealmURL();
        RLMRealm *realm = [RLMRealm realmWithConfiguration:config error:nil];
        XCTAssertEqual(1U, [IntObject allObjectsInRealm:realm].count);
    }
}

- (void)testWriteCopyToPathWithNewKey {
    NSData *key1 = RLMGenerateKey();
    NSData *key2 = RLMGenerateKey();

    @autoreleasepool {
        RLMRealm *realm = [self realmWithKey:key1];
        [realm transactionWithBlock:^{
            [IntObject createInRealm:realm withValue:@[@1]];
        }];
        [realm writeCopyToURL:RLMTestRealmURL() encryptionKey:key2 error:nil];
    }

    @autoreleasepool {
        RLMRealmConfiguration *config = [self configurationWithKey:key2];
        config.fileURL = RLMTestRealmURL();
        RLMRealm *realm = [RLMRealm realmWithConfiguration:config error:nil];
        XCTAssertEqual(1U, [IntObject allObjectsInRealm:realm].count);
    }
}

- (void)testWriteCopyForConfigurationAndKey {
    NSData *key1 = RLMGenerateKey();
    NSData *key2 = RLMGenerateKey();

    RLMRealmConfiguration *destinationConfig = [self configurationWithKey:key2];
    destinationConfig.encryptionKey = key2;
    destinationConfig.fileURL = RLMTestRealmURL();

    @autoreleasepool {
        RLMRealm *realm = [self realmWithKey:key1];
        [realm transactionWithBlock:^{
            [IntObject createInRealm:realm withValue:@[@1]];
        }];
        [realm writeCopyForConfiguration:destinationConfig error:nil];
    }

    @autoreleasepool {
        RLMRealm *realm = [RLMRealm realmWithConfiguration:destinationConfig error:nil];
        XCTAssertEqual(1U, [IntObject allObjectsInRealm:realm].count);
    }
}

#pragma mark - Migrations

- (void)createRealmRequiringMigrationWithKey:(NSData *)key migrationRun:(BOOL *)migrationRun {
    // Create an object schema which requires migration to the shared schema
    RLMObjectSchema *objectSchema = [RLMObjectSchema schemaForObjectClass:IntObject.class];
    objectSchema.properties = @[];

    RLMSchema *schema = [[RLMSchema alloc] init];
    schema.objectSchema = @[objectSchema];

    // Create the Realm file on disk
    @autoreleasepool {
        RLMRealmConfiguration *config = [RLMRealmConfiguration defaultConfiguration];
        config.encryptionKey = key;
        config.customSchema = schema;
        [RLMRealm realmWithConfiguration:config error:nil];
    }

    RLMRealmConfiguration *config = [RLMRealmConfiguration defaultConfiguration];
    config.schemaVersion = 1;
    config.migrationBlock = ^(__unused RLMMigration *migration, __unused uint64_t oldSchemaVersion) {
        *migrationRun = YES;
    };
    [RLMRealmConfiguration setDefaultConfiguration:config];
}

- (void)testImplicitMigration {
    NSData *key = RLMGenerateKey();
    BOOL migrationRan = NO;
    [self createRealmRequiringMigrationWithKey:key migrationRun:&migrationRan];

    XCTAssertThrows([RLMRealm defaultRealm]);
    XCTAssertFalse(migrationRan);

    RLMRealmConfiguration *config = [RLMRealmConfiguration defaultConfiguration];
    config.encryptionKey = key;
    XCTAssertNoThrow([RLMRealm realmWithConfiguration:config error:nil]);
    XCTAssertTrue(migrationRan);
}

- (void)testExplicitMigration {
    NSData *key = RLMGenerateKey();
    __block BOOL migrationRan = NO;
    [self createRealmRequiringMigrationWithKey:key migrationRun:&migrationRan];

    RLMRealmConfiguration *configuration = [RLMRealmConfiguration defaultConfiguration];
    configuration.schemaVersion = 1;
    configuration.migrationBlock = ^(__unused RLMMigration *migration, __unused uint64_t oldSchemaVersion) {
        migrationRan = YES;
    };

    XCTAssertFalse([RLMRealm performMigrationForConfiguration:configuration error:nil]);
    XCTAssertFalse(migrationRan);

    configuration.encryptionKey = key;
    XCTAssertTrue([RLMRealm performMigrationForConfiguration:configuration error:nil]);
    XCTAssertTrue(migrationRan);
}

@end
