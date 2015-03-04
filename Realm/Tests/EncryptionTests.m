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

@interface EncryptionTests : RLMTestCase
@end

@implementation EncryptionTests

- (RLMRealm *)realmWithKey:(NSData *)key {
    return [RLMRealm realmWithPath:RLMDefaultRealmPath()
                     encryptionKey:key
                          readOnly:NO
                             error:nil];
}

#pragma mark - Key validation

- (void)testBadEncryptionKeys {
    XCTAssertThrows([RLMRealm realmWithPath:RLMRealm.defaultRealmPath encryptionKey:nil readOnly:NO error:nil]);
    XCTAssertThrows([RLMRealm realmWithPath:RLMRealm.defaultRealmPath encryptionKey:NSData.data readOnly:NO error:nil]);
    XCTAssertThrows([RLMRealm migrateRealmAtPath:RLMRealm.defaultRealmPath encryptionKey:nil]);
    XCTAssertThrows([RLMRealm migrateRealmAtPath:RLMRealm.defaultRealmPath encryptionKey:NSData.data]);
    XCTAssertThrows([RLMRealm setEncryptionKey:NSData.data forRealmsAtPath:RLMRealm.defaultRealmPath]);
    XCTAssertThrows([RLMRealm.defaultRealm writeCopyToPath:RLMTestRealmPath() encryptionKey:nil error:nil]);
    XCTAssertThrows([RLMRealm.defaultRealm writeCopyToPath:RLMTestRealmPath() encryptionKey:NSData.data error:nil]);
}

- (void)testValidEncryptionKeys {
    NSData *key = [[NSMutableData alloc] initWithLength:64];
    XCTAssertNoThrow([RLMRealm setEncryptionKey:key
                                forRealmsAtPath:RLMRealm.defaultRealmPath]);
    XCTAssertNoThrow([RLMRealm setEncryptionKey:nil forRealmsAtPath:RLMRealm.defaultRealmPath]);
    XCTAssertNoThrow([RLMRealm.defaultRealm writeCopyToPath:RLMTestRealmPath() encryptionKey:key error:nil]);
}

#pragma mark - realmWithPath:

- (void)testReopenWithSameKeyWorks {
    NSData *key = RLMGenerateKey();
    @autoreleasepool {
        RLMRealm *realm = [self realmWithKey:key];
        [realm transactionWithBlock:^{
            [IntObject createInRealm:realm withObject:@[@1]];
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
    NSData *key = RLMGenerateKey();
    @autoreleasepool {
        RLMRealm *realm = [self realmWithKey:key];
        [realm transactionWithBlock:^{
            [IntObject createInRealm:realm withObject:@[@1]];
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
}

- (void)testExplicitlyPassedKeyOverridesRegisteredKey {
    NSData *key = RLMGenerateKey();
    @autoreleasepool {
        RLMRealm *realm = [self realmWithKey:key];
        [realm transactionWithBlock:^{
            [IntObject createInRealm:realm withObject:@[@1]];
        }];
    }

    [RLMRealm setEncryptionKey:RLMGenerateKey() forRealmsAtPath:RLMDefaultRealmPath()];
    @autoreleasepool {
        RLMRealm *realm = [self realmWithKey:key];
        XCTAssertEqual(1U, [IntObject allObjectsInRealm:realm].count);
    }
}

#pragma mark - writeCopyToPath:

- (void)testWriteCopyToPathWithNoRegisteredKeyWritesDecrypted {
    NSData *key = RLMGenerateKey();
    @autoreleasepool {
        RLMRealm *realm = [self realmWithKey:key];
        [realm transactionWithBlock:^{
            [IntObject createInRealm:realm withObject:@[@1]];
        }];
        [realm writeCopyToPath:RLMTestRealmPath() error:nil];
    }

    @autoreleasepool {
        RLMRealm *realm = [self realmWithTestPath];
        XCTAssertEqual(1U, [IntObject allObjectsInRealm:realm].count);
    }
}

- (void)testWriteCopyToPathUsesRegisteredKey {
    NSData *key = RLMGenerateKey();
    [RLMRealm setEncryptionKey:key forRealmsAtPath:RLMTestRealmPath()];

    @autoreleasepool {
        RLMRealm *realm = [self realmWithKey:key];
        [realm transactionWithBlock:^{
            [IntObject createInRealm:realm withObject:@[@1]];
        }];
        [realm writeCopyToPath:RLMTestRealmPath() error:nil];
    }

    @autoreleasepool {
        RLMRealm *realm = [self realmWithKey:key];
        XCTAssertEqual(1U, [IntObject allObjectsInRealm:realm].count);
    }
}

- (void)testWriteCopyToPathWithNewKey {
    NSData *key1 = RLMGenerateKey();
    NSData *key2 = RLMGenerateKey();
    NSData *key3 = RLMGenerateKey();
    [RLMRealm setEncryptionKey:key3 forRealmsAtPath:RLMTestRealmPath()];

    @autoreleasepool {
        RLMRealm *realm = [self realmWithKey:key1];
        [realm transactionWithBlock:^{
            [IntObject createInRealm:realm withObject:@[@1]];
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

    [RLMRealm setSchemaVersion:1
                forRealmAtPath:RLMDefaultRealmPath()
            withMigrationBlock:^(__unused RLMMigration *migration, __unused NSUInteger oldSchemaVersion) {
                *migrationRun = YES;
            }];
}

- (void)testImplicitMigrationWithRegisteredKey {
    NSData *key = RLMGenerateKey();
    BOOL migrationRan = NO;
    [self createRealmRequiringMigrationWithKey:key migrationRun:&migrationRan];

    XCTAssertThrows([RLMRealm defaultRealm]);
    XCTAssertFalse(migrationRan);

    [RLMRealm setEncryptionKey:key forRealmsAtPath:RLMDefaultRealmPath()];
    XCTAssertNoThrow([RLMRealm defaultRealm]);
    XCTAssertTrue(migrationRan);
}

- (void)testImplicitMigrationWithExplicitKey {
    NSData *key = RLMGenerateKey();
    BOOL migrationRan = NO;
    [self createRealmRequiringMigrationWithKey:key migrationRun:&migrationRan];

    XCTAssertThrows([RLMRealm defaultRealm]);
    XCTAssertFalse(migrationRan);

    XCTAssertNoThrow([RLMRealm realmWithPath:RLMDefaultRealmPath() encryptionKey:key readOnly:NO error:nil]);
    XCTAssertTrue(migrationRan);
}

- (void)testExplicitMigrationWithRegisteredKey {
    NSData *key = RLMGenerateKey();
    BOOL migrationRan = NO;
    [self createRealmRequiringMigrationWithKey:key migrationRun:&migrationRan];

    XCTAssertNotNil([RLMRealm migrateRealmAtPath:RLMDefaultRealmPath()]);
    XCTAssertFalse(migrationRan);

    [RLMRealm setEncryptionKey:key forRealmsAtPath:RLMDefaultRealmPath()];
    XCTAssertNil([RLMRealm migrateRealmAtPath:RLMDefaultRealmPath()]);
    XCTAssertTrue(migrationRan);
}

- (void)testExplicitMigrationWithExplicitKey {
    NSData *key = RLMGenerateKey();
    BOOL migrationRan = NO;
    [self createRealmRequiringMigrationWithKey:key migrationRun:&migrationRan];

    XCTAssertNotNil([RLMRealm migrateRealmAtPath:RLMDefaultRealmPath()]);
    XCTAssertFalse(migrationRan);

    XCTAssertNil([RLMRealm migrateRealmAtPath:RLMDefaultRealmPath() encryptionKey:key]);
    XCTAssertTrue(migrationRan);
}

@end
