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

#import <realm/version.hpp>
#import <objc/runtime.h>

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

@interface DateMigrationObject : RLMObject
@property (nonatomic, strong) NSDate *nonNullNonIndexed;
@property (nonatomic, strong) NSDate *nullNonIndexed;
@property (nonatomic, strong) NSDate *nonNullIndexed;
@property (nonatomic, strong) NSDate *nullIndexed;
@property (nonatomic) int cookie;
@end

#define RLM_OLD_DATE_FORMAT (REALM_VER_MAJOR < 1 && REALM_VER_MINOR < 100)

@implementation DateMigrationObject
+ (NSArray *)requiredProperties {
    return @[@"nonNullNonIndexed", @"nonNullIndexed"];
}

+ (NSArray *)indexedProperties {
    return @[@"nonNullIndexed", @"nullIndexed"];
}
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
    config.fileURL = RLMTestRealmURL();
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
        config.fileURL = RLMTestRealmURL();
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
        config.fileURL = RLMTestRealmURL();
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
        config.fileURL = RLMTestRealmURL();
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

    RLMAssertThrowsWithCodeMatching([RLMRealm realmWithConfiguration:config error:nil], RLMErrorSchemaMismatch);

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

- (RLMRealmConfiguration *)renameConfigurationWithObjectSchemas:(NSArray *)objectSchemas migrationBlock:(RLMMigrationBlock)block {
    RLMRealmConfiguration *configuration = [RLMRealmConfiguration new];
    configuration.fileURL = RLMTestRealmURL();
    configuration.schemaVersion = 1;
    configuration.customSchema = [self schemaWithObjects:objectSchemas];
    configuration.migrationBlock = block;
    return configuration;
}

- (RLMRealmConfiguration *)renameConfigurationWithObjectSchemas:(NSArray *)objectSchemas className:(NSString *)className
                                                        oldName:(NSString *)oldName newName:(NSString *)newName {
    return [self renameConfigurationWithObjectSchemas:objectSchemas migrationBlock:^(RLMMigration *migration, uint64_t) {
        [migration renamePropertyForClass:className oldName:oldName newName:newName];
        [migration enumerateObjects:AllTypesObject.className block:^(RLMObject *oldObject, RLMObject *newObject) {
            XCTAssertNotNil(oldObject[oldName]);
            RLMAssertThrowsWithReasonMatching(newObject[newName], @"Invalid property name");
            XCTAssertEqualObjects(oldObject[oldName], newObject[newName]);
            XCTAssertEqualObjects([oldObject.description stringByReplacingOccurrencesOfString:@"before_" withString:@""], newObject.description);
        }];
    }];
}

- (void)assertPropertyRenameError:(NSString *)errorMessage objectSchemas:(NSArray *)objectSchemas
                        className:(NSString *)className oldName:(NSString *)oldName newName:(NSString *)newName {
    RLMRealmConfiguration *config = [self renameConfigurationWithObjectSchemas:objectSchemas className:className
                                                                       oldName:oldName newName:newName];
    XCTAssertTrue([[[RLMRealm migrateRealm:config] localizedDescription] rangeOfString:errorMessage].location != NSNotFound);
}

- (void)assertPropertyRenameError:(NSString *)errorMessage
             firstSchemaTransform:(void (^)(RLMObjectSchema *, RLMProperty *, RLMProperty *))transform1
            secondSchemaTransform:(void (^)(RLMObjectSchema *, RLMProperty *, RLMProperty *))transform2 {
    RLMObjectSchema *schema = [RLMObjectSchema schemaForObjectClass:StringObject.class];
    RLMProperty *afterProperty = schema.properties.firstObject;
    RLMProperty *beforeProperty = [afterProperty copyWithNewName:@"before_stringCol"];
    schema.properties = @[beforeProperty];
    if (transform1) { transform1(schema, beforeProperty, afterProperty); }

    [self createTestRealmWithSchema:@[schema] block:^(RLMRealm *realm) {
        if (errorMessage == nil) {
            [StringObject createInRealm:realm withValue:@[@"0"]];
        }
    }];

    schema.properties = @[afterProperty];
    if (transform2) { transform2(schema, beforeProperty, afterProperty); }

    RLMRealmConfiguration *config = [self renameConfigurationWithObjectSchemas:@[schema] className:StringObject.className
                                                                       oldName:beforeProperty.name newName:afterProperty.name];

    if (errorMessage) {
        XCTAssertEqualObjects([[RLMRealm migrateRealm:config] localizedDescription], errorMessage);
    } else {
        XCTAssertNil([RLMRealm migrateRealm:config]);
        XCTAssertEqualObjects(@"0", [[[StringObject allObjectsInRealm:[RLMRealm realmWithConfiguration:config error:nil]] firstObject] stringCol]);
    }
}

#pragma mark - Schema versions

- (void)testGetSchemaVersion {
    XCTAssertThrows([RLMRealm schemaVersionAtURL:RLMDefaultRealmURL() encryptionKey:nil error:nil]);
    NSError *error;
    XCTAssertEqual(RLMNotVersioned, [RLMRealm schemaVersionAtURL:RLMDefaultRealmURL() encryptionKey:nil error:&error]);
    RLMValidateRealmError(error, RLMErrorFail, @"Cannot open an uninitialized realm in read-only mode", nil);

    RLMRealmConfiguration *config = [RLMRealmConfiguration defaultConfiguration];
    @autoreleasepool { [RLMRealm realmWithConfiguration:config error:nil]; }
    XCTAssertEqual(0U, [RLMRealm schemaVersionAtURL:config.fileURL encryptionKey:nil error:nil]);

    config.schemaVersion = 1;
    config.migrationBlock = ^(__unused RLMMigration *migration, uint64_t oldSchemaVersion) {
        XCTAssertEqual(0U, oldSchemaVersion);
    };

    @autoreleasepool { [RLMRealm realmWithConfiguration:config error:nil]; }
    XCTAssertEqual(1U, [RLMRealm schemaVersionAtURL:config.fileURL encryptionKey:nil error:nil]);
}

- (void)testSchemaVersionCannotGoDown {
    RLMRealmConfiguration *config = [RLMRealmConfiguration defaultConfiguration];
    config.schemaVersion = 10;
    @autoreleasepool { [RLMRealm realmWithConfiguration:config error:nil]; }
    XCTAssertEqual(10U, [RLMRealm schemaVersionAtURL:config.fileURL encryptionKey:nil error:nil]);

    config.schemaVersion = 5;
    RLMAssertThrowsWithReasonMatching([RLMRealm realmWithConfiguration:config error:nil],
                                      @"Provided schema version 5 is less than last set version 10.");
}

- (void)testDifferentSchemaVersionsAtDifferentPaths {
    RLMRealmConfiguration *config = [RLMRealmConfiguration defaultConfiguration];
    config.schemaVersion = 10;
    @autoreleasepool { [RLMRealm realmWithConfiguration:config error:nil]; }
    XCTAssertEqual(10U, [RLMRealm schemaVersionAtURL:config.fileURL encryptionKey:nil error:nil]);

    RLMRealmConfiguration *config2 = [RLMRealmConfiguration defaultConfiguration];
    config2.schemaVersion = 5;
    config2.fileURL = RLMTestRealmURL();
    @autoreleasepool { [RLMRealm realmWithConfiguration:config2 error:nil]; }
    XCTAssertEqual(5U, [RLMRealm schemaVersionAtURL:config2.fileURL encryptionKey:nil error:nil]);

    // Should not have been changed
    XCTAssertEqual(10U, [RLMRealm schemaVersionAtURL:config.fileURL encryptionKey:nil error:nil]);
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

- (void)testDeleteRealmIfMigrationNeededWithSetCustomSchema {
    RLMObjectSchema *from = [RLMObjectSchema schemaForObjectClass:MigrationTwoStringObject.class];
    from.properties = [from.properties subarrayWithRange:{0, 1}];

    RLMObjectSchema *to = [RLMObjectSchema schemaForObjectClass:MigrationTwoStringObject.class];

    RLMRealmConfiguration *config = [RLMRealmConfiguration new];
    config.customSchema = [self schemaWithObjects:@[from]];
    @autoreleasepool { [RLMRealm realmWithConfiguration:config error:nil]; }

    config.customSchema = [self schemaWithObjects:@[to]];
    config.migrationBlock = ^(__unused RLMMigration *migration, __unused uint64_t oldSchemaVersion) {
        XCTFail(@"Migration block should not have been called");
    };

    config.deleteRealmIfMigrationNeeded = YES;

    XCTAssertNoThrow([RLMRealm realmWithConfiguration:config error:nil]);
    RLMAssertRealmSchemaMatchesTable(self, [RLMRealm realmWithConfiguration:config error:nil]);
}

- (void)testDeleteRealmIfMigrationNeeded {
    for (uint64_t targetSchemaVersion = 1; targetSchemaVersion < 2; targetSchemaVersion++) {
        RLMRealmConfiguration *configuration = [RLMRealmConfiguration defaultConfiguration];
        RLMObjectSchema *objectSchema = [RLMObjectSchema schemaForObjectClass:MigrationObject.class];
        configuration.customSchema = [self schemaWithObjects:@[objectSchema]];

        @autoreleasepool {
            [[NSFileManager defaultManager] removeItemAtURL:configuration.fileURL error:nil];
            RLMRealm *realm = [RLMRealm realmWithConfiguration:configuration error:nil];
            [realm transactionWithBlock:^{
                [realm addObject:[MigrationObject new]];
            }];
        }

        // Change string to int, requiring a migration
        RLMProperty *stringCol = objectSchema.properties[1];
        stringCol.type = RLMPropertyTypeInt;
        stringCol.objcType = 'i';
        stringCol.optional = NO;
        objectSchema.properties = @[stringCol];

        configuration.customSchema = [self schemaWithObjects:@[objectSchema]];

        @autoreleasepool {
            XCTAssertThrows([RLMRealm realmWithConfiguration:configuration error:nil]);
            RLMRealmConfiguration *dynamicConfiguration = [RLMRealmConfiguration defaultConfiguration];
            dynamicConfiguration.dynamic = YES;
            XCTAssertFalse([[RLMRealm realmWithConfiguration:dynamicConfiguration error:nil] isEmpty]);
        }

        configuration.schemaVersion = targetSchemaVersion;
        configuration.migrationBlock = ^(__unused RLMMigration *migration, __unused uint64_t oldSchemaVersion) {
            XCTFail(@"Migration block should not have been called");
        };
        configuration.deleteRealmIfMigrationNeeded = YES;

        RLMRealm *realm = [RLMRealm realmWithConfiguration:configuration error:nil];
        RLMAssertRealmSchemaMatchesTable(self, realm);
        XCTAssertTrue(realm.isEmpty);
    }
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
        RLMRealm *realm = [self readOnlyRealmWithURL:RLMTestRealmURL() error:nil];

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
    RLMProperty *thirdProperty = [[RLMProperty alloc] initWithName:@"deletedCol" type:RLMPropertyTypeBool objectClassName:nil linkOriginPropertyName:nil indexed:NO optional:NO];
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
    RLMProperty *oldInt = [[RLMProperty alloc] initWithName:@"oldIntCol" type:RLMPropertyTypeInt objectClassName:nil linkOriginPropertyName:nil indexed:NO optional:NO];
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
        config.fileURL = RLMTestRealmURL();
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
    config.fileURL = RLMTestRealmURL();
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

- (void)testDateTimeFormatAutoMigration {
    static const int cookieValue = 0xDEADBEEF;

    NSDate *distantPast = NSDate.distantPast;
    NSDate *distantFuture = NSDate.distantFuture;
    NSDate *beforeEpoch = [NSDate dateWithTimeIntervalSince1970:-100];
    NSDate *epoch = [NSDate dateWithTimeIntervalSince1970:0];
    NSDate *afterEpoch = [NSDate dateWithTimeIntervalSince1970:100];
    NSDate *referenceDate = [NSDate dateWithTimeIntervalSinceReferenceDate:0];

    NSArray *expectedDates = @[distantPast, distantFuture, beforeEpoch, epoch, afterEpoch, referenceDate];

    RLMRealmConfiguration *config = [RLMRealmConfiguration defaultConfiguration];
    config.objectClasses = @[[DateMigrationObject class]];

    @autoreleasepool {
#if RLM_OLD_DATE_FORMAT
        RLMRealm *realm = [RLMRealm realmWithConfiguration:config error:nil];
        [realm beginWriteTransaction];
        for (NSDate *date in expectedDates) {
            [DateMigrationObject createInRealm:realm withValue:@[date, date, date, date, @(cookieValue)]];
            [DateMigrationObject createInRealm:realm withValue:@[date, NSNull.null, date, NSNull.null, @(cookieValue)]];
        }
        [realm commitWriteTransaction];

        NSURL *url = [config.fileURL.URLByDeletingLastPathComponent URLByAppendingPathComponent:@"fileformat-old-date.realm"];
        [realm writeCopyToURL:url encryptionKey:nil error:nil];
        NSLog(@"wrote pre-migration realm to %@", url);
#else
        NSURL *bundledRealmURL = [[NSBundle bundleForClass:[DateMigrationObject class]]
                                  URLForResource:@"fileformat-old-date" withExtension:@"realm"];
        [NSFileManager.defaultManager copyItemAtURL:bundledRealmURL toURL:config.fileURL error:nil];

        RLMRealm *realm = [RLMRealm realmWithConfiguration:config error:nil];
        RLMResults *dates = [DateMigrationObject allObjectsInRealm:realm];
        XCTAssertEqual(expectedDates.count * 2, dates.count);
        for (NSUInteger i = 0; i < expectedDates.count; ++i) {
            NSDate *expected = expectedDates[i];
            DateMigrationObject *obj = dates[i * 2];
            XCTAssertEqualObjects(obj.nonNullNonIndexed, expected);
            XCTAssertEqualObjects(obj.nonNullIndexed, expected);
            XCTAssertEqualObjects(obj.nullNonIndexed, expected);
            XCTAssertEqualObjects(obj.nullIndexed, expected);
            XCTAssertEqual(obj.cookie, cookieValue);

            obj = dates[i * 2 + 1];
            XCTAssertEqualObjects(obj.nonNullNonIndexed, expected);
            XCTAssertEqualObjects(obj.nonNullIndexed, expected);
            XCTAssertNil(obj.nullNonIndexed);
            XCTAssertNil(obj.nullIndexed);
            XCTAssertEqual(obj.cookie, cookieValue);
        }

        for (NSDate *date in expectedDates) {
            RLMResults *results = [DateMigrationObject objectsInRealm:realm
                                   where:@"nonNullIndexed = %@ AND nullIndexed = %@",
                                   date, date];
            XCTAssertEqual(1U, results.count);
            DateMigrationObject *obj = results.firstObject;
            XCTAssertEqualObjects(date, obj.nonNullIndexed);
            XCTAssertEqualObjects(date, obj.nullIndexed);

            results = [DateMigrationObject objectsInRealm:realm
                       where:@"nonNullIndexed = %@ AND nullIndexed = nil", date];
            XCTAssertEqual(1U, results.count);
            obj = results.firstObject;
            XCTAssertEqualObjects(date, obj.nonNullIndexed);
            XCTAssertNil(obj.nullIndexed);
        }
#endif
    }

    @autoreleasepool {
        NSURL *bundledRealmURL = [[NSBundle bundleForClass:[DateMigrationObject class]]
                                  URLForResource:@"fileformat-pre-null" withExtension:@"realm"];
        [NSFileManager.defaultManager removeItemAtURL:config.fileURL error:nil];
        [NSFileManager.defaultManager copyItemAtURL:bundledRealmURL toURL:config.fileURL error:nil];

        config.schemaVersion = 1; // Nullability of some properties changed
        RLMRealm *realm = [RLMRealm realmWithConfiguration:config error:nil];
        RLMResults *dates = [DateMigrationObject allObjectsInRealm:realm];
        XCTAssertEqual(expectedDates.count, dates.count);
        for (NSUInteger i = 0; i < expectedDates.count; ++i) {
            NSDate *expected = expectedDates[i];
            DateMigrationObject *obj = dates[i];
            XCTAssertEqualObjects(obj.nonNullNonIndexed, expected);
            XCTAssertEqualObjects(obj.nonNullIndexed, expected);
            XCTAssertEqualObjects(obj.nullNonIndexed, expected);
            XCTAssertEqualObjects(obj.nullIndexed, expected);
            XCTAssertEqual(obj.cookie, cookieValue);
        }
    }
}

- (void)testMigratingFromMixed {
    NSArray *values = @[@YES, @1, @1.1, @1.2f, @"str",
                        [@"data" dataUsingEncoding:NSUTF8StringEncoding],
                        [NSDate dateWithTimeIntervalSince1970:100]];
    RLMRealmConfiguration *config = [RLMRealmConfiguration defaultConfiguration];
    config.objectClasses = @[[AllTypesObject class], [LinkToAllTypesObject class], [StringObject class]];

#if 0 // Code for generating the test realm
    RLMRealm *realm = [RLMRealm realmWithConfiguration:config error:nil];
    [realm beginWriteTransaction];
    for (id value in values) {
        [AllTypesObject createInRealm:realm withValue:@[@NO, @0, @0, @0, @"",
                                                        NSData.data, NSDate.date,
                                                        @NO, @0, value, NSNull.null]];
    }
    [realm commitWriteTransaction];

    NSURL *url = [config.fileURL.URLByDeletingLastPathComponent URLByAppendingPathComponent:@"mixed-column.realm"];
    [realm writeCopyToURL:url encryptionKey:nil error:nil];
    NSLog(@"wrote pre-migration realm to %@", url);
#else
    NSURL *bundledRealmURL = [[NSBundle bundleForClass:[DateMigrationObject class]]
                              URLForResource:@"mixed-column" withExtension:@"realm"];
    [NSFileManager.defaultManager removeItemAtURL:config.fileURL error:nil];
    [NSFileManager.defaultManager copyItemAtURL:bundledRealmURL toURL:config.fileURL error:nil];

    __block bool migrationCalled = false;
    config.schemaVersion = 1;
    config.migrationBlock = ^(RLMMigration *migration, uint64_t) {
        __block NSUInteger i = values.count;
        [migration enumerateObjects:@"AllTypesObject" block:^(RLMObject *oldObject, RLMObject *newObject) {
            XCTAssertEqualObjects(values[--i], oldObject[@"mixedCol"]);
            RLMAssertThrowsWithReasonMatching(newObject[@"mixedCol"],
                                              @"Invalid property name `mixedCol` for class `AllTypesObject`.");
        }];
        migrationCalled = true;
    };
    XCTAssertNil([RLMRealm migrateRealm:config]);
    XCTAssertTrue(migrationCalled);
#endif
}

#pragma mark - Property Rename

// Successful Property Rename Tests

- (void)testMigrationRenameProperty {
    RLMObjectSchema *objectSchema = [RLMObjectSchema schemaForObjectClass:AllTypesObject.class];
    RLMObjectSchema *stringObjectSchema = [RLMObjectSchema schemaForObjectClass:StringObject.class];
    RLMObjectSchema *linkingObjectsSchema = [RLMObjectSchema schemaForObjectClass:LinkToAllTypesObject.class];
    NSMutableArray *beforeProperties = [NSMutableArray arrayWithCapacity:objectSchema.properties.count];
    for (RLMProperty *property in objectSchema.properties) {
        [beforeProperties addObject:[property copyWithNewName:[NSString stringWithFormat:@"before_%@", property.name]]];
    }
    NSArray *afterProperties = objectSchema.properties;
    objectSchema.properties = beforeProperties;

    NSDate *now = [NSDate dateWithTimeIntervalSince1970:100000];
    id inputValue = @[@YES, @1, @1.1f, @1.11, @"string", [NSData dataWithBytes:"a" length:1], now, @YES, @11, @[@"a"]];

    [self createTestRealmWithSchema:@[objectSchema, stringObjectSchema, linkingObjectsSchema] block:^(RLMRealm *realm) {
        [AllTypesObject createInRealm:realm withValue:inputValue];
    }];

    objectSchema.properties = afterProperties;

    RLMRealmConfiguration *config = [self renameConfigurationWithObjectSchemas:@[objectSchema, stringObjectSchema, linkingObjectsSchema]
                                                                migrationBlock:^(RLMMigration *migration, __unused uint64_t oldSchemaVersion) {
        [afterProperties enumerateObjectsUsingBlock:^(RLMProperty *property, NSUInteger idx, __unused BOOL *stop) {
            [migration renamePropertyForClass:AllTypesObject.className oldName:[beforeProperties[idx] name] newName:property.name];
            [migration enumerateObjects:AllTypesObject.className block:^(RLMObject *oldObject, RLMObject *newObject) {
                XCTAssertNotNil(oldObject[[beforeProperties[idx] name]]);
                RLMAssertThrowsWithReasonMatching(newObject[[beforeProperties[idx] name]], @"Invalid property name");
                if (![property.objectClassName isEqualToString:@""]) { return; }
                XCTAssertEqualObjects(oldObject[[beforeProperties[idx] name]], newObject[property.name]);
            }];
        }];
        [migration enumerateObjects:AllTypesObject.className block:^(RLMObject *oldObject, RLMObject *newObject) {
            XCTAssertEqualObjects([oldObject.description stringByReplacingOccurrencesOfString:@"before_" withString:@""], newObject.description);
        }];
    }];
    XCTAssertNil([RLMRealm migrateRealm:config]);

    RLMRealm *realm = [RLMRealm realmWithConfiguration:config error:nil];
    RLMAssertRealmSchemaMatchesTable(self, realm);

    RLMResults *allObjects = [AllTypesObject allObjectsInRealm:realm];
    XCTAssertEqual(1U, allObjects.count);
    XCTAssertEqual(1U, [[StringObject allObjectsInRealm:realm] count]);

    AllTypesObject *obj = allObjects.firstObject;
    XCTAssertEqualObjects(inputValue[0], @(obj.boolCol));
    XCTAssertEqualObjects(inputValue[1], @(obj.intCol));
    XCTAssertEqualObjects(inputValue[2], @(obj.floatCol));
    XCTAssertEqualObjects(inputValue[3], @(obj.doubleCol));
    XCTAssertEqualObjects(inputValue[4], obj.stringCol);
    XCTAssertEqualObjects(inputValue[5], obj.binaryCol);
    XCTAssertEqualObjects(inputValue[6], obj.dateCol);
    XCTAssertEqualObjects(inputValue[7], @(obj.cBoolCol));
    XCTAssertEqualObjects(inputValue[8], @(obj.longCol));
    XCTAssertEqualObjects(inputValue[9], @[obj.objectCol.stringCol]);
}

- (void)testMultipleMigrationRenameProperty {
    RLMObjectSchema *schema = [RLMObjectSchema schemaForObjectClass:StringObject.class];
    schema.properties = @[[schema.properties.firstObject copyWithNewName:@"stringCol0"]];

    [self createTestRealmWithSchema:@[schema] block:^(RLMRealm *realm) {
        [StringObject createInRealm:realm withValue:@[@"0"]];
    }];

    schema.properties = @[[schema.properties.firstObject copyWithNewName:@"stringCol"]];

    __block bool migrationCalled = false;

    RLMRealmConfiguration *config = [RLMRealmConfiguration new];
    config.fileURL = RLMTestRealmURL();
    config.customSchema = [self schemaWithObjects:@[schema]];
    config.schemaVersion = 2;
    config.migrationBlock = ^(RLMMigration *migration, uint64_t oldVersion){
        migrationCalled = true;
        __block id oldValue = nil;
        if (oldVersion < 1) {
            [migration renamePropertyForClass:StringObject.className oldName:@"stringCol0" newName:@"stringCol1"];
            [migration enumerateObjects:StringObject.className block:^(RLMObject *oldObject, RLMObject *newObject) {
                oldValue = oldObject[@"stringCol0"];
                XCTAssertNotNil(oldValue);
                XCTAssertEqualObjects(newObject[@"stringCol1"], oldValue);
                RLMAssertThrowsWithReasonMatching(newObject[@"stringCol0"], @"Invalid property name");
            }];
        }
        if (oldVersion < 2) {
            [migration renamePropertyForClass:StringObject.className oldName:@"stringCol1" newName:@"stringCol"];

            [migration enumerateObjects:StringObject.className block:^(RLMObject *oldObject, RLMObject *newObject) {
                XCTAssertEqualObjects(oldObject[@"stringCol0"], oldValue);
                XCTAssertEqualObjects(newObject[@"stringCol"], oldValue);
                RLMAssertThrowsWithReasonMatching(newObject[@"stringCol0"], @"Invalid property name");
                RLMAssertThrowsWithReasonMatching(newObject[@"stringCol1"], @"Invalid property name");
            }];
        }
    };

    XCTAssertNil([RLMRealm migrateRealm:config]);
    XCTAssertTrue(migrationCalled);
    XCTAssertEqualObjects(@"0", [[[StringObject allObjectsInRealm:[RLMRealm realmWithConfiguration:config error:nil]] firstObject] stringCol]);
}

- (void)testMigrationRenamePropertyPrimaryKeyBoth {
    [self assertPropertyRenameError:nil firstSchemaTransform:^(RLMObjectSchema *schema, RLMProperty *beforeProperty, __unused RLMProperty *afterProperty) {
        schema.primaryKeyProperty = beforeProperty;
    } secondSchemaTransform:^(RLMObjectSchema *schema, __unused RLMProperty *beforeProperty, RLMProperty *afterProperty) {
        schema.primaryKeyProperty = afterProperty;
    }];
}

- (void)testMigrationRenamePropertyUnsetPrimaryKey {
    [self assertPropertyRenameError:nil firstSchemaTransform:^(RLMObjectSchema *schema, RLMProperty *beforeProperty, __unused RLMProperty *afterProperty) {
        schema.primaryKeyProperty = beforeProperty;
    } secondSchemaTransform:^(RLMObjectSchema *schema, __unused RLMProperty *beforeProperty, __unused RLMProperty *afterProperty) {
        schema.primaryKeyProperty = nil;
    }];
}

- (void)testMigrationRenamePropertySetPrimaryKey {
    [self assertPropertyRenameError:nil firstSchemaTransform:nil
                     secondSchemaTransform:^(RLMObjectSchema *schema, __unused RLMProperty *beforeProperty, RLMProperty *afterProperty) {
        schema.primaryKeyProperty = afterProperty;
    }];
}

- (void)testMigrationRenamePropertyIndexBoth {
    [self assertPropertyRenameError:nil firstSchemaTransform:^(__unused RLMObjectSchema *schema, RLMProperty *beforeProperty, __unused RLMProperty *afterProperty) {
        afterProperty.indexed = YES;
        beforeProperty.indexed = YES;
    } secondSchemaTransform:nil];
}

- (void)testMigrationRenamePropertyUnsetIndex {
    [self assertPropertyRenameError:nil firstSchemaTransform:^(__unused RLMObjectSchema *schema, RLMProperty *beforeProperty, __unused RLMProperty *afterProperty) {
        beforeProperty.indexed = YES;
    } secondSchemaTransform:nil];
}

- (void)testMigrationRenamePropertySetIndex {
    [self assertPropertyRenameError:nil firstSchemaTransform:^(__unused RLMObjectSchema *schema, __unused RLMProperty *beforeProperty, RLMProperty *afterProperty) {
        afterProperty.indexed = YES;
    } secondSchemaTransform:nil];
}

- (void)testMigrationRenamePropertySetOptional {
    [self assertPropertyRenameError:nil firstSchemaTransform:^(__unused RLMObjectSchema *schema, RLMProperty *beforeProperty, __unused RLMProperty *afterProperty) {
        beforeProperty.optional = NO;
    } secondSchemaTransform:nil];
}

// Unsuccessful Property Rename Tests

- (void)testMigrationRenamePropertySetRequired {
    [self assertPropertyRenameError:@"Migration is required due to the following errors:\n- Nullability for property 'stringCol' has been changed from true to false."
               firstSchemaTransform:^(__unused RLMObjectSchema *schema, __unused RLMProperty *beforeProperty, RLMProperty *afterProperty) {
        afterProperty.optional = NO;
    } secondSchemaTransform:nil];
}

- (void)testMigrationRenamePropertyTypeMismatch {
    [self assertPropertyRenameError:@"Old property 'before_stringCol' of type 'int' cannot be renamed to property 'stringCol' of type 'string'."
               firstSchemaTransform:^(__unused RLMObjectSchema *schema, RLMProperty *beforeProperty, __unused RLMProperty *afterProperty) {
        beforeProperty.type = RLMPropertyTypeInt;
    } secondSchemaTransform:nil];
}

- (void)testMigrationRenamePropertyObjectTypeMismatch {
    RLMObjectSchema *objectSchema = [RLMObjectSchema schemaForObjectClass:MigrationLinkObject.class];
    RLMObjectSchema *migrationObjectSchema = [RLMObjectSchema schemaForObjectClass:MigrationObject.class];
    NSArray *afterProperties = objectSchema.properties;
    NSMutableArray *beforeProperties = [NSMutableArray arrayWithCapacity:2];
    for (RLMProperty *property in afterProperties) {
        RLMProperty *beforeProperty = [property copyWithNewName:[NSString stringWithFormat:@"before_%@", property.name]];
        beforeProperty.objectClassName = MigrationLinkObject.className;
        [beforeProperties addObject:beforeProperty];
    }
    objectSchema.properties = beforeProperties;

    [self createTestRealmWithSchema:@[objectSchema] block:^(__unused RLMRealm *realm) {
        // No need to create an object
    }];

    objectSchema.properties = afterProperties;

    [self assertPropertyRenameError:@"Old property 'before_object' of type '<MigrationLinkObject>' cannot be renamed to property 'object' of type '<MigrationObject>'."
                      objectSchemas:@[objectSchema, migrationObjectSchema] className:MigrationLinkObject.className oldName:[beforeProperties[0] name] newName:[afterProperties[0] name]];

    [self assertPropertyRenameError:@"Old property 'before_array' of type 'array<MigrationLinkObject>' cannot be renamed to property 'array' of type 'array<MigrationObject>'."
                      objectSchemas:@[objectSchema, migrationObjectSchema] className:MigrationLinkObject.className oldName:[beforeProperties[1] name] newName:[afterProperties[1] name]];
}

- (void)testMigrationRenameMissingPropertiesAndClasses {
    RLMObjectSchema *objectSchema = [RLMObjectSchema schemaForObjectClass:StringObject.class];

    [self createTestRealmWithSchema:@[objectSchema] block:^(__unused RLMRealm *realm) {
        // No need to create an object
    }];

    // Missing Old Property
    [self assertPropertyRenameError:@"Old property 'nonExistentProperty1' is missing from the Realm file so it cannot be renamed to 'nonExistentProperty2'."
                      objectSchemas:@[objectSchema] className:StringObject.className oldName:@"nonExistentProperty1" newName:@"nonExistentProperty2"];

    // Missing New Property
    [self assertPropertyRenameError:@"Renamed property 'nonExistentProperty' is not in the latest model."
                      objectSchemas:@[objectSchema] className:StringObject.className oldName:@"stringCol" newName:@"nonExistentProperty"];

    // Removed Class
    [self assertPropertyRenameError:@"Cannot rename properties on type 'StringObject' because it is missing from the specified schema."
                      objectSchemas:@[[RLMObjectSchema schemaForObjectClass:IntObject.class]] className:StringObject.className oldName:@"stringCol" newName:@"stringCol2"];

    // Without Removing Old Property
    RLMProperty *secondProperty = [objectSchema.properties.firstObject copyWithNewName:@"stringCol2"];
    objectSchema.properties = [objectSchema.properties arrayByAddingObject:secondProperty];
    [self assertPropertyRenameError:@"Old property 'stringCol' cannot be renamed to 'stringCol2' because the old property is still present in the specified schema."
                      objectSchemas:@[objectSchema] className:StringObject.className oldName:@"stringCol" newName:@"stringCol2"];
}

@end
