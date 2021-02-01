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
        unmanaged.uuidObj,
        optUnmanaged.boolObj,
        optUnmanaged.intObj,
        optUnmanaged.floatObj,
        optUnmanaged.doubleObj,
        optUnmanaged.stringObj,
        optUnmanaged.dataObj,
        optUnmanaged.dateObj,
        optUnmanaged.decimalObj,
        optUnmanaged.objectIdObj,
        optUnmanaged.uuidObj,
        managed.boolObj,
        managed.intObj,
        managed.floatObj,
        managed.doubleObj,
        managed.stringObj,
        managed.dataObj,
        managed.dateObj,
        managed.decimalObj,
        managed.objectIdObj,
        managed.uuidObj,
        optManaged.boolObj,
        optManaged.intObj,
        optManaged.floatObj,
        optManaged.doubleObj,
        optManaged.stringObj,
        optManaged.dataObj,
        optManaged.dateObj,
        optManaged.decimalObj,
        optManaged.objectIdObj,
        optManaged.uuidObj,
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
    [unmanaged.stringObj addObjects:@[@"a", @"bc"]];
    [unmanaged.dataObj addObjects:@[data(1), data(2)]];
    [unmanaged.dateObj addObjects:@[date(1), date(2)]];
    [unmanaged.decimalObj addObjects:@[decimal128(1), decimal128(2)]];
    [unmanaged.objectIdObj addObjects:@[objectId(1), objectId(2)]];
    [unmanaged.uuidObj addObjects:@[uuid(@"00000000-0000-0000-0000-000000000000"), uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")]];
    [optUnmanaged.boolObj addObjects:@[NSNull.null, @NO, @YES]];
    [optUnmanaged.intObj addObjects:@[NSNull.null, @2, @3]];
    [optUnmanaged.floatObj addObjects:@[NSNull.null, @2.2f, @3.3f]];
    [optUnmanaged.doubleObj addObjects:@[NSNull.null, @2.2, @3.3]];
    [optUnmanaged.stringObj addObjects:@[NSNull.null, @"a", @"bc"]];
    [optUnmanaged.dataObj addObjects:@[NSNull.null, data(1), data(2)]];
    [optUnmanaged.dateObj addObjects:@[NSNull.null, date(1), date(2)]];
    [optUnmanaged.decimalObj addObjects:@[NSNull.null, decimal128(1), decimal128(2)]];
    [optUnmanaged.objectIdObj addObjects:@[NSNull.null, objectId(1), objectId(2)]];
    [optUnmanaged.uuidObj addObjects:@[NSNull.null, uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"), uuid(@"00000000-0000-0000-0000-000000000000")]];
    [managed.boolObj addObjects:@[@NO, @YES]];
    [managed.intObj addObjects:@[@2, @3]];
    [managed.floatObj addObjects:@[@2.2f, @3.3f]];
    [managed.doubleObj addObjects:@[@2.2, @3.3]];
    [managed.stringObj addObjects:@[@"a", @"bc"]];
    [managed.dataObj addObjects:@[data(1), data(2)]];
    [managed.dateObj addObjects:@[date(1), date(2)]];
    [managed.decimalObj addObjects:@[decimal128(1), decimal128(2)]];
    [managed.objectIdObj addObjects:@[objectId(1), objectId(2)]];
    [managed.uuidObj addObjects:@[uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"), uuid(@"00000000-0000-0000-0000-000000000000")]];
    [optManaged.boolObj addObjects:@[NSNull.null, @NO, @YES]];
    [optManaged.intObj addObjects:@[NSNull.null, @2, @3]];
    [optManaged.floatObj addObjects:@[NSNull.null, @2.2f, @3.3f]];
    [optManaged.doubleObj addObjects:@[NSNull.null, @2.2, @3.3]];
    [optManaged.stringObj addObjects:@[NSNull.null, @"a", @"bc"]];
    [optManaged.dataObj addObjects:@[NSNull.null, data(1), data(2)]];
    [optManaged.dateObj addObjects:@[NSNull.null, date(1), date(2)]];
    [optManaged.decimalObj addObjects:@[NSNull.null, decimal128(1), decimal128(2)]];
    [optManaged.objectIdObj addObjects:@[NSNull.null, objectId(1), objectId(2)]];
    [optManaged.uuidObj addObjects:@[NSNull.null, uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"), uuid(@"00000000-0000-0000-0000-000000000000")]];
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

- (void)testContainsObject {
    XCTAssertFalse([unmanaged.boolObj containsObject:@NO]);
    XCTAssertFalse([unmanaged.intObj containsObject:@2]);
    XCTAssertFalse([unmanaged.floatObj containsObject:@2.2f]);
    XCTAssertFalse([unmanaged.doubleObj containsObject:@2.2]);
    XCTAssertFalse([unmanaged.stringObj containsObject:@"a"]);
    XCTAssertFalse([unmanaged.dataObj containsObject:data(1)]);
    XCTAssertFalse([unmanaged.dateObj containsObject:date(1)]);
    XCTAssertFalse([unmanaged.decimalObj containsObject:decimal128(1)]);
    XCTAssertFalse([unmanaged.objectIdObj containsObject:objectId(1)]);
    XCTAssertFalse([unmanaged.uuidObj containsObject:uuid(@"00000000-0000-0000-0000-000000000000")]);
    XCTAssertFalse([optUnmanaged.boolObj containsObject:NSNull.null]);
    XCTAssertFalse([optUnmanaged.intObj containsObject:NSNull.null]);
    XCTAssertFalse([optUnmanaged.floatObj containsObject:NSNull.null]);
    XCTAssertFalse([optUnmanaged.doubleObj containsObject:NSNull.null]);
    XCTAssertFalse([optUnmanaged.stringObj containsObject:NSNull.null]);
    XCTAssertFalse([optUnmanaged.dataObj containsObject:NSNull.null]);
    XCTAssertFalse([optUnmanaged.dateObj containsObject:NSNull.null]);
    XCTAssertFalse([optUnmanaged.decimalObj containsObject:NSNull.null]);
    XCTAssertFalse([optUnmanaged.objectIdObj containsObject:NSNull.null]);
    XCTAssertFalse([optUnmanaged.uuidObj containsObject:NSNull.null]);
    XCTAssertFalse([managed.boolObj containsObject:@NO]);
    XCTAssertFalse([managed.intObj containsObject:@2]);
    XCTAssertFalse([managed.floatObj containsObject:@2.2f]);
    XCTAssertFalse([managed.doubleObj containsObject:@2.2]);
    XCTAssertFalse([managed.stringObj containsObject:@"a"]);
    XCTAssertFalse([managed.dataObj containsObject:data(1)]);
    XCTAssertFalse([managed.dateObj containsObject:date(1)]);
    XCTAssertFalse([managed.decimalObj containsObject:decimal128(1)]);
    XCTAssertFalse([managed.objectIdObj containsObject:objectId(1)]);
    XCTAssertFalse([managed.uuidObj containsObject:uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")]);
    XCTAssertFalse([optManaged.boolObj containsObject:NSNull.null]);
    XCTAssertFalse([optManaged.intObj containsObject:NSNull.null]);
    XCTAssertFalse([optManaged.floatObj containsObject:NSNull.null]);
    XCTAssertFalse([optManaged.doubleObj containsObject:NSNull.null]);
    XCTAssertFalse([optManaged.stringObj containsObject:NSNull.null]);
    XCTAssertFalse([optManaged.dataObj containsObject:NSNull.null]);
    XCTAssertFalse([optManaged.dateObj containsObject:NSNull.null]);
    XCTAssertFalse([optManaged.decimalObj containsObject:NSNull.null]);
    XCTAssertFalse([optManaged.objectIdObj containsObject:NSNull.null]);
    XCTAssertFalse([optManaged.uuidObj containsObject:NSNull.null]);
    [unmanaged.boolObj addObject:@NO];
    [unmanaged.intObj addObject:@2];
    [unmanaged.floatObj addObject:@2.2f];
    [unmanaged.doubleObj addObject:@2.2];
    [unmanaged.stringObj addObject:@"a"];
    [unmanaged.dataObj addObject:data(1)];
    [unmanaged.dateObj addObject:date(1)];
    [unmanaged.decimalObj addObject:decimal128(1)];
    [unmanaged.objectIdObj addObject:objectId(1)];
    [unmanaged.uuidObj addObject:uuid(@"00000000-0000-0000-0000-000000000000")];
    [optUnmanaged.boolObj addObject:NSNull.null];
    [optUnmanaged.intObj addObject:NSNull.null];
    [optUnmanaged.floatObj addObject:NSNull.null];
    [optUnmanaged.doubleObj addObject:NSNull.null];
    [optUnmanaged.stringObj addObject:NSNull.null];
    [optUnmanaged.dataObj addObject:NSNull.null];
    [optUnmanaged.dateObj addObject:NSNull.null];
    [optUnmanaged.decimalObj addObject:NSNull.null];
    [optUnmanaged.objectIdObj addObject:NSNull.null];
    [optUnmanaged.uuidObj addObject:NSNull.null];
    [managed.boolObj addObject:@NO];
    [managed.intObj addObject:@2];
    [managed.floatObj addObject:@2.2f];
    [managed.doubleObj addObject:@2.2];
    [managed.stringObj addObject:@"a"];
    [managed.dataObj addObject:data(1)];
    [managed.dateObj addObject:date(1)];
    [managed.decimalObj addObject:decimal128(1)];
    [managed.objectIdObj addObject:objectId(1)];
    [managed.uuidObj addObject:uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")];
    [optManaged.boolObj addObject:NSNull.null];
    [optManaged.intObj addObject:NSNull.null];
    [optManaged.floatObj addObject:NSNull.null];
    [optManaged.doubleObj addObject:NSNull.null];
    [optManaged.stringObj addObject:NSNull.null];
    [optManaged.dataObj addObject:NSNull.null];
    [optManaged.dateObj addObject:NSNull.null];
    [optManaged.decimalObj addObject:NSNull.null];
    [optManaged.objectIdObj addObject:NSNull.null];
    [optManaged.uuidObj addObject:NSNull.null];
    XCTAssertTrue([unmanaged.boolObj containsObject:@NO]);
    XCTAssertTrue([unmanaged.intObj containsObject:@2]);
    XCTAssertTrue([unmanaged.floatObj containsObject:@2.2f]);
    XCTAssertTrue([unmanaged.doubleObj containsObject:@2.2]);
    XCTAssertTrue([unmanaged.stringObj containsObject:@"a"]);
    XCTAssertTrue([unmanaged.dataObj containsObject:data(1)]);
    XCTAssertTrue([unmanaged.dateObj containsObject:date(1)]);
    XCTAssertTrue([unmanaged.decimalObj containsObject:decimal128(1)]);
    XCTAssertTrue([unmanaged.objectIdObj containsObject:objectId(1)]);
    XCTAssertTrue([unmanaged.uuidObj containsObject:uuid(@"00000000-0000-0000-0000-000000000000")]);
    XCTAssertTrue([optUnmanaged.boolObj containsObject:NSNull.null]);
    XCTAssertTrue([optUnmanaged.intObj containsObject:NSNull.null]);
    XCTAssertTrue([optUnmanaged.floatObj containsObject:NSNull.null]);
    XCTAssertTrue([optUnmanaged.doubleObj containsObject:NSNull.null]);
    XCTAssertTrue([optUnmanaged.stringObj containsObject:NSNull.null]);
    XCTAssertTrue([optUnmanaged.dataObj containsObject:NSNull.null]);
    XCTAssertTrue([optUnmanaged.dateObj containsObject:NSNull.null]);
    XCTAssertTrue([optUnmanaged.decimalObj containsObject:NSNull.null]);
    XCTAssertTrue([optUnmanaged.objectIdObj containsObject:NSNull.null]);
    XCTAssertTrue([optUnmanaged.uuidObj containsObject:NSNull.null]);
    XCTAssertTrue([managed.boolObj containsObject:@NO]);
    XCTAssertTrue([managed.intObj containsObject:@2]);
    XCTAssertTrue([managed.floatObj containsObject:@2.2f]);
    XCTAssertTrue([managed.doubleObj containsObject:@2.2]);
    XCTAssertTrue([managed.stringObj containsObject:@"a"]);
    XCTAssertTrue([managed.dataObj containsObject:data(1)]);
    XCTAssertTrue([managed.dateObj containsObject:date(1)]);
    XCTAssertTrue([managed.decimalObj containsObject:decimal128(1)]);
    XCTAssertTrue([managed.objectIdObj containsObject:objectId(1)]);
    XCTAssertTrue([managed.uuidObj containsObject:uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")]);
    XCTAssertTrue([optManaged.boolObj containsObject:NSNull.null]);
    XCTAssertTrue([optManaged.intObj containsObject:NSNull.null]);
    XCTAssertTrue([optManaged.floatObj containsObject:NSNull.null]);
    XCTAssertTrue([optManaged.doubleObj containsObject:NSNull.null]);
    XCTAssertTrue([optManaged.stringObj containsObject:NSNull.null]);
    XCTAssertTrue([optManaged.dataObj containsObject:NSNull.null]);
    XCTAssertTrue([optManaged.dateObj containsObject:NSNull.null]);
    XCTAssertTrue([optManaged.decimalObj containsObject:NSNull.null]);
    XCTAssertTrue([optManaged.objectIdObj containsObject:NSNull.null]);
    XCTAssertTrue([optManaged.uuidObj containsObject:NSNull.null]);
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
    RLMAssertThrowsWithReason([unmanaged.uuidObj addObject:@"a"], 
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'uuid'");
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
    RLMAssertThrowsWithReason([optUnmanaged.uuidObj addObject:@"a"], 
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'uuid?'");
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
    RLMAssertThrowsWithReason([managed.uuidObj addObject:@"a"], 
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'uuid'");
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
    RLMAssertThrowsWithReason([optManaged.uuidObj addObject:@"a"], 
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'uuid?'");
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
    RLMAssertThrowsWithReason([unmanaged.uuidObj addObject:NSNull.null], 
                              @"Invalid value '<null>' of type 'NSNull' for expected type 'uuid'");
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
    RLMAssertThrowsWithReason([managed.uuidObj addObject:NSNull.null], 
                              @"Invalid value '<null>' of type 'NSNull' for expected type 'uuid'");

    [unmanaged.boolObj addObject:@NO];
    [unmanaged.intObj addObject:@2];
    [unmanaged.floatObj addObject:@2.2f];
    [unmanaged.doubleObj addObject:@2.2];
    [unmanaged.stringObj addObject:@"a"];
    [unmanaged.dataObj addObject:data(1)];
    [unmanaged.dateObj addObject:date(1)];
    [unmanaged.decimalObj addObject:decimal128(1)];
    [unmanaged.objectIdObj addObject:objectId(1)];
    [unmanaged.uuidObj addObject:uuid(@"00000000-0000-0000-0000-000000000000")];
    [optUnmanaged.boolObj addObject:NSNull.null];
    [optUnmanaged.intObj addObject:NSNull.null];
    [optUnmanaged.floatObj addObject:NSNull.null];
    [optUnmanaged.doubleObj addObject:NSNull.null];
    [optUnmanaged.stringObj addObject:NSNull.null];
    [optUnmanaged.dataObj addObject:NSNull.null];
    [optUnmanaged.dateObj addObject:NSNull.null];
    [optUnmanaged.decimalObj addObject:NSNull.null];
    [optUnmanaged.objectIdObj addObject:NSNull.null];
    [optUnmanaged.uuidObj addObject:NSNull.null];
    [managed.boolObj addObject:@NO];
    [managed.intObj addObject:@2];
    [managed.floatObj addObject:@2.2f];
    [managed.doubleObj addObject:@2.2];
    [managed.stringObj addObject:@"a"];
    [managed.dataObj addObject:data(1)];
    [managed.dateObj addObject:date(1)];
    [managed.decimalObj addObject:decimal128(1)];
    [managed.objectIdObj addObject:objectId(1)];
    [managed.uuidObj addObject:uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")];
    [optManaged.boolObj addObject:NSNull.null];
    [optManaged.intObj addObject:NSNull.null];
    [optManaged.floatObj addObject:NSNull.null];
    [optManaged.doubleObj addObject:NSNull.null];
    [optManaged.stringObj addObject:NSNull.null];
    [optManaged.dataObj addObject:NSNull.null];
    [optManaged.dateObj addObject:NSNull.null];
    [optManaged.decimalObj addObject:NSNull.null];
    [optManaged.objectIdObj addObject:NSNull.null];
    [optManaged.uuidObj addObject:NSNull.null];
    XCTAssertTrue([unmanaged.boolObj containsObject:@NO]);
    XCTAssertTrue([unmanaged.intObj containsObject:@2]);
    XCTAssertTrue([unmanaged.floatObj containsObject:@2.2f]);
    XCTAssertTrue([unmanaged.doubleObj containsObject:@2.2]);
    XCTAssertTrue([unmanaged.stringObj containsObject:@"a"]);
    XCTAssertTrue([unmanaged.dataObj containsObject:data(1)]);
    XCTAssertTrue([unmanaged.dateObj containsObject:date(1)]);
    XCTAssertTrue([unmanaged.decimalObj containsObject:decimal128(1)]);
    XCTAssertTrue([unmanaged.objectIdObj containsObject:objectId(1)]);
    XCTAssertTrue([unmanaged.uuidObj containsObject:uuid(@"00000000-0000-0000-0000-000000000000")]);
    XCTAssertTrue([optUnmanaged.boolObj containsObject:NSNull.null]);
    XCTAssertTrue([optUnmanaged.intObj containsObject:NSNull.null]);
    XCTAssertTrue([optUnmanaged.floatObj containsObject:NSNull.null]);
    XCTAssertTrue([optUnmanaged.doubleObj containsObject:NSNull.null]);
    XCTAssertTrue([optUnmanaged.stringObj containsObject:NSNull.null]);
    XCTAssertTrue([optUnmanaged.dataObj containsObject:NSNull.null]);
    XCTAssertTrue([optUnmanaged.dateObj containsObject:NSNull.null]);
    XCTAssertTrue([optUnmanaged.decimalObj containsObject:NSNull.null]);
    XCTAssertTrue([optUnmanaged.objectIdObj containsObject:NSNull.null]);
    XCTAssertTrue([optUnmanaged.uuidObj containsObject:NSNull.null]);
    XCTAssertTrue([managed.boolObj containsObject:@NO]);
    XCTAssertTrue([managed.intObj containsObject:@2]);
    XCTAssertTrue([managed.floatObj containsObject:@2.2f]);
    XCTAssertTrue([managed.doubleObj containsObject:@2.2]);
    XCTAssertTrue([managed.stringObj containsObject:@"a"]);
    XCTAssertTrue([managed.dataObj containsObject:data(1)]);
    XCTAssertTrue([managed.dateObj containsObject:date(1)]);
    XCTAssertTrue([managed.decimalObj containsObject:decimal128(1)]);
    XCTAssertTrue([managed.objectIdObj containsObject:objectId(1)]);
    XCTAssertTrue([managed.uuidObj containsObject:uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")]);
    XCTAssertTrue([optManaged.boolObj containsObject:NSNull.null]);
    XCTAssertTrue([optManaged.intObj containsObject:NSNull.null]);
    XCTAssertTrue([optManaged.floatObj containsObject:NSNull.null]);
    XCTAssertTrue([optManaged.doubleObj containsObject:NSNull.null]);
    XCTAssertTrue([optManaged.stringObj containsObject:NSNull.null]);
    XCTAssertTrue([optManaged.dataObj containsObject:NSNull.null]);
    XCTAssertTrue([optManaged.dateObj containsObject:NSNull.null]);
    XCTAssertTrue([optManaged.decimalObj containsObject:NSNull.null]);
    XCTAssertTrue([optManaged.objectIdObj containsObject:NSNull.null]);
    XCTAssertTrue([optManaged.uuidObj containsObject:NSNull.null]);

    [optUnmanaged.boolObj addObject:NSNull.null];
    [optUnmanaged.intObj addObject:NSNull.null];
    [optUnmanaged.floatObj addObject:NSNull.null];
    [optUnmanaged.doubleObj addObject:NSNull.null];
    [optUnmanaged.stringObj addObject:NSNull.null];
    [optUnmanaged.dataObj addObject:NSNull.null];
    [optUnmanaged.dateObj addObject:NSNull.null];
    [optUnmanaged.decimalObj addObject:NSNull.null];
    [optUnmanaged.objectIdObj addObject:NSNull.null];
    [optUnmanaged.uuidObj addObject:NSNull.null];
    [optManaged.boolObj addObject:NSNull.null];
    [optManaged.intObj addObject:NSNull.null];
    [optManaged.floatObj addObject:NSNull.null];
    [optManaged.doubleObj addObject:NSNull.null];
    [optManaged.stringObj addObject:NSNull.null];
    [optManaged.dataObj addObject:NSNull.null];
    [optManaged.dateObj addObject:NSNull.null];
    [optManaged.decimalObj addObject:NSNull.null];
    [optManaged.objectIdObj addObject:NSNull.null];
    [optManaged.uuidObj addObject:NSNull.null];
    XCTAssertTrue([optUnmanaged.boolObj containsObject:NSNull.null]);
    XCTAssertTrue([optUnmanaged.intObj containsObject:NSNull.null]);
    XCTAssertTrue([optUnmanaged.floatObj containsObject:NSNull.null]);
    XCTAssertTrue([optUnmanaged.doubleObj containsObject:NSNull.null]);
    XCTAssertTrue([optUnmanaged.stringObj containsObject:NSNull.null]);
    XCTAssertTrue([optUnmanaged.dataObj containsObject:NSNull.null]);
    XCTAssertTrue([optUnmanaged.dateObj containsObject:NSNull.null]);
    XCTAssertTrue([optUnmanaged.decimalObj containsObject:NSNull.null]);
    XCTAssertTrue([optUnmanaged.objectIdObj containsObject:NSNull.null]);
    XCTAssertTrue([optUnmanaged.uuidObj containsObject:NSNull.null]);
    XCTAssertTrue([optManaged.boolObj containsObject:NSNull.null]);
    XCTAssertTrue([optManaged.intObj containsObject:NSNull.null]);
    XCTAssertTrue([optManaged.floatObj containsObject:NSNull.null]);
    XCTAssertTrue([optManaged.doubleObj containsObject:NSNull.null]);
    XCTAssertTrue([optManaged.stringObj containsObject:NSNull.null]);
    XCTAssertTrue([optManaged.dataObj containsObject:NSNull.null]);
    XCTAssertTrue([optManaged.dateObj containsObject:NSNull.null]);
    XCTAssertTrue([optManaged.decimalObj containsObject:NSNull.null]);
    XCTAssertTrue([optManaged.objectIdObj containsObject:NSNull.null]);
    XCTAssertTrue([optManaged.uuidObj containsObject:NSNull.null]);
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
    RLMAssertThrowsWithReason([unmanaged.uuidObj addObjects:@[@"a"]], 
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'uuid'");
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
    RLMAssertThrowsWithReason([optUnmanaged.uuidObj addObjects:@[@"a"]], 
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'uuid?'");
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
    RLMAssertThrowsWithReason([managed.uuidObj addObjects:@[@"a"]], 
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'uuid'");
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
    RLMAssertThrowsWithReason([optManaged.uuidObj addObjects:@[@"a"]], 
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'uuid?'");
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
    RLMAssertThrowsWithReason([unmanaged.uuidObj addObjects:@[NSNull.null]], 
                              @"Invalid value '<null>' of type 'NSNull' for expected type 'uuid'");
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
    RLMAssertThrowsWithReason([managed.uuidObj addObjects:@[NSNull.null]], 
                              @"Invalid value '<null>' of type 'NSNull' for expected type 'uuid'");

    [self addObjects];
    XCTAssertTrue([unmanaged.boolObj containsObject:@NO]);
    XCTAssertTrue([unmanaged.intObj containsObject:@2]);
    XCTAssertTrue([unmanaged.floatObj containsObject:@2.2f]);
    XCTAssertTrue([unmanaged.doubleObj containsObject:@2.2]);
    XCTAssertTrue([unmanaged.stringObj containsObject:@"a"]);
    XCTAssertTrue([unmanaged.dataObj containsObject:data(1)]);
    XCTAssertTrue([unmanaged.dateObj containsObject:date(1)]);
    XCTAssertTrue([unmanaged.decimalObj containsObject:decimal128(1)]);
    XCTAssertTrue([unmanaged.objectIdObj containsObject:objectId(1)]);
    XCTAssertTrue([unmanaged.uuidObj containsObject:uuid(@"00000000-0000-0000-0000-000000000000")]);
    XCTAssertTrue([optUnmanaged.boolObj containsObject:NSNull.null]);
    XCTAssertTrue([optUnmanaged.intObj containsObject:NSNull.null]);
    XCTAssertTrue([optUnmanaged.floatObj containsObject:NSNull.null]);
    XCTAssertTrue([optUnmanaged.doubleObj containsObject:NSNull.null]);
    XCTAssertTrue([optUnmanaged.stringObj containsObject:NSNull.null]);
    XCTAssertTrue([optUnmanaged.dataObj containsObject:NSNull.null]);
    XCTAssertTrue([optUnmanaged.dateObj containsObject:NSNull.null]);
    XCTAssertTrue([optUnmanaged.decimalObj containsObject:NSNull.null]);
    XCTAssertTrue([optUnmanaged.objectIdObj containsObject:NSNull.null]);
    XCTAssertTrue([optUnmanaged.uuidObj containsObject:NSNull.null]);
    XCTAssertTrue([managed.boolObj containsObject:@NO]);
    XCTAssertTrue([managed.intObj containsObject:@2]);
    XCTAssertTrue([managed.floatObj containsObject:@2.2f]);
    XCTAssertTrue([managed.doubleObj containsObject:@2.2]);
    XCTAssertTrue([managed.stringObj containsObject:@"a"]);
    XCTAssertTrue([managed.dataObj containsObject:data(1)]);
    XCTAssertTrue([managed.dateObj containsObject:date(1)]);
    XCTAssertTrue([managed.decimalObj containsObject:decimal128(1)]);
    XCTAssertTrue([managed.objectIdObj containsObject:objectId(1)]);
    XCTAssertTrue([managed.uuidObj containsObject:uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")]);
    XCTAssertTrue([optManaged.boolObj containsObject:NSNull.null]);
    XCTAssertTrue([optManaged.intObj containsObject:NSNull.null]);
    XCTAssertTrue([optManaged.floatObj containsObject:NSNull.null]);
    XCTAssertTrue([optManaged.doubleObj containsObject:NSNull.null]);
    XCTAssertTrue([optManaged.stringObj containsObject:NSNull.null]);
    XCTAssertTrue([optManaged.dataObj containsObject:NSNull.null]);
    XCTAssertTrue([optManaged.dateObj containsObject:NSNull.null]);
    XCTAssertTrue([optManaged.decimalObj containsObject:NSNull.null]);
    XCTAssertTrue([optManaged.objectIdObj containsObject:NSNull.null]);
    XCTAssertTrue([optManaged.uuidObj containsObject:NSNull.null]);
    XCTAssertTrue([unmanaged.boolObj containsObject:@YES]);
    XCTAssertTrue([unmanaged.intObj containsObject:@3]);
    XCTAssertTrue([unmanaged.floatObj containsObject:@3.3f]);
    XCTAssertTrue([unmanaged.doubleObj containsObject:@3.3]);
    XCTAssertTrue([unmanaged.stringObj containsObject:@"bc"]);
    XCTAssertTrue([unmanaged.dataObj containsObject:data(2)]);
    XCTAssertTrue([unmanaged.dateObj containsObject:date(2)]);
    XCTAssertTrue([unmanaged.decimalObj containsObject:decimal128(2)]);
    XCTAssertTrue([unmanaged.objectIdObj containsObject:objectId(2)]);
    XCTAssertTrue([unmanaged.uuidObj containsObject:uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")]);
    XCTAssertTrue([optUnmanaged.boolObj containsObject:@NO]);
    XCTAssertTrue([optUnmanaged.intObj containsObject:@2]);
    XCTAssertTrue([optUnmanaged.floatObj containsObject:@2.2f]);
    XCTAssertTrue([optUnmanaged.doubleObj containsObject:@2.2]);
    XCTAssertTrue([optUnmanaged.stringObj containsObject:@"a"]);
    XCTAssertTrue([optUnmanaged.dataObj containsObject:data(1)]);
    XCTAssertTrue([optUnmanaged.dateObj containsObject:date(1)]);
    XCTAssertTrue([optUnmanaged.decimalObj containsObject:decimal128(1)]);
    XCTAssertTrue([optUnmanaged.objectIdObj containsObject:objectId(1)]);
    XCTAssertTrue([optUnmanaged.uuidObj containsObject:uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")]);
    XCTAssertTrue([managed.boolObj containsObject:@YES]);
    XCTAssertTrue([managed.intObj containsObject:@3]);
    XCTAssertTrue([managed.floatObj containsObject:@3.3f]);
    XCTAssertTrue([managed.doubleObj containsObject:@3.3]);
    XCTAssertTrue([managed.stringObj containsObject:@"bc"]);
    XCTAssertTrue([managed.dataObj containsObject:data(2)]);
    XCTAssertTrue([managed.dateObj containsObject:date(2)]);
    XCTAssertTrue([managed.decimalObj containsObject:decimal128(2)]);
    XCTAssertTrue([managed.objectIdObj containsObject:objectId(2)]);
    XCTAssertTrue([managed.uuidObj containsObject:uuid(@"00000000-0000-0000-0000-000000000000")]);
    XCTAssertTrue([optManaged.boolObj containsObject:@NO]);
    XCTAssertTrue([optManaged.intObj containsObject:@2]);
    XCTAssertTrue([optManaged.floatObj containsObject:@2.2f]);
    XCTAssertTrue([optManaged.doubleObj containsObject:@2.2]);
    XCTAssertTrue([optManaged.stringObj containsObject:@"a"]);
    XCTAssertTrue([optManaged.dataObj containsObject:data(1)]);
    XCTAssertTrue([optManaged.dateObj containsObject:date(1)]);
    XCTAssertTrue([optManaged.decimalObj containsObject:decimal128(1)]);
    XCTAssertTrue([optManaged.objectIdObj containsObject:objectId(1)]);
    XCTAssertTrue([optManaged.uuidObj containsObject:uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")]);
    XCTAssertTrue([optUnmanaged.boolObj containsObject:@YES]);
    XCTAssertTrue([optUnmanaged.intObj containsObject:@3]);
    XCTAssertTrue([optUnmanaged.floatObj containsObject:@3.3f]);
    XCTAssertTrue([optUnmanaged.doubleObj containsObject:@3.3]);
    XCTAssertTrue([optUnmanaged.stringObj containsObject:@"bc"]);
    XCTAssertTrue([optUnmanaged.dataObj containsObject:data(2)]);
    XCTAssertTrue([optUnmanaged.dateObj containsObject:date(2)]);
    XCTAssertTrue([optUnmanaged.decimalObj containsObject:decimal128(2)]);
    XCTAssertTrue([optUnmanaged.objectIdObj containsObject:objectId(2)]);
    XCTAssertTrue([optUnmanaged.uuidObj containsObject:uuid(@"00000000-0000-0000-0000-000000000000")]);
    XCTAssertTrue([optManaged.boolObj containsObject:@YES]);
    XCTAssertTrue([optManaged.intObj containsObject:@3]);
    XCTAssertTrue([optManaged.floatObj containsObject:@3.3f]);
    XCTAssertTrue([optManaged.doubleObj containsObject:@3.3]);
    XCTAssertTrue([optManaged.stringObj containsObject:@"bc"]);
    XCTAssertTrue([optManaged.dataObj containsObject:data(2)]);
    XCTAssertTrue([optManaged.dateObj containsObject:date(2)]);
    XCTAssertTrue([optManaged.decimalObj containsObject:decimal128(2)]);
    XCTAssertTrue([optManaged.objectIdObj containsObject:objectId(2)]);
    XCTAssertTrue([optManaged.uuidObj containsObject:uuid(@"00000000-0000-0000-0000-000000000000")]);
}

- (void)testRemoveObject {
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
    XCTAssertEqual(unmanaged.uuidObj.count, 2U);
    XCTAssertEqual(managed.boolObj.count, 2U);
    XCTAssertEqual(managed.intObj.count, 2U);
    XCTAssertEqual(managed.floatObj.count, 2U);
    XCTAssertEqual(managed.doubleObj.count, 2U);
    XCTAssertEqual(managed.stringObj.count, 2U);
    XCTAssertEqual(managed.dataObj.count, 2U);
    XCTAssertEqual(managed.dateObj.count, 2U);
    XCTAssertEqual(managed.decimalObj.count, 2U);
    XCTAssertEqual(managed.objectIdObj.count, 2U);
    XCTAssertEqual(managed.uuidObj.count, 2U);
    XCTAssertEqual(optUnmanaged.boolObj.count, 3U);
    XCTAssertEqual(optUnmanaged.intObj.count, 3U);
    XCTAssertEqual(optUnmanaged.floatObj.count, 3U);
    XCTAssertEqual(optUnmanaged.doubleObj.count, 3U);
    XCTAssertEqual(optUnmanaged.stringObj.count, 3U);
    XCTAssertEqual(optUnmanaged.dataObj.count, 3U);
    XCTAssertEqual(optUnmanaged.dateObj.count, 3U);
    XCTAssertEqual(optUnmanaged.decimalObj.count, 3U);
    XCTAssertEqual(optUnmanaged.objectIdObj.count, 3U);
    XCTAssertEqual(optUnmanaged.uuidObj.count, 3U);
    XCTAssertEqual(optManaged.boolObj.count, 3U);
    XCTAssertEqual(optManaged.intObj.count, 3U);
    XCTAssertEqual(optManaged.floatObj.count, 3U);
    XCTAssertEqual(optManaged.doubleObj.count, 3U);
    XCTAssertEqual(optManaged.stringObj.count, 3U);
    XCTAssertEqual(optManaged.dataObj.count, 3U);
    XCTAssertEqual(optManaged.dateObj.count, 3U);
    XCTAssertEqual(optManaged.decimalObj.count, 3U);
    XCTAssertEqual(optManaged.objectIdObj.count, 3U);
    XCTAssertEqual(optManaged.uuidObj.count, 3U);

    for (RLMSet *set in allSets) {
        [set removeObject:set.allObjects[0]];
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
    XCTAssertEqual(unmanaged.uuidObj.count, 1U);
    XCTAssertEqual(managed.boolObj.count, 1U);
    XCTAssertEqual(managed.intObj.count, 1U);
    XCTAssertEqual(managed.floatObj.count, 1U);
    XCTAssertEqual(managed.doubleObj.count, 1U);
    XCTAssertEqual(managed.stringObj.count, 1U);
    XCTAssertEqual(managed.dataObj.count, 1U);
    XCTAssertEqual(managed.dateObj.count, 1U);
    XCTAssertEqual(managed.decimalObj.count, 1U);
    XCTAssertEqual(managed.objectIdObj.count, 1U);
    XCTAssertEqual(managed.uuidObj.count, 1U);
    XCTAssertEqual(optUnmanaged.boolObj.count, 2U);
    XCTAssertEqual(optUnmanaged.intObj.count, 2U);
    XCTAssertEqual(optUnmanaged.floatObj.count, 2U);
    XCTAssertEqual(optUnmanaged.doubleObj.count, 2U);
    XCTAssertEqual(optUnmanaged.stringObj.count, 2U);
    XCTAssertEqual(optUnmanaged.dataObj.count, 2U);
    XCTAssertEqual(optUnmanaged.dateObj.count, 2U);
    XCTAssertEqual(optUnmanaged.decimalObj.count, 2U);
    XCTAssertEqual(optUnmanaged.objectIdObj.count, 2U);
    XCTAssertEqual(optUnmanaged.uuidObj.count, 2U);
    XCTAssertEqual(optManaged.boolObj.count, 2U);
    XCTAssertEqual(optManaged.intObj.count, 2U);
    XCTAssertEqual(optManaged.floatObj.count, 2U);
    XCTAssertEqual(optManaged.doubleObj.count, 2U);
    XCTAssertEqual(optManaged.stringObj.count, 2U);
    XCTAssertEqual(optManaged.dataObj.count, 2U);
    XCTAssertEqual(optManaged.dateObj.count, 2U);
    XCTAssertEqual(optManaged.decimalObj.count, 2U);
    XCTAssertEqual(optManaged.objectIdObj.count, 2U);
    XCTAssertEqual(optManaged.uuidObj.count, 2U);
}

- (void)testIndexOfObjectSorted {
    [managed.boolObj addObjects:@[@NO, @YES, @NO, @YES]];
    [managed.intObj addObjects:@[@2, @3, @2, @3]];
    [managed.floatObj addObjects:@[@2.2f, @3.3f, @2.2f, @3.3f]];
    [managed.doubleObj addObjects:@[@2.2, @3.3, @2.2, @3.3]];
    [managed.stringObj addObjects:@[@"a", @"bc", @"a", @"bc"]];
    [managed.dataObj addObjects:@[data(1), data(2), data(1), data(2)]];
    [managed.dateObj addObjects:@[date(1), date(2), date(1), date(2)]];
    [managed.decimalObj addObjects:@[decimal128(1), decimal128(2), decimal128(1), decimal128(2)]];
    [managed.objectIdObj addObjects:@[objectId(1), objectId(2), objectId(1), objectId(2)]];
    [managed.uuidObj addObjects:@[uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"), uuid(@"00000000-0000-0000-0000-000000000000"), uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"), uuid(@"00000000-0000-0000-0000-000000000000")]];
    [optManaged.boolObj addObjects:@[NSNull.null, @NO, NSNull.null, @NO, NSNull.null]];
    [optManaged.intObj addObjects:@[NSNull.null, @2, NSNull.null, @2, NSNull.null]];
    [optManaged.floatObj addObjects:@[NSNull.null, @2.2f, NSNull.null, @2.2f, NSNull.null]];
    [optManaged.doubleObj addObjects:@[NSNull.null, @2.2, NSNull.null, @2.2, NSNull.null]];
    [optManaged.stringObj addObjects:@[NSNull.null, @"a", NSNull.null, @"a", NSNull.null]];
    [optManaged.dataObj addObjects:@[NSNull.null, data(1), NSNull.null, data(1), NSNull.null]];
    [optManaged.dateObj addObjects:@[NSNull.null, date(1), NSNull.null, date(1), NSNull.null]];
    [optManaged.decimalObj addObjects:@[NSNull.null, decimal128(1), NSNull.null, decimal128(1), NSNull.null]];
    [optManaged.objectIdObj addObjects:@[NSNull.null, objectId(1), NSNull.null, objectId(1), NSNull.null]];
    [optManaged.uuidObj addObjects:@[NSNull.null, uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"), NSNull.null, uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"), NSNull.null]];
    // ordering can't be guaranteed in set, so just verify the indexes are between 0 and 1
    XCTAssertTrue([[managed.boolObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:@YES] == 0U || 
                  [[managed.boolObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:@YES] == 1U);
    XCTAssertTrue([[managed.intObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:@3] == 0U || 
                  [[managed.intObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:@3] == 1U);
    XCTAssertTrue([[managed.floatObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:@3.3f] == 0U || 
                  [[managed.floatObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:@3.3f] == 1U);
    XCTAssertTrue([[managed.doubleObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:@3.3] == 0U || 
                  [[managed.doubleObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:@3.3] == 1U);
    XCTAssertTrue([[managed.stringObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:@"bc"] == 0U || 
                  [[managed.stringObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:@"bc"] == 1U);
    XCTAssertTrue([[managed.dataObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:data(2)] == 0U || 
                  [[managed.dataObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:data(2)] == 1U);
    XCTAssertTrue([[managed.dateObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:date(2)] == 0U || 
                  [[managed.dateObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:date(2)] == 1U);
    XCTAssertTrue([[managed.decimalObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:decimal128(2)] == 0U || 
                  [[managed.decimalObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:decimal128(2)] == 1U);
    XCTAssertTrue([[managed.objectIdObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:objectId(2)] == 0U || 
                  [[managed.objectIdObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:objectId(2)] == 1U);
    XCTAssertTrue([[managed.uuidObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:uuid(@"00000000-0000-0000-0000-000000000000")] == 0U || 
                  [[managed.uuidObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:uuid(@"00000000-0000-0000-0000-000000000000")] == 1U);
    XCTAssertTrue([[managed.boolObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:@NO] == 0U || 
                  [[managed.boolObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:@NO] == 1U);
    XCTAssertTrue([[managed.intObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:@2] == 0U || 
                  [[managed.intObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:@2] == 1U);
    XCTAssertTrue([[managed.floatObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:@2.2f] == 0U || 
                  [[managed.floatObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:@2.2f] == 1U);
    XCTAssertTrue([[managed.doubleObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:@2.2] == 0U || 
                  [[managed.doubleObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:@2.2] == 1U);
    XCTAssertTrue([[managed.stringObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:@"a"] == 0U || 
                  [[managed.stringObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:@"a"] == 1U);
    XCTAssertTrue([[managed.dataObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:data(1)] == 0U || 
                  [[managed.dataObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:data(1)] == 1U);
    XCTAssertTrue([[managed.dateObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:date(1)] == 0U || 
                  [[managed.dateObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:date(1)] == 1U);
    XCTAssertTrue([[managed.decimalObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:decimal128(1)] == 0U || 
                  [[managed.decimalObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:decimal128(1)] == 1U);
    XCTAssertTrue([[managed.objectIdObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:objectId(1)] == 0U || 
                  [[managed.objectIdObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:objectId(1)] == 1U);
    XCTAssertTrue([[managed.uuidObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")] == 0U || 
                  [[managed.uuidObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")] == 1U);

    XCTAssertTrue([[optManaged.boolObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:@NO] == 0U || 
                  [[optManaged.boolObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:@NO] == 1U);
    XCTAssertTrue([[optManaged.intObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:@2] == 0U || 
                  [[optManaged.intObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:@2] == 1U);
    XCTAssertTrue([[optManaged.floatObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:@2.2f] == 0U || 
                  [[optManaged.floatObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:@2.2f] == 1U);
    XCTAssertTrue([[optManaged.doubleObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:@2.2] == 0U || 
                  [[optManaged.doubleObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:@2.2] == 1U);
    XCTAssertTrue([[optManaged.stringObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:@"a"] == 0U || 
                  [[optManaged.stringObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:@"a"] == 1U);
    XCTAssertTrue([[optManaged.dataObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:data(1)] == 0U || 
                  [[optManaged.dataObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:data(1)] == 1U);
    XCTAssertTrue([[optManaged.dateObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:date(1)] == 0U || 
                  [[optManaged.dateObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:date(1)] == 1U);
    XCTAssertTrue([[optManaged.decimalObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:decimal128(1)] == 0U || 
                  [[optManaged.decimalObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:decimal128(1)] == 1U);
    XCTAssertTrue([[optManaged.objectIdObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:objectId(1)] == 0U || 
                  [[optManaged.objectIdObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:objectId(1)] == 1U);
    XCTAssertTrue([[optManaged.uuidObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")] == 0U || 
                  [[optManaged.uuidObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")] == 1U);
    XCTAssertTrue([[optManaged.boolObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:NSNull.null] == 0U || 
                  [[optManaged.boolObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:NSNull.null] == 1U);
    XCTAssertTrue([[optManaged.intObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:NSNull.null] == 0U || 
                  [[optManaged.intObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:NSNull.null] == 1U);
    XCTAssertTrue([[optManaged.floatObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:NSNull.null] == 0U || 
                  [[optManaged.floatObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:NSNull.null] == 1U);
    XCTAssertTrue([[optManaged.doubleObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:NSNull.null] == 0U || 
                  [[optManaged.doubleObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:NSNull.null] == 1U);
    XCTAssertTrue([[optManaged.stringObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:NSNull.null] == 0U || 
                  [[optManaged.stringObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:NSNull.null] == 1U);
    XCTAssertTrue([[optManaged.dataObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:NSNull.null] == 0U || 
                  [[optManaged.dataObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:NSNull.null] == 1U);
    XCTAssertTrue([[optManaged.dateObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:NSNull.null] == 0U || 
                  [[optManaged.dateObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:NSNull.null] == 1U);
    XCTAssertTrue([[optManaged.decimalObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:NSNull.null] == 0U || 
                  [[optManaged.decimalObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:NSNull.null] == 1U);
    XCTAssertTrue([[optManaged.objectIdObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:NSNull.null] == 0U || 
                  [[optManaged.objectIdObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:NSNull.null] == 1U);
    XCTAssertTrue([[optManaged.uuidObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:NSNull.null] == 0U || 
                  [[optManaged.uuidObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:NSNull.null] == 1U);
}

- (void)testIndexOfObjectDistinct {
    [managed.boolObj addObjects:@[@NO, @NO, @YES]];
    [managed.intObj addObjects:@[@2, @2, @3]];
    [managed.floatObj addObjects:@[@2.2f, @2.2f, @3.3f]];
    [managed.doubleObj addObjects:@[@2.2, @2.2, @3.3]];
    [managed.stringObj addObjects:@[@"a", @"a", @"bc"]];
    [managed.dataObj addObjects:@[data(1), data(1), data(2)]];
    [managed.dateObj addObjects:@[date(1), date(1), date(2)]];
    [managed.decimalObj addObjects:@[decimal128(1), decimal128(1), decimal128(2)]];
    [managed.objectIdObj addObjects:@[objectId(1), objectId(1), objectId(2)]];
    [managed.uuidObj addObjects:@[uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"), uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"), uuid(@"00000000-0000-0000-0000-000000000000")]];
    [optManaged.boolObj addObjects:@[NSNull.null, NSNull.null, NSNull.null, @NO, NSNull.null]];
    [optManaged.intObj addObjects:@[NSNull.null, NSNull.null, NSNull.null, @2, NSNull.null]];
    [optManaged.floatObj addObjects:@[NSNull.null, NSNull.null, NSNull.null, @2.2f, NSNull.null]];
    [optManaged.doubleObj addObjects:@[NSNull.null, NSNull.null, NSNull.null, @2.2, NSNull.null]];
    [optManaged.stringObj addObjects:@[NSNull.null, NSNull.null, NSNull.null, @"a", NSNull.null]];
    [optManaged.dataObj addObjects:@[NSNull.null, NSNull.null, NSNull.null, data(1), NSNull.null]];
    [optManaged.dateObj addObjects:@[NSNull.null, NSNull.null, NSNull.null, date(1), NSNull.null]];
    [optManaged.decimalObj addObjects:@[NSNull.null, NSNull.null, NSNull.null, decimal128(1), NSNull.null]];
    [optManaged.objectIdObj addObjects:@[NSNull.null, NSNull.null, NSNull.null, objectId(1), NSNull.null]];
    [optManaged.uuidObj addObjects:@[NSNull.null, NSNull.null, NSNull.null, uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"), NSNull.null]];
    // ordering can't be guaranteed in set, so just verify the indexes are between 0 and 1
    XCTAssertTrue([[managed.boolObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:@NO] == 0U || 
                  [[managed.boolObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:@NO] == 1U);
    XCTAssertTrue([[managed.intObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:@2] == 0U || 
                  [[managed.intObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:@2] == 1U);
    XCTAssertTrue([[managed.floatObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:@2.2f] == 0U || 
                  [[managed.floatObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:@2.2f] == 1U);
    XCTAssertTrue([[managed.doubleObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:@2.2] == 0U || 
                  [[managed.doubleObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:@2.2] == 1U);
    XCTAssertTrue([[managed.stringObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:@"a"] == 0U || 
                  [[managed.stringObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:@"a"] == 1U);
    XCTAssertTrue([[managed.dataObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:data(1)] == 0U || 
                  [[managed.dataObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:data(1)] == 1U);
    XCTAssertTrue([[managed.dateObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:date(1)] == 0U || 
                  [[managed.dateObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:date(1)] == 1U);
    XCTAssertTrue([[managed.decimalObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:decimal128(1)] == 0U || 
                  [[managed.decimalObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:decimal128(1)] == 1U);
    XCTAssertTrue([[managed.objectIdObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:objectId(1)] == 0U || 
                  [[managed.objectIdObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:objectId(1)] == 1U);
    XCTAssertTrue([[managed.uuidObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")] == 0U || 
                  [[managed.uuidObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")] == 1U);
    XCTAssertTrue([[managed.boolObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:@YES] == 0U || 
                  [[managed.boolObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:@YES] == 1U);
    XCTAssertTrue([[managed.intObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:@3] == 0U || 
                  [[managed.intObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:@3] == 1U);
    XCTAssertTrue([[managed.floatObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:@3.3f] == 0U || 
                  [[managed.floatObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:@3.3f] == 1U);
    XCTAssertTrue([[managed.doubleObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:@3.3] == 0U || 
                  [[managed.doubleObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:@3.3] == 1U);
    XCTAssertTrue([[managed.stringObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:@"bc"] == 0U || 
                  [[managed.stringObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:@"bc"] == 1U);
    XCTAssertTrue([[managed.dataObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:data(2)] == 0U || 
                  [[managed.dataObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:data(2)] == 1U);
    XCTAssertTrue([[managed.dateObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:date(2)] == 0U || 
                  [[managed.dateObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:date(2)] == 1U);
    XCTAssertTrue([[managed.decimalObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:decimal128(2)] == 0U || 
                  [[managed.decimalObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:decimal128(2)] == 1U);
    XCTAssertTrue([[managed.objectIdObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:objectId(2)] == 0U || 
                  [[managed.objectIdObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:objectId(2)] == 1U);
    XCTAssertTrue([[managed.uuidObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:uuid(@"00000000-0000-0000-0000-000000000000")] == 0U || 
                  [[managed.uuidObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:uuid(@"00000000-0000-0000-0000-000000000000")] == 1U);

    XCTAssertTrue([[optManaged.boolObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:NSNull.null] == 0U || 
                  [[optManaged.boolObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:NSNull.null] == 1U);
    XCTAssertTrue([[optManaged.intObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:NSNull.null] == 0U || 
                  [[optManaged.intObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:NSNull.null] == 1U);
    XCTAssertTrue([[optManaged.floatObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:NSNull.null] == 0U || 
                  [[optManaged.floatObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:NSNull.null] == 1U);
    XCTAssertTrue([[optManaged.doubleObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:NSNull.null] == 0U || 
                  [[optManaged.doubleObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:NSNull.null] == 1U);
    XCTAssertTrue([[optManaged.stringObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:NSNull.null] == 0U || 
                  [[optManaged.stringObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:NSNull.null] == 1U);
    XCTAssertTrue([[optManaged.dataObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:NSNull.null] == 0U || 
                  [[optManaged.dataObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:NSNull.null] == 1U);
    XCTAssertTrue([[optManaged.dateObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:NSNull.null] == 0U || 
                  [[optManaged.dateObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:NSNull.null] == 1U);
    XCTAssertTrue([[optManaged.decimalObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:NSNull.null] == 0U || 
                  [[optManaged.decimalObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:NSNull.null] == 1U);
    XCTAssertTrue([[optManaged.objectIdObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:NSNull.null] == 0U || 
                  [[optManaged.objectIdObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:NSNull.null] == 1U);
    XCTAssertTrue([[optManaged.uuidObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:NSNull.null] == 0U || 
                  [[optManaged.uuidObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:NSNull.null] == 1U);
    XCTAssertTrue([[optManaged.boolObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:@NO] == 0U || 
                  [[optManaged.boolObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:@NO] == 1U);
    XCTAssertTrue([[optManaged.intObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:@2] == 0U || 
                  [[optManaged.intObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:@2] == 1U);
    XCTAssertTrue([[optManaged.floatObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:@2.2f] == 0U || 
                  [[optManaged.floatObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:@2.2f] == 1U);
    XCTAssertTrue([[optManaged.doubleObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:@2.2] == 0U || 
                  [[optManaged.doubleObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:@2.2] == 1U);
    XCTAssertTrue([[optManaged.stringObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:@"a"] == 0U || 
                  [[optManaged.stringObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:@"a"] == 1U);
    XCTAssertTrue([[optManaged.dataObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:data(1)] == 0U || 
                  [[optManaged.dataObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:data(1)] == 1U);
    XCTAssertTrue([[optManaged.dateObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:date(1)] == 0U || 
                  [[optManaged.dateObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:date(1)] == 1U);
    XCTAssertTrue([[optManaged.decimalObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:decimal128(1)] == 0U || 
                  [[optManaged.decimalObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:decimal128(1)] == 1U);
    XCTAssertTrue([[optManaged.objectIdObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:objectId(1)] == 0U || 
                  [[optManaged.objectIdObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:objectId(1)] == 1U);
    XCTAssertTrue([[optManaged.uuidObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")] == 0U || 
                  [[optManaged.uuidObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")] == 1U);
    XCTAssertTrue([[optManaged.boolObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:NSNull.null] == 0U || 
                  [[optManaged.boolObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:NSNull.null] == 1U);
    XCTAssertTrue([[optManaged.intObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:NSNull.null] == 0U || 
                  [[optManaged.intObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:NSNull.null] == 1U);
    XCTAssertTrue([[optManaged.floatObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:NSNull.null] == 0U || 
                  [[optManaged.floatObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:NSNull.null] == 1U);
    XCTAssertTrue([[optManaged.doubleObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:NSNull.null] == 0U || 
                  [[optManaged.doubleObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:NSNull.null] == 1U);
    XCTAssertTrue([[optManaged.stringObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:NSNull.null] == 0U || 
                  [[optManaged.stringObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:NSNull.null] == 1U);
    XCTAssertTrue([[optManaged.dataObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:NSNull.null] == 0U || 
                  [[optManaged.dataObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:NSNull.null] == 1U);
    XCTAssertTrue([[optManaged.dateObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:NSNull.null] == 0U || 
                  [[optManaged.dateObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:NSNull.null] == 1U);
    XCTAssertTrue([[optManaged.decimalObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:NSNull.null] == 0U || 
                  [[optManaged.decimalObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:NSNull.null] == 1U);
    XCTAssertTrue([[optManaged.objectIdObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:NSNull.null] == 0U || 
                  [[optManaged.objectIdObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:NSNull.null] == 1U);
    XCTAssertTrue([[optManaged.uuidObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:NSNull.null] == 0U || 
                  [[optManaged.uuidObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:NSNull.null] == 1U);
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
    RLMAssertThrowsWithReason([unmanaged.uuidObj sortedResultsUsingKeyPath:@"self" ascending:NO], 
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
    RLMAssertThrowsWithReason([optUnmanaged.uuidObj sortedResultsUsingKeyPath:@"self" ascending:NO], 
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
    RLMAssertThrowsWithReason([unmanaged.uuidObj sortedResultsUsingDescriptors:@[]], 
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
    RLMAssertThrowsWithReason([optUnmanaged.uuidObj sortedResultsUsingDescriptors:@[]], 
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
    RLMAssertThrowsWithReason([managed.uuidObj sortedResultsUsingKeyPath:@"not self" ascending:NO], 
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
    RLMAssertThrowsWithReason([optManaged.uuidObj sortedResultsUsingKeyPath:@"not self" ascending:NO], 
                              @"can only be sorted on 'self'");

    [managed.boolObj addObjects:@[@NO, @YES, @NO]];
    [managed.intObj addObjects:@[@2, @3, @2]];
    [managed.floatObj addObjects:@[@2.2f, @3.3f, @2.2f]];
    [managed.doubleObj addObjects:@[@2.2, @3.3, @2.2]];
    [managed.stringObj addObjects:@[@"a", @"bc", @"a"]];
    [managed.dataObj addObjects:@[data(1), data(2), data(1)]];
    [managed.dateObj addObjects:@[date(1), date(2), date(1)]];
    [managed.decimalObj addObjects:@[decimal128(1), decimal128(2), decimal128(1)]];
    [managed.objectIdObj addObjects:@[objectId(1), objectId(2), objectId(1)]];
    [managed.uuidObj addObjects:@[uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"), uuid(@"00000000-0000-0000-0000-000000000000"), uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")]];
    [optManaged.boolObj addObjects:@[NSNull.null, @NO, NSNull.null, @NO, NSNull.null]];
    [optManaged.intObj addObjects:@[NSNull.null, @2, NSNull.null, @2, NSNull.null]];
    [optManaged.floatObj addObjects:@[NSNull.null, @2.2f, NSNull.null, @2.2f, NSNull.null]];
    [optManaged.doubleObj addObjects:@[NSNull.null, @2.2, NSNull.null, @2.2, NSNull.null]];
    [optManaged.stringObj addObjects:@[NSNull.null, @"a", NSNull.null, @"a", NSNull.null]];
    [optManaged.dataObj addObjects:@[NSNull.null, data(1), NSNull.null, data(1), NSNull.null]];
    [optManaged.dateObj addObjects:@[NSNull.null, date(1), NSNull.null, date(1), NSNull.null]];
    [optManaged.decimalObj addObjects:@[NSNull.null, decimal128(1), NSNull.null, decimal128(1), NSNull.null]];
    [optManaged.objectIdObj addObjects:@[NSNull.null, objectId(1), NSNull.null, objectId(1), NSNull.null]];
    [optManaged.uuidObj addObjects:@[NSNull.null, uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"), NSNull.null, uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"), NSNull.null]];

    XCTAssertEqualObjects([NSSet setWithArray:[[[managed.boolObj sortedResultsUsingDescriptors:@[]] valueForKey:@"self"] allObjects]], 
                          ([NSSet setWithArray:@[@NO, @YES]]));
    XCTAssertEqualObjects([NSSet setWithArray:[[[managed.intObj sortedResultsUsingDescriptors:@[]] valueForKey:@"self"] allObjects]], 
                          ([NSSet setWithArray:@[@2, @3]]));
    XCTAssertEqualObjects([NSSet setWithArray:[[[managed.floatObj sortedResultsUsingDescriptors:@[]] valueForKey:@"self"] allObjects]], 
                          ([NSSet setWithArray:@[@2.2f, @3.3f]]));
    XCTAssertEqualObjects([NSSet setWithArray:[[[managed.doubleObj sortedResultsUsingDescriptors:@[]] valueForKey:@"self"] allObjects]], 
                          ([NSSet setWithArray:@[@2.2, @3.3]]));
    XCTAssertEqualObjects([NSSet setWithArray:[[[managed.stringObj sortedResultsUsingDescriptors:@[]] valueForKey:@"self"] allObjects]], 
                          ([NSSet setWithArray:@[@"a", @"bc"]]));
    XCTAssertEqualObjects([NSSet setWithArray:[[[managed.dataObj sortedResultsUsingDescriptors:@[]] valueForKey:@"self"] allObjects]], 
                          ([NSSet setWithArray:@[data(1), data(2)]]));
    XCTAssertEqualObjects([NSSet setWithArray:[[[managed.dateObj sortedResultsUsingDescriptors:@[]] valueForKey:@"self"] allObjects]], 
                          ([NSSet setWithArray:@[date(1), date(2)]]));
    XCTAssertEqualObjects([NSSet setWithArray:[[[managed.decimalObj sortedResultsUsingDescriptors:@[]] valueForKey:@"self"] allObjects]], 
                          ([NSSet setWithArray:@[decimal128(1), decimal128(2)]]));
    XCTAssertEqualObjects([NSSet setWithArray:[[[managed.objectIdObj sortedResultsUsingDescriptors:@[]] valueForKey:@"self"] allObjects]], 
                          ([NSSet setWithArray:@[objectId(1), objectId(2)]]));
    XCTAssertEqualObjects([NSSet setWithArray:[[[managed.uuidObj sortedResultsUsingDescriptors:@[]] valueForKey:@"self"] allObjects]], 
                          ([NSSet setWithArray:@[uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"), uuid(@"00000000-0000-0000-0000-000000000000")]]));
    XCTAssertEqualObjects([NSSet setWithArray:[[[optManaged.boolObj sortedResultsUsingDescriptors:@[]] valueForKey:@"self"] allObjects]], 
                          ([NSSet setWithArray:@[NSNull.null, @NO]]));
    XCTAssertEqualObjects([NSSet setWithArray:[[[optManaged.intObj sortedResultsUsingDescriptors:@[]] valueForKey:@"self"] allObjects]], 
                          ([NSSet setWithArray:@[NSNull.null, @2]]));
    XCTAssertEqualObjects([NSSet setWithArray:[[[optManaged.floatObj sortedResultsUsingDescriptors:@[]] valueForKey:@"self"] allObjects]], 
                          ([NSSet setWithArray:@[NSNull.null, @2.2f]]));
    XCTAssertEqualObjects([NSSet setWithArray:[[[optManaged.doubleObj sortedResultsUsingDescriptors:@[]] valueForKey:@"self"] allObjects]], 
                          ([NSSet setWithArray:@[NSNull.null, @2.2]]));
    XCTAssertEqualObjects([NSSet setWithArray:[[[optManaged.stringObj sortedResultsUsingDescriptors:@[]] valueForKey:@"self"] allObjects]], 
                          ([NSSet setWithArray:@[NSNull.null, @"a"]]));
    XCTAssertEqualObjects([NSSet setWithArray:[[[optManaged.dataObj sortedResultsUsingDescriptors:@[]] valueForKey:@"self"] allObjects]], 
                          ([NSSet setWithArray:@[NSNull.null, data(1)]]));
    XCTAssertEqualObjects([NSSet setWithArray:[[[optManaged.dateObj sortedResultsUsingDescriptors:@[]] valueForKey:@"self"] allObjects]], 
                          ([NSSet setWithArray:@[NSNull.null, date(1)]]));
    XCTAssertEqualObjects([NSSet setWithArray:[[[optManaged.decimalObj sortedResultsUsingDescriptors:@[]] valueForKey:@"self"] allObjects]], 
                          ([NSSet setWithArray:@[NSNull.null, decimal128(1)]]));
    XCTAssertEqualObjects([NSSet setWithArray:[[[optManaged.objectIdObj sortedResultsUsingDescriptors:@[]] valueForKey:@"self"] allObjects]], 
                          ([NSSet setWithArray:@[NSNull.null, objectId(1)]]));
    XCTAssertEqualObjects([NSSet setWithArray:[[[optManaged.uuidObj sortedResultsUsingDescriptors:@[]] valueForKey:@"self"] allObjects]], 
                          ([NSSet setWithArray:@[NSNull.null, uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")]]));

    XCTAssertEqualObjects([NSSet setWithArray:[[[managed.boolObj sortedResultsUsingKeyPath:@"self" ascending:NO] valueForKey:@"self"] allObjects]], 
                          ([NSSet setWithArray:@[@YES, @NO]]));
    XCTAssertEqualObjects([NSSet setWithArray:[[[managed.intObj sortedResultsUsingKeyPath:@"self" ascending:NO] valueForKey:@"self"] allObjects]], 
                          ([NSSet setWithArray:@[@3, @2]]));
    XCTAssertEqualObjects([NSSet setWithArray:[[[managed.floatObj sortedResultsUsingKeyPath:@"self" ascending:NO] valueForKey:@"self"] allObjects]], 
                          ([NSSet setWithArray:@[@3.3f, @2.2f]]));
    XCTAssertEqualObjects([NSSet setWithArray:[[[managed.doubleObj sortedResultsUsingKeyPath:@"self" ascending:NO] valueForKey:@"self"] allObjects]], 
                          ([NSSet setWithArray:@[@3.3, @2.2]]));
    XCTAssertEqualObjects([NSSet setWithArray:[[[managed.stringObj sortedResultsUsingKeyPath:@"self" ascending:NO] valueForKey:@"self"] allObjects]], 
                          ([NSSet setWithArray:@[@"bc", @"a"]]));
    XCTAssertEqualObjects([NSSet setWithArray:[[[managed.dataObj sortedResultsUsingKeyPath:@"self" ascending:NO] valueForKey:@"self"] allObjects]], 
                          ([NSSet setWithArray:@[data(2), data(1)]]));
    XCTAssertEqualObjects([NSSet setWithArray:[[[managed.dateObj sortedResultsUsingKeyPath:@"self" ascending:NO] valueForKey:@"self"] allObjects]], 
                          ([NSSet setWithArray:@[date(2), date(1)]]));
    XCTAssertEqualObjects([NSSet setWithArray:[[[managed.decimalObj sortedResultsUsingKeyPath:@"self" ascending:NO] valueForKey:@"self"] allObjects]], 
                          ([NSSet setWithArray:@[decimal128(2), decimal128(1)]]));
    XCTAssertEqualObjects([NSSet setWithArray:[[[managed.objectIdObj sortedResultsUsingKeyPath:@"self" ascending:NO] valueForKey:@"self"] allObjects]], 
                          ([NSSet setWithArray:@[objectId(2), objectId(1)]]));
    XCTAssertEqualObjects([NSSet setWithArray:[[[managed.uuidObj sortedResultsUsingKeyPath:@"self" ascending:NO] valueForKey:@"self"] allObjects]], 
                          ([NSSet setWithArray:@[uuid(@"00000000-0000-0000-0000-000000000000"), uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")]]));
    XCTAssertEqualObjects([NSSet setWithArray:[[[optManaged.boolObj sortedResultsUsingKeyPath:@"self" ascending:NO] valueForKey:@"self"] allObjects]], 
                          ([NSSet setWithArray:@[@NO, NSNull.null]]));
    XCTAssertEqualObjects([NSSet setWithArray:[[[optManaged.intObj sortedResultsUsingKeyPath:@"self" ascending:NO] valueForKey:@"self"] allObjects]], 
                          ([NSSet setWithArray:@[@2, NSNull.null]]));
    XCTAssertEqualObjects([NSSet setWithArray:[[[optManaged.floatObj sortedResultsUsingKeyPath:@"self" ascending:NO] valueForKey:@"self"] allObjects]], 
                          ([NSSet setWithArray:@[@2.2f, NSNull.null]]));
    XCTAssertEqualObjects([NSSet setWithArray:[[[optManaged.doubleObj sortedResultsUsingKeyPath:@"self" ascending:NO] valueForKey:@"self"] allObjects]], 
                          ([NSSet setWithArray:@[@2.2, NSNull.null]]));
    XCTAssertEqualObjects([NSSet setWithArray:[[[optManaged.stringObj sortedResultsUsingKeyPath:@"self" ascending:NO] valueForKey:@"self"] allObjects]], 
                          ([NSSet setWithArray:@[@"a", NSNull.null]]));
    XCTAssertEqualObjects([NSSet setWithArray:[[[optManaged.dataObj sortedResultsUsingKeyPath:@"self" ascending:NO] valueForKey:@"self"] allObjects]], 
                          ([NSSet setWithArray:@[data(1), NSNull.null]]));
    XCTAssertEqualObjects([NSSet setWithArray:[[[optManaged.dateObj sortedResultsUsingKeyPath:@"self" ascending:NO] valueForKey:@"self"] allObjects]], 
                          ([NSSet setWithArray:@[date(1), NSNull.null]]));
    XCTAssertEqualObjects([NSSet setWithArray:[[[optManaged.decimalObj sortedResultsUsingKeyPath:@"self" ascending:NO] valueForKey:@"self"] allObjects]], 
                          ([NSSet setWithArray:@[decimal128(1), NSNull.null]]));
    XCTAssertEqualObjects([NSSet setWithArray:[[[optManaged.objectIdObj sortedResultsUsingKeyPath:@"self" ascending:NO] valueForKey:@"self"] allObjects]], 
                          ([NSSet setWithArray:@[objectId(1), NSNull.null]]));
    XCTAssertEqualObjects([NSSet setWithArray:[[[optManaged.uuidObj sortedResultsUsingKeyPath:@"self" ascending:NO] valueForKey:@"self"] allObjects]], 
                          ([NSSet setWithArray:@[uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"), NSNull.null]]));

    XCTAssertEqualObjects([NSSet setWithArray:[[[managed.boolObj sortedResultsUsingKeyPath:@"self" ascending:YES] valueForKey:@"self"] allObjects]], 
                          ([NSSet setWithArray:@[@NO, @YES]]));
    XCTAssertEqualObjects([NSSet setWithArray:[[[managed.intObj sortedResultsUsingKeyPath:@"self" ascending:YES] valueForKey:@"self"] allObjects]], 
                          ([NSSet setWithArray:@[@2, @3]]));
    XCTAssertEqualObjects([NSSet setWithArray:[[[managed.floatObj sortedResultsUsingKeyPath:@"self" ascending:YES] valueForKey:@"self"] allObjects]], 
                          ([NSSet setWithArray:@[@2.2f, @3.3f]]));
    XCTAssertEqualObjects([NSSet setWithArray:[[[managed.doubleObj sortedResultsUsingKeyPath:@"self" ascending:YES] valueForKey:@"self"] allObjects]], 
                          ([NSSet setWithArray:@[@2.2, @3.3]]));
    XCTAssertEqualObjects([NSSet setWithArray:[[[managed.stringObj sortedResultsUsingKeyPath:@"self" ascending:YES] valueForKey:@"self"] allObjects]], 
                          ([NSSet setWithArray:@[@"a", @"bc"]]));
    XCTAssertEqualObjects([NSSet setWithArray:[[[managed.dataObj sortedResultsUsingKeyPath:@"self" ascending:YES] valueForKey:@"self"] allObjects]], 
                          ([NSSet setWithArray:@[data(1), data(2)]]));
    XCTAssertEqualObjects([NSSet setWithArray:[[[managed.dateObj sortedResultsUsingKeyPath:@"self" ascending:YES] valueForKey:@"self"] allObjects]], 
                          ([NSSet setWithArray:@[date(1), date(2)]]));
    XCTAssertEqualObjects([NSSet setWithArray:[[[managed.decimalObj sortedResultsUsingKeyPath:@"self" ascending:YES] valueForKey:@"self"] allObjects]], 
                          ([NSSet setWithArray:@[decimal128(1), decimal128(2)]]));
    XCTAssertEqualObjects([NSSet setWithArray:[[[managed.objectIdObj sortedResultsUsingKeyPath:@"self" ascending:YES] valueForKey:@"self"] allObjects]], 
                          ([NSSet setWithArray:@[objectId(1), objectId(2)]]));
    XCTAssertEqualObjects([NSSet setWithArray:[[[managed.uuidObj sortedResultsUsingKeyPath:@"self" ascending:YES] valueForKey:@"self"] allObjects]], 
                          ([NSSet setWithArray:@[uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"), uuid(@"00000000-0000-0000-0000-000000000000")]]));
    XCTAssertEqualObjects([NSSet setWithArray:[[[optManaged.boolObj sortedResultsUsingKeyPath:@"self" ascending:YES] valueForKey:@"self"] allObjects]], 
                          ([NSSet setWithArray:@[NSNull.null, @NO]]));
    XCTAssertEqualObjects([NSSet setWithArray:[[[optManaged.intObj sortedResultsUsingKeyPath:@"self" ascending:YES] valueForKey:@"self"] allObjects]], 
                          ([NSSet setWithArray:@[NSNull.null, @2]]));
    XCTAssertEqualObjects([NSSet setWithArray:[[[optManaged.floatObj sortedResultsUsingKeyPath:@"self" ascending:YES] valueForKey:@"self"] allObjects]], 
                          ([NSSet setWithArray:@[NSNull.null, @2.2f]]));
    XCTAssertEqualObjects([NSSet setWithArray:[[[optManaged.doubleObj sortedResultsUsingKeyPath:@"self" ascending:YES] valueForKey:@"self"] allObjects]], 
                          ([NSSet setWithArray:@[NSNull.null, @2.2]]));
    XCTAssertEqualObjects([NSSet setWithArray:[[[optManaged.stringObj sortedResultsUsingKeyPath:@"self" ascending:YES] valueForKey:@"self"] allObjects]], 
                          ([NSSet setWithArray:@[NSNull.null, @"a"]]));
    XCTAssertEqualObjects([NSSet setWithArray:[[[optManaged.dataObj sortedResultsUsingKeyPath:@"self" ascending:YES] valueForKey:@"self"] allObjects]], 
                          ([NSSet setWithArray:@[NSNull.null, data(1)]]));
    XCTAssertEqualObjects([NSSet setWithArray:[[[optManaged.dateObj sortedResultsUsingKeyPath:@"self" ascending:YES] valueForKey:@"self"] allObjects]], 
                          ([NSSet setWithArray:@[NSNull.null, date(1)]]));
    XCTAssertEqualObjects([NSSet setWithArray:[[[optManaged.decimalObj sortedResultsUsingKeyPath:@"self" ascending:YES] valueForKey:@"self"] allObjects]], 
                          ([NSSet setWithArray:@[NSNull.null, decimal128(1)]]));
    XCTAssertEqualObjects([NSSet setWithArray:[[[optManaged.objectIdObj sortedResultsUsingKeyPath:@"self" ascending:YES] valueForKey:@"self"] allObjects]], 
                          ([NSSet setWithArray:@[NSNull.null, objectId(1)]]));
    XCTAssertEqualObjects([NSSet setWithArray:[[[optManaged.uuidObj sortedResultsUsingKeyPath:@"self" ascending:YES] valueForKey:@"self"] allObjects]], 
                          ([NSSet setWithArray:@[NSNull.null, uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")]]));
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
    RLMAssertThrowsWithReason([unmanaged.uuidObj objectsWhere:@"TRUEPREDICATE"], 
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
    RLMAssertThrowsWithReason([optUnmanaged.uuidObj objectsWhere:@"TRUEPREDICATE"], 
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
    RLMAssertThrowsWithReason([unmanaged.uuidObj objectsWithPredicate:[NSPredicate predicateWithValue:YES]], 
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
    RLMAssertThrowsWithReason([optUnmanaged.uuidObj objectsWithPredicate:[NSPredicate predicateWithValue:YES]], 
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
    RLMAssertThrowsWithReason([managed.uuidObj objectsWhere:@"TRUEPREDICATE"], 
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
    RLMAssertThrowsWithReason([optManaged.uuidObj objectsWhere:@"TRUEPREDICATE"], 
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
    RLMAssertThrowsWithReason([managed.uuidObj objectsWithPredicate:[NSPredicate predicateWithValue:YES]], 
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
    RLMAssertThrowsWithReason([optManaged.uuidObj objectsWithPredicate:[NSPredicate predicateWithValue:YES]], 
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
    RLMAssertThrowsWithReason([[managed.uuidObj sortedResultsUsingKeyPath:@"self" ascending:NO] 
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
    RLMAssertThrowsWithReason([[optManaged.uuidObj sortedResultsUsingKeyPath:@"self" ascending:NO] 
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
    RLMAssertThrowsWithReason([[managed.uuidObj sortedResultsUsingKeyPath:@"self" ascending:NO] 
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
    RLMAssertThrowsWithReason([[optManaged.uuidObj sortedResultsUsingKeyPath:@"self" ascending:NO] 
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
    RLMAssertThrowsWithReason([unmanaged.uuidObj addNotificationBlock:^(__unused id a, __unused id c, __unused id e) { }], 
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
    RLMAssertThrowsWithReason([optUnmanaged.uuidObj addNotificationBlock:^(__unused id a, __unused id c, __unused id e) { }], 
                              @"This method may only be called on RLMSet instances retrieved from an RLMRealm");
}

- (void)testSetSet {
    [managed.boolObj addObjects:@[@NO, @YES]];
    [managed.intObj addObjects:@[@2, @3]];
    [managed.floatObj addObjects:@[@2.2f, @3.3f]];
    [managed.doubleObj addObjects:@[@2.2, @3.3]];
    [managed.stringObj addObjects:@[@"a", @"bc"]];
    [managed.dataObj addObjects:@[data(1), data(2)]];
    [managed.dateObj addObjects:@[date(1), date(2)]];
    [managed.decimalObj addObjects:@[decimal128(1), decimal128(2)]];
    [managed.objectIdObj addObjects:@[objectId(1), objectId(2)]];
    [managed.uuidObj addObjects:@[uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"), uuid(@"00000000-0000-0000-0000-000000000000")]];
    [optManaged.boolObj addObjects:@[NSNull.null, @NO, NSNull.null]];
    [optManaged.intObj addObjects:@[NSNull.null, @2, NSNull.null]];
    [optManaged.floatObj addObjects:@[NSNull.null, @2.2f, NSNull.null]];
    [optManaged.doubleObj addObjects:@[NSNull.null, @2.2, NSNull.null]];
    [optManaged.stringObj addObjects:@[NSNull.null, @"a", NSNull.null]];
    [optManaged.dataObj addObjects:@[NSNull.null, data(1), NSNull.null]];
    [optManaged.dateObj addObjects:@[NSNull.null, date(1), NSNull.null]];
    [optManaged.decimalObj addObjects:@[NSNull.null, decimal128(1), NSNull.null]];
    [optManaged.objectIdObj addObjects:@[NSNull.null, objectId(1), NSNull.null]];
    [optManaged.uuidObj addObjects:@[NSNull.null, uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"), NSNull.null]];
    [managed.boolObj2 addObjects:@[@YES, @NO]];
    [managed.intObj2 addObjects:@[@3, @4]];
    [managed.floatObj2 addObjects:@[@3.3f, @4.4f]];
    [managed.doubleObj2 addObjects:@[@3.3, @4.4]];
    [managed.stringObj2 addObjects:@[@"bc", @"de"]];
    [managed.dataObj2 addObjects:@[data(2), data(3)]];
    [managed.dateObj2 addObjects:@[date(2), date(3)]];
    [managed.decimalObj2 addObjects:@[decimal128(2), decimal128(3)]];
    [managed.objectIdObj2 addObjects:@[objectId(2), objectId(3)]];
    [managed.uuidObj2 addObjects:@[uuid(@"00000000-0000-0000-0000-000000000000"), uuid(@"123DECC8-B300-4954-A233-F89909F4FD89")]];
    [optManaged.boolObj2 addObjects:@[@YES, @NO, NSNull.null]];
    [optManaged.intObj2 addObjects:@[@3, @4, NSNull.null]];
    [optManaged.floatObj2 addObjects:@[@3.3f, @4.4f, NSNull.null]];
    [optManaged.doubleObj2 addObjects:@[@3.3, @4.4, NSNull.null]];
    [optManaged.stringObj2 addObjects:@[@"bc", @"de", NSNull.null]];
    [optManaged.dataObj2 addObjects:@[data(2), data(3), NSNull.null]];
    [optManaged.dateObj2 addObjects:@[date(2), date(3), NSNull.null]];
    [optManaged.decimalObj2 addObjects:@[decimal128(2), decimal128(3), NSNull.null]];
    [optManaged.objectIdObj2 addObjects:@[objectId(2), objectId(3), NSNull.null]];
    [optManaged.uuidObj2 addObjects:@[uuid(@"00000000-0000-0000-0000-000000000000"), uuid(@"123DECC8-B300-4954-A233-F89909F4FD89"), NSNull.null]];
    [realm commitWriteTransaction];

    [unmanaged.boolObj addObjects:@[@NO, @YES]];
    [unmanaged.intObj addObjects:@[@2, @3]];
    [unmanaged.floatObj addObjects:@[@2.2f, @3.3f]];
    [unmanaged.doubleObj addObjects:@[@2.2, @3.3]];
    [unmanaged.stringObj addObjects:@[@"a", @"bc"]];
    [unmanaged.dataObj addObjects:@[data(1), data(2)]];
    [unmanaged.dateObj addObjects:@[date(1), date(2)]];
    [unmanaged.decimalObj addObjects:@[decimal128(1), decimal128(2)]];
    [unmanaged.objectIdObj addObjects:@[objectId(1), objectId(2)]];
    [unmanaged.uuidObj addObjects:@[uuid(@"00000000-0000-0000-0000-000000000000"), uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")]];
    [optUnmanaged.boolObj addObjects:@[NSNull.null, @NO, NSNull.null]];
    [optUnmanaged.intObj addObjects:@[NSNull.null, @2, NSNull.null]];
    [optUnmanaged.floatObj addObjects:@[NSNull.null, @2.2f, NSNull.null]];
    [optUnmanaged.doubleObj addObjects:@[NSNull.null, @2.2, NSNull.null]];
    [optUnmanaged.stringObj addObjects:@[NSNull.null, @"a", NSNull.null]];
    [optUnmanaged.dataObj addObjects:@[NSNull.null, data(1), NSNull.null]];
    [optUnmanaged.dateObj addObjects:@[NSNull.null, date(1), NSNull.null]];
    [optUnmanaged.decimalObj addObjects:@[NSNull.null, decimal128(1), NSNull.null]];
    [optUnmanaged.objectIdObj addObjects:@[NSNull.null, objectId(1), NSNull.null]];
    [optUnmanaged.uuidObj addObjects:@[NSNull.null, uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"), NSNull.null]];
    [unmanaged.boolObj2 addObjects:@[@NO, @YES]];
    [unmanaged.intObj2 addObjects:@[@2, @4]];
    [unmanaged.floatObj2 addObjects:@[@2.2f, @4.4f]];
    [unmanaged.doubleObj2 addObjects:@[@2.2, @4.4]];
    [unmanaged.stringObj2 addObjects:@[@"a", @"de"]];
    [unmanaged.dataObj2 addObjects:@[data(1), data(3)]];
    [unmanaged.dateObj2 addObjects:@[date(1), date(3)]];
    [unmanaged.decimalObj2 addObjects:@[decimal128(1), decimal128(3)]];
    [unmanaged.objectIdObj2 addObjects:@[objectId(1), objectId(3)]];
    [unmanaged.uuidObj2 addObjects:@[uuid(@"00000000-0000-0000-0000-000000000000"), uuid(@"123DECC8-B300-4954-A233-F89909F4FD89")]];
    [optUnmanaged.boolObj2 addObjects:@[@YES, @NO, NSNull.null]];
    [optUnmanaged.intObj2 addObjects:@[@3, @4, NSNull.null]];
    [optUnmanaged.floatObj2 addObjects:@[@3.3f, @4.4f, NSNull.null]];
    [optUnmanaged.doubleObj2 addObjects:@[@3.3, @4.4, NSNull.null]];
    [optUnmanaged.stringObj2 addObjects:@[@"bc", @"de", NSNull.null]];
    [optUnmanaged.dataObj2 addObjects:@[data(2), data(3), NSNull.null]];
    [optUnmanaged.dateObj2 addObjects:@[date(2), date(3), NSNull.null]];
    [optUnmanaged.decimalObj2 addObjects:@[decimal128(2), decimal128(4), NSNull.null]];
    [optUnmanaged.objectIdObj2 addObjects:@[objectId(2), objectId(4), NSNull.null]];
    [optUnmanaged.uuidObj2 addObjects:@[uuid(@"00000000-0000-0000-0000-000000000000"), uuid(@"123DECC8-B300-4954-A233-F89909F4FD89"), NSNull.null]];

    [unmanaged.boolObj setSet:unmanaged.boolObj2];
    [unmanaged.intObj setSet:unmanaged.intObj2];
    [unmanaged.floatObj setSet:unmanaged.floatObj2];
    [unmanaged.doubleObj setSet:unmanaged.doubleObj2];
    [unmanaged.stringObj setSet:unmanaged.stringObj2];
    [unmanaged.dataObj setSet:unmanaged.dataObj2];
    [unmanaged.dateObj setSet:unmanaged.dateObj2];
    [unmanaged.decimalObj setSet:unmanaged.decimalObj2];
    [unmanaged.objectIdObj setSet:unmanaged.objectIdObj2];
    [unmanaged.uuidObj setSet:unmanaged.uuidObj2];
    [optUnmanaged.boolObj setSet:optUnmanaged.boolObj2];
    [optUnmanaged.intObj setSet:optUnmanaged.intObj2];
    [optUnmanaged.floatObj setSet:optUnmanaged.floatObj2];
    [optUnmanaged.doubleObj setSet:optUnmanaged.doubleObj2];
    [optUnmanaged.stringObj setSet:optUnmanaged.stringObj2];
    [optUnmanaged.dataObj setSet:optUnmanaged.dataObj2];
    [optUnmanaged.dateObj setSet:optUnmanaged.dateObj2];
    [optUnmanaged.decimalObj setSet:optUnmanaged.decimalObj2];
    [optUnmanaged.objectIdObj setSet:optUnmanaged.objectIdObj2];
    [optUnmanaged.uuidObj setSet:optUnmanaged.uuidObj2];

    [realm beginWriteTransaction];
    [managed.boolObj setSet:managed.boolObj2];
    [managed.intObj setSet:managed.intObj2];
    [managed.floatObj setSet:managed.floatObj2];
    [managed.doubleObj setSet:managed.doubleObj2];
    [managed.stringObj setSet:managed.stringObj2];
    [managed.dataObj setSet:managed.dataObj2];
    [managed.dateObj setSet:managed.dateObj2];
    [managed.decimalObj setSet:managed.decimalObj2];
    [managed.objectIdObj setSet:managed.objectIdObj2];
    [managed.uuidObj setSet:managed.uuidObj2];
    [optManaged.boolObj setSet:optManaged.boolObj2];
    [optManaged.intObj setSet:optManaged.intObj2];
    [optManaged.floatObj setSet:optManaged.floatObj2];
    [optManaged.doubleObj setSet:optManaged.doubleObj2];
    [optManaged.stringObj setSet:optManaged.stringObj2];
    [optManaged.dataObj setSet:optManaged.dataObj2];
    [optManaged.dateObj setSet:optManaged.dateObj2];
    [optManaged.decimalObj setSet:optManaged.decimalObj2];
    [optManaged.objectIdObj setSet:optManaged.objectIdObj2];
    [optManaged.uuidObj setSet:optManaged.uuidObj2];
    [realm commitWriteTransaction];

    XCTAssertEqual(unmanaged.boolObj.count, 2U);
    XCTAssertEqualObjects(unmanaged.boolObj.allObjects, (@[@NO, @YES]));
    XCTAssertEqual(unmanaged.intObj.count, 2U);
    XCTAssertEqual(unmanaged.floatObj.count, 2U);
    XCTAssertEqual(unmanaged.doubleObj.count, 2U);
    XCTAssertEqual(unmanaged.stringObj.count, 2U);
    XCTAssertEqual(unmanaged.dataObj.count, 2U);
    XCTAssertEqual(unmanaged.dateObj.count, 2U);
    XCTAssertEqual(unmanaged.decimalObj.count, 2U);
    XCTAssertEqual(unmanaged.objectIdObj.count, 2U);
    XCTAssertEqual(unmanaged.uuidObj.count, 2U);
    XCTAssertEqualObjects([NSSet setWithArray:unmanaged.intObj.allObjects], ([NSSet setWithArray:@[@2, @4]]));
    XCTAssertEqualObjects([NSSet setWithArray:unmanaged.floatObj.allObjects], ([NSSet setWithArray:@[@2.2f, @4.4f]]));
    XCTAssertEqualObjects([NSSet setWithArray:unmanaged.doubleObj.allObjects], ([NSSet setWithArray:@[@2.2, @4.4]]));
    XCTAssertEqualObjects([NSSet setWithArray:unmanaged.stringObj.allObjects], ([NSSet setWithArray:@[@"a", @"de"]]));
    XCTAssertEqualObjects([NSSet setWithArray:unmanaged.dataObj.allObjects], ([NSSet setWithArray:@[data(1), data(3)]]));
    XCTAssertEqualObjects([NSSet setWithArray:unmanaged.dateObj.allObjects], ([NSSet setWithArray:@[date(1), date(3)]]));
    XCTAssertEqualObjects([NSSet setWithArray:unmanaged.decimalObj.allObjects], ([NSSet setWithArray:@[decimal128(1), decimal128(3)]]));
    XCTAssertEqualObjects([NSSet setWithArray:unmanaged.objectIdObj.allObjects], ([NSSet setWithArray:@[objectId(1), objectId(3)]]));
    XCTAssertEqualObjects([NSSet setWithArray:unmanaged.uuidObj.allObjects], ([NSSet setWithArray:@[uuid(@"00000000-0000-0000-0000-000000000000"), uuid(@"123DECC8-B300-4954-A233-F89909F4FD89")]]));
    XCTAssertEqual(optUnmanaged.boolObj.count, 3U);
    XCTAssertEqualObjects([NSSet setWithArray:optUnmanaged.boolObj.allObjects], ([NSSet setWithArray:@[NSNull.null, @NO, @YES]]));
    XCTAssertEqual(optUnmanaged.intObj.count, 3U);
    XCTAssertEqual(optUnmanaged.floatObj.count, 3U);
    XCTAssertEqual(optUnmanaged.doubleObj.count, 3U);
    XCTAssertEqual(optUnmanaged.stringObj.count, 3U);
    XCTAssertEqual(optUnmanaged.dataObj.count, 3U);
    XCTAssertEqual(optUnmanaged.dateObj.count, 3U);
    XCTAssertEqual(optUnmanaged.decimalObj.count, 3U);
    XCTAssertEqual(optUnmanaged.objectIdObj.count, 3U);
    XCTAssertEqual(optUnmanaged.uuidObj.count, 3U);
    XCTAssertEqualObjects([NSSet setWithArray:optUnmanaged.intObj.allObjects], ([NSSet setWithArray:@[NSNull.null, @3, @4]]));
    XCTAssertEqualObjects([NSSet setWithArray:optUnmanaged.floatObj.allObjects], ([NSSet setWithArray:@[NSNull.null, @3.3f, @4.4f]]));
    XCTAssertEqualObjects([NSSet setWithArray:optUnmanaged.doubleObj.allObjects], ([NSSet setWithArray:@[NSNull.null, @3.3, @4.4]]));
    XCTAssertEqualObjects([NSSet setWithArray:optUnmanaged.stringObj.allObjects], ([NSSet setWithArray:@[NSNull.null, @"bc", @"de"]]));
    XCTAssertEqualObjects([NSSet setWithArray:optUnmanaged.dataObj.allObjects], ([NSSet setWithArray:@[NSNull.null, data(2), data(3)]]));
    XCTAssertEqualObjects([NSSet setWithArray:optUnmanaged.dateObj.allObjects], ([NSSet setWithArray:@[NSNull.null, date(2), date(3)]]));
    XCTAssertEqualObjects([NSSet setWithArray:optUnmanaged.decimalObj.allObjects], ([NSSet setWithArray:@[NSNull.null, decimal128(2), decimal128(4)]]));
    XCTAssertEqualObjects([NSSet setWithArray:optUnmanaged.objectIdObj.allObjects], ([NSSet setWithArray:@[NSNull.null, objectId(2), objectId(4)]]));
    XCTAssertEqualObjects([NSSet setWithArray:optUnmanaged.uuidObj.allObjects], ([NSSet setWithArray:@[NSNull.null, uuid(@"00000000-0000-0000-0000-000000000000"), uuid(@"123DECC8-B300-4954-A233-F89909F4FD89")]]));
    XCTAssertEqual(managed.boolObj.count, 2U);
    XCTAssertEqualObjects([NSSet setWithArray:managed.boolObj.allObjects], ([NSSet setWithArray:@[@NO, @YES]]));
    XCTAssertEqual(managed.intObj.count, 2U);
    XCTAssertEqual(managed.floatObj.count, 2U);
    XCTAssertEqual(managed.doubleObj.count, 2U);
    XCTAssertEqual(managed.stringObj.count, 2U);
    XCTAssertEqual(managed.dataObj.count, 2U);
    XCTAssertEqual(managed.dateObj.count, 2U);
    XCTAssertEqual(managed.decimalObj.count, 2U);
    XCTAssertEqual(managed.objectIdObj.count, 2U);
    XCTAssertEqual(managed.uuidObj.count, 2U);
    XCTAssertEqualObjects([NSSet setWithArray:managed.intObj.allObjects], ([NSSet setWithArray:@[@3, @4]]));
    XCTAssertEqualObjects([NSSet setWithArray:managed.floatObj.allObjects], ([NSSet setWithArray:@[@3.3f, @4.4f]]));
    XCTAssertEqualObjects([NSSet setWithArray:managed.doubleObj.allObjects], ([NSSet setWithArray:@[@3.3, @4.4]]));
    XCTAssertEqualObjects([NSSet setWithArray:managed.stringObj.allObjects], ([NSSet setWithArray:@[@"bc", @"de"]]));
    XCTAssertEqualObjects([NSSet setWithArray:managed.dataObj.allObjects], ([NSSet setWithArray:@[data(2), data(3)]]));
    XCTAssertEqualObjects([NSSet setWithArray:managed.dateObj.allObjects], ([NSSet setWithArray:@[date(2), date(3)]]));
    XCTAssertEqualObjects([NSSet setWithArray:managed.decimalObj.allObjects], ([NSSet setWithArray:@[decimal128(2), decimal128(3)]]));
    XCTAssertEqualObjects([NSSet setWithArray:managed.objectIdObj.allObjects], ([NSSet setWithArray:@[objectId(2), objectId(3)]]));
    XCTAssertEqualObjects([NSSet setWithArray:managed.uuidObj.allObjects], ([NSSet setWithArray:@[uuid(@"00000000-0000-0000-0000-000000000000"), uuid(@"123DECC8-B300-4954-A233-F89909F4FD89")]]));
    XCTAssertEqual(optManaged.boolObj.count, 3U);
    XCTAssertEqual(optManaged.intObj.count, 3U);
    XCTAssertEqual(optManaged.floatObj.count, 3U);
    XCTAssertEqual(optManaged.doubleObj.count, 3U);
    XCTAssertEqual(optManaged.stringObj.count, 3U);
    XCTAssertEqual(optManaged.dataObj.count, 3U);
    XCTAssertEqual(optManaged.dateObj.count, 3U);
    XCTAssertEqual(optManaged.decimalObj.count, 3U);
    XCTAssertEqual(optManaged.objectIdObj.count, 3U);
    XCTAssertEqual(optManaged.uuidObj.count, 3U);
}

- (void)testUnion {
    [managed.boolObj addObjects:@[@NO, @YES]];
    [managed.intObj addObjects:@[@2, @3]];
    [managed.floatObj addObjects:@[@2.2f, @3.3f]];
    [managed.doubleObj addObjects:@[@2.2, @3.3]];
    [managed.stringObj addObjects:@[@"a", @"bc"]];
    [managed.dataObj addObjects:@[data(1), data(2)]];
    [managed.dateObj addObjects:@[date(1), date(2)]];
    [managed.decimalObj addObjects:@[decimal128(1), decimal128(2)]];
    [managed.objectIdObj addObjects:@[objectId(1), objectId(2)]];
    [managed.uuidObj addObjects:@[uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"), uuid(@"00000000-0000-0000-0000-000000000000")]];
    [optManaged.boolObj addObjects:@[NSNull.null, @NO, NSNull.null]];
    [optManaged.intObj addObjects:@[NSNull.null, @2, NSNull.null]];
    [optManaged.floatObj addObjects:@[NSNull.null, @2.2f, NSNull.null]];
    [optManaged.doubleObj addObjects:@[NSNull.null, @2.2, NSNull.null]];
    [optManaged.stringObj addObjects:@[NSNull.null, @"a", NSNull.null]];
    [optManaged.dataObj addObjects:@[NSNull.null, data(1), NSNull.null]];
    [optManaged.dateObj addObjects:@[NSNull.null, date(1), NSNull.null]];
    [optManaged.decimalObj addObjects:@[NSNull.null, decimal128(1), NSNull.null]];
    [optManaged.objectIdObj addObjects:@[NSNull.null, objectId(1), NSNull.null]];
    [optManaged.uuidObj addObjects:@[NSNull.null, uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"), NSNull.null]];
    [managed.boolObj2 addObjects:@[@YES, @NO]];
    [managed.intObj2 addObjects:@[@3, @4]];
    [managed.floatObj2 addObjects:@[@3.3f, @4.4f]];
    [managed.doubleObj2 addObjects:@[@3.3, @4.4]];
    [managed.stringObj2 addObjects:@[@"bc", @"de"]];
    [managed.dataObj2 addObjects:@[data(2), data(3)]];
    [managed.dateObj2 addObjects:@[date(2), date(3)]];
    [managed.decimalObj2 addObjects:@[decimal128(2), decimal128(3)]];
    [managed.objectIdObj2 addObjects:@[objectId(2), objectId(3)]];
    [managed.uuidObj2 addObjects:@[uuid(@"00000000-0000-0000-0000-000000000000"), uuid(@"123DECC8-B300-4954-A233-F89909F4FD89")]];
    [optManaged.boolObj2 addObjects:@[@YES, @NO, NSNull.null]];
    [optManaged.intObj2 addObjects:@[@3, @4, NSNull.null]];
    [optManaged.floatObj2 addObjects:@[@3.3f, @4.4f, NSNull.null]];
    [optManaged.doubleObj2 addObjects:@[@3.3, @4.4, NSNull.null]];
    [optManaged.stringObj2 addObjects:@[@"bc", @"de", NSNull.null]];
    [optManaged.dataObj2 addObjects:@[data(2), data(3), NSNull.null]];
    [optManaged.dateObj2 addObjects:@[date(2), date(3), NSNull.null]];
    [optManaged.decimalObj2 addObjects:@[decimal128(2), decimal128(3), NSNull.null]];
    [optManaged.objectIdObj2 addObjects:@[objectId(2), objectId(3), NSNull.null]];
    [optManaged.uuidObj2 addObjects:@[uuid(@"00000000-0000-0000-0000-000000000000"), uuid(@"123DECC8-B300-4954-A233-F89909F4FD89"), NSNull.null]];
    [realm commitWriteTransaction];

    [unmanaged.boolObj addObjects:@[@NO, @YES]];
    [unmanaged.intObj addObjects:@[@2, @3]];
    [unmanaged.floatObj addObjects:@[@2.2f, @3.3f]];
    [unmanaged.doubleObj addObjects:@[@2.2, @3.3]];
    [unmanaged.stringObj addObjects:@[@"a", @"bc"]];
    [unmanaged.dataObj addObjects:@[data(1), data(2)]];
    [unmanaged.dateObj addObjects:@[date(1), date(2)]];
    [unmanaged.decimalObj addObjects:@[decimal128(1), decimal128(2)]];
    [unmanaged.objectIdObj addObjects:@[objectId(1), objectId(2)]];
    [unmanaged.uuidObj addObjects:@[uuid(@"00000000-0000-0000-0000-000000000000"), uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")]];
    [optUnmanaged.boolObj addObjects:@[NSNull.null, @NO, NSNull.null]];
    [optUnmanaged.intObj addObjects:@[NSNull.null, @2, NSNull.null]];
    [optUnmanaged.floatObj addObjects:@[NSNull.null, @2.2f, NSNull.null]];
    [optUnmanaged.doubleObj addObjects:@[NSNull.null, @2.2, NSNull.null]];
    [optUnmanaged.stringObj addObjects:@[NSNull.null, @"a", NSNull.null]];
    [optUnmanaged.dataObj addObjects:@[NSNull.null, data(1), NSNull.null]];
    [optUnmanaged.dateObj addObjects:@[NSNull.null, date(1), NSNull.null]];
    [optUnmanaged.decimalObj addObjects:@[NSNull.null, decimal128(1), NSNull.null]];
    [optUnmanaged.objectIdObj addObjects:@[NSNull.null, objectId(1), NSNull.null]];
    [optUnmanaged.uuidObj addObjects:@[NSNull.null, uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"), NSNull.null]];
    [unmanaged.boolObj2 addObjects:@[@NO, @YES]];
    [unmanaged.intObj2 addObjects:@[@2, @4]];
    [unmanaged.floatObj2 addObjects:@[@2.2f, @4.4f]];
    [unmanaged.doubleObj2 addObjects:@[@2.2, @4.4]];
    [unmanaged.stringObj2 addObjects:@[@"a", @"de"]];
    [unmanaged.dataObj2 addObjects:@[data(1), data(3)]];
    [unmanaged.dateObj2 addObjects:@[date(1), date(3)]];
    [unmanaged.decimalObj2 addObjects:@[decimal128(1), decimal128(3)]];
    [unmanaged.objectIdObj2 addObjects:@[objectId(1), objectId(3)]];
    [unmanaged.uuidObj2 addObjects:@[uuid(@"00000000-0000-0000-0000-000000000000"), uuid(@"123DECC8-B300-4954-A233-F89909F4FD89")]];
    [optUnmanaged.boolObj2 addObjects:@[@YES, @NO, NSNull.null]];
    [optUnmanaged.intObj2 addObjects:@[@3, @4, NSNull.null]];
    [optUnmanaged.floatObj2 addObjects:@[@3.3f, @4.4f, NSNull.null]];
    [optUnmanaged.doubleObj2 addObjects:@[@3.3, @4.4, NSNull.null]];
    [optUnmanaged.stringObj2 addObjects:@[@"bc", @"de", NSNull.null]];
    [optUnmanaged.dataObj2 addObjects:@[data(2), data(3), NSNull.null]];
    [optUnmanaged.dateObj2 addObjects:@[date(2), date(3), NSNull.null]];
    [optUnmanaged.decimalObj2 addObjects:@[decimal128(2), decimal128(4), NSNull.null]];
    [optUnmanaged.objectIdObj2 addObjects:@[objectId(2), objectId(4), NSNull.null]];
    [optUnmanaged.uuidObj2 addObjects:@[uuid(@"00000000-0000-0000-0000-000000000000"), uuid(@"123DECC8-B300-4954-A233-F89909F4FD89"), NSNull.null]];

    XCTAssertThrows([managed.boolObj unionSet:managed.boolObj2]);
    XCTAssertThrows([managed.intObj unionSet:managed.intObj2]);
    XCTAssertThrows([managed.floatObj unionSet:managed.floatObj2]);
    XCTAssertThrows([managed.doubleObj unionSet:managed.doubleObj2]);
    XCTAssertThrows([managed.stringObj unionSet:managed.stringObj2]);
    XCTAssertThrows([managed.dataObj unionSet:managed.dataObj2]);
    XCTAssertThrows([managed.dateObj unionSet:managed.dateObj2]);
    XCTAssertThrows([managed.decimalObj unionSet:managed.decimalObj2]);
    XCTAssertThrows([managed.objectIdObj unionSet:managed.objectIdObj2]);
    XCTAssertThrows([managed.uuidObj unionSet:managed.uuidObj2]);
    XCTAssertThrows([optManaged.boolObj unionSet:optManaged.boolObj2]);
    XCTAssertThrows([optManaged.intObj unionSet:optManaged.intObj2]);
    XCTAssertThrows([optManaged.floatObj unionSet:optManaged.floatObj2]);
    XCTAssertThrows([optManaged.doubleObj unionSet:optManaged.doubleObj2]);
    XCTAssertThrows([optManaged.stringObj unionSet:optManaged.stringObj2]);
    XCTAssertThrows([optManaged.dataObj unionSet:optManaged.dataObj2]);
    XCTAssertThrows([optManaged.dateObj unionSet:optManaged.dateObj2]);
    XCTAssertThrows([optManaged.decimalObj unionSet:optManaged.decimalObj2]);
    XCTAssertThrows([optManaged.objectIdObj unionSet:optManaged.objectIdObj2]);
    XCTAssertThrows([optManaged.uuidObj unionSet:optManaged.uuidObj2]);
    [unmanaged.boolObj unionSet:unmanaged.boolObj2];
    [unmanaged.intObj unionSet:unmanaged.intObj2];
    [unmanaged.floatObj unionSet:unmanaged.floatObj2];
    [unmanaged.doubleObj unionSet:unmanaged.doubleObj2];
    [unmanaged.stringObj unionSet:unmanaged.stringObj2];
    [unmanaged.dataObj unionSet:unmanaged.dataObj2];
    [unmanaged.dateObj unionSet:unmanaged.dateObj2];
    [unmanaged.decimalObj unionSet:unmanaged.decimalObj2];
    [unmanaged.objectIdObj unionSet:unmanaged.objectIdObj2];
    [unmanaged.uuidObj unionSet:unmanaged.uuidObj2];
    [optUnmanaged.boolObj unionSet:optUnmanaged.boolObj2];
    [optUnmanaged.intObj unionSet:optUnmanaged.intObj2];
    [optUnmanaged.floatObj unionSet:optUnmanaged.floatObj2];
    [optUnmanaged.doubleObj unionSet:optUnmanaged.doubleObj2];
    [optUnmanaged.stringObj unionSet:optUnmanaged.stringObj2];
    [optUnmanaged.dataObj unionSet:optUnmanaged.dataObj2];
    [optUnmanaged.dateObj unionSet:optUnmanaged.dateObj2];
    [optUnmanaged.decimalObj unionSet:optUnmanaged.decimalObj2];
    [optUnmanaged.objectIdObj unionSet:optUnmanaged.objectIdObj2];
    [optUnmanaged.uuidObj unionSet:optUnmanaged.uuidObj2];

    [realm beginWriteTransaction];
    [managed.boolObj unionSet:managed.boolObj2];
    [managed.intObj unionSet:managed.intObj2];
    [managed.floatObj unionSet:managed.floatObj2];
    [managed.doubleObj unionSet:managed.doubleObj2];
    [managed.stringObj unionSet:managed.stringObj2];
    [managed.dataObj unionSet:managed.dataObj2];
    [managed.dateObj unionSet:managed.dateObj2];
    [managed.decimalObj unionSet:managed.decimalObj2];
    [managed.objectIdObj unionSet:managed.objectIdObj2];
    [managed.uuidObj unionSet:managed.uuidObj2];
    [optManaged.boolObj unionSet:optManaged.boolObj2];
    [optManaged.intObj unionSet:optManaged.intObj2];
    [optManaged.floatObj unionSet:optManaged.floatObj2];
    [optManaged.doubleObj unionSet:optManaged.doubleObj2];
    [optManaged.stringObj unionSet:optManaged.stringObj2];
    [optManaged.dataObj unionSet:optManaged.dataObj2];
    [optManaged.dateObj unionSet:optManaged.dateObj2];
    [optManaged.decimalObj unionSet:optManaged.decimalObj2];
    [optManaged.objectIdObj unionSet:optManaged.objectIdObj2];
    [optManaged.uuidObj unionSet:optManaged.uuidObj2];
    [realm commitWriteTransaction];

    XCTAssertEqual(unmanaged.boolObj.count, 2U);
    XCTAssertEqualObjects([NSSet setWithArray:unmanaged.boolObj.allObjects], ([NSSet setWithArray:@[@NO, @YES]]));
    XCTAssertEqual(unmanaged.intObj.count, 3U);
    XCTAssertEqual(unmanaged.floatObj.count, 3U);
    XCTAssertEqual(unmanaged.doubleObj.count, 3U);
    XCTAssertEqual(unmanaged.stringObj.count, 3U);
    XCTAssertEqual(unmanaged.dataObj.count, 3U);
    XCTAssertEqual(unmanaged.dateObj.count, 3U);
    XCTAssertEqual(unmanaged.decimalObj.count, 3U);
    XCTAssertEqual(unmanaged.objectIdObj.count, 3U);
    XCTAssertEqual(unmanaged.uuidObj.count, 3U);
    XCTAssertEqualObjects([NSSet setWithArray:unmanaged.intObj.allObjects], ([NSSet setWithArray:@[@2, @3, @4]]));
    XCTAssertEqualObjects([NSSet setWithArray:unmanaged.floatObj.allObjects], ([NSSet setWithArray:@[@2.2f, @3.3f, @4.4f]]));
    XCTAssertEqualObjects([NSSet setWithArray:unmanaged.doubleObj.allObjects], ([NSSet setWithArray:@[@2.2, @3.3, @4.4]]));
    XCTAssertEqualObjects([NSSet setWithArray:unmanaged.stringObj.allObjects], ([NSSet setWithArray:@[@"a", @"bc", @"de"]]));
    XCTAssertEqualObjects([NSSet setWithArray:unmanaged.dataObj.allObjects], ([NSSet setWithArray:@[data(1), data(2), data(3)]]));
    XCTAssertEqualObjects([NSSet setWithArray:unmanaged.dateObj.allObjects], ([NSSet setWithArray:@[date(1), date(2), date(3)]]));
    XCTAssertEqualObjects([NSSet setWithArray:unmanaged.decimalObj.allObjects], ([NSSet setWithArray:@[decimal128(1), decimal128(2), decimal128(3)]]));
    XCTAssertEqualObjects([NSSet setWithArray:unmanaged.objectIdObj.allObjects], ([NSSet setWithArray:@[objectId(1), objectId(2), objectId(3)]]));
    XCTAssertEqualObjects([NSSet setWithArray:unmanaged.uuidObj.allObjects], ([NSSet setWithArray:@[uuid(@"00000000-0000-0000-0000-000000000000"), uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"), uuid(@"123DECC8-B300-4954-A233-F89909F4FD89")]]));
    XCTAssertEqual(optUnmanaged.boolObj.count, 3U);
    XCTAssertEqualObjects([NSSet setWithArray:optUnmanaged.boolObj.allObjects], ([NSSet setWithArray:@[NSNull.null, @NO, @YES]]));
    XCTAssertEqual(optUnmanaged.intObj.count, 4U);
    XCTAssertEqual(optUnmanaged.floatObj.count, 4U);
    XCTAssertEqual(optUnmanaged.doubleObj.count, 4U);
    XCTAssertEqual(optUnmanaged.stringObj.count, 4U);
    XCTAssertEqual(optUnmanaged.dataObj.count, 4U);
    XCTAssertEqual(optUnmanaged.dateObj.count, 4U);
    XCTAssertEqual(optUnmanaged.decimalObj.count, 4U);
    XCTAssertEqual(optUnmanaged.objectIdObj.count, 4U);
    XCTAssertEqual(optUnmanaged.uuidObj.count, 4U);
    XCTAssertEqualObjects([NSSet setWithArray:optUnmanaged.intObj.allObjects], ([NSSet setWithArray:@[NSNull.null, @2, @3, @4]]));
    XCTAssertEqualObjects([NSSet setWithArray:optUnmanaged.floatObj.allObjects], ([NSSet setWithArray:@[NSNull.null, @2.2f, @3.3f, @4.4f]]));
    XCTAssertEqualObjects([NSSet setWithArray:optUnmanaged.doubleObj.allObjects], ([NSSet setWithArray:@[NSNull.null, @2.2, @3.3, @4.4]]));
    XCTAssertEqualObjects([NSSet setWithArray:optUnmanaged.stringObj.allObjects], ([NSSet setWithArray:@[NSNull.null, @"a", @"bc", @"de"]]));
    XCTAssertEqualObjects([NSSet setWithArray:optUnmanaged.dataObj.allObjects], ([NSSet setWithArray:@[NSNull.null, data(1), data(2), data(3)]]));
    XCTAssertEqualObjects([NSSet setWithArray:optUnmanaged.dateObj.allObjects], ([NSSet setWithArray:@[NSNull.null, date(1), date(2), date(3)]]));
    XCTAssertEqualObjects([NSSet setWithArray:optUnmanaged.decimalObj.allObjects], ([NSSet setWithArray:@[NSNull.null, decimal128(1), decimal128(2), decimal128(4)]]));
    XCTAssertEqualObjects([NSSet setWithArray:optUnmanaged.objectIdObj.allObjects], ([NSSet setWithArray:@[NSNull.null, objectId(1), objectId(2), objectId(4)]]));
    XCTAssertEqualObjects([NSSet setWithArray:optUnmanaged.uuidObj.allObjects], ([NSSet setWithArray:@[NSNull.null, uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"), uuid(@"00000000-0000-0000-0000-000000000000"), uuid(@"123DECC8-B300-4954-A233-F89909F4FD89")]]));
    XCTAssertEqual(managed.boolObj.count, 2U);
    XCTAssertEqualObjects([NSSet setWithArray:managed.boolObj.allObjects], ([NSSet setWithArray:@[@NO, @YES]]));
    XCTAssertEqual(managed.intObj.count, 3U);
    XCTAssertEqual(managed.floatObj.count, 3U);
    XCTAssertEqual(managed.doubleObj.count, 3U);
    XCTAssertEqual(managed.stringObj.count, 3U);
    XCTAssertEqual(managed.dataObj.count, 3U);
    XCTAssertEqual(managed.dateObj.count, 3U);
    XCTAssertEqual(managed.decimalObj.count, 3U);
    XCTAssertEqual(managed.objectIdObj.count, 3U);
    XCTAssertEqual(managed.uuidObj.count, 3U);
    XCTAssertEqualObjects([NSSet setWithArray:managed.intObj.allObjects], ([NSSet setWithArray:@[@2, @3, @4]]));
    XCTAssertEqualObjects([NSSet setWithArray:managed.floatObj.allObjects], ([NSSet setWithArray:@[@2.2f, @3.3f, @4.4f]]));
    XCTAssertEqualObjects([NSSet setWithArray:managed.doubleObj.allObjects], ([NSSet setWithArray:@[@2.2, @3.3, @4.4]]));
    XCTAssertEqualObjects([NSSet setWithArray:managed.stringObj.allObjects], ([NSSet setWithArray:@[@"a", @"bc", @"de"]]));
    XCTAssertEqualObjects([NSSet setWithArray:managed.dataObj.allObjects], ([NSSet setWithArray:@[data(1), data(2), data(3)]]));
    XCTAssertEqualObjects([NSSet setWithArray:managed.dateObj.allObjects], ([NSSet setWithArray:@[date(1), date(2), date(3)]]));
    XCTAssertEqualObjects([NSSet setWithArray:managed.decimalObj.allObjects], ([NSSet setWithArray:@[decimal128(1), decimal128(2), decimal128(3)]]));
    XCTAssertEqualObjects([NSSet setWithArray:managed.objectIdObj.allObjects], ([NSSet setWithArray:@[objectId(1), objectId(2), objectId(3)]]));
    XCTAssertEqualObjects([NSSet setWithArray:managed.uuidObj.allObjects], ([NSSet setWithArray:@[uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"), uuid(@"00000000-0000-0000-0000-000000000000"), uuid(@"123DECC8-B300-4954-A233-F89909F4FD89")]]));
    XCTAssertEqual(optManaged.boolObj.count, 3U);
    XCTAssertEqual(optManaged.intObj.count, 4U);
    XCTAssertEqual(optManaged.floatObj.count, 4U);
    XCTAssertEqual(optManaged.doubleObj.count, 4U);
    XCTAssertEqual(optManaged.stringObj.count, 4U);
    XCTAssertEqual(optManaged.dataObj.count, 4U);
    XCTAssertEqual(optManaged.dateObj.count, 4U);
    XCTAssertEqual(optManaged.decimalObj.count, 4U);
    XCTAssertEqual(optManaged.objectIdObj.count, 4U);
    XCTAssertEqual(optManaged.uuidObj.count, 4U);
}

- (void)testIntersect {
    [managed.boolObj addObjects:@[@NO, @YES]];
    [managed.intObj addObjects:@[@2, @3]];
    [managed.floatObj addObjects:@[@2.2f, @3.3f]];
    [managed.doubleObj addObjects:@[@2.2, @3.3]];
    [managed.stringObj addObjects:@[@"a", @"bc"]];
    [managed.dataObj addObjects:@[data(1), data(2)]];
    [managed.dateObj addObjects:@[date(1), date(2)]];
    [managed.decimalObj addObjects:@[decimal128(1), decimal128(2)]];
    [managed.objectIdObj addObjects:@[objectId(1), objectId(2)]];
    [managed.uuidObj addObjects:@[uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"), uuid(@"00000000-0000-0000-0000-000000000000")]];
    [optManaged.boolObj addObjects:@[NSNull.null, @NO, NSNull.null]];
    [optManaged.intObj addObjects:@[NSNull.null, @2, NSNull.null]];
    [optManaged.floatObj addObjects:@[NSNull.null, @2.2f, NSNull.null]];
    [optManaged.doubleObj addObjects:@[NSNull.null, @2.2, NSNull.null]];
    [optManaged.stringObj addObjects:@[NSNull.null, @"a", NSNull.null]];
    [optManaged.dataObj addObjects:@[NSNull.null, data(1), NSNull.null]];
    [optManaged.dateObj addObjects:@[NSNull.null, date(1), NSNull.null]];
    [optManaged.decimalObj addObjects:@[NSNull.null, decimal128(1), NSNull.null]];
    [optManaged.objectIdObj addObjects:@[NSNull.null, objectId(1), NSNull.null]];
    [optManaged.uuidObj addObjects:@[NSNull.null, uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"), NSNull.null]];
    [managed.boolObj2 addObjects:@[@YES, @NO]];
    [managed.intObj2 addObjects:@[@3, @4]];
    [managed.floatObj2 addObjects:@[@3.3f, @4.4f]];
    [managed.doubleObj2 addObjects:@[@3.3, @4.4]];
    [managed.stringObj2 addObjects:@[@"bc", @"de"]];
    [managed.dataObj2 addObjects:@[data(2), data(3)]];
    [managed.dateObj2 addObjects:@[date(2), date(3)]];
    [managed.decimalObj2 addObjects:@[decimal128(2), decimal128(3)]];
    [managed.objectIdObj2 addObjects:@[objectId(2), objectId(3)]];
    [managed.uuidObj2 addObjects:@[uuid(@"00000000-0000-0000-0000-000000000000"), uuid(@"123DECC8-B300-4954-A233-F89909F4FD89")]];
    [optManaged.boolObj2 addObjects:@[@YES, @NO, NSNull.null]];
    [optManaged.intObj2 addObjects:@[@3, @4, NSNull.null]];
    [optManaged.floatObj2 addObjects:@[@3.3f, @4.4f, NSNull.null]];
    [optManaged.doubleObj2 addObjects:@[@3.3, @4.4, NSNull.null]];
    [optManaged.stringObj2 addObjects:@[@"bc", @"de", NSNull.null]];
    [optManaged.dataObj2 addObjects:@[data(2), data(3), NSNull.null]];
    [optManaged.dateObj2 addObjects:@[date(2), date(3), NSNull.null]];
    [optManaged.decimalObj2 addObjects:@[decimal128(2), decimal128(3), NSNull.null]];
    [optManaged.objectIdObj2 addObjects:@[objectId(2), objectId(3), NSNull.null]];
    [optManaged.uuidObj2 addObjects:@[uuid(@"00000000-0000-0000-0000-000000000000"), uuid(@"123DECC8-B300-4954-A233-F89909F4FD89"), NSNull.null]];
    [realm commitWriteTransaction];

    [unmanaged.boolObj addObjects:@[@NO, @YES]];
    [unmanaged.intObj addObjects:@[@2, @3]];
    [unmanaged.floatObj addObjects:@[@2.2f, @3.3f]];
    [unmanaged.doubleObj addObjects:@[@2.2, @3.3]];
    [unmanaged.stringObj addObjects:@[@"a", @"bc"]];
    [unmanaged.dataObj addObjects:@[data(1), data(2)]];
    [unmanaged.dateObj addObjects:@[date(1), date(2)]];
    [unmanaged.decimalObj addObjects:@[decimal128(1), decimal128(2)]];
    [unmanaged.objectIdObj addObjects:@[objectId(1), objectId(2)]];
    [unmanaged.uuidObj addObjects:@[uuid(@"00000000-0000-0000-0000-000000000000"), uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")]];
    [optUnmanaged.boolObj addObjects:@[NSNull.null, @NO, NSNull.null]];
    [optUnmanaged.intObj addObjects:@[NSNull.null, @2, NSNull.null]];
    [optUnmanaged.floatObj addObjects:@[NSNull.null, @2.2f, NSNull.null]];
    [optUnmanaged.doubleObj addObjects:@[NSNull.null, @2.2, NSNull.null]];
    [optUnmanaged.stringObj addObjects:@[NSNull.null, @"a", NSNull.null]];
    [optUnmanaged.dataObj addObjects:@[NSNull.null, data(1), NSNull.null]];
    [optUnmanaged.dateObj addObjects:@[NSNull.null, date(1), NSNull.null]];
    [optUnmanaged.decimalObj addObjects:@[NSNull.null, decimal128(1), NSNull.null]];
    [optUnmanaged.objectIdObj addObjects:@[NSNull.null, objectId(1), NSNull.null]];
    [optUnmanaged.uuidObj addObjects:@[NSNull.null, uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"), NSNull.null]];
    [unmanaged.boolObj2 addObjects:@[@NO, @YES]];
    [unmanaged.intObj2 addObjects:@[@2, @4]];
    [unmanaged.floatObj2 addObjects:@[@2.2f, @4.4f]];
    [unmanaged.doubleObj2 addObjects:@[@2.2, @4.4]];
    [unmanaged.stringObj2 addObjects:@[@"a", @"de"]];
    [unmanaged.dataObj2 addObjects:@[data(1), data(3)]];
    [unmanaged.dateObj2 addObjects:@[date(1), date(3)]];
    [unmanaged.decimalObj2 addObjects:@[decimal128(1), decimal128(3)]];
    [unmanaged.objectIdObj2 addObjects:@[objectId(1), objectId(3)]];
    [unmanaged.uuidObj2 addObjects:@[uuid(@"00000000-0000-0000-0000-000000000000"), uuid(@"123DECC8-B300-4954-A233-F89909F4FD89")]];
    [optUnmanaged.boolObj2 addObjects:@[@YES, @NO, NSNull.null]];
    [optUnmanaged.intObj2 addObjects:@[@3, @4, NSNull.null]];
    [optUnmanaged.floatObj2 addObjects:@[@3.3f, @4.4f, NSNull.null]];
    [optUnmanaged.doubleObj2 addObjects:@[@3.3, @4.4, NSNull.null]];
    [optUnmanaged.stringObj2 addObjects:@[@"bc", @"de", NSNull.null]];
    [optUnmanaged.dataObj2 addObjects:@[data(2), data(3), NSNull.null]];
    [optUnmanaged.dateObj2 addObjects:@[date(2), date(3), NSNull.null]];
    [optUnmanaged.decimalObj2 addObjects:@[decimal128(2), decimal128(4), NSNull.null]];
    [optUnmanaged.objectIdObj2 addObjects:@[objectId(2), objectId(4), NSNull.null]];
    [optUnmanaged.uuidObj2 addObjects:@[uuid(@"00000000-0000-0000-0000-000000000000"), uuid(@"123DECC8-B300-4954-A233-F89909F4FD89"), NSNull.null]];

    XCTAssertThrows([managed.boolObj intersectSet:managed.boolObj2]);
    XCTAssertThrows([managed.intObj intersectSet:managed.intObj2]);
    XCTAssertThrows([managed.floatObj intersectSet:managed.floatObj2]);
    XCTAssertThrows([managed.doubleObj intersectSet:managed.doubleObj2]);
    XCTAssertThrows([managed.stringObj intersectSet:managed.stringObj2]);
    XCTAssertThrows([managed.dataObj intersectSet:managed.dataObj2]);
    XCTAssertThrows([managed.dateObj intersectSet:managed.dateObj2]);
    XCTAssertThrows([managed.decimalObj intersectSet:managed.decimalObj2]);
    XCTAssertThrows([managed.objectIdObj intersectSet:managed.objectIdObj2]);
    XCTAssertThrows([managed.uuidObj intersectSet:managed.uuidObj2]);
    XCTAssertThrows([optManaged.boolObj intersectSet:optManaged.boolObj2]);
    XCTAssertThrows([optManaged.intObj intersectSet:optManaged.intObj2]);
    XCTAssertThrows([optManaged.floatObj intersectSet:optManaged.floatObj2]);
    XCTAssertThrows([optManaged.doubleObj intersectSet:optManaged.doubleObj2]);
    XCTAssertThrows([optManaged.stringObj intersectSet:optManaged.stringObj2]);
    XCTAssertThrows([optManaged.dataObj intersectSet:optManaged.dataObj2]);
    XCTAssertThrows([optManaged.dateObj intersectSet:optManaged.dateObj2]);
    XCTAssertThrows([optManaged.decimalObj intersectSet:optManaged.decimalObj2]);
    XCTAssertThrows([optManaged.objectIdObj intersectSet:optManaged.objectIdObj2]);
    XCTAssertThrows([optManaged.uuidObj intersectSet:optManaged.uuidObj2]);
    XCTAssertTrue([managed.boolObj intersectsSet:managed.boolObj2]);
    XCTAssertTrue([managed.intObj intersectsSet:managed.intObj2]);
    XCTAssertTrue([managed.floatObj intersectsSet:managed.floatObj2]);
    XCTAssertTrue([managed.doubleObj intersectsSet:managed.doubleObj2]);
    XCTAssertTrue([managed.stringObj intersectsSet:managed.stringObj2]);
    XCTAssertTrue([managed.dataObj intersectsSet:managed.dataObj2]);
    XCTAssertTrue([managed.dateObj intersectsSet:managed.dateObj2]);
    XCTAssertTrue([managed.decimalObj intersectsSet:managed.decimalObj2]);
    XCTAssertTrue([managed.objectIdObj intersectsSet:managed.objectIdObj2]);
    XCTAssertTrue([managed.uuidObj intersectsSet:managed.uuidObj2]);
    XCTAssertTrue([optManaged.boolObj intersectsSet:optManaged.boolObj2]);
    XCTAssertTrue([optManaged.intObj intersectsSet:optManaged.intObj2]);
    XCTAssertTrue([optManaged.floatObj intersectsSet:optManaged.floatObj2]);
    XCTAssertTrue([optManaged.doubleObj intersectsSet:optManaged.doubleObj2]);
    XCTAssertTrue([optManaged.stringObj intersectsSet:optManaged.stringObj2]);
    XCTAssertTrue([optManaged.dataObj intersectsSet:optManaged.dataObj2]);
    XCTAssertTrue([optManaged.dateObj intersectsSet:optManaged.dateObj2]);
    XCTAssertTrue([optManaged.decimalObj intersectsSet:optManaged.decimalObj2]);
    XCTAssertTrue([optManaged.objectIdObj intersectsSet:optManaged.objectIdObj2]);
    XCTAssertTrue([optManaged.uuidObj intersectsSet:optManaged.uuidObj2]);
    XCTAssertTrue([unmanaged.boolObj intersectsSet:unmanaged.boolObj2]);
    XCTAssertTrue([unmanaged.intObj intersectsSet:unmanaged.intObj2]);
    XCTAssertTrue([unmanaged.floatObj intersectsSet:unmanaged.floatObj2]);
    XCTAssertTrue([unmanaged.doubleObj intersectsSet:unmanaged.doubleObj2]);
    XCTAssertTrue([unmanaged.stringObj intersectsSet:unmanaged.stringObj2]);
    XCTAssertTrue([unmanaged.dataObj intersectsSet:unmanaged.dataObj2]);
    XCTAssertTrue([unmanaged.dateObj intersectsSet:unmanaged.dateObj2]);
    XCTAssertTrue([unmanaged.decimalObj intersectsSet:unmanaged.decimalObj2]);
    XCTAssertTrue([unmanaged.objectIdObj intersectsSet:unmanaged.objectIdObj2]);
    XCTAssertTrue([unmanaged.uuidObj intersectsSet:unmanaged.uuidObj2]);
    XCTAssertTrue([optUnmanaged.boolObj intersectsSet:optUnmanaged.boolObj2]);
    XCTAssertTrue([optUnmanaged.intObj intersectsSet:optUnmanaged.intObj2]);
    XCTAssertTrue([optUnmanaged.floatObj intersectsSet:optUnmanaged.floatObj2]);
    XCTAssertTrue([optUnmanaged.doubleObj intersectsSet:optUnmanaged.doubleObj2]);
    XCTAssertTrue([optUnmanaged.stringObj intersectsSet:optUnmanaged.stringObj2]);
    XCTAssertTrue([optUnmanaged.dataObj intersectsSet:optUnmanaged.dataObj2]);
    XCTAssertTrue([optUnmanaged.dateObj intersectsSet:optUnmanaged.dateObj2]);
    XCTAssertTrue([optUnmanaged.decimalObj intersectsSet:optUnmanaged.decimalObj2]);
    XCTAssertTrue([optUnmanaged.objectIdObj intersectsSet:optUnmanaged.objectIdObj2]);
    XCTAssertTrue([optUnmanaged.uuidObj intersectsSet:optUnmanaged.uuidObj2]);

    [unmanaged.boolObj intersectSet:unmanaged.boolObj2];
    [unmanaged.intObj intersectSet:unmanaged.intObj2];
    [unmanaged.floatObj intersectSet:unmanaged.floatObj2];
    [unmanaged.doubleObj intersectSet:unmanaged.doubleObj2];
    [unmanaged.stringObj intersectSet:unmanaged.stringObj2];
    [unmanaged.dataObj intersectSet:unmanaged.dataObj2];
    [unmanaged.dateObj intersectSet:unmanaged.dateObj2];
    [unmanaged.decimalObj intersectSet:unmanaged.decimalObj2];
    [unmanaged.objectIdObj intersectSet:unmanaged.objectIdObj2];
    [unmanaged.uuidObj intersectSet:unmanaged.uuidObj2];
    [optUnmanaged.boolObj intersectSet:optUnmanaged.boolObj2];
    [optUnmanaged.intObj intersectSet:optUnmanaged.intObj2];
    [optUnmanaged.floatObj intersectSet:optUnmanaged.floatObj2];
    [optUnmanaged.doubleObj intersectSet:optUnmanaged.doubleObj2];
    [optUnmanaged.stringObj intersectSet:optUnmanaged.stringObj2];
    [optUnmanaged.dataObj intersectSet:optUnmanaged.dataObj2];
    [optUnmanaged.dateObj intersectSet:optUnmanaged.dateObj2];
    [optUnmanaged.decimalObj intersectSet:optUnmanaged.decimalObj2];
    [optUnmanaged.objectIdObj intersectSet:optUnmanaged.objectIdObj2];
    [optUnmanaged.uuidObj intersectSet:optUnmanaged.uuidObj2];

    [realm beginWriteTransaction];
    [managed.boolObj intersectSet:managed.boolObj2];
    [managed.intObj intersectSet:managed.intObj2];
    [managed.floatObj intersectSet:managed.floatObj2];
    [managed.doubleObj intersectSet:managed.doubleObj2];
    [managed.stringObj intersectSet:managed.stringObj2];
    [managed.dataObj intersectSet:managed.dataObj2];
    [managed.dateObj intersectSet:managed.dateObj2];
    [managed.decimalObj intersectSet:managed.decimalObj2];
    [managed.objectIdObj intersectSet:managed.objectIdObj2];
    [managed.uuidObj intersectSet:managed.uuidObj2];
    [optManaged.boolObj intersectSet:optManaged.boolObj2];
    [optManaged.intObj intersectSet:optManaged.intObj2];
    [optManaged.floatObj intersectSet:optManaged.floatObj2];
    [optManaged.doubleObj intersectSet:optManaged.doubleObj2];
    [optManaged.stringObj intersectSet:optManaged.stringObj2];
    [optManaged.dataObj intersectSet:optManaged.dataObj2];
    [optManaged.dateObj intersectSet:optManaged.dateObj2];
    [optManaged.decimalObj intersectSet:optManaged.decimalObj2];
    [optManaged.objectIdObj intersectSet:optManaged.objectIdObj2];
    [optManaged.uuidObj intersectSet:optManaged.uuidObj2];
    [realm commitWriteTransaction];

    XCTAssertEqual(unmanaged.boolObj.count, 2U);
    XCTAssertEqualObjects([NSSet setWithArray:unmanaged.boolObj.allObjects], ([NSSet setWithArray:@[@NO, @YES]]));
    XCTAssertEqual(unmanaged.intObj.count, 1U);
    XCTAssertEqual(unmanaged.floatObj.count, 1U);
    XCTAssertEqual(unmanaged.doubleObj.count, 1U);
    XCTAssertEqual(unmanaged.stringObj.count, 1U);
    XCTAssertEqual(unmanaged.dataObj.count, 1U);
    XCTAssertEqual(unmanaged.dateObj.count, 1U);
    XCTAssertEqual(unmanaged.decimalObj.count, 1U);
    XCTAssertEqual(unmanaged.objectIdObj.count, 1U);
    XCTAssertEqual(unmanaged.uuidObj.count, 1U);
    XCTAssertEqualObjects(unmanaged.intObj.allObjects, (@[@2]));
    XCTAssertEqualObjects(unmanaged.floatObj.allObjects, (@[@2.2f]));
    XCTAssertEqualObjects(unmanaged.doubleObj.allObjects, (@[@2.2]));
    XCTAssertEqualObjects(unmanaged.stringObj.allObjects, (@[@"a"]));
    XCTAssertEqualObjects(unmanaged.dataObj.allObjects, (@[data(1)]));
    XCTAssertEqualObjects(unmanaged.dateObj.allObjects, (@[date(1)]));
    XCTAssertEqualObjects(unmanaged.decimalObj.allObjects, (@[decimal128(1)]));
    XCTAssertEqualObjects(unmanaged.objectIdObj.allObjects, (@[objectId(1)]));
    XCTAssertEqualObjects(unmanaged.uuidObj.allObjects, (@[uuid(@"00000000-0000-0000-0000-000000000000")]));
    XCTAssertEqual(optUnmanaged.boolObj.count, 2U);
    XCTAssertEqualObjects([NSSet setWithArray:optUnmanaged.boolObj.allObjects], ([NSSet setWithArray:@[NSNull.null, @NO]]));
    XCTAssertEqual(optUnmanaged.intObj.count, 1U);
    XCTAssertEqual(optUnmanaged.floatObj.count, 1U);
    XCTAssertEqual(optUnmanaged.doubleObj.count, 1U);
    XCTAssertEqual(optUnmanaged.stringObj.count, 1U);
    XCTAssertEqual(optUnmanaged.dataObj.count, 1U);
    XCTAssertEqual(optUnmanaged.dateObj.count, 1U);
    XCTAssertEqual(optUnmanaged.decimalObj.count, 1U);
    XCTAssertEqual(optUnmanaged.objectIdObj.count, 1U);
    XCTAssertEqual(optUnmanaged.uuidObj.count, 1U);
    XCTAssertEqualObjects([NSSet setWithArray:optUnmanaged.intObj.allObjects], ([NSSet setWithArray:@[NSNull.null]]));
    XCTAssertEqualObjects([NSSet setWithArray:optUnmanaged.floatObj.allObjects], ([NSSet setWithArray:@[NSNull.null]]));
    XCTAssertEqualObjects([NSSet setWithArray:optUnmanaged.doubleObj.allObjects], ([NSSet setWithArray:@[NSNull.null]]));
    XCTAssertEqualObjects([NSSet setWithArray:optUnmanaged.stringObj.allObjects], ([NSSet setWithArray:@[NSNull.null]]));
    XCTAssertEqualObjects([NSSet setWithArray:optUnmanaged.dataObj.allObjects], ([NSSet setWithArray:@[NSNull.null]]));
    XCTAssertEqualObjects([NSSet setWithArray:optUnmanaged.dateObj.allObjects], ([NSSet setWithArray:@[NSNull.null]]));
    XCTAssertEqualObjects([NSSet setWithArray:optUnmanaged.decimalObj.allObjects], ([NSSet setWithArray:@[NSNull.null]]));
    XCTAssertEqualObjects([NSSet setWithArray:optUnmanaged.objectIdObj.allObjects], ([NSSet setWithArray:@[NSNull.null]]));
    XCTAssertEqualObjects([NSSet setWithArray:optUnmanaged.uuidObj.allObjects], ([NSSet setWithArray:@[NSNull.null]]));
    XCTAssertEqual(managed.boolObj.count, 2U);
    XCTAssertEqualObjects([NSSet setWithArray:managed.boolObj.allObjects], ([NSSet setWithArray:@[@NO, @YES]]));
    XCTAssertEqual(managed.intObj.count, 1U);
    XCTAssertEqual(managed.floatObj.count, 1U);
    XCTAssertEqual(managed.doubleObj.count, 1U);
    XCTAssertEqual(managed.stringObj.count, 1U);
    XCTAssertEqual(managed.dataObj.count, 1U);
    XCTAssertEqual(managed.dateObj.count, 1U);
    XCTAssertEqual(managed.decimalObj.count, 1U);
    XCTAssertEqual(managed.objectIdObj.count, 1U);
    XCTAssertEqual(managed.uuidObj.count, 1U);
    XCTAssertEqualObjects(managed.intObj.allObjects, (@[@3]));
    XCTAssertEqualObjects(managed.floatObj.allObjects, (@[@3.3f]));
    XCTAssertEqualObjects(managed.doubleObj.allObjects, (@[@3.3]));
    XCTAssertEqualObjects(managed.stringObj.allObjects, (@[@"bc"]));
    XCTAssertEqualObjects(managed.dataObj.allObjects, (@[data(2)]));
    XCTAssertEqualObjects(managed.dateObj.allObjects, (@[date(2)]));
    XCTAssertEqualObjects(managed.decimalObj.allObjects, (@[decimal128(2)]));
    XCTAssertEqualObjects(managed.objectIdObj.allObjects, (@[objectId(2)]));
    XCTAssertEqualObjects(managed.uuidObj.allObjects, (@[uuid(@"00000000-0000-0000-0000-000000000000")]));
    XCTAssertEqual(optManaged.boolObj.count, 2U);
    XCTAssertEqualObjects([NSSet setWithArray:optManaged.boolObj.allObjects], ([NSSet setWithArray:@[NSNull.null, @NO]]));
    XCTAssertEqual(optManaged.intObj.count, 1U);
    XCTAssertEqual(optManaged.floatObj.count, 1U);
    XCTAssertEqual(optManaged.doubleObj.count, 1U);
    XCTAssertEqual(optManaged.stringObj.count, 1U);
    XCTAssertEqual(optManaged.dataObj.count, 1U);
    XCTAssertEqual(optManaged.dateObj.count, 1U);
    XCTAssertEqual(optManaged.decimalObj.count, 1U);
    XCTAssertEqual(optManaged.objectIdObj.count, 1U);
    XCTAssertEqual(optManaged.uuidObj.count, 1U);
    XCTAssertEqualObjects(optManaged.intObj.allObjects, (@[NSNull.null]));
    XCTAssertEqualObjects(optManaged.floatObj.allObjects, (@[NSNull.null]));
    XCTAssertEqualObjects(optManaged.doubleObj.allObjects, (@[NSNull.null]));
    XCTAssertEqualObjects(optManaged.stringObj.allObjects, (@[NSNull.null]));
    XCTAssertEqualObjects(optManaged.dataObj.allObjects, (@[NSNull.null]));
    XCTAssertEqualObjects(optManaged.dateObj.allObjects, (@[NSNull.null]));
    XCTAssertEqualObjects(optManaged.decimalObj.allObjects, (@[NSNull.null]));
    XCTAssertEqualObjects(optManaged.objectIdObj.allObjects, (@[NSNull.null]));
    XCTAssertEqualObjects(optManaged.uuidObj.allObjects, (@[NSNull.null]));
}

- (void)testMinus {
    [managed.boolObj addObjects:@[@NO, @YES]];
    [managed.intObj addObjects:@[@2, @3]];
    [managed.floatObj addObjects:@[@2.2f, @3.3f]];
    [managed.doubleObj addObjects:@[@2.2, @3.3]];
    [managed.stringObj addObjects:@[@"a", @"bc"]];
    [managed.dataObj addObjects:@[data(1), data(2)]];
    [managed.dateObj addObjects:@[date(1), date(2)]];
    [managed.decimalObj addObjects:@[decimal128(1), decimal128(2)]];
    [managed.objectIdObj addObjects:@[objectId(1), objectId(2)]];
    [managed.uuidObj addObjects:@[uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"), uuid(@"00000000-0000-0000-0000-000000000000")]];
    [optManaged.boolObj addObjects:@[NSNull.null, @NO, NSNull.null]];
    [optManaged.intObj addObjects:@[NSNull.null, @2, NSNull.null]];
    [optManaged.floatObj addObjects:@[NSNull.null, @2.2f, NSNull.null]];
    [optManaged.doubleObj addObjects:@[NSNull.null, @2.2, NSNull.null]];
    [optManaged.stringObj addObjects:@[NSNull.null, @"a", NSNull.null]];
    [optManaged.dataObj addObjects:@[NSNull.null, data(1), NSNull.null]];
    [optManaged.dateObj addObjects:@[NSNull.null, date(1), NSNull.null]];
    [optManaged.decimalObj addObjects:@[NSNull.null, decimal128(1), NSNull.null]];
    [optManaged.objectIdObj addObjects:@[NSNull.null, objectId(1), NSNull.null]];
    [optManaged.uuidObj addObjects:@[NSNull.null, uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"), NSNull.null]];
    [managed.boolObj2 addObjects:@[@YES, @NO]];
    [managed.intObj2 addObjects:@[@3, @4]];
    [managed.floatObj2 addObjects:@[@3.3f, @4.4f]];
    [managed.doubleObj2 addObjects:@[@3.3, @4.4]];
    [managed.stringObj2 addObjects:@[@"bc", @"de"]];
    [managed.dataObj2 addObjects:@[data(2), data(3)]];
    [managed.dateObj2 addObjects:@[date(2), date(3)]];
    [managed.decimalObj2 addObjects:@[decimal128(2), decimal128(3)]];
    [managed.objectIdObj2 addObjects:@[objectId(2), objectId(3)]];
    [managed.uuidObj2 addObjects:@[uuid(@"00000000-0000-0000-0000-000000000000"), uuid(@"123DECC8-B300-4954-A233-F89909F4FD89")]];
    [optManaged.boolObj2 addObjects:@[@YES, @NO, NSNull.null]];
    [optManaged.intObj2 addObjects:@[@3, @4, NSNull.null]];
    [optManaged.floatObj2 addObjects:@[@3.3f, @4.4f, NSNull.null]];
    [optManaged.doubleObj2 addObjects:@[@3.3, @4.4, NSNull.null]];
    [optManaged.stringObj2 addObjects:@[@"bc", @"de", NSNull.null]];
    [optManaged.dataObj2 addObjects:@[data(2), data(3), NSNull.null]];
    [optManaged.dateObj2 addObjects:@[date(2), date(3), NSNull.null]];
    [optManaged.decimalObj2 addObjects:@[decimal128(2), decimal128(3), NSNull.null]];
    [optManaged.objectIdObj2 addObjects:@[objectId(2), objectId(3), NSNull.null]];
    [optManaged.uuidObj2 addObjects:@[uuid(@"00000000-0000-0000-0000-000000000000"), uuid(@"123DECC8-B300-4954-A233-F89909F4FD89"), NSNull.null]];
    [realm commitWriteTransaction];

    [unmanaged.boolObj addObjects:@[@NO, @YES]];
    [unmanaged.intObj addObjects:@[@2, @3]];
    [unmanaged.floatObj addObjects:@[@2.2f, @3.3f]];
    [unmanaged.doubleObj addObjects:@[@2.2, @3.3]];
    [unmanaged.stringObj addObjects:@[@"a", @"bc"]];
    [unmanaged.dataObj addObjects:@[data(1), data(2)]];
    [unmanaged.dateObj addObjects:@[date(1), date(2)]];
    [unmanaged.decimalObj addObjects:@[decimal128(1), decimal128(2)]];
    [unmanaged.objectIdObj addObjects:@[objectId(1), objectId(2)]];
    [unmanaged.uuidObj addObjects:@[uuid(@"00000000-0000-0000-0000-000000000000"), uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")]];
    [optUnmanaged.boolObj addObjects:@[NSNull.null, @NO, NSNull.null]];
    [optUnmanaged.intObj addObjects:@[NSNull.null, @2, NSNull.null]];
    [optUnmanaged.floatObj addObjects:@[NSNull.null, @2.2f, NSNull.null]];
    [optUnmanaged.doubleObj addObjects:@[NSNull.null, @2.2, NSNull.null]];
    [optUnmanaged.stringObj addObjects:@[NSNull.null, @"a", NSNull.null]];
    [optUnmanaged.dataObj addObjects:@[NSNull.null, data(1), NSNull.null]];
    [optUnmanaged.dateObj addObjects:@[NSNull.null, date(1), NSNull.null]];
    [optUnmanaged.decimalObj addObjects:@[NSNull.null, decimal128(1), NSNull.null]];
    [optUnmanaged.objectIdObj addObjects:@[NSNull.null, objectId(1), NSNull.null]];
    [optUnmanaged.uuidObj addObjects:@[NSNull.null, uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"), NSNull.null]];
    [unmanaged.boolObj2 addObjects:@[@NO, @YES]];
    [unmanaged.intObj2 addObjects:@[@2, @4]];
    [unmanaged.floatObj2 addObjects:@[@2.2f, @4.4f]];
    [unmanaged.doubleObj2 addObjects:@[@2.2, @4.4]];
    [unmanaged.stringObj2 addObjects:@[@"a", @"de"]];
    [unmanaged.dataObj2 addObjects:@[data(1), data(3)]];
    [unmanaged.dateObj2 addObjects:@[date(1), date(3)]];
    [unmanaged.decimalObj2 addObjects:@[decimal128(1), decimal128(3)]];
    [unmanaged.objectIdObj2 addObjects:@[objectId(1), objectId(3)]];
    [unmanaged.uuidObj2 addObjects:@[uuid(@"00000000-0000-0000-0000-000000000000"), uuid(@"123DECC8-B300-4954-A233-F89909F4FD89")]];
    [optUnmanaged.boolObj2 addObjects:@[@YES, @NO, NSNull.null]];
    [optUnmanaged.intObj2 addObjects:@[@3, @4, NSNull.null]];
    [optUnmanaged.floatObj2 addObjects:@[@3.3f, @4.4f, NSNull.null]];
    [optUnmanaged.doubleObj2 addObjects:@[@3.3, @4.4, NSNull.null]];
    [optUnmanaged.stringObj2 addObjects:@[@"bc", @"de", NSNull.null]];
    [optUnmanaged.dataObj2 addObjects:@[data(2), data(3), NSNull.null]];
    [optUnmanaged.dateObj2 addObjects:@[date(2), date(3), NSNull.null]];
    [optUnmanaged.decimalObj2 addObjects:@[decimal128(2), decimal128(4), NSNull.null]];
    [optUnmanaged.objectIdObj2 addObjects:@[objectId(2), objectId(4), NSNull.null]];
    [optUnmanaged.uuidObj2 addObjects:@[uuid(@"00000000-0000-0000-0000-000000000000"), uuid(@"123DECC8-B300-4954-A233-F89909F4FD89"), NSNull.null]];

    XCTAssertThrows([managed.boolObj minusSet:managed.boolObj2]);
    XCTAssertThrows([managed.intObj minusSet:managed.intObj2]);
    XCTAssertThrows([managed.floatObj minusSet:managed.floatObj2]);
    XCTAssertThrows([managed.doubleObj minusSet:managed.doubleObj2]);
    XCTAssertThrows([managed.stringObj minusSet:managed.stringObj2]);
    XCTAssertThrows([managed.dataObj minusSet:managed.dataObj2]);
    XCTAssertThrows([managed.dateObj minusSet:managed.dateObj2]);
    XCTAssertThrows([managed.decimalObj minusSet:managed.decimalObj2]);
    XCTAssertThrows([managed.objectIdObj minusSet:managed.objectIdObj2]);
    XCTAssertThrows([managed.uuidObj minusSet:managed.uuidObj2]);
    XCTAssertThrows([optManaged.boolObj minusSet:optManaged.boolObj2]);
    XCTAssertThrows([optManaged.intObj minusSet:optManaged.intObj2]);
    XCTAssertThrows([optManaged.floatObj minusSet:optManaged.floatObj2]);
    XCTAssertThrows([optManaged.doubleObj minusSet:optManaged.doubleObj2]);
    XCTAssertThrows([optManaged.stringObj minusSet:optManaged.stringObj2]);
    XCTAssertThrows([optManaged.dataObj minusSet:optManaged.dataObj2]);
    XCTAssertThrows([optManaged.dateObj minusSet:optManaged.dateObj2]);
    XCTAssertThrows([optManaged.decimalObj minusSet:optManaged.decimalObj2]);
    XCTAssertThrows([optManaged.objectIdObj minusSet:optManaged.objectIdObj2]);
    XCTAssertThrows([optManaged.uuidObj minusSet:optManaged.uuidObj2]);

    [unmanaged.boolObj minusSet:unmanaged.boolObj2];
    [unmanaged.intObj minusSet:unmanaged.intObj2];
    [unmanaged.floatObj minusSet:unmanaged.floatObj2];
    [unmanaged.doubleObj minusSet:unmanaged.doubleObj2];
    [unmanaged.stringObj minusSet:unmanaged.stringObj2];
    [unmanaged.dataObj minusSet:unmanaged.dataObj2];
    [unmanaged.dateObj minusSet:unmanaged.dateObj2];
    [unmanaged.decimalObj minusSet:unmanaged.decimalObj2];
    [unmanaged.objectIdObj minusSet:unmanaged.objectIdObj2];
    [unmanaged.uuidObj minusSet:unmanaged.uuidObj2];
    [optUnmanaged.boolObj minusSet:optUnmanaged.boolObj2];
    [optUnmanaged.intObj minusSet:optUnmanaged.intObj2];
    [optUnmanaged.floatObj minusSet:optUnmanaged.floatObj2];
    [optUnmanaged.doubleObj minusSet:optUnmanaged.doubleObj2];
    [optUnmanaged.stringObj minusSet:optUnmanaged.stringObj2];
    [optUnmanaged.dataObj minusSet:optUnmanaged.dataObj2];
    [optUnmanaged.dateObj minusSet:optUnmanaged.dateObj2];
    [optUnmanaged.decimalObj minusSet:optUnmanaged.decimalObj2];
    [optUnmanaged.objectIdObj minusSet:optUnmanaged.objectIdObj2];
    [optUnmanaged.uuidObj minusSet:optUnmanaged.uuidObj2];

    [realm beginWriteTransaction];
    [managed.boolObj minusSet:managed.boolObj2];
    [managed.intObj minusSet:managed.intObj2];
    [managed.floatObj minusSet:managed.floatObj2];
    [managed.doubleObj minusSet:managed.doubleObj2];
    [managed.stringObj minusSet:managed.stringObj2];
    [managed.dataObj minusSet:managed.dataObj2];
    [managed.dateObj minusSet:managed.dateObj2];
    [managed.decimalObj minusSet:managed.decimalObj2];
    [managed.objectIdObj minusSet:managed.objectIdObj2];
    [managed.uuidObj minusSet:managed.uuidObj2];
    [optManaged.boolObj minusSet:optManaged.boolObj2];
    [optManaged.intObj minusSet:optManaged.intObj2];
    [optManaged.floatObj minusSet:optManaged.floatObj2];
    [optManaged.doubleObj minusSet:optManaged.doubleObj2];
    [optManaged.stringObj minusSet:optManaged.stringObj2];
    [optManaged.dataObj minusSet:optManaged.dataObj2];
    [optManaged.dateObj minusSet:optManaged.dateObj2];
    [optManaged.decimalObj minusSet:optManaged.decimalObj2];
    [optManaged.objectIdObj minusSet:optManaged.objectIdObj2];
    [optManaged.uuidObj minusSet:optManaged.uuidObj2];
    [realm commitWriteTransaction];

    XCTAssertEqual(unmanaged.boolObj.count, 0U);
    XCTAssertEqualObjects(unmanaged.boolObj.allObjects, (@[]));
    XCTAssertEqual(unmanaged.intObj.count, 1U);
    XCTAssertEqual(unmanaged.floatObj.count, 1U);
    XCTAssertEqual(unmanaged.doubleObj.count, 1U);
    XCTAssertEqual(unmanaged.stringObj.count, 1U);
    XCTAssertEqual(unmanaged.dataObj.count, 1U);
    XCTAssertEqual(unmanaged.dateObj.count, 1U);
    XCTAssertEqual(unmanaged.decimalObj.count, 1U);
    XCTAssertEqual(unmanaged.objectIdObj.count, 1U);
    XCTAssertEqual(unmanaged.uuidObj.count, 1U);
    XCTAssertEqualObjects(unmanaged.intObj.allObjects, (@[@3]));
    XCTAssertEqualObjects(unmanaged.floatObj.allObjects, (@[@3.3f]));
    XCTAssertEqualObjects(unmanaged.doubleObj.allObjects, (@[@3.3]));
    XCTAssertEqualObjects(unmanaged.stringObj.allObjects, (@[@"bc"]));
    XCTAssertEqualObjects(unmanaged.dataObj.allObjects, (@[data(2)]));
    XCTAssertEqualObjects(unmanaged.dateObj.allObjects, (@[date(2)]));
    XCTAssertEqualObjects(unmanaged.decimalObj.allObjects, (@[decimal128(2)]));
    XCTAssertEqualObjects(unmanaged.objectIdObj.allObjects, (@[objectId(2)]));
    XCTAssertEqualObjects(unmanaged.uuidObj.allObjects, (@[uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")]));
    XCTAssertEqual(optUnmanaged.boolObj.count, 0U);
    XCTAssertEqualObjects(optUnmanaged.boolObj.allObjects, (@[]));
    XCTAssertEqual(optUnmanaged.intObj.count, 1U);
    XCTAssertEqual(optUnmanaged.floatObj.count, 1U);
    XCTAssertEqual(optUnmanaged.doubleObj.count, 1U);
    XCTAssertEqual(optUnmanaged.stringObj.count, 1U);
    XCTAssertEqual(optUnmanaged.dataObj.count, 1U);
    XCTAssertEqual(optUnmanaged.dateObj.count, 1U);
    XCTAssertEqual(optUnmanaged.decimalObj.count, 1U);
    XCTAssertEqual(optUnmanaged.objectIdObj.count, 1U);
    XCTAssertEqual(optUnmanaged.uuidObj.count, 1U);
    XCTAssertEqualObjects(optUnmanaged.intObj.allObjects, (@[@2]));
    XCTAssertEqualObjects(optUnmanaged.floatObj.allObjects, (@[@2.2f]));
    XCTAssertEqualObjects(optUnmanaged.doubleObj.allObjects, (@[@2.2]));
    XCTAssertEqualObjects(optUnmanaged.stringObj.allObjects, (@[@"a"]));
    XCTAssertEqualObjects(optUnmanaged.dataObj.allObjects, (@[data(1)]));
    XCTAssertEqualObjects(optUnmanaged.dateObj.allObjects, (@[date(1)]));
    XCTAssertEqualObjects(optUnmanaged.decimalObj.allObjects, (@[decimal128(1)]));
    XCTAssertEqualObjects(optUnmanaged.objectIdObj.allObjects, (@[objectId(1)]));
    XCTAssertEqualObjects(optUnmanaged.uuidObj.allObjects, (@[uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")]));
    XCTAssertEqual(managed.boolObj.count, 0U);
    XCTAssertEqualObjects(managed.boolObj.allObjects, (@[]));
    XCTAssertEqual(managed.intObj.count, 1U);
    XCTAssertEqual(managed.floatObj.count, 1U);
    XCTAssertEqual(managed.doubleObj.count, 1U);
    XCTAssertEqual(managed.stringObj.count, 1U);
    XCTAssertEqual(managed.dataObj.count, 1U);
    XCTAssertEqual(managed.dateObj.count, 1U);
    XCTAssertEqual(managed.decimalObj.count, 1U);
    XCTAssertEqual(managed.objectIdObj.count, 1U);
    XCTAssertEqual(managed.uuidObj.count, 1U);
    XCTAssertEqualObjects(managed.intObj.allObjects, (@[@2]));
    XCTAssertEqualObjects(managed.floatObj.allObjects, (@[@2.2f]));
    XCTAssertEqualObjects(managed.doubleObj.allObjects, (@[@2.2]));
    XCTAssertEqualObjects(managed.stringObj.allObjects, (@[@"a"]));
    XCTAssertEqualObjects(managed.dataObj.allObjects, (@[data(1)]));
    XCTAssertEqualObjects(managed.dateObj.allObjects, (@[date(1)]));
    XCTAssertEqualObjects(managed.decimalObj.allObjects, (@[decimal128(1)]));
    XCTAssertEqualObjects(managed.objectIdObj.allObjects, (@[objectId(1)]));
    XCTAssertEqualObjects(managed.uuidObj.allObjects, (@[uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")]));
    XCTAssertEqual(optManaged.boolObj.count, 0U);
    XCTAssertEqualObjects(optManaged.boolObj.allObjects, (@[]));
    XCTAssertEqual(optManaged.intObj.count, 1U);
    XCTAssertEqual(optManaged.floatObj.count, 1U);
    XCTAssertEqual(optManaged.doubleObj.count, 1U);
    XCTAssertEqual(optManaged.stringObj.count, 1U);
    XCTAssertEqual(optManaged.dataObj.count, 1U);
    XCTAssertEqual(optManaged.dateObj.count, 1U);
    XCTAssertEqual(optManaged.decimalObj.count, 1U);
    XCTAssertEqual(optManaged.objectIdObj.count, 1U);
    XCTAssertEqual(optManaged.uuidObj.count, 1U);
    XCTAssertEqualObjects(optManaged.intObj.allObjects, (@[@2]));
    XCTAssertEqualObjects(optManaged.floatObj.allObjects, (@[@2.2f]));
    XCTAssertEqualObjects(optManaged.doubleObj.allObjects, (@[@2.2]));
    XCTAssertEqualObjects(optManaged.stringObj.allObjects, (@[@"a"]));
    XCTAssertEqualObjects(optManaged.dataObj.allObjects, (@[data(1)]));
    XCTAssertEqualObjects(optManaged.dateObj.allObjects, (@[date(1)]));
    XCTAssertEqualObjects(optManaged.decimalObj.allObjects, (@[decimal128(1)]));
    XCTAssertEqualObjects(optManaged.objectIdObj.allObjects, (@[objectId(1)]));
    XCTAssertEqualObjects(optManaged.uuidObj.allObjects, (@[uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")]));
}

- (void)testIsSubsetOfSet {
    [managed.boolObj addObjects:@[@NO, @YES]];
    [managed.intObj addObjects:@[@2, @3]];
    [managed.floatObj addObjects:@[@2.2f, @3.3f]];
    [managed.doubleObj addObjects:@[@2.2, @3.3]];
    [managed.stringObj addObjects:@[@"a", @"bc"]];
    [managed.dataObj addObjects:@[data(1), data(2)]];
    [managed.dateObj addObjects:@[date(1), date(2)]];
    [managed.decimalObj addObjects:@[decimal128(1), decimal128(2)]];
    [managed.objectIdObj addObjects:@[objectId(1), objectId(2)]];
    [managed.uuidObj addObjects:@[uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"), uuid(@"00000000-0000-0000-0000-000000000000")]];
    [optManaged.boolObj addObjects:@[NSNull.null, @NO, NSNull.null]];
    [optManaged.intObj addObjects:@[NSNull.null, @2, NSNull.null]];
    [optManaged.floatObj addObjects:@[NSNull.null, @2.2f, NSNull.null]];
    [optManaged.doubleObj addObjects:@[NSNull.null, @2.2, NSNull.null]];
    [optManaged.stringObj addObjects:@[NSNull.null, @"a", NSNull.null]];
    [optManaged.dataObj addObjects:@[NSNull.null, data(1), NSNull.null]];
    [optManaged.dateObj addObjects:@[NSNull.null, date(1), NSNull.null]];
    [optManaged.decimalObj addObjects:@[NSNull.null, decimal128(1), NSNull.null]];
    [optManaged.objectIdObj addObjects:@[NSNull.null, objectId(1), NSNull.null]];
    [optManaged.uuidObj addObjects:@[NSNull.null, uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"), NSNull.null]];
    [managed.boolObj2 addObjects:@[@NO, @YES, @YES, @NO]];
    [managed.intObj2 addObjects:@[@2, @3, @3, @4]];
    [managed.floatObj2 addObjects:@[@2.2f, @3.3f, @3.3f, @4.4f]];
    [managed.doubleObj2 addObjects:@[@2.2, @3.3, @3.3, @4.4]];
    [managed.stringObj2 addObjects:@[@"a", @"bc", @"bc", @"de"]];
    [managed.dataObj2 addObjects:@[data(1), data(2), data(2), data(3)]];
    [managed.dateObj2 addObjects:@[date(1), date(2), date(2), date(3)]];
    [managed.decimalObj2 addObjects:@[decimal128(1), decimal128(2), decimal128(2), decimal128(3)]];
    [managed.objectIdObj2 addObjects:@[objectId(1), objectId(2), objectId(2), objectId(3)]];
    [managed.uuidObj2 addObjects:@[uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"), uuid(@"00000000-0000-0000-0000-000000000000"), uuid(@"00000000-0000-0000-0000-000000000000"), uuid(@"123DECC8-B300-4954-A233-F89909F4FD89")]];
    [optManaged.boolObj2 addObjects:@[NSNull.null, @NO, @YES, @NO, NSNull.null]];
    [optManaged.intObj2 addObjects:@[NSNull.null, @2, @3, @4, NSNull.null]];
    [optManaged.floatObj2 addObjects:@[NSNull.null, @2.2f, @3.3f, @4.4f, NSNull.null]];
    [optManaged.doubleObj2 addObjects:@[NSNull.null, @2.2, @3.3, @4.4, NSNull.null]];
    [optManaged.stringObj2 addObjects:@[NSNull.null, @"a", @"bc", @"de", NSNull.null]];
    [optManaged.dataObj2 addObjects:@[NSNull.null, data(1), data(2), data(3), NSNull.null]];
    [optManaged.dateObj2 addObjects:@[NSNull.null, date(1), date(2), date(3), NSNull.null]];
    [optManaged.decimalObj2 addObjects:@[NSNull.null, decimal128(1), decimal128(2), decimal128(3), NSNull.null]];
    [optManaged.objectIdObj2 addObjects:@[NSNull.null, objectId(1), objectId(2), objectId(3), NSNull.null]];
    [optManaged.uuidObj2 addObjects:@[NSNull.null, uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"), uuid(@"00000000-0000-0000-0000-000000000000"), uuid(@"123DECC8-B300-4954-A233-F89909F4FD89"), NSNull.null]];
    [realm commitWriteTransaction];

    [unmanaged.boolObj addObjects:@[@NO, @YES]];
    [unmanaged.intObj addObjects:@[@2, @3]];
    [unmanaged.floatObj addObjects:@[@2.2f, @3.3f]];
    [unmanaged.doubleObj addObjects:@[@2.2, @3.3]];
    [unmanaged.stringObj addObjects:@[@"a", @"bc"]];
    [unmanaged.dataObj addObjects:@[data(1), data(2)]];
    [unmanaged.dateObj addObjects:@[date(1), date(2)]];
    [unmanaged.decimalObj addObjects:@[decimal128(1), decimal128(2)]];
    [unmanaged.objectIdObj addObjects:@[objectId(1), objectId(2)]];
    [unmanaged.uuidObj addObjects:@[uuid(@"00000000-0000-0000-0000-000000000000"), uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")]];
    [optUnmanaged.boolObj addObjects:@[NSNull.null, @NO, NSNull.null]];
    [optUnmanaged.intObj addObjects:@[NSNull.null, @2, NSNull.null]];
    [optUnmanaged.floatObj addObjects:@[NSNull.null, @2.2f, NSNull.null]];
    [optUnmanaged.doubleObj addObjects:@[NSNull.null, @2.2, NSNull.null]];
    [optUnmanaged.stringObj addObjects:@[NSNull.null, @"a", NSNull.null]];
    [optUnmanaged.dataObj addObjects:@[NSNull.null, data(1), NSNull.null]];
    [optUnmanaged.dateObj addObjects:@[NSNull.null, date(1), NSNull.null]];
    [optUnmanaged.decimalObj addObjects:@[NSNull.null, decimal128(1), NSNull.null]];
    [optUnmanaged.objectIdObj addObjects:@[NSNull.null, objectId(1), NSNull.null]];
    [optUnmanaged.uuidObj addObjects:@[NSNull.null, uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"), NSNull.null]];
    [unmanaged.boolObj2 addObjects:@[@NO, @YES, @NO, @YES]];
    [unmanaged.intObj2 addObjects:@[@2, @3, @2, @4]];
    [unmanaged.floatObj2 addObjects:@[@2.2f, @3.3f, @2.2f, @4.4f]];
    [unmanaged.doubleObj2 addObjects:@[@2.2, @3.3, @2.2, @4.4]];
    [unmanaged.stringObj2 addObjects:@[@"a", @"bc", @"a", @"de"]];
    [unmanaged.dataObj2 addObjects:@[data(1), data(2), data(1), data(3)]];
    [unmanaged.dateObj2 addObjects:@[date(1), date(2), date(1), date(3)]];
    [unmanaged.decimalObj2 addObjects:@[decimal128(1), decimal128(2), decimal128(1), decimal128(3)]];
    [unmanaged.objectIdObj2 addObjects:@[objectId(1), objectId(2), objectId(1), objectId(3)]];
    [unmanaged.uuidObj2 addObjects:@[uuid(@"00000000-0000-0000-0000-000000000000"), uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"), uuid(@"00000000-0000-0000-0000-000000000000"), uuid(@"123DECC8-B300-4954-A233-F89909F4FD89")]];
    [optUnmanaged.boolObj2 addObjects:@[NSNull.null, @NO, @YES, @NO, NSNull.null]];
    [optUnmanaged.intObj2 addObjects:@[NSNull.null, @2, @3, @4, NSNull.null]];
    [optUnmanaged.floatObj2 addObjects:@[NSNull.null, @2.2f, @3.3f, @4.4f, NSNull.null]];
    [optUnmanaged.doubleObj2 addObjects:@[NSNull.null, @2.2, @3.3, @4.4, NSNull.null]];
    [optUnmanaged.stringObj2 addObjects:@[NSNull.null, @"a", @"bc", @"de", NSNull.null]];
    [optUnmanaged.dataObj2 addObjects:@[NSNull.null, data(1), data(2), data(3), NSNull.null]];
    [optUnmanaged.dateObj2 addObjects:@[NSNull.null, date(1), date(2), date(3), NSNull.null]];
    [optUnmanaged.decimalObj2 addObjects:@[NSNull.null, decimal128(1), decimal128(2), decimal128(4), NSNull.null]];
    [optUnmanaged.objectIdObj2 addObjects:@[NSNull.null, objectId(1), objectId(2), objectId(4), NSNull.null]];
    [optUnmanaged.uuidObj2 addObjects:@[NSNull.null, uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"), uuid(@"00000000-0000-0000-0000-000000000000"), uuid(@"123DECC8-B300-4954-A233-F89909F4FD89"), NSNull.null]];

    XCTAssertTrue([managed.boolObj2 isSubsetOfSet:managed.boolObj]);
    XCTAssertTrue([unmanaged.boolObj2 isSubsetOfSet:unmanaged.boolObj]);
    XCTAssertFalse([optManaged.boolObj2 isSubsetOfSet:optManaged.boolObj]);
    XCTAssertFalse([optUnmanaged.boolObj2 isSubsetOfSet:optUnmanaged.boolObj]);

    XCTAssertTrue([managed.boolObj isSubsetOfSet:managed.boolObj2]);
    XCTAssertTrue([unmanaged.boolObj isSubsetOfSet:unmanaged.boolObj2]);
    XCTAssertTrue([optManaged.boolObj isSubsetOfSet:optManaged.boolObj2]);
    XCTAssertTrue([optUnmanaged.boolObj isSubsetOfSet:optUnmanaged.boolObj2]);

    XCTAssertTrue([managed.intObj isSubsetOfSet:managed.intObj2]);
    XCTAssertTrue([managed.floatObj isSubsetOfSet:managed.floatObj2]);
    XCTAssertTrue([managed.doubleObj isSubsetOfSet:managed.doubleObj2]);
    XCTAssertTrue([managed.stringObj isSubsetOfSet:managed.stringObj2]);
    XCTAssertTrue([managed.dataObj isSubsetOfSet:managed.dataObj2]);
    XCTAssertTrue([managed.dateObj isSubsetOfSet:managed.dateObj2]);
    XCTAssertTrue([managed.decimalObj isSubsetOfSet:managed.decimalObj2]);
    XCTAssertTrue([managed.objectIdObj isSubsetOfSet:managed.objectIdObj2]);
    XCTAssertTrue([managed.uuidObj isSubsetOfSet:managed.uuidObj2]);
    XCTAssertTrue([optManaged.intObj isSubsetOfSet:optManaged.intObj2]);
    XCTAssertTrue([optManaged.floatObj isSubsetOfSet:optManaged.floatObj2]);
    XCTAssertTrue([optManaged.doubleObj isSubsetOfSet:optManaged.doubleObj2]);
    XCTAssertTrue([optManaged.stringObj isSubsetOfSet:optManaged.stringObj2]);
    XCTAssertTrue([optManaged.dataObj isSubsetOfSet:optManaged.dataObj2]);
    XCTAssertTrue([optManaged.dateObj isSubsetOfSet:optManaged.dateObj2]);
    XCTAssertTrue([optManaged.decimalObj isSubsetOfSet:optManaged.decimalObj2]);
    XCTAssertTrue([optManaged.objectIdObj isSubsetOfSet:optManaged.objectIdObj2]);
    XCTAssertTrue([optManaged.uuidObj isSubsetOfSet:optManaged.uuidObj2]);
    XCTAssertTrue([unmanaged.intObj isSubsetOfSet:unmanaged.intObj2]);
    XCTAssertTrue([unmanaged.floatObj isSubsetOfSet:unmanaged.floatObj2]);
    XCTAssertTrue([unmanaged.doubleObj isSubsetOfSet:unmanaged.doubleObj2]);
    XCTAssertTrue([unmanaged.stringObj isSubsetOfSet:unmanaged.stringObj2]);
    XCTAssertTrue([unmanaged.dataObj isSubsetOfSet:unmanaged.dataObj2]);
    XCTAssertTrue([unmanaged.dateObj isSubsetOfSet:unmanaged.dateObj2]);
    XCTAssertTrue([unmanaged.decimalObj isSubsetOfSet:unmanaged.decimalObj2]);
    XCTAssertTrue([unmanaged.objectIdObj isSubsetOfSet:unmanaged.objectIdObj2]);
    XCTAssertTrue([unmanaged.uuidObj isSubsetOfSet:unmanaged.uuidObj2]);
    XCTAssertTrue([optUnmanaged.intObj isSubsetOfSet:optUnmanaged.intObj2]);
    XCTAssertTrue([optUnmanaged.floatObj isSubsetOfSet:optUnmanaged.floatObj2]);
    XCTAssertTrue([optUnmanaged.doubleObj isSubsetOfSet:optUnmanaged.doubleObj2]);
    XCTAssertTrue([optUnmanaged.stringObj isSubsetOfSet:optUnmanaged.stringObj2]);
    XCTAssertTrue([optUnmanaged.dataObj isSubsetOfSet:optUnmanaged.dataObj2]);
    XCTAssertTrue([optUnmanaged.dateObj isSubsetOfSet:optUnmanaged.dateObj2]);
    XCTAssertTrue([optUnmanaged.decimalObj isSubsetOfSet:optUnmanaged.decimalObj2]);
    XCTAssertTrue([optUnmanaged.objectIdObj isSubsetOfSet:optUnmanaged.objectIdObj2]);
    XCTAssertTrue([optUnmanaged.uuidObj isSubsetOfSet:optUnmanaged.uuidObj2]);
    XCTAssertFalse([managed.intObj2 isSubsetOfSet:managed.intObj]);
    XCTAssertFalse([managed.floatObj2 isSubsetOfSet:managed.floatObj]);
    XCTAssertFalse([managed.doubleObj2 isSubsetOfSet:managed.doubleObj]);
    XCTAssertFalse([managed.stringObj2 isSubsetOfSet:managed.stringObj]);
    XCTAssertFalse([managed.dataObj2 isSubsetOfSet:managed.dataObj]);
    XCTAssertFalse([managed.dateObj2 isSubsetOfSet:managed.dateObj]);
    XCTAssertFalse([managed.decimalObj2 isSubsetOfSet:managed.decimalObj]);
    XCTAssertFalse([managed.objectIdObj2 isSubsetOfSet:managed.objectIdObj]);
    XCTAssertFalse([managed.uuidObj2 isSubsetOfSet:managed.uuidObj]);
    XCTAssertFalse([optManaged.intObj2 isSubsetOfSet:optManaged.intObj]);
    XCTAssertFalse([optManaged.floatObj2 isSubsetOfSet:optManaged.floatObj]);
    XCTAssertFalse([optManaged.doubleObj2 isSubsetOfSet:optManaged.doubleObj]);
    XCTAssertFalse([optManaged.stringObj2 isSubsetOfSet:optManaged.stringObj]);
    XCTAssertFalse([optManaged.dataObj2 isSubsetOfSet:optManaged.dataObj]);
    XCTAssertFalse([optManaged.dateObj2 isSubsetOfSet:optManaged.dateObj]);
    XCTAssertFalse([optManaged.decimalObj2 isSubsetOfSet:optManaged.decimalObj]);
    XCTAssertFalse([optManaged.objectIdObj2 isSubsetOfSet:optManaged.objectIdObj]);
    XCTAssertFalse([optManaged.uuidObj2 isSubsetOfSet:optManaged.uuidObj]);
    XCTAssertFalse([unmanaged.intObj2 isSubsetOfSet:unmanaged.intObj]);
    XCTAssertFalse([unmanaged.floatObj2 isSubsetOfSet:unmanaged.floatObj]);
    XCTAssertFalse([unmanaged.doubleObj2 isSubsetOfSet:unmanaged.doubleObj]);
    XCTAssertFalse([unmanaged.stringObj2 isSubsetOfSet:unmanaged.stringObj]);
    XCTAssertFalse([unmanaged.dataObj2 isSubsetOfSet:unmanaged.dataObj]);
    XCTAssertFalse([unmanaged.dateObj2 isSubsetOfSet:unmanaged.dateObj]);
    XCTAssertFalse([unmanaged.decimalObj2 isSubsetOfSet:unmanaged.decimalObj]);
    XCTAssertFalse([unmanaged.objectIdObj2 isSubsetOfSet:unmanaged.objectIdObj]);
    XCTAssertFalse([unmanaged.uuidObj2 isSubsetOfSet:unmanaged.uuidObj]);
    XCTAssertFalse([optUnmanaged.intObj2 isSubsetOfSet:optUnmanaged.intObj]);
    XCTAssertFalse([optUnmanaged.floatObj2 isSubsetOfSet:optUnmanaged.floatObj]);
    XCTAssertFalse([optUnmanaged.doubleObj2 isSubsetOfSet:optUnmanaged.doubleObj]);
    XCTAssertFalse([optUnmanaged.stringObj2 isSubsetOfSet:optUnmanaged.stringObj]);
    XCTAssertFalse([optUnmanaged.dataObj2 isSubsetOfSet:optUnmanaged.dataObj]);
    XCTAssertFalse([optUnmanaged.dateObj2 isSubsetOfSet:optUnmanaged.dateObj]);
    XCTAssertFalse([optUnmanaged.decimalObj2 isSubsetOfSet:optUnmanaged.decimalObj]);
    XCTAssertFalse([optUnmanaged.objectIdObj2 isSubsetOfSet:optUnmanaged.objectIdObj]);
    XCTAssertFalse([optUnmanaged.uuidObj2 isSubsetOfSet:optUnmanaged.uuidObj]);
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
    RLMAssertThrowsWithReason([unmanaged.uuidObj minOfProperty:@"self"], 
                              @"minOfProperty: is not supported for uuid set");
    RLMAssertThrowsWithReason([optUnmanaged.boolObj minOfProperty:@"self"], 
                              @"minOfProperty: is not supported for bool? set");
    RLMAssertThrowsWithReason([optUnmanaged.stringObj minOfProperty:@"self"], 
                              @"minOfProperty: is not supported for string? set");
    RLMAssertThrowsWithReason([optUnmanaged.dataObj minOfProperty:@"self"], 
                              @"minOfProperty: is not supported for data? set");
    RLMAssertThrowsWithReason([optUnmanaged.objectIdObj minOfProperty:@"self"], 
                              @"minOfProperty: is not supported for object id? set");
    RLMAssertThrowsWithReason([optUnmanaged.uuidObj minOfProperty:@"self"], 
                              @"minOfProperty: is not supported for uuid? set");
    RLMAssertThrowsWithReason([managed.boolObj minOfProperty:@"self"], 
                              @"minOfProperty: is not supported for bool set 'AllPrimitiveSets.boolObj'");
    RLMAssertThrowsWithReason([managed.stringObj minOfProperty:@"self"], 
                              @"minOfProperty: is not supported for string set 'AllPrimitiveSets.stringObj'");
    RLMAssertThrowsWithReason([managed.dataObj minOfProperty:@"self"], 
                              @"minOfProperty: is not supported for data set 'AllPrimitiveSets.dataObj'");
    RLMAssertThrowsWithReason([managed.objectIdObj minOfProperty:@"self"], 
                              @"minOfProperty: is not supported for object id set 'AllPrimitiveSets.objectIdObj'");
    RLMAssertThrowsWithReason([managed.uuidObj minOfProperty:@"self"], 
                              @"minOfProperty: is not supported for uuid set 'AllPrimitiveSets.uuidObj'");
    RLMAssertThrowsWithReason([optManaged.boolObj minOfProperty:@"self"], 
                              @"minOfProperty: is not supported for bool? set 'AllOptionalPrimitiveSets.boolObj'");
    RLMAssertThrowsWithReason([optManaged.stringObj minOfProperty:@"self"], 
                              @"minOfProperty: is not supported for string? set 'AllOptionalPrimitiveSets.stringObj'");
    RLMAssertThrowsWithReason([optManaged.dataObj minOfProperty:@"self"], 
                              @"minOfProperty: is not supported for data? set 'AllOptionalPrimitiveSets.dataObj'");
    RLMAssertThrowsWithReason([optManaged.objectIdObj minOfProperty:@"self"], 
                              @"minOfProperty: is not supported for object id? set 'AllOptionalPrimitiveSets.objectIdObj'");
    RLMAssertThrowsWithReason([optManaged.uuidObj minOfProperty:@"self"], 
                              @"minOfProperty: is not supported for uuid? set 'AllOptionalPrimitiveSets.uuidObj'");

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
    RLMAssertThrowsWithReason([unmanaged.uuidObj maxOfProperty:@"self"], 
                              @"maxOfProperty: is not supported for uuid set");
    RLMAssertThrowsWithReason([optUnmanaged.boolObj maxOfProperty:@"self"], 
                              @"maxOfProperty: is not supported for bool? set");
    RLMAssertThrowsWithReason([optUnmanaged.stringObj maxOfProperty:@"self"], 
                              @"maxOfProperty: is not supported for string? set");
    RLMAssertThrowsWithReason([optUnmanaged.dataObj maxOfProperty:@"self"], 
                              @"maxOfProperty: is not supported for data? set");
    RLMAssertThrowsWithReason([optUnmanaged.objectIdObj maxOfProperty:@"self"], 
                              @"maxOfProperty: is not supported for object id? set");
    RLMAssertThrowsWithReason([optUnmanaged.uuidObj maxOfProperty:@"self"], 
                              @"maxOfProperty: is not supported for uuid? set");
    RLMAssertThrowsWithReason([managed.boolObj maxOfProperty:@"self"], 
                              @"maxOfProperty: is not supported for bool set 'AllPrimitiveSets.boolObj'");
    RLMAssertThrowsWithReason([managed.stringObj maxOfProperty:@"self"], 
                              @"maxOfProperty: is not supported for string set 'AllPrimitiveSets.stringObj'");
    RLMAssertThrowsWithReason([managed.dataObj maxOfProperty:@"self"], 
                              @"maxOfProperty: is not supported for data set 'AllPrimitiveSets.dataObj'");
    RLMAssertThrowsWithReason([managed.objectIdObj maxOfProperty:@"self"], 
                              @"maxOfProperty: is not supported for object id set 'AllPrimitiveSets.objectIdObj'");
    RLMAssertThrowsWithReason([managed.uuidObj maxOfProperty:@"self"], 
                              @"maxOfProperty: is not supported for uuid set 'AllPrimitiveSets.uuidObj'");
    RLMAssertThrowsWithReason([optManaged.boolObj maxOfProperty:@"self"], 
                              @"maxOfProperty: is not supported for bool? set 'AllOptionalPrimitiveSets.boolObj'");
    RLMAssertThrowsWithReason([optManaged.stringObj maxOfProperty:@"self"], 
                              @"maxOfProperty: is not supported for string? set 'AllOptionalPrimitiveSets.stringObj'");
    RLMAssertThrowsWithReason([optManaged.dataObj maxOfProperty:@"self"], 
                              @"maxOfProperty: is not supported for data? set 'AllOptionalPrimitiveSets.dataObj'");
    RLMAssertThrowsWithReason([optManaged.objectIdObj maxOfProperty:@"self"], 
                              @"maxOfProperty: is not supported for object id? set 'AllOptionalPrimitiveSets.objectIdObj'");
    RLMAssertThrowsWithReason([optManaged.uuidObj maxOfProperty:@"self"], 
                              @"maxOfProperty: is not supported for uuid? set 'AllOptionalPrimitiveSets.uuidObj'");

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
    RLMAssertThrowsWithReason([unmanaged.uuidObj sumOfProperty:@"self"], 
                              @"sumOfProperty: is not supported for uuid set");
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
    RLMAssertThrowsWithReason([optUnmanaged.uuidObj sumOfProperty:@"self"], 
                              @"sumOfProperty: is not supported for uuid? set");
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
    RLMAssertThrowsWithReason([managed.uuidObj sumOfProperty:@"self"], 
                              @"sumOfProperty: is not supported for uuid set 'AllPrimitiveSets.uuidObj'");
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
    RLMAssertThrowsWithReason([optManaged.uuidObj sumOfProperty:@"self"], 
                              @"sumOfProperty: is not supported for uuid? set 'AllOptionalPrimitiveSets.uuidObj'");

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
    XCTAssertEqualWithAccuracy([optUnmanaged.intObj sumOfProperty:@"self"].doubleValue, sum(@[NSNull.null, @2, @3]), .001);
    XCTAssertEqualWithAccuracy([optUnmanaged.floatObj sumOfProperty:@"self"].doubleValue, sum(@[NSNull.null, @2.2f, @3.3f]), .001);
    XCTAssertEqualWithAccuracy([optUnmanaged.doubleObj sumOfProperty:@"self"].doubleValue, sum(@[NSNull.null, @2.2, @3.3]), .001);
    XCTAssertEqualWithAccuracy([optUnmanaged.decimalObj sumOfProperty:@"self"].doubleValue, sum(@[NSNull.null, decimal128(1), decimal128(2)]), .001);
    XCTAssertEqualWithAccuracy([managed.intObj sumOfProperty:@"self"].doubleValue, sum(@[@2, @3]), .001);
    XCTAssertEqualWithAccuracy([managed.floatObj sumOfProperty:@"self"].doubleValue, sum(@[@2.2f, @3.3f]), .001);
    XCTAssertEqualWithAccuracy([managed.doubleObj sumOfProperty:@"self"].doubleValue, sum(@[@2.2, @3.3]), .001);
    XCTAssertEqualWithAccuracy([managed.decimalObj sumOfProperty:@"self"].doubleValue, sum(@[decimal128(1), decimal128(2)]), .001);
    XCTAssertEqualWithAccuracy([optManaged.intObj sumOfProperty:@"self"].doubleValue, sum(@[NSNull.null, @2, @3]), .001);
    XCTAssertEqualWithAccuracy([optManaged.floatObj sumOfProperty:@"self"].doubleValue, sum(@[NSNull.null, @2.2f, @3.3f]), .001);
    XCTAssertEqualWithAccuracy([optManaged.doubleObj sumOfProperty:@"self"].doubleValue, sum(@[NSNull.null, @2.2, @3.3]), .001);
    XCTAssertEqualWithAccuracy([optManaged.decimalObj sumOfProperty:@"self"].doubleValue, sum(@[NSNull.null, decimal128(1), decimal128(2)]), .001);
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
    RLMAssertThrowsWithReason([unmanaged.uuidObj averageOfProperty:@"self"], 
                              @"averageOfProperty: is not supported for uuid set");
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
    RLMAssertThrowsWithReason([optUnmanaged.uuidObj averageOfProperty:@"self"], 
                              @"averageOfProperty: is not supported for uuid? set");
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
    RLMAssertThrowsWithReason([managed.uuidObj averageOfProperty:@"self"], 
                              @"averageOfProperty: is not supported for uuid set 'AllPrimitiveSets.uuidObj'");
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
    RLMAssertThrowsWithReason([optManaged.uuidObj averageOfProperty:@"self"], 
                              @"averageOfProperty: is not supported for uuid? set 'AllOptionalPrimitiveSets.uuidObj'");

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
    XCTAssertEqualWithAccuracy([optUnmanaged.intObj averageOfProperty:@"self"].doubleValue, average(@[NSNull.null, @2, @3]), .001);
    XCTAssertEqualWithAccuracy([optUnmanaged.floatObj averageOfProperty:@"self"].doubleValue, average(@[NSNull.null, @2.2f, @3.3f]), .001);
    XCTAssertEqualWithAccuracy([optUnmanaged.doubleObj averageOfProperty:@"self"].doubleValue, average(@[NSNull.null, @2.2, @3.3]), .001);
    XCTAssertEqualWithAccuracy([optUnmanaged.decimalObj averageOfProperty:@"self"].doubleValue, average(@[NSNull.null, decimal128(1), decimal128(2)]), .001);
    XCTAssertEqualWithAccuracy([managed.intObj averageOfProperty:@"self"].doubleValue, average(@[@2, @3]), .001);
    XCTAssertEqualWithAccuracy([managed.floatObj averageOfProperty:@"self"].doubleValue, average(@[@2.2f, @3.3f]), .001);
    XCTAssertEqualWithAccuracy([managed.doubleObj averageOfProperty:@"self"].doubleValue, average(@[@2.2, @3.3]), .001);
    XCTAssertEqualWithAccuracy([managed.decimalObj averageOfProperty:@"self"].doubleValue, average(@[decimal128(1), decimal128(2)]), .001);
    XCTAssertEqualWithAccuracy([optManaged.intObj averageOfProperty:@"self"].doubleValue, average(@[NSNull.null, @2, @3]), .001);
    XCTAssertEqualWithAccuracy([optManaged.floatObj averageOfProperty:@"self"].doubleValue, average(@[NSNull.null, @2.2f, @3.3f]), .001);
    XCTAssertEqualWithAccuracy([optManaged.doubleObj averageOfProperty:@"self"].doubleValue, average(@[NSNull.null, @2.2, @3.3]), .001);
    XCTAssertEqualWithAccuracy([optManaged.decimalObj averageOfProperty:@"self"].doubleValue, average(@[NSNull.null, decimal128(1), decimal128(2)]), .001);
}

- (void)testFastEnumeration {
    for (int i = 0; i < 10; ++i) {
        [self addObjects];
    }

    { 
     NSUInteger i = 0; 
     NSArray *values = @[@NO, @YES]; 
     for (id value in unmanaged.boolObj) { 
     XCTAssertTrue([[NSSet setWithArray:values] containsObject:value]); 
     } 
     } 
    
    { 
     NSUInteger i = 0; 
     NSArray *values = @[@2, @3]; 
     for (id value in unmanaged.intObj) { 
     XCTAssertTrue([[NSSet setWithArray:values] containsObject:value]); 
     } 
     } 
    
    { 
     NSUInteger i = 0; 
     NSArray *values = @[@2.2f, @3.3f]; 
     for (id value in unmanaged.floatObj) { 
     XCTAssertTrue([[NSSet setWithArray:values] containsObject:value]); 
     } 
     } 
    
    { 
     NSUInteger i = 0; 
     NSArray *values = @[@2.2, @3.3]; 
     for (id value in unmanaged.doubleObj) { 
     XCTAssertTrue([[NSSet setWithArray:values] containsObject:value]); 
     } 
     } 
    
    { 
     NSUInteger i = 0; 
     NSArray *values = @[@"a", @"bc"]; 
     for (id value in unmanaged.stringObj) { 
     XCTAssertTrue([[NSSet setWithArray:values] containsObject:value]); 
     } 
     } 
    
    { 
     NSUInteger i = 0; 
     NSArray *values = @[data(1), data(2)]; 
     for (id value in unmanaged.dataObj) { 
     XCTAssertTrue([[NSSet setWithArray:values] containsObject:value]); 
     } 
     } 
    
    { 
     NSUInteger i = 0; 
     NSArray *values = @[date(1), date(2)]; 
     for (id value in unmanaged.dateObj) { 
     XCTAssertTrue([[NSSet setWithArray:values] containsObject:value]); 
     } 
     } 
    
    { 
     NSUInteger i = 0; 
     NSArray *values = @[decimal128(1), decimal128(2)]; 
     for (id value in unmanaged.decimalObj) { 
     XCTAssertTrue([[NSSet setWithArray:values] containsObject:value]); 
     } 
     } 
    
    { 
     NSUInteger i = 0; 
     NSArray *values = @[objectId(1), objectId(2)]; 
     for (id value in unmanaged.objectIdObj) { 
     XCTAssertTrue([[NSSet setWithArray:values] containsObject:value]); 
     } 
     } 
    
    { 
     NSUInteger i = 0; 
     NSArray *values = @[uuid(@"00000000-0000-0000-0000-000000000000"), uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")]; 
     for (id value in unmanaged.uuidObj) { 
     XCTAssertTrue([[NSSet setWithArray:values] containsObject:value]); 
     } 
     } 
    
    { 
     NSUInteger i = 0; 
     NSArray *values = @[NSNull.null, @NO, @YES]; 
     for (id value in optUnmanaged.boolObj) { 
     XCTAssertTrue([[NSSet setWithArray:values] containsObject:value]); 
     } 
     } 
    
    { 
     NSUInteger i = 0; 
     NSArray *values = @[NSNull.null, @2, @3]; 
     for (id value in optUnmanaged.intObj) { 
     XCTAssertTrue([[NSSet setWithArray:values] containsObject:value]); 
     } 
     } 
    
    { 
     NSUInteger i = 0; 
     NSArray *values = @[NSNull.null, @2.2f, @3.3f]; 
     for (id value in optUnmanaged.floatObj) { 
     XCTAssertTrue([[NSSet setWithArray:values] containsObject:value]); 
     } 
     } 
    
    { 
     NSUInteger i = 0; 
     NSArray *values = @[NSNull.null, @2.2, @3.3]; 
     for (id value in optUnmanaged.doubleObj) { 
     XCTAssertTrue([[NSSet setWithArray:values] containsObject:value]); 
     } 
     } 
    
    { 
     NSUInteger i = 0; 
     NSArray *values = @[NSNull.null, @"a", @"bc"]; 
     for (id value in optUnmanaged.stringObj) { 
     XCTAssertTrue([[NSSet setWithArray:values] containsObject:value]); 
     } 
     } 
    
    { 
     NSUInteger i = 0; 
     NSArray *values = @[NSNull.null, data(1), data(2)]; 
     for (id value in optUnmanaged.dataObj) { 
     XCTAssertTrue([[NSSet setWithArray:values] containsObject:value]); 
     } 
     } 
    
    { 
     NSUInteger i = 0; 
     NSArray *values = @[NSNull.null, date(1), date(2)]; 
     for (id value in optUnmanaged.dateObj) { 
     XCTAssertTrue([[NSSet setWithArray:values] containsObject:value]); 
     } 
     } 
    
    { 
     NSUInteger i = 0; 
     NSArray *values = @[NSNull.null, decimal128(1), decimal128(2)]; 
     for (id value in optUnmanaged.decimalObj) { 
     XCTAssertTrue([[NSSet setWithArray:values] containsObject:value]); 
     } 
     } 
    
    { 
     NSUInteger i = 0; 
     NSArray *values = @[NSNull.null, objectId(1), objectId(2)]; 
     for (id value in optUnmanaged.objectIdObj) { 
     XCTAssertTrue([[NSSet setWithArray:values] containsObject:value]); 
     } 
     } 
    
    { 
     NSUInteger i = 0; 
     NSArray *values = @[NSNull.null, uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"), uuid(@"00000000-0000-0000-0000-000000000000")]; 
     for (id value in optUnmanaged.uuidObj) { 
     XCTAssertTrue([[NSSet setWithArray:values] containsObject:value]); 
     } 
     } 
    
    { 
     NSUInteger i = 0; 
     NSArray *values = @[@NO, @YES]; 
     for (id value in managed.boolObj) { 
     XCTAssertTrue([[NSSet setWithArray:values] containsObject:value]); 
     } 
     } 
    
    { 
     NSUInteger i = 0; 
     NSArray *values = @[@2, @3]; 
     for (id value in managed.intObj) { 
     XCTAssertTrue([[NSSet setWithArray:values] containsObject:value]); 
     } 
     } 
    
    { 
     NSUInteger i = 0; 
     NSArray *values = @[@2.2f, @3.3f]; 
     for (id value in managed.floatObj) { 
     XCTAssertTrue([[NSSet setWithArray:values] containsObject:value]); 
     } 
     } 
    
    { 
     NSUInteger i = 0; 
     NSArray *values = @[@2.2, @3.3]; 
     for (id value in managed.doubleObj) { 
     XCTAssertTrue([[NSSet setWithArray:values] containsObject:value]); 
     } 
     } 
    
    { 
     NSUInteger i = 0; 
     NSArray *values = @[@"a", @"bc"]; 
     for (id value in managed.stringObj) { 
     XCTAssertTrue([[NSSet setWithArray:values] containsObject:value]); 
     } 
     } 
    
    { 
     NSUInteger i = 0; 
     NSArray *values = @[data(1), data(2)]; 
     for (id value in managed.dataObj) { 
     XCTAssertTrue([[NSSet setWithArray:values] containsObject:value]); 
     } 
     } 
    
    { 
     NSUInteger i = 0; 
     NSArray *values = @[date(1), date(2)]; 
     for (id value in managed.dateObj) { 
     XCTAssertTrue([[NSSet setWithArray:values] containsObject:value]); 
     } 
     } 
    
    { 
     NSUInteger i = 0; 
     NSArray *values = @[decimal128(1), decimal128(2)]; 
     for (id value in managed.decimalObj) { 
     XCTAssertTrue([[NSSet setWithArray:values] containsObject:value]); 
     } 
     } 
    
    { 
     NSUInteger i = 0; 
     NSArray *values = @[objectId(1), objectId(2)]; 
     for (id value in managed.objectIdObj) { 
     XCTAssertTrue([[NSSet setWithArray:values] containsObject:value]); 
     } 
     } 
    
    { 
     NSUInteger i = 0; 
     NSArray *values = @[uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"), uuid(@"00000000-0000-0000-0000-000000000000")]; 
     for (id value in managed.uuidObj) { 
     XCTAssertTrue([[NSSet setWithArray:values] containsObject:value]); 
     } 
     } 
    
    { 
     NSUInteger i = 0; 
     NSArray *values = @[NSNull.null, @NO, @YES]; 
     for (id value in optManaged.boolObj) { 
     XCTAssertTrue([[NSSet setWithArray:values] containsObject:value]); 
     } 
     } 
    
    { 
     NSUInteger i = 0; 
     NSArray *values = @[NSNull.null, @2, @3]; 
     for (id value in optManaged.intObj) { 
     XCTAssertTrue([[NSSet setWithArray:values] containsObject:value]); 
     } 
     } 
    
    { 
     NSUInteger i = 0; 
     NSArray *values = @[NSNull.null, @2.2f, @3.3f]; 
     for (id value in optManaged.floatObj) { 
     XCTAssertTrue([[NSSet setWithArray:values] containsObject:value]); 
     } 
     } 
    
    { 
     NSUInteger i = 0; 
     NSArray *values = @[NSNull.null, @2.2, @3.3]; 
     for (id value in optManaged.doubleObj) { 
     XCTAssertTrue([[NSSet setWithArray:values] containsObject:value]); 
     } 
     } 
    
    { 
     NSUInteger i = 0; 
     NSArray *values = @[NSNull.null, @"a", @"bc"]; 
     for (id value in optManaged.stringObj) { 
     XCTAssertTrue([[NSSet setWithArray:values] containsObject:value]); 
     } 
     } 
    
    { 
     NSUInteger i = 0; 
     NSArray *values = @[NSNull.null, data(1), data(2)]; 
     for (id value in optManaged.dataObj) { 
     XCTAssertTrue([[NSSet setWithArray:values] containsObject:value]); 
     } 
     } 
    
    { 
     NSUInteger i = 0; 
     NSArray *values = @[NSNull.null, date(1), date(2)]; 
     for (id value in optManaged.dateObj) { 
     XCTAssertTrue([[NSSet setWithArray:values] containsObject:value]); 
     } 
     } 
    
    { 
     NSUInteger i = 0; 
     NSArray *values = @[NSNull.null, decimal128(1), decimal128(2)]; 
     for (id value in optManaged.decimalObj) { 
     XCTAssertTrue([[NSSet setWithArray:values] containsObject:value]); 
     } 
     } 
    
    { 
     NSUInteger i = 0; 
     NSArray *values = @[NSNull.null, objectId(1), objectId(2)]; 
     for (id value in optManaged.objectIdObj) { 
     XCTAssertTrue([[NSSet setWithArray:values] containsObject:value]); 
     } 
     } 
    
    { 
     NSUInteger i = 0; 
     NSArray *values = @[NSNull.null, uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"), uuid(@"00000000-0000-0000-0000-000000000000")]; 
     for (id value in optManaged.uuidObj) { 
     XCTAssertTrue([[NSSet setWithArray:values] containsObject:value]); 
     } 
     } 
    
}

- (void)testValueForKeySelf {
    for (RLMSet *set in allSets) {
        XCTAssertEqualObjects([[set valueForKey:@"self"] allObjects], @[]);
    }

    [self addObjects];

    XCTAssertEqualObjects([NSSet setWithArray:[[unmanaged.boolObj valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[@NO, @YES]]));
    XCTAssertEqualObjects([NSSet setWithArray:[[unmanaged.intObj valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[@2, @3]]));
    XCTAssertEqualObjects([NSSet setWithArray:[[unmanaged.floatObj valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[@2.2f, @3.3f]]));
    XCTAssertEqualObjects([NSSet setWithArray:[[unmanaged.doubleObj valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[@2.2, @3.3]]));
    XCTAssertEqualObjects([NSSet setWithArray:[[unmanaged.stringObj valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[@"a", @"bc"]]));
    XCTAssertEqualObjects([NSSet setWithArray:[[unmanaged.dataObj valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[data(1), data(2)]]));
    XCTAssertEqualObjects([NSSet setWithArray:[[unmanaged.dateObj valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[date(1), date(2)]]));
    XCTAssertEqualObjects([NSSet setWithArray:[[unmanaged.decimalObj valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[decimal128(1), decimal128(2)]]));
    XCTAssertEqualObjects([NSSet setWithArray:[[unmanaged.objectIdObj valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[objectId(1), objectId(2)]]));
    XCTAssertEqualObjects([NSSet setWithArray:[[unmanaged.uuidObj valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[uuid(@"00000000-0000-0000-0000-000000000000"), uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")]]));
    XCTAssertEqualObjects([NSSet setWithArray:[[optUnmanaged.boolObj valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[NSNull.null, @NO, @YES]]));
    XCTAssertEqualObjects([NSSet setWithArray:[[optUnmanaged.intObj valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[NSNull.null, @2, @3]]));
    XCTAssertEqualObjects([NSSet setWithArray:[[optUnmanaged.floatObj valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[NSNull.null, @2.2f, @3.3f]]));
    XCTAssertEqualObjects([NSSet setWithArray:[[optUnmanaged.doubleObj valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[NSNull.null, @2.2, @3.3]]));
    XCTAssertEqualObjects([NSSet setWithArray:[[optUnmanaged.stringObj valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[NSNull.null, @"a", @"bc"]]));
    XCTAssertEqualObjects([NSSet setWithArray:[[optUnmanaged.dataObj valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[NSNull.null, data(1), data(2)]]));
    XCTAssertEqualObjects([NSSet setWithArray:[[optUnmanaged.dateObj valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[NSNull.null, date(1), date(2)]]));
    XCTAssertEqualObjects([NSSet setWithArray:[[optUnmanaged.decimalObj valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[NSNull.null, decimal128(1), decimal128(2)]]));
    XCTAssertEqualObjects([NSSet setWithArray:[[optUnmanaged.objectIdObj valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[NSNull.null, objectId(1), objectId(2)]]));
    XCTAssertEqualObjects([NSSet setWithArray:[[optUnmanaged.uuidObj valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[NSNull.null, uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"), uuid(@"00000000-0000-0000-0000-000000000000")]]));
    XCTAssertEqualObjects([NSSet setWithArray:[[managed.boolObj valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[@NO, @YES]]));
    XCTAssertEqualObjects([NSSet setWithArray:[[managed.intObj valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[@2, @3]]));
    XCTAssertEqualObjects([NSSet setWithArray:[[managed.floatObj valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[@2.2f, @3.3f]]));
    XCTAssertEqualObjects([NSSet setWithArray:[[managed.doubleObj valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[@2.2, @3.3]]));
    XCTAssertEqualObjects([NSSet setWithArray:[[managed.stringObj valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[@"a", @"bc"]]));
    XCTAssertEqualObjects([NSSet setWithArray:[[managed.dataObj valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[data(1), data(2)]]));
    XCTAssertEqualObjects([NSSet setWithArray:[[managed.dateObj valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[date(1), date(2)]]));
    XCTAssertEqualObjects([NSSet setWithArray:[[managed.decimalObj valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[decimal128(1), decimal128(2)]]));
    XCTAssertEqualObjects([NSSet setWithArray:[[managed.objectIdObj valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[objectId(1), objectId(2)]]));
    XCTAssertEqualObjects([NSSet setWithArray:[[managed.uuidObj valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"), uuid(@"00000000-0000-0000-0000-000000000000")]]));
    XCTAssertEqualObjects([NSSet setWithArray:[[optManaged.boolObj valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[NSNull.null, @NO, @YES]]));
    XCTAssertEqualObjects([NSSet setWithArray:[[optManaged.intObj valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[NSNull.null, @2, @3]]));
    XCTAssertEqualObjects([NSSet setWithArray:[[optManaged.floatObj valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[NSNull.null, @2.2f, @3.3f]]));
    XCTAssertEqualObjects([NSSet setWithArray:[[optManaged.doubleObj valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[NSNull.null, @2.2, @3.3]]));
    XCTAssertEqualObjects([NSSet setWithArray:[[optManaged.stringObj valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[NSNull.null, @"a", @"bc"]]));
    XCTAssertEqualObjects([NSSet setWithArray:[[optManaged.dataObj valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[NSNull.null, data(1), data(2)]]));
    XCTAssertEqualObjects([NSSet setWithArray:[[optManaged.dateObj valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[NSNull.null, date(1), date(2)]]));
    XCTAssertEqualObjects([NSSet setWithArray:[[optManaged.decimalObj valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[NSNull.null, decimal128(1), decimal128(2)]]));
    XCTAssertEqualObjects([NSSet setWithArray:[[optManaged.objectIdObj valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[NSNull.null, objectId(1), objectId(2)]]));
    XCTAssertEqualObjects([NSSet setWithArray:[[optManaged.uuidObj valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[NSNull.null, uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"), uuid(@"00000000-0000-0000-0000-000000000000")]]));
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
    XCTAssertEqualObjects([optUnmanaged.intObj valueForKeyPath:@"@max.self"], @3);
    XCTAssertEqualObjects([optUnmanaged.floatObj valueForKeyPath:@"@max.self"], @3.3f);
    XCTAssertEqualObjects([optUnmanaged.doubleObj valueForKeyPath:@"@max.self"], @3.3);
    XCTAssertEqualObjects([optUnmanaged.dateObj valueForKeyPath:@"@max.self"], date(2));
    XCTAssertEqualObjects([optUnmanaged.decimalObj valueForKeyPath:@"@max.self"], decimal128(2));

    XCTAssertEqualObjects([managed.intObj valueForKeyPath:@"@min.self"], @2);
    XCTAssertEqualObjects([managed.floatObj valueForKeyPath:@"@min.self"], @2.2f);
    XCTAssertEqualObjects([managed.doubleObj valueForKeyPath:@"@min.self"], @2.2);
    XCTAssertEqualObjects([managed.dateObj valueForKeyPath:@"@min.self"], date(1));
    XCTAssertEqualObjects([managed.decimalObj valueForKeyPath:@"@min.self"], decimal128(1));
    XCTAssertEqualObjects([optManaged.intObj valueForKeyPath:@"@max.self"], @3);
    XCTAssertEqualObjects([optManaged.floatObj valueForKeyPath:@"@max.self"], @3.3f);
    XCTAssertEqualObjects([optManaged.doubleObj valueForKeyPath:@"@max.self"], @3.3);
    XCTAssertEqualObjects([optManaged.dateObj valueForKeyPath:@"@max.self"], date(2));
    XCTAssertEqualObjects([optManaged.decimalObj valueForKeyPath:@"@max.self"], decimal128(2));

    XCTAssertEqualWithAccuracy([[unmanaged.intObj valueForKeyPath:@"@sum.self"] doubleValue], sum(@[@2, @3]), .001);
    XCTAssertEqualWithAccuracy([[unmanaged.floatObj valueForKeyPath:@"@sum.self"] doubleValue], sum(@[@2.2f, @3.3f]), .001);
    XCTAssertEqualWithAccuracy([[unmanaged.doubleObj valueForKeyPath:@"@sum.self"] doubleValue], sum(@[@2.2, @3.3]), .001);
    XCTAssertEqualWithAccuracy([[unmanaged.decimalObj valueForKeyPath:@"@sum.self"] doubleValue], sum(@[decimal128(1), decimal128(2)]), .001);
    XCTAssertEqualWithAccuracy([[optUnmanaged.intObj valueForKeyPath:@"@sum.self"] doubleValue], sum(@[NSNull.null, @2, @3]), .001);
    XCTAssertEqualWithAccuracy([[optUnmanaged.floatObj valueForKeyPath:@"@sum.self"] doubleValue], sum(@[NSNull.null, @2.2f, @3.3f]), .001);
    XCTAssertEqualWithAccuracy([[optUnmanaged.doubleObj valueForKeyPath:@"@sum.self"] doubleValue], sum(@[NSNull.null, @2.2, @3.3]), .001);
    XCTAssertEqualWithAccuracy([[optUnmanaged.decimalObj valueForKeyPath:@"@sum.self"] doubleValue], sum(@[NSNull.null, decimal128(1), decimal128(2)]), .001);
    XCTAssertEqualWithAccuracy([[managed.intObj valueForKeyPath:@"@sum.self"] doubleValue], sum(@[@2, @3]), .001);
    XCTAssertEqualWithAccuracy([[managed.floatObj valueForKeyPath:@"@sum.self"] doubleValue], sum(@[@2.2f, @3.3f]), .001);
    XCTAssertEqualWithAccuracy([[managed.doubleObj valueForKeyPath:@"@sum.self"] doubleValue], sum(@[@2.2, @3.3]), .001);
    XCTAssertEqualWithAccuracy([[managed.decimalObj valueForKeyPath:@"@sum.self"] doubleValue], sum(@[decimal128(1), decimal128(2)]), .001);
    XCTAssertEqualWithAccuracy([[optManaged.intObj valueForKeyPath:@"@sum.self"] doubleValue], sum(@[NSNull.null, @2, @3]), .001);
    XCTAssertEqualWithAccuracy([[optManaged.floatObj valueForKeyPath:@"@sum.self"] doubleValue], sum(@[NSNull.null, @2.2f, @3.3f]), .001);
    XCTAssertEqualWithAccuracy([[optManaged.doubleObj valueForKeyPath:@"@sum.self"] doubleValue], sum(@[NSNull.null, @2.2, @3.3]), .001);
    XCTAssertEqualWithAccuracy([[optManaged.decimalObj valueForKeyPath:@"@sum.self"] doubleValue], sum(@[NSNull.null, decimal128(1), decimal128(2)]), .001);
    XCTAssertEqualWithAccuracy([[unmanaged.intObj valueForKeyPath:@"@avg.self"] doubleValue], average(@[@2, @3]), .001);
    XCTAssertEqualWithAccuracy([[unmanaged.floatObj valueForKeyPath:@"@avg.self"] doubleValue], average(@[@2.2f, @3.3f]), .001);
    XCTAssertEqualWithAccuracy([[unmanaged.doubleObj valueForKeyPath:@"@avg.self"] doubleValue], average(@[@2.2, @3.3]), .001);
    XCTAssertEqualWithAccuracy([[unmanaged.decimalObj valueForKeyPath:@"@avg.self"] doubleValue], average(@[decimal128(1), decimal128(2)]), .001);
    XCTAssertEqualWithAccuracy([[optUnmanaged.intObj valueForKeyPath:@"@avg.self"] doubleValue], average(@[NSNull.null, @2, @3]), .001);
    XCTAssertEqualWithAccuracy([[optUnmanaged.floatObj valueForKeyPath:@"@avg.self"] doubleValue], average(@[NSNull.null, @2.2f, @3.3f]), .001);
    XCTAssertEqualWithAccuracy([[optUnmanaged.doubleObj valueForKeyPath:@"@avg.self"] doubleValue], average(@[NSNull.null, @2.2, @3.3]), .001);
    XCTAssertEqualWithAccuracy([[optUnmanaged.decimalObj valueForKeyPath:@"@avg.self"] doubleValue], average(@[NSNull.null, decimal128(1), decimal128(2)]), .001);
    XCTAssertEqualWithAccuracy([[managed.intObj valueForKeyPath:@"@avg.self"] doubleValue], average(@[@2, @3]), .001);
    XCTAssertEqualWithAccuracy([[managed.floatObj valueForKeyPath:@"@avg.self"] doubleValue], average(@[@2.2f, @3.3f]), .001);
    XCTAssertEqualWithAccuracy([[managed.doubleObj valueForKeyPath:@"@avg.self"] doubleValue], average(@[@2.2, @3.3]), .001);
    XCTAssertEqualWithAccuracy([[managed.decimalObj valueForKeyPath:@"@avg.self"] doubleValue], average(@[decimal128(1), decimal128(2)]), .001);
    XCTAssertEqualWithAccuracy([[optManaged.intObj valueForKeyPath:@"@avg.self"] doubleValue], average(@[NSNull.null, @2, @3]), .001);
    XCTAssertEqualWithAccuracy([[optManaged.floatObj valueForKeyPath:@"@avg.self"] doubleValue], average(@[NSNull.null, @2.2f, @3.3f]), .001);
    XCTAssertEqualWithAccuracy([[optManaged.doubleObj valueForKeyPath:@"@avg.self"] doubleValue], average(@[NSNull.null, @2.2, @3.3]), .001);
    XCTAssertEqualWithAccuracy([[optManaged.decimalObj valueForKeyPath:@"@avg.self"] doubleValue], average(@[NSNull.null, decimal128(1), decimal128(2)]), .001);
}

- (void)testValueForKeyLength {
    for (RLMSet *set in allSets) {
        XCTAssertEqualObjects([[set valueForKey:@"length"] allObjects], @[]);
    }

    [self addObjects];
    XCTAssertEqualObjects([unmanaged.stringObj valueForKey:@"length"], ([[NSSet setWithArray:@[@"a", @"bc"]] valueForKey:@"length"]));
    XCTAssertEqualObjects([optUnmanaged.stringObj valueForKey:@"length"], ([[NSSet setWithArray:@[NSNull.null, @"a", @"bc"]] valueForKey:@"length"]));
    XCTAssertEqualObjects([managed.stringObj valueForKey:@"length"], ([[NSSet setWithArray:@[@"a", @"bc"]] valueForKey:@"length"]));
    XCTAssertEqualObjects([optManaged.stringObj valueForKey:@"length"], ([[NSSet setWithArray:@[NSNull.null, @"a", @"bc"]] valueForKey:@"length"]));
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
    RLMAssertThrowsWithReason([unmanaged.uuidObj setValue:@"a" forKey:@"self"], 
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'uuid'");
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
    RLMAssertThrowsWithReason([optUnmanaged.uuidObj setValue:@"a" forKey:@"self"], 
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'uuid?'");
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
    RLMAssertThrowsWithReason([managed.uuidObj setValue:@"a" forKey:@"self"], 
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'uuid'");
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
    RLMAssertThrowsWithReason([optManaged.uuidObj setValue:@"a" forKey:@"self"], 
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'uuid?'");
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
    RLMAssertThrowsWithReason([unmanaged.uuidObj setValue:NSNull.null forKey:@"self"], 
                              @"Invalid value '<null>' of type 'NSNull' for expected type 'uuid'");
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
    RLMAssertThrowsWithReason([managed.uuidObj setValue:NSNull.null forKey:@"self"], 
                              @"Invalid value '<null>' of type 'NSNull' for expected type 'uuid'");

    [self addObjects];

    // setValue overrides all existing values
    [unmanaged.boolObj setValue:@NO forKey:@"self"];
    [unmanaged.intObj setValue:@2 forKey:@"self"];
    [unmanaged.floatObj setValue:@2.2f forKey:@"self"];
    [unmanaged.doubleObj setValue:@2.2 forKey:@"self"];
    [unmanaged.stringObj setValue:@"a" forKey:@"self"];
    [unmanaged.dataObj setValue:data(1) forKey:@"self"];
    [unmanaged.dateObj setValue:date(1) forKey:@"self"];
    [unmanaged.decimalObj setValue:decimal128(1) forKey:@"self"];
    [unmanaged.objectIdObj setValue:objectId(1) forKey:@"self"];
    [unmanaged.uuidObj setValue:uuid(@"00000000-0000-0000-0000-000000000000") forKey:@"self"];
    [optUnmanaged.boolObj setValue:NSNull.null forKey:@"self"];
    [optUnmanaged.intObj setValue:NSNull.null forKey:@"self"];
    [optUnmanaged.floatObj setValue:NSNull.null forKey:@"self"];
    [optUnmanaged.doubleObj setValue:NSNull.null forKey:@"self"];
    [optUnmanaged.stringObj setValue:NSNull.null forKey:@"self"];
    [optUnmanaged.dataObj setValue:NSNull.null forKey:@"self"];
    [optUnmanaged.dateObj setValue:NSNull.null forKey:@"self"];
    [optUnmanaged.decimalObj setValue:NSNull.null forKey:@"self"];
    [optUnmanaged.objectIdObj setValue:NSNull.null forKey:@"self"];
    [optUnmanaged.uuidObj setValue:NSNull.null forKey:@"self"];
    [managed.boolObj setValue:@NO forKey:@"self"];
    [managed.intObj setValue:@2 forKey:@"self"];
    [managed.floatObj setValue:@2.2f forKey:@"self"];
    [managed.doubleObj setValue:@2.2 forKey:@"self"];
    [managed.stringObj setValue:@"a" forKey:@"self"];
    [managed.dataObj setValue:data(1) forKey:@"self"];
    [managed.dateObj setValue:date(1) forKey:@"self"];
    [managed.decimalObj setValue:decimal128(1) forKey:@"self"];
    [managed.objectIdObj setValue:objectId(1) forKey:@"self"];
    [managed.uuidObj setValue:uuid(@"137DECC8-B300-4954-A233-F89909F4FD89") forKey:@"self"];
    [optManaged.boolObj setValue:NSNull.null forKey:@"self"];
    [optManaged.intObj setValue:NSNull.null forKey:@"self"];
    [optManaged.floatObj setValue:NSNull.null forKey:@"self"];
    [optManaged.doubleObj setValue:NSNull.null forKey:@"self"];
    [optManaged.stringObj setValue:NSNull.null forKey:@"self"];
    [optManaged.dataObj setValue:NSNull.null forKey:@"self"];
    [optManaged.dateObj setValue:NSNull.null forKey:@"self"];
    [optManaged.decimalObj setValue:NSNull.null forKey:@"self"];
    [optManaged.objectIdObj setValue:NSNull.null forKey:@"self"];
    [optManaged.uuidObj setValue:NSNull.null forKey:@"self"];

    RLMAssertThrowsWithReason(unmanaged.boolObj.allObjects[1], @"index 1 beyond bounds [0 .. 0]");
    RLMAssertThrowsWithReason(unmanaged.intObj.allObjects[1], @"index 1 beyond bounds [0 .. 0]");
    RLMAssertThrowsWithReason(unmanaged.floatObj.allObjects[1], @"index 1 beyond bounds [0 .. 0]");
    RLMAssertThrowsWithReason(unmanaged.doubleObj.allObjects[1], @"index 1 beyond bounds [0 .. 0]");
    RLMAssertThrowsWithReason(unmanaged.stringObj.allObjects[1], @"index 1 beyond bounds [0 .. 0]");
    RLMAssertThrowsWithReason(unmanaged.dataObj.allObjects[1], @"index 1 beyond bounds [0 .. 0]");
    RLMAssertThrowsWithReason(unmanaged.dateObj.allObjects[1], @"index 1 beyond bounds [0 .. 0]");
    RLMAssertThrowsWithReason(unmanaged.decimalObj.allObjects[1], @"index 1 beyond bounds [0 .. 0]");
    RLMAssertThrowsWithReason(unmanaged.objectIdObj.allObjects[1], @"index 1 beyond bounds [0 .. 0]");
    RLMAssertThrowsWithReason(unmanaged.uuidObj.allObjects[1], @"index 1 beyond bounds [0 .. 0]");
    RLMAssertThrowsWithReason(optUnmanaged.boolObj.allObjects[1], @"index 1 beyond bounds [0 .. 0]");
    RLMAssertThrowsWithReason(optUnmanaged.intObj.allObjects[1], @"index 1 beyond bounds [0 .. 0]");
    RLMAssertThrowsWithReason(optUnmanaged.floatObj.allObjects[1], @"index 1 beyond bounds [0 .. 0]");
    RLMAssertThrowsWithReason(optUnmanaged.doubleObj.allObjects[1], @"index 1 beyond bounds [0 .. 0]");
    RLMAssertThrowsWithReason(optUnmanaged.stringObj.allObjects[1], @"index 1 beyond bounds [0 .. 0]");
    RLMAssertThrowsWithReason(optUnmanaged.dataObj.allObjects[1], @"index 1 beyond bounds [0 .. 0]");
    RLMAssertThrowsWithReason(optUnmanaged.dateObj.allObjects[1], @"index 1 beyond bounds [0 .. 0]");
    RLMAssertThrowsWithReason(optUnmanaged.decimalObj.allObjects[1], @"index 1 beyond bounds [0 .. 0]");
    RLMAssertThrowsWithReason(optUnmanaged.objectIdObj.allObjects[1], @"index 1 beyond bounds [0 .. 0]");
    RLMAssertThrowsWithReason(optUnmanaged.uuidObj.allObjects[1], @"index 1 beyond bounds [0 .. 0]");
    RLMAssertThrowsWithReason(managed.boolObj.allObjects[1], @"index 1 beyond bounds [0 .. 0]");
    RLMAssertThrowsWithReason(managed.intObj.allObjects[1], @"index 1 beyond bounds [0 .. 0]");
    RLMAssertThrowsWithReason(managed.floatObj.allObjects[1], @"index 1 beyond bounds [0 .. 0]");
    RLMAssertThrowsWithReason(managed.doubleObj.allObjects[1], @"index 1 beyond bounds [0 .. 0]");
    RLMAssertThrowsWithReason(managed.stringObj.allObjects[1], @"index 1 beyond bounds [0 .. 0]");
    RLMAssertThrowsWithReason(managed.dataObj.allObjects[1], @"index 1 beyond bounds [0 .. 0]");
    RLMAssertThrowsWithReason(managed.dateObj.allObjects[1], @"index 1 beyond bounds [0 .. 0]");
    RLMAssertThrowsWithReason(managed.decimalObj.allObjects[1], @"index 1 beyond bounds [0 .. 0]");
    RLMAssertThrowsWithReason(managed.objectIdObj.allObjects[1], @"index 1 beyond bounds [0 .. 0]");
    RLMAssertThrowsWithReason(managed.uuidObj.allObjects[1], @"index 1 beyond bounds [0 .. 0]");
    RLMAssertThrowsWithReason(optManaged.boolObj.allObjects[1], @"index 1 beyond bounds [0 .. 0]");
    RLMAssertThrowsWithReason(optManaged.intObj.allObjects[1], @"index 1 beyond bounds [0 .. 0]");
    RLMAssertThrowsWithReason(optManaged.floatObj.allObjects[1], @"index 1 beyond bounds [0 .. 0]");
    RLMAssertThrowsWithReason(optManaged.doubleObj.allObjects[1], @"index 1 beyond bounds [0 .. 0]");
    RLMAssertThrowsWithReason(optManaged.stringObj.allObjects[1], @"index 1 beyond bounds [0 .. 0]");
    RLMAssertThrowsWithReason(optManaged.dataObj.allObjects[1], @"index 1 beyond bounds [0 .. 0]");
    RLMAssertThrowsWithReason(optManaged.dateObj.allObjects[1], @"index 1 beyond bounds [0 .. 0]");
    RLMAssertThrowsWithReason(optManaged.decimalObj.allObjects[1], @"index 1 beyond bounds [0 .. 0]");
    RLMAssertThrowsWithReason(optManaged.objectIdObj.allObjects[1], @"index 1 beyond bounds [0 .. 0]");
    RLMAssertThrowsWithReason(optManaged.uuidObj.allObjects[1], @"index 1 beyond bounds [0 .. 0]");

    XCTAssertEqualObjects(unmanaged.boolObj.allObjects[0], @NO);
    XCTAssertEqualObjects(unmanaged.intObj.allObjects[0], @2);
    XCTAssertEqualObjects(unmanaged.floatObj.allObjects[0], @2.2f);
    XCTAssertEqualObjects(unmanaged.doubleObj.allObjects[0], @2.2);
    XCTAssertEqualObjects(unmanaged.stringObj.allObjects[0], @"a");
    XCTAssertEqualObjects(unmanaged.dataObj.allObjects[0], data(1));
    XCTAssertEqualObjects(unmanaged.dateObj.allObjects[0], date(1));
    XCTAssertEqualObjects(unmanaged.decimalObj.allObjects[0], decimal128(1));
    XCTAssertEqualObjects(unmanaged.objectIdObj.allObjects[0], objectId(1));
    XCTAssertEqualObjects(unmanaged.uuidObj.allObjects[0], uuid(@"00000000-0000-0000-0000-000000000000"));
    XCTAssertEqualObjects(optUnmanaged.boolObj.allObjects[0], NSNull.null);
    XCTAssertEqualObjects(optUnmanaged.intObj.allObjects[0], NSNull.null);
    XCTAssertEqualObjects(optUnmanaged.floatObj.allObjects[0], NSNull.null);
    XCTAssertEqualObjects(optUnmanaged.doubleObj.allObjects[0], NSNull.null);
    XCTAssertEqualObjects(optUnmanaged.stringObj.allObjects[0], NSNull.null);
    XCTAssertEqualObjects(optUnmanaged.dataObj.allObjects[0], NSNull.null);
    XCTAssertEqualObjects(optUnmanaged.dateObj.allObjects[0], NSNull.null);
    XCTAssertEqualObjects(optUnmanaged.decimalObj.allObjects[0], NSNull.null);
    XCTAssertEqualObjects(optUnmanaged.objectIdObj.allObjects[0], NSNull.null);
    XCTAssertEqualObjects(optUnmanaged.uuidObj.allObjects[0], NSNull.null);
    XCTAssertEqualObjects(managed.boolObj.allObjects[0], @NO);
    XCTAssertEqualObjects(managed.intObj.allObjects[0], @2);
    XCTAssertEqualObjects(managed.floatObj.allObjects[0], @2.2f);
    XCTAssertEqualObjects(managed.doubleObj.allObjects[0], @2.2);
    XCTAssertEqualObjects(managed.stringObj.allObjects[0], @"a");
    XCTAssertEqualObjects(managed.dataObj.allObjects[0], data(1));
    XCTAssertEqualObjects(managed.dateObj.allObjects[0], date(1));
    XCTAssertEqualObjects(managed.decimalObj.allObjects[0], decimal128(1));
    XCTAssertEqualObjects(managed.objectIdObj.allObjects[0], objectId(1));
    XCTAssertEqualObjects(managed.uuidObj.allObjects[0], uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"));
    XCTAssertEqualObjects(optManaged.boolObj.allObjects[0], NSNull.null);
    XCTAssertEqualObjects(optManaged.intObj.allObjects[0], NSNull.null);
    XCTAssertEqualObjects(optManaged.floatObj.allObjects[0], NSNull.null);
    XCTAssertEqualObjects(optManaged.doubleObj.allObjects[0], NSNull.null);
    XCTAssertEqualObjects(optManaged.stringObj.allObjects[0], NSNull.null);
    XCTAssertEqualObjects(optManaged.dataObj.allObjects[0], NSNull.null);
    XCTAssertEqualObjects(optManaged.dateObj.allObjects[0], NSNull.null);
    XCTAssertEqualObjects(optManaged.decimalObj.allObjects[0], NSNull.null);
    XCTAssertEqualObjects(optManaged.objectIdObj.allObjects[0], NSNull.null);
    XCTAssertEqualObjects(optManaged.uuidObj.allObjects[0], NSNull.null);
    XCTAssertEqualObjects(optUnmanaged.boolObj.allObjects[0], NSNull.null);
    XCTAssertEqualObjects(optUnmanaged.intObj.allObjects[0], NSNull.null);
    XCTAssertEqualObjects(optUnmanaged.floatObj.allObjects[0], NSNull.null);
    XCTAssertEqualObjects(optUnmanaged.doubleObj.allObjects[0], NSNull.null);
    XCTAssertEqualObjects(optUnmanaged.stringObj.allObjects[0], NSNull.null);
    XCTAssertEqualObjects(optUnmanaged.dataObj.allObjects[0], NSNull.null);
    XCTAssertEqualObjects(optUnmanaged.dateObj.allObjects[0], NSNull.null);
    XCTAssertEqualObjects(optUnmanaged.decimalObj.allObjects[0], NSNull.null);
    XCTAssertEqualObjects(optUnmanaged.objectIdObj.allObjects[0], NSNull.null);
    XCTAssertEqualObjects(optUnmanaged.uuidObj.allObjects[0], NSNull.null);
    XCTAssertEqualObjects(optManaged.boolObj.allObjects[0], NSNull.null);
    XCTAssertEqualObjects(optManaged.intObj.allObjects[0], NSNull.null);
    XCTAssertEqualObjects(optManaged.floatObj.allObjects[0], NSNull.null);
    XCTAssertEqualObjects(optManaged.doubleObj.allObjects[0], NSNull.null);
    XCTAssertEqualObjects(optManaged.stringObj.allObjects[0], NSNull.null);
    XCTAssertEqualObjects(optManaged.dataObj.allObjects[0], NSNull.null);
    XCTAssertEqualObjects(optManaged.dateObj.allObjects[0], NSNull.null);
    XCTAssertEqualObjects(optManaged.decimalObj.allObjects[0], NSNull.null);
    XCTAssertEqualObjects(optManaged.objectIdObj.allObjects[0], NSNull.null);
    XCTAssertEqualObjects(optManaged.uuidObj.allObjects[0], NSNull.null);

    [optUnmanaged.boolObj setValue:NSNull.null forKey:@"self"];
    [optUnmanaged.intObj setValue:NSNull.null forKey:@"self"];
    [optUnmanaged.floatObj setValue:NSNull.null forKey:@"self"];
    [optUnmanaged.doubleObj setValue:NSNull.null forKey:@"self"];
    [optUnmanaged.stringObj setValue:NSNull.null forKey:@"self"];
    [optUnmanaged.dataObj setValue:NSNull.null forKey:@"self"];
    [optUnmanaged.dateObj setValue:NSNull.null forKey:@"self"];
    [optUnmanaged.decimalObj setValue:NSNull.null forKey:@"self"];
    [optUnmanaged.objectIdObj setValue:NSNull.null forKey:@"self"];
    [optUnmanaged.uuidObj setValue:NSNull.null forKey:@"self"];
    [optManaged.boolObj setValue:NSNull.null forKey:@"self"];
    [optManaged.intObj setValue:NSNull.null forKey:@"self"];
    [optManaged.floatObj setValue:NSNull.null forKey:@"self"];
    [optManaged.doubleObj setValue:NSNull.null forKey:@"self"];
    [optManaged.stringObj setValue:NSNull.null forKey:@"self"];
    [optManaged.dataObj setValue:NSNull.null forKey:@"self"];
    [optManaged.dateObj setValue:NSNull.null forKey:@"self"];
    [optManaged.decimalObj setValue:NSNull.null forKey:@"self"];
    [optManaged.objectIdObj setValue:NSNull.null forKey:@"self"];
    [optManaged.uuidObj setValue:NSNull.null forKey:@"self"];
    XCTAssertEqualObjects(optUnmanaged.boolObj.allObjects[0], NSNull.null);
    XCTAssertEqualObjects(optUnmanaged.intObj.allObjects[0], NSNull.null);
    XCTAssertEqualObjects(optUnmanaged.floatObj.allObjects[0], NSNull.null);
    XCTAssertEqualObjects(optUnmanaged.doubleObj.allObjects[0], NSNull.null);
    XCTAssertEqualObjects(optUnmanaged.stringObj.allObjects[0], NSNull.null);
    XCTAssertEqualObjects(optUnmanaged.dataObj.allObjects[0], NSNull.null);
    XCTAssertEqualObjects(optUnmanaged.dateObj.allObjects[0], NSNull.null);
    XCTAssertEqualObjects(optUnmanaged.decimalObj.allObjects[0], NSNull.null);
    XCTAssertEqualObjects(optUnmanaged.objectIdObj.allObjects[0], NSNull.null);
    XCTAssertEqualObjects(optUnmanaged.uuidObj.allObjects[0], NSNull.null);
    XCTAssertEqualObjects(optManaged.boolObj.allObjects[0], NSNull.null);
    XCTAssertEqualObjects(optManaged.intObj.allObjects[0], NSNull.null);
    XCTAssertEqualObjects(optManaged.floatObj.allObjects[0], NSNull.null);
    XCTAssertEqualObjects(optManaged.doubleObj.allObjects[0], NSNull.null);
    XCTAssertEqualObjects(optManaged.stringObj.allObjects[0], NSNull.null);
    XCTAssertEqualObjects(optManaged.dataObj.allObjects[0], NSNull.null);
    XCTAssertEqualObjects(optManaged.dateObj.allObjects[0], NSNull.null);
    XCTAssertEqualObjects(optManaged.decimalObj.allObjects[0], NSNull.null);
    XCTAssertEqualObjects(optManaged.objectIdObj.allObjects[0], NSNull.null);
    XCTAssertEqualObjects(optManaged.uuidObj.allObjects[0], NSNull.null);
}

- (void)testAssignment {
    unmanaged.boolObj = (id)@[@YES]; 
     XCTAssertEqualObjects(unmanaged.boolObj.allObjects[0], @YES);
    unmanaged.intObj = (id)@[@3]; 
     XCTAssertEqualObjects(unmanaged.intObj.allObjects[0], @3);
    unmanaged.floatObj = (id)@[@3.3f]; 
     XCTAssertEqualObjects(unmanaged.floatObj.allObjects[0], @3.3f);
    unmanaged.doubleObj = (id)@[@3.3]; 
     XCTAssertEqualObjects(unmanaged.doubleObj.allObjects[0], @3.3);
    unmanaged.stringObj = (id)@[@"bc"]; 
     XCTAssertEqualObjects(unmanaged.stringObj.allObjects[0], @"bc");
    unmanaged.dataObj = (id)@[data(2)]; 
     XCTAssertEqualObjects(unmanaged.dataObj.allObjects[0], data(2));
    unmanaged.dateObj = (id)@[date(2)]; 
     XCTAssertEqualObjects(unmanaged.dateObj.allObjects[0], date(2));
    unmanaged.decimalObj = (id)@[decimal128(2)]; 
     XCTAssertEqualObjects(unmanaged.decimalObj.allObjects[0], decimal128(2));
    unmanaged.objectIdObj = (id)@[objectId(2)]; 
     XCTAssertEqualObjects(unmanaged.objectIdObj.allObjects[0], objectId(2));
    unmanaged.uuidObj = (id)@[uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")]; 
     XCTAssertEqualObjects(unmanaged.uuidObj.allObjects[0], uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"));
    optUnmanaged.boolObj = (id)@[@NO]; 
     XCTAssertEqualObjects(optUnmanaged.boolObj.allObjects[0], @NO);
    optUnmanaged.intObj = (id)@[@2]; 
     XCTAssertEqualObjects(optUnmanaged.intObj.allObjects[0], @2);
    optUnmanaged.floatObj = (id)@[@2.2f]; 
     XCTAssertEqualObjects(optUnmanaged.floatObj.allObjects[0], @2.2f);
    optUnmanaged.doubleObj = (id)@[@2.2]; 
     XCTAssertEqualObjects(optUnmanaged.doubleObj.allObjects[0], @2.2);
    optUnmanaged.stringObj = (id)@[@"a"]; 
     XCTAssertEqualObjects(optUnmanaged.stringObj.allObjects[0], @"a");
    optUnmanaged.dataObj = (id)@[data(1)]; 
     XCTAssertEqualObjects(optUnmanaged.dataObj.allObjects[0], data(1));
    optUnmanaged.dateObj = (id)@[date(1)]; 
     XCTAssertEqualObjects(optUnmanaged.dateObj.allObjects[0], date(1));
    optUnmanaged.decimalObj = (id)@[decimal128(1)]; 
     XCTAssertEqualObjects(optUnmanaged.decimalObj.allObjects[0], decimal128(1));
    optUnmanaged.objectIdObj = (id)@[objectId(1)]; 
     XCTAssertEqualObjects(optUnmanaged.objectIdObj.allObjects[0], objectId(1));
    optUnmanaged.uuidObj = (id)@[uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")]; 
     XCTAssertEqualObjects(optUnmanaged.uuidObj.allObjects[0], uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"));
    managed.boolObj = (id)@[@YES]; 
     XCTAssertEqualObjects(managed.boolObj.allObjects[0], @YES);
    managed.intObj = (id)@[@3]; 
     XCTAssertEqualObjects(managed.intObj.allObjects[0], @3);
    managed.floatObj = (id)@[@3.3f]; 
     XCTAssertEqualObjects(managed.floatObj.allObjects[0], @3.3f);
    managed.doubleObj = (id)@[@3.3]; 
     XCTAssertEqualObjects(managed.doubleObj.allObjects[0], @3.3);
    managed.stringObj = (id)@[@"bc"]; 
     XCTAssertEqualObjects(managed.stringObj.allObjects[0], @"bc");
    managed.dataObj = (id)@[data(2)]; 
     XCTAssertEqualObjects(managed.dataObj.allObjects[0], data(2));
    managed.dateObj = (id)@[date(2)]; 
     XCTAssertEqualObjects(managed.dateObj.allObjects[0], date(2));
    managed.decimalObj = (id)@[decimal128(2)]; 
     XCTAssertEqualObjects(managed.decimalObj.allObjects[0], decimal128(2));
    managed.objectIdObj = (id)@[objectId(2)]; 
     XCTAssertEqualObjects(managed.objectIdObj.allObjects[0], objectId(2));
    managed.uuidObj = (id)@[uuid(@"00000000-0000-0000-0000-000000000000")]; 
     XCTAssertEqualObjects(managed.uuidObj.allObjects[0], uuid(@"00000000-0000-0000-0000-000000000000"));
    optManaged.boolObj = (id)@[@NO]; 
     XCTAssertEqualObjects(optManaged.boolObj.allObjects[0], @NO);
    optManaged.intObj = (id)@[@2]; 
     XCTAssertEqualObjects(optManaged.intObj.allObjects[0], @2);
    optManaged.floatObj = (id)@[@2.2f]; 
     XCTAssertEqualObjects(optManaged.floatObj.allObjects[0], @2.2f);
    optManaged.doubleObj = (id)@[@2.2]; 
     XCTAssertEqualObjects(optManaged.doubleObj.allObjects[0], @2.2);
    optManaged.stringObj = (id)@[@"a"]; 
     XCTAssertEqualObjects(optManaged.stringObj.allObjects[0], @"a");
    optManaged.dataObj = (id)@[data(1)]; 
     XCTAssertEqualObjects(optManaged.dataObj.allObjects[0], data(1));
    optManaged.dateObj = (id)@[date(1)]; 
     XCTAssertEqualObjects(optManaged.dateObj.allObjects[0], date(1));
    optManaged.decimalObj = (id)@[decimal128(1)]; 
     XCTAssertEqualObjects(optManaged.decimalObj.allObjects[0], decimal128(1));
    optManaged.objectIdObj = (id)@[objectId(1)]; 
     XCTAssertEqualObjects(optManaged.objectIdObj.allObjects[0], objectId(1));
    optManaged.uuidObj = (id)@[uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")]; 
     XCTAssertEqualObjects(optManaged.uuidObj.allObjects[0], uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"));

    // Should replace and not append
    unmanaged.boolObj = (id)@[@NO, @YES]; 
     XCTAssertEqualObjects([NSSet setWithArray:[[unmanaged.boolObj valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[@NO, @YES]])); 
    
    unmanaged.intObj = (id)@[@2, @3]; 
     XCTAssertEqualObjects([NSSet setWithArray:[[unmanaged.intObj valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[@2, @3]])); 
    
    unmanaged.floatObj = (id)@[@2.2f, @3.3f]; 
     XCTAssertEqualObjects([NSSet setWithArray:[[unmanaged.floatObj valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[@2.2f, @3.3f]])); 
    
    unmanaged.doubleObj = (id)@[@2.2, @3.3]; 
     XCTAssertEqualObjects([NSSet setWithArray:[[unmanaged.doubleObj valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[@2.2, @3.3]])); 
    
    unmanaged.stringObj = (id)@[@"a", @"bc"]; 
     XCTAssertEqualObjects([NSSet setWithArray:[[unmanaged.stringObj valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[@"a", @"bc"]])); 
    
    unmanaged.dataObj = (id)@[data(1), data(2)]; 
     XCTAssertEqualObjects([NSSet setWithArray:[[unmanaged.dataObj valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[data(1), data(2)]])); 
    
    unmanaged.dateObj = (id)@[date(1), date(2)]; 
     XCTAssertEqualObjects([NSSet setWithArray:[[unmanaged.dateObj valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[date(1), date(2)]])); 
    
    unmanaged.decimalObj = (id)@[decimal128(1), decimal128(2)]; 
     XCTAssertEqualObjects([NSSet setWithArray:[[unmanaged.decimalObj valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[decimal128(1), decimal128(2)]])); 
    
    unmanaged.objectIdObj = (id)@[objectId(1), objectId(2)]; 
     XCTAssertEqualObjects([NSSet setWithArray:[[unmanaged.objectIdObj valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[objectId(1), objectId(2)]])); 
    
    unmanaged.uuidObj = (id)@[uuid(@"00000000-0000-0000-0000-000000000000"), uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")]; 
     XCTAssertEqualObjects([NSSet setWithArray:[[unmanaged.uuidObj valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[uuid(@"00000000-0000-0000-0000-000000000000"), uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")]])); 
    
    optUnmanaged.boolObj = (id)@[NSNull.null, @NO, @YES]; 
     XCTAssertEqualObjects([NSSet setWithArray:[[optUnmanaged.boolObj valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[NSNull.null, @NO, @YES]])); 
    
    optUnmanaged.intObj = (id)@[NSNull.null, @2, @3]; 
     XCTAssertEqualObjects([NSSet setWithArray:[[optUnmanaged.intObj valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[NSNull.null, @2, @3]])); 
    
    optUnmanaged.floatObj = (id)@[NSNull.null, @2.2f, @3.3f]; 
     XCTAssertEqualObjects([NSSet setWithArray:[[optUnmanaged.floatObj valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[NSNull.null, @2.2f, @3.3f]])); 
    
    optUnmanaged.doubleObj = (id)@[NSNull.null, @2.2, @3.3]; 
     XCTAssertEqualObjects([NSSet setWithArray:[[optUnmanaged.doubleObj valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[NSNull.null, @2.2, @3.3]])); 
    
    optUnmanaged.stringObj = (id)@[NSNull.null, @"a", @"bc"]; 
     XCTAssertEqualObjects([NSSet setWithArray:[[optUnmanaged.stringObj valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[NSNull.null, @"a", @"bc"]])); 
    
    optUnmanaged.dataObj = (id)@[NSNull.null, data(1), data(2)]; 
     XCTAssertEqualObjects([NSSet setWithArray:[[optUnmanaged.dataObj valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[NSNull.null, data(1), data(2)]])); 
    
    optUnmanaged.dateObj = (id)@[NSNull.null, date(1), date(2)]; 
     XCTAssertEqualObjects([NSSet setWithArray:[[optUnmanaged.dateObj valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[NSNull.null, date(1), date(2)]])); 
    
    optUnmanaged.decimalObj = (id)@[NSNull.null, decimal128(1), decimal128(2)]; 
     XCTAssertEqualObjects([NSSet setWithArray:[[optUnmanaged.decimalObj valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[NSNull.null, decimal128(1), decimal128(2)]])); 
    
    optUnmanaged.objectIdObj = (id)@[NSNull.null, objectId(1), objectId(2)]; 
     XCTAssertEqualObjects([NSSet setWithArray:[[optUnmanaged.objectIdObj valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[NSNull.null, objectId(1), objectId(2)]])); 
    
    optUnmanaged.uuidObj = (id)@[NSNull.null, uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"), uuid(@"00000000-0000-0000-0000-000000000000")]; 
     XCTAssertEqualObjects([NSSet setWithArray:[[optUnmanaged.uuidObj valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[NSNull.null, uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"), uuid(@"00000000-0000-0000-0000-000000000000")]])); 
    
    managed.boolObj = (id)@[@NO, @YES]; 
     XCTAssertEqualObjects([NSSet setWithArray:[[managed.boolObj valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[@NO, @YES]])); 
    
    managed.intObj = (id)@[@2, @3]; 
     XCTAssertEqualObjects([NSSet setWithArray:[[managed.intObj valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[@2, @3]])); 
    
    managed.floatObj = (id)@[@2.2f, @3.3f]; 
     XCTAssertEqualObjects([NSSet setWithArray:[[managed.floatObj valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[@2.2f, @3.3f]])); 
    
    managed.doubleObj = (id)@[@2.2, @3.3]; 
     XCTAssertEqualObjects([NSSet setWithArray:[[managed.doubleObj valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[@2.2, @3.3]])); 
    
    managed.stringObj = (id)@[@"a", @"bc"]; 
     XCTAssertEqualObjects([NSSet setWithArray:[[managed.stringObj valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[@"a", @"bc"]])); 
    
    managed.dataObj = (id)@[data(1), data(2)]; 
     XCTAssertEqualObjects([NSSet setWithArray:[[managed.dataObj valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[data(1), data(2)]])); 
    
    managed.dateObj = (id)@[date(1), date(2)]; 
     XCTAssertEqualObjects([NSSet setWithArray:[[managed.dateObj valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[date(1), date(2)]])); 
    
    managed.decimalObj = (id)@[decimal128(1), decimal128(2)]; 
     XCTAssertEqualObjects([NSSet setWithArray:[[managed.decimalObj valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[decimal128(1), decimal128(2)]])); 
    
    managed.objectIdObj = (id)@[objectId(1), objectId(2)]; 
     XCTAssertEqualObjects([NSSet setWithArray:[[managed.objectIdObj valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[objectId(1), objectId(2)]])); 
    
    managed.uuidObj = (id)@[uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"), uuid(@"00000000-0000-0000-0000-000000000000")]; 
     XCTAssertEqualObjects([NSSet setWithArray:[[managed.uuidObj valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"), uuid(@"00000000-0000-0000-0000-000000000000")]])); 
    
    optManaged.boolObj = (id)@[NSNull.null, @NO, @YES]; 
     XCTAssertEqualObjects([NSSet setWithArray:[[optManaged.boolObj valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[NSNull.null, @NO, @YES]])); 
    
    optManaged.intObj = (id)@[NSNull.null, @2, @3]; 
     XCTAssertEqualObjects([NSSet setWithArray:[[optManaged.intObj valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[NSNull.null, @2, @3]])); 
    
    optManaged.floatObj = (id)@[NSNull.null, @2.2f, @3.3f]; 
     XCTAssertEqualObjects([NSSet setWithArray:[[optManaged.floatObj valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[NSNull.null, @2.2f, @3.3f]])); 
    
    optManaged.doubleObj = (id)@[NSNull.null, @2.2, @3.3]; 
     XCTAssertEqualObjects([NSSet setWithArray:[[optManaged.doubleObj valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[NSNull.null, @2.2, @3.3]])); 
    
    optManaged.stringObj = (id)@[NSNull.null, @"a", @"bc"]; 
     XCTAssertEqualObjects([NSSet setWithArray:[[optManaged.stringObj valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[NSNull.null, @"a", @"bc"]])); 
    
    optManaged.dataObj = (id)@[NSNull.null, data(1), data(2)]; 
     XCTAssertEqualObjects([NSSet setWithArray:[[optManaged.dataObj valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[NSNull.null, data(1), data(2)]])); 
    
    optManaged.dateObj = (id)@[NSNull.null, date(1), date(2)]; 
     XCTAssertEqualObjects([NSSet setWithArray:[[optManaged.dateObj valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[NSNull.null, date(1), date(2)]])); 
    
    optManaged.decimalObj = (id)@[NSNull.null, decimal128(1), decimal128(2)]; 
     XCTAssertEqualObjects([NSSet setWithArray:[[optManaged.decimalObj valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[NSNull.null, decimal128(1), decimal128(2)]])); 
    
    optManaged.objectIdObj = (id)@[NSNull.null, objectId(1), objectId(2)]; 
     XCTAssertEqualObjects([NSSet setWithArray:[[optManaged.objectIdObj valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[NSNull.null, objectId(1), objectId(2)]])); 
    
    optManaged.uuidObj = (id)@[NSNull.null, uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"), uuid(@"00000000-0000-0000-0000-000000000000")]; 
     XCTAssertEqualObjects([NSSet setWithArray:[[optManaged.uuidObj valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[NSNull.null, uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"), uuid(@"00000000-0000-0000-0000-000000000000")]])); 
    

    // Should not clear the set
    unmanaged.boolObj = unmanaged.boolObj; 
     XCTAssertEqualObjects([NSSet setWithArray:[[unmanaged.boolObj valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[@NO, @YES]])); 
    
    unmanaged.intObj = unmanaged.intObj; 
     XCTAssertEqualObjects([NSSet setWithArray:[[unmanaged.intObj valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[@2, @3]])); 
    
    unmanaged.floatObj = unmanaged.floatObj; 
     XCTAssertEqualObjects([NSSet setWithArray:[[unmanaged.floatObj valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[@2.2f, @3.3f]])); 
    
    unmanaged.doubleObj = unmanaged.doubleObj; 
     XCTAssertEqualObjects([NSSet setWithArray:[[unmanaged.doubleObj valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[@2.2, @3.3]])); 
    
    unmanaged.stringObj = unmanaged.stringObj; 
     XCTAssertEqualObjects([NSSet setWithArray:[[unmanaged.stringObj valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[@"a", @"bc"]])); 
    
    unmanaged.dataObj = unmanaged.dataObj; 
     XCTAssertEqualObjects([NSSet setWithArray:[[unmanaged.dataObj valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[data(1), data(2)]])); 
    
    unmanaged.dateObj = unmanaged.dateObj; 
     XCTAssertEqualObjects([NSSet setWithArray:[[unmanaged.dateObj valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[date(1), date(2)]])); 
    
    unmanaged.decimalObj = unmanaged.decimalObj; 
     XCTAssertEqualObjects([NSSet setWithArray:[[unmanaged.decimalObj valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[decimal128(1), decimal128(2)]])); 
    
    unmanaged.objectIdObj = unmanaged.objectIdObj; 
     XCTAssertEqualObjects([NSSet setWithArray:[[unmanaged.objectIdObj valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[objectId(1), objectId(2)]])); 
    
    unmanaged.uuidObj = unmanaged.uuidObj; 
     XCTAssertEqualObjects([NSSet setWithArray:[[unmanaged.uuidObj valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[uuid(@"00000000-0000-0000-0000-000000000000"), uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")]])); 
    
    optUnmanaged.boolObj = optUnmanaged.boolObj; 
     XCTAssertEqualObjects([NSSet setWithArray:[[optUnmanaged.boolObj valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[NSNull.null, @NO, @YES]])); 
    
    optUnmanaged.intObj = optUnmanaged.intObj; 
     XCTAssertEqualObjects([NSSet setWithArray:[[optUnmanaged.intObj valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[NSNull.null, @2, @3]])); 
    
    optUnmanaged.floatObj = optUnmanaged.floatObj; 
     XCTAssertEqualObjects([NSSet setWithArray:[[optUnmanaged.floatObj valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[NSNull.null, @2.2f, @3.3f]])); 
    
    optUnmanaged.doubleObj = optUnmanaged.doubleObj; 
     XCTAssertEqualObjects([NSSet setWithArray:[[optUnmanaged.doubleObj valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[NSNull.null, @2.2, @3.3]])); 
    
    optUnmanaged.stringObj = optUnmanaged.stringObj; 
     XCTAssertEqualObjects([NSSet setWithArray:[[optUnmanaged.stringObj valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[NSNull.null, @"a", @"bc"]])); 
    
    optUnmanaged.dataObj = optUnmanaged.dataObj; 
     XCTAssertEqualObjects([NSSet setWithArray:[[optUnmanaged.dataObj valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[NSNull.null, data(1), data(2)]])); 
    
    optUnmanaged.dateObj = optUnmanaged.dateObj; 
     XCTAssertEqualObjects([NSSet setWithArray:[[optUnmanaged.dateObj valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[NSNull.null, date(1), date(2)]])); 
    
    optUnmanaged.decimalObj = optUnmanaged.decimalObj; 
     XCTAssertEqualObjects([NSSet setWithArray:[[optUnmanaged.decimalObj valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[NSNull.null, decimal128(1), decimal128(2)]])); 
    
    optUnmanaged.objectIdObj = optUnmanaged.objectIdObj; 
     XCTAssertEqualObjects([NSSet setWithArray:[[optUnmanaged.objectIdObj valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[NSNull.null, objectId(1), objectId(2)]])); 
    
    optUnmanaged.uuidObj = optUnmanaged.uuidObj; 
     XCTAssertEqualObjects([NSSet setWithArray:[[optUnmanaged.uuidObj valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[NSNull.null, uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"), uuid(@"00000000-0000-0000-0000-000000000000")]])); 
    
    managed.boolObj = managed.boolObj; 
     XCTAssertEqualObjects([NSSet setWithArray:[[managed.boolObj valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[@NO, @YES]])); 
    
    managed.intObj = managed.intObj; 
     XCTAssertEqualObjects([NSSet setWithArray:[[managed.intObj valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[@2, @3]])); 
    
    managed.floatObj = managed.floatObj; 
     XCTAssertEqualObjects([NSSet setWithArray:[[managed.floatObj valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[@2.2f, @3.3f]])); 
    
    managed.doubleObj = managed.doubleObj; 
     XCTAssertEqualObjects([NSSet setWithArray:[[managed.doubleObj valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[@2.2, @3.3]])); 
    
    managed.stringObj = managed.stringObj; 
     XCTAssertEqualObjects([NSSet setWithArray:[[managed.stringObj valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[@"a", @"bc"]])); 
    
    managed.dataObj = managed.dataObj; 
     XCTAssertEqualObjects([NSSet setWithArray:[[managed.dataObj valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[data(1), data(2)]])); 
    
    managed.dateObj = managed.dateObj; 
     XCTAssertEqualObjects([NSSet setWithArray:[[managed.dateObj valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[date(1), date(2)]])); 
    
    managed.decimalObj = managed.decimalObj; 
     XCTAssertEqualObjects([NSSet setWithArray:[[managed.decimalObj valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[decimal128(1), decimal128(2)]])); 
    
    managed.objectIdObj = managed.objectIdObj; 
     XCTAssertEqualObjects([NSSet setWithArray:[[managed.objectIdObj valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[objectId(1), objectId(2)]])); 
    
    managed.uuidObj = managed.uuidObj; 
     XCTAssertEqualObjects([NSSet setWithArray:[[managed.uuidObj valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"), uuid(@"00000000-0000-0000-0000-000000000000")]])); 
    
    optManaged.boolObj = optManaged.boolObj; 
     XCTAssertEqualObjects([NSSet setWithArray:[[optManaged.boolObj valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[NSNull.null, @NO, @YES]])); 
    
    optManaged.intObj = optManaged.intObj; 
     XCTAssertEqualObjects([NSSet setWithArray:[[optManaged.intObj valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[NSNull.null, @2, @3]])); 
    
    optManaged.floatObj = optManaged.floatObj; 
     XCTAssertEqualObjects([NSSet setWithArray:[[optManaged.floatObj valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[NSNull.null, @2.2f, @3.3f]])); 
    
    optManaged.doubleObj = optManaged.doubleObj; 
     XCTAssertEqualObjects([NSSet setWithArray:[[optManaged.doubleObj valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[NSNull.null, @2.2, @3.3]])); 
    
    optManaged.stringObj = optManaged.stringObj; 
     XCTAssertEqualObjects([NSSet setWithArray:[[optManaged.stringObj valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[NSNull.null, @"a", @"bc"]])); 
    
    optManaged.dataObj = optManaged.dataObj; 
     XCTAssertEqualObjects([NSSet setWithArray:[[optManaged.dataObj valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[NSNull.null, data(1), data(2)]])); 
    
    optManaged.dateObj = optManaged.dateObj; 
     XCTAssertEqualObjects([NSSet setWithArray:[[optManaged.dateObj valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[NSNull.null, date(1), date(2)]])); 
    
    optManaged.decimalObj = optManaged.decimalObj; 
     XCTAssertEqualObjects([NSSet setWithArray:[[optManaged.decimalObj valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[NSNull.null, decimal128(1), decimal128(2)]])); 
    
    optManaged.objectIdObj = optManaged.objectIdObj; 
     XCTAssertEqualObjects([NSSet setWithArray:[[optManaged.objectIdObj valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[NSNull.null, objectId(1), objectId(2)]])); 
    
    optManaged.uuidObj = optManaged.uuidObj; 
     XCTAssertEqualObjects([NSSet setWithArray:[[optManaged.uuidObj valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[NSNull.null, uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"), uuid(@"00000000-0000-0000-0000-000000000000")]])); 
    

    [unmanaged.intObj removeAllObjects];
    unmanaged.intObj = managed.intObj;
    XCTAssertEqualObjects([NSSet setWithArray:[[unmanaged.intObj valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[@2, @3]]));

    [managed.intObj removeAllObjects];
    managed.intObj = unmanaged.intObj;
    XCTAssertEqualObjects([NSSet setWithArray:[[managed.intObj valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[@2, @3]]));
}

- (void)testDynamicAssignment {
    unmanaged[@"boolObj"] = (id)@[@YES]; 
     XCTAssertEqualObjects(((RLMSet *)unmanaged[@"boolObj"]).allObjects[0], @YES);
    unmanaged[@"intObj"] = (id)@[@3]; 
     XCTAssertEqualObjects(((RLMSet *)unmanaged[@"intObj"]).allObjects[0], @3);
    unmanaged[@"floatObj"] = (id)@[@3.3f]; 
     XCTAssertEqualObjects(((RLMSet *)unmanaged[@"floatObj"]).allObjects[0], @3.3f);
    unmanaged[@"doubleObj"] = (id)@[@3.3]; 
     XCTAssertEqualObjects(((RLMSet *)unmanaged[@"doubleObj"]).allObjects[0], @3.3);
    unmanaged[@"stringObj"] = (id)@[@"bc"]; 
     XCTAssertEqualObjects(((RLMSet *)unmanaged[@"stringObj"]).allObjects[0], @"bc");
    unmanaged[@"dataObj"] = (id)@[data(2)]; 
     XCTAssertEqualObjects(((RLMSet *)unmanaged[@"dataObj"]).allObjects[0], data(2));
    unmanaged[@"dateObj"] = (id)@[date(2)]; 
     XCTAssertEqualObjects(((RLMSet *)unmanaged[@"dateObj"]).allObjects[0], date(2));
    unmanaged[@"decimalObj"] = (id)@[decimal128(2)]; 
     XCTAssertEqualObjects(((RLMSet *)unmanaged[@"decimalObj"]).allObjects[0], decimal128(2));
    unmanaged[@"objectIdObj"] = (id)@[objectId(2)]; 
     XCTAssertEqualObjects(((RLMSet *)unmanaged[@"objectIdObj"]).allObjects[0], objectId(2));
    unmanaged[@"uuidObj"] = (id)@[uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")]; 
     XCTAssertEqualObjects(((RLMSet *)unmanaged[@"uuidObj"]).allObjects[0], uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"));
    optUnmanaged[@"boolObj"] = (id)@[@NO]; 
     XCTAssertEqualObjects(((RLMSet *)optUnmanaged[@"boolObj"]).allObjects[0], @NO);
    optUnmanaged[@"intObj"] = (id)@[@2]; 
     XCTAssertEqualObjects(((RLMSet *)optUnmanaged[@"intObj"]).allObjects[0], @2);
    optUnmanaged[@"floatObj"] = (id)@[@2.2f]; 
     XCTAssertEqualObjects(((RLMSet *)optUnmanaged[@"floatObj"]).allObjects[0], @2.2f);
    optUnmanaged[@"doubleObj"] = (id)@[@2.2]; 
     XCTAssertEqualObjects(((RLMSet *)optUnmanaged[@"doubleObj"]).allObjects[0], @2.2);
    optUnmanaged[@"stringObj"] = (id)@[@"a"]; 
     XCTAssertEqualObjects(((RLMSet *)optUnmanaged[@"stringObj"]).allObjects[0], @"a");
    optUnmanaged[@"dataObj"] = (id)@[data(1)]; 
     XCTAssertEqualObjects(((RLMSet *)optUnmanaged[@"dataObj"]).allObjects[0], data(1));
    optUnmanaged[@"dateObj"] = (id)@[date(1)]; 
     XCTAssertEqualObjects(((RLMSet *)optUnmanaged[@"dateObj"]).allObjects[0], date(1));
    optUnmanaged[@"decimalObj"] = (id)@[decimal128(1)]; 
     XCTAssertEqualObjects(((RLMSet *)optUnmanaged[@"decimalObj"]).allObjects[0], decimal128(1));
    optUnmanaged[@"objectIdObj"] = (id)@[objectId(1)]; 
     XCTAssertEqualObjects(((RLMSet *)optUnmanaged[@"objectIdObj"]).allObjects[0], objectId(1));
    optUnmanaged[@"uuidObj"] = (id)@[uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")]; 
     XCTAssertEqualObjects(((RLMSet *)optUnmanaged[@"uuidObj"]).allObjects[0], uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"));
    managed[@"boolObj"] = (id)@[@YES]; 
     XCTAssertEqualObjects(((RLMSet *)managed[@"boolObj"]).allObjects[0], @YES);
    managed[@"intObj"] = (id)@[@3]; 
     XCTAssertEqualObjects(((RLMSet *)managed[@"intObj"]).allObjects[0], @3);
    managed[@"floatObj"] = (id)@[@3.3f]; 
     XCTAssertEqualObjects(((RLMSet *)managed[@"floatObj"]).allObjects[0], @3.3f);
    managed[@"doubleObj"] = (id)@[@3.3]; 
     XCTAssertEqualObjects(((RLMSet *)managed[@"doubleObj"]).allObjects[0], @3.3);
    managed[@"stringObj"] = (id)@[@"bc"]; 
     XCTAssertEqualObjects(((RLMSet *)managed[@"stringObj"]).allObjects[0], @"bc");
    managed[@"dataObj"] = (id)@[data(2)]; 
     XCTAssertEqualObjects(((RLMSet *)managed[@"dataObj"]).allObjects[0], data(2));
    managed[@"dateObj"] = (id)@[date(2)]; 
     XCTAssertEqualObjects(((RLMSet *)managed[@"dateObj"]).allObjects[0], date(2));
    managed[@"decimalObj"] = (id)@[decimal128(2)]; 
     XCTAssertEqualObjects(((RLMSet *)managed[@"decimalObj"]).allObjects[0], decimal128(2));
    managed[@"objectIdObj"] = (id)@[objectId(2)]; 
     XCTAssertEqualObjects(((RLMSet *)managed[@"objectIdObj"]).allObjects[0], objectId(2));
    managed[@"uuidObj"] = (id)@[uuid(@"00000000-0000-0000-0000-000000000000")]; 
     XCTAssertEqualObjects(((RLMSet *)managed[@"uuidObj"]).allObjects[0], uuid(@"00000000-0000-0000-0000-000000000000"));
    optManaged[@"boolObj"] = (id)@[@NO]; 
     XCTAssertEqualObjects(((RLMSet *)optManaged[@"boolObj"]).allObjects[0], @NO);
    optManaged[@"intObj"] = (id)@[@2]; 
     XCTAssertEqualObjects(((RLMSet *)optManaged[@"intObj"]).allObjects[0], @2);
    optManaged[@"floatObj"] = (id)@[@2.2f]; 
     XCTAssertEqualObjects(((RLMSet *)optManaged[@"floatObj"]).allObjects[0], @2.2f);
    optManaged[@"doubleObj"] = (id)@[@2.2]; 
     XCTAssertEqualObjects(((RLMSet *)optManaged[@"doubleObj"]).allObjects[0], @2.2);
    optManaged[@"stringObj"] = (id)@[@"a"]; 
     XCTAssertEqualObjects(((RLMSet *)optManaged[@"stringObj"]).allObjects[0], @"a");
    optManaged[@"dataObj"] = (id)@[data(1)]; 
     XCTAssertEqualObjects(((RLMSet *)optManaged[@"dataObj"]).allObjects[0], data(1));
    optManaged[@"dateObj"] = (id)@[date(1)]; 
     XCTAssertEqualObjects(((RLMSet *)optManaged[@"dateObj"]).allObjects[0], date(1));
    optManaged[@"decimalObj"] = (id)@[decimal128(1)]; 
     XCTAssertEqualObjects(((RLMSet *)optManaged[@"decimalObj"]).allObjects[0], decimal128(1));
    optManaged[@"objectIdObj"] = (id)@[objectId(1)]; 
     XCTAssertEqualObjects(((RLMSet *)optManaged[@"objectIdObj"]).allObjects[0], objectId(1));
    optManaged[@"uuidObj"] = (id)@[uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")]; 
     XCTAssertEqualObjects(((RLMSet *)optManaged[@"uuidObj"]).allObjects[0], uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"));

    // Should replace and not append
    unmanaged[@"boolObj"] = (id)@[@NO, @YES]; 
     XCTAssertEqualObjects([NSSet setWithArray:[[unmanaged[@"boolObj"] valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[@NO, @YES]])); 
    
    unmanaged[@"intObj"] = (id)@[@2, @3]; 
     XCTAssertEqualObjects([NSSet setWithArray:[[unmanaged[@"intObj"] valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[@2, @3]])); 
    
    unmanaged[@"floatObj"] = (id)@[@2.2f, @3.3f]; 
     XCTAssertEqualObjects([NSSet setWithArray:[[unmanaged[@"floatObj"] valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[@2.2f, @3.3f]])); 
    
    unmanaged[@"doubleObj"] = (id)@[@2.2, @3.3]; 
     XCTAssertEqualObjects([NSSet setWithArray:[[unmanaged[@"doubleObj"] valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[@2.2, @3.3]])); 
    
    unmanaged[@"stringObj"] = (id)@[@"a", @"bc"]; 
     XCTAssertEqualObjects([NSSet setWithArray:[[unmanaged[@"stringObj"] valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[@"a", @"bc"]])); 
    
    unmanaged[@"dataObj"] = (id)@[data(1), data(2)]; 
     XCTAssertEqualObjects([NSSet setWithArray:[[unmanaged[@"dataObj"] valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[data(1), data(2)]])); 
    
    unmanaged[@"dateObj"] = (id)@[date(1), date(2)]; 
     XCTAssertEqualObjects([NSSet setWithArray:[[unmanaged[@"dateObj"] valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[date(1), date(2)]])); 
    
    unmanaged[@"decimalObj"] = (id)@[decimal128(1), decimal128(2)]; 
     XCTAssertEqualObjects([NSSet setWithArray:[[unmanaged[@"decimalObj"] valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[decimal128(1), decimal128(2)]])); 
    
    unmanaged[@"objectIdObj"] = (id)@[objectId(1), objectId(2)]; 
     XCTAssertEqualObjects([NSSet setWithArray:[[unmanaged[@"objectIdObj"] valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[objectId(1), objectId(2)]])); 
    
    unmanaged[@"uuidObj"] = (id)@[uuid(@"00000000-0000-0000-0000-000000000000"), uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")]; 
     XCTAssertEqualObjects([NSSet setWithArray:[[unmanaged[@"uuidObj"] valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[uuid(@"00000000-0000-0000-0000-000000000000"), uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")]])); 
    
    optUnmanaged[@"boolObj"] = (id)@[NSNull.null, @NO, @YES]; 
     XCTAssertEqualObjects([NSSet setWithArray:[[optUnmanaged[@"boolObj"] valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[NSNull.null, @NO, @YES]])); 
    
    optUnmanaged[@"intObj"] = (id)@[NSNull.null, @2, @3]; 
     XCTAssertEqualObjects([NSSet setWithArray:[[optUnmanaged[@"intObj"] valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[NSNull.null, @2, @3]])); 
    
    optUnmanaged[@"floatObj"] = (id)@[NSNull.null, @2.2f, @3.3f]; 
     XCTAssertEqualObjects([NSSet setWithArray:[[optUnmanaged[@"floatObj"] valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[NSNull.null, @2.2f, @3.3f]])); 
    
    optUnmanaged[@"doubleObj"] = (id)@[NSNull.null, @2.2, @3.3]; 
     XCTAssertEqualObjects([NSSet setWithArray:[[optUnmanaged[@"doubleObj"] valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[NSNull.null, @2.2, @3.3]])); 
    
    optUnmanaged[@"stringObj"] = (id)@[NSNull.null, @"a", @"bc"]; 
     XCTAssertEqualObjects([NSSet setWithArray:[[optUnmanaged[@"stringObj"] valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[NSNull.null, @"a", @"bc"]])); 
    
    optUnmanaged[@"dataObj"] = (id)@[NSNull.null, data(1), data(2)]; 
     XCTAssertEqualObjects([NSSet setWithArray:[[optUnmanaged[@"dataObj"] valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[NSNull.null, data(1), data(2)]])); 
    
    optUnmanaged[@"dateObj"] = (id)@[NSNull.null, date(1), date(2)]; 
     XCTAssertEqualObjects([NSSet setWithArray:[[optUnmanaged[@"dateObj"] valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[NSNull.null, date(1), date(2)]])); 
    
    optUnmanaged[@"decimalObj"] = (id)@[NSNull.null, decimal128(1), decimal128(2)]; 
     XCTAssertEqualObjects([NSSet setWithArray:[[optUnmanaged[@"decimalObj"] valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[NSNull.null, decimal128(1), decimal128(2)]])); 
    
    optUnmanaged[@"objectIdObj"] = (id)@[NSNull.null, objectId(1), objectId(2)]; 
     XCTAssertEqualObjects([NSSet setWithArray:[[optUnmanaged[@"objectIdObj"] valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[NSNull.null, objectId(1), objectId(2)]])); 
    
    optUnmanaged[@"uuidObj"] = (id)@[NSNull.null, uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"), uuid(@"00000000-0000-0000-0000-000000000000")]; 
     XCTAssertEqualObjects([NSSet setWithArray:[[optUnmanaged[@"uuidObj"] valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[NSNull.null, uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"), uuid(@"00000000-0000-0000-0000-000000000000")]])); 
    
    managed[@"boolObj"] = (id)@[@NO, @YES]; 
     XCTAssertEqualObjects([NSSet setWithArray:[[managed[@"boolObj"] valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[@NO, @YES]])); 
    
    managed[@"intObj"] = (id)@[@2, @3]; 
     XCTAssertEqualObjects([NSSet setWithArray:[[managed[@"intObj"] valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[@2, @3]])); 
    
    managed[@"floatObj"] = (id)@[@2.2f, @3.3f]; 
     XCTAssertEqualObjects([NSSet setWithArray:[[managed[@"floatObj"] valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[@2.2f, @3.3f]])); 
    
    managed[@"doubleObj"] = (id)@[@2.2, @3.3]; 
     XCTAssertEqualObjects([NSSet setWithArray:[[managed[@"doubleObj"] valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[@2.2, @3.3]])); 
    
    managed[@"stringObj"] = (id)@[@"a", @"bc"]; 
     XCTAssertEqualObjects([NSSet setWithArray:[[managed[@"stringObj"] valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[@"a", @"bc"]])); 
    
    managed[@"dataObj"] = (id)@[data(1), data(2)]; 
     XCTAssertEqualObjects([NSSet setWithArray:[[managed[@"dataObj"] valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[data(1), data(2)]])); 
    
    managed[@"dateObj"] = (id)@[date(1), date(2)]; 
     XCTAssertEqualObjects([NSSet setWithArray:[[managed[@"dateObj"] valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[date(1), date(2)]])); 
    
    managed[@"decimalObj"] = (id)@[decimal128(1), decimal128(2)]; 
     XCTAssertEqualObjects([NSSet setWithArray:[[managed[@"decimalObj"] valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[decimal128(1), decimal128(2)]])); 
    
    managed[@"objectIdObj"] = (id)@[objectId(1), objectId(2)]; 
     XCTAssertEqualObjects([NSSet setWithArray:[[managed[@"objectIdObj"] valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[objectId(1), objectId(2)]])); 
    
    managed[@"uuidObj"] = (id)@[uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"), uuid(@"00000000-0000-0000-0000-000000000000")]; 
     XCTAssertEqualObjects([NSSet setWithArray:[[managed[@"uuidObj"] valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"), uuid(@"00000000-0000-0000-0000-000000000000")]])); 
    
    optManaged[@"boolObj"] = (id)@[NSNull.null, @NO, @YES]; 
     XCTAssertEqualObjects([NSSet setWithArray:[[optManaged[@"boolObj"] valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[NSNull.null, @NO, @YES]])); 
    
    optManaged[@"intObj"] = (id)@[NSNull.null, @2, @3]; 
     XCTAssertEqualObjects([NSSet setWithArray:[[optManaged[@"intObj"] valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[NSNull.null, @2, @3]])); 
    
    optManaged[@"floatObj"] = (id)@[NSNull.null, @2.2f, @3.3f]; 
     XCTAssertEqualObjects([NSSet setWithArray:[[optManaged[@"floatObj"] valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[NSNull.null, @2.2f, @3.3f]])); 
    
    optManaged[@"doubleObj"] = (id)@[NSNull.null, @2.2, @3.3]; 
     XCTAssertEqualObjects([NSSet setWithArray:[[optManaged[@"doubleObj"] valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[NSNull.null, @2.2, @3.3]])); 
    
    optManaged[@"stringObj"] = (id)@[NSNull.null, @"a", @"bc"]; 
     XCTAssertEqualObjects([NSSet setWithArray:[[optManaged[@"stringObj"] valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[NSNull.null, @"a", @"bc"]])); 
    
    optManaged[@"dataObj"] = (id)@[NSNull.null, data(1), data(2)]; 
     XCTAssertEqualObjects([NSSet setWithArray:[[optManaged[@"dataObj"] valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[NSNull.null, data(1), data(2)]])); 
    
    optManaged[@"dateObj"] = (id)@[NSNull.null, date(1), date(2)]; 
     XCTAssertEqualObjects([NSSet setWithArray:[[optManaged[@"dateObj"] valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[NSNull.null, date(1), date(2)]])); 
    
    optManaged[@"decimalObj"] = (id)@[NSNull.null, decimal128(1), decimal128(2)]; 
     XCTAssertEqualObjects([NSSet setWithArray:[[optManaged[@"decimalObj"] valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[NSNull.null, decimal128(1), decimal128(2)]])); 
    
    optManaged[@"objectIdObj"] = (id)@[NSNull.null, objectId(1), objectId(2)]; 
     XCTAssertEqualObjects([NSSet setWithArray:[[optManaged[@"objectIdObj"] valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[NSNull.null, objectId(1), objectId(2)]])); 
    
    optManaged[@"uuidObj"] = (id)@[NSNull.null, uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"), uuid(@"00000000-0000-0000-0000-000000000000")]; 
     XCTAssertEqualObjects([NSSet setWithArray:[[optManaged[@"uuidObj"] valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[NSNull.null, uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"), uuid(@"00000000-0000-0000-0000-000000000000")]])); 
    

    // Should not clear the set
    unmanaged[@"boolObj"] = unmanaged[@"boolObj"]; 
     XCTAssertEqualObjects([NSSet setWithArray:[[unmanaged[@"boolObj"] valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[@NO, @YES]])); 
    
    unmanaged[@"intObj"] = unmanaged[@"intObj"]; 
     XCTAssertEqualObjects([NSSet setWithArray:[[unmanaged[@"intObj"] valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[@2, @3]])); 
    
    unmanaged[@"floatObj"] = unmanaged[@"floatObj"]; 
     XCTAssertEqualObjects([NSSet setWithArray:[[unmanaged[@"floatObj"] valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[@2.2f, @3.3f]])); 
    
    unmanaged[@"doubleObj"] = unmanaged[@"doubleObj"]; 
     XCTAssertEqualObjects([NSSet setWithArray:[[unmanaged[@"doubleObj"] valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[@2.2, @3.3]])); 
    
    unmanaged[@"stringObj"] = unmanaged[@"stringObj"]; 
     XCTAssertEqualObjects([NSSet setWithArray:[[unmanaged[@"stringObj"] valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[@"a", @"bc"]])); 
    
    unmanaged[@"dataObj"] = unmanaged[@"dataObj"]; 
     XCTAssertEqualObjects([NSSet setWithArray:[[unmanaged[@"dataObj"] valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[data(1), data(2)]])); 
    
    unmanaged[@"dateObj"] = unmanaged[@"dateObj"]; 
     XCTAssertEqualObjects([NSSet setWithArray:[[unmanaged[@"dateObj"] valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[date(1), date(2)]])); 
    
    unmanaged[@"decimalObj"] = unmanaged[@"decimalObj"]; 
     XCTAssertEqualObjects([NSSet setWithArray:[[unmanaged[@"decimalObj"] valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[decimal128(1), decimal128(2)]])); 
    
    unmanaged[@"objectIdObj"] = unmanaged[@"objectIdObj"]; 
     XCTAssertEqualObjects([NSSet setWithArray:[[unmanaged[@"objectIdObj"] valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[objectId(1), objectId(2)]])); 
    
    unmanaged[@"uuidObj"] = unmanaged[@"uuidObj"]; 
     XCTAssertEqualObjects([NSSet setWithArray:[[unmanaged[@"uuidObj"] valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[uuid(@"00000000-0000-0000-0000-000000000000"), uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")]])); 
    
    optUnmanaged[@"boolObj"] = optUnmanaged[@"boolObj"]; 
     XCTAssertEqualObjects([NSSet setWithArray:[[optUnmanaged[@"boolObj"] valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[NSNull.null, @NO, @YES]])); 
    
    optUnmanaged[@"intObj"] = optUnmanaged[@"intObj"]; 
     XCTAssertEqualObjects([NSSet setWithArray:[[optUnmanaged[@"intObj"] valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[NSNull.null, @2, @3]])); 
    
    optUnmanaged[@"floatObj"] = optUnmanaged[@"floatObj"]; 
     XCTAssertEqualObjects([NSSet setWithArray:[[optUnmanaged[@"floatObj"] valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[NSNull.null, @2.2f, @3.3f]])); 
    
    optUnmanaged[@"doubleObj"] = optUnmanaged[@"doubleObj"]; 
     XCTAssertEqualObjects([NSSet setWithArray:[[optUnmanaged[@"doubleObj"] valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[NSNull.null, @2.2, @3.3]])); 
    
    optUnmanaged[@"stringObj"] = optUnmanaged[@"stringObj"]; 
     XCTAssertEqualObjects([NSSet setWithArray:[[optUnmanaged[@"stringObj"] valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[NSNull.null, @"a", @"bc"]])); 
    
    optUnmanaged[@"dataObj"] = optUnmanaged[@"dataObj"]; 
     XCTAssertEqualObjects([NSSet setWithArray:[[optUnmanaged[@"dataObj"] valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[NSNull.null, data(1), data(2)]])); 
    
    optUnmanaged[@"dateObj"] = optUnmanaged[@"dateObj"]; 
     XCTAssertEqualObjects([NSSet setWithArray:[[optUnmanaged[@"dateObj"] valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[NSNull.null, date(1), date(2)]])); 
    
    optUnmanaged[@"decimalObj"] = optUnmanaged[@"decimalObj"]; 
     XCTAssertEqualObjects([NSSet setWithArray:[[optUnmanaged[@"decimalObj"] valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[NSNull.null, decimal128(1), decimal128(2)]])); 
    
    optUnmanaged[@"objectIdObj"] = optUnmanaged[@"objectIdObj"]; 
     XCTAssertEqualObjects([NSSet setWithArray:[[optUnmanaged[@"objectIdObj"] valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[NSNull.null, objectId(1), objectId(2)]])); 
    
    optUnmanaged[@"uuidObj"] = optUnmanaged[@"uuidObj"]; 
     XCTAssertEqualObjects([NSSet setWithArray:[[optUnmanaged[@"uuidObj"] valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[NSNull.null, uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"), uuid(@"00000000-0000-0000-0000-000000000000")]])); 
    
    managed[@"boolObj"] = managed[@"boolObj"]; 
     XCTAssertEqualObjects([NSSet setWithArray:[[managed[@"boolObj"] valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[@NO, @YES]])); 
    
    managed[@"intObj"] = managed[@"intObj"]; 
     XCTAssertEqualObjects([NSSet setWithArray:[[managed[@"intObj"] valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[@2, @3]])); 
    
    managed[@"floatObj"] = managed[@"floatObj"]; 
     XCTAssertEqualObjects([NSSet setWithArray:[[managed[@"floatObj"] valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[@2.2f, @3.3f]])); 
    
    managed[@"doubleObj"] = managed[@"doubleObj"]; 
     XCTAssertEqualObjects([NSSet setWithArray:[[managed[@"doubleObj"] valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[@2.2, @3.3]])); 
    
    managed[@"stringObj"] = managed[@"stringObj"]; 
     XCTAssertEqualObjects([NSSet setWithArray:[[managed[@"stringObj"] valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[@"a", @"bc"]])); 
    
    managed[@"dataObj"] = managed[@"dataObj"]; 
     XCTAssertEqualObjects([NSSet setWithArray:[[managed[@"dataObj"] valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[data(1), data(2)]])); 
    
    managed[@"dateObj"] = managed[@"dateObj"]; 
     XCTAssertEqualObjects([NSSet setWithArray:[[managed[@"dateObj"] valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[date(1), date(2)]])); 
    
    managed[@"decimalObj"] = managed[@"decimalObj"]; 
     XCTAssertEqualObjects([NSSet setWithArray:[[managed[@"decimalObj"] valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[decimal128(1), decimal128(2)]])); 
    
    managed[@"objectIdObj"] = managed[@"objectIdObj"]; 
     XCTAssertEqualObjects([NSSet setWithArray:[[managed[@"objectIdObj"] valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[objectId(1), objectId(2)]])); 
    
    managed[@"uuidObj"] = managed[@"uuidObj"]; 
     XCTAssertEqualObjects([NSSet setWithArray:[[managed[@"uuidObj"] valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"), uuid(@"00000000-0000-0000-0000-000000000000")]])); 
    
    optManaged[@"boolObj"] = optManaged[@"boolObj"]; 
     XCTAssertEqualObjects([NSSet setWithArray:[[optManaged[@"boolObj"] valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[NSNull.null, @NO, @YES]])); 
    
    optManaged[@"intObj"] = optManaged[@"intObj"]; 
     XCTAssertEqualObjects([NSSet setWithArray:[[optManaged[@"intObj"] valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[NSNull.null, @2, @3]])); 
    
    optManaged[@"floatObj"] = optManaged[@"floatObj"]; 
     XCTAssertEqualObjects([NSSet setWithArray:[[optManaged[@"floatObj"] valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[NSNull.null, @2.2f, @3.3f]])); 
    
    optManaged[@"doubleObj"] = optManaged[@"doubleObj"]; 
     XCTAssertEqualObjects([NSSet setWithArray:[[optManaged[@"doubleObj"] valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[NSNull.null, @2.2, @3.3]])); 
    
    optManaged[@"stringObj"] = optManaged[@"stringObj"]; 
     XCTAssertEqualObjects([NSSet setWithArray:[[optManaged[@"stringObj"] valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[NSNull.null, @"a", @"bc"]])); 
    
    optManaged[@"dataObj"] = optManaged[@"dataObj"]; 
     XCTAssertEqualObjects([NSSet setWithArray:[[optManaged[@"dataObj"] valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[NSNull.null, data(1), data(2)]])); 
    
    optManaged[@"dateObj"] = optManaged[@"dateObj"]; 
     XCTAssertEqualObjects([NSSet setWithArray:[[optManaged[@"dateObj"] valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[NSNull.null, date(1), date(2)]])); 
    
    optManaged[@"decimalObj"] = optManaged[@"decimalObj"]; 
     XCTAssertEqualObjects([NSSet setWithArray:[[optManaged[@"decimalObj"] valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[NSNull.null, decimal128(1), decimal128(2)]])); 
    
    optManaged[@"objectIdObj"] = optManaged[@"objectIdObj"]; 
     XCTAssertEqualObjects([NSSet setWithArray:[[optManaged[@"objectIdObj"] valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[NSNull.null, objectId(1), objectId(2)]])); 
    
    optManaged[@"uuidObj"] = optManaged[@"uuidObj"]; 
     XCTAssertEqualObjects([NSSet setWithArray:[[optManaged[@"uuidObj"] valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[NSNull.null, uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"), uuid(@"00000000-0000-0000-0000-000000000000")]])); 
    

    [unmanaged[@"intObj"] removeAllObjects];
    unmanaged[@"intObj"] = managed.intObj;
    XCTAssertEqualObjects([NSSet setWithArray:[[unmanaged[@"intObj"] valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[@2, @3]]));

    [managed[@"intObj"] removeAllObjects];
    managed[@"intObj"] = unmanaged.intObj;
    XCTAssertEqualObjects([NSSet setWithArray:[[managed[@"intObj"] valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[@2, @3]]));
}

- (void)testInvalidAssignment {
    RLMAssertThrowsWithReason(unmanaged.intObj = (id)@[NSNull.null],
                              @"Invalid value '<null>' of type 'NSNull' for 'int' property 'AllPrimitiveSets.intObj'.");
    RLMAssertThrowsWithReason(unmanaged.intObj = (id)@[@"a"],
                              @"Invalid value 'a' of type '__NSCFConstantString' for 'int' property 'AllPrimitiveSets.intObj'.");
    RLMAssertThrowsWithReason(unmanaged.intObj = (id)(@[@1, @"a"]),
                              @"Invalid value 'a' of type '__NSCFConstantString' for 'int' property 'AllPrimitiveSets.intObj'.");
    RLMAssertThrowsWithReason(unmanaged.intObj = (id)unmanaged.floatObj,
                              @"RLMSet<float> does not match expected type 'int' for property 'AllPrimitiveSets.intObj'.");
    RLMAssertThrowsWithReason(unmanaged.intObj = (id)optUnmanaged.intObj,
                              @"RLMSet<int?> does not match expected type 'int' for property 'AllPrimitiveSets.intObj'.");
    RLMAssertThrowsWithReason(unmanaged[@"intObj"] = unmanaged[@"floatObj"],
                              @"RLMSet<float> does not match expected type 'int' for property 'AllPrimitiveSets.intObj'.");
    RLMAssertThrowsWithReason(unmanaged[@"intObj"] = optUnmanaged[@"intObj"],
                              @"RLMSet<int?> does not match expected type 'int' for property 'AllPrimitiveSets.intObj'.");

    RLMAssertThrowsWithReason(managed.intObj = (id)@[NSNull.null],
                              @"Invalid value '<null>' of type 'NSNull' for 'int' property 'AllPrimitiveSets.intObj'.");
    RLMAssertThrowsWithReason(managed.intObj = (id)@[@"a"],
                              @"Invalid value 'a' of type '__NSCFConstantString' for 'int' property 'AllPrimitiveSets.intObj'.");
    RLMAssertThrowsWithReason(managed.intObj = (id)(@[@1, @"a"]),
                              @"Invalid value 'a' of type '__NSCFConstantString' for 'int' property 'AllPrimitiveSets.intObj'.");
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

    RLMAssertThrowsWithReason([set addObject:@0], @"invalidated");
    RLMAssertThrowsWithReason([set addObjects:@[@0]], @"invalidated");
    RLMAssertThrowsWithReason([set removeAllObjects], @"invalidated");

    RLMAssertThrowsWithReason([set sortedResultsUsingKeyPath:@"self" ascending:YES], @"invalidated");
    RLMAssertThrowsWithReason([set sortedResultsUsingDescriptors:@[[RLMSortDescriptor sortDescriptorWithKeyPath:@"self" ascending:YES]]], @"invalidated");
    RLMAssertThrowsWithReason(set.allObjects[0], @"invalidated");
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
    XCTAssertNoThrow([set sortedResultsUsingKeyPath:@"self" ascending:YES]);
    XCTAssertNoThrow([set sortedResultsUsingDescriptors:@[[RLMSortDescriptor sortDescriptorWithKeyPath:@"self" ascending:YES]]]);
    XCTAssertNoThrow(set.allObjects[0]);
    XCTAssertNoThrow([set valueForKey:@"self"]);
    XCTAssertNoThrow({for (__unused id obj in set);});


    RLMAssertThrowsWithReason([set addObject:@0], @"write transaction");
    RLMAssertThrowsWithReason([set addObjects:@[@0]], @"write transaction");
    RLMAssertThrowsWithReason([set removeAllObjects], @"write transaction");

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
