////////////////////////////////////////////////////////////////////////////
//
// Copyright 2014 Realm Inc.
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

#import "RLMMigration.h"
#import "RLMObjectSchema_Private.hpp"
#import "RLMProperty_Private.h"
#import "RLMRealm_Dynamic.h"
#import "RLMRealm_Private.h"
#import "RLMSchema_Private.h"
#import "RLMObjectStore.h"

#import <realm/table.hpp>

@interface MigrationObject : RLMObject
@property int intCol;
@property NSString *stringCol;
@end

@implementation MigrationObject
@end

@interface MigrationPrimaryKeyObject : RLMObject
@property int intCol;
@end

@implementation MigrationPrimaryKeyObject
+ (NSString *)primaryKey {
    return @"intCol";
}
@end

@interface MigrationStringPrimaryKeyObject : RLMObject
@property NSString * stringCol;
@end

@implementation MigrationStringPrimaryKeyObject
+ (NSString *)primaryKey {
    return @"stringCol";
}
@end

@interface ThreeFieldMigrationObject : RLMObject
@property int col1;
@property int col2;
@property int col3;
@end

@implementation ThreeFieldMigrationObject
@end

@interface MigrationTests : RLMTestCase
@end

@implementation MigrationTests

- (RLMRealm *)realmWithSingleObject:(RLMObjectSchema *)objectSchema {
    // modify object schema to use RLMObject class (or else bad accessors will get created)
    objectSchema.objectClass = RLMObject.class;
    objectSchema.accessorClass = RLMObject.class;

    RLMSchema *schema = [[RLMSchema alloc] init];
    schema.objectSchema = @[objectSchema];
    RLMRealm *realm = [self realmWithTestPathAndSchema:schema];

    // Set the initial version to 0 since we're pretending this was created with
    // a shared schema
    [realm beginWriteTransaction];
    RLMRealmSetSchemaVersion(realm, 0);
    [realm commitWriteTransaction];

    return realm;
}

- (void)testSchemaVersion {
    [RLMRealm setDefaultRealmSchemaVersion:1 withMigrationBlock:^(__unused RLMMigration *migration,
                                                      __unused NSUInteger oldSchemaVersion) {
    }];

    RLMRealm *defaultRealm = [RLMRealm defaultRealm];
    XCTAssertEqual(1U, RLMRealmSchemaVersion(defaultRealm));
}

- (void)testGetSchemaVersion {
    XCTAssertThrows([RLMRealm schemaVersionAtPath:RLMRealm.defaultRealmPath encryptionKey:nil error:nil]);
    @autoreleasepool {
        [RLMRealm defaultRealm];
    }

    XCTAssertEqual(0U, [RLMRealm schemaVersionAtPath:RLMRealm.defaultRealmPath encryptionKey:nil error:nil]);
    [RLMRealm setDefaultRealmSchemaVersion:1 withMigrationBlock:^(__unused RLMMigration *migration,
                                                                  __unused NSUInteger oldSchemaVersion) {
    }];

    RLMRealm *realm = [RLMRealm defaultRealm];
    XCTAssertEqual(1U, [RLMRealm schemaVersionAtPath:RLMRealm.defaultRealmPath encryptionKey:nil error:nil]);
    realm = nil;
}

- (void)testPerRealmMigration {
    @autoreleasepool {
        [RLMRealm defaultRealm];
    }

    XCTAssertEqual(0U, [RLMRealm schemaVersionAtPath:RLMRealm.defaultRealmPath encryptionKey:nil error:nil]);
    [RLMRealm setDefaultRealmSchemaVersion:1 withMigrationBlock:nil];

    @autoreleasepool {
        RLMRealm *defaultRealm = [RLMRealm defaultRealm];
        RLMRealm *anotherRealm = [RLMRealm realmWithPath:RLMTestRealmPath()];

        XCTAssertEqual(1U, [RLMRealm schemaVersionAtPath:defaultRealm.path encryptionKey:nil error:nil]);
        XCTAssertEqual(0U, [RLMRealm schemaVersionAtPath:anotherRealm.path encryptionKey:nil error:nil]);
    }

    __block bool migrationComplete = false;
    [RLMRealm setSchemaVersion:2 forRealmAtPath:RLMTestRealmPath() withMigrationBlock:^(__unused RLMMigration *migration,
                                                                                        __unused NSUInteger oldSchemaVersion) {
        migrationComplete = true;
    }];
    RLMRealm *anotherRealm = [RLMRealm realmWithPath:RLMTestRealmPath()];

    XCTAssertEqual(2U, [RLMRealm schemaVersionAtPath:anotherRealm.path encryptionKey:nil error:nil]);
    XCTAssertTrue(migrationComplete);
}

- (void)testAddingPropertyAtEnd {
    // create schema to migrate from with single string column
    RLMObjectSchema *objectSchema = [RLMObjectSchema schemaForObjectClass:MigrationObject.class];
    objectSchema.properties = @[objectSchema.properties[0]];

    @autoreleasepool {
        // create realm with old schema and populate
        RLMRealm *realm = [self realmWithSingleObject:objectSchema];
        [realm beginWriteTransaction];
        [realm createObject:MigrationObject.className withObject:@[@1]];
        [realm createObject:MigrationObject.className withObject:@[@2]];
        [realm commitWriteTransaction];
    }

    @autoreleasepool {
        // open realm with new schema before migration to test migration is necessary
        objectSchema = [RLMObjectSchema schemaForObjectClass:MigrationObject.class];
        XCTAssertThrows([self realmWithTestPath], @"Migration should be required");
    }

    // apply migration
    [RLMRealm setSchemaVersion:1 forRealmAtPath:RLMTestRealmPath() withMigrationBlock:^(RLMMigration *migration, NSUInteger oldSchemaVersion) {
        XCTAssertEqual(oldSchemaVersion, 0U, @"Initial schema version should be 0");
        [migration enumerateObjects:MigrationObject.className
                              block:^(RLMObject *oldObject, RLMObject *newObject) {
            XCTAssertThrows(oldObject[@"stringCol"], @"stringCol should not exist on old object");
            NSNumber *intObj;
            XCTAssertNoThrow(intObj = oldObject[@"intCol"], @"Should be able to access intCol on oldObject");
            XCTAssertEqualObjects(newObject[@"intCol"], oldObject[@"intCol"]);
            NSString *stringObj = [NSString stringWithFormat:@"%@", intObj];
            XCTAssertNoThrow(newObject[@"stringCol"] = stringObj, @"Should be able to set stringCol");
        }];
    }];
    [RLMRealm migrateRealmAtPath:RLMTestRealmPath()];

    // verify migration
    @autoreleasepool {
        RLMRealm *realm = [self realmWithTestPath];
        MigrationObject *mig1 = [MigrationObject allObjectsInRealm:realm][1];
        XCTAssertEqual(mig1.intCol, 2, @"Int column should have value 2");
        XCTAssertEqualObjects(mig1.stringCol, @"2", @"String column should be populated");
    }

    [RLMRealm setSchemaVersion:0 forRealmAtPath:RLMTestRealmPath() withMigrationBlock:nil];
    XCTAssertThrows([RLMRealm migrateRealmAtPath:RLMTestRealmPath()]);
}

- (void)testAddingPropertyAtBeginningPreservesData {
    // create schema to migrate from with the second and third columns from the final data
    RLMObjectSchema *objectSchema = [RLMObjectSchema schemaForObjectClass:ThreeFieldMigrationObject.class];
    objectSchema.properties = @[objectSchema.properties[1], objectSchema.properties[2]];

    // create realm with old schema and populate
    RLMRealm *realm = [self realmWithSingleObject:objectSchema];
    [realm beginWriteTransaction];
    [realm createObject:ThreeFieldMigrationObject.className withObject:@[@1, @2]];
    [realm commitWriteTransaction];

    [RLMRealm setSchemaVersion:1 forRealmAtPath:RLMTestRealmPath() withMigrationBlock:^(RLMMigration *migration, NSUInteger) {
        [migration enumerateObjects:ThreeFieldMigrationObject.className
                              block:^(RLMObject *oldObject, RLMObject *newObject) {
            XCTAssertThrows(oldObject[@"col1"]);
            XCTAssertEqualObjects(oldObject[@"col2"], newObject[@"col2"]);
            XCTAssertEqualObjects(oldObject[@"col3"], newObject[@"col3"]);
        }];
    }];
    [RLMRealm migrateRealmAtPath:RLMTestRealmPath()];

    // verify migration
    realm = [self realmWithTestPath];
    ThreeFieldMigrationObject *mig = [ThreeFieldMigrationObject allObjectsInRealm:realm][0];
    XCTAssertEqual(0, mig.col1);
    XCTAssertEqual(1, mig.col2);
    XCTAssertEqual(2, mig.col3);
}

- (void)testRemoveProperty {
    // create schema to migrate from with single string column
    RLMObjectSchema *objectSchema = [RLMObjectSchema schemaForObjectClass:MigrationObject.class];
    RLMProperty *thirdProperty = [[RLMProperty alloc] initWithName:@"deletedCol" type:RLMPropertyTypeBool objectClassName:nil indexed:NO];
    thirdProperty.column = 2;
    objectSchema.properties = [objectSchema.properties arrayByAddingObject:thirdProperty];

    // create realm with old schema and populate
    RLMRealm *realm = [self realmWithSingleObject:objectSchema];
    [realm beginWriteTransaction];
    [realm createObject:MigrationObject.className withObject:@[@1, @"1", @YES]];
    [realm createObject:MigrationObject.className withObject:@[@2, @"2", @NO]];
    [realm commitWriteTransaction];

    // apply migration
    [RLMRealm setSchemaVersion:1 forRealmAtPath:RLMTestRealmPath() withMigrationBlock:^(RLMMigration *migration, NSUInteger oldSchemaVersion) {
        XCTAssertEqual(oldSchemaVersion, 0U, @"Initial schema version should be 0");
        [migration enumerateObjects:MigrationObject.className
                                       block:^(RLMObject *oldObject, RLMObject *newObject) {
            XCTAssertNoThrow(oldObject[@"deletedCol"], @"Deleted column should be accessible on old object.");
            XCTAssertThrows(newObject[@"deletedCol"], @"Deleted column should not be accessible on new object.");

            XCTAssertEqualObjects(newObject[@"intCol"], oldObject[@"intCol"]);
            XCTAssertEqualObjects(newObject[@"stringCol"], oldObject[@"stringCol"]);
        }];
    }];
    [RLMRealm migrateRealmAtPath:RLMTestRealmPath()];

    // verify migration
    realm = [self realmWithTestPath];
    MigrationObject *mig1 = [MigrationObject allObjectsInRealm:realm][1];
    XCTAssertThrows(mig1[@"deletedCol"], @"Deleted column should no longer be accessible.");
}

- (void)testRemoveAndAddProperty {
    // create schema to migrate from with single string column
    RLMObjectSchema *objectSchema = [RLMObjectSchema schemaForObjectClass:MigrationObject.class];
    RLMProperty *oldInt = [[RLMProperty alloc] initWithName:@"oldIntCol" type:RLMPropertyTypeInt objectClassName:nil indexed:NO];
    objectSchema.properties = @[oldInt, objectSchema.properties[1]];

    // create realm with old schema and populate
    RLMRealm *realm = [self realmWithSingleObject:objectSchema];
    [realm beginWriteTransaction];
    [realm createObject:MigrationObject.className withObject:@[@1, @"1"]];
    [realm createObject:MigrationObject.className withObject:@[@1, @"2"]];
    [realm commitWriteTransaction];

    // object migration object
    void (^migrateObjectBlock)(RLMObject *, RLMObject *) = ^(RLMObject *oldObject, RLMObject *newObject) {
        XCTAssertNoThrow(oldObject[@"oldIntCol"], @"Deleted column should be accessible on old object.");
        XCTAssertThrows(oldObject[@"intCol"], @"New column should not be accessible on old object.");
        XCTAssertEqual([oldObject[@"oldIntCol"] intValue], 1, @"Deleted column value is correct.");
        XCTAssertNoThrow(newObject[@"intCol"], @"New column is accessible on new object.");
        XCTAssertThrows(newObject[@"oldIntCol"], @"Old column should not be accessible on old object.");
        XCTAssertEqual([newObject[@"intCol"] intValue], 0, @"New column value is uninitialized.");
    };

    // apply migration
    [RLMRealm setSchemaVersion:1 forRealmAtPath:RLMTestRealmPath() withMigrationBlock:^(RLMMigration *migration, NSUInteger oldSchemaVersion) {
        XCTAssertEqual(oldSchemaVersion, 0U, @"Initial schema version should be 0");
        [migration enumerateObjects:MigrationObject.className block:migrateObjectBlock];
    }];
    [RLMRealm migrateRealmAtPath:RLMTestRealmPath()];

    // verify migration
    realm = [self realmWithTestPath];
    MigrationObject *mig1 = [MigrationObject allObjectsInRealm:realm][1];
    XCTAssertThrows(mig1[@"oldIntCol"], @"Deleted column should no longer be accessible.");
    XCTAssertEqual(0U, [mig1.objectSchema.properties[0] column]);
    XCTAssertEqual(1U, [mig1.objectSchema.properties[1] column]);
}

- (void)testChangePropertyType {
    // make string an int
    RLMObjectSchema *objectSchema = [RLMObjectSchema schemaForObjectClass:MigrationObject.class];
    RLMProperty *stringCol = objectSchema.properties[1];
    stringCol.type = RLMPropertyTypeInt;
    stringCol.objcType = 'i';

    // create realm with old schema and populate
    RLMRealm *realm = [self realmWithSingleObject:objectSchema];
    [realm beginWriteTransaction];
    [realm createObject:MigrationObject.className withObject:@[@1, @1]];
    [realm createObject:MigrationObject.className withObject:@[@2, @2]];
    [realm commitWriteTransaction];

    // apply migration
    [RLMRealm setSchemaVersion:1 forRealmAtPath:RLMTestRealmPath() withMigrationBlock:^(RLMMigration *migration, NSUInteger oldSchemaVersion) {
        XCTAssertEqual(oldSchemaVersion, 0U, @"Initial schema version should be 0");
        [migration enumerateObjects:MigrationObject.className
                                       block:^(RLMObject *oldObject, RLMObject *newObject) {
            XCTAssertEqualObjects(newObject[@"intCol"], oldObject[@"intCol"]);
            NSNumber *intObj = oldObject[@"stringCol"];
            XCTAssert([intObj isKindOfClass:NSNumber.class], @"Old stringCol should be int");
            newObject[@"stringCol"] = intObj.stringValue;
        }];
    }];
    [RLMRealm migrateRealmAtPath:RLMTestRealmPath()];

    // verify migration
    realm = [self realmWithTestPath];
    MigrationObject *mig1 = [MigrationObject allObjectsInRealm:realm][1];
    XCTAssertEqualObjects(mig1[@"stringCol"], @"2", @"stringCol should be string after migration.");
}

- (void)testPrimaryKeyMigration {
    // make string an int
    RLMObjectSchema *objectSchema = [RLMObjectSchema schemaForObjectClass:MigrationPrimaryKeyObject.class];
    objectSchema.primaryKeyProperty.isPrimary = NO;
    objectSchema.primaryKeyProperty = nil;

    // create realm with old schema and populate
    RLMRealm *realm = [self realmWithSingleObject:objectSchema];
    [realm beginWriteTransaction];
    [realm createObject:MigrationPrimaryKeyObject.className withObject:@[@1]];
    [realm createObject:MigrationPrimaryKeyObject.className withObject:@[@1]];
    [realm commitWriteTransaction];

    // apply migration
    [RLMRealm setSchemaVersion:1
                forRealmAtPath:RLMTestRealmPath()
            withMigrationBlock:^(__unused RLMMigration *migration, __unused NSUInteger oldSchemaVersion) {}];
    XCTAssertThrows([RLMRealm migrateRealmAtPath:RLMTestRealmPath()],
                    @"Migration should throw due to duplicate primary keys)");

    [RLMRealm setSchemaVersion:1
                forRealmAtPath:RLMTestRealmPath()
            withMigrationBlock:^(__unused RLMMigration *migration, __unused NSUInteger oldSchemaVersion) {
        __block int objectID = 0;
        [migration enumerateObjects:@"MigrationPrimaryKeyObject" block:^(__unused RLMObject *oldObject, RLMObject *newObject) {
            newObject[@"intCol"] = @(objectID++);
        }];
    }];
    [RLMRealm migrateRealmAtPath:RLMTestRealmPath()];
}

- (void)testRemovePrimaryKeyMigration {
    RLMObjectSchema *objectSchema = [RLMObjectSchema schemaForObjectClass:MigrationPrimaryKeyObject.class];

    // create realm with old schema and populate
    RLMRealm *realm = [self realmWithSingleObject:objectSchema];
    [realm beginWriteTransaction];
    [realm createObject:MigrationPrimaryKeyObject.className withObject:@[@1]];
    [realm createObject:MigrationPrimaryKeyObject.className withObject:@[@2]];
    [realm commitWriteTransaction];

    objectSchema = [RLMObjectSchema schemaForObjectClass:MigrationPrimaryKeyObject.class];
    objectSchema.primaryKeyProperty.isPrimary = NO;
    objectSchema.primaryKeyProperty = nil;

    // needs a no-op migration
    XCTAssertThrows([self realmWithSingleObject:objectSchema]);

    [RLMRealm setSchemaVersion:1
                forRealmAtPath:RLMTestRealmPath()
            withMigrationBlock:^(RLMMigration *migration, __unused NSUInteger oldSchemaVersion) {
        [migration enumerateObjects:@"MigrationPrimaryKeyObject" block:^(RLMObject *oldObject, RLMObject *newObject) {
            XCTAssertEqualObjects(oldObject[@"intCol"], newObject[@"intCol"]);
        }];
    }];

    XCTAssertNoThrow([self realmWithSingleObject:objectSchema]);
}

- (void)testStringPrimaryKeyMigration {
    // make string an int
    RLMObjectSchema *objectSchema = [RLMObjectSchema schemaForObjectClass:MigrationStringPrimaryKeyObject.class];
    objectSchema.primaryKeyProperty.isPrimary = NO;
    objectSchema.primaryKeyProperty = nil;

    // create realm with old schema and populate
    RLMRealm *realm = [self realmWithSingleObject:objectSchema];
    [realm beginWriteTransaction];
    [realm createObject:MigrationStringPrimaryKeyObject.className withObject:@[@"1"]];
    [realm createObject:MigrationStringPrimaryKeyObject.className withObject:@[@"2"]];
    [realm commitWriteTransaction];

    // apply migration
    [RLMRealm setSchemaVersion:1
                forRealmAtPath:RLMTestRealmPath()
            withMigrationBlock:^(__unused RLMMigration *migration, __unused NSUInteger oldSchemaVersion) {
        [migration enumerateObjects:@"MigrationStringPrimaryKeyObject" block:^(__unused RLMObject *oldObject, RLMObject *newObject) {
            newObject[@"stringCol"] = [[NSUUID UUID] UUIDString];
        }];
    }];
    [RLMRealm migrateRealmAtPath:RLMTestRealmPath()];
}

- (void)testStringPrimaryKeyNoIndexMigration {
    // make string an int
    RLMObjectSchema *objectSchema = [RLMObjectSchema schemaForObjectClass:MigrationStringPrimaryKeyObject.class];

    // create without search index
    objectSchema.primaryKeyProperty.indexed = NO;

    // create realm with old schema and populate
    RLMRealm *realm = [self realmWithSingleObject:objectSchema];
    [realm beginWriteTransaction];
    [realm createObject:MigrationStringPrimaryKeyObject.className withObject:@[@"1"]];
    [realm createObject:MigrationStringPrimaryKeyObject.className withObject:@[@"2"]];
    [realm commitWriteTransaction];

    // apply migration
    [RLMRealm setSchemaVersion:1
                forRealmAtPath:RLMTestRealmPath()
            withMigrationBlock:^(__unused RLMMigration *migration, __unused NSUInteger oldSchemaVersion) {
        [migration enumerateObjects:@"MigrationStringPrimaryKeyObject" block:^(__unused RLMObject *oldObject, RLMObject *newObject) {
            newObject[@"stringCol"] = [[NSUUID UUID] UUIDString];
        }];
    }];
    [RLMRealm migrateRealmAtPath:RLMTestRealmPath()];
}

#if 0 // FIXME: re-enable when int indexing is enabled
- (void)testIntPrimaryKeyNoIndexMigration {
    // make string an int
    RLMObjectSchema *objectSchema = [RLMObjectSchema schemaForObjectClass:MigrationPrimaryKeyObject.class];

    // create without search index
    objectSchema.primaryKeyProperty.indexed = NO;

    // create realm with old schema and populate
    @autoreleasepool {
        RLMRealm *realm = [self realmWithSingleObject:objectSchema];
        [realm beginWriteTransaction];
        [realm createObject:MigrationPrimaryKeyObject.className withObject:@[@1]];
        [realm createObject:MigrationPrimaryKeyObject.className withObject:@[@2]];
        [realm commitWriteTransaction];

        XCTAssertFalse(realm.schema[MigrationPrimaryKeyObject.className].table->has_search_index(0));
    }

    // apply migration
    [RLMRealm setSchemaVersion:1 forRealmAtPath:RLMTestRealmPath() withMigrationBlock:^(__unused RLMMigration *migration, __unused NSUInteger oldSchemaVersion) { }];
    [RLMRealm migrateRealmAtPath:RLMTestRealmPath()];

    // check that column is now indexed
    RLMRealm *realm = [self realmWithTestPath];
    XCTAssertTrue(realm.schema[MigrationPrimaryKeyObject.className].table->has_search_index(0));

    // verify that old data still exists
    RLMResults *objects = [MigrationPrimaryKeyObject allObjectsInRealm:realm];
    XCTAssertEqual(1, [objects[0] intCol]);
    XCTAssertEqual(2, [objects[1] intCol]);
}
#endif

- (void)testDuplicatePrimaryKeyMigration {
    // make string an int
    RLMObjectSchema *objectSchema = [RLMObjectSchema schemaForObjectClass:MigrationPrimaryKeyObject.class];
    objectSchema.primaryKeyProperty.isPrimary = NO;
    objectSchema.primaryKeyProperty = nil;

    // create realm with old schema and populate
    RLMRealm *realm = [self realmWithSingleObject:objectSchema];
    [realm beginWriteTransaction];
    [realm createObject:MigrationPrimaryKeyObject.className withObject:@[@1]];
    [realm createObject:MigrationPrimaryKeyObject.className withObject:@[@1]];
    [realm commitWriteTransaction];

    // apply bad migration
    [RLMRealm setSchemaVersion:1
                forRealmAtPath:RLMTestRealmPath()
            withMigrationBlock:^(__unused RLMMigration *migration, __unused NSUInteger oldSchemaVersion) {}];
    XCTAssertThrows([RLMRealm migrateRealmAtPath:RLMTestRealmPath()], @"Migration should throw due to duplicate primary keys)");

    // apply good migration
    [RLMRealm setSchemaVersion:1
                forRealmAtPath:RLMTestRealmPath()
            withMigrationBlock:^(RLMMigration *migration, __unused NSUInteger oldSchemaVersion) {
        NSMutableSet *seen = [NSMutableSet set];
        __block bool duplicateDeleted = false;
        [migration enumerateObjects:@"MigrationPrimaryKeyObject" block:^(__unused RLMObject *oldObject, RLMObject *newObject) {
           if ([seen containsObject:newObject[@"intCol"]]) {
               duplicateDeleted = true;
               [migration deleteObject:newObject];
           }
           else {
               [seen addObject:newObject[@"intCol"]];
           }
        }];
        XCTAssertEqual(true, duplicateDeleted);
    }];
    [RLMRealm migrateRealmAtPath:RLMTestRealmPath()];

    // make sure deletion occurred
    XCTAssertEqual(1U, [[MigrationPrimaryKeyObject allObjectsInRealm:[RLMRealm realmWithPath:RLMTestRealmPath()]] count]);
}

- (void)testIncompleteMigrationIsRolledBack {
    // make string an int
    RLMObjectSchema *objectSchema = [RLMObjectSchema schemaForObjectClass:MigrationPrimaryKeyObject.class];
    objectSchema.primaryKeyProperty.isPrimary = NO;
    objectSchema.primaryKeyProperty = nil;

    // create realm with old schema and populate
    @autoreleasepool {
        RLMRealm *realm = [self realmWithSingleObject:objectSchema];
        [realm beginWriteTransaction];
        [realm createObject:MigrationPrimaryKeyObject.className withObject:@[@1]];
        [realm createObject:MigrationPrimaryKeyObject.className withObject:@[@1]];
        [realm commitWriteTransaction];
    }

    // fail to apply migration
    [RLMRealm setSchemaVersion:1
                forRealmAtPath:RLMTestRealmPath()
            withMigrationBlock:^(__unused RLMMigration *migration, __unused NSUInteger oldSchemaVersion) {}];
    XCTAssertThrows([RLMRealm migrateRealmAtPath:RLMTestRealmPath()], @"Migration should throw due to duplicate primary keys)");

    // should still be able to open with pre-migration schema
    XCTAssertNoThrow([self realmWithSingleObject:objectSchema]);
}

- (void)testAddObjectDuringMigration {
    // initialize realm
    @autoreleasepool {
        [RLMRealm defaultRealm];
    }

    [RLMRealm setDefaultRealmSchemaVersion:1
                        withMigrationBlock:^(RLMMigration *migration, __unused NSUInteger oldSchemaVersion) {
        [migration createObject:StringObject.className withObject:@[@"string"]];
    }];

    // implicit migration
    XCTAssertEqual(1U, StringObject.allObjects.count);
}

- (void)testVersionNumberCanStaySameWithNoSchemaChanges {
    @autoreleasepool { [self realmWithTestPathAndSchema:[RLMSchema sharedSchema]]; }

    [RLMRealm setSchemaVersion:0
                forRealmAtPath:RLMTestRealmPath()
            withMigrationBlock:^(__unused RLMMigration *migration, __unused NSUInteger oldSchemaVersion) {}];
    XCTAssertNoThrow([RLMRealm migrateRealmAtPath:RLMTestRealmPath()]);
}

- (void)testMigrationIsAppliedWhenNeeded {
    @autoreleasepool {
        // make string an int
        RLMObjectSchema *objectSchema = [RLMObjectSchema schemaForObjectClass:MigrationObject.class];
        RLMProperty *stringCol = objectSchema.properties[1];
        stringCol.type = RLMPropertyTypeInt;
        stringCol.objcType = 'i';

        // create realm with old schema and populate
        RLMRealm *realm = [self realmWithSingleObject:objectSchema];
        [realm beginWriteTransaction];
        [realm createObject:MigrationObject.className withObject:@[@1, @1]];
        [realm commitWriteTransaction];
    }

    __block bool migrationApplied = false;
    [RLMRealm setSchemaVersion:1
                forRealmAtPath:RLMTestRealmPath()
            withMigrationBlock:^(RLMMigration *migration, __unused NSUInteger oldSchemaVersion) {
                [migration enumerateObjects:MigrationObject.className block:^(RLMObject *, RLMObject *newObject) {
                    newObject[@"stringCol"] = @"";
                }];
                migrationApplied = true;
            }];

    // migration should be applied when opening realm
    @autoreleasepool {
        [RLMRealm realmWithPath:RLMTestRealmPath()];
    }
    XCTAssertEqual(true, migrationApplied);

    // applying migration at same version is no-op
    migrationApplied = false;
    [RLMRealm migrateRealmAtPath:RLMTestRealmPath()];
    XCTAssertEqual(false, migrationApplied);

    // test version cant go down
    [RLMRealm setSchemaVersion:0
                forRealmAtPath:RLMTestRealmPath()
            withMigrationBlock:^(__unused RLMMigration *migration, __unused NSUInteger oldSchemaVersion) {}];
    XCTAssertThrows([RLMRealm migrateRealmAtPath:RLMTestRealmPath()]);
}

- (void)testVersionNumberCanStaySameWhenAddingObjectSchema {
    @autoreleasepool {
        // create realm with old schema and populate
        RLMRealm *realm = [self realmWithSingleObject:[RLMObjectSchema schemaForObjectClass:MigrationObject.class]];
        [realm beginWriteTransaction];
        [realm createObject:MigrationObject.className withObject:@[@1, @"1"]];
        [realm commitWriteTransaction];
    }
    XCTAssertNoThrow([RLMRealm realmWithPath:RLMTestRealmPath()]);
}

- (void)testRearrangeProperties {
    @autoreleasepool {
        // create object in default realm
        [[RLMRealm defaultRealm] transactionWithBlock:^{
            [CircleObject createInDefaultRealmWithObject:@[@"data", NSNull.null]];
        }];

        // create realm with the properties reversed
        RLMSchema *schema = [[RLMSchema sharedSchema] copy];
        RLMObjectSchema *objectSchema = schema[@"CircleObject"];
        objectSchema.properties = @[objectSchema.properties[1], objectSchema.properties[0]];

        RLMRealm *realm = [self realmWithTestPathAndSchema:schema];
        [realm beginWriteTransaction];
        [realm createObject:CircleObject.className withObject:@[NSNull.null, @"data"]];
        [realm commitWriteTransaction];
    }

    // migration should not be requried
    RLMRealm *realm = nil;
    XCTAssertNoThrow(realm = [self realmWithTestPath]);

    // accessors should work
    CircleObject *obj = [[CircleObject allObjectsInRealm:realm] firstObject];
    XCTAssertEqualObjects(@"data", obj.data);
    [realm beginWriteTransaction];
    XCTAssertNoThrow(obj.data = @"new data");
    XCTAssertNoThrow(obj.next = obj);
    [realm commitWriteTransaction];

    // open the default Realm and make sure accessors with alternate ordering work
    CircleObject *defaultObj = [[CircleObject allObjects] firstObject];
    XCTAssertEqualObjects(defaultObj.data, @"data");

    // test object from other realm still works
    XCTAssertEqualObjects(obj.data, @"new data");

    // verify schema for both objects
    NSArray *properties = defaultObj.objectSchema.properties;
    for (NSUInteger i = 0; i < properties.count; i++) {
        XCTAssertEqual([properties[i] column], i);
    }
    properties = obj.objectSchema.properties;
    for (NSUInteger i = 0; i < properties.count; i++) {
        XCTAssertEqual([properties[i] column], i);
    }
}

- (void)testMigrationDoesNotEffectOtherPaths {
    RLMRealm *defaultRealm = RLMRealm.defaultRealm;
    [RLMRealm migrateRealmAtPath:RLMTestRealmPath()];
    XCTAssertEqual(defaultRealm, RLMRealm.defaultRealm);
}

- (void)testAccessorCreationForReadOnlyRealms {
    RLMClearAccessorCache();

    // Create a realm file with only a single table
    @autoreleasepool {
        RLMRealm *realm = [self realmWithSingleObject:[RLMObjectSchema schemaForObjectClass:IntObject.class]];
        [realm beginWriteTransaction];
        [realm createObject:IntObject.className withObject:@[@1]];
        [realm commitWriteTransaction];
    }

    Class intObjectAccessorClass;
    @autoreleasepool {
        RLMRealm *realm = [RLMRealm realmWithPath:RLMTestRealmPath() readOnly:YES error:nil];

        intObjectAccessorClass = realm.schema[IntObject.className].accessorClass;

        // StringObject table doesn't exist, so it should not have an accessor
        // class despite being in the object schema
        RLMObjectSchema *missingTableSchema = realm.schema[StringObject.className];
        XCTAssertNotNil(missingTableSchema);
        XCTAssertEqual(missingTableSchema.accessorClass, RLMObject.class);
    }

    @autoreleasepool {
        RLMRealm *realm = [RLMRealm realmWithPath:RLMTestRealmPath() readOnly:NO error:nil];

        // read-write realm should have a different IntObject accessor class due
        // to that we check for RLMSchema compatibility and not for each RLMObjectSchema
        XCTAssertNotEqual(intObjectAccessorClass, realm.schema[IntObject.className].accessorClass);

        // StringObject should now have an accessor class
        RLMObjectSchema *missingTableSchema = realm.schema[StringObject.className];
        XCTAssertNotNil(missingTableSchema);
        XCTAssertNotNil(missingTableSchema.accessorClass);
        XCTAssertNotEqual(missingTableSchema.accessorClass, RLMObject.class);
    }

    RLMClearAccessorCache();
}

@end

