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
#import "RLMRealm_Private.h"
#import "RLMSchema_Private.h"
#import "RLMUtil.hpp"

@interface EncryptionTests : RLMTestCase
@end

@implementation EncryptionTests

- (RLMRealmConfiguration *)configurationWithKey:(NSData *)key {
    RLMRealmConfiguration *configuration = [[RLMRealmConfiguration alloc] init];
    configuration.path = RLMDefaultRealmPath();
    configuration.encryptionKey = key;
    return configuration;
}

- (RLMRealm *)realmWithKey:(NSData *)key {
    return [RLMRealm realmWithConfiguration:[self configurationWithKey:key] error:nil];
}

#pragma mark - Key validation

- (void)testBadEncryptionKeys {
    XCTAssertThrows([RLMRealm.defaultRealm writeCopyToPath:RLMTestRealmPath() encryptionKey:self.nonLiteralNil error:nil]);
    XCTAssertThrows([RLMRealm.defaultRealm writeCopyToPath:RLMTestRealmPath() encryptionKey:NSData.data error:nil]);
}

- (void)testValidEncryptionKeys {
    NSData *key = [[NSMutableData alloc] initWithLength:64];
    XCTAssertNoThrow([RLMRealm.defaultRealm writeCopyToPath:RLMTestRealmPath() encryptionKey:key error:nil]);
}

#pragma mark - realmWithPath:

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

- (void)testReopenWithNoKeyThrows {
    NSData *key = RLMGenerateKey();
    @autoreleasepool {
        [self realmWithKey:key];
    }

    @autoreleasepool {
        XCTAssertThrows([RLMRealm defaultRealm]);
    }
}

- (void)testReopenWithWrongKeyThrows {
    @autoreleasepool {
        NSData *key = RLMGenerateKey();
        [self realmWithKey:key];
    }

    @autoreleasepool {
        NSData *key = RLMGenerateKey();
        XCTAssertThrows([self realmWithKey:key]);
    }
}

- (void)testOpenUnencryptedWithKeyThrows {
    @autoreleasepool {
        [RLMRealm defaultRealm];
    }

    @autoreleasepool {
        NSData *key = RLMGenerateKey();
        XCTAssertThrows([self realmWithKey:key]);
    }
}

- (void)testOpenWithNewKeyWhileAlreadyOpenThrows {
    [self realmWithKey:RLMGenerateKey()];
    XCTAssertThrows([self realmWithKey:RLMGenerateKey()]);
}

#pragma mark - writeCopyToPath:

- (void)testWriteCopyToPathWithNoKeyWritesDecrypted {
    NSData *key = RLMGenerateKey();
    @autoreleasepool {
        RLMRealm *realm = [self realmWithKey:key];
        [realm transactionWithBlock:^{
            [IntObject createInRealm:realm withValue:@[@1]];
        }];
        [realm writeCopyToPath:RLMTestRealmPath() error:nil];
    }

    @autoreleasepool {
        RLMRealm *realm = [self realmWithTestPath];
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
        [realm writeCopyToPath:RLMTestRealmPath() encryptionKey:key2 error:nil];
    }

    @autoreleasepool {
        RLMRealmConfiguration *config = [self configurationWithKey:key2];
        config.path = RLMTestRealmPath();
        RLMRealm *realm = [RLMRealm realmWithConfiguration:config error:nil];
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
        [RLMRealm realmWithPath:RLMDefaultRealmPath() key:key readOnly:NO
                       inMemory:NO dynamic:YES schema: schema error:nil];
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

    XCTAssertNotNil([RLMRealm migrateRealm:configuration]);
    XCTAssertFalse(migrationRan);

    configuration.encryptionKey = key;
    XCTAssertNil([RLMRealm migrateRealm:configuration]);
    XCTAssertTrue(migrationRan);
}

@end
