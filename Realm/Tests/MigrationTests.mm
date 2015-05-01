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
#import "RLMObject_Private.h"
#import "RLMObjectSchema_Private.hpp"
#import "RLMProperty_Private.h"
#import "RLMRealm_Dynamic.h"
#import "RLMRealm_Private.hpp"
#import "RLMSchema_Private.h"
#import "RLMUtil.hpp"
#import "RLMObjectStore.h"

#import "object_store.hpp"
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

@interface MigrationTwoStringObject : RLMObject
@property NSString *col1;
@property NSString *col2;
@end

@implementation MigrationTwoStringObject
@end

@interface MigrationTests : RLMTestCase
@end

@implementation MigrationTests

- (RLMRealm *)realmWithSingleObject:(RLMObjectSchema *)objectSchema {
    // modify object schema to use RLMObject class (or else bad accessors will get created)
    objectSchema.objectClass = RLMDynamicObject.class;
    objectSchema.accessorClass = RLMDynamicObject.class;

    RLMSchema *schema = [[RLMSchema alloc] init];
    schema.objectSchema = @[objectSchema];
    RLMRealm *realm = [self realmWithTestPathAndSchema:schema];
    
    return realm;
}

- (void)testSchemaVersion {
    [RLMRealm setDefaultRealmSchemaVersion:1 withMigrationBlock:^(__unused RLMMigration *migration,
                                                                  __unused uint64_t oldSchemaVersion) {
    }];

    RLMRealm *defaultRealm = [RLMRealm defaultRealm];
    XCTAssertEqual(1U, realm::ObjectStore::get_schema_version(defaultRealm.group));
}

- (void)testGetSchemaVersion {
    XCTAssertThrows([RLMRealm schemaVersionAtPath:RLMRealm.defaultRealmPath encryptionKey:nil error:nil]);
    @autoreleasepool {
        [RLMRealm defaultRealm];
    }

    XCTAssertEqual(0U, [RLMRealm schemaVersionAtPath:RLMRealm.defaultRealmPath encryptionKey:nil error:nil]);
    [RLMRealm setDefaultRealmSchemaVersion:1 withMigrationBlock:^(__unused RLMMigration *migration,
                                                                  uint64_t oldSchemaVersion) {
        XCTAssertEqual(0U, oldSchemaVersion);
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
                                                                                        uint64_t oldSchemaVersion) {
        XCTAssertEqual(0U, oldSchemaVersion);
        migrationComplete = true;
    }];
    RLMRealm *anotherRealm = [RLMRealm realmWithPath:RLMTestRealmPath()];

    XCTAssertEqual(2U, [RLMRealm schemaVersionAtPath:anotherRealm.path encryptionKey:nil error:nil]);
    XCTAssertTrue(migrationComplete);
}

- (void)testRemovingSubclass {
    @autoreleasepool {
        RLMObjectSchema *objectSchema = [[RLMObjectSchema alloc] initWithClassName:@"DeletedClass" objectClass:RLMObject.class properties:@[]];
        RLMRealm *realm = [self realmWithSingleObject:objectSchema];

        [realm transactionWithBlock:^{
            [realm createObject:@"DeletedClass" withValue:@[]];
        }];
    }

    @autoreleasepool {
        // apply migration
        [RLMRealm setSchemaVersion:1 forRealmAtPath:RLMTestRealmPath() withMigrationBlock:^(RLMMigration *migration, uint64_t oldSchemaVersion) {
            XCTAssertEqual(oldSchemaVersion, 0U, @"Initial schema version should be 0");

            XCTAssertTrue([migration deleteDataForClassName:@"DeletedClass"]);
            XCTAssertFalse([migration deleteDataForClassName:@"NoSuchClass"]);
            XCTAssertFalse([migration deleteDataForClassName:nil]);

            [migration createObject:StringObject.className withValue:@[@"migration"]];
            XCTAssertTrue([migration deleteDataForClassName:StringObject.className]);
        }];
        [RLMRealm migrateRealmAtPath:RLMTestRealmPath()];
    }

    @autoreleasepool {
        // verify migration
        RLMRealm *realm = [self realmWithTestPath];
        XCTAssertFalse(ObjectStore::table_for_object_type(realm.group, "DeletedClass"), @"The deleted class should not have a table.");
        XCTAssertEqual(0U, [StringObject allObjectsInRealm:realm].count);
    }
}

- (void)testAddingPropertyAtEnd {
    // create schema to migrate from with single string column
    RLMObjectSchema *objectSchema = [RLMObjectSchema schemaForObjectClass:MigrationObject.class];
    objectSchema.properties = @[objectSchema.properties[0]];

    @autoreleasepool {
        // create realm with old schema and populate
        RLMRealm *realm = [self realmWithSingleObject:objectSchema];
        [realm beginWriteTransaction];
        [realm createObject:MigrationObject.className withValue:@[@1]];
        [realm createObject:MigrationObject.className withValue:@[@2]];
        [realm commitWriteTransaction];
    }

    @autoreleasepool {
        // open realm with new schema before migration to test migration is necessary
        objectSchema = [RLMObjectSchema schemaForObjectClass:MigrationObject.class];
        XCTAssertThrows([self realmWithTestPath], @"Migration should be required");
    }

    // apply migration
    [RLMRealm setSchemaVersion:1 forRealmAtPath:RLMTestRealmPath() withMigrationBlock:^(RLMMigration *migration, uint64_t oldSchemaVersion) {
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
    XCTAssertNotNil([RLMRealm migrateRealmAtPath:RLMTestRealmPath()]);
}

- (void)testAddingPropertyAtBeginningPreservesData {
    // create schema to migrate from with the second and third columns from the final data
    RLMObjectSchema *objectSchema = [RLMObjectSchema schemaForObjectClass:ThreeFieldMigrationObject.class];
    objectSchema.properties = @[objectSchema.properties[1], objectSchema.properties[2]];

    // create realm with old schema and populate
    RLMRealm *realm = [self realmWithSingleObject:objectSchema];
    [realm beginWriteTransaction];
    [realm createObject:ThreeFieldMigrationObject.className withValue:@[@1, @2]];
    [realm commitWriteTransaction];

    [RLMRealm setSchemaVersion:1 forRealmAtPath:RLMTestRealmPath() withMigrationBlock:^(RLMMigration *migration, uint64_t) {
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
    RLMProperty *thirdProperty = [[RLMProperty alloc] initWithName:@"deletedCol" type:RLMPropertyTypeBool objectClassName:nil indexed:NO optional:NO];
    thirdProperty.column = 2;
    objectSchema.properties = [objectSchema.properties arrayByAddingObject:thirdProperty];

    // create realm with old schema and populate
    RLMRealm *realm = [self realmWithSingleObject:objectSchema];
    [realm beginWriteTransaction];
    [realm createObject:MigrationObject.className withValue:@[@1, @"1", @YES]];
    [realm createObject:MigrationObject.className withValue:@[@2, @"2", @NO]];
    [realm commitWriteTransaction];

    // apply migration
    [RLMRealm setSchemaVersion:1 forRealmAtPath:RLMTestRealmPath() withMigrationBlock:^(RLMMigration *migration, uint64_t oldSchemaVersion) {
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
    RLMProperty *oldInt = [[RLMProperty alloc] initWithName:@"oldIntCol" type:RLMPropertyTypeInt objectClassName:nil indexed:NO optional:NO];
    objectSchema.properties = @[oldInt, objectSchema.properties[1]];

    // create realm with old schema and populate
    RLMRealm *realm = [self realmWithSingleObject:objectSchema];
    [realm beginWriteTransaction];
    [realm createObject:MigrationObject.className withValue:@[@1, @"1"]];
    [realm createObject:MigrationObject.className withValue:@[@1, @"2"]];
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
    [RLMRealm setSchemaVersion:1 forRealmAtPath:RLMTestRealmPath() withMigrationBlock:^(RLMMigration *migration, uint64_t oldSchemaVersion) {
        XCTAssertEqual(oldSchemaVersion, 0U, @"Initial schema version should be 0");
        [migration enumerateObjects:MigrationObject.className block:migrateObjectBlock];
    }];
    [RLMRealm migrateRealmAtPath:RLMTestRealmPath()];

    // verify migration
    realm = [self realmWithTestPath];
    MigrationObject *mig1 = [MigrationObject allObjectsInRealm:realm][1];
    XCTAssertThrows(mig1[@"oldIntCol"], @"Deleted column should no longer be accessible.");
}

- (void)testChangePropertyType {
    // make string an int
    RLMObjectSchema *objectSchema = [RLMObjectSchema schemaForObjectClass:MigrationObject.class];
    RLMProperty *stringCol = objectSchema.properties[1];
    stringCol.type = RLMPropertyTypeInt;
    stringCol.objcType = 'i';
    stringCol.optional = NO;

    // create realm with old schema and populate
    RLMRealm *realm = [self realmWithSingleObject:objectSchema];
    [realm beginWriteTransaction];
    [realm createObject:MigrationObject.className withValue:@[@1, @1]];
    [realm createObject:MigrationObject.className withValue:@[@2, @2]];
    [realm commitWriteTransaction];

    // apply migration
    [RLMRealm setSchemaVersion:1 forRealmAtPath:RLMTestRealmPath() withMigrationBlock:^(RLMMigration *migration, uint64_t oldSchemaVersion) {
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
    [realm createObject:MigrationPrimaryKeyObject.className withValue:@[@1]];
    [realm createObject:MigrationPrimaryKeyObject.className withValue:@[@1]];
    [realm commitWriteTransaction];

    // apply migration
    [RLMRealm setSchemaVersion:1
                forRealmAtPath:RLMTestRealmPath()
            withMigrationBlock:^(__unused RLMMigration *migration, __unused uint64_t oldSchemaVersion) {}];
    XCTAssertNotNil([RLMRealm migrateRealmAtPath:RLMTestRealmPath()],
                    @"Migration should return error due to duplicate primary keys)");

    [RLMRealm setSchemaVersion:1
                forRealmAtPath:RLMTestRealmPath()
            withMigrationBlock:^(__unused RLMMigration *migration, __unused uint64_t oldSchemaVersion) {
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
    [realm createObject:MigrationPrimaryKeyObject.className withValue:@[@1]];
    [realm createObject:MigrationPrimaryKeyObject.className withValue:@[@2]];
    [realm commitWriteTransaction];

    objectSchema = [RLMObjectSchema schemaForObjectClass:MigrationPrimaryKeyObject.class];
    objectSchema.primaryKeyProperty.isPrimary = NO;
    objectSchema.primaryKeyProperty = nil;

    // needs a no-op migration
    XCTAssertThrows([self realmWithSingleObject:objectSchema]);

    [RLMRealm setSchemaVersion:1
                forRealmAtPath:RLMTestRealmPath()
            withMigrationBlock:^(RLMMigration *migration, __unused uint64_t oldSchemaVersion) {
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
    [realm createObject:MigrationStringPrimaryKeyObject.className withValue:@[@"1"]];
    [realm createObject:MigrationStringPrimaryKeyObject.className withValue:@[@"2"]];
    [realm commitWriteTransaction];

    // apply migration
    [RLMRealm setSchemaVersion:1
                forRealmAtPath:RLMTestRealmPath()
            withMigrationBlock:^(__unused RLMMigration *migration, __unused uint64_t oldSchemaVersion) {
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
    [realm createObject:MigrationStringPrimaryKeyObject.className withValue:@[@"1"]];
    [realm createObject:MigrationStringPrimaryKeyObject.className withValue:@[@"2"]];
    [realm commitWriteTransaction];

    // apply migration
    [RLMRealm setSchemaVersion:1
                forRealmAtPath:RLMTestRealmPath()
            withMigrationBlock:^(__unused RLMMigration *migration, __unused uint64_t oldSchemaVersion) {
        [migration enumerateObjects:@"MigrationStringPrimaryKeyObject" block:^(__unused RLMObject *oldObject, RLMObject *newObject) {
            newObject[@"stringCol"] = [[NSUUID UUID] UUIDString];
        }];
    }];
    [RLMRealm migrateRealmAtPath:RLMTestRealmPath()];
}

- (void)testIntPrimaryKeyNoIndexMigration {
    // make string an int
    RLMObjectSchema *objectSchema = [RLMObjectSchema schemaForObjectClass:MigrationPrimaryKeyObject.class];

    // create without search index
    objectSchema.primaryKeyProperty.indexed = NO;

    // create realm with old schema and populate
    @autoreleasepool {
        RLMRealm *realm = [self realmWithSingleObject:objectSchema];
        [realm beginWriteTransaction];
        [realm createObject:MigrationPrimaryKeyObject.className withValue:@[@1]];
        [realm createObject:MigrationPrimaryKeyObject.className withValue:@[@2]];
        [realm commitWriteTransaction];
    }

    // apply migration
    [RLMRealm setSchemaVersion:1 forRealmAtPath:RLMTestRealmPath() withMigrationBlock:^(__unused RLMMigration *migration, __unused uint64_t oldSchemaVersion) { }];
    [RLMRealm migrateRealmAtPath:RLMTestRealmPath()];

    // check that column is now indexed
    RLMRealm *realm = [self realmWithTestPath];
    XCTAssertTrue(realm.schema[MigrationPrimaryKeyObject.className].table->has_search_index(0));

    // verify that old data still exists
    RLMResults *objects = [MigrationPrimaryKeyObject allObjectsInRealm:realm];
    XCTAssertEqual(1, [objects[0] intCol]);
    XCTAssertEqual(2, [objects[1] intCol]);
}

- (void)testDuplicatePrimaryKeyMigration {
    // make the pk non-primary so that we can add duplicate values
    RLMObjectSchema *objectSchema = [RLMObjectSchema schemaForObjectClass:MigrationPrimaryKeyObject.class];
    objectSchema.primaryKeyProperty.isPrimary = NO;
    objectSchema.primaryKeyProperty = nil;

    // populate with values that will be invalid when the property is made primary
    RLMRealm *realm = [self realmWithSingleObject:objectSchema];
    [realm beginWriteTransaction];
    [realm createObject:MigrationPrimaryKeyObject.className withValue:@[@1]];
    [realm createObject:MigrationPrimaryKeyObject.className withValue:@[@1]];
    [realm commitWriteTransaction];

    // apply bad migration
    [RLMRealm setSchemaVersion:1
                forRealmAtPath:RLMTestRealmPath()
            withMigrationBlock:^(__unused RLMMigration *migration, __unused uint64_t oldSchemaVersion) {}];
    XCTAssertNotNil([RLMRealm migrateRealmAtPath:RLMTestRealmPath()], @"Migration should return error due to duplicate primary keys)");

    // apply good migration that deletes duplicates
    [RLMRealm setSchemaVersion:1
                forRealmAtPath:RLMTestRealmPath()
            withMigrationBlock:^(RLMMigration *migration, __unused uint64_t oldSchemaVersion) {
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
        [realm createObject:MigrationPrimaryKeyObject.className withValue:@[@1]];
        [realm createObject:MigrationPrimaryKeyObject.className withValue:@[@1]];
        [realm commitWriteTransaction];
    }

    // fail to apply migration
    [RLMRealm setSchemaVersion:1
                forRealmAtPath:RLMTestRealmPath()
            withMigrationBlock:^(__unused RLMMigration *migration, __unused uint64_t oldSchemaVersion) {}];
    XCTAssertNotNil([RLMRealm migrateRealmAtPath:RLMTestRealmPath()], @"Migration should return error due to duplicate primary keys)");

    // should still be able to open with pre-migration schema
    XCTAssertNoThrow([self realmWithSingleObject:objectSchema]);
}

- (void)testAddObjectDuringMigration {
    // initialize realm
    @autoreleasepool {
        [RLMRealm defaultRealm];
    }

    [RLMRealm setDefaultRealmSchemaVersion:1
                        withMigrationBlock:^(RLMMigration *migration, __unused uint64_t oldSchemaVersion) {
        [migration createObject:StringObject.className withValue:@[@"string"]];
    }];

    // implicit migration
    XCTAssertEqual(1U, StringObject.allObjects.count);
}

- (void)testVersionNumberCanStaySameWithNoSchemaChanges {
    @autoreleasepool { [self realmWithTestPathAndSchema:[RLMSchema sharedSchema]]; }

    [RLMRealm setSchemaVersion:0
                forRealmAtPath:RLMTestRealmPath()
            withMigrationBlock:^(__unused RLMMigration *migration, __unused uint64_t oldSchemaVersion) {}];
    XCTAssertNoThrow([RLMRealm migrateRealmAtPath:RLMTestRealmPath()]);
}

- (void)testMigrationIsAppliedWhenNeeded {
    @autoreleasepool {
        // make string an int
        RLMObjectSchema *objectSchema = [RLMObjectSchema schemaForObjectClass:MigrationObject.class];
        RLMProperty *stringCol = objectSchema.properties[1];
        stringCol.type = RLMPropertyTypeInt;
        stringCol.objcType = 'i';
        stringCol.optional = NO;

        // create realm with old schema and populate
        RLMRealm *realm = [self realmWithSingleObject:objectSchema];
        [realm beginWriteTransaction];
        [realm createObject:MigrationObject.className withValue:@[@1, @1]];
        [realm commitWriteTransaction];
    }

    __block bool migrationApplied = false;
    [RLMRealm setSchemaVersion:1
                forRealmAtPath:RLMTestRealmPath()
            withMigrationBlock:^(RLMMigration *migration, __unused uint64_t oldSchemaVersion) {
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
            withMigrationBlock:^(__unused RLMMigration *migration, __unused uint64_t oldSchemaVersion) {}];
    XCTAssertNotNil([RLMRealm migrateRealmAtPath:RLMTestRealmPath()]);
}

- (void)testVersionNumberCanStaySameWhenAddingObjectSchema {
    @autoreleasepool {
        // create realm with old schema and populate
        RLMRealm *realm = [self realmWithSingleObject:[RLMObjectSchema schemaForObjectClass:MigrationObject.class]];
        [realm beginWriteTransaction];
        [realm createObject:MigrationObject.className withValue:@[@1, @"1"]];
        [realm commitWriteTransaction];
    }
    XCTAssertNoThrow([RLMRealm realmWithPath:RLMTestRealmPath()]);
}

- (void)testRearrangeProperties {
    @autoreleasepool {
        // create object in default realm
        [[RLMRealm defaultRealm] transactionWithBlock:^{
            [CircleObject createInDefaultRealmWithValue:@[@"data", NSNull.null]];
        }];

        // create realm with the properties reversed
        RLMSchema *schema = [[RLMSchema sharedSchema] copy];
        RLMObjectSchema *objectSchema = schema[@"CircleObject"];
        objectSchema.properties = @[objectSchema.properties[1], objectSchema.properties[0]];

        RLMRealm *realm = [self realmWithTestPathAndSchema:schema];
        [realm beginWriteTransaction];
        [realm createObject:CircleObject.className withValue:@[NSNull.null, @"data"]];
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
        [realm createObject:IntObject.className withValue:@[@1]];
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
        XCTAssertEqual(missingTableSchema.accessorClass, RLMDynamicObject.class);
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

- (void)testAddingAndRemovingIndex {
    RLMSchema *noIndex = [[RLMSchema alloc] init];
    noIndex.objectSchema = @[[RLMObjectSchema schemaForObjectClass:StringObject.class]];

    RLMSchema *index = [[RLMSchema alloc] init];
    RLMObjectSchema *objectSchema = [RLMObjectSchema schemaForObjectClass:StringObject.class];
    [objectSchema.properties[0] setIndexed:YES];
    index.objectSchema = @[objectSchema];

    auto columnIsIndexed = ^(RLMRealm *realm) {
        RLMObjectSchema *objectSchema = realm.schema[@"StringObject"];
        return objectSchema.table->has_search_index([objectSchema.properties[0] column]);
    };

    // create initial file with no index
    @autoreleasepool {
        XCTAssertFalse(columnIsIndexed([self realmWithTestPathAndSchema:noIndex]));
    }

    // should add index when opening with indexed schema
    @autoreleasepool {
        XCTAssertTrue(columnIsIndexed([self realmWithTestPathAndSchema:index]));
    }

    // should remove index when opening with non-indexed schema
    @autoreleasepool {
        XCTAssertFalse(columnIsIndexed([self realmWithTestPathAndSchema:noIndex]));
    }

    // create initial file with index
    [self deleteFiles];
    @autoreleasepool {
        XCTAssertTrue(columnIsIndexed([self realmWithTestPathAndSchema:index]));
    }

    // should be able to open readonly with mismatched index schema
    @autoreleasepool {
        XCTAssertTrue(columnIsIndexed([RLMRealm realmWithPath:RLMTestRealmPath() readOnly:YES error:nil]));
    }
}

- (void)testEnumeratedObjectsDuringMigration {
    // initialize realm
    @autoreleasepool {
        [[RLMRealm defaultRealm] transactionWithBlock:^{
            [StringObject createInDefaultRealmWithValue:@[@"string"]];
            [ArrayPropertyObject createInDefaultRealmWithValue:@[@"array", @[@[@"string"]], @[@[@1]]]];
        }];
    }

    [RLMRealm setDefaultRealmSchemaVersion:1
                        withMigrationBlock:^(RLMMigration *migration, __unused uint64_t oldSchemaVersion) {
                            [migration enumerateObjects:StringObject.className block:^(RLMObject *oldObject, RLMObject *newObject) {
                                XCTAssertEqualObjects([oldObject valueForKey:@"stringCol"], oldObject[@"stringCol"]);
                                [newObject setValue:@"otherString" forKey:@"stringCol"];
                                XCTAssertEqualObjects([oldObject valueForKey:@"realm"], oldObject.realm);
                                XCTAssertThrows([oldObject valueForKey:@"noSuchKey"]);
                                XCTAssertThrows([newObject setValue:@1 forKey:@"noSuchKey"]);
                            }];

                            [migration enumerateObjects:ArrayPropertyObject.className block:^(RLMObject *oldObject, RLMObject *newObject) {
                                XCTAssertEqual(RLMDynamicObject.class, newObject.class);
                                XCTAssertEqual(RLMDynamicObject.class, oldObject.class);
                                XCTAssertEqual(RLMDynamicObject.class, [[oldObject[@"array"] firstObject] class]);
                                XCTAssertEqual(RLMDynamicObject.class, [[newObject[@"array"] firstObject] class]);
                            }];
                        }];

    // implicit migration
    XCTAssertEqualObjects(@"otherString", [StringObject.allObjects.firstObject stringCol]);
}

- (void)testMigrationBlockNotCalledForIntialRealmCreation {
    [RLMRealm setSchemaVersion:1
                forRealmAtPath:RLMTestRealmPath()
            withMigrationBlock:^(__unused RLMMigration *migration, __unused uint64_t oldSchemaVersion) {
                XCTFail(@"Migration block should not have been called");
            }];
    XCTAssertNoThrow([self realmWithTestPath]);
}

- (void)testRLMNotVersionedHasCorrectValue
{
    XCTAssertEqual(RLMNotVersioned, std::numeric_limits<uint64_t>::max());
}

- (void)testSetSchemaVersionValidatesVersion
{
    RLMAssertThrowsWithReasonMatching([RLMRealm setSchemaVersion:RLMNotVersioned forRealmAtPath:RLMTestRealmPath() withMigrationBlock:nil], @"Cannot set schema version");
    [RLMRealm setSchemaVersion:RLMNotVersioned - 1 forRealmAtPath:RLMTestRealmPath() withMigrationBlock:nil];
}

- (void)testChangingColumnNullability {
    RLMSchema *nullable = [[RLMSchema alloc] init];
    nullable.objectSchema = @[[RLMObjectSchema schemaForObjectClass:StringObject.class]];

    RLMSchema *nonnull = [[RLMSchema alloc] init];
    RLMObjectSchema *objectSchema = [RLMObjectSchema schemaForObjectClass:StringObject.class];
    [objectSchema.properties[0] setOptional:NO];
    nonnull.objectSchema = @[objectSchema];

    // create initial required column
    @autoreleasepool {
        [self realmWithTestPathAndSchema:nonnull];
    }

    // attempt to open with an optional column
    @autoreleasepool {
        XCTAssertThrows([self realmWithTestPathAndSchema:nullable]);
    }

    [self deleteFiles];

    // create initial optional column
    @autoreleasepool {
        [self realmWithTestPathAndSchema:nullable];
    }

    // attempt to open with a required column
    @autoreleasepool {
        XCTAssertThrows([self realmWithTestPathAndSchema:nonnull]);
    }
}

- (void)testRequiredToNullableAutoMigration {
    RLMSchema *nullable = [[RLMSchema alloc] init];
    nullable.objectSchema = @[[RLMObjectSchema schemaForObjectClass:MigrationTwoStringObject.class]];

    RLMSchema *nonnull = [[RLMSchema alloc] init];
    RLMObjectSchema *objectSchema = [RLMObjectSchema schemaForObjectClass:MigrationTwoStringObject.class];
    [objectSchema.properties setValue:@NO forKey:@"optional"];
    nonnull.objectSchema = @[objectSchema];

    // create initial required column
    @autoreleasepool {
        RLMRealm *realm = [self realmWithTestPathAndSchema:nonnull];
        [realm transactionWithBlock:^{
            [MigrationTwoStringObject createInRealm:realm withValue:@[@"string", @"string2"]];
        }];
    }

    @autoreleasepool {
        [RLMRealm setSchemaVersion:1 forRealmAtPath:RLMTestRealmPath() withMigrationBlock:nil];
        RLMRealm *realm = [self realmWithTestPathAndSchema:nullable];
        XCTAssertEqualObjects([[MigrationTwoStringObject allObjectsInRealm:realm] valueForKey:@"col2"], @[@"string2"]);
        XCTAssertTrue(realm.schema[@"MigrationTwoStringObject"][@"col1"].optional);
    }
}

@end
