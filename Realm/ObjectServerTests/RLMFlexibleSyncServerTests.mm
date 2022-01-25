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

@interface RLMFlexibleSyncTests : RLMSyncTestCase
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
    RLMAssertThrowsWithReason(realm.subscriptions, @"This Realm was not configured with flexible sync");
}

- (void)testGetSubscriptionsWhenPbsRealm {
    RLMRealm *realm = [self realmForTest:_cmd];
    RLMAssertThrowsWithReason(realm.subscriptions, @"This Realm was not configured with flexible sync");
}

- (void)testFlexibleSyncRealmFilePath {
    RLMUser *user = [self logInUserForCredentials:[self basicCredentialsWithName:NSStringFromSelector(_cmd)
                                                                        register:YES
                                                                             app:self.flexibleSyncApp]
                                              app:self.flexibleSyncApp];
    RLMRealmConfiguration *config = [user flexibleSyncConfiguration];
    NSString *expected = [NSString stringWithFormat:@"mongodb-realm/%@/%@/flx_sync_default.realm", self.flexibleSyncAppId, user.identifier];
    XCTAssertTrue([config.fileURL.path hasSuffix:expected]);
}

- (void)testGetSubscriptionsWhenFlexibleSync {
    RLMRealm *realm = [self openFlexibleSyncRealm:_cmd];
    RLMSyncSubscriptionSet *subs = realm.subscriptions;
    XCTAssertNotNil(subs);
    XCTAssertEqual(subs.version, 0UL);
    XCTAssertEqual(subs.count, 0UL);
}

- (void)testGetSubscriptionsWhenSameVersion {
    RLMRealm *realm = [self openFlexibleSyncRealm:_cmd];
    RLMSyncSubscriptionSet *subs1 = realm.subscriptions;
    RLMSyncSubscriptionSet *subs2 = realm.subscriptions;
    XCTAssertEqual(subs1.version, 0UL);
    XCTAssertEqual(subs2.version, 0UL);
}

- (void)testCheckVersionAfterAddSubscription {
    RLMRealm *realm = [self openFlexibleSyncRealm:_cmd];
    RLMSyncSubscriptionSet *subs = realm.subscriptions;
    XCTAssertNotNil(subs);
    XCTAssertEqual(subs.version, 0UL);
    XCTAssertEqual(subs.count, 0UL);

    [subs write:^{
        [subs addSubscriptionWithClassName:Person.className
                                     where:@"age > 15"];
    }];

    XCTAssertEqual(subs.version, 1UL);
    XCTAssertEqual(subs.count, 1UL);
}

- (void)testEmptyWriteSubscriptions {
    RLMRealm *realm = [self openFlexibleSyncRealm:_cmd];
    RLMSyncSubscriptionSet *subs = realm.subscriptions;
    XCTAssertNotNil(subs);
    XCTAssertEqual(subs.version, 0UL);
    XCTAssertEqual(subs.count, 0UL);

    [subs write:^{
    }];

    XCTAssertEqual(subs.version, 1UL);
    XCTAssertEqual(subs.count, 0UL);
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
    XCTAssertNil(foundSubscription.name);
    XCTAssert(foundSubscription.queryString, @"age > 15");
}

- (void)testAddAndFindSubscriptionWithCompoundQuery {
    RLMRealm *realm = [self openFlexibleSyncRealm:_cmd];
    RLMSyncSubscriptionSet *subs = realm.subscriptions;
    XCTAssertNotNil(subs);
    XCTAssertEqual(subs.version, 0UL);
    XCTAssertEqual(subs.count, 0UL);

    [subs write:^{
        [subs addSubscriptionWithClassName:Person.className
                                     where:@"firstName == %@ and lastName == %@", @"John", @"Doe"];
    }];

    XCTAssertEqual(subs.version, 1UL);
    XCTAssertEqual(subs.count, 1UL);

    RLMSyncSubscription *foundSubscription = [subs subscriptionWithClassName:Person.className
                                                                       where:@"firstName == %@ and lastName == %@", @"John", @"Doe"];
    XCTAssertNotNil(foundSubscription);
    XCTAssertNil(foundSubscription.name);
    XCTAssert(foundSubscription.queryString, @"firstName == 'John' and lastName == 'Doe'");
}

- (void)testAddAndFindSubscriptionWithPredicate {
    RLMRealm *realm = [self openFlexibleSyncRealm:_cmd];
    RLMSyncSubscriptionSet *subs = realm.subscriptions;
    XCTAssertNotNil(subs);
    XCTAssertEqual(subs.version, 0UL);
    XCTAssertEqual(subs.count, 0UL);

    [subs write:^{
        [subs addSubscriptionWithClassName:Person.className
                                 predicate:[NSPredicate predicateWithFormat:@"age == %d", 20]];
    }];

    XCTAssertEqual(subs.version, 1UL);
    XCTAssertEqual(subs.count, 1UL);

    RLMSyncSubscription *foundSubscription = [subs subscriptionWithClassName:Person.className
                                                                   predicate:[NSPredicate predicateWithFormat:@"age == %d", 20]];
    XCTAssertNotNil(foundSubscription);
    XCTAssertNil(foundSubscription.name);
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
    XCTAssertEqual(realm.subscriptions.version, 0UL);
    XCTAssertEqual(realm.subscriptions.count, 0UL);

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

    XCTAssertEqual(subs.version, 1UL);
    XCTAssertEqual(subs.count, 1UL);
}

- (void)testAddDuplicateNamedSubscriptionWillThrow {
    RLMRealm *realm = [self openFlexibleSyncRealm:_cmd];
    RLMSyncSubscriptionSet *subs = realm.subscriptions;

    [subs write:^{
        [subs addSubscriptionWithClassName:Person.className
                          subscriptionName:@"person_age"
                                     where:@"age > 15"];
        RLMAssertThrowsWithReason([subs addSubscriptionWithClassName:Person.className
                                                    subscriptionName:@"person_age"
                                                               where:@"age > 20"],
                                  @"Cannot duplicate a subscription. If you meant to update the subscription please use the `update` method.");
    }];

    XCTAssertEqual(subs.version, 1UL);
    XCTAssertEqual(subs.count, 1UL);

    RLMSyncSubscription *foundSubscription = [subs subscriptionWithName:@"person_age"];
    XCTAssertNotNil(foundSubscription);

    XCTAssertEqualObjects(foundSubscription.name, @"person_age");
    XCTAssertEqualObjects(foundSubscription.queryString, @"age > 15");
    XCTAssertEqualObjects(foundSubscription.objectClassName, @"Person");
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

    XCTAssertEqual(subs.version, 1UL);
    XCTAssertEqual(subs.count, 1UL);
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

    XCTAssertEqual(subs.version, 1UL);
    XCTAssertEqual(subs.count, 2UL);

    RLMSyncSubscription *foundSubscription = [subs subscriptionWithName:@"person_age_1"];
    XCTAssertNotNil(foundSubscription);

    RLMSyncSubscription *foundSubscription2 = [subs subscriptionWithName:@"person_age_2"];
    XCTAssertNotNil(foundSubscription2);

    XCTAssertNotEqualObjects(foundSubscription.name, foundSubscription2.name);
    XCTAssertEqualObjects(foundSubscription.queryString, foundSubscription2.queryString);
    XCTAssertEqualObjects(foundSubscription.objectClassName, foundSubscription2.objectClassName);
}

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

    XCTAssertEqual(subs.version, 1UL);
    XCTAssertEqual(subs.count, 2UL);
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

    XCTAssertEqual(subs.version, 1UL);
    XCTAssertEqual(subs.count, 2UL);
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

    XCTAssertEqual(realm.subscriptions.version, 2UL);
    XCTAssertEqual(realm.subscriptions.count, 2UL);

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

    XCTAssertEqual(subs.version, 1UL);
    XCTAssertEqual(subs.count, 2UL);

    [subs write:^{
        [subs removeSubscriptionWithName:@"person_age_1"];
    }];

    XCTAssertEqual(subs.version, 2UL);
    XCTAssertEqual(subs.count, 1UL);

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

    XCTAssertEqual(subs.version, 1UL);
    XCTAssertEqual(subs.count, 1UL);
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
                                     where:@"firstName == %@", @"John"];
        [subs addSubscriptionWithClassName:Person.className
                          subscriptionName:@"person_lastname"
                                 predicate:[NSPredicate predicateWithFormat:@"lastName == %@", @"Doe"]];
    }];

    XCTAssertEqual(subs.version, 1UL);
    XCTAssertEqual(subs.count, 3UL);

    [subs write:^{
        [subs removeSubscriptionWithClassName:Person.className where:@"firstName == %@", @"John"];
        [subs removeSubscriptionWithClassName:Person.className predicate:[NSPredicate predicateWithFormat:@"lastName == %@", @"Doe"]];
    }];
    
    XCTAssertEqual(subs.version, 2UL);
    XCTAssertEqual(subs.count, 1UL);

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
                                 predicate:[NSPredicate predicateWithFormat:@"lastName == %@", @"Doe"]];
    }];

    XCTAssertEqual(subs.version, 1UL);
    XCTAssertEqual(subs.count, 3UL);

    RLMSyncSubscription *foundSubscription = [subs subscriptionWithName:@"person_age"];
    XCTAssertNotNil(foundSubscription);

    [subs write:^{
        [subs removeSubscription:foundSubscription];
    }];

    XCTAssertEqual(subs.version, 2UL);
    XCTAssertEqual(subs.count, 2UL);

    RLMSyncSubscription *foundSubscription2 = [subs subscriptionWithName:@"person_firstname"];
    XCTAssertNotNil(foundSubscription2);

    [subs write:^{
        [subs removeSubscription:foundSubscription2];
    }];

    XCTAssertEqual(subs.version, 3UL);
    XCTAssertEqual(subs.count, 1UL);
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
                                 predicate:[NSPredicate predicateWithFormat:@"lastName == %@", @"Doe"]];
    }];

    XCTAssertEqual(subs.version, 1UL);
    XCTAssertEqual(subs.count, 3UL);

    [subs write:^{
        [subs removeAllSubscriptions];
    }];

    XCTAssertEqual(subs.version, 2UL);
    XCTAssertEqual(subs.count, 0UL);

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
                                 predicate:[NSPredicate predicateWithFormat:@"lastName == %@", @"Doe"]];
    }];

    XCTAssertEqual(subs.version, 1UL);
    XCTAssertEqual(subs.count, 3UL);

    [subs write:^{
        [subs removeAllSubscriptionsWithClassName:Person.className];
    }];

    XCTAssertEqual(subs.version, 2UL);
    XCTAssertEqual(subs.count, 1UL);

    RLMSyncSubscription *foundSubscription = [subs subscriptionWithName:@"dog_name"];
    XCTAssertNotNil(foundSubscription);

    [subs write:^{
        [subs removeAllSubscriptionsWithClassName:Dog.className];
    }];

    XCTAssertEqual(subs.version, 3UL);
    XCTAssertEqual(subs.count, 0UL);
}

- (void)testUpdateSubscriptionQuery {
    RLMRealm *realm = [self openFlexibleSyncRealm:_cmd];
    RLMSyncSubscriptionSet *subs = realm.subscriptions;

    [subs write:^{
        [subs addSubscriptionWithClassName:Person.className
                          subscriptionName:@"person_age"
                                     where:@"age > 15"];
    }];

    XCTAssertEqual(subs.version, 1UL);
    XCTAssertEqual(subs.count, 1UL);

    RLMSyncSubscription *foundSubscription = [subs subscriptionWithName:@"person_age"];
    XCTAssertNotNil(foundSubscription);

    [subs write:^{
        [foundSubscription updateSubscriptionWhere:@"age > 20"];
    }];

    XCTAssertEqual(subs.version, 2UL);
    XCTAssertEqual(subs.count, 1UL);

    RLMSyncSubscription *foundSubscription2 = [subs subscriptionWithName:@"person_age"];
    XCTAssertNotNil(foundSubscription2);
    XCTAssertEqualObjects(foundSubscription2.queryString, @"age > 20");
    XCTAssertEqualObjects(foundSubscription2.objectClassName, @"Person");
}

- (void)testUpdateSubscriptionQueryWithoutWriteThrow {
    RLMRealm *realm = [self openFlexibleSyncRealm:_cmd];
    RLMSyncSubscriptionSet *subs = realm.subscriptions;

    [subs write:^{
        [subs addSubscriptionWithClassName:Person.className
                          subscriptionName:@"subscription_1"
                                     where:@"age > 15"];
    }];

    XCTAssertEqual(subs.version, 1UL);
    XCTAssertEqual(subs.count, 1UL);

    RLMSyncSubscription *foundSubscription = [subs subscriptionWithName:@"subscription_1"];
    XCTAssertNotNil(foundSubscription);

    RLMAssertThrowsWithReason([foundSubscription updateSubscriptionWithPredicate:[NSPredicate predicateWithFormat:@"name == 'Tomas'"]], @"Can only add, remove, or update subscriptions within a write subscription block.");
}

- (void)testSubscriptionSetIterate {
    RLMRealm *realm = [self openFlexibleSyncRealm:_cmd];
    RLMSyncSubscriptionSet *subs = realm.subscriptions;

    double numberOfSubs = 100;
    [subs write:^{
        for (int i = 0; i < numberOfSubs; ++i) {
            [subs addSubscriptionWithClassName:Person.className
                              subscriptionName:[NSString stringWithFormat:@"person_age_%d", i]
                                         where:[NSString stringWithFormat:@"age > %d", i]];
        }
    }];

    XCTAssertEqual(subs.version, 1UL);
    XCTAssertEqual(subs.count, (unsigned long)numberOfSubs);

    __weak id objects[(unsigned long)pow(numberOfSubs, 2.0) + (unsigned long)numberOfSubs];
    NSInteger count = 0;
    for (RLMSyncSubscription *sub in subs) {
        XCTAssertNotNil(sub);
        objects[count++] = sub;
        for (RLMSyncSubscription *sub in subs) {
            objects[count++] = sub;
        }
    }
    XCTAssertEqual(count, pow(numberOfSubs, 2) + numberOfSubs);
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

    XCTAssertEqual(subs.version, 1UL);
    XCTAssertEqual(subs.count, (unsigned long)numberOfSubs);

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

    XCTAssertEqual(subs.count, 0UL);

    int numberOfSubs = 20;
    [subs write:^{
        for (int i = 1; i <= numberOfSubs; ++i) {
            [subs addSubscriptionWithClassName:Person.className
                              subscriptionName:[NSString stringWithFormat:@"person_age_%d", i]
                                         where:[NSString stringWithFormat:@"age > %d", i]];
        }
    }];

    XCTAssertEqual(subs.version, 1UL);
    XCTAssertEqual(subs.count, (unsigned long)numberOfSubs);

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

@interface RLMFlexibleSyncServerTests : RLMSyncTestCase
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
            [realm addObject:person];
        }
    }];
    RLMRealm *realm = [self getFlexibleSyncRealm:_cmd];
    XCTAssertNotNil(realm);
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
        int numberOfSubs = 21;
        for (int i = 1; i <= numberOfSubs; ++i) {
            Person *person = [[Person alloc] initWithPrimaryKey:[RLMObjectId objectId]
                                                            age:i
                                                      firstName:[NSString stringWithFormat:@"firstname_%d", i]
                                                       lastName:[NSString stringWithFormat:@"lastname_%d", i]];
            // We are using the partition property to filter only the objects for this test
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
        [realm addObject:dog];
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
        [realm addObject:dog];
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
        [realm addObject:dog];
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
        [realm addObject:dog];
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
        [foundSub updateSubscriptionWhere:@"age > 20 and partition == %@", NSStringFromSelector(_cmd)];
    }];
    CHECK_COUNT(1, Person, realm);
}

- (void)testFlexibleSyncAddObjectOutsideQuery {
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
                                     where:@"age > 18 and partition == %@", NSStringFromSelector(_cmd)];
    }];
    CHECK_COUNT(3, Person, realm);

    auto ex = [self expectationWithDescription:@"should client reset"];
    [self.flexibleSyncApp syncManager].errorHandler = ^(NSError * error, RLMSyncSession *) {
        XCTAssertNotNil(error);
        [ex fulfill];
    };
    [realm transactionWithBlock:^{
        [realm addObject:[[Person alloc] initWithPrimaryKey:[RLMObjectId objectId] age:10 firstName:@"Nic" lastName:@"Cages"]];
    }];
    [self waitForExpectations:@[ex] timeout:20];
}
@end
