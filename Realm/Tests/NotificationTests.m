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

@interface NotificationTests : RLMTestCase
@property (nonatomic, strong) RLMNotificationToken *token;
@property (nonatomic) bool called;
@end

@implementation NotificationTests
- (void)setUp {
    @autoreleasepool {
        RLMRealm *realm = [RLMRealm defaultRealm];
        [realm transactionWithBlock:^{
            for (int i = 0; i < 10; ++i)
                [IntObject createInDefaultRealmWithValue:@[@(i)]];
        }];
    }

    _token = [self.query addNotificationBlock:^(RLMResults *results, NSError *error) {
        XCTAssertNotNil(results);
        XCTAssertNil(error);
        self.called = true;
        CFRunLoopStop(CFRunLoopGetCurrent());
    }];
    CFRunLoopRun();
}

- (void)tearDown {
    [_token stop];
    [super tearDown];
}

- (RLMResults *)query {
    return [IntObject objectsWhere:@"intCol > 0 AND intCol < 5"];
}

- (void)runAndWaitForNotification:(void (^)(RLMRealm *))block {
    _called = false;
    [self waitForNotification:RLMRealmDidChangeNotification realm:RLMRealm.defaultRealm block:^{
        RLMRealm *realm = [RLMRealm defaultRealm];
        [realm transactionWithBlock:^{
            block(realm);
        }];
    }];
}

- (void)expectNotification:(void (^)(RLMRealm *))block {
    [self runAndWaitForNotification:block];
    XCTAssertTrue(_called);
}

- (void)expectNoNotification:(void (^)(RLMRealm *))block {
    [self runAndWaitForNotification:block];
    XCTAssertFalse(_called);
}

- (void)testInsertObjectMatchingQuery {
    [self expectNotification:^(RLMRealm *realm) {
        [IntObject createInRealm:realm withValue:@[@3]];
    }];
}

- (void)testInsertObjectNotMatchingQuery {
    [self expectNoNotification:^(RLMRealm *realm) {
        [IntObject createInRealm:realm withValue:@[@10]];
    }];
}

- (void)testModifyObjectMatchingQuery {
    [self expectNotification:^(RLMRealm *realm) {
        [[IntObject objectsInRealm:realm where:@"intCol = 3"] setValue:@4 forKey:@"intCol"];
    }];
}

- (void)testModifyObjectToNoLongerMatchQuery {
    [self expectNotification:^(RLMRealm *realm) {
        [[IntObject objectsInRealm:realm where:@"intCol = 3"] setValue:@5 forKey:@"intCol"];
    }];
}

- (void)testModifyObjectNotMatchingQuery {
    [self expectNoNotification:^(RLMRealm *realm) {
        [[IntObject objectsInRealm:realm where:@"intCol = 5"] setValue:@6 forKey:@"intCol"];
    }];
}

- (void)testModifyObjectToMatchQuery {
    [self expectNotification:^(RLMRealm *realm) {
        [[IntObject objectsInRealm:realm where:@"intCol = 5"] setValue:@4 forKey:@"intCol"];
    }];
}

- (void)testDeleteObjectMatchingQuery {
    [self expectNotification:^(RLMRealm *realm) {
        [realm deleteObjects:[IntObject objectsInRealm:realm where:@"intCol = 4"]];
    }];
}

- (void)testDeleteObjectNotMatchingQuery {
    [self expectNoNotification:^(RLMRealm *realm) {
        [realm deleteObjects:[IntObject objectsInRealm:realm where:@"intCol = 5"]];
    }];
    [self expectNoNotification:^(RLMRealm *realm) {
        [realm deleteObjects:[IntObject objectsInRealm:realm where:@"intCol = 0"]];
    }];
}

- (void)testNonMatchingObjectMovedToIndexOfMatchingRowAndMadeMatching {
    [self expectNotification:^(RLMRealm *realm) {
        // Make the last object match the query
        [[[IntObject allObjectsInRealm:realm] lastObject] setIntCol:3];
        // Move the now-matching object over a previously matching object
        [realm deleteObjects:[IntObject objectsInRealm:realm where:@"intCol = 2"]];
    }];
}
@end

@interface SortedNotificationTests : NotificationTests
@end
@implementation SortedNotificationTests
- (RLMResults *)query {
    return [[IntObject objectsWhere:@"intCol > 0 AND intCol < 5"] sortedResultsUsingProperty:@"intCol" ascending:NO];
}

- (void)testMoveMatchingObjectDueToDeletionOfNonMatchingObject {
    [self expectNoNotification:^(RLMRealm *realm) {
        // Make a matching object be the last row
        [realm deleteObjects:[IntObject objectsInRealm:realm where:@"intCol >= 5"]];
        // Delete a non-last, non-match row so that a matched row is moved
        [realm deleteObjects:[IntObject objectsInRealm:realm where:@"intCol = 0"]];
    }];
}

- (void)testMultipleMovesOfSingleRow {
    [self expectNotification:^(RLMRealm *realm) {
        [realm deleteObjects:[IntObject allObjectsInRealm:realm]];
        [IntObject createInRealm:realm withValue:@[@10]];
        [IntObject createInRealm:realm withValue:@[@10]];
        [IntObject createInRealm:realm withValue:@[@3]];
    }];

    [self expectNoNotification:^(RLMRealm *realm) {
        RLMResults *objects = [IntObject allObjectsInRealm:realm];
        [realm deleteObject:objects[1]];
        [realm deleteObject:objects[0]];
    }];
}
@end

static NSNumber *NotFound;

@interface ChangesetTests : RLMTestCase
@property (nonatomic, strong) RLMNotificationToken *token;
@property (nonatomic, strong) NSArray<RLMObjectChange *> *changes;
@end

@implementation ChangesetTests

+ (void)setUp {
    [super setUp];
    NotFound = @(NSNotFound);
}

- (void)expectChange:(NSArray *)expected
                from:(void (^)(RLMRealm *))block {
    @autoreleasepool {
        RLMRealm *realm = [RLMRealm defaultRealm];
        [realm transactionWithBlock:^{
            [realm deleteAllObjects];
            for (int i = 0; i < 10; ++i) {
                IntObject *io = [IntObject createInDefaultRealmWithValue:@[@(i)]];
                [ArrayPropertyObject createInDefaultRealmWithValue:@[@"", @[], @[io]]];
            }
        }];
    }

    __block bool first = true;
    _token = [self.query addNotificationBlockWatchingKeypaths:@[]
                                                      changes:^(RLMResults *results,
                                                                NSArray<RLMObjectChange *> *changes,
                                                                NSError *error) {
        XCTAssertNotNil(results);
        XCTAssertNil(error);
        _changes = changes;
        XCTAssertTrue(first || changes);
        first = false;
        CFRunLoopStop(CFRunLoopGetCurrent());
    }];
    CFRunLoopRun();

    [self waitForNotification:RLMRealmDidChangeNotification realm:RLMRealm.defaultRealm block:^{
        RLMRealm *realm = [RLMRealm defaultRealm];
        [realm transactionWithBlock:^{
            block(realm);
        }];
    }];

    [_token stop];
    _token = nil;

    if (!expected) {
        XCTAssertNil(_changes);
        return;
    }

    XCTAssertEqual(expected.count, _changes.count);
    if (expected.count != _changes.count) {
        return;
    }

    for (NSUInteger i = 0; i < expected.count; ++i) {
        XCTAssertEqual([expected[i][0] unsignedIntegerValue], _changes[i].oldIndex);
        XCTAssertEqual([expected[i][1] unsignedIntegerValue], _changes[i].newIndex);
    }
}

- (RLMResults *)query {
    return [IntObject objectsWhere:@"intCol > 0 AND intCol < 5"];
}

- (void)testDeleteMultiple {
    [self expectChange:nil from:^(RLMRealm *realm) {
        [realm deleteObjects:[IntObject objectsInRealm:realm where:@"intCol > 4"]];
    }];
    [self expectChange:nil from:^(RLMRealm *realm) {
        [realm deleteObjects:[IntObject objectsInRealm:realm where:@"intCol > 4"]];
    }];
    [self expectChange:nil from:^(RLMRealm *realm) {
        [realm deleteObjects:[IntObject objectsInRealm:realm where:@"intCol > 5"]];
        [realm deleteObjects:[IntObject objectsInRealm:realm where:@"intCol = 0"]];
    }];

    [self expectChange:@[@[@1, NotFound], @[@2, NotFound], @[@3, NotFound]]
                  from:^(RLMRealm *realm) {
        [realm deleteObjects:[IntObject objectsInRealm:realm where:@"intCol > 1"]];
    }];
    [self expectChange:@[@[@1, NotFound], @[@2, NotFound], @[@3, NotFound]]
                  from:^(RLMRealm *realm) {
        [realm deleteObjects:[IntObject objectsInRealm:realm where:@"intCol = 2"]];
        [realm deleteObjects:[IntObject objectsInRealm:realm where:@"intCol = 3"]];
        [realm deleteObjects:[IntObject objectsInRealm:realm where:@"intCol = 4"]];
    }];
    [self expectChange:@[@[@1, NotFound], @[@2, NotFound], @[@3, NotFound]]
                  from:^(RLMRealm *realm) {
        [realm deleteObjects:[IntObject objectsInRealm:realm where:@"intCol = 4"]];
        [realm deleteObjects:[IntObject objectsInRealm:realm where:@"intCol = 3"]];
        [realm deleteObjects:[IntObject objectsInRealm:realm where:@"intCol = 2"]];
    }];

    [self expectChange:@[@[@3, @0]] from:^(RLMRealm *realm) {
        [realm deleteObjects:[IntObject objectsInRealm:realm where:@"intCol > 4"]];
        [realm deleteObjects:[IntObject objectsInRealm:realm where:@"intCol < 1"]];
    }];
}

- (void)testDeleteNewlyInsertedRowMatchingQuery {
    [self expectChange:nil from:^(RLMRealm *realm) {
        [IntObject createInRealm:realm withValue:@[@3]];
        [realm deleteObject:[IntObject allObjectsInRealm:realm].lastObject];
    }];
}

- (void)testInsertObjectMatchingQuery {
    [self expectChange:@[@[NotFound, @4]] from:^(RLMRealm *realm) {
        [IntObject createInRealm:realm withValue:@[@3]];
    }];
}

- (void)testInsertObjectNotMatchingQuery {
    [self expectChange:nil from:^(RLMRealm *realm) {
        [IntObject createInRealm:realm withValue:@[@5]];
    }];
}

- (void)testInsertBothMatchingAndNonMatching {
    [self expectChange:@[@[NotFound, @4]] from:^(RLMRealm *realm) {
        [IntObject createInRealm:realm withValue:@[@5]];
        [IntObject createInRealm:realm withValue:@[@3]];
    }];
}

- (void)testInsertMultipleMatching {
    [self expectChange:@[@[NotFound, @4], @[NotFound, @5]] from:^(RLMRealm *realm) {
        [IntObject createInRealm:realm withValue:@[@5]];
        [IntObject createInRealm:realm withValue:@[@3]];
        [IntObject createInRealm:realm withValue:@[@5]];
        [IntObject createInRealm:realm withValue:@[@2]];
    }];
}

- (void)testModifyObjectMatchingQuery {
    [self expectChange:@[@[@2, @2]] from:^(RLMRealm *realm) {
        [[IntObject objectsInRealm:realm where:@"intCol = 3"] setValue:@4 forKey:@"intCol"];
    }];
}

- (void)testModifyObjectToNoLongerMatchQuery {
    [self expectChange:@[@[@2, NotFound]] from:^(RLMRealm *realm) {
        [[IntObject objectsInRealm:realm where:@"intCol = 3"] setValue:@5 forKey:@"intCol"];
    }];
}

- (void)testModifyObjectNotMatchingQuery {
    [self expectChange:nil from:^(RLMRealm *realm) {
        [[IntObject objectsInRealm:realm where:@"intCol = 5"] setValue:@6 forKey:@"intCol"];
    }];
}

- (void)testModifyObjectToMatchQuery {
    [self expectChange:@[@[NotFound, @4]] from:^(RLMRealm *realm) {
        [[IntObject objectsInRealm:realm where:@"intCol = 5"] setValue:@4 forKey:@"intCol"];
    }];
}

- (void)testDeleteObjectMatchingQuery {
    [self expectChange:@[@[@0, NotFound]] from:^(RLMRealm *realm) {
        [realm deleteObjects:[IntObject objectsInRealm:realm where:@"intCol = 1"]];
    }];
    [self expectChange:@[@[@3, NotFound]] from:^(RLMRealm *realm) {
        [realm deleteObjects:[IntObject objectsInRealm:realm where:@"intCol = 4"]];
    }];
}

- (void)testDeleteNonMatchingBeforeMatches {
    [self expectChange:nil from:^(RLMRealm *realm) {
        [realm deleteObjects:[IntObject objectsInRealm:realm where:@"intCol = 0"]];
    }];
}

- (void)testDeleteNonMatchingAfterMatches {
    [self expectChange:nil from:^(RLMRealm *realm) {
        [realm deleteObjects:[IntObject objectsInRealm:realm where:@"intCol = 5"]];
    }];
}

- (void)testMoveMatchingObjectDueToDeletionOfNonMatchingObject {
    [self expectChange:@[@[@3, @0]] from:^(RLMRealm *realm) {
        // Make a matching object be the last row
        [realm deleteObjects:[IntObject objectsInRealm:realm where:@"intCol >= 5"]];
        // Delete a non-last, non-match row so that a matched row is moved
        [realm deleteObjects:[IntObject objectsInRealm:realm where:@"intCol = 0"]];
    }];
}

- (void)testNonMatchingObjectMovedToIndexOfMatchingRowAndMadeMatching {
    [self expectChange:@[@[@1, @1]] from:^(RLMRealm *realm) {
        // Make the last object match the query
        [[[IntObject allObjectsInRealm:realm] lastObject] setIntCol:3];
        // Move the now-matching object over a previously matching object
        [realm deleteObjects:[IntObject objectsInRealm:realm where:@"intCol = 2"]];
    }];
}

@end

@interface LinkViewChangesetTests : RLMTestCase
@property (nonatomic, strong) RLMNotificationToken *token;
@property (nonatomic, strong) NSArray<RLMObjectChange *> *changes;
@end

@implementation LinkViewChangesetTests

+ (void)setUp {
    [super setUp];
    NotFound = @(NSNotFound);
}

- (void)expectChange:(NSArray *)expected
                from:(void (^)(RLMRealm *))block {
    @autoreleasepool {
        RLMRealm *realm = [RLMRealm defaultRealm];
        [realm transactionWithBlock:^{
            [realm deleteAllObjects];
            for (int i = 0; i < 10; ++i) {
                [IntObject createInDefaultRealmWithValue:@[@(i)]];
            }
            [ArrayPropertyObject createInDefaultRealmWithValue:@[@"", @[], [IntObject allObjectsInRealm:realm]]];
        }];
    }

    @autoreleasepool {
        __block bool first = true;
        _token = [self.query addNotificationBlockWatchingKeypaths:@[] changes:^(RLMResults *results,
                                                                                NSArray<RLMObjectChange *> *changes,
                                                                                NSError *error) {
            XCTAssertNotNil(results);
            XCTAssertNil(error);
            _changes = changes;
            XCTAssertTrue(first || changes);
            first = false;
            CFRunLoopStop(CFRunLoopGetCurrent());
        }];
        CFRunLoopRun();

        [self waitForNotification:RLMRealmDidChangeNotification realm:RLMRealm.defaultRealm block:^{
            RLMRealm *realm = [RLMRealm defaultRealm];
            [realm transactionWithBlock:^{
                block(realm);
            }];
        }];

        [_token stop];
    }

    if (!expected) {
        XCTAssertNil(_changes);
        return;
    }

    XCTAssertEqual(expected.count, _changes.count);
    if (expected.count != _changes.count) {
        return;
    }

    for (NSUInteger i = 0; i < expected.count; ++i) {
        XCTAssertEqual([expected[i][0] unsignedIntegerValue], _changes[i].oldIndex);
        XCTAssertEqual([expected[i][1] unsignedIntegerValue], _changes[i].newIndex);
    }
}

- (RLMResults *)query {
    return [[[ArrayPropertyObject.allObjects firstObject] intArray]
            objectsWhere:@"intCol > 0 AND intCol < 5"];
}

- (void)testDeleteMultiple {
    [self expectChange:nil from:^(RLMRealm *realm) {
        [realm deleteObjects:[IntObject objectsInRealm:realm where:@"intCol > 4"]];
    }];
    [self expectChange:nil from:^(RLMRealm *realm) {
        [realm deleteObjects:[IntObject objectsInRealm:realm where:@"intCol > 5"]];
        [realm deleteObjects:[IntObject objectsInRealm:realm where:@"intCol = 0"]];
    }];

    [self expectChange:@[@[@1, NotFound], @[@2, NotFound], @[@3, NotFound]]
                  from:^(RLMRealm *realm) {
        [realm deleteObjects:[IntObject objectsInRealm:realm where:@"intCol > 1"]];
    }];
    [self expectChange:@[@[@1, NotFound], @[@2, NotFound], @[@3, NotFound]]
                  from:^(RLMRealm *realm) {
        [realm deleteObjects:[IntObject objectsInRealm:realm where:@"intCol = 2"]];
        [realm deleteObjects:[IntObject objectsInRealm:realm where:@"intCol = 3"]];
        [realm deleteObjects:[IntObject objectsInRealm:realm where:@"intCol = 4"]];
    }];
    [self expectChange:@[@[@1, NotFound], @[@2, NotFound], @[@3, NotFound]]
                  from:^(RLMRealm *realm) {
        [realm deleteObjects:[IntObject objectsInRealm:realm where:@"intCol = 4"]];
        [realm deleteObjects:[IntObject objectsInRealm:realm where:@"intCol = 3"]];
        [realm deleteObjects:[IntObject objectsInRealm:realm where:@"intCol = 2"]];
    }];

    [self expectChange:nil from:^(RLMRealm *realm) {
        [realm deleteObjects:[IntObject objectsInRealm:realm where:@"intCol > 4"]];
        [realm deleteObjects:[IntObject objectsInRealm:realm where:@"intCol < 1"]];
    }];
}

- (void)testModifyObjectMatchingQuery {
    [self expectChange:@[@[@2, @2]] from:^(RLMRealm *realm) {
        [[IntObject objectsInRealm:realm where:@"intCol = 3"] setValue:@4 forKey:@"intCol"];
    }];
}

- (void)testModifyObjectToNoLongerMatchQuery {
    [self expectChange:@[@[@2, NotFound]] from:^(RLMRealm *realm) {
        [[IntObject objectsInRealm:realm where:@"intCol = 3"] setValue:@5 forKey:@"intCol"];
    }];
}

- (void)testModifyObjectNotMatchingQuery {
    [self expectChange:nil from:^(RLMRealm *realm) {
        [[IntObject objectsInRealm:realm where:@"intCol = 5"] setValue:@6 forKey:@"intCol"];
    }];
}

- (void)testModifyObjectToMatchQuery {
    [self expectChange:@[@[NotFound, @4]] from:^(RLMRealm *realm) {
        [[IntObject objectsInRealm:realm where:@"intCol = 5"] setValue:@4 forKey:@"intCol"];
    }];
}

- (void)testDeleteObjectMatchingQuery {
    [self expectChange:@[@[@0, NotFound]] from:^(RLMRealm *realm) {
        [realm deleteObjects:[IntObject objectsInRealm:realm where:@"intCol = 1"]];
    }];
    [self expectChange:@[@[@3, NotFound]] from:^(RLMRealm *realm) {
        [realm deleteObjects:[IntObject objectsInRealm:realm where:@"intCol = 4"]];
    }];
}

- (void)testDeleteNonMatchingBeforeMatches {
    [self expectChange:nil from:^(RLMRealm *realm) {
        [realm deleteObjects:[IntObject objectsInRealm:realm where:@"intCol = 0"]];
    }];
}

- (void)testDeleteNonMatchingAfterMatches {
    [self expectChange:nil from:^(RLMRealm *realm) {
        [realm deleteObjects:[IntObject objectsInRealm:realm where:@"intCol = 5"]];
    }];
}

- (void)testMoveMatchingObjectDueToDeletionOfNonMatchingObject {
    [self expectChange:nil from:^(RLMRealm *realm) {
        // Make a matching object be the last row
        [realm deleteObjects:[IntObject objectsInRealm:realm where:@"intCol >= 5"]];
        // Delete a non-last, non-match row so that a matched row is moved
        [realm deleteObjects:[IntObject objectsInRealm:realm where:@"intCol = 0"]];
    }];
}

- (void)testNonMatchingObjectMovedToIndexOfMatchingRowAndMadeMatching {
    [self expectChange:@[@[@1, NotFound], @[NotFound, @3]] from:^(RLMRealm *realm) {
        // Make the last object match the query
        [[[IntObject allObjectsInRealm:realm] lastObject] setIntCol:3];
        // Move the now-matching object over a previously matching object
        [realm deleteObjects:[IntObject objectsInRealm:realm where:@"intCol = 2"]];
    }];
}

- (void)testDeleteNewlyInsertedRowMatchingQuery {
    [self expectChange:nil from:^(RLMRealm *realm) {
        RLMArray *array = [[[ArrayPropertyObject allObjectsInRealm:realm] firstObject] intArray];
        [array addObject:[IntObject createInRealm:realm withValue:@[@3]]];
        [realm deleteObject:[IntObject allObjectsInRealm:realm].lastObject];
    }];
}

- (void)testInsertObjectMatchingQuery {
    [self expectChange:@[@[NotFound, @4]] from:^(RLMRealm *realm) {
        RLMArray *array = [[[ArrayPropertyObject allObjectsInRealm:realm] firstObject] intArray];
        [array addObject:[IntObject createInRealm:realm withValue:@[@3]]];
    }];
}

- (void)testInsertObjectNotMatchingQuery {
    [self expectChange:nil from:^(RLMRealm *realm) {
        RLMArray *array = [[[ArrayPropertyObject allObjectsInRealm:realm] firstObject] intArray];
        [array addObject:[IntObject createInRealm:realm withValue:@[@5]]];
    }];
}

- (void)testInsertBothMatchingAndNonMatching {
    [self expectChange:@[@[NotFound, @4]] from:^(RLMRealm *realm) {
        RLMArray *array = [[[ArrayPropertyObject allObjectsInRealm:realm] firstObject] intArray];
        [array addObject:[IntObject createInRealm:realm withValue:@[@5]]];
        [array addObject:[IntObject createInRealm:realm withValue:@[@3]]];
    }];
}

- (void)testInsertMultipleMatching {
    [self expectChange:@[@[NotFound, @4], @[NotFound, @5]] from:^(RLMRealm *realm) {
        RLMArray *array = [[[ArrayPropertyObject allObjectsInRealm:realm] firstObject] intArray];
        [array addObject:[IntObject createInRealm:realm withValue:@[@5]]];
        [array addObject:[IntObject createInRealm:realm withValue:@[@3]]];
        [array addObject:[IntObject createInRealm:realm withValue:@[@5]]];
        [array addObject:[IntObject createInRealm:realm withValue:@[@2]]];
    }];
}

- (void)testInsertAtIndex {
    [self expectChange:@[@[NotFound, @0]] from:^(RLMRealm *realm) {
        RLMArray *array = [[[ArrayPropertyObject allObjectsInRealm:realm] firstObject] intArray];
        IntObject *io = [IntObject createInRealm:realm withValue:@[@3]];
        [array insertObject:io atIndex:0];
    }];

    [self expectChange:@[@[NotFound, @0]] from:^(RLMRealm *realm) {
        RLMArray *array = [[[ArrayPropertyObject allObjectsInRealm:realm] firstObject] intArray];
        IntObject *io = [IntObject createInRealm:realm withValue:@[@3]];
        [array insertObject:io atIndex:1];
    }];

    [self expectChange:@[@[NotFound, @1]] from:^(RLMRealm *realm) {
        RLMArray *array = [[[ArrayPropertyObject allObjectsInRealm:realm] firstObject] intArray];
        IntObject *io = [IntObject createInRealm:realm withValue:@[@3]];
        [array insertObject:io atIndex:2];
    }];

    [self expectChange:nil from:^(RLMRealm *realm) {
        RLMArray *array = [[[ArrayPropertyObject allObjectsInRealm:realm] firstObject] intArray];
        IntObject *io = [IntObject createInRealm:realm withValue:@[@5]];
        [array insertObject:io atIndex:2];
    }];
}

- (void)testExchangeObjects {
    // adjacent swap: one move, since second is redundant
    [self expectChange:@[@[@1, @0]] from:^(RLMRealm *realm) {
        RLMArray *array = [[[ArrayPropertyObject allObjectsInRealm:realm] firstObject] intArray];
        [array exchangeObjectAtIndex:1 withObjectAtIndex:2];
    }];

    // non-adjacent: two moves needed
//    [self expectChange:@[@[@0, @2]] from:^(RLMRealm *realm) {
//        RLMArray *array = [[[ArrayPropertyObject allObjectsInRealm:realm] firstObject] intArray];
//        [array exchangeObjectAtIndex:1 withObjectAtIndex:3];
//    }];
}

- (void)testRemoveFromArray {
    [self expectChange:@[@[@0, NotFound]] from:^(RLMRealm *realm) {
        RLMArray *array = [[[ArrayPropertyObject allObjectsInRealm:realm] firstObject] intArray];
        [array removeObjectAtIndex:1];
    }];

    [self expectChange:nil from:^(RLMRealm *realm) {
        RLMArray *array = [[[ArrayPropertyObject allObjectsInRealm:realm] firstObject] intArray];
        [array removeObjectAtIndex:0];
    }];
}

- (void)testClearArray {
    [self expectChange:@[@[@0, NotFound], @[@1, NotFound], @[@2, NotFound], @[@3, NotFound]]
                  from:^(RLMRealm *realm) {
        RLMArray *array = [[[ArrayPropertyObject allObjectsInRealm:realm] firstObject] intArray];
        [array removeAllObjects];
    }];
}

#if 0 // needs https://github.com/realm/realm-core/pull/1434
- (void)testDeleteArray {
    [self expectChange:@[@[@0, NotFound], @[@1, NotFound], @[@2, NotFound], @[@3, NotFound]]
                  from:^(RLMRealm *realm) {
                      [realm deleteObjects:[ArrayPropertyObject allObjectsInRealm:realm]];
    }];
}
#endif

@end
