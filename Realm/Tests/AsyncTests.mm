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

#import "impl/realm_coordinator.hpp"

#import <realm/string_data.hpp>

#import <sys/resource.h>

// A whole bunch of blocks don't use their RLMResults parameter
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
    auto token = [[IntObject objectsWhere:@"intCol > 0"] addNotificationBlock:^(RLMResults *results, RLMCollectionChange *change, NSError *e) {
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
    [token stop];
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
    [token stop];
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
    [token stop];
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
    [token stop];
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
    [token stop];
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
    [token stop];
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
    [token stop];
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
    [token stop];
}

- (void)testQueryingLinkList {
    RLMRealm *realm = [RLMRealm defaultRealm];
    [realm beginWriteTransaction];
    ArrayPropertyObject *array = [ArrayPropertyObject createInRealm:realm withValue:@[@"", @[], @[]]];
    [realm commitWriteTransaction];

    __block XCTestExpectation *expectation = [self expectationWithDescription:@""];
    __block int expected = 0;
    auto token = [[array.intArray objectsWhere:@"intCol > 0"] addNotificationBlock:^(RLMResults *results, RLMCollectionChange *change, NSError *e) {
        XCTAssertNil(e);
        XCTAssertNotNil(results);
        XCTAssertEqual((int)results.count, expected);
        for (int i = 0; i < expected; ++i) {
            XCTAssertEqual([results[i] intCol], i + 1);
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

    [token stop];
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

    [token stop];
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
    [token stop];
}

- (void)testStaleResultsAreDiscardedWhenThreadIsBlocked {
    XCTestExpectation *expectation = [self expectationWithDescription:@""];
    auto token = [IntObject.allObjects addNotificationBlock:^(RLMResults *results, RLMCollectionChange *change, NSError *e) {
        // Will fail if this is called with the initial results
        XCTAssertEqual(1U, results.count);
        // Will fail if it's called twice
        [expectation fulfill];
    }];

    dispatch_semaphore_t sema = dispatch_semaphore_create(0);

    // Add a notification block on a background thread and wait for it to have been added
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        @autoreleasepool {
            __block RLMNotificationToken *token;
            CFRunLoopPerformBlock(CFRunLoopGetCurrent(), kCFRunLoopDefaultMode, ^{
                token = [RLMRealm.defaultRealm addNotificationBlock:^(RLMNotification notification, RLMRealm *realm) {
                    CFRunLoopStop(CFRunLoopGetCurrent());
                    dispatch_semaphore_signal(sema);
                    [token stop];
                    token = nil;
                }];
                dispatch_semaphore_signal(sema);
            });

            CFRunLoopRun();
        }
        dispatch_semaphore_signal(sema);
    });
    dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);

    // Make a commit on a background thread, and wait for the notification for
    // it to have been sent to the other background thread (which happens only
    // after all queries have run)
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        @autoreleasepool {
            [RLMRealm.defaultRealm transactionWithBlock:^{
                [IntObject createInDefaultRealmWithValue:@[@0]];
            } error:nil];
        }
    });
    dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);

    // Only now let the main thread pick up the notifications
    [self waitForExpectationsWithTimeout:2.0 handler:nil];
    [token stop];
    dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
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

    [token stop];
    [token2 stop];
}

- (void)testErrorHandling {
    RLMRealm *realm = [RLMRealm defaultRealm];
    XCTestExpectation *exp = [self expectationWithDescription:@""];

    // Set the max open files to zero so that opening new files will fail
    rlimit oldrl;
    getrlimit(RLIMIT_NOFILE, &oldrl);
    rlimit rl = oldrl;
    rl.rlim_cur = 0;
    setrlimit(RLIMIT_NOFILE, &rl);

    // Will try to open another copy of the file for the pin SG
    __block bool called = false;
    auto token = [IntObject.allObjects addNotificationBlock:^(RLMResults *results, RLMCollectionChange *change, NSError *error) {
        XCTAssertNil(results);
        RLMValidateRealmError(error, RLMErrorFileAccess, @"Too many open files", nil);
        called = true;
        [exp fulfill];
    }];

    // Restore the old open file limit now so that we can make commits
    setrlimit(RLIMIT_NOFILE, &oldrl);

    // Block should still be called asynchronously
    XCTAssertFalse(called);
    [self waitForExpectationsWithTimeout:2.0 handler:nil];
    XCTAssertTrue(called);

    // Neither adding a new async query nor commiting a write transaction should
    // cause it to resend the error
    XCTestExpectation *exp2 = [self expectationWithDescription:@""];
    auto token2 = [IntObject.allObjects addNotificationBlock:^(RLMResults *results, RLMCollectionChange *change, NSError *error) {
        XCTAssertNil(results);
        RLMValidateRealmError(error, RLMErrorFileAccess, @"Too many open files", nil);
        [exp2 fulfill];
    }];
    [realm beginWriteTransaction];
    [IntObject createInDefaultRealmWithValue:@[@0]];
    [realm commitWriteTransaction];

    [self waitForExpectationsWithTimeout:2.0 handler:nil];

    [token stop];
    [token2 stop];
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
    [token stop];
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

    [token stop];
    XCTAssertNoThrow([RLMRealm realmWithConfiguration:config error:nil]);
}

- (void)testAddAndRemoveQueries {
    RLMRealm *realm = [RLMRealm defaultRealm];
    @autoreleasepool {
        RLMResults *results = IntObject.allObjects;
        [[self subscribeAndWaitForInitial:results block:^(RLMResults *r) {
            XCTFail(@"results delivered after removal");
        }] stop];

        // Readd same results at same version
        [[self subscribeAndWaitForInitial:results block:^(RLMResults *r) {
            XCTFail(@"results delivered after removal");
        }] stop];

        // Add different results at same version
        [[self subscribeAndWaitForInitial:IntObject.allObjects block:^(RLMResults *r) {
            XCTFail(@"results delivered after removal");
        }] stop];

        [self waitForNotification:RLMRealmDidChangeNotification realm:RLMRealm.defaultRealm block:^{
            [RLMRealm.defaultRealm transactionWithBlock:^{ }];
        }];

        // Readd at later version
        [[self subscribeAndWaitForInitial:results block:^(RLMResults *r) {
            XCTFail(@"results delivered after removal");
        }] stop];

        // Add different results at later version
        [[self subscribeAndWaitForInitial:[IntObject allObjectsInRealm:realm] block:^(RLMResults *r) {
            XCTFail(@"results delivered after removal");
        }] stop];
    }

    // Add different results after all of the previous async queries have been
    // removed entirely
    [[self subscribeAndWaitForInitial:[IntObject allObjectsInRealm:realm] block:^(RLMResults *r) {
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
        [tokens[i] stop];
    }
}

- (void)testMultipleSourceVersionsWithNotifiersRemovedBeforeRunning {
    RLMRealmConfiguration *config = [RLMRealmConfiguration defaultConfiguration];
    config.cache = false;
    config.config.automatic_change_notifications = false;

    // Create ten RLMRealm instances, each with a different read version
    RLMRealm *realms[10];
    for (int i = 0; i < 10; ++i) {
        RLMRealm *realm = realms[i] = [RLMRealm realmWithConfiguration:config error:nil];
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
            [tokens[i] stop];
        }
    }

    // Let the background job run now
    auto coord = realm::_impl::RealmCoordinator::get_existing_coordinator(config.config.path);
    coord->on_change();

    for (int i = 7; i < 10; ++i) {
        realms[i]->_realm->notify();
        XCTAssertEqual(calls, i - 6);
    }

    for (int i = 7; i < 10; ++i) {
        [tokens[i] stop];
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

    [token1 stop];

    [self waitForNotification:RLMRealmDidChangeNotification realm:results.realm block:^{
        [self createObject:0];
    }];

    XCTAssertEqual(calls1, 1);
    XCTAssertEqual(calls2, 2);

    [token2 stop];

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
        [token1 stop];
        ++calls;
    }];
    token2 = [self subscribeAndWaitForInitial:results block:^(RLMResults *results) {
        [token2 stop];
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

    // Triggers one call on each block
    [self waitForNotification:RLMRealmDidChangeNotification realm:results.realm block:^{
        [self createObject:0];
    }];
    XCTAssertEqual(calls, 2);

    // Triggers one call on each block
    [self waitForNotification:RLMRealmDidChangeNotification realm:results.realm block:^{
        [self createObject:0];
    }];
    XCTAssertEqual(calls, 4);

    [token1 stop];
    [token2 stop];
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

    [token1 stop];
    [token2 stop];
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
    [realmToken stop];

    // Wait for the initial async query results created within the notification
    [self waitForExpectationsWithTimeout:2.0 handler:nil];
    [queryToken stop];
}

- (void)testBlockedThreadWithNotificationsDoesNotPreventDeliveryOnOtherThreads {
    dispatch_semaphore_t sema = dispatch_semaphore_create(0);
    dispatch_semaphore_t sema2 = dispatch_semaphore_create(0);
    [self dispatchAsync:^{
        // Add a notification block on a background thread, run the runloop
        // until the initial results are ready, and then block the thread without
        // running the runloop until the main thread is done testing things
        __block RLMNotificationToken *token;
        CFRunLoopPerformBlock(CFRunLoopGetCurrent(), kCFRunLoopDefaultMode, ^{
            token = [IntObject.allObjects addNotificationBlock:^(RLMResults *results, RLMCollectionChange *change, NSError *error) {
                dispatch_semaphore_signal(sema);
                CFRunLoopStop(CFRunLoopGetCurrent());
                dispatch_semaphore_wait(sema2, DISPATCH_TIME_FOREVER);
            }];
        });
        CFRunLoopRun();
        [token stop];
    }];
    dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);

    __block int calls = 0;
    auto token = [self subscribeAndWaitForInitial:IntObject.allObjects block:^(RLMResults *results) {
        ++calls;
    }];
    XCTAssertEqual(calls, 0);

    [self waitForNotification:RLMRealmDidChangeNotification realm:RLMRealm.defaultRealm block:^{
        [self createObject:0];
    }];
    XCTAssertEqual(calls, 1);

    [token stop];
    dispatch_semaphore_signal(sema2);
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

- (void)testRemoveNotificationBlockFromWrongThread {
    // Unlike adding this is allowed, because it can happen due to capturing
    // tokens in blocks and users are very confused by errors from deallocation
    // on the wrong thread
    RLMResults *results = [IntObject allObjects];
    auto token = [results addNotificationBlock:^(RLMResults *results, RLMCollectionChange *change, NSError *error) {
        XCTFail(@"should not be called");
    }];
    [self dispatchAsyncAndWait:^{
        [token stop];
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
                [token2 stop];
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
            [token1 stop];
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

- (void)testAsyncNotSupportedInWriteTransactions {
    [RLMRealm.defaultRealm transactionWithBlock:^{
        XCTAssertThrows([IntObject.allObjects addNotificationBlock:^(RLMResults *results, RLMCollectionChange *change, NSError *error) {
            XCTFail(@"should not be called");
        }]);
    }];
}

- (void)testTransactionsAfterDeletingLinkView {
    RLMRealm *realm = [RLMRealm defaultRealm];
    [realm beginWriteTransaction];
    IntObject *io = [IntObject createInRealm:realm withValue:@[@5]];
    ArrayPropertyObject *apo = [ArrayPropertyObject createInRealm:realm withValue:@[@"", @[], @[io]]];
    [realm commitWriteTransaction];

    RLMNotificationToken *token1 = [self subscribeAndWaitForInitial:apo.intArray block:^(RLMArray *array) {
        XCTAssertEqual(array.count, 0U);
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

    [token1 stop];
    [token2 stop];
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
            [token stop];
            CFRunLoopStop(CFRunLoopGetCurrent());
        });
        CFRunLoopRun();
    }];

    dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
    CFRunLoopRun();
    [token stop];
}

@end
