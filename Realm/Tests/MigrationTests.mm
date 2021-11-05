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
#import "RLMRealmUtil.hpp"

#import <realm/object-store/object_store.hpp>
#import <realm/object-store/shared_realm.hpp>
#import <realm/table.hpp>
#import <realm/version.hpp>

#import <objc/runtime.h>

using namespace realm;

static void RLMAssertRealmSchemaMatchesTable(id self, RLMRealm *realm) {
    for (RLMObjectSchema *objectSchema in realm.schema.objectSchema) {
        auto& info = realm->_info[objectSchema.className];
        TableRef table = ObjectStore::table_for_object_type(realm.group, objectSchema.objectStoreName);
        for (RLMProperty *property in objectSchema.properties) {
            auto column = info.tableColumn(property);
            XCTAssertEqual(column, table->get_column_key(RLMStringDataWithNSString(property.columnName)));
            if (property.isPrimary)
                XCTAssertTrue(property.indexed);
            XCTAssertEqual(property.indexed, table->has_search_index(column));
        }
    }
    static_cast<void>(self);
}

@interface MigrationTestObject : RLMObject
@property int intCol;
@property NSString *stringCol;
@end
RLM_COLLECTION_TYPE(MigrationTestObject);

@implementation MigrationTestObject
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

@interface ThreeFieldMigrationTestObject : RLMObject
@property int col1;
@property int col2;
@property int col3;
@end

@implementation ThreeFieldMigrationTestObject
@end

@interface MigrationTwoStringObject : RLMObject
@property NSString *col1;
@property NSString *col2;
@end

@implementation MigrationTwoStringObject
@end

@interface MigrationLinkObject : RLMObject
@property MigrationTestObject *object;
@property RLMArray<MigrationTestObject> *array;
@property RLMSet<MigrationTestObject> *set;
@property RLMDictionary<NSString *, MigrationTestObject *><RLMString, MigrationTestObject> *dictionary;
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
    config.encryptionKey = RLMRealmConfiguration.rawDefaultConfiguration.encryptionKey;
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
        RLMRealmConfiguration *config = self.config;
        config.customSchema = [self schemaWithObjects:objectSchema];

        RLMRealm *realm = [RLMRealm realmWithConfiguration:config error:nil];
        [realm beginWriteTransaction];
        block(realm);
        [realm commitWriteTransaction];
    }
}

- (RLMRealm *)migrateTestRealmWithBlock:(RLMMigrationBlock)block NS_RETURNS_RETAINED {
    @autoreleasepool {
        RLMRealmConfiguration *config = self.config;
        config.schemaVersion = 1;
        config.migrationBlock = block;
        XCTAssertTrue([RLMRealm performMigrationForConfiguration:config error:nil]);

        RLMRealm *realm = [RLMRealm realmWithConfiguration:config error:nil];
        RLMAssertRealmSchemaMatchesTable(self, realm);
        return realm;
    }
}

- (void)failToMigrateTestRealmWithBlock:(RLMMigrationBlock)block {
    @autoreleasepool {
        RLMRealmConfiguration *config = self.config;
        config.schemaVersion = 1;
        config.migrationBlock = block;
        XCTAssertFalse([RLMRealm performMigrationForConfiguration:config error:nil]);
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
    RLMRealmConfiguration *config = self.config;
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
    RLMRealmConfiguration *configuration = self.config;
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
    NSError *error;
    [RLMRealm performMigrationForConfiguration:config error:&error];
    XCTAssertTrue([error.localizedDescription rangeOfString:errorMessage].location != NSNotFound,
                  @"\"%@\" should contain \"%@\"", error.localizedDescription, errorMessage);
}

- (void)assertPropertyRenameError:(NSString *)errorMessage
             firstSchemaTransform:(void (^)(RLMObjectSchema *, RLMProperty *, RLMProperty *))transform1
            secondSchemaTransform:(void (^)(RLMObjectSchema *, RLMProperty *, RLMProperty *))transform2 {
    RLMObjectSchema *schema = [RLMObjectSchema schemaForObjectClass:StringObject.class];
    RLMProperty *afterProperty = schema.properties.firstObject;
    RLMProperty *beforeProperty = [afterProperty copyWithNewName:@"before_stringCol"];
    schema.properties = @[beforeProperty];
    if (transform1) {
        transform1(schema, beforeProperty, afterProperty);
    }

    [self createTestRealmWithSchema:@[schema] block:^(RLMRealm *realm) {
        if (errorMessage == nil) {
            [StringObject createInRealm:realm withValue:@[@"0"]];
        }
    }];

    schema.properties = @[afterProperty];
    if (transform2) {
        transform2(schema, beforeProperty, afterProperty);
    }

    auto config = [self renameConfigurationWithObjectSchemas:@[schema]
                                                   className:StringObject.className
                                                     oldName:beforeProperty.name
                                                     newName:afterProperty.name];

    if (errorMessage) {
        NSError *error;
        [RLMRealm performMigrationForConfiguration:config error:&error];
        XCTAssertEqualObjects([error localizedDescription], errorMessage);
    } else {
        XCTAssertTrue([RLMRealm performMigrationForConfiguration:config error:nil]);
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
    config.encryptionKey = nil;
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
    XCTAssertEqual(10U, [RLMRealm schemaVersionAtURL:config.fileURL encryptionKey:config.encryptionKey error:nil]);

    config.schemaVersion = 5;
    RLMAssertThrowsWithReasonMatching([RLMRealm realmWithConfiguration:config error:nil],
                                      @"Provided schema version 5 is less than last set version 10.");
}

- (void)testDifferentSchemaVersionsAtDifferentPaths {
    RLMRealmConfiguration *config = [RLMRealmConfiguration defaultConfiguration];
    config.schemaVersion = 10;
    @autoreleasepool { [RLMRealm realmWithConfiguration:config error:nil]; }
    XCTAssertEqual(10U, [RLMRealm schemaVersionAtURL:config.fileURL encryptionKey:config.encryptionKey error:nil]);

    RLMRealmConfiguration *config2 = [RLMRealmConfiguration defaultConfiguration];
    config2.schemaVersion = 5;
    config2.fileURL = RLMTestRealmURL();
    @autoreleasepool { [RLMRealm realmWithConfiguration:config2 error:nil]; }
    XCTAssertEqual(5U, [RLMRealm schemaVersionAtURL:config2.fileURL encryptionKey:config.encryptionKey error:nil]);

    // Should not have been changed
    XCTAssertEqual(10U, [RLMRealm schemaVersionAtURL:config.fileURL encryptionKey:config.encryptionKey error:nil]);
}

#pragma mark - Migration Requirements

- (void)testAddingClassDoesNotRequireMigration {
    RLMRealmConfiguration *config = self.config;
    config.objectClasses = @[MigrationTestObject.class];
    @autoreleasepool { [RLMRealm realmWithConfiguration:config error:nil]; }

    config.objectClasses = @[MigrationTestObject.class, ThreeFieldMigrationTestObject.class];
    XCTAssertNoThrow([RLMRealm realmWithConfiguration:config error:nil]);
}

- (void)testRemovingClassDoesNotRequireMigration {
    RLMRealmConfiguration *config = self.config;
    config.objectClasses = @[MigrationTestObject.class, ThreeFieldMigrationTestObject.class];
    @autoreleasepool { [RLMRealm realmWithConfiguration:config error:nil]; }

    config.objectClasses = @[MigrationTestObject.class];
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
    NSArray *linkTargets = @[[RLMObjectSchema schemaForObjectClass:MigrationTestObject.class],
                             [RLMObjectSchema schemaForObjectClass:MigrationTwoStringObject.class]];
    RLMObjectSchema *from = [RLMObjectSchema schemaForObjectClass:MigrationLinkObject.class];

    RLMObjectSchema *to = [RLMObjectSchema schemaForObjectClass:MigrationLinkObject.class];
    [to.properties[0] setObjectClassName:@"MigrationTwoStringObject"];

    [self assertMigrationRequiredForChangeFrom:[linkTargets arrayByAddingObject:from]
                                            to:[linkTargets arrayByAddingObject:to]];
}

- (void)testChangingLinkListTargetRequiresMigration {
    NSArray *linkTargets = @[[RLMObjectSchema schemaForObjectClass:MigrationTestObject.class],
                             [RLMObjectSchema schemaForObjectClass:MigrationTwoStringObject.class]];
    RLMObjectSchema *from = [RLMObjectSchema schemaForObjectClass:MigrationLinkObject.class];

    RLMObjectSchema *to = [RLMObjectSchema schemaForObjectClass:MigrationLinkObject.class];
    [to.properties[1] setObjectClassName:@"MigrationTwoStringObject"];

    [self assertMigrationRequiredForChangeFrom:[linkTargets arrayByAddingObject:from]
                                            to:[linkTargets arrayByAddingObject:to]];
}

- (void)testChangingPropertyTypesRequiresMigration {
    RLMObjectSchema *from = [RLMObjectSchema schemaForObjectClass:MigrationTestObject.class];

    RLMObjectSchema *to = [RLMObjectSchema schemaForObjectClass:MigrationTestObject.class];
    to.objectClass = RLMObject.class;
    RLMProperty *prop = to.properties[0];
    RLMProperty *strProp = to.properties[1];
    prop.type = strProp.type;

    [self assertMigrationRequiredForChangeFrom:@[from] to:@[to]];
}

- (void)testDeleteRealmIfMigrationNeededWithSetCustomSchema {
    RLMObjectSchema *from = [RLMObjectSchema schemaForObjectClass:MigrationTwoStringObject.class];
    from.properties = [from.properties subarrayWithRange:{0, 1}];

    RLMObjectSchema *to = [RLMObjectSchema schemaForObjectClass:MigrationTwoStringObject.class];

    RLMRealmConfiguration *config = self.config;
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
        RLMObjectSchema *objectSchema = [RLMObjectSchema schemaForObjectClass:MigrationTestObject.class];
        configuration.customSchema = [self schemaWithObjects:@[objectSchema]];

        @autoreleasepool {
            [[NSFileManager defaultManager] removeItemAtURL:configuration.fileURL error:nil];
            RLMRealm *realm = [RLMRealm realmWithConfiguration:configuration error:nil];
            [realm transactionWithBlock:^{
                [realm addObject:[MigrationTestObject new]];
            }];
        }

        // Change string to int, requiring a migration
        objectSchema.objectClass = RLMObject.class;
        RLMProperty *stringCol = objectSchema.properties[1];
        stringCol.type = RLMPropertyTypeInt;
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
    auto& info = realm->_info[@"StringObject"];
    XCTAssertTrue(info.table()->has_search_index(info.tableColumn(objectSchema.properties[0].name)));
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

    // -createObject:withValue: takes values in the order the properties appear in the array
    [realm createObject:CircleObject.className withValue:@[NSNull.null, @"data"]];
    RLMAssertThrowsWithReasonMatching(([realm createObject:CircleObject.className withValue:@[@"data", NSNull.null]]),
                                      @"Invalid value 'data' to initialize object of type 'CircleObject'");
    [realm commitWriteTransaction];

    // accessors should work
    CircleObject *obj = [[CircleObject allObjectsInRealm:realm] firstObject];
    XCTAssertEqualObjects(@"data", obj.data);
    XCTAssertNil(obj.next);
    [realm beginWriteTransaction];
    XCTAssertNoThrow(obj.data = @"new data");
    XCTAssertNoThrow(obj.next = obj);
    [realm commitWriteTransaction];

    // open the default Realm and make sure accessors with alternate ordering work
    CircleObject *defaultObj = [[CircleObject allObjects] firstObject];
    XCTAssertEqualObjects(defaultObj.data, @"data");

    RLMAssertRealmSchemaMatchesTable(self, realm);

    // re-check that things still work for the realm with the swapped order
    XCTAssertEqualObjects(obj.data, @"new data");

    [realm beginWriteTransaction];
    [realm createObject:CircleObject.className withValue:@[NSNull.null, @"data"]];
    RLMAssertThrowsWithReasonMatching(([realm createObject:CircleObject.className withValue:@[@"data", NSNull.null]]),
                                      @"Invalid value 'data' to initialize object of type 'CircleObject'");
    [realm commitWriteTransaction];
}

#pragma mark - Migration block invocatios

- (void)testMigrationBlockNotCalledForIntialRealmCreation {
    RLMRealmConfiguration *config = self.config;
    config.migrationBlock = ^(__unused RLMMigration *migration, __unused uint64_t oldSchemaVersion) {
        XCTFail(@"Migration block should not have been called");
    };
    XCTAssertNoThrow([RLMRealm realmWithConfiguration:config error:nil]);
}

- (void)testMigrationBlockNotCalledWhenSchemaVersionIsUnchanged {
    RLMRealmConfiguration *config = self.config;
    config.schemaVersion = 1;
    @autoreleasepool { XCTAssertNoThrow([RLMRealm realmWithConfiguration:config error:nil]); }

    config.migrationBlock = ^(__unused RLMMigration *migration, __unused uint64_t oldSchemaVersion) {
        XCTFail(@"Migration block should not have been called");
    };
    @autoreleasepool { XCTAssertNoThrow([RLMRealm realmWithConfiguration:config error:nil]); }
    @autoreleasepool { XCTAssertTrue([RLMRealm performMigrationForConfiguration:config error:nil]); }
}

- (void)testMigrationBlockCalledWhenSchemaVersionHasChanged {
    RLMRealmConfiguration *config = self.config;
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
    @autoreleasepool { XCTAssertTrue([RLMRealm performMigrationForConfiguration:config error:nil]); }
    XCTAssertTrue(migrationCalled);
}

#pragma mark - Async Migration

- (void)testAsyncMigration {
    RLMRealmConfiguration *c = self.config;
    c.schemaVersion = 1;
    @autoreleasepool { XCTAssertNoThrow([RLMRealm realmWithConfiguration:c error:nil]); }
    XCTAssertNil(RLMGetAnyCachedRealmForPath(c.pathOnDisk.UTF8String));
    XCTestExpectation *ex = [self expectationWithDescription:@"async-migration"];
    __block bool migrationCalled = false;
    c.schemaVersion = 2;
    c.migrationBlock = ^(__unused RLMMigration *migration, __unused uint64_t oldSchemaVersion) {
        migrationCalled = true;
    };
    [RLMRealm asyncOpenWithConfiguration:c
                           callbackQueue:dispatch_get_main_queue()
                                 callback:^(RLMRealm * _Nullable realm, NSError * _Nullable error) {
        XCTAssertTrue(migrationCalled);
        XCTAssertNil(error);
        XCTAssertNotNil(realm);
        [ex fulfill];
    }];
    XCTAssertFalse(migrationCalled);
    XCTAssertNil(RLMGetAnyCachedRealmForPath(c.pathOnDisk.UTF8String));
    [self waitForExpectationsWithTimeout:1 handler:nil];
    XCTAssertTrue(migrationCalled);
    XCTAssertNil(RLMGetAnyCachedRealmForPath(c.pathOnDisk.UTF8String));
}

#pragma mark - Migration Correctness

- (void)testRemovingSubclass {
    RLMProperty *prop = [[RLMProperty alloc] initWithName:@"id"
                                                     type:RLMPropertyTypeInt
                                          objectClassName:nil
                                   linkOriginPropertyName:nil
                                                  indexed:NO
                                                 optional:NO];
    RLMObjectSchema *objectSchema = [[RLMObjectSchema alloc] initWithClassName:@"DeletedClass" objectClass:RLMObject.class properties:@[prop]];
    [self createTestRealmWithSchema:@[objectSchema] block:^(RLMRealm *realm) {
        [realm createObject:@"DeletedClass" withValue:@[@0]];
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
    RLMObjectSchema *objectSchema = [RLMObjectSchema schemaForObjectClass:MigrationTestObject.class];
    objectSchema.properties = @[objectSchema.properties[0]];
    [self createTestRealmWithSchema:@[objectSchema] block:^(RLMRealm *realm) {
        [realm createObject:MigrationTestObject.className withValue:@[@1]];
        [realm createObject:MigrationTestObject.className withValue:@[@2]];
    }];

    // apply migration
    RLMRealm *realm = [self migrateTestRealmWithBlock:^(RLMMigration *migration, uint64_t oldSchemaVersion) {
        XCTAssertEqual(oldSchemaVersion, 0U, @"Initial schema version should be 0");
        [migration enumerateObjects:MigrationTestObject.className
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
    MigrationTestObject *mig1 = [MigrationTestObject allObjectsInRealm:realm][1];
    XCTAssertEqual(mig1.intCol, 2, @"Int column should have value 2");
    XCTAssertEqualObjects(mig1.stringCol, @"2", @"String column should be populated");
}

- (void)testAddingPropertyAtBeginningPreservesData {
    // create schema to migrate from with the second and third columns from the final data
    RLMObjectSchema *objectSchema = [RLMObjectSchema schemaForObjectClass:ThreeFieldMigrationTestObject.class];
    objectSchema.properties = @[objectSchema.properties[1], objectSchema.properties[2]];

    [self createTestRealmWithSchema:@[objectSchema] block:^(RLMRealm *realm) {
        [realm createObject:ThreeFieldMigrationTestObject.className withValue:@[@1, @2]];
    }];

    RLMRealm *realm = [self migrateTestRealmWithBlock:^(RLMMigration *migration, uint64_t) {
        [migration enumerateObjects:ThreeFieldMigrationTestObject.className
                              block:^(RLMObject *oldObject, RLMObject *newObject) {
            XCTAssertThrows(oldObject[@"col1"]);
            XCTAssertEqualObjects(oldObject[@"col2"], newObject[@"col2"]);
            XCTAssertEqualObjects(oldObject[@"col3"], newObject[@"col3"]);
        }];
    }];

    // verify migration
    ThreeFieldMigrationTestObject *mig = [ThreeFieldMigrationTestObject allObjectsInRealm:realm][0];
    XCTAssertEqual(0, mig.col1);
    XCTAssertEqual(1, mig.col2);
    XCTAssertEqual(2, mig.col3);
}

- (void)testRemoveProperty {
    // create schema with an extra column
    RLMObjectSchema *objectSchema = [RLMObjectSchema schemaForObjectClass:MigrationTestObject.class];
    RLMProperty *thirdProperty = [[RLMProperty alloc] initWithName:@"deletedCol" type:RLMPropertyTypeBool objectClassName:nil linkOriginPropertyName:nil indexed:NO optional:NO];
    objectSchema.properties = [objectSchema.properties arrayByAddingObject:thirdProperty];

    // create realm with old schema and populate
    [self createTestRealmWithSchema:@[objectSchema] block:^(RLMRealm *realm) {
        [realm createObject:MigrationTestObject.className withValue:@[@1, @"1", @YES]];
        [realm createObject:MigrationTestObject.className withValue:@[@2, @"2", @NO]];
    }];

    // apply migration
    RLMRealm *realm = [self migrateTestRealmWithBlock:^(RLMMigration *migration, uint64_t oldSchemaVersion) {
        XCTAssertEqual(oldSchemaVersion, 0U, @"Initial schema version should be 0");
        [migration enumerateObjects:MigrationTestObject.className
                                       block:^(RLMObject *oldObject, RLMObject *newObject) {
            XCTAssertNoThrow(oldObject[@"deletedCol"], @"Deleted column should be accessible on old object.");
            XCTAssertThrows(newObject[@"deletedCol"], @"Deleted column should not be accessible on new object.");

            XCTAssertEqualObjects(newObject[@"intCol"], oldObject[@"intCol"]);
            XCTAssertEqualObjects(newObject[@"stringCol"], oldObject[@"stringCol"]);
        }];
    }];

    // verify migration
    MigrationTestObject *mig1 = [MigrationTestObject allObjectsInRealm:realm][1];
    XCTAssertThrows(mig1[@"deletedCol"], @"Deleted column should no longer be accessible.");
}

- (void)testRemoveAndAddProperty {
    // create schema to migrate from with single string column
    RLMObjectSchema *objectSchema = [RLMObjectSchema schemaForObjectClass:MigrationTestObject.class];
    RLMProperty *oldInt = [[RLMProperty alloc] initWithName:@"oldIntCol" type:RLMPropertyTypeInt objectClassName:nil linkOriginPropertyName:nil indexed:NO optional:NO];
    objectSchema.properties = @[oldInt, objectSchema.properties[1]];

    // create realm with old schema and populate
    [self createTestRealmWithSchema:@[objectSchema] block:^(RLMRealm *realm) {
        [realm createObject:MigrationTestObject.className withValue:@[@1, @"1"]];
        [realm createObject:MigrationTestObject.className withValue:@[@1, @"2"]];
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
        [migration enumerateObjects:MigrationTestObject.className block:migrateObjectBlock];
    }];

    // verify migration
    MigrationTestObject *mig1 = [MigrationTestObject allObjectsInRealm:realm][1];
    XCTAssertThrows(mig1[@"oldIntCol"], @"Deleted column should no longer be accessible.");
}

- (void)testChangePropertyType {
    // make string an int
    RLMObjectSchema *objectSchema = [RLMObjectSchema schemaForObjectClass:MigrationTestObject.class];
    objectSchema.objectClass = RLMObject.class;
    RLMProperty *stringCol = objectSchema.properties[1];
    stringCol.type = RLMPropertyTypeInt;
    stringCol.optional = NO;

    // create realm with old schema and populate
    [self createTestRealmWithSchema:@[objectSchema] block:^(RLMRealm *realm) {
        [realm createObject:MigrationTestObject.className withValue:@[@1, @1]];
        [realm createObject:MigrationTestObject.className withValue:@[@2, @2]];
    }];

    // apply migration
    RLMRealm *realm = [self migrateTestRealmWithBlock:^(RLMMigration *migration, uint64_t oldSchemaVersion) {
        XCTAssertEqual(oldSchemaVersion, 0U, @"Initial schema version should be 0");
        [migration enumerateObjects:MigrationTestObject.className
                              block:^(RLMObject *oldObject, RLMObject *newObject) {
            XCTAssertEqualObjects(newObject[@"intCol"], oldObject[@"intCol"]);
            NSNumber *intObj = oldObject[@"stringCol"];
            XCTAssert([intObj isKindOfClass:NSNumber.class], @"Old stringCol should be int");
            newObject[@"stringCol"] = intObj.stringValue;
        }];
    }];

    // verify migration
    MigrationTestObject *mig1 = [MigrationTestObject allObjectsInRealm:realm][1];
    XCTAssertEqualObjects(mig1[@"stringCol"], @"2", @"stringCol should be string after migration.");
}

- (void)testChangeObjectLinkType {
    // create realm with old schema and populate
    [self createTestRealmWithSchema:RLMSchema.sharedSchema.objectSchema block:^(RLMRealm *realm) {
        id obj = [realm createObject:MigrationTestObject.className withValue:@[@1, @"1"]];
        [realm createObject:MigrationLinkObject.className withValue:@[obj, @[obj], @[obj]]];
    }];

    // Make the object link property link to a different class
    RLMRealmConfiguration *config = self.config;
    RLMObjectSchema *objectSchema = [RLMObjectSchema schemaForObjectClass:MigrationLinkObject.class];
    [objectSchema.properties[0] setObjectClassName:MigrationLinkObject.className];
    config.customSchema = [self schemaWithObjects:@[objectSchema, [RLMObjectSchema schemaForObjectClass:MigrationTestObject.class]]];

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
                                           XCTAssertEqual(1U, [oldObject[@"set"] count]);
                                           XCTAssertEqual(1U, [newObject[@"set"] count]);
                                       }];
    };
    RLMRealm *realm = [RLMRealm realmWithConfiguration:config error:nil];
    RLMAssertRealmSchemaMatchesTable(self, realm);
}

- (void)testChangeArrayLinkType {
    // create realm with old schema and populate
    RLMRealmConfiguration *config = [self config];
    [self createTestRealmWithSchema:RLMSchema.sharedSchema.objectSchema block:^(RLMRealm *realm) {
        id obj = [realm createObject:MigrationTestObject.className withValue:@[@1, @"1"]];
        [realm createObject:MigrationLinkObject.className withValue:@[obj, @[obj]]];
    }];

    // Make the array linklist property link to a different class
    RLMObjectSchema *objectSchema = [RLMObjectSchema schemaForObjectClass:MigrationLinkObject.class];
    [objectSchema.properties[1] setObjectClassName:MigrationLinkObject.className];
    config.customSchema = [self schemaWithObjects:@[objectSchema, [RLMObjectSchema schemaForObjectClass:MigrationTestObject.class]]];

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

- (void)testChangeSetLinkType {
    // create realm with old schema and populate
    RLMRealmConfiguration *config = [self config];
    [self createTestRealmWithSchema:RLMSchema.sharedSchema.objectSchema block:^(RLMRealm *realm) {
        id obj = [realm createObject:MigrationTestObject.className withValue:@[@1, @"1"]];
        [realm createObject:MigrationLinkObject.className withValue:@[obj, @[obj], @[obj]]];
    }];

    // Make the set linklist property link to a different class
    RLMObjectSchema *objectSchema = [RLMObjectSchema schemaForObjectClass:MigrationLinkObject.class];
    [objectSchema.properties[2] setObjectClassName:MigrationLinkObject.className];
    config.customSchema = [self schemaWithObjects:@[objectSchema, [RLMObjectSchema schemaForObjectClass:MigrationTestObject.class]]];

    // Apply migration
    config.schemaVersion = 1;
    config.migrationBlock = ^(RLMMigration *migration, uint64_t oldSchemaVersion) {
        XCTAssertEqual(oldSchemaVersion, 0U, @"Initial schema version should be 0");
        [migration enumerateObjects:MigrationLinkObject.className
                                       block:^(RLMObject *oldObject, RLMObject *newObject) {
                                           XCTAssertNotNil(oldObject[@"object"]);
                                           XCTAssertNotNil(newObject[@"object"]);

                                           XCTAssertEqual(1U, [oldObject[@"set"] count]);
                                           XCTAssertEqual(0U, [newObject[@"set"] count]);
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
    [self createTestRealmWithClasses:@[StringObject.class, ArrayPropertyObject.class, SetPropertyObject.class, IntObject.class]
                               block:^(RLMRealm *realm) {
        [StringObject createInRealm:realm withValue:@[@"string"]];
        [ArrayPropertyObject createInRealm:realm withValue:@[@"array", @[@[@"string"]], @[@[@1]]]];
        [SetPropertyObject createInRealm:realm withValue:@[@"set", @[@[@"string"]], @[@[@1]]]];
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

        [migration enumerateObjects:SetPropertyObject.className block:^(RLMObject *oldObject, RLMObject *newObject) {
            XCTAssertEqual(RLMDynamicObject.class, newObject.class);
            XCTAssertEqual(RLMDynamicObject.class, oldObject.class);
            XCTAssertEqual(RLMDynamicObject.class, [[oldObject[@"set"] allObjects][0] class]);
            XCTAssertEqual(RLMDynamicObject.class, [[newObject[@"set"] allObjects][0] class]);
        }];
    }];

    XCTAssertEqualObjects(@"otherString", [[StringObject allObjectsInRealm:realm].firstObject stringCol]);
}

- (void)testEnumerateObjectsAfterDeleteObjects {
    [self createTestRealmWithClasses:@[StringObject.class, IntObject.class, BoolObject.class] block:^(RLMRealm *realm) {
        [StringObject createInRealm:realm withValue:@[@"1"]];
        [StringObject createInRealm:realm withValue:@[@"2"]];
        [StringObject createInRealm:realm withValue:@[@"3"]];
        [IntObject createInRealm:realm withValue:@[@1]];
        [IntObject createInRealm:realm withValue:@[@2]];
        [IntObject createInRealm:realm withValue:@[@3]];
        [BoolObject createInRealm:realm withValue:@[@YES]];
        [BoolObject createInRealm:realm withValue:@[@NO]];
        [BoolObject createInRealm:realm withValue:@[@YES]];
    }];

    [self migrateTestRealmWithBlock:^(RLMMigration *migration, uint64_t) {
        __block NSInteger count = 0;
        [migration enumerateObjects:StringObject.className block:^(RLMObject *oldObject, RLMObject *newObject) {
            XCTAssertEqualObjects(oldObject[@"stringCol"], newObject[@"stringCol"]);
            if ([oldObject[@"stringCol"] isEqualToString:@"2"]) {
                [migration deleteObject:newObject];
            }
        }];
        [migration enumerateObjects:StringObject.className block:^(RLMObject *oldObject, RLMObject *newObject) {
            XCTAssertEqualObjects(oldObject[@"stringCol"], newObject[@"stringCol"]);
            count++;
        }];
        XCTAssertEqual(count, 2);

        count = 0;
        [migration enumerateObjects:IntObject.className block:^(RLMObject *oldObject, RLMObject *newObject) {
            XCTAssertEqualObjects(oldObject[@"intCol"], newObject[@"intCol"]);
            if ([oldObject[@"intCol"] isEqualToNumber:@1]) {
                [migration deleteObject:newObject];
            }
        }];
        [migration enumerateObjects:IntObject.className block:^(RLMObject *oldObject, RLMObject *newObject) {
            XCTAssertEqualObjects(oldObject[@"intCol"], newObject[@"intCol"]);
            count++;
        }];
        XCTAssertEqual(count, 2);

        [migration enumerateObjects:BoolObject.className block:^(RLMObject *oldObject, RLMObject *newObject) {
            XCTAssertEqualObjects(oldObject[@"boolCol"], newObject[@"boolCol"]);
            [migration deleteObject:newObject];
        }];
        [migration enumerateObjects:BoolObject.className block:^(__unused RLMObject *oldObject, __unused RLMObject *newObject) {
            XCTFail(@"This line should not executed since all objects have been deleted.");
        }];
    }];
}

- (void)testEnumerateObjectsAfterDeleteInsertObjects {
    [self createTestRealmWithClasses:@[StringObject.class, IntObject.class, BoolObject.class] block:^(RLMRealm *realm) {
        [StringObject createInRealm:realm withValue:@[@"1"]];
        [StringObject createInRealm:realm withValue:@[@"2"]];
        [StringObject createInRealm:realm withValue:@[@"3"]];
        [IntObject createInRealm:realm withValue:@[@1]];
        [IntObject createInRealm:realm withValue:@[@2]];
        [IntObject createInRealm:realm withValue:@[@3]];
        [BoolObject createInRealm:realm withValue:@[@YES]];
        [BoolObject createInRealm:realm withValue:@[@NO]];
        [BoolObject createInRealm:realm withValue:@[@YES]];
    }];

    [self migrateTestRealmWithBlock:^(RLMMigration *migration, uint64_t) {
        __block NSInteger count = 0;
        [migration enumerateObjects:StringObject.className block:^(RLMObject *oldObject, RLMObject *newObject) {
            XCTAssertEqualObjects(oldObject[@"stringCol"], newObject[@"stringCol"]);
            if ([newObject[@"stringCol"] isEqualToString:@"2"]) {
                [migration deleteObject:newObject];
                [migration createObject:StringObject.className withValue:@[@"A"]];
            }
        }];
        [migration enumerateObjects:StringObject.className block:^(RLMObject *oldObject, RLMObject *newObject) {
            XCTAssertEqualObjects(oldObject[@"stringCol"], newObject[@"stringCol"]);
            count++;
        }];
        XCTAssertEqual(count, 2);

        count = 0;
        [migration enumerateObjects:IntObject.className block:^(RLMObject *oldObject, RLMObject *newObject) {
            XCTAssertEqualObjects(oldObject[@"intCol"], newObject[@"intCol"]);
            if ([newObject[@"intCol"] isEqualToNumber:@1]) {
                [migration deleteObject:newObject];
                [migration createObject:IntObject.className withValue:@[@0]];
            }
        }];
        [migration enumerateObjects:IntObject.className block:^(RLMObject *oldObject, RLMObject *newObject) {
            XCTAssertEqualObjects(oldObject[@"intCol"], newObject[@"intCol"]);
            count++;
        }];
        XCTAssertEqual(count, 2);

        [migration enumerateObjects:BoolObject.className block:^(RLMObject *oldObject, RLMObject *newObject) {
            XCTAssertEqualObjects(oldObject[@"boolCol"], newObject[@"boolCol"]);
            [migration deleteObject:newObject];
            [migration createObject:BoolObject.className withValue:@[@NO]];
        }];
        [migration enumerateObjects:BoolObject.className block:^(__unused RLMObject *oldObject, __unused RLMObject *newObject) {
            XCTFail(@"This line should not executed since all objects have been deleted.");
        }];
    }];
}

- (void)testEnumerateObjectTypeRemovedFromSchema {
    [self createTestRealmWithClasses:@[IntObject.class] block:^(RLMRealm *realm) {
        [IntObject createInRealm:realm withValue:@[@1]];
        [IntObject createInRealm:realm withValue:@[@2]];
    }];

    RLMRealmConfiguration *config = self.config;
    config.objectClasses = @[StringObject.class];
    config.schemaVersion = 1;
    __block int enumerateCalls = 0;
    config.migrationBlock = ^(RLMMigration *migration, uint64_t) {
        [migration enumerateObjects:IntObject.className block:^(RLMObject *oldObject, RLMObject *newObject) {
            XCTAssertNotNil(oldObject);
            XCTAssertNil(newObject);
            ++enumerateCalls;
            XCTAssertGreaterThan([oldObject[@"intCol"] intValue], 0);
        }];
    };
    XCTAssertTrue([RLMRealm performMigrationForConfiguration:config error:nil]);
    XCTAssertEqual(enumerateCalls, 2);
}

- (void)testEnumerateObjectsAfterDeleteData {
    [self createTestRealmWithClasses:@[IntObject.class] block:^(RLMRealm *realm) {
        [IntObject createInRealm:realm withValue:@[@1]];
        [IntObject createInRealm:realm withValue:@[@2]];
    }];

    [self migrateTestRealmWithBlock:^(RLMMigration *migration, uint64_t) {
        [migration enumerateObjects:IntObject.className block:^(RLMObject *oldObject, RLMObject *newObject) {
            XCTAssertNotNil(oldObject);
            XCTAssertNotNil(newObject);
        }];
        [migration deleteDataForClassName:IntObject.className];
        [migration enumerateObjects:IntObject.className block:^(RLMObject *, RLMObject *) {
            XCTFail(@"should not have enumerated any objects");
        }];
    }];
}

- (RLMResults *)objectsOfType:(Class)cls {
    auto config = self.config;
    config.schemaVersion = 1;
    RLMRealm *realm = [RLMRealm realmWithConfiguration:config error:nil];
    return [cls allObjectsInRealm:realm];
}

- (void)testDeleteSomeObjectsWithinMigration {
    [self createTestRealmWithClasses:@[IntObject.class] block:^(RLMRealm *realm) {
        [IntObject createInRealm:realm withValue:@[@1]];
        [IntObject createInRealm:realm withValue:@[@2]];
        [IntObject createInRealm:realm withValue:@[@3]];
    }];

    [self migrateTestRealmWithBlock:^(RLMMigration *migration, uint64_t) {
        [migration enumerateObjects:IntObject.className block:^(RLMObject *, RLMObject *newObject) {
            if ([newObject[@"intCol"] intValue] != 2) {
                [migration deleteObject:newObject];
            }
        }];
    }];

    XCTAssertEqualObjects([[self objectsOfType:IntObject.class] valueForKey:@"intCol"], (@[@2]));
}

- (void)testDeleteObjectsWithinSeparateEnumerations {
    [self createTestRealmWithClasses:@[IntObject.class] block:^(RLMRealm *realm) {
        [IntObject createInRealm:realm withValue:@[@1]];
        [IntObject createInRealm:realm withValue:@[@2]];
        [IntObject createInRealm:realm withValue:@[@3]];
    }];

    [self migrateTestRealmWithBlock:^(RLMMigration *migration, uint64_t) {
        [migration enumerateObjects:IntObject.className block:^(RLMObject *, RLMObject *newObject) {
            if ([newObject[@"intCol"] intValue] == 1) {
                [migration deleteObject:newObject];
            }
        }];
        [migration enumerateObjects:IntObject.className block:^(RLMObject *, RLMObject *newObject) {
            if ([newObject[@"intCol"] intValue] == 3) {
                [migration deleteObject:newObject];
            }
        }];
    }];

    XCTAssertEqualObjects([[self objectsOfType:IntObject.class] valueForKey:@"intCol"], (@[@2]));
}

- (void)testDeleteAndRecreateObjectsWithinMigration {
    [self createTestRealmWithClasses:@[IntObject.class, PrimaryIntObject.class] block:^(RLMRealm *realm) {
        [IntObject createInRealm:realm withValue:@[@1]];
        [IntObject createInRealm:realm withValue:@[@2]];
        [PrimaryIntObject createInRealm:realm withValue:@[@1]];
        [PrimaryIntObject createInRealm:realm withValue:@[@2]];
    }];

    [self migrateTestRealmWithBlock:^(RLMMigration *migration, uint64_t) {
        [migration enumerateObjects:IntObject.className block:^(RLMObject *, RLMObject *newObject) {
            [migration deleteObject:newObject];
        }];
        [migration enumerateObjects:PrimaryIntObject.className block:^(RLMObject *, RLMObject *newObject) {
            [migration deleteObject:newObject];
        }];

        [migration createObject:IntObject.className withValue:@[@2]];
        [migration createObject:IntObject.className withValue:@[@4]];
        [migration createObject:PrimaryIntObject.className withValue:@[@2]];
        [migration createObject:PrimaryIntObject.className withValue:@[@4]];
    }];

    XCTAssertEqualObjects([[self objectsOfType:IntObject.class] valueForKey:@"intCol"], (@[@2, @4]));
    XCTAssertEqualObjects([[self objectsOfType:PrimaryIntObject.class] valueForKey:@"intCol"], (@[@2, @4]));
}

- (void)testDeleteAllDataAndRecreateObjectsWithinMigration {
    [self createTestRealmWithClasses:@[IntObject.class, PrimaryIntObject.class] block:^(RLMRealm *realm) {
        [IntObject createInRealm:realm withValue:@[@1]];
        [IntObject createInRealm:realm withValue:@[@2]];
        [PrimaryIntObject createInRealm:realm withValue:@[@1]];
        [PrimaryIntObject createInRealm:realm withValue:@[@2]];
    }];

    [self migrateTestRealmWithBlock:^(RLMMigration *migration, uint64_t) {
        [migration deleteDataForClassName:IntObject.className];
        [migration deleteDataForClassName:PrimaryIntObject.className];

        [migration createObject:IntObject.className withValue:@[@2]];
        [migration createObject:IntObject.className withValue:@[@4]];
        [migration createObject:PrimaryIntObject.className withValue:@[@2]];
        [migration createObject:PrimaryIntObject.className withValue:@[@4]];
    }];

    XCTAssertEqualObjects([[self objectsOfType:IntObject.class] valueForKey:@"intCol"], (@[@2, @4]));
    XCTAssertEqualObjects([[self objectsOfType:PrimaryIntObject.class] valueForKey:@"intCol"], (@[@2, @4]));
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

    objectSchema.objectClass = RLMObject.class;
    [objectSchema.properties setValue:@NO forKey:@"optional"];

    RLMRealm *realm;
    @autoreleasepool {
        RLMRealmConfiguration *config = self.config;
        config.customSchema = [self schemaWithObjects:@[ objectSchema ]];
        config.schemaVersion = 1;
        XCTAssertTrue([RLMRealm performMigrationForConfiguration:config error:nil]);

        realm = [RLMRealm realmWithConfiguration:config error:nil];
        RLMAssertRealmSchemaMatchesTable(self, realm);
    }

    RLMResults *allObjects = [AllOptionalTypes allObjectsInRealm:realm];
    XCTAssertEqual(2U, allObjects.count);

    AllOptionalTypes *obj = allObjects[0];
    XCTAssertEqualObjects(@0, obj[@"intObj"]);
    XCTAssertEqualObjects(@0, obj[@"floatObj"]);
    XCTAssertEqualObjects(@0, obj[@"doubleObj"]);
    XCTAssertEqualObjects(@0, obj[@"boolObj"]);
    XCTAssertEqualObjects(@"", obj[@"string"]);
    XCTAssertEqualObjects(NSData.data, obj[@"data"]);
    XCTAssertEqualObjects([NSDate dateWithTimeIntervalSince1970:0], obj[@"date"]);

    obj = allObjects[1];
    XCTAssertEqualObjects(@0, obj[@"intObj"]);
    XCTAssertEqualObjects(@0, obj[@"floatObj"]);
    XCTAssertEqualObjects(@0, obj[@"doubleObj"]);
    XCTAssertEqualObjects(@0, obj[@"boolObj"]);
    XCTAssertEqualObjects(@"", obj[@"string"]);
    XCTAssertEqualObjects(NSData.data, obj[@"data"]);
    XCTAssertEqualObjects([NSDate dateWithTimeIntervalSince1970:0], obj[@"date"]);
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
    RLMRealmConfiguration *config = self.config;
    config.customSchema = [self schemaWithObjects:@[objectSchema]];
    config.schemaVersion = 1;
    config.migrationBlock = ^(RLMMigration *migration, uint64_t) {
        [migration createObject:RequiredPropertiesObject.className withValue:@[@"World", [NSData data], [NSDate date]]];
    };

    XCTAssertTrue([RLMRealm performMigrationForConfiguration:config error:nil]);
    RLMRealm *realm = [RLMRealm realmWithConfiguration:config error:nil];

    RLMResults *allObjects = [RequiredPropertiesObject allObjectsInRealm:realm];
    XCTAssertEqualObjects(@"Hello", [allObjects[0] stringCol]);
    XCTAssertEqualObjects(@"World", [allObjects[1] stringCol]);
}

- (void)testModifyPrimaryKeyInMigration {
    RLMObjectSchema *objectSchema = [RLMObjectSchema schemaForObjectClass:PrimaryStringObject.class];

    objectSchema.primaryKeyProperty = objectSchema[@"intCol"];
    [self createTestRealmWithSchema:@[objectSchema] block:^(RLMRealm *realm) {
        for (int i = 0; i < 10; ++i) {
            [PrimaryStringObject createInRealm:realm withValue:@[@(i).stringValue, @(i + 10)]];
        }
    }];

    auto realm = [self migrateTestRealmWithBlock:^(RLMMigration *migration, uint64_t) {
        [migration enumerateObjects:@"PrimaryStringObject" block:^(RLMObject *oldObject, RLMObject *newObject) {
            newObject[@"stringCol"] = [oldObject[@"intCol"] stringValue];
        }];
    }];

    for (int i = 10; i < 20; ++i) {
        auto obj = [PrimaryStringObject objectInRealm:realm forPrimaryKey:@(i).stringValue];
        XCTAssertNotNil(obj);
        XCTAssertEqual(obj.intCol, i);
    }
}

- (void)testChangeEmptyTableFromTopLevelToEmbedded {
    RLMObjectSchema *fromChild = [RLMObjectSchema schemaForObjectClass:EmbeddedIntObject.class];
    fromChild.isEmbedded = false;
    RLMObjectSchema *fromParent = [RLMObjectSchema schemaForObjectClass:EmbeddedIntParentObject.class];

    RLMObjectSchema *toChild = [RLMObjectSchema schemaForObjectClass:EmbeddedIntObject.class];
    RLMObjectSchema *toParent = [RLMObjectSchema schemaForObjectClass:EmbeddedIntParentObject.class];

    [self assertMigrationRequiredForChangeFrom:@[fromChild, fromParent] to:@[toChild, toParent]];
}

- (void)testChangeEmptyTableFromEmbeddedToTopLevel {
    RLMObjectSchema *fromChild = [RLMObjectSchema schemaForObjectClass:EmbeddedIntObject.class];
    RLMObjectSchema *fromParent = [RLMObjectSchema schemaForObjectClass:EmbeddedIntParentObject.class];

    RLMObjectSchema *toChild = [RLMObjectSchema schemaForObjectClass:EmbeddedIntObject.class];
    toChild.isEmbedded = false;
    RLMObjectSchema *toParent = [RLMObjectSchema schemaForObjectClass:EmbeddedIntParentObject.class];

    [self assertMigrationRequiredForChangeFrom:@[fromChild, fromParent] to:@[toChild, toParent]];
}

- (void)testChangeToEmbeddedRequiresMigration {
    RLMObjectSchema *fromChild = [RLMObjectSchema schemaForObjectClass:EmbeddedIntObject.class];
    fromChild.isEmbedded = false;
    RLMObjectSchema *fromParent = [RLMObjectSchema schemaForObjectClass:EmbeddedIntParentObject.class];

    RLMObjectSchema *toChild = [RLMObjectSchema schemaForObjectClass:EmbeddedIntObject.class];
    RLMObjectSchema *toParent = [RLMObjectSchema schemaForObjectClass:EmbeddedIntParentObject.class];
    
    [self createTestRealmWithSchema:@[fromChild, fromParent] block:^(RLMRealm *realm) {
        EmbeddedIntObject *childObject = (EmbeddedIntObject *)[realm createObject:EmbeddedIntObject.className withValue:@[@42]];
        [realm createObject:EmbeddedIntParentObject.className withValue:@[@42, childObject, NSNull.null]];
        [realm createObject:EmbeddedIntParentObject.className withValue:@[@43, childObject, NSNull.null]];
    }];
    
    [self assertMigrationRequiredForChangeFrom:@[fromChild, fromParent] to:@[toChild, toParent]];
}

- (void)testChangeTableToEmbeddedWithoutBacklinks {
    RLMObjectSchema *fromChild = [RLMObjectSchema schemaForObjectClass:EmbeddedIntObject.class];
    fromChild.isEmbedded = false;
    RLMObjectSchema *toChild = [RLMObjectSchema schemaForObjectClass:EmbeddedIntObject.class];
    [self createTestRealmWithSchema:@[fromChild] block:^(RLMRealm *) {}];
    
    RLMRealmConfiguration *realmConfiguration = self.config;
    realmConfiguration.schemaVersion = 1;
    realmConfiguration.customSchema = [self schemaWithObjects:@[toChild]];
    NSError *error;
    XCTAssertFalse([RLMRealm performMigrationForConfiguration:realmConfiguration error:&error]);
    XCTAssertNotNil(error);
}

- (void)testChangeTableToEmbeddedWithOnlyOneLinkPerObject {
    RLMObjectSchema *fromChild = [RLMObjectSchema schemaForObjectClass:EmbeddedIntObject.class];
    fromChild.isEmbedded = false;
    RLMObjectSchema *fromParent = [RLMObjectSchema schemaForObjectClass:EmbeddedIntParentObject.class];

    [self createTestRealmWithSchema:@[fromChild, fromParent] block:^(RLMRealm *realm) {
        EmbeddedIntObject *childObject1 = (EmbeddedIntObject *)[realm createObject:EmbeddedIntObject.className withValue:@[@42]];
        [realm createObject:EmbeddedIntParentObject.className withValue:@[@42, childObject1, NSNull.null]];
        EmbeddedIntObject *childObject2 = (EmbeddedIntObject *)[realm createObject:EmbeddedIntObject.className withValue:@[@43]];
        [realm createObject:EmbeddedIntParentObject.className withValue:@[@43, childObject2, NSNull.null]];
    }];
    
    __block int parentEnumerateCalls = 0;
    __block int childEnumerateCalls = 0;
    RLMRealm *realm = [self migrateTestRealmWithBlock:^(RLMMigration *migration, uint64_t) {
        [migration enumerateObjects:EmbeddedIntParentObject.className block:^(RLMObject *oldObject, RLMObject *newObject) {
            parentEnumerateCalls++;
            XCTAssertNotNil(oldObject);
            XCTAssertNotNil(newObject);
            NSNumber *newIntProperty = newObject[@"object"][@"intCol"];
            XCTAssertEqual(oldObject[@"object"][@"intCol"], newIntProperty);
            XCTAssert([newIntProperty isEqual: @42] || [newIntProperty isEqual:@43]);
        }];
        [migration enumerateObjects:EmbeddedIntObject.className block:^(RLMObject *oldObject, RLMObject *newObject) {
            childEnumerateCalls++;
            XCTAssertNotNil(oldObject);
            XCTAssertNotNil(newObject);
            NSNumber *newIntProperty = newObject[@"intCol"];
            XCTAssertEqual(oldObject[@"intCol"], newIntProperty);
            XCTAssert([newIntProperty isEqual:@42] || [newIntProperty isEqual:@43]);
        }];
    }];
    XCTAssertNotNil(realm);
    XCTAssertEqual(parentEnumerateCalls, 2);
    XCTAssertEqual(childEnumerateCalls, 2);
    RLMResults<EmbeddedIntParentObject *> *parentObjects = RLMGetObjects(realm, EmbeddedIntParentObject.className, nil);
    XCTAssertEqual(parentObjects.count, 2U);
    EmbeddedIntParentObject *firstParentObject = parentObjects[0];
    XCTAssertEqual(firstParentObject.pk, 42);
    EmbeddedIntObject *firstParentsChild = firstParentObject.object;
    XCTAssertEqual(firstParentsChild.intCol, 42);
    EmbeddedIntParentObject *secondParentObject = parentObjects[1];
    EmbeddedIntObject *secondParentsChild = secondParentObject.object;
    XCTAssertEqual(secondParentsChild.intCol, 43);
}

- (void)testChangeToEmbeddedWithMultipleBacklinksWithoutProperMigration {
    RLMObjectSchema *fromChild = [RLMObjectSchema schemaForObjectClass:EmbeddedIntObject.class];
    fromChild.isEmbedded = false;
    RLMObjectSchema *fromParent = [RLMObjectSchema schemaForObjectClass:EmbeddedIntParentObject.class];

    [self createTestRealmWithSchema:@[fromChild, fromParent] block:^(RLMRealm *realm) {
        EmbeddedIntObject *childObject = (EmbeddedIntObject *)[realm createObject:EmbeddedIntObject.className withValue:@[@42]];
        [realm createObject:EmbeddedIntParentObject.className withValue:@[@42, childObject, NSNull.null]];
        [realm createObject:EmbeddedIntParentObject.className withValue:@[@43, childObject, NSNull.null]];
    }];
    
    __block bool migrationCalled = false;
    [self failToMigrateTestRealmWithBlock:^(RLMMigration *, uint64_t) {
        migrationCalled = true;
    }];
    XCTAssert(migrationCalled);
}

- (void)testConvertToEmbeddedWithMultipleIncomingLinksResolvedInMigrationBlock {
    RLMObjectSchema *fromChild = [RLMObjectSchema schemaForObjectClass:EmbeddedIntObject.class];
    fromChild.isEmbedded = false;
    RLMObjectSchema *fromParent = [RLMObjectSchema schemaForObjectClass:EmbeddedIntParentObject.class];

    [self createTestRealmWithSchema:@[fromChild, fromParent] block:^(RLMRealm *realm) {
        EmbeddedIntObject *childObject = (EmbeddedIntObject *)[realm createObject:EmbeddedIntObject.className withValue:@[@42]];
        [realm createObject:EmbeddedIntParentObject.className withValue:@[@42, childObject, NSNull.null]];
        [realm createObject:EmbeddedIntParentObject.className withValue:@[@43, childObject, NSNull.null]];
    }];
    
    __block int parentEnumerateCalls = 0;
    __block int childEnumerateCalls = 0;
    RLMRealm *realm = [self migrateTestRealmWithBlock:^(RLMMigration *migration, uint64_t) {
        [migration enumerateObjects:EmbeddedIntParentObject.className block:^(RLMObject *oldObject, RLMObject *newObject) {
            parentEnumerateCalls++;
            XCTAssertNotNil(oldObject);
            XCTAssertNotNil(newObject);
            newObject[@"object"] = nil;
        }];
        [migration enumerateObjects:EmbeddedIntObject.className block:^(RLMObject *oldObject, RLMObject *newObject) {
            childEnumerateCalls++;
            XCTAssertNotNil(oldObject);
            XCTAssertNotNil(newObject);
            [migration deleteObject:newObject];
        }];
    }];
    XCTAssertEqual(parentEnumerateCalls, 2);
    XCTAssertEqual(childEnumerateCalls, 1);

    RLMResults<EmbeddedIntParentObject *> *parentObjects = RLMGetObjects(realm, EmbeddedIntParentObject.className, nil);
    XCTAssertEqual(parentObjects.count, 2U);
    EmbeddedIntParentObject *firstParentObject = parentObjects[0];
    XCTAssertNil(firstParentObject.object);
    EmbeddedIntParentObject *secondParentObject = parentObjects[1];
    XCTAssertNil(secondParentObject.object);
    RLMResults<EmbeddedIntObject *> *childObjects = RLMGetObjects(realm, EmbeddedIntObject.className, nil);
    XCTAssertEqual(childObjects.count, 0U);
}

- (void)testConvertToEmbeddedAddingMoreLinks {
    RLMObjectSchema *fromChild = [RLMObjectSchema schemaForObjectClass:EmbeddedIntObject.class];
    fromChild.isEmbedded = false;
    RLMObjectSchema *fromParent = [RLMObjectSchema schemaForObjectClass:EmbeddedIntParentObject.class];

    [self createTestRealmWithSchema:@[fromChild, fromParent] block:^(RLMRealm *realm) {
        EmbeddedIntObject *childObject = (EmbeddedIntObject *)[realm createObject:EmbeddedIntObject.className withValue:@[@42]];
        [realm createObject:EmbeddedIntParentObject.className withValue:@[@42, childObject, NSNull.null]];
        [realm createObject:EmbeddedIntParentObject.className withValue:@[@43, childObject, NSNull.null]];
    }];
    
    __block int parentEnumerateCalls = 0;
    [self failToMigrateTestRealmWithBlock:^(RLMMigration *migration, uint64_t) {
        [migration enumerateObjects:EmbeddedIntParentObject.className block:^(RLMObject *oldObject, RLMObject *newObject) {
            parentEnumerateCalls++;
            XCTAssertNotNil(oldObject);
            XCTAssertNotNil(newObject);
            RLMObject *childObject = newObject[@"object"];
            [migration createObject:EmbeddedIntParentObject.className withValue:@[@43, childObject, NSNull.null]];
        }];
    }];
    XCTAssertEqual(parentEnumerateCalls, 2);
}

#pragma mark - Property Rename

// Successful Property Rename Tests

- (void)testMigrationRenameProperty {
    RLMObjectSchema *objectSchema = [RLMObjectSchema schemaForObjectClass:AllTypesObject.class];
    RLMObjectSchema *stringObjectSchema = [RLMObjectSchema schemaForObjectClass:StringObject.class];
    RLMObjectSchema *mixedObjectSchema = [RLMObjectSchema schemaForObjectClass:MixedObject.class];
    RLMObjectSchema *linkingObjectsSchema = [RLMObjectSchema schemaForObjectClass:LinkToAllTypesObject.class];
    NSMutableArray *beforeProperties = [NSMutableArray arrayWithCapacity:objectSchema.properties.count];
    for (RLMProperty *property in objectSchema.properties) {
        [beforeProperties addObject:[property copyWithNewName:[NSString stringWithFormat:@"before_%@", property.name]]];
    }
    NSArray *afterProperties = objectSchema.properties;
    objectSchema.properties = beforeProperties;

    NSDictionary *valueDictionary = [AllTypesObject values:1 stringObject:(id)@[@"a"] mixedObject:(id)@[@"a"]];
    NSMutableArray *inputValue = [NSMutableArray arrayWithCapacity:valueDictionary.count];
    for (NSString *key in [afterProperties valueForKey:@"name"]) {
        [inputValue addObject:valueDictionary[key]];
    }

    [self createTestRealmWithSchema:@[objectSchema, stringObjectSchema, mixedObjectSchema, linkingObjectsSchema]
                              block:^(RLMRealm *realm) {
        [AllTypesObject createInRealm:realm withValue:inputValue];
    }];

    objectSchema.properties = afterProperties;

    RLMRealmConfiguration *config = [self renameConfigurationWithObjectSchemas:@[objectSchema, stringObjectSchema, mixedObjectSchema, linkingObjectsSchema]
                                                                migrationBlock:^(RLMMigration *migration, __unused uint64_t oldSchemaVersion) {
        [afterProperties enumerateObjectsUsingBlock:^(RLMProperty *property, NSUInteger idx, __unused BOOL *stop) {
            [migration renamePropertyForClass:AllTypesObject.className oldName:[beforeProperties[idx] name] newName:property.name];
            [migration enumerateObjects:AllTypesObject.className block:^(RLMObject *oldObject, RLMObject *newObject) {
                XCTAssertNotNil(oldObject[[beforeProperties[idx] name]]);
                RLMAssertThrowsWithReasonMatching(newObject[[beforeProperties[idx] name]], @"Invalid property name");
                if ([property.objectClassName isEqualToString:@""]) {
                    XCTAssertEqualObjects(oldObject[[beforeProperties[idx] name]], newObject[property.name]);
                }
            }];
        }];
        [migration enumerateObjects:AllTypesObject.className block:^(RLMObject *oldObject, RLMObject *newObject) {
            NSString *(^regexReplace)(NSString *) = ^(NSString *desc) {
                NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"<0x[0-9a-f]+>"
                                                                                       options:NSRegularExpressionCaseInsensitive
                                                                                         error:nil];
                return [regex stringByReplacingMatchesInString:desc
                                                       options:0
                                                         range:NSMakeRange(0, desc.length)
                                                  withTemplate:@""];
            };

            NSString *oldDescription = [oldObject.description stringByReplacingOccurrencesOfString:@"before_" withString:@""];
            NSString *newDescription = newObject.description;

            oldDescription = regexReplace(oldDescription);
            newDescription = regexReplace(newDescription);

            XCTAssertEqualObjects(oldDescription, newDescription);
        }];
    }];
    XCTAssertTrue([RLMRealm performMigrationForConfiguration:config error:nil]);

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
    XCTAssertEqualObjects(inputValue[9], obj.decimalCol);
    XCTAssertEqualObjects(inputValue[10], obj.objectIdCol);
    XCTAssertEqualObjects(inputValue[11], obj.uuidCol);
    XCTAssertEqualObjects(inputValue[12], @[obj.objectCol.stringCol]);
    XCTAssertEqualObjects(inputValue[13], @[obj.mixedObjectCol.anyCol]);
    XCTAssertEqualObjects(inputValue[14], obj.anyCol);
}

- (void)testMultipleMigrationRenameProperty {
    RLMObjectSchema *schema = [RLMObjectSchema schemaForObjectClass:StringObject.class];
    schema.properties = @[[schema.properties.firstObject copyWithNewName:@"stringCol0"]];

    [self createTestRealmWithSchema:@[schema] block:^(RLMRealm *realm) {
        [StringObject createInRealm:realm withValue:@[@"0"]];
    }];

    schema.properties = @[[schema.properties.firstObject copyWithNewName:@"stringCol"]];

    __block bool migrationCalled = false;

    RLMRealmConfiguration *config = self.config;
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
                RLMAssertThrowsWithReasonMatching(newObject[@"stringCol0"], @"Invalid property name");
                RLMAssertThrowsWithReasonMatching(newObject[@"stringCol1"], @"Invalid property name");
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

    XCTAssertTrue([RLMRealm performMigrationForConfiguration:config error:nil]);
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
              secondSchemaTransform:^(RLMObjectSchema *schema, RLMProperty *, RLMProperty *afterProperty) {
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
    [self assertPropertyRenameError:@"Cannot rename property 'StringObject.before_stringCol' to 'stringCol' because it would change from optional to required."
               firstSchemaTransform:^(__unused RLMObjectSchema *schema, __unused RLMProperty *beforeProperty, RLMProperty *afterProperty) {
        afterProperty.optional = NO;
    } secondSchemaTransform:nil];
}

- (void)testMigrationRenamePropertyTypeMismatch {
    [self assertPropertyRenameError:@"Cannot rename property 'StringObject.before_stringCol' to 'stringCol' because it would change from type 'int' to 'string'."
               firstSchemaTransform:^(RLMObjectSchema *, RLMProperty *beforeProperty, RLMProperty *) {
        beforeProperty.type = RLMPropertyTypeInt;
    } secondSchemaTransform:nil];
}

- (void)testMigrationRenamePropertyObjectTypeMismatch {
    RLMObjectSchema *objectSchema = [RLMObjectSchema schemaForObjectClass:MigrationLinkObject.class];
    RLMObjectSchema *migrationObjectSchema = [RLMObjectSchema schemaForObjectClass:MigrationTestObject.class];
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

    [self assertPropertyRenameError:@"Cannot rename property 'MigrationLinkObject.before_object' to 'object' because it would change from type '<MigrationLinkObject>' to '<MigrationTestObject>'."
                      objectSchemas:@[objectSchema, migrationObjectSchema]
                          className:MigrationLinkObject.className
                            oldName:[beforeProperties[0] name]
                            newName:[afterProperties[0] name]];

    [self assertPropertyRenameError:@"Cannot rename property 'MigrationLinkObject.before_array' to 'array' because it would change from type 'array<MigrationLinkObject>' to 'array<MigrationTestObject>'."
                      objectSchemas:@[objectSchema, migrationObjectSchema]
                          className:MigrationLinkObject.className
                            oldName:[beforeProperties[1] name]
                            newName:[afterProperties[1] name]];
}

- (void)testMigrationRenameMissingPropertiesAndClasses {
    RLMObjectSchema *objectSchema = [RLMObjectSchema schemaForObjectClass:StringObject.class];

    [self createTestRealmWithSchema:@[objectSchema] block:^(__unused RLMRealm *realm) {
        // No need to create an object
    }];

    // Missing Old Property
    [self assertPropertyRenameError:@"Cannot rename property 'StringObject.nonExistentProperty1' because it does not exist."
                      objectSchemas:@[objectSchema] className:StringObject.className
                            oldName:@"nonExistentProperty1" newName:@"nonExistentProperty2"];

    // Missing New Property
    RLMObjectSchema *renamedProperty = [objectSchema copy];
    renamedProperty.properties[0].name = @"stringCol2";
    [self assertPropertyRenameError:@"Renamed property 'StringObject.nonExistentProperty' does not exist."
                      objectSchemas:@[renamedProperty] className:StringObject.className
                            oldName:@"stringCol" newName:@"nonExistentProperty"];

    // Removed Class
    [self assertPropertyRenameError:@"Cannot rename properties for type 'StringObject' because it has been removed from the Realm."
                      objectSchemas:@[[RLMObjectSchema schemaForObjectClass:IntObject.class]]
                          className:StringObject.className oldName:@"stringCol" newName:@"stringCol2"];

    // Without Removing Old Property
    RLMProperty *secondProperty = [objectSchema.properties.firstObject copyWithNewName:@"stringCol2"];
    objectSchema.properties = [objectSchema.properties arrayByAddingObject:secondProperty];
    [self assertPropertyRenameError:@"Cannot rename property 'StringObject.stringCol' to 'stringCol2' because the source property still exists."
                      objectSchemas:@[objectSchema] className:StringObject.className oldName:@"stringCol" newName:@"stringCol2"];
}

@end
