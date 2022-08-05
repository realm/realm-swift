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

#pragma mark UnsupportedLinkObject

@interface UnsupportedLinkObject : RLMAsymmetricObject
@property RLMObjectId *_id;
@property Person *object;
@property RLM_GENERIC_ARRAY(Person) *objectArray;
@end

@implementation UnsupportedLinkObject

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

@implementation RLMAsymmetricSyncServerTests {
    NSString *_asymmetricSyncAppId;
    RLMApp *_asymmetricSyncApp;
}

#pragma mark Asymmetric Sync App

- (NSString *)asymmetricSyncAppId {
    if (!_asymmetricSyncAppId) {
        static NSString *s_appId;
        if (s_appId) {
            _asymmetricSyncAppId = s_appId;
        }
        else {
            NSError *error;
            NSArray *objectsSchema = @[[RLMObjectSchema schemaForObjectClass:PersonAsymmetric.class]];
            _asymmetricSyncAppId = [RealmServer.shared createAppForAsymmetricSchema:objectsSchema error:&error];
            if (error) {
                NSLog(@"Failed to create asymmetric app: %@", error);
                abort();
            }
            s_appId = _asymmetricSyncAppId;
        }
    }
    return _asymmetricSyncAppId;
}

- (RLMApp *)asymmetricSyncApp {
    if (!_asymmetricSyncApp) {
        _asymmetricSyncApp = [RLMApp appWithId:self.asymmetricSyncAppId
                                 configuration:self.defaultAppConfiguration
                                 rootDirectory:self.clientDataRoot];
        RLMSyncManager *syncManager = self.asymmetricSyncApp.syncManager;
        syncManager.logLevel = RLMSyncLogLevelTrace;
        syncManager.userAgent = self.name;
    }
    return _asymmetricSyncApp;
}

- (RLMUser *)userForSelector:(SEL)testSel {
    return [self logInUserForCredentials:[self basicCredentialsWithName:NSStringFromSelector(testSel)
                                                               register:YES
                                                                    app:self.asymmetricSyncApp]
                                     app:self.asymmetricSyncApp];
}

- (void)tearDown {
    RLMUser *user = [self logInUserForCredentials:[RLMCredentials anonymousCredentials]
                                              app:self.asymmetricSyncApp];
    RLMMongoClient *client = [user mongoClientWithServiceName:@"mongodb1"];
    RLMMongoDatabase *database = [client databaseWithName:@"test_data"];
    RLMMongoCollection *collection = [database collectionWithName:@"PersonAsymmetric"];
    [self cleanupRemoteDocuments:collection];
    [super tearDown];
}

- (void)checkCountInMongo:(unsigned long)expectedCount {
    RLMUser *user = [self logInUserForCredentials:[RLMCredentials anonymousCredentials]
                                              app:self.asymmetricSyncApp];
    RLMMongoClient *client = [user mongoClientWithServiceName:@"mongodb1"];
    RLMMongoDatabase *database = [client databaseWithName:@"test_data"];
    RLMMongoCollection *collection = [database collectionWithName:@"PersonAsymmetric"];

    __block unsigned long count = 0;
    NSDate *waitStart = [NSDate date];
    while (count < expectedCount && ([waitStart timeIntervalSinceNow] > -600.0)) {
        [collection countWhere:@{}
                    completion:^(NSInteger c, NSError *error) {
            count = c;

        }];
        sleep(5);
    }
    XCTAssertEqual(count, expectedCount);
}

- (void)testAsymmetricObjectSchema {
    RLMUser *user = [self userForSelector:_cmd];
    RLMRealmConfiguration *configuration = [user flexibleSyncConfiguration];
    configuration.objectClasses = @[PersonAsymmetric.self];
    RLMRealm *realm = [RLMRealm realmWithConfiguration:configuration error:nil];
    XCTAssertTrue(realm.schema.objectSchema[0].isAsymmetric);
}

- (void)testUnsupportedAsymmetricLinkAsymmetricThrowsError {
    RLMUser *user = [self userForSelector:_cmd];
    RLMRealmConfiguration *configuration = [user flexibleSyncConfiguration];
    configuration.objectClasses = @[UnsupportedLinkAsymmetric.self, PersonAsymmetric.self];
    NSError *error;
    RLMRealm *realm = [RLMRealm realmWithConfiguration:configuration error:&error];
    XCTAssertNil(realm);
    // This error comes from core, we are not even adding this objects to the server schema.
    XCTAssert([error.localizedDescription containsString:@"Asymmetric table with property 'UnsupportedLinkAsymmetric.object' of type 'object' cannot have an object type."]);
    XCTAssert([error.localizedDescription containsString:@"Asymmetric table with property 'UnsupportedLinkAsymmetric.objectArray' of type 'array' cannot have an object type."]);
}

- (void)testUnsupportedAsymmetricLinkObjectThrowsError  {
    RLMUser *user = [self userForSelector:_cmd];
    RLMRealmConfiguration *configuration = [user flexibleSyncConfiguration];
    configuration.objectClasses = @[UnsupportedLinkObject.self, Person.self];
    NSError *error;
    RLMRealm *realm = [RLMRealm realmWithConfiguration:configuration error:&error];
    XCTAssertNil(realm);
    // This error comes from core, we are not even adding this objects to the server schema.
    XCTAssert([error.localizedDescription containsString:@"Asymmetric table with property 'UnsupportedLinkObject.object' of type 'object' cannot have an object type."]);
    XCTAssert([error.localizedDescription containsString:@"Asymmetric table with property 'UnsupportedLinkObject.objectArray' of type 'array' cannot have an object type."]);
}

- (void)testUnsupportedObjectLinksAsymmetricThrowsError  {
    RLMUser *user = [self userForSelector:_cmd];
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
    configuration.objectClasses =  @[PersonAsymmetric.self];
    NSError *error;
    RLMRealm *realm = [RLMRealm realmWithConfiguration:configuration error:&error];
    XCTAssertNil(realm);
    XCTAssertNotNil(error);
}

// FIXME: Enable this test when this is implemented on core. Core should validate if the schema includes an asymmetric table for a PBS configuration and throw an error.
- (void)fixme_testOpenPBSConfigurationWithAsymmetricObjectError {
    RLMUser *user = [self userForTest:_cmd];
    RLMRealmConfiguration *configuration = [user configurationWithPartitionValue:NSStringFromSelector(_cmd)];
    configuration.objectClasses = @[PersonAsymmetric.self];
    NSError *error;
    RLMRealm *realm = [RLMRealm realmWithConfiguration:configuration error:&error];
    XCTAssertNil(realm);
    XCTAssertNotNil(error);
}

- (void)testCreateAsymmetricObjects {
    RLMUser *user = [self userForSelector:_cmd];
    RLMRealmConfiguration *configuration = [user flexibleSyncConfiguration];
    configuration.objectClasses = @[PersonAsymmetric.self];
    RLMRealm *realm = [RLMRealm realmWithConfiguration:configuration error:nil];
    XCTAssertNotNil(realm);

    [realm beginWriteTransaction];
    for (int i = 1; i <= 12; ++i) {
        RLMObjectId *oid = [RLMObjectId objectId];
        (void)[PersonAsymmetric createInRealm:realm withValue:@[oid, [NSString stringWithFormat:@"firstname_%d", i], [NSString stringWithFormat:@"lastname_%d", i]]];
    }
    [realm commitWriteTransaction];
    [self waitForUploadsForRealm:realm];
    [self checkCountInMongo:12];
}

- (void)testCreateAsymmetricSameObjectNotDuplicates {
    RLMUser *user = [self userForSelector:_cmd];
    RLMRealmConfiguration *configuration = [user flexibleSyncConfiguration];
    configuration.objectClasses = @[PersonAsymmetric.self];
    RLMRealm *realm = [RLMRealm realmWithConfiguration:configuration error:nil];
    XCTAssertNotNil(realm);

    RLMObjectId *oid = [RLMObjectId objectId];
    [realm beginWriteTransaction];
    (void)[PersonAsymmetric createInRealm:realm withValue:@[oid, @"firstname", @"lastname", @10]];
    [realm commitWriteTransaction];
    [self waitForUploadsForRealm:realm];
    [self checkCountInMongo:1];

    [realm beginWriteTransaction];
    (void)[PersonAsymmetric createInRealm:realm withValue:@[oid, @"firstname", @"lastname", @10]];
    [realm commitWriteTransaction];
    [self waitForUploadsForRealm:realm];
    [self checkCountInMongo:1];
}
@end
