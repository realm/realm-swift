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
    config.objectClasses = @[Dog.self, Person.self, HugeSyncObject.self, RLMSetSyncObject.self,
                             RLMArraySyncObject.self, UUIDPrimaryKeyObject.self, StringPrimaryKeyObject.self,
                             IntPrimaryKeyObject.self, AllTypesSyncObject.self, RLMDictionarySyncObject.self];
    RLMRealm *realm = [RLMRealm realmWithConfiguration:config error:nil];
    [self waitForDownloadsForRealm:realm];
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

    XCTAssertEqual(realm.subscriptions.version, 1);
    XCTAssertEqual(realm.subscriptions.count, 1);
}

- (void)testAddSubscriptionWithoutWriteThrow {
    RLMRealm *realm = [self getFlexibleSyncRealm];
    RLMSyncSubscriptionSet *subs = realm.subscriptions;
    RLMAssertThrowsWithReason([subs addSubscriptionWithClassName:Person.className where:@"age > 15"],
                              @"Can only add, remove, or update subscriptions within a write subscription block.");
}

- (void)testAddAndFindSubscriptionByQuery {
    RLMRealm *realm = [self getFlexibleSyncRealm];
    RLMSyncSubscriptionSet *subs = realm.subscriptions;

    [subs write:^{
        [subs addSubscriptionWithClassName:Person.className
                                     where:@"age > 15"];
    }];
    
    RLMSyncSubscription *foundSubscription = [realm.subscriptions subscriptionWithClassName:Person.className
                                                                                  where:@"age > 15"];
    XCTAssertNotNil(foundSubscription);
    XCTAssert(foundSubscription.name, @"");
    XCTAssert(foundSubscription.queryString, @"age > 15");
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

    RLMSyncSubscription *foundSubscription = [realm.subscriptions subscriptionWithName:@"person_older_15"];
    XCTAssertNotNil(foundSubscription);
    XCTAssert(foundSubscription.name, @"person_older_15");
    XCTAssert(foundSubscription.queryString, @"age > 15");
}
@end
