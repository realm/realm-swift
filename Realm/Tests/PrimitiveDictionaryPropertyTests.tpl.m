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
@interface NSUUID (RLMUUIDCompateTests)
- (NSComparisonResult)compare:(NSUUID *)other;
@end
@implementation NSUUID (RLMUUIDCompateTests)
- (NSComparisonResult)compare:(NSUUID *)other {
    return [[self UUIDString] compare:other.UUIDString];
}
@end

@interface LinkToAllPrimitiveDictionaries : RLMObject
@property (nonatomic) AllPrimitiveDictionaries *link;
@end
@implementation LinkToAllPrimitiveDictionaries
@end

@interface LinkToAllOptionalPrimitiveDictionaries : RLMObject
@property (nonatomic) AllOptionalPrimitiveDictionaries *link;
@end
@implementation LinkToAllOptionalPrimitiveDictionaries
@end

@interface PrimitiveArrayPropertyTests : RLMTestCase
@end

@implementation PrimitiveArrayPropertyTests {
    AllPrimitiveDictionaries *unmanaged;
    AllPrimitiveDictionaries *managed;
    AllOptionalPrimitiveDictionaries *optUnmanaged;
    AllOptionalPrimitiveDictionaries *optManaged;
    RLMRealm *realm;
    NSArray<RLMDictionary *> *allDictionaries;
}

- (void)setUp {
    unmanaged = [[AllPrimitiveDictionaries alloc] init];
    optUnmanaged = [[AllOptionalPrimitiveDictionaries alloc] init];
    realm = [RLMRealm defaultRealm];
    [realm beginWriteTransaction];
    managed = [AllPrimitiveDictionaries createInRealm:realm withValue:@[]];
    optManaged = [AllOptionalPrimitiveDictionaries createInRealm:realm withValue:@[]];
    allDictionaries = @[
        $dictionary,
    ];
}

- (void)tearDown {
    if (realm.inWriteTransaction) {
        [realm cancelWriteTransaction];
    }
}

- (void)addObjects {
    [$dictionary addObjectsFrom:$values];
}

- (void)testCount {
    XCTAssertEqual(unmanaged.intObj.count, 0U);
    unmanaged.intObj[@"testVal"] = @1;
    XCTAssertEqual(unmanaged.intObj.count, 1U);
}

- (void)testType {
    XCTAssertEqual(unmanaged.boolObj.type, RLMPropertyTypeBool);
    XCTAssertEqual(unmanaged.intObj.type, RLMPropertyTypeInt);
    XCTAssertEqual(unmanaged.floatObj.type, RLMPropertyTypeFloat);
    XCTAssertEqual(unmanaged.doubleObj.type, RLMPropertyTypeDouble);
    XCTAssertEqual(unmanaged.stringObj.type, RLMPropertyTypeString);
    XCTAssertEqual(unmanaged.dataObj.type, RLMPropertyTypeData);
    XCTAssertEqual(unmanaged.dateObj.type, RLMPropertyTypeDate);
    XCTAssertEqual(optUnmanaged.boolObj.type, RLMPropertyTypeBool);
    XCTAssertEqual(optUnmanaged.intObj.type, RLMPropertyTypeInt);
    XCTAssertEqual(optUnmanaged.floatObj.type, RLMPropertyTypeFloat);
    XCTAssertEqual(optUnmanaged.doubleObj.type, RLMPropertyTypeDouble);
    XCTAssertEqual(optUnmanaged.stringObj.type, RLMPropertyTypeString);
    XCTAssertEqual(optUnmanaged.dataObj.type, RLMPropertyTypeData);
    XCTAssertEqual(optUnmanaged.dateObj.type, RLMPropertyTypeDate);
}

- (void)testOptional {
    XCTAssertFalse(unmanaged.boolObj.optional);
    XCTAssertFalse(unmanaged.intObj.optional);
    XCTAssertFalse(unmanaged.floatObj.optional);
    XCTAssertFalse(unmanaged.doubleObj.optional);
    XCTAssertFalse(unmanaged.stringObj.optional);
    XCTAssertFalse(unmanaged.dataObj.optional);
    XCTAssertFalse(unmanaged.dateObj.optional);
    XCTAssertTrue(optUnmanaged.boolObj.optional);
    XCTAssertTrue(optUnmanaged.intObj.optional);
    XCTAssertTrue(optUnmanaged.floatObj.optional);
    XCTAssertTrue(optUnmanaged.doubleObj.optional);
    XCTAssertTrue(optUnmanaged.stringObj.optional);
    XCTAssertTrue(optUnmanaged.dataObj.optional);
    XCTAssertTrue(optUnmanaged.dateObj.optional);
}

- (void)testObjectClassName {
    XCTAssertNil(unmanaged.boolObj.objectClassName);
    XCTAssertNil(unmanaged.intObj.objectClassName);
    XCTAssertNil(unmanaged.floatObj.objectClassName);
    XCTAssertNil(unmanaged.doubleObj.objectClassName);
    XCTAssertNil(unmanaged.stringObj.objectClassName);
    XCTAssertNil(unmanaged.dataObj.objectClassName);
    XCTAssertNil(unmanaged.dateObj.objectClassName);
    XCTAssertNil(optUnmanaged.boolObj.objectClassName);
    XCTAssertNil(optUnmanaged.intObj.objectClassName);
    XCTAssertNil(optUnmanaged.floatObj.objectClassName);
    XCTAssertNil(optUnmanaged.doubleObj.objectClassName);
    XCTAssertNil(optUnmanaged.stringObj.objectClassName);
    XCTAssertNil(optUnmanaged.dataObj.objectClassName);
    XCTAssertNil(optUnmanaged.dateObj.objectClassName);
}

- (void)testRealm {
    XCTAssertNil(unmanaged.boolObj.realm);
    XCTAssertNil(unmanaged.intObj.realm);
    XCTAssertNil(unmanaged.floatObj.realm);
    XCTAssertNil(unmanaged.doubleObj.realm);
    XCTAssertNil(unmanaged.stringObj.realm);
    XCTAssertNil(unmanaged.dataObj.realm);
    XCTAssertNil(unmanaged.dateObj.realm);
    XCTAssertNil(optUnmanaged.boolObj.realm);
    XCTAssertNil(optUnmanaged.intObj.realm);
    XCTAssertNil(optUnmanaged.floatObj.realm);
    XCTAssertNil(optUnmanaged.doubleObj.realm);
    XCTAssertNil(optUnmanaged.stringObj.realm);
    XCTAssertNil(optUnmanaged.dataObj.realm);
    XCTAssertNil(optUnmanaged.dateObj.realm);
}

- (void)testInvalidated {
    RLMDictionary *dictionary;
    @autoreleasepool {
        AllPrimitiveDictionaries *obj = [[AllPrimitiveDictionaries alloc] init];
        dictionary = obj.intObj;
        XCTAssertFalse(dictionary.invalidated);
    }
    XCTAssertFalse(dictionary.invalidated);
}

- (void)testDeleteObjectsInRealm {
    RLMAssertThrowsWithReason([realm deleteObjects:$allDictionaries], @"Cannot delete objects from RLMArray");
}

- (void)testObjectAtIndex {
    RLMAssertThrowsWithReason([unmanaged.intObj objectAtIndex:0],
                              @"Index 0 is out of bounds (must be less than 0).");
    unmanaged.intObj[@"testVal"] = @1;
    XCTAssertEqualObjects([unmanaged.intObj objectAtIndex:0], @1);
}

- (void)testFirstObject {
    XCTAssertNil($allDictionaries.firstObject);

    [self addObjects];
    XCTAssertEqualObjects($dictionary.firstObject, $first);

    [$allDictionaries removeAllObjects];

    %o $dictionary[@"0"] = NSNull.null;
    %o XCTAssertEqualObjects($dictionary.firstObject, NSNull.null);
}
/**
- (void)testLastObject {
    XCTAssertNil($allDictionaries.lastObject);

    [self addObjects];

    XCTAssertEqualObjects($dictionary.lastObject, $last);

    [$allDictionaries removeLastObject];
    %o XCTAssertEqualObjects($dictionary.lastObject, $v1);
}
*/

- (void)testAddObject {
    RLMAssertThrowsWithReason([$dictionary addObject:$wrong], ^n @"Invalid value '$wdesc' of type '$wtype' for expected type '$type'");
    %r RLMAssertThrowsWithReason([$dictionary addObject:NSNull.null], ^n @"Invalid value '<null>' of type 'NSNull' for expected type '$type'");

    [$dictionary addObject:$v0];
    XCTAssertEqualObjects($dictionary[0], $v0);

    %o [$dictionary addObject:NSNull.null];
    %o XCTAssertEqualObjects($dictionary[1], NSNull.null);
}

- (void)testAddObjects {
    RLMAssertThrowsWithReason([$dictionary addObjects:@[$wrong]], ^n @"Invalid value '$wdesc' of type '$wtype' for expected type '$type'");
    %r RLMAssertThrowsWithReason([$dictionary addObjects:@[NSNull.null]], ^n @"Invalid value '<null>' of type 'NSNull' for expected type '$type'");

    [self addObjects];
    XCTAssertEqualObjects($dictionary[0], $v0);
    XCTAssertEqualObjects($dictionary[1], $v1);
    %o XCTAssertEqualObjects($dictionary[2], NSNull.null);
}

- (void)testInsertObject {
    RLMAssertThrowsWithReason([$dictionary insertObject:$wrong atIndex:0], ^n @"Invalid value '$wdesc' of type '$wtype' for expected type '$type'");
    %r RLMAssertThrowsWithReason([$dictionary insertObject:NSNull.null atIndex:0], ^n @"Invalid value '<null>' of type 'NSNull' for expected type '$type'");
    RLMAssertThrowsWithReason([$dictionary insertObject:$v0 atIndex:1], ^n @"Index 1 is out of bounds (must be less than 1).");

    [$dictionary insertObject:$v0 atIndex:0];
    XCTAssertEqualObjects($dictionary[0], $v0);

    [$dictionary insertObject:$v1 atIndex:0];
    XCTAssertEqualObjects($dictionary[0], $v1);
    XCTAssertEqualObjects($dictionary[1], $v0);

    %o [$dictionary insertObject:NSNull.null atIndex:1];
    %o XCTAssertEqualObjects($dictionary[0], $v1);
    %o XCTAssertEqualObjects($dictionary[1], NSNull.null);
    %o XCTAssertEqualObjects($dictionary[2], $v0);
}

- (void)testRemoveObject {
    RLMAssertThrowsWithReason([$allDictionaries removeObjectAtIndex:0], ^n @"Index 0 is out of bounds (must be less than 0).");

    [self addObjects];
    %r XCTAssertEqual($dictionary.count, 2U);
    %o XCTAssertEqual($dictionary.count, 3U);

    %r RLMAssertThrowsWithReason([$dictionary removeObjectAtIndex:2], ^n @"Index 2 is out of bounds (must be less than 2).");
    %o RLMAssertThrowsWithReason([$dictionary removeObjectAtIndex:3], ^n @"Index 3 is out of bounds (must be less than 3).");

    [$allDictionaries removeObjectAtIndex:0];
    %r XCTAssertEqual($dictionary.count, 1U);
    %o XCTAssertEqual($dictionary.count, 2U);

    XCTAssertEqualObjects($dictionary[0], $v1);
    %o XCTAssertEqualObjects($dictionary[1], NSNull.null);
}

- (void)testRemoveLastObject {
    XCTAssertNoThrow([$allDictionaries removeLastObject]);

    [self addObjects];
    %r XCTAssertEqual($dictionary.count, 2U);
    %o XCTAssertEqual($dictionary.count, 3U);

    [$allDictionaries removeLastObject];
    %r XCTAssertEqual($dictionary.count, 1U);
    %o XCTAssertEqual($dictionary.count, 2U);

    XCTAssertEqualObjects($dictionary[0], $v0);
    %o XCTAssertEqualObjects($dictionary[1], $v1);
}

- (void)testReplace {
    RLMAssertThrowsWithReason([$dictionary replaceObjectAtIndex:0 withObject:$v0], ^n @"Index 0 is out of bounds (must be less than 0).");

    [$dictionary addObject:$v0]; ^nl [$dictionary replaceObjectAtIndex:0 withObject:$v1]; ^nl XCTAssertEqualObjects($dictionary[0], $v1); ^nl

    %o [$dictionary replaceObjectAtIndex:0 withObject:NSNull.null]; ^nl XCTAssertEqualObjects($dictionary[0], NSNull.null);

    RLMAssertThrowsWithReason([$dictionary replaceObjectAtIndex:0 withObject:$wrong], ^n @"Invalid value '$wdesc' of type '$wtype' for expected type '$type'");
    %r RLMAssertThrowsWithReason([$dictionary replaceObjectAtIndex:0 withObject:NSNull.null], ^n @"Invalid value '<null>' of type 'NSNull' for expected type '$type'");
}

- (void)testMove {
    RLMAssertThrowsWithReason([$allDictionaries moveObjectAtIndex:0 toIndex:1], ^n @"Index 0 is out of bounds (must be less than 0).");
    RLMAssertThrowsWithReason([$allDictionaries moveObjectAtIndex:1 toIndex:0], ^n @"Index 1 is out of bounds (must be less than 0).");

    [$dictionary addObjects:@[$v0, $v1, $v0, $v1]];

    [$allDictionaries moveObjectAtIndex:2 toIndex:0];

    XCTAssertEqualObjects([$dictionary valueForKey:@"self"], ^n (@[$v0, $v0, $v1, $v1]));
}

- (void)testExchange {
    RLMAssertThrowsWithReason([$allDictionaries exchangeObjectAtIndex:0 withObjectAtIndex:1], ^n @"Index 0 is out of bounds (must be less than 0).");
    RLMAssertThrowsWithReason([$allDictionaries exchangeObjectAtIndex:1 withObjectAtIndex:0], ^n @"Index 1 is out of bounds (must be less than 0).");

    [$dictionary addObjects:@[$v0, $v1, $v0, $v1]];

    [$allDictionaries exchangeObjectAtIndex:2 withObjectAtIndex:1];

    XCTAssertEqualObjects([$dictionary valueForKey:@"self"], ^n (@[$v0, $v0, $v1, $v1]));
}

- (void)testIndexOfObject {
    XCTAssertEqual(NSNotFound, [$dictionary indexOfObject:$v0]);

    RLMAssertThrowsWithReason([$dictionary indexOfObject:$wrong], ^n @"Invalid value '$wdesc' of type '$wtype' for expected type '$type'");

    %r RLMAssertThrowsWithReason([$dictionary indexOfObject:NSNull.null], ^n @"Invalid value '<null>' of type 'NSNull' for expected type '$type'");
    %o XCTAssertEqual(NSNotFound, [$dictionary indexOfObject:NSNull.null]);

    [self addObjects];

    XCTAssertEqual(1U, [$dictionary indexOfObject:$v1]);
}

- (void)testIndexOfObjectSorted {
    %man %r [$dictionary addObjects:@[$v0, $v1, $v0, $v1]];
    %man %o [$dictionary addObjects:@[$v0, $v1, NSNull.null, $v1, $v0]];

    %man %r XCTAssertEqual(0U, [[$dictionary sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:$v1]);
    %man %r XCTAssertEqual(2U, [[$dictionary sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:$v0]);

    %man %o XCTAssertEqual(0U, [[$dictionary sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:$v1]);
    %man %o XCTAssertEqual(2U, [[$dictionary sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:$v0]);
    %man %o XCTAssertEqual(4U, [[$dictionary sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:NSNull.null]);
}

- (void)testIndexOfObjectDistinct {
    %man %r [$dictionary addObjects:@[$v0, $v0, $v1]];
    %man %o [$dictionary addObjects:@[$v0, $v0, NSNull.null, $v1, $v0]];

    %man %r XCTAssertEqual(0U, [[$dictionary distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:$v0]);
    %man %r XCTAssertEqual(1U, [[$dictionary distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:$v1]);

    %man %o XCTAssertEqual(0U, [[$dictionary distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:$v0]);
    %man %o XCTAssertEqual(2U, [[$dictionary distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:$v1]);
    %man %o XCTAssertEqual(1U, [[$dictionary distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:NSNull.null]);
}

- (void)testIndexOfObjectWhere {
    %man RLMAssertThrowsWithReason([$dictionary indexOfObjectWhere:@"TRUEPREDICATE"], @"implemented");
    %man RLMAssertThrowsWithReason([[$dictionary sortedResultsUsingKeyPath:@"self" ascending:NO] ^n  indexOfObjectWhere:@"TRUEPREDICATE"], @"implemented");

    %unman XCTAssertEqual(NSNotFound, [$dictionary indexOfObjectWhere:@"TRUEPREDICATE"]);

    [self addObjects];

    %unman XCTAssertEqual(0U, [$dictionary indexOfObjectWhere:@"TRUEPREDICATE"]);
    %unman XCTAssertEqual(NSNotFound, [$dictionary indexOfObjectWhere:@"FALSEPREDICATE"]);
}

- (void)testIndexOfObjectWithPredicate {
    %man RLMAssertThrowsWithReason([$dictionary indexOfObjectWithPredicate:[NSPredicate predicateWithValue:YES]], @"implemented");
    %man RLMAssertThrowsWithReason([[$dictionary sortedResultsUsingKeyPath:@"self" ascending:NO] ^n  indexOfObjectWithPredicate:[NSPredicate predicateWithValue:YES]], @"implemented");

    %unman XCTAssertEqual(NSNotFound, [$dictionary indexOfObjectWithPredicate:[NSPredicate predicateWithValue:YES]]);

    [self addObjects];

    %unman XCTAssertEqual(0U, [$dictionary indexOfObjectWithPredicate:[NSPredicate predicateWithValue:YES]]);
    %unman XCTAssertEqual(NSNotFound, [$dictionary indexOfObjectWithPredicate:[NSPredicate predicateWithValue:NO]]);
}

- (void)testSort {
    %unman RLMAssertThrowsWithReason([$dictionary sortedResultsUsingKeyPath:@"self" ascending:NO], ^n @"This method may only be called on RLMArray instances retrieved from an RLMRealm");
    %unman RLMAssertThrowsWithReason([$dictionary sortedResultsUsingDescriptors:@[]], ^n @"This method may only be called on RLMArray instances retrieved from an RLMRealm");
    %man RLMAssertThrowsWithReason([$dictionary sortedResultsUsingKeyPath:@"not self" ascending:NO], ^n @"can only be sorted on 'self'");

    %man %r [$dictionary addObjects:@[$v0, $v1, $v0]];
    %man %o [$dictionary addObjects:@[$v0, $v1, NSNull.null, $v1, $v0]];

    %man %r XCTAssertEqualObjects([[$dictionary sortedResultsUsingDescriptors:@[]] valueForKey:@"self"], ^n (@[$v0, $v1, $v0]));
    %man %o XCTAssertEqualObjects([[$dictionary sortedResultsUsingDescriptors:@[]] valueForKey:@"self"], ^n (@[$v0, $v1, NSNull.null, $v1, $v0]));

    %man %r XCTAssertEqualObjects([[$dictionary sortedResultsUsingKeyPath:@"self" ascending:NO] valueForKey:@"self"], ^n (@[$v1, $v0, $v0]));
    %man %o XCTAssertEqualObjects([[$dictionary sortedResultsUsingKeyPath:@"self" ascending:NO] valueForKey:@"self"], ^n (@[$v1, $v1, $v0, $v0, NSNull.null]));

    %man %r XCTAssertEqualObjects([[$dictionary sortedResultsUsingKeyPath:@"self" ascending:YES] valueForKey:@"self"], ^n (@[$v0, $v0, $v1]));
    %man %o XCTAssertEqualObjects([[$dictionary sortedResultsUsingKeyPath:@"self" ascending:YES] valueForKey:@"self"], ^n (@[NSNull.null, $v0, $v0, $v1, $v1]));
}

- (void)testFilter {
    %unman RLMAssertThrowsWithReason([$dictionary objectsWhere:@"TRUEPREDICATE"], ^n @"This method may only be called on RLMArray instances retrieved from an RLMRealm");
    %unman RLMAssertThrowsWithReason([$dictionary objectsWithPredicate:[NSPredicate predicateWithValue:YES]], ^n @"This method may only be called on RLMArray instances retrieved from an RLMRealm");

    %man RLMAssertThrowsWithReason([$dictionary objectsWhere:@"TRUEPREDICATE"], ^n @"implemented");
    %man RLMAssertThrowsWithReason([$dictionary objectsWithPredicate:[NSPredicate predicateWithValue:YES]], ^n @"implemented");

    %man RLMAssertThrowsWithReason([[$dictionary sortedResultsUsingKeyPath:@"self" ascending:NO] ^n  objectsWhere:@"TRUEPREDICATE"], @"implemented");
    %man RLMAssertThrowsWithReason([[$dictionary sortedResultsUsingKeyPath:@"self" ascending:NO] ^n  objectsWithPredicate:[NSPredicate predicateWithValue:YES]], @"implemented");
}

- (void)testNotifications {
    %unman RLMAssertThrowsWithReason([$dictionary addNotificationBlock:^(__unused id a, __unused id c, __unused id e) { }], ^n @"This method may only be called on RLMArray instances retrieved from an RLMRealm");
}

- (void)testMin {
    %nominmax %unman RLMAssertThrowsWithReason([$dictionary minOfProperty:@"self"], ^n @"minOfProperty: is not supported for $type array");
    %nominmax %man RLMAssertThrowsWithReason([$dictionary minOfProperty:@"self"], ^n @"minOfProperty: is not supported for $type array '$class.$prop'");

    %minmax XCTAssertNil([$dictionary minOfProperty:@"self"]);

    [self addObjects];

    %minmax XCTAssertEqualObjects([$dictionary minOfProperty:@"self"], $v0);
}

- (void)testMax {
    %nominmax %unman RLMAssertThrowsWithReason([$dictionary maxOfProperty:@"self"], ^n @"maxOfProperty: is not supported for $type array");
    %nominmax %man RLMAssertThrowsWithReason([$dictionary maxOfProperty:@"self"], ^n @"maxOfProperty: is not supported for $type array '$class.$prop'");

    %minmax XCTAssertNil([$dictionary maxOfProperty:@"self"]);

    [self addObjects];

    %minmax XCTAssertEqualObjects([$dictionary maxOfProperty:@"self"], $v1);
}

- (void)testSum {
    %nosum %unman RLMAssertThrowsWithReason([$dictionary sumOfProperty:@"self"], ^n @"sumOfProperty: is not supported for $type array");
    %nosum %man RLMAssertThrowsWithReason([$dictionary sumOfProperty:@"self"], ^n @"sumOfProperty: is not supported for $type array '$class.$prop'");

    %sum XCTAssertEqualObjects([$dictionary sumOfProperty:@"self"], @0);

    [self addObjects];

    %sum XCTAssertEqualWithAccuracy([$dictionary sumOfProperty:@"self"].doubleValue, sum($values), .001);
}

- (void)testAverage {
    %noavg %unman RLMAssertThrowsWithReason([$dictionary averageOfProperty:@"self"], ^n @"averageOfProperty: is not supported for $type array");
    %noavg %man RLMAssertThrowsWithReason([$dictionary averageOfProperty:@"self"], ^n @"averageOfProperty: is not supported for $type array '$class.$prop'");

    %avg XCTAssertNil([$dictionary averageOfProperty:@"self"]);

    [self addObjects];

    %avg XCTAssertEqualWithAccuracy([$dictionary averageOfProperty:@"self"].doubleValue, average($values), .001);
}

- (void)testFastEnumeration {
    for (int i = 0; i < 10; ++i) {
        [self addObjects];
    }

    { ^nl NSUInteger i = 0; ^nl NSArray *values = $values; ^nl for (id value in $dictionary) { ^nl XCTAssertEqualObjects(values[i++ % values.count], value); ^nl } ^nl XCTAssertEqual(i, $dictionary.count); ^nl } ^nl
}

- (void)testValueForKeySelf {
    XCTAssertEqualObjects([$allDictionaries valueForKey:@"self"], @[]);

    [self addObjects];

    XCTAssertEqualObjects([$dictionary valueForKey:@"self"], ($values));
}

- (void)testValueForKeyNumericAggregates {
    %minmax XCTAssertNil([$dictionary valueForKeyPath:@"@min.self"]);
    %minmax XCTAssertNil([$dictionary valueForKeyPath:@"@max.self"]);
    %sum XCTAssertEqualObjects([$dictionary valueForKeyPath:@"@sum.self"], @0);
    %avg XCTAssertNil([$dictionary valueForKeyPath:@"@avg.self"]);

    [self addObjects];

    %minmax XCTAssertEqualObjects([$dictionary valueForKeyPath:@"@min.self"], $v0);
    %minmax XCTAssertEqualObjects([$dictionary valueForKeyPath:@"@max.self"], $v1);
    %sum XCTAssertEqualWithAccuracy([[$dictionary valueForKeyPath:@"@sum.self"] doubleValue], sum($values), .001);
    %avg XCTAssertEqualWithAccuracy([[$dictionary valueForKeyPath:@"@avg.self"] doubleValue], average($values), .001);
}

- (void)testValueForKeyLength {
    XCTAssertEqualObjects([$allDictionaries valueForKey:@"length"], @[]);

    [self addObjects];

    %string XCTAssertEqualObjects([$dictionary valueForKey:@"length"], ([$values valueForKey:@"length"]));
}

// Sort the distinct results to match the order used in values, as it
// doesn't preserve the order naturally
static NSArray *sortedDistinctUnion(id array, NSString *type, NSString *prop) {
    return [[array valueForKeyPath:[NSString stringWithFormat:@"@distinctUnionOf%@.%@", type, prop]]
            sortedArrayUsingComparator:^NSComparisonResult(id a, id b) {
                bool aIsNull = a == NSNull.null;
                bool bIsNull = b == NSNull.null;
                if (aIsNull && bIsNull) {
                    return 0;
                }
                if (aIsNull) {
                    return 1;
                }
                if (bIsNull) {
                    return -1;
                }

                if ([a isKindOfClass:[NSData class]]) {
                    if ([a length] != [b length]) {
                        return [a length] < [b length] ? -1 : 1;
                    }
                    int result = memcmp([a bytes], [b bytes], [a length]);
                    if (!result) {
                        return 0;
                    }
                    return result < 0 ? -1 : 1;
                }

                if ([a isKindOfClass:[RLMObjectId class]]) {
                    int64_t idx1 = [objectIds indexOfObject:a];
                    int64_t idx2 = [objectIds indexOfObject:b];
                    return idx1 - idx2;
                }

                return [a compare:b];
            }];
}

- (void)testUnionOfObjects {
    XCTAssertEqualObjects([$allDictionaries valueForKeyPath:@"@unionOfObjects.self"], @[]);
    XCTAssertEqualObjects([$allDictionaries valueForKeyPath:@"@distinctUnionOfObjects.self"], @[]);

    [self addObjects];
    [self addObjects];

    XCTAssertEqualObjects([$dictionary valueForKeyPath:@"@unionOfObjects.self"], ^n ($values2));
    XCTAssertEqualObjects(sortedDistinctUnion($dictionary, @"Objects", @"self"), ^n ($values));
}

- (void)testUnionOfArrays {
    RLMResults *allRequired = [AllPrimitiveDictionaries allObjectsInRealm:realm];
    RLMResults *allOptional = [AllOptionalPrimitiveDictionaries allObjectsInRealm:realm];

    %man %r XCTAssertEqualObjects([allRequired valueForKeyPath:@"@unionOfArrays.$prop"], @[]);
    %man %o XCTAssertEqualObjects([allOptional valueForKeyPath:@"@unionOfArrays.$prop"], @[]);
    %man %r XCTAssertEqualObjects([allRequired valueForKeyPath:@"@distinctUnionOfArrays.$prop"], @[]);
    %man %o XCTAssertEqualObjects([allOptional valueForKeyPath:@"@distinctUnionOfArrays.$prop"], @[]);

    [self addObjects];

    [AllPrimitiveDictionaries createInRealm:realm withValue:managed];
    [AllOptionalPrimitiveDictionaries createInRealm:realm withValue:optManaged];

    %man %r XCTAssertEqualObjects([allRequired valueForKeyPath:@"@unionOfArrays.$prop"], ^n ($values2));
    %man %o XCTAssertEqualObjects([allOptional valueForKeyPath:@"@unionOfArrays.$prop"], ^n ($values2));
    %man %r XCTAssertEqualObjects(sortedDistinctUnion(allRequired, @"Arrays", @"$prop"), ^n ($values));
    %man %o XCTAssertEqualObjects(sortedDistinctUnion(allOptional, @"Arrays", @"$prop"), ^n ($values));
}

- (void)testSetValueForKey {
    RLMAssertThrowsWithReason([$allDictionaries setValue:@0 forKey:@"not self"], ^n @"this class is not key value coding-compliant for the key not self.");
    RLMAssertThrowsWithReason([$dictionary setValue:$wrong forKey:@"self"], ^n @"Invalid value '$wdesc' of type '$wtype' for expected type '$type'");
    %r RLMAssertThrowsWithReason([$dictionary setValue:NSNull.null forKey:@"self"], ^n @"Invalid value '<null>' of type 'NSNull' for expected type '$type'");

    [self addObjects];

    [$dictionary setValue:$v0 forKey:@"self"];

    XCTAssertEqualObjects($dictionary[0], $v0);
    XCTAssertEqualObjects($dictionary[1], $v0);
    %o XCTAssertEqualObjects($dictionary[2], $v0);

    %o [$dictionary setValue:NSNull.null forKey:@"self"];
    %o XCTAssertEqualObjects($dictionary[0], NSNull.null);
}

- (void)testAssignment {
    $dictionary = (id)@[$v1]; ^nl XCTAssertEqualObjects($dictionary[0], $v1);

    // Should replace and not append
    $dictionary = (id)$values; ^nl XCTAssertEqualObjects([$dictionary valueForKey:@"self"], ($values)); ^nl

    // Should not clear the array
    $dictionary = $dictionary; ^nl XCTAssertEqualObjects([$dictionary valueForKey:@"self"], ($values)); ^nl

    [unmanaged.intObj removeAllObjects];
    unmanaged.intObj = managed.intObj;
    XCTAssertEqualObjects([unmanaged.intObj valueForKey:@"self"], (@[@2, @3]));

    [managed.intObj removeAllObjects];
    managed.intObj = unmanaged.intObj;
    XCTAssertEqualObjects([managed.intObj valueForKey:@"self"], (@[@2, @3]));
}

- (void)testDynamicAssignment {
    $obj[@"$prop"] = (id)@[$v1]; ^nl XCTAssertEqualObjects($obj[@"$prop"][0], $v1);

    // Should replace and not append
    $obj[@"$prop"] = (id)$values; ^nl XCTAssertEqualObjects([$obj[@"$prop"] valueForKey:@"self"], ($values)); ^nl 

    // Should not clear the array
    $obj[@"$prop"] = $obj[@"$prop"]; ^nl XCTAssertEqualObjects([$obj[@"$prop"] valueForKey:@"self"], ($values)); ^nl 

    [unmanaged[@"intObj"] removeAllObjects];
    unmanaged[@"intObj"] = managed.intObj;
    XCTAssertEqualObjects([unmanaged[@"intObj"] valueForKey:@"self"], (@[@2, @3]));

    [managed[@"intObj"] removeAllObjects];
    managed[@"intObj"] = unmanaged.intObj;
    XCTAssertEqualObjects([managed[@"intObj"] valueForKey:@"self"], (@[@2, @3]));
}

- (void)testInvalidAssignment {
    RLMAssertThrowsWithReason(unmanaged.intObj = (id)@[NSNull.null],
                              @"Invalid value '<null>' of type 'NSNull' for 'int' array property 'AllPrimitiveDictionaries.intObj'.");
    RLMAssertThrowsWithReason(unmanaged.intObj = (id)@[@"a"],
                              @"Invalid value 'a' of type '__NSCFConstantString' for 'int' array property 'AllPrimitiveDictionaries.intObj'.");
    RLMAssertThrowsWithReason(unmanaged.intObj = (id)(@[@1, @"a"]),
                              @"Invalid value 'a' of type '__NSCFConstantString' for 'int' array property 'AllPrimitiveDictionaries.intObj'.");
    RLMAssertThrowsWithReason(unmanaged.intObj = (id)unmanaged.floatObj,
                              @"RLMArray<float> does not match expected type 'int' for property 'AllPrimitiveDictionaries.intObj'.");
    RLMAssertThrowsWithReason(unmanaged.intObj = (id)optUnmanaged.intObj,
                              @"RLMArray<int?> does not match expected type 'int' for property 'AllPrimitiveDictionaries.intObj'.");
    RLMAssertThrowsWithReason(unmanaged[@"intObj"] = unmanaged[@"floatObj"],
                              @"RLMArray<float> does not match expected type 'int' for property 'AllPrimitiveDictionaries.intObj'.");
    RLMAssertThrowsWithReason(unmanaged[@"intObj"] = optUnmanaged[@"intObj"],
                              @"RLMArray<int?> does not match expected type 'int' for property 'AllPrimitiveDictionaries.intObj'.");

    RLMAssertThrowsWithReason(managed.intObj = (id)@[NSNull.null],
                              @"Invalid value '<null>' of type 'NSNull' for 'int' array property 'AllPrimitiveDictionaries.intObj'.");
    RLMAssertThrowsWithReason(managed.intObj = (id)@[@"a"],
                              @"Invalid value 'a' of type '__NSCFConstantString' for 'int' array property 'AllPrimitiveDictionaries.intObj'.");
    RLMAssertThrowsWithReason(managed.intObj = (id)(@[@1, @"a"]),
                              @"Invalid value 'a' of type '__NSCFConstantString' for 'int' array property 'AllPrimitiveDictionaries.intObj'.");
    RLMAssertThrowsWithReason(managed.intObj = (id)managed.floatObj,
                              @"RLMArray<float> does not match expected type 'int' for property 'AllPrimitiveDictionaries.intObj'.");
    RLMAssertThrowsWithReason(managed.intObj = (id)optManaged.intObj,
                              @"RLMArray<int?> does not match expected type 'int' for property 'AllPrimitiveDictionaries.intObj'.");
    RLMAssertThrowsWithReason(managed[@"intObj"] = (id)managed[@"floatObj"],
                              @"RLMArray<float> does not match expected type 'int' for property 'AllPrimitiveDictionaries.intObj'.");
    RLMAssertThrowsWithReason(managed[@"intObj"] = (id)optManaged[@"intObj"],
                              @"RLMArray<int?> does not match expected type 'int' for property 'AllPrimitiveDictionaries.intObj'.");
}

- (void)testAllMethodsCheckThread {
    RLMArray *array = managed.intObj;
    [self dispatchAsyncAndWait:^{
        RLMAssertThrowsWithReason([array count], @"thread");
        RLMAssertThrowsWithReason([array objectAtIndex:0], @"thread");
        RLMAssertThrowsWithReason([array firstObject], @"thread");
        RLMAssertThrowsWithReason([array lastObject], @"thread");

        RLMAssertThrowsWithReason([array addObject:@0], @"thread");
        RLMAssertThrowsWithReason([array addObjects:@[@0]], @"thread");
        RLMAssertThrowsWithReason([array insertObject:@0 atIndex:0], @"thread");
        RLMAssertThrowsWithReason([array removeObjectAtIndex:0], @"thread");
        RLMAssertThrowsWithReason([array removeLastObject], @"thread");
        RLMAssertThrowsWithReason([array removeAllObjects], @"thread");
        RLMAssertThrowsWithReason([array replaceObjectAtIndex:0 withObject:@0], @"thread");
        RLMAssertThrowsWithReason([array moveObjectAtIndex:0 toIndex:1], @"thread");
        RLMAssertThrowsWithReason([array exchangeObjectAtIndex:0 withObjectAtIndex:1], @"thread");

        RLMAssertThrowsWithReason([array indexOfObject:@1], @"thread");
        /* RLMAssertThrowsWithReason([array indexOfObjectWhere:@"TRUEPREDICATE"], @"thread"); */
        /* RLMAssertThrowsWithReason([array indexOfObjectWithPredicate:[NSPredicate predicateWithValue:NO]], @"thread"); */
        /* RLMAssertThrowsWithReason([array objectsWhere:@"TRUEPREDICATE"], @"thread"); */
        /* RLMAssertThrowsWithReason([array objectsWithPredicate:[NSPredicate predicateWithValue:NO]], @"thread"); */
        RLMAssertThrowsWithReason([array sortedResultsUsingKeyPath:@"self" ascending:YES], @"thread");
        RLMAssertThrowsWithReason([array sortedResultsUsingDescriptors:@[[RLMSortDescriptor sortDescriptorWithKeyPath:@"self" ascending:YES]]], @"thread");
        RLMAssertThrowsWithReason(array[0], @"thread");
        RLMAssertThrowsWithReason(array[0] = @0, @"thread");
        RLMAssertThrowsWithReason([array valueForKey:@"self"], @"thread");
        RLMAssertThrowsWithReason([array setValue:@1 forKey:@"self"], @"thread");
        RLMAssertThrowsWithReason({for (__unused id obj in array);}, @"thread");
    }];
}

- (void)testAllMethodsCheckForInvalidation {
    RLMArray *array = managed.intObj;
    [realm cancelWriteTransaction];
    [realm invalidate];

    XCTAssertNoThrow([array objectClassName]);
    XCTAssertNoThrow([array realm]);
    XCTAssertNoThrow([array isInvalidated]);

    RLMAssertThrowsWithReason([array count], @"invalidated");
    RLMAssertThrowsWithReason([array objectAtIndex:0], @"invalidated");
    RLMAssertThrowsWithReason([array firstObject], @"invalidated");
    RLMAssertThrowsWithReason([array lastObject], @"invalidated");

    RLMAssertThrowsWithReason([array addObject:@0], @"invalidated");
    RLMAssertThrowsWithReason([array addObjects:@[@0]], @"invalidated");
    RLMAssertThrowsWithReason([array insertObject:@0 atIndex:0], @"invalidated");
    RLMAssertThrowsWithReason([array removeObjectAtIndex:0], @"invalidated");
    RLMAssertThrowsWithReason([array removeLastObject], @"invalidated");
    RLMAssertThrowsWithReason([array removeAllObjects], @"invalidated");
    RLMAssertThrowsWithReason([array replaceObjectAtIndex:0 withObject:@0], @"invalidated");
    RLMAssertThrowsWithReason([array moveObjectAtIndex:0 toIndex:1], @"invalidated");
    RLMAssertThrowsWithReason([array exchangeObjectAtIndex:0 withObjectAtIndex:1], @"invalidated");

    RLMAssertThrowsWithReason([array indexOfObject:@1], @"invalidated");
    /* RLMAssertThrowsWithReason([array indexOfObjectWhere:@"TRUEPREDICATE"], @"invalidated"); */
    /* RLMAssertThrowsWithReason([array indexOfObjectWithPredicate:[NSPredicate predicateWithValue:YES]], @"invalidated"); */
    /* RLMAssertThrowsWithReason([array objectsWhere:@"TRUEPREDICATE"], @"invalidated"); */
    /* RLMAssertThrowsWithReason([array objectsWithPredicate:[NSPredicate predicateWithValue:YES]], @"invalidated"); */
    RLMAssertThrowsWithReason([array sortedResultsUsingKeyPath:@"self" ascending:YES], @"invalidated");
    RLMAssertThrowsWithReason([array sortedResultsUsingDescriptors:@[[RLMSortDescriptor sortDescriptorWithKeyPath:@"self" ascending:YES]]], @"invalidated");
    RLMAssertThrowsWithReason(array[0], @"invalidated");
    RLMAssertThrowsWithReason(array[0] = @0, @"invalidated");
    RLMAssertThrowsWithReason([array valueForKey:@"self"], @"invalidated");
    RLMAssertThrowsWithReason([array setValue:@1 forKey:@"self"], @"invalidated");
    RLMAssertThrowsWithReason({for (__unused id obj in array);}, @"invalidated");

    [realm beginWriteTransaction];
}

- (void)testMutatingMethodsCheckForWriteTransaction {
    RLMArray *array = managed.intObj;
    [array addObject:@0];
    [realm commitWriteTransaction];

    XCTAssertNoThrow([array objectClassName]);
    XCTAssertNoThrow([array realm]);
    XCTAssertNoThrow([array isInvalidated]);

    XCTAssertNoThrow([array count]);
    XCTAssertNoThrow([array objectAtIndex:0]);
    XCTAssertNoThrow([array firstObject]);
    XCTAssertNoThrow([array lastObject]);

    XCTAssertNoThrow([array indexOfObject:@1]);
    /* XCTAssertNoThrow([array indexOfObjectWhere:@"TRUEPREDICATE"]); */
    /* XCTAssertNoThrow([array indexOfObjectWithPredicate:[NSPredicate predicateWithValue:YES]]); */
    /* XCTAssertNoThrow([array objectsWhere:@"TRUEPREDICATE"]); */
    /* XCTAssertNoThrow([array objectsWithPredicate:[NSPredicate predicateWithValue:YES]]); */
    XCTAssertNoThrow([array sortedResultsUsingKeyPath:@"self" ascending:YES]);
    XCTAssertNoThrow([array sortedResultsUsingDescriptors:@[[RLMSortDescriptor sortDescriptorWithKeyPath:@"self" ascending:YES]]]);
    XCTAssertNoThrow(array[0]);
    XCTAssertNoThrow([array valueForKey:@"self"]);
    XCTAssertNoThrow({for (__unused id obj in array);});


    RLMAssertThrowsWithReason([array addObject:@0], @"write transaction");
    RLMAssertThrowsWithReason([array addObjects:@[@0]], @"write transaction");
    RLMAssertThrowsWithReason([array insertObject:@0 atIndex:0], @"write transaction");
    RLMAssertThrowsWithReason([array removeObjectAtIndex:0], @"write transaction");
    RLMAssertThrowsWithReason([array removeLastObject], @"write transaction");
    RLMAssertThrowsWithReason([array removeAllObjects], @"write transaction");
    RLMAssertThrowsWithReason([array replaceObjectAtIndex:0 withObject:@0], @"write transaction");
    RLMAssertThrowsWithReason([array moveObjectAtIndex:0 toIndex:1], @"write transaction");
    RLMAssertThrowsWithReason([array exchangeObjectAtIndex:0 withObjectAtIndex:1], @"write transaction");

    RLMAssertThrowsWithReason(array[0] = @0, @"write transaction");
    RLMAssertThrowsWithReason([array setValue:@1 forKey:@"self"], @"write transaction");
}

- (void)testDeleteOwningObject {
    RLMArray *array = managed.intObj;
    XCTAssertFalse(array.isInvalidated);
    [realm deleteObject:managed];
    XCTAssertTrue(array.isInvalidated);
}

#pragma clang diagnostic ignored "-Warc-retain-cycles"

- (void)testNotificationSentInitially {
    [realm commitWriteTransaction];

    id expectation = [self expectationWithDescription:@""];
    id token = [managed.intObj addNotificationBlock:^(RLMArray *array, RLMCollectionChange *change, NSError *error) {
        XCTAssertNotNil(array);
        XCTAssertNil(change);
        XCTAssertNil(error);
        [expectation fulfill];
    }];

    [self waitForExpectationsWithTimeout:2.0 handler:nil];
    [(RLMNotificationToken *)token invalidate];
}

- (void)testNotificationSentAfterCommit {
    [realm commitWriteTransaction];

    __block bool first = true;
    __block id expectation = [self expectationWithDescription:@""];
    id token = [managed.intObj addNotificationBlock:^(RLMArray *array, RLMCollectionChange *change, NSError *error) {
        XCTAssertNotNil(array);
        XCTAssertNil(error);
        if (first) {
            XCTAssertNil(change);
        }
        else {
            XCTAssertEqualObjects(change.insertions, @[@0]);
        }

        first = false;
        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:2.0 handler:nil];

    expectation = [self expectationWithDescription:@""];
    [self dispatchAsyncAndWait:^{
        RLMRealm *r = [RLMRealm defaultRealm];
        [r transactionWithBlock:^{
            RLMArray *array = [(AllPrimitiveDictionaries *)[AllPrimitiveDictionaries allObjectsInRealm:r].firstObject intObj];
            [array addObject:@0];
        }];
    }];
    [self waitForExpectationsWithTimeout:2.0 handler:nil];

    [(RLMNotificationToken *)token invalidate];
}

- (void)testNotificationNotSentForUnrelatedChange {
    [realm commitWriteTransaction];

    id expectation = [self expectationWithDescription:@""];
    id token = [managed.intObj addNotificationBlock:^(__unused RLMArray *array, __unused RLMCollectionChange *change, __unused NSError *error) {
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
                [AllPrimitiveDictionaries createInRealm:r withValue:@[]];
            }];
        }];
    }];
    [(RLMNotificationToken *)token invalidate];
}

- (void)testNotificationSentOnlyForActualRefresh {
    [realm commitWriteTransaction];

    __block id expectation = [self expectationWithDescription:@""];
    id token = [managed.intObj addNotificationBlock:^(RLMArray *array, __unused RLMCollectionChange *change, NSError *error) {
        XCTAssertNotNil(array);
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
            RLMRealm *r = [RLMRealm defaultRealm];
            [r transactionWithBlock:^{
                RLMArray *array = [(AllPrimitiveDictionaries *)[AllPrimitiveDictionaries allObjectsInRealm:r].firstObject intObj];
                [array addObject:@0];
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
    id token = [managed.intObj addNotificationBlock:^(RLMArray *array, RLMCollectionChange *change, NSError *error) {
        XCTAssertNotNil(array);
        XCTAssertNil(error);
        if (first) {
            XCTAssertNil(change);
            first = false;
        }
        else {
            XCTAssertEqualObjects(change.deletions, (@[@0, @1]));
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

#pragma mark - Queries

#define RLMAssertCount(cls, expectedCount, ...) \
    XCTAssertEqual(expectedCount, ([cls objectsInRealm:realm where:__VA_ARGS__].count))

- (void)createObjectWithValueIndex:(NSUInteger)index {
    NSRange range = {index, 1};
    id obj = [AllPrimitiveDictionaries createInRealm:realm withValue:@{
        %r %man @"$prop": [$values subarrayWithRange:range],
    }];
    [LinkToAllPrimitiveDictionaries createInRealm:realm withValue:@[obj]];
    obj = [AllOptionalPrimitiveDictionaries createInRealm:realm withValue:@{
        %o %man @"$prop": [$values subarrayWithRange:range],
    }];
    [LinkToAllOptionalPrimitiveDictionaries createInRealm:realm withValue:@[obj]];
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
    %man %minmax RLMAssertCount($class, 1, @"ANY $prop < %@", $v1);
    %man %minmax RLMAssertCount($class, 1, @"ANY $prop <= %@", $v0);

    [self createObjectWithValueIndex:1];

    %man RLMAssertCount($class, 1, @"ANY $prop = %@", $v0);
    %man RLMAssertCount($class, 1, @"ANY $prop = %@", $v1);
    %man RLMAssertCount($class, 1, @"ANY $prop != %@", $v0);
    %man RLMAssertCount($class, 1, @"ANY $prop != %@", $v1);
    %man %minmax RLMAssertCount($class, 1, @"ANY $prop > %@", $v0);
    %man %minmax RLMAssertCount($class, 2, @"ANY $prop >= %@", $v0);
    %man %minmax RLMAssertCount($class, 0, @"ANY $prop < %@", $v0);
    %man %minmax RLMAssertCount($class, 1, @"ANY $prop < %@", $v1);
    %man %minmax RLMAssertCount($class, 1, @"ANY $prop <= %@", $v0);
    %man %minmax RLMAssertCount($class, 2, @"ANY $prop <= %@", $v1);

    %man %nominmax RLMAssertThrowsWithReason(([$class objectsInRealm:realm where:@"ANY $prop > %@", $v0]), ^n @"Operator '>' not supported for type '$basetype'");
}

- (void)testQueryBetween {
    [realm deleteAllObjects];

    %man %nominmax RLMAssertThrowsWithReason(([$class objectsInRealm:realm where:@"ANY $prop BETWEEN %@", @[$v0, $v1]]), ^n @"Operator 'BETWEEN' not supported for type '$basetype'");

    %man %minmax RLMAssertCount($class, 0, @"ANY $prop BETWEEN %@", @[$v0, $v1]);

    [self createObjectWithValueIndex:0];

    %man %minmax RLMAssertCount($class, 1, @"ANY $prop BETWEEN %@", @[$v0, $v0]);
    %man %minmax RLMAssertCount($class, 1, @"ANY $prop BETWEEN %@", @[$v0, $v1]);
    %man %minmax RLMAssertCount($class, 0, @"ANY $prop BETWEEN %@", @[$v1, $v1]);
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

    [AllPrimitiveDictionaries createInRealm:realm withValue:@{
        %r %man @"$prop": @[],
    }];
    [AllOptionalPrimitiveDictionaries createInRealm:realm withValue:@{
        %o %man @"$prop": @[],
    }];
    [AllPrimitiveDictionaries createInRealm:realm withValue:@{
        %r %man @"$prop": @[$v0],
    }];
    [AllOptionalPrimitiveDictionaries createInRealm:realm withValue:@{
        %o %man @"$prop": @[$v0],
    }];
    [AllPrimitiveDictionaries createInRealm:realm withValue:@{
        %r %man @"$prop": @[$v0, $v0],
    }];
    [AllOptionalPrimitiveDictionaries createInRealm:realm withValue:@{
        %o %man @"$prop": @[$v0, $v0],
    }];

    for (unsigned int i = 0; i < 3; ++i) {
        %man RLMAssertCount($class, 1U, @"$prop.@count == %@", @(i));
        %man RLMAssertCount($class, 2U, @"$prop.@count != %@", @(i));
        %man RLMAssertCount($class, 2 - i, @"$prop.@count > %@", @(i));
        %man RLMAssertCount($class, 3 - i, @"$prop.@count >= %@", @(i));
        %man RLMAssertCount($class, i, @"$prop.@count < %@", @(i));
        %man RLMAssertCount($class, i + 1, @"$prop.@count <= %@", @(i));
    }
}

- (void)testQuerySum {
    [realm deleteAllObjects];

    %nodate %nosum %man RLMAssertThrowsWithReason(([$class objectsInRealm:realm where:@"$prop.@sum = %@", $v0]), ^n @"@sum can only be applied to a numeric property.");
    %date %man RLMAssertThrowsWithReason(([$class objectsInRealm:realm where:@"$prop.@sum = %@", $v0]), ^n @"Cannot sum or average date properties");

    %sum %man RLMAssertThrowsWithReason(([$class objectsInRealm:realm where:@"$prop.@sum = %@", $wrong]), ^n @"@sum on a property of type $basetype cannot be compared with '$wdesc'");
    %sum %man RLMAssertThrowsWithReason(([$class objectsInRealm:realm where:@"$prop.@sum.prop = %@", $wrong]), ^n @"Property '$prop' is not a link in object of type '$class'");
    %sum %man RLMAssertThrowsWithReason(([$class objectsInRealm:realm where:@"$prop.@sum = %@", NSNull.null]), ^n @"@sum on a property of type $basetype cannot be compared with '<null>'");

    [AllPrimitiveDictionaries createInRealm:realm withValue:@{
        %man %r %sum @"$prop": @[],
    }];
    [AllOptionalPrimitiveDictionaries createInRealm:realm withValue:@{
        %man %o %sum @"$prop": @[],
    }];
    [AllPrimitiveDictionaries createInRealm:realm withValue:@{
        %man %r %sum @"$prop": @[$v0],
    }];
    [AllOptionalPrimitiveDictionaries createInRealm:realm withValue:@{
        %man %o %sum @"$prop": @[$v0],
    }];
    [AllPrimitiveDictionaries createInRealm:realm withValue:@{
        %man %r %sum @"$prop": @[$v0, $v0],
    }];
    [AllOptionalPrimitiveDictionaries createInRealm:realm withValue:@{
        %man %o %sum @"$prop": @[$v0, $v0],
    }];
    [AllPrimitiveDictionaries createInRealm:realm withValue:@{
        %man %r %sum @"$prop": @[$v0, $v0, $v0],
    }];
    [AllOptionalPrimitiveDictionaries createInRealm:realm withValue:@{
        %man %o %sum @"$prop": @[$v0, $v0, $v0],
    }];

    %sum %man RLMAssertCount($class, 1U, @"$prop.@sum == %@", @0);
    %sum %man RLMAssertCount($class, 1U, @"$prop.@sum == %@", $v0);
    %sum %man RLMAssertCount($class, 3U, @"$prop.@sum != %@", $v0);
    %sum %man RLMAssertCount($class, 3U, @"$prop.@sum >= %@", $v0);
    %sum %man RLMAssertCount($class, 2U, @"$prop.@sum > %@", $v0);
    %sum %man RLMAssertCount($class, 2U, @"$prop.@sum < %@", $v1);
    %sum %man RLMAssertCount($class, 2U, @"$prop.@sum <= %@", $v1);
}

- (void)testQueryAverage {
    [realm deleteAllObjects];

    %nodate %noavg %man RLMAssertThrowsWithReason(([$class objectsInRealm:realm where:@"$prop.@avg = %@", $v0]), ^n @"@avg can only be applied to a numeric property.");
    %date %man RLMAssertThrowsWithReason(([$class objectsInRealm:realm where:@"$prop.@avg = %@", $v0]), ^n @"Cannot sum or average date properties");

    %avg %man RLMAssertThrowsWithReason(([$class objectsInRealm:realm where:@"$prop.@avg = %@", $wrong]), ^n @"@avg on a property of type $basetype cannot be compared with '$wdesc'");
    %avg %man RLMAssertThrowsWithReason(([$class objectsInRealm:realm where:@"$prop.@avg.prop = %@", $wrong]), ^n @"Property '$prop' is not a link in object of type '$class'");

    [AllPrimitiveDictionaries createInRealm:realm withValue:@{
        %man %r %avg @"$prop": @[],
    }];
    [AllOptionalPrimitiveDictionaries createInRealm:realm withValue:@{
        %man %o %avg @"$prop": @[],
    }];
    [AllPrimitiveDictionaries createInRealm:realm withValue:@{
        %man %r %avg @"$prop": @[$v0],
    }];
    [AllOptionalPrimitiveDictionaries createInRealm:realm withValue:@{
        %man %o %avg @"$prop": @[$v0],
    }];
    [AllPrimitiveDictionaries createInRealm:realm withValue:@{
        %man %r %avg @"$prop": @[$v0, $v1],
    }];
    [AllOptionalPrimitiveDictionaries createInRealm:realm withValue:@{
        %man %o %avg @"$prop": @[$v0, $v1],
    }];
    [AllPrimitiveDictionaries createInRealm:realm withValue:@{
        %man %r %avg @"$prop": @[$v1],
    }];
    [AllOptionalPrimitiveDictionaries createInRealm:realm withValue:@{
        %man %o %avg @"$prop": @[$v1],
    }];

    %avg %man RLMAssertCount($class, 1U, @"$prop.@avg == %@", NSNull.null);
    %avg %man RLMAssertCount($class, 1U, @"$prop.@avg == %@", $v0);
    %avg %man RLMAssertCount($class, 3U, @"$prop.@avg != %@", $v0);
    %avg %man RLMAssertCount($class, 3U, @"$prop.@avg >= %@", $v0);
    %avg %man RLMAssertCount($class, 2U, @"$prop.@avg > %@", $v0);
    %avg %man RLMAssertCount($class, 2U, @"$prop.@avg < %@", $v1);
    %avg %man RLMAssertCount($class, 3U, @"$prop.@avg <= %@", $v1);
}

- (void)testQueryMin {
    [realm deleteAllObjects];

    %nominmax %man RLMAssertThrowsWithReason(([$class objectsInRealm:realm where:@"$prop.@min = %@", $v0]), ^n @"@min can only be applied to a numeric property.");
    %minmax %man RLMAssertThrowsWithReason(([$class objectsInRealm:realm where:@"$prop.@min = %@", $wrong]), ^n @"@min on a property of type $basetype cannot be compared with '$wdesc'");
    %minmax %man RLMAssertThrowsWithReason(([$class objectsInRealm:realm where:@"$prop.@min.prop = %@", $wrong]), ^n @"Property '$prop' is not a link in object of type '$class'");

    // No objects, so count is zero
    %minmax %man RLMAssertCount($class, 0U, @"$prop.@min == %@", $v0);

    [AllPrimitiveDictionaries createInRealm:realm withValue:@{}];
    [AllOptionalPrimitiveDictionaries createInRealm:realm withValue:@{}];

    // Only empty arrays, so count is zero
    %minmax %man RLMAssertCount($class, 0U, @"$prop.@min == %@", $v0);
    %minmax %man RLMAssertCount($class, 0U, @"$prop.@min == %@", $v1);

    %minmax %man RLMAssertCount($class, 1U, @"$prop.@min == nil");
    %minmax %man RLMAssertCount($class, 1U, @"$prop.@min == %@", NSNull.null);

    [self createObjectWithValueIndex:0];

    // One object where v0 is min and zero with v1
    %minmax %man RLMAssertCount($class, 1U, @"$prop.@min == %@", $v0);
    %minmax %man RLMAssertCount($class, 0U, @"$prop.@min == %@", $v1);

    [self createObjectWithValueIndex:1];

    // One object where v0 is min and one with v1
    %minmax %man RLMAssertCount($class, 1U, @"$prop.@min == %@", $v0);
    %minmax %man RLMAssertCount($class, 1U, @"$prop.@min == %@", $v1);

    [AllPrimitiveDictionaries createInRealm:realm withValue:@{
        %minmax %r %man @"$prop": @[$v1, $v0],
    }];
    [AllOptionalPrimitiveDictionaries createInRealm:realm withValue:@{
        %minmax %o %man @"$prop": @[$v1, $v0],
    }];

    // New object with both v0 and v1 matches v0 but not v1
    %minmax %man RLMAssertCount($class, 2U, @"$prop.@min == %@", $v0);
    %minmax %man RLMAssertCount($class, 1U, @"$prop.@min == %@", $v1);
}

- (void)testQueryMax {
    [realm deleteAllObjects];

    %nominmax %man RLMAssertThrowsWithReason(([$class objectsInRealm:realm where:@"$prop.@max = %@", $v0]), ^n @"@max can only be applied to a numeric property.");
    %minmax %man RLMAssertThrowsWithReason(([$class objectsInRealm:realm where:@"$prop.@max = %@", $wrong]), ^n @"@max on a property of type $basetype cannot be compared with '$wdesc'");
    %minmax %man RLMAssertThrowsWithReason(([$class objectsInRealm:realm where:@"$prop.@max.prop = %@", $wrong]), ^n @"Property '$prop' is not a link in object of type '$class'");

    // No objects, so count is zero
    %minmax %man RLMAssertCount($class, 0U, @"$prop.@max == %@", $v0);

    [AllPrimitiveDictionaries createInRealm:realm withValue:@{}];
    [AllOptionalPrimitiveDictionaries createInRealm:realm withValue:@{}];

    // Only empty arrays, so count is zero
    %minmax %man RLMAssertCount($class, 0U, @"$prop.@max == %@", $v0);
    %minmax %man RLMAssertCount($class, 0U, @"$prop.@max == %@", $v1);

    %minmax %man RLMAssertCount($class, 1U, @"$prop.@max == nil");
    %minmax %man RLMAssertCount($class, 1U, @"$prop.@max == %@", NSNull.null);

    [self createObjectWithValueIndex:0];

    // One object where v0 is min and zero with v1
    %minmax %man RLMAssertCount($class, 1U, @"$prop.@max == %@", $v0);
    %minmax %man RLMAssertCount($class, 0U, @"$prop.@max == %@", $v1);

    [self createObjectWithValueIndex:1];

    // One object where v0 is min and one with v1
    %minmax %man RLMAssertCount($class, 1U, @"$prop.@max == %@", $v0);
    %minmax %man RLMAssertCount($class, 1U, @"$prop.@max == %@", $v1);

    [AllPrimitiveDictionaries createInRealm:realm withValue:@{
        %minmax %r %man @"$prop": @[$v1, $v0],
    }];
    [AllOptionalPrimitiveDictionaries createInRealm:realm withValue:@{
        %minmax %o %man @"$prop": @[$v1, $v0],
    }];

    // New object with both v0 and v1 matches v1 but not v0
    %minmax %man RLMAssertCount($class, 1U, @"$prop.@max == %@", $v0);
    %minmax %man RLMAssertCount($class, 2U, @"$prop.@max == %@", $v1);
}

- (void)testQueryBasicOperatorsOverLink {
    [realm deleteAllObjects];

    %man RLMAssertCount(LinkTo$class, 0, @"ANY link.$prop = %@", $v0);
    %man RLMAssertCount(LinkTo$class, 0, @"ANY link.$prop != %@", $v0);
    %man %minmax RLMAssertCount(LinkTo$class, 0, @"ANY link.$prop > %@", $v0);
    %man %minmax RLMAssertCount(LinkTo$class, 0, @"ANY link.$prop >= %@", $v0);
    %man %minmax RLMAssertCount(LinkTo$class, 0, @"ANY link.$prop < %@", $v0);
    %man %minmax RLMAssertCount(LinkTo$class, 0, @"ANY link.$prop <= %@", $v0);

    [self createObjectWithValueIndex:0];

    %man RLMAssertCount(LinkTo$class, 0, @"ANY link.$prop = %@", $v1);
    %man RLMAssertCount(LinkTo$class, 1, @"ANY link.$prop = %@", $v0);
    %man RLMAssertCount(LinkTo$class, 0, @"ANY link.$prop != %@", $v0);
    %man RLMAssertCount(LinkTo$class, 1, @"ANY link.$prop != %@", $v1);
    %man %minmax RLMAssertCount(LinkTo$class, 0, @"ANY link.$prop > %@", $v0);
    %man %minmax RLMAssertCount(LinkTo$class, 1, @"ANY link.$prop >= %@", $v0);
    %man %minmax RLMAssertCount(LinkTo$class, 0, @"ANY link.$prop < %@", $v0);
    %man %minmax RLMAssertCount(LinkTo$class, 1, @"ANY link.$prop < %@", $v1);
    %man %minmax RLMAssertCount(LinkTo$class, 1, @"ANY link.$prop <= %@", $v0);

    [self createObjectWithValueIndex:1];

    %man RLMAssertCount(LinkTo$class, 1, @"ANY link.$prop = %@", $v0);
    %man RLMAssertCount(LinkTo$class, 1, @"ANY link.$prop = %@", $v1);
    %man RLMAssertCount(LinkTo$class, 1, @"ANY link.$prop != %@", $v0);
    %man RLMAssertCount(LinkTo$class, 1, @"ANY link.$prop != %@", $v1);
    %man %minmax RLMAssertCount(LinkTo$class, 1, @"ANY link.$prop > %@", $v0);
    %man %minmax RLMAssertCount(LinkTo$class, 2, @"ANY link.$prop >= %@", $v0);
    %man %minmax RLMAssertCount(LinkTo$class, 0, @"ANY link.$prop < %@", $v0);
    %man %minmax RLMAssertCount(LinkTo$class, 1, @"ANY link.$prop < %@", $v1);
    %man %minmax RLMAssertCount(LinkTo$class, 1, @"ANY link.$prop <= %@", $v0);
    %man %minmax RLMAssertCount(LinkTo$class, 2, @"ANY link.$prop <= %@", $v1);

    %man %nominmax RLMAssertThrowsWithReason(([LinkTo$class objectsInRealm:realm where:@"ANY link.$prop > %@", $v0]), ^n @"Operator '>' not supported for type '$basetype'");
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
        id obj = [AllPrimitiveDictionaries createInRealm:realm withValue:@{
            @"stringObj": @[value],
            @"dataObj": @[[value dataUsingEncoding:NSUTF8StringEncoding]]
        }];
        [LinkToAllPrimitiveDictionaries createInRealm:realm withValue:@[obj]];
        obj = [AllOptionalPrimitiveDictionaries createInRealm:realm withValue:@{
            @"stringObj": @[value],
            @"dataObj": @[[value dataUsingEncoding:NSUTF8StringEncoding]]
        }];
        [LinkToAllOptionalPrimitiveDictionaries createInRealm:realm withValue:@[obj]];
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
        RLMAssertThrowsWithReason([AllPrimitiveDictionaries objectsInRealm:realm where:query],
                                  @"Expected object of type string for property 'stringObj' on object of type 'AllPrimitiveDictionaries', but received: (null)");
        RLMAssertCount(AllOptionalPrimitiveDictionaries, count, query, NSNull.null);
        query = [NSString stringWithFormat:@"ANY link.stringObj %@ nil", operator];
        RLMAssertThrowsWithReason([LinkToAllPrimitiveDictionaries objectsInRealm:realm where:query],
                                  @"Expected object of type string for property 'link.stringObj' on object of type 'LinkToAllPrimitiveDictionaries', but received: (null)");
        RLMAssertCount(LinkToAllOptionalPrimitiveDictionaries, count, query, NSNull.null);

        query = [NSString stringWithFormat:@"ANY dataObj %@ nil", operator];
        RLMAssertThrowsWithReason([AllPrimitiveDictionaries objectsInRealm:realm where:query],
                                  @"Expected object of type data for property 'dataObj' on object of type 'AllPrimitiveDictionaries', but received: (null)");
        RLMAssertCount(AllOptionalPrimitiveDictionaries, count, query, NSNull.null);

        query = [NSString stringWithFormat:@"ANY link.dataObj %@ nil", operator];
        RLMAssertThrowsWithReason([LinkToAllPrimitiveDictionaries objectsInRealm:realm where:query],
                                  @"Expected object of type data for property 'link.dataObj' on object of type 'LinkToAllPrimitiveDictionaries', but received: (null)");
        RLMAssertCount(LinkToAllOptionalPrimitiveDictionaries, count, query, NSNull.null);
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

@end
