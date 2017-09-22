////////////////////////////////////////////////////////////////////////////
//
// Copyright 2017 Realm Inc.
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

@interface PrimitiveArrayPropertyTests : RLMTestCase
@end

@implementation PrimitiveArrayPropertyTests {
    AllPrimitiveArrays *unmanaged;
    AllPrimitiveArrays *managed;
    AllOptionalPrimitiveArrays *optUnmanaged;
    AllOptionalPrimitiveArrays *optManaged;
    RLMRealm *realm;
}

- (void)setUp {
    unmanaged = [[AllPrimitiveArrays alloc] init];
    optUnmanaged = [[AllOptionalPrimitiveArrays alloc] init];
    realm = [RLMRealm defaultRealm];
    [realm beginWriteTransaction];
    managed = [AllPrimitiveArrays createInRealm:realm withValue:@[]];
    optManaged = [AllOptionalPrimitiveArrays createInRealm:realm withValue:@[]];
}

- (void)tearDown {
    if (realm.inWriteTransaction) {
        [realm cancelWriteTransaction];
    }
}

- (void)testCount {
    XCTAssertEqual(unmanaged.intObj.count, 0U);
    [unmanaged.intObj addObject:@1];
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
    RLMArray *array;
    @autoreleasepool {
        AllPrimitiveArrays *obj = [[AllPrimitiveArrays alloc] init];
        array = obj.intObj;
        XCTAssertFalse(array.invalidated);
    }
    XCTAssertFalse(array.invalidated);
}

- (void)testDeleteObjectsInRealm {
    RLMAssertThrowsWithReason([realm deleteObjects:$array], @"Cannot delete objects from RLMArray");
}

static NSDate *date(int i) {
    return [NSDate dateWithTimeIntervalSince1970:i];
}
static NSData *data(int i) {
    return [NSData dataWithBytesNoCopy:calloc(i, 1) length:i freeWhenDone:YES];
}

- (void)testObjectAtIndex {
    RLMAssertThrowsWithReason([unmanaged.intObj objectAtIndex:0],
                              @"Index 0 is out of bounds (must be less than 0).");

    [unmanaged.intObj addObject:@1];
    XCTAssertEqualObjects([unmanaged.intObj objectAtIndex:0], @1);
}

- (void)testFirstObject {
    XCTAssertNil($array.firstObject);

    %r [$array addObjects:$values];
    %r XCTAssertEqualObjects($array.firstObject, $first);

    %o [$array addObject:NSNull.null];
    %o XCTAssertEqualObjects($array.firstObject, NSNull.null);

    %o [$array removeAllObjects];

    %o [$array addObjects:$values];
    %o XCTAssertEqualObjects($array.firstObject, $first);
}

- (void)testLastObject {
    XCTAssertNil($array.lastObject);

    [$array addObjects:$values];
    XCTAssertEqualObjects($array.lastObject, $last);

    %o [$array removeLastObject];
    %o XCTAssertEqualObjects($array.lastObject, $v1);
}

- (void)testAddObject {
    RLMAssertThrowsWithReason([$array addObject:$wrong], ^n @"Invalid value '$wdesc' of type '$wtype' for expected type '$type'");
    %r RLMAssertThrowsWithReason([$array addObject:NSNull.null], ^n @"Invalid value '<null>' of type 'NSNull' for expected type '$type'");

    [$array addObject:$v0];
    XCTAssertEqualObjects($array[0], $v0);

    %o [$array addObject:NSNull.null];
    %o XCTAssertEqualObjects($array[1], NSNull.null);
}

- (void)testAddObjects {
    RLMAssertThrowsWithReason([$array addObjects:@[$wrong]], ^n @"Invalid value '$wdesc' of type '$wtype' for expected type '$type'");
    %r RLMAssertThrowsWithReason([$array addObjects:@[NSNull.null]], ^n @"Invalid value '<null>' of type 'NSNull' for expected type '$type'");

    [$array addObjects:$values];
    XCTAssertEqualObjects($array[0], $v0);
    XCTAssertEqualObjects($array[1], $v1);
    %o XCTAssertEqualObjects($array[2], NSNull.null);
}

- (void)testInsertObject {
    RLMAssertThrowsWithReason([$array insertObject:$wrong atIndex:0], ^n @"Invalid value '$wdesc' of type '$wtype' for expected type '$type'");
    %r RLMAssertThrowsWithReason([$array insertObject:NSNull.null atIndex:0], ^n @"Invalid value '<null>' of type 'NSNull' for expected type '$type'");
    RLMAssertThrowsWithReason([$array insertObject:$v0 atIndex:1], ^n @"Index 1 is out of bounds (must be less than 1).");

    [$array insertObject:$v0 atIndex:0];
    XCTAssertEqualObjects($array[0], $v0);

    [$array insertObject:$v1 atIndex:0];
    XCTAssertEqualObjects($array[0], $v1);
    XCTAssertEqualObjects($array[1], $v0);

    %o [$array insertObject:NSNull.null atIndex:1];
    %o XCTAssertEqualObjects($array[0], $v1);
    %o XCTAssertEqualObjects($array[1], NSNull.null);
    %o XCTAssertEqualObjects($array[2], $v0);
}

- (void)testRemoveObject {
    RLMAssertThrowsWithReason([$array removeObjectAtIndex:0], ^n @"Index 0 is out of bounds (must be less than 0).");

    [$array addObjects:$values];
    %r XCTAssertEqual($array.count, 2U);
    %o XCTAssertEqual($array.count, 3U);

    %r RLMAssertThrowsWithReason([$array removeObjectAtIndex:2], ^n @"Index 2 is out of bounds (must be less than 2).");
    %o RLMAssertThrowsWithReason([$array removeObjectAtIndex:3], ^n @"Index 3 is out of bounds (must be less than 3).");

    [$array removeObjectAtIndex:0];
    %r XCTAssertEqual($array.count, 1U);
    %o XCTAssertEqual($array.count, 2U);

    XCTAssertEqualObjects($array[0], $v1);
    %o XCTAssertEqualObjects($array[1], NSNull.null);
}

- (void)testRemoveLastObject {
    XCTAssertNoThrow([$array removeLastObject]);

    [$array addObjects:$values];
    %r XCTAssertEqual($array.count, 2U);
    %o XCTAssertEqual($array.count, 3U);

    [$array removeLastObject];
    %r XCTAssertEqual($array.count, 1U);
    %o XCTAssertEqual($array.count, 2U);

    XCTAssertEqualObjects($array[0], $v0);
    %o XCTAssertEqualObjects($array[1], $v1);
}

- (void)testReplace {
    RLMAssertThrowsWithReason([$array replaceObjectAtIndex:0 withObject:$v0], ^n @"Index 0 is out of bounds (must be less than 0).");

    [$array addObject:$v0]; ^nl [$array replaceObjectAtIndex:0 withObject:$v1]; ^nl XCTAssertEqualObjects($array[0], $v1); ^nl 

    %o [$array replaceObjectAtIndex:0 withObject:NSNull.null]; ^nl XCTAssertEqualObjects($array[0], NSNull.null);

    RLMAssertThrowsWithReason([$array replaceObjectAtIndex:0 withObject:$wrong], ^n @"Invalid value '$wdesc' of type '$wtype' for expected type '$type'");
    %r RLMAssertThrowsWithReason([$array replaceObjectAtIndex:0 withObject:NSNull.null], ^n @"Invalid value '<null>' of type 'NSNull' for expected type '$type'");
}

- (void)testMove {
    RLMAssertThrowsWithReason([$array moveObjectAtIndex:0 toIndex:1], ^n @"Index 0 is out of bounds (must be less than 0).");
    RLMAssertThrowsWithReason([$array moveObjectAtIndex:1 toIndex:0], ^n @"Index 1 is out of bounds (must be less than 0).");

    [$array addObjects:@[$v0, $v1, $v0, $v1]];

    [$array moveObjectAtIndex:2 toIndex:0];

    XCTAssertEqualObjects([$array valueForKey:@"self"], ^n (@[$v0, $v0, $v1, $v1]));
}

- (void)testExchange {
    RLMAssertThrowsWithReason([$array exchangeObjectAtIndex:0 withObjectAtIndex:1], ^n @"Index 0 is out of bounds (must be less than 0).");
    RLMAssertThrowsWithReason([$array exchangeObjectAtIndex:1 withObjectAtIndex:0], ^n @"Index 1 is out of bounds (must be less than 0).");

    [$array addObjects:@[$v0, $v1, $v0, $v1]];

    [$array exchangeObjectAtIndex:2 withObjectAtIndex:1];

    XCTAssertEqualObjects([$array valueForKey:@"self"], ^n (@[$v0, $v0, $v1, $v1]));
}

- (void)testIndexOfObject {
    XCTAssertEqual(NSNotFound, [$array indexOfObject:$v0]);

    RLMAssertThrowsWithReason([$array indexOfObject:$wrong], ^n @"Invalid value '$wdesc' of type '$wtype' for expected type '$type'");

    %r RLMAssertThrowsWithReason([$array indexOfObject:NSNull.null], ^n @"Invalid value '<null>' of type 'NSNull' for expected type '$type'");
    %o XCTAssertEqual(NSNotFound, [$array indexOfObject:NSNull.null]);

    [$array addObjects:$values];

    XCTAssertEqual(1U, [$array indexOfObject:$v1]);
}

- (void)testIndexOfObjectWhere {
    %man RLMAssertThrowsWithReason([$array indexOfObjectWhere:@"TRUEPREDICATE"], @"implemented");
    %man RLMAssertThrowsWithReason([[$array sortedResultsUsingKeyPath:@"self" ascending:NO] ^n  indexOfObjectWhere:@"TRUEPREDICATE"], @"implemented");

    %unman XCTAssertEqual(NSNotFound, [$array indexOfObjectWhere:@"TRUEPREDICATE"]);

    %unman [$array addObjects:$values];

    %unman XCTAssertEqual(0U, [$array indexOfObjectWhere:@"TRUEPREDICATE"]);
    %unman XCTAssertEqual(NSNotFound, [$array indexOfObjectWhere:@"FALSEPREDICATE"]);
}

- (void)testIndexOfObjectWithPredicate {
    %man RLMAssertThrowsWithReason([$array indexOfObjectWithPredicate:[NSPredicate predicateWithValue:YES]], @"implemented");
    %man RLMAssertThrowsWithReason([[$array sortedResultsUsingKeyPath:@"self" ascending:NO] ^n  indexOfObjectWithPredicate:[NSPredicate predicateWithValue:YES]], @"implemented");

    %unman XCTAssertEqual(NSNotFound, [$array indexOfObjectWithPredicate:[NSPredicate predicateWithValue:YES]]);

    %unman [$array addObjects:$values];

    %unman XCTAssertEqual(0U, [$array indexOfObjectWithPredicate:[NSPredicate predicateWithValue:YES]]);
    %unman XCTAssertEqual(NSNotFound, [$array indexOfObjectWithPredicate:[NSPredicate predicateWithValue:NO]]);
}

- (void)testSort {
    %unman RLMAssertThrowsWithReason([$array sortedResultsUsingKeyPath:@"self" ascending:NO], ^n @"This method may only be called on RLMArray instances retrieved from an RLMRealm");
    %unman RLMAssertThrowsWithReason([$array sortedResultsUsingDescriptors:@[]], ^n @"This method may only be called on RLMArray instances retrieved from an RLMRealm");
    %man RLMAssertThrowsWithReason([$array sortedResultsUsingKeyPath:@"not self" ascending:NO], ^n @"can only be sorted on 'self'");

    %man %r [$array addObjects:@[$v0, $v1, $v0]];
    %man %o [$array addObjects:@[$v0, $v1, NSNull.null, $v1, $v0]];

    %man %r XCTAssertEqualObjects([[$array sortedResultsUsingDescriptors:@[]] valueForKey:@"self"], ^n (@[$v0, $v1, $v0]));
    %man %o XCTAssertEqualObjects([[$array sortedResultsUsingDescriptors:@[]] valueForKey:@"self"], ^n (@[$v0, $v1, NSNull.null, $v1, $v0]));

    %man %r XCTAssertEqualObjects([[$array sortedResultsUsingKeyPath:@"self" ascending:NO] valueForKey:@"self"], ^n (@[$v1, $v0, $v0]));
    %man %o XCTAssertEqualObjects([[$array sortedResultsUsingKeyPath:@"self" ascending:NO] valueForKey:@"self"], ^n (@[$v1, $v1, $v0, $v0, NSNull.null]));

    %man %r XCTAssertEqualObjects([[$array sortedResultsUsingKeyPath:@"self" ascending:YES] valueForKey:@"self"], ^n (@[$v0, $v0, $v1]));
    %man %o XCTAssertEqualObjects([[$array sortedResultsUsingKeyPath:@"self" ascending:YES] valueForKey:@"self"], ^n (@[NSNull.null, $v0, $v0, $v1, $v1]));
}

- (void)testFilter {
    %unman RLMAssertThrowsWithReason([$array objectsWhere:@"TRUEPREDICATE"], ^n @"This method may only be called on RLMArray instances retrieved from an RLMRealm");
    %unman RLMAssertThrowsWithReason([$array objectsWithPredicate:[NSPredicate predicateWithValue:YES]], ^n @"This method may only be called on RLMArray instances retrieved from an RLMRealm");

    %man RLMAssertThrowsWithReason([$array objectsWhere:@"TRUEPREDICATE"], ^n @"implemented");
    %man RLMAssertThrowsWithReason([$array objectsWithPredicate:[NSPredicate predicateWithValue:YES]], ^n @"implemented");

    %man RLMAssertThrowsWithReason([[$array sortedResultsUsingKeyPath:@"self" ascending:NO] ^n  objectsWhere:@"TRUEPREDICATE"], @"implemented");
    %man RLMAssertThrowsWithReason([[$array sortedResultsUsingKeyPath:@"self" ascending:NO] ^n  objectsWithPredicate:[NSPredicate predicateWithValue:YES]], @"implemented");
}

- (void)testNotifications {
    %unman RLMAssertThrowsWithReason([$array addNotificationBlock:^(__unused id a, __unused id c, __unused id e) { }], ^n @"This method may only be called on RLMArray instances retrieved from an RLMRealm");
}

- (void)testMin {
    %nominmax %unman RLMAssertThrowsWithReason([$array minOfProperty:@"self"], ^n @"minOfProperty: is not supported for $type array");
    %nominmax %man RLMAssertThrowsWithReason([$array minOfProperty:@"self"], ^n @"minOfProperty: is not supported for $type array '$class.$prop'");

    %minmax XCTAssertNil([$array minOfProperty:@"self"]);

    %minmax [$array addObjects:$values];

    %minmax XCTAssertEqualObjects([$array minOfProperty:@"self"], $v0);
}

- (void)testMax {
    %nominmax %unman RLMAssertThrowsWithReason([$array maxOfProperty:@"self"], ^n @"maxOfProperty: is not supported for $type array");
    %nominmax %man RLMAssertThrowsWithReason([$array maxOfProperty:@"self"], ^n @"maxOfProperty: is not supported for $type array '$class.$prop'");

    %minmax XCTAssertNil([$array maxOfProperty:@"self"]);

    %minmax [$array addObjects:$values];

    %minmax XCTAssertEqualObjects([$array maxOfProperty:@"self"], $v1);
}

- (void)testSum {
    %nosum %unman RLMAssertThrowsWithReason([$array sumOfProperty:@"self"], ^n @"sumOfProperty: is not supported for $type array");
    %nosum %man RLMAssertThrowsWithReason([$array sumOfProperty:@"self"], ^n @"sumOfProperty: is not supported for $type array '$class.$prop'");

    %sum XCTAssertEqualObjects([$array sumOfProperty:@"self"], @0);

    %sum [$array addObjects:$values];

    %sum XCTAssertEqualObjects([$array sumOfProperty:@"self"], @($s0 + $s1));
}

- (void)testAverage {
    %noavg %unman RLMAssertThrowsWithReason([$array averageOfProperty:@"self"], ^n @"averageOfProperty: is not supported for $type array");
    %noavg %man RLMAssertThrowsWithReason([$array averageOfProperty:@"self"], ^n @"averageOfProperty: is not supported for $type array '$class.$prop'");

    %avg XCTAssertNil([$array averageOfProperty:@"self"]);

    %avg [$array addObjects:$values];

    %avg XCTAssertEqualWithAccuracy([$array averageOfProperty:@"self"].doubleValue, ($s0 + $s1) / 2.0, .001);
}

- (void)testFastEnumeration {
    for (int i = 0; i < 10; ++i) {
        [$array addObjects:$values];
    }

    { ^nl NSUInteger i = 0; ^nl NSArray *values = $values; ^nl for (id value in $array) { ^nl XCTAssertEqualObjects(values[i++ % values.count], value); ^nl } ^nl XCTAssertEqual(i, $array.count); ^nl } ^nl 
}

- (void)testValueForKeySelf {
    XCTAssertEqualObjects([$array valueForKey:@"self"], @[]);

    [$array addObjects:$values];

    XCTAssertEqualObjects([$array valueForKey:@"self"], ($values));
}

- (void)testValueForKeyNumericAggregates {
    %minmax XCTAssertNil([$array valueForKeyPath:@"@min.self"]);
    %minmax XCTAssertNil([$array valueForKeyPath:@"@max.self"]);
    %sum XCTAssertEqualObjects([$array valueForKeyPath:@"@sum.self"], @0);
    %avg XCTAssertNil([$array valueForKeyPath:@"@avg.self"]);

    [$array addObjects:$values];

    %minmax XCTAssertEqualObjects([$array valueForKeyPath:@"@min.self"], $v0);
    %minmax XCTAssertEqualObjects([$array valueForKeyPath:@"@max.self"], $v1);
    %sum XCTAssertEqualObjects([$array valueForKeyPath:@"@sum.self"], @($s0 + $s1));
    %avg XCTAssertEqualWithAccuracy([[$array valueForKeyPath:@"@avg.self"] doubleValue], ($s0 + $s1) / 2.0, .001);
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

                return [a compare:b];
            }];
}

- (void)testUnionOfObjects {
    XCTAssertEqualObjects([$array valueForKeyPath:@"@unionOfObjects.self"], @[]);
    XCTAssertEqualObjects([$array valueForKeyPath:@"@distinctUnionOfObjects.self"], @[]);

    [$array addObjects:$values2];

    XCTAssertEqualObjects([$array valueForKeyPath:@"@unionOfObjects.self"], ^n ($values2));
    XCTAssertEqualObjects(sortedDistinctUnion($array, @"Objects", @"self"), ^n ($values));
}

- (void)testUnionOfArrays {
    RLMResults *allRequired = [AllPrimitiveArrays allObjectsInRealm:realm];
    RLMResults *allOptional = [AllOptionalPrimitiveArrays allObjectsInRealm:realm];

    %man %r XCTAssertEqualObjects([allRequired valueForKeyPath:@"@unionOfArrays.$prop"], @[]);
    %man %o XCTAssertEqualObjects([allOptional valueForKeyPath:@"@unionOfArrays.$prop"], @[]);
    %man %r XCTAssertEqualObjects([allRequired valueForKeyPath:@"@distinctUnionOfArrays.$prop"], @[]);
    %man %o XCTAssertEqualObjects([allOptional valueForKeyPath:@"@distinctUnionOfArrays.$prop"], @[]);

    [$array addObjects:$values];

    [AllPrimitiveArrays createInRealm:realm withValue:managed];
    [AllOptionalPrimitiveArrays createInRealm:realm withValue:optManaged];

    %man %r XCTAssertEqualObjects([allRequired valueForKeyPath:@"@unionOfArrays.$prop"], ^n ($values2));
    %man %o XCTAssertEqualObjects([allOptional valueForKeyPath:@"@unionOfArrays.$prop"], ^n ($values2));
    %man %r XCTAssertEqualObjects(sortedDistinctUnion(allRequired, @"Arrays", @"$prop"), ^n ($values));
    %man %o XCTAssertEqualObjects(sortedDistinctUnion(allOptional, @"Arrays", @"$prop"), ^n ($values));
}

- (void)testSetValueForKey {
    RLMAssertThrowsWithReason([$array setValue:@0 forKey:@"not self"], ^n @"this class is not key value coding-compliant for the key not self.");
    RLMAssertThrowsWithReason([$array setValue:$wrong forKey:@"self"], ^n @"Invalid value '$wdesc' of type '$wtype' for expected type '$type'");
    %r RLMAssertThrowsWithReason([$array setValue:NSNull.null forKey:@"self"], ^n @"Invalid value '<null>' of type 'NSNull' for expected type '$type'");

    [$array addObjects:$values];

    [$array setValue:$v0 forKey:@"self"];

    XCTAssertEqualObjects($array[0], $v0);
    XCTAssertEqualObjects($array[1], $v0);
    %o XCTAssertEqualObjects($array[2], $v0);

    %o [$array setValue:NSNull.null forKey:@"self"];
    %o XCTAssertEqualObjects($array[0], NSNull.null);
}

- (void)testAssignment {
    $array = (id)@[$v1]; ^nl XCTAssertEqualObjects($array[0], $v1);

    // Should replace and not append
    $array = (id)$values; ^nl XCTAssertEqualObjects([$array valueForKey:@"self"], ($values)); ^nl 

    // Should not clear the array
    $array = $array; ^nl XCTAssertEqualObjects([$array valueForKey:@"self"], ($values)); ^nl 

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
                              @"Invalid value '<null>' of type 'NSNull' for 'int' array property 'AllPrimitiveArrays.intObj'.");
    RLMAssertThrowsWithReason(unmanaged.intObj = (id)@[@"a"],
                              @"Invalid value 'a' of type '__NSCFConstantString' for 'int' array property 'AllPrimitiveArrays.intObj'.");
    RLMAssertThrowsWithReason(unmanaged.intObj = (id)(@[@1, @"a"]),
                              @"Invalid value 'a' of type '__NSCFConstantString' for 'int' array property 'AllPrimitiveArrays.intObj'.");
    RLMAssertThrowsWithReason(unmanaged.intObj = (id)unmanaged.floatObj,
                              @"RLMArray<float> does not match expected type 'int' for property 'AllPrimitiveArrays.intObj'.");
    RLMAssertThrowsWithReason(unmanaged.intObj = (id)optUnmanaged.intObj,
                              @"RLMArray<int?> does not match expected type 'int' for property 'AllPrimitiveArrays.intObj'.");
    RLMAssertThrowsWithReason(unmanaged[@"intObj"] = unmanaged[@"floatObj"],
                              @"RLMArray<float> does not match expected type 'int' for property 'AllPrimitiveArrays.intObj'.");
    RLMAssertThrowsWithReason(unmanaged[@"intObj"] = optUnmanaged[@"intObj"],
                              @"RLMArray<int?> does not match expected type 'int' for property 'AllPrimitiveArrays.intObj'.");

    RLMAssertThrowsWithReason(managed.intObj = (id)@[NSNull.null],
                              @"Invalid value '<null>' of type 'NSNull' for 'int' array property 'AllPrimitiveArrays.intObj'.");
    RLMAssertThrowsWithReason(managed.intObj = (id)@[@"a"],
                              @"Invalid value 'a' of type '__NSCFConstantString' for 'int' array property 'AllPrimitiveArrays.intObj'.");
    RLMAssertThrowsWithReason(managed.intObj = (id)(@[@1, @"a"]),
                              @"Invalid value 'a' of type '__NSCFConstantString' for 'int' array property 'AllPrimitiveArrays.intObj'.");
    RLMAssertThrowsWithReason(managed.intObj = (id)managed.floatObj,
                              @"RLMArray<float> does not match expected type 'int' for property 'AllPrimitiveArrays.intObj'.");
    RLMAssertThrowsWithReason(managed.intObj = (id)optManaged.intObj,
                              @"RLMArray<int?> does not match expected type 'int' for property 'AllPrimitiveArrays.intObj'.");
    RLMAssertThrowsWithReason(managed[@"intObj"] = (id)managed[@"floatObj"],
                              @"RLMArray<float> does not match expected type 'int' for property 'AllPrimitiveArrays.intObj'.");
    RLMAssertThrowsWithReason(managed[@"intObj"] = (id)optManaged[@"intObj"],
                              @"RLMArray<int?> does not match expected type 'int' for property 'AllPrimitiveArrays.intObj'.");
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
            RLMArray *array = [(AllPrimitiveArrays *)[AllPrimitiveArrays allObjectsInRealm:r].firstObject intObj];
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
                [AllPrimitiveArrays createInRealm:r withValue:@[]];
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
                RLMArray *array = [(AllPrimitiveArrays *)[AllPrimitiveArrays allObjectsInRealm:r].firstObject intObj];
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

@end
