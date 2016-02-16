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
#import "RLMObjectStore.h"
#import "RLMObject_Private.h"
#import "RLMProperty_Private.h"
#import "RLMRealmConfiguration_Private.h"
#import "RLMRealm_Dynamic.h"
#import "RLMRealm_Private.hpp"
#import "RLMSchema_Private.h"
#import "RLMUtil.hpp"

#import "object_store.hpp"
#import "shared_realm.hpp"

using namespace realm;

static void RLMAssertRealmSchemaMatchesTable(id self, RLMRealm *realm) {
    for (RLMObjectSchema *objectSchema in realm.schema.objectSchema) {
        Table *table = objectSchema.table;
        for (RLMProperty *property in objectSchema.properties) {
            XCTAssertEqual(property.column, table->get_column_index(RLMStringDataWithNSString(property.name)));
            XCTAssertEqual(property.indexed || property.isPrimary, table->has_search_index(property.column));
        }
    }
}

@interface MigrationObject : RLMObject
@property int intCol;
@property NSString *stringCol;
@end
RLM_ARRAY_TYPE(MigrationObject);

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

@interface MigrationLinkObject : RLMObject
@property MigrationObject *object;
@property RLMArray<MigrationObject> *array;
@end

@implementation MigrationLinkObject
@end

@interface MigrationTests : RLMTestCase
@end

@implementation MigrationTests
#pragma mark - Helper methods
- (RLMSchema *)schemaWithObjects:(NSArray *)objects {
    RLMSchema *schema = [[RLMSchema alloc] init];
    schema.objectSchema = objects;
    return schema;
}

- (RLMRealm *)realmWithSingleObject:(RLMObjectSchema *)objectSchema {
    return [self realmWithTestPathAndSchema:[self schemaWithObjects:@[objectSchema]]];
}

- (RLMRealmConfiguration *)config {
    RLMRealmConfiguration *config = [RLMRealmConfiguration new];
    config.path = RLMTestRealmPath();
    return config;
}

- (void)createTestRealmWithClasses:(NSArray *)classes block:(void (^)(RLMRealm *realm))block {
    NSMutableArray *objectSchema = [NSMutableArray arrayWithCapacity:classes.count];
    for (Class cls in classes) {
        [objectSchema addObject:[RLMObjectSchema schemaForObjectClass:cls]];
    }
    [self createTestRealmWithSchema:objectSchema block:block];
}

- (void)createTestRealmWithSchema:(NSArray *)objectSchema block:(void (^)(RLMRealm *realm))block {
    @autoreleasepool {
        RLMRealmConfiguration *config = [RLMRealmConfiguration new];
        config.path = RLMTestRealmPath();
        config.customSchema = [self schemaWithObjects:objectSchema];

        RLMRealm *realm = [RLMRealm realmWithConfiguration:config error:nil];
        [realm beginWriteTransaction];
        block(realm);
        [realm commitWriteTransaction];
    }
}

- (RLMRealm *)migrateTestRealmWithBlock:(RLMMigrationBlock)block NS_RETURNS_RETAINED {
    @autoreleasepool {
        RLMRealmConfiguration *config = [RLMRealmConfiguration new];
        config.path = RLMTestRealmPath();
        config.schemaVersion = 1;
        config.migrationBlock = block;
        XCTAssertNil([RLMRealm migrateRealm:config]);

        RLMRealm *realm = [RLMRealm realmWithConfiguration:config error:nil];
        RLMAssertRealmSchemaMatchesTable(self, realm);
        return realm;
    }
}

- (void)failToMigrateTestRealmWithBlock:(RLMMigrationBlock)block {
    @autoreleasepool {
        RLMRealmConfiguration *config = [RLMRealmConfiguration new];
        config.path = RLMTestRealmPath();
        config.schemaVersion = 1;
        config.migrationBlock = block;
        XCTAssertNotNil([RLMRealm migrateRealm:config]);
    }
}

- (void)assertMigrationRequiredForChangeFrom:(NSArray *)from to:(NSArray *)to {
    RLMRealmConfiguration *config = [RLMRealmConfiguration new];
    config.customSchema = [self schemaWithObjects:from];
    @autoreleasepool { [RLMRealm realmWithConfiguration:config error:nil]; }

    config.customSchema = [self schemaWithObjects:to];
    config.migrationBlock = ^(__unused RLMMigration *migration, __unused uint64_t oldSchemaVersion) {
        XCTFail(@"Migration block should not have been called");
    };

    XCTAssertThrows([RLMRealm realmWithConfiguration:config error:nil]);

    __block bool migrationCalled = false;
    config.schemaVersion = 1;
    config.migrationBlock = ^(__unused RLMMigration *migration, __unused uint64_t oldSchemaVersion) {
        migrationCalled = true;
    };

    XCTAssertNoThrow([RLMRealm realmWithConfiguration:config error:nil]);
    XCTAssertTrue(migrationCalled);
    RLMAssertRealmSchemaMatchesTable(self, [RLMRealm realmWithConfiguration:config error:nil]);
}
- (void)assertNoMigrationRequiredForChangeFrom:(NSArray *)from to:(NSArray *)to {
    RLMRealmConfiguration *config = [RLMRealmConfiguration new];
    config.customSchema = [self schemaWithObjects:from];
    @autoreleasepool { [RLMRealm realmWithConfiguration:config error:nil]; }

    config.customSchema = [self schemaWithObjects:to];
    config.migrationBlock = ^(__unused RLMMigration *migration, __unused uint64_t oldSchemaVersion) {
        XCTFail(@"Migration block should not have been called");
    };

    XCTAssertNoThrow([RLMRealm realmWithConfiguration:config error:nil]);
    RLMAssertRealmSchemaMatchesTable(self, [RLMRealm realmWithConfiguration:config error:nil]);
}

#pragma mark - Schema versions

- (void)testGetSchemaVersion {
    XCTAssertThrows([RLMRealm schemaVersionAtPath:RLMDefaultRealmPath() encryptionKey:nil error:nil]);
    NSError *error;
    XCTAssertEqual(RLMNotVersioned, [RLMRealm schemaVersionAtPath:RLMDefaultRealmPath() encryptionKey:nil error:&error]);
    XCTAssertNotNil(error);

    RLMRealmConfiguration *config = [RLMRealmConfiguration defaultConfiguration];
    @autoreleasepool { [RLMRealm realmWithConfiguration:config error:nil]; }
    XCTAssertEqual(0U, [RLMRealm schemaVersionAtPath:config.path encryptionKey:nil error:nil]);

    config.schemaVersion = 1;
    config.migrationBlock = ^(__unused RLMMigration *migration, uint64_t oldSchemaVersion) {
        XCTAssertEqual(0U, oldSchemaVersion);
    };

    @autoreleasepool { [RLMRealm realmWithConfiguration:config error:nil]; }
    XCTAssertEqual(1U, [RLMRealm schemaVersionAtPath:config.path encryptionKey:nil error:nil]);
}

- (void)testSchemaVersionCannotGoDown {
    RLMRealmConfiguration *config = [RLMRealmConfiguration defaultConfiguration];
    config.schemaVersion = 10;
    @autoreleasepool { [RLMRealm realmWithConfiguration:config error:nil]; }
    XCTAssertEqual(10U, [RLMRealm schemaVersionAtPath:config.path encryptionKey:nil error:nil]);

    config.schemaVersion = 5;
    RLMAssertThrowsWithReasonMatching([RLMRealm realmWithConfiguration:config error:nil],
                                      @"Provided schema version 5 is less than last set version 10.");
}

- (void)testDifferentSchemaVersionsAtDifferentPaths {
    RLMRealmConfiguration *config = [RLMRealmConfiguration defaultConfiguration];
    config.schemaVersion = 10;
    @autoreleasepool { [RLMRealm realmWithConfiguration:config error:nil]; }
    XCTAssertEqual(10U, [RLMRealm schemaVersionAtPath:config.path encryptionKey:nil error:nil]);

    RLMRealmConfiguration *config2 = [RLMRealmConfiguration defaultConfiguration];
    config2.schemaVersion = 5;
    config2.path = RLMTestRealmPath();
    @autoreleasepool { [RLMRealm realmWithConfiguration:config2 error:nil]; }
    XCTAssertEqual(5U, [RLMRealm schemaVersionAtPath:config2.path encryptionKey:nil error:nil]);

    // Should not have been changed
    XCTAssertEqual(10U, [RLMRealm schemaVersionAtPath:config.path encryptionKey:nil error:nil]);
}

#pragma mark - Migration Requirements

- (void)testAddingClassDoesNotRequireMigration {
    RLMRealmConfiguration *config = [RLMRealmConfiguration new];
    config.objectClasses = @[MigrationObject.class];
    @autoreleasepool { [RLMRealm realmWithConfiguration:config error:nil]; }

    config.objectClasses = @[MigrationObject.class, ThreeFieldMigrationObject.class];
    XCTAssertNoThrow([RLMRealm realmWithConfiguration:config error:nil]);
}

- (void)testRemovingClassDoesNotRequireMigration {
    RLMRealmConfiguration *config = [RLMRealmConfiguration new];
    config.objectClasses = @[MigrationObject.class, ThreeFieldMigrationObject.class];
    @autoreleasepool { [RLMRealm realmWithConfiguration:config error:nil]; }

    config.objectClasses = @[MigrationObject.class];
    XCTAssertNoThrow([RLMRealm realmWithConfiguration:config error:nil]);
}

- (void)testAddingColumnRequiresMigration {
    RLMObjectSchema *from = [RLMObjectSchema schemaForObjectClass:MigrationTwoStringObject.class];
    from.properties = [from.properties subarrayWithRange:{0, 1}];

    RLMObjectSchema *to = [RLMObjectSchema schemaForObjectClass:MigrationTwoStringObject.class];

    [self assertMigrationRequiredForChangeFrom:@[from] to:@[to]];
}

- (void)testRemovingColumnRequiresMigration {
    RLMObjectSchema *from = [RLMObjectSchema schemaForObjectClass:MigrationTwoStringObject.class];

    RLMObjectSchema *to = [RLMObjectSchema schemaForObjectClass:MigrationTwoStringObject.class];
    to.properties = [to.properties subarrayWithRange:{0, 1}];

    [self assertMigrationRequiredForChangeFrom:@[from] to:@[to]];
}

- (void)testChangingColumnOrderDoesNotRequireMigration {
    RLMObjectSchema *from = [RLMObjectSchema schemaForObjectClass:MigrationTwoStringObject.class];

    RLMObjectSchema *to = [RLMObjectSchema schemaForObjectClass:MigrationTwoStringObject.class];
    to.properties = @[to.properties[1], to.properties[0]];

    [self assertNoMigrationRequiredForChangeFrom:@[from] to:@[to]];
}

- (void)testAddingIndexDoesNotRequireMigration {
    RLMObjectSchema *from = [RLMObjectSchema schemaForObjectClass:MigrationTwoStringObject.class];

    RLMObjectSchema *to = [RLMObjectSchema schemaForObjectClass:MigrationTwoStringObject.class];
    [to.properties[0] setIndexed:YES];

    [self assertNoMigrationRequiredForChangeFrom:@[from] to:@[to]];
}

- (void)testRemovingIndexDoesNotRequireMigration {
    RLMObjectSchema *from = [RLMObjectSchema schemaForObjectClass:MigrationTwoStringObject.class];
    [from.properties[0] setIndexed:YES];

    RLMObjectSchema *to = [RLMObjectSchema schemaForObjectClass:MigrationTwoStringObject.class];

    [self assertNoMigrationRequiredForChangeFrom:@[from] to:@[to]];
}

- (void)testAddingPrimaryKeyRequiresMigration {
    RLMObjectSchema *from = [RLMObjectSchema schemaForObjectClass:MigrationTwoStringObject.class];

    RLMObjectSchema *to = [RLMObjectSchema schemaForObjectClass:MigrationTwoStringObject.class];
    to.primaryKeyProperty = to.properties[0];

    [self assertMigrationRequiredForChangeFrom:@[from] to:@[to]];
}

- (void)testRemovingPrimaryKeyRequiresMigration {
    RLMObjectSchema *from = [RLMObjectSchema schemaForObjectClass:MigrationTwoStringObject.class];
    from.primaryKeyProperty = from.properties[0];

    RLMObjectSchema *to = [RLMObjectSchema schemaForObjectClass:MigrationTwoStringObject.class];

    [self assertMigrationRequiredForChangeFrom:@[from] to:@[to]];
}

- (void)testChangingPrimaryKeyRequiresMigration {
    RLMObjectSchema *from = [RLMObjectSchema schemaForObjectClass:MigrationTwoStringObject.class];
    from.primaryKeyProperty = from.properties[0];

    RLMObjectSchema *to = [RLMObjectSchema schemaForObjectClass:MigrationTwoStringObject.class];
    to.primaryKeyProperty = to.properties[1];

    [self assertMigrationRequiredForChangeFrom:@[from] to:@[to]];
}

- (void)testMakingPropertyOptionalRequiresMigration {
    RLMObjectSchema *from = [RLMObjectSchema schemaForObjectClass:MigrationTwoStringObject.class];
    [from.properties[0] setOptional:NO];

    RLMObjectSchema *to = [RLMObjectSchema schemaForObjectClass:MigrationTwoStringObject.class];

    [self assertMigrationRequiredForChangeFrom:@[from] to:@[to]];
}

- (void)testMakingPropertyNonOptionalRequiresMigration {
    RLMObjectSchema *from = [RLMObjectSchema schemaForObjectClass:MigrationTwoStringObject.class];

    RLMObjectSchema *to = [RLMObjectSchema schemaForObjectClass:MigrationTwoStringObject.class];
    [to.properties[0] setOptional:NO];

    [self assertMigrationRequiredForChangeFrom:@[from] to:@[to]];
}

- (void)testChangingLinkTargetRequiresMigration {
    NSArray *linkTargets = @[[RLMObjectSchema schemaForObjectClass:MigrationObject.class],
                             [RLMObjectSchema schemaForObjectClass:MigrationTwoStringObject.class]];
    RLMObjectSchema *from = [RLMObjectSchema schemaForObjectClass:MigrationLinkObject.class];

    RLMObjectSchema *to = [RLMObjectSchema schemaForObjectClass:MigrationLinkObject.class];
    [to.properties[0] setObjectClassName:@"MigrationTwoStringObject"];

    [self assertMigrationRequiredForChangeFrom:[linkTargets arrayByAddingObject:from]
                                            to:[linkTargets arrayByAddingObject:to]];
}

- (void)testChangingLinkListTargetRequiresMigration {
    NSArray *linkTargets = @[[RLMObjectSchema schemaForObjectClass:MigrationObject.class],
                             [RLMObjectSchema schemaForObjectClass:MigrationTwoStringObject.class]];
    RLMObjectSchema *from = [RLMObjectSchema schemaForObjectClass:MigrationLinkObject.class];

    RLMObjectSchema *to = [RLMObjectSchema schemaForObjectClass:MigrationLinkObject.class];
    [to.properties[1] setObjectClassName:@"MigrationTwoStringObject"];

    [self assertMigrationRequiredForChangeFrom:[linkTargets arrayByAddingObject:from]
                                            to:[linkTargets arrayByAddingObject:to]];
}

- (void)testChangingPropertyTypesRequiresMigration {
    RLMObjectSchema *from = [RLMObjectSchema schemaForObjectClass:MigrationObject.class];

    RLMObjectSchema *to = [RLMObjectSchema schemaForObjectClass:MigrationObject.class];
    RLMProperty *prop = to.properties[0];
    RLMProperty *strProp = to.properties[1];
    prop.type = strProp.type;
    prop.objcRawType = strProp.objcRawType;
    prop.objcType = strProp.objcType;

    [self assertMigrationRequiredForChangeFrom:@[from] to:@[to]];
}

- (void)testChangingIntSizeDoesNotRequireMigration {
    RLMObjectSchema *from = [RLMObjectSchema schemaForObjectClass:MigrationObject.class];

    RLMObjectSchema *to = [RLMObjectSchema schemaForObjectClass:MigrationObject.class];
    RLMProperty *prop = to.properties[0];
    prop.objcRawType = @"q"; // 'long long' rather than 'int'
    prop.objcType = 'q';

    [self assertNoMigrationRequiredForChangeFrom:@[from] to:@[to]];
}

#pragma mark - Allowed schema mismatches

- (void)testMismatchedIndexAllowedForReadOnly {
    RLMObjectSchema *objectSchema = [RLMObjectSchema schemaForObjectClass:StringObject.class];
    [objectSchema.properties[0] setIndexed:YES];

    [self createTestRealmWithSchema:@[objectSchema] block:^(RLMRealm *) { }];

    // should be able to open readonly with mismatched index schema
    RLMRealmConfiguration *config = [self config];
    config.readOnly = true;
    RLMRealm *realm = [RLMRealm realmWithConfiguration:config error:nil];
    objectSchema = realm.schema[@"StringObject"];
    XCTAssertTrue(objectSchema.table->has_search_index([objectSchema.properties[0] column]));
}

- (void)testRearrangeProperties {
    // create object in default realm
    [RLMRealm.defaultRealm transactionWithBlock:^{
        [CircleObject createInDefaultRealmWithValue:@[@"data", NSNull.null]];
    }];

    // create realm with the properties reversed
    RLMSchema *schema = [[RLMSchema sharedSchema] copy];
    RLMObjectSchema *objectSchema = schema[@"CircleObject"];
    objectSchema.properties = @[objectSchema.properties[1], objectSchema.properties[0]];

    RLMRealm *realm = [self realmWithTestPathAndSchema:schema];
    [realm beginWriteTransaction];
    [realm createObject:CircleObject.className withValue:@[@"data", NSNull.null]];

    // -createObject:withValue: takes values in the order the properties were declared.
    RLMAssertThrowsWithReasonMatching(([realm createObject:CircleObject.className withValue:@[NSNull.null, @"data"]]), @"object of type 'CircleObject'");
    [realm commitWriteTransaction];

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

    RLMAssertRealmSchemaMatchesTable(self, realm);

    // verify schema for both objects
    NSArray *properties = defaultObj.objectSchema.properties;
    for (NSUInteger i = 0; i < properties.count; i++) {
        XCTAssertEqual([properties[i] column], i);
    }
    properties = obj.objectSchema.properties;
    for (NSUInteger i = 0; i < properties.count; i++) {
        XCTAssertEqual([properties[i] column], i);
    }

    [realm beginWriteTransaction];
    [realm createObject:CircleObject.className withValue:@[@"data", NSNull.null]];

    // -createObject:withValue: takes values in the order the properties were declared.
    RLMAssertThrowsWithReasonMatching(([realm createObject:CircleObject.className withValue:@[NSNull.null, @"data"]]), @"object of type 'CircleObject'");
    [realm commitWriteTransaction];
}

- (void)testAccessorCreationForReadOnlyRealms {
    RLMClearAccessorCache();

    // Create a realm file with only a single table
    [self createTestRealmWithSchema:@[[RLMObjectSchema schemaForObjectClass:IntObject.class]] block:^(RLMRealm *realm) {
        [realm createObject:IntObject.className withValue:@[@1]];
    }];

    Class intObjectAccessorClass;
    @autoreleasepool {
        RLMRealm *realm = [self readOnlyRealmWithPath:RLMTestRealmPath() error:nil];

        intObjectAccessorClass = realm.schema[IntObject.className].accessorClass;

        // StringObject table doesn't exist, so it should not have an accessor
        // class despite being in the object schema
        RLMObjectSchema *missingTableSchema = realm.schema[StringObject.className];
        XCTAssertNotNil(missingTableSchema);
        XCTAssertEqual(missingTableSchema.accessorClass, RLMDynamicObject.class);
    }

    @autoreleasepool {
        RLMRealm *realm = [self realmWithTestPath];

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

#pragma mark - Migration block invocatios

- (void)testMigrationBlockNotCalledForIntialRealmCreation {
    RLMRealmConfiguration *config = [RLMRealmConfiguration new];
    config.migrationBlock = ^(__unused RLMMigration *migration, __unused uint64_t oldSchemaVersion) {
        XCTFail(@"Migration block should not have been called");
    };
    XCTAssertNoThrow([RLMRealm realmWithConfiguration:config error:nil]);
}

- (void)testMigrationBlockNotCalledWhenSchemaVersionIsUnchanged {
    RLMRealmConfiguration *config = [RLMRealmConfiguration new];
    config.schemaVersion = 1;
    @autoreleasepool { XCTAssertNoThrow([RLMRealm realmWithConfiguration:config error:nil]); }

    config.migrationBlock = ^(__unused RLMMigration *migration, __unused uint64_t oldSchemaVersion) {
        XCTFail(@"Migration block should not have been called");
    };
    @autoreleasepool { XCTAssertNoThrow([RLMRealm realmWithConfiguration:config error:nil]); }
    @autoreleasepool { XCTAssertNil([RLMRealm migrateRealm:config]); }
}

- (void)testMigrationBlockCalledWhenSchemaVersionHasChanged {
    RLMRealmConfiguration *config = [RLMRealmConfiguration new];
    config.schemaVersion = 1;
    @autoreleasepool { XCTAssertNoThrow([RLMRealm realmWithConfiguration:config error:nil]); }

    __block bool migrationCalled = false;
    config.schemaVersion = 2;
    config.migrationBlock = ^(__unused RLMMigration *migration, __unused uint64_t oldSchemaVersion) {
        migrationCalled = true;
    };
    @autoreleasepool { XCTAssertNoThrow([RLMRealm realmWithConfiguration:config error:nil]); }
    XCTAssertTrue(migrationCalled);

    migrationCalled = false;
    config.schemaVersion = 3;
    @autoreleasepool { XCTAssertNil([RLMRealm migrateRealm:config]); }
    XCTAssertTrue(migrationCalled);
}

#pragma mark - Migration Correctness

- (void)testRemovingSubclass {
    RLMObjectSchema *objectSchema = [[RLMObjectSchema alloc] initWithClassName:@"DeletedClass" objectClass:RLMObject.class properties:@[]];
    [self createTestRealmWithSchema:@[objectSchema] block:^(RLMRealm *realm) {
        [realm createObject:@"DeletedClass" withValue:@[]];
    }];

    // apply migration
    RLMRealm *realm = [self migrateTestRealmWithBlock:^(RLMMigration *migration, uint64_t oldSchemaVersion) {
        XCTAssertEqual(oldSchemaVersion, 0U, @"Initial schema version should be 0");

        XCTAssertTrue([migration deleteDataForClassName:@"DeletedClass"]);
        XCTAssertFalse([migration deleteDataForClassName:@"NoSuchClass"]);
        XCTAssertFalse([migration deleteDataForClassName:self.nonLiteralNil]);

        [migration createObject:StringObject.className withValue:@[@"migration"]];
        XCTAssertTrue([migration deleteDataForClassName:StringObject.className]);
    }];

    XCTAssertFalse(ObjectStore::table_for_object_type(realm.group, "DeletedClass"), @"The deleted class should not have a table.");
    XCTAssertEqual(0U, [StringObject allObjectsInRealm:realm].count);
}

- (void)testAddingPropertyAtEnd {
    // create schema to migrate from with single string column
    RLMObjectSchema *objectSchema = [RLMObjectSchema schemaForObjectClass:MigrationObject.class];
    objectSchema.properties = @[objectSchema.properties[0]];
    [self createTestRealmWithSchema:@[objectSchema] block:^(RLMRealm *realm) {
        [realm createObject:MigrationObject.className withValue:@[@1]];
        [realm createObject:MigrationObject.className withValue:@[@2]];
    }];

    // apply migration
    RLMRealm *realm = [self migrateTestRealmWithBlock:^(RLMMigration *migration, uint64_t oldSchemaVersion) {
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

    // verify migration
    MigrationObject *mig1 = [MigrationObject allObjectsInRealm:realm][1];
    XCTAssertEqual(mig1.intCol, 2, @"Int column should have value 2");
    XCTAssertEqualObjects(mig1.stringCol, @"2", @"String column should be populated");
}

- (void)testAddingPropertyAtBeginningPreservesData {
    // create schema to migrate from with the second and third columns from the final data
    RLMObjectSchema *objectSchema = [RLMObjectSchema schemaForObjectClass:ThreeFieldMigrationObject.class];
    objectSchema.properties = @[objectSchema.properties[1], objectSchema.properties[2]];

    [self createTestRealmWithSchema:@[objectSchema] block:^(RLMRealm *realm) {
        [realm createObject:ThreeFieldMigrationObject.className withValue:@[@1, @2]];
    }];

    RLMRealm *realm = [self migrateTestRealmWithBlock:^(RLMMigration *migration, uint64_t) {
        [migration enumerateObjects:ThreeFieldMigrationObject.className
                              block:^(RLMObject *oldObject, RLMObject *newObject) {
            XCTAssertThrows(oldObject[@"col1"]);
            XCTAssertEqualObjects(oldObject[@"col2"], newObject[@"col2"]);
            XCTAssertEqualObjects(oldObject[@"col3"], newObject[@"col3"]);
        }];
    }];

    // verify migration
    ThreeFieldMigrationObject *mig = [ThreeFieldMigrationObject allObjectsInRealm:realm][0];
    XCTAssertEqual(0, mig.col1);
    XCTAssertEqual(1, mig.col2);
    XCTAssertEqual(2, mig.col3);
}

- (void)testRemoveProperty {
    // create schema with an extra column
    RLMObjectSchema *objectSchema = [RLMObjectSchema schemaForObjectClass:MigrationObject.class];
    RLMProperty *thirdProperty = [[RLMProperty alloc] initWithName:@"deletedCol" type:RLMPropertyTypeBool objectClassName:nil indexed:NO optional:NO];
    thirdProperty.column = 2;
    thirdProperty.declarationIndex = 2;
    objectSchema.properties = [objectSchema.properties arrayByAddingObject:thirdProperty];

    // create realm with old schema and populate
    [self createTestRealmWithSchema:@[objectSchema] block:^(RLMRealm *realm) {
        [realm createObject:MigrationObject.className withValue:@[@1, @"1", @YES]];
        [realm createObject:MigrationObject.className withValue:@[@2, @"2", @NO]];
    }];

    // apply migration
    RLMRealm *realm = [self migrateTestRealmWithBlock:^(RLMMigration *migration, uint64_t oldSchemaVersion) {
        XCTAssertEqual(oldSchemaVersion, 0U, @"Initial schema version should be 0");
        [migration enumerateObjects:MigrationObject.className
                                       block:^(RLMObject *oldObject, RLMObject *newObject) {
            XCTAssertNoThrow(oldObject[@"deletedCol"], @"Deleted column should be accessible on old object.");
            XCTAssertThrows(newObject[@"deletedCol"], @"Deleted column should not be accessible on new object.");

            XCTAssertEqualObjects(newObject[@"intCol"], oldObject[@"intCol"]);
            XCTAssertEqualObjects(newObject[@"stringCol"], oldObject[@"stringCol"]);
        }];
    }];

    // verify migration
    MigrationObject *mig1 = [MigrationObject allObjectsInRealm:realm][1];
    XCTAssertThrows(mig1[@"deletedCol"], @"Deleted column should no longer be accessible.");
}

- (void)testRemoveAndAddProperty {
    // create schema to migrate from with single string column
    RLMObjectSchema *objectSchema = [RLMObjectSchema schemaForObjectClass:MigrationObject.class];
    RLMProperty *oldInt = [[RLMProperty alloc] initWithName:@"oldIntCol" type:RLMPropertyTypeInt objectClassName:nil indexed:NO optional:NO];
    objectSchema.properties = @[oldInt, objectSchema.properties[1]];

    // create realm with old schema and populate
    [self createTestRealmWithSchema:@[objectSchema] block:^(RLMRealm *realm) {
        [realm createObject:MigrationObject.className withValue:@[@1, @"1"]];
        [realm createObject:MigrationObject.className withValue:@[@1, @"2"]];
    }];

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
    RLMRealm *realm = [self migrateTestRealmWithBlock:^(RLMMigration *migration, uint64_t oldSchemaVersion) {
        XCTAssertEqual(oldSchemaVersion, 0U, @"Initial schema version should be 0");
        [migration enumerateObjects:MigrationObject.className block:migrateObjectBlock];
    }];

    // verify migration
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
    [self createTestRealmWithSchema:@[objectSchema] block:^(RLMRealm *realm) {
        [realm createObject:MigrationObject.className withValue:@[@1, @1]];
        [realm createObject:MigrationObject.className withValue:@[@2, @2]];
    }];

    // apply migration
    RLMRealm *realm = [self migrateTestRealmWithBlock:^(RLMMigration *migration, uint64_t oldSchemaVersion) {
        XCTAssertEqual(oldSchemaVersion, 0U, @"Initial schema version should be 0");
        [migration enumerateObjects:MigrationObject.className
                                       block:^(RLMObject *oldObject, RLMObject *newObject) {
            XCTAssertEqualObjects(newObject[@"intCol"], oldObject[@"intCol"]);
            NSNumber *intObj = oldObject[@"stringCol"];
            XCTAssert([intObj isKindOfClass:NSNumber.class], @"Old stringCol should be int");
            newObject[@"stringCol"] = intObj.stringValue;
        }];
    }];

    // verify migration
    MigrationObject *mig1 = [MigrationObject allObjectsInRealm:realm][1];
    XCTAssertEqualObjects(mig1[@"stringCol"], @"2", @"stringCol should be string after migration.");
}

- (void)testChangeObjectLinkType {
    // create realm with old schema and populate
    [self createTestRealmWithSchema:RLMSchema.sharedSchema.objectSchema block:^(RLMRealm *realm) {
        id obj = [realm createObject:MigrationObject.className withValue:@[@1, @"1"]];
        [realm createObject:MigrationLinkObject.className withValue:@[obj, @[obj]]];
    }];

    // Make the object link property link to a different class
    RLMRealmConfiguration *config = self.config;
    RLMObjectSchema *objectSchema = [RLMObjectSchema schemaForObjectClass:MigrationLinkObject.class];
    [objectSchema.properties[0] setObjectClassName:MigrationLinkObject.className];
    config.customSchema = [self schemaWithObjects:@[objectSchema, [RLMObjectSchema schemaForObjectClass:MigrationObject.class]]];

    // Apply migration
    config.schemaVersion = 1;
    config.migrationBlock = ^(RLMMigration *migration, uint64_t oldSchemaVersion) {
        XCTAssertEqual(oldSchemaVersion, 0U, @"Initial schema version should be 0");
        [migration enumerateObjects:MigrationLinkObject.className
                                       block:^(RLMObject *oldObject, RLMObject *newObject) {
                                           XCTAssertNotNil(oldObject[@"object"]);
                                           XCTAssertNil(newObject[@"object"]);

                                           XCTAssertEqual(1U, [oldObject[@"array"] count]);
                                           XCTAssertEqual(1U, [newObject[@"array"] count]);
                                       }];
    };
    RLMRealm *realm = [RLMRealm realmWithConfiguration:config error:nil];
    RLMAssertRealmSchemaMatchesTable(self, realm);
}

- (void)testChangeArrayLinkType {
    // create realm with old schema and populate
    RLMRealmConfiguration *config = [self config];
    [self createTestRealmWithSchema:RLMSchema.sharedSchema.objectSchema block:^(RLMRealm *realm) {
        id obj = [realm createObject:MigrationObject.className withValue:@[@1, @"1"]];
        [realm createObject:MigrationLinkObject.className withValue:@[obj, @[obj]]];
    }];

    // Make the array linklist property link to a different class
    RLMObjectSchema *objectSchema = [RLMObjectSchema schemaForObjectClass:MigrationLinkObject.class];
    [objectSchema.properties[1] setObjectClassName:MigrationLinkObject.className];
    config.customSchema = [self schemaWithObjects:@[objectSchema, [RLMObjectSchema schemaForObjectClass:MigrationObject.class]]];

    // Apply migration
    config.schemaVersion = 1;
    config.migrationBlock = ^(RLMMigration *migration, uint64_t oldSchemaVersion) {
        XCTAssertEqual(oldSchemaVersion, 0U, @"Initial schema version should be 0");
        [migration enumerateObjects:MigrationLinkObject.className
                                       block:^(RLMObject *oldObject, RLMObject *newObject) {
                                           XCTAssertNotNil(oldObject[@"object"]);
                                           XCTAssertNotNil(newObject[@"object"]);

                                           XCTAssertEqual(1U, [oldObject[@"array"] count]);
                                           XCTAssertEqual(0U, [newObject[@"array"] count]);
                                       }];
    };
    RLMRealm *realm = [RLMRealm realmWithConfiguration:config error:nil];
    RLMAssertRealmSchemaMatchesTable(self, realm);
}

- (void)testMakingPropertyPrimaryPreservesValues {
    RLMObjectSchema *objectSchema = [RLMObjectSchema schemaForObjectClass:MigrationStringPrimaryKeyObject.class];
    objectSchema.primaryKeyProperty = nil;

    [self createTestRealmWithSchema:@[objectSchema] block:^(RLMRealm *realm) {
        [realm createObject:MigrationStringPrimaryKeyObject.className withValue:@[@"1"]];
        [realm createObject:MigrationStringPrimaryKeyObject.className withValue:@[@"2"]];
    }];

    RLMRealm *realm = [self migrateTestRealmWithBlock:nil];
    RLMResults *objects = [MigrationStringPrimaryKeyObject allObjectsInRealm:realm];
    XCTAssertEqualObjects(@"1", [objects[0] stringCol]);
    XCTAssertEqualObjects(@"2", [objects[1] stringCol]);
}

- (void)testAddingPrimaryKeyShouldRejectDuplicateValues {
    // make the pk non-primary so that we can add duplicate values
    RLMObjectSchema *objectSchema = [RLMObjectSchema schemaForObjectClass:MigrationPrimaryKeyObject.class];
    objectSchema.primaryKeyProperty = nil;
    [self createTestRealmWithSchema:@[objectSchema] block:^(RLMRealm *realm) {
        // populate with values that will be invalid when the property is made primary
        [realm createObject:MigrationPrimaryKeyObject.className withValue:@[@1]];
        [realm createObject:MigrationPrimaryKeyObject.className withValue:@[@1]];
    }];

    // Fails due to duplicate values
    [self failToMigrateTestRealmWithBlock:nil];

    // apply good migration that deletes duplicates
    RLMRealm *realm = [self migrateTestRealmWithBlock:^(RLMMigration *migration, uint64_t) {
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

    // make sure deletion occurred
    XCTAssertEqual(1U, [[MigrationPrimaryKeyObject allObjectsInRealm:realm] count]);
}

- (void)testIncompleteMigrationIsRolledBack {
    RLMObjectSchema *objectSchema = [RLMObjectSchema schemaForObjectClass:MigrationPrimaryKeyObject.class];
    objectSchema.primaryKeyProperty = nil;
    [self createTestRealmWithSchema:@[objectSchema] block:^(RLMRealm *realm) {
        [realm createObject:MigrationPrimaryKeyObject.className withValue:@[@1]];
        [realm createObject:MigrationPrimaryKeyObject.className withValue:@[@1]];
    }];

    // fail to apply migration
    [self failToMigrateTestRealmWithBlock:nil];

    // should still be able to open with pre-migration schema
    XCTAssertNoThrow([self realmWithSingleObject:objectSchema]);
}

- (void)testAddObjectDuringMigration {
    // initialize realm
    @autoreleasepool { [self realmWithTestPath]; }

    RLMRealm *realm = [self migrateTestRealmWithBlock:^(RLMMigration * migration, uint64_t) {
        [migration createObject:StringObject.className withValue:@[@"string"]];
    }];
    XCTAssertEqual(1U, [StringObject allObjectsInRealm:realm].count);
}

- (void)testEnumeratedObjectsDuringMigration {
    [self createTestRealmWithClasses:@[StringObject.class, ArrayPropertyObject.class, IntObject.class] block:^(RLMRealm *realm) {
        [StringObject createInRealm:realm withValue:@[@"string"]];
        [ArrayPropertyObject createInRealm:realm withValue:@[@"array", @[@[@"string"]], @[@[@1]]]];
    }];

    RLMRealm *realm = [self migrateTestRealmWithBlock:^(RLMMigration *migration, uint64_t) {
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

    XCTAssertEqualObjects(@"otherString", [[StringObject allObjectsInRealm:realm].firstObject stringCol]);
}

- (void)testRequiredToNullableAutoMigration {
    RLMObjectSchema *objectSchema = [RLMObjectSchema schemaForObjectClass:AllOptionalTypes.class];
    [objectSchema.properties setValue:@NO forKey:@"optional"];

    // create initial required column
    [self createTestRealmWithSchema:@[objectSchema] block:^(RLMRealm *realm) {
        [AllOptionalTypes createInRealm:realm withValue:@[@1, @1, @1, @1, @"str",
                                                          [@"data" dataUsingEncoding:NSUTF8StringEncoding],
                                                          [NSDate dateWithTimeIntervalSince1970:1]]];
        [AllOptionalTypes createInRealm:realm withValue:@[@2, @2, @2, @0, @"str2",
                                                          [@"data2" dataUsingEncoding:NSUTF8StringEncoding],
                                                          [NSDate dateWithTimeIntervalSince1970:2]]];
    }];

    RLMRealm *realm = [self migrateTestRealmWithBlock:nil];
    RLMResults *allObjects = [AllOptionalTypes allObjectsInRealm:realm];
    XCTAssertEqual(2U, allObjects.count);

    AllOptionalTypes *obj = allObjects[0];
    XCTAssertEqualObjects(@1, obj.intObj);
    XCTAssertEqualObjects(@1, obj.floatObj);
    XCTAssertEqualObjects(@1, obj.doubleObj);
    XCTAssertEqualObjects(@1, obj.boolObj);
    XCTAssertEqualObjects(@"str", obj.string);
    XCTAssertEqualObjects([@"data" dataUsingEncoding:NSUTF8StringEncoding], obj.data);
    XCTAssertEqualObjects([NSDate dateWithTimeIntervalSince1970:1], obj.date);

    obj = allObjects[1];
    XCTAssertEqualObjects(@2, obj.intObj);
    XCTAssertEqualObjects(@2, obj.floatObj);
    XCTAssertEqualObjects(@2, obj.doubleObj);
    XCTAssertEqualObjects(@0, obj.boolObj);
    XCTAssertEqualObjects(@"str2", obj.string);
    XCTAssertEqualObjects([@"data2" dataUsingEncoding:NSUTF8StringEncoding], obj.data);
    XCTAssertEqualObjects([NSDate dateWithTimeIntervalSince1970:2], obj.date);
}

- (void)testNullableToRequiredMigration {
    RLMObjectSchema *objectSchema = [RLMObjectSchema schemaForObjectClass:AllOptionalTypes.class];

    // create initial nullable column
    [self createTestRealmWithSchema:@[objectSchema] block:^(RLMRealm *realm) {
        [AllOptionalTypes createInRealm:realm withValue:@[ [NSNull null], [NSNull null], [NSNull null], [NSNull null],
                                                           [NSNull null], [NSNull null], [NSNull null]]];
        [AllOptionalTypes createInRealm:realm withValue:@[@2, @2, @2, @0, @"str2",
                                                          [@"data2" dataUsingEncoding:NSUTF8StringEncoding],
                                                          [NSDate dateWithTimeIntervalSince1970:2]]];
    }];

    [objectSchema.properties setValue:@NO forKey:@"optional"];

    RLMRealm *realm;
    @autoreleasepool {
        RLMRealmConfiguration *config = [RLMRealmConfiguration new];
        config.path = RLMTestRealmPath();
        config.customSchema = [self schemaWithObjects:@[ objectSchema ]];
        config.schemaVersion = 1;
        XCTAssertNil([RLMRealm migrateRealm:config]);

        realm = [RLMRealm realmWithConfiguration:config error:nil];
        RLMAssertRealmSchemaMatchesTable(self, realm);
    }

    RLMResults *allObjects = [AllOptionalTypes allObjectsInRealm:realm];
    XCTAssertEqual(2U, allObjects.count);

    AllOptionalTypes *obj = allObjects[0];
    XCTAssertEqualObjects(@0, obj.intObj);
    XCTAssertEqualObjects(@0, obj.floatObj);
    XCTAssertEqualObjects(@0, obj.doubleObj);
    XCTAssertEqualObjects(@0, obj.boolObj);
    XCTAssertEqualObjects(@"", obj.string);
    XCTAssertEqualObjects(NSData.data, obj.data);
    XCTAssertEqualObjects([NSDate dateWithTimeIntervalSince1970:0], obj.date);

    obj = allObjects[1];
    XCTAssertEqualObjects(@0, obj.intObj);
    XCTAssertEqualObjects(@0, obj.floatObj);
    XCTAssertEqualObjects(@0, obj.doubleObj);
    XCTAssertEqualObjects(@0, obj.boolObj);
    XCTAssertEqualObjects(@"", obj.string);
    XCTAssertEqualObjects(NSData.data, obj.data);
    XCTAssertEqualObjects([NSDate dateWithTimeIntervalSince1970:0], obj.date);
}

- (void)testMigrationAfterReorderingProperties {
    RLMObjectSchema *objectSchema = [RLMObjectSchema schemaForObjectClass:RequiredPropertiesObject.class];
    // Create a table where the order of columns does not match the order the properties are declared in the class.
    objectSchema.properties = @[ objectSchema.properties[2], objectSchema.properties[0], objectSchema.properties[1] ];

    [self createTestRealmWithSchema:@[objectSchema] block:^(RLMRealm *realm) {
        // We use a dictionary here to ensure that the test reaches the migration case below, even if the non-migration
        // case doesn't handle the ordering correctly. The non-migration case is tested in testRearrangeProperties.
        [RequiredPropertiesObject createInRealm:realm withValue:@{ @"stringCol": @"Hello", @"dateCol": [NSDate date], @"binaryCol": [NSData data] }];
    }];

    objectSchema = [RLMObjectSchema schemaForObjectClass:RequiredPropertiesObject.class];
    RLMRealmConfiguration *config = [RLMRealmConfiguration new];
    config.path = RLMTestRealmPath();
    config.customSchema = [self schemaWithObjects:@[objectSchema]];
    config.schemaVersion = 1;
    config.migrationBlock = ^(RLMMigration *migration, uint64_t) {
        [migration createObject:RequiredPropertiesObject.className withValue:@[@"World", [NSData data], [NSDate date]]];
    };

    XCTAssertNil([RLMRealm migrateRealm:config]);
    RLMRealm *realm = [RLMRealm realmWithConfiguration:config error:nil];

    RLMResults *allObjects = [RequiredPropertiesObject allObjectsInRealm:realm];
    XCTAssertEqualObjects(@"Hello", [allObjects[0] stringCol]);
    XCTAssertEqualObjects(@"World", [allObjects[1] stringCol]);
}

@end
