////////////////////////////////////////////////////////////////////////////
//
// Copyright 2021 Realm Inc.
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
#import "RLMSyncSubscription_Private.h"
#import "RLMApp_Private.hpp"

@interface TimeoutProxyServer : NSObject
- (instancetype)initWithPort:(uint16_t)port targetPort:(uint16_t)targetPort;
- (void)startAndReturnError:(NSError **)error;
- (void)stop;
@property (nonatomic) double delay;
@end

@interface RLMFlexibleSyncTests : RLMSyncTestCase
@end

@implementation RLMFlexibleSyncTests
- (NSArray *)defaultObjectTypes {
    return @[Dog.self, Person.self, UUIDPrimaryKeyObject.self];
}

- (NSString *)createAppWithError:(NSError **)error {
    return [self createFlexibleSyncAppWithError:error];
}

- (RLMRealmConfiguration *)configurationForUser:(RLMUser *)user {
    return [user flexibleSyncConfiguration];
}

- (void)createPeople:(RLMRealm *)realm {
    const int numberOfSubs = 21;
    for (int i = 1; i <= numberOfSubs; ++i) {
        Person *person = [[Person alloc] initWithPrimaryKey:[RLMObjectId objectId]
                                                        age:i
                                                  firstName:[NSString stringWithFormat:@"firstname_%d", i]
                                                   lastName:[NSString stringWithFormat:@"lastname_%d", i]];
        person.partition = self.name;
        [realm addObject:person];
    }
}
- (void)createDog:(RLMRealm *)realm {
    Dog *dog = [[Dog alloc] initWithPrimaryKey:[RLMObjectId objectId]
                                         breed:@"Labradoodle"
                                          name:@"Tom"];
    dog.partition = self.name;
    [realm addObject:dog];
}

- (void)testFlexibleSyncWithoutQuery {
    [self populateData:^(RLMRealm *realm) {
        [self createPeople:realm];
    }];

    RLMRealm *realm = [self openRealm];
    CHECK_COUNT(0, Person, realm);

    RLMSyncSubscriptionSet *subs = realm.subscriptions;
    XCTAssertNotNil(subs);
    XCTAssertEqual(subs.version, 0UL);
    XCTAssertEqual(subs.count, 0UL);

    [self waitForDownloadsForRealm:realm];
    CHECK_COUNT(0, Person, realm);
    CHECK_COUNT(0, Dog, realm);
}

- (void)testFlexibleSyncAddQuery {
    [self populateData:^(RLMRealm *realm) {
        [self createPeople:realm];
    }];

    RLMRealm *realm = [self openRealm];
    CHECK_COUNT(0, Person, realm);

    [self writeQueryAndCompleteForRealm:realm block:^(RLMSyncSubscriptionSet *subs) {
        [subs addSubscriptionWithClassName:Person.className
                          subscriptionName:@"person_age"
                                     where:@"age > 15 and partition == %@", self.name];
    }];

    CHECK_COUNT(6, Person, realm);
    CHECK_COUNT(0, Dog, realm);
}

- (void)testFlexibleSyncAddMultipleQuery {
    [self populateData:^(RLMRealm *realm) {
        [self createPeople:realm];
        [self createDog:realm];
    }];

    RLMRealm *realm = [self openRealm];
    CHECK_COUNT(0, Person, realm);

    [self writeQueryAndCompleteForRealm:realm block:^(RLMSyncSubscriptionSet *subs) {
        [subs addSubscriptionWithClassName:Person.className
                          subscriptionName:@"person_age"
                                     where:@"age > 10 and partition == %@", self.name];
        [subs addSubscriptionWithClassName:Dog.className
                          subscriptionName:@"dog_breed_labradoodle"
                                     where:@"breed == 'Labradoodle' and partition == %@", self.name];
    }];

    CHECK_COUNT(11, Person, realm);
    CHECK_COUNT(1, Dog, realm);
}

- (void)testFlexibleSyncRemoveQuery {
    [self populateData:^(RLMRealm *realm) {
        [self createPeople:realm];
        [self createDog:realm];
    }];

    RLMRealm *realm = [self openRealm];
    CHECK_COUNT(0, Person, realm);

    [self writeQueryAndCompleteForRealm:realm block:^(RLMSyncSubscriptionSet *subs) {
        [subs addSubscriptionWithClassName:Person.className
                          subscriptionName:@"person_age"
                                     where:@"age > 5 and partition == %@", self.name];
        [subs addSubscriptionWithClassName:Dog.className
                          subscriptionName:@"dog_breed_labradoodle"
                                     where:@"breed == 'Labradoodle' and partition == %@", self.name];
    }];
    CHECK_COUNT(16, Person, realm);
    CHECK_COUNT(1, Dog, realm);

    [self writeQueryAndCompleteForRealm:realm block:^(RLMSyncSubscriptionSet *subs) {
        [subs removeSubscriptionWithName:@"person_age"];
    }];
    CHECK_COUNT(0, Person, realm);
    CHECK_COUNT(1, Dog, realm);
}

- (void)testFlexibleSyncRemoveAllQueries {
    [self populateData:^(RLMRealm *realm) {
        [self createPeople:realm];
        [self createDog:realm];
    }];

    RLMRealm *realm = [self openRealm];
    CHECK_COUNT(0, Person, realm);

    [self writeQueryAndCompleteForRealm:realm block:^(RLMSyncSubscriptionSet *subs) {
        [subs addSubscriptionWithClassName:Person.className
                          subscriptionName:@"person_age"
                                     where:@"age > 5 and partition == %@", self.name];
        [subs addSubscriptionWithClassName:Dog.className
                          subscriptionName:@"dog_breed_labradoodle"
                                     where:@"breed == 'Labradoodle' and partition == %@", self.name];
    }];
    CHECK_COUNT(16, Person, realm);
    CHECK_COUNT(1, Dog, realm);

    [self writeQueryAndCompleteForRealm:realm block:^(RLMSyncSubscriptionSet *subs) {
        [subs removeAllSubscriptions];
        [subs addSubscriptionWithClassName:Person.className
                          subscriptionName:@"person_age"
                                     where:@"age > 0 and partition == %@", self.name];
    }];
    CHECK_COUNT(21, Person, realm);
    CHECK_COUNT(0, Dog, realm);
}

- (void)testFlexibleSyncRemoveAllQueriesForType {
    [self populateData:^(RLMRealm *realm) {
        [self createPeople:realm];
        [self createDog:realm];
    }];

    RLMRealm *realm = [self openRealm];
    CHECK_COUNT(0, Person, realm);

    [self writeQueryAndCompleteForRealm:realm block:^(RLMSyncSubscriptionSet *subs) {
        [subs addSubscriptionWithClassName:Person.className
                          subscriptionName:@"person_age"
                                     where:@"age > 20 and partition == %@", self.name];
        [subs addSubscriptionWithClassName:Person.className
                          subscriptionName:@"person_age_2"
                                     where:@"firstName == 'firstname_1' and partition == %@", self.name];
        [subs addSubscriptionWithClassName:Dog.className
                          subscriptionName:@"dog_breed_labradoodle"
                                     where:@"breed == 'Labradoodle' and partition == %@", self.name];
    }];
    CHECK_COUNT(2, Person, realm);
    CHECK_COUNT(1, Dog, realm);

    [self writeQueryAndCompleteForRealm:realm block:^(RLMSyncSubscriptionSet *subs) {
        [subs removeAllSubscriptionsWithClassName:Person.className];
    }];
    CHECK_COUNT(0, Person, realm);
    CHECK_COUNT(1, Dog, realm);
}

- (void)testRemoveAllUnnamedSubscriptions {
    [self populateData:^(RLMRealm *realm) {
        [self createPeople:realm];
        [self createDog:realm];
    }];

    RLMRealm *realm = [self openRealm];
    CHECK_COUNT(0, Person, realm);

    [self writeQueryAndCompleteForRealm:realm block:^(RLMSyncSubscriptionSet *subs) {
        [subs addSubscriptionWithClassName:Person.className
                                     where:@"age > 20 and partition == %@", self.name];
        [subs addSubscriptionWithClassName:Person.className
                          subscriptionName:@"person_age_2"
                                     where:@"firstName == 'firstname_1' and partition == %@", self.name];
        [subs addSubscriptionWithClassName:Dog.className
                                     where:@"breed == 'Labradoodle' and partition == %@", self.name];
    }];
    XCTAssertEqual(realm.subscriptions.count, 3U);
    CHECK_COUNT(2, Person, realm);
    CHECK_COUNT(1, Dog, realm);

    [self writeQueryAndCompleteForRealm:realm block:^(RLMSyncSubscriptionSet *subs) {
        [subs removeAllUnnamedSubscriptions];
    }];
    XCTAssertEqual(realm.subscriptions.count, 1U);
    CHECK_COUNT(1, Person, realm);
    CHECK_COUNT(0, Dog, realm);
}

- (void)testFlexibleSyncUpdateQuery {
    [self populateData:^(RLMRealm *realm) {
        [self createPeople:realm];
    }];

    RLMRealm *realm = [self openRealm];
    CHECK_COUNT(0, Person, realm);

    [self writeQueryAndCompleteForRealm:realm block:^(RLMSyncSubscriptionSet *subs) {
        [subs addSubscriptionWithClassName:Person.className
                          subscriptionName:@"person_age"
                                     where:@"age > 0 and partition == %@", self.name];
    }];
    CHECK_COUNT(21, Person, realm);

    [self writeQueryAndCompleteForRealm:realm block:^(RLMSyncSubscriptionSet *subs) {
        RLMSyncSubscription *foundSub = [subs subscriptionWithName:@"person_age"];
        [foundSub updateSubscriptionWhere:@"age > 20 and partition == %@", self.name];
    }];
    CHECK_COUNT(1, Person, realm);
}

- (void)testFlexibleSyncAddObjectOutsideQuery {
    [self populateData:^(RLMRealm *realm) {
        [self createPeople:realm];
    }];

    RLMRealm *realm = [self openRealm];
    CHECK_COUNT(0, Person, realm);

    [self writeQueryAndCompleteForRealm:realm block:^(RLMSyncSubscriptionSet *subs) {
        [subs addSubscriptionWithClassName:Person.className
                          subscriptionName:@"person_age"
                                     where:@"age > 18 and partition == %@", self.name];
    }];
    CHECK_COUNT(3, Person, realm);

    RLMObjectId *invalidObjectPK = [RLMObjectId objectId];
    auto ex = [self expectationWithDescription:@"should revert write"];
    self.app.syncManager.errorHandler = ^(NSError *error, RLMSyncSession *) {
        RLMValidateError(error, RLMSyncErrorDomain, RLMSyncErrorWriteRejected,
                         @"Client attempted a write that is not allowed; it has been reverted");
        NSArray<RLMCompensatingWriteInfo *> *info = error.userInfo[RLMCompensatingWriteInfoKey];
        XCTAssertEqual(info.count, 1U);
        XCTAssertEqualObjects(info[0].objectType, @"Person");
        XCTAssertEqualObjects(info[0].primaryKey, invalidObjectPK);
        XCTAssertEqualObjects(info[0].reason,
                              ([NSString stringWithFormat:@"write to ObjectID(\"%@\") in table \"Person\" not allowed; object is outside of the current query view", invalidObjectPK]));
        [ex fulfill];
    };
    [realm transactionWithBlock:^{
        [realm addObject:[[Person alloc] initWithPrimaryKey:invalidObjectPK age:10 firstName:@"Nic" lastName:@"Cages"]];
    }];
    [self waitForExpectations:@[ex] timeout:20];
    [self waitForDownloadsForRealm:realm];
    CHECK_COUNT(3, Person, realm);
}

- (void)testFlexibleSyncInitialSubscription {
    RLMUser *user = [self createUser];
    RLMRealmConfiguration *config = [user flexibleSyncConfigurationWithInitialSubscriptions:^(RLMSyncSubscriptionSet *subscriptions) {
        [subscriptions addSubscriptionWithClassName:Person.className
                                   subscriptionName:@"person_age"
                                              where:@"TRUEPREDICATE"];
    } rerunOnOpen:false];
    config.objectClasses = @[Person.self];
    RLMRealm *realm = [RLMRealm realmWithConfiguration:config error:nil];
    XCTAssertEqual(realm.subscriptions.count, 1UL);
}

- (void)testFlexibleSyncInitialSubscriptionAwait {
    [self populateData:^(RLMRealm *realm) {
        [self createPeople:realm];
    }];

    RLMUser *user = [self createUser];
    RLMRealmConfiguration *config = [user flexibleSyncConfigurationWithInitialSubscriptions:^(RLMSyncSubscriptionSet *subscriptions) {
        [subscriptions addSubscriptionWithClassName:Person.className
                                   subscriptionName:@"person_age"
                                              where:@"age > 10 and partition == %@", self.name];
    } rerunOnOpen:false];
    config.objectClasses = @[Person.self];
    XCTestExpectation *ex = [self expectationWithDescription:@"download-realm"];
    [RLMRealm asyncOpenWithConfiguration:config
                           callbackQueue:dispatch_get_main_queue()
                                callback:^(RLMRealm *realm, NSError *error) {
        XCTAssertNil(error);
        XCTAssertEqual(realm.subscriptions.count, 1UL);
        CHECK_COUNT(11, Person, realm);
        [ex fulfill];
    }];
    [self waitForExpectationsWithTimeout:30.0 handler:nil];
}

- (void)testFlexibleSyncInitialSubscriptionDoNotRerunOnOpen {
    RLMUser *user = [self createUser];
    RLMRealmConfiguration *config = [user flexibleSyncConfigurationWithInitialSubscriptions:^(RLMSyncSubscriptionSet *subscriptions) {
        [subscriptions addSubscriptionWithClassName:Person.className
                                   subscriptionName:@"person_age"
                                              where:@"age > 10 and partition == %@", self.name];
    } rerunOnOpen:false];
    config.objectClasses = @[Person.self];

    @autoreleasepool {
        RLMRealm *realm = [RLMRealm realmWithConfiguration:config error:nil];
        XCTAssertEqual(realm.subscriptions.count, 1UL);
    }

    RLMRealm *realm = [RLMRealm realmWithConfiguration:config error:nil];
    XCTAssertEqual(realm.subscriptions.count, 1UL);

    [self dispatchAsyncAndWait:^{
        RLMRealm *realm = [RLMRealm realmWithConfiguration:config error:nil];
        XCTAssertEqual(realm.subscriptions.count, 1UL);
    }];
}

- (void)testFlexibleSyncInitialSubscriptionRerunOnOpen {
    [self populateData:^(RLMRealm *realm) {
        [self createPeople:realm];
    }];

    RLMUser *user = [self createUser];

    __block int openCount = 0;
    RLMRealmConfiguration *config = [user flexibleSyncConfigurationWithInitialSubscriptions:^(RLMSyncSubscriptionSet *subscriptions) {
        XCTAssertLessThan(openCount, 2);
        int age = openCount == 0 ? 10 : 5;
        [subscriptions addSubscriptionWithClassName:Person.className
                                              where:@"age > %i and partition == %@", age, self.name];
        ++openCount;
    } rerunOnOpen:true];
    config.objectClasses = @[Person.self];
    XCTestExpectation *ex = [self expectationWithDescription:@"download-realm"];
    [RLMRealm asyncOpenWithConfiguration:config
                           callbackQueue:dispatch_get_main_queue()
                                callback:^(RLMRealm *realm, NSError *error) {
        XCTAssertNotNil(realm);
        XCTAssertNil(error);
        XCTAssertEqual(realm.subscriptions.count, 1UL);
        CHECK_COUNT(11, Person, realm);
        [ex fulfill];
    }];
    [self waitForExpectationsWithTimeout:90.0 handler:nil];
    XCTAssertEqual(openCount, 1);

    __block RLMRealm *realm;
    XCTestExpectation *ex2 = [self expectationWithDescription:@"download-realm-2"];
    [RLMRealm asyncOpenWithConfiguration:config
                           callbackQueue:dispatch_get_main_queue()
                                callback:^(RLMRealm *r, NSError *error) {
        realm = r;
        XCTAssertNotNil(realm);
        XCTAssertNil(error);
        XCTAssertEqual(realm.subscriptions.count, 2UL);
        CHECK_COUNT(16, Person, realm);
        [ex2 fulfill];
    }];
    [self waitForExpectationsWithTimeout:90.0 handler:nil];
    XCTAssertEqual(openCount, 2);

    [self dispatchAsyncAndWait:^{
        [RLMRealm realmWithConfiguration:config error:nil];
        // Should not have called initial subscriptions despite rerunOnOpen being
        // set as the Realm was already open
        XCTAssertEqual(openCount, 2);
    }];
}

- (void)testFlexibleSyncInitialOnConnectionTimeout {
    TimeoutProxyServer *proxy = [[TimeoutProxyServer alloc] initWithPort:5678 targetPort:9090];
    NSError *error;
    [proxy startAndReturnError:&error];
    XCTAssertNil(error);

    RLMAppConfiguration *appConfig = [[RLMAppConfiguration alloc] initWithBaseURL:@"http://localhost:9090"
                                                                        transport:[AsyncOpenConnectionTimeoutTransport new]
                                                          defaultRequestTimeoutMS:60];
    RLMSyncTimeoutOptions *timeoutOptions = [RLMSyncTimeoutOptions new];
    timeoutOptions.connectTimeout = 1000.0;
    appConfig.syncTimeouts = timeoutOptions;
    RLMApp *app = [RLMApp appWithId:self.appId configuration:appConfig];
    RLMUser *user = [self logInUserForCredentials:[RLMCredentials anonymousCredentials] app:app];

    RLMRealmConfiguration *config = [user flexibleSyncConfigurationWithInitialSubscriptions:^(RLMSyncSubscriptionSet *subscriptions) {
        [subscriptions addSubscriptionWithClassName:Person.className
                                              where:@"age > 10 and partition == %@", self.name];
    } rerunOnOpen:true];
    config.objectClasses = @[Person.class];
    RLMSyncConfiguration *syncConfig = config.syncConfiguration;
    syncConfig.cancelAsyncOpenOnNonFatalErrors = true;
    config.syncConfiguration = syncConfig;

    // Set delay above the timeout so it should fail
    proxy.delay = 2.0;

    XCTestExpectation *ex = [self expectationWithDescription:@"async open"];
    [RLMRealm asyncOpenWithConfiguration:config
                           callbackQueue:dispatch_get_main_queue()
                                callback:^(RLMRealm *realm, NSError *error) {
        RLMValidateError(error, NSPOSIXErrorDomain, ETIMEDOUT,
                         @"Sync connection was not fully established in time");
        XCTAssertNil(realm);
        [ex fulfill];
    }];
    [self waitForExpectationsWithTimeout:30.0 handler:nil];

    [proxy stop];
}

- (void)testSubscribeWithName {
    [self populateData:^(RLMRealm *realm) {
        Person *person = [[Person alloc] initWithPrimaryKey:[RLMObjectId objectId]
                                                        age:30
                                                  firstName:@"Brian"
                                                   lastName:@"Epstein"];
        person.partition = self.name;
        [realm addObject:person];
    }];

    RLMRealm *realm = [self openRealm];
    CHECK_COUNT(0, Person, realm);

    XCTestExpectation *ex = [self expectationWithDescription:@"wait for download"];
    [[[Person allObjectsInRealm:realm] objectsWhere:@"lastName == 'Epstein'"] subscribeWithName:@"5thBeatle" onQueue:dispatch_get_main_queue() completion:^(RLMResults *results, NSError *error) {
        XCTAssertNil(error);
        XCTAssertEqual(results.count, 1U);
        [ex fulfill];
    }];
    [self waitForExpectationsWithTimeout:5.0 handler:nil];
}

- (void)testUnsubscribeWithinBlock {
    [self populateData:^(RLMRealm *realm) {
        Person *person = [[Person alloc] initWithPrimaryKey:[RLMObjectId objectId]
                                                        age:30
                                                  firstName:@"Joe"
                                                   lastName:@"Doe"];
        person.partition = self.name;
        [realm addObject:person];
    }];

    RLMRealm *realm = [self openRealm];
    CHECK_COUNT(0, Person, realm);

    XCTestExpectation *ex = [self expectationWithDescription:@"wait for download"];
    [[Person objectsInRealm:realm where:@"lastName == 'Doe' AND partition == %@", self.name]
     subscribeWithName:@"unknown" onQueue:dispatch_get_main_queue()
     completion:^(RLMResults *results, NSError *error) {
        XCTAssertNil(error);
        XCTAssertEqual(results.count, 1U);
        [results unsubscribe];
        [ex fulfill];
    }];
    [self waitForExpectationsWithTimeout:5.0 handler:nil];
    XCTAssertEqual(realm.subscriptions.count, 0U);
}

- (void)testSubscribeOnQueue {
    [self populateData:^(RLMRealm *realm) {
        Person *person = [[Person alloc] initWithPrimaryKey:[RLMObjectId objectId]
                                                        age:30
                                                  firstName:@"Sophia"
                                                   lastName:@"Loren"];
        person.partition = self.name;
        [realm addObject:person];
    }];

    RLMUser *user = [self createUser];
    RLMRealmConfiguration *config = [user flexibleSyncConfiguration];
    config.objectClasses = @[Person.self];

    XCTestExpectation *ex = [self expectationWithDescription:@"wait for download"];
    [self dispatchAsyncAndWait:^{
        RLMRealm *realm = [RLMRealm realmWithConfiguration:config error:nil];
        XCTAssertNotNil(realm);
        CHECK_COUNT(0, Person, realm);

        [[[Person allObjectsInRealm:realm] objectsWhere:@"lastName == 'Loren'"]
         subscribeWithCompletionOnQueue:dispatch_get_main_queue()
         completion:^(RLMResults *results, NSError *error) {
            XCTAssertNil(error);
            XCTAssertEqual(results.realm.subscriptions.count, 1UL);
            XCTAssertEqual(results.realm.subscriptions.state, RLMSyncSubscriptionStateComplete);
            CHECK_COUNT(1, Person, results.realm);
            [ex fulfill];
        }];
    }];
    [self waitForExpectationsWithTimeout:20.0 handler:nil];

    RLMRealm *realm = [RLMRealm realmWithConfiguration:config error:nil];
    XCTAssertEqual(realm.subscriptions.count, 1UL);
    CHECK_COUNT(1, Person, realm);
}

- (void)testSubscribeWithNameAndTimeout {
    [self populateData:^(RLMRealm *realm) {
        [self createPeople:realm];
    }];

    RLMRealm *realm = [self openRealm];
    XCTAssertNotNil(realm);
    CHECK_COUNT(0, Person, realm);

    [[realm syncSession] suspend];
    XCTestExpectation *ex = [self expectationWithDescription:@"expect timeout"];
    NSTimeInterval timeout = 2.0;
    RLMResults *res = [[Person allObjectsInRealm:realm] objectsWhere:@"age >= 20"];
    [res subscribeWithName:@"20up" waitForSync:RLMWaitForSyncModeAlways onQueue:dispatch_get_main_queue() timeout:timeout completion:^(RLMResults *results, NSError *error) {
        XCTAssert(error);
        NSString *expectedDesc = [NSString stringWithFormat:@"Waiting for update timed out after %.01f seconds.", timeout];
        XCTAssert([error.localizedDescription isEqualToString:expectedDesc]);
        XCTAssertNil(results);
        [ex fulfill];
    }];
    XCTAssertEqual(realm.subscriptions.count, 1UL);
    [self waitForExpectationsWithTimeout:5.0 handler:nil];

    // resume session and wait for complete
    // otherwise test will not tear down successfully
    [[realm syncSession] resume];
    NSDate * start = [[NSDate alloc] init];
    while (realm.subscriptions.state != RLMSyncSubscriptionStateComplete && start.timeIntervalSinceNow > -10.0) {
        sleep(1);
    }
    XCTAssertEqual(realm.subscriptions.state, RLMSyncSubscriptionStateComplete);
}

- (void)testFlexibleSyncInitialSubscriptionThrowsError {
    RLMUser *user = [self createUser];
    RLMRealmConfiguration *config = [user flexibleSyncConfigurationWithInitialSubscriptions:^(RLMSyncSubscriptionSet *subscriptions) {
        [subscriptions addSubscriptionWithClassName:UUIDPrimaryKeyObject.className
                                              where:@"strCol == %@", @"Tom"];
    } rerunOnOpen:false];
    config.objectClasses = @[UUIDPrimaryKeyObject.self];
    XCTestExpectation *ex = [self expectationWithDescription:@"download-realm"];
    [RLMRealm asyncOpenWithConfiguration:config
                           callbackQueue:dispatch_get_main_queue()
                                callback:^(RLMRealm *realm, NSError *error) {
        RLMValidateError(error, RLMErrorDomain, RLMErrorSubscriptionFailed,
                         @"Invalid query: unsupported query for table \"UUIDPrimaryKeyObject\": key \"strCol\" is not a queryable field");
        XCTAssertNil(realm);
        [ex fulfill];
    }];
    [self waitForExpectationsWithTimeout:30.0 handler:nil];
}
@end
