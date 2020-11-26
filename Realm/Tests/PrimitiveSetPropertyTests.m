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
        unmanaged.boolObj,
        unmanaged.intObj,
        unmanaged.floatObj,
        unmanaged.doubleObj,
        unmanaged.stringObj,
        unmanaged.dataObj,
        unmanaged.dateObj,
        unmanaged.decimalObj,
        unmanaged.objectIdObj,
        optUnmanaged.boolObj,
        optUnmanaged.intObj,
        optUnmanaged.floatObj,
        optUnmanaged.doubleObj,
        optUnmanaged.stringObj,
        optUnmanaged.dataObj,
        optUnmanaged.dateObj,
        optUnmanaged.decimalObj,
        optUnmanaged.objectIdObj,
        managed.boolObj,
        managed.intObj,
        managed.floatObj,
        managed.doubleObj,
        managed.stringObj,
        managed.dataObj,
        managed.dateObj,
        managed.decimalObj,
        managed.objectIdObj,
        optManaged.boolObj,
        optManaged.intObj,
        optManaged.floatObj,
        optManaged.doubleObj,
        optManaged.stringObj,
        optManaged.dataObj,
        optManaged.dateObj,
        optManaged.decimalObj,
        optManaged.objectIdObj,
    ];
}

- (void)tearDown {
    if (realm.inWriteTransaction) {
        [realm cancelWriteTransaction];
    }
}

- (void)addObjects {
    [unmanaged.boolObj addObjects:@[@NO, @YES]];
    [unmanaged.intObj addObjects:@[@2, @3]];
    [unmanaged.floatObj addObjects:@[@2.2f, @3.3f]];
    [unmanaged.doubleObj addObjects:@[@2.2, @3.3]];
    [unmanaged.stringObj addObjects:@[@"a", @"b"]];
    [unmanaged.dataObj addObjects:@[data(1), data(2)]];
    [unmanaged.dateObj addObjects:@[date(1), date(2)]];
    [unmanaged.decimalObj addObjects:@[decimal128(1), decimal128(2)]];
    [unmanaged.objectIdObj addObjects:@[objectId(1), objectId(2)]];
    [optUnmanaged.boolObj addObjects:@[@NO, @YES, NSNull.null]];
    [optUnmanaged.intObj addObjects:@[@2, @3, NSNull.null]];
    [optUnmanaged.floatObj addObjects:@[@2.2f, @3.3f, NSNull.null]];
    [optUnmanaged.doubleObj addObjects:@[@2.2, @3.3, NSNull.null]];
    [optUnmanaged.stringObj addObjects:@[@"a", @"b", NSNull.null]];
    [optUnmanaged.dataObj addObjects:@[data(1), data(2), NSNull.null]];
    [optUnmanaged.dateObj addObjects:@[date(1), date(2), NSNull.null]];
    [optUnmanaged.decimalObj addObjects:@[decimal128(1), decimal128(2), NSNull.null]];
    [optUnmanaged.objectIdObj addObjects:@[objectId(1), objectId(2), NSNull.null]];
    [managed.boolObj addObjects:@[@NO, @YES]];
    [managed.intObj addObjects:@[@2, @3]];
    [managed.floatObj addObjects:@[@2.2f, @3.3f]];
    [managed.doubleObj addObjects:@[@2.2, @3.3]];
    [managed.stringObj addObjects:@[@"a", @"b"]];
    [managed.dataObj addObjects:@[data(1), data(2)]];
    [managed.dateObj addObjects:@[date(1), date(2)]];
    [managed.decimalObj addObjects:@[decimal128(1), decimal128(2)]];
    [managed.objectIdObj addObjects:@[objectId(1), objectId(2)]];
    [optManaged.boolObj addObjects:@[@NO, @YES, NSNull.null]];
    [optManaged.intObj addObjects:@[@2, @3, NSNull.null]];
    [optManaged.floatObj addObjects:@[@2.2f, @3.3f, NSNull.null]];
    [optManaged.doubleObj addObjects:@[@2.2, @3.3, NSNull.null]];
    [optManaged.stringObj addObjects:@[@"a", @"b", NSNull.null]];
    [optManaged.dataObj addObjects:@[data(1), data(2), NSNull.null]];
    [optManaged.dateObj addObjects:@[date(1), date(2), NSNull.null]];
    [optManaged.decimalObj addObjects:@[decimal128(1), decimal128(2), NSNull.null]];
    [optManaged.objectIdObj addObjects:@[objectId(1), objectId(2), NSNull.null]];
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
    RLMSet *set;
    @autoreleasepool {
        AllPrimitiveSets *obj = [[AllPrimitiveSets alloc] init];
        set = obj.intObj;
        XCTAssertFalse(set.invalidated);
    }
    XCTAssertFalse(set.invalidated);
}

- (void)testDeleteObjectsInRealm {
    for (RLMSet *set in allSets) {
        RLMAssertThrowsWithReason([realm deleteObjects:set], @"Cannot delete objects from RLMSet");
    }
}

- (void)testObjectAtIndex {
    RLMAssertThrowsWithReason([unmanaged.intObj objectAtIndex:0],
                              @"Index 0 is out of bounds (must be less than 0).");

    [unmanaged.intObj addObject:@1];
    XCTAssertEqualObjects([unmanaged.intObj objectAtIndex:0], @1);
}

- (void)testFirstObject {
    for (RLMSet *set in allSets) {
        XCTAssertNil(set.firstObject);
    }

    [self addObjects];
    XCTAssertEqualObjects(unmanaged.boolObj.firstObject, @NO);
    XCTAssertEqualObjects(unmanaged.intObj.firstObject, @2);
    XCTAssertEqualObjects(unmanaged.floatObj.firstObject, @2.2f);
    XCTAssertEqualObjects(unmanaged.doubleObj.firstObject, @2.2);
    XCTAssertEqualObjects(unmanaged.stringObj.firstObject, @"a");
    XCTAssertEqualObjects(unmanaged.dataObj.firstObject, data(1));
    XCTAssertEqualObjects(unmanaged.dateObj.firstObject, date(1));
    XCTAssertEqualObjects(unmanaged.decimalObj.firstObject, decimal128(1));
    XCTAssertEqualObjects(unmanaged.objectIdObj.firstObject, objectId(1));
    XCTAssertEqualObjects(optUnmanaged.boolObj.firstObject, @NO);
    XCTAssertEqualObjects(optUnmanaged.intObj.firstObject, @2);
    XCTAssertEqualObjects(optUnmanaged.floatObj.firstObject, @2.2f);
    XCTAssertEqualObjects(optUnmanaged.doubleObj.firstObject, @2.2);
    XCTAssertEqualObjects(optUnmanaged.stringObj.firstObject, @"a");
    XCTAssertEqualObjects(optUnmanaged.dataObj.firstObject, data(1));
    XCTAssertEqualObjects(optUnmanaged.dateObj.firstObject, date(1));
    XCTAssertEqualObjects(optUnmanaged.decimalObj.firstObject, decimal128(1));
    XCTAssertEqualObjects(optUnmanaged.objectIdObj.firstObject, objectId(1));
    XCTAssertEqualObjects(managed.boolObj.firstObject, @NO);
    XCTAssertEqualObjects(managed.intObj.firstObject, @2);
    XCTAssertEqualObjects(managed.floatObj.firstObject, @2.2f);
    XCTAssertEqualObjects(managed.doubleObj.firstObject, @2.2);
    XCTAssertEqualObjects(managed.stringObj.firstObject, @"a");
    XCTAssertEqualObjects(managed.dataObj.firstObject, data(1));
    XCTAssertEqualObjects(managed.dateObj.firstObject, date(1));
    XCTAssertEqualObjects(managed.decimalObj.firstObject, decimal128(1));
    XCTAssertEqualObjects(managed.objectIdObj.firstObject, objectId(1));
    XCTAssertEqualObjects(optManaged.boolObj.firstObject, @NO);
    XCTAssertEqualObjects(optManaged.intObj.firstObject, @2);
    XCTAssertEqualObjects(optManaged.floatObj.firstObject, @2.2f);
    XCTAssertEqualObjects(optManaged.doubleObj.firstObject, @2.2);
    XCTAssertEqualObjects(optManaged.stringObj.firstObject, @"a");
    XCTAssertEqualObjects(optManaged.dataObj.firstObject, data(1));
    XCTAssertEqualObjects(optManaged.dateObj.firstObject, date(1));
    XCTAssertEqualObjects(optManaged.decimalObj.firstObject, decimal128(1));
    XCTAssertEqualObjects(optManaged.objectIdObj.firstObject, objectId(1));

    for (RLMSet *set in allSets) {
        [set removeAllObjects];
    }

    [optUnmanaged.boolObj addObject:NSNull.null];
    [optUnmanaged.intObj addObject:NSNull.null];
    [optUnmanaged.floatObj addObject:NSNull.null];
    [optUnmanaged.doubleObj addObject:NSNull.null];
    [optUnmanaged.stringObj addObject:NSNull.null];
    [optUnmanaged.dataObj addObject:NSNull.null];
    [optUnmanaged.dateObj addObject:NSNull.null];
    [optUnmanaged.decimalObj addObject:NSNull.null];
    [optUnmanaged.objectIdObj addObject:NSNull.null];
    [optManaged.boolObj addObject:NSNull.null];
    [optManaged.intObj addObject:NSNull.null];
    [optManaged.floatObj addObject:NSNull.null];
    [optManaged.doubleObj addObject:NSNull.null];
    [optManaged.stringObj addObject:NSNull.null];
    [optManaged.dataObj addObject:NSNull.null];
    [optManaged.dateObj addObject:NSNull.null];
    [optManaged.decimalObj addObject:NSNull.null];
    [optManaged.objectIdObj addObject:NSNull.null];
    XCTAssertEqualObjects(optUnmanaged.boolObj.firstObject, NSNull.null);
    XCTAssertEqualObjects(optUnmanaged.intObj.firstObject, NSNull.null);
    XCTAssertEqualObjects(optUnmanaged.floatObj.firstObject, NSNull.null);
    XCTAssertEqualObjects(optUnmanaged.doubleObj.firstObject, NSNull.null);
    XCTAssertEqualObjects(optUnmanaged.stringObj.firstObject, NSNull.null);
    XCTAssertEqualObjects(optUnmanaged.dataObj.firstObject, NSNull.null);
    XCTAssertEqualObjects(optUnmanaged.dateObj.firstObject, NSNull.null);
    XCTAssertEqualObjects(optUnmanaged.decimalObj.firstObject, NSNull.null);
    XCTAssertEqualObjects(optUnmanaged.objectIdObj.firstObject, NSNull.null);
    XCTAssertEqualObjects(optManaged.boolObj.firstObject, NSNull.null);
    XCTAssertEqualObjects(optManaged.intObj.firstObject, NSNull.null);
    XCTAssertEqualObjects(optManaged.floatObj.firstObject, NSNull.null);
    XCTAssertEqualObjects(optManaged.doubleObj.firstObject, NSNull.null);
    XCTAssertEqualObjects(optManaged.stringObj.firstObject, NSNull.null);
    XCTAssertEqualObjects(optManaged.dataObj.firstObject, NSNull.null);
    XCTAssertEqualObjects(optManaged.dateObj.firstObject, NSNull.null);
    XCTAssertEqualObjects(optManaged.decimalObj.firstObject, NSNull.null);
    XCTAssertEqualObjects(optManaged.objectIdObj.firstObject, NSNull.null);
}

- (void)testLastObject {
    for (RLMSet *set in allSets) {
        XCTAssertNil(set.lastObject);
    }

    [self addObjects];

    XCTAssertEqualObjects(unmanaged.boolObj.lastObject, @YES);
    XCTAssertEqualObjects(unmanaged.intObj.lastObject, @3);
    XCTAssertEqualObjects(unmanaged.floatObj.lastObject, @3.3f);
    XCTAssertEqualObjects(unmanaged.doubleObj.lastObject, @3.3);
    XCTAssertEqualObjects(unmanaged.stringObj.lastObject, @"b");
    XCTAssertEqualObjects(unmanaged.dataObj.lastObject, data(2));
    XCTAssertEqualObjects(unmanaged.dateObj.lastObject, date(2));
    XCTAssertEqualObjects(unmanaged.decimalObj.lastObject, decimal128(2));
    XCTAssertEqualObjects(unmanaged.objectIdObj.lastObject, objectId(2));
    XCTAssertEqualObjects(optUnmanaged.boolObj.lastObject, NSNull.null);
    XCTAssertEqualObjects(optUnmanaged.intObj.lastObject, NSNull.null);
    XCTAssertEqualObjects(optUnmanaged.floatObj.lastObject, NSNull.null);
    XCTAssertEqualObjects(optUnmanaged.doubleObj.lastObject, NSNull.null);
    XCTAssertEqualObjects(optUnmanaged.stringObj.lastObject, NSNull.null);
    XCTAssertEqualObjects(optUnmanaged.dataObj.lastObject, NSNull.null);
    XCTAssertEqualObjects(optUnmanaged.dateObj.lastObject, NSNull.null);
    XCTAssertEqualObjects(optUnmanaged.decimalObj.lastObject, NSNull.null);
    XCTAssertEqualObjects(optUnmanaged.objectIdObj.lastObject, NSNull.null);
    XCTAssertEqualObjects(managed.boolObj.lastObject, @YES);
    XCTAssertEqualObjects(managed.intObj.lastObject, @3);
    XCTAssertEqualObjects(managed.floatObj.lastObject, @3.3f);
    XCTAssertEqualObjects(managed.doubleObj.lastObject, @3.3);
    XCTAssertEqualObjects(managed.stringObj.lastObject, @"b");
    XCTAssertEqualObjects(managed.dataObj.lastObject, data(2));
    XCTAssertEqualObjects(managed.dateObj.lastObject, date(2));
    XCTAssertEqualObjects(managed.decimalObj.lastObject, decimal128(2));
    XCTAssertEqualObjects(managed.objectIdObj.lastObject, objectId(2));
    XCTAssertEqualObjects(optManaged.boolObj.lastObject, NSNull.null);
    XCTAssertEqualObjects(optManaged.intObj.lastObject, NSNull.null);
    XCTAssertEqualObjects(optManaged.floatObj.lastObject, NSNull.null);
    XCTAssertEqualObjects(optManaged.doubleObj.lastObject, NSNull.null);
    XCTAssertEqualObjects(optManaged.stringObj.lastObject, NSNull.null);
    XCTAssertEqualObjects(optManaged.dataObj.lastObject, NSNull.null);
    XCTAssertEqualObjects(optManaged.dateObj.lastObject, NSNull.null);
    XCTAssertEqualObjects(optManaged.decimalObj.lastObject, NSNull.null);
    XCTAssertEqualObjects(optManaged.objectIdObj.lastObject, NSNull.null);

    for (RLMSet *set in allSets) {
        [set removeLastObject];
    }
    XCTAssertEqualObjects(optUnmanaged.boolObj.lastObject, @YES);
    XCTAssertEqualObjects(optUnmanaged.intObj.lastObject, @3);
    XCTAssertEqualObjects(optUnmanaged.floatObj.lastObject, @3.3f);
    XCTAssertEqualObjects(optUnmanaged.doubleObj.lastObject, @3.3);
    XCTAssertEqualObjects(optUnmanaged.stringObj.lastObject, @"b");
    XCTAssertEqualObjects(optUnmanaged.dataObj.lastObject, data(2));
    XCTAssertEqualObjects(optUnmanaged.dateObj.lastObject, date(2));
    XCTAssertEqualObjects(optUnmanaged.decimalObj.lastObject, decimal128(2));
    XCTAssertEqualObjects(optUnmanaged.objectIdObj.lastObject, objectId(2));
    XCTAssertEqualObjects(optManaged.boolObj.lastObject, @YES);
    XCTAssertEqualObjects(optManaged.intObj.lastObject, @3);
    XCTAssertEqualObjects(optManaged.floatObj.lastObject, @3.3f);
    XCTAssertEqualObjects(optManaged.doubleObj.lastObject, @3.3);
    XCTAssertEqualObjects(optManaged.stringObj.lastObject, @"b");
    XCTAssertEqualObjects(optManaged.dataObj.lastObject, data(2));
    XCTAssertEqualObjects(optManaged.dateObj.lastObject, date(2));
    XCTAssertEqualObjects(optManaged.decimalObj.lastObject, decimal128(2));
    XCTAssertEqualObjects(optManaged.objectIdObj.lastObject, objectId(2));
}

- (void)testAddObject {
    RLMAssertThrowsWithReason([unmanaged.boolObj addObject:@"a"], 
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'bool'");
    RLMAssertThrowsWithReason([unmanaged.intObj addObject:@"a"], 
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'int'");
    RLMAssertThrowsWithReason([unmanaged.floatObj addObject:@"a"], 
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'float'");
    RLMAssertThrowsWithReason([unmanaged.doubleObj addObject:@"a"], 
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'double'");
    RLMAssertThrowsWithReason([unmanaged.stringObj addObject:@2], 
                              @"Invalid value '2' of type '__NSCFNumber' for expected type 'string'");
    RLMAssertThrowsWithReason([unmanaged.dataObj addObject:@"a"], 
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'data'");
    RLMAssertThrowsWithReason([unmanaged.dateObj addObject:@"a"], 
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'date'");
    RLMAssertThrowsWithReason([unmanaged.decimalObj addObject:@"a"], 
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'decimal128'");
    RLMAssertThrowsWithReason([unmanaged.objectIdObj addObject:@"a"], 
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'object id'");
    RLMAssertThrowsWithReason([optUnmanaged.boolObj addObject:@"a"], 
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'bool?'");
    RLMAssertThrowsWithReason([optUnmanaged.intObj addObject:@"a"], 
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'int?'");
    RLMAssertThrowsWithReason([optUnmanaged.floatObj addObject:@"a"], 
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'float?'");
    RLMAssertThrowsWithReason([optUnmanaged.doubleObj addObject:@"a"], 
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'double?'");
    RLMAssertThrowsWithReason([optUnmanaged.stringObj addObject:@2], 
                              @"Invalid value '2' of type '__NSCFNumber' for expected type 'string?'");
    RLMAssertThrowsWithReason([optUnmanaged.dataObj addObject:@"a"], 
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'data?'");
    RLMAssertThrowsWithReason([optUnmanaged.dateObj addObject:@"a"], 
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'date?'");
    RLMAssertThrowsWithReason([optUnmanaged.decimalObj addObject:@"a"], 
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'decimal128?'");
    RLMAssertThrowsWithReason([optUnmanaged.objectIdObj addObject:@"a"], 
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'object id?'");
    RLMAssertThrowsWithReason([managed.boolObj addObject:@"a"], 
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'bool'");
    RLMAssertThrowsWithReason([managed.intObj addObject:@"a"], 
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'int'");
    RLMAssertThrowsWithReason([managed.floatObj addObject:@"a"], 
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'float'");
    RLMAssertThrowsWithReason([managed.doubleObj addObject:@"a"], 
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'double'");
    RLMAssertThrowsWithReason([managed.stringObj addObject:@2], 
                              @"Invalid value '2' of type '__NSCFNumber' for expected type 'string'");
    RLMAssertThrowsWithReason([managed.dataObj addObject:@"a"], 
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'data'");
    RLMAssertThrowsWithReason([managed.dateObj addObject:@"a"], 
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'date'");
    RLMAssertThrowsWithReason([managed.decimalObj addObject:@"a"], 
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'decimal128'");
    RLMAssertThrowsWithReason([managed.objectIdObj addObject:@"a"], 
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'object id'");
    RLMAssertThrowsWithReason([optManaged.boolObj addObject:@"a"], 
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'bool?'");
    RLMAssertThrowsWithReason([optManaged.intObj addObject:@"a"], 
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'int?'");
    RLMAssertThrowsWithReason([optManaged.floatObj addObject:@"a"], 
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'float?'");
    RLMAssertThrowsWithReason([optManaged.doubleObj addObject:@"a"], 
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'double?'");
    RLMAssertThrowsWithReason([optManaged.stringObj addObject:@2], 
                              @"Invalid value '2' of type '__NSCFNumber' for expected type 'string?'");
    RLMAssertThrowsWithReason([optManaged.dataObj addObject:@"a"], 
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'data?'");
    RLMAssertThrowsWithReason([optManaged.dateObj addObject:@"a"], 
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'date?'");
    RLMAssertThrowsWithReason([optManaged.decimalObj addObject:@"a"], 
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'decimal128?'");
    RLMAssertThrowsWithReason([optManaged.objectIdObj addObject:@"a"], 
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'object id?'");
    RLMAssertThrowsWithReason([unmanaged.boolObj addObject:NSNull.null], 
                              @"Invalid value '<null>' of type 'NSNull' for expected type 'bool'");
    RLMAssertThrowsWithReason([unmanaged.intObj addObject:NSNull.null], 
                              @"Invalid value '<null>' of type 'NSNull' for expected type 'int'");
    RLMAssertThrowsWithReason([unmanaged.floatObj addObject:NSNull.null], 
                              @"Invalid value '<null>' of type 'NSNull' for expected type 'float'");
    RLMAssertThrowsWithReason([unmanaged.doubleObj addObject:NSNull.null], 
                              @"Invalid value '<null>' of type 'NSNull' for expected type 'double'");
    RLMAssertThrowsWithReason([unmanaged.stringObj addObject:NSNull.null], 
                              @"Invalid value '<null>' of type 'NSNull' for expected type 'string'");
    RLMAssertThrowsWithReason([unmanaged.dataObj addObject:NSNull.null], 
                              @"Invalid value '<null>' of type 'NSNull' for expected type 'data'");
    RLMAssertThrowsWithReason([unmanaged.dateObj addObject:NSNull.null], 
                              @"Invalid value '<null>' of type 'NSNull' for expected type 'date'");
    RLMAssertThrowsWithReason([unmanaged.decimalObj addObject:NSNull.null], 
                              @"Invalid value '<null>' of type 'NSNull' for expected type 'decimal128'");
    RLMAssertThrowsWithReason([unmanaged.objectIdObj addObject:NSNull.null], 
                              @"Invalid value '<null>' of type 'NSNull' for expected type 'object id'");
    RLMAssertThrowsWithReason([managed.boolObj addObject:NSNull.null], 
                              @"Invalid value '<null>' of type 'NSNull' for expected type 'bool'");
    RLMAssertThrowsWithReason([managed.intObj addObject:NSNull.null], 
                              @"Invalid value '<null>' of type 'NSNull' for expected type 'int'");
    RLMAssertThrowsWithReason([managed.floatObj addObject:NSNull.null], 
                              @"Invalid value '<null>' of type 'NSNull' for expected type 'float'");
    RLMAssertThrowsWithReason([managed.doubleObj addObject:NSNull.null], 
                              @"Invalid value '<null>' of type 'NSNull' for expected type 'double'");
    RLMAssertThrowsWithReason([managed.stringObj addObject:NSNull.null], 
                              @"Invalid value '<null>' of type 'NSNull' for expected type 'string'");
    RLMAssertThrowsWithReason([managed.dataObj addObject:NSNull.null], 
                              @"Invalid value '<null>' of type 'NSNull' for expected type 'data'");
    RLMAssertThrowsWithReason([managed.dateObj addObject:NSNull.null], 
                              @"Invalid value '<null>' of type 'NSNull' for expected type 'date'");
    RLMAssertThrowsWithReason([managed.decimalObj addObject:NSNull.null], 
                              @"Invalid value '<null>' of type 'NSNull' for expected type 'decimal128'");
    RLMAssertThrowsWithReason([managed.objectIdObj addObject:NSNull.null], 
                              @"Invalid value '<null>' of type 'NSNull' for expected type 'object id'");

    [unmanaged.boolObj addObject:@NO];
    [unmanaged.intObj addObject:@2];
    [unmanaged.floatObj addObject:@2.2f];
    [unmanaged.doubleObj addObject:@2.2];
    [unmanaged.stringObj addObject:@"a"];
    [unmanaged.dataObj addObject:data(1)];
    [unmanaged.dateObj addObject:date(1)];
    [unmanaged.decimalObj addObject:decimal128(1)];
    [unmanaged.objectIdObj addObject:objectId(1)];
    [optUnmanaged.boolObj addObject:@NO];
    [optUnmanaged.intObj addObject:@2];
    [optUnmanaged.floatObj addObject:@2.2f];
    [optUnmanaged.doubleObj addObject:@2.2];
    [optUnmanaged.stringObj addObject:@"a"];
    [optUnmanaged.dataObj addObject:data(1)];
    [optUnmanaged.dateObj addObject:date(1)];
    [optUnmanaged.decimalObj addObject:decimal128(1)];
    [optUnmanaged.objectIdObj addObject:objectId(1)];
    [managed.boolObj addObject:@NO];
    [managed.intObj addObject:@2];
    [managed.floatObj addObject:@2.2f];
    [managed.doubleObj addObject:@2.2];
    [managed.stringObj addObject:@"a"];
    [managed.dataObj addObject:data(1)];
    [managed.dateObj addObject:date(1)];
    [managed.decimalObj addObject:decimal128(1)];
    [managed.objectIdObj addObject:objectId(1)];
    [optManaged.boolObj addObject:@NO];
    [optManaged.intObj addObject:@2];
    [optManaged.floatObj addObject:@2.2f];
    [optManaged.doubleObj addObject:@2.2];
    [optManaged.stringObj addObject:@"a"];
    [optManaged.dataObj addObject:data(1)];
    [optManaged.dateObj addObject:date(1)];
    [optManaged.decimalObj addObject:decimal128(1)];
    [optManaged.objectIdObj addObject:objectId(1)];
    XCTAssertEqualObjects(unmanaged.boolObj[0], @NO);
    XCTAssertEqualObjects(unmanaged.intObj[0], @2);
    XCTAssertEqualObjects(unmanaged.floatObj[0], @2.2f);
    XCTAssertEqualObjects(unmanaged.doubleObj[0], @2.2);
    XCTAssertEqualObjects(unmanaged.stringObj[0], @"a");
    XCTAssertEqualObjects(unmanaged.dataObj[0], data(1));
    XCTAssertEqualObjects(unmanaged.dateObj[0], date(1));
    XCTAssertEqualObjects(unmanaged.decimalObj[0], decimal128(1));
    XCTAssertEqualObjects(unmanaged.objectIdObj[0], objectId(1));
    XCTAssertEqualObjects(optUnmanaged.boolObj[0], @NO);
    XCTAssertEqualObjects(optUnmanaged.intObj[0], @2);
    XCTAssertEqualObjects(optUnmanaged.floatObj[0], @2.2f);
    XCTAssertEqualObjects(optUnmanaged.doubleObj[0], @2.2);
    XCTAssertEqualObjects(optUnmanaged.stringObj[0], @"a");
    XCTAssertEqualObjects(optUnmanaged.dataObj[0], data(1));
    XCTAssertEqualObjects(optUnmanaged.dateObj[0], date(1));
    XCTAssertEqualObjects(optUnmanaged.decimalObj[0], decimal128(1));
    XCTAssertEqualObjects(optUnmanaged.objectIdObj[0], objectId(1));
    XCTAssertEqualObjects(managed.boolObj[0], @NO);
    XCTAssertEqualObjects(managed.intObj[0], @2);
    XCTAssertEqualObjects(managed.floatObj[0], @2.2f);
    XCTAssertEqualObjects(managed.doubleObj[0], @2.2);
    XCTAssertEqualObjects(managed.stringObj[0], @"a");
    XCTAssertEqualObjects(managed.dataObj[0], data(1));
    XCTAssertEqualObjects(managed.dateObj[0], date(1));
    XCTAssertEqualObjects(managed.decimalObj[0], decimal128(1));
    XCTAssertEqualObjects(managed.objectIdObj[0], objectId(1));
    XCTAssertEqualObjects(optManaged.boolObj[0], @NO);
    XCTAssertEqualObjects(optManaged.intObj[0], @2);
    XCTAssertEqualObjects(optManaged.floatObj[0], @2.2f);
    XCTAssertEqualObjects(optManaged.doubleObj[0], @2.2);
    XCTAssertEqualObjects(optManaged.stringObj[0], @"a");
    XCTAssertEqualObjects(optManaged.dataObj[0], data(1));
    XCTAssertEqualObjects(optManaged.dateObj[0], date(1));
    XCTAssertEqualObjects(optManaged.decimalObj[0], decimal128(1));
    XCTAssertEqualObjects(optManaged.objectIdObj[0], objectId(1));

    [optUnmanaged.boolObj addObject:NSNull.null];
    [optUnmanaged.intObj addObject:NSNull.null];
    [optUnmanaged.floatObj addObject:NSNull.null];
    [optUnmanaged.doubleObj addObject:NSNull.null];
    [optUnmanaged.stringObj addObject:NSNull.null];
    [optUnmanaged.dataObj addObject:NSNull.null];
    [optUnmanaged.dateObj addObject:NSNull.null];
    [optUnmanaged.decimalObj addObject:NSNull.null];
    [optUnmanaged.objectIdObj addObject:NSNull.null];
    [optManaged.boolObj addObject:NSNull.null];
    [optManaged.intObj addObject:NSNull.null];
    [optManaged.floatObj addObject:NSNull.null];
    [optManaged.doubleObj addObject:NSNull.null];
    [optManaged.stringObj addObject:NSNull.null];
    [optManaged.dataObj addObject:NSNull.null];
    [optManaged.dateObj addObject:NSNull.null];
    [optManaged.decimalObj addObject:NSNull.null];
    [optManaged.objectIdObj addObject:NSNull.null];
    XCTAssertEqualObjects(optUnmanaged.boolObj[1], NSNull.null);
    XCTAssertEqualObjects(optUnmanaged.intObj[1], NSNull.null);
    XCTAssertEqualObjects(optUnmanaged.floatObj[1], NSNull.null);
    XCTAssertEqualObjects(optUnmanaged.doubleObj[1], NSNull.null);
    XCTAssertEqualObjects(optUnmanaged.stringObj[1], NSNull.null);
    XCTAssertEqualObjects(optUnmanaged.dataObj[1], NSNull.null);
    XCTAssertEqualObjects(optUnmanaged.dateObj[1], NSNull.null);
    XCTAssertEqualObjects(optUnmanaged.decimalObj[1], NSNull.null);
    XCTAssertEqualObjects(optUnmanaged.objectIdObj[1], NSNull.null);
    XCTAssertEqualObjects(optManaged.boolObj[1], NSNull.null);
    XCTAssertEqualObjects(optManaged.intObj[1], NSNull.null);
    XCTAssertEqualObjects(optManaged.floatObj[1], NSNull.null);
    XCTAssertEqualObjects(optManaged.doubleObj[1], NSNull.null);
    XCTAssertEqualObjects(optManaged.stringObj[1], NSNull.null);
    XCTAssertEqualObjects(optManaged.dataObj[1], NSNull.null);
    XCTAssertEqualObjects(optManaged.dateObj[1], NSNull.null);
    XCTAssertEqualObjects(optManaged.decimalObj[1], NSNull.null);
    XCTAssertEqualObjects(optManaged.objectIdObj[1], NSNull.null);
}

- (void)testAddObjects {
    RLMAssertThrowsWithReason([unmanaged.boolObj addObjects:@[@"a"]], 
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'bool'");
    RLMAssertThrowsWithReason([unmanaged.intObj addObjects:@[@"a"]], 
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'int'");
    RLMAssertThrowsWithReason([unmanaged.floatObj addObjects:@[@"a"]], 
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'float'");
    RLMAssertThrowsWithReason([unmanaged.doubleObj addObjects:@[@"a"]], 
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'double'");
    RLMAssertThrowsWithReason([unmanaged.stringObj addObjects:@[@2]], 
                              @"Invalid value '2' of type '__NSCFNumber' for expected type 'string'");
    RLMAssertThrowsWithReason([unmanaged.dataObj addObjects:@[@"a"]], 
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'data'");
    RLMAssertThrowsWithReason([unmanaged.dateObj addObjects:@[@"a"]], 
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'date'");
    RLMAssertThrowsWithReason([unmanaged.decimalObj addObjects:@[@"a"]], 
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'decimal128'");
    RLMAssertThrowsWithReason([unmanaged.objectIdObj addObjects:@[@"a"]], 
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'object id'");
    RLMAssertThrowsWithReason([optUnmanaged.boolObj addObjects:@[@"a"]], 
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'bool?'");
    RLMAssertThrowsWithReason([optUnmanaged.intObj addObjects:@[@"a"]], 
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'int?'");
    RLMAssertThrowsWithReason([optUnmanaged.floatObj addObjects:@[@"a"]], 
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'float?'");
    RLMAssertThrowsWithReason([optUnmanaged.doubleObj addObjects:@[@"a"]], 
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'double?'");
    RLMAssertThrowsWithReason([optUnmanaged.stringObj addObjects:@[@2]], 
                              @"Invalid value '2' of type '__NSCFNumber' for expected type 'string?'");
    RLMAssertThrowsWithReason([optUnmanaged.dataObj addObjects:@[@"a"]], 
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'data?'");
    RLMAssertThrowsWithReason([optUnmanaged.dateObj addObjects:@[@"a"]], 
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'date?'");
    RLMAssertThrowsWithReason([optUnmanaged.decimalObj addObjects:@[@"a"]], 
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'decimal128?'");
    RLMAssertThrowsWithReason([optUnmanaged.objectIdObj addObjects:@[@"a"]], 
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'object id?'");
    RLMAssertThrowsWithReason([managed.boolObj addObjects:@[@"a"]], 
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'bool'");
    RLMAssertThrowsWithReason([managed.intObj addObjects:@[@"a"]], 
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'int'");
    RLMAssertThrowsWithReason([managed.floatObj addObjects:@[@"a"]], 
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'float'");
    RLMAssertThrowsWithReason([managed.doubleObj addObjects:@[@"a"]], 
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'double'");
    RLMAssertThrowsWithReason([managed.stringObj addObjects:@[@2]], 
                              @"Invalid value '2' of type '__NSCFNumber' for expected type 'string'");
    RLMAssertThrowsWithReason([managed.dataObj addObjects:@[@"a"]], 
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'data'");
    RLMAssertThrowsWithReason([managed.dateObj addObjects:@[@"a"]], 
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'date'");
    RLMAssertThrowsWithReason([managed.decimalObj addObjects:@[@"a"]], 
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'decimal128'");
    RLMAssertThrowsWithReason([managed.objectIdObj addObjects:@[@"a"]], 
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'object id'");
    RLMAssertThrowsWithReason([optManaged.boolObj addObjects:@[@"a"]], 
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'bool?'");
    RLMAssertThrowsWithReason([optManaged.intObj addObjects:@[@"a"]], 
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'int?'");
    RLMAssertThrowsWithReason([optManaged.floatObj addObjects:@[@"a"]], 
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'float?'");
    RLMAssertThrowsWithReason([optManaged.doubleObj addObjects:@[@"a"]], 
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'double?'");
    RLMAssertThrowsWithReason([optManaged.stringObj addObjects:@[@2]], 
                              @"Invalid value '2' of type '__NSCFNumber' for expected type 'string?'");
    RLMAssertThrowsWithReason([optManaged.dataObj addObjects:@[@"a"]], 
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'data?'");
    RLMAssertThrowsWithReason([optManaged.dateObj addObjects:@[@"a"]], 
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'date?'");
    RLMAssertThrowsWithReason([optManaged.decimalObj addObjects:@[@"a"]], 
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'decimal128?'");
    RLMAssertThrowsWithReason([optManaged.objectIdObj addObjects:@[@"a"]], 
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'object id?'");
    RLMAssertThrowsWithReason([unmanaged.boolObj addObjects:@[NSNull.null]], 
                              @"Invalid value '<null>' of type 'NSNull' for expected type 'bool'");
    RLMAssertThrowsWithReason([unmanaged.intObj addObjects:@[NSNull.null]], 
                              @"Invalid value '<null>' of type 'NSNull' for expected type 'int'");
    RLMAssertThrowsWithReason([unmanaged.floatObj addObjects:@[NSNull.null]], 
                              @"Invalid value '<null>' of type 'NSNull' for expected type 'float'");
    RLMAssertThrowsWithReason([unmanaged.doubleObj addObjects:@[NSNull.null]], 
                              @"Invalid value '<null>' of type 'NSNull' for expected type 'double'");
    RLMAssertThrowsWithReason([unmanaged.stringObj addObjects:@[NSNull.null]], 
                              @"Invalid value '<null>' of type 'NSNull' for expected type 'string'");
    RLMAssertThrowsWithReason([unmanaged.dataObj addObjects:@[NSNull.null]], 
                              @"Invalid value '<null>' of type 'NSNull' for expected type 'data'");
    RLMAssertThrowsWithReason([unmanaged.dateObj addObjects:@[NSNull.null]], 
                              @"Invalid value '<null>' of type 'NSNull' for expected type 'date'");
    RLMAssertThrowsWithReason([unmanaged.decimalObj addObjects:@[NSNull.null]], 
                              @"Invalid value '<null>' of type 'NSNull' for expected type 'decimal128'");
    RLMAssertThrowsWithReason([unmanaged.objectIdObj addObjects:@[NSNull.null]], 
                              @"Invalid value '<null>' of type 'NSNull' for expected type 'object id'");
    RLMAssertThrowsWithReason([managed.boolObj addObjects:@[NSNull.null]], 
                              @"Invalid value '<null>' of type 'NSNull' for expected type 'bool'");
    RLMAssertThrowsWithReason([managed.intObj addObjects:@[NSNull.null]], 
                              @"Invalid value '<null>' of type 'NSNull' for expected type 'int'");
    RLMAssertThrowsWithReason([managed.floatObj addObjects:@[NSNull.null]], 
                              @"Invalid value '<null>' of type 'NSNull' for expected type 'float'");
    RLMAssertThrowsWithReason([managed.doubleObj addObjects:@[NSNull.null]], 
                              @"Invalid value '<null>' of type 'NSNull' for expected type 'double'");
    RLMAssertThrowsWithReason([managed.stringObj addObjects:@[NSNull.null]], 
                              @"Invalid value '<null>' of type 'NSNull' for expected type 'string'");
    RLMAssertThrowsWithReason([managed.dataObj addObjects:@[NSNull.null]], 
                              @"Invalid value '<null>' of type 'NSNull' for expected type 'data'");
    RLMAssertThrowsWithReason([managed.dateObj addObjects:@[NSNull.null]], 
                              @"Invalid value '<null>' of type 'NSNull' for expected type 'date'");
    RLMAssertThrowsWithReason([managed.decimalObj addObjects:@[NSNull.null]], 
                              @"Invalid value '<null>' of type 'NSNull' for expected type 'decimal128'");
    RLMAssertThrowsWithReason([managed.objectIdObj addObjects:@[NSNull.null]], 
                              @"Invalid value '<null>' of type 'NSNull' for expected type 'object id'");

    [self addObjects];
    XCTAssertEqualObjects(unmanaged.boolObj[0], @NO);
    XCTAssertEqualObjects(unmanaged.intObj[0], @2);
    XCTAssertEqualObjects(unmanaged.floatObj[0], @2.2f);
    XCTAssertEqualObjects(unmanaged.doubleObj[0], @2.2);
    XCTAssertEqualObjects(unmanaged.stringObj[0], @"a");
    XCTAssertEqualObjects(unmanaged.dataObj[0], data(1));
    XCTAssertEqualObjects(unmanaged.dateObj[0], date(1));
    XCTAssertEqualObjects(unmanaged.decimalObj[0], decimal128(1));
    XCTAssertEqualObjects(unmanaged.objectIdObj[0], objectId(1));
    XCTAssertEqualObjects(optUnmanaged.boolObj[0], @NO);
    XCTAssertEqualObjects(optUnmanaged.intObj[0], @2);
    XCTAssertEqualObjects(optUnmanaged.floatObj[0], @2.2f);
    XCTAssertEqualObjects(optUnmanaged.doubleObj[0], @2.2);
    XCTAssertEqualObjects(optUnmanaged.stringObj[0], @"a");
    XCTAssertEqualObjects(optUnmanaged.dataObj[0], data(1));
    XCTAssertEqualObjects(optUnmanaged.dateObj[0], date(1));
    XCTAssertEqualObjects(optUnmanaged.decimalObj[0], decimal128(1));
    XCTAssertEqualObjects(optUnmanaged.objectIdObj[0], objectId(1));
    XCTAssertEqualObjects(managed.boolObj[0], @NO);
    XCTAssertEqualObjects(managed.intObj[0], @2);
    XCTAssertEqualObjects(managed.floatObj[0], @2.2f);
    XCTAssertEqualObjects(managed.doubleObj[0], @2.2);
    XCTAssertEqualObjects(managed.stringObj[0], @"a");
    XCTAssertEqualObjects(managed.dataObj[0], data(1));
    XCTAssertEqualObjects(managed.dateObj[0], date(1));
    XCTAssertEqualObjects(managed.decimalObj[0], decimal128(1));
    XCTAssertEqualObjects(managed.objectIdObj[0], objectId(1));
    XCTAssertEqualObjects(optManaged.boolObj[0], @NO);
    XCTAssertEqualObjects(optManaged.intObj[0], @2);
    XCTAssertEqualObjects(optManaged.floatObj[0], @2.2f);
    XCTAssertEqualObjects(optManaged.doubleObj[0], @2.2);
    XCTAssertEqualObjects(optManaged.stringObj[0], @"a");
    XCTAssertEqualObjects(optManaged.dataObj[0], data(1));
    XCTAssertEqualObjects(optManaged.dateObj[0], date(1));
    XCTAssertEqualObjects(optManaged.decimalObj[0], decimal128(1));
    XCTAssertEqualObjects(optManaged.objectIdObj[0], objectId(1));
    XCTAssertEqualObjects(unmanaged.boolObj[1], @YES);
    XCTAssertEqualObjects(unmanaged.intObj[1], @3);
    XCTAssertEqualObjects(unmanaged.floatObj[1], @3.3f);
    XCTAssertEqualObjects(unmanaged.doubleObj[1], @3.3);
    XCTAssertEqualObjects(unmanaged.stringObj[1], @"b");
    XCTAssertEqualObjects(unmanaged.dataObj[1], data(2));
    XCTAssertEqualObjects(unmanaged.dateObj[1], date(2));
    XCTAssertEqualObjects(unmanaged.decimalObj[1], decimal128(2));
    XCTAssertEqualObjects(unmanaged.objectIdObj[1], objectId(2));
    XCTAssertEqualObjects(optUnmanaged.boolObj[1], @YES);
    XCTAssertEqualObjects(optUnmanaged.intObj[1], @3);
    XCTAssertEqualObjects(optUnmanaged.floatObj[1], @3.3f);
    XCTAssertEqualObjects(optUnmanaged.doubleObj[1], @3.3);
    XCTAssertEqualObjects(optUnmanaged.stringObj[1], @"b");
    XCTAssertEqualObjects(optUnmanaged.dataObj[1], data(2));
    XCTAssertEqualObjects(optUnmanaged.dateObj[1], date(2));
    XCTAssertEqualObjects(optUnmanaged.decimalObj[1], decimal128(2));
    XCTAssertEqualObjects(optUnmanaged.objectIdObj[1], objectId(2));
    XCTAssertEqualObjects(managed.boolObj[1], @YES);
    XCTAssertEqualObjects(managed.intObj[1], @3);
    XCTAssertEqualObjects(managed.floatObj[1], @3.3f);
    XCTAssertEqualObjects(managed.doubleObj[1], @3.3);
    XCTAssertEqualObjects(managed.stringObj[1], @"b");
    XCTAssertEqualObjects(managed.dataObj[1], data(2));
    XCTAssertEqualObjects(managed.dateObj[1], date(2));
    XCTAssertEqualObjects(managed.decimalObj[1], decimal128(2));
    XCTAssertEqualObjects(managed.objectIdObj[1], objectId(2));
    XCTAssertEqualObjects(optManaged.boolObj[1], @YES);
    XCTAssertEqualObjects(optManaged.intObj[1], @3);
    XCTAssertEqualObjects(optManaged.floatObj[1], @3.3f);
    XCTAssertEqualObjects(optManaged.doubleObj[1], @3.3);
    XCTAssertEqualObjects(optManaged.stringObj[1], @"b");
    XCTAssertEqualObjects(optManaged.dataObj[1], data(2));
    XCTAssertEqualObjects(optManaged.dateObj[1], date(2));
    XCTAssertEqualObjects(optManaged.decimalObj[1], decimal128(2));
    XCTAssertEqualObjects(optManaged.objectIdObj[1], objectId(2));
    XCTAssertEqualObjects(optUnmanaged.boolObj[2], NSNull.null);
    XCTAssertEqualObjects(optUnmanaged.intObj[2], NSNull.null);
    XCTAssertEqualObjects(optUnmanaged.floatObj[2], NSNull.null);
    XCTAssertEqualObjects(optUnmanaged.doubleObj[2], NSNull.null);
    XCTAssertEqualObjects(optUnmanaged.stringObj[2], NSNull.null);
    XCTAssertEqualObjects(optUnmanaged.dataObj[2], NSNull.null);
    XCTAssertEqualObjects(optUnmanaged.dateObj[2], NSNull.null);
    XCTAssertEqualObjects(optUnmanaged.decimalObj[2], NSNull.null);
    XCTAssertEqualObjects(optUnmanaged.objectIdObj[2], NSNull.null);
    XCTAssertEqualObjects(optManaged.boolObj[2], NSNull.null);
    XCTAssertEqualObjects(optManaged.intObj[2], NSNull.null);
    XCTAssertEqualObjects(optManaged.floatObj[2], NSNull.null);
    XCTAssertEqualObjects(optManaged.doubleObj[2], NSNull.null);
    XCTAssertEqualObjects(optManaged.stringObj[2], NSNull.null);
    XCTAssertEqualObjects(optManaged.dataObj[2], NSNull.null);
    XCTAssertEqualObjects(optManaged.dateObj[2], NSNull.null);
    XCTAssertEqualObjects(optManaged.decimalObj[2], NSNull.null);
    XCTAssertEqualObjects(optManaged.objectIdObj[2], NSNull.null);
}

- (void)testRemoveObject {

}

- (void)testRemoveLastObject {
    for (RLMSet *set in allSets) {
        XCTAssertNoThrow([set removeLastObject]);
    }

    [self addObjects];
    XCTAssertEqual(unmanaged.boolObj.count, 2U);
    XCTAssertEqual(unmanaged.intObj.count, 2U);
    XCTAssertEqual(unmanaged.floatObj.count, 2U);
    XCTAssertEqual(unmanaged.doubleObj.count, 2U);
    XCTAssertEqual(unmanaged.stringObj.count, 2U);
    XCTAssertEqual(unmanaged.dataObj.count, 2U);
    XCTAssertEqual(unmanaged.dateObj.count, 2U);
    XCTAssertEqual(unmanaged.decimalObj.count, 2U);
    XCTAssertEqual(unmanaged.objectIdObj.count, 2U);
    XCTAssertEqual(managed.boolObj.count, 2U);
    XCTAssertEqual(managed.intObj.count, 2U);
    XCTAssertEqual(managed.floatObj.count, 2U);
    XCTAssertEqual(managed.doubleObj.count, 2U);
    XCTAssertEqual(managed.stringObj.count, 2U);
    XCTAssertEqual(managed.dataObj.count, 2U);
    XCTAssertEqual(managed.dateObj.count, 2U);
    XCTAssertEqual(managed.decimalObj.count, 2U);
    XCTAssertEqual(managed.objectIdObj.count, 2U);
    XCTAssertEqual(optUnmanaged.boolObj.count, 3U);
    XCTAssertEqual(optUnmanaged.intObj.count, 3U);
    XCTAssertEqual(optUnmanaged.floatObj.count, 3U);
    XCTAssertEqual(optUnmanaged.doubleObj.count, 3U);
    XCTAssertEqual(optUnmanaged.stringObj.count, 3U);
    XCTAssertEqual(optUnmanaged.dataObj.count, 3U);
    XCTAssertEqual(optUnmanaged.dateObj.count, 3U);
    XCTAssertEqual(optUnmanaged.decimalObj.count, 3U);
    XCTAssertEqual(optUnmanaged.objectIdObj.count, 3U);
    XCTAssertEqual(optManaged.boolObj.count, 3U);
    XCTAssertEqual(optManaged.intObj.count, 3U);
    XCTAssertEqual(optManaged.floatObj.count, 3U);
    XCTAssertEqual(optManaged.doubleObj.count, 3U);
    XCTAssertEqual(optManaged.stringObj.count, 3U);
    XCTAssertEqual(optManaged.dataObj.count, 3U);
    XCTAssertEqual(optManaged.dateObj.count, 3U);
    XCTAssertEqual(optManaged.decimalObj.count, 3U);
    XCTAssertEqual(optManaged.objectIdObj.count, 3U);

    for (RLMSet *set in allSets) {
        [set removeLastObject];
    }
    XCTAssertEqual(unmanaged.boolObj.count, 1U);
    XCTAssertEqual(unmanaged.intObj.count, 1U);
    XCTAssertEqual(unmanaged.floatObj.count, 1U);
    XCTAssertEqual(unmanaged.doubleObj.count, 1U);
    XCTAssertEqual(unmanaged.stringObj.count, 1U);
    XCTAssertEqual(unmanaged.dataObj.count, 1U);
    XCTAssertEqual(unmanaged.dateObj.count, 1U);
    XCTAssertEqual(unmanaged.decimalObj.count, 1U);
    XCTAssertEqual(unmanaged.objectIdObj.count, 1U);
    XCTAssertEqual(managed.boolObj.count, 1U);
    XCTAssertEqual(managed.intObj.count, 1U);
    XCTAssertEqual(managed.floatObj.count, 1U);
    XCTAssertEqual(managed.doubleObj.count, 1U);
    XCTAssertEqual(managed.stringObj.count, 1U);
    XCTAssertEqual(managed.dataObj.count, 1U);
    XCTAssertEqual(managed.dateObj.count, 1U);
    XCTAssertEqual(managed.decimalObj.count, 1U);
    XCTAssertEqual(managed.objectIdObj.count, 1U);
    XCTAssertEqual(optUnmanaged.boolObj.count, 2U);
    XCTAssertEqual(optUnmanaged.intObj.count, 2U);
    XCTAssertEqual(optUnmanaged.floatObj.count, 2U);
    XCTAssertEqual(optUnmanaged.doubleObj.count, 2U);
    XCTAssertEqual(optUnmanaged.stringObj.count, 2U);
    XCTAssertEqual(optUnmanaged.dataObj.count, 2U);
    XCTAssertEqual(optUnmanaged.dateObj.count, 2U);
    XCTAssertEqual(optUnmanaged.decimalObj.count, 2U);
    XCTAssertEqual(optUnmanaged.objectIdObj.count, 2U);
    XCTAssertEqual(optManaged.boolObj.count, 2U);
    XCTAssertEqual(optManaged.intObj.count, 2U);
    XCTAssertEqual(optManaged.floatObj.count, 2U);
    XCTAssertEqual(optManaged.doubleObj.count, 2U);
    XCTAssertEqual(optManaged.stringObj.count, 2U);
    XCTAssertEqual(optManaged.dataObj.count, 2U);
    XCTAssertEqual(optManaged.dateObj.count, 2U);
    XCTAssertEqual(optManaged.decimalObj.count, 2U);
    XCTAssertEqual(optManaged.objectIdObj.count, 2U);

    XCTAssertEqualObjects(unmanaged.boolObj[0], @NO);
    XCTAssertEqualObjects(unmanaged.intObj[0], @2);
    XCTAssertEqualObjects(unmanaged.floatObj[0], @2.2f);
    XCTAssertEqualObjects(unmanaged.doubleObj[0], @2.2);
    XCTAssertEqualObjects(unmanaged.stringObj[0], @"a");
    XCTAssertEqualObjects(unmanaged.dataObj[0], data(1));
    XCTAssertEqualObjects(unmanaged.dateObj[0], date(1));
    XCTAssertEqualObjects(unmanaged.decimalObj[0], decimal128(1));
    XCTAssertEqualObjects(unmanaged.objectIdObj[0], objectId(1));
    XCTAssertEqualObjects(optUnmanaged.boolObj[0], @NO);
    XCTAssertEqualObjects(optUnmanaged.intObj[0], @2);
    XCTAssertEqualObjects(optUnmanaged.floatObj[0], @2.2f);
    XCTAssertEqualObjects(optUnmanaged.doubleObj[0], @2.2);
    XCTAssertEqualObjects(optUnmanaged.stringObj[0], @"a");
    XCTAssertEqualObjects(optUnmanaged.dataObj[0], data(1));
    XCTAssertEqualObjects(optUnmanaged.dateObj[0], date(1));
    XCTAssertEqualObjects(optUnmanaged.decimalObj[0], decimal128(1));
    XCTAssertEqualObjects(optUnmanaged.objectIdObj[0], objectId(1));
    XCTAssertEqualObjects(managed.boolObj[0], @NO);
    XCTAssertEqualObjects(managed.intObj[0], @2);
    XCTAssertEqualObjects(managed.floatObj[0], @2.2f);
    XCTAssertEqualObjects(managed.doubleObj[0], @2.2);
    XCTAssertEqualObjects(managed.stringObj[0], @"a");
    XCTAssertEqualObjects(managed.dataObj[0], data(1));
    XCTAssertEqualObjects(managed.dateObj[0], date(1));
    XCTAssertEqualObjects(managed.decimalObj[0], decimal128(1));
    XCTAssertEqualObjects(managed.objectIdObj[0], objectId(1));
    XCTAssertEqualObjects(optManaged.boolObj[0], @NO);
    XCTAssertEqualObjects(optManaged.intObj[0], @2);
    XCTAssertEqualObjects(optManaged.floatObj[0], @2.2f);
    XCTAssertEqualObjects(optManaged.doubleObj[0], @2.2);
    XCTAssertEqualObjects(optManaged.stringObj[0], @"a");
    XCTAssertEqualObjects(optManaged.dataObj[0], data(1));
    XCTAssertEqualObjects(optManaged.dateObj[0], date(1));
    XCTAssertEqualObjects(optManaged.decimalObj[0], decimal128(1));
    XCTAssertEqualObjects(optManaged.objectIdObj[0], objectId(1));
    XCTAssertEqualObjects(optUnmanaged.boolObj[1], @YES);
    XCTAssertEqualObjects(optUnmanaged.intObj[1], @3);
    XCTAssertEqualObjects(optUnmanaged.floatObj[1], @3.3f);
    XCTAssertEqualObjects(optUnmanaged.doubleObj[1], @3.3);
    XCTAssertEqualObjects(optUnmanaged.stringObj[1], @"b");
    XCTAssertEqualObjects(optUnmanaged.dataObj[1], data(2));
    XCTAssertEqualObjects(optUnmanaged.dateObj[1], date(2));
    XCTAssertEqualObjects(optUnmanaged.decimalObj[1], decimal128(2));
    XCTAssertEqualObjects(optUnmanaged.objectIdObj[1], objectId(2));
    XCTAssertEqualObjects(optManaged.boolObj[1], @YES);
    XCTAssertEqualObjects(optManaged.intObj[1], @3);
    XCTAssertEqualObjects(optManaged.floatObj[1], @3.3f);
    XCTAssertEqualObjects(optManaged.doubleObj[1], @3.3);
    XCTAssertEqualObjects(optManaged.stringObj[1], @"b");
    XCTAssertEqualObjects(optManaged.dataObj[1], data(2));
    XCTAssertEqualObjects(optManaged.dateObj[1], date(2));
    XCTAssertEqualObjects(optManaged.decimalObj[1], decimal128(2));
    XCTAssertEqualObjects(optManaged.objectIdObj[1], objectId(2));
}

- (void)testIndexOfObject {
    XCTAssertEqual(NSNotFound, [unmanaged.boolObj indexOfObject:@NO]);
    XCTAssertEqual(NSNotFound, [unmanaged.intObj indexOfObject:@2]);
    XCTAssertEqual(NSNotFound, [unmanaged.floatObj indexOfObject:@2.2f]);
    XCTAssertEqual(NSNotFound, [unmanaged.doubleObj indexOfObject:@2.2]);
    XCTAssertEqual(NSNotFound, [unmanaged.stringObj indexOfObject:@"a"]);
    XCTAssertEqual(NSNotFound, [unmanaged.dataObj indexOfObject:data(1)]);
    XCTAssertEqual(NSNotFound, [unmanaged.dateObj indexOfObject:date(1)]);
    XCTAssertEqual(NSNotFound, [unmanaged.decimalObj indexOfObject:decimal128(1)]);
    XCTAssertEqual(NSNotFound, [unmanaged.objectIdObj indexOfObject:objectId(1)]);
    XCTAssertEqual(NSNotFound, [optUnmanaged.boolObj indexOfObject:@NO]);
    XCTAssertEqual(NSNotFound, [optUnmanaged.intObj indexOfObject:@2]);
    XCTAssertEqual(NSNotFound, [optUnmanaged.floatObj indexOfObject:@2.2f]);
    XCTAssertEqual(NSNotFound, [optUnmanaged.doubleObj indexOfObject:@2.2]);
    XCTAssertEqual(NSNotFound, [optUnmanaged.stringObj indexOfObject:@"a"]);
    XCTAssertEqual(NSNotFound, [optUnmanaged.dataObj indexOfObject:data(1)]);
    XCTAssertEqual(NSNotFound, [optUnmanaged.dateObj indexOfObject:date(1)]);
    XCTAssertEqual(NSNotFound, [optUnmanaged.decimalObj indexOfObject:decimal128(1)]);
    XCTAssertEqual(NSNotFound, [optUnmanaged.objectIdObj indexOfObject:objectId(1)]);
    XCTAssertEqual(NSNotFound, [managed.boolObj indexOfObject:@NO]);
    XCTAssertEqual(NSNotFound, [managed.intObj indexOfObject:@2]);
    XCTAssertEqual(NSNotFound, [managed.floatObj indexOfObject:@2.2f]);
    XCTAssertEqual(NSNotFound, [managed.doubleObj indexOfObject:@2.2]);
    XCTAssertEqual(NSNotFound, [managed.stringObj indexOfObject:@"a"]);
    XCTAssertEqual(NSNotFound, [managed.dataObj indexOfObject:data(1)]);
    XCTAssertEqual(NSNotFound, [managed.dateObj indexOfObject:date(1)]);
    XCTAssertEqual(NSNotFound, [managed.decimalObj indexOfObject:decimal128(1)]);
    XCTAssertEqual(NSNotFound, [managed.objectIdObj indexOfObject:objectId(1)]);
    XCTAssertEqual(NSNotFound, [optManaged.boolObj indexOfObject:@NO]);
    XCTAssertEqual(NSNotFound, [optManaged.intObj indexOfObject:@2]);
    XCTAssertEqual(NSNotFound, [optManaged.floatObj indexOfObject:@2.2f]);
    XCTAssertEqual(NSNotFound, [optManaged.doubleObj indexOfObject:@2.2]);
    XCTAssertEqual(NSNotFound, [optManaged.stringObj indexOfObject:@"a"]);
    XCTAssertEqual(NSNotFound, [optManaged.dataObj indexOfObject:data(1)]);
    XCTAssertEqual(NSNotFound, [optManaged.dateObj indexOfObject:date(1)]);
    XCTAssertEqual(NSNotFound, [optManaged.decimalObj indexOfObject:decimal128(1)]);
    XCTAssertEqual(NSNotFound, [optManaged.objectIdObj indexOfObject:objectId(1)]);

    RLMAssertThrowsWithReason([unmanaged.boolObj indexOfObject:@"a"], 
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'bool'");
    RLMAssertThrowsWithReason([unmanaged.intObj indexOfObject:@"a"], 
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'int'");
    RLMAssertThrowsWithReason([unmanaged.floatObj indexOfObject:@"a"], 
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'float'");
    RLMAssertThrowsWithReason([unmanaged.doubleObj indexOfObject:@"a"], 
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'double'");
    RLMAssertThrowsWithReason([unmanaged.stringObj indexOfObject:@2], 
                              @"Invalid value '2' of type '__NSCFNumber' for expected type 'string'");
    RLMAssertThrowsWithReason([unmanaged.dataObj indexOfObject:@"a"], 
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'data'");
    RLMAssertThrowsWithReason([unmanaged.dateObj indexOfObject:@"a"], 
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'date'");
    RLMAssertThrowsWithReason([unmanaged.decimalObj indexOfObject:@"a"], 
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'decimal128'");
    RLMAssertThrowsWithReason([unmanaged.objectIdObj indexOfObject:@"a"], 
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'object id'");
    RLMAssertThrowsWithReason([optUnmanaged.boolObj indexOfObject:@"a"], 
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'bool?'");
    RLMAssertThrowsWithReason([optUnmanaged.intObj indexOfObject:@"a"], 
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'int?'");
    RLMAssertThrowsWithReason([optUnmanaged.floatObj indexOfObject:@"a"], 
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'float?'");
    RLMAssertThrowsWithReason([optUnmanaged.doubleObj indexOfObject:@"a"], 
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'double?'");
    RLMAssertThrowsWithReason([optUnmanaged.stringObj indexOfObject:@2], 
                              @"Invalid value '2' of type '__NSCFNumber' for expected type 'string?'");
    RLMAssertThrowsWithReason([optUnmanaged.dataObj indexOfObject:@"a"], 
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'data?'");
    RLMAssertThrowsWithReason([optUnmanaged.dateObj indexOfObject:@"a"], 
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'date?'");
    RLMAssertThrowsWithReason([optUnmanaged.decimalObj indexOfObject:@"a"], 
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'decimal128?'");
    RLMAssertThrowsWithReason([optUnmanaged.objectIdObj indexOfObject:@"a"], 
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'object id?'");
    RLMAssertThrowsWithReason([managed.boolObj indexOfObject:@"a"], 
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'bool'");
    RLMAssertThrowsWithReason([managed.intObj indexOfObject:@"a"], 
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'int'");
    RLMAssertThrowsWithReason([managed.floatObj indexOfObject:@"a"], 
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'float'");
    RLMAssertThrowsWithReason([managed.doubleObj indexOfObject:@"a"], 
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'double'");
    RLMAssertThrowsWithReason([managed.stringObj indexOfObject:@2], 
                              @"Invalid value '2' of type '__NSCFNumber' for expected type 'string'");
    RLMAssertThrowsWithReason([managed.dataObj indexOfObject:@"a"], 
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'data'");
    RLMAssertThrowsWithReason([managed.dateObj indexOfObject:@"a"], 
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'date'");
    RLMAssertThrowsWithReason([managed.decimalObj indexOfObject:@"a"], 
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'decimal128'");
    RLMAssertThrowsWithReason([managed.objectIdObj indexOfObject:@"a"], 
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'object id'");
    RLMAssertThrowsWithReason([optManaged.boolObj indexOfObject:@"a"], 
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'bool?'");
    RLMAssertThrowsWithReason([optManaged.intObj indexOfObject:@"a"], 
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'int?'");
    RLMAssertThrowsWithReason([optManaged.floatObj indexOfObject:@"a"], 
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'float?'");
    RLMAssertThrowsWithReason([optManaged.doubleObj indexOfObject:@"a"], 
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'double?'");
    RLMAssertThrowsWithReason([optManaged.stringObj indexOfObject:@2], 
                              @"Invalid value '2' of type '__NSCFNumber' for expected type 'string?'");
    RLMAssertThrowsWithReason([optManaged.dataObj indexOfObject:@"a"], 
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'data?'");
    RLMAssertThrowsWithReason([optManaged.dateObj indexOfObject:@"a"], 
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'date?'");
    RLMAssertThrowsWithReason([optManaged.decimalObj indexOfObject:@"a"], 
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'decimal128?'");
    RLMAssertThrowsWithReason([optManaged.objectIdObj indexOfObject:@"a"], 
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'object id?'");

    RLMAssertThrowsWithReason([unmanaged.boolObj indexOfObject:NSNull.null], 
                              @"Invalid value '<null>' of type 'NSNull' for expected type 'bool'");
    RLMAssertThrowsWithReason([unmanaged.intObj indexOfObject:NSNull.null], 
                              @"Invalid value '<null>' of type 'NSNull' for expected type 'int'");
    RLMAssertThrowsWithReason([unmanaged.floatObj indexOfObject:NSNull.null], 
                              @"Invalid value '<null>' of type 'NSNull' for expected type 'float'");
    RLMAssertThrowsWithReason([unmanaged.doubleObj indexOfObject:NSNull.null], 
                              @"Invalid value '<null>' of type 'NSNull' for expected type 'double'");
    RLMAssertThrowsWithReason([unmanaged.stringObj indexOfObject:NSNull.null], 
                              @"Invalid value '<null>' of type 'NSNull' for expected type 'string'");
    RLMAssertThrowsWithReason([unmanaged.dataObj indexOfObject:NSNull.null], 
                              @"Invalid value '<null>' of type 'NSNull' for expected type 'data'");
    RLMAssertThrowsWithReason([unmanaged.dateObj indexOfObject:NSNull.null], 
                              @"Invalid value '<null>' of type 'NSNull' for expected type 'date'");
    RLMAssertThrowsWithReason([unmanaged.decimalObj indexOfObject:NSNull.null], 
                              @"Invalid value '<null>' of type 'NSNull' for expected type 'decimal128'");
    RLMAssertThrowsWithReason([unmanaged.objectIdObj indexOfObject:NSNull.null], 
                              @"Invalid value '<null>' of type 'NSNull' for expected type 'object id'");
    RLMAssertThrowsWithReason([managed.boolObj indexOfObject:NSNull.null], 
                              @"Invalid value '<null>' of type 'NSNull' for expected type 'bool'");
    RLMAssertThrowsWithReason([managed.intObj indexOfObject:NSNull.null], 
                              @"Invalid value '<null>' of type 'NSNull' for expected type 'int'");
    RLMAssertThrowsWithReason([managed.floatObj indexOfObject:NSNull.null], 
                              @"Invalid value '<null>' of type 'NSNull' for expected type 'float'");
    RLMAssertThrowsWithReason([managed.doubleObj indexOfObject:NSNull.null], 
                              @"Invalid value '<null>' of type 'NSNull' for expected type 'double'");
    RLMAssertThrowsWithReason([managed.stringObj indexOfObject:NSNull.null], 
                              @"Invalid value '<null>' of type 'NSNull' for expected type 'string'");
    RLMAssertThrowsWithReason([managed.dataObj indexOfObject:NSNull.null], 
                              @"Invalid value '<null>' of type 'NSNull' for expected type 'data'");
    RLMAssertThrowsWithReason([managed.dateObj indexOfObject:NSNull.null], 
                              @"Invalid value '<null>' of type 'NSNull' for expected type 'date'");
    RLMAssertThrowsWithReason([managed.decimalObj indexOfObject:NSNull.null], 
                              @"Invalid value '<null>' of type 'NSNull' for expected type 'decimal128'");
    RLMAssertThrowsWithReason([managed.objectIdObj indexOfObject:NSNull.null], 
                              @"Invalid value '<null>' of type 'NSNull' for expected type 'object id'");
    XCTAssertEqual(NSNotFound, [optUnmanaged.boolObj indexOfObject:NSNull.null]);
    XCTAssertEqual(NSNotFound, [optUnmanaged.intObj indexOfObject:NSNull.null]);
    XCTAssertEqual(NSNotFound, [optUnmanaged.floatObj indexOfObject:NSNull.null]);
    XCTAssertEqual(NSNotFound, [optUnmanaged.doubleObj indexOfObject:NSNull.null]);
    XCTAssertEqual(NSNotFound, [optUnmanaged.stringObj indexOfObject:NSNull.null]);
    XCTAssertEqual(NSNotFound, [optUnmanaged.dataObj indexOfObject:NSNull.null]);
    XCTAssertEqual(NSNotFound, [optUnmanaged.dateObj indexOfObject:NSNull.null]);
    XCTAssertEqual(NSNotFound, [optUnmanaged.decimalObj indexOfObject:NSNull.null]);
    XCTAssertEqual(NSNotFound, [optUnmanaged.objectIdObj indexOfObject:NSNull.null]);
    XCTAssertEqual(NSNotFound, [optManaged.boolObj indexOfObject:NSNull.null]);
    XCTAssertEqual(NSNotFound, [optManaged.intObj indexOfObject:NSNull.null]);
    XCTAssertEqual(NSNotFound, [optManaged.floatObj indexOfObject:NSNull.null]);
    XCTAssertEqual(NSNotFound, [optManaged.doubleObj indexOfObject:NSNull.null]);
    XCTAssertEqual(NSNotFound, [optManaged.stringObj indexOfObject:NSNull.null]);
    XCTAssertEqual(NSNotFound, [optManaged.dataObj indexOfObject:NSNull.null]);
    XCTAssertEqual(NSNotFound, [optManaged.dateObj indexOfObject:NSNull.null]);
    XCTAssertEqual(NSNotFound, [optManaged.decimalObj indexOfObject:NSNull.null]);
    XCTAssertEqual(NSNotFound, [optManaged.objectIdObj indexOfObject:NSNull.null]);

    [self addObjects];

    XCTAssertEqual(1U, [unmanaged.boolObj indexOfObject:@YES]);
    XCTAssertEqual(1U, [unmanaged.intObj indexOfObject:@3]);
    XCTAssertEqual(1U, [unmanaged.floatObj indexOfObject:@3.3f]);
    XCTAssertEqual(1U, [unmanaged.doubleObj indexOfObject:@3.3]);
    XCTAssertEqual(1U, [unmanaged.stringObj indexOfObject:@"b"]);
    XCTAssertEqual(1U, [unmanaged.dataObj indexOfObject:data(2)]);
    XCTAssertEqual(1U, [unmanaged.dateObj indexOfObject:date(2)]);
    XCTAssertEqual(1U, [unmanaged.decimalObj indexOfObject:decimal128(2)]);
    XCTAssertEqual(1U, [unmanaged.objectIdObj indexOfObject:objectId(2)]);
    XCTAssertEqual(1U, [optUnmanaged.boolObj indexOfObject:@YES]);
    XCTAssertEqual(1U, [optUnmanaged.intObj indexOfObject:@3]);
    XCTAssertEqual(1U, [optUnmanaged.floatObj indexOfObject:@3.3f]);
    XCTAssertEqual(1U, [optUnmanaged.doubleObj indexOfObject:@3.3]);
    XCTAssertEqual(1U, [optUnmanaged.stringObj indexOfObject:@"b"]);
    XCTAssertEqual(1U, [optUnmanaged.dataObj indexOfObject:data(2)]);
    XCTAssertEqual(1U, [optUnmanaged.dateObj indexOfObject:date(2)]);
    XCTAssertEqual(1U, [optUnmanaged.decimalObj indexOfObject:decimal128(2)]);
    XCTAssertEqual(1U, [optUnmanaged.objectIdObj indexOfObject:objectId(2)]);
    XCTAssertEqual(1U, [managed.boolObj indexOfObject:@YES]);
    XCTAssertEqual(1U, [managed.intObj indexOfObject:@3]);
    XCTAssertEqual(1U, [managed.floatObj indexOfObject:@3.3f]);
    XCTAssertEqual(1U, [managed.doubleObj indexOfObject:@3.3]);
    XCTAssertEqual(1U, [managed.stringObj indexOfObject:@"b"]);
    XCTAssertEqual(1U, [managed.dataObj indexOfObject:data(2)]);
    XCTAssertEqual(1U, [managed.dateObj indexOfObject:date(2)]);
    XCTAssertEqual(1U, [managed.decimalObj indexOfObject:decimal128(2)]);
    XCTAssertEqual(1U, [managed.objectIdObj indexOfObject:objectId(2)]);
    XCTAssertEqual(1U, [optManaged.boolObj indexOfObject:@YES]);
    XCTAssertEqual(1U, [optManaged.intObj indexOfObject:@3]);
    XCTAssertEqual(1U, [optManaged.floatObj indexOfObject:@3.3f]);
    XCTAssertEqual(1U, [optManaged.doubleObj indexOfObject:@3.3]);
    XCTAssertEqual(1U, [optManaged.stringObj indexOfObject:@"b"]);
    XCTAssertEqual(1U, [optManaged.dataObj indexOfObject:data(2)]);
    XCTAssertEqual(1U, [optManaged.dateObj indexOfObject:date(2)]);
    XCTAssertEqual(1U, [optManaged.decimalObj indexOfObject:decimal128(2)]);
    XCTAssertEqual(1U, [optManaged.objectIdObj indexOfObject:objectId(2)]);
}

- (void)testIndexOfObjectSorted {
    [managed.boolObj addObjects:@[@NO, @YES, @NO, @YES]];
    [managed.intObj addObjects:@[@2, @3, @2, @3]];
    [managed.floatObj addObjects:@[@2.2f, @3.3f, @2.2f, @3.3f]];
    [managed.doubleObj addObjects:@[@2.2, @3.3, @2.2, @3.3]];
    [managed.stringObj addObjects:@[@"a", @"b", @"a", @"b"]];
    [managed.dataObj addObjects:@[data(1), data(2), data(1), data(2)]];
    [managed.dateObj addObjects:@[date(1), date(2), date(1), date(2)]];
    [managed.decimalObj addObjects:@[decimal128(1), decimal128(2), decimal128(1), decimal128(2)]];
    [managed.objectIdObj addObjects:@[objectId(1), objectId(2), objectId(1), objectId(2)]];
    [optManaged.boolObj addObjects:@[@NO, @YES, NSNull.null, @YES, @NO]];
    [optManaged.intObj addObjects:@[@2, @3, NSNull.null, @3, @2]];
    [optManaged.floatObj addObjects:@[@2.2f, @3.3f, NSNull.null, @3.3f, @2.2f]];
    [optManaged.doubleObj addObjects:@[@2.2, @3.3, NSNull.null, @3.3, @2.2]];
    [optManaged.stringObj addObjects:@[@"a", @"b", NSNull.null, @"b", @"a"]];
    [optManaged.dataObj addObjects:@[data(1), data(2), NSNull.null, data(2), data(1)]];
    [optManaged.dateObj addObjects:@[date(1), date(2), NSNull.null, date(2), date(1)]];
    [optManaged.decimalObj addObjects:@[decimal128(1), decimal128(2), NSNull.null, decimal128(2), decimal128(1)]];
    [optManaged.objectIdObj addObjects:@[objectId(1), objectId(2), NSNull.null, objectId(2), objectId(1)]];

    XCTAssertEqual(0U, [[managed.boolObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:@YES]);
    XCTAssertEqual(0U, [[managed.intObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:@3]);
    XCTAssertEqual(0U, [[managed.floatObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:@3.3f]);
    XCTAssertEqual(0U, [[managed.doubleObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:@3.3]);
    XCTAssertEqual(0U, [[managed.stringObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:@"b"]);
    XCTAssertEqual(0U, [[managed.dataObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:data(2)]);
    XCTAssertEqual(0U, [[managed.dateObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:date(2)]);
    XCTAssertEqual(0U, [[managed.decimalObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:decimal128(2)]);
    XCTAssertEqual(0U, [[managed.objectIdObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:objectId(2)]);
    XCTAssertEqual(2U, [[managed.boolObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:@NO]);
    XCTAssertEqual(2U, [[managed.intObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:@2]);
    XCTAssertEqual(2U, [[managed.floatObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:@2.2f]);
    XCTAssertEqual(2U, [[managed.doubleObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:@2.2]);
    XCTAssertEqual(2U, [[managed.stringObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:@"a"]);
    XCTAssertEqual(2U, [[managed.dataObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:data(1)]);
    XCTAssertEqual(2U, [[managed.dateObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:date(1)]);
    XCTAssertEqual(2U, [[managed.decimalObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:decimal128(1)]);
    XCTAssertEqual(2U, [[managed.objectIdObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:objectId(1)]);

    XCTAssertEqual(0U, [[optManaged.boolObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:@YES]);
    XCTAssertEqual(0U, [[optManaged.intObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:@3]);
    XCTAssertEqual(0U, [[optManaged.floatObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:@3.3f]);
    XCTAssertEqual(0U, [[optManaged.doubleObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:@3.3]);
    XCTAssertEqual(0U, [[optManaged.stringObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:@"b"]);
    XCTAssertEqual(0U, [[optManaged.dataObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:data(2)]);
    XCTAssertEqual(0U, [[optManaged.dateObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:date(2)]);
    XCTAssertEqual(0U, [[optManaged.decimalObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:decimal128(2)]);
    XCTAssertEqual(0U, [[optManaged.objectIdObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:objectId(2)]);
    XCTAssertEqual(2U, [[optManaged.boolObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:@NO]);
    XCTAssertEqual(2U, [[optManaged.intObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:@2]);
    XCTAssertEqual(2U, [[optManaged.floatObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:@2.2f]);
    XCTAssertEqual(2U, [[optManaged.doubleObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:@2.2]);
    XCTAssertEqual(2U, [[optManaged.stringObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:@"a"]);
    XCTAssertEqual(2U, [[optManaged.dataObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:data(1)]);
    XCTAssertEqual(2U, [[optManaged.dateObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:date(1)]);
    XCTAssertEqual(2U, [[optManaged.decimalObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:decimal128(1)]);
    XCTAssertEqual(2U, [[optManaged.objectIdObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:objectId(1)]);
    XCTAssertEqual(4U, [[optManaged.boolObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:NSNull.null]);
    XCTAssertEqual(4U, [[optManaged.intObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:NSNull.null]);
    XCTAssertEqual(4U, [[optManaged.floatObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:NSNull.null]);
    XCTAssertEqual(4U, [[optManaged.doubleObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:NSNull.null]);
    XCTAssertEqual(4U, [[optManaged.stringObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:NSNull.null]);
    XCTAssertEqual(4U, [[optManaged.dataObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:NSNull.null]);
    XCTAssertEqual(4U, [[optManaged.dateObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:NSNull.null]);
    XCTAssertEqual(4U, [[optManaged.decimalObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:NSNull.null]);
    XCTAssertEqual(4U, [[optManaged.objectIdObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:NSNull.null]);
}

- (void)testIndexOfObjectDistinct {
    [managed.boolObj addObjects:@[@NO, @NO, @YES]];
    [managed.intObj addObjects:@[@2, @2, @3]];
    [managed.floatObj addObjects:@[@2.2f, @2.2f, @3.3f]];
    [managed.doubleObj addObjects:@[@2.2, @2.2, @3.3]];
    [managed.stringObj addObjects:@[@"a", @"a", @"b"]];
    [managed.dataObj addObjects:@[data(1), data(1), data(2)]];
    [managed.dateObj addObjects:@[date(1), date(1), date(2)]];
    [managed.decimalObj addObjects:@[decimal128(1), decimal128(1), decimal128(2)]];
    [managed.objectIdObj addObjects:@[objectId(1), objectId(1), objectId(2)]];
    [optManaged.boolObj addObjects:@[@NO, @NO, NSNull.null, @YES, @NO]];
    [optManaged.intObj addObjects:@[@2, @2, NSNull.null, @3, @2]];
    [optManaged.floatObj addObjects:@[@2.2f, @2.2f, NSNull.null, @3.3f, @2.2f]];
    [optManaged.doubleObj addObjects:@[@2.2, @2.2, NSNull.null, @3.3, @2.2]];
    [optManaged.stringObj addObjects:@[@"a", @"a", NSNull.null, @"b", @"a"]];
    [optManaged.dataObj addObjects:@[data(1), data(1), NSNull.null, data(2), data(1)]];
    [optManaged.dateObj addObjects:@[date(1), date(1), NSNull.null, date(2), date(1)]];
    [optManaged.decimalObj addObjects:@[decimal128(1), decimal128(1), NSNull.null, decimal128(2), decimal128(1)]];
    [optManaged.objectIdObj addObjects:@[objectId(1), objectId(1), NSNull.null, objectId(2), objectId(1)]];

    XCTAssertEqual(0U, [[managed.boolObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:@NO]);
    XCTAssertEqual(0U, [[managed.intObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:@2]);
    XCTAssertEqual(0U, [[managed.floatObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:@2.2f]);
    XCTAssertEqual(0U, [[managed.doubleObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:@2.2]);
    XCTAssertEqual(0U, [[managed.stringObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:@"a"]);
    XCTAssertEqual(0U, [[managed.dataObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:data(1)]);
    XCTAssertEqual(0U, [[managed.dateObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:date(1)]);
    XCTAssertEqual(0U, [[managed.decimalObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:decimal128(1)]);
    XCTAssertEqual(0U, [[managed.objectIdObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:objectId(1)]);
    XCTAssertEqual(1U, [[managed.boolObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:@YES]);
    XCTAssertEqual(1U, [[managed.intObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:@3]);
    XCTAssertEqual(1U, [[managed.floatObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:@3.3f]);
    XCTAssertEqual(1U, [[managed.doubleObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:@3.3]);
    XCTAssertEqual(1U, [[managed.stringObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:@"b"]);
    XCTAssertEqual(1U, [[managed.dataObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:data(2)]);
    XCTAssertEqual(1U, [[managed.dateObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:date(2)]);
    XCTAssertEqual(1U, [[managed.decimalObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:decimal128(2)]);
    XCTAssertEqual(1U, [[managed.objectIdObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:objectId(2)]);

    XCTAssertEqual(0U, [[optManaged.boolObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:@NO]);
    XCTAssertEqual(0U, [[optManaged.intObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:@2]);
    XCTAssertEqual(0U, [[optManaged.floatObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:@2.2f]);
    XCTAssertEqual(0U, [[optManaged.doubleObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:@2.2]);
    XCTAssertEqual(0U, [[optManaged.stringObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:@"a"]);
    XCTAssertEqual(0U, [[optManaged.dataObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:data(1)]);
    XCTAssertEqual(0U, [[optManaged.dateObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:date(1)]);
    XCTAssertEqual(0U, [[optManaged.decimalObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:decimal128(1)]);
    XCTAssertEqual(0U, [[optManaged.objectIdObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:objectId(1)]);
    XCTAssertEqual(2U, [[optManaged.boolObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:@YES]);
    XCTAssertEqual(2U, [[optManaged.intObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:@3]);
    XCTAssertEqual(2U, [[optManaged.floatObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:@3.3f]);
    XCTAssertEqual(2U, [[optManaged.doubleObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:@3.3]);
    XCTAssertEqual(2U, [[optManaged.stringObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:@"b"]);
    XCTAssertEqual(2U, [[optManaged.dataObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:data(2)]);
    XCTAssertEqual(2U, [[optManaged.dateObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:date(2)]);
    XCTAssertEqual(2U, [[optManaged.decimalObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:decimal128(2)]);
    XCTAssertEqual(2U, [[optManaged.objectIdObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:objectId(2)]);
    XCTAssertEqual(1U, [[optManaged.boolObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:NSNull.null]);
    XCTAssertEqual(1U, [[optManaged.intObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:NSNull.null]);
    XCTAssertEqual(1U, [[optManaged.floatObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:NSNull.null]);
    XCTAssertEqual(1U, [[optManaged.doubleObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:NSNull.null]);
    XCTAssertEqual(1U, [[optManaged.stringObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:NSNull.null]);
    XCTAssertEqual(1U, [[optManaged.dataObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:NSNull.null]);
    XCTAssertEqual(1U, [[optManaged.dateObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:NSNull.null]);
    XCTAssertEqual(1U, [[optManaged.decimalObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:NSNull.null]);
    XCTAssertEqual(1U, [[optManaged.objectIdObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:NSNull.null]);
}

- (void)testIndexOfObjectWhere {
    RLMAssertThrowsWithReason([managed.boolObj indexOfObjectWhere:@"TRUEPREDICATE"], @"implemented");
    RLMAssertThrowsWithReason([managed.intObj indexOfObjectWhere:@"TRUEPREDICATE"], @"implemented");
    RLMAssertThrowsWithReason([managed.floatObj indexOfObjectWhere:@"TRUEPREDICATE"], @"implemented");
    RLMAssertThrowsWithReason([managed.doubleObj indexOfObjectWhere:@"TRUEPREDICATE"], @"implemented");
    RLMAssertThrowsWithReason([managed.stringObj indexOfObjectWhere:@"TRUEPREDICATE"], @"implemented");
    RLMAssertThrowsWithReason([managed.dataObj indexOfObjectWhere:@"TRUEPREDICATE"], @"implemented");
    RLMAssertThrowsWithReason([managed.dateObj indexOfObjectWhere:@"TRUEPREDICATE"], @"implemented");
    RLMAssertThrowsWithReason([managed.decimalObj indexOfObjectWhere:@"TRUEPREDICATE"], @"implemented");
    RLMAssertThrowsWithReason([managed.objectIdObj indexOfObjectWhere:@"TRUEPREDICATE"], @"implemented");
    RLMAssertThrowsWithReason([optManaged.boolObj indexOfObjectWhere:@"TRUEPREDICATE"], @"implemented");
    RLMAssertThrowsWithReason([optManaged.intObj indexOfObjectWhere:@"TRUEPREDICATE"], @"implemented");
    RLMAssertThrowsWithReason([optManaged.floatObj indexOfObjectWhere:@"TRUEPREDICATE"], @"implemented");
    RLMAssertThrowsWithReason([optManaged.doubleObj indexOfObjectWhere:@"TRUEPREDICATE"], @"implemented");
    RLMAssertThrowsWithReason([optManaged.stringObj indexOfObjectWhere:@"TRUEPREDICATE"], @"implemented");
    RLMAssertThrowsWithReason([optManaged.dataObj indexOfObjectWhere:@"TRUEPREDICATE"], @"implemented");
    RLMAssertThrowsWithReason([optManaged.dateObj indexOfObjectWhere:@"TRUEPREDICATE"], @"implemented");
    RLMAssertThrowsWithReason([optManaged.decimalObj indexOfObjectWhere:@"TRUEPREDICATE"], @"implemented");
    RLMAssertThrowsWithReason([optManaged.objectIdObj indexOfObjectWhere:@"TRUEPREDICATE"], @"implemented");
    RLMAssertThrowsWithReason([[managed.boolObj sortedResultsUsingKeyPath:@"self" ascending:NO] 
                               indexOfObjectWhere:@"TRUEPREDICATE"], @"implemented");
    RLMAssertThrowsWithReason([[managed.intObj sortedResultsUsingKeyPath:@"self" ascending:NO] 
                               indexOfObjectWhere:@"TRUEPREDICATE"], @"implemented");
    RLMAssertThrowsWithReason([[managed.floatObj sortedResultsUsingKeyPath:@"self" ascending:NO] 
                               indexOfObjectWhere:@"TRUEPREDICATE"], @"implemented");
    RLMAssertThrowsWithReason([[managed.doubleObj sortedResultsUsingKeyPath:@"self" ascending:NO] 
                               indexOfObjectWhere:@"TRUEPREDICATE"], @"implemented");
    RLMAssertThrowsWithReason([[managed.stringObj sortedResultsUsingKeyPath:@"self" ascending:NO] 
                               indexOfObjectWhere:@"TRUEPREDICATE"], @"implemented");
    RLMAssertThrowsWithReason([[managed.dataObj sortedResultsUsingKeyPath:@"self" ascending:NO] 
                               indexOfObjectWhere:@"TRUEPREDICATE"], @"implemented");
    RLMAssertThrowsWithReason([[managed.dateObj sortedResultsUsingKeyPath:@"self" ascending:NO] 
                               indexOfObjectWhere:@"TRUEPREDICATE"], @"implemented");
    RLMAssertThrowsWithReason([[managed.decimalObj sortedResultsUsingKeyPath:@"self" ascending:NO] 
                               indexOfObjectWhere:@"TRUEPREDICATE"], @"implemented");
    RLMAssertThrowsWithReason([[managed.objectIdObj sortedResultsUsingKeyPath:@"self" ascending:NO] 
                               indexOfObjectWhere:@"TRUEPREDICATE"], @"implemented");
    RLMAssertThrowsWithReason([[optManaged.boolObj sortedResultsUsingKeyPath:@"self" ascending:NO] 
                               indexOfObjectWhere:@"TRUEPREDICATE"], @"implemented");
    RLMAssertThrowsWithReason([[optManaged.intObj sortedResultsUsingKeyPath:@"self" ascending:NO] 
                               indexOfObjectWhere:@"TRUEPREDICATE"], @"implemented");
    RLMAssertThrowsWithReason([[optManaged.floatObj sortedResultsUsingKeyPath:@"self" ascending:NO] 
                               indexOfObjectWhere:@"TRUEPREDICATE"], @"implemented");
    RLMAssertThrowsWithReason([[optManaged.doubleObj sortedResultsUsingKeyPath:@"self" ascending:NO] 
                               indexOfObjectWhere:@"TRUEPREDICATE"], @"implemented");
    RLMAssertThrowsWithReason([[optManaged.stringObj sortedResultsUsingKeyPath:@"self" ascending:NO] 
                               indexOfObjectWhere:@"TRUEPREDICATE"], @"implemented");
    RLMAssertThrowsWithReason([[optManaged.dataObj sortedResultsUsingKeyPath:@"self" ascending:NO] 
                               indexOfObjectWhere:@"TRUEPREDICATE"], @"implemented");
    RLMAssertThrowsWithReason([[optManaged.dateObj sortedResultsUsingKeyPath:@"self" ascending:NO] 
                               indexOfObjectWhere:@"TRUEPREDICATE"], @"implemented");
    RLMAssertThrowsWithReason([[optManaged.decimalObj sortedResultsUsingKeyPath:@"self" ascending:NO] 
                               indexOfObjectWhere:@"TRUEPREDICATE"], @"implemented");
    RLMAssertThrowsWithReason([[optManaged.objectIdObj sortedResultsUsingKeyPath:@"self" ascending:NO] 
                               indexOfObjectWhere:@"TRUEPREDICATE"], @"implemented");

    XCTAssertEqual(NSNotFound, [unmanaged.boolObj indexOfObjectWhere:@"TRUEPREDICATE"]);
    XCTAssertEqual(NSNotFound, [unmanaged.intObj indexOfObjectWhere:@"TRUEPREDICATE"]);
    XCTAssertEqual(NSNotFound, [unmanaged.floatObj indexOfObjectWhere:@"TRUEPREDICATE"]);
    XCTAssertEqual(NSNotFound, [unmanaged.doubleObj indexOfObjectWhere:@"TRUEPREDICATE"]);
    XCTAssertEqual(NSNotFound, [unmanaged.stringObj indexOfObjectWhere:@"TRUEPREDICATE"]);
    XCTAssertEqual(NSNotFound, [unmanaged.dataObj indexOfObjectWhere:@"TRUEPREDICATE"]);
    XCTAssertEqual(NSNotFound, [unmanaged.dateObj indexOfObjectWhere:@"TRUEPREDICATE"]);
    XCTAssertEqual(NSNotFound, [unmanaged.decimalObj indexOfObjectWhere:@"TRUEPREDICATE"]);
    XCTAssertEqual(NSNotFound, [unmanaged.objectIdObj indexOfObjectWhere:@"TRUEPREDICATE"]);
    XCTAssertEqual(NSNotFound, [optUnmanaged.boolObj indexOfObjectWhere:@"TRUEPREDICATE"]);
    XCTAssertEqual(NSNotFound, [optUnmanaged.intObj indexOfObjectWhere:@"TRUEPREDICATE"]);
    XCTAssertEqual(NSNotFound, [optUnmanaged.floatObj indexOfObjectWhere:@"TRUEPREDICATE"]);
    XCTAssertEqual(NSNotFound, [optUnmanaged.doubleObj indexOfObjectWhere:@"TRUEPREDICATE"]);
    XCTAssertEqual(NSNotFound, [optUnmanaged.stringObj indexOfObjectWhere:@"TRUEPREDICATE"]);
    XCTAssertEqual(NSNotFound, [optUnmanaged.dataObj indexOfObjectWhere:@"TRUEPREDICATE"]);
    XCTAssertEqual(NSNotFound, [optUnmanaged.dateObj indexOfObjectWhere:@"TRUEPREDICATE"]);
    XCTAssertEqual(NSNotFound, [optUnmanaged.decimalObj indexOfObjectWhere:@"TRUEPREDICATE"]);
    XCTAssertEqual(NSNotFound, [optUnmanaged.objectIdObj indexOfObjectWhere:@"TRUEPREDICATE"]);

    [self addObjects];

    XCTAssertEqual(0U, [unmanaged.boolObj indexOfObjectWhere:@"TRUEPREDICATE"]);
    XCTAssertEqual(0U, [unmanaged.intObj indexOfObjectWhere:@"TRUEPREDICATE"]);
    XCTAssertEqual(0U, [unmanaged.floatObj indexOfObjectWhere:@"TRUEPREDICATE"]);
    XCTAssertEqual(0U, [unmanaged.doubleObj indexOfObjectWhere:@"TRUEPREDICATE"]);
    XCTAssertEqual(0U, [unmanaged.stringObj indexOfObjectWhere:@"TRUEPREDICATE"]);
    XCTAssertEqual(0U, [unmanaged.dataObj indexOfObjectWhere:@"TRUEPREDICATE"]);
    XCTAssertEqual(0U, [unmanaged.dateObj indexOfObjectWhere:@"TRUEPREDICATE"]);
    XCTAssertEqual(0U, [unmanaged.decimalObj indexOfObjectWhere:@"TRUEPREDICATE"]);
    XCTAssertEqual(0U, [unmanaged.objectIdObj indexOfObjectWhere:@"TRUEPREDICATE"]);
    XCTAssertEqual(0U, [optUnmanaged.boolObj indexOfObjectWhere:@"TRUEPREDICATE"]);
    XCTAssertEqual(0U, [optUnmanaged.intObj indexOfObjectWhere:@"TRUEPREDICATE"]);
    XCTAssertEqual(0U, [optUnmanaged.floatObj indexOfObjectWhere:@"TRUEPREDICATE"]);
    XCTAssertEqual(0U, [optUnmanaged.doubleObj indexOfObjectWhere:@"TRUEPREDICATE"]);
    XCTAssertEqual(0U, [optUnmanaged.stringObj indexOfObjectWhere:@"TRUEPREDICATE"]);
    XCTAssertEqual(0U, [optUnmanaged.dataObj indexOfObjectWhere:@"TRUEPREDICATE"]);
    XCTAssertEqual(0U, [optUnmanaged.dateObj indexOfObjectWhere:@"TRUEPREDICATE"]);
    XCTAssertEqual(0U, [optUnmanaged.decimalObj indexOfObjectWhere:@"TRUEPREDICATE"]);
    XCTAssertEqual(0U, [optUnmanaged.objectIdObj indexOfObjectWhere:@"TRUEPREDICATE"]);
    XCTAssertEqual(NSNotFound, [unmanaged.boolObj indexOfObjectWhere:@"FALSEPREDICATE"]);
    XCTAssertEqual(NSNotFound, [unmanaged.intObj indexOfObjectWhere:@"FALSEPREDICATE"]);
    XCTAssertEqual(NSNotFound, [unmanaged.floatObj indexOfObjectWhere:@"FALSEPREDICATE"]);
    XCTAssertEqual(NSNotFound, [unmanaged.doubleObj indexOfObjectWhere:@"FALSEPREDICATE"]);
    XCTAssertEqual(NSNotFound, [unmanaged.stringObj indexOfObjectWhere:@"FALSEPREDICATE"]);
    XCTAssertEqual(NSNotFound, [unmanaged.dataObj indexOfObjectWhere:@"FALSEPREDICATE"]);
    XCTAssertEqual(NSNotFound, [unmanaged.dateObj indexOfObjectWhere:@"FALSEPREDICATE"]);
    XCTAssertEqual(NSNotFound, [unmanaged.decimalObj indexOfObjectWhere:@"FALSEPREDICATE"]);
    XCTAssertEqual(NSNotFound, [unmanaged.objectIdObj indexOfObjectWhere:@"FALSEPREDICATE"]);
    XCTAssertEqual(NSNotFound, [optUnmanaged.boolObj indexOfObjectWhere:@"FALSEPREDICATE"]);
    XCTAssertEqual(NSNotFound, [optUnmanaged.intObj indexOfObjectWhere:@"FALSEPREDICATE"]);
    XCTAssertEqual(NSNotFound, [optUnmanaged.floatObj indexOfObjectWhere:@"FALSEPREDICATE"]);
    XCTAssertEqual(NSNotFound, [optUnmanaged.doubleObj indexOfObjectWhere:@"FALSEPREDICATE"]);
    XCTAssertEqual(NSNotFound, [optUnmanaged.stringObj indexOfObjectWhere:@"FALSEPREDICATE"]);
    XCTAssertEqual(NSNotFound, [optUnmanaged.dataObj indexOfObjectWhere:@"FALSEPREDICATE"]);
    XCTAssertEqual(NSNotFound, [optUnmanaged.dateObj indexOfObjectWhere:@"FALSEPREDICATE"]);
    XCTAssertEqual(NSNotFound, [optUnmanaged.decimalObj indexOfObjectWhere:@"FALSEPREDICATE"]);
    XCTAssertEqual(NSNotFound, [optUnmanaged.objectIdObj indexOfObjectWhere:@"FALSEPREDICATE"]);
}

- (void)testIndexOfObjectWithPredicate {
    RLMAssertThrowsWithReason([managed.boolObj indexOfObjectWithPredicate:[NSPredicate predicateWithValue:YES]], @"implemented");
    RLMAssertThrowsWithReason([managed.intObj indexOfObjectWithPredicate:[NSPredicate predicateWithValue:YES]], @"implemented");
    RLMAssertThrowsWithReason([managed.floatObj indexOfObjectWithPredicate:[NSPredicate predicateWithValue:YES]], @"implemented");
    RLMAssertThrowsWithReason([managed.doubleObj indexOfObjectWithPredicate:[NSPredicate predicateWithValue:YES]], @"implemented");
    RLMAssertThrowsWithReason([managed.stringObj indexOfObjectWithPredicate:[NSPredicate predicateWithValue:YES]], @"implemented");
    RLMAssertThrowsWithReason([managed.dataObj indexOfObjectWithPredicate:[NSPredicate predicateWithValue:YES]], @"implemented");
    RLMAssertThrowsWithReason([managed.dateObj indexOfObjectWithPredicate:[NSPredicate predicateWithValue:YES]], @"implemented");
    RLMAssertThrowsWithReason([managed.decimalObj indexOfObjectWithPredicate:[NSPredicate predicateWithValue:YES]], @"implemented");
    RLMAssertThrowsWithReason([managed.objectIdObj indexOfObjectWithPredicate:[NSPredicate predicateWithValue:YES]], @"implemented");
    RLMAssertThrowsWithReason([optManaged.boolObj indexOfObjectWithPredicate:[NSPredicate predicateWithValue:YES]], @"implemented");
    RLMAssertThrowsWithReason([optManaged.intObj indexOfObjectWithPredicate:[NSPredicate predicateWithValue:YES]], @"implemented");
    RLMAssertThrowsWithReason([optManaged.floatObj indexOfObjectWithPredicate:[NSPredicate predicateWithValue:YES]], @"implemented");
    RLMAssertThrowsWithReason([optManaged.doubleObj indexOfObjectWithPredicate:[NSPredicate predicateWithValue:YES]], @"implemented");
    RLMAssertThrowsWithReason([optManaged.stringObj indexOfObjectWithPredicate:[NSPredicate predicateWithValue:YES]], @"implemented");
    RLMAssertThrowsWithReason([optManaged.dataObj indexOfObjectWithPredicate:[NSPredicate predicateWithValue:YES]], @"implemented");
    RLMAssertThrowsWithReason([optManaged.dateObj indexOfObjectWithPredicate:[NSPredicate predicateWithValue:YES]], @"implemented");
    RLMAssertThrowsWithReason([optManaged.decimalObj indexOfObjectWithPredicate:[NSPredicate predicateWithValue:YES]], @"implemented");
    RLMAssertThrowsWithReason([optManaged.objectIdObj indexOfObjectWithPredicate:[NSPredicate predicateWithValue:YES]], @"implemented");
    RLMAssertThrowsWithReason([[managed.boolObj sortedResultsUsingKeyPath:@"self" ascending:NO] 
                               indexOfObjectWithPredicate:[NSPredicate predicateWithValue:YES]], @"implemented");
    RLMAssertThrowsWithReason([[managed.intObj sortedResultsUsingKeyPath:@"self" ascending:NO] 
                               indexOfObjectWithPredicate:[NSPredicate predicateWithValue:YES]], @"implemented");
    RLMAssertThrowsWithReason([[managed.floatObj sortedResultsUsingKeyPath:@"self" ascending:NO] 
                               indexOfObjectWithPredicate:[NSPredicate predicateWithValue:YES]], @"implemented");
    RLMAssertThrowsWithReason([[managed.doubleObj sortedResultsUsingKeyPath:@"self" ascending:NO] 
                               indexOfObjectWithPredicate:[NSPredicate predicateWithValue:YES]], @"implemented");
    RLMAssertThrowsWithReason([[managed.stringObj sortedResultsUsingKeyPath:@"self" ascending:NO] 
                               indexOfObjectWithPredicate:[NSPredicate predicateWithValue:YES]], @"implemented");
    RLMAssertThrowsWithReason([[managed.dataObj sortedResultsUsingKeyPath:@"self" ascending:NO] 
                               indexOfObjectWithPredicate:[NSPredicate predicateWithValue:YES]], @"implemented");
    RLMAssertThrowsWithReason([[managed.dateObj sortedResultsUsingKeyPath:@"self" ascending:NO] 
                               indexOfObjectWithPredicate:[NSPredicate predicateWithValue:YES]], @"implemented");
    RLMAssertThrowsWithReason([[managed.decimalObj sortedResultsUsingKeyPath:@"self" ascending:NO] 
                               indexOfObjectWithPredicate:[NSPredicate predicateWithValue:YES]], @"implemented");
    RLMAssertThrowsWithReason([[managed.objectIdObj sortedResultsUsingKeyPath:@"self" ascending:NO] 
                               indexOfObjectWithPredicate:[NSPredicate predicateWithValue:YES]], @"implemented");
    RLMAssertThrowsWithReason([[optManaged.boolObj sortedResultsUsingKeyPath:@"self" ascending:NO] 
                               indexOfObjectWithPredicate:[NSPredicate predicateWithValue:YES]], @"implemented");
    RLMAssertThrowsWithReason([[optManaged.intObj sortedResultsUsingKeyPath:@"self" ascending:NO] 
                               indexOfObjectWithPredicate:[NSPredicate predicateWithValue:YES]], @"implemented");
    RLMAssertThrowsWithReason([[optManaged.floatObj sortedResultsUsingKeyPath:@"self" ascending:NO] 
                               indexOfObjectWithPredicate:[NSPredicate predicateWithValue:YES]], @"implemented");
    RLMAssertThrowsWithReason([[optManaged.doubleObj sortedResultsUsingKeyPath:@"self" ascending:NO] 
                               indexOfObjectWithPredicate:[NSPredicate predicateWithValue:YES]], @"implemented");
    RLMAssertThrowsWithReason([[optManaged.stringObj sortedResultsUsingKeyPath:@"self" ascending:NO] 
                               indexOfObjectWithPredicate:[NSPredicate predicateWithValue:YES]], @"implemented");
    RLMAssertThrowsWithReason([[optManaged.dataObj sortedResultsUsingKeyPath:@"self" ascending:NO] 
                               indexOfObjectWithPredicate:[NSPredicate predicateWithValue:YES]], @"implemented");
    RLMAssertThrowsWithReason([[optManaged.dateObj sortedResultsUsingKeyPath:@"self" ascending:NO] 
                               indexOfObjectWithPredicate:[NSPredicate predicateWithValue:YES]], @"implemented");
    RLMAssertThrowsWithReason([[optManaged.decimalObj sortedResultsUsingKeyPath:@"self" ascending:NO] 
                               indexOfObjectWithPredicate:[NSPredicate predicateWithValue:YES]], @"implemented");
    RLMAssertThrowsWithReason([[optManaged.objectIdObj sortedResultsUsingKeyPath:@"self" ascending:NO] 
                               indexOfObjectWithPredicate:[NSPredicate predicateWithValue:YES]], @"implemented");

    XCTAssertEqual(NSNotFound, [unmanaged.boolObj indexOfObjectWithPredicate:[NSPredicate predicateWithValue:YES]]);
    XCTAssertEqual(NSNotFound, [unmanaged.intObj indexOfObjectWithPredicate:[NSPredicate predicateWithValue:YES]]);
    XCTAssertEqual(NSNotFound, [unmanaged.floatObj indexOfObjectWithPredicate:[NSPredicate predicateWithValue:YES]]);
    XCTAssertEqual(NSNotFound, [unmanaged.doubleObj indexOfObjectWithPredicate:[NSPredicate predicateWithValue:YES]]);
    XCTAssertEqual(NSNotFound, [unmanaged.stringObj indexOfObjectWithPredicate:[NSPredicate predicateWithValue:YES]]);
    XCTAssertEqual(NSNotFound, [unmanaged.dataObj indexOfObjectWithPredicate:[NSPredicate predicateWithValue:YES]]);
    XCTAssertEqual(NSNotFound, [unmanaged.dateObj indexOfObjectWithPredicate:[NSPredicate predicateWithValue:YES]]);
    XCTAssertEqual(NSNotFound, [unmanaged.decimalObj indexOfObjectWithPredicate:[NSPredicate predicateWithValue:YES]]);
    XCTAssertEqual(NSNotFound, [unmanaged.objectIdObj indexOfObjectWithPredicate:[NSPredicate predicateWithValue:YES]]);
    XCTAssertEqual(NSNotFound, [optUnmanaged.boolObj indexOfObjectWithPredicate:[NSPredicate predicateWithValue:YES]]);
    XCTAssertEqual(NSNotFound, [optUnmanaged.intObj indexOfObjectWithPredicate:[NSPredicate predicateWithValue:YES]]);
    XCTAssertEqual(NSNotFound, [optUnmanaged.floatObj indexOfObjectWithPredicate:[NSPredicate predicateWithValue:YES]]);
    XCTAssertEqual(NSNotFound, [optUnmanaged.doubleObj indexOfObjectWithPredicate:[NSPredicate predicateWithValue:YES]]);
    XCTAssertEqual(NSNotFound, [optUnmanaged.stringObj indexOfObjectWithPredicate:[NSPredicate predicateWithValue:YES]]);
    XCTAssertEqual(NSNotFound, [optUnmanaged.dataObj indexOfObjectWithPredicate:[NSPredicate predicateWithValue:YES]]);
    XCTAssertEqual(NSNotFound, [optUnmanaged.dateObj indexOfObjectWithPredicate:[NSPredicate predicateWithValue:YES]]);
    XCTAssertEqual(NSNotFound, [optUnmanaged.decimalObj indexOfObjectWithPredicate:[NSPredicate predicateWithValue:YES]]);
    XCTAssertEqual(NSNotFound, [optUnmanaged.objectIdObj indexOfObjectWithPredicate:[NSPredicate predicateWithValue:YES]]);

    [self addObjects];

    XCTAssertEqual(0U, [unmanaged.boolObj indexOfObjectWithPredicate:[NSPredicate predicateWithValue:YES]]);
    XCTAssertEqual(0U, [unmanaged.intObj indexOfObjectWithPredicate:[NSPredicate predicateWithValue:YES]]);
    XCTAssertEqual(0U, [unmanaged.floatObj indexOfObjectWithPredicate:[NSPredicate predicateWithValue:YES]]);
    XCTAssertEqual(0U, [unmanaged.doubleObj indexOfObjectWithPredicate:[NSPredicate predicateWithValue:YES]]);
    XCTAssertEqual(0U, [unmanaged.stringObj indexOfObjectWithPredicate:[NSPredicate predicateWithValue:YES]]);
    XCTAssertEqual(0U, [unmanaged.dataObj indexOfObjectWithPredicate:[NSPredicate predicateWithValue:YES]]);
    XCTAssertEqual(0U, [unmanaged.dateObj indexOfObjectWithPredicate:[NSPredicate predicateWithValue:YES]]);
    XCTAssertEqual(0U, [unmanaged.decimalObj indexOfObjectWithPredicate:[NSPredicate predicateWithValue:YES]]);
    XCTAssertEqual(0U, [unmanaged.objectIdObj indexOfObjectWithPredicate:[NSPredicate predicateWithValue:YES]]);
    XCTAssertEqual(0U, [optUnmanaged.boolObj indexOfObjectWithPredicate:[NSPredicate predicateWithValue:YES]]);
    XCTAssertEqual(0U, [optUnmanaged.intObj indexOfObjectWithPredicate:[NSPredicate predicateWithValue:YES]]);
    XCTAssertEqual(0U, [optUnmanaged.floatObj indexOfObjectWithPredicate:[NSPredicate predicateWithValue:YES]]);
    XCTAssertEqual(0U, [optUnmanaged.doubleObj indexOfObjectWithPredicate:[NSPredicate predicateWithValue:YES]]);
    XCTAssertEqual(0U, [optUnmanaged.stringObj indexOfObjectWithPredicate:[NSPredicate predicateWithValue:YES]]);
    XCTAssertEqual(0U, [optUnmanaged.dataObj indexOfObjectWithPredicate:[NSPredicate predicateWithValue:YES]]);
    XCTAssertEqual(0U, [optUnmanaged.dateObj indexOfObjectWithPredicate:[NSPredicate predicateWithValue:YES]]);
    XCTAssertEqual(0U, [optUnmanaged.decimalObj indexOfObjectWithPredicate:[NSPredicate predicateWithValue:YES]]);
    XCTAssertEqual(0U, [optUnmanaged.objectIdObj indexOfObjectWithPredicate:[NSPredicate predicateWithValue:YES]]);
    XCTAssertEqual(NSNotFound, [unmanaged.boolObj indexOfObjectWithPredicate:[NSPredicate predicateWithValue:NO]]);
    XCTAssertEqual(NSNotFound, [unmanaged.intObj indexOfObjectWithPredicate:[NSPredicate predicateWithValue:NO]]);
    XCTAssertEqual(NSNotFound, [unmanaged.floatObj indexOfObjectWithPredicate:[NSPredicate predicateWithValue:NO]]);
    XCTAssertEqual(NSNotFound, [unmanaged.doubleObj indexOfObjectWithPredicate:[NSPredicate predicateWithValue:NO]]);
    XCTAssertEqual(NSNotFound, [unmanaged.stringObj indexOfObjectWithPredicate:[NSPredicate predicateWithValue:NO]]);
    XCTAssertEqual(NSNotFound, [unmanaged.dataObj indexOfObjectWithPredicate:[NSPredicate predicateWithValue:NO]]);
    XCTAssertEqual(NSNotFound, [unmanaged.dateObj indexOfObjectWithPredicate:[NSPredicate predicateWithValue:NO]]);
    XCTAssertEqual(NSNotFound, [unmanaged.decimalObj indexOfObjectWithPredicate:[NSPredicate predicateWithValue:NO]]);
    XCTAssertEqual(NSNotFound, [unmanaged.objectIdObj indexOfObjectWithPredicate:[NSPredicate predicateWithValue:NO]]);
    XCTAssertEqual(NSNotFound, [optUnmanaged.boolObj indexOfObjectWithPredicate:[NSPredicate predicateWithValue:NO]]);
    XCTAssertEqual(NSNotFound, [optUnmanaged.intObj indexOfObjectWithPredicate:[NSPredicate predicateWithValue:NO]]);
    XCTAssertEqual(NSNotFound, [optUnmanaged.floatObj indexOfObjectWithPredicate:[NSPredicate predicateWithValue:NO]]);
    XCTAssertEqual(NSNotFound, [optUnmanaged.doubleObj indexOfObjectWithPredicate:[NSPredicate predicateWithValue:NO]]);
    XCTAssertEqual(NSNotFound, [optUnmanaged.stringObj indexOfObjectWithPredicate:[NSPredicate predicateWithValue:NO]]);
    XCTAssertEqual(NSNotFound, [optUnmanaged.dataObj indexOfObjectWithPredicate:[NSPredicate predicateWithValue:NO]]);
    XCTAssertEqual(NSNotFound, [optUnmanaged.dateObj indexOfObjectWithPredicate:[NSPredicate predicateWithValue:NO]]);
    XCTAssertEqual(NSNotFound, [optUnmanaged.decimalObj indexOfObjectWithPredicate:[NSPredicate predicateWithValue:NO]]);
    XCTAssertEqual(NSNotFound, [optUnmanaged.objectIdObj indexOfObjectWithPredicate:[NSPredicate predicateWithValue:NO]]);
}

- (void)testSort {
    RLMAssertThrowsWithReason([unmanaged.boolObj sortedResultsUsingKeyPath:@"self" ascending:NO], 
                              @"This method may only be called on RLMSet instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.intObj sortedResultsUsingKeyPath:@"self" ascending:NO], 
                              @"This method may only be called on RLMSet instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.floatObj sortedResultsUsingKeyPath:@"self" ascending:NO], 
                              @"This method may only be called on RLMSet instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.doubleObj sortedResultsUsingKeyPath:@"self" ascending:NO], 
                              @"This method may only be called on RLMSet instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.stringObj sortedResultsUsingKeyPath:@"self" ascending:NO], 
                              @"This method may only be called on RLMSet instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.dataObj sortedResultsUsingKeyPath:@"self" ascending:NO], 
                              @"This method may only be called on RLMSet instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.dateObj sortedResultsUsingKeyPath:@"self" ascending:NO], 
                              @"This method may only be called on RLMSet instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.decimalObj sortedResultsUsingKeyPath:@"self" ascending:NO], 
                              @"This method may only be called on RLMSet instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.objectIdObj sortedResultsUsingKeyPath:@"self" ascending:NO], 
                              @"This method may only be called on RLMSet instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([optUnmanaged.boolObj sortedResultsUsingKeyPath:@"self" ascending:NO], 
                              @"This method may only be called on RLMSet instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([optUnmanaged.intObj sortedResultsUsingKeyPath:@"self" ascending:NO], 
                              @"This method may only be called on RLMSet instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([optUnmanaged.floatObj sortedResultsUsingKeyPath:@"self" ascending:NO], 
                              @"This method may only be called on RLMSet instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([optUnmanaged.doubleObj sortedResultsUsingKeyPath:@"self" ascending:NO], 
                              @"This method may only be called on RLMSet instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([optUnmanaged.stringObj sortedResultsUsingKeyPath:@"self" ascending:NO], 
                              @"This method may only be called on RLMSet instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([optUnmanaged.dataObj sortedResultsUsingKeyPath:@"self" ascending:NO], 
                              @"This method may only be called on RLMSet instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([optUnmanaged.dateObj sortedResultsUsingKeyPath:@"self" ascending:NO], 
                              @"This method may only be called on RLMSet instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([optUnmanaged.decimalObj sortedResultsUsingKeyPath:@"self" ascending:NO], 
                              @"This method may only be called on RLMSet instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([optUnmanaged.objectIdObj sortedResultsUsingKeyPath:@"self" ascending:NO], 
                              @"This method may only be called on RLMSet instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.boolObj sortedResultsUsingDescriptors:@[]], 
                              @"This method may only be called on RLMSet instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.intObj sortedResultsUsingDescriptors:@[]], 
                              @"This method may only be called on RLMSet instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.floatObj sortedResultsUsingDescriptors:@[]], 
                              @"This method may only be called on RLMSet instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.doubleObj sortedResultsUsingDescriptors:@[]], 
                              @"This method may only be called on RLMSet instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.stringObj sortedResultsUsingDescriptors:@[]], 
                              @"This method may only be called on RLMSet instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.dataObj sortedResultsUsingDescriptors:@[]], 
                              @"This method may only be called on RLMSet instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.dateObj sortedResultsUsingDescriptors:@[]], 
                              @"This method may only be called on RLMSet instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.decimalObj sortedResultsUsingDescriptors:@[]], 
                              @"This method may only be called on RLMSet instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.objectIdObj sortedResultsUsingDescriptors:@[]], 
                              @"This method may only be called on RLMSet instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([optUnmanaged.boolObj sortedResultsUsingDescriptors:@[]], 
                              @"This method may only be called on RLMSet instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([optUnmanaged.intObj sortedResultsUsingDescriptors:@[]], 
                              @"This method may only be called on RLMSet instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([optUnmanaged.floatObj sortedResultsUsingDescriptors:@[]], 
                              @"This method may only be called on RLMSet instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([optUnmanaged.doubleObj sortedResultsUsingDescriptors:@[]], 
                              @"This method may only be called on RLMSet instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([optUnmanaged.stringObj sortedResultsUsingDescriptors:@[]], 
                              @"This method may only be called on RLMSet instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([optUnmanaged.dataObj sortedResultsUsingDescriptors:@[]], 
                              @"This method may only be called on RLMSet instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([optUnmanaged.dateObj sortedResultsUsingDescriptors:@[]], 
                              @"This method may only be called on RLMSet instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([optUnmanaged.decimalObj sortedResultsUsingDescriptors:@[]], 
                              @"This method may only be called on RLMSet instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([optUnmanaged.objectIdObj sortedResultsUsingDescriptors:@[]], 
                              @"This method may only be called on RLMSet instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([managed.boolObj sortedResultsUsingKeyPath:@"not self" ascending:NO], 
                              @"can only be sorted on 'self'");
    RLMAssertThrowsWithReason([managed.intObj sortedResultsUsingKeyPath:@"not self" ascending:NO], 
                              @"can only be sorted on 'self'");
    RLMAssertThrowsWithReason([managed.floatObj sortedResultsUsingKeyPath:@"not self" ascending:NO], 
                              @"can only be sorted on 'self'");
    RLMAssertThrowsWithReason([managed.doubleObj sortedResultsUsingKeyPath:@"not self" ascending:NO], 
                              @"can only be sorted on 'self'");
    RLMAssertThrowsWithReason([managed.stringObj sortedResultsUsingKeyPath:@"not self" ascending:NO], 
                              @"can only be sorted on 'self'");
    RLMAssertThrowsWithReason([managed.dataObj sortedResultsUsingKeyPath:@"not self" ascending:NO], 
                              @"can only be sorted on 'self'");
    RLMAssertThrowsWithReason([managed.dateObj sortedResultsUsingKeyPath:@"not self" ascending:NO], 
                              @"can only be sorted on 'self'");
    RLMAssertThrowsWithReason([managed.decimalObj sortedResultsUsingKeyPath:@"not self" ascending:NO], 
                              @"can only be sorted on 'self'");
    RLMAssertThrowsWithReason([managed.objectIdObj sortedResultsUsingKeyPath:@"not self" ascending:NO], 
                              @"can only be sorted on 'self'");
    RLMAssertThrowsWithReason([optManaged.boolObj sortedResultsUsingKeyPath:@"not self" ascending:NO], 
                              @"can only be sorted on 'self'");
    RLMAssertThrowsWithReason([optManaged.intObj sortedResultsUsingKeyPath:@"not self" ascending:NO], 
                              @"can only be sorted on 'self'");
    RLMAssertThrowsWithReason([optManaged.floatObj sortedResultsUsingKeyPath:@"not self" ascending:NO], 
                              @"can only be sorted on 'self'");
    RLMAssertThrowsWithReason([optManaged.doubleObj sortedResultsUsingKeyPath:@"not self" ascending:NO], 
                              @"can only be sorted on 'self'");
    RLMAssertThrowsWithReason([optManaged.stringObj sortedResultsUsingKeyPath:@"not self" ascending:NO], 
                              @"can only be sorted on 'self'");
    RLMAssertThrowsWithReason([optManaged.dataObj sortedResultsUsingKeyPath:@"not self" ascending:NO], 
                              @"can only be sorted on 'self'");
    RLMAssertThrowsWithReason([optManaged.dateObj sortedResultsUsingKeyPath:@"not self" ascending:NO], 
                              @"can only be sorted on 'self'");
    RLMAssertThrowsWithReason([optManaged.decimalObj sortedResultsUsingKeyPath:@"not self" ascending:NO], 
                              @"can only be sorted on 'self'");
    RLMAssertThrowsWithReason([optManaged.objectIdObj sortedResultsUsingKeyPath:@"not self" ascending:NO], 
                              @"can only be sorted on 'self'");

    [managed.boolObj addObjects:@[@NO, @YES, @NO]];
    [managed.intObj addObjects:@[@2, @3, @2]];
    [managed.floatObj addObjects:@[@2.2f, @3.3f, @2.2f]];
    [managed.doubleObj addObjects:@[@2.2, @3.3, @2.2]];
    [managed.stringObj addObjects:@[@"a", @"b", @"a"]];
    [managed.dataObj addObjects:@[data(1), data(2), data(1)]];
    [managed.dateObj addObjects:@[date(1), date(2), date(1)]];
    [managed.decimalObj addObjects:@[decimal128(1), decimal128(2), decimal128(1)]];
    [managed.objectIdObj addObjects:@[objectId(1), objectId(2), objectId(1)]];
    [optManaged.boolObj addObjects:@[@NO, @YES, NSNull.null, @YES, @NO]];
    [optManaged.intObj addObjects:@[@2, @3, NSNull.null, @3, @2]];
    [optManaged.floatObj addObjects:@[@2.2f, @3.3f, NSNull.null, @3.3f, @2.2f]];
    [optManaged.doubleObj addObjects:@[@2.2, @3.3, NSNull.null, @3.3, @2.2]];
    [optManaged.stringObj addObjects:@[@"a", @"b", NSNull.null, @"b", @"a"]];
    [optManaged.dataObj addObjects:@[data(1), data(2), NSNull.null, data(2), data(1)]];
    [optManaged.dateObj addObjects:@[date(1), date(2), NSNull.null, date(2), date(1)]];
    [optManaged.decimalObj addObjects:@[decimal128(1), decimal128(2), NSNull.null, decimal128(2), decimal128(1)]];
    [optManaged.objectIdObj addObjects:@[objectId(1), objectId(2), NSNull.null, objectId(2), objectId(1)]];

    XCTAssertEqualObjects([[managed.boolObj sortedResultsUsingDescriptors:@[]] valueForKey:@"self"], 
                          (@[@NO, @YES, @NO]));
    XCTAssertEqualObjects([[managed.intObj sortedResultsUsingDescriptors:@[]] valueForKey:@"self"], 
                          (@[@2, @3, @2]));
    XCTAssertEqualObjects([[managed.floatObj sortedResultsUsingDescriptors:@[]] valueForKey:@"self"], 
                          (@[@2.2f, @3.3f, @2.2f]));
    XCTAssertEqualObjects([[managed.doubleObj sortedResultsUsingDescriptors:@[]] valueForKey:@"self"], 
                          (@[@2.2, @3.3, @2.2]));
    XCTAssertEqualObjects([[managed.stringObj sortedResultsUsingDescriptors:@[]] valueForKey:@"self"], 
                          (@[@"a", @"b", @"a"]));
    XCTAssertEqualObjects([[managed.dataObj sortedResultsUsingDescriptors:@[]] valueForKey:@"self"], 
                          (@[data(1), data(2), data(1)]));
    XCTAssertEqualObjects([[managed.dateObj sortedResultsUsingDescriptors:@[]] valueForKey:@"self"], 
                          (@[date(1), date(2), date(1)]));
    XCTAssertEqualObjects([[managed.decimalObj sortedResultsUsingDescriptors:@[]] valueForKey:@"self"], 
                          (@[decimal128(1), decimal128(2), decimal128(1)]));
    XCTAssertEqualObjects([[managed.objectIdObj sortedResultsUsingDescriptors:@[]] valueForKey:@"self"], 
                          (@[objectId(1), objectId(2), objectId(1)]));
    XCTAssertEqualObjects([[optManaged.boolObj sortedResultsUsingDescriptors:@[]] valueForKey:@"self"], 
                          (@[@NO, @YES, NSNull.null, @YES, @NO]));
    XCTAssertEqualObjects([[optManaged.intObj sortedResultsUsingDescriptors:@[]] valueForKey:@"self"], 
                          (@[@2, @3, NSNull.null, @3, @2]));
    XCTAssertEqualObjects([[optManaged.floatObj sortedResultsUsingDescriptors:@[]] valueForKey:@"self"], 
                          (@[@2.2f, @3.3f, NSNull.null, @3.3f, @2.2f]));
    XCTAssertEqualObjects([[optManaged.doubleObj sortedResultsUsingDescriptors:@[]] valueForKey:@"self"], 
                          (@[@2.2, @3.3, NSNull.null, @3.3, @2.2]));
    XCTAssertEqualObjects([[optManaged.stringObj sortedResultsUsingDescriptors:@[]] valueForKey:@"self"], 
                          (@[@"a", @"b", NSNull.null, @"b", @"a"]));
    XCTAssertEqualObjects([[optManaged.dataObj sortedResultsUsingDescriptors:@[]] valueForKey:@"self"], 
                          (@[data(1), data(2), NSNull.null, data(2), data(1)]));
    XCTAssertEqualObjects([[optManaged.dateObj sortedResultsUsingDescriptors:@[]] valueForKey:@"self"], 
                          (@[date(1), date(2), NSNull.null, date(2), date(1)]));
    XCTAssertEqualObjects([[optManaged.decimalObj sortedResultsUsingDescriptors:@[]] valueForKey:@"self"], 
                          (@[decimal128(1), decimal128(2), NSNull.null, decimal128(2), decimal128(1)]));
    XCTAssertEqualObjects([[optManaged.objectIdObj sortedResultsUsingDescriptors:@[]] valueForKey:@"self"], 
                          (@[objectId(1), objectId(2), NSNull.null, objectId(2), objectId(1)]));

    XCTAssertEqualObjects([[managed.boolObj sortedResultsUsingKeyPath:@"self" ascending:NO] valueForKey:@"self"], 
                          (@[@YES, @NO, @NO]));
    XCTAssertEqualObjects([[managed.intObj sortedResultsUsingKeyPath:@"self" ascending:NO] valueForKey:@"self"], 
                          (@[@3, @2, @2]));
    XCTAssertEqualObjects([[managed.floatObj sortedResultsUsingKeyPath:@"self" ascending:NO] valueForKey:@"self"], 
                          (@[@3.3f, @2.2f, @2.2f]));
    XCTAssertEqualObjects([[managed.doubleObj sortedResultsUsingKeyPath:@"self" ascending:NO] valueForKey:@"self"], 
                          (@[@3.3, @2.2, @2.2]));
    XCTAssertEqualObjects([[managed.stringObj sortedResultsUsingKeyPath:@"self" ascending:NO] valueForKey:@"self"], 
                          (@[@"b", @"a", @"a"]));
    XCTAssertEqualObjects([[managed.dataObj sortedResultsUsingKeyPath:@"self" ascending:NO] valueForKey:@"self"], 
                          (@[data(2), data(1), data(1)]));
    XCTAssertEqualObjects([[managed.dateObj sortedResultsUsingKeyPath:@"self" ascending:NO] valueForKey:@"self"], 
                          (@[date(2), date(1), date(1)]));
    XCTAssertEqualObjects([[managed.decimalObj sortedResultsUsingKeyPath:@"self" ascending:NO] valueForKey:@"self"], 
                          (@[decimal128(2), decimal128(1), decimal128(1)]));
    XCTAssertEqualObjects([[managed.objectIdObj sortedResultsUsingKeyPath:@"self" ascending:NO] valueForKey:@"self"], 
                          (@[objectId(2), objectId(1), objectId(1)]));
    XCTAssertEqualObjects([[optManaged.boolObj sortedResultsUsingKeyPath:@"self" ascending:NO] valueForKey:@"self"], 
                          (@[@YES, @YES, @NO, @NO, NSNull.null]));
    XCTAssertEqualObjects([[optManaged.intObj sortedResultsUsingKeyPath:@"self" ascending:NO] valueForKey:@"self"], 
                          (@[@3, @3, @2, @2, NSNull.null]));
    XCTAssertEqualObjects([[optManaged.floatObj sortedResultsUsingKeyPath:@"self" ascending:NO] valueForKey:@"self"], 
                          (@[@3.3f, @3.3f, @2.2f, @2.2f, NSNull.null]));
    XCTAssertEqualObjects([[optManaged.doubleObj sortedResultsUsingKeyPath:@"self" ascending:NO] valueForKey:@"self"], 
                          (@[@3.3, @3.3, @2.2, @2.2, NSNull.null]));
    XCTAssertEqualObjects([[optManaged.stringObj sortedResultsUsingKeyPath:@"self" ascending:NO] valueForKey:@"self"], 
                          (@[@"b", @"b", @"a", @"a", NSNull.null]));
    XCTAssertEqualObjects([[optManaged.dataObj sortedResultsUsingKeyPath:@"self" ascending:NO] valueForKey:@"self"], 
                          (@[data(2), data(2), data(1), data(1), NSNull.null]));
    XCTAssertEqualObjects([[optManaged.dateObj sortedResultsUsingKeyPath:@"self" ascending:NO] valueForKey:@"self"], 
                          (@[date(2), date(2), date(1), date(1), NSNull.null]));
    XCTAssertEqualObjects([[optManaged.decimalObj sortedResultsUsingKeyPath:@"self" ascending:NO] valueForKey:@"self"], 
                          (@[decimal128(2), decimal128(2), decimal128(1), decimal128(1), NSNull.null]));
    XCTAssertEqualObjects([[optManaged.objectIdObj sortedResultsUsingKeyPath:@"self" ascending:NO] valueForKey:@"self"], 
                          (@[objectId(2), objectId(2), objectId(1), objectId(1), NSNull.null]));

    XCTAssertEqualObjects([[managed.boolObj sortedResultsUsingKeyPath:@"self" ascending:YES] valueForKey:@"self"], 
                          (@[@NO, @NO, @YES]));
    XCTAssertEqualObjects([[managed.intObj sortedResultsUsingKeyPath:@"self" ascending:YES] valueForKey:@"self"], 
                          (@[@2, @2, @3]));
    XCTAssertEqualObjects([[managed.floatObj sortedResultsUsingKeyPath:@"self" ascending:YES] valueForKey:@"self"], 
                          (@[@2.2f, @2.2f, @3.3f]));
    XCTAssertEqualObjects([[managed.doubleObj sortedResultsUsingKeyPath:@"self" ascending:YES] valueForKey:@"self"], 
                          (@[@2.2, @2.2, @3.3]));
    XCTAssertEqualObjects([[managed.stringObj sortedResultsUsingKeyPath:@"self" ascending:YES] valueForKey:@"self"], 
                          (@[@"a", @"a", @"b"]));
    XCTAssertEqualObjects([[managed.dataObj sortedResultsUsingKeyPath:@"self" ascending:YES] valueForKey:@"self"], 
                          (@[data(1), data(1), data(2)]));
    XCTAssertEqualObjects([[managed.dateObj sortedResultsUsingKeyPath:@"self" ascending:YES] valueForKey:@"self"], 
                          (@[date(1), date(1), date(2)]));
    XCTAssertEqualObjects([[managed.decimalObj sortedResultsUsingKeyPath:@"self" ascending:YES] valueForKey:@"self"], 
                          (@[decimal128(1), decimal128(1), decimal128(2)]));
    XCTAssertEqualObjects([[managed.objectIdObj sortedResultsUsingKeyPath:@"self" ascending:YES] valueForKey:@"self"], 
                          (@[objectId(1), objectId(1), objectId(2)]));
    XCTAssertEqualObjects([[optManaged.boolObj sortedResultsUsingKeyPath:@"self" ascending:YES] valueForKey:@"self"], 
                          (@[NSNull.null, @NO, @NO, @YES, @YES]));
    XCTAssertEqualObjects([[optManaged.intObj sortedResultsUsingKeyPath:@"self" ascending:YES] valueForKey:@"self"], 
                          (@[NSNull.null, @2, @2, @3, @3]));
    XCTAssertEqualObjects([[optManaged.floatObj sortedResultsUsingKeyPath:@"self" ascending:YES] valueForKey:@"self"], 
                          (@[NSNull.null, @2.2f, @2.2f, @3.3f, @3.3f]));
    XCTAssertEqualObjects([[optManaged.doubleObj sortedResultsUsingKeyPath:@"self" ascending:YES] valueForKey:@"self"], 
                          (@[NSNull.null, @2.2, @2.2, @3.3, @3.3]));
    XCTAssertEqualObjects([[optManaged.stringObj sortedResultsUsingKeyPath:@"self" ascending:YES] valueForKey:@"self"], 
                          (@[NSNull.null, @"a", @"a", @"b", @"b"]));
    XCTAssertEqualObjects([[optManaged.dataObj sortedResultsUsingKeyPath:@"self" ascending:YES] valueForKey:@"self"], 
                          (@[NSNull.null, data(1), data(1), data(2), data(2)]));
    XCTAssertEqualObjects([[optManaged.dateObj sortedResultsUsingKeyPath:@"self" ascending:YES] valueForKey:@"self"], 
                          (@[NSNull.null, date(1), date(1), date(2), date(2)]));
    XCTAssertEqualObjects([[optManaged.decimalObj sortedResultsUsingKeyPath:@"self" ascending:YES] valueForKey:@"self"], 
                          (@[NSNull.null, decimal128(1), decimal128(1), decimal128(2), decimal128(2)]));
    XCTAssertEqualObjects([[optManaged.objectIdObj sortedResultsUsingKeyPath:@"self" ascending:YES] valueForKey:@"self"], 
                          (@[NSNull.null, objectId(1), objectId(1), objectId(2), objectId(2)]));
}

- (void)testFilter {
    RLMAssertThrowsWithReason([unmanaged.boolObj objectsWhere:@"TRUEPREDICATE"], 
                              @"This method may only be called on RLMSet instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.intObj objectsWhere:@"TRUEPREDICATE"], 
                              @"This method may only be called on RLMSet instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.floatObj objectsWhere:@"TRUEPREDICATE"], 
                              @"This method may only be called on RLMSet instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.doubleObj objectsWhere:@"TRUEPREDICATE"], 
                              @"This method may only be called on RLMSet instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.stringObj objectsWhere:@"TRUEPREDICATE"], 
                              @"This method may only be called on RLMSet instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.dataObj objectsWhere:@"TRUEPREDICATE"], 
                              @"This method may only be called on RLMSet instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.dateObj objectsWhere:@"TRUEPREDICATE"], 
                              @"This method may only be called on RLMSet instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.decimalObj objectsWhere:@"TRUEPREDICATE"], 
                              @"This method may only be called on RLMSet instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.objectIdObj objectsWhere:@"TRUEPREDICATE"], 
                              @"This method may only be called on RLMSet instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([optUnmanaged.boolObj objectsWhere:@"TRUEPREDICATE"], 
                              @"This method may only be called on RLMSet instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([optUnmanaged.intObj objectsWhere:@"TRUEPREDICATE"], 
                              @"This method may only be called on RLMSet instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([optUnmanaged.floatObj objectsWhere:@"TRUEPREDICATE"], 
                              @"This method may only be called on RLMSet instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([optUnmanaged.doubleObj objectsWhere:@"TRUEPREDICATE"], 
                              @"This method may only be called on RLMSet instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([optUnmanaged.stringObj objectsWhere:@"TRUEPREDICATE"], 
                              @"This method may only be called on RLMSet instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([optUnmanaged.dataObj objectsWhere:@"TRUEPREDICATE"], 
                              @"This method may only be called on RLMSet instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([optUnmanaged.dateObj objectsWhere:@"TRUEPREDICATE"], 
                              @"This method may only be called on RLMSet instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([optUnmanaged.decimalObj objectsWhere:@"TRUEPREDICATE"], 
                              @"This method may only be called on RLMSet instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([optUnmanaged.objectIdObj objectsWhere:@"TRUEPREDICATE"], 
                              @"This method may only be called on RLMSet instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.boolObj objectsWithPredicate:[NSPredicate predicateWithValue:YES]], 
                              @"This method may only be called on RLMSet instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.intObj objectsWithPredicate:[NSPredicate predicateWithValue:YES]], 
                              @"This method may only be called on RLMSet instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.floatObj objectsWithPredicate:[NSPredicate predicateWithValue:YES]], 
                              @"This method may only be called on RLMSet instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.doubleObj objectsWithPredicate:[NSPredicate predicateWithValue:YES]], 
                              @"This method may only be called on RLMSet instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.stringObj objectsWithPredicate:[NSPredicate predicateWithValue:YES]], 
                              @"This method may only be called on RLMSet instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.dataObj objectsWithPredicate:[NSPredicate predicateWithValue:YES]], 
                              @"This method may only be called on RLMSet instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.dateObj objectsWithPredicate:[NSPredicate predicateWithValue:YES]], 
                              @"This method may only be called on RLMSet instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.decimalObj objectsWithPredicate:[NSPredicate predicateWithValue:YES]], 
                              @"This method may only be called on RLMSet instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.objectIdObj objectsWithPredicate:[NSPredicate predicateWithValue:YES]], 
                              @"This method may only be called on RLMSet instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([optUnmanaged.boolObj objectsWithPredicate:[NSPredicate predicateWithValue:YES]], 
                              @"This method may only be called on RLMSet instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([optUnmanaged.intObj objectsWithPredicate:[NSPredicate predicateWithValue:YES]], 
                              @"This method may only be called on RLMSet instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([optUnmanaged.floatObj objectsWithPredicate:[NSPredicate predicateWithValue:YES]], 
                              @"This method may only be called on RLMSet instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([optUnmanaged.doubleObj objectsWithPredicate:[NSPredicate predicateWithValue:YES]], 
                              @"This method may only be called on RLMSet instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([optUnmanaged.stringObj objectsWithPredicate:[NSPredicate predicateWithValue:YES]], 
                              @"This method may only be called on RLMSet instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([optUnmanaged.dataObj objectsWithPredicate:[NSPredicate predicateWithValue:YES]], 
                              @"This method may only be called on RLMSet instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([optUnmanaged.dateObj objectsWithPredicate:[NSPredicate predicateWithValue:YES]], 
                              @"This method may only be called on RLMSet instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([optUnmanaged.decimalObj objectsWithPredicate:[NSPredicate predicateWithValue:YES]], 
                              @"This method may only be called on RLMSet instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([optUnmanaged.objectIdObj objectsWithPredicate:[NSPredicate predicateWithValue:YES]], 
                              @"This method may only be called on RLMSet instances retrieved from an RLMRealm");

    RLMAssertThrowsWithReason([managed.boolObj objectsWhere:@"TRUEPREDICATE"], 
                              @"implemented");
    RLMAssertThrowsWithReason([managed.intObj objectsWhere:@"TRUEPREDICATE"], 
                              @"implemented");
    RLMAssertThrowsWithReason([managed.floatObj objectsWhere:@"TRUEPREDICATE"], 
                              @"implemented");
    RLMAssertThrowsWithReason([managed.doubleObj objectsWhere:@"TRUEPREDICATE"], 
                              @"implemented");
    RLMAssertThrowsWithReason([managed.stringObj objectsWhere:@"TRUEPREDICATE"], 
                              @"implemented");
    RLMAssertThrowsWithReason([managed.dataObj objectsWhere:@"TRUEPREDICATE"], 
                              @"implemented");
    RLMAssertThrowsWithReason([managed.dateObj objectsWhere:@"TRUEPREDICATE"], 
                              @"implemented");
    RLMAssertThrowsWithReason([managed.decimalObj objectsWhere:@"TRUEPREDICATE"], 
                              @"implemented");
    RLMAssertThrowsWithReason([managed.objectIdObj objectsWhere:@"TRUEPREDICATE"], 
                              @"implemented");
    RLMAssertThrowsWithReason([optManaged.boolObj objectsWhere:@"TRUEPREDICATE"], 
                              @"implemented");
    RLMAssertThrowsWithReason([optManaged.intObj objectsWhere:@"TRUEPREDICATE"], 
                              @"implemented");
    RLMAssertThrowsWithReason([optManaged.floatObj objectsWhere:@"TRUEPREDICATE"], 
                              @"implemented");
    RLMAssertThrowsWithReason([optManaged.doubleObj objectsWhere:@"TRUEPREDICATE"], 
                              @"implemented");
    RLMAssertThrowsWithReason([optManaged.stringObj objectsWhere:@"TRUEPREDICATE"], 
                              @"implemented");
    RLMAssertThrowsWithReason([optManaged.dataObj objectsWhere:@"TRUEPREDICATE"], 
                              @"implemented");
    RLMAssertThrowsWithReason([optManaged.dateObj objectsWhere:@"TRUEPREDICATE"], 
                              @"implemented");
    RLMAssertThrowsWithReason([optManaged.decimalObj objectsWhere:@"TRUEPREDICATE"], 
                              @"implemented");
    RLMAssertThrowsWithReason([optManaged.objectIdObj objectsWhere:@"TRUEPREDICATE"], 
                              @"implemented");
    RLMAssertThrowsWithReason([managed.boolObj objectsWithPredicate:[NSPredicate predicateWithValue:YES]], 
                              @"implemented");
    RLMAssertThrowsWithReason([managed.intObj objectsWithPredicate:[NSPredicate predicateWithValue:YES]], 
                              @"implemented");
    RLMAssertThrowsWithReason([managed.floatObj objectsWithPredicate:[NSPredicate predicateWithValue:YES]], 
                              @"implemented");
    RLMAssertThrowsWithReason([managed.doubleObj objectsWithPredicate:[NSPredicate predicateWithValue:YES]], 
                              @"implemented");
    RLMAssertThrowsWithReason([managed.stringObj objectsWithPredicate:[NSPredicate predicateWithValue:YES]], 
                              @"implemented");
    RLMAssertThrowsWithReason([managed.dataObj objectsWithPredicate:[NSPredicate predicateWithValue:YES]], 
                              @"implemented");
    RLMAssertThrowsWithReason([managed.dateObj objectsWithPredicate:[NSPredicate predicateWithValue:YES]], 
                              @"implemented");
    RLMAssertThrowsWithReason([managed.decimalObj objectsWithPredicate:[NSPredicate predicateWithValue:YES]], 
                              @"implemented");
    RLMAssertThrowsWithReason([managed.objectIdObj objectsWithPredicate:[NSPredicate predicateWithValue:YES]], 
                              @"implemented");
    RLMAssertThrowsWithReason([optManaged.boolObj objectsWithPredicate:[NSPredicate predicateWithValue:YES]], 
                              @"implemented");
    RLMAssertThrowsWithReason([optManaged.intObj objectsWithPredicate:[NSPredicate predicateWithValue:YES]], 
                              @"implemented");
    RLMAssertThrowsWithReason([optManaged.floatObj objectsWithPredicate:[NSPredicate predicateWithValue:YES]], 
                              @"implemented");
    RLMAssertThrowsWithReason([optManaged.doubleObj objectsWithPredicate:[NSPredicate predicateWithValue:YES]], 
                              @"implemented");
    RLMAssertThrowsWithReason([optManaged.stringObj objectsWithPredicate:[NSPredicate predicateWithValue:YES]], 
                              @"implemented");
    RLMAssertThrowsWithReason([optManaged.dataObj objectsWithPredicate:[NSPredicate predicateWithValue:YES]], 
                              @"implemented");
    RLMAssertThrowsWithReason([optManaged.dateObj objectsWithPredicate:[NSPredicate predicateWithValue:YES]], 
                              @"implemented");
    RLMAssertThrowsWithReason([optManaged.decimalObj objectsWithPredicate:[NSPredicate predicateWithValue:YES]], 
                              @"implemented");
    RLMAssertThrowsWithReason([optManaged.objectIdObj objectsWithPredicate:[NSPredicate predicateWithValue:YES]], 
                              @"implemented");

    RLMAssertThrowsWithReason([[managed.boolObj sortedResultsUsingKeyPath:@"self" ascending:NO] 
                               objectsWhere:@"TRUEPREDICATE"], @"implemented");
    RLMAssertThrowsWithReason([[managed.intObj sortedResultsUsingKeyPath:@"self" ascending:NO] 
                               objectsWhere:@"TRUEPREDICATE"], @"implemented");
    RLMAssertThrowsWithReason([[managed.floatObj sortedResultsUsingKeyPath:@"self" ascending:NO] 
                               objectsWhere:@"TRUEPREDICATE"], @"implemented");
    RLMAssertThrowsWithReason([[managed.doubleObj sortedResultsUsingKeyPath:@"self" ascending:NO] 
                               objectsWhere:@"TRUEPREDICATE"], @"implemented");
    RLMAssertThrowsWithReason([[managed.stringObj sortedResultsUsingKeyPath:@"self" ascending:NO] 
                               objectsWhere:@"TRUEPREDICATE"], @"implemented");
    RLMAssertThrowsWithReason([[managed.dataObj sortedResultsUsingKeyPath:@"self" ascending:NO] 
                               objectsWhere:@"TRUEPREDICATE"], @"implemented");
    RLMAssertThrowsWithReason([[managed.dateObj sortedResultsUsingKeyPath:@"self" ascending:NO] 
                               objectsWhere:@"TRUEPREDICATE"], @"implemented");
    RLMAssertThrowsWithReason([[managed.decimalObj sortedResultsUsingKeyPath:@"self" ascending:NO] 
                               objectsWhere:@"TRUEPREDICATE"], @"implemented");
    RLMAssertThrowsWithReason([[managed.objectIdObj sortedResultsUsingKeyPath:@"self" ascending:NO] 
                               objectsWhere:@"TRUEPREDICATE"], @"implemented");
    RLMAssertThrowsWithReason([[optManaged.boolObj sortedResultsUsingKeyPath:@"self" ascending:NO] 
                               objectsWhere:@"TRUEPREDICATE"], @"implemented");
    RLMAssertThrowsWithReason([[optManaged.intObj sortedResultsUsingKeyPath:@"self" ascending:NO] 
                               objectsWhere:@"TRUEPREDICATE"], @"implemented");
    RLMAssertThrowsWithReason([[optManaged.floatObj sortedResultsUsingKeyPath:@"self" ascending:NO] 
                               objectsWhere:@"TRUEPREDICATE"], @"implemented");
    RLMAssertThrowsWithReason([[optManaged.doubleObj sortedResultsUsingKeyPath:@"self" ascending:NO] 
                               objectsWhere:@"TRUEPREDICATE"], @"implemented");
    RLMAssertThrowsWithReason([[optManaged.stringObj sortedResultsUsingKeyPath:@"self" ascending:NO] 
                               objectsWhere:@"TRUEPREDICATE"], @"implemented");
    RLMAssertThrowsWithReason([[optManaged.dataObj sortedResultsUsingKeyPath:@"self" ascending:NO] 
                               objectsWhere:@"TRUEPREDICATE"], @"implemented");
    RLMAssertThrowsWithReason([[optManaged.dateObj sortedResultsUsingKeyPath:@"self" ascending:NO] 
                               objectsWhere:@"TRUEPREDICATE"], @"implemented");
    RLMAssertThrowsWithReason([[optManaged.decimalObj sortedResultsUsingKeyPath:@"self" ascending:NO] 
                               objectsWhere:@"TRUEPREDICATE"], @"implemented");
    RLMAssertThrowsWithReason([[optManaged.objectIdObj sortedResultsUsingKeyPath:@"self" ascending:NO] 
                               objectsWhere:@"TRUEPREDICATE"], @"implemented");
    RLMAssertThrowsWithReason([[managed.boolObj sortedResultsUsingKeyPath:@"self" ascending:NO] 
                               objectsWithPredicate:[NSPredicate predicateWithValue:YES]], @"implemented");
    RLMAssertThrowsWithReason([[managed.intObj sortedResultsUsingKeyPath:@"self" ascending:NO] 
                               objectsWithPredicate:[NSPredicate predicateWithValue:YES]], @"implemented");
    RLMAssertThrowsWithReason([[managed.floatObj sortedResultsUsingKeyPath:@"self" ascending:NO] 
                               objectsWithPredicate:[NSPredicate predicateWithValue:YES]], @"implemented");
    RLMAssertThrowsWithReason([[managed.doubleObj sortedResultsUsingKeyPath:@"self" ascending:NO] 
                               objectsWithPredicate:[NSPredicate predicateWithValue:YES]], @"implemented");
    RLMAssertThrowsWithReason([[managed.stringObj sortedResultsUsingKeyPath:@"self" ascending:NO] 
                               objectsWithPredicate:[NSPredicate predicateWithValue:YES]], @"implemented");
    RLMAssertThrowsWithReason([[managed.dataObj sortedResultsUsingKeyPath:@"self" ascending:NO] 
                               objectsWithPredicate:[NSPredicate predicateWithValue:YES]], @"implemented");
    RLMAssertThrowsWithReason([[managed.dateObj sortedResultsUsingKeyPath:@"self" ascending:NO] 
                               objectsWithPredicate:[NSPredicate predicateWithValue:YES]], @"implemented");
    RLMAssertThrowsWithReason([[managed.decimalObj sortedResultsUsingKeyPath:@"self" ascending:NO] 
                               objectsWithPredicate:[NSPredicate predicateWithValue:YES]], @"implemented");
    RLMAssertThrowsWithReason([[managed.objectIdObj sortedResultsUsingKeyPath:@"self" ascending:NO] 
                               objectsWithPredicate:[NSPredicate predicateWithValue:YES]], @"implemented");
    RLMAssertThrowsWithReason([[optManaged.boolObj sortedResultsUsingKeyPath:@"self" ascending:NO] 
                               objectsWithPredicate:[NSPredicate predicateWithValue:YES]], @"implemented");
    RLMAssertThrowsWithReason([[optManaged.intObj sortedResultsUsingKeyPath:@"self" ascending:NO] 
                               objectsWithPredicate:[NSPredicate predicateWithValue:YES]], @"implemented");
    RLMAssertThrowsWithReason([[optManaged.floatObj sortedResultsUsingKeyPath:@"self" ascending:NO] 
                               objectsWithPredicate:[NSPredicate predicateWithValue:YES]], @"implemented");
    RLMAssertThrowsWithReason([[optManaged.doubleObj sortedResultsUsingKeyPath:@"self" ascending:NO] 
                               objectsWithPredicate:[NSPredicate predicateWithValue:YES]], @"implemented");
    RLMAssertThrowsWithReason([[optManaged.stringObj sortedResultsUsingKeyPath:@"self" ascending:NO] 
                               objectsWithPredicate:[NSPredicate predicateWithValue:YES]], @"implemented");
    RLMAssertThrowsWithReason([[optManaged.dataObj sortedResultsUsingKeyPath:@"self" ascending:NO] 
                               objectsWithPredicate:[NSPredicate predicateWithValue:YES]], @"implemented");
    RLMAssertThrowsWithReason([[optManaged.dateObj sortedResultsUsingKeyPath:@"self" ascending:NO] 
                               objectsWithPredicate:[NSPredicate predicateWithValue:YES]], @"implemented");
    RLMAssertThrowsWithReason([[optManaged.decimalObj sortedResultsUsingKeyPath:@"self" ascending:NO] 
                               objectsWithPredicate:[NSPredicate predicateWithValue:YES]], @"implemented");
    RLMAssertThrowsWithReason([[optManaged.objectIdObj sortedResultsUsingKeyPath:@"self" ascending:NO] 
                               objectsWithPredicate:[NSPredicate predicateWithValue:YES]], @"implemented");
}

- (void)testNotifications {
    RLMAssertThrowsWithReason([unmanaged.boolObj addNotificationBlock:^(__unused id a, __unused id c, __unused id e) { }], 
                              @"This method may only be called on RLMSet instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.intObj addNotificationBlock:^(__unused id a, __unused id c, __unused id e) { }], 
                              @"This method may only be called on RLMSet instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.floatObj addNotificationBlock:^(__unused id a, __unused id c, __unused id e) { }], 
                              @"This method may only be called on RLMSet instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.doubleObj addNotificationBlock:^(__unused id a, __unused id c, __unused id e) { }], 
                              @"This method may only be called on RLMSet instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.stringObj addNotificationBlock:^(__unused id a, __unused id c, __unused id e) { }], 
                              @"This method may only be called on RLMSet instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.dataObj addNotificationBlock:^(__unused id a, __unused id c, __unused id e) { }], 
                              @"This method may only be called on RLMSet instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.dateObj addNotificationBlock:^(__unused id a, __unused id c, __unused id e) { }], 
                              @"This method may only be called on RLMSet instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.decimalObj addNotificationBlock:^(__unused id a, __unused id c, __unused id e) { }], 
                              @"This method may only be called on RLMSet instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.objectIdObj addNotificationBlock:^(__unused id a, __unused id c, __unused id e) { }], 
                              @"This method may only be called on RLMSet instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([optUnmanaged.boolObj addNotificationBlock:^(__unused id a, __unused id c, __unused id e) { }], 
                              @"This method may only be called on RLMSet instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([optUnmanaged.intObj addNotificationBlock:^(__unused id a, __unused id c, __unused id e) { }], 
                              @"This method may only be called on RLMSet instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([optUnmanaged.floatObj addNotificationBlock:^(__unused id a, __unused id c, __unused id e) { }], 
                              @"This method may only be called on RLMSet instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([optUnmanaged.doubleObj addNotificationBlock:^(__unused id a, __unused id c, __unused id e) { }], 
                              @"This method may only be called on RLMSet instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([optUnmanaged.stringObj addNotificationBlock:^(__unused id a, __unused id c, __unused id e) { }], 
                              @"This method may only be called on RLMSet instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([optUnmanaged.dataObj addNotificationBlock:^(__unused id a, __unused id c, __unused id e) { }], 
                              @"This method may only be called on RLMSet instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([optUnmanaged.dateObj addNotificationBlock:^(__unused id a, __unused id c, __unused id e) { }], 
                              @"This method may only be called on RLMSet instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([optUnmanaged.decimalObj addNotificationBlock:^(__unused id a, __unused id c, __unused id e) { }], 
                              @"This method may only be called on RLMSet instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([optUnmanaged.objectIdObj addNotificationBlock:^(__unused id a, __unused id c, __unused id e) { }], 
                              @"This method may only be called on RLMSet instances retrieved from an RLMRealm");
}

- (void)testMin {
    RLMAssertThrowsWithReason([unmanaged.boolObj minOfProperty:@"self"], 
                              @"minOfProperty: is not supported for bool set");
    RLMAssertThrowsWithReason([unmanaged.stringObj minOfProperty:@"self"], 
                              @"minOfProperty: is not supported for string set");
    RLMAssertThrowsWithReason([unmanaged.dataObj minOfProperty:@"self"], 
                              @"minOfProperty: is not supported for data set");
    RLMAssertThrowsWithReason([unmanaged.objectIdObj minOfProperty:@"self"], 
                              @"minOfProperty: is not supported for object id set");
    RLMAssertThrowsWithReason([optUnmanaged.boolObj minOfProperty:@"self"], 
                              @"minOfProperty: is not supported for bool? set");
    RLMAssertThrowsWithReason([optUnmanaged.stringObj minOfProperty:@"self"], 
                              @"minOfProperty: is not supported for string? set");
    RLMAssertThrowsWithReason([optUnmanaged.dataObj minOfProperty:@"self"], 
                              @"minOfProperty: is not supported for data? set");
    RLMAssertThrowsWithReason([optUnmanaged.objectIdObj minOfProperty:@"self"], 
                              @"minOfProperty: is not supported for object id? set");
    RLMAssertThrowsWithReason([managed.boolObj minOfProperty:@"self"], 
                              @"minOfProperty: is not supported for bool set 'AllPrimitiveSets.boolObj'");
    RLMAssertThrowsWithReason([managed.stringObj minOfProperty:@"self"], 
                              @"minOfProperty: is not supported for string set 'AllPrimitiveSets.stringObj'");
    RLMAssertThrowsWithReason([managed.dataObj minOfProperty:@"self"], 
                              @"minOfProperty: is not supported for data set 'AllPrimitiveSets.dataObj'");
    RLMAssertThrowsWithReason([managed.objectIdObj minOfProperty:@"self"], 
                              @"minOfProperty: is not supported for object id set 'AllPrimitiveSets.objectIdObj'");
    RLMAssertThrowsWithReason([optManaged.boolObj minOfProperty:@"self"], 
                              @"minOfProperty: is not supported for bool? set 'AllOptionalPrimitiveSets.boolObj'");
    RLMAssertThrowsWithReason([optManaged.stringObj minOfProperty:@"self"], 
                              @"minOfProperty: is not supported for string? set 'AllOptionalPrimitiveSets.stringObj'");
    RLMAssertThrowsWithReason([optManaged.dataObj minOfProperty:@"self"], 
                              @"minOfProperty: is not supported for data? set 'AllOptionalPrimitiveSets.dataObj'");
    RLMAssertThrowsWithReason([optManaged.objectIdObj minOfProperty:@"self"], 
                              @"minOfProperty: is not supported for object id? set 'AllOptionalPrimitiveSets.objectIdObj'");

    XCTAssertNil([unmanaged.intObj minOfProperty:@"self"]);
    XCTAssertNil([unmanaged.floatObj minOfProperty:@"self"]);
    XCTAssertNil([unmanaged.doubleObj minOfProperty:@"self"]);
    XCTAssertNil([unmanaged.dateObj minOfProperty:@"self"]);
    XCTAssertNil([unmanaged.decimalObj minOfProperty:@"self"]);
    XCTAssertNil([optUnmanaged.intObj minOfProperty:@"self"]);
    XCTAssertNil([optUnmanaged.floatObj minOfProperty:@"self"]);
    XCTAssertNil([optUnmanaged.doubleObj minOfProperty:@"self"]);
    XCTAssertNil([optUnmanaged.dateObj minOfProperty:@"self"]);
    XCTAssertNil([optUnmanaged.decimalObj minOfProperty:@"self"]);
    XCTAssertNil([managed.intObj minOfProperty:@"self"]);
    XCTAssertNil([managed.floatObj minOfProperty:@"self"]);
    XCTAssertNil([managed.doubleObj minOfProperty:@"self"]);
    XCTAssertNil([managed.dateObj minOfProperty:@"self"]);
    XCTAssertNil([managed.decimalObj minOfProperty:@"self"]);
    XCTAssertNil([optManaged.intObj minOfProperty:@"self"]);
    XCTAssertNil([optManaged.floatObj minOfProperty:@"self"]);
    XCTAssertNil([optManaged.doubleObj minOfProperty:@"self"]);
    XCTAssertNil([optManaged.dateObj minOfProperty:@"self"]);
    XCTAssertNil([optManaged.decimalObj minOfProperty:@"self"]);

    [self addObjects];

    XCTAssertEqualObjects([unmanaged.intObj minOfProperty:@"self"], @2);
    XCTAssertEqualObjects([unmanaged.floatObj minOfProperty:@"self"], @2.2f);
    XCTAssertEqualObjects([unmanaged.doubleObj minOfProperty:@"self"], @2.2);
    XCTAssertEqualObjects([unmanaged.dateObj minOfProperty:@"self"], date(1));
    XCTAssertEqualObjects([unmanaged.decimalObj minOfProperty:@"self"], decimal128(1));
    XCTAssertEqualObjects([optUnmanaged.intObj minOfProperty:@"self"], @2);
    XCTAssertEqualObjects([optUnmanaged.floatObj minOfProperty:@"self"], @2.2f);
    XCTAssertEqualObjects([optUnmanaged.doubleObj minOfProperty:@"self"], @2.2);
    XCTAssertEqualObjects([optUnmanaged.dateObj minOfProperty:@"self"], date(1));
    XCTAssertEqualObjects([optUnmanaged.decimalObj minOfProperty:@"self"], decimal128(1));
    XCTAssertEqualObjects([managed.intObj minOfProperty:@"self"], @2);
    XCTAssertEqualObjects([managed.floatObj minOfProperty:@"self"], @2.2f);
    XCTAssertEqualObjects([managed.doubleObj minOfProperty:@"self"], @2.2);
    XCTAssertEqualObjects([managed.dateObj minOfProperty:@"self"], date(1));
    XCTAssertEqualObjects([managed.decimalObj minOfProperty:@"self"], decimal128(1));
    XCTAssertEqualObjects([optManaged.intObj minOfProperty:@"self"], @2);
    XCTAssertEqualObjects([optManaged.floatObj minOfProperty:@"self"], @2.2f);
    XCTAssertEqualObjects([optManaged.doubleObj minOfProperty:@"self"], @2.2);
    XCTAssertEqualObjects([optManaged.dateObj minOfProperty:@"self"], date(1));
    XCTAssertEqualObjects([optManaged.decimalObj minOfProperty:@"self"], decimal128(1));
}

- (void)testMax {
    RLMAssertThrowsWithReason([unmanaged.boolObj maxOfProperty:@"self"], 
                              @"maxOfProperty: is not supported for bool set");
    RLMAssertThrowsWithReason([unmanaged.stringObj maxOfProperty:@"self"], 
                              @"maxOfProperty: is not supported for string set");
    RLMAssertThrowsWithReason([unmanaged.dataObj maxOfProperty:@"self"], 
                              @"maxOfProperty: is not supported for data set");
    RLMAssertThrowsWithReason([unmanaged.objectIdObj maxOfProperty:@"self"], 
                              @"maxOfProperty: is not supported for object id set");
    RLMAssertThrowsWithReason([optUnmanaged.boolObj maxOfProperty:@"self"], 
                              @"maxOfProperty: is not supported for bool? set");
    RLMAssertThrowsWithReason([optUnmanaged.stringObj maxOfProperty:@"self"], 
                              @"maxOfProperty: is not supported for string? set");
    RLMAssertThrowsWithReason([optUnmanaged.dataObj maxOfProperty:@"self"], 
                              @"maxOfProperty: is not supported for data? set");
    RLMAssertThrowsWithReason([optUnmanaged.objectIdObj maxOfProperty:@"self"], 
                              @"maxOfProperty: is not supported for object id? set");
    RLMAssertThrowsWithReason([managed.boolObj maxOfProperty:@"self"], 
                              @"maxOfProperty: is not supported for bool set 'AllPrimitiveSets.boolObj'");
    RLMAssertThrowsWithReason([managed.stringObj maxOfProperty:@"self"], 
                              @"maxOfProperty: is not supported for string set 'AllPrimitiveSets.stringObj'");
    RLMAssertThrowsWithReason([managed.dataObj maxOfProperty:@"self"], 
                              @"maxOfProperty: is not supported for data set 'AllPrimitiveSets.dataObj'");
    RLMAssertThrowsWithReason([managed.objectIdObj maxOfProperty:@"self"], 
                              @"maxOfProperty: is not supported for object id set 'AllPrimitiveSets.objectIdObj'");
    RLMAssertThrowsWithReason([optManaged.boolObj maxOfProperty:@"self"], 
                              @"maxOfProperty: is not supported for bool? set 'AllOptionalPrimitiveSets.boolObj'");
    RLMAssertThrowsWithReason([optManaged.stringObj maxOfProperty:@"self"], 
                              @"maxOfProperty: is not supported for string? set 'AllOptionalPrimitiveSets.stringObj'");
    RLMAssertThrowsWithReason([optManaged.dataObj maxOfProperty:@"self"], 
                              @"maxOfProperty: is not supported for data? set 'AllOptionalPrimitiveSets.dataObj'");
    RLMAssertThrowsWithReason([optManaged.objectIdObj maxOfProperty:@"self"], 
                              @"maxOfProperty: is not supported for object id? set 'AllOptionalPrimitiveSets.objectIdObj'");

    XCTAssertNil([unmanaged.intObj maxOfProperty:@"self"]);
    XCTAssertNil([unmanaged.floatObj maxOfProperty:@"self"]);
    XCTAssertNil([unmanaged.doubleObj maxOfProperty:@"self"]);
    XCTAssertNil([unmanaged.dateObj maxOfProperty:@"self"]);
    XCTAssertNil([unmanaged.decimalObj maxOfProperty:@"self"]);
    XCTAssertNil([optUnmanaged.intObj maxOfProperty:@"self"]);
    XCTAssertNil([optUnmanaged.floatObj maxOfProperty:@"self"]);
    XCTAssertNil([optUnmanaged.doubleObj maxOfProperty:@"self"]);
    XCTAssertNil([optUnmanaged.dateObj maxOfProperty:@"self"]);
    XCTAssertNil([optUnmanaged.decimalObj maxOfProperty:@"self"]);
    XCTAssertNil([managed.intObj maxOfProperty:@"self"]);
    XCTAssertNil([managed.floatObj maxOfProperty:@"self"]);
    XCTAssertNil([managed.doubleObj maxOfProperty:@"self"]);
    XCTAssertNil([managed.dateObj maxOfProperty:@"self"]);
    XCTAssertNil([managed.decimalObj maxOfProperty:@"self"]);
    XCTAssertNil([optManaged.intObj maxOfProperty:@"self"]);
    XCTAssertNil([optManaged.floatObj maxOfProperty:@"self"]);
    XCTAssertNil([optManaged.doubleObj maxOfProperty:@"self"]);
    XCTAssertNil([optManaged.dateObj maxOfProperty:@"self"]);
    XCTAssertNil([optManaged.decimalObj maxOfProperty:@"self"]);

    [self addObjects];

    XCTAssertEqualObjects([unmanaged.intObj maxOfProperty:@"self"], @3);
    XCTAssertEqualObjects([unmanaged.floatObj maxOfProperty:@"self"], @3.3f);
    XCTAssertEqualObjects([unmanaged.doubleObj maxOfProperty:@"self"], @3.3);
    XCTAssertEqualObjects([unmanaged.dateObj maxOfProperty:@"self"], date(2));
    XCTAssertEqualObjects([unmanaged.decimalObj maxOfProperty:@"self"], decimal128(2));
    XCTAssertEqualObjects([optUnmanaged.intObj maxOfProperty:@"self"], @3);
    XCTAssertEqualObjects([optUnmanaged.floatObj maxOfProperty:@"self"], @3.3f);
    XCTAssertEqualObjects([optUnmanaged.doubleObj maxOfProperty:@"self"], @3.3);
    XCTAssertEqualObjects([optUnmanaged.dateObj maxOfProperty:@"self"], date(2));
    XCTAssertEqualObjects([optUnmanaged.decimalObj maxOfProperty:@"self"], decimal128(2));
    XCTAssertEqualObjects([managed.intObj maxOfProperty:@"self"], @3);
    XCTAssertEqualObjects([managed.floatObj maxOfProperty:@"self"], @3.3f);
    XCTAssertEqualObjects([managed.doubleObj maxOfProperty:@"self"], @3.3);
    XCTAssertEqualObjects([managed.dateObj maxOfProperty:@"self"], date(2));
    XCTAssertEqualObjects([managed.decimalObj maxOfProperty:@"self"], decimal128(2));
    XCTAssertEqualObjects([optManaged.intObj maxOfProperty:@"self"], @3);
    XCTAssertEqualObjects([optManaged.floatObj maxOfProperty:@"self"], @3.3f);
    XCTAssertEqualObjects([optManaged.doubleObj maxOfProperty:@"self"], @3.3);
    XCTAssertEqualObjects([optManaged.dateObj maxOfProperty:@"self"], date(2));
    XCTAssertEqualObjects([optManaged.decimalObj maxOfProperty:@"self"], decimal128(2));
}

- (void)testSum {
    RLMAssertThrowsWithReason([unmanaged.boolObj sumOfProperty:@"self"], 
                              @"sumOfProperty: is not supported for bool set");
    RLMAssertThrowsWithReason([unmanaged.stringObj sumOfProperty:@"self"], 
                              @"sumOfProperty: is not supported for string set");
    RLMAssertThrowsWithReason([unmanaged.dataObj sumOfProperty:@"self"], 
                              @"sumOfProperty: is not supported for data set");
    RLMAssertThrowsWithReason([unmanaged.dateObj sumOfProperty:@"self"], 
                              @"sumOfProperty: is not supported for date set");
    RLMAssertThrowsWithReason([unmanaged.objectIdObj sumOfProperty:@"self"], 
                              @"sumOfProperty: is not supported for object id set");
    RLMAssertThrowsWithReason([optUnmanaged.boolObj sumOfProperty:@"self"], 
                              @"sumOfProperty: is not supported for bool? set");
    RLMAssertThrowsWithReason([optUnmanaged.stringObj sumOfProperty:@"self"], 
                              @"sumOfProperty: is not supported for string? set");
    RLMAssertThrowsWithReason([optUnmanaged.dataObj sumOfProperty:@"self"], 
                              @"sumOfProperty: is not supported for data? set");
    RLMAssertThrowsWithReason([optUnmanaged.dateObj sumOfProperty:@"self"], 
                              @"sumOfProperty: is not supported for date? set");
    RLMAssertThrowsWithReason([optUnmanaged.objectIdObj sumOfProperty:@"self"], 
                              @"sumOfProperty: is not supported for object id? set");
    RLMAssertThrowsWithReason([managed.boolObj sumOfProperty:@"self"], 
                              @"sumOfProperty: is not supported for bool set 'AllPrimitiveSets.boolObj'");
    RLMAssertThrowsWithReason([managed.stringObj sumOfProperty:@"self"], 
                              @"sumOfProperty: is not supported for string set 'AllPrimitiveSets.stringObj'");
    RLMAssertThrowsWithReason([managed.dataObj sumOfProperty:@"self"], 
                              @"sumOfProperty: is not supported for data set 'AllPrimitiveSets.dataObj'");
    RLMAssertThrowsWithReason([managed.dateObj sumOfProperty:@"self"], 
                              @"sumOfProperty: is not supported for date set 'AllPrimitiveSets.dateObj'");
    RLMAssertThrowsWithReason([managed.objectIdObj sumOfProperty:@"self"], 
                              @"sumOfProperty: is not supported for object id set 'AllPrimitiveSets.objectIdObj'");
    RLMAssertThrowsWithReason([optManaged.boolObj sumOfProperty:@"self"], 
                              @"sumOfProperty: is not supported for bool? set 'AllOptionalPrimitiveSets.boolObj'");
    RLMAssertThrowsWithReason([optManaged.stringObj sumOfProperty:@"self"], 
                              @"sumOfProperty: is not supported for string? set 'AllOptionalPrimitiveSets.stringObj'");
    RLMAssertThrowsWithReason([optManaged.dataObj sumOfProperty:@"self"], 
                              @"sumOfProperty: is not supported for data? set 'AllOptionalPrimitiveSets.dataObj'");
    RLMAssertThrowsWithReason([optManaged.dateObj sumOfProperty:@"self"], 
                              @"sumOfProperty: is not supported for date? set 'AllOptionalPrimitiveSets.dateObj'");
    RLMAssertThrowsWithReason([optManaged.objectIdObj sumOfProperty:@"self"], 
                              @"sumOfProperty: is not supported for object id? set 'AllOptionalPrimitiveSets.objectIdObj'");

    XCTAssertEqualObjects([unmanaged.intObj sumOfProperty:@"self"], @0);
    XCTAssertEqualObjects([unmanaged.floatObj sumOfProperty:@"self"], @0);
    XCTAssertEqualObjects([unmanaged.doubleObj sumOfProperty:@"self"], @0);
    XCTAssertEqualObjects([unmanaged.decimalObj sumOfProperty:@"self"], @0);
    XCTAssertEqualObjects([optUnmanaged.intObj sumOfProperty:@"self"], @0);
    XCTAssertEqualObjects([optUnmanaged.floatObj sumOfProperty:@"self"], @0);
    XCTAssertEqualObjects([optUnmanaged.doubleObj sumOfProperty:@"self"], @0);
    XCTAssertEqualObjects([optUnmanaged.decimalObj sumOfProperty:@"self"], @0);
    XCTAssertEqualObjects([managed.intObj sumOfProperty:@"self"], @0);
    XCTAssertEqualObjects([managed.floatObj sumOfProperty:@"self"], @0);
    XCTAssertEqualObjects([managed.doubleObj sumOfProperty:@"self"], @0);
    XCTAssertEqualObjects([managed.decimalObj sumOfProperty:@"self"], @0);
    XCTAssertEqualObjects([optManaged.intObj sumOfProperty:@"self"], @0);
    XCTAssertEqualObjects([optManaged.floatObj sumOfProperty:@"self"], @0);
    XCTAssertEqualObjects([optManaged.doubleObj sumOfProperty:@"self"], @0);
    XCTAssertEqualObjects([optManaged.decimalObj sumOfProperty:@"self"], @0);

    [self addObjects];

    XCTAssertEqualWithAccuracy([unmanaged.intObj sumOfProperty:@"self"].doubleValue, sum(@[@2, @3]), .001);
    XCTAssertEqualWithAccuracy([unmanaged.floatObj sumOfProperty:@"self"].doubleValue, sum(@[@2.2f, @3.3f]), .001);
    XCTAssertEqualWithAccuracy([unmanaged.doubleObj sumOfProperty:@"self"].doubleValue, sum(@[@2.2, @3.3]), .001);
    XCTAssertEqualWithAccuracy([unmanaged.decimalObj sumOfProperty:@"self"].doubleValue, sum(@[decimal128(1), decimal128(2)]), .001);
    XCTAssertEqualWithAccuracy([optUnmanaged.intObj sumOfProperty:@"self"].doubleValue, sum(@[@2, @3, NSNull.null]), .001);
    XCTAssertEqualWithAccuracy([optUnmanaged.floatObj sumOfProperty:@"self"].doubleValue, sum(@[@2.2f, @3.3f, NSNull.null]), .001);
    XCTAssertEqualWithAccuracy([optUnmanaged.doubleObj sumOfProperty:@"self"].doubleValue, sum(@[@2.2, @3.3, NSNull.null]), .001);
    XCTAssertEqualWithAccuracy([optUnmanaged.decimalObj sumOfProperty:@"self"].doubleValue, sum(@[decimal128(1), decimal128(2), NSNull.null]), .001);
    XCTAssertEqualWithAccuracy([managed.intObj sumOfProperty:@"self"].doubleValue, sum(@[@2, @3]), .001);
    XCTAssertEqualWithAccuracy([managed.floatObj sumOfProperty:@"self"].doubleValue, sum(@[@2.2f, @3.3f]), .001);
    XCTAssertEqualWithAccuracy([managed.doubleObj sumOfProperty:@"self"].doubleValue, sum(@[@2.2, @3.3]), .001);
    XCTAssertEqualWithAccuracy([managed.decimalObj sumOfProperty:@"self"].doubleValue, sum(@[decimal128(1), decimal128(2)]), .001);
    XCTAssertEqualWithAccuracy([optManaged.intObj sumOfProperty:@"self"].doubleValue, sum(@[@2, @3, NSNull.null]), .001);
    XCTAssertEqualWithAccuracy([optManaged.floatObj sumOfProperty:@"self"].doubleValue, sum(@[@2.2f, @3.3f, NSNull.null]), .001);
    XCTAssertEqualWithAccuracy([optManaged.doubleObj sumOfProperty:@"self"].doubleValue, sum(@[@2.2, @3.3, NSNull.null]), .001);
    XCTAssertEqualWithAccuracy([optManaged.decimalObj sumOfProperty:@"self"].doubleValue, sum(@[decimal128(1), decimal128(2), NSNull.null]), .001);
}

- (void)testAverage {
    RLMAssertThrowsWithReason([unmanaged.boolObj averageOfProperty:@"self"], 
                              @"averageOfProperty: is not supported for bool set");
    RLMAssertThrowsWithReason([unmanaged.stringObj averageOfProperty:@"self"], 
                              @"averageOfProperty: is not supported for string set");
    RLMAssertThrowsWithReason([unmanaged.dataObj averageOfProperty:@"self"], 
                              @"averageOfProperty: is not supported for data set");
    RLMAssertThrowsWithReason([unmanaged.dateObj averageOfProperty:@"self"], 
                              @"averageOfProperty: is not supported for date set");
    RLMAssertThrowsWithReason([unmanaged.objectIdObj averageOfProperty:@"self"], 
                              @"averageOfProperty: is not supported for object id set");
    RLMAssertThrowsWithReason([optUnmanaged.boolObj averageOfProperty:@"self"], 
                              @"averageOfProperty: is not supported for bool? set");
    RLMAssertThrowsWithReason([optUnmanaged.stringObj averageOfProperty:@"self"], 
                              @"averageOfProperty: is not supported for string? set");
    RLMAssertThrowsWithReason([optUnmanaged.dataObj averageOfProperty:@"self"], 
                              @"averageOfProperty: is not supported for data? set");
    RLMAssertThrowsWithReason([optUnmanaged.dateObj averageOfProperty:@"self"], 
                              @"averageOfProperty: is not supported for date? set");
    RLMAssertThrowsWithReason([optUnmanaged.objectIdObj averageOfProperty:@"self"], 
                              @"averageOfProperty: is not supported for object id? set");
    RLMAssertThrowsWithReason([managed.boolObj averageOfProperty:@"self"], 
                              @"averageOfProperty: is not supported for bool set 'AllPrimitiveSets.boolObj'");
    RLMAssertThrowsWithReason([managed.stringObj averageOfProperty:@"self"], 
                              @"averageOfProperty: is not supported for string set 'AllPrimitiveSets.stringObj'");
    RLMAssertThrowsWithReason([managed.dataObj averageOfProperty:@"self"], 
                              @"averageOfProperty: is not supported for data set 'AllPrimitiveSets.dataObj'");
    RLMAssertThrowsWithReason([managed.dateObj averageOfProperty:@"self"], 
                              @"averageOfProperty: is not supported for date set 'AllPrimitiveSets.dateObj'");
    RLMAssertThrowsWithReason([managed.objectIdObj averageOfProperty:@"self"], 
                              @"averageOfProperty: is not supported for object id set 'AllPrimitiveSets.objectIdObj'");
    RLMAssertThrowsWithReason([optManaged.boolObj averageOfProperty:@"self"], 
                              @"averageOfProperty: is not supported for bool? set 'AllOptionalPrimitiveSets.boolObj'");
    RLMAssertThrowsWithReason([optManaged.stringObj averageOfProperty:@"self"], 
                              @"averageOfProperty: is not supported for string? set 'AllOptionalPrimitiveSets.stringObj'");
    RLMAssertThrowsWithReason([optManaged.dataObj averageOfProperty:@"self"], 
                              @"averageOfProperty: is not supported for data? set 'AllOptionalPrimitiveSets.dataObj'");
    RLMAssertThrowsWithReason([optManaged.dateObj averageOfProperty:@"self"], 
                              @"averageOfProperty: is not supported for date? set 'AllOptionalPrimitiveSets.dateObj'");
    RLMAssertThrowsWithReason([optManaged.objectIdObj averageOfProperty:@"self"], 
                              @"averageOfProperty: is not supported for object id? set 'AllOptionalPrimitiveSets.objectIdObj'");

    XCTAssertNil([unmanaged.intObj averageOfProperty:@"self"]);
    XCTAssertNil([unmanaged.floatObj averageOfProperty:@"self"]);
    XCTAssertNil([unmanaged.doubleObj averageOfProperty:@"self"]);
    XCTAssertNil([unmanaged.decimalObj averageOfProperty:@"self"]);
    XCTAssertNil([optUnmanaged.intObj averageOfProperty:@"self"]);
    XCTAssertNil([optUnmanaged.floatObj averageOfProperty:@"self"]);
    XCTAssertNil([optUnmanaged.doubleObj averageOfProperty:@"self"]);
    XCTAssertNil([optUnmanaged.decimalObj averageOfProperty:@"self"]);
    XCTAssertNil([managed.intObj averageOfProperty:@"self"]);
    XCTAssertNil([managed.floatObj averageOfProperty:@"self"]);
    XCTAssertNil([managed.doubleObj averageOfProperty:@"self"]);
    XCTAssertNil([managed.decimalObj averageOfProperty:@"self"]);
    XCTAssertNil([optManaged.intObj averageOfProperty:@"self"]);
    XCTAssertNil([optManaged.floatObj averageOfProperty:@"self"]);
    XCTAssertNil([optManaged.doubleObj averageOfProperty:@"self"]);
    XCTAssertNil([optManaged.decimalObj averageOfProperty:@"self"]);

    [self addObjects];

    XCTAssertEqualWithAccuracy([unmanaged.intObj averageOfProperty:@"self"].doubleValue, average(@[@2, @3]), .001);
    XCTAssertEqualWithAccuracy([unmanaged.floatObj averageOfProperty:@"self"].doubleValue, average(@[@2.2f, @3.3f]), .001);
    XCTAssertEqualWithAccuracy([unmanaged.doubleObj averageOfProperty:@"self"].doubleValue, average(@[@2.2, @3.3]), .001);
    XCTAssertEqualWithAccuracy([unmanaged.decimalObj averageOfProperty:@"self"].doubleValue, average(@[decimal128(1), decimal128(2)]), .001);
    XCTAssertEqualWithAccuracy([optUnmanaged.intObj averageOfProperty:@"self"].doubleValue, average(@[@2, @3, NSNull.null]), .001);
    XCTAssertEqualWithAccuracy([optUnmanaged.floatObj averageOfProperty:@"self"].doubleValue, average(@[@2.2f, @3.3f, NSNull.null]), .001);
    XCTAssertEqualWithAccuracy([optUnmanaged.doubleObj averageOfProperty:@"self"].doubleValue, average(@[@2.2, @3.3, NSNull.null]), .001);
    XCTAssertEqualWithAccuracy([optUnmanaged.decimalObj averageOfProperty:@"self"].doubleValue, average(@[decimal128(1), decimal128(2), NSNull.null]), .001);
    XCTAssertEqualWithAccuracy([managed.intObj averageOfProperty:@"self"].doubleValue, average(@[@2, @3]), .001);
    XCTAssertEqualWithAccuracy([managed.floatObj averageOfProperty:@"self"].doubleValue, average(@[@2.2f, @3.3f]), .001);
    XCTAssertEqualWithAccuracy([managed.doubleObj averageOfProperty:@"self"].doubleValue, average(@[@2.2, @3.3]), .001);
    XCTAssertEqualWithAccuracy([managed.decimalObj averageOfProperty:@"self"].doubleValue, average(@[decimal128(1), decimal128(2)]), .001);
    XCTAssertEqualWithAccuracy([optManaged.intObj averageOfProperty:@"self"].doubleValue, average(@[@2, @3, NSNull.null]), .001);
    XCTAssertEqualWithAccuracy([optManaged.floatObj averageOfProperty:@"self"].doubleValue, average(@[@2.2f, @3.3f, NSNull.null]), .001);
    XCTAssertEqualWithAccuracy([optManaged.doubleObj averageOfProperty:@"self"].doubleValue, average(@[@2.2, @3.3, NSNull.null]), .001);
    XCTAssertEqualWithAccuracy([optManaged.decimalObj averageOfProperty:@"self"].doubleValue, average(@[decimal128(1), decimal128(2), NSNull.null]), .001);
}

- (void)testFastEnumeration {
    for (int i = 0; i < 10; ++i) {
        [self addObjects];
    }

    { 
     NSUInteger i = 0; 
     NSArray *values = @[@NO, @YES]; 
     for (id value in unmanaged.boolObj) { 
     XCTAssertEqualObjects(values[i++ % values.count], value); 
     } 
     XCTAssertEqual(i, unmanaged.boolObj.count); 
     } 
    
    { 
     NSUInteger i = 0; 
     NSArray *values = @[@2, @3]; 
     for (id value in unmanaged.intObj) { 
     XCTAssertEqualObjects(values[i++ % values.count], value); 
     } 
     XCTAssertEqual(i, unmanaged.intObj.count); 
     } 
    
    { 
     NSUInteger i = 0; 
     NSArray *values = @[@2.2f, @3.3f]; 
     for (id value in unmanaged.floatObj) { 
     XCTAssertEqualObjects(values[i++ % values.count], value); 
     } 
     XCTAssertEqual(i, unmanaged.floatObj.count); 
     } 
    
    { 
     NSUInteger i = 0; 
     NSArray *values = @[@2.2, @3.3]; 
     for (id value in unmanaged.doubleObj) { 
     XCTAssertEqualObjects(values[i++ % values.count], value); 
     } 
     XCTAssertEqual(i, unmanaged.doubleObj.count); 
     } 
    
    { 
     NSUInteger i = 0; 
     NSArray *values = @[@"a", @"b"]; 
     for (id value in unmanaged.stringObj) { 
     XCTAssertEqualObjects(values[i++ % values.count], value); 
     } 
     XCTAssertEqual(i, unmanaged.stringObj.count); 
     } 
    
    { 
     NSUInteger i = 0; 
     NSArray *values = @[data(1), data(2)]; 
     for (id value in unmanaged.dataObj) { 
     XCTAssertEqualObjects(values[i++ % values.count], value); 
     } 
     XCTAssertEqual(i, unmanaged.dataObj.count); 
     } 
    
    { 
     NSUInteger i = 0; 
     NSArray *values = @[date(1), date(2)]; 
     for (id value in unmanaged.dateObj) { 
     XCTAssertEqualObjects(values[i++ % values.count], value); 
     } 
     XCTAssertEqual(i, unmanaged.dateObj.count); 
     } 
    
    { 
     NSUInteger i = 0; 
     NSArray *values = @[decimal128(1), decimal128(2)]; 
     for (id value in unmanaged.decimalObj) { 
     XCTAssertEqualObjects(values[i++ % values.count], value); 
     } 
     XCTAssertEqual(i, unmanaged.decimalObj.count); 
     } 
    
    { 
     NSUInteger i = 0; 
     NSArray *values = @[objectId(1), objectId(2)]; 
     for (id value in unmanaged.objectIdObj) { 
     XCTAssertEqualObjects(values[i++ % values.count], value); 
     } 
     XCTAssertEqual(i, unmanaged.objectIdObj.count); 
     } 
    
    { 
     NSUInteger i = 0; 
     NSArray *values = @[@NO, @YES, NSNull.null]; 
     for (id value in optUnmanaged.boolObj) { 
     XCTAssertEqualObjects(values[i++ % values.count], value); 
     } 
     XCTAssertEqual(i, optUnmanaged.boolObj.count); 
     } 
    
    { 
     NSUInteger i = 0; 
     NSArray *values = @[@2, @3, NSNull.null]; 
     for (id value in optUnmanaged.intObj) { 
     XCTAssertEqualObjects(values[i++ % values.count], value); 
     } 
     XCTAssertEqual(i, optUnmanaged.intObj.count); 
     } 
    
    { 
     NSUInteger i = 0; 
     NSArray *values = @[@2.2f, @3.3f, NSNull.null]; 
     for (id value in optUnmanaged.floatObj) { 
     XCTAssertEqualObjects(values[i++ % values.count], value); 
     } 
     XCTAssertEqual(i, optUnmanaged.floatObj.count); 
     } 
    
    { 
     NSUInteger i = 0; 
     NSArray *values = @[@2.2, @3.3, NSNull.null]; 
     for (id value in optUnmanaged.doubleObj) { 
     XCTAssertEqualObjects(values[i++ % values.count], value); 
     } 
     XCTAssertEqual(i, optUnmanaged.doubleObj.count); 
     } 
    
    { 
     NSUInteger i = 0; 
     NSArray *values = @[@"a", @"b", NSNull.null]; 
     for (id value in optUnmanaged.stringObj) { 
     XCTAssertEqualObjects(values[i++ % values.count], value); 
     } 
     XCTAssertEqual(i, optUnmanaged.stringObj.count); 
     } 
    
    { 
     NSUInteger i = 0; 
     NSArray *values = @[data(1), data(2), NSNull.null]; 
     for (id value in optUnmanaged.dataObj) { 
     XCTAssertEqualObjects(values[i++ % values.count], value); 
     } 
     XCTAssertEqual(i, optUnmanaged.dataObj.count); 
     } 
    
    { 
     NSUInteger i = 0; 
     NSArray *values = @[date(1), date(2), NSNull.null]; 
     for (id value in optUnmanaged.dateObj) { 
     XCTAssertEqualObjects(values[i++ % values.count], value); 
     } 
     XCTAssertEqual(i, optUnmanaged.dateObj.count); 
     } 
    
    { 
     NSUInteger i = 0; 
     NSArray *values = @[decimal128(1), decimal128(2), NSNull.null]; 
     for (id value in optUnmanaged.decimalObj) { 
     XCTAssertEqualObjects(values[i++ % values.count], value); 
     } 
     XCTAssertEqual(i, optUnmanaged.decimalObj.count); 
     } 
    
    { 
     NSUInteger i = 0; 
     NSArray *values = @[objectId(1), objectId(2), NSNull.null]; 
     for (id value in optUnmanaged.objectIdObj) { 
     XCTAssertEqualObjects(values[i++ % values.count], value); 
     } 
     XCTAssertEqual(i, optUnmanaged.objectIdObj.count); 
     } 
    
    { 
     NSUInteger i = 0; 
     NSArray *values = @[@NO, @YES]; 
     for (id value in managed.boolObj) { 
     XCTAssertEqualObjects(values[i++ % values.count], value); 
     } 
     XCTAssertEqual(i, managed.boolObj.count); 
     } 
    
    { 
     NSUInteger i = 0; 
     NSArray *values = @[@2, @3]; 
     for (id value in managed.intObj) { 
     XCTAssertEqualObjects(values[i++ % values.count], value); 
     } 
     XCTAssertEqual(i, managed.intObj.count); 
     } 
    
    { 
     NSUInteger i = 0; 
     NSArray *values = @[@2.2f, @3.3f]; 
     for (id value in managed.floatObj) { 
     XCTAssertEqualObjects(values[i++ % values.count], value); 
     } 
     XCTAssertEqual(i, managed.floatObj.count); 
     } 
    
    { 
     NSUInteger i = 0; 
     NSArray *values = @[@2.2, @3.3]; 
     for (id value in managed.doubleObj) { 
     XCTAssertEqualObjects(values[i++ % values.count], value); 
     } 
     XCTAssertEqual(i, managed.doubleObj.count); 
     } 
    
    { 
     NSUInteger i = 0; 
     NSArray *values = @[@"a", @"b"]; 
     for (id value in managed.stringObj) { 
     XCTAssertEqualObjects(values[i++ % values.count], value); 
     } 
     XCTAssertEqual(i, managed.stringObj.count); 
     } 
    
    { 
     NSUInteger i = 0; 
     NSArray *values = @[data(1), data(2)]; 
     for (id value in managed.dataObj) { 
     XCTAssertEqualObjects(values[i++ % values.count], value); 
     } 
     XCTAssertEqual(i, managed.dataObj.count); 
     } 
    
    { 
     NSUInteger i = 0; 
     NSArray *values = @[date(1), date(2)]; 
     for (id value in managed.dateObj) { 
     XCTAssertEqualObjects(values[i++ % values.count], value); 
     } 
     XCTAssertEqual(i, managed.dateObj.count); 
     } 
    
    { 
     NSUInteger i = 0; 
     NSArray *values = @[decimal128(1), decimal128(2)]; 
     for (id value in managed.decimalObj) { 
     XCTAssertEqualObjects(values[i++ % values.count], value); 
     } 
     XCTAssertEqual(i, managed.decimalObj.count); 
     } 
    
    { 
     NSUInteger i = 0; 
     NSArray *values = @[objectId(1), objectId(2)]; 
     for (id value in managed.objectIdObj) { 
     XCTAssertEqualObjects(values[i++ % values.count], value); 
     } 
     XCTAssertEqual(i, managed.objectIdObj.count); 
     } 
    
    { 
     NSUInteger i = 0; 
     NSArray *values = @[@NO, @YES, NSNull.null]; 
     for (id value in optManaged.boolObj) { 
     XCTAssertEqualObjects(values[i++ % values.count], value); 
     } 
     XCTAssertEqual(i, optManaged.boolObj.count); 
     } 
    
    { 
     NSUInteger i = 0; 
     NSArray *values = @[@2, @3, NSNull.null]; 
     for (id value in optManaged.intObj) { 
     XCTAssertEqualObjects(values[i++ % values.count], value); 
     } 
     XCTAssertEqual(i, optManaged.intObj.count); 
     } 
    
    { 
     NSUInteger i = 0; 
     NSArray *values = @[@2.2f, @3.3f, NSNull.null]; 
     for (id value in optManaged.floatObj) { 
     XCTAssertEqualObjects(values[i++ % values.count], value); 
     } 
     XCTAssertEqual(i, optManaged.floatObj.count); 
     } 
    
    { 
     NSUInteger i = 0; 
     NSArray *values = @[@2.2, @3.3, NSNull.null]; 
     for (id value in optManaged.doubleObj) { 
     XCTAssertEqualObjects(values[i++ % values.count], value); 
     } 
     XCTAssertEqual(i, optManaged.doubleObj.count); 
     } 
    
    { 
     NSUInteger i = 0; 
     NSArray *values = @[@"a", @"b", NSNull.null]; 
     for (id value in optManaged.stringObj) { 
     XCTAssertEqualObjects(values[i++ % values.count], value); 
     } 
     XCTAssertEqual(i, optManaged.stringObj.count); 
     } 
    
    { 
     NSUInteger i = 0; 
     NSArray *values = @[data(1), data(2), NSNull.null]; 
     for (id value in optManaged.dataObj) { 
     XCTAssertEqualObjects(values[i++ % values.count], value); 
     } 
     XCTAssertEqual(i, optManaged.dataObj.count); 
     } 
    
    { 
     NSUInteger i = 0; 
     NSArray *values = @[date(1), date(2), NSNull.null]; 
     for (id value in optManaged.dateObj) { 
     XCTAssertEqualObjects(values[i++ % values.count], value); 
     } 
     XCTAssertEqual(i, optManaged.dateObj.count); 
     } 
    
    { 
     NSUInteger i = 0; 
     NSArray *values = @[decimal128(1), decimal128(2), NSNull.null]; 
     for (id value in optManaged.decimalObj) { 
     XCTAssertEqualObjects(values[i++ % values.count], value); 
     } 
     XCTAssertEqual(i, optManaged.decimalObj.count); 
     } 
    
    { 
     NSUInteger i = 0; 
     NSArray *values = @[objectId(1), objectId(2), NSNull.null]; 
     for (id value in optManaged.objectIdObj) { 
     XCTAssertEqualObjects(values[i++ % values.count], value); 
     } 
     XCTAssertEqual(i, optManaged.objectIdObj.count); 
     } 
    
}

- (void)testValueForKeySelf {
    for (RLMSet *set in allSets) {
        XCTAssertEqualObjects([set valueForKey:@"self"], @[]);
    }

    [self addObjects];

    XCTAssertEqualObjects([unmanaged.boolObj valueForKey:@"self"], (@[@NO, @YES]));
    XCTAssertEqualObjects([unmanaged.intObj valueForKey:@"self"], (@[@2, @3]));
    XCTAssertEqualObjects([unmanaged.floatObj valueForKey:@"self"], (@[@2.2f, @3.3f]));
    XCTAssertEqualObjects([unmanaged.doubleObj valueForKey:@"self"], (@[@2.2, @3.3]));
    XCTAssertEqualObjects([unmanaged.stringObj valueForKey:@"self"], (@[@"a", @"b"]));
    XCTAssertEqualObjects([unmanaged.dataObj valueForKey:@"self"], (@[data(1), data(2)]));
    XCTAssertEqualObjects([unmanaged.dateObj valueForKey:@"self"], (@[date(1), date(2)]));
    XCTAssertEqualObjects([unmanaged.decimalObj valueForKey:@"self"], (@[decimal128(1), decimal128(2)]));
    XCTAssertEqualObjects([unmanaged.objectIdObj valueForKey:@"self"], (@[objectId(1), objectId(2)]));
    XCTAssertEqualObjects([optUnmanaged.boolObj valueForKey:@"self"], (@[@NO, @YES, NSNull.null]));
    XCTAssertEqualObjects([optUnmanaged.intObj valueForKey:@"self"], (@[@2, @3, NSNull.null]));
    XCTAssertEqualObjects([optUnmanaged.floatObj valueForKey:@"self"], (@[@2.2f, @3.3f, NSNull.null]));
    XCTAssertEqualObjects([optUnmanaged.doubleObj valueForKey:@"self"], (@[@2.2, @3.3, NSNull.null]));
    XCTAssertEqualObjects([optUnmanaged.stringObj valueForKey:@"self"], (@[@"a", @"b", NSNull.null]));
    XCTAssertEqualObjects([optUnmanaged.dataObj valueForKey:@"self"], (@[data(1), data(2), NSNull.null]));
    XCTAssertEqualObjects([optUnmanaged.dateObj valueForKey:@"self"], (@[date(1), date(2), NSNull.null]));
    XCTAssertEqualObjects([optUnmanaged.decimalObj valueForKey:@"self"], (@[decimal128(1), decimal128(2), NSNull.null]));
    XCTAssertEqualObjects([optUnmanaged.objectIdObj valueForKey:@"self"], (@[objectId(1), objectId(2), NSNull.null]));
    XCTAssertEqualObjects([managed.boolObj valueForKey:@"self"], (@[@NO, @YES]));
    XCTAssertEqualObjects([managed.intObj valueForKey:@"self"], (@[@2, @3]));
    XCTAssertEqualObjects([managed.floatObj valueForKey:@"self"], (@[@2.2f, @3.3f]));
    XCTAssertEqualObjects([managed.doubleObj valueForKey:@"self"], (@[@2.2, @3.3]));
    XCTAssertEqualObjects([managed.stringObj valueForKey:@"self"], (@[@"a", @"b"]));
    XCTAssertEqualObjects([managed.dataObj valueForKey:@"self"], (@[data(1), data(2)]));
    XCTAssertEqualObjects([managed.dateObj valueForKey:@"self"], (@[date(1), date(2)]));
    XCTAssertEqualObjects([managed.decimalObj valueForKey:@"self"], (@[decimal128(1), decimal128(2)]));
    XCTAssertEqualObjects([managed.objectIdObj valueForKey:@"self"], (@[objectId(1), objectId(2)]));
    XCTAssertEqualObjects([optManaged.boolObj valueForKey:@"self"], (@[@NO, @YES, NSNull.null]));
    XCTAssertEqualObjects([optManaged.intObj valueForKey:@"self"], (@[@2, @3, NSNull.null]));
    XCTAssertEqualObjects([optManaged.floatObj valueForKey:@"self"], (@[@2.2f, @3.3f, NSNull.null]));
    XCTAssertEqualObjects([optManaged.doubleObj valueForKey:@"self"], (@[@2.2, @3.3, NSNull.null]));
    XCTAssertEqualObjects([optManaged.stringObj valueForKey:@"self"], (@[@"a", @"b", NSNull.null]));
    XCTAssertEqualObjects([optManaged.dataObj valueForKey:@"self"], (@[data(1), data(2), NSNull.null]));
    XCTAssertEqualObjects([optManaged.dateObj valueForKey:@"self"], (@[date(1), date(2), NSNull.null]));
    XCTAssertEqualObjects([optManaged.decimalObj valueForKey:@"self"], (@[decimal128(1), decimal128(2), NSNull.null]));
    XCTAssertEqualObjects([optManaged.objectIdObj valueForKey:@"self"], (@[objectId(1), objectId(2), NSNull.null]));
}

- (void)testValueForKeyNumericAggregates {
    XCTAssertNil([unmanaged.intObj valueForKeyPath:@"@min.self"]);
    XCTAssertNil([unmanaged.floatObj valueForKeyPath:@"@min.self"]);
    XCTAssertNil([unmanaged.doubleObj valueForKeyPath:@"@min.self"]);
    XCTAssertNil([unmanaged.dateObj valueForKeyPath:@"@min.self"]);
    XCTAssertNil([unmanaged.decimalObj valueForKeyPath:@"@min.self"]);
    XCTAssertNil([optUnmanaged.intObj valueForKeyPath:@"@min.self"]);
    XCTAssertNil([optUnmanaged.floatObj valueForKeyPath:@"@min.self"]);
    XCTAssertNil([optUnmanaged.doubleObj valueForKeyPath:@"@min.self"]);
    XCTAssertNil([optUnmanaged.dateObj valueForKeyPath:@"@min.self"]);
    XCTAssertNil([optUnmanaged.decimalObj valueForKeyPath:@"@min.self"]);
    XCTAssertNil([managed.intObj valueForKeyPath:@"@min.self"]);
    XCTAssertNil([managed.floatObj valueForKeyPath:@"@min.self"]);
    XCTAssertNil([managed.doubleObj valueForKeyPath:@"@min.self"]);
    XCTAssertNil([managed.dateObj valueForKeyPath:@"@min.self"]);
    XCTAssertNil([managed.decimalObj valueForKeyPath:@"@min.self"]);
    XCTAssertNil([optManaged.intObj valueForKeyPath:@"@min.self"]);
    XCTAssertNil([optManaged.floatObj valueForKeyPath:@"@min.self"]);
    XCTAssertNil([optManaged.doubleObj valueForKeyPath:@"@min.self"]);
    XCTAssertNil([optManaged.dateObj valueForKeyPath:@"@min.self"]);
    XCTAssertNil([optManaged.decimalObj valueForKeyPath:@"@min.self"]);
    XCTAssertNil([unmanaged.intObj valueForKeyPath:@"@max.self"]);
    XCTAssertNil([unmanaged.floatObj valueForKeyPath:@"@max.self"]);
    XCTAssertNil([unmanaged.doubleObj valueForKeyPath:@"@max.self"]);
    XCTAssertNil([unmanaged.dateObj valueForKeyPath:@"@max.self"]);
    XCTAssertNil([unmanaged.decimalObj valueForKeyPath:@"@max.self"]);
    XCTAssertNil([optUnmanaged.intObj valueForKeyPath:@"@max.self"]);
    XCTAssertNil([optUnmanaged.floatObj valueForKeyPath:@"@max.self"]);
    XCTAssertNil([optUnmanaged.doubleObj valueForKeyPath:@"@max.self"]);
    XCTAssertNil([optUnmanaged.dateObj valueForKeyPath:@"@max.self"]);
    XCTAssertNil([optUnmanaged.decimalObj valueForKeyPath:@"@max.self"]);
    XCTAssertNil([managed.intObj valueForKeyPath:@"@max.self"]);
    XCTAssertNil([managed.floatObj valueForKeyPath:@"@max.self"]);
    XCTAssertNil([managed.doubleObj valueForKeyPath:@"@max.self"]);
    XCTAssertNil([managed.dateObj valueForKeyPath:@"@max.self"]);
    XCTAssertNil([managed.decimalObj valueForKeyPath:@"@max.self"]);
    XCTAssertNil([optManaged.intObj valueForKeyPath:@"@max.self"]);
    XCTAssertNil([optManaged.floatObj valueForKeyPath:@"@max.self"]);
    XCTAssertNil([optManaged.doubleObj valueForKeyPath:@"@max.self"]);
    XCTAssertNil([optManaged.dateObj valueForKeyPath:@"@max.self"]);
    XCTAssertNil([optManaged.decimalObj valueForKeyPath:@"@max.self"]);
    XCTAssertEqualObjects([unmanaged.intObj valueForKeyPath:@"@sum.self"], @0);
    XCTAssertEqualObjects([unmanaged.floatObj valueForKeyPath:@"@sum.self"], @0);
    XCTAssertEqualObjects([unmanaged.doubleObj valueForKeyPath:@"@sum.self"], @0);
    XCTAssertEqualObjects([unmanaged.decimalObj valueForKeyPath:@"@sum.self"], @0);
    XCTAssertEqualObjects([optUnmanaged.intObj valueForKeyPath:@"@sum.self"], @0);
    XCTAssertEqualObjects([optUnmanaged.floatObj valueForKeyPath:@"@sum.self"], @0);
    XCTAssertEqualObjects([optUnmanaged.doubleObj valueForKeyPath:@"@sum.self"], @0);
    XCTAssertEqualObjects([optUnmanaged.decimalObj valueForKeyPath:@"@sum.self"], @0);
    XCTAssertEqualObjects([managed.intObj valueForKeyPath:@"@sum.self"], @0);
    XCTAssertEqualObjects([managed.floatObj valueForKeyPath:@"@sum.self"], @0);
    XCTAssertEqualObjects([managed.doubleObj valueForKeyPath:@"@sum.self"], @0);
    XCTAssertEqualObjects([managed.decimalObj valueForKeyPath:@"@sum.self"], @0);
    XCTAssertEqualObjects([optManaged.intObj valueForKeyPath:@"@sum.self"], @0);
    XCTAssertEqualObjects([optManaged.floatObj valueForKeyPath:@"@sum.self"], @0);
    XCTAssertEqualObjects([optManaged.doubleObj valueForKeyPath:@"@sum.self"], @0);
    XCTAssertEqualObjects([optManaged.decimalObj valueForKeyPath:@"@sum.self"], @0);
    XCTAssertNil([unmanaged.intObj valueForKeyPath:@"@avg.self"]);
    XCTAssertNil([unmanaged.floatObj valueForKeyPath:@"@avg.self"]);
    XCTAssertNil([unmanaged.doubleObj valueForKeyPath:@"@avg.self"]);
    XCTAssertNil([unmanaged.decimalObj valueForKeyPath:@"@avg.self"]);
    XCTAssertNil([optUnmanaged.intObj valueForKeyPath:@"@avg.self"]);
    XCTAssertNil([optUnmanaged.floatObj valueForKeyPath:@"@avg.self"]);
    XCTAssertNil([optUnmanaged.doubleObj valueForKeyPath:@"@avg.self"]);
    XCTAssertNil([optUnmanaged.decimalObj valueForKeyPath:@"@avg.self"]);
    XCTAssertNil([managed.intObj valueForKeyPath:@"@avg.self"]);
    XCTAssertNil([managed.floatObj valueForKeyPath:@"@avg.self"]);
    XCTAssertNil([managed.doubleObj valueForKeyPath:@"@avg.self"]);
    XCTAssertNil([managed.decimalObj valueForKeyPath:@"@avg.self"]);
    XCTAssertNil([optManaged.intObj valueForKeyPath:@"@avg.self"]);
    XCTAssertNil([optManaged.floatObj valueForKeyPath:@"@avg.self"]);
    XCTAssertNil([optManaged.doubleObj valueForKeyPath:@"@avg.self"]);
    XCTAssertNil([optManaged.decimalObj valueForKeyPath:@"@avg.self"]);

    [self addObjects];

    XCTAssertEqualObjects([unmanaged.intObj valueForKeyPath:@"@min.self"], @2);
    XCTAssertEqualObjects([unmanaged.floatObj valueForKeyPath:@"@min.self"], @2.2f);
    XCTAssertEqualObjects([unmanaged.doubleObj valueForKeyPath:@"@min.self"], @2.2);
    XCTAssertEqualObjects([unmanaged.dateObj valueForKeyPath:@"@min.self"], date(1));
    XCTAssertEqualObjects([unmanaged.decimalObj valueForKeyPath:@"@min.self"], decimal128(1));
    XCTAssertEqualObjects([optUnmanaged.intObj valueForKeyPath:@"@min.self"], @2);
    XCTAssertEqualObjects([optUnmanaged.floatObj valueForKeyPath:@"@min.self"], @2.2f);
    XCTAssertEqualObjects([optUnmanaged.doubleObj valueForKeyPath:@"@min.self"], @2.2);
    XCTAssertEqualObjects([optUnmanaged.dateObj valueForKeyPath:@"@min.self"], date(1));
    XCTAssertEqualObjects([optUnmanaged.decimalObj valueForKeyPath:@"@min.self"], decimal128(1));
    XCTAssertEqualObjects([managed.intObj valueForKeyPath:@"@min.self"], @2);
    XCTAssertEqualObjects([managed.floatObj valueForKeyPath:@"@min.self"], @2.2f);
    XCTAssertEqualObjects([managed.doubleObj valueForKeyPath:@"@min.self"], @2.2);
    XCTAssertEqualObjects([managed.dateObj valueForKeyPath:@"@min.self"], date(1));
    XCTAssertEqualObjects([managed.decimalObj valueForKeyPath:@"@min.self"], decimal128(1));
    XCTAssertEqualObjects([optManaged.intObj valueForKeyPath:@"@min.self"], @2);
    XCTAssertEqualObjects([optManaged.floatObj valueForKeyPath:@"@min.self"], @2.2f);
    XCTAssertEqualObjects([optManaged.doubleObj valueForKeyPath:@"@min.self"], @2.2);
    XCTAssertEqualObjects([optManaged.dateObj valueForKeyPath:@"@min.self"], date(1));
    XCTAssertEqualObjects([optManaged.decimalObj valueForKeyPath:@"@min.self"], decimal128(1));
    XCTAssertEqualObjects([unmanaged.intObj valueForKeyPath:@"@max.self"], @3);
    XCTAssertEqualObjects([unmanaged.floatObj valueForKeyPath:@"@max.self"], @3.3f);
    XCTAssertEqualObjects([unmanaged.doubleObj valueForKeyPath:@"@max.self"], @3.3);
    XCTAssertEqualObjects([unmanaged.dateObj valueForKeyPath:@"@max.self"], date(2));
    XCTAssertEqualObjects([unmanaged.decimalObj valueForKeyPath:@"@max.self"], decimal128(2));
    XCTAssertEqualObjects([optUnmanaged.intObj valueForKeyPath:@"@max.self"], @3);
    XCTAssertEqualObjects([optUnmanaged.floatObj valueForKeyPath:@"@max.self"], @3.3f);
    XCTAssertEqualObjects([optUnmanaged.doubleObj valueForKeyPath:@"@max.self"], @3.3);
    XCTAssertEqualObjects([optUnmanaged.dateObj valueForKeyPath:@"@max.self"], date(2));
    XCTAssertEqualObjects([optUnmanaged.decimalObj valueForKeyPath:@"@max.self"], decimal128(2));
    XCTAssertEqualObjects([managed.intObj valueForKeyPath:@"@max.self"], @3);
    XCTAssertEqualObjects([managed.floatObj valueForKeyPath:@"@max.self"], @3.3f);
    XCTAssertEqualObjects([managed.doubleObj valueForKeyPath:@"@max.self"], @3.3);
    XCTAssertEqualObjects([managed.dateObj valueForKeyPath:@"@max.self"], date(2));
    XCTAssertEqualObjects([managed.decimalObj valueForKeyPath:@"@max.self"], decimal128(2));
    XCTAssertEqualObjects([optManaged.intObj valueForKeyPath:@"@max.self"], @3);
    XCTAssertEqualObjects([optManaged.floatObj valueForKeyPath:@"@max.self"], @3.3f);
    XCTAssertEqualObjects([optManaged.doubleObj valueForKeyPath:@"@max.self"], @3.3);
    XCTAssertEqualObjects([optManaged.dateObj valueForKeyPath:@"@max.self"], date(2));
    XCTAssertEqualObjects([optManaged.decimalObj valueForKeyPath:@"@max.self"], decimal128(2));
    XCTAssertEqualWithAccuracy([[unmanaged.intObj valueForKeyPath:@"@sum.self"] doubleValue], sum(@[@2, @3]), .001);
    XCTAssertEqualWithAccuracy([[unmanaged.floatObj valueForKeyPath:@"@sum.self"] doubleValue], sum(@[@2.2f, @3.3f]), .001);
    XCTAssertEqualWithAccuracy([[unmanaged.doubleObj valueForKeyPath:@"@sum.self"] doubleValue], sum(@[@2.2, @3.3]), .001);
    XCTAssertEqualWithAccuracy([[unmanaged.decimalObj valueForKeyPath:@"@sum.self"] doubleValue], sum(@[decimal128(1), decimal128(2)]), .001);
    XCTAssertEqualWithAccuracy([[optUnmanaged.intObj valueForKeyPath:@"@sum.self"] doubleValue], sum(@[@2, @3, NSNull.null]), .001);
    XCTAssertEqualWithAccuracy([[optUnmanaged.floatObj valueForKeyPath:@"@sum.self"] doubleValue], sum(@[@2.2f, @3.3f, NSNull.null]), .001);
    XCTAssertEqualWithAccuracy([[optUnmanaged.doubleObj valueForKeyPath:@"@sum.self"] doubleValue], sum(@[@2.2, @3.3, NSNull.null]), .001);
    XCTAssertEqualWithAccuracy([[optUnmanaged.decimalObj valueForKeyPath:@"@sum.self"] doubleValue], sum(@[decimal128(1), decimal128(2), NSNull.null]), .001);
    XCTAssertEqualWithAccuracy([[managed.intObj valueForKeyPath:@"@sum.self"] doubleValue], sum(@[@2, @3]), .001);
    XCTAssertEqualWithAccuracy([[managed.floatObj valueForKeyPath:@"@sum.self"] doubleValue], sum(@[@2.2f, @3.3f]), .001);
    XCTAssertEqualWithAccuracy([[managed.doubleObj valueForKeyPath:@"@sum.self"] doubleValue], sum(@[@2.2, @3.3]), .001);
    XCTAssertEqualWithAccuracy([[managed.decimalObj valueForKeyPath:@"@sum.self"] doubleValue], sum(@[decimal128(1), decimal128(2)]), .001);
    XCTAssertEqualWithAccuracy([[optManaged.intObj valueForKeyPath:@"@sum.self"] doubleValue], sum(@[@2, @3, NSNull.null]), .001);
    XCTAssertEqualWithAccuracy([[optManaged.floatObj valueForKeyPath:@"@sum.self"] doubleValue], sum(@[@2.2f, @3.3f, NSNull.null]), .001);
    XCTAssertEqualWithAccuracy([[optManaged.doubleObj valueForKeyPath:@"@sum.self"] doubleValue], sum(@[@2.2, @3.3, NSNull.null]), .001);
    XCTAssertEqualWithAccuracy([[optManaged.decimalObj valueForKeyPath:@"@sum.self"] doubleValue], sum(@[decimal128(1), decimal128(2), NSNull.null]), .001);
    XCTAssertEqualWithAccuracy([[unmanaged.intObj valueForKeyPath:@"@avg.self"] doubleValue], average(@[@2, @3]), .001);
    XCTAssertEqualWithAccuracy([[unmanaged.floatObj valueForKeyPath:@"@avg.self"] doubleValue], average(@[@2.2f, @3.3f]), .001);
    XCTAssertEqualWithAccuracy([[unmanaged.doubleObj valueForKeyPath:@"@avg.self"] doubleValue], average(@[@2.2, @3.3]), .001);
    XCTAssertEqualWithAccuracy([[unmanaged.decimalObj valueForKeyPath:@"@avg.self"] doubleValue], average(@[decimal128(1), decimal128(2)]), .001);
    XCTAssertEqualWithAccuracy([[optUnmanaged.intObj valueForKeyPath:@"@avg.self"] doubleValue], average(@[@2, @3, NSNull.null]), .001);
    XCTAssertEqualWithAccuracy([[optUnmanaged.floatObj valueForKeyPath:@"@avg.self"] doubleValue], average(@[@2.2f, @3.3f, NSNull.null]), .001);
    XCTAssertEqualWithAccuracy([[optUnmanaged.doubleObj valueForKeyPath:@"@avg.self"] doubleValue], average(@[@2.2, @3.3, NSNull.null]), .001);
    XCTAssertEqualWithAccuracy([[optUnmanaged.decimalObj valueForKeyPath:@"@avg.self"] doubleValue], average(@[decimal128(1), decimal128(2), NSNull.null]), .001);
    XCTAssertEqualWithAccuracy([[managed.intObj valueForKeyPath:@"@avg.self"] doubleValue], average(@[@2, @3]), .001);
    XCTAssertEqualWithAccuracy([[managed.floatObj valueForKeyPath:@"@avg.self"] doubleValue], average(@[@2.2f, @3.3f]), .001);
    XCTAssertEqualWithAccuracy([[managed.doubleObj valueForKeyPath:@"@avg.self"] doubleValue], average(@[@2.2, @3.3]), .001);
    XCTAssertEqualWithAccuracy([[managed.decimalObj valueForKeyPath:@"@avg.self"] doubleValue], average(@[decimal128(1), decimal128(2)]), .001);
    XCTAssertEqualWithAccuracy([[optManaged.intObj valueForKeyPath:@"@avg.self"] doubleValue], average(@[@2, @3, NSNull.null]), .001);
    XCTAssertEqualWithAccuracy([[optManaged.floatObj valueForKeyPath:@"@avg.self"] doubleValue], average(@[@2.2f, @3.3f, NSNull.null]), .001);
    XCTAssertEqualWithAccuracy([[optManaged.doubleObj valueForKeyPath:@"@avg.self"] doubleValue], average(@[@2.2, @3.3, NSNull.null]), .001);
    XCTAssertEqualWithAccuracy([[optManaged.decimalObj valueForKeyPath:@"@avg.self"] doubleValue], average(@[decimal128(1), decimal128(2), NSNull.null]), .001);
}

- (void)testValueForKeyLength {
    for (RLMSet *set in allSets) {
        XCTAssertEqualObjects([set valueForKey:@"length"], @[]);
    }

    [self addObjects];

    XCTAssertEqualObjects([unmanaged.stringObj valueForKey:@"length"], ([@[@"a", @"b"] valueForKey:@"length"]));
    XCTAssertEqualObjects([optUnmanaged.stringObj valueForKey:@"length"], ([@[@"a", @"b", NSNull.null] valueForKey:@"length"]));
    XCTAssertEqualObjects([managed.stringObj valueForKey:@"length"], ([@[@"a", @"b"] valueForKey:@"length"]));
    XCTAssertEqualObjects([optManaged.stringObj valueForKey:@"length"], ([@[@"a", @"b", NSNull.null] valueForKey:@"length"]));
}

- (void)testUnionOfObjects {

}

- (void)testUnionOfSets {

}

- (void)testSetValueForKey {
    for (RLMSet *set in allSets) {
        RLMAssertThrowsWithReason([set setValue:@0 forKey:@"not self"],
                                  @"this class is not key value coding-compliant for the key not self.");
    }
    RLMAssertThrowsWithReason([unmanaged.boolObj setValue:@"a" forKey:@"self"], 
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'bool'");
    RLMAssertThrowsWithReason([unmanaged.intObj setValue:@"a" forKey:@"self"], 
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'int'");
    RLMAssertThrowsWithReason([unmanaged.floatObj setValue:@"a" forKey:@"self"], 
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'float'");
    RLMAssertThrowsWithReason([unmanaged.doubleObj setValue:@"a" forKey:@"self"], 
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'double'");
    RLMAssertThrowsWithReason([unmanaged.stringObj setValue:@2 forKey:@"self"], 
                              @"Invalid value '2' of type '__NSCFNumber' for expected type 'string'");
    RLMAssertThrowsWithReason([unmanaged.dataObj setValue:@"a" forKey:@"self"], 
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'data'");
    RLMAssertThrowsWithReason([unmanaged.dateObj setValue:@"a" forKey:@"self"], 
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'date'");
    RLMAssertThrowsWithReason([unmanaged.decimalObj setValue:@"a" forKey:@"self"], 
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'decimal128'");
    RLMAssertThrowsWithReason([unmanaged.objectIdObj setValue:@"a" forKey:@"self"], 
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'object id'");
    RLMAssertThrowsWithReason([optUnmanaged.boolObj setValue:@"a" forKey:@"self"], 
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'bool?'");
    RLMAssertThrowsWithReason([optUnmanaged.intObj setValue:@"a" forKey:@"self"], 
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'int?'");
    RLMAssertThrowsWithReason([optUnmanaged.floatObj setValue:@"a" forKey:@"self"], 
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'float?'");
    RLMAssertThrowsWithReason([optUnmanaged.doubleObj setValue:@"a" forKey:@"self"], 
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'double?'");
    RLMAssertThrowsWithReason([optUnmanaged.stringObj setValue:@2 forKey:@"self"], 
                              @"Invalid value '2' of type '__NSCFNumber' for expected type 'string?'");
    RLMAssertThrowsWithReason([optUnmanaged.dataObj setValue:@"a" forKey:@"self"], 
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'data?'");
    RLMAssertThrowsWithReason([optUnmanaged.dateObj setValue:@"a" forKey:@"self"], 
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'date?'");
    RLMAssertThrowsWithReason([optUnmanaged.decimalObj setValue:@"a" forKey:@"self"], 
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'decimal128?'");
    RLMAssertThrowsWithReason([optUnmanaged.objectIdObj setValue:@"a" forKey:@"self"], 
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'object id?'");
    RLMAssertThrowsWithReason([managed.boolObj setValue:@"a" forKey:@"self"], 
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'bool'");
    RLMAssertThrowsWithReason([managed.intObj setValue:@"a" forKey:@"self"], 
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'int'");
    RLMAssertThrowsWithReason([managed.floatObj setValue:@"a" forKey:@"self"], 
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'float'");
    RLMAssertThrowsWithReason([managed.doubleObj setValue:@"a" forKey:@"self"], 
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'double'");
    RLMAssertThrowsWithReason([managed.stringObj setValue:@2 forKey:@"self"], 
                              @"Invalid value '2' of type '__NSCFNumber' for expected type 'string'");
    RLMAssertThrowsWithReason([managed.dataObj setValue:@"a" forKey:@"self"], 
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'data'");
    RLMAssertThrowsWithReason([managed.dateObj setValue:@"a" forKey:@"self"], 
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'date'");
    RLMAssertThrowsWithReason([managed.decimalObj setValue:@"a" forKey:@"self"], 
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'decimal128'");
    RLMAssertThrowsWithReason([managed.objectIdObj setValue:@"a" forKey:@"self"], 
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'object id'");
    RLMAssertThrowsWithReason([optManaged.boolObj setValue:@"a" forKey:@"self"], 
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'bool?'");
    RLMAssertThrowsWithReason([optManaged.intObj setValue:@"a" forKey:@"self"], 
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'int?'");
    RLMAssertThrowsWithReason([optManaged.floatObj setValue:@"a" forKey:@"self"], 
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'float?'");
    RLMAssertThrowsWithReason([optManaged.doubleObj setValue:@"a" forKey:@"self"], 
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'double?'");
    RLMAssertThrowsWithReason([optManaged.stringObj setValue:@2 forKey:@"self"], 
                              @"Invalid value '2' of type '__NSCFNumber' for expected type 'string?'");
    RLMAssertThrowsWithReason([optManaged.dataObj setValue:@"a" forKey:@"self"], 
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'data?'");
    RLMAssertThrowsWithReason([optManaged.dateObj setValue:@"a" forKey:@"self"], 
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'date?'");
    RLMAssertThrowsWithReason([optManaged.decimalObj setValue:@"a" forKey:@"self"], 
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'decimal128?'");
    RLMAssertThrowsWithReason([optManaged.objectIdObj setValue:@"a" forKey:@"self"], 
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'object id?'");
    RLMAssertThrowsWithReason([unmanaged.boolObj setValue:NSNull.null forKey:@"self"], 
                              @"Invalid value '<null>' of type 'NSNull' for expected type 'bool'");
    RLMAssertThrowsWithReason([unmanaged.intObj setValue:NSNull.null forKey:@"self"], 
                              @"Invalid value '<null>' of type 'NSNull' for expected type 'int'");
    RLMAssertThrowsWithReason([unmanaged.floatObj setValue:NSNull.null forKey:@"self"], 
                              @"Invalid value '<null>' of type 'NSNull' for expected type 'float'");
    RLMAssertThrowsWithReason([unmanaged.doubleObj setValue:NSNull.null forKey:@"self"], 
                              @"Invalid value '<null>' of type 'NSNull' for expected type 'double'");
    RLMAssertThrowsWithReason([unmanaged.stringObj setValue:NSNull.null forKey:@"self"], 
                              @"Invalid value '<null>' of type 'NSNull' for expected type 'string'");
    RLMAssertThrowsWithReason([unmanaged.dataObj setValue:NSNull.null forKey:@"self"], 
                              @"Invalid value '<null>' of type 'NSNull' for expected type 'data'");
    RLMAssertThrowsWithReason([unmanaged.dateObj setValue:NSNull.null forKey:@"self"], 
                              @"Invalid value '<null>' of type 'NSNull' for expected type 'date'");
    RLMAssertThrowsWithReason([unmanaged.decimalObj setValue:NSNull.null forKey:@"self"], 
                              @"Invalid value '<null>' of type 'NSNull' for expected type 'decimal128'");
    RLMAssertThrowsWithReason([unmanaged.objectIdObj setValue:NSNull.null forKey:@"self"], 
                              @"Invalid value '<null>' of type 'NSNull' for expected type 'object id'");
    RLMAssertThrowsWithReason([managed.boolObj setValue:NSNull.null forKey:@"self"], 
                              @"Invalid value '<null>' of type 'NSNull' for expected type 'bool'");
    RLMAssertThrowsWithReason([managed.intObj setValue:NSNull.null forKey:@"self"], 
                              @"Invalid value '<null>' of type 'NSNull' for expected type 'int'");
    RLMAssertThrowsWithReason([managed.floatObj setValue:NSNull.null forKey:@"self"], 
                              @"Invalid value '<null>' of type 'NSNull' for expected type 'float'");
    RLMAssertThrowsWithReason([managed.doubleObj setValue:NSNull.null forKey:@"self"], 
                              @"Invalid value '<null>' of type 'NSNull' for expected type 'double'");
    RLMAssertThrowsWithReason([managed.stringObj setValue:NSNull.null forKey:@"self"], 
                              @"Invalid value '<null>' of type 'NSNull' for expected type 'string'");
    RLMAssertThrowsWithReason([managed.dataObj setValue:NSNull.null forKey:@"self"], 
                              @"Invalid value '<null>' of type 'NSNull' for expected type 'data'");
    RLMAssertThrowsWithReason([managed.dateObj setValue:NSNull.null forKey:@"self"], 
                              @"Invalid value '<null>' of type 'NSNull' for expected type 'date'");
    RLMAssertThrowsWithReason([managed.decimalObj setValue:NSNull.null forKey:@"self"], 
                              @"Invalid value '<null>' of type 'NSNull' for expected type 'decimal128'");
    RLMAssertThrowsWithReason([managed.objectIdObj setValue:NSNull.null forKey:@"self"], 
                              @"Invalid value '<null>' of type 'NSNull' for expected type 'object id'");

    [self addObjects];

    [unmanaged.boolObj setValue:@NO forKey:@"self"];
    [unmanaged.intObj setValue:@2 forKey:@"self"];
    [unmanaged.floatObj setValue:@2.2f forKey:@"self"];
    [unmanaged.doubleObj setValue:@2.2 forKey:@"self"];
    [unmanaged.stringObj setValue:@"a" forKey:@"self"];
    [unmanaged.dataObj setValue:data(1) forKey:@"self"];
    [unmanaged.dateObj setValue:date(1) forKey:@"self"];
    [unmanaged.decimalObj setValue:decimal128(1) forKey:@"self"];
    [unmanaged.objectIdObj setValue:objectId(1) forKey:@"self"];
    [optUnmanaged.boolObj setValue:@NO forKey:@"self"];
    [optUnmanaged.intObj setValue:@2 forKey:@"self"];
    [optUnmanaged.floatObj setValue:@2.2f forKey:@"self"];
    [optUnmanaged.doubleObj setValue:@2.2 forKey:@"self"];
    [optUnmanaged.stringObj setValue:@"a" forKey:@"self"];
    [optUnmanaged.dataObj setValue:data(1) forKey:@"self"];
    [optUnmanaged.dateObj setValue:date(1) forKey:@"self"];
    [optUnmanaged.decimalObj setValue:decimal128(1) forKey:@"self"];
    [optUnmanaged.objectIdObj setValue:objectId(1) forKey:@"self"];
    [managed.boolObj setValue:@NO forKey:@"self"];
    [managed.intObj setValue:@2 forKey:@"self"];
    [managed.floatObj setValue:@2.2f forKey:@"self"];
    [managed.doubleObj setValue:@2.2 forKey:@"self"];
    [managed.stringObj setValue:@"a" forKey:@"self"];
    [managed.dataObj setValue:data(1) forKey:@"self"];
    [managed.dateObj setValue:date(1) forKey:@"self"];
    [managed.decimalObj setValue:decimal128(1) forKey:@"self"];
    [managed.objectIdObj setValue:objectId(1) forKey:@"self"];
    [optManaged.boolObj setValue:@NO forKey:@"self"];
    [optManaged.intObj setValue:@2 forKey:@"self"];
    [optManaged.floatObj setValue:@2.2f forKey:@"self"];
    [optManaged.doubleObj setValue:@2.2 forKey:@"self"];
    [optManaged.stringObj setValue:@"a" forKey:@"self"];
    [optManaged.dataObj setValue:data(1) forKey:@"self"];
    [optManaged.dateObj setValue:date(1) forKey:@"self"];
    [optManaged.decimalObj setValue:decimal128(1) forKey:@"self"];
    [optManaged.objectIdObj setValue:objectId(1) forKey:@"self"];

    XCTAssertEqualObjects(unmanaged.boolObj[0], @NO);
    XCTAssertEqualObjects(unmanaged.intObj[0], @2);
    XCTAssertEqualObjects(unmanaged.floatObj[0], @2.2f);
    XCTAssertEqualObjects(unmanaged.doubleObj[0], @2.2);
    XCTAssertEqualObjects(unmanaged.stringObj[0], @"a");
    XCTAssertEqualObjects(unmanaged.dataObj[0], data(1));
    XCTAssertEqualObjects(unmanaged.dateObj[0], date(1));
    XCTAssertEqualObjects(unmanaged.decimalObj[0], decimal128(1));
    XCTAssertEqualObjects(unmanaged.objectIdObj[0], objectId(1));
    XCTAssertEqualObjects(optUnmanaged.boolObj[0], @NO);
    XCTAssertEqualObjects(optUnmanaged.intObj[0], @2);
    XCTAssertEqualObjects(optUnmanaged.floatObj[0], @2.2f);
    XCTAssertEqualObjects(optUnmanaged.doubleObj[0], @2.2);
    XCTAssertEqualObjects(optUnmanaged.stringObj[0], @"a");
    XCTAssertEqualObjects(optUnmanaged.dataObj[0], data(1));
    XCTAssertEqualObjects(optUnmanaged.dateObj[0], date(1));
    XCTAssertEqualObjects(optUnmanaged.decimalObj[0], decimal128(1));
    XCTAssertEqualObjects(optUnmanaged.objectIdObj[0], objectId(1));
    XCTAssertEqualObjects(managed.boolObj[0], @NO);
    XCTAssertEqualObjects(managed.intObj[0], @2);
    XCTAssertEqualObjects(managed.floatObj[0], @2.2f);
    XCTAssertEqualObjects(managed.doubleObj[0], @2.2);
    XCTAssertEqualObjects(managed.stringObj[0], @"a");
    XCTAssertEqualObjects(managed.dataObj[0], data(1));
    XCTAssertEqualObjects(managed.dateObj[0], date(1));
    XCTAssertEqualObjects(managed.decimalObj[0], decimal128(1));
    XCTAssertEqualObjects(managed.objectIdObj[0], objectId(1));
    XCTAssertEqualObjects(optManaged.boolObj[0], @NO);
    XCTAssertEqualObjects(optManaged.intObj[0], @2);
    XCTAssertEqualObjects(optManaged.floatObj[0], @2.2f);
    XCTAssertEqualObjects(optManaged.doubleObj[0], @2.2);
    XCTAssertEqualObjects(optManaged.stringObj[0], @"a");
    XCTAssertEqualObjects(optManaged.dataObj[0], data(1));
    XCTAssertEqualObjects(optManaged.dateObj[0], date(1));
    XCTAssertEqualObjects(optManaged.decimalObj[0], decimal128(1));
    XCTAssertEqualObjects(optManaged.objectIdObj[0], objectId(1));
    XCTAssertEqualObjects(unmanaged.boolObj[1], @NO);
    XCTAssertEqualObjects(unmanaged.intObj[1], @2);
    XCTAssertEqualObjects(unmanaged.floatObj[1], @2.2f);
    XCTAssertEqualObjects(unmanaged.doubleObj[1], @2.2);
    XCTAssertEqualObjects(unmanaged.stringObj[1], @"a");
    XCTAssertEqualObjects(unmanaged.dataObj[1], data(1));
    XCTAssertEqualObjects(unmanaged.dateObj[1], date(1));
    XCTAssertEqualObjects(unmanaged.decimalObj[1], decimal128(1));
    XCTAssertEqualObjects(unmanaged.objectIdObj[1], objectId(1));
    XCTAssertEqualObjects(optUnmanaged.boolObj[1], @NO);
    XCTAssertEqualObjects(optUnmanaged.intObj[1], @2);
    XCTAssertEqualObjects(optUnmanaged.floatObj[1], @2.2f);
    XCTAssertEqualObjects(optUnmanaged.doubleObj[1], @2.2);
    XCTAssertEqualObjects(optUnmanaged.stringObj[1], @"a");
    XCTAssertEqualObjects(optUnmanaged.dataObj[1], data(1));
    XCTAssertEqualObjects(optUnmanaged.dateObj[1], date(1));
    XCTAssertEqualObjects(optUnmanaged.decimalObj[1], decimal128(1));
    XCTAssertEqualObjects(optUnmanaged.objectIdObj[1], objectId(1));
    XCTAssertEqualObjects(managed.boolObj[1], @NO);
    XCTAssertEqualObjects(managed.intObj[1], @2);
    XCTAssertEqualObjects(managed.floatObj[1], @2.2f);
    XCTAssertEqualObjects(managed.doubleObj[1], @2.2);
    XCTAssertEqualObjects(managed.stringObj[1], @"a");
    XCTAssertEqualObjects(managed.dataObj[1], data(1));
    XCTAssertEqualObjects(managed.dateObj[1], date(1));
    XCTAssertEqualObjects(managed.decimalObj[1], decimal128(1));
    XCTAssertEqualObjects(managed.objectIdObj[1], objectId(1));
    XCTAssertEqualObjects(optManaged.boolObj[1], @NO);
    XCTAssertEqualObjects(optManaged.intObj[1], @2);
    XCTAssertEqualObjects(optManaged.floatObj[1], @2.2f);
    XCTAssertEqualObjects(optManaged.doubleObj[1], @2.2);
    XCTAssertEqualObjects(optManaged.stringObj[1], @"a");
    XCTAssertEqualObjects(optManaged.dataObj[1], data(1));
    XCTAssertEqualObjects(optManaged.dateObj[1], date(1));
    XCTAssertEqualObjects(optManaged.decimalObj[1], decimal128(1));
    XCTAssertEqualObjects(optManaged.objectIdObj[1], objectId(1));
    XCTAssertEqualObjects(optUnmanaged.boolObj[2], @NO);
    XCTAssertEqualObjects(optUnmanaged.intObj[2], @2);
    XCTAssertEqualObjects(optUnmanaged.floatObj[2], @2.2f);
    XCTAssertEqualObjects(optUnmanaged.doubleObj[2], @2.2);
    XCTAssertEqualObjects(optUnmanaged.stringObj[2], @"a");
    XCTAssertEqualObjects(optUnmanaged.dataObj[2], data(1));
    XCTAssertEqualObjects(optUnmanaged.dateObj[2], date(1));
    XCTAssertEqualObjects(optUnmanaged.decimalObj[2], decimal128(1));
    XCTAssertEqualObjects(optUnmanaged.objectIdObj[2], objectId(1));
    XCTAssertEqualObjects(optManaged.boolObj[2], @NO);
    XCTAssertEqualObjects(optManaged.intObj[2], @2);
    XCTAssertEqualObjects(optManaged.floatObj[2], @2.2f);
    XCTAssertEqualObjects(optManaged.doubleObj[2], @2.2);
    XCTAssertEqualObjects(optManaged.stringObj[2], @"a");
    XCTAssertEqualObjects(optManaged.dataObj[2], data(1));
    XCTAssertEqualObjects(optManaged.dateObj[2], date(1));
    XCTAssertEqualObjects(optManaged.decimalObj[2], decimal128(1));
    XCTAssertEqualObjects(optManaged.objectIdObj[2], objectId(1));

    [optUnmanaged.boolObj setValue:NSNull.null forKey:@"self"];
    [optUnmanaged.intObj setValue:NSNull.null forKey:@"self"];
    [optUnmanaged.floatObj setValue:NSNull.null forKey:@"self"];
    [optUnmanaged.doubleObj setValue:NSNull.null forKey:@"self"];
    [optUnmanaged.stringObj setValue:NSNull.null forKey:@"self"];
    [optUnmanaged.dataObj setValue:NSNull.null forKey:@"self"];
    [optUnmanaged.dateObj setValue:NSNull.null forKey:@"self"];
    [optUnmanaged.decimalObj setValue:NSNull.null forKey:@"self"];
    [optUnmanaged.objectIdObj setValue:NSNull.null forKey:@"self"];
    [optManaged.boolObj setValue:NSNull.null forKey:@"self"];
    [optManaged.intObj setValue:NSNull.null forKey:@"self"];
    [optManaged.floatObj setValue:NSNull.null forKey:@"self"];
    [optManaged.doubleObj setValue:NSNull.null forKey:@"self"];
    [optManaged.stringObj setValue:NSNull.null forKey:@"self"];
    [optManaged.dataObj setValue:NSNull.null forKey:@"self"];
    [optManaged.dateObj setValue:NSNull.null forKey:@"self"];
    [optManaged.decimalObj setValue:NSNull.null forKey:@"self"];
    [optManaged.objectIdObj setValue:NSNull.null forKey:@"self"];
    XCTAssertEqualObjects(optUnmanaged.boolObj[0], NSNull.null);
    XCTAssertEqualObjects(optUnmanaged.intObj[0], NSNull.null);
    XCTAssertEqualObjects(optUnmanaged.floatObj[0], NSNull.null);
    XCTAssertEqualObjects(optUnmanaged.doubleObj[0], NSNull.null);
    XCTAssertEqualObjects(optUnmanaged.stringObj[0], NSNull.null);
    XCTAssertEqualObjects(optUnmanaged.dataObj[0], NSNull.null);
    XCTAssertEqualObjects(optUnmanaged.dateObj[0], NSNull.null);
    XCTAssertEqualObjects(optUnmanaged.decimalObj[0], NSNull.null);
    XCTAssertEqualObjects(optUnmanaged.objectIdObj[0], NSNull.null);
    XCTAssertEqualObjects(optManaged.boolObj[0], NSNull.null);
    XCTAssertEqualObjects(optManaged.intObj[0], NSNull.null);
    XCTAssertEqualObjects(optManaged.floatObj[0], NSNull.null);
    XCTAssertEqualObjects(optManaged.doubleObj[0], NSNull.null);
    XCTAssertEqualObjects(optManaged.stringObj[0], NSNull.null);
    XCTAssertEqualObjects(optManaged.dataObj[0], NSNull.null);
    XCTAssertEqualObjects(optManaged.dateObj[0], NSNull.null);
    XCTAssertEqualObjects(optManaged.decimalObj[0], NSNull.null);
    XCTAssertEqualObjects(optManaged.objectIdObj[0], NSNull.null);
}

- (void)testAssignment {
    unmanaged.boolObj = (id)@[@YES]; 
     XCTAssertEqualObjects(unmanaged.boolObj[0], @YES);
    unmanaged.intObj = (id)@[@3]; 
     XCTAssertEqualObjects(unmanaged.intObj[0], @3);
    unmanaged.floatObj = (id)@[@3.3f]; 
     XCTAssertEqualObjects(unmanaged.floatObj[0], @3.3f);
    unmanaged.doubleObj = (id)@[@3.3]; 
     XCTAssertEqualObjects(unmanaged.doubleObj[0], @3.3);
    unmanaged.stringObj = (id)@[@"b"]; 
     XCTAssertEqualObjects(unmanaged.stringObj[0], @"b");
    unmanaged.dataObj = (id)@[data(2)]; 
     XCTAssertEqualObjects(unmanaged.dataObj[0], data(2));
    unmanaged.dateObj = (id)@[date(2)]; 
     XCTAssertEqualObjects(unmanaged.dateObj[0], date(2));
    unmanaged.decimalObj = (id)@[decimal128(2)]; 
     XCTAssertEqualObjects(unmanaged.decimalObj[0], decimal128(2));
    unmanaged.objectIdObj = (id)@[objectId(2)]; 
     XCTAssertEqualObjects(unmanaged.objectIdObj[0], objectId(2));
    optUnmanaged.boolObj = (id)@[@YES]; 
     XCTAssertEqualObjects(optUnmanaged.boolObj[0], @YES);
    optUnmanaged.intObj = (id)@[@3]; 
     XCTAssertEqualObjects(optUnmanaged.intObj[0], @3);
    optUnmanaged.floatObj = (id)@[@3.3f]; 
     XCTAssertEqualObjects(optUnmanaged.floatObj[0], @3.3f);
    optUnmanaged.doubleObj = (id)@[@3.3]; 
     XCTAssertEqualObjects(optUnmanaged.doubleObj[0], @3.3);
    optUnmanaged.stringObj = (id)@[@"b"]; 
     XCTAssertEqualObjects(optUnmanaged.stringObj[0], @"b");
    optUnmanaged.dataObj = (id)@[data(2)]; 
     XCTAssertEqualObjects(optUnmanaged.dataObj[0], data(2));
    optUnmanaged.dateObj = (id)@[date(2)]; 
     XCTAssertEqualObjects(optUnmanaged.dateObj[0], date(2));
    optUnmanaged.decimalObj = (id)@[decimal128(2)]; 
     XCTAssertEqualObjects(optUnmanaged.decimalObj[0], decimal128(2));
    optUnmanaged.objectIdObj = (id)@[objectId(2)]; 
     XCTAssertEqualObjects(optUnmanaged.objectIdObj[0], objectId(2));
    managed.boolObj = (id)@[@YES]; 
     XCTAssertEqualObjects(managed.boolObj[0], @YES);
    managed.intObj = (id)@[@3]; 
     XCTAssertEqualObjects(managed.intObj[0], @3);
    managed.floatObj = (id)@[@3.3f]; 
     XCTAssertEqualObjects(managed.floatObj[0], @3.3f);
    managed.doubleObj = (id)@[@3.3]; 
     XCTAssertEqualObjects(managed.doubleObj[0], @3.3);
    managed.stringObj = (id)@[@"b"]; 
     XCTAssertEqualObjects(managed.stringObj[0], @"b");
    managed.dataObj = (id)@[data(2)]; 
     XCTAssertEqualObjects(managed.dataObj[0], data(2));
    managed.dateObj = (id)@[date(2)]; 
     XCTAssertEqualObjects(managed.dateObj[0], date(2));
    managed.decimalObj = (id)@[decimal128(2)]; 
     XCTAssertEqualObjects(managed.decimalObj[0], decimal128(2));
    managed.objectIdObj = (id)@[objectId(2)]; 
     XCTAssertEqualObjects(managed.objectIdObj[0], objectId(2));
    optManaged.boolObj = (id)@[@YES]; 
     XCTAssertEqualObjects(optManaged.boolObj[0], @YES);
    optManaged.intObj = (id)@[@3]; 
     XCTAssertEqualObjects(optManaged.intObj[0], @3);
    optManaged.floatObj = (id)@[@3.3f]; 
     XCTAssertEqualObjects(optManaged.floatObj[0], @3.3f);
    optManaged.doubleObj = (id)@[@3.3]; 
     XCTAssertEqualObjects(optManaged.doubleObj[0], @3.3);
    optManaged.stringObj = (id)@[@"b"]; 
     XCTAssertEqualObjects(optManaged.stringObj[0], @"b");
    optManaged.dataObj = (id)@[data(2)]; 
     XCTAssertEqualObjects(optManaged.dataObj[0], data(2));
    optManaged.dateObj = (id)@[date(2)]; 
     XCTAssertEqualObjects(optManaged.dateObj[0], date(2));
    optManaged.decimalObj = (id)@[decimal128(2)]; 
     XCTAssertEqualObjects(optManaged.decimalObj[0], decimal128(2));
    optManaged.objectIdObj = (id)@[objectId(2)]; 
     XCTAssertEqualObjects(optManaged.objectIdObj[0], objectId(2));

    // Should replace and not append
    unmanaged.boolObj = (id)@[@NO, @YES]; 
     XCTAssertEqualObjects([unmanaged.boolObj valueForKey:@"self"], (@[@NO, @YES])); 
    
    unmanaged.intObj = (id)@[@2, @3]; 
     XCTAssertEqualObjects([unmanaged.intObj valueForKey:@"self"], (@[@2, @3])); 
    
    unmanaged.floatObj = (id)@[@2.2f, @3.3f]; 
     XCTAssertEqualObjects([unmanaged.floatObj valueForKey:@"self"], (@[@2.2f, @3.3f])); 
    
    unmanaged.doubleObj = (id)@[@2.2, @3.3]; 
     XCTAssertEqualObjects([unmanaged.doubleObj valueForKey:@"self"], (@[@2.2, @3.3])); 
    
    unmanaged.stringObj = (id)@[@"a", @"b"]; 
     XCTAssertEqualObjects([unmanaged.stringObj valueForKey:@"self"], (@[@"a", @"b"])); 
    
    unmanaged.dataObj = (id)@[data(1), data(2)]; 
     XCTAssertEqualObjects([unmanaged.dataObj valueForKey:@"self"], (@[data(1), data(2)])); 
    
    unmanaged.dateObj = (id)@[date(1), date(2)]; 
     XCTAssertEqualObjects([unmanaged.dateObj valueForKey:@"self"], (@[date(1), date(2)])); 
    
    unmanaged.decimalObj = (id)@[decimal128(1), decimal128(2)]; 
     XCTAssertEqualObjects([unmanaged.decimalObj valueForKey:@"self"], (@[decimal128(1), decimal128(2)])); 
    
    unmanaged.objectIdObj = (id)@[objectId(1), objectId(2)]; 
     XCTAssertEqualObjects([unmanaged.objectIdObj valueForKey:@"self"], (@[objectId(1), objectId(2)])); 
    
    optUnmanaged.boolObj = (id)@[@NO, @YES, NSNull.null]; 
     XCTAssertEqualObjects([optUnmanaged.boolObj valueForKey:@"self"], (@[@NO, @YES, NSNull.null])); 
    
    optUnmanaged.intObj = (id)@[@2, @3, NSNull.null]; 
     XCTAssertEqualObjects([optUnmanaged.intObj valueForKey:@"self"], (@[@2, @3, NSNull.null])); 
    
    optUnmanaged.floatObj = (id)@[@2.2f, @3.3f, NSNull.null]; 
     XCTAssertEqualObjects([optUnmanaged.floatObj valueForKey:@"self"], (@[@2.2f, @3.3f, NSNull.null])); 
    
    optUnmanaged.doubleObj = (id)@[@2.2, @3.3, NSNull.null]; 
     XCTAssertEqualObjects([optUnmanaged.doubleObj valueForKey:@"self"], (@[@2.2, @3.3, NSNull.null])); 
    
    optUnmanaged.stringObj = (id)@[@"a", @"b", NSNull.null]; 
     XCTAssertEqualObjects([optUnmanaged.stringObj valueForKey:@"self"], (@[@"a", @"b", NSNull.null])); 
    
    optUnmanaged.dataObj = (id)@[data(1), data(2), NSNull.null]; 
     XCTAssertEqualObjects([optUnmanaged.dataObj valueForKey:@"self"], (@[data(1), data(2), NSNull.null])); 
    
    optUnmanaged.dateObj = (id)@[date(1), date(2), NSNull.null]; 
     XCTAssertEqualObjects([optUnmanaged.dateObj valueForKey:@"self"], (@[date(1), date(2), NSNull.null])); 
    
    optUnmanaged.decimalObj = (id)@[decimal128(1), decimal128(2), NSNull.null]; 
     XCTAssertEqualObjects([optUnmanaged.decimalObj valueForKey:@"self"], (@[decimal128(1), decimal128(2), NSNull.null])); 
    
    optUnmanaged.objectIdObj = (id)@[objectId(1), objectId(2), NSNull.null]; 
     XCTAssertEqualObjects([optUnmanaged.objectIdObj valueForKey:@"self"], (@[objectId(1), objectId(2), NSNull.null])); 
    
    managed.boolObj = (id)@[@NO, @YES]; 
     XCTAssertEqualObjects([managed.boolObj valueForKey:@"self"], (@[@NO, @YES])); 
    
    managed.intObj = (id)@[@2, @3]; 
     XCTAssertEqualObjects([managed.intObj valueForKey:@"self"], (@[@2, @3])); 
    
    managed.floatObj = (id)@[@2.2f, @3.3f]; 
     XCTAssertEqualObjects([managed.floatObj valueForKey:@"self"], (@[@2.2f, @3.3f])); 
    
    managed.doubleObj = (id)@[@2.2, @3.3]; 
     XCTAssertEqualObjects([managed.doubleObj valueForKey:@"self"], (@[@2.2, @3.3])); 
    
    managed.stringObj = (id)@[@"a", @"b"]; 
     XCTAssertEqualObjects([managed.stringObj valueForKey:@"self"], (@[@"a", @"b"])); 
    
    managed.dataObj = (id)@[data(1), data(2)]; 
     XCTAssertEqualObjects([managed.dataObj valueForKey:@"self"], (@[data(1), data(2)])); 
    
    managed.dateObj = (id)@[date(1), date(2)]; 
     XCTAssertEqualObjects([managed.dateObj valueForKey:@"self"], (@[date(1), date(2)])); 
    
    managed.decimalObj = (id)@[decimal128(1), decimal128(2)]; 
     XCTAssertEqualObjects([managed.decimalObj valueForKey:@"self"], (@[decimal128(1), decimal128(2)])); 
    
    managed.objectIdObj = (id)@[objectId(1), objectId(2)]; 
     XCTAssertEqualObjects([managed.objectIdObj valueForKey:@"self"], (@[objectId(1), objectId(2)])); 
    
    optManaged.boolObj = (id)@[@NO, @YES, NSNull.null]; 
     XCTAssertEqualObjects([optManaged.boolObj valueForKey:@"self"], (@[@NO, @YES, NSNull.null])); 
    
    optManaged.intObj = (id)@[@2, @3, NSNull.null]; 
     XCTAssertEqualObjects([optManaged.intObj valueForKey:@"self"], (@[@2, @3, NSNull.null])); 
    
    optManaged.floatObj = (id)@[@2.2f, @3.3f, NSNull.null]; 
     XCTAssertEqualObjects([optManaged.floatObj valueForKey:@"self"], (@[@2.2f, @3.3f, NSNull.null])); 
    
    optManaged.doubleObj = (id)@[@2.2, @3.3, NSNull.null]; 
     XCTAssertEqualObjects([optManaged.doubleObj valueForKey:@"self"], (@[@2.2, @3.3, NSNull.null])); 
    
    optManaged.stringObj = (id)@[@"a", @"b", NSNull.null]; 
     XCTAssertEqualObjects([optManaged.stringObj valueForKey:@"self"], (@[@"a", @"b", NSNull.null])); 
    
    optManaged.dataObj = (id)@[data(1), data(2), NSNull.null]; 
     XCTAssertEqualObjects([optManaged.dataObj valueForKey:@"self"], (@[data(1), data(2), NSNull.null])); 
    
    optManaged.dateObj = (id)@[date(1), date(2), NSNull.null]; 
     XCTAssertEqualObjects([optManaged.dateObj valueForKey:@"self"], (@[date(1), date(2), NSNull.null])); 
    
    optManaged.decimalObj = (id)@[decimal128(1), decimal128(2), NSNull.null]; 
     XCTAssertEqualObjects([optManaged.decimalObj valueForKey:@"self"], (@[decimal128(1), decimal128(2), NSNull.null])); 
    
    optManaged.objectIdObj = (id)@[objectId(1), objectId(2), NSNull.null]; 
     XCTAssertEqualObjects([optManaged.objectIdObj valueForKey:@"self"], (@[objectId(1), objectId(2), NSNull.null])); 
    

    // Should not clear the set
    unmanaged.boolObj = unmanaged.boolObj; 
     XCTAssertEqualObjects([unmanaged.boolObj valueForKey:@"self"], (@[@NO, @YES])); 
    
    unmanaged.intObj = unmanaged.intObj; 
     XCTAssertEqualObjects([unmanaged.intObj valueForKey:@"self"], (@[@2, @3])); 
    
    unmanaged.floatObj = unmanaged.floatObj; 
     XCTAssertEqualObjects([unmanaged.floatObj valueForKey:@"self"], (@[@2.2f, @3.3f])); 
    
    unmanaged.doubleObj = unmanaged.doubleObj; 
     XCTAssertEqualObjects([unmanaged.doubleObj valueForKey:@"self"], (@[@2.2, @3.3])); 
    
    unmanaged.stringObj = unmanaged.stringObj; 
     XCTAssertEqualObjects([unmanaged.stringObj valueForKey:@"self"], (@[@"a", @"b"])); 
    
    unmanaged.dataObj = unmanaged.dataObj; 
     XCTAssertEqualObjects([unmanaged.dataObj valueForKey:@"self"], (@[data(1), data(2)])); 
    
    unmanaged.dateObj = unmanaged.dateObj; 
     XCTAssertEqualObjects([unmanaged.dateObj valueForKey:@"self"], (@[date(1), date(2)])); 
    
    unmanaged.decimalObj = unmanaged.decimalObj; 
     XCTAssertEqualObjects([unmanaged.decimalObj valueForKey:@"self"], (@[decimal128(1), decimal128(2)])); 
    
    unmanaged.objectIdObj = unmanaged.objectIdObj; 
     XCTAssertEqualObjects([unmanaged.objectIdObj valueForKey:@"self"], (@[objectId(1), objectId(2)])); 
    
    optUnmanaged.boolObj = optUnmanaged.boolObj; 
     XCTAssertEqualObjects([optUnmanaged.boolObj valueForKey:@"self"], (@[@NO, @YES, NSNull.null])); 
    
    optUnmanaged.intObj = optUnmanaged.intObj; 
     XCTAssertEqualObjects([optUnmanaged.intObj valueForKey:@"self"], (@[@2, @3, NSNull.null])); 
    
    optUnmanaged.floatObj = optUnmanaged.floatObj; 
     XCTAssertEqualObjects([optUnmanaged.floatObj valueForKey:@"self"], (@[@2.2f, @3.3f, NSNull.null])); 
    
    optUnmanaged.doubleObj = optUnmanaged.doubleObj; 
     XCTAssertEqualObjects([optUnmanaged.doubleObj valueForKey:@"self"], (@[@2.2, @3.3, NSNull.null])); 
    
    optUnmanaged.stringObj = optUnmanaged.stringObj; 
     XCTAssertEqualObjects([optUnmanaged.stringObj valueForKey:@"self"], (@[@"a", @"b", NSNull.null])); 
    
    optUnmanaged.dataObj = optUnmanaged.dataObj; 
     XCTAssertEqualObjects([optUnmanaged.dataObj valueForKey:@"self"], (@[data(1), data(2), NSNull.null])); 
    
    optUnmanaged.dateObj = optUnmanaged.dateObj; 
     XCTAssertEqualObjects([optUnmanaged.dateObj valueForKey:@"self"], (@[date(1), date(2), NSNull.null])); 
    
    optUnmanaged.decimalObj = optUnmanaged.decimalObj; 
     XCTAssertEqualObjects([optUnmanaged.decimalObj valueForKey:@"self"], (@[decimal128(1), decimal128(2), NSNull.null])); 
    
    optUnmanaged.objectIdObj = optUnmanaged.objectIdObj; 
     XCTAssertEqualObjects([optUnmanaged.objectIdObj valueForKey:@"self"], (@[objectId(1), objectId(2), NSNull.null])); 
    
    managed.boolObj = managed.boolObj; 
     XCTAssertEqualObjects([managed.boolObj valueForKey:@"self"], (@[@NO, @YES])); 
    
    managed.intObj = managed.intObj; 
     XCTAssertEqualObjects([managed.intObj valueForKey:@"self"], (@[@2, @3])); 
    
    managed.floatObj = managed.floatObj; 
     XCTAssertEqualObjects([managed.floatObj valueForKey:@"self"], (@[@2.2f, @3.3f])); 
    
    managed.doubleObj = managed.doubleObj; 
     XCTAssertEqualObjects([managed.doubleObj valueForKey:@"self"], (@[@2.2, @3.3])); 
    
    managed.stringObj = managed.stringObj; 
     XCTAssertEqualObjects([managed.stringObj valueForKey:@"self"], (@[@"a", @"b"])); 
    
    managed.dataObj = managed.dataObj; 
     XCTAssertEqualObjects([managed.dataObj valueForKey:@"self"], (@[data(1), data(2)])); 
    
    managed.dateObj = managed.dateObj; 
     XCTAssertEqualObjects([managed.dateObj valueForKey:@"self"], (@[date(1), date(2)])); 
    
    managed.decimalObj = managed.decimalObj; 
     XCTAssertEqualObjects([managed.decimalObj valueForKey:@"self"], (@[decimal128(1), decimal128(2)])); 
    
    managed.objectIdObj = managed.objectIdObj; 
     XCTAssertEqualObjects([managed.objectIdObj valueForKey:@"self"], (@[objectId(1), objectId(2)])); 
    
    optManaged.boolObj = optManaged.boolObj; 
     XCTAssertEqualObjects([optManaged.boolObj valueForKey:@"self"], (@[@NO, @YES, NSNull.null])); 
    
    optManaged.intObj = optManaged.intObj; 
     XCTAssertEqualObjects([optManaged.intObj valueForKey:@"self"], (@[@2, @3, NSNull.null])); 
    
    optManaged.floatObj = optManaged.floatObj; 
     XCTAssertEqualObjects([optManaged.floatObj valueForKey:@"self"], (@[@2.2f, @3.3f, NSNull.null])); 
    
    optManaged.doubleObj = optManaged.doubleObj; 
     XCTAssertEqualObjects([optManaged.doubleObj valueForKey:@"self"], (@[@2.2, @3.3, NSNull.null])); 
    
    optManaged.stringObj = optManaged.stringObj; 
     XCTAssertEqualObjects([optManaged.stringObj valueForKey:@"self"], (@[@"a", @"b", NSNull.null])); 
    
    optManaged.dataObj = optManaged.dataObj; 
     XCTAssertEqualObjects([optManaged.dataObj valueForKey:@"self"], (@[data(1), data(2), NSNull.null])); 
    
    optManaged.dateObj = optManaged.dateObj; 
     XCTAssertEqualObjects([optManaged.dateObj valueForKey:@"self"], (@[date(1), date(2), NSNull.null])); 
    
    optManaged.decimalObj = optManaged.decimalObj; 
     XCTAssertEqualObjects([optManaged.decimalObj valueForKey:@"self"], (@[decimal128(1), decimal128(2), NSNull.null])); 
    
    optManaged.objectIdObj = optManaged.objectIdObj; 
     XCTAssertEqualObjects([optManaged.objectIdObj valueForKey:@"self"], (@[objectId(1), objectId(2), NSNull.null])); 
    

    [unmanaged.intObj removeAllObjects];
    unmanaged.intObj = managed.intObj;
    XCTAssertEqualObjects([unmanaged.intObj valueForKey:@"self"], (@[@2, @3]));

    [managed.intObj removeAllObjects];
    managed.intObj = unmanaged.intObj;
    XCTAssertEqualObjects([managed.intObj valueForKey:@"self"], (@[@2, @3]));
}

- (void)testDynamicAssignment {
    unmanaged[@"boolObj"] = (id)@[@YES]; 
     XCTAssertEqualObjects(unmanaged[@"boolObj"][0], @YES);
    unmanaged[@"intObj"] = (id)@[@3]; 
     XCTAssertEqualObjects(unmanaged[@"intObj"][0], @3);
    unmanaged[@"floatObj"] = (id)@[@3.3f]; 
     XCTAssertEqualObjects(unmanaged[@"floatObj"][0], @3.3f);
    unmanaged[@"doubleObj"] = (id)@[@3.3]; 
     XCTAssertEqualObjects(unmanaged[@"doubleObj"][0], @3.3);
    unmanaged[@"stringObj"] = (id)@[@"b"]; 
     XCTAssertEqualObjects(unmanaged[@"stringObj"][0], @"b");
    unmanaged[@"dataObj"] = (id)@[data(2)]; 
     XCTAssertEqualObjects(unmanaged[@"dataObj"][0], data(2));
    unmanaged[@"dateObj"] = (id)@[date(2)]; 
     XCTAssertEqualObjects(unmanaged[@"dateObj"][0], date(2));
    unmanaged[@"decimalObj"] = (id)@[decimal128(2)]; 
     XCTAssertEqualObjects(unmanaged[@"decimalObj"][0], decimal128(2));
    unmanaged[@"objectIdObj"] = (id)@[objectId(2)]; 
     XCTAssertEqualObjects(unmanaged[@"objectIdObj"][0], objectId(2));
    optUnmanaged[@"boolObj"] = (id)@[@YES]; 
     XCTAssertEqualObjects(optUnmanaged[@"boolObj"][0], @YES);
    optUnmanaged[@"intObj"] = (id)@[@3]; 
     XCTAssertEqualObjects(optUnmanaged[@"intObj"][0], @3);
    optUnmanaged[@"floatObj"] = (id)@[@3.3f]; 
     XCTAssertEqualObjects(optUnmanaged[@"floatObj"][0], @3.3f);
    optUnmanaged[@"doubleObj"] = (id)@[@3.3]; 
     XCTAssertEqualObjects(optUnmanaged[@"doubleObj"][0], @3.3);
    optUnmanaged[@"stringObj"] = (id)@[@"b"]; 
     XCTAssertEqualObjects(optUnmanaged[@"stringObj"][0], @"b");
    optUnmanaged[@"dataObj"] = (id)@[data(2)]; 
     XCTAssertEqualObjects(optUnmanaged[@"dataObj"][0], data(2));
    optUnmanaged[@"dateObj"] = (id)@[date(2)]; 
     XCTAssertEqualObjects(optUnmanaged[@"dateObj"][0], date(2));
    optUnmanaged[@"decimalObj"] = (id)@[decimal128(2)]; 
     XCTAssertEqualObjects(optUnmanaged[@"decimalObj"][0], decimal128(2));
    optUnmanaged[@"objectIdObj"] = (id)@[objectId(2)]; 
     XCTAssertEqualObjects(optUnmanaged[@"objectIdObj"][0], objectId(2));
    managed[@"boolObj"] = (id)@[@YES]; 
     XCTAssertEqualObjects(managed[@"boolObj"][0], @YES);
    managed[@"intObj"] = (id)@[@3]; 
     XCTAssertEqualObjects(managed[@"intObj"][0], @3);
    managed[@"floatObj"] = (id)@[@3.3f]; 
     XCTAssertEqualObjects(managed[@"floatObj"][0], @3.3f);
    managed[@"doubleObj"] = (id)@[@3.3]; 
     XCTAssertEqualObjects(managed[@"doubleObj"][0], @3.3);
    managed[@"stringObj"] = (id)@[@"b"]; 
     XCTAssertEqualObjects(managed[@"stringObj"][0], @"b");
    managed[@"dataObj"] = (id)@[data(2)]; 
     XCTAssertEqualObjects(managed[@"dataObj"][0], data(2));
    managed[@"dateObj"] = (id)@[date(2)]; 
     XCTAssertEqualObjects(managed[@"dateObj"][0], date(2));
    managed[@"decimalObj"] = (id)@[decimal128(2)]; 
     XCTAssertEqualObjects(managed[@"decimalObj"][0], decimal128(2));
    managed[@"objectIdObj"] = (id)@[objectId(2)]; 
     XCTAssertEqualObjects(managed[@"objectIdObj"][0], objectId(2));
    optManaged[@"boolObj"] = (id)@[@YES]; 
     XCTAssertEqualObjects(optManaged[@"boolObj"][0], @YES);
    optManaged[@"intObj"] = (id)@[@3]; 
     XCTAssertEqualObjects(optManaged[@"intObj"][0], @3);
    optManaged[@"floatObj"] = (id)@[@3.3f]; 
     XCTAssertEqualObjects(optManaged[@"floatObj"][0], @3.3f);
    optManaged[@"doubleObj"] = (id)@[@3.3]; 
     XCTAssertEqualObjects(optManaged[@"doubleObj"][0], @3.3);
    optManaged[@"stringObj"] = (id)@[@"b"]; 
     XCTAssertEqualObjects(optManaged[@"stringObj"][0], @"b");
    optManaged[@"dataObj"] = (id)@[data(2)]; 
     XCTAssertEqualObjects(optManaged[@"dataObj"][0], data(2));
    optManaged[@"dateObj"] = (id)@[date(2)]; 
     XCTAssertEqualObjects(optManaged[@"dateObj"][0], date(2));
    optManaged[@"decimalObj"] = (id)@[decimal128(2)]; 
     XCTAssertEqualObjects(optManaged[@"decimalObj"][0], decimal128(2));
    optManaged[@"objectIdObj"] = (id)@[objectId(2)]; 
     XCTAssertEqualObjects(optManaged[@"objectIdObj"][0], objectId(2));

    // Should replace and not append
    unmanaged[@"boolObj"] = (id)@[@NO, @YES]; 
     XCTAssertEqualObjects([unmanaged[@"boolObj"] valueForKey:@"self"], (@[@NO, @YES])); 
    
    unmanaged[@"intObj"] = (id)@[@2, @3]; 
     XCTAssertEqualObjects([unmanaged[@"intObj"] valueForKey:@"self"], (@[@2, @3])); 
    
    unmanaged[@"floatObj"] = (id)@[@2.2f, @3.3f]; 
     XCTAssertEqualObjects([unmanaged[@"floatObj"] valueForKey:@"self"], (@[@2.2f, @3.3f])); 
    
    unmanaged[@"doubleObj"] = (id)@[@2.2, @3.3]; 
     XCTAssertEqualObjects([unmanaged[@"doubleObj"] valueForKey:@"self"], (@[@2.2, @3.3])); 
    
    unmanaged[@"stringObj"] = (id)@[@"a", @"b"]; 
     XCTAssertEqualObjects([unmanaged[@"stringObj"] valueForKey:@"self"], (@[@"a", @"b"])); 
    
    unmanaged[@"dataObj"] = (id)@[data(1), data(2)]; 
     XCTAssertEqualObjects([unmanaged[@"dataObj"] valueForKey:@"self"], (@[data(1), data(2)])); 
    
    unmanaged[@"dateObj"] = (id)@[date(1), date(2)]; 
     XCTAssertEqualObjects([unmanaged[@"dateObj"] valueForKey:@"self"], (@[date(1), date(2)])); 
    
    unmanaged[@"decimalObj"] = (id)@[decimal128(1), decimal128(2)]; 
     XCTAssertEqualObjects([unmanaged[@"decimalObj"] valueForKey:@"self"], (@[decimal128(1), decimal128(2)])); 
    
    unmanaged[@"objectIdObj"] = (id)@[objectId(1), objectId(2)]; 
     XCTAssertEqualObjects([unmanaged[@"objectIdObj"] valueForKey:@"self"], (@[objectId(1), objectId(2)])); 
    
    optUnmanaged[@"boolObj"] = (id)@[@NO, @YES, NSNull.null]; 
     XCTAssertEqualObjects([optUnmanaged[@"boolObj"] valueForKey:@"self"], (@[@NO, @YES, NSNull.null])); 
    
    optUnmanaged[@"intObj"] = (id)@[@2, @3, NSNull.null]; 
     XCTAssertEqualObjects([optUnmanaged[@"intObj"] valueForKey:@"self"], (@[@2, @3, NSNull.null])); 
    
    optUnmanaged[@"floatObj"] = (id)@[@2.2f, @3.3f, NSNull.null]; 
     XCTAssertEqualObjects([optUnmanaged[@"floatObj"] valueForKey:@"self"], (@[@2.2f, @3.3f, NSNull.null])); 
    
    optUnmanaged[@"doubleObj"] = (id)@[@2.2, @3.3, NSNull.null]; 
     XCTAssertEqualObjects([optUnmanaged[@"doubleObj"] valueForKey:@"self"], (@[@2.2, @3.3, NSNull.null])); 
    
    optUnmanaged[@"stringObj"] = (id)@[@"a", @"b", NSNull.null]; 
     XCTAssertEqualObjects([optUnmanaged[@"stringObj"] valueForKey:@"self"], (@[@"a", @"b", NSNull.null])); 
    
    optUnmanaged[@"dataObj"] = (id)@[data(1), data(2), NSNull.null]; 
     XCTAssertEqualObjects([optUnmanaged[@"dataObj"] valueForKey:@"self"], (@[data(1), data(2), NSNull.null])); 
    
    optUnmanaged[@"dateObj"] = (id)@[date(1), date(2), NSNull.null]; 
     XCTAssertEqualObjects([optUnmanaged[@"dateObj"] valueForKey:@"self"], (@[date(1), date(2), NSNull.null])); 
    
    optUnmanaged[@"decimalObj"] = (id)@[decimal128(1), decimal128(2), NSNull.null]; 
     XCTAssertEqualObjects([optUnmanaged[@"decimalObj"] valueForKey:@"self"], (@[decimal128(1), decimal128(2), NSNull.null])); 
    
    optUnmanaged[@"objectIdObj"] = (id)@[objectId(1), objectId(2), NSNull.null]; 
     XCTAssertEqualObjects([optUnmanaged[@"objectIdObj"] valueForKey:@"self"], (@[objectId(1), objectId(2), NSNull.null])); 
    
    managed[@"boolObj"] = (id)@[@NO, @YES]; 
     XCTAssertEqualObjects([managed[@"boolObj"] valueForKey:@"self"], (@[@NO, @YES])); 
    
    managed[@"intObj"] = (id)@[@2, @3]; 
     XCTAssertEqualObjects([managed[@"intObj"] valueForKey:@"self"], (@[@2, @3])); 
    
    managed[@"floatObj"] = (id)@[@2.2f, @3.3f]; 
     XCTAssertEqualObjects([managed[@"floatObj"] valueForKey:@"self"], (@[@2.2f, @3.3f])); 
    
    managed[@"doubleObj"] = (id)@[@2.2, @3.3]; 
     XCTAssertEqualObjects([managed[@"doubleObj"] valueForKey:@"self"], (@[@2.2, @3.3])); 
    
    managed[@"stringObj"] = (id)@[@"a", @"b"]; 
     XCTAssertEqualObjects([managed[@"stringObj"] valueForKey:@"self"], (@[@"a", @"b"])); 
    
    managed[@"dataObj"] = (id)@[data(1), data(2)]; 
     XCTAssertEqualObjects([managed[@"dataObj"] valueForKey:@"self"], (@[data(1), data(2)])); 
    
    managed[@"dateObj"] = (id)@[date(1), date(2)]; 
     XCTAssertEqualObjects([managed[@"dateObj"] valueForKey:@"self"], (@[date(1), date(2)])); 
    
    managed[@"decimalObj"] = (id)@[decimal128(1), decimal128(2)]; 
     XCTAssertEqualObjects([managed[@"decimalObj"] valueForKey:@"self"], (@[decimal128(1), decimal128(2)])); 
    
    managed[@"objectIdObj"] = (id)@[objectId(1), objectId(2)]; 
     XCTAssertEqualObjects([managed[@"objectIdObj"] valueForKey:@"self"], (@[objectId(1), objectId(2)])); 
    
    optManaged[@"boolObj"] = (id)@[@NO, @YES, NSNull.null]; 
     XCTAssertEqualObjects([optManaged[@"boolObj"] valueForKey:@"self"], (@[@NO, @YES, NSNull.null])); 
    
    optManaged[@"intObj"] = (id)@[@2, @3, NSNull.null]; 
     XCTAssertEqualObjects([optManaged[@"intObj"] valueForKey:@"self"], (@[@2, @3, NSNull.null])); 
    
    optManaged[@"floatObj"] = (id)@[@2.2f, @3.3f, NSNull.null]; 
     XCTAssertEqualObjects([optManaged[@"floatObj"] valueForKey:@"self"], (@[@2.2f, @3.3f, NSNull.null])); 
    
    optManaged[@"doubleObj"] = (id)@[@2.2, @3.3, NSNull.null]; 
     XCTAssertEqualObjects([optManaged[@"doubleObj"] valueForKey:@"self"], (@[@2.2, @3.3, NSNull.null])); 
    
    optManaged[@"stringObj"] = (id)@[@"a", @"b", NSNull.null]; 
     XCTAssertEqualObjects([optManaged[@"stringObj"] valueForKey:@"self"], (@[@"a", @"b", NSNull.null])); 
    
    optManaged[@"dataObj"] = (id)@[data(1), data(2), NSNull.null]; 
     XCTAssertEqualObjects([optManaged[@"dataObj"] valueForKey:@"self"], (@[data(1), data(2), NSNull.null])); 
    
    optManaged[@"dateObj"] = (id)@[date(1), date(2), NSNull.null]; 
     XCTAssertEqualObjects([optManaged[@"dateObj"] valueForKey:@"self"], (@[date(1), date(2), NSNull.null])); 
    
    optManaged[@"decimalObj"] = (id)@[decimal128(1), decimal128(2), NSNull.null]; 
     XCTAssertEqualObjects([optManaged[@"decimalObj"] valueForKey:@"self"], (@[decimal128(1), decimal128(2), NSNull.null])); 
    
    optManaged[@"objectIdObj"] = (id)@[objectId(1), objectId(2), NSNull.null]; 
     XCTAssertEqualObjects([optManaged[@"objectIdObj"] valueForKey:@"self"], (@[objectId(1), objectId(2), NSNull.null])); 
    

    // Should not clear the set
    unmanaged[@"boolObj"] = unmanaged[@"boolObj"]; 
     XCTAssertEqualObjects([unmanaged[@"boolObj"] valueForKey:@"self"], (@[@NO, @YES])); 
    
    unmanaged[@"intObj"] = unmanaged[@"intObj"]; 
     XCTAssertEqualObjects([unmanaged[@"intObj"] valueForKey:@"self"], (@[@2, @3])); 
    
    unmanaged[@"floatObj"] = unmanaged[@"floatObj"]; 
     XCTAssertEqualObjects([unmanaged[@"floatObj"] valueForKey:@"self"], (@[@2.2f, @3.3f])); 
    
    unmanaged[@"doubleObj"] = unmanaged[@"doubleObj"]; 
     XCTAssertEqualObjects([unmanaged[@"doubleObj"] valueForKey:@"self"], (@[@2.2, @3.3])); 
    
    unmanaged[@"stringObj"] = unmanaged[@"stringObj"]; 
     XCTAssertEqualObjects([unmanaged[@"stringObj"] valueForKey:@"self"], (@[@"a", @"b"])); 
    
    unmanaged[@"dataObj"] = unmanaged[@"dataObj"]; 
     XCTAssertEqualObjects([unmanaged[@"dataObj"] valueForKey:@"self"], (@[data(1), data(2)])); 
    
    unmanaged[@"dateObj"] = unmanaged[@"dateObj"]; 
     XCTAssertEqualObjects([unmanaged[@"dateObj"] valueForKey:@"self"], (@[date(1), date(2)])); 
    
    unmanaged[@"decimalObj"] = unmanaged[@"decimalObj"]; 
     XCTAssertEqualObjects([unmanaged[@"decimalObj"] valueForKey:@"self"], (@[decimal128(1), decimal128(2)])); 
    
    unmanaged[@"objectIdObj"] = unmanaged[@"objectIdObj"]; 
     XCTAssertEqualObjects([unmanaged[@"objectIdObj"] valueForKey:@"self"], (@[objectId(1), objectId(2)])); 
    
    optUnmanaged[@"boolObj"] = optUnmanaged[@"boolObj"]; 
     XCTAssertEqualObjects([optUnmanaged[@"boolObj"] valueForKey:@"self"], (@[@NO, @YES, NSNull.null])); 
    
    optUnmanaged[@"intObj"] = optUnmanaged[@"intObj"]; 
     XCTAssertEqualObjects([optUnmanaged[@"intObj"] valueForKey:@"self"], (@[@2, @3, NSNull.null])); 
    
    optUnmanaged[@"floatObj"] = optUnmanaged[@"floatObj"]; 
     XCTAssertEqualObjects([optUnmanaged[@"floatObj"] valueForKey:@"self"], (@[@2.2f, @3.3f, NSNull.null])); 
    
    optUnmanaged[@"doubleObj"] = optUnmanaged[@"doubleObj"]; 
     XCTAssertEqualObjects([optUnmanaged[@"doubleObj"] valueForKey:@"self"], (@[@2.2, @3.3, NSNull.null])); 
    
    optUnmanaged[@"stringObj"] = optUnmanaged[@"stringObj"]; 
     XCTAssertEqualObjects([optUnmanaged[@"stringObj"] valueForKey:@"self"], (@[@"a", @"b", NSNull.null])); 
    
    optUnmanaged[@"dataObj"] = optUnmanaged[@"dataObj"]; 
     XCTAssertEqualObjects([optUnmanaged[@"dataObj"] valueForKey:@"self"], (@[data(1), data(2), NSNull.null])); 
    
    optUnmanaged[@"dateObj"] = optUnmanaged[@"dateObj"]; 
     XCTAssertEqualObjects([optUnmanaged[@"dateObj"] valueForKey:@"self"], (@[date(1), date(2), NSNull.null])); 
    
    optUnmanaged[@"decimalObj"] = optUnmanaged[@"decimalObj"]; 
     XCTAssertEqualObjects([optUnmanaged[@"decimalObj"] valueForKey:@"self"], (@[decimal128(1), decimal128(2), NSNull.null])); 
    
    optUnmanaged[@"objectIdObj"] = optUnmanaged[@"objectIdObj"]; 
     XCTAssertEqualObjects([optUnmanaged[@"objectIdObj"] valueForKey:@"self"], (@[objectId(1), objectId(2), NSNull.null])); 
    
    managed[@"boolObj"] = managed[@"boolObj"]; 
     XCTAssertEqualObjects([managed[@"boolObj"] valueForKey:@"self"], (@[@NO, @YES])); 
    
    managed[@"intObj"] = managed[@"intObj"]; 
     XCTAssertEqualObjects([managed[@"intObj"] valueForKey:@"self"], (@[@2, @3])); 
    
    managed[@"floatObj"] = managed[@"floatObj"]; 
     XCTAssertEqualObjects([managed[@"floatObj"] valueForKey:@"self"], (@[@2.2f, @3.3f])); 
    
    managed[@"doubleObj"] = managed[@"doubleObj"]; 
     XCTAssertEqualObjects([managed[@"doubleObj"] valueForKey:@"self"], (@[@2.2, @3.3])); 
    
    managed[@"stringObj"] = managed[@"stringObj"]; 
     XCTAssertEqualObjects([managed[@"stringObj"] valueForKey:@"self"], (@[@"a", @"b"])); 
    
    managed[@"dataObj"] = managed[@"dataObj"]; 
     XCTAssertEqualObjects([managed[@"dataObj"] valueForKey:@"self"], (@[data(1), data(2)])); 
    
    managed[@"dateObj"] = managed[@"dateObj"]; 
     XCTAssertEqualObjects([managed[@"dateObj"] valueForKey:@"self"], (@[date(1), date(2)])); 
    
    managed[@"decimalObj"] = managed[@"decimalObj"]; 
     XCTAssertEqualObjects([managed[@"decimalObj"] valueForKey:@"self"], (@[decimal128(1), decimal128(2)])); 
    
    managed[@"objectIdObj"] = managed[@"objectIdObj"]; 
     XCTAssertEqualObjects([managed[@"objectIdObj"] valueForKey:@"self"], (@[objectId(1), objectId(2)])); 
    
    optManaged[@"boolObj"] = optManaged[@"boolObj"]; 
     XCTAssertEqualObjects([optManaged[@"boolObj"] valueForKey:@"self"], (@[@NO, @YES, NSNull.null])); 
    
    optManaged[@"intObj"] = optManaged[@"intObj"]; 
     XCTAssertEqualObjects([optManaged[@"intObj"] valueForKey:@"self"], (@[@2, @3, NSNull.null])); 
    
    optManaged[@"floatObj"] = optManaged[@"floatObj"]; 
     XCTAssertEqualObjects([optManaged[@"floatObj"] valueForKey:@"self"], (@[@2.2f, @3.3f, NSNull.null])); 
    
    optManaged[@"doubleObj"] = optManaged[@"doubleObj"]; 
     XCTAssertEqualObjects([optManaged[@"doubleObj"] valueForKey:@"self"], (@[@2.2, @3.3, NSNull.null])); 
    
    optManaged[@"stringObj"] = optManaged[@"stringObj"]; 
     XCTAssertEqualObjects([optManaged[@"stringObj"] valueForKey:@"self"], (@[@"a", @"b", NSNull.null])); 
    
    optManaged[@"dataObj"] = optManaged[@"dataObj"]; 
     XCTAssertEqualObjects([optManaged[@"dataObj"] valueForKey:@"self"], (@[data(1), data(2), NSNull.null])); 
    
    optManaged[@"dateObj"] = optManaged[@"dateObj"]; 
     XCTAssertEqualObjects([optManaged[@"dateObj"] valueForKey:@"self"], (@[date(1), date(2), NSNull.null])); 
    
    optManaged[@"decimalObj"] = optManaged[@"decimalObj"]; 
     XCTAssertEqualObjects([optManaged[@"decimalObj"] valueForKey:@"self"], (@[decimal128(1), decimal128(2), NSNull.null])); 
    
    optManaged[@"objectIdObj"] = optManaged[@"objectIdObj"]; 
     XCTAssertEqualObjects([optManaged[@"objectIdObj"] valueForKey:@"self"], (@[objectId(1), objectId(2), NSNull.null])); 
    

    [unmanaged[@"intObj"] removeAllObjects];
    unmanaged[@"intObj"] = managed.intObj;
    XCTAssertEqualObjects([unmanaged[@"intObj"] valueForKey:@"self"], (@[@2, @3]));

    [managed[@"intObj"] removeAllObjects];
    managed[@"intObj"] = unmanaged.intObj;
    XCTAssertEqualObjects([managed[@"intObj"] valueForKey:@"self"], (@[@2, @3]));
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
        RLMAssertThrowsWithReason([set objectAtIndex:0], @"thread");
        RLMAssertThrowsWithReason([set firstObject], @"thread");
        RLMAssertThrowsWithReason([set lastObject], @"thread");

        RLMAssertThrowsWithReason([set addObject:@0], @"thread");
        RLMAssertThrowsWithReason([set addObjects:@[@0]], @"thread");
        RLMAssertThrowsWithReason([set removeLastObject], @"thread");
        RLMAssertThrowsWithReason([set removeAllObjects], @"thread");

        RLMAssertThrowsWithReason([set indexOfObject:@1], @"thread");
        /* RLMAssertThrowsWithReason([set indexOfObjectWhere:@"TRUEPREDICATE"], @"thread"); */
        /* RLMAssertThrowsWithReason([set indexOfObjectWithPredicate:[NSPredicate predicateWithValue:NO]], @"thread"); */
        /* RLMAssertThrowsWithReason([set objectsWhere:@"TRUEPREDICATE"], @"thread"); */
        /* RLMAssertThrowsWithReason([set objectsWithPredicate:[NSPredicate predicateWithValue:NO]], @"thread"); */
        RLMAssertThrowsWithReason([set sortedResultsUsingKeyPath:@"self" ascending:YES], @"thread");
        RLMAssertThrowsWithReason([set sortedResultsUsingDescriptors:@[[RLMSortDescriptor sortDescriptorWithKeyPath:@"self" ascending:YES]]], @"thread");
        RLMAssertThrowsWithReason(set[0], @"thread");
        RLMAssertThrowsWithReason(set[0] = @0, @"thread");
        RLMAssertThrowsWithReason([set valueForKey:@"self"], @"thread");
        RLMAssertThrowsWithReason([set setValue:@1 forKey:@"self"], @"thread");
        RLMAssertThrowsWithReason({for (__unused id obj in set);}, @"thread");
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
    RLMAssertThrowsWithReason([set objectAtIndex:0], @"invalidated");
    RLMAssertThrowsWithReason([set firstObject], @"invalidated");
    RLMAssertThrowsWithReason([set lastObject], @"invalidated");

    RLMAssertThrowsWithReason([set addObject:@0], @"invalidated");
    RLMAssertThrowsWithReason([set addObjects:@[@0]], @"invalidated");
    RLMAssertThrowsWithReason([set removeLastObject], @"invalidated");
    RLMAssertThrowsWithReason([set removeAllObjects], @"invalidated");

    RLMAssertThrowsWithReason([set indexOfObject:@1], @"invalidated");
    /* RLMAssertThrowsWithReason([set indexOfObjectWhere:@"TRUEPREDICATE"], @"invalidated"); */
    /* RLMAssertThrowsWithReason([set indexOfObjectWithPredicate:[NSPredicate predicateWithValue:YES]], @"invalidated"); */
    /* RLMAssertThrowsWithReason([set objectsWhere:@"TRUEPREDICATE"], @"invalidated"); */
    /* RLMAssertThrowsWithReason([set objectsWithPredicate:[NSPredicate predicateWithValue:YES]], @"invalidated"); */
    RLMAssertThrowsWithReason([set sortedResultsUsingKeyPath:@"self" ascending:YES], @"invalidated");
    RLMAssertThrowsWithReason([set sortedResultsUsingDescriptors:@[[RLMSortDescriptor sortDescriptorWithKeyPath:@"self" ascending:YES]]], @"invalidated");
    RLMAssertThrowsWithReason(set[0], @"invalidated");
    RLMAssertThrowsWithReason(set[0] = @0, @"invalidated");
    RLMAssertThrowsWithReason([set valueForKey:@"self"], @"invalidated");
    RLMAssertThrowsWithReason([set setValue:@1 forKey:@"self"], @"invalidated");
    RLMAssertThrowsWithReason({for (__unused id obj in set);}, @"invalidated");

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
    XCTAssertNoThrow([set objectAtIndex:0]);
    XCTAssertNoThrow([set firstObject]);
    XCTAssertNoThrow([set lastObject]);

    XCTAssertNoThrow([set indexOfObject:@1]);
    /* XCTAssertNoThrow([set indexOfObjectWhere:@"TRUEPREDICATE"]); */
    /* XCTAssertNoThrow([set indexOfObjectWithPredicate:[NSPredicate predicateWithValue:YES]]); */
    /* XCTAssertNoThrow([set objectsWhere:@"TRUEPREDICATE"]); */
    /* XCTAssertNoThrow([set objectsWithPredicate:[NSPredicate predicateWithValue:YES]]); */
    XCTAssertNoThrow([set sortedResultsUsingKeyPath:@"self" ascending:YES]);
    XCTAssertNoThrow([set sortedResultsUsingDescriptors:@[[RLMSortDescriptor sortDescriptorWithKeyPath:@"self" ascending:YES]]]);
    XCTAssertNoThrow(set[0]);
    XCTAssertNoThrow([set valueForKey:@"self"]);
    XCTAssertNoThrow({for (__unused id obj in set);});


    RLMAssertThrowsWithReason([set addObject:@0], @"write transaction");
    RLMAssertThrowsWithReason([set addObjects:@[@0]], @"write transaction");
    RLMAssertThrowsWithReason([set removeLastObject], @"write transaction");
    RLMAssertThrowsWithReason([set removeAllObjects], @"write transaction");

    RLMAssertThrowsWithReason(set[0] = @0, @"write transaction");
    RLMAssertThrowsWithReason([set setValue:@1 forKey:@"self"], @"write transaction");
}

- (void)testDeleteOwningObject {
    RLMSet *set = managed.intObj;
    XCTAssertFalse(set.isInvalidated);
    [realm deleteObject:managed];
    XCTAssertTrue(set.isInvalidated);
}

#pragma clang diagnostic ignored "-Warc-retain-cycles"

- (void)testNotificationSentInitially {
    [realm commitWriteTransaction];

    id expectation = [self expectationWithDescription:@""];
    id token = [managed.intObj addNotificationBlock:^(RLMSet *set, RLMCollectionChange *change, NSError *error) {
        XCTAssertNotNil(set);
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
    id token = [managed.intObj addNotificationBlock:^(RLMSet *set, RLMCollectionChange *change, NSError *error) {
        XCTAssertNotNil(set);
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
