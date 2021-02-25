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

@interface PrimitiveDictionaryPropertyTests : RLMTestCase
@end

@implementation PrimitiveDictionaryPropertyTests {
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
    [$dictionary addObjects:$values];
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
    RLMAssertThrowsWithReason([realm deleteObjects:$allDictionaries], @"Cannot delete objects from RLMDictionary");
}

- (void)testObjectAtIndex {
    RLMAssertThrowsWithReason([unmanaged.intObj objectAtIndex:0],
                              @"Index 0 is out of bounds (must be less than 0).");
    unmanaged.intObj[@"testVal"] = @1;
    XCTAssertEqualObjects([unmanaged.intObj objectAtIndex:0], @1);
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

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wnonnull"

- (void)testSetObject {
    // Fail with nil key on unmanaged
    %unman RLMAssertThrowsWithReason([$dictionary setObject:$first forKey:nil], ^n @"Invalid nil key for dictionary expecting key of type 'string'.");
    // Fail with nil key on managed
    %man RLMAssertThrowsWithReason([$dictionary setObject:$first forKey:nil], ^n @"Unsupported key type (null) in key array");
    // c
    %r RLMAssertThrowsWithReason([$dictionary setObject:NSNull.null forKey: @"testVal"], ^n @"Invalid value '<null>' of type 'NSNull' for expected type '$type'");
    // d
    %unman RLMAssertThrowsWithReason([$dictionary setObject:$first forKey:(id)$first], ^n @"Invalid key '$cVal' of type '$cType' for expected type 'string'");
    // e
    %man RLMAssertThrowsWithReason([$dictionary setObject:$first forKey:(id)$first], ^n @"Invalid key '$cVal' of type '$cType' for expected type 'string'");
    // f
    RLMAssertThrowsWithReason([$dictionary setObject:$wrong forKey: @"wrongVal"], ^n @"Invalid value '$wdesc' of type '$wtype' for expected type '$type'");
    %r RLMAssertThrowsWithReason([$dictionary setObject:NSNull.null forKey: @"nullVal"], ^n @"Invalid value '<null>' of type 'NSNull' for expected type '$type'");

    $dictionary[@"val"] = $v0;
    XCTAssertEqualObjects($dictionary[@"val"], $v0);

    %o $dictionary[@"val"] = NSNull.null;
    %o XCTAssertEqualObjects($dictionary[@"val"], NSNull.null);
}
#pragma clang diagnostic pop

- (void)testAddObjects {
    RLMAssertThrowsWithReason([$dictionary addObjects:@{@"wrongVal": $wrong}], ^n @"Invalid value '$wdesc' of type '$wtype' for expected type '$type'");
    %r RLMAssertThrowsWithReason([$dictionary addObjects:@{@"nullVal": NSNull.null}], ^n @"Invalid value '<null>' of type 'NSNull' for expected type '$type'");

    [self addObjects];
    XCTAssertEqualObjects($dictionary[@"0"], $v0);
    XCTAssertEqualObjects($dictionary[@"1"], $v1);
    %o XCTAssertEqualObjects($dictionary[@"2"], NSNull.null);
}
/**
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
 */
- (void)testRemoveObject {
    [self addObjects];
    %r XCTAssertEqual($dictionary.count, 2U);
    %o XCTAssertEqual($dictionary.count, 3U);

    [$allDictionaries removeObjectForKey:@"0"];
    %r XCTAssertEqual($dictionary.count, 1U);
    %o XCTAssertEqual($dictionary.count, 2U);

    XCTAssertEqualObjects($dictionary[0], $v1);
    %o XCTAssertEqualObjects($dictionary[1], NSNull.null);
}

- (void)testRemoveObjects {
    [self addObjects];
    %r XCTAssertEqual($dictionary.count, 2U);
    %o XCTAssertEqual($dictionary.count, 3U);

    [$allDictionaries removeObjectsForKeys:@[@"0"]];
    %r XCTAssertEqual($dictionary.count, 1U);
    %o XCTAssertEqual($dictionary.count, 2U);

    XCTAssertEqualObjects($dictionary[0], $v1);
    %o XCTAssertEqualObjects($dictionary[1], NSNull.null);
}

- (void)testUpdateObjects {
    [self addObjects];
    %r XCTAssertEqual($dictionary.count, 2U);
    %o XCTAssertEqual($dictionary.count, 3U);

    %r XCTAssertEqualObjects($dictionary[@"1"], $v1);
    %o XCTAssertEqualObjects($dictionary[@"2"], NSNull.null);

    %r $dictionary[@"1"] = $dictionary[@"0"];
    %o $dictionary[@"2"] = $dictionary[@"1"];

    %r XCTAssertNotEqualObjects($dictionary[@"1"], $v1);
    %o XCTAssertNotEqualObjects($dictionary[@"2"], NSNull.null);
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
    %man %r [$dictionary addObjects:@{@"2": $v0, @"3": $v1, @"4": $v0, @"5": $v1}];
    %man %o [$dictionary addObjects:@{@"2": $v0, @"3": $v1, @"4": NSNull.null, @"5": $v1, @"6": $v0}];

    %man %r XCTAssertEqual(0U, [[$dictionary sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:@"1"]);
    %man %r XCTAssertEqual(2U, [[$dictionary sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:@"0"]);

    %man %o XCTAssertEqual(0U, [[$dictionary sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:@"1"]);
    %man %o XCTAssertEqual(2U, [[$dictionary sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:@"0"]);
    %man %o XCTAssertEqual(4U, [[$dictionary sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:NSNull.null]);
}

- (void)testIndexOfObjectDistinct {
    %man %r [$dictionary addObjects:@{@"2": $v0, @"3": $v0, @"4": $v1}];
    %man %o [$dictionary addObjects:@{@"2": $v0, @"3": $v0, @"4": NSNull.null, @"5": $v1, @"6": $v0}];

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
    %unman RLMAssertThrowsWithReason([$dictionary sortedResultsUsingKeyPath:@"self" ascending:NO], ^n @"This method may only be called on RLMDictionary instances retrieved from an RLMRealm");
    %unman RLMAssertThrowsWithReason([$dictionary sortedResultsUsingDescriptors:@[]], ^n @"This method may only be called on RLMDictionary instances retrieved from an RLMRealm");
    %man RLMAssertThrowsWithReason([$dictionary sortedResultsUsingKeyPath:@"not self" ascending:NO], ^n @"can only be sorted on 'self'");

    %man %r [$dictionary addObjects:@{@"2": $v0, @"3": $v1, @"4": $v0}];
    %man %o [$dictionary addObjects:@{@"2": $v0, @"3": $v1, @"4": NSNull.null, @"5": $v1, @"6": $v0}];

    %man %r XCTAssertEqualObjects([[$dictionary sortedResultsUsingDescriptors:@[]] valueForKey:@"self"], ^n (@[$v0, $v1, $v0]));
    %man %o XCTAssertEqualObjects([[$dictionary sortedResultsUsingDescriptors:@[]] valueForKey:@"self"], ^n (@[$v0, $v1, NSNull.null, $v1, $v0]));

    %man %r XCTAssertEqualObjects([[$dictionary sortedResultsUsingKeyPath:@"self" ascending:NO] valueForKey:@"self"], ^n (@[$v1, $v0, $v0]));
    %man %o XCTAssertEqualObjects([[$dictionary sortedResultsUsingKeyPath:@"self" ascending:NO] valueForKey:@"self"], ^n (@[$v1, $v1, $v0, $v0, NSNull.null]));

    %man %r XCTAssertEqualObjects([[$dictionary sortedResultsUsingKeyPath:@"self" ascending:YES] valueForKey:@"self"], ^n (@[$v0, $v0, $v1]));
    %man %o XCTAssertEqualObjects([[$dictionary sortedResultsUsingKeyPath:@"self" ascending:YES] valueForKey:@"self"], ^n (@[NSNull.null, $v0, $v0, $v1, $v1]));
}

- (void)testFilter {
    %unman RLMAssertThrowsWithReason([$dictionary objectsWhere:@"TRUEPREDICATE"], ^n @"This method may only be called on RLMDictionary instances retrieved from an RLMRealm");
    %unman RLMAssertThrowsWithReason([$dictionary objectsWithPredicate:[NSPredicate predicateWithValue:YES]], ^n @"This method may only be called on RLMDictionary instances retrieved from an RLMRealm");

    %man RLMAssertThrowsWithReason([$dictionary objectsWhere:@"TRUEPREDICATE"], ^n @"implemented");
    %man RLMAssertThrowsWithReason([$dictionary objectsWithPredicate:[NSPredicate predicateWithValue:YES]], ^n @"implemented");

    %man RLMAssertThrowsWithReason([[$dictionary sortedResultsUsingKeyPath:@"self" ascending:NO] ^n  objectsWhere:@"TRUEPREDICATE"], @"implemented");
    %man RLMAssertThrowsWithReason([[$dictionary sortedResultsUsingKeyPath:@"self" ascending:NO] ^n  objectsWithPredicate:[NSPredicate predicateWithValue:YES]], @"implemented");
}

- (void)testNotifications {
    %unman RLMAssertThrowsWithReason([$dictionary addNotificationBlock:^(__unused id a, __unused id c, __unused id e) { }], ^n @"This method may only be called on RLMDictionary instances retrieved from an RLMRealm");
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

    { ^nl NSUInteger i = 0; ^nl NSDictionary *values = $values; ^nl for (id key in $dictionary) { ^nl id value = $dictionary[key]; ^nl XCTAssertEqualObjects(values[key], value); ^nl } ^nl XCTAssertEqual(i, $dictionary.count); ^nl } ^nl 
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
    $dictionary = (id)@{@"testKey": $v1}; ^nl XCTAssertEqualObjects($dictionary[@"testKey"], $v1);

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
    RLMAssertThrowsWithReason(unmanaged.intObj = (id)@{@"0": NSNull.null},
                              @"Invalid value '<null>' of type 'NSNull' for RLMDictionary<string, int> property 'AllPrimitiveDictionaries.intObj'.");
    RLMAssertThrowsWithReason(unmanaged.intObj = (id)@{@"0": @"a"},
                              @"Invalid value 'a' of type '__NSCFConstantString' for RLMDictionary<string, int> property 'AllPrimitiveDictionaries.intObj'.");
    RLMAssertThrowsWithReason(unmanaged.intObj = (id)(@{@"0": @1, @"1": @"a"}),
                              @"Invalid value 'a' of type '__NSCFConstantString' for RLMDictionary<string, int> property 'AllPrimitiveDictionaries.intObj'.");
    RLMAssertThrowsWithReason(unmanaged.intObj = (id)unmanaged.floatObj,
                              @"RLMDictionary<string, float> does not match expected type RLMDictionary<string, int> for property 'AllPrimitiveDictionaries.intObj'.");
    RLMAssertThrowsWithReason(unmanaged.intObj = (id)optUnmanaged.intObj,
                              @"RLMDictionary<string, int?> does not match expected type RLMDictionary<string, int> for property 'AllPrimitiveDictionaries.intObj'.");
    RLMAssertThrowsWithReason(unmanaged[@"intObj"] = unmanaged[@"floatObj"],
                              @"RLMDictionary<string, float> does not match expected type RLMDictionary<string, int> for property 'AllPrimitiveDictionaries.intObj'.");
    RLMAssertThrowsWithReason(unmanaged[@"intObj"] = optUnmanaged[@"intObj"],
                              @"RLMDictionary<string, int?> does not match expected type RLMDictionary<string, int> for property 'AllPrimitiveDictionaries.intObj'.");

    RLMAssertThrowsWithReason(managed.intObj = (id)@{@"0": NSNull.null},
                              @"Invalid value '<null>' of type 'NSNull' for RLMDictionary<string, int> property 'AllPrimitiveDictionaries.intObj'.");
    RLMAssertThrowsWithReason(managed.intObj = (id)@{@"0": @"a"},
                              @"Invalid value 'a' of type '__NSCFConstantString' for RLMDictionary<string, int> property 'AllPrimitiveDictionaries.intObj'.");
    RLMAssertThrowsWithReason(managed.intObj = (id)(@{@"0": @1, @"0": @"a"}),
                              @"Invalid value 'a' of type '__NSCFConstantString' for RLMDictionary<string, int> property 'AllPrimitiveDictionaries.intObj'.");
    RLMAssertThrowsWithReason(managed.intObj = (id)managed.floatObj,
                              @"RLMDictionary<string, float> does not match expected type RLMDictionary<string, int> for property 'AllPrimitiveDictionaries.intObj'.");
    RLMAssertThrowsWithReason(managed.intObj = (id)optManaged.intObj,
                              @"RLMDictionary<string, int?> does not match expected type RLMDictionary<string, int> for property 'AllPrimitiveDictionaries.intObj'.");
    RLMAssertThrowsWithReason(managed[@"intObj"] = (id)managed[@"floatObj"],
                              @"RLMDictionary<string, float> does not match expected type RLMDictionary<string, int> for property 'AllPrimitiveDictionaries.intObj'.");
    RLMAssertThrowsWithReason(managed[@"intObj"] = (id)optManaged[@"intObj"],
                              @"RLMDictionary<string, int?> does not match expected type RLMDictionary<string, int> for property 'AllPrimitiveDictionaries.intObj'.");
}

- (void)testAllMethodsCheckThread {
    RLMDictionary *dictionary = managed.intObj;
    [self dispatchAsyncAndWait:^{
        RLMAssertThrowsWithReason([dictionary count], @"thread");
        RLMAssertThrowsWithReason([dictionary objectAtIndex:0], @"thread");
        RLMAssertThrowsWithReason([dictionary firstObject], @"thread");
        RLMAssertThrowsWithReason([dictionary lastObject], @"thread");

        RLMAssertThrowsWithReason([dictionary setObject:@0 forKey:@"thread"], @"thread");
        RLMAssertThrowsWithReason([dictionary addObjects:@{@"thread": @0}], @"thread");
        RLMAssertThrowsWithReason([dictionary removeObjectForKey:@"thread"], @"thread");
        RLMAssertThrowsWithReason([dictionary removeObjectsForKeys:(id)@[@"thread"]], @"thread");
        RLMAssertThrowsWithReason([dictionary removeAllObjects], @"thread");
        RLMAssertThrowsWithReason([dictionary setObject:NSNull.null forKey:@"thread"], @"thread");

        RLMAssertThrowsWithReason([dictionary indexOfObject:@1], @"thread");
        /* RLMAssertThrowsWithReason([dictionary indexOfObjectWhere:@"TRUEPREDICATE"], @"thread"); */
        /* RLMAssertThrowsWithReason([dictionary indexOfObjectWithPredicate:[NSPredicate predicateWithValue:NO]], @"thread"); */
        /* RLMAssertThrowsWithReason([dictionary objectsWhere:@"TRUEPREDICATE"], @"thread"); */
        /* RLMAssertThrowsWithReason([dictionary objectsWithPredicate:[NSPredicate predicateWithValue:NO]], @"thread"); */
        RLMAssertThrowsWithReason([dictionary sortedResultsUsingKeyPath:@"self" ascending:YES], @"thread");
        RLMAssertThrowsWithReason([dictionary sortedResultsUsingDescriptors:@[[RLMSortDescriptor sortDescriptorWithKeyPath:@"self" ascending:YES]]], @"thread");
        RLMAssertThrowsWithReason(dictionary[@"thread"], @"thread");
        RLMAssertThrowsWithReason(dictionary[@"thread"] = @0, @"thread");
        RLMAssertThrowsWithReason([dictionary valueForKey:@"self"], @"thread");
        RLMAssertThrowsWithReason([dictionary setValue:@1 forKey:@"self"], @"thread");
        RLMAssertThrowsWithReason({for (__unused id obj in dictionary);}, @"thread");
    }];
}

- (void)testAllMethodsCheckForInvalidation {
    RLMDictionary *dictionary = managed.intObj;
    [realm cancelWriteTransaction];
    [realm invalidate];

    XCTAssertNoThrow([dictionary objectClassName]);
    XCTAssertNoThrow([dictionary realm]);
    XCTAssertNoThrow([dictionary isInvalidated]);
    
    RLMAssertThrowsWithReason([dictionary count], @"invalidated");
    RLMAssertThrowsWithReason([dictionary objectAtIndex:0], @"invalidated");
    RLMAssertThrowsWithReason([dictionary firstObject], @"invalidated");
    RLMAssertThrowsWithReason([dictionary lastObject], @"invalidated");

    RLMAssertThrowsWithReason([dictionary setObject:@0 forKey:@"thread"], @"invalidated");
    RLMAssertThrowsWithReason([dictionary addObjects:@{@"invalidated": @0}], @"invalidated");
    RLMAssertThrowsWithReason([dictionary removeObjectForKey:@"invalidated"], @"invalidated");
    RLMAssertThrowsWithReason([dictionary removeObjectsForKeys:(id)@[@"invalidated"]], @"invalidated");
    RLMAssertThrowsWithReason([dictionary removeAllObjects], @"invalidated");
    RLMAssertThrowsWithReason([dictionary setObject:NSNull.null forKey:@"invalidated"], @"invalidated");

    RLMAssertThrowsWithReason([dictionary indexOfObject:@1], @"invalidated");
    /* RLMAssertThrowsWithReason([dictionary indexOfObjectWhere:@"TRUEPREDICATE"], @"invalidated"); */
    /* RLMAssertThrowsWithReason([dictionary indexOfObjectWithPredicate:[NSPredicate predicateWithValue:NO]], @"invalidated"); */
    /* RLMAssertThrowsWithReason([dictionary objectsWhere:@"TRUEPREDICATE"], @"invalidated"); */
    /* RLMAssertThrowsWithReason([dictionary objectsWithPredicate:[NSPredicate predicateWithValue:NO]], @"invalidated"); */
    RLMAssertThrowsWithReason([dictionary sortedResultsUsingKeyPath:@"self" ascending:YES], @"invalidated");
    RLMAssertThrowsWithReason([dictionary sortedResultsUsingDescriptors:@[[RLMSortDescriptor sortDescriptorWithKeyPath:@"self" ascending:YES]]], @"invalidated");
    RLMAssertThrowsWithReason(dictionary[@"invalidated"], @"invalidated");
    RLMAssertThrowsWithReason(dictionary[@"invalidated"] = @0, @"invalidated");
    RLMAssertThrowsWithReason([dictionary valueForKey:@"self"], @"invalidated");
    RLMAssertThrowsWithReason([dictionary setValue:@1 forKey:@"self"], @"invalidated");
    RLMAssertThrowsWithReason({for (__unused id obj in dictionary);}, @"invalidated");

    [realm beginWriteTransaction];
}

- (void)testMutatingMethodsCheckForWriteTransaction {
    RLMDictionary *dictionary = managed.intObj;
    [dictionary setObject:@0 forKey:@"testKey"];
    [realm commitWriteTransaction];

    XCTAssertNoThrow([dictionary objectClassName]);
    XCTAssertNoThrow([dictionary realm]);
    XCTAssertNoThrow([dictionary isInvalidated]);

    XCTAssertNoThrow([dictionary count]);
    XCTAssertNoThrow([dictionary objectAtIndex:0]);
    XCTAssertNoThrow([dictionary firstObject]);
    XCTAssertNoThrow([dictionary lastObject]);

    XCTAssertNoThrow([dictionary indexOfObject:@1]);
    /* XCTAssertNoThrow([dictionary indexOfObjectWhere:@"TRUEPREDICATE"]); */
    /* XCTAssertNoThrow([dictionary indexOfObjectWithPredicate:[NSPredicate predicateWithValue:YES]]); */
    /* XCTAssertNoThrow([dictionary objectsWhere:@"TRUEPREDICATE"]); */
    /* XCTAssertNoThrow([dictionary objectsWithPredicate:[NSPredicate predicateWithValue:YES]]); */
    XCTAssertNoThrow([dictionary sortedResultsUsingKeyPath:@"self" ascending:YES]);
    XCTAssertNoThrow([dictionary sortedResultsUsingDescriptors:@[[RLMSortDescriptor sortDescriptorWithKeyPath:@"self" ascending:YES]]]);
    XCTAssertNoThrow(dictionary[0]);
    XCTAssertNoThrow([dictionary valueForKey:@"self"]);
    XCTAssertNoThrow({for (__unused id obj in dictionary);});
    
    RLMAssertThrowsWithReason([dictionary setObject:@0 forKey:@"testKey"], @"write transaction");
    RLMAssertThrowsWithReason([dictionary addObjects:@{@"testKey": @0}], @"write transaction");
    RLMAssertThrowsWithReason([dictionary removeObjectForKey:@"testKey"], @"write transaction");
    RLMAssertThrowsWithReason([dictionary removeObjectsForKeys:(id)@[@"testKey"]], @"write transaction");
    RLMAssertThrowsWithReason([dictionary removeAllObjects], @"write transaction");
    RLMAssertThrowsWithReason([dictionary setObject:NSNull.null forKey:@"testKey"], @"write transaction");

    RLMAssertThrowsWithReason(dictionary[@"testKey"] = @0, @"write transaction");
    RLMAssertThrowsWithReason([dictionary setValue:@1 forKey:@"self"], @"write transaction");
}

- (void)testDeleteOwningObject {
    RLMDictionary *dictionary = managed.intObj;
    XCTAssertFalse(dictionary.isInvalidated);
    [realm deleteObject:managed];
    XCTAssertTrue(dictionary.isInvalidated);
}

#pragma clang diagnostic ignored "-Warc-retain-cycles"

- (void)testNotificationSentInitially {
    [realm commitWriteTransaction];

    id expectation = [self expectationWithDescription:@""];
    id token = [managed.intObj addNotificationBlock:^(RLMDictionary *dictionary, RLMCollectionChange *change, NSError *error) {
        XCTAssertNotNil(dictionary);
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
    id token = [managed.intObj addNotificationBlock:^(RLMDictionary *dictionary, RLMCollectionChange *change, NSError *error) {
        XCTAssertNotNil(dictionary);
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
            RLMDictionary *dictionary = [(AllPrimitiveDictionaries *)[AllPrimitiveDictionaries allObjectsInRealm:r].firstObject intObj];
            dictionary[@"testKey"] = @0;
        }];
    }];
    [self waitForExpectationsWithTimeout:2.0 handler:nil];

    [(RLMNotificationToken *)token invalidate];
}

- (void)testNotificationNotSentForUnrelatedChange {
    [realm commitWriteTransaction];

    id expectation = [self expectationWithDescription:@""];
    id token = [managed.intObj addNotificationBlock:^(__unused RLMDictionary *dictionary, __unused RLMCollectionChange *change, __unused NSError *error) {
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
    id token = [managed.intObj addNotificationBlock:^(RLMDictionary *dictionary, __unused RLMCollectionChange *change, NSError *error) {
        XCTAssertNotNil(dictionary);
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
                RLMDictionary *dictionary = [(AllPrimitiveDictionaries *)[AllPrimitiveDictionaries allObjectsInRealm:r].firstObject intObj];
                dictionary[@"testKey"] = @0;
            }];
        }];
    }];

    expectation = [self expectationWithDescription:@""];
    [realm refresh];
    [self waitForExpectationsWithTimeout:2.0 handler:nil];

    [(RLMNotificationToken *)token invalidate];
}

- (void)testDeletingObjectWithNotificationsRegistered {
    [managed.intObj addObjects:@{@"a": @10, @"b": @20}];
    [realm commitWriteTransaction];

    __block bool first = true;
    __block id expectation = [self expectationWithDescription:@""];
    id token = [managed.intObj addNotificationBlock:^(RLMDictionary *dictionary, RLMCollectionChange *change, NSError *error) {
        XCTAssertNotNil(dictionary);
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
//    NSRange range = {index, 1};
//    id obj = [AllPrimitiveDictionaries createInRealm:realm withValue:@{
//        %r %man @"$prop": [$values subarrayWithRange:range],
//    }];
//    [LinkToAllPrimitiveDictionaries createInRealm:realm withValue:@[obj]];
//    obj = [AllOptionalPrimitiveDictionaries createInRealm:realm withValue:@{
//        %o %man @"$prop": [$values subarrayWithRange:range],
//    }];
//    [LinkToAllOptionalPrimitiveDictionaries createInRealm:realm withValue:@[obj]];
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
