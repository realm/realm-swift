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

@interface LinkToAllPrimitiveArrays : RLMObject
@property (nonatomic) AllPrimitiveArrays *link;
@end
@implementation LinkToAllPrimitiveArrays
@end

@interface LinkToAllOptionalPrimitiveArrays : RLMObject
@property (nonatomic) AllOptionalPrimitiveArrays *link;
@end
@implementation LinkToAllOptionalPrimitiveArrays
@end

@interface PrimitiveArrayPropertyTests : RLMTestCase
@end

@implementation PrimitiveArrayPropertyTests {
    AllPrimitiveArrays *unmanaged;
    AllPrimitiveArrays *managed;
    AllOptionalPrimitiveArrays *optUnmanaged;
    AllOptionalPrimitiveArrays *optManaged;
    RLMRealm *realm;
    NSArray<RLMArray *> *allArrays;
}

- (void)setUp {
    unmanaged = [[AllPrimitiveArrays alloc] init];
    optUnmanaged = [[AllOptionalPrimitiveArrays alloc] init];
    realm = [RLMRealm defaultRealm];
    [realm beginWriteTransaction];
    managed = [AllPrimitiveArrays createInRealm:realm withValue:@[]];
    optManaged = [AllOptionalPrimitiveArrays createInRealm:realm withValue:@[]];
    allArrays = @[
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
        unmanaged.anyBoolObj,
        unmanaged.anyIntObj,
        unmanaged.anyFloatObj,
        unmanaged.anyDoubleObj,
        unmanaged.anyStringObj,
        unmanaged.anyDataObj,
        unmanaged.anyDateObj,
        unmanaged.anyDecimalObj,
        unmanaged.anyObjectIdObj,
        unmanaged.anyUUIDObj,
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
        managed.anyBoolObj,
        managed.anyIntObj,
        managed.anyFloatObj,
        managed.anyDoubleObj,
        managed.anyStringObj,
        managed.anyDataObj,
        managed.anyDateObj,
        managed.anyDecimalObj,
        managed.anyObjectIdObj,
        managed.anyUUIDObj,
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
    [unmanaged.stringObj addObjects:@[@"a", @"b"]];
    [unmanaged.dataObj addObjects:@[data(1), data(2)]];
    [unmanaged.dateObj addObjects:@[date(1), date(2)]];
    [unmanaged.decimalObj addObjects:@[decimal128(2), decimal128(3)]];
    [unmanaged.objectIdObj addObjects:@[objectId(1), objectId(2)]];
    [unmanaged.uuidObj addObjects:@[uuid(@"00000000-0000-0000-0000-000000000000"), uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")]];
    [unmanaged.anyBoolObj addObjects:@[@NO, @YES]];
    [unmanaged.anyIntObj addObjects:@[@2, @3]];
    [unmanaged.anyFloatObj addObjects:@[@2.2f, @3.3f]];
    [unmanaged.anyDoubleObj addObjects:@[@2.2, @3.3]];
    [unmanaged.anyStringObj addObjects:@[@"a", @"b"]];
    [unmanaged.anyDataObj addObjects:@[data(1), data(2)]];
    [unmanaged.anyDateObj addObjects:@[date(1), date(2)]];
    [unmanaged.anyDecimalObj addObjects:@[decimal128(2), decimal128(3)]];
    [unmanaged.anyObjectIdObj addObjects:@[objectId(1), objectId(2)]];
    [unmanaged.anyUUIDObj addObjects:@[uuid(@"00000000-0000-0000-0000-000000000000"), uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")]];
    [optUnmanaged.boolObj addObjects:@[@NO, @YES, NSNull.null]];
    [optUnmanaged.intObj addObjects:@[@2, @3, NSNull.null]];
    [optUnmanaged.floatObj addObjects:@[@2.2f, @3.3f, NSNull.null]];
    [optUnmanaged.doubleObj addObjects:@[@2.2, @3.3, NSNull.null]];
    [optUnmanaged.stringObj addObjects:@[@"a", @"b", NSNull.null]];
    [optUnmanaged.dataObj addObjects:@[data(1), data(2), NSNull.null]];
    [optUnmanaged.dateObj addObjects:@[date(1), date(2), NSNull.null]];
    [optUnmanaged.decimalObj addObjects:@[decimal128(2), decimal128(3), NSNull.null]];
    [optUnmanaged.objectIdObj addObjects:@[objectId(1), objectId(2), NSNull.null]];
    [optUnmanaged.uuidObj addObjects:@[uuid(@"00000000-0000-0000-0000-000000000000"), uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"), NSNull.null]];
    [managed.boolObj addObjects:@[@NO, @YES]];
    [managed.intObj addObjects:@[@2, @3]];
    [managed.floatObj addObjects:@[@2.2f, @3.3f]];
    [managed.doubleObj addObjects:@[@2.2, @3.3]];
    [managed.stringObj addObjects:@[@"a", @"b"]];
    [managed.dataObj addObjects:@[data(1), data(2)]];
    [managed.dateObj addObjects:@[date(1), date(2)]];
    [managed.decimalObj addObjects:@[decimal128(2), decimal128(3)]];
    [managed.objectIdObj addObjects:@[objectId(1), objectId(2)]];
    [managed.uuidObj addObjects:@[uuid(@"00000000-0000-0000-0000-000000000000"), uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")]];
    [managed.anyBoolObj addObjects:@[@NO, @YES]];
    [managed.anyIntObj addObjects:@[@2, @3]];
    [managed.anyFloatObj addObjects:@[@2.2f, @3.3f]];
    [managed.anyDoubleObj addObjects:@[@2.2, @3.3]];
    [managed.anyStringObj addObjects:@[@"a", @"b"]];
    [managed.anyDataObj addObjects:@[data(1), data(2)]];
    [managed.anyDateObj addObjects:@[date(1), date(2)]];
    [managed.anyDecimalObj addObjects:@[decimal128(2), decimal128(3)]];
    [managed.anyObjectIdObj addObjects:@[objectId(1), objectId(2)]];
    [managed.anyUUIDObj addObjects:@[uuid(@"00000000-0000-0000-0000-000000000000"), uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")]];
    [optManaged.boolObj addObjects:@[@NO, @YES, NSNull.null]];
    [optManaged.intObj addObjects:@[@2, @3, NSNull.null]];
    [optManaged.floatObj addObjects:@[@2.2f, @3.3f, NSNull.null]];
    [optManaged.doubleObj addObjects:@[@2.2, @3.3, NSNull.null]];
    [optManaged.stringObj addObjects:@[@"a", @"b", NSNull.null]];
    [optManaged.dataObj addObjects:@[data(1), data(2), NSNull.null]];
    [optManaged.dateObj addObjects:@[date(1), date(2), NSNull.null]];
    [optManaged.decimalObj addObjects:@[decimal128(2), decimal128(3), NSNull.null]];
    [optManaged.objectIdObj addObjects:@[objectId(1), objectId(2), NSNull.null]];
    [optManaged.uuidObj addObjects:@[uuid(@"00000000-0000-0000-0000-000000000000"), uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"), NSNull.null]];
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
    XCTAssertEqual(unmanaged.anyBoolObj.type, RLMPropertyTypeAny);
    XCTAssertEqual(unmanaged.anyIntObj.type, RLMPropertyTypeAny);
    XCTAssertEqual(unmanaged.anyFloatObj.type, RLMPropertyTypeAny);
    XCTAssertEqual(unmanaged.anyDoubleObj.type, RLMPropertyTypeAny);
    XCTAssertEqual(unmanaged.anyStringObj.type, RLMPropertyTypeAny);
    XCTAssertEqual(unmanaged.anyDataObj.type, RLMPropertyTypeAny);
    XCTAssertEqual(unmanaged.anyDateObj.type, RLMPropertyTypeAny);
    XCTAssertEqual(unmanaged.anyDecimalObj.type, RLMPropertyTypeAny);
    XCTAssertEqual(unmanaged.anyObjectIdObj.type, RLMPropertyTypeAny);
    XCTAssertEqual(unmanaged.anyUUIDObj.type, RLMPropertyTypeAny);
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
    XCTAssertFalse(unmanaged.anyBoolObj.optional);
    XCTAssertFalse(unmanaged.anyIntObj.optional);
    XCTAssertFalse(unmanaged.anyFloatObj.optional);
    XCTAssertFalse(unmanaged.anyDoubleObj.optional);
    XCTAssertFalse(unmanaged.anyStringObj.optional);
    XCTAssertFalse(unmanaged.anyDataObj.optional);
    XCTAssertFalse(unmanaged.anyDateObj.optional);
    XCTAssertFalse(unmanaged.anyDecimalObj.optional);
    XCTAssertFalse(unmanaged.anyObjectIdObj.optional);
    XCTAssertFalse(unmanaged.anyUUIDObj.optional);
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
    XCTAssertNil(unmanaged.anyBoolObj.objectClassName);
    XCTAssertNil(unmanaged.anyIntObj.objectClassName);
    XCTAssertNil(unmanaged.anyFloatObj.objectClassName);
    XCTAssertNil(unmanaged.anyDoubleObj.objectClassName);
    XCTAssertNil(unmanaged.anyStringObj.objectClassName);
    XCTAssertNil(unmanaged.anyDataObj.objectClassName);
    XCTAssertNil(unmanaged.anyDateObj.objectClassName);
    XCTAssertNil(unmanaged.anyDecimalObj.objectClassName);
    XCTAssertNil(unmanaged.anyObjectIdObj.objectClassName);
    XCTAssertNil(unmanaged.anyUUIDObj.objectClassName);
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
    XCTAssertNil(unmanaged.anyBoolObj.realm);
    XCTAssertNil(unmanaged.anyIntObj.realm);
    XCTAssertNil(unmanaged.anyFloatObj.realm);
    XCTAssertNil(unmanaged.anyDoubleObj.realm);
    XCTAssertNil(unmanaged.anyStringObj.realm);
    XCTAssertNil(unmanaged.anyDataObj.realm);
    XCTAssertNil(unmanaged.anyDateObj.realm);
    XCTAssertNil(unmanaged.anyDecimalObj.realm);
    XCTAssertNil(unmanaged.anyObjectIdObj.realm);
    XCTAssertNil(unmanaged.anyUUIDObj.realm);
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
    for (RLMArray *array in allArrays) {
        RLMAssertThrowsWithReason([realm deleteObjects:array], @"Cannot delete objects from RLMArray");
    }
}

- (void)testObjectAtIndex {
    RLMAssertThrowsWithReason([unmanaged.intObj objectAtIndex:0],
                              @"Index 0 is out of bounds (must be less than 0).");

    [unmanaged.intObj addObject:@1];
    XCTAssertEqualObjects([unmanaged.intObj objectAtIndex:0], @1);
}

- (void)testFirstObject {
    for (RLMArray *array in allArrays) {
        XCTAssertNil(array.firstObject);
    }

    [self addObjects];
    XCTAssertEqualObjects(unmanaged.boolObj.firstObject, @NO);
    XCTAssertEqualObjects(unmanaged.intObj.firstObject, @2);
    XCTAssertEqualObjects(unmanaged.floatObj.firstObject, @2.2f);
    XCTAssertEqualObjects(unmanaged.doubleObj.firstObject, @2.2);
    XCTAssertEqualObjects(unmanaged.stringObj.firstObject, @"a");
    XCTAssertEqualObjects(unmanaged.dataObj.firstObject, data(1));
    XCTAssertEqualObjects(unmanaged.dateObj.firstObject, date(1));
    XCTAssertEqualObjects(unmanaged.decimalObj.firstObject, decimal128(2));
    XCTAssertEqualObjects(unmanaged.objectIdObj.firstObject, objectId(1));
    XCTAssertEqualObjects(unmanaged.uuidObj.firstObject, uuid(@"00000000-0000-0000-0000-000000000000"));
    XCTAssertEqualObjects(unmanaged.anyBoolObj.firstObject, @NO);
    XCTAssertEqualObjects(unmanaged.anyIntObj.firstObject, @2);
    XCTAssertEqualObjects(unmanaged.anyFloatObj.firstObject, @2.2f);
    XCTAssertEqualObjects(unmanaged.anyDoubleObj.firstObject, @2.2);
    XCTAssertEqualObjects(unmanaged.anyStringObj.firstObject, @"a");
    XCTAssertEqualObjects(unmanaged.anyDataObj.firstObject, data(1));
    XCTAssertEqualObjects(unmanaged.anyDateObj.firstObject, date(1));
    XCTAssertEqualObjects(unmanaged.anyDecimalObj.firstObject, decimal128(2));
    XCTAssertEqualObjects(unmanaged.anyObjectIdObj.firstObject, objectId(1));
    XCTAssertEqualObjects(unmanaged.anyUUIDObj.firstObject, uuid(@"00000000-0000-0000-0000-000000000000"));
    XCTAssertEqualObjects(optUnmanaged.boolObj.firstObject, @NO);
    XCTAssertEqualObjects(optUnmanaged.intObj.firstObject, @2);
    XCTAssertEqualObjects(optUnmanaged.floatObj.firstObject, @2.2f);
    XCTAssertEqualObjects(optUnmanaged.doubleObj.firstObject, @2.2);
    XCTAssertEqualObjects(optUnmanaged.stringObj.firstObject, @"a");
    XCTAssertEqualObjects(optUnmanaged.dataObj.firstObject, data(1));
    XCTAssertEqualObjects(optUnmanaged.dateObj.firstObject, date(1));
    XCTAssertEqualObjects(optUnmanaged.decimalObj.firstObject, decimal128(2));
    XCTAssertEqualObjects(optUnmanaged.objectIdObj.firstObject, objectId(1));
    XCTAssertEqualObjects(optUnmanaged.uuidObj.firstObject, uuid(@"00000000-0000-0000-0000-000000000000"));
    XCTAssertEqualObjects(managed.boolObj.firstObject, @NO);
    XCTAssertEqualObjects(managed.intObj.firstObject, @2);
    XCTAssertEqualObjects(managed.floatObj.firstObject, @2.2f);
    XCTAssertEqualObjects(managed.doubleObj.firstObject, @2.2);
    XCTAssertEqualObjects(managed.stringObj.firstObject, @"a");
    XCTAssertEqualObjects(managed.dataObj.firstObject, data(1));
    XCTAssertEqualObjects(managed.dateObj.firstObject, date(1));
    XCTAssertEqualObjects(managed.decimalObj.firstObject, decimal128(2));
    XCTAssertEqualObjects(managed.objectIdObj.firstObject, objectId(1));
    XCTAssertEqualObjects(managed.uuidObj.firstObject, uuid(@"00000000-0000-0000-0000-000000000000"));
    XCTAssertEqualObjects(managed.anyBoolObj.firstObject, @NO);
    XCTAssertEqualObjects(managed.anyIntObj.firstObject, @2);
    XCTAssertEqualObjects(managed.anyFloatObj.firstObject, @2.2f);
    XCTAssertEqualObjects(managed.anyDoubleObj.firstObject, @2.2);
    XCTAssertEqualObjects(managed.anyStringObj.firstObject, @"a");
    XCTAssertEqualObjects(managed.anyDataObj.firstObject, data(1));
    XCTAssertEqualObjects(managed.anyDateObj.firstObject, date(1));
    XCTAssertEqualObjects(managed.anyDecimalObj.firstObject, decimal128(2));
    XCTAssertEqualObjects(managed.anyObjectIdObj.firstObject, objectId(1));
    XCTAssertEqualObjects(managed.anyUUIDObj.firstObject, uuid(@"00000000-0000-0000-0000-000000000000"));
    XCTAssertEqualObjects(optManaged.boolObj.firstObject, @NO);
    XCTAssertEqualObjects(optManaged.intObj.firstObject, @2);
    XCTAssertEqualObjects(optManaged.floatObj.firstObject, @2.2f);
    XCTAssertEqualObjects(optManaged.doubleObj.firstObject, @2.2);
    XCTAssertEqualObjects(optManaged.stringObj.firstObject, @"a");
    XCTAssertEqualObjects(optManaged.dataObj.firstObject, data(1));
    XCTAssertEqualObjects(optManaged.dateObj.firstObject, date(1));
    XCTAssertEqualObjects(optManaged.decimalObj.firstObject, decimal128(2));
    XCTAssertEqualObjects(optManaged.objectIdObj.firstObject, objectId(1));
    XCTAssertEqualObjects(optManaged.uuidObj.firstObject, uuid(@"00000000-0000-0000-0000-000000000000"));

    for (RLMArray *array in allArrays) {
        [array removeAllObjects];
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
    XCTAssertEqualObjects(optUnmanaged.boolObj.firstObject, NSNull.null);
    XCTAssertEqualObjects(optUnmanaged.intObj.firstObject, NSNull.null);
    XCTAssertEqualObjects(optUnmanaged.floatObj.firstObject, NSNull.null);
    XCTAssertEqualObjects(optUnmanaged.doubleObj.firstObject, NSNull.null);
    XCTAssertEqualObjects(optUnmanaged.stringObj.firstObject, NSNull.null);
    XCTAssertEqualObjects(optUnmanaged.dataObj.firstObject, NSNull.null);
    XCTAssertEqualObjects(optUnmanaged.dateObj.firstObject, NSNull.null);
    XCTAssertEqualObjects(optUnmanaged.decimalObj.firstObject, NSNull.null);
    XCTAssertEqualObjects(optUnmanaged.objectIdObj.firstObject, NSNull.null);
    XCTAssertEqualObjects(optUnmanaged.uuidObj.firstObject, NSNull.null);
    XCTAssertEqualObjects(optManaged.boolObj.firstObject, NSNull.null);
    XCTAssertEqualObjects(optManaged.intObj.firstObject, NSNull.null);
    XCTAssertEqualObjects(optManaged.floatObj.firstObject, NSNull.null);
    XCTAssertEqualObjects(optManaged.doubleObj.firstObject, NSNull.null);
    XCTAssertEqualObjects(optManaged.stringObj.firstObject, NSNull.null);
    XCTAssertEqualObjects(optManaged.dataObj.firstObject, NSNull.null);
    XCTAssertEqualObjects(optManaged.dateObj.firstObject, NSNull.null);
    XCTAssertEqualObjects(optManaged.decimalObj.firstObject, NSNull.null);
    XCTAssertEqualObjects(optManaged.objectIdObj.firstObject, NSNull.null);
    XCTAssertEqualObjects(optManaged.uuidObj.firstObject, NSNull.null);
}

- (void)testLastObject {
    for (RLMArray *array in allArrays) {
        XCTAssertNil(array.lastObject);
    }

    [self addObjects];

    XCTAssertEqualObjects(unmanaged.boolObj.lastObject, @YES);
    XCTAssertEqualObjects(unmanaged.intObj.lastObject, @3);
    XCTAssertEqualObjects(unmanaged.floatObj.lastObject, @3.3f);
    XCTAssertEqualObjects(unmanaged.doubleObj.lastObject, @3.3);
    XCTAssertEqualObjects(unmanaged.stringObj.lastObject, @"b");
    XCTAssertEqualObjects(unmanaged.dataObj.lastObject, data(2));
    XCTAssertEqualObjects(unmanaged.dateObj.lastObject, date(2));
    XCTAssertEqualObjects(unmanaged.decimalObj.lastObject, decimal128(3));
    XCTAssertEqualObjects(unmanaged.objectIdObj.lastObject, objectId(2));
    XCTAssertEqualObjects(unmanaged.uuidObj.lastObject, uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"));
    XCTAssertEqualObjects(unmanaged.anyBoolObj.lastObject, @YES);
    XCTAssertEqualObjects(unmanaged.anyIntObj.lastObject, @3);
    XCTAssertEqualObjects(unmanaged.anyFloatObj.lastObject, @3.3f);
    XCTAssertEqualObjects(unmanaged.anyDoubleObj.lastObject, @3.3);
    XCTAssertEqualObjects(unmanaged.anyStringObj.lastObject, @"b");
    XCTAssertEqualObjects(unmanaged.anyDataObj.lastObject, data(2));
    XCTAssertEqualObjects(unmanaged.anyDateObj.lastObject, date(2));
    XCTAssertEqualObjects(unmanaged.anyDecimalObj.lastObject, decimal128(3));
    XCTAssertEqualObjects(unmanaged.anyObjectIdObj.lastObject, objectId(2));
    XCTAssertEqualObjects(unmanaged.anyUUIDObj.lastObject, uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"));
    XCTAssertEqualObjects(optUnmanaged.boolObj.lastObject, NSNull.null);
    XCTAssertEqualObjects(optUnmanaged.intObj.lastObject, NSNull.null);
    XCTAssertEqualObjects(optUnmanaged.floatObj.lastObject, NSNull.null);
    XCTAssertEqualObjects(optUnmanaged.doubleObj.lastObject, NSNull.null);
    XCTAssertEqualObjects(optUnmanaged.stringObj.lastObject, NSNull.null);
    XCTAssertEqualObjects(optUnmanaged.dataObj.lastObject, NSNull.null);
    XCTAssertEqualObjects(optUnmanaged.dateObj.lastObject, NSNull.null);
    XCTAssertEqualObjects(optUnmanaged.decimalObj.lastObject, NSNull.null);
    XCTAssertEqualObjects(optUnmanaged.objectIdObj.lastObject, NSNull.null);
    XCTAssertEqualObjects(optUnmanaged.uuidObj.lastObject, NSNull.null);
    XCTAssertEqualObjects(managed.boolObj.lastObject, @YES);
    XCTAssertEqualObjects(managed.intObj.lastObject, @3);
    XCTAssertEqualObjects(managed.floatObj.lastObject, @3.3f);
    XCTAssertEqualObjects(managed.doubleObj.lastObject, @3.3);
    XCTAssertEqualObjects(managed.stringObj.lastObject, @"b");
    XCTAssertEqualObjects(managed.dataObj.lastObject, data(2));
    XCTAssertEqualObjects(managed.dateObj.lastObject, date(2));
    XCTAssertEqualObjects(managed.decimalObj.lastObject, decimal128(3));
    XCTAssertEqualObjects(managed.objectIdObj.lastObject, objectId(2));
    XCTAssertEqualObjects(managed.uuidObj.lastObject, uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"));
    XCTAssertEqualObjects(managed.anyBoolObj.lastObject, @YES);
    XCTAssertEqualObjects(managed.anyIntObj.lastObject, @3);
    XCTAssertEqualObjects(managed.anyFloatObj.lastObject, @3.3f);
    XCTAssertEqualObjects(managed.anyDoubleObj.lastObject, @3.3);
    XCTAssertEqualObjects(managed.anyStringObj.lastObject, @"b");
    XCTAssertEqualObjects(managed.anyDataObj.lastObject, data(2));
    XCTAssertEqualObjects(managed.anyDateObj.lastObject, date(2));
    XCTAssertEqualObjects(managed.anyDecimalObj.lastObject, decimal128(3));
    XCTAssertEqualObjects(managed.anyObjectIdObj.lastObject, objectId(2));
    XCTAssertEqualObjects(managed.anyUUIDObj.lastObject, uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"));
    XCTAssertEqualObjects(optManaged.boolObj.lastObject, NSNull.null);
    XCTAssertEqualObjects(optManaged.intObj.lastObject, NSNull.null);
    XCTAssertEqualObjects(optManaged.floatObj.lastObject, NSNull.null);
    XCTAssertEqualObjects(optManaged.doubleObj.lastObject, NSNull.null);
    XCTAssertEqualObjects(optManaged.stringObj.lastObject, NSNull.null);
    XCTAssertEqualObjects(optManaged.dataObj.lastObject, NSNull.null);
    XCTAssertEqualObjects(optManaged.dateObj.lastObject, NSNull.null);
    XCTAssertEqualObjects(optManaged.decimalObj.lastObject, NSNull.null);
    XCTAssertEqualObjects(optManaged.objectIdObj.lastObject, NSNull.null);
    XCTAssertEqualObjects(optManaged.uuidObj.lastObject, NSNull.null);

    for (RLMArray *array in allArrays) {
        [array removeLastObject];
    }
    XCTAssertEqualObjects(optUnmanaged.boolObj.lastObject, @YES);
    XCTAssertEqualObjects(optUnmanaged.intObj.lastObject, @3);
    XCTAssertEqualObjects(optUnmanaged.floatObj.lastObject, @3.3f);
    XCTAssertEqualObjects(optUnmanaged.doubleObj.lastObject, @3.3);
    XCTAssertEqualObjects(optUnmanaged.stringObj.lastObject, @"b");
    XCTAssertEqualObjects(optUnmanaged.dataObj.lastObject, data(2));
    XCTAssertEqualObjects(optUnmanaged.dateObj.lastObject, date(2));
    XCTAssertEqualObjects(optUnmanaged.decimalObj.lastObject, decimal128(3));
    XCTAssertEqualObjects(optUnmanaged.objectIdObj.lastObject, objectId(2));
    XCTAssertEqualObjects(optUnmanaged.uuidObj.lastObject, uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"));
    XCTAssertEqualObjects(optManaged.boolObj.lastObject, @YES);
    XCTAssertEqualObjects(optManaged.intObj.lastObject, @3);
    XCTAssertEqualObjects(optManaged.floatObj.lastObject, @3.3f);
    XCTAssertEqualObjects(optManaged.doubleObj.lastObject, @3.3);
    XCTAssertEqualObjects(optManaged.stringObj.lastObject, @"b");
    XCTAssertEqualObjects(optManaged.dataObj.lastObject, data(2));
    XCTAssertEqualObjects(optManaged.dateObj.lastObject, date(2));
    XCTAssertEqualObjects(optManaged.decimalObj.lastObject, decimal128(3));
    XCTAssertEqualObjects(optManaged.objectIdObj.lastObject, objectId(2));
    XCTAssertEqualObjects(optManaged.uuidObj.lastObject, uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"));
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
    [unmanaged.decimalObj addObject:decimal128(2)];
    [unmanaged.objectIdObj addObject:objectId(1)];
    [unmanaged.uuidObj addObject:uuid(@"00000000-0000-0000-0000-000000000000")];
    [unmanaged.anyBoolObj addObject:@NO];
    [unmanaged.anyIntObj addObject:@2];
    [unmanaged.anyFloatObj addObject:@2.2f];
    [unmanaged.anyDoubleObj addObject:@2.2];
    [unmanaged.anyStringObj addObject:@"a"];
    [unmanaged.anyDataObj addObject:data(1)];
    [unmanaged.anyDateObj addObject:date(1)];
    [unmanaged.anyDecimalObj addObject:decimal128(2)];
    [unmanaged.anyObjectIdObj addObject:objectId(1)];
    [unmanaged.anyUUIDObj addObject:uuid(@"00000000-0000-0000-0000-000000000000")];
    [optUnmanaged.boolObj addObject:@NO];
    [optUnmanaged.intObj addObject:@2];
    [optUnmanaged.floatObj addObject:@2.2f];
    [optUnmanaged.doubleObj addObject:@2.2];
    [optUnmanaged.stringObj addObject:@"a"];
    [optUnmanaged.dataObj addObject:data(1)];
    [optUnmanaged.dateObj addObject:date(1)];
    [optUnmanaged.decimalObj addObject:decimal128(2)];
    [optUnmanaged.objectIdObj addObject:objectId(1)];
    [optUnmanaged.uuidObj addObject:uuid(@"00000000-0000-0000-0000-000000000000")];
    [managed.boolObj addObject:@NO];
    [managed.intObj addObject:@2];
    [managed.floatObj addObject:@2.2f];
    [managed.doubleObj addObject:@2.2];
    [managed.stringObj addObject:@"a"];
    [managed.dataObj addObject:data(1)];
    [managed.dateObj addObject:date(1)];
    [managed.decimalObj addObject:decimal128(2)];
    [managed.objectIdObj addObject:objectId(1)];
    [managed.uuidObj addObject:uuid(@"00000000-0000-0000-0000-000000000000")];
    [managed.anyBoolObj addObject:@NO];
    [managed.anyIntObj addObject:@2];
    [managed.anyFloatObj addObject:@2.2f];
    [managed.anyDoubleObj addObject:@2.2];
    [managed.anyStringObj addObject:@"a"];
    [managed.anyDataObj addObject:data(1)];
    [managed.anyDateObj addObject:date(1)];
    [managed.anyDecimalObj addObject:decimal128(2)];
    [managed.anyObjectIdObj addObject:objectId(1)];
    [managed.anyUUIDObj addObject:uuid(@"00000000-0000-0000-0000-000000000000")];
    [optManaged.boolObj addObject:@NO];
    [optManaged.intObj addObject:@2];
    [optManaged.floatObj addObject:@2.2f];
    [optManaged.doubleObj addObject:@2.2];
    [optManaged.stringObj addObject:@"a"];
    [optManaged.dataObj addObject:data(1)];
    [optManaged.dateObj addObject:date(1)];
    [optManaged.decimalObj addObject:decimal128(2)];
    [optManaged.objectIdObj addObject:objectId(1)];
    [optManaged.uuidObj addObject:uuid(@"00000000-0000-0000-0000-000000000000")];
    XCTAssertEqualObjects(unmanaged.boolObj[0], @NO);
    XCTAssertEqualObjects(unmanaged.intObj[0], @2);
    XCTAssertEqualObjects(unmanaged.floatObj[0], @2.2f);
    XCTAssertEqualObjects(unmanaged.doubleObj[0], @2.2);
    XCTAssertEqualObjects(unmanaged.stringObj[0], @"a");
    XCTAssertEqualObjects(unmanaged.dataObj[0], data(1));
    XCTAssertEqualObjects(unmanaged.dateObj[0], date(1));
    XCTAssertEqualObjects(unmanaged.decimalObj[0], decimal128(2));
    XCTAssertEqualObjects(unmanaged.objectIdObj[0], objectId(1));
    XCTAssertEqualObjects(unmanaged.uuidObj[0], uuid(@"00000000-0000-0000-0000-000000000000"));
    XCTAssertEqualObjects(unmanaged.anyBoolObj[0], @NO);
    XCTAssertEqualObjects(unmanaged.anyIntObj[0], @2);
    XCTAssertEqualObjects(unmanaged.anyFloatObj[0], @2.2f);
    XCTAssertEqualObjects(unmanaged.anyDoubleObj[0], @2.2);
    XCTAssertEqualObjects(unmanaged.anyStringObj[0], @"a");
    XCTAssertEqualObjects(unmanaged.anyDataObj[0], data(1));
    XCTAssertEqualObjects(unmanaged.anyDateObj[0], date(1));
    XCTAssertEqualObjects(unmanaged.anyDecimalObj[0], decimal128(2));
    XCTAssertEqualObjects(unmanaged.anyObjectIdObj[0], objectId(1));
    XCTAssertEqualObjects(unmanaged.anyUUIDObj[0], uuid(@"00000000-0000-0000-0000-000000000000"));
    XCTAssertEqualObjects(optUnmanaged.boolObj[0], @NO);
    XCTAssertEqualObjects(optUnmanaged.intObj[0], @2);
    XCTAssertEqualObjects(optUnmanaged.floatObj[0], @2.2f);
    XCTAssertEqualObjects(optUnmanaged.doubleObj[0], @2.2);
    XCTAssertEqualObjects(optUnmanaged.stringObj[0], @"a");
    XCTAssertEqualObjects(optUnmanaged.dataObj[0], data(1));
    XCTAssertEqualObjects(optUnmanaged.dateObj[0], date(1));
    XCTAssertEqualObjects(optUnmanaged.decimalObj[0], decimal128(2));
    XCTAssertEqualObjects(optUnmanaged.objectIdObj[0], objectId(1));
    XCTAssertEqualObjects(optUnmanaged.uuidObj[0], uuid(@"00000000-0000-0000-0000-000000000000"));
    XCTAssertEqualObjects(managed.boolObj[0], @NO);
    XCTAssertEqualObjects(managed.intObj[0], @2);
    XCTAssertEqualObjects(managed.floatObj[0], @2.2f);
    XCTAssertEqualObjects(managed.doubleObj[0], @2.2);
    XCTAssertEqualObjects(managed.stringObj[0], @"a");
    XCTAssertEqualObjects(managed.dataObj[0], data(1));
    XCTAssertEqualObjects(managed.dateObj[0], date(1));
    XCTAssertEqualObjects(managed.decimalObj[0], decimal128(2));
    XCTAssertEqualObjects(managed.objectIdObj[0], objectId(1));
    XCTAssertEqualObjects(managed.uuidObj[0], uuid(@"00000000-0000-0000-0000-000000000000"));
    XCTAssertEqualObjects(managed.anyBoolObj[0], @NO);
    XCTAssertEqualObjects(managed.anyIntObj[0], @2);
    XCTAssertEqualObjects(managed.anyFloatObj[0], @2.2f);
    XCTAssertEqualObjects(managed.anyDoubleObj[0], @2.2);
    XCTAssertEqualObjects(managed.anyStringObj[0], @"a");
    XCTAssertEqualObjects(managed.anyDataObj[0], data(1));
    XCTAssertEqualObjects(managed.anyDateObj[0], date(1));
    XCTAssertEqualObjects(managed.anyDecimalObj[0], decimal128(2));
    XCTAssertEqualObjects(managed.anyObjectIdObj[0], objectId(1));
    XCTAssertEqualObjects(managed.anyUUIDObj[0], uuid(@"00000000-0000-0000-0000-000000000000"));
    XCTAssertEqualObjects(optManaged.boolObj[0], @NO);
    XCTAssertEqualObjects(optManaged.intObj[0], @2);
    XCTAssertEqualObjects(optManaged.floatObj[0], @2.2f);
    XCTAssertEqualObjects(optManaged.doubleObj[0], @2.2);
    XCTAssertEqualObjects(optManaged.stringObj[0], @"a");
    XCTAssertEqualObjects(optManaged.dataObj[0], data(1));
    XCTAssertEqualObjects(optManaged.dateObj[0], date(1));
    XCTAssertEqualObjects(optManaged.decimalObj[0], decimal128(2));
    XCTAssertEqualObjects(optManaged.objectIdObj[0], objectId(1));
    XCTAssertEqualObjects(optManaged.uuidObj[0], uuid(@"00000000-0000-0000-0000-000000000000"));

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
    XCTAssertEqualObjects(optUnmanaged.boolObj[1], NSNull.null);
    XCTAssertEqualObjects(optUnmanaged.intObj[1], NSNull.null);
    XCTAssertEqualObjects(optUnmanaged.floatObj[1], NSNull.null);
    XCTAssertEqualObjects(optUnmanaged.doubleObj[1], NSNull.null);
    XCTAssertEqualObjects(optUnmanaged.stringObj[1], NSNull.null);
    XCTAssertEqualObjects(optUnmanaged.dataObj[1], NSNull.null);
    XCTAssertEqualObjects(optUnmanaged.dateObj[1], NSNull.null);
    XCTAssertEqualObjects(optUnmanaged.decimalObj[1], NSNull.null);
    XCTAssertEqualObjects(optUnmanaged.objectIdObj[1], NSNull.null);
    XCTAssertEqualObjects(optUnmanaged.uuidObj[1], NSNull.null);
    XCTAssertEqualObjects(optManaged.boolObj[1], NSNull.null);
    XCTAssertEqualObjects(optManaged.intObj[1], NSNull.null);
    XCTAssertEqualObjects(optManaged.floatObj[1], NSNull.null);
    XCTAssertEqualObjects(optManaged.doubleObj[1], NSNull.null);
    XCTAssertEqualObjects(optManaged.stringObj[1], NSNull.null);
    XCTAssertEqualObjects(optManaged.dataObj[1], NSNull.null);
    XCTAssertEqualObjects(optManaged.dateObj[1], NSNull.null);
    XCTAssertEqualObjects(optManaged.decimalObj[1], NSNull.null);
    XCTAssertEqualObjects(optManaged.objectIdObj[1], NSNull.null);
    XCTAssertEqualObjects(optManaged.uuidObj[1], NSNull.null);
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
    XCTAssertEqualObjects(unmanaged.boolObj[0], @NO);
    XCTAssertEqualObjects(unmanaged.intObj[0], @2);
    XCTAssertEqualObjects(unmanaged.floatObj[0], @2.2f);
    XCTAssertEqualObjects(unmanaged.doubleObj[0], @2.2);
    XCTAssertEqualObjects(unmanaged.stringObj[0], @"a");
    XCTAssertEqualObjects(unmanaged.dataObj[0], data(1));
    XCTAssertEqualObjects(unmanaged.dateObj[0], date(1));
    XCTAssertEqualObjects(unmanaged.decimalObj[0], decimal128(2));
    XCTAssertEqualObjects(unmanaged.objectIdObj[0], objectId(1));
    XCTAssertEqualObjects(unmanaged.uuidObj[0], uuid(@"00000000-0000-0000-0000-000000000000"));
    XCTAssertEqualObjects(unmanaged.anyBoolObj[0], @NO);
    XCTAssertEqualObjects(unmanaged.anyIntObj[0], @2);
    XCTAssertEqualObjects(unmanaged.anyFloatObj[0], @2.2f);
    XCTAssertEqualObjects(unmanaged.anyDoubleObj[0], @2.2);
    XCTAssertEqualObjects(unmanaged.anyStringObj[0], @"a");
    XCTAssertEqualObjects(unmanaged.anyDataObj[0], data(1));
    XCTAssertEqualObjects(unmanaged.anyDateObj[0], date(1));
    XCTAssertEqualObjects(unmanaged.anyDecimalObj[0], decimal128(2));
    XCTAssertEqualObjects(unmanaged.anyObjectIdObj[0], objectId(1));
    XCTAssertEqualObjects(unmanaged.anyUUIDObj[0], uuid(@"00000000-0000-0000-0000-000000000000"));
    XCTAssertEqualObjects(optUnmanaged.boolObj[0], @NO);
    XCTAssertEqualObjects(optUnmanaged.intObj[0], @2);
    XCTAssertEqualObjects(optUnmanaged.floatObj[0], @2.2f);
    XCTAssertEqualObjects(optUnmanaged.doubleObj[0], @2.2);
    XCTAssertEqualObjects(optUnmanaged.stringObj[0], @"a");
    XCTAssertEqualObjects(optUnmanaged.dataObj[0], data(1));
    XCTAssertEqualObjects(optUnmanaged.dateObj[0], date(1));
    XCTAssertEqualObjects(optUnmanaged.decimalObj[0], decimal128(2));
    XCTAssertEqualObjects(optUnmanaged.objectIdObj[0], objectId(1));
    XCTAssertEqualObjects(optUnmanaged.uuidObj[0], uuid(@"00000000-0000-0000-0000-000000000000"));
    XCTAssertEqualObjects(managed.boolObj[0], @NO);
    XCTAssertEqualObjects(managed.intObj[0], @2);
    XCTAssertEqualObjects(managed.floatObj[0], @2.2f);
    XCTAssertEqualObjects(managed.doubleObj[0], @2.2);
    XCTAssertEqualObjects(managed.stringObj[0], @"a");
    XCTAssertEqualObjects(managed.dataObj[0], data(1));
    XCTAssertEqualObjects(managed.dateObj[0], date(1));
    XCTAssertEqualObjects(managed.decimalObj[0], decimal128(2));
    XCTAssertEqualObjects(managed.objectIdObj[0], objectId(1));
    XCTAssertEqualObjects(managed.uuidObj[0], uuid(@"00000000-0000-0000-0000-000000000000"));
    XCTAssertEqualObjects(managed.anyBoolObj[0], @NO);
    XCTAssertEqualObjects(managed.anyIntObj[0], @2);
    XCTAssertEqualObjects(managed.anyFloatObj[0], @2.2f);
    XCTAssertEqualObjects(managed.anyDoubleObj[0], @2.2);
    XCTAssertEqualObjects(managed.anyStringObj[0], @"a");
    XCTAssertEqualObjects(managed.anyDataObj[0], data(1));
    XCTAssertEqualObjects(managed.anyDateObj[0], date(1));
    XCTAssertEqualObjects(managed.anyDecimalObj[0], decimal128(2));
    XCTAssertEqualObjects(managed.anyObjectIdObj[0], objectId(1));
    XCTAssertEqualObjects(managed.anyUUIDObj[0], uuid(@"00000000-0000-0000-0000-000000000000"));
    XCTAssertEqualObjects(optManaged.boolObj[0], @NO);
    XCTAssertEqualObjects(optManaged.intObj[0], @2);
    XCTAssertEqualObjects(optManaged.floatObj[0], @2.2f);
    XCTAssertEqualObjects(optManaged.doubleObj[0], @2.2);
    XCTAssertEqualObjects(optManaged.stringObj[0], @"a");
    XCTAssertEqualObjects(optManaged.dataObj[0], data(1));
    XCTAssertEqualObjects(optManaged.dateObj[0], date(1));
    XCTAssertEqualObjects(optManaged.decimalObj[0], decimal128(2));
    XCTAssertEqualObjects(optManaged.objectIdObj[0], objectId(1));
    XCTAssertEqualObjects(optManaged.uuidObj[0], uuid(@"00000000-0000-0000-0000-000000000000"));
    XCTAssertEqualObjects(unmanaged.boolObj[1], @YES);
    XCTAssertEqualObjects(unmanaged.intObj[1], @3);
    XCTAssertEqualObjects(unmanaged.floatObj[1], @3.3f);
    XCTAssertEqualObjects(unmanaged.doubleObj[1], @3.3);
    XCTAssertEqualObjects(unmanaged.stringObj[1], @"b");
    XCTAssertEqualObjects(unmanaged.dataObj[1], data(2));
    XCTAssertEqualObjects(unmanaged.dateObj[1], date(2));
    XCTAssertEqualObjects(unmanaged.decimalObj[1], decimal128(3));
    XCTAssertEqualObjects(unmanaged.objectIdObj[1], objectId(2));
    XCTAssertEqualObjects(unmanaged.uuidObj[1], uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"));
    XCTAssertEqualObjects(unmanaged.anyBoolObj[1], @YES);
    XCTAssertEqualObjects(unmanaged.anyIntObj[1], @3);
    XCTAssertEqualObjects(unmanaged.anyFloatObj[1], @3.3f);
    XCTAssertEqualObjects(unmanaged.anyDoubleObj[1], @3.3);
    XCTAssertEqualObjects(unmanaged.anyStringObj[1], @"b");
    XCTAssertEqualObjects(unmanaged.anyDataObj[1], data(2));
    XCTAssertEqualObjects(unmanaged.anyDateObj[1], date(2));
    XCTAssertEqualObjects(unmanaged.anyDecimalObj[1], decimal128(3));
    XCTAssertEqualObjects(unmanaged.anyObjectIdObj[1], objectId(2));
    XCTAssertEqualObjects(unmanaged.anyUUIDObj[1], uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"));
    XCTAssertEqualObjects(optUnmanaged.boolObj[1], @YES);
    XCTAssertEqualObjects(optUnmanaged.intObj[1], @3);
    XCTAssertEqualObjects(optUnmanaged.floatObj[1], @3.3f);
    XCTAssertEqualObjects(optUnmanaged.doubleObj[1], @3.3);
    XCTAssertEqualObjects(optUnmanaged.stringObj[1], @"b");
    XCTAssertEqualObjects(optUnmanaged.dataObj[1], data(2));
    XCTAssertEqualObjects(optUnmanaged.dateObj[1], date(2));
    XCTAssertEqualObjects(optUnmanaged.decimalObj[1], decimal128(3));
    XCTAssertEqualObjects(optUnmanaged.objectIdObj[1], objectId(2));
    XCTAssertEqualObjects(optUnmanaged.uuidObj[1], uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"));
    XCTAssertEqualObjects(managed.boolObj[1], @YES);
    XCTAssertEqualObjects(managed.intObj[1], @3);
    XCTAssertEqualObjects(managed.floatObj[1], @3.3f);
    XCTAssertEqualObjects(managed.doubleObj[1], @3.3);
    XCTAssertEqualObjects(managed.stringObj[1], @"b");
    XCTAssertEqualObjects(managed.dataObj[1], data(2));
    XCTAssertEqualObjects(managed.dateObj[1], date(2));
    XCTAssertEqualObjects(managed.decimalObj[1], decimal128(3));
    XCTAssertEqualObjects(managed.objectIdObj[1], objectId(2));
    XCTAssertEqualObjects(managed.uuidObj[1], uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"));
    XCTAssertEqualObjects(managed.anyBoolObj[1], @YES);
    XCTAssertEqualObjects(managed.anyIntObj[1], @3);
    XCTAssertEqualObjects(managed.anyFloatObj[1], @3.3f);
    XCTAssertEqualObjects(managed.anyDoubleObj[1], @3.3);
    XCTAssertEqualObjects(managed.anyStringObj[1], @"b");
    XCTAssertEqualObjects(managed.anyDataObj[1], data(2));
    XCTAssertEqualObjects(managed.anyDateObj[1], date(2));
    XCTAssertEqualObjects(managed.anyDecimalObj[1], decimal128(3));
    XCTAssertEqualObjects(managed.anyObjectIdObj[1], objectId(2));
    XCTAssertEqualObjects(managed.anyUUIDObj[1], uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"));
    XCTAssertEqualObjects(optManaged.boolObj[1], @YES);
    XCTAssertEqualObjects(optManaged.intObj[1], @3);
    XCTAssertEqualObjects(optManaged.floatObj[1], @3.3f);
    XCTAssertEqualObjects(optManaged.doubleObj[1], @3.3);
    XCTAssertEqualObjects(optManaged.stringObj[1], @"b");
    XCTAssertEqualObjects(optManaged.dataObj[1], data(2));
    XCTAssertEqualObjects(optManaged.dateObj[1], date(2));
    XCTAssertEqualObjects(optManaged.decimalObj[1], decimal128(3));
    XCTAssertEqualObjects(optManaged.objectIdObj[1], objectId(2));
    XCTAssertEqualObjects(optManaged.uuidObj[1], uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"));
    XCTAssertEqualObjects(optUnmanaged.boolObj[2], NSNull.null);
    XCTAssertEqualObjects(optUnmanaged.intObj[2], NSNull.null);
    XCTAssertEqualObjects(optUnmanaged.floatObj[2], NSNull.null);
    XCTAssertEqualObjects(optUnmanaged.doubleObj[2], NSNull.null);
    XCTAssertEqualObjects(optUnmanaged.stringObj[2], NSNull.null);
    XCTAssertEqualObjects(optUnmanaged.dataObj[2], NSNull.null);
    XCTAssertEqualObjects(optUnmanaged.dateObj[2], NSNull.null);
    XCTAssertEqualObjects(optUnmanaged.decimalObj[2], NSNull.null);
    XCTAssertEqualObjects(optUnmanaged.objectIdObj[2], NSNull.null);
    XCTAssertEqualObjects(optUnmanaged.uuidObj[2], NSNull.null);
    XCTAssertEqualObjects(optManaged.boolObj[2], NSNull.null);
    XCTAssertEqualObjects(optManaged.intObj[2], NSNull.null);
    XCTAssertEqualObjects(optManaged.floatObj[2], NSNull.null);
    XCTAssertEqualObjects(optManaged.doubleObj[2], NSNull.null);
    XCTAssertEqualObjects(optManaged.stringObj[2], NSNull.null);
    XCTAssertEqualObjects(optManaged.dataObj[2], NSNull.null);
    XCTAssertEqualObjects(optManaged.dateObj[2], NSNull.null);
    XCTAssertEqualObjects(optManaged.decimalObj[2], NSNull.null);
    XCTAssertEqualObjects(optManaged.objectIdObj[2], NSNull.null);
    XCTAssertEqualObjects(optManaged.uuidObj[2], NSNull.null);
}

- (void)testInsertObject {
    RLMAssertThrowsWithReason([unmanaged.boolObj insertObject:@"a" atIndex:0],
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'bool'");
    RLMAssertThrowsWithReason([unmanaged.intObj insertObject:@"a" atIndex:0],
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'int'");
    RLMAssertThrowsWithReason([unmanaged.floatObj insertObject:@"a" atIndex:0],
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'float'");
    RLMAssertThrowsWithReason([unmanaged.doubleObj insertObject:@"a" atIndex:0],
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'double'");
    RLMAssertThrowsWithReason([unmanaged.stringObj insertObject:@2 atIndex:0],
                              @"Invalid value '2' of type '__NSCFNumber' for expected type 'string'");
    RLMAssertThrowsWithReason([unmanaged.dataObj insertObject:@"a" atIndex:0],
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'data'");
    RLMAssertThrowsWithReason([unmanaged.dateObj insertObject:@"a" atIndex:0],
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'date'");
    RLMAssertThrowsWithReason([unmanaged.decimalObj insertObject:@"a" atIndex:0],
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'decimal128'");
    RLMAssertThrowsWithReason([unmanaged.objectIdObj insertObject:@"a" atIndex:0],
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'object id'");
    RLMAssertThrowsWithReason([unmanaged.uuidObj insertObject:@"a" atIndex:0],
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'uuid'");
    RLMAssertThrowsWithReason([optUnmanaged.boolObj insertObject:@"a" atIndex:0],
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'bool?'");
    RLMAssertThrowsWithReason([optUnmanaged.intObj insertObject:@"a" atIndex:0],
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'int?'");
    RLMAssertThrowsWithReason([optUnmanaged.floatObj insertObject:@"a" atIndex:0],
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'float?'");
    RLMAssertThrowsWithReason([optUnmanaged.doubleObj insertObject:@"a" atIndex:0],
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'double?'");
    RLMAssertThrowsWithReason([optUnmanaged.stringObj insertObject:@2 atIndex:0],
                              @"Invalid value '2' of type '__NSCFNumber' for expected type 'string?'");
    RLMAssertThrowsWithReason([optUnmanaged.dataObj insertObject:@"a" atIndex:0],
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'data?'");
    RLMAssertThrowsWithReason([optUnmanaged.dateObj insertObject:@"a" atIndex:0],
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'date?'");
    RLMAssertThrowsWithReason([optUnmanaged.decimalObj insertObject:@"a" atIndex:0],
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'decimal128?'");
    RLMAssertThrowsWithReason([optUnmanaged.objectIdObj insertObject:@"a" atIndex:0],
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'object id?'");
    RLMAssertThrowsWithReason([optUnmanaged.uuidObj insertObject:@"a" atIndex:0],
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'uuid?'");
    RLMAssertThrowsWithReason([managed.boolObj insertObject:@"a" atIndex:0],
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'bool'");
    RLMAssertThrowsWithReason([managed.intObj insertObject:@"a" atIndex:0],
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'int'");
    RLMAssertThrowsWithReason([managed.floatObj insertObject:@"a" atIndex:0],
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'float'");
    RLMAssertThrowsWithReason([managed.doubleObj insertObject:@"a" atIndex:0],
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'double'");
    RLMAssertThrowsWithReason([managed.stringObj insertObject:@2 atIndex:0],
                              @"Invalid value '2' of type '__NSCFNumber' for expected type 'string'");
    RLMAssertThrowsWithReason([managed.dataObj insertObject:@"a" atIndex:0],
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'data'");
    RLMAssertThrowsWithReason([managed.dateObj insertObject:@"a" atIndex:0],
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'date'");
    RLMAssertThrowsWithReason([managed.decimalObj insertObject:@"a" atIndex:0],
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'decimal128'");
    RLMAssertThrowsWithReason([managed.objectIdObj insertObject:@"a" atIndex:0],
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'object id'");
    RLMAssertThrowsWithReason([managed.uuidObj insertObject:@"a" atIndex:0],
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'uuid'");
    RLMAssertThrowsWithReason([optManaged.boolObj insertObject:@"a" atIndex:0],
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'bool?'");
    RLMAssertThrowsWithReason([optManaged.intObj insertObject:@"a" atIndex:0],
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'int?'");
    RLMAssertThrowsWithReason([optManaged.floatObj insertObject:@"a" atIndex:0],
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'float?'");
    RLMAssertThrowsWithReason([optManaged.doubleObj insertObject:@"a" atIndex:0],
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'double?'");
    RLMAssertThrowsWithReason([optManaged.stringObj insertObject:@2 atIndex:0],
                              @"Invalid value '2' of type '__NSCFNumber' for expected type 'string?'");
    RLMAssertThrowsWithReason([optManaged.dataObj insertObject:@"a" atIndex:0],
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'data?'");
    RLMAssertThrowsWithReason([optManaged.dateObj insertObject:@"a" atIndex:0],
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'date?'");
    RLMAssertThrowsWithReason([optManaged.decimalObj insertObject:@"a" atIndex:0],
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'decimal128?'");
    RLMAssertThrowsWithReason([optManaged.objectIdObj insertObject:@"a" atIndex:0],
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'object id?'");
    RLMAssertThrowsWithReason([optManaged.uuidObj insertObject:@"a" atIndex:0],
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'uuid?'");
    RLMAssertThrowsWithReason([unmanaged.boolObj insertObject:NSNull.null atIndex:0],
                              @"Invalid value '<null>' of type 'NSNull' for expected type 'bool'");
    RLMAssertThrowsWithReason([unmanaged.intObj insertObject:NSNull.null atIndex:0],
                              @"Invalid value '<null>' of type 'NSNull' for expected type 'int'");
    RLMAssertThrowsWithReason([unmanaged.floatObj insertObject:NSNull.null atIndex:0],
                              @"Invalid value '<null>' of type 'NSNull' for expected type 'float'");
    RLMAssertThrowsWithReason([unmanaged.doubleObj insertObject:NSNull.null atIndex:0],
                              @"Invalid value '<null>' of type 'NSNull' for expected type 'double'");
    RLMAssertThrowsWithReason([unmanaged.stringObj insertObject:NSNull.null atIndex:0],
                              @"Invalid value '<null>' of type 'NSNull' for expected type 'string'");
    RLMAssertThrowsWithReason([unmanaged.dataObj insertObject:NSNull.null atIndex:0],
                              @"Invalid value '<null>' of type 'NSNull' for expected type 'data'");
    RLMAssertThrowsWithReason([unmanaged.dateObj insertObject:NSNull.null atIndex:0],
                              @"Invalid value '<null>' of type 'NSNull' for expected type 'date'");
    RLMAssertThrowsWithReason([unmanaged.decimalObj insertObject:NSNull.null atIndex:0],
                              @"Invalid value '<null>' of type 'NSNull' for expected type 'decimal128'");
    RLMAssertThrowsWithReason([unmanaged.objectIdObj insertObject:NSNull.null atIndex:0],
                              @"Invalid value '<null>' of type 'NSNull' for expected type 'object id'");
    RLMAssertThrowsWithReason([unmanaged.uuidObj insertObject:NSNull.null atIndex:0],
                              @"Invalid value '<null>' of type 'NSNull' for expected type 'uuid'");
    RLMAssertThrowsWithReason([managed.boolObj insertObject:NSNull.null atIndex:0],
                              @"Invalid value '<null>' of type 'NSNull' for expected type 'bool'");
    RLMAssertThrowsWithReason([managed.intObj insertObject:NSNull.null atIndex:0],
                              @"Invalid value '<null>' of type 'NSNull' for expected type 'int'");
    RLMAssertThrowsWithReason([managed.floatObj insertObject:NSNull.null atIndex:0],
                              @"Invalid value '<null>' of type 'NSNull' for expected type 'float'");
    RLMAssertThrowsWithReason([managed.doubleObj insertObject:NSNull.null atIndex:0],
                              @"Invalid value '<null>' of type 'NSNull' for expected type 'double'");
    RLMAssertThrowsWithReason([managed.stringObj insertObject:NSNull.null atIndex:0],
                              @"Invalid value '<null>' of type 'NSNull' for expected type 'string'");
    RLMAssertThrowsWithReason([managed.dataObj insertObject:NSNull.null atIndex:0],
                              @"Invalid value '<null>' of type 'NSNull' for expected type 'data'");
    RLMAssertThrowsWithReason([managed.dateObj insertObject:NSNull.null atIndex:0],
                              @"Invalid value '<null>' of type 'NSNull' for expected type 'date'");
    RLMAssertThrowsWithReason([managed.decimalObj insertObject:NSNull.null atIndex:0],
                              @"Invalid value '<null>' of type 'NSNull' for expected type 'decimal128'");
    RLMAssertThrowsWithReason([managed.objectIdObj insertObject:NSNull.null atIndex:0],
                              @"Invalid value '<null>' of type 'NSNull' for expected type 'object id'");
    RLMAssertThrowsWithReason([managed.uuidObj insertObject:NSNull.null atIndex:0],
                              @"Invalid value '<null>' of type 'NSNull' for expected type 'uuid'");
    RLMAssertThrowsWithReason([unmanaged.boolObj insertObject:@NO atIndex:1],
                              @"Index 1 is out of bounds (must be less than 1).");
    RLMAssertThrowsWithReason([unmanaged.intObj insertObject:@2 atIndex:1],
                              @"Index 1 is out of bounds (must be less than 1).");
    RLMAssertThrowsWithReason([unmanaged.floatObj insertObject:@2.2f atIndex:1],
                              @"Index 1 is out of bounds (must be less than 1).");
    RLMAssertThrowsWithReason([unmanaged.doubleObj insertObject:@2.2 atIndex:1],
                              @"Index 1 is out of bounds (must be less than 1).");
    RLMAssertThrowsWithReason([unmanaged.stringObj insertObject:@"a" atIndex:1],
                              @"Index 1 is out of bounds (must be less than 1).");
    RLMAssertThrowsWithReason([unmanaged.dataObj insertObject:data(1) atIndex:1],
                              @"Index 1 is out of bounds (must be less than 1).");
    RLMAssertThrowsWithReason([unmanaged.dateObj insertObject:date(1) atIndex:1],
                              @"Index 1 is out of bounds (must be less than 1).");
    RLMAssertThrowsWithReason([unmanaged.decimalObj insertObject:decimal128(2) atIndex:1],
                              @"Index 1 is out of bounds (must be less than 1).");
    RLMAssertThrowsWithReason([unmanaged.objectIdObj insertObject:objectId(1) atIndex:1],
                              @"Index 1 is out of bounds (must be less than 1).");
    RLMAssertThrowsWithReason([unmanaged.uuidObj insertObject:uuid(@"00000000-0000-0000-0000-000000000000") atIndex:1],
                              @"Index 1 is out of bounds (must be less than 1).");
    RLMAssertThrowsWithReason([unmanaged.anyBoolObj insertObject:@NO atIndex:1],
                              @"Index 1 is out of bounds (must be less than 1).");
    RLMAssertThrowsWithReason([unmanaged.anyIntObj insertObject:@2 atIndex:1],
                              @"Index 1 is out of bounds (must be less than 1).");
    RLMAssertThrowsWithReason([unmanaged.anyFloatObj insertObject:@2.2f atIndex:1],
                              @"Index 1 is out of bounds (must be less than 1).");
    RLMAssertThrowsWithReason([unmanaged.anyDoubleObj insertObject:@2.2 atIndex:1],
                              @"Index 1 is out of bounds (must be less than 1).");
    RLMAssertThrowsWithReason([unmanaged.anyStringObj insertObject:@"a" atIndex:1],
                              @"Index 1 is out of bounds (must be less than 1).");
    RLMAssertThrowsWithReason([unmanaged.anyDataObj insertObject:data(1) atIndex:1],
                              @"Index 1 is out of bounds (must be less than 1).");
    RLMAssertThrowsWithReason([unmanaged.anyDateObj insertObject:date(1) atIndex:1],
                              @"Index 1 is out of bounds (must be less than 1).");
    RLMAssertThrowsWithReason([unmanaged.anyDecimalObj insertObject:decimal128(2) atIndex:1],
                              @"Index 1 is out of bounds (must be less than 1).");
    RLMAssertThrowsWithReason([unmanaged.anyObjectIdObj insertObject:objectId(1) atIndex:1],
                              @"Index 1 is out of bounds (must be less than 1).");
    RLMAssertThrowsWithReason([unmanaged.anyUUIDObj insertObject:uuid(@"00000000-0000-0000-0000-000000000000") atIndex:1],
                              @"Index 1 is out of bounds (must be less than 1).");
    RLMAssertThrowsWithReason([optUnmanaged.boolObj insertObject:@NO atIndex:1],
                              @"Index 1 is out of bounds (must be less than 1).");
    RLMAssertThrowsWithReason([optUnmanaged.intObj insertObject:@2 atIndex:1],
                              @"Index 1 is out of bounds (must be less than 1).");
    RLMAssertThrowsWithReason([optUnmanaged.floatObj insertObject:@2.2f atIndex:1],
                              @"Index 1 is out of bounds (must be less than 1).");
    RLMAssertThrowsWithReason([optUnmanaged.doubleObj insertObject:@2.2 atIndex:1],
                              @"Index 1 is out of bounds (must be less than 1).");
    RLMAssertThrowsWithReason([optUnmanaged.stringObj insertObject:@"a" atIndex:1],
                              @"Index 1 is out of bounds (must be less than 1).");
    RLMAssertThrowsWithReason([optUnmanaged.dataObj insertObject:data(1) atIndex:1],
                              @"Index 1 is out of bounds (must be less than 1).");
    RLMAssertThrowsWithReason([optUnmanaged.dateObj insertObject:date(1) atIndex:1],
                              @"Index 1 is out of bounds (must be less than 1).");
    RLMAssertThrowsWithReason([optUnmanaged.decimalObj insertObject:decimal128(2) atIndex:1],
                              @"Index 1 is out of bounds (must be less than 1).");
    RLMAssertThrowsWithReason([optUnmanaged.objectIdObj insertObject:objectId(1) atIndex:1],
                              @"Index 1 is out of bounds (must be less than 1).");
    RLMAssertThrowsWithReason([optUnmanaged.uuidObj insertObject:uuid(@"00000000-0000-0000-0000-000000000000") atIndex:1],
                              @"Index 1 is out of bounds (must be less than 1).");
    RLMAssertThrowsWithReason([managed.boolObj insertObject:@NO atIndex:1],
                              @"Index 1 is out of bounds (must be less than 1).");
    RLMAssertThrowsWithReason([managed.intObj insertObject:@2 atIndex:1],
                              @"Index 1 is out of bounds (must be less than 1).");
    RLMAssertThrowsWithReason([managed.floatObj insertObject:@2.2f atIndex:1],
                              @"Index 1 is out of bounds (must be less than 1).");
    RLMAssertThrowsWithReason([managed.doubleObj insertObject:@2.2 atIndex:1],
                              @"Index 1 is out of bounds (must be less than 1).");
    RLMAssertThrowsWithReason([managed.stringObj insertObject:@"a" atIndex:1],
                              @"Index 1 is out of bounds (must be less than 1).");
    RLMAssertThrowsWithReason([managed.dataObj insertObject:data(1) atIndex:1],
                              @"Index 1 is out of bounds (must be less than 1).");
    RLMAssertThrowsWithReason([managed.dateObj insertObject:date(1) atIndex:1],
                              @"Index 1 is out of bounds (must be less than 1).");
    RLMAssertThrowsWithReason([managed.decimalObj insertObject:decimal128(2) atIndex:1],
                              @"Index 1 is out of bounds (must be less than 1).");
    RLMAssertThrowsWithReason([managed.objectIdObj insertObject:objectId(1) atIndex:1],
                              @"Index 1 is out of bounds (must be less than 1).");
    RLMAssertThrowsWithReason([managed.uuidObj insertObject:uuid(@"00000000-0000-0000-0000-000000000000") atIndex:1],
                              @"Index 1 is out of bounds (must be less than 1).");
    RLMAssertThrowsWithReason([managed.anyBoolObj insertObject:@NO atIndex:1],
                              @"Index 1 is out of bounds (must be less than 1).");
    RLMAssertThrowsWithReason([managed.anyIntObj insertObject:@2 atIndex:1],
                              @"Index 1 is out of bounds (must be less than 1).");
    RLMAssertThrowsWithReason([managed.anyFloatObj insertObject:@2.2f atIndex:1],
                              @"Index 1 is out of bounds (must be less than 1).");
    RLMAssertThrowsWithReason([managed.anyDoubleObj insertObject:@2.2 atIndex:1],
                              @"Index 1 is out of bounds (must be less than 1).");
    RLMAssertThrowsWithReason([managed.anyStringObj insertObject:@"a" atIndex:1],
                              @"Index 1 is out of bounds (must be less than 1).");
    RLMAssertThrowsWithReason([managed.anyDataObj insertObject:data(1) atIndex:1],
                              @"Index 1 is out of bounds (must be less than 1).");
    RLMAssertThrowsWithReason([managed.anyDateObj insertObject:date(1) atIndex:1],
                              @"Index 1 is out of bounds (must be less than 1).");
    RLMAssertThrowsWithReason([managed.anyDecimalObj insertObject:decimal128(2) atIndex:1],
                              @"Index 1 is out of bounds (must be less than 1).");
    RLMAssertThrowsWithReason([managed.anyObjectIdObj insertObject:objectId(1) atIndex:1],
                              @"Index 1 is out of bounds (must be less than 1).");
    RLMAssertThrowsWithReason([managed.anyUUIDObj insertObject:uuid(@"00000000-0000-0000-0000-000000000000") atIndex:1],
                              @"Index 1 is out of bounds (must be less than 1).");
    RLMAssertThrowsWithReason([optManaged.boolObj insertObject:@NO atIndex:1],
                              @"Index 1 is out of bounds (must be less than 1).");
    RLMAssertThrowsWithReason([optManaged.intObj insertObject:@2 atIndex:1],
                              @"Index 1 is out of bounds (must be less than 1).");
    RLMAssertThrowsWithReason([optManaged.floatObj insertObject:@2.2f atIndex:1],
                              @"Index 1 is out of bounds (must be less than 1).");
    RLMAssertThrowsWithReason([optManaged.doubleObj insertObject:@2.2 atIndex:1],
                              @"Index 1 is out of bounds (must be less than 1).");
    RLMAssertThrowsWithReason([optManaged.stringObj insertObject:@"a" atIndex:1],
                              @"Index 1 is out of bounds (must be less than 1).");
    RLMAssertThrowsWithReason([optManaged.dataObj insertObject:data(1) atIndex:1],
                              @"Index 1 is out of bounds (must be less than 1).");
    RLMAssertThrowsWithReason([optManaged.dateObj insertObject:date(1) atIndex:1],
                              @"Index 1 is out of bounds (must be less than 1).");
    RLMAssertThrowsWithReason([optManaged.decimalObj insertObject:decimal128(2) atIndex:1],
                              @"Index 1 is out of bounds (must be less than 1).");
    RLMAssertThrowsWithReason([optManaged.objectIdObj insertObject:objectId(1) atIndex:1],
                              @"Index 1 is out of bounds (must be less than 1).");
    RLMAssertThrowsWithReason([optManaged.uuidObj insertObject:uuid(@"00000000-0000-0000-0000-000000000000") atIndex:1],
                              @"Index 1 is out of bounds (must be less than 1).");

    [unmanaged.boolObj insertObject:@NO atIndex:0];
    [unmanaged.intObj insertObject:@2 atIndex:0];
    [unmanaged.floatObj insertObject:@2.2f atIndex:0];
    [unmanaged.doubleObj insertObject:@2.2 atIndex:0];
    [unmanaged.stringObj insertObject:@"a" atIndex:0];
    [unmanaged.dataObj insertObject:data(1) atIndex:0];
    [unmanaged.dateObj insertObject:date(1) atIndex:0];
    [unmanaged.decimalObj insertObject:decimal128(2) atIndex:0];
    [unmanaged.objectIdObj insertObject:objectId(1) atIndex:0];
    [unmanaged.uuidObj insertObject:uuid(@"00000000-0000-0000-0000-000000000000") atIndex:0];
    [unmanaged.anyBoolObj insertObject:@NO atIndex:0];
    [unmanaged.anyIntObj insertObject:@2 atIndex:0];
    [unmanaged.anyFloatObj insertObject:@2.2f atIndex:0];
    [unmanaged.anyDoubleObj insertObject:@2.2 atIndex:0];
    [unmanaged.anyStringObj insertObject:@"a" atIndex:0];
    [unmanaged.anyDataObj insertObject:data(1) atIndex:0];
    [unmanaged.anyDateObj insertObject:date(1) atIndex:0];
    [unmanaged.anyDecimalObj insertObject:decimal128(2) atIndex:0];
    [unmanaged.anyObjectIdObj insertObject:objectId(1) atIndex:0];
    [unmanaged.anyUUIDObj insertObject:uuid(@"00000000-0000-0000-0000-000000000000") atIndex:0];
    [optUnmanaged.boolObj insertObject:@NO atIndex:0];
    [optUnmanaged.intObj insertObject:@2 atIndex:0];
    [optUnmanaged.floatObj insertObject:@2.2f atIndex:0];
    [optUnmanaged.doubleObj insertObject:@2.2 atIndex:0];
    [optUnmanaged.stringObj insertObject:@"a" atIndex:0];
    [optUnmanaged.dataObj insertObject:data(1) atIndex:0];
    [optUnmanaged.dateObj insertObject:date(1) atIndex:0];
    [optUnmanaged.decimalObj insertObject:decimal128(2) atIndex:0];
    [optUnmanaged.objectIdObj insertObject:objectId(1) atIndex:0];
    [optUnmanaged.uuidObj insertObject:uuid(@"00000000-0000-0000-0000-000000000000") atIndex:0];
    [managed.boolObj insertObject:@NO atIndex:0];
    [managed.intObj insertObject:@2 atIndex:0];
    [managed.floatObj insertObject:@2.2f atIndex:0];
    [managed.doubleObj insertObject:@2.2 atIndex:0];
    [managed.stringObj insertObject:@"a" atIndex:0];
    [managed.dataObj insertObject:data(1) atIndex:0];
    [managed.dateObj insertObject:date(1) atIndex:0];
    [managed.decimalObj insertObject:decimal128(2) atIndex:0];
    [managed.objectIdObj insertObject:objectId(1) atIndex:0];
    [managed.uuidObj insertObject:uuid(@"00000000-0000-0000-0000-000000000000") atIndex:0];
    [managed.anyBoolObj insertObject:@NO atIndex:0];
    [managed.anyIntObj insertObject:@2 atIndex:0];
    [managed.anyFloatObj insertObject:@2.2f atIndex:0];
    [managed.anyDoubleObj insertObject:@2.2 atIndex:0];
    [managed.anyStringObj insertObject:@"a" atIndex:0];
    [managed.anyDataObj insertObject:data(1) atIndex:0];
    [managed.anyDateObj insertObject:date(1) atIndex:0];
    [managed.anyDecimalObj insertObject:decimal128(2) atIndex:0];
    [managed.anyObjectIdObj insertObject:objectId(1) atIndex:0];
    [managed.anyUUIDObj insertObject:uuid(@"00000000-0000-0000-0000-000000000000") atIndex:0];
    [optManaged.boolObj insertObject:@NO atIndex:0];
    [optManaged.intObj insertObject:@2 atIndex:0];
    [optManaged.floatObj insertObject:@2.2f atIndex:0];
    [optManaged.doubleObj insertObject:@2.2 atIndex:0];
    [optManaged.stringObj insertObject:@"a" atIndex:0];
    [optManaged.dataObj insertObject:data(1) atIndex:0];
    [optManaged.dateObj insertObject:date(1) atIndex:0];
    [optManaged.decimalObj insertObject:decimal128(2) atIndex:0];
    [optManaged.objectIdObj insertObject:objectId(1) atIndex:0];
    [optManaged.uuidObj insertObject:uuid(@"00000000-0000-0000-0000-000000000000") atIndex:0];
    XCTAssertEqualObjects(unmanaged.boolObj[0], @NO);
    XCTAssertEqualObjects(unmanaged.intObj[0], @2);
    XCTAssertEqualObjects(unmanaged.floatObj[0], @2.2f);
    XCTAssertEqualObjects(unmanaged.doubleObj[0], @2.2);
    XCTAssertEqualObjects(unmanaged.stringObj[0], @"a");
    XCTAssertEqualObjects(unmanaged.dataObj[0], data(1));
    XCTAssertEqualObjects(unmanaged.dateObj[0], date(1));
    XCTAssertEqualObjects(unmanaged.decimalObj[0], decimal128(2));
    XCTAssertEqualObjects(unmanaged.objectIdObj[0], objectId(1));
    XCTAssertEqualObjects(unmanaged.uuidObj[0], uuid(@"00000000-0000-0000-0000-000000000000"));
    XCTAssertEqualObjects(unmanaged.anyBoolObj[0], @NO);
    XCTAssertEqualObjects(unmanaged.anyIntObj[0], @2);
    XCTAssertEqualObjects(unmanaged.anyFloatObj[0], @2.2f);
    XCTAssertEqualObjects(unmanaged.anyDoubleObj[0], @2.2);
    XCTAssertEqualObjects(unmanaged.anyStringObj[0], @"a");
    XCTAssertEqualObjects(unmanaged.anyDataObj[0], data(1));
    XCTAssertEqualObjects(unmanaged.anyDateObj[0], date(1));
    XCTAssertEqualObjects(unmanaged.anyDecimalObj[0], decimal128(2));
    XCTAssertEqualObjects(unmanaged.anyObjectIdObj[0], objectId(1));
    XCTAssertEqualObjects(unmanaged.anyUUIDObj[0], uuid(@"00000000-0000-0000-0000-000000000000"));
    XCTAssertEqualObjects(optUnmanaged.boolObj[0], @NO);
    XCTAssertEqualObjects(optUnmanaged.intObj[0], @2);
    XCTAssertEqualObjects(optUnmanaged.floatObj[0], @2.2f);
    XCTAssertEqualObjects(optUnmanaged.doubleObj[0], @2.2);
    XCTAssertEqualObjects(optUnmanaged.stringObj[0], @"a");
    XCTAssertEqualObjects(optUnmanaged.dataObj[0], data(1));
    XCTAssertEqualObjects(optUnmanaged.dateObj[0], date(1));
    XCTAssertEqualObjects(optUnmanaged.decimalObj[0], decimal128(2));
    XCTAssertEqualObjects(optUnmanaged.objectIdObj[0], objectId(1));
    XCTAssertEqualObjects(optUnmanaged.uuidObj[0], uuid(@"00000000-0000-0000-0000-000000000000"));
    XCTAssertEqualObjects(managed.boolObj[0], @NO);
    XCTAssertEqualObjects(managed.intObj[0], @2);
    XCTAssertEqualObjects(managed.floatObj[0], @2.2f);
    XCTAssertEqualObjects(managed.doubleObj[0], @2.2);
    XCTAssertEqualObjects(managed.stringObj[0], @"a");
    XCTAssertEqualObjects(managed.dataObj[0], data(1));
    XCTAssertEqualObjects(managed.dateObj[0], date(1));
    XCTAssertEqualObjects(managed.decimalObj[0], decimal128(2));
    XCTAssertEqualObjects(managed.objectIdObj[0], objectId(1));
    XCTAssertEqualObjects(managed.uuidObj[0], uuid(@"00000000-0000-0000-0000-000000000000"));
    XCTAssertEqualObjects(managed.anyBoolObj[0], @NO);
    XCTAssertEqualObjects(managed.anyIntObj[0], @2);
    XCTAssertEqualObjects(managed.anyFloatObj[0], @2.2f);
    XCTAssertEqualObjects(managed.anyDoubleObj[0], @2.2);
    XCTAssertEqualObjects(managed.anyStringObj[0], @"a");
    XCTAssertEqualObjects(managed.anyDataObj[0], data(1));
    XCTAssertEqualObjects(managed.anyDateObj[0], date(1));
    XCTAssertEqualObjects(managed.anyDecimalObj[0], decimal128(2));
    XCTAssertEqualObjects(managed.anyObjectIdObj[0], objectId(1));
    XCTAssertEqualObjects(managed.anyUUIDObj[0], uuid(@"00000000-0000-0000-0000-000000000000"));
    XCTAssertEqualObjects(optManaged.boolObj[0], @NO);
    XCTAssertEqualObjects(optManaged.intObj[0], @2);
    XCTAssertEqualObjects(optManaged.floatObj[0], @2.2f);
    XCTAssertEqualObjects(optManaged.doubleObj[0], @2.2);
    XCTAssertEqualObjects(optManaged.stringObj[0], @"a");
    XCTAssertEqualObjects(optManaged.dataObj[0], data(1));
    XCTAssertEqualObjects(optManaged.dateObj[0], date(1));
    XCTAssertEqualObjects(optManaged.decimalObj[0], decimal128(2));
    XCTAssertEqualObjects(optManaged.objectIdObj[0], objectId(1));
    XCTAssertEqualObjects(optManaged.uuidObj[0], uuid(@"00000000-0000-0000-0000-000000000000"));

    [unmanaged.boolObj insertObject:@YES atIndex:0];
    [unmanaged.intObj insertObject:@3 atIndex:0];
    [unmanaged.floatObj insertObject:@3.3f atIndex:0];
    [unmanaged.doubleObj insertObject:@3.3 atIndex:0];
    [unmanaged.stringObj insertObject:@"b" atIndex:0];
    [unmanaged.dataObj insertObject:data(2) atIndex:0];
    [unmanaged.dateObj insertObject:date(2) atIndex:0];
    [unmanaged.decimalObj insertObject:decimal128(3) atIndex:0];
    [unmanaged.objectIdObj insertObject:objectId(2) atIndex:0];
    [unmanaged.uuidObj insertObject:uuid(@"137DECC8-B300-4954-A233-F89909F4FD89") atIndex:0];
    [unmanaged.anyBoolObj insertObject:@YES atIndex:0];
    [unmanaged.anyIntObj insertObject:@3 atIndex:0];
    [unmanaged.anyFloatObj insertObject:@3.3f atIndex:0];
    [unmanaged.anyDoubleObj insertObject:@3.3 atIndex:0];
    [unmanaged.anyStringObj insertObject:@"b" atIndex:0];
    [unmanaged.anyDataObj insertObject:data(2) atIndex:0];
    [unmanaged.anyDateObj insertObject:date(2) atIndex:0];
    [unmanaged.anyDecimalObj insertObject:decimal128(3) atIndex:0];
    [unmanaged.anyObjectIdObj insertObject:objectId(2) atIndex:0];
    [unmanaged.anyUUIDObj insertObject:uuid(@"137DECC8-B300-4954-A233-F89909F4FD89") atIndex:0];
    [optUnmanaged.boolObj insertObject:@YES atIndex:0];
    [optUnmanaged.intObj insertObject:@3 atIndex:0];
    [optUnmanaged.floatObj insertObject:@3.3f atIndex:0];
    [optUnmanaged.doubleObj insertObject:@3.3 atIndex:0];
    [optUnmanaged.stringObj insertObject:@"b" atIndex:0];
    [optUnmanaged.dataObj insertObject:data(2) atIndex:0];
    [optUnmanaged.dateObj insertObject:date(2) atIndex:0];
    [optUnmanaged.decimalObj insertObject:decimal128(3) atIndex:0];
    [optUnmanaged.objectIdObj insertObject:objectId(2) atIndex:0];
    [optUnmanaged.uuidObj insertObject:uuid(@"137DECC8-B300-4954-A233-F89909F4FD89") atIndex:0];
    [managed.boolObj insertObject:@YES atIndex:0];
    [managed.intObj insertObject:@3 atIndex:0];
    [managed.floatObj insertObject:@3.3f atIndex:0];
    [managed.doubleObj insertObject:@3.3 atIndex:0];
    [managed.stringObj insertObject:@"b" atIndex:0];
    [managed.dataObj insertObject:data(2) atIndex:0];
    [managed.dateObj insertObject:date(2) atIndex:0];
    [managed.decimalObj insertObject:decimal128(3) atIndex:0];
    [managed.objectIdObj insertObject:objectId(2) atIndex:0];
    [managed.uuidObj insertObject:uuid(@"137DECC8-B300-4954-A233-F89909F4FD89") atIndex:0];
    [managed.anyBoolObj insertObject:@YES atIndex:0];
    [managed.anyIntObj insertObject:@3 atIndex:0];
    [managed.anyFloatObj insertObject:@3.3f atIndex:0];
    [managed.anyDoubleObj insertObject:@3.3 atIndex:0];
    [managed.anyStringObj insertObject:@"b" atIndex:0];
    [managed.anyDataObj insertObject:data(2) atIndex:0];
    [managed.anyDateObj insertObject:date(2) atIndex:0];
    [managed.anyDecimalObj insertObject:decimal128(3) atIndex:0];
    [managed.anyObjectIdObj insertObject:objectId(2) atIndex:0];
    [managed.anyUUIDObj insertObject:uuid(@"137DECC8-B300-4954-A233-F89909F4FD89") atIndex:0];
    [optManaged.boolObj insertObject:@YES atIndex:0];
    [optManaged.intObj insertObject:@3 atIndex:0];
    [optManaged.floatObj insertObject:@3.3f atIndex:0];
    [optManaged.doubleObj insertObject:@3.3 atIndex:0];
    [optManaged.stringObj insertObject:@"b" atIndex:0];
    [optManaged.dataObj insertObject:data(2) atIndex:0];
    [optManaged.dateObj insertObject:date(2) atIndex:0];
    [optManaged.decimalObj insertObject:decimal128(3) atIndex:0];
    [optManaged.objectIdObj insertObject:objectId(2) atIndex:0];
    [optManaged.uuidObj insertObject:uuid(@"137DECC8-B300-4954-A233-F89909F4FD89") atIndex:0];
    XCTAssertEqualObjects(unmanaged.boolObj[0], @YES);
    XCTAssertEqualObjects(unmanaged.intObj[0], @3);
    XCTAssertEqualObjects(unmanaged.floatObj[0], @3.3f);
    XCTAssertEqualObjects(unmanaged.doubleObj[0], @3.3);
    XCTAssertEqualObjects(unmanaged.stringObj[0], @"b");
    XCTAssertEqualObjects(unmanaged.dataObj[0], data(2));
    XCTAssertEqualObjects(unmanaged.dateObj[0], date(2));
    XCTAssertEqualObjects(unmanaged.decimalObj[0], decimal128(3));
    XCTAssertEqualObjects(unmanaged.objectIdObj[0], objectId(2));
    XCTAssertEqualObjects(unmanaged.uuidObj[0], uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"));
    XCTAssertEqualObjects(unmanaged.anyBoolObj[0], @YES);
    XCTAssertEqualObjects(unmanaged.anyIntObj[0], @3);
    XCTAssertEqualObjects(unmanaged.anyFloatObj[0], @3.3f);
    XCTAssertEqualObjects(unmanaged.anyDoubleObj[0], @3.3);
    XCTAssertEqualObjects(unmanaged.anyStringObj[0], @"b");
    XCTAssertEqualObjects(unmanaged.anyDataObj[0], data(2));
    XCTAssertEqualObjects(unmanaged.anyDateObj[0], date(2));
    XCTAssertEqualObjects(unmanaged.anyDecimalObj[0], decimal128(3));
    XCTAssertEqualObjects(unmanaged.anyObjectIdObj[0], objectId(2));
    XCTAssertEqualObjects(unmanaged.anyUUIDObj[0], uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"));
    XCTAssertEqualObjects(optUnmanaged.boolObj[0], @YES);
    XCTAssertEqualObjects(optUnmanaged.intObj[0], @3);
    XCTAssertEqualObjects(optUnmanaged.floatObj[0], @3.3f);
    XCTAssertEqualObjects(optUnmanaged.doubleObj[0], @3.3);
    XCTAssertEqualObjects(optUnmanaged.stringObj[0], @"b");
    XCTAssertEqualObjects(optUnmanaged.dataObj[0], data(2));
    XCTAssertEqualObjects(optUnmanaged.dateObj[0], date(2));
    XCTAssertEqualObjects(optUnmanaged.decimalObj[0], decimal128(3));
    XCTAssertEqualObjects(optUnmanaged.objectIdObj[0], objectId(2));
    XCTAssertEqualObjects(optUnmanaged.uuidObj[0], uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"));
    XCTAssertEqualObjects(managed.boolObj[0], @YES);
    XCTAssertEqualObjects(managed.intObj[0], @3);
    XCTAssertEqualObjects(managed.floatObj[0], @3.3f);
    XCTAssertEqualObjects(managed.doubleObj[0], @3.3);
    XCTAssertEqualObjects(managed.stringObj[0], @"b");
    XCTAssertEqualObjects(managed.dataObj[0], data(2));
    XCTAssertEqualObjects(managed.dateObj[0], date(2));
    XCTAssertEqualObjects(managed.decimalObj[0], decimal128(3));
    XCTAssertEqualObjects(managed.objectIdObj[0], objectId(2));
    XCTAssertEqualObjects(managed.uuidObj[0], uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"));
    XCTAssertEqualObjects(managed.anyBoolObj[0], @YES);
    XCTAssertEqualObjects(managed.anyIntObj[0], @3);
    XCTAssertEqualObjects(managed.anyFloatObj[0], @3.3f);
    XCTAssertEqualObjects(managed.anyDoubleObj[0], @3.3);
    XCTAssertEqualObjects(managed.anyStringObj[0], @"b");
    XCTAssertEqualObjects(managed.anyDataObj[0], data(2));
    XCTAssertEqualObjects(managed.anyDateObj[0], date(2));
    XCTAssertEqualObjects(managed.anyDecimalObj[0], decimal128(3));
    XCTAssertEqualObjects(managed.anyObjectIdObj[0], objectId(2));
    XCTAssertEqualObjects(managed.anyUUIDObj[0], uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"));
    XCTAssertEqualObjects(optManaged.boolObj[0], @YES);
    XCTAssertEqualObjects(optManaged.intObj[0], @3);
    XCTAssertEqualObjects(optManaged.floatObj[0], @3.3f);
    XCTAssertEqualObjects(optManaged.doubleObj[0], @3.3);
    XCTAssertEqualObjects(optManaged.stringObj[0], @"b");
    XCTAssertEqualObjects(optManaged.dataObj[0], data(2));
    XCTAssertEqualObjects(optManaged.dateObj[0], date(2));
    XCTAssertEqualObjects(optManaged.decimalObj[0], decimal128(3));
    XCTAssertEqualObjects(optManaged.objectIdObj[0], objectId(2));
    XCTAssertEqualObjects(optManaged.uuidObj[0], uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"));
    XCTAssertEqualObjects(unmanaged.boolObj[1], @NO);
    XCTAssertEqualObjects(unmanaged.intObj[1], @2);
    XCTAssertEqualObjects(unmanaged.floatObj[1], @2.2f);
    XCTAssertEqualObjects(unmanaged.doubleObj[1], @2.2);
    XCTAssertEqualObjects(unmanaged.stringObj[1], @"a");
    XCTAssertEqualObjects(unmanaged.dataObj[1], data(1));
    XCTAssertEqualObjects(unmanaged.dateObj[1], date(1));
    XCTAssertEqualObjects(unmanaged.decimalObj[1], decimal128(2));
    XCTAssertEqualObjects(unmanaged.objectIdObj[1], objectId(1));
    XCTAssertEqualObjects(unmanaged.uuidObj[1], uuid(@"00000000-0000-0000-0000-000000000000"));
    XCTAssertEqualObjects(unmanaged.anyBoolObj[1], @NO);
    XCTAssertEqualObjects(unmanaged.anyIntObj[1], @2);
    XCTAssertEqualObjects(unmanaged.anyFloatObj[1], @2.2f);
    XCTAssertEqualObjects(unmanaged.anyDoubleObj[1], @2.2);
    XCTAssertEqualObjects(unmanaged.anyStringObj[1], @"a");
    XCTAssertEqualObjects(unmanaged.anyDataObj[1], data(1));
    XCTAssertEqualObjects(unmanaged.anyDateObj[1], date(1));
    XCTAssertEqualObjects(unmanaged.anyDecimalObj[1], decimal128(2));
    XCTAssertEqualObjects(unmanaged.anyObjectIdObj[1], objectId(1));
    XCTAssertEqualObjects(unmanaged.anyUUIDObj[1], uuid(@"00000000-0000-0000-0000-000000000000"));
    XCTAssertEqualObjects(optUnmanaged.boolObj[1], @NO);
    XCTAssertEqualObjects(optUnmanaged.intObj[1], @2);
    XCTAssertEqualObjects(optUnmanaged.floatObj[1], @2.2f);
    XCTAssertEqualObjects(optUnmanaged.doubleObj[1], @2.2);
    XCTAssertEqualObjects(optUnmanaged.stringObj[1], @"a");
    XCTAssertEqualObjects(optUnmanaged.dataObj[1], data(1));
    XCTAssertEqualObjects(optUnmanaged.dateObj[1], date(1));
    XCTAssertEqualObjects(optUnmanaged.decimalObj[1], decimal128(2));
    XCTAssertEqualObjects(optUnmanaged.objectIdObj[1], objectId(1));
    XCTAssertEqualObjects(optUnmanaged.uuidObj[1], uuid(@"00000000-0000-0000-0000-000000000000"));
    XCTAssertEqualObjects(managed.boolObj[1], @NO);
    XCTAssertEqualObjects(managed.intObj[1], @2);
    XCTAssertEqualObjects(managed.floatObj[1], @2.2f);
    XCTAssertEqualObjects(managed.doubleObj[1], @2.2);
    XCTAssertEqualObjects(managed.stringObj[1], @"a");
    XCTAssertEqualObjects(managed.dataObj[1], data(1));
    XCTAssertEqualObjects(managed.dateObj[1], date(1));
    XCTAssertEqualObjects(managed.decimalObj[1], decimal128(2));
    XCTAssertEqualObjects(managed.objectIdObj[1], objectId(1));
    XCTAssertEqualObjects(managed.uuidObj[1], uuid(@"00000000-0000-0000-0000-000000000000"));
    XCTAssertEqualObjects(managed.anyBoolObj[1], @NO);
    XCTAssertEqualObjects(managed.anyIntObj[1], @2);
    XCTAssertEqualObjects(managed.anyFloatObj[1], @2.2f);
    XCTAssertEqualObjects(managed.anyDoubleObj[1], @2.2);
    XCTAssertEqualObjects(managed.anyStringObj[1], @"a");
    XCTAssertEqualObjects(managed.anyDataObj[1], data(1));
    XCTAssertEqualObjects(managed.anyDateObj[1], date(1));
    XCTAssertEqualObjects(managed.anyDecimalObj[1], decimal128(2));
    XCTAssertEqualObjects(managed.anyObjectIdObj[1], objectId(1));
    XCTAssertEqualObjects(managed.anyUUIDObj[1], uuid(@"00000000-0000-0000-0000-000000000000"));
    XCTAssertEqualObjects(optManaged.boolObj[1], @NO);
    XCTAssertEqualObjects(optManaged.intObj[1], @2);
    XCTAssertEqualObjects(optManaged.floatObj[1], @2.2f);
    XCTAssertEqualObjects(optManaged.doubleObj[1], @2.2);
    XCTAssertEqualObjects(optManaged.stringObj[1], @"a");
    XCTAssertEqualObjects(optManaged.dataObj[1], data(1));
    XCTAssertEqualObjects(optManaged.dateObj[1], date(1));
    XCTAssertEqualObjects(optManaged.decimalObj[1], decimal128(2));
    XCTAssertEqualObjects(optManaged.objectIdObj[1], objectId(1));
    XCTAssertEqualObjects(optManaged.uuidObj[1], uuid(@"00000000-0000-0000-0000-000000000000"));

    [optUnmanaged.boolObj insertObject:NSNull.null atIndex:1];
    [optUnmanaged.intObj insertObject:NSNull.null atIndex:1];
    [optUnmanaged.floatObj insertObject:NSNull.null atIndex:1];
    [optUnmanaged.doubleObj insertObject:NSNull.null atIndex:1];
    [optUnmanaged.stringObj insertObject:NSNull.null atIndex:1];
    [optUnmanaged.dataObj insertObject:NSNull.null atIndex:1];
    [optUnmanaged.dateObj insertObject:NSNull.null atIndex:1];
    [optUnmanaged.decimalObj insertObject:NSNull.null atIndex:1];
    [optUnmanaged.objectIdObj insertObject:NSNull.null atIndex:1];
    [optUnmanaged.uuidObj insertObject:NSNull.null atIndex:1];
    [optManaged.boolObj insertObject:NSNull.null atIndex:1];
    [optManaged.intObj insertObject:NSNull.null atIndex:1];
    [optManaged.floatObj insertObject:NSNull.null atIndex:1];
    [optManaged.doubleObj insertObject:NSNull.null atIndex:1];
    [optManaged.stringObj insertObject:NSNull.null atIndex:1];
    [optManaged.dataObj insertObject:NSNull.null atIndex:1];
    [optManaged.dateObj insertObject:NSNull.null atIndex:1];
    [optManaged.decimalObj insertObject:NSNull.null atIndex:1];
    [optManaged.objectIdObj insertObject:NSNull.null atIndex:1];
    [optManaged.uuidObj insertObject:NSNull.null atIndex:1];
    XCTAssertEqualObjects(optUnmanaged.boolObj[0], @YES);
    XCTAssertEqualObjects(optUnmanaged.intObj[0], @3);
    XCTAssertEqualObjects(optUnmanaged.floatObj[0], @3.3f);
    XCTAssertEqualObjects(optUnmanaged.doubleObj[0], @3.3);
    XCTAssertEqualObjects(optUnmanaged.stringObj[0], @"b");
    XCTAssertEqualObjects(optUnmanaged.dataObj[0], data(2));
    XCTAssertEqualObjects(optUnmanaged.dateObj[0], date(2));
    XCTAssertEqualObjects(optUnmanaged.decimalObj[0], decimal128(3));
    XCTAssertEqualObjects(optUnmanaged.objectIdObj[0], objectId(2));
    XCTAssertEqualObjects(optUnmanaged.uuidObj[0], uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"));
    XCTAssertEqualObjects(optManaged.boolObj[0], @YES);
    XCTAssertEqualObjects(optManaged.intObj[0], @3);
    XCTAssertEqualObjects(optManaged.floatObj[0], @3.3f);
    XCTAssertEqualObjects(optManaged.doubleObj[0], @3.3);
    XCTAssertEqualObjects(optManaged.stringObj[0], @"b");
    XCTAssertEqualObjects(optManaged.dataObj[0], data(2));
    XCTAssertEqualObjects(optManaged.dateObj[0], date(2));
    XCTAssertEqualObjects(optManaged.decimalObj[0], decimal128(3));
    XCTAssertEqualObjects(optManaged.objectIdObj[0], objectId(2));
    XCTAssertEqualObjects(optManaged.uuidObj[0], uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"));
    XCTAssertEqualObjects(optUnmanaged.boolObj[1], NSNull.null);
    XCTAssertEqualObjects(optUnmanaged.intObj[1], NSNull.null);
    XCTAssertEqualObjects(optUnmanaged.floatObj[1], NSNull.null);
    XCTAssertEqualObjects(optUnmanaged.doubleObj[1], NSNull.null);
    XCTAssertEqualObjects(optUnmanaged.stringObj[1], NSNull.null);
    XCTAssertEqualObjects(optUnmanaged.dataObj[1], NSNull.null);
    XCTAssertEqualObjects(optUnmanaged.dateObj[1], NSNull.null);
    XCTAssertEqualObjects(optUnmanaged.decimalObj[1], NSNull.null);
    XCTAssertEqualObjects(optUnmanaged.objectIdObj[1], NSNull.null);
    XCTAssertEqualObjects(optUnmanaged.uuidObj[1], NSNull.null);
    XCTAssertEqualObjects(optManaged.boolObj[1], NSNull.null);
    XCTAssertEqualObjects(optManaged.intObj[1], NSNull.null);
    XCTAssertEqualObjects(optManaged.floatObj[1], NSNull.null);
    XCTAssertEqualObjects(optManaged.doubleObj[1], NSNull.null);
    XCTAssertEqualObjects(optManaged.stringObj[1], NSNull.null);
    XCTAssertEqualObjects(optManaged.dataObj[1], NSNull.null);
    XCTAssertEqualObjects(optManaged.dateObj[1], NSNull.null);
    XCTAssertEqualObjects(optManaged.decimalObj[1], NSNull.null);
    XCTAssertEqualObjects(optManaged.objectIdObj[1], NSNull.null);
    XCTAssertEqualObjects(optManaged.uuidObj[1], NSNull.null);
    XCTAssertEqualObjects(optUnmanaged.boolObj[2], @NO);
    XCTAssertEqualObjects(optUnmanaged.intObj[2], @2);
    XCTAssertEqualObjects(optUnmanaged.floatObj[2], @2.2f);
    XCTAssertEqualObjects(optUnmanaged.doubleObj[2], @2.2);
    XCTAssertEqualObjects(optUnmanaged.stringObj[2], @"a");
    XCTAssertEqualObjects(optUnmanaged.dataObj[2], data(1));
    XCTAssertEqualObjects(optUnmanaged.dateObj[2], date(1));
    XCTAssertEqualObjects(optUnmanaged.decimalObj[2], decimal128(2));
    XCTAssertEqualObjects(optUnmanaged.objectIdObj[2], objectId(1));
    XCTAssertEqualObjects(optUnmanaged.uuidObj[2], uuid(@"00000000-0000-0000-0000-000000000000"));
    XCTAssertEqualObjects(optManaged.boolObj[2], @NO);
    XCTAssertEqualObjects(optManaged.intObj[2], @2);
    XCTAssertEqualObjects(optManaged.floatObj[2], @2.2f);
    XCTAssertEqualObjects(optManaged.doubleObj[2], @2.2);
    XCTAssertEqualObjects(optManaged.stringObj[2], @"a");
    XCTAssertEqualObjects(optManaged.dataObj[2], data(1));
    XCTAssertEqualObjects(optManaged.dateObj[2], date(1));
    XCTAssertEqualObjects(optManaged.decimalObj[2], decimal128(2));
    XCTAssertEqualObjects(optManaged.objectIdObj[2], objectId(1));
    XCTAssertEqualObjects(optManaged.uuidObj[2], uuid(@"00000000-0000-0000-0000-000000000000"));
}

- (void)testRemoveObject {
    for (RLMArray *array in allArrays) {
        RLMAssertThrowsWithReason([array removeObjectAtIndex:0],
                                  @"Index 0 is out of bounds (must be less than 0).");
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

    RLMAssertThrowsWithReason([unmanaged.boolObj removeObjectAtIndex:2],
                              @"Index 2 is out of bounds (must be less than 2).");
    RLMAssertThrowsWithReason([unmanaged.intObj removeObjectAtIndex:2],
                              @"Index 2 is out of bounds (must be less than 2).");
    RLMAssertThrowsWithReason([unmanaged.floatObj removeObjectAtIndex:2],
                              @"Index 2 is out of bounds (must be less than 2).");
    RLMAssertThrowsWithReason([unmanaged.doubleObj removeObjectAtIndex:2],
                              @"Index 2 is out of bounds (must be less than 2).");
    RLMAssertThrowsWithReason([unmanaged.stringObj removeObjectAtIndex:2],
                              @"Index 2 is out of bounds (must be less than 2).");
    RLMAssertThrowsWithReason([unmanaged.dataObj removeObjectAtIndex:2],
                              @"Index 2 is out of bounds (must be less than 2).");
    RLMAssertThrowsWithReason([unmanaged.dateObj removeObjectAtIndex:2],
                              @"Index 2 is out of bounds (must be less than 2).");
    RLMAssertThrowsWithReason([unmanaged.decimalObj removeObjectAtIndex:2],
                              @"Index 2 is out of bounds (must be less than 2).");
    RLMAssertThrowsWithReason([unmanaged.objectIdObj removeObjectAtIndex:2],
                              @"Index 2 is out of bounds (must be less than 2).");
    RLMAssertThrowsWithReason([unmanaged.uuidObj removeObjectAtIndex:2],
                              @"Index 2 is out of bounds (must be less than 2).");
    RLMAssertThrowsWithReason([managed.boolObj removeObjectAtIndex:2],
                              @"Index 2 is out of bounds (must be less than 2).");
    RLMAssertThrowsWithReason([managed.intObj removeObjectAtIndex:2],
                              @"Index 2 is out of bounds (must be less than 2).");
    RLMAssertThrowsWithReason([managed.floatObj removeObjectAtIndex:2],
                              @"Index 2 is out of bounds (must be less than 2).");
    RLMAssertThrowsWithReason([managed.doubleObj removeObjectAtIndex:2],
                              @"Index 2 is out of bounds (must be less than 2).");
    RLMAssertThrowsWithReason([managed.stringObj removeObjectAtIndex:2],
                              @"Index 2 is out of bounds (must be less than 2).");
    RLMAssertThrowsWithReason([managed.dataObj removeObjectAtIndex:2],
                              @"Index 2 is out of bounds (must be less than 2).");
    RLMAssertThrowsWithReason([managed.dateObj removeObjectAtIndex:2],
                              @"Index 2 is out of bounds (must be less than 2).");
    RLMAssertThrowsWithReason([managed.decimalObj removeObjectAtIndex:2],
                              @"Index 2 is out of bounds (must be less than 2).");
    RLMAssertThrowsWithReason([managed.objectIdObj removeObjectAtIndex:2],
                              @"Index 2 is out of bounds (must be less than 2).");
    RLMAssertThrowsWithReason([managed.uuidObj removeObjectAtIndex:2],
                              @"Index 2 is out of bounds (must be less than 2).");
    RLMAssertThrowsWithReason([optUnmanaged.boolObj removeObjectAtIndex:3],
                              @"Index 3 is out of bounds (must be less than 3).");
    RLMAssertThrowsWithReason([optUnmanaged.intObj removeObjectAtIndex:3],
                              @"Index 3 is out of bounds (must be less than 3).");
    RLMAssertThrowsWithReason([optUnmanaged.floatObj removeObjectAtIndex:3],
                              @"Index 3 is out of bounds (must be less than 3).");
    RLMAssertThrowsWithReason([optUnmanaged.doubleObj removeObjectAtIndex:3],
                              @"Index 3 is out of bounds (must be less than 3).");
    RLMAssertThrowsWithReason([optUnmanaged.stringObj removeObjectAtIndex:3],
                              @"Index 3 is out of bounds (must be less than 3).");
    RLMAssertThrowsWithReason([optUnmanaged.dataObj removeObjectAtIndex:3],
                              @"Index 3 is out of bounds (must be less than 3).");
    RLMAssertThrowsWithReason([optUnmanaged.dateObj removeObjectAtIndex:3],
                              @"Index 3 is out of bounds (must be less than 3).");
    RLMAssertThrowsWithReason([optUnmanaged.decimalObj removeObjectAtIndex:3],
                              @"Index 3 is out of bounds (must be less than 3).");
    RLMAssertThrowsWithReason([optUnmanaged.objectIdObj removeObjectAtIndex:3],
                              @"Index 3 is out of bounds (must be less than 3).");
    RLMAssertThrowsWithReason([optUnmanaged.uuidObj removeObjectAtIndex:3],
                              @"Index 3 is out of bounds (must be less than 3).");
    RLMAssertThrowsWithReason([optManaged.boolObj removeObjectAtIndex:3],
                              @"Index 3 is out of bounds (must be less than 3).");
    RLMAssertThrowsWithReason([optManaged.intObj removeObjectAtIndex:3],
                              @"Index 3 is out of bounds (must be less than 3).");
    RLMAssertThrowsWithReason([optManaged.floatObj removeObjectAtIndex:3],
                              @"Index 3 is out of bounds (must be less than 3).");
    RLMAssertThrowsWithReason([optManaged.doubleObj removeObjectAtIndex:3],
                              @"Index 3 is out of bounds (must be less than 3).");
    RLMAssertThrowsWithReason([optManaged.stringObj removeObjectAtIndex:3],
                              @"Index 3 is out of bounds (must be less than 3).");
    RLMAssertThrowsWithReason([optManaged.dataObj removeObjectAtIndex:3],
                              @"Index 3 is out of bounds (must be less than 3).");
    RLMAssertThrowsWithReason([optManaged.dateObj removeObjectAtIndex:3],
                              @"Index 3 is out of bounds (must be less than 3).");
    RLMAssertThrowsWithReason([optManaged.decimalObj removeObjectAtIndex:3],
                              @"Index 3 is out of bounds (must be less than 3).");
    RLMAssertThrowsWithReason([optManaged.objectIdObj removeObjectAtIndex:3],
                              @"Index 3 is out of bounds (must be less than 3).");
    RLMAssertThrowsWithReason([optManaged.uuidObj removeObjectAtIndex:3],
                              @"Index 3 is out of bounds (must be less than 3).");

    for (RLMArray *array in allArrays) {
        [array removeObjectAtIndex:0];
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

    XCTAssertEqualObjects(unmanaged.boolObj[0], @YES);
    XCTAssertEqualObjects(unmanaged.intObj[0], @3);
    XCTAssertEqualObjects(unmanaged.floatObj[0], @3.3f);
    XCTAssertEqualObjects(unmanaged.doubleObj[0], @3.3);
    XCTAssertEqualObjects(unmanaged.stringObj[0], @"b");
    XCTAssertEqualObjects(unmanaged.dataObj[0], data(2));
    XCTAssertEqualObjects(unmanaged.dateObj[0], date(2));
    XCTAssertEqualObjects(unmanaged.decimalObj[0], decimal128(3));
    XCTAssertEqualObjects(unmanaged.objectIdObj[0], objectId(2));
    XCTAssertEqualObjects(unmanaged.uuidObj[0], uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"));
    XCTAssertEqualObjects(unmanaged.anyBoolObj[0], @YES);
    XCTAssertEqualObjects(unmanaged.anyIntObj[0], @3);
    XCTAssertEqualObjects(unmanaged.anyFloatObj[0], @3.3f);
    XCTAssertEqualObjects(unmanaged.anyDoubleObj[0], @3.3);
    XCTAssertEqualObjects(unmanaged.anyStringObj[0], @"b");
    XCTAssertEqualObjects(unmanaged.anyDataObj[0], data(2));
    XCTAssertEqualObjects(unmanaged.anyDateObj[0], date(2));
    XCTAssertEqualObjects(unmanaged.anyDecimalObj[0], decimal128(3));
    XCTAssertEqualObjects(unmanaged.anyObjectIdObj[0], objectId(2));
    XCTAssertEqualObjects(unmanaged.anyUUIDObj[0], uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"));
    XCTAssertEqualObjects(optUnmanaged.boolObj[0], @YES);
    XCTAssertEqualObjects(optUnmanaged.intObj[0], @3);
    XCTAssertEqualObjects(optUnmanaged.floatObj[0], @3.3f);
    XCTAssertEqualObjects(optUnmanaged.doubleObj[0], @3.3);
    XCTAssertEqualObjects(optUnmanaged.stringObj[0], @"b");
    XCTAssertEqualObjects(optUnmanaged.dataObj[0], data(2));
    XCTAssertEqualObjects(optUnmanaged.dateObj[0], date(2));
    XCTAssertEqualObjects(optUnmanaged.decimalObj[0], decimal128(3));
    XCTAssertEqualObjects(optUnmanaged.objectIdObj[0], objectId(2));
    XCTAssertEqualObjects(optUnmanaged.uuidObj[0], uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"));
    XCTAssertEqualObjects(managed.boolObj[0], @YES);
    XCTAssertEqualObjects(managed.intObj[0], @3);
    XCTAssertEqualObjects(managed.floatObj[0], @3.3f);
    XCTAssertEqualObjects(managed.doubleObj[0], @3.3);
    XCTAssertEqualObjects(managed.stringObj[0], @"b");
    XCTAssertEqualObjects(managed.dataObj[0], data(2));
    XCTAssertEqualObjects(managed.dateObj[0], date(2));
    XCTAssertEqualObjects(managed.decimalObj[0], decimal128(3));
    XCTAssertEqualObjects(managed.objectIdObj[0], objectId(2));
    XCTAssertEqualObjects(managed.uuidObj[0], uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"));
    XCTAssertEqualObjects(managed.anyBoolObj[0], @YES);
    XCTAssertEqualObjects(managed.anyIntObj[0], @3);
    XCTAssertEqualObjects(managed.anyFloatObj[0], @3.3f);
    XCTAssertEqualObjects(managed.anyDoubleObj[0], @3.3);
    XCTAssertEqualObjects(managed.anyStringObj[0], @"b");
    XCTAssertEqualObjects(managed.anyDataObj[0], data(2));
    XCTAssertEqualObjects(managed.anyDateObj[0], date(2));
    XCTAssertEqualObjects(managed.anyDecimalObj[0], decimal128(3));
    XCTAssertEqualObjects(managed.anyObjectIdObj[0], objectId(2));
    XCTAssertEqualObjects(managed.anyUUIDObj[0], uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"));
    XCTAssertEqualObjects(optManaged.boolObj[0], @YES);
    XCTAssertEqualObjects(optManaged.intObj[0], @3);
    XCTAssertEqualObjects(optManaged.floatObj[0], @3.3f);
    XCTAssertEqualObjects(optManaged.doubleObj[0], @3.3);
    XCTAssertEqualObjects(optManaged.stringObj[0], @"b");
    XCTAssertEqualObjects(optManaged.dataObj[0], data(2));
    XCTAssertEqualObjects(optManaged.dateObj[0], date(2));
    XCTAssertEqualObjects(optManaged.decimalObj[0], decimal128(3));
    XCTAssertEqualObjects(optManaged.objectIdObj[0], objectId(2));
    XCTAssertEqualObjects(optManaged.uuidObj[0], uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"));
    XCTAssertEqualObjects(optUnmanaged.boolObj[1], NSNull.null);
    XCTAssertEqualObjects(optUnmanaged.intObj[1], NSNull.null);
    XCTAssertEqualObjects(optUnmanaged.floatObj[1], NSNull.null);
    XCTAssertEqualObjects(optUnmanaged.doubleObj[1], NSNull.null);
    XCTAssertEqualObjects(optUnmanaged.stringObj[1], NSNull.null);
    XCTAssertEqualObjects(optUnmanaged.dataObj[1], NSNull.null);
    XCTAssertEqualObjects(optUnmanaged.dateObj[1], NSNull.null);
    XCTAssertEqualObjects(optUnmanaged.decimalObj[1], NSNull.null);
    XCTAssertEqualObjects(optUnmanaged.objectIdObj[1], NSNull.null);
    XCTAssertEqualObjects(optUnmanaged.uuidObj[1], NSNull.null);
    XCTAssertEqualObjects(optManaged.boolObj[1], NSNull.null);
    XCTAssertEqualObjects(optManaged.intObj[1], NSNull.null);
    XCTAssertEqualObjects(optManaged.floatObj[1], NSNull.null);
    XCTAssertEqualObjects(optManaged.doubleObj[1], NSNull.null);
    XCTAssertEqualObjects(optManaged.stringObj[1], NSNull.null);
    XCTAssertEqualObjects(optManaged.dataObj[1], NSNull.null);
    XCTAssertEqualObjects(optManaged.dateObj[1], NSNull.null);
    XCTAssertEqualObjects(optManaged.decimalObj[1], NSNull.null);
    XCTAssertEqualObjects(optManaged.objectIdObj[1], NSNull.null);
    XCTAssertEqualObjects(optManaged.uuidObj[1], NSNull.null);
}

- (void)testRemoveLastObject {
    for (RLMArray *array in allArrays) {
        XCTAssertNoThrow([array removeLastObject]);
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

    for (RLMArray *array in allArrays) {
        [array removeLastObject];
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

    XCTAssertEqualObjects(unmanaged.boolObj[0], @NO);
    XCTAssertEqualObjects(unmanaged.intObj[0], @2);
    XCTAssertEqualObjects(unmanaged.floatObj[0], @2.2f);
    XCTAssertEqualObjects(unmanaged.doubleObj[0], @2.2);
    XCTAssertEqualObjects(unmanaged.stringObj[0], @"a");
    XCTAssertEqualObjects(unmanaged.dataObj[0], data(1));
    XCTAssertEqualObjects(unmanaged.dateObj[0], date(1));
    XCTAssertEqualObjects(unmanaged.decimalObj[0], decimal128(2));
    XCTAssertEqualObjects(unmanaged.objectIdObj[0], objectId(1));
    XCTAssertEqualObjects(unmanaged.uuidObj[0], uuid(@"00000000-0000-0000-0000-000000000000"));
    XCTAssertEqualObjects(unmanaged.anyBoolObj[0], @NO);
    XCTAssertEqualObjects(unmanaged.anyIntObj[0], @2);
    XCTAssertEqualObjects(unmanaged.anyFloatObj[0], @2.2f);
    XCTAssertEqualObjects(unmanaged.anyDoubleObj[0], @2.2);
    XCTAssertEqualObjects(unmanaged.anyStringObj[0], @"a");
    XCTAssertEqualObjects(unmanaged.anyDataObj[0], data(1));
    XCTAssertEqualObjects(unmanaged.anyDateObj[0], date(1));
    XCTAssertEqualObjects(unmanaged.anyDecimalObj[0], decimal128(2));
    XCTAssertEqualObjects(unmanaged.anyObjectIdObj[0], objectId(1));
    XCTAssertEqualObjects(unmanaged.anyUUIDObj[0], uuid(@"00000000-0000-0000-0000-000000000000"));
    XCTAssertEqualObjects(optUnmanaged.boolObj[0], @NO);
    XCTAssertEqualObjects(optUnmanaged.intObj[0], @2);
    XCTAssertEqualObjects(optUnmanaged.floatObj[0], @2.2f);
    XCTAssertEqualObjects(optUnmanaged.doubleObj[0], @2.2);
    XCTAssertEqualObjects(optUnmanaged.stringObj[0], @"a");
    XCTAssertEqualObjects(optUnmanaged.dataObj[0], data(1));
    XCTAssertEqualObjects(optUnmanaged.dateObj[0], date(1));
    XCTAssertEqualObjects(optUnmanaged.decimalObj[0], decimal128(2));
    XCTAssertEqualObjects(optUnmanaged.objectIdObj[0], objectId(1));
    XCTAssertEqualObjects(optUnmanaged.uuidObj[0], uuid(@"00000000-0000-0000-0000-000000000000"));
    XCTAssertEqualObjects(managed.boolObj[0], @NO);
    XCTAssertEqualObjects(managed.intObj[0], @2);
    XCTAssertEqualObjects(managed.floatObj[0], @2.2f);
    XCTAssertEqualObjects(managed.doubleObj[0], @2.2);
    XCTAssertEqualObjects(managed.stringObj[0], @"a");
    XCTAssertEqualObjects(managed.dataObj[0], data(1));
    XCTAssertEqualObjects(managed.dateObj[0], date(1));
    XCTAssertEqualObjects(managed.decimalObj[0], decimal128(2));
    XCTAssertEqualObjects(managed.objectIdObj[0], objectId(1));
    XCTAssertEqualObjects(managed.uuidObj[0], uuid(@"00000000-0000-0000-0000-000000000000"));
    XCTAssertEqualObjects(managed.anyBoolObj[0], @NO);
    XCTAssertEqualObjects(managed.anyIntObj[0], @2);
    XCTAssertEqualObjects(managed.anyFloatObj[0], @2.2f);
    XCTAssertEqualObjects(managed.anyDoubleObj[0], @2.2);
    XCTAssertEqualObjects(managed.anyStringObj[0], @"a");
    XCTAssertEqualObjects(managed.anyDataObj[0], data(1));
    XCTAssertEqualObjects(managed.anyDateObj[0], date(1));
    XCTAssertEqualObjects(managed.anyDecimalObj[0], decimal128(2));
    XCTAssertEqualObjects(managed.anyObjectIdObj[0], objectId(1));
    XCTAssertEqualObjects(managed.anyUUIDObj[0], uuid(@"00000000-0000-0000-0000-000000000000"));
    XCTAssertEqualObjects(optManaged.boolObj[0], @NO);
    XCTAssertEqualObjects(optManaged.intObj[0], @2);
    XCTAssertEqualObjects(optManaged.floatObj[0], @2.2f);
    XCTAssertEqualObjects(optManaged.doubleObj[0], @2.2);
    XCTAssertEqualObjects(optManaged.stringObj[0], @"a");
    XCTAssertEqualObjects(optManaged.dataObj[0], data(1));
    XCTAssertEqualObjects(optManaged.dateObj[0], date(1));
    XCTAssertEqualObjects(optManaged.decimalObj[0], decimal128(2));
    XCTAssertEqualObjects(optManaged.objectIdObj[0], objectId(1));
    XCTAssertEqualObjects(optManaged.uuidObj[0], uuid(@"00000000-0000-0000-0000-000000000000"));
    XCTAssertEqualObjects(optUnmanaged.boolObj[1], @YES);
    XCTAssertEqualObjects(optUnmanaged.intObj[1], @3);
    XCTAssertEqualObjects(optUnmanaged.floatObj[1], @3.3f);
    XCTAssertEqualObjects(optUnmanaged.doubleObj[1], @3.3);
    XCTAssertEqualObjects(optUnmanaged.stringObj[1], @"b");
    XCTAssertEqualObjects(optUnmanaged.dataObj[1], data(2));
    XCTAssertEqualObjects(optUnmanaged.dateObj[1], date(2));
    XCTAssertEqualObjects(optUnmanaged.decimalObj[1], decimal128(3));
    XCTAssertEqualObjects(optUnmanaged.objectIdObj[1], objectId(2));
    XCTAssertEqualObjects(optUnmanaged.uuidObj[1], uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"));
    XCTAssertEqualObjects(optManaged.boolObj[1], @YES);
    XCTAssertEqualObjects(optManaged.intObj[1], @3);
    XCTAssertEqualObjects(optManaged.floatObj[1], @3.3f);
    XCTAssertEqualObjects(optManaged.doubleObj[1], @3.3);
    XCTAssertEqualObjects(optManaged.stringObj[1], @"b");
    XCTAssertEqualObjects(optManaged.dataObj[1], data(2));
    XCTAssertEqualObjects(optManaged.dateObj[1], date(2));
    XCTAssertEqualObjects(optManaged.decimalObj[1], decimal128(3));
    XCTAssertEqualObjects(optManaged.objectIdObj[1], objectId(2));
    XCTAssertEqualObjects(optManaged.uuidObj[1], uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"));
}

- (void)testReplace {
    RLMAssertThrowsWithReason([unmanaged.boolObj replaceObjectAtIndex:0 withObject:@NO],
                              @"Index 0 is out of bounds (must be less than 0).");
    RLMAssertThrowsWithReason([unmanaged.intObj replaceObjectAtIndex:0 withObject:@2],
                              @"Index 0 is out of bounds (must be less than 0).");
    RLMAssertThrowsWithReason([unmanaged.floatObj replaceObjectAtIndex:0 withObject:@2.2f],
                              @"Index 0 is out of bounds (must be less than 0).");
    RLMAssertThrowsWithReason([unmanaged.doubleObj replaceObjectAtIndex:0 withObject:@2.2],
                              @"Index 0 is out of bounds (must be less than 0).");
    RLMAssertThrowsWithReason([unmanaged.stringObj replaceObjectAtIndex:0 withObject:@"a"],
                              @"Index 0 is out of bounds (must be less than 0).");
    RLMAssertThrowsWithReason([unmanaged.dataObj replaceObjectAtIndex:0 withObject:data(1)],
                              @"Index 0 is out of bounds (must be less than 0).");
    RLMAssertThrowsWithReason([unmanaged.dateObj replaceObjectAtIndex:0 withObject:date(1)],
                              @"Index 0 is out of bounds (must be less than 0).");
    RLMAssertThrowsWithReason([unmanaged.decimalObj replaceObjectAtIndex:0 withObject:decimal128(2)],
                              @"Index 0 is out of bounds (must be less than 0).");
    RLMAssertThrowsWithReason([unmanaged.objectIdObj replaceObjectAtIndex:0 withObject:objectId(1)],
                              @"Index 0 is out of bounds (must be less than 0).");
    RLMAssertThrowsWithReason([unmanaged.uuidObj replaceObjectAtIndex:0 withObject:uuid(@"00000000-0000-0000-0000-000000000000")],
                              @"Index 0 is out of bounds (must be less than 0).");
    RLMAssertThrowsWithReason([unmanaged.anyBoolObj replaceObjectAtIndex:0 withObject:@NO],
                              @"Index 0 is out of bounds (must be less than 0).");
    RLMAssertThrowsWithReason([unmanaged.anyIntObj replaceObjectAtIndex:0 withObject:@2],
                              @"Index 0 is out of bounds (must be less than 0).");
    RLMAssertThrowsWithReason([unmanaged.anyFloatObj replaceObjectAtIndex:0 withObject:@2.2f],
                              @"Index 0 is out of bounds (must be less than 0).");
    RLMAssertThrowsWithReason([unmanaged.anyDoubleObj replaceObjectAtIndex:0 withObject:@2.2],
                              @"Index 0 is out of bounds (must be less than 0).");
    RLMAssertThrowsWithReason([unmanaged.anyStringObj replaceObjectAtIndex:0 withObject:@"a"],
                              @"Index 0 is out of bounds (must be less than 0).");
    RLMAssertThrowsWithReason([unmanaged.anyDataObj replaceObjectAtIndex:0 withObject:data(1)],
                              @"Index 0 is out of bounds (must be less than 0).");
    RLMAssertThrowsWithReason([unmanaged.anyDateObj replaceObjectAtIndex:0 withObject:date(1)],
                              @"Index 0 is out of bounds (must be less than 0).");
    RLMAssertThrowsWithReason([unmanaged.anyDecimalObj replaceObjectAtIndex:0 withObject:decimal128(2)],
                              @"Index 0 is out of bounds (must be less than 0).");
    RLMAssertThrowsWithReason([unmanaged.anyObjectIdObj replaceObjectAtIndex:0 withObject:objectId(1)],
                              @"Index 0 is out of bounds (must be less than 0).");
    RLMAssertThrowsWithReason([unmanaged.anyUUIDObj replaceObjectAtIndex:0 withObject:uuid(@"00000000-0000-0000-0000-000000000000")],
                              @"Index 0 is out of bounds (must be less than 0).");
    RLMAssertThrowsWithReason([optUnmanaged.boolObj replaceObjectAtIndex:0 withObject:@NO],
                              @"Index 0 is out of bounds (must be less than 0).");
    RLMAssertThrowsWithReason([optUnmanaged.intObj replaceObjectAtIndex:0 withObject:@2],
                              @"Index 0 is out of bounds (must be less than 0).");
    RLMAssertThrowsWithReason([optUnmanaged.floatObj replaceObjectAtIndex:0 withObject:@2.2f],
                              @"Index 0 is out of bounds (must be less than 0).");
    RLMAssertThrowsWithReason([optUnmanaged.doubleObj replaceObjectAtIndex:0 withObject:@2.2],
                              @"Index 0 is out of bounds (must be less than 0).");
    RLMAssertThrowsWithReason([optUnmanaged.stringObj replaceObjectAtIndex:0 withObject:@"a"],
                              @"Index 0 is out of bounds (must be less than 0).");
    RLMAssertThrowsWithReason([optUnmanaged.dataObj replaceObjectAtIndex:0 withObject:data(1)],
                              @"Index 0 is out of bounds (must be less than 0).");
    RLMAssertThrowsWithReason([optUnmanaged.dateObj replaceObjectAtIndex:0 withObject:date(1)],
                              @"Index 0 is out of bounds (must be less than 0).");
    RLMAssertThrowsWithReason([optUnmanaged.decimalObj replaceObjectAtIndex:0 withObject:decimal128(2)],
                              @"Index 0 is out of bounds (must be less than 0).");
    RLMAssertThrowsWithReason([optUnmanaged.objectIdObj replaceObjectAtIndex:0 withObject:objectId(1)],
                              @"Index 0 is out of bounds (must be less than 0).");
    RLMAssertThrowsWithReason([optUnmanaged.uuidObj replaceObjectAtIndex:0 withObject:uuid(@"00000000-0000-0000-0000-000000000000")],
                              @"Index 0 is out of bounds (must be less than 0).");
    RLMAssertThrowsWithReason([managed.boolObj replaceObjectAtIndex:0 withObject:@NO],
                              @"Index 0 is out of bounds (must be less than 0).");
    RLMAssertThrowsWithReason([managed.intObj replaceObjectAtIndex:0 withObject:@2],
                              @"Index 0 is out of bounds (must be less than 0).");
    RLMAssertThrowsWithReason([managed.floatObj replaceObjectAtIndex:0 withObject:@2.2f],
                              @"Index 0 is out of bounds (must be less than 0).");
    RLMAssertThrowsWithReason([managed.doubleObj replaceObjectAtIndex:0 withObject:@2.2],
                              @"Index 0 is out of bounds (must be less than 0).");
    RLMAssertThrowsWithReason([managed.stringObj replaceObjectAtIndex:0 withObject:@"a"],
                              @"Index 0 is out of bounds (must be less than 0).");
    RLMAssertThrowsWithReason([managed.dataObj replaceObjectAtIndex:0 withObject:data(1)],
                              @"Index 0 is out of bounds (must be less than 0).");
    RLMAssertThrowsWithReason([managed.dateObj replaceObjectAtIndex:0 withObject:date(1)],
                              @"Index 0 is out of bounds (must be less than 0).");
    RLMAssertThrowsWithReason([managed.decimalObj replaceObjectAtIndex:0 withObject:decimal128(2)],
                              @"Index 0 is out of bounds (must be less than 0).");
    RLMAssertThrowsWithReason([managed.objectIdObj replaceObjectAtIndex:0 withObject:objectId(1)],
                              @"Index 0 is out of bounds (must be less than 0).");
    RLMAssertThrowsWithReason([managed.uuidObj replaceObjectAtIndex:0 withObject:uuid(@"00000000-0000-0000-0000-000000000000")],
                              @"Index 0 is out of bounds (must be less than 0).");
    RLMAssertThrowsWithReason([managed.anyBoolObj replaceObjectAtIndex:0 withObject:@NO],
                              @"Index 0 is out of bounds (must be less than 0).");
    RLMAssertThrowsWithReason([managed.anyIntObj replaceObjectAtIndex:0 withObject:@2],
                              @"Index 0 is out of bounds (must be less than 0).");
    RLMAssertThrowsWithReason([managed.anyFloatObj replaceObjectAtIndex:0 withObject:@2.2f],
                              @"Index 0 is out of bounds (must be less than 0).");
    RLMAssertThrowsWithReason([managed.anyDoubleObj replaceObjectAtIndex:0 withObject:@2.2],
                              @"Index 0 is out of bounds (must be less than 0).");
    RLMAssertThrowsWithReason([managed.anyStringObj replaceObjectAtIndex:0 withObject:@"a"],
                              @"Index 0 is out of bounds (must be less than 0).");
    RLMAssertThrowsWithReason([managed.anyDataObj replaceObjectAtIndex:0 withObject:data(1)],
                              @"Index 0 is out of bounds (must be less than 0).");
    RLMAssertThrowsWithReason([managed.anyDateObj replaceObjectAtIndex:0 withObject:date(1)],
                              @"Index 0 is out of bounds (must be less than 0).");
    RLMAssertThrowsWithReason([managed.anyDecimalObj replaceObjectAtIndex:0 withObject:decimal128(2)],
                              @"Index 0 is out of bounds (must be less than 0).");
    RLMAssertThrowsWithReason([managed.anyObjectIdObj replaceObjectAtIndex:0 withObject:objectId(1)],
                              @"Index 0 is out of bounds (must be less than 0).");
    RLMAssertThrowsWithReason([managed.anyUUIDObj replaceObjectAtIndex:0 withObject:uuid(@"00000000-0000-0000-0000-000000000000")],
                              @"Index 0 is out of bounds (must be less than 0).");
    RLMAssertThrowsWithReason([optManaged.boolObj replaceObjectAtIndex:0 withObject:@NO],
                              @"Index 0 is out of bounds (must be less than 0).");
    RLMAssertThrowsWithReason([optManaged.intObj replaceObjectAtIndex:0 withObject:@2],
                              @"Index 0 is out of bounds (must be less than 0).");
    RLMAssertThrowsWithReason([optManaged.floatObj replaceObjectAtIndex:0 withObject:@2.2f],
                              @"Index 0 is out of bounds (must be less than 0).");
    RLMAssertThrowsWithReason([optManaged.doubleObj replaceObjectAtIndex:0 withObject:@2.2],
                              @"Index 0 is out of bounds (must be less than 0).");
    RLMAssertThrowsWithReason([optManaged.stringObj replaceObjectAtIndex:0 withObject:@"a"],
                              @"Index 0 is out of bounds (must be less than 0).");
    RLMAssertThrowsWithReason([optManaged.dataObj replaceObjectAtIndex:0 withObject:data(1)],
                              @"Index 0 is out of bounds (must be less than 0).");
    RLMAssertThrowsWithReason([optManaged.dateObj replaceObjectAtIndex:0 withObject:date(1)],
                              @"Index 0 is out of bounds (must be less than 0).");
    RLMAssertThrowsWithReason([optManaged.decimalObj replaceObjectAtIndex:0 withObject:decimal128(2)],
                              @"Index 0 is out of bounds (must be less than 0).");
    RLMAssertThrowsWithReason([optManaged.objectIdObj replaceObjectAtIndex:0 withObject:objectId(1)],
                              @"Index 0 is out of bounds (must be less than 0).");
    RLMAssertThrowsWithReason([optManaged.uuidObj replaceObjectAtIndex:0 withObject:uuid(@"00000000-0000-0000-0000-000000000000")],
                              @"Index 0 is out of bounds (must be less than 0).");

    [unmanaged.boolObj addObject:@NO];
    [unmanaged.boolObj replaceObjectAtIndex:0 withObject:@YES];
    XCTAssertEqualObjects(unmanaged.boolObj[0], @YES);
    
    [unmanaged.intObj addObject:@2];
    [unmanaged.intObj replaceObjectAtIndex:0 withObject:@3];
    XCTAssertEqualObjects(unmanaged.intObj[0], @3);
    
    [unmanaged.floatObj addObject:@2.2f];
    [unmanaged.floatObj replaceObjectAtIndex:0 withObject:@3.3f];
    XCTAssertEqualObjects(unmanaged.floatObj[0], @3.3f);
    
    [unmanaged.doubleObj addObject:@2.2];
    [unmanaged.doubleObj replaceObjectAtIndex:0 withObject:@3.3];
    XCTAssertEqualObjects(unmanaged.doubleObj[0], @3.3);
    
    [unmanaged.stringObj addObject:@"a"];
    [unmanaged.stringObj replaceObjectAtIndex:0 withObject:@"b"];
    XCTAssertEqualObjects(unmanaged.stringObj[0], @"b");
    
    [unmanaged.dataObj addObject:data(1)];
    [unmanaged.dataObj replaceObjectAtIndex:0 withObject:data(2)];
    XCTAssertEqualObjects(unmanaged.dataObj[0], data(2));
    
    [unmanaged.dateObj addObject:date(1)];
    [unmanaged.dateObj replaceObjectAtIndex:0 withObject:date(2)];
    XCTAssertEqualObjects(unmanaged.dateObj[0], date(2));
    
    [unmanaged.decimalObj addObject:decimal128(2)];
    [unmanaged.decimalObj replaceObjectAtIndex:0 withObject:decimal128(3)];
    XCTAssertEqualObjects(unmanaged.decimalObj[0], decimal128(3));
    
    [unmanaged.objectIdObj addObject:objectId(1)];
    [unmanaged.objectIdObj replaceObjectAtIndex:0 withObject:objectId(2)];
    XCTAssertEqualObjects(unmanaged.objectIdObj[0], objectId(2));
    
    [unmanaged.uuidObj addObject:uuid(@"00000000-0000-0000-0000-000000000000")];
    [unmanaged.uuidObj replaceObjectAtIndex:0 withObject:uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")];
    XCTAssertEqualObjects(unmanaged.uuidObj[0], uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"));
    
    [unmanaged.anyBoolObj addObject:@NO];
    [unmanaged.anyBoolObj replaceObjectAtIndex:0 withObject:@YES];
    XCTAssertEqualObjects(unmanaged.anyBoolObj[0], @YES);
    
    [unmanaged.anyIntObj addObject:@2];
    [unmanaged.anyIntObj replaceObjectAtIndex:0 withObject:@3];
    XCTAssertEqualObjects(unmanaged.anyIntObj[0], @3);
    
    [unmanaged.anyFloatObj addObject:@2.2f];
    [unmanaged.anyFloatObj replaceObjectAtIndex:0 withObject:@3.3f];
    XCTAssertEqualObjects(unmanaged.anyFloatObj[0], @3.3f);
    
    [unmanaged.anyDoubleObj addObject:@2.2];
    [unmanaged.anyDoubleObj replaceObjectAtIndex:0 withObject:@3.3];
    XCTAssertEqualObjects(unmanaged.anyDoubleObj[0], @3.3);
    
    [unmanaged.anyStringObj addObject:@"a"];
    [unmanaged.anyStringObj replaceObjectAtIndex:0 withObject:@"b"];
    XCTAssertEqualObjects(unmanaged.anyStringObj[0], @"b");
    
    [unmanaged.anyDataObj addObject:data(1)];
    [unmanaged.anyDataObj replaceObjectAtIndex:0 withObject:data(2)];
    XCTAssertEqualObjects(unmanaged.anyDataObj[0], data(2));
    
    [unmanaged.anyDateObj addObject:date(1)];
    [unmanaged.anyDateObj replaceObjectAtIndex:0 withObject:date(2)];
    XCTAssertEqualObjects(unmanaged.anyDateObj[0], date(2));
    
    [unmanaged.anyDecimalObj addObject:decimal128(2)];
    [unmanaged.anyDecimalObj replaceObjectAtIndex:0 withObject:decimal128(3)];
    XCTAssertEqualObjects(unmanaged.anyDecimalObj[0], decimal128(3));
    
    [unmanaged.anyObjectIdObj addObject:objectId(1)];
    [unmanaged.anyObjectIdObj replaceObjectAtIndex:0 withObject:objectId(2)];
    XCTAssertEqualObjects(unmanaged.anyObjectIdObj[0], objectId(2));
    
    [unmanaged.anyUUIDObj addObject:uuid(@"00000000-0000-0000-0000-000000000000")];
    [unmanaged.anyUUIDObj replaceObjectAtIndex:0 withObject:uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")];
    XCTAssertEqualObjects(unmanaged.anyUUIDObj[0], uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"));
    
    [optUnmanaged.boolObj addObject:@NO];
    [optUnmanaged.boolObj replaceObjectAtIndex:0 withObject:@YES];
    XCTAssertEqualObjects(optUnmanaged.boolObj[0], @YES);
    
    [optUnmanaged.intObj addObject:@2];
    [optUnmanaged.intObj replaceObjectAtIndex:0 withObject:@3];
    XCTAssertEqualObjects(optUnmanaged.intObj[0], @3);
    
    [optUnmanaged.floatObj addObject:@2.2f];
    [optUnmanaged.floatObj replaceObjectAtIndex:0 withObject:@3.3f];
    XCTAssertEqualObjects(optUnmanaged.floatObj[0], @3.3f);
    
    [optUnmanaged.doubleObj addObject:@2.2];
    [optUnmanaged.doubleObj replaceObjectAtIndex:0 withObject:@3.3];
    XCTAssertEqualObjects(optUnmanaged.doubleObj[0], @3.3);
    
    [optUnmanaged.stringObj addObject:@"a"];
    [optUnmanaged.stringObj replaceObjectAtIndex:0 withObject:@"b"];
    XCTAssertEqualObjects(optUnmanaged.stringObj[0], @"b");
    
    [optUnmanaged.dataObj addObject:data(1)];
    [optUnmanaged.dataObj replaceObjectAtIndex:0 withObject:data(2)];
    XCTAssertEqualObjects(optUnmanaged.dataObj[0], data(2));
    
    [optUnmanaged.dateObj addObject:date(1)];
    [optUnmanaged.dateObj replaceObjectAtIndex:0 withObject:date(2)];
    XCTAssertEqualObjects(optUnmanaged.dateObj[0], date(2));
    
    [optUnmanaged.decimalObj addObject:decimal128(2)];
    [optUnmanaged.decimalObj replaceObjectAtIndex:0 withObject:decimal128(3)];
    XCTAssertEqualObjects(optUnmanaged.decimalObj[0], decimal128(3));
    
    [optUnmanaged.objectIdObj addObject:objectId(1)];
    [optUnmanaged.objectIdObj replaceObjectAtIndex:0 withObject:objectId(2)];
    XCTAssertEqualObjects(optUnmanaged.objectIdObj[0], objectId(2));
    
    [optUnmanaged.uuidObj addObject:uuid(@"00000000-0000-0000-0000-000000000000")];
    [optUnmanaged.uuidObj replaceObjectAtIndex:0 withObject:uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")];
    XCTAssertEqualObjects(optUnmanaged.uuidObj[0], uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"));
    
    [managed.boolObj addObject:@NO];
    [managed.boolObj replaceObjectAtIndex:0 withObject:@YES];
    XCTAssertEqualObjects(managed.boolObj[0], @YES);
    
    [managed.intObj addObject:@2];
    [managed.intObj replaceObjectAtIndex:0 withObject:@3];
    XCTAssertEqualObjects(managed.intObj[0], @3);
    
    [managed.floatObj addObject:@2.2f];
    [managed.floatObj replaceObjectAtIndex:0 withObject:@3.3f];
    XCTAssertEqualObjects(managed.floatObj[0], @3.3f);
    
    [managed.doubleObj addObject:@2.2];
    [managed.doubleObj replaceObjectAtIndex:0 withObject:@3.3];
    XCTAssertEqualObjects(managed.doubleObj[0], @3.3);
    
    [managed.stringObj addObject:@"a"];
    [managed.stringObj replaceObjectAtIndex:0 withObject:@"b"];
    XCTAssertEqualObjects(managed.stringObj[0], @"b");
    
    [managed.dataObj addObject:data(1)];
    [managed.dataObj replaceObjectAtIndex:0 withObject:data(2)];
    XCTAssertEqualObjects(managed.dataObj[0], data(2));
    
    [managed.dateObj addObject:date(1)];
    [managed.dateObj replaceObjectAtIndex:0 withObject:date(2)];
    XCTAssertEqualObjects(managed.dateObj[0], date(2));
    
    [managed.decimalObj addObject:decimal128(2)];
    [managed.decimalObj replaceObjectAtIndex:0 withObject:decimal128(3)];
    XCTAssertEqualObjects(managed.decimalObj[0], decimal128(3));
    
    [managed.objectIdObj addObject:objectId(1)];
    [managed.objectIdObj replaceObjectAtIndex:0 withObject:objectId(2)];
    XCTAssertEqualObjects(managed.objectIdObj[0], objectId(2));
    
    [managed.uuidObj addObject:uuid(@"00000000-0000-0000-0000-000000000000")];
    [managed.uuidObj replaceObjectAtIndex:0 withObject:uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")];
    XCTAssertEqualObjects(managed.uuidObj[0], uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"));
    
    [managed.anyBoolObj addObject:@NO];
    [managed.anyBoolObj replaceObjectAtIndex:0 withObject:@YES];
    XCTAssertEqualObjects(managed.anyBoolObj[0], @YES);
    
    [managed.anyIntObj addObject:@2];
    [managed.anyIntObj replaceObjectAtIndex:0 withObject:@3];
    XCTAssertEqualObjects(managed.anyIntObj[0], @3);
    
    [managed.anyFloatObj addObject:@2.2f];
    [managed.anyFloatObj replaceObjectAtIndex:0 withObject:@3.3f];
    XCTAssertEqualObjects(managed.anyFloatObj[0], @3.3f);
    
    [managed.anyDoubleObj addObject:@2.2];
    [managed.anyDoubleObj replaceObjectAtIndex:0 withObject:@3.3];
    XCTAssertEqualObjects(managed.anyDoubleObj[0], @3.3);
    
    [managed.anyStringObj addObject:@"a"];
    [managed.anyStringObj replaceObjectAtIndex:0 withObject:@"b"];
    XCTAssertEqualObjects(managed.anyStringObj[0], @"b");
    
    [managed.anyDataObj addObject:data(1)];
    [managed.anyDataObj replaceObjectAtIndex:0 withObject:data(2)];
    XCTAssertEqualObjects(managed.anyDataObj[0], data(2));
    
    [managed.anyDateObj addObject:date(1)];
    [managed.anyDateObj replaceObjectAtIndex:0 withObject:date(2)];
    XCTAssertEqualObjects(managed.anyDateObj[0], date(2));
    
    [managed.anyDecimalObj addObject:decimal128(2)];
    [managed.anyDecimalObj replaceObjectAtIndex:0 withObject:decimal128(3)];
    XCTAssertEqualObjects(managed.anyDecimalObj[0], decimal128(3));
    
    [managed.anyObjectIdObj addObject:objectId(1)];
    [managed.anyObjectIdObj replaceObjectAtIndex:0 withObject:objectId(2)];
    XCTAssertEqualObjects(managed.anyObjectIdObj[0], objectId(2));
    
    [managed.anyUUIDObj addObject:uuid(@"00000000-0000-0000-0000-000000000000")];
    [managed.anyUUIDObj replaceObjectAtIndex:0 withObject:uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")];
    XCTAssertEqualObjects(managed.anyUUIDObj[0], uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"));
    
    [optManaged.boolObj addObject:@NO];
    [optManaged.boolObj replaceObjectAtIndex:0 withObject:@YES];
    XCTAssertEqualObjects(optManaged.boolObj[0], @YES);
    
    [optManaged.intObj addObject:@2];
    [optManaged.intObj replaceObjectAtIndex:0 withObject:@3];
    XCTAssertEqualObjects(optManaged.intObj[0], @3);
    
    [optManaged.floatObj addObject:@2.2f];
    [optManaged.floatObj replaceObjectAtIndex:0 withObject:@3.3f];
    XCTAssertEqualObjects(optManaged.floatObj[0], @3.3f);
    
    [optManaged.doubleObj addObject:@2.2];
    [optManaged.doubleObj replaceObjectAtIndex:0 withObject:@3.3];
    XCTAssertEqualObjects(optManaged.doubleObj[0], @3.3);
    
    [optManaged.stringObj addObject:@"a"];
    [optManaged.stringObj replaceObjectAtIndex:0 withObject:@"b"];
    XCTAssertEqualObjects(optManaged.stringObj[0], @"b");
    
    [optManaged.dataObj addObject:data(1)];
    [optManaged.dataObj replaceObjectAtIndex:0 withObject:data(2)];
    XCTAssertEqualObjects(optManaged.dataObj[0], data(2));
    
    [optManaged.dateObj addObject:date(1)];
    [optManaged.dateObj replaceObjectAtIndex:0 withObject:date(2)];
    XCTAssertEqualObjects(optManaged.dateObj[0], date(2));
    
    [optManaged.decimalObj addObject:decimal128(2)];
    [optManaged.decimalObj replaceObjectAtIndex:0 withObject:decimal128(3)];
    XCTAssertEqualObjects(optManaged.decimalObj[0], decimal128(3));
    
    [optManaged.objectIdObj addObject:objectId(1)];
    [optManaged.objectIdObj replaceObjectAtIndex:0 withObject:objectId(2)];
    XCTAssertEqualObjects(optManaged.objectIdObj[0], objectId(2));
    
    [optManaged.uuidObj addObject:uuid(@"00000000-0000-0000-0000-000000000000")];
    [optManaged.uuidObj replaceObjectAtIndex:0 withObject:uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")];
    XCTAssertEqualObjects(optManaged.uuidObj[0], uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"));
    

    [optUnmanaged.boolObj replaceObjectAtIndex:0 withObject:NSNull.null];
    XCTAssertEqualObjects(optUnmanaged.boolObj[0], NSNull.null);
    [optUnmanaged.intObj replaceObjectAtIndex:0 withObject:NSNull.null];
    XCTAssertEqualObjects(optUnmanaged.intObj[0], NSNull.null);
    [optUnmanaged.floatObj replaceObjectAtIndex:0 withObject:NSNull.null];
    XCTAssertEqualObjects(optUnmanaged.floatObj[0], NSNull.null);
    [optUnmanaged.doubleObj replaceObjectAtIndex:0 withObject:NSNull.null];
    XCTAssertEqualObjects(optUnmanaged.doubleObj[0], NSNull.null);
    [optUnmanaged.stringObj replaceObjectAtIndex:0 withObject:NSNull.null];
    XCTAssertEqualObjects(optUnmanaged.stringObj[0], NSNull.null);
    [optUnmanaged.dataObj replaceObjectAtIndex:0 withObject:NSNull.null];
    XCTAssertEqualObjects(optUnmanaged.dataObj[0], NSNull.null);
    [optUnmanaged.dateObj replaceObjectAtIndex:0 withObject:NSNull.null];
    XCTAssertEqualObjects(optUnmanaged.dateObj[0], NSNull.null);
    [optUnmanaged.decimalObj replaceObjectAtIndex:0 withObject:NSNull.null];
    XCTAssertEqualObjects(optUnmanaged.decimalObj[0], NSNull.null);
    [optUnmanaged.objectIdObj replaceObjectAtIndex:0 withObject:NSNull.null];
    XCTAssertEqualObjects(optUnmanaged.objectIdObj[0], NSNull.null);
    [optUnmanaged.uuidObj replaceObjectAtIndex:0 withObject:NSNull.null];
    XCTAssertEqualObjects(optUnmanaged.uuidObj[0], NSNull.null);
    [optManaged.boolObj replaceObjectAtIndex:0 withObject:NSNull.null];
    XCTAssertEqualObjects(optManaged.boolObj[0], NSNull.null);
    [optManaged.intObj replaceObjectAtIndex:0 withObject:NSNull.null];
    XCTAssertEqualObjects(optManaged.intObj[0], NSNull.null);
    [optManaged.floatObj replaceObjectAtIndex:0 withObject:NSNull.null];
    XCTAssertEqualObjects(optManaged.floatObj[0], NSNull.null);
    [optManaged.doubleObj replaceObjectAtIndex:0 withObject:NSNull.null];
    XCTAssertEqualObjects(optManaged.doubleObj[0], NSNull.null);
    [optManaged.stringObj replaceObjectAtIndex:0 withObject:NSNull.null];
    XCTAssertEqualObjects(optManaged.stringObj[0], NSNull.null);
    [optManaged.dataObj replaceObjectAtIndex:0 withObject:NSNull.null];
    XCTAssertEqualObjects(optManaged.dataObj[0], NSNull.null);
    [optManaged.dateObj replaceObjectAtIndex:0 withObject:NSNull.null];
    XCTAssertEqualObjects(optManaged.dateObj[0], NSNull.null);
    [optManaged.decimalObj replaceObjectAtIndex:0 withObject:NSNull.null];
    XCTAssertEqualObjects(optManaged.decimalObj[0], NSNull.null);
    [optManaged.objectIdObj replaceObjectAtIndex:0 withObject:NSNull.null];
    XCTAssertEqualObjects(optManaged.objectIdObj[0], NSNull.null);
    [optManaged.uuidObj replaceObjectAtIndex:0 withObject:NSNull.null];
    XCTAssertEqualObjects(optManaged.uuidObj[0], NSNull.null);

    RLMAssertThrowsWithReason([unmanaged.boolObj replaceObjectAtIndex:0 withObject:@"a"],
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'bool'");
    RLMAssertThrowsWithReason([unmanaged.intObj replaceObjectAtIndex:0 withObject:@"a"],
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'int'");
    RLMAssertThrowsWithReason([unmanaged.floatObj replaceObjectAtIndex:0 withObject:@"a"],
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'float'");
    RLMAssertThrowsWithReason([unmanaged.doubleObj replaceObjectAtIndex:0 withObject:@"a"],
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'double'");
    RLMAssertThrowsWithReason([unmanaged.stringObj replaceObjectAtIndex:0 withObject:@2],
                              @"Invalid value '2' of type '__NSCFNumber' for expected type 'string'");
    RLMAssertThrowsWithReason([unmanaged.dataObj replaceObjectAtIndex:0 withObject:@"a"],
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'data'");
    RLMAssertThrowsWithReason([unmanaged.dateObj replaceObjectAtIndex:0 withObject:@"a"],
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'date'");
    RLMAssertThrowsWithReason([unmanaged.decimalObj replaceObjectAtIndex:0 withObject:@"a"],
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'decimal128'");
    RLMAssertThrowsWithReason([unmanaged.objectIdObj replaceObjectAtIndex:0 withObject:@"a"],
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'object id'");
    RLMAssertThrowsWithReason([unmanaged.uuidObj replaceObjectAtIndex:0 withObject:@"a"],
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'uuid'");
    RLMAssertThrowsWithReason([optUnmanaged.boolObj replaceObjectAtIndex:0 withObject:@"a"],
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'bool?'");
    RLMAssertThrowsWithReason([optUnmanaged.intObj replaceObjectAtIndex:0 withObject:@"a"],
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'int?'");
    RLMAssertThrowsWithReason([optUnmanaged.floatObj replaceObjectAtIndex:0 withObject:@"a"],
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'float?'");
    RLMAssertThrowsWithReason([optUnmanaged.doubleObj replaceObjectAtIndex:0 withObject:@"a"],
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'double?'");
    RLMAssertThrowsWithReason([optUnmanaged.stringObj replaceObjectAtIndex:0 withObject:@2],
                              @"Invalid value '2' of type '__NSCFNumber' for expected type 'string?'");
    RLMAssertThrowsWithReason([optUnmanaged.dataObj replaceObjectAtIndex:0 withObject:@"a"],
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'data?'");
    RLMAssertThrowsWithReason([optUnmanaged.dateObj replaceObjectAtIndex:0 withObject:@"a"],
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'date?'");
    RLMAssertThrowsWithReason([optUnmanaged.decimalObj replaceObjectAtIndex:0 withObject:@"a"],
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'decimal128?'");
    RLMAssertThrowsWithReason([optUnmanaged.objectIdObj replaceObjectAtIndex:0 withObject:@"a"],
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'object id?'");
    RLMAssertThrowsWithReason([optUnmanaged.uuidObj replaceObjectAtIndex:0 withObject:@"a"],
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'uuid?'");
    RLMAssertThrowsWithReason([managed.boolObj replaceObjectAtIndex:0 withObject:@"a"],
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'bool'");
    RLMAssertThrowsWithReason([managed.intObj replaceObjectAtIndex:0 withObject:@"a"],
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'int'");
    RLMAssertThrowsWithReason([managed.floatObj replaceObjectAtIndex:0 withObject:@"a"],
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'float'");
    RLMAssertThrowsWithReason([managed.doubleObj replaceObjectAtIndex:0 withObject:@"a"],
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'double'");
    RLMAssertThrowsWithReason([managed.stringObj replaceObjectAtIndex:0 withObject:@2],
                              @"Invalid value '2' of type '__NSCFNumber' for expected type 'string'");
    RLMAssertThrowsWithReason([managed.dataObj replaceObjectAtIndex:0 withObject:@"a"],
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'data'");
    RLMAssertThrowsWithReason([managed.dateObj replaceObjectAtIndex:0 withObject:@"a"],
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'date'");
    RLMAssertThrowsWithReason([managed.decimalObj replaceObjectAtIndex:0 withObject:@"a"],
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'decimal128'");
    RLMAssertThrowsWithReason([managed.objectIdObj replaceObjectAtIndex:0 withObject:@"a"],
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'object id'");
    RLMAssertThrowsWithReason([managed.uuidObj replaceObjectAtIndex:0 withObject:@"a"],
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'uuid'");
    RLMAssertThrowsWithReason([optManaged.boolObj replaceObjectAtIndex:0 withObject:@"a"],
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'bool?'");
    RLMAssertThrowsWithReason([optManaged.intObj replaceObjectAtIndex:0 withObject:@"a"],
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'int?'");
    RLMAssertThrowsWithReason([optManaged.floatObj replaceObjectAtIndex:0 withObject:@"a"],
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'float?'");
    RLMAssertThrowsWithReason([optManaged.doubleObj replaceObjectAtIndex:0 withObject:@"a"],
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'double?'");
    RLMAssertThrowsWithReason([optManaged.stringObj replaceObjectAtIndex:0 withObject:@2],
                              @"Invalid value '2' of type '__NSCFNumber' for expected type 'string?'");
    RLMAssertThrowsWithReason([optManaged.dataObj replaceObjectAtIndex:0 withObject:@"a"],
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'data?'");
    RLMAssertThrowsWithReason([optManaged.dateObj replaceObjectAtIndex:0 withObject:@"a"],
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'date?'");
    RLMAssertThrowsWithReason([optManaged.decimalObj replaceObjectAtIndex:0 withObject:@"a"],
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'decimal128?'");
    RLMAssertThrowsWithReason([optManaged.objectIdObj replaceObjectAtIndex:0 withObject:@"a"],
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'object id?'");
    RLMAssertThrowsWithReason([optManaged.uuidObj replaceObjectAtIndex:0 withObject:@"a"],
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'uuid?'");
    RLMAssertThrowsWithReason([unmanaged.boolObj replaceObjectAtIndex:0 withObject:NSNull.null],
                              @"Invalid value '<null>' of type 'NSNull' for expected type 'bool'");
    RLMAssertThrowsWithReason([unmanaged.intObj replaceObjectAtIndex:0 withObject:NSNull.null],
                              @"Invalid value '<null>' of type 'NSNull' for expected type 'int'");
    RLMAssertThrowsWithReason([unmanaged.floatObj replaceObjectAtIndex:0 withObject:NSNull.null],
                              @"Invalid value '<null>' of type 'NSNull' for expected type 'float'");
    RLMAssertThrowsWithReason([unmanaged.doubleObj replaceObjectAtIndex:0 withObject:NSNull.null],
                              @"Invalid value '<null>' of type 'NSNull' for expected type 'double'");
    RLMAssertThrowsWithReason([unmanaged.stringObj replaceObjectAtIndex:0 withObject:NSNull.null],
                              @"Invalid value '<null>' of type 'NSNull' for expected type 'string'");
    RLMAssertThrowsWithReason([unmanaged.dataObj replaceObjectAtIndex:0 withObject:NSNull.null],
                              @"Invalid value '<null>' of type 'NSNull' for expected type 'data'");
    RLMAssertThrowsWithReason([unmanaged.dateObj replaceObjectAtIndex:0 withObject:NSNull.null],
                              @"Invalid value '<null>' of type 'NSNull' for expected type 'date'");
    RLMAssertThrowsWithReason([unmanaged.decimalObj replaceObjectAtIndex:0 withObject:NSNull.null],
                              @"Invalid value '<null>' of type 'NSNull' for expected type 'decimal128'");
    RLMAssertThrowsWithReason([unmanaged.objectIdObj replaceObjectAtIndex:0 withObject:NSNull.null],
                              @"Invalid value '<null>' of type 'NSNull' for expected type 'object id'");
    RLMAssertThrowsWithReason([unmanaged.uuidObj replaceObjectAtIndex:0 withObject:NSNull.null],
                              @"Invalid value '<null>' of type 'NSNull' for expected type 'uuid'");
    RLMAssertThrowsWithReason([managed.boolObj replaceObjectAtIndex:0 withObject:NSNull.null],
                              @"Invalid value '<null>' of type 'NSNull' for expected type 'bool'");
    RLMAssertThrowsWithReason([managed.intObj replaceObjectAtIndex:0 withObject:NSNull.null],
                              @"Invalid value '<null>' of type 'NSNull' for expected type 'int'");
    RLMAssertThrowsWithReason([managed.floatObj replaceObjectAtIndex:0 withObject:NSNull.null],
                              @"Invalid value '<null>' of type 'NSNull' for expected type 'float'");
    RLMAssertThrowsWithReason([managed.doubleObj replaceObjectAtIndex:0 withObject:NSNull.null],
                              @"Invalid value '<null>' of type 'NSNull' for expected type 'double'");
    RLMAssertThrowsWithReason([managed.stringObj replaceObjectAtIndex:0 withObject:NSNull.null],
                              @"Invalid value '<null>' of type 'NSNull' for expected type 'string'");
    RLMAssertThrowsWithReason([managed.dataObj replaceObjectAtIndex:0 withObject:NSNull.null],
                              @"Invalid value '<null>' of type 'NSNull' for expected type 'data'");
    RLMAssertThrowsWithReason([managed.dateObj replaceObjectAtIndex:0 withObject:NSNull.null],
                              @"Invalid value '<null>' of type 'NSNull' for expected type 'date'");
    RLMAssertThrowsWithReason([managed.decimalObj replaceObjectAtIndex:0 withObject:NSNull.null],
                              @"Invalid value '<null>' of type 'NSNull' for expected type 'decimal128'");
    RLMAssertThrowsWithReason([managed.objectIdObj replaceObjectAtIndex:0 withObject:NSNull.null],
                              @"Invalid value '<null>' of type 'NSNull' for expected type 'object id'");
    RLMAssertThrowsWithReason([managed.uuidObj replaceObjectAtIndex:0 withObject:NSNull.null],
                              @"Invalid value '<null>' of type 'NSNull' for expected type 'uuid'");
}

- (void)testMove {
    for (RLMArray *array in allArrays) {
        RLMAssertThrowsWithReason([array moveObjectAtIndex:0 toIndex:1],
                                  @"Index 0 is out of bounds (must be less than 0).");
    }
    for (RLMArray *array in allArrays) {
        RLMAssertThrowsWithReason([array moveObjectAtIndex:1 toIndex:0],
                                  @"Index 1 is out of bounds (must be less than 0).");
    }

    [unmanaged.boolObj addObjects:@[@NO, @YES, @NO, @YES]];
    [unmanaged.intObj addObjects:@[@2, @3, @2, @3]];
    [unmanaged.floatObj addObjects:@[@2.2f, @3.3f, @2.2f, @3.3f]];
    [unmanaged.doubleObj addObjects:@[@2.2, @3.3, @2.2, @3.3]];
    [unmanaged.stringObj addObjects:@[@"a", @"b", @"a", @"b"]];
    [unmanaged.dataObj addObjects:@[data(1), data(2), data(1), data(2)]];
    [unmanaged.dateObj addObjects:@[date(1), date(2), date(1), date(2)]];
    [unmanaged.decimalObj addObjects:@[decimal128(2), decimal128(3), decimal128(2), decimal128(3)]];
    [unmanaged.objectIdObj addObjects:@[objectId(1), objectId(2), objectId(1), objectId(2)]];
    [unmanaged.uuidObj addObjects:@[uuid(@"00000000-0000-0000-0000-000000000000"), uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"), uuid(@"00000000-0000-0000-0000-000000000000"), uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")]];
    [unmanaged.anyBoolObj addObjects:@[@NO, @YES, @NO, @YES]];
    [unmanaged.anyIntObj addObjects:@[@2, @3, @2, @3]];
    [unmanaged.anyFloatObj addObjects:@[@2.2f, @3.3f, @2.2f, @3.3f]];
    [unmanaged.anyDoubleObj addObjects:@[@2.2, @3.3, @2.2, @3.3]];
    [unmanaged.anyStringObj addObjects:@[@"a", @"b", @"a", @"b"]];
    [unmanaged.anyDataObj addObjects:@[data(1), data(2), data(1), data(2)]];
    [unmanaged.anyDateObj addObjects:@[date(1), date(2), date(1), date(2)]];
    [unmanaged.anyDecimalObj addObjects:@[decimal128(2), decimal128(3), decimal128(2), decimal128(3)]];
    [unmanaged.anyObjectIdObj addObjects:@[objectId(1), objectId(2), objectId(1), objectId(2)]];
    [unmanaged.anyUUIDObj addObjects:@[uuid(@"00000000-0000-0000-0000-000000000000"), uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"), uuid(@"00000000-0000-0000-0000-000000000000"), uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")]];
    [optUnmanaged.boolObj addObjects:@[@NO, @YES, @NO, @YES]];
    [optUnmanaged.intObj addObjects:@[@2, @3, @2, @3]];
    [optUnmanaged.floatObj addObjects:@[@2.2f, @3.3f, @2.2f, @3.3f]];
    [optUnmanaged.doubleObj addObjects:@[@2.2, @3.3, @2.2, @3.3]];
    [optUnmanaged.stringObj addObjects:@[@"a", @"b", @"a", @"b"]];
    [optUnmanaged.dataObj addObjects:@[data(1), data(2), data(1), data(2)]];
    [optUnmanaged.dateObj addObjects:@[date(1), date(2), date(1), date(2)]];
    [optUnmanaged.decimalObj addObjects:@[decimal128(2), decimal128(3), decimal128(2), decimal128(3)]];
    [optUnmanaged.objectIdObj addObjects:@[objectId(1), objectId(2), objectId(1), objectId(2)]];
    [optUnmanaged.uuidObj addObjects:@[uuid(@"00000000-0000-0000-0000-000000000000"), uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"), uuid(@"00000000-0000-0000-0000-000000000000"), uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")]];
    [managed.boolObj addObjects:@[@NO, @YES, @NO, @YES]];
    [managed.intObj addObjects:@[@2, @3, @2, @3]];
    [managed.floatObj addObjects:@[@2.2f, @3.3f, @2.2f, @3.3f]];
    [managed.doubleObj addObjects:@[@2.2, @3.3, @2.2, @3.3]];
    [managed.stringObj addObjects:@[@"a", @"b", @"a", @"b"]];
    [managed.dataObj addObjects:@[data(1), data(2), data(1), data(2)]];
    [managed.dateObj addObjects:@[date(1), date(2), date(1), date(2)]];
    [managed.decimalObj addObjects:@[decimal128(2), decimal128(3), decimal128(2), decimal128(3)]];
    [managed.objectIdObj addObjects:@[objectId(1), objectId(2), objectId(1), objectId(2)]];
    [managed.uuidObj addObjects:@[uuid(@"00000000-0000-0000-0000-000000000000"), uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"), uuid(@"00000000-0000-0000-0000-000000000000"), uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")]];
    [managed.anyBoolObj addObjects:@[@NO, @YES, @NO, @YES]];
    [managed.anyIntObj addObjects:@[@2, @3, @2, @3]];
    [managed.anyFloatObj addObjects:@[@2.2f, @3.3f, @2.2f, @3.3f]];
    [managed.anyDoubleObj addObjects:@[@2.2, @3.3, @2.2, @3.3]];
    [managed.anyStringObj addObjects:@[@"a", @"b", @"a", @"b"]];
    [managed.anyDataObj addObjects:@[data(1), data(2), data(1), data(2)]];
    [managed.anyDateObj addObjects:@[date(1), date(2), date(1), date(2)]];
    [managed.anyDecimalObj addObjects:@[decimal128(2), decimal128(3), decimal128(2), decimal128(3)]];
    [managed.anyObjectIdObj addObjects:@[objectId(1), objectId(2), objectId(1), objectId(2)]];
    [managed.anyUUIDObj addObjects:@[uuid(@"00000000-0000-0000-0000-000000000000"), uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"), uuid(@"00000000-0000-0000-0000-000000000000"), uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")]];
    [optManaged.boolObj addObjects:@[@NO, @YES, @NO, @YES]];
    [optManaged.intObj addObjects:@[@2, @3, @2, @3]];
    [optManaged.floatObj addObjects:@[@2.2f, @3.3f, @2.2f, @3.3f]];
    [optManaged.doubleObj addObjects:@[@2.2, @3.3, @2.2, @3.3]];
    [optManaged.stringObj addObjects:@[@"a", @"b", @"a", @"b"]];
    [optManaged.dataObj addObjects:@[data(1), data(2), data(1), data(2)]];
    [optManaged.dateObj addObjects:@[date(1), date(2), date(1), date(2)]];
    [optManaged.decimalObj addObjects:@[decimal128(2), decimal128(3), decimal128(2), decimal128(3)]];
    [optManaged.objectIdObj addObjects:@[objectId(1), objectId(2), objectId(1), objectId(2)]];
    [optManaged.uuidObj addObjects:@[uuid(@"00000000-0000-0000-0000-000000000000"), uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"), uuid(@"00000000-0000-0000-0000-000000000000"), uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")]];

    for (RLMArray *array in allArrays) {
        [array moveObjectAtIndex:2 toIndex:0];
    }

    XCTAssertEqualObjects([unmanaged.boolObj valueForKey:@"self"],
                          (@[@NO, @NO, @YES, @YES]));
    XCTAssertEqualObjects([unmanaged.intObj valueForKey:@"self"],
                          (@[@2, @2, @3, @3]));
    XCTAssertEqualObjects([unmanaged.floatObj valueForKey:@"self"],
                          (@[@2.2f, @2.2f, @3.3f, @3.3f]));
    XCTAssertEqualObjects([unmanaged.doubleObj valueForKey:@"self"],
                          (@[@2.2, @2.2, @3.3, @3.3]));
    XCTAssertEqualObjects([unmanaged.stringObj valueForKey:@"self"],
                          (@[@"a", @"a", @"b", @"b"]));
    XCTAssertEqualObjects([unmanaged.dataObj valueForKey:@"self"],
                          (@[data(1), data(1), data(2), data(2)]));
    XCTAssertEqualObjects([unmanaged.dateObj valueForKey:@"self"],
                          (@[date(1), date(1), date(2), date(2)]));
    XCTAssertEqualObjects([unmanaged.decimalObj valueForKey:@"self"],
                          (@[decimal128(2), decimal128(2), decimal128(3), decimal128(3)]));
    XCTAssertEqualObjects([unmanaged.objectIdObj valueForKey:@"self"],
                          (@[objectId(1), objectId(1), objectId(2), objectId(2)]));
    XCTAssertEqualObjects([unmanaged.uuidObj valueForKey:@"self"],
                          (@[uuid(@"00000000-0000-0000-0000-000000000000"), uuid(@"00000000-0000-0000-0000-000000000000"), uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"), uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")]));
    XCTAssertEqualObjects([unmanaged.anyBoolObj valueForKey:@"self"],
                          (@[@NO, @NO, @YES, @YES]));
    XCTAssertEqualObjects([unmanaged.anyIntObj valueForKey:@"self"],
                          (@[@2, @2, @3, @3]));
    XCTAssertEqualObjects([unmanaged.anyFloatObj valueForKey:@"self"],
                          (@[@2.2f, @2.2f, @3.3f, @3.3f]));
    XCTAssertEqualObjects([unmanaged.anyDoubleObj valueForKey:@"self"],
                          (@[@2.2, @2.2, @3.3, @3.3]));
    XCTAssertEqualObjects([unmanaged.anyStringObj valueForKey:@"self"],
                          (@[@"a", @"a", @"b", @"b"]));
    XCTAssertEqualObjects([unmanaged.anyDataObj valueForKey:@"self"],
                          (@[data(1), data(1), data(2), data(2)]));
    XCTAssertEqualObjects([unmanaged.anyDateObj valueForKey:@"self"],
                          (@[date(1), date(1), date(2), date(2)]));
    XCTAssertEqualObjects([unmanaged.anyDecimalObj valueForKey:@"self"],
                          (@[decimal128(2), decimal128(2), decimal128(3), decimal128(3)]));
    XCTAssertEqualObjects([unmanaged.anyObjectIdObj valueForKey:@"self"],
                          (@[objectId(1), objectId(1), objectId(2), objectId(2)]));
    XCTAssertEqualObjects([unmanaged.anyUUIDObj valueForKey:@"self"],
                          (@[uuid(@"00000000-0000-0000-0000-000000000000"), uuid(@"00000000-0000-0000-0000-000000000000"), uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"), uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")]));
    XCTAssertEqualObjects([optUnmanaged.boolObj valueForKey:@"self"],
                          (@[@NO, @NO, @YES, @YES]));
    XCTAssertEqualObjects([optUnmanaged.intObj valueForKey:@"self"],
                          (@[@2, @2, @3, @3]));
    XCTAssertEqualObjects([optUnmanaged.floatObj valueForKey:@"self"],
                          (@[@2.2f, @2.2f, @3.3f, @3.3f]));
    XCTAssertEqualObjects([optUnmanaged.doubleObj valueForKey:@"self"],
                          (@[@2.2, @2.2, @3.3, @3.3]));
    XCTAssertEqualObjects([optUnmanaged.stringObj valueForKey:@"self"],
                          (@[@"a", @"a", @"b", @"b"]));
    XCTAssertEqualObjects([optUnmanaged.dataObj valueForKey:@"self"],
                          (@[data(1), data(1), data(2), data(2)]));
    XCTAssertEqualObjects([optUnmanaged.dateObj valueForKey:@"self"],
                          (@[date(1), date(1), date(2), date(2)]));
    XCTAssertEqualObjects([optUnmanaged.decimalObj valueForKey:@"self"],
                          (@[decimal128(2), decimal128(2), decimal128(3), decimal128(3)]));
    XCTAssertEqualObjects([optUnmanaged.objectIdObj valueForKey:@"self"],
                          (@[objectId(1), objectId(1), objectId(2), objectId(2)]));
    XCTAssertEqualObjects([optUnmanaged.uuidObj valueForKey:@"self"],
                          (@[uuid(@"00000000-0000-0000-0000-000000000000"), uuid(@"00000000-0000-0000-0000-000000000000"), uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"), uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")]));
    XCTAssertEqualObjects([managed.boolObj valueForKey:@"self"],
                          (@[@NO, @NO, @YES, @YES]));
    XCTAssertEqualObjects([managed.intObj valueForKey:@"self"],
                          (@[@2, @2, @3, @3]));
    XCTAssertEqualObjects([managed.floatObj valueForKey:@"self"],
                          (@[@2.2f, @2.2f, @3.3f, @3.3f]));
    XCTAssertEqualObjects([managed.doubleObj valueForKey:@"self"],
                          (@[@2.2, @2.2, @3.3, @3.3]));
    XCTAssertEqualObjects([managed.stringObj valueForKey:@"self"],
                          (@[@"a", @"a", @"b", @"b"]));
    XCTAssertEqualObjects([managed.dataObj valueForKey:@"self"],
                          (@[data(1), data(1), data(2), data(2)]));
    XCTAssertEqualObjects([managed.dateObj valueForKey:@"self"],
                          (@[date(1), date(1), date(2), date(2)]));
    XCTAssertEqualObjects([managed.decimalObj valueForKey:@"self"],
                          (@[decimal128(2), decimal128(2), decimal128(3), decimal128(3)]));
    XCTAssertEqualObjects([managed.objectIdObj valueForKey:@"self"],
                          (@[objectId(1), objectId(1), objectId(2), objectId(2)]));
    XCTAssertEqualObjects([managed.uuidObj valueForKey:@"self"],
                          (@[uuid(@"00000000-0000-0000-0000-000000000000"), uuid(@"00000000-0000-0000-0000-000000000000"), uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"), uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")]));
    XCTAssertEqualObjects([managed.anyBoolObj valueForKey:@"self"],
                          (@[@NO, @NO, @YES, @YES]));
    XCTAssertEqualObjects([managed.anyIntObj valueForKey:@"self"],
                          (@[@2, @2, @3, @3]));
    XCTAssertEqualObjects([managed.anyFloatObj valueForKey:@"self"],
                          (@[@2.2f, @2.2f, @3.3f, @3.3f]));
    XCTAssertEqualObjects([managed.anyDoubleObj valueForKey:@"self"],
                          (@[@2.2, @2.2, @3.3, @3.3]));
    XCTAssertEqualObjects([managed.anyStringObj valueForKey:@"self"],
                          (@[@"a", @"a", @"b", @"b"]));
    XCTAssertEqualObjects([managed.anyDataObj valueForKey:@"self"],
                          (@[data(1), data(1), data(2), data(2)]));
    XCTAssertEqualObjects([managed.anyDateObj valueForKey:@"self"],
                          (@[date(1), date(1), date(2), date(2)]));
    XCTAssertEqualObjects([managed.anyDecimalObj valueForKey:@"self"],
                          (@[decimal128(2), decimal128(2), decimal128(3), decimal128(3)]));
    XCTAssertEqualObjects([managed.anyObjectIdObj valueForKey:@"self"],
                          (@[objectId(1), objectId(1), objectId(2), objectId(2)]));
    XCTAssertEqualObjects([managed.anyUUIDObj valueForKey:@"self"],
                          (@[uuid(@"00000000-0000-0000-0000-000000000000"), uuid(@"00000000-0000-0000-0000-000000000000"), uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"), uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")]));
    XCTAssertEqualObjects([optManaged.boolObj valueForKey:@"self"],
                          (@[@NO, @NO, @YES, @YES]));
    XCTAssertEqualObjects([optManaged.intObj valueForKey:@"self"],
                          (@[@2, @2, @3, @3]));
    XCTAssertEqualObjects([optManaged.floatObj valueForKey:@"self"],
                          (@[@2.2f, @2.2f, @3.3f, @3.3f]));
    XCTAssertEqualObjects([optManaged.doubleObj valueForKey:@"self"],
                          (@[@2.2, @2.2, @3.3, @3.3]));
    XCTAssertEqualObjects([optManaged.stringObj valueForKey:@"self"],
                          (@[@"a", @"a", @"b", @"b"]));
    XCTAssertEqualObjects([optManaged.dataObj valueForKey:@"self"],
                          (@[data(1), data(1), data(2), data(2)]));
    XCTAssertEqualObjects([optManaged.dateObj valueForKey:@"self"],
                          (@[date(1), date(1), date(2), date(2)]));
    XCTAssertEqualObjects([optManaged.decimalObj valueForKey:@"self"],
                          (@[decimal128(2), decimal128(2), decimal128(3), decimal128(3)]));
    XCTAssertEqualObjects([optManaged.objectIdObj valueForKey:@"self"],
                          (@[objectId(1), objectId(1), objectId(2), objectId(2)]));
    XCTAssertEqualObjects([optManaged.uuidObj valueForKey:@"self"],
                          (@[uuid(@"00000000-0000-0000-0000-000000000000"), uuid(@"00000000-0000-0000-0000-000000000000"), uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"), uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")]));
}

- (void)testExchange {
    for (RLMArray *array in allArrays) {
        RLMAssertThrowsWithReason([array exchangeObjectAtIndex:0 withObjectAtIndex:1],
                                  @"Index 0 is out of bounds (must be less than 0).");
    }
    for (RLMArray *array in allArrays) {
        RLMAssertThrowsWithReason([array exchangeObjectAtIndex:1 withObjectAtIndex:0],
                                  @"Index 1 is out of bounds (must be less than 0).");
    }

    [unmanaged.boolObj addObjects:@[@NO, @YES, @NO, @YES]];
    [unmanaged.intObj addObjects:@[@2, @3, @2, @3]];
    [unmanaged.floatObj addObjects:@[@2.2f, @3.3f, @2.2f, @3.3f]];
    [unmanaged.doubleObj addObjects:@[@2.2, @3.3, @2.2, @3.3]];
    [unmanaged.stringObj addObjects:@[@"a", @"b", @"a", @"b"]];
    [unmanaged.dataObj addObjects:@[data(1), data(2), data(1), data(2)]];
    [unmanaged.dateObj addObjects:@[date(1), date(2), date(1), date(2)]];
    [unmanaged.decimalObj addObjects:@[decimal128(2), decimal128(3), decimal128(2), decimal128(3)]];
    [unmanaged.objectIdObj addObjects:@[objectId(1), objectId(2), objectId(1), objectId(2)]];
    [unmanaged.uuidObj addObjects:@[uuid(@"00000000-0000-0000-0000-000000000000"), uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"), uuid(@"00000000-0000-0000-0000-000000000000"), uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")]];
    [unmanaged.anyBoolObj addObjects:@[@NO, @YES, @NO, @YES]];
    [unmanaged.anyIntObj addObjects:@[@2, @3, @2, @3]];
    [unmanaged.anyFloatObj addObjects:@[@2.2f, @3.3f, @2.2f, @3.3f]];
    [unmanaged.anyDoubleObj addObjects:@[@2.2, @3.3, @2.2, @3.3]];
    [unmanaged.anyStringObj addObjects:@[@"a", @"b", @"a", @"b"]];
    [unmanaged.anyDataObj addObjects:@[data(1), data(2), data(1), data(2)]];
    [unmanaged.anyDateObj addObjects:@[date(1), date(2), date(1), date(2)]];
    [unmanaged.anyDecimalObj addObjects:@[decimal128(2), decimal128(3), decimal128(2), decimal128(3)]];
    [unmanaged.anyObjectIdObj addObjects:@[objectId(1), objectId(2), objectId(1), objectId(2)]];
    [unmanaged.anyUUIDObj addObjects:@[uuid(@"00000000-0000-0000-0000-000000000000"), uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"), uuid(@"00000000-0000-0000-0000-000000000000"), uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")]];
    [optUnmanaged.boolObj addObjects:@[@NO, @YES, @NO, @YES]];
    [optUnmanaged.intObj addObjects:@[@2, @3, @2, @3]];
    [optUnmanaged.floatObj addObjects:@[@2.2f, @3.3f, @2.2f, @3.3f]];
    [optUnmanaged.doubleObj addObjects:@[@2.2, @3.3, @2.2, @3.3]];
    [optUnmanaged.stringObj addObjects:@[@"a", @"b", @"a", @"b"]];
    [optUnmanaged.dataObj addObjects:@[data(1), data(2), data(1), data(2)]];
    [optUnmanaged.dateObj addObjects:@[date(1), date(2), date(1), date(2)]];
    [optUnmanaged.decimalObj addObjects:@[decimal128(2), decimal128(3), decimal128(2), decimal128(3)]];
    [optUnmanaged.objectIdObj addObjects:@[objectId(1), objectId(2), objectId(1), objectId(2)]];
    [optUnmanaged.uuidObj addObjects:@[uuid(@"00000000-0000-0000-0000-000000000000"), uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"), uuid(@"00000000-0000-0000-0000-000000000000"), uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")]];
    [managed.boolObj addObjects:@[@NO, @YES, @NO, @YES]];
    [managed.intObj addObjects:@[@2, @3, @2, @3]];
    [managed.floatObj addObjects:@[@2.2f, @3.3f, @2.2f, @3.3f]];
    [managed.doubleObj addObjects:@[@2.2, @3.3, @2.2, @3.3]];
    [managed.stringObj addObjects:@[@"a", @"b", @"a", @"b"]];
    [managed.dataObj addObjects:@[data(1), data(2), data(1), data(2)]];
    [managed.dateObj addObjects:@[date(1), date(2), date(1), date(2)]];
    [managed.decimalObj addObjects:@[decimal128(2), decimal128(3), decimal128(2), decimal128(3)]];
    [managed.objectIdObj addObjects:@[objectId(1), objectId(2), objectId(1), objectId(2)]];
    [managed.uuidObj addObjects:@[uuid(@"00000000-0000-0000-0000-000000000000"), uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"), uuid(@"00000000-0000-0000-0000-000000000000"), uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")]];
    [managed.anyBoolObj addObjects:@[@NO, @YES, @NO, @YES]];
    [managed.anyIntObj addObjects:@[@2, @3, @2, @3]];
    [managed.anyFloatObj addObjects:@[@2.2f, @3.3f, @2.2f, @3.3f]];
    [managed.anyDoubleObj addObjects:@[@2.2, @3.3, @2.2, @3.3]];
    [managed.anyStringObj addObjects:@[@"a", @"b", @"a", @"b"]];
    [managed.anyDataObj addObjects:@[data(1), data(2), data(1), data(2)]];
    [managed.anyDateObj addObjects:@[date(1), date(2), date(1), date(2)]];
    [managed.anyDecimalObj addObjects:@[decimal128(2), decimal128(3), decimal128(2), decimal128(3)]];
    [managed.anyObjectIdObj addObjects:@[objectId(1), objectId(2), objectId(1), objectId(2)]];
    [managed.anyUUIDObj addObjects:@[uuid(@"00000000-0000-0000-0000-000000000000"), uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"), uuid(@"00000000-0000-0000-0000-000000000000"), uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")]];
    [optManaged.boolObj addObjects:@[@NO, @YES, @NO, @YES]];
    [optManaged.intObj addObjects:@[@2, @3, @2, @3]];
    [optManaged.floatObj addObjects:@[@2.2f, @3.3f, @2.2f, @3.3f]];
    [optManaged.doubleObj addObjects:@[@2.2, @3.3, @2.2, @3.3]];
    [optManaged.stringObj addObjects:@[@"a", @"b", @"a", @"b"]];
    [optManaged.dataObj addObjects:@[data(1), data(2), data(1), data(2)]];
    [optManaged.dateObj addObjects:@[date(1), date(2), date(1), date(2)]];
    [optManaged.decimalObj addObjects:@[decimal128(2), decimal128(3), decimal128(2), decimal128(3)]];
    [optManaged.objectIdObj addObjects:@[objectId(1), objectId(2), objectId(1), objectId(2)]];
    [optManaged.uuidObj addObjects:@[uuid(@"00000000-0000-0000-0000-000000000000"), uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"), uuid(@"00000000-0000-0000-0000-000000000000"), uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")]];

    for (RLMArray *array in allArrays) {
        [array exchangeObjectAtIndex:2 withObjectAtIndex:1];
    }

    XCTAssertEqualObjects([unmanaged.boolObj valueForKey:@"self"],
                          (@[@NO, @NO, @YES, @YES]));
    XCTAssertEqualObjects([unmanaged.intObj valueForKey:@"self"],
                          (@[@2, @2, @3, @3]));
    XCTAssertEqualObjects([unmanaged.floatObj valueForKey:@"self"],
                          (@[@2.2f, @2.2f, @3.3f, @3.3f]));
    XCTAssertEqualObjects([unmanaged.doubleObj valueForKey:@"self"],
                          (@[@2.2, @2.2, @3.3, @3.3]));
    XCTAssertEqualObjects([unmanaged.stringObj valueForKey:@"self"],
                          (@[@"a", @"a", @"b", @"b"]));
    XCTAssertEqualObjects([unmanaged.dataObj valueForKey:@"self"],
                          (@[data(1), data(1), data(2), data(2)]));
    XCTAssertEqualObjects([unmanaged.dateObj valueForKey:@"self"],
                          (@[date(1), date(1), date(2), date(2)]));
    XCTAssertEqualObjects([unmanaged.decimalObj valueForKey:@"self"],
                          (@[decimal128(2), decimal128(2), decimal128(3), decimal128(3)]));
    XCTAssertEqualObjects([unmanaged.objectIdObj valueForKey:@"self"],
                          (@[objectId(1), objectId(1), objectId(2), objectId(2)]));
    XCTAssertEqualObjects([unmanaged.uuidObj valueForKey:@"self"],
                          (@[uuid(@"00000000-0000-0000-0000-000000000000"), uuid(@"00000000-0000-0000-0000-000000000000"), uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"), uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")]));
    XCTAssertEqualObjects([unmanaged.anyBoolObj valueForKey:@"self"],
                          (@[@NO, @NO, @YES, @YES]));
    XCTAssertEqualObjects([unmanaged.anyIntObj valueForKey:@"self"],
                          (@[@2, @2, @3, @3]));
    XCTAssertEqualObjects([unmanaged.anyFloatObj valueForKey:@"self"],
                          (@[@2.2f, @2.2f, @3.3f, @3.3f]));
    XCTAssertEqualObjects([unmanaged.anyDoubleObj valueForKey:@"self"],
                          (@[@2.2, @2.2, @3.3, @3.3]));
    XCTAssertEqualObjects([unmanaged.anyStringObj valueForKey:@"self"],
                          (@[@"a", @"a", @"b", @"b"]));
    XCTAssertEqualObjects([unmanaged.anyDataObj valueForKey:@"self"],
                          (@[data(1), data(1), data(2), data(2)]));
    XCTAssertEqualObjects([unmanaged.anyDateObj valueForKey:@"self"],
                          (@[date(1), date(1), date(2), date(2)]));
    XCTAssertEqualObjects([unmanaged.anyDecimalObj valueForKey:@"self"],
                          (@[decimal128(2), decimal128(2), decimal128(3), decimal128(3)]));
    XCTAssertEqualObjects([unmanaged.anyObjectIdObj valueForKey:@"self"],
                          (@[objectId(1), objectId(1), objectId(2), objectId(2)]));
    XCTAssertEqualObjects([unmanaged.anyUUIDObj valueForKey:@"self"],
                          (@[uuid(@"00000000-0000-0000-0000-000000000000"), uuid(@"00000000-0000-0000-0000-000000000000"), uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"), uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")]));
    XCTAssertEqualObjects([optUnmanaged.boolObj valueForKey:@"self"],
                          (@[@NO, @NO, @YES, @YES]));
    XCTAssertEqualObjects([optUnmanaged.intObj valueForKey:@"self"],
                          (@[@2, @2, @3, @3]));
    XCTAssertEqualObjects([optUnmanaged.floatObj valueForKey:@"self"],
                          (@[@2.2f, @2.2f, @3.3f, @3.3f]));
    XCTAssertEqualObjects([optUnmanaged.doubleObj valueForKey:@"self"],
                          (@[@2.2, @2.2, @3.3, @3.3]));
    XCTAssertEqualObjects([optUnmanaged.stringObj valueForKey:@"self"],
                          (@[@"a", @"a", @"b", @"b"]));
    XCTAssertEqualObjects([optUnmanaged.dataObj valueForKey:@"self"],
                          (@[data(1), data(1), data(2), data(2)]));
    XCTAssertEqualObjects([optUnmanaged.dateObj valueForKey:@"self"],
                          (@[date(1), date(1), date(2), date(2)]));
    XCTAssertEqualObjects([optUnmanaged.decimalObj valueForKey:@"self"],
                          (@[decimal128(2), decimal128(2), decimal128(3), decimal128(3)]));
    XCTAssertEqualObjects([optUnmanaged.objectIdObj valueForKey:@"self"],
                          (@[objectId(1), objectId(1), objectId(2), objectId(2)]));
    XCTAssertEqualObjects([optUnmanaged.uuidObj valueForKey:@"self"],
                          (@[uuid(@"00000000-0000-0000-0000-000000000000"), uuid(@"00000000-0000-0000-0000-000000000000"), uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"), uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")]));
    XCTAssertEqualObjects([managed.boolObj valueForKey:@"self"],
                          (@[@NO, @NO, @YES, @YES]));
    XCTAssertEqualObjects([managed.intObj valueForKey:@"self"],
                          (@[@2, @2, @3, @3]));
    XCTAssertEqualObjects([managed.floatObj valueForKey:@"self"],
                          (@[@2.2f, @2.2f, @3.3f, @3.3f]));
    XCTAssertEqualObjects([managed.doubleObj valueForKey:@"self"],
                          (@[@2.2, @2.2, @3.3, @3.3]));
    XCTAssertEqualObjects([managed.stringObj valueForKey:@"self"],
                          (@[@"a", @"a", @"b", @"b"]));
    XCTAssertEqualObjects([managed.dataObj valueForKey:@"self"],
                          (@[data(1), data(1), data(2), data(2)]));
    XCTAssertEqualObjects([managed.dateObj valueForKey:@"self"],
                          (@[date(1), date(1), date(2), date(2)]));
    XCTAssertEqualObjects([managed.decimalObj valueForKey:@"self"],
                          (@[decimal128(2), decimal128(2), decimal128(3), decimal128(3)]));
    XCTAssertEqualObjects([managed.objectIdObj valueForKey:@"self"],
                          (@[objectId(1), objectId(1), objectId(2), objectId(2)]));
    XCTAssertEqualObjects([managed.uuidObj valueForKey:@"self"],
                          (@[uuid(@"00000000-0000-0000-0000-000000000000"), uuid(@"00000000-0000-0000-0000-000000000000"), uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"), uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")]));
    XCTAssertEqualObjects([managed.anyBoolObj valueForKey:@"self"],
                          (@[@NO, @NO, @YES, @YES]));
    XCTAssertEqualObjects([managed.anyIntObj valueForKey:@"self"],
                          (@[@2, @2, @3, @3]));
    XCTAssertEqualObjects([managed.anyFloatObj valueForKey:@"self"],
                          (@[@2.2f, @2.2f, @3.3f, @3.3f]));
    XCTAssertEqualObjects([managed.anyDoubleObj valueForKey:@"self"],
                          (@[@2.2, @2.2, @3.3, @3.3]));
    XCTAssertEqualObjects([managed.anyStringObj valueForKey:@"self"],
                          (@[@"a", @"a", @"b", @"b"]));
    XCTAssertEqualObjects([managed.anyDataObj valueForKey:@"self"],
                          (@[data(1), data(1), data(2), data(2)]));
    XCTAssertEqualObjects([managed.anyDateObj valueForKey:@"self"],
                          (@[date(1), date(1), date(2), date(2)]));
    XCTAssertEqualObjects([managed.anyDecimalObj valueForKey:@"self"],
                          (@[decimal128(2), decimal128(2), decimal128(3), decimal128(3)]));
    XCTAssertEqualObjects([managed.anyObjectIdObj valueForKey:@"self"],
                          (@[objectId(1), objectId(1), objectId(2), objectId(2)]));
    XCTAssertEqualObjects([managed.anyUUIDObj valueForKey:@"self"],
                          (@[uuid(@"00000000-0000-0000-0000-000000000000"), uuid(@"00000000-0000-0000-0000-000000000000"), uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"), uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")]));
    XCTAssertEqualObjects([optManaged.boolObj valueForKey:@"self"],
                          (@[@NO, @NO, @YES, @YES]));
    XCTAssertEqualObjects([optManaged.intObj valueForKey:@"self"],
                          (@[@2, @2, @3, @3]));
    XCTAssertEqualObjects([optManaged.floatObj valueForKey:@"self"],
                          (@[@2.2f, @2.2f, @3.3f, @3.3f]));
    XCTAssertEqualObjects([optManaged.doubleObj valueForKey:@"self"],
                          (@[@2.2, @2.2, @3.3, @3.3]));
    XCTAssertEqualObjects([optManaged.stringObj valueForKey:@"self"],
                          (@[@"a", @"a", @"b", @"b"]));
    XCTAssertEqualObjects([optManaged.dataObj valueForKey:@"self"],
                          (@[data(1), data(1), data(2), data(2)]));
    XCTAssertEqualObjects([optManaged.dateObj valueForKey:@"self"],
                          (@[date(1), date(1), date(2), date(2)]));
    XCTAssertEqualObjects([optManaged.decimalObj valueForKey:@"self"],
                          (@[decimal128(2), decimal128(2), decimal128(3), decimal128(3)]));
    XCTAssertEqualObjects([optManaged.objectIdObj valueForKey:@"self"],
                          (@[objectId(1), objectId(1), objectId(2), objectId(2)]));
    XCTAssertEqualObjects([optManaged.uuidObj valueForKey:@"self"],
                          (@[uuid(@"00000000-0000-0000-0000-000000000000"), uuid(@"00000000-0000-0000-0000-000000000000"), uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"), uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")]));
}

- (void)testIndexOfObject {
    XCTAssertEqual(NSNotFound, [unmanaged.boolObj indexOfObject:@NO]);
    XCTAssertEqual(NSNotFound, [unmanaged.intObj indexOfObject:@2]);
    XCTAssertEqual(NSNotFound, [unmanaged.floatObj indexOfObject:@2.2f]);
    XCTAssertEqual(NSNotFound, [unmanaged.doubleObj indexOfObject:@2.2]);
    XCTAssertEqual(NSNotFound, [unmanaged.stringObj indexOfObject:@"a"]);
    XCTAssertEqual(NSNotFound, [unmanaged.dataObj indexOfObject:data(1)]);
    XCTAssertEqual(NSNotFound, [unmanaged.dateObj indexOfObject:date(1)]);
    XCTAssertEqual(NSNotFound, [unmanaged.decimalObj indexOfObject:decimal128(2)]);
    XCTAssertEqual(NSNotFound, [unmanaged.objectIdObj indexOfObject:objectId(1)]);
    XCTAssertEqual(NSNotFound, [unmanaged.uuidObj indexOfObject:uuid(@"00000000-0000-0000-0000-000000000000")]);
    XCTAssertEqual(NSNotFound, [unmanaged.anyBoolObj indexOfObject:@NO]);
    XCTAssertEqual(NSNotFound, [unmanaged.anyIntObj indexOfObject:@2]);
    XCTAssertEqual(NSNotFound, [unmanaged.anyFloatObj indexOfObject:@2.2f]);
    XCTAssertEqual(NSNotFound, [unmanaged.anyDoubleObj indexOfObject:@2.2]);
    XCTAssertEqual(NSNotFound, [unmanaged.anyStringObj indexOfObject:@"a"]);
    XCTAssertEqual(NSNotFound, [unmanaged.anyDataObj indexOfObject:data(1)]);
    XCTAssertEqual(NSNotFound, [unmanaged.anyDateObj indexOfObject:date(1)]);
    XCTAssertEqual(NSNotFound, [unmanaged.anyDecimalObj indexOfObject:decimal128(2)]);
    XCTAssertEqual(NSNotFound, [unmanaged.anyObjectIdObj indexOfObject:objectId(1)]);
    XCTAssertEqual(NSNotFound, [unmanaged.anyUUIDObj indexOfObject:uuid(@"00000000-0000-0000-0000-000000000000")]);
    XCTAssertEqual(NSNotFound, [optUnmanaged.boolObj indexOfObject:@NO]);
    XCTAssertEqual(NSNotFound, [optUnmanaged.intObj indexOfObject:@2]);
    XCTAssertEqual(NSNotFound, [optUnmanaged.floatObj indexOfObject:@2.2f]);
    XCTAssertEqual(NSNotFound, [optUnmanaged.doubleObj indexOfObject:@2.2]);
    XCTAssertEqual(NSNotFound, [optUnmanaged.stringObj indexOfObject:@"a"]);
    XCTAssertEqual(NSNotFound, [optUnmanaged.dataObj indexOfObject:data(1)]);
    XCTAssertEqual(NSNotFound, [optUnmanaged.dateObj indexOfObject:date(1)]);
    XCTAssertEqual(NSNotFound, [optUnmanaged.decimalObj indexOfObject:decimal128(2)]);
    XCTAssertEqual(NSNotFound, [optUnmanaged.objectIdObj indexOfObject:objectId(1)]);
    XCTAssertEqual(NSNotFound, [optUnmanaged.uuidObj indexOfObject:uuid(@"00000000-0000-0000-0000-000000000000")]);
    XCTAssertEqual(NSNotFound, [managed.boolObj indexOfObject:@NO]);
    XCTAssertEqual(NSNotFound, [managed.intObj indexOfObject:@2]);
    XCTAssertEqual(NSNotFound, [managed.floatObj indexOfObject:@2.2f]);
    XCTAssertEqual(NSNotFound, [managed.doubleObj indexOfObject:@2.2]);
    XCTAssertEqual(NSNotFound, [managed.stringObj indexOfObject:@"a"]);
    XCTAssertEqual(NSNotFound, [managed.dataObj indexOfObject:data(1)]);
    XCTAssertEqual(NSNotFound, [managed.dateObj indexOfObject:date(1)]);
    XCTAssertEqual(NSNotFound, [managed.decimalObj indexOfObject:decimal128(2)]);
    XCTAssertEqual(NSNotFound, [managed.objectIdObj indexOfObject:objectId(1)]);
    XCTAssertEqual(NSNotFound, [managed.uuidObj indexOfObject:uuid(@"00000000-0000-0000-0000-000000000000")]);
    XCTAssertEqual(NSNotFound, [managed.anyBoolObj indexOfObject:@NO]);
    XCTAssertEqual(NSNotFound, [managed.anyIntObj indexOfObject:@2]);
    XCTAssertEqual(NSNotFound, [managed.anyFloatObj indexOfObject:@2.2f]);
    XCTAssertEqual(NSNotFound, [managed.anyDoubleObj indexOfObject:@2.2]);
    XCTAssertEqual(NSNotFound, [managed.anyStringObj indexOfObject:@"a"]);
    XCTAssertEqual(NSNotFound, [managed.anyDataObj indexOfObject:data(1)]);
    XCTAssertEqual(NSNotFound, [managed.anyDateObj indexOfObject:date(1)]);
    XCTAssertEqual(NSNotFound, [managed.anyDecimalObj indexOfObject:decimal128(2)]);
    XCTAssertEqual(NSNotFound, [managed.anyObjectIdObj indexOfObject:objectId(1)]);
    XCTAssertEqual(NSNotFound, [managed.anyUUIDObj indexOfObject:uuid(@"00000000-0000-0000-0000-000000000000")]);
    XCTAssertEqual(NSNotFound, [optManaged.boolObj indexOfObject:@NO]);
    XCTAssertEqual(NSNotFound, [optManaged.intObj indexOfObject:@2]);
    XCTAssertEqual(NSNotFound, [optManaged.floatObj indexOfObject:@2.2f]);
    XCTAssertEqual(NSNotFound, [optManaged.doubleObj indexOfObject:@2.2]);
    XCTAssertEqual(NSNotFound, [optManaged.stringObj indexOfObject:@"a"]);
    XCTAssertEqual(NSNotFound, [optManaged.dataObj indexOfObject:data(1)]);
    XCTAssertEqual(NSNotFound, [optManaged.dateObj indexOfObject:date(1)]);
    XCTAssertEqual(NSNotFound, [optManaged.decimalObj indexOfObject:decimal128(2)]);
    XCTAssertEqual(NSNotFound, [optManaged.objectIdObj indexOfObject:objectId(1)]);
    XCTAssertEqual(NSNotFound, [optManaged.uuidObj indexOfObject:uuid(@"00000000-0000-0000-0000-000000000000")]);

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
    RLMAssertThrowsWithReason([unmanaged.uuidObj indexOfObject:@"a"],
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'uuid'");
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
    RLMAssertThrowsWithReason([optUnmanaged.uuidObj indexOfObject:@"a"],
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'uuid?'");
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
    RLMAssertThrowsWithReason([managed.uuidObj indexOfObject:@"a"],
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'uuid'");
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
    RLMAssertThrowsWithReason([optManaged.uuidObj indexOfObject:@"a"],
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'uuid?'");

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
    RLMAssertThrowsWithReason([unmanaged.uuidObj indexOfObject:NSNull.null],
                              @"Invalid value '<null>' of type 'NSNull' for expected type 'uuid'");
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
    RLMAssertThrowsWithReason([managed.uuidObj indexOfObject:NSNull.null],
                              @"Invalid value '<null>' of type 'NSNull' for expected type 'uuid'");
    XCTAssertEqual(NSNotFound, [optUnmanaged.boolObj indexOfObject:NSNull.null]);
    XCTAssertEqual(NSNotFound, [optUnmanaged.intObj indexOfObject:NSNull.null]);
    XCTAssertEqual(NSNotFound, [optUnmanaged.floatObj indexOfObject:NSNull.null]);
    XCTAssertEqual(NSNotFound, [optUnmanaged.doubleObj indexOfObject:NSNull.null]);
    XCTAssertEqual(NSNotFound, [optUnmanaged.stringObj indexOfObject:NSNull.null]);
    XCTAssertEqual(NSNotFound, [optUnmanaged.dataObj indexOfObject:NSNull.null]);
    XCTAssertEqual(NSNotFound, [optUnmanaged.dateObj indexOfObject:NSNull.null]);
    XCTAssertEqual(NSNotFound, [optUnmanaged.decimalObj indexOfObject:NSNull.null]);
    XCTAssertEqual(NSNotFound, [optUnmanaged.objectIdObj indexOfObject:NSNull.null]);
    XCTAssertEqual(NSNotFound, [optUnmanaged.uuidObj indexOfObject:NSNull.null]);
    XCTAssertEqual(NSNotFound, [optManaged.boolObj indexOfObject:NSNull.null]);
    XCTAssertEqual(NSNotFound, [optManaged.intObj indexOfObject:NSNull.null]);
    XCTAssertEqual(NSNotFound, [optManaged.floatObj indexOfObject:NSNull.null]);
    XCTAssertEqual(NSNotFound, [optManaged.doubleObj indexOfObject:NSNull.null]);
    XCTAssertEqual(NSNotFound, [optManaged.stringObj indexOfObject:NSNull.null]);
    XCTAssertEqual(NSNotFound, [optManaged.dataObj indexOfObject:NSNull.null]);
    XCTAssertEqual(NSNotFound, [optManaged.dateObj indexOfObject:NSNull.null]);
    XCTAssertEqual(NSNotFound, [optManaged.decimalObj indexOfObject:NSNull.null]);
    XCTAssertEqual(NSNotFound, [optManaged.objectIdObj indexOfObject:NSNull.null]);
    XCTAssertEqual(NSNotFound, [optManaged.uuidObj indexOfObject:NSNull.null]);

    [self addObjects];

    XCTAssertEqual(1U, [unmanaged.boolObj indexOfObject:@YES]);
    XCTAssertEqual(1U, [unmanaged.intObj indexOfObject:@3]);
    XCTAssertEqual(1U, [unmanaged.floatObj indexOfObject:@3.3f]);
    XCTAssertEqual(1U, [unmanaged.doubleObj indexOfObject:@3.3]);
    XCTAssertEqual(1U, [unmanaged.stringObj indexOfObject:@"b"]);
    XCTAssertEqual(1U, [unmanaged.dataObj indexOfObject:data(2)]);
    XCTAssertEqual(1U, [unmanaged.dateObj indexOfObject:date(2)]);
    XCTAssertEqual(1U, [unmanaged.decimalObj indexOfObject:decimal128(3)]);
    XCTAssertEqual(1U, [unmanaged.objectIdObj indexOfObject:objectId(2)]);
    XCTAssertEqual(1U, [unmanaged.uuidObj indexOfObject:uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")]);
    XCTAssertEqual(1U, [unmanaged.anyBoolObj indexOfObject:@YES]);
    XCTAssertEqual(1U, [unmanaged.anyIntObj indexOfObject:@3]);
    XCTAssertEqual(1U, [unmanaged.anyFloatObj indexOfObject:@3.3f]);
    XCTAssertEqual(1U, [unmanaged.anyDoubleObj indexOfObject:@3.3]);
    XCTAssertEqual(1U, [unmanaged.anyStringObj indexOfObject:@"b"]);
    XCTAssertEqual(1U, [unmanaged.anyDataObj indexOfObject:data(2)]);
    XCTAssertEqual(1U, [unmanaged.anyDateObj indexOfObject:date(2)]);
    XCTAssertEqual(1U, [unmanaged.anyDecimalObj indexOfObject:decimal128(3)]);
    XCTAssertEqual(1U, [unmanaged.anyObjectIdObj indexOfObject:objectId(2)]);
    XCTAssertEqual(1U, [unmanaged.anyUUIDObj indexOfObject:uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")]);
    XCTAssertEqual(1U, [optUnmanaged.boolObj indexOfObject:@YES]);
    XCTAssertEqual(1U, [optUnmanaged.intObj indexOfObject:@3]);
    XCTAssertEqual(1U, [optUnmanaged.floatObj indexOfObject:@3.3f]);
    XCTAssertEqual(1U, [optUnmanaged.doubleObj indexOfObject:@3.3]);
    XCTAssertEqual(1U, [optUnmanaged.stringObj indexOfObject:@"b"]);
    XCTAssertEqual(1U, [optUnmanaged.dataObj indexOfObject:data(2)]);
    XCTAssertEqual(1U, [optUnmanaged.dateObj indexOfObject:date(2)]);
    XCTAssertEqual(1U, [optUnmanaged.decimalObj indexOfObject:decimal128(3)]);
    XCTAssertEqual(1U, [optUnmanaged.objectIdObj indexOfObject:objectId(2)]);
    XCTAssertEqual(1U, [optUnmanaged.uuidObj indexOfObject:uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")]);
    XCTAssertEqual(1U, [managed.boolObj indexOfObject:@YES]);
    XCTAssertEqual(1U, [managed.intObj indexOfObject:@3]);
    XCTAssertEqual(1U, [managed.floatObj indexOfObject:@3.3f]);
    XCTAssertEqual(1U, [managed.doubleObj indexOfObject:@3.3]);
    XCTAssertEqual(1U, [managed.stringObj indexOfObject:@"b"]);
    XCTAssertEqual(1U, [managed.dataObj indexOfObject:data(2)]);
    XCTAssertEqual(1U, [managed.dateObj indexOfObject:date(2)]);
    XCTAssertEqual(1U, [managed.decimalObj indexOfObject:decimal128(3)]);
    XCTAssertEqual(1U, [managed.objectIdObj indexOfObject:objectId(2)]);
    XCTAssertEqual(1U, [managed.uuidObj indexOfObject:uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")]);
    XCTAssertEqual(1U, [managed.anyBoolObj indexOfObject:@YES]);
    XCTAssertEqual(1U, [managed.anyIntObj indexOfObject:@3]);
    XCTAssertEqual(1U, [managed.anyFloatObj indexOfObject:@3.3f]);
    XCTAssertEqual(1U, [managed.anyDoubleObj indexOfObject:@3.3]);
    XCTAssertEqual(1U, [managed.anyStringObj indexOfObject:@"b"]);
    XCTAssertEqual(1U, [managed.anyDataObj indexOfObject:data(2)]);
    XCTAssertEqual(1U, [managed.anyDateObj indexOfObject:date(2)]);
    XCTAssertEqual(1U, [managed.anyDecimalObj indexOfObject:decimal128(3)]);
    XCTAssertEqual(1U, [managed.anyObjectIdObj indexOfObject:objectId(2)]);
    XCTAssertEqual(1U, [managed.anyUUIDObj indexOfObject:uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")]);
    XCTAssertEqual(1U, [optManaged.boolObj indexOfObject:@YES]);
    XCTAssertEqual(1U, [optManaged.intObj indexOfObject:@3]);
    XCTAssertEqual(1U, [optManaged.floatObj indexOfObject:@3.3f]);
    XCTAssertEqual(1U, [optManaged.doubleObj indexOfObject:@3.3]);
    XCTAssertEqual(1U, [optManaged.stringObj indexOfObject:@"b"]);
    XCTAssertEqual(1U, [optManaged.dataObj indexOfObject:data(2)]);
    XCTAssertEqual(1U, [optManaged.dateObj indexOfObject:date(2)]);
    XCTAssertEqual(1U, [optManaged.decimalObj indexOfObject:decimal128(3)]);
    XCTAssertEqual(1U, [optManaged.objectIdObj indexOfObject:objectId(2)]);
    XCTAssertEqual(1U, [optManaged.uuidObj indexOfObject:uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")]);
}

- (void)testIndexOfObjectSorted {
    [managed.boolObj addObjects:@[@NO, @YES, @NO, @YES]];
    [managed.intObj addObjects:@[@2, @3, @2, @3]];
    [managed.floatObj addObjects:@[@2.2f, @3.3f, @2.2f, @3.3f]];
    [managed.doubleObj addObjects:@[@2.2, @3.3, @2.2, @3.3]];
    [managed.stringObj addObjects:@[@"a", @"b", @"a", @"b"]];
    [managed.dataObj addObjects:@[data(1), data(2), data(1), data(2)]];
    [managed.dateObj addObjects:@[date(1), date(2), date(1), date(2)]];
    [managed.decimalObj addObjects:@[decimal128(2), decimal128(3), decimal128(2), decimal128(3)]];
    [managed.objectIdObj addObjects:@[objectId(1), objectId(2), objectId(1), objectId(2)]];
    [managed.uuidObj addObjects:@[uuid(@"00000000-0000-0000-0000-000000000000"), uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"), uuid(@"00000000-0000-0000-0000-000000000000"), uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")]];
    [optManaged.boolObj addObjects:@[@NO, @YES, NSNull.null, @YES, @NO]];
    [optManaged.intObj addObjects:@[@2, @3, NSNull.null, @3, @2]];
    [optManaged.floatObj addObjects:@[@2.2f, @3.3f, NSNull.null, @3.3f, @2.2f]];
    [optManaged.doubleObj addObjects:@[@2.2, @3.3, NSNull.null, @3.3, @2.2]];
    [optManaged.stringObj addObjects:@[@"a", @"b", NSNull.null, @"b", @"a"]];
    [optManaged.dataObj addObjects:@[data(1), data(2), NSNull.null, data(2), data(1)]];
    [optManaged.dateObj addObjects:@[date(1), date(2), NSNull.null, date(2), date(1)]];
    [optManaged.decimalObj addObjects:@[decimal128(2), decimal128(3), NSNull.null, decimal128(3), decimal128(2)]];
    [optManaged.objectIdObj addObjects:@[objectId(1), objectId(2), NSNull.null, objectId(2), objectId(1)]];
    [optManaged.uuidObj addObjects:@[uuid(@"00000000-0000-0000-0000-000000000000"), uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"), NSNull.null, uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"), uuid(@"00000000-0000-0000-0000-000000000000")]];

    XCTAssertEqual(0U, [[managed.boolObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:@YES]);
    XCTAssertEqual(0U, [[managed.intObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:@3]);
    XCTAssertEqual(0U, [[managed.floatObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:@3.3f]);
    XCTAssertEqual(0U, [[managed.doubleObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:@3.3]);
    XCTAssertEqual(0U, [[managed.stringObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:@"b"]);
    XCTAssertEqual(0U, [[managed.dataObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:data(2)]);
    XCTAssertEqual(0U, [[managed.dateObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:date(2)]);
    XCTAssertEqual(0U, [[managed.decimalObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:decimal128(3)]);
    XCTAssertEqual(0U, [[managed.objectIdObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:objectId(2)]);
    XCTAssertEqual(0U, [[managed.uuidObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")]);
    XCTAssertEqual(2U, [[managed.boolObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:@NO]);
    XCTAssertEqual(2U, [[managed.intObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:@2]);
    XCTAssertEqual(2U, [[managed.floatObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:@2.2f]);
    XCTAssertEqual(2U, [[managed.doubleObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:@2.2]);
    XCTAssertEqual(2U, [[managed.stringObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:@"a"]);
    XCTAssertEqual(2U, [[managed.dataObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:data(1)]);
    XCTAssertEqual(2U, [[managed.dateObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:date(1)]);
    XCTAssertEqual(2U, [[managed.decimalObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:decimal128(2)]);
    XCTAssertEqual(2U, [[managed.objectIdObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:objectId(1)]);
    XCTAssertEqual(2U, [[managed.uuidObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:uuid(@"00000000-0000-0000-0000-000000000000")]);

    XCTAssertEqual(0U, [[optManaged.boolObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:@YES]);
    XCTAssertEqual(0U, [[optManaged.intObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:@3]);
    XCTAssertEqual(0U, [[optManaged.floatObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:@3.3f]);
    XCTAssertEqual(0U, [[optManaged.doubleObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:@3.3]);
    XCTAssertEqual(0U, [[optManaged.stringObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:@"b"]);
    XCTAssertEqual(0U, [[optManaged.dataObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:data(2)]);
    XCTAssertEqual(0U, [[optManaged.dateObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:date(2)]);
    XCTAssertEqual(0U, [[optManaged.decimalObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:decimal128(3)]);
    XCTAssertEqual(0U, [[optManaged.objectIdObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:objectId(2)]);
    XCTAssertEqual(0U, [[optManaged.uuidObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")]);
    XCTAssertEqual(2U, [[optManaged.boolObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:@NO]);
    XCTAssertEqual(2U, [[optManaged.intObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:@2]);
    XCTAssertEqual(2U, [[optManaged.floatObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:@2.2f]);
    XCTAssertEqual(2U, [[optManaged.doubleObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:@2.2]);
    XCTAssertEqual(2U, [[optManaged.stringObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:@"a"]);
    XCTAssertEqual(2U, [[optManaged.dataObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:data(1)]);
    XCTAssertEqual(2U, [[optManaged.dateObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:date(1)]);
    XCTAssertEqual(2U, [[optManaged.decimalObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:decimal128(2)]);
    XCTAssertEqual(2U, [[optManaged.objectIdObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:objectId(1)]);
    XCTAssertEqual(2U, [[optManaged.uuidObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:uuid(@"00000000-0000-0000-0000-000000000000")]);
    XCTAssertEqual(4U, [[optManaged.boolObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:NSNull.null]);
    XCTAssertEqual(4U, [[optManaged.intObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:NSNull.null]);
    XCTAssertEqual(4U, [[optManaged.floatObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:NSNull.null]);
    XCTAssertEqual(4U, [[optManaged.doubleObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:NSNull.null]);
    XCTAssertEqual(4U, [[optManaged.stringObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:NSNull.null]);
    XCTAssertEqual(4U, [[optManaged.dataObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:NSNull.null]);
    XCTAssertEqual(4U, [[optManaged.dateObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:NSNull.null]);
    XCTAssertEqual(4U, [[optManaged.decimalObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:NSNull.null]);
    XCTAssertEqual(4U, [[optManaged.objectIdObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:NSNull.null]);
    XCTAssertEqual(4U, [[optManaged.uuidObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:NSNull.null]);
}

- (void)testIndexOfObjectDistinct {
    [managed.boolObj addObjects:@[@NO, @NO, @YES]];
    [managed.intObj addObjects:@[@2, @2, @3]];
    [managed.floatObj addObjects:@[@2.2f, @2.2f, @3.3f]];
    [managed.doubleObj addObjects:@[@2.2, @2.2, @3.3]];
    [managed.stringObj addObjects:@[@"a", @"a", @"b"]];
    [managed.dataObj addObjects:@[data(1), data(1), data(2)]];
    [managed.dateObj addObjects:@[date(1), date(1), date(2)]];
    [managed.decimalObj addObjects:@[decimal128(2), decimal128(2), decimal128(3)]];
    [managed.objectIdObj addObjects:@[objectId(1), objectId(1), objectId(2)]];
    [managed.uuidObj addObjects:@[uuid(@"00000000-0000-0000-0000-000000000000"), uuid(@"00000000-0000-0000-0000-000000000000"), uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")]];
    [optManaged.boolObj addObjects:@[@NO, @NO, NSNull.null, @YES, @NO]];
    [optManaged.intObj addObjects:@[@2, @2, NSNull.null, @3, @2]];
    [optManaged.floatObj addObjects:@[@2.2f, @2.2f, NSNull.null, @3.3f, @2.2f]];
    [optManaged.doubleObj addObjects:@[@2.2, @2.2, NSNull.null, @3.3, @2.2]];
    [optManaged.stringObj addObjects:@[@"a", @"a", NSNull.null, @"b", @"a"]];
    [optManaged.dataObj addObjects:@[data(1), data(1), NSNull.null, data(2), data(1)]];
    [optManaged.dateObj addObjects:@[date(1), date(1), NSNull.null, date(2), date(1)]];
    [optManaged.decimalObj addObjects:@[decimal128(2), decimal128(2), NSNull.null, decimal128(3), decimal128(2)]];
    [optManaged.objectIdObj addObjects:@[objectId(1), objectId(1), NSNull.null, objectId(2), objectId(1)]];
    [optManaged.uuidObj addObjects:@[uuid(@"00000000-0000-0000-0000-000000000000"), uuid(@"00000000-0000-0000-0000-000000000000"), NSNull.null, uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"), uuid(@"00000000-0000-0000-0000-000000000000")]];

    XCTAssertEqual(0U, [[managed.boolObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:@NO]);
    XCTAssertEqual(0U, [[managed.intObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:@2]);
    XCTAssertEqual(0U, [[managed.floatObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:@2.2f]);
    XCTAssertEqual(0U, [[managed.doubleObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:@2.2]);
    XCTAssertEqual(0U, [[managed.stringObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:@"a"]);
    XCTAssertEqual(0U, [[managed.dataObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:data(1)]);
    XCTAssertEqual(0U, [[managed.dateObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:date(1)]);
    XCTAssertEqual(0U, [[managed.decimalObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:decimal128(2)]);
    XCTAssertEqual(0U, [[managed.objectIdObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:objectId(1)]);
    XCTAssertEqual(0U, [[managed.uuidObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:uuid(@"00000000-0000-0000-0000-000000000000")]);
    XCTAssertEqual(1U, [[managed.boolObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:@YES]);
    XCTAssertEqual(1U, [[managed.intObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:@3]);
    XCTAssertEqual(1U, [[managed.floatObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:@3.3f]);
    XCTAssertEqual(1U, [[managed.doubleObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:@3.3]);
    XCTAssertEqual(1U, [[managed.stringObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:@"b"]);
    XCTAssertEqual(1U, [[managed.dataObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:data(2)]);
    XCTAssertEqual(1U, [[managed.dateObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:date(2)]);
    XCTAssertEqual(1U, [[managed.decimalObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:decimal128(3)]);
    XCTAssertEqual(1U, [[managed.objectIdObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:objectId(2)]);
    XCTAssertEqual(1U, [[managed.uuidObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")]);

    XCTAssertEqual(0U, [[optManaged.boolObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:@NO]);
    XCTAssertEqual(0U, [[optManaged.intObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:@2]);
    XCTAssertEqual(0U, [[optManaged.floatObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:@2.2f]);
    XCTAssertEqual(0U, [[optManaged.doubleObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:@2.2]);
    XCTAssertEqual(0U, [[optManaged.stringObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:@"a"]);
    XCTAssertEqual(0U, [[optManaged.dataObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:data(1)]);
    XCTAssertEqual(0U, [[optManaged.dateObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:date(1)]);
    XCTAssertEqual(0U, [[optManaged.decimalObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:decimal128(2)]);
    XCTAssertEqual(0U, [[optManaged.objectIdObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:objectId(1)]);
    XCTAssertEqual(0U, [[optManaged.uuidObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:uuid(@"00000000-0000-0000-0000-000000000000")]);
    XCTAssertEqual(2U, [[optManaged.boolObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:@YES]);
    XCTAssertEqual(2U, [[optManaged.intObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:@3]);
    XCTAssertEqual(2U, [[optManaged.floatObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:@3.3f]);
    XCTAssertEqual(2U, [[optManaged.doubleObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:@3.3]);
    XCTAssertEqual(2U, [[optManaged.stringObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:@"b"]);
    XCTAssertEqual(2U, [[optManaged.dataObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:data(2)]);
    XCTAssertEqual(2U, [[optManaged.dateObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:date(2)]);
    XCTAssertEqual(2U, [[optManaged.decimalObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:decimal128(3)]);
    XCTAssertEqual(2U, [[optManaged.objectIdObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:objectId(2)]);
    XCTAssertEqual(2U, [[optManaged.uuidObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")]);
    XCTAssertEqual(1U, [[optManaged.boolObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:NSNull.null]);
    XCTAssertEqual(1U, [[optManaged.intObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:NSNull.null]);
    XCTAssertEqual(1U, [[optManaged.floatObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:NSNull.null]);
    XCTAssertEqual(1U, [[optManaged.doubleObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:NSNull.null]);
    XCTAssertEqual(1U, [[optManaged.stringObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:NSNull.null]);
    XCTAssertEqual(1U, [[optManaged.dataObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:NSNull.null]);
    XCTAssertEqual(1U, [[optManaged.dateObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:NSNull.null]);
    XCTAssertEqual(1U, [[optManaged.decimalObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:NSNull.null]);
    XCTAssertEqual(1U, [[optManaged.objectIdObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:NSNull.null]);
    XCTAssertEqual(1U, [[optManaged.uuidObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:NSNull.null]);
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
    RLMAssertThrowsWithReason([managed.uuidObj indexOfObjectWhere:@"TRUEPREDICATE"], @"implemented");
    RLMAssertThrowsWithReason([managed.anyBoolObj indexOfObjectWhere:@"TRUEPREDICATE"], @"implemented");
    RLMAssertThrowsWithReason([managed.anyIntObj indexOfObjectWhere:@"TRUEPREDICATE"], @"implemented");
    RLMAssertThrowsWithReason([managed.anyFloatObj indexOfObjectWhere:@"TRUEPREDICATE"], @"implemented");
    RLMAssertThrowsWithReason([managed.anyDoubleObj indexOfObjectWhere:@"TRUEPREDICATE"], @"implemented");
    RLMAssertThrowsWithReason([managed.anyStringObj indexOfObjectWhere:@"TRUEPREDICATE"], @"implemented");
    RLMAssertThrowsWithReason([managed.anyDataObj indexOfObjectWhere:@"TRUEPREDICATE"], @"implemented");
    RLMAssertThrowsWithReason([managed.anyDateObj indexOfObjectWhere:@"TRUEPREDICATE"], @"implemented");
    RLMAssertThrowsWithReason([managed.anyDecimalObj indexOfObjectWhere:@"TRUEPREDICATE"], @"implemented");
    RLMAssertThrowsWithReason([managed.anyObjectIdObj indexOfObjectWhere:@"TRUEPREDICATE"], @"implemented");
    RLMAssertThrowsWithReason([managed.anyUUIDObj indexOfObjectWhere:@"TRUEPREDICATE"], @"implemented");
    RLMAssertThrowsWithReason([optManaged.boolObj indexOfObjectWhere:@"TRUEPREDICATE"], @"implemented");
    RLMAssertThrowsWithReason([optManaged.intObj indexOfObjectWhere:@"TRUEPREDICATE"], @"implemented");
    RLMAssertThrowsWithReason([optManaged.floatObj indexOfObjectWhere:@"TRUEPREDICATE"], @"implemented");
    RLMAssertThrowsWithReason([optManaged.doubleObj indexOfObjectWhere:@"TRUEPREDICATE"], @"implemented");
    RLMAssertThrowsWithReason([optManaged.stringObj indexOfObjectWhere:@"TRUEPREDICATE"], @"implemented");
    RLMAssertThrowsWithReason([optManaged.dataObj indexOfObjectWhere:@"TRUEPREDICATE"], @"implemented");
    RLMAssertThrowsWithReason([optManaged.dateObj indexOfObjectWhere:@"TRUEPREDICATE"], @"implemented");
    RLMAssertThrowsWithReason([optManaged.decimalObj indexOfObjectWhere:@"TRUEPREDICATE"], @"implemented");
    RLMAssertThrowsWithReason([optManaged.objectIdObj indexOfObjectWhere:@"TRUEPREDICATE"], @"implemented");
    RLMAssertThrowsWithReason([optManaged.uuidObj indexOfObjectWhere:@"TRUEPREDICATE"], @"implemented");
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
    RLMAssertThrowsWithReason([[managed.uuidObj sortedResultsUsingKeyPath:@"self" ascending:NO]
                               indexOfObjectWhere:@"TRUEPREDICATE"], @"implemented");
    RLMAssertThrowsWithReason([[managed.anyBoolObj sortedResultsUsingKeyPath:@"self" ascending:NO]
                               indexOfObjectWhere:@"TRUEPREDICATE"], @"implemented");
    RLMAssertThrowsWithReason([[managed.anyIntObj sortedResultsUsingKeyPath:@"self" ascending:NO]
                               indexOfObjectWhere:@"TRUEPREDICATE"], @"implemented");
    RLMAssertThrowsWithReason([[managed.anyFloatObj sortedResultsUsingKeyPath:@"self" ascending:NO]
                               indexOfObjectWhere:@"TRUEPREDICATE"], @"implemented");
    RLMAssertThrowsWithReason([[managed.anyDoubleObj sortedResultsUsingKeyPath:@"self" ascending:NO]
                               indexOfObjectWhere:@"TRUEPREDICATE"], @"implemented");
    RLMAssertThrowsWithReason([[managed.anyStringObj sortedResultsUsingKeyPath:@"self" ascending:NO]
                               indexOfObjectWhere:@"TRUEPREDICATE"], @"implemented");
    RLMAssertThrowsWithReason([[managed.anyDataObj sortedResultsUsingKeyPath:@"self" ascending:NO]
                               indexOfObjectWhere:@"TRUEPREDICATE"], @"implemented");
    RLMAssertThrowsWithReason([[managed.anyDateObj sortedResultsUsingKeyPath:@"self" ascending:NO]
                               indexOfObjectWhere:@"TRUEPREDICATE"], @"implemented");
    RLMAssertThrowsWithReason([[managed.anyDecimalObj sortedResultsUsingKeyPath:@"self" ascending:NO]
                               indexOfObjectWhere:@"TRUEPREDICATE"], @"implemented");
    RLMAssertThrowsWithReason([[managed.anyObjectIdObj sortedResultsUsingKeyPath:@"self" ascending:NO]
                               indexOfObjectWhere:@"TRUEPREDICATE"], @"implemented");
    RLMAssertThrowsWithReason([[managed.anyUUIDObj sortedResultsUsingKeyPath:@"self" ascending:NO]
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
    RLMAssertThrowsWithReason([[optManaged.uuidObj sortedResultsUsingKeyPath:@"self" ascending:NO]
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
    XCTAssertEqual(NSNotFound, [unmanaged.uuidObj indexOfObjectWhere:@"TRUEPREDICATE"]);
    XCTAssertEqual(NSNotFound, [unmanaged.anyBoolObj indexOfObjectWhere:@"TRUEPREDICATE"]);
    XCTAssertEqual(NSNotFound, [unmanaged.anyIntObj indexOfObjectWhere:@"TRUEPREDICATE"]);
    XCTAssertEqual(NSNotFound, [unmanaged.anyFloatObj indexOfObjectWhere:@"TRUEPREDICATE"]);
    XCTAssertEqual(NSNotFound, [unmanaged.anyDoubleObj indexOfObjectWhere:@"TRUEPREDICATE"]);
    XCTAssertEqual(NSNotFound, [unmanaged.anyStringObj indexOfObjectWhere:@"TRUEPREDICATE"]);
    XCTAssertEqual(NSNotFound, [unmanaged.anyDataObj indexOfObjectWhere:@"TRUEPREDICATE"]);
    XCTAssertEqual(NSNotFound, [unmanaged.anyDateObj indexOfObjectWhere:@"TRUEPREDICATE"]);
    XCTAssertEqual(NSNotFound, [unmanaged.anyDecimalObj indexOfObjectWhere:@"TRUEPREDICATE"]);
    XCTAssertEqual(NSNotFound, [unmanaged.anyObjectIdObj indexOfObjectWhere:@"TRUEPREDICATE"]);
    XCTAssertEqual(NSNotFound, [unmanaged.anyUUIDObj indexOfObjectWhere:@"TRUEPREDICATE"]);
    XCTAssertEqual(NSNotFound, [optUnmanaged.boolObj indexOfObjectWhere:@"TRUEPREDICATE"]);
    XCTAssertEqual(NSNotFound, [optUnmanaged.intObj indexOfObjectWhere:@"TRUEPREDICATE"]);
    XCTAssertEqual(NSNotFound, [optUnmanaged.floatObj indexOfObjectWhere:@"TRUEPREDICATE"]);
    XCTAssertEqual(NSNotFound, [optUnmanaged.doubleObj indexOfObjectWhere:@"TRUEPREDICATE"]);
    XCTAssertEqual(NSNotFound, [optUnmanaged.stringObj indexOfObjectWhere:@"TRUEPREDICATE"]);
    XCTAssertEqual(NSNotFound, [optUnmanaged.dataObj indexOfObjectWhere:@"TRUEPREDICATE"]);
    XCTAssertEqual(NSNotFound, [optUnmanaged.dateObj indexOfObjectWhere:@"TRUEPREDICATE"]);
    XCTAssertEqual(NSNotFound, [optUnmanaged.decimalObj indexOfObjectWhere:@"TRUEPREDICATE"]);
    XCTAssertEqual(NSNotFound, [optUnmanaged.objectIdObj indexOfObjectWhere:@"TRUEPREDICATE"]);
    XCTAssertEqual(NSNotFound, [optUnmanaged.uuidObj indexOfObjectWhere:@"TRUEPREDICATE"]);

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
    XCTAssertEqual(0U, [unmanaged.uuidObj indexOfObjectWhere:@"TRUEPREDICATE"]);
    XCTAssertEqual(0U, [unmanaged.anyBoolObj indexOfObjectWhere:@"TRUEPREDICATE"]);
    XCTAssertEqual(0U, [unmanaged.anyIntObj indexOfObjectWhere:@"TRUEPREDICATE"]);
    XCTAssertEqual(0U, [unmanaged.anyFloatObj indexOfObjectWhere:@"TRUEPREDICATE"]);
    XCTAssertEqual(0U, [unmanaged.anyDoubleObj indexOfObjectWhere:@"TRUEPREDICATE"]);
    XCTAssertEqual(0U, [unmanaged.anyStringObj indexOfObjectWhere:@"TRUEPREDICATE"]);
    XCTAssertEqual(0U, [unmanaged.anyDataObj indexOfObjectWhere:@"TRUEPREDICATE"]);
    XCTAssertEqual(0U, [unmanaged.anyDateObj indexOfObjectWhere:@"TRUEPREDICATE"]);
    XCTAssertEqual(0U, [unmanaged.anyDecimalObj indexOfObjectWhere:@"TRUEPREDICATE"]);
    XCTAssertEqual(0U, [unmanaged.anyObjectIdObj indexOfObjectWhere:@"TRUEPREDICATE"]);
    XCTAssertEqual(0U, [unmanaged.anyUUIDObj indexOfObjectWhere:@"TRUEPREDICATE"]);
    XCTAssertEqual(0U, [optUnmanaged.boolObj indexOfObjectWhere:@"TRUEPREDICATE"]);
    XCTAssertEqual(0U, [optUnmanaged.intObj indexOfObjectWhere:@"TRUEPREDICATE"]);
    XCTAssertEqual(0U, [optUnmanaged.floatObj indexOfObjectWhere:@"TRUEPREDICATE"]);
    XCTAssertEqual(0U, [optUnmanaged.doubleObj indexOfObjectWhere:@"TRUEPREDICATE"]);
    XCTAssertEqual(0U, [optUnmanaged.stringObj indexOfObjectWhere:@"TRUEPREDICATE"]);
    XCTAssertEqual(0U, [optUnmanaged.dataObj indexOfObjectWhere:@"TRUEPREDICATE"]);
    XCTAssertEqual(0U, [optUnmanaged.dateObj indexOfObjectWhere:@"TRUEPREDICATE"]);
    XCTAssertEqual(0U, [optUnmanaged.decimalObj indexOfObjectWhere:@"TRUEPREDICATE"]);
    XCTAssertEqual(0U, [optUnmanaged.objectIdObj indexOfObjectWhere:@"TRUEPREDICATE"]);
    XCTAssertEqual(0U, [optUnmanaged.uuidObj indexOfObjectWhere:@"TRUEPREDICATE"]);
    XCTAssertEqual(NSNotFound, [unmanaged.boolObj indexOfObjectWhere:@"FALSEPREDICATE"]);
    XCTAssertEqual(NSNotFound, [unmanaged.intObj indexOfObjectWhere:@"FALSEPREDICATE"]);
    XCTAssertEqual(NSNotFound, [unmanaged.floatObj indexOfObjectWhere:@"FALSEPREDICATE"]);
    XCTAssertEqual(NSNotFound, [unmanaged.doubleObj indexOfObjectWhere:@"FALSEPREDICATE"]);
    XCTAssertEqual(NSNotFound, [unmanaged.stringObj indexOfObjectWhere:@"FALSEPREDICATE"]);
    XCTAssertEqual(NSNotFound, [unmanaged.dataObj indexOfObjectWhere:@"FALSEPREDICATE"]);
    XCTAssertEqual(NSNotFound, [unmanaged.dateObj indexOfObjectWhere:@"FALSEPREDICATE"]);
    XCTAssertEqual(NSNotFound, [unmanaged.decimalObj indexOfObjectWhere:@"FALSEPREDICATE"]);
    XCTAssertEqual(NSNotFound, [unmanaged.objectIdObj indexOfObjectWhere:@"FALSEPREDICATE"]);
    XCTAssertEqual(NSNotFound, [unmanaged.uuidObj indexOfObjectWhere:@"FALSEPREDICATE"]);
    XCTAssertEqual(NSNotFound, [unmanaged.anyBoolObj indexOfObjectWhere:@"FALSEPREDICATE"]);
    XCTAssertEqual(NSNotFound, [unmanaged.anyIntObj indexOfObjectWhere:@"FALSEPREDICATE"]);
    XCTAssertEqual(NSNotFound, [unmanaged.anyFloatObj indexOfObjectWhere:@"FALSEPREDICATE"]);
    XCTAssertEqual(NSNotFound, [unmanaged.anyDoubleObj indexOfObjectWhere:@"FALSEPREDICATE"]);
    XCTAssertEqual(NSNotFound, [unmanaged.anyStringObj indexOfObjectWhere:@"FALSEPREDICATE"]);
    XCTAssertEqual(NSNotFound, [unmanaged.anyDataObj indexOfObjectWhere:@"FALSEPREDICATE"]);
    XCTAssertEqual(NSNotFound, [unmanaged.anyDateObj indexOfObjectWhere:@"FALSEPREDICATE"]);
    XCTAssertEqual(NSNotFound, [unmanaged.anyDecimalObj indexOfObjectWhere:@"FALSEPREDICATE"]);
    XCTAssertEqual(NSNotFound, [unmanaged.anyObjectIdObj indexOfObjectWhere:@"FALSEPREDICATE"]);
    XCTAssertEqual(NSNotFound, [unmanaged.anyUUIDObj indexOfObjectWhere:@"FALSEPREDICATE"]);
    XCTAssertEqual(NSNotFound, [optUnmanaged.boolObj indexOfObjectWhere:@"FALSEPREDICATE"]);
    XCTAssertEqual(NSNotFound, [optUnmanaged.intObj indexOfObjectWhere:@"FALSEPREDICATE"]);
    XCTAssertEqual(NSNotFound, [optUnmanaged.floatObj indexOfObjectWhere:@"FALSEPREDICATE"]);
    XCTAssertEqual(NSNotFound, [optUnmanaged.doubleObj indexOfObjectWhere:@"FALSEPREDICATE"]);
    XCTAssertEqual(NSNotFound, [optUnmanaged.stringObj indexOfObjectWhere:@"FALSEPREDICATE"]);
    XCTAssertEqual(NSNotFound, [optUnmanaged.dataObj indexOfObjectWhere:@"FALSEPREDICATE"]);
    XCTAssertEqual(NSNotFound, [optUnmanaged.dateObj indexOfObjectWhere:@"FALSEPREDICATE"]);
    XCTAssertEqual(NSNotFound, [optUnmanaged.decimalObj indexOfObjectWhere:@"FALSEPREDICATE"]);
    XCTAssertEqual(NSNotFound, [optUnmanaged.objectIdObj indexOfObjectWhere:@"FALSEPREDICATE"]);
    XCTAssertEqual(NSNotFound, [optUnmanaged.uuidObj indexOfObjectWhere:@"FALSEPREDICATE"]);
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
    RLMAssertThrowsWithReason([managed.uuidObj indexOfObjectWithPredicate:[NSPredicate predicateWithValue:YES]], @"implemented");
    RLMAssertThrowsWithReason([managed.anyBoolObj indexOfObjectWithPredicate:[NSPredicate predicateWithValue:YES]], @"implemented");
    RLMAssertThrowsWithReason([managed.anyIntObj indexOfObjectWithPredicate:[NSPredicate predicateWithValue:YES]], @"implemented");
    RLMAssertThrowsWithReason([managed.anyFloatObj indexOfObjectWithPredicate:[NSPredicate predicateWithValue:YES]], @"implemented");
    RLMAssertThrowsWithReason([managed.anyDoubleObj indexOfObjectWithPredicate:[NSPredicate predicateWithValue:YES]], @"implemented");
    RLMAssertThrowsWithReason([managed.anyStringObj indexOfObjectWithPredicate:[NSPredicate predicateWithValue:YES]], @"implemented");
    RLMAssertThrowsWithReason([managed.anyDataObj indexOfObjectWithPredicate:[NSPredicate predicateWithValue:YES]], @"implemented");
    RLMAssertThrowsWithReason([managed.anyDateObj indexOfObjectWithPredicate:[NSPredicate predicateWithValue:YES]], @"implemented");
    RLMAssertThrowsWithReason([managed.anyDecimalObj indexOfObjectWithPredicate:[NSPredicate predicateWithValue:YES]], @"implemented");
    RLMAssertThrowsWithReason([managed.anyObjectIdObj indexOfObjectWithPredicate:[NSPredicate predicateWithValue:YES]], @"implemented");
    RLMAssertThrowsWithReason([managed.anyUUIDObj indexOfObjectWithPredicate:[NSPredicate predicateWithValue:YES]], @"implemented");
    RLMAssertThrowsWithReason([optManaged.boolObj indexOfObjectWithPredicate:[NSPredicate predicateWithValue:YES]], @"implemented");
    RLMAssertThrowsWithReason([optManaged.intObj indexOfObjectWithPredicate:[NSPredicate predicateWithValue:YES]], @"implemented");
    RLMAssertThrowsWithReason([optManaged.floatObj indexOfObjectWithPredicate:[NSPredicate predicateWithValue:YES]], @"implemented");
    RLMAssertThrowsWithReason([optManaged.doubleObj indexOfObjectWithPredicate:[NSPredicate predicateWithValue:YES]], @"implemented");
    RLMAssertThrowsWithReason([optManaged.stringObj indexOfObjectWithPredicate:[NSPredicate predicateWithValue:YES]], @"implemented");
    RLMAssertThrowsWithReason([optManaged.dataObj indexOfObjectWithPredicate:[NSPredicate predicateWithValue:YES]], @"implemented");
    RLMAssertThrowsWithReason([optManaged.dateObj indexOfObjectWithPredicate:[NSPredicate predicateWithValue:YES]], @"implemented");
    RLMAssertThrowsWithReason([optManaged.decimalObj indexOfObjectWithPredicate:[NSPredicate predicateWithValue:YES]], @"implemented");
    RLMAssertThrowsWithReason([optManaged.objectIdObj indexOfObjectWithPredicate:[NSPredicate predicateWithValue:YES]], @"implemented");
    RLMAssertThrowsWithReason([optManaged.uuidObj indexOfObjectWithPredicate:[NSPredicate predicateWithValue:YES]], @"implemented");
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
    RLMAssertThrowsWithReason([[managed.uuidObj sortedResultsUsingKeyPath:@"self" ascending:NO]
                               indexOfObjectWithPredicate:[NSPredicate predicateWithValue:YES]], @"implemented");
    RLMAssertThrowsWithReason([[managed.anyBoolObj sortedResultsUsingKeyPath:@"self" ascending:NO]
                               indexOfObjectWithPredicate:[NSPredicate predicateWithValue:YES]], @"implemented");
    RLMAssertThrowsWithReason([[managed.anyIntObj sortedResultsUsingKeyPath:@"self" ascending:NO]
                               indexOfObjectWithPredicate:[NSPredicate predicateWithValue:YES]], @"implemented");
    RLMAssertThrowsWithReason([[managed.anyFloatObj sortedResultsUsingKeyPath:@"self" ascending:NO]
                               indexOfObjectWithPredicate:[NSPredicate predicateWithValue:YES]], @"implemented");
    RLMAssertThrowsWithReason([[managed.anyDoubleObj sortedResultsUsingKeyPath:@"self" ascending:NO]
                               indexOfObjectWithPredicate:[NSPredicate predicateWithValue:YES]], @"implemented");
    RLMAssertThrowsWithReason([[managed.anyStringObj sortedResultsUsingKeyPath:@"self" ascending:NO]
                               indexOfObjectWithPredicate:[NSPredicate predicateWithValue:YES]], @"implemented");
    RLMAssertThrowsWithReason([[managed.anyDataObj sortedResultsUsingKeyPath:@"self" ascending:NO]
                               indexOfObjectWithPredicate:[NSPredicate predicateWithValue:YES]], @"implemented");
    RLMAssertThrowsWithReason([[managed.anyDateObj sortedResultsUsingKeyPath:@"self" ascending:NO]
                               indexOfObjectWithPredicate:[NSPredicate predicateWithValue:YES]], @"implemented");
    RLMAssertThrowsWithReason([[managed.anyDecimalObj sortedResultsUsingKeyPath:@"self" ascending:NO]
                               indexOfObjectWithPredicate:[NSPredicate predicateWithValue:YES]], @"implemented");
    RLMAssertThrowsWithReason([[managed.anyObjectIdObj sortedResultsUsingKeyPath:@"self" ascending:NO]
                               indexOfObjectWithPredicate:[NSPredicate predicateWithValue:YES]], @"implemented");
    RLMAssertThrowsWithReason([[managed.anyUUIDObj sortedResultsUsingKeyPath:@"self" ascending:NO]
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
    RLMAssertThrowsWithReason([[optManaged.uuidObj sortedResultsUsingKeyPath:@"self" ascending:NO]
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
    XCTAssertEqual(NSNotFound, [unmanaged.uuidObj indexOfObjectWithPredicate:[NSPredicate predicateWithValue:YES]]);
    XCTAssertEqual(NSNotFound, [unmanaged.anyBoolObj indexOfObjectWithPredicate:[NSPredicate predicateWithValue:YES]]);
    XCTAssertEqual(NSNotFound, [unmanaged.anyIntObj indexOfObjectWithPredicate:[NSPredicate predicateWithValue:YES]]);
    XCTAssertEqual(NSNotFound, [unmanaged.anyFloatObj indexOfObjectWithPredicate:[NSPredicate predicateWithValue:YES]]);
    XCTAssertEqual(NSNotFound, [unmanaged.anyDoubleObj indexOfObjectWithPredicate:[NSPredicate predicateWithValue:YES]]);
    XCTAssertEqual(NSNotFound, [unmanaged.anyStringObj indexOfObjectWithPredicate:[NSPredicate predicateWithValue:YES]]);
    XCTAssertEqual(NSNotFound, [unmanaged.anyDataObj indexOfObjectWithPredicate:[NSPredicate predicateWithValue:YES]]);
    XCTAssertEqual(NSNotFound, [unmanaged.anyDateObj indexOfObjectWithPredicate:[NSPredicate predicateWithValue:YES]]);
    XCTAssertEqual(NSNotFound, [unmanaged.anyDecimalObj indexOfObjectWithPredicate:[NSPredicate predicateWithValue:YES]]);
    XCTAssertEqual(NSNotFound, [unmanaged.anyObjectIdObj indexOfObjectWithPredicate:[NSPredicate predicateWithValue:YES]]);
    XCTAssertEqual(NSNotFound, [unmanaged.anyUUIDObj indexOfObjectWithPredicate:[NSPredicate predicateWithValue:YES]]);
    XCTAssertEqual(NSNotFound, [optUnmanaged.boolObj indexOfObjectWithPredicate:[NSPredicate predicateWithValue:YES]]);
    XCTAssertEqual(NSNotFound, [optUnmanaged.intObj indexOfObjectWithPredicate:[NSPredicate predicateWithValue:YES]]);
    XCTAssertEqual(NSNotFound, [optUnmanaged.floatObj indexOfObjectWithPredicate:[NSPredicate predicateWithValue:YES]]);
    XCTAssertEqual(NSNotFound, [optUnmanaged.doubleObj indexOfObjectWithPredicate:[NSPredicate predicateWithValue:YES]]);
    XCTAssertEqual(NSNotFound, [optUnmanaged.stringObj indexOfObjectWithPredicate:[NSPredicate predicateWithValue:YES]]);
    XCTAssertEqual(NSNotFound, [optUnmanaged.dataObj indexOfObjectWithPredicate:[NSPredicate predicateWithValue:YES]]);
    XCTAssertEqual(NSNotFound, [optUnmanaged.dateObj indexOfObjectWithPredicate:[NSPredicate predicateWithValue:YES]]);
    XCTAssertEqual(NSNotFound, [optUnmanaged.decimalObj indexOfObjectWithPredicate:[NSPredicate predicateWithValue:YES]]);
    XCTAssertEqual(NSNotFound, [optUnmanaged.objectIdObj indexOfObjectWithPredicate:[NSPredicate predicateWithValue:YES]]);
    XCTAssertEqual(NSNotFound, [optUnmanaged.uuidObj indexOfObjectWithPredicate:[NSPredicate predicateWithValue:YES]]);

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
    XCTAssertEqual(0U, [unmanaged.uuidObj indexOfObjectWithPredicate:[NSPredicate predicateWithValue:YES]]);
    XCTAssertEqual(0U, [unmanaged.anyBoolObj indexOfObjectWithPredicate:[NSPredicate predicateWithValue:YES]]);
    XCTAssertEqual(0U, [unmanaged.anyIntObj indexOfObjectWithPredicate:[NSPredicate predicateWithValue:YES]]);
    XCTAssertEqual(0U, [unmanaged.anyFloatObj indexOfObjectWithPredicate:[NSPredicate predicateWithValue:YES]]);
    XCTAssertEqual(0U, [unmanaged.anyDoubleObj indexOfObjectWithPredicate:[NSPredicate predicateWithValue:YES]]);
    XCTAssertEqual(0U, [unmanaged.anyStringObj indexOfObjectWithPredicate:[NSPredicate predicateWithValue:YES]]);
    XCTAssertEqual(0U, [unmanaged.anyDataObj indexOfObjectWithPredicate:[NSPredicate predicateWithValue:YES]]);
    XCTAssertEqual(0U, [unmanaged.anyDateObj indexOfObjectWithPredicate:[NSPredicate predicateWithValue:YES]]);
    XCTAssertEqual(0U, [unmanaged.anyDecimalObj indexOfObjectWithPredicate:[NSPredicate predicateWithValue:YES]]);
    XCTAssertEqual(0U, [unmanaged.anyObjectIdObj indexOfObjectWithPredicate:[NSPredicate predicateWithValue:YES]]);
    XCTAssertEqual(0U, [unmanaged.anyUUIDObj indexOfObjectWithPredicate:[NSPredicate predicateWithValue:YES]]);
    XCTAssertEqual(0U, [optUnmanaged.boolObj indexOfObjectWithPredicate:[NSPredicate predicateWithValue:YES]]);
    XCTAssertEqual(0U, [optUnmanaged.intObj indexOfObjectWithPredicate:[NSPredicate predicateWithValue:YES]]);
    XCTAssertEqual(0U, [optUnmanaged.floatObj indexOfObjectWithPredicate:[NSPredicate predicateWithValue:YES]]);
    XCTAssertEqual(0U, [optUnmanaged.doubleObj indexOfObjectWithPredicate:[NSPredicate predicateWithValue:YES]]);
    XCTAssertEqual(0U, [optUnmanaged.stringObj indexOfObjectWithPredicate:[NSPredicate predicateWithValue:YES]]);
    XCTAssertEqual(0U, [optUnmanaged.dataObj indexOfObjectWithPredicate:[NSPredicate predicateWithValue:YES]]);
    XCTAssertEqual(0U, [optUnmanaged.dateObj indexOfObjectWithPredicate:[NSPredicate predicateWithValue:YES]]);
    XCTAssertEqual(0U, [optUnmanaged.decimalObj indexOfObjectWithPredicate:[NSPredicate predicateWithValue:YES]]);
    XCTAssertEqual(0U, [optUnmanaged.objectIdObj indexOfObjectWithPredicate:[NSPredicate predicateWithValue:YES]]);
    XCTAssertEqual(0U, [optUnmanaged.uuidObj indexOfObjectWithPredicate:[NSPredicate predicateWithValue:YES]]);
    XCTAssertEqual(NSNotFound, [unmanaged.boolObj indexOfObjectWithPredicate:[NSPredicate predicateWithValue:NO]]);
    XCTAssertEqual(NSNotFound, [unmanaged.intObj indexOfObjectWithPredicate:[NSPredicate predicateWithValue:NO]]);
    XCTAssertEqual(NSNotFound, [unmanaged.floatObj indexOfObjectWithPredicate:[NSPredicate predicateWithValue:NO]]);
    XCTAssertEqual(NSNotFound, [unmanaged.doubleObj indexOfObjectWithPredicate:[NSPredicate predicateWithValue:NO]]);
    XCTAssertEqual(NSNotFound, [unmanaged.stringObj indexOfObjectWithPredicate:[NSPredicate predicateWithValue:NO]]);
    XCTAssertEqual(NSNotFound, [unmanaged.dataObj indexOfObjectWithPredicate:[NSPredicate predicateWithValue:NO]]);
    XCTAssertEqual(NSNotFound, [unmanaged.dateObj indexOfObjectWithPredicate:[NSPredicate predicateWithValue:NO]]);
    XCTAssertEqual(NSNotFound, [unmanaged.decimalObj indexOfObjectWithPredicate:[NSPredicate predicateWithValue:NO]]);
    XCTAssertEqual(NSNotFound, [unmanaged.objectIdObj indexOfObjectWithPredicate:[NSPredicate predicateWithValue:NO]]);
    XCTAssertEqual(NSNotFound, [unmanaged.uuidObj indexOfObjectWithPredicate:[NSPredicate predicateWithValue:NO]]);
    XCTAssertEqual(NSNotFound, [unmanaged.anyBoolObj indexOfObjectWithPredicate:[NSPredicate predicateWithValue:NO]]);
    XCTAssertEqual(NSNotFound, [unmanaged.anyIntObj indexOfObjectWithPredicate:[NSPredicate predicateWithValue:NO]]);
    XCTAssertEqual(NSNotFound, [unmanaged.anyFloatObj indexOfObjectWithPredicate:[NSPredicate predicateWithValue:NO]]);
    XCTAssertEqual(NSNotFound, [unmanaged.anyDoubleObj indexOfObjectWithPredicate:[NSPredicate predicateWithValue:NO]]);
    XCTAssertEqual(NSNotFound, [unmanaged.anyStringObj indexOfObjectWithPredicate:[NSPredicate predicateWithValue:NO]]);
    XCTAssertEqual(NSNotFound, [unmanaged.anyDataObj indexOfObjectWithPredicate:[NSPredicate predicateWithValue:NO]]);
    XCTAssertEqual(NSNotFound, [unmanaged.anyDateObj indexOfObjectWithPredicate:[NSPredicate predicateWithValue:NO]]);
    XCTAssertEqual(NSNotFound, [unmanaged.anyDecimalObj indexOfObjectWithPredicate:[NSPredicate predicateWithValue:NO]]);
    XCTAssertEqual(NSNotFound, [unmanaged.anyObjectIdObj indexOfObjectWithPredicate:[NSPredicate predicateWithValue:NO]]);
    XCTAssertEqual(NSNotFound, [unmanaged.anyUUIDObj indexOfObjectWithPredicate:[NSPredicate predicateWithValue:NO]]);
    XCTAssertEqual(NSNotFound, [optUnmanaged.boolObj indexOfObjectWithPredicate:[NSPredicate predicateWithValue:NO]]);
    XCTAssertEqual(NSNotFound, [optUnmanaged.intObj indexOfObjectWithPredicate:[NSPredicate predicateWithValue:NO]]);
    XCTAssertEqual(NSNotFound, [optUnmanaged.floatObj indexOfObjectWithPredicate:[NSPredicate predicateWithValue:NO]]);
    XCTAssertEqual(NSNotFound, [optUnmanaged.doubleObj indexOfObjectWithPredicate:[NSPredicate predicateWithValue:NO]]);
    XCTAssertEqual(NSNotFound, [optUnmanaged.stringObj indexOfObjectWithPredicate:[NSPredicate predicateWithValue:NO]]);
    XCTAssertEqual(NSNotFound, [optUnmanaged.dataObj indexOfObjectWithPredicate:[NSPredicate predicateWithValue:NO]]);
    XCTAssertEqual(NSNotFound, [optUnmanaged.dateObj indexOfObjectWithPredicate:[NSPredicate predicateWithValue:NO]]);
    XCTAssertEqual(NSNotFound, [optUnmanaged.decimalObj indexOfObjectWithPredicate:[NSPredicate predicateWithValue:NO]]);
    XCTAssertEqual(NSNotFound, [optUnmanaged.objectIdObj indexOfObjectWithPredicate:[NSPredicate predicateWithValue:NO]]);
    XCTAssertEqual(NSNotFound, [optUnmanaged.uuidObj indexOfObjectWithPredicate:[NSPredicate predicateWithValue:NO]]);
}

- (void)testSort {
    RLMAssertThrowsWithReason([unmanaged.boolObj sortedResultsUsingKeyPath:@"self" ascending:NO],
                              @"This method may only be called on RLMArray instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.intObj sortedResultsUsingKeyPath:@"self" ascending:NO],
                              @"This method may only be called on RLMArray instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.floatObj sortedResultsUsingKeyPath:@"self" ascending:NO],
                              @"This method may only be called on RLMArray instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.doubleObj sortedResultsUsingKeyPath:@"self" ascending:NO],
                              @"This method may only be called on RLMArray instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.stringObj sortedResultsUsingKeyPath:@"self" ascending:NO],
                              @"This method may only be called on RLMArray instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.dataObj sortedResultsUsingKeyPath:@"self" ascending:NO],
                              @"This method may only be called on RLMArray instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.dateObj sortedResultsUsingKeyPath:@"self" ascending:NO],
                              @"This method may only be called on RLMArray instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.decimalObj sortedResultsUsingKeyPath:@"self" ascending:NO],
                              @"This method may only be called on RLMArray instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.objectIdObj sortedResultsUsingKeyPath:@"self" ascending:NO],
                              @"This method may only be called on RLMArray instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.uuidObj sortedResultsUsingKeyPath:@"self" ascending:NO],
                              @"This method may only be called on RLMArray instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.anyBoolObj sortedResultsUsingKeyPath:@"self" ascending:NO],
                              @"This method may only be called on RLMArray instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.anyIntObj sortedResultsUsingKeyPath:@"self" ascending:NO],
                              @"This method may only be called on RLMArray instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.anyFloatObj sortedResultsUsingKeyPath:@"self" ascending:NO],
                              @"This method may only be called on RLMArray instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.anyDoubleObj sortedResultsUsingKeyPath:@"self" ascending:NO],
                              @"This method may only be called on RLMArray instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.anyStringObj sortedResultsUsingKeyPath:@"self" ascending:NO],
                              @"This method may only be called on RLMArray instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.anyDataObj sortedResultsUsingKeyPath:@"self" ascending:NO],
                              @"This method may only be called on RLMArray instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.anyDateObj sortedResultsUsingKeyPath:@"self" ascending:NO],
                              @"This method may only be called on RLMArray instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.anyDecimalObj sortedResultsUsingKeyPath:@"self" ascending:NO],
                              @"This method may only be called on RLMArray instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.anyObjectIdObj sortedResultsUsingKeyPath:@"self" ascending:NO],
                              @"This method may only be called on RLMArray instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.anyUUIDObj sortedResultsUsingKeyPath:@"self" ascending:NO],
                              @"This method may only be called on RLMArray instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([optUnmanaged.boolObj sortedResultsUsingKeyPath:@"self" ascending:NO],
                              @"This method may only be called on RLMArray instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([optUnmanaged.intObj sortedResultsUsingKeyPath:@"self" ascending:NO],
                              @"This method may only be called on RLMArray instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([optUnmanaged.floatObj sortedResultsUsingKeyPath:@"self" ascending:NO],
                              @"This method may only be called on RLMArray instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([optUnmanaged.doubleObj sortedResultsUsingKeyPath:@"self" ascending:NO],
                              @"This method may only be called on RLMArray instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([optUnmanaged.stringObj sortedResultsUsingKeyPath:@"self" ascending:NO],
                              @"This method may only be called on RLMArray instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([optUnmanaged.dataObj sortedResultsUsingKeyPath:@"self" ascending:NO],
                              @"This method may only be called on RLMArray instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([optUnmanaged.dateObj sortedResultsUsingKeyPath:@"self" ascending:NO],
                              @"This method may only be called on RLMArray instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([optUnmanaged.decimalObj sortedResultsUsingKeyPath:@"self" ascending:NO],
                              @"This method may only be called on RLMArray instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([optUnmanaged.objectIdObj sortedResultsUsingKeyPath:@"self" ascending:NO],
                              @"This method may only be called on RLMArray instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([optUnmanaged.uuidObj sortedResultsUsingKeyPath:@"self" ascending:NO],
                              @"This method may only be called on RLMArray instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.boolObj sortedResultsUsingDescriptors:@[]],
                              @"This method may only be called on RLMArray instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.intObj sortedResultsUsingDescriptors:@[]],
                              @"This method may only be called on RLMArray instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.floatObj sortedResultsUsingDescriptors:@[]],
                              @"This method may only be called on RLMArray instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.doubleObj sortedResultsUsingDescriptors:@[]],
                              @"This method may only be called on RLMArray instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.stringObj sortedResultsUsingDescriptors:@[]],
                              @"This method may only be called on RLMArray instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.dataObj sortedResultsUsingDescriptors:@[]],
                              @"This method may only be called on RLMArray instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.dateObj sortedResultsUsingDescriptors:@[]],
                              @"This method may only be called on RLMArray instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.decimalObj sortedResultsUsingDescriptors:@[]],
                              @"This method may only be called on RLMArray instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.objectIdObj sortedResultsUsingDescriptors:@[]],
                              @"This method may only be called on RLMArray instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.uuidObj sortedResultsUsingDescriptors:@[]],
                              @"This method may only be called on RLMArray instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.anyBoolObj sortedResultsUsingDescriptors:@[]],
                              @"This method may only be called on RLMArray instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.anyIntObj sortedResultsUsingDescriptors:@[]],
                              @"This method may only be called on RLMArray instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.anyFloatObj sortedResultsUsingDescriptors:@[]],
                              @"This method may only be called on RLMArray instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.anyDoubleObj sortedResultsUsingDescriptors:@[]],
                              @"This method may only be called on RLMArray instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.anyStringObj sortedResultsUsingDescriptors:@[]],
                              @"This method may only be called on RLMArray instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.anyDataObj sortedResultsUsingDescriptors:@[]],
                              @"This method may only be called on RLMArray instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.anyDateObj sortedResultsUsingDescriptors:@[]],
                              @"This method may only be called on RLMArray instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.anyDecimalObj sortedResultsUsingDescriptors:@[]],
                              @"This method may only be called on RLMArray instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.anyObjectIdObj sortedResultsUsingDescriptors:@[]],
                              @"This method may only be called on RLMArray instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.anyUUIDObj sortedResultsUsingDescriptors:@[]],
                              @"This method may only be called on RLMArray instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([optUnmanaged.boolObj sortedResultsUsingDescriptors:@[]],
                              @"This method may only be called on RLMArray instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([optUnmanaged.intObj sortedResultsUsingDescriptors:@[]],
                              @"This method may only be called on RLMArray instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([optUnmanaged.floatObj sortedResultsUsingDescriptors:@[]],
                              @"This method may only be called on RLMArray instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([optUnmanaged.doubleObj sortedResultsUsingDescriptors:@[]],
                              @"This method may only be called on RLMArray instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([optUnmanaged.stringObj sortedResultsUsingDescriptors:@[]],
                              @"This method may only be called on RLMArray instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([optUnmanaged.dataObj sortedResultsUsingDescriptors:@[]],
                              @"This method may only be called on RLMArray instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([optUnmanaged.dateObj sortedResultsUsingDescriptors:@[]],
                              @"This method may only be called on RLMArray instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([optUnmanaged.decimalObj sortedResultsUsingDescriptors:@[]],
                              @"This method may only be called on RLMArray instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([optUnmanaged.objectIdObj sortedResultsUsingDescriptors:@[]],
                              @"This method may only be called on RLMArray instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([optUnmanaged.uuidObj sortedResultsUsingDescriptors:@[]],
                              @"This method may only be called on RLMArray instances retrieved from an RLMRealm");
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
    RLMAssertThrowsWithReason([managed.anyBoolObj sortedResultsUsingKeyPath:@"not self" ascending:NO],
                              @"can only be sorted on 'self'");
    RLMAssertThrowsWithReason([managed.anyIntObj sortedResultsUsingKeyPath:@"not self" ascending:NO],
                              @"can only be sorted on 'self'");
    RLMAssertThrowsWithReason([managed.anyFloatObj sortedResultsUsingKeyPath:@"not self" ascending:NO],
                              @"can only be sorted on 'self'");
    RLMAssertThrowsWithReason([managed.anyDoubleObj sortedResultsUsingKeyPath:@"not self" ascending:NO],
                              @"can only be sorted on 'self'");
    RLMAssertThrowsWithReason([managed.anyStringObj sortedResultsUsingKeyPath:@"not self" ascending:NO],
                              @"can only be sorted on 'self'");
    RLMAssertThrowsWithReason([managed.anyDataObj sortedResultsUsingKeyPath:@"not self" ascending:NO],
                              @"can only be sorted on 'self'");
    RLMAssertThrowsWithReason([managed.anyDateObj sortedResultsUsingKeyPath:@"not self" ascending:NO],
                              @"can only be sorted on 'self'");
    RLMAssertThrowsWithReason([managed.anyDecimalObj sortedResultsUsingKeyPath:@"not self" ascending:NO],
                              @"can only be sorted on 'self'");
    RLMAssertThrowsWithReason([managed.anyObjectIdObj sortedResultsUsingKeyPath:@"not self" ascending:NO],
                              @"can only be sorted on 'self'");
    RLMAssertThrowsWithReason([managed.anyUUIDObj sortedResultsUsingKeyPath:@"not self" ascending:NO],
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
    [managed.stringObj addObjects:@[@"a", @"b", @"a"]];
    [managed.dataObj addObjects:@[data(1), data(2), data(1)]];
    [managed.dateObj addObjects:@[date(1), date(2), date(1)]];
    [managed.decimalObj addObjects:@[decimal128(2), decimal128(3), decimal128(2)]];
    [managed.objectIdObj addObjects:@[objectId(1), objectId(2), objectId(1)]];
    [managed.uuidObj addObjects:@[uuid(@"00000000-0000-0000-0000-000000000000"), uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"), uuid(@"00000000-0000-0000-0000-000000000000")]];
    [optManaged.boolObj addObjects:@[@NO, @YES, NSNull.null, @YES, @NO]];
    [optManaged.intObj addObjects:@[@2, @3, NSNull.null, @3, @2]];
    [optManaged.floatObj addObjects:@[@2.2f, @3.3f, NSNull.null, @3.3f, @2.2f]];
    [optManaged.doubleObj addObjects:@[@2.2, @3.3, NSNull.null, @3.3, @2.2]];
    [optManaged.stringObj addObjects:@[@"a", @"b", NSNull.null, @"b", @"a"]];
    [optManaged.dataObj addObjects:@[data(1), data(2), NSNull.null, data(2), data(1)]];
    [optManaged.dateObj addObjects:@[date(1), date(2), NSNull.null, date(2), date(1)]];
    [optManaged.decimalObj addObjects:@[decimal128(2), decimal128(3), NSNull.null, decimal128(3), decimal128(2)]];
    [optManaged.objectIdObj addObjects:@[objectId(1), objectId(2), NSNull.null, objectId(2), objectId(1)]];
    [optManaged.uuidObj addObjects:@[uuid(@"00000000-0000-0000-0000-000000000000"), uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"), NSNull.null, uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"), uuid(@"00000000-0000-0000-0000-000000000000")]];

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
                          (@[decimal128(2), decimal128(3), decimal128(2)]));
    XCTAssertEqualObjects([[managed.objectIdObj sortedResultsUsingDescriptors:@[]] valueForKey:@"self"],
                          (@[objectId(1), objectId(2), objectId(1)]));
    XCTAssertEqualObjects([[managed.uuidObj sortedResultsUsingDescriptors:@[]] valueForKey:@"self"],
                          (@[uuid(@"00000000-0000-0000-0000-000000000000"), uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"), uuid(@"00000000-0000-0000-0000-000000000000")]));
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
                          (@[decimal128(2), decimal128(3), NSNull.null, decimal128(3), decimal128(2)]));
    XCTAssertEqualObjects([[optManaged.objectIdObj sortedResultsUsingDescriptors:@[]] valueForKey:@"self"],
                          (@[objectId(1), objectId(2), NSNull.null, objectId(2), objectId(1)]));
    XCTAssertEqualObjects([[optManaged.uuidObj sortedResultsUsingDescriptors:@[]] valueForKey:@"self"],
                          (@[uuid(@"00000000-0000-0000-0000-000000000000"), uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"), NSNull.null, uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"), uuid(@"00000000-0000-0000-0000-000000000000")]));

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
                          (@[decimal128(3), decimal128(2), decimal128(2)]));
    XCTAssertEqualObjects([[managed.objectIdObj sortedResultsUsingKeyPath:@"self" ascending:NO] valueForKey:@"self"],
                          (@[objectId(2), objectId(1), objectId(1)]));
    XCTAssertEqualObjects([[managed.uuidObj sortedResultsUsingKeyPath:@"self" ascending:NO] valueForKey:@"self"],
                          (@[uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"), uuid(@"00000000-0000-0000-0000-000000000000"), uuid(@"00000000-0000-0000-0000-000000000000")]));
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
                          (@[decimal128(3), decimal128(3), decimal128(2), decimal128(2), NSNull.null]));
    XCTAssertEqualObjects([[optManaged.objectIdObj sortedResultsUsingKeyPath:@"self" ascending:NO] valueForKey:@"self"],
                          (@[objectId(2), objectId(2), objectId(1), objectId(1), NSNull.null]));
    XCTAssertEqualObjects([[optManaged.uuidObj sortedResultsUsingKeyPath:@"self" ascending:NO] valueForKey:@"self"],
                          (@[uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"), uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"), uuid(@"00000000-0000-0000-0000-000000000000"), uuid(@"00000000-0000-0000-0000-000000000000"), NSNull.null]));

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
                          (@[decimal128(2), decimal128(2), decimal128(3)]));
    XCTAssertEqualObjects([[managed.objectIdObj sortedResultsUsingKeyPath:@"self" ascending:YES] valueForKey:@"self"],
                          (@[objectId(1), objectId(1), objectId(2)]));
    XCTAssertEqualObjects([[managed.uuidObj sortedResultsUsingKeyPath:@"self" ascending:YES] valueForKey:@"self"],
                          (@[uuid(@"00000000-0000-0000-0000-000000000000"), uuid(@"00000000-0000-0000-0000-000000000000"), uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")]));
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
                          (@[NSNull.null, decimal128(2), decimal128(2), decimal128(3), decimal128(3)]));
    XCTAssertEqualObjects([[optManaged.objectIdObj sortedResultsUsingKeyPath:@"self" ascending:YES] valueForKey:@"self"],
                          (@[NSNull.null, objectId(1), objectId(1), objectId(2), objectId(2)]));
    XCTAssertEqualObjects([[optManaged.uuidObj sortedResultsUsingKeyPath:@"self" ascending:YES] valueForKey:@"self"],
                          (@[NSNull.null, uuid(@"00000000-0000-0000-0000-000000000000"), uuid(@"00000000-0000-0000-0000-000000000000"), uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"), uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")]));
}

- (void)testFilter {
    RLMAssertThrowsWithReason([unmanaged.boolObj objectsWhere:@"TRUEPREDICATE"],
                              @"This method may only be called on RLMArray instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.intObj objectsWhere:@"TRUEPREDICATE"],
                              @"This method may only be called on RLMArray instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.floatObj objectsWhere:@"TRUEPREDICATE"],
                              @"This method may only be called on RLMArray instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.doubleObj objectsWhere:@"TRUEPREDICATE"],
                              @"This method may only be called on RLMArray instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.stringObj objectsWhere:@"TRUEPREDICATE"],
                              @"This method may only be called on RLMArray instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.dataObj objectsWhere:@"TRUEPREDICATE"],
                              @"This method may only be called on RLMArray instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.dateObj objectsWhere:@"TRUEPREDICATE"],
                              @"This method may only be called on RLMArray instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.decimalObj objectsWhere:@"TRUEPREDICATE"],
                              @"This method may only be called on RLMArray instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.objectIdObj objectsWhere:@"TRUEPREDICATE"],
                              @"This method may only be called on RLMArray instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.uuidObj objectsWhere:@"TRUEPREDICATE"],
                              @"This method may only be called on RLMArray instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.anyBoolObj objectsWhere:@"TRUEPREDICATE"],
                              @"This method may only be called on RLMArray instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.anyIntObj objectsWhere:@"TRUEPREDICATE"],
                              @"This method may only be called on RLMArray instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.anyFloatObj objectsWhere:@"TRUEPREDICATE"],
                              @"This method may only be called on RLMArray instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.anyDoubleObj objectsWhere:@"TRUEPREDICATE"],
                              @"This method may only be called on RLMArray instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.anyStringObj objectsWhere:@"TRUEPREDICATE"],
                              @"This method may only be called on RLMArray instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.anyDataObj objectsWhere:@"TRUEPREDICATE"],
                              @"This method may only be called on RLMArray instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.anyDateObj objectsWhere:@"TRUEPREDICATE"],
                              @"This method may only be called on RLMArray instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.anyDecimalObj objectsWhere:@"TRUEPREDICATE"],
                              @"This method may only be called on RLMArray instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.anyObjectIdObj objectsWhere:@"TRUEPREDICATE"],
                              @"This method may only be called on RLMArray instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.anyUUIDObj objectsWhere:@"TRUEPREDICATE"],
                              @"This method may only be called on RLMArray instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([optUnmanaged.boolObj objectsWhere:@"TRUEPREDICATE"],
                              @"This method may only be called on RLMArray instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([optUnmanaged.intObj objectsWhere:@"TRUEPREDICATE"],
                              @"This method may only be called on RLMArray instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([optUnmanaged.floatObj objectsWhere:@"TRUEPREDICATE"],
                              @"This method may only be called on RLMArray instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([optUnmanaged.doubleObj objectsWhere:@"TRUEPREDICATE"],
                              @"This method may only be called on RLMArray instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([optUnmanaged.stringObj objectsWhere:@"TRUEPREDICATE"],
                              @"This method may only be called on RLMArray instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([optUnmanaged.dataObj objectsWhere:@"TRUEPREDICATE"],
                              @"This method may only be called on RLMArray instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([optUnmanaged.dateObj objectsWhere:@"TRUEPREDICATE"],
                              @"This method may only be called on RLMArray instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([optUnmanaged.decimalObj objectsWhere:@"TRUEPREDICATE"],
                              @"This method may only be called on RLMArray instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([optUnmanaged.objectIdObj objectsWhere:@"TRUEPREDICATE"],
                              @"This method may only be called on RLMArray instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([optUnmanaged.uuidObj objectsWhere:@"TRUEPREDICATE"],
                              @"This method may only be called on RLMArray instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.boolObj objectsWithPredicate:[NSPredicate predicateWithValue:YES]],
                              @"This method may only be called on RLMArray instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.intObj objectsWithPredicate:[NSPredicate predicateWithValue:YES]],
                              @"This method may only be called on RLMArray instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.floatObj objectsWithPredicate:[NSPredicate predicateWithValue:YES]],
                              @"This method may only be called on RLMArray instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.doubleObj objectsWithPredicate:[NSPredicate predicateWithValue:YES]],
                              @"This method may only be called on RLMArray instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.stringObj objectsWithPredicate:[NSPredicate predicateWithValue:YES]],
                              @"This method may only be called on RLMArray instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.dataObj objectsWithPredicate:[NSPredicate predicateWithValue:YES]],
                              @"This method may only be called on RLMArray instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.dateObj objectsWithPredicate:[NSPredicate predicateWithValue:YES]],
                              @"This method may only be called on RLMArray instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.decimalObj objectsWithPredicate:[NSPredicate predicateWithValue:YES]],
                              @"This method may only be called on RLMArray instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.objectIdObj objectsWithPredicate:[NSPredicate predicateWithValue:YES]],
                              @"This method may only be called on RLMArray instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.uuidObj objectsWithPredicate:[NSPredicate predicateWithValue:YES]],
                              @"This method may only be called on RLMArray instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.anyBoolObj objectsWithPredicate:[NSPredicate predicateWithValue:YES]],
                              @"This method may only be called on RLMArray instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.anyIntObj objectsWithPredicate:[NSPredicate predicateWithValue:YES]],
                              @"This method may only be called on RLMArray instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.anyFloatObj objectsWithPredicate:[NSPredicate predicateWithValue:YES]],
                              @"This method may only be called on RLMArray instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.anyDoubleObj objectsWithPredicate:[NSPredicate predicateWithValue:YES]],
                              @"This method may only be called on RLMArray instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.anyStringObj objectsWithPredicate:[NSPredicate predicateWithValue:YES]],
                              @"This method may only be called on RLMArray instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.anyDataObj objectsWithPredicate:[NSPredicate predicateWithValue:YES]],
                              @"This method may only be called on RLMArray instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.anyDateObj objectsWithPredicate:[NSPredicate predicateWithValue:YES]],
                              @"This method may only be called on RLMArray instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.anyDecimalObj objectsWithPredicate:[NSPredicate predicateWithValue:YES]],
                              @"This method may only be called on RLMArray instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.anyObjectIdObj objectsWithPredicate:[NSPredicate predicateWithValue:YES]],
                              @"This method may only be called on RLMArray instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.anyUUIDObj objectsWithPredicate:[NSPredicate predicateWithValue:YES]],
                              @"This method may only be called on RLMArray instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([optUnmanaged.boolObj objectsWithPredicate:[NSPredicate predicateWithValue:YES]],
                              @"This method may only be called on RLMArray instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([optUnmanaged.intObj objectsWithPredicate:[NSPredicate predicateWithValue:YES]],
                              @"This method may only be called on RLMArray instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([optUnmanaged.floatObj objectsWithPredicate:[NSPredicate predicateWithValue:YES]],
                              @"This method may only be called on RLMArray instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([optUnmanaged.doubleObj objectsWithPredicate:[NSPredicate predicateWithValue:YES]],
                              @"This method may only be called on RLMArray instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([optUnmanaged.stringObj objectsWithPredicate:[NSPredicate predicateWithValue:YES]],
                              @"This method may only be called on RLMArray instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([optUnmanaged.dataObj objectsWithPredicate:[NSPredicate predicateWithValue:YES]],
                              @"This method may only be called on RLMArray instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([optUnmanaged.dateObj objectsWithPredicate:[NSPredicate predicateWithValue:YES]],
                              @"This method may only be called on RLMArray instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([optUnmanaged.decimalObj objectsWithPredicate:[NSPredicate predicateWithValue:YES]],
                              @"This method may only be called on RLMArray instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([optUnmanaged.objectIdObj objectsWithPredicate:[NSPredicate predicateWithValue:YES]],
                              @"This method may only be called on RLMArray instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([optUnmanaged.uuidObj objectsWithPredicate:[NSPredicate predicateWithValue:YES]],
                              @"This method may only be called on RLMArray instances retrieved from an RLMRealm");

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
    RLMAssertThrowsWithReason([managed.anyBoolObj objectsWhere:@"TRUEPREDICATE"],
                              @"implemented");
    RLMAssertThrowsWithReason([managed.anyIntObj objectsWhere:@"TRUEPREDICATE"],
                              @"implemented");
    RLMAssertThrowsWithReason([managed.anyFloatObj objectsWhere:@"TRUEPREDICATE"],
                              @"implemented");
    RLMAssertThrowsWithReason([managed.anyDoubleObj objectsWhere:@"TRUEPREDICATE"],
                              @"implemented");
    RLMAssertThrowsWithReason([managed.anyStringObj objectsWhere:@"TRUEPREDICATE"],
                              @"implemented");
    RLMAssertThrowsWithReason([managed.anyDataObj objectsWhere:@"TRUEPREDICATE"],
                              @"implemented");
    RLMAssertThrowsWithReason([managed.anyDateObj objectsWhere:@"TRUEPREDICATE"],
                              @"implemented");
    RLMAssertThrowsWithReason([managed.anyDecimalObj objectsWhere:@"TRUEPREDICATE"],
                              @"implemented");
    RLMAssertThrowsWithReason([managed.anyObjectIdObj objectsWhere:@"TRUEPREDICATE"],
                              @"implemented");
    RLMAssertThrowsWithReason([managed.anyUUIDObj objectsWhere:@"TRUEPREDICATE"],
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
    RLMAssertThrowsWithReason([managed.anyBoolObj objectsWithPredicate:[NSPredicate predicateWithValue:YES]],
                              @"implemented");
    RLMAssertThrowsWithReason([managed.anyIntObj objectsWithPredicate:[NSPredicate predicateWithValue:YES]],
                              @"implemented");
    RLMAssertThrowsWithReason([managed.anyFloatObj objectsWithPredicate:[NSPredicate predicateWithValue:YES]],
                              @"implemented");
    RLMAssertThrowsWithReason([managed.anyDoubleObj objectsWithPredicate:[NSPredicate predicateWithValue:YES]],
                              @"implemented");
    RLMAssertThrowsWithReason([managed.anyStringObj objectsWithPredicate:[NSPredicate predicateWithValue:YES]],
                              @"implemented");
    RLMAssertThrowsWithReason([managed.anyDataObj objectsWithPredicate:[NSPredicate predicateWithValue:YES]],
                              @"implemented");
    RLMAssertThrowsWithReason([managed.anyDateObj objectsWithPredicate:[NSPredicate predicateWithValue:YES]],
                              @"implemented");
    RLMAssertThrowsWithReason([managed.anyDecimalObj objectsWithPredicate:[NSPredicate predicateWithValue:YES]],
                              @"implemented");
    RLMAssertThrowsWithReason([managed.anyObjectIdObj objectsWithPredicate:[NSPredicate predicateWithValue:YES]],
                              @"implemented");
    RLMAssertThrowsWithReason([managed.anyUUIDObj objectsWithPredicate:[NSPredicate predicateWithValue:YES]],
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
    RLMAssertThrowsWithReason([[managed.anyBoolObj sortedResultsUsingKeyPath:@"self" ascending:NO]
                               objectsWhere:@"TRUEPREDICATE"], @"implemented");
    RLMAssertThrowsWithReason([[managed.anyIntObj sortedResultsUsingKeyPath:@"self" ascending:NO]
                               objectsWhere:@"TRUEPREDICATE"], @"implemented");
    RLMAssertThrowsWithReason([[managed.anyFloatObj sortedResultsUsingKeyPath:@"self" ascending:NO]
                               objectsWhere:@"TRUEPREDICATE"], @"implemented");
    RLMAssertThrowsWithReason([[managed.anyDoubleObj sortedResultsUsingKeyPath:@"self" ascending:NO]
                               objectsWhere:@"TRUEPREDICATE"], @"implemented");
    RLMAssertThrowsWithReason([[managed.anyStringObj sortedResultsUsingKeyPath:@"self" ascending:NO]
                               objectsWhere:@"TRUEPREDICATE"], @"implemented");
    RLMAssertThrowsWithReason([[managed.anyDataObj sortedResultsUsingKeyPath:@"self" ascending:NO]
                               objectsWhere:@"TRUEPREDICATE"], @"implemented");
    RLMAssertThrowsWithReason([[managed.anyDateObj sortedResultsUsingKeyPath:@"self" ascending:NO]
                               objectsWhere:@"TRUEPREDICATE"], @"implemented");
    RLMAssertThrowsWithReason([[managed.anyDecimalObj sortedResultsUsingKeyPath:@"self" ascending:NO]
                               objectsWhere:@"TRUEPREDICATE"], @"implemented");
    RLMAssertThrowsWithReason([[managed.anyObjectIdObj sortedResultsUsingKeyPath:@"self" ascending:NO]
                               objectsWhere:@"TRUEPREDICATE"], @"implemented");
    RLMAssertThrowsWithReason([[managed.anyUUIDObj sortedResultsUsingKeyPath:@"self" ascending:NO]
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
    RLMAssertThrowsWithReason([[managed.anyBoolObj sortedResultsUsingKeyPath:@"self" ascending:NO]
                               objectsWithPredicate:[NSPredicate predicateWithValue:YES]], @"implemented");
    RLMAssertThrowsWithReason([[managed.anyIntObj sortedResultsUsingKeyPath:@"self" ascending:NO]
                               objectsWithPredicate:[NSPredicate predicateWithValue:YES]], @"implemented");
    RLMAssertThrowsWithReason([[managed.anyFloatObj sortedResultsUsingKeyPath:@"self" ascending:NO]
                               objectsWithPredicate:[NSPredicate predicateWithValue:YES]], @"implemented");
    RLMAssertThrowsWithReason([[managed.anyDoubleObj sortedResultsUsingKeyPath:@"self" ascending:NO]
                               objectsWithPredicate:[NSPredicate predicateWithValue:YES]], @"implemented");
    RLMAssertThrowsWithReason([[managed.anyStringObj sortedResultsUsingKeyPath:@"self" ascending:NO]
                               objectsWithPredicate:[NSPredicate predicateWithValue:YES]], @"implemented");
    RLMAssertThrowsWithReason([[managed.anyDataObj sortedResultsUsingKeyPath:@"self" ascending:NO]
                               objectsWithPredicate:[NSPredicate predicateWithValue:YES]], @"implemented");
    RLMAssertThrowsWithReason([[managed.anyDateObj sortedResultsUsingKeyPath:@"self" ascending:NO]
                               objectsWithPredicate:[NSPredicate predicateWithValue:YES]], @"implemented");
    RLMAssertThrowsWithReason([[managed.anyDecimalObj sortedResultsUsingKeyPath:@"self" ascending:NO]
                               objectsWithPredicate:[NSPredicate predicateWithValue:YES]], @"implemented");
    RLMAssertThrowsWithReason([[managed.anyObjectIdObj sortedResultsUsingKeyPath:@"self" ascending:NO]
                               objectsWithPredicate:[NSPredicate predicateWithValue:YES]], @"implemented");
    RLMAssertThrowsWithReason([[managed.anyUUIDObj sortedResultsUsingKeyPath:@"self" ascending:NO]
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
                              @"This method may only be called on RLMArray instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.intObj addNotificationBlock:^(__unused id a, __unused id c, __unused id e) { }],
                              @"This method may only be called on RLMArray instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.floatObj addNotificationBlock:^(__unused id a, __unused id c, __unused id e) { }],
                              @"This method may only be called on RLMArray instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.doubleObj addNotificationBlock:^(__unused id a, __unused id c, __unused id e) { }],
                              @"This method may only be called on RLMArray instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.stringObj addNotificationBlock:^(__unused id a, __unused id c, __unused id e) { }],
                              @"This method may only be called on RLMArray instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.dataObj addNotificationBlock:^(__unused id a, __unused id c, __unused id e) { }],
                              @"This method may only be called on RLMArray instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.dateObj addNotificationBlock:^(__unused id a, __unused id c, __unused id e) { }],
                              @"This method may only be called on RLMArray instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.decimalObj addNotificationBlock:^(__unused id a, __unused id c, __unused id e) { }],
                              @"This method may only be called on RLMArray instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.objectIdObj addNotificationBlock:^(__unused id a, __unused id c, __unused id e) { }],
                              @"This method may only be called on RLMArray instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.uuidObj addNotificationBlock:^(__unused id a, __unused id c, __unused id e) { }],
                              @"This method may only be called on RLMArray instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.anyBoolObj addNotificationBlock:^(__unused id a, __unused id c, __unused id e) { }],
                              @"This method may only be called on RLMArray instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.anyIntObj addNotificationBlock:^(__unused id a, __unused id c, __unused id e) { }],
                              @"This method may only be called on RLMArray instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.anyFloatObj addNotificationBlock:^(__unused id a, __unused id c, __unused id e) { }],
                              @"This method may only be called on RLMArray instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.anyDoubleObj addNotificationBlock:^(__unused id a, __unused id c, __unused id e) { }],
                              @"This method may only be called on RLMArray instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.anyStringObj addNotificationBlock:^(__unused id a, __unused id c, __unused id e) { }],
                              @"This method may only be called on RLMArray instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.anyDataObj addNotificationBlock:^(__unused id a, __unused id c, __unused id e) { }],
                              @"This method may only be called on RLMArray instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.anyDateObj addNotificationBlock:^(__unused id a, __unused id c, __unused id e) { }],
                              @"This method may only be called on RLMArray instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.anyDecimalObj addNotificationBlock:^(__unused id a, __unused id c, __unused id e) { }],
                              @"This method may only be called on RLMArray instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.anyObjectIdObj addNotificationBlock:^(__unused id a, __unused id c, __unused id e) { }],
                              @"This method may only be called on RLMArray instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.anyUUIDObj addNotificationBlock:^(__unused id a, __unused id c, __unused id e) { }],
                              @"This method may only be called on RLMArray instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([optUnmanaged.boolObj addNotificationBlock:^(__unused id a, __unused id c, __unused id e) { }],
                              @"This method may only be called on RLMArray instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([optUnmanaged.intObj addNotificationBlock:^(__unused id a, __unused id c, __unused id e) { }],
                              @"This method may only be called on RLMArray instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([optUnmanaged.floatObj addNotificationBlock:^(__unused id a, __unused id c, __unused id e) { }],
                              @"This method may only be called on RLMArray instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([optUnmanaged.doubleObj addNotificationBlock:^(__unused id a, __unused id c, __unused id e) { }],
                              @"This method may only be called on RLMArray instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([optUnmanaged.stringObj addNotificationBlock:^(__unused id a, __unused id c, __unused id e) { }],
                              @"This method may only be called on RLMArray instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([optUnmanaged.dataObj addNotificationBlock:^(__unused id a, __unused id c, __unused id e) { }],
                              @"This method may only be called on RLMArray instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([optUnmanaged.dateObj addNotificationBlock:^(__unused id a, __unused id c, __unused id e) { }],
                              @"This method may only be called on RLMArray instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([optUnmanaged.decimalObj addNotificationBlock:^(__unused id a, __unused id c, __unused id e) { }],
                              @"This method may only be called on RLMArray instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([optUnmanaged.objectIdObj addNotificationBlock:^(__unused id a, __unused id c, __unused id e) { }],
                              @"This method may only be called on RLMArray instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([optUnmanaged.uuidObj addNotificationBlock:^(__unused id a, __unused id c, __unused id e) { }],
                              @"This method may only be called on RLMArray instances retrieved from an RLMRealm");
}

- (void)testMin {
    RLMAssertThrowsWithReason([unmanaged.boolObj minOfProperty:@"self"],
                              @"minOfProperty: is not supported for bool array");
    RLMAssertThrowsWithReason([unmanaged.stringObj minOfProperty:@"self"],
                              @"minOfProperty: is not supported for string array");
    RLMAssertThrowsWithReason([unmanaged.dataObj minOfProperty:@"self"],
                              @"minOfProperty: is not supported for data array");
    RLMAssertThrowsWithReason([unmanaged.objectIdObj minOfProperty:@"self"],
                              @"minOfProperty: is not supported for object id array");
    RLMAssertThrowsWithReason([unmanaged.uuidObj minOfProperty:@"self"],
                              @"minOfProperty: is not supported for uuid array");
    RLMAssertThrowsWithReason([optUnmanaged.boolObj minOfProperty:@"self"],
                              @"minOfProperty: is not supported for bool? array");
    RLMAssertThrowsWithReason([optUnmanaged.stringObj minOfProperty:@"self"],
                              @"minOfProperty: is not supported for string? array");
    RLMAssertThrowsWithReason([optUnmanaged.dataObj minOfProperty:@"self"],
                              @"minOfProperty: is not supported for data? array");
    RLMAssertThrowsWithReason([optUnmanaged.objectIdObj minOfProperty:@"self"],
                              @"minOfProperty: is not supported for object id? array");
    RLMAssertThrowsWithReason([optUnmanaged.uuidObj minOfProperty:@"self"],
                              @"minOfProperty: is not supported for uuid? array");
    RLMAssertThrowsWithReason([managed.boolObj minOfProperty:@"self"],
                              @"minOfProperty: is not supported for bool array 'AllPrimitiveArrays.boolObj'");
    RLMAssertThrowsWithReason([managed.stringObj minOfProperty:@"self"],
                              @"minOfProperty: is not supported for string array 'AllPrimitiveArrays.stringObj'");
    RLMAssertThrowsWithReason([managed.dataObj minOfProperty:@"self"],
                              @"minOfProperty: is not supported for data array 'AllPrimitiveArrays.dataObj'");
    RLMAssertThrowsWithReason([managed.objectIdObj minOfProperty:@"self"],
                              @"minOfProperty: is not supported for object id array 'AllPrimitiveArrays.objectIdObj'");
    RLMAssertThrowsWithReason([managed.uuidObj minOfProperty:@"self"],
                              @"minOfProperty: is not supported for uuid array 'AllPrimitiveArrays.uuidObj'");
    RLMAssertThrowsWithReason([optManaged.boolObj minOfProperty:@"self"],
                              @"minOfProperty: is not supported for bool? array 'AllOptionalPrimitiveArrays.boolObj'");
    RLMAssertThrowsWithReason([optManaged.stringObj minOfProperty:@"self"],
                              @"minOfProperty: is not supported for string? array 'AllOptionalPrimitiveArrays.stringObj'");
    RLMAssertThrowsWithReason([optManaged.dataObj minOfProperty:@"self"],
                              @"minOfProperty: is not supported for data? array 'AllOptionalPrimitiveArrays.dataObj'");
    RLMAssertThrowsWithReason([optManaged.objectIdObj minOfProperty:@"self"],
                              @"minOfProperty: is not supported for object id? array 'AllOptionalPrimitiveArrays.objectIdObj'");
    RLMAssertThrowsWithReason([optManaged.uuidObj minOfProperty:@"self"],
                              @"minOfProperty: is not supported for uuid? array 'AllOptionalPrimitiveArrays.uuidObj'");

    XCTAssertNil([unmanaged.intObj minOfProperty:@"self"]);
    XCTAssertNil([unmanaged.floatObj minOfProperty:@"self"]);
    XCTAssertNil([unmanaged.doubleObj minOfProperty:@"self"]);
    XCTAssertNil([unmanaged.dateObj minOfProperty:@"self"]);
    XCTAssertNil([unmanaged.decimalObj minOfProperty:@"self"]);
    XCTAssertNil([unmanaged.anyFloatObj minOfProperty:@"self"]);
    XCTAssertNil([unmanaged.anyDoubleObj minOfProperty:@"self"]);
    XCTAssertNil([unmanaged.anyDateObj minOfProperty:@"self"]);
    XCTAssertNil([unmanaged.anyDecimalObj minOfProperty:@"self"]);
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
    XCTAssertNil([managed.anyIntObj minOfProperty:@"self"]);
    XCTAssertNil([managed.anyFloatObj minOfProperty:@"self"]);
    XCTAssertNil([managed.anyDoubleObj minOfProperty:@"self"]);
    XCTAssertNil([managed.anyDateObj minOfProperty:@"self"]);
    XCTAssertNil([managed.anyDecimalObj minOfProperty:@"self"]);
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
    XCTAssertEqualObjects([unmanaged.decimalObj minOfProperty:@"self"], decimal128(2));
    XCTAssertEqualObjects([unmanaged.anyFloatObj minOfProperty:@"self"], @2.2f);
    XCTAssertEqualObjects([unmanaged.anyDoubleObj minOfProperty:@"self"], @2.2);
    XCTAssertEqualObjects([unmanaged.anyDateObj minOfProperty:@"self"], date(1));
    XCTAssertEqualObjects([unmanaged.anyDecimalObj minOfProperty:@"self"], decimal128(2));
    XCTAssertEqualObjects([optUnmanaged.intObj minOfProperty:@"self"], @2);
    XCTAssertEqualObjects([optUnmanaged.floatObj minOfProperty:@"self"], @2.2f);
    XCTAssertEqualObjects([optUnmanaged.doubleObj minOfProperty:@"self"], @2.2);
    XCTAssertEqualObjects([optUnmanaged.dateObj minOfProperty:@"self"], date(1));
    XCTAssertEqualObjects([optUnmanaged.decimalObj minOfProperty:@"self"], decimal128(2));
    XCTAssertEqualObjects([managed.intObj minOfProperty:@"self"], @2);
    XCTAssertEqualObjects([managed.floatObj minOfProperty:@"self"], @2.2f);
    XCTAssertEqualObjects([managed.doubleObj minOfProperty:@"self"], @2.2);
    XCTAssertEqualObjects([managed.dateObj minOfProperty:@"self"], date(1));
    XCTAssertEqualObjects([managed.decimalObj minOfProperty:@"self"], decimal128(2));
    XCTAssertEqualObjects([managed.anyIntObj minOfProperty:@"self"], @2);
    XCTAssertEqualObjects([managed.anyFloatObj minOfProperty:@"self"], @2.2f);
    XCTAssertEqualObjects([managed.anyDoubleObj minOfProperty:@"self"], @2.2);
    XCTAssertEqualObjects([managed.anyDateObj minOfProperty:@"self"], date(1));
    XCTAssertEqualObjects([managed.anyDecimalObj minOfProperty:@"self"], decimal128(2));
    XCTAssertEqualObjects([optManaged.intObj minOfProperty:@"self"], @2);
    XCTAssertEqualObjects([optManaged.floatObj minOfProperty:@"self"], @2.2f);
    XCTAssertEqualObjects([optManaged.doubleObj minOfProperty:@"self"], @2.2);
    XCTAssertEqualObjects([optManaged.dateObj minOfProperty:@"self"], date(1));
    XCTAssertEqualObjects([optManaged.decimalObj minOfProperty:@"self"], decimal128(2));
}

- (void)testMax {
    RLMAssertThrowsWithReason([unmanaged.boolObj maxOfProperty:@"self"],
                              @"maxOfProperty: is not supported for bool array");
    RLMAssertThrowsWithReason([unmanaged.stringObj maxOfProperty:@"self"],
                              @"maxOfProperty: is not supported for string array");
    RLMAssertThrowsWithReason([unmanaged.dataObj maxOfProperty:@"self"],
                              @"maxOfProperty: is not supported for data array");
    RLMAssertThrowsWithReason([unmanaged.objectIdObj maxOfProperty:@"self"],
                              @"maxOfProperty: is not supported for object id array");
    RLMAssertThrowsWithReason([unmanaged.uuidObj maxOfProperty:@"self"],
                              @"maxOfProperty: is not supported for uuid array");
    RLMAssertThrowsWithReason([optUnmanaged.boolObj maxOfProperty:@"self"],
                              @"maxOfProperty: is not supported for bool? array");
    RLMAssertThrowsWithReason([optUnmanaged.stringObj maxOfProperty:@"self"],
                              @"maxOfProperty: is not supported for string? array");
    RLMAssertThrowsWithReason([optUnmanaged.dataObj maxOfProperty:@"self"],
                              @"maxOfProperty: is not supported for data? array");
    RLMAssertThrowsWithReason([optUnmanaged.objectIdObj maxOfProperty:@"self"],
                              @"maxOfProperty: is not supported for object id? array");
    RLMAssertThrowsWithReason([optUnmanaged.uuidObj maxOfProperty:@"self"],
                              @"maxOfProperty: is not supported for uuid? array");
    RLMAssertThrowsWithReason([managed.boolObj maxOfProperty:@"self"],
                              @"maxOfProperty: is not supported for bool array 'AllPrimitiveArrays.boolObj'");
    RLMAssertThrowsWithReason([managed.stringObj maxOfProperty:@"self"],
                              @"maxOfProperty: is not supported for string array 'AllPrimitiveArrays.stringObj'");
    RLMAssertThrowsWithReason([managed.dataObj maxOfProperty:@"self"],
                              @"maxOfProperty: is not supported for data array 'AllPrimitiveArrays.dataObj'");
    RLMAssertThrowsWithReason([managed.objectIdObj maxOfProperty:@"self"],
                              @"maxOfProperty: is not supported for object id array 'AllPrimitiveArrays.objectIdObj'");
    RLMAssertThrowsWithReason([managed.uuidObj maxOfProperty:@"self"],
                              @"maxOfProperty: is not supported for uuid array 'AllPrimitiveArrays.uuidObj'");
    RLMAssertThrowsWithReason([optManaged.boolObj maxOfProperty:@"self"],
                              @"maxOfProperty: is not supported for bool? array 'AllOptionalPrimitiveArrays.boolObj'");
    RLMAssertThrowsWithReason([optManaged.stringObj maxOfProperty:@"self"],
                              @"maxOfProperty: is not supported for string? array 'AllOptionalPrimitiveArrays.stringObj'");
    RLMAssertThrowsWithReason([optManaged.dataObj maxOfProperty:@"self"],
                              @"maxOfProperty: is not supported for data? array 'AllOptionalPrimitiveArrays.dataObj'");
    RLMAssertThrowsWithReason([optManaged.objectIdObj maxOfProperty:@"self"],
                              @"maxOfProperty: is not supported for object id? array 'AllOptionalPrimitiveArrays.objectIdObj'");
    RLMAssertThrowsWithReason([optManaged.uuidObj maxOfProperty:@"self"],
                              @"maxOfProperty: is not supported for uuid? array 'AllOptionalPrimitiveArrays.uuidObj'");

    XCTAssertNil([unmanaged.intObj maxOfProperty:@"self"]);
    XCTAssertNil([unmanaged.floatObj maxOfProperty:@"self"]);
    XCTAssertNil([unmanaged.doubleObj maxOfProperty:@"self"]);
    XCTAssertNil([unmanaged.dateObj maxOfProperty:@"self"]);
    XCTAssertNil([unmanaged.decimalObj maxOfProperty:@"self"]);
    XCTAssertNil([unmanaged.anyFloatObj maxOfProperty:@"self"]);
    XCTAssertNil([unmanaged.anyDoubleObj maxOfProperty:@"self"]);
    XCTAssertNil([unmanaged.anyDateObj maxOfProperty:@"self"]);
    XCTAssertNil([unmanaged.anyDecimalObj maxOfProperty:@"self"]);
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
    XCTAssertNil([managed.anyIntObj maxOfProperty:@"self"]);
    XCTAssertNil([managed.anyFloatObj maxOfProperty:@"self"]);
    XCTAssertNil([managed.anyDoubleObj maxOfProperty:@"self"]);
    XCTAssertNil([managed.anyDateObj maxOfProperty:@"self"]);
    XCTAssertNil([managed.anyDecimalObj maxOfProperty:@"self"]);
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
    XCTAssertEqualObjects([unmanaged.decimalObj maxOfProperty:@"self"], decimal128(3));
    XCTAssertEqualObjects([unmanaged.anyFloatObj maxOfProperty:@"self"], @3.3f);
    XCTAssertEqualObjects([unmanaged.anyDoubleObj maxOfProperty:@"self"], @3.3);
    XCTAssertEqualObjects([unmanaged.anyDateObj maxOfProperty:@"self"], date(2));
    XCTAssertEqualObjects([unmanaged.anyDecimalObj maxOfProperty:@"self"], decimal128(3));
    XCTAssertEqualObjects([optUnmanaged.intObj maxOfProperty:@"self"], @3);
    XCTAssertEqualObjects([optUnmanaged.floatObj maxOfProperty:@"self"], @3.3f);
    XCTAssertEqualObjects([optUnmanaged.doubleObj maxOfProperty:@"self"], @3.3);
    XCTAssertEqualObjects([optUnmanaged.dateObj maxOfProperty:@"self"], date(2));
    XCTAssertEqualObjects([optUnmanaged.decimalObj maxOfProperty:@"self"], decimal128(3));
    XCTAssertEqualObjects([managed.intObj maxOfProperty:@"self"], @3);
    XCTAssertEqualObjects([managed.floatObj maxOfProperty:@"self"], @3.3f);
    XCTAssertEqualObjects([managed.doubleObj maxOfProperty:@"self"], @3.3);
    XCTAssertEqualObjects([managed.dateObj maxOfProperty:@"self"], date(2));
    XCTAssertEqualObjects([managed.decimalObj maxOfProperty:@"self"], decimal128(3));
    XCTAssertEqualObjects([managed.anyIntObj maxOfProperty:@"self"], @3);
    XCTAssertEqualObjects([managed.anyFloatObj maxOfProperty:@"self"], @3.3f);
    XCTAssertEqualObjects([managed.anyDoubleObj maxOfProperty:@"self"], @3.3);
    XCTAssertEqualObjects([managed.anyDateObj maxOfProperty:@"self"], date(2));
    XCTAssertEqualObjects([managed.anyDecimalObj maxOfProperty:@"self"], decimal128(3));
    XCTAssertEqualObjects([optManaged.intObj maxOfProperty:@"self"], @3);
    XCTAssertEqualObjects([optManaged.floatObj maxOfProperty:@"self"], @3.3f);
    XCTAssertEqualObjects([optManaged.doubleObj maxOfProperty:@"self"], @3.3);
    XCTAssertEqualObjects([optManaged.dateObj maxOfProperty:@"self"], date(2));
    XCTAssertEqualObjects([optManaged.decimalObj maxOfProperty:@"self"], decimal128(3));
}

- (void)testSum {
    RLMAssertThrowsWithReason([unmanaged.boolObj sumOfProperty:@"self"],
                              @"sumOfProperty: is not supported for bool array");
    RLMAssertThrowsWithReason([unmanaged.stringObj sumOfProperty:@"self"],
                              @"sumOfProperty: is not supported for string array");
    RLMAssertThrowsWithReason([unmanaged.dataObj sumOfProperty:@"self"],
                              @"sumOfProperty: is not supported for data array");
    RLMAssertThrowsWithReason([unmanaged.dateObj sumOfProperty:@"self"],
                              @"sumOfProperty: is not supported for date array");
    RLMAssertThrowsWithReason([unmanaged.objectIdObj sumOfProperty:@"self"],
                              @"sumOfProperty: is not supported for object id array");
    RLMAssertThrowsWithReason([unmanaged.uuidObj sumOfProperty:@"self"],
                              @"sumOfProperty: is not supported for uuid array");
    RLMAssertThrowsWithReason([optUnmanaged.boolObj sumOfProperty:@"self"],
                              @"sumOfProperty: is not supported for bool? array");
    RLMAssertThrowsWithReason([optUnmanaged.stringObj sumOfProperty:@"self"],
                              @"sumOfProperty: is not supported for string? array");
    RLMAssertThrowsWithReason([optUnmanaged.dataObj sumOfProperty:@"self"],
                              @"sumOfProperty: is not supported for data? array");
    RLMAssertThrowsWithReason([optUnmanaged.dateObj sumOfProperty:@"self"],
                              @"sumOfProperty: is not supported for date? array");
    RLMAssertThrowsWithReason([optUnmanaged.objectIdObj sumOfProperty:@"self"],
                              @"sumOfProperty: is not supported for object id? array");
    RLMAssertThrowsWithReason([optUnmanaged.uuidObj sumOfProperty:@"self"],
                              @"sumOfProperty: is not supported for uuid? array");
    RLMAssertThrowsWithReason([managed.boolObj sumOfProperty:@"self"],
                              @"sumOfProperty: is not supported for bool array 'AllPrimitiveArrays.boolObj'");
    RLMAssertThrowsWithReason([managed.stringObj sumOfProperty:@"self"],
                              @"sumOfProperty: is not supported for string array 'AllPrimitiveArrays.stringObj'");
    RLMAssertThrowsWithReason([managed.dataObj sumOfProperty:@"self"],
                              @"sumOfProperty: is not supported for data array 'AllPrimitiveArrays.dataObj'");
    RLMAssertThrowsWithReason([managed.dateObj sumOfProperty:@"self"],
                              @"sumOfProperty: is not supported for date array 'AllPrimitiveArrays.dateObj'");
    RLMAssertThrowsWithReason([managed.objectIdObj sumOfProperty:@"self"],
                              @"sumOfProperty: is not supported for object id array 'AllPrimitiveArrays.objectIdObj'");
    RLMAssertThrowsWithReason([managed.uuidObj sumOfProperty:@"self"],
                              @"sumOfProperty: is not supported for uuid array 'AllPrimitiveArrays.uuidObj'");
    RLMAssertThrowsWithReason([optManaged.boolObj sumOfProperty:@"self"],
                              @"sumOfProperty: is not supported for bool? array 'AllOptionalPrimitiveArrays.boolObj'");
    RLMAssertThrowsWithReason([optManaged.stringObj sumOfProperty:@"self"],
                              @"sumOfProperty: is not supported for string? array 'AllOptionalPrimitiveArrays.stringObj'");
    RLMAssertThrowsWithReason([optManaged.dataObj sumOfProperty:@"self"],
                              @"sumOfProperty: is not supported for data? array 'AllOptionalPrimitiveArrays.dataObj'");
    RLMAssertThrowsWithReason([optManaged.dateObj sumOfProperty:@"self"],
                              @"sumOfProperty: is not supported for date? array 'AllOptionalPrimitiveArrays.dateObj'");
    RLMAssertThrowsWithReason([optManaged.objectIdObj sumOfProperty:@"self"],
                              @"sumOfProperty: is not supported for object id? array 'AllOptionalPrimitiveArrays.objectIdObj'");
    RLMAssertThrowsWithReason([optManaged.uuidObj sumOfProperty:@"self"],
                              @"sumOfProperty: is not supported for uuid? array 'AllOptionalPrimitiveArrays.uuidObj'");

    XCTAssertEqualObjects([unmanaged.intObj sumOfProperty:@"self"], @0);
    XCTAssertEqualObjects([unmanaged.floatObj sumOfProperty:@"self"], @0);
    XCTAssertEqualObjects([unmanaged.doubleObj sumOfProperty:@"self"], @0);
    XCTAssertEqualObjects([unmanaged.decimalObj sumOfProperty:@"self"], @0);
    XCTAssertEqualObjects([unmanaged.anyIntObj sumOfProperty:@"self"], @0);
    XCTAssertEqualObjects([unmanaged.anyFloatObj sumOfProperty:@"self"], @0);
    XCTAssertEqualObjects([unmanaged.anyDoubleObj sumOfProperty:@"self"], @0);
    XCTAssertEqualObjects([unmanaged.anyDecimalObj sumOfProperty:@"self"], @0);
    XCTAssertEqualObjects([optUnmanaged.intObj sumOfProperty:@"self"], @0);
    XCTAssertEqualObjects([optUnmanaged.floatObj sumOfProperty:@"self"], @0);
    XCTAssertEqualObjects([optUnmanaged.doubleObj sumOfProperty:@"self"], @0);
    XCTAssertEqualObjects([optUnmanaged.decimalObj sumOfProperty:@"self"], @0);
    XCTAssertEqualObjects([managed.intObj sumOfProperty:@"self"], @0);
    XCTAssertEqualObjects([managed.floatObj sumOfProperty:@"self"], @0);
    XCTAssertEqualObjects([managed.doubleObj sumOfProperty:@"self"], @0);
    XCTAssertEqualObjects([managed.decimalObj sumOfProperty:@"self"], @0);
    XCTAssertEqualObjects([managed.anyIntObj sumOfProperty:@"self"], @0);
    XCTAssertEqualObjects([managed.anyFloatObj sumOfProperty:@"self"], @0);
    XCTAssertEqualObjects([managed.anyDoubleObj sumOfProperty:@"self"], @0);
    XCTAssertEqualObjects([managed.anyDecimalObj sumOfProperty:@"self"], @0);
    XCTAssertEqualObjects([optManaged.intObj sumOfProperty:@"self"], @0);
    XCTAssertEqualObjects([optManaged.floatObj sumOfProperty:@"self"], @0);
    XCTAssertEqualObjects([optManaged.doubleObj sumOfProperty:@"self"], @0);
    XCTAssertEqualObjects([optManaged.decimalObj sumOfProperty:@"self"], @0);

    [self addObjects];

    XCTAssertEqualWithAccuracy([unmanaged.intObj sumOfProperty:@"self"].doubleValue, sum(@[@2, @3]), .001);
    XCTAssertEqualWithAccuracy([unmanaged.floatObj sumOfProperty:@"self"].doubleValue, sum(@[@2.2f, @3.3f]), .001);
    XCTAssertEqualWithAccuracy([unmanaged.doubleObj sumOfProperty:@"self"].doubleValue, sum(@[@2.2, @3.3]), .001);
    XCTAssertEqualWithAccuracy([unmanaged.decimalObj sumOfProperty:@"self"].doubleValue, sum(@[decimal128(2), decimal128(3)]), .001);
    XCTAssertEqualWithAccuracy([unmanaged.anyIntObj sumOfProperty:@"self"].doubleValue, sum(@[@2, @3]), .001);
    XCTAssertEqualWithAccuracy([unmanaged.anyFloatObj sumOfProperty:@"self"].doubleValue, sum(@[@2.2f, @3.3f]), .001);
    XCTAssertEqualWithAccuracy([unmanaged.anyDoubleObj sumOfProperty:@"self"].doubleValue, sum(@[@2.2, @3.3]), .001);
    XCTAssertEqualWithAccuracy([unmanaged.anyDecimalObj sumOfProperty:@"self"].doubleValue, sum(@[decimal128(2), decimal128(3)]), .001);
    XCTAssertEqualWithAccuracy([optUnmanaged.intObj sumOfProperty:@"self"].doubleValue, sum(@[@2, @3, NSNull.null]), .001);
    XCTAssertEqualWithAccuracy([optUnmanaged.floatObj sumOfProperty:@"self"].doubleValue, sum(@[@2.2f, @3.3f, NSNull.null]), .001);
    XCTAssertEqualWithAccuracy([optUnmanaged.doubleObj sumOfProperty:@"self"].doubleValue, sum(@[@2.2, @3.3, NSNull.null]), .001);
    XCTAssertEqualWithAccuracy([optUnmanaged.decimalObj sumOfProperty:@"self"].doubleValue, sum(@[decimal128(2), decimal128(3), NSNull.null]), .001);
    XCTAssertEqualWithAccuracy([managed.intObj sumOfProperty:@"self"].doubleValue, sum(@[@2, @3]), .001);
    XCTAssertEqualWithAccuracy([managed.floatObj sumOfProperty:@"self"].doubleValue, sum(@[@2.2f, @3.3f]), .001);
    XCTAssertEqualWithAccuracy([managed.doubleObj sumOfProperty:@"self"].doubleValue, sum(@[@2.2, @3.3]), .001);
    XCTAssertEqualWithAccuracy([managed.decimalObj sumOfProperty:@"self"].doubleValue, sum(@[decimal128(2), decimal128(3)]), .001);
    XCTAssertEqualWithAccuracy([managed.anyIntObj sumOfProperty:@"self"].doubleValue, sum(@[@2, @3]), .001);
    XCTAssertEqualWithAccuracy([managed.anyFloatObj sumOfProperty:@"self"].doubleValue, sum(@[@2.2f, @3.3f]), .001);
    XCTAssertEqualWithAccuracy([managed.anyDoubleObj sumOfProperty:@"self"].doubleValue, sum(@[@2.2, @3.3]), .001);
    XCTAssertEqualWithAccuracy([managed.anyDecimalObj sumOfProperty:@"self"].doubleValue, sum(@[decimal128(2), decimal128(3)]), .001);
    XCTAssertEqualWithAccuracy([optManaged.intObj sumOfProperty:@"self"].doubleValue, sum(@[@2, @3, NSNull.null]), .001);
    XCTAssertEqualWithAccuracy([optManaged.floatObj sumOfProperty:@"self"].doubleValue, sum(@[@2.2f, @3.3f, NSNull.null]), .001);
    XCTAssertEqualWithAccuracy([optManaged.doubleObj sumOfProperty:@"self"].doubleValue, sum(@[@2.2, @3.3, NSNull.null]), .001);
    XCTAssertEqualWithAccuracy([optManaged.decimalObj sumOfProperty:@"self"].doubleValue, sum(@[decimal128(2), decimal128(3), NSNull.null]), .001);
}

- (void)testAverage {
    RLMAssertThrowsWithReason([unmanaged.boolObj averageOfProperty:@"self"],
                              @"averageOfProperty: is not supported for bool array");
    RLMAssertThrowsWithReason([unmanaged.stringObj averageOfProperty:@"self"],
                              @"averageOfProperty: is not supported for string array");
    RLMAssertThrowsWithReason([unmanaged.dataObj averageOfProperty:@"self"],
                              @"averageOfProperty: is not supported for data array");
    RLMAssertThrowsWithReason([unmanaged.dateObj averageOfProperty:@"self"],
                              @"averageOfProperty: is not supported for date array");
    RLMAssertThrowsWithReason([unmanaged.objectIdObj averageOfProperty:@"self"],
                              @"averageOfProperty: is not supported for object id array");
    RLMAssertThrowsWithReason([unmanaged.uuidObj averageOfProperty:@"self"],
                              @"averageOfProperty: is not supported for uuid array");
    RLMAssertThrowsWithReason([optUnmanaged.boolObj averageOfProperty:@"self"],
                              @"averageOfProperty: is not supported for bool? array");
    RLMAssertThrowsWithReason([optUnmanaged.stringObj averageOfProperty:@"self"],
                              @"averageOfProperty: is not supported for string? array");
    RLMAssertThrowsWithReason([optUnmanaged.dataObj averageOfProperty:@"self"],
                              @"averageOfProperty: is not supported for data? array");
    RLMAssertThrowsWithReason([optUnmanaged.dateObj averageOfProperty:@"self"],
                              @"averageOfProperty: is not supported for date? array");
    RLMAssertThrowsWithReason([optUnmanaged.objectIdObj averageOfProperty:@"self"],
                              @"averageOfProperty: is not supported for object id? array");
    RLMAssertThrowsWithReason([optUnmanaged.uuidObj averageOfProperty:@"self"],
                              @"averageOfProperty: is not supported for uuid? array");
    RLMAssertThrowsWithReason([managed.boolObj averageOfProperty:@"self"],
                              @"averageOfProperty: is not supported for bool array 'AllPrimitiveArrays.boolObj'");
    RLMAssertThrowsWithReason([managed.stringObj averageOfProperty:@"self"],
                              @"averageOfProperty: is not supported for string array 'AllPrimitiveArrays.stringObj'");
    RLMAssertThrowsWithReason([managed.dataObj averageOfProperty:@"self"],
                              @"averageOfProperty: is not supported for data array 'AllPrimitiveArrays.dataObj'");
    RLMAssertThrowsWithReason([managed.dateObj averageOfProperty:@"self"],
                              @"averageOfProperty: is not supported for date array 'AllPrimitiveArrays.dateObj'");
    RLMAssertThrowsWithReason([managed.objectIdObj averageOfProperty:@"self"],
                              @"averageOfProperty: is not supported for object id array 'AllPrimitiveArrays.objectIdObj'");
    RLMAssertThrowsWithReason([managed.uuidObj averageOfProperty:@"self"],
                              @"averageOfProperty: is not supported for uuid array 'AllPrimitiveArrays.uuidObj'");
    RLMAssertThrowsWithReason([optManaged.boolObj averageOfProperty:@"self"],
                              @"averageOfProperty: is not supported for bool? array 'AllOptionalPrimitiveArrays.boolObj'");
    RLMAssertThrowsWithReason([optManaged.stringObj averageOfProperty:@"self"],
                              @"averageOfProperty: is not supported for string? array 'AllOptionalPrimitiveArrays.stringObj'");
    RLMAssertThrowsWithReason([optManaged.dataObj averageOfProperty:@"self"],
                              @"averageOfProperty: is not supported for data? array 'AllOptionalPrimitiveArrays.dataObj'");
    RLMAssertThrowsWithReason([optManaged.dateObj averageOfProperty:@"self"],
                              @"averageOfProperty: is not supported for date? array 'AllOptionalPrimitiveArrays.dateObj'");
    RLMAssertThrowsWithReason([optManaged.objectIdObj averageOfProperty:@"self"],
                              @"averageOfProperty: is not supported for object id? array 'AllOptionalPrimitiveArrays.objectIdObj'");
    RLMAssertThrowsWithReason([optManaged.uuidObj averageOfProperty:@"self"],
                              @"averageOfProperty: is not supported for uuid? array 'AllOptionalPrimitiveArrays.uuidObj'");

    XCTAssertNil([unmanaged.intObj averageOfProperty:@"self"]);
    XCTAssertNil([unmanaged.floatObj averageOfProperty:@"self"]);
    XCTAssertNil([unmanaged.doubleObj averageOfProperty:@"self"]);
    XCTAssertNil([unmanaged.decimalObj averageOfProperty:@"self"]);
    XCTAssertNil([unmanaged.anyIntObj averageOfProperty:@"self"]);
    XCTAssertNil([unmanaged.anyFloatObj averageOfProperty:@"self"]);
    XCTAssertNil([unmanaged.anyDoubleObj averageOfProperty:@"self"]);
    XCTAssertNil([unmanaged.anyDecimalObj averageOfProperty:@"self"]);
    XCTAssertNil([optUnmanaged.intObj averageOfProperty:@"self"]);
    XCTAssertNil([optUnmanaged.floatObj averageOfProperty:@"self"]);
    XCTAssertNil([optUnmanaged.doubleObj averageOfProperty:@"self"]);
    XCTAssertNil([optUnmanaged.decimalObj averageOfProperty:@"self"]);
    XCTAssertNil([managed.intObj averageOfProperty:@"self"]);
    XCTAssertNil([managed.floatObj averageOfProperty:@"self"]);
    XCTAssertNil([managed.doubleObj averageOfProperty:@"self"]);
    XCTAssertNil([managed.decimalObj averageOfProperty:@"self"]);
    XCTAssertNil([managed.anyIntObj averageOfProperty:@"self"]);
    XCTAssertNil([managed.anyFloatObj averageOfProperty:@"self"]);
    XCTAssertNil([managed.anyDoubleObj averageOfProperty:@"self"]);
    XCTAssertNil([managed.anyDecimalObj averageOfProperty:@"self"]);
    XCTAssertNil([optManaged.intObj averageOfProperty:@"self"]);
    XCTAssertNil([optManaged.floatObj averageOfProperty:@"self"]);
    XCTAssertNil([optManaged.doubleObj averageOfProperty:@"self"]);
    XCTAssertNil([optManaged.decimalObj averageOfProperty:@"self"]);

    [self addObjects];

    XCTAssertEqualWithAccuracy([unmanaged.intObj averageOfProperty:@"self"].doubleValue, average(@[@2, @3]), .001);
    XCTAssertEqualWithAccuracy([unmanaged.floatObj averageOfProperty:@"self"].doubleValue, average(@[@2.2f, @3.3f]), .001);
    XCTAssertEqualWithAccuracy([unmanaged.doubleObj averageOfProperty:@"self"].doubleValue, average(@[@2.2, @3.3]), .001);
    XCTAssertEqualWithAccuracy([unmanaged.decimalObj averageOfProperty:@"self"].doubleValue, average(@[decimal128(2), decimal128(3)]), .001);
    XCTAssertEqualWithAccuracy([unmanaged.anyIntObj averageOfProperty:@"self"].doubleValue, average(@[@2, @3]), .001);
    XCTAssertEqualWithAccuracy([unmanaged.anyFloatObj averageOfProperty:@"self"].doubleValue, average(@[@2.2f, @3.3f]), .001);
    XCTAssertEqualWithAccuracy([unmanaged.anyDoubleObj averageOfProperty:@"self"].doubleValue, average(@[@2.2, @3.3]), .001);
    XCTAssertEqualWithAccuracy([unmanaged.anyDecimalObj averageOfProperty:@"self"].doubleValue, average(@[decimal128(2), decimal128(3)]), .001);
    XCTAssertEqualWithAccuracy([optUnmanaged.intObj averageOfProperty:@"self"].doubleValue, average(@[@2, @3, NSNull.null]), .001);
    XCTAssertEqualWithAccuracy([optUnmanaged.floatObj averageOfProperty:@"self"].doubleValue, average(@[@2.2f, @3.3f, NSNull.null]), .001);
    XCTAssertEqualWithAccuracy([optUnmanaged.doubleObj averageOfProperty:@"self"].doubleValue, average(@[@2.2, @3.3, NSNull.null]), .001);
    XCTAssertEqualWithAccuracy([optUnmanaged.decimalObj averageOfProperty:@"self"].doubleValue, average(@[decimal128(2), decimal128(3), NSNull.null]), .001);
    XCTAssertEqualWithAccuracy([managed.intObj averageOfProperty:@"self"].doubleValue, average(@[@2, @3]), .001);
    XCTAssertEqualWithAccuracy([managed.floatObj averageOfProperty:@"self"].doubleValue, average(@[@2.2f, @3.3f]), .001);
    XCTAssertEqualWithAccuracy([managed.doubleObj averageOfProperty:@"self"].doubleValue, average(@[@2.2, @3.3]), .001);
    XCTAssertEqualWithAccuracy([managed.decimalObj averageOfProperty:@"self"].doubleValue, average(@[decimal128(2), decimal128(3)]), .001);
    XCTAssertEqualWithAccuracy([managed.anyIntObj averageOfProperty:@"self"].doubleValue, average(@[@2, @3]), .001);
    XCTAssertEqualWithAccuracy([managed.anyFloatObj averageOfProperty:@"self"].doubleValue, average(@[@2.2f, @3.3f]), .001);
    XCTAssertEqualWithAccuracy([managed.anyDoubleObj averageOfProperty:@"self"].doubleValue, average(@[@2.2, @3.3]), .001);
    XCTAssertEqualWithAccuracy([managed.anyDecimalObj averageOfProperty:@"self"].doubleValue, average(@[decimal128(2), decimal128(3)]), .001);
    XCTAssertEqualWithAccuracy([optManaged.intObj averageOfProperty:@"self"].doubleValue, average(@[@2, @3, NSNull.null]), .001);
    XCTAssertEqualWithAccuracy([optManaged.floatObj averageOfProperty:@"self"].doubleValue, average(@[@2.2f, @3.3f, NSNull.null]), .001);
    XCTAssertEqualWithAccuracy([optManaged.doubleObj averageOfProperty:@"self"].doubleValue, average(@[@2.2, @3.3, NSNull.null]), .001);
    XCTAssertEqualWithAccuracy([optManaged.decimalObj averageOfProperty:@"self"].doubleValue, average(@[decimal128(2), decimal128(3), NSNull.null]), .001);
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
    NSArray *values = @[decimal128(2), decimal128(3)];
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
    NSArray *values = @[uuid(@"00000000-0000-0000-0000-000000000000"), uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")];
    for (id value in unmanaged.uuidObj) {
    XCTAssertEqualObjects(values[i++ % values.count], value);
    }
    XCTAssertEqual(i, unmanaged.uuidObj.count);
    }
    
    {
    NSUInteger i = 0;
    NSArray *values = @[@NO, @YES];
    for (id value in unmanaged.anyBoolObj) {
    XCTAssertEqualObjects(values[i++ % values.count], value);
    }
    XCTAssertEqual(i, unmanaged.anyBoolObj.count);
    }
    
    {
    NSUInteger i = 0;
    NSArray *values = @[@2, @3];
    for (id value in unmanaged.anyIntObj) {
    XCTAssertEqualObjects(values[i++ % values.count], value);
    }
    XCTAssertEqual(i, unmanaged.anyIntObj.count);
    }
    
    {
    NSUInteger i = 0;
    NSArray *values = @[@2.2f, @3.3f];
    for (id value in unmanaged.anyFloatObj) {
    XCTAssertEqualObjects(values[i++ % values.count], value);
    }
    XCTAssertEqual(i, unmanaged.anyFloatObj.count);
    }
    
    {
    NSUInteger i = 0;
    NSArray *values = @[@2.2, @3.3];
    for (id value in unmanaged.anyDoubleObj) {
    XCTAssertEqualObjects(values[i++ % values.count], value);
    }
    XCTAssertEqual(i, unmanaged.anyDoubleObj.count);
    }
    
    {
    NSUInteger i = 0;
    NSArray *values = @[@"a", @"b"];
    for (id value in unmanaged.anyStringObj) {
    XCTAssertEqualObjects(values[i++ % values.count], value);
    }
    XCTAssertEqual(i, unmanaged.anyStringObj.count);
    }
    
    {
    NSUInteger i = 0;
    NSArray *values = @[data(1), data(2)];
    for (id value in unmanaged.anyDataObj) {
    XCTAssertEqualObjects(values[i++ % values.count], value);
    }
    XCTAssertEqual(i, unmanaged.anyDataObj.count);
    }
    
    {
    NSUInteger i = 0;
    NSArray *values = @[date(1), date(2)];
    for (id value in unmanaged.anyDateObj) {
    XCTAssertEqualObjects(values[i++ % values.count], value);
    }
    XCTAssertEqual(i, unmanaged.anyDateObj.count);
    }
    
    {
    NSUInteger i = 0;
    NSArray *values = @[decimal128(2), decimal128(3)];
    for (id value in unmanaged.anyDecimalObj) {
    XCTAssertEqualObjects(values[i++ % values.count], value);
    }
    XCTAssertEqual(i, unmanaged.anyDecimalObj.count);
    }
    
    {
    NSUInteger i = 0;
    NSArray *values = @[objectId(1), objectId(2)];
    for (id value in unmanaged.anyObjectIdObj) {
    XCTAssertEqualObjects(values[i++ % values.count], value);
    }
    XCTAssertEqual(i, unmanaged.anyObjectIdObj.count);
    }
    
    {
    NSUInteger i = 0;
    NSArray *values = @[uuid(@"00000000-0000-0000-0000-000000000000"), uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")];
    for (id value in unmanaged.anyUUIDObj) {
    XCTAssertEqualObjects(values[i++ % values.count], value);
    }
    XCTAssertEqual(i, unmanaged.anyUUIDObj.count);
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
    NSArray *values = @[decimal128(2), decimal128(3), NSNull.null];
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
    NSArray *values = @[uuid(@"00000000-0000-0000-0000-000000000000"), uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"), NSNull.null];
    for (id value in optUnmanaged.uuidObj) {
    XCTAssertEqualObjects(values[i++ % values.count], value);
    }
    XCTAssertEqual(i, optUnmanaged.uuidObj.count);
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
    NSArray *values = @[decimal128(2), decimal128(3)];
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
    NSArray *values = @[uuid(@"00000000-0000-0000-0000-000000000000"), uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")];
    for (id value in managed.uuidObj) {
    XCTAssertEqualObjects(values[i++ % values.count], value);
    }
    XCTAssertEqual(i, managed.uuidObj.count);
    }
    
    {
    NSUInteger i = 0;
    NSArray *values = @[@NO, @YES];
    for (id value in managed.anyBoolObj) {
    XCTAssertEqualObjects(values[i++ % values.count], value);
    }
    XCTAssertEqual(i, managed.anyBoolObj.count);
    }
    
    {
    NSUInteger i = 0;
    NSArray *values = @[@2, @3];
    for (id value in managed.anyIntObj) {
    XCTAssertEqualObjects(values[i++ % values.count], value);
    }
    XCTAssertEqual(i, managed.anyIntObj.count);
    }
    
    {
    NSUInteger i = 0;
    NSArray *values = @[@2.2f, @3.3f];
    for (id value in managed.anyFloatObj) {
    XCTAssertEqualObjects(values[i++ % values.count], value);
    }
    XCTAssertEqual(i, managed.anyFloatObj.count);
    }
    
    {
    NSUInteger i = 0;
    NSArray *values = @[@2.2, @3.3];
    for (id value in managed.anyDoubleObj) {
    XCTAssertEqualObjects(values[i++ % values.count], value);
    }
    XCTAssertEqual(i, managed.anyDoubleObj.count);
    }
    
    {
    NSUInteger i = 0;
    NSArray *values = @[@"a", @"b"];
    for (id value in managed.anyStringObj) {
    XCTAssertEqualObjects(values[i++ % values.count], value);
    }
    XCTAssertEqual(i, managed.anyStringObj.count);
    }
    
    {
    NSUInteger i = 0;
    NSArray *values = @[data(1), data(2)];
    for (id value in managed.anyDataObj) {
    XCTAssertEqualObjects(values[i++ % values.count], value);
    }
    XCTAssertEqual(i, managed.anyDataObj.count);
    }
    
    {
    NSUInteger i = 0;
    NSArray *values = @[date(1), date(2)];
    for (id value in managed.anyDateObj) {
    XCTAssertEqualObjects(values[i++ % values.count], value);
    }
    XCTAssertEqual(i, managed.anyDateObj.count);
    }
    
    {
    NSUInteger i = 0;
    NSArray *values = @[decimal128(2), decimal128(3)];
    for (id value in managed.anyDecimalObj) {
    XCTAssertEqualObjects(values[i++ % values.count], value);
    }
    XCTAssertEqual(i, managed.anyDecimalObj.count);
    }
    
    {
    NSUInteger i = 0;
    NSArray *values = @[objectId(1), objectId(2)];
    for (id value in managed.anyObjectIdObj) {
    XCTAssertEqualObjects(values[i++ % values.count], value);
    }
    XCTAssertEqual(i, managed.anyObjectIdObj.count);
    }
    
    {
    NSUInteger i = 0;
    NSArray *values = @[uuid(@"00000000-0000-0000-0000-000000000000"), uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")];
    for (id value in managed.anyUUIDObj) {
    XCTAssertEqualObjects(values[i++ % values.count], value);
    }
    XCTAssertEqual(i, managed.anyUUIDObj.count);
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
    NSArray *values = @[decimal128(2), decimal128(3), NSNull.null];
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
    
    {
    NSUInteger i = 0;
    NSArray *values = @[uuid(@"00000000-0000-0000-0000-000000000000"), uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"), NSNull.null];
    for (id value in optManaged.uuidObj) {
    XCTAssertEqualObjects(values[i++ % values.count], value);
    }
    XCTAssertEqual(i, optManaged.uuidObj.count);
    }
    
}

- (void)testValueForKeySelf {
    for (RLMArray *array in allArrays) {
        XCTAssertEqualObjects([array valueForKey:@"self"], @[]);
    }

    [self addObjects];

    XCTAssertEqualObjects([unmanaged.boolObj valueForKey:@"self"], (@[@NO, @YES]));
    XCTAssertEqualObjects([unmanaged.intObj valueForKey:@"self"], (@[@2, @3]));
    XCTAssertEqualObjects([unmanaged.floatObj valueForKey:@"self"], (@[@2.2f, @3.3f]));
    XCTAssertEqualObjects([unmanaged.doubleObj valueForKey:@"self"], (@[@2.2, @3.3]));
    XCTAssertEqualObjects([unmanaged.stringObj valueForKey:@"self"], (@[@"a", @"b"]));
    XCTAssertEqualObjects([unmanaged.dataObj valueForKey:@"self"], (@[data(1), data(2)]));
    XCTAssertEqualObjects([unmanaged.dateObj valueForKey:@"self"], (@[date(1), date(2)]));
    XCTAssertEqualObjects([unmanaged.decimalObj valueForKey:@"self"], (@[decimal128(2), decimal128(3)]));
    XCTAssertEqualObjects([unmanaged.objectIdObj valueForKey:@"self"], (@[objectId(1), objectId(2)]));
    XCTAssertEqualObjects([unmanaged.uuidObj valueForKey:@"self"], (@[uuid(@"00000000-0000-0000-0000-000000000000"), uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")]));
    XCTAssertEqualObjects([unmanaged.anyBoolObj valueForKey:@"self"], (@[@NO, @YES]));
    XCTAssertEqualObjects([unmanaged.anyIntObj valueForKey:@"self"], (@[@2, @3]));
    XCTAssertEqualObjects([unmanaged.anyFloatObj valueForKey:@"self"], (@[@2.2f, @3.3f]));
    XCTAssertEqualObjects([unmanaged.anyDoubleObj valueForKey:@"self"], (@[@2.2, @3.3]));
    XCTAssertEqualObjects([unmanaged.anyStringObj valueForKey:@"self"], (@[@"a", @"b"]));
    XCTAssertEqualObjects([unmanaged.anyDataObj valueForKey:@"self"], (@[data(1), data(2)]));
    XCTAssertEqualObjects([unmanaged.anyDateObj valueForKey:@"self"], (@[date(1), date(2)]));
    XCTAssertEqualObjects([unmanaged.anyDecimalObj valueForKey:@"self"], (@[decimal128(2), decimal128(3)]));
    XCTAssertEqualObjects([unmanaged.anyObjectIdObj valueForKey:@"self"], (@[objectId(1), objectId(2)]));
    XCTAssertEqualObjects([unmanaged.anyUUIDObj valueForKey:@"self"], (@[uuid(@"00000000-0000-0000-0000-000000000000"), uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")]));
    XCTAssertEqualObjects([optUnmanaged.boolObj valueForKey:@"self"], (@[@NO, @YES, NSNull.null]));
    XCTAssertEqualObjects([optUnmanaged.intObj valueForKey:@"self"], (@[@2, @3, NSNull.null]));
    XCTAssertEqualObjects([optUnmanaged.floatObj valueForKey:@"self"], (@[@2.2f, @3.3f, NSNull.null]));
    XCTAssertEqualObjects([optUnmanaged.doubleObj valueForKey:@"self"], (@[@2.2, @3.3, NSNull.null]));
    XCTAssertEqualObjects([optUnmanaged.stringObj valueForKey:@"self"], (@[@"a", @"b", NSNull.null]));
    XCTAssertEqualObjects([optUnmanaged.dataObj valueForKey:@"self"], (@[data(1), data(2), NSNull.null]));
    XCTAssertEqualObjects([optUnmanaged.dateObj valueForKey:@"self"], (@[date(1), date(2), NSNull.null]));
    XCTAssertEqualObjects([optUnmanaged.decimalObj valueForKey:@"self"], (@[decimal128(2), decimal128(3), NSNull.null]));
    XCTAssertEqualObjects([optUnmanaged.objectIdObj valueForKey:@"self"], (@[objectId(1), objectId(2), NSNull.null]));
    XCTAssertEqualObjects([optUnmanaged.uuidObj valueForKey:@"self"], (@[uuid(@"00000000-0000-0000-0000-000000000000"), uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"), NSNull.null]));
    XCTAssertEqualObjects([managed.boolObj valueForKey:@"self"], (@[@NO, @YES]));
    XCTAssertEqualObjects([managed.intObj valueForKey:@"self"], (@[@2, @3]));
    XCTAssertEqualObjects([managed.floatObj valueForKey:@"self"], (@[@2.2f, @3.3f]));
    XCTAssertEqualObjects([managed.doubleObj valueForKey:@"self"], (@[@2.2, @3.3]));
    XCTAssertEqualObjects([managed.stringObj valueForKey:@"self"], (@[@"a", @"b"]));
    XCTAssertEqualObjects([managed.dataObj valueForKey:@"self"], (@[data(1), data(2)]));
    XCTAssertEqualObjects([managed.dateObj valueForKey:@"self"], (@[date(1), date(2)]));
    XCTAssertEqualObjects([managed.decimalObj valueForKey:@"self"], (@[decimal128(2), decimal128(3)]));
    XCTAssertEqualObjects([managed.objectIdObj valueForKey:@"self"], (@[objectId(1), objectId(2)]));
    XCTAssertEqualObjects([managed.uuidObj valueForKey:@"self"], (@[uuid(@"00000000-0000-0000-0000-000000000000"), uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")]));
    XCTAssertEqualObjects([managed.anyBoolObj valueForKey:@"self"], (@[@NO, @YES]));
    XCTAssertEqualObjects([managed.anyIntObj valueForKey:@"self"], (@[@2, @3]));
    XCTAssertEqualObjects([managed.anyFloatObj valueForKey:@"self"], (@[@2.2f, @3.3f]));
    XCTAssertEqualObjects([managed.anyDoubleObj valueForKey:@"self"], (@[@2.2, @3.3]));
    XCTAssertEqualObjects([managed.anyStringObj valueForKey:@"self"], (@[@"a", @"b"]));
    XCTAssertEqualObjects([managed.anyDataObj valueForKey:@"self"], (@[data(1), data(2)]));
    XCTAssertEqualObjects([managed.anyDateObj valueForKey:@"self"], (@[date(1), date(2)]));
    XCTAssertEqualObjects([managed.anyDecimalObj valueForKey:@"self"], (@[decimal128(2), decimal128(3)]));
    XCTAssertEqualObjects([managed.anyObjectIdObj valueForKey:@"self"], (@[objectId(1), objectId(2)]));
    XCTAssertEqualObjects([managed.anyUUIDObj valueForKey:@"self"], (@[uuid(@"00000000-0000-0000-0000-000000000000"), uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")]));
    XCTAssertEqualObjects([optManaged.boolObj valueForKey:@"self"], (@[@NO, @YES, NSNull.null]));
    XCTAssertEqualObjects([optManaged.intObj valueForKey:@"self"], (@[@2, @3, NSNull.null]));
    XCTAssertEqualObjects([optManaged.floatObj valueForKey:@"self"], (@[@2.2f, @3.3f, NSNull.null]));
    XCTAssertEqualObjects([optManaged.doubleObj valueForKey:@"self"], (@[@2.2, @3.3, NSNull.null]));
    XCTAssertEqualObjects([optManaged.stringObj valueForKey:@"self"], (@[@"a", @"b", NSNull.null]));
    XCTAssertEqualObjects([optManaged.dataObj valueForKey:@"self"], (@[data(1), data(2), NSNull.null]));
    XCTAssertEqualObjects([optManaged.dateObj valueForKey:@"self"], (@[date(1), date(2), NSNull.null]));
    XCTAssertEqualObjects([optManaged.decimalObj valueForKey:@"self"], (@[decimal128(2), decimal128(3), NSNull.null]));
    XCTAssertEqualObjects([optManaged.objectIdObj valueForKey:@"self"], (@[objectId(1), objectId(2), NSNull.null]));
    XCTAssertEqualObjects([optManaged.uuidObj valueForKey:@"self"], (@[uuid(@"00000000-0000-0000-0000-000000000000"), uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"), NSNull.null]));
}

- (void)testValueForKeyNumericAggregates {
    XCTAssertNil([unmanaged.intObj valueForKeyPath:@"@min.self"]);
    XCTAssertNil([unmanaged.floatObj valueForKeyPath:@"@min.self"]);
    XCTAssertNil([unmanaged.doubleObj valueForKeyPath:@"@min.self"]);
    XCTAssertNil([unmanaged.dateObj valueForKeyPath:@"@min.self"]);
    XCTAssertNil([unmanaged.decimalObj valueForKeyPath:@"@min.self"]);
    XCTAssertNil([unmanaged.anyFloatObj valueForKeyPath:@"@min.self"]);
    XCTAssertNil([unmanaged.anyDoubleObj valueForKeyPath:@"@min.self"]);
    XCTAssertNil([unmanaged.anyDateObj valueForKeyPath:@"@min.self"]);
    XCTAssertNil([unmanaged.anyDecimalObj valueForKeyPath:@"@min.self"]);
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
    XCTAssertNil([managed.anyIntObj valueForKeyPath:@"@min.self"]);
    XCTAssertNil([managed.anyFloatObj valueForKeyPath:@"@min.self"]);
    XCTAssertNil([managed.anyDoubleObj valueForKeyPath:@"@min.self"]);
    XCTAssertNil([managed.anyDateObj valueForKeyPath:@"@min.self"]);
    XCTAssertNil([managed.anyDecimalObj valueForKeyPath:@"@min.self"]);
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
    XCTAssertNil([unmanaged.anyFloatObj valueForKeyPath:@"@max.self"]);
    XCTAssertNil([unmanaged.anyDoubleObj valueForKeyPath:@"@max.self"]);
    XCTAssertNil([unmanaged.anyDateObj valueForKeyPath:@"@max.self"]);
    XCTAssertNil([unmanaged.anyDecimalObj valueForKeyPath:@"@max.self"]);
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
    XCTAssertNil([managed.anyIntObj valueForKeyPath:@"@max.self"]);
    XCTAssertNil([managed.anyFloatObj valueForKeyPath:@"@max.self"]);
    XCTAssertNil([managed.anyDoubleObj valueForKeyPath:@"@max.self"]);
    XCTAssertNil([managed.anyDateObj valueForKeyPath:@"@max.self"]);
    XCTAssertNil([managed.anyDecimalObj valueForKeyPath:@"@max.self"]);
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
    XCTAssertEqualObjects([unmanaged.decimalObj valueForKeyPath:@"@min.self"], decimal128(2));
    XCTAssertEqualObjects([unmanaged.anyFloatObj valueForKeyPath:@"@min.self"], @2.2f);
    XCTAssertEqualObjects([unmanaged.anyDoubleObj valueForKeyPath:@"@min.self"], @2.2);
    XCTAssertEqualObjects([unmanaged.anyDateObj valueForKeyPath:@"@min.self"], date(1));
    XCTAssertEqualObjects([unmanaged.anyDecimalObj valueForKeyPath:@"@min.self"], decimal128(2));
    XCTAssertEqualObjects([optUnmanaged.intObj valueForKeyPath:@"@min.self"], @2);
    XCTAssertEqualObjects([optUnmanaged.floatObj valueForKeyPath:@"@min.self"], @2.2f);
    XCTAssertEqualObjects([optUnmanaged.doubleObj valueForKeyPath:@"@min.self"], @2.2);
    XCTAssertEqualObjects([optUnmanaged.dateObj valueForKeyPath:@"@min.self"], date(1));
    XCTAssertEqualObjects([optUnmanaged.decimalObj valueForKeyPath:@"@min.self"], decimal128(2));
    XCTAssertEqualObjects([managed.intObj valueForKeyPath:@"@min.self"], @2);
    XCTAssertEqualObjects([managed.floatObj valueForKeyPath:@"@min.self"], @2.2f);
    XCTAssertEqualObjects([managed.doubleObj valueForKeyPath:@"@min.self"], @2.2);
    XCTAssertEqualObjects([managed.dateObj valueForKeyPath:@"@min.self"], date(1));
    XCTAssertEqualObjects([managed.decimalObj valueForKeyPath:@"@min.self"], decimal128(2));
    XCTAssertEqualObjects([managed.anyIntObj valueForKeyPath:@"@min.self"], @2);
    XCTAssertEqualObjects([managed.anyFloatObj valueForKeyPath:@"@min.self"], @2.2f);
    XCTAssertEqualObjects([managed.anyDoubleObj valueForKeyPath:@"@min.self"], @2.2);
    XCTAssertEqualObjects([managed.anyDateObj valueForKeyPath:@"@min.self"], date(1));
    XCTAssertEqualObjects([managed.anyDecimalObj valueForKeyPath:@"@min.self"], decimal128(2));
    XCTAssertEqualObjects([optManaged.intObj valueForKeyPath:@"@min.self"], @2);
    XCTAssertEqualObjects([optManaged.floatObj valueForKeyPath:@"@min.self"], @2.2f);
    XCTAssertEqualObjects([optManaged.doubleObj valueForKeyPath:@"@min.self"], @2.2);
    XCTAssertEqualObjects([optManaged.dateObj valueForKeyPath:@"@min.self"], date(1));
    XCTAssertEqualObjects([optManaged.decimalObj valueForKeyPath:@"@min.self"], decimal128(2));
    XCTAssertEqualObjects([unmanaged.intObj valueForKeyPath:@"@max.self"], @3);
    XCTAssertEqualObjects([unmanaged.floatObj valueForKeyPath:@"@max.self"], @3.3f);
    XCTAssertEqualObjects([unmanaged.doubleObj valueForKeyPath:@"@max.self"], @3.3);
    XCTAssertEqualObjects([unmanaged.dateObj valueForKeyPath:@"@max.self"], date(2));
    XCTAssertEqualObjects([unmanaged.decimalObj valueForKeyPath:@"@max.self"], decimal128(3));
    XCTAssertEqualObjects([unmanaged.anyFloatObj valueForKeyPath:@"@max.self"], @3.3f);
    XCTAssertEqualObjects([unmanaged.anyDoubleObj valueForKeyPath:@"@max.self"], @3.3);
    XCTAssertEqualObjects([unmanaged.anyDateObj valueForKeyPath:@"@max.self"], date(2));
    XCTAssertEqualObjects([unmanaged.anyDecimalObj valueForKeyPath:@"@max.self"], decimal128(3));
    XCTAssertEqualObjects([optUnmanaged.intObj valueForKeyPath:@"@max.self"], @3);
    XCTAssertEqualObjects([optUnmanaged.floatObj valueForKeyPath:@"@max.self"], @3.3f);
    XCTAssertEqualObjects([optUnmanaged.doubleObj valueForKeyPath:@"@max.self"], @3.3);
    XCTAssertEqualObjects([optUnmanaged.dateObj valueForKeyPath:@"@max.self"], date(2));
    XCTAssertEqualObjects([optUnmanaged.decimalObj valueForKeyPath:@"@max.self"], decimal128(3));
    XCTAssertEqualObjects([managed.intObj valueForKeyPath:@"@max.self"], @3);
    XCTAssertEqualObjects([managed.floatObj valueForKeyPath:@"@max.self"], @3.3f);
    XCTAssertEqualObjects([managed.doubleObj valueForKeyPath:@"@max.self"], @3.3);
    XCTAssertEqualObjects([managed.dateObj valueForKeyPath:@"@max.self"], date(2));
    XCTAssertEqualObjects([managed.decimalObj valueForKeyPath:@"@max.self"], decimal128(3));
    XCTAssertEqualObjects([managed.anyIntObj valueForKeyPath:@"@max.self"], @3);
    XCTAssertEqualObjects([managed.anyFloatObj valueForKeyPath:@"@max.self"], @3.3f);
    XCTAssertEqualObjects([managed.anyDoubleObj valueForKeyPath:@"@max.self"], @3.3);
    XCTAssertEqualObjects([managed.anyDateObj valueForKeyPath:@"@max.self"], date(2));
    XCTAssertEqualObjects([managed.anyDecimalObj valueForKeyPath:@"@max.self"], decimal128(3));
    XCTAssertEqualObjects([optManaged.intObj valueForKeyPath:@"@max.self"], @3);
    XCTAssertEqualObjects([optManaged.floatObj valueForKeyPath:@"@max.self"], @3.3f);
    XCTAssertEqualObjects([optManaged.doubleObj valueForKeyPath:@"@max.self"], @3.3);
    XCTAssertEqualObjects([optManaged.dateObj valueForKeyPath:@"@max.self"], date(2));
    XCTAssertEqualObjects([optManaged.decimalObj valueForKeyPath:@"@max.self"], decimal128(3));
    XCTAssertEqualWithAccuracy([[unmanaged.intObj valueForKeyPath:@"@sum.self"] doubleValue], sum(@[@2, @3]), .001);
    XCTAssertEqualWithAccuracy([[unmanaged.floatObj valueForKeyPath:@"@sum.self"] doubleValue], sum(@[@2.2f, @3.3f]), .001);
    XCTAssertEqualWithAccuracy([[unmanaged.doubleObj valueForKeyPath:@"@sum.self"] doubleValue], sum(@[@2.2, @3.3]), .001);
    XCTAssertEqualWithAccuracy([[unmanaged.decimalObj valueForKeyPath:@"@sum.self"] doubleValue], sum(@[decimal128(2), decimal128(3)]), .001);
    XCTAssertEqualWithAccuracy([[optUnmanaged.intObj valueForKeyPath:@"@sum.self"] doubleValue], sum(@[@2, @3, NSNull.null]), .001);
    XCTAssertEqualWithAccuracy([[optUnmanaged.floatObj valueForKeyPath:@"@sum.self"] doubleValue], sum(@[@2.2f, @3.3f, NSNull.null]), .001);
    XCTAssertEqualWithAccuracy([[optUnmanaged.doubleObj valueForKeyPath:@"@sum.self"] doubleValue], sum(@[@2.2, @3.3, NSNull.null]), .001);
    XCTAssertEqualWithAccuracy([[optUnmanaged.decimalObj valueForKeyPath:@"@sum.self"] doubleValue], sum(@[decimal128(2), decimal128(3), NSNull.null]), .001);
    XCTAssertEqualWithAccuracy([[managed.intObj valueForKeyPath:@"@sum.self"] doubleValue], sum(@[@2, @3]), .001);
    XCTAssertEqualWithAccuracy([[managed.floatObj valueForKeyPath:@"@sum.self"] doubleValue], sum(@[@2.2f, @3.3f]), .001);
    XCTAssertEqualWithAccuracy([[managed.doubleObj valueForKeyPath:@"@sum.self"] doubleValue], sum(@[@2.2, @3.3]), .001);
    XCTAssertEqualWithAccuracy([[managed.decimalObj valueForKeyPath:@"@sum.self"] doubleValue], sum(@[decimal128(2), decimal128(3)]), .001);
    XCTAssertEqualWithAccuracy([[optManaged.intObj valueForKeyPath:@"@sum.self"] doubleValue], sum(@[@2, @3, NSNull.null]), .001);
    XCTAssertEqualWithAccuracy([[optManaged.floatObj valueForKeyPath:@"@sum.self"] doubleValue], sum(@[@2.2f, @3.3f, NSNull.null]), .001);
    XCTAssertEqualWithAccuracy([[optManaged.doubleObj valueForKeyPath:@"@sum.self"] doubleValue], sum(@[@2.2, @3.3, NSNull.null]), .001);
    XCTAssertEqualWithAccuracy([[optManaged.decimalObj valueForKeyPath:@"@sum.self"] doubleValue], sum(@[decimal128(2), decimal128(3), NSNull.null]), .001);
    XCTAssertEqualWithAccuracy([[unmanaged.intObj valueForKeyPath:@"@avg.self"] doubleValue], average(@[@2, @3]), .001);
    XCTAssertEqualWithAccuracy([[unmanaged.floatObj valueForKeyPath:@"@avg.self"] doubleValue], average(@[@2.2f, @3.3f]), .001);
    XCTAssertEqualWithAccuracy([[unmanaged.doubleObj valueForKeyPath:@"@avg.self"] doubleValue], average(@[@2.2, @3.3]), .001);
    XCTAssertEqualWithAccuracy([[unmanaged.decimalObj valueForKeyPath:@"@avg.self"] doubleValue], average(@[decimal128(2), decimal128(3)]), .001);
    XCTAssertEqualWithAccuracy([[optUnmanaged.intObj valueForKeyPath:@"@avg.self"] doubleValue], average(@[@2, @3, NSNull.null]), .001);
    XCTAssertEqualWithAccuracy([[optUnmanaged.floatObj valueForKeyPath:@"@avg.self"] doubleValue], average(@[@2.2f, @3.3f, NSNull.null]), .001);
    XCTAssertEqualWithAccuracy([[optUnmanaged.doubleObj valueForKeyPath:@"@avg.self"] doubleValue], average(@[@2.2, @3.3, NSNull.null]), .001);
    XCTAssertEqualWithAccuracy([[optUnmanaged.decimalObj valueForKeyPath:@"@avg.self"] doubleValue], average(@[decimal128(2), decimal128(3), NSNull.null]), .001);
    XCTAssertEqualWithAccuracy([[managed.intObj valueForKeyPath:@"@avg.self"] doubleValue], average(@[@2, @3]), .001);
    XCTAssertEqualWithAccuracy([[managed.floatObj valueForKeyPath:@"@avg.self"] doubleValue], average(@[@2.2f, @3.3f]), .001);
    XCTAssertEqualWithAccuracy([[managed.doubleObj valueForKeyPath:@"@avg.self"] doubleValue], average(@[@2.2, @3.3]), .001);
    XCTAssertEqualWithAccuracy([[managed.decimalObj valueForKeyPath:@"@avg.self"] doubleValue], average(@[decimal128(2), decimal128(3)]), .001);
    XCTAssertEqualWithAccuracy([[optManaged.intObj valueForKeyPath:@"@avg.self"] doubleValue], average(@[@2, @3, NSNull.null]), .001);
    XCTAssertEqualWithAccuracy([[optManaged.floatObj valueForKeyPath:@"@avg.self"] doubleValue], average(@[@2.2f, @3.3f, NSNull.null]), .001);
    XCTAssertEqualWithAccuracy([[optManaged.doubleObj valueForKeyPath:@"@avg.self"] doubleValue], average(@[@2.2, @3.3, NSNull.null]), .001);
    XCTAssertEqualWithAccuracy([[optManaged.decimalObj valueForKeyPath:@"@avg.self"] doubleValue], average(@[decimal128(2), decimal128(3), NSNull.null]), .001);
}

- (void)testValueForKeyLength {
    for (RLMArray *array in allArrays) {
        XCTAssertEqualObjects([array valueForKey:@"length"], @[]);
    }

    [self addObjects];

    XCTAssertEqualObjects([unmanaged.stringObj valueForKey:@"length"], ([@[@"a", @"b"] valueForKey:@"length"]));
    XCTAssertEqualObjects([unmanaged.anyStringObj valueForKey:@"length"], ([@[@"a", @"b"] valueForKey:@"length"]));
    XCTAssertEqualObjects([optUnmanaged.stringObj valueForKey:@"length"], ([@[@"a", @"b", NSNull.null] valueForKey:@"length"]));
    XCTAssertEqualObjects([managed.stringObj valueForKey:@"length"], ([@[@"a", @"b"] valueForKey:@"length"]));
    XCTAssertEqualObjects([managed.anyStringObj valueForKey:@"length"], ([@[@"a", @"b"] valueForKey:@"length"]));
    XCTAssertEqualObjects([optManaged.stringObj valueForKey:@"length"], ([@[@"a", @"b", NSNull.null] valueForKey:@"length"]));
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

                if ([a respondsToSelector:@selector(objCType)]
                    && [b respondsToSelector:@selector(objCType)]) {
                    return [a compare:b];
                } else {
                    if ([a isKindOfClass:[RLMDecimal128 class]]) {
                        a = [NSNumber numberWithDouble:[(RLMDecimal128 *)a doubleValue]];
                    }
                    if ([b isKindOfClass:[RLMDecimal128 class]]) {
                        b = [NSNumber numberWithDouble:[(RLMDecimal128 *)b doubleValue]];
                    }
                    return [a compare:b];
                }
            }];
}

- (void)testUnionOfObjects {
    for (RLMArray *array in allArrays) {
        XCTAssertEqualObjects([array valueForKeyPath:@"@unionOfObjects.self"], @[]);
    }
    for (RLMArray *array in allArrays) {
        XCTAssertEqualObjects([array valueForKeyPath:@"@distinctUnionOfObjects.self"], @[]);
    }

    [self addObjects];
    [self addObjects];

    XCTAssertEqualObjects([unmanaged.boolObj valueForKeyPath:@"@unionOfObjects.self"],
                          (@[@NO, @YES, @NO, @YES]));
    XCTAssertEqualObjects([unmanaged.intObj valueForKeyPath:@"@unionOfObjects.self"],
                          (@[@2, @3, @2, @3]));
    XCTAssertEqualObjects([unmanaged.floatObj valueForKeyPath:@"@unionOfObjects.self"],
                          (@[@2.2f, @3.3f, @2.2f, @3.3f]));
    XCTAssertEqualObjects([unmanaged.doubleObj valueForKeyPath:@"@unionOfObjects.self"],
                          (@[@2.2, @3.3, @2.2, @3.3]));
    XCTAssertEqualObjects([unmanaged.stringObj valueForKeyPath:@"@unionOfObjects.self"],
                          (@[@"a", @"b", @"a", @"b"]));
    XCTAssertEqualObjects([unmanaged.dataObj valueForKeyPath:@"@unionOfObjects.self"],
                          (@[data(1), data(2), data(1), data(2)]));
    XCTAssertEqualObjects([unmanaged.dateObj valueForKeyPath:@"@unionOfObjects.self"],
                          (@[date(1), date(2), date(1), date(2)]));
    XCTAssertEqualObjects([unmanaged.decimalObj valueForKeyPath:@"@unionOfObjects.self"],
                          (@[decimal128(2), decimal128(3), decimal128(2), decimal128(3)]));
    XCTAssertEqualObjects([unmanaged.objectIdObj valueForKeyPath:@"@unionOfObjects.self"],
                          (@[objectId(1), objectId(2), objectId(1), objectId(2)]));
    XCTAssertEqualObjects([unmanaged.uuidObj valueForKeyPath:@"@unionOfObjects.self"],
                          (@[uuid(@"00000000-0000-0000-0000-000000000000"), uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"), uuid(@"00000000-0000-0000-0000-000000000000"), uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")]));
    XCTAssertEqualObjects([unmanaged.anyBoolObj valueForKeyPath:@"@unionOfObjects.self"],
                          (@[@NO, @YES, @NO, @YES]));
    XCTAssertEqualObjects([unmanaged.anyIntObj valueForKeyPath:@"@unionOfObjects.self"],
                          (@[@2, @3, @2, @3]));
    XCTAssertEqualObjects([unmanaged.anyFloatObj valueForKeyPath:@"@unionOfObjects.self"],
                          (@[@2.2f, @3.3f, @2.2f, @3.3f]));
    XCTAssertEqualObjects([unmanaged.anyDoubleObj valueForKeyPath:@"@unionOfObjects.self"],
                          (@[@2.2, @3.3, @2.2, @3.3]));
    XCTAssertEqualObjects([unmanaged.anyStringObj valueForKeyPath:@"@unionOfObjects.self"],
                          (@[@"a", @"b", @"a", @"b"]));
    XCTAssertEqualObjects([unmanaged.anyDataObj valueForKeyPath:@"@unionOfObjects.self"],
                          (@[data(1), data(2), data(1), data(2)]));
    XCTAssertEqualObjects([unmanaged.anyDateObj valueForKeyPath:@"@unionOfObjects.self"],
                          (@[date(1), date(2), date(1), date(2)]));
    XCTAssertEqualObjects([unmanaged.anyDecimalObj valueForKeyPath:@"@unionOfObjects.self"],
                          (@[decimal128(2), decimal128(3), decimal128(2), decimal128(3)]));
    XCTAssertEqualObjects([unmanaged.anyObjectIdObj valueForKeyPath:@"@unionOfObjects.self"],
                          (@[objectId(1), objectId(2), objectId(1), objectId(2)]));
    XCTAssertEqualObjects([unmanaged.anyUUIDObj valueForKeyPath:@"@unionOfObjects.self"],
                          (@[uuid(@"00000000-0000-0000-0000-000000000000"), uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"), uuid(@"00000000-0000-0000-0000-000000000000"), uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")]));
    XCTAssertEqualObjects([optUnmanaged.boolObj valueForKeyPath:@"@unionOfObjects.self"],
                          (@[@NO, @YES, NSNull.null, @NO, @YES, NSNull.null]));
    XCTAssertEqualObjects([optUnmanaged.intObj valueForKeyPath:@"@unionOfObjects.self"],
                          (@[@2, @3, NSNull.null, @2, @3, NSNull.null]));
    XCTAssertEqualObjects([optUnmanaged.floatObj valueForKeyPath:@"@unionOfObjects.self"],
                          (@[@2.2f, @3.3f, NSNull.null, @2.2f, @3.3f, NSNull.null]));
    XCTAssertEqualObjects([optUnmanaged.doubleObj valueForKeyPath:@"@unionOfObjects.self"],
                          (@[@2.2, @3.3, NSNull.null, @2.2, @3.3, NSNull.null]));
    XCTAssertEqualObjects([optUnmanaged.stringObj valueForKeyPath:@"@unionOfObjects.self"],
                          (@[@"a", @"b", NSNull.null, @"a", @"b", NSNull.null]));
    XCTAssertEqualObjects([optUnmanaged.dataObj valueForKeyPath:@"@unionOfObjects.self"],
                          (@[data(1), data(2), NSNull.null, data(1), data(2), NSNull.null]));
    XCTAssertEqualObjects([optUnmanaged.dateObj valueForKeyPath:@"@unionOfObjects.self"],
                          (@[date(1), date(2), NSNull.null, date(1), date(2), NSNull.null]));
    XCTAssertEqualObjects([optUnmanaged.decimalObj valueForKeyPath:@"@unionOfObjects.self"],
                          (@[decimal128(2), decimal128(3), NSNull.null, decimal128(2), decimal128(3), NSNull.null]));
    XCTAssertEqualObjects([optUnmanaged.objectIdObj valueForKeyPath:@"@unionOfObjects.self"],
                          (@[objectId(1), objectId(2), NSNull.null, objectId(1), objectId(2), NSNull.null]));
    XCTAssertEqualObjects([optUnmanaged.uuidObj valueForKeyPath:@"@unionOfObjects.self"],
                          (@[uuid(@"00000000-0000-0000-0000-000000000000"), uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"), NSNull.null, uuid(@"00000000-0000-0000-0000-000000000000"), uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"), NSNull.null]));
    XCTAssertEqualObjects([managed.boolObj valueForKeyPath:@"@unionOfObjects.self"],
                          (@[@NO, @YES, @NO, @YES]));
    XCTAssertEqualObjects([managed.intObj valueForKeyPath:@"@unionOfObjects.self"],
                          (@[@2, @3, @2, @3]));
    XCTAssertEqualObjects([managed.floatObj valueForKeyPath:@"@unionOfObjects.self"],
                          (@[@2.2f, @3.3f, @2.2f, @3.3f]));
    XCTAssertEqualObjects([managed.doubleObj valueForKeyPath:@"@unionOfObjects.self"],
                          (@[@2.2, @3.3, @2.2, @3.3]));
    XCTAssertEqualObjects([managed.stringObj valueForKeyPath:@"@unionOfObjects.self"],
                          (@[@"a", @"b", @"a", @"b"]));
    XCTAssertEqualObjects([managed.dataObj valueForKeyPath:@"@unionOfObjects.self"],
                          (@[data(1), data(2), data(1), data(2)]));
    XCTAssertEqualObjects([managed.dateObj valueForKeyPath:@"@unionOfObjects.self"],
                          (@[date(1), date(2), date(1), date(2)]));
    XCTAssertEqualObjects([managed.decimalObj valueForKeyPath:@"@unionOfObjects.self"],
                          (@[decimal128(2), decimal128(3), decimal128(2), decimal128(3)]));
    XCTAssertEqualObjects([managed.objectIdObj valueForKeyPath:@"@unionOfObjects.self"],
                          (@[objectId(1), objectId(2), objectId(1), objectId(2)]));
    XCTAssertEqualObjects([managed.uuidObj valueForKeyPath:@"@unionOfObjects.self"],
                          (@[uuid(@"00000000-0000-0000-0000-000000000000"), uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"), uuid(@"00000000-0000-0000-0000-000000000000"), uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")]));
    XCTAssertEqualObjects([managed.anyBoolObj valueForKeyPath:@"@unionOfObjects.self"],
                          (@[@NO, @YES, @NO, @YES]));
    XCTAssertEqualObjects([managed.anyIntObj valueForKeyPath:@"@unionOfObjects.self"],
                          (@[@2, @3, @2, @3]));
    XCTAssertEqualObjects([managed.anyFloatObj valueForKeyPath:@"@unionOfObjects.self"],
                          (@[@2.2f, @3.3f, @2.2f, @3.3f]));
    XCTAssertEqualObjects([managed.anyDoubleObj valueForKeyPath:@"@unionOfObjects.self"],
                          (@[@2.2, @3.3, @2.2, @3.3]));
    XCTAssertEqualObjects([managed.anyStringObj valueForKeyPath:@"@unionOfObjects.self"],
                          (@[@"a", @"b", @"a", @"b"]));
    XCTAssertEqualObjects([managed.anyDataObj valueForKeyPath:@"@unionOfObjects.self"],
                          (@[data(1), data(2), data(1), data(2)]));
    XCTAssertEqualObjects([managed.anyDateObj valueForKeyPath:@"@unionOfObjects.self"],
                          (@[date(1), date(2), date(1), date(2)]));
    XCTAssertEqualObjects([managed.anyDecimalObj valueForKeyPath:@"@unionOfObjects.self"],
                          (@[decimal128(2), decimal128(3), decimal128(2), decimal128(3)]));
    XCTAssertEqualObjects([managed.anyObjectIdObj valueForKeyPath:@"@unionOfObjects.self"],
                          (@[objectId(1), objectId(2), objectId(1), objectId(2)]));
    XCTAssertEqualObjects([managed.anyUUIDObj valueForKeyPath:@"@unionOfObjects.self"],
                          (@[uuid(@"00000000-0000-0000-0000-000000000000"), uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"), uuid(@"00000000-0000-0000-0000-000000000000"), uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")]));
    XCTAssertEqualObjects([optManaged.boolObj valueForKeyPath:@"@unionOfObjects.self"],
                          (@[@NO, @YES, NSNull.null, @NO, @YES, NSNull.null]));
    XCTAssertEqualObjects([optManaged.intObj valueForKeyPath:@"@unionOfObjects.self"],
                          (@[@2, @3, NSNull.null, @2, @3, NSNull.null]));
    XCTAssertEqualObjects([optManaged.floatObj valueForKeyPath:@"@unionOfObjects.self"],
                          (@[@2.2f, @3.3f, NSNull.null, @2.2f, @3.3f, NSNull.null]));
    XCTAssertEqualObjects([optManaged.doubleObj valueForKeyPath:@"@unionOfObjects.self"],
                          (@[@2.2, @3.3, NSNull.null, @2.2, @3.3, NSNull.null]));
    XCTAssertEqualObjects([optManaged.stringObj valueForKeyPath:@"@unionOfObjects.self"],
                          (@[@"a", @"b", NSNull.null, @"a", @"b", NSNull.null]));
    XCTAssertEqualObjects([optManaged.dataObj valueForKeyPath:@"@unionOfObjects.self"],
                          (@[data(1), data(2), NSNull.null, data(1), data(2), NSNull.null]));
    XCTAssertEqualObjects([optManaged.dateObj valueForKeyPath:@"@unionOfObjects.self"],
                          (@[date(1), date(2), NSNull.null, date(1), date(2), NSNull.null]));
    XCTAssertEqualObjects([optManaged.decimalObj valueForKeyPath:@"@unionOfObjects.self"],
                          (@[decimal128(2), decimal128(3), NSNull.null, decimal128(2), decimal128(3), NSNull.null]));
    XCTAssertEqualObjects([optManaged.objectIdObj valueForKeyPath:@"@unionOfObjects.self"],
                          (@[objectId(1), objectId(2), NSNull.null, objectId(1), objectId(2), NSNull.null]));
    XCTAssertEqualObjects([optManaged.uuidObj valueForKeyPath:@"@unionOfObjects.self"],
                          (@[uuid(@"00000000-0000-0000-0000-000000000000"), uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"), NSNull.null, uuid(@"00000000-0000-0000-0000-000000000000"), uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"), NSNull.null]));
    XCTAssertEqualObjects(sortedDistinctUnion(unmanaged.boolObj, @"Objects", @"self"),
                          (@[@NO, @YES]));
    XCTAssertEqualObjects(sortedDistinctUnion(unmanaged.intObj, @"Objects", @"self"),
                          (@[@2, @3]));
    XCTAssertEqualObjects(sortedDistinctUnion(unmanaged.floatObj, @"Objects", @"self"),
                          (@[@2.2f, @3.3f]));
    XCTAssertEqualObjects(sortedDistinctUnion(unmanaged.doubleObj, @"Objects", @"self"),
                          (@[@2.2, @3.3]));
    XCTAssertEqualObjects(sortedDistinctUnion(unmanaged.stringObj, @"Objects", @"self"),
                          (@[@"a", @"b"]));
    XCTAssertEqualObjects(sortedDistinctUnion(unmanaged.dataObj, @"Objects", @"self"),
                          (@[data(1), data(2)]));
    XCTAssertEqualObjects(sortedDistinctUnion(unmanaged.dateObj, @"Objects", @"self"),
                          (@[date(1), date(2)]));
    XCTAssertEqualObjects(sortedDistinctUnion(unmanaged.decimalObj, @"Objects", @"self"),
                          (@[decimal128(2), decimal128(3)]));
    XCTAssertEqualObjects(sortedDistinctUnion(unmanaged.objectIdObj, @"Objects", @"self"),
                          (@[objectId(1), objectId(2)]));
    XCTAssertEqualObjects(sortedDistinctUnion(unmanaged.uuidObj, @"Objects", @"self"),
                          (@[uuid(@"00000000-0000-0000-0000-000000000000"), uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")]));
    XCTAssertEqualObjects(sortedDistinctUnion(unmanaged.anyBoolObj, @"Objects", @"self"),
                          (@[@NO, @YES]));
    XCTAssertEqualObjects(sortedDistinctUnion(unmanaged.anyIntObj, @"Objects", @"self"),
                          (@[@2, @3]));
    XCTAssertEqualObjects(sortedDistinctUnion(unmanaged.anyFloatObj, @"Objects", @"self"),
                          (@[@2.2f, @3.3f]));
    XCTAssertEqualObjects(sortedDistinctUnion(unmanaged.anyDoubleObj, @"Objects", @"self"),
                          (@[@2.2, @3.3]));
    XCTAssertEqualObjects(sortedDistinctUnion(unmanaged.anyStringObj, @"Objects", @"self"),
                          (@[@"a", @"b"]));
    XCTAssertEqualObjects(sortedDistinctUnion(unmanaged.anyDataObj, @"Objects", @"self"),
                          (@[data(1), data(2)]));
    XCTAssertEqualObjects(sortedDistinctUnion(unmanaged.anyDateObj, @"Objects", @"self"),
                          (@[date(1), date(2)]));
    XCTAssertEqualObjects(sortedDistinctUnion(unmanaged.anyDecimalObj, @"Objects", @"self"),
                          (@[decimal128(2), decimal128(3)]));
    XCTAssertEqualObjects(sortedDistinctUnion(unmanaged.anyObjectIdObj, @"Objects", @"self"),
                          (@[objectId(1), objectId(2)]));
    XCTAssertEqualObjects(sortedDistinctUnion(unmanaged.anyUUIDObj, @"Objects", @"self"),
                          (@[uuid(@"00000000-0000-0000-0000-000000000000"), uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")]));
    XCTAssertEqualObjects(sortedDistinctUnion(optUnmanaged.boolObj, @"Objects", @"self"),
                          (@[@NO, @YES, NSNull.null]));
    XCTAssertEqualObjects(sortedDistinctUnion(optUnmanaged.intObj, @"Objects", @"self"),
                          (@[@2, @3, NSNull.null]));
    XCTAssertEqualObjects(sortedDistinctUnion(optUnmanaged.floatObj, @"Objects", @"self"),
                          (@[@2.2f, @3.3f, NSNull.null]));
    XCTAssertEqualObjects(sortedDistinctUnion(optUnmanaged.doubleObj, @"Objects", @"self"),
                          (@[@2.2, @3.3, NSNull.null]));
    XCTAssertEqualObjects(sortedDistinctUnion(optUnmanaged.stringObj, @"Objects", @"self"),
                          (@[@"a", @"b", NSNull.null]));
    XCTAssertEqualObjects(sortedDistinctUnion(optUnmanaged.dataObj, @"Objects", @"self"),
                          (@[data(1), data(2), NSNull.null]));
    XCTAssertEqualObjects(sortedDistinctUnion(optUnmanaged.dateObj, @"Objects", @"self"),
                          (@[date(1), date(2), NSNull.null]));
    XCTAssertEqualObjects(sortedDistinctUnion(optUnmanaged.decimalObj, @"Objects", @"self"),
                          (@[decimal128(2), decimal128(3), NSNull.null]));
    XCTAssertEqualObjects(sortedDistinctUnion(optUnmanaged.objectIdObj, @"Objects", @"self"),
                          (@[objectId(1), objectId(2), NSNull.null]));
    XCTAssertEqualObjects(sortedDistinctUnion(optUnmanaged.uuidObj, @"Objects", @"self"),
                          (@[uuid(@"00000000-0000-0000-0000-000000000000"), uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"), NSNull.null]));
    XCTAssertEqualObjects(sortedDistinctUnion(managed.boolObj, @"Objects", @"self"),
                          (@[@NO, @YES]));
    XCTAssertEqualObjects(sortedDistinctUnion(managed.intObj, @"Objects", @"self"),
                          (@[@2, @3]));
    XCTAssertEqualObjects(sortedDistinctUnion(managed.floatObj, @"Objects", @"self"),
                          (@[@2.2f, @3.3f]));
    XCTAssertEqualObjects(sortedDistinctUnion(managed.doubleObj, @"Objects", @"self"),
                          (@[@2.2, @3.3]));
    XCTAssertEqualObjects(sortedDistinctUnion(managed.stringObj, @"Objects", @"self"),
                          (@[@"a", @"b"]));
    XCTAssertEqualObjects(sortedDistinctUnion(managed.dataObj, @"Objects", @"self"),
                          (@[data(1), data(2)]));
    XCTAssertEqualObjects(sortedDistinctUnion(managed.dateObj, @"Objects", @"self"),
                          (@[date(1), date(2)]));
    XCTAssertEqualObjects(sortedDistinctUnion(managed.decimalObj, @"Objects", @"self"),
                          (@[decimal128(2), decimal128(3)]));
    XCTAssertEqualObjects(sortedDistinctUnion(managed.objectIdObj, @"Objects", @"self"),
                          (@[objectId(1), objectId(2)]));
    XCTAssertEqualObjects(sortedDistinctUnion(managed.uuidObj, @"Objects", @"self"),
                          (@[uuid(@"00000000-0000-0000-0000-000000000000"), uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")]));
    XCTAssertEqualObjects(sortedDistinctUnion(managed.anyBoolObj, @"Objects", @"self"),
                          (@[@NO, @YES]));
    XCTAssertEqualObjects(sortedDistinctUnion(managed.anyIntObj, @"Objects", @"self"),
                          (@[@2, @3]));
    XCTAssertEqualObjects(sortedDistinctUnion(managed.anyFloatObj, @"Objects", @"self"),
                          (@[@2.2f, @3.3f]));
    XCTAssertEqualObjects(sortedDistinctUnion(managed.anyDoubleObj, @"Objects", @"self"),
                          (@[@2.2, @3.3]));
    XCTAssertEqualObjects(sortedDistinctUnion(managed.anyStringObj, @"Objects", @"self"),
                          (@[@"a", @"b"]));
    XCTAssertEqualObjects(sortedDistinctUnion(managed.anyDataObj, @"Objects", @"self"),
                          (@[data(1), data(2)]));
    XCTAssertEqualObjects(sortedDistinctUnion(managed.anyDateObj, @"Objects", @"self"),
                          (@[date(1), date(2)]));
    XCTAssertEqualObjects(sortedDistinctUnion(managed.anyDecimalObj, @"Objects", @"self"),
                          (@[decimal128(2), decimal128(3)]));
    XCTAssertEqualObjects(sortedDistinctUnion(managed.anyObjectIdObj, @"Objects", @"self"),
                          (@[objectId(1), objectId(2)]));
    XCTAssertEqualObjects(sortedDistinctUnion(managed.anyUUIDObj, @"Objects", @"self"),
                          (@[uuid(@"00000000-0000-0000-0000-000000000000"), uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")]));
    XCTAssertEqualObjects(sortedDistinctUnion(optManaged.boolObj, @"Objects", @"self"),
                          (@[@NO, @YES, NSNull.null]));
    XCTAssertEqualObjects(sortedDistinctUnion(optManaged.intObj, @"Objects", @"self"),
                          (@[@2, @3, NSNull.null]));
    XCTAssertEqualObjects(sortedDistinctUnion(optManaged.floatObj, @"Objects", @"self"),
                          (@[@2.2f, @3.3f, NSNull.null]));
    XCTAssertEqualObjects(sortedDistinctUnion(optManaged.doubleObj, @"Objects", @"self"),
                          (@[@2.2, @3.3, NSNull.null]));
    XCTAssertEqualObjects(sortedDistinctUnion(optManaged.stringObj, @"Objects", @"self"),
                          (@[@"a", @"b", NSNull.null]));
    XCTAssertEqualObjects(sortedDistinctUnion(optManaged.dataObj, @"Objects", @"self"),
                          (@[data(1), data(2), NSNull.null]));
    XCTAssertEqualObjects(sortedDistinctUnion(optManaged.dateObj, @"Objects", @"self"),
                          (@[date(1), date(2), NSNull.null]));
    XCTAssertEqualObjects(sortedDistinctUnion(optManaged.decimalObj, @"Objects", @"self"),
                          (@[decimal128(2), decimal128(3), NSNull.null]));
    XCTAssertEqualObjects(sortedDistinctUnion(optManaged.objectIdObj, @"Objects", @"self"),
                          (@[objectId(1), objectId(2), NSNull.null]));
    XCTAssertEqualObjects(sortedDistinctUnion(optManaged.uuidObj, @"Objects", @"self"),
                          (@[uuid(@"00000000-0000-0000-0000-000000000000"), uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"), NSNull.null]));
}

- (void)testUnionOfArrays {
    RLMResults *allRequired = [AllPrimitiveArrays allObjectsInRealm:realm];
    RLMResults *allOptional = [AllOptionalPrimitiveArrays allObjectsInRealm:realm];

    XCTAssertEqualObjects([allRequired valueForKeyPath:@"@unionOfArrays.boolObj"], @[]);
    XCTAssertEqualObjects([allRequired valueForKeyPath:@"@unionOfArrays.intObj"], @[]);
    XCTAssertEqualObjects([allRequired valueForKeyPath:@"@unionOfArrays.floatObj"], @[]);
    XCTAssertEqualObjects([allRequired valueForKeyPath:@"@unionOfArrays.doubleObj"], @[]);
    XCTAssertEqualObjects([allRequired valueForKeyPath:@"@unionOfArrays.stringObj"], @[]);
    XCTAssertEqualObjects([allRequired valueForKeyPath:@"@unionOfArrays.dataObj"], @[]);
    XCTAssertEqualObjects([allRequired valueForKeyPath:@"@unionOfArrays.dateObj"], @[]);
    XCTAssertEqualObjects([allRequired valueForKeyPath:@"@unionOfArrays.decimalObj"], @[]);
    XCTAssertEqualObjects([allRequired valueForKeyPath:@"@unionOfArrays.objectIdObj"], @[]);
    XCTAssertEqualObjects([allRequired valueForKeyPath:@"@unionOfArrays.uuidObj"], @[]);
    XCTAssertEqualObjects([allOptional valueForKeyPath:@"@unionOfArrays.boolObj"], @[]);
    XCTAssertEqualObjects([allOptional valueForKeyPath:@"@unionOfArrays.intObj"], @[]);
    XCTAssertEqualObjects([allOptional valueForKeyPath:@"@unionOfArrays.floatObj"], @[]);
    XCTAssertEqualObjects([allOptional valueForKeyPath:@"@unionOfArrays.doubleObj"], @[]);
    XCTAssertEqualObjects([allOptional valueForKeyPath:@"@unionOfArrays.stringObj"], @[]);
    XCTAssertEqualObjects([allOptional valueForKeyPath:@"@unionOfArrays.dataObj"], @[]);
    XCTAssertEqualObjects([allOptional valueForKeyPath:@"@unionOfArrays.dateObj"], @[]);
    XCTAssertEqualObjects([allOptional valueForKeyPath:@"@unionOfArrays.decimalObj"], @[]);
    XCTAssertEqualObjects([allOptional valueForKeyPath:@"@unionOfArrays.objectIdObj"], @[]);
    XCTAssertEqualObjects([allOptional valueForKeyPath:@"@unionOfArrays.uuidObj"], @[]);
    XCTAssertEqualObjects([allRequired valueForKeyPath:@"@distinctUnionOfArrays.boolObj"], @[]);
    XCTAssertEqualObjects([allRequired valueForKeyPath:@"@distinctUnionOfArrays.intObj"], @[]);
    XCTAssertEqualObjects([allRequired valueForKeyPath:@"@distinctUnionOfArrays.floatObj"], @[]);
    XCTAssertEqualObjects([allRequired valueForKeyPath:@"@distinctUnionOfArrays.doubleObj"], @[]);
    XCTAssertEqualObjects([allRequired valueForKeyPath:@"@distinctUnionOfArrays.stringObj"], @[]);
    XCTAssertEqualObjects([allRequired valueForKeyPath:@"@distinctUnionOfArrays.dataObj"], @[]);
    XCTAssertEqualObjects([allRequired valueForKeyPath:@"@distinctUnionOfArrays.dateObj"], @[]);
    XCTAssertEqualObjects([allRequired valueForKeyPath:@"@distinctUnionOfArrays.decimalObj"], @[]);
    XCTAssertEqualObjects([allRequired valueForKeyPath:@"@distinctUnionOfArrays.objectIdObj"], @[]);
    XCTAssertEqualObjects([allRequired valueForKeyPath:@"@distinctUnionOfArrays.uuidObj"], @[]);
    XCTAssertEqualObjects([allOptional valueForKeyPath:@"@distinctUnionOfArrays.boolObj"], @[]);
    XCTAssertEqualObjects([allOptional valueForKeyPath:@"@distinctUnionOfArrays.intObj"], @[]);
    XCTAssertEqualObjects([allOptional valueForKeyPath:@"@distinctUnionOfArrays.floatObj"], @[]);
    XCTAssertEqualObjects([allOptional valueForKeyPath:@"@distinctUnionOfArrays.doubleObj"], @[]);
    XCTAssertEqualObjects([allOptional valueForKeyPath:@"@distinctUnionOfArrays.stringObj"], @[]);
    XCTAssertEqualObjects([allOptional valueForKeyPath:@"@distinctUnionOfArrays.dataObj"], @[]);
    XCTAssertEqualObjects([allOptional valueForKeyPath:@"@distinctUnionOfArrays.dateObj"], @[]);
    XCTAssertEqualObjects([allOptional valueForKeyPath:@"@distinctUnionOfArrays.decimalObj"], @[]);
    XCTAssertEqualObjects([allOptional valueForKeyPath:@"@distinctUnionOfArrays.objectIdObj"], @[]);
    XCTAssertEqualObjects([allOptional valueForKeyPath:@"@distinctUnionOfArrays.uuidObj"], @[]);

    XCTAssertEqualObjects([allRequired valueForKeyPath:@"@unionOfArrays.anyBoolObj"], @[]);
    XCTAssertEqualObjects([allRequired valueForKeyPath:@"@unionOfArrays.anyIntObj"], @[]);
    XCTAssertEqualObjects([allRequired valueForKeyPath:@"@unionOfArrays.anyFloatObj"], @[]);
    XCTAssertEqualObjects([allRequired valueForKeyPath:@"@unionOfArrays.anyDoubleObj"], @[]);
    XCTAssertEqualObjects([allRequired valueForKeyPath:@"@unionOfArrays.anyStringObj"], @[]);
    XCTAssertEqualObjects([allRequired valueForKeyPath:@"@unionOfArrays.anyDataObj"], @[]);
    XCTAssertEqualObjects([allRequired valueForKeyPath:@"@unionOfArrays.anyDateObj"], @[]);
    XCTAssertEqualObjects([allRequired valueForKeyPath:@"@unionOfArrays.anyDecimalObj"], @[]);
    XCTAssertEqualObjects([allRequired valueForKeyPath:@"@unionOfArrays.anyObjectIdObj"], @[]);
    XCTAssertEqualObjects([allRequired valueForKeyPath:@"@unionOfArrays.anyUUIDObj"], @[]);
    XCTAssertEqualObjects([allRequired valueForKeyPath:@"@distinctUnionOfArrays.anyBoolObj"], @[]);
    XCTAssertEqualObjects([allRequired valueForKeyPath:@"@distinctUnionOfArrays.anyIntObj"], @[]);
    XCTAssertEqualObjects([allRequired valueForKeyPath:@"@distinctUnionOfArrays.anyFloatObj"], @[]);
    XCTAssertEqualObjects([allRequired valueForKeyPath:@"@distinctUnionOfArrays.anyDoubleObj"], @[]);
    XCTAssertEqualObjects([allRequired valueForKeyPath:@"@distinctUnionOfArrays.anyStringObj"], @[]);
    XCTAssertEqualObjects([allRequired valueForKeyPath:@"@distinctUnionOfArrays.anyDataObj"], @[]);
    XCTAssertEqualObjects([allRequired valueForKeyPath:@"@distinctUnionOfArrays.anyDateObj"], @[]);
    XCTAssertEqualObjects([allRequired valueForKeyPath:@"@distinctUnionOfArrays.anyDecimalObj"], @[]);
    XCTAssertEqualObjects([allRequired valueForKeyPath:@"@distinctUnionOfArrays.anyObjectIdObj"], @[]);
    XCTAssertEqualObjects([allRequired valueForKeyPath:@"@distinctUnionOfArrays.anyUUIDObj"], @[]);


    [self addObjects];

    [AllPrimitiveArrays createInRealm:realm withValue:managed];
    [AllOptionalPrimitiveArrays createInRealm:realm withValue:optManaged];

    XCTAssertEqualObjects([allRequired valueForKeyPath:@"@unionOfArrays.boolObj"],
                          (@[@NO, @YES, @NO, @YES]));
    XCTAssertEqualObjects([allRequired valueForKeyPath:@"@unionOfArrays.intObj"],
                          (@[@2, @3, @2, @3]));
    XCTAssertEqualObjects([allRequired valueForKeyPath:@"@unionOfArrays.floatObj"],
                          (@[@2.2f, @3.3f, @2.2f, @3.3f]));
    XCTAssertEqualObjects([allRequired valueForKeyPath:@"@unionOfArrays.doubleObj"],
                          (@[@2.2, @3.3, @2.2, @3.3]));
    XCTAssertEqualObjects([allRequired valueForKeyPath:@"@unionOfArrays.stringObj"],
                          (@[@"a", @"b", @"a", @"b"]));
    XCTAssertEqualObjects([allRequired valueForKeyPath:@"@unionOfArrays.dataObj"],
                          (@[data(1), data(2), data(1), data(2)]));
    XCTAssertEqualObjects([allRequired valueForKeyPath:@"@unionOfArrays.dateObj"],
                          (@[date(1), date(2), date(1), date(2)]));
    XCTAssertEqualObjects([allRequired valueForKeyPath:@"@unionOfArrays.decimalObj"],
                          (@[decimal128(2), decimal128(3), decimal128(2), decimal128(3)]));
    XCTAssertEqualObjects([allRequired valueForKeyPath:@"@unionOfArrays.objectIdObj"],
                          (@[objectId(1), objectId(2), objectId(1), objectId(2)]));
    XCTAssertEqualObjects([allRequired valueForKeyPath:@"@unionOfArrays.uuidObj"],
                          (@[uuid(@"00000000-0000-0000-0000-000000000000"), uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"), uuid(@"00000000-0000-0000-0000-000000000000"), uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")]));
    XCTAssertEqualObjects([allOptional valueForKeyPath:@"@unionOfArrays.boolObj"],
                          (@[@NO, @YES, NSNull.null, @NO, @YES, NSNull.null]));
    XCTAssertEqualObjects([allOptional valueForKeyPath:@"@unionOfArrays.intObj"],
                          (@[@2, @3, NSNull.null, @2, @3, NSNull.null]));
    XCTAssertEqualObjects([allOptional valueForKeyPath:@"@unionOfArrays.floatObj"],
                          (@[@2.2f, @3.3f, NSNull.null, @2.2f, @3.3f, NSNull.null]));
    XCTAssertEqualObjects([allOptional valueForKeyPath:@"@unionOfArrays.doubleObj"],
                          (@[@2.2, @3.3, NSNull.null, @2.2, @3.3, NSNull.null]));
    XCTAssertEqualObjects([allOptional valueForKeyPath:@"@unionOfArrays.stringObj"],
                          (@[@"a", @"b", NSNull.null, @"a", @"b", NSNull.null]));
    XCTAssertEqualObjects([allOptional valueForKeyPath:@"@unionOfArrays.dataObj"],
                          (@[data(1), data(2), NSNull.null, data(1), data(2), NSNull.null]));
    XCTAssertEqualObjects([allOptional valueForKeyPath:@"@unionOfArrays.dateObj"],
                          (@[date(1), date(2), NSNull.null, date(1), date(2), NSNull.null]));
    XCTAssertEqualObjects([allOptional valueForKeyPath:@"@unionOfArrays.decimalObj"],
                          (@[decimal128(2), decimal128(3), NSNull.null, decimal128(2), decimal128(3), NSNull.null]));
    XCTAssertEqualObjects([allOptional valueForKeyPath:@"@unionOfArrays.objectIdObj"],
                          (@[objectId(1), objectId(2), NSNull.null, objectId(1), objectId(2), NSNull.null]));
    XCTAssertEqualObjects([allOptional valueForKeyPath:@"@unionOfArrays.uuidObj"],
                          (@[uuid(@"00000000-0000-0000-0000-000000000000"), uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"), NSNull.null, uuid(@"00000000-0000-0000-0000-000000000000"), uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"), NSNull.null]));
    XCTAssertEqualObjects(sortedDistinctUnion(allRequired, @"Arrays", @"boolObj"),
                          (@[@NO, @YES]));
    XCTAssertEqualObjects(sortedDistinctUnion(allRequired, @"Arrays", @"intObj"),
                          (@[@2, @3]));
    XCTAssertEqualObjects(sortedDistinctUnion(allRequired, @"Arrays", @"floatObj"),
                          (@[@2.2f, @3.3f]));
    XCTAssertEqualObjects(sortedDistinctUnion(allRequired, @"Arrays", @"doubleObj"),
                          (@[@2.2, @3.3]));
    XCTAssertEqualObjects(sortedDistinctUnion(allRequired, @"Arrays", @"stringObj"),
                          (@[@"a", @"b"]));
    XCTAssertEqualObjects(sortedDistinctUnion(allRequired, @"Arrays", @"dataObj"),
                          (@[data(1), data(2)]));
    XCTAssertEqualObjects(sortedDistinctUnion(allRequired, @"Arrays", @"dateObj"),
                          (@[date(1), date(2)]));
    XCTAssertEqualObjects(sortedDistinctUnion(allRequired, @"Arrays", @"decimalObj"),
                          (@[decimal128(2), decimal128(3)]));
    XCTAssertEqualObjects(sortedDistinctUnion(allRequired, @"Arrays", @"objectIdObj"),
                          (@[objectId(1), objectId(2)]));
    XCTAssertEqualObjects(sortedDistinctUnion(allRequired, @"Arrays", @"uuidObj"),
                          (@[uuid(@"00000000-0000-0000-0000-000000000000"), uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")]));
    XCTAssertEqualObjects(sortedDistinctUnion(allOptional, @"Arrays", @"boolObj"),
                          (@[@NO, @YES, NSNull.null]));
    XCTAssertEqualObjects(sortedDistinctUnion(allOptional, @"Arrays", @"intObj"),
                          (@[@2, @3, NSNull.null]));
    XCTAssertEqualObjects(sortedDistinctUnion(allOptional, @"Arrays", @"floatObj"),
                          (@[@2.2f, @3.3f, NSNull.null]));
    XCTAssertEqualObjects(sortedDistinctUnion(allOptional, @"Arrays", @"doubleObj"),
                          (@[@2.2, @3.3, NSNull.null]));
    XCTAssertEqualObjects(sortedDistinctUnion(allOptional, @"Arrays", @"stringObj"),
                          (@[@"a", @"b", NSNull.null]));
    XCTAssertEqualObjects(sortedDistinctUnion(allOptional, @"Arrays", @"dataObj"),
                          (@[data(1), data(2), NSNull.null]));
    XCTAssertEqualObjects(sortedDistinctUnion(allOptional, @"Arrays", @"dateObj"),
                          (@[date(1), date(2), NSNull.null]));
    XCTAssertEqualObjects(sortedDistinctUnion(allOptional, @"Arrays", @"decimalObj"),
                          (@[decimal128(2), decimal128(3), NSNull.null]));
    XCTAssertEqualObjects(sortedDistinctUnion(allOptional, @"Arrays", @"objectIdObj"),
                          (@[objectId(1), objectId(2), NSNull.null]));
    XCTAssertEqualObjects(sortedDistinctUnion(allOptional, @"Arrays", @"uuidObj"),
                          (@[uuid(@"00000000-0000-0000-0000-000000000000"), uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"), NSNull.null]));

    XCTAssertEqualObjects([allRequired valueForKeyPath:@"@unionOfArrays.anyBoolObj"],
                          (@[@NO, @YES, @NO, @YES]));
    XCTAssertEqualObjects([allRequired valueForKeyPath:@"@unionOfArrays.anyIntObj"],
                          (@[@2, @3, @2, @3]));
    XCTAssertEqualObjects([allRequired valueForKeyPath:@"@unionOfArrays.anyFloatObj"],
                          (@[@2.2f, @3.3f, @2.2f, @3.3f]));
    XCTAssertEqualObjects([allRequired valueForKeyPath:@"@unionOfArrays.anyDoubleObj"],
                          (@[@2.2, @3.3, @2.2, @3.3]));
    XCTAssertEqualObjects([allRequired valueForKeyPath:@"@unionOfArrays.anyStringObj"],
                          (@[@"a", @"b", @"a", @"b"]));
    XCTAssertEqualObjects([allRequired valueForKeyPath:@"@unionOfArrays.anyDataObj"],
                          (@[data(1), data(2), data(1), data(2)]));
    XCTAssertEqualObjects([allRequired valueForKeyPath:@"@unionOfArrays.anyDateObj"],
                          (@[date(1), date(2), date(1), date(2)]));
    XCTAssertEqualObjects([allRequired valueForKeyPath:@"@unionOfArrays.anyDecimalObj"],
                          (@[decimal128(2), decimal128(3), decimal128(2), decimal128(3)]));
    XCTAssertEqualObjects([allRequired valueForKeyPath:@"@unionOfArrays.anyObjectIdObj"],
                          (@[objectId(1), objectId(2), objectId(1), objectId(2)]));
    XCTAssertEqualObjects([allRequired valueForKeyPath:@"@unionOfArrays.anyUUIDObj"],
                          (@[uuid(@"00000000-0000-0000-0000-000000000000"), uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"), uuid(@"00000000-0000-0000-0000-000000000000"), uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")]));
    XCTAssertEqualObjects(sortedDistinctUnion(allRequired, @"Arrays", @"anyBoolObj"),
                          (@[@NO, @YES]));
    XCTAssertEqualObjects(sortedDistinctUnion(allRequired, @"Arrays", @"anyIntObj"),
                          (@[@2, @3]));
    XCTAssertEqualObjects(sortedDistinctUnion(allRequired, @"Arrays", @"anyFloatObj"),
                          (@[@2.2f, @3.3f]));
    XCTAssertEqualObjects(sortedDistinctUnion(allRequired, @"Arrays", @"anyDoubleObj"),
                          (@[@2.2, @3.3]));
    XCTAssertEqualObjects(sortedDistinctUnion(allRequired, @"Arrays", @"anyStringObj"),
                          (@[@"a", @"b"]));
    XCTAssertEqualObjects(sortedDistinctUnion(allRequired, @"Arrays", @"anyDataObj"),
                          (@[data(1), data(2)]));
    XCTAssertEqualObjects(sortedDistinctUnion(allRequired, @"Arrays", @"anyDateObj"),
                          (@[date(1), date(2)]));
    XCTAssertEqualObjects(sortedDistinctUnion(allRequired, @"Arrays", @"anyDecimalObj"),
                          (@[decimal128(2), decimal128(3)]));
    XCTAssertEqualObjects(sortedDistinctUnion(allRequired, @"Arrays", @"anyObjectIdObj"),
                          (@[objectId(1), objectId(2)]));
    XCTAssertEqualObjects(sortedDistinctUnion(allRequired, @"Arrays", @"anyUUIDObj"),
                          (@[uuid(@"00000000-0000-0000-0000-000000000000"), uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")]));
}

- (void)testSetValueForKey {
    for (RLMArray *array in allArrays) {
        RLMAssertThrowsWithReason([array setValue:@0 forKey:@"not self"],
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

    [unmanaged.boolObj setValue:@NO forKey:@"self"];
    [unmanaged.intObj setValue:@2 forKey:@"self"];
    [unmanaged.floatObj setValue:@2.2f forKey:@"self"];
    [unmanaged.doubleObj setValue:@2.2 forKey:@"self"];
    [unmanaged.stringObj setValue:@"a" forKey:@"self"];
    [unmanaged.dataObj setValue:data(1) forKey:@"self"];
    [unmanaged.dateObj setValue:date(1) forKey:@"self"];
    [unmanaged.decimalObj setValue:decimal128(2) forKey:@"self"];
    [unmanaged.objectIdObj setValue:objectId(1) forKey:@"self"];
    [unmanaged.uuidObj setValue:uuid(@"00000000-0000-0000-0000-000000000000") forKey:@"self"];
    [unmanaged.anyBoolObj setValue:@NO forKey:@"self"];
    [unmanaged.anyIntObj setValue:@2 forKey:@"self"];
    [unmanaged.anyFloatObj setValue:@2.2f forKey:@"self"];
    [unmanaged.anyDoubleObj setValue:@2.2 forKey:@"self"];
    [unmanaged.anyStringObj setValue:@"a" forKey:@"self"];
    [unmanaged.anyDataObj setValue:data(1) forKey:@"self"];
    [unmanaged.anyDateObj setValue:date(1) forKey:@"self"];
    [unmanaged.anyDecimalObj setValue:decimal128(2) forKey:@"self"];
    [unmanaged.anyObjectIdObj setValue:objectId(1) forKey:@"self"];
    [unmanaged.anyUUIDObj setValue:uuid(@"00000000-0000-0000-0000-000000000000") forKey:@"self"];
    [optUnmanaged.boolObj setValue:@NO forKey:@"self"];
    [optUnmanaged.intObj setValue:@2 forKey:@"self"];
    [optUnmanaged.floatObj setValue:@2.2f forKey:@"self"];
    [optUnmanaged.doubleObj setValue:@2.2 forKey:@"self"];
    [optUnmanaged.stringObj setValue:@"a" forKey:@"self"];
    [optUnmanaged.dataObj setValue:data(1) forKey:@"self"];
    [optUnmanaged.dateObj setValue:date(1) forKey:@"self"];
    [optUnmanaged.decimalObj setValue:decimal128(2) forKey:@"self"];
    [optUnmanaged.objectIdObj setValue:objectId(1) forKey:@"self"];
    [optUnmanaged.uuidObj setValue:uuid(@"00000000-0000-0000-0000-000000000000") forKey:@"self"];
    [managed.boolObj setValue:@NO forKey:@"self"];
    [managed.intObj setValue:@2 forKey:@"self"];
    [managed.floatObj setValue:@2.2f forKey:@"self"];
    [managed.doubleObj setValue:@2.2 forKey:@"self"];
    [managed.stringObj setValue:@"a" forKey:@"self"];
    [managed.dataObj setValue:data(1) forKey:@"self"];
    [managed.dateObj setValue:date(1) forKey:@"self"];
    [managed.decimalObj setValue:decimal128(2) forKey:@"self"];
    [managed.objectIdObj setValue:objectId(1) forKey:@"self"];
    [managed.uuidObj setValue:uuid(@"00000000-0000-0000-0000-000000000000") forKey:@"self"];
    [managed.anyBoolObj setValue:@NO forKey:@"self"];
    [managed.anyIntObj setValue:@2 forKey:@"self"];
    [managed.anyFloatObj setValue:@2.2f forKey:@"self"];
    [managed.anyDoubleObj setValue:@2.2 forKey:@"self"];
    [managed.anyStringObj setValue:@"a" forKey:@"self"];
    [managed.anyDataObj setValue:data(1) forKey:@"self"];
    [managed.anyDateObj setValue:date(1) forKey:@"self"];
    [managed.anyDecimalObj setValue:decimal128(2) forKey:@"self"];
    [managed.anyObjectIdObj setValue:objectId(1) forKey:@"self"];
    [managed.anyUUIDObj setValue:uuid(@"00000000-0000-0000-0000-000000000000") forKey:@"self"];
    [optManaged.boolObj setValue:@NO forKey:@"self"];
    [optManaged.intObj setValue:@2 forKey:@"self"];
    [optManaged.floatObj setValue:@2.2f forKey:@"self"];
    [optManaged.doubleObj setValue:@2.2 forKey:@"self"];
    [optManaged.stringObj setValue:@"a" forKey:@"self"];
    [optManaged.dataObj setValue:data(1) forKey:@"self"];
    [optManaged.dateObj setValue:date(1) forKey:@"self"];
    [optManaged.decimalObj setValue:decimal128(2) forKey:@"self"];
    [optManaged.objectIdObj setValue:objectId(1) forKey:@"self"];
    [optManaged.uuidObj setValue:uuid(@"00000000-0000-0000-0000-000000000000") forKey:@"self"];

    XCTAssertEqualObjects(unmanaged.boolObj[0], @NO);
    XCTAssertEqualObjects(unmanaged.intObj[0], @2);
    XCTAssertEqualObjects(unmanaged.floatObj[0], @2.2f);
    XCTAssertEqualObjects(unmanaged.doubleObj[0], @2.2);
    XCTAssertEqualObjects(unmanaged.stringObj[0], @"a");
    XCTAssertEqualObjects(unmanaged.dataObj[0], data(1));
    XCTAssertEqualObjects(unmanaged.dateObj[0], date(1));
    XCTAssertEqualObjects(unmanaged.decimalObj[0], decimal128(2));
    XCTAssertEqualObjects(unmanaged.objectIdObj[0], objectId(1));
    XCTAssertEqualObjects(unmanaged.uuidObj[0], uuid(@"00000000-0000-0000-0000-000000000000"));
    XCTAssertEqualObjects(unmanaged.anyBoolObj[0], @NO);
    XCTAssertEqualObjects(unmanaged.anyIntObj[0], @2);
    XCTAssertEqualObjects(unmanaged.anyFloatObj[0], @2.2f);
    XCTAssertEqualObjects(unmanaged.anyDoubleObj[0], @2.2);
    XCTAssertEqualObjects(unmanaged.anyStringObj[0], @"a");
    XCTAssertEqualObjects(unmanaged.anyDataObj[0], data(1));
    XCTAssertEqualObjects(unmanaged.anyDateObj[0], date(1));
    XCTAssertEqualObjects(unmanaged.anyDecimalObj[0], decimal128(2));
    XCTAssertEqualObjects(unmanaged.anyObjectIdObj[0], objectId(1));
    XCTAssertEqualObjects(unmanaged.anyUUIDObj[0], uuid(@"00000000-0000-0000-0000-000000000000"));
    XCTAssertEqualObjects(optUnmanaged.boolObj[0], @NO);
    XCTAssertEqualObjects(optUnmanaged.intObj[0], @2);
    XCTAssertEqualObjects(optUnmanaged.floatObj[0], @2.2f);
    XCTAssertEqualObjects(optUnmanaged.doubleObj[0], @2.2);
    XCTAssertEqualObjects(optUnmanaged.stringObj[0], @"a");
    XCTAssertEqualObjects(optUnmanaged.dataObj[0], data(1));
    XCTAssertEqualObjects(optUnmanaged.dateObj[0], date(1));
    XCTAssertEqualObjects(optUnmanaged.decimalObj[0], decimal128(2));
    XCTAssertEqualObjects(optUnmanaged.objectIdObj[0], objectId(1));
    XCTAssertEqualObjects(optUnmanaged.uuidObj[0], uuid(@"00000000-0000-0000-0000-000000000000"));
    XCTAssertEqualObjects(managed.boolObj[0], @NO);
    XCTAssertEqualObjects(managed.intObj[0], @2);
    XCTAssertEqualObjects(managed.floatObj[0], @2.2f);
    XCTAssertEqualObjects(managed.doubleObj[0], @2.2);
    XCTAssertEqualObjects(managed.stringObj[0], @"a");
    XCTAssertEqualObjects(managed.dataObj[0], data(1));
    XCTAssertEqualObjects(managed.dateObj[0], date(1));
    XCTAssertEqualObjects(managed.decimalObj[0], decimal128(2));
    XCTAssertEqualObjects(managed.objectIdObj[0], objectId(1));
    XCTAssertEqualObjects(managed.uuidObj[0], uuid(@"00000000-0000-0000-0000-000000000000"));
    XCTAssertEqualObjects(managed.anyBoolObj[0], @NO);
    XCTAssertEqualObjects(managed.anyIntObj[0], @2);
    XCTAssertEqualObjects(managed.anyFloatObj[0], @2.2f);
    XCTAssertEqualObjects(managed.anyDoubleObj[0], @2.2);
    XCTAssertEqualObjects(managed.anyStringObj[0], @"a");
    XCTAssertEqualObjects(managed.anyDataObj[0], data(1));
    XCTAssertEqualObjects(managed.anyDateObj[0], date(1));
    XCTAssertEqualObjects(managed.anyDecimalObj[0], decimal128(2));
    XCTAssertEqualObjects(managed.anyObjectIdObj[0], objectId(1));
    XCTAssertEqualObjects(managed.anyUUIDObj[0], uuid(@"00000000-0000-0000-0000-000000000000"));
    XCTAssertEqualObjects(optManaged.boolObj[0], @NO);
    XCTAssertEqualObjects(optManaged.intObj[0], @2);
    XCTAssertEqualObjects(optManaged.floatObj[0], @2.2f);
    XCTAssertEqualObjects(optManaged.doubleObj[0], @2.2);
    XCTAssertEqualObjects(optManaged.stringObj[0], @"a");
    XCTAssertEqualObjects(optManaged.dataObj[0], data(1));
    XCTAssertEqualObjects(optManaged.dateObj[0], date(1));
    XCTAssertEqualObjects(optManaged.decimalObj[0], decimal128(2));
    XCTAssertEqualObjects(optManaged.objectIdObj[0], objectId(1));
    XCTAssertEqualObjects(optManaged.uuidObj[0], uuid(@"00000000-0000-0000-0000-000000000000"));
    XCTAssertEqualObjects(unmanaged.boolObj[1], @NO);
    XCTAssertEqualObjects(unmanaged.intObj[1], @2);
    XCTAssertEqualObjects(unmanaged.floatObj[1], @2.2f);
    XCTAssertEqualObjects(unmanaged.doubleObj[1], @2.2);
    XCTAssertEqualObjects(unmanaged.stringObj[1], @"a");
    XCTAssertEqualObjects(unmanaged.dataObj[1], data(1));
    XCTAssertEqualObjects(unmanaged.dateObj[1], date(1));
    XCTAssertEqualObjects(unmanaged.decimalObj[1], decimal128(2));
    XCTAssertEqualObjects(unmanaged.objectIdObj[1], objectId(1));
    XCTAssertEqualObjects(unmanaged.uuidObj[1], uuid(@"00000000-0000-0000-0000-000000000000"));
    XCTAssertEqualObjects(unmanaged.anyBoolObj[1], @NO);
    XCTAssertEqualObjects(unmanaged.anyIntObj[1], @2);
    XCTAssertEqualObjects(unmanaged.anyFloatObj[1], @2.2f);
    XCTAssertEqualObjects(unmanaged.anyDoubleObj[1], @2.2);
    XCTAssertEqualObjects(unmanaged.anyStringObj[1], @"a");
    XCTAssertEqualObjects(unmanaged.anyDataObj[1], data(1));
    XCTAssertEqualObjects(unmanaged.anyDateObj[1], date(1));
    XCTAssertEqualObjects(unmanaged.anyDecimalObj[1], decimal128(2));
    XCTAssertEqualObjects(unmanaged.anyObjectIdObj[1], objectId(1));
    XCTAssertEqualObjects(unmanaged.anyUUIDObj[1], uuid(@"00000000-0000-0000-0000-000000000000"));
    XCTAssertEqualObjects(optUnmanaged.boolObj[1], @NO);
    XCTAssertEqualObjects(optUnmanaged.intObj[1], @2);
    XCTAssertEqualObjects(optUnmanaged.floatObj[1], @2.2f);
    XCTAssertEqualObjects(optUnmanaged.doubleObj[1], @2.2);
    XCTAssertEqualObjects(optUnmanaged.stringObj[1], @"a");
    XCTAssertEqualObjects(optUnmanaged.dataObj[1], data(1));
    XCTAssertEqualObjects(optUnmanaged.dateObj[1], date(1));
    XCTAssertEqualObjects(optUnmanaged.decimalObj[1], decimal128(2));
    XCTAssertEqualObjects(optUnmanaged.objectIdObj[1], objectId(1));
    XCTAssertEqualObjects(optUnmanaged.uuidObj[1], uuid(@"00000000-0000-0000-0000-000000000000"));
    XCTAssertEqualObjects(managed.boolObj[1], @NO);
    XCTAssertEqualObjects(managed.intObj[1], @2);
    XCTAssertEqualObjects(managed.floatObj[1], @2.2f);
    XCTAssertEqualObjects(managed.doubleObj[1], @2.2);
    XCTAssertEqualObjects(managed.stringObj[1], @"a");
    XCTAssertEqualObjects(managed.dataObj[1], data(1));
    XCTAssertEqualObjects(managed.dateObj[1], date(1));
    XCTAssertEqualObjects(managed.decimalObj[1], decimal128(2));
    XCTAssertEqualObjects(managed.objectIdObj[1], objectId(1));
    XCTAssertEqualObjects(managed.uuidObj[1], uuid(@"00000000-0000-0000-0000-000000000000"));
    XCTAssertEqualObjects(managed.anyBoolObj[1], @NO);
    XCTAssertEqualObjects(managed.anyIntObj[1], @2);
    XCTAssertEqualObjects(managed.anyFloatObj[1], @2.2f);
    XCTAssertEqualObjects(managed.anyDoubleObj[1], @2.2);
    XCTAssertEqualObjects(managed.anyStringObj[1], @"a");
    XCTAssertEqualObjects(managed.anyDataObj[1], data(1));
    XCTAssertEqualObjects(managed.anyDateObj[1], date(1));
    XCTAssertEqualObjects(managed.anyDecimalObj[1], decimal128(2));
    XCTAssertEqualObjects(managed.anyObjectIdObj[1], objectId(1));
    XCTAssertEqualObjects(managed.anyUUIDObj[1], uuid(@"00000000-0000-0000-0000-000000000000"));
    XCTAssertEqualObjects(optManaged.boolObj[1], @NO);
    XCTAssertEqualObjects(optManaged.intObj[1], @2);
    XCTAssertEqualObjects(optManaged.floatObj[1], @2.2f);
    XCTAssertEqualObjects(optManaged.doubleObj[1], @2.2);
    XCTAssertEqualObjects(optManaged.stringObj[1], @"a");
    XCTAssertEqualObjects(optManaged.dataObj[1], data(1));
    XCTAssertEqualObjects(optManaged.dateObj[1], date(1));
    XCTAssertEqualObjects(optManaged.decimalObj[1], decimal128(2));
    XCTAssertEqualObjects(optManaged.objectIdObj[1], objectId(1));
    XCTAssertEqualObjects(optManaged.uuidObj[1], uuid(@"00000000-0000-0000-0000-000000000000"));
    XCTAssertEqualObjects(optUnmanaged.boolObj[2], @NO);
    XCTAssertEqualObjects(optUnmanaged.intObj[2], @2);
    XCTAssertEqualObjects(optUnmanaged.floatObj[2], @2.2f);
    XCTAssertEqualObjects(optUnmanaged.doubleObj[2], @2.2);
    XCTAssertEqualObjects(optUnmanaged.stringObj[2], @"a");
    XCTAssertEqualObjects(optUnmanaged.dataObj[2], data(1));
    XCTAssertEqualObjects(optUnmanaged.dateObj[2], date(1));
    XCTAssertEqualObjects(optUnmanaged.decimalObj[2], decimal128(2));
    XCTAssertEqualObjects(optUnmanaged.objectIdObj[2], objectId(1));
    XCTAssertEqualObjects(optUnmanaged.uuidObj[2], uuid(@"00000000-0000-0000-0000-000000000000"));
    XCTAssertEqualObjects(optManaged.boolObj[2], @NO);
    XCTAssertEqualObjects(optManaged.intObj[2], @2);
    XCTAssertEqualObjects(optManaged.floatObj[2], @2.2f);
    XCTAssertEqualObjects(optManaged.doubleObj[2], @2.2);
    XCTAssertEqualObjects(optManaged.stringObj[2], @"a");
    XCTAssertEqualObjects(optManaged.dataObj[2], data(1));
    XCTAssertEqualObjects(optManaged.dateObj[2], date(1));
    XCTAssertEqualObjects(optManaged.decimalObj[2], decimal128(2));
    XCTAssertEqualObjects(optManaged.objectIdObj[2], objectId(1));
    XCTAssertEqualObjects(optManaged.uuidObj[2], uuid(@"00000000-0000-0000-0000-000000000000"));

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
    XCTAssertEqualObjects(optUnmanaged.boolObj[0], NSNull.null);
    XCTAssertEqualObjects(optUnmanaged.intObj[0], NSNull.null);
    XCTAssertEqualObjects(optUnmanaged.floatObj[0], NSNull.null);
    XCTAssertEqualObjects(optUnmanaged.doubleObj[0], NSNull.null);
    XCTAssertEqualObjects(optUnmanaged.stringObj[0], NSNull.null);
    XCTAssertEqualObjects(optUnmanaged.dataObj[0], NSNull.null);
    XCTAssertEqualObjects(optUnmanaged.dateObj[0], NSNull.null);
    XCTAssertEqualObjects(optUnmanaged.decimalObj[0], NSNull.null);
    XCTAssertEqualObjects(optUnmanaged.objectIdObj[0], NSNull.null);
    XCTAssertEqualObjects(optUnmanaged.uuidObj[0], NSNull.null);
    XCTAssertEqualObjects(optManaged.boolObj[0], NSNull.null);
    XCTAssertEqualObjects(optManaged.intObj[0], NSNull.null);
    XCTAssertEqualObjects(optManaged.floatObj[0], NSNull.null);
    XCTAssertEqualObjects(optManaged.doubleObj[0], NSNull.null);
    XCTAssertEqualObjects(optManaged.stringObj[0], NSNull.null);
    XCTAssertEqualObjects(optManaged.dataObj[0], NSNull.null);
    XCTAssertEqualObjects(optManaged.dateObj[0], NSNull.null);
    XCTAssertEqualObjects(optManaged.decimalObj[0], NSNull.null);
    XCTAssertEqualObjects(optManaged.objectIdObj[0], NSNull.null);
    XCTAssertEqualObjects(optManaged.uuidObj[0], NSNull.null);
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
    unmanaged.decimalObj = (id)@[decimal128(3)];
    XCTAssertEqualObjects(unmanaged.decimalObj[0], decimal128(3));
    unmanaged.objectIdObj = (id)@[objectId(2)];
    XCTAssertEqualObjects(unmanaged.objectIdObj[0], objectId(2));
    unmanaged.uuidObj = (id)@[uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")];
    XCTAssertEqualObjects(unmanaged.uuidObj[0], uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"));
    unmanaged.anyBoolObj = (id)@[@YES];
    XCTAssertEqualObjects(unmanaged.anyBoolObj[0], @YES);
    unmanaged.anyIntObj = (id)@[@3];
    XCTAssertEqualObjects(unmanaged.anyIntObj[0], @3);
    unmanaged.anyFloatObj = (id)@[@3.3f];
    XCTAssertEqualObjects(unmanaged.anyFloatObj[0], @3.3f);
    unmanaged.anyDoubleObj = (id)@[@3.3];
    XCTAssertEqualObjects(unmanaged.anyDoubleObj[0], @3.3);
    unmanaged.anyStringObj = (id)@[@"b"];
    XCTAssertEqualObjects(unmanaged.anyStringObj[0], @"b");
    unmanaged.anyDataObj = (id)@[data(2)];
    XCTAssertEqualObjects(unmanaged.anyDataObj[0], data(2));
    unmanaged.anyDateObj = (id)@[date(2)];
    XCTAssertEqualObjects(unmanaged.anyDateObj[0], date(2));
    unmanaged.anyDecimalObj = (id)@[decimal128(3)];
    XCTAssertEqualObjects(unmanaged.anyDecimalObj[0], decimal128(3));
    unmanaged.anyObjectIdObj = (id)@[objectId(2)];
    XCTAssertEqualObjects(unmanaged.anyObjectIdObj[0], objectId(2));
    unmanaged.anyUUIDObj = (id)@[uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")];
    XCTAssertEqualObjects(unmanaged.anyUUIDObj[0], uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"));
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
    optUnmanaged.decimalObj = (id)@[decimal128(3)];
    XCTAssertEqualObjects(optUnmanaged.decimalObj[0], decimal128(3));
    optUnmanaged.objectIdObj = (id)@[objectId(2)];
    XCTAssertEqualObjects(optUnmanaged.objectIdObj[0], objectId(2));
    optUnmanaged.uuidObj = (id)@[uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")];
    XCTAssertEqualObjects(optUnmanaged.uuidObj[0], uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"));
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
    managed.decimalObj = (id)@[decimal128(3)];
    XCTAssertEqualObjects(managed.decimalObj[0], decimal128(3));
    managed.objectIdObj = (id)@[objectId(2)];
    XCTAssertEqualObjects(managed.objectIdObj[0], objectId(2));
    managed.uuidObj = (id)@[uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")];
    XCTAssertEqualObjects(managed.uuidObj[0], uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"));
    managed.anyBoolObj = (id)@[@YES];
    XCTAssertEqualObjects(managed.anyBoolObj[0], @YES);
    managed.anyIntObj = (id)@[@3];
    XCTAssertEqualObjects(managed.anyIntObj[0], @3);
    managed.anyFloatObj = (id)@[@3.3f];
    XCTAssertEqualObjects(managed.anyFloatObj[0], @3.3f);
    managed.anyDoubleObj = (id)@[@3.3];
    XCTAssertEqualObjects(managed.anyDoubleObj[0], @3.3);
    managed.anyStringObj = (id)@[@"b"];
    XCTAssertEqualObjects(managed.anyStringObj[0], @"b");
    managed.anyDataObj = (id)@[data(2)];
    XCTAssertEqualObjects(managed.anyDataObj[0], data(2));
    managed.anyDateObj = (id)@[date(2)];
    XCTAssertEqualObjects(managed.anyDateObj[0], date(2));
    managed.anyDecimalObj = (id)@[decimal128(3)];
    XCTAssertEqualObjects(managed.anyDecimalObj[0], decimal128(3));
    managed.anyObjectIdObj = (id)@[objectId(2)];
    XCTAssertEqualObjects(managed.anyObjectIdObj[0], objectId(2));
    managed.anyUUIDObj = (id)@[uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")];
    XCTAssertEqualObjects(managed.anyUUIDObj[0], uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"));
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
    optManaged.decimalObj = (id)@[decimal128(3)];
    XCTAssertEqualObjects(optManaged.decimalObj[0], decimal128(3));
    optManaged.objectIdObj = (id)@[objectId(2)];
    XCTAssertEqualObjects(optManaged.objectIdObj[0], objectId(2));
    optManaged.uuidObj = (id)@[uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")];
    XCTAssertEqualObjects(optManaged.uuidObj[0], uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"));

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
    
    unmanaged.decimalObj = (id)@[decimal128(2), decimal128(3)];
    XCTAssertEqualObjects([unmanaged.decimalObj valueForKey:@"self"], (@[decimal128(2), decimal128(3)]));
    
    unmanaged.objectIdObj = (id)@[objectId(1), objectId(2)];
    XCTAssertEqualObjects([unmanaged.objectIdObj valueForKey:@"self"], (@[objectId(1), objectId(2)]));
    
    unmanaged.uuidObj = (id)@[uuid(@"00000000-0000-0000-0000-000000000000"), uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")];
    XCTAssertEqualObjects([unmanaged.uuidObj valueForKey:@"self"], (@[uuid(@"00000000-0000-0000-0000-000000000000"), uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")]));
    
    unmanaged.anyBoolObj = (id)@[@NO, @YES];
    XCTAssertEqualObjects([unmanaged.anyBoolObj valueForKey:@"self"], (@[@NO, @YES]));
    
    unmanaged.anyIntObj = (id)@[@2, @3];
    XCTAssertEqualObjects([unmanaged.anyIntObj valueForKey:@"self"], (@[@2, @3]));
    
    unmanaged.anyFloatObj = (id)@[@2.2f, @3.3f];
    XCTAssertEqualObjects([unmanaged.anyFloatObj valueForKey:@"self"], (@[@2.2f, @3.3f]));
    
    unmanaged.anyDoubleObj = (id)@[@2.2, @3.3];
    XCTAssertEqualObjects([unmanaged.anyDoubleObj valueForKey:@"self"], (@[@2.2, @3.3]));
    
    unmanaged.anyStringObj = (id)@[@"a", @"b"];
    XCTAssertEqualObjects([unmanaged.anyStringObj valueForKey:@"self"], (@[@"a", @"b"]));
    
    unmanaged.anyDataObj = (id)@[data(1), data(2)];
    XCTAssertEqualObjects([unmanaged.anyDataObj valueForKey:@"self"], (@[data(1), data(2)]));
    
    unmanaged.anyDateObj = (id)@[date(1), date(2)];
    XCTAssertEqualObjects([unmanaged.anyDateObj valueForKey:@"self"], (@[date(1), date(2)]));
    
    unmanaged.anyDecimalObj = (id)@[decimal128(2), decimal128(3)];
    XCTAssertEqualObjects([unmanaged.anyDecimalObj valueForKey:@"self"], (@[decimal128(2), decimal128(3)]));
    
    unmanaged.anyObjectIdObj = (id)@[objectId(1), objectId(2)];
    XCTAssertEqualObjects([unmanaged.anyObjectIdObj valueForKey:@"self"], (@[objectId(1), objectId(2)]));
    
    unmanaged.anyUUIDObj = (id)@[uuid(@"00000000-0000-0000-0000-000000000000"), uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")];
    XCTAssertEqualObjects([unmanaged.anyUUIDObj valueForKey:@"self"], (@[uuid(@"00000000-0000-0000-0000-000000000000"), uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")]));
    
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
    
    optUnmanaged.decimalObj = (id)@[decimal128(2), decimal128(3), NSNull.null];
    XCTAssertEqualObjects([optUnmanaged.decimalObj valueForKey:@"self"], (@[decimal128(2), decimal128(3), NSNull.null]));
    
    optUnmanaged.objectIdObj = (id)@[objectId(1), objectId(2), NSNull.null];
    XCTAssertEqualObjects([optUnmanaged.objectIdObj valueForKey:@"self"], (@[objectId(1), objectId(2), NSNull.null]));
    
    optUnmanaged.uuidObj = (id)@[uuid(@"00000000-0000-0000-0000-000000000000"), uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"), NSNull.null];
    XCTAssertEqualObjects([optUnmanaged.uuidObj valueForKey:@"self"], (@[uuid(@"00000000-0000-0000-0000-000000000000"), uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"), NSNull.null]));
    
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
    
    managed.decimalObj = (id)@[decimal128(2), decimal128(3)];
    XCTAssertEqualObjects([managed.decimalObj valueForKey:@"self"], (@[decimal128(2), decimal128(3)]));
    
    managed.objectIdObj = (id)@[objectId(1), objectId(2)];
    XCTAssertEqualObjects([managed.objectIdObj valueForKey:@"self"], (@[objectId(1), objectId(2)]));
    
    managed.uuidObj = (id)@[uuid(@"00000000-0000-0000-0000-000000000000"), uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")];
    XCTAssertEqualObjects([managed.uuidObj valueForKey:@"self"], (@[uuid(@"00000000-0000-0000-0000-000000000000"), uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")]));
    
    managed.anyBoolObj = (id)@[@NO, @YES];
    XCTAssertEqualObjects([managed.anyBoolObj valueForKey:@"self"], (@[@NO, @YES]));
    
    managed.anyIntObj = (id)@[@2, @3];
    XCTAssertEqualObjects([managed.anyIntObj valueForKey:@"self"], (@[@2, @3]));
    
    managed.anyFloatObj = (id)@[@2.2f, @3.3f];
    XCTAssertEqualObjects([managed.anyFloatObj valueForKey:@"self"], (@[@2.2f, @3.3f]));
    
    managed.anyDoubleObj = (id)@[@2.2, @3.3];
    XCTAssertEqualObjects([managed.anyDoubleObj valueForKey:@"self"], (@[@2.2, @3.3]));
    
    managed.anyStringObj = (id)@[@"a", @"b"];
    XCTAssertEqualObjects([managed.anyStringObj valueForKey:@"self"], (@[@"a", @"b"]));
    
    managed.anyDataObj = (id)@[data(1), data(2)];
    XCTAssertEqualObjects([managed.anyDataObj valueForKey:@"self"], (@[data(1), data(2)]));
    
    managed.anyDateObj = (id)@[date(1), date(2)];
    XCTAssertEqualObjects([managed.anyDateObj valueForKey:@"self"], (@[date(1), date(2)]));
    
    managed.anyDecimalObj = (id)@[decimal128(2), decimal128(3)];
    XCTAssertEqualObjects([managed.anyDecimalObj valueForKey:@"self"], (@[decimal128(2), decimal128(3)]));
    
    managed.anyObjectIdObj = (id)@[objectId(1), objectId(2)];
    XCTAssertEqualObjects([managed.anyObjectIdObj valueForKey:@"self"], (@[objectId(1), objectId(2)]));
    
    managed.anyUUIDObj = (id)@[uuid(@"00000000-0000-0000-0000-000000000000"), uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")];
    XCTAssertEqualObjects([managed.anyUUIDObj valueForKey:@"self"], (@[uuid(@"00000000-0000-0000-0000-000000000000"), uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")]));
    
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
    
    optManaged.decimalObj = (id)@[decimal128(2), decimal128(3), NSNull.null];
    XCTAssertEqualObjects([optManaged.decimalObj valueForKey:@"self"], (@[decimal128(2), decimal128(3), NSNull.null]));
    
    optManaged.objectIdObj = (id)@[objectId(1), objectId(2), NSNull.null];
    XCTAssertEqualObjects([optManaged.objectIdObj valueForKey:@"self"], (@[objectId(1), objectId(2), NSNull.null]));
    
    optManaged.uuidObj = (id)@[uuid(@"00000000-0000-0000-0000-000000000000"), uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"), NSNull.null];
    XCTAssertEqualObjects([optManaged.uuidObj valueForKey:@"self"], (@[uuid(@"00000000-0000-0000-0000-000000000000"), uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"), NSNull.null]));
    

    // Should not clear the array
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
    XCTAssertEqualObjects([unmanaged.decimalObj valueForKey:@"self"], (@[decimal128(2), decimal128(3)]));
    
    unmanaged.objectIdObj = unmanaged.objectIdObj;
    XCTAssertEqualObjects([unmanaged.objectIdObj valueForKey:@"self"], (@[objectId(1), objectId(2)]));
    
    unmanaged.uuidObj = unmanaged.uuidObj;
    XCTAssertEqualObjects([unmanaged.uuidObj valueForKey:@"self"], (@[uuid(@"00000000-0000-0000-0000-000000000000"), uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")]));
    
    unmanaged.anyBoolObj = unmanaged.anyBoolObj;
    XCTAssertEqualObjects([unmanaged.anyBoolObj valueForKey:@"self"], (@[@NO, @YES]));
    
    unmanaged.anyIntObj = unmanaged.anyIntObj;
    XCTAssertEqualObjects([unmanaged.anyIntObj valueForKey:@"self"], (@[@2, @3]));
    
    unmanaged.anyFloatObj = unmanaged.anyFloatObj;
    XCTAssertEqualObjects([unmanaged.anyFloatObj valueForKey:@"self"], (@[@2.2f, @3.3f]));
    
    unmanaged.anyDoubleObj = unmanaged.anyDoubleObj;
    XCTAssertEqualObjects([unmanaged.anyDoubleObj valueForKey:@"self"], (@[@2.2, @3.3]));
    
    unmanaged.anyStringObj = unmanaged.anyStringObj;
    XCTAssertEqualObjects([unmanaged.anyStringObj valueForKey:@"self"], (@[@"a", @"b"]));
    
    unmanaged.anyDataObj = unmanaged.anyDataObj;
    XCTAssertEqualObjects([unmanaged.anyDataObj valueForKey:@"self"], (@[data(1), data(2)]));
    
    unmanaged.anyDateObj = unmanaged.anyDateObj;
    XCTAssertEqualObjects([unmanaged.anyDateObj valueForKey:@"self"], (@[date(1), date(2)]));
    
    unmanaged.anyDecimalObj = unmanaged.anyDecimalObj;
    XCTAssertEqualObjects([unmanaged.anyDecimalObj valueForKey:@"self"], (@[decimal128(2), decimal128(3)]));
    
    unmanaged.anyObjectIdObj = unmanaged.anyObjectIdObj;
    XCTAssertEqualObjects([unmanaged.anyObjectIdObj valueForKey:@"self"], (@[objectId(1), objectId(2)]));
    
    unmanaged.anyUUIDObj = unmanaged.anyUUIDObj;
    XCTAssertEqualObjects([unmanaged.anyUUIDObj valueForKey:@"self"], (@[uuid(@"00000000-0000-0000-0000-000000000000"), uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")]));
    
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
    XCTAssertEqualObjects([optUnmanaged.decimalObj valueForKey:@"self"], (@[decimal128(2), decimal128(3), NSNull.null]));
    
    optUnmanaged.objectIdObj = optUnmanaged.objectIdObj;
    XCTAssertEqualObjects([optUnmanaged.objectIdObj valueForKey:@"self"], (@[objectId(1), objectId(2), NSNull.null]));
    
    optUnmanaged.uuidObj = optUnmanaged.uuidObj;
    XCTAssertEqualObjects([optUnmanaged.uuidObj valueForKey:@"self"], (@[uuid(@"00000000-0000-0000-0000-000000000000"), uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"), NSNull.null]));
    
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
    XCTAssertEqualObjects([managed.decimalObj valueForKey:@"self"], (@[decimal128(2), decimal128(3)]));
    
    managed.objectIdObj = managed.objectIdObj;
    XCTAssertEqualObjects([managed.objectIdObj valueForKey:@"self"], (@[objectId(1), objectId(2)]));
    
    managed.uuidObj = managed.uuidObj;
    XCTAssertEqualObjects([managed.uuidObj valueForKey:@"self"], (@[uuid(@"00000000-0000-0000-0000-000000000000"), uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")]));
    
    managed.anyBoolObj = managed.anyBoolObj;
    XCTAssertEqualObjects([managed.anyBoolObj valueForKey:@"self"], (@[@NO, @YES]));
    
    managed.anyIntObj = managed.anyIntObj;
    XCTAssertEqualObjects([managed.anyIntObj valueForKey:@"self"], (@[@2, @3]));
    
    managed.anyFloatObj = managed.anyFloatObj;
    XCTAssertEqualObjects([managed.anyFloatObj valueForKey:@"self"], (@[@2.2f, @3.3f]));
    
    managed.anyDoubleObj = managed.anyDoubleObj;
    XCTAssertEqualObjects([managed.anyDoubleObj valueForKey:@"self"], (@[@2.2, @3.3]));
    
    managed.anyStringObj = managed.anyStringObj;
    XCTAssertEqualObjects([managed.anyStringObj valueForKey:@"self"], (@[@"a", @"b"]));
    
    managed.anyDataObj = managed.anyDataObj;
    XCTAssertEqualObjects([managed.anyDataObj valueForKey:@"self"], (@[data(1), data(2)]));
    
    managed.anyDateObj = managed.anyDateObj;
    XCTAssertEqualObjects([managed.anyDateObj valueForKey:@"self"], (@[date(1), date(2)]));
    
    managed.anyDecimalObj = managed.anyDecimalObj;
    XCTAssertEqualObjects([managed.anyDecimalObj valueForKey:@"self"], (@[decimal128(2), decimal128(3)]));
    
    managed.anyObjectIdObj = managed.anyObjectIdObj;
    XCTAssertEqualObjects([managed.anyObjectIdObj valueForKey:@"self"], (@[objectId(1), objectId(2)]));
    
    managed.anyUUIDObj = managed.anyUUIDObj;
    XCTAssertEqualObjects([managed.anyUUIDObj valueForKey:@"self"], (@[uuid(@"00000000-0000-0000-0000-000000000000"), uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")]));
    
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
    XCTAssertEqualObjects([optManaged.decimalObj valueForKey:@"self"], (@[decimal128(2), decimal128(3), NSNull.null]));
    
    optManaged.objectIdObj = optManaged.objectIdObj;
    XCTAssertEqualObjects([optManaged.objectIdObj valueForKey:@"self"], (@[objectId(1), objectId(2), NSNull.null]));
    
    optManaged.uuidObj = optManaged.uuidObj;
    XCTAssertEqualObjects([optManaged.uuidObj valueForKey:@"self"], (@[uuid(@"00000000-0000-0000-0000-000000000000"), uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"), NSNull.null]));
    

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
    unmanaged[@"decimalObj"] = (id)@[decimal128(3)];
    XCTAssertEqualObjects(unmanaged[@"decimalObj"][0], decimal128(3));
    unmanaged[@"objectIdObj"] = (id)@[objectId(2)];
    XCTAssertEqualObjects(unmanaged[@"objectIdObj"][0], objectId(2));
    unmanaged[@"uuidObj"] = (id)@[uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")];
    XCTAssertEqualObjects(unmanaged[@"uuidObj"][0], uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"));
    unmanaged[@"anyBoolObj"] = (id)@[@YES];
    XCTAssertEqualObjects(unmanaged[@"anyBoolObj"][0], @YES);
    unmanaged[@"anyIntObj"] = (id)@[@3];
    XCTAssertEqualObjects(unmanaged[@"anyIntObj"][0], @3);
    unmanaged[@"anyFloatObj"] = (id)@[@3.3f];
    XCTAssertEqualObjects(unmanaged[@"anyFloatObj"][0], @3.3f);
    unmanaged[@"anyDoubleObj"] = (id)@[@3.3];
    XCTAssertEqualObjects(unmanaged[@"anyDoubleObj"][0], @3.3);
    unmanaged[@"anyStringObj"] = (id)@[@"b"];
    XCTAssertEqualObjects(unmanaged[@"anyStringObj"][0], @"b");
    unmanaged[@"anyDataObj"] = (id)@[data(2)];
    XCTAssertEqualObjects(unmanaged[@"anyDataObj"][0], data(2));
    unmanaged[@"anyDateObj"] = (id)@[date(2)];
    XCTAssertEqualObjects(unmanaged[@"anyDateObj"][0], date(2));
    unmanaged[@"anyDecimalObj"] = (id)@[decimal128(3)];
    XCTAssertEqualObjects(unmanaged[@"anyDecimalObj"][0], decimal128(3));
    unmanaged[@"anyObjectIdObj"] = (id)@[objectId(2)];
    XCTAssertEqualObjects(unmanaged[@"anyObjectIdObj"][0], objectId(2));
    unmanaged[@"anyUUIDObj"] = (id)@[uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")];
    XCTAssertEqualObjects(unmanaged[@"anyUUIDObj"][0], uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"));
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
    optUnmanaged[@"decimalObj"] = (id)@[decimal128(3)];
    XCTAssertEqualObjects(optUnmanaged[@"decimalObj"][0], decimal128(3));
    optUnmanaged[@"objectIdObj"] = (id)@[objectId(2)];
    XCTAssertEqualObjects(optUnmanaged[@"objectIdObj"][0], objectId(2));
    optUnmanaged[@"uuidObj"] = (id)@[uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")];
    XCTAssertEqualObjects(optUnmanaged[@"uuidObj"][0], uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"));
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
    managed[@"decimalObj"] = (id)@[decimal128(3)];
    XCTAssertEqualObjects(managed[@"decimalObj"][0], decimal128(3));
    managed[@"objectIdObj"] = (id)@[objectId(2)];
    XCTAssertEqualObjects(managed[@"objectIdObj"][0], objectId(2));
    managed[@"uuidObj"] = (id)@[uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")];
    XCTAssertEqualObjects(managed[@"uuidObj"][0], uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"));
    managed[@"anyBoolObj"] = (id)@[@YES];
    XCTAssertEqualObjects(managed[@"anyBoolObj"][0], @YES);
    managed[@"anyIntObj"] = (id)@[@3];
    XCTAssertEqualObjects(managed[@"anyIntObj"][0], @3);
    managed[@"anyFloatObj"] = (id)@[@3.3f];
    XCTAssertEqualObjects(managed[@"anyFloatObj"][0], @3.3f);
    managed[@"anyDoubleObj"] = (id)@[@3.3];
    XCTAssertEqualObjects(managed[@"anyDoubleObj"][0], @3.3);
    managed[@"anyStringObj"] = (id)@[@"b"];
    XCTAssertEqualObjects(managed[@"anyStringObj"][0], @"b");
    managed[@"anyDataObj"] = (id)@[data(2)];
    XCTAssertEqualObjects(managed[@"anyDataObj"][0], data(2));
    managed[@"anyDateObj"] = (id)@[date(2)];
    XCTAssertEqualObjects(managed[@"anyDateObj"][0], date(2));
    managed[@"anyDecimalObj"] = (id)@[decimal128(3)];
    XCTAssertEqualObjects(managed[@"anyDecimalObj"][0], decimal128(3));
    managed[@"anyObjectIdObj"] = (id)@[objectId(2)];
    XCTAssertEqualObjects(managed[@"anyObjectIdObj"][0], objectId(2));
    managed[@"anyUUIDObj"] = (id)@[uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")];
    XCTAssertEqualObjects(managed[@"anyUUIDObj"][0], uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"));
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
    optManaged[@"decimalObj"] = (id)@[decimal128(3)];
    XCTAssertEqualObjects(optManaged[@"decimalObj"][0], decimal128(3));
    optManaged[@"objectIdObj"] = (id)@[objectId(2)];
    XCTAssertEqualObjects(optManaged[@"objectIdObj"][0], objectId(2));
    optManaged[@"uuidObj"] = (id)@[uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")];
    XCTAssertEqualObjects(optManaged[@"uuidObj"][0], uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"));

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
    
    unmanaged[@"decimalObj"] = (id)@[decimal128(2), decimal128(3)];
    XCTAssertEqualObjects([unmanaged[@"decimalObj"] valueForKey:@"self"], (@[decimal128(2), decimal128(3)]));
    
    unmanaged[@"objectIdObj"] = (id)@[objectId(1), objectId(2)];
    XCTAssertEqualObjects([unmanaged[@"objectIdObj"] valueForKey:@"self"], (@[objectId(1), objectId(2)]));
    
    unmanaged[@"uuidObj"] = (id)@[uuid(@"00000000-0000-0000-0000-000000000000"), uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")];
    XCTAssertEqualObjects([unmanaged[@"uuidObj"] valueForKey:@"self"], (@[uuid(@"00000000-0000-0000-0000-000000000000"), uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")]));
    
    unmanaged[@"anyBoolObj"] = (id)@[@NO, @YES];
    XCTAssertEqualObjects([unmanaged[@"anyBoolObj"] valueForKey:@"self"], (@[@NO, @YES]));
    
    unmanaged[@"anyIntObj"] = (id)@[@2, @3];
    XCTAssertEqualObjects([unmanaged[@"anyIntObj"] valueForKey:@"self"], (@[@2, @3]));
    
    unmanaged[@"anyFloatObj"] = (id)@[@2.2f, @3.3f];
    XCTAssertEqualObjects([unmanaged[@"anyFloatObj"] valueForKey:@"self"], (@[@2.2f, @3.3f]));
    
    unmanaged[@"anyDoubleObj"] = (id)@[@2.2, @3.3];
    XCTAssertEqualObjects([unmanaged[@"anyDoubleObj"] valueForKey:@"self"], (@[@2.2, @3.3]));
    
    unmanaged[@"anyStringObj"] = (id)@[@"a", @"b"];
    XCTAssertEqualObjects([unmanaged[@"anyStringObj"] valueForKey:@"self"], (@[@"a", @"b"]));
    
    unmanaged[@"anyDataObj"] = (id)@[data(1), data(2)];
    XCTAssertEqualObjects([unmanaged[@"anyDataObj"] valueForKey:@"self"], (@[data(1), data(2)]));
    
    unmanaged[@"anyDateObj"] = (id)@[date(1), date(2)];
    XCTAssertEqualObjects([unmanaged[@"anyDateObj"] valueForKey:@"self"], (@[date(1), date(2)]));
    
    unmanaged[@"anyDecimalObj"] = (id)@[decimal128(2), decimal128(3)];
    XCTAssertEqualObjects([unmanaged[@"anyDecimalObj"] valueForKey:@"self"], (@[decimal128(2), decimal128(3)]));
    
    unmanaged[@"anyObjectIdObj"] = (id)@[objectId(1), objectId(2)];
    XCTAssertEqualObjects([unmanaged[@"anyObjectIdObj"] valueForKey:@"self"], (@[objectId(1), objectId(2)]));
    
    unmanaged[@"anyUUIDObj"] = (id)@[uuid(@"00000000-0000-0000-0000-000000000000"), uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")];
    XCTAssertEqualObjects([unmanaged[@"anyUUIDObj"] valueForKey:@"self"], (@[uuid(@"00000000-0000-0000-0000-000000000000"), uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")]));
    
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
    
    optUnmanaged[@"decimalObj"] = (id)@[decimal128(2), decimal128(3), NSNull.null];
    XCTAssertEqualObjects([optUnmanaged[@"decimalObj"] valueForKey:@"self"], (@[decimal128(2), decimal128(3), NSNull.null]));
    
    optUnmanaged[@"objectIdObj"] = (id)@[objectId(1), objectId(2), NSNull.null];
    XCTAssertEqualObjects([optUnmanaged[@"objectIdObj"] valueForKey:@"self"], (@[objectId(1), objectId(2), NSNull.null]));
    
    optUnmanaged[@"uuidObj"] = (id)@[uuid(@"00000000-0000-0000-0000-000000000000"), uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"), NSNull.null];
    XCTAssertEqualObjects([optUnmanaged[@"uuidObj"] valueForKey:@"self"], (@[uuid(@"00000000-0000-0000-0000-000000000000"), uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"), NSNull.null]));
    
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
    
    managed[@"decimalObj"] = (id)@[decimal128(2), decimal128(3)];
    XCTAssertEqualObjects([managed[@"decimalObj"] valueForKey:@"self"], (@[decimal128(2), decimal128(3)]));
    
    managed[@"objectIdObj"] = (id)@[objectId(1), objectId(2)];
    XCTAssertEqualObjects([managed[@"objectIdObj"] valueForKey:@"self"], (@[objectId(1), objectId(2)]));
    
    managed[@"uuidObj"] = (id)@[uuid(@"00000000-0000-0000-0000-000000000000"), uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")];
    XCTAssertEqualObjects([managed[@"uuidObj"] valueForKey:@"self"], (@[uuid(@"00000000-0000-0000-0000-000000000000"), uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")]));
    
    managed[@"anyBoolObj"] = (id)@[@NO, @YES];
    XCTAssertEqualObjects([managed[@"anyBoolObj"] valueForKey:@"self"], (@[@NO, @YES]));
    
    managed[@"anyIntObj"] = (id)@[@2, @3];
    XCTAssertEqualObjects([managed[@"anyIntObj"] valueForKey:@"self"], (@[@2, @3]));
    
    managed[@"anyFloatObj"] = (id)@[@2.2f, @3.3f];
    XCTAssertEqualObjects([managed[@"anyFloatObj"] valueForKey:@"self"], (@[@2.2f, @3.3f]));
    
    managed[@"anyDoubleObj"] = (id)@[@2.2, @3.3];
    XCTAssertEqualObjects([managed[@"anyDoubleObj"] valueForKey:@"self"], (@[@2.2, @3.3]));
    
    managed[@"anyStringObj"] = (id)@[@"a", @"b"];
    XCTAssertEqualObjects([managed[@"anyStringObj"] valueForKey:@"self"], (@[@"a", @"b"]));
    
    managed[@"anyDataObj"] = (id)@[data(1), data(2)];
    XCTAssertEqualObjects([managed[@"anyDataObj"] valueForKey:@"self"], (@[data(1), data(2)]));
    
    managed[@"anyDateObj"] = (id)@[date(1), date(2)];
    XCTAssertEqualObjects([managed[@"anyDateObj"] valueForKey:@"self"], (@[date(1), date(2)]));
    
    managed[@"anyDecimalObj"] = (id)@[decimal128(2), decimal128(3)];
    XCTAssertEqualObjects([managed[@"anyDecimalObj"] valueForKey:@"self"], (@[decimal128(2), decimal128(3)]));
    
    managed[@"anyObjectIdObj"] = (id)@[objectId(1), objectId(2)];
    XCTAssertEqualObjects([managed[@"anyObjectIdObj"] valueForKey:@"self"], (@[objectId(1), objectId(2)]));
    
    managed[@"anyUUIDObj"] = (id)@[uuid(@"00000000-0000-0000-0000-000000000000"), uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")];
    XCTAssertEqualObjects([managed[@"anyUUIDObj"] valueForKey:@"self"], (@[uuid(@"00000000-0000-0000-0000-000000000000"), uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")]));
    
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
    
    optManaged[@"decimalObj"] = (id)@[decimal128(2), decimal128(3), NSNull.null];
    XCTAssertEqualObjects([optManaged[@"decimalObj"] valueForKey:@"self"], (@[decimal128(2), decimal128(3), NSNull.null]));
    
    optManaged[@"objectIdObj"] = (id)@[objectId(1), objectId(2), NSNull.null];
    XCTAssertEqualObjects([optManaged[@"objectIdObj"] valueForKey:@"self"], (@[objectId(1), objectId(2), NSNull.null]));
    
    optManaged[@"uuidObj"] = (id)@[uuid(@"00000000-0000-0000-0000-000000000000"), uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"), NSNull.null];
    XCTAssertEqualObjects([optManaged[@"uuidObj"] valueForKey:@"self"], (@[uuid(@"00000000-0000-0000-0000-000000000000"), uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"), NSNull.null]));
    

    // Should not clear the array
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
    XCTAssertEqualObjects([unmanaged[@"decimalObj"] valueForKey:@"self"], (@[decimal128(2), decimal128(3)]));
    
    unmanaged[@"objectIdObj"] = unmanaged[@"objectIdObj"];
    XCTAssertEqualObjects([unmanaged[@"objectIdObj"] valueForKey:@"self"], (@[objectId(1), objectId(2)]));
    
    unmanaged[@"uuidObj"] = unmanaged[@"uuidObj"];
    XCTAssertEqualObjects([unmanaged[@"uuidObj"] valueForKey:@"self"], (@[uuid(@"00000000-0000-0000-0000-000000000000"), uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")]));
    
    unmanaged[@"anyBoolObj"] = unmanaged[@"anyBoolObj"];
    XCTAssertEqualObjects([unmanaged[@"anyBoolObj"] valueForKey:@"self"], (@[@NO, @YES]));
    
    unmanaged[@"anyIntObj"] = unmanaged[@"anyIntObj"];
    XCTAssertEqualObjects([unmanaged[@"anyIntObj"] valueForKey:@"self"], (@[@2, @3]));
    
    unmanaged[@"anyFloatObj"] = unmanaged[@"anyFloatObj"];
    XCTAssertEqualObjects([unmanaged[@"anyFloatObj"] valueForKey:@"self"], (@[@2.2f, @3.3f]));
    
    unmanaged[@"anyDoubleObj"] = unmanaged[@"anyDoubleObj"];
    XCTAssertEqualObjects([unmanaged[@"anyDoubleObj"] valueForKey:@"self"], (@[@2.2, @3.3]));
    
    unmanaged[@"anyStringObj"] = unmanaged[@"anyStringObj"];
    XCTAssertEqualObjects([unmanaged[@"anyStringObj"] valueForKey:@"self"], (@[@"a", @"b"]));
    
    unmanaged[@"anyDataObj"] = unmanaged[@"anyDataObj"];
    XCTAssertEqualObjects([unmanaged[@"anyDataObj"] valueForKey:@"self"], (@[data(1), data(2)]));
    
    unmanaged[@"anyDateObj"] = unmanaged[@"anyDateObj"];
    XCTAssertEqualObjects([unmanaged[@"anyDateObj"] valueForKey:@"self"], (@[date(1), date(2)]));
    
    unmanaged[@"anyDecimalObj"] = unmanaged[@"anyDecimalObj"];
    XCTAssertEqualObjects([unmanaged[@"anyDecimalObj"] valueForKey:@"self"], (@[decimal128(2), decimal128(3)]));
    
    unmanaged[@"anyObjectIdObj"] = unmanaged[@"anyObjectIdObj"];
    XCTAssertEqualObjects([unmanaged[@"anyObjectIdObj"] valueForKey:@"self"], (@[objectId(1), objectId(2)]));
    
    unmanaged[@"anyUUIDObj"] = unmanaged[@"anyUUIDObj"];
    XCTAssertEqualObjects([unmanaged[@"anyUUIDObj"] valueForKey:@"self"], (@[uuid(@"00000000-0000-0000-0000-000000000000"), uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")]));
    
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
    XCTAssertEqualObjects([optUnmanaged[@"decimalObj"] valueForKey:@"self"], (@[decimal128(2), decimal128(3), NSNull.null]));
    
    optUnmanaged[@"objectIdObj"] = optUnmanaged[@"objectIdObj"];
    XCTAssertEqualObjects([optUnmanaged[@"objectIdObj"] valueForKey:@"self"], (@[objectId(1), objectId(2), NSNull.null]));
    
    optUnmanaged[@"uuidObj"] = optUnmanaged[@"uuidObj"];
    XCTAssertEqualObjects([optUnmanaged[@"uuidObj"] valueForKey:@"self"], (@[uuid(@"00000000-0000-0000-0000-000000000000"), uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"), NSNull.null]));
    
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
    XCTAssertEqualObjects([managed[@"decimalObj"] valueForKey:@"self"], (@[decimal128(2), decimal128(3)]));
    
    managed[@"objectIdObj"] = managed[@"objectIdObj"];
    XCTAssertEqualObjects([managed[@"objectIdObj"] valueForKey:@"self"], (@[objectId(1), objectId(2)]));
    
    managed[@"uuidObj"] = managed[@"uuidObj"];
    XCTAssertEqualObjects([managed[@"uuidObj"] valueForKey:@"self"], (@[uuid(@"00000000-0000-0000-0000-000000000000"), uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")]));
    
    managed[@"anyBoolObj"] = managed[@"anyBoolObj"];
    XCTAssertEqualObjects([managed[@"anyBoolObj"] valueForKey:@"self"], (@[@NO, @YES]));
    
    managed[@"anyIntObj"] = managed[@"anyIntObj"];
    XCTAssertEqualObjects([managed[@"anyIntObj"] valueForKey:@"self"], (@[@2, @3]));
    
    managed[@"anyFloatObj"] = managed[@"anyFloatObj"];
    XCTAssertEqualObjects([managed[@"anyFloatObj"] valueForKey:@"self"], (@[@2.2f, @3.3f]));
    
    managed[@"anyDoubleObj"] = managed[@"anyDoubleObj"];
    XCTAssertEqualObjects([managed[@"anyDoubleObj"] valueForKey:@"self"], (@[@2.2, @3.3]));
    
    managed[@"anyStringObj"] = managed[@"anyStringObj"];
    XCTAssertEqualObjects([managed[@"anyStringObj"] valueForKey:@"self"], (@[@"a", @"b"]));
    
    managed[@"anyDataObj"] = managed[@"anyDataObj"];
    XCTAssertEqualObjects([managed[@"anyDataObj"] valueForKey:@"self"], (@[data(1), data(2)]));
    
    managed[@"anyDateObj"] = managed[@"anyDateObj"];
    XCTAssertEqualObjects([managed[@"anyDateObj"] valueForKey:@"self"], (@[date(1), date(2)]));
    
    managed[@"anyDecimalObj"] = managed[@"anyDecimalObj"];
    XCTAssertEqualObjects([managed[@"anyDecimalObj"] valueForKey:@"self"], (@[decimal128(2), decimal128(3)]));
    
    managed[@"anyObjectIdObj"] = managed[@"anyObjectIdObj"];
    XCTAssertEqualObjects([managed[@"anyObjectIdObj"] valueForKey:@"self"], (@[objectId(1), objectId(2)]));
    
    managed[@"anyUUIDObj"] = managed[@"anyUUIDObj"];
    XCTAssertEqualObjects([managed[@"anyUUIDObj"] valueForKey:@"self"], (@[uuid(@"00000000-0000-0000-0000-000000000000"), uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")]));
    
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
    XCTAssertEqualObjects([optManaged[@"decimalObj"] valueForKey:@"self"], (@[decimal128(2), decimal128(3), NSNull.null]));
    
    optManaged[@"objectIdObj"] = optManaged[@"objectIdObj"];
    XCTAssertEqualObjects([optManaged[@"objectIdObj"] valueForKey:@"self"], (@[objectId(1), objectId(2), NSNull.null]));
    
    optManaged[@"uuidObj"] = optManaged[@"uuidObj"];
    XCTAssertEqualObjects([optManaged[@"uuidObj"] valueForKey:@"self"], (@[uuid(@"00000000-0000-0000-0000-000000000000"), uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"), NSNull.null]));
    

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

#pragma mark - Queries

#define RLMAssertCount(cls, expectedCount, ...) \
    XCTAssertEqual(expectedCount, ([cls objectsInRealm:realm where:__VA_ARGS__].count))

- (void)createObjectWithValueIndex:(NSUInteger)index {
    NSRange range = {index, 1};
    id obj = [AllPrimitiveArrays createInRealm:realm withValue:@{
        @"boolObj": [@[@NO, @YES] subarrayWithRange:range],
        @"intObj": [@[@2, @3] subarrayWithRange:range],
        @"floatObj": [@[@2.2f, @3.3f] subarrayWithRange:range],
        @"doubleObj": [@[@2.2, @3.3] subarrayWithRange:range],
        @"stringObj": [@[@"a", @"b"] subarrayWithRange:range],
        @"dataObj": [@[data(1), data(2)] subarrayWithRange:range],
        @"dateObj": [@[date(1), date(2)] subarrayWithRange:range],
        @"decimalObj": [@[decimal128(2), decimal128(3)] subarrayWithRange:range],
        @"objectIdObj": [@[objectId(1), objectId(2)] subarrayWithRange:range],
        @"uuidObj": [@[uuid(@"00000000-0000-0000-0000-000000000000"), uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")] subarrayWithRange:range],
        @"anyBoolObj": [@[@NO, @YES] subarrayWithRange:range],
        @"anyIntObj": [@[@2, @3] subarrayWithRange:range],
        @"anyFloatObj": [@[@2.2f, @3.3f] subarrayWithRange:range],
        @"anyDoubleObj": [@[@2.2, @3.3] subarrayWithRange:range],
        @"anyStringObj": [@[@"a", @"b"] subarrayWithRange:range],
        @"anyDataObj": [@[data(1), data(2)] subarrayWithRange:range],
        @"anyDateObj": [@[date(1), date(2)] subarrayWithRange:range],
        @"anyDecimalObj": [@[decimal128(2), decimal128(3)] subarrayWithRange:range],
        @"anyObjectIdObj": [@[objectId(1), objectId(2)] subarrayWithRange:range],
        @"anyUUIDObj": [@[uuid(@"00000000-0000-0000-0000-000000000000"), uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")] subarrayWithRange:range],
    }];
    [LinkToAllPrimitiveArrays createInRealm:realm withValue:@[obj]];
    obj = [AllOptionalPrimitiveArrays createInRealm:realm withValue:@{
        @"boolObj": [@[@NO, @YES, NSNull.null] subarrayWithRange:range],
        @"intObj": [@[@2, @3, NSNull.null] subarrayWithRange:range],
        @"floatObj": [@[@2.2f, @3.3f, NSNull.null] subarrayWithRange:range],
        @"doubleObj": [@[@2.2, @3.3, NSNull.null] subarrayWithRange:range],
        @"stringObj": [@[@"a", @"b", NSNull.null] subarrayWithRange:range],
        @"dataObj": [@[data(1), data(2), NSNull.null] subarrayWithRange:range],
        @"dateObj": [@[date(1), date(2), NSNull.null] subarrayWithRange:range],
        @"decimalObj": [@[decimal128(2), decimal128(3), NSNull.null] subarrayWithRange:range],
        @"objectIdObj": [@[objectId(1), objectId(2), NSNull.null] subarrayWithRange:range],
        @"uuidObj": [@[uuid(@"00000000-0000-0000-0000-000000000000"), uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"), NSNull.null] subarrayWithRange:range],
    }];
    [LinkToAllOptionalPrimitiveArrays createInRealm:realm withValue:@[obj]];
}

- (void)testQueryBasicOperators {
    [realm deleteAllObjects];

    RLMAssertCount(AllPrimitiveArrays, 0, @"ANY boolObj = %@", @NO);
    RLMAssertCount(AllPrimitiveArrays, 0, @"ANY intObj = %@", @2);
    RLMAssertCount(AllPrimitiveArrays, 0, @"ANY floatObj = %@", @2.2f);
    RLMAssertCount(AllPrimitiveArrays, 0, @"ANY doubleObj = %@", @2.2);
    RLMAssertCount(AllPrimitiveArrays, 0, @"ANY stringObj = %@", @"a");
    RLMAssertCount(AllPrimitiveArrays, 0, @"ANY dataObj = %@", data(1));
    RLMAssertCount(AllPrimitiveArrays, 0, @"ANY dateObj = %@", date(1));
    RLMAssertCount(AllPrimitiveArrays, 0, @"ANY decimalObj = %@", decimal128(2));
    RLMAssertCount(AllPrimitiveArrays, 0, @"ANY objectIdObj = %@", objectId(1));
    RLMAssertCount(AllPrimitiveArrays, 0, @"ANY uuidObj = %@", uuid(@"00000000-0000-0000-0000-000000000000"));
    RLMAssertCount(AllPrimitiveArrays, 0, @"ANY anyBoolObj = %@", @NO);
    RLMAssertCount(AllPrimitiveArrays, 0, @"ANY anyIntObj = %@", @2);
    RLMAssertCount(AllPrimitiveArrays, 0, @"ANY anyFloatObj = %@", @2.2f);
    RLMAssertCount(AllPrimitiveArrays, 0, @"ANY anyDoubleObj = %@", @2.2);
    RLMAssertCount(AllPrimitiveArrays, 0, @"ANY anyStringObj = %@", @"a");
    RLMAssertCount(AllPrimitiveArrays, 0, @"ANY anyDataObj = %@", data(1));
    RLMAssertCount(AllPrimitiveArrays, 0, @"ANY anyDateObj = %@", date(1));
    RLMAssertCount(AllPrimitiveArrays, 0, @"ANY anyDecimalObj = %@", decimal128(2));
    RLMAssertCount(AllPrimitiveArrays, 0, @"ANY anyObjectIdObj = %@", objectId(1));
    RLMAssertCount(AllPrimitiveArrays, 0, @"ANY anyUUIDObj = %@", uuid(@"00000000-0000-0000-0000-000000000000"));
    RLMAssertCount(AllOptionalPrimitiveArrays, 0, @"ANY boolObj = %@", @NO);
    RLMAssertCount(AllOptionalPrimitiveArrays, 0, @"ANY intObj = %@", @2);
    RLMAssertCount(AllOptionalPrimitiveArrays, 0, @"ANY floatObj = %@", @2.2f);
    RLMAssertCount(AllOptionalPrimitiveArrays, 0, @"ANY doubleObj = %@", @2.2);
    RLMAssertCount(AllOptionalPrimitiveArrays, 0, @"ANY stringObj = %@", @"a");
    RLMAssertCount(AllOptionalPrimitiveArrays, 0, @"ANY dataObj = %@", data(1));
    RLMAssertCount(AllOptionalPrimitiveArrays, 0, @"ANY dateObj = %@", date(1));
    RLMAssertCount(AllOptionalPrimitiveArrays, 0, @"ANY decimalObj = %@", decimal128(2));
    RLMAssertCount(AllOptionalPrimitiveArrays, 0, @"ANY objectIdObj = %@", objectId(1));
    RLMAssertCount(AllOptionalPrimitiveArrays, 0, @"ANY uuidObj = %@", uuid(@"00000000-0000-0000-0000-000000000000"));
    RLMAssertCount(AllPrimitiveArrays, 0, @"ANY boolObj != %@", @NO);
    RLMAssertCount(AllPrimitiveArrays, 0, @"ANY intObj != %@", @2);
    RLMAssertCount(AllPrimitiveArrays, 0, @"ANY floatObj != %@", @2.2f);
    RLMAssertCount(AllPrimitiveArrays, 0, @"ANY doubleObj != %@", @2.2);
    RLMAssertCount(AllPrimitiveArrays, 0, @"ANY stringObj != %@", @"a");
    RLMAssertCount(AllPrimitiveArrays, 0, @"ANY dataObj != %@", data(1));
    RLMAssertCount(AllPrimitiveArrays, 0, @"ANY dateObj != %@", date(1));
    RLMAssertCount(AllPrimitiveArrays, 0, @"ANY decimalObj != %@", decimal128(2));
    RLMAssertCount(AllPrimitiveArrays, 0, @"ANY objectIdObj != %@", objectId(1));
    RLMAssertCount(AllPrimitiveArrays, 0, @"ANY uuidObj != %@", uuid(@"00000000-0000-0000-0000-000000000000"));
    RLMAssertCount(AllPrimitiveArrays, 0, @"ANY anyBoolObj != %@", @NO);
    RLMAssertCount(AllPrimitiveArrays, 0, @"ANY anyIntObj != %@", @2);
    RLMAssertCount(AllPrimitiveArrays, 0, @"ANY anyFloatObj != %@", @2.2f);
    RLMAssertCount(AllPrimitiveArrays, 0, @"ANY anyDoubleObj != %@", @2.2);
    RLMAssertCount(AllPrimitiveArrays, 0, @"ANY anyStringObj != %@", @"a");
    RLMAssertCount(AllPrimitiveArrays, 0, @"ANY anyDataObj != %@", data(1));
    RLMAssertCount(AllPrimitiveArrays, 0, @"ANY anyDateObj != %@", date(1));
    RLMAssertCount(AllPrimitiveArrays, 0, @"ANY anyDecimalObj != %@", decimal128(2));
    RLMAssertCount(AllPrimitiveArrays, 0, @"ANY anyObjectIdObj != %@", objectId(1));
    RLMAssertCount(AllPrimitiveArrays, 0, @"ANY anyUUIDObj != %@", uuid(@"00000000-0000-0000-0000-000000000000"));
    RLMAssertCount(AllOptionalPrimitiveArrays, 0, @"ANY boolObj != %@", @NO);
    RLMAssertCount(AllOptionalPrimitiveArrays, 0, @"ANY intObj != %@", @2);
    RLMAssertCount(AllOptionalPrimitiveArrays, 0, @"ANY floatObj != %@", @2.2f);
    RLMAssertCount(AllOptionalPrimitiveArrays, 0, @"ANY doubleObj != %@", @2.2);
    RLMAssertCount(AllOptionalPrimitiveArrays, 0, @"ANY stringObj != %@", @"a");
    RLMAssertCount(AllOptionalPrimitiveArrays, 0, @"ANY dataObj != %@", data(1));
    RLMAssertCount(AllOptionalPrimitiveArrays, 0, @"ANY dateObj != %@", date(1));
    RLMAssertCount(AllOptionalPrimitiveArrays, 0, @"ANY decimalObj != %@", decimal128(2));
    RLMAssertCount(AllOptionalPrimitiveArrays, 0, @"ANY objectIdObj != %@", objectId(1));
    RLMAssertCount(AllOptionalPrimitiveArrays, 0, @"ANY uuidObj != %@", uuid(@"00000000-0000-0000-0000-000000000000"));
    RLMAssertCount(AllPrimitiveArrays, 0, @"ANY intObj > %@", @2);
    RLMAssertCount(AllPrimitiveArrays, 0, @"ANY floatObj > %@", @2.2f);
    RLMAssertCount(AllPrimitiveArrays, 0, @"ANY doubleObj > %@", @2.2);
    RLMAssertCount(AllPrimitiveArrays, 0, @"ANY dateObj > %@", date(1));
    RLMAssertCount(AllPrimitiveArrays, 0, @"ANY decimalObj > %@", decimal128(2));
    RLMAssertCount(AllPrimitiveArrays, 0, @"ANY anyIntObj > %@", @2);
    RLMAssertCount(AllPrimitiveArrays, 0, @"ANY anyFloatObj > %@", @2.2f);
    RLMAssertCount(AllPrimitiveArrays, 0, @"ANY anyDoubleObj > %@", @2.2);
    RLMAssertCount(AllPrimitiveArrays, 0, @"ANY anyDateObj > %@", date(1));
    RLMAssertCount(AllPrimitiveArrays, 0, @"ANY anyDecimalObj > %@", decimal128(2));
    RLMAssertCount(AllOptionalPrimitiveArrays, 0, @"ANY intObj > %@", @2);
    RLMAssertCount(AllOptionalPrimitiveArrays, 0, @"ANY floatObj > %@", @2.2f);
    RLMAssertCount(AllOptionalPrimitiveArrays, 0, @"ANY doubleObj > %@", @2.2);
    RLMAssertCount(AllOptionalPrimitiveArrays, 0, @"ANY dateObj > %@", date(1));
    RLMAssertCount(AllOptionalPrimitiveArrays, 0, @"ANY decimalObj > %@", decimal128(2));
    RLMAssertCount(AllPrimitiveArrays, 0, @"ANY intObj >= %@", @2);
    RLMAssertCount(AllPrimitiveArrays, 0, @"ANY floatObj >= %@", @2.2f);
    RLMAssertCount(AllPrimitiveArrays, 0, @"ANY doubleObj >= %@", @2.2);
    RLMAssertCount(AllPrimitiveArrays, 0, @"ANY dateObj >= %@", date(1));
    RLMAssertCount(AllPrimitiveArrays, 0, @"ANY decimalObj >= %@", decimal128(2));
    RLMAssertCount(AllPrimitiveArrays, 0, @"ANY anyIntObj >= %@", @2);
    RLMAssertCount(AllPrimitiveArrays, 0, @"ANY anyFloatObj >= %@", @2.2f);
    RLMAssertCount(AllPrimitiveArrays, 0, @"ANY anyDoubleObj >= %@", @2.2);
    RLMAssertCount(AllPrimitiveArrays, 0, @"ANY anyDateObj >= %@", date(1));
    RLMAssertCount(AllPrimitiveArrays, 0, @"ANY anyDecimalObj >= %@", decimal128(2));
    RLMAssertCount(AllOptionalPrimitiveArrays, 0, @"ANY intObj >= %@", @2);
    RLMAssertCount(AllOptionalPrimitiveArrays, 0, @"ANY floatObj >= %@", @2.2f);
    RLMAssertCount(AllOptionalPrimitiveArrays, 0, @"ANY doubleObj >= %@", @2.2);
    RLMAssertCount(AllOptionalPrimitiveArrays, 0, @"ANY dateObj >= %@", date(1));
    RLMAssertCount(AllOptionalPrimitiveArrays, 0, @"ANY decimalObj >= %@", decimal128(2));
    RLMAssertCount(AllPrimitiveArrays, 0, @"ANY intObj < %@", @2);
    RLMAssertCount(AllPrimitiveArrays, 0, @"ANY floatObj < %@", @2.2f);
    RLMAssertCount(AllPrimitiveArrays, 0, @"ANY doubleObj < %@", @2.2);
    RLMAssertCount(AllPrimitiveArrays, 0, @"ANY dateObj < %@", date(1));
    RLMAssertCount(AllPrimitiveArrays, 0, @"ANY decimalObj < %@", decimal128(2));
    RLMAssertCount(AllPrimitiveArrays, 0, @"ANY anyIntObj < %@", @2);
    RLMAssertCount(AllPrimitiveArrays, 0, @"ANY anyFloatObj < %@", @2.2f);
    RLMAssertCount(AllPrimitiveArrays, 0, @"ANY anyDoubleObj < %@", @2.2);
    RLMAssertCount(AllPrimitiveArrays, 0, @"ANY anyDateObj < %@", date(1));
    RLMAssertCount(AllPrimitiveArrays, 0, @"ANY anyDecimalObj < %@", decimal128(2));
    RLMAssertCount(AllOptionalPrimitiveArrays, 0, @"ANY intObj < %@", @2);
    RLMAssertCount(AllOptionalPrimitiveArrays, 0, @"ANY floatObj < %@", @2.2f);
    RLMAssertCount(AllOptionalPrimitiveArrays, 0, @"ANY doubleObj < %@", @2.2);
    RLMAssertCount(AllOptionalPrimitiveArrays, 0, @"ANY dateObj < %@", date(1));
    RLMAssertCount(AllOptionalPrimitiveArrays, 0, @"ANY decimalObj < %@", decimal128(2));
    RLMAssertCount(AllPrimitiveArrays, 0, @"ANY intObj <= %@", @2);
    RLMAssertCount(AllPrimitiveArrays, 0, @"ANY floatObj <= %@", @2.2f);
    RLMAssertCount(AllPrimitiveArrays, 0, @"ANY doubleObj <= %@", @2.2);
    RLMAssertCount(AllPrimitiveArrays, 0, @"ANY dateObj <= %@", date(1));
    RLMAssertCount(AllPrimitiveArrays, 0, @"ANY decimalObj <= %@", decimal128(2));
    RLMAssertCount(AllPrimitiveArrays, 0, @"ANY anyIntObj <= %@", @2);
    RLMAssertCount(AllPrimitiveArrays, 0, @"ANY anyFloatObj <= %@", @2.2f);
    RLMAssertCount(AllPrimitiveArrays, 0, @"ANY anyDoubleObj <= %@", @2.2);
    RLMAssertCount(AllPrimitiveArrays, 0, @"ANY anyDateObj <= %@", date(1));
    RLMAssertCount(AllPrimitiveArrays, 0, @"ANY anyDecimalObj <= %@", decimal128(2));
    RLMAssertCount(AllOptionalPrimitiveArrays, 0, @"ANY intObj <= %@", @2);
    RLMAssertCount(AllOptionalPrimitiveArrays, 0, @"ANY floatObj <= %@", @2.2f);
    RLMAssertCount(AllOptionalPrimitiveArrays, 0, @"ANY doubleObj <= %@", @2.2);
    RLMAssertCount(AllOptionalPrimitiveArrays, 0, @"ANY dateObj <= %@", date(1));
    RLMAssertCount(AllOptionalPrimitiveArrays, 0, @"ANY decimalObj <= %@", decimal128(2));

    [self createObjectWithValueIndex:0];

    RLMAssertCount(AllPrimitiveArrays, 0, @"ANY boolObj = %@", @YES);
    RLMAssertCount(AllPrimitiveArrays, 0, @"ANY intObj = %@", @3);
    RLMAssertCount(AllPrimitiveArrays, 0, @"ANY floatObj = %@", @3.3f);
    RLMAssertCount(AllPrimitiveArrays, 0, @"ANY doubleObj = %@", @3.3);
    RLMAssertCount(AllPrimitiveArrays, 0, @"ANY stringObj = %@", @"b");
    RLMAssertCount(AllPrimitiveArrays, 0, @"ANY dataObj = %@", data(2));
    RLMAssertCount(AllPrimitiveArrays, 0, @"ANY dateObj = %@", date(2));
    RLMAssertCount(AllPrimitiveArrays, 0, @"ANY decimalObj = %@", decimal128(3));
    RLMAssertCount(AllPrimitiveArrays, 0, @"ANY objectIdObj = %@", objectId(2));
    RLMAssertCount(AllPrimitiveArrays, 0, @"ANY uuidObj = %@", uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"));
    RLMAssertCount(AllPrimitiveArrays, 0, @"ANY anyBoolObj = %@", @YES);
    RLMAssertCount(AllPrimitiveArrays, 0, @"ANY anyIntObj = %@", @3);
    RLMAssertCount(AllPrimitiveArrays, 0, @"ANY anyFloatObj = %@", @3.3f);
    RLMAssertCount(AllPrimitiveArrays, 0, @"ANY anyDoubleObj = %@", @3.3);
    RLMAssertCount(AllPrimitiveArrays, 0, @"ANY anyStringObj = %@", @"b");
    RLMAssertCount(AllPrimitiveArrays, 0, @"ANY anyDataObj = %@", data(2));
    RLMAssertCount(AllPrimitiveArrays, 0, @"ANY anyDateObj = %@", date(2));
    RLMAssertCount(AllPrimitiveArrays, 0, @"ANY anyDecimalObj = %@", decimal128(3));
    RLMAssertCount(AllPrimitiveArrays, 0, @"ANY anyObjectIdObj = %@", objectId(2));
    RLMAssertCount(AllPrimitiveArrays, 0, @"ANY anyUUIDObj = %@", uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"));
    RLMAssertCount(AllOptionalPrimitiveArrays, 0, @"ANY boolObj = %@", @YES);
    RLMAssertCount(AllOptionalPrimitiveArrays, 0, @"ANY intObj = %@", @3);
    RLMAssertCount(AllOptionalPrimitiveArrays, 0, @"ANY floatObj = %@", @3.3f);
    RLMAssertCount(AllOptionalPrimitiveArrays, 0, @"ANY doubleObj = %@", @3.3);
    RLMAssertCount(AllOptionalPrimitiveArrays, 0, @"ANY stringObj = %@", @"b");
    RLMAssertCount(AllOptionalPrimitiveArrays, 0, @"ANY dataObj = %@", data(2));
    RLMAssertCount(AllOptionalPrimitiveArrays, 0, @"ANY dateObj = %@", date(2));
    RLMAssertCount(AllOptionalPrimitiveArrays, 0, @"ANY decimalObj = %@", decimal128(3));
    RLMAssertCount(AllOptionalPrimitiveArrays, 0, @"ANY objectIdObj = %@", objectId(2));
    RLMAssertCount(AllOptionalPrimitiveArrays, 0, @"ANY uuidObj = %@", uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"));
    RLMAssertCount(AllPrimitiveArrays, 1, @"ANY boolObj = %@", @NO);
    RLMAssertCount(AllPrimitiveArrays, 1, @"ANY intObj = %@", @2);
    RLMAssertCount(AllPrimitiveArrays, 1, @"ANY floatObj = %@", @2.2f);
    RLMAssertCount(AllPrimitiveArrays, 1, @"ANY doubleObj = %@", @2.2);
    RLMAssertCount(AllPrimitiveArrays, 1, @"ANY stringObj = %@", @"a");
    RLMAssertCount(AllPrimitiveArrays, 1, @"ANY dataObj = %@", data(1));
    RLMAssertCount(AllPrimitiveArrays, 1, @"ANY dateObj = %@", date(1));
    RLMAssertCount(AllPrimitiveArrays, 1, @"ANY decimalObj = %@", decimal128(2));
    RLMAssertCount(AllPrimitiveArrays, 1, @"ANY objectIdObj = %@", objectId(1));
    RLMAssertCount(AllPrimitiveArrays, 1, @"ANY uuidObj = %@", uuid(@"00000000-0000-0000-0000-000000000000"));
    RLMAssertCount(AllPrimitiveArrays, 1, @"ANY anyBoolObj = %@", @NO);
    RLMAssertCount(AllPrimitiveArrays, 1, @"ANY anyIntObj = %@", @2);
    RLMAssertCount(AllPrimitiveArrays, 1, @"ANY anyFloatObj = %@", @2.2f);
    RLMAssertCount(AllPrimitiveArrays, 1, @"ANY anyDoubleObj = %@", @2.2);
    RLMAssertCount(AllPrimitiveArrays, 1, @"ANY anyStringObj = %@", @"a");
    RLMAssertCount(AllPrimitiveArrays, 1, @"ANY anyDataObj = %@", data(1));
    RLMAssertCount(AllPrimitiveArrays, 1, @"ANY anyDateObj = %@", date(1));
    RLMAssertCount(AllPrimitiveArrays, 1, @"ANY anyDecimalObj = %@", decimal128(2));
    RLMAssertCount(AllPrimitiveArrays, 1, @"ANY anyObjectIdObj = %@", objectId(1));
    RLMAssertCount(AllPrimitiveArrays, 1, @"ANY anyUUIDObj = %@", uuid(@"00000000-0000-0000-0000-000000000000"));
    RLMAssertCount(AllOptionalPrimitiveArrays, 1, @"ANY boolObj = %@", @NO);
    RLMAssertCount(AllOptionalPrimitiveArrays, 1, @"ANY intObj = %@", @2);
    RLMAssertCount(AllOptionalPrimitiveArrays, 1, @"ANY floatObj = %@", @2.2f);
    RLMAssertCount(AllOptionalPrimitiveArrays, 1, @"ANY doubleObj = %@", @2.2);
    RLMAssertCount(AllOptionalPrimitiveArrays, 1, @"ANY stringObj = %@", @"a");
    RLMAssertCount(AllOptionalPrimitiveArrays, 1, @"ANY dataObj = %@", data(1));
    RLMAssertCount(AllOptionalPrimitiveArrays, 1, @"ANY dateObj = %@", date(1));
    RLMAssertCount(AllOptionalPrimitiveArrays, 1, @"ANY decimalObj = %@", decimal128(2));
    RLMAssertCount(AllOptionalPrimitiveArrays, 1, @"ANY objectIdObj = %@", objectId(1));
    RLMAssertCount(AllOptionalPrimitiveArrays, 1, @"ANY uuidObj = %@", uuid(@"00000000-0000-0000-0000-000000000000"));
    RLMAssertCount(AllPrimitiveArrays, 0, @"ANY boolObj != %@", @NO);
    RLMAssertCount(AllPrimitiveArrays, 0, @"ANY intObj != %@", @2);
    RLMAssertCount(AllPrimitiveArrays, 0, @"ANY floatObj != %@", @2.2f);
    RLMAssertCount(AllPrimitiveArrays, 0, @"ANY doubleObj != %@", @2.2);
    RLMAssertCount(AllPrimitiveArrays, 0, @"ANY stringObj != %@", @"a");
    RLMAssertCount(AllPrimitiveArrays, 0, @"ANY dataObj != %@", data(1));
    RLMAssertCount(AllPrimitiveArrays, 0, @"ANY dateObj != %@", date(1));
    RLMAssertCount(AllPrimitiveArrays, 0, @"ANY decimalObj != %@", decimal128(2));
    RLMAssertCount(AllPrimitiveArrays, 0, @"ANY objectIdObj != %@", objectId(1));
    RLMAssertCount(AllPrimitiveArrays, 0, @"ANY uuidObj != %@", uuid(@"00000000-0000-0000-0000-000000000000"));
    RLMAssertCount(AllPrimitiveArrays, 0, @"ANY anyBoolObj != %@", @NO);
    RLMAssertCount(AllPrimitiveArrays, 0, @"ANY anyIntObj != %@", @2);
    RLMAssertCount(AllPrimitiveArrays, 0, @"ANY anyFloatObj != %@", @2.2f);
    RLMAssertCount(AllPrimitiveArrays, 0, @"ANY anyDoubleObj != %@", @2.2);
    RLMAssertCount(AllPrimitiveArrays, 0, @"ANY anyStringObj != %@", @"a");
    RLMAssertCount(AllPrimitiveArrays, 0, @"ANY anyDataObj != %@", data(1));
    RLMAssertCount(AllPrimitiveArrays, 0, @"ANY anyDateObj != %@", date(1));
    RLMAssertCount(AllPrimitiveArrays, 0, @"ANY anyDecimalObj != %@", decimal128(2));
    RLMAssertCount(AllPrimitiveArrays, 0, @"ANY anyObjectIdObj != %@", objectId(1));
    RLMAssertCount(AllPrimitiveArrays, 0, @"ANY anyUUIDObj != %@", uuid(@"00000000-0000-0000-0000-000000000000"));
    RLMAssertCount(AllOptionalPrimitiveArrays, 0, @"ANY boolObj != %@", @NO);
    RLMAssertCount(AllOptionalPrimitiveArrays, 0, @"ANY intObj != %@", @2);
    RLMAssertCount(AllOptionalPrimitiveArrays, 0, @"ANY floatObj != %@", @2.2f);
    RLMAssertCount(AllOptionalPrimitiveArrays, 0, @"ANY doubleObj != %@", @2.2);
    RLMAssertCount(AllOptionalPrimitiveArrays, 0, @"ANY stringObj != %@", @"a");
    RLMAssertCount(AllOptionalPrimitiveArrays, 0, @"ANY dataObj != %@", data(1));
    RLMAssertCount(AllOptionalPrimitiveArrays, 0, @"ANY dateObj != %@", date(1));
    RLMAssertCount(AllOptionalPrimitiveArrays, 0, @"ANY decimalObj != %@", decimal128(2));
    RLMAssertCount(AllOptionalPrimitiveArrays, 0, @"ANY objectIdObj != %@", objectId(1));
    RLMAssertCount(AllOptionalPrimitiveArrays, 0, @"ANY uuidObj != %@", uuid(@"00000000-0000-0000-0000-000000000000"));
    RLMAssertCount(AllPrimitiveArrays, 1, @"ANY boolObj != %@", @YES);
    RLMAssertCount(AllPrimitiveArrays, 1, @"ANY intObj != %@", @3);
    RLMAssertCount(AllPrimitiveArrays, 1, @"ANY floatObj != %@", @3.3f);
    RLMAssertCount(AllPrimitiveArrays, 1, @"ANY doubleObj != %@", @3.3);
    RLMAssertCount(AllPrimitiveArrays, 1, @"ANY stringObj != %@", @"b");
    RLMAssertCount(AllPrimitiveArrays, 1, @"ANY dataObj != %@", data(2));
    RLMAssertCount(AllPrimitiveArrays, 1, @"ANY dateObj != %@", date(2));
    RLMAssertCount(AllPrimitiveArrays, 1, @"ANY decimalObj != %@", decimal128(3));
    RLMAssertCount(AllPrimitiveArrays, 1, @"ANY objectIdObj != %@", objectId(2));
    RLMAssertCount(AllPrimitiveArrays, 1, @"ANY uuidObj != %@", uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"));
    RLMAssertCount(AllPrimitiveArrays, 1, @"ANY anyBoolObj != %@", @YES);
    RLMAssertCount(AllPrimitiveArrays, 1, @"ANY anyIntObj != %@", @3);
    RLMAssertCount(AllPrimitiveArrays, 1, @"ANY anyFloatObj != %@", @3.3f);
    RLMAssertCount(AllPrimitiveArrays, 1, @"ANY anyDoubleObj != %@", @3.3);
    RLMAssertCount(AllPrimitiveArrays, 1, @"ANY anyStringObj != %@", @"b");
    RLMAssertCount(AllPrimitiveArrays, 1, @"ANY anyDataObj != %@", data(2));
    RLMAssertCount(AllPrimitiveArrays, 1, @"ANY anyDateObj != %@", date(2));
    RLMAssertCount(AllPrimitiveArrays, 1, @"ANY anyDecimalObj != %@", decimal128(3));
    RLMAssertCount(AllPrimitiveArrays, 1, @"ANY anyObjectIdObj != %@", objectId(2));
    RLMAssertCount(AllPrimitiveArrays, 1, @"ANY anyUUIDObj != %@", uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"));
    RLMAssertCount(AllOptionalPrimitiveArrays, 1, @"ANY boolObj != %@", @YES);
    RLMAssertCount(AllOptionalPrimitiveArrays, 1, @"ANY intObj != %@", @3);
    RLMAssertCount(AllOptionalPrimitiveArrays, 1, @"ANY floatObj != %@", @3.3f);
    RLMAssertCount(AllOptionalPrimitiveArrays, 1, @"ANY doubleObj != %@", @3.3);
    RLMAssertCount(AllOptionalPrimitiveArrays, 1, @"ANY stringObj != %@", @"b");
    RLMAssertCount(AllOptionalPrimitiveArrays, 1, @"ANY dataObj != %@", data(2));
    RLMAssertCount(AllOptionalPrimitiveArrays, 1, @"ANY dateObj != %@", date(2));
    RLMAssertCount(AllOptionalPrimitiveArrays, 1, @"ANY decimalObj != %@", decimal128(3));
    RLMAssertCount(AllOptionalPrimitiveArrays, 1, @"ANY objectIdObj != %@", objectId(2));
    RLMAssertCount(AllOptionalPrimitiveArrays, 1, @"ANY uuidObj != %@", uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"));
    RLMAssertCount(AllPrimitiveArrays, 0, @"ANY intObj > %@", @2);
    RLMAssertCount(AllPrimitiveArrays, 0, @"ANY floatObj > %@", @2.2f);
    RLMAssertCount(AllPrimitiveArrays, 0, @"ANY doubleObj > %@", @2.2);
    RLMAssertCount(AllPrimitiveArrays, 0, @"ANY dateObj > %@", date(1));
    RLMAssertCount(AllPrimitiveArrays, 0, @"ANY decimalObj > %@", decimal128(2));
    RLMAssertCount(AllPrimitiveArrays, 0, @"ANY anyIntObj > %@", @2);
    RLMAssertCount(AllPrimitiveArrays, 0, @"ANY anyFloatObj > %@", @2.2f);
    RLMAssertCount(AllPrimitiveArrays, 0, @"ANY anyDoubleObj > %@", @2.2);
    RLMAssertCount(AllPrimitiveArrays, 0, @"ANY anyDateObj > %@", date(1));
    RLMAssertCount(AllPrimitiveArrays, 0, @"ANY anyDecimalObj > %@", decimal128(2));
    RLMAssertCount(AllOptionalPrimitiveArrays, 0, @"ANY intObj > %@", @2);
    RLMAssertCount(AllOptionalPrimitiveArrays, 0, @"ANY floatObj > %@", @2.2f);
    RLMAssertCount(AllOptionalPrimitiveArrays, 0, @"ANY doubleObj > %@", @2.2);
    RLMAssertCount(AllOptionalPrimitiveArrays, 0, @"ANY dateObj > %@", date(1));
    RLMAssertCount(AllOptionalPrimitiveArrays, 0, @"ANY decimalObj > %@", decimal128(2));
    RLMAssertCount(AllPrimitiveArrays, 1, @"ANY intObj >= %@", @2);
    RLMAssertCount(AllPrimitiveArrays, 1, @"ANY floatObj >= %@", @2.2f);
    RLMAssertCount(AllPrimitiveArrays, 1, @"ANY doubleObj >= %@", @2.2);
    RLMAssertCount(AllPrimitiveArrays, 1, @"ANY dateObj >= %@", date(1));
    RLMAssertCount(AllPrimitiveArrays, 1, @"ANY decimalObj >= %@", decimal128(2));
    RLMAssertCount(AllPrimitiveArrays, 1, @"ANY anyIntObj >= %@", @2);
    RLMAssertCount(AllPrimitiveArrays, 1, @"ANY anyFloatObj >= %@", @2.2f);
    RLMAssertCount(AllPrimitiveArrays, 1, @"ANY anyDoubleObj >= %@", @2.2);
    RLMAssertCount(AllPrimitiveArrays, 1, @"ANY anyDateObj >= %@", date(1));
    RLMAssertCount(AllPrimitiveArrays, 1, @"ANY anyDecimalObj >= %@", decimal128(2));
    RLMAssertCount(AllOptionalPrimitiveArrays, 1, @"ANY intObj >= %@", @2);
    RLMAssertCount(AllOptionalPrimitiveArrays, 1, @"ANY floatObj >= %@", @2.2f);
    RLMAssertCount(AllOptionalPrimitiveArrays, 1, @"ANY doubleObj >= %@", @2.2);
    RLMAssertCount(AllOptionalPrimitiveArrays, 1, @"ANY dateObj >= %@", date(1));
    RLMAssertCount(AllOptionalPrimitiveArrays, 1, @"ANY decimalObj >= %@", decimal128(2));
    RLMAssertCount(AllPrimitiveArrays, 0, @"ANY intObj < %@", @2);
    RLMAssertCount(AllPrimitiveArrays, 0, @"ANY floatObj < %@", @2.2f);
    RLMAssertCount(AllPrimitiveArrays, 0, @"ANY doubleObj < %@", @2.2);
    RLMAssertCount(AllPrimitiveArrays, 0, @"ANY dateObj < %@", date(1));
    RLMAssertCount(AllPrimitiveArrays, 0, @"ANY decimalObj < %@", decimal128(2));
    RLMAssertCount(AllPrimitiveArrays, 0, @"ANY anyIntObj < %@", @2);
    RLMAssertCount(AllPrimitiveArrays, 0, @"ANY anyFloatObj < %@", @2.2f);
    RLMAssertCount(AllPrimitiveArrays, 0, @"ANY anyDoubleObj < %@", @2.2);
    RLMAssertCount(AllPrimitiveArrays, 0, @"ANY anyDateObj < %@", date(1));
    RLMAssertCount(AllPrimitiveArrays, 0, @"ANY anyDecimalObj < %@", decimal128(2));
    RLMAssertCount(AllOptionalPrimitiveArrays, 0, @"ANY intObj < %@", @2);
    RLMAssertCount(AllOptionalPrimitiveArrays, 0, @"ANY floatObj < %@", @2.2f);
    RLMAssertCount(AllOptionalPrimitiveArrays, 0, @"ANY doubleObj < %@", @2.2);
    RLMAssertCount(AllOptionalPrimitiveArrays, 0, @"ANY dateObj < %@", date(1));
    RLMAssertCount(AllOptionalPrimitiveArrays, 0, @"ANY decimalObj < %@", decimal128(2));
    RLMAssertCount(AllPrimitiveArrays, 1, @"ANY intObj < %@", @3);
    RLMAssertCount(AllPrimitiveArrays, 1, @"ANY floatObj < %@", @3.3f);
    RLMAssertCount(AllPrimitiveArrays, 1, @"ANY doubleObj < %@", @3.3);
    RLMAssertCount(AllPrimitiveArrays, 1, @"ANY dateObj < %@", date(2));
    RLMAssertCount(AllPrimitiveArrays, 1, @"ANY decimalObj < %@", decimal128(3));
    RLMAssertCount(AllPrimitiveArrays, 1, @"ANY anyIntObj < %@", @3);
    RLMAssertCount(AllPrimitiveArrays, 1, @"ANY anyFloatObj < %@", @3.3f);
    RLMAssertCount(AllPrimitiveArrays, 1, @"ANY anyDoubleObj < %@", @3.3);
    RLMAssertCount(AllPrimitiveArrays, 1, @"ANY anyDateObj < %@", date(2));
    RLMAssertCount(AllPrimitiveArrays, 1, @"ANY anyDecimalObj < %@", decimal128(3));
    RLMAssertCount(AllOptionalPrimitiveArrays, 1, @"ANY intObj < %@", @3);
    RLMAssertCount(AllOptionalPrimitiveArrays, 1, @"ANY floatObj < %@", @3.3f);
    RLMAssertCount(AllOptionalPrimitiveArrays, 1, @"ANY doubleObj < %@", @3.3);
    RLMAssertCount(AllOptionalPrimitiveArrays, 1, @"ANY dateObj < %@", date(2));
    RLMAssertCount(AllOptionalPrimitiveArrays, 1, @"ANY decimalObj < %@", decimal128(3));
    RLMAssertCount(AllPrimitiveArrays, 1, @"ANY intObj <= %@", @2);
    RLMAssertCount(AllPrimitiveArrays, 1, @"ANY floatObj <= %@", @2.2f);
    RLMAssertCount(AllPrimitiveArrays, 1, @"ANY doubleObj <= %@", @2.2);
    RLMAssertCount(AllPrimitiveArrays, 1, @"ANY dateObj <= %@", date(1));
    RLMAssertCount(AllPrimitiveArrays, 1, @"ANY decimalObj <= %@", decimal128(2));
    RLMAssertCount(AllPrimitiveArrays, 1, @"ANY anyIntObj <= %@", @2);
    RLMAssertCount(AllPrimitiveArrays, 1, @"ANY anyFloatObj <= %@", @2.2f);
    RLMAssertCount(AllPrimitiveArrays, 1, @"ANY anyDoubleObj <= %@", @2.2);
    RLMAssertCount(AllPrimitiveArrays, 1, @"ANY anyDateObj <= %@", date(1));
    RLMAssertCount(AllPrimitiveArrays, 1, @"ANY anyDecimalObj <= %@", decimal128(2));
    RLMAssertCount(AllOptionalPrimitiveArrays, 1, @"ANY intObj <= %@", @2);
    RLMAssertCount(AllOptionalPrimitiveArrays, 1, @"ANY floatObj <= %@", @2.2f);
    RLMAssertCount(AllOptionalPrimitiveArrays, 1, @"ANY doubleObj <= %@", @2.2);
    RLMAssertCount(AllOptionalPrimitiveArrays, 1, @"ANY dateObj <= %@", date(1));
    RLMAssertCount(AllOptionalPrimitiveArrays, 1, @"ANY decimalObj <= %@", decimal128(2));

    [self createObjectWithValueIndex:1];

    RLMAssertCount(AllPrimitiveArrays, 1, @"ANY boolObj = %@", @NO);
    RLMAssertCount(AllPrimitiveArrays, 1, @"ANY intObj = %@", @2);
    RLMAssertCount(AllPrimitiveArrays, 1, @"ANY floatObj = %@", @2.2f);
    RLMAssertCount(AllPrimitiveArrays, 1, @"ANY doubleObj = %@", @2.2);
    RLMAssertCount(AllPrimitiveArrays, 1, @"ANY stringObj = %@", @"a");
    RLMAssertCount(AllPrimitiveArrays, 1, @"ANY dataObj = %@", data(1));
    RLMAssertCount(AllPrimitiveArrays, 1, @"ANY dateObj = %@", date(1));
    RLMAssertCount(AllPrimitiveArrays, 1, @"ANY decimalObj = %@", decimal128(2));
    RLMAssertCount(AllPrimitiveArrays, 1, @"ANY objectIdObj = %@", objectId(1));
    RLMAssertCount(AllPrimitiveArrays, 1, @"ANY uuidObj = %@", uuid(@"00000000-0000-0000-0000-000000000000"));
    RLMAssertCount(AllPrimitiveArrays, 1, @"ANY anyBoolObj = %@", @NO);
    RLMAssertCount(AllPrimitiveArrays, 1, @"ANY anyIntObj = %@", @2);
    RLMAssertCount(AllPrimitiveArrays, 1, @"ANY anyFloatObj = %@", @2.2f);
    RLMAssertCount(AllPrimitiveArrays, 1, @"ANY anyDoubleObj = %@", @2.2);
    RLMAssertCount(AllPrimitiveArrays, 1, @"ANY anyStringObj = %@", @"a");
    RLMAssertCount(AllPrimitiveArrays, 1, @"ANY anyDataObj = %@", data(1));
    RLMAssertCount(AllPrimitiveArrays, 1, @"ANY anyDateObj = %@", date(1));
    RLMAssertCount(AllPrimitiveArrays, 1, @"ANY anyDecimalObj = %@", decimal128(2));
    RLMAssertCount(AllPrimitiveArrays, 1, @"ANY anyObjectIdObj = %@", objectId(1));
    RLMAssertCount(AllPrimitiveArrays, 1, @"ANY anyUUIDObj = %@", uuid(@"00000000-0000-0000-0000-000000000000"));
    RLMAssertCount(AllOptionalPrimitiveArrays, 1, @"ANY boolObj = %@", @NO);
    RLMAssertCount(AllOptionalPrimitiveArrays, 1, @"ANY intObj = %@", @2);
    RLMAssertCount(AllOptionalPrimitiveArrays, 1, @"ANY floatObj = %@", @2.2f);
    RLMAssertCount(AllOptionalPrimitiveArrays, 1, @"ANY doubleObj = %@", @2.2);
    RLMAssertCount(AllOptionalPrimitiveArrays, 1, @"ANY stringObj = %@", @"a");
    RLMAssertCount(AllOptionalPrimitiveArrays, 1, @"ANY dataObj = %@", data(1));
    RLMAssertCount(AllOptionalPrimitiveArrays, 1, @"ANY dateObj = %@", date(1));
    RLMAssertCount(AllOptionalPrimitiveArrays, 1, @"ANY decimalObj = %@", decimal128(2));
    RLMAssertCount(AllOptionalPrimitiveArrays, 1, @"ANY objectIdObj = %@", objectId(1));
    RLMAssertCount(AllOptionalPrimitiveArrays, 1, @"ANY uuidObj = %@", uuid(@"00000000-0000-0000-0000-000000000000"));
    RLMAssertCount(AllPrimitiveArrays, 1, @"ANY boolObj = %@", @YES);
    RLMAssertCount(AllPrimitiveArrays, 1, @"ANY intObj = %@", @3);
    RLMAssertCount(AllPrimitiveArrays, 1, @"ANY floatObj = %@", @3.3f);
    RLMAssertCount(AllPrimitiveArrays, 1, @"ANY doubleObj = %@", @3.3);
    RLMAssertCount(AllPrimitiveArrays, 1, @"ANY stringObj = %@", @"b");
    RLMAssertCount(AllPrimitiveArrays, 1, @"ANY dataObj = %@", data(2));
    RLMAssertCount(AllPrimitiveArrays, 1, @"ANY dateObj = %@", date(2));
    RLMAssertCount(AllPrimitiveArrays, 1, @"ANY decimalObj = %@", decimal128(3));
    RLMAssertCount(AllPrimitiveArrays, 1, @"ANY objectIdObj = %@", objectId(2));
    RLMAssertCount(AllPrimitiveArrays, 1, @"ANY uuidObj = %@", uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"));
    RLMAssertCount(AllPrimitiveArrays, 1, @"ANY anyBoolObj = %@", @YES);
    RLMAssertCount(AllPrimitiveArrays, 1, @"ANY anyIntObj = %@", @3);
    RLMAssertCount(AllPrimitiveArrays, 1, @"ANY anyFloatObj = %@", @3.3f);
    RLMAssertCount(AllPrimitiveArrays, 1, @"ANY anyDoubleObj = %@", @3.3);
    RLMAssertCount(AllPrimitiveArrays, 1, @"ANY anyStringObj = %@", @"b");
    RLMAssertCount(AllPrimitiveArrays, 1, @"ANY anyDataObj = %@", data(2));
    RLMAssertCount(AllPrimitiveArrays, 1, @"ANY anyDateObj = %@", date(2));
    RLMAssertCount(AllPrimitiveArrays, 1, @"ANY anyDecimalObj = %@", decimal128(3));
    RLMAssertCount(AllPrimitiveArrays, 1, @"ANY anyObjectIdObj = %@", objectId(2));
    RLMAssertCount(AllPrimitiveArrays, 1, @"ANY anyUUIDObj = %@", uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"));
    RLMAssertCount(AllOptionalPrimitiveArrays, 1, @"ANY boolObj = %@", @YES);
    RLMAssertCount(AllOptionalPrimitiveArrays, 1, @"ANY intObj = %@", @3);
    RLMAssertCount(AllOptionalPrimitiveArrays, 1, @"ANY floatObj = %@", @3.3f);
    RLMAssertCount(AllOptionalPrimitiveArrays, 1, @"ANY doubleObj = %@", @3.3);
    RLMAssertCount(AllOptionalPrimitiveArrays, 1, @"ANY stringObj = %@", @"b");
    RLMAssertCount(AllOptionalPrimitiveArrays, 1, @"ANY dataObj = %@", data(2));
    RLMAssertCount(AllOptionalPrimitiveArrays, 1, @"ANY dateObj = %@", date(2));
    RLMAssertCount(AllOptionalPrimitiveArrays, 1, @"ANY decimalObj = %@", decimal128(3));
    RLMAssertCount(AllOptionalPrimitiveArrays, 1, @"ANY objectIdObj = %@", objectId(2));
    RLMAssertCount(AllOptionalPrimitiveArrays, 1, @"ANY uuidObj = %@", uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"));
    RLMAssertCount(AllPrimitiveArrays, 1, @"ANY boolObj != %@", @NO);
    RLMAssertCount(AllPrimitiveArrays, 1, @"ANY intObj != %@", @2);
    RLMAssertCount(AllPrimitiveArrays, 1, @"ANY floatObj != %@", @2.2f);
    RLMAssertCount(AllPrimitiveArrays, 1, @"ANY doubleObj != %@", @2.2);
    RLMAssertCount(AllPrimitiveArrays, 1, @"ANY stringObj != %@", @"a");
    RLMAssertCount(AllPrimitiveArrays, 1, @"ANY dataObj != %@", data(1));
    RLMAssertCount(AllPrimitiveArrays, 1, @"ANY dateObj != %@", date(1));
    RLMAssertCount(AllPrimitiveArrays, 1, @"ANY decimalObj != %@", decimal128(2));
    RLMAssertCount(AllPrimitiveArrays, 1, @"ANY objectIdObj != %@", objectId(1));
    RLMAssertCount(AllPrimitiveArrays, 1, @"ANY uuidObj != %@", uuid(@"00000000-0000-0000-0000-000000000000"));
    RLMAssertCount(AllPrimitiveArrays, 1, @"ANY anyBoolObj != %@", @NO);
    RLMAssertCount(AllPrimitiveArrays, 1, @"ANY anyIntObj != %@", @2);
    RLMAssertCount(AllPrimitiveArrays, 1, @"ANY anyFloatObj != %@", @2.2f);
    RLMAssertCount(AllPrimitiveArrays, 1, @"ANY anyDoubleObj != %@", @2.2);
    RLMAssertCount(AllPrimitiveArrays, 1, @"ANY anyStringObj != %@", @"a");
    RLMAssertCount(AllPrimitiveArrays, 1, @"ANY anyDataObj != %@", data(1));
    RLMAssertCount(AllPrimitiveArrays, 1, @"ANY anyDateObj != %@", date(1));
    RLMAssertCount(AllPrimitiveArrays, 1, @"ANY anyDecimalObj != %@", decimal128(2));
    RLMAssertCount(AllPrimitiveArrays, 1, @"ANY anyObjectIdObj != %@", objectId(1));
    RLMAssertCount(AllPrimitiveArrays, 1, @"ANY anyUUIDObj != %@", uuid(@"00000000-0000-0000-0000-000000000000"));
    RLMAssertCount(AllOptionalPrimitiveArrays, 1, @"ANY boolObj != %@", @NO);
    RLMAssertCount(AllOptionalPrimitiveArrays, 1, @"ANY intObj != %@", @2);
    RLMAssertCount(AllOptionalPrimitiveArrays, 1, @"ANY floatObj != %@", @2.2f);
    RLMAssertCount(AllOptionalPrimitiveArrays, 1, @"ANY doubleObj != %@", @2.2);
    RLMAssertCount(AllOptionalPrimitiveArrays, 1, @"ANY stringObj != %@", @"a");
    RLMAssertCount(AllOptionalPrimitiveArrays, 1, @"ANY dataObj != %@", data(1));
    RLMAssertCount(AllOptionalPrimitiveArrays, 1, @"ANY dateObj != %@", date(1));
    RLMAssertCount(AllOptionalPrimitiveArrays, 1, @"ANY decimalObj != %@", decimal128(2));
    RLMAssertCount(AllOptionalPrimitiveArrays, 1, @"ANY objectIdObj != %@", objectId(1));
    RLMAssertCount(AllOptionalPrimitiveArrays, 1, @"ANY uuidObj != %@", uuid(@"00000000-0000-0000-0000-000000000000"));
    RLMAssertCount(AllPrimitiveArrays, 1, @"ANY boolObj != %@", @YES);
    RLMAssertCount(AllPrimitiveArrays, 1, @"ANY intObj != %@", @3);
    RLMAssertCount(AllPrimitiveArrays, 1, @"ANY floatObj != %@", @3.3f);
    RLMAssertCount(AllPrimitiveArrays, 1, @"ANY doubleObj != %@", @3.3);
    RLMAssertCount(AllPrimitiveArrays, 1, @"ANY stringObj != %@", @"b");
    RLMAssertCount(AllPrimitiveArrays, 1, @"ANY dataObj != %@", data(2));
    RLMAssertCount(AllPrimitiveArrays, 1, @"ANY dateObj != %@", date(2));
    RLMAssertCount(AllPrimitiveArrays, 1, @"ANY decimalObj != %@", decimal128(3));
    RLMAssertCount(AllPrimitiveArrays, 1, @"ANY objectIdObj != %@", objectId(2));
    RLMAssertCount(AllPrimitiveArrays, 1, @"ANY uuidObj != %@", uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"));
    RLMAssertCount(AllPrimitiveArrays, 1, @"ANY anyBoolObj != %@", @YES);
    RLMAssertCount(AllPrimitiveArrays, 1, @"ANY anyIntObj != %@", @3);
    RLMAssertCount(AllPrimitiveArrays, 1, @"ANY anyFloatObj != %@", @3.3f);
    RLMAssertCount(AllPrimitiveArrays, 1, @"ANY anyDoubleObj != %@", @3.3);
    RLMAssertCount(AllPrimitiveArrays, 1, @"ANY anyStringObj != %@", @"b");
    RLMAssertCount(AllPrimitiveArrays, 1, @"ANY anyDataObj != %@", data(2));
    RLMAssertCount(AllPrimitiveArrays, 1, @"ANY anyDateObj != %@", date(2));
    RLMAssertCount(AllPrimitiveArrays, 1, @"ANY anyDecimalObj != %@", decimal128(3));
    RLMAssertCount(AllPrimitiveArrays, 1, @"ANY anyObjectIdObj != %@", objectId(2));
    RLMAssertCount(AllPrimitiveArrays, 1, @"ANY anyUUIDObj != %@", uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"));
    RLMAssertCount(AllOptionalPrimitiveArrays, 1, @"ANY boolObj != %@", @YES);
    RLMAssertCount(AllOptionalPrimitiveArrays, 1, @"ANY intObj != %@", @3);
    RLMAssertCount(AllOptionalPrimitiveArrays, 1, @"ANY floatObj != %@", @3.3f);
    RLMAssertCount(AllOptionalPrimitiveArrays, 1, @"ANY doubleObj != %@", @3.3);
    RLMAssertCount(AllOptionalPrimitiveArrays, 1, @"ANY stringObj != %@", @"b");
    RLMAssertCount(AllOptionalPrimitiveArrays, 1, @"ANY dataObj != %@", data(2));
    RLMAssertCount(AllOptionalPrimitiveArrays, 1, @"ANY dateObj != %@", date(2));
    RLMAssertCount(AllOptionalPrimitiveArrays, 1, @"ANY decimalObj != %@", decimal128(3));
    RLMAssertCount(AllOptionalPrimitiveArrays, 1, @"ANY objectIdObj != %@", objectId(2));
    RLMAssertCount(AllOptionalPrimitiveArrays, 1, @"ANY uuidObj != %@", uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"));
    RLMAssertCount(AllPrimitiveArrays, 1, @"ANY intObj > %@", @2);
    RLMAssertCount(AllPrimitiveArrays, 1, @"ANY floatObj > %@", @2.2f);
    RLMAssertCount(AllPrimitiveArrays, 1, @"ANY doubleObj > %@", @2.2);
    RLMAssertCount(AllPrimitiveArrays, 1, @"ANY dateObj > %@", date(1));
    RLMAssertCount(AllPrimitiveArrays, 1, @"ANY decimalObj > %@", decimal128(2));
    RLMAssertCount(AllPrimitiveArrays, 1, @"ANY anyIntObj > %@", @2);
    RLMAssertCount(AllPrimitiveArrays, 1, @"ANY anyFloatObj > %@", @2.2f);
    RLMAssertCount(AllPrimitiveArrays, 1, @"ANY anyDoubleObj > %@", @2.2);
    RLMAssertCount(AllPrimitiveArrays, 1, @"ANY anyDateObj > %@", date(1));
    RLMAssertCount(AllPrimitiveArrays, 1, @"ANY anyDecimalObj > %@", decimal128(2));
    RLMAssertCount(AllOptionalPrimitiveArrays, 1, @"ANY intObj > %@", @2);
    RLMAssertCount(AllOptionalPrimitiveArrays, 1, @"ANY floatObj > %@", @2.2f);
    RLMAssertCount(AllOptionalPrimitiveArrays, 1, @"ANY doubleObj > %@", @2.2);
    RLMAssertCount(AllOptionalPrimitiveArrays, 1, @"ANY dateObj > %@", date(1));
    RLMAssertCount(AllOptionalPrimitiveArrays, 1, @"ANY decimalObj > %@", decimal128(2));
    RLMAssertCount(AllPrimitiveArrays, 2, @"ANY intObj >= %@", @2);
    RLMAssertCount(AllPrimitiveArrays, 2, @"ANY floatObj >= %@", @2.2f);
    RLMAssertCount(AllPrimitiveArrays, 2, @"ANY doubleObj >= %@", @2.2);
    RLMAssertCount(AllPrimitiveArrays, 2, @"ANY dateObj >= %@", date(1));
    RLMAssertCount(AllPrimitiveArrays, 2, @"ANY decimalObj >= %@", decimal128(2));
    RLMAssertCount(AllPrimitiveArrays, 2, @"ANY anyIntObj >= %@", @2);
    RLMAssertCount(AllPrimitiveArrays, 2, @"ANY anyFloatObj >= %@", @2.2f);
    RLMAssertCount(AllPrimitiveArrays, 2, @"ANY anyDoubleObj >= %@", @2.2);
    RLMAssertCount(AllPrimitiveArrays, 2, @"ANY anyDateObj >= %@", date(1));
    RLMAssertCount(AllPrimitiveArrays, 2, @"ANY anyDecimalObj >= %@", decimal128(2));
    RLMAssertCount(AllOptionalPrimitiveArrays, 2, @"ANY intObj >= %@", @2);
    RLMAssertCount(AllOptionalPrimitiveArrays, 2, @"ANY floatObj >= %@", @2.2f);
    RLMAssertCount(AllOptionalPrimitiveArrays, 2, @"ANY doubleObj >= %@", @2.2);
    RLMAssertCount(AllOptionalPrimitiveArrays, 2, @"ANY dateObj >= %@", date(1));
    RLMAssertCount(AllOptionalPrimitiveArrays, 2, @"ANY decimalObj >= %@", decimal128(2));
    RLMAssertCount(AllPrimitiveArrays, 0, @"ANY intObj < %@", @2);
    RLMAssertCount(AllPrimitiveArrays, 0, @"ANY floatObj < %@", @2.2f);
    RLMAssertCount(AllPrimitiveArrays, 0, @"ANY doubleObj < %@", @2.2);
    RLMAssertCount(AllPrimitiveArrays, 0, @"ANY dateObj < %@", date(1));
    RLMAssertCount(AllPrimitiveArrays, 0, @"ANY decimalObj < %@", decimal128(2));
    RLMAssertCount(AllPrimitiveArrays, 0, @"ANY anyIntObj < %@", @2);
    RLMAssertCount(AllPrimitiveArrays, 0, @"ANY anyFloatObj < %@", @2.2f);
    RLMAssertCount(AllPrimitiveArrays, 0, @"ANY anyDoubleObj < %@", @2.2);
    RLMAssertCount(AllPrimitiveArrays, 0, @"ANY anyDateObj < %@", date(1));
    RLMAssertCount(AllPrimitiveArrays, 0, @"ANY anyDecimalObj < %@", decimal128(2));
    RLMAssertCount(AllOptionalPrimitiveArrays, 0, @"ANY intObj < %@", @2);
    RLMAssertCount(AllOptionalPrimitiveArrays, 0, @"ANY floatObj < %@", @2.2f);
    RLMAssertCount(AllOptionalPrimitiveArrays, 0, @"ANY doubleObj < %@", @2.2);
    RLMAssertCount(AllOptionalPrimitiveArrays, 0, @"ANY dateObj < %@", date(1));
    RLMAssertCount(AllOptionalPrimitiveArrays, 0, @"ANY decimalObj < %@", decimal128(2));
    RLMAssertCount(AllPrimitiveArrays, 1, @"ANY intObj < %@", @3);
    RLMAssertCount(AllPrimitiveArrays, 1, @"ANY floatObj < %@", @3.3f);
    RLMAssertCount(AllPrimitiveArrays, 1, @"ANY doubleObj < %@", @3.3);
    RLMAssertCount(AllPrimitiveArrays, 1, @"ANY dateObj < %@", date(2));
    RLMAssertCount(AllPrimitiveArrays, 1, @"ANY decimalObj < %@", decimal128(3));
    RLMAssertCount(AllPrimitiveArrays, 1, @"ANY anyIntObj < %@", @3);
    RLMAssertCount(AllPrimitiveArrays, 1, @"ANY anyFloatObj < %@", @3.3f);
    RLMAssertCount(AllPrimitiveArrays, 1, @"ANY anyDoubleObj < %@", @3.3);
    RLMAssertCount(AllPrimitiveArrays, 1, @"ANY anyDateObj < %@", date(2));
    RLMAssertCount(AllPrimitiveArrays, 1, @"ANY anyDecimalObj < %@", decimal128(3));
    RLMAssertCount(AllOptionalPrimitiveArrays, 1, @"ANY intObj < %@", @3);
    RLMAssertCount(AllOptionalPrimitiveArrays, 1, @"ANY floatObj < %@", @3.3f);
    RLMAssertCount(AllOptionalPrimitiveArrays, 1, @"ANY doubleObj < %@", @3.3);
    RLMAssertCount(AllOptionalPrimitiveArrays, 1, @"ANY dateObj < %@", date(2));
    RLMAssertCount(AllOptionalPrimitiveArrays, 1, @"ANY decimalObj < %@", decimal128(3));
    RLMAssertCount(AllPrimitiveArrays, 1, @"ANY intObj <= %@", @2);
    RLMAssertCount(AllPrimitiveArrays, 1, @"ANY floatObj <= %@", @2.2f);
    RLMAssertCount(AllPrimitiveArrays, 1, @"ANY doubleObj <= %@", @2.2);
    RLMAssertCount(AllPrimitiveArrays, 1, @"ANY dateObj <= %@", date(1));
    RLMAssertCount(AllPrimitiveArrays, 1, @"ANY decimalObj <= %@", decimal128(2));
    RLMAssertCount(AllPrimitiveArrays, 1, @"ANY anyIntObj <= %@", @2);
    RLMAssertCount(AllPrimitiveArrays, 1, @"ANY anyFloatObj <= %@", @2.2f);
    RLMAssertCount(AllPrimitiveArrays, 1, @"ANY anyDoubleObj <= %@", @2.2);
    RLMAssertCount(AllPrimitiveArrays, 1, @"ANY anyDateObj <= %@", date(1));
    RLMAssertCount(AllPrimitiveArrays, 1, @"ANY anyDecimalObj <= %@", decimal128(2));
    RLMAssertCount(AllOptionalPrimitiveArrays, 1, @"ANY intObj <= %@", @2);
    RLMAssertCount(AllOptionalPrimitiveArrays, 1, @"ANY floatObj <= %@", @2.2f);
    RLMAssertCount(AllOptionalPrimitiveArrays, 1, @"ANY doubleObj <= %@", @2.2);
    RLMAssertCount(AllOptionalPrimitiveArrays, 1, @"ANY dateObj <= %@", date(1));
    RLMAssertCount(AllOptionalPrimitiveArrays, 1, @"ANY decimalObj <= %@", decimal128(2));
    RLMAssertCount(AllPrimitiveArrays, 2, @"ANY intObj <= %@", @3);
    RLMAssertCount(AllPrimitiveArrays, 2, @"ANY floatObj <= %@", @3.3f);
    RLMAssertCount(AllPrimitiveArrays, 2, @"ANY doubleObj <= %@", @3.3);
    RLMAssertCount(AllPrimitiveArrays, 2, @"ANY dateObj <= %@", date(2));
    RLMAssertCount(AllPrimitiveArrays, 2, @"ANY decimalObj <= %@", decimal128(3));
    RLMAssertCount(AllPrimitiveArrays, 2, @"ANY anyIntObj <= %@", @3);
    RLMAssertCount(AllPrimitiveArrays, 2, @"ANY anyFloatObj <= %@", @3.3f);
    RLMAssertCount(AllPrimitiveArrays, 2, @"ANY anyDoubleObj <= %@", @3.3);
    RLMAssertCount(AllPrimitiveArrays, 2, @"ANY anyDateObj <= %@", date(2));
    RLMAssertCount(AllPrimitiveArrays, 2, @"ANY anyDecimalObj <= %@", decimal128(3));
    RLMAssertCount(AllOptionalPrimitiveArrays, 2, @"ANY intObj <= %@", @3);
    RLMAssertCount(AllOptionalPrimitiveArrays, 2, @"ANY floatObj <= %@", @3.3f);
    RLMAssertCount(AllOptionalPrimitiveArrays, 2, @"ANY doubleObj <= %@", @3.3);
    RLMAssertCount(AllOptionalPrimitiveArrays, 2, @"ANY dateObj <= %@", date(2));
    RLMAssertCount(AllOptionalPrimitiveArrays, 2, @"ANY decimalObj <= %@", decimal128(3));

    RLMAssertThrowsWithReason(([AllPrimitiveArrays objectsInRealm:realm where:@"ANY boolObj > %@", @NO]),
                              @"Operator '>' not supported for type 'bool'");
    RLMAssertThrowsWithReason(([AllPrimitiveArrays objectsInRealm:realm where:@"ANY stringObj > %@", @"a"]),
                              @"Operator '>' not supported for type 'string'");
    RLMAssertThrowsWithReason(([AllPrimitiveArrays objectsInRealm:realm where:@"ANY dataObj > %@", data(1)]),
                              @"Operator '>' not supported for type 'data'");
    RLMAssertThrowsWithReason(([AllPrimitiveArrays objectsInRealm:realm where:@"ANY objectIdObj > %@", objectId(1)]),
                              @"Operator '>' not supported for type 'object id'");
    RLMAssertThrowsWithReason(([AllPrimitiveArrays objectsInRealm:realm where:@"ANY uuidObj > %@", uuid(@"00000000-0000-0000-0000-000000000000")]),
                              @"Operator '>' not supported for type 'uuid'");
    RLMAssertThrowsWithReason(([AllOptionalPrimitiveArrays objectsInRealm:realm where:@"ANY boolObj > %@", @NO]),
                              @"Operator '>' not supported for type 'bool'");
    RLMAssertThrowsWithReason(([AllOptionalPrimitiveArrays objectsInRealm:realm where:@"ANY stringObj > %@", @"a"]),
                              @"Operator '>' not supported for type 'string'");
    RLMAssertThrowsWithReason(([AllOptionalPrimitiveArrays objectsInRealm:realm where:@"ANY dataObj > %@", data(1)]),
                              @"Operator '>' not supported for type 'data'");
    RLMAssertThrowsWithReason(([AllOptionalPrimitiveArrays objectsInRealm:realm where:@"ANY objectIdObj > %@", objectId(1)]),
                              @"Operator '>' not supported for type 'object id'");
    RLMAssertThrowsWithReason(([AllOptionalPrimitiveArrays objectsInRealm:realm where:@"ANY uuidObj > %@", uuid(@"00000000-0000-0000-0000-000000000000")]),
                              @"Operator '>' not supported for type 'uuid'");
}

- (void)testQueryBetween {
    [realm deleteAllObjects];

    RLMAssertThrowsWithReason(([AllPrimitiveArrays objectsInRealm:realm where:@"ANY boolObj BETWEEN %@", @[@NO, @YES]]),
                              @"Operator 'BETWEEN' not supported for type 'bool'");
    RLMAssertThrowsWithReason(([AllPrimitiveArrays objectsInRealm:realm where:@"ANY stringObj BETWEEN %@", @[@"a", @"b"]]),
                              @"Operator 'BETWEEN' not supported for type 'string'");
    RLMAssertThrowsWithReason(([AllPrimitiveArrays objectsInRealm:realm where:@"ANY dataObj BETWEEN %@", @[data(1), data(2)]]),
                              @"Operator 'BETWEEN' not supported for type 'data'");
    RLMAssertThrowsWithReason(([AllPrimitiveArrays objectsInRealm:realm where:@"ANY objectIdObj BETWEEN %@", @[objectId(1), objectId(2)]]),
                              @"Operator 'BETWEEN' not supported for type 'object id'");
    RLMAssertThrowsWithReason(([AllPrimitiveArrays objectsInRealm:realm where:@"ANY uuidObj BETWEEN %@", @[uuid(@"00000000-0000-0000-0000-000000000000"), uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")]]),
                              @"Operator 'BETWEEN' not supported for type 'uuid'");
    RLMAssertThrowsWithReason(([AllOptionalPrimitiveArrays objectsInRealm:realm where:@"ANY boolObj BETWEEN %@", @[@NO, @YES]]),
                              @"Operator 'BETWEEN' not supported for type 'bool'");
    RLMAssertThrowsWithReason(([AllOptionalPrimitiveArrays objectsInRealm:realm where:@"ANY stringObj BETWEEN %@", @[@"a", @"b"]]),
                              @"Operator 'BETWEEN' not supported for type 'string'");
    RLMAssertThrowsWithReason(([AllOptionalPrimitiveArrays objectsInRealm:realm where:@"ANY dataObj BETWEEN %@", @[data(1), data(2)]]),
                              @"Operator 'BETWEEN' not supported for type 'data'");
    RLMAssertThrowsWithReason(([AllOptionalPrimitiveArrays objectsInRealm:realm where:@"ANY objectIdObj BETWEEN %@", @[objectId(1), objectId(2)]]),
                              @"Operator 'BETWEEN' not supported for type 'object id'");
    RLMAssertThrowsWithReason(([AllOptionalPrimitiveArrays objectsInRealm:realm where:@"ANY uuidObj BETWEEN %@", @[uuid(@"00000000-0000-0000-0000-000000000000"), uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")]]),
                              @"Operator 'BETWEEN' not supported for type 'uuid'");

    RLMAssertCount(AllPrimitiveArrays, 0, @"ANY intObj BETWEEN %@", @[@2, @3]);
    RLMAssertCount(AllPrimitiveArrays, 0, @"ANY floatObj BETWEEN %@", @[@2.2f, @3.3f]);
    RLMAssertCount(AllPrimitiveArrays, 0, @"ANY doubleObj BETWEEN %@", @[@2.2, @3.3]);
    RLMAssertCount(AllPrimitiveArrays, 0, @"ANY dateObj BETWEEN %@", @[date(1), date(2)]);
    RLMAssertCount(AllPrimitiveArrays, 0, @"ANY decimalObj BETWEEN %@", @[decimal128(2), decimal128(3)]);
    RLMAssertCount(AllPrimitiveArrays, 0, @"ANY anyIntObj BETWEEN %@", @[@2, @3]);
    RLMAssertCount(AllPrimitiveArrays, 0, @"ANY anyFloatObj BETWEEN %@", @[@2.2f, @3.3f]);
    RLMAssertCount(AllPrimitiveArrays, 0, @"ANY anyDoubleObj BETWEEN %@", @[@2.2, @3.3]);
    RLMAssertCount(AllPrimitiveArrays, 0, @"ANY anyDateObj BETWEEN %@", @[date(1), date(2)]);
    RLMAssertCount(AllPrimitiveArrays, 0, @"ANY anyDecimalObj BETWEEN %@", @[decimal128(2), decimal128(3)]);
    RLMAssertCount(AllOptionalPrimitiveArrays, 0, @"ANY intObj BETWEEN %@", @[@2, @3]);
    RLMAssertCount(AllOptionalPrimitiveArrays, 0, @"ANY floatObj BETWEEN %@", @[@2.2f, @3.3f]);
    RLMAssertCount(AllOptionalPrimitiveArrays, 0, @"ANY doubleObj BETWEEN %@", @[@2.2, @3.3]);
    RLMAssertCount(AllOptionalPrimitiveArrays, 0, @"ANY dateObj BETWEEN %@", @[date(1), date(2)]);
    RLMAssertCount(AllOptionalPrimitiveArrays, 0, @"ANY decimalObj BETWEEN %@", @[decimal128(2), decimal128(3)]);

    [self createObjectWithValueIndex:0];

    RLMAssertCount(AllPrimitiveArrays, 1, @"ANY intObj BETWEEN %@", @[@2, @2]);
    RLMAssertCount(AllPrimitiveArrays, 1, @"ANY floatObj BETWEEN %@", @[@2.2f, @2.2f]);
    RLMAssertCount(AllPrimitiveArrays, 1, @"ANY doubleObj BETWEEN %@", @[@2.2, @2.2]);
    RLMAssertCount(AllPrimitiveArrays, 1, @"ANY dateObj BETWEEN %@", @[date(1), date(1)]);
    RLMAssertCount(AllPrimitiveArrays, 1, @"ANY decimalObj BETWEEN %@", @[decimal128(2), decimal128(2)]);
    RLMAssertCount(AllPrimitiveArrays, 1, @"ANY anyIntObj BETWEEN %@", @[@2, @2]);
    RLMAssertCount(AllPrimitiveArrays, 1, @"ANY anyFloatObj BETWEEN %@", @[@2.2f, @2.2f]);
    RLMAssertCount(AllPrimitiveArrays, 1, @"ANY anyDoubleObj BETWEEN %@", @[@2.2, @2.2]);
    RLMAssertCount(AllPrimitiveArrays, 1, @"ANY anyDateObj BETWEEN %@", @[date(1), date(1)]);
    RLMAssertCount(AllPrimitiveArrays, 1, @"ANY anyDecimalObj BETWEEN %@", @[decimal128(2), decimal128(2)]);
    RLMAssertCount(AllOptionalPrimitiveArrays, 1, @"ANY intObj BETWEEN %@", @[@2, @2]);
    RLMAssertCount(AllOptionalPrimitiveArrays, 1, @"ANY floatObj BETWEEN %@", @[@2.2f, @2.2f]);
    RLMAssertCount(AllOptionalPrimitiveArrays, 1, @"ANY doubleObj BETWEEN %@", @[@2.2, @2.2]);
    RLMAssertCount(AllOptionalPrimitiveArrays, 1, @"ANY dateObj BETWEEN %@", @[date(1), date(1)]);
    RLMAssertCount(AllOptionalPrimitiveArrays, 1, @"ANY decimalObj BETWEEN %@", @[decimal128(2), decimal128(2)]);
    RLMAssertCount(AllPrimitiveArrays, 1, @"ANY intObj BETWEEN %@", @[@2, @3]);
    RLMAssertCount(AllPrimitiveArrays, 1, @"ANY floatObj BETWEEN %@", @[@2.2f, @3.3f]);
    RLMAssertCount(AllPrimitiveArrays, 1, @"ANY doubleObj BETWEEN %@", @[@2.2, @3.3]);
    RLMAssertCount(AllPrimitiveArrays, 1, @"ANY dateObj BETWEEN %@", @[date(1), date(2)]);
    RLMAssertCount(AllPrimitiveArrays, 1, @"ANY decimalObj BETWEEN %@", @[decimal128(2), decimal128(3)]);
    RLMAssertCount(AllPrimitiveArrays, 1, @"ANY anyIntObj BETWEEN %@", @[@2, @3]);
    RLMAssertCount(AllPrimitiveArrays, 1, @"ANY anyFloatObj BETWEEN %@", @[@2.2f, @3.3f]);
    RLMAssertCount(AllPrimitiveArrays, 1, @"ANY anyDoubleObj BETWEEN %@", @[@2.2, @3.3]);
    RLMAssertCount(AllPrimitiveArrays, 1, @"ANY anyDateObj BETWEEN %@", @[date(1), date(2)]);
    RLMAssertCount(AllPrimitiveArrays, 1, @"ANY anyDecimalObj BETWEEN %@", @[decimal128(2), decimal128(3)]);
    RLMAssertCount(AllOptionalPrimitiveArrays, 1, @"ANY intObj BETWEEN %@", @[@2, @3]);
    RLMAssertCount(AllOptionalPrimitiveArrays, 1, @"ANY floatObj BETWEEN %@", @[@2.2f, @3.3f]);
    RLMAssertCount(AllOptionalPrimitiveArrays, 1, @"ANY doubleObj BETWEEN %@", @[@2.2, @3.3]);
    RLMAssertCount(AllOptionalPrimitiveArrays, 1, @"ANY dateObj BETWEEN %@", @[date(1), date(2)]);
    RLMAssertCount(AllOptionalPrimitiveArrays, 1, @"ANY decimalObj BETWEEN %@", @[decimal128(2), decimal128(3)]);
    RLMAssertCount(AllPrimitiveArrays, 0, @"ANY intObj BETWEEN %@", @[@3, @3]);
    RLMAssertCount(AllPrimitiveArrays, 0, @"ANY floatObj BETWEEN %@", @[@3.3f, @3.3f]);
    RLMAssertCount(AllPrimitiveArrays, 0, @"ANY doubleObj BETWEEN %@", @[@3.3, @3.3]);
    RLMAssertCount(AllPrimitiveArrays, 0, @"ANY dateObj BETWEEN %@", @[date(2), date(2)]);
    RLMAssertCount(AllPrimitiveArrays, 0, @"ANY decimalObj BETWEEN %@", @[decimal128(3), decimal128(3)]);
    RLMAssertCount(AllPrimitiveArrays, 0, @"ANY anyIntObj BETWEEN %@", @[@3, @3]);
    RLMAssertCount(AllPrimitiveArrays, 0, @"ANY anyFloatObj BETWEEN %@", @[@3.3f, @3.3f]);
    RLMAssertCount(AllPrimitiveArrays, 0, @"ANY anyDoubleObj BETWEEN %@", @[@3.3, @3.3]);
    RLMAssertCount(AllPrimitiveArrays, 0, @"ANY anyDateObj BETWEEN %@", @[date(2), date(2)]);
    RLMAssertCount(AllPrimitiveArrays, 0, @"ANY anyDecimalObj BETWEEN %@", @[decimal128(3), decimal128(3)]);
    RLMAssertCount(AllOptionalPrimitiveArrays, 0, @"ANY intObj BETWEEN %@", @[@3, @3]);
    RLMAssertCount(AllOptionalPrimitiveArrays, 0, @"ANY floatObj BETWEEN %@", @[@3.3f, @3.3f]);
    RLMAssertCount(AllOptionalPrimitiveArrays, 0, @"ANY doubleObj BETWEEN %@", @[@3.3, @3.3]);
    RLMAssertCount(AllOptionalPrimitiveArrays, 0, @"ANY dateObj BETWEEN %@", @[date(2), date(2)]);
    RLMAssertCount(AllOptionalPrimitiveArrays, 0, @"ANY decimalObj BETWEEN %@", @[decimal128(3), decimal128(3)]);
}

- (void)testQueryIn {
    [realm deleteAllObjects];

    RLMAssertCount(AllPrimitiveArrays, 0, @"ANY boolObj IN %@", @[@NO, @YES]);
    RLMAssertCount(AllPrimitiveArrays, 0, @"ANY intObj IN %@", @[@2, @3]);
    RLMAssertCount(AllPrimitiveArrays, 0, @"ANY floatObj IN %@", @[@2.2f, @3.3f]);
    RLMAssertCount(AllPrimitiveArrays, 0, @"ANY doubleObj IN %@", @[@2.2, @3.3]);
    RLMAssertCount(AllPrimitiveArrays, 0, @"ANY stringObj IN %@", @[@"a", @"b"]);
    RLMAssertCount(AllPrimitiveArrays, 0, @"ANY dataObj IN %@", @[data(1), data(2)]);
    RLMAssertCount(AllPrimitiveArrays, 0, @"ANY dateObj IN %@", @[date(1), date(2)]);
    RLMAssertCount(AllPrimitiveArrays, 0, @"ANY decimalObj IN %@", @[decimal128(2), decimal128(3)]);
    RLMAssertCount(AllPrimitiveArrays, 0, @"ANY objectIdObj IN %@", @[objectId(1), objectId(2)]);
    RLMAssertCount(AllPrimitiveArrays, 0, @"ANY uuidObj IN %@", @[uuid(@"00000000-0000-0000-0000-000000000000"), uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")]);
    RLMAssertCount(AllPrimitiveArrays, 0, @"ANY anyBoolObj IN %@", @[@NO, @YES]);
    RLMAssertCount(AllPrimitiveArrays, 0, @"ANY anyIntObj IN %@", @[@2, @3]);
    RLMAssertCount(AllPrimitiveArrays, 0, @"ANY anyFloatObj IN %@", @[@2.2f, @3.3f]);
    RLMAssertCount(AllPrimitiveArrays, 0, @"ANY anyDoubleObj IN %@", @[@2.2, @3.3]);
    RLMAssertCount(AllPrimitiveArrays, 0, @"ANY anyStringObj IN %@", @[@"a", @"b"]);
    RLMAssertCount(AllPrimitiveArrays, 0, @"ANY anyDataObj IN %@", @[data(1), data(2)]);
    RLMAssertCount(AllPrimitiveArrays, 0, @"ANY anyDateObj IN %@", @[date(1), date(2)]);
    RLMAssertCount(AllPrimitiveArrays, 0, @"ANY anyDecimalObj IN %@", @[decimal128(2), decimal128(3)]);
    RLMAssertCount(AllPrimitiveArrays, 0, @"ANY anyObjectIdObj IN %@", @[objectId(1), objectId(2)]);
    RLMAssertCount(AllPrimitiveArrays, 0, @"ANY anyUUIDObj IN %@", @[uuid(@"00000000-0000-0000-0000-000000000000"), uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")]);
    RLMAssertCount(AllOptionalPrimitiveArrays, 0, @"ANY boolObj IN %@", @[@NO, @YES]);
    RLMAssertCount(AllOptionalPrimitiveArrays, 0, @"ANY intObj IN %@", @[@2, @3]);
    RLMAssertCount(AllOptionalPrimitiveArrays, 0, @"ANY floatObj IN %@", @[@2.2f, @3.3f]);
    RLMAssertCount(AllOptionalPrimitiveArrays, 0, @"ANY doubleObj IN %@", @[@2.2, @3.3]);
    RLMAssertCount(AllOptionalPrimitiveArrays, 0, @"ANY stringObj IN %@", @[@"a", @"b"]);
    RLMAssertCount(AllOptionalPrimitiveArrays, 0, @"ANY dataObj IN %@", @[data(1), data(2)]);
    RLMAssertCount(AllOptionalPrimitiveArrays, 0, @"ANY dateObj IN %@", @[date(1), date(2)]);
    RLMAssertCount(AllOptionalPrimitiveArrays, 0, @"ANY decimalObj IN %@", @[decimal128(2), decimal128(3)]);
    RLMAssertCount(AllOptionalPrimitiveArrays, 0, @"ANY objectIdObj IN %@", @[objectId(1), objectId(2)]);
    RLMAssertCount(AllOptionalPrimitiveArrays, 0, @"ANY uuidObj IN %@", @[uuid(@"00000000-0000-0000-0000-000000000000"), uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")]);

    [self createObjectWithValueIndex:0];

    RLMAssertCount(AllPrimitiveArrays, 0, @"ANY boolObj IN %@", @[@YES]);
    RLMAssertCount(AllPrimitiveArrays, 0, @"ANY intObj IN %@", @[@3]);
    RLMAssertCount(AllPrimitiveArrays, 0, @"ANY floatObj IN %@", @[@3.3f]);
    RLMAssertCount(AllPrimitiveArrays, 0, @"ANY doubleObj IN %@", @[@3.3]);
    RLMAssertCount(AllPrimitiveArrays, 0, @"ANY stringObj IN %@", @[@"b"]);
    RLMAssertCount(AllPrimitiveArrays, 0, @"ANY dataObj IN %@", @[data(2)]);
    RLMAssertCount(AllPrimitiveArrays, 0, @"ANY dateObj IN %@", @[date(2)]);
    RLMAssertCount(AllPrimitiveArrays, 0, @"ANY decimalObj IN %@", @[decimal128(3)]);
    RLMAssertCount(AllPrimitiveArrays, 0, @"ANY objectIdObj IN %@", @[objectId(2)]);
    RLMAssertCount(AllPrimitiveArrays, 0, @"ANY uuidObj IN %@", @[uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")]);
    RLMAssertCount(AllPrimitiveArrays, 0, @"ANY anyBoolObj IN %@", @[@YES]);
    RLMAssertCount(AllPrimitiveArrays, 0, @"ANY anyIntObj IN %@", @[@3]);
    RLMAssertCount(AllPrimitiveArrays, 0, @"ANY anyFloatObj IN %@", @[@3.3f]);
    RLMAssertCount(AllPrimitiveArrays, 0, @"ANY anyDoubleObj IN %@", @[@3.3]);
    RLMAssertCount(AllPrimitiveArrays, 0, @"ANY anyStringObj IN %@", @[@"b"]);
    RLMAssertCount(AllPrimitiveArrays, 0, @"ANY anyDataObj IN %@", @[data(2)]);
    RLMAssertCount(AllPrimitiveArrays, 0, @"ANY anyDateObj IN %@", @[date(2)]);
    RLMAssertCount(AllPrimitiveArrays, 0, @"ANY anyDecimalObj IN %@", @[decimal128(3)]);
    RLMAssertCount(AllPrimitiveArrays, 0, @"ANY anyObjectIdObj IN %@", @[objectId(2)]);
    RLMAssertCount(AllPrimitiveArrays, 0, @"ANY anyUUIDObj IN %@", @[uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")]);
    RLMAssertCount(AllOptionalPrimitiveArrays, 0, @"ANY boolObj IN %@", @[@YES]);
    RLMAssertCount(AllOptionalPrimitiveArrays, 0, @"ANY intObj IN %@", @[@3]);
    RLMAssertCount(AllOptionalPrimitiveArrays, 0, @"ANY floatObj IN %@", @[@3.3f]);
    RLMAssertCount(AllOptionalPrimitiveArrays, 0, @"ANY doubleObj IN %@", @[@3.3]);
    RLMAssertCount(AllOptionalPrimitiveArrays, 0, @"ANY stringObj IN %@", @[@"b"]);
    RLMAssertCount(AllOptionalPrimitiveArrays, 0, @"ANY dataObj IN %@", @[data(2)]);
    RLMAssertCount(AllOptionalPrimitiveArrays, 0, @"ANY dateObj IN %@", @[date(2)]);
    RLMAssertCount(AllOptionalPrimitiveArrays, 0, @"ANY decimalObj IN %@", @[decimal128(3)]);
    RLMAssertCount(AllOptionalPrimitiveArrays, 0, @"ANY objectIdObj IN %@", @[objectId(2)]);
    RLMAssertCount(AllOptionalPrimitiveArrays, 0, @"ANY uuidObj IN %@", @[uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")]);
    RLMAssertCount(AllPrimitiveArrays, 1, @"ANY boolObj IN %@", @[@NO, @YES]);
    RLMAssertCount(AllPrimitiveArrays, 1, @"ANY intObj IN %@", @[@2, @3]);
    RLMAssertCount(AllPrimitiveArrays, 1, @"ANY floatObj IN %@", @[@2.2f, @3.3f]);
    RLMAssertCount(AllPrimitiveArrays, 1, @"ANY doubleObj IN %@", @[@2.2, @3.3]);
    RLMAssertCount(AllPrimitiveArrays, 1, @"ANY stringObj IN %@", @[@"a", @"b"]);
    RLMAssertCount(AllPrimitiveArrays, 1, @"ANY dataObj IN %@", @[data(1), data(2)]);
    RLMAssertCount(AllPrimitiveArrays, 1, @"ANY dateObj IN %@", @[date(1), date(2)]);
    RLMAssertCount(AllPrimitiveArrays, 1, @"ANY decimalObj IN %@", @[decimal128(2), decimal128(3)]);
    RLMAssertCount(AllPrimitiveArrays, 1, @"ANY objectIdObj IN %@", @[objectId(1), objectId(2)]);
    RLMAssertCount(AllPrimitiveArrays, 1, @"ANY uuidObj IN %@", @[uuid(@"00000000-0000-0000-0000-000000000000"), uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")]);
    RLMAssertCount(AllPrimitiveArrays, 1, @"ANY anyBoolObj IN %@", @[@NO, @YES]);
    RLMAssertCount(AllPrimitiveArrays, 1, @"ANY anyIntObj IN %@", @[@2, @3]);
    RLMAssertCount(AllPrimitiveArrays, 1, @"ANY anyFloatObj IN %@", @[@2.2f, @3.3f]);
    RLMAssertCount(AllPrimitiveArrays, 1, @"ANY anyDoubleObj IN %@", @[@2.2, @3.3]);
    RLMAssertCount(AllPrimitiveArrays, 1, @"ANY anyStringObj IN %@", @[@"a", @"b"]);
    RLMAssertCount(AllPrimitiveArrays, 1, @"ANY anyDataObj IN %@", @[data(1), data(2)]);
    RLMAssertCount(AllPrimitiveArrays, 1, @"ANY anyDateObj IN %@", @[date(1), date(2)]);
    RLMAssertCount(AllPrimitiveArrays, 1, @"ANY anyDecimalObj IN %@", @[decimal128(2), decimal128(3)]);
    RLMAssertCount(AllPrimitiveArrays, 1, @"ANY anyObjectIdObj IN %@", @[objectId(1), objectId(2)]);
    RLMAssertCount(AllPrimitiveArrays, 1, @"ANY anyUUIDObj IN %@", @[uuid(@"00000000-0000-0000-0000-000000000000"), uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")]);
    RLMAssertCount(AllOptionalPrimitiveArrays, 1, @"ANY boolObj IN %@", @[@NO, @YES]);
    RLMAssertCount(AllOptionalPrimitiveArrays, 1, @"ANY intObj IN %@", @[@2, @3]);
    RLMAssertCount(AllOptionalPrimitiveArrays, 1, @"ANY floatObj IN %@", @[@2.2f, @3.3f]);
    RLMAssertCount(AllOptionalPrimitiveArrays, 1, @"ANY doubleObj IN %@", @[@2.2, @3.3]);
    RLMAssertCount(AllOptionalPrimitiveArrays, 1, @"ANY stringObj IN %@", @[@"a", @"b"]);
    RLMAssertCount(AllOptionalPrimitiveArrays, 1, @"ANY dataObj IN %@", @[data(1), data(2)]);
    RLMAssertCount(AllOptionalPrimitiveArrays, 1, @"ANY dateObj IN %@", @[date(1), date(2)]);
    RLMAssertCount(AllOptionalPrimitiveArrays, 1, @"ANY decimalObj IN %@", @[decimal128(2), decimal128(3)]);
    RLMAssertCount(AllOptionalPrimitiveArrays, 1, @"ANY objectIdObj IN %@", @[objectId(1), objectId(2)]);
    RLMAssertCount(AllOptionalPrimitiveArrays, 1, @"ANY uuidObj IN %@", @[uuid(@"00000000-0000-0000-0000-000000000000"), uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")]);
}

- (void)testQueryCount {
    [realm deleteAllObjects];

    [AllPrimitiveArrays createInRealm:realm withValue:@{
        @"boolObj": @[],
        @"intObj": @[],
        @"floatObj": @[],
        @"doubleObj": @[],
        @"stringObj": @[],
        @"dataObj": @[],
        @"dateObj": @[],
        @"decimalObj": @[],
        @"objectIdObj": @[],
        @"uuidObj": @[],
        @"anyBoolObj": @[],
        @"anyIntObj": @[],
        @"anyFloatObj": @[],
        @"anyDoubleObj": @[],
        @"anyStringObj": @[],
        @"anyDataObj": @[],
        @"anyDateObj": @[],
        @"anyDecimalObj": @[],
        @"anyObjectIdObj": @[],
        @"anyUUIDObj": @[],
    }];
    [AllOptionalPrimitiveArrays createInRealm:realm withValue:@{
        @"boolObj": @[],
        @"intObj": @[],
        @"floatObj": @[],
        @"doubleObj": @[],
        @"stringObj": @[],
        @"dataObj": @[],
        @"dateObj": @[],
        @"decimalObj": @[],
        @"objectIdObj": @[],
        @"uuidObj": @[],
    }];
    [AllPrimitiveArrays createInRealm:realm withValue:@{
        @"boolObj": @[@NO],
        @"intObj": @[@2],
        @"floatObj": @[@2.2f],
        @"doubleObj": @[@2.2],
        @"stringObj": @[@"a"],
        @"dataObj": @[data(1)],
        @"dateObj": @[date(1)],
        @"decimalObj": @[decimal128(2)],
        @"objectIdObj": @[objectId(1)],
        @"uuidObj": @[uuid(@"00000000-0000-0000-0000-000000000000")],
        @"anyBoolObj": @[@NO],
        @"anyIntObj": @[@2],
        @"anyFloatObj": @[@2.2f],
        @"anyDoubleObj": @[@2.2],
        @"anyStringObj": @[@"a"],
        @"anyDataObj": @[data(1)],
        @"anyDateObj": @[date(1)],
        @"anyDecimalObj": @[decimal128(2)],
        @"anyObjectIdObj": @[objectId(1)],
        @"anyUUIDObj": @[uuid(@"00000000-0000-0000-0000-000000000000")],
    }];
    [AllOptionalPrimitiveArrays createInRealm:realm withValue:@{
        @"boolObj": @[@NO],
        @"intObj": @[@2],
        @"floatObj": @[@2.2f],
        @"doubleObj": @[@2.2],
        @"stringObj": @[@"a"],
        @"dataObj": @[data(1)],
        @"dateObj": @[date(1)],
        @"decimalObj": @[decimal128(2)],
        @"objectIdObj": @[objectId(1)],
        @"uuidObj": @[uuid(@"00000000-0000-0000-0000-000000000000")],
    }];
    [AllPrimitiveArrays createInRealm:realm withValue:@{
        @"boolObj": @[@NO, @NO],
        @"intObj": @[@2, @2],
        @"floatObj": @[@2.2f, @2.2f],
        @"doubleObj": @[@2.2, @2.2],
        @"stringObj": @[@"a", @"a"],
        @"dataObj": @[data(1), data(1)],
        @"dateObj": @[date(1), date(1)],
        @"decimalObj": @[decimal128(2), decimal128(2)],
        @"objectIdObj": @[objectId(1), objectId(1)],
        @"uuidObj": @[uuid(@"00000000-0000-0000-0000-000000000000"), uuid(@"00000000-0000-0000-0000-000000000000")],
        @"anyBoolObj": @[@NO, @NO],
        @"anyIntObj": @[@2, @2],
        @"anyFloatObj": @[@2.2f, @2.2f],
        @"anyDoubleObj": @[@2.2, @2.2],
        @"anyStringObj": @[@"a", @"a"],
        @"anyDataObj": @[data(1), data(1)],
        @"anyDateObj": @[date(1), date(1)],
        @"anyDecimalObj": @[decimal128(2), decimal128(2)],
        @"anyObjectIdObj": @[objectId(1), objectId(1)],
        @"anyUUIDObj": @[uuid(@"00000000-0000-0000-0000-000000000000"), uuid(@"00000000-0000-0000-0000-000000000000")],
    }];
    [AllOptionalPrimitiveArrays createInRealm:realm withValue:@{
        @"boolObj": @[@NO, @NO],
        @"intObj": @[@2, @2],
        @"floatObj": @[@2.2f, @2.2f],
        @"doubleObj": @[@2.2, @2.2],
        @"stringObj": @[@"a", @"a"],
        @"dataObj": @[data(1), data(1)],
        @"dateObj": @[date(1), date(1)],
        @"decimalObj": @[decimal128(2), decimal128(2)],
        @"objectIdObj": @[objectId(1), objectId(1)],
        @"uuidObj": @[uuid(@"00000000-0000-0000-0000-000000000000"), uuid(@"00000000-0000-0000-0000-000000000000")],
    }];

    for (unsigned int i = 0; i < 3; ++i) {
        RLMAssertCount(AllPrimitiveArrays, 1U, @"boolObj.@count == %@", @(i));
        RLMAssertCount(AllPrimitiveArrays, 1U, @"intObj.@count == %@", @(i));
        RLMAssertCount(AllPrimitiveArrays, 1U, @"floatObj.@count == %@", @(i));
        RLMAssertCount(AllPrimitiveArrays, 1U, @"doubleObj.@count == %@", @(i));
        RLMAssertCount(AllPrimitiveArrays, 1U, @"stringObj.@count == %@", @(i));
        RLMAssertCount(AllPrimitiveArrays, 1U, @"dataObj.@count == %@", @(i));
        RLMAssertCount(AllPrimitiveArrays, 1U, @"dateObj.@count == %@", @(i));
        RLMAssertCount(AllPrimitiveArrays, 1U, @"decimalObj.@count == %@", @(i));
        RLMAssertCount(AllPrimitiveArrays, 1U, @"objectIdObj.@count == %@", @(i));
        RLMAssertCount(AllPrimitiveArrays, 1U, @"uuidObj.@count == %@", @(i));
        RLMAssertCount(AllPrimitiveArrays, 1U, @"anyBoolObj.@count == %@", @(i));
        RLMAssertCount(AllPrimitiveArrays, 1U, @"anyIntObj.@count == %@", @(i));
        RLMAssertCount(AllPrimitiveArrays, 1U, @"anyFloatObj.@count == %@", @(i));
        RLMAssertCount(AllPrimitiveArrays, 1U, @"anyDoubleObj.@count == %@", @(i));
        RLMAssertCount(AllPrimitiveArrays, 1U, @"anyStringObj.@count == %@", @(i));
        RLMAssertCount(AllPrimitiveArrays, 1U, @"anyDataObj.@count == %@", @(i));
        RLMAssertCount(AllPrimitiveArrays, 1U, @"anyDateObj.@count == %@", @(i));
        RLMAssertCount(AllPrimitiveArrays, 1U, @"anyDecimalObj.@count == %@", @(i));
        RLMAssertCount(AllPrimitiveArrays, 1U, @"anyObjectIdObj.@count == %@", @(i));
        RLMAssertCount(AllPrimitiveArrays, 1U, @"anyUUIDObj.@count == %@", @(i));
        RLMAssertCount(AllOptionalPrimitiveArrays, 1U, @"boolObj.@count == %@", @(i));
        RLMAssertCount(AllOptionalPrimitiveArrays, 1U, @"intObj.@count == %@", @(i));
        RLMAssertCount(AllOptionalPrimitiveArrays, 1U, @"floatObj.@count == %@", @(i));
        RLMAssertCount(AllOptionalPrimitiveArrays, 1U, @"doubleObj.@count == %@", @(i));
        RLMAssertCount(AllOptionalPrimitiveArrays, 1U, @"stringObj.@count == %@", @(i));
        RLMAssertCount(AllOptionalPrimitiveArrays, 1U, @"dataObj.@count == %@", @(i));
        RLMAssertCount(AllOptionalPrimitiveArrays, 1U, @"dateObj.@count == %@", @(i));
        RLMAssertCount(AllOptionalPrimitiveArrays, 1U, @"decimalObj.@count == %@", @(i));
        RLMAssertCount(AllOptionalPrimitiveArrays, 1U, @"objectIdObj.@count == %@", @(i));
        RLMAssertCount(AllOptionalPrimitiveArrays, 1U, @"uuidObj.@count == %@", @(i));
        RLMAssertCount(AllPrimitiveArrays, 2U, @"boolObj.@count != %@", @(i));
        RLMAssertCount(AllPrimitiveArrays, 2U, @"intObj.@count != %@", @(i));
        RLMAssertCount(AllPrimitiveArrays, 2U, @"floatObj.@count != %@", @(i));
        RLMAssertCount(AllPrimitiveArrays, 2U, @"doubleObj.@count != %@", @(i));
        RLMAssertCount(AllPrimitiveArrays, 2U, @"stringObj.@count != %@", @(i));
        RLMAssertCount(AllPrimitiveArrays, 2U, @"dataObj.@count != %@", @(i));
        RLMAssertCount(AllPrimitiveArrays, 2U, @"dateObj.@count != %@", @(i));
        RLMAssertCount(AllPrimitiveArrays, 2U, @"decimalObj.@count != %@", @(i));
        RLMAssertCount(AllPrimitiveArrays, 2U, @"objectIdObj.@count != %@", @(i));
        RLMAssertCount(AllPrimitiveArrays, 2U, @"uuidObj.@count != %@", @(i));
        RLMAssertCount(AllPrimitiveArrays, 2U, @"anyBoolObj.@count != %@", @(i));
        RLMAssertCount(AllPrimitiveArrays, 2U, @"anyIntObj.@count != %@", @(i));
        RLMAssertCount(AllPrimitiveArrays, 2U, @"anyFloatObj.@count != %@", @(i));
        RLMAssertCount(AllPrimitiveArrays, 2U, @"anyDoubleObj.@count != %@", @(i));
        RLMAssertCount(AllPrimitiveArrays, 2U, @"anyStringObj.@count != %@", @(i));
        RLMAssertCount(AllPrimitiveArrays, 2U, @"anyDataObj.@count != %@", @(i));
        RLMAssertCount(AllPrimitiveArrays, 2U, @"anyDateObj.@count != %@", @(i));
        RLMAssertCount(AllPrimitiveArrays, 2U, @"anyDecimalObj.@count != %@", @(i));
        RLMAssertCount(AllPrimitiveArrays, 2U, @"anyObjectIdObj.@count != %@", @(i));
        RLMAssertCount(AllPrimitiveArrays, 2U, @"anyUUIDObj.@count != %@", @(i));
        RLMAssertCount(AllOptionalPrimitiveArrays, 2U, @"boolObj.@count != %@", @(i));
        RLMAssertCount(AllOptionalPrimitiveArrays, 2U, @"intObj.@count != %@", @(i));
        RLMAssertCount(AllOptionalPrimitiveArrays, 2U, @"floatObj.@count != %@", @(i));
        RLMAssertCount(AllOptionalPrimitiveArrays, 2U, @"doubleObj.@count != %@", @(i));
        RLMAssertCount(AllOptionalPrimitiveArrays, 2U, @"stringObj.@count != %@", @(i));
        RLMAssertCount(AllOptionalPrimitiveArrays, 2U, @"dataObj.@count != %@", @(i));
        RLMAssertCount(AllOptionalPrimitiveArrays, 2U, @"dateObj.@count != %@", @(i));
        RLMAssertCount(AllOptionalPrimitiveArrays, 2U, @"decimalObj.@count != %@", @(i));
        RLMAssertCount(AllOptionalPrimitiveArrays, 2U, @"objectIdObj.@count != %@", @(i));
        RLMAssertCount(AllOptionalPrimitiveArrays, 2U, @"uuidObj.@count != %@", @(i));
        RLMAssertCount(AllPrimitiveArrays, 2 - i, @"boolObj.@count > %@", @(i));
        RLMAssertCount(AllPrimitiveArrays, 2 - i, @"intObj.@count > %@", @(i));
        RLMAssertCount(AllPrimitiveArrays, 2 - i, @"floatObj.@count > %@", @(i));
        RLMAssertCount(AllPrimitiveArrays, 2 - i, @"doubleObj.@count > %@", @(i));
        RLMAssertCount(AllPrimitiveArrays, 2 - i, @"stringObj.@count > %@", @(i));
        RLMAssertCount(AllPrimitiveArrays, 2 - i, @"dataObj.@count > %@", @(i));
        RLMAssertCount(AllPrimitiveArrays, 2 - i, @"dateObj.@count > %@", @(i));
        RLMAssertCount(AllPrimitiveArrays, 2 - i, @"decimalObj.@count > %@", @(i));
        RLMAssertCount(AllPrimitiveArrays, 2 - i, @"objectIdObj.@count > %@", @(i));
        RLMAssertCount(AllPrimitiveArrays, 2 - i, @"uuidObj.@count > %@", @(i));
        RLMAssertCount(AllPrimitiveArrays, 2 - i, @"anyBoolObj.@count > %@", @(i));
        RLMAssertCount(AllPrimitiveArrays, 2 - i, @"anyIntObj.@count > %@", @(i));
        RLMAssertCount(AllPrimitiveArrays, 2 - i, @"anyFloatObj.@count > %@", @(i));
        RLMAssertCount(AllPrimitiveArrays, 2 - i, @"anyDoubleObj.@count > %@", @(i));
        RLMAssertCount(AllPrimitiveArrays, 2 - i, @"anyStringObj.@count > %@", @(i));
        RLMAssertCount(AllPrimitiveArrays, 2 - i, @"anyDataObj.@count > %@", @(i));
        RLMAssertCount(AllPrimitiveArrays, 2 - i, @"anyDateObj.@count > %@", @(i));
        RLMAssertCount(AllPrimitiveArrays, 2 - i, @"anyDecimalObj.@count > %@", @(i));
        RLMAssertCount(AllPrimitiveArrays, 2 - i, @"anyObjectIdObj.@count > %@", @(i));
        RLMAssertCount(AllPrimitiveArrays, 2 - i, @"anyUUIDObj.@count > %@", @(i));
        RLMAssertCount(AllOptionalPrimitiveArrays, 2 - i, @"boolObj.@count > %@", @(i));
        RLMAssertCount(AllOptionalPrimitiveArrays, 2 - i, @"intObj.@count > %@", @(i));
        RLMAssertCount(AllOptionalPrimitiveArrays, 2 - i, @"floatObj.@count > %@", @(i));
        RLMAssertCount(AllOptionalPrimitiveArrays, 2 - i, @"doubleObj.@count > %@", @(i));
        RLMAssertCount(AllOptionalPrimitiveArrays, 2 - i, @"stringObj.@count > %@", @(i));
        RLMAssertCount(AllOptionalPrimitiveArrays, 2 - i, @"dataObj.@count > %@", @(i));
        RLMAssertCount(AllOptionalPrimitiveArrays, 2 - i, @"dateObj.@count > %@", @(i));
        RLMAssertCount(AllOptionalPrimitiveArrays, 2 - i, @"decimalObj.@count > %@", @(i));
        RLMAssertCount(AllOptionalPrimitiveArrays, 2 - i, @"objectIdObj.@count > %@", @(i));
        RLMAssertCount(AllOptionalPrimitiveArrays, 2 - i, @"uuidObj.@count > %@", @(i));
        RLMAssertCount(AllPrimitiveArrays, 3 - i, @"boolObj.@count >= %@", @(i));
        RLMAssertCount(AllPrimitiveArrays, 3 - i, @"intObj.@count >= %@", @(i));
        RLMAssertCount(AllPrimitiveArrays, 3 - i, @"floatObj.@count >= %@", @(i));
        RLMAssertCount(AllPrimitiveArrays, 3 - i, @"doubleObj.@count >= %@", @(i));
        RLMAssertCount(AllPrimitiveArrays, 3 - i, @"stringObj.@count >= %@", @(i));
        RLMAssertCount(AllPrimitiveArrays, 3 - i, @"dataObj.@count >= %@", @(i));
        RLMAssertCount(AllPrimitiveArrays, 3 - i, @"dateObj.@count >= %@", @(i));
        RLMAssertCount(AllPrimitiveArrays, 3 - i, @"decimalObj.@count >= %@", @(i));
        RLMAssertCount(AllPrimitiveArrays, 3 - i, @"objectIdObj.@count >= %@", @(i));
        RLMAssertCount(AllPrimitiveArrays, 3 - i, @"uuidObj.@count >= %@", @(i));
        RLMAssertCount(AllPrimitiveArrays, 3 - i, @"anyBoolObj.@count >= %@", @(i));
        RLMAssertCount(AllPrimitiveArrays, 3 - i, @"anyIntObj.@count >= %@", @(i));
        RLMAssertCount(AllPrimitiveArrays, 3 - i, @"anyFloatObj.@count >= %@", @(i));
        RLMAssertCount(AllPrimitiveArrays, 3 - i, @"anyDoubleObj.@count >= %@", @(i));
        RLMAssertCount(AllPrimitiveArrays, 3 - i, @"anyStringObj.@count >= %@", @(i));
        RLMAssertCount(AllPrimitiveArrays, 3 - i, @"anyDataObj.@count >= %@", @(i));
        RLMAssertCount(AllPrimitiveArrays, 3 - i, @"anyDateObj.@count >= %@", @(i));
        RLMAssertCount(AllPrimitiveArrays, 3 - i, @"anyDecimalObj.@count >= %@", @(i));
        RLMAssertCount(AllPrimitiveArrays, 3 - i, @"anyObjectIdObj.@count >= %@", @(i));
        RLMAssertCount(AllPrimitiveArrays, 3 - i, @"anyUUIDObj.@count >= %@", @(i));
        RLMAssertCount(AllOptionalPrimitiveArrays, 3 - i, @"boolObj.@count >= %@", @(i));
        RLMAssertCount(AllOptionalPrimitiveArrays, 3 - i, @"intObj.@count >= %@", @(i));
        RLMAssertCount(AllOptionalPrimitiveArrays, 3 - i, @"floatObj.@count >= %@", @(i));
        RLMAssertCount(AllOptionalPrimitiveArrays, 3 - i, @"doubleObj.@count >= %@", @(i));
        RLMAssertCount(AllOptionalPrimitiveArrays, 3 - i, @"stringObj.@count >= %@", @(i));
        RLMAssertCount(AllOptionalPrimitiveArrays, 3 - i, @"dataObj.@count >= %@", @(i));
        RLMAssertCount(AllOptionalPrimitiveArrays, 3 - i, @"dateObj.@count >= %@", @(i));
        RLMAssertCount(AllOptionalPrimitiveArrays, 3 - i, @"decimalObj.@count >= %@", @(i));
        RLMAssertCount(AllOptionalPrimitiveArrays, 3 - i, @"objectIdObj.@count >= %@", @(i));
        RLMAssertCount(AllOptionalPrimitiveArrays, 3 - i, @"uuidObj.@count >= %@", @(i));
        RLMAssertCount(AllPrimitiveArrays, i, @"boolObj.@count < %@", @(i));
        RLMAssertCount(AllPrimitiveArrays, i, @"intObj.@count < %@", @(i));
        RLMAssertCount(AllPrimitiveArrays, i, @"floatObj.@count < %@", @(i));
        RLMAssertCount(AllPrimitiveArrays, i, @"doubleObj.@count < %@", @(i));
        RLMAssertCount(AllPrimitiveArrays, i, @"stringObj.@count < %@", @(i));
        RLMAssertCount(AllPrimitiveArrays, i, @"dataObj.@count < %@", @(i));
        RLMAssertCount(AllPrimitiveArrays, i, @"dateObj.@count < %@", @(i));
        RLMAssertCount(AllPrimitiveArrays, i, @"decimalObj.@count < %@", @(i));
        RLMAssertCount(AllPrimitiveArrays, i, @"objectIdObj.@count < %@", @(i));
        RLMAssertCount(AllPrimitiveArrays, i, @"uuidObj.@count < %@", @(i));
        RLMAssertCount(AllPrimitiveArrays, i, @"anyBoolObj.@count < %@", @(i));
        RLMAssertCount(AllPrimitiveArrays, i, @"anyIntObj.@count < %@", @(i));
        RLMAssertCount(AllPrimitiveArrays, i, @"anyFloatObj.@count < %@", @(i));
        RLMAssertCount(AllPrimitiveArrays, i, @"anyDoubleObj.@count < %@", @(i));
        RLMAssertCount(AllPrimitiveArrays, i, @"anyStringObj.@count < %@", @(i));
        RLMAssertCount(AllPrimitiveArrays, i, @"anyDataObj.@count < %@", @(i));
        RLMAssertCount(AllPrimitiveArrays, i, @"anyDateObj.@count < %@", @(i));
        RLMAssertCount(AllPrimitiveArrays, i, @"anyDecimalObj.@count < %@", @(i));
        RLMAssertCount(AllPrimitiveArrays, i, @"anyObjectIdObj.@count < %@", @(i));
        RLMAssertCount(AllPrimitiveArrays, i, @"anyUUIDObj.@count < %@", @(i));
        RLMAssertCount(AllOptionalPrimitiveArrays, i, @"boolObj.@count < %@", @(i));
        RLMAssertCount(AllOptionalPrimitiveArrays, i, @"intObj.@count < %@", @(i));
        RLMAssertCount(AllOptionalPrimitiveArrays, i, @"floatObj.@count < %@", @(i));
        RLMAssertCount(AllOptionalPrimitiveArrays, i, @"doubleObj.@count < %@", @(i));
        RLMAssertCount(AllOptionalPrimitiveArrays, i, @"stringObj.@count < %@", @(i));
        RLMAssertCount(AllOptionalPrimitiveArrays, i, @"dataObj.@count < %@", @(i));
        RLMAssertCount(AllOptionalPrimitiveArrays, i, @"dateObj.@count < %@", @(i));
        RLMAssertCount(AllOptionalPrimitiveArrays, i, @"decimalObj.@count < %@", @(i));
        RLMAssertCount(AllOptionalPrimitiveArrays, i, @"objectIdObj.@count < %@", @(i));
        RLMAssertCount(AllOptionalPrimitiveArrays, i, @"uuidObj.@count < %@", @(i));
        RLMAssertCount(AllPrimitiveArrays, i + 1, @"boolObj.@count <= %@", @(i));
        RLMAssertCount(AllPrimitiveArrays, i + 1, @"intObj.@count <= %@", @(i));
        RLMAssertCount(AllPrimitiveArrays, i + 1, @"floatObj.@count <= %@", @(i));
        RLMAssertCount(AllPrimitiveArrays, i + 1, @"doubleObj.@count <= %@", @(i));
        RLMAssertCount(AllPrimitiveArrays, i + 1, @"stringObj.@count <= %@", @(i));
        RLMAssertCount(AllPrimitiveArrays, i + 1, @"dataObj.@count <= %@", @(i));
        RLMAssertCount(AllPrimitiveArrays, i + 1, @"dateObj.@count <= %@", @(i));
        RLMAssertCount(AllPrimitiveArrays, i + 1, @"decimalObj.@count <= %@", @(i));
        RLMAssertCount(AllPrimitiveArrays, i + 1, @"objectIdObj.@count <= %@", @(i));
        RLMAssertCount(AllPrimitiveArrays, i + 1, @"uuidObj.@count <= %@", @(i));
        RLMAssertCount(AllPrimitiveArrays, i + 1, @"anyBoolObj.@count <= %@", @(i));
        RLMAssertCount(AllPrimitiveArrays, i + 1, @"anyIntObj.@count <= %@", @(i));
        RLMAssertCount(AllPrimitiveArrays, i + 1, @"anyFloatObj.@count <= %@", @(i));
        RLMAssertCount(AllPrimitiveArrays, i + 1, @"anyDoubleObj.@count <= %@", @(i));
        RLMAssertCount(AllPrimitiveArrays, i + 1, @"anyStringObj.@count <= %@", @(i));
        RLMAssertCount(AllPrimitiveArrays, i + 1, @"anyDataObj.@count <= %@", @(i));
        RLMAssertCount(AllPrimitiveArrays, i + 1, @"anyDateObj.@count <= %@", @(i));
        RLMAssertCount(AllPrimitiveArrays, i + 1, @"anyDecimalObj.@count <= %@", @(i));
        RLMAssertCount(AllPrimitiveArrays, i + 1, @"anyObjectIdObj.@count <= %@", @(i));
        RLMAssertCount(AllPrimitiveArrays, i + 1, @"anyUUIDObj.@count <= %@", @(i));
        RLMAssertCount(AllOptionalPrimitiveArrays, i + 1, @"boolObj.@count <= %@", @(i));
        RLMAssertCount(AllOptionalPrimitiveArrays, i + 1, @"intObj.@count <= %@", @(i));
        RLMAssertCount(AllOptionalPrimitiveArrays, i + 1, @"floatObj.@count <= %@", @(i));
        RLMAssertCount(AllOptionalPrimitiveArrays, i + 1, @"doubleObj.@count <= %@", @(i));
        RLMAssertCount(AllOptionalPrimitiveArrays, i + 1, @"stringObj.@count <= %@", @(i));
        RLMAssertCount(AllOptionalPrimitiveArrays, i + 1, @"dataObj.@count <= %@", @(i));
        RLMAssertCount(AllOptionalPrimitiveArrays, i + 1, @"dateObj.@count <= %@", @(i));
        RLMAssertCount(AllOptionalPrimitiveArrays, i + 1, @"decimalObj.@count <= %@", @(i));
        RLMAssertCount(AllOptionalPrimitiveArrays, i + 1, @"objectIdObj.@count <= %@", @(i));
        RLMAssertCount(AllOptionalPrimitiveArrays, i + 1, @"uuidObj.@count <= %@", @(i));
    }
}

- (void)testQuerySum {
    [realm deleteAllObjects];

    RLMAssertThrowsWithReason(([AllPrimitiveArrays objectsInRealm:realm where:@"boolObj.@sum = %@", @NO]),
                              @"@sum can only be applied to a numeric property.");
    RLMAssertThrowsWithReason(([AllPrimitiveArrays objectsInRealm:realm where:@"stringObj.@sum = %@", @"a"]),
                              @"@sum can only be applied to a numeric property.");
    RLMAssertThrowsWithReason(([AllPrimitiveArrays objectsInRealm:realm where:@"dataObj.@sum = %@", data(1)]),
                              @"@sum can only be applied to a numeric property.");
    RLMAssertThrowsWithReason(([AllPrimitiveArrays objectsInRealm:realm where:@"objectIdObj.@sum = %@", objectId(1)]),
                              @"@sum can only be applied to a numeric property.");
    RLMAssertThrowsWithReason(([AllPrimitiveArrays objectsInRealm:realm where:@"uuidObj.@sum = %@", uuid(@"00000000-0000-0000-0000-000000000000")]),
                              @"@sum can only be applied to a numeric property.");
    RLMAssertThrowsWithReason(([AllOptionalPrimitiveArrays objectsInRealm:realm where:@"boolObj.@sum = %@", @NO]),
                              @"@sum can only be applied to a numeric property.");
    RLMAssertThrowsWithReason(([AllOptionalPrimitiveArrays objectsInRealm:realm where:@"stringObj.@sum = %@", @"a"]),
                              @"@sum can only be applied to a numeric property.");
    RLMAssertThrowsWithReason(([AllOptionalPrimitiveArrays objectsInRealm:realm where:@"dataObj.@sum = %@", data(1)]),
                              @"@sum can only be applied to a numeric property.");
    RLMAssertThrowsWithReason(([AllOptionalPrimitiveArrays objectsInRealm:realm where:@"objectIdObj.@sum = %@", objectId(1)]),
                              @"@sum can only be applied to a numeric property.");
    RLMAssertThrowsWithReason(([AllOptionalPrimitiveArrays objectsInRealm:realm where:@"uuidObj.@sum = %@", uuid(@"00000000-0000-0000-0000-000000000000")]),
                              @"@sum can only be applied to a numeric property.");
    RLMAssertThrowsWithReason(([AllPrimitiveArrays objectsInRealm:realm where:@"dateObj.@sum = %@", date(1)]),
                              @"Cannot sum or average date properties");
    RLMAssertThrowsWithReason(([AllOptionalPrimitiveArrays objectsInRealm:realm where:@"dateObj.@sum = %@", date(1)]),
                              @"Cannot sum or average date properties");

    RLMAssertThrowsWithReason(([AllPrimitiveArrays objectsInRealm:realm where:@"intObj.@sum = %@", @"a"]),
                              @"@sum on a property of type int cannot be compared with 'a'");
    RLMAssertThrowsWithReason(([AllPrimitiveArrays objectsInRealm:realm where:@"floatObj.@sum = %@", @"a"]),
                              @"@sum on a property of type float cannot be compared with 'a'");
    RLMAssertThrowsWithReason(([AllPrimitiveArrays objectsInRealm:realm where:@"doubleObj.@sum = %@", @"a"]),
                              @"@sum on a property of type double cannot be compared with 'a'");
    RLMAssertThrowsWithReason(([AllPrimitiveArrays objectsInRealm:realm where:@"decimalObj.@sum = %@", @"a"]),
                              @"@sum on a property of type decimal128 cannot be compared with 'a'");
    RLMAssertThrowsWithReason(([AllOptionalPrimitiveArrays objectsInRealm:realm where:@"intObj.@sum = %@", @"a"]),
                              @"@sum on a property of type int cannot be compared with 'a'");
    RLMAssertThrowsWithReason(([AllOptionalPrimitiveArrays objectsInRealm:realm where:@"floatObj.@sum = %@", @"a"]),
                              @"@sum on a property of type float cannot be compared with 'a'");
    RLMAssertThrowsWithReason(([AllOptionalPrimitiveArrays objectsInRealm:realm where:@"doubleObj.@sum = %@", @"a"]),
                              @"@sum on a property of type double cannot be compared with 'a'");
    RLMAssertThrowsWithReason(([AllOptionalPrimitiveArrays objectsInRealm:realm where:@"decimalObj.@sum = %@", @"a"]),
                              @"@sum on a property of type decimal128 cannot be compared with 'a'");
    RLMAssertThrowsWithReason(([AllPrimitiveArrays objectsInRealm:realm where:@"intObj.@sum.prop = %@", @"a"]),
                              @"Property 'intObj' is not a link in object of type 'AllPrimitiveArrays'");
    RLMAssertThrowsWithReason(([AllPrimitiveArrays objectsInRealm:realm where:@"floatObj.@sum.prop = %@", @"a"]),
                              @"Property 'floatObj' is not a link in object of type 'AllPrimitiveArrays'");
    RLMAssertThrowsWithReason(([AllPrimitiveArrays objectsInRealm:realm where:@"doubleObj.@sum.prop = %@", @"a"]),
                              @"Property 'doubleObj' is not a link in object of type 'AllPrimitiveArrays'");
    RLMAssertThrowsWithReason(([AllPrimitiveArrays objectsInRealm:realm where:@"decimalObj.@sum.prop = %@", @"a"]),
                              @"Property 'decimalObj' is not a link in object of type 'AllPrimitiveArrays'");
    RLMAssertThrowsWithReason(([AllOptionalPrimitiveArrays objectsInRealm:realm where:@"intObj.@sum.prop = %@", @"a"]),
                              @"Property 'intObj' is not a link in object of type 'AllOptionalPrimitiveArrays'");
    RLMAssertThrowsWithReason(([AllOptionalPrimitiveArrays objectsInRealm:realm where:@"floatObj.@sum.prop = %@", @"a"]),
                              @"Property 'floatObj' is not a link in object of type 'AllOptionalPrimitiveArrays'");
    RLMAssertThrowsWithReason(([AllOptionalPrimitiveArrays objectsInRealm:realm where:@"doubleObj.@sum.prop = %@", @"a"]),
                              @"Property 'doubleObj' is not a link in object of type 'AllOptionalPrimitiveArrays'");
    RLMAssertThrowsWithReason(([AllOptionalPrimitiveArrays objectsInRealm:realm where:@"decimalObj.@sum.prop = %@", @"a"]),
                              @"Property 'decimalObj' is not a link in object of type 'AllOptionalPrimitiveArrays'");
    RLMAssertThrowsWithReason(([AllPrimitiveArrays objectsInRealm:realm where:@"intObj.@sum = %@", NSNull.null]),
                              @"@sum on a property of type int cannot be compared with '<null>'");
    RLMAssertThrowsWithReason(([AllPrimitiveArrays objectsInRealm:realm where:@"floatObj.@sum = %@", NSNull.null]),
                              @"@sum on a property of type float cannot be compared with '<null>'");
    RLMAssertThrowsWithReason(([AllPrimitiveArrays objectsInRealm:realm where:@"doubleObj.@sum = %@", NSNull.null]),
                              @"@sum on a property of type double cannot be compared with '<null>'");
    RLMAssertThrowsWithReason(([AllPrimitiveArrays objectsInRealm:realm where:@"decimalObj.@sum = %@", NSNull.null]),
                              @"@sum on a property of type decimal128 cannot be compared with '<null>'");
    RLMAssertThrowsWithReason(([AllOptionalPrimitiveArrays objectsInRealm:realm where:@"intObj.@sum = %@", NSNull.null]),
                              @"@sum on a property of type int cannot be compared with '<null>'");
    RLMAssertThrowsWithReason(([AllOptionalPrimitiveArrays objectsInRealm:realm where:@"floatObj.@sum = %@", NSNull.null]),
                              @"@sum on a property of type float cannot be compared with '<null>'");
    RLMAssertThrowsWithReason(([AllOptionalPrimitiveArrays objectsInRealm:realm where:@"doubleObj.@sum = %@", NSNull.null]),
                              @"@sum on a property of type double cannot be compared with '<null>'");
    RLMAssertThrowsWithReason(([AllOptionalPrimitiveArrays objectsInRealm:realm where:@"decimalObj.@sum = %@", NSNull.null]),
                              @"@sum on a property of type decimal128 cannot be compared with '<null>'");

    [AllPrimitiveArrays createInRealm:realm withValue:@{
        @"intObj": @[],
        @"floatObj": @[],
        @"doubleObj": @[],
        @"decimalObj": @[],
    }];
    [AllOptionalPrimitiveArrays createInRealm:realm withValue:@{
        @"intObj": @[],
        @"floatObj": @[],
        @"doubleObj": @[],
        @"decimalObj": @[],
    }];
    [AllPrimitiveArrays createInRealm:realm withValue:@{
        @"intObj": @[@2],
        @"floatObj": @[@2.2f],
        @"doubleObj": @[@2.2],
        @"decimalObj": @[decimal128(2)],
    }];
    [AllOptionalPrimitiveArrays createInRealm:realm withValue:@{
        @"intObj": @[@2],
        @"floatObj": @[@2.2f],
        @"doubleObj": @[@2.2],
        @"decimalObj": @[decimal128(2)],
    }];
    [AllPrimitiveArrays createInRealm:realm withValue:@{
        @"intObj": @[@2, @2],
        @"floatObj": @[@2.2f, @2.2f],
        @"doubleObj": @[@2.2, @2.2],
        @"decimalObj": @[decimal128(2), decimal128(2)],
    }];
    [AllOptionalPrimitiveArrays createInRealm:realm withValue:@{
        @"intObj": @[@2, @2],
        @"floatObj": @[@2.2f, @2.2f],
        @"doubleObj": @[@2.2, @2.2],
        @"decimalObj": @[decimal128(2), decimal128(2)],
    }];
    [AllPrimitiveArrays createInRealm:realm withValue:@{
        @"intObj": @[@2, @2, @2],
        @"floatObj": @[@2.2f, @2.2f, @2.2f],
        @"doubleObj": @[@2.2, @2.2, @2.2],
        @"decimalObj": @[decimal128(2), decimal128(2), decimal128(2)],
    }];
    [AllOptionalPrimitiveArrays createInRealm:realm withValue:@{
        @"intObj": @[@2, @2, @2],
        @"floatObj": @[@2.2f, @2.2f, @2.2f],
        @"doubleObj": @[@2.2, @2.2, @2.2],
        @"decimalObj": @[decimal128(2), decimal128(2), decimal128(2)],
    }];

    RLMAssertCount(AllPrimitiveArrays, 1U, @"intObj.@sum == %@", @0);
    RLMAssertCount(AllPrimitiveArrays, 1U, @"floatObj.@sum == %@", @0);
    RLMAssertCount(AllPrimitiveArrays, 1U, @"doubleObj.@sum == %@", @0);
    RLMAssertCount(AllPrimitiveArrays, 1U, @"decimalObj.@sum == %@", @0);
    RLMAssertCount(AllOptionalPrimitiveArrays, 1U, @"intObj.@sum == %@", @0);
    RLMAssertCount(AllOptionalPrimitiveArrays, 1U, @"floatObj.@sum == %@", @0);
    RLMAssertCount(AllOptionalPrimitiveArrays, 1U, @"doubleObj.@sum == %@", @0);
    RLMAssertCount(AllOptionalPrimitiveArrays, 1U, @"decimalObj.@sum == %@", @0);
    RLMAssertCount(AllPrimitiveArrays, 1U, @"intObj.@sum == %@", @2);
    RLMAssertCount(AllPrimitiveArrays, 1U, @"floatObj.@sum == %@", @2.2f);
    RLMAssertCount(AllPrimitiveArrays, 1U, @"doubleObj.@sum == %@", @2.2);
    RLMAssertCount(AllPrimitiveArrays, 1U, @"decimalObj.@sum == %@", decimal128(2));
    RLMAssertCount(AllOptionalPrimitiveArrays, 1U, @"intObj.@sum == %@", @2);
    RLMAssertCount(AllOptionalPrimitiveArrays, 1U, @"floatObj.@sum == %@", @2.2f);
    RLMAssertCount(AllOptionalPrimitiveArrays, 1U, @"doubleObj.@sum == %@", @2.2);
    RLMAssertCount(AllOptionalPrimitiveArrays, 1U, @"decimalObj.@sum == %@", decimal128(2));
    RLMAssertCount(AllPrimitiveArrays, 3U, @"intObj.@sum != %@", @2);
    RLMAssertCount(AllPrimitiveArrays, 3U, @"floatObj.@sum != %@", @2.2f);
    RLMAssertCount(AllPrimitiveArrays, 3U, @"doubleObj.@sum != %@", @2.2);
    RLMAssertCount(AllPrimitiveArrays, 3U, @"decimalObj.@sum != %@", decimal128(2));
    RLMAssertCount(AllOptionalPrimitiveArrays, 3U, @"intObj.@sum != %@", @2);
    RLMAssertCount(AllOptionalPrimitiveArrays, 3U, @"floatObj.@sum != %@", @2.2f);
    RLMAssertCount(AllOptionalPrimitiveArrays, 3U, @"doubleObj.@sum != %@", @2.2);
    RLMAssertCount(AllOptionalPrimitiveArrays, 3U, @"decimalObj.@sum != %@", decimal128(2));
    RLMAssertCount(AllPrimitiveArrays, 3U, @"intObj.@sum >= %@", @2);
    RLMAssertCount(AllPrimitiveArrays, 3U, @"floatObj.@sum >= %@", @2.2f);
    RLMAssertCount(AllPrimitiveArrays, 3U, @"doubleObj.@sum >= %@", @2.2);
    RLMAssertCount(AllPrimitiveArrays, 3U, @"decimalObj.@sum >= %@", decimal128(2));
    RLMAssertCount(AllOptionalPrimitiveArrays, 3U, @"intObj.@sum >= %@", @2);
    RLMAssertCount(AllOptionalPrimitiveArrays, 3U, @"floatObj.@sum >= %@", @2.2f);
    RLMAssertCount(AllOptionalPrimitiveArrays, 3U, @"doubleObj.@sum >= %@", @2.2);
    RLMAssertCount(AllOptionalPrimitiveArrays, 3U, @"decimalObj.@sum >= %@", decimal128(2));
    RLMAssertCount(AllPrimitiveArrays, 2U, @"intObj.@sum > %@", @2);
    RLMAssertCount(AllPrimitiveArrays, 2U, @"floatObj.@sum > %@", @2.2f);
    RLMAssertCount(AllPrimitiveArrays, 2U, @"doubleObj.@sum > %@", @2.2);
    RLMAssertCount(AllPrimitiveArrays, 2U, @"decimalObj.@sum > %@", decimal128(2));
    RLMAssertCount(AllOptionalPrimitiveArrays, 2U, @"intObj.@sum > %@", @2);
    RLMAssertCount(AllOptionalPrimitiveArrays, 2U, @"floatObj.@sum > %@", @2.2f);
    RLMAssertCount(AllOptionalPrimitiveArrays, 2U, @"doubleObj.@sum > %@", @2.2);
    RLMAssertCount(AllOptionalPrimitiveArrays, 2U, @"decimalObj.@sum > %@", decimal128(2));
    RLMAssertCount(AllPrimitiveArrays, 2U, @"intObj.@sum < %@", @3);
    RLMAssertCount(AllPrimitiveArrays, 2U, @"floatObj.@sum < %@", @3.3f);
    RLMAssertCount(AllPrimitiveArrays, 2U, @"doubleObj.@sum < %@", @3.3);
    RLMAssertCount(AllPrimitiveArrays, 2U, @"decimalObj.@sum < %@", decimal128(3));
    RLMAssertCount(AllOptionalPrimitiveArrays, 2U, @"intObj.@sum < %@", @3);
    RLMAssertCount(AllOptionalPrimitiveArrays, 2U, @"floatObj.@sum < %@", @3.3f);
    RLMAssertCount(AllOptionalPrimitiveArrays, 2U, @"doubleObj.@sum < %@", @3.3);
    RLMAssertCount(AllOptionalPrimitiveArrays, 2U, @"decimalObj.@sum < %@", decimal128(3));
    RLMAssertCount(AllPrimitiveArrays, 2U, @"intObj.@sum <= %@", @3);
    RLMAssertCount(AllPrimitiveArrays, 2U, @"floatObj.@sum <= %@", @3.3f);
    RLMAssertCount(AllPrimitiveArrays, 2U, @"doubleObj.@sum <= %@", @3.3);
    RLMAssertCount(AllPrimitiveArrays, 2U, @"decimalObj.@sum <= %@", decimal128(3));
    RLMAssertCount(AllOptionalPrimitiveArrays, 2U, @"intObj.@sum <= %@", @3);
    RLMAssertCount(AllOptionalPrimitiveArrays, 2U, @"floatObj.@sum <= %@", @3.3f);
    RLMAssertCount(AllOptionalPrimitiveArrays, 2U, @"doubleObj.@sum <= %@", @3.3);
    RLMAssertCount(AllOptionalPrimitiveArrays, 2U, @"decimalObj.@sum <= %@", decimal128(3));
}

- (void)testQueryAverage {
    [realm deleteAllObjects];

    RLMAssertThrowsWithReason(([AllPrimitiveArrays objectsInRealm:realm where:@"boolObj.@avg = %@", @NO]),
                              @"@avg can only be applied to a numeric property.");
    RLMAssertThrowsWithReason(([AllPrimitiveArrays objectsInRealm:realm where:@"stringObj.@avg = %@", @"a"]),
                              @"@avg can only be applied to a numeric property.");
    RLMAssertThrowsWithReason(([AllPrimitiveArrays objectsInRealm:realm where:@"dataObj.@avg = %@", data(1)]),
                              @"@avg can only be applied to a numeric property.");
    RLMAssertThrowsWithReason(([AllPrimitiveArrays objectsInRealm:realm where:@"objectIdObj.@avg = %@", objectId(1)]),
                              @"@avg can only be applied to a numeric property.");
    RLMAssertThrowsWithReason(([AllPrimitiveArrays objectsInRealm:realm where:@"uuidObj.@avg = %@", uuid(@"00000000-0000-0000-0000-000000000000")]),
                              @"@avg can only be applied to a numeric property.");
    RLMAssertThrowsWithReason(([AllOptionalPrimitiveArrays objectsInRealm:realm where:@"boolObj.@avg = %@", @NO]),
                              @"@avg can only be applied to a numeric property.");
    RLMAssertThrowsWithReason(([AllOptionalPrimitiveArrays objectsInRealm:realm where:@"stringObj.@avg = %@", @"a"]),
                              @"@avg can only be applied to a numeric property.");
    RLMAssertThrowsWithReason(([AllOptionalPrimitiveArrays objectsInRealm:realm where:@"dataObj.@avg = %@", data(1)]),
                              @"@avg can only be applied to a numeric property.");
    RLMAssertThrowsWithReason(([AllOptionalPrimitiveArrays objectsInRealm:realm where:@"objectIdObj.@avg = %@", objectId(1)]),
                              @"@avg can only be applied to a numeric property.");
    RLMAssertThrowsWithReason(([AllOptionalPrimitiveArrays objectsInRealm:realm where:@"uuidObj.@avg = %@", uuid(@"00000000-0000-0000-0000-000000000000")]),
                              @"@avg can only be applied to a numeric property.");
    RLMAssertThrowsWithReason(([AllPrimitiveArrays objectsInRealm:realm where:@"dateObj.@avg = %@", date(1)]),
                              @"Cannot sum or average date properties");
    RLMAssertThrowsWithReason(([AllOptionalPrimitiveArrays objectsInRealm:realm where:@"dateObj.@avg = %@", date(1)]),
                              @"Cannot sum or average date properties");

    RLMAssertThrowsWithReason(([AllPrimitiveArrays objectsInRealm:realm where:@"intObj.@avg = %@", @"a"]),
                              @"@avg on a property of type int cannot be compared with 'a'");
    RLMAssertThrowsWithReason(([AllPrimitiveArrays objectsInRealm:realm where:@"floatObj.@avg = %@", @"a"]),
                              @"@avg on a property of type float cannot be compared with 'a'");
    RLMAssertThrowsWithReason(([AllPrimitiveArrays objectsInRealm:realm where:@"doubleObj.@avg = %@", @"a"]),
                              @"@avg on a property of type double cannot be compared with 'a'");
    RLMAssertThrowsWithReason(([AllPrimitiveArrays objectsInRealm:realm where:@"decimalObj.@avg = %@", @"a"]),
                              @"@avg on a property of type decimal128 cannot be compared with 'a'");
    RLMAssertThrowsWithReason(([AllOptionalPrimitiveArrays objectsInRealm:realm where:@"intObj.@avg = %@", @"a"]),
                              @"@avg on a property of type int cannot be compared with 'a'");
    RLMAssertThrowsWithReason(([AllOptionalPrimitiveArrays objectsInRealm:realm where:@"floatObj.@avg = %@", @"a"]),
                              @"@avg on a property of type float cannot be compared with 'a'");
    RLMAssertThrowsWithReason(([AllOptionalPrimitiveArrays objectsInRealm:realm where:@"doubleObj.@avg = %@", @"a"]),
                              @"@avg on a property of type double cannot be compared with 'a'");
    RLMAssertThrowsWithReason(([AllOptionalPrimitiveArrays objectsInRealm:realm where:@"decimalObj.@avg = %@", @"a"]),
                              @"@avg on a property of type decimal128 cannot be compared with 'a'");
    RLMAssertThrowsWithReason(([AllPrimitiveArrays objectsInRealm:realm where:@"intObj.@avg.prop = %@", @"a"]),
                              @"Property 'intObj' is not a link in object of type 'AllPrimitiveArrays'");
    RLMAssertThrowsWithReason(([AllPrimitiveArrays objectsInRealm:realm where:@"floatObj.@avg.prop = %@", @"a"]),
                              @"Property 'floatObj' is not a link in object of type 'AllPrimitiveArrays'");
    RLMAssertThrowsWithReason(([AllPrimitiveArrays objectsInRealm:realm where:@"doubleObj.@avg.prop = %@", @"a"]),
                              @"Property 'doubleObj' is not a link in object of type 'AllPrimitiveArrays'");
    RLMAssertThrowsWithReason(([AllPrimitiveArrays objectsInRealm:realm where:@"decimalObj.@avg.prop = %@", @"a"]),
                              @"Property 'decimalObj' is not a link in object of type 'AllPrimitiveArrays'");
    RLMAssertThrowsWithReason(([AllOptionalPrimitiveArrays objectsInRealm:realm where:@"intObj.@avg.prop = %@", @"a"]),
                              @"Property 'intObj' is not a link in object of type 'AllOptionalPrimitiveArrays'");
    RLMAssertThrowsWithReason(([AllOptionalPrimitiveArrays objectsInRealm:realm where:@"floatObj.@avg.prop = %@", @"a"]),
                              @"Property 'floatObj' is not a link in object of type 'AllOptionalPrimitiveArrays'");
    RLMAssertThrowsWithReason(([AllOptionalPrimitiveArrays objectsInRealm:realm where:@"doubleObj.@avg.prop = %@", @"a"]),
                              @"Property 'doubleObj' is not a link in object of type 'AllOptionalPrimitiveArrays'");
    RLMAssertThrowsWithReason(([AllOptionalPrimitiveArrays objectsInRealm:realm where:@"decimalObj.@avg.prop = %@", @"a"]),
                              @"Property 'decimalObj' is not a link in object of type 'AllOptionalPrimitiveArrays'");

    [AllPrimitiveArrays createInRealm:realm withValue:@{
        @"intObj": @[],
        @"floatObj": @[],
        @"doubleObj": @[],
        @"decimalObj": @[],
    }];
    [AllOptionalPrimitiveArrays createInRealm:realm withValue:@{
        @"intObj": @[],
        @"floatObj": @[],
        @"doubleObj": @[],
        @"decimalObj": @[],
    }];
    [AllPrimitiveArrays createInRealm:realm withValue:@{
        @"intObj": @[@2],
        @"floatObj": @[@2.2f],
        @"doubleObj": @[@2.2],
        @"decimalObj": @[decimal128(2)],
    }];
    [AllOptionalPrimitiveArrays createInRealm:realm withValue:@{
        @"intObj": @[@2],
        @"floatObj": @[@2.2f],
        @"doubleObj": @[@2.2],
        @"decimalObj": @[decimal128(2)],
    }];
    [AllPrimitiveArrays createInRealm:realm withValue:@{
        @"intObj": @[@2, @3],
        @"floatObj": @[@2.2f, @3.3f],
        @"doubleObj": @[@2.2, @3.3],
        @"decimalObj": @[decimal128(2), decimal128(3)],
    }];
    [AllOptionalPrimitiveArrays createInRealm:realm withValue:@{
        @"intObj": @[@2, @3],
        @"floatObj": @[@2.2f, @3.3f],
        @"doubleObj": @[@2.2, @3.3],
        @"decimalObj": @[decimal128(2), decimal128(3)],
    }];
    [AllPrimitiveArrays createInRealm:realm withValue:@{
        @"intObj": @[@3],
        @"floatObj": @[@3.3f],
        @"doubleObj": @[@3.3],
        @"decimalObj": @[decimal128(3)],
    }];
    [AllOptionalPrimitiveArrays createInRealm:realm withValue:@{
        @"intObj": @[@3],
        @"floatObj": @[@3.3f],
        @"doubleObj": @[@3.3],
        @"decimalObj": @[decimal128(3)],
    }];

    RLMAssertCount(AllPrimitiveArrays, 1U, @"intObj.@avg == %@", NSNull.null);
    RLMAssertCount(AllPrimitiveArrays, 1U, @"floatObj.@avg == %@", NSNull.null);
    RLMAssertCount(AllPrimitiveArrays, 1U, @"doubleObj.@avg == %@", NSNull.null);
    RLMAssertCount(AllPrimitiveArrays, 1U, @"decimalObj.@avg == %@", NSNull.null);
    RLMAssertCount(AllOptionalPrimitiveArrays, 1U, @"intObj.@avg == %@", NSNull.null);
    RLMAssertCount(AllOptionalPrimitiveArrays, 1U, @"floatObj.@avg == %@", NSNull.null);
    RLMAssertCount(AllOptionalPrimitiveArrays, 1U, @"doubleObj.@avg == %@", NSNull.null);
    RLMAssertCount(AllOptionalPrimitiveArrays, 1U, @"decimalObj.@avg == %@", NSNull.null);
    RLMAssertCount(AllPrimitiveArrays, 1U, @"intObj.@avg == %@", @2);
    RLMAssertCount(AllPrimitiveArrays, 1U, @"floatObj.@avg == %@", @2.2f);
    RLMAssertCount(AllPrimitiveArrays, 1U, @"doubleObj.@avg == %@", @2.2);
    RLMAssertCount(AllPrimitiveArrays, 1U, @"decimalObj.@avg == %@", decimal128(2));
    RLMAssertCount(AllOptionalPrimitiveArrays, 1U, @"intObj.@avg == %@", @2);
    RLMAssertCount(AllOptionalPrimitiveArrays, 1U, @"floatObj.@avg == %@", @2.2f);
    RLMAssertCount(AllOptionalPrimitiveArrays, 1U, @"doubleObj.@avg == %@", @2.2);
    RLMAssertCount(AllOptionalPrimitiveArrays, 1U, @"decimalObj.@avg == %@", decimal128(2));
    RLMAssertCount(AllPrimitiveArrays, 3U, @"intObj.@avg != %@", @2);
    RLMAssertCount(AllPrimitiveArrays, 3U, @"floatObj.@avg != %@", @2.2f);
    RLMAssertCount(AllPrimitiveArrays, 3U, @"doubleObj.@avg != %@", @2.2);
    RLMAssertCount(AllPrimitiveArrays, 3U, @"decimalObj.@avg != %@", decimal128(2));
    RLMAssertCount(AllOptionalPrimitiveArrays, 3U, @"intObj.@avg != %@", @2);
    RLMAssertCount(AllOptionalPrimitiveArrays, 3U, @"floatObj.@avg != %@", @2.2f);
    RLMAssertCount(AllOptionalPrimitiveArrays, 3U, @"doubleObj.@avg != %@", @2.2);
    RLMAssertCount(AllOptionalPrimitiveArrays, 3U, @"decimalObj.@avg != %@", decimal128(2));
    RLMAssertCount(AllPrimitiveArrays, 3U, @"intObj.@avg >= %@", @2);
    RLMAssertCount(AllPrimitiveArrays, 3U, @"floatObj.@avg >= %@", @2.2f);
    RLMAssertCount(AllPrimitiveArrays, 3U, @"doubleObj.@avg >= %@", @2.2);
    RLMAssertCount(AllPrimitiveArrays, 3U, @"decimalObj.@avg >= %@", decimal128(2));
    RLMAssertCount(AllOptionalPrimitiveArrays, 3U, @"intObj.@avg >= %@", @2);
    RLMAssertCount(AllOptionalPrimitiveArrays, 3U, @"floatObj.@avg >= %@", @2.2f);
    RLMAssertCount(AllOptionalPrimitiveArrays, 3U, @"doubleObj.@avg >= %@", @2.2);
    RLMAssertCount(AllOptionalPrimitiveArrays, 3U, @"decimalObj.@avg >= %@", decimal128(2));
    RLMAssertCount(AllPrimitiveArrays, 2U, @"intObj.@avg > %@", @2);
    RLMAssertCount(AllPrimitiveArrays, 2U, @"floatObj.@avg > %@", @2.2f);
    RLMAssertCount(AllPrimitiveArrays, 2U, @"doubleObj.@avg > %@", @2.2);
    RLMAssertCount(AllPrimitiveArrays, 2U, @"decimalObj.@avg > %@", decimal128(2));
    RLMAssertCount(AllOptionalPrimitiveArrays, 2U, @"intObj.@avg > %@", @2);
    RLMAssertCount(AllOptionalPrimitiveArrays, 2U, @"floatObj.@avg > %@", @2.2f);
    RLMAssertCount(AllOptionalPrimitiveArrays, 2U, @"doubleObj.@avg > %@", @2.2);
    RLMAssertCount(AllOptionalPrimitiveArrays, 2U, @"decimalObj.@avg > %@", decimal128(2));
    RLMAssertCount(AllPrimitiveArrays, 2U, @"intObj.@avg < %@", @3);
    RLMAssertCount(AllPrimitiveArrays, 2U, @"floatObj.@avg < %@", @3.3f);
    RLMAssertCount(AllPrimitiveArrays, 2U, @"doubleObj.@avg < %@", @3.3);
    RLMAssertCount(AllPrimitiveArrays, 2U, @"decimalObj.@avg < %@", decimal128(3));
    RLMAssertCount(AllOptionalPrimitiveArrays, 2U, @"intObj.@avg < %@", @3);
    RLMAssertCount(AllOptionalPrimitiveArrays, 2U, @"floatObj.@avg < %@", @3.3f);
    RLMAssertCount(AllOptionalPrimitiveArrays, 2U, @"doubleObj.@avg < %@", @3.3);
    RLMAssertCount(AllOptionalPrimitiveArrays, 2U, @"decimalObj.@avg < %@", decimal128(3));
    RLMAssertCount(AllPrimitiveArrays, 3U, @"intObj.@avg <= %@", @3);
    RLMAssertCount(AllPrimitiveArrays, 3U, @"floatObj.@avg <= %@", @3.3f);
    RLMAssertCount(AllPrimitiveArrays, 3U, @"doubleObj.@avg <= %@", @3.3);
    RLMAssertCount(AllPrimitiveArrays, 3U, @"decimalObj.@avg <= %@", decimal128(3));
    RLMAssertCount(AllOptionalPrimitiveArrays, 3U, @"intObj.@avg <= %@", @3);
    RLMAssertCount(AllOptionalPrimitiveArrays, 3U, @"floatObj.@avg <= %@", @3.3f);
    RLMAssertCount(AllOptionalPrimitiveArrays, 3U, @"doubleObj.@avg <= %@", @3.3);
    RLMAssertCount(AllOptionalPrimitiveArrays, 3U, @"decimalObj.@avg <= %@", decimal128(3));
}

- (void)testQueryMin {
    [realm deleteAllObjects];

    RLMAssertThrowsWithReason(([AllPrimitiveArrays objectsInRealm:realm where:@"boolObj.@min = %@", @NO]),
                              @"@min can only be applied to a numeric property.");
    RLMAssertThrowsWithReason(([AllPrimitiveArrays objectsInRealm:realm where:@"stringObj.@min = %@", @"a"]),
                              @"@min can only be applied to a numeric property.");
    RLMAssertThrowsWithReason(([AllPrimitiveArrays objectsInRealm:realm where:@"dataObj.@min = %@", data(1)]),
                              @"@min can only be applied to a numeric property.");
    RLMAssertThrowsWithReason(([AllPrimitiveArrays objectsInRealm:realm where:@"objectIdObj.@min = %@", objectId(1)]),
                              @"@min can only be applied to a numeric property.");
    RLMAssertThrowsWithReason(([AllPrimitiveArrays objectsInRealm:realm where:@"uuidObj.@min = %@", uuid(@"00000000-0000-0000-0000-000000000000")]),
                              @"@min can only be applied to a numeric property.");
    RLMAssertThrowsWithReason(([AllOptionalPrimitiveArrays objectsInRealm:realm where:@"boolObj.@min = %@", @NO]),
                              @"@min can only be applied to a numeric property.");
    RLMAssertThrowsWithReason(([AllOptionalPrimitiveArrays objectsInRealm:realm where:@"stringObj.@min = %@", @"a"]),
                              @"@min can only be applied to a numeric property.");
    RLMAssertThrowsWithReason(([AllOptionalPrimitiveArrays objectsInRealm:realm where:@"dataObj.@min = %@", data(1)]),
                              @"@min can only be applied to a numeric property.");
    RLMAssertThrowsWithReason(([AllOptionalPrimitiveArrays objectsInRealm:realm where:@"objectIdObj.@min = %@", objectId(1)]),
                              @"@min can only be applied to a numeric property.");
    RLMAssertThrowsWithReason(([AllOptionalPrimitiveArrays objectsInRealm:realm where:@"uuidObj.@min = %@", uuid(@"00000000-0000-0000-0000-000000000000")]),
                              @"@min can only be applied to a numeric property.");
    RLMAssertThrowsWithReason(([AllPrimitiveArrays objectsInRealm:realm where:@"intObj.@min = %@", @"a"]),
                              @"@min on a property of type int cannot be compared with 'a'");
    RLMAssertThrowsWithReason(([AllPrimitiveArrays objectsInRealm:realm where:@"floatObj.@min = %@", @"a"]),
                              @"@min on a property of type float cannot be compared with 'a'");
    RLMAssertThrowsWithReason(([AllPrimitiveArrays objectsInRealm:realm where:@"doubleObj.@min = %@", @"a"]),
                              @"@min on a property of type double cannot be compared with 'a'");
    RLMAssertThrowsWithReason(([AllPrimitiveArrays objectsInRealm:realm where:@"dateObj.@min = %@", @"a"]),
                              @"@min on a property of type date cannot be compared with 'a'");
    RLMAssertThrowsWithReason(([AllPrimitiveArrays objectsInRealm:realm where:@"decimalObj.@min = %@", @"a"]),
                              @"@min on a property of type decimal128 cannot be compared with 'a'");
    RLMAssertThrowsWithReason(([AllOptionalPrimitiveArrays objectsInRealm:realm where:@"intObj.@min = %@", @"a"]),
                              @"@min on a property of type int cannot be compared with 'a'");
    RLMAssertThrowsWithReason(([AllOptionalPrimitiveArrays objectsInRealm:realm where:@"floatObj.@min = %@", @"a"]),
                              @"@min on a property of type float cannot be compared with 'a'");
    RLMAssertThrowsWithReason(([AllOptionalPrimitiveArrays objectsInRealm:realm where:@"doubleObj.@min = %@", @"a"]),
                              @"@min on a property of type double cannot be compared with 'a'");
    RLMAssertThrowsWithReason(([AllOptionalPrimitiveArrays objectsInRealm:realm where:@"dateObj.@min = %@", @"a"]),
                              @"@min on a property of type date cannot be compared with 'a'");
    RLMAssertThrowsWithReason(([AllOptionalPrimitiveArrays objectsInRealm:realm where:@"decimalObj.@min = %@", @"a"]),
                              @"@min on a property of type decimal128 cannot be compared with 'a'");
    RLMAssertThrowsWithReason(([AllPrimitiveArrays objectsInRealm:realm where:@"intObj.@min.prop = %@", @"a"]),
                              @"Property 'intObj' is not a link in object of type 'AllPrimitiveArrays'");
    RLMAssertThrowsWithReason(([AllPrimitiveArrays objectsInRealm:realm where:@"floatObj.@min.prop = %@", @"a"]),
                              @"Property 'floatObj' is not a link in object of type 'AllPrimitiveArrays'");
    RLMAssertThrowsWithReason(([AllPrimitiveArrays objectsInRealm:realm where:@"doubleObj.@min.prop = %@", @"a"]),
                              @"Property 'doubleObj' is not a link in object of type 'AllPrimitiveArrays'");
    RLMAssertThrowsWithReason(([AllPrimitiveArrays objectsInRealm:realm where:@"dateObj.@min.prop = %@", @"a"]),
                              @"Property 'dateObj' is not a link in object of type 'AllPrimitiveArrays'");
    RLMAssertThrowsWithReason(([AllPrimitiveArrays objectsInRealm:realm where:@"decimalObj.@min.prop = %@", @"a"]),
                              @"Property 'decimalObj' is not a link in object of type 'AllPrimitiveArrays'");
    RLMAssertThrowsWithReason(([AllPrimitiveArrays objectsInRealm:realm where:@"anyIntObj.@min.prop = %@", @"a"]),
                              @"Property 'anyIntObj' is not a link in object of type 'AllPrimitiveArrays'");
    RLMAssertThrowsWithReason(([AllPrimitiveArrays objectsInRealm:realm where:@"anyFloatObj.@min.prop = %@", @"a"]),
                              @"Property 'anyFloatObj' is not a link in object of type 'AllPrimitiveArrays'");
    RLMAssertThrowsWithReason(([AllPrimitiveArrays objectsInRealm:realm where:@"anyDoubleObj.@min.prop = %@", @"a"]),
                              @"Property 'anyDoubleObj' is not a link in object of type 'AllPrimitiveArrays'");
    RLMAssertThrowsWithReason(([AllPrimitiveArrays objectsInRealm:realm where:@"anyDateObj.@min.prop = %@", @"a"]),
                              @"Property 'anyDateObj' is not a link in object of type 'AllPrimitiveArrays'");
    RLMAssertThrowsWithReason(([AllPrimitiveArrays objectsInRealm:realm where:@"anyDecimalObj.@min.prop = %@", @"a"]),
                              @"Property 'anyDecimalObj' is not a link in object of type 'AllPrimitiveArrays'");
    RLMAssertThrowsWithReason(([AllOptionalPrimitiveArrays objectsInRealm:realm where:@"intObj.@min.prop = %@", @"a"]),
                              @"Property 'intObj' is not a link in object of type 'AllOptionalPrimitiveArrays'");
    RLMAssertThrowsWithReason(([AllOptionalPrimitiveArrays objectsInRealm:realm where:@"floatObj.@min.prop = %@", @"a"]),
                              @"Property 'floatObj' is not a link in object of type 'AllOptionalPrimitiveArrays'");
    RLMAssertThrowsWithReason(([AllOptionalPrimitiveArrays objectsInRealm:realm where:@"doubleObj.@min.prop = %@", @"a"]),
                              @"Property 'doubleObj' is not a link in object of type 'AllOptionalPrimitiveArrays'");
    RLMAssertThrowsWithReason(([AllOptionalPrimitiveArrays objectsInRealm:realm where:@"dateObj.@min.prop = %@", @"a"]),
                              @"Property 'dateObj' is not a link in object of type 'AllOptionalPrimitiveArrays'");
    RLMAssertThrowsWithReason(([AllOptionalPrimitiveArrays objectsInRealm:realm where:@"decimalObj.@min.prop = %@", @"a"]),
                              @"Property 'decimalObj' is not a link in object of type 'AllOptionalPrimitiveArrays'");

    // No objects, so count is zero
    RLMAssertCount(AllPrimitiveArrays, 0U, @"intObj.@min == %@", @2);
    RLMAssertCount(AllPrimitiveArrays, 0U, @"floatObj.@min == %@", @2.2f);
    RLMAssertCount(AllPrimitiveArrays, 0U, @"doubleObj.@min == %@", @2.2);
    RLMAssertCount(AllPrimitiveArrays, 0U, @"dateObj.@min == %@", date(1));
    RLMAssertCount(AllPrimitiveArrays, 0U, @"decimalObj.@min == %@", decimal128(2));
    RLMAssertCount(AllPrimitiveArrays, 0U, @"anyIntObj.@min == %@", @2);
    RLMAssertCount(AllPrimitiveArrays, 0U, @"anyFloatObj.@min == %@", @2.2f);
    RLMAssertCount(AllPrimitiveArrays, 0U, @"anyDoubleObj.@min == %@", @2.2);
    RLMAssertCount(AllPrimitiveArrays, 0U, @"anyDateObj.@min == %@", date(1));
    RLMAssertCount(AllPrimitiveArrays, 0U, @"anyDecimalObj.@min == %@", decimal128(2));
    RLMAssertCount(AllOptionalPrimitiveArrays, 0U, @"intObj.@min == %@", @2);
    RLMAssertCount(AllOptionalPrimitiveArrays, 0U, @"floatObj.@min == %@", @2.2f);
    RLMAssertCount(AllOptionalPrimitiveArrays, 0U, @"doubleObj.@min == %@", @2.2);
    RLMAssertCount(AllOptionalPrimitiveArrays, 0U, @"dateObj.@min == %@", date(1));
    RLMAssertCount(AllOptionalPrimitiveArrays, 0U, @"decimalObj.@min == %@", decimal128(2));

    [AllPrimitiveArrays createInRealm:realm withValue:@{}];
    [AllOptionalPrimitiveArrays createInRealm:realm withValue:@{}];

    // Only empty arrays, so count is zero
    RLMAssertCount(AllPrimitiveArrays, 0U, @"intObj.@min == %@", @2);
    RLMAssertCount(AllPrimitiveArrays, 0U, @"floatObj.@min == %@", @2.2f);
    RLMAssertCount(AllPrimitiveArrays, 0U, @"doubleObj.@min == %@", @2.2);
    RLMAssertCount(AllPrimitiveArrays, 0U, @"dateObj.@min == %@", date(1));
    RLMAssertCount(AllPrimitiveArrays, 0U, @"decimalObj.@min == %@", decimal128(2));
    RLMAssertCount(AllPrimitiveArrays, 0U, @"anyIntObj.@min == %@", @2);
    RLMAssertCount(AllPrimitiveArrays, 0U, @"anyFloatObj.@min == %@", @2.2f);
    RLMAssertCount(AllPrimitiveArrays, 0U, @"anyDoubleObj.@min == %@", @2.2);
    RLMAssertCount(AllPrimitiveArrays, 0U, @"anyDateObj.@min == %@", date(1));
    RLMAssertCount(AllPrimitiveArrays, 0U, @"anyDecimalObj.@min == %@", decimal128(2));
    RLMAssertCount(AllOptionalPrimitiveArrays, 0U, @"intObj.@min == %@", @2);
    RLMAssertCount(AllOptionalPrimitiveArrays, 0U, @"floatObj.@min == %@", @2.2f);
    RLMAssertCount(AllOptionalPrimitiveArrays, 0U, @"doubleObj.@min == %@", @2.2);
    RLMAssertCount(AllOptionalPrimitiveArrays, 0U, @"dateObj.@min == %@", date(1));
    RLMAssertCount(AllOptionalPrimitiveArrays, 0U, @"decimalObj.@min == %@", decimal128(2));
    RLMAssertCount(AllPrimitiveArrays, 0U, @"intObj.@min == %@", @3);
    RLMAssertCount(AllPrimitiveArrays, 0U, @"floatObj.@min == %@", @3.3f);
    RLMAssertCount(AllPrimitiveArrays, 0U, @"doubleObj.@min == %@", @3.3);
    RLMAssertCount(AllPrimitiveArrays, 0U, @"dateObj.@min == %@", date(2));
    RLMAssertCount(AllPrimitiveArrays, 0U, @"decimalObj.@min == %@", decimal128(3));
    RLMAssertCount(AllPrimitiveArrays, 0U, @"anyIntObj.@min == %@", @3);
    RLMAssertCount(AllPrimitiveArrays, 0U, @"anyFloatObj.@min == %@", @3.3f);
    RLMAssertCount(AllPrimitiveArrays, 0U, @"anyDoubleObj.@min == %@", @3.3);
    RLMAssertCount(AllPrimitiveArrays, 0U, @"anyDateObj.@min == %@", date(2));
    RLMAssertCount(AllPrimitiveArrays, 0U, @"anyDecimalObj.@min == %@", decimal128(3));
    RLMAssertCount(AllOptionalPrimitiveArrays, 0U, @"intObj.@min == %@", @3);
    RLMAssertCount(AllOptionalPrimitiveArrays, 0U, @"floatObj.@min == %@", @3.3f);
    RLMAssertCount(AllOptionalPrimitiveArrays, 0U, @"doubleObj.@min == %@", @3.3);
    RLMAssertCount(AllOptionalPrimitiveArrays, 0U, @"dateObj.@min == %@", date(2));
    RLMAssertCount(AllOptionalPrimitiveArrays, 0U, @"decimalObj.@min == %@", decimal128(3));

    RLMAssertCount(AllPrimitiveArrays, 1U, @"intObj.@min == nil");
    RLMAssertCount(AllPrimitiveArrays, 1U, @"floatObj.@min == nil");
    RLMAssertCount(AllPrimitiveArrays, 1U, @"doubleObj.@min == nil");
    RLMAssertCount(AllPrimitiveArrays, 1U, @"dateObj.@min == nil");
    RLMAssertCount(AllPrimitiveArrays, 1U, @"decimalObj.@min == nil");
    RLMAssertCount(AllPrimitiveArrays, 1U, @"anyIntObj.@min == nil");
    RLMAssertCount(AllPrimitiveArrays, 1U, @"anyFloatObj.@min == nil");
    RLMAssertCount(AllPrimitiveArrays, 1U, @"anyDoubleObj.@min == nil");
    RLMAssertCount(AllPrimitiveArrays, 1U, @"anyDateObj.@min == nil");
    RLMAssertCount(AllPrimitiveArrays, 1U, @"anyDecimalObj.@min == nil");
    RLMAssertCount(AllOptionalPrimitiveArrays, 1U, @"intObj.@min == nil");
    RLMAssertCount(AllOptionalPrimitiveArrays, 1U, @"floatObj.@min == nil");
    RLMAssertCount(AllOptionalPrimitiveArrays, 1U, @"doubleObj.@min == nil");
    RLMAssertCount(AllOptionalPrimitiveArrays, 1U, @"dateObj.@min == nil");
    RLMAssertCount(AllOptionalPrimitiveArrays, 1U, @"decimalObj.@min == nil");
    RLMAssertCount(AllPrimitiveArrays, 1U, @"intObj.@min == %@", NSNull.null);
    RLMAssertCount(AllPrimitiveArrays, 1U, @"floatObj.@min == %@", NSNull.null);
    RLMAssertCount(AllPrimitiveArrays, 1U, @"doubleObj.@min == %@", NSNull.null);
    RLMAssertCount(AllPrimitiveArrays, 1U, @"dateObj.@min == %@", NSNull.null);
    RLMAssertCount(AllPrimitiveArrays, 1U, @"decimalObj.@min == %@", NSNull.null);
    RLMAssertCount(AllPrimitiveArrays, 1U, @"anyIntObj.@min == %@", NSNull.null);
    RLMAssertCount(AllPrimitiveArrays, 1U, @"anyFloatObj.@min == %@", NSNull.null);
    RLMAssertCount(AllPrimitiveArrays, 1U, @"anyDoubleObj.@min == %@", NSNull.null);
    RLMAssertCount(AllPrimitiveArrays, 1U, @"anyDateObj.@min == %@", NSNull.null);
    RLMAssertCount(AllPrimitiveArrays, 1U, @"anyDecimalObj.@min == %@", NSNull.null);
    RLMAssertCount(AllOptionalPrimitiveArrays, 1U, @"intObj.@min == %@", NSNull.null);
    RLMAssertCount(AllOptionalPrimitiveArrays, 1U, @"floatObj.@min == %@", NSNull.null);
    RLMAssertCount(AllOptionalPrimitiveArrays, 1U, @"doubleObj.@min == %@", NSNull.null);
    RLMAssertCount(AllOptionalPrimitiveArrays, 1U, @"dateObj.@min == %@", NSNull.null);
    RLMAssertCount(AllOptionalPrimitiveArrays, 1U, @"decimalObj.@min == %@", NSNull.null);

    [self createObjectWithValueIndex:0];

    // One object where v0 is min and zero with v1
    RLMAssertCount(AllPrimitiveArrays, 1U, @"intObj.@min == %@", @2);
    RLMAssertCount(AllPrimitiveArrays, 1U, @"floatObj.@min == %@", @2.2f);
    RLMAssertCount(AllPrimitiveArrays, 1U, @"doubleObj.@min == %@", @2.2);
    RLMAssertCount(AllPrimitiveArrays, 1U, @"dateObj.@min == %@", date(1));
    RLMAssertCount(AllPrimitiveArrays, 1U, @"decimalObj.@min == %@", decimal128(2));
    RLMAssertCount(AllPrimitiveArrays, 1U, @"anyIntObj.@min == %@", @2);
    RLMAssertCount(AllPrimitiveArrays, 1U, @"anyFloatObj.@min == %@", @2.2f);
    RLMAssertCount(AllPrimitiveArrays, 1U, @"anyDoubleObj.@min == %@", @2.2);
    RLMAssertCount(AllPrimitiveArrays, 1U, @"anyDateObj.@min == %@", date(1));
    RLMAssertCount(AllPrimitiveArrays, 1U, @"anyDecimalObj.@min == %@", decimal128(2));
    RLMAssertCount(AllOptionalPrimitiveArrays, 1U, @"intObj.@min == %@", @2);
    RLMAssertCount(AllOptionalPrimitiveArrays, 1U, @"floatObj.@min == %@", @2.2f);
    RLMAssertCount(AllOptionalPrimitiveArrays, 1U, @"doubleObj.@min == %@", @2.2);
    RLMAssertCount(AllOptionalPrimitiveArrays, 1U, @"dateObj.@min == %@", date(1));
    RLMAssertCount(AllOptionalPrimitiveArrays, 1U, @"decimalObj.@min == %@", decimal128(2));
    RLMAssertCount(AllPrimitiveArrays, 0U, @"intObj.@min == %@", @3);
    RLMAssertCount(AllPrimitiveArrays, 0U, @"floatObj.@min == %@", @3.3f);
    RLMAssertCount(AllPrimitiveArrays, 0U, @"doubleObj.@min == %@", @3.3);
    RLMAssertCount(AllPrimitiveArrays, 0U, @"dateObj.@min == %@", date(2));
    RLMAssertCount(AllPrimitiveArrays, 0U, @"decimalObj.@min == %@", decimal128(3));
    RLMAssertCount(AllPrimitiveArrays, 0U, @"anyIntObj.@min == %@", @3);
    RLMAssertCount(AllPrimitiveArrays, 0U, @"anyFloatObj.@min == %@", @3.3f);
    RLMAssertCount(AllPrimitiveArrays, 0U, @"anyDoubleObj.@min == %@", @3.3);
    RLMAssertCount(AllPrimitiveArrays, 0U, @"anyDateObj.@min == %@", date(2));
    RLMAssertCount(AllPrimitiveArrays, 0U, @"anyDecimalObj.@min == %@", decimal128(3));
    RLMAssertCount(AllOptionalPrimitiveArrays, 0U, @"intObj.@min == %@", @3);
    RLMAssertCount(AllOptionalPrimitiveArrays, 0U, @"floatObj.@min == %@", @3.3f);
    RLMAssertCount(AllOptionalPrimitiveArrays, 0U, @"doubleObj.@min == %@", @3.3);
    RLMAssertCount(AllOptionalPrimitiveArrays, 0U, @"dateObj.@min == %@", date(2));
    RLMAssertCount(AllOptionalPrimitiveArrays, 0U, @"decimalObj.@min == %@", decimal128(3));

    [self createObjectWithValueIndex:1];

    // One object where v0 is min and one with v1
    RLMAssertCount(AllPrimitiveArrays, 1U, @"intObj.@min == %@", @2);
    RLMAssertCount(AllPrimitiveArrays, 1U, @"floatObj.@min == %@", @2.2f);
    RLMAssertCount(AllPrimitiveArrays, 1U, @"doubleObj.@min == %@", @2.2);
    RLMAssertCount(AllPrimitiveArrays, 1U, @"dateObj.@min == %@", date(1));
    RLMAssertCount(AllPrimitiveArrays, 1U, @"decimalObj.@min == %@", decimal128(2));
    RLMAssertCount(AllPrimitiveArrays, 1U, @"anyIntObj.@min == %@", @2);
    RLMAssertCount(AllPrimitiveArrays, 1U, @"anyFloatObj.@min == %@", @2.2f);
    RLMAssertCount(AllPrimitiveArrays, 1U, @"anyDoubleObj.@min == %@", @2.2);
    RLMAssertCount(AllPrimitiveArrays, 1U, @"anyDateObj.@min == %@", date(1));
    RLMAssertCount(AllPrimitiveArrays, 1U, @"anyDecimalObj.@min == %@", decimal128(2));
    RLMAssertCount(AllOptionalPrimitiveArrays, 1U, @"intObj.@min == %@", @2);
    RLMAssertCount(AllOptionalPrimitiveArrays, 1U, @"floatObj.@min == %@", @2.2f);
    RLMAssertCount(AllOptionalPrimitiveArrays, 1U, @"doubleObj.@min == %@", @2.2);
    RLMAssertCount(AllOptionalPrimitiveArrays, 1U, @"dateObj.@min == %@", date(1));
    RLMAssertCount(AllOptionalPrimitiveArrays, 1U, @"decimalObj.@min == %@", decimal128(2));
    RLMAssertCount(AllPrimitiveArrays, 1U, @"intObj.@min == %@", @3);
    RLMAssertCount(AllPrimitiveArrays, 1U, @"floatObj.@min == %@", @3.3f);
    RLMAssertCount(AllPrimitiveArrays, 1U, @"doubleObj.@min == %@", @3.3);
    RLMAssertCount(AllPrimitiveArrays, 1U, @"dateObj.@min == %@", date(2));
    RLMAssertCount(AllPrimitiveArrays, 1U, @"decimalObj.@min == %@", decimal128(3));
    RLMAssertCount(AllPrimitiveArrays, 1U, @"anyIntObj.@min == %@", @3);
    RLMAssertCount(AllPrimitiveArrays, 1U, @"anyFloatObj.@min == %@", @3.3f);
    RLMAssertCount(AllPrimitiveArrays, 1U, @"anyDoubleObj.@min == %@", @3.3);
    RLMAssertCount(AllPrimitiveArrays, 1U, @"anyDateObj.@min == %@", date(2));
    RLMAssertCount(AllPrimitiveArrays, 1U, @"anyDecimalObj.@min == %@", decimal128(3));
    RLMAssertCount(AllOptionalPrimitiveArrays, 1U, @"intObj.@min == %@", @3);
    RLMAssertCount(AllOptionalPrimitiveArrays, 1U, @"floatObj.@min == %@", @3.3f);
    RLMAssertCount(AllOptionalPrimitiveArrays, 1U, @"doubleObj.@min == %@", @3.3);
    RLMAssertCount(AllOptionalPrimitiveArrays, 1U, @"dateObj.@min == %@", date(2));
    RLMAssertCount(AllOptionalPrimitiveArrays, 1U, @"decimalObj.@min == %@", decimal128(3));

    [AllPrimitiveArrays createInRealm:realm withValue:@{
        @"intObj": @[@3, @2],
        @"floatObj": @[@3.3f, @2.2f],
        @"doubleObj": @[@3.3, @2.2],
        @"dateObj": @[date(2), date(1)],
        @"decimalObj": @[decimal128(3), decimal128(2)],
        @"anyIntObj": @[@3, @2],
        @"anyFloatObj": @[@3.3f, @2.2f],
        @"anyDoubleObj": @[@3.3, @2.2],
        @"anyDateObj": @[date(2), date(1)],
        @"anyDecimalObj": @[decimal128(3), decimal128(2)],
    }];
    [AllOptionalPrimitiveArrays createInRealm:realm withValue:@{
        @"intObj": @[@3, @2],
        @"floatObj": @[@3.3f, @2.2f],
        @"doubleObj": @[@3.3, @2.2],
        @"dateObj": @[date(2), date(1)],
        @"decimalObj": @[decimal128(3), decimal128(2)],
    }];

    // New object with both v0 and v1 matches v0 but not v1
    RLMAssertCount(AllPrimitiveArrays, 2U, @"intObj.@min == %@", @2);
    RLMAssertCount(AllPrimitiveArrays, 2U, @"floatObj.@min == %@", @2.2f);
    RLMAssertCount(AllPrimitiveArrays, 2U, @"doubleObj.@min == %@", @2.2);
    RLMAssertCount(AllPrimitiveArrays, 2U, @"dateObj.@min == %@", date(1));
    RLMAssertCount(AllPrimitiveArrays, 2U, @"decimalObj.@min == %@", decimal128(2));
    RLMAssertCount(AllPrimitiveArrays, 2U, @"anyIntObj.@min == %@", @2);
    RLMAssertCount(AllPrimitiveArrays, 2U, @"anyFloatObj.@min == %@", @2.2f);
    RLMAssertCount(AllPrimitiveArrays, 2U, @"anyDoubleObj.@min == %@", @2.2);
    RLMAssertCount(AllPrimitiveArrays, 2U, @"anyDateObj.@min == %@", date(1));
    RLMAssertCount(AllPrimitiveArrays, 2U, @"anyDecimalObj.@min == %@", decimal128(2));
    RLMAssertCount(AllOptionalPrimitiveArrays, 2U, @"intObj.@min == %@", @2);
    RLMAssertCount(AllOptionalPrimitiveArrays, 2U, @"floatObj.@min == %@", @2.2f);
    RLMAssertCount(AllOptionalPrimitiveArrays, 2U, @"doubleObj.@min == %@", @2.2);
    RLMAssertCount(AllOptionalPrimitiveArrays, 2U, @"dateObj.@min == %@", date(1));
    RLMAssertCount(AllOptionalPrimitiveArrays, 2U, @"decimalObj.@min == %@", decimal128(2));
    RLMAssertCount(AllPrimitiveArrays, 1U, @"intObj.@min == %@", @3);
    RLMAssertCount(AllPrimitiveArrays, 1U, @"floatObj.@min == %@", @3.3f);
    RLMAssertCount(AllPrimitiveArrays, 1U, @"doubleObj.@min == %@", @3.3);
    RLMAssertCount(AllPrimitiveArrays, 1U, @"dateObj.@min == %@", date(2));
    RLMAssertCount(AllPrimitiveArrays, 1U, @"decimalObj.@min == %@", decimal128(3));
    RLMAssertCount(AllPrimitiveArrays, 1U, @"anyIntObj.@min == %@", @3);
    RLMAssertCount(AllPrimitiveArrays, 1U, @"anyFloatObj.@min == %@", @3.3f);
    RLMAssertCount(AllPrimitiveArrays, 1U, @"anyDoubleObj.@min == %@", @3.3);
    RLMAssertCount(AllPrimitiveArrays, 1U, @"anyDateObj.@min == %@", date(2));
    RLMAssertCount(AllPrimitiveArrays, 1U, @"anyDecimalObj.@min == %@", decimal128(3));
    RLMAssertCount(AllOptionalPrimitiveArrays, 1U, @"intObj.@min == %@", @3);
    RLMAssertCount(AllOptionalPrimitiveArrays, 1U, @"floatObj.@min == %@", @3.3f);
    RLMAssertCount(AllOptionalPrimitiveArrays, 1U, @"doubleObj.@min == %@", @3.3);
    RLMAssertCount(AllOptionalPrimitiveArrays, 1U, @"dateObj.@min == %@", date(2));
    RLMAssertCount(AllOptionalPrimitiveArrays, 1U, @"decimalObj.@min == %@", decimal128(3));
}

- (void)testQueryMax {
    [realm deleteAllObjects];

    RLMAssertThrowsWithReason(([AllPrimitiveArrays objectsInRealm:realm where:@"boolObj.@max = %@", @NO]),
                              @"@max can only be applied to a numeric property.");
    RLMAssertThrowsWithReason(([AllPrimitiveArrays objectsInRealm:realm where:@"stringObj.@max = %@", @"a"]),
                              @"@max can only be applied to a numeric property.");
    RLMAssertThrowsWithReason(([AllPrimitiveArrays objectsInRealm:realm where:@"dataObj.@max = %@", data(1)]),
                              @"@max can only be applied to a numeric property.");
    RLMAssertThrowsWithReason(([AllPrimitiveArrays objectsInRealm:realm where:@"objectIdObj.@max = %@", objectId(1)]),
                              @"@max can only be applied to a numeric property.");
    RLMAssertThrowsWithReason(([AllPrimitiveArrays objectsInRealm:realm where:@"uuidObj.@max = %@", uuid(@"00000000-0000-0000-0000-000000000000")]),
                              @"@max can only be applied to a numeric property.");
    RLMAssertThrowsWithReason(([AllOptionalPrimitiveArrays objectsInRealm:realm where:@"boolObj.@max = %@", @NO]),
                              @"@max can only be applied to a numeric property.");
    RLMAssertThrowsWithReason(([AllOptionalPrimitiveArrays objectsInRealm:realm where:@"stringObj.@max = %@", @"a"]),
                              @"@max can only be applied to a numeric property.");
    RLMAssertThrowsWithReason(([AllOptionalPrimitiveArrays objectsInRealm:realm where:@"dataObj.@max = %@", data(1)]),
                              @"@max can only be applied to a numeric property.");
    RLMAssertThrowsWithReason(([AllOptionalPrimitiveArrays objectsInRealm:realm where:@"objectIdObj.@max = %@", objectId(1)]),
                              @"@max can only be applied to a numeric property.");
    RLMAssertThrowsWithReason(([AllOptionalPrimitiveArrays objectsInRealm:realm where:@"uuidObj.@max = %@", uuid(@"00000000-0000-0000-0000-000000000000")]),
                              @"@max can only be applied to a numeric property.");
    RLMAssertThrowsWithReason(([AllPrimitiveArrays objectsInRealm:realm where:@"intObj.@max = %@", @"a"]),
                              @"@max on a property of type int cannot be compared with 'a'");
    RLMAssertThrowsWithReason(([AllPrimitiveArrays objectsInRealm:realm where:@"floatObj.@max = %@", @"a"]),
                              @"@max on a property of type float cannot be compared with 'a'");
    RLMAssertThrowsWithReason(([AllPrimitiveArrays objectsInRealm:realm where:@"doubleObj.@max = %@", @"a"]),
                              @"@max on a property of type double cannot be compared with 'a'");
    RLMAssertThrowsWithReason(([AllPrimitiveArrays objectsInRealm:realm where:@"dateObj.@max = %@", @"a"]),
                              @"@max on a property of type date cannot be compared with 'a'");
    RLMAssertThrowsWithReason(([AllPrimitiveArrays objectsInRealm:realm where:@"decimalObj.@max = %@", @"a"]),
                              @"@max on a property of type decimal128 cannot be compared with 'a'");
    RLMAssertThrowsWithReason(([AllOptionalPrimitiveArrays objectsInRealm:realm where:@"intObj.@max = %@", @"a"]),
                              @"@max on a property of type int cannot be compared with 'a'");
    RLMAssertThrowsWithReason(([AllOptionalPrimitiveArrays objectsInRealm:realm where:@"floatObj.@max = %@", @"a"]),
                              @"@max on a property of type float cannot be compared with 'a'");
    RLMAssertThrowsWithReason(([AllOptionalPrimitiveArrays objectsInRealm:realm where:@"doubleObj.@max = %@", @"a"]),
                              @"@max on a property of type double cannot be compared with 'a'");
    RLMAssertThrowsWithReason(([AllOptionalPrimitiveArrays objectsInRealm:realm where:@"dateObj.@max = %@", @"a"]),
                              @"@max on a property of type date cannot be compared with 'a'");
    RLMAssertThrowsWithReason(([AllOptionalPrimitiveArrays objectsInRealm:realm where:@"decimalObj.@max = %@", @"a"]),
                              @"@max on a property of type decimal128 cannot be compared with 'a'");
    RLMAssertThrowsWithReason(([AllPrimitiveArrays objectsInRealm:realm where:@"intObj.@max.prop = %@", @"a"]),
                              @"Property 'intObj' is not a link in object of type 'AllPrimitiveArrays'");
    RLMAssertThrowsWithReason(([AllPrimitiveArrays objectsInRealm:realm where:@"floatObj.@max.prop = %@", @"a"]),
                              @"Property 'floatObj' is not a link in object of type 'AllPrimitiveArrays'");
    RLMAssertThrowsWithReason(([AllPrimitiveArrays objectsInRealm:realm where:@"doubleObj.@max.prop = %@", @"a"]),
                              @"Property 'doubleObj' is not a link in object of type 'AllPrimitiveArrays'");
    RLMAssertThrowsWithReason(([AllPrimitiveArrays objectsInRealm:realm where:@"dateObj.@max.prop = %@", @"a"]),
                              @"Property 'dateObj' is not a link in object of type 'AllPrimitiveArrays'");
    RLMAssertThrowsWithReason(([AllPrimitiveArrays objectsInRealm:realm where:@"decimalObj.@max.prop = %@", @"a"]),
                              @"Property 'decimalObj' is not a link in object of type 'AllPrimitiveArrays'");
    RLMAssertThrowsWithReason(([AllPrimitiveArrays objectsInRealm:realm where:@"anyIntObj.@max.prop = %@", @"a"]),
                              @"Property 'anyIntObj' is not a link in object of type 'AllPrimitiveArrays'");
    RLMAssertThrowsWithReason(([AllPrimitiveArrays objectsInRealm:realm where:@"anyFloatObj.@max.prop = %@", @"a"]),
                              @"Property 'anyFloatObj' is not a link in object of type 'AllPrimitiveArrays'");
    RLMAssertThrowsWithReason(([AllPrimitiveArrays objectsInRealm:realm where:@"anyDoubleObj.@max.prop = %@", @"a"]),
                              @"Property 'anyDoubleObj' is not a link in object of type 'AllPrimitiveArrays'");
    RLMAssertThrowsWithReason(([AllPrimitiveArrays objectsInRealm:realm where:@"anyDateObj.@max.prop = %@", @"a"]),
                              @"Property 'anyDateObj' is not a link in object of type 'AllPrimitiveArrays'");
    RLMAssertThrowsWithReason(([AllPrimitiveArrays objectsInRealm:realm where:@"anyDecimalObj.@max.prop = %@", @"a"]),
                              @"Property 'anyDecimalObj' is not a link in object of type 'AllPrimitiveArrays'");
    RLMAssertThrowsWithReason(([AllOptionalPrimitiveArrays objectsInRealm:realm where:@"intObj.@max.prop = %@", @"a"]),
                              @"Property 'intObj' is not a link in object of type 'AllOptionalPrimitiveArrays'");
    RLMAssertThrowsWithReason(([AllOptionalPrimitiveArrays objectsInRealm:realm where:@"floatObj.@max.prop = %@", @"a"]),
                              @"Property 'floatObj' is not a link in object of type 'AllOptionalPrimitiveArrays'");
    RLMAssertThrowsWithReason(([AllOptionalPrimitiveArrays objectsInRealm:realm where:@"doubleObj.@max.prop = %@", @"a"]),
                              @"Property 'doubleObj' is not a link in object of type 'AllOptionalPrimitiveArrays'");
    RLMAssertThrowsWithReason(([AllOptionalPrimitiveArrays objectsInRealm:realm where:@"dateObj.@max.prop = %@", @"a"]),
                              @"Property 'dateObj' is not a link in object of type 'AllOptionalPrimitiveArrays'");
    RLMAssertThrowsWithReason(([AllOptionalPrimitiveArrays objectsInRealm:realm where:@"decimalObj.@max.prop = %@", @"a"]),
                              @"Property 'decimalObj' is not a link in object of type 'AllOptionalPrimitiveArrays'");

    // No objects, so count is zero
    RLMAssertCount(AllPrimitiveArrays, 0U, @"intObj.@max == %@", @2);
    RLMAssertCount(AllPrimitiveArrays, 0U, @"floatObj.@max == %@", @2.2f);
    RLMAssertCount(AllPrimitiveArrays, 0U, @"doubleObj.@max == %@", @2.2);
    RLMAssertCount(AllPrimitiveArrays, 0U, @"dateObj.@max == %@", date(1));
    RLMAssertCount(AllPrimitiveArrays, 0U, @"decimalObj.@max == %@", decimal128(2));
    RLMAssertCount(AllPrimitiveArrays, 0U, @"anyIntObj.@max == %@", @2);
    RLMAssertCount(AllPrimitiveArrays, 0U, @"anyFloatObj.@max == %@", @2.2f);
    RLMAssertCount(AllPrimitiveArrays, 0U, @"anyDoubleObj.@max == %@", @2.2);
    RLMAssertCount(AllPrimitiveArrays, 0U, @"anyDateObj.@max == %@", date(1));
    RLMAssertCount(AllPrimitiveArrays, 0U, @"anyDecimalObj.@max == %@", decimal128(2));
    RLMAssertCount(AllOptionalPrimitiveArrays, 0U, @"intObj.@max == %@", @2);
    RLMAssertCount(AllOptionalPrimitiveArrays, 0U, @"floatObj.@max == %@", @2.2f);
    RLMAssertCount(AllOptionalPrimitiveArrays, 0U, @"doubleObj.@max == %@", @2.2);
    RLMAssertCount(AllOptionalPrimitiveArrays, 0U, @"dateObj.@max == %@", date(1));
    RLMAssertCount(AllOptionalPrimitiveArrays, 0U, @"decimalObj.@max == %@", decimal128(2));

    [AllPrimitiveArrays createInRealm:realm withValue:@{}];
    [AllOptionalPrimitiveArrays createInRealm:realm withValue:@{}];

    // Only empty arrays, so count is zero
    RLMAssertCount(AllPrimitiveArrays, 0U, @"intObj.@max == %@", @2);
    RLMAssertCount(AllPrimitiveArrays, 0U, @"floatObj.@max == %@", @2.2f);
    RLMAssertCount(AllPrimitiveArrays, 0U, @"doubleObj.@max == %@", @2.2);
    RLMAssertCount(AllPrimitiveArrays, 0U, @"dateObj.@max == %@", date(1));
    RLMAssertCount(AllPrimitiveArrays, 0U, @"decimalObj.@max == %@", decimal128(2));
    RLMAssertCount(AllPrimitiveArrays, 0U, @"anyIntObj.@max == %@", @2);
    RLMAssertCount(AllPrimitiveArrays, 0U, @"anyFloatObj.@max == %@", @2.2f);
    RLMAssertCount(AllPrimitiveArrays, 0U, @"anyDoubleObj.@max == %@", @2.2);
    RLMAssertCount(AllPrimitiveArrays, 0U, @"anyDateObj.@max == %@", date(1));
    RLMAssertCount(AllPrimitiveArrays, 0U, @"anyDecimalObj.@max == %@", decimal128(2));
    RLMAssertCount(AllOptionalPrimitiveArrays, 0U, @"intObj.@max == %@", @2);
    RLMAssertCount(AllOptionalPrimitiveArrays, 0U, @"floatObj.@max == %@", @2.2f);
    RLMAssertCount(AllOptionalPrimitiveArrays, 0U, @"doubleObj.@max == %@", @2.2);
    RLMAssertCount(AllOptionalPrimitiveArrays, 0U, @"dateObj.@max == %@", date(1));
    RLMAssertCount(AllOptionalPrimitiveArrays, 0U, @"decimalObj.@max == %@", decimal128(2));
    RLMAssertCount(AllPrimitiveArrays, 0U, @"intObj.@max == %@", @3);
    RLMAssertCount(AllPrimitiveArrays, 0U, @"floatObj.@max == %@", @3.3f);
    RLMAssertCount(AllPrimitiveArrays, 0U, @"doubleObj.@max == %@", @3.3);
    RLMAssertCount(AllPrimitiveArrays, 0U, @"dateObj.@max == %@", date(2));
    RLMAssertCount(AllPrimitiveArrays, 0U, @"decimalObj.@max == %@", decimal128(3));
    RLMAssertCount(AllPrimitiveArrays, 0U, @"anyIntObj.@max == %@", @3);
    RLMAssertCount(AllPrimitiveArrays, 0U, @"anyFloatObj.@max == %@", @3.3f);
    RLMAssertCount(AllPrimitiveArrays, 0U, @"anyDoubleObj.@max == %@", @3.3);
    RLMAssertCount(AllPrimitiveArrays, 0U, @"anyDateObj.@max == %@", date(2));
    RLMAssertCount(AllPrimitiveArrays, 0U, @"anyDecimalObj.@max == %@", decimal128(3));
    RLMAssertCount(AllOptionalPrimitiveArrays, 0U, @"intObj.@max == %@", @3);
    RLMAssertCount(AllOptionalPrimitiveArrays, 0U, @"floatObj.@max == %@", @3.3f);
    RLMAssertCount(AllOptionalPrimitiveArrays, 0U, @"doubleObj.@max == %@", @3.3);
    RLMAssertCount(AllOptionalPrimitiveArrays, 0U, @"dateObj.@max == %@", date(2));
    RLMAssertCount(AllOptionalPrimitiveArrays, 0U, @"decimalObj.@max == %@", decimal128(3));

    RLMAssertCount(AllPrimitiveArrays, 1U, @"intObj.@max == nil");
    RLMAssertCount(AllPrimitiveArrays, 1U, @"floatObj.@max == nil");
    RLMAssertCount(AllPrimitiveArrays, 1U, @"doubleObj.@max == nil");
    RLMAssertCount(AllPrimitiveArrays, 1U, @"dateObj.@max == nil");
    RLMAssertCount(AllPrimitiveArrays, 1U, @"decimalObj.@max == nil");
    RLMAssertCount(AllPrimitiveArrays, 1U, @"anyIntObj.@max == nil");
    RLMAssertCount(AllPrimitiveArrays, 1U, @"anyFloatObj.@max == nil");
    RLMAssertCount(AllPrimitiveArrays, 1U, @"anyDoubleObj.@max == nil");
    RLMAssertCount(AllPrimitiveArrays, 1U, @"anyDateObj.@max == nil");
    RLMAssertCount(AllPrimitiveArrays, 1U, @"anyDecimalObj.@max == nil");
    RLMAssertCount(AllOptionalPrimitiveArrays, 1U, @"intObj.@max == nil");
    RLMAssertCount(AllOptionalPrimitiveArrays, 1U, @"floatObj.@max == nil");
    RLMAssertCount(AllOptionalPrimitiveArrays, 1U, @"doubleObj.@max == nil");
    RLMAssertCount(AllOptionalPrimitiveArrays, 1U, @"dateObj.@max == nil");
    RLMAssertCount(AllOptionalPrimitiveArrays, 1U, @"decimalObj.@max == nil");
    RLMAssertCount(AllPrimitiveArrays, 1U, @"intObj.@max == %@", NSNull.null);
    RLMAssertCount(AllPrimitiveArrays, 1U, @"floatObj.@max == %@", NSNull.null);
    RLMAssertCount(AllPrimitiveArrays, 1U, @"doubleObj.@max == %@", NSNull.null);
    RLMAssertCount(AllPrimitiveArrays, 1U, @"dateObj.@max == %@", NSNull.null);
    RLMAssertCount(AllPrimitiveArrays, 1U, @"decimalObj.@max == %@", NSNull.null);
    RLMAssertCount(AllPrimitiveArrays, 1U, @"anyIntObj.@max == %@", NSNull.null);
    RLMAssertCount(AllPrimitiveArrays, 1U, @"anyFloatObj.@max == %@", NSNull.null);
    RLMAssertCount(AllPrimitiveArrays, 1U, @"anyDoubleObj.@max == %@", NSNull.null);
    RLMAssertCount(AllPrimitiveArrays, 1U, @"anyDateObj.@max == %@", NSNull.null);
    RLMAssertCount(AllPrimitiveArrays, 1U, @"anyDecimalObj.@max == %@", NSNull.null);
    RLMAssertCount(AllOptionalPrimitiveArrays, 1U, @"intObj.@max == %@", NSNull.null);
    RLMAssertCount(AllOptionalPrimitiveArrays, 1U, @"floatObj.@max == %@", NSNull.null);
    RLMAssertCount(AllOptionalPrimitiveArrays, 1U, @"doubleObj.@max == %@", NSNull.null);
    RLMAssertCount(AllOptionalPrimitiveArrays, 1U, @"dateObj.@max == %@", NSNull.null);
    RLMAssertCount(AllOptionalPrimitiveArrays, 1U, @"decimalObj.@max == %@", NSNull.null);

    [self createObjectWithValueIndex:0];

    // One object where v0 is min and zero with v1
    RLMAssertCount(AllPrimitiveArrays, 1U, @"intObj.@max == %@", @2);
    RLMAssertCount(AllPrimitiveArrays, 1U, @"floatObj.@max == %@", @2.2f);
    RLMAssertCount(AllPrimitiveArrays, 1U, @"doubleObj.@max == %@", @2.2);
    RLMAssertCount(AllPrimitiveArrays, 1U, @"dateObj.@max == %@", date(1));
    RLMAssertCount(AllPrimitiveArrays, 1U, @"decimalObj.@max == %@", decimal128(2));
    RLMAssertCount(AllPrimitiveArrays, 1U, @"anyIntObj.@max == %@", @2);
    RLMAssertCount(AllPrimitiveArrays, 1U, @"anyFloatObj.@max == %@", @2.2f);
    RLMAssertCount(AllPrimitiveArrays, 1U, @"anyDoubleObj.@max == %@", @2.2);
    RLMAssertCount(AllPrimitiveArrays, 1U, @"anyDateObj.@max == %@", date(1));
    RLMAssertCount(AllPrimitiveArrays, 1U, @"anyDecimalObj.@max == %@", decimal128(2));
    RLMAssertCount(AllOptionalPrimitiveArrays, 1U, @"intObj.@max == %@", @2);
    RLMAssertCount(AllOptionalPrimitiveArrays, 1U, @"floatObj.@max == %@", @2.2f);
    RLMAssertCount(AllOptionalPrimitiveArrays, 1U, @"doubleObj.@max == %@", @2.2);
    RLMAssertCount(AllOptionalPrimitiveArrays, 1U, @"dateObj.@max == %@", date(1));
    RLMAssertCount(AllOptionalPrimitiveArrays, 1U, @"decimalObj.@max == %@", decimal128(2));
    RLMAssertCount(AllPrimitiveArrays, 0U, @"intObj.@max == %@", @3);
    RLMAssertCount(AllPrimitiveArrays, 0U, @"floatObj.@max == %@", @3.3f);
    RLMAssertCount(AllPrimitiveArrays, 0U, @"doubleObj.@max == %@", @3.3);
    RLMAssertCount(AllPrimitiveArrays, 0U, @"dateObj.@max == %@", date(2));
    RLMAssertCount(AllPrimitiveArrays, 0U, @"decimalObj.@max == %@", decimal128(3));
    RLMAssertCount(AllPrimitiveArrays, 0U, @"anyIntObj.@max == %@", @3);
    RLMAssertCount(AllPrimitiveArrays, 0U, @"anyFloatObj.@max == %@", @3.3f);
    RLMAssertCount(AllPrimitiveArrays, 0U, @"anyDoubleObj.@max == %@", @3.3);
    RLMAssertCount(AllPrimitiveArrays, 0U, @"anyDateObj.@max == %@", date(2));
    RLMAssertCount(AllPrimitiveArrays, 0U, @"anyDecimalObj.@max == %@", decimal128(3));
    RLMAssertCount(AllOptionalPrimitiveArrays, 0U, @"intObj.@max == %@", @3);
    RLMAssertCount(AllOptionalPrimitiveArrays, 0U, @"floatObj.@max == %@", @3.3f);
    RLMAssertCount(AllOptionalPrimitiveArrays, 0U, @"doubleObj.@max == %@", @3.3);
    RLMAssertCount(AllOptionalPrimitiveArrays, 0U, @"dateObj.@max == %@", date(2));
    RLMAssertCount(AllOptionalPrimitiveArrays, 0U, @"decimalObj.@max == %@", decimal128(3));

    [self createObjectWithValueIndex:1];

    // One object where v0 is min and one with v1
    RLMAssertCount(AllPrimitiveArrays, 1U, @"intObj.@max == %@", @2);
    RLMAssertCount(AllPrimitiveArrays, 1U, @"floatObj.@max == %@", @2.2f);
    RLMAssertCount(AllPrimitiveArrays, 1U, @"doubleObj.@max == %@", @2.2);
    RLMAssertCount(AllPrimitiveArrays, 1U, @"dateObj.@max == %@", date(1));
    RLMAssertCount(AllPrimitiveArrays, 1U, @"decimalObj.@max == %@", decimal128(2));
    RLMAssertCount(AllPrimitiveArrays, 1U, @"anyIntObj.@max == %@", @2);
    RLMAssertCount(AllPrimitiveArrays, 1U, @"anyFloatObj.@max == %@", @2.2f);
    RLMAssertCount(AllPrimitiveArrays, 1U, @"anyDoubleObj.@max == %@", @2.2);
    RLMAssertCount(AllPrimitiveArrays, 1U, @"anyDateObj.@max == %@", date(1));
    RLMAssertCount(AllPrimitiveArrays, 1U, @"anyDecimalObj.@max == %@", decimal128(2));
    RLMAssertCount(AllOptionalPrimitiveArrays, 1U, @"intObj.@max == %@", @2);
    RLMAssertCount(AllOptionalPrimitiveArrays, 1U, @"floatObj.@max == %@", @2.2f);
    RLMAssertCount(AllOptionalPrimitiveArrays, 1U, @"doubleObj.@max == %@", @2.2);
    RLMAssertCount(AllOptionalPrimitiveArrays, 1U, @"dateObj.@max == %@", date(1));
    RLMAssertCount(AllOptionalPrimitiveArrays, 1U, @"decimalObj.@max == %@", decimal128(2));
    RLMAssertCount(AllPrimitiveArrays, 1U, @"intObj.@max == %@", @3);
    RLMAssertCount(AllPrimitiveArrays, 1U, @"floatObj.@max == %@", @3.3f);
    RLMAssertCount(AllPrimitiveArrays, 1U, @"doubleObj.@max == %@", @3.3);
    RLMAssertCount(AllPrimitiveArrays, 1U, @"dateObj.@max == %@", date(2));
    RLMAssertCount(AllPrimitiveArrays, 1U, @"decimalObj.@max == %@", decimal128(3));
    RLMAssertCount(AllPrimitiveArrays, 1U, @"anyIntObj.@max == %@", @3);
    RLMAssertCount(AllPrimitiveArrays, 1U, @"anyFloatObj.@max == %@", @3.3f);
    RLMAssertCount(AllPrimitiveArrays, 1U, @"anyDoubleObj.@max == %@", @3.3);
    RLMAssertCount(AllPrimitiveArrays, 1U, @"anyDateObj.@max == %@", date(2));
    RLMAssertCount(AllPrimitiveArrays, 1U, @"anyDecimalObj.@max == %@", decimal128(3));
    RLMAssertCount(AllOptionalPrimitiveArrays, 1U, @"intObj.@max == %@", @3);
    RLMAssertCount(AllOptionalPrimitiveArrays, 1U, @"floatObj.@max == %@", @3.3f);
    RLMAssertCount(AllOptionalPrimitiveArrays, 1U, @"doubleObj.@max == %@", @3.3);
    RLMAssertCount(AllOptionalPrimitiveArrays, 1U, @"dateObj.@max == %@", date(2));
    RLMAssertCount(AllOptionalPrimitiveArrays, 1U, @"decimalObj.@max == %@", decimal128(3));

    [AllPrimitiveArrays createInRealm:realm withValue:@{
        @"intObj": @[@3, @2],
        @"floatObj": @[@3.3f, @2.2f],
        @"doubleObj": @[@3.3, @2.2],
        @"dateObj": @[date(2), date(1)],
        @"decimalObj": @[decimal128(3), decimal128(2)],
        @"anyIntObj": @[@3, @2],
        @"anyFloatObj": @[@3.3f, @2.2f],
        @"anyDoubleObj": @[@3.3, @2.2],
        @"anyDateObj": @[date(2), date(1)],
        @"anyDecimalObj": @[decimal128(3), decimal128(2)],
    }];
    [AllOptionalPrimitiveArrays createInRealm:realm withValue:@{
        @"intObj": @[@3, @2],
        @"floatObj": @[@3.3f, @2.2f],
        @"doubleObj": @[@3.3, @2.2],
        @"dateObj": @[date(2), date(1)],
        @"decimalObj": @[decimal128(3), decimal128(2)],
    }];

    // New object with both v0 and v1 matches v1 but not v0
    RLMAssertCount(AllPrimitiveArrays, 1U, @"intObj.@max == %@", @2);
    RLMAssertCount(AllPrimitiveArrays, 1U, @"floatObj.@max == %@", @2.2f);
    RLMAssertCount(AllPrimitiveArrays, 1U, @"doubleObj.@max == %@", @2.2);
    RLMAssertCount(AllPrimitiveArrays, 1U, @"dateObj.@max == %@", date(1));
    RLMAssertCount(AllPrimitiveArrays, 1U, @"decimalObj.@max == %@", decimal128(2));
    RLMAssertCount(AllPrimitiveArrays, 1U, @"anyIntObj.@max == %@", @2);
    RLMAssertCount(AllPrimitiveArrays, 1U, @"anyFloatObj.@max == %@", @2.2f);
    RLMAssertCount(AllPrimitiveArrays, 1U, @"anyDoubleObj.@max == %@", @2.2);
    RLMAssertCount(AllPrimitiveArrays, 1U, @"anyDateObj.@max == %@", date(1));
    RLMAssertCount(AllPrimitiveArrays, 1U, @"anyDecimalObj.@max == %@", decimal128(2));
    RLMAssertCount(AllOptionalPrimitiveArrays, 1U, @"intObj.@max == %@", @2);
    RLMAssertCount(AllOptionalPrimitiveArrays, 1U, @"floatObj.@max == %@", @2.2f);
    RLMAssertCount(AllOptionalPrimitiveArrays, 1U, @"doubleObj.@max == %@", @2.2);
    RLMAssertCount(AllOptionalPrimitiveArrays, 1U, @"dateObj.@max == %@", date(1));
    RLMAssertCount(AllOptionalPrimitiveArrays, 1U, @"decimalObj.@max == %@", decimal128(2));
    RLMAssertCount(AllPrimitiveArrays, 2U, @"intObj.@max == %@", @3);
    RLMAssertCount(AllPrimitiveArrays, 2U, @"floatObj.@max == %@", @3.3f);
    RLMAssertCount(AllPrimitiveArrays, 2U, @"doubleObj.@max == %@", @3.3);
    RLMAssertCount(AllPrimitiveArrays, 2U, @"dateObj.@max == %@", date(2));
    RLMAssertCount(AllPrimitiveArrays, 2U, @"decimalObj.@max == %@", decimal128(3));
    RLMAssertCount(AllPrimitiveArrays, 2U, @"anyIntObj.@max == %@", @3);
    RLMAssertCount(AllPrimitiveArrays, 2U, @"anyFloatObj.@max == %@", @3.3f);
    RLMAssertCount(AllPrimitiveArrays, 2U, @"anyDoubleObj.@max == %@", @3.3);
    RLMAssertCount(AllPrimitiveArrays, 2U, @"anyDateObj.@max == %@", date(2));
    RLMAssertCount(AllPrimitiveArrays, 2U, @"anyDecimalObj.@max == %@", decimal128(3));
    RLMAssertCount(AllOptionalPrimitiveArrays, 2U, @"intObj.@max == %@", @3);
    RLMAssertCount(AllOptionalPrimitiveArrays, 2U, @"floatObj.@max == %@", @3.3f);
    RLMAssertCount(AllOptionalPrimitiveArrays, 2U, @"doubleObj.@max == %@", @3.3);
    RLMAssertCount(AllOptionalPrimitiveArrays, 2U, @"dateObj.@max == %@", date(2));
    RLMAssertCount(AllOptionalPrimitiveArrays, 2U, @"decimalObj.@max == %@", decimal128(3));
}

- (void)testQueryBasicOperatorsOverLink {
    [realm deleteAllObjects];

    RLMAssertCount(LinkToAllPrimitiveArrays, 0, @"ANY link.boolObj = %@", @NO);
    RLMAssertCount(LinkToAllPrimitiveArrays, 0, @"ANY link.intObj = %@", @2);
    RLMAssertCount(LinkToAllPrimitiveArrays, 0, @"ANY link.floatObj = %@", @2.2f);
    RLMAssertCount(LinkToAllPrimitiveArrays, 0, @"ANY link.doubleObj = %@", @2.2);
    RLMAssertCount(LinkToAllPrimitiveArrays, 0, @"ANY link.stringObj = %@", @"a");
    RLMAssertCount(LinkToAllPrimitiveArrays, 0, @"ANY link.dataObj = %@", data(1));
    RLMAssertCount(LinkToAllPrimitiveArrays, 0, @"ANY link.dateObj = %@", date(1));
    RLMAssertCount(LinkToAllPrimitiveArrays, 0, @"ANY link.decimalObj = %@", decimal128(2));
    RLMAssertCount(LinkToAllPrimitiveArrays, 0, @"ANY link.objectIdObj = %@", objectId(1));
    RLMAssertCount(LinkToAllPrimitiveArrays, 0, @"ANY link.uuidObj = %@", uuid(@"00000000-0000-0000-0000-000000000000"));
    RLMAssertCount(LinkToAllPrimitiveArrays, 0, @"ANY link.anyBoolObj = %@", @NO);
    RLMAssertCount(LinkToAllPrimitiveArrays, 0, @"ANY link.anyIntObj = %@", @2);
    RLMAssertCount(LinkToAllPrimitiveArrays, 0, @"ANY link.anyFloatObj = %@", @2.2f);
    RLMAssertCount(LinkToAllPrimitiveArrays, 0, @"ANY link.anyDoubleObj = %@", @2.2);
    RLMAssertCount(LinkToAllPrimitiveArrays, 0, @"ANY link.anyStringObj = %@", @"a");
    RLMAssertCount(LinkToAllPrimitiveArrays, 0, @"ANY link.anyDataObj = %@", data(1));
    RLMAssertCount(LinkToAllPrimitiveArrays, 0, @"ANY link.anyDateObj = %@", date(1));
    RLMAssertCount(LinkToAllPrimitiveArrays, 0, @"ANY link.anyDecimalObj = %@", decimal128(2));
    RLMAssertCount(LinkToAllPrimitiveArrays, 0, @"ANY link.anyObjectIdObj = %@", objectId(1));
    RLMAssertCount(LinkToAllPrimitiveArrays, 0, @"ANY link.anyUUIDObj = %@", uuid(@"00000000-0000-0000-0000-000000000000"));
    RLMAssertCount(LinkToAllOptionalPrimitiveArrays, 0, @"ANY link.boolObj = %@", @NO);
    RLMAssertCount(LinkToAllOptionalPrimitiveArrays, 0, @"ANY link.intObj = %@", @2);
    RLMAssertCount(LinkToAllOptionalPrimitiveArrays, 0, @"ANY link.floatObj = %@", @2.2f);
    RLMAssertCount(LinkToAllOptionalPrimitiveArrays, 0, @"ANY link.doubleObj = %@", @2.2);
    RLMAssertCount(LinkToAllOptionalPrimitiveArrays, 0, @"ANY link.stringObj = %@", @"a");
    RLMAssertCount(LinkToAllOptionalPrimitiveArrays, 0, @"ANY link.dataObj = %@", data(1));
    RLMAssertCount(LinkToAllOptionalPrimitiveArrays, 0, @"ANY link.dateObj = %@", date(1));
    RLMAssertCount(LinkToAllOptionalPrimitiveArrays, 0, @"ANY link.decimalObj = %@", decimal128(2));
    RLMAssertCount(LinkToAllOptionalPrimitiveArrays, 0, @"ANY link.objectIdObj = %@", objectId(1));
    RLMAssertCount(LinkToAllOptionalPrimitiveArrays, 0, @"ANY link.uuidObj = %@", uuid(@"00000000-0000-0000-0000-000000000000"));
    RLMAssertCount(LinkToAllPrimitiveArrays, 0, @"ANY link.boolObj != %@", @NO);
    RLMAssertCount(LinkToAllPrimitiveArrays, 0, @"ANY link.intObj != %@", @2);
    RLMAssertCount(LinkToAllPrimitiveArrays, 0, @"ANY link.floatObj != %@", @2.2f);
    RLMAssertCount(LinkToAllPrimitiveArrays, 0, @"ANY link.doubleObj != %@", @2.2);
    RLMAssertCount(LinkToAllPrimitiveArrays, 0, @"ANY link.stringObj != %@", @"a");
    RLMAssertCount(LinkToAllPrimitiveArrays, 0, @"ANY link.dataObj != %@", data(1));
    RLMAssertCount(LinkToAllPrimitiveArrays, 0, @"ANY link.dateObj != %@", date(1));
    RLMAssertCount(LinkToAllPrimitiveArrays, 0, @"ANY link.decimalObj != %@", decimal128(2));
    RLMAssertCount(LinkToAllPrimitiveArrays, 0, @"ANY link.objectIdObj != %@", objectId(1));
    RLMAssertCount(LinkToAllPrimitiveArrays, 0, @"ANY link.uuidObj != %@", uuid(@"00000000-0000-0000-0000-000000000000"));
    RLMAssertCount(LinkToAllPrimitiveArrays, 0, @"ANY link.anyBoolObj != %@", @NO);
    RLMAssertCount(LinkToAllPrimitiveArrays, 0, @"ANY link.anyIntObj != %@", @2);
    RLMAssertCount(LinkToAllPrimitiveArrays, 0, @"ANY link.anyFloatObj != %@", @2.2f);
    RLMAssertCount(LinkToAllPrimitiveArrays, 0, @"ANY link.anyDoubleObj != %@", @2.2);
    RLMAssertCount(LinkToAllPrimitiveArrays, 0, @"ANY link.anyStringObj != %@", @"a");
    RLMAssertCount(LinkToAllPrimitiveArrays, 0, @"ANY link.anyDataObj != %@", data(1));
    RLMAssertCount(LinkToAllPrimitiveArrays, 0, @"ANY link.anyDateObj != %@", date(1));
    RLMAssertCount(LinkToAllPrimitiveArrays, 0, @"ANY link.anyDecimalObj != %@", decimal128(2));
    RLMAssertCount(LinkToAllPrimitiveArrays, 0, @"ANY link.anyObjectIdObj != %@", objectId(1));
    RLMAssertCount(LinkToAllPrimitiveArrays, 0, @"ANY link.anyUUIDObj != %@", uuid(@"00000000-0000-0000-0000-000000000000"));
    RLMAssertCount(LinkToAllOptionalPrimitiveArrays, 0, @"ANY link.boolObj != %@", @NO);
    RLMAssertCount(LinkToAllOptionalPrimitiveArrays, 0, @"ANY link.intObj != %@", @2);
    RLMAssertCount(LinkToAllOptionalPrimitiveArrays, 0, @"ANY link.floatObj != %@", @2.2f);
    RLMAssertCount(LinkToAllOptionalPrimitiveArrays, 0, @"ANY link.doubleObj != %@", @2.2);
    RLMAssertCount(LinkToAllOptionalPrimitiveArrays, 0, @"ANY link.stringObj != %@", @"a");
    RLMAssertCount(LinkToAllOptionalPrimitiveArrays, 0, @"ANY link.dataObj != %@", data(1));
    RLMAssertCount(LinkToAllOptionalPrimitiveArrays, 0, @"ANY link.dateObj != %@", date(1));
    RLMAssertCount(LinkToAllOptionalPrimitiveArrays, 0, @"ANY link.decimalObj != %@", decimal128(2));
    RLMAssertCount(LinkToAllOptionalPrimitiveArrays, 0, @"ANY link.objectIdObj != %@", objectId(1));
    RLMAssertCount(LinkToAllOptionalPrimitiveArrays, 0, @"ANY link.uuidObj != %@", uuid(@"00000000-0000-0000-0000-000000000000"));
    RLMAssertCount(LinkToAllPrimitiveArrays, 0, @"ANY link.intObj > %@", @2);
    RLMAssertCount(LinkToAllPrimitiveArrays, 0, @"ANY link.floatObj > %@", @2.2f);
    RLMAssertCount(LinkToAllPrimitiveArrays, 0, @"ANY link.doubleObj > %@", @2.2);
    RLMAssertCount(LinkToAllPrimitiveArrays, 0, @"ANY link.dateObj > %@", date(1));
    RLMAssertCount(LinkToAllPrimitiveArrays, 0, @"ANY link.decimalObj > %@", decimal128(2));
    RLMAssertCount(LinkToAllPrimitiveArrays, 0, @"ANY link.anyIntObj > %@", @2);
    RLMAssertCount(LinkToAllPrimitiveArrays, 0, @"ANY link.anyFloatObj > %@", @2.2f);
    RLMAssertCount(LinkToAllPrimitiveArrays, 0, @"ANY link.anyDoubleObj > %@", @2.2);
    RLMAssertCount(LinkToAllPrimitiveArrays, 0, @"ANY link.anyDateObj > %@", date(1));
    RLMAssertCount(LinkToAllPrimitiveArrays, 0, @"ANY link.anyDecimalObj > %@", decimal128(2));
    RLMAssertCount(LinkToAllOptionalPrimitiveArrays, 0, @"ANY link.intObj > %@", @2);
    RLMAssertCount(LinkToAllOptionalPrimitiveArrays, 0, @"ANY link.floatObj > %@", @2.2f);
    RLMAssertCount(LinkToAllOptionalPrimitiveArrays, 0, @"ANY link.doubleObj > %@", @2.2);
    RLMAssertCount(LinkToAllOptionalPrimitiveArrays, 0, @"ANY link.dateObj > %@", date(1));
    RLMAssertCount(LinkToAllOptionalPrimitiveArrays, 0, @"ANY link.decimalObj > %@", decimal128(2));
    RLMAssertCount(LinkToAllPrimitiveArrays, 0, @"ANY link.intObj >= %@", @2);
    RLMAssertCount(LinkToAllPrimitiveArrays, 0, @"ANY link.floatObj >= %@", @2.2f);
    RLMAssertCount(LinkToAllPrimitiveArrays, 0, @"ANY link.doubleObj >= %@", @2.2);
    RLMAssertCount(LinkToAllPrimitiveArrays, 0, @"ANY link.dateObj >= %@", date(1));
    RLMAssertCount(LinkToAllPrimitiveArrays, 0, @"ANY link.decimalObj >= %@", decimal128(2));
    RLMAssertCount(LinkToAllPrimitiveArrays, 0, @"ANY link.anyIntObj >= %@", @2);
    RLMAssertCount(LinkToAllPrimitiveArrays, 0, @"ANY link.anyFloatObj >= %@", @2.2f);
    RLMAssertCount(LinkToAllPrimitiveArrays, 0, @"ANY link.anyDoubleObj >= %@", @2.2);
    RLMAssertCount(LinkToAllPrimitiveArrays, 0, @"ANY link.anyDateObj >= %@", date(1));
    RLMAssertCount(LinkToAllPrimitiveArrays, 0, @"ANY link.anyDecimalObj >= %@", decimal128(2));
    RLMAssertCount(LinkToAllOptionalPrimitiveArrays, 0, @"ANY link.intObj >= %@", @2);
    RLMAssertCount(LinkToAllOptionalPrimitiveArrays, 0, @"ANY link.floatObj >= %@", @2.2f);
    RLMAssertCount(LinkToAllOptionalPrimitiveArrays, 0, @"ANY link.doubleObj >= %@", @2.2);
    RLMAssertCount(LinkToAllOptionalPrimitiveArrays, 0, @"ANY link.dateObj >= %@", date(1));
    RLMAssertCount(LinkToAllOptionalPrimitiveArrays, 0, @"ANY link.decimalObj >= %@", decimal128(2));
    RLMAssertCount(LinkToAllPrimitiveArrays, 0, @"ANY link.intObj < %@", @2);
    RLMAssertCount(LinkToAllPrimitiveArrays, 0, @"ANY link.floatObj < %@", @2.2f);
    RLMAssertCount(LinkToAllPrimitiveArrays, 0, @"ANY link.doubleObj < %@", @2.2);
    RLMAssertCount(LinkToAllPrimitiveArrays, 0, @"ANY link.dateObj < %@", date(1));
    RLMAssertCount(LinkToAllPrimitiveArrays, 0, @"ANY link.decimalObj < %@", decimal128(2));
    RLMAssertCount(LinkToAllPrimitiveArrays, 0, @"ANY link.anyIntObj < %@", @2);
    RLMAssertCount(LinkToAllPrimitiveArrays, 0, @"ANY link.anyFloatObj < %@", @2.2f);
    RLMAssertCount(LinkToAllPrimitiveArrays, 0, @"ANY link.anyDoubleObj < %@", @2.2);
    RLMAssertCount(LinkToAllPrimitiveArrays, 0, @"ANY link.anyDateObj < %@", date(1));
    RLMAssertCount(LinkToAllPrimitiveArrays, 0, @"ANY link.anyDecimalObj < %@", decimal128(2));
    RLMAssertCount(LinkToAllOptionalPrimitiveArrays, 0, @"ANY link.intObj < %@", @2);
    RLMAssertCount(LinkToAllOptionalPrimitiveArrays, 0, @"ANY link.floatObj < %@", @2.2f);
    RLMAssertCount(LinkToAllOptionalPrimitiveArrays, 0, @"ANY link.doubleObj < %@", @2.2);
    RLMAssertCount(LinkToAllOptionalPrimitiveArrays, 0, @"ANY link.dateObj < %@", date(1));
    RLMAssertCount(LinkToAllOptionalPrimitiveArrays, 0, @"ANY link.decimalObj < %@", decimal128(2));
    RLMAssertCount(LinkToAllPrimitiveArrays, 0, @"ANY link.intObj <= %@", @2);
    RLMAssertCount(LinkToAllPrimitiveArrays, 0, @"ANY link.floatObj <= %@", @2.2f);
    RLMAssertCount(LinkToAllPrimitiveArrays, 0, @"ANY link.doubleObj <= %@", @2.2);
    RLMAssertCount(LinkToAllPrimitiveArrays, 0, @"ANY link.dateObj <= %@", date(1));
    RLMAssertCount(LinkToAllPrimitiveArrays, 0, @"ANY link.decimalObj <= %@", decimal128(2));
    RLMAssertCount(LinkToAllPrimitiveArrays, 0, @"ANY link.anyIntObj <= %@", @2);
    RLMAssertCount(LinkToAllPrimitiveArrays, 0, @"ANY link.anyFloatObj <= %@", @2.2f);
    RLMAssertCount(LinkToAllPrimitiveArrays, 0, @"ANY link.anyDoubleObj <= %@", @2.2);
    RLMAssertCount(LinkToAllPrimitiveArrays, 0, @"ANY link.anyDateObj <= %@", date(1));
    RLMAssertCount(LinkToAllPrimitiveArrays, 0, @"ANY link.anyDecimalObj <= %@", decimal128(2));
    RLMAssertCount(LinkToAllOptionalPrimitiveArrays, 0, @"ANY link.intObj <= %@", @2);
    RLMAssertCount(LinkToAllOptionalPrimitiveArrays, 0, @"ANY link.floatObj <= %@", @2.2f);
    RLMAssertCount(LinkToAllOptionalPrimitiveArrays, 0, @"ANY link.doubleObj <= %@", @2.2);
    RLMAssertCount(LinkToAllOptionalPrimitiveArrays, 0, @"ANY link.dateObj <= %@", date(1));
    RLMAssertCount(LinkToAllOptionalPrimitiveArrays, 0, @"ANY link.decimalObj <= %@", decimal128(2));

    [self createObjectWithValueIndex:0];

    RLMAssertCount(LinkToAllPrimitiveArrays, 0, @"ANY link.boolObj = %@", @YES);
    RLMAssertCount(LinkToAllPrimitiveArrays, 0, @"ANY link.intObj = %@", @3);
    RLMAssertCount(LinkToAllPrimitiveArrays, 0, @"ANY link.floatObj = %@", @3.3f);
    RLMAssertCount(LinkToAllPrimitiveArrays, 0, @"ANY link.doubleObj = %@", @3.3);
    RLMAssertCount(LinkToAllPrimitiveArrays, 0, @"ANY link.stringObj = %@", @"b");
    RLMAssertCount(LinkToAllPrimitiveArrays, 0, @"ANY link.dataObj = %@", data(2));
    RLMAssertCount(LinkToAllPrimitiveArrays, 0, @"ANY link.dateObj = %@", date(2));
    RLMAssertCount(LinkToAllPrimitiveArrays, 0, @"ANY link.decimalObj = %@", decimal128(3));
    RLMAssertCount(LinkToAllPrimitiveArrays, 0, @"ANY link.objectIdObj = %@", objectId(2));
    RLMAssertCount(LinkToAllPrimitiveArrays, 0, @"ANY link.uuidObj = %@", uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"));
    RLMAssertCount(LinkToAllPrimitiveArrays, 0, @"ANY link.anyBoolObj = %@", @YES);
    RLMAssertCount(LinkToAllPrimitiveArrays, 0, @"ANY link.anyIntObj = %@", @3);
    RLMAssertCount(LinkToAllPrimitiveArrays, 0, @"ANY link.anyFloatObj = %@", @3.3f);
    RLMAssertCount(LinkToAllPrimitiveArrays, 0, @"ANY link.anyDoubleObj = %@", @3.3);
    RLMAssertCount(LinkToAllPrimitiveArrays, 0, @"ANY link.anyStringObj = %@", @"b");
    RLMAssertCount(LinkToAllPrimitiveArrays, 0, @"ANY link.anyDataObj = %@", data(2));
    RLMAssertCount(LinkToAllPrimitiveArrays, 0, @"ANY link.anyDateObj = %@", date(2));
    RLMAssertCount(LinkToAllPrimitiveArrays, 0, @"ANY link.anyDecimalObj = %@", decimal128(3));
    RLMAssertCount(LinkToAllPrimitiveArrays, 0, @"ANY link.anyObjectIdObj = %@", objectId(2));
    RLMAssertCount(LinkToAllPrimitiveArrays, 0, @"ANY link.anyUUIDObj = %@", uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"));
    RLMAssertCount(LinkToAllOptionalPrimitiveArrays, 0, @"ANY link.boolObj = %@", @YES);
    RLMAssertCount(LinkToAllOptionalPrimitiveArrays, 0, @"ANY link.intObj = %@", @3);
    RLMAssertCount(LinkToAllOptionalPrimitiveArrays, 0, @"ANY link.floatObj = %@", @3.3f);
    RLMAssertCount(LinkToAllOptionalPrimitiveArrays, 0, @"ANY link.doubleObj = %@", @3.3);
    RLMAssertCount(LinkToAllOptionalPrimitiveArrays, 0, @"ANY link.stringObj = %@", @"b");
    RLMAssertCount(LinkToAllOptionalPrimitiveArrays, 0, @"ANY link.dataObj = %@", data(2));
    RLMAssertCount(LinkToAllOptionalPrimitiveArrays, 0, @"ANY link.dateObj = %@", date(2));
    RLMAssertCount(LinkToAllOptionalPrimitiveArrays, 0, @"ANY link.decimalObj = %@", decimal128(3));
    RLMAssertCount(LinkToAllOptionalPrimitiveArrays, 0, @"ANY link.objectIdObj = %@", objectId(2));
    RLMAssertCount(LinkToAllOptionalPrimitiveArrays, 0, @"ANY link.uuidObj = %@", uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"));
    RLMAssertCount(LinkToAllPrimitiveArrays, 1, @"ANY link.boolObj = %@", @NO);
    RLMAssertCount(LinkToAllPrimitiveArrays, 1, @"ANY link.intObj = %@", @2);
    RLMAssertCount(LinkToAllPrimitiveArrays, 1, @"ANY link.floatObj = %@", @2.2f);
    RLMAssertCount(LinkToAllPrimitiveArrays, 1, @"ANY link.doubleObj = %@", @2.2);
    RLMAssertCount(LinkToAllPrimitiveArrays, 1, @"ANY link.stringObj = %@", @"a");
    RLMAssertCount(LinkToAllPrimitiveArrays, 1, @"ANY link.dataObj = %@", data(1));
    RLMAssertCount(LinkToAllPrimitiveArrays, 1, @"ANY link.dateObj = %@", date(1));
    RLMAssertCount(LinkToAllPrimitiveArrays, 1, @"ANY link.decimalObj = %@", decimal128(2));
    RLMAssertCount(LinkToAllPrimitiveArrays, 1, @"ANY link.objectIdObj = %@", objectId(1));
    RLMAssertCount(LinkToAllPrimitiveArrays, 1, @"ANY link.uuidObj = %@", uuid(@"00000000-0000-0000-0000-000000000000"));
    RLMAssertCount(LinkToAllPrimitiveArrays, 1, @"ANY link.anyBoolObj = %@", @NO);
    RLMAssertCount(LinkToAllPrimitiveArrays, 1, @"ANY link.anyIntObj = %@", @2);
    RLMAssertCount(LinkToAllPrimitiveArrays, 1, @"ANY link.anyFloatObj = %@", @2.2f);
    RLMAssertCount(LinkToAllPrimitiveArrays, 1, @"ANY link.anyDoubleObj = %@", @2.2);
    RLMAssertCount(LinkToAllPrimitiveArrays, 1, @"ANY link.anyStringObj = %@", @"a");
    RLMAssertCount(LinkToAllPrimitiveArrays, 1, @"ANY link.anyDataObj = %@", data(1));
    RLMAssertCount(LinkToAllPrimitiveArrays, 1, @"ANY link.anyDateObj = %@", date(1));
    RLMAssertCount(LinkToAllPrimitiveArrays, 1, @"ANY link.anyDecimalObj = %@", decimal128(2));
    RLMAssertCount(LinkToAllPrimitiveArrays, 1, @"ANY link.anyObjectIdObj = %@", objectId(1));
    RLMAssertCount(LinkToAllPrimitiveArrays, 1, @"ANY link.anyUUIDObj = %@", uuid(@"00000000-0000-0000-0000-000000000000"));
    RLMAssertCount(LinkToAllOptionalPrimitiveArrays, 1, @"ANY link.boolObj = %@", @NO);
    RLMAssertCount(LinkToAllOptionalPrimitiveArrays, 1, @"ANY link.intObj = %@", @2);
    RLMAssertCount(LinkToAllOptionalPrimitiveArrays, 1, @"ANY link.floatObj = %@", @2.2f);
    RLMAssertCount(LinkToAllOptionalPrimitiveArrays, 1, @"ANY link.doubleObj = %@", @2.2);
    RLMAssertCount(LinkToAllOptionalPrimitiveArrays, 1, @"ANY link.stringObj = %@", @"a");
    RLMAssertCount(LinkToAllOptionalPrimitiveArrays, 1, @"ANY link.dataObj = %@", data(1));
    RLMAssertCount(LinkToAllOptionalPrimitiveArrays, 1, @"ANY link.dateObj = %@", date(1));
    RLMAssertCount(LinkToAllOptionalPrimitiveArrays, 1, @"ANY link.decimalObj = %@", decimal128(2));
    RLMAssertCount(LinkToAllOptionalPrimitiveArrays, 1, @"ANY link.objectIdObj = %@", objectId(1));
    RLMAssertCount(LinkToAllOptionalPrimitiveArrays, 1, @"ANY link.uuidObj = %@", uuid(@"00000000-0000-0000-0000-000000000000"));
    RLMAssertCount(LinkToAllPrimitiveArrays, 0, @"ANY link.boolObj != %@", @NO);
    RLMAssertCount(LinkToAllPrimitiveArrays, 0, @"ANY link.intObj != %@", @2);
    RLMAssertCount(LinkToAllPrimitiveArrays, 0, @"ANY link.floatObj != %@", @2.2f);
    RLMAssertCount(LinkToAllPrimitiveArrays, 0, @"ANY link.doubleObj != %@", @2.2);
    RLMAssertCount(LinkToAllPrimitiveArrays, 0, @"ANY link.stringObj != %@", @"a");
    RLMAssertCount(LinkToAllPrimitiveArrays, 0, @"ANY link.dataObj != %@", data(1));
    RLMAssertCount(LinkToAllPrimitiveArrays, 0, @"ANY link.dateObj != %@", date(1));
    RLMAssertCount(LinkToAllPrimitiveArrays, 0, @"ANY link.decimalObj != %@", decimal128(2));
    RLMAssertCount(LinkToAllPrimitiveArrays, 0, @"ANY link.objectIdObj != %@", objectId(1));
    RLMAssertCount(LinkToAllPrimitiveArrays, 0, @"ANY link.uuidObj != %@", uuid(@"00000000-0000-0000-0000-000000000000"));
    RLMAssertCount(LinkToAllPrimitiveArrays, 0, @"ANY link.anyBoolObj != %@", @NO);
    RLMAssertCount(LinkToAllPrimitiveArrays, 0, @"ANY link.anyIntObj != %@", @2);
    RLMAssertCount(LinkToAllPrimitiveArrays, 0, @"ANY link.anyFloatObj != %@", @2.2f);
    RLMAssertCount(LinkToAllPrimitiveArrays, 0, @"ANY link.anyDoubleObj != %@", @2.2);
    RLMAssertCount(LinkToAllPrimitiveArrays, 0, @"ANY link.anyStringObj != %@", @"a");
    RLMAssertCount(LinkToAllPrimitiveArrays, 0, @"ANY link.anyDataObj != %@", data(1));
    RLMAssertCount(LinkToAllPrimitiveArrays, 0, @"ANY link.anyDateObj != %@", date(1));
    RLMAssertCount(LinkToAllPrimitiveArrays, 0, @"ANY link.anyDecimalObj != %@", decimal128(2));
    RLMAssertCount(LinkToAllPrimitiveArrays, 0, @"ANY link.anyObjectIdObj != %@", objectId(1));
    RLMAssertCount(LinkToAllPrimitiveArrays, 0, @"ANY link.anyUUIDObj != %@", uuid(@"00000000-0000-0000-0000-000000000000"));
    RLMAssertCount(LinkToAllOptionalPrimitiveArrays, 0, @"ANY link.boolObj != %@", @NO);
    RLMAssertCount(LinkToAllOptionalPrimitiveArrays, 0, @"ANY link.intObj != %@", @2);
    RLMAssertCount(LinkToAllOptionalPrimitiveArrays, 0, @"ANY link.floatObj != %@", @2.2f);
    RLMAssertCount(LinkToAllOptionalPrimitiveArrays, 0, @"ANY link.doubleObj != %@", @2.2);
    RLMAssertCount(LinkToAllOptionalPrimitiveArrays, 0, @"ANY link.stringObj != %@", @"a");
    RLMAssertCount(LinkToAllOptionalPrimitiveArrays, 0, @"ANY link.dataObj != %@", data(1));
    RLMAssertCount(LinkToAllOptionalPrimitiveArrays, 0, @"ANY link.dateObj != %@", date(1));
    RLMAssertCount(LinkToAllOptionalPrimitiveArrays, 0, @"ANY link.decimalObj != %@", decimal128(2));
    RLMAssertCount(LinkToAllOptionalPrimitiveArrays, 0, @"ANY link.objectIdObj != %@", objectId(1));
    RLMAssertCount(LinkToAllOptionalPrimitiveArrays, 0, @"ANY link.uuidObj != %@", uuid(@"00000000-0000-0000-0000-000000000000"));
    RLMAssertCount(LinkToAllPrimitiveArrays, 1, @"ANY link.boolObj != %@", @YES);
    RLMAssertCount(LinkToAllPrimitiveArrays, 1, @"ANY link.intObj != %@", @3);
    RLMAssertCount(LinkToAllPrimitiveArrays, 1, @"ANY link.floatObj != %@", @3.3f);
    RLMAssertCount(LinkToAllPrimitiveArrays, 1, @"ANY link.doubleObj != %@", @3.3);
    RLMAssertCount(LinkToAllPrimitiveArrays, 1, @"ANY link.stringObj != %@", @"b");
    RLMAssertCount(LinkToAllPrimitiveArrays, 1, @"ANY link.dataObj != %@", data(2));
    RLMAssertCount(LinkToAllPrimitiveArrays, 1, @"ANY link.dateObj != %@", date(2));
    RLMAssertCount(LinkToAllPrimitiveArrays, 1, @"ANY link.decimalObj != %@", decimal128(3));
    RLMAssertCount(LinkToAllPrimitiveArrays, 1, @"ANY link.objectIdObj != %@", objectId(2));
    RLMAssertCount(LinkToAllPrimitiveArrays, 1, @"ANY link.uuidObj != %@", uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"));
    RLMAssertCount(LinkToAllPrimitiveArrays, 1, @"ANY link.anyBoolObj != %@", @YES);
    RLMAssertCount(LinkToAllPrimitiveArrays, 1, @"ANY link.anyIntObj != %@", @3);
    RLMAssertCount(LinkToAllPrimitiveArrays, 1, @"ANY link.anyFloatObj != %@", @3.3f);
    RLMAssertCount(LinkToAllPrimitiveArrays, 1, @"ANY link.anyDoubleObj != %@", @3.3);
    RLMAssertCount(LinkToAllPrimitiveArrays, 1, @"ANY link.anyStringObj != %@", @"b");
    RLMAssertCount(LinkToAllPrimitiveArrays, 1, @"ANY link.anyDataObj != %@", data(2));
    RLMAssertCount(LinkToAllPrimitiveArrays, 1, @"ANY link.anyDateObj != %@", date(2));
    RLMAssertCount(LinkToAllPrimitiveArrays, 1, @"ANY link.anyDecimalObj != %@", decimal128(3));
    RLMAssertCount(LinkToAllPrimitiveArrays, 1, @"ANY link.anyObjectIdObj != %@", objectId(2));
    RLMAssertCount(LinkToAllPrimitiveArrays, 1, @"ANY link.anyUUIDObj != %@", uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"));
    RLMAssertCount(LinkToAllOptionalPrimitiveArrays, 1, @"ANY link.boolObj != %@", @YES);
    RLMAssertCount(LinkToAllOptionalPrimitiveArrays, 1, @"ANY link.intObj != %@", @3);
    RLMAssertCount(LinkToAllOptionalPrimitiveArrays, 1, @"ANY link.floatObj != %@", @3.3f);
    RLMAssertCount(LinkToAllOptionalPrimitiveArrays, 1, @"ANY link.doubleObj != %@", @3.3);
    RLMAssertCount(LinkToAllOptionalPrimitiveArrays, 1, @"ANY link.stringObj != %@", @"b");
    RLMAssertCount(LinkToAllOptionalPrimitiveArrays, 1, @"ANY link.dataObj != %@", data(2));
    RLMAssertCount(LinkToAllOptionalPrimitiveArrays, 1, @"ANY link.dateObj != %@", date(2));
    RLMAssertCount(LinkToAllOptionalPrimitiveArrays, 1, @"ANY link.decimalObj != %@", decimal128(3));
    RLMAssertCount(LinkToAllOptionalPrimitiveArrays, 1, @"ANY link.objectIdObj != %@", objectId(2));
    RLMAssertCount(LinkToAllOptionalPrimitiveArrays, 1, @"ANY link.uuidObj != %@", uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"));
    RLMAssertCount(LinkToAllPrimitiveArrays, 0, @"ANY link.intObj > %@", @2);
    RLMAssertCount(LinkToAllPrimitiveArrays, 0, @"ANY link.floatObj > %@", @2.2f);
    RLMAssertCount(LinkToAllPrimitiveArrays, 0, @"ANY link.doubleObj > %@", @2.2);
    RLMAssertCount(LinkToAllPrimitiveArrays, 0, @"ANY link.dateObj > %@", date(1));
    RLMAssertCount(LinkToAllPrimitiveArrays, 0, @"ANY link.decimalObj > %@", decimal128(2));
    RLMAssertCount(LinkToAllPrimitiveArrays, 0, @"ANY link.anyIntObj > %@", @2);
    RLMAssertCount(LinkToAllPrimitiveArrays, 0, @"ANY link.anyFloatObj > %@", @2.2f);
    RLMAssertCount(LinkToAllPrimitiveArrays, 0, @"ANY link.anyDoubleObj > %@", @2.2);
    RLMAssertCount(LinkToAllPrimitiveArrays, 0, @"ANY link.anyDateObj > %@", date(1));
    RLMAssertCount(LinkToAllPrimitiveArrays, 0, @"ANY link.anyDecimalObj > %@", decimal128(2));
    RLMAssertCount(LinkToAllOptionalPrimitiveArrays, 0, @"ANY link.intObj > %@", @2);
    RLMAssertCount(LinkToAllOptionalPrimitiveArrays, 0, @"ANY link.floatObj > %@", @2.2f);
    RLMAssertCount(LinkToAllOptionalPrimitiveArrays, 0, @"ANY link.doubleObj > %@", @2.2);
    RLMAssertCount(LinkToAllOptionalPrimitiveArrays, 0, @"ANY link.dateObj > %@", date(1));
    RLMAssertCount(LinkToAllOptionalPrimitiveArrays, 0, @"ANY link.decimalObj > %@", decimal128(2));
    RLMAssertCount(LinkToAllPrimitiveArrays, 1, @"ANY link.intObj >= %@", @2);
    RLMAssertCount(LinkToAllPrimitiveArrays, 1, @"ANY link.floatObj >= %@", @2.2f);
    RLMAssertCount(LinkToAllPrimitiveArrays, 1, @"ANY link.doubleObj >= %@", @2.2);
    RLMAssertCount(LinkToAllPrimitiveArrays, 1, @"ANY link.dateObj >= %@", date(1));
    RLMAssertCount(LinkToAllPrimitiveArrays, 1, @"ANY link.decimalObj >= %@", decimal128(2));
    RLMAssertCount(LinkToAllPrimitiveArrays, 1, @"ANY link.anyIntObj >= %@", @2);
    RLMAssertCount(LinkToAllPrimitiveArrays, 1, @"ANY link.anyFloatObj >= %@", @2.2f);
    RLMAssertCount(LinkToAllPrimitiveArrays, 1, @"ANY link.anyDoubleObj >= %@", @2.2);
    RLMAssertCount(LinkToAllPrimitiveArrays, 1, @"ANY link.anyDateObj >= %@", date(1));
    RLMAssertCount(LinkToAllPrimitiveArrays, 1, @"ANY link.anyDecimalObj >= %@", decimal128(2));
    RLMAssertCount(LinkToAllOptionalPrimitiveArrays, 1, @"ANY link.intObj >= %@", @2);
    RLMAssertCount(LinkToAllOptionalPrimitiveArrays, 1, @"ANY link.floatObj >= %@", @2.2f);
    RLMAssertCount(LinkToAllOptionalPrimitiveArrays, 1, @"ANY link.doubleObj >= %@", @2.2);
    RLMAssertCount(LinkToAllOptionalPrimitiveArrays, 1, @"ANY link.dateObj >= %@", date(1));
    RLMAssertCount(LinkToAllOptionalPrimitiveArrays, 1, @"ANY link.decimalObj >= %@", decimal128(2));
    RLMAssertCount(LinkToAllPrimitiveArrays, 0, @"ANY link.intObj < %@", @2);
    RLMAssertCount(LinkToAllPrimitiveArrays, 0, @"ANY link.floatObj < %@", @2.2f);
    RLMAssertCount(LinkToAllPrimitiveArrays, 0, @"ANY link.doubleObj < %@", @2.2);
    RLMAssertCount(LinkToAllPrimitiveArrays, 0, @"ANY link.dateObj < %@", date(1));
    RLMAssertCount(LinkToAllPrimitiveArrays, 0, @"ANY link.decimalObj < %@", decimal128(2));
    RLMAssertCount(LinkToAllPrimitiveArrays, 0, @"ANY link.anyIntObj < %@", @2);
    RLMAssertCount(LinkToAllPrimitiveArrays, 0, @"ANY link.anyFloatObj < %@", @2.2f);
    RLMAssertCount(LinkToAllPrimitiveArrays, 0, @"ANY link.anyDoubleObj < %@", @2.2);
    RLMAssertCount(LinkToAllPrimitiveArrays, 0, @"ANY link.anyDateObj < %@", date(1));
    RLMAssertCount(LinkToAllPrimitiveArrays, 0, @"ANY link.anyDecimalObj < %@", decimal128(2));
    RLMAssertCount(LinkToAllOptionalPrimitiveArrays, 0, @"ANY link.intObj < %@", @2);
    RLMAssertCount(LinkToAllOptionalPrimitiveArrays, 0, @"ANY link.floatObj < %@", @2.2f);
    RLMAssertCount(LinkToAllOptionalPrimitiveArrays, 0, @"ANY link.doubleObj < %@", @2.2);
    RLMAssertCount(LinkToAllOptionalPrimitiveArrays, 0, @"ANY link.dateObj < %@", date(1));
    RLMAssertCount(LinkToAllOptionalPrimitiveArrays, 0, @"ANY link.decimalObj < %@", decimal128(2));
    RLMAssertCount(LinkToAllPrimitiveArrays, 1, @"ANY link.intObj < %@", @3);
    RLMAssertCount(LinkToAllPrimitiveArrays, 1, @"ANY link.floatObj < %@", @3.3f);
    RLMAssertCount(LinkToAllPrimitiveArrays, 1, @"ANY link.doubleObj < %@", @3.3);
    RLMAssertCount(LinkToAllPrimitiveArrays, 1, @"ANY link.dateObj < %@", date(2));
    RLMAssertCount(LinkToAllPrimitiveArrays, 1, @"ANY link.decimalObj < %@", decimal128(3));
    RLMAssertCount(LinkToAllPrimitiveArrays, 1, @"ANY link.anyIntObj < %@", @3);
    RLMAssertCount(LinkToAllPrimitiveArrays, 1, @"ANY link.anyFloatObj < %@", @3.3f);
    RLMAssertCount(LinkToAllPrimitiveArrays, 1, @"ANY link.anyDoubleObj < %@", @3.3);
    RLMAssertCount(LinkToAllPrimitiveArrays, 1, @"ANY link.anyDateObj < %@", date(2));
    RLMAssertCount(LinkToAllPrimitiveArrays, 1, @"ANY link.anyDecimalObj < %@", decimal128(3));
    RLMAssertCount(LinkToAllOptionalPrimitiveArrays, 1, @"ANY link.intObj < %@", @3);
    RLMAssertCount(LinkToAllOptionalPrimitiveArrays, 1, @"ANY link.floatObj < %@", @3.3f);
    RLMAssertCount(LinkToAllOptionalPrimitiveArrays, 1, @"ANY link.doubleObj < %@", @3.3);
    RLMAssertCount(LinkToAllOptionalPrimitiveArrays, 1, @"ANY link.dateObj < %@", date(2));
    RLMAssertCount(LinkToAllOptionalPrimitiveArrays, 1, @"ANY link.decimalObj < %@", decimal128(3));
    RLMAssertCount(LinkToAllPrimitiveArrays, 1, @"ANY link.intObj <= %@", @2);
    RLMAssertCount(LinkToAllPrimitiveArrays, 1, @"ANY link.floatObj <= %@", @2.2f);
    RLMAssertCount(LinkToAllPrimitiveArrays, 1, @"ANY link.doubleObj <= %@", @2.2);
    RLMAssertCount(LinkToAllPrimitiveArrays, 1, @"ANY link.dateObj <= %@", date(1));
    RLMAssertCount(LinkToAllPrimitiveArrays, 1, @"ANY link.decimalObj <= %@", decimal128(2));
    RLMAssertCount(LinkToAllPrimitiveArrays, 1, @"ANY link.anyIntObj <= %@", @2);
    RLMAssertCount(LinkToAllPrimitiveArrays, 1, @"ANY link.anyFloatObj <= %@", @2.2f);
    RLMAssertCount(LinkToAllPrimitiveArrays, 1, @"ANY link.anyDoubleObj <= %@", @2.2);
    RLMAssertCount(LinkToAllPrimitiveArrays, 1, @"ANY link.anyDateObj <= %@", date(1));
    RLMAssertCount(LinkToAllPrimitiveArrays, 1, @"ANY link.anyDecimalObj <= %@", decimal128(2));
    RLMAssertCount(LinkToAllOptionalPrimitiveArrays, 1, @"ANY link.intObj <= %@", @2);
    RLMAssertCount(LinkToAllOptionalPrimitiveArrays, 1, @"ANY link.floatObj <= %@", @2.2f);
    RLMAssertCount(LinkToAllOptionalPrimitiveArrays, 1, @"ANY link.doubleObj <= %@", @2.2);
    RLMAssertCount(LinkToAllOptionalPrimitiveArrays, 1, @"ANY link.dateObj <= %@", date(1));
    RLMAssertCount(LinkToAllOptionalPrimitiveArrays, 1, @"ANY link.decimalObj <= %@", decimal128(2));

    [self createObjectWithValueIndex:1];

    RLMAssertCount(LinkToAllPrimitiveArrays, 1, @"ANY link.boolObj = %@", @NO);
    RLMAssertCount(LinkToAllPrimitiveArrays, 1, @"ANY link.intObj = %@", @2);
    RLMAssertCount(LinkToAllPrimitiveArrays, 1, @"ANY link.floatObj = %@", @2.2f);
    RLMAssertCount(LinkToAllPrimitiveArrays, 1, @"ANY link.doubleObj = %@", @2.2);
    RLMAssertCount(LinkToAllPrimitiveArrays, 1, @"ANY link.stringObj = %@", @"a");
    RLMAssertCount(LinkToAllPrimitiveArrays, 1, @"ANY link.dataObj = %@", data(1));
    RLMAssertCount(LinkToAllPrimitiveArrays, 1, @"ANY link.dateObj = %@", date(1));
    RLMAssertCount(LinkToAllPrimitiveArrays, 1, @"ANY link.decimalObj = %@", decimal128(2));
    RLMAssertCount(LinkToAllPrimitiveArrays, 1, @"ANY link.objectIdObj = %@", objectId(1));
    RLMAssertCount(LinkToAllPrimitiveArrays, 1, @"ANY link.uuidObj = %@", uuid(@"00000000-0000-0000-0000-000000000000"));
    RLMAssertCount(LinkToAllPrimitiveArrays, 1, @"ANY link.anyBoolObj = %@", @NO);
    RLMAssertCount(LinkToAllPrimitiveArrays, 1, @"ANY link.anyIntObj = %@", @2);
    RLMAssertCount(LinkToAllPrimitiveArrays, 1, @"ANY link.anyFloatObj = %@", @2.2f);
    RLMAssertCount(LinkToAllPrimitiveArrays, 1, @"ANY link.anyDoubleObj = %@", @2.2);
    RLMAssertCount(LinkToAllPrimitiveArrays, 1, @"ANY link.anyStringObj = %@", @"a");
    RLMAssertCount(LinkToAllPrimitiveArrays, 1, @"ANY link.anyDataObj = %@", data(1));
    RLMAssertCount(LinkToAllPrimitiveArrays, 1, @"ANY link.anyDateObj = %@", date(1));
    RLMAssertCount(LinkToAllPrimitiveArrays, 1, @"ANY link.anyDecimalObj = %@", decimal128(2));
    RLMAssertCount(LinkToAllPrimitiveArrays, 1, @"ANY link.anyObjectIdObj = %@", objectId(1));
    RLMAssertCount(LinkToAllPrimitiveArrays, 1, @"ANY link.anyUUIDObj = %@", uuid(@"00000000-0000-0000-0000-000000000000"));
    RLMAssertCount(LinkToAllOptionalPrimitiveArrays, 1, @"ANY link.boolObj = %@", @NO);
    RLMAssertCount(LinkToAllOptionalPrimitiveArrays, 1, @"ANY link.intObj = %@", @2);
    RLMAssertCount(LinkToAllOptionalPrimitiveArrays, 1, @"ANY link.floatObj = %@", @2.2f);
    RLMAssertCount(LinkToAllOptionalPrimitiveArrays, 1, @"ANY link.doubleObj = %@", @2.2);
    RLMAssertCount(LinkToAllOptionalPrimitiveArrays, 1, @"ANY link.stringObj = %@", @"a");
    RLMAssertCount(LinkToAllOptionalPrimitiveArrays, 1, @"ANY link.dataObj = %@", data(1));
    RLMAssertCount(LinkToAllOptionalPrimitiveArrays, 1, @"ANY link.dateObj = %@", date(1));
    RLMAssertCount(LinkToAllOptionalPrimitiveArrays, 1, @"ANY link.decimalObj = %@", decimal128(2));
    RLMAssertCount(LinkToAllOptionalPrimitiveArrays, 1, @"ANY link.objectIdObj = %@", objectId(1));
    RLMAssertCount(LinkToAllOptionalPrimitiveArrays, 1, @"ANY link.uuidObj = %@", uuid(@"00000000-0000-0000-0000-000000000000"));
    RLMAssertCount(LinkToAllPrimitiveArrays, 1, @"ANY link.boolObj = %@", @YES);
    RLMAssertCount(LinkToAllPrimitiveArrays, 1, @"ANY link.intObj = %@", @3);
    RLMAssertCount(LinkToAllPrimitiveArrays, 1, @"ANY link.floatObj = %@", @3.3f);
    RLMAssertCount(LinkToAllPrimitiveArrays, 1, @"ANY link.doubleObj = %@", @3.3);
    RLMAssertCount(LinkToAllPrimitiveArrays, 1, @"ANY link.stringObj = %@", @"b");
    RLMAssertCount(LinkToAllPrimitiveArrays, 1, @"ANY link.dataObj = %@", data(2));
    RLMAssertCount(LinkToAllPrimitiveArrays, 1, @"ANY link.dateObj = %@", date(2));
    RLMAssertCount(LinkToAllPrimitiveArrays, 1, @"ANY link.decimalObj = %@", decimal128(3));
    RLMAssertCount(LinkToAllPrimitiveArrays, 1, @"ANY link.objectIdObj = %@", objectId(2));
    RLMAssertCount(LinkToAllPrimitiveArrays, 1, @"ANY link.uuidObj = %@", uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"));
    RLMAssertCount(LinkToAllPrimitiveArrays, 1, @"ANY link.anyBoolObj = %@", @YES);
    RLMAssertCount(LinkToAllPrimitiveArrays, 1, @"ANY link.anyIntObj = %@", @3);
    RLMAssertCount(LinkToAllPrimitiveArrays, 1, @"ANY link.anyFloatObj = %@", @3.3f);
    RLMAssertCount(LinkToAllPrimitiveArrays, 1, @"ANY link.anyDoubleObj = %@", @3.3);
    RLMAssertCount(LinkToAllPrimitiveArrays, 1, @"ANY link.anyStringObj = %@", @"b");
    RLMAssertCount(LinkToAllPrimitiveArrays, 1, @"ANY link.anyDataObj = %@", data(2));
    RLMAssertCount(LinkToAllPrimitiveArrays, 1, @"ANY link.anyDateObj = %@", date(2));
    RLMAssertCount(LinkToAllPrimitiveArrays, 1, @"ANY link.anyDecimalObj = %@", decimal128(3));
    RLMAssertCount(LinkToAllPrimitiveArrays, 1, @"ANY link.anyObjectIdObj = %@", objectId(2));
    RLMAssertCount(LinkToAllPrimitiveArrays, 1, @"ANY link.anyUUIDObj = %@", uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"));
    RLMAssertCount(LinkToAllOptionalPrimitiveArrays, 1, @"ANY link.boolObj = %@", @YES);
    RLMAssertCount(LinkToAllOptionalPrimitiveArrays, 1, @"ANY link.intObj = %@", @3);
    RLMAssertCount(LinkToAllOptionalPrimitiveArrays, 1, @"ANY link.floatObj = %@", @3.3f);
    RLMAssertCount(LinkToAllOptionalPrimitiveArrays, 1, @"ANY link.doubleObj = %@", @3.3);
    RLMAssertCount(LinkToAllOptionalPrimitiveArrays, 1, @"ANY link.stringObj = %@", @"b");
    RLMAssertCount(LinkToAllOptionalPrimitiveArrays, 1, @"ANY link.dataObj = %@", data(2));
    RLMAssertCount(LinkToAllOptionalPrimitiveArrays, 1, @"ANY link.dateObj = %@", date(2));
    RLMAssertCount(LinkToAllOptionalPrimitiveArrays, 1, @"ANY link.decimalObj = %@", decimal128(3));
    RLMAssertCount(LinkToAllOptionalPrimitiveArrays, 1, @"ANY link.objectIdObj = %@", objectId(2));
    RLMAssertCount(LinkToAllOptionalPrimitiveArrays, 1, @"ANY link.uuidObj = %@", uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"));
    RLMAssertCount(LinkToAllPrimitiveArrays, 1, @"ANY link.boolObj != %@", @NO);
    RLMAssertCount(LinkToAllPrimitiveArrays, 1, @"ANY link.intObj != %@", @2);
    RLMAssertCount(LinkToAllPrimitiveArrays, 1, @"ANY link.floatObj != %@", @2.2f);
    RLMAssertCount(LinkToAllPrimitiveArrays, 1, @"ANY link.doubleObj != %@", @2.2);
    RLMAssertCount(LinkToAllPrimitiveArrays, 1, @"ANY link.stringObj != %@", @"a");
    RLMAssertCount(LinkToAllPrimitiveArrays, 1, @"ANY link.dataObj != %@", data(1));
    RLMAssertCount(LinkToAllPrimitiveArrays, 1, @"ANY link.dateObj != %@", date(1));
    RLMAssertCount(LinkToAllPrimitiveArrays, 1, @"ANY link.decimalObj != %@", decimal128(2));
    RLMAssertCount(LinkToAllPrimitiveArrays, 1, @"ANY link.objectIdObj != %@", objectId(1));
    RLMAssertCount(LinkToAllPrimitiveArrays, 1, @"ANY link.uuidObj != %@", uuid(@"00000000-0000-0000-0000-000000000000"));
    RLMAssertCount(LinkToAllPrimitiveArrays, 1, @"ANY link.anyBoolObj != %@", @NO);
    RLMAssertCount(LinkToAllPrimitiveArrays, 1, @"ANY link.anyIntObj != %@", @2);
    RLMAssertCount(LinkToAllPrimitiveArrays, 1, @"ANY link.anyFloatObj != %@", @2.2f);
    RLMAssertCount(LinkToAllPrimitiveArrays, 1, @"ANY link.anyDoubleObj != %@", @2.2);
    RLMAssertCount(LinkToAllPrimitiveArrays, 1, @"ANY link.anyStringObj != %@", @"a");
    RLMAssertCount(LinkToAllPrimitiveArrays, 1, @"ANY link.anyDataObj != %@", data(1));
    RLMAssertCount(LinkToAllPrimitiveArrays, 1, @"ANY link.anyDateObj != %@", date(1));
    RLMAssertCount(LinkToAllPrimitiveArrays, 1, @"ANY link.anyDecimalObj != %@", decimal128(2));
    RLMAssertCount(LinkToAllPrimitiveArrays, 1, @"ANY link.anyObjectIdObj != %@", objectId(1));
    RLMAssertCount(LinkToAllPrimitiveArrays, 1, @"ANY link.anyUUIDObj != %@", uuid(@"00000000-0000-0000-0000-000000000000"));
    RLMAssertCount(LinkToAllOptionalPrimitiveArrays, 1, @"ANY link.boolObj != %@", @NO);
    RLMAssertCount(LinkToAllOptionalPrimitiveArrays, 1, @"ANY link.intObj != %@", @2);
    RLMAssertCount(LinkToAllOptionalPrimitiveArrays, 1, @"ANY link.floatObj != %@", @2.2f);
    RLMAssertCount(LinkToAllOptionalPrimitiveArrays, 1, @"ANY link.doubleObj != %@", @2.2);
    RLMAssertCount(LinkToAllOptionalPrimitiveArrays, 1, @"ANY link.stringObj != %@", @"a");
    RLMAssertCount(LinkToAllOptionalPrimitiveArrays, 1, @"ANY link.dataObj != %@", data(1));
    RLMAssertCount(LinkToAllOptionalPrimitiveArrays, 1, @"ANY link.dateObj != %@", date(1));
    RLMAssertCount(LinkToAllOptionalPrimitiveArrays, 1, @"ANY link.decimalObj != %@", decimal128(2));
    RLMAssertCount(LinkToAllOptionalPrimitiveArrays, 1, @"ANY link.objectIdObj != %@", objectId(1));
    RLMAssertCount(LinkToAllOptionalPrimitiveArrays, 1, @"ANY link.uuidObj != %@", uuid(@"00000000-0000-0000-0000-000000000000"));
    RLMAssertCount(LinkToAllPrimitiveArrays, 1, @"ANY link.boolObj != %@", @YES);
    RLMAssertCount(LinkToAllPrimitiveArrays, 1, @"ANY link.intObj != %@", @3);
    RLMAssertCount(LinkToAllPrimitiveArrays, 1, @"ANY link.floatObj != %@", @3.3f);
    RLMAssertCount(LinkToAllPrimitiveArrays, 1, @"ANY link.doubleObj != %@", @3.3);
    RLMAssertCount(LinkToAllPrimitiveArrays, 1, @"ANY link.stringObj != %@", @"b");
    RLMAssertCount(LinkToAllPrimitiveArrays, 1, @"ANY link.dataObj != %@", data(2));
    RLMAssertCount(LinkToAllPrimitiveArrays, 1, @"ANY link.dateObj != %@", date(2));
    RLMAssertCount(LinkToAllPrimitiveArrays, 1, @"ANY link.decimalObj != %@", decimal128(3));
    RLMAssertCount(LinkToAllPrimitiveArrays, 1, @"ANY link.objectIdObj != %@", objectId(2));
    RLMAssertCount(LinkToAllPrimitiveArrays, 1, @"ANY link.uuidObj != %@", uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"));
    RLMAssertCount(LinkToAllPrimitiveArrays, 1, @"ANY link.anyBoolObj != %@", @YES);
    RLMAssertCount(LinkToAllPrimitiveArrays, 1, @"ANY link.anyIntObj != %@", @3);
    RLMAssertCount(LinkToAllPrimitiveArrays, 1, @"ANY link.anyFloatObj != %@", @3.3f);
    RLMAssertCount(LinkToAllPrimitiveArrays, 1, @"ANY link.anyDoubleObj != %@", @3.3);
    RLMAssertCount(LinkToAllPrimitiveArrays, 1, @"ANY link.anyStringObj != %@", @"b");
    RLMAssertCount(LinkToAllPrimitiveArrays, 1, @"ANY link.anyDataObj != %@", data(2));
    RLMAssertCount(LinkToAllPrimitiveArrays, 1, @"ANY link.anyDateObj != %@", date(2));
    RLMAssertCount(LinkToAllPrimitiveArrays, 1, @"ANY link.anyDecimalObj != %@", decimal128(3));
    RLMAssertCount(LinkToAllPrimitiveArrays, 1, @"ANY link.anyObjectIdObj != %@", objectId(2));
    RLMAssertCount(LinkToAllPrimitiveArrays, 1, @"ANY link.anyUUIDObj != %@", uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"));
    RLMAssertCount(LinkToAllOptionalPrimitiveArrays, 1, @"ANY link.boolObj != %@", @YES);
    RLMAssertCount(LinkToAllOptionalPrimitiveArrays, 1, @"ANY link.intObj != %@", @3);
    RLMAssertCount(LinkToAllOptionalPrimitiveArrays, 1, @"ANY link.floatObj != %@", @3.3f);
    RLMAssertCount(LinkToAllOptionalPrimitiveArrays, 1, @"ANY link.doubleObj != %@", @3.3);
    RLMAssertCount(LinkToAllOptionalPrimitiveArrays, 1, @"ANY link.stringObj != %@", @"b");
    RLMAssertCount(LinkToAllOptionalPrimitiveArrays, 1, @"ANY link.dataObj != %@", data(2));
    RLMAssertCount(LinkToAllOptionalPrimitiveArrays, 1, @"ANY link.dateObj != %@", date(2));
    RLMAssertCount(LinkToAllOptionalPrimitiveArrays, 1, @"ANY link.decimalObj != %@", decimal128(3));
    RLMAssertCount(LinkToAllOptionalPrimitiveArrays, 1, @"ANY link.objectIdObj != %@", objectId(2));
    RLMAssertCount(LinkToAllOptionalPrimitiveArrays, 1, @"ANY link.uuidObj != %@", uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"));
    RLMAssertCount(LinkToAllPrimitiveArrays, 1, @"ANY link.intObj > %@", @2);
    RLMAssertCount(LinkToAllPrimitiveArrays, 1, @"ANY link.floatObj > %@", @2.2f);
    RLMAssertCount(LinkToAllPrimitiveArrays, 1, @"ANY link.doubleObj > %@", @2.2);
    RLMAssertCount(LinkToAllPrimitiveArrays, 1, @"ANY link.dateObj > %@", date(1));
    RLMAssertCount(LinkToAllPrimitiveArrays, 1, @"ANY link.decimalObj > %@", decimal128(2));
    RLMAssertCount(LinkToAllPrimitiveArrays, 1, @"ANY link.anyIntObj > %@", @2);
    RLMAssertCount(LinkToAllPrimitiveArrays, 1, @"ANY link.anyFloatObj > %@", @2.2f);
    RLMAssertCount(LinkToAllPrimitiveArrays, 1, @"ANY link.anyDoubleObj > %@", @2.2);
    RLMAssertCount(LinkToAllPrimitiveArrays, 1, @"ANY link.anyDateObj > %@", date(1));
    RLMAssertCount(LinkToAllPrimitiveArrays, 1, @"ANY link.anyDecimalObj > %@", decimal128(2));
    RLMAssertCount(LinkToAllOptionalPrimitiveArrays, 1, @"ANY link.intObj > %@", @2);
    RLMAssertCount(LinkToAllOptionalPrimitiveArrays, 1, @"ANY link.floatObj > %@", @2.2f);
    RLMAssertCount(LinkToAllOptionalPrimitiveArrays, 1, @"ANY link.doubleObj > %@", @2.2);
    RLMAssertCount(LinkToAllOptionalPrimitiveArrays, 1, @"ANY link.dateObj > %@", date(1));
    RLMAssertCount(LinkToAllOptionalPrimitiveArrays, 1, @"ANY link.decimalObj > %@", decimal128(2));
    RLMAssertCount(LinkToAllPrimitiveArrays, 2, @"ANY link.intObj >= %@", @2);
    RLMAssertCount(LinkToAllPrimitiveArrays, 2, @"ANY link.floatObj >= %@", @2.2f);
    RLMAssertCount(LinkToAllPrimitiveArrays, 2, @"ANY link.doubleObj >= %@", @2.2);
    RLMAssertCount(LinkToAllPrimitiveArrays, 2, @"ANY link.dateObj >= %@", date(1));
    RLMAssertCount(LinkToAllPrimitiveArrays, 2, @"ANY link.decimalObj >= %@", decimal128(2));
    RLMAssertCount(LinkToAllPrimitiveArrays, 2, @"ANY link.anyIntObj >= %@", @2);
    RLMAssertCount(LinkToAllPrimitiveArrays, 2, @"ANY link.anyFloatObj >= %@", @2.2f);
    RLMAssertCount(LinkToAllPrimitiveArrays, 2, @"ANY link.anyDoubleObj >= %@", @2.2);
    RLMAssertCount(LinkToAllPrimitiveArrays, 2, @"ANY link.anyDateObj >= %@", date(1));
    RLMAssertCount(LinkToAllPrimitiveArrays, 2, @"ANY link.anyDecimalObj >= %@", decimal128(2));
    RLMAssertCount(LinkToAllOptionalPrimitiveArrays, 2, @"ANY link.intObj >= %@", @2);
    RLMAssertCount(LinkToAllOptionalPrimitiveArrays, 2, @"ANY link.floatObj >= %@", @2.2f);
    RLMAssertCount(LinkToAllOptionalPrimitiveArrays, 2, @"ANY link.doubleObj >= %@", @2.2);
    RLMAssertCount(LinkToAllOptionalPrimitiveArrays, 2, @"ANY link.dateObj >= %@", date(1));
    RLMAssertCount(LinkToAllOptionalPrimitiveArrays, 2, @"ANY link.decimalObj >= %@", decimal128(2));
    RLMAssertCount(LinkToAllPrimitiveArrays, 0, @"ANY link.intObj < %@", @2);
    RLMAssertCount(LinkToAllPrimitiveArrays, 0, @"ANY link.floatObj < %@", @2.2f);
    RLMAssertCount(LinkToAllPrimitiveArrays, 0, @"ANY link.doubleObj < %@", @2.2);
    RLMAssertCount(LinkToAllPrimitiveArrays, 0, @"ANY link.dateObj < %@", date(1));
    RLMAssertCount(LinkToAllPrimitiveArrays, 0, @"ANY link.decimalObj < %@", decimal128(2));
    RLMAssertCount(LinkToAllPrimitiveArrays, 0, @"ANY link.anyIntObj < %@", @2);
    RLMAssertCount(LinkToAllPrimitiveArrays, 0, @"ANY link.anyFloatObj < %@", @2.2f);
    RLMAssertCount(LinkToAllPrimitiveArrays, 0, @"ANY link.anyDoubleObj < %@", @2.2);
    RLMAssertCount(LinkToAllPrimitiveArrays, 0, @"ANY link.anyDateObj < %@", date(1));
    RLMAssertCount(LinkToAllPrimitiveArrays, 0, @"ANY link.anyDecimalObj < %@", decimal128(2));
    RLMAssertCount(LinkToAllOptionalPrimitiveArrays, 0, @"ANY link.intObj < %@", @2);
    RLMAssertCount(LinkToAllOptionalPrimitiveArrays, 0, @"ANY link.floatObj < %@", @2.2f);
    RLMAssertCount(LinkToAllOptionalPrimitiveArrays, 0, @"ANY link.doubleObj < %@", @2.2);
    RLMAssertCount(LinkToAllOptionalPrimitiveArrays, 0, @"ANY link.dateObj < %@", date(1));
    RLMAssertCount(LinkToAllOptionalPrimitiveArrays, 0, @"ANY link.decimalObj < %@", decimal128(2));
    RLMAssertCount(LinkToAllPrimitiveArrays, 1, @"ANY link.intObj < %@", @3);
    RLMAssertCount(LinkToAllPrimitiveArrays, 1, @"ANY link.floatObj < %@", @3.3f);
    RLMAssertCount(LinkToAllPrimitiveArrays, 1, @"ANY link.doubleObj < %@", @3.3);
    RLMAssertCount(LinkToAllPrimitiveArrays, 1, @"ANY link.dateObj < %@", date(2));
    RLMAssertCount(LinkToAllPrimitiveArrays, 1, @"ANY link.decimalObj < %@", decimal128(3));
    RLMAssertCount(LinkToAllPrimitiveArrays, 1, @"ANY link.anyIntObj < %@", @3);
    RLMAssertCount(LinkToAllPrimitiveArrays, 1, @"ANY link.anyFloatObj < %@", @3.3f);
    RLMAssertCount(LinkToAllPrimitiveArrays, 1, @"ANY link.anyDoubleObj < %@", @3.3);
    RLMAssertCount(LinkToAllPrimitiveArrays, 1, @"ANY link.anyDateObj < %@", date(2));
    RLMAssertCount(LinkToAllPrimitiveArrays, 1, @"ANY link.anyDecimalObj < %@", decimal128(3));
    RLMAssertCount(LinkToAllOptionalPrimitiveArrays, 1, @"ANY link.intObj < %@", @3);
    RLMAssertCount(LinkToAllOptionalPrimitiveArrays, 1, @"ANY link.floatObj < %@", @3.3f);
    RLMAssertCount(LinkToAllOptionalPrimitiveArrays, 1, @"ANY link.doubleObj < %@", @3.3);
    RLMAssertCount(LinkToAllOptionalPrimitiveArrays, 1, @"ANY link.dateObj < %@", date(2));
    RLMAssertCount(LinkToAllOptionalPrimitiveArrays, 1, @"ANY link.decimalObj < %@", decimal128(3));
    RLMAssertCount(LinkToAllPrimitiveArrays, 1, @"ANY link.intObj <= %@", @2);
    RLMAssertCount(LinkToAllPrimitiveArrays, 1, @"ANY link.floatObj <= %@", @2.2f);
    RLMAssertCount(LinkToAllPrimitiveArrays, 1, @"ANY link.doubleObj <= %@", @2.2);
    RLMAssertCount(LinkToAllPrimitiveArrays, 1, @"ANY link.dateObj <= %@", date(1));
    RLMAssertCount(LinkToAllPrimitiveArrays, 1, @"ANY link.decimalObj <= %@", decimal128(2));
    RLMAssertCount(LinkToAllPrimitiveArrays, 1, @"ANY link.anyIntObj <= %@", @2);
    RLMAssertCount(LinkToAllPrimitiveArrays, 1, @"ANY link.anyFloatObj <= %@", @2.2f);
    RLMAssertCount(LinkToAllPrimitiveArrays, 1, @"ANY link.anyDoubleObj <= %@", @2.2);
    RLMAssertCount(LinkToAllPrimitiveArrays, 1, @"ANY link.anyDateObj <= %@", date(1));
    RLMAssertCount(LinkToAllPrimitiveArrays, 1, @"ANY link.anyDecimalObj <= %@", decimal128(2));
    RLMAssertCount(LinkToAllOptionalPrimitiveArrays, 1, @"ANY link.intObj <= %@", @2);
    RLMAssertCount(LinkToAllOptionalPrimitiveArrays, 1, @"ANY link.floatObj <= %@", @2.2f);
    RLMAssertCount(LinkToAllOptionalPrimitiveArrays, 1, @"ANY link.doubleObj <= %@", @2.2);
    RLMAssertCount(LinkToAllOptionalPrimitiveArrays, 1, @"ANY link.dateObj <= %@", date(1));
    RLMAssertCount(LinkToAllOptionalPrimitiveArrays, 1, @"ANY link.decimalObj <= %@", decimal128(2));
    RLMAssertCount(LinkToAllPrimitiveArrays, 2, @"ANY link.intObj <= %@", @3);
    RLMAssertCount(LinkToAllPrimitiveArrays, 2, @"ANY link.floatObj <= %@", @3.3f);
    RLMAssertCount(LinkToAllPrimitiveArrays, 2, @"ANY link.doubleObj <= %@", @3.3);
    RLMAssertCount(LinkToAllPrimitiveArrays, 2, @"ANY link.dateObj <= %@", date(2));
    RLMAssertCount(LinkToAllPrimitiveArrays, 2, @"ANY link.decimalObj <= %@", decimal128(3));
    RLMAssertCount(LinkToAllPrimitiveArrays, 2, @"ANY link.anyIntObj <= %@", @3);
    RLMAssertCount(LinkToAllPrimitiveArrays, 2, @"ANY link.anyFloatObj <= %@", @3.3f);
    RLMAssertCount(LinkToAllPrimitiveArrays, 2, @"ANY link.anyDoubleObj <= %@", @3.3);
    RLMAssertCount(LinkToAllPrimitiveArrays, 2, @"ANY link.anyDateObj <= %@", date(2));
    RLMAssertCount(LinkToAllPrimitiveArrays, 2, @"ANY link.anyDecimalObj <= %@", decimal128(3));
    RLMAssertCount(LinkToAllOptionalPrimitiveArrays, 2, @"ANY link.intObj <= %@", @3);
    RLMAssertCount(LinkToAllOptionalPrimitiveArrays, 2, @"ANY link.floatObj <= %@", @3.3f);
    RLMAssertCount(LinkToAllOptionalPrimitiveArrays, 2, @"ANY link.doubleObj <= %@", @3.3);
    RLMAssertCount(LinkToAllOptionalPrimitiveArrays, 2, @"ANY link.dateObj <= %@", date(2));
    RLMAssertCount(LinkToAllOptionalPrimitiveArrays, 2, @"ANY link.decimalObj <= %@", decimal128(3));

    RLMAssertThrowsWithReason(([LinkToAllPrimitiveArrays objectsInRealm:realm where:@"ANY link.boolObj > %@", @NO]),
                              @"Operator '>' not supported for type 'bool'");
    RLMAssertThrowsWithReason(([LinkToAllPrimitiveArrays objectsInRealm:realm where:@"ANY link.stringObj > %@", @"a"]),
                              @"Operator '>' not supported for type 'string'");
    RLMAssertThrowsWithReason(([LinkToAllPrimitiveArrays objectsInRealm:realm where:@"ANY link.dataObj > %@", data(1)]),
                              @"Operator '>' not supported for type 'data'");
    RLMAssertThrowsWithReason(([LinkToAllPrimitiveArrays objectsInRealm:realm where:@"ANY link.objectIdObj > %@", objectId(1)]),
                              @"Operator '>' not supported for type 'object id'");
    RLMAssertThrowsWithReason(([LinkToAllPrimitiveArrays objectsInRealm:realm where:@"ANY link.uuidObj > %@", uuid(@"00000000-0000-0000-0000-000000000000")]),
                              @"Operator '>' not supported for type 'uuid'");
    RLMAssertThrowsWithReason(([LinkToAllOptionalPrimitiveArrays objectsInRealm:realm where:@"ANY link.boolObj > %@", @NO]),
                              @"Operator '>' not supported for type 'bool'");
    RLMAssertThrowsWithReason(([LinkToAllOptionalPrimitiveArrays objectsInRealm:realm where:@"ANY link.stringObj > %@", @"a"]),
                              @"Operator '>' not supported for type 'string'");
    RLMAssertThrowsWithReason(([LinkToAllOptionalPrimitiveArrays objectsInRealm:realm where:@"ANY link.dataObj > %@", data(1)]),
                              @"Operator '>' not supported for type 'data'");
    RLMAssertThrowsWithReason(([LinkToAllOptionalPrimitiveArrays objectsInRealm:realm where:@"ANY link.objectIdObj > %@", objectId(1)]),
                              @"Operator '>' not supported for type 'object id'");
    RLMAssertThrowsWithReason(([LinkToAllOptionalPrimitiveArrays objectsInRealm:realm where:@"ANY link.uuidObj > %@", uuid(@"00000000-0000-0000-0000-000000000000")]),
                              @"Operator '>' not supported for type 'uuid'");
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
        id obj = [AllPrimitiveArrays createInRealm:realm withValue:@{
            @"stringObj": @[value],
            @"dataObj": @[[value dataUsingEncoding:NSUTF8StringEncoding]]
        }];
        [LinkToAllPrimitiveArrays createInRealm:realm withValue:@[obj]];
        obj = [AllOptionalPrimitiveArrays createInRealm:realm withValue:@{
            @"stringObj": @[value],
            @"dataObj": @[[value dataUsingEncoding:NSUTF8StringEncoding]]
        }];
        [LinkToAllOptionalPrimitiveArrays createInRealm:realm withValue:@[obj]];
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
        RLMAssertCount(AllPrimitiveArrays, count, query, value);
        RLMAssertCount(AllPrimitiveArrays, count, query, value);
        RLMAssertCount(AllOptionalPrimitiveArrays, count, query, value);
        query = [NSString stringWithFormat:@"ANY link.stringObj %@ %%@", operator];
        RLMAssertCount(LinkToAllPrimitiveArrays, count, query, value);
        RLMAssertCount(LinkToAllPrimitiveArrays, count, query, value);
        RLMAssertCount(LinkToAllOptionalPrimitiveArrays, count, query, value);

        query = [NSString stringWithFormat:@"ANY dataObj %@ %%@", operator];
        RLMAssertCount(AllPrimitiveArrays, count, query, data);
        RLMAssertCount(AllPrimitiveArrays, count, query, data);
        RLMAssertCount(AllOptionalPrimitiveArrays, count, query, data);
        query = [NSString stringWithFormat:@"ANY link.dataObj %@ %%@", operator];
        RLMAssertCount(LinkToAllPrimitiveArrays, count, query, data);
        RLMAssertCount(LinkToAllPrimitiveArrays, count, query, data);
        RLMAssertCount(LinkToAllOptionalPrimitiveArrays, count, query, data);
    };
    void (^testNull)(NSString *, NSUInteger) = ^(NSString *operator, NSUInteger count) {
        NSString *query = [NSString stringWithFormat:@"ANY stringObj %@ nil", operator];
        RLMAssertThrowsWithReason([AllPrimitiveArrays objectsInRealm:realm where:query],
                                  @"Expected object of type string for property 'stringObj' on object of type 'AllPrimitiveArrays', but received: (null)");
        RLMAssertCount(AllOptionalPrimitiveArrays, count, query, NSNull.null);
        query = [NSString stringWithFormat:@"ANY link.stringObj %@ nil", operator];
        RLMAssertThrowsWithReason([LinkToAllPrimitiveArrays objectsInRealm:realm where:query],
                                  @"Expected object of type string for property 'link.stringObj' on object of type 'LinkToAllPrimitiveArrays', but received: (null)");
        RLMAssertCount(LinkToAllOptionalPrimitiveArrays, count, query, NSNull.null);

        query = [NSString stringWithFormat:@"ANY dataObj %@ nil", operator];
        RLMAssertThrowsWithReason([AllPrimitiveArrays objectsInRealm:realm where:query],
                                  @"Expected object of type data for property 'dataObj' on object of type 'AllPrimitiveArrays', but received: (null)");
        RLMAssertCount(AllOptionalPrimitiveArrays, count, query, NSNull.null);

        query = [NSString stringWithFormat:@"ANY link.dataObj %@ nil", operator];
        RLMAssertThrowsWithReason([LinkToAllPrimitiveArrays objectsInRealm:realm where:query],
                                  @"Expected object of type data for property 'link.dataObj' on object of type 'LinkToAllPrimitiveArrays', but received: (null)");
        RLMAssertCount(LinkToAllOptionalPrimitiveArrays, count, query, NSNull.null);
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
