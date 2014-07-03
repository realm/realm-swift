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

extern "C" {
#import "RLMTestCase.h"
}
#import "RLMMigration.h"
#import "RLMProperty_Private.h"
#import "RLMSchema_Private.h"
#import "RLMObjectStore.h"
#import "RLMObjectSchema_Private.hpp"

@interface MigrationObject : RLMObject
@property int intCol;
@property NSString *stringCol;
@end

@implementation MigrationObject
@end

@interface MigrationTests : RLMTestCase
@end

@implementation MigrationTests

- (RLMRealm *)realmWithSingleObject:(RLMObjectSchema *)objectSchema {
    // modify object schema to use RLMObject class (or else bad accessors will get created)
    objectSchema.objectClass = RLMObject.class;

    RLMSchema *schema = [[RLMSchema alloc] init];
    schema.objectSchema = @[objectSchema];
    return [self dynamicRealmWithTestPathAndSchema:schema];
}

- (void)testAddingProperty {
    // create schema to migrate from with single string column
    RLMObjectSchema *objectSchema = [RLMObjectSchema schemaForObjectClass:MigrationObject.class];
    objectSchema.properties = @[objectSchema.properties[0]];

    // create realm with old schema and populate
    RLMRealm *realm = [self realmWithSingleObject:objectSchema];
    [realm beginWriteTransaction];
    RLMCreateObjectInRealmWithValue(realm, MigrationObject.className, @[@1]);
    RLMCreateObjectInRealmWithValue(realm, MigrationObject.className, @[@2]);
    [realm commitWriteTransaction];

    // open realm with new schema before migration to test migration is necessary
    objectSchema = [RLMObjectSchema schemaForObjectClass:MigrationObject.class];
    XCTAssertThrows([self realmWithTestPath], @"Migration should be required");
    
    // apply migration
    [RLMRealm applyMigrationBlock:^NSUInteger(RLMMigration *migration, NSUInteger oldSchemaVersion) {
        XCTAssertEqual(oldSchemaVersion, 0U, @"Initial schema version should be 0");
        [migration enumerateObjects:MigrationObject.className
                                       block:^(RLMObject *oldObject, RLMObject *newObject) {
            XCTAssertThrows(oldObject[@"stringCol"], @"stringCol should not exist on old object");
            NSNumber *intObj;
            XCTAssertNoThrow(intObj = oldObject[@"intCol"], @"Should be able to access intCol on oldObject");
            NSString *stringObj = [NSString stringWithFormat:@"%@", intObj];
            XCTAssertNoThrow(newObject[@"stringCol"] = stringObj, @"Should be able to set stringCol");
        }];
        return 1;
    } atPath:RLMTestRealmPath() error:nil];

    // verify migration
    realm = [self realmWithTestPath];
    MigrationObject *mig1 = [realm allObjects:MigrationObject.className][1];
    XCTAssertEqual(mig1.intCol, 2, @"Int column should have value 2");
    XCTAssertEqualObjects(mig1.stringCol, @"2", @"String column should be populated");
}


- (void)testRemoveProperty {
    // create schema to migrate from with single string column
    RLMObjectSchema *objectSchema = [RLMObjectSchema schemaForObjectClass:MigrationObject.class];
    RLMProperty *thirdProperty = [[RLMProperty alloc] initWithName:@"deletedCol" type:RLMPropertyTypeBool column:2];
    objectSchema.properties = [objectSchema.properties arrayByAddingObject:thirdProperty];

    // create realm with old schema and populate
    RLMRealm *realm = [self realmWithSingleObject:objectSchema];
    [realm beginWriteTransaction];
    RLMCreateObjectInRealmWithValue(realm, MigrationObject.className, @[@1, @"1", @YES]);
    RLMCreateObjectInRealmWithValue(realm, MigrationObject.className, @[@2, @"2", @NO]);
    [realm commitWriteTransaction];

    // apply migration
    [RLMRealm applyMigrationBlock:^NSUInteger(RLMMigration *migration, NSUInteger oldSchemaVersion) {
        XCTAssertEqual(oldSchemaVersion, 0U, @"Initial schema version should be 0");
        [migration enumerateObjects:MigrationObject.className
                                       block:^(RLMObject *oldObject, RLMObject *newObject) {
            XCTAssertNoThrow(oldObject[@"deletedCol"], @"Deleted column should be accessible on old object.");
            XCTAssertThrows(newObject[@"deletedCol"], @"Deleted column should not be accessible on new object.");
        }];
        return 1;
    } atPath:RLMTestRealmPath() error:nil];

    // verify migration
    realm = [self realmWithTestPath];
    MigrationObject *mig1 = [realm allObjects:MigrationObject.className][1];
    XCTAssertThrows(mig1[@"deletedCol"], @"Deleted column should no longer be accessible.");
}

- (void)testRemoveAndAddProperty {
    // create schema to migrate from with single string column
    RLMObjectSchema *objectSchema = [RLMObjectSchema schemaForObjectClass:MigrationObject.class];
    RLMProperty *oldInt = [[RLMProperty alloc] initWithName:@"oldIntCol" type:RLMPropertyTypeInt column:0];
    objectSchema.properties = @[oldInt, objectSchema.properties[1]];

    // create realm with old schema and populate
    RLMRealm *realm = [self realmWithSingleObject:objectSchema];
    [realm beginWriteTransaction];
    RLMCreateObjectInRealmWithValue(realm, MigrationObject.className, @[@1, @"1"]);
    RLMCreateObjectInRealmWithValue(realm, MigrationObject.className, @[@1, @"2"]);
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
    [RLMRealm applyMigrationBlock:^NSUInteger(RLMMigration *migration, NSUInteger oldSchemaVersion) {
        XCTAssertEqual(oldSchemaVersion, 0U, @"Initial schema version should be 0");
        [migration enumerateObjects:MigrationObject.className block:migrateObjectBlock];
        return 1;
    } atPath:RLMTestRealmPath() error:nil];

    // verify migration
    realm = [self realmWithTestPath];
    MigrationObject *mig1 = [realm allObjects:MigrationObject.className][1];
    XCTAssertThrows(mig1[@"deletedCol"], @"Deleted column should no longer be accessible.");
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
    RLMCreateObjectInRealmWithValue(realm, MigrationObject.className, @[@1, @1]);
    RLMCreateObjectInRealmWithValue(realm, MigrationObject.className, @[@2, @2]);
    [realm commitWriteTransaction];

    // apply migration
    [RLMRealm applyMigrationBlock:^NSUInteger(RLMMigration *migration, NSUInteger oldSchemaVersion) {
        XCTAssertEqual(oldSchemaVersion, 0U, @"Initial schema version should be 0");
        [migration enumerateObjects:MigrationObject.className
                                       block:^(RLMObject *oldObject, RLMObject *newObject) {
            NSNumber *intObj = oldObject[@"stringCol"];
            XCTAssert([intObj isKindOfClass:NSNumber.class], @"Old stringCol should be int");
            newObject[@"stringCol"] = [NSString stringWithFormat:@"%@", intObj];
        }];
        return 1;
    } atPath:RLMTestRealmPath() error:nil];

    // verify migration
    realm = [self realmWithTestPath];
    MigrationObject *mig1 = [realm allObjects:MigrationObject.className][1];
    XCTAssertEqualObjects(mig1[@"stringCol"], @"2", @"strintCol should be string after migration.");
}

- (void)testNoMigrationApplied {
    // create realm an tables
    RLMRealm *realm = [self dynamicRealmWithTestPathAndSchema:[RLMSchema sharedSchema]];
    realm = nil;
    
    // apply migration
    XCTAssertNoThrow(
        [RLMRealm applyMigrationBlock:^NSUInteger(__unused RLMMigration *migration, NSUInteger oldSchemaVersion) {
            return oldSchemaVersion;
        } atPath:RLMTestRealmPath() error:nil],
        @"Returning the same version should work when no migration is required");
}

@end

