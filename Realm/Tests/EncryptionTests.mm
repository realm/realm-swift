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

- (RLMRealm *)realmWithKey:(NSData *)key {
    RLMConfiguration *configuration = [[RLMConfiguration alloc] init];
    configuration.path = RLMDefaultRealmPath();
    configuration.encryptionKey = key;
    return [RLMRealm realmWithConfiguration:configuration error:nil];
}

+ (XCTestSuite *)defaultTestSuite
{
    if (RLMIsDebuggerAttached()) {
        XCTestSuite *suite = [XCTestSuite testSuiteWithName:NSStringFromClass(self)];
        [suite addTest:[EncryptionTests testCaseWithSelector:@selector(encryptionTestsAreSkippedWhileDebuggerIsAttached)]];
        return suite;
    }

    return [super defaultTestSuite];
}

- (void)encryptionTestsAreSkippedWhileDebuggerIsAttached
{
}

#pragma mark - Key validation

- (void)testBadEncryptionKeys {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    XCTAssertThrows([RLMRealm realmWithPath:RLMRealm.defaultRealmPath encryptionKey:self.nonLiteralNil readOnly:NO error:nil]);
    XCTAssertThrows([RLMRealm realmWithPath:RLMRealm.defaultRealmPath encryptionKey:NSData.data readOnly:NO error:nil]);
    XCTAssertThrows([RLMRealm migrateRealmAtPath:RLMRealm.defaultRealmPath encryptionKey:self.nonLiteralNil]);
    XCTAssertThrows([RLMRealm migrateRealmAtPath:RLMRealm.defaultRealmPath encryptionKey:NSData.data]);
    XCTAssertThrows([RLMRealm setEncryptionKey:NSData.data forRealmsAtPath:RLMRealm.defaultRealmPath]);
    XCTAssertThrows([RLMRealm.defaultRealm writeCopyToPath:RLMTestRealmPath() encryptionKey:self.nonLiteralNil error:nil]);
    XCTAssertThrows([RLMRealm.defaultRealm writeCopyToPath:RLMTestRealmPath() encryptionKey:NSData.data error:nil]);
#pragma clang diagnostic pop
}

- (void)testValidEncryptionKeys {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    NSData *key = [[NSMutableData alloc] initWithLength:64];
    XCTAssertNoThrow([RLMRealm setEncryptionKey:key
                                forRealmsAtPath:RLMRealm.defaultRealmPath]);
    XCTAssertNoThrow([RLMRealm setEncryptionKey:nil forRealmsAtPath:RLMRealm.defaultRealmPath]);
    XCTAssertNoThrow([RLMRealm.defaultRealm writeCopyToPath:RLMTestRealmPath() encryptionKey:key error:nil]);
#pragma clang diagnostic pop
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

#pragma mark - Registered encryption key

- (void)testRegisteredKeyIsUsed {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    NSData *key = RLMGenerateKey();
    @autoreleasepool {
        RLMRealm *realm = [self realmWithKey:key];
        [realm transactionWithBlock:^{
            [IntObject createInRealm:realm withValue:@[@1]];
        }];
    }

    [RLMRealm setEncryptionKey:RLMGenerateKey() forRealmsAtPath:RLMDefaultRealmPath()];
    @autoreleasepool {
        XCTAssertThrows([IntObject allObjects]);
    }

    [RLMRealm setEncryptionKey:key forRealmsAtPath:RLMDefaultRealmPath()];
    @autoreleasepool {
        XCTAssertEqual(1U, [IntObject allObjects].count);
    }
#pragma clang diagnostic pop
}

- (void)testExplicitlyPassedKeyOverridesRegisteredKey {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    NSData *key = RLMGenerateKey();
    @autoreleasepool {
        RLMRealm *realm = [self realmWithKey:key];
        [realm transactionWithBlock:^{
            [IntObject createInRealm:realm withValue:@[@1]];
        }];
    }

    [RLMRealm setEncryptionKey:RLMGenerateKey() forRealmsAtPath:RLMDefaultRealmPath()];
    @autoreleasepool {
        RLMRealm *realm = [self realmWithKey:key];
        XCTAssertEqual(1U, [IntObject allObjectsInRealm:realm].count);
    }
#pragma clang diagnostic pop
}

- (void)testCannotSetEncryptionKeyToNilWhenRealmIsOpen {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    NSData *key = RLMGenerateKey();
    RLMRealm *realm = [self realmWithTestPath];
    NSString *path = realm.path;

    XCTAssertNoThrow([RLMRealm setEncryptionKey:nil forRealmsAtPath:path]);
    XCTAssertThrows([RLMRealm setEncryptionKey:key forRealmsAtPath:path]);
#pragma clang diagnostic pop
}

- (void)testCannotSetEncryptionKeyFromNilWhenRealmIsOpen {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    NSData *key = RLMGenerateKey();
    NSString *path = RLMTestRealmPath();
    [RLMRealm setEncryptionKey:key forRealmsAtPath:path];
    [self realmWithTestPath];

    XCTAssertThrows([RLMRealm setEncryptionKey:nil forRealmsAtPath:path]);
    XCTAssertNoThrow([RLMRealm setEncryptionKey:key forRealmsAtPath:path]);
#pragma clang diagnostic pop
}

#pragma mark - writeCopyToPath:

- (void)testWriteCopyToPathWithNoRegisteredKeyWritesDecrypted {
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

- (void)testWriteCopyToPathUsesRegisteredKey {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    NSData *key = RLMGenerateKey();
    [RLMRealm setEncryptionKey:key forRealmsAtPath:RLMTestRealmPath()];

    @autoreleasepool {
        RLMRealm *realm = [self realmWithKey:key];
        [realm transactionWithBlock:^{
            [IntObject createInRealm:realm withValue:@[@1]];
        }];
        [realm writeCopyToPath:RLMTestRealmPath() error:nil];
    }

    @autoreleasepool {
        RLMRealm *realm = [self realmWithKey:key];
        XCTAssertEqual(1U, [IntObject allObjectsInRealm:realm].count);
    }
#pragma clang diagnostic pop
}

- (void)testWriteCopyToPathWithNewKey {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    NSData *key1 = RLMGenerateKey();
    NSData *key2 = RLMGenerateKey();
    NSData *key3 = RLMGenerateKey();
    [RLMRealm setEncryptionKey:key3 forRealmsAtPath:RLMTestRealmPath()];

    @autoreleasepool {
        RLMRealm *realm = [self realmWithKey:key1];
        [realm transactionWithBlock:^{
            [IntObject createInRealm:realm withValue:@[@1]];
        }];
        [realm writeCopyToPath:RLMTestRealmPath() encryptionKey:key2 error:nil];
    }

    @autoreleasepool {
        RLMRealm *realm = [RLMRealm realmWithPath:RLMTestRealmPath()
                                    encryptionKey:key2
                                         readOnly:NO
                                            error:nil];
        XCTAssertEqual(1U, [IntObject allObjectsInRealm:realm].count);
    }
#pragma clang diagnostic pop
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

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    [RLMRealm setDefaultRealmSchemaVersion:1 withMigrationBlock:^(__unused RLMMigration *migration, __unused uint64_t oldSchemaVersion) {
        *migrationRun = YES;
    }];
#pragma clang diagnostic pop
}

- (void)testImplicitMigrationWithRegisteredKey {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    NSData *key = RLMGenerateKey();
    BOOL migrationRan = NO;
    [self createRealmRequiringMigrationWithKey:key migrationRun:&migrationRan];

    XCTAssertThrows([RLMRealm defaultRealm]);
    XCTAssertFalse(migrationRan);

    [RLMRealm setEncryptionKey:key forRealmsAtPath:RLMDefaultRealmPath()];
    XCTAssertNoThrow([RLMRealm defaultRealm]);
    XCTAssertTrue(migrationRan);
#pragma clang diagnostic pop
}

- (void)testImplicitMigrationWithExplicitKey {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    NSData *key = RLMGenerateKey();
    BOOL migrationRan = NO;
    [self createRealmRequiringMigrationWithKey:key migrationRun:&migrationRan];

    XCTAssertThrows([RLMRealm defaultRealm]);
    XCTAssertFalse(migrationRan);

    XCTAssertNoThrow([RLMRealm realmWithPath:[RLMRealm defaultRealmPath] encryptionKey:key readOnly:NO error:nil]);
    XCTAssertTrue(migrationRan);
#pragma clang diagnostic pop
}

- (void)testExplicitMigrationWithRegisteredKey {
    NSData *key = RLMGenerateKey();
    BOOL migrationRan = NO;
    [self createRealmRequiringMigrationWithKey:key migrationRun:&migrationRan];

    RLMConfiguration *configuration = [RLMConfiguration defaultConfiguration];

    XCTAssertNotNil([RLMRealm migrateRealm:configuration]);
    XCTAssertFalse(migrationRan);

    configuration.encryptionKey = key;
    XCTAssertNil([RLMRealm migrateRealm:configuration]);
    XCTAssertTrue(migrationRan);
}

- (void)testExplicitMigrationWithExplicitKey {
    NSData *key = RLMGenerateKey();
    BOOL migrationRan = NO;
    [self createRealmRequiringMigrationWithKey:key migrationRun:&migrationRan];

    RLMConfiguration *configuration = [RLMConfiguration defaultConfiguration];

    XCTAssertNotNil([RLMRealm migrateRealm:configuration]);
    XCTAssertFalse(migrationRan);

    configuration.encryptionKey = key;
    XCTAssertNil([RLMRealm migrateRealm:configuration]);
    XCTAssertTrue(migrationRan);
}

@end
