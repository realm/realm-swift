////////////////////////////////////////////////////////////////////////////
//
// Copyright 2022 Realm Inc.
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

#import "RLMSyncTestCase.h"

#import "RLMApp_Private.h"
#import "RLMObject_Private.h"
#import "RLMObjectSchema_Private.h"

#pragma mark PersonAsymmetric

@interface PersonAsymmetric : RLMAsymmetricObject
@property RLMObjectId *_id;
@property NSString *firstName;
@property NSString *lastName;
@property NSInteger age;

- (instancetype)initWithPrimaryKey:(RLMObjectId *)primaryKey firstName:(NSString *)firstName lastName:(NSString *)lastName age:(NSInteger)age;
@end

@implementation PersonAsymmetric

+ (NSDictionary *)defaultPropertyValues {
    return @{@"_id": [RLMObjectId objectId]};
}

+ (NSString *)primaryKey {
    return @"_id";
}

+ (NSArray *)requiredProperties {
    return @[@"firstName", @"lastName", @"age"];
}

+ (bool)_realmIgnoreClass {
    return true;
}

- (instancetype)initWithPrimaryKey:(RLMObjectId *)primaryKey firstName:(NSString *)firstName lastName:(NSString *)lastName age:(NSInteger)age {
    self = [super init];
    if (self) {
        self._id = primaryKey;
        self.age = age;
        self.firstName = firstName;
        self.lastName = lastName;
    }
    return self;
}
@end

#pragma mark UnsupportedLinkAsymmetric

RLM_COLLECTION_TYPE(PersonAsymmetric);
@interface UnsupportedLinkAsymmetric : RLMAsymmetricObject
@property RLMObjectId *_id;
@property PersonAsymmetric *object;
@property RLM_GENERIC_ARRAY(PersonAsymmetric) *objectArray;
@end

@implementation UnsupportedLinkAsymmetric

+ (NSDictionary *)defaultPropertyValues {
    return @{@"_id": [RLMObjectId objectId]};
}

+ (NSString *)primaryKey {
    return @"_id";
}

+ (bool)_realmIgnoreClass {
    return YES;
}
@end

#pragma mark UnsupportedObjectLinkAsymmetric

@interface UnsupportedObjectLinkAsymmetric : RLMObject
@property RLMObjectId *_id;
@property PersonAsymmetric *object;
@property RLM_GENERIC_ARRAY(PersonAsymmetric) *objectArray;
@end

@implementation UnsupportedObjectLinkAsymmetric

+ (NSDictionary *)defaultPropertyValues {
    return @{@"_id": [RLMObjectId objectId]};
}

+ (NSString *)primaryKey {
    return @"_id";
}

+ (bool)_realmIgnoreClass {
    return true;
}
@end

@interface RLMAsymmetricSyncServerTests : RLMSyncTestCase
@end

@implementation RLMAsymmetricSyncServerTests

#pragma mark Asymmetric Sync App

- (NSString *)createAppWithError:(NSError **)error {
    return [RealmServer.shared createAppWithFields:@[]
                                             types:@[PersonAsymmetric.self]
                                        persistent:true
                                             error:error];
}

- (NSArray *)defaultObjectTypes {
    return @[PersonAsymmetric.self];
}

- (RLMRealmConfiguration *)configurationForUser:(RLMUser *)user {
    return [user flexibleSyncConfiguration];
}

- (void)tearDown {
    [self cleanupRemoteDocuments:[self.anonymousUser collectionForType:PersonAsymmetric.class app:self.app]];
    [super tearDown];
}

- (void)checkCountInMongo:(unsigned long)expectedCount {
    RLMMongoCollection *collection = [self.anonymousUser collectionForType:PersonAsymmetric.class app:self.app];

    __block unsigned long count = 0;
    NSDate *waitStart = [NSDate date];
    while (count < expectedCount && ([waitStart timeIntervalSinceNow] > -600.0)) {
        auto ex = [self expectationWithDescription:@""];
        [collection countWhere:@{}
                    completion:^(NSInteger c, NSError *error) {
            XCTAssertNil(error);
            count = c;
            [ex fulfill];
        }];
        [self waitForExpectations:@[ex] timeout:5.0];
        if (count < expectedCount) {
            sleep(5);
        }
    }
    XCTAssertEqual(count, expectedCount);
}

- (void)testAsymmetricObjectSchema {
    RLMRealm *realm = [self openRealm];
    XCTAssertTrue(realm.schema.objectSchema[0].isAsymmetric);
}

- (void)testUnsupportedAsymmetricLinkAsymmetricThrowsError {
    RLMUser *user = [self createUser];
    RLMRealmConfiguration *configuration = [user flexibleSyncConfiguration];
    configuration.objectClasses = @[UnsupportedLinkAsymmetric.self, PersonAsymmetric.self];
    NSError *error;
    RLMRealm *realm = [RLMRealm realmWithConfiguration:configuration error:&error];
    XCTAssertNil(realm);
    XCTAssert([error.localizedDescription containsString:@"Property 'UnsupportedLinkAsymmetric.object' of type 'object' cannot be a link to an asymmetric object."]);
    XCTAssert([error.localizedDescription containsString:@"Property 'UnsupportedLinkAsymmetric.objectArray' of type 'array' cannot be a link to an asymmetric object."]);
}

- (void)testUnsupportedObjectLinksAsymmetricThrowsError  {
    RLMUser *user = [self createUser];
    RLMRealmConfiguration *configuration = [user flexibleSyncConfiguration];
    configuration.objectClasses = @[UnsupportedObjectLinkAsymmetric.self, PersonAsymmetric.self];
    NSError *error;
    RLMRealm *realm = [RLMRealm realmWithConfiguration:configuration error:&error];
    XCTAssertNil(realm);
    // This error comes from core, we are not even adding this objects to the server schema.
    XCTAssert([error.localizedDescription containsString:@"Property 'UnsupportedObjectLinkAsymmetric.object' of type 'object' cannot be a link to an asymmetric object."]);
    XCTAssert([error.localizedDescription containsString:@"Property 'UnsupportedObjectLinkAsymmetric.objectArray' of type 'array' cannot be a link to an asymmetric object."]);
}

- (void)testOpenLocalRealmWithAsymmetricObjectError {
    RLMRealmConfiguration *configuration = [RLMRealmConfiguration defaultConfiguration];
    configuration.objectClasses = @[PersonAsymmetric.self];
    NSError *error;
    RLMRealm *realm = [RLMRealm realmWithConfiguration:configuration error:&error];
    XCTAssertNil(realm);
    RLMValidateErrorContains(error, RLMErrorDomain, RLMErrorFail,
                             @"Asymmetric table 'PersonAsymmetric' not allowed in a local Realm");
}

- (void)testOpenPBSConfigurationWithAsymmetricObjectError {
    RLMUser *user = [self createUser];
    RLMRealmConfiguration *configuration = [user configurationWithPartitionValue:self.name];
    configuration.objectClasses = @[PersonAsymmetric.self];
    NSError *error;
    RLMRealm *realm = [RLMRealm realmWithConfiguration:configuration error:&error];
    XCTAssertNil(realm);
    RLMValidateErrorContains(error, RLMErrorDomain, RLMErrorFail,
                             @"Asymmetric table 'PersonAsymmetric' not allowed in partition based sync");
}

- (void)testCreateAsymmetricObjects {
    RLMRealm *realm = [self openRealm];

    [realm beginWriteTransaction];
    for (int i = 1; i <= 12; ++i) {
        RLMObjectId *oid = [RLMObjectId objectId];
        PersonAsymmetric *person = [PersonAsymmetric createInRealm:realm withValue:@[
            oid, [NSString stringWithFormat:@"firstname_%d", i],
            [NSString stringWithFormat:@"lastname_%d", i]
        ]];
        XCTAssertNil(person);
    }
    [realm commitWriteTransaction];
    [self waitForUploadsForRealm:realm];
    [self checkCountInMongo:12];
}

- (void)testCreateAsymmetricSameObjectNotDuplicates {
    RLMRealm *realm = [self openRealm];

    RLMObjectId *oid = [RLMObjectId objectId];
    [realm beginWriteTransaction];
    PersonAsymmetric *person = [PersonAsymmetric createInRealm:realm withValue:@[oid, @"firstname", @"lastname", @10]];
    XCTAssertNil(person);
    [realm commitWriteTransaction];
    [self waitForUploadsForRealm:realm];
    [self checkCountInMongo:1];

    [realm beginWriteTransaction];
    PersonAsymmetric *person2 = [PersonAsymmetric createInRealm:realm withValue:@[oid, @"firstname", @"lastname", @10]];
    XCTAssertNil(person2);
    [realm commitWriteTransaction];
    [self waitForUploadsForRealm:realm];
    [self checkCountInMongo:1];
}
@end
