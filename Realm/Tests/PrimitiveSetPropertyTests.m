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
    [unmanaged.stringObj addObjects:@[@"a", @"bc"]];
    [unmanaged.dataObj addObjects:@[data(1), data(2)]];
    [unmanaged.dateObj addObjects:@[date(1), date(2)]];
    [unmanaged.decimalObj addObjects:@[decimal128(1), decimal128(2)]];
    [unmanaged.objectIdObj addObjects:@[objectId(1), objectId(2)]];
    [unmanaged.uuidObj addObjects:@[uuid(@"00000000-0000-0000-0000-000000000000"), uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")]];
    [unmanaged.anyBoolObj addObjects:@[@NO, @YES]];
    [unmanaged.anyIntObj addObjects:@[@2, @3]];
    [unmanaged.anyFloatObj addObjects:@[@2.2f, @3.3f]];
    [unmanaged.anyDoubleObj addObjects:@[@2.2, @3.3]];
    [unmanaged.anyStringObj addObjects:@[@"a", @"b"]];
    [unmanaged.anyDataObj addObjects:@[data(1), data(2)]];
    [unmanaged.anyDateObj addObjects:@[date(1), date(2)]];
    [unmanaged.anyDecimalObj addObjects:@[decimal128(1), decimal128(2)]];
    [unmanaged.anyObjectIdObj addObjects:@[objectId(1), objectId(2)]];
    [unmanaged.anyUUIDObj addObjects:@[uuid(@"00000000-0000-0000-0000-000000000000"), uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")]];
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
    [managed.anyBoolObj addObjects:@[@NO, @YES]];
    [managed.anyIntObj addObjects:@[@2, @3]];
    [managed.anyFloatObj addObjects:@[@2.2f, @3.3f]];
    [managed.anyDoubleObj addObjects:@[@2.2, @3.3]];
    [managed.anyStringObj addObjects:@[@"a", @"b"]];
    [managed.anyDataObj addObjects:@[data(1), data(2)]];
    [managed.anyDateObj addObjects:@[date(1), date(2)]];
    [managed.anyDecimalObj addObjects:@[decimal128(1), decimal128(2)]];
    [managed.anyObjectIdObj addObjects:@[objectId(1), objectId(2)]];
    [managed.anyUUIDObj addObjects:@[uuid(@"00000000-0000-0000-0000-000000000000"), uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")]];
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
    for (RLMSet *set in allSets) {
        RLMAssertThrowsWithReason([realm deleteObjects:set], @"Cannot delete objects from RLMSet");
    }
}

- (void)testObjectAtIndex {
    RLMAssertThrowsWithReason([unmanaged.intObj objectAtIndex:0],
                              @"Index 0 is out of bounds (must be less than 0).");

    [unmanaged.intObj addObject:@1];
    uncheckedAssertEqualObjects([unmanaged.intObj objectAtIndex:0], @1);
}

- (void)testContainsObject {
    uncheckedAssertFalse([unmanaged.boolObj containsObject:@NO]);
    uncheckedAssertFalse([unmanaged.intObj containsObject:@2]);
    uncheckedAssertFalse([unmanaged.floatObj containsObject:@2.2f]);
    uncheckedAssertFalse([unmanaged.doubleObj containsObject:@2.2]);
    uncheckedAssertFalse([unmanaged.stringObj containsObject:@"a"]);
    uncheckedAssertFalse([unmanaged.dataObj containsObject:data(1)]);
    uncheckedAssertFalse([unmanaged.dateObj containsObject:date(1)]);
    uncheckedAssertFalse([unmanaged.decimalObj containsObject:decimal128(1)]);
    uncheckedAssertFalse([unmanaged.objectIdObj containsObject:objectId(1)]);
    uncheckedAssertFalse([unmanaged.uuidObj containsObject:uuid(@"00000000-0000-0000-0000-000000000000")]);
    uncheckedAssertFalse([unmanaged.anyBoolObj containsObject:@NO]);
    uncheckedAssertFalse([unmanaged.anyIntObj containsObject:@2]);
    uncheckedAssertFalse([unmanaged.anyFloatObj containsObject:@2.2f]);
    uncheckedAssertFalse([unmanaged.anyDoubleObj containsObject:@2.2]);
    uncheckedAssertFalse([unmanaged.anyStringObj containsObject:@"a"]);
    uncheckedAssertFalse([unmanaged.anyDataObj containsObject:data(1)]);
    uncheckedAssertFalse([unmanaged.anyDateObj containsObject:date(1)]);
    uncheckedAssertFalse([unmanaged.anyDecimalObj containsObject:decimal128(1)]);
    uncheckedAssertFalse([unmanaged.anyObjectIdObj containsObject:objectId(1)]);
    uncheckedAssertFalse([unmanaged.anyUUIDObj containsObject:uuid(@"00000000-0000-0000-0000-000000000000")]);
    uncheckedAssertFalse([optUnmanaged.boolObj containsObject:NSNull.null]);
    uncheckedAssertFalse([optUnmanaged.intObj containsObject:NSNull.null]);
    uncheckedAssertFalse([optUnmanaged.floatObj containsObject:NSNull.null]);
    uncheckedAssertFalse([optUnmanaged.doubleObj containsObject:NSNull.null]);
    uncheckedAssertFalse([optUnmanaged.stringObj containsObject:NSNull.null]);
    uncheckedAssertFalse([optUnmanaged.dataObj containsObject:NSNull.null]);
    uncheckedAssertFalse([optUnmanaged.dateObj containsObject:NSNull.null]);
    uncheckedAssertFalse([optUnmanaged.decimalObj containsObject:NSNull.null]);
    uncheckedAssertFalse([optUnmanaged.objectIdObj containsObject:NSNull.null]);
    uncheckedAssertFalse([optUnmanaged.uuidObj containsObject:NSNull.null]);
    uncheckedAssertFalse([managed.boolObj containsObject:@NO]);
    uncheckedAssertFalse([managed.intObj containsObject:@2]);
    uncheckedAssertFalse([managed.floatObj containsObject:@2.2f]);
    uncheckedAssertFalse([managed.doubleObj containsObject:@2.2]);
    uncheckedAssertFalse([managed.stringObj containsObject:@"a"]);
    uncheckedAssertFalse([managed.dataObj containsObject:data(1)]);
    uncheckedAssertFalse([managed.dateObj containsObject:date(1)]);
    uncheckedAssertFalse([managed.decimalObj containsObject:decimal128(1)]);
    uncheckedAssertFalse([managed.objectIdObj containsObject:objectId(1)]);
    uncheckedAssertFalse([managed.uuidObj containsObject:uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")]);
    uncheckedAssertFalse([managed.anyBoolObj containsObject:@NO]);
    uncheckedAssertFalse([managed.anyIntObj containsObject:@2]);
    uncheckedAssertFalse([managed.anyFloatObj containsObject:@2.2f]);
    uncheckedAssertFalse([managed.anyDoubleObj containsObject:@2.2]);
    uncheckedAssertFalse([managed.anyStringObj containsObject:@"a"]);
    uncheckedAssertFalse([managed.anyDataObj containsObject:data(1)]);
    uncheckedAssertFalse([managed.anyDateObj containsObject:date(1)]);
    uncheckedAssertFalse([managed.anyDecimalObj containsObject:decimal128(1)]);
    uncheckedAssertFalse([managed.anyObjectIdObj containsObject:objectId(1)]);
    uncheckedAssertFalse([managed.anyUUIDObj containsObject:uuid(@"00000000-0000-0000-0000-000000000000")]);
    uncheckedAssertFalse([optManaged.boolObj containsObject:NSNull.null]);
    uncheckedAssertFalse([optManaged.intObj containsObject:NSNull.null]);
    uncheckedAssertFalse([optManaged.floatObj containsObject:NSNull.null]);
    uncheckedAssertFalse([optManaged.doubleObj containsObject:NSNull.null]);
    uncheckedAssertFalse([optManaged.stringObj containsObject:NSNull.null]);
    uncheckedAssertFalse([optManaged.dataObj containsObject:NSNull.null]);
    uncheckedAssertFalse([optManaged.dateObj containsObject:NSNull.null]);
    uncheckedAssertFalse([optManaged.decimalObj containsObject:NSNull.null]);
    uncheckedAssertFalse([optManaged.objectIdObj containsObject:NSNull.null]);
    uncheckedAssertFalse([optManaged.uuidObj containsObject:NSNull.null]);
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
    [unmanaged.anyBoolObj addObject:@NO];
    [unmanaged.anyIntObj addObject:@2];
    [unmanaged.anyFloatObj addObject:@2.2f];
    [unmanaged.anyDoubleObj addObject:@2.2];
    [unmanaged.anyStringObj addObject:@"a"];
    [unmanaged.anyDataObj addObject:data(1)];
    [unmanaged.anyDateObj addObject:date(1)];
    [unmanaged.anyDecimalObj addObject:decimal128(1)];
    [unmanaged.anyObjectIdObj addObject:objectId(1)];
    [unmanaged.anyUUIDObj addObject:uuid(@"00000000-0000-0000-0000-000000000000")];
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
    [managed.anyBoolObj addObject:@NO];
    [managed.anyIntObj addObject:@2];
    [managed.anyFloatObj addObject:@2.2f];
    [managed.anyDoubleObj addObject:@2.2];
    [managed.anyStringObj addObject:@"a"];
    [managed.anyDataObj addObject:data(1)];
    [managed.anyDateObj addObject:date(1)];
    [managed.anyDecimalObj addObject:decimal128(1)];
    [managed.anyObjectIdObj addObject:objectId(1)];
    [managed.anyUUIDObj addObject:uuid(@"00000000-0000-0000-0000-000000000000")];
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
    uncheckedAssertTrue([unmanaged.boolObj containsObject:@NO]);
    uncheckedAssertTrue([unmanaged.intObj containsObject:@2]);
    uncheckedAssertTrue([unmanaged.floatObj containsObject:@2.2f]);
    uncheckedAssertTrue([unmanaged.doubleObj containsObject:@2.2]);
    uncheckedAssertTrue([unmanaged.stringObj containsObject:@"a"]);
    uncheckedAssertTrue([unmanaged.dataObj containsObject:data(1)]);
    uncheckedAssertTrue([unmanaged.dateObj containsObject:date(1)]);
    uncheckedAssertTrue([unmanaged.decimalObj containsObject:decimal128(1)]);
    uncheckedAssertTrue([unmanaged.objectIdObj containsObject:objectId(1)]);
    uncheckedAssertTrue([unmanaged.uuidObj containsObject:uuid(@"00000000-0000-0000-0000-000000000000")]);
    uncheckedAssertTrue([unmanaged.anyBoolObj containsObject:@NO]);
    uncheckedAssertTrue([unmanaged.anyIntObj containsObject:@2]);
    uncheckedAssertTrue([unmanaged.anyFloatObj containsObject:@2.2f]);
    uncheckedAssertTrue([unmanaged.anyDoubleObj containsObject:@2.2]);
    uncheckedAssertTrue([unmanaged.anyStringObj containsObject:@"a"]);
    uncheckedAssertTrue([unmanaged.anyDataObj containsObject:data(1)]);
    uncheckedAssertTrue([unmanaged.anyDateObj containsObject:date(1)]);
    uncheckedAssertTrue([unmanaged.anyDecimalObj containsObject:decimal128(1)]);
    uncheckedAssertTrue([unmanaged.anyObjectIdObj containsObject:objectId(1)]);
    uncheckedAssertTrue([unmanaged.anyUUIDObj containsObject:uuid(@"00000000-0000-0000-0000-000000000000")]);
    uncheckedAssertTrue([optUnmanaged.boolObj containsObject:NSNull.null]);
    uncheckedAssertTrue([optUnmanaged.intObj containsObject:NSNull.null]);
    uncheckedAssertTrue([optUnmanaged.floatObj containsObject:NSNull.null]);
    uncheckedAssertTrue([optUnmanaged.doubleObj containsObject:NSNull.null]);
    uncheckedAssertTrue([optUnmanaged.stringObj containsObject:NSNull.null]);
    uncheckedAssertTrue([optUnmanaged.dataObj containsObject:NSNull.null]);
    uncheckedAssertTrue([optUnmanaged.dateObj containsObject:NSNull.null]);
    uncheckedAssertTrue([optUnmanaged.decimalObj containsObject:NSNull.null]);
    uncheckedAssertTrue([optUnmanaged.objectIdObj containsObject:NSNull.null]);
    uncheckedAssertTrue([optUnmanaged.uuidObj containsObject:NSNull.null]);
    uncheckedAssertTrue([managed.boolObj containsObject:@NO]);
    uncheckedAssertTrue([managed.intObj containsObject:@2]);
    uncheckedAssertTrue([managed.floatObj containsObject:@2.2f]);
    uncheckedAssertTrue([managed.doubleObj containsObject:@2.2]);
    uncheckedAssertTrue([managed.stringObj containsObject:@"a"]);
    uncheckedAssertTrue([managed.dataObj containsObject:data(1)]);
    uncheckedAssertTrue([managed.dateObj containsObject:date(1)]);
    uncheckedAssertTrue([managed.decimalObj containsObject:decimal128(1)]);
    uncheckedAssertTrue([managed.objectIdObj containsObject:objectId(1)]);
    uncheckedAssertTrue([managed.uuidObj containsObject:uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")]);
    uncheckedAssertTrue([managed.anyBoolObj containsObject:@NO]);
    uncheckedAssertTrue([managed.anyIntObj containsObject:@2]);
    uncheckedAssertTrue([managed.anyFloatObj containsObject:@2.2f]);
    uncheckedAssertTrue([managed.anyDoubleObj containsObject:@2.2]);
    uncheckedAssertTrue([managed.anyStringObj containsObject:@"a"]);
    uncheckedAssertTrue([managed.anyDataObj containsObject:data(1)]);
    uncheckedAssertTrue([managed.anyDateObj containsObject:date(1)]);
    uncheckedAssertTrue([managed.anyDecimalObj containsObject:decimal128(1)]);
    uncheckedAssertTrue([managed.anyObjectIdObj containsObject:objectId(1)]);
    uncheckedAssertTrue([managed.anyUUIDObj containsObject:uuid(@"00000000-0000-0000-0000-000000000000")]);
    uncheckedAssertTrue([optManaged.boolObj containsObject:NSNull.null]);
    uncheckedAssertTrue([optManaged.intObj containsObject:NSNull.null]);
    uncheckedAssertTrue([optManaged.floatObj containsObject:NSNull.null]);
    uncheckedAssertTrue([optManaged.doubleObj containsObject:NSNull.null]);
    uncheckedAssertTrue([optManaged.stringObj containsObject:NSNull.null]);
    uncheckedAssertTrue([optManaged.dataObj containsObject:NSNull.null]);
    uncheckedAssertTrue([optManaged.dateObj containsObject:NSNull.null]);
    uncheckedAssertTrue([optManaged.decimalObj containsObject:NSNull.null]);
    uncheckedAssertTrue([optManaged.objectIdObj containsObject:NSNull.null]);
    uncheckedAssertTrue([optManaged.uuidObj containsObject:NSNull.null]);
}

- (void)testAddObject {
    RLMAssertThrowsWithReason([unmanaged.boolObj addObject:@"a"], 
                              @"Invalid value 'a' of type '" RLMConstantString "' for expected type 'bool'");
    RLMAssertThrowsWithReason([unmanaged.intObj addObject:@"a"], 
                              @"Invalid value 'a' of type '" RLMConstantString "' for expected type 'int'");
    RLMAssertThrowsWithReason([unmanaged.floatObj addObject:@"a"], 
                              @"Invalid value 'a' of type '" RLMConstantString "' for expected type 'float'");
    RLMAssertThrowsWithReason([unmanaged.doubleObj addObject:@"a"], 
                              @"Invalid value 'a' of type '" RLMConstantString "' for expected type 'double'");
    RLMAssertThrowsWithReason([unmanaged.stringObj addObject:@2], 
                              @"Invalid value '2' of type '" RLMConstantInt "' for expected type 'string'");
    RLMAssertThrowsWithReason([unmanaged.dataObj addObject:@"a"], 
                              @"Invalid value 'a' of type '" RLMConstantString "' for expected type 'data'");
    RLMAssertThrowsWithReason([unmanaged.dateObj addObject:@"a"], 
                              @"Invalid value 'a' of type '" RLMConstantString "' for expected type 'date'");
    RLMAssertThrowsWithReason([unmanaged.decimalObj addObject:@"a"], 
                              @"Invalid value 'a' of type '" RLMConstantString "' for expected type 'decimal128'");
    RLMAssertThrowsWithReason([unmanaged.objectIdObj addObject:@"a"], 
                              @"Invalid value 'a' of type '" RLMConstantString "' for expected type 'object id'");
    RLMAssertThrowsWithReason([unmanaged.uuidObj addObject:@"a"], 
                              @"Invalid value 'a' of type '" RLMConstantString "' for expected type 'uuid'");
    RLMAssertThrowsWithReason([optUnmanaged.boolObj addObject:@"a"], 
                              @"Invalid value 'a' of type '" RLMConstantString "' for expected type 'bool?'");
    RLMAssertThrowsWithReason([optUnmanaged.intObj addObject:@"a"], 
                              @"Invalid value 'a' of type '" RLMConstantString "' for expected type 'int?'");
    RLMAssertThrowsWithReason([optUnmanaged.floatObj addObject:@"a"], 
                              @"Invalid value 'a' of type '" RLMConstantString "' for expected type 'float?'");
    RLMAssertThrowsWithReason([optUnmanaged.doubleObj addObject:@"a"], 
                              @"Invalid value 'a' of type '" RLMConstantString "' for expected type 'double?'");
    RLMAssertThrowsWithReason([optUnmanaged.stringObj addObject:@2], 
                              @"Invalid value '2' of type '" RLMConstantInt "' for expected type 'string?'");
    RLMAssertThrowsWithReason([optUnmanaged.dataObj addObject:@"a"], 
                              @"Invalid value 'a' of type '" RLMConstantString "' for expected type 'data?'");
    RLMAssertThrowsWithReason([optUnmanaged.dateObj addObject:@"a"], 
                              @"Invalid value 'a' of type '" RLMConstantString "' for expected type 'date?'");
    RLMAssertThrowsWithReason([optUnmanaged.decimalObj addObject:@"a"], 
                              @"Invalid value 'a' of type '" RLMConstantString "' for expected type 'decimal128?'");
    RLMAssertThrowsWithReason([optUnmanaged.objectIdObj addObject:@"a"], 
                              @"Invalid value 'a' of type '" RLMConstantString "' for expected type 'object id?'");
    RLMAssertThrowsWithReason([optUnmanaged.uuidObj addObject:@"a"], 
                              @"Invalid value 'a' of type '" RLMConstantString "' for expected type 'uuid?'");
    RLMAssertThrowsWithReason([managed.boolObj addObject:@"a"], 
                              @"Invalid value 'a' of type '" RLMConstantString "' for expected type 'bool'");
    RLMAssertThrowsWithReason([managed.intObj addObject:@"a"], 
                              @"Invalid value 'a' of type '" RLMConstantString "' for expected type 'int'");
    RLMAssertThrowsWithReason([managed.floatObj addObject:@"a"], 
                              @"Invalid value 'a' of type '" RLMConstantString "' for expected type 'float'");
    RLMAssertThrowsWithReason([managed.doubleObj addObject:@"a"], 
                              @"Invalid value 'a' of type '" RLMConstantString "' for expected type 'double'");
    RLMAssertThrowsWithReason([managed.stringObj addObject:@2], 
                              @"Invalid value '2' of type '" RLMConstantInt "' for expected type 'string'");
    RLMAssertThrowsWithReason([managed.dataObj addObject:@"a"], 
                              @"Invalid value 'a' of type '" RLMConstantString "' for expected type 'data'");
    RLMAssertThrowsWithReason([managed.dateObj addObject:@"a"], 
                              @"Invalid value 'a' of type '" RLMConstantString "' for expected type 'date'");
    RLMAssertThrowsWithReason([managed.decimalObj addObject:@"a"], 
                              @"Invalid value 'a' of type '" RLMConstantString "' for expected type 'decimal128'");
    RLMAssertThrowsWithReason([managed.objectIdObj addObject:@"a"], 
                              @"Invalid value 'a' of type '" RLMConstantString "' for expected type 'object id'");
    RLMAssertThrowsWithReason([managed.uuidObj addObject:@"a"], 
                              @"Invalid value 'a' of type '" RLMConstantString "' for expected type 'uuid'");
    RLMAssertThrowsWithReason([optManaged.boolObj addObject:@"a"], 
                              @"Invalid value 'a' of type '" RLMConstantString "' for expected type 'bool?'");
    RLMAssertThrowsWithReason([optManaged.intObj addObject:@"a"], 
                              @"Invalid value 'a' of type '" RLMConstantString "' for expected type 'int?'");
    RLMAssertThrowsWithReason([optManaged.floatObj addObject:@"a"], 
                              @"Invalid value 'a' of type '" RLMConstantString "' for expected type 'float?'");
    RLMAssertThrowsWithReason([optManaged.doubleObj addObject:@"a"], 
                              @"Invalid value 'a' of type '" RLMConstantString "' for expected type 'double?'");
    RLMAssertThrowsWithReason([optManaged.stringObj addObject:@2], 
                              @"Invalid value '2' of type '" RLMConstantInt "' for expected type 'string?'");
    RLMAssertThrowsWithReason([optManaged.dataObj addObject:@"a"], 
                              @"Invalid value 'a' of type '" RLMConstantString "' for expected type 'data?'");
    RLMAssertThrowsWithReason([optManaged.dateObj addObject:@"a"], 
                              @"Invalid value 'a' of type '" RLMConstantString "' for expected type 'date?'");
    RLMAssertThrowsWithReason([optManaged.decimalObj addObject:@"a"], 
                              @"Invalid value 'a' of type '" RLMConstantString "' for expected type 'decimal128?'");
    RLMAssertThrowsWithReason([optManaged.objectIdObj addObject:@"a"], 
                              @"Invalid value 'a' of type '" RLMConstantString "' for expected type 'object id?'");
    RLMAssertThrowsWithReason([optManaged.uuidObj addObject:@"a"], 
                              @"Invalid value 'a' of type '" RLMConstantString "' for expected type 'uuid?'");
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
    [unmanaged.anyBoolObj addObject:@NO];
    [unmanaged.anyIntObj addObject:@2];
    [unmanaged.anyFloatObj addObject:@2.2f];
    [unmanaged.anyDoubleObj addObject:@2.2];
    [unmanaged.anyStringObj addObject:@"a"];
    [unmanaged.anyDataObj addObject:data(1)];
    [unmanaged.anyDateObj addObject:date(1)];
    [unmanaged.anyDecimalObj addObject:decimal128(1)];
    [unmanaged.anyObjectIdObj addObject:objectId(1)];
    [unmanaged.anyUUIDObj addObject:uuid(@"00000000-0000-0000-0000-000000000000")];
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
    [managed.anyBoolObj addObject:@NO];
    [managed.anyIntObj addObject:@2];
    [managed.anyFloatObj addObject:@2.2f];
    [managed.anyDoubleObj addObject:@2.2];
    [managed.anyStringObj addObject:@"a"];
    [managed.anyDataObj addObject:data(1)];
    [managed.anyDateObj addObject:date(1)];
    [managed.anyDecimalObj addObject:decimal128(1)];
    [managed.anyObjectIdObj addObject:objectId(1)];
    [managed.anyUUIDObj addObject:uuid(@"00000000-0000-0000-0000-000000000000")];
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
    uncheckedAssertTrue([unmanaged.boolObj containsObject:@NO]);
    uncheckedAssertTrue([unmanaged.intObj containsObject:@2]);
    uncheckedAssertTrue([unmanaged.floatObj containsObject:@2.2f]);
    uncheckedAssertTrue([unmanaged.doubleObj containsObject:@2.2]);
    uncheckedAssertTrue([unmanaged.stringObj containsObject:@"a"]);
    uncheckedAssertTrue([unmanaged.dataObj containsObject:data(1)]);
    uncheckedAssertTrue([unmanaged.dateObj containsObject:date(1)]);
    uncheckedAssertTrue([unmanaged.decimalObj containsObject:decimal128(1)]);
    uncheckedAssertTrue([unmanaged.objectIdObj containsObject:objectId(1)]);
    uncheckedAssertTrue([unmanaged.uuidObj containsObject:uuid(@"00000000-0000-0000-0000-000000000000")]);
    uncheckedAssertTrue([unmanaged.anyBoolObj containsObject:@NO]);
    uncheckedAssertTrue([unmanaged.anyIntObj containsObject:@2]);
    uncheckedAssertTrue([unmanaged.anyFloatObj containsObject:@2.2f]);
    uncheckedAssertTrue([unmanaged.anyDoubleObj containsObject:@2.2]);
    uncheckedAssertTrue([unmanaged.anyStringObj containsObject:@"a"]);
    uncheckedAssertTrue([unmanaged.anyDataObj containsObject:data(1)]);
    uncheckedAssertTrue([unmanaged.anyDateObj containsObject:date(1)]);
    uncheckedAssertTrue([unmanaged.anyDecimalObj containsObject:decimal128(1)]);
    uncheckedAssertTrue([unmanaged.anyObjectIdObj containsObject:objectId(1)]);
    uncheckedAssertTrue([unmanaged.anyUUIDObj containsObject:uuid(@"00000000-0000-0000-0000-000000000000")]);
    uncheckedAssertTrue([optUnmanaged.boolObj containsObject:NSNull.null]);
    uncheckedAssertTrue([optUnmanaged.intObj containsObject:NSNull.null]);
    uncheckedAssertTrue([optUnmanaged.floatObj containsObject:NSNull.null]);
    uncheckedAssertTrue([optUnmanaged.doubleObj containsObject:NSNull.null]);
    uncheckedAssertTrue([optUnmanaged.stringObj containsObject:NSNull.null]);
    uncheckedAssertTrue([optUnmanaged.dataObj containsObject:NSNull.null]);
    uncheckedAssertTrue([optUnmanaged.dateObj containsObject:NSNull.null]);
    uncheckedAssertTrue([optUnmanaged.decimalObj containsObject:NSNull.null]);
    uncheckedAssertTrue([optUnmanaged.objectIdObj containsObject:NSNull.null]);
    uncheckedAssertTrue([optUnmanaged.uuidObj containsObject:NSNull.null]);
    uncheckedAssertTrue([managed.boolObj containsObject:@NO]);
    uncheckedAssertTrue([managed.intObj containsObject:@2]);
    uncheckedAssertTrue([managed.floatObj containsObject:@2.2f]);
    uncheckedAssertTrue([managed.doubleObj containsObject:@2.2]);
    uncheckedAssertTrue([managed.stringObj containsObject:@"a"]);
    uncheckedAssertTrue([managed.dataObj containsObject:data(1)]);
    uncheckedAssertTrue([managed.dateObj containsObject:date(1)]);
    uncheckedAssertTrue([managed.decimalObj containsObject:decimal128(1)]);
    uncheckedAssertTrue([managed.objectIdObj containsObject:objectId(1)]);
    uncheckedAssertTrue([managed.uuidObj containsObject:uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")]);
    uncheckedAssertTrue([managed.anyBoolObj containsObject:@NO]);
    uncheckedAssertTrue([managed.anyIntObj containsObject:@2]);
    uncheckedAssertTrue([managed.anyFloatObj containsObject:@2.2f]);
    uncheckedAssertTrue([managed.anyDoubleObj containsObject:@2.2]);
    uncheckedAssertTrue([managed.anyStringObj containsObject:@"a"]);
    uncheckedAssertTrue([managed.anyDataObj containsObject:data(1)]);
    uncheckedAssertTrue([managed.anyDateObj containsObject:date(1)]);
    uncheckedAssertTrue([managed.anyDecimalObj containsObject:decimal128(1)]);
    uncheckedAssertTrue([managed.anyObjectIdObj containsObject:objectId(1)]);
    uncheckedAssertTrue([managed.anyUUIDObj containsObject:uuid(@"00000000-0000-0000-0000-000000000000")]);
    uncheckedAssertTrue([optManaged.boolObj containsObject:NSNull.null]);
    uncheckedAssertTrue([optManaged.intObj containsObject:NSNull.null]);
    uncheckedAssertTrue([optManaged.floatObj containsObject:NSNull.null]);
    uncheckedAssertTrue([optManaged.doubleObj containsObject:NSNull.null]);
    uncheckedAssertTrue([optManaged.stringObj containsObject:NSNull.null]);
    uncheckedAssertTrue([optManaged.dataObj containsObject:NSNull.null]);
    uncheckedAssertTrue([optManaged.dateObj containsObject:NSNull.null]);
    uncheckedAssertTrue([optManaged.decimalObj containsObject:NSNull.null]);
    uncheckedAssertTrue([optManaged.objectIdObj containsObject:NSNull.null]);
    uncheckedAssertTrue([optManaged.uuidObj containsObject:NSNull.null]);

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
    uncheckedAssertTrue([optUnmanaged.intObj containsObject:NSNull.null]);
    uncheckedAssertTrue([optUnmanaged.floatObj containsObject:NSNull.null]);
    uncheckedAssertTrue([optUnmanaged.doubleObj containsObject:NSNull.null]);
    uncheckedAssertTrue([optUnmanaged.stringObj containsObject:NSNull.null]);
    uncheckedAssertTrue([optUnmanaged.dataObj containsObject:NSNull.null]);
    uncheckedAssertTrue([optUnmanaged.dateObj containsObject:NSNull.null]);
    uncheckedAssertTrue([optUnmanaged.decimalObj containsObject:NSNull.null]);
    uncheckedAssertTrue([optUnmanaged.objectIdObj containsObject:NSNull.null]);
    uncheckedAssertTrue([optUnmanaged.uuidObj containsObject:NSNull.null]);
    uncheckedAssertTrue([optManaged.boolObj containsObject:NSNull.null]);
    uncheckedAssertTrue([optManaged.intObj containsObject:NSNull.null]);
    uncheckedAssertTrue([optManaged.floatObj containsObject:NSNull.null]);
    uncheckedAssertTrue([optManaged.doubleObj containsObject:NSNull.null]);
    uncheckedAssertTrue([optManaged.stringObj containsObject:NSNull.null]);
    uncheckedAssertTrue([optManaged.dataObj containsObject:NSNull.null]);
    uncheckedAssertTrue([optManaged.dateObj containsObject:NSNull.null]);
    uncheckedAssertTrue([optManaged.decimalObj containsObject:NSNull.null]);
    uncheckedAssertTrue([optManaged.objectIdObj containsObject:NSNull.null]);
    uncheckedAssertTrue([optManaged.uuidObj containsObject:NSNull.null]);
}

- (void)testAddObjects {
    RLMAssertThrowsWithReason([unmanaged.boolObj addObjects:@[@"a"]], 
                              @"Invalid value 'a' of type '" RLMConstantString "' for expected type 'bool'");
    RLMAssertThrowsWithReason([unmanaged.intObj addObjects:@[@"a"]], 
                              @"Invalid value 'a' of type '" RLMConstantString "' for expected type 'int'");
    RLMAssertThrowsWithReason([unmanaged.floatObj addObjects:@[@"a"]], 
                              @"Invalid value 'a' of type '" RLMConstantString "' for expected type 'float'");
    RLMAssertThrowsWithReason([unmanaged.doubleObj addObjects:@[@"a"]], 
                              @"Invalid value 'a' of type '" RLMConstantString "' for expected type 'double'");
    RLMAssertThrowsWithReason([unmanaged.stringObj addObjects:@[@2]], 
                              @"Invalid value '2' of type '" RLMConstantInt "' for expected type 'string'");
    RLMAssertThrowsWithReason([unmanaged.dataObj addObjects:@[@"a"]], 
                              @"Invalid value 'a' of type '" RLMConstantString "' for expected type 'data'");
    RLMAssertThrowsWithReason([unmanaged.dateObj addObjects:@[@"a"]], 
                              @"Invalid value 'a' of type '" RLMConstantString "' for expected type 'date'");
    RLMAssertThrowsWithReason([unmanaged.decimalObj addObjects:@[@"a"]], 
                              @"Invalid value 'a' of type '" RLMConstantString "' for expected type 'decimal128'");
    RLMAssertThrowsWithReason([unmanaged.objectIdObj addObjects:@[@"a"]], 
                              @"Invalid value 'a' of type '" RLMConstantString "' for expected type 'object id'");
    RLMAssertThrowsWithReason([unmanaged.uuidObj addObjects:@[@"a"]], 
                              @"Invalid value 'a' of type '" RLMConstantString "' for expected type 'uuid'");
    RLMAssertThrowsWithReason([optUnmanaged.boolObj addObjects:@[@"a"]], 
                              @"Invalid value 'a' of type '" RLMConstantString "' for expected type 'bool?'");
    RLMAssertThrowsWithReason([optUnmanaged.intObj addObjects:@[@"a"]], 
                              @"Invalid value 'a' of type '" RLMConstantString "' for expected type 'int?'");
    RLMAssertThrowsWithReason([optUnmanaged.floatObj addObjects:@[@"a"]], 
                              @"Invalid value 'a' of type '" RLMConstantString "' for expected type 'float?'");
    RLMAssertThrowsWithReason([optUnmanaged.doubleObj addObjects:@[@"a"]], 
                              @"Invalid value 'a' of type '" RLMConstantString "' for expected type 'double?'");
    RLMAssertThrowsWithReason([optUnmanaged.stringObj addObjects:@[@2]], 
                              @"Invalid value '2' of type '" RLMConstantInt "' for expected type 'string?'");
    RLMAssertThrowsWithReason([optUnmanaged.dataObj addObjects:@[@"a"]], 
                              @"Invalid value 'a' of type '" RLMConstantString "' for expected type 'data?'");
    RLMAssertThrowsWithReason([optUnmanaged.dateObj addObjects:@[@"a"]], 
                              @"Invalid value 'a' of type '" RLMConstantString "' for expected type 'date?'");
    RLMAssertThrowsWithReason([optUnmanaged.decimalObj addObjects:@[@"a"]], 
                              @"Invalid value 'a' of type '" RLMConstantString "' for expected type 'decimal128?'");
    RLMAssertThrowsWithReason([optUnmanaged.objectIdObj addObjects:@[@"a"]], 
                              @"Invalid value 'a' of type '" RLMConstantString "' for expected type 'object id?'");
    RLMAssertThrowsWithReason([optUnmanaged.uuidObj addObjects:@[@"a"]], 
                              @"Invalid value 'a' of type '" RLMConstantString "' for expected type 'uuid?'");
    RLMAssertThrowsWithReason([managed.boolObj addObjects:@[@"a"]], 
                              @"Invalid value 'a' of type '" RLMConstantString "' for expected type 'bool'");
    RLMAssertThrowsWithReason([managed.intObj addObjects:@[@"a"]], 
                              @"Invalid value 'a' of type '" RLMConstantString "' for expected type 'int'");
    RLMAssertThrowsWithReason([managed.floatObj addObjects:@[@"a"]], 
                              @"Invalid value 'a' of type '" RLMConstantString "' for expected type 'float'");
    RLMAssertThrowsWithReason([managed.doubleObj addObjects:@[@"a"]], 
                              @"Invalid value 'a' of type '" RLMConstantString "' for expected type 'double'");
    RLMAssertThrowsWithReason([managed.stringObj addObjects:@[@2]], 
                              @"Invalid value '2' of type '" RLMConstantInt "' for expected type 'string'");
    RLMAssertThrowsWithReason([managed.dataObj addObjects:@[@"a"]], 
                              @"Invalid value 'a' of type '" RLMConstantString "' for expected type 'data'");
    RLMAssertThrowsWithReason([managed.dateObj addObjects:@[@"a"]], 
                              @"Invalid value 'a' of type '" RLMConstantString "' for expected type 'date'");
    RLMAssertThrowsWithReason([managed.decimalObj addObjects:@[@"a"]], 
                              @"Invalid value 'a' of type '" RLMConstantString "' for expected type 'decimal128'");
    RLMAssertThrowsWithReason([managed.objectIdObj addObjects:@[@"a"]], 
                              @"Invalid value 'a' of type '" RLMConstantString "' for expected type 'object id'");
    RLMAssertThrowsWithReason([managed.uuidObj addObjects:@[@"a"]], 
                              @"Invalid value 'a' of type '" RLMConstantString "' for expected type 'uuid'");
    RLMAssertThrowsWithReason([optManaged.boolObj addObjects:@[@"a"]], 
                              @"Invalid value 'a' of type '" RLMConstantString "' for expected type 'bool?'");
    RLMAssertThrowsWithReason([optManaged.intObj addObjects:@[@"a"]], 
                              @"Invalid value 'a' of type '" RLMConstantString "' for expected type 'int?'");
    RLMAssertThrowsWithReason([optManaged.floatObj addObjects:@[@"a"]], 
                              @"Invalid value 'a' of type '" RLMConstantString "' for expected type 'float?'");
    RLMAssertThrowsWithReason([optManaged.doubleObj addObjects:@[@"a"]], 
                              @"Invalid value 'a' of type '" RLMConstantString "' for expected type 'double?'");
    RLMAssertThrowsWithReason([optManaged.stringObj addObjects:@[@2]], 
                              @"Invalid value '2' of type '" RLMConstantInt "' for expected type 'string?'");
    RLMAssertThrowsWithReason([optManaged.dataObj addObjects:@[@"a"]], 
                              @"Invalid value 'a' of type '" RLMConstantString "' for expected type 'data?'");
    RLMAssertThrowsWithReason([optManaged.dateObj addObjects:@[@"a"]], 
                              @"Invalid value 'a' of type '" RLMConstantString "' for expected type 'date?'");
    RLMAssertThrowsWithReason([optManaged.decimalObj addObjects:@[@"a"]], 
                              @"Invalid value 'a' of type '" RLMConstantString "' for expected type 'decimal128?'");
    RLMAssertThrowsWithReason([optManaged.objectIdObj addObjects:@[@"a"]], 
                              @"Invalid value 'a' of type '" RLMConstantString "' for expected type 'object id?'");
    RLMAssertThrowsWithReason([optManaged.uuidObj addObjects:@[@"a"]], 
                              @"Invalid value 'a' of type '" RLMConstantString "' for expected type 'uuid?'");
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
    uncheckedAssertTrue([unmanaged.boolObj containsObject:@NO]);
    uncheckedAssertTrue([unmanaged.intObj containsObject:@2]);
    uncheckedAssertTrue([unmanaged.floatObj containsObject:@2.2f]);
    uncheckedAssertTrue([unmanaged.doubleObj containsObject:@2.2]);
    uncheckedAssertTrue([unmanaged.stringObj containsObject:@"a"]);
    uncheckedAssertTrue([unmanaged.dataObj containsObject:data(1)]);
    uncheckedAssertTrue([unmanaged.dateObj containsObject:date(1)]);
    uncheckedAssertTrue([unmanaged.decimalObj containsObject:decimal128(1)]);
    uncheckedAssertTrue([unmanaged.objectIdObj containsObject:objectId(1)]);
    uncheckedAssertTrue([unmanaged.uuidObj containsObject:uuid(@"00000000-0000-0000-0000-000000000000")]);
    uncheckedAssertTrue([unmanaged.anyBoolObj containsObject:@NO]);
    uncheckedAssertTrue([unmanaged.anyIntObj containsObject:@2]);
    uncheckedAssertTrue([unmanaged.anyFloatObj containsObject:@2.2f]);
    uncheckedAssertTrue([unmanaged.anyDoubleObj containsObject:@2.2]);
    uncheckedAssertTrue([unmanaged.anyStringObj containsObject:@"a"]);
    uncheckedAssertTrue([unmanaged.anyDataObj containsObject:data(1)]);
    uncheckedAssertTrue([unmanaged.anyDateObj containsObject:date(1)]);
    uncheckedAssertTrue([unmanaged.anyDecimalObj containsObject:decimal128(1)]);
    uncheckedAssertTrue([unmanaged.anyObjectIdObj containsObject:objectId(1)]);
    uncheckedAssertTrue([unmanaged.anyUUIDObj containsObject:uuid(@"00000000-0000-0000-0000-000000000000")]);
    uncheckedAssertTrue([optUnmanaged.boolObj containsObject:NSNull.null]);
    uncheckedAssertTrue([optUnmanaged.intObj containsObject:NSNull.null]);
    uncheckedAssertTrue([optUnmanaged.floatObj containsObject:NSNull.null]);
    uncheckedAssertTrue([optUnmanaged.doubleObj containsObject:NSNull.null]);
    uncheckedAssertTrue([optUnmanaged.stringObj containsObject:NSNull.null]);
    uncheckedAssertTrue([optUnmanaged.dataObj containsObject:NSNull.null]);
    uncheckedAssertTrue([optUnmanaged.dateObj containsObject:NSNull.null]);
    uncheckedAssertTrue([optUnmanaged.decimalObj containsObject:NSNull.null]);
    uncheckedAssertTrue([optUnmanaged.objectIdObj containsObject:NSNull.null]);
    uncheckedAssertTrue([optUnmanaged.uuidObj containsObject:NSNull.null]);
    uncheckedAssertTrue([managed.boolObj containsObject:@NO]);
    uncheckedAssertTrue([managed.intObj containsObject:@2]);
    uncheckedAssertTrue([managed.floatObj containsObject:@2.2f]);
    uncheckedAssertTrue([managed.doubleObj containsObject:@2.2]);
    uncheckedAssertTrue([managed.stringObj containsObject:@"a"]);
    uncheckedAssertTrue([managed.dataObj containsObject:data(1)]);
    uncheckedAssertTrue([managed.dateObj containsObject:date(1)]);
    uncheckedAssertTrue([managed.decimalObj containsObject:decimal128(1)]);
    uncheckedAssertTrue([managed.objectIdObj containsObject:objectId(1)]);
    uncheckedAssertTrue([managed.uuidObj containsObject:uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")]);
    uncheckedAssertTrue([managed.anyBoolObj containsObject:@NO]);
    uncheckedAssertTrue([managed.anyIntObj containsObject:@2]);
    uncheckedAssertTrue([managed.anyFloatObj containsObject:@2.2f]);
    uncheckedAssertTrue([managed.anyDoubleObj containsObject:@2.2]);
    uncheckedAssertTrue([managed.anyStringObj containsObject:@"a"]);
    uncheckedAssertTrue([managed.anyDataObj containsObject:data(1)]);
    uncheckedAssertTrue([managed.anyDateObj containsObject:date(1)]);
    uncheckedAssertTrue([managed.anyDecimalObj containsObject:decimal128(1)]);
    uncheckedAssertTrue([managed.anyObjectIdObj containsObject:objectId(1)]);
    uncheckedAssertTrue([managed.anyUUIDObj containsObject:uuid(@"00000000-0000-0000-0000-000000000000")]);
    uncheckedAssertTrue([optManaged.boolObj containsObject:NSNull.null]);
    uncheckedAssertTrue([optManaged.intObj containsObject:NSNull.null]);
    uncheckedAssertTrue([optManaged.floatObj containsObject:NSNull.null]);
    uncheckedAssertTrue([optManaged.doubleObj containsObject:NSNull.null]);
    uncheckedAssertTrue([optManaged.stringObj containsObject:NSNull.null]);
    uncheckedAssertTrue([optManaged.dataObj containsObject:NSNull.null]);
    uncheckedAssertTrue([optManaged.dateObj containsObject:NSNull.null]);
    uncheckedAssertTrue([optManaged.decimalObj containsObject:NSNull.null]);
    uncheckedAssertTrue([optManaged.objectIdObj containsObject:NSNull.null]);
    uncheckedAssertTrue([optManaged.uuidObj containsObject:NSNull.null]);
    uncheckedAssertTrue([unmanaged.boolObj containsObject:@YES]);
    uncheckedAssertTrue([unmanaged.intObj containsObject:@3]);
    uncheckedAssertTrue([unmanaged.floatObj containsObject:@3.3f]);
    uncheckedAssertTrue([unmanaged.doubleObj containsObject:@3.3]);
    uncheckedAssertTrue([unmanaged.stringObj containsObject:@"bc"]);
    uncheckedAssertTrue([unmanaged.dataObj containsObject:data(2)]);
    uncheckedAssertTrue([unmanaged.dateObj containsObject:date(2)]);
    uncheckedAssertTrue([unmanaged.decimalObj containsObject:decimal128(2)]);
    uncheckedAssertTrue([unmanaged.objectIdObj containsObject:objectId(2)]);
    uncheckedAssertTrue([unmanaged.uuidObj containsObject:uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")]);
    uncheckedAssertTrue([unmanaged.anyBoolObj containsObject:@YES]);
    uncheckedAssertTrue([unmanaged.anyIntObj containsObject:@3]);
    uncheckedAssertTrue([unmanaged.anyFloatObj containsObject:@3.3f]);
    uncheckedAssertTrue([unmanaged.anyDoubleObj containsObject:@3.3]);
    uncheckedAssertTrue([unmanaged.anyStringObj containsObject:@"b"]);
    uncheckedAssertTrue([unmanaged.anyDataObj containsObject:data(2)]);
    uncheckedAssertTrue([unmanaged.anyDateObj containsObject:date(2)]);
    uncheckedAssertTrue([unmanaged.anyDecimalObj containsObject:decimal128(2)]);
    uncheckedAssertTrue([unmanaged.anyObjectIdObj containsObject:objectId(2)]);
    uncheckedAssertTrue([unmanaged.anyUUIDObj containsObject:uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")]);
    uncheckedAssertTrue([optUnmanaged.boolObj containsObject:@NO]);
    uncheckedAssertTrue([optUnmanaged.intObj containsObject:@2]);
    uncheckedAssertTrue([optUnmanaged.floatObj containsObject:@2.2f]);
    uncheckedAssertTrue([optUnmanaged.doubleObj containsObject:@2.2]);
    uncheckedAssertTrue([optUnmanaged.stringObj containsObject:@"a"]);
    uncheckedAssertTrue([optUnmanaged.dataObj containsObject:data(1)]);
    uncheckedAssertTrue([optUnmanaged.dateObj containsObject:date(1)]);
    uncheckedAssertTrue([optUnmanaged.decimalObj containsObject:decimal128(1)]);
    uncheckedAssertTrue([optUnmanaged.objectIdObj containsObject:objectId(1)]);
    uncheckedAssertTrue([optUnmanaged.uuidObj containsObject:uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")]);
    uncheckedAssertTrue([managed.boolObj containsObject:@YES]);
    uncheckedAssertTrue([managed.intObj containsObject:@3]);
    uncheckedAssertTrue([managed.floatObj containsObject:@3.3f]);
    uncheckedAssertTrue([managed.doubleObj containsObject:@3.3]);
    uncheckedAssertTrue([managed.stringObj containsObject:@"bc"]);
    uncheckedAssertTrue([managed.dataObj containsObject:data(2)]);
    uncheckedAssertTrue([managed.dateObj containsObject:date(2)]);
    uncheckedAssertTrue([managed.decimalObj containsObject:decimal128(2)]);
    uncheckedAssertTrue([managed.objectIdObj containsObject:objectId(2)]);
    uncheckedAssertTrue([managed.uuidObj containsObject:uuid(@"00000000-0000-0000-0000-000000000000")]);
    uncheckedAssertTrue([managed.anyBoolObj containsObject:@YES]);
    uncheckedAssertTrue([managed.anyIntObj containsObject:@3]);
    uncheckedAssertTrue([managed.anyFloatObj containsObject:@3.3f]);
    uncheckedAssertTrue([managed.anyDoubleObj containsObject:@3.3]);
    uncheckedAssertTrue([managed.anyStringObj containsObject:@"b"]);
    uncheckedAssertTrue([managed.anyDataObj containsObject:data(2)]);
    uncheckedAssertTrue([managed.anyDateObj containsObject:date(2)]);
    uncheckedAssertTrue([managed.anyDecimalObj containsObject:decimal128(2)]);
    uncheckedAssertTrue([managed.anyObjectIdObj containsObject:objectId(2)]);
    uncheckedAssertTrue([managed.anyUUIDObj containsObject:uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")]);
    uncheckedAssertTrue([optManaged.boolObj containsObject:@NO]);
    uncheckedAssertTrue([optManaged.intObj containsObject:@2]);
    uncheckedAssertTrue([optManaged.floatObj containsObject:@2.2f]);
    uncheckedAssertTrue([optManaged.doubleObj containsObject:@2.2]);
    uncheckedAssertTrue([optManaged.stringObj containsObject:@"a"]);
    uncheckedAssertTrue([optManaged.dataObj containsObject:data(1)]);
    uncheckedAssertTrue([optManaged.dateObj containsObject:date(1)]);
    uncheckedAssertTrue([optManaged.decimalObj containsObject:decimal128(1)]);
    uncheckedAssertTrue([optManaged.objectIdObj containsObject:objectId(1)]);
    uncheckedAssertTrue([optManaged.uuidObj containsObject:uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")]);
    uncheckedAssertTrue([optUnmanaged.intObj containsObject:@3]);
    uncheckedAssertTrue([optUnmanaged.floatObj containsObject:@3.3f]);
    uncheckedAssertTrue([optUnmanaged.doubleObj containsObject:@3.3]);
    uncheckedAssertTrue([optUnmanaged.stringObj containsObject:@"bc"]);
    uncheckedAssertTrue([optUnmanaged.dataObj containsObject:data(2)]);
    uncheckedAssertTrue([optUnmanaged.dateObj containsObject:date(2)]);
    uncheckedAssertTrue([optUnmanaged.decimalObj containsObject:decimal128(2)]);
    uncheckedAssertTrue([optUnmanaged.objectIdObj containsObject:objectId(2)]);
    uncheckedAssertTrue([optUnmanaged.uuidObj containsObject:uuid(@"00000000-0000-0000-0000-000000000000")]);
    uncheckedAssertTrue([optManaged.boolObj containsObject:@YES]);
    uncheckedAssertTrue([optManaged.intObj containsObject:@3]);
    uncheckedAssertTrue([optManaged.floatObj containsObject:@3.3f]);
    uncheckedAssertTrue([optManaged.doubleObj containsObject:@3.3]);
    uncheckedAssertTrue([optManaged.stringObj containsObject:@"bc"]);
    uncheckedAssertTrue([optManaged.dataObj containsObject:data(2)]);
    uncheckedAssertTrue([optManaged.dateObj containsObject:date(2)]);
    uncheckedAssertTrue([optManaged.decimalObj containsObject:decimal128(2)]);
    uncheckedAssertTrue([optManaged.objectIdObj containsObject:objectId(2)]);
    uncheckedAssertTrue([optManaged.uuidObj containsObject:uuid(@"00000000-0000-0000-0000-000000000000")]);
}

- (void)testRemoveObject {
    [self addObjects];
    uncheckedAssertEqual(unmanaged.boolObj.count, 2U);
    uncheckedAssertEqual(unmanaged.intObj.count, 2U);
    uncheckedAssertEqual(unmanaged.floatObj.count, 2U);
    uncheckedAssertEqual(unmanaged.doubleObj.count, 2U);
    uncheckedAssertEqual(unmanaged.stringObj.count, 2U);
    uncheckedAssertEqual(unmanaged.dataObj.count, 2U);
    uncheckedAssertEqual(unmanaged.dateObj.count, 2U);
    uncheckedAssertEqual(unmanaged.decimalObj.count, 2U);
    uncheckedAssertEqual(unmanaged.objectIdObj.count, 2U);
    uncheckedAssertEqual(unmanaged.uuidObj.count, 2U);
    uncheckedAssertEqual(unmanaged.anyBoolObj.count, 2U);
    uncheckedAssertEqual(unmanaged.anyIntObj.count, 2U);
    uncheckedAssertEqual(unmanaged.anyFloatObj.count, 2U);
    uncheckedAssertEqual(unmanaged.anyDoubleObj.count, 2U);
    uncheckedAssertEqual(unmanaged.anyStringObj.count, 2U);
    uncheckedAssertEqual(unmanaged.anyDataObj.count, 2U);
    uncheckedAssertEqual(unmanaged.anyDateObj.count, 2U);
    uncheckedAssertEqual(unmanaged.anyDecimalObj.count, 2U);
    uncheckedAssertEqual(unmanaged.anyObjectIdObj.count, 2U);
    uncheckedAssertEqual(unmanaged.anyUUIDObj.count, 2U);
    uncheckedAssertEqual(managed.boolObj.count, 2U);
    uncheckedAssertEqual(managed.intObj.count, 2U);
    uncheckedAssertEqual(managed.floatObj.count, 2U);
    uncheckedAssertEqual(managed.doubleObj.count, 2U);
    uncheckedAssertEqual(managed.stringObj.count, 2U);
    uncheckedAssertEqual(managed.dataObj.count, 2U);
    uncheckedAssertEqual(managed.dateObj.count, 2U);
    uncheckedAssertEqual(managed.decimalObj.count, 2U);
    uncheckedAssertEqual(managed.objectIdObj.count, 2U);
    uncheckedAssertEqual(managed.uuidObj.count, 2U);
    uncheckedAssertEqual(managed.anyBoolObj.count, 2U);
    uncheckedAssertEqual(managed.anyIntObj.count, 2U);
    uncheckedAssertEqual(managed.anyFloatObj.count, 2U);
    uncheckedAssertEqual(managed.anyDoubleObj.count, 2U);
    uncheckedAssertEqual(managed.anyStringObj.count, 2U);
    uncheckedAssertEqual(managed.anyDataObj.count, 2U);
    uncheckedAssertEqual(managed.anyDateObj.count, 2U);
    uncheckedAssertEqual(managed.anyDecimalObj.count, 2U);
    uncheckedAssertEqual(managed.anyObjectIdObj.count, 2U);
    uncheckedAssertEqual(managed.anyUUIDObj.count, 2U);
    uncheckedAssertEqual(optUnmanaged.intObj.count, 3U);
    uncheckedAssertEqual(optUnmanaged.floatObj.count, 3U);
    uncheckedAssertEqual(optUnmanaged.doubleObj.count, 3U);
    uncheckedAssertEqual(optUnmanaged.stringObj.count, 3U);
    uncheckedAssertEqual(optUnmanaged.dataObj.count, 3U);
    uncheckedAssertEqual(optUnmanaged.dateObj.count, 3U);
    uncheckedAssertEqual(optUnmanaged.decimalObj.count, 3U);
    uncheckedAssertEqual(optUnmanaged.objectIdObj.count, 3U);
    uncheckedAssertEqual(optUnmanaged.uuidObj.count, 3U);
    uncheckedAssertEqual(optManaged.boolObj.count, 3U);
    uncheckedAssertEqual(optManaged.intObj.count, 3U);
    uncheckedAssertEqual(optManaged.floatObj.count, 3U);
    uncheckedAssertEqual(optManaged.doubleObj.count, 3U);
    uncheckedAssertEqual(optManaged.stringObj.count, 3U);
    uncheckedAssertEqual(optManaged.dataObj.count, 3U);
    uncheckedAssertEqual(optManaged.dateObj.count, 3U);
    uncheckedAssertEqual(optManaged.decimalObj.count, 3U);
    uncheckedAssertEqual(optManaged.objectIdObj.count, 3U);
    uncheckedAssertEqual(optManaged.uuidObj.count, 3U);

    for (RLMSet *set in allSets) {
        [set removeObject:set.allObjects[0]];
    }
    uncheckedAssertEqual(unmanaged.boolObj.count, 1U);
    uncheckedAssertEqual(unmanaged.intObj.count, 1U);
    uncheckedAssertEqual(unmanaged.floatObj.count, 1U);
    uncheckedAssertEqual(unmanaged.doubleObj.count, 1U);
    uncheckedAssertEqual(unmanaged.stringObj.count, 1U);
    uncheckedAssertEqual(unmanaged.dataObj.count, 1U);
    uncheckedAssertEqual(unmanaged.dateObj.count, 1U);
    uncheckedAssertEqual(unmanaged.decimalObj.count, 1U);
    uncheckedAssertEqual(unmanaged.objectIdObj.count, 1U);
    uncheckedAssertEqual(unmanaged.uuidObj.count, 1U);
    uncheckedAssertEqual(unmanaged.anyBoolObj.count, 1U);
    uncheckedAssertEqual(unmanaged.anyIntObj.count, 1U);
    uncheckedAssertEqual(unmanaged.anyFloatObj.count, 1U);
    uncheckedAssertEqual(unmanaged.anyDoubleObj.count, 1U);
    uncheckedAssertEqual(unmanaged.anyStringObj.count, 1U);
    uncheckedAssertEqual(unmanaged.anyDataObj.count, 1U);
    uncheckedAssertEqual(unmanaged.anyDateObj.count, 1U);
    uncheckedAssertEqual(unmanaged.anyDecimalObj.count, 1U);
    uncheckedAssertEqual(unmanaged.anyObjectIdObj.count, 1U);
    uncheckedAssertEqual(unmanaged.anyUUIDObj.count, 1U);
    uncheckedAssertEqual(managed.boolObj.count, 1U);
    uncheckedAssertEqual(managed.intObj.count, 1U);
    uncheckedAssertEqual(managed.floatObj.count, 1U);
    uncheckedAssertEqual(managed.doubleObj.count, 1U);
    uncheckedAssertEqual(managed.stringObj.count, 1U);
    uncheckedAssertEqual(managed.dataObj.count, 1U);
    uncheckedAssertEqual(managed.dateObj.count, 1U);
    uncheckedAssertEqual(managed.decimalObj.count, 1U);
    uncheckedAssertEqual(managed.objectIdObj.count, 1U);
    uncheckedAssertEqual(managed.uuidObj.count, 1U);
    uncheckedAssertEqual(managed.anyBoolObj.count, 1U);
    uncheckedAssertEqual(managed.anyIntObj.count, 1U);
    uncheckedAssertEqual(managed.anyFloatObj.count, 1U);
    uncheckedAssertEqual(managed.anyDoubleObj.count, 1U);
    uncheckedAssertEqual(managed.anyStringObj.count, 1U);
    uncheckedAssertEqual(managed.anyDataObj.count, 1U);
    uncheckedAssertEqual(managed.anyDateObj.count, 1U);
    uncheckedAssertEqual(managed.anyDecimalObj.count, 1U);
    uncheckedAssertEqual(managed.anyObjectIdObj.count, 1U);
    uncheckedAssertEqual(managed.anyUUIDObj.count, 1U);
    uncheckedAssertEqual(optUnmanaged.intObj.count, 2U);
    uncheckedAssertEqual(optUnmanaged.floatObj.count, 2U);
    uncheckedAssertEqual(optUnmanaged.doubleObj.count, 2U);
    uncheckedAssertEqual(optUnmanaged.stringObj.count, 2U);
    uncheckedAssertEqual(optUnmanaged.dataObj.count, 2U);
    uncheckedAssertEqual(optUnmanaged.dateObj.count, 2U);
    uncheckedAssertEqual(optUnmanaged.decimalObj.count, 2U);
    uncheckedAssertEqual(optUnmanaged.objectIdObj.count, 2U);
    uncheckedAssertEqual(optUnmanaged.uuidObj.count, 2U);
    uncheckedAssertEqual(optManaged.boolObj.count, 2U);
    uncheckedAssertEqual(optManaged.intObj.count, 2U);
    uncheckedAssertEqual(optManaged.floatObj.count, 2U);
    uncheckedAssertEqual(optManaged.doubleObj.count, 2U);
    uncheckedAssertEqual(optManaged.stringObj.count, 2U);
    uncheckedAssertEqual(optManaged.dataObj.count, 2U);
    uncheckedAssertEqual(optManaged.dateObj.count, 2U);
    uncheckedAssertEqual(optManaged.decimalObj.count, 2U);
    uncheckedAssertEqual(optManaged.objectIdObj.count, 2U);
    uncheckedAssertEqual(optManaged.uuidObj.count, 2U);
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
    [managed.anyBoolObj addObjects:@[@NO, @YES, @NO, @YES]];
    [managed.anyIntObj addObjects:@[@2, @3, @2, @3]];
    [managed.anyFloatObj addObjects:@[@2.2f, @3.3f, @2.2f, @3.3f]];
    [managed.anyDoubleObj addObjects:@[@2.2, @3.3, @2.2, @3.3]];
    [managed.anyStringObj addObjects:@[@"a", @"b", @"a", @"b"]];
    [managed.anyDataObj addObjects:@[data(1), data(2), data(1), data(2)]];
    [managed.anyDateObj addObjects:@[date(1), date(2), date(1), date(2)]];
    [managed.anyDecimalObj addObjects:@[decimal128(1), decimal128(2), decimal128(1), decimal128(2)]];
    [managed.anyObjectIdObj addObjects:@[objectId(1), objectId(2), objectId(1), objectId(2)]];
    [managed.anyUUIDObj addObjects:@[uuid(@"00000000-0000-0000-0000-000000000000"), uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"), uuid(@"00000000-0000-0000-0000-000000000000"), uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")]];
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
    uncheckedAssertTrue([[managed.boolObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:@YES] == 0U || 
                        [[managed.boolObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:@YES] == 1U);
    uncheckedAssertTrue([[managed.intObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:@3] == 0U || 
                        [[managed.intObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:@3] == 1U);
    uncheckedAssertTrue([[managed.floatObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:@3.3f] == 0U || 
                        [[managed.floatObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:@3.3f] == 1U);
    uncheckedAssertTrue([[managed.doubleObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:@3.3] == 0U || 
                        [[managed.doubleObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:@3.3] == 1U);
    uncheckedAssertTrue([[managed.stringObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:@"bc"] == 0U || 
                        [[managed.stringObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:@"bc"] == 1U);
    uncheckedAssertTrue([[managed.dataObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:data(2)] == 0U || 
                        [[managed.dataObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:data(2)] == 1U);
    uncheckedAssertTrue([[managed.dateObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:date(2)] == 0U || 
                        [[managed.dateObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:date(2)] == 1U);
    uncheckedAssertTrue([[managed.decimalObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:decimal128(2)] == 0U || 
                        [[managed.decimalObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:decimal128(2)] == 1U);
    uncheckedAssertTrue([[managed.objectIdObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:objectId(2)] == 0U || 
                        [[managed.objectIdObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:objectId(2)] == 1U);
    uncheckedAssertTrue([[managed.uuidObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:uuid(@"00000000-0000-0000-0000-000000000000")] == 0U || 
                        [[managed.uuidObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:uuid(@"00000000-0000-0000-0000-000000000000")] == 1U);
    uncheckedAssertTrue([[managed.anyBoolObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:@YES] == 0U || 
                        [[managed.anyBoolObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:@YES] == 1U);
    uncheckedAssertTrue([[managed.anyIntObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:@3] == 0U || 
                        [[managed.anyIntObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:@3] == 1U);
    uncheckedAssertTrue([[managed.anyFloatObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:@3.3f] == 0U || 
                        [[managed.anyFloatObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:@3.3f] == 1U);
    uncheckedAssertTrue([[managed.anyDoubleObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:@3.3] == 0U || 
                        [[managed.anyDoubleObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:@3.3] == 1U);
    uncheckedAssertTrue([[managed.anyStringObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:@"b"] == 0U || 
                        [[managed.anyStringObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:@"b"] == 1U);
    uncheckedAssertTrue([[managed.anyDataObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:data(2)] == 0U || 
                        [[managed.anyDataObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:data(2)] == 1U);
    uncheckedAssertTrue([[managed.anyDateObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:date(2)] == 0U || 
                        [[managed.anyDateObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:date(2)] == 1U);
    uncheckedAssertTrue([[managed.anyDecimalObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:decimal128(2)] == 0U || 
                        [[managed.anyDecimalObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:decimal128(2)] == 1U);
    uncheckedAssertTrue([[managed.anyObjectIdObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:objectId(2)] == 0U || 
                        [[managed.anyObjectIdObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:objectId(2)] == 1U);
    uncheckedAssertTrue([[managed.anyUUIDObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")] == 0U || 
                        [[managed.anyUUIDObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")] == 1U);
    uncheckedAssertTrue([[managed.boolObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:@NO] == 0U || 
                        [[managed.boolObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:@NO] == 1U);
    uncheckedAssertTrue([[managed.intObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:@2] == 0U || 
                        [[managed.intObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:@2] == 1U);
    uncheckedAssertTrue([[managed.floatObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:@2.2f] == 0U || 
                        [[managed.floatObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:@2.2f] == 1U);
    uncheckedAssertTrue([[managed.doubleObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:@2.2] == 0U || 
                        [[managed.doubleObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:@2.2] == 1U);
    uncheckedAssertTrue([[managed.stringObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:@"a"] == 0U || 
                        [[managed.stringObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:@"a"] == 1U);
    uncheckedAssertTrue([[managed.dataObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:data(1)] == 0U || 
                        [[managed.dataObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:data(1)] == 1U);
    uncheckedAssertTrue([[managed.dateObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:date(1)] == 0U || 
                        [[managed.dateObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:date(1)] == 1U);
    uncheckedAssertTrue([[managed.decimalObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:decimal128(1)] == 0U || 
                        [[managed.decimalObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:decimal128(1)] == 1U);
    uncheckedAssertTrue([[managed.objectIdObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:objectId(1)] == 0U || 
                        [[managed.objectIdObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:objectId(1)] == 1U);
    uncheckedAssertTrue([[managed.uuidObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")] == 0U || 
                        [[managed.uuidObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")] == 1U);
    uncheckedAssertTrue([[managed.anyBoolObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:@NO] == 0U || 
                        [[managed.anyBoolObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:@NO] == 1U);
    uncheckedAssertTrue([[managed.anyIntObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:@2] == 0U || 
                        [[managed.anyIntObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:@2] == 1U);
    uncheckedAssertTrue([[managed.anyFloatObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:@2.2f] == 0U || 
                        [[managed.anyFloatObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:@2.2f] == 1U);
    uncheckedAssertTrue([[managed.anyDoubleObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:@2.2] == 0U || 
                        [[managed.anyDoubleObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:@2.2] == 1U);
    uncheckedAssertTrue([[managed.anyStringObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:@"a"] == 0U || 
                        [[managed.anyStringObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:@"a"] == 1U);
    uncheckedAssertTrue([[managed.anyDataObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:data(1)] == 0U || 
                        [[managed.anyDataObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:data(1)] == 1U);
    uncheckedAssertTrue([[managed.anyDateObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:date(1)] == 0U || 
                        [[managed.anyDateObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:date(1)] == 1U);
    uncheckedAssertTrue([[managed.anyDecimalObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:decimal128(1)] == 0U || 
                        [[managed.anyDecimalObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:decimal128(1)] == 1U);
    uncheckedAssertTrue([[managed.anyObjectIdObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:objectId(1)] == 0U || 
                        [[managed.anyObjectIdObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:objectId(1)] == 1U);
    uncheckedAssertTrue([[managed.anyUUIDObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:uuid(@"00000000-0000-0000-0000-000000000000")] == 0U || 
                        [[managed.anyUUIDObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:uuid(@"00000000-0000-0000-0000-000000000000")] == 1U);

    uncheckedAssertTrue([[optManaged.boolObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:@NO] == 0U || 
                        [[optManaged.boolObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:@NO] == 1U);
    uncheckedAssertTrue([[optManaged.intObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:@2] == 0U || 
                        [[optManaged.intObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:@2] == 1U);
    uncheckedAssertTrue([[optManaged.floatObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:@2.2f] == 0U || 
                        [[optManaged.floatObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:@2.2f] == 1U);
    uncheckedAssertTrue([[optManaged.doubleObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:@2.2] == 0U || 
                        [[optManaged.doubleObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:@2.2] == 1U);
    uncheckedAssertTrue([[optManaged.stringObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:@"a"] == 0U || 
                        [[optManaged.stringObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:@"a"] == 1U);
    uncheckedAssertTrue([[optManaged.dataObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:data(1)] == 0U || 
                        [[optManaged.dataObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:data(1)] == 1U);
    uncheckedAssertTrue([[optManaged.dateObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:date(1)] == 0U || 
                        [[optManaged.dateObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:date(1)] == 1U);
    uncheckedAssertTrue([[optManaged.decimalObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:decimal128(1)] == 0U || 
                        [[optManaged.decimalObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:decimal128(1)] == 1U);
    uncheckedAssertTrue([[optManaged.objectIdObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:objectId(1)] == 0U || 
                        [[optManaged.objectIdObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:objectId(1)] == 1U);
    uncheckedAssertTrue([[optManaged.uuidObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")] == 0U || 
                        [[optManaged.uuidObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")] == 1U);
    uncheckedAssertTrue([[optManaged.boolObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:NSNull.null] == 0U || 
                        [[optManaged.boolObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:NSNull.null] == 1U);
    uncheckedAssertTrue([[optManaged.intObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:NSNull.null] == 0U || 
                        [[optManaged.intObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:NSNull.null] == 1U);
    uncheckedAssertTrue([[optManaged.floatObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:NSNull.null] == 0U || 
                        [[optManaged.floatObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:NSNull.null] == 1U);
    uncheckedAssertTrue([[optManaged.doubleObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:NSNull.null] == 0U || 
                        [[optManaged.doubleObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:NSNull.null] == 1U);
    uncheckedAssertTrue([[optManaged.stringObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:NSNull.null] == 0U || 
                        [[optManaged.stringObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:NSNull.null] == 1U);
    uncheckedAssertTrue([[optManaged.dataObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:NSNull.null] == 0U || 
                        [[optManaged.dataObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:NSNull.null] == 1U);
    uncheckedAssertTrue([[optManaged.dateObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:NSNull.null] == 0U || 
                        [[optManaged.dateObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:NSNull.null] == 1U);
    uncheckedAssertTrue([[optManaged.decimalObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:NSNull.null] == 0U || 
                        [[optManaged.decimalObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:NSNull.null] == 1U);
    uncheckedAssertTrue([[optManaged.objectIdObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:NSNull.null] == 0U || 
                        [[optManaged.objectIdObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:NSNull.null] == 1U);
    uncheckedAssertTrue([[optManaged.uuidObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:NSNull.null] == 0U || 
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
    [managed.anyBoolObj addObjects:@[@NO, @NO, @YES]];
    [managed.anyIntObj addObjects:@[@2, @2, @3]];
    [managed.anyFloatObj addObjects:@[@2.2f, @2.2f, @3.3f]];
    [managed.anyDoubleObj addObjects:@[@2.2, @2.2, @3.3]];
    [managed.anyStringObj addObjects:@[@"a", @"a", @"b"]];
    [managed.anyDataObj addObjects:@[data(1), data(1), data(2)]];
    [managed.anyDateObj addObjects:@[date(1), date(1), date(2)]];
    [managed.anyDecimalObj addObjects:@[decimal128(1), decimal128(1), decimal128(2)]];
    [managed.anyObjectIdObj addObjects:@[objectId(1), objectId(1), objectId(2)]];
    [managed.anyUUIDObj addObjects:@[uuid(@"00000000-0000-0000-0000-000000000000"), uuid(@"00000000-0000-0000-0000-000000000000"), uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")]];
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
    uncheckedAssertTrue([[managed.boolObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:@NO] == 0U || 
                        [[managed.boolObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:@NO] == 1U);
    uncheckedAssertTrue([[managed.intObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:@2] == 0U || 
                        [[managed.intObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:@2] == 1U);
    uncheckedAssertTrue([[managed.floatObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:@2.2f] == 0U || 
                        [[managed.floatObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:@2.2f] == 1U);
    uncheckedAssertTrue([[managed.doubleObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:@2.2] == 0U || 
                        [[managed.doubleObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:@2.2] == 1U);
    uncheckedAssertTrue([[managed.stringObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:@"a"] == 0U || 
                        [[managed.stringObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:@"a"] == 1U);
    uncheckedAssertTrue([[managed.dataObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:data(1)] == 0U || 
                        [[managed.dataObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:data(1)] == 1U);
    uncheckedAssertTrue([[managed.dateObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:date(1)] == 0U || 
                        [[managed.dateObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:date(1)] == 1U);
    uncheckedAssertTrue([[managed.decimalObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:decimal128(1)] == 0U || 
                        [[managed.decimalObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:decimal128(1)] == 1U);
    uncheckedAssertTrue([[managed.objectIdObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:objectId(1)] == 0U || 
                        [[managed.objectIdObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:objectId(1)] == 1U);
    uncheckedAssertTrue([[managed.uuidObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")] == 0U || 
                        [[managed.uuidObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")] == 1U);
    uncheckedAssertTrue([[managed.anyBoolObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:@NO] == 0U || 
                        [[managed.anyBoolObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:@NO] == 1U);
    uncheckedAssertTrue([[managed.anyIntObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:@2] == 0U || 
                        [[managed.anyIntObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:@2] == 1U);
    uncheckedAssertTrue([[managed.anyFloatObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:@2.2f] == 0U || 
                        [[managed.anyFloatObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:@2.2f] == 1U);
    uncheckedAssertTrue([[managed.anyDoubleObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:@2.2] == 0U || 
                        [[managed.anyDoubleObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:@2.2] == 1U);
    uncheckedAssertTrue([[managed.anyStringObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:@"a"] == 0U || 
                        [[managed.anyStringObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:@"a"] == 1U);
    uncheckedAssertTrue([[managed.anyDataObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:data(1)] == 0U || 
                        [[managed.anyDataObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:data(1)] == 1U);
    uncheckedAssertTrue([[managed.anyDateObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:date(1)] == 0U || 
                        [[managed.anyDateObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:date(1)] == 1U);
    uncheckedAssertTrue([[managed.anyDecimalObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:decimal128(1)] == 0U || 
                        [[managed.anyDecimalObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:decimal128(1)] == 1U);
    uncheckedAssertTrue([[managed.anyObjectIdObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:objectId(1)] == 0U || 
                        [[managed.anyObjectIdObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:objectId(1)] == 1U);
    uncheckedAssertTrue([[managed.anyUUIDObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:uuid(@"00000000-0000-0000-0000-000000000000")] == 0U || 
                        [[managed.anyUUIDObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:uuid(@"00000000-0000-0000-0000-000000000000")] == 1U);
    uncheckedAssertTrue([[managed.boolObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:@YES] == 0U || 
                        [[managed.boolObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:@YES] == 1U);
    uncheckedAssertTrue([[managed.intObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:@3] == 0U || 
                        [[managed.intObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:@3] == 1U);
    uncheckedAssertTrue([[managed.floatObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:@3.3f] == 0U || 
                        [[managed.floatObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:@3.3f] == 1U);
    uncheckedAssertTrue([[managed.doubleObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:@3.3] == 0U || 
                        [[managed.doubleObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:@3.3] == 1U);
    uncheckedAssertTrue([[managed.stringObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:@"bc"] == 0U || 
                        [[managed.stringObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:@"bc"] == 1U);
    uncheckedAssertTrue([[managed.dataObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:data(2)] == 0U || 
                        [[managed.dataObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:data(2)] == 1U);
    uncheckedAssertTrue([[managed.dateObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:date(2)] == 0U || 
                        [[managed.dateObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:date(2)] == 1U);
    uncheckedAssertTrue([[managed.decimalObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:decimal128(2)] == 0U || 
                        [[managed.decimalObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:decimal128(2)] == 1U);
    uncheckedAssertTrue([[managed.objectIdObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:objectId(2)] == 0U || 
                        [[managed.objectIdObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:objectId(2)] == 1U);
    uncheckedAssertTrue([[managed.uuidObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:uuid(@"00000000-0000-0000-0000-000000000000")] == 0U || 
                        [[managed.uuidObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:uuid(@"00000000-0000-0000-0000-000000000000")] == 1U);
    uncheckedAssertTrue([[managed.anyBoolObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:@YES] == 0U || 
                        [[managed.anyBoolObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:@YES] == 1U);
    uncheckedAssertTrue([[managed.anyIntObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:@3] == 0U || 
                        [[managed.anyIntObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:@3] == 1U);
    uncheckedAssertTrue([[managed.anyFloatObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:@3.3f] == 0U || 
                        [[managed.anyFloatObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:@3.3f] == 1U);
    uncheckedAssertTrue([[managed.anyDoubleObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:@3.3] == 0U || 
                        [[managed.anyDoubleObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:@3.3] == 1U);
    uncheckedAssertTrue([[managed.anyStringObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:@"b"] == 0U || 
                        [[managed.anyStringObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:@"b"] == 1U);
    uncheckedAssertTrue([[managed.anyDataObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:data(2)] == 0U || 
                        [[managed.anyDataObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:data(2)] == 1U);
    uncheckedAssertTrue([[managed.anyDateObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:date(2)] == 0U || 
                        [[managed.anyDateObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:date(2)] == 1U);
    uncheckedAssertTrue([[managed.anyDecimalObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:decimal128(2)] == 0U || 
                        [[managed.anyDecimalObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:decimal128(2)] == 1U);
    uncheckedAssertTrue([[managed.anyObjectIdObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:objectId(2)] == 0U || 
                        [[managed.anyObjectIdObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:objectId(2)] == 1U);
    uncheckedAssertTrue([[managed.anyUUIDObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")] == 0U || 
                        [[managed.anyUUIDObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")] == 1U);

    uncheckedAssertTrue([[optManaged.boolObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:NSNull.null] == 0U || 
                        [[optManaged.boolObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:NSNull.null] == 1U);
    uncheckedAssertTrue([[optManaged.intObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:NSNull.null] == 0U || 
                        [[optManaged.intObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:NSNull.null] == 1U);
    uncheckedAssertTrue([[optManaged.floatObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:NSNull.null] == 0U || 
                        [[optManaged.floatObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:NSNull.null] == 1U);
    uncheckedAssertTrue([[optManaged.doubleObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:NSNull.null] == 0U || 
                        [[optManaged.doubleObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:NSNull.null] == 1U);
    uncheckedAssertTrue([[optManaged.stringObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:NSNull.null] == 0U || 
                        [[optManaged.stringObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:NSNull.null] == 1U);
    uncheckedAssertTrue([[optManaged.dataObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:NSNull.null] == 0U || 
                        [[optManaged.dataObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:NSNull.null] == 1U);
    uncheckedAssertTrue([[optManaged.dateObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:NSNull.null] == 0U || 
                        [[optManaged.dateObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:NSNull.null] == 1U);
    uncheckedAssertTrue([[optManaged.decimalObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:NSNull.null] == 0U || 
                        [[optManaged.decimalObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:NSNull.null] == 1U);
    uncheckedAssertTrue([[optManaged.objectIdObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:NSNull.null] == 0U || 
                        [[optManaged.objectIdObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:NSNull.null] == 1U);
    uncheckedAssertTrue([[optManaged.uuidObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:NSNull.null] == 0U || 
                        [[optManaged.uuidObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:NSNull.null] == 1U);
    uncheckedAssertTrue([[optManaged.boolObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:@NO] == 0U || 
                        [[optManaged.boolObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:@NO] == 1U);
    uncheckedAssertTrue([[optManaged.intObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:@2] == 0U || 
                        [[optManaged.intObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:@2] == 1U);
    uncheckedAssertTrue([[optManaged.floatObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:@2.2f] == 0U || 
                        [[optManaged.floatObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:@2.2f] == 1U);
    uncheckedAssertTrue([[optManaged.doubleObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:@2.2] == 0U || 
                        [[optManaged.doubleObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:@2.2] == 1U);
    uncheckedAssertTrue([[optManaged.stringObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:@"a"] == 0U || 
                        [[optManaged.stringObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:@"a"] == 1U);
    uncheckedAssertTrue([[optManaged.dataObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:data(1)] == 0U || 
                        [[optManaged.dataObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:data(1)] == 1U);
    uncheckedAssertTrue([[optManaged.dateObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:date(1)] == 0U || 
                        [[optManaged.dateObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:date(1)] == 1U);
    uncheckedAssertTrue([[optManaged.decimalObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:decimal128(1)] == 0U || 
                        [[optManaged.decimalObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:decimal128(1)] == 1U);
    uncheckedAssertTrue([[optManaged.objectIdObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:objectId(1)] == 0U || 
                        [[optManaged.objectIdObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:objectId(1)] == 1U);
    uncheckedAssertTrue([[optManaged.uuidObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")] == 0U || 
                        [[optManaged.uuidObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")] == 1U);
    uncheckedAssertTrue([[optManaged.boolObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:NSNull.null] == 0U || 
                        [[optManaged.boolObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:NSNull.null] == 1U);
    uncheckedAssertTrue([[optManaged.intObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:NSNull.null] == 0U || 
                        [[optManaged.intObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:NSNull.null] == 1U);
    uncheckedAssertTrue([[optManaged.floatObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:NSNull.null] == 0U || 
                        [[optManaged.floatObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:NSNull.null] == 1U);
    uncheckedAssertTrue([[optManaged.doubleObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:NSNull.null] == 0U || 
                        [[optManaged.doubleObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:NSNull.null] == 1U);
    uncheckedAssertTrue([[optManaged.stringObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:NSNull.null] == 0U || 
                        [[optManaged.stringObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:NSNull.null] == 1U);
    uncheckedAssertTrue([[optManaged.dataObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:NSNull.null] == 0U || 
                        [[optManaged.dataObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:NSNull.null] == 1U);
    uncheckedAssertTrue([[optManaged.dateObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:NSNull.null] == 0U || 
                        [[optManaged.dateObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:NSNull.null] == 1U);
    uncheckedAssertTrue([[optManaged.decimalObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:NSNull.null] == 0U || 
                        [[optManaged.decimalObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:NSNull.null] == 1U);
    uncheckedAssertTrue([[optManaged.objectIdObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:NSNull.null] == 0U || 
                        [[optManaged.objectIdObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:NSNull.null] == 1U);
    uncheckedAssertTrue([[optManaged.uuidObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:NSNull.null] == 0U || 
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
    RLMAssertThrowsWithReason([unmanaged.anyBoolObj sortedResultsUsingKeyPath:@"self" ascending:NO], 
                              @"This method may only be called on RLMSet instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.anyIntObj sortedResultsUsingKeyPath:@"self" ascending:NO], 
                              @"This method may only be called on RLMSet instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.anyFloatObj sortedResultsUsingKeyPath:@"self" ascending:NO], 
                              @"This method may only be called on RLMSet instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.anyDoubleObj sortedResultsUsingKeyPath:@"self" ascending:NO], 
                              @"This method may only be called on RLMSet instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.anyStringObj sortedResultsUsingKeyPath:@"self" ascending:NO], 
                              @"This method may only be called on RLMSet instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.anyDataObj sortedResultsUsingKeyPath:@"self" ascending:NO], 
                              @"This method may only be called on RLMSet instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.anyDateObj sortedResultsUsingKeyPath:@"self" ascending:NO], 
                              @"This method may only be called on RLMSet instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.anyDecimalObj sortedResultsUsingKeyPath:@"self" ascending:NO], 
                              @"This method may only be called on RLMSet instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.anyObjectIdObj sortedResultsUsingKeyPath:@"self" ascending:NO], 
                              @"This method may only be called on RLMSet instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.anyUUIDObj sortedResultsUsingKeyPath:@"self" ascending:NO], 
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
    RLMAssertThrowsWithReason([unmanaged.anyBoolObj sortedResultsUsingDescriptors:@[]], 
                              @"This method may only be called on RLMSet instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.anyIntObj sortedResultsUsingDescriptors:@[]], 
                              @"This method may only be called on RLMSet instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.anyFloatObj sortedResultsUsingDescriptors:@[]], 
                              @"This method may only be called on RLMSet instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.anyDoubleObj sortedResultsUsingDescriptors:@[]], 
                              @"This method may only be called on RLMSet instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.anyStringObj sortedResultsUsingDescriptors:@[]], 
                              @"This method may only be called on RLMSet instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.anyDataObj sortedResultsUsingDescriptors:@[]], 
                              @"This method may only be called on RLMSet instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.anyDateObj sortedResultsUsingDescriptors:@[]], 
                              @"This method may only be called on RLMSet instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.anyDecimalObj sortedResultsUsingDescriptors:@[]], 
                              @"This method may only be called on RLMSet instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.anyObjectIdObj sortedResultsUsingDescriptors:@[]], 
                              @"This method may only be called on RLMSet instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.anyUUIDObj sortedResultsUsingDescriptors:@[]], 
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
    [managed.stringObj addObjects:@[@"a", @"bc", @"a"]];
    [managed.dataObj addObjects:@[data(1), data(2), data(1)]];
    [managed.dateObj addObjects:@[date(1), date(2), date(1)]];
    [managed.decimalObj addObjects:@[decimal128(1), decimal128(2), decimal128(1)]];
    [managed.objectIdObj addObjects:@[objectId(1), objectId(2), objectId(1)]];
    [managed.uuidObj addObjects:@[uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"), uuid(@"00000000-0000-0000-0000-000000000000"), uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")]];
    [managed.anyBoolObj addObjects:@[@NO, @YES, @NO]];
    [managed.anyIntObj addObjects:@[@2, @3, @2]];
    [managed.anyFloatObj addObjects:@[@2.2f, @3.3f, @2.2f]];
    [managed.anyDoubleObj addObjects:@[@2.2, @3.3, @2.2]];
    [managed.anyStringObj addObjects:@[@"a", @"b", @"a"]];
    [managed.anyDataObj addObjects:@[data(1), data(2), data(1)]];
    [managed.anyDateObj addObjects:@[date(1), date(2), date(1)]];
    [managed.anyDecimalObj addObjects:@[decimal128(1), decimal128(2), decimal128(1)]];
    [managed.anyObjectIdObj addObjects:@[objectId(1), objectId(2), objectId(1)]];
    [managed.anyUUIDObj addObjects:@[uuid(@"00000000-0000-0000-0000-000000000000"), uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"), uuid(@"00000000-0000-0000-0000-000000000000")]];
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

    uncheckedAssertEqualObjects([NSSet setWithArray:[[[managed.boolObj sortedResultsUsingDescriptors:@[]] valueForKey:@"self"] allObjects]], 
                                ([NSSet setWithArray:@[@NO, @YES]]));
    uncheckedAssertEqualObjects([NSSet setWithArray:[[[managed.intObj sortedResultsUsingDescriptors:@[]] valueForKey:@"self"] allObjects]], 
                                ([NSSet setWithArray:@[@2, @3]]));
    uncheckedAssertEqualObjects([NSSet setWithArray:[[[managed.floatObj sortedResultsUsingDescriptors:@[]] valueForKey:@"self"] allObjects]], 
                                ([NSSet setWithArray:@[@2.2f, @3.3f]]));
    uncheckedAssertEqualObjects([NSSet setWithArray:[[[managed.doubleObj sortedResultsUsingDescriptors:@[]] valueForKey:@"self"] allObjects]], 
                                ([NSSet setWithArray:@[@2.2, @3.3]]));
    uncheckedAssertEqualObjects([NSSet setWithArray:[[[managed.stringObj sortedResultsUsingDescriptors:@[]] valueForKey:@"self"] allObjects]], 
                                ([NSSet setWithArray:@[@"a", @"bc"]]));
    uncheckedAssertEqualObjects([NSSet setWithArray:[[[managed.dataObj sortedResultsUsingDescriptors:@[]] valueForKey:@"self"] allObjects]], 
                                ([NSSet setWithArray:@[data(1), data(2)]]));
    uncheckedAssertEqualObjects([NSSet setWithArray:[[[managed.dateObj sortedResultsUsingDescriptors:@[]] valueForKey:@"self"] allObjects]], 
                                ([NSSet setWithArray:@[date(1), date(2)]]));
    uncheckedAssertEqualObjects([NSSet setWithArray:[[[managed.decimalObj sortedResultsUsingDescriptors:@[]] valueForKey:@"self"] allObjects]], 
                                ([NSSet setWithArray:@[decimal128(1), decimal128(2)]]));
    uncheckedAssertEqualObjects([NSSet setWithArray:[[[managed.objectIdObj sortedResultsUsingDescriptors:@[]] valueForKey:@"self"] allObjects]], 
                                ([NSSet setWithArray:@[objectId(1), objectId(2)]]));
    uncheckedAssertEqualObjects([NSSet setWithArray:[[[managed.uuidObj sortedResultsUsingDescriptors:@[]] valueForKey:@"self"] allObjects]], 
                                ([NSSet setWithArray:@[uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"), uuid(@"00000000-0000-0000-0000-000000000000")]]));
    uncheckedAssertEqualObjects([NSSet setWithArray:[[[managed.anyBoolObj sortedResultsUsingDescriptors:@[]] valueForKey:@"self"] allObjects]], 
                                ([NSSet setWithArray:@[@NO, @YES]]));
    uncheckedAssertEqualObjects([NSSet setWithArray:[[[managed.anyIntObj sortedResultsUsingDescriptors:@[]] valueForKey:@"self"] allObjects]], 
                                ([NSSet setWithArray:@[@2, @3]]));
    uncheckedAssertEqualObjects([NSSet setWithArray:[[[managed.anyFloatObj sortedResultsUsingDescriptors:@[]] valueForKey:@"self"] allObjects]], 
                                ([NSSet setWithArray:@[@2.2f, @3.3f]]));
    uncheckedAssertEqualObjects([NSSet setWithArray:[[[managed.anyDoubleObj sortedResultsUsingDescriptors:@[]] valueForKey:@"self"] allObjects]], 
                                ([NSSet setWithArray:@[@2.2, @3.3]]));
    uncheckedAssertEqualObjects([NSSet setWithArray:[[[managed.anyStringObj sortedResultsUsingDescriptors:@[]] valueForKey:@"self"] allObjects]], 
                                ([NSSet setWithArray:@[@"a", @"b"]]));
    uncheckedAssertEqualObjects([NSSet setWithArray:[[[managed.anyDataObj sortedResultsUsingDescriptors:@[]] valueForKey:@"self"] allObjects]], 
                                ([NSSet setWithArray:@[data(1), data(2)]]));
    uncheckedAssertEqualObjects([NSSet setWithArray:[[[managed.anyDateObj sortedResultsUsingDescriptors:@[]] valueForKey:@"self"] allObjects]], 
                                ([NSSet setWithArray:@[date(1), date(2)]]));
    uncheckedAssertEqualObjects([NSSet setWithArray:[[[managed.anyDecimalObj sortedResultsUsingDescriptors:@[]] valueForKey:@"self"] allObjects]], 
                                ([NSSet setWithArray:@[decimal128(1), decimal128(2)]]));
    uncheckedAssertEqualObjects([NSSet setWithArray:[[[managed.anyObjectIdObj sortedResultsUsingDescriptors:@[]] valueForKey:@"self"] allObjects]], 
                                ([NSSet setWithArray:@[objectId(1), objectId(2)]]));
    uncheckedAssertEqualObjects([NSSet setWithArray:[[[managed.anyUUIDObj sortedResultsUsingDescriptors:@[]] valueForKey:@"self"] allObjects]], 
                                ([NSSet setWithArray:@[uuid(@"00000000-0000-0000-0000-000000000000"), uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")]]));
    uncheckedAssertEqualObjects([NSSet setWithArray:[[[optManaged.boolObj sortedResultsUsingDescriptors:@[]] valueForKey:@"self"] allObjects]], 
                                ([NSSet setWithArray:@[NSNull.null, @NO]]));
    uncheckedAssertEqualObjects([NSSet setWithArray:[[[optManaged.intObj sortedResultsUsingDescriptors:@[]] valueForKey:@"self"] allObjects]], 
                                ([NSSet setWithArray:@[NSNull.null, @2]]));
    uncheckedAssertEqualObjects([NSSet setWithArray:[[[optManaged.floatObj sortedResultsUsingDescriptors:@[]] valueForKey:@"self"] allObjects]], 
                                ([NSSet setWithArray:@[NSNull.null, @2.2f]]));
    uncheckedAssertEqualObjects([NSSet setWithArray:[[[optManaged.doubleObj sortedResultsUsingDescriptors:@[]] valueForKey:@"self"] allObjects]], 
                                ([NSSet setWithArray:@[NSNull.null, @2.2]]));
    uncheckedAssertEqualObjects([NSSet setWithArray:[[[optManaged.stringObj sortedResultsUsingDescriptors:@[]] valueForKey:@"self"] allObjects]], 
                                ([NSSet setWithArray:@[NSNull.null, @"a"]]));
    uncheckedAssertEqualObjects([NSSet setWithArray:[[[optManaged.dataObj sortedResultsUsingDescriptors:@[]] valueForKey:@"self"] allObjects]], 
                                ([NSSet setWithArray:@[NSNull.null, data(1)]]));
    uncheckedAssertEqualObjects([NSSet setWithArray:[[[optManaged.dateObj sortedResultsUsingDescriptors:@[]] valueForKey:@"self"] allObjects]], 
                                ([NSSet setWithArray:@[NSNull.null, date(1)]]));
    uncheckedAssertEqualObjects([NSSet setWithArray:[[[optManaged.decimalObj sortedResultsUsingDescriptors:@[]] valueForKey:@"self"] allObjects]], 
                                ([NSSet setWithArray:@[NSNull.null, decimal128(1)]]));
    uncheckedAssertEqualObjects([NSSet setWithArray:[[[optManaged.objectIdObj sortedResultsUsingDescriptors:@[]] valueForKey:@"self"] allObjects]], 
                                ([NSSet setWithArray:@[NSNull.null, objectId(1)]]));
    uncheckedAssertEqualObjects([NSSet setWithArray:[[[optManaged.uuidObj sortedResultsUsingDescriptors:@[]] valueForKey:@"self"] allObjects]], 
                                ([NSSet setWithArray:@[NSNull.null, uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")]]));

    uncheckedAssertEqualObjects([NSSet setWithArray:[[[managed.boolObj sortedResultsUsingKeyPath:@"self" ascending:NO] valueForKey:@"self"] allObjects]], 
                                ([NSSet setWithArray:@[@YES, @NO]]));
    uncheckedAssertEqualObjects([NSSet setWithArray:[[[managed.intObj sortedResultsUsingKeyPath:@"self" ascending:NO] valueForKey:@"self"] allObjects]], 
                                ([NSSet setWithArray:@[@3, @2]]));
    uncheckedAssertEqualObjects([NSSet setWithArray:[[[managed.floatObj sortedResultsUsingKeyPath:@"self" ascending:NO] valueForKey:@"self"] allObjects]], 
                                ([NSSet setWithArray:@[@3.3f, @2.2f]]));
    uncheckedAssertEqualObjects([NSSet setWithArray:[[[managed.doubleObj sortedResultsUsingKeyPath:@"self" ascending:NO] valueForKey:@"self"] allObjects]], 
                                ([NSSet setWithArray:@[@3.3, @2.2]]));
    uncheckedAssertEqualObjects([NSSet setWithArray:[[[managed.stringObj sortedResultsUsingKeyPath:@"self" ascending:NO] valueForKey:@"self"] allObjects]], 
                                ([NSSet setWithArray:@[@"bc", @"a"]]));
    uncheckedAssertEqualObjects([NSSet setWithArray:[[[managed.dataObj sortedResultsUsingKeyPath:@"self" ascending:NO] valueForKey:@"self"] allObjects]], 
                                ([NSSet setWithArray:@[data(2), data(1)]]));
    uncheckedAssertEqualObjects([NSSet setWithArray:[[[managed.dateObj sortedResultsUsingKeyPath:@"self" ascending:NO] valueForKey:@"self"] allObjects]], 
                                ([NSSet setWithArray:@[date(2), date(1)]]));
    uncheckedAssertEqualObjects([NSSet setWithArray:[[[managed.decimalObj sortedResultsUsingKeyPath:@"self" ascending:NO] valueForKey:@"self"] allObjects]], 
                                ([NSSet setWithArray:@[decimal128(2), decimal128(1)]]));
    uncheckedAssertEqualObjects([NSSet setWithArray:[[[managed.objectIdObj sortedResultsUsingKeyPath:@"self" ascending:NO] valueForKey:@"self"] allObjects]], 
                                ([NSSet setWithArray:@[objectId(2), objectId(1)]]));
    uncheckedAssertEqualObjects([NSSet setWithArray:[[[managed.uuidObj sortedResultsUsingKeyPath:@"self" ascending:NO] valueForKey:@"self"] allObjects]], 
                                ([NSSet setWithArray:@[uuid(@"00000000-0000-0000-0000-000000000000"), uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")]]));
    uncheckedAssertEqualObjects([NSSet setWithArray:[[[managed.anyBoolObj sortedResultsUsingKeyPath:@"self" ascending:NO] valueForKey:@"self"] allObjects]], 
                                ([NSSet setWithArray:@[@YES, @NO]]));
    uncheckedAssertEqualObjects([NSSet setWithArray:[[[managed.anyIntObj sortedResultsUsingKeyPath:@"self" ascending:NO] valueForKey:@"self"] allObjects]], 
                                ([NSSet setWithArray:@[@3, @2]]));
    uncheckedAssertEqualObjects([NSSet setWithArray:[[[managed.anyFloatObj sortedResultsUsingKeyPath:@"self" ascending:NO] valueForKey:@"self"] allObjects]], 
                                ([NSSet setWithArray:@[@3.3f, @2.2f]]));
    uncheckedAssertEqualObjects([NSSet setWithArray:[[[managed.anyDoubleObj sortedResultsUsingKeyPath:@"self" ascending:NO] valueForKey:@"self"] allObjects]], 
                                ([NSSet setWithArray:@[@3.3, @2.2]]));
    uncheckedAssertEqualObjects([NSSet setWithArray:[[[managed.anyStringObj sortedResultsUsingKeyPath:@"self" ascending:NO] valueForKey:@"self"] allObjects]], 
                                ([NSSet setWithArray:@[@"b", @"a"]]));
    uncheckedAssertEqualObjects([NSSet setWithArray:[[[managed.anyDataObj sortedResultsUsingKeyPath:@"self" ascending:NO] valueForKey:@"self"] allObjects]], 
                                ([NSSet setWithArray:@[data(2), data(1)]]));
    uncheckedAssertEqualObjects([NSSet setWithArray:[[[managed.anyDateObj sortedResultsUsingKeyPath:@"self" ascending:NO] valueForKey:@"self"] allObjects]], 
                                ([NSSet setWithArray:@[date(2), date(1)]]));
    uncheckedAssertEqualObjects([NSSet setWithArray:[[[managed.anyDecimalObj sortedResultsUsingKeyPath:@"self" ascending:NO] valueForKey:@"self"] allObjects]], 
                                ([NSSet setWithArray:@[decimal128(2), decimal128(1)]]));
    uncheckedAssertEqualObjects([NSSet setWithArray:[[[managed.anyObjectIdObj sortedResultsUsingKeyPath:@"self" ascending:NO] valueForKey:@"self"] allObjects]], 
                                ([NSSet setWithArray:@[objectId(2), objectId(1)]]));
    uncheckedAssertEqualObjects([NSSet setWithArray:[[[managed.anyUUIDObj sortedResultsUsingKeyPath:@"self" ascending:NO] valueForKey:@"self"] allObjects]], 
                                ([NSSet setWithArray:@[uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"), uuid(@"00000000-0000-0000-0000-000000000000")]]));
    uncheckedAssertEqualObjects([NSSet setWithArray:[[[optManaged.boolObj sortedResultsUsingKeyPath:@"self" ascending:NO] valueForKey:@"self"] allObjects]], 
                                ([NSSet setWithArray:@[@NO, NSNull.null]]));
    uncheckedAssertEqualObjects([NSSet setWithArray:[[[optManaged.intObj sortedResultsUsingKeyPath:@"self" ascending:NO] valueForKey:@"self"] allObjects]], 
                                ([NSSet setWithArray:@[@2, NSNull.null]]));
    uncheckedAssertEqualObjects([NSSet setWithArray:[[[optManaged.floatObj sortedResultsUsingKeyPath:@"self" ascending:NO] valueForKey:@"self"] allObjects]], 
                                ([NSSet setWithArray:@[@2.2f, NSNull.null]]));
    uncheckedAssertEqualObjects([NSSet setWithArray:[[[optManaged.doubleObj sortedResultsUsingKeyPath:@"self" ascending:NO] valueForKey:@"self"] allObjects]], 
                                ([NSSet setWithArray:@[@2.2, NSNull.null]]));
    uncheckedAssertEqualObjects([NSSet setWithArray:[[[optManaged.stringObj sortedResultsUsingKeyPath:@"self" ascending:NO] valueForKey:@"self"] allObjects]], 
                                ([NSSet setWithArray:@[@"a", NSNull.null]]));
    uncheckedAssertEqualObjects([NSSet setWithArray:[[[optManaged.dataObj sortedResultsUsingKeyPath:@"self" ascending:NO] valueForKey:@"self"] allObjects]], 
                                ([NSSet setWithArray:@[data(1), NSNull.null]]));
    uncheckedAssertEqualObjects([NSSet setWithArray:[[[optManaged.dateObj sortedResultsUsingKeyPath:@"self" ascending:NO] valueForKey:@"self"] allObjects]], 
                                ([NSSet setWithArray:@[date(1), NSNull.null]]));
    uncheckedAssertEqualObjects([NSSet setWithArray:[[[optManaged.decimalObj sortedResultsUsingKeyPath:@"self" ascending:NO] valueForKey:@"self"] allObjects]], 
                                ([NSSet setWithArray:@[decimal128(1), NSNull.null]]));
    uncheckedAssertEqualObjects([NSSet setWithArray:[[[optManaged.objectIdObj sortedResultsUsingKeyPath:@"self" ascending:NO] valueForKey:@"self"] allObjects]], 
                                ([NSSet setWithArray:@[objectId(1), NSNull.null]]));
    uncheckedAssertEqualObjects([NSSet setWithArray:[[[optManaged.uuidObj sortedResultsUsingKeyPath:@"self" ascending:NO] valueForKey:@"self"] allObjects]], 
                                ([NSSet setWithArray:@[uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"), NSNull.null]]));

    uncheckedAssertEqualObjects([NSSet setWithArray:[[[managed.boolObj sortedResultsUsingKeyPath:@"self" ascending:YES] valueForKey:@"self"] allObjects]], 
                                ([NSSet setWithArray:@[@NO, @YES]]));
    uncheckedAssertEqualObjects([NSSet setWithArray:[[[managed.intObj sortedResultsUsingKeyPath:@"self" ascending:YES] valueForKey:@"self"] allObjects]], 
                                ([NSSet setWithArray:@[@2, @3]]));
    uncheckedAssertEqualObjects([NSSet setWithArray:[[[managed.floatObj sortedResultsUsingKeyPath:@"self" ascending:YES] valueForKey:@"self"] allObjects]], 
                                ([NSSet setWithArray:@[@2.2f, @3.3f]]));
    uncheckedAssertEqualObjects([NSSet setWithArray:[[[managed.doubleObj sortedResultsUsingKeyPath:@"self" ascending:YES] valueForKey:@"self"] allObjects]], 
                                ([NSSet setWithArray:@[@2.2, @3.3]]));
    uncheckedAssertEqualObjects([NSSet setWithArray:[[[managed.stringObj sortedResultsUsingKeyPath:@"self" ascending:YES] valueForKey:@"self"] allObjects]], 
                                ([NSSet setWithArray:@[@"a", @"bc"]]));
    uncheckedAssertEqualObjects([NSSet setWithArray:[[[managed.dataObj sortedResultsUsingKeyPath:@"self" ascending:YES] valueForKey:@"self"] allObjects]], 
                                ([NSSet setWithArray:@[data(1), data(2)]]));
    uncheckedAssertEqualObjects([NSSet setWithArray:[[[managed.dateObj sortedResultsUsingKeyPath:@"self" ascending:YES] valueForKey:@"self"] allObjects]], 
                                ([NSSet setWithArray:@[date(1), date(2)]]));
    uncheckedAssertEqualObjects([NSSet setWithArray:[[[managed.decimalObj sortedResultsUsingKeyPath:@"self" ascending:YES] valueForKey:@"self"] allObjects]], 
                                ([NSSet setWithArray:@[decimal128(1), decimal128(2)]]));
    uncheckedAssertEqualObjects([NSSet setWithArray:[[[managed.objectIdObj sortedResultsUsingKeyPath:@"self" ascending:YES] valueForKey:@"self"] allObjects]], 
                                ([NSSet setWithArray:@[objectId(1), objectId(2)]]));
    uncheckedAssertEqualObjects([NSSet setWithArray:[[[managed.uuidObj sortedResultsUsingKeyPath:@"self" ascending:YES] valueForKey:@"self"] allObjects]], 
                                ([NSSet setWithArray:@[uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"), uuid(@"00000000-0000-0000-0000-000000000000")]]));
    uncheckedAssertEqualObjects([NSSet setWithArray:[[[managed.anyBoolObj sortedResultsUsingKeyPath:@"self" ascending:YES] valueForKey:@"self"] allObjects]], 
                                ([NSSet setWithArray:@[@NO, @YES]]));
    uncheckedAssertEqualObjects([NSSet setWithArray:[[[managed.anyIntObj sortedResultsUsingKeyPath:@"self" ascending:YES] valueForKey:@"self"] allObjects]], 
                                ([NSSet setWithArray:@[@2, @3]]));
    uncheckedAssertEqualObjects([NSSet setWithArray:[[[managed.anyFloatObj sortedResultsUsingKeyPath:@"self" ascending:YES] valueForKey:@"self"] allObjects]], 
                                ([NSSet setWithArray:@[@2.2f, @3.3f]]));
    uncheckedAssertEqualObjects([NSSet setWithArray:[[[managed.anyDoubleObj sortedResultsUsingKeyPath:@"self" ascending:YES] valueForKey:@"self"] allObjects]], 
                                ([NSSet setWithArray:@[@2.2, @3.3]]));
    uncheckedAssertEqualObjects([NSSet setWithArray:[[[managed.anyStringObj sortedResultsUsingKeyPath:@"self" ascending:YES] valueForKey:@"self"] allObjects]], 
                                ([NSSet setWithArray:@[@"a", @"b"]]));
    uncheckedAssertEqualObjects([NSSet setWithArray:[[[managed.anyDataObj sortedResultsUsingKeyPath:@"self" ascending:YES] valueForKey:@"self"] allObjects]], 
                                ([NSSet setWithArray:@[data(1), data(2)]]));
    uncheckedAssertEqualObjects([NSSet setWithArray:[[[managed.anyDateObj sortedResultsUsingKeyPath:@"self" ascending:YES] valueForKey:@"self"] allObjects]], 
                                ([NSSet setWithArray:@[date(1), date(2)]]));
    uncheckedAssertEqualObjects([NSSet setWithArray:[[[managed.anyDecimalObj sortedResultsUsingKeyPath:@"self" ascending:YES] valueForKey:@"self"] allObjects]], 
                                ([NSSet setWithArray:@[decimal128(1), decimal128(2)]]));
    uncheckedAssertEqualObjects([NSSet setWithArray:[[[managed.anyObjectIdObj sortedResultsUsingKeyPath:@"self" ascending:YES] valueForKey:@"self"] allObjects]], 
                                ([NSSet setWithArray:@[objectId(1), objectId(2)]]));
    uncheckedAssertEqualObjects([NSSet setWithArray:[[[managed.anyUUIDObj sortedResultsUsingKeyPath:@"self" ascending:YES] valueForKey:@"self"] allObjects]], 
                                ([NSSet setWithArray:@[uuid(@"00000000-0000-0000-0000-000000000000"), uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")]]));
    uncheckedAssertEqualObjects([NSSet setWithArray:[[[optManaged.boolObj sortedResultsUsingKeyPath:@"self" ascending:YES] valueForKey:@"self"] allObjects]], 
                                ([NSSet setWithArray:@[NSNull.null, @NO]]));
    uncheckedAssertEqualObjects([NSSet setWithArray:[[[optManaged.intObj sortedResultsUsingKeyPath:@"self" ascending:YES] valueForKey:@"self"] allObjects]], 
                                ([NSSet setWithArray:@[NSNull.null, @2]]));
    uncheckedAssertEqualObjects([NSSet setWithArray:[[[optManaged.floatObj sortedResultsUsingKeyPath:@"self" ascending:YES] valueForKey:@"self"] allObjects]], 
                                ([NSSet setWithArray:@[NSNull.null, @2.2f]]));
    uncheckedAssertEqualObjects([NSSet setWithArray:[[[optManaged.doubleObj sortedResultsUsingKeyPath:@"self" ascending:YES] valueForKey:@"self"] allObjects]], 
                                ([NSSet setWithArray:@[NSNull.null, @2.2]]));
    uncheckedAssertEqualObjects([NSSet setWithArray:[[[optManaged.stringObj sortedResultsUsingKeyPath:@"self" ascending:YES] valueForKey:@"self"] allObjects]], 
                                ([NSSet setWithArray:@[NSNull.null, @"a"]]));
    uncheckedAssertEqualObjects([NSSet setWithArray:[[[optManaged.dataObj sortedResultsUsingKeyPath:@"self" ascending:YES] valueForKey:@"self"] allObjects]], 
                                ([NSSet setWithArray:@[NSNull.null, data(1)]]));
    uncheckedAssertEqualObjects([NSSet setWithArray:[[[optManaged.dateObj sortedResultsUsingKeyPath:@"self" ascending:YES] valueForKey:@"self"] allObjects]], 
                                ([NSSet setWithArray:@[NSNull.null, date(1)]]));
    uncheckedAssertEqualObjects([NSSet setWithArray:[[[optManaged.decimalObj sortedResultsUsingKeyPath:@"self" ascending:YES] valueForKey:@"self"] allObjects]], 
                                ([NSSet setWithArray:@[NSNull.null, decimal128(1)]]));
    uncheckedAssertEqualObjects([NSSet setWithArray:[[[optManaged.objectIdObj sortedResultsUsingKeyPath:@"self" ascending:YES] valueForKey:@"self"] allObjects]], 
                                ([NSSet setWithArray:@[NSNull.null, objectId(1)]]));
    uncheckedAssertEqualObjects([NSSet setWithArray:[[[optManaged.uuidObj sortedResultsUsingKeyPath:@"self" ascending:YES] valueForKey:@"self"] allObjects]], 
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
    RLMAssertThrowsWithReason([unmanaged.anyBoolObj objectsWhere:@"TRUEPREDICATE"], 
                              @"This method may only be called on RLMSet instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.anyIntObj objectsWhere:@"TRUEPREDICATE"], 
                              @"This method may only be called on RLMSet instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.anyFloatObj objectsWhere:@"TRUEPREDICATE"], 
                              @"This method may only be called on RLMSet instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.anyDoubleObj objectsWhere:@"TRUEPREDICATE"], 
                              @"This method may only be called on RLMSet instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.anyStringObj objectsWhere:@"TRUEPREDICATE"], 
                              @"This method may only be called on RLMSet instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.anyDataObj objectsWhere:@"TRUEPREDICATE"], 
                              @"This method may only be called on RLMSet instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.anyDateObj objectsWhere:@"TRUEPREDICATE"], 
                              @"This method may only be called on RLMSet instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.anyDecimalObj objectsWhere:@"TRUEPREDICATE"], 
                              @"This method may only be called on RLMSet instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.anyObjectIdObj objectsWhere:@"TRUEPREDICATE"], 
                              @"This method may only be called on RLMSet instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.anyUUIDObj objectsWhere:@"TRUEPREDICATE"], 
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
    RLMAssertThrowsWithReason([unmanaged.anyBoolObj objectsWithPredicate:[NSPredicate predicateWithValue:YES]], 
                              @"This method may only be called on RLMSet instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.anyIntObj objectsWithPredicate:[NSPredicate predicateWithValue:YES]], 
                              @"This method may only be called on RLMSet instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.anyFloatObj objectsWithPredicate:[NSPredicate predicateWithValue:YES]], 
                              @"This method may only be called on RLMSet instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.anyDoubleObj objectsWithPredicate:[NSPredicate predicateWithValue:YES]], 
                              @"This method may only be called on RLMSet instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.anyStringObj objectsWithPredicate:[NSPredicate predicateWithValue:YES]], 
                              @"This method may only be called on RLMSet instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.anyDataObj objectsWithPredicate:[NSPredicate predicateWithValue:YES]], 
                              @"This method may only be called on RLMSet instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.anyDateObj objectsWithPredicate:[NSPredicate predicateWithValue:YES]], 
                              @"This method may only be called on RLMSet instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.anyDecimalObj objectsWithPredicate:[NSPredicate predicateWithValue:YES]], 
                              @"This method may only be called on RLMSet instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.anyObjectIdObj objectsWithPredicate:[NSPredicate predicateWithValue:YES]], 
                              @"This method may only be called on RLMSet instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.anyUUIDObj objectsWithPredicate:[NSPredicate predicateWithValue:YES]], 
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
    RLMAssertThrowsWithReason([unmanaged.anyBoolObj addNotificationBlock:^(__unused id a, __unused id c, __unused id e) { }], 
                              @"This method may only be called on RLMSet instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.anyIntObj addNotificationBlock:^(__unused id a, __unused id c, __unused id e) { }], 
                              @"This method may only be called on RLMSet instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.anyFloatObj addNotificationBlock:^(__unused id a, __unused id c, __unused id e) { }], 
                              @"This method may only be called on RLMSet instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.anyDoubleObj addNotificationBlock:^(__unused id a, __unused id c, __unused id e) { }], 
                              @"This method may only be called on RLMSet instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.anyStringObj addNotificationBlock:^(__unused id a, __unused id c, __unused id e) { }], 
                              @"This method may only be called on RLMSet instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.anyDataObj addNotificationBlock:^(__unused id a, __unused id c, __unused id e) { }], 
                              @"This method may only be called on RLMSet instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.anyDateObj addNotificationBlock:^(__unused id a, __unused id c, __unused id e) { }], 
                              @"This method may only be called on RLMSet instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.anyDecimalObj addNotificationBlock:^(__unused id a, __unused id c, __unused id e) { }], 
                              @"This method may only be called on RLMSet instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.anyObjectIdObj addNotificationBlock:^(__unused id a, __unused id c, __unused id e) { }], 
                              @"This method may only be called on RLMSet instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.anyUUIDObj addNotificationBlock:^(__unused id a, __unused id c, __unused id e) { }], 
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
    [managed.anyBoolObj addObjects:@[@NO, @YES]];
    [managed.anyIntObj addObjects:@[@2, @3]];
    [managed.anyFloatObj addObjects:@[@2.2f, @3.3f]];
    [managed.anyDoubleObj addObjects:@[@2.2, @3.3]];
    [managed.anyStringObj addObjects:@[@"a", @"b"]];
    [managed.anyDataObj addObjects:@[data(1), data(2)]];
    [managed.anyDateObj addObjects:@[date(1), date(2)]];
    [managed.anyDecimalObj addObjects:@[decimal128(1), decimal128(2)]];
    [managed.anyObjectIdObj addObjects:@[objectId(1), objectId(2)]];
    [managed.anyUUIDObj addObjects:@[uuid(@"00000000-0000-0000-0000-000000000000"), uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")]];
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
    [managed.anyBoolObj2 addObjects:@[@NO, @YES]];
    [managed.anyIntObj2 addObjects:@[@2, @4]];
    [managed.anyFloatObj2 addObjects:@[@2.2f, @4.4f]];
    [managed.anyDoubleObj2 addObjects:@[@2.2, @4.4]];
    [managed.anyStringObj2 addObjects:@[@"a", @"d"]];
    [managed.anyDataObj2 addObjects:@[data(1), data(3)]];
    [managed.anyDateObj2 addObjects:@[date(1), date(3)]];
    [managed.anyDecimalObj2 addObjects:@[decimal128(1), decimal128(3)]];
    [managed.anyObjectIdObj2 addObjects:@[objectId(1), objectId(3)]];
    [managed.anyUUIDObj2 addObjects:@[uuid(@"00000000-0000-0000-0000-000000000000"), uuid(@"123DECC8-B300-4954-A233-F89909F4FD89")]];
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
    [unmanaged.anyBoolObj addObjects:@[@NO, @YES]];
    [unmanaged.anyIntObj addObjects:@[@2, @3]];
    [unmanaged.anyFloatObj addObjects:@[@2.2f, @3.3f]];
    [unmanaged.anyDoubleObj addObjects:@[@2.2, @3.3]];
    [unmanaged.anyStringObj addObjects:@[@"a", @"b"]];
    [unmanaged.anyDataObj addObjects:@[data(1), data(2)]];
    [unmanaged.anyDateObj addObjects:@[date(1), date(2)]];
    [unmanaged.anyDecimalObj addObjects:@[decimal128(1), decimal128(2)]];
    [unmanaged.anyObjectIdObj addObjects:@[objectId(1), objectId(2)]];
    [unmanaged.anyUUIDObj addObjects:@[uuid(@"00000000-0000-0000-0000-000000000000"), uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")]];
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
    [unmanaged.anyBoolObj2 addObjects:@[@NO, @YES]];
    [unmanaged.anyIntObj2 addObjects:@[@2, @4]];
    [unmanaged.anyFloatObj2 addObjects:@[@4.4f, @3.3f]];
    [unmanaged.anyDoubleObj2 addObjects:@[@2.2, @4.4]];
    [unmanaged.anyStringObj2 addObjects:@[@"a", @"d"]];
    [unmanaged.anyDataObj2 addObjects:@[data(1), data(3)]];
    [unmanaged.anyDateObj2 addObjects:@[date(1), date(4)]];
    [unmanaged.anyDecimalObj2 addObjects:@[decimal128(1), decimal128(3)]];
    [unmanaged.anyObjectIdObj2 addObjects:@[objectId(1), objectId(3)]];
    [unmanaged.anyUUIDObj2 addObjects:@[uuid(@"00000000-0000-0000-0000-000000000000"), uuid(@"123DECC8-B300-4954-A233-F89909F4FD89")]];
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
    [unmanaged.anyBoolObj setSet:unmanaged.anyBoolObj2];
    [unmanaged.anyIntObj setSet:unmanaged.anyIntObj2];
    [unmanaged.anyFloatObj setSet:unmanaged.anyFloatObj2];
    [unmanaged.anyDoubleObj setSet:unmanaged.anyDoubleObj2];
    [unmanaged.anyStringObj setSet:unmanaged.anyStringObj2];
    [unmanaged.anyDataObj setSet:unmanaged.anyDataObj2];
    [unmanaged.anyDateObj setSet:unmanaged.anyDateObj2];
    [unmanaged.anyDecimalObj setSet:unmanaged.anyDecimalObj2];
    [unmanaged.anyObjectIdObj setSet:unmanaged.anyObjectIdObj2];
    [unmanaged.anyUUIDObj setSet:unmanaged.anyUUIDObj2];
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
    [managed.anyBoolObj setSet:managed.anyBoolObj2];
    [managed.anyIntObj setSet:managed.anyIntObj2];
    [managed.anyFloatObj setSet:managed.anyFloatObj2];
    [managed.anyDoubleObj setSet:managed.anyDoubleObj2];
    [managed.anyStringObj setSet:managed.anyStringObj2];
    [managed.anyDataObj setSet:managed.anyDataObj2];
    [managed.anyDateObj setSet:managed.anyDateObj2];
    [managed.anyDecimalObj setSet:managed.anyDecimalObj2];
    [managed.anyObjectIdObj setSet:managed.anyObjectIdObj2];
    [managed.anyUUIDObj setSet:managed.anyUUIDObj2];
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

    uncheckedAssertEqual(unmanaged.boolObj.count, 2U);
    uncheckedAssertEqualObjects(unmanaged.boolObj.allObjects, (@[@NO, @YES]));
    uncheckedAssertEqual(managed.boolObj.count, 2U);
    uncheckedAssertEqualObjects([NSSet setWithArray:managed.boolObj.allObjects], ([NSSet setWithArray:@[@NO, @YES]]));
    uncheckedAssertEqual(optManaged.boolObj.count, 3U);
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
    [managed.anyBoolObj addObjects:@[@NO, @YES]];
    [managed.anyIntObj addObjects:@[@2, @3]];
    [managed.anyFloatObj addObjects:@[@2.2f, @3.3f]];
    [managed.anyDoubleObj addObjects:@[@2.2, @3.3]];
    [managed.anyStringObj addObjects:@[@"a", @"b"]];
    [managed.anyDataObj addObjects:@[data(1), data(2)]];
    [managed.anyDateObj addObjects:@[date(1), date(2)]];
    [managed.anyDecimalObj addObjects:@[decimal128(1), decimal128(2)]];
    [managed.anyObjectIdObj addObjects:@[objectId(1), objectId(2)]];
    [managed.anyUUIDObj addObjects:@[uuid(@"00000000-0000-0000-0000-000000000000"), uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")]];
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
    [managed.anyBoolObj2 addObjects:@[@NO, @YES]];
    [managed.anyIntObj2 addObjects:@[@2, @4]];
    [managed.anyFloatObj2 addObjects:@[@2.2f, @4.4f]];
    [managed.anyDoubleObj2 addObjects:@[@2.2, @4.4]];
    [managed.anyStringObj2 addObjects:@[@"a", @"d"]];
    [managed.anyDataObj2 addObjects:@[data(1), data(3)]];
    [managed.anyDateObj2 addObjects:@[date(1), date(3)]];
    [managed.anyDecimalObj2 addObjects:@[decimal128(1), decimal128(3)]];
    [managed.anyObjectIdObj2 addObjects:@[objectId(1), objectId(3)]];
    [managed.anyUUIDObj2 addObjects:@[uuid(@"00000000-0000-0000-0000-000000000000"), uuid(@"123DECC8-B300-4954-A233-F89909F4FD89")]];
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
    [unmanaged.anyBoolObj addObjects:@[@NO, @YES]];
    [unmanaged.anyIntObj addObjects:@[@2, @3]];
    [unmanaged.anyFloatObj addObjects:@[@2.2f, @3.3f]];
    [unmanaged.anyDoubleObj addObjects:@[@2.2, @3.3]];
    [unmanaged.anyStringObj addObjects:@[@"a", @"b"]];
    [unmanaged.anyDataObj addObjects:@[data(1), data(2)]];
    [unmanaged.anyDateObj addObjects:@[date(1), date(2)]];
    [unmanaged.anyDecimalObj addObjects:@[decimal128(1), decimal128(2)]];
    [unmanaged.anyObjectIdObj addObjects:@[objectId(1), objectId(2)]];
    [unmanaged.anyUUIDObj addObjects:@[uuid(@"00000000-0000-0000-0000-000000000000"), uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")]];
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
    [unmanaged.anyBoolObj2 addObjects:@[@NO, @YES]];
    [unmanaged.anyIntObj2 addObjects:@[@2, @4]];
    [unmanaged.anyFloatObj2 addObjects:@[@4.4f, @3.3f]];
    [unmanaged.anyDoubleObj2 addObjects:@[@2.2, @4.4]];
    [unmanaged.anyStringObj2 addObjects:@[@"a", @"d"]];
    [unmanaged.anyDataObj2 addObjects:@[data(1), data(3)]];
    [unmanaged.anyDateObj2 addObjects:@[date(1), date(4)]];
    [unmanaged.anyDecimalObj2 addObjects:@[decimal128(1), decimal128(3)]];
    [unmanaged.anyObjectIdObj2 addObjects:@[objectId(1), objectId(3)]];
    [unmanaged.anyUUIDObj2 addObjects:@[uuid(@"00000000-0000-0000-0000-000000000000"), uuid(@"123DECC8-B300-4954-A233-F89909F4FD89")]];
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
    XCTAssertThrows([managed.anyBoolObj unionSet:managed.anyBoolObj2]);
    XCTAssertThrows([managed.anyIntObj unionSet:managed.anyIntObj2]);
    XCTAssertThrows([managed.anyFloatObj unionSet:managed.anyFloatObj2]);
    XCTAssertThrows([managed.anyDoubleObj unionSet:managed.anyDoubleObj2]);
    XCTAssertThrows([managed.anyStringObj unionSet:managed.anyStringObj2]);
    XCTAssertThrows([managed.anyDataObj unionSet:managed.anyDataObj2]);
    XCTAssertThrows([managed.anyDateObj unionSet:managed.anyDateObj2]);
    XCTAssertThrows([managed.anyDecimalObj unionSet:managed.anyDecimalObj2]);
    XCTAssertThrows([managed.anyObjectIdObj unionSet:managed.anyObjectIdObj2]);
    XCTAssertThrows([managed.anyUUIDObj unionSet:managed.anyUUIDObj2]);
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
    [unmanaged.anyBoolObj unionSet:unmanaged.anyBoolObj2];
    [unmanaged.anyIntObj unionSet:unmanaged.anyIntObj2];
    [unmanaged.anyFloatObj unionSet:unmanaged.anyFloatObj2];
    [unmanaged.anyDoubleObj unionSet:unmanaged.anyDoubleObj2];
    [unmanaged.anyStringObj unionSet:unmanaged.anyStringObj2];
    [unmanaged.anyDataObj unionSet:unmanaged.anyDataObj2];
    [unmanaged.anyDateObj unionSet:unmanaged.anyDateObj2];
    [unmanaged.anyDecimalObj unionSet:unmanaged.anyDecimalObj2];
    [unmanaged.anyObjectIdObj unionSet:unmanaged.anyObjectIdObj2];
    [unmanaged.anyUUIDObj unionSet:unmanaged.anyUUIDObj2];
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
    [managed.anyBoolObj unionSet:managed.anyBoolObj2];
    [managed.anyIntObj unionSet:managed.anyIntObj2];
    [managed.anyFloatObj unionSet:managed.anyFloatObj2];
    [managed.anyDoubleObj unionSet:managed.anyDoubleObj2];
    [managed.anyStringObj unionSet:managed.anyStringObj2];
    [managed.anyDataObj unionSet:managed.anyDataObj2];
    [managed.anyDateObj unionSet:managed.anyDateObj2];
    [managed.anyDecimalObj unionSet:managed.anyDecimalObj2];
    [managed.anyObjectIdObj unionSet:managed.anyObjectIdObj2];
    [managed.anyUUIDObj unionSet:managed.anyUUIDObj2];
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

    uncheckedAssertEqual(unmanaged.boolObj.count, 2U);
    uncheckedAssertEqualObjects([NSSet setWithArray:unmanaged.boolObj.allObjects], ([NSSet setWithArray:@[@NO, @YES]]));
    uncheckedAssertEqual(managed.boolObj.count, 2U);
    uncheckedAssertEqualObjects([NSSet setWithArray:managed.boolObj.allObjects], ([NSSet setWithArray:@[@NO, @YES]]));
    uncheckedAssertEqual(optManaged.boolObj.count, 3U);
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
    [managed.anyBoolObj addObjects:@[@NO, @YES]];
    [managed.anyIntObj addObjects:@[@2, @3]];
    [managed.anyFloatObj addObjects:@[@2.2f, @3.3f]];
    [managed.anyDoubleObj addObjects:@[@2.2, @3.3]];
    [managed.anyStringObj addObjects:@[@"a", @"b"]];
    [managed.anyDataObj addObjects:@[data(1), data(2)]];
    [managed.anyDateObj addObjects:@[date(1), date(2)]];
    [managed.anyDecimalObj addObjects:@[decimal128(1), decimal128(2)]];
    [managed.anyObjectIdObj addObjects:@[objectId(1), objectId(2)]];
    [managed.anyUUIDObj addObjects:@[uuid(@"00000000-0000-0000-0000-000000000000"), uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")]];
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
    [managed.anyBoolObj2 addObjects:@[@NO, @YES]];
    [managed.anyIntObj2 addObjects:@[@2, @4]];
    [managed.anyFloatObj2 addObjects:@[@2.2f, @4.4f]];
    [managed.anyDoubleObj2 addObjects:@[@2.2, @4.4]];
    [managed.anyStringObj2 addObjects:@[@"a", @"d"]];
    [managed.anyDataObj2 addObjects:@[data(1), data(3)]];
    [managed.anyDateObj2 addObjects:@[date(1), date(3)]];
    [managed.anyDecimalObj2 addObjects:@[decimal128(1), decimal128(3)]];
    [managed.anyObjectIdObj2 addObjects:@[objectId(1), objectId(3)]];
    [managed.anyUUIDObj2 addObjects:@[uuid(@"00000000-0000-0000-0000-000000000000"), uuid(@"123DECC8-B300-4954-A233-F89909F4FD89")]];
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
    [unmanaged.anyBoolObj addObjects:@[@NO, @YES]];
    [unmanaged.anyIntObj addObjects:@[@2, @3]];
    [unmanaged.anyFloatObj addObjects:@[@2.2f, @3.3f]];
    [unmanaged.anyDoubleObj addObjects:@[@2.2, @3.3]];
    [unmanaged.anyStringObj addObjects:@[@"a", @"b"]];
    [unmanaged.anyDataObj addObjects:@[data(1), data(2)]];
    [unmanaged.anyDateObj addObjects:@[date(1), date(2)]];
    [unmanaged.anyDecimalObj addObjects:@[decimal128(1), decimal128(2)]];
    [unmanaged.anyObjectIdObj addObjects:@[objectId(1), objectId(2)]];
    [unmanaged.anyUUIDObj addObjects:@[uuid(@"00000000-0000-0000-0000-000000000000"), uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")]];
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
    [unmanaged.anyBoolObj2 addObjects:@[@NO, @YES]];
    [unmanaged.anyIntObj2 addObjects:@[@2, @4]];
    [unmanaged.anyFloatObj2 addObjects:@[@4.4f, @3.3f]];
    [unmanaged.anyDoubleObj2 addObjects:@[@2.2, @4.4]];
    [unmanaged.anyStringObj2 addObjects:@[@"a", @"d"]];
    [unmanaged.anyDataObj2 addObjects:@[data(1), data(3)]];
    [unmanaged.anyDateObj2 addObjects:@[date(1), date(4)]];
    [unmanaged.anyDecimalObj2 addObjects:@[decimal128(1), decimal128(3)]];
    [unmanaged.anyObjectIdObj2 addObjects:@[objectId(1), objectId(3)]];
    [unmanaged.anyUUIDObj2 addObjects:@[uuid(@"00000000-0000-0000-0000-000000000000"), uuid(@"123DECC8-B300-4954-A233-F89909F4FD89")]];
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
    XCTAssertThrows([managed.anyBoolObj intersectSet:managed.anyBoolObj2]);
    XCTAssertThrows([managed.anyIntObj intersectSet:managed.anyIntObj2]);
    XCTAssertThrows([managed.anyFloatObj intersectSet:managed.anyFloatObj2]);
    XCTAssertThrows([managed.anyDoubleObj intersectSet:managed.anyDoubleObj2]);
    XCTAssertThrows([managed.anyStringObj intersectSet:managed.anyStringObj2]);
    XCTAssertThrows([managed.anyDataObj intersectSet:managed.anyDataObj2]);
    XCTAssertThrows([managed.anyDateObj intersectSet:managed.anyDateObj2]);
    XCTAssertThrows([managed.anyDecimalObj intersectSet:managed.anyDecimalObj2]);
    XCTAssertThrows([managed.anyObjectIdObj intersectSet:managed.anyObjectIdObj2]);
    XCTAssertThrows([managed.anyUUIDObj intersectSet:managed.anyUUIDObj2]);
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
    uncheckedAssertTrue([managed.boolObj intersectsSet:managed.boolObj2]);
    uncheckedAssertTrue([managed.intObj intersectsSet:managed.intObj2]);
    uncheckedAssertTrue([managed.floatObj intersectsSet:managed.floatObj2]);
    uncheckedAssertTrue([managed.doubleObj intersectsSet:managed.doubleObj2]);
    uncheckedAssertTrue([managed.stringObj intersectsSet:managed.stringObj2]);
    uncheckedAssertTrue([managed.dataObj intersectsSet:managed.dataObj2]);
    uncheckedAssertTrue([managed.dateObj intersectsSet:managed.dateObj2]);
    uncheckedAssertTrue([managed.decimalObj intersectsSet:managed.decimalObj2]);
    uncheckedAssertTrue([managed.objectIdObj intersectsSet:managed.objectIdObj2]);
    uncheckedAssertTrue([managed.uuidObj intersectsSet:managed.uuidObj2]);
    uncheckedAssertTrue([managed.anyBoolObj intersectsSet:managed.anyBoolObj2]);
    uncheckedAssertTrue([managed.anyIntObj intersectsSet:managed.anyIntObj2]);
    uncheckedAssertTrue([managed.anyFloatObj intersectsSet:managed.anyFloatObj2]);
    uncheckedAssertTrue([managed.anyDoubleObj intersectsSet:managed.anyDoubleObj2]);
    uncheckedAssertTrue([managed.anyStringObj intersectsSet:managed.anyStringObj2]);
    uncheckedAssertTrue([managed.anyDataObj intersectsSet:managed.anyDataObj2]);
    uncheckedAssertTrue([managed.anyDateObj intersectsSet:managed.anyDateObj2]);
    uncheckedAssertTrue([managed.anyDecimalObj intersectsSet:managed.anyDecimalObj2]);
    uncheckedAssertTrue([managed.anyObjectIdObj intersectsSet:managed.anyObjectIdObj2]);
    uncheckedAssertTrue([managed.anyUUIDObj intersectsSet:managed.anyUUIDObj2]);
    uncheckedAssertTrue([optManaged.boolObj intersectsSet:optManaged.boolObj2]);
    uncheckedAssertTrue([optManaged.intObj intersectsSet:optManaged.intObj2]);
    uncheckedAssertTrue([optManaged.floatObj intersectsSet:optManaged.floatObj2]);
    uncheckedAssertTrue([optManaged.doubleObj intersectsSet:optManaged.doubleObj2]);
    uncheckedAssertTrue([optManaged.stringObj intersectsSet:optManaged.stringObj2]);
    uncheckedAssertTrue([optManaged.dataObj intersectsSet:optManaged.dataObj2]);
    uncheckedAssertTrue([optManaged.dateObj intersectsSet:optManaged.dateObj2]);
    uncheckedAssertTrue([optManaged.decimalObj intersectsSet:optManaged.decimalObj2]);
    uncheckedAssertTrue([optManaged.objectIdObj intersectsSet:optManaged.objectIdObj2]);
    uncheckedAssertTrue([optManaged.uuidObj intersectsSet:optManaged.uuidObj2]);
    uncheckedAssertTrue([unmanaged.boolObj intersectsSet:unmanaged.boolObj2]);
    uncheckedAssertTrue([unmanaged.intObj intersectsSet:unmanaged.intObj2]);
    uncheckedAssertTrue([unmanaged.floatObj intersectsSet:unmanaged.floatObj2]);
    uncheckedAssertTrue([unmanaged.doubleObj intersectsSet:unmanaged.doubleObj2]);
    uncheckedAssertTrue([unmanaged.stringObj intersectsSet:unmanaged.stringObj2]);
    uncheckedAssertTrue([unmanaged.dataObj intersectsSet:unmanaged.dataObj2]);
    uncheckedAssertTrue([unmanaged.dateObj intersectsSet:unmanaged.dateObj2]);
    uncheckedAssertTrue([unmanaged.decimalObj intersectsSet:unmanaged.decimalObj2]);
    uncheckedAssertTrue([unmanaged.objectIdObj intersectsSet:unmanaged.objectIdObj2]);
    uncheckedAssertTrue([unmanaged.uuidObj intersectsSet:unmanaged.uuidObj2]);
    uncheckedAssertTrue([unmanaged.anyBoolObj intersectsSet:unmanaged.anyBoolObj2]);
    uncheckedAssertTrue([unmanaged.anyIntObj intersectsSet:unmanaged.anyIntObj2]);
    uncheckedAssertTrue([unmanaged.anyFloatObj intersectsSet:unmanaged.anyFloatObj2]);
    uncheckedAssertTrue([unmanaged.anyDoubleObj intersectsSet:unmanaged.anyDoubleObj2]);
    uncheckedAssertTrue([unmanaged.anyStringObj intersectsSet:unmanaged.anyStringObj2]);
    uncheckedAssertTrue([unmanaged.anyDataObj intersectsSet:unmanaged.anyDataObj2]);
    uncheckedAssertTrue([unmanaged.anyDateObj intersectsSet:unmanaged.anyDateObj2]);
    uncheckedAssertTrue([unmanaged.anyDecimalObj intersectsSet:unmanaged.anyDecimalObj2]);
    uncheckedAssertTrue([unmanaged.anyObjectIdObj intersectsSet:unmanaged.anyObjectIdObj2]);
    uncheckedAssertTrue([unmanaged.anyUUIDObj intersectsSet:unmanaged.anyUUIDObj2]);
    uncheckedAssertTrue([optUnmanaged.intObj intersectsSet:optUnmanaged.intObj2]);
    uncheckedAssertTrue([optUnmanaged.floatObj intersectsSet:optUnmanaged.floatObj2]);
    uncheckedAssertTrue([optUnmanaged.doubleObj intersectsSet:optUnmanaged.doubleObj2]);
    uncheckedAssertTrue([optUnmanaged.stringObj intersectsSet:optUnmanaged.stringObj2]);
    uncheckedAssertTrue([optUnmanaged.dataObj intersectsSet:optUnmanaged.dataObj2]);
    uncheckedAssertTrue([optUnmanaged.dateObj intersectsSet:optUnmanaged.dateObj2]);
    uncheckedAssertTrue([optUnmanaged.decimalObj intersectsSet:optUnmanaged.decimalObj2]);
    uncheckedAssertTrue([optUnmanaged.objectIdObj intersectsSet:optUnmanaged.objectIdObj2]);
    uncheckedAssertTrue([optUnmanaged.uuidObj intersectsSet:optUnmanaged.uuidObj2]);

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
    [unmanaged.anyBoolObj intersectSet:unmanaged.anyBoolObj2];
    [unmanaged.anyIntObj intersectSet:unmanaged.anyIntObj2];
    [unmanaged.anyFloatObj intersectSet:unmanaged.anyFloatObj2];
    [unmanaged.anyDoubleObj intersectSet:unmanaged.anyDoubleObj2];
    [unmanaged.anyStringObj intersectSet:unmanaged.anyStringObj2];
    [unmanaged.anyDataObj intersectSet:unmanaged.anyDataObj2];
    [unmanaged.anyDateObj intersectSet:unmanaged.anyDateObj2];
    [unmanaged.anyDecimalObj intersectSet:unmanaged.anyDecimalObj2];
    [unmanaged.anyObjectIdObj intersectSet:unmanaged.anyObjectIdObj2];
    [unmanaged.anyUUIDObj intersectSet:unmanaged.anyUUIDObj2];
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
    [managed.anyBoolObj intersectSet:managed.anyBoolObj2];
    [managed.anyIntObj intersectSet:managed.anyIntObj2];
    [managed.anyFloatObj intersectSet:managed.anyFloatObj2];
    [managed.anyDoubleObj intersectSet:managed.anyDoubleObj2];
    [managed.anyStringObj intersectSet:managed.anyStringObj2];
    [managed.anyDataObj intersectSet:managed.anyDataObj2];
    [managed.anyDateObj intersectSet:managed.anyDateObj2];
    [managed.anyDecimalObj intersectSet:managed.anyDecimalObj2];
    [managed.anyObjectIdObj intersectSet:managed.anyObjectIdObj2];
    [managed.anyUUIDObj intersectSet:managed.anyUUIDObj2];
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

    uncheckedAssertEqual(unmanaged.boolObj.count, 2U);
    uncheckedAssertEqualObjects([NSSet setWithArray:unmanaged.boolObj.allObjects], ([NSSet setWithArray:@[@NO, @YES]]));
    uncheckedAssertEqual(managed.boolObj.count, 2U);
    uncheckedAssertEqualObjects([NSSet setWithArray:managed.boolObj.allObjects], ([NSSet setWithArray:@[@NO, @YES]]));
    uncheckedAssertEqual(optManaged.boolObj.count, 2U);
    uncheckedAssertEqualObjects([NSSet setWithArray:optManaged.boolObj.allObjects], ([NSSet setWithArray:@[NSNull.null, @NO]]));
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
    [managed.anyBoolObj addObjects:@[@NO, @YES]];
    [managed.anyIntObj addObjects:@[@2, @3]];
    [managed.anyFloatObj addObjects:@[@2.2f, @3.3f]];
    [managed.anyDoubleObj addObjects:@[@2.2, @3.3]];
    [managed.anyStringObj addObjects:@[@"a", @"b"]];
    [managed.anyDataObj addObjects:@[data(1), data(2)]];
    [managed.anyDateObj addObjects:@[date(1), date(2)]];
    [managed.anyDecimalObj addObjects:@[decimal128(1), decimal128(2)]];
    [managed.anyObjectIdObj addObjects:@[objectId(1), objectId(2)]];
    [managed.anyUUIDObj addObjects:@[uuid(@"00000000-0000-0000-0000-000000000000"), uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")]];
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
    [managed.anyBoolObj2 addObjects:@[@NO, @YES]];
    [managed.anyIntObj2 addObjects:@[@2, @4]];
    [managed.anyFloatObj2 addObjects:@[@2.2f, @4.4f]];
    [managed.anyDoubleObj2 addObjects:@[@2.2, @4.4]];
    [managed.anyStringObj2 addObjects:@[@"a", @"d"]];
    [managed.anyDataObj2 addObjects:@[data(1), data(3)]];
    [managed.anyDateObj2 addObjects:@[date(1), date(3)]];
    [managed.anyDecimalObj2 addObjects:@[decimal128(1), decimal128(3)]];
    [managed.anyObjectIdObj2 addObjects:@[objectId(1), objectId(3)]];
    [managed.anyUUIDObj2 addObjects:@[uuid(@"00000000-0000-0000-0000-000000000000"), uuid(@"123DECC8-B300-4954-A233-F89909F4FD89")]];
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
    [unmanaged.anyBoolObj addObjects:@[@NO, @YES]];
    [unmanaged.anyIntObj addObjects:@[@2, @3]];
    [unmanaged.anyFloatObj addObjects:@[@2.2f, @3.3f]];
    [unmanaged.anyDoubleObj addObjects:@[@2.2, @3.3]];
    [unmanaged.anyStringObj addObjects:@[@"a", @"b"]];
    [unmanaged.anyDataObj addObjects:@[data(1), data(2)]];
    [unmanaged.anyDateObj addObjects:@[date(1), date(2)]];
    [unmanaged.anyDecimalObj addObjects:@[decimal128(1), decimal128(2)]];
    [unmanaged.anyObjectIdObj addObjects:@[objectId(1), objectId(2)]];
    [unmanaged.anyUUIDObj addObjects:@[uuid(@"00000000-0000-0000-0000-000000000000"), uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")]];
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
    [unmanaged.anyBoolObj2 addObjects:@[@NO, @YES]];
    [unmanaged.anyIntObj2 addObjects:@[@2, @4]];
    [unmanaged.anyFloatObj2 addObjects:@[@4.4f, @3.3f]];
    [unmanaged.anyDoubleObj2 addObjects:@[@2.2, @4.4]];
    [unmanaged.anyStringObj2 addObjects:@[@"a", @"d"]];
    [unmanaged.anyDataObj2 addObjects:@[data(1), data(3)]];
    [unmanaged.anyDateObj2 addObjects:@[date(1), date(4)]];
    [unmanaged.anyDecimalObj2 addObjects:@[decimal128(1), decimal128(3)]];
    [unmanaged.anyObjectIdObj2 addObjects:@[objectId(1), objectId(3)]];
    [unmanaged.anyUUIDObj2 addObjects:@[uuid(@"00000000-0000-0000-0000-000000000000"), uuid(@"123DECC8-B300-4954-A233-F89909F4FD89")]];
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
    XCTAssertThrows([managed.anyBoolObj minusSet:managed.anyBoolObj2]);
    XCTAssertThrows([managed.anyIntObj minusSet:managed.anyIntObj2]);
    XCTAssertThrows([managed.anyFloatObj minusSet:managed.anyFloatObj2]);
    XCTAssertThrows([managed.anyDoubleObj minusSet:managed.anyDoubleObj2]);
    XCTAssertThrows([managed.anyStringObj minusSet:managed.anyStringObj2]);
    XCTAssertThrows([managed.anyDataObj minusSet:managed.anyDataObj2]);
    XCTAssertThrows([managed.anyDateObj minusSet:managed.anyDateObj2]);
    XCTAssertThrows([managed.anyDecimalObj minusSet:managed.anyDecimalObj2]);
    XCTAssertThrows([managed.anyObjectIdObj minusSet:managed.anyObjectIdObj2]);
    XCTAssertThrows([managed.anyUUIDObj minusSet:managed.anyUUIDObj2]);
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
    [unmanaged.anyBoolObj minusSet:unmanaged.anyBoolObj2];
    [unmanaged.anyIntObj minusSet:unmanaged.anyIntObj2];
    [unmanaged.anyFloatObj minusSet:unmanaged.anyFloatObj2];
    [unmanaged.anyDoubleObj minusSet:unmanaged.anyDoubleObj2];
    [unmanaged.anyStringObj minusSet:unmanaged.anyStringObj2];
    [unmanaged.anyDataObj minusSet:unmanaged.anyDataObj2];
    [unmanaged.anyDateObj minusSet:unmanaged.anyDateObj2];
    [unmanaged.anyDecimalObj minusSet:unmanaged.anyDecimalObj2];
    [unmanaged.anyObjectIdObj minusSet:unmanaged.anyObjectIdObj2];
    [unmanaged.anyUUIDObj minusSet:unmanaged.anyUUIDObj2];
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
    [managed.anyBoolObj minusSet:managed.anyBoolObj2];
    [managed.anyIntObj minusSet:managed.anyIntObj2];
    [managed.anyFloatObj minusSet:managed.anyFloatObj2];
    [managed.anyDoubleObj minusSet:managed.anyDoubleObj2];
    [managed.anyStringObj minusSet:managed.anyStringObj2];
    [managed.anyDataObj minusSet:managed.anyDataObj2];
    [managed.anyDateObj minusSet:managed.anyDateObj2];
    [managed.anyDecimalObj minusSet:managed.anyDecimalObj2];
    [managed.anyObjectIdObj minusSet:managed.anyObjectIdObj2];
    [managed.anyUUIDObj minusSet:managed.anyUUIDObj2];
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

    uncheckedAssertEqual(unmanaged.boolObj.count, 0U);
    uncheckedAssertEqualObjects(unmanaged.boolObj.allObjects, (@[]));
    uncheckedAssertEqual(managed.boolObj.count, 0U);
    uncheckedAssertEqualObjects(managed.boolObj.allObjects, (@[]));
    uncheckedAssertEqual(optManaged.boolObj.count, 0U);
    uncheckedAssertEqualObjects(optManaged.boolObj.allObjects, (@[]));
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
    [managed.anyBoolObj addObjects:@[@NO, @YES]];
    [managed.anyIntObj addObjects:@[@2, @3]];
    [managed.anyFloatObj addObjects:@[@2.2f, @3.3f]];
    [managed.anyDoubleObj addObjects:@[@2.2, @3.3]];
    [managed.anyStringObj addObjects:@[@"a", @"b"]];
    [managed.anyDataObj addObjects:@[data(1), data(2)]];
    [managed.anyDateObj addObjects:@[date(1), date(2)]];
    [managed.anyDecimalObj addObjects:@[decimal128(1), decimal128(2)]];
    [managed.anyObjectIdObj addObjects:@[objectId(1), objectId(2)]];
    [managed.anyUUIDObj addObjects:@[uuid(@"00000000-0000-0000-0000-000000000000"), uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")]];
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
    [managed.anyBoolObj2 addObjects:@[@NO, @YES, @NO, @YES]];
    [managed.anyIntObj2 addObjects:@[@2, @3, @2, @4]];
    [managed.anyFloatObj2 addObjects:@[@2.2f, @3.3f, @2.2f, @4.4f]];
    [managed.anyDoubleObj2 addObjects:@[@2.2, @3.3, @2.2, @4.4]];
    [managed.anyStringObj2 addObjects:@[@"a", @"b", @"a", @"d"]];
    [managed.anyDataObj2 addObjects:@[data(1), data(2), data(1), data(3)]];
    [managed.anyDateObj2 addObjects:@[date(1), date(2), date(1), date(3)]];
    [managed.anyDecimalObj2 addObjects:@[decimal128(1), decimal128(2), decimal128(1), decimal128(3)]];
    [managed.anyObjectIdObj2 addObjects:@[objectId(1), objectId(2), objectId(1), objectId(3)]];
    [managed.anyUUIDObj2 addObjects:@[uuid(@"00000000-0000-0000-0000-000000000000"), uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"), uuid(@"00000000-0000-0000-0000-000000000000"), uuid(@"123DECC8-B300-4954-A233-F89909F4FD89")]];
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
    [unmanaged.anyBoolObj addObjects:@[@NO, @YES]];
    [unmanaged.anyIntObj addObjects:@[@2, @3]];
    [unmanaged.anyFloatObj addObjects:@[@2.2f, @3.3f]];
    [unmanaged.anyDoubleObj addObjects:@[@2.2, @3.3]];
    [unmanaged.anyStringObj addObjects:@[@"a", @"b"]];
    [unmanaged.anyDataObj addObjects:@[data(1), data(2)]];
    [unmanaged.anyDateObj addObjects:@[date(1), date(2)]];
    [unmanaged.anyDecimalObj addObjects:@[decimal128(1), decimal128(2)]];
    [unmanaged.anyObjectIdObj addObjects:@[objectId(1), objectId(2)]];
    [unmanaged.anyUUIDObj addObjects:@[uuid(@"00000000-0000-0000-0000-000000000000"), uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")]];
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
    [unmanaged.anyBoolObj2 addObjects:@[@NO, @YES, @NO, @YES]];
    [unmanaged.anyIntObj2 addObjects:@[@2, @3, @2, @4]];
    [unmanaged.anyFloatObj2 addObjects:@[@2.2f, @3.3f, @4.4f, @3.3f]];
    [unmanaged.anyDoubleObj2 addObjects:@[@2.2, @3.3, @2.2, @4.4]];
    [unmanaged.anyStringObj2 addObjects:@[@"a", @"b", @"a", @"d"]];
    [unmanaged.anyDataObj2 addObjects:@[data(1), data(2), data(1), data(3)]];
    [unmanaged.anyDateObj2 addObjects:@[date(1), date(2), date(1), date(4)]];
    [unmanaged.anyDecimalObj2 addObjects:@[decimal128(1), decimal128(2), decimal128(1), decimal128(3)]];
    [unmanaged.anyObjectIdObj2 addObjects:@[objectId(1), objectId(2), objectId(1), objectId(3)]];
    [unmanaged.anyUUIDObj2 addObjects:@[uuid(@"00000000-0000-0000-0000-000000000000"), uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"), uuid(@"00000000-0000-0000-0000-000000000000"), uuid(@"123DECC8-B300-4954-A233-F89909F4FD89")]];
    [optUnmanaged.intObj2 addObjects:@[NSNull.null, @2, @3, @4, NSNull.null]];
    [optUnmanaged.floatObj2 addObjects:@[NSNull.null, @2.2f, @3.3f, @4.4f, NSNull.null]];
    [optUnmanaged.doubleObj2 addObjects:@[NSNull.null, @2.2, @3.3, @4.4, NSNull.null]];
    [optUnmanaged.stringObj2 addObjects:@[NSNull.null, @"a", @"bc", @"de", NSNull.null]];
    [optUnmanaged.dataObj2 addObjects:@[NSNull.null, data(1), data(2), data(3), NSNull.null]];
    [optUnmanaged.dateObj2 addObjects:@[NSNull.null, date(1), date(2), date(3), NSNull.null]];
    [optUnmanaged.decimalObj2 addObjects:@[NSNull.null, decimal128(1), decimal128(2), decimal128(4), NSNull.null]];
    [optUnmanaged.objectIdObj2 addObjects:@[NSNull.null, objectId(1), objectId(2), objectId(4), NSNull.null]];
    [optUnmanaged.uuidObj2 addObjects:@[NSNull.null, uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"), uuid(@"00000000-0000-0000-0000-000000000000"), uuid(@"123DECC8-B300-4954-A233-F89909F4FD89"), NSNull.null]];

    uncheckedAssertTrue([managed.boolObj2 isSubsetOfSet:managed.boolObj]);
    uncheckedAssertTrue([unmanaged.boolObj2 isSubsetOfSet:unmanaged.boolObj]);
    uncheckedAssertFalse([optManaged.boolObj2 isSubsetOfSet:optManaged.boolObj]);

    uncheckedAssertTrue([managed.boolObj isSubsetOfSet:managed.boolObj2]);
    uncheckedAssertTrue([unmanaged.boolObj isSubsetOfSet:unmanaged.boolObj2]);
    uncheckedAssertTrue([optManaged.boolObj isSubsetOfSet:optManaged.boolObj2]);

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

    uncheckedAssertNil([unmanaged.intObj minOfProperty:@"self"]);
    uncheckedAssertNil([unmanaged.floatObj minOfProperty:@"self"]);
    uncheckedAssertNil([unmanaged.doubleObj minOfProperty:@"self"]);
    uncheckedAssertNil([unmanaged.dateObj minOfProperty:@"self"]);
    uncheckedAssertNil([unmanaged.decimalObj minOfProperty:@"self"]);
    uncheckedAssertNil([unmanaged.anyFloatObj minOfProperty:@"self"]);
    uncheckedAssertNil([unmanaged.anyDoubleObj minOfProperty:@"self"]);
    uncheckedAssertNil([unmanaged.anyDateObj minOfProperty:@"self"]);
    uncheckedAssertNil([unmanaged.anyDecimalObj minOfProperty:@"self"]);
    uncheckedAssertNil([optUnmanaged.intObj minOfProperty:@"self"]);
    uncheckedAssertNil([optUnmanaged.floatObj minOfProperty:@"self"]);
    uncheckedAssertNil([optUnmanaged.doubleObj minOfProperty:@"self"]);
    uncheckedAssertNil([optUnmanaged.dateObj minOfProperty:@"self"]);
    uncheckedAssertNil([optUnmanaged.decimalObj minOfProperty:@"self"]);
    uncheckedAssertNil([managed.intObj minOfProperty:@"self"]);
    uncheckedAssertNil([managed.floatObj minOfProperty:@"self"]);
    uncheckedAssertNil([managed.doubleObj minOfProperty:@"self"]);
    uncheckedAssertNil([managed.dateObj minOfProperty:@"self"]);
    uncheckedAssertNil([managed.decimalObj minOfProperty:@"self"]);
    uncheckedAssertNil([managed.anyIntObj minOfProperty:@"self"]);
    uncheckedAssertNil([managed.anyFloatObj minOfProperty:@"self"]);
    uncheckedAssertNil([managed.anyDoubleObj minOfProperty:@"self"]);
    uncheckedAssertNil([managed.anyDateObj minOfProperty:@"self"]);
    uncheckedAssertNil([managed.anyDecimalObj minOfProperty:@"self"]);
    uncheckedAssertNil([optManaged.intObj minOfProperty:@"self"]);
    uncheckedAssertNil([optManaged.floatObj minOfProperty:@"self"]);
    uncheckedAssertNil([optManaged.doubleObj minOfProperty:@"self"]);
    uncheckedAssertNil([optManaged.dateObj minOfProperty:@"self"]);
    uncheckedAssertNil([optManaged.decimalObj minOfProperty:@"self"]);

    [self addObjects];

    uncheckedAssertEqualObjects([unmanaged.intObj minOfProperty:@"self"], @2);
    uncheckedAssertEqualObjects([unmanaged.floatObj minOfProperty:@"self"], @2.2f);
    uncheckedAssertEqualObjects([unmanaged.doubleObj minOfProperty:@"self"], @2.2);
    uncheckedAssertEqualObjects([unmanaged.dateObj minOfProperty:@"self"], date(1));
    uncheckedAssertEqualObjects([unmanaged.decimalObj minOfProperty:@"self"], decimal128(1));
    uncheckedAssertEqualObjects([unmanaged.anyFloatObj minOfProperty:@"self"], @2.2f);
    uncheckedAssertEqualObjects([unmanaged.anyDoubleObj minOfProperty:@"self"], @2.2);
    uncheckedAssertEqualObjects([unmanaged.anyDateObj minOfProperty:@"self"], date(1));
    uncheckedAssertEqualObjects([unmanaged.anyDecimalObj minOfProperty:@"self"], decimal128(1));
    uncheckedAssertEqualObjects([optUnmanaged.intObj minOfProperty:@"self"], @2);
    uncheckedAssertEqualObjects([optUnmanaged.floatObj minOfProperty:@"self"], @2.2f);
    uncheckedAssertEqualObjects([optUnmanaged.doubleObj minOfProperty:@"self"], @2.2);
    uncheckedAssertEqualObjects([optUnmanaged.dateObj minOfProperty:@"self"], date(1));
    uncheckedAssertEqualObjects([optUnmanaged.decimalObj minOfProperty:@"self"], decimal128(1));

    uncheckedAssertEqualObjects([managed.intObj minOfProperty:@"self"], @2);
    uncheckedAssertEqualObjects([managed.floatObj minOfProperty:@"self"], @2.2f);
    uncheckedAssertEqualObjects([managed.doubleObj minOfProperty:@"self"], @2.2);
    uncheckedAssertEqualObjects([managed.dateObj minOfProperty:@"self"], date(1));
    uncheckedAssertEqualObjects([managed.decimalObj minOfProperty:@"self"], decimal128(1));
    uncheckedAssertEqualObjects([managed.anyIntObj minOfProperty:@"self"], @2);
    uncheckedAssertEqualObjects([managed.anyFloatObj minOfProperty:@"self"], @2.2f);
    uncheckedAssertEqualObjects([managed.anyDoubleObj minOfProperty:@"self"], @2.2);
    uncheckedAssertEqualObjects([managed.anyDateObj minOfProperty:@"self"], date(1));
    uncheckedAssertEqualObjects([managed.anyDecimalObj minOfProperty:@"self"], decimal128(1));
    uncheckedAssertEqualObjects([optManaged.intObj minOfProperty:@"self"], @2);
    uncheckedAssertEqualObjects([optManaged.floatObj minOfProperty:@"self"], @2.2f);
    uncheckedAssertEqualObjects([optManaged.doubleObj minOfProperty:@"self"], @2.2);
    uncheckedAssertEqualObjects([optManaged.dateObj minOfProperty:@"self"], date(1));
    uncheckedAssertEqualObjects([optManaged.decimalObj minOfProperty:@"self"], decimal128(1));
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

    uncheckedAssertNil([unmanaged.intObj maxOfProperty:@"self"]);
    uncheckedAssertNil([unmanaged.floatObj maxOfProperty:@"self"]);
    uncheckedAssertNil([unmanaged.doubleObj maxOfProperty:@"self"]);
    uncheckedAssertNil([unmanaged.dateObj maxOfProperty:@"self"]);
    uncheckedAssertNil([unmanaged.decimalObj maxOfProperty:@"self"]);
    uncheckedAssertNil([unmanaged.anyFloatObj maxOfProperty:@"self"]);
    uncheckedAssertNil([unmanaged.anyDoubleObj maxOfProperty:@"self"]);
    uncheckedAssertNil([unmanaged.anyDateObj maxOfProperty:@"self"]);
    uncheckedAssertNil([unmanaged.anyDecimalObj maxOfProperty:@"self"]);
    uncheckedAssertNil([optUnmanaged.intObj maxOfProperty:@"self"]);
    uncheckedAssertNil([optUnmanaged.floatObj maxOfProperty:@"self"]);
    uncheckedAssertNil([optUnmanaged.doubleObj maxOfProperty:@"self"]);
    uncheckedAssertNil([optUnmanaged.dateObj maxOfProperty:@"self"]);
    uncheckedAssertNil([optUnmanaged.decimalObj maxOfProperty:@"self"]);
    uncheckedAssertNil([managed.intObj maxOfProperty:@"self"]);
    uncheckedAssertNil([managed.floatObj maxOfProperty:@"self"]);
    uncheckedAssertNil([managed.doubleObj maxOfProperty:@"self"]);
    uncheckedAssertNil([managed.dateObj maxOfProperty:@"self"]);
    uncheckedAssertNil([managed.decimalObj maxOfProperty:@"self"]);
    uncheckedAssertNil([managed.anyIntObj maxOfProperty:@"self"]);
    uncheckedAssertNil([managed.anyFloatObj maxOfProperty:@"self"]);
    uncheckedAssertNil([managed.anyDoubleObj maxOfProperty:@"self"]);
    uncheckedAssertNil([managed.anyDateObj maxOfProperty:@"self"]);
    uncheckedAssertNil([managed.anyDecimalObj maxOfProperty:@"self"]);
    uncheckedAssertNil([optManaged.intObj maxOfProperty:@"self"]);
    uncheckedAssertNil([optManaged.floatObj maxOfProperty:@"self"]);
    uncheckedAssertNil([optManaged.doubleObj maxOfProperty:@"self"]);
    uncheckedAssertNil([optManaged.dateObj maxOfProperty:@"self"]);
    uncheckedAssertNil([optManaged.decimalObj maxOfProperty:@"self"]);

    [self addObjects];

    uncheckedAssertEqualObjects([unmanaged.intObj maxOfProperty:@"self"], @3);
    uncheckedAssertEqualObjects([unmanaged.floatObj maxOfProperty:@"self"], @3.3f);
    uncheckedAssertEqualObjects([unmanaged.doubleObj maxOfProperty:@"self"], @3.3);
    uncheckedAssertEqualObjects([unmanaged.dateObj maxOfProperty:@"self"], date(2));
    uncheckedAssertEqualObjects([unmanaged.decimalObj maxOfProperty:@"self"], decimal128(2));
    uncheckedAssertEqualObjects([unmanaged.anyFloatObj maxOfProperty:@"self"], @3.3f);
    uncheckedAssertEqualObjects([unmanaged.anyDoubleObj maxOfProperty:@"self"], @3.3);
    uncheckedAssertEqualObjects([unmanaged.anyDateObj maxOfProperty:@"self"], date(2));
    uncheckedAssertEqualObjects([unmanaged.anyDecimalObj maxOfProperty:@"self"], decimal128(2));
    uncheckedAssertEqualObjects([optUnmanaged.intObj maxOfProperty:@"self"], @3);
    uncheckedAssertEqualObjects([optUnmanaged.floatObj maxOfProperty:@"self"], @3.3f);
    uncheckedAssertEqualObjects([optUnmanaged.doubleObj maxOfProperty:@"self"], @3.3);
    uncheckedAssertEqualObjects([optUnmanaged.dateObj maxOfProperty:@"self"], date(2));
    uncheckedAssertEqualObjects([optUnmanaged.decimalObj maxOfProperty:@"self"], decimal128(2));

    uncheckedAssertEqualObjects([managed.intObj maxOfProperty:@"self"], @3);
    uncheckedAssertEqualObjects([managed.floatObj maxOfProperty:@"self"], @3.3f);
    uncheckedAssertEqualObjects([managed.doubleObj maxOfProperty:@"self"], @3.3);
    uncheckedAssertEqualObjects([managed.dateObj maxOfProperty:@"self"], date(2));
    uncheckedAssertEqualObjects([managed.decimalObj maxOfProperty:@"self"], decimal128(2));
    uncheckedAssertEqualObjects([managed.anyIntObj maxOfProperty:@"self"], @3);
    uncheckedAssertEqualObjects([managed.anyFloatObj maxOfProperty:@"self"], @3.3f);
    uncheckedAssertEqualObjects([managed.anyDoubleObj maxOfProperty:@"self"], @3.3);
    uncheckedAssertEqualObjects([managed.anyDateObj maxOfProperty:@"self"], date(2));
    uncheckedAssertEqualObjects([managed.anyDecimalObj maxOfProperty:@"self"], decimal128(2));
    uncheckedAssertEqualObjects([optManaged.intObj maxOfProperty:@"self"], @3);
    uncheckedAssertEqualObjects([optManaged.floatObj maxOfProperty:@"self"], @3.3f);
    uncheckedAssertEqualObjects([optManaged.doubleObj maxOfProperty:@"self"], @3.3);
    uncheckedAssertEqualObjects([optManaged.dateObj maxOfProperty:@"self"], date(2));
    uncheckedAssertEqualObjects([optManaged.decimalObj maxOfProperty:@"self"], decimal128(2));
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

    uncheckedAssertEqualObjects([unmanaged.intObj sumOfProperty:@"self"], @0);
    uncheckedAssertEqualObjects([unmanaged.floatObj sumOfProperty:@"self"], @0);
    uncheckedAssertEqualObjects([unmanaged.doubleObj sumOfProperty:@"self"], @0);
    uncheckedAssertEqualObjects([unmanaged.decimalObj sumOfProperty:@"self"], @0);
    uncheckedAssertEqualObjects([unmanaged.anyIntObj sumOfProperty:@"self"], @0);
    uncheckedAssertEqualObjects([unmanaged.anyFloatObj sumOfProperty:@"self"], @0);
    uncheckedAssertEqualObjects([unmanaged.anyDoubleObj sumOfProperty:@"self"], @0);
    uncheckedAssertEqualObjects([unmanaged.anyDecimalObj sumOfProperty:@"self"], @0);
    uncheckedAssertEqualObjects([optUnmanaged.intObj sumOfProperty:@"self"], @0);
    uncheckedAssertEqualObjects([optUnmanaged.floatObj sumOfProperty:@"self"], @0);
    uncheckedAssertEqualObjects([optUnmanaged.doubleObj sumOfProperty:@"self"], @0);
    uncheckedAssertEqualObjects([optUnmanaged.decimalObj sumOfProperty:@"self"], @0);
    uncheckedAssertEqualObjects([managed.intObj sumOfProperty:@"self"], @0);
    uncheckedAssertEqualObjects([managed.floatObj sumOfProperty:@"self"], @0);
    uncheckedAssertEqualObjects([managed.doubleObj sumOfProperty:@"self"], @0);
    uncheckedAssertEqualObjects([managed.decimalObj sumOfProperty:@"self"], @0);
    uncheckedAssertEqualObjects([managed.anyIntObj sumOfProperty:@"self"], @0);
    uncheckedAssertEqualObjects([managed.anyFloatObj sumOfProperty:@"self"], @0);
    uncheckedAssertEqualObjects([managed.anyDoubleObj sumOfProperty:@"self"], @0);
    uncheckedAssertEqualObjects([managed.anyDecimalObj sumOfProperty:@"self"], @0);
    uncheckedAssertEqualObjects([optManaged.intObj sumOfProperty:@"self"], @0);
    uncheckedAssertEqualObjects([optManaged.floatObj sumOfProperty:@"self"], @0);
    uncheckedAssertEqualObjects([optManaged.doubleObj sumOfProperty:@"self"], @0);
    uncheckedAssertEqualObjects([optManaged.decimalObj sumOfProperty:@"self"], @0);

    [self addObjects];

    XCTAssertEqualWithAccuracy([unmanaged.intObj sumOfProperty:@"self"].doubleValue, sum(@[@2, @3]), .001);
    XCTAssertEqualWithAccuracy([unmanaged.floatObj sumOfProperty:@"self"].doubleValue, sum(@[@2.2f, @3.3f]), .001);
    XCTAssertEqualWithAccuracy([unmanaged.doubleObj sumOfProperty:@"self"].doubleValue, sum(@[@2.2, @3.3]), .001);
    XCTAssertEqualWithAccuracy([unmanaged.decimalObj sumOfProperty:@"self"].doubleValue, sum(@[decimal128(1), decimal128(2)]), .001);
    XCTAssertEqualWithAccuracy([unmanaged.anyIntObj sumOfProperty:@"self"].doubleValue, sum(@[@2, @3]), .001);
    XCTAssertEqualWithAccuracy([unmanaged.anyFloatObj sumOfProperty:@"self"].doubleValue, sum(@[@2.2f, @3.3f]), .001);
    XCTAssertEqualWithAccuracy([unmanaged.anyDoubleObj sumOfProperty:@"self"].doubleValue, sum(@[@2.2, @3.3]), .001);
    XCTAssertEqualWithAccuracy([unmanaged.anyDecimalObj sumOfProperty:@"self"].doubleValue, sum(@[decimal128(1), decimal128(2)]), .001);
    XCTAssertEqualWithAccuracy([optUnmanaged.intObj sumOfProperty:@"self"].doubleValue, sum(@[NSNull.null, @2, @3]), .001);
    XCTAssertEqualWithAccuracy([optUnmanaged.floatObj sumOfProperty:@"self"].doubleValue, sum(@[NSNull.null, @2.2f, @3.3f]), .001);
    XCTAssertEqualWithAccuracy([optUnmanaged.doubleObj sumOfProperty:@"self"].doubleValue, sum(@[NSNull.null, @2.2, @3.3]), .001);
    XCTAssertEqualWithAccuracy([optUnmanaged.decimalObj sumOfProperty:@"self"].doubleValue, sum(@[NSNull.null, decimal128(1), decimal128(2)]), .001);
    XCTAssertEqualWithAccuracy([managed.intObj sumOfProperty:@"self"].doubleValue, sum(@[@2, @3]), .001);
    XCTAssertEqualWithAccuracy([managed.floatObj sumOfProperty:@"self"].doubleValue, sum(@[@2.2f, @3.3f]), .001);
    XCTAssertEqualWithAccuracy([managed.doubleObj sumOfProperty:@"self"].doubleValue, sum(@[@2.2, @3.3]), .001);
    XCTAssertEqualWithAccuracy([managed.decimalObj sumOfProperty:@"self"].doubleValue, sum(@[decimal128(1), decimal128(2)]), .001);
    XCTAssertEqualWithAccuracy([managed.anyIntObj sumOfProperty:@"self"].doubleValue, sum(@[@2, @3]), .001);
    XCTAssertEqualWithAccuracy([managed.anyFloatObj sumOfProperty:@"self"].doubleValue, sum(@[@2.2f, @3.3f]), .001);
    XCTAssertEqualWithAccuracy([managed.anyDoubleObj sumOfProperty:@"self"].doubleValue, sum(@[@2.2, @3.3]), .001);
    XCTAssertEqualWithAccuracy([managed.anyDecimalObj sumOfProperty:@"self"].doubleValue, sum(@[decimal128(1), decimal128(2)]), .001);
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

    uncheckedAssertNil([unmanaged.intObj averageOfProperty:@"self"]);
    uncheckedAssertNil([unmanaged.floatObj averageOfProperty:@"self"]);
    uncheckedAssertNil([unmanaged.doubleObj averageOfProperty:@"self"]);
    uncheckedAssertNil([unmanaged.decimalObj averageOfProperty:@"self"]);
    uncheckedAssertNil([unmanaged.anyIntObj averageOfProperty:@"self"]);
    uncheckedAssertNil([unmanaged.anyFloatObj averageOfProperty:@"self"]);
    uncheckedAssertNil([unmanaged.anyDoubleObj averageOfProperty:@"self"]);
    uncheckedAssertNil([unmanaged.anyDecimalObj averageOfProperty:@"self"]);
    uncheckedAssertNil([optUnmanaged.intObj averageOfProperty:@"self"]);
    uncheckedAssertNil([optUnmanaged.floatObj averageOfProperty:@"self"]);
    uncheckedAssertNil([optUnmanaged.doubleObj averageOfProperty:@"self"]);
    uncheckedAssertNil([optUnmanaged.decimalObj averageOfProperty:@"self"]);
    uncheckedAssertNil([managed.intObj averageOfProperty:@"self"]);
    uncheckedAssertNil([managed.floatObj averageOfProperty:@"self"]);
    uncheckedAssertNil([managed.doubleObj averageOfProperty:@"self"]);
    uncheckedAssertNil([managed.decimalObj averageOfProperty:@"self"]);
    uncheckedAssertNil([managed.anyIntObj averageOfProperty:@"self"]);
    uncheckedAssertNil([managed.anyFloatObj averageOfProperty:@"self"]);
    uncheckedAssertNil([managed.anyDoubleObj averageOfProperty:@"self"]);
    uncheckedAssertNil([managed.anyDecimalObj averageOfProperty:@"self"]);
    uncheckedAssertNil([optManaged.intObj averageOfProperty:@"self"]);
    uncheckedAssertNil([optManaged.floatObj averageOfProperty:@"self"]);
    uncheckedAssertNil([optManaged.doubleObj averageOfProperty:@"self"]);
    uncheckedAssertNil([optManaged.decimalObj averageOfProperty:@"self"]);

    [self addObjects];

    XCTAssertEqualWithAccuracy([unmanaged.intObj averageOfProperty:@"self"].doubleValue, average(@[@2, @3]), .001);
    XCTAssertEqualWithAccuracy([unmanaged.floatObj averageOfProperty:@"self"].doubleValue, average(@[@2.2f, @3.3f]), .001);
    XCTAssertEqualWithAccuracy([unmanaged.doubleObj averageOfProperty:@"self"].doubleValue, average(@[@2.2, @3.3]), .001);
    XCTAssertEqualWithAccuracy([unmanaged.decimalObj averageOfProperty:@"self"].doubleValue, average(@[decimal128(1), decimal128(2)]), .001);
    XCTAssertEqualWithAccuracy([unmanaged.anyIntObj averageOfProperty:@"self"].doubleValue, average(@[@2, @3]), .001);
    XCTAssertEqualWithAccuracy([unmanaged.anyFloatObj averageOfProperty:@"self"].doubleValue, average(@[@2.2f, @3.3f]), .001);
    XCTAssertEqualWithAccuracy([unmanaged.anyDoubleObj averageOfProperty:@"self"].doubleValue, average(@[@2.2, @3.3]), .001);
    XCTAssertEqualWithAccuracy([unmanaged.anyDecimalObj averageOfProperty:@"self"].doubleValue, average(@[decimal128(1), decimal128(2)]), .001);
    XCTAssertEqualWithAccuracy([optUnmanaged.intObj averageOfProperty:@"self"].doubleValue, average(@[NSNull.null, @2, @3]), .001);
    XCTAssertEqualWithAccuracy([optUnmanaged.floatObj averageOfProperty:@"self"].doubleValue, average(@[NSNull.null, @2.2f, @3.3f]), .001);
    XCTAssertEqualWithAccuracy([optUnmanaged.doubleObj averageOfProperty:@"self"].doubleValue, average(@[NSNull.null, @2.2, @3.3]), .001);
    XCTAssertEqualWithAccuracy([optUnmanaged.decimalObj averageOfProperty:@"self"].doubleValue, average(@[NSNull.null, decimal128(1), decimal128(2)]), .001);
    XCTAssertEqualWithAccuracy([managed.intObj averageOfProperty:@"self"].doubleValue, average(@[@2, @3]), .001);
    XCTAssertEqualWithAccuracy([managed.floatObj averageOfProperty:@"self"].doubleValue, average(@[@2.2f, @3.3f]), .001);
    XCTAssertEqualWithAccuracy([managed.doubleObj averageOfProperty:@"self"].doubleValue, average(@[@2.2, @3.3]), .001);
    XCTAssertEqualWithAccuracy([managed.decimalObj averageOfProperty:@"self"].doubleValue, average(@[decimal128(1), decimal128(2)]), .001);
    XCTAssertEqualWithAccuracy([managed.anyIntObj averageOfProperty:@"self"].doubleValue, average(@[@2, @3]), .001);
    XCTAssertEqualWithAccuracy([managed.anyFloatObj averageOfProperty:@"self"].doubleValue, average(@[@2.2f, @3.3f]), .001);
    XCTAssertEqualWithAccuracy([managed.anyDoubleObj averageOfProperty:@"self"].doubleValue, average(@[@2.2, @3.3]), .001);
    XCTAssertEqualWithAccuracy([managed.anyDecimalObj averageOfProperty:@"self"].doubleValue, average(@[decimal128(1), decimal128(2)]), .001);
    XCTAssertEqualWithAccuracy([optManaged.intObj averageOfProperty:@"self"].doubleValue, average(@[NSNull.null, @2, @3]), .001);
    XCTAssertEqualWithAccuracy([optManaged.floatObj averageOfProperty:@"self"].doubleValue, average(@[NSNull.null, @2.2f, @3.3f]), .001);
    XCTAssertEqualWithAccuracy([optManaged.doubleObj averageOfProperty:@"self"].doubleValue, average(@[NSNull.null, @2.2, @3.3]), .001);
    XCTAssertEqualWithAccuracy([optManaged.decimalObj averageOfProperty:@"self"].doubleValue, average(@[NSNull.null, decimal128(1), decimal128(2)]), .001);
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
    ^{ 
     NSArray *values = @[@NO, @YES]; 
     for (id value in unmanaged.boolObj) { 
     uncheckedAssertTrue([[NSSet setWithArray:values] containsObject:value]); 
     } 
     }(); 
    
    ^{ 
     NSArray *values = @[@2, @3]; 
     for (id value in unmanaged.intObj) { 
     uncheckedAssertTrue([[NSSet setWithArray:values] containsObject:value]); 
     } 
     }(); 
    
    ^{ 
     NSArray *values = @[@2.2f, @3.3f]; 
     for (id value in unmanaged.floatObj) { 
     uncheckedAssertTrue([[NSSet setWithArray:values] containsObject:value]); 
     } 
     }(); 
    
    ^{ 
     NSArray *values = @[@2.2, @3.3]; 
     for (id value in unmanaged.doubleObj) { 
     uncheckedAssertTrue([[NSSet setWithArray:values] containsObject:value]); 
     } 
     }(); 
    
    ^{ 
     NSArray *values = @[@"a", @"bc"]; 
     for (id value in unmanaged.stringObj) { 
     uncheckedAssertTrue([[NSSet setWithArray:values] containsObject:value]); 
     } 
     }(); 
    
    ^{ 
     NSArray *values = @[data(1), data(2)]; 
     for (id value in unmanaged.dataObj) { 
     uncheckedAssertTrue([[NSSet setWithArray:values] containsObject:value]); 
     } 
     }(); 
    
    ^{ 
     NSArray *values = @[date(1), date(2)]; 
     for (id value in unmanaged.dateObj) { 
     uncheckedAssertTrue([[NSSet setWithArray:values] containsObject:value]); 
     } 
     }(); 
    
    ^{ 
     NSArray *values = @[decimal128(1), decimal128(2)]; 
     for (id value in unmanaged.decimalObj) { 
     uncheckedAssertTrue([[NSSet setWithArray:values] containsObject:value]); 
     } 
     }(); 
    
    ^{ 
     NSArray *values = @[objectId(1), objectId(2)]; 
     for (id value in unmanaged.objectIdObj) { 
     uncheckedAssertTrue([[NSSet setWithArray:values] containsObject:value]); 
     } 
     }(); 
    
    ^{ 
     NSArray *values = @[uuid(@"00000000-0000-0000-0000-000000000000"), uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")]; 
     for (id value in unmanaged.uuidObj) { 
     uncheckedAssertTrue([[NSSet setWithArray:values] containsObject:value]); 
     } 
     }(); 
    
    ^{ 
     NSArray *values = @[@NO, @YES]; 
     for (id value in unmanaged.anyBoolObj) { 
     uncheckedAssertTrue([[NSSet setWithArray:values] containsObject:value]); 
     } 
     }(); 
    
    ^{ 
     NSArray *values = @[@2, @3]; 
     for (id value in unmanaged.anyIntObj) { 
     uncheckedAssertTrue([[NSSet setWithArray:values] containsObject:value]); 
     } 
     }(); 
    
    ^{ 
     NSArray *values = @[@2.2f, @3.3f]; 
     for (id value in unmanaged.anyFloatObj) { 
     uncheckedAssertTrue([[NSSet setWithArray:values] containsObject:value]); 
     } 
     }(); 
    
    ^{ 
     NSArray *values = @[@2.2, @3.3]; 
     for (id value in unmanaged.anyDoubleObj) { 
     uncheckedAssertTrue([[NSSet setWithArray:values] containsObject:value]); 
     } 
     }(); 
    
    ^{ 
     NSArray *values = @[@"a", @"b"]; 
     for (id value in unmanaged.anyStringObj) { 
     uncheckedAssertTrue([[NSSet setWithArray:values] containsObject:value]); 
     } 
     }(); 
    
    ^{ 
     NSArray *values = @[data(1), data(2)]; 
     for (id value in unmanaged.anyDataObj) { 
     uncheckedAssertTrue([[NSSet setWithArray:values] containsObject:value]); 
     } 
     }(); 
    
    ^{ 
     NSArray *values = @[date(1), date(2)]; 
     for (id value in unmanaged.anyDateObj) { 
     uncheckedAssertTrue([[NSSet setWithArray:values] containsObject:value]); 
     } 
     }(); 
    
    ^{ 
     NSArray *values = @[decimal128(1), decimal128(2)]; 
     for (id value in unmanaged.anyDecimalObj) { 
     uncheckedAssertTrue([[NSSet setWithArray:values] containsObject:value]); 
     } 
     }(); 
    
    ^{ 
     NSArray *values = @[objectId(1), objectId(2)]; 
     for (id value in unmanaged.anyObjectIdObj) { 
     uncheckedAssertTrue([[NSSet setWithArray:values] containsObject:value]); 
     } 
     }(); 
    
    ^{ 
     NSArray *values = @[uuid(@"00000000-0000-0000-0000-000000000000"), uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")]; 
     for (id value in unmanaged.anyUUIDObj) { 
     uncheckedAssertTrue([[NSSet setWithArray:values] containsObject:value]); 
     } 
     }(); 
    
    ^{ 
     NSArray *values = @[NSNull.null, @NO, @YES]; 
     for (id value in optUnmanaged.boolObj) { 
     uncheckedAssertTrue([[NSSet setWithArray:values] containsObject:value]); 
     } 
     }(); 
    
    ^{ 
     NSArray *values = @[NSNull.null, @2, @3]; 
     for (id value in optUnmanaged.intObj) { 
     uncheckedAssertTrue([[NSSet setWithArray:values] containsObject:value]); 
     } 
     }(); 
    
    ^{ 
     NSArray *values = @[NSNull.null, @2.2f, @3.3f]; 
     for (id value in optUnmanaged.floatObj) { 
     uncheckedAssertTrue([[NSSet setWithArray:values] containsObject:value]); 
     } 
     }(); 
    
    ^{ 
     NSArray *values = @[NSNull.null, @2.2, @3.3]; 
     for (id value in optUnmanaged.doubleObj) { 
     uncheckedAssertTrue([[NSSet setWithArray:values] containsObject:value]); 
     } 
     }(); 
    
    ^{ 
     NSArray *values = @[NSNull.null, @"a", @"bc"]; 
     for (id value in optUnmanaged.stringObj) { 
     uncheckedAssertTrue([[NSSet setWithArray:values] containsObject:value]); 
     } 
     }(); 
    
    ^{ 
     NSArray *values = @[NSNull.null, data(1), data(2)]; 
     for (id value in optUnmanaged.dataObj) { 
     uncheckedAssertTrue([[NSSet setWithArray:values] containsObject:value]); 
     } 
     }(); 
    
    ^{ 
     NSArray *values = @[NSNull.null, date(1), date(2)]; 
     for (id value in optUnmanaged.dateObj) { 
     uncheckedAssertTrue([[NSSet setWithArray:values] containsObject:value]); 
     } 
     }(); 
    
    ^{ 
     NSArray *values = @[NSNull.null, decimal128(1), decimal128(2)]; 
     for (id value in optUnmanaged.decimalObj) { 
     uncheckedAssertTrue([[NSSet setWithArray:values] containsObject:value]); 
     } 
     }(); 
    
    ^{ 
     NSArray *values = @[NSNull.null, objectId(1), objectId(2)]; 
     for (id value in optUnmanaged.objectIdObj) { 
     uncheckedAssertTrue([[NSSet setWithArray:values] containsObject:value]); 
     } 
     }(); 
    
    ^{ 
     NSArray *values = @[NSNull.null, uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"), uuid(@"00000000-0000-0000-0000-000000000000")]; 
     for (id value in optUnmanaged.uuidObj) { 
     uncheckedAssertTrue([[NSSet setWithArray:values] containsObject:value]); 
     } 
     }(); 
    
    ^{ 
     NSArray *values = @[@NO, @YES]; 
     for (id value in managed.boolObj) { 
     uncheckedAssertTrue([[NSSet setWithArray:values] containsObject:value]); 
     } 
     }(); 
    
    ^{ 
     NSArray *values = @[@2, @3]; 
     for (id value in managed.intObj) { 
     uncheckedAssertTrue([[NSSet setWithArray:values] containsObject:value]); 
     } 
     }(); 
    
    ^{ 
     NSArray *values = @[@2.2f, @3.3f]; 
     for (id value in managed.floatObj) { 
     uncheckedAssertTrue([[NSSet setWithArray:values] containsObject:value]); 
     } 
     }(); 
    
    ^{ 
     NSArray *values = @[@2.2, @3.3]; 
     for (id value in managed.doubleObj) { 
     uncheckedAssertTrue([[NSSet setWithArray:values] containsObject:value]); 
     } 
     }(); 
    
    ^{ 
     NSArray *values = @[@"a", @"bc"]; 
     for (id value in managed.stringObj) { 
     uncheckedAssertTrue([[NSSet setWithArray:values] containsObject:value]); 
     } 
     }(); 
    
    ^{ 
     NSArray *values = @[data(1), data(2)]; 
     for (id value in managed.dataObj) { 
     uncheckedAssertTrue([[NSSet setWithArray:values] containsObject:value]); 
     } 
     }(); 
    
    ^{ 
     NSArray *values = @[date(1), date(2)]; 
     for (id value in managed.dateObj) { 
     uncheckedAssertTrue([[NSSet setWithArray:values] containsObject:value]); 
     } 
     }(); 
    
    ^{ 
     NSArray *values = @[decimal128(1), decimal128(2)]; 
     for (id value in managed.decimalObj) { 
     uncheckedAssertTrue([[NSSet setWithArray:values] containsObject:value]); 
     } 
     }(); 
    
    ^{ 
     NSArray *values = @[objectId(1), objectId(2)]; 
     for (id value in managed.objectIdObj) { 
     uncheckedAssertTrue([[NSSet setWithArray:values] containsObject:value]); 
     } 
     }(); 
    
    ^{ 
     NSArray *values = @[uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"), uuid(@"00000000-0000-0000-0000-000000000000")]; 
     for (id value in managed.uuidObj) { 
     uncheckedAssertTrue([[NSSet setWithArray:values] containsObject:value]); 
     } 
     }(); 
    
    ^{ 
     NSArray *values = @[@NO, @YES]; 
     for (id value in managed.anyBoolObj) { 
     uncheckedAssertTrue([[NSSet setWithArray:values] containsObject:value]); 
     } 
     }(); 
    
    ^{ 
     NSArray *values = @[@2, @3]; 
     for (id value in managed.anyIntObj) { 
     uncheckedAssertTrue([[NSSet setWithArray:values] containsObject:value]); 
     } 
     }(); 
    
    ^{ 
     NSArray *values = @[@2.2f, @3.3f]; 
     for (id value in managed.anyFloatObj) { 
     uncheckedAssertTrue([[NSSet setWithArray:values] containsObject:value]); 
     } 
     }(); 
    
    ^{ 
     NSArray *values = @[@2.2, @3.3]; 
     for (id value in managed.anyDoubleObj) { 
     uncheckedAssertTrue([[NSSet setWithArray:values] containsObject:value]); 
     } 
     }(); 
    
    ^{ 
     NSArray *values = @[@"a", @"b"]; 
     for (id value in managed.anyStringObj) { 
     uncheckedAssertTrue([[NSSet setWithArray:values] containsObject:value]); 
     } 
     }(); 
    
    ^{ 
     NSArray *values = @[data(1), data(2)]; 
     for (id value in managed.anyDataObj) { 
     uncheckedAssertTrue([[NSSet setWithArray:values] containsObject:value]); 
     } 
     }(); 
    
    ^{ 
     NSArray *values = @[date(1), date(2)]; 
     for (id value in managed.anyDateObj) { 
     uncheckedAssertTrue([[NSSet setWithArray:values] containsObject:value]); 
     } 
     }(); 
    
    ^{ 
     NSArray *values = @[decimal128(1), decimal128(2)]; 
     for (id value in managed.anyDecimalObj) { 
     uncheckedAssertTrue([[NSSet setWithArray:values] containsObject:value]); 
     } 
     }(); 
    
    ^{ 
     NSArray *values = @[objectId(1), objectId(2)]; 
     for (id value in managed.anyObjectIdObj) { 
     uncheckedAssertTrue([[NSSet setWithArray:values] containsObject:value]); 
     } 
     }(); 
    
    ^{ 
     NSArray *values = @[uuid(@"00000000-0000-0000-0000-000000000000"), uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")]; 
     for (id value in managed.anyUUIDObj) { 
     uncheckedAssertTrue([[NSSet setWithArray:values] containsObject:value]); 
     } 
     }(); 
    
    ^{ 
     NSArray *values = @[NSNull.null, @NO, @YES]; 
     for (id value in optManaged.boolObj) { 
     uncheckedAssertTrue([[NSSet setWithArray:values] containsObject:value]); 
     } 
     }(); 
    
    ^{ 
     NSArray *values = @[NSNull.null, @2, @3]; 
     for (id value in optManaged.intObj) { 
     uncheckedAssertTrue([[NSSet setWithArray:values] containsObject:value]); 
     } 
     }(); 
    
    ^{ 
     NSArray *values = @[NSNull.null, @2.2f, @3.3f]; 
     for (id value in optManaged.floatObj) { 
     uncheckedAssertTrue([[NSSet setWithArray:values] containsObject:value]); 
     } 
     }(); 
    
    ^{ 
     NSArray *values = @[NSNull.null, @2.2, @3.3]; 
     for (id value in optManaged.doubleObj) { 
     uncheckedAssertTrue([[NSSet setWithArray:values] containsObject:value]); 
     } 
     }(); 
    
    ^{ 
     NSArray *values = @[NSNull.null, @"a", @"bc"]; 
     for (id value in optManaged.stringObj) { 
     uncheckedAssertTrue([[NSSet setWithArray:values] containsObject:value]); 
     } 
     }(); 
    
    ^{ 
     NSArray *values = @[NSNull.null, data(1), data(2)]; 
     for (id value in optManaged.dataObj) { 
     uncheckedAssertTrue([[NSSet setWithArray:values] containsObject:value]); 
     } 
     }(); 
    
    ^{ 
     NSArray *values = @[NSNull.null, date(1), date(2)]; 
     for (id value in optManaged.dateObj) { 
     uncheckedAssertTrue([[NSSet setWithArray:values] containsObject:value]); 
     } 
     }(); 
    
    ^{ 
     NSArray *values = @[NSNull.null, decimal128(1), decimal128(2)]; 
     for (id value in optManaged.decimalObj) { 
     uncheckedAssertTrue([[NSSet setWithArray:values] containsObject:value]); 
     } 
     }(); 
    
    ^{ 
     NSArray *values = @[NSNull.null, objectId(1), objectId(2)]; 
     for (id value in optManaged.objectIdObj) { 
     uncheckedAssertTrue([[NSSet setWithArray:values] containsObject:value]); 
     } 
     }(); 
    
    ^{ 
     NSArray *values = @[NSNull.null, uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"), uuid(@"00000000-0000-0000-0000-000000000000")]; 
     for (id value in optManaged.uuidObj) { 
     uncheckedAssertTrue([[NSSet setWithArray:values] containsObject:value]); 
     } 
     }(); 
    
}

- (void)testValueForKeySelf {
    for (RLMSet *set in allSets) {
        uncheckedAssertEqualObjects([[set valueForKey:@"self"] allObjects], @[]);
    }

    [self addObjects];

    uncheckedAssertEqualObjects([NSSet setWithArray:[[unmanaged.boolObj valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[@NO, @YES]]));
    uncheckedAssertEqualObjects([NSSet setWithArray:[[unmanaged.intObj valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[@2, @3]]));
    uncheckedAssertEqualObjects([NSSet setWithArray:[[unmanaged.floatObj valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[@2.2f, @3.3f]]));
    uncheckedAssertEqualObjects([NSSet setWithArray:[[unmanaged.doubleObj valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[@2.2, @3.3]]));
    uncheckedAssertEqualObjects([NSSet setWithArray:[[unmanaged.stringObj valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[@"a", @"bc"]]));
    uncheckedAssertEqualObjects([NSSet setWithArray:[[unmanaged.dataObj valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[data(1), data(2)]]));
    uncheckedAssertEqualObjects([NSSet setWithArray:[[unmanaged.dateObj valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[date(1), date(2)]]));
    uncheckedAssertEqualObjects([NSSet setWithArray:[[unmanaged.decimalObj valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[decimal128(1), decimal128(2)]]));
    uncheckedAssertEqualObjects([NSSet setWithArray:[[unmanaged.objectIdObj valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[objectId(1), objectId(2)]]));
    uncheckedAssertEqualObjects([NSSet setWithArray:[[unmanaged.uuidObj valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[uuid(@"00000000-0000-0000-0000-000000000000"), uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")]]));
    uncheckedAssertEqualObjects([NSSet setWithArray:[[unmanaged.anyBoolObj valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[@NO, @YES]]));
    uncheckedAssertEqualObjects([NSSet setWithArray:[[unmanaged.anyIntObj valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[@2, @3]]));
    uncheckedAssertEqualObjects([NSSet setWithArray:[[unmanaged.anyFloatObj valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[@2.2f, @3.3f]]));
    uncheckedAssertEqualObjects([NSSet setWithArray:[[unmanaged.anyDoubleObj valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[@2.2, @3.3]]));
    uncheckedAssertEqualObjects([NSSet setWithArray:[[unmanaged.anyStringObj valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[@"a", @"b"]]));
    uncheckedAssertEqualObjects([NSSet setWithArray:[[unmanaged.anyDataObj valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[data(1), data(2)]]));
    uncheckedAssertEqualObjects([NSSet setWithArray:[[unmanaged.anyDateObj valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[date(1), date(2)]]));
    uncheckedAssertEqualObjects([NSSet setWithArray:[[unmanaged.anyDecimalObj valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[decimal128(1), decimal128(2)]]));
    uncheckedAssertEqualObjects([NSSet setWithArray:[[unmanaged.anyObjectIdObj valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[objectId(1), objectId(2)]]));
    uncheckedAssertEqualObjects([NSSet setWithArray:[[unmanaged.anyUUIDObj valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[uuid(@"00000000-0000-0000-0000-000000000000"), uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")]]));
    uncheckedAssertEqualObjects([NSSet setWithArray:[[optUnmanaged.boolObj valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[NSNull.null, @NO, @YES]]));
    uncheckedAssertEqualObjects([NSSet setWithArray:[[optUnmanaged.intObj valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[NSNull.null, @2, @3]]));
    uncheckedAssertEqualObjects([NSSet setWithArray:[[optUnmanaged.floatObj valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[NSNull.null, @2.2f, @3.3f]]));
    uncheckedAssertEqualObjects([NSSet setWithArray:[[optUnmanaged.doubleObj valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[NSNull.null, @2.2, @3.3]]));
    uncheckedAssertEqualObjects([NSSet setWithArray:[[optUnmanaged.stringObj valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[NSNull.null, @"a", @"bc"]]));
    uncheckedAssertEqualObjects([NSSet setWithArray:[[optUnmanaged.dataObj valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[NSNull.null, data(1), data(2)]]));
    uncheckedAssertEqualObjects([NSSet setWithArray:[[optUnmanaged.dateObj valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[NSNull.null, date(1), date(2)]]));
    uncheckedAssertEqualObjects([NSSet setWithArray:[[optUnmanaged.decimalObj valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[NSNull.null, decimal128(1), decimal128(2)]]));
    uncheckedAssertEqualObjects([NSSet setWithArray:[[optUnmanaged.objectIdObj valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[NSNull.null, objectId(1), objectId(2)]]));
    uncheckedAssertEqualObjects([NSSet setWithArray:[[optUnmanaged.uuidObj valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[NSNull.null, uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"), uuid(@"00000000-0000-0000-0000-000000000000")]]));
    uncheckedAssertEqualObjects([NSSet setWithArray:[[managed.boolObj valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[@NO, @YES]]));
    uncheckedAssertEqualObjects([NSSet setWithArray:[[managed.intObj valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[@2, @3]]));
    uncheckedAssertEqualObjects([NSSet setWithArray:[[managed.floatObj valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[@2.2f, @3.3f]]));
    uncheckedAssertEqualObjects([NSSet setWithArray:[[managed.doubleObj valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[@2.2, @3.3]]));
    uncheckedAssertEqualObjects([NSSet setWithArray:[[managed.stringObj valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[@"a", @"bc"]]));
    uncheckedAssertEqualObjects([NSSet setWithArray:[[managed.dataObj valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[data(1), data(2)]]));
    uncheckedAssertEqualObjects([NSSet setWithArray:[[managed.dateObj valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[date(1), date(2)]]));
    uncheckedAssertEqualObjects([NSSet setWithArray:[[managed.decimalObj valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[decimal128(1), decimal128(2)]]));
    uncheckedAssertEqualObjects([NSSet setWithArray:[[managed.objectIdObj valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[objectId(1), objectId(2)]]));
    uncheckedAssertEqualObjects([NSSet setWithArray:[[managed.uuidObj valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"), uuid(@"00000000-0000-0000-0000-000000000000")]]));
    uncheckedAssertEqualObjects([NSSet setWithArray:[[managed.anyBoolObj valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[@NO, @YES]]));
    uncheckedAssertEqualObjects([NSSet setWithArray:[[managed.anyIntObj valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[@2, @3]]));
    uncheckedAssertEqualObjects([NSSet setWithArray:[[managed.anyFloatObj valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[@2.2f, @3.3f]]));
    uncheckedAssertEqualObjects([NSSet setWithArray:[[managed.anyDoubleObj valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[@2.2, @3.3]]));
    uncheckedAssertEqualObjects([NSSet setWithArray:[[managed.anyStringObj valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[@"a", @"b"]]));
    uncheckedAssertEqualObjects([NSSet setWithArray:[[managed.anyDataObj valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[data(1), data(2)]]));
    uncheckedAssertEqualObjects([NSSet setWithArray:[[managed.anyDateObj valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[date(1), date(2)]]));
    uncheckedAssertEqualObjects([NSSet setWithArray:[[managed.anyDecimalObj valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[decimal128(1), decimal128(2)]]));
    uncheckedAssertEqualObjects([NSSet setWithArray:[[managed.anyObjectIdObj valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[objectId(1), objectId(2)]]));
    uncheckedAssertEqualObjects([NSSet setWithArray:[[managed.anyUUIDObj valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[uuid(@"00000000-0000-0000-0000-000000000000"), uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")]]));
    uncheckedAssertEqualObjects([NSSet setWithArray:[[optManaged.boolObj valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[NSNull.null, @NO, @YES]]));
    uncheckedAssertEqualObjects([NSSet setWithArray:[[optManaged.intObj valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[NSNull.null, @2, @3]]));
    uncheckedAssertEqualObjects([NSSet setWithArray:[[optManaged.floatObj valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[NSNull.null, @2.2f, @3.3f]]));
    uncheckedAssertEqualObjects([NSSet setWithArray:[[optManaged.doubleObj valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[NSNull.null, @2.2, @3.3]]));
    uncheckedAssertEqualObjects([NSSet setWithArray:[[optManaged.stringObj valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[NSNull.null, @"a", @"bc"]]));
    uncheckedAssertEqualObjects([NSSet setWithArray:[[optManaged.dataObj valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[NSNull.null, data(1), data(2)]]));
    uncheckedAssertEqualObjects([NSSet setWithArray:[[optManaged.dateObj valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[NSNull.null, date(1), date(2)]]));
    uncheckedAssertEqualObjects([NSSet setWithArray:[[optManaged.decimalObj valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[NSNull.null, decimal128(1), decimal128(2)]]));
    uncheckedAssertEqualObjects([NSSet setWithArray:[[optManaged.objectIdObj valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[NSNull.null, objectId(1), objectId(2)]]));
    uncheckedAssertEqualObjects([NSSet setWithArray:[[optManaged.uuidObj valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[NSNull.null, uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"), uuid(@"00000000-0000-0000-0000-000000000000")]]));
}

- (void)testValueForKeyNumericAggregates {
    uncheckedAssertNil([unmanaged.intObj valueForKeyPath:@"@min.self"]);
    uncheckedAssertNil([unmanaged.floatObj valueForKeyPath:@"@min.self"]);
    uncheckedAssertNil([unmanaged.doubleObj valueForKeyPath:@"@min.self"]);
    uncheckedAssertNil([unmanaged.dateObj valueForKeyPath:@"@min.self"]);
    uncheckedAssertNil([unmanaged.decimalObj valueForKeyPath:@"@min.self"]);
    uncheckedAssertNil([unmanaged.anyFloatObj valueForKeyPath:@"@min.self"]);
    uncheckedAssertNil([unmanaged.anyDoubleObj valueForKeyPath:@"@min.self"]);
    uncheckedAssertNil([unmanaged.anyDateObj valueForKeyPath:@"@min.self"]);
    uncheckedAssertNil([unmanaged.anyDecimalObj valueForKeyPath:@"@min.self"]);
    uncheckedAssertNil([optUnmanaged.intObj valueForKeyPath:@"@min.self"]);
    uncheckedAssertNil([optUnmanaged.floatObj valueForKeyPath:@"@min.self"]);
    uncheckedAssertNil([optUnmanaged.doubleObj valueForKeyPath:@"@min.self"]);
    uncheckedAssertNil([optUnmanaged.dateObj valueForKeyPath:@"@min.self"]);
    uncheckedAssertNil([optUnmanaged.decimalObj valueForKeyPath:@"@min.self"]);
    uncheckedAssertNil([managed.intObj valueForKeyPath:@"@min.self"]);
    uncheckedAssertNil([managed.floatObj valueForKeyPath:@"@min.self"]);
    uncheckedAssertNil([managed.doubleObj valueForKeyPath:@"@min.self"]);
    uncheckedAssertNil([managed.dateObj valueForKeyPath:@"@min.self"]);
    uncheckedAssertNil([managed.decimalObj valueForKeyPath:@"@min.self"]);
    uncheckedAssertNil([managed.anyIntObj valueForKeyPath:@"@min.self"]);
    uncheckedAssertNil([managed.anyFloatObj valueForKeyPath:@"@min.self"]);
    uncheckedAssertNil([managed.anyDoubleObj valueForKeyPath:@"@min.self"]);
    uncheckedAssertNil([managed.anyDateObj valueForKeyPath:@"@min.self"]);
    uncheckedAssertNil([managed.anyDecimalObj valueForKeyPath:@"@min.self"]);
    uncheckedAssertNil([optManaged.intObj valueForKeyPath:@"@min.self"]);
    uncheckedAssertNil([optManaged.floatObj valueForKeyPath:@"@min.self"]);
    uncheckedAssertNil([optManaged.doubleObj valueForKeyPath:@"@min.self"]);
    uncheckedAssertNil([optManaged.dateObj valueForKeyPath:@"@min.self"]);
    uncheckedAssertNil([optManaged.decimalObj valueForKeyPath:@"@min.self"]);
    uncheckedAssertNil([unmanaged.intObj valueForKeyPath:@"@max.self"]);
    uncheckedAssertNil([unmanaged.floatObj valueForKeyPath:@"@max.self"]);
    uncheckedAssertNil([unmanaged.doubleObj valueForKeyPath:@"@max.self"]);
    uncheckedAssertNil([unmanaged.dateObj valueForKeyPath:@"@max.self"]);
    uncheckedAssertNil([unmanaged.decimalObj valueForKeyPath:@"@max.self"]);
    uncheckedAssertNil([unmanaged.anyFloatObj valueForKeyPath:@"@max.self"]);
    uncheckedAssertNil([unmanaged.anyDoubleObj valueForKeyPath:@"@max.self"]);
    uncheckedAssertNil([unmanaged.anyDateObj valueForKeyPath:@"@max.self"]);
    uncheckedAssertNil([unmanaged.anyDecimalObj valueForKeyPath:@"@max.self"]);
    uncheckedAssertNil([optUnmanaged.intObj valueForKeyPath:@"@max.self"]);
    uncheckedAssertNil([optUnmanaged.floatObj valueForKeyPath:@"@max.self"]);
    uncheckedAssertNil([optUnmanaged.doubleObj valueForKeyPath:@"@max.self"]);
    uncheckedAssertNil([optUnmanaged.dateObj valueForKeyPath:@"@max.self"]);
    uncheckedAssertNil([optUnmanaged.decimalObj valueForKeyPath:@"@max.self"]);
    uncheckedAssertNil([managed.intObj valueForKeyPath:@"@max.self"]);
    uncheckedAssertNil([managed.floatObj valueForKeyPath:@"@max.self"]);
    uncheckedAssertNil([managed.doubleObj valueForKeyPath:@"@max.self"]);
    uncheckedAssertNil([managed.dateObj valueForKeyPath:@"@max.self"]);
    uncheckedAssertNil([managed.decimalObj valueForKeyPath:@"@max.self"]);
    uncheckedAssertNil([managed.anyIntObj valueForKeyPath:@"@max.self"]);
    uncheckedAssertNil([managed.anyFloatObj valueForKeyPath:@"@max.self"]);
    uncheckedAssertNil([managed.anyDoubleObj valueForKeyPath:@"@max.self"]);
    uncheckedAssertNil([managed.anyDateObj valueForKeyPath:@"@max.self"]);
    uncheckedAssertNil([managed.anyDecimalObj valueForKeyPath:@"@max.self"]);
    uncheckedAssertNil([optManaged.intObj valueForKeyPath:@"@max.self"]);
    uncheckedAssertNil([optManaged.floatObj valueForKeyPath:@"@max.self"]);
    uncheckedAssertNil([optManaged.doubleObj valueForKeyPath:@"@max.self"]);
    uncheckedAssertNil([optManaged.dateObj valueForKeyPath:@"@max.self"]);
    uncheckedAssertNil([optManaged.decimalObj valueForKeyPath:@"@max.self"]);
    uncheckedAssertEqualObjects([unmanaged.intObj valueForKeyPath:@"@sum.self"], @0);
    uncheckedAssertEqualObjects([unmanaged.floatObj valueForKeyPath:@"@sum.self"], @0);
    uncheckedAssertEqualObjects([unmanaged.doubleObj valueForKeyPath:@"@sum.self"], @0);
    uncheckedAssertEqualObjects([unmanaged.decimalObj valueForKeyPath:@"@sum.self"], @0);
    uncheckedAssertEqualObjects([unmanaged.anyIntObj valueForKeyPath:@"@sum.self"], @0);
    uncheckedAssertEqualObjects([unmanaged.anyFloatObj valueForKeyPath:@"@sum.self"], @0);
    uncheckedAssertEqualObjects([unmanaged.anyDoubleObj valueForKeyPath:@"@sum.self"], @0);
    uncheckedAssertEqualObjects([unmanaged.anyDecimalObj valueForKeyPath:@"@sum.self"], @0);
    uncheckedAssertEqualObjects([optUnmanaged.intObj valueForKeyPath:@"@sum.self"], @0);
    uncheckedAssertEqualObjects([optUnmanaged.floatObj valueForKeyPath:@"@sum.self"], @0);
    uncheckedAssertEqualObjects([optUnmanaged.doubleObj valueForKeyPath:@"@sum.self"], @0);
    uncheckedAssertEqualObjects([optUnmanaged.decimalObj valueForKeyPath:@"@sum.self"], @0);
    uncheckedAssertEqualObjects([managed.intObj valueForKeyPath:@"@sum.self"], @0);
    uncheckedAssertEqualObjects([managed.floatObj valueForKeyPath:@"@sum.self"], @0);
    uncheckedAssertEqualObjects([managed.doubleObj valueForKeyPath:@"@sum.self"], @0);
    uncheckedAssertEqualObjects([managed.decimalObj valueForKeyPath:@"@sum.self"], @0);
    uncheckedAssertEqualObjects([managed.anyIntObj valueForKeyPath:@"@sum.self"], @0);
    uncheckedAssertEqualObjects([managed.anyFloatObj valueForKeyPath:@"@sum.self"], @0);
    uncheckedAssertEqualObjects([managed.anyDoubleObj valueForKeyPath:@"@sum.self"], @0);
    uncheckedAssertEqualObjects([managed.anyDecimalObj valueForKeyPath:@"@sum.self"], @0);
    uncheckedAssertEqualObjects([optManaged.intObj valueForKeyPath:@"@sum.self"], @0);
    uncheckedAssertEqualObjects([optManaged.floatObj valueForKeyPath:@"@sum.self"], @0);
    uncheckedAssertEqualObjects([optManaged.doubleObj valueForKeyPath:@"@sum.self"], @0);
    uncheckedAssertEqualObjects([optManaged.decimalObj valueForKeyPath:@"@sum.self"], @0);
    uncheckedAssertNil([unmanaged.intObj valueForKeyPath:@"@avg.self"]);
    uncheckedAssertNil([unmanaged.floatObj valueForKeyPath:@"@avg.self"]);
    uncheckedAssertNil([unmanaged.doubleObj valueForKeyPath:@"@avg.self"]);
    uncheckedAssertNil([unmanaged.decimalObj valueForKeyPath:@"@avg.self"]);
    uncheckedAssertNil([unmanaged.anyIntObj valueForKeyPath:@"@avg.self"]);
    uncheckedAssertNil([unmanaged.anyFloatObj valueForKeyPath:@"@avg.self"]);
    uncheckedAssertNil([unmanaged.anyDoubleObj valueForKeyPath:@"@avg.self"]);
    uncheckedAssertNil([unmanaged.anyDecimalObj valueForKeyPath:@"@avg.self"]);
    uncheckedAssertNil([optUnmanaged.intObj valueForKeyPath:@"@avg.self"]);
    uncheckedAssertNil([optUnmanaged.floatObj valueForKeyPath:@"@avg.self"]);
    uncheckedAssertNil([optUnmanaged.doubleObj valueForKeyPath:@"@avg.self"]);
    uncheckedAssertNil([optUnmanaged.decimalObj valueForKeyPath:@"@avg.self"]);
    uncheckedAssertNil([managed.intObj valueForKeyPath:@"@avg.self"]);
    uncheckedAssertNil([managed.floatObj valueForKeyPath:@"@avg.self"]);
    uncheckedAssertNil([managed.doubleObj valueForKeyPath:@"@avg.self"]);
    uncheckedAssertNil([managed.decimalObj valueForKeyPath:@"@avg.self"]);
    uncheckedAssertNil([managed.anyIntObj valueForKeyPath:@"@avg.self"]);
    uncheckedAssertNil([managed.anyFloatObj valueForKeyPath:@"@avg.self"]);
    uncheckedAssertNil([managed.anyDoubleObj valueForKeyPath:@"@avg.self"]);
    uncheckedAssertNil([managed.anyDecimalObj valueForKeyPath:@"@avg.self"]);
    uncheckedAssertNil([optManaged.intObj valueForKeyPath:@"@avg.self"]);
    uncheckedAssertNil([optManaged.floatObj valueForKeyPath:@"@avg.self"]);
    uncheckedAssertNil([optManaged.doubleObj valueForKeyPath:@"@avg.self"]);
    uncheckedAssertNil([optManaged.decimalObj valueForKeyPath:@"@avg.self"]);

    [self addObjects];

    uncheckedAssertEqualObjects([unmanaged.intObj valueForKeyPath:@"@min.self"], @2);
    uncheckedAssertEqualObjects([unmanaged.floatObj valueForKeyPath:@"@min.self"], @2.2f);
    uncheckedAssertEqualObjects([unmanaged.doubleObj valueForKeyPath:@"@min.self"], @2.2);
    uncheckedAssertEqualObjects([unmanaged.dateObj valueForKeyPath:@"@min.self"], date(1));
    uncheckedAssertEqualObjects([unmanaged.decimalObj valueForKeyPath:@"@min.self"], decimal128(1));
    uncheckedAssertEqualObjects([unmanaged.anyFloatObj valueForKeyPath:@"@min.self"], @2.2f);
    uncheckedAssertEqualObjects([unmanaged.anyDoubleObj valueForKeyPath:@"@min.self"], @2.2);
    uncheckedAssertEqualObjects([unmanaged.anyDateObj valueForKeyPath:@"@min.self"], date(1));
    uncheckedAssertEqualObjects([unmanaged.anyDecimalObj valueForKeyPath:@"@min.self"], decimal128(1));
    uncheckedAssertEqualObjects([optUnmanaged.intObj valueForKeyPath:@"@max.self"], @3);
    uncheckedAssertEqualObjects([optUnmanaged.floatObj valueForKeyPath:@"@max.self"], @3.3f);
    uncheckedAssertEqualObjects([optUnmanaged.doubleObj valueForKeyPath:@"@max.self"], @3.3);
    uncheckedAssertEqualObjects([optUnmanaged.dateObj valueForKeyPath:@"@max.self"], date(2));
    uncheckedAssertEqualObjects([optUnmanaged.decimalObj valueForKeyPath:@"@max.self"], decimal128(2));

    uncheckedAssertEqualObjects([managed.intObj valueForKeyPath:@"@min.self"], @2);
    uncheckedAssertEqualObjects([managed.floatObj valueForKeyPath:@"@min.self"], @2.2f);
    uncheckedAssertEqualObjects([managed.doubleObj valueForKeyPath:@"@min.self"], @2.2);
    uncheckedAssertEqualObjects([managed.dateObj valueForKeyPath:@"@min.self"], date(1));
    uncheckedAssertEqualObjects([managed.decimalObj valueForKeyPath:@"@min.self"], decimal128(1));
    uncheckedAssertEqualObjects([managed.anyIntObj valueForKeyPath:@"@min.self"], @2);
    uncheckedAssertEqualObjects([managed.anyFloatObj valueForKeyPath:@"@min.self"], @2.2f);
    uncheckedAssertEqualObjects([managed.anyDoubleObj valueForKeyPath:@"@min.self"], @2.2);
    uncheckedAssertEqualObjects([managed.anyDateObj valueForKeyPath:@"@min.self"], date(1));
    uncheckedAssertEqualObjects([managed.anyDecimalObj valueForKeyPath:@"@min.self"], decimal128(1));
    uncheckedAssertEqualObjects([optManaged.intObj valueForKeyPath:@"@max.self"], @3);
    uncheckedAssertEqualObjects([optManaged.floatObj valueForKeyPath:@"@max.self"], @3.3f);
    uncheckedAssertEqualObjects([optManaged.doubleObj valueForKeyPath:@"@max.self"], @3.3);
    uncheckedAssertEqualObjects([optManaged.dateObj valueForKeyPath:@"@max.self"], date(2));
    uncheckedAssertEqualObjects([optManaged.decimalObj valueForKeyPath:@"@max.self"], decimal128(2));

    XCTAssertEqualWithAccuracy([[unmanaged.intObj valueForKeyPath:@"@sum.self"] doubleValue], sum(@[@2, @3]), .001);
    XCTAssertEqualWithAccuracy([[unmanaged.floatObj valueForKeyPath:@"@sum.self"] doubleValue], sum(@[@2.2f, @3.3f]), .001);
    XCTAssertEqualWithAccuracy([[unmanaged.doubleObj valueForKeyPath:@"@sum.self"] doubleValue], sum(@[@2.2, @3.3]), .001);
    XCTAssertEqualWithAccuracy([[unmanaged.decimalObj valueForKeyPath:@"@sum.self"] doubleValue], sum(@[decimal128(1), decimal128(2)]), .001);
    XCTAssertEqualWithAccuracy([[unmanaged.anyIntObj valueForKeyPath:@"@sum.self"] doubleValue], sum(@[@2, @3]), .001);
    XCTAssertEqualWithAccuracy([[unmanaged.anyFloatObj valueForKeyPath:@"@sum.self"] doubleValue], sum(@[@2.2f, @3.3f]), .001);
    XCTAssertEqualWithAccuracy([[unmanaged.anyDoubleObj valueForKeyPath:@"@sum.self"] doubleValue], sum(@[@2.2, @3.3]), .001);
    XCTAssertEqualWithAccuracy([[unmanaged.anyDecimalObj valueForKeyPath:@"@sum.self"] doubleValue], sum(@[decimal128(1), decimal128(2)]), .001);
    XCTAssertEqualWithAccuracy([[optUnmanaged.intObj valueForKeyPath:@"@sum.self"] doubleValue], sum(@[NSNull.null, @2, @3]), .001);
    XCTAssertEqualWithAccuracy([[optUnmanaged.floatObj valueForKeyPath:@"@sum.self"] doubleValue], sum(@[NSNull.null, @2.2f, @3.3f]), .001);
    XCTAssertEqualWithAccuracy([[optUnmanaged.doubleObj valueForKeyPath:@"@sum.self"] doubleValue], sum(@[NSNull.null, @2.2, @3.3]), .001);
    XCTAssertEqualWithAccuracy([[optUnmanaged.decimalObj valueForKeyPath:@"@sum.self"] doubleValue], sum(@[NSNull.null, decimal128(1), decimal128(2)]), .001);
    XCTAssertEqualWithAccuracy([[managed.intObj valueForKeyPath:@"@sum.self"] doubleValue], sum(@[@2, @3]), .001);
    XCTAssertEqualWithAccuracy([[managed.floatObj valueForKeyPath:@"@sum.self"] doubleValue], sum(@[@2.2f, @3.3f]), .001);
    XCTAssertEqualWithAccuracy([[managed.doubleObj valueForKeyPath:@"@sum.self"] doubleValue], sum(@[@2.2, @3.3]), .001);
    XCTAssertEqualWithAccuracy([[managed.decimalObj valueForKeyPath:@"@sum.self"] doubleValue], sum(@[decimal128(1), decimal128(2)]), .001);
    XCTAssertEqualWithAccuracy([[managed.anyIntObj valueForKeyPath:@"@sum.self"] doubleValue], sum(@[@2, @3]), .001);
    XCTAssertEqualWithAccuracy([[managed.anyFloatObj valueForKeyPath:@"@sum.self"] doubleValue], sum(@[@2.2f, @3.3f]), .001);
    XCTAssertEqualWithAccuracy([[managed.anyDoubleObj valueForKeyPath:@"@sum.self"] doubleValue], sum(@[@2.2, @3.3]), .001);
    XCTAssertEqualWithAccuracy([[managed.anyDecimalObj valueForKeyPath:@"@sum.self"] doubleValue], sum(@[decimal128(1), decimal128(2)]), .001);
    XCTAssertEqualWithAccuracy([[optManaged.intObj valueForKeyPath:@"@sum.self"] doubleValue], sum(@[NSNull.null, @2, @3]), .001);
    XCTAssertEqualWithAccuracy([[optManaged.floatObj valueForKeyPath:@"@sum.self"] doubleValue], sum(@[NSNull.null, @2.2f, @3.3f]), .001);
    XCTAssertEqualWithAccuracy([[optManaged.doubleObj valueForKeyPath:@"@sum.self"] doubleValue], sum(@[NSNull.null, @2.2, @3.3]), .001);
    XCTAssertEqualWithAccuracy([[optManaged.decimalObj valueForKeyPath:@"@sum.self"] doubleValue], sum(@[NSNull.null, decimal128(1), decimal128(2)]), .001);
    XCTAssertEqualWithAccuracy([[unmanaged.intObj valueForKeyPath:@"@avg.self"] doubleValue], average(@[@2, @3]), .001);
    XCTAssertEqualWithAccuracy([[unmanaged.floatObj valueForKeyPath:@"@avg.self"] doubleValue], average(@[@2.2f, @3.3f]), .001);
    XCTAssertEqualWithAccuracy([[unmanaged.doubleObj valueForKeyPath:@"@avg.self"] doubleValue], average(@[@2.2, @3.3]), .001);
    XCTAssertEqualWithAccuracy([[unmanaged.decimalObj valueForKeyPath:@"@avg.self"] doubleValue], average(@[decimal128(1), decimal128(2)]), .001);
    XCTAssertEqualWithAccuracy([[unmanaged.anyIntObj valueForKeyPath:@"@avg.self"] doubleValue], average(@[@2, @3]), .001);
    XCTAssertEqualWithAccuracy([[unmanaged.anyFloatObj valueForKeyPath:@"@avg.self"] doubleValue], average(@[@2.2f, @3.3f]), .001);
    XCTAssertEqualWithAccuracy([[unmanaged.anyDoubleObj valueForKeyPath:@"@avg.self"] doubleValue], average(@[@2.2, @3.3]), .001);
    XCTAssertEqualWithAccuracy([[unmanaged.anyDecimalObj valueForKeyPath:@"@avg.self"] doubleValue], average(@[decimal128(1), decimal128(2)]), .001);
    XCTAssertEqualWithAccuracy([[optUnmanaged.intObj valueForKeyPath:@"@avg.self"] doubleValue], average(@[NSNull.null, @2, @3]), .001);
    XCTAssertEqualWithAccuracy([[optUnmanaged.floatObj valueForKeyPath:@"@avg.self"] doubleValue], average(@[NSNull.null, @2.2f, @3.3f]), .001);
    XCTAssertEqualWithAccuracy([[optUnmanaged.doubleObj valueForKeyPath:@"@avg.self"] doubleValue], average(@[NSNull.null, @2.2, @3.3]), .001);
    XCTAssertEqualWithAccuracy([[optUnmanaged.decimalObj valueForKeyPath:@"@avg.self"] doubleValue], average(@[NSNull.null, decimal128(1), decimal128(2)]), .001);
    XCTAssertEqualWithAccuracy([[managed.intObj valueForKeyPath:@"@avg.self"] doubleValue], average(@[@2, @3]), .001);
    XCTAssertEqualWithAccuracy([[managed.floatObj valueForKeyPath:@"@avg.self"] doubleValue], average(@[@2.2f, @3.3f]), .001);
    XCTAssertEqualWithAccuracy([[managed.doubleObj valueForKeyPath:@"@avg.self"] doubleValue], average(@[@2.2, @3.3]), .001);
    XCTAssertEqualWithAccuracy([[managed.decimalObj valueForKeyPath:@"@avg.self"] doubleValue], average(@[decimal128(1), decimal128(2)]), .001);
    XCTAssertEqualWithAccuracy([[managed.anyIntObj valueForKeyPath:@"@avg.self"] doubleValue], average(@[@2, @3]), .001);
    XCTAssertEqualWithAccuracy([[managed.anyFloatObj valueForKeyPath:@"@avg.self"] doubleValue], average(@[@2.2f, @3.3f]), .001);
    XCTAssertEqualWithAccuracy([[managed.anyDoubleObj valueForKeyPath:@"@avg.self"] doubleValue], average(@[@2.2, @3.3]), .001);
    XCTAssertEqualWithAccuracy([[managed.anyDecimalObj valueForKeyPath:@"@avg.self"] doubleValue], average(@[decimal128(1), decimal128(2)]), .001);
    XCTAssertEqualWithAccuracy([[optManaged.intObj valueForKeyPath:@"@avg.self"] doubleValue], average(@[NSNull.null, @2, @3]), .001);
    XCTAssertEqualWithAccuracy([[optManaged.floatObj valueForKeyPath:@"@avg.self"] doubleValue], average(@[NSNull.null, @2.2f, @3.3f]), .001);
    XCTAssertEqualWithAccuracy([[optManaged.doubleObj valueForKeyPath:@"@avg.self"] doubleValue], average(@[NSNull.null, @2.2, @3.3]), .001);
    XCTAssertEqualWithAccuracy([[optManaged.decimalObj valueForKeyPath:@"@avg.self"] doubleValue], average(@[NSNull.null, decimal128(1), decimal128(2)]), .001);
}

- (void)testValueForKeyLength {
    for (RLMSet *set in allSets) {
        uncheckedAssertEqualObjects([[set valueForKey:@"length"] allObjects], @[]);
    }

    [self addObjects];
    uncheckedAssertEqualObjects([unmanaged.stringObj valueForKey:@"length"], ([[NSSet setWithArray:@[@"a", @"bc"]] valueForKey:@"length"]));
    uncheckedAssertEqualObjects([unmanaged.anyStringObj valueForKey:@"length"], ([[NSSet setWithArray:@[@"a", @"b"]] valueForKey:@"length"]));
    uncheckedAssertEqualObjects([optUnmanaged.stringObj valueForKey:@"length"], ([[NSSet setWithArray:@[NSNull.null, @"a", @"bc"]] valueForKey:@"length"]));
    uncheckedAssertEqualObjects([managed.stringObj valueForKey:@"length"], ([[NSSet setWithArray:@[@"a", @"bc"]] valueForKey:@"length"]));
    uncheckedAssertEqualObjects([managed.anyStringObj valueForKey:@"length"], ([[NSSet setWithArray:@[@"a", @"b"]] valueForKey:@"length"]));
    uncheckedAssertEqualObjects([optManaged.stringObj valueForKey:@"length"], ([[NSSet setWithArray:@[NSNull.null, @"a", @"bc"]] valueForKey:@"length"]));
}

- (void)testSetValueForKey {
    for (RLMSet *set in allSets) {
        RLMAssertThrowsWithReason([set setValue:@0 forKey:@"not self"],
                                  @"this class is not key value coding-compliant for the key not self.");
    }
    RLMAssertThrowsWithReason([unmanaged.boolObj setValue:@"a" forKey:@"self"], 
                              @"Invalid value 'a' of type '" RLMConstantString "' for expected type 'bool'");
    RLMAssertThrowsWithReason([unmanaged.intObj setValue:@"a" forKey:@"self"], 
                              @"Invalid value 'a' of type '" RLMConstantString "' for expected type 'int'");
    RLMAssertThrowsWithReason([unmanaged.floatObj setValue:@"a" forKey:@"self"], 
                              @"Invalid value 'a' of type '" RLMConstantString "' for expected type 'float'");
    RLMAssertThrowsWithReason([unmanaged.doubleObj setValue:@"a" forKey:@"self"], 
                              @"Invalid value 'a' of type '" RLMConstantString "' for expected type 'double'");
    RLMAssertThrowsWithReason([unmanaged.stringObj setValue:@2 forKey:@"self"], 
                              @"Invalid value '2' of type '" RLMConstantInt "' for expected type 'string'");
    RLMAssertThrowsWithReason([unmanaged.dataObj setValue:@"a" forKey:@"self"], 
                              @"Invalid value 'a' of type '" RLMConstantString "' for expected type 'data'");
    RLMAssertThrowsWithReason([unmanaged.dateObj setValue:@"a" forKey:@"self"], 
                              @"Invalid value 'a' of type '" RLMConstantString "' for expected type 'date'");
    RLMAssertThrowsWithReason([unmanaged.decimalObj setValue:@"a" forKey:@"self"], 
                              @"Invalid value 'a' of type '" RLMConstantString "' for expected type 'decimal128'");
    RLMAssertThrowsWithReason([unmanaged.objectIdObj setValue:@"a" forKey:@"self"], 
                              @"Invalid value 'a' of type '" RLMConstantString "' for expected type 'object id'");
    RLMAssertThrowsWithReason([unmanaged.uuidObj setValue:@"a" forKey:@"self"], 
                              @"Invalid value 'a' of type '" RLMConstantString "' for expected type 'uuid'");
    RLMAssertThrowsWithReason([optUnmanaged.boolObj setValue:@"a" forKey:@"self"], 
                              @"Invalid value 'a' of type '" RLMConstantString "' for expected type 'bool?'");
    RLMAssertThrowsWithReason([optUnmanaged.intObj setValue:@"a" forKey:@"self"], 
                              @"Invalid value 'a' of type '" RLMConstantString "' for expected type 'int?'");
    RLMAssertThrowsWithReason([optUnmanaged.floatObj setValue:@"a" forKey:@"self"], 
                              @"Invalid value 'a' of type '" RLMConstantString "' for expected type 'float?'");
    RLMAssertThrowsWithReason([optUnmanaged.doubleObj setValue:@"a" forKey:@"self"], 
                              @"Invalid value 'a' of type '" RLMConstantString "' for expected type 'double?'");
    RLMAssertThrowsWithReason([optUnmanaged.stringObj setValue:@2 forKey:@"self"], 
                              @"Invalid value '2' of type '" RLMConstantInt "' for expected type 'string?'");
    RLMAssertThrowsWithReason([optUnmanaged.dataObj setValue:@"a" forKey:@"self"], 
                              @"Invalid value 'a' of type '" RLMConstantString "' for expected type 'data?'");
    RLMAssertThrowsWithReason([optUnmanaged.dateObj setValue:@"a" forKey:@"self"], 
                              @"Invalid value 'a' of type '" RLMConstantString "' for expected type 'date?'");
    RLMAssertThrowsWithReason([optUnmanaged.decimalObj setValue:@"a" forKey:@"self"], 
                              @"Invalid value 'a' of type '" RLMConstantString "' for expected type 'decimal128?'");
    RLMAssertThrowsWithReason([optUnmanaged.objectIdObj setValue:@"a" forKey:@"self"], 
                              @"Invalid value 'a' of type '" RLMConstantString "' for expected type 'object id?'");
    RLMAssertThrowsWithReason([optUnmanaged.uuidObj setValue:@"a" forKey:@"self"], 
                              @"Invalid value 'a' of type '" RLMConstantString "' for expected type 'uuid?'");
    RLMAssertThrowsWithReason([managed.boolObj setValue:@"a" forKey:@"self"], 
                              @"Invalid value 'a' of type '" RLMConstantString "' for expected type 'bool'");
    RLMAssertThrowsWithReason([managed.intObj setValue:@"a" forKey:@"self"], 
                              @"Invalid value 'a' of type '" RLMConstantString "' for expected type 'int'");
    RLMAssertThrowsWithReason([managed.floatObj setValue:@"a" forKey:@"self"], 
                              @"Invalid value 'a' of type '" RLMConstantString "' for expected type 'float'");
    RLMAssertThrowsWithReason([managed.doubleObj setValue:@"a" forKey:@"self"], 
                              @"Invalid value 'a' of type '" RLMConstantString "' for expected type 'double'");
    RLMAssertThrowsWithReason([managed.stringObj setValue:@2 forKey:@"self"], 
                              @"Invalid value '2' of type '" RLMConstantInt "' for expected type 'string'");
    RLMAssertThrowsWithReason([managed.dataObj setValue:@"a" forKey:@"self"], 
                              @"Invalid value 'a' of type '" RLMConstantString "' for expected type 'data'");
    RLMAssertThrowsWithReason([managed.dateObj setValue:@"a" forKey:@"self"], 
                              @"Invalid value 'a' of type '" RLMConstantString "' for expected type 'date'");
    RLMAssertThrowsWithReason([managed.decimalObj setValue:@"a" forKey:@"self"], 
                              @"Invalid value 'a' of type '" RLMConstantString "' for expected type 'decimal128'");
    RLMAssertThrowsWithReason([managed.objectIdObj setValue:@"a" forKey:@"self"], 
                              @"Invalid value 'a' of type '" RLMConstantString "' for expected type 'object id'");
    RLMAssertThrowsWithReason([managed.uuidObj setValue:@"a" forKey:@"self"], 
                              @"Invalid value 'a' of type '" RLMConstantString "' for expected type 'uuid'");
    RLMAssertThrowsWithReason([optManaged.boolObj setValue:@"a" forKey:@"self"], 
                              @"Invalid value 'a' of type '" RLMConstantString "' for expected type 'bool?'");
    RLMAssertThrowsWithReason([optManaged.intObj setValue:@"a" forKey:@"self"], 
                              @"Invalid value 'a' of type '" RLMConstantString "' for expected type 'int?'");
    RLMAssertThrowsWithReason([optManaged.floatObj setValue:@"a" forKey:@"self"], 
                              @"Invalid value 'a' of type '" RLMConstantString "' for expected type 'float?'");
    RLMAssertThrowsWithReason([optManaged.doubleObj setValue:@"a" forKey:@"self"], 
                              @"Invalid value 'a' of type '" RLMConstantString "' for expected type 'double?'");
    RLMAssertThrowsWithReason([optManaged.stringObj setValue:@2 forKey:@"self"], 
                              @"Invalid value '2' of type '" RLMConstantInt "' for expected type 'string?'");
    RLMAssertThrowsWithReason([optManaged.dataObj setValue:@"a" forKey:@"self"], 
                              @"Invalid value 'a' of type '" RLMConstantString "' for expected type 'data?'");
    RLMAssertThrowsWithReason([optManaged.dateObj setValue:@"a" forKey:@"self"], 
                              @"Invalid value 'a' of type '" RLMConstantString "' for expected type 'date?'");
    RLMAssertThrowsWithReason([optManaged.decimalObj setValue:@"a" forKey:@"self"], 
                              @"Invalid value 'a' of type '" RLMConstantString "' for expected type 'decimal128?'");
    RLMAssertThrowsWithReason([optManaged.objectIdObj setValue:@"a" forKey:@"self"], 
                              @"Invalid value 'a' of type '" RLMConstantString "' for expected type 'object id?'");
    RLMAssertThrowsWithReason([optManaged.uuidObj setValue:@"a" forKey:@"self"], 
                              @"Invalid value 'a' of type '" RLMConstantString "' for expected type 'uuid?'");
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
    [unmanaged.anyBoolObj setValue:@NO forKey:@"self"];
    [unmanaged.anyIntObj setValue:@2 forKey:@"self"];
    [unmanaged.anyFloatObj setValue:@2.2f forKey:@"self"];
    [unmanaged.anyDoubleObj setValue:@2.2 forKey:@"self"];
    [unmanaged.anyStringObj setValue:@"a" forKey:@"self"];
    [unmanaged.anyDataObj setValue:data(1) forKey:@"self"];
    [unmanaged.anyDateObj setValue:date(1) forKey:@"self"];
    [unmanaged.anyDecimalObj setValue:decimal128(1) forKey:@"self"];
    [unmanaged.anyObjectIdObj setValue:objectId(1) forKey:@"self"];
    [unmanaged.anyUUIDObj setValue:uuid(@"00000000-0000-0000-0000-000000000000") forKey:@"self"];
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
    [managed.anyBoolObj setValue:@NO forKey:@"self"];
    [managed.anyIntObj setValue:@2 forKey:@"self"];
    [managed.anyFloatObj setValue:@2.2f forKey:@"self"];
    [managed.anyDoubleObj setValue:@2.2 forKey:@"self"];
    [managed.anyStringObj setValue:@"a" forKey:@"self"];
    [managed.anyDataObj setValue:data(1) forKey:@"self"];
    [managed.anyDateObj setValue:date(1) forKey:@"self"];
    [managed.anyDecimalObj setValue:decimal128(1) forKey:@"self"];
    [managed.anyObjectIdObj setValue:objectId(1) forKey:@"self"];
    [managed.anyUUIDObj setValue:uuid(@"00000000-0000-0000-0000-000000000000") forKey:@"self"];
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
    RLMAssertThrowsWithReason(unmanaged.anyBoolObj.allObjects[1], @"index 1 beyond bounds [0 .. 0]");
    RLMAssertThrowsWithReason(unmanaged.anyIntObj.allObjects[1], @"index 1 beyond bounds [0 .. 0]");
    RLMAssertThrowsWithReason(unmanaged.anyFloatObj.allObjects[1], @"index 1 beyond bounds [0 .. 0]");
    RLMAssertThrowsWithReason(unmanaged.anyDoubleObj.allObjects[1], @"index 1 beyond bounds [0 .. 0]");
    RLMAssertThrowsWithReason(unmanaged.anyStringObj.allObjects[1], @"index 1 beyond bounds [0 .. 0]");
    RLMAssertThrowsWithReason(unmanaged.anyDataObj.allObjects[1], @"index 1 beyond bounds [0 .. 0]");
    RLMAssertThrowsWithReason(unmanaged.anyDateObj.allObjects[1], @"index 1 beyond bounds [0 .. 0]");
    RLMAssertThrowsWithReason(unmanaged.anyDecimalObj.allObjects[1], @"index 1 beyond bounds [0 .. 0]");
    RLMAssertThrowsWithReason(unmanaged.anyObjectIdObj.allObjects[1], @"index 1 beyond bounds [0 .. 0]");
    RLMAssertThrowsWithReason(unmanaged.anyUUIDObj.allObjects[1], @"index 1 beyond bounds [0 .. 0]");
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
    RLMAssertThrowsWithReason(managed.anyBoolObj.allObjects[1], @"index 1 beyond bounds [0 .. 0]");
    RLMAssertThrowsWithReason(managed.anyIntObj.allObjects[1], @"index 1 beyond bounds [0 .. 0]");
    RLMAssertThrowsWithReason(managed.anyFloatObj.allObjects[1], @"index 1 beyond bounds [0 .. 0]");
    RLMAssertThrowsWithReason(managed.anyDoubleObj.allObjects[1], @"index 1 beyond bounds [0 .. 0]");
    RLMAssertThrowsWithReason(managed.anyStringObj.allObjects[1], @"index 1 beyond bounds [0 .. 0]");
    RLMAssertThrowsWithReason(managed.anyDataObj.allObjects[1], @"index 1 beyond bounds [0 .. 0]");
    RLMAssertThrowsWithReason(managed.anyDateObj.allObjects[1], @"index 1 beyond bounds [0 .. 0]");
    RLMAssertThrowsWithReason(managed.anyDecimalObj.allObjects[1], @"index 1 beyond bounds [0 .. 0]");
    RLMAssertThrowsWithReason(managed.anyObjectIdObj.allObjects[1], @"index 1 beyond bounds [0 .. 0]");
    RLMAssertThrowsWithReason(managed.anyUUIDObj.allObjects[1], @"index 1 beyond bounds [0 .. 0]");
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

    uncheckedAssertEqualObjects(unmanaged.boolObj.allObjects[0], @NO);
    uncheckedAssertEqualObjects(unmanaged.intObj.allObjects[0], @2);
    uncheckedAssertEqualObjects(unmanaged.floatObj.allObjects[0], @2.2f);
    uncheckedAssertEqualObjects(unmanaged.doubleObj.allObjects[0], @2.2);
    uncheckedAssertEqualObjects(unmanaged.stringObj.allObjects[0], @"a");
    uncheckedAssertEqualObjects(unmanaged.dataObj.allObjects[0], data(1));
    uncheckedAssertEqualObjects(unmanaged.dateObj.allObjects[0], date(1));
    uncheckedAssertEqualObjects(unmanaged.decimalObj.allObjects[0], decimal128(1));
    uncheckedAssertEqualObjects(unmanaged.objectIdObj.allObjects[0], objectId(1));
    uncheckedAssertEqualObjects(unmanaged.uuidObj.allObjects[0], uuid(@"00000000-0000-0000-0000-000000000000"));
    uncheckedAssertEqualObjects(unmanaged.anyBoolObj.allObjects[0], @NO);
    uncheckedAssertEqualObjects(unmanaged.anyIntObj.allObjects[0], @2);
    uncheckedAssertEqualObjects(unmanaged.anyFloatObj.allObjects[0], @2.2f);
    uncheckedAssertEqualObjects(unmanaged.anyDoubleObj.allObjects[0], @2.2);
    uncheckedAssertEqualObjects(unmanaged.anyStringObj.allObjects[0], @"a");
    uncheckedAssertEqualObjects(unmanaged.anyDataObj.allObjects[0], data(1));
    uncheckedAssertEqualObjects(unmanaged.anyDateObj.allObjects[0], date(1));
    uncheckedAssertEqualObjects(unmanaged.anyDecimalObj.allObjects[0], decimal128(1));
    uncheckedAssertEqualObjects(unmanaged.anyObjectIdObj.allObjects[0], objectId(1));
    uncheckedAssertEqualObjects(unmanaged.anyUUIDObj.allObjects[0], uuid(@"00000000-0000-0000-0000-000000000000"));
    uncheckedAssertEqualObjects(optUnmanaged.boolObj.allObjects[0], NSNull.null);
    uncheckedAssertEqualObjects(optUnmanaged.intObj.allObjects[0], NSNull.null);
    uncheckedAssertEqualObjects(optUnmanaged.floatObj.allObjects[0], NSNull.null);
    uncheckedAssertEqualObjects(optUnmanaged.doubleObj.allObjects[0], NSNull.null);
    uncheckedAssertEqualObjects(optUnmanaged.stringObj.allObjects[0], NSNull.null);
    uncheckedAssertEqualObjects(optUnmanaged.dataObj.allObjects[0], NSNull.null);
    uncheckedAssertEqualObjects(optUnmanaged.dateObj.allObjects[0], NSNull.null);
    uncheckedAssertEqualObjects(optUnmanaged.decimalObj.allObjects[0], NSNull.null);
    uncheckedAssertEqualObjects(optUnmanaged.objectIdObj.allObjects[0], NSNull.null);
    uncheckedAssertEqualObjects(optUnmanaged.uuidObj.allObjects[0], NSNull.null);
    uncheckedAssertEqualObjects(managed.boolObj.allObjects[0], @NO);
    uncheckedAssertEqualObjects(managed.intObj.allObjects[0], @2);
    uncheckedAssertEqualObjects(managed.floatObj.allObjects[0], @2.2f);
    uncheckedAssertEqualObjects(managed.doubleObj.allObjects[0], @2.2);
    uncheckedAssertEqualObjects(managed.stringObj.allObjects[0], @"a");
    uncheckedAssertEqualObjects(managed.dataObj.allObjects[0], data(1));
    uncheckedAssertEqualObjects(managed.dateObj.allObjects[0], date(1));
    uncheckedAssertEqualObjects(managed.decimalObj.allObjects[0], decimal128(1));
    uncheckedAssertEqualObjects(managed.objectIdObj.allObjects[0], objectId(1));
    uncheckedAssertEqualObjects(managed.uuidObj.allObjects[0], uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"));
    uncheckedAssertEqualObjects(managed.anyBoolObj.allObjects[0], @NO);
    uncheckedAssertEqualObjects(managed.anyIntObj.allObjects[0], @2);
    uncheckedAssertEqualObjects(managed.anyFloatObj.allObjects[0], @2.2f);
    uncheckedAssertEqualObjects(managed.anyDoubleObj.allObjects[0], @2.2);
    uncheckedAssertEqualObjects(managed.anyStringObj.allObjects[0], @"a");
    uncheckedAssertEqualObjects(managed.anyDataObj.allObjects[0], data(1));
    uncheckedAssertEqualObjects(managed.anyDateObj.allObjects[0], date(1));
    uncheckedAssertEqualObjects(managed.anyDecimalObj.allObjects[0], decimal128(1));
    uncheckedAssertEqualObjects(managed.anyObjectIdObj.allObjects[0], objectId(1));
    uncheckedAssertEqualObjects(managed.anyUUIDObj.allObjects[0], uuid(@"00000000-0000-0000-0000-000000000000"));
    uncheckedAssertEqualObjects(optManaged.boolObj.allObjects[0], NSNull.null);
    uncheckedAssertEqualObjects(optManaged.intObj.allObjects[0], NSNull.null);
    uncheckedAssertEqualObjects(optManaged.floatObj.allObjects[0], NSNull.null);
    uncheckedAssertEqualObjects(optManaged.doubleObj.allObjects[0], NSNull.null);
    uncheckedAssertEqualObjects(optManaged.stringObj.allObjects[0], NSNull.null);
    uncheckedAssertEqualObjects(optManaged.dataObj.allObjects[0], NSNull.null);
    uncheckedAssertEqualObjects(optManaged.dateObj.allObjects[0], NSNull.null);
    uncheckedAssertEqualObjects(optManaged.decimalObj.allObjects[0], NSNull.null);
    uncheckedAssertEqualObjects(optManaged.objectIdObj.allObjects[0], NSNull.null);
    uncheckedAssertEqualObjects(optManaged.uuidObj.allObjects[0], NSNull.null);
    uncheckedAssertEqualObjects(optUnmanaged.intObj.allObjects[0], NSNull.null);
    uncheckedAssertEqualObjects(optUnmanaged.floatObj.allObjects[0], NSNull.null);
    uncheckedAssertEqualObjects(optUnmanaged.doubleObj.allObjects[0], NSNull.null);
    uncheckedAssertEqualObjects(optUnmanaged.stringObj.allObjects[0], NSNull.null);
    uncheckedAssertEqualObjects(optUnmanaged.dataObj.allObjects[0], NSNull.null);
    uncheckedAssertEqualObjects(optUnmanaged.dateObj.allObjects[0], NSNull.null);
    uncheckedAssertEqualObjects(optUnmanaged.decimalObj.allObjects[0], NSNull.null);
    uncheckedAssertEqualObjects(optUnmanaged.objectIdObj.allObjects[0], NSNull.null);
    uncheckedAssertEqualObjects(optUnmanaged.uuidObj.allObjects[0], NSNull.null);
    uncheckedAssertEqualObjects(optManaged.boolObj.allObjects[0], NSNull.null);
    uncheckedAssertEqualObjects(optManaged.intObj.allObjects[0], NSNull.null);
    uncheckedAssertEqualObjects(optManaged.floatObj.allObjects[0], NSNull.null);
    uncheckedAssertEqualObjects(optManaged.doubleObj.allObjects[0], NSNull.null);
    uncheckedAssertEqualObjects(optManaged.stringObj.allObjects[0], NSNull.null);
    uncheckedAssertEqualObjects(optManaged.dataObj.allObjects[0], NSNull.null);
    uncheckedAssertEqualObjects(optManaged.dateObj.allObjects[0], NSNull.null);
    uncheckedAssertEqualObjects(optManaged.decimalObj.allObjects[0], NSNull.null);
    uncheckedAssertEqualObjects(optManaged.objectIdObj.allObjects[0], NSNull.null);
    uncheckedAssertEqualObjects(optManaged.uuidObj.allObjects[0], NSNull.null);

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
    uncheckedAssertEqualObjects(optUnmanaged.intObj.allObjects[0], NSNull.null);
    uncheckedAssertEqualObjects(optUnmanaged.floatObj.allObjects[0], NSNull.null);
    uncheckedAssertEqualObjects(optUnmanaged.doubleObj.allObjects[0], NSNull.null);
    uncheckedAssertEqualObjects(optUnmanaged.stringObj.allObjects[0], NSNull.null);
    uncheckedAssertEqualObjects(optUnmanaged.dataObj.allObjects[0], NSNull.null);
    uncheckedAssertEqualObjects(optUnmanaged.dateObj.allObjects[0], NSNull.null);
    uncheckedAssertEqualObjects(optUnmanaged.decimalObj.allObjects[0], NSNull.null);
    uncheckedAssertEqualObjects(optUnmanaged.objectIdObj.allObjects[0], NSNull.null);
    uncheckedAssertEqualObjects(optUnmanaged.uuidObj.allObjects[0], NSNull.null);
    uncheckedAssertEqualObjects(optManaged.boolObj.allObjects[0], NSNull.null);
    uncheckedAssertEqualObjects(optManaged.intObj.allObjects[0], NSNull.null);
    uncheckedAssertEqualObjects(optManaged.floatObj.allObjects[0], NSNull.null);
    uncheckedAssertEqualObjects(optManaged.doubleObj.allObjects[0], NSNull.null);
    uncheckedAssertEqualObjects(optManaged.stringObj.allObjects[0], NSNull.null);
    uncheckedAssertEqualObjects(optManaged.dataObj.allObjects[0], NSNull.null);
    uncheckedAssertEqualObjects(optManaged.dateObj.allObjects[0], NSNull.null);
    uncheckedAssertEqualObjects(optManaged.decimalObj.allObjects[0], NSNull.null);
    uncheckedAssertEqualObjects(optManaged.objectIdObj.allObjects[0], NSNull.null);
    uncheckedAssertEqualObjects(optManaged.uuidObj.allObjects[0], NSNull.null);
}

- (void)testAssignment {
    unmanaged.boolObj = (id)@[@YES]; 
     uncheckedAssertEqualObjects(unmanaged.boolObj.allObjects[0], @YES);
    unmanaged.intObj = (id)@[@3]; 
     uncheckedAssertEqualObjects(unmanaged.intObj.allObjects[0], @3);
    unmanaged.floatObj = (id)@[@3.3f]; 
     uncheckedAssertEqualObjects(unmanaged.floatObj.allObjects[0], @3.3f);
    unmanaged.doubleObj = (id)@[@3.3]; 
     uncheckedAssertEqualObjects(unmanaged.doubleObj.allObjects[0], @3.3);
    unmanaged.stringObj = (id)@[@"bc"]; 
     uncheckedAssertEqualObjects(unmanaged.stringObj.allObjects[0], @"bc");
    unmanaged.dataObj = (id)@[data(2)]; 
     uncheckedAssertEqualObjects(unmanaged.dataObj.allObjects[0], data(2));
    unmanaged.dateObj = (id)@[date(2)]; 
     uncheckedAssertEqualObjects(unmanaged.dateObj.allObjects[0], date(2));
    unmanaged.decimalObj = (id)@[decimal128(2)]; 
     uncheckedAssertEqualObjects(unmanaged.decimalObj.allObjects[0], decimal128(2));
    unmanaged.objectIdObj = (id)@[objectId(2)]; 
     uncheckedAssertEqualObjects(unmanaged.objectIdObj.allObjects[0], objectId(2));
    unmanaged.uuidObj = (id)@[uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")]; 
     uncheckedAssertEqualObjects(unmanaged.uuidObj.allObjects[0], uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"));
    unmanaged.anyBoolObj = (id)@[@YES]; 
     uncheckedAssertEqualObjects(unmanaged.anyBoolObj.allObjects[0], @YES);
    unmanaged.anyIntObj = (id)@[@3]; 
     uncheckedAssertEqualObjects(unmanaged.anyIntObj.allObjects[0], @3);
    unmanaged.anyFloatObj = (id)@[@3.3f]; 
     uncheckedAssertEqualObjects(unmanaged.anyFloatObj.allObjects[0], @3.3f);
    unmanaged.anyDoubleObj = (id)@[@3.3]; 
     uncheckedAssertEqualObjects(unmanaged.anyDoubleObj.allObjects[0], @3.3);
    unmanaged.anyStringObj = (id)@[@"b"]; 
     uncheckedAssertEqualObjects(unmanaged.anyStringObj.allObjects[0], @"b");
    unmanaged.anyDataObj = (id)@[data(2)]; 
     uncheckedAssertEqualObjects(unmanaged.anyDataObj.allObjects[0], data(2));
    unmanaged.anyDateObj = (id)@[date(2)]; 
     uncheckedAssertEqualObjects(unmanaged.anyDateObj.allObjects[0], date(2));
    unmanaged.anyDecimalObj = (id)@[decimal128(2)]; 
     uncheckedAssertEqualObjects(unmanaged.anyDecimalObj.allObjects[0], decimal128(2));
    unmanaged.anyObjectIdObj = (id)@[objectId(2)]; 
     uncheckedAssertEqualObjects(unmanaged.anyObjectIdObj.allObjects[0], objectId(2));
    unmanaged.anyUUIDObj = (id)@[uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")]; 
     uncheckedAssertEqualObjects(unmanaged.anyUUIDObj.allObjects[0], uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"));
    optUnmanaged.boolObj = (id)@[@NO]; 
     uncheckedAssertEqualObjects(optUnmanaged.boolObj.allObjects[0], @NO);
    optUnmanaged.intObj = (id)@[@2]; 
     uncheckedAssertEqualObjects(optUnmanaged.intObj.allObjects[0], @2);
    optUnmanaged.floatObj = (id)@[@2.2f]; 
     uncheckedAssertEqualObjects(optUnmanaged.floatObj.allObjects[0], @2.2f);
    optUnmanaged.doubleObj = (id)@[@2.2]; 
     uncheckedAssertEqualObjects(optUnmanaged.doubleObj.allObjects[0], @2.2);
    optUnmanaged.stringObj = (id)@[@"a"]; 
     uncheckedAssertEqualObjects(optUnmanaged.stringObj.allObjects[0], @"a");
    optUnmanaged.dataObj = (id)@[data(1)]; 
     uncheckedAssertEqualObjects(optUnmanaged.dataObj.allObjects[0], data(1));
    optUnmanaged.dateObj = (id)@[date(1)]; 
     uncheckedAssertEqualObjects(optUnmanaged.dateObj.allObjects[0], date(1));
    optUnmanaged.decimalObj = (id)@[decimal128(1)]; 
     uncheckedAssertEqualObjects(optUnmanaged.decimalObj.allObjects[0], decimal128(1));
    optUnmanaged.objectIdObj = (id)@[objectId(1)]; 
     uncheckedAssertEqualObjects(optUnmanaged.objectIdObj.allObjects[0], objectId(1));
    optUnmanaged.uuidObj = (id)@[uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")]; 
     uncheckedAssertEqualObjects(optUnmanaged.uuidObj.allObjects[0], uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"));
    managed.boolObj = (id)@[@YES]; 
     uncheckedAssertEqualObjects(managed.boolObj.allObjects[0], @YES);
    managed.intObj = (id)@[@3]; 
     uncheckedAssertEqualObjects(managed.intObj.allObjects[0], @3);
    managed.floatObj = (id)@[@3.3f]; 
     uncheckedAssertEqualObjects(managed.floatObj.allObjects[0], @3.3f);
    managed.doubleObj = (id)@[@3.3]; 
     uncheckedAssertEqualObjects(managed.doubleObj.allObjects[0], @3.3);
    managed.stringObj = (id)@[@"bc"]; 
     uncheckedAssertEqualObjects(managed.stringObj.allObjects[0], @"bc");
    managed.dataObj = (id)@[data(2)]; 
     uncheckedAssertEqualObjects(managed.dataObj.allObjects[0], data(2));
    managed.dateObj = (id)@[date(2)]; 
     uncheckedAssertEqualObjects(managed.dateObj.allObjects[0], date(2));
    managed.decimalObj = (id)@[decimal128(2)]; 
     uncheckedAssertEqualObjects(managed.decimalObj.allObjects[0], decimal128(2));
    managed.objectIdObj = (id)@[objectId(2)]; 
     uncheckedAssertEqualObjects(managed.objectIdObj.allObjects[0], objectId(2));
    managed.uuidObj = (id)@[uuid(@"00000000-0000-0000-0000-000000000000")]; 
     uncheckedAssertEqualObjects(managed.uuidObj.allObjects[0], uuid(@"00000000-0000-0000-0000-000000000000"));
    managed.anyBoolObj = (id)@[@YES]; 
     uncheckedAssertEqualObjects(managed.anyBoolObj.allObjects[0], @YES);
    managed.anyIntObj = (id)@[@3]; 
     uncheckedAssertEqualObjects(managed.anyIntObj.allObjects[0], @3);
    managed.anyFloatObj = (id)@[@3.3f]; 
     uncheckedAssertEqualObjects(managed.anyFloatObj.allObjects[0], @3.3f);
    managed.anyDoubleObj = (id)@[@3.3]; 
     uncheckedAssertEqualObjects(managed.anyDoubleObj.allObjects[0], @3.3);
    managed.anyStringObj = (id)@[@"b"]; 
     uncheckedAssertEqualObjects(managed.anyStringObj.allObjects[0], @"b");
    managed.anyDataObj = (id)@[data(2)]; 
     uncheckedAssertEqualObjects(managed.anyDataObj.allObjects[0], data(2));
    managed.anyDateObj = (id)@[date(2)]; 
     uncheckedAssertEqualObjects(managed.anyDateObj.allObjects[0], date(2));
    managed.anyDecimalObj = (id)@[decimal128(2)]; 
     uncheckedAssertEqualObjects(managed.anyDecimalObj.allObjects[0], decimal128(2));
    managed.anyObjectIdObj = (id)@[objectId(2)]; 
     uncheckedAssertEqualObjects(managed.anyObjectIdObj.allObjects[0], objectId(2));
    managed.anyUUIDObj = (id)@[uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")]; 
     uncheckedAssertEqualObjects(managed.anyUUIDObj.allObjects[0], uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"));
    optManaged.boolObj = (id)@[@NO]; 
     uncheckedAssertEqualObjects(optManaged.boolObj.allObjects[0], @NO);
    optManaged.intObj = (id)@[@2]; 
     uncheckedAssertEqualObjects(optManaged.intObj.allObjects[0], @2);
    optManaged.floatObj = (id)@[@2.2f]; 
     uncheckedAssertEqualObjects(optManaged.floatObj.allObjects[0], @2.2f);
    optManaged.doubleObj = (id)@[@2.2]; 
     uncheckedAssertEqualObjects(optManaged.doubleObj.allObjects[0], @2.2);
    optManaged.stringObj = (id)@[@"a"]; 
     uncheckedAssertEqualObjects(optManaged.stringObj.allObjects[0], @"a");
    optManaged.dataObj = (id)@[data(1)]; 
     uncheckedAssertEqualObjects(optManaged.dataObj.allObjects[0], data(1));
    optManaged.dateObj = (id)@[date(1)]; 
     uncheckedAssertEqualObjects(optManaged.dateObj.allObjects[0], date(1));
    optManaged.decimalObj = (id)@[decimal128(1)]; 
     uncheckedAssertEqualObjects(optManaged.decimalObj.allObjects[0], decimal128(1));
    optManaged.objectIdObj = (id)@[objectId(1)]; 
     uncheckedAssertEqualObjects(optManaged.objectIdObj.allObjects[0], objectId(1));
    optManaged.uuidObj = (id)@[uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")]; 
     uncheckedAssertEqualObjects(optManaged.uuidObj.allObjects[0], uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"));

    // Should replace and not append
    unmanaged.boolObj = (id)@[@NO, @YES]; 
     uncheckedAssertEqualObjects([NSSet setWithArray:[[unmanaged.boolObj valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[@NO, @YES]])); 
    
    unmanaged.intObj = (id)@[@2, @3]; 
     uncheckedAssertEqualObjects([NSSet setWithArray:[[unmanaged.intObj valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[@2, @3]])); 
    
    unmanaged.floatObj = (id)@[@2.2f, @3.3f]; 
     uncheckedAssertEqualObjects([NSSet setWithArray:[[unmanaged.floatObj valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[@2.2f, @3.3f]])); 
    
    unmanaged.doubleObj = (id)@[@2.2, @3.3]; 
     uncheckedAssertEqualObjects([NSSet setWithArray:[[unmanaged.doubleObj valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[@2.2, @3.3]])); 
    
    unmanaged.stringObj = (id)@[@"a", @"bc"]; 
     uncheckedAssertEqualObjects([NSSet setWithArray:[[unmanaged.stringObj valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[@"a", @"bc"]])); 
    
    unmanaged.dataObj = (id)@[data(1), data(2)]; 
     uncheckedAssertEqualObjects([NSSet setWithArray:[[unmanaged.dataObj valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[data(1), data(2)]])); 
    
    unmanaged.dateObj = (id)@[date(1), date(2)]; 
     uncheckedAssertEqualObjects([NSSet setWithArray:[[unmanaged.dateObj valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[date(1), date(2)]])); 
    
    unmanaged.decimalObj = (id)@[decimal128(1), decimal128(2)]; 
     uncheckedAssertEqualObjects([NSSet setWithArray:[[unmanaged.decimalObj valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[decimal128(1), decimal128(2)]])); 
    
    unmanaged.objectIdObj = (id)@[objectId(1), objectId(2)]; 
     uncheckedAssertEqualObjects([NSSet setWithArray:[[unmanaged.objectIdObj valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[objectId(1), objectId(2)]])); 
    
    unmanaged.uuidObj = (id)@[uuid(@"00000000-0000-0000-0000-000000000000"), uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")]; 
     uncheckedAssertEqualObjects([NSSet setWithArray:[[unmanaged.uuidObj valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[uuid(@"00000000-0000-0000-0000-000000000000"), uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")]])); 
    
    unmanaged.anyBoolObj = (id)@[@NO, @YES]; 
     uncheckedAssertEqualObjects([NSSet setWithArray:[[unmanaged.anyBoolObj valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[@NO, @YES]])); 
    
    unmanaged.anyIntObj = (id)@[@2, @3]; 
     uncheckedAssertEqualObjects([NSSet setWithArray:[[unmanaged.anyIntObj valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[@2, @3]])); 
    
    unmanaged.anyFloatObj = (id)@[@2.2f, @3.3f]; 
     uncheckedAssertEqualObjects([NSSet setWithArray:[[unmanaged.anyFloatObj valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[@2.2f, @3.3f]])); 
    
    unmanaged.anyDoubleObj = (id)@[@2.2, @3.3]; 
     uncheckedAssertEqualObjects([NSSet setWithArray:[[unmanaged.anyDoubleObj valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[@2.2, @3.3]])); 
    
    unmanaged.anyStringObj = (id)@[@"a", @"b"]; 
     uncheckedAssertEqualObjects([NSSet setWithArray:[[unmanaged.anyStringObj valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[@"a", @"b"]])); 
    
    unmanaged.anyDataObj = (id)@[data(1), data(2)]; 
     uncheckedAssertEqualObjects([NSSet setWithArray:[[unmanaged.anyDataObj valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[data(1), data(2)]])); 
    
    unmanaged.anyDateObj = (id)@[date(1), date(2)]; 
     uncheckedAssertEqualObjects([NSSet setWithArray:[[unmanaged.anyDateObj valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[date(1), date(2)]])); 
    
    unmanaged.anyDecimalObj = (id)@[decimal128(1), decimal128(2)]; 
     uncheckedAssertEqualObjects([NSSet setWithArray:[[unmanaged.anyDecimalObj valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[decimal128(1), decimal128(2)]])); 
    
    unmanaged.anyObjectIdObj = (id)@[objectId(1), objectId(2)]; 
     uncheckedAssertEqualObjects([NSSet setWithArray:[[unmanaged.anyObjectIdObj valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[objectId(1), objectId(2)]])); 
    
    unmanaged.anyUUIDObj = (id)@[uuid(@"00000000-0000-0000-0000-000000000000"), uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")]; 
     uncheckedAssertEqualObjects([NSSet setWithArray:[[unmanaged.anyUUIDObj valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[uuid(@"00000000-0000-0000-0000-000000000000"), uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")]])); 
    
    optUnmanaged.boolObj = (id)@[NSNull.null, @NO, @YES]; 
     uncheckedAssertEqualObjects([NSSet setWithArray:[[optUnmanaged.boolObj valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[NSNull.null, @NO, @YES]])); 
    
    optUnmanaged.intObj = (id)@[NSNull.null, @2, @3]; 
     uncheckedAssertEqualObjects([NSSet setWithArray:[[optUnmanaged.intObj valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[NSNull.null, @2, @3]])); 
    
    optUnmanaged.floatObj = (id)@[NSNull.null, @2.2f, @3.3f]; 
     uncheckedAssertEqualObjects([NSSet setWithArray:[[optUnmanaged.floatObj valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[NSNull.null, @2.2f, @3.3f]])); 
    
    optUnmanaged.doubleObj = (id)@[NSNull.null, @2.2, @3.3]; 
     uncheckedAssertEqualObjects([NSSet setWithArray:[[optUnmanaged.doubleObj valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[NSNull.null, @2.2, @3.3]])); 
    
    optUnmanaged.stringObj = (id)@[NSNull.null, @"a", @"bc"]; 
     uncheckedAssertEqualObjects([NSSet setWithArray:[[optUnmanaged.stringObj valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[NSNull.null, @"a", @"bc"]])); 
    
    optUnmanaged.dataObj = (id)@[NSNull.null, data(1), data(2)]; 
     uncheckedAssertEqualObjects([NSSet setWithArray:[[optUnmanaged.dataObj valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[NSNull.null, data(1), data(2)]])); 
    
    optUnmanaged.dateObj = (id)@[NSNull.null, date(1), date(2)]; 
     uncheckedAssertEqualObjects([NSSet setWithArray:[[optUnmanaged.dateObj valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[NSNull.null, date(1), date(2)]])); 
    
    optUnmanaged.decimalObj = (id)@[NSNull.null, decimal128(1), decimal128(2)]; 
     uncheckedAssertEqualObjects([NSSet setWithArray:[[optUnmanaged.decimalObj valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[NSNull.null, decimal128(1), decimal128(2)]])); 
    
    optUnmanaged.objectIdObj = (id)@[NSNull.null, objectId(1), objectId(2)]; 
     uncheckedAssertEqualObjects([NSSet setWithArray:[[optUnmanaged.objectIdObj valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[NSNull.null, objectId(1), objectId(2)]])); 
    
    optUnmanaged.uuidObj = (id)@[NSNull.null, uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"), uuid(@"00000000-0000-0000-0000-000000000000")]; 
     uncheckedAssertEqualObjects([NSSet setWithArray:[[optUnmanaged.uuidObj valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[NSNull.null, uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"), uuid(@"00000000-0000-0000-0000-000000000000")]])); 
    
    managed.boolObj = (id)@[@NO, @YES]; 
     uncheckedAssertEqualObjects([NSSet setWithArray:[[managed.boolObj valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[@NO, @YES]])); 
    
    managed.intObj = (id)@[@2, @3]; 
     uncheckedAssertEqualObjects([NSSet setWithArray:[[managed.intObj valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[@2, @3]])); 
    
    managed.floatObj = (id)@[@2.2f, @3.3f]; 
     uncheckedAssertEqualObjects([NSSet setWithArray:[[managed.floatObj valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[@2.2f, @3.3f]])); 
    
    managed.doubleObj = (id)@[@2.2, @3.3]; 
     uncheckedAssertEqualObjects([NSSet setWithArray:[[managed.doubleObj valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[@2.2, @3.3]])); 
    
    managed.stringObj = (id)@[@"a", @"bc"]; 
     uncheckedAssertEqualObjects([NSSet setWithArray:[[managed.stringObj valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[@"a", @"bc"]])); 
    
    managed.dataObj = (id)@[data(1), data(2)]; 
     uncheckedAssertEqualObjects([NSSet setWithArray:[[managed.dataObj valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[data(1), data(2)]])); 
    
    managed.dateObj = (id)@[date(1), date(2)]; 
     uncheckedAssertEqualObjects([NSSet setWithArray:[[managed.dateObj valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[date(1), date(2)]])); 
    
    managed.decimalObj = (id)@[decimal128(1), decimal128(2)]; 
     uncheckedAssertEqualObjects([NSSet setWithArray:[[managed.decimalObj valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[decimal128(1), decimal128(2)]])); 
    
    managed.objectIdObj = (id)@[objectId(1), objectId(2)]; 
     uncheckedAssertEqualObjects([NSSet setWithArray:[[managed.objectIdObj valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[objectId(1), objectId(2)]])); 
    
    managed.uuidObj = (id)@[uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"), uuid(@"00000000-0000-0000-0000-000000000000")]; 
     uncheckedAssertEqualObjects([NSSet setWithArray:[[managed.uuidObj valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"), uuid(@"00000000-0000-0000-0000-000000000000")]])); 
    
    managed.anyBoolObj = (id)@[@NO, @YES]; 
     uncheckedAssertEqualObjects([NSSet setWithArray:[[managed.anyBoolObj valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[@NO, @YES]])); 
    
    managed.anyIntObj = (id)@[@2, @3]; 
     uncheckedAssertEqualObjects([NSSet setWithArray:[[managed.anyIntObj valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[@2, @3]])); 
    
    managed.anyFloatObj = (id)@[@2.2f, @3.3f]; 
     uncheckedAssertEqualObjects([NSSet setWithArray:[[managed.anyFloatObj valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[@2.2f, @3.3f]])); 
    
    managed.anyDoubleObj = (id)@[@2.2, @3.3]; 
     uncheckedAssertEqualObjects([NSSet setWithArray:[[managed.anyDoubleObj valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[@2.2, @3.3]])); 
    
    managed.anyStringObj = (id)@[@"a", @"b"]; 
     uncheckedAssertEqualObjects([NSSet setWithArray:[[managed.anyStringObj valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[@"a", @"b"]])); 
    
    managed.anyDataObj = (id)@[data(1), data(2)]; 
     uncheckedAssertEqualObjects([NSSet setWithArray:[[managed.anyDataObj valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[data(1), data(2)]])); 
    
    managed.anyDateObj = (id)@[date(1), date(2)]; 
     uncheckedAssertEqualObjects([NSSet setWithArray:[[managed.anyDateObj valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[date(1), date(2)]])); 
    
    managed.anyDecimalObj = (id)@[decimal128(1), decimal128(2)]; 
     uncheckedAssertEqualObjects([NSSet setWithArray:[[managed.anyDecimalObj valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[decimal128(1), decimal128(2)]])); 
    
    managed.anyObjectIdObj = (id)@[objectId(1), objectId(2)]; 
     uncheckedAssertEqualObjects([NSSet setWithArray:[[managed.anyObjectIdObj valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[objectId(1), objectId(2)]])); 
    
    managed.anyUUIDObj = (id)@[uuid(@"00000000-0000-0000-0000-000000000000"), uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")]; 
     uncheckedAssertEqualObjects([NSSet setWithArray:[[managed.anyUUIDObj valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[uuid(@"00000000-0000-0000-0000-000000000000"), uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")]])); 
    
    optManaged.boolObj = (id)@[NSNull.null, @NO, @YES]; 
     uncheckedAssertEqualObjects([NSSet setWithArray:[[optManaged.boolObj valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[NSNull.null, @NO, @YES]])); 
    
    optManaged.intObj = (id)@[NSNull.null, @2, @3]; 
     uncheckedAssertEqualObjects([NSSet setWithArray:[[optManaged.intObj valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[NSNull.null, @2, @3]])); 
    
    optManaged.floatObj = (id)@[NSNull.null, @2.2f, @3.3f]; 
     uncheckedAssertEqualObjects([NSSet setWithArray:[[optManaged.floatObj valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[NSNull.null, @2.2f, @3.3f]])); 
    
    optManaged.doubleObj = (id)@[NSNull.null, @2.2, @3.3]; 
     uncheckedAssertEqualObjects([NSSet setWithArray:[[optManaged.doubleObj valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[NSNull.null, @2.2, @3.3]])); 
    
    optManaged.stringObj = (id)@[NSNull.null, @"a", @"bc"]; 
     uncheckedAssertEqualObjects([NSSet setWithArray:[[optManaged.stringObj valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[NSNull.null, @"a", @"bc"]])); 
    
    optManaged.dataObj = (id)@[NSNull.null, data(1), data(2)]; 
     uncheckedAssertEqualObjects([NSSet setWithArray:[[optManaged.dataObj valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[NSNull.null, data(1), data(2)]])); 
    
    optManaged.dateObj = (id)@[NSNull.null, date(1), date(2)]; 
     uncheckedAssertEqualObjects([NSSet setWithArray:[[optManaged.dateObj valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[NSNull.null, date(1), date(2)]])); 
    
    optManaged.decimalObj = (id)@[NSNull.null, decimal128(1), decimal128(2)]; 
     uncheckedAssertEqualObjects([NSSet setWithArray:[[optManaged.decimalObj valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[NSNull.null, decimal128(1), decimal128(2)]])); 
    
    optManaged.objectIdObj = (id)@[NSNull.null, objectId(1), objectId(2)]; 
     uncheckedAssertEqualObjects([NSSet setWithArray:[[optManaged.objectIdObj valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[NSNull.null, objectId(1), objectId(2)]])); 
    
    optManaged.uuidObj = (id)@[NSNull.null, uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"), uuid(@"00000000-0000-0000-0000-000000000000")]; 
     uncheckedAssertEqualObjects([NSSet setWithArray:[[optManaged.uuidObj valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[NSNull.null, uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"), uuid(@"00000000-0000-0000-0000-000000000000")]])); 
    

    // Should not clear the set
    unmanaged.boolObj = unmanaged.boolObj; 
     uncheckedAssertEqualObjects([NSSet setWithArray:[[unmanaged.boolObj valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[@NO, @YES]])); 
    
    unmanaged.intObj = unmanaged.intObj; 
     uncheckedAssertEqualObjects([NSSet setWithArray:[[unmanaged.intObj valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[@2, @3]])); 
    
    unmanaged.floatObj = unmanaged.floatObj; 
     uncheckedAssertEqualObjects([NSSet setWithArray:[[unmanaged.floatObj valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[@2.2f, @3.3f]])); 
    
    unmanaged.doubleObj = unmanaged.doubleObj; 
     uncheckedAssertEqualObjects([NSSet setWithArray:[[unmanaged.doubleObj valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[@2.2, @3.3]])); 
    
    unmanaged.stringObj = unmanaged.stringObj; 
     uncheckedAssertEqualObjects([NSSet setWithArray:[[unmanaged.stringObj valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[@"a", @"bc"]])); 
    
    unmanaged.dataObj = unmanaged.dataObj; 
     uncheckedAssertEqualObjects([NSSet setWithArray:[[unmanaged.dataObj valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[data(1), data(2)]])); 
    
    unmanaged.dateObj = unmanaged.dateObj; 
     uncheckedAssertEqualObjects([NSSet setWithArray:[[unmanaged.dateObj valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[date(1), date(2)]])); 
    
    unmanaged.decimalObj = unmanaged.decimalObj; 
     uncheckedAssertEqualObjects([NSSet setWithArray:[[unmanaged.decimalObj valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[decimal128(1), decimal128(2)]])); 
    
    unmanaged.objectIdObj = unmanaged.objectIdObj; 
     uncheckedAssertEqualObjects([NSSet setWithArray:[[unmanaged.objectIdObj valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[objectId(1), objectId(2)]])); 
    
    unmanaged.uuidObj = unmanaged.uuidObj; 
     uncheckedAssertEqualObjects([NSSet setWithArray:[[unmanaged.uuidObj valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[uuid(@"00000000-0000-0000-0000-000000000000"), uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")]])); 
    
    unmanaged.anyBoolObj = unmanaged.anyBoolObj; 
     uncheckedAssertEqualObjects([NSSet setWithArray:[[unmanaged.anyBoolObj valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[@NO, @YES]])); 
    
    unmanaged.anyIntObj = unmanaged.anyIntObj; 
     uncheckedAssertEqualObjects([NSSet setWithArray:[[unmanaged.anyIntObj valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[@2, @3]])); 
    
    unmanaged.anyFloatObj = unmanaged.anyFloatObj; 
     uncheckedAssertEqualObjects([NSSet setWithArray:[[unmanaged.anyFloatObj valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[@2.2f, @3.3f]])); 
    
    unmanaged.anyDoubleObj = unmanaged.anyDoubleObj; 
     uncheckedAssertEqualObjects([NSSet setWithArray:[[unmanaged.anyDoubleObj valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[@2.2, @3.3]])); 
    
    unmanaged.anyStringObj = unmanaged.anyStringObj; 
     uncheckedAssertEqualObjects([NSSet setWithArray:[[unmanaged.anyStringObj valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[@"a", @"b"]])); 
    
    unmanaged.anyDataObj = unmanaged.anyDataObj; 
     uncheckedAssertEqualObjects([NSSet setWithArray:[[unmanaged.anyDataObj valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[data(1), data(2)]])); 
    
    unmanaged.anyDateObj = unmanaged.anyDateObj; 
     uncheckedAssertEqualObjects([NSSet setWithArray:[[unmanaged.anyDateObj valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[date(1), date(2)]])); 
    
    unmanaged.anyDecimalObj = unmanaged.anyDecimalObj; 
     uncheckedAssertEqualObjects([NSSet setWithArray:[[unmanaged.anyDecimalObj valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[decimal128(1), decimal128(2)]])); 
    
    unmanaged.anyObjectIdObj = unmanaged.anyObjectIdObj; 
     uncheckedAssertEqualObjects([NSSet setWithArray:[[unmanaged.anyObjectIdObj valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[objectId(1), objectId(2)]])); 
    
    unmanaged.anyUUIDObj = unmanaged.anyUUIDObj; 
     uncheckedAssertEqualObjects([NSSet setWithArray:[[unmanaged.anyUUIDObj valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[uuid(@"00000000-0000-0000-0000-000000000000"), uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")]])); 
    
    optUnmanaged.boolObj = optUnmanaged.boolObj; 
     uncheckedAssertEqualObjects([NSSet setWithArray:[[optUnmanaged.boolObj valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[NSNull.null, @NO, @YES]])); 
    
    optUnmanaged.intObj = optUnmanaged.intObj; 
     uncheckedAssertEqualObjects([NSSet setWithArray:[[optUnmanaged.intObj valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[NSNull.null, @2, @3]])); 
    
    optUnmanaged.floatObj = optUnmanaged.floatObj; 
     uncheckedAssertEqualObjects([NSSet setWithArray:[[optUnmanaged.floatObj valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[NSNull.null, @2.2f, @3.3f]])); 
    
    optUnmanaged.doubleObj = optUnmanaged.doubleObj; 
     uncheckedAssertEqualObjects([NSSet setWithArray:[[optUnmanaged.doubleObj valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[NSNull.null, @2.2, @3.3]])); 
    
    optUnmanaged.stringObj = optUnmanaged.stringObj; 
     uncheckedAssertEqualObjects([NSSet setWithArray:[[optUnmanaged.stringObj valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[NSNull.null, @"a", @"bc"]])); 
    
    optUnmanaged.dataObj = optUnmanaged.dataObj; 
     uncheckedAssertEqualObjects([NSSet setWithArray:[[optUnmanaged.dataObj valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[NSNull.null, data(1), data(2)]])); 
    
    optUnmanaged.dateObj = optUnmanaged.dateObj; 
     uncheckedAssertEqualObjects([NSSet setWithArray:[[optUnmanaged.dateObj valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[NSNull.null, date(1), date(2)]])); 
    
    optUnmanaged.decimalObj = optUnmanaged.decimalObj; 
     uncheckedAssertEqualObjects([NSSet setWithArray:[[optUnmanaged.decimalObj valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[NSNull.null, decimal128(1), decimal128(2)]])); 
    
    optUnmanaged.objectIdObj = optUnmanaged.objectIdObj; 
     uncheckedAssertEqualObjects([NSSet setWithArray:[[optUnmanaged.objectIdObj valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[NSNull.null, objectId(1), objectId(2)]])); 
    
    optUnmanaged.uuidObj = optUnmanaged.uuidObj; 
     uncheckedAssertEqualObjects([NSSet setWithArray:[[optUnmanaged.uuidObj valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[NSNull.null, uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"), uuid(@"00000000-0000-0000-0000-000000000000")]])); 
    
    managed.boolObj = managed.boolObj; 
     uncheckedAssertEqualObjects([NSSet setWithArray:[[managed.boolObj valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[@NO, @YES]])); 
    
    managed.intObj = managed.intObj; 
     uncheckedAssertEqualObjects([NSSet setWithArray:[[managed.intObj valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[@2, @3]])); 
    
    managed.floatObj = managed.floatObj; 
     uncheckedAssertEqualObjects([NSSet setWithArray:[[managed.floatObj valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[@2.2f, @3.3f]])); 
    
    managed.doubleObj = managed.doubleObj; 
     uncheckedAssertEqualObjects([NSSet setWithArray:[[managed.doubleObj valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[@2.2, @3.3]])); 
    
    managed.stringObj = managed.stringObj; 
     uncheckedAssertEqualObjects([NSSet setWithArray:[[managed.stringObj valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[@"a", @"bc"]])); 
    
    managed.dataObj = managed.dataObj; 
     uncheckedAssertEqualObjects([NSSet setWithArray:[[managed.dataObj valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[data(1), data(2)]])); 
    
    managed.dateObj = managed.dateObj; 
     uncheckedAssertEqualObjects([NSSet setWithArray:[[managed.dateObj valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[date(1), date(2)]])); 
    
    managed.decimalObj = managed.decimalObj; 
     uncheckedAssertEqualObjects([NSSet setWithArray:[[managed.decimalObj valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[decimal128(1), decimal128(2)]])); 
    
    managed.objectIdObj = managed.objectIdObj; 
     uncheckedAssertEqualObjects([NSSet setWithArray:[[managed.objectIdObj valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[objectId(1), objectId(2)]])); 
    
    managed.uuidObj = managed.uuidObj; 
     uncheckedAssertEqualObjects([NSSet setWithArray:[[managed.uuidObj valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"), uuid(@"00000000-0000-0000-0000-000000000000")]])); 
    
    managed.anyBoolObj = managed.anyBoolObj; 
     uncheckedAssertEqualObjects([NSSet setWithArray:[[managed.anyBoolObj valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[@NO, @YES]])); 
    
    managed.anyIntObj = managed.anyIntObj; 
     uncheckedAssertEqualObjects([NSSet setWithArray:[[managed.anyIntObj valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[@2, @3]])); 
    
    managed.anyFloatObj = managed.anyFloatObj; 
     uncheckedAssertEqualObjects([NSSet setWithArray:[[managed.anyFloatObj valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[@2.2f, @3.3f]])); 
    
    managed.anyDoubleObj = managed.anyDoubleObj; 
     uncheckedAssertEqualObjects([NSSet setWithArray:[[managed.anyDoubleObj valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[@2.2, @3.3]])); 
    
    managed.anyStringObj = managed.anyStringObj; 
     uncheckedAssertEqualObjects([NSSet setWithArray:[[managed.anyStringObj valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[@"a", @"b"]])); 
    
    managed.anyDataObj = managed.anyDataObj; 
     uncheckedAssertEqualObjects([NSSet setWithArray:[[managed.anyDataObj valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[data(1), data(2)]])); 
    
    managed.anyDateObj = managed.anyDateObj; 
     uncheckedAssertEqualObjects([NSSet setWithArray:[[managed.anyDateObj valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[date(1), date(2)]])); 
    
    managed.anyDecimalObj = managed.anyDecimalObj; 
     uncheckedAssertEqualObjects([NSSet setWithArray:[[managed.anyDecimalObj valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[decimal128(1), decimal128(2)]])); 
    
    managed.anyObjectIdObj = managed.anyObjectIdObj; 
     uncheckedAssertEqualObjects([NSSet setWithArray:[[managed.anyObjectIdObj valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[objectId(1), objectId(2)]])); 
    
    managed.anyUUIDObj = managed.anyUUIDObj; 
     uncheckedAssertEqualObjects([NSSet setWithArray:[[managed.anyUUIDObj valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[uuid(@"00000000-0000-0000-0000-000000000000"), uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")]])); 
    
    optManaged.boolObj = optManaged.boolObj; 
     uncheckedAssertEqualObjects([NSSet setWithArray:[[optManaged.boolObj valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[NSNull.null, @NO, @YES]])); 
    
    optManaged.intObj = optManaged.intObj; 
     uncheckedAssertEqualObjects([NSSet setWithArray:[[optManaged.intObj valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[NSNull.null, @2, @3]])); 
    
    optManaged.floatObj = optManaged.floatObj; 
     uncheckedAssertEqualObjects([NSSet setWithArray:[[optManaged.floatObj valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[NSNull.null, @2.2f, @3.3f]])); 
    
    optManaged.doubleObj = optManaged.doubleObj; 
     uncheckedAssertEqualObjects([NSSet setWithArray:[[optManaged.doubleObj valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[NSNull.null, @2.2, @3.3]])); 
    
    optManaged.stringObj = optManaged.stringObj; 
     uncheckedAssertEqualObjects([NSSet setWithArray:[[optManaged.stringObj valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[NSNull.null, @"a", @"bc"]])); 
    
    optManaged.dataObj = optManaged.dataObj; 
     uncheckedAssertEqualObjects([NSSet setWithArray:[[optManaged.dataObj valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[NSNull.null, data(1), data(2)]])); 
    
    optManaged.dateObj = optManaged.dateObj; 
     uncheckedAssertEqualObjects([NSSet setWithArray:[[optManaged.dateObj valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[NSNull.null, date(1), date(2)]])); 
    
    optManaged.decimalObj = optManaged.decimalObj; 
     uncheckedAssertEqualObjects([NSSet setWithArray:[[optManaged.decimalObj valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[NSNull.null, decimal128(1), decimal128(2)]])); 
    
    optManaged.objectIdObj = optManaged.objectIdObj; 
     uncheckedAssertEqualObjects([NSSet setWithArray:[[optManaged.objectIdObj valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[NSNull.null, objectId(1), objectId(2)]])); 
    
    optManaged.uuidObj = optManaged.uuidObj; 
     uncheckedAssertEqualObjects([NSSet setWithArray:[[optManaged.uuidObj valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[NSNull.null, uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"), uuid(@"00000000-0000-0000-0000-000000000000")]])); 
    

    [unmanaged.intObj removeAllObjects];
    unmanaged.intObj = managed.intObj;
    uncheckedAssertEqualObjects([NSSet setWithArray:[[unmanaged.intObj valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[@2, @3]]));

    [managed.intObj removeAllObjects];
    managed.intObj = unmanaged.intObj;
    uncheckedAssertEqualObjects([NSSet setWithArray:[[managed.intObj valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[@2, @3]]));
}

- (void)testDynamicAssignment {
    unmanaged[@"boolObj"] = (id)@[@YES]; 
     uncheckedAssertEqualObjects(((RLMSet *)unmanaged[@"boolObj"]).allObjects[0], @YES);
    unmanaged[@"intObj"] = (id)@[@3]; 
     uncheckedAssertEqualObjects(((RLMSet *)unmanaged[@"intObj"]).allObjects[0], @3);
    unmanaged[@"floatObj"] = (id)@[@3.3f]; 
     uncheckedAssertEqualObjects(((RLMSet *)unmanaged[@"floatObj"]).allObjects[0], @3.3f);
    unmanaged[@"doubleObj"] = (id)@[@3.3]; 
     uncheckedAssertEqualObjects(((RLMSet *)unmanaged[@"doubleObj"]).allObjects[0], @3.3);
    unmanaged[@"stringObj"] = (id)@[@"bc"]; 
     uncheckedAssertEqualObjects(((RLMSet *)unmanaged[@"stringObj"]).allObjects[0], @"bc");
    unmanaged[@"dataObj"] = (id)@[data(2)]; 
     uncheckedAssertEqualObjects(((RLMSet *)unmanaged[@"dataObj"]).allObjects[0], data(2));
    unmanaged[@"dateObj"] = (id)@[date(2)]; 
     uncheckedAssertEqualObjects(((RLMSet *)unmanaged[@"dateObj"]).allObjects[0], date(2));
    unmanaged[@"decimalObj"] = (id)@[decimal128(2)]; 
     uncheckedAssertEqualObjects(((RLMSet *)unmanaged[@"decimalObj"]).allObjects[0], decimal128(2));
    unmanaged[@"objectIdObj"] = (id)@[objectId(2)]; 
     uncheckedAssertEqualObjects(((RLMSet *)unmanaged[@"objectIdObj"]).allObjects[0], objectId(2));
    unmanaged[@"uuidObj"] = (id)@[uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")]; 
     uncheckedAssertEqualObjects(((RLMSet *)unmanaged[@"uuidObj"]).allObjects[0], uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"));
    unmanaged[@"anyBoolObj"] = (id)@[@YES]; 
     uncheckedAssertEqualObjects(((RLMSet *)unmanaged[@"anyBoolObj"]).allObjects[0], @YES);
    unmanaged[@"anyIntObj"] = (id)@[@3]; 
     uncheckedAssertEqualObjects(((RLMSet *)unmanaged[@"anyIntObj"]).allObjects[0], @3);
    unmanaged[@"anyFloatObj"] = (id)@[@3.3f]; 
     uncheckedAssertEqualObjects(((RLMSet *)unmanaged[@"anyFloatObj"]).allObjects[0], @3.3f);
    unmanaged[@"anyDoubleObj"] = (id)@[@3.3]; 
     uncheckedAssertEqualObjects(((RLMSet *)unmanaged[@"anyDoubleObj"]).allObjects[0], @3.3);
    unmanaged[@"anyStringObj"] = (id)@[@"b"]; 
     uncheckedAssertEqualObjects(((RLMSet *)unmanaged[@"anyStringObj"]).allObjects[0], @"b");
    unmanaged[@"anyDataObj"] = (id)@[data(2)]; 
     uncheckedAssertEqualObjects(((RLMSet *)unmanaged[@"anyDataObj"]).allObjects[0], data(2));
    unmanaged[@"anyDateObj"] = (id)@[date(2)]; 
     uncheckedAssertEqualObjects(((RLMSet *)unmanaged[@"anyDateObj"]).allObjects[0], date(2));
    unmanaged[@"anyDecimalObj"] = (id)@[decimal128(2)]; 
     uncheckedAssertEqualObjects(((RLMSet *)unmanaged[@"anyDecimalObj"]).allObjects[0], decimal128(2));
    unmanaged[@"anyObjectIdObj"] = (id)@[objectId(2)]; 
     uncheckedAssertEqualObjects(((RLMSet *)unmanaged[@"anyObjectIdObj"]).allObjects[0], objectId(2));
    unmanaged[@"anyUUIDObj"] = (id)@[uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")]; 
     uncheckedAssertEqualObjects(((RLMSet *)unmanaged[@"anyUUIDObj"]).allObjects[0], uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"));
    optUnmanaged[@"boolObj"] = (id)@[@NO]; 
     uncheckedAssertEqualObjects(((RLMSet *)optUnmanaged[@"boolObj"]).allObjects[0], @NO);
    optUnmanaged[@"intObj"] = (id)@[@2]; 
     uncheckedAssertEqualObjects(((RLMSet *)optUnmanaged[@"intObj"]).allObjects[0], @2);
    optUnmanaged[@"floatObj"] = (id)@[@2.2f]; 
     uncheckedAssertEqualObjects(((RLMSet *)optUnmanaged[@"floatObj"]).allObjects[0], @2.2f);
    optUnmanaged[@"doubleObj"] = (id)@[@2.2]; 
     uncheckedAssertEqualObjects(((RLMSet *)optUnmanaged[@"doubleObj"]).allObjects[0], @2.2);
    optUnmanaged[@"stringObj"] = (id)@[@"a"]; 
     uncheckedAssertEqualObjects(((RLMSet *)optUnmanaged[@"stringObj"]).allObjects[0], @"a");
    optUnmanaged[@"dataObj"] = (id)@[data(1)]; 
     uncheckedAssertEqualObjects(((RLMSet *)optUnmanaged[@"dataObj"]).allObjects[0], data(1));
    optUnmanaged[@"dateObj"] = (id)@[date(1)]; 
     uncheckedAssertEqualObjects(((RLMSet *)optUnmanaged[@"dateObj"]).allObjects[0], date(1));
    optUnmanaged[@"decimalObj"] = (id)@[decimal128(1)]; 
     uncheckedAssertEqualObjects(((RLMSet *)optUnmanaged[@"decimalObj"]).allObjects[0], decimal128(1));
    optUnmanaged[@"objectIdObj"] = (id)@[objectId(1)]; 
     uncheckedAssertEqualObjects(((RLMSet *)optUnmanaged[@"objectIdObj"]).allObjects[0], objectId(1));
    optUnmanaged[@"uuidObj"] = (id)@[uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")]; 
     uncheckedAssertEqualObjects(((RLMSet *)optUnmanaged[@"uuidObj"]).allObjects[0], uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"));
    managed[@"boolObj"] = (id)@[@YES]; 
     uncheckedAssertEqualObjects(((RLMSet *)managed[@"boolObj"]).allObjects[0], @YES);
    managed[@"intObj"] = (id)@[@3]; 
     uncheckedAssertEqualObjects(((RLMSet *)managed[@"intObj"]).allObjects[0], @3);
    managed[@"floatObj"] = (id)@[@3.3f]; 
     uncheckedAssertEqualObjects(((RLMSet *)managed[@"floatObj"]).allObjects[0], @3.3f);
    managed[@"doubleObj"] = (id)@[@3.3]; 
     uncheckedAssertEqualObjects(((RLMSet *)managed[@"doubleObj"]).allObjects[0], @3.3);
    managed[@"stringObj"] = (id)@[@"bc"]; 
     uncheckedAssertEqualObjects(((RLMSet *)managed[@"stringObj"]).allObjects[0], @"bc");
    managed[@"dataObj"] = (id)@[data(2)]; 
     uncheckedAssertEqualObjects(((RLMSet *)managed[@"dataObj"]).allObjects[0], data(2));
    managed[@"dateObj"] = (id)@[date(2)]; 
     uncheckedAssertEqualObjects(((RLMSet *)managed[@"dateObj"]).allObjects[0], date(2));
    managed[@"decimalObj"] = (id)@[decimal128(2)]; 
     uncheckedAssertEqualObjects(((RLMSet *)managed[@"decimalObj"]).allObjects[0], decimal128(2));
    managed[@"objectIdObj"] = (id)@[objectId(2)]; 
     uncheckedAssertEqualObjects(((RLMSet *)managed[@"objectIdObj"]).allObjects[0], objectId(2));
    managed[@"uuidObj"] = (id)@[uuid(@"00000000-0000-0000-0000-000000000000")]; 
     uncheckedAssertEqualObjects(((RLMSet *)managed[@"uuidObj"]).allObjects[0], uuid(@"00000000-0000-0000-0000-000000000000"));
    managed[@"anyBoolObj"] = (id)@[@YES]; 
     uncheckedAssertEqualObjects(((RLMSet *)managed[@"anyBoolObj"]).allObjects[0], @YES);
    managed[@"anyIntObj"] = (id)@[@3]; 
     uncheckedAssertEqualObjects(((RLMSet *)managed[@"anyIntObj"]).allObjects[0], @3);
    managed[@"anyFloatObj"] = (id)@[@3.3f]; 
     uncheckedAssertEqualObjects(((RLMSet *)managed[@"anyFloatObj"]).allObjects[0], @3.3f);
    managed[@"anyDoubleObj"] = (id)@[@3.3]; 
     uncheckedAssertEqualObjects(((RLMSet *)managed[@"anyDoubleObj"]).allObjects[0], @3.3);
    managed[@"anyStringObj"] = (id)@[@"b"]; 
     uncheckedAssertEqualObjects(((RLMSet *)managed[@"anyStringObj"]).allObjects[0], @"b");
    managed[@"anyDataObj"] = (id)@[data(2)]; 
     uncheckedAssertEqualObjects(((RLMSet *)managed[@"anyDataObj"]).allObjects[0], data(2));
    managed[@"anyDateObj"] = (id)@[date(2)]; 
     uncheckedAssertEqualObjects(((RLMSet *)managed[@"anyDateObj"]).allObjects[0], date(2));
    managed[@"anyDecimalObj"] = (id)@[decimal128(2)]; 
     uncheckedAssertEqualObjects(((RLMSet *)managed[@"anyDecimalObj"]).allObjects[0], decimal128(2));
    managed[@"anyObjectIdObj"] = (id)@[objectId(2)]; 
     uncheckedAssertEqualObjects(((RLMSet *)managed[@"anyObjectIdObj"]).allObjects[0], objectId(2));
    managed[@"anyUUIDObj"] = (id)@[uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")]; 
     uncheckedAssertEqualObjects(((RLMSet *)managed[@"anyUUIDObj"]).allObjects[0], uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"));
    optManaged[@"boolObj"] = (id)@[@NO]; 
     uncheckedAssertEqualObjects(((RLMSet *)optManaged[@"boolObj"]).allObjects[0], @NO);
    optManaged[@"intObj"] = (id)@[@2]; 
     uncheckedAssertEqualObjects(((RLMSet *)optManaged[@"intObj"]).allObjects[0], @2);
    optManaged[@"floatObj"] = (id)@[@2.2f]; 
     uncheckedAssertEqualObjects(((RLMSet *)optManaged[@"floatObj"]).allObjects[0], @2.2f);
    optManaged[@"doubleObj"] = (id)@[@2.2]; 
     uncheckedAssertEqualObjects(((RLMSet *)optManaged[@"doubleObj"]).allObjects[0], @2.2);
    optManaged[@"stringObj"] = (id)@[@"a"]; 
     uncheckedAssertEqualObjects(((RLMSet *)optManaged[@"stringObj"]).allObjects[0], @"a");
    optManaged[@"dataObj"] = (id)@[data(1)]; 
     uncheckedAssertEqualObjects(((RLMSet *)optManaged[@"dataObj"]).allObjects[0], data(1));
    optManaged[@"dateObj"] = (id)@[date(1)]; 
     uncheckedAssertEqualObjects(((RLMSet *)optManaged[@"dateObj"]).allObjects[0], date(1));
    optManaged[@"decimalObj"] = (id)@[decimal128(1)]; 
     uncheckedAssertEqualObjects(((RLMSet *)optManaged[@"decimalObj"]).allObjects[0], decimal128(1));
    optManaged[@"objectIdObj"] = (id)@[objectId(1)]; 
     uncheckedAssertEqualObjects(((RLMSet *)optManaged[@"objectIdObj"]).allObjects[0], objectId(1));
    optManaged[@"uuidObj"] = (id)@[uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")]; 
     uncheckedAssertEqualObjects(((RLMSet *)optManaged[@"uuidObj"]).allObjects[0], uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"));

    // Should replace and not append
    unmanaged[@"boolObj"] = (id)@[@NO, @YES]; 
     uncheckedAssertEqualObjects([NSSet setWithArray:[[unmanaged[@"boolObj"] valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[@NO, @YES]])); 
    
    unmanaged[@"intObj"] = (id)@[@2, @3]; 
     uncheckedAssertEqualObjects([NSSet setWithArray:[[unmanaged[@"intObj"] valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[@2, @3]])); 
    
    unmanaged[@"floatObj"] = (id)@[@2.2f, @3.3f]; 
     uncheckedAssertEqualObjects([NSSet setWithArray:[[unmanaged[@"floatObj"] valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[@2.2f, @3.3f]])); 
    
    unmanaged[@"doubleObj"] = (id)@[@2.2, @3.3]; 
     uncheckedAssertEqualObjects([NSSet setWithArray:[[unmanaged[@"doubleObj"] valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[@2.2, @3.3]])); 
    
    unmanaged[@"stringObj"] = (id)@[@"a", @"bc"]; 
     uncheckedAssertEqualObjects([NSSet setWithArray:[[unmanaged[@"stringObj"] valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[@"a", @"bc"]])); 
    
    unmanaged[@"dataObj"] = (id)@[data(1), data(2)]; 
     uncheckedAssertEqualObjects([NSSet setWithArray:[[unmanaged[@"dataObj"] valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[data(1), data(2)]])); 
    
    unmanaged[@"dateObj"] = (id)@[date(1), date(2)]; 
     uncheckedAssertEqualObjects([NSSet setWithArray:[[unmanaged[@"dateObj"] valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[date(1), date(2)]])); 
    
    unmanaged[@"decimalObj"] = (id)@[decimal128(1), decimal128(2)]; 
     uncheckedAssertEqualObjects([NSSet setWithArray:[[unmanaged[@"decimalObj"] valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[decimal128(1), decimal128(2)]])); 
    
    unmanaged[@"objectIdObj"] = (id)@[objectId(1), objectId(2)]; 
     uncheckedAssertEqualObjects([NSSet setWithArray:[[unmanaged[@"objectIdObj"] valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[objectId(1), objectId(2)]])); 
    
    unmanaged[@"uuidObj"] = (id)@[uuid(@"00000000-0000-0000-0000-000000000000"), uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")]; 
     uncheckedAssertEqualObjects([NSSet setWithArray:[[unmanaged[@"uuidObj"] valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[uuid(@"00000000-0000-0000-0000-000000000000"), uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")]])); 
    
    unmanaged[@"anyBoolObj"] = (id)@[@NO, @YES]; 
     uncheckedAssertEqualObjects([NSSet setWithArray:[[unmanaged[@"anyBoolObj"] valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[@NO, @YES]])); 
    
    unmanaged[@"anyIntObj"] = (id)@[@2, @3]; 
     uncheckedAssertEqualObjects([NSSet setWithArray:[[unmanaged[@"anyIntObj"] valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[@2, @3]])); 
    
    unmanaged[@"anyFloatObj"] = (id)@[@2.2f, @3.3f]; 
     uncheckedAssertEqualObjects([NSSet setWithArray:[[unmanaged[@"anyFloatObj"] valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[@2.2f, @3.3f]])); 
    
    unmanaged[@"anyDoubleObj"] = (id)@[@2.2, @3.3]; 
     uncheckedAssertEqualObjects([NSSet setWithArray:[[unmanaged[@"anyDoubleObj"] valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[@2.2, @3.3]])); 
    
    unmanaged[@"anyStringObj"] = (id)@[@"a", @"b"]; 
     uncheckedAssertEqualObjects([NSSet setWithArray:[[unmanaged[@"anyStringObj"] valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[@"a", @"b"]])); 
    
    unmanaged[@"anyDataObj"] = (id)@[data(1), data(2)]; 
     uncheckedAssertEqualObjects([NSSet setWithArray:[[unmanaged[@"anyDataObj"] valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[data(1), data(2)]])); 
    
    unmanaged[@"anyDateObj"] = (id)@[date(1), date(2)]; 
     uncheckedAssertEqualObjects([NSSet setWithArray:[[unmanaged[@"anyDateObj"] valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[date(1), date(2)]])); 
    
    unmanaged[@"anyDecimalObj"] = (id)@[decimal128(1), decimal128(2)]; 
     uncheckedAssertEqualObjects([NSSet setWithArray:[[unmanaged[@"anyDecimalObj"] valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[decimal128(1), decimal128(2)]])); 
    
    unmanaged[@"anyObjectIdObj"] = (id)@[objectId(1), objectId(2)]; 
     uncheckedAssertEqualObjects([NSSet setWithArray:[[unmanaged[@"anyObjectIdObj"] valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[objectId(1), objectId(2)]])); 
    
    unmanaged[@"anyUUIDObj"] = (id)@[uuid(@"00000000-0000-0000-0000-000000000000"), uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")]; 
     uncheckedAssertEqualObjects([NSSet setWithArray:[[unmanaged[@"anyUUIDObj"] valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[uuid(@"00000000-0000-0000-0000-000000000000"), uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")]])); 
    
    optUnmanaged[@"boolObj"] = (id)@[NSNull.null, @NO, @YES]; 
     uncheckedAssertEqualObjects([NSSet setWithArray:[[optUnmanaged[@"boolObj"] valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[NSNull.null, @NO, @YES]])); 
    
    optUnmanaged[@"intObj"] = (id)@[NSNull.null, @2, @3]; 
     uncheckedAssertEqualObjects([NSSet setWithArray:[[optUnmanaged[@"intObj"] valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[NSNull.null, @2, @3]])); 
    
    optUnmanaged[@"floatObj"] = (id)@[NSNull.null, @2.2f, @3.3f]; 
     uncheckedAssertEqualObjects([NSSet setWithArray:[[optUnmanaged[@"floatObj"] valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[NSNull.null, @2.2f, @3.3f]])); 
    
    optUnmanaged[@"doubleObj"] = (id)@[NSNull.null, @2.2, @3.3]; 
     uncheckedAssertEqualObjects([NSSet setWithArray:[[optUnmanaged[@"doubleObj"] valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[NSNull.null, @2.2, @3.3]])); 
    
    optUnmanaged[@"stringObj"] = (id)@[NSNull.null, @"a", @"bc"]; 
     uncheckedAssertEqualObjects([NSSet setWithArray:[[optUnmanaged[@"stringObj"] valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[NSNull.null, @"a", @"bc"]])); 
    
    optUnmanaged[@"dataObj"] = (id)@[NSNull.null, data(1), data(2)]; 
     uncheckedAssertEqualObjects([NSSet setWithArray:[[optUnmanaged[@"dataObj"] valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[NSNull.null, data(1), data(2)]])); 
    
    optUnmanaged[@"dateObj"] = (id)@[NSNull.null, date(1), date(2)]; 
     uncheckedAssertEqualObjects([NSSet setWithArray:[[optUnmanaged[@"dateObj"] valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[NSNull.null, date(1), date(2)]])); 
    
    optUnmanaged[@"decimalObj"] = (id)@[NSNull.null, decimal128(1), decimal128(2)]; 
     uncheckedAssertEqualObjects([NSSet setWithArray:[[optUnmanaged[@"decimalObj"] valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[NSNull.null, decimal128(1), decimal128(2)]])); 
    
    optUnmanaged[@"objectIdObj"] = (id)@[NSNull.null, objectId(1), objectId(2)]; 
     uncheckedAssertEqualObjects([NSSet setWithArray:[[optUnmanaged[@"objectIdObj"] valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[NSNull.null, objectId(1), objectId(2)]])); 
    
    optUnmanaged[@"uuidObj"] = (id)@[NSNull.null, uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"), uuid(@"00000000-0000-0000-0000-000000000000")]; 
     uncheckedAssertEqualObjects([NSSet setWithArray:[[optUnmanaged[@"uuidObj"] valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[NSNull.null, uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"), uuid(@"00000000-0000-0000-0000-000000000000")]])); 
    
    managed[@"boolObj"] = (id)@[@NO, @YES]; 
     uncheckedAssertEqualObjects([NSSet setWithArray:[[managed[@"boolObj"] valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[@NO, @YES]])); 
    
    managed[@"intObj"] = (id)@[@2, @3]; 
     uncheckedAssertEqualObjects([NSSet setWithArray:[[managed[@"intObj"] valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[@2, @3]])); 
    
    managed[@"floatObj"] = (id)@[@2.2f, @3.3f]; 
     uncheckedAssertEqualObjects([NSSet setWithArray:[[managed[@"floatObj"] valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[@2.2f, @3.3f]])); 
    
    managed[@"doubleObj"] = (id)@[@2.2, @3.3]; 
     uncheckedAssertEqualObjects([NSSet setWithArray:[[managed[@"doubleObj"] valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[@2.2, @3.3]])); 
    
    managed[@"stringObj"] = (id)@[@"a", @"bc"]; 
     uncheckedAssertEqualObjects([NSSet setWithArray:[[managed[@"stringObj"] valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[@"a", @"bc"]])); 
    
    managed[@"dataObj"] = (id)@[data(1), data(2)]; 
     uncheckedAssertEqualObjects([NSSet setWithArray:[[managed[@"dataObj"] valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[data(1), data(2)]])); 
    
    managed[@"dateObj"] = (id)@[date(1), date(2)]; 
     uncheckedAssertEqualObjects([NSSet setWithArray:[[managed[@"dateObj"] valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[date(1), date(2)]])); 
    
    managed[@"decimalObj"] = (id)@[decimal128(1), decimal128(2)]; 
     uncheckedAssertEqualObjects([NSSet setWithArray:[[managed[@"decimalObj"] valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[decimal128(1), decimal128(2)]])); 
    
    managed[@"objectIdObj"] = (id)@[objectId(1), objectId(2)]; 
     uncheckedAssertEqualObjects([NSSet setWithArray:[[managed[@"objectIdObj"] valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[objectId(1), objectId(2)]])); 
    
    managed[@"uuidObj"] = (id)@[uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"), uuid(@"00000000-0000-0000-0000-000000000000")]; 
     uncheckedAssertEqualObjects([NSSet setWithArray:[[managed[@"uuidObj"] valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"), uuid(@"00000000-0000-0000-0000-000000000000")]])); 
    
    managed[@"anyBoolObj"] = (id)@[@NO, @YES]; 
     uncheckedAssertEqualObjects([NSSet setWithArray:[[managed[@"anyBoolObj"] valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[@NO, @YES]])); 
    
    managed[@"anyIntObj"] = (id)@[@2, @3]; 
     uncheckedAssertEqualObjects([NSSet setWithArray:[[managed[@"anyIntObj"] valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[@2, @3]])); 
    
    managed[@"anyFloatObj"] = (id)@[@2.2f, @3.3f]; 
     uncheckedAssertEqualObjects([NSSet setWithArray:[[managed[@"anyFloatObj"] valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[@2.2f, @3.3f]])); 
    
    managed[@"anyDoubleObj"] = (id)@[@2.2, @3.3]; 
     uncheckedAssertEqualObjects([NSSet setWithArray:[[managed[@"anyDoubleObj"] valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[@2.2, @3.3]])); 
    
    managed[@"anyStringObj"] = (id)@[@"a", @"b"]; 
     uncheckedAssertEqualObjects([NSSet setWithArray:[[managed[@"anyStringObj"] valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[@"a", @"b"]])); 
    
    managed[@"anyDataObj"] = (id)@[data(1), data(2)]; 
     uncheckedAssertEqualObjects([NSSet setWithArray:[[managed[@"anyDataObj"] valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[data(1), data(2)]])); 
    
    managed[@"anyDateObj"] = (id)@[date(1), date(2)]; 
     uncheckedAssertEqualObjects([NSSet setWithArray:[[managed[@"anyDateObj"] valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[date(1), date(2)]])); 
    
    managed[@"anyDecimalObj"] = (id)@[decimal128(1), decimal128(2)]; 
     uncheckedAssertEqualObjects([NSSet setWithArray:[[managed[@"anyDecimalObj"] valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[decimal128(1), decimal128(2)]])); 
    
    managed[@"anyObjectIdObj"] = (id)@[objectId(1), objectId(2)]; 
     uncheckedAssertEqualObjects([NSSet setWithArray:[[managed[@"anyObjectIdObj"] valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[objectId(1), objectId(2)]])); 
    
    managed[@"anyUUIDObj"] = (id)@[uuid(@"00000000-0000-0000-0000-000000000000"), uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")]; 
     uncheckedAssertEqualObjects([NSSet setWithArray:[[managed[@"anyUUIDObj"] valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[uuid(@"00000000-0000-0000-0000-000000000000"), uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")]])); 
    
    optManaged[@"boolObj"] = (id)@[NSNull.null, @NO, @YES]; 
     uncheckedAssertEqualObjects([NSSet setWithArray:[[optManaged[@"boolObj"] valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[NSNull.null, @NO, @YES]])); 
    
    optManaged[@"intObj"] = (id)@[NSNull.null, @2, @3]; 
     uncheckedAssertEqualObjects([NSSet setWithArray:[[optManaged[@"intObj"] valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[NSNull.null, @2, @3]])); 
    
    optManaged[@"floatObj"] = (id)@[NSNull.null, @2.2f, @3.3f]; 
     uncheckedAssertEqualObjects([NSSet setWithArray:[[optManaged[@"floatObj"] valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[NSNull.null, @2.2f, @3.3f]])); 
    
    optManaged[@"doubleObj"] = (id)@[NSNull.null, @2.2, @3.3]; 
     uncheckedAssertEqualObjects([NSSet setWithArray:[[optManaged[@"doubleObj"] valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[NSNull.null, @2.2, @3.3]])); 
    
    optManaged[@"stringObj"] = (id)@[NSNull.null, @"a", @"bc"]; 
     uncheckedAssertEqualObjects([NSSet setWithArray:[[optManaged[@"stringObj"] valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[NSNull.null, @"a", @"bc"]])); 
    
    optManaged[@"dataObj"] = (id)@[NSNull.null, data(1), data(2)]; 
     uncheckedAssertEqualObjects([NSSet setWithArray:[[optManaged[@"dataObj"] valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[NSNull.null, data(1), data(2)]])); 
    
    optManaged[@"dateObj"] = (id)@[NSNull.null, date(1), date(2)]; 
     uncheckedAssertEqualObjects([NSSet setWithArray:[[optManaged[@"dateObj"] valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[NSNull.null, date(1), date(2)]])); 
    
    optManaged[@"decimalObj"] = (id)@[NSNull.null, decimal128(1), decimal128(2)]; 
     uncheckedAssertEqualObjects([NSSet setWithArray:[[optManaged[@"decimalObj"] valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[NSNull.null, decimal128(1), decimal128(2)]])); 
    
    optManaged[@"objectIdObj"] = (id)@[NSNull.null, objectId(1), objectId(2)]; 
     uncheckedAssertEqualObjects([NSSet setWithArray:[[optManaged[@"objectIdObj"] valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[NSNull.null, objectId(1), objectId(2)]])); 
    
    optManaged[@"uuidObj"] = (id)@[NSNull.null, uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"), uuid(@"00000000-0000-0000-0000-000000000000")]; 
     uncheckedAssertEqualObjects([NSSet setWithArray:[[optManaged[@"uuidObj"] valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[NSNull.null, uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"), uuid(@"00000000-0000-0000-0000-000000000000")]])); 
    

    // Should not clear the set
    unmanaged[@"boolObj"] = unmanaged[@"boolObj"]; 
     uncheckedAssertEqualObjects([NSSet setWithArray:[[unmanaged[@"boolObj"] valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[@NO, @YES]])); 
    
    unmanaged[@"intObj"] = unmanaged[@"intObj"]; 
     uncheckedAssertEqualObjects([NSSet setWithArray:[[unmanaged[@"intObj"] valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[@2, @3]])); 
    
    unmanaged[@"floatObj"] = unmanaged[@"floatObj"]; 
     uncheckedAssertEqualObjects([NSSet setWithArray:[[unmanaged[@"floatObj"] valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[@2.2f, @3.3f]])); 
    
    unmanaged[@"doubleObj"] = unmanaged[@"doubleObj"]; 
     uncheckedAssertEqualObjects([NSSet setWithArray:[[unmanaged[@"doubleObj"] valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[@2.2, @3.3]])); 
    
    unmanaged[@"stringObj"] = unmanaged[@"stringObj"]; 
     uncheckedAssertEqualObjects([NSSet setWithArray:[[unmanaged[@"stringObj"] valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[@"a", @"bc"]])); 
    
    unmanaged[@"dataObj"] = unmanaged[@"dataObj"]; 
     uncheckedAssertEqualObjects([NSSet setWithArray:[[unmanaged[@"dataObj"] valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[data(1), data(2)]])); 
    
    unmanaged[@"dateObj"] = unmanaged[@"dateObj"]; 
     uncheckedAssertEqualObjects([NSSet setWithArray:[[unmanaged[@"dateObj"] valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[date(1), date(2)]])); 
    
    unmanaged[@"decimalObj"] = unmanaged[@"decimalObj"]; 
     uncheckedAssertEqualObjects([NSSet setWithArray:[[unmanaged[@"decimalObj"] valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[decimal128(1), decimal128(2)]])); 
    
    unmanaged[@"objectIdObj"] = unmanaged[@"objectIdObj"]; 
     uncheckedAssertEqualObjects([NSSet setWithArray:[[unmanaged[@"objectIdObj"] valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[objectId(1), objectId(2)]])); 
    
    unmanaged[@"uuidObj"] = unmanaged[@"uuidObj"]; 
     uncheckedAssertEqualObjects([NSSet setWithArray:[[unmanaged[@"uuidObj"] valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[uuid(@"00000000-0000-0000-0000-000000000000"), uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")]])); 
    
    unmanaged[@"anyBoolObj"] = unmanaged[@"anyBoolObj"]; 
     uncheckedAssertEqualObjects([NSSet setWithArray:[[unmanaged[@"anyBoolObj"] valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[@NO, @YES]])); 
    
    unmanaged[@"anyIntObj"] = unmanaged[@"anyIntObj"]; 
     uncheckedAssertEqualObjects([NSSet setWithArray:[[unmanaged[@"anyIntObj"] valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[@2, @3]])); 
    
    unmanaged[@"anyFloatObj"] = unmanaged[@"anyFloatObj"]; 
     uncheckedAssertEqualObjects([NSSet setWithArray:[[unmanaged[@"anyFloatObj"] valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[@2.2f, @3.3f]])); 
    
    unmanaged[@"anyDoubleObj"] = unmanaged[@"anyDoubleObj"]; 
     uncheckedAssertEqualObjects([NSSet setWithArray:[[unmanaged[@"anyDoubleObj"] valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[@2.2, @3.3]])); 
    
    unmanaged[@"anyStringObj"] = unmanaged[@"anyStringObj"]; 
     uncheckedAssertEqualObjects([NSSet setWithArray:[[unmanaged[@"anyStringObj"] valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[@"a", @"b"]])); 
    
    unmanaged[@"anyDataObj"] = unmanaged[@"anyDataObj"]; 
     uncheckedAssertEqualObjects([NSSet setWithArray:[[unmanaged[@"anyDataObj"] valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[data(1), data(2)]])); 
    
    unmanaged[@"anyDateObj"] = unmanaged[@"anyDateObj"]; 
     uncheckedAssertEqualObjects([NSSet setWithArray:[[unmanaged[@"anyDateObj"] valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[date(1), date(2)]])); 
    
    unmanaged[@"anyDecimalObj"] = unmanaged[@"anyDecimalObj"]; 
     uncheckedAssertEqualObjects([NSSet setWithArray:[[unmanaged[@"anyDecimalObj"] valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[decimal128(1), decimal128(2)]])); 
    
    unmanaged[@"anyObjectIdObj"] = unmanaged[@"anyObjectIdObj"]; 
     uncheckedAssertEqualObjects([NSSet setWithArray:[[unmanaged[@"anyObjectIdObj"] valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[objectId(1), objectId(2)]])); 
    
    unmanaged[@"anyUUIDObj"] = unmanaged[@"anyUUIDObj"]; 
     uncheckedAssertEqualObjects([NSSet setWithArray:[[unmanaged[@"anyUUIDObj"] valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[uuid(@"00000000-0000-0000-0000-000000000000"), uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")]])); 
    
    optUnmanaged[@"boolObj"] = optUnmanaged[@"boolObj"]; 
     uncheckedAssertEqualObjects([NSSet setWithArray:[[optUnmanaged[@"boolObj"] valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[NSNull.null, @NO, @YES]])); 
    
    optUnmanaged[@"intObj"] = optUnmanaged[@"intObj"]; 
     uncheckedAssertEqualObjects([NSSet setWithArray:[[optUnmanaged[@"intObj"] valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[NSNull.null, @2, @3]])); 
    
    optUnmanaged[@"floatObj"] = optUnmanaged[@"floatObj"]; 
     uncheckedAssertEqualObjects([NSSet setWithArray:[[optUnmanaged[@"floatObj"] valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[NSNull.null, @2.2f, @3.3f]])); 
    
    optUnmanaged[@"doubleObj"] = optUnmanaged[@"doubleObj"]; 
     uncheckedAssertEqualObjects([NSSet setWithArray:[[optUnmanaged[@"doubleObj"] valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[NSNull.null, @2.2, @3.3]])); 
    
    optUnmanaged[@"stringObj"] = optUnmanaged[@"stringObj"]; 
     uncheckedAssertEqualObjects([NSSet setWithArray:[[optUnmanaged[@"stringObj"] valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[NSNull.null, @"a", @"bc"]])); 
    
    optUnmanaged[@"dataObj"] = optUnmanaged[@"dataObj"]; 
     uncheckedAssertEqualObjects([NSSet setWithArray:[[optUnmanaged[@"dataObj"] valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[NSNull.null, data(1), data(2)]])); 
    
    optUnmanaged[@"dateObj"] = optUnmanaged[@"dateObj"]; 
     uncheckedAssertEqualObjects([NSSet setWithArray:[[optUnmanaged[@"dateObj"] valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[NSNull.null, date(1), date(2)]])); 
    
    optUnmanaged[@"decimalObj"] = optUnmanaged[@"decimalObj"]; 
     uncheckedAssertEqualObjects([NSSet setWithArray:[[optUnmanaged[@"decimalObj"] valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[NSNull.null, decimal128(1), decimal128(2)]])); 
    
    optUnmanaged[@"objectIdObj"] = optUnmanaged[@"objectIdObj"]; 
     uncheckedAssertEqualObjects([NSSet setWithArray:[[optUnmanaged[@"objectIdObj"] valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[NSNull.null, objectId(1), objectId(2)]])); 
    
    optUnmanaged[@"uuidObj"] = optUnmanaged[@"uuidObj"]; 
     uncheckedAssertEqualObjects([NSSet setWithArray:[[optUnmanaged[@"uuidObj"] valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[NSNull.null, uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"), uuid(@"00000000-0000-0000-0000-000000000000")]])); 
    
    managed[@"boolObj"] = managed[@"boolObj"]; 
     uncheckedAssertEqualObjects([NSSet setWithArray:[[managed[@"boolObj"] valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[@NO, @YES]])); 
    
    managed[@"intObj"] = managed[@"intObj"]; 
     uncheckedAssertEqualObjects([NSSet setWithArray:[[managed[@"intObj"] valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[@2, @3]])); 
    
    managed[@"floatObj"] = managed[@"floatObj"]; 
     uncheckedAssertEqualObjects([NSSet setWithArray:[[managed[@"floatObj"] valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[@2.2f, @3.3f]])); 
    
    managed[@"doubleObj"] = managed[@"doubleObj"]; 
     uncheckedAssertEqualObjects([NSSet setWithArray:[[managed[@"doubleObj"] valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[@2.2, @3.3]])); 
    
    managed[@"stringObj"] = managed[@"stringObj"]; 
     uncheckedAssertEqualObjects([NSSet setWithArray:[[managed[@"stringObj"] valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[@"a", @"bc"]])); 
    
    managed[@"dataObj"] = managed[@"dataObj"]; 
     uncheckedAssertEqualObjects([NSSet setWithArray:[[managed[@"dataObj"] valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[data(1), data(2)]])); 
    
    managed[@"dateObj"] = managed[@"dateObj"]; 
     uncheckedAssertEqualObjects([NSSet setWithArray:[[managed[@"dateObj"] valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[date(1), date(2)]])); 
    
    managed[@"decimalObj"] = managed[@"decimalObj"]; 
     uncheckedAssertEqualObjects([NSSet setWithArray:[[managed[@"decimalObj"] valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[decimal128(1), decimal128(2)]])); 
    
    managed[@"objectIdObj"] = managed[@"objectIdObj"]; 
     uncheckedAssertEqualObjects([NSSet setWithArray:[[managed[@"objectIdObj"] valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[objectId(1), objectId(2)]])); 
    
    managed[@"uuidObj"] = managed[@"uuidObj"]; 
     uncheckedAssertEqualObjects([NSSet setWithArray:[[managed[@"uuidObj"] valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"), uuid(@"00000000-0000-0000-0000-000000000000")]])); 
    
    managed[@"anyBoolObj"] = managed[@"anyBoolObj"]; 
     uncheckedAssertEqualObjects([NSSet setWithArray:[[managed[@"anyBoolObj"] valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[@NO, @YES]])); 
    
    managed[@"anyIntObj"] = managed[@"anyIntObj"]; 
     uncheckedAssertEqualObjects([NSSet setWithArray:[[managed[@"anyIntObj"] valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[@2, @3]])); 
    
    managed[@"anyFloatObj"] = managed[@"anyFloatObj"]; 
     uncheckedAssertEqualObjects([NSSet setWithArray:[[managed[@"anyFloatObj"] valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[@2.2f, @3.3f]])); 
    
    managed[@"anyDoubleObj"] = managed[@"anyDoubleObj"]; 
     uncheckedAssertEqualObjects([NSSet setWithArray:[[managed[@"anyDoubleObj"] valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[@2.2, @3.3]])); 
    
    managed[@"anyStringObj"] = managed[@"anyStringObj"]; 
     uncheckedAssertEqualObjects([NSSet setWithArray:[[managed[@"anyStringObj"] valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[@"a", @"b"]])); 
    
    managed[@"anyDataObj"] = managed[@"anyDataObj"]; 
     uncheckedAssertEqualObjects([NSSet setWithArray:[[managed[@"anyDataObj"] valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[data(1), data(2)]])); 
    
    managed[@"anyDateObj"] = managed[@"anyDateObj"]; 
     uncheckedAssertEqualObjects([NSSet setWithArray:[[managed[@"anyDateObj"] valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[date(1), date(2)]])); 
    
    managed[@"anyDecimalObj"] = managed[@"anyDecimalObj"]; 
     uncheckedAssertEqualObjects([NSSet setWithArray:[[managed[@"anyDecimalObj"] valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[decimal128(1), decimal128(2)]])); 
    
    managed[@"anyObjectIdObj"] = managed[@"anyObjectIdObj"]; 
     uncheckedAssertEqualObjects([NSSet setWithArray:[[managed[@"anyObjectIdObj"] valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[objectId(1), objectId(2)]])); 
    
    managed[@"anyUUIDObj"] = managed[@"anyUUIDObj"]; 
     uncheckedAssertEqualObjects([NSSet setWithArray:[[managed[@"anyUUIDObj"] valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[uuid(@"00000000-0000-0000-0000-000000000000"), uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")]])); 
    
    optManaged[@"boolObj"] = optManaged[@"boolObj"]; 
     uncheckedAssertEqualObjects([NSSet setWithArray:[[optManaged[@"boolObj"] valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[NSNull.null, @NO, @YES]])); 
    
    optManaged[@"intObj"] = optManaged[@"intObj"]; 
     uncheckedAssertEqualObjects([NSSet setWithArray:[[optManaged[@"intObj"] valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[NSNull.null, @2, @3]])); 
    
    optManaged[@"floatObj"] = optManaged[@"floatObj"]; 
     uncheckedAssertEqualObjects([NSSet setWithArray:[[optManaged[@"floatObj"] valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[NSNull.null, @2.2f, @3.3f]])); 
    
    optManaged[@"doubleObj"] = optManaged[@"doubleObj"]; 
     uncheckedAssertEqualObjects([NSSet setWithArray:[[optManaged[@"doubleObj"] valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[NSNull.null, @2.2, @3.3]])); 
    
    optManaged[@"stringObj"] = optManaged[@"stringObj"]; 
     uncheckedAssertEqualObjects([NSSet setWithArray:[[optManaged[@"stringObj"] valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[NSNull.null, @"a", @"bc"]])); 
    
    optManaged[@"dataObj"] = optManaged[@"dataObj"]; 
     uncheckedAssertEqualObjects([NSSet setWithArray:[[optManaged[@"dataObj"] valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[NSNull.null, data(1), data(2)]])); 
    
    optManaged[@"dateObj"] = optManaged[@"dateObj"]; 
     uncheckedAssertEqualObjects([NSSet setWithArray:[[optManaged[@"dateObj"] valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[NSNull.null, date(1), date(2)]])); 
    
    optManaged[@"decimalObj"] = optManaged[@"decimalObj"]; 
     uncheckedAssertEqualObjects([NSSet setWithArray:[[optManaged[@"decimalObj"] valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[NSNull.null, decimal128(1), decimal128(2)]])); 
    
    optManaged[@"objectIdObj"] = optManaged[@"objectIdObj"]; 
     uncheckedAssertEqualObjects([NSSet setWithArray:[[optManaged[@"objectIdObj"] valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[NSNull.null, objectId(1), objectId(2)]])); 
    
    optManaged[@"uuidObj"] = optManaged[@"uuidObj"]; 
     uncheckedAssertEqualObjects([NSSet setWithArray:[[optManaged[@"uuidObj"] valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[NSNull.null, uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"), uuid(@"00000000-0000-0000-0000-000000000000")]])); 
    

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
        @"boolObj": [@[@NO, @YES] subarrayWithRange:range],
        @"intObj": [@[@2, @3] subarrayWithRange:range],
        @"floatObj": [@[@2.2f, @3.3f] subarrayWithRange:range],
        @"doubleObj": [@[@2.2, @3.3] subarrayWithRange:range],
        @"stringObj": [@[@"a", @"bc"] subarrayWithRange:range],
        @"dataObj": [@[data(1), data(2)] subarrayWithRange:range],
        @"dateObj": [@[date(1), date(2)] subarrayWithRange:range],
        @"decimalObj": [@[decimal128(1), decimal128(2)] subarrayWithRange:range],
        @"objectIdObj": [@[objectId(1), objectId(2)] subarrayWithRange:range],
        @"uuidObj": [@[uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"), uuid(@"00000000-0000-0000-0000-000000000000")] subarrayWithRange:range],
        @"anyBoolObj": [@[@NO, @YES] subarrayWithRange:range],
        @"anyIntObj": [@[@2, @3] subarrayWithRange:range],
        @"anyFloatObj": [@[@2.2f, @3.3f] subarrayWithRange:range],
        @"anyDoubleObj": [@[@2.2, @3.3] subarrayWithRange:range],
        @"anyStringObj": [@[@"a", @"b"] subarrayWithRange:range],
        @"anyDataObj": [@[data(1), data(2)] subarrayWithRange:range],
        @"anyDateObj": [@[date(1), date(2)] subarrayWithRange:range],
        @"anyDecimalObj": [@[decimal128(1), decimal128(2)] subarrayWithRange:range],
        @"anyObjectIdObj": [@[objectId(1), objectId(2)] subarrayWithRange:range],
        @"anyUUIDObj": [@[uuid(@"00000000-0000-0000-0000-000000000000"), uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")] subarrayWithRange:range],
    }];
    [LinkToAllPrimitiveSets createInRealm:realm withValue:@[obj]];
    obj = [AllOptionalPrimitiveSets createInRealm:realm withValue:@{
        @"boolObj": [@[NSNull.null, @NO, @YES] subarrayWithRange:range],
        @"intObj": [@[NSNull.null, @2, @3] subarrayWithRange:range],
        @"floatObj": [@[NSNull.null, @2.2f, @3.3f] subarrayWithRange:range],
        @"doubleObj": [@[NSNull.null, @2.2, @3.3] subarrayWithRange:range],
        @"stringObj": [@[NSNull.null, @"a", @"bc"] subarrayWithRange:range],
        @"dataObj": [@[NSNull.null, data(1), data(2)] subarrayWithRange:range],
        @"dateObj": [@[NSNull.null, date(1), date(2)] subarrayWithRange:range],
        @"decimalObj": [@[NSNull.null, decimal128(1), decimal128(2)] subarrayWithRange:range],
        @"objectIdObj": [@[NSNull.null, objectId(1), objectId(2)] subarrayWithRange:range],
        @"uuidObj": [@[NSNull.null, uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"), uuid(@"00000000-0000-0000-0000-000000000000")] subarrayWithRange:range],
    }];
    [LinkToAllOptionalPrimitiveSets createInRealm:realm withValue:@[obj]];
}

- (void)testQueryBasicOperators {
    [realm deleteAllObjects];

    RLMAssertCount(AllPrimitiveSets, 0, @"ANY boolObj = %@", @NO);
    RLMAssertCount(AllPrimitiveSets, 0, @"ANY intObj = %@", @2);
    RLMAssertCount(AllPrimitiveSets, 0, @"ANY floatObj = %@", @2.2f);
    RLMAssertCount(AllPrimitiveSets, 0, @"ANY doubleObj = %@", @2.2);
    RLMAssertCount(AllPrimitiveSets, 0, @"ANY stringObj = %@", @"a");
    RLMAssertCount(AllPrimitiveSets, 0, @"ANY dataObj = %@", data(1));
    RLMAssertCount(AllPrimitiveSets, 0, @"ANY dateObj = %@", date(1));
    RLMAssertCount(AllPrimitiveSets, 0, @"ANY decimalObj = %@", decimal128(1));
    RLMAssertCount(AllPrimitiveSets, 0, @"ANY objectIdObj = %@", objectId(1));
    RLMAssertCount(AllPrimitiveSets, 0, @"ANY uuidObj = %@", uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"));
    RLMAssertCount(AllPrimitiveSets, 0, @"ANY anyBoolObj = %@", @NO);
    RLMAssertCount(AllPrimitiveSets, 0, @"ANY anyIntObj = %@", @2);
    RLMAssertCount(AllPrimitiveSets, 0, @"ANY anyFloatObj = %@", @2.2f);
    RLMAssertCount(AllPrimitiveSets, 0, @"ANY anyDoubleObj = %@", @2.2);
    RLMAssertCount(AllPrimitiveSets, 0, @"ANY anyStringObj = %@", @"a");
    RLMAssertCount(AllPrimitiveSets, 0, @"ANY anyDataObj = %@", data(1));
    RLMAssertCount(AllPrimitiveSets, 0, @"ANY anyDateObj = %@", date(1));
    RLMAssertCount(AllPrimitiveSets, 0, @"ANY anyDecimalObj = %@", decimal128(1));
    RLMAssertCount(AllPrimitiveSets, 0, @"ANY anyObjectIdObj = %@", objectId(1));
    RLMAssertCount(AllPrimitiveSets, 0, @"ANY anyUUIDObj = %@", uuid(@"00000000-0000-0000-0000-000000000000"));
    RLMAssertCount(AllOptionalPrimitiveSets, 0, @"ANY boolObj = %@", NSNull.null);
    RLMAssertCount(AllOptionalPrimitiveSets, 0, @"ANY intObj = %@", NSNull.null);
    RLMAssertCount(AllOptionalPrimitiveSets, 0, @"ANY floatObj = %@", NSNull.null);
    RLMAssertCount(AllOptionalPrimitiveSets, 0, @"ANY doubleObj = %@", NSNull.null);
    RLMAssertCount(AllOptionalPrimitiveSets, 0, @"ANY stringObj = %@", NSNull.null);
    RLMAssertCount(AllOptionalPrimitiveSets, 0, @"ANY dataObj = %@", NSNull.null);
    RLMAssertCount(AllOptionalPrimitiveSets, 0, @"ANY dateObj = %@", NSNull.null);
    RLMAssertCount(AllOptionalPrimitiveSets, 0, @"ANY decimalObj = %@", NSNull.null);
    RLMAssertCount(AllOptionalPrimitiveSets, 0, @"ANY objectIdObj = %@", NSNull.null);
    RLMAssertCount(AllOptionalPrimitiveSets, 0, @"ANY uuidObj = %@", NSNull.null);
    RLMAssertCount(AllPrimitiveSets, 0, @"ANY boolObj != %@", @NO);
    RLMAssertCount(AllPrimitiveSets, 0, @"ANY intObj != %@", @2);
    RLMAssertCount(AllPrimitiveSets, 0, @"ANY floatObj != %@", @2.2f);
    RLMAssertCount(AllPrimitiveSets, 0, @"ANY doubleObj != %@", @2.2);
    RLMAssertCount(AllPrimitiveSets, 0, @"ANY stringObj != %@", @"a");
    RLMAssertCount(AllPrimitiveSets, 0, @"ANY dataObj != %@", data(1));
    RLMAssertCount(AllPrimitiveSets, 0, @"ANY dateObj != %@", date(1));
    RLMAssertCount(AllPrimitiveSets, 0, @"ANY decimalObj != %@", decimal128(1));
    RLMAssertCount(AllPrimitiveSets, 0, @"ANY objectIdObj != %@", objectId(1));
    RLMAssertCount(AllPrimitiveSets, 0, @"ANY uuidObj != %@", uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"));
    RLMAssertCount(AllPrimitiveSets, 0, @"ANY anyBoolObj != %@", @NO);
    RLMAssertCount(AllPrimitiveSets, 0, @"ANY anyIntObj != %@", @2);
    RLMAssertCount(AllPrimitiveSets, 0, @"ANY anyFloatObj != %@", @2.2f);
    RLMAssertCount(AllPrimitiveSets, 0, @"ANY anyDoubleObj != %@", @2.2);
    RLMAssertCount(AllPrimitiveSets, 0, @"ANY anyStringObj != %@", @"a");
    RLMAssertCount(AllPrimitiveSets, 0, @"ANY anyDataObj != %@", data(1));
    RLMAssertCount(AllPrimitiveSets, 0, @"ANY anyDateObj != %@", date(1));
    RLMAssertCount(AllPrimitiveSets, 0, @"ANY anyDecimalObj != %@", decimal128(1));
    RLMAssertCount(AllPrimitiveSets, 0, @"ANY anyObjectIdObj != %@", objectId(1));
    RLMAssertCount(AllPrimitiveSets, 0, @"ANY anyUUIDObj != %@", uuid(@"00000000-0000-0000-0000-000000000000"));
    RLMAssertCount(AllOptionalPrimitiveSets, 0, @"ANY boolObj != %@", NSNull.null);
    RLMAssertCount(AllOptionalPrimitiveSets, 0, @"ANY intObj != %@", NSNull.null);
    RLMAssertCount(AllOptionalPrimitiveSets, 0, @"ANY floatObj != %@", NSNull.null);
    RLMAssertCount(AllOptionalPrimitiveSets, 0, @"ANY doubleObj != %@", NSNull.null);
    RLMAssertCount(AllOptionalPrimitiveSets, 0, @"ANY stringObj != %@", NSNull.null);
    RLMAssertCount(AllOptionalPrimitiveSets, 0, @"ANY dataObj != %@", NSNull.null);
    RLMAssertCount(AllOptionalPrimitiveSets, 0, @"ANY dateObj != %@", NSNull.null);
    RLMAssertCount(AllOptionalPrimitiveSets, 0, @"ANY decimalObj != %@", NSNull.null);
    RLMAssertCount(AllOptionalPrimitiveSets, 0, @"ANY objectIdObj != %@", NSNull.null);
    RLMAssertCount(AllOptionalPrimitiveSets, 0, @"ANY uuidObj != %@", NSNull.null);
    RLMAssertCount(AllPrimitiveSets, 0, @"ANY intObj > %@", @2);
    RLMAssertCount(AllPrimitiveSets, 0, @"ANY floatObj > %@", @2.2f);
    RLMAssertCount(AllPrimitiveSets, 0, @"ANY doubleObj > %@", @2.2);
    RLMAssertCount(AllPrimitiveSets, 0, @"ANY dateObj > %@", date(1));
    RLMAssertCount(AllPrimitiveSets, 0, @"ANY decimalObj > %@", decimal128(1));
    RLMAssertCount(AllPrimitiveSets, 0, @"ANY anyIntObj > %@", @2);
    RLMAssertCount(AllPrimitiveSets, 0, @"ANY anyFloatObj > %@", @2.2f);
    RLMAssertCount(AllPrimitiveSets, 0, @"ANY anyDoubleObj > %@", @2.2);
    RLMAssertCount(AllPrimitiveSets, 0, @"ANY anyDateObj > %@", date(1));
    RLMAssertCount(AllPrimitiveSets, 0, @"ANY anyDecimalObj > %@", decimal128(1));
    RLMAssertCount(AllOptionalPrimitiveSets, 0, @"ANY intObj > %@", NSNull.null);
    RLMAssertCount(AllOptionalPrimitiveSets, 0, @"ANY floatObj > %@", NSNull.null);
    RLMAssertCount(AllOptionalPrimitiveSets, 0, @"ANY doubleObj > %@", NSNull.null);
    RLMAssertCount(AllOptionalPrimitiveSets, 0, @"ANY dateObj > %@", NSNull.null);
    RLMAssertCount(AllOptionalPrimitiveSets, 0, @"ANY decimalObj > %@", NSNull.null);
    RLMAssertCount(AllPrimitiveSets, 0, @"ANY intObj >= %@", @2);
    RLMAssertCount(AllPrimitiveSets, 0, @"ANY floatObj >= %@", @2.2f);
    RLMAssertCount(AllPrimitiveSets, 0, @"ANY doubleObj >= %@", @2.2);
    RLMAssertCount(AllPrimitiveSets, 0, @"ANY dateObj >= %@", date(1));
    RLMAssertCount(AllPrimitiveSets, 0, @"ANY decimalObj >= %@", decimal128(1));
    RLMAssertCount(AllPrimitiveSets, 0, @"ANY anyIntObj >= %@", @2);
    RLMAssertCount(AllPrimitiveSets, 0, @"ANY anyFloatObj >= %@", @2.2f);
    RLMAssertCount(AllPrimitiveSets, 0, @"ANY anyDoubleObj >= %@", @2.2);
    RLMAssertCount(AllPrimitiveSets, 0, @"ANY anyDateObj >= %@", date(1));
    RLMAssertCount(AllPrimitiveSets, 0, @"ANY anyDecimalObj >= %@", decimal128(1));
    RLMAssertCount(AllOptionalPrimitiveSets, 0, @"ANY intObj >= %@", NSNull.null);
    RLMAssertCount(AllOptionalPrimitiveSets, 0, @"ANY floatObj >= %@", NSNull.null);
    RLMAssertCount(AllOptionalPrimitiveSets, 0, @"ANY doubleObj >= %@", NSNull.null);
    RLMAssertCount(AllOptionalPrimitiveSets, 0, @"ANY dateObj >= %@", NSNull.null);
    RLMAssertCount(AllOptionalPrimitiveSets, 0, @"ANY decimalObj >= %@", NSNull.null);
    RLMAssertCount(AllPrimitiveSets, 0, @"ANY intObj < %@", @2);
    RLMAssertCount(AllPrimitiveSets, 0, @"ANY floatObj < %@", @2.2f);
    RLMAssertCount(AllPrimitiveSets, 0, @"ANY doubleObj < %@", @2.2);
    RLMAssertCount(AllPrimitiveSets, 0, @"ANY dateObj < %@", date(1));
    RLMAssertCount(AllPrimitiveSets, 0, @"ANY decimalObj < %@", decimal128(1));
    RLMAssertCount(AllPrimitiveSets, 0, @"ANY anyIntObj < %@", @2);
    RLMAssertCount(AllPrimitiveSets, 0, @"ANY anyFloatObj < %@", @2.2f);
    RLMAssertCount(AllPrimitiveSets, 0, @"ANY anyDoubleObj < %@", @2.2);
    RLMAssertCount(AllPrimitiveSets, 0, @"ANY anyDateObj < %@", date(1));
    RLMAssertCount(AllPrimitiveSets, 0, @"ANY anyDecimalObj < %@", decimal128(1));
    RLMAssertCount(AllOptionalPrimitiveSets, 0, @"ANY intObj < %@", NSNull.null);
    RLMAssertCount(AllOptionalPrimitiveSets, 0, @"ANY floatObj < %@", NSNull.null);
    RLMAssertCount(AllOptionalPrimitiveSets, 0, @"ANY doubleObj < %@", NSNull.null);
    RLMAssertCount(AllOptionalPrimitiveSets, 0, @"ANY dateObj < %@", NSNull.null);
    RLMAssertCount(AllOptionalPrimitiveSets, 0, @"ANY decimalObj < %@", NSNull.null);
    RLMAssertCount(AllPrimitiveSets, 0, @"ANY intObj <= %@", @2);
    RLMAssertCount(AllPrimitiveSets, 0, @"ANY floatObj <= %@", @2.2f);
    RLMAssertCount(AllPrimitiveSets, 0, @"ANY doubleObj <= %@", @2.2);
    RLMAssertCount(AllPrimitiveSets, 0, @"ANY dateObj <= %@", date(1));
    RLMAssertCount(AllPrimitiveSets, 0, @"ANY decimalObj <= %@", decimal128(1));
    RLMAssertCount(AllPrimitiveSets, 0, @"ANY anyIntObj <= %@", @2);
    RLMAssertCount(AllPrimitiveSets, 0, @"ANY anyFloatObj <= %@", @2.2f);
    RLMAssertCount(AllPrimitiveSets, 0, @"ANY anyDoubleObj <= %@", @2.2);
    RLMAssertCount(AllPrimitiveSets, 0, @"ANY anyDateObj <= %@", date(1));
    RLMAssertCount(AllPrimitiveSets, 0, @"ANY anyDecimalObj <= %@", decimal128(1));
    RLMAssertCount(AllOptionalPrimitiveSets, 0, @"ANY intObj <= %@", NSNull.null);
    RLMAssertCount(AllOptionalPrimitiveSets, 0, @"ANY floatObj <= %@", NSNull.null);
    RLMAssertCount(AllOptionalPrimitiveSets, 0, @"ANY doubleObj <= %@", NSNull.null);
    RLMAssertCount(AllOptionalPrimitiveSets, 0, @"ANY dateObj <= %@", NSNull.null);
    RLMAssertCount(AllOptionalPrimitiveSets, 0, @"ANY decimalObj <= %@", NSNull.null);

    [self createObjectWithValueIndex:0];

    RLMAssertCount(AllPrimitiveSets, 0, @"ANY boolObj = %@", @YES);
    RLMAssertCount(AllPrimitiveSets, 0, @"ANY intObj = %@", @3);
    RLMAssertCount(AllPrimitiveSets, 0, @"ANY floatObj = %@", @3.3f);
    RLMAssertCount(AllPrimitiveSets, 0, @"ANY doubleObj = %@", @3.3);
    RLMAssertCount(AllPrimitiveSets, 0, @"ANY stringObj = %@", @"bc");
    RLMAssertCount(AllPrimitiveSets, 0, @"ANY dataObj = %@", data(2));
    RLMAssertCount(AllPrimitiveSets, 0, @"ANY dateObj = %@", date(2));
    RLMAssertCount(AllPrimitiveSets, 0, @"ANY decimalObj = %@", decimal128(2));
    RLMAssertCount(AllPrimitiveSets, 0, @"ANY objectIdObj = %@", objectId(2));
    RLMAssertCount(AllPrimitiveSets, 0, @"ANY uuidObj = %@", uuid(@"00000000-0000-0000-0000-000000000000"));
    RLMAssertCount(AllPrimitiveSets, 0, @"ANY anyBoolObj = %@", @YES);
    RLMAssertCount(AllPrimitiveSets, 0, @"ANY anyIntObj = %@", @3);
    RLMAssertCount(AllPrimitiveSets, 0, @"ANY anyFloatObj = %@", @3.3f);
    RLMAssertCount(AllPrimitiveSets, 0, @"ANY anyDoubleObj = %@", @3.3);
    RLMAssertCount(AllPrimitiveSets, 0, @"ANY anyStringObj = %@", @"b");
    RLMAssertCount(AllPrimitiveSets, 0, @"ANY anyDataObj = %@", data(2));
    RLMAssertCount(AllPrimitiveSets, 0, @"ANY anyDateObj = %@", date(2));
    RLMAssertCount(AllPrimitiveSets, 0, @"ANY anyDecimalObj = %@", decimal128(2));
    RLMAssertCount(AllPrimitiveSets, 0, @"ANY anyObjectIdObj = %@", objectId(2));
    RLMAssertCount(AllPrimitiveSets, 0, @"ANY anyUUIDObj = %@", uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"));
    RLMAssertCount(AllOptionalPrimitiveSets, 0, @"ANY boolObj = %@", @NO);
    RLMAssertCount(AllOptionalPrimitiveSets, 0, @"ANY intObj = %@", @2);
    RLMAssertCount(AllOptionalPrimitiveSets, 0, @"ANY floatObj = %@", @2.2f);
    RLMAssertCount(AllOptionalPrimitiveSets, 0, @"ANY doubleObj = %@", @2.2);
    RLMAssertCount(AllOptionalPrimitiveSets, 0, @"ANY stringObj = %@", @"a");
    RLMAssertCount(AllOptionalPrimitiveSets, 0, @"ANY dataObj = %@", data(1));
    RLMAssertCount(AllOptionalPrimitiveSets, 0, @"ANY dateObj = %@", date(1));
    RLMAssertCount(AllOptionalPrimitiveSets, 0, @"ANY decimalObj = %@", decimal128(1));
    RLMAssertCount(AllOptionalPrimitiveSets, 0, @"ANY objectIdObj = %@", objectId(1));
    RLMAssertCount(AllOptionalPrimitiveSets, 0, @"ANY uuidObj = %@", uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"));
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY boolObj = %@", @NO);
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY intObj = %@", @2);
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY floatObj = %@", @2.2f);
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY doubleObj = %@", @2.2);
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY stringObj = %@", @"a");
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY dataObj = %@", data(1));
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY dateObj = %@", date(1));
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY decimalObj = %@", decimal128(1));
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY objectIdObj = %@", objectId(1));
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY uuidObj = %@", uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"));
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY anyBoolObj = %@", @NO);
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY anyIntObj = %@", @2);
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY anyFloatObj = %@", @2.2f);
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY anyDoubleObj = %@", @2.2);
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY anyStringObj = %@", @"a");
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY anyDataObj = %@", data(1));
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY anyDateObj = %@", date(1));
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY anyDecimalObj = %@", decimal128(1));
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY anyObjectIdObj = %@", objectId(1));
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY anyUUIDObj = %@", uuid(@"00000000-0000-0000-0000-000000000000"));
    RLMAssertCount(AllOptionalPrimitiveSets, 1, @"ANY boolObj = %@", NSNull.null);
    RLMAssertCount(AllOptionalPrimitiveSets, 1, @"ANY intObj = %@", NSNull.null);
    RLMAssertCount(AllOptionalPrimitiveSets, 1, @"ANY floatObj = %@", NSNull.null);
    RLMAssertCount(AllOptionalPrimitiveSets, 1, @"ANY doubleObj = %@", NSNull.null);
    RLMAssertCount(AllOptionalPrimitiveSets, 1, @"ANY stringObj = %@", NSNull.null);
    RLMAssertCount(AllOptionalPrimitiveSets, 1, @"ANY dataObj = %@", NSNull.null);
    RLMAssertCount(AllOptionalPrimitiveSets, 1, @"ANY dateObj = %@", NSNull.null);
    RLMAssertCount(AllOptionalPrimitiveSets, 1, @"ANY decimalObj = %@", NSNull.null);
    RLMAssertCount(AllOptionalPrimitiveSets, 1, @"ANY objectIdObj = %@", NSNull.null);
    RLMAssertCount(AllOptionalPrimitiveSets, 1, @"ANY uuidObj = %@", NSNull.null);
    RLMAssertCount(AllPrimitiveSets, 0, @"ANY boolObj != %@", @NO);
    RLMAssertCount(AllPrimitiveSets, 0, @"ANY intObj != %@", @2);
    RLMAssertCount(AllPrimitiveSets, 0, @"ANY floatObj != %@", @2.2f);
    RLMAssertCount(AllPrimitiveSets, 0, @"ANY doubleObj != %@", @2.2);
    RLMAssertCount(AllPrimitiveSets, 0, @"ANY stringObj != %@", @"a");
    RLMAssertCount(AllPrimitiveSets, 0, @"ANY dataObj != %@", data(1));
    RLMAssertCount(AllPrimitiveSets, 0, @"ANY dateObj != %@", date(1));
    RLMAssertCount(AllPrimitiveSets, 0, @"ANY decimalObj != %@", decimal128(1));
    RLMAssertCount(AllPrimitiveSets, 0, @"ANY objectIdObj != %@", objectId(1));
    RLMAssertCount(AllPrimitiveSets, 0, @"ANY uuidObj != %@", uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"));
    RLMAssertCount(AllPrimitiveSets, 0, @"ANY anyBoolObj != %@", @NO);
    RLMAssertCount(AllPrimitiveSets, 0, @"ANY anyIntObj != %@", @2);
    RLMAssertCount(AllPrimitiveSets, 0, @"ANY anyFloatObj != %@", @2.2f);
    RLMAssertCount(AllPrimitiveSets, 0, @"ANY anyDoubleObj != %@", @2.2);
    RLMAssertCount(AllPrimitiveSets, 0, @"ANY anyStringObj != %@", @"a");
    RLMAssertCount(AllPrimitiveSets, 0, @"ANY anyDataObj != %@", data(1));
    RLMAssertCount(AllPrimitiveSets, 0, @"ANY anyDateObj != %@", date(1));
    RLMAssertCount(AllPrimitiveSets, 0, @"ANY anyDecimalObj != %@", decimal128(1));
    RLMAssertCount(AllPrimitiveSets, 0, @"ANY anyObjectIdObj != %@", objectId(1));
    RLMAssertCount(AllPrimitiveSets, 0, @"ANY anyUUIDObj != %@", uuid(@"00000000-0000-0000-0000-000000000000"));
    RLMAssertCount(AllOptionalPrimitiveSets, 0, @"ANY boolObj != %@", NSNull.null);
    RLMAssertCount(AllOptionalPrimitiveSets, 0, @"ANY intObj != %@", NSNull.null);
    RLMAssertCount(AllOptionalPrimitiveSets, 0, @"ANY floatObj != %@", NSNull.null);
    RLMAssertCount(AllOptionalPrimitiveSets, 0, @"ANY doubleObj != %@", NSNull.null);
    RLMAssertCount(AllOptionalPrimitiveSets, 0, @"ANY stringObj != %@", NSNull.null);
    RLMAssertCount(AllOptionalPrimitiveSets, 0, @"ANY dataObj != %@", NSNull.null);
    RLMAssertCount(AllOptionalPrimitiveSets, 0, @"ANY dateObj != %@", NSNull.null);
    RLMAssertCount(AllOptionalPrimitiveSets, 0, @"ANY decimalObj != %@", NSNull.null);
    RLMAssertCount(AllOptionalPrimitiveSets, 0, @"ANY objectIdObj != %@", NSNull.null);
    RLMAssertCount(AllOptionalPrimitiveSets, 0, @"ANY uuidObj != %@", NSNull.null);
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY boolObj != %@", @YES);
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY intObj != %@", @3);
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY floatObj != %@", @3.3f);
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY doubleObj != %@", @3.3);
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY stringObj != %@", @"bc");
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY dataObj != %@", data(2));
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY dateObj != %@", date(2));
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY decimalObj != %@", decimal128(2));
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY objectIdObj != %@", objectId(2));
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY uuidObj != %@", uuid(@"00000000-0000-0000-0000-000000000000"));
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY anyBoolObj != %@", @YES);
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY anyIntObj != %@", @3);
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY anyFloatObj != %@", @3.3f);
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY anyDoubleObj != %@", @3.3);
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY anyStringObj != %@", @"b");
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY anyDataObj != %@", data(2));
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY anyDateObj != %@", date(2));
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY anyDecimalObj != %@", decimal128(2));
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY anyObjectIdObj != %@", objectId(2));
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY anyUUIDObj != %@", uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"));
    RLMAssertCount(AllOptionalPrimitiveSets, 1, @"ANY boolObj != %@", @NO);
    RLMAssertCount(AllOptionalPrimitiveSets, 1, @"ANY intObj != %@", @2);
    RLMAssertCount(AllOptionalPrimitiveSets, 1, @"ANY floatObj != %@", @2.2f);
    RLMAssertCount(AllOptionalPrimitiveSets, 1, @"ANY doubleObj != %@", @2.2);
    RLMAssertCount(AllOptionalPrimitiveSets, 1, @"ANY stringObj != %@", @"a");
    RLMAssertCount(AllOptionalPrimitiveSets, 1, @"ANY dataObj != %@", data(1));
    RLMAssertCount(AllOptionalPrimitiveSets, 1, @"ANY dateObj != %@", date(1));
    RLMAssertCount(AllOptionalPrimitiveSets, 1, @"ANY decimalObj != %@", decimal128(1));
    RLMAssertCount(AllOptionalPrimitiveSets, 1, @"ANY objectIdObj != %@", objectId(1));
    RLMAssertCount(AllOptionalPrimitiveSets, 1, @"ANY uuidObj != %@", uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"));
    RLMAssertCount(AllPrimitiveSets, 0, @"ANY intObj > %@", @2);
    RLMAssertCount(AllPrimitiveSets, 0, @"ANY floatObj > %@", @2.2f);
    RLMAssertCount(AllPrimitiveSets, 0, @"ANY doubleObj > %@", @2.2);
    RLMAssertCount(AllPrimitiveSets, 0, @"ANY dateObj > %@", date(1));
    RLMAssertCount(AllPrimitiveSets, 0, @"ANY decimalObj > %@", decimal128(1));
    RLMAssertCount(AllPrimitiveSets, 0, @"ANY anyIntObj > %@", @2);
    RLMAssertCount(AllPrimitiveSets, 0, @"ANY anyFloatObj > %@", @2.2f);
    RLMAssertCount(AllPrimitiveSets, 0, @"ANY anyDoubleObj > %@", @2.2);
    RLMAssertCount(AllPrimitiveSets, 0, @"ANY anyDateObj > %@", date(1));
    RLMAssertCount(AllPrimitiveSets, 0, @"ANY anyDecimalObj > %@", decimal128(1));
    RLMAssertCount(AllOptionalPrimitiveSets, 0, @"ANY intObj > %@", NSNull.null);
    RLMAssertCount(AllOptionalPrimitiveSets, 0, @"ANY floatObj > %@", NSNull.null);
    RLMAssertCount(AllOptionalPrimitiveSets, 0, @"ANY doubleObj > %@", NSNull.null);
    RLMAssertCount(AllOptionalPrimitiveSets, 0, @"ANY dateObj > %@", NSNull.null);
    RLMAssertCount(AllOptionalPrimitiveSets, 0, @"ANY decimalObj > %@", NSNull.null);
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY intObj >= %@", @2);
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY floatObj >= %@", @2.2f);
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY doubleObj >= %@", @2.2);
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY dateObj >= %@", date(1));
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY decimalObj >= %@", decimal128(1));
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY anyIntObj >= %@", @2);
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY anyFloatObj >= %@", @2.2f);
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY anyDoubleObj >= %@", @2.2);
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY anyDateObj >= %@", date(1));
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY anyDecimalObj >= %@", decimal128(1));
    RLMAssertCount(AllOptionalPrimitiveSets, 1, @"ANY intObj >= %@", NSNull.null);
    RLMAssertCount(AllOptionalPrimitiveSets, 1, @"ANY floatObj >= %@", NSNull.null);
    RLMAssertCount(AllOptionalPrimitiveSets, 1, @"ANY doubleObj >= %@", NSNull.null);
    RLMAssertCount(AllOptionalPrimitiveSets, 1, @"ANY dateObj >= %@", NSNull.null);
    RLMAssertCount(AllOptionalPrimitiveSets, 1, @"ANY decimalObj >= %@", NSNull.null);
    RLMAssertCount(AllPrimitiveSets, 0, @"ANY intObj < %@", @2);
    RLMAssertCount(AllPrimitiveSets, 0, @"ANY floatObj < %@", @2.2f);
    RLMAssertCount(AllPrimitiveSets, 0, @"ANY doubleObj < %@", @2.2);
    RLMAssertCount(AllPrimitiveSets, 0, @"ANY dateObj < %@", date(1));
    RLMAssertCount(AllPrimitiveSets, 0, @"ANY decimalObj < %@", decimal128(1));
    RLMAssertCount(AllPrimitiveSets, 0, @"ANY anyIntObj < %@", @2);
    RLMAssertCount(AllPrimitiveSets, 0, @"ANY anyFloatObj < %@", @2.2f);
    RLMAssertCount(AllPrimitiveSets, 0, @"ANY anyDoubleObj < %@", @2.2);
    RLMAssertCount(AllPrimitiveSets, 0, @"ANY anyDateObj < %@", date(1));
    RLMAssertCount(AllPrimitiveSets, 0, @"ANY anyDecimalObj < %@", decimal128(1));
    RLMAssertCount(AllOptionalPrimitiveSets, 0, @"ANY intObj < %@", NSNull.null);
    RLMAssertCount(AllOptionalPrimitiveSets, 0, @"ANY floatObj < %@", NSNull.null);
    RLMAssertCount(AllOptionalPrimitiveSets, 0, @"ANY doubleObj < %@", NSNull.null);
    RLMAssertCount(AllOptionalPrimitiveSets, 0, @"ANY dateObj < %@", NSNull.null);
    RLMAssertCount(AllOptionalPrimitiveSets, 0, @"ANY decimalObj < %@", NSNull.null);
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY intObj < %@", @3);
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY floatObj < %@", @3.3f);
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY doubleObj < %@", @3.3);
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY dateObj < %@", date(2));
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY decimalObj < %@", decimal128(2));
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY anyIntObj < %@", @3);
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY anyFloatObj < %@", @3.3f);
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY anyDoubleObj < %@", @3.3);
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY anyDateObj < %@", date(2));
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY anyDecimalObj < %@", decimal128(2));
    RLMAssertCount(AllOptionalPrimitiveSets, 0, @"ANY intObj < %@", @2);
    RLMAssertCount(AllOptionalPrimitiveSets, 0, @"ANY floatObj < %@", @2.2f);
    RLMAssertCount(AllOptionalPrimitiveSets, 0, @"ANY doubleObj < %@", @2.2);
    RLMAssertCount(AllOptionalPrimitiveSets, 0, @"ANY dateObj < %@", date(1));
    RLMAssertCount(AllOptionalPrimitiveSets, 0, @"ANY decimalObj < %@", decimal128(1));
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY intObj <= %@", @2);
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY floatObj <= %@", @2.2f);
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY doubleObj <= %@", @2.2);
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY dateObj <= %@", date(1));
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY decimalObj <= %@", decimal128(1));
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY anyIntObj <= %@", @2);
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY anyFloatObj <= %@", @2.2f);
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY anyDoubleObj <= %@", @2.2);
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY anyDateObj <= %@", date(1));
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY anyDecimalObj <= %@", decimal128(1));
    RLMAssertCount(AllOptionalPrimitiveSets, 1, @"ANY intObj <= %@", NSNull.null);
    RLMAssertCount(AllOptionalPrimitiveSets, 1, @"ANY floatObj <= %@", NSNull.null);
    RLMAssertCount(AllOptionalPrimitiveSets, 1, @"ANY doubleObj <= %@", NSNull.null);
    RLMAssertCount(AllOptionalPrimitiveSets, 1, @"ANY dateObj <= %@", NSNull.null);
    RLMAssertCount(AllOptionalPrimitiveSets, 1, @"ANY decimalObj <= %@", NSNull.null);

    [self createObjectWithValueIndex:1];

    RLMAssertCount(AllPrimitiveSets, 1, @"ANY boolObj = %@", @NO);
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY intObj = %@", @2);
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY floatObj = %@", @2.2f);
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY doubleObj = %@", @2.2);
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY stringObj = %@", @"a");
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY dataObj = %@", data(1));
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY dateObj = %@", date(1));
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY decimalObj = %@", decimal128(1));
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY objectIdObj = %@", objectId(1));
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY uuidObj = %@", uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"));
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY anyBoolObj = %@", @NO);
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY anyIntObj = %@", @2);
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY anyFloatObj = %@", @2.2f);
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY anyDoubleObj = %@", @2.2);
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY anyStringObj = %@", @"a");
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY anyDataObj = %@", data(1));
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY anyDateObj = %@", date(1));
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY anyDecimalObj = %@", decimal128(1));
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY anyObjectIdObj = %@", objectId(1));
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY anyUUIDObj = %@", uuid(@"00000000-0000-0000-0000-000000000000"));
    RLMAssertCount(AllOptionalPrimitiveSets, 1, @"ANY boolObj = %@", NSNull.null);
    RLMAssertCount(AllOptionalPrimitiveSets, 1, @"ANY intObj = %@", NSNull.null);
    RLMAssertCount(AllOptionalPrimitiveSets, 1, @"ANY floatObj = %@", NSNull.null);
    RLMAssertCount(AllOptionalPrimitiveSets, 1, @"ANY doubleObj = %@", NSNull.null);
    RLMAssertCount(AllOptionalPrimitiveSets, 1, @"ANY stringObj = %@", NSNull.null);
    RLMAssertCount(AllOptionalPrimitiveSets, 1, @"ANY dataObj = %@", NSNull.null);
    RLMAssertCount(AllOptionalPrimitiveSets, 1, @"ANY dateObj = %@", NSNull.null);
    RLMAssertCount(AllOptionalPrimitiveSets, 1, @"ANY decimalObj = %@", NSNull.null);
    RLMAssertCount(AllOptionalPrimitiveSets, 1, @"ANY objectIdObj = %@", NSNull.null);
    RLMAssertCount(AllOptionalPrimitiveSets, 1, @"ANY uuidObj = %@", NSNull.null);
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY boolObj = %@", @YES);
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY intObj = %@", @3);
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY floatObj = %@", @3.3f);
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY doubleObj = %@", @3.3);
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY stringObj = %@", @"bc");
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY dataObj = %@", data(2));
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY dateObj = %@", date(2));
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY decimalObj = %@", decimal128(2));
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY objectIdObj = %@", objectId(2));
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY uuidObj = %@", uuid(@"00000000-0000-0000-0000-000000000000"));
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY anyBoolObj = %@", @YES);
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY anyIntObj = %@", @3);
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY anyFloatObj = %@", @3.3f);
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY anyDoubleObj = %@", @3.3);
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY anyStringObj = %@", @"b");
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY anyDataObj = %@", data(2));
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY anyDateObj = %@", date(2));
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY anyDecimalObj = %@", decimal128(2));
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY anyObjectIdObj = %@", objectId(2));
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY anyUUIDObj = %@", uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"));
    RLMAssertCount(AllOptionalPrimitiveSets, 1, @"ANY boolObj = %@", @NO);
    RLMAssertCount(AllOptionalPrimitiveSets, 1, @"ANY intObj = %@", @2);
    RLMAssertCount(AllOptionalPrimitiveSets, 1, @"ANY floatObj = %@", @2.2f);
    RLMAssertCount(AllOptionalPrimitiveSets, 1, @"ANY doubleObj = %@", @2.2);
    RLMAssertCount(AllOptionalPrimitiveSets, 1, @"ANY stringObj = %@", @"a");
    RLMAssertCount(AllOptionalPrimitiveSets, 1, @"ANY dataObj = %@", data(1));
    RLMAssertCount(AllOptionalPrimitiveSets, 1, @"ANY dateObj = %@", date(1));
    RLMAssertCount(AllOptionalPrimitiveSets, 1, @"ANY decimalObj = %@", decimal128(1));
    RLMAssertCount(AllOptionalPrimitiveSets, 1, @"ANY objectIdObj = %@", objectId(1));
    RLMAssertCount(AllOptionalPrimitiveSets, 1, @"ANY uuidObj = %@", uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"));
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY boolObj != %@", @NO);
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY intObj != %@", @2);
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY floatObj != %@", @2.2f);
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY doubleObj != %@", @2.2);
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY stringObj != %@", @"a");
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY dataObj != %@", data(1));
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY dateObj != %@", date(1));
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY decimalObj != %@", decimal128(1));
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY objectIdObj != %@", objectId(1));
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY uuidObj != %@", uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"));
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY anyBoolObj != %@", @NO);
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY anyIntObj != %@", @2);
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY anyFloatObj != %@", @2.2f);
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY anyDoubleObj != %@", @2.2);
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY anyStringObj != %@", @"a");
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY anyDataObj != %@", data(1));
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY anyDateObj != %@", date(1));
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY anyDecimalObj != %@", decimal128(1));
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY anyObjectIdObj != %@", objectId(1));
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY anyUUIDObj != %@", uuid(@"00000000-0000-0000-0000-000000000000"));
    RLMAssertCount(AllOptionalPrimitiveSets, 1, @"ANY boolObj != %@", NSNull.null);
    RLMAssertCount(AllOptionalPrimitiveSets, 1, @"ANY intObj != %@", NSNull.null);
    RLMAssertCount(AllOptionalPrimitiveSets, 1, @"ANY floatObj != %@", NSNull.null);
    RLMAssertCount(AllOptionalPrimitiveSets, 1, @"ANY doubleObj != %@", NSNull.null);
    RLMAssertCount(AllOptionalPrimitiveSets, 1, @"ANY stringObj != %@", NSNull.null);
    RLMAssertCount(AllOptionalPrimitiveSets, 1, @"ANY dataObj != %@", NSNull.null);
    RLMAssertCount(AllOptionalPrimitiveSets, 1, @"ANY dateObj != %@", NSNull.null);
    RLMAssertCount(AllOptionalPrimitiveSets, 1, @"ANY decimalObj != %@", NSNull.null);
    RLMAssertCount(AllOptionalPrimitiveSets, 1, @"ANY objectIdObj != %@", NSNull.null);
    RLMAssertCount(AllOptionalPrimitiveSets, 1, @"ANY uuidObj != %@", NSNull.null);
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY boolObj != %@", @YES);
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY intObj != %@", @3);
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY floatObj != %@", @3.3f);
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY doubleObj != %@", @3.3);
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY stringObj != %@", @"bc");
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY dataObj != %@", data(2));
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY dateObj != %@", date(2));
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY decimalObj != %@", decimal128(2));
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY objectIdObj != %@", objectId(2));
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY uuidObj != %@", uuid(@"00000000-0000-0000-0000-000000000000"));
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY anyBoolObj != %@", @YES);
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY anyIntObj != %@", @3);
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY anyFloatObj != %@", @3.3f);
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY anyDoubleObj != %@", @3.3);
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY anyStringObj != %@", @"b");
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY anyDataObj != %@", data(2));
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY anyDateObj != %@", date(2));
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY anyDecimalObj != %@", decimal128(2));
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY anyObjectIdObj != %@", objectId(2));
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY anyUUIDObj != %@", uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"));
    RLMAssertCount(AllOptionalPrimitiveSets, 1, @"ANY boolObj != %@", @NO);
    RLMAssertCount(AllOptionalPrimitiveSets, 1, @"ANY intObj != %@", @2);
    RLMAssertCount(AllOptionalPrimitiveSets, 1, @"ANY floatObj != %@", @2.2f);
    RLMAssertCount(AllOptionalPrimitiveSets, 1, @"ANY doubleObj != %@", @2.2);
    RLMAssertCount(AllOptionalPrimitiveSets, 1, @"ANY stringObj != %@", @"a");
    RLMAssertCount(AllOptionalPrimitiveSets, 1, @"ANY dataObj != %@", data(1));
    RLMAssertCount(AllOptionalPrimitiveSets, 1, @"ANY dateObj != %@", date(1));
    RLMAssertCount(AllOptionalPrimitiveSets, 1, @"ANY decimalObj != %@", decimal128(1));
    RLMAssertCount(AllOptionalPrimitiveSets, 1, @"ANY objectIdObj != %@", objectId(1));
    RLMAssertCount(AllOptionalPrimitiveSets, 1, @"ANY uuidObj != %@", uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"));
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY intObj > %@", @2);
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY floatObj > %@", @2.2f);
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY doubleObj > %@", @2.2);
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY dateObj > %@", date(1));
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY decimalObj > %@", decimal128(1));
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY anyIntObj > %@", @2);
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY anyFloatObj > %@", @2.2f);
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY anyDoubleObj > %@", @2.2);
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY anyDateObj > %@", date(1));
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY anyDecimalObj > %@", decimal128(1));
    RLMAssertCount(AllPrimitiveSets, 2, @"ANY intObj >= %@", @2);
    RLMAssertCount(AllPrimitiveSets, 2, @"ANY floatObj >= %@", @2.2f);
    RLMAssertCount(AllPrimitiveSets, 2, @"ANY doubleObj >= %@", @2.2);
    RLMAssertCount(AllPrimitiveSets, 2, @"ANY dateObj >= %@", date(1));
    RLMAssertCount(AllPrimitiveSets, 2, @"ANY decimalObj >= %@", decimal128(1));
    RLMAssertCount(AllPrimitiveSets, 2, @"ANY anyIntObj >= %@", @2);
    RLMAssertCount(AllPrimitiveSets, 2, @"ANY anyFloatObj >= %@", @2.2f);
    RLMAssertCount(AllPrimitiveSets, 2, @"ANY anyDoubleObj >= %@", @2.2);
    RLMAssertCount(AllPrimitiveSets, 2, @"ANY anyDateObj >= %@", date(1));
    RLMAssertCount(AllPrimitiveSets, 2, @"ANY anyDecimalObj >= %@", decimal128(1));
    RLMAssertCount(AllPrimitiveSets, 0, @"ANY intObj < %@", @2);
    RLMAssertCount(AllPrimitiveSets, 0, @"ANY floatObj < %@", @2.2f);
    RLMAssertCount(AllPrimitiveSets, 0, @"ANY doubleObj < %@", @2.2);
    RLMAssertCount(AllPrimitiveSets, 0, @"ANY dateObj < %@", date(1));
    RLMAssertCount(AllPrimitiveSets, 0, @"ANY decimalObj < %@", decimal128(1));
    RLMAssertCount(AllPrimitiveSets, 0, @"ANY anyIntObj < %@", @2);
    RLMAssertCount(AllPrimitiveSets, 0, @"ANY anyFloatObj < %@", @2.2f);
    RLMAssertCount(AllPrimitiveSets, 0, @"ANY anyDoubleObj < %@", @2.2);
    RLMAssertCount(AllPrimitiveSets, 0, @"ANY anyDateObj < %@", date(1));
    RLMAssertCount(AllPrimitiveSets, 0, @"ANY anyDecimalObj < %@", decimal128(1));
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY intObj < %@", @3);
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY floatObj < %@", @3.3f);
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY doubleObj < %@", @3.3);
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY dateObj < %@", date(2));
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY decimalObj < %@", decimal128(2));
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY anyIntObj < %@", @3);
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY anyFloatObj < %@", @3.3f);
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY anyDoubleObj < %@", @3.3);
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY anyDateObj < %@", date(2));
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY anyDecimalObj < %@", decimal128(2));
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY intObj <= %@", @2);
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY floatObj <= %@", @2.2f);
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY doubleObj <= %@", @2.2);
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY dateObj <= %@", date(1));
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY decimalObj <= %@", decimal128(1));
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY anyIntObj <= %@", @2);
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY anyFloatObj <= %@", @2.2f);
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY anyDoubleObj <= %@", @2.2);
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY anyDateObj <= %@", date(1));
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY anyDecimalObj <= %@", decimal128(1));
    RLMAssertCount(AllPrimitiveSets, 2, @"ANY intObj <= %@", @3);
    RLMAssertCount(AllPrimitiveSets, 2, @"ANY floatObj <= %@", @3.3f);
    RLMAssertCount(AllPrimitiveSets, 2, @"ANY doubleObj <= %@", @3.3);
    RLMAssertCount(AllPrimitiveSets, 2, @"ANY dateObj <= %@", date(2));
    RLMAssertCount(AllPrimitiveSets, 2, @"ANY decimalObj <= %@", decimal128(2));
    RLMAssertCount(AllPrimitiveSets, 2, @"ANY anyIntObj <= %@", @3);
    RLMAssertCount(AllPrimitiveSets, 2, @"ANY anyFloatObj <= %@", @3.3f);
    RLMAssertCount(AllPrimitiveSets, 2, @"ANY anyDoubleObj <= %@", @3.3);
    RLMAssertCount(AllPrimitiveSets, 2, @"ANY anyDateObj <= %@", date(2));
    RLMAssertCount(AllPrimitiveSets, 2, @"ANY anyDecimalObj <= %@", decimal128(2));

    RLMAssertCount(AllOptionalPrimitiveSets, 0, @"ANY intObj > %@", NSNull.null);
    RLMAssertCount(AllOptionalPrimitiveSets, 0, @"ANY floatObj > %@", NSNull.null);
    RLMAssertCount(AllOptionalPrimitiveSets, 0, @"ANY doubleObj > %@", NSNull.null);
    RLMAssertCount(AllOptionalPrimitiveSets, 0, @"ANY dateObj > %@", NSNull.null);
    RLMAssertCount(AllOptionalPrimitiveSets, 0, @"ANY decimalObj > %@", NSNull.null);
    RLMAssertCount(AllOptionalPrimitiveSets, 1, @"ANY intObj >= %@", @2);
    RLMAssertCount(AllOptionalPrimitiveSets, 1, @"ANY floatObj >= %@", @2.2f);
    RLMAssertCount(AllOptionalPrimitiveSets, 1, @"ANY doubleObj >= %@", @2.2);
    RLMAssertCount(AllOptionalPrimitiveSets, 1, @"ANY dateObj >= %@", date(1));
    RLMAssertCount(AllOptionalPrimitiveSets, 1, @"ANY decimalObj >= %@", decimal128(1));
    RLMAssertCount(AllOptionalPrimitiveSets, 0, @"ANY intObj < %@", @2);
    RLMAssertCount(AllOptionalPrimitiveSets, 0, @"ANY floatObj < %@", @2.2f);
    RLMAssertCount(AllOptionalPrimitiveSets, 0, @"ANY doubleObj < %@", @2.2);
    RLMAssertCount(AllOptionalPrimitiveSets, 0, @"ANY dateObj < %@", date(1));
    RLMAssertCount(AllOptionalPrimitiveSets, 0, @"ANY decimalObj < %@", decimal128(1));
    RLMAssertCount(AllOptionalPrimitiveSets, 1, @"ANY intObj < %@", @3);
    RLMAssertCount(AllOptionalPrimitiveSets, 1, @"ANY floatObj < %@", @3.3f);
    RLMAssertCount(AllOptionalPrimitiveSets, 1, @"ANY doubleObj < %@", @3.3);
    RLMAssertCount(AllOptionalPrimitiveSets, 1, @"ANY dateObj < %@", date(2));
    RLMAssertCount(AllOptionalPrimitiveSets, 1, @"ANY decimalObj < %@", decimal128(2));
    RLMAssertCount(AllOptionalPrimitiveSets, 1, @"ANY intObj <= %@", NSNull.null);
    RLMAssertCount(AllOptionalPrimitiveSets, 1, @"ANY floatObj <= %@", NSNull.null);
    RLMAssertCount(AllOptionalPrimitiveSets, 1, @"ANY doubleObj <= %@", NSNull.null);
    RLMAssertCount(AllOptionalPrimitiveSets, 1, @"ANY dateObj <= %@", NSNull.null);
    RLMAssertCount(AllOptionalPrimitiveSets, 1, @"ANY decimalObj <= %@", NSNull.null);
    RLMAssertCount(AllOptionalPrimitiveSets, 1, @"ANY intObj <= %@", @2);
    RLMAssertCount(AllOptionalPrimitiveSets, 1, @"ANY floatObj <= %@", @2.2f);
    RLMAssertCount(AllOptionalPrimitiveSets, 1, @"ANY doubleObj <= %@", @2.2);
    RLMAssertCount(AllOptionalPrimitiveSets, 1, @"ANY dateObj <= %@", date(1));
    RLMAssertCount(AllOptionalPrimitiveSets, 1, @"ANY decimalObj <= %@", decimal128(1));

    RLMAssertThrows(([AllPrimitiveSets objectsInRealm:realm where:@"ANY boolObj > %@", @NO]));
    RLMAssertThrows(([AllPrimitiveSets objectsInRealm:realm where:@"ANY stringObj > %@", @"a"]));
    RLMAssertThrows(([AllPrimitiveSets objectsInRealm:realm where:@"ANY dataObj > %@", data(1)]));
    RLMAssertThrows(([AllPrimitiveSets objectsInRealm:realm where:@"ANY objectIdObj > %@", objectId(1)]));
    RLMAssertThrows(([AllPrimitiveSets objectsInRealm:realm where:@"ANY uuidObj > %@", uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")]));
    RLMAssertThrows(([AllOptionalPrimitiveSets objectsInRealm:realm where:@"ANY boolObj > %@", NSNull.null]));
    RLMAssertThrows(([AllOptionalPrimitiveSets objectsInRealm:realm where:@"ANY stringObj > %@", NSNull.null]));
    RLMAssertThrows(([AllOptionalPrimitiveSets objectsInRealm:realm where:@"ANY dataObj > %@", NSNull.null]));
    RLMAssertThrows(([AllOptionalPrimitiveSets objectsInRealm:realm where:@"ANY objectIdObj > %@", NSNull.null]));
    RLMAssertThrows(([AllOptionalPrimitiveSets objectsInRealm:realm where:@"ANY uuidObj > %@", NSNull.null]));
}

- (void)testQueryBetween {
    [realm deleteAllObjects];

    RLMAssertThrowsWithReason(([AllPrimitiveSets objectsInRealm:realm where:@"ANY boolObj BETWEEN %@", @[@NO, @YES]]), 
                              @"Operator 'BETWEEN' not supported for type 'bool'");
    RLMAssertThrowsWithReason(([AllPrimitiveSets objectsInRealm:realm where:@"ANY stringObj BETWEEN %@", @[@"a", @"bc"]]), 
                              @"Operator 'BETWEEN' not supported for type 'string'");
    RLMAssertThrowsWithReason(([AllPrimitiveSets objectsInRealm:realm where:@"ANY dataObj BETWEEN %@", @[data(1), data(2)]]), 
                              @"Operator 'BETWEEN' not supported for type 'data'");
    RLMAssertThrowsWithReason(([AllPrimitiveSets objectsInRealm:realm where:@"ANY objectIdObj BETWEEN %@", @[objectId(1), objectId(2)]]), 
                              @"Operator 'BETWEEN' not supported for type 'object id'");
    RLMAssertThrowsWithReason(([AllPrimitiveSets objectsInRealm:realm where:@"ANY uuidObj BETWEEN %@", @[uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"), uuid(@"00000000-0000-0000-0000-000000000000")]]), 
                              @"Operator 'BETWEEN' not supported for type 'uuid'");
    RLMAssertThrowsWithReason(([AllOptionalPrimitiveSets objectsInRealm:realm where:@"ANY boolObj BETWEEN %@", @[NSNull.null, @NO]]), 
                              @"Operator 'BETWEEN' not supported for type 'bool'");
    RLMAssertThrowsWithReason(([AllOptionalPrimitiveSets objectsInRealm:realm where:@"ANY stringObj BETWEEN %@", @[NSNull.null, @"a"]]), 
                              @"Operator 'BETWEEN' not supported for type 'string'");
    RLMAssertThrowsWithReason(([AllOptionalPrimitiveSets objectsInRealm:realm where:@"ANY dataObj BETWEEN %@", @[NSNull.null, data(1)]]), 
                              @"Operator 'BETWEEN' not supported for type 'data'");
    RLMAssertThrowsWithReason(([AllOptionalPrimitiveSets objectsInRealm:realm where:@"ANY objectIdObj BETWEEN %@", @[NSNull.null, objectId(1)]]), 
                              @"Operator 'BETWEEN' not supported for type 'object id'");
    RLMAssertThrowsWithReason(([AllOptionalPrimitiveSets objectsInRealm:realm where:@"ANY uuidObj BETWEEN %@", @[NSNull.null, uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")]]), 
                              @"Operator 'BETWEEN' not supported for type 'uuid'");

    RLMAssertCount(AllPrimitiveSets, 0, @"ANY intObj BETWEEN %@", @[@2, @3]);
    RLMAssertCount(AllPrimitiveSets, 0, @"ANY floatObj BETWEEN %@", @[@2.2f, @3.3f]);
    RLMAssertCount(AllPrimitiveSets, 0, @"ANY doubleObj BETWEEN %@", @[@2.2, @3.3]);
    RLMAssertCount(AllPrimitiveSets, 0, @"ANY dateObj BETWEEN %@", @[date(1), date(2)]);
    RLMAssertCount(AllPrimitiveSets, 0, @"ANY decimalObj BETWEEN %@", @[decimal128(1), decimal128(2)]);
    RLMAssertCount(AllPrimitiveSets, 0, @"ANY anyIntObj BETWEEN %@", @[@2, @3]);
    RLMAssertCount(AllPrimitiveSets, 0, @"ANY anyFloatObj BETWEEN %@", @[@2.2f, @3.3f]);
    RLMAssertCount(AllPrimitiveSets, 0, @"ANY anyDoubleObj BETWEEN %@", @[@2.2, @3.3]);
    RLMAssertCount(AllPrimitiveSets, 0, @"ANY anyDateObj BETWEEN %@", @[date(1), date(2)]);
    RLMAssertCount(AllPrimitiveSets, 0, @"ANY anyDecimalObj BETWEEN %@", @[decimal128(1), decimal128(2)]);
    RLMAssertCount(AllOptionalPrimitiveSets, 0, @"ANY intObj BETWEEN %@", @[NSNull.null, @2]);
    RLMAssertCount(AllOptionalPrimitiveSets, 0, @"ANY floatObj BETWEEN %@", @[NSNull.null, @2.2f]);
    RLMAssertCount(AllOptionalPrimitiveSets, 0, @"ANY doubleObj BETWEEN %@", @[NSNull.null, @2.2]);
    RLMAssertCount(AllOptionalPrimitiveSets, 0, @"ANY dateObj BETWEEN %@", @[NSNull.null, date(1)]);
    RLMAssertCount(AllOptionalPrimitiveSets, 0, @"ANY decimalObj BETWEEN %@", @[NSNull.null, decimal128(1)]);

    [self createObjectWithValueIndex:1];

    RLMAssertCount(AllPrimitiveSets, 1, @"ANY intObj BETWEEN %@", @[@3, @3]);
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY floatObj BETWEEN %@", @[@3.3f, @3.3f]);
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY doubleObj BETWEEN %@", @[@3.3, @3.3]);
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY dateObj BETWEEN %@", @[date(2), date(2)]);
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY decimalObj BETWEEN %@", @[decimal128(2), decimal128(2)]);
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY anyIntObj BETWEEN %@", @[@3, @3]);
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY anyFloatObj BETWEEN %@", @[@3.3f, @3.3f]);
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY anyDoubleObj BETWEEN %@", @[@3.3, @3.3]);
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY anyDateObj BETWEEN %@", @[date(2), date(2)]);
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY anyDecimalObj BETWEEN %@", @[decimal128(2), decimal128(2)]);
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY intObj BETWEEN %@", @[@2, @3]);
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY floatObj BETWEEN %@", @[@2.2f, @3.3f]);
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY doubleObj BETWEEN %@", @[@2.2, @3.3]);
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY dateObj BETWEEN %@", @[date(1), date(2)]);
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY decimalObj BETWEEN %@", @[decimal128(1), decimal128(2)]);
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY anyIntObj BETWEEN %@", @[@2, @3]);
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY anyFloatObj BETWEEN %@", @[@2.2f, @3.3f]);
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY anyDoubleObj BETWEEN %@", @[@2.2, @3.3]);
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY anyDateObj BETWEEN %@", @[date(1), date(2)]);
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY anyDecimalObj BETWEEN %@", @[decimal128(1), decimal128(2)]);
    RLMAssertCount(AllPrimitiveSets, 0, @"ANY intObj BETWEEN %@", @[@2, @2]);
    RLMAssertCount(AllPrimitiveSets, 0, @"ANY floatObj BETWEEN %@", @[@2.2f, @2.2f]);
    RLMAssertCount(AllPrimitiveSets, 0, @"ANY doubleObj BETWEEN %@", @[@2.2, @2.2]);
    RLMAssertCount(AllPrimitiveSets, 0, @"ANY dateObj BETWEEN %@", @[date(1), date(1)]);
    RLMAssertCount(AllPrimitiveSets, 0, @"ANY decimalObj BETWEEN %@", @[decimal128(1), decimal128(1)]);
    RLMAssertCount(AllPrimitiveSets, 0, @"ANY anyIntObj BETWEEN %@", @[@2, @2]);
    RLMAssertCount(AllPrimitiveSets, 0, @"ANY anyFloatObj BETWEEN %@", @[@2.2f, @2.2f]);
    RLMAssertCount(AllPrimitiveSets, 0, @"ANY anyDoubleObj BETWEEN %@", @[@2.2, @2.2]);
    RLMAssertCount(AllPrimitiveSets, 0, @"ANY anyDateObj BETWEEN %@", @[date(1), date(1)]);
    RLMAssertCount(AllPrimitiveSets, 0, @"ANY anyDecimalObj BETWEEN %@", @[decimal128(1), decimal128(1)]);

    RLMAssertCount(AllOptionalPrimitiveSets, 1, @"ANY intObj BETWEEN %@", @[@2, @2]);
    RLMAssertCount(AllOptionalPrimitiveSets, 1, @"ANY floatObj BETWEEN %@", @[@2.2f, @2.2f]);
    RLMAssertCount(AllOptionalPrimitiveSets, 1, @"ANY doubleObj BETWEEN %@", @[@2.2, @2.2]);
    RLMAssertCount(AllOptionalPrimitiveSets, 1, @"ANY dateObj BETWEEN %@", @[date(1), date(1)]);
    RLMAssertCount(AllOptionalPrimitiveSets, 1, @"ANY decimalObj BETWEEN %@", @[decimal128(1), decimal128(1)]);
    RLMAssertCount(AllOptionalPrimitiveSets, 1, @"ANY intObj BETWEEN %@", @[@2, @3]);
    RLMAssertCount(AllOptionalPrimitiveSets, 1, @"ANY floatObj BETWEEN %@", @[@2.2f, @3.3f]);
    RLMAssertCount(AllOptionalPrimitiveSets, 1, @"ANY doubleObj BETWEEN %@", @[@2.2, @3.3]);
    RLMAssertCount(AllOptionalPrimitiveSets, 1, @"ANY dateObj BETWEEN %@", @[date(1), date(2)]);
    RLMAssertCount(AllOptionalPrimitiveSets, 1, @"ANY decimalObj BETWEEN %@", @[decimal128(1), decimal128(2)]);
    RLMAssertCount(AllOptionalPrimitiveSets, 0, @"ANY intObj BETWEEN %@", @[@3, @3]);
    RLMAssertCount(AllOptionalPrimitiveSets, 0, @"ANY floatObj BETWEEN %@", @[@3.3f, @3.3f]);
    RLMAssertCount(AllOptionalPrimitiveSets, 0, @"ANY doubleObj BETWEEN %@", @[@3.3, @3.3]);
    RLMAssertCount(AllOptionalPrimitiveSets, 0, @"ANY dateObj BETWEEN %@", @[date(2), date(2)]);
    RLMAssertCount(AllOptionalPrimitiveSets, 0, @"ANY decimalObj BETWEEN %@", @[decimal128(2), decimal128(2)]);
}

- (void)testQueryIn {
    [realm deleteAllObjects];

    RLMAssertCount(AllPrimitiveSets, 0, @"ANY boolObj IN %@", @[@NO, @YES]);
    RLMAssertCount(AllPrimitiveSets, 0, @"ANY intObj IN %@", @[@2, @3]);
    RLMAssertCount(AllPrimitiveSets, 0, @"ANY floatObj IN %@", @[@2.2f, @3.3f]);
    RLMAssertCount(AllPrimitiveSets, 0, @"ANY doubleObj IN %@", @[@2.2, @3.3]);
    RLMAssertCount(AllPrimitiveSets, 0, @"ANY stringObj IN %@", @[@"a", @"bc"]);
    RLMAssertCount(AllPrimitiveSets, 0, @"ANY dataObj IN %@", @[data(1), data(2)]);
    RLMAssertCount(AllPrimitiveSets, 0, @"ANY dateObj IN %@", @[date(1), date(2)]);
    RLMAssertCount(AllPrimitiveSets, 0, @"ANY decimalObj IN %@", @[decimal128(1), decimal128(2)]);
    RLMAssertCount(AllPrimitiveSets, 0, @"ANY objectIdObj IN %@", @[objectId(1), objectId(2)]);
    RLMAssertCount(AllPrimitiveSets, 0, @"ANY uuidObj IN %@", @[uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"), uuid(@"00000000-0000-0000-0000-000000000000")]);
    RLMAssertCount(AllPrimitiveSets, 0, @"ANY anyBoolObj IN %@", @[@NO, @YES]);
    RLMAssertCount(AllPrimitiveSets, 0, @"ANY anyIntObj IN %@", @[@2, @3]);
    RLMAssertCount(AllPrimitiveSets, 0, @"ANY anyFloatObj IN %@", @[@2.2f, @3.3f]);
    RLMAssertCount(AllPrimitiveSets, 0, @"ANY anyDoubleObj IN %@", @[@2.2, @3.3]);
    RLMAssertCount(AllPrimitiveSets, 0, @"ANY anyStringObj IN %@", @[@"a", @"b"]);
    RLMAssertCount(AllPrimitiveSets, 0, @"ANY anyDataObj IN %@", @[data(1), data(2)]);
    RLMAssertCount(AllPrimitiveSets, 0, @"ANY anyDateObj IN %@", @[date(1), date(2)]);
    RLMAssertCount(AllPrimitiveSets, 0, @"ANY anyDecimalObj IN %@", @[decimal128(1), decimal128(2)]);
    RLMAssertCount(AllPrimitiveSets, 0, @"ANY anyObjectIdObj IN %@", @[objectId(1), objectId(2)]);
    RLMAssertCount(AllPrimitiveSets, 0, @"ANY anyUUIDObj IN %@", @[uuid(@"00000000-0000-0000-0000-000000000000"), uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")]);
    RLMAssertCount(AllOptionalPrimitiveSets, 0, @"ANY boolObj IN %@", @[NSNull.null, @NO]);
    RLMAssertCount(AllOptionalPrimitiveSets, 0, @"ANY intObj IN %@", @[NSNull.null, @2]);
    RLMAssertCount(AllOptionalPrimitiveSets, 0, @"ANY floatObj IN %@", @[NSNull.null, @2.2f]);
    RLMAssertCount(AllOptionalPrimitiveSets, 0, @"ANY doubleObj IN %@", @[NSNull.null, @2.2]);
    RLMAssertCount(AllOptionalPrimitiveSets, 0, @"ANY stringObj IN %@", @[NSNull.null, @"a"]);
    RLMAssertCount(AllOptionalPrimitiveSets, 0, @"ANY dataObj IN %@", @[NSNull.null, data(1)]);
    RLMAssertCount(AllOptionalPrimitiveSets, 0, @"ANY dateObj IN %@", @[NSNull.null, date(1)]);
    RLMAssertCount(AllOptionalPrimitiveSets, 0, @"ANY decimalObj IN %@", @[NSNull.null, decimal128(1)]);
    RLMAssertCount(AllOptionalPrimitiveSets, 0, @"ANY objectIdObj IN %@", @[NSNull.null, objectId(1)]);
    RLMAssertCount(AllOptionalPrimitiveSets, 0, @"ANY uuidObj IN %@", @[NSNull.null, uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")]);

    [self createObjectWithValueIndex:0];

    RLMAssertCount(AllPrimitiveSets, 0, @"ANY boolObj IN %@", @[@YES]);
    RLMAssertCount(AllPrimitiveSets, 0, @"ANY intObj IN %@", @[@3]);
    RLMAssertCount(AllPrimitiveSets, 0, @"ANY floatObj IN %@", @[@3.3f]);
    RLMAssertCount(AllPrimitiveSets, 0, @"ANY doubleObj IN %@", @[@3.3]);
    RLMAssertCount(AllPrimitiveSets, 0, @"ANY stringObj IN %@", @[@"bc"]);
    RLMAssertCount(AllPrimitiveSets, 0, @"ANY dataObj IN %@", @[data(2)]);
    RLMAssertCount(AllPrimitiveSets, 0, @"ANY dateObj IN %@", @[date(2)]);
    RLMAssertCount(AllPrimitiveSets, 0, @"ANY decimalObj IN %@", @[decimal128(2)]);
    RLMAssertCount(AllPrimitiveSets, 0, @"ANY objectIdObj IN %@", @[objectId(2)]);
    RLMAssertCount(AllPrimitiveSets, 0, @"ANY uuidObj IN %@", @[uuid(@"00000000-0000-0000-0000-000000000000")]);
    RLMAssertCount(AllPrimitiveSets, 0, @"ANY anyBoolObj IN %@", @[@YES]);
    RLMAssertCount(AllPrimitiveSets, 0, @"ANY anyIntObj IN %@", @[@3]);
    RLMAssertCount(AllPrimitiveSets, 0, @"ANY anyFloatObj IN %@", @[@3.3f]);
    RLMAssertCount(AllPrimitiveSets, 0, @"ANY anyDoubleObj IN %@", @[@3.3]);
    RLMAssertCount(AllPrimitiveSets, 0, @"ANY anyStringObj IN %@", @[@"b"]);
    RLMAssertCount(AllPrimitiveSets, 0, @"ANY anyDataObj IN %@", @[data(2)]);
    RLMAssertCount(AllPrimitiveSets, 0, @"ANY anyDateObj IN %@", @[date(2)]);
    RLMAssertCount(AllPrimitiveSets, 0, @"ANY anyDecimalObj IN %@", @[decimal128(2)]);
    RLMAssertCount(AllPrimitiveSets, 0, @"ANY anyObjectIdObj IN %@", @[objectId(2)]);
    RLMAssertCount(AllPrimitiveSets, 0, @"ANY anyUUIDObj IN %@", @[uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")]);
    RLMAssertCount(AllOptionalPrimitiveSets, 0, @"ANY boolObj IN %@", @[@NO]);
    RLMAssertCount(AllOptionalPrimitiveSets, 0, @"ANY intObj IN %@", @[@2]);
    RLMAssertCount(AllOptionalPrimitiveSets, 0, @"ANY floatObj IN %@", @[@2.2f]);
    RLMAssertCount(AllOptionalPrimitiveSets, 0, @"ANY doubleObj IN %@", @[@2.2]);
    RLMAssertCount(AllOptionalPrimitiveSets, 0, @"ANY stringObj IN %@", @[@"a"]);
    RLMAssertCount(AllOptionalPrimitiveSets, 0, @"ANY dataObj IN %@", @[data(1)]);
    RLMAssertCount(AllOptionalPrimitiveSets, 0, @"ANY dateObj IN %@", @[date(1)]);
    RLMAssertCount(AllOptionalPrimitiveSets, 0, @"ANY decimalObj IN %@", @[decimal128(1)]);
    RLMAssertCount(AllOptionalPrimitiveSets, 0, @"ANY objectIdObj IN %@", @[objectId(1)]);
    RLMAssertCount(AllOptionalPrimitiveSets, 0, @"ANY uuidObj IN %@", @[uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")]);
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY boolObj IN %@", @[@NO, @YES]);
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY intObj IN %@", @[@2, @3]);
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY floatObj IN %@", @[@2.2f, @3.3f]);
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY doubleObj IN %@", @[@2.2, @3.3]);
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY stringObj IN %@", @[@"a", @"bc"]);
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY dataObj IN %@", @[data(1), data(2)]);
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY dateObj IN %@", @[date(1), date(2)]);
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY decimalObj IN %@", @[decimal128(1), decimal128(2)]);
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY objectIdObj IN %@", @[objectId(1), objectId(2)]);
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY uuidObj IN %@", @[uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"), uuid(@"00000000-0000-0000-0000-000000000000")]);
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY anyBoolObj IN %@", @[@NO, @YES]);
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY anyIntObj IN %@", @[@2, @3]);
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY anyFloatObj IN %@", @[@2.2f, @3.3f]);
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY anyDoubleObj IN %@", @[@2.2, @3.3]);
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY anyStringObj IN %@", @[@"a", @"b"]);
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY anyDataObj IN %@", @[data(1), data(2)]);
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY anyDateObj IN %@", @[date(1), date(2)]);
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY anyDecimalObj IN %@", @[decimal128(1), decimal128(2)]);
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY anyObjectIdObj IN %@", @[objectId(1), objectId(2)]);
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY anyUUIDObj IN %@", @[uuid(@"00000000-0000-0000-0000-000000000000"), uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")]);
    RLMAssertCount(AllOptionalPrimitiveSets, 1, @"ANY boolObj IN %@", @[NSNull.null, @NO]);
    RLMAssertCount(AllOptionalPrimitiveSets, 1, @"ANY intObj IN %@", @[NSNull.null, @2]);
    RLMAssertCount(AllOptionalPrimitiveSets, 1, @"ANY floatObj IN %@", @[NSNull.null, @2.2f]);
    RLMAssertCount(AllOptionalPrimitiveSets, 1, @"ANY doubleObj IN %@", @[NSNull.null, @2.2]);
    RLMAssertCount(AllOptionalPrimitiveSets, 1, @"ANY stringObj IN %@", @[NSNull.null, @"a"]);
    RLMAssertCount(AllOptionalPrimitiveSets, 1, @"ANY dataObj IN %@", @[NSNull.null, data(1)]);
    RLMAssertCount(AllOptionalPrimitiveSets, 1, @"ANY dateObj IN %@", @[NSNull.null, date(1)]);
    RLMAssertCount(AllOptionalPrimitiveSets, 1, @"ANY decimalObj IN %@", @[NSNull.null, decimal128(1)]);
    RLMAssertCount(AllOptionalPrimitiveSets, 1, @"ANY objectIdObj IN %@", @[NSNull.null, objectId(1)]);
    RLMAssertCount(AllOptionalPrimitiveSets, 1, @"ANY uuidObj IN %@", @[NSNull.null, uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")]);
}

- (void)testQueryCount {
    [realm deleteAllObjects];

    [AllPrimitiveSets createInRealm:realm withValue:@{
        @"boolObj": @[@NO, @YES],
        @"intObj": @[@2, @3],
        @"floatObj": @[@2.2f, @3.3f],
        @"doubleObj": @[@2.2, @3.3],
        @"stringObj": @[@"a", @"bc"],
        @"dataObj": @[data(1), data(2)],
        @"dateObj": @[date(1), date(2)],
        @"decimalObj": @[decimal128(1), decimal128(2)],
        @"objectIdObj": @[objectId(1), objectId(2)],
        @"uuidObj": @[uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"), uuid(@"00000000-0000-0000-0000-000000000000")],
        @"anyBoolObj": @[@NO, @YES],
        @"anyIntObj": @[@2, @3],
        @"anyFloatObj": @[@2.2f, @3.3f],
        @"anyDoubleObj": @[@2.2, @3.3],
        @"anyStringObj": @[@"a", @"b"],
        @"anyDataObj": @[data(1), data(2)],
        @"anyDateObj": @[date(1), date(2)],
        @"anyDecimalObj": @[decimal128(1), decimal128(2)],
        @"anyObjectIdObj": @[objectId(1), objectId(2)],
        @"anyUUIDObj": @[uuid(@"00000000-0000-0000-0000-000000000000"), uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")],
    }];
    [AllOptionalPrimitiveSets createInRealm:realm withValue:@{
        @"boolObj": @[NSNull.null, @NO],
        @"intObj": @[NSNull.null, @2],
        @"floatObj": @[NSNull.null, @2.2f],
        @"doubleObj": @[NSNull.null, @2.2],
        @"stringObj": @[NSNull.null, @"a"],
        @"dataObj": @[NSNull.null, data(1)],
        @"dateObj": @[NSNull.null, date(1)],
        @"decimalObj": @[NSNull.null, decimal128(1)],
        @"objectIdObj": @[NSNull.null, objectId(1)],
        @"uuidObj": @[NSNull.null, uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")],
    }];

    RLMAssertCount(AllPrimitiveSets, 1U, @"boolObj.@count == %@", @(2));
    RLMAssertCount(AllPrimitiveSets, 1U, @"intObj.@count == %@", @(2));
    RLMAssertCount(AllPrimitiveSets, 1U, @"floatObj.@count == %@", @(2));
    RLMAssertCount(AllPrimitiveSets, 1U, @"doubleObj.@count == %@", @(2));
    RLMAssertCount(AllPrimitiveSets, 1U, @"stringObj.@count == %@", @(2));
    RLMAssertCount(AllPrimitiveSets, 1U, @"dataObj.@count == %@", @(2));
    RLMAssertCount(AllPrimitiveSets, 1U, @"dateObj.@count == %@", @(2));
    RLMAssertCount(AllPrimitiveSets, 1U, @"decimalObj.@count == %@", @(2));
    RLMAssertCount(AllPrimitiveSets, 1U, @"objectIdObj.@count == %@", @(2));
    RLMAssertCount(AllPrimitiveSets, 1U, @"uuidObj.@count == %@", @(2));
    RLMAssertCount(AllPrimitiveSets, 1U, @"anyBoolObj.@count == %@", @(2));
    RLMAssertCount(AllPrimitiveSets, 1U, @"anyIntObj.@count == %@", @(2));
    RLMAssertCount(AllPrimitiveSets, 1U, @"anyFloatObj.@count == %@", @(2));
    RLMAssertCount(AllPrimitiveSets, 1U, @"anyDoubleObj.@count == %@", @(2));
    RLMAssertCount(AllPrimitiveSets, 1U, @"anyStringObj.@count == %@", @(2));
    RLMAssertCount(AllPrimitiveSets, 1U, @"anyDataObj.@count == %@", @(2));
    RLMAssertCount(AllPrimitiveSets, 1U, @"anyDateObj.@count == %@", @(2));
    RLMAssertCount(AllPrimitiveSets, 1U, @"anyDecimalObj.@count == %@", @(2));
    RLMAssertCount(AllPrimitiveSets, 1U, @"anyObjectIdObj.@count == %@", @(2));
    RLMAssertCount(AllPrimitiveSets, 1U, @"anyUUIDObj.@count == %@", @(2));
    RLMAssertCount(AllOptionalPrimitiveSets, 1U, @"boolObj.@count == %@", @(2));
    RLMAssertCount(AllOptionalPrimitiveSets, 1U, @"intObj.@count == %@", @(2));
    RLMAssertCount(AllOptionalPrimitiveSets, 1U, @"floatObj.@count == %@", @(2));
    RLMAssertCount(AllOptionalPrimitiveSets, 1U, @"doubleObj.@count == %@", @(2));
    RLMAssertCount(AllOptionalPrimitiveSets, 1U, @"stringObj.@count == %@", @(2));
    RLMAssertCount(AllOptionalPrimitiveSets, 1U, @"dataObj.@count == %@", @(2));
    RLMAssertCount(AllOptionalPrimitiveSets, 1U, @"dateObj.@count == %@", @(2));
    RLMAssertCount(AllOptionalPrimitiveSets, 1U, @"decimalObj.@count == %@", @(2));
    RLMAssertCount(AllOptionalPrimitiveSets, 1U, @"objectIdObj.@count == %@", @(2));
    RLMAssertCount(AllOptionalPrimitiveSets, 1U, @"uuidObj.@count == %@", @(2));
    RLMAssertCount(AllPrimitiveSets, 0U, @"boolObj.@count != %@", @(2));
    RLMAssertCount(AllPrimitiveSets, 0U, @"intObj.@count != %@", @(2));
    RLMAssertCount(AllPrimitiveSets, 0U, @"floatObj.@count != %@", @(2));
    RLMAssertCount(AllPrimitiveSets, 0U, @"doubleObj.@count != %@", @(2));
    RLMAssertCount(AllPrimitiveSets, 0U, @"stringObj.@count != %@", @(2));
    RLMAssertCount(AllPrimitiveSets, 0U, @"dataObj.@count != %@", @(2));
    RLMAssertCount(AllPrimitiveSets, 0U, @"dateObj.@count != %@", @(2));
    RLMAssertCount(AllPrimitiveSets, 0U, @"decimalObj.@count != %@", @(2));
    RLMAssertCount(AllPrimitiveSets, 0U, @"objectIdObj.@count != %@", @(2));
    RLMAssertCount(AllPrimitiveSets, 0U, @"uuidObj.@count != %@", @(2));
    RLMAssertCount(AllPrimitiveSets, 0U, @"anyBoolObj.@count != %@", @(2));
    RLMAssertCount(AllPrimitiveSets, 0U, @"anyIntObj.@count != %@", @(2));
    RLMAssertCount(AllPrimitiveSets, 0U, @"anyFloatObj.@count != %@", @(2));
    RLMAssertCount(AllPrimitiveSets, 0U, @"anyDoubleObj.@count != %@", @(2));
    RLMAssertCount(AllPrimitiveSets, 0U, @"anyStringObj.@count != %@", @(2));
    RLMAssertCount(AllPrimitiveSets, 0U, @"anyDataObj.@count != %@", @(2));
    RLMAssertCount(AllPrimitiveSets, 0U, @"anyDateObj.@count != %@", @(2));
    RLMAssertCount(AllPrimitiveSets, 0U, @"anyDecimalObj.@count != %@", @(2));
    RLMAssertCount(AllPrimitiveSets, 0U, @"anyObjectIdObj.@count != %@", @(2));
    RLMAssertCount(AllPrimitiveSets, 0U, @"anyUUIDObj.@count != %@", @(2));
    RLMAssertCount(AllOptionalPrimitiveSets, 0U, @"boolObj.@count != %@", @(2));
    RLMAssertCount(AllOptionalPrimitiveSets, 0U, @"intObj.@count != %@", @(2));
    RLMAssertCount(AllOptionalPrimitiveSets, 0U, @"floatObj.@count != %@", @(2));
    RLMAssertCount(AllOptionalPrimitiveSets, 0U, @"doubleObj.@count != %@", @(2));
    RLMAssertCount(AllOptionalPrimitiveSets, 0U, @"stringObj.@count != %@", @(2));
    RLMAssertCount(AllOptionalPrimitiveSets, 0U, @"dataObj.@count != %@", @(2));
    RLMAssertCount(AllOptionalPrimitiveSets, 0U, @"dateObj.@count != %@", @(2));
    RLMAssertCount(AllOptionalPrimitiveSets, 0U, @"decimalObj.@count != %@", @(2));
    RLMAssertCount(AllOptionalPrimitiveSets, 0U, @"objectIdObj.@count != %@", @(2));
    RLMAssertCount(AllOptionalPrimitiveSets, 0U, @"uuidObj.@count != %@", @(2));
    RLMAssertCount(AllPrimitiveSets, 0, @"boolObj.@count > %@", @(2));
    RLMAssertCount(AllPrimitiveSets, 0, @"intObj.@count > %@", @(2));
    RLMAssertCount(AllPrimitiveSets, 0, @"floatObj.@count > %@", @(2));
    RLMAssertCount(AllPrimitiveSets, 0, @"doubleObj.@count > %@", @(2));
    RLMAssertCount(AllPrimitiveSets, 0, @"stringObj.@count > %@", @(2));
    RLMAssertCount(AllPrimitiveSets, 0, @"dataObj.@count > %@", @(2));
    RLMAssertCount(AllPrimitiveSets, 0, @"dateObj.@count > %@", @(2));
    RLMAssertCount(AllPrimitiveSets, 0, @"decimalObj.@count > %@", @(2));
    RLMAssertCount(AllPrimitiveSets, 0, @"objectIdObj.@count > %@", @(2));
    RLMAssertCount(AllPrimitiveSets, 0, @"uuidObj.@count > %@", @(2));
    RLMAssertCount(AllPrimitiveSets, 0, @"anyBoolObj.@count > %@", @(2));
    RLMAssertCount(AllPrimitiveSets, 0, @"anyIntObj.@count > %@", @(2));
    RLMAssertCount(AllPrimitiveSets, 0, @"anyFloatObj.@count > %@", @(2));
    RLMAssertCount(AllPrimitiveSets, 0, @"anyDoubleObj.@count > %@", @(2));
    RLMAssertCount(AllPrimitiveSets, 0, @"anyStringObj.@count > %@", @(2));
    RLMAssertCount(AllPrimitiveSets, 0, @"anyDataObj.@count > %@", @(2));
    RLMAssertCount(AllPrimitiveSets, 0, @"anyDateObj.@count > %@", @(2));
    RLMAssertCount(AllPrimitiveSets, 0, @"anyDecimalObj.@count > %@", @(2));
    RLMAssertCount(AllPrimitiveSets, 0, @"anyObjectIdObj.@count > %@", @(2));
    RLMAssertCount(AllPrimitiveSets, 0, @"anyUUIDObj.@count > %@", @(2));
    RLMAssertCount(AllOptionalPrimitiveSets, 0, @"boolObj.@count > %@", @(2));
    RLMAssertCount(AllOptionalPrimitiveSets, 0, @"intObj.@count > %@", @(2));
    RLMAssertCount(AllOptionalPrimitiveSets, 0, @"floatObj.@count > %@", @(2));
    RLMAssertCount(AllOptionalPrimitiveSets, 0, @"doubleObj.@count > %@", @(2));
    RLMAssertCount(AllOptionalPrimitiveSets, 0, @"stringObj.@count > %@", @(2));
    RLMAssertCount(AllOptionalPrimitiveSets, 0, @"dataObj.@count > %@", @(2));
    RLMAssertCount(AllOptionalPrimitiveSets, 0, @"dateObj.@count > %@", @(2));
    RLMAssertCount(AllOptionalPrimitiveSets, 0, @"decimalObj.@count > %@", @(2));
    RLMAssertCount(AllOptionalPrimitiveSets, 0, @"objectIdObj.@count > %@", @(2));
    RLMAssertCount(AllOptionalPrimitiveSets, 0, @"uuidObj.@count > %@", @(2));
    RLMAssertCount(AllPrimitiveSets, 1, @"boolObj.@count >= %@", @(2));
    RLMAssertCount(AllPrimitiveSets, 1, @"intObj.@count >= %@", @(2));
    RLMAssertCount(AllPrimitiveSets, 1, @"floatObj.@count >= %@", @(2));
    RLMAssertCount(AllPrimitiveSets, 1, @"doubleObj.@count >= %@", @(2));
    RLMAssertCount(AllPrimitiveSets, 1, @"stringObj.@count >= %@", @(2));
    RLMAssertCount(AllPrimitiveSets, 1, @"dataObj.@count >= %@", @(2));
    RLMAssertCount(AllPrimitiveSets, 1, @"dateObj.@count >= %@", @(2));
    RLMAssertCount(AllPrimitiveSets, 1, @"decimalObj.@count >= %@", @(2));
    RLMAssertCount(AllPrimitiveSets, 1, @"objectIdObj.@count >= %@", @(2));
    RLMAssertCount(AllPrimitiveSets, 1, @"uuidObj.@count >= %@", @(2));
    RLMAssertCount(AllPrimitiveSets, 1, @"anyBoolObj.@count >= %@", @(2));
    RLMAssertCount(AllPrimitiveSets, 1, @"anyIntObj.@count >= %@", @(2));
    RLMAssertCount(AllPrimitiveSets, 1, @"anyFloatObj.@count >= %@", @(2));
    RLMAssertCount(AllPrimitiveSets, 1, @"anyDoubleObj.@count >= %@", @(2));
    RLMAssertCount(AllPrimitiveSets, 1, @"anyStringObj.@count >= %@", @(2));
    RLMAssertCount(AllPrimitiveSets, 1, @"anyDataObj.@count >= %@", @(2));
    RLMAssertCount(AllPrimitiveSets, 1, @"anyDateObj.@count >= %@", @(2));
    RLMAssertCount(AllPrimitiveSets, 1, @"anyDecimalObj.@count >= %@", @(2));
    RLMAssertCount(AllPrimitiveSets, 1, @"anyObjectIdObj.@count >= %@", @(2));
    RLMAssertCount(AllPrimitiveSets, 1, @"anyUUIDObj.@count >= %@", @(2));
    RLMAssertCount(AllOptionalPrimitiveSets, 1, @"boolObj.@count >= %@", @(2));
    RLMAssertCount(AllOptionalPrimitiveSets, 1, @"intObj.@count >= %@", @(2));
    RLMAssertCount(AllOptionalPrimitiveSets, 1, @"floatObj.@count >= %@", @(2));
    RLMAssertCount(AllOptionalPrimitiveSets, 1, @"doubleObj.@count >= %@", @(2));
    RLMAssertCount(AllOptionalPrimitiveSets, 1, @"stringObj.@count >= %@", @(2));
    RLMAssertCount(AllOptionalPrimitiveSets, 1, @"dataObj.@count >= %@", @(2));
    RLMAssertCount(AllOptionalPrimitiveSets, 1, @"dateObj.@count >= %@", @(2));
    RLMAssertCount(AllOptionalPrimitiveSets, 1, @"decimalObj.@count >= %@", @(2));
    RLMAssertCount(AllOptionalPrimitiveSets, 1, @"objectIdObj.@count >= %@", @(2));
    RLMAssertCount(AllOptionalPrimitiveSets, 1, @"uuidObj.@count >= %@", @(2));
    RLMAssertCount(AllPrimitiveSets, 0, @"boolObj.@count < %@", @(2));
    RLMAssertCount(AllPrimitiveSets, 0, @"intObj.@count < %@", @(2));
    RLMAssertCount(AllPrimitiveSets, 0, @"floatObj.@count < %@", @(2));
    RLMAssertCount(AllPrimitiveSets, 0, @"doubleObj.@count < %@", @(2));
    RLMAssertCount(AllPrimitiveSets, 0, @"stringObj.@count < %@", @(2));
    RLMAssertCount(AllPrimitiveSets, 0, @"dataObj.@count < %@", @(2));
    RLMAssertCount(AllPrimitiveSets, 0, @"dateObj.@count < %@", @(2));
    RLMAssertCount(AllPrimitiveSets, 0, @"decimalObj.@count < %@", @(2));
    RLMAssertCount(AllPrimitiveSets, 0, @"objectIdObj.@count < %@", @(2));
    RLMAssertCount(AllPrimitiveSets, 0, @"uuidObj.@count < %@", @(2));
    RLMAssertCount(AllPrimitiveSets, 0, @"anyBoolObj.@count < %@", @(2));
    RLMAssertCount(AllPrimitiveSets, 0, @"anyIntObj.@count < %@", @(2));
    RLMAssertCount(AllPrimitiveSets, 0, @"anyFloatObj.@count < %@", @(2));
    RLMAssertCount(AllPrimitiveSets, 0, @"anyDoubleObj.@count < %@", @(2));
    RLMAssertCount(AllPrimitiveSets, 0, @"anyStringObj.@count < %@", @(2));
    RLMAssertCount(AllPrimitiveSets, 0, @"anyDataObj.@count < %@", @(2));
    RLMAssertCount(AllPrimitiveSets, 0, @"anyDateObj.@count < %@", @(2));
    RLMAssertCount(AllPrimitiveSets, 0, @"anyDecimalObj.@count < %@", @(2));
    RLMAssertCount(AllPrimitiveSets, 0, @"anyObjectIdObj.@count < %@", @(2));
    RLMAssertCount(AllPrimitiveSets, 0, @"anyUUIDObj.@count < %@", @(2));
    RLMAssertCount(AllOptionalPrimitiveSets, 0, @"boolObj.@count < %@", @(2));
    RLMAssertCount(AllOptionalPrimitiveSets, 0, @"intObj.@count < %@", @(2));
    RLMAssertCount(AllOptionalPrimitiveSets, 0, @"floatObj.@count < %@", @(2));
    RLMAssertCount(AllOptionalPrimitiveSets, 0, @"doubleObj.@count < %@", @(2));
    RLMAssertCount(AllOptionalPrimitiveSets, 0, @"stringObj.@count < %@", @(2));
    RLMAssertCount(AllOptionalPrimitiveSets, 0, @"dataObj.@count < %@", @(2));
    RLMAssertCount(AllOptionalPrimitiveSets, 0, @"dateObj.@count < %@", @(2));
    RLMAssertCount(AllOptionalPrimitiveSets, 0, @"decimalObj.@count < %@", @(2));
    RLMAssertCount(AllOptionalPrimitiveSets, 0, @"objectIdObj.@count < %@", @(2));
    RLMAssertCount(AllOptionalPrimitiveSets, 0, @"uuidObj.@count < %@", @(2));
    RLMAssertCount(AllPrimitiveSets, 1, @"boolObj.@count <= %@", @(2));
    RLMAssertCount(AllPrimitiveSets, 1, @"intObj.@count <= %@", @(2));
    RLMAssertCount(AllPrimitiveSets, 1, @"floatObj.@count <= %@", @(2));
    RLMAssertCount(AllPrimitiveSets, 1, @"doubleObj.@count <= %@", @(2));
    RLMAssertCount(AllPrimitiveSets, 1, @"stringObj.@count <= %@", @(2));
    RLMAssertCount(AllPrimitiveSets, 1, @"dataObj.@count <= %@", @(2));
    RLMAssertCount(AllPrimitiveSets, 1, @"dateObj.@count <= %@", @(2));
    RLMAssertCount(AllPrimitiveSets, 1, @"decimalObj.@count <= %@", @(2));
    RLMAssertCount(AllPrimitiveSets, 1, @"objectIdObj.@count <= %@", @(2));
    RLMAssertCount(AllPrimitiveSets, 1, @"uuidObj.@count <= %@", @(2));
    RLMAssertCount(AllPrimitiveSets, 1, @"anyBoolObj.@count <= %@", @(2));
    RLMAssertCount(AllPrimitiveSets, 1, @"anyIntObj.@count <= %@", @(2));
    RLMAssertCount(AllPrimitiveSets, 1, @"anyFloatObj.@count <= %@", @(2));
    RLMAssertCount(AllPrimitiveSets, 1, @"anyDoubleObj.@count <= %@", @(2));
    RLMAssertCount(AllPrimitiveSets, 1, @"anyStringObj.@count <= %@", @(2));
    RLMAssertCount(AllPrimitiveSets, 1, @"anyDataObj.@count <= %@", @(2));
    RLMAssertCount(AllPrimitiveSets, 1, @"anyDateObj.@count <= %@", @(2));
    RLMAssertCount(AllPrimitiveSets, 1, @"anyDecimalObj.@count <= %@", @(2));
    RLMAssertCount(AllPrimitiveSets, 1, @"anyObjectIdObj.@count <= %@", @(2));
    RLMAssertCount(AllPrimitiveSets, 1, @"anyUUIDObj.@count <= %@", @(2));
    RLMAssertCount(AllOptionalPrimitiveSets, 1, @"boolObj.@count <= %@", @(2));
    RLMAssertCount(AllOptionalPrimitiveSets, 1, @"intObj.@count <= %@", @(2));
    RLMAssertCount(AllOptionalPrimitiveSets, 1, @"floatObj.@count <= %@", @(2));
    RLMAssertCount(AllOptionalPrimitiveSets, 1, @"doubleObj.@count <= %@", @(2));
    RLMAssertCount(AllOptionalPrimitiveSets, 1, @"stringObj.@count <= %@", @(2));
    RLMAssertCount(AllOptionalPrimitiveSets, 1, @"dataObj.@count <= %@", @(2));
    RLMAssertCount(AllOptionalPrimitiveSets, 1, @"dateObj.@count <= %@", @(2));
    RLMAssertCount(AllOptionalPrimitiveSets, 1, @"decimalObj.@count <= %@", @(2));
    RLMAssertCount(AllOptionalPrimitiveSets, 1, @"objectIdObj.@count <= %@", @(2));
    RLMAssertCount(AllOptionalPrimitiveSets, 1, @"uuidObj.@count <= %@", @(2));
}

- (void)testQuerySum {
    [realm deleteAllObjects];

    RLMAssertThrowsWithReason(([AllPrimitiveSets objectsInRealm:realm where:@"boolObj.@sum = %@", @NO]), 
                              @"Invalid keypath 'boolObj.@sum': @sum can only be applied to a collection of numeric values.");
    RLMAssertThrowsWithReason(([AllPrimitiveSets objectsInRealm:realm where:@"stringObj.@sum = %@", @"a"]), 
                              @"Invalid keypath 'stringObj.@sum': @sum can only be applied to a collection of numeric values.");
    RLMAssertThrowsWithReason(([AllPrimitiveSets objectsInRealm:realm where:@"dataObj.@sum = %@", data(1)]), 
                              @"Invalid keypath 'dataObj.@sum': @sum can only be applied to a collection of numeric values.");
    RLMAssertThrowsWithReason(([AllPrimitiveSets objectsInRealm:realm where:@"objectIdObj.@sum = %@", objectId(1)]), 
                              @"Invalid keypath 'objectIdObj.@sum': @sum can only be applied to a collection of numeric values.");
    RLMAssertThrowsWithReason(([AllPrimitiveSets objectsInRealm:realm where:@"uuidObj.@sum = %@", uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")]), 
                              @"Invalid keypath 'uuidObj.@sum': @sum can only be applied to a collection of numeric values.");
    RLMAssertThrowsWithReason(([AllOptionalPrimitiveSets objectsInRealm:realm where:@"boolObj.@sum = %@", NSNull.null]), 
                              @"Invalid keypath 'boolObj.@sum': @sum can only be applied to a collection of numeric values.");
    RLMAssertThrowsWithReason(([AllOptionalPrimitiveSets objectsInRealm:realm where:@"stringObj.@sum = %@", NSNull.null]), 
                              @"Invalid keypath 'stringObj.@sum': @sum can only be applied to a collection of numeric values.");
    RLMAssertThrowsWithReason(([AllOptionalPrimitiveSets objectsInRealm:realm where:@"dataObj.@sum = %@", NSNull.null]), 
                              @"Invalid keypath 'dataObj.@sum': @sum can only be applied to a collection of numeric values.");
    RLMAssertThrowsWithReason(([AllOptionalPrimitiveSets objectsInRealm:realm where:@"objectIdObj.@sum = %@", NSNull.null]), 
                              @"Invalid keypath 'objectIdObj.@sum': @sum can only be applied to a collection of numeric values.");
    RLMAssertThrowsWithReason(([AllOptionalPrimitiveSets objectsInRealm:realm where:@"uuidObj.@sum = %@", NSNull.null]), 
                              @"Invalid keypath 'uuidObj.@sum': @sum can only be applied to a collection of numeric values.");
    RLMAssertThrowsWithReason(([AllPrimitiveSets objectsInRealm:realm where:@"dateObj.@sum = %@", date(1)]), 
                              @"Cannot sum or average date properties");

    RLMAssertThrowsWithReason(([AllPrimitiveSets objectsInRealm:realm where:@"intObj.@sum = %@", @"a"]), 
                              @"@sum on a property of type int cannot be compared with 'a'");
    RLMAssertThrowsWithReason(([AllPrimitiveSets objectsInRealm:realm where:@"floatObj.@sum = %@", @"a"]), 
                              @"@sum on a property of type float cannot be compared with 'a'");
    RLMAssertThrowsWithReason(([AllPrimitiveSets objectsInRealm:realm where:@"doubleObj.@sum = %@", @"a"]), 
                              @"@sum on a property of type double cannot be compared with 'a'");
    RLMAssertThrowsWithReason(([AllPrimitiveSets objectsInRealm:realm where:@"decimalObj.@sum = %@", @"a"]), 
                              @"@sum on a property of type decimal128 cannot be compared with 'a'");
    RLMAssertThrowsWithReason(([AllOptionalPrimitiveSets objectsInRealm:realm where:@"intObj.@sum = %@", @"a"]), 
                              @"@sum on a property of type int cannot be compared with 'a'");
    RLMAssertThrowsWithReason(([AllOptionalPrimitiveSets objectsInRealm:realm where:@"floatObj.@sum = %@", @"a"]), 
                              @"@sum on a property of type float cannot be compared with 'a'");
    RLMAssertThrowsWithReason(([AllOptionalPrimitiveSets objectsInRealm:realm where:@"doubleObj.@sum = %@", @"a"]), 
                              @"@sum on a property of type double cannot be compared with 'a'");
    RLMAssertThrowsWithReason(([AllOptionalPrimitiveSets objectsInRealm:realm where:@"decimalObj.@sum = %@", @"a"]), 
                              @"@sum on a property of type decimal128 cannot be compared with 'a'");
    RLMAssertThrowsWithReason(([AllPrimitiveSets objectsInRealm:realm where:@"intObj.@sum.prop = %@", @"a"]), 
                              @"Invalid keypath 'intObj.@sum.prop': @sum on a collection of values must appear at the end of a keypath.");
    RLMAssertThrowsWithReason(([AllPrimitiveSets objectsInRealm:realm where:@"floatObj.@sum.prop = %@", @"a"]), 
                              @"Invalid keypath 'floatObj.@sum.prop': @sum on a collection of values must appear at the end of a keypath.");
    RLMAssertThrowsWithReason(([AllPrimitiveSets objectsInRealm:realm where:@"doubleObj.@sum.prop = %@", @"a"]), 
                              @"Invalid keypath 'doubleObj.@sum.prop': @sum on a collection of values must appear at the end of a keypath.");
    RLMAssertThrowsWithReason(([AllPrimitiveSets objectsInRealm:realm where:@"decimalObj.@sum.prop = %@", @"a"]), 
                              @"Invalid keypath 'decimalObj.@sum.prop': @sum on a collection of values must appear at the end of a keypath.");
    RLMAssertThrowsWithReason(([AllOptionalPrimitiveSets objectsInRealm:realm where:@"intObj.@sum.prop = %@", @"a"]), 
                              @"Invalid keypath 'intObj.@sum.prop': @sum on a collection of values must appear at the end of a keypath.");
    RLMAssertThrowsWithReason(([AllOptionalPrimitiveSets objectsInRealm:realm where:@"floatObj.@sum.prop = %@", @"a"]), 
                              @"Invalid keypath 'floatObj.@sum.prop': @sum on a collection of values must appear at the end of a keypath.");
    RLMAssertThrowsWithReason(([AllOptionalPrimitiveSets objectsInRealm:realm where:@"doubleObj.@sum.prop = %@", @"a"]), 
                              @"Invalid keypath 'doubleObj.@sum.prop': @sum on a collection of values must appear at the end of a keypath.");
    RLMAssertThrowsWithReason(([AllOptionalPrimitiveSets objectsInRealm:realm where:@"decimalObj.@sum.prop = %@", @"a"]), 
                              @"Invalid keypath 'decimalObj.@sum.prop': @sum on a collection of values must appear at the end of a keypath.");
    RLMAssertThrowsWithReason(([AllPrimitiveSets objectsInRealm:realm where:@"intObj.@sum = %@", NSNull.null]), 
                              @"@sum on a property of type int cannot be compared with '<null>'");
    RLMAssertThrowsWithReason(([AllPrimitiveSets objectsInRealm:realm where:@"floatObj.@sum = %@", NSNull.null]), 
                              @"@sum on a property of type float cannot be compared with '<null>'");
    RLMAssertThrowsWithReason(([AllPrimitiveSets objectsInRealm:realm where:@"doubleObj.@sum = %@", NSNull.null]), 
                              @"@sum on a property of type double cannot be compared with '<null>'");
    RLMAssertThrowsWithReason(([AllPrimitiveSets objectsInRealm:realm where:@"decimalObj.@sum = %@", NSNull.null]), 
                              @"@sum on a property of type decimal128 cannot be compared with '<null>'");
    RLMAssertThrowsWithReason(([AllOptionalPrimitiveSets objectsInRealm:realm where:@"intObj.@sum = %@", NSNull.null]), 
                              @"@sum on a property of type int cannot be compared with '<null>'");
    RLMAssertThrowsWithReason(([AllOptionalPrimitiveSets objectsInRealm:realm where:@"floatObj.@sum = %@", NSNull.null]), 
                              @"@sum on a property of type float cannot be compared with '<null>'");
    RLMAssertThrowsWithReason(([AllOptionalPrimitiveSets objectsInRealm:realm where:@"doubleObj.@sum = %@", NSNull.null]), 
                              @"@sum on a property of type double cannot be compared with '<null>'");
    RLMAssertThrowsWithReason(([AllOptionalPrimitiveSets objectsInRealm:realm where:@"decimalObj.@sum = %@", NSNull.null]), 
                              @"@sum on a property of type decimal128 cannot be compared with '<null>'");

    [AllPrimitiveSets createInRealm:realm withValue:@{
        @"intObj": @[],
        @"floatObj": @[],
        @"doubleObj": @[],
        @"decimalObj": @[],
        @"anyIntObj": @[],
        @"anyFloatObj": @[],
        @"anyDoubleObj": @[],
        @"anyDecimalObj": @[],
    }];
    [AllOptionalPrimitiveSets createInRealm:realm withValue:@{
        @"intObj": @[],
        @"floatObj": @[],
        @"doubleObj": @[],
        @"decimalObj": @[],
    }];
    [AllPrimitiveSets createInRealm:realm withValue:@{
        @"intObj": @[@2],
        @"floatObj": @[@2.2f],
        @"doubleObj": @[@2.2],
        @"decimalObj": @[decimal128(1)],
        @"anyIntObj": @[@2],
        @"anyFloatObj": @[@2.2f],
        @"anyDoubleObj": @[@2.2],
        @"anyDecimalObj": @[decimal128(1)],
    }];
    [AllOptionalPrimitiveSets createInRealm:realm withValue:@{
        @"intObj": @[@2],
        @"floatObj": @[@2.2f],
        @"doubleObj": @[@2.2],
        @"decimalObj": @[decimal128(1)],
    }];
    [AllPrimitiveSets createInRealm:realm withValue:@{
        @"intObj": @[@2, @2],
        @"floatObj": @[@2.2f, @2.2f],
        @"doubleObj": @[@2.2, @2.2],
        @"decimalObj": @[decimal128(1), decimal128(1)],
        @"anyIntObj": @[@2, @2],
        @"anyFloatObj": @[@2.2f, @2.2f],
        @"anyDoubleObj": @[@2.2, @2.2],
        @"anyDecimalObj": @[decimal128(1), decimal128(1)],
    }];
    [AllOptionalPrimitiveSets createInRealm:realm withValue:@{
        @"intObj": @[@2, @3],
        @"floatObj": @[@2.2f, @3.3f],
        @"doubleObj": @[@2.2, @3.3],
        @"decimalObj": @[decimal128(1), decimal128(2)],
    }];
    [AllPrimitiveSets createInRealm:realm withValue:@{
        @"intObj": @[@3, @3, @3],
        @"floatObj": @[@3.3f, @3.3f, @3.3f],
        @"doubleObj": @[@3.3, @3.3, @3.3],
        @"decimalObj": @[decimal128(2), decimal128(2), decimal128(2)],
        @"anyIntObj": @[@3, @3, @3],
        @"anyFloatObj": @[@3.3f, @3.3f, @3.3f],
        @"anyDoubleObj": @[@3.3, @3.3, @3.3],
        @"anyDecimalObj": @[decimal128(2), decimal128(2), decimal128(2)],
    }];
    [AllOptionalPrimitiveSets createInRealm:realm withValue:@{
        @"intObj": @[@2, @2, @2],
        @"floatObj": @[@2.2f, @2.2f, @2.2f],
        @"doubleObj": @[@2.2, @2.2, @2.2],
        @"decimalObj": @[decimal128(1), decimal128(1), decimal128(1)],
    }];

    RLMAssertCount(AllPrimitiveSets, 1U, @"intObj.@sum == %@", @0);
    RLMAssertCount(AllPrimitiveSets, 1U, @"floatObj.@sum == %@", @0);
    RLMAssertCount(AllPrimitiveSets, 1U, @"doubleObj.@sum == %@", @0);
    RLMAssertCount(AllPrimitiveSets, 1U, @"decimalObj.@sum == %@", @0);
    RLMAssertCount(AllPrimitiveSets, 1U, @"anyIntObj.@sum == %@", @0);
    RLMAssertCount(AllPrimitiveSets, 1U, @"anyFloatObj.@sum == %@", @0);
    RLMAssertCount(AllPrimitiveSets, 1U, @"anyDoubleObj.@sum == %@", @0);
    RLMAssertCount(AllPrimitiveSets, 1U, @"anyDecimalObj.@sum == %@", @0);
    RLMAssertCount(AllPrimitiveSets, 2U, @"intObj.@sum == %@", @2);
    RLMAssertCount(AllPrimitiveSets, 2U, @"floatObj.@sum == %@", @2.2f);
    RLMAssertCount(AllPrimitiveSets, 2U, @"doubleObj.@sum == %@", @2.2);
    RLMAssertCount(AllPrimitiveSets, 2U, @"decimalObj.@sum == %@", decimal128(1));
    RLMAssertCount(AllPrimitiveSets, 2U, @"anyIntObj.@sum == %@", @2);
    RLMAssertCount(AllPrimitiveSets, 2U, @"anyFloatObj.@sum == %@", @2.2f);
    RLMAssertCount(AllPrimitiveSets, 2U, @"anyDoubleObj.@sum == %@", @2.2);
    RLMAssertCount(AllPrimitiveSets, 2U, @"anyDecimalObj.@sum == %@", decimal128(1));
    RLMAssertCount(AllPrimitiveSets, 3U, @"intObj.@sum != %@", @3);
    RLMAssertCount(AllPrimitiveSets, 3U, @"floatObj.@sum != %@", @3.3f);
    RLMAssertCount(AllPrimitiveSets, 3U, @"doubleObj.@sum != %@", @3.3);
    RLMAssertCount(AllPrimitiveSets, 3U, @"decimalObj.@sum != %@", decimal128(2));
    RLMAssertCount(AllPrimitiveSets, 3U, @"anyIntObj.@sum != %@", @3);
    RLMAssertCount(AllPrimitiveSets, 3U, @"anyFloatObj.@sum != %@", @3.3f);
    RLMAssertCount(AllPrimitiveSets, 3U, @"anyDoubleObj.@sum != %@", @3.3);
    RLMAssertCount(AllPrimitiveSets, 3U, @"anyDecimalObj.@sum != %@", decimal128(2));
    RLMAssertCount(AllPrimitiveSets, 3U, @"intObj.@sum >= %@", @2);
    RLMAssertCount(AllPrimitiveSets, 3U, @"floatObj.@sum >= %@", @2.2f);
    RLMAssertCount(AllPrimitiveSets, 3U, @"doubleObj.@sum >= %@", @2.2);
    RLMAssertCount(AllPrimitiveSets, 3U, @"decimalObj.@sum >= %@", decimal128(1));
    RLMAssertCount(AllPrimitiveSets, 3U, @"anyIntObj.@sum >= %@", @2);
    RLMAssertCount(AllPrimitiveSets, 3U, @"anyFloatObj.@sum >= %@", @2.2f);
    RLMAssertCount(AllPrimitiveSets, 3U, @"anyDoubleObj.@sum >= %@", @2.2);
    RLMAssertCount(AllPrimitiveSets, 3U, @"anyDecimalObj.@sum >= %@", decimal128(1));
    RLMAssertCount(AllPrimitiveSets, 1U, @"intObj.@sum > %@", @2);
    RLMAssertCount(AllPrimitiveSets, 1U, @"floatObj.@sum > %@", @2.2f);
    RLMAssertCount(AllPrimitiveSets, 1U, @"doubleObj.@sum > %@", @2.2);
    RLMAssertCount(AllPrimitiveSets, 1U, @"decimalObj.@sum > %@", decimal128(1));
    RLMAssertCount(AllPrimitiveSets, 1U, @"anyIntObj.@sum > %@", @2);
    RLMAssertCount(AllPrimitiveSets, 1U, @"anyFloatObj.@sum > %@", @2.2f);
    RLMAssertCount(AllPrimitiveSets, 1U, @"anyDoubleObj.@sum > %@", @2.2);
    RLMAssertCount(AllPrimitiveSets, 1U, @"anyDecimalObj.@sum > %@", decimal128(1));
    RLMAssertCount(AllPrimitiveSets, 3U, @"intObj.@sum < %@", @3);
    RLMAssertCount(AllPrimitiveSets, 3U, @"floatObj.@sum < %@", @3.3f);
    RLMAssertCount(AllPrimitiveSets, 3U, @"doubleObj.@sum < %@", @3.3);
    RLMAssertCount(AllPrimitiveSets, 3U, @"decimalObj.@sum < %@", decimal128(2));
    RLMAssertCount(AllPrimitiveSets, 3U, @"anyIntObj.@sum < %@", @3);
    RLMAssertCount(AllPrimitiveSets, 3U, @"anyFloatObj.@sum < %@", @3.3f);
    RLMAssertCount(AllPrimitiveSets, 3U, @"anyDoubleObj.@sum < %@", @3.3);
    RLMAssertCount(AllPrimitiveSets, 3U, @"anyDecimalObj.@sum < %@", decimal128(2));
    RLMAssertCount(AllPrimitiveSets, 4U, @"intObj.@sum <= %@", @3);
    RLMAssertCount(AllPrimitiveSets, 4U, @"floatObj.@sum <= %@", @3.3f);
    RLMAssertCount(AllPrimitiveSets, 4U, @"doubleObj.@sum <= %@", @3.3);
    RLMAssertCount(AllPrimitiveSets, 4U, @"decimalObj.@sum <= %@", decimal128(2));
    RLMAssertCount(AllPrimitiveSets, 4U, @"anyIntObj.@sum <= %@", @3);
    RLMAssertCount(AllPrimitiveSets, 4U, @"anyFloatObj.@sum <= %@", @3.3f);
    RLMAssertCount(AllPrimitiveSets, 4U, @"anyDoubleObj.@sum <= %@", @3.3);
    RLMAssertCount(AllPrimitiveSets, 4U, @"anyDecimalObj.@sum <= %@", decimal128(2));

    RLMAssertCount(AllOptionalPrimitiveSets, 1U, @"intObj.@sum == %@", @0);
    RLMAssertCount(AllOptionalPrimitiveSets, 1U, @"floatObj.@sum == %@", @0);
    RLMAssertCount(AllOptionalPrimitiveSets, 1U, @"doubleObj.@sum == %@", @0);
    RLMAssertCount(AllOptionalPrimitiveSets, 1U, @"decimalObj.@sum == %@", @0);
    RLMAssertCount(AllOptionalPrimitiveSets, 2U, @"intObj.@sum == %@", @2);
    RLMAssertCount(AllOptionalPrimitiveSets, 2U, @"floatObj.@sum == %@", @2.2f);
    RLMAssertCount(AllOptionalPrimitiveSets, 2U, @"doubleObj.@sum == %@", @2.2);
    RLMAssertCount(AllOptionalPrimitiveSets, 2U, @"decimalObj.@sum == %@", decimal128(1));
    RLMAssertCount(AllOptionalPrimitiveSets, 2U, @"intObj.@sum != %@", @2);
    RLMAssertCount(AllOptionalPrimitiveSets, 2U, @"floatObj.@sum != %@", @2.2f);
    RLMAssertCount(AllOptionalPrimitiveSets, 2U, @"doubleObj.@sum != %@", @2.2);
    RLMAssertCount(AllOptionalPrimitiveSets, 2U, @"decimalObj.@sum != %@", decimal128(1));
    RLMAssertCount(AllOptionalPrimitiveSets, 3U, @"intObj.@sum >= %@", @2);
    RLMAssertCount(AllOptionalPrimitiveSets, 3U, @"floatObj.@sum >= %@", @2.2f);
    RLMAssertCount(AllOptionalPrimitiveSets, 3U, @"doubleObj.@sum >= %@", @2.2);
    RLMAssertCount(AllOptionalPrimitiveSets, 3U, @"decimalObj.@sum >= %@", decimal128(1));
    RLMAssertCount(AllOptionalPrimitiveSets, 1U, @"intObj.@sum > %@", @2);
    RLMAssertCount(AllOptionalPrimitiveSets, 1U, @"floatObj.@sum > %@", @2.2f);
    RLMAssertCount(AllOptionalPrimitiveSets, 1U, @"doubleObj.@sum > %@", @2.2);
    RLMAssertCount(AllOptionalPrimitiveSets, 1U, @"decimalObj.@sum > %@", decimal128(1));
    RLMAssertCount(AllOptionalPrimitiveSets, 3U, @"intObj.@sum < %@", @3);
    RLMAssertCount(AllOptionalPrimitiveSets, 3U, @"floatObj.@sum < %@", @3.3f);
    RLMAssertCount(AllOptionalPrimitiveSets, 3U, @"doubleObj.@sum < %@", @3.3);
    RLMAssertCount(AllOptionalPrimitiveSets, 3U, @"decimalObj.@sum < %@", decimal128(2));
    RLMAssertCount(AllOptionalPrimitiveSets, 3U, @"intObj.@sum <= %@", @2);
    RLMAssertCount(AllOptionalPrimitiveSets, 3U, @"floatObj.@sum <= %@", @2.2f);
    RLMAssertCount(AllOptionalPrimitiveSets, 3U, @"doubleObj.@sum <= %@", @2.2);
    RLMAssertCount(AllOptionalPrimitiveSets, 3U, @"decimalObj.@sum <= %@", decimal128(1));
}

- (void)testQueryAverage {
    [realm deleteAllObjects];

    RLMAssertThrowsWithReason(([AllPrimitiveSets objectsInRealm:realm where:@"boolObj.@avg = %@", @NO]), 
                              @"Invalid keypath 'boolObj.@avg': @avg can only be applied to a collection of numeric values.");
    RLMAssertThrowsWithReason(([AllPrimitiveSets objectsInRealm:realm where:@"stringObj.@avg = %@", @"a"]), 
                              @"Invalid keypath 'stringObj.@avg': @avg can only be applied to a collection of numeric values.");
    RLMAssertThrowsWithReason(([AllPrimitiveSets objectsInRealm:realm where:@"dataObj.@avg = %@", data(1)]), 
                              @"Invalid keypath 'dataObj.@avg': @avg can only be applied to a collection of numeric values.");
    RLMAssertThrowsWithReason(([AllPrimitiveSets objectsInRealm:realm where:@"objectIdObj.@avg = %@", objectId(1)]), 
                              @"Invalid keypath 'objectIdObj.@avg': @avg can only be applied to a collection of numeric values.");
    RLMAssertThrowsWithReason(([AllPrimitiveSets objectsInRealm:realm where:@"uuidObj.@avg = %@", uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")]), 
                              @"Invalid keypath 'uuidObj.@avg': @avg can only be applied to a collection of numeric values.");
    RLMAssertThrowsWithReason(([AllOptionalPrimitiveSets objectsInRealm:realm where:@"boolObj.@avg = %@", NSNull.null]), 
                              @"Invalid keypath 'boolObj.@avg': @avg can only be applied to a collection of numeric values.");
    RLMAssertThrowsWithReason(([AllOptionalPrimitiveSets objectsInRealm:realm where:@"stringObj.@avg = %@", NSNull.null]), 
                              @"Invalid keypath 'stringObj.@avg': @avg can only be applied to a collection of numeric values.");
    RLMAssertThrowsWithReason(([AllOptionalPrimitiveSets objectsInRealm:realm where:@"dataObj.@avg = %@", NSNull.null]), 
                              @"Invalid keypath 'dataObj.@avg': @avg can only be applied to a collection of numeric values.");
    RLMAssertThrowsWithReason(([AllOptionalPrimitiveSets objectsInRealm:realm where:@"objectIdObj.@avg = %@", NSNull.null]), 
                              @"Invalid keypath 'objectIdObj.@avg': @avg can only be applied to a collection of numeric values.");
    RLMAssertThrowsWithReason(([AllOptionalPrimitiveSets objectsInRealm:realm where:@"uuidObj.@avg = %@", NSNull.null]), 
                              @"Invalid keypath 'uuidObj.@avg': @avg can only be applied to a collection of numeric values.");
    RLMAssertThrowsWithReason(([AllPrimitiveSets objectsInRealm:realm where:@"dateObj.@avg = %@", date(1)]), 
                              @"Cannot sum or average date properties");
    RLMAssertThrowsWithReason(([AllOptionalPrimitiveSets objectsInRealm:realm where:@"dateObj.@avg = %@", NSNull.null]), 
                              @"Cannot sum or average date properties");

    RLMAssertThrowsWithReason(([AllPrimitiveSets objectsInRealm:realm where:@"intObj.@avg = %@", @"a"]), 
                              @"@avg on a property of type int cannot be compared with 'a'");
    RLMAssertThrowsWithReason(([AllPrimitiveSets objectsInRealm:realm where:@"floatObj.@avg = %@", @"a"]), 
                              @"@avg on a property of type float cannot be compared with 'a'");
    RLMAssertThrowsWithReason(([AllPrimitiveSets objectsInRealm:realm where:@"doubleObj.@avg = %@", @"a"]), 
                              @"@avg on a property of type double cannot be compared with 'a'");
    RLMAssertThrowsWithReason(([AllPrimitiveSets objectsInRealm:realm where:@"decimalObj.@avg = %@", @"a"]), 
                              @"@avg on a property of type decimal128 cannot be compared with 'a'");
    RLMAssertThrowsWithReason(([AllOptionalPrimitiveSets objectsInRealm:realm where:@"intObj.@avg = %@", @"a"]), 
                              @"@avg on a property of type int cannot be compared with 'a'");
    RLMAssertThrowsWithReason(([AllOptionalPrimitiveSets objectsInRealm:realm where:@"floatObj.@avg = %@", @"a"]), 
                              @"@avg on a property of type float cannot be compared with 'a'");
    RLMAssertThrowsWithReason(([AllOptionalPrimitiveSets objectsInRealm:realm where:@"doubleObj.@avg = %@", @"a"]), 
                              @"@avg on a property of type double cannot be compared with 'a'");
    RLMAssertThrowsWithReason(([AllOptionalPrimitiveSets objectsInRealm:realm where:@"decimalObj.@avg = %@", @"a"]), 
                              @"@avg on a property of type decimal128 cannot be compared with 'a'");
    RLMAssertThrowsWithReason(([AllPrimitiveSets objectsInRealm:realm where:@"intObj.@avg.prop = %@", @"a"]), 
                              @"Invalid keypath 'intObj.@avg.prop': @avg on a collection of values must appear at the end of a keypath.");
    RLMAssertThrowsWithReason(([AllPrimitiveSets objectsInRealm:realm where:@"floatObj.@avg.prop = %@", @"a"]), 
                              @"Invalid keypath 'floatObj.@avg.prop': @avg on a collection of values must appear at the end of a keypath.");
    RLMAssertThrowsWithReason(([AllPrimitiveSets objectsInRealm:realm where:@"doubleObj.@avg.prop = %@", @"a"]), 
                              @"Invalid keypath 'doubleObj.@avg.prop': @avg on a collection of values must appear at the end of a keypath.");
    RLMAssertThrowsWithReason(([AllPrimitiveSets objectsInRealm:realm where:@"decimalObj.@avg.prop = %@", @"a"]), 
                              @"Invalid keypath 'decimalObj.@avg.prop': @avg on a collection of values must appear at the end of a keypath.");
    RLMAssertThrowsWithReason(([AllOptionalPrimitiveSets objectsInRealm:realm where:@"intObj.@avg.prop = %@", @"a"]), 
                              @"Invalid keypath 'intObj.@avg.prop': @avg on a collection of values must appear at the end of a keypath.");
    RLMAssertThrowsWithReason(([AllOptionalPrimitiveSets objectsInRealm:realm where:@"floatObj.@avg.prop = %@", @"a"]), 
                              @"Invalid keypath 'floatObj.@avg.prop': @avg on a collection of values must appear at the end of a keypath.");
    RLMAssertThrowsWithReason(([AllOptionalPrimitiveSets objectsInRealm:realm where:@"doubleObj.@avg.prop = %@", @"a"]), 
                              @"Invalid keypath 'doubleObj.@avg.prop': @avg on a collection of values must appear at the end of a keypath.");
    RLMAssertThrowsWithReason(([AllOptionalPrimitiveSets objectsInRealm:realm where:@"decimalObj.@avg.prop = %@", @"a"]), 
                              @"Invalid keypath 'decimalObj.@avg.prop': @avg on a collection of values must appear at the end of a keypath.");

    [AllPrimitiveSets createInRealm:realm withValue:@{
        @"intObj": @[],
        @"floatObj": @[],
        @"doubleObj": @[],
        @"decimalObj": @[],
        @"anyIntObj": @[],
        @"anyFloatObj": @[],
        @"anyDoubleObj": @[],
        @"anyDecimalObj": @[],
    }];
    [AllOptionalPrimitiveSets createInRealm:realm withValue:@{
        @"intObj": @[],
        @"floatObj": @[],
        @"doubleObj": @[],
        @"decimalObj": @[],
    }];
    [AllPrimitiveSets createInRealm:realm withValue:@{
        @"intObj": @[@3],
        @"floatObj": @[@3.3f],
        @"doubleObj": @[@3.3],
        @"decimalObj": @[decimal128(2)],
        @"anyIntObj": @[@3],
        @"anyFloatObj": @[@3.3f],
        @"anyDoubleObj": @[@3.3],
        @"anyDecimalObj": @[decimal128(2)],
    }];
    [AllOptionalPrimitiveSets createInRealm:realm withValue:@{
        @"intObj": @[@3],
        @"floatObj": @[@3.3f],
        @"doubleObj": @[@3.3],
        @"decimalObj": @[decimal128(2)],
    }];
    [AllPrimitiveSets createInRealm:realm withValue:@{
        @"intObj": @[@2, @3],
        @"floatObj": @[@2.2f, @3.3f],
        @"doubleObj": @[@2.2, @3.3],
        @"decimalObj": @[decimal128(1), decimal128(2)],
        @"anyIntObj": @[@2, @3],
        @"anyFloatObj": @[@2.2f, @3.3f],
        @"anyDoubleObj": @[@2.2, @3.3],
        @"anyDecimalObj": @[decimal128(1), decimal128(2)],
    }];
    [AllOptionalPrimitiveSets createInRealm:realm withValue:@{
        @"intObj": @[@2, @3],
        @"floatObj": @[@2.2f, @3.3f],
        @"doubleObj": @[@2.2, @3.3],
        @"decimalObj": @[decimal128(1), decimal128(2)],
    }];
    [AllPrimitiveSets createInRealm:realm withValue:@{
        @"intObj": @[@3],
        @"floatObj": @[@3.3f],
        @"doubleObj": @[@3.3],
        @"decimalObj": @[decimal128(2)],
        @"anyIntObj": @[@3],
        @"anyFloatObj": @[@3.3f],
        @"anyDoubleObj": @[@3.3],
        @"anyDecimalObj": @[decimal128(2)],
    }];
    [AllOptionalPrimitiveSets createInRealm:realm withValue:@{
        @"intObj": @[@3],
        @"floatObj": @[@3.3f],
        @"doubleObj": @[@3.3],
        @"decimalObj": @[decimal128(2)],
    }];

    RLMAssertCount(AllPrimitiveSets, 1U, @"intObj.@avg == %@", NSNull.null);
    RLMAssertCount(AllPrimitiveSets, 1U, @"floatObj.@avg == %@", NSNull.null);
    RLMAssertCount(AllPrimitiveSets, 1U, @"doubleObj.@avg == %@", NSNull.null);
    RLMAssertCount(AllPrimitiveSets, 1U, @"decimalObj.@avg == %@", NSNull.null);
    RLMAssertCount(AllPrimitiveSets, 1U, @"anyIntObj.@avg == %@", NSNull.null);
    RLMAssertCount(AllPrimitiveSets, 1U, @"anyFloatObj.@avg == %@", NSNull.null);
    RLMAssertCount(AllPrimitiveSets, 1U, @"anyDoubleObj.@avg == %@", NSNull.null);
    RLMAssertCount(AllPrimitiveSets, 1U, @"anyDecimalObj.@avg == %@", NSNull.null);
    RLMAssertCount(AllOptionalPrimitiveSets, 1U, @"intObj.@avg == %@", NSNull.null);
    RLMAssertCount(AllOptionalPrimitiveSets, 1U, @"floatObj.@avg == %@", NSNull.null);
    RLMAssertCount(AllOptionalPrimitiveSets, 1U, @"doubleObj.@avg == %@", NSNull.null);
    RLMAssertCount(AllOptionalPrimitiveSets, 1U, @"decimalObj.@avg == %@", NSNull.null);
    RLMAssertCount(AllPrimitiveSets, 2U, @"intObj.@avg == %@", @3);
    RLMAssertCount(AllPrimitiveSets, 2U, @"floatObj.@avg == %@", @3.3f);
    RLMAssertCount(AllPrimitiveSets, 2U, @"doubleObj.@avg == %@", @3.3);
    RLMAssertCount(AllPrimitiveSets, 2U, @"decimalObj.@avg == %@", decimal128(2));
    RLMAssertCount(AllPrimitiveSets, 2U, @"anyIntObj.@avg == %@", @3);
    RLMAssertCount(AllPrimitiveSets, 2U, @"anyFloatObj.@avg == %@", @3.3f);
    RLMAssertCount(AllPrimitiveSets, 2U, @"anyDoubleObj.@avg == %@", @3.3);
    RLMAssertCount(AllPrimitiveSets, 2U, @"anyDecimalObj.@avg == %@", decimal128(2));
    RLMAssertCount(AllOptionalPrimitiveSets, 2U, @"intObj.@avg == %@", @3);
    RLMAssertCount(AllOptionalPrimitiveSets, 2U, @"floatObj.@avg == %@", @3.3f);
    RLMAssertCount(AllOptionalPrimitiveSets, 2U, @"doubleObj.@avg == %@", @3.3);
    RLMAssertCount(AllOptionalPrimitiveSets, 2U, @"decimalObj.@avg == %@", decimal128(2));
    RLMAssertCount(AllPrimitiveSets, 2U, @"intObj.@avg != %@", @3);
    RLMAssertCount(AllPrimitiveSets, 2U, @"floatObj.@avg != %@", @3.3f);
    RLMAssertCount(AllPrimitiveSets, 2U, @"doubleObj.@avg != %@", @3.3);
    RLMAssertCount(AllPrimitiveSets, 2U, @"decimalObj.@avg != %@", decimal128(2));
    RLMAssertCount(AllPrimitiveSets, 2U, @"anyIntObj.@avg != %@", @3);
    RLMAssertCount(AllPrimitiveSets, 2U, @"anyFloatObj.@avg != %@", @3.3f);
    RLMAssertCount(AllPrimitiveSets, 2U, @"anyDoubleObj.@avg != %@", @3.3);
    RLMAssertCount(AllPrimitiveSets, 2U, @"anyDecimalObj.@avg != %@", decimal128(2));
    RLMAssertCount(AllOptionalPrimitiveSets, 2U, @"intObj.@avg != %@", @3);
    RLMAssertCount(AllOptionalPrimitiveSets, 2U, @"floatObj.@avg != %@", @3.3f);
    RLMAssertCount(AllOptionalPrimitiveSets, 2U, @"doubleObj.@avg != %@", @3.3);
    RLMAssertCount(AllOptionalPrimitiveSets, 2U, @"decimalObj.@avg != %@", decimal128(2));
    RLMAssertCount(AllPrimitiveSets, 2U, @"intObj.@avg >= %@", @3);
    RLMAssertCount(AllPrimitiveSets, 2U, @"floatObj.@avg >= %@", @3.3f);
    RLMAssertCount(AllPrimitiveSets, 2U, @"doubleObj.@avg >= %@", @3.3);
    RLMAssertCount(AllPrimitiveSets, 2U, @"decimalObj.@avg >= %@", decimal128(2));
    RLMAssertCount(AllPrimitiveSets, 2U, @"anyIntObj.@avg >= %@", @3);
    RLMAssertCount(AllPrimitiveSets, 2U, @"anyFloatObj.@avg >= %@", @3.3f);
    RLMAssertCount(AllPrimitiveSets, 2U, @"anyDoubleObj.@avg >= %@", @3.3);
    RLMAssertCount(AllPrimitiveSets, 2U, @"anyDecimalObj.@avg >= %@", decimal128(2));
    RLMAssertCount(AllOptionalPrimitiveSets, 2U, @"intObj.@avg >= %@", @3);
    RLMAssertCount(AllOptionalPrimitiveSets, 2U, @"floatObj.@avg >= %@", @3.3f);
    RLMAssertCount(AllOptionalPrimitiveSets, 2U, @"doubleObj.@avg >= %@", @3.3);
    RLMAssertCount(AllOptionalPrimitiveSets, 2U, @"decimalObj.@avg >= %@", decimal128(2));
    RLMAssertCount(AllPrimitiveSets, 3U, @"intObj.@avg > %@", @2);
    RLMAssertCount(AllPrimitiveSets, 3U, @"floatObj.@avg > %@", @2.2f);
    RLMAssertCount(AllPrimitiveSets, 3U, @"doubleObj.@avg > %@", @2.2);
    RLMAssertCount(AllPrimitiveSets, 3U, @"decimalObj.@avg > %@", decimal128(1));
    RLMAssertCount(AllPrimitiveSets, 3U, @"anyIntObj.@avg > %@", @2);
    RLMAssertCount(AllPrimitiveSets, 3U, @"anyFloatObj.@avg > %@", @2.2f);
    RLMAssertCount(AllPrimitiveSets, 3U, @"anyDoubleObj.@avg > %@", @2.2);
    RLMAssertCount(AllPrimitiveSets, 3U, @"anyDecimalObj.@avg > %@", decimal128(1));
    RLMAssertCount(AllOptionalPrimitiveSets, 3U, @"intObj.@avg > %@", @2);
    RLMAssertCount(AllOptionalPrimitiveSets, 3U, @"floatObj.@avg > %@", @2.2f);
    RLMAssertCount(AllOptionalPrimitiveSets, 3U, @"doubleObj.@avg > %@", @2.2);
    RLMAssertCount(AllOptionalPrimitiveSets, 3U, @"decimalObj.@avg > %@", decimal128(1));
    RLMAssertCount(AllPrimitiveSets, 1U, @"intObj.@avg < %@", @3);
    RLMAssertCount(AllPrimitiveSets, 1U, @"floatObj.@avg < %@", @3.3f);
    RLMAssertCount(AllPrimitiveSets, 1U, @"doubleObj.@avg < %@", @3.3);
    RLMAssertCount(AllPrimitiveSets, 1U, @"decimalObj.@avg < %@", decimal128(2));
    RLMAssertCount(AllPrimitiveSets, 1U, @"anyIntObj.@avg < %@", @3);
    RLMAssertCount(AllPrimitiveSets, 1U, @"anyFloatObj.@avg < %@", @3.3f);
    RLMAssertCount(AllPrimitiveSets, 1U, @"anyDoubleObj.@avg < %@", @3.3);
    RLMAssertCount(AllPrimitiveSets, 1U, @"anyDecimalObj.@avg < %@", decimal128(2));
    RLMAssertCount(AllOptionalPrimitiveSets, 1U, @"intObj.@avg < %@", @3);
    RLMAssertCount(AllOptionalPrimitiveSets, 1U, @"floatObj.@avg < %@", @3.3f);
    RLMAssertCount(AllOptionalPrimitiveSets, 1U, @"doubleObj.@avg < %@", @3.3);
    RLMAssertCount(AllOptionalPrimitiveSets, 1U, @"decimalObj.@avg < %@", decimal128(2));
    RLMAssertCount(AllPrimitiveSets, 3U, @"intObj.@avg <= %@", @3);
    RLMAssertCount(AllPrimitiveSets, 3U, @"floatObj.@avg <= %@", @3.3f);
    RLMAssertCount(AllPrimitiveSets, 3U, @"doubleObj.@avg <= %@", @3.3);
    RLMAssertCount(AllPrimitiveSets, 3U, @"decimalObj.@avg <= %@", decimal128(2));
    RLMAssertCount(AllPrimitiveSets, 3U, @"anyIntObj.@avg <= %@", @3);
    RLMAssertCount(AllPrimitiveSets, 3U, @"anyFloatObj.@avg <= %@", @3.3f);
    RLMAssertCount(AllPrimitiveSets, 3U, @"anyDoubleObj.@avg <= %@", @3.3);
    RLMAssertCount(AllPrimitiveSets, 3U, @"anyDecimalObj.@avg <= %@", decimal128(2));
    RLMAssertCount(AllOptionalPrimitiveSets, 3U, @"intObj.@avg <= %@", @3);
    RLMAssertCount(AllOptionalPrimitiveSets, 3U, @"floatObj.@avg <= %@", @3.3f);
    RLMAssertCount(AllOptionalPrimitiveSets, 3U, @"doubleObj.@avg <= %@", @3.3);
    RLMAssertCount(AllOptionalPrimitiveSets, 3U, @"decimalObj.@avg <= %@", decimal128(2));
}

- (void)testQueryMin {
    [realm deleteAllObjects];

    RLMAssertThrowsWithReason(([AllPrimitiveSets objectsInRealm:realm where:@"boolObj.@min = %@", @NO]), 
                              @"Invalid keypath 'boolObj.@min': @min can only be applied to a collection of numeric values.");
    RLMAssertThrowsWithReason(([AllPrimitiveSets objectsInRealm:realm where:@"stringObj.@min = %@", @"a"]), 
                              @"Invalid keypath 'stringObj.@min': @min can only be applied to a collection of numeric values.");
    RLMAssertThrowsWithReason(([AllPrimitiveSets objectsInRealm:realm where:@"dataObj.@min = %@", data(1)]), 
                              @"Invalid keypath 'dataObj.@min': @min can only be applied to a collection of numeric values.");
    RLMAssertThrowsWithReason(([AllPrimitiveSets objectsInRealm:realm where:@"objectIdObj.@min = %@", objectId(1)]), 
                              @"Invalid keypath 'objectIdObj.@min': @min can only be applied to a collection of numeric values.");
    RLMAssertThrowsWithReason(([AllPrimitiveSets objectsInRealm:realm where:@"uuidObj.@min = %@", uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")]), 
                              @"Invalid keypath 'uuidObj.@min': @min can only be applied to a collection of numeric values.");
    RLMAssertThrowsWithReason(([AllOptionalPrimitiveSets objectsInRealm:realm where:@"boolObj.@min = %@", NSNull.null]), 
                              @"Invalid keypath 'boolObj.@min': @min can only be applied to a collection of numeric values.");
    RLMAssertThrowsWithReason(([AllOptionalPrimitiveSets objectsInRealm:realm where:@"stringObj.@min = %@", NSNull.null]), 
                              @"Invalid keypath 'stringObj.@min': @min can only be applied to a collection of numeric values.");
    RLMAssertThrowsWithReason(([AllOptionalPrimitiveSets objectsInRealm:realm where:@"dataObj.@min = %@", NSNull.null]), 
                              @"Invalid keypath 'dataObj.@min': @min can only be applied to a collection of numeric values.");
    RLMAssertThrowsWithReason(([AllOptionalPrimitiveSets objectsInRealm:realm where:@"objectIdObj.@min = %@", NSNull.null]), 
                              @"Invalid keypath 'objectIdObj.@min': @min can only be applied to a collection of numeric values.");
    RLMAssertThrowsWithReason(([AllOptionalPrimitiveSets objectsInRealm:realm where:@"uuidObj.@min = %@", NSNull.null]), 
                              @"Invalid keypath 'uuidObj.@min': @min can only be applied to a collection of numeric values.");
    RLMAssertThrowsWithReason(([AllPrimitiveSets objectsInRealm:realm where:@"intObj.@min = %@", @"a"]), 
                              @"@min on a property of type int cannot be compared with 'a'");
    RLMAssertThrowsWithReason(([AllPrimitiveSets objectsInRealm:realm where:@"floatObj.@min = %@", @"a"]), 
                              @"@min on a property of type float cannot be compared with 'a'");
    RLMAssertThrowsWithReason(([AllPrimitiveSets objectsInRealm:realm where:@"doubleObj.@min = %@", @"a"]), 
                              @"@min on a property of type double cannot be compared with 'a'");
    RLMAssertThrowsWithReason(([AllPrimitiveSets objectsInRealm:realm where:@"dateObj.@min = %@", @"a"]), 
                              @"@min on a property of type date cannot be compared with 'a'");
    RLMAssertThrowsWithReason(([AllPrimitiveSets objectsInRealm:realm where:@"decimalObj.@min = %@", @"a"]), 
                              @"@min on a property of type decimal128 cannot be compared with 'a'");
    RLMAssertThrowsWithReason(([AllOptionalPrimitiveSets objectsInRealm:realm where:@"intObj.@min = %@", @"a"]), 
                              @"@min on a property of type int cannot be compared with 'a'");
    RLMAssertThrowsWithReason(([AllOptionalPrimitiveSets objectsInRealm:realm where:@"floatObj.@min = %@", @"a"]), 
                              @"@min on a property of type float cannot be compared with 'a'");
    RLMAssertThrowsWithReason(([AllOptionalPrimitiveSets objectsInRealm:realm where:@"doubleObj.@min = %@", @"a"]), 
                              @"@min on a property of type double cannot be compared with 'a'");
    RLMAssertThrowsWithReason(([AllOptionalPrimitiveSets objectsInRealm:realm where:@"dateObj.@min = %@", @"a"]), 
                              @"@min on a property of type date cannot be compared with 'a'");
    RLMAssertThrowsWithReason(([AllOptionalPrimitiveSets objectsInRealm:realm where:@"decimalObj.@min = %@", @"a"]), 
                              @"@min on a property of type decimal128 cannot be compared with 'a'");
    RLMAssertThrowsWithReason(([AllPrimitiveSets objectsInRealm:realm where:@"intObj.@min.prop = %@", @"a"]), 
                              @"Invalid keypath 'intObj.@min.prop': @min on a collection of values must appear at the end of a keypath.");
    RLMAssertThrowsWithReason(([AllPrimitiveSets objectsInRealm:realm where:@"floatObj.@min.prop = %@", @"a"]), 
                              @"Invalid keypath 'floatObj.@min.prop': @min on a collection of values must appear at the end of a keypath.");
    RLMAssertThrowsWithReason(([AllPrimitiveSets objectsInRealm:realm where:@"doubleObj.@min.prop = %@", @"a"]), 
                              @"Invalid keypath 'doubleObj.@min.prop': @min on a collection of values must appear at the end of a keypath.");
    RLMAssertThrowsWithReason(([AllPrimitiveSets objectsInRealm:realm where:@"dateObj.@min.prop = %@", @"a"]), 
                              @"Invalid keypath 'dateObj.@min.prop': @min on a collection of values must appear at the end of a keypath.");
    RLMAssertThrowsWithReason(([AllPrimitiveSets objectsInRealm:realm where:@"decimalObj.@min.prop = %@", @"a"]), 
                              @"Invalid keypath 'decimalObj.@min.prop': @min on a collection of values must appear at the end of a keypath.");
    RLMAssertThrowsWithReason(([AllPrimitiveSets objectsInRealm:realm where:@"anyIntObj.@min.prop = %@", @"a"]), 
                              @"Invalid keypath 'anyIntObj.@min.prop': @min on a collection of values must appear at the end of a keypath.");
    RLMAssertThrowsWithReason(([AllPrimitiveSets objectsInRealm:realm where:@"anyFloatObj.@min.prop = %@", @"a"]), 
                              @"Invalid keypath 'anyFloatObj.@min.prop': @min on a collection of values must appear at the end of a keypath.");
    RLMAssertThrowsWithReason(([AllPrimitiveSets objectsInRealm:realm where:@"anyDoubleObj.@min.prop = %@", @"a"]), 
                              @"Invalid keypath 'anyDoubleObj.@min.prop': @min on a collection of values must appear at the end of a keypath.");
    RLMAssertThrowsWithReason(([AllPrimitiveSets objectsInRealm:realm where:@"anyDateObj.@min.prop = %@", @"a"]), 
                              @"Invalid keypath 'anyDateObj.@min.prop': @min on a collection of values must appear at the end of a keypath.");
    RLMAssertThrowsWithReason(([AllPrimitiveSets objectsInRealm:realm where:@"anyDecimalObj.@min.prop = %@", @"a"]), 
                              @"Invalid keypath 'anyDecimalObj.@min.prop': @min on a collection of values must appear at the end of a keypath.");
    RLMAssertThrowsWithReason(([AllOptionalPrimitiveSets objectsInRealm:realm where:@"intObj.@min.prop = %@", @"a"]), 
                              @"Invalid keypath 'intObj.@min.prop': @min on a collection of values must appear at the end of a keypath.");
    RLMAssertThrowsWithReason(([AllOptionalPrimitiveSets objectsInRealm:realm where:@"floatObj.@min.prop = %@", @"a"]), 
                              @"Invalid keypath 'floatObj.@min.prop': @min on a collection of values must appear at the end of a keypath.");
    RLMAssertThrowsWithReason(([AllOptionalPrimitiveSets objectsInRealm:realm where:@"doubleObj.@min.prop = %@", @"a"]), 
                              @"Invalid keypath 'doubleObj.@min.prop': @min on a collection of values must appear at the end of a keypath.");
    RLMAssertThrowsWithReason(([AllOptionalPrimitiveSets objectsInRealm:realm where:@"dateObj.@min.prop = %@", @"a"]), 
                              @"Invalid keypath 'dateObj.@min.prop': @min on a collection of values must appear at the end of a keypath.");
    RLMAssertThrowsWithReason(([AllOptionalPrimitiveSets objectsInRealm:realm where:@"decimalObj.@min.prop = %@", @"a"]), 
                              @"Invalid keypath 'decimalObj.@min.prop': @min on a collection of values must appear at the end of a keypath.");

    // No objects, so count is zero
    RLMAssertCount(AllPrimitiveSets, 0U, @"intObj.@min == %@", @2);
    RLMAssertCount(AllPrimitiveSets, 0U, @"floatObj.@min == %@", @2.2f);
    RLMAssertCount(AllPrimitiveSets, 0U, @"doubleObj.@min == %@", @2.2);
    RLMAssertCount(AllPrimitiveSets, 0U, @"dateObj.@min == %@", date(1));
    RLMAssertCount(AllPrimitiveSets, 0U, @"decimalObj.@min == %@", decimal128(1));
    RLMAssertCount(AllPrimitiveSets, 0U, @"anyIntObj.@min == %@", @2);
    RLMAssertCount(AllPrimitiveSets, 0U, @"anyFloatObj.@min == %@", @2.2f);
    RLMAssertCount(AllPrimitiveSets, 0U, @"anyDoubleObj.@min == %@", @2.2);
    RLMAssertCount(AllPrimitiveSets, 0U, @"anyDateObj.@min == %@", date(1));
    RLMAssertCount(AllPrimitiveSets, 0U, @"anyDecimalObj.@min == %@", decimal128(1));
    RLMAssertCount(AllOptionalPrimitiveSets, 0U, @"intObj.@min == %@", NSNull.null);
    RLMAssertCount(AllOptionalPrimitiveSets, 0U, @"floatObj.@min == %@", NSNull.null);
    RLMAssertCount(AllOptionalPrimitiveSets, 0U, @"doubleObj.@min == %@", NSNull.null);
    RLMAssertCount(AllOptionalPrimitiveSets, 0U, @"dateObj.@min == %@", NSNull.null);
    RLMAssertCount(AllOptionalPrimitiveSets, 0U, @"decimalObj.@min == %@", NSNull.null);

    [AllPrimitiveSets createInRealm:realm withValue:@{}];
    [AllOptionalPrimitiveSets createInRealm:realm withValue:@{}];

    // Only empty arrays, so count is zero
    RLMAssertCount(AllPrimitiveSets, 0U, @"intObj.@min == %@", @2);
    RLMAssertCount(AllPrimitiveSets, 0U, @"floatObj.@min == %@", @2.2f);
    RLMAssertCount(AllPrimitiveSets, 0U, @"doubleObj.@min == %@", @2.2);
    RLMAssertCount(AllPrimitiveSets, 0U, @"dateObj.@min == %@", date(1));
    RLMAssertCount(AllPrimitiveSets, 0U, @"decimalObj.@min == %@", decimal128(1));
    RLMAssertCount(AllPrimitiveSets, 0U, @"anyIntObj.@min == %@", @2);
    RLMAssertCount(AllPrimitiveSets, 0U, @"anyFloatObj.@min == %@", @2.2f);
    RLMAssertCount(AllPrimitiveSets, 0U, @"anyDoubleObj.@min == %@", @2.2);
    RLMAssertCount(AllPrimitiveSets, 0U, @"anyDateObj.@min == %@", date(1));
    RLMAssertCount(AllPrimitiveSets, 0U, @"anyDecimalObj.@min == %@", decimal128(1));
    RLMAssertCount(AllPrimitiveSets, 0U, @"intObj.@min == %@", @3);
    RLMAssertCount(AllPrimitiveSets, 0U, @"floatObj.@min == %@", @3.3f);
    RLMAssertCount(AllPrimitiveSets, 0U, @"doubleObj.@min == %@", @3.3);
    RLMAssertCount(AllPrimitiveSets, 0U, @"dateObj.@min == %@", date(2));
    RLMAssertCount(AllPrimitiveSets, 0U, @"decimalObj.@min == %@", decimal128(2));
    RLMAssertCount(AllPrimitiveSets, 0U, @"anyIntObj.@min == %@", @3);
    RLMAssertCount(AllPrimitiveSets, 0U, @"anyFloatObj.@min == %@", @3.3f);
    RLMAssertCount(AllPrimitiveSets, 0U, @"anyDoubleObj.@min == %@", @3.3);
    RLMAssertCount(AllPrimitiveSets, 0U, @"anyDateObj.@min == %@", date(2));
    RLMAssertCount(AllPrimitiveSets, 0U, @"anyDecimalObj.@min == %@", decimal128(2));

    RLMAssertCount(AllOptionalPrimitiveSets, 0U, @"intObj.@min == %@", @2);
    RLMAssertCount(AllOptionalPrimitiveSets, 0U, @"floatObj.@min == %@", @2.2f);
    RLMAssertCount(AllOptionalPrimitiveSets, 0U, @"doubleObj.@min == %@", @2.2);
    RLMAssertCount(AllOptionalPrimitiveSets, 0U, @"dateObj.@min == %@", date(1));
    RLMAssertCount(AllOptionalPrimitiveSets, 0U, @"decimalObj.@min == %@", decimal128(1));
    RLMAssertCount(AllOptionalPrimitiveSets, 0U, @"intObj.@min == %@", @3);
    RLMAssertCount(AllOptionalPrimitiveSets, 0U, @"floatObj.@min == %@", @3.3f);
    RLMAssertCount(AllOptionalPrimitiveSets, 0U, @"doubleObj.@min == %@", @3.3);
    RLMAssertCount(AllOptionalPrimitiveSets, 0U, @"dateObj.@min == %@", date(2));
    RLMAssertCount(AllOptionalPrimitiveSets, 0U, @"decimalObj.@min == %@", decimal128(2));

    [self createObjectWithValueIndex:1];

    RLMAssertCount(AllPrimitiveSets, 1U, @"intObj.@min == %@", @3);
    RLMAssertCount(AllPrimitiveSets, 1U, @"floatObj.@min == %@", @3.3f);
    RLMAssertCount(AllPrimitiveSets, 1U, @"doubleObj.@min == %@", @3.3);
    RLMAssertCount(AllPrimitiveSets, 1U, @"dateObj.@min == %@", date(2));
    RLMAssertCount(AllPrimitiveSets, 1U, @"decimalObj.@min == %@", decimal128(2));
    RLMAssertCount(AllPrimitiveSets, 1U, @"anyIntObj.@min == %@", @3);
    RLMAssertCount(AllPrimitiveSets, 1U, @"anyFloatObj.@min == %@", @3.3f);
    RLMAssertCount(AllPrimitiveSets, 1U, @"anyDoubleObj.@min == %@", @3.3);
    RLMAssertCount(AllPrimitiveSets, 1U, @"anyDateObj.@min == %@", date(2));
    RLMAssertCount(AllPrimitiveSets, 1U, @"anyDecimalObj.@min == %@", decimal128(2));
    RLMAssertCount(AllOptionalPrimitiveSets, 1U, @"intObj.@min == %@", @2);
    RLMAssertCount(AllOptionalPrimitiveSets, 1U, @"floatObj.@min == %@", @2.2f);
    RLMAssertCount(AllOptionalPrimitiveSets, 1U, @"doubleObj.@min == %@", @2.2);
    RLMAssertCount(AllOptionalPrimitiveSets, 1U, @"dateObj.@min == %@", date(1));
    RLMAssertCount(AllOptionalPrimitiveSets, 1U, @"decimalObj.@min == %@", decimal128(1));

    RLMAssertCount(AllPrimitiveSets, 0U, @"intObj.@min == %@", @2);
    RLMAssertCount(AllPrimitiveSets, 0U, @"floatObj.@min == %@", @2.2f);
    RLMAssertCount(AllPrimitiveSets, 0U, @"doubleObj.@min == %@", @2.2);
    RLMAssertCount(AllPrimitiveSets, 0U, @"dateObj.@min == %@", date(1));
    RLMAssertCount(AllPrimitiveSets, 0U, @"decimalObj.@min == %@", decimal128(1));
    RLMAssertCount(AllPrimitiveSets, 0U, @"anyIntObj.@min == %@", @2);
    RLMAssertCount(AllPrimitiveSets, 0U, @"anyFloatObj.@min == %@", @2.2f);
    RLMAssertCount(AllPrimitiveSets, 0U, @"anyDoubleObj.@min == %@", @2.2);
    RLMAssertCount(AllPrimitiveSets, 0U, @"anyDateObj.@min == %@", date(1));
    RLMAssertCount(AllPrimitiveSets, 0U, @"anyDecimalObj.@min == %@", decimal128(1));
    RLMAssertCount(AllOptionalPrimitiveSets, 0U, @"intObj.@min == %@", @3);
    RLMAssertCount(AllOptionalPrimitiveSets, 0U, @"floatObj.@min == %@", @3.3f);
    RLMAssertCount(AllOptionalPrimitiveSets, 0U, @"doubleObj.@min == %@", @3.3);
    RLMAssertCount(AllOptionalPrimitiveSets, 0U, @"dateObj.@min == %@", date(2));
    RLMAssertCount(AllOptionalPrimitiveSets, 0U, @"decimalObj.@min == %@", decimal128(2));

    [AllPrimitiveSets createInRealm:realm withValue:@{
        @"intObj": @[@3, @2],
        @"floatObj": @[@3.3f, @2.2f],
        @"doubleObj": @[@3.3, @2.2],
        @"dateObj": @[date(2), date(1)],
        @"decimalObj": @[decimal128(2), decimal128(1)],
        @"anyIntObj": @[@3, @2],
        @"anyFloatObj": @[@3.3f, @2.2f],
        @"anyDoubleObj": @[@3.3, @2.2],
        @"anyDateObj": @[date(2), date(1)],
        @"anyDecimalObj": @[decimal128(2), decimal128(1)],
    }];
    [AllOptionalPrimitiveSets createInRealm:realm withValue:@{
        @"intObj": @[@3, @2],
        @"floatObj": @[@3.3f, @2.2f],
        @"doubleObj": @[@3.3, @2.2],
        @"dateObj": @[date(2), date(1)],
        @"decimalObj": @[decimal128(2), decimal128(1)],
    }];

    RLMAssertCount(AllPrimitiveSets, 1U, @"intObj.@min == %@", @2);
    RLMAssertCount(AllPrimitiveSets, 1U, @"floatObj.@min == %@", @2.2f);
    RLMAssertCount(AllPrimitiveSets, 1U, @"doubleObj.@min == %@", @2.2);
    RLMAssertCount(AllPrimitiveSets, 1U, @"dateObj.@min == %@", date(1));
    RLMAssertCount(AllPrimitiveSets, 1U, @"decimalObj.@min == %@", decimal128(1));
    RLMAssertCount(AllPrimitiveSets, 1U, @"anyIntObj.@min == %@", @2);
    RLMAssertCount(AllPrimitiveSets, 1U, @"anyFloatObj.@min == %@", @2.2f);
    RLMAssertCount(AllPrimitiveSets, 1U, @"anyDoubleObj.@min == %@", @2.2);
    RLMAssertCount(AllPrimitiveSets, 1U, @"anyDateObj.@min == %@", date(1));
    RLMAssertCount(AllPrimitiveSets, 1U, @"anyDecimalObj.@min == %@", decimal128(1));
    RLMAssertCount(AllOptionalPrimitiveSets, 2U, @"intObj.@min == %@", @2);
    RLMAssertCount(AllOptionalPrimitiveSets, 2U, @"floatObj.@min == %@", @2.2f);
    RLMAssertCount(AllOptionalPrimitiveSets, 2U, @"doubleObj.@min == %@", @2.2);
    RLMAssertCount(AllOptionalPrimitiveSets, 2U, @"dateObj.@min == %@", date(1));
    RLMAssertCount(AllOptionalPrimitiveSets, 2U, @"decimalObj.@min == %@", decimal128(1));

    RLMAssertCount(AllPrimitiveSets, 1U, @"intObj.@min == %@", @2);
    RLMAssertCount(AllPrimitiveSets, 1U, @"floatObj.@min == %@", @2.2f);
    RLMAssertCount(AllPrimitiveSets, 1U, @"doubleObj.@min == %@", @2.2);
    RLMAssertCount(AllPrimitiveSets, 1U, @"dateObj.@min == %@", date(1));
    RLMAssertCount(AllPrimitiveSets, 1U, @"decimalObj.@min == %@", decimal128(1));
    RLMAssertCount(AllPrimitiveSets, 1U, @"anyIntObj.@min == %@", @2);
    RLMAssertCount(AllPrimitiveSets, 1U, @"anyFloatObj.@min == %@", @2.2f);
    RLMAssertCount(AllPrimitiveSets, 1U, @"anyDoubleObj.@min == %@", @2.2);
    RLMAssertCount(AllPrimitiveSets, 1U, @"anyDateObj.@min == %@", date(1));
    RLMAssertCount(AllPrimitiveSets, 1U, @"anyDecimalObj.@min == %@", decimal128(1));
    RLMAssertCount(AllOptionalPrimitiveSets, 2U, @"intObj.@min == %@", @2);
    RLMAssertCount(AllOptionalPrimitiveSets, 2U, @"floatObj.@min == %@", @2.2f);
    RLMAssertCount(AllOptionalPrimitiveSets, 2U, @"doubleObj.@min == %@", @2.2);
    RLMAssertCount(AllOptionalPrimitiveSets, 2U, @"dateObj.@min == %@", date(1));
    RLMAssertCount(AllOptionalPrimitiveSets, 2U, @"decimalObj.@min == %@", decimal128(1));
}

- (void)testQueryMax {
    [realm deleteAllObjects];

    RLMAssertThrowsWithReason(([AllPrimitiveSets objectsInRealm:realm where:@"boolObj.@max = %@", @NO]), 
                              @"Invalid keypath 'boolObj.@max': @max can only be applied to a collection of numeric values.");
    RLMAssertThrowsWithReason(([AllPrimitiveSets objectsInRealm:realm where:@"stringObj.@max = %@", @"a"]), 
                              @"Invalid keypath 'stringObj.@max': @max can only be applied to a collection of numeric values.");
    RLMAssertThrowsWithReason(([AllPrimitiveSets objectsInRealm:realm where:@"dataObj.@max = %@", data(1)]), 
                              @"Invalid keypath 'dataObj.@max': @max can only be applied to a collection of numeric values.");
    RLMAssertThrowsWithReason(([AllPrimitiveSets objectsInRealm:realm where:@"objectIdObj.@max = %@", objectId(1)]), 
                              @"Invalid keypath 'objectIdObj.@max': @max can only be applied to a collection of numeric values.");
    RLMAssertThrowsWithReason(([AllPrimitiveSets objectsInRealm:realm where:@"uuidObj.@max = %@", uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")]), 
                              @"Invalid keypath 'uuidObj.@max': @max can only be applied to a collection of numeric values.");
    RLMAssertThrowsWithReason(([AllOptionalPrimitiveSets objectsInRealm:realm where:@"boolObj.@max = %@", NSNull.null]), 
                              @"Invalid keypath 'boolObj.@max': @max can only be applied to a collection of numeric values.");
    RLMAssertThrowsWithReason(([AllOptionalPrimitiveSets objectsInRealm:realm where:@"stringObj.@max = %@", NSNull.null]), 
                              @"Invalid keypath 'stringObj.@max': @max can only be applied to a collection of numeric values.");
    RLMAssertThrowsWithReason(([AllOptionalPrimitiveSets objectsInRealm:realm where:@"dataObj.@max = %@", NSNull.null]), 
                              @"Invalid keypath 'dataObj.@max': @max can only be applied to a collection of numeric values.");
    RLMAssertThrowsWithReason(([AllOptionalPrimitiveSets objectsInRealm:realm where:@"objectIdObj.@max = %@", NSNull.null]), 
                              @"Invalid keypath 'objectIdObj.@max': @max can only be applied to a collection of numeric values.");
    RLMAssertThrowsWithReason(([AllOptionalPrimitiveSets objectsInRealm:realm where:@"uuidObj.@max = %@", NSNull.null]), 
                              @"Invalid keypath 'uuidObj.@max': @max can only be applied to a collection of numeric values.");
    RLMAssertThrowsWithReason(([AllPrimitiveSets objectsInRealm:realm where:@"intObj.@max = %@", @"a"]), 
                              @"@max on a property of type int cannot be compared with 'a'");
    RLMAssertThrowsWithReason(([AllPrimitiveSets objectsInRealm:realm where:@"floatObj.@max = %@", @"a"]), 
                              @"@max on a property of type float cannot be compared with 'a'");
    RLMAssertThrowsWithReason(([AllPrimitiveSets objectsInRealm:realm where:@"doubleObj.@max = %@", @"a"]), 
                              @"@max on a property of type double cannot be compared with 'a'");
    RLMAssertThrowsWithReason(([AllPrimitiveSets objectsInRealm:realm where:@"dateObj.@max = %@", @"a"]), 
                              @"@max on a property of type date cannot be compared with 'a'");
    RLMAssertThrowsWithReason(([AllPrimitiveSets objectsInRealm:realm where:@"decimalObj.@max = %@", @"a"]), 
                              @"@max on a property of type decimal128 cannot be compared with 'a'");
    RLMAssertThrowsWithReason(([AllOptionalPrimitiveSets objectsInRealm:realm where:@"intObj.@max = %@", @"a"]), 
                              @"@max on a property of type int cannot be compared with 'a'");
    RLMAssertThrowsWithReason(([AllOptionalPrimitiveSets objectsInRealm:realm where:@"floatObj.@max = %@", @"a"]), 
                              @"@max on a property of type float cannot be compared with 'a'");
    RLMAssertThrowsWithReason(([AllOptionalPrimitiveSets objectsInRealm:realm where:@"doubleObj.@max = %@", @"a"]), 
                              @"@max on a property of type double cannot be compared with 'a'");
    RLMAssertThrowsWithReason(([AllOptionalPrimitiveSets objectsInRealm:realm where:@"dateObj.@max = %@", @"a"]), 
                              @"@max on a property of type date cannot be compared with 'a'");
    RLMAssertThrowsWithReason(([AllOptionalPrimitiveSets objectsInRealm:realm where:@"decimalObj.@max = %@", @"a"]), 
                              @"@max on a property of type decimal128 cannot be compared with 'a'");
    RLMAssertThrowsWithReason(([AllPrimitiveSets objectsInRealm:realm where:@"intObj.@max.prop = %@", @"a"]), 
                              @"Invalid keypath 'intObj.@max.prop': @max on a collection of values must appear at the end of a keypath.");
    RLMAssertThrowsWithReason(([AllPrimitiveSets objectsInRealm:realm where:@"floatObj.@max.prop = %@", @"a"]), 
                              @"Invalid keypath 'floatObj.@max.prop': @max on a collection of values must appear at the end of a keypath.");
    RLMAssertThrowsWithReason(([AllPrimitiveSets objectsInRealm:realm where:@"doubleObj.@max.prop = %@", @"a"]), 
                              @"Invalid keypath 'doubleObj.@max.prop': @max on a collection of values must appear at the end of a keypath.");
    RLMAssertThrowsWithReason(([AllPrimitiveSets objectsInRealm:realm where:@"dateObj.@max.prop = %@", @"a"]), 
                              @"Invalid keypath 'dateObj.@max.prop': @max on a collection of values must appear at the end of a keypath.");
    RLMAssertThrowsWithReason(([AllPrimitiveSets objectsInRealm:realm where:@"decimalObj.@max.prop = %@", @"a"]), 
                              @"Invalid keypath 'decimalObj.@max.prop': @max on a collection of values must appear at the end of a keypath.");
    RLMAssertThrowsWithReason(([AllPrimitiveSets objectsInRealm:realm where:@"anyIntObj.@max.prop = %@", @"a"]), 
                              @"Invalid keypath 'anyIntObj.@max.prop': @max on a collection of values must appear at the end of a keypath.");
    RLMAssertThrowsWithReason(([AllPrimitiveSets objectsInRealm:realm where:@"anyFloatObj.@max.prop = %@", @"a"]), 
                              @"Invalid keypath 'anyFloatObj.@max.prop': @max on a collection of values must appear at the end of a keypath.");
    RLMAssertThrowsWithReason(([AllPrimitiveSets objectsInRealm:realm where:@"anyDoubleObj.@max.prop = %@", @"a"]), 
                              @"Invalid keypath 'anyDoubleObj.@max.prop': @max on a collection of values must appear at the end of a keypath.");
    RLMAssertThrowsWithReason(([AllPrimitiveSets objectsInRealm:realm where:@"anyDateObj.@max.prop = %@", @"a"]), 
                              @"Invalid keypath 'anyDateObj.@max.prop': @max on a collection of values must appear at the end of a keypath.");
    RLMAssertThrowsWithReason(([AllPrimitiveSets objectsInRealm:realm where:@"anyDecimalObj.@max.prop = %@", @"a"]), 
                              @"Invalid keypath 'anyDecimalObj.@max.prop': @max on a collection of values must appear at the end of a keypath.");
    RLMAssertThrowsWithReason(([AllOptionalPrimitiveSets objectsInRealm:realm where:@"intObj.@max.prop = %@", @"a"]), 
                              @"Invalid keypath 'intObj.@max.prop': @max on a collection of values must appear at the end of a keypath.");
    RLMAssertThrowsWithReason(([AllOptionalPrimitiveSets objectsInRealm:realm where:@"floatObj.@max.prop = %@", @"a"]), 
                              @"Invalid keypath 'floatObj.@max.prop': @max on a collection of values must appear at the end of a keypath.");
    RLMAssertThrowsWithReason(([AllOptionalPrimitiveSets objectsInRealm:realm where:@"doubleObj.@max.prop = %@", @"a"]), 
                              @"Invalid keypath 'doubleObj.@max.prop': @max on a collection of values must appear at the end of a keypath.");
    RLMAssertThrowsWithReason(([AllOptionalPrimitiveSets objectsInRealm:realm where:@"dateObj.@max.prop = %@", @"a"]), 
                              @"Invalid keypath 'dateObj.@max.prop': @max on a collection of values must appear at the end of a keypath.");
    RLMAssertThrowsWithReason(([AllOptionalPrimitiveSets objectsInRealm:realm where:@"decimalObj.@max.prop = %@", @"a"]), 
                              @"Invalid keypath 'decimalObj.@max.prop': @max on a collection of values must appear at the end of a keypath.");

    // No objects, so count is zero
    RLMAssertCount(AllPrimitiveSets, 0U, @"intObj.@max == %@", @2);
    RLMAssertCount(AllPrimitiveSets, 0U, @"floatObj.@max == %@", @2.2f);
    RLMAssertCount(AllPrimitiveSets, 0U, @"doubleObj.@max == %@", @2.2);
    RLMAssertCount(AllPrimitiveSets, 0U, @"dateObj.@max == %@", date(1));
    RLMAssertCount(AllPrimitiveSets, 0U, @"decimalObj.@max == %@", decimal128(1));
    RLMAssertCount(AllPrimitiveSets, 0U, @"anyIntObj.@max == %@", @2);
    RLMAssertCount(AllPrimitiveSets, 0U, @"anyFloatObj.@max == %@", @2.2f);
    RLMAssertCount(AllPrimitiveSets, 0U, @"anyDoubleObj.@max == %@", @2.2);
    RLMAssertCount(AllPrimitiveSets, 0U, @"anyDateObj.@max == %@", date(1));
    RLMAssertCount(AllPrimitiveSets, 0U, @"anyDecimalObj.@max == %@", decimal128(1));
    RLMAssertCount(AllOptionalPrimitiveSets, 0U, @"intObj.@max == %@", NSNull.null);
    RLMAssertCount(AllOptionalPrimitiveSets, 0U, @"floatObj.@max == %@", NSNull.null);
    RLMAssertCount(AllOptionalPrimitiveSets, 0U, @"doubleObj.@max == %@", NSNull.null);
    RLMAssertCount(AllOptionalPrimitiveSets, 0U, @"dateObj.@max == %@", NSNull.null);
    RLMAssertCount(AllOptionalPrimitiveSets, 0U, @"decimalObj.@max == %@", NSNull.null);

    [AllPrimitiveSets createInRealm:realm withValue:@{}];
    [AllOptionalPrimitiveSets createInRealm:realm withValue:@{}];

    // Only empty arrays, so count is zero
    RLMAssertCount(AllPrimitiveSets, 0U, @"intObj.@max == %@", @2);
    RLMAssertCount(AllPrimitiveSets, 0U, @"floatObj.@max == %@", @2.2f);
    RLMAssertCount(AllPrimitiveSets, 0U, @"doubleObj.@max == %@", @2.2);
    RLMAssertCount(AllPrimitiveSets, 0U, @"dateObj.@max == %@", date(1));
    RLMAssertCount(AllPrimitiveSets, 0U, @"decimalObj.@max == %@", decimal128(1));
    RLMAssertCount(AllPrimitiveSets, 0U, @"anyIntObj.@max == %@", @2);
    RLMAssertCount(AllPrimitiveSets, 0U, @"anyFloatObj.@max == %@", @2.2f);
    RLMAssertCount(AllPrimitiveSets, 0U, @"anyDoubleObj.@max == %@", @2.2);
    RLMAssertCount(AllPrimitiveSets, 0U, @"anyDateObj.@max == %@", date(1));
    RLMAssertCount(AllPrimitiveSets, 0U, @"anyDecimalObj.@max == %@", decimal128(1));
    RLMAssertCount(AllPrimitiveSets, 0U, @"intObj.@max == %@", @3);
    RLMAssertCount(AllPrimitiveSets, 0U, @"floatObj.@max == %@", @3.3f);
    RLMAssertCount(AllPrimitiveSets, 0U, @"doubleObj.@max == %@", @3.3);
    RLMAssertCount(AllPrimitiveSets, 0U, @"dateObj.@max == %@", date(2));
    RLMAssertCount(AllPrimitiveSets, 0U, @"decimalObj.@max == %@", decimal128(2));
    RLMAssertCount(AllPrimitiveSets, 0U, @"anyIntObj.@max == %@", @3);
    RLMAssertCount(AllPrimitiveSets, 0U, @"anyFloatObj.@max == %@", @3.3f);
    RLMAssertCount(AllPrimitiveSets, 0U, @"anyDoubleObj.@max == %@", @3.3);
    RLMAssertCount(AllPrimitiveSets, 0U, @"anyDateObj.@max == %@", date(2));
    RLMAssertCount(AllPrimitiveSets, 0U, @"anyDecimalObj.@max == %@", decimal128(2));

    RLMAssertCount(AllOptionalPrimitiveSets, 0U, @"intObj.@max == %@", @2);
    RLMAssertCount(AllOptionalPrimitiveSets, 0U, @"floatObj.@max == %@", @2.2f);
    RLMAssertCount(AllOptionalPrimitiveSets, 0U, @"doubleObj.@max == %@", @2.2);
    RLMAssertCount(AllOptionalPrimitiveSets, 0U, @"dateObj.@max == %@", date(1));
    RLMAssertCount(AllOptionalPrimitiveSets, 0U, @"decimalObj.@max == %@", decimal128(1));
    RLMAssertCount(AllOptionalPrimitiveSets, 0U, @"intObj.@max == %@", @3);
    RLMAssertCount(AllOptionalPrimitiveSets, 0U, @"floatObj.@max == %@", @3.3f);
    RLMAssertCount(AllOptionalPrimitiveSets, 0U, @"doubleObj.@max == %@", @3.3);
    RLMAssertCount(AllOptionalPrimitiveSets, 0U, @"dateObj.@max == %@", date(2));
    RLMAssertCount(AllOptionalPrimitiveSets, 0U, @"decimalObj.@max == %@", decimal128(2));

    RLMAssertCount(AllPrimitiveSets, 1U, @"intObj.@max == nil");
    RLMAssertCount(AllPrimitiveSets, 1U, @"floatObj.@max == nil");
    RLMAssertCount(AllPrimitiveSets, 1U, @"doubleObj.@max == nil");
    RLMAssertCount(AllPrimitiveSets, 1U, @"dateObj.@max == nil");
    RLMAssertCount(AllPrimitiveSets, 1U, @"decimalObj.@max == nil");
    RLMAssertCount(AllPrimitiveSets, 1U, @"anyIntObj.@max == nil");
    RLMAssertCount(AllPrimitiveSets, 1U, @"anyFloatObj.@max == nil");
    RLMAssertCount(AllPrimitiveSets, 1U, @"anyDoubleObj.@max == nil");
    RLMAssertCount(AllPrimitiveSets, 1U, @"anyDateObj.@max == nil");
    RLMAssertCount(AllPrimitiveSets, 1U, @"anyDecimalObj.@max == nil");
    RLMAssertCount(AllOptionalPrimitiveSets, 1U, @"intObj.@max == nil");
    RLMAssertCount(AllOptionalPrimitiveSets, 1U, @"floatObj.@max == nil");
    RLMAssertCount(AllOptionalPrimitiveSets, 1U, @"doubleObj.@max == nil");
    RLMAssertCount(AllOptionalPrimitiveSets, 1U, @"dateObj.@max == nil");
    RLMAssertCount(AllOptionalPrimitiveSets, 1U, @"decimalObj.@max == nil");
    RLMAssertCount(AllPrimitiveSets, 1U, @"intObj.@max == %@", NSNull.null);
    RLMAssertCount(AllPrimitiveSets, 1U, @"floatObj.@max == %@", NSNull.null);
    RLMAssertCount(AllPrimitiveSets, 1U, @"doubleObj.@max == %@", NSNull.null);
    RLMAssertCount(AllPrimitiveSets, 1U, @"dateObj.@max == %@", NSNull.null);
    RLMAssertCount(AllPrimitiveSets, 1U, @"decimalObj.@max == %@", NSNull.null);
    RLMAssertCount(AllPrimitiveSets, 1U, @"anyIntObj.@max == %@", NSNull.null);
    RLMAssertCount(AllPrimitiveSets, 1U, @"anyFloatObj.@max == %@", NSNull.null);
    RLMAssertCount(AllPrimitiveSets, 1U, @"anyDoubleObj.@max == %@", NSNull.null);
    RLMAssertCount(AllPrimitiveSets, 1U, @"anyDateObj.@max == %@", NSNull.null);
    RLMAssertCount(AllPrimitiveSets, 1U, @"anyDecimalObj.@max == %@", NSNull.null);
    RLMAssertCount(AllOptionalPrimitiveSets, 1U, @"intObj.@max == %@", NSNull.null);
    RLMAssertCount(AllOptionalPrimitiveSets, 1U, @"floatObj.@max == %@", NSNull.null);
    RLMAssertCount(AllOptionalPrimitiveSets, 1U, @"doubleObj.@max == %@", NSNull.null);
    RLMAssertCount(AllOptionalPrimitiveSets, 1U, @"dateObj.@max == %@", NSNull.null);
    RLMAssertCount(AllOptionalPrimitiveSets, 1U, @"decimalObj.@max == %@", NSNull.null);

    [self createObjectWithValueIndex:1];

    RLMAssertCount(AllPrimitiveSets, 1U, @"intObj.@max == %@", @3);
    RLMAssertCount(AllPrimitiveSets, 1U, @"floatObj.@max == %@", @3.3f);
    RLMAssertCount(AllPrimitiveSets, 1U, @"doubleObj.@max == %@", @3.3);
    RLMAssertCount(AllPrimitiveSets, 1U, @"dateObj.@max == %@", date(2));
    RLMAssertCount(AllPrimitiveSets, 1U, @"decimalObj.@max == %@", decimal128(2));
    RLMAssertCount(AllPrimitiveSets, 1U, @"anyIntObj.@max == %@", @3);
    RLMAssertCount(AllPrimitiveSets, 1U, @"anyFloatObj.@max == %@", @3.3f);
    RLMAssertCount(AllPrimitiveSets, 1U, @"anyDoubleObj.@max == %@", @3.3);
    RLMAssertCount(AllPrimitiveSets, 1U, @"anyDateObj.@max == %@", date(2));
    RLMAssertCount(AllPrimitiveSets, 1U, @"anyDecimalObj.@max == %@", decimal128(2));
    RLMAssertCount(AllPrimitiveSets, 0U, @"intObj.@max == %@", @2);
    RLMAssertCount(AllPrimitiveSets, 0U, @"floatObj.@max == %@", @2.2f);
    RLMAssertCount(AllPrimitiveSets, 0U, @"doubleObj.@max == %@", @2.2);
    RLMAssertCount(AllPrimitiveSets, 0U, @"dateObj.@max == %@", date(1));
    RLMAssertCount(AllPrimitiveSets, 0U, @"decimalObj.@max == %@", decimal128(1));
    RLMAssertCount(AllPrimitiveSets, 0U, @"anyIntObj.@max == %@", @2);
    RLMAssertCount(AllPrimitiveSets, 0U, @"anyFloatObj.@max == %@", @2.2f);
    RLMAssertCount(AllPrimitiveSets, 0U, @"anyDoubleObj.@max == %@", @2.2);
    RLMAssertCount(AllPrimitiveSets, 0U, @"anyDateObj.@max == %@", date(1));
    RLMAssertCount(AllPrimitiveSets, 0U, @"anyDecimalObj.@max == %@", decimal128(1));

    RLMAssertCount(AllOptionalPrimitiveSets, 1U, @"intObj.@max == %@", @2);
    RLMAssertCount(AllOptionalPrimitiveSets, 1U, @"floatObj.@max == %@", @2.2f);
    RLMAssertCount(AllOptionalPrimitiveSets, 1U, @"doubleObj.@max == %@", @2.2);
    RLMAssertCount(AllOptionalPrimitiveSets, 1U, @"dateObj.@max == %@", date(1));
    RLMAssertCount(AllOptionalPrimitiveSets, 1U, @"decimalObj.@max == %@", decimal128(1));
    RLMAssertCount(AllOptionalPrimitiveSets, 0U, @"intObj.@max == %@", @3);
    RLMAssertCount(AllOptionalPrimitiveSets, 0U, @"floatObj.@max == %@", @3.3f);
    RLMAssertCount(AllOptionalPrimitiveSets, 0U, @"doubleObj.@max == %@", @3.3);
    RLMAssertCount(AllOptionalPrimitiveSets, 0U, @"dateObj.@max == %@", date(2));
    RLMAssertCount(AllOptionalPrimitiveSets, 0U, @"decimalObj.@max == %@", decimal128(2));

    [AllPrimitiveSets createInRealm:realm withValue:@{
        @"intObj": @[@2],
        @"floatObj": @[@2.2f],
        @"doubleObj": @[@2.2],
        @"dateObj": @[date(1)],
        @"decimalObj": @[decimal128(1)],
        @"anyIntObj": @[@2],
        @"anyFloatObj": @[@2.2f],
        @"anyDoubleObj": @[@2.2],
        @"anyDateObj": @[date(1)],
        @"anyDecimalObj": @[decimal128(1)],
    }];

    [AllPrimitiveSets createInRealm:realm withValue:@{
        @"intObj": @[@3, @2],
        @"floatObj": @[@3.3f, @2.2f],
        @"doubleObj": @[@3.3, @2.2],
        @"dateObj": @[date(2), date(1)],
        @"decimalObj": @[decimal128(2), decimal128(1)],
        @"anyIntObj": @[@3, @2],
        @"anyFloatObj": @[@3.3f, @2.2f],
        @"anyDoubleObj": @[@3.3, @2.2],
        @"anyDateObj": @[date(2), date(1)],
        @"anyDecimalObj": @[decimal128(2), decimal128(1)],
    }];
    [AllOptionalPrimitiveSets createInRealm:realm withValue:@{
        @"intObj": @[@2, NSNull.null],
        @"floatObj": @[@2.2f, NSNull.null],
        @"doubleObj": @[@2.2, NSNull.null],
        @"dateObj": @[date(1), NSNull.null],
        @"decimalObj": @[decimal128(1), NSNull.null],
    }];

    RLMAssertCount(AllPrimitiveSets, 1U, @"intObj.@max == %@", @2);
    RLMAssertCount(AllPrimitiveSets, 1U, @"floatObj.@max == %@", @2.2f);
    RLMAssertCount(AllPrimitiveSets, 1U, @"doubleObj.@max == %@", @2.2);
    RLMAssertCount(AllPrimitiveSets, 1U, @"dateObj.@max == %@", date(1));
    RLMAssertCount(AllPrimitiveSets, 1U, @"decimalObj.@max == %@", decimal128(1));
    RLMAssertCount(AllPrimitiveSets, 2U, @"intObj.@max == %@", @3);
    RLMAssertCount(AllPrimitiveSets, 2U, @"floatObj.@max == %@", @3.3f);
    RLMAssertCount(AllPrimitiveSets, 2U, @"doubleObj.@max == %@", @3.3);
    RLMAssertCount(AllPrimitiveSets, 2U, @"dateObj.@max == %@", date(2));
    RLMAssertCount(AllPrimitiveSets, 2U, @"decimalObj.@max == %@", decimal128(2));

    RLMAssertCount(AllOptionalPrimitiveSets, 1U, @"intObj.@max == %@", NSNull.null);
    RLMAssertCount(AllOptionalPrimitiveSets, 1U, @"floatObj.@max == %@", NSNull.null);
    RLMAssertCount(AllOptionalPrimitiveSets, 1U, @"doubleObj.@max == %@", NSNull.null);
    RLMAssertCount(AllOptionalPrimitiveSets, 1U, @"dateObj.@max == %@", NSNull.null);
    RLMAssertCount(AllOptionalPrimitiveSets, 1U, @"decimalObj.@max == %@", NSNull.null);
    RLMAssertCount(AllOptionalPrimitiveSets, 2U, @"intObj.@max == %@", @2);
    RLMAssertCount(AllOptionalPrimitiveSets, 2U, @"floatObj.@max == %@", @2.2f);
    RLMAssertCount(AllOptionalPrimitiveSets, 2U, @"doubleObj.@max == %@", @2.2);
    RLMAssertCount(AllOptionalPrimitiveSets, 2U, @"dateObj.@max == %@", date(1));
    RLMAssertCount(AllOptionalPrimitiveSets, 2U, @"decimalObj.@max == %@", decimal128(1));

    RLMAssertCount(AllPrimitiveSets, 1U, @"anyIntObj.@max == %@", @2);
    RLMAssertCount(AllPrimitiveSets, 1U, @"anyFloatObj.@max == %@", @2.2f);
    RLMAssertCount(AllPrimitiveSets, 1U, @"anyDoubleObj.@max == %@", @2.2);
    RLMAssertCount(AllPrimitiveSets, 1U, @"anyDateObj.@max == %@", date(1));
    RLMAssertCount(AllPrimitiveSets, 1U, @"anyDecimalObj.@max == %@", decimal128(1));
    RLMAssertCount(AllPrimitiveSets, 2U, @"anyIntObj.@max == %@", @3);
    RLMAssertCount(AllPrimitiveSets, 2U, @"anyFloatObj.@max == %@", @3.3f);
    RLMAssertCount(AllPrimitiveSets, 2U, @"anyDoubleObj.@max == %@", @3.3);
    RLMAssertCount(AllPrimitiveSets, 2U, @"anyDateObj.@max == %@", date(2));
    RLMAssertCount(AllPrimitiveSets, 2U, @"anyDecimalObj.@max == %@", decimal128(2));
}

- (void)testQueryBasicOperatorsOverLink {
    [realm deleteAllObjects];

    RLMAssertCount(LinkToAllPrimitiveSets, 0, @"ANY link.boolObj = %@", @NO);
    RLMAssertCount(LinkToAllPrimitiveSets, 0, @"ANY link.intObj = %@", @2);
    RLMAssertCount(LinkToAllPrimitiveSets, 0, @"ANY link.floatObj = %@", @2.2f);
    RLMAssertCount(LinkToAllPrimitiveSets, 0, @"ANY link.doubleObj = %@", @2.2);
    RLMAssertCount(LinkToAllPrimitiveSets, 0, @"ANY link.stringObj = %@", @"a");
    RLMAssertCount(LinkToAllPrimitiveSets, 0, @"ANY link.dataObj = %@", data(1));
    RLMAssertCount(LinkToAllPrimitiveSets, 0, @"ANY link.dateObj = %@", date(1));
    RLMAssertCount(LinkToAllPrimitiveSets, 0, @"ANY link.decimalObj = %@", decimal128(1));
    RLMAssertCount(LinkToAllPrimitiveSets, 0, @"ANY link.objectIdObj = %@", objectId(1));
    RLMAssertCount(LinkToAllPrimitiveSets, 0, @"ANY link.uuidObj = %@", uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"));
    RLMAssertCount(LinkToAllPrimitiveSets, 0, @"ANY link.anyBoolObj = %@", @NO);
    RLMAssertCount(LinkToAllPrimitiveSets, 0, @"ANY link.anyIntObj = %@", @2);
    RLMAssertCount(LinkToAllPrimitiveSets, 0, @"ANY link.anyFloatObj = %@", @2.2f);
    RLMAssertCount(LinkToAllPrimitiveSets, 0, @"ANY link.anyDoubleObj = %@", @2.2);
    RLMAssertCount(LinkToAllPrimitiveSets, 0, @"ANY link.anyStringObj = %@", @"a");
    RLMAssertCount(LinkToAllPrimitiveSets, 0, @"ANY link.anyDataObj = %@", data(1));
    RLMAssertCount(LinkToAllPrimitiveSets, 0, @"ANY link.anyDateObj = %@", date(1));
    RLMAssertCount(LinkToAllPrimitiveSets, 0, @"ANY link.anyDecimalObj = %@", decimal128(1));
    RLMAssertCount(LinkToAllPrimitiveSets, 0, @"ANY link.anyObjectIdObj = %@", objectId(1));
    RLMAssertCount(LinkToAllPrimitiveSets, 0, @"ANY link.anyUUIDObj = %@", uuid(@"00000000-0000-0000-0000-000000000000"));
    RLMAssertCount(LinkToAllOptionalPrimitiveSets, 0, @"ANY link.boolObj = %@", NSNull.null);
    RLMAssertCount(LinkToAllOptionalPrimitiveSets, 0, @"ANY link.intObj = %@", NSNull.null);
    RLMAssertCount(LinkToAllOptionalPrimitiveSets, 0, @"ANY link.floatObj = %@", NSNull.null);
    RLMAssertCount(LinkToAllOptionalPrimitiveSets, 0, @"ANY link.doubleObj = %@", NSNull.null);
    RLMAssertCount(LinkToAllOptionalPrimitiveSets, 0, @"ANY link.stringObj = %@", NSNull.null);
    RLMAssertCount(LinkToAllOptionalPrimitiveSets, 0, @"ANY link.dataObj = %@", NSNull.null);
    RLMAssertCount(LinkToAllOptionalPrimitiveSets, 0, @"ANY link.dateObj = %@", NSNull.null);
    RLMAssertCount(LinkToAllOptionalPrimitiveSets, 0, @"ANY link.decimalObj = %@", NSNull.null);
    RLMAssertCount(LinkToAllOptionalPrimitiveSets, 0, @"ANY link.objectIdObj = %@", NSNull.null);
    RLMAssertCount(LinkToAllOptionalPrimitiveSets, 0, @"ANY link.uuidObj = %@", NSNull.null);
    RLMAssertCount(LinkToAllPrimitiveSets, 0, @"ANY link.boolObj != %@", @NO);
    RLMAssertCount(LinkToAllPrimitiveSets, 0, @"ANY link.intObj != %@", @2);
    RLMAssertCount(LinkToAllPrimitiveSets, 0, @"ANY link.floatObj != %@", @2.2f);
    RLMAssertCount(LinkToAllPrimitiveSets, 0, @"ANY link.doubleObj != %@", @2.2);
    RLMAssertCount(LinkToAllPrimitiveSets, 0, @"ANY link.stringObj != %@", @"a");
    RLMAssertCount(LinkToAllPrimitiveSets, 0, @"ANY link.dataObj != %@", data(1));
    RLMAssertCount(LinkToAllPrimitiveSets, 0, @"ANY link.dateObj != %@", date(1));
    RLMAssertCount(LinkToAllPrimitiveSets, 0, @"ANY link.decimalObj != %@", decimal128(1));
    RLMAssertCount(LinkToAllPrimitiveSets, 0, @"ANY link.objectIdObj != %@", objectId(1));
    RLMAssertCount(LinkToAllPrimitiveSets, 0, @"ANY link.uuidObj != %@", uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"));
    RLMAssertCount(LinkToAllPrimitiveSets, 0, @"ANY link.anyBoolObj != %@", @NO);
    RLMAssertCount(LinkToAllPrimitiveSets, 0, @"ANY link.anyIntObj != %@", @2);
    RLMAssertCount(LinkToAllPrimitiveSets, 0, @"ANY link.anyFloatObj != %@", @2.2f);
    RLMAssertCount(LinkToAllPrimitiveSets, 0, @"ANY link.anyDoubleObj != %@", @2.2);
    RLMAssertCount(LinkToAllPrimitiveSets, 0, @"ANY link.anyStringObj != %@", @"a");
    RLMAssertCount(LinkToAllPrimitiveSets, 0, @"ANY link.anyDataObj != %@", data(1));
    RLMAssertCount(LinkToAllPrimitiveSets, 0, @"ANY link.anyDateObj != %@", date(1));
    RLMAssertCount(LinkToAllPrimitiveSets, 0, @"ANY link.anyDecimalObj != %@", decimal128(1));
    RLMAssertCount(LinkToAllPrimitiveSets, 0, @"ANY link.anyObjectIdObj != %@", objectId(1));
    RLMAssertCount(LinkToAllPrimitiveSets, 0, @"ANY link.anyUUIDObj != %@", uuid(@"00000000-0000-0000-0000-000000000000"));
    RLMAssertCount(LinkToAllOptionalPrimitiveSets, 0, @"ANY link.boolObj != %@", NSNull.null);
    RLMAssertCount(LinkToAllOptionalPrimitiveSets, 0, @"ANY link.intObj != %@", NSNull.null);
    RLMAssertCount(LinkToAllOptionalPrimitiveSets, 0, @"ANY link.floatObj != %@", NSNull.null);
    RLMAssertCount(LinkToAllOptionalPrimitiveSets, 0, @"ANY link.doubleObj != %@", NSNull.null);
    RLMAssertCount(LinkToAllOptionalPrimitiveSets, 0, @"ANY link.stringObj != %@", NSNull.null);
    RLMAssertCount(LinkToAllOptionalPrimitiveSets, 0, @"ANY link.dataObj != %@", NSNull.null);
    RLMAssertCount(LinkToAllOptionalPrimitiveSets, 0, @"ANY link.dateObj != %@", NSNull.null);
    RLMAssertCount(LinkToAllOptionalPrimitiveSets, 0, @"ANY link.decimalObj != %@", NSNull.null);
    RLMAssertCount(LinkToAllOptionalPrimitiveSets, 0, @"ANY link.objectIdObj != %@", NSNull.null);
    RLMAssertCount(LinkToAllOptionalPrimitiveSets, 0, @"ANY link.uuidObj != %@", NSNull.null);
    RLMAssertCount(LinkToAllPrimitiveSets, 0, @"ANY link.intObj > %@", @2);
    RLMAssertCount(LinkToAllPrimitiveSets, 0, @"ANY link.floatObj > %@", @2.2f);
    RLMAssertCount(LinkToAllPrimitiveSets, 0, @"ANY link.doubleObj > %@", @2.2);
    RLMAssertCount(LinkToAllPrimitiveSets, 0, @"ANY link.dateObj > %@", date(1));
    RLMAssertCount(LinkToAllPrimitiveSets, 0, @"ANY link.decimalObj > %@", decimal128(1));
    RLMAssertCount(LinkToAllPrimitiveSets, 0, @"ANY link.anyIntObj > %@", @2);
    RLMAssertCount(LinkToAllPrimitiveSets, 0, @"ANY link.anyFloatObj > %@", @2.2f);
    RLMAssertCount(LinkToAllPrimitiveSets, 0, @"ANY link.anyDoubleObj > %@", @2.2);
    RLMAssertCount(LinkToAllPrimitiveSets, 0, @"ANY link.anyDateObj > %@", date(1));
    RLMAssertCount(LinkToAllPrimitiveSets, 0, @"ANY link.anyDecimalObj > %@", decimal128(1));
    RLMAssertCount(LinkToAllOptionalPrimitiveSets, 0, @"ANY link.intObj > %@", NSNull.null);
    RLMAssertCount(LinkToAllOptionalPrimitiveSets, 0, @"ANY link.floatObj > %@", NSNull.null);
    RLMAssertCount(LinkToAllOptionalPrimitiveSets, 0, @"ANY link.doubleObj > %@", NSNull.null);
    RLMAssertCount(LinkToAllOptionalPrimitiveSets, 0, @"ANY link.dateObj > %@", NSNull.null);
    RLMAssertCount(LinkToAllOptionalPrimitiveSets, 0, @"ANY link.decimalObj > %@", NSNull.null);
    RLMAssertCount(LinkToAllPrimitiveSets, 0, @"ANY link.intObj >= %@", @2);
    RLMAssertCount(LinkToAllPrimitiveSets, 0, @"ANY link.floatObj >= %@", @2.2f);
    RLMAssertCount(LinkToAllPrimitiveSets, 0, @"ANY link.doubleObj >= %@", @2.2);
    RLMAssertCount(LinkToAllPrimitiveSets, 0, @"ANY link.dateObj >= %@", date(1));
    RLMAssertCount(LinkToAllPrimitiveSets, 0, @"ANY link.decimalObj >= %@", decimal128(1));
    RLMAssertCount(LinkToAllPrimitiveSets, 0, @"ANY link.anyIntObj >= %@", @2);
    RLMAssertCount(LinkToAllPrimitiveSets, 0, @"ANY link.anyFloatObj >= %@", @2.2f);
    RLMAssertCount(LinkToAllPrimitiveSets, 0, @"ANY link.anyDoubleObj >= %@", @2.2);
    RLMAssertCount(LinkToAllPrimitiveSets, 0, @"ANY link.anyDateObj >= %@", date(1));
    RLMAssertCount(LinkToAllPrimitiveSets, 0, @"ANY link.anyDecimalObj >= %@", decimal128(1));
    RLMAssertCount(LinkToAllOptionalPrimitiveSets, 0, @"ANY link.intObj >= %@", NSNull.null);
    RLMAssertCount(LinkToAllOptionalPrimitiveSets, 0, @"ANY link.floatObj >= %@", NSNull.null);
    RLMAssertCount(LinkToAllOptionalPrimitiveSets, 0, @"ANY link.doubleObj >= %@", NSNull.null);
    RLMAssertCount(LinkToAllOptionalPrimitiveSets, 0, @"ANY link.dateObj >= %@", NSNull.null);
    RLMAssertCount(LinkToAllOptionalPrimitiveSets, 0, @"ANY link.decimalObj >= %@", NSNull.null);
    RLMAssertCount(LinkToAllPrimitiveSets, 0, @"ANY link.intObj < %@", @2);
    RLMAssertCount(LinkToAllPrimitiveSets, 0, @"ANY link.floatObj < %@", @2.2f);
    RLMAssertCount(LinkToAllPrimitiveSets, 0, @"ANY link.doubleObj < %@", @2.2);
    RLMAssertCount(LinkToAllPrimitiveSets, 0, @"ANY link.dateObj < %@", date(1));
    RLMAssertCount(LinkToAllPrimitiveSets, 0, @"ANY link.decimalObj < %@", decimal128(1));
    RLMAssertCount(LinkToAllPrimitiveSets, 0, @"ANY link.anyIntObj < %@", @2);
    RLMAssertCount(LinkToAllPrimitiveSets, 0, @"ANY link.anyFloatObj < %@", @2.2f);
    RLMAssertCount(LinkToAllPrimitiveSets, 0, @"ANY link.anyDoubleObj < %@", @2.2);
    RLMAssertCount(LinkToAllPrimitiveSets, 0, @"ANY link.anyDateObj < %@", date(1));
    RLMAssertCount(LinkToAllPrimitiveSets, 0, @"ANY link.anyDecimalObj < %@", decimal128(1));
    RLMAssertCount(LinkToAllOptionalPrimitiveSets, 0, @"ANY link.intObj < %@", NSNull.null);
    RLMAssertCount(LinkToAllOptionalPrimitiveSets, 0, @"ANY link.floatObj < %@", NSNull.null);
    RLMAssertCount(LinkToAllOptionalPrimitiveSets, 0, @"ANY link.doubleObj < %@", NSNull.null);
    RLMAssertCount(LinkToAllOptionalPrimitiveSets, 0, @"ANY link.dateObj < %@", NSNull.null);
    RLMAssertCount(LinkToAllOptionalPrimitiveSets, 0, @"ANY link.decimalObj < %@", NSNull.null);
    RLMAssertCount(LinkToAllPrimitiveSets, 0, @"ANY link.intObj <= %@", @2);
    RLMAssertCount(LinkToAllPrimitiveSets, 0, @"ANY link.floatObj <= %@", @2.2f);
    RLMAssertCount(LinkToAllPrimitiveSets, 0, @"ANY link.doubleObj <= %@", @2.2);
    RLMAssertCount(LinkToAllPrimitiveSets, 0, @"ANY link.dateObj <= %@", date(1));
    RLMAssertCount(LinkToAllPrimitiveSets, 0, @"ANY link.decimalObj <= %@", decimal128(1));
    RLMAssertCount(LinkToAllPrimitiveSets, 0, @"ANY link.anyIntObj <= %@", @2);
    RLMAssertCount(LinkToAllPrimitiveSets, 0, @"ANY link.anyFloatObj <= %@", @2.2f);
    RLMAssertCount(LinkToAllPrimitiveSets, 0, @"ANY link.anyDoubleObj <= %@", @2.2);
    RLMAssertCount(LinkToAllPrimitiveSets, 0, @"ANY link.anyDateObj <= %@", date(1));
    RLMAssertCount(LinkToAllPrimitiveSets, 0, @"ANY link.anyDecimalObj <= %@", decimal128(1));
    RLMAssertCount(LinkToAllOptionalPrimitiveSets, 0, @"ANY link.intObj <= %@", NSNull.null);
    RLMAssertCount(LinkToAllOptionalPrimitiveSets, 0, @"ANY link.floatObj <= %@", NSNull.null);
    RLMAssertCount(LinkToAllOptionalPrimitiveSets, 0, @"ANY link.doubleObj <= %@", NSNull.null);
    RLMAssertCount(LinkToAllOptionalPrimitiveSets, 0, @"ANY link.dateObj <= %@", NSNull.null);
    RLMAssertCount(LinkToAllOptionalPrimitiveSets, 0, @"ANY link.decimalObj <= %@", NSNull.null);

    [self createObjectWithValueIndex:1];

    RLMAssertCount(LinkToAllPrimitiveSets, 1, @"ANY link.boolObj = %@", @YES);
    RLMAssertCount(LinkToAllPrimitiveSets, 1, @"ANY link.intObj = %@", @3);
    RLMAssertCount(LinkToAllPrimitiveSets, 1, @"ANY link.floatObj = %@", @3.3f);
    RLMAssertCount(LinkToAllPrimitiveSets, 1, @"ANY link.doubleObj = %@", @3.3);
    RLMAssertCount(LinkToAllPrimitiveSets, 1, @"ANY link.stringObj = %@", @"bc");
    RLMAssertCount(LinkToAllPrimitiveSets, 1, @"ANY link.dataObj = %@", data(2));
    RLMAssertCount(LinkToAllPrimitiveSets, 1, @"ANY link.dateObj = %@", date(2));
    RLMAssertCount(LinkToAllPrimitiveSets, 1, @"ANY link.decimalObj = %@", decimal128(2));
    RLMAssertCount(LinkToAllPrimitiveSets, 1, @"ANY link.objectIdObj = %@", objectId(2));
    RLMAssertCount(LinkToAllPrimitiveSets, 1, @"ANY link.uuidObj = %@", uuid(@"00000000-0000-0000-0000-000000000000"));
    RLMAssertCount(LinkToAllPrimitiveSets, 1, @"ANY link.anyBoolObj = %@", @YES);
    RLMAssertCount(LinkToAllPrimitiveSets, 1, @"ANY link.anyIntObj = %@", @3);
    RLMAssertCount(LinkToAllPrimitiveSets, 1, @"ANY link.anyFloatObj = %@", @3.3f);
    RLMAssertCount(LinkToAllPrimitiveSets, 1, @"ANY link.anyDoubleObj = %@", @3.3);
    RLMAssertCount(LinkToAllPrimitiveSets, 1, @"ANY link.anyStringObj = %@", @"b");
    RLMAssertCount(LinkToAllPrimitiveSets, 1, @"ANY link.anyDataObj = %@", data(2));
    RLMAssertCount(LinkToAllPrimitiveSets, 1, @"ANY link.anyDateObj = %@", date(2));
    RLMAssertCount(LinkToAllPrimitiveSets, 1, @"ANY link.anyDecimalObj = %@", decimal128(2));
    RLMAssertCount(LinkToAllPrimitiveSets, 1, @"ANY link.anyObjectIdObj = %@", objectId(2));
    RLMAssertCount(LinkToAllPrimitiveSets, 1, @"ANY link.anyUUIDObj = %@", uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"));
    RLMAssertCount(LinkToAllOptionalPrimitiveSets, 1, @"ANY link.boolObj = %@", @NO);
    RLMAssertCount(LinkToAllOptionalPrimitiveSets, 1, @"ANY link.intObj = %@", @2);
    RLMAssertCount(LinkToAllOptionalPrimitiveSets, 1, @"ANY link.floatObj = %@", @2.2f);
    RLMAssertCount(LinkToAllOptionalPrimitiveSets, 1, @"ANY link.doubleObj = %@", @2.2);
    RLMAssertCount(LinkToAllOptionalPrimitiveSets, 1, @"ANY link.stringObj = %@", @"a");
    RLMAssertCount(LinkToAllOptionalPrimitiveSets, 1, @"ANY link.dataObj = %@", data(1));
    RLMAssertCount(LinkToAllOptionalPrimitiveSets, 1, @"ANY link.dateObj = %@", date(1));
    RLMAssertCount(LinkToAllOptionalPrimitiveSets, 1, @"ANY link.decimalObj = %@", decimal128(1));
    RLMAssertCount(LinkToAllOptionalPrimitiveSets, 1, @"ANY link.objectIdObj = %@", objectId(1));
    RLMAssertCount(LinkToAllOptionalPrimitiveSets, 1, @"ANY link.uuidObj = %@", uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"));
    RLMAssertCount(LinkToAllPrimitiveSets, 1, @"ANY link.boolObj != %@", @NO);
    RLMAssertCount(LinkToAllPrimitiveSets, 1, @"ANY link.intObj != %@", @2);
    RLMAssertCount(LinkToAllPrimitiveSets, 1, @"ANY link.floatObj != %@", @2.2f);
    RLMAssertCount(LinkToAllPrimitiveSets, 1, @"ANY link.doubleObj != %@", @2.2);
    RLMAssertCount(LinkToAllPrimitiveSets, 1, @"ANY link.stringObj != %@", @"a");
    RLMAssertCount(LinkToAllPrimitiveSets, 1, @"ANY link.dataObj != %@", data(1));
    RLMAssertCount(LinkToAllPrimitiveSets, 1, @"ANY link.dateObj != %@", date(1));
    RLMAssertCount(LinkToAllPrimitiveSets, 1, @"ANY link.decimalObj != %@", decimal128(1));
    RLMAssertCount(LinkToAllPrimitiveSets, 1, @"ANY link.objectIdObj != %@", objectId(1));
    RLMAssertCount(LinkToAllPrimitiveSets, 1, @"ANY link.uuidObj != %@", uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"));
    RLMAssertCount(LinkToAllPrimitiveSets, 1, @"ANY link.anyBoolObj != %@", @NO);
    RLMAssertCount(LinkToAllPrimitiveSets, 1, @"ANY link.anyIntObj != %@", @2);
    RLMAssertCount(LinkToAllPrimitiveSets, 1, @"ANY link.anyFloatObj != %@", @2.2f);
    RLMAssertCount(LinkToAllPrimitiveSets, 1, @"ANY link.anyDoubleObj != %@", @2.2);
    RLMAssertCount(LinkToAllPrimitiveSets, 1, @"ANY link.anyStringObj != %@", @"a");
    RLMAssertCount(LinkToAllPrimitiveSets, 1, @"ANY link.anyDataObj != %@", data(1));
    RLMAssertCount(LinkToAllPrimitiveSets, 1, @"ANY link.anyDateObj != %@", date(1));
    RLMAssertCount(LinkToAllPrimitiveSets, 1, @"ANY link.anyDecimalObj != %@", decimal128(1));
    RLMAssertCount(LinkToAllPrimitiveSets, 1, @"ANY link.anyObjectIdObj != %@", objectId(1));
    RLMAssertCount(LinkToAllPrimitiveSets, 1, @"ANY link.anyUUIDObj != %@", uuid(@"00000000-0000-0000-0000-000000000000"));
    RLMAssertCount(LinkToAllOptionalPrimitiveSets, 1, @"ANY link.boolObj != %@", NSNull.null);
    RLMAssertCount(LinkToAllOptionalPrimitiveSets, 1, @"ANY link.intObj != %@", NSNull.null);
    RLMAssertCount(LinkToAllOptionalPrimitiveSets, 1, @"ANY link.floatObj != %@", NSNull.null);
    RLMAssertCount(LinkToAllOptionalPrimitiveSets, 1, @"ANY link.doubleObj != %@", NSNull.null);
    RLMAssertCount(LinkToAllOptionalPrimitiveSets, 1, @"ANY link.stringObj != %@", NSNull.null);
    RLMAssertCount(LinkToAllOptionalPrimitiveSets, 1, @"ANY link.dataObj != %@", NSNull.null);
    RLMAssertCount(LinkToAllOptionalPrimitiveSets, 1, @"ANY link.dateObj != %@", NSNull.null);
    RLMAssertCount(LinkToAllOptionalPrimitiveSets, 1, @"ANY link.decimalObj != %@", NSNull.null);
    RLMAssertCount(LinkToAllOptionalPrimitiveSets, 1, @"ANY link.objectIdObj != %@", NSNull.null);
    RLMAssertCount(LinkToAllOptionalPrimitiveSets, 1, @"ANY link.uuidObj != %@", NSNull.null);
    RLMAssertCount(LinkToAllPrimitiveSets, 1, @"ANY link.intObj > %@", @2);
    RLMAssertCount(LinkToAllPrimitiveSets, 1, @"ANY link.floatObj > %@", @2.2f);
    RLMAssertCount(LinkToAllPrimitiveSets, 1, @"ANY link.doubleObj > %@", @2.2);
    RLMAssertCount(LinkToAllPrimitiveSets, 1, @"ANY link.dateObj > %@", date(1));
    RLMAssertCount(LinkToAllPrimitiveSets, 1, @"ANY link.decimalObj > %@", decimal128(1));
    RLMAssertCount(LinkToAllPrimitiveSets, 1, @"ANY link.anyIntObj > %@", @2);
    RLMAssertCount(LinkToAllPrimitiveSets, 1, @"ANY link.anyFloatObj > %@", @2.2f);
    RLMAssertCount(LinkToAllPrimitiveSets, 1, @"ANY link.anyDoubleObj > %@", @2.2);
    RLMAssertCount(LinkToAllPrimitiveSets, 1, @"ANY link.anyDateObj > %@", date(1));
    RLMAssertCount(LinkToAllPrimitiveSets, 1, @"ANY link.anyDecimalObj > %@", decimal128(1));
    RLMAssertCount(LinkToAllOptionalPrimitiveSets, 0, @"ANY link.intObj > %@", @2);
    RLMAssertCount(LinkToAllOptionalPrimitiveSets, 0, @"ANY link.floatObj > %@", @2.2f);
    RLMAssertCount(LinkToAllOptionalPrimitiveSets, 0, @"ANY link.doubleObj > %@", @2.2);
    RLMAssertCount(LinkToAllOptionalPrimitiveSets, 0, @"ANY link.dateObj > %@", date(1));
    RLMAssertCount(LinkToAllOptionalPrimitiveSets, 0, @"ANY link.decimalObj > %@", decimal128(1));

    RLMAssertCount(LinkToAllPrimitiveSets, 1, @"ANY link.intObj >= %@", @2);
    RLMAssertCount(LinkToAllPrimitiveSets, 1, @"ANY link.floatObj >= %@", @2.2f);
    RLMAssertCount(LinkToAllPrimitiveSets, 1, @"ANY link.doubleObj >= %@", @2.2);
    RLMAssertCount(LinkToAllPrimitiveSets, 1, @"ANY link.dateObj >= %@", date(1));
    RLMAssertCount(LinkToAllPrimitiveSets, 1, @"ANY link.decimalObj >= %@", decimal128(1));
    RLMAssertCount(LinkToAllPrimitiveSets, 1, @"ANY link.anyIntObj >= %@", @2);
    RLMAssertCount(LinkToAllPrimitiveSets, 1, @"ANY link.anyFloatObj >= %@", @2.2f);
    RLMAssertCount(LinkToAllPrimitiveSets, 1, @"ANY link.anyDoubleObj >= %@", @2.2);
    RLMAssertCount(LinkToAllPrimitiveSets, 1, @"ANY link.anyDateObj >= %@", date(1));
    RLMAssertCount(LinkToAllPrimitiveSets, 1, @"ANY link.anyDecimalObj >= %@", decimal128(1));
    RLMAssertCount(LinkToAllOptionalPrimitiveSets, 1, @"ANY link.intObj >= %@", @2);
    RLMAssertCount(LinkToAllOptionalPrimitiveSets, 1, @"ANY link.floatObj >= %@", @2.2f);
    RLMAssertCount(LinkToAllOptionalPrimitiveSets, 1, @"ANY link.doubleObj >= %@", @2.2);
    RLMAssertCount(LinkToAllOptionalPrimitiveSets, 1, @"ANY link.dateObj >= %@", date(1));
    RLMAssertCount(LinkToAllOptionalPrimitiveSets, 1, @"ANY link.decimalObj >= %@", decimal128(1));

    RLMAssertCount(LinkToAllPrimitiveSets, 0, @"ANY link.intObj < %@", @2);
    RLMAssertCount(LinkToAllPrimitiveSets, 0, @"ANY link.floatObj < %@", @2.2f);
    RLMAssertCount(LinkToAllPrimitiveSets, 0, @"ANY link.doubleObj < %@", @2.2);
    RLMAssertCount(LinkToAllPrimitiveSets, 0, @"ANY link.dateObj < %@", date(1));
    RLMAssertCount(LinkToAllPrimitiveSets, 0, @"ANY link.decimalObj < %@", decimal128(1));
    RLMAssertCount(LinkToAllPrimitiveSets, 0, @"ANY link.anyIntObj < %@", @2);
    RLMAssertCount(LinkToAllPrimitiveSets, 0, @"ANY link.anyFloatObj < %@", @2.2f);
    RLMAssertCount(LinkToAllPrimitiveSets, 0, @"ANY link.anyDoubleObj < %@", @2.2);
    RLMAssertCount(LinkToAllPrimitiveSets, 0, @"ANY link.anyDateObj < %@", date(1));
    RLMAssertCount(LinkToAllPrimitiveSets, 0, @"ANY link.anyDecimalObj < %@", decimal128(1));
    RLMAssertCount(LinkToAllOptionalPrimitiveSets, 0, @"ANY link.intObj < %@", NSNull.null);
    RLMAssertCount(LinkToAllOptionalPrimitiveSets, 0, @"ANY link.floatObj < %@", NSNull.null);
    RLMAssertCount(LinkToAllOptionalPrimitiveSets, 0, @"ANY link.doubleObj < %@", NSNull.null);
    RLMAssertCount(LinkToAllOptionalPrimitiveSets, 0, @"ANY link.dateObj < %@", NSNull.null);
    RLMAssertCount(LinkToAllOptionalPrimitiveSets, 0, @"ANY link.decimalObj < %@", NSNull.null);
    RLMAssertCount(LinkToAllPrimitiveSets, 1, @"ANY link.intObj < %@", @4);
    RLMAssertCount(LinkToAllPrimitiveSets, 1, @"ANY link.floatObj < %@", @4.4f);
    RLMAssertCount(LinkToAllPrimitiveSets, 1, @"ANY link.doubleObj < %@", @4.4);
    RLMAssertCount(LinkToAllPrimitiveSets, 1, @"ANY link.dateObj < %@", date(3));
    RLMAssertCount(LinkToAllPrimitiveSets, 1, @"ANY link.decimalObj < %@", decimal128(3));
    RLMAssertCount(LinkToAllPrimitiveSets, 1, @"ANY link.anyIntObj < %@", @4);
    RLMAssertCount(LinkToAllPrimitiveSets, 1, @"ANY link.anyFloatObj < %@", @4.4f);
    RLMAssertCount(LinkToAllPrimitiveSets, 1, @"ANY link.anyDoubleObj < %@", @4.4);
    RLMAssertCount(LinkToAllPrimitiveSets, 1, @"ANY link.anyDateObj < %@", date(3));
    RLMAssertCount(LinkToAllPrimitiveSets, 1, @"ANY link.anyDecimalObj < %@", decimal128(3));
    RLMAssertCount(LinkToAllOptionalPrimitiveSets, 1, @"ANY link.intObj < %@", @3);
    RLMAssertCount(LinkToAllOptionalPrimitiveSets, 1, @"ANY link.floatObj < %@", @3.3f);
    RLMAssertCount(LinkToAllOptionalPrimitiveSets, 1, @"ANY link.doubleObj < %@", @3.3);
    RLMAssertCount(LinkToAllOptionalPrimitiveSets, 1, @"ANY link.dateObj < %@", date(2));
    RLMAssertCount(LinkToAllOptionalPrimitiveSets, 1, @"ANY link.decimalObj < %@", decimal128(2));

    RLMAssertCount(LinkToAllPrimitiveSets, 1, @"ANY link.intObj <= %@", @3);
    RLMAssertCount(LinkToAllPrimitiveSets, 1, @"ANY link.floatObj <= %@", @3.3f);
    RLMAssertCount(LinkToAllPrimitiveSets, 1, @"ANY link.doubleObj <= %@", @3.3);
    RLMAssertCount(LinkToAllPrimitiveSets, 1, @"ANY link.dateObj <= %@", date(2));
    RLMAssertCount(LinkToAllPrimitiveSets, 1, @"ANY link.decimalObj <= %@", decimal128(2));
    RLMAssertCount(LinkToAllPrimitiveSets, 1, @"ANY link.anyIntObj <= %@", @3);
    RLMAssertCount(LinkToAllPrimitiveSets, 1, @"ANY link.anyFloatObj <= %@", @3.3f);
    RLMAssertCount(LinkToAllPrimitiveSets, 1, @"ANY link.anyDoubleObj <= %@", @3.3);
    RLMAssertCount(LinkToAllPrimitiveSets, 1, @"ANY link.anyDateObj <= %@", date(2));
    RLMAssertCount(LinkToAllPrimitiveSets, 1, @"ANY link.anyDecimalObj <= %@", decimal128(2));
    RLMAssertCount(LinkToAllOptionalPrimitiveSets, 1, @"ANY link.intObj <= %@", @2);
    RLMAssertCount(LinkToAllOptionalPrimitiveSets, 1, @"ANY link.floatObj <= %@", @2.2f);
    RLMAssertCount(LinkToAllOptionalPrimitiveSets, 1, @"ANY link.doubleObj <= %@", @2.2);
    RLMAssertCount(LinkToAllOptionalPrimitiveSets, 1, @"ANY link.dateObj <= %@", date(1));
    RLMAssertCount(LinkToAllOptionalPrimitiveSets, 1, @"ANY link.decimalObj <= %@", decimal128(1));

    RLMAssertThrowsWithReason(([LinkToAllPrimitiveSets objectsInRealm:realm where:@"ANY link.boolObj > %@", @NO]), 
                              @"Operator '>' not supported for type 'bool'");
    RLMAssertThrowsWithReason(([LinkToAllPrimitiveSets objectsInRealm:realm where:@"ANY link.stringObj > %@", @"a"]), 
                              @"Operator '>' not supported for type 'string'");
    RLMAssertThrowsWithReason(([LinkToAllPrimitiveSets objectsInRealm:realm where:@"ANY link.dataObj > %@", data(1)]), 
                              @"Operator '>' not supported for type 'data'");
    RLMAssertThrowsWithReason(([LinkToAllPrimitiveSets objectsInRealm:realm where:@"ANY link.objectIdObj > %@", objectId(1)]), 
                              @"Operator '>' not supported for type 'object id'");
    RLMAssertThrowsWithReason(([LinkToAllPrimitiveSets objectsInRealm:realm where:@"ANY link.uuidObj > %@", uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")]), 
                              @"Operator '>' not supported for type 'uuid'");
    RLMAssertThrowsWithReason(([LinkToAllOptionalPrimitiveSets objectsInRealm:realm where:@"ANY link.boolObj > %@", NSNull.null]), 
                              @"Operator '>' not supported for type 'bool'");
    RLMAssertThrowsWithReason(([LinkToAllOptionalPrimitiveSets objectsInRealm:realm where:@"ANY link.stringObj > %@", NSNull.null]), 
                              @"Operator '>' not supported for type 'string'");
    RLMAssertThrowsWithReason(([LinkToAllOptionalPrimitiveSets objectsInRealm:realm where:@"ANY link.dataObj > %@", NSNull.null]), 
                              @"Operator '>' not supported for type 'data'");
    RLMAssertThrowsWithReason(([LinkToAllOptionalPrimitiveSets objectsInRealm:realm where:@"ANY link.objectIdObj > %@", NSNull.null]), 
                              @"Operator '>' not supported for type 'object id'");
    RLMAssertThrowsWithReason(([LinkToAllOptionalPrimitiveSets objectsInRealm:realm where:@"ANY link.uuidObj > %@", NSNull.null]), 
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
        RLMAssertCount(AllPrimitiveSets, count, query, value);
        RLMAssertCount(AllPrimitiveSets, count, query, value);
        RLMAssertCount(AllOptionalPrimitiveSets, count, query, value);
        query = [NSString stringWithFormat:@"ANY link.stringObj %@ %%@", operator];
        RLMAssertCount(LinkToAllPrimitiveSets, count, query, value);
        RLMAssertCount(LinkToAllPrimitiveSets, count, query, value);
        RLMAssertCount(LinkToAllOptionalPrimitiveSets, count, query, value);

        query = [NSString stringWithFormat:@"ANY dataObj %@ %%@", operator];
        RLMAssertCount(AllPrimitiveSets, count, query, data);
        RLMAssertCount(AllPrimitiveSets, count, query, data);
        RLMAssertCount(AllOptionalPrimitiveSets, count, query, data);
        query = [NSString stringWithFormat:@"ANY link.dataObj %@ %%@", operator];
        RLMAssertCount(LinkToAllPrimitiveSets, count, query, data);
        RLMAssertCount(LinkToAllPrimitiveSets, count, query, data);
        RLMAssertCount(LinkToAllOptionalPrimitiveSets, count, query, data);
    };
    void (^testNull)(NSString *, NSUInteger) = ^(NSString *operator, NSUInteger count) {
        NSString *query = [NSString stringWithFormat:@"ANY stringObj %@ nil", operator];
        RLMAssertThrowsWithReason([AllPrimitiveSets objectsInRealm:realm where:query],
                                  @"Cannot compare value '(null)' of type '(null)' to property 'stringObj' of type 'string'");
        RLMAssertCount(AllOptionalPrimitiveSets, count, query, NSNull.null);
        query = [NSString stringWithFormat:@"ANY link.stringObj %@ nil", operator];
        RLMAssertThrowsWithReason([LinkToAllPrimitiveSets objectsInRealm:realm where:query],
                                  @"Cannot compare value '(null)' of type '(null)' to property 'stringObj' of type 'string'");
        RLMAssertCount(LinkToAllOptionalPrimitiveSets, count, query, NSNull.null);

        query = [NSString stringWithFormat:@"ANY dataObj %@ nil", operator];
        RLMAssertThrowsWithReason([AllPrimitiveSets objectsInRealm:realm where:query],
                                  @"Cannot compare value '(null)' of type '(null)' to property 'dataObj' of type 'data'");
        RLMAssertCount(AllOptionalPrimitiveSets, count, query, NSNull.null);

        query = [NSString stringWithFormat:@"ANY link.dataObj %@ nil", operator];
        RLMAssertThrowsWithReason([LinkToAllPrimitiveSets objectsInRealm:realm where:query],
                                  @"Cannot compare value '(null)' of type '(null)' to property 'dataObj' of type 'data'");
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
