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

// These are defined in Swift. Importing the auto-generated header doesn't work
// when building with SPM, so just redeclare the bits we need.
@interface RealmServer : NSObject
+ (RealmServer *)shared;
- (NSString *)createAppWithQueryableFields:(NSArray *)queryableFields error:(NSError **)error;
@end

@interface RLMFlexibleSyncTestCase: RLMSyncTestCase
- (RLMRealm *)flexibleSyncRealmForUser:(RLMUser *)user;
@end

@implementation RLMFlexibleSyncTestCase {
    NSString *_flexibleSyncAppId;
    RLMApp *_flexibleSyncApp;
}

- (NSString *)flexibleSyncAppId {
    if (!_flexibleSyncAppId) {
        static NSString *s_appId;
        if (s_appId) {
            _flexibleSyncAppId = s_appId;
        }
        else {
            NSError *error;
            _flexibleSyncAppId = [RealmServer.shared createAppWithQueryableFields:@[@"age", @"breed", @"partition", @"firstName"] error:&error];
            if (error) {
                NSLog(@"Failed to create app: %@", error);
                abort();
            }

            s_appId = _flexibleSyncAppId;
        }
    }
    return _flexibleSyncAppId;
}

- (RLMApp *)flexibleSyncApp {
    if (!_flexibleSyncApp) {
        _flexibleSyncApp = [RLMApp appWithId:self.flexibleSyncAppId
                               configuration:self.defaultAppConfiguration
                               rootDirectory:self.clientDataRoot];
        RLMSyncManager *syncManager = self.flexibleSyncApp.syncManager;
        syncManager.logLevel = RLMSyncLogLevelTrace;
        syncManager.userAgent = self.name;
    }
    return _flexibleSyncApp;
}

- (RLMRealm *)flexibleSyncRealmForUser:(RLMUser *)user {
    RLMRealmConfiguration *config = [user flexibleSyncConfiguration];
    config.objectClasses = @[Dog.self,
                             Person.self];
    RLMRealm *realm = [RLMRealm realmWithConfiguration:config error:nil];
    [self waitForDownloadsForRealm:realm];
    return realm;
}

- (RLMRealm *)getFlexibleSyncRealm:(SEL)testSel {
    RLMUser *user = [self logInUserForCredentials:[self basicCredentialsWithName:NSStringFromSelector(testSel)
                                                                        register:YES
                                                                             app:self.flexibleSyncApp]
                                              app:self.flexibleSyncApp];
    RLMRealm *realm = [self flexibleSyncRealmForUser:user];
    XCTAssertNotNil(realm);
    return realm;
}

-(RLMRealm *)openFlexibleSyncRealm:(SEL)testSel {
    RLMUser *user = [self logInUserForCredentials:[self basicCredentialsWithName:NSStringFromSelector(testSel)
                                                                        register:YES
                                                                             app:self.flexibleSyncApp]
                                              app:self.flexibleSyncApp];
    RLMRealmConfiguration *config = [user flexibleSyncConfiguration];
    config.objectClasses = @[Dog.self,
                             Person.self];
    RLMRealm *realm = [RLMRealm realmWithConfiguration:config error:nil];
    XCTAssertNotNil(realm);
    return realm;
}

- (void)populateData:(void (^)(RLMRealm *))block {
    [self writeToFlxRealm:^(RLMRealm *realm) {
        [realm beginWriteTransaction];
        block(realm);
        [realm commitWriteTransaction];
        [self waitForUploadsForRealm:realm];
    }];
}

- (void)writeToFlxRealm:(void (^)(RLMRealm *))block {
    NSString *userName = [NSStringFromSelector(_cmd) stringByAppendingString:[NSUUID UUID].UUIDString];
    RLMUser *user = [self logInUserForCredentials:[self basicCredentialsWithName:userName
                                                                        register:YES
                                                                             app:self.flexibleSyncApp]
                                              app:self.flexibleSyncApp];
    RLMRealmConfiguration *config = [user flexibleSyncConfiguration];
    config.objectClasses = @[Dog.self,
                             Person.self];
    RLMRealm *realm = [RLMRealm realmWithConfiguration:config error:nil];

    RLMSyncSubscriptionSet *subs = realm.subscriptions;
    [subs write:^{
        [subs addSubscriptionWithClassName:Person.className
                          subscriptionName:@"person_all"
                                     where:@"TRUEPREDICATE"];
        [subs addSubscriptionWithClassName:Dog.className
                          subscriptionName:@"dog_all"
                                     where:@"TRUEPREDICATE"];
    }];

    XCTAssertNotNil(subs);
    XCTAssertEqual(subs.version, 1);
    XCTAssertEqual(subs.count, 2);

    XCTestExpectation *ex = [self expectationWithDescription:@"state changes"];
    [subs observe:^(RLMSyncSubscriptionState state) {
        if (state == RLMSyncSubscriptionStateComplete) {
            [ex fulfill];
        }
    }];
    [self waitForExpectationsWithTimeout:20.0 handler:nil];
    block(realm);
}
- (void)writeQueryAndCompleteForRealm:(RLMRealm *)realm block:(void (^)(RLMSyncSubscriptionSet *))block {
    RLMSyncSubscriptionSet *subs = realm.subscriptions;
    XCTAssertNotNil(subs);

    [subs write:^{
        block(subs);
    }];
    XCTAssertNotNil(subs);

    XCTestExpectation *ex = [self expectationWithDescription:@"state changes"];
    [subs observe:^(RLMSyncSubscriptionState state) {
        if (state == RLMSyncSubscriptionStateComplete) {
            [ex fulfill];
        }
    }];
    [self waitForExpectationsWithTimeout:20.0 handler:nil];
    [self waitForDownloadsForRealm:realm];
}
@end

@interface RLMFlexibleSyncTests: RLMFlexibleSyncTestCase
@end

@implementation RLMFlexibleSyncTests
- (void)testCreateFlexibleSyncApp {
    NSString *appId =  [RealmServer.shared createAppWithQueryableFields:@[@"age", @"breed"]
                                                                  error:nil];
    RLMApp *app = [RLMApp appWithId:appId
                      configuration:[self defaultAppConfiguration]
                      rootDirectory:[self clientDataRoot]];
    XCTAssertNotNil(app);
}

- (void)testFlexibleSyncOpenRealm {
    XCTAssertNotNil([self openFlexibleSyncRealm:_cmd]);
}

- (void)testGetSubscriptionsWhenLocalRealm {
    RLMRealm *realm = [RLMRealm defaultRealm];
    RLMAssertThrowsWithReason(realm.subscriptions, @"Realm was not build for a sync session");
}

- (void)testGetSubscriptionsWhenPbsRealm {
    RLMRealm *realm = [self realmForTest:_cmd];
    RLMAssertThrowsWithReason(realm.subscriptions, @"Realm sync session is not Flexible Sync");
}

- (void)testGetSubscriptionsWhenFlexibleSync {
    RLMRealm *realm = [self openFlexibleSyncRealm:_cmd];
    RLMSyncSubscriptionSet *subs = realm.subscriptions;
    XCTAssertNotNil(subs);
    XCTAssertEqual(subs.version, 0);
    XCTAssertEqual(subs.count, 0);
}

- (void)testGetSubscriptionsWhenSameVersion {
    RLMRealm *realm = [self openFlexibleSyncRealm:_cmd];
    RLMSyncSubscriptionSet *subs1 = realm.subscriptions;
    RLMSyncSubscriptionSet *subs2 = realm.subscriptions;
    XCTAssertEqual(subs1.version, 0);
    XCTAssertEqual(subs2.version, 0);
}

- (void)testCheckVersionAfterAddSubscription {
    RLMRealm *realm = [self openFlexibleSyncRealm:_cmd];
    RLMSyncSubscriptionSet *subs = realm.subscriptions;
    XCTAssertNotNil(subs);
    XCTAssertEqual(subs.version, 0);
    XCTAssertEqual(subs.count, 0);

    [subs write:^{
        [subs addSubscriptionWithClassName:Person.className
                                     where:@"age > 15"];
    }];

    XCTAssertEqual(subs.version, 1);
    XCTAssertEqual(subs.count, 1);
}

- (void)testEmptyWriteSubscriptions {
    RLMRealm *realm = [self openFlexibleSyncRealm:_cmd];
    RLMSyncSubscriptionSet *subs = realm.subscriptions;
    XCTAssertNotNil(subs);
    XCTAssertEqual(subs.version, 0);
    XCTAssertEqual(subs.count, 0);

    [subs write:^{
    }];

    XCTAssertEqual(subs.version, 1);
    XCTAssertEqual(subs.count, 0);
}

- (void)testAddAndFindSubscriptionByQuery {
    RLMRealm *realm = [self openFlexibleSyncRealm:_cmd];
    RLMSyncSubscriptionSet *subs = realm.subscriptions;

    [subs write:^{
        [subs addSubscriptionWithClassName:Person.className
                                     where:@"age > 15"];
    }];

    RLMSyncSubscription *foundSubscription = [subs subscriptionWithClassName:Person.className
                                                                       where:@"age > 15"];
    XCTAssertNotNil(foundSubscription);
    XCTAssert(foundSubscription.name, @"");
    XCTAssert(foundSubscription.queryString, @"age > 15");
}

- (void)testAddAndFindSubscriptionWithComplexQuery {
    RLMRealm *realm = [self openFlexibleSyncRealm:_cmd];
    RLMSyncSubscriptionSet *subs = realm.subscriptions;
    XCTAssertNotNil(subs);
    XCTAssertEqual(subs.version, 0);
    XCTAssertEqual(subs.count, 0);

    [subs write:^{
        [subs addSubscriptionWithClassName:Person.className
                                     where:@"firstName BEGINSWITH %@ and lastName == %@", @"J", @"Doe"];
    }];

    XCTAssertEqual(subs.version, 1);
    XCTAssertEqual(subs.count, 1);

    RLMSyncSubscription *foundSubscription = [subs subscriptionWithClassName:Person.className
                                                                       where:@"firstName BEGINSWITH %@ and lastName == %@", @"J", @"Doe"];
    XCTAssertNotNil(foundSubscription);
    XCTAssert(foundSubscription.name, @"");
    XCTAssert(foundSubscription.queryString, @"firstName BEGINSWITH 'J' and lastName == 'Doe'");
}

- (void)testAddAndFindSubscriptionWithPredicate {
    RLMRealm *realm = [self openFlexibleSyncRealm:_cmd];
    RLMSyncSubscriptionSet *subs = realm.subscriptions;
    XCTAssertNotNil(subs);
    XCTAssertEqual(subs.version, 0);
    XCTAssertEqual(subs.count, 0);

    [subs write:^{
        [subs addSubscriptionWithClassName:Person.className
                                 predicate:[NSPredicate predicateWithFormat:@"age == %d", 20]];
    }];

    XCTAssertEqual(subs.version, 1);
    XCTAssertEqual(subs.count, 1);

    RLMSyncSubscription *foundSubscription = [subs subscriptionWithClassName:Person.className
                                                                   predicate:[NSPredicate predicateWithFormat:@"age == %d", 20]];
    XCTAssertNotNil(foundSubscription);
    XCTAssert(foundSubscription.name, @"");
    XCTAssert(foundSubscription.queryString, @"age == 20");
}

- (void)testAddSubscriptionWithoutWriteThrow {
    RLMRealm *realm = [self openFlexibleSyncRealm:_cmd];
    RLMSyncSubscriptionSet *subs = realm.subscriptions;
    RLMAssertThrowsWithReason([subs addSubscriptionWithClassName:Person.className where:@"age > 15"],
                              @"Can only add, remove, or update subscriptions within a write subscription block.");
}

- (void)testAddAndFindSubscriptionByName {
    RLMRealm *realm = [self openFlexibleSyncRealm:_cmd];
    RLMSyncSubscriptionSet *subs = realm.subscriptions;
    XCTAssertNotNil(realm.subscriptions);
    XCTAssertEqual(realm.subscriptions.version, 0);
    XCTAssertEqual(realm.subscriptions.count, 0);

    [subs write:^{
        [subs addSubscriptionWithClassName:Person.className
                          subscriptionName:@"person_older_15"
                                     where:@"age > 15"];
    }];

    RLMSyncSubscription *foundSubscription = [subs subscriptionWithName:@"person_older_15"];
    XCTAssertNotNil(foundSubscription);
    XCTAssert(foundSubscription.name, @"person_older_15");
    XCTAssert(foundSubscription.queryString, @"age > 15");
}

- (void)testAddDuplicateSubscription {
    RLMRealm *realm = [self openFlexibleSyncRealm:_cmd];
    RLMSyncSubscriptionSet *subs = realm.subscriptions;

    [subs write:^{
        [subs addSubscriptionWithClassName:Person.className
                                     where:@"age > 15"];
        [subs addSubscriptionWithClassName:Person.className
                                     where:@"age > 15"];
    }];

    XCTAssertEqual(subs.version, 1);
    XCTAssertEqual(subs.count, 1);
}

- (void)testAddDuplicateSubscriptionWithPredicate {
    RLMRealm *realm = [self openFlexibleSyncRealm:_cmd];
    RLMSyncSubscriptionSet *subs = realm.subscriptions;

    [subs write:^{
        [subs addSubscriptionWithClassName:Person.className
                                     where:@"age > 15"];
        [subs addSubscriptionWithClassName:Person.className
                                 predicate:[NSPredicate predicateWithFormat:@"age > %d", 15]];
    }];

    XCTAssertEqual(subs.version, 1);
    XCTAssertEqual(subs.count, 1);
}

- (void)testAddDuplicateSubscriptionWithDifferentName {
    RLMRealm *realm = [self openFlexibleSyncRealm:_cmd];
    RLMSyncSubscriptionSet *subs = realm.subscriptions;

    [subs write:^{
        [subs addSubscriptionWithClassName:Person.className
                          subscriptionName:@"person_age_1"
                                     where:@"age > 15"];
        [subs addSubscriptionWithClassName:Person.className
                          subscriptionName:@"person_age_2"
                                 predicate:[NSPredicate predicateWithFormat:@"age > %d", 15]];
    }];

    XCTAssertEqual(subs.version, 1);
    XCTAssertEqual(subs.count, 2);

    RLMSyncSubscription *foundSubscription = [subs subscriptionWithName:@"person_age_1"];
    XCTAssertNotNil(foundSubscription);

    RLMSyncSubscription *foundSubscription2 = [subs subscriptionWithName:@"person_age_2"];
    XCTAssertNotNil(foundSubscription2);

    XCTAssertNotEqualObjects(foundSubscription.name, foundSubscription2.name);
    XCTAssertEqualObjects(foundSubscription.queryString, foundSubscription2.queryString);
    XCTAssertEqualObjects(foundSubscription.objectClassName, foundSubscription2.objectClassName);
}

// An unnamed subscription should not override a named one, this should create a subscription with a different name, (there is a bug in core, that's why this is failing)
- (void)testOverrideNamedWithUnnamedSubscription {
    RLMRealm *realm = [self openFlexibleSyncRealm:_cmd];
    RLMSyncSubscriptionSet *subs = realm.subscriptions;

    [subs write:^{
        [subs addSubscriptionWithClassName:Person.className
                          subscriptionName:@"person_age_1"
                                     where:@"age > 15"];
        [subs addSubscriptionWithClassName:Person.className
                                 predicate:[NSPredicate predicateWithFormat:@"age > %d", 15]];
    }];

    XCTAssertEqual(subs.version, 1);
    XCTAssertEqual(subs.count, 2);
}

- (void)testOverrideUnnamedWithNamedSubscription {
    RLMRealm *realm = [self openFlexibleSyncRealm:_cmd];
    RLMSyncSubscriptionSet *subs = realm.subscriptions;

    [subs write:^{
        [subs addSubscriptionWithClassName:Person.className
                                 predicate:[NSPredicate predicateWithFormat:@"age > %d", 15]];
        [subs addSubscriptionWithClassName:Person.className
                          subscriptionName:@"person_age_1"
                                     where:@"age > 15"];
    }];

    XCTAssertEqual(subs.version, 1);
    XCTAssertEqual(subs.count, 2);
}

- (void)testAddSubscriptionInDifferentWriteBlocks {
    RLMRealm *realm = [self openFlexibleSyncRealm:_cmd];
    RLMSyncSubscriptionSet *subs = realm.subscriptions;

    [subs write:^{
        [subs addSubscriptionWithClassName:Person.className
                          subscriptionName:@"person_age_1"
                                     where:@"age > 15"];
    }];

    [subs write:^{
        [subs addSubscriptionWithClassName:Person.className
                          subscriptionName:@"person_age_2"
                                 predicate:[NSPredicate predicateWithFormat:@"age > %d", 20]];
    }];

    XCTAssertEqual(realm.subscriptions.version, 2);
    XCTAssertEqual(realm.subscriptions.count, 2);

    RLMSyncSubscription *foundSubscription = [subs subscriptionWithName:@"person_age_1"];
    XCTAssertNotNil(foundSubscription);

    RLMSyncSubscription *foundSubscription2 = [subs subscriptionWithName:@"person_age_2"];
    XCTAssertNotNil(foundSubscription2);
}

- (void)testRemoveSubscriptionByName {
    RLMRealm *realm = [self openFlexibleSyncRealm:_cmd];
    RLMSyncSubscriptionSet *subs = realm.subscriptions;

    [subs write:^{
        [subs addSubscriptionWithClassName:Person.className
                          subscriptionName:@"person_age_1"
                                     where:@"age > 15"];
        [subs addSubscriptionWithClassName:Person.className
                          subscriptionName:@"person_age_2"
                                 predicate:[NSPredicate predicateWithFormat:@"age > %d", 20]];
    }];

    XCTAssertEqual(subs.version, 1);
    XCTAssertEqual(subs.count, 2);

    [subs write:^{
        [subs removeSubscriptionWithName:@"person_age_1"];
    }];

    XCTAssertEqual(subs.version, 2);
    XCTAssertEqual(subs.count, 1);

    RLMSyncSubscription *foundSubscription = [subs subscriptionWithName:@"person_age_1"];
    XCTAssertNil(foundSubscription);

    RLMSyncSubscription *foundSubscription2 = [subs subscriptionWithName:@"person_age_2"];
    XCTAssertNotNil(foundSubscription2);
}

- (void)testRemoveSubscriptionWithoutWriteThrow {
    RLMRealm *realm = [self openFlexibleSyncRealm:_cmd];
    RLMSyncSubscriptionSet *subs = realm.subscriptions;

    [subs write:^{
        [subs addSubscriptionWithClassName:Person.className
                          subscriptionName:@"person_age_1"
                                     where:@"age > 15"];
    }];

    XCTAssertEqual(subs.version, 1);
    XCTAssertEqual(subs.count, 1);
    RLMAssertThrowsWithReason([subs removeSubscriptionWithName:@"person_age_1"], @"Can only add, remove, or update subscriptions within a write subscription block.");
}

- (void)testRemoveSubscriptionByQuery {
    RLMRealm *realm = [self openFlexibleSyncRealm:_cmd];
    RLMSyncSubscriptionSet *subs = realm.subscriptions;

    [subs write:^{
        [subs addSubscriptionWithClassName:Person.className
                          subscriptionName:@"person_age"
                                     where:@"age > 15"];
        [subs addSubscriptionWithClassName:Person.className
                          subscriptionName:@"person_firstname"
                                     where:@"firstName == '%@'", @"John"];
        [subs addSubscriptionWithClassName:Person.className
                          subscriptionName:@"person_lastname"
                                 predicate:[NSPredicate predicateWithFormat:@"lastName BEGINSWITH %@", @"A"]];
    }];

    XCTAssertEqual(subs.version, 1);
    XCTAssertEqual(subs.count, 3);

    [subs write:^{
        [subs removeSubscriptionWithClassName:Person.className where:@"firstName == '%@'", @"John"];
        [subs removeSubscriptionWithClassName:Person.className predicate:[NSPredicate predicateWithFormat:@"lastName BEGINSWITH %@", @"A"]];
    }];
    
    XCTAssertEqual(subs.version, 2);
    XCTAssertEqual(subs.count, 1);

    RLMSyncSubscription *foundSubscription = [subs subscriptionWithName:@"person_age"];
    XCTAssertNotNil(foundSubscription);

    RLMSyncSubscription *foundSubscription2 = [subs subscriptionWithName:@"person_firstname"];
    XCTAssertNil(foundSubscription2);

    RLMSyncSubscription *foundSubscription3 = [subs subscriptionWithName:@"person_lastname"];
    XCTAssertNil(foundSubscription3);
}

- (void)testRemoveSubscription {
    RLMRealm *realm = [self openFlexibleSyncRealm:_cmd];
    RLMSyncSubscriptionSet *subs = realm.subscriptions;

    [subs write:^{
        [subs addSubscriptionWithClassName:Person.className
                          subscriptionName:@"person_age"
                                     where:@"age > 15"];
        [subs addSubscriptionWithClassName:Person.className
                          subscriptionName:@"person_firstname"
                                     where:@"firstName == '%@'", @"John"];
        [subs addSubscriptionWithClassName:Person.className
                          subscriptionName:@"person_lastname"
                                 predicate:[NSPredicate predicateWithFormat:@"lastName BEGINSWITH %@", @"A"]];
    }];

    XCTAssertEqual(subs.version, 1);
    XCTAssertEqual(subs.count, 3);

    RLMSyncSubscription *foundSubscription = [subs subscriptionWithName:@"person_age"];
    XCTAssertNotNil(foundSubscription);

    [subs write:^{
        [subs removeSubscription:foundSubscription];
    }];

    XCTAssertEqual(subs.version, 2);
    XCTAssertEqual(subs.count, 2);

    RLMSyncSubscription *foundSubscription2 = [subs subscriptionWithName:@"person_firstname"];
    XCTAssertNotNil(foundSubscription2);

    [subs write:^{
        [subs removeSubscription:foundSubscription2];
    }];

    XCTAssertEqual(subs.version, 3);
    XCTAssertEqual(subs.count, 1);
}

- (void)testRemoveAllSubscription {
    RLMRealm *realm = [self openFlexibleSyncRealm:_cmd];
    RLMSyncSubscriptionSet *subs = realm.subscriptions;

    [subs write:^{
        [subs addSubscriptionWithClassName:Person.className
                          subscriptionName:@"person_age"
                                     where:@"age > 15"];
        [subs addSubscriptionWithClassName:Person.className
                          subscriptionName:@"person_firstname"
                                     where:@"firstName == '%@'", @"John"];
        [subs addSubscriptionWithClassName:Person.className
                          subscriptionName:@"person_lastname"
                                 predicate:[NSPredicate predicateWithFormat:@"lastName BEGINSWITH %@", @"A"]];
    }];

    XCTAssertEqual(subs.version, 1);
    XCTAssertEqual(subs.count, 3);

    [subs write:^{
        [subs removeAllSubscriptions];
    }];

    XCTAssertEqual(subs.version, 2);
    XCTAssertEqual(subs.count, 0);

    RLMSyncSubscription *foundSubscription = [subs subscriptionWithName:@"person_age_3"];
    XCTAssertNil(foundSubscription);
}

- (void)testRemoveAllSubscriptionForType {
    RLMRealm *realm = [self openFlexibleSyncRealm:_cmd];
    RLMSyncSubscriptionSet *subs = realm.subscriptions;

    [subs write:^{
        [subs addSubscriptionWithClassName:Person.className
                          subscriptionName:@"person_age"
                                     where:@"age > 15"];
        [subs addSubscriptionWithClassName:Dog.className
                          subscriptionName:@"dog_name"
                                     where:@"name == '%@'", @"Tomas"];
        [subs addSubscriptionWithClassName:Person.className
                          subscriptionName:@"person_lastname"
                                 predicate:[NSPredicate predicateWithFormat:@"lastName BEGINSWITH %@", @"A"]];
    }];

    XCTAssertEqual(subs.version, 1);
    XCTAssertEqual(subs.count, 3);

    [subs write:^{
        [subs removeAllSubscriptionsWithClassName:Person.className];
    }];

    XCTAssertEqual(subs.version, 2);
    XCTAssertEqual(subs.count, 1);

    RLMSyncSubscription *foundSubscription = [subs subscriptionWithName:@"dog_name"];
    XCTAssertNotNil(foundSubscription);

    [subs write:^{
        [subs removeAllSubscriptionsWithClassName:Dog.className];
    }];

    XCTAssertEqual(subs.version, 3);
    XCTAssertEqual(subs.count, 0);
}

- (void)testUpdateSubscriptionQueryWithSameClassName {
    RLMRealm *realm = [self openFlexibleSyncRealm:_cmd];
    RLMSyncSubscriptionSet *subs = realm.subscriptions;

    [subs write:^{
        [subs addSubscriptionWithClassName:Person.className
                          subscriptionName:@"person_age"
                                     where:@"age > 15"];
    }];

    XCTAssertEqual(subs.version, 1);
    XCTAssertEqual(subs.count, 1);

    RLMSyncSubscription *foundSubscription = [subs subscriptionWithName:@"person_age"];
    XCTAssertNotNil(foundSubscription);

    [subs write:^{
        [foundSubscription updateSubscriptionWithClassName:Person.className where:@"age > 20"];
    }];

    XCTAssertEqual(subs.version, 2);
    XCTAssertEqual(subs.count, 1);

    RLMSyncSubscription *foundSubscription2 = [subs subscriptionWithName:@"person_age"];
    XCTAssertNotNil(foundSubscription2);
    XCTAssertEqualObjects(foundSubscription2.queryString, @"age > 20");
    XCTAssertEqualObjects(foundSubscription2.objectClassName, @"Person");
}

- (void)testUpdateSubscriptionQueryWithDifferentClassName {
    RLMRealm *realm = [self openFlexibleSyncRealm:_cmd];
    RLMSyncSubscriptionSet *subs = realm.subscriptions;

    [subs write:^{
        [subs addSubscriptionWithClassName:Person.className
                          subscriptionName:@"subscription_1"
                                     where:@"age > 15"];
    }];

    XCTAssertEqual(subs.version, 1);
    XCTAssertEqual(subs.count, 1);

    RLMSyncSubscription *foundSubscription = [subs subscriptionWithName:@"subscription_1"];
    XCTAssertNotNil(foundSubscription);

    [subs write:^{
        [foundSubscription updateSubscriptionWithClassName:Dog.className predicate:[NSPredicate predicateWithFormat:@"name == 'Tomas'"]];
    }];

    XCTAssertEqual(subs.version, 2);
    XCTAssertEqual(subs.count, 1);

    RLMSyncSubscription *foundSubscription2 = [subs subscriptionWithName:@"subscription_1"];
    XCTAssertNotNil(foundSubscription2);
    XCTAssertEqualObjects(foundSubscription2.queryString, @"name == \"Tomas\"");
    XCTAssertEqualObjects(foundSubscription2.objectClassName, @"Dog");
}

- (void)testUpdateSubscriptionQueryWithoutWriteThrow {
    RLMRealm *realm = [self openFlexibleSyncRealm:_cmd];
    RLMSyncSubscriptionSet *subs = realm.subscriptions;

    [subs write:^{
        [subs addSubscriptionWithClassName:Person.className
                          subscriptionName:@"subscription_1"
                                     where:@"age > 15"];
    }];

    XCTAssertEqual(subs.version, 1);
    XCTAssertEqual(subs.count, 1);

    RLMSyncSubscription *foundSubscription = [subs subscriptionWithName:@"subscription_1"];
    XCTAssertNotNil(foundSubscription);

    RLMAssertThrowsWithReason([foundSubscription updateSubscriptionWithClassName:Dog.className predicate:[NSPredicate predicateWithFormat:@"name == 'Tomas'"]], @"Can only add, remove, or update subscriptions within a write subscription block.");
}

- (void)testSubscriptionSetIterate {
    RLMRealm *realm = [self openFlexibleSyncRealm:_cmd];
    RLMSyncSubscriptionSet *subs = realm.subscriptions;

    int numberOfSubs = 100;
    [subs write:^{
        for (int i = 0; i < numberOfSubs; ++i) {
            [subs addSubscriptionWithClassName:Person.className
                              subscriptionName:[NSString stringWithFormat:@"person_age_%d", i]
                                         where:[NSString stringWithFormat:@"age > %d", i]];
        }
    }];

    XCTAssertEqual(subs.version, 1);
    XCTAssertEqual(subs.count, numberOfSubs);

    __weak id objects[numberOfSubs];
    NSInteger count = 0;
    for(RLMSyncSubscription *sub in subs) {
        XCTAssertNotNil(sub);
        objects[count++] = sub;
    }
    XCTAssertEqual(count, numberOfSubs);
}

- (void)testSubscriptionSetFirstAndLast {
    RLMRealm *realm = [self openFlexibleSyncRealm:_cmd];
    RLMSyncSubscriptionSet *subs = realm.subscriptions;

    XCTAssertNil(subs.firstObject);
    XCTAssertNil(subs.lastObject);

    int numberOfSubs = 20;
    [subs write:^{
        for (int i = 1; i <= numberOfSubs; ++i) {
            [subs addSubscriptionWithClassName:Person.className
                              subscriptionName:[NSString stringWithFormat:@"person_age_%d", i]
                                         where:[NSString stringWithFormat:@"age > %d", i]];
        }
    }];

    XCTAssertEqual(subs.version, 1);
    XCTAssertEqual(subs.count, numberOfSubs);

    RLMSyncSubscription *firstSubscription = subs.firstObject;
    XCTAssertEqualObjects(firstSubscription.name, @"person_age_1");
    XCTAssertEqualObjects(firstSubscription.queryString, @"age > 1");

    RLMSyncSubscription *lastSubscription = subs.lastObject;
    XCTAssertEqualObjects(lastSubscription.name, ([NSString stringWithFormat:@"person_age_%d", numberOfSubs]));
    XCTAssertEqualObjects(lastSubscription.queryString, ([NSString stringWithFormat:@"age > %d", numberOfSubs]));
}

- (void)testSubscriptionSetSubscript {
    RLMRealm *realm = [self openFlexibleSyncRealm:_cmd];
    RLMSyncSubscriptionSet *subs = realm.subscriptions;

    XCTAssertEqual(subs.count, 0);

    int numberOfSubs = 20;
    [subs write:^{
        for (int i = 1; i <= numberOfSubs; ++i) {
            [subs addSubscriptionWithClassName:Person.className
                              subscriptionName:[NSString stringWithFormat:@"person_age_%d", i]
                                         where:[NSString stringWithFormat:@"age > %d", i]];
        }
    }];

    XCTAssertEqual(subs.version, 1);
    XCTAssertEqual(subs.count, numberOfSubs);

    RLMSyncSubscription *firstSubscription = subs[0];
    XCTAssertEqualObjects(firstSubscription.name, @"person_age_1");
    XCTAssertEqualObjects(firstSubscription.queryString, @"age > 1");

    RLMSyncSubscription *lastSubscription = subs[numberOfSubs-1];
    XCTAssertEqualObjects(lastSubscription.name, ([NSString stringWithFormat:@"person_age_%d", numberOfSubs]));
    XCTAssertEqualObjects(lastSubscription.queryString, ([NSString stringWithFormat:@"age > %d", numberOfSubs]));

    int index = (numberOfSubs/2);
    RLMSyncSubscription *objectAtIndexSubscription = [subs objectAtIndex:index];
    XCTAssertEqualObjects(objectAtIndexSubscription.name, ([NSString stringWithFormat:@"person_age_%d", index+1]));
    XCTAssertEqualObjects(objectAtIndexSubscription.queryString, ([NSString stringWithFormat:@"age > %d", index+1]));
}
@end

@interface RLMFlexibleSyncServerTests: RLMFlexibleSyncTestCase
@end

@implementation RLMFlexibleSyncServerTests
- (void)testFlexibleSyncWithoutQuery {
    [self populateData:^(RLMRealm *realm) {
        int numberOfSubs = 21;
        for (int i = 1; i <= numberOfSubs; ++i) {
            Person *person = [[Person alloc] initWithPrimaryKey:[RLMObjectId objectId]
                                                            age:i
                                                      firstName:[NSString stringWithFormat:@"firstname_%d", i]
                                                       lastName:[NSString stringWithFormat:@"lastname_%d", i]];
            person.partition = NSStringFromSelector(_cmd);
            [realm addObject: person];
        }
    }];
    RLMRealm *realm = [self getFlexibleSyncRealm:_cmd];
    XCTAssertNotNil(realm);
    CHECK_COUNT(0, Person, realm);

    RLMSyncSubscriptionSet *subs = realm.subscriptions;
    XCTAssertNotNil(subs);
    XCTAssertEqual(subs.version, 0);
    XCTAssertEqual(subs.count, 0);

    [self waitForDownloadsForRealm:realm];
    CHECK_COUNT(0, Person, realm);
    CHECK_COUNT(0, Dog, realm);
}

- (void)testFlexibleSyncAddQuery {
    [self populateData:^(RLMRealm *realm) {
        int numberOfSubs = 21;
        for (int i = 1; i <= numberOfSubs; ++i) {
            Person *person = [[Person alloc] initWithPrimaryKey:[RLMObjectId objectId]
                                                            age:i
                                                      firstName:[NSString stringWithFormat:@"firstname_%d", i]
                                                       lastName:[NSString stringWithFormat:@"lastname_%d", i]];
            person.partition = NSStringFromSelector(_cmd);
            [realm addObject: person];
        }
    }];

    RLMRealm *realm = [self getFlexibleSyncRealm:_cmd];
    XCTAssertNotNil(realm);
    CHECK_COUNT(0, Person, realm);

    [self writeQueryAndCompleteForRealm:realm block:^(RLMSyncSubscriptionSet *subs) {
        [subs addSubscriptionWithClassName:Person.className
                          subscriptionName:@"person_age"
                                     where:@"age > 15 and partition == %@", NSStringFromSelector(_cmd)];
    }];

    CHECK_COUNT(6, Person, realm);
    CHECK_COUNT(0, Dog, realm);
}

- (void)testFlexibleSyncAddMultipleQuery {
    [self populateData:^(RLMRealm *realm) {
        int numberOfSubs = 21;
        for (int i = 1; i <= numberOfSubs; ++i) {
            Person *person = [[Person alloc] initWithPrimaryKey:[RLMObjectId objectId]
                                                            age:i
                                                      firstName:[NSString stringWithFormat:@"firstname_%d", i]
                                                       lastName:[NSString stringWithFormat:@"lastname_%d", i]];
            person.partition = NSStringFromSelector(_cmd);
            [realm addObject: person];
        }
        Dog *dog = [[Dog alloc] initWithPrimaryKey:[RLMObjectId objectId]
                                             breed:@"Labradoodle"
                                              name:@"Tom"];
        dog.partition = NSStringFromSelector(_cmd);
        [realm addObject: dog];
    }];

    RLMRealm *realm = [self getFlexibleSyncRealm:_cmd];
    XCTAssertNotNil(realm);
    CHECK_COUNT(0, Person, realm);

    [self writeQueryAndCompleteForRealm:realm block:^(RLMSyncSubscriptionSet *subs) {
        [subs addSubscriptionWithClassName:Person.className
                          subscriptionName:@"person_age"
                                     where:@"age > 10 and partition == %@", NSStringFromSelector(_cmd)];
        [subs addSubscriptionWithClassName:Dog.className
                          subscriptionName:@"dog_breed_labradoodle"
                                     where:@"breed == 'Labradoodle' and partition == %@", NSStringFromSelector(_cmd)];
    }];

    CHECK_COUNT(11, Person, realm);
    CHECK_COUNT(1, Dog, realm);
}

- (void)testFlexibleSyncRemoveQuery {
    [self populateData:^(RLMRealm *realm) {
        int numberOfSubs = 21;
        for (int i = 1; i <= numberOfSubs; ++i) {
            Person *person = [[Person alloc] initWithPrimaryKey:[RLMObjectId objectId]
                                                            age:i
                                                      firstName:[NSString stringWithFormat:@"firstname_%d", i]
                                                       lastName:[NSString stringWithFormat:@"lastname_%d", i]];
            person.partition = NSStringFromSelector(_cmd);
            [realm addObject: person];
        }
        Dog *dog = [[Dog alloc] initWithPrimaryKey:[RLMObjectId objectId]
                                             breed:@"Labradoodle"
                                              name:@"Tom"];
        dog.partition = NSStringFromSelector(_cmd);
        [realm addObject: dog];
    }];

    RLMRealm *realm = [self getFlexibleSyncRealm:_cmd];
    XCTAssertNotNil(realm);
    CHECK_COUNT(0, Person, realm);

    [self writeQueryAndCompleteForRealm:realm block:^(RLMSyncSubscriptionSet *subs) {
        [subs addSubscriptionWithClassName:Person.className
                          subscriptionName:@"person_age"
                                     where:@"age > 5 and partition == %@", NSStringFromSelector(_cmd)];
        [subs addSubscriptionWithClassName:Dog.className
                          subscriptionName:@"dog_breed_labradoodle"
                                     where:@"breed == 'Labradoodle' and partition == %@", NSStringFromSelector(_cmd)];
    }];
    CHECK_COUNT(16, Person, realm);
    CHECK_COUNT(1, Dog, realm);

    [self writeQueryAndCompleteForRealm:realm block:^(RLMSyncSubscriptionSet *subs) {
        [subs removeSubscriptionWithName:@"person_age"];
    }];
    CHECK_COUNT(0, Person, realm)
    CHECK_COUNT(1, Dog, realm);
}

- (void)testFlexibleSyncRemoveAllQueries {
    [self populateData:^(RLMRealm *realm) {
        int numberOfSubs = 21;
        for (int i = 1; i <= numberOfSubs; ++i) {
            Person *person = [[Person alloc] initWithPrimaryKey:[RLMObjectId objectId]
                                                            age:i
                                                      firstName:[NSString stringWithFormat:@"firstname_%d", i]
                                                       lastName:[NSString stringWithFormat:@"lastname_%d", i]];
            person.partition = NSStringFromSelector(_cmd);
            [realm addObject: person];
        }
        Dog *dog = [[Dog alloc] initWithPrimaryKey:[RLMObjectId objectId]
                                             breed:@"Labradoodle"
                                              name:@"Tom"];
        dog.partition = NSStringFromSelector(_cmd);
        [realm addObject: dog];
    }];

    RLMRealm *realm = [self getFlexibleSyncRealm:_cmd];
    XCTAssertNotNil(realm);
    CHECK_COUNT(0, Person, realm);

    [self writeQueryAndCompleteForRealm:realm block:^(RLMSyncSubscriptionSet *subs) {
        [subs addSubscriptionWithClassName:Person.className
                          subscriptionName:@"person_age"
                                     where:@"age > 5 and partition == %@", NSStringFromSelector(_cmd)];
        [subs addSubscriptionWithClassName:Dog.className
                          subscriptionName:@"dog_breed_labradoodle"
                                     where:@"breed == 'Labradoodle' and partition == %@", NSStringFromSelector(_cmd)];
    }];
    CHECK_COUNT(16, Person, realm);
    CHECK_COUNT(1, Dog, realm);

    [self writeQueryAndCompleteForRealm:realm block:^(RLMSyncSubscriptionSet *subs) {
        [subs removeAllSubscriptions];
        [subs addSubscriptionWithClassName:Person.className
                          subscriptionName:@"person_age"
                                     where:@"age > 0 and partition == %@", NSStringFromSelector(_cmd)];
    }];
    CHECK_COUNT(21, Person, realm)
    CHECK_COUNT(0, Dog, realm);
}

- (void)testFlexibleSyncRemoveAllQueriesForType {
    [self populateData:^(RLMRealm *realm) {
        int numberOfSubs = 21;
        for (int i = 1; i <= numberOfSubs; ++i) {
            Person *person = [[Person alloc] initWithPrimaryKey:[RLMObjectId objectId]
                                                            age:i
                                                      firstName:[NSString stringWithFormat:@"firstname_%d", i]
                                                       lastName:[NSString stringWithFormat:@"lastname_%d", i]];
            person.partition = NSStringFromSelector(_cmd);
            [realm addObject: person];
        }
        Dog *dog = [[Dog alloc] initWithPrimaryKey:[RLMObjectId objectId]
                                             breed:@"Labradoodle"
                                              name:@"Tom"];
        dog.partition = NSStringFromSelector(_cmd);
        [realm addObject: dog];
    }];

    RLMRealm *realm = [self getFlexibleSyncRealm:_cmd];
    XCTAssertNotNil(realm);
    CHECK_COUNT(0, Person, realm);

    [self writeQueryAndCompleteForRealm:realm block:^(RLMSyncSubscriptionSet *subs) {
        [subs addSubscriptionWithClassName:Person.className
                          subscriptionName:@"person_age"
                                     where:@"age > 20 and partition == %@", NSStringFromSelector(_cmd)];
        [subs addSubscriptionWithClassName:Person.className
                          subscriptionName:@"person_age_2"
                                     where:@"firstName == 'firstname_1' and partition == %@", NSStringFromSelector(_cmd)];
        [subs addSubscriptionWithClassName:Dog.className
                          subscriptionName:@"dog_breed_labradoodle"
                                     where:@"breed == 'Labradoodle' and partition == %@", NSStringFromSelector(_cmd)];
    }];
    CHECK_COUNT(2, Person, realm);
    CHECK_COUNT(1, Dog, realm);

    [self writeQueryAndCompleteForRealm:realm block:^(RLMSyncSubscriptionSet *subs) {
        [subs removeAllSubscriptionsWithClassName:Person.className];
    }];
    CHECK_COUNT(0, Person, realm)
    CHECK_COUNT(1, Dog, realm);
}

- (void)testFlexibleSyncUpdateQuery {
    [self populateData:^(RLMRealm *realm) {
        int numberOfSubs = 21;
        for (int i = 1; i <= numberOfSubs; ++i) {
            Person *person = [[Person alloc] initWithPrimaryKey:[RLMObjectId objectId]
                                                            age:i
                                                      firstName:[NSString stringWithFormat:@"firstname_%d", i]
                                                       lastName:[NSString stringWithFormat:@"lastname_%d", i]];
            person.partition = NSStringFromSelector(_cmd);
            [realm addObject: person];
        }
    }];

    RLMRealm *realm = [self getFlexibleSyncRealm:_cmd];
    XCTAssertNotNil(realm);
    CHECK_COUNT(0, Person, realm);

    [self writeQueryAndCompleteForRealm:realm block:^(RLMSyncSubscriptionSet *subs) {
        [subs addSubscriptionWithClassName:Person.className
                          subscriptionName:@"person_age"
                                     where:@"age > 0 and partition == %@", NSStringFromSelector(_cmd)];
    }];
    CHECK_COUNT(21, Person, realm);

    [self writeQueryAndCompleteForRealm:realm block:^(RLMSyncSubscriptionSet *subs) {
        RLMSyncSubscription *foundSub = [subs subscriptionWithName:@"person_age"];
        [foundSub updateSubscriptionWithClassName:Person.className where:@"age > 20 and partition == %@", NSStringFromSelector(_cmd)];
    }];
    CHECK_COUNT(1, Person, realm);
}

- (void)testFlexibleSyncUpdateQueryToDifferentClass {
    [self populateData:^(RLMRealm *realm) {
        int numberOfSubs = 21;
        for (int i = 1; i <= numberOfSubs; ++i) {
            Person *person = [[Person alloc] initWithPrimaryKey:[RLMObjectId objectId]
                                                            age:i
                                                      firstName:[NSString stringWithFormat:@"firstname_%d", i]
                                                       lastName:[NSString stringWithFormat:@"lastname_%d", i]];
            person.partition = NSStringFromSelector(_cmd);
            [realm addObject: person];
        }
        Dog *dog = [[Dog alloc] initWithPrimaryKey:[RLMObjectId objectId]
                                             breed:@"Labradoodle"
                                              name:@"Tom"];
        dog.partition = NSStringFromSelector(_cmd);
        [realm addObject: dog];
    }];

    RLMRealm *realm = [self getFlexibleSyncRealm:_cmd];
    XCTAssertNotNil(realm);
    CHECK_COUNT(0, Person, realm);

    [self writeQueryAndCompleteForRealm:realm block:^(RLMSyncSubscriptionSet *subs) {
        [subs addSubscriptionWithClassName:Person.className
                          subscriptionName:@"main_query"
                                     where:@"age > 0 and partition == %@", NSStringFromSelector(_cmd)];
    }];
    CHECK_COUNT(21, Person, realm);
    CHECK_COUNT(0, Dog, realm);

    [self writeQueryAndCompleteForRealm:realm block:^(RLMSyncSubscriptionSet *subs) {
        RLMSyncSubscription *foundSub = [subs subscriptionWithName:@"main_query"];
        [foundSub updateSubscriptionWithClassName:Dog.className where:@"breed == 'Labradoodle' and partition == %@", NSStringFromSelector(_cmd)];
    }];
    CHECK_COUNT(0, Person, realm);
    CHECK_COUNT(1, Dog, realm);
}

// TODO: This test should pass when `https://github.com/10gen/baas/pull/5449` when this pull request gets merged and the server send a request to erase the object when it is not within the query
//- (void)testFlexibleSyncAddObjectOutsideQuery {
//    [self populateData:^(RLMRealm *realm) {
//        int numberOfSubs = 21;
//        for (int i = 1; i <= numberOfSubs; ++i) {
//            Person *person = [[Person alloc] initWithPrimaryKey:[RLMObjectId objectId]
//                                                            age:i
//                                                      firstName:[NSString stringWithFormat:@"firstname_%d", i]
//                                                       lastName:[NSString stringWithFormat:@"lastname_%d", i]];
//            person.partition = NSStringFromSelector(_cmd);
//            [realm addObject: person];
//        }
//    }];
//
//    RLMRealm *realm = [self getFlexibleSyncRealm:_cmd];
//    XCTAssertNotNil(realm);
//    CHECK_COUNT(0, Person, realm);
//
//    [self writeQueryAndCompleteForRealm:realm block:^(RLMSyncSubscriptionSet *subs) {
//        [subs addSubscriptionWithClassName:Person.className
//                          subscriptionName:@"person_age"
//                                     where:@"age > 18"];
//    }];
//    CHECK_COUNT(3, Person, realm);
//
//    [realm transactionWithBlock:^{
//        [realm addObject:[[Person alloc] initWithPrimaryKey:[RLMObjectId objectId] age:10 firstName:@"Nic" lastName:@"Cages"]];
//    }];
//    [self waitForUploadsForRealm:realm];
//    [self waitForDownloadsForRealm:realm];
//    CHECK_COUNT(3, Person, realm);
//
//    // Second realm, with different app
//    NSString *appId = [RealmServer.shared createAppWithQueryableFields:@[@"age"] error:nil];
//    RLMApp *app = [RLMApp appWithId:appId
//                      configuration:[self defaultAppConfiguration]
//                      rootDirectory:[self clientDataRoot]];
//
//    RLMUser *user = [self logInUserForCredentials:[self basicCredentialsWithName:@"lmao@10gen.com"
//                                                                        register:YES
//                                                                             app:app] app:app];
//    RLMRealmConfiguration *config = [user flexibleSyncConfiguration];
//    config.objectClasses = @[Dog.self,
//                             Person.self];
//    RLMRealm *realm2 = [RLMRealm realmWithConfiguration:config error:nil];
//    XCTAssertNotNil(realm2);
//    CHECK_COUNT(0, Person, realm2);
//
//    [self writeQueryAndCompleteForRealm:realm2 block:^(RLMSyncSubscriptionSet *subs) {
//        [subs addSubscriptionWithClassName:Person.className
//                          subscriptionName:@"person_age"
//                                     where:@"age > 18"];
//    }];
//    CHECK_COUNT(3, Person, realm2);
//
//    [realm transactionWithBlock:^{
//        [realm addObject:[[Person alloc] initWithPrimaryKey:[RLMObjectId objectId] age:45 firstName:@"Steven" lastName:@"Hanks"]];
//        [realm addObject:[[Person alloc] initWithPrimaryKey:[RLMObjectId objectId] age:25 firstName:@"John" lastName:@"Stallone"]];
//    }];
//    [self waitForUploadsForRealm:realm];
//    [self waitForDownloadsForRealm:realm];
//
//    [self waitForDownloadsForRealm:realm2];
//    CHECK_COUNT(5, Person, realm2);
//    CHECK_COUNT(5, Person, realm);
//}
@end
