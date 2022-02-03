////////////////////////////////////////////////////////////////////////////
//
// Copyright 2020 Realm Inc.
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

static NSDate *date(int i) {
    return [NSDate dateWithTimeIntervalSince1970:i];
}
static NSData *data(int i) {
    return [NSData dataWithBytesNoCopy:calloc(i, 1) length:i freeWhenDone:YES];
}
static RLMDecimal128 *decimal128(int i) {
    return [RLMDecimal128 decimalWithNumber:@(i)];
}
static NSMutableArray *objectIds;
static RLMObjectId *objectId(NSUInteger i) {
    if (!objectIds) {
        objectIds = [NSMutableArray new];
    }
    while (i >= objectIds.count) {
        [objectIds addObject:RLMObjectId.objectId];
    }
    return objectIds[i];
}
static NSUUID *uuid(NSString *uuidString) {
    return [[NSUUID alloc] initWithUUIDString:uuidString];
}
static void count(NSArray *values, double *sum, NSUInteger *count) {
    for (id value in values) {
        if (value != NSNull.null) {
            ++*count;
            *sum += [value doubleValue];
        }
    }
}
static double sum(NSArray *values) {
    double sum = 0;
    NSUInteger c = 0;
    count(values, &sum, &c);
    return sum;
}
static double average(NSArray *values) {
    double sum = 0;
    NSUInteger c = 0;
    count(values, &sum, &c);
    return sum / c;
}

@interface LinkToAllPrimitiveSets : RLMObject
@property (nonatomic) AllPrimitiveSets *link;
@end
@implementation LinkToAllPrimitiveSets
@end

@interface LinkToAllOptionalPrimitiveSets : RLMObject
@property (nonatomic) AllOptionalPrimitiveSets *link;
@end
@implementation LinkToAllOptionalPrimitiveSets
@end

@interface PrimitiveSetPropertyTests : RLMTestCase
@end

@implementation PrimitiveSetPropertyTests {
    AllPrimitiveSets *unmanaged;
    AllPrimitiveSets *managed;
    AllOptionalPrimitiveSets *optUnmanaged;
    AllOptionalPrimitiveSets *optManaged;
    RLMRealm *realm;
    NSArray<RLMSet *> *allSets;
}

- (void)setUp {
    unmanaged = [[AllPrimitiveSets alloc] init];
    optUnmanaged = [[AllOptionalPrimitiveSets alloc] init];
    realm = [RLMRealm defaultRealm];
    [realm beginWriteTransaction];
    managed = [AllPrimitiveSets createInRealm:realm withValue:@[]];
    optManaged = [AllOptionalPrimitiveSets createInRealm:realm withValue:@[]];
    allSets = @[
        $set,
    ];
}

- (void)tearDown {
    if (realm.inWriteTransaction) {
        [realm cancelWriteTransaction];
    }
}

- (void)addObjects {
    [$set addObjects:$values];
}

- (void)testCount {
    uncheckedAssertEqual(unmanaged.intObj.count, 0U);
    [unmanaged.intObj addObject:@1];
    uncheckedAssertEqual(unmanaged.intObj.count, 1U);
}

- (void)testType {
    uncheckedAssertEqual(unmanaged.boolObj.type, RLMPropertyTypeBool);
    uncheckedAssertEqual(unmanaged.intObj.type, RLMPropertyTypeInt);
    uncheckedAssertEqual(unmanaged.floatObj.type, RLMPropertyTypeFloat);
    uncheckedAssertEqual(unmanaged.doubleObj.type, RLMPropertyTypeDouble);
    uncheckedAssertEqual(unmanaged.stringObj.type, RLMPropertyTypeString);
    uncheckedAssertEqual(unmanaged.dataObj.type, RLMPropertyTypeData);
    uncheckedAssertEqual(unmanaged.dateObj.type, RLMPropertyTypeDate);
    uncheckedAssertEqual(optUnmanaged.boolObj.type, RLMPropertyTypeBool);
    uncheckedAssertEqual(optUnmanaged.intObj.type, RLMPropertyTypeInt);
    uncheckedAssertEqual(optUnmanaged.floatObj.type, RLMPropertyTypeFloat);
    uncheckedAssertEqual(optUnmanaged.doubleObj.type, RLMPropertyTypeDouble);
    uncheckedAssertEqual(optUnmanaged.stringObj.type, RLMPropertyTypeString);
    uncheckedAssertEqual(optUnmanaged.dataObj.type, RLMPropertyTypeData);
    uncheckedAssertEqual(optUnmanaged.dateObj.type, RLMPropertyTypeDate);
}

- (void)testOptional {
    uncheckedAssertFalse(unmanaged.boolObj.optional);
    uncheckedAssertFalse(unmanaged.intObj.optional);
    uncheckedAssertFalse(unmanaged.floatObj.optional);
    uncheckedAssertFalse(unmanaged.doubleObj.optional);
    uncheckedAssertFalse(unmanaged.stringObj.optional);
    uncheckedAssertFalse(unmanaged.dataObj.optional);
    uncheckedAssertFalse(unmanaged.dateObj.optional);
    uncheckedAssertTrue(optUnmanaged.boolObj.optional);
    uncheckedAssertTrue(optUnmanaged.intObj.optional);
    uncheckedAssertTrue(optUnmanaged.floatObj.optional);
    uncheckedAssertTrue(optUnmanaged.doubleObj.optional);
    uncheckedAssertTrue(optUnmanaged.stringObj.optional);
    uncheckedAssertTrue(optUnmanaged.dataObj.optional);
    uncheckedAssertTrue(optUnmanaged.dateObj.optional);
}

- (void)testObjectClassName {
    uncheckedAssertNil(unmanaged.boolObj.objectClassName);
    uncheckedAssertNil(unmanaged.intObj.objectClassName);
    uncheckedAssertNil(unmanaged.floatObj.objectClassName);
    uncheckedAssertNil(unmanaged.doubleObj.objectClassName);
    uncheckedAssertNil(unmanaged.stringObj.objectClassName);
    uncheckedAssertNil(unmanaged.dataObj.objectClassName);
    uncheckedAssertNil(unmanaged.dateObj.objectClassName);
    uncheckedAssertNil(optUnmanaged.boolObj.objectClassName);
    uncheckedAssertNil(optUnmanaged.intObj.objectClassName);
    uncheckedAssertNil(optUnmanaged.floatObj.objectClassName);
    uncheckedAssertNil(optUnmanaged.doubleObj.objectClassName);
    uncheckedAssertNil(optUnmanaged.stringObj.objectClassName);
    uncheckedAssertNil(optUnmanaged.dataObj.objectClassName);
    uncheckedAssertNil(optUnmanaged.dateObj.objectClassName);
}

- (void)testRealm {
    uncheckedAssertNil(unmanaged.boolObj.realm);
    uncheckedAssertNil(unmanaged.intObj.realm);
    uncheckedAssertNil(unmanaged.floatObj.realm);
    uncheckedAssertNil(unmanaged.doubleObj.realm);
    uncheckedAssertNil(unmanaged.stringObj.realm);
    uncheckedAssertNil(unmanaged.dataObj.realm);
    uncheckedAssertNil(unmanaged.dateObj.realm);
    uncheckedAssertNil(optUnmanaged.boolObj.realm);
    uncheckedAssertNil(optUnmanaged.intObj.realm);
    uncheckedAssertNil(optUnmanaged.floatObj.realm);
    uncheckedAssertNil(optUnmanaged.doubleObj.realm);
    uncheckedAssertNil(optUnmanaged.stringObj.realm);
    uncheckedAssertNil(optUnmanaged.dataObj.realm);
    uncheckedAssertNil(optUnmanaged.dateObj.realm);
}

- (void)testInvalidated {
    RLMSet *set;
    @autoreleasepool {
        AllPrimitiveSets *obj = [[AllPrimitiveSets alloc] init];
        set = obj.intObj;
        uncheckedAssertFalse(set.invalidated);
    }
    uncheckedAssertFalse(set.invalidated);
}

- (void)testDeleteObjectsInRealm {
    RLMAssertThrowsWithReason([realm deleteObjects:$allSets], @"Cannot delete objects from RLMSet");
}

- (void)testObjectAtIndex {
    RLMAssertThrowsWithReason([unmanaged.intObj objectAtIndex:0],
                              @"Index 0 is out of bounds (must be less than 0).");

    [unmanaged.intObj addObject:@1];
    uncheckedAssertEqualObjects([unmanaged.intObj objectAtIndex:0], @1);
}

- (void)testContainsObject {
    uncheckedAssertFalse([$set containsObject:$v0]);
    [$set addObject:$v0];
    uncheckedAssertTrue([$set containsObject:$v0]);
}

- (void)testAddObject {
    %noany RLMAssertThrowsWithReason([$set addObject:$wrong], ^n @"Invalid value '$wdesc' of type '" $wtype "' for expected type '$type'");
    %noany %r RLMAssertThrowsWithReason([$set addObject:NSNull.null], ^n @"Invalid value '<null>' of type 'NSNull' for expected type '$type'");

    [$set addObject:$v0];
    uncheckedAssertTrue([$set containsObject:$v0]);

    %o [$set addObject:NSNull.null];
    %o uncheckedAssertTrue([$set containsObject:NSNull.null]);
}

- (void)testAddObjects {
    %noany RLMAssertThrowsWithReason([$set addObjects:@[$wrong]], ^n @"Invalid value '$wdesc' of type '" $wtype "' for expected type '$type'");
    %noany %r RLMAssertThrowsWithReason([$set addObjects:@[NSNull.null]], ^n @"Invalid value '<null>' of type 'NSNull' for expected type '$type'");

    [self addObjects];
    uncheckedAssertTrue([$set containsObject:$v0]);
    uncheckedAssertTrue([$set containsObject:$v1]);
    %o uncheckedAssertTrue([$set containsObject:$v2]);
}

- (void)testRemoveObject {
    [self addObjects];
    %r uncheckedAssertEqual($set.count, 2U);
    %o uncheckedAssertEqual($set.count, 3U);

    [$allSets removeObject:$allSets.allObjects[0]];
    %r uncheckedAssertEqual($set.count, 1U);
    %o uncheckedAssertEqual($set.count, 2U);
}

- (void)testIndexOfObjectSorted {
    %man %r [$set addObjects:@[$v0, $v1, $v0, $v1]];
    %man %o [$set addObjects:@[$v0, $v1, NSNull.null, $v1, $v0]];
    // ordering can't be guaranteed in set, so just verify the indexes are between 0 and 1
    %man %r uncheckedAssertTrue([[$set sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:$v1] == 0U || ^n [[$set sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:$v1] == 1U);
    %man %r uncheckedAssertTrue([[$set sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:$v0] == 0U || ^n [[$set sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:$v0] == 1U);

    %man %o uncheckedAssertTrue([[$set sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:$v1] == 0U || ^n [[$set sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:$v1] == 1U);
    %man %o uncheckedAssertTrue([[$set sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:$v0] == 0U || ^n [[$set sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:$v0] == 1U);
}

- (void)testIndexOfObjectDistinct {
    %man %r [$set addObjects:@[$v0, $v0, $v1]];
    %man %o [$set addObjects:@[$v0, $v0, NSNull.null, $v1, $v0]];
    // ordering can't be guaranteed in set, so just verify the indexes are between 0 and 1
    %man %r uncheckedAssertTrue([[$set distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:$v0] == 0U || ^n [[$set distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:$v0] == 1U);
    %man %r uncheckedAssertTrue([[$set distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:$v1] == 0U || ^n [[$set distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:$v1] == 1U);

    %man %o uncheckedAssertTrue([[$set distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:$v0] == 0U || ^n [[$set distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:$v0] == 1U);
    %man %o uncheckedAssertTrue([[$set distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:$v1] == 0U || ^n [[$set distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:$v1] == 1U);
    %man %o uncheckedAssertTrue([[$set distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:NSNull.null] == 0U || ^n [[$set distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:NSNull.null] == 1U);
}

- (void)testSort {
    %unman RLMAssertThrowsWithReason([$set sortedResultsUsingKeyPath:@"self" ascending:NO], ^n @"This method may only be called on RLMSet instances retrieved from an RLMRealm");
    %unman RLMAssertThrowsWithReason([$set sortedResultsUsingDescriptors:@[]], ^n @"This method may only be called on RLMSet instances retrieved from an RLMRealm");
    %man RLMAssertThrowsWithReason([$set sortedResultsUsingKeyPath:@"not self" ascending:NO], ^n @"can only be sorted on 'self'");

    %man %r [$set addObjects:@[$v0, $v1, $v0]];
    %man %o [$set addObjects:@[$v0, $v1, NSNull.null, $v1, $v0]];

    %man %r uncheckedAssertEqualObjects([NSSet setWithArray:[[[$set sortedResultsUsingDescriptors:@[]] valueForKey:@"self"] allObjects]], ^n ([NSSet setWithArray:@[$v0, $v1]]));
    %man %o uncheckedAssertEqualObjects([NSSet setWithArray:[[[$set sortedResultsUsingDescriptors:@[]] valueForKey:@"self"] allObjects]], ^n ([NSSet setWithArray:@[$v0, $v1]]));

    %man %r uncheckedAssertEqualObjects([NSSet setWithArray:[[[$set sortedResultsUsingKeyPath:@"self" ascending:NO] valueForKey:@"self"] allObjects]], ^n ([NSSet setWithArray:@[$v1, $v0]]));
    %man %o uncheckedAssertEqualObjects([NSSet setWithArray:[[[$set sortedResultsUsingKeyPath:@"self" ascending:NO] valueForKey:@"self"] allObjects]], ^n ([NSSet setWithArray:@[$v1, $v0]]));

    %man %r uncheckedAssertEqualObjects([NSSet setWithArray:[[[$set sortedResultsUsingKeyPath:@"self" ascending:YES] valueForKey:@"self"] allObjects]], ^n ([NSSet setWithArray:@[$v0, $v1]]));
    %man %o uncheckedAssertEqualObjects([NSSet setWithArray:[[[$set sortedResultsUsingKeyPath:@"self" ascending:YES] valueForKey:@"self"] allObjects]], ^n ([NSSet setWithArray:@[NSNull.null, $v1]]));
}

- (void)testFilter {
    %unman RLMAssertThrowsWithReason([$set objectsWhere:@"TRUEPREDICATE"], ^n @"This method may only be called on RLMSet instances retrieved from an RLMRealm");
    %unman RLMAssertThrowsWithReason([$set objectsWithPredicate:[NSPredicate predicateWithValue:YES]], ^n @"This method may only be called on RLMSet instances retrieved from an RLMRealm");

    %man RLMAssertThrowsWithReason([$set objectsWhere:@"TRUEPREDICATE"], ^n @"implemented");
    %man RLMAssertThrowsWithReason([$set objectsWithPredicate:[NSPredicate predicateWithValue:YES]], ^n @"implemented");

    %man RLMAssertThrowsWithReason([[$set sortedResultsUsingKeyPath:@"self" ascending:NO] ^n  objectsWhere:@"TRUEPREDICATE"], @"implemented");
    %man RLMAssertThrowsWithReason([[$set sortedResultsUsingKeyPath:@"self" ascending:NO] ^n  objectsWithPredicate:[NSPredicate predicateWithValue:YES]], @"implemented");
}

- (void)testNotifications {
    %unman RLMAssertThrowsWithReason([$set addNotificationBlock:^(__unused id a, __unused id c, __unused id e) { }], ^n @"This method may only be called on RLMSet instances retrieved from an RLMRealm");
}

- (void)testSetSet {
    %man %r [$set addObjects:@[$v0, $v1]];
    %man %o [$set addObjects:@[$v0, $v1, NSNull.null]];
    %man %r [$set2 addObjects:@[$v3, $v4]];
    %man %o [$set2 addObjects:@[$v3, $v4, NSNull.null]];
    [realm commitWriteTransaction];

    %unman %r [$set addObjects:@[$v0, $v1]];
    %unman %o [$set addObjects:@[$v0, $v1, NSNull.null]];
    %unman %r [$set2 addObjects:@[$v3, $v4]];
    %unman %o [$set2 addObjects:@[$v3, $v4, NSNull.null]];

    %unman [$set setSet:$set2];

    [realm beginWriteTransaction];
    %man [$set setSet:$set2];
    [realm commitWriteTransaction];

    %unman %r %maxtwovalues uncheckedAssertEqual($set.count, 2U);
    %unman %r %maxtwovalues uncheckedAssertEqualObjects($set.allObjects, (@[$v0, $v1]));
    %unman %r %nomaxvalues uncheckedAssertEqual($set.count, 2U);
    %unman %r %nomaxvalues uncheckedAssertEqualObjects([NSSet setWithArray:$set.allObjects], ([NSSet setWithArray:@[$v0, $v4]]));
    %unman %o %maxtwovalues uncheckedAssertEqual($set.count, 3U);
    %unman %o %maxtwovalues uncheckedAssertEqualObjects([NSSet setWithArray:$set.allObjects], ([NSSet setWithArray:@[$v0, $v1, $v2]]));
    %unman %o %nomaxvalues uncheckedAssertEqual($set.count, 3U);
    %unman %o %nomaxvalues uncheckedAssertEqualObjects([NSSet setWithArray:$set.allObjects], ([NSSet setWithArray:@[$v0, $v3, $v4]]));
    %man %r %maxtwovalues uncheckedAssertEqual($set.count, 2U);
    %man %r %maxtwovalues uncheckedAssertEqualObjects([NSSet setWithArray:$set.allObjects], ([NSSet setWithArray:@[$v0, $v1]]));
    %man %r %nomaxvalues uncheckedAssertEqual($set.count, 2U);
    %man %r %nomaxvalues uncheckedAssertEqualObjects([NSSet setWithArray:$set.allObjects], ([NSSet setWithArray:@[$v1, $v4]]));
    %man %o %maxtwovalues uncheckedAssertEqual($set.count, 3U);
    %man %o %maxtwovalues uncheckedAssertEqualObjects([NSSet setWithArray:$set.allObjects], ([NSSet setWithArray:@[$v0, $v1, %v2]]));
    %man %o %nomaxvalues uncheckedAssertEqual($set.count, 3U);
    %man %o %nomaxvalues uncheckedAssertEqualObjects([NSSet setWithArray:$set.allObjects], ([NSSet setWithArray:@[$v0, $v1, %v3, %v4]]));
}

- (void)testUnion {
    %man %r [$set addObjects:@[$v0, $v1]];
    %man %o [$set addObjects:@[$v0, $v1, NSNull.null]];
    %man %r [$set2 addObjects:@[$v3, $v4]];
    %man %o [$set2 addObjects:@[$v3, $v4, NSNull.null]];
    [realm commitWriteTransaction];

    %unman %r [$set addObjects:@[$v0, $v1]];
    %unman %o [$set addObjects:@[$v0, $v1, NSNull.null]];
    %unman %r [$set2 addObjects:@[$v3, $v4]];
    %unman %o [$set2 addObjects:@[$v3, $v4, NSNull.null]];

    %man XCTAssertThrows([$set unionSet:$set2]);
    %unman [$set unionSet:$set2];

    [realm beginWriteTransaction];
    %man [$set unionSet:$set2];
    [realm commitWriteTransaction];

    %unman %r %maxtwovalues uncheckedAssertEqual($set.count, 2U);
    %unman %r %maxtwovalues uncheckedAssertEqualObjects([NSSet setWithArray:$set.allObjects], ([NSSet setWithArray:@[$v0, $v1]]));
    %unman %r %nomaxvalues uncheckedAssertEqual($set.count, 3U);
    %unman %r %nomaxvalues uncheckedAssertEqualObjects([NSSet setWithArray:$set.allObjects], ([NSSet setWithArray:@[$v0, $v1, $v4]]));
    %unman %o %maxtwovalues uncheckedAssertEqual($set.count, 3U);
    %unman %o %maxtwovalues uncheckedAssertEqualObjects([NSSet setWithArray:$set.allObjects], ([NSSet setWithArray:@[$v0, $v1, $v2]]));
    %unman %o %nomaxvalues uncheckedAssertEqual($set.count, 4U);
    %unman %o %nomaxvalues uncheckedAssertEqualObjects([NSSet setWithArray:$set.allObjects], ([NSSet setWithArray:@[$v0, $v1, $v3, $v4]]));
    %man %r %maxtwovalues uncheckedAssertEqual($set.count, 2U);
    %man %r %maxtwovalues uncheckedAssertEqualObjects([NSSet setWithArray:$set.allObjects], ([NSSet setWithArray:@[$v0, $v1]]));
    %man %r %nomaxvalues uncheckedAssertEqual($set.count, 3U);
    %man %r %nomaxvalues uncheckedAssertEqualObjects([NSSet setWithArray:$set.allObjects], ([NSSet setWithArray:@[$v0, $v1, $v4]]));
    %man %o %maxtwovalues uncheckedAssertEqual($set.count, 3U);
    %man %o %maxtwovalues uncheckedAssertEqualObjects([NSSet setWithArray:$set.allObjects], ([NSSet setWithArray:@[$v0, $v1, %v2]]));
    %man %o %nomaxvalues uncheckedAssertEqual($set.count, 4U);
    %man %o %nomaxvalues uncheckedAssertEqualObjects([NSSet setWithArray:$set.allObjects], ([NSSet setWithArray:@[$v0, $v1, %v3, %v4]]));
}

- (void)testIntersect {
    %man %r [$set addObjects:@[$v0, $v1]];
    %man %o [$set addObjects:@[$v0, $v1, NSNull.null]];
    %man %r [$set2 addObjects:@[$v3, $v4]];
    %man %o [$set2 addObjects:@[$v3, $v4, NSNull.null]];
    [realm commitWriteTransaction];

    %unman %r [$set addObjects:@[$v0, $v1]];
    %unman %o [$set addObjects:@[$v0, $v1, NSNull.null]];
    %unman %r [$set2 addObjects:@[$v3, $v4]];
    %unman %o [$set2 addObjects:@[$v3, $v4, NSNull.null]];

    %man XCTAssertThrows([$set intersectSet:$set2]);
    %man uncheckedAssertTrue([$set intersectsSet:$set2]);
    %unman uncheckedAssertTrue([$set intersectsSet:$set2]);

    %unman [$set intersectSet:$set2];

    [realm beginWriteTransaction];
    %man [$set intersectSet:$set2];
    [realm commitWriteTransaction];

    %unman %r %maxtwovalues uncheckedAssertEqual($set.count, 2U);
    %unman %r %maxtwovalues uncheckedAssertEqualObjects([NSSet setWithArray:$set.allObjects], ([NSSet setWithArray:@[$v0, $v1]]));
    %unman %r %nomaxvalues uncheckedAssertEqual($set.count, 1U);
    %unman %r %nomaxvalues uncheckedAssertEqualObjects($set.allObjects, (@[$v0]));
    %unman %o %maxtwovalues uncheckedAssertEqual($set.count, 2U);
    %unman %o %maxtwovalues uncheckedAssertEqualObjects([NSSet setWithArray:$set.allObjects], ([NSSet setWithArray:@[$v0, $v1]]));
    %unman %o %nomaxvalues uncheckedAssertEqual($set.count, 1U);
    %unman %o %nomaxvalues uncheckedAssertEqualObjects([NSSet setWithArray:$set.allObjects], ([NSSet setWithArray:@[$v0]]));
    %man %r %maxtwovalues uncheckedAssertEqual($set.count, 2U);
    %man %r %maxtwovalues uncheckedAssertEqualObjects([NSSet setWithArray:$set.allObjects], ([NSSet setWithArray:@[$v0, $v1]]));
    %man %r %nomaxvalues uncheckedAssertEqual($set.count, 1U);
    %man %r %nomaxvalues uncheckedAssertEqualObjects($set.allObjects, (@[$v1]));
    %man %o %maxtwovalues uncheckedAssertEqual($set.count, 2U);
    %man %o %maxtwovalues uncheckedAssertEqualObjects([NSSet setWithArray:$set.allObjects], ([NSSet setWithArray:@[$v0, $v1]]));
    %man %o %nomaxvalues uncheckedAssertEqual($set.count, 1U);
    %man %o %nomaxvalues uncheckedAssertEqualObjects($set.allObjects, (@[$v0]));
}

- (void)testMinus {
    %man %r [$set addObjects:@[$v0, $v1]];
    %man %o [$set addObjects:@[$v0, $v1, NSNull.null]];
    %man %r [$set2 addObjects:@[$v3, $v4]];
    %man %o [$set2 addObjects:@[$v3, $v4, NSNull.null]];
    [realm commitWriteTransaction];

    %unman %r [$set addObjects:@[$v0, $v1]];
    %unman %o [$set addObjects:@[$v0, $v1, NSNull.null]];
    %unman %r [$set2 addObjects:@[$v3, $v4]];
    %unman %o [$set2 addObjects:@[$v3, $v4, NSNull.null]];

    %man XCTAssertThrows([$set minusSet:$set2]);

    %unman [$set minusSet:$set2];

    [realm beginWriteTransaction];
    %man [$set minusSet:$set2];
    [realm commitWriteTransaction];

    %unman %r %maxtwovalues uncheckedAssertEqual($set.count, 0U);
    %unman %r %maxtwovalues uncheckedAssertEqualObjects($set.allObjects, (@[]));
    %unman %r %nomaxvalues uncheckedAssertEqual($set.count, 1U);
    %unman %r %nomaxvalues uncheckedAssertEqualObjects($set.allObjects, (@[$v1]));
    %unman %o %maxtwovalues uncheckedAssertEqual($set.count, 0U);
    %unman %o %maxtwovalues uncheckedAssertEqualObjects($set.allObjects, (@[]));
    %unman %o %nomaxvalues uncheckedAssertEqual($set.count, 1U);
    %unman %o %nomaxvalues uncheckedAssertEqualObjects($set.allObjects, (@[$v1]));
    %man %r %maxtwovalues uncheckedAssertEqual($set.count, 0U);
    %man %r %maxtwovalues uncheckedAssertEqualObjects($set.allObjects, (@[]));
    %man %r %nomaxvalues uncheckedAssertEqual($set.count, 1U);
    %man %r %nomaxvalues uncheckedAssertEqualObjects($set.allObjects, (@[$v0]));
    %man %o %maxtwovalues uncheckedAssertEqual($set.count, 0U);
    %man %o %maxtwovalues uncheckedAssertEqualObjects($set.allObjects, (@[]));
    %man %o %nomaxvalues uncheckedAssertEqual($set.count, 1U);
    %man %o %nomaxvalues uncheckedAssertEqualObjects($set.allObjects, (@[$v1]));
}

- (void)testIsSubsetOfSet {
    %man %r [$set addObjects:@[$v0, $v1]];
    %man %o [$set addObjects:@[$v0, $v1, NSNull.null]];
    %man %r [$set2 addObjects:@[$v0, $v1, $v3, $v4]];
    %man %o [$set2 addObjects:@[$v0, $v1, $v3, $v4, NSNull.null]];
    [realm commitWriteTransaction];

    %unman %r [$set addObjects:@[$v0, $v1]];
    %unman %o [$set addObjects:@[$v0, $v1, NSNull.null]];
    %unman %r [$set2 addObjects:@[$v0, $v1, $v3, $v4]];
    %unman %o [$set2 addObjects:@[$v0, $v1, $v3, $v4, NSNull.null]];

    %maxtwovalues %r %man uncheckedAssertTrue([$set2 isSubsetOfSet:$set]);
    %maxtwovalues %r %unman uncheckedAssertTrue([$set2 isSubsetOfSet:$set]);
    %maxtwovalues %o %man uncheckedAssertFalse([$set2 isSubsetOfSet:$set]);
    %maxtwovalues %o %unman uncheckedAssertFalse([$set2 isSubsetOfSet:$set]);

    %maxtwovalues %r %man uncheckedAssertTrue([$set isSubsetOfSet:$set2]);
    %maxtwovalues %r %unman uncheckedAssertTrue([$set isSubsetOfSet:$set2]);
    %maxtwovalues %o %man uncheckedAssertTrue([$set isSubsetOfSet:$set2]);
    %maxtwovalues %o %unman uncheckedAssertTrue([$set isSubsetOfSet:$set2]);

    %nomaxvalues %man uncheckedAssertTrue([$set isSubsetOfSet:$set2]);
    %nomaxvalues %unman uncheckedAssertTrue([$set isSubsetOfSet:$set2]);
    %nomaxvalues %man uncheckedAssertFalse([$set2 isSubsetOfSet:$set]);
    %nomaxvalues %unman uncheckedAssertFalse([$set2 isSubsetOfSet:$set]);
}

- (void)testMin {
    %noany %nominmax %unman RLMAssertThrowsWithReason([$set minOfProperty:@"self"], ^n @"minOfProperty: is not supported for $type set");
    %noany %nominmax %man RLMAssertThrowsWithReason([$set minOfProperty:@"self"], ^n @"minOfProperty: is not supported for $type set '$class.$prop'");

    %minmax uncheckedAssertNil([$set minOfProperty:@"self"]);

    [self addObjects];

    %minmax %unman %r uncheckedAssertEqualObjects([$set minOfProperty:@"self"], $v0);
    %minmax %unman %o uncheckedAssertEqualObjects([$set minOfProperty:@"self"], $v1);

    %minmax %man %r uncheckedAssertEqualObjects([$set minOfProperty:@"self"], $v0);
    %minmax %man %o uncheckedAssertEqualObjects([$set minOfProperty:@"self"], $v1);
}

- (void)testMax {
    %noany %nominmax %unman RLMAssertThrowsWithReason([$set maxOfProperty:@"self"], ^n @"maxOfProperty: is not supported for $type set");
    %noany %nominmax %man RLMAssertThrowsWithReason([$set maxOfProperty:@"self"], ^n @"maxOfProperty: is not supported for $type set '$class.$prop'");

    %minmax uncheckedAssertNil([$set maxOfProperty:@"self"]);

    [self addObjects];

    %minmax %unman %r uncheckedAssertEqualObjects([$set maxOfProperty:@"self"], $v1);
    %minmax %unman %o uncheckedAssertEqualObjects([$set maxOfProperty:@"self"], $v2);

    %minmax %man %r uncheckedAssertEqualObjects([$set maxOfProperty:@"self"], $v1);
    %minmax %man %o uncheckedAssertEqualObjects([$set maxOfProperty:@"self"], $v2);
}

- (void)testSum {
    %noany %nosum %unman RLMAssertThrowsWithReason([$set sumOfProperty:@"self"], ^n @"sumOfProperty: is not supported for $type set");
    %noany %nosum %man RLMAssertThrowsWithReason([$set sumOfProperty:@"self"], ^n @"sumOfProperty: is not supported for $type set '$class.$prop'");

    %sum uncheckedAssertEqualObjects([$set sumOfProperty:@"self"], @0);

    [self addObjects];

    %sum XCTAssertEqualWithAccuracy([$set sumOfProperty:@"self"].doubleValue, sum($values), .001);
}

- (void)testAverage {
    %noany %noavg %unman RLMAssertThrowsWithReason([$set averageOfProperty:@"self"], ^n @"averageOfProperty: is not supported for $type set");
    %noany %noavg %man RLMAssertThrowsWithReason([$set averageOfProperty:@"self"], ^n @"averageOfProperty: is not supported for $type set '$class.$prop'");

    %avg uncheckedAssertNil([$set averageOfProperty:@"self"]);

    [self addObjects];

    %avg XCTAssertEqualWithAccuracy([$set averageOfProperty:@"self"].doubleValue, average($values), .001);
}

- (void)testFastEnumeration {
    for (int i = 0; i < 10; ++i) {
        [self addObjects];
    }

    // This is wrapped in a block to work around a compiler bug in Xcode 12.5:
    // in release builds, reads on `values` will read the wrong local variable,
    // resulting in a crash when it tries to send a message to some unitialized
    // stack space. Putting them in separate obj-c blocks prevents this
    // incorrect optimization.
    ^{ ^nl NSArray *values = $values; ^nl for (id value in $set) { ^nl uncheckedAssertTrue([[NSSet setWithArray:values] containsObject:value]); ^nl } ^nl }(); ^nl
}

- (void)testValueForKeySelf {
    uncheckedAssertEqualObjects([[$allSets valueForKey:@"self"] allObjects], @[]);

    [self addObjects];

    uncheckedAssertEqualObjects([NSSet setWithArray:[[$set valueForKey:@"self"] allObjects]], ([NSSet setWithArray:$values]));
}

- (void)testValueForKeyNumericAggregates {
    %minmax uncheckedAssertNil([$set valueForKeyPath:@"@min.self"]);
    %minmax uncheckedAssertNil([$set valueForKeyPath:@"@max.self"]);
    %sum uncheckedAssertEqualObjects([$set valueForKeyPath:@"@sum.self"], @0);
    %avg uncheckedAssertNil([$set valueForKeyPath:@"@avg.self"]);

    [self addObjects];

    %minmax %unman %r uncheckedAssertEqualObjects([$set valueForKeyPath:@"@min.self"], $v0);
    %minmax %unman %o uncheckedAssertEqualObjects([$set valueForKeyPath:@"@max.self"], $v2);

    %minmax %man %r uncheckedAssertEqualObjects([$set valueForKeyPath:@"@min.self"], $v0);
    %minmax %man %o uncheckedAssertEqualObjects([$set valueForKeyPath:@"@max.self"], $v2);

    %sum XCTAssertEqualWithAccuracy([[$set valueForKeyPath:@"@sum.self"] doubleValue], sum($values), .001);
    %avg XCTAssertEqualWithAccuracy([[$set valueForKeyPath:@"@avg.self"] doubleValue], average($values), .001);
}

- (void)testValueForKeyLength {
    uncheckedAssertEqualObjects([[$allSets valueForKey:@"length"] allObjects], @[]);

    [self addObjects];
    %string uncheckedAssertEqualObjects([$set valueForKey:@"length"], ([[NSSet setWithArray:$values] valueForKey:@"length"]));
}

- (void)testSetValueForKey {
    RLMAssertThrowsWithReason([$allSets setValue:@0 forKey:@"not self"], ^n @"this class is not key value coding-compliant for the key not self.");
    %noany RLMAssertThrowsWithReason([$set setValue:$wrong forKey:@"self"], ^n @"Invalid value '$wdesc' of type '" $wtype "' for expected type '$type'");
    %noany %r RLMAssertThrowsWithReason([$set setValue:NSNull.null forKey:@"self"], ^n @"Invalid value '<null>' of type 'NSNull' for expected type '$type'");

    [self addObjects];

    // setValue overrides all existing values
    [$set setValue:$v0 forKey:@"self"];

    RLMAssertThrowsWithReason($set.allObjects[1], @"index 1 beyond bounds [0 .. 0]");

    uncheckedAssertEqualObjects($set.allObjects[0], $v0);
    %o uncheckedAssertEqualObjects($set.allObjects[0], $v0);

    %o [$set setValue:NSNull.null forKey:@"self"];
    %o uncheckedAssertEqualObjects($set.allObjects[0], NSNull.null);
}

- (void)testAssignment {
    $set = (id)@[$v1]; ^nl uncheckedAssertEqualObjects($set.allObjects[0], $v1);

    // Should replace and not append
    $set = (id)$values; ^nl uncheckedAssertEqualObjects([NSSet setWithArray:[[$set valueForKey:@"self"] allObjects]], ([NSSet setWithArray:$values])); ^nl

    // Should not clear the set
    $set = $set; ^nl uncheckedAssertEqualObjects([NSSet setWithArray:[[$set valueForKey:@"self"] allObjects]], ([NSSet setWithArray:$values])); ^nl

    [unmanaged.intObj removeAllObjects];
    unmanaged.intObj = managed.intObj;
    uncheckedAssertEqualObjects([NSSet setWithArray:[[unmanaged.intObj valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[@2, @3]]));

    [managed.intObj removeAllObjects];
    managed.intObj = unmanaged.intObj;
    uncheckedAssertEqualObjects([NSSet setWithArray:[[managed.intObj valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[@2, @3]]));
}

- (void)testDynamicAssignment {
    $obj[@"$prop"] = (id)@[$v1]; ^nl uncheckedAssertEqualObjects(((RLMSet *)$obj[@"$prop"]).allObjects[0], $v1);

    // Should replace and not append
    $obj[@"$prop"] = (id)$values; ^nl uncheckedAssertEqualObjects([NSSet setWithArray:[[$obj[@"$prop"] valueForKey:@"self"] allObjects]], ([NSSet setWithArray:$values])); ^nl

    // Should not clear the set
    $obj[@"$prop"] = $obj[@"$prop"]; ^nl uncheckedAssertEqualObjects([NSSet setWithArray:[[$obj[@"$prop"] valueForKey:@"self"] allObjects]], ([NSSet setWithArray:$values])); ^nl

    [unmanaged[@"intObj"] removeAllObjects];
    unmanaged[@"intObj"] = managed.intObj;
    uncheckedAssertEqualObjects([NSSet setWithArray:[[unmanaged[@"intObj"] valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[@2, @3]]));

    [managed[@"intObj"] removeAllObjects];
    managed[@"intObj"] = unmanaged.intObj;
    uncheckedAssertEqualObjects([NSSet setWithArray:[[managed[@"intObj"] valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[@2, @3]]));
}

- (void)testInvalidAssignment {
    RLMAssertThrowsWithReason(unmanaged.intObj = (id)@[NSNull.null],
                              @"Invalid value '<null>' of type 'NSNull' for 'int' set property 'AllPrimitiveSets.intObj'.");
    RLMAssertThrowsWithReason(unmanaged.intObj = (id)@[@"a"],
                              @"Invalid value 'a' of type '__NSCFConstantString' for 'int' set property 'AllPrimitiveSets.intObj'.");
    RLMAssertThrowsWithReason(unmanaged.intObj = (id)(@[@1, @"a"]),
                              @"Invalid value 'a' of type '__NSCFConstantString' for 'int' set property 'AllPrimitiveSets.intObj'.");
    RLMAssertThrowsWithReason(unmanaged.intObj = (id)unmanaged.floatObj,
                              @"RLMSet<float> does not match expected type 'int' for property 'AllPrimitiveSets.intObj'.");
    RLMAssertThrowsWithReason(unmanaged.intObj = (id)optUnmanaged.intObj,
                              @"RLMSet<int?> does not match expected type 'int' for property 'AllPrimitiveSets.intObj'.");
    RLMAssertThrowsWithReason(unmanaged[@"intObj"] = unmanaged[@"floatObj"],
                              @"RLMSet<float> does not match expected type 'int' for property 'AllPrimitiveSets.intObj'.");
    RLMAssertThrowsWithReason(unmanaged[@"intObj"] = optUnmanaged[@"intObj"],
                              @"RLMSet<int?> does not match expected type 'int' for property 'AllPrimitiveSets.intObj'.");

    RLMAssertThrowsWithReason(managed.intObj = (id)@[NSNull.null],
                              @"Invalid value '<null>' of type 'NSNull' for 'int' set property 'AllPrimitiveSets.intObj'.");
    RLMAssertThrowsWithReason(managed.intObj = (id)@[@"a"],
                              @"Invalid value 'a' of type '__NSCFConstantString' for 'int' set property 'AllPrimitiveSets.intObj'.");
    RLMAssertThrowsWithReason(managed.intObj = (id)(@[@1, @"a"]),
                              @"Invalid value 'a' of type '__NSCFConstantString' for 'int' set property 'AllPrimitiveSets.intObj'.");
    RLMAssertThrowsWithReason(managed.intObj = (id)managed.floatObj,
                              @"RLMSet<float> does not match expected type 'int' for property 'AllPrimitiveSets.intObj'.");
    RLMAssertThrowsWithReason(managed.intObj = (id)optManaged.intObj,
                              @"RLMSet<int?> does not match expected type 'int' for property 'AllPrimitiveSets.intObj'.");
    RLMAssertThrowsWithReason(managed[@"intObj"] = (id)managed[@"floatObj"],
                              @"RLMSet<float> does not match expected type 'int' for property 'AllPrimitiveSets.intObj'.");
    RLMAssertThrowsWithReason(managed[@"intObj"] = (id)optManaged[@"intObj"],
                              @"RLMSet<int?> does not match expected type 'int' for property 'AllPrimitiveSets.intObj'.");
}

- (void)testAllMethodsCheckThread {
    RLMSet *set = managed.intObj;
    [self dispatchAsyncAndWait:^{
        RLMAssertThrowsWithReason([set count], @"thread");

        RLMAssertThrowsWithReason([set addObject:@0], @"thread");
        RLMAssertThrowsWithReason([set addObjects:@[@0]], @"thread");
        RLMAssertThrowsWithReason([set removeAllObjects], @"thread");
        RLMAssertThrowsWithReason([set sortedResultsUsingKeyPath:@"self" ascending:YES], @"thread");
        RLMAssertThrowsWithReason([set sortedResultsUsingDescriptors:@[[RLMSortDescriptor sortDescriptorWithKeyPath:@"self" ascending:YES]]], @"thread");
        RLMAssertThrowsWithReason(set.allObjects[0], @"thread");
        RLMAssertThrowsWithReason([set valueForKey:@"self"], @"thread");
        RLMAssertThrowsWithReason([set setValue:@1 forKey:@"self"], @"thread");
        RLMAssertThrowsWithReason(({for (__unused id obj in set);}), @"thread");
    }];
}

- (void)testAllMethodsCheckForInvalidation {
    RLMSet *set = managed.intObj;
    [realm cancelWriteTransaction];
    [realm invalidate];

    XCTAssertNoThrow([set objectClassName]);
    XCTAssertNoThrow([set realm]);
    XCTAssertNoThrow([set isInvalidated]);

    RLMAssertThrowsWithReason([set count], @"invalidated");

    RLMAssertThrowsWithReason([set addObject:@0], @"invalidated");
    RLMAssertThrowsWithReason([set addObjects:@[@0]], @"invalidated");
    RLMAssertThrowsWithReason([set removeAllObjects], @"invalidated");

    RLMAssertThrowsWithReason([set sortedResultsUsingKeyPath:@"self" ascending:YES], @"invalidated");
    RLMAssertThrowsWithReason([set sortedResultsUsingDescriptors:@[[RLMSortDescriptor sortDescriptorWithKeyPath:@"self" ascending:YES]]], @"invalidated");
    RLMAssertThrowsWithReason(set.allObjects[0], @"invalidated");
    RLMAssertThrowsWithReason([set valueForKey:@"self"], @"invalidated");
    RLMAssertThrowsWithReason([set setValue:@1 forKey:@"self"], @"invalidated");
    RLMAssertThrowsWithReason(({for (__unused id obj in set);}), @"invalidated");

    [realm beginWriteTransaction];
}

- (void)testMutatingMethodsCheckForWriteTransaction {
    RLMSet *set = managed.intObj;
    [set addObject:@0];
    [realm commitWriteTransaction];

    XCTAssertNoThrow([set objectClassName]);
    XCTAssertNoThrow([set realm]);
    XCTAssertNoThrow([set isInvalidated]);

    XCTAssertNoThrow([set count]);
    XCTAssertNoThrow([set sortedResultsUsingKeyPath:@"self" ascending:YES]);
    XCTAssertNoThrow([set sortedResultsUsingDescriptors:@[[RLMSortDescriptor sortDescriptorWithKeyPath:@"self" ascending:YES]]]);
    XCTAssertNoThrow(set.allObjects[0]);
    XCTAssertNoThrow([set valueForKey:@"self"]);
    XCTAssertNoThrow(({for (__unused id obj in set);}));


    RLMAssertThrowsWithReason([set addObject:@0], @"write transaction");
    RLMAssertThrowsWithReason([set addObjects:@[@0]], @"write transaction");
    RLMAssertThrowsWithReason([set removeAllObjects], @"write transaction");

    RLMAssertThrowsWithReason([set setValue:@1 forKey:@"self"], @"write transaction");
}

- (void)testDeleteOwningObject {
    RLMSet *set = managed.intObj;
    uncheckedAssertFalse(set.isInvalidated);
    [realm deleteObject:managed];
    uncheckedAssertTrue(set.isInvalidated);
}

#pragma mark - Queries

#define RLMAssertCount(cls, expectedCount, ...) \
    uncheckedAssertEqual(expectedCount, ([cls objectsInRealm:realm where:__VA_ARGS__].count))

- (void)createObjectWithValueIndex:(NSUInteger)index {
    NSRange range = {index, 1};
    id obj = [AllPrimitiveSets createInRealm:realm withValue:@{
        %r %man @"$prop": [$values subarrayWithRange:range],
    }];
    [LinkToAllPrimitiveSets createInRealm:realm withValue:@[obj]];
    obj = [AllOptionalPrimitiveSets createInRealm:realm withValue:@{
        %o %man @"$prop": [$values subarrayWithRange:range],
    }];
    [LinkToAllOptionalPrimitiveSets createInRealm:realm withValue:@[obj]];
}

- (void)testQueryBasicOperators {
    [realm deleteAllObjects];

    %man RLMAssertCount($class, 0, @"ANY $prop = %@", $v0);
    %man RLMAssertCount($class, 0, @"ANY $prop != %@", $v0);
    %man %minmax RLMAssertCount($class, 0, @"ANY $prop > %@", $v0);
    %man %minmax RLMAssertCount($class, 0, @"ANY $prop >= %@", $v0);
    %man %minmax RLMAssertCount($class, 0, @"ANY $prop < %@", $v0);
    %man %minmax RLMAssertCount($class, 0, @"ANY $prop <= %@", $v0);

    [self createObjectWithValueIndex:0];

    %man RLMAssertCount($class, 0, @"ANY $prop = %@", $v1);
    %man RLMAssertCount($class, 1, @"ANY $prop = %@", $v0);
    %man RLMAssertCount($class, 0, @"ANY $prop != %@", $v0);
    %man RLMAssertCount($class, 1, @"ANY $prop != %@", $v1);
    %man %minmax RLMAssertCount($class, 0, @"ANY $prop > %@", $v0);
    %man %minmax RLMAssertCount($class, 1, @"ANY $prop >= %@", $v0);
    %man %minmax RLMAssertCount($class, 0, @"ANY $prop < %@", $v0);
    %r %man %minmax RLMAssertCount($class, 1, @"ANY $prop < %@", $v1);
    %o %man %minmax RLMAssertCount($class, 0, @"ANY $prop < %@", $v1);
    %man %minmax RLMAssertCount($class, 1, @"ANY $prop <= %@", $v0);

    [self createObjectWithValueIndex:1];

    %man RLMAssertCount($class, 1, @"ANY $prop = %@", $v0);
    %man RLMAssertCount($class, 1, @"ANY $prop = %@", $v1);
    %man RLMAssertCount($class, 1, @"ANY $prop != %@", $v0);
    %man RLMAssertCount($class, 1, @"ANY $prop != %@", $v1);
    %r %man %minmax RLMAssertCount($class, 1, @"ANY $prop > %@", $v0);
    %r %man %minmax RLMAssertCount($class, 2, @"ANY $prop >= %@", $v0);
    %r %man %minmax RLMAssertCount($class, 0, @"ANY $prop < %@", $v0);
    %r %man %minmax RLMAssertCount($class, 1, @"ANY $prop < %@", $v1);
    %r %man %minmax RLMAssertCount($class, 1, @"ANY $prop <= %@", $v0);
    %r %man %minmax RLMAssertCount($class, 2, @"ANY $prop <= %@", $v1);

    %o %man %minmax RLMAssertCount($class, 0, @"ANY $prop > %@", $v0);
    %o %man %minmax RLMAssertCount($class, 1, @"ANY $prop >= %@", $v1);
    %o %man %minmax RLMAssertCount($class, 0, @"ANY $prop < %@", $v1);
    %o %man %minmax RLMAssertCount($class, 1, @"ANY $prop < %@", $v2);
    %o %man %minmax RLMAssertCount($class, 1, @"ANY $prop <= %@", $v0);
    %o %man %minmax RLMAssertCount($class, 1, @"ANY $prop <= %@", $v1);

    %noany %man %nominmax RLMAssertThrows(([$class objectsInRealm:realm where:@"ANY $prop > %@", $v0]));
}

- (void)testQueryBetween {
    [realm deleteAllObjects];

    %noany %man %nominmax RLMAssertThrowsWithReason(([$class objectsInRealm:realm where:@"ANY $prop BETWEEN %@", @[$v0, $v1]]), ^n @"Operator 'BETWEEN' not supported for type '$basetype'");

    %man %minmax RLMAssertCount($class, 0, @"ANY $prop BETWEEN %@", @[$v0, $v1]);

    [self createObjectWithValueIndex:1];

    %r %man %minmax RLMAssertCount($class, 1, @"ANY $prop BETWEEN %@", @[$v1, $v1]);
    %r %man %minmax RLMAssertCount($class, 1, @"ANY $prop BETWEEN %@", @[$v0, $v1]);
    %r %man %minmax RLMAssertCount($class, 0, @"ANY $prop BETWEEN %@", @[$v0, $v0]);

    %o %man %minmax RLMAssertCount($class, 1, @"ANY $prop BETWEEN %@", @[$v1, $v1]);
    %o %man %minmax RLMAssertCount($class, 1, @"ANY $prop BETWEEN %@", @[$v1, $v2]);
    %o %man %minmax RLMAssertCount($class, 0, @"ANY $prop BETWEEN %@", @[$v3, $v3]);
}

- (void)testQueryIn {
    [realm deleteAllObjects];

    %man RLMAssertCount($class, 0, @"ANY $prop IN %@", @[$v0, $v1]);

    [self createObjectWithValueIndex:0];

    %man RLMAssertCount($class, 0, @"ANY $prop IN %@", @[$v1]);
    %man RLMAssertCount($class, 1, @"ANY $prop IN %@", @[$v0, $v1]);
}

- (void)testQueryCount {
    [realm deleteAllObjects];

    [AllPrimitiveSets createInRealm:realm withValue:@{
        %r %man @"$prop": @[$v0, $v1],
    }];
    [AllOptionalPrimitiveSets createInRealm:realm withValue:@{
        %o %man @"$prop": @[$v0, $v1],
    }];

    %man RLMAssertCount($class, 1U, @"$prop.@count == %@", @(2));
    %man RLMAssertCount($class, 0U, @"$prop.@count != %@", @(2));
    %man RLMAssertCount($class, 0, @"$prop.@count > %@", @(2));
    %man RLMAssertCount($class, 1, @"$prop.@count >= %@", @(2));
    %man RLMAssertCount($class, 0, @"$prop.@count < %@", @(2));
    %man RLMAssertCount($class, 1, @"$prop.@count <= %@", @(2));
}

- (void)testQuerySum {
    [realm deleteAllObjects];

    %noany %nodate %nosum %man RLMAssertThrowsWithReason(([$class objectsInRealm:realm where:@"$prop.@sum = %@", $v0]), ^n @"@sum can only be applied to a numeric property.");
    %noany %date %man RLMAssertThrowsWithReason(([$class objectsInRealm:realm where:@"$prop.@sum = %@", $v1]), ^n @"Cannot sum or average date properties");
    %noany %sum %man RLMAssertThrowsWithReason(([$class objectsInRealm:realm where:@"$prop.@sum = %@", $wrong]), ^n @"@sum on a property of type $basetype cannot be compared with '$wdesc'");
    %sum %man RLMAssertThrowsWithReason(([$class objectsInRealm:realm where:@"$prop.@sum.prop = %@", $wrong]), ^n @"Property '$prop' is not a link in object of type '$class'");
    %noany %sum %man RLMAssertThrowsWithReason(([$class objectsInRealm:realm where:@"$prop.@sum = %@", NSNull.null]), ^n @"@sum on a property of type $basetype cannot be compared with '<null>'");

    [AllPrimitiveSets createInRealm:realm withValue:@{
        %man %r %sum @"$prop": @[],
    }];
    [AllOptionalPrimitiveSets createInRealm:realm withValue:@{
        %man %o %sum @"$prop": @[],
    }];
    [AllPrimitiveSets createInRealm:realm withValue:@{
        %man %r %sum @"$prop": @[$v0],
    }];
    [AllOptionalPrimitiveSets createInRealm:realm withValue:@{
        %man %o %sum @"$prop": @[$v1],
    }];
    [AllPrimitiveSets createInRealm:realm withValue:@{
        %man %r %sum @"$prop": @[$v0, $v0],
    }];
    [AllOptionalPrimitiveSets createInRealm:realm withValue:@{
        %man %o %sum @"$prop": @[$v1, $v2],
    }];
    [AllPrimitiveSets createInRealm:realm withValue:@{
        %man %r %sum @"$prop": @[$v1, $v1, $v1],
    }];
    [AllOptionalPrimitiveSets createInRealm:realm withValue:@{
        %man %o %sum @"$prop": @[$v1, $v1, $v1],
    }];

    %r %sum %man RLMAssertCount($class, 1U, @"$prop.@sum == %@", @0);
    %r %sum %man RLMAssertCount($class, 2U, @"$prop.@sum == %@", $v0);
    %r %sum %man RLMAssertCount($class, 3U, @"$prop.@sum != %@", $v1);
    %r %sum %man RLMAssertCount($class, 3U, @"$prop.@sum >= %@", $v0);
    %r %sum %man RLMAssertCount($class, 1U, @"$prop.@sum > %@", $v0);
    %r %sum %man RLMAssertCount($class, 3U, @"$prop.@sum < %@", $v1);
    %r %sum %man RLMAssertCount($class, 4U, @"$prop.@sum <= %@", $v1);

    %o %sum %man RLMAssertCount($class, 1U, @"$prop.@sum == %@", @0);
    %o %sum %man RLMAssertCount($class, 2U, @"$prop.@sum == %@", $v1);
    %o %sum %man RLMAssertCount($class, 2U, @"$prop.@sum != %@", $v1);
    %o %sum %man RLMAssertCount($class, 3U, @"$prop.@sum >= %@", $v1);
    %o %sum %man RLMAssertCount($class, 1U, @"$prop.@sum > %@", $v1);
    %o %sum %man RLMAssertCount($class, 3U, @"$prop.@sum < %@", $v2);
    %o %sum %man RLMAssertCount($class, 3U, @"$prop.@sum <= %@", $v1);
}

- (void)testQueryAverage {
    [realm deleteAllObjects];

    %noany %nodate %noavg %man RLMAssertThrowsWithReason(([$class objectsInRealm:realm where:@"$prop.@avg = %@", $v0]), ^n @"@avg can only be applied to a numeric property.");
    %noany %date %man RLMAssertThrowsWithReason(([$class objectsInRealm:realm where:@"$prop.@avg = %@", $v0]), ^n @"Cannot sum or average date properties");
    %noany %avg %man RLMAssertThrowsWithReason(([$class objectsInRealm:realm where:@"$prop.@avg = %@", $wrong]), ^n @"@avg on a property of type $basetype cannot be compared with '$wdesc'");
    %noany %avg %man RLMAssertThrowsWithReason(([$class objectsInRealm:realm where:@"$prop.@avg.prop = %@", $wrong]), ^n @"Property '$prop' is not a link in object of type '$class'");

    [AllPrimitiveSets createInRealm:realm withValue:@{
        %man %r %avg @"$prop": @[],
    }];
    [AllOptionalPrimitiveSets createInRealm:realm withValue:@{
        %man %o %avg @"$prop": @[],
    }];
    [AllPrimitiveSets createInRealm:realm withValue:@{
        %man %r %avg @"$prop": @[$v1],
    }];
    [AllOptionalPrimitiveSets createInRealm:realm withValue:@{
        %man %o %avg @"$prop": @[$v2],
    }];
    [AllPrimitiveSets createInRealm:realm withValue:@{
        %man %r %avg @"$prop": @[$v0, $v1],
    }];
    [AllOptionalPrimitiveSets createInRealm:realm withValue:@{
        %man %o %avg @"$prop": @[$v1, $v2],
    }];
    [AllPrimitiveSets createInRealm:realm withValue:@{
        %man %r %avg @"$prop": @[$v1],
    }];
    [AllOptionalPrimitiveSets createInRealm:realm withValue:@{
        %man %o %avg @"$prop": @[$v2],
    }];

    %avg %man RLMAssertCount($class, 1U, @"$prop.@avg == %@", NSNull.null);
    %r %avg %man RLMAssertCount($class, 2U, @"$prop.@avg == %@", $v1);
    %o %avg %man RLMAssertCount($class, 2U, @"$prop.@avg == %@", $v2);
    %r %avg %man RLMAssertCount($class, 2U, @"$prop.@avg != %@", $v1);
    %o %avg %man RLMAssertCount($class, 2U, @"$prop.@avg != %@", $v2);
    %r %avg %man RLMAssertCount($class, 2U, @"$prop.@avg >= %@", $v1);
    %o %avg %man RLMAssertCount($class, 2U, @"$prop.@avg >= %@", $v2);
    %r %avg %man RLMAssertCount($class, 3U, @"$prop.@avg > %@", $v0);
    %o %avg %man RLMAssertCount($class, 3U, @"$prop.@avg > %@", $v1);
    %r %avg %man RLMAssertCount($class, 1U, @"$prop.@avg < %@", $v1);
    %o %avg %man RLMAssertCount($class, 1U, @"$prop.@avg < %@", $v2);
    %r %avg %man RLMAssertCount($class, 3U, @"$prop.@avg <= %@", $v1);
    %o %avg %man RLMAssertCount($class, 3U, @"$prop.@avg <= %@", $v2);
}

- (void)testQueryMin {
    [realm deleteAllObjects];

    %noany %nominmax %man RLMAssertThrowsWithReason(([$class objectsInRealm:realm where:@"$prop.@min = %@", $v0]), ^n @"@min can only be applied to a numeric property.");
    %noany %minmax %man RLMAssertThrowsWithReason(([$class objectsInRealm:realm where:@"$prop.@min = %@", $wrong]), ^n @"@min on a property of type $basetype cannot be compared with '$wdesc'");
    %minmax %man RLMAssertThrowsWithReason(([$class objectsInRealm:realm where:@"$prop.@min.prop = %@", $wrong]), ^n @"Property '$prop' is not a link in object of type '$class'");

    // No objects, so count is zero
    %minmax %man RLMAssertCount($class, 0U, @"$prop.@min == %@", $v0);

    [AllPrimitiveSets createInRealm:realm withValue:@{}];
    [AllOptionalPrimitiveSets createInRealm:realm withValue:@{}];

    // Only empty arrays, so count is zero
    %r %minmax %man RLMAssertCount($class, 0U, @"$prop.@min == %@", $v0);
    %r %minmax %man RLMAssertCount($class, 0U, @"$prop.@min == %@", $v1);

    %o %minmax %man RLMAssertCount($class, 0U, @"$prop.@min == %@", $v1);
    %o %minmax %man RLMAssertCount($class, 0U, @"$prop.@min == %@", $v2);

    [self createObjectWithValueIndex:1];

    %r %minmax %man RLMAssertCount($class, 1U, @"$prop.@min == %@", $v1);
    %o %minmax %man RLMAssertCount($class, 1U, @"$prop.@min == %@", $v1);

    %r %minmax %man RLMAssertCount($class, 0U, @"$prop.@min == %@", $v0);
    %o %minmax %man RLMAssertCount($class, 0U, @"$prop.@min == %@", $v2);

    [AllPrimitiveSets createInRealm:realm withValue:@{
        %minmax %r %man @"$prop": @[$v1, $v0],
    }];
    [AllOptionalPrimitiveSets createInRealm:realm withValue:@{
        %minmax %o %man @"$prop": @[$v2, $v1],
    }];

    %r %minmax %man RLMAssertCount($class, 1U, @"$prop.@min == %@", $v0);
    %o %minmax %man RLMAssertCount($class, 2U, @"$prop.@min == %@", $v1);

    %r %minmax %man RLMAssertCount($class, 1U, @"$prop.@min == %@", $v0);
    %o %minmax %man RLMAssertCount($class, 2U, @"$prop.@min == %@", $v1);
}

- (void)testQueryMax {
    [realm deleteAllObjects];

    %noany %nominmax %man RLMAssertThrowsWithReason(([$class objectsInRealm:realm where:@"$prop.@max = %@", $v0]), ^n @"@max can only be applied to a numeric property.");
    %noany %minmax %man RLMAssertThrowsWithReason(([$class objectsInRealm:realm where:@"$prop.@max = %@", $wrong]), ^n @"@max on a property of type $basetype cannot be compared with '$wdesc'");
    %minmax %man RLMAssertThrowsWithReason(([$class objectsInRealm:realm where:@"$prop.@max.prop = %@", $wrong]), ^n @"Property '$prop' is not a link in object of type '$class'");

    // No objects, so count is zero
    %minmax %man RLMAssertCount($class, 0U, @"$prop.@max == %@", $v0);

    [AllPrimitiveSets createInRealm:realm withValue:@{}];
    [AllOptionalPrimitiveSets createInRealm:realm withValue:@{}];

    // Only empty arrays, so count is zero
    %r %minmax %man RLMAssertCount($class, 0U, @"$prop.@max == %@", $v0);
    %r %minmax %man RLMAssertCount($class, 0U, @"$prop.@max == %@", $v1);

    %o %minmax %man RLMAssertCount($class, 0U, @"$prop.@max == %@", $v1);
    %o %minmax %man RLMAssertCount($class, 0U, @"$prop.@max == %@", $v2);

    %minmax %man RLMAssertCount($class, 1U, @"$prop.@max == nil");
    %minmax %man RLMAssertCount($class, 1U, @"$prop.@max == %@", NSNull.null);

    [self createObjectWithValueIndex:1];

    %r %minmax %man RLMAssertCount($class, 1U, @"$prop.@max == %@", $v1);
    %r %minmax %man RLMAssertCount($class, 0U, @"$prop.@max == %@", $v0);

    %o %minmax %man RLMAssertCount($class, 1U, @"$prop.@max == %@", $v1);
    %o %minmax %man RLMAssertCount($class, 0U, @"$prop.@max == %@", $v2);

    [AllPrimitiveSets createInRealm:realm withValue:@{
        %minmax %r %man @"$prop": @[$v0],
    }];

    [AllPrimitiveSets createInRealm:realm withValue:@{
        %minmax %r %man @"$prop": @[$v1, $v0],
    }];
    [AllOptionalPrimitiveSets createInRealm:realm withValue:@{
        %minmax %o %man @"$prop": @[$v1, $v0],
    }];

    %noany %r %minmax %man RLMAssertCount($class, 1U, @"$prop.@max == %@", $v0);
    %noany %r %minmax %man RLMAssertCount($class, 2U, @"$prop.@max == %@", $v1);

    %o %minmax %man RLMAssertCount($class, 1U, @"$prop.@max == %@", $v0);
    %o %minmax %man RLMAssertCount($class, 2U, @"$prop.@max == %@", $v1);

    %any %minmax %man RLMAssertCount($class, 1U, @"$prop.@max == %@", $v0);
    %any %minmax %man RLMAssertCount($class, 2U, @"$prop.@max == %@", $v1);
}

- (void)testQueryBasicOperatorsOverLink {
    [realm deleteAllObjects];

    %man RLMAssertCount(LinkTo$class, 0, @"ANY link.$prop = %@", $v0);
    %man RLMAssertCount(LinkTo$class, 0, @"ANY link.$prop != %@", $v0);
    %man %minmax RLMAssertCount(LinkTo$class, 0, @"ANY link.$prop > %@", $v0);
    %man %minmax RLMAssertCount(LinkTo$class, 0, @"ANY link.$prop >= %@", $v0);
    %man %minmax RLMAssertCount(LinkTo$class, 0, @"ANY link.$prop < %@", $v0);
    %man %minmax RLMAssertCount(LinkTo$class, 0, @"ANY link.$prop <= %@", $v0);

    [self createObjectWithValueIndex:1];

    %man RLMAssertCount(LinkTo$class, 1, @"ANY link.$prop = %@", $v1);
    %man RLMAssertCount(LinkTo$class, 1, @"ANY link.$prop != %@", $v0);
    %r %man %minmax RLMAssertCount(LinkTo$class, 1, @"ANY link.$prop > %@", $v0);
    %o %man %minmax RLMAssertCount(LinkTo$class, 0, @"ANY link.$prop > %@", $v1);

    %r %man %minmax RLMAssertCount(LinkTo$class, 1, @"ANY link.$prop >= %@", $v0);
    %o %man %minmax RLMAssertCount(LinkTo$class, 1, @"ANY link.$prop >= %@", $v1);

    %man %minmax RLMAssertCount(LinkTo$class, 0, @"ANY link.$prop < %@", $v0);
    %r %man %minmax RLMAssertCount(LinkTo$class, 1, @"ANY link.$prop < %@", $v4);
    %o %man %minmax RLMAssertCount(LinkTo$class, 1, @"ANY link.$prop < %@", $v2);

    %man %minmax RLMAssertCount(LinkTo$class, 1, @"ANY link.$prop <= %@", $v1);

    %man %nominmax %noany RLMAssertThrowsWithReason(([LinkTo$class objectsInRealm:realm where:@"ANY link.$prop > %@", $v0]), ^n @"Operator '>' not supported for type '$basetype'");
}

- (void)testSubstringQueries {
    NSArray *values = @[
        @"",

        @"á", @"ó", @"ú",

        @"áá", @"áó", @"áú",
        @"óá", @"óó", @"óú",
        @"úá", @"úó", @"úú",

        @"ááá", @"ááó", @"ááú", @"áóá", @"áóó", @"áóú", @"áúá", @"áúó", @"áúú",
        @"óáá", @"óáó", @"óáú", @"óóá", @"óóó", @"óóú", @"óúá", @"óúó", @"óúú",
        @"úáá", @"úáó", @"úáú", @"úóá", @"úóó", @"úóú", @"úúá", @"úúó", @"úúú",
    ];

    void (^create)(NSString *) = ^(NSString *value) {
        id obj = [AllPrimitiveSets createInRealm:realm withValue:@{
            @"stringObj": @[value],
            @"dataObj": @[[value dataUsingEncoding:NSUTF8StringEncoding]]
        }];
        [LinkToAllPrimitiveSets createInRealm:realm withValue:@[obj]];
        obj = [AllOptionalPrimitiveSets createInRealm:realm withValue:@{
            @"stringObj": @[value],
            @"dataObj": @[[value dataUsingEncoding:NSUTF8StringEncoding]]
        }];
        [LinkToAllOptionalPrimitiveSets createInRealm:realm withValue:@[obj]];
    };

    for (NSString *value in values) {
        create(value);
        create(value.uppercaseString);
        create([value stringByApplyingTransform:NSStringTransformStripDiacritics reverse:NO]);
        create([value.uppercaseString stringByApplyingTransform:NSStringTransformStripDiacritics reverse:NO]);
    }

    void (^test)(NSString *, id, NSUInteger) = ^(NSString *operator, NSString *value, NSUInteger count) {
        NSData *data = [value dataUsingEncoding:NSUTF8StringEncoding];

        NSString *query = [NSString stringWithFormat:@"ANY stringObj %@ %%@", operator];
        %man %string RLMAssertCount($class, count, query, value);
        query = [NSString stringWithFormat:@"ANY link.stringObj %@ %%@", operator];
        %man %string RLMAssertCount(LinkTo$class, count, query, value);

        query = [NSString stringWithFormat:@"ANY dataObj %@ %%@", operator];
        %man %string RLMAssertCount($class, count, query, data);
        query = [NSString stringWithFormat:@"ANY link.dataObj %@ %%@", operator];
        %man %string RLMAssertCount(LinkTo$class, count, query, data);
    };
    void (^testNull)(NSString *, NSUInteger) = ^(NSString *operator, NSUInteger count) {
        NSString *query = [NSString stringWithFormat:@"ANY stringObj %@ nil", operator];
        RLMAssertThrowsWithReason([AllPrimitiveSets objectsInRealm:realm where:query],
                                  @"Expected object of type string for property 'stringObj' on object of type 'AllPrimitiveSets', but received: (null)");
        RLMAssertCount(AllOptionalPrimitiveSets, count, query, NSNull.null);
        query = [NSString stringWithFormat:@"ANY link.stringObj %@ nil", operator];
        RLMAssertThrowsWithReason([LinkToAllPrimitiveSets objectsInRealm:realm where:query],
                                  @"Expected object of type string for property 'link.stringObj' on object of type 'LinkToAllPrimitiveSets', but received: (null)");
        RLMAssertCount(LinkToAllOptionalPrimitiveSets, count, query, NSNull.null);

        query = [NSString stringWithFormat:@"ANY dataObj %@ nil", operator];
        RLMAssertThrowsWithReason([AllPrimitiveSets objectsInRealm:realm where:query],
                                  @"Expected object of type data for property 'dataObj' on object of type 'AllPrimitiveSets', but received: (null)");
        RLMAssertCount(AllOptionalPrimitiveSets, count, query, NSNull.null);

        query = [NSString stringWithFormat:@"ANY link.dataObj %@ nil", operator];
        RLMAssertThrowsWithReason([LinkToAllPrimitiveSets objectsInRealm:realm where:query],
                                  @"Expected object of type data for property 'link.dataObj' on object of type 'LinkToAllPrimitiveSets', but received: (null)");
        RLMAssertCount(LinkToAllOptionalPrimitiveSets, count, query, NSNull.null);
    };

    // Core's implementation of case-insensitive comparisons only works for
    // unaccented a-z, so the diacritic-sensitive, case-insensitive queries
    // match half as many as they should. Many of the below tests will start
    // failing if this is fixed.

    testNull(@"==", 0);
    test(@"==", @"", 4);
    test(@"==", @"a", 1);
    test(@"==", @"á", 1);
    test(@"==[c]", @"a", 2);
    test(@"==[c]", @"á", 1);
    test(@"==", @"A", 1);
    test(@"==", @"Á", 1);
    test(@"==[c]", @"A", 2);
    test(@"==[c]", @"Á", 1);
    test(@"==[d]", @"a", 2);
    test(@"==[d]", @"á", 2);
    test(@"==[cd]", @"a", 4);
    test(@"==[cd]", @"á", 4);
    test(@"==[d]", @"A", 2);
    test(@"==[d]", @"Á", 2);
    test(@"==[cd]", @"A", 4);
    test(@"==[cd]", @"Á", 4);

    testNull(@"!=", 160);
    test(@"!=", @"", 156);
    test(@"!=", @"a", 159);
    test(@"!=", @"á", 159);
    test(@"!=[c]", @"a", 158);
    test(@"!=[c]", @"á", 159);
    test(@"!=", @"A", 159);
    test(@"!=", @"Á", 159);
    test(@"!=[c]", @"A", 158);
    test(@"!=[c]", @"Á", 159);
    test(@"!=[d]", @"a", 158);
    test(@"!=[d]", @"á", 158);
    test(@"!=[cd]", @"a", 156);
    test(@"!=[cd]", @"á", 156);
    test(@"!=[d]", @"A", 158);
    test(@"!=[d]", @"Á", 158);
    test(@"!=[cd]", @"A", 156);
    test(@"!=[cd]", @"Á", 156);

    testNull(@"CONTAINS", 0);
    testNull(@"CONTAINS[c]", 0);
    testNull(@"CONTAINS[d]", 0);
    testNull(@"CONTAINS[cd]", 0);
    test(@"CONTAINS", @"a", 25);
    test(@"CONTAINS", @"á", 25);
    test(@"CONTAINS[c]", @"a", 50);
    test(@"CONTAINS[c]", @"á", 25);
    test(@"CONTAINS", @"A", 25);
    test(@"CONTAINS", @"Á", 25);
    test(@"CONTAINS[c]", @"A", 50);
    test(@"CONTAINS[c]", @"Á", 25);
    test(@"CONTAINS[d]", @"a", 50);
    test(@"CONTAINS[d]", @"á", 50);
    test(@"CONTAINS[cd]", @"a", 100);
    test(@"CONTAINS[cd]", @"á", 100);
    test(@"CONTAINS[d]", @"A", 50);
    test(@"CONTAINS[d]", @"Á", 50);
    test(@"CONTAINS[cd]", @"A", 100);
    test(@"CONTAINS[cd]", @"Á", 100);

    test(@"BEGINSWITH", @"a", 13);
    test(@"BEGINSWITH", @"á", 13);
    test(@"BEGINSWITH[c]", @"a", 26);
    test(@"BEGINSWITH[c]", @"á", 13);
    test(@"BEGINSWITH", @"A", 13);
    test(@"BEGINSWITH", @"Á", 13);
    test(@"BEGINSWITH[c]", @"A", 26);
    test(@"BEGINSWITH[c]", @"Á", 13);
    test(@"BEGINSWITH[d]", @"a", 26);
    test(@"BEGINSWITH[d]", @"á", 26);
    test(@"BEGINSWITH[cd]", @"a", 52);
    test(@"BEGINSWITH[cd]", @"á", 52);
    test(@"BEGINSWITH[d]", @"A", 26);
    test(@"BEGINSWITH[d]", @"Á", 26);
    test(@"BEGINSWITH[cd]", @"A", 52);
    test(@"BEGINSWITH[cd]", @"Á", 52);

    test(@"ENDSWITH", @"a", 13);
    test(@"ENDSWITH", @"á", 13);
    test(@"ENDSWITH[c]", @"a", 26);
    test(@"ENDSWITH[c]", @"á", 13);
    test(@"ENDSWITH", @"A", 13);
    test(@"ENDSWITH", @"Á", 13);
    test(@"ENDSWITH[c]", @"A", 26);
    test(@"ENDSWITH[c]", @"Á", 13);
    test(@"ENDSWITH[d]", @"a", 26);
    test(@"ENDSWITH[d]", @"á", 26);
    test(@"ENDSWITH[cd]", @"a", 52);
    test(@"ENDSWITH[cd]", @"á", 52);
    test(@"ENDSWITH[d]", @"A", 26);
    test(@"ENDSWITH[d]", @"Á", 26);
    test(@"ENDSWITH[cd]", @"A", 52);
    test(@"ENDSWITH[cd]", @"Á", 52);
}


#pragma clang diagnostic ignored "-Warc-retain-cycles"

- (void)testNotificationSentInitially {
    [realm commitWriteTransaction];

    id expectation = [self expectationWithDescription:@""];
    id token = [managed.intObj addNotificationBlock:^(RLMSet *set, RLMCollectionChange *change, NSError *error) {
        XCTAssertNotNil(set);
        uncheckedAssertNil(change);
        uncheckedAssertNil(error);
        [expectation fulfill];
    }];

    [self waitForExpectationsWithTimeout:2.0 handler:nil];
    [(RLMNotificationToken *)token invalidate];
}

- (void)testNotificationSentAfterCommit {
    [realm commitWriteTransaction];

    __block bool first = true;
    __block id expectation = [self expectationWithDescription:@""];
    id token = [managed.intObj addNotificationBlock:^(RLMSet *set, RLMCollectionChange *change, NSError *error) {
        XCTAssertNotNil(set);
        uncheckedAssertNil(error);
        if (first) {
            uncheckedAssertNil(change);
        }
        else {
            uncheckedAssertEqualObjects(change.insertions, @[@0]);
        }

        first = false;
        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:2.0 handler:nil];

    expectation = [self expectationWithDescription:@""];
    [self dispatchAsyncAndWait:^{
        RLMRealm *r = [RLMRealm defaultRealm];
        [r transactionWithBlock:^{
            RLMSet *set = [(AllPrimitiveSets *)[AllPrimitiveSets allObjectsInRealm:r].firstObject intObj];
            [set addObject:@0];
        }];
    }];
    [self waitForExpectationsWithTimeout:2.0 handler:nil];

    [(RLMNotificationToken *)token invalidate];
}

- (void)testNotificationNotSentForUnrelatedChange {
    [realm commitWriteTransaction];

    id expectation = [self expectationWithDescription:@""];
    id token = [managed.intObj addNotificationBlock:^(__unused RLMSet *set, __unused RLMCollectionChange *change, __unused NSError *error) {
        // will throw if it's incorrectly called a second time due to the
        // unrelated write transaction
        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:2.0 handler:nil];

    // All notification blocks are called as part of a single runloop event, so
    // waiting for this one also waits for the above one to get a chance to run
    [self waitForNotification:RLMRealmDidChangeNotification realm:realm block:^{
        [self dispatchAsyncAndWait:^{
            RLMRealm *r = [RLMRealm defaultRealm];
            [r transactionWithBlock:^{
                [AllPrimitiveSets createInRealm:r withValue:@[]];
            }];
        }];
    }];
    [(RLMNotificationToken *)token invalidate];
}

- (void)testNotificationSentOnlyForActualRefresh {
    [realm commitWriteTransaction];

    __block id expectation = [self expectationWithDescription:@""];
    id token = [managed.intObj addNotificationBlock:^(RLMSet *set, __unused RLMCollectionChange *change, NSError *error) {
        XCTAssertNotNil(set);
        uncheckedAssertNil(error);
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
            RLMRealm *r = [RLMRealm defaultRealm];
            [r transactionWithBlock:^{
                RLMSet *set = [(AllPrimitiveSets *)[AllPrimitiveSets allObjectsInRealm:r].firstObject intObj];
                [set addObject:@0];
            }];
        }];
    }];

    expectation = [self expectationWithDescription:@""];
    [realm refresh];
    [self waitForExpectationsWithTimeout:2.0 handler:nil];

    [(RLMNotificationToken *)token invalidate];
}

- (void)testDeletingObjectWithNotificationsRegistered {
    [managed.intObj addObjects:@[@10, @20]];
    [realm commitWriteTransaction];

    __block bool first = true;
    __block id expectation = [self expectationWithDescription:@""];
    id token = [managed.intObj addNotificationBlock:^(RLMSet *set, RLMCollectionChange *change, NSError *error) {
        XCTAssertNotNil(set);
        uncheckedAssertNil(error);
        if (first) {
            uncheckedAssertNil(change);
            first = false;
        }
        else {
            uncheckedAssertEqualObjects(change.deletions, (@[@0, @1]));
        }
        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:2.0 handler:nil];

    [realm beginWriteTransaction];
    [realm deleteObject:managed];
    [realm commitWriteTransaction];

    expectation = [self expectationWithDescription:@""];
    [self waitForExpectationsWithTimeout:2.0 handler:nil];

    [(RLMNotificationToken *)token invalidate];
}

@end
