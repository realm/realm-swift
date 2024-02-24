////////////////////////////////////////////////////////////////////////////
//
// Copyright 2015 Realm Inc.
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

#import "RLMRealmConfiguration_Private.hpp"
#import "RLMRealm_Private.hpp"

#import <realm/object-store/impl/realm_coordinator.hpp>

#import <sys/resource.h>

// A whole bunch of blocks don't use their RLMResults parameter
#pragma clang diagnostic ignored "-Wunused-parameter"

@interface ManualRefreshRealm : RLMRealm
@end
@implementation ManualRefreshRealm
- (void)verifyNotificationsAreSupported:(__unused bool)isCollection {
    // The normal implementation of this will reject realms with automatic change notifications disabled
}
@end

@interface AsyncTests : RLMTestCase
@end

@implementation AsyncTests
- (void)createObject:(int)value {
    @autoreleasepool {
        RLMRealm *realm = [RLMRealm defaultRealm];
        [realm transactionWithBlock:^{
            [IntObject createInDefaultRealmWithValue:@[@(value)]];
        }];
    }
}

- (void)testInitialResultsAreDelivered {
    [self createObject:1];

    XCTestExpectation *expectation = [self expectationWithDescription:@""];
    auto token = [[IntObject objectsWhere:@"intCol > 0"] addNotificationBlock:^(RLMResults *results, RLMCollectionChange *change, NSError *e) {
        XCTAssertNil(e);
        XCTAssertEqualObjects(results.objectClassName, @"IntObject");
        XCTAssertEqual(results.count, 1U);
        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:2.0 handler:nil];
    [token invalidate];
}

- (void)testNewResultsAreDeliveredAfterLocalCommit {
    __block XCTestExpectation *expectation = [self expectationWithDescription:@""];
    __block NSUInteger expected = 0;
    auto token = [[IntObject objectsWhere:@"intCol > 0"] addNotificationBlock:^(RLMResults *results, RLMCollectionChange *change, NSError *e) {
        XCTAssertEqual(results.count, expected++);
        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:2.0 handler:nil];

    expectation = [self expectationWithDescription:@""];
    [self createObject:1];
    [self waitForExpectationsWithTimeout:2.0 handler:nil];

    expectation = [self expectationWithDescription:@""];
    [self createObject:2];
    [self waitForExpectationsWithTimeout:2.0 handler:nil];
    [token invalidate];
}

- (void)testNewResultsAreDeliveredAfterBackgroundCommit {
    __block XCTestExpectation *expectation = [self expectationWithDescription:@""];
    __block NSUInteger expected = 0;
    auto token = [[IntObject objectsWhere:@"intCol > 0"] addNotificationBlock:^(RLMResults *results, RLMCollectionChange *change, NSError *e) {
        XCTAssertEqual(results.count, expected++);
        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:2.0 handler:nil];

    expectation = [self expectationWithDescription:@""];
    [self dispatchAsyncAndWait:^{ [self createObject:1]; }];
    [self waitForExpectationsWithTimeout:2.0 handler:nil];

    expectation = [self expectationWithDescription:@""];
    [self dispatchAsyncAndWait:^{ [self createObject:2]; }];
    [self waitForExpectationsWithTimeout:2.0 handler:nil];
    [token invalidate];
}

- (void)testResultsPerserveQuery {
    __block XCTestExpectation *expectation = [self expectationWithDescription:@""];
    __block NSUInteger expected = 0;
    auto token = [[IntObject objectsWhere:@"intCol > 0"] addNotificationBlock:^(RLMResults *results, RLMCollectionChange *change, NSError *e) {
        XCTAssertEqual(results.count, expected);
        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:2.0 handler:nil];

    expectation = [self expectationWithDescription:@""];
    ++expected;
    [self dispatchAsyncAndWait:^{
        [self createObject:1];
        [self createObject:-11];
    }];
    [self waitForExpectationsWithTimeout:2.0 handler:nil];
    [token invalidate];
}

- (void)testResultsPerserveSort {
    __block XCTestExpectation *expectation = [self expectationWithDescription:@""];
    __block int expected = 0;
    auto token = [[IntObject.allObjects sortedResultsUsingKeyPath:@"intCol" ascending:NO] addNotificationBlock:^(RLMResults *results, RLMCollectionChange *change, NSError *e) {
        XCTAssertEqual([results.firstObject intCol], expected);
        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:2.0 handler:nil];

    expectation = [self expectationWithDescription:@""];
    expected = 1;
    [self dispatchAsyncAndWait:^{ [self createObject:1]; }];
    [self waitForExpectationsWithTimeout:2.0 handler:nil];

    expectation = [self expectationWithDescription:@""];
    [self dispatchAsyncAndWait:^{ [self createObject:-1]; }];
    [self waitForExpectationsWithTimeout:2.0 handler:nil];

    expectation = [self expectationWithDescription:@""];
    expected = 2;
    [self dispatchAsyncAndWait:^{ [self createObject:2]; }];
    [self waitForExpectationsWithTimeout:2.0 handler:nil];
    [token invalidate];
}

- (void)testQueryingDeliveredQueryResults {
    __block XCTestExpectation *expectation = [self expectationWithDescription:@""];
    __block NSUInteger expected = 0;
    auto token = [[IntObject objectsWhere:@"intCol > 0"] addNotificationBlock:^(RLMResults *results, RLMCollectionChange *change, NSError *e) {
        XCTAssertEqual([results objectsWhere:@"intCol < 10"].count, expected++);
        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:2.0 handler:nil];

    expectation = [self expectationWithDescription:@""];
    [self dispatchAsyncAndWait:^{ [self createObject:1]; }];
    [self waitForExpectationsWithTimeout:2.0 handler:nil];

    expectation = [self expectationWithDescription:@""];
    [self dispatchAsyncAndWait:^{ [self createObject:2]; }];
    [self waitForExpectationsWithTimeout:2.0 handler:nil];
    [token invalidate];
}

- (void)testQueryingDeliveredTableResults {
    __block XCTestExpectation *expectation = [self expectationWithDescription:@""];
    __block NSUInteger expected = 0;
    auto token = [[IntObject allObjects] addNotificationBlock:^(RLMResults *results, RLMCollectionChange *change, NSError *e) {
        XCTAssertEqual([results objectsWhere:@"intCol < 10"].count, expected++);
        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:2.0 handler:nil];

    expectation = [self expectationWithDescription:@""];
    [self dispatchAsyncAndWait:^{ [self createObject:1]; }];
    [self waitForExpectationsWithTimeout:2.0 handler:nil];

    expectation = [self expectationWithDescription:@""];
    [self dispatchAsyncAndWait:^{ [self createObject:2]; }];
    [self waitForExpectationsWithTimeout:2.0 handler:nil];
    [token invalidate];
}

- (void)testQueryingDeliveredSortedResults {
    __block XCTestExpectation *expectation = [self expectationWithDescription:@""];
    __block int expected = 0;
    auto token = [[IntObject.allObjects sortedResultsUsingKeyPath:@"intCol" ascending:NO] addNotificationBlock:^(RLMResults *results, RLMCollectionChange *change, NSError *e) {
        XCTAssertEqual([[results objectsWhere:@"intCol < 10"].firstObject intCol], expected++);
        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:2.0 handler:nil];

    expectation = [self expectationWithDescription:@""];
    [self dispatchAsyncAndWait:^{ [self createObject:1]; }];
    [self waitForExpectationsWithTimeout:2.0 handler:nil];

    expectation = [self expectationWithDescription:@""];
    [self dispatchAsyncAndWait:^{ [self createObject:2]; }];
    [self waitForExpectationsWithTimeout:2.0 handler:nil];
    [token invalidate];
}

- (void)testSortingDeliveredResults {
    __block XCTestExpectation *expectation = [self expectationWithDescription:@""];
    __block int expected = 0;
    auto token = [[IntObject allObjects] addNotificationBlock:^(RLMResults *results, RLMCollectionChange *change, NSError *e) {
        XCTAssertEqual([[results sortedResultsUsingKeyPath:@"intCol" ascending:NO].firstObject intCol], expected++);
        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:2.0 handler:nil];

    expectation = [self expectationWithDescription:@""];
    [self dispatchAsyncAndWait:^{ [self createObject:1]; }];
    [self waitForExpectationsWithTimeout:2.0 handler:nil];

    expectation = [self expectationWithDescription:@""];
    [self dispatchAsyncAndWait:^{ [self createObject:2]; }];
    [self waitForExpectationsWithTimeout:2.0 handler:nil];
    [token invalidate];
}

- (void)testQueryingLinkList {
    RLMRealm *realm = [RLMRealm defaultRealm];
    [realm beginWriteTransaction];
    ArrayPropertyObject *array = [ArrayPropertyObject createInRealm:realm withValue:@[@"", @[], @[]]];
    [realm commitWriteTransaction];

    __block XCTestExpectation *expectation = [self expectationWithDescription:@""];
    __block int expected = 0;
    auto token = [[array.intArray objectsWhere:@"intCol > 0"] addNotificationBlock:^(RLMResults<IntObject *> *results,
                                                                                     RLMCollectionChange *change, NSError *e) {
//        NSLog(@"IntArray: %d", (int)array.intArray.count);
        XCTAssertNil(e);
        XCTAssertNotNil(results);
        XCTAssertEqual((int)results.count, expected);
        for (int i = 0; i < expected; ++i) {
            XCTAssertEqual(results[i].intCol, i + 1);
        }
        ++expected;
        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:2.0 handler:nil];

    for (int i = 0; i < 3; ++i) {
        expectation = [self expectationWithDescription:@""];
        [self dispatchAsyncAndWait:^{
            RLMRealm *realm = [RLMRealm defaultRealm];
            ArrayPropertyObject *array = [[ArrayPropertyObject allObjectsInRealm:realm] firstObject];

            // Create two objects, one in the list and one not, to verify that the
            // LinkList is actually be used
            [realm beginWriteTransaction];
            [IntObject createInRealm:realm withValue:@[@(i + 1)]];
            [array.intArray addObject:[IntObject createInRealm:realm withValue:@[@(i + 1)]]];
            [realm commitWriteTransaction];
        }];
        [self waitForExpectationsWithTimeout:2.0 handler:nil];
    }

    [token invalidate];
}

- (RLMNotificationToken *)subscribeAndWaitForInitial:(id<RLMCollection>)query block:(void (^)(id))block {
    __block XCTestExpectation *exp = [self expectationWithDescription:@"wait for initial results"];
    auto token = [query addNotificationBlock:^(id results, RLMCollectionChange *change, NSError *e) {
        XCTAssertNotNil(results);
        XCTAssertNil(e);
        if (exp) {
            [exp fulfill];
            exp = nil;
        }
        else {
            block(results);
        }
    }];
    [self waitForExpectationsWithTimeout:2.0 handler:nil];
    return token;
}

- (void)testManualRefreshUsesAsyncResultsWhenPossible {
    __block bool called = false;
    auto token = [self subscribeAndWaitForInitial:IntObject.allObjects block:^(RLMResults *results) {
        called = true;
    }];

    RLMRealm *realm = [RLMRealm defaultRealm];
    realm.autorefresh = NO;

    [self waitForNotification:RLMRealmRefreshRequiredNotification realm:realm block:^{
        [self dispatchAsync:^{
            [RLMRealm.defaultRealm transactionWithBlock:^{
                [IntObject createInDefaultRealmWithValue:@[@0]];
            }];
        }];
    }];

    XCTAssertFalse(called);
    [realm refresh];
    XCTAssertTrue(called);

    [token invalidate];
}

- (void)testModifyingUnrelatedTableDoesNotTriggerResend {
    __block XCTestExpectation *expectation = [self expectationWithDescription:@""];
    auto token = [[IntObject allObjects] addNotificationBlock:^(RLMResults *results, RLMCollectionChange *change, NSError *e) {
        // will throw if called a second time
        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:2.0 handler:nil];

    [self waitForNotification:RLMRealmDidChangeNotification realm:RLMRealm.defaultRealm block:^{
        RLMRealm *realm = [RLMRealm defaultRealm];
        [realm transactionWithBlock:^{
            [StringObject createInDefaultRealmWithValue:@[@""]];
        }];
    }];
    [token invalidate];
}

- (void)testStaleResultsAreDiscardedWhenThreadIsBlocked {
    XCTestExpectation *expectation = [self expectationWithDescription:@""];
    auto token = [IntObject.allObjects addNotificationBlock:^(RLMResults *results, RLMCollectionChange *change, NSError *e) {
        // Will fail if this is called with the initial results
        XCTAssertEqual(1U, results.count);
        // Will fail if it's called twice
        [expectation fulfill];
    }];

    // Advance the version on a different thread, and then wait for async work
    // to complete for that new version
    [self dispatchAsyncAndWait:^{
        [RLMRealm.defaultRealm transactionWithBlock:^{
            [IntObject createInDefaultRealmWithValue:@[@0]];
        } error:nil];

        __block RLMNotificationToken *token;
        CFRunLoopPerformBlock(CFRunLoopGetCurrent(), kCFRunLoopDefaultMode, ^{
            token = [IntObject.allObjects addNotificationBlock:^(RLMResults *, RLMCollectionChange *, NSError *) {
                [token invalidate];
                token = nil;
                CFRunLoopStop(CFRunLoopGetCurrent());
            }];
        });
        CFRunLoopRun();
    }];

    // Only now let the main thread pick up the notifications
    [self waitForExpectationsWithTimeout:2.0 handler:nil];
    [token invalidate];
}

- (void)testCommitInOneNotificationDoesNotCancelOtherNotifications {
    __block XCTestExpectation *exp1 = nil;
    __block XCTestExpectation *exp2 = nil;
    __block int firstBlockCalls = 0;
    __block int secondBlockCalls = 0;

    auto token = [self subscribeAndWaitForInitial:IntObject.allObjects block:^(RLMResults *results) {
        ++firstBlockCalls;
        if (firstBlockCalls == 2) {
            [exp1 fulfill];
        }
        else {
            [results.realm beginWriteTransaction];
            [IntObject createInDefaultRealmWithValue:@[@1]];
            [results.realm commitWriteTransaction];
        }
    }];
    auto token2 = [self subscribeAndWaitForInitial:IntObject.allObjects block:^(RLMResults *results) {
        ++secondBlockCalls;
        if (secondBlockCalls == 2) {
            [exp2 fulfill];
        }
    }];

    exp1 = [self expectationWithDescription:@""];
    exp2 = [self expectationWithDescription:@""];

    [RLMRealm.defaultRealm transactionWithBlock:^{
        [IntObject createInDefaultRealmWithValue:@[@0]];
    } error:nil];

    [self waitForExpectationsWithTimeout:2.0 handler:nil];

    XCTAssertEqual(2, firstBlockCalls);
    XCTAssertEqual(2, secondBlockCalls);

    [token invalidate];
    [token2 invalidate];
}

- (void)testRLMResultsInstanceIsReused {
    __weak __block RLMResults *prev;
    __block bool first = true;

    XCTestExpectation *expectation = [self expectationWithDescription:@""];
    auto token = [IntObject.allObjects addNotificationBlock:^(RLMResults *results, RLMCollectionChange *change, NSError *e) {
        if (first) {
            prev = results;
            first = false;
        }
        else {
            XCTAssertEqual(prev, results); // deliberately not EqualObjects
        }
        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:2.0 handler:nil];
    XCTAssertNotNil(prev);
    [token invalidate];
}

- (void)testCancellationTokenKeepsSubscriptionAlive {
    __block XCTestExpectation *expectation = [self expectationWithDescription:@""];
    RLMNotificationToken *token;
    @autoreleasepool {
        token = [IntObject.allObjects addNotificationBlock:^(RLMResults *results, RLMCollectionChange *change, NSError *err) {
            XCTAssertNotNil(results);
            XCTAssertNil(err);
            [expectation fulfill];
        }];
    }
    [self waitForExpectationsWithTimeout:2.0 handler:nil];

    // at this point there are no strong references to anything other than the
    // token, so verify that things haven't magically gone away
    // this would be better as a multi-process tests with the commit done
    // from a different process

    expectation = [self expectationWithDescription:@""];
    @autoreleasepool {
        [RLMRealm.defaultRealm transactionWithBlock:^{
            [IntObject createInDefaultRealmWithValue:@[@0]];
        }];
    }
    [self waitForExpectationsWithTimeout:2.0 handler:nil];
}

- (void)testCancellationTokenPreventsOpeningRealmWithMismatchedConfig {
    __block XCTestExpectation *expectation = [self expectationWithDescription:@""];
    RLMNotificationToken *token;
    @autoreleasepool {
        token = [IntObject.allObjects addNotificationBlock:^(RLMResults *results, RLMCollectionChange *change, NSError *err) {
            XCTAssertNotNil(results);
            XCTAssertNil(err);
            [expectation fulfill];
        }];
    }
    [self waitForExpectationsWithTimeout:2.0 handler:nil];

    RLMRealmConfiguration *config = [RLMRealmConfiguration defaultConfiguration];
    config.readOnly = true;
    @autoreleasepool {
        XCTAssertThrows([RLMRealm realmWithConfiguration:config error:nil]);
    }

    [token invalidate];
    XCTAssertNoThrow([RLMRealm realmWithConfiguration:config error:nil]);
}

- (void)testAddAndRemoveQueries {
    RLMRealm *realm = [RLMRealm defaultRealm];
    @autoreleasepool {
        RLMResults *results = IntObject.allObjects;
        [[self subscribeAndWaitForInitial:results block:^(RLMResults *r) {
            XCTFail(@"results delivered after removal");
        }] invalidate];

        // Readd same results at same version
        [[self subscribeAndWaitForInitial:results block:^(RLMResults *r) {
            XCTFail(@"results delivered after removal");
        }] invalidate];

        // Add different results at same version
        [[self subscribeAndWaitForInitial:IntObject.allObjects block:^(RLMResults *r) {
            XCTFail(@"results delivered after removal");
        }] invalidate];

        [self waitForNotification:RLMRealmDidChangeNotification realm:RLMRealm.defaultRealm block:^{
            [RLMRealm.defaultRealm transactionWithBlock:^{ }];
        }];

        // Readd at later version
        [[self subscribeAndWaitForInitial:results block:^(RLMResults *r) {
            XCTFail(@"results delivered after removal");
        }] invalidate];

        // Add different results at later version
        [[self subscribeAndWaitForInitial:[IntObject allObjectsInRealm:realm] block:^(RLMResults *r) {
            XCTFail(@"results delivered after removal");
        }] invalidate];
    }

    // Add different results after all of the previous async queries have been
    // removed entirely
    [[self subscribeAndWaitForInitial:[IntObject allObjectsInRealm:realm] block:^(RLMResults *r) {
        XCTFail(@"results delivered after removal");
    }] invalidate];
}

- (void)testMultipleSourceVersionsForAsyncQueries {
    RLMRealmConfiguration *config = [RLMRealmConfiguration defaultConfiguration];
    config.cache = false;

    // Create ten RLMRealm instances, each with a different read version
    RLMRealm *realms[10];
    for (int i = 0; i < 10; ++i) {
        RLMRealm *realm = realms[i] = [RLMRealm realmWithConfiguration:config error:nil];
        [realm transactionWithBlock:^{
            [IntObject createInRealm:realm withValue:@[@(i)]];
        }];
    }

    // Each Realm should see a different number of objects as they're on different versions
    for (NSUInteger i = 0; i < 10; ++i) {
        XCTAssertEqual(i + 1, [IntObject allObjectsInRealm:realms[i]].count);
    }

    RLMNotificationToken *tokens[10];

    // asyncify them in reverse order so that the version pin has to go backwards
    for (int i = 9; i >= 0; --i) {
        XCTestExpectation *exp = [self expectationWithDescription:@(i).stringValue];
        tokens[i] = [[IntObject allObjectsInRealm:realms[i]] addNotificationBlock:^(RLMResults *results, RLMCollectionChange *change, NSError *error) {
            XCTAssertEqual(10U, results.count);
            XCTAssertNil(error);
            [exp fulfill];
        }];
    }

    [self waitForExpectationsWithTimeout:2.0 handler:nil];

    for (int i = 0; i < 10; ++i) {
        [tokens[i] invalidate];
    }
}

- (void)testMultipleSourceVersionsWithNotifiersRemovedBeforeRunning {
    RLMRealmConfiguration *config = [RLMRealmConfiguration defaultConfiguration];
    config.cache = false;
    config.configRef.automatic_change_notifications = false;

    // Create ten RLMRealm instances, each with a different read version
    RLMRealm *realms[10];
    for (int i = 0; i < 10; ++i) {
        RLMRealm *realm = realms[i] = [ManualRefreshRealm realmWithConfiguration:config error:nil];
        [realm transactionWithBlock:^{
            [IntObject createInRealm:realm withValue:@[@(i)]];
        }];
    }

    __block int calls = 0;
    RLMNotificationToken *tokens[10];
    @autoreleasepool {
        for (int i = 0; i < 10; ++i) {
            tokens[i] = [[IntObject allObjectsInRealm:realms[i]]
                         addNotificationBlock:^(RLMResults *, RLMCollectionChange *, NSError *) {
                             ++calls;
                         }];
        }

        // Each Realm should see a different number of objects as they're on different versions
        for (NSUInteger i = 0; i < 10; ++i) {
            XCTAssertEqual(i + 1, [IntObject allObjectsInRealm:realms[i]].count);
        }

        // remove all but the last two so that the version pin is for a version
        // that doesn't have a notifier anymore
        for (int i = 0; i < 7; ++i) {
            [tokens[i] invalidate];
        }
    }

    // Let the background job run now
    auto coord = realm::_impl::RealmCoordinator::get_coordinator(config.path);
    coord->on_change();

    for (int i = 7; i < 10; ++i) {
        realms[i]->_realm->notify();
        XCTAssertEqual(calls, i - 6);
    }

    for (int i = 7; i < 10; ++i) {
        [tokens[i] invalidate];
    }
}

- (void)testMultipleCallbacksForOneQuery {
    RLMResults *results = IntObject.allObjects;

    __block int calls1 = 0;
    auto token1 = [self subscribeAndWaitForInitial:results block:^(RLMResults *results) {
        ++calls1;
    }];
    XCTAssertEqual(calls1, 0);

    __block int calls2 = 0;
    auto token2 = [self subscribeAndWaitForInitial:results block:^(RLMResults *results) {
        ++calls2;
    }];
    XCTAssertEqual(calls1, 0);
    XCTAssertEqual(calls2, 0);

    [self waitForNotification:RLMRealmDidChangeNotification realm:results.realm block:^{
        [self createObject:0];
    }];

    XCTAssertEqual(calls1, 1);
    XCTAssertEqual(calls2, 1);

    [token1 invalidate];

    [self waitForNotification:RLMRealmDidChangeNotification realm:results.realm block:^{
        [self createObject:0];
    }];

    XCTAssertEqual(calls1, 1);
    XCTAssertEqual(calls2, 2);

    [token2 invalidate];

    [self waitForNotification:RLMRealmDidChangeNotification realm:results.realm block:^{
        [self createObject:0];
    }];

    XCTAssertEqual(calls1, 1);
    XCTAssertEqual(calls2, 2);
}

- (void)testRemovingBlockFromWithinNotificationBlock {
    RLMResults *results = IntObject.allObjects;

    __block int calls = 0;
    __block RLMNotificationToken *token1, *token2;
    token1 = [self subscribeAndWaitForInitial:results block:^(RLMResults *results) {
        [token1 invalidate];
        ++calls;
    }];
    token2 = [self subscribeAndWaitForInitial:results block:^(RLMResults *results) {
        [token2 invalidate];
        ++calls;
    }];

    [self waitForNotification:RLMRealmDidChangeNotification realm:results.realm block:^{
        [self createObject:0];
    }];

    [self waitForNotification:RLMRealmDidChangeNotification realm:results.realm block:^{
        [self createObject:0];
    }];
    XCTAssertEqual(calls, 2);
}

- (void)testAddingBlockFromWithinNotificationBlock {
    RLMResults *results = IntObject.allObjects;

    __block int calls = 0;
    __block RLMNotificationToken *token1, *token2;
    token1 = [self subscribeAndWaitForInitial:results block:^(RLMResults *results) {
        if (++calls == 1) {
            token2 = [results addNotificationBlock:^(RLMResults *results, RLMCollectionChange *change, NSError *error) {
                ++calls;
            }];
        }
    }];

    // Triggers one call on each block. Nested call is deferred until next refresh.
    [self waitForNotification:RLMRealmDidChangeNotification realm:results.realm block:^{
        [self createObject:0];
    }];
    XCTAssertEqual(calls, 1);
    [results.realm refresh];
    XCTAssertEqual(calls, 2);

    // Triggers one call on each block
    [self waitForNotification:RLMRealmDidChangeNotification realm:results.realm block:^{
        [self createObject:0];
    }];
    XCTAssertEqual(calls, 4);

    [token1 invalidate];
    [token2 invalidate];
}

- (void)testAddingNewQueryWithinNotificationBlock {
    RLMResults *results1 = IntObject.allObjects;
    RLMResults *results2 = IntObject.allObjects;

    __block int calls = 0;
    __block RLMNotificationToken *token1, *token2;
    token1 = [self subscribeAndWaitForInitial:results1 block:^(RLMResults *results) {
        ++calls;
        if (calls == 1) {
            CFRunLoopStop(CFRunLoopGetCurrent());
            token2 = [results2 addNotificationBlock:^(RLMResults *results, RLMCollectionChange *change, NSError *error) {
                CFRunLoopStop(CFRunLoopGetCurrent());
                ++calls;
            }];
        }
    }];

    // Triggers one call on outer block, but inner does not get a chance to deliver
    [self dispatchAsync:^{ [self createObject:0]; }];
    CFRunLoopRun();
    XCTAssertEqual(calls, 1);

    // Pick up the initial run of the inner block
    CFRunLoopRun();
    assert(calls == 2);
    XCTAssertEqual(calls, 2);

    // Triggers a call on each block
    [self dispatchAsync:^{ [self createObject:0]; }];
    CFRunLoopRun();
    XCTAssertEqual(calls, 4);

    [token1 invalidate];
    [token2 invalidate];
}

- (void)testAddingNewQueryWithinRealmNotificationBlock {
    __block RLMNotificationToken *queryToken;
    __block XCTestExpectation *exp;
    auto realmToken = [RLMRealm.defaultRealm addNotificationBlock:^(RLMNotification notification, RLMRealm *realm) {
        CFRunLoopStop(CFRunLoopGetCurrent());
        exp = [self expectationWithDescription:@"query notification"];
        queryToken = [IntObject.allObjects addNotificationBlock:^(RLMResults *results, RLMCollectionChange *change, NSError *e) {
            [exp fulfill];
        }];
    }];

    // Make a background commit to trigger a Realm notification
    [self dispatchAsync:^{ [RLMRealm.defaultRealm transactionWithBlock:^{}]; }];

    // Wait for the notification
    CFRunLoopRun();
    [realmToken invalidate];

    // Wait for the initial async query results created within the notification
    [self waitForExpectationsWithTimeout:2.0 handler:nil];
    [queryToken invalidate];
}

- (void)testBlockedThreadWithNotificationsDoesNotPreventDeliveryOnOtherThreads {
    dispatch_group_t group1 = dispatch_group_create();
    dispatch_group_t group2 = dispatch_group_create();
    // Add a notification block on a background thread, run the runloop
    // until the initial results are ready, and then block the thread without
    // running the runloop until the main thread is done testing things
    __block RLMNotificationToken *token;
    dispatch_group_enter(group1);
    dispatch_group_enter(group2);
    token = [IntObject.allObjects addNotificationBlock:^(RLMResults *, RLMCollectionChange *, NSError *) {
        dispatch_group_leave(group1);
        dispatch_group_wait(group2, DISPATCH_TIME_FOREVER);
    } queue:self.bgQueue];

    dispatch_group_wait(group1, DISPATCH_TIME_FOREVER);

    __block int calls = 0;
    auto token2 = [self subscribeAndWaitForInitial:IntObject.allObjects block:^(RLMResults *results) {
        ++calls;
    }];
    XCTAssertEqual(calls, 0);

    [self waitForNotification:RLMRealmDidChangeNotification realm:RLMRealm.defaultRealm block:^{
        [self createObject:0];
    }];
    XCTAssertEqual(calls, 1);

    [token invalidate];
    [token2 invalidate];
    dispatch_group_leave(group2);
}

- (void)testAddNotificationBlockFromWrongThread {
    RLMResults *results = [IntObject allObjects];
    [self dispatchAsyncAndWait:^{
        CFRunLoopPerformBlock(CFRunLoopGetCurrent(), kCFRunLoopDefaultMode, ^{
            XCTAssertThrows([results addNotificationBlock:^(RLMResults *results, RLMCollectionChange *change, NSError *error) {
                XCTFail(@"should not be called");
            }]);
            CFRunLoopStop(CFRunLoopGetCurrent());
        });
        CFRunLoopRun();
    }];
}

- (void)testAddNotificationBlockFromWrongQueue {
    auto queue = dispatch_queue_create("background queue", DISPATCH_QUEUE_SERIAL);
    __block RLMResults *results;
    dispatch_sync(queue, ^{
        RLMRealm *realm = [RLMRealm defaultRealmForQueue:queue];
        results = [IntObject allObjectsInRealm:realm];
    });
    XCTAssertThrows([results addNotificationBlock:^(RLMResults *results, RLMCollectionChange *change, NSError *error) {
        XCTFail(@"should not be called");
    }]);
}

- (void)testRemoveNotificationBlockFromWrongThread {
    // Unlike adding this is allowed, because it can happen due to capturing
    // tokens in blocks and users are very confused by errors from deallocation
    // on the wrong thread
    RLMResults *results = [IntObject allObjects];
    auto token = [results addNotificationBlock:^(RLMResults *results, RLMCollectionChange *change, NSError *error) {
        XCTFail(@"should not be called");
    }];
    [self dispatchAsyncAndWait:^{
        [token invalidate];
    }];
}

- (void)testSimultaneouslyRemoveCallbacksFromCallbacksForOtherResults {
    dispatch_semaphore_t sema1 = dispatch_semaphore_create(0);
    dispatch_semaphore_t sema2 = dispatch_semaphore_create(0);
    __block RLMNotificationToken *token1, *token2;

    [self dispatchAsync:^{
        CFRunLoopPerformBlock(CFRunLoopGetCurrent(), kCFRunLoopDefaultMode, ^{
            __block bool first = true;
            token1 = [IntObject.allObjects addNotificationBlock:^(RLMResults *results, RLMCollectionChange *change, NSError *error) {
                XCTAssertTrue(first);
                first = false;
                dispatch_semaphore_signal(sema1);
                dispatch_semaphore_wait(sema2, DISPATCH_TIME_FOREVER);
                [token2 invalidate];
                CFRunLoopStop(CFRunLoopGetCurrent());
            }];
        });
        CFRunLoopRun();
    }];

    CFRunLoopPerformBlock(CFRunLoopGetCurrent(), kCFRunLoopDefaultMode, ^{
        __block bool first = true;
        token2 = [IntObject.allObjects addNotificationBlock:^(RLMResults *results, RLMCollectionChange *change, NSError *error) {
            XCTAssertTrue(first);
            first = false;
            dispatch_semaphore_signal(sema2);
            dispatch_semaphore_wait(sema1, DISPATCH_TIME_FOREVER);
            [token1 invalidate];
            CFRunLoopStop(CFRunLoopGetCurrent());
        }];
    });
    CFRunLoopRun();
}

- (void)testAsyncNotSupportedForReadOnlyRealms {
    @autoreleasepool { [RLMRealm defaultRealm]; }

    RLMRealmConfiguration *config = [RLMRealmConfiguration defaultConfiguration];
    config.readOnly = true;
    RLMRealm *realm = [RLMRealm realmWithConfiguration:config error:nil];

    XCTAssertThrows([[IntObject allObjectsInRealm:realm] addNotificationBlock:^(RLMResults *results, RLMCollectionChange *change, NSError *error) {
        XCTFail(@"should not be called");
    }]);
}

- (void)testAsyncNotSupportedAfterMakingChangesInWriteTransactions {
    RLMRealm *realm = [RLMRealm defaultRealm];
    [realm transactionWithBlock:^{
        XCTAssertNoThrow([IntObject.allObjects addNotificationBlock:^(RLMResults *, RLMCollectionChange *, NSError *) {}]);
        [IntObject createInRealm:realm withValue:@[@0]];
        RLMAssertThrowsWithReason([IntObject.allObjects addNotificationBlock:^(RLMResults *, RLMCollectionChange *, NSError *) {}],
                                  @"Cannot create asynchronous query after making changes in a write transaction.");
        RLMAssertThrowsWithReason([IntObject.allObjects[0] addNotificationBlock:^(BOOL, NSArray *, NSError *) {}],
                                  @"Cannot create asynchronous query after making changes in a write transaction.");
    }];
}

- (void)testTransactionsAfterDeletingArrayLinkView {
    RLMRealm *realm = [RLMRealm defaultRealm];
    [realm beginWriteTransaction];
    IntObject *io = [IntObject createInRealm:realm withValue:@[@5]];
    ArrayPropertyObject *apo = [ArrayPropertyObject createInRealm:realm withValue:@[@"", @[], @[io]]];
    [realm commitWriteTransaction];

    RLMNotificationToken *token1 = [self subscribeAndWaitForInitial:apo.intArray block:^(RLMArray *array) {
        XCTAssertTrue(array.invalidated);
    }];
    RLMResults *asResults = [apo.intArray objectsWhere:@"intCol = 5"];
    RLMNotificationToken *token2 = [self subscribeAndWaitForInitial:asResults block:^(RLMResults *results) {
        XCTAssertEqual(results.count, 0U);
    }];

    // Delete the object containing the RLMArray with notifiers
    [self waitForNotification:RLMRealmDidChangeNotification realm:realm block:^{
        RLMRealm *realm = [RLMRealm defaultRealm];
        [realm transactionWithBlock:^{
            [realm deleteObject:[ArrayPropertyObject allObjectsInRealm:realm].firstObject];
        }];
    }];

    // Perform another transaction while the notifiers are still alive as
    // transactions deleting the RLMArray and transactions with the RLMArray
    // already deleted hit different code paths
    [self waitForNotification:RLMRealmDidChangeNotification realm:realm block:^{
        RLMRealm *realm = [RLMRealm defaultRealm];
        [realm transactionWithBlock:^{
            [ArrayPropertyObject createInRealm:realm withValue:@[@"", @[], @[]]];
        }];
    }];

    [token1 invalidate];
    [token2 invalidate];
}

- (void)testTransactionsAfterDeletingSetLinkView {
    RLMRealm *realm = [RLMRealm defaultRealm];
    [realm beginWriteTransaction];
    IntObject *io = [IntObject createInRealm:realm withValue:@[@5]];
    SetPropertyObject *spo = [SetPropertyObject createInRealm:realm withValue:@[@"", @[], @[io]]];
    [realm commitWriteTransaction];

    RLMNotificationToken *token1 = [self subscribeAndWaitForInitial:spo.intSet block:^(RLMSet *set) {
        XCTAssertTrue(set.invalidated);
    }];
    RLMResults *asResults = [spo.intSet objectsWhere:@"intCol = 5"];
    RLMNotificationToken *token2 = [self subscribeAndWaitForInitial:asResults block:^(RLMResults *results) {
        XCTAssertEqual(results.count, 0U);
    }];

    // Delete the object containing the RLMArray with notifiers
    [self waitForNotification:RLMRealmDidChangeNotification realm:realm block:^{
        RLMRealm *realm = [RLMRealm defaultRealm];
        [realm transactionWithBlock:^{
            [realm deleteObject:[SetPropertyObject allObjectsInRealm:realm].firstObject];
        }];
    }];

    // Perform another transaction while the notifiers are still alive as
    // transactions deleting the RLMArray and transactions with the RLMArray
    // already deleted hit different code paths
    [self waitForNotification:RLMRealmDidChangeNotification realm:realm block:^{
        RLMRealm *realm = [RLMRealm defaultRealm];
        [realm transactionWithBlock:^{
            [SetPropertyObject createInRealm:realm withValue:@[@"", @[], @[]]];
        }];
    }];

    [token1 invalidate];
    [token2 invalidate];
}

- (void)testInitialResultDiscardsChanges {
    auto token = [IntObject.allObjects addNotificationBlock:^(RLMResults *results, RLMCollectionChange *changes, NSError *) {
        XCTAssertEqual(results.count, 1U);
        XCTAssertNil(changes);
        CFRunLoopStop(CFRunLoopGetCurrent());
    }];

    // Make a write on a background thread, and then wait for the notification
    // for that write to be delivered to ensure that the notification we get on
    // the main thread actually would include changes
    dispatch_semaphore_t sema = dispatch_semaphore_create(0);
    [self dispatchAsync:^{
        CFRunLoopPerformBlock(CFRunLoopGetCurrent(), kCFRunLoopDefaultMode, ^{
            auto token = [IntObject.allObjects addNotificationBlock:^(RLMResults *results, RLMCollectionChange *changes, NSError *) {
                if (changes) {
                    dispatch_semaphore_signal(sema);
                    CFRunLoopStop(CFRunLoopGetCurrent());
                }
            }];

            [RLMRealm.defaultRealm transactionWithBlock:^{
                [IntObject createInDefaultRealmWithValue:@[@0]];
            }];

            CFRunLoopRun();
            [token invalidate];
            CFRunLoopStop(CFRunLoopGetCurrent());
        });
        CFRunLoopRun();
    }];

    dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
    CFRunLoopRun();
    [token invalidate];
}

- (void)testNotificationDeliveryToQueue {
    RLMRealm *realm = [RLMRealm defaultRealm];
    __block RLMNotificationToken *token;
    dispatch_semaphore_t sema = dispatch_semaphore_create(0);

    [self dispatchAsync:^{
        RLMRealm *bgRealm = [RLMRealm defaultRealmForQueue:self.bgQueue];
        token = [[IntObject allObjectsInRealm:bgRealm] addNotificationBlock:^(RLMResults *results, RLMCollectionChange *, NSError *) {
            XCTAssertNotNil(results);
            XCTAssertNoThrow(results.count);
            dispatch_semaphore_signal(sema);
        }];
    }];
    dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);

    [realm transactionWithBlock:^{
        [IntObject createInRealm:realm withValue:@[@1]];
    }];
    dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
    [token invalidate];
}

@end
