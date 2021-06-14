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
static double sum(NSDictionary *dictionary) {
    NSArray *values = dictionary.allValues;
    double sum = 0;
    NSUInteger c = 0;
    count(values, &sum, &c);
    return sum;
}
static double average(NSDictionary *dictionary) {
    NSArray *values = dictionary.allValues;
    double sum = 0;
    NSUInteger c = 0;
    count(values, &sum, &c);
    return sum / c;
}

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
    [$dictionary addEntriesFromDictionary:$values];
}

- (void)testCount {
    uncheckedAssertEqual(unmanaged.intObj.count, 0U);
    unmanaged.intObj[@"testVal"] = @1;
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
    RLMDictionary *dictionary;
    @autoreleasepool {
        AllPrimitiveDictionaries *obj = [[AllPrimitiveDictionaries alloc] init];
        dictionary = obj.intObj;
        uncheckedAssertFalse(dictionary.invalidated);
    }
    uncheckedAssertFalse(dictionary.invalidated);
}

- (void)testDeleteObjectsInRealm {
    %unman RLMAssertThrowsWithReason([realm deleteObjects:$dictionary], @"Cannot delete objects from RLMDictionary");
    %man RLMAssertThrowsWithReason([realm deleteObjects:$dictionary], @"Cannot delete objects from RLMManagedDictionary<RLMString, $type>: only RLMObjects can be deleted.");
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wnonnull"

- (void)testSetObject {
    // Managed non-optional
    %man %r uncheckedAssertNil($dictionary[$firstKey]);
    %man %r XCTAssertNoThrow($dictionary[$firstKey] = $firstValue);
    %man %r uncheckedAssertEqualObjects($dictionary[$firstKey], $firstValue);
    %noany %man %r RLMAssertThrowsWithReason($dictionary[$firstKey] = (id)NSNull.null, @"Invalid value '<null>' of type 'NSNull' for expected type '$type'.");
    %man %r XCTAssertNoThrow($dictionary[$firstKey] = nil);
    %man %r uncheckedAssertNil($dictionary[$firstKey]);

    // Managed optional
    %man %o uncheckedAssertNil($dictionary[$firstKey]);
    %man %o XCTAssertNoThrow($dictionary[$firstKey] = $firstValue);
    %man %o uncheckedAssertEqualObjects($dictionary[$firstKey], $firstValue);
    %man %o XCTAssertNoThrow($dictionary[$firstKey] = (id)NSNull.null);
    %man %o uncheckedAssertEqualObjects($dictionary[$firstKey], (id)NSNull.null);
    %man %o XCTAssertNoThrow($dictionary[$firstKey] = nil);
    %man %o uncheckedAssertNil($dictionary[$firstKey]);

    // Unmanaged non-optional
    %unman %r uncheckedAssertNil($dictionary[$firstKey]);
    %unman %r XCTAssertNoThrow($dictionary[$firstKey] = $firstValue);
    %unman %r uncheckedAssertEqualObjects($dictionary[$firstKey], $firstValue);
    %noany %unman %r RLMAssertThrowsWithReason($dictionary[$firstKey] = (id)NSNull.null, @"Invalid value '<null>' of type 'NSNull' for expected type '$type'.");
    %unman %r XCTAssertNoThrow($dictionary[$firstKey] = nil);
    %unman %r uncheckedAssertNil($dictionary[$firstKey]);

    // Unmanaged optional
    %unman %o uncheckedAssertNil($dictionary[$firstKey]);
    %unman %o XCTAssertNoThrow($dictionary[$firstKey] = $firstValue);
    %unman %o uncheckedAssertEqualObjects($dictionary[$firstKey], $firstValue);
    %unman %o XCTAssertNoThrow($dictionary[$firstKey] = (id)NSNull.null);
    %unman %o uncheckedAssertEqual($dictionary[$firstKey], (id)NSNull.null);
    %unman %o XCTAssertNoThrow($dictionary[$firstKey] = nil);
    %unman %o uncheckedAssertNil($dictionary[$firstKey]);

    // Fail with nil key
    RLMAssertThrowsWithReason([$dictionary setObject:$firstValue forKey:nil], ^n @"Invalid nil key for dictionary expecting key of type 'string'.");
    // Fail on set nil for non-optional
    %noany %r RLMAssertThrowsWithReason([$dictionary setObject:(id)NSNull.null forKey:$firstKey], ^n @"Invalid value '<null>' of type 'NSNull' for expected type '$type'");

    %noany RLMAssertThrowsWithReason([$dictionary setObject:(id)$wrong forKey:$firstKey], ^n @"Invalid value '$wdesc' of type '" $wtype "' for expected type '$type'");
    %noany %r RLMAssertThrowsWithReason([$dictionary setObject:(id)NSNull.null forKey:$firstKey], ^n @"Invalid value '<null>' of type 'NSNull' for expected type '$type'");

    $dictionary[$firstKey] = $v0;
    uncheckedAssertEqualObjects($dictionary[$firstKey], $v0);

    %o $dictionary[$firstKey] = (id)NSNull.null;
    %o uncheckedAssertEqualObjects($dictionary[$firstKey], (id)NSNull.null);
}
#pragma clang diagnostic pop

- (void)testAddObjects {
    %noany RLMAssertThrowsWithReason([$dictionary addEntriesFromDictionary:@{$firstKey: $wrong}], ^n @"Invalid value '$wdesc' of type '" $wtype "' for expected type '$type'");
    %noany %r RLMAssertThrowsWithReason([$dictionary addEntriesFromDictionary:@{$firstKey: (id)NSNull.null}], ^n @"Invalid value '<null>' of type 'NSNull' for expected type '$type'");

    [self addObjects];
    uncheckedAssertEqualObjects($dictionary[$k0], $v0);
    uncheckedAssertEqualObjects($dictionary[$k1], $v1);
    %o uncheckedAssertEqualObjects($dictionary[$k1], (id)NSNull.null);
}

- (void)testRemoveObject {
    [self addObjects];
    %r uncheckedAssertEqual($dictionary.count, 2U);
    %o uncheckedAssertEqual($dictionary.count, 2U);

    uncheckedAssertEqualObjects($dictionary[$k0], $v0);

    [$dictionary removeObjectForKey:$k0];

    %r uncheckedAssertEqual($dictionary.count, 1U);
    %o uncheckedAssertEqual($dictionary.count, 1U);

    uncheckedAssertNil($dictionary[$k0]);
}

- (void)testRemoveObjects {
    [self addObjects];
    uncheckedAssertEqual($dictionary.count, 2U);

    uncheckedAssertEqualObjects($dictionary[$k0], $v0);

    [$dictionary removeObjectsForKeys:@[$k0, $k1]];

    uncheckedAssertEqual($dictionary.count, 0U);
    uncheckedAssertNil($dictionary[$k0]);
}

- (void)testUpdateObjects {
    [self addObjects];
    uncheckedAssertEqual($dictionary.count, 2U);

    uncheckedAssertEqualObjects($dictionary[$k0], $v0);
    uncheckedAssertEqualObjects($dictionary[$k1], $v1);

    $dictionary[$k1] = $dictionary[$k0];
    $dictionary[$k0] = $dictionary[$k1];

    uncheckedAssertEqualObjects($dictionary[$k1], $v0);
}

- (void)testIndexOfObjectSorted {
    [$dictionary addEntriesFromDictionary:@{ $k0: $v0, $k1: $v1 }];

    %man %o uncheckedAssertEqual(0U, [[$dictionary sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:$v0]);
    %man %o uncheckedAssertEqual(1U, [[$dictionary sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:(id)$v1]);
    %man %r uncheckedAssertEqual(1U, [[$dictionary sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:$v0]);
    %man %r uncheckedAssertEqual(0U, [[$dictionary sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:$v1]);

    %man %o uncheckedAssertEqual(1U, [[$dictionary sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:(id)NSNull.null]);
}

- (void)testIndexOfObjectDistinct {
    [$dictionary addEntriesFromDictionary:@{ $k0: $v0, $k1: $v1 }];

    %man %r uncheckedAssertEqual(1U, [[$dictionary distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:$v0]);
    %man %r uncheckedAssertEqual(0U, [[$dictionary distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:$v1]);

    %man %o uncheckedAssertEqual(1U, [[$dictionary distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:$v0]);
    %man %o uncheckedAssertEqual(0U, [[$dictionary distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:(id)$v1]);
    %man %o uncheckedAssertEqual(0U, [[$dictionary distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:(id)NSNull.null]);
}

- (void)testSort {
    %unman RLMAssertThrowsWithReason([$dictionary sortedResultsUsingKeyPath:@"self" ascending:NO], ^n @"This method may only be called on RLMDictionary instances retrieved from an RLMRealm");
    %unman RLMAssertThrowsWithReason([$dictionary sortedResultsUsingDescriptors:@[]], ^n @"This method may only be called on RLMDictionary instances retrieved from an RLMRealm");
    %man RLMAssertThrowsWithReason([$dictionary sortedResultsUsingKeyPath:@"not self" ascending:NO], ^n @"can only be sorted on 'self'");

    [$dictionary addEntriesFromDictionary:@{ $k0: $v0, $k1: $v1 }];

    %man uncheckedAssertEqualObjects([[$dictionary sortedResultsUsingDescriptors:@[]] valueForKey:@"self"], ^n (@[$v1, $v0]));

    %man %r uncheckedAssertEqualObjects([[$dictionary sortedResultsUsingKeyPath:@"self" ascending:NO] valueForKey:@"self"], ^n (@[$v1, $v0]));
    %man %o uncheckedAssertEqualObjects([[$dictionary sortedResultsUsingKeyPath:@"self" ascending:NO] valueForKey:@"self"], ^n (@[$v0, $v1]));

    %man %r uncheckedAssertEqualObjects([[$dictionary sortedResultsUsingKeyPath:@"self" ascending:YES] valueForKey:@"self"], ^n (@[$v0, $v1]));
    %man %o uncheckedAssertEqualObjects([[$dictionary sortedResultsUsingKeyPath:@"self" ascending:YES] valueForKey:@"self"], ^n (@[$v1, $v0]));
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
    %noany %nominmax %unman RLMAssertThrowsWithReason([$dictionary minOfProperty:@"self"], ^n @"minOfProperty: is not supported for $type dictionary");
    %noany %nominmax %man RLMAssertThrowsWithReason([$dictionary minOfProperty:@"self"], ^n @"minOfProperty: is not supported for $type dictionary '$class.$prop'");

    %minmax uncheckedAssertNil([$dictionary minOfProperty:@"self"]);

    [self addObjects];

    %minmax uncheckedAssertEqualObjects([$dictionary minOfProperty:@"self"], $v0);
}

- (void)testMax {
    %noany %nominmax %unman RLMAssertThrowsWithReason([$dictionary maxOfProperty:@"self"], ^n @"maxOfProperty: is not supported for $type dictionary");
    %noany %nominmax %man RLMAssertThrowsWithReason([$dictionary maxOfProperty:@"self"], ^n @"maxOfProperty: is not supported for $type dictionary '$class.$prop'");

    %minmax uncheckedAssertNil([$dictionary maxOfProperty:@"self"]);

    [self addObjects];

    %r %minmax uncheckedAssertEqualObjects([$dictionary maxOfProperty:@"self"], $v1);
    %o %minmax uncheckedAssertEqualObjects([$dictionary maxOfProperty:@"self"], $v0);
}

- (void)testSum {
    %noany %nosum %unman RLMAssertThrowsWithReason([$dictionary sumOfProperty:@"self"], ^n @"sumOfProperty: is not supported for $type dictionary");
    %noany %nosum %man RLMAssertThrowsWithReason([$dictionary sumOfProperty:@"self"], ^n @"sumOfProperty: is not supported for $type dictionary '$class.$prop'");

    %sum uncheckedAssertEqualObjects([$dictionary sumOfProperty:@"self"], @0);

    [self addObjects];

    %sum XCTAssertEqualWithAccuracy([$dictionary sumOfProperty:@"self"].doubleValue, sum($values), .001);
}

- (void)testAverage {
    %noany %noavg %unman RLMAssertThrowsWithReason([$dictionary averageOfProperty:@"self"], ^n @"averageOfProperty: is not supported for $type dictionary");
    %noany %noavg %man RLMAssertThrowsWithReason([$dictionary averageOfProperty:@"self"], ^n @"averageOfProperty: is not supported for $type dictionary '$class.$prop'");

    %avg uncheckedAssertNil([$dictionary averageOfProperty:@"self"]);

    [self addObjects];

    %avg XCTAssertEqualWithAccuracy([$dictionary averageOfProperty:@"self"].doubleValue, average($values), .001);
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
    ^{ ^nl NSDictionary *values = $values; ^nl for (id key in $dictionary) { ^nl     id value = $dictionary[key]; ^nl     uncheckedAssertEqualObjects(values[key], value); ^nl } ^nl uncheckedAssertEqual(values.count, $dictionary.count); ^nl }(); ^nl 
}

- (void)testValueForKeyNumericAggregates {
    %minmax uncheckedAssertNil([$dictionary valueForKeyPath:@"@min.self"]);
    %minmax uncheckedAssertNil([$dictionary valueForKeyPath:@"@max.self"]);
    %sum uncheckedAssertEqualObjects([$dictionary valueForKeyPath:@"@sum.self"], @0);
    %avg uncheckedAssertNil([$dictionary valueForKeyPath:@"@avg.self"]);

    [self addObjects];

    %minmax uncheckedAssertEqualObjects([$dictionary valueForKeyPath:@"@min.self"], $v0);
    %r %minmax uncheckedAssertEqualObjects([$dictionary valueForKeyPath:@"@max.self"], $v1);
    %o %minmax uncheckedAssertEqualObjects([$dictionary valueForKeyPath:@"@max.self"], $v0);
    %sum XCTAssertEqualWithAccuracy([[$dictionary valueForKeyPath:@"@sum.self"] doubleValue], sum($values), .001);
    %avg XCTAssertEqualWithAccuracy([[$dictionary valueForKeyPath:@"@avg.self"] doubleValue], average($values), .001);
}

- (void)testSetValueForKey {
    %noany RLMAssertThrowsWithReason([$dictionary setValue:$wrong forKey:$k0], ^n @"Invalid value '$wdesc' of type '" $wtype "' for expected type '$type'");
    %noany %r RLMAssertThrowsWithReason([$dictionary setValue:(id)NSNull.null forKey:@"self"], ^n @"Invalid value '<null>' of type 'NSNull' for expected type '$type'");

    [self addObjects];

    uncheckedAssertEqualObjects($dictionary[$k0], $v0);

    %o [$dictionary setValue:(id)NSNull.null forKey:$k0];
    %o uncheckedAssertEqualObjects($dictionary[$k0], (id)NSNull.null);
}

- (void)testAssignment {
    $dictionary = (id)@{$k1: $v1}; ^nl uncheckedAssertEqualObjects($dictionary[$k1], $v1);

    [unmanaged.intObj removeAllObjects];
    unmanaged.intObj = managed.intObj;

    uncheckedAssertEqual(unmanaged.intObj.count, 1);
    uncheckedAssertEqualObjects(unmanaged.intObj.allValues, managed.intObj.allValues);

    [managed.intObj removeAllObjects];
    managed.intObj = unmanaged.intObj;

    uncheckedAssertEqual(managed.intObj.count, 1);
    uncheckedAssertEqualObjects(managed.intObj.allValues, unmanaged.intObj.allValues);
}

- (void)testInvalidAssignment {
    RLMAssertThrowsWithReason(unmanaged.intObj = (id)@{@"0": (id)NSNull.null},
                              @"Invalid value '<null>' of type 'NSNull' for 'int' dictionary property 'AllPrimitiveDictionaries.intObj'.");
    RLMAssertThrowsWithReason(unmanaged.intObj = (id)@{@"0": @"a"},
                              @"Invalid value 'a' of type '__NSCFConstantString' for 'int' dictionary property 'AllPrimitiveDictionaries.intObj'.");
    RLMAssertThrowsWithReason(unmanaged.intObj = (id)(@{@"0": @1, @"1": @"a"}),
                              @"Invalid value 'a' of type '__NSCFConstantString' for 'int' dictionary property 'AllPrimitiveDictionaries.intObj'.");
    RLMAssertThrowsWithReason(unmanaged.intObj = (id)unmanaged.floatObj,
                              @"RLMDictionary<string, float> does not match expected type 'int' for property 'AllPrimitiveDictionaries.intObj'.");
    RLMAssertThrowsWithReason(unmanaged.intObj = (id)optUnmanaged.intObj,
                              @"RLMDictionary<string, int?> does not match expected type 'int' for property 'AllPrimitiveDictionaries.intObj'.");
    RLMAssertThrowsWithReason(unmanaged[@"intObj"] = unmanaged[@"floatObj"],
                              @"RLMDictionary<string, float> does not match expected type 'int' for property 'AllPrimitiveDictionaries.intObj'.");
    RLMAssertThrowsWithReason(unmanaged[@"intObj"] = optUnmanaged[@"intObj"],
                              @"RLMDictionary<string, int?> does not match expected type 'int' for property 'AllPrimitiveDictionaries.intObj'.");

    RLMAssertThrowsWithReason(managed.intObj = (id)@{@"0": (id)NSNull.null},
                              @"Invalid value '<null>' of type 'NSNull' for 'int' dictionary property 'AllPrimitiveDictionaries.intObj'.");
    RLMAssertThrowsWithReason(managed.intObj = (id)@{@"0": @"a"},
                              @"Invalid value 'a' of type '__NSCFConstantString' for 'int' dictionary property 'AllPrimitiveDictionaries.intObj'.");
    RLMAssertThrowsWithReason(managed.intObj = (id)(@{@"0": @1, @"1": @"a"}),
                              @"Invalid value 'a' of type '__NSCFConstantString' for 'int' dictionary property 'AllPrimitiveDictionaries.intObj'.");
    RLMAssertThrowsWithReason(managed.intObj = (id)managed.floatObj,
                              @"RLMDictionary<string, float> does not match expected type 'int' for property 'AllPrimitiveDictionaries.intObj'.");
    RLMAssertThrowsWithReason(managed.intObj = (id)optManaged.intObj,
                              @"RLMDictionary<string, int?> does not match expected type 'int' for property 'AllPrimitiveDictionaries.intObj'.");
    RLMAssertThrowsWithReason(managed[@"intObj"] = (id)managed[@"floatObj"],
                              @"RLMDictionary<string, float> does not match expected type 'int' for property 'AllPrimitiveDictionaries.intObj'.");
    RLMAssertThrowsWithReason(managed[@"intObj"] = (id)optManaged[@"intObj"],
                              @"RLMDictionary<string, int?> does not match expected type 'int' for property 'AllPrimitiveDictionaries.intObj'.");
}

- (void)testAllMethodsCheckThread {
    RLMDictionary *dictionary = managed.intObj;
    [self dispatchAsyncAndWait:^{
        RLMAssertThrowsWithReason([dictionary count], @"thread");
        RLMAssertThrowsWithReason(dictionary[@"0"], @"thread");
        RLMAssertThrowsWithReason([dictionary count], @"thread");

        RLMAssertThrowsWithReason([dictionary setObject:@0 forKey:@"thread"], @"thread");
        RLMAssertThrowsWithReason([dictionary addEntriesFromDictionary:@{@"thread": @0}], @"thread");
        RLMAssertThrowsWithReason([dictionary removeObjectForKey:@"thread"], @"thread");
        RLMAssertThrowsWithReason([dictionary removeObjectsForKeys:(id)@[@"thread"]], @"thread");
        RLMAssertThrowsWithReason([dictionary removeAllObjects], @"thread");
        RLMAssertThrowsWithReason([optManaged.intObj setObject:(id)NSNull.null forKey:@"thread"], @"thread");

        RLMAssertThrowsWithReason([dictionary sortedResultsUsingKeyPath:@"self" ascending:YES], @"thread");
        RLMAssertThrowsWithReason([dictionary sortedResultsUsingDescriptors:@[[RLMSortDescriptor sortDescriptorWithKeyPath:@"self" ascending:YES]]], @"thread");
        RLMAssertThrowsWithReason(dictionary[@"thread"], @"thread");
        RLMAssertThrowsWithReason(dictionary[@"thread"] = @0, @"thread");
        RLMAssertThrowsWithReason([dictionary valueForKey:@"self"], @"thread");
        RLMAssertThrowsWithReason([dictionary setValue:@1 forKey:@"self"], @"thread");
        RLMAssertThrowsWithReason(({for (__unused id obj in dictionary);}), @"thread");
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
    uncheckedAssertNil(dictionary[@"0"]);
    RLMAssertThrowsWithReason([dictionary count], @"invalidated");

    RLMAssertThrowsWithReason([dictionary setObject:@0 forKey:@"thread"], @"invalidated");
    RLMAssertThrowsWithReason([dictionary addEntriesFromDictionary:@{@"invalidated": @0}], @"invalidated");
    RLMAssertThrowsWithReason([dictionary removeObjectForKey:@"invalidated"], @"invalidated");
    RLMAssertThrowsWithReason([dictionary removeObjectsForKeys:(id)@[@"invalidated"]], @"invalidated");
    RLMAssertThrowsWithReason([dictionary removeAllObjects], @"invalidated");
    RLMAssertThrowsWithReason([optManaged.intObj setObject:(id)NSNull.null forKey:@"invalidated"], @"invalidated");

    RLMAssertThrowsWithReason([dictionary sortedResultsUsingKeyPath:@"self" ascending:YES], @"invalidated");
    RLMAssertThrowsWithReason([dictionary sortedResultsUsingDescriptors:@[[RLMSortDescriptor sortDescriptorWithKeyPath:@"self" ascending:YES]]], @"invalidated");
    RLMAssertThrowsWithReason(dictionary[@"invalidated"] = @0, @"invalidated");
    uncheckedAssertNil([dictionary valueForKey:@"self"]);
    RLMAssertThrowsWithReason([dictionary setValue:@1 forKey:@"self"], @"invalidated");
    RLMAssertThrowsWithReason(({for (__unused id obj in dictionary);}), @"invalidated");

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
    XCTAssertNoThrow(dictionary[@"0"]);
    XCTAssertNoThrow([dictionary count]);

    XCTAssertNoThrow([dictionary sortedResultsUsingKeyPath:@"self" ascending:YES]);
    XCTAssertNoThrow([dictionary sortedResultsUsingDescriptors:@[[RLMSortDescriptor sortDescriptorWithKeyPath:@"self" ascending:YES]]]);
    XCTAssertNoThrow(dictionary[@"0"]);
    XCTAssertNoThrow([dictionary valueForKey:@"self"]);
    XCTAssertNoThrow(({for (__unused id obj in dictionary);}));

    RLMAssertThrowsWithReason([dictionary setObject:@0 forKey:@"testKey"], @"write transaction");
    RLMAssertThrowsWithReason([dictionary addEntriesFromDictionary:@{@"testKey": @0}], @"write transaction");
    RLMAssertThrowsWithReason([dictionary removeObjectForKey:@"testKey"], @"write transaction");
    RLMAssertThrowsWithReason([dictionary removeObjectsForKeys:(id)@[@"testKey"]], @"write transaction");
    RLMAssertThrowsWithReason([dictionary removeAllObjects], @"write transaction");
    RLMAssertThrowsWithReason([optManaged.intObj setObject:(id)NSNull.null forKey:@"testKey"], @"write transaction");

    RLMAssertThrowsWithReason(dictionary[@"testKey"] = @0, @"write transaction");
    RLMAssertThrowsWithReason([dictionary setValue:@1 forKey:@"self"], @"write transaction");
}

- (void)testDeleteOwningObject {
    RLMDictionary *dictionary = managed.intObj;
    uncheckedAssertFalse(dictionary.isInvalidated);
    [realm deleteObject:managed];
    uncheckedAssertTrue(dictionary.isInvalidated);
}

#pragma clang diagnostic ignored "-Warc-retain-cycles"

- (void)testNotificationSentInitially {
    [realm commitWriteTransaction];

    id expectation = [self expectationWithDescription:@""];
    id token = [managed.intObj addNotificationBlock:^(RLMDictionary *dictionary, RLMDictionaryChange *change, NSError *error) {
        XCTAssertNotNil(dictionary);
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
    __block bool second = false;
    __block id expectation = [self expectationWithDescription:@""];
    id token = [managed.intObj addNotificationBlock:^(RLMDictionary *dictionary, RLMDictionaryChange *change, NSError *error) {
        XCTAssertNotNil(dictionary);
        uncheckedAssertNil(error);
        if (first) {
            uncheckedAssertNil(change);
        }
        else if (!second) {
            uncheckedAssertEqualObjects(change.insertions, @[@"testKey"]);
        } else {
            uncheckedAssertEqualObjects(change.deletions, @[@"testKey"]);
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

    second = true;
    expectation = [self expectationWithDescription:@""];
    [self dispatchAsyncAndWait:^{
        RLMRealm *r = [RLMRealm defaultRealm];
        [r transactionWithBlock:^{
            RLMDictionary *dictionary = [(AllPrimitiveDictionaries *)[AllPrimitiveDictionaries allObjectsInRealm:r].firstObject intObj];
            [dictionary removeObjectForKey:@"testKey"];
        }];
    }];
    [self waitForExpectationsWithTimeout:2.0 handler:nil];

    [(RLMNotificationToken *)token invalidate];
}

- (void)testNotificationNotSentForUnrelatedChange {
    [realm commitWriteTransaction];

    id expectation = [self expectationWithDescription:@""];
    id token = [managed.intObj addNotificationBlock:^(__unused RLMDictionary *dictionary, __unused RLMDictionaryChange *change, __unused NSError *error) {
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
    id token = [managed.intObj addNotificationBlock:^(RLMDictionary *dictionary, __unused RLMDictionaryChange *change, NSError *error) {
        XCTAssertNotNil(dictionary);
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
#pragma mark - Queries

#define RLMAssertCount(cls, expectedCount, ...) \
    uncheckedAssertEqual(expectedCount, ([cls objectsInRealm:realm where:__VA_ARGS__].count))

- (void)createObject {
    %r %man id $prop = @{$k0: $v0};

    id obj = [AllPrimitiveDictionaries createInRealm:realm withValue: @{
        %r %man @"$prop": $prop,
    }];
    [LinkToAllPrimitiveDictionaries createInRealm:realm withValue:@[obj]];
    obj = [AllOptionalPrimitiveDictionaries createInRealm:realm withValue:@{
        %o %man @"$prop": $prop,
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

    [self createObject];

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

    %nostring %noany %man %nominmax RLMAssertThrowsWithReason(([$class objectsInRealm:realm where:@"ANY $prop > %@", $v0]), ^n @"Operator '>' not supported for type '$basetype'");
    %string %noany %man %nominmax RLMAssertThrowsWithReason(([$class objectsInRealm:realm where:@"ANY $prop > %@", $v0]), ^n @"Operator '>' not supported for string queries on Dictionary.");
    %any %string %man %nominmax RLMAssertThrowsWithReason(([$class objectsInRealm:realm where:@"ANY $prop > %@", $v0]), ^n @"Operator '>' not supported for string queries on Dictionary.");
}

- (void)testQueryBetween {
    [realm deleteAllObjects];

    %noany %man %nominmax RLMAssertThrowsWithReason(([$class objectsInRealm:realm where:@"ANY $prop BETWEEN %@", @[$v0, $v1]]), ^n @"Operator 'BETWEEN' not supported for type '$basetype'");

    %man %minmax RLMAssertCount($class, 0, @"ANY $prop BETWEEN %@", @[$v0, $v1]);

    [self createObject];

    %r %man %minmax RLMAssertCount($class, 1, @"ANY $prop BETWEEN %@", @[$v0, $v0]);
    %r %man %minmax RLMAssertCount($class, 1, @"ANY $prop BETWEEN %@", @[$v0, $v1]);
    %r %man %minmax RLMAssertCount($class, 0, @"ANY $prop BETWEEN %@", @[$v1, $v1]);
    %o %man %minmax RLMAssertCount($class, 1, @"ANY $prop BETWEEN %@", @[$v0, $v0]);
    %o %man %minmax RLMAssertCount($class, 0, @"ANY $prop BETWEEN %@", @[$v0, $v1]);
    %o %man %minmax RLMAssertCount($class, 0, @"ANY $prop BETWEEN %@", @[$v1, $v1]);
}

- (void)testQueryIn {
    [realm deleteAllObjects];

    %man RLMAssertCount($class, 0, @"ANY $prop IN %@", @[$v0, $v1]);

    [self createObject];

    %man RLMAssertCount($class, 0, @"ANY $prop IN %@", @[$v1]);
    %man RLMAssertCount($class, 1, @"ANY $prop IN %@", @[$v0, $v1]);
}

- (void)testQueryCount {
    [realm deleteAllObjects];

    [AllPrimitiveDictionaries createInRealm:realm withValue:@{
        %r %man @"$prop": $values,
    }];
    [AllOptionalPrimitiveDictionaries createInRealm:realm withValue:@{
        %o %man @"$prop": $values,
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
    %date %man RLMAssertThrowsWithReason(([$class objectsInRealm:realm where:@"$prop.@sum = %@", $v0]), ^n @"Cannot sum or average date properties");

    %noany %sum %man RLMAssertThrowsWithReason(([$class objectsInRealm:realm where:@"$prop.@sum = %@", $wrong]), ^n @"@sum on a property of type $basetype cannot be compared with '$wdesc'");
    %sum %man RLMAssertThrowsWithReason(([$class objectsInRealm:realm where:@"$prop.@sum.prop = %@", $wrong]), ^n @"Property '$prop' is not a link in object of type '$class'");
    %sum %man RLMAssertThrowsWithReason(([$class objectsInRealm:realm where:@"$prop.@sum = %@", (id)NSNull.null]), ^n @"@sum on a property of type $basetype cannot be compared with '<null>'");

    [AllPrimitiveDictionaries createInRealm:realm withValue:@{
        %man %r %sum @"$prop": @{},
    }];
    [AllOptionalPrimitiveDictionaries createInRealm:realm withValue:@{
        %man %o %sum @"$prop": @{},
    }];
    [AllPrimitiveDictionaries createInRealm:realm withValue:@{
        %man %r %sum @"$prop": @{$k0: $v0},
    }];
    [AllOptionalPrimitiveDictionaries createInRealm:realm withValue:@{
        %man %o %sum @"$prop": @{$k0: $v0},
    }];
    [AllPrimitiveDictionaries createInRealm:realm withValue:@{
        %man %r %sum @"$prop": $values,
    }];
    [AllOptionalPrimitiveDictionaries createInRealm:realm withValue:@{
        %man %o %sum @"$prop": $values,
    }];
    [AllPrimitiveDictionaries createInRealm:realm withValue:@{
        %man %r %sum @"$prop": $values,
    }];
    [AllOptionalPrimitiveDictionaries createInRealm:realm withValue:@{
        %man %o %sum @"$prop": $values,
    }];

    %sum %man RLMAssertCount($class, 1U, @"$prop.@sum == %@", @0);
    %r %sum %man RLMAssertCount($class, 1U, @"$prop.@sum == %@", $v0);
    %o %sum %man RLMAssertCount($class, 3U, @"$prop.@sum == %@", $v0);
    %r %sum %man RLMAssertCount($class, 3U, @"$prop.@sum != %@", $v0);
    %o %sum %man RLMAssertCount($class, 1U, @"$prop.@sum != %@", $v0);
    %sum %man RLMAssertCount($class, 3U, @"$prop.@sum >= %@", $v0);
    %r %sum %man RLMAssertCount($class, 2U, @"$prop.@sum > %@", $v0);
    %o %sum %man RLMAssertCount($class, 0U, @"$prop.@sum > %@", $v0);
    %r %sum %man RLMAssertCount($class, 2U, @"$prop.@sum < %@", $v1);
    %o %sum %man RLMAssertCount($class, 1U, @"$prop.@sum < %@", $v0);
    %r %sum %man RLMAssertCount($class, 2U, @"$prop.@sum <= %@", $v1);
    %o %sum %man RLMAssertCount($class, 4U, @"$prop.@sum <= %@", $v0);
}

- (void)testQueryAverage {
    [realm deleteAllObjects];

    %noany %nodate %noavg %man RLMAssertThrowsWithReason(([$class objectsInRealm:realm where:@"$prop.@avg = %@", $v0]), ^n @"@avg can only be applied to a numeric property.");
    %date %man RLMAssertThrowsWithReason(([$class objectsInRealm:realm where:@"$prop.@avg = %@", $v0]), ^n @"Cannot sum or average date properties");

    %noany %avg %man RLMAssertThrowsWithReason(([$class objectsInRealm:realm where:@"$prop.@avg = %@", $wrong]), ^n @"@avg on a property of type $basetype cannot be compared with '$wdesc'");
    %avg %man RLMAssertThrowsWithReason(([$class objectsInRealm:realm where:@"$prop.@avg.prop = %@", $wrong]), ^n @"Property '$prop' is not a link in object of type '$class'");

    [AllPrimitiveDictionaries createInRealm:realm withValue:@{
        %man %r %avg @"$prop": @{},
    }];
    [AllOptionalPrimitiveDictionaries createInRealm:realm withValue:@{
        %man %o %avg @"$prop": @{},
    }];
    [AllPrimitiveDictionaries createInRealm:realm withValue:@{
        %man %r %avg @"$prop": @{$k0: $v0},
    }];
    [AllOptionalPrimitiveDictionaries createInRealm:realm withValue:@{
        %man %o %avg @"$prop": @{$k0: $v0},
    }];
    [AllPrimitiveDictionaries createInRealm:realm withValue:@{
        %man %r %avg @"$prop": $values,
    }];
    [AllOptionalPrimitiveDictionaries createInRealm:realm withValue:@{
        %man %o %avg @"$prop": $values,
    }];
    [AllPrimitiveDictionaries createInRealm:realm withValue:@{
        %man %r %avg @"$prop": @{$k0: $v1},
    }];
    [AllOptionalPrimitiveDictionaries createInRealm:realm withValue:@{
        %man %o %avg @"$prop": @{$k0: $v0},
    }];

    %avg %man RLMAssertCount($class, 1U, @"$prop.@avg == %@", NSNull.null);
    %r %avg %man RLMAssertCount($class, 1U, @"$prop.@avg == %@", $v0);
    %o %avg %man RLMAssertCount($class, 3U, @"$prop.@avg == %@", $v0);
    %r %avg %man RLMAssertCount($class, 3U, @"$prop.@avg != %@", $v0);
    %o %avg %man RLMAssertCount($class, 1U, @"$prop.@avg != %@", $v0);
    %avg %man RLMAssertCount($class, 3U, @"$prop.@avg >= %@", $v0);
    %r %avg %man RLMAssertCount($class, 2U, @"$prop.@avg > %@", $v0);
    %o %avg %man RLMAssertCount($class, 0U, @"$prop.@avg > %@", $v0);
    %r %avg %man RLMAssertCount($class, 2U, @"$prop.@avg < %@", $v1);
    %o %avg %man RLMAssertCount($class, 0U, @"$prop.@avg < %@", $v0);
    %r %avg %man RLMAssertCount($class, 3U, @"$prop.@avg <= %@", $v1);
    %o %avg %man RLMAssertCount($class, 1U, @"$prop.@avg <= %@", $v1);
    %o %avg %man RLMAssertCount($class, 3U, @"$prop.@avg <= %@", $v0);
}

- (void)testQueryMin {
    [realm deleteAllObjects];

    %noany %nominmax %man RLMAssertThrowsWithReason(([$class objectsInRealm:realm where:@"$prop.@min = %@", $v0]), ^n @"@min can only be applied to a numeric property.");
    %noany %minmax %man RLMAssertThrowsWithReason(([$class objectsInRealm:realm where:@"$prop.@min = %@", $wrong]), ^n @"@min on a property of type $basetype cannot be compared with '$wdesc'");
    %minmax %man RLMAssertThrowsWithReason(([$class objectsInRealm:realm where:@"$prop.@min.prop = %@", $wrong]), ^n @"Property '$prop' is not a link in object of type '$class'");

    // No objects, so count is zero
    %minmax %man RLMAssertCount($class, 0U, @"$prop.@min == %@", $v0);

    [AllPrimitiveDictionaries createInRealm:realm withValue:@{}];
    [AllOptionalPrimitiveDictionaries createInRealm:realm withValue:@{}];

    // Only empty dictionarys, so count is zero
    %minmax %man RLMAssertCount($class, 0U, @"$prop.@min == %@", $v0);
    %r %minmax %man RLMAssertCount($class, 0U, @"$prop.@min == %@", $v1);
    %o %minmax %man RLMAssertCount($class, 1U, @"$prop.@min == %@", $v1);

    %minmax %man RLMAssertCount($class, 1U, @"$prop.@min == nil");
    %minmax %man RLMAssertCount($class, 1U, @"$prop.@min == %@", NSNull.null);

    [self createObject];

    // One object where v0 is min and zero with v1
    %minmax %man RLMAssertCount($class, 1U, @"$prop.@min == %@", $v0);
    %r %minmax %man RLMAssertCount($class, 0U, @"$prop.@min == %@", $v1);
    %o %minmax %man RLMAssertCount($class, 1U, @"$prop.@min == %@", $v1);
}

- (void)testQueryMax {
    [realm deleteAllObjects];

    %noany %nominmax %man RLMAssertThrowsWithReason(([$class objectsInRealm:realm where:@"$prop.@max = %@", $v0]), ^n @"@max can only be applied to a numeric property.");
    %noany %minmax %man RLMAssertThrowsWithReason(([$class objectsInRealm:realm where:@"$prop.@max = %@", $wrong]), ^n @"@max on a property of type $basetype cannot be compared with '$wdesc'");
    %minmax %man RLMAssertThrowsWithReason(([$class objectsInRealm:realm where:@"$prop.@max.prop = %@", $wrong]), ^n @"Property '$prop' is not a link in object of type '$class'");

    // No objects, so count is zero
    %minmax %man RLMAssertCount($class, 0U, @"$prop.@max == %@", $v0);

    [AllPrimitiveDictionaries createInRealm:realm withValue:@{}];
    [AllOptionalPrimitiveDictionaries createInRealm:realm withValue:@{}];

    // Only empty dictionarys, so count is zero.
    %r %minmax %man RLMAssertCount($class, 0U, @"$prop.@max == %@", $v0);
    %r %minmax %man RLMAssertCount($class, 0U, @"$prop.@max == %@", $v1);

    %o %minmax %man RLMAssertCount($class, 0U, @"$prop.@max == %@", $v0);
    %o %minmax %man RLMAssertCount($class, 1U, @"$prop.@max == %@", $v1);

    %minmax %man RLMAssertCount($class, 1U, @"$prop.@max == nil");
    %minmax %man RLMAssertCount($class, 1U, @"$prop.@max == %@", NSNull.null);

    [self createObject];

    // One object where v0 is min and zero with v1
    %minmax %man RLMAssertCount($class, 1U, @"$prop.@max == %@", $v0);
    %r %minmax %man RLMAssertCount($class, 0U, @"$prop.@max == %@", $v1);
    %o %minmax %man RLMAssertCount($class, 1U, @"$prop.@max == %@", $v1);
}

- (void)testQueryBasicOperatorsOverLink {
    [realm deleteAllObjects];

    %man RLMAssertCount(LinkTo$class, 0, @"ANY link.$prop = %@", $v0);
    %man RLMAssertCount(LinkTo$class, 0, @"ANY link.$prop != %@", $v0);
    %man %minmax RLMAssertCount(LinkTo$class, 0, @"ANY link.$prop > %@", $v0);
    %man %minmax RLMAssertCount(LinkTo$class, 0, @"ANY link.$prop >= %@", $v0);
    %man %minmax RLMAssertCount(LinkTo$class, 0, @"ANY link.$prop < %@", $v0);
    %man %minmax RLMAssertCount(LinkTo$class, 0, @"ANY link.$prop <= %@", $v0);

    [self createObject];

    %man RLMAssertCount(LinkTo$class, 0, @"ANY link.$prop = %@", $v1);
    %man RLMAssertCount(LinkTo$class, 1, @"ANY link.$prop = %@", $v0);
    %man RLMAssertCount(LinkTo$class, 0, @"ANY link.$prop != %@", $v0);
    %man RLMAssertCount(LinkTo$class, 1, @"ANY link.$prop != %@", $v1);
    %man %minmax RLMAssertCount(LinkTo$class, 0, @"ANY link.$prop > %@", $v0);
    %man %minmax RLMAssertCount(LinkTo$class, 1, @"ANY link.$prop >= %@", $v0);
    %man %minmax RLMAssertCount(LinkTo$class, 0, @"ANY link.$prop < %@", $v0);
    %r %man %minmax RLMAssertCount(LinkTo$class, 1, @"ANY link.$prop < %@", $v1);
    %o %man %minmax RLMAssertCount(LinkTo$class, 0, @"ANY link.$prop < %@", $v1);
    %man %minmax RLMAssertCount(LinkTo$class, 1, @"ANY link.$prop <= %@", $v0);

    %noany %nostring %man %nominmax RLMAssertThrowsWithReason(([LinkTo$class objectsInRealm:realm where:@"ANY link.$prop > %@", $v0]), ^n @"Operator '>' not supported for type '$basetype'");
    %string %man %nominmax RLMAssertThrowsWithReason(([LinkTo$class objectsInRealm:realm where:@"ANY link.$prop > %@", $v0]), ^n @"Operator '>' not supported for string queries on Dictionary.");
}

- (void)testSubstringQueries {
    [realm deleteAllObjects];
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
            @"stringObj": @{@"key": value},
            @"dataObj": @{@"key": [value dataUsingEncoding:NSUTF8StringEncoding]}
        }];
        [LinkToAllPrimitiveDictionaries createInRealm:realm withValue:@[obj]];
        obj = [AllOptionalPrimitiveDictionaries createInRealm:realm withValue:@{
            @"stringObj": @{@"key": value},
            @"dataObj": @{@"key": [value dataUsingEncoding:NSUTF8StringEncoding]}
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
