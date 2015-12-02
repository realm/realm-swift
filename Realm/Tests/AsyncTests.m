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

#import "RLMRealmConfiguration_Private.h"

#pragma clang diagnostic ignored "-Wunused-parameter"

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
    id token = [[IntObject objectsWhere:@"intCol > 0"] addNotificationBlock:^(RLMResults *results, NSError *e) {
        XCTAssertNil(e);
        XCTAssertEqualObjects(results.objectClassName, @"IntObject");
        XCTAssertEqual(results.count, 1U);
        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:2.0 handler:nil];
    [token stop];
}

- (void)testNewResultsAreDeliveredAfterLocalCommit {
    __block XCTestExpectation *expectation = [self expectationWithDescription:@""];
    __block NSUInteger expected = 0;
    id token = [[IntObject objectsWhere:@"intCol > 0"] addNotificationBlock:^(RLMResults *results, NSError *e) {
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
    [token stop];
}

- (void)testNewResultsAreDeliveredAfterBackgroundCommit {
    __block XCTestExpectation *expectation = [self expectationWithDescription:@""];
    __block NSUInteger expected = 0;
    id token = [[IntObject objectsWhere:@"intCol > 0"] addNotificationBlock:^(RLMResults *results, NSError *e) {
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
    [token stop];
}

- (void)testResultsPerserveQuery {
    __block XCTestExpectation *expectation = [self expectationWithDescription:@""];
    __block NSUInteger expected = 0;
    id token = [[IntObject objectsWhere:@"intCol > 0"] addNotificationBlock:^(RLMResults *results, NSError *e) {
        XCTAssertEqual(results.count, expected);
        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:2.0 handler:nil];

    expectation = [self expectationWithDescription:@""];
    ++expected;
    [self dispatchAsyncAndWait:^{ [self createObject:1]; }];
    [self waitForExpectationsWithTimeout:2.0 handler:nil];

    expectation = [self expectationWithDescription:@""];
    [self dispatchAsyncAndWait:^{ [self createObject:-1]; }];
    [self waitForExpectationsWithTimeout:2.0 handler:nil];
    [token stop];
}

- (void)testResultsPerserveSort {
    __block XCTestExpectation *expectation = [self expectationWithDescription:@""];
    __block int expected = 0;
    id token = [[IntObject.allObjects sortedResultsUsingProperty:@"intCol" ascending:NO] addNotificationBlock:^(RLMResults *results, NSError *e) {
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
    [token stop];
}

- (void)testQueryingDeliveredQueryResults {
    __block XCTestExpectation *expectation = [self expectationWithDescription:@""];
    __block NSUInteger expected = 0;
    id token = [[IntObject objectsWhere:@"intCol > 0"] addNotificationBlock:^(RLMResults *results, NSError *e) {
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
    [token stop];
}

- (void)testQueryingDeliveredTableResults {
    __block XCTestExpectation *expectation = [self expectationWithDescription:@""];
    __block NSUInteger expected = 0;
    id token = [[IntObject allObjects] addNotificationBlock:^(RLMResults *results, NSError *e) {
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
    [token stop];
}

- (void)testQueryingDeliveredSortedResults {
    __block XCTestExpectation *expectation = [self expectationWithDescription:@""];
    __block int expected = 0;
    id token = [[IntObject.allObjects sortedResultsUsingProperty:@"intCol" ascending:NO] addNotificationBlock:^(RLMResults *results, NSError *e) {
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
    [token stop];
}

- (void)testSortingDeliveredResults {
    __block XCTestExpectation *expectation = [self expectationWithDescription:@""];
    __block int expected = 0;
    id token = [[IntObject allObjects] addNotificationBlock:^(RLMResults *results, NSError *e) {
        XCTAssertEqual([[results sortedResultsUsingProperty:@"intCol" ascending:NO].firstObject intCol], expected++);
        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:2.0 handler:nil];

    expectation = [self expectationWithDescription:@""];
    [self dispatchAsyncAndWait:^{ [self createObject:1]; }];
    [self waitForExpectationsWithTimeout:2.0 handler:nil];

    expectation = [self expectationWithDescription:@""];
    [self dispatchAsyncAndWait:^{ [self createObject:2]; }];
    [self waitForExpectationsWithTimeout:2.0 handler:nil];
    [token stop];
}

- (void)testQueryingLinkList {
    RLMRealm *realm = [RLMRealm defaultRealm];
    [realm beginWriteTransaction];
    ArrayPropertyObject *array = [ArrayPropertyObject createInRealm:realm withValue:@[@"", @[], @[]]];
    [realm commitWriteTransaction];

    dispatch_semaphore_t sema = dispatch_semaphore_create(0);
    dispatch_queue_t queue = dispatch_queue_create("queue", 0);
    __block int expected = 0;
    id token = [[array.intArray objectsWhere:@"intCol > 0"] deliverOn:queue block:^(RLMResults *results, NSError *e) {
        XCTAssertNil(e);
        XCTAssertNotNil(results);
        XCTAssertEqual((int)results.count, expected);
        for (int i = 0; i < expected; ++i) {
            XCTAssertEqual([results[i] intCol], i + 1);
        }
        ++expected;
        dispatch_semaphore_signal(sema);
    }];
    dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);

    for (int i = 0; i < 3; ++i) {
        // Create two objects, one in the list and one not, to verify that the
        // LinkList is actually be used
        [realm beginWriteTransaction];
        [IntObject createInRealm:realm withValue:@[@(i + 1)]];
        [array.intArray addObject:[IntObject createInRealm:realm withValue:@[@(i + 1)]]];
        [realm commitWriteTransaction];
        dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
    }
    dispatch_sync(queue, ^{});
    [token stop];
}

- (RLMNotificationToken *)subscribeAndWaitForInitial:(RLMResults *)query block:(void (^)(RLMResults *))block {
    __block XCTestExpectation *exp = [self expectationWithDescription:@"wait for initial results"];
    id token = [query addNotificationBlock:^(RLMResults *results, NSError *e) {
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
    id token = [self subscribeAndWaitForInitial:IntObject.allObjects block:^(RLMResults *results) {
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

    [token stop];
}

- (void)testModifyingUnrelatedTableDoesNotTriggerResend {
    __block XCTestExpectation *expectation = [self expectationWithDescription:@""];
    id token = [[IntObject allObjects] addNotificationBlock:^(RLMResults *results, NSError *e) {
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
    [token stop];
}

- (void)testStaleResultsAreDiscardedWhenTargetQueueIsBlocked {
    dispatch_queue_t queue = dispatch_queue_create("queue", DISPATCH_QUEUE_SERIAL);
    dispatch_semaphore_t sema = dispatch_semaphore_create(0);

    // Block the target queue so that it can't receive the initial results until
    // after we've made another commit
    dispatch_semaphore_t results_ready_sema = dispatch_semaphore_create(0);
    dispatch_async(queue , ^{
        dispatch_semaphore_signal(sema);
        dispatch_semaphore_wait(results_ready_sema, DISPATCH_TIME_FOREVER);

    });
    dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);

    // Set up the async query
    __block int calls = 0;
    id token = [IntObject.allObjects deliverOn:queue block:^(RLMResults *results, NSError *e) {
        ++calls;
        XCTAssertEqual(1U, results.count);
        dispatch_semaphore_signal(sema);
    }];

    [self waitForNotification:RLMRealmDidChangeNotification realm:RLMRealm.defaultRealm block:^{
        [RLMRealm.defaultRealm transactionWithBlock:^{
            [IntObject createInDefaultRealmWithValue:@[@0]];
        } error:nil];
    }];

    dispatch_semaphore_signal(results_ready_sema);
    dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);

    dispatch_sync(queue, ^{});

    // Should only have been called for the update and not the initial results
    XCTAssertEqual(1, calls);
    [token stop];
}

- (void)testStaleResultsAreDiscardedWhenManuallyRefreshing {
}

- (void)testStaleResultsAreDiscardedEvenAfterBeingQueuedForDelivery {
    // This test relies on blocks being called in the order in which they are
    // added, which is an implementation detail that could change

    // This test sets up two async queries, waits for the initial results for
    // each to be ready, and then makes a commit to trigger both at the same
    // time. From the handler for the first, it then makes another commit, so
    // that the results for the second one are for an out-of-date transaction
    // version, and are not delivered.

    __block XCTestExpectation *exp1 = nil;
    __block XCTestExpectation *exp2 = nil;
    __block int firstBlockCalls = 0;
    __block int secondBlockCalls = 0;

    id token = [self subscribeAndWaitForInitial:IntObject.allObjects block:^(RLMResults *results) {
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
    id token2 = [self subscribeAndWaitForInitial:IntObject.allObjects block:^(RLMResults *results) {
        ++secondBlockCalls;
        [exp2 fulfill];
    }];

    exp1 = [self expectationWithDescription:@""];
    exp2 = [self expectationWithDescription:@""];

    [RLMRealm.defaultRealm transactionWithBlock:^{
        [IntObject createInDefaultRealmWithValue:@[@0]];
    } error:nil];

    [self waitForExpectationsWithTimeout:2.0 handler:nil];

    XCTAssertEqual(2, firstBlockCalls);
    XCTAssertEqual(1, secondBlockCalls);

    [token stop];
    [token2 stop];
}

- (void)testDeliverToQueueVersionHandling {
    // This is the same as the above test, except delivering to a background queue

    dispatch_queue_t queue = dispatch_queue_create("queue", 0);
    dispatch_semaphore_t sema = dispatch_semaphore_create(0);
    __block int firstBlockCalls = 0;
    __block int secondBlockCalls = 0;

    id token = [IntObject.allObjects deliverOn:queue block:^(RLMResults *results, NSError *e) {
        ++firstBlockCalls;
        if (firstBlockCalls == 1 || firstBlockCalls == 3) {
            dispatch_semaphore_signal(sema);
        }
        else {
            [results.realm beginWriteTransaction];
            [IntObject createInDefaultRealmWithValue:@[@1]];
            [results.realm commitWriteTransaction];
        }
    }];

    id token2 = [IntObject.allObjects deliverOn:queue block:^(RLMResults *results, NSError *e) {
        ++secondBlockCalls;
        dispatch_semaphore_signal(sema);
    }];

    dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
    dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);

    [RLMRealm.defaultRealm transactionWithBlock:^{
        [IntObject createInDefaultRealmWithValue:@[@0]];
    } error:nil];

    dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
    dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);

    XCTAssertEqual(3, firstBlockCalls);
    XCTAssertEqual(2, secondBlockCalls);

    dispatch_sync(queue, ^{});
    [token stop];
    [token2 stop];
}

- (void)testCancelSubscriptionWithPendingReadyResults {
    // This test relies on the specific order in which things are called after
    // a commit, which is an implementation detail that could change

    dispatch_queue_t queue = dispatch_queue_create("queue", DISPATCH_QUEUE_SERIAL);
    dispatch_semaphore_t sema = dispatch_semaphore_create(0);

    // Create the async query and wait for the first run of it to complete
    __block int calls = 0;
    RLMNotificationToken *queryToken = [IntObject.allObjects deliverOn:queue block:^(RLMResults *results, NSError *e) {
        ++calls;
        dispatch_semaphore_signal(sema);
    }];
    dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);

    // Block the queue which we've asked for results to be delivered on until
    // the main thread gets a commit notification, which happens only after
    // all async queries are ready
    dispatch_semaphore_t results_ready_sema = dispatch_semaphore_create(0);
    dispatch_async(queue , ^{
        dispatch_semaphore_signal(sema);
        dispatch_semaphore_wait(results_ready_sema, DISPATCH_TIME_FOREVER);

    });
    dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);

    [self waitForNotification:RLMRealmDidChangeNotification realm:RLMRealm.defaultRealm block:^{
        [RLMRealm.defaultRealm transactionWithBlock:^{
            [IntObject createInDefaultRealmWithValue:@[@0]];
        } error:nil];
    }];

    [queryToken stop];
    dispatch_semaphore_signal(results_ready_sema);

    dispatch_sync(queue, ^{});

    // Should have been called for the first run, but not after the commit
    XCTAssertEqual(1, calls);
}

- (void)testErrorHandling {
    RLMRealm *realm = [RLMRealm defaultRealm];

    // Force an error when opening the helper SharedGroups by deleting the file
    // after opening the Realm
    [NSFileManager.defaultManager removeItemAtPath:realm.path error:nil];

    __block bool called = false;
    XCTestExpectation *exp = [self expectationWithDescription:@""];
    id token = [IntObject.allObjects addNotificationBlock:^(RLMResults *results, NSError *error) {
        XCTAssertNil(results);
        XCTAssertNotNil(error);
        called = true;
        [exp fulfill];
    }];

    // Block should still be called asyncronously
    XCTAssertFalse(called);

    [self waitForExpectationsWithTimeout:2.0 handler:nil];

    // Neither adding a new async query nor commiting a write transaction should
    // cause it to resend the error
    XCTestExpectation *exp2 = [self expectationWithDescription:@""];
    id token2 = [IntObject.allObjects addNotificationBlock:^(RLMResults *results, NSError *error) {
        XCTAssertNil(results);
        XCTAssertNotNil(error);
        [exp2 fulfill];
    }];
    [realm beginWriteTransaction];
    [IntObject createInDefaultRealmWithValue:@[@0]];
    [realm commitWriteTransaction];

    [self waitForExpectationsWithTimeout:2.0 handler:nil];

    [token stop];
    [token2 stop];
}

- (void)testQueueErrorHandling {
    RLMRealm *realm = [RLMRealm defaultRealm];

    // Force an error when opening the helper SharedGroups by deleting the file
    // after opening the Realm
    [NSFileManager.defaultManager removeItemAtPath:realm.path error:nil];

    dispatch_queue_t queue = dispatch_queue_create("queue", 0);
    dispatch_semaphore_t sema = dispatch_semaphore_create(0);
    __block bool called = false;
    id token = [IntObject.allObjects deliverOn:queue block:^(RLMResults *results, NSError *error) {
        XCTAssertNil(results);
        XCTAssertNotNil(error);
        XCTAssertFalse(called);
        called = true;
        dispatch_semaphore_signal(sema);
    }];
    dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);

    // Neither adding a new async query nor commiting a write transaction should
    // cause it to resend the error
    id token2 = [IntObject.allObjects deliverOn:queue block:^(RLMResults *results, NSError *error) {
        XCTAssertNil(results);
        XCTAssertNotNil(error);
        dispatch_semaphore_signal(sema);
    }];
    [realm beginWriteTransaction];
    [IntObject createInDefaultRealmWithValue:@[@0]];
    [realm commitWriteTransaction];

    dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
    dispatch_sync(queue, ^{});
    [token stop];
    [token2 stop];
}

- (void)testErrorWhenDelivering {
    RLMRealm *realm = [RLMRealm defaultRealm];

    dispatch_queue_t queue = dispatch_queue_create("queue", DISPATCH_QUEUE_SERIAL);
    dispatch_semaphore_t sema = dispatch_semaphore_create(0);

    // Create the async query and wait for the first run of it to complete
    __block bool first = true;
    id token = [IntObject.allObjects deliverOn:queue block:^(RLMResults *results, NSError *e) {
        if (first) {
            XCTAssertNil(e);
            XCTAssertNotNil(results);
            first = false;
        }
        else {
            XCTAssertNil(results);
            XCTAssertNotNil(e);
        }
        dispatch_semaphore_signal(sema);
    }];
    dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);

    // Block the queue which we've asked for results to be delivered on until
    // the main thread gets a commit notification, which happens only after
    // all async queries are ready
    dispatch_semaphore_t results_ready_sema = dispatch_semaphore_create(0);
    dispatch_async(queue , ^{
        dispatch_semaphore_signal(sema);
        dispatch_semaphore_wait(results_ready_sema, DISPATCH_TIME_FOREVER);

        // Once results are ready, delete the Realm file so that delivering them
        // to the queue will fail
        [NSFileManager.defaultManager removeItemAtPath:realm.path error:nil];
    });
    dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);

    [self waitForNotification:RLMRealmDidChangeNotification realm:RLMRealm.defaultRealm block:^{
        [RLMRealm.defaultRealm transactionWithBlock:^{
            [IntObject createInDefaultRealmWithValue:@[@0]];
        } error:nil];
    }];

    dispatch_semaphore_signal(results_ready_sema);

    dispatch_sync(queue, ^{});
    [token stop];
}

- (void)testRLMResultsInstanceIsReusedWhenRetainedExternally {
    dispatch_queue_t queue = dispatch_queue_create("queue", 0);
    dispatch_semaphore_t sema = dispatch_semaphore_create(0);
    __block RLMResults *prev;
    __block bool first = true;
    id token = [IntObject.allObjects deliverOn:queue block:^(RLMResults *results, NSError *e) {
        if (first) {
            prev = results;
            first = false;
        }
        else {
            XCTAssertEqual(prev, results); // deliberately not EqualObjects
        }
        dispatch_semaphore_signal(sema);
    }];
    dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);

    [self createObject:1];
    dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
    [token stop];

    dispatch_sync(queue, ^{});
}

- (void)testRLMResultsInstanceIsHeldWeaklyForDeliverOn {
    dispatch_queue_t queue = dispatch_queue_create("queue", 0);
    dispatch_semaphore_t sema = dispatch_semaphore_create(0);
   __weak __block RLMResults *prev;
    id token = [IntObject.allObjects deliverOn:queue block:^(RLMResults *results, NSError *e) {
        XCTAssertNotNil(results);
        XCTAssertNil(e);
        XCTAssertNil(prev);
        prev = results;
        dispatch_semaphore_signal(sema);
    }];
    dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);

    [self createObject:1];
    dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
    dispatch_sync(queue, ^{});

    XCTAssertNil(prev);
    [token stop];
}

- (void)testRLMResultsInstanceIsHeldStronglyForThreadLocalNotifications {
   __weak __block RLMResults *prev;
    __block bool first = true;

    XCTestExpectation *expectation = [self expectationWithDescription:@""];
    id token = [IntObject.allObjects addNotificationBlock:^(RLMResults *results, NSError *e) {
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
    [token stop];
}

- (void)testCancellationTokenKeepsSubscriptionAlive {
    __block XCTestExpectation *expectation = [self expectationWithDescription:@""];
    RLMNotificationToken *token;
    @autoreleasepool {
        token = [IntObject.allObjects addNotificationBlock:^(RLMResults *results, NSError *err) {
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
        token = [IntObject.allObjects addNotificationBlock:^(RLMResults *results, NSError *err) {
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

    [token stop];
    XCTAssertNoThrow([RLMRealm realmWithConfiguration:config error:nil]);
}

- (void)testResultsAreDeliveredToTheCorrectQueue {
    dispatch_queue_t queues[6];
    for (int i = 0; i < 5; ++i) {
        queues[i] = dispatch_queue_create("background queue", 0);
    }
    queues[5] = dispatch_get_main_queue();

    dispatch_semaphore_t sema = dispatch_semaphore_create(0);
    id tokens[6];
    for (int i = 0; i < 6; ++i) {
        dispatch_queue_t queue = queues[i];
        tokens[i] = [IntObject.allObjects deliverOn:queue block:^(RLMResults *results, NSError *error) {
            XCTAssertNotNil(results);
            XCTAssertNil(error);

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated"
            XCTAssertEqual(dispatch_get_current_queue(), queue);
#pragma clang diagnostic pop

            dispatch_semaphore_signal(sema);
        }];
    }

    dispatch_block_t waitForAll = ^{
        XCTestExpectation *expectation = [self expectationWithDescription:@"background wait"];
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            for (int i = 0; i < 6; ++i) {
                dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
            }
            [expectation fulfill];
        });
        [self waitForExpectationsWithTimeout:2.0 handler:nil];
    };

    waitForAll();

    [self dispatchAsyncAndWait:^{
        [RLMRealm.defaultRealm transactionWithBlock:^{
            [IntObject createInDefaultRealmWithValue:@[@0]];
        }];
    }];

    waitForAll();

    for (int i = 0; i < 5; ++i) {
        dispatch_sync(queues[i], ^{});
        [tokens[i] stop];
    }
}

- (void)testAddAndRemoveQueries {
    [[self subscribeAndWaitForInitial:IntObject.allObjects block:^(RLMResults *r) {
        XCTFail(@"results delivered after removal");
    }] stop];

    // Readd at same version
    [[self subscribeAndWaitForInitial:IntObject.allObjects block:^(RLMResults *r) {
        XCTFail(@"results delivered after removal");
    }] stop];

    [RLMRealm.defaultRealm transactionWithBlock:^{ }];

    // Readd at later version
    [[self subscribeAndWaitForInitial:IntObject.allObjects block:^(RLMResults *r) {
        XCTFail(@"results delivered after removal");
    }] stop];
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

    id tokens[10];

    // asyncify them in reverse order so that the version pin has to go backwards
    for (int i = 9; i >= 0; --i) {
        XCTestExpectation *exp = [self expectationWithDescription:@(i).stringValue];
        tokens[i] = [[IntObject allObjectsInRealm:realms[i]] addNotificationBlock:^(RLMResults *results, NSError *error) {
            XCTAssertEqual(10U, results.count);
            XCTAssertNil(error);
            [exp fulfill];
        }];
    }

    [self waitForExpectationsWithTimeout:2.0 handler:nil];

    for (int i = 0; i < 10; ++i) {
        [tokens[i] stop];
    }
}

- (void)testAsyncNotSupportedForReadOnlyRealms {
    @autoreleasepool { [RLMRealm defaultRealm]; }

    RLMRealmConfiguration *config = [RLMRealmConfiguration defaultConfiguration];
    config.readOnly = true;
    RLMRealm *realm = [RLMRealm realmWithConfiguration:config error:nil];

    XCTAssertThrows([[IntObject allObjectsInRealm:realm] addNotificationBlock:^(RLMResults *results, NSError *error) {
        XCTFail(@"should not be called");
    }]);
}

- (void)testAsyncNotSupportedInWriteTransactions {
    [RLMRealm.defaultRealm transactionWithBlock:^{
        XCTAssertThrows([IntObject.allObjects addNotificationBlock:^(RLMResults *results, NSError *error) {
            XCTFail(@"should not be called");
        }]);
    }];
}

@end
