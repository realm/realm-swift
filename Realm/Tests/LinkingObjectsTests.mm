////////////////////////////////////////////////////////////////////////////
//
// Copyright 2016 Realm Inc.
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

@interface LinkingObjectsTests : RLMTestCase
@end

@implementation LinkingObjectsTests

- (void)testBasics {
    NSArray *(^asArray)(id) = ^(id arrayLike) {
        return [arrayLike valueForKeyPath:@"self"];
    };

    RLMRealm *realm = [self realmWithTestPath];
    [realm beginWriteTransaction];

    PersonObject *hannah = [PersonObject createInRealm:realm withValue:@[ @"Hannah", @0 ]];
    PersonObject *mark   = [PersonObject createInRealm:realm withValue:@[ @"Mark",  @30, @[ hannah ]]];

    RLMLinkingObjects *hannahsParents = hannah.parents;
    XCTAssertEqualObjects(asArray(hannahsParents), (@[ mark ]));

    [realm commitWriteTransaction];

    XCTAssertEqualObjects(asArray(hannahsParents), (@[ mark ]));

    [realm beginWriteTransaction];
    PersonObject *diane = [PersonObject createInRealm:realm withValue:@[ @"Diane", @29, @[ hannah ]]];
    [realm commitWriteTransaction];

    XCTAssertEqualObjects(asArray(hannahsParents), (@[ mark, diane ]));

    [realm beginWriteTransaction];
    [realm deleteObject:hannah];
    [realm commitWriteTransaction];
    XCTAssertEqualObjects(asArray(hannahsParents), (@[ ]));
}

- (void)testLinkingObjectsOnUnmanagedObject {
    PersonObject *don = [[PersonObject alloc] initWithValue:@[ @"Don", @60, @[] ]];

    XCTAssertEqual(0u, don.parents.count);
    XCTAssertNil(don.parents.firstObject);
    XCTAssertNil(don.parents.lastObject);

    for (__unused id parent in don.parents) {
        XCTFail(@"Got an item in empty linking objects");
    }

    XCTAssertEqual(0u, [don.parents sortedResultsUsingKeyPath:@"age" ascending:YES].count);
    XCTAssertEqual(0u, [don.parents objectsWhere:@"TRUEPREDICATE"].count);

    XCTAssertNil([don.parents minOfProperty:@"age"]);
    XCTAssertNil([don.parents maxOfProperty:@"age"]);
    XCTAssertEqualObjects(@0, [don.parents sumOfProperty:@"age"]);
    XCTAssertNil([don.parents averageOfProperty:@"age"]);

    XCTAssertEqualObjects(@[], [don.parents valueForKey:@"age"]);
    XCTAssertEqualObjects(@0, [don.parents valueForKeyPath:@"@count"]);
    XCTAssertNil([don.parents valueForKeyPath:@"@min.age"]);
    XCTAssertNil([don.parents valueForKeyPath:@"@max.age"]);
    XCTAssertEqualObjects(@0, [don.parents valueForKeyPath:@"@sum.age"]);
    XCTAssertNil([don.parents valueForKeyPath:@"@avg.age"]);

    PersonObject *mark = [[PersonObject alloc] initWithValue:@[ @"Mark", @30, @[] ]];
    XCTAssertEqual(NSNotFound, [don.parents indexOfObject:mark]);
    XCTAssertEqual(NSNotFound, [don.parents indexOfObjectWhere:@"TRUEPREDICATE"]);
}

- (void)testFilteredLinkingObjects {
    NSArray *(^asArray)(id) = ^(id arrayLike) {
        return [arrayLike valueForKeyPath:@"self"];
    };

    RLMRealm *realm = [self realmWithTestPath];
    [realm beginWriteTransaction];

    PersonObject *hannah = [PersonObject createInRealm:realm withValue:@[ @"Hannah", @0 ]];
    PersonObject *mark   = [PersonObject createInRealm:realm withValue:@[ @"Mark",  @30, @[ hannah ]]];
    PersonObject *diane  = [PersonObject createInRealm:realm withValue:@[ @"Diane", @29, @[ hannah ]]];

    RLMLinkingObjects *hannahsParents = hannah.parents;

    // Three separate queries so that accessing a property on one doesn't invalidate testing of other properties.
    RLMResults *resultsA = [hannahsParents objectsWhere:@"age > 25"];
    RLMResults *resultsB = [hannahsParents objectsWhere:@"age > 25"];
    RLMResults *resultsC = [hannahsParents objectsWhere:@"age > 25"];

    [mark.children removeAllObjects];
    [realm commitWriteTransaction];

    XCTAssertEqual(resultsA.count, 1u);
    XCTAssertEqual(NSNotFound, [resultsB indexOfObjectWhere:@"name = 'Mark'"]);
    XCTAssertEqualObjects(asArray(resultsC), (@[ diane ]));
}

- (void)testNotificationSentInitially {
    RLMRealm *realm = [self realmWithTestPath];
    [realm beginWriteTransaction];

    PersonObject *hannah = [PersonObject createInRealm:realm withValue:@[ @"Hannah", @0 ]];
    PersonObject *mark   = [PersonObject createInRealm:realm withValue:@[ @"Mark",  @30, @[ hannah ]]];

    [realm commitWriteTransaction];

    id expectation = [self expectationWithDescription:@""];
    RLMNotificationToken *token = [hannah.parents addNotificationBlock:^(RLMResults *linkingObjects, RLMCollectionChange *change, NSError *error) {
        XCTAssertEqualObjects([linkingObjects valueForKeyPath:@"self"], (@[ mark ]));
        XCTAssertNil(change);
        XCTAssertNil(error);
        [expectation fulfill];
    }];

    [self waitForExpectationsWithTimeout:2.0 handler:nil];
    [token invalidate];
}

- (void)testNotificationSentAfterCommit {
    RLMRealm *realm = self.realmWithTestPath;
    [realm beginWriteTransaction];
    PersonObject *hannah = [PersonObject createInRealm:realm withValue:@[ @"Hannah", @0 ]];
    [realm commitWriteTransaction];

    __block bool first = true;
    __block id expectation = [self expectationWithDescription:@""];
    RLMNotificationToken *token = [hannah.parents addNotificationBlock:^(RLMResults *linkingObjects, RLMCollectionChange *change, NSError *error) {
        XCTAssertNotNil(linkingObjects);
        XCTAssert(first ? !change : !!change);
        XCTAssertNil(error);
        first = false;
        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:2.0 handler:nil];

    expectation = [self expectationWithDescription:@""];
    [self dispatchAsyncAndWait:^{
        RLMRealm *realm = self.realmWithTestPath;
        [realm transactionWithBlock:^{
            [PersonObject createInRealm:realm withValue:@[ @"Mark",  @30, [PersonObject objectsInRealm:realm where:@"name == 'Hannah'"] ]];
        }];
    }];
    [self waitForExpectationsWithTimeout:2.0 handler:nil];

    [token invalidate];
}

- (void)testNotificationNotSentForUnrelatedChange {
    RLMRealm *realm = self.realmWithTestPath;
    [realm beginWriteTransaction];
    PersonObject *hannah = [PersonObject createInRealm:realm withValue:@[ @"Hannah", @0 ]];
    [realm commitWriteTransaction];

    id expectation = [self expectationWithDescription:@""];
    RLMNotificationToken *token = [hannah.parents addNotificationBlock:^(RLMResults *, RLMCollectionChange *, NSError *) {
        // will throw if it's incorrectly called a second time due to the
        // unrelated write transaction
        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:2.0 handler:nil];

    // All notification blocks are called as part of a single runloop event, so
    // waiting for this one also waits for the above one to get a chance to run
    [self waitForNotification:RLMRealmDidChangeNotification realm:realm block:^{
        [self dispatchAsyncAndWait:^{
            [self.realmWithTestPath transactionWithBlock:^{ }];
        }];
    }];
    [token invalidate];
}

- (void)testNotificationSentOnlyForActualRefresh {
    RLMRealm *realm = self.realmWithTestPath;
    [realm beginWriteTransaction];
    PersonObject *hannah = [PersonObject createInRealm:realm withValue:@[ @"Hannah", @0 ]];
    [realm commitWriteTransaction];

    __block id expectation = [self expectationWithDescription:@""];
    RLMNotificationToken *token = [hannah.parents addNotificationBlock:^(RLMResults *linkingObjects, RLMCollectionChange *, NSError *error) {
        XCTAssertNotNil(linkingObjects);
        XCTAssertNil(error);
        // will throw if it's called a second time before we create the new
        // expectation object immediately before manually refreshing
        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:2.0 handler:nil];

    // Turn off autorefresh, so the background commit should not result in a notification
    realm.autorefresh = NO;

    // All notification blocks are called as part of a single runloop event, so
    // waiting for this one also waits for the above one to get a chance to run
    [self waitForNotification:RLMRealmRefreshRequiredNotification realm:realm block:^{
        [self dispatchAsyncAndWait:^{
            RLMRealm *realm = self.realmWithTestPath;
            [realm transactionWithBlock:^{
                [PersonObject createInRealm:realm withValue:@[ @"Mark",  @30, [PersonObject objectsInRealm:realm where:@"name == 'Hannah'"] ]];
            }];
        }];
    }];

    expectation = [self expectationWithDescription:@""];
    [realm refresh];
    [self waitForExpectationsWithTimeout:2.0 handler:nil];

    [token invalidate];
}

- (void)testDeletingObjectWithNotificationsRegistered {
    RLMRealm *realm = self.realmWithTestPath;
    [realm beginWriteTransaction];
    PersonObject *hannah = [PersonObject createInRealm:realm withValue:@[ @"Hannah", @0 ]];
    PersonObject *mark   = [PersonObject createInRealm:realm withValue:@[ @"Mark",  @30, @[ hannah ]]];
    [realm commitWriteTransaction];

    __block id expectation = [self expectationWithDescription:@""];
    RLMNotificationToken *token = [hannah.parents addNotificationBlock:^(RLMResults *linkingObjects, RLMCollectionChange *, NSError *error) {
        XCTAssertNotNil(linkingObjects);
        XCTAssertNil(error);
        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:2.0 handler:nil];

    [realm beginWriteTransaction];
    [realm deleteObject:mark];
    [realm commitWriteTransaction];

    [token invalidate];
}

- (void)testRenamedProperties {
    RLMRealm *realm = self.realmWithTestPath;
    [realm beginWriteTransaction];
    auto obj1 = [RenamedProperties1 createInRealm:realm withValue:@[@1, @"a"]];
    auto obj2 = [RenamedProperties2 createInRealm:realm withValue:@[@2, @"b"]];
    auto link = [LinkToRenamedProperties1 createInRealm:realm withValue:@[obj1, obj2, @[obj1, obj1]]];
    [realm commitWriteTransaction];

    XCTAssertEqualObjects(obj1.linking1.objectClassName, @"LinkToRenamedProperties1");
    XCTAssertEqualObjects(obj1.linking2.objectClassName, @"LinkToRenamedProperties2");

    XCTAssertTrue([obj1.linking1[0] isEqualToObject:link]);
    XCTAssertTrue([obj2.linking2[0] isEqualToObject:link]);
}

@end
