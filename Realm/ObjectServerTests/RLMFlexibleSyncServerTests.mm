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
- (NSString *)createAppForFlexibleSyncAndReturnError:(NSError **)error;
@end

@interface RLMFlexibleSyncTestCase: RLMSyncTestCase
- (RLMRealm *)flexibleSyncRealmForUser:(RLMUser *)user;
@end

@implementation RLMFlexibleSyncTestCase
- (RLMRealm *)flexibleSyncRealmForUser:(RLMUser *)user {
    RLMRealmConfiguration *config = [user flexibleSyncConfiguration];
    config.objectClasses = @[Dog.self,
                             Person.self];
    RLMRealm *realm = [RLMRealm realmWithConfiguration:config error:nil];
    return realm;
}

-(RLMRealm *)getFlexibleSyncRealm {
    NSString *appId = [RealmServer.shared createAppForFlexibleSyncAndReturnError:nil];
    RLMApp *app = [RLMApp appWithId:appId
                      configuration:[self defaultAppConfiguration]
                      rootDirectory:[self clientDataRoot]];
    RLMUser *user =  [self logInUserForCredentials:[self basicCredentialsWithName:NSStringFromSelector(_cmd)
                                                                         register:YES
                                                                              app:app]
                                               app:app];
    RLMRealm *realm = [self flexibleSyncRealmForUser:user];
    XCTAssertNotNil(realm);
    return realm;
}
@end

@interface RLMFlexibleSyncServerTests: RLMFlexibleSyncTestCase
@end

@implementation RLMFlexibleSyncServerTests
- (void)testCreateFlexibleSyncApp {
    NSString *appId = [RealmServer.shared createAppForFlexibleSyncAndReturnError:nil];
    RLMApp *app = [RLMApp appWithId:appId
                      configuration:[self defaultAppConfiguration]
                      rootDirectory:[self clientDataRoot]];
    XCTAssertNotNil(app);
}

- (void)testFlexibleSyncOpenRealm {
    XCTAssertNotNil([self getFlexibleSyncRealm]);
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
    RLMRealm *realm = [self getFlexibleSyncRealm];
    RLMSyncSubscriptionSet *subs = realm.subscriptions;
    XCTAssertNotNil(subs);
    XCTAssertEqual(subs.version, 0);
    XCTAssertEqual(subs.count, 0);
}

- (void)testGetSubscriptionsWhenSameVersion {
    RLMRealm *realm = [self getFlexibleSyncRealm];
    RLMSyncSubscriptionSet *subs1 = realm.subscriptions;
    RLMSyncSubscriptionSet *subs2 = realm.subscriptions;
    XCTAssertEqual(subs1.version, 0);
    XCTAssertEqual(subs2.version, 0);
}

- (void)testCheckVersionAfterAddSubscription {
    RLMRealm *realm = [self getFlexibleSyncRealm];
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
    RLMRealm *realm = [self getFlexibleSyncRealm];
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
    RLMRealm *realm = [self getFlexibleSyncRealm];
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
    RLMRealm *realm = [self getFlexibleSyncRealm];
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
    RLMRealm *realm = [self getFlexibleSyncRealm];
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
    RLMRealm *realm = [self getFlexibleSyncRealm];
    RLMSyncSubscriptionSet *subs = realm.subscriptions;
    RLMAssertThrowsWithReason([subs addSubscriptionWithClassName:Person.className where:@"age > 15"],
                              @"Can only add, remove, or update subscriptions within a write subscription block.");
}

- (void)testAddAndFindSubscriptionByName {
    RLMRealm *realm = [self getFlexibleSyncRealm];
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
    RLMRealm *realm = [self getFlexibleSyncRealm];
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
    RLMRealm *realm = [self getFlexibleSyncRealm];
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
    RLMRealm *realm = [self getFlexibleSyncRealm];
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
    RLMRealm *realm = [self getFlexibleSyncRealm];
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
    RLMRealm *realm = [self getFlexibleSyncRealm];
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
    RLMRealm *realm = [self getFlexibleSyncRealm];
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
    RLMRealm *realm = [self getFlexibleSyncRealm];
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
    RLMRealm *realm = [self getFlexibleSyncRealm];
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
    RLMRealm *realm = [self getFlexibleSyncRealm];
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
    RLMRealm *realm = [self getFlexibleSyncRealm];
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
    RLMRealm *realm = [self getFlexibleSyncRealm];
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
    RLMRealm *realm = [self getFlexibleSyncRealm];
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
    RLMRealm *realm = [self getFlexibleSyncRealm];
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
    RLMRealm *realm = [self getFlexibleSyncRealm];
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
    RLMRealm *realm = [self getFlexibleSyncRealm];
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
    RLMRealm *realm = [self getFlexibleSyncRealm];
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
    RLMRealm *realm = [self getFlexibleSyncRealm];
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
    RLMRealm *realm = [self getFlexibleSyncRealm];
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
