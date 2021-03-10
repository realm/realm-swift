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
        unmanaged.anyObjA,
        unmanaged.anyObjB,
        unmanaged.anyObjC,
        unmanaged.anyObjD,
        unmanaged.anyObjE,
        unmanaged.anyObjF,
        unmanaged.anyObjG,
        unmanaged.anyObjH,
        unmanaged.anyObjI,
        unmanaged.anyObjJ,
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
        managed.anyObjA,
        managed.anyObjB,
        managed.anyObjC,
        managed.anyObjD,
        managed.anyObjE,
        managed.anyObjF,
        managed.anyObjG,
        managed.anyObjH,
        managed.anyObjI,
        managed.anyObjJ,
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
    [unmanaged.anyObjA addObjects:@[@NO, @YES]];
    [unmanaged.anyObjB addObjects:@[@2, @3]];
    [unmanaged.anyObjC addObjects:@[@2.2f, @3.3f]];
    [unmanaged.anyObjD addObjects:@[@2.2, @3.3]];
    [unmanaged.anyObjE addObjects:@[@"a", @"b"]];
    [unmanaged.anyObjF addObjects:@[data(1), data(2)]];
    [unmanaged.anyObjG addObjects:@[date(1), date(2)]];
    [unmanaged.anyObjH addObjects:@[decimal128(1), decimal128(2)]];
    [unmanaged.anyObjI addObjects:@[objectId(1), objectId(2)]];
    [unmanaged.anyObjJ addObjects:@[uuid(@"00000000-0000-0000-0000-000000000000"), uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")]];
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
    [managed.anyObjA addObjects:@[@NO, @YES]];
    [managed.anyObjB addObjects:@[@2, @3]];
    [managed.anyObjC addObjects:@[@2.2f, @3.3f]];
    [managed.anyObjD addObjects:@[@2.2, @3.3]];
    [managed.anyObjE addObjects:@[@"a", @"b"]];
    [managed.anyObjF addObjects:@[data(1), data(2)]];
    [managed.anyObjG addObjects:@[date(1), date(2)]];
    [managed.anyObjH addObjects:@[decimal128(1), decimal128(2)]];
    [managed.anyObjI addObjects:@[objectId(1), objectId(2)]];
    [managed.anyObjJ addObjects:@[uuid(@"00000000-0000-0000-0000-000000000000"), uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")]];
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
    XCTAssertFalse([unmanaged.anyObjA containsObject:@NO]);
    XCTAssertFalse([unmanaged.anyObjB containsObject:@2]);
    XCTAssertFalse([unmanaged.anyObjC containsObject:@2.2f]);
    XCTAssertFalse([unmanaged.anyObjD containsObject:@2.2]);
    XCTAssertFalse([unmanaged.anyObjE containsObject:@"a"]);
    XCTAssertFalse([unmanaged.anyObjF containsObject:data(1)]);
    XCTAssertFalse([unmanaged.anyObjG containsObject:date(1)]);
    XCTAssertFalse([unmanaged.anyObjH containsObject:decimal128(1)]);
    XCTAssertFalse([unmanaged.anyObjI containsObject:objectId(1)]);
    XCTAssertFalse([unmanaged.anyObjJ containsObject:uuid(@"00000000-0000-0000-0000-000000000000")]);
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
    XCTAssertFalse([managed.anyObjA containsObject:@NO]);
    XCTAssertFalse([managed.anyObjB containsObject:@2]);
    XCTAssertFalse([managed.anyObjC containsObject:@2.2f]);
    XCTAssertFalse([managed.anyObjD containsObject:@2.2]);
    XCTAssertFalse([managed.anyObjE containsObject:@"a"]);
    XCTAssertFalse([managed.anyObjF containsObject:data(1)]);
    XCTAssertFalse([managed.anyObjG containsObject:date(1)]);
    XCTAssertFalse([managed.anyObjH containsObject:decimal128(1)]);
    XCTAssertFalse([managed.anyObjI containsObject:objectId(1)]);
    XCTAssertFalse([managed.anyObjJ containsObject:uuid(@"00000000-0000-0000-0000-000000000000")]);
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
    [unmanaged.anyObjA addObject:@NO];
    [unmanaged.anyObjB addObject:@2];
    [unmanaged.anyObjC addObject:@2.2f];
    [unmanaged.anyObjD addObject:@2.2];
    [unmanaged.anyObjE addObject:@"a"];
    [unmanaged.anyObjF addObject:data(1)];
    [unmanaged.anyObjG addObject:date(1)];
    [unmanaged.anyObjH addObject:decimal128(1)];
    [unmanaged.anyObjI addObject:objectId(1)];
    [unmanaged.anyObjJ addObject:uuid(@"00000000-0000-0000-0000-000000000000")];
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
    [managed.anyObjA addObject:@NO];
    [managed.anyObjB addObject:@2];
    [managed.anyObjC addObject:@2.2f];
    [managed.anyObjD addObject:@2.2];
    [managed.anyObjE addObject:@"a"];
    [managed.anyObjF addObject:data(1)];
    [managed.anyObjG addObject:date(1)];
    [managed.anyObjH addObject:decimal128(1)];
    [managed.anyObjI addObject:objectId(1)];
    [managed.anyObjJ addObject:uuid(@"00000000-0000-0000-0000-000000000000")];
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
    XCTAssertTrue([unmanaged.anyObjA containsObject:@NO]);
    XCTAssertTrue([unmanaged.anyObjB containsObject:@2]);
    XCTAssertTrue([unmanaged.anyObjC containsObject:@2.2f]);
    XCTAssertTrue([unmanaged.anyObjD containsObject:@2.2]);
    XCTAssertTrue([unmanaged.anyObjE containsObject:@"a"]);
    XCTAssertTrue([unmanaged.anyObjF containsObject:data(1)]);
    XCTAssertTrue([unmanaged.anyObjG containsObject:date(1)]);
    XCTAssertTrue([unmanaged.anyObjH containsObject:decimal128(1)]);
    XCTAssertTrue([unmanaged.anyObjI containsObject:objectId(1)]);
    XCTAssertTrue([unmanaged.anyObjJ containsObject:uuid(@"00000000-0000-0000-0000-000000000000")]);
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
    XCTAssertTrue([managed.anyObjA containsObject:@NO]);
    XCTAssertTrue([managed.anyObjB containsObject:@2]);
    XCTAssertTrue([managed.anyObjC containsObject:@2.2f]);
    XCTAssertTrue([managed.anyObjD containsObject:@2.2]);
    XCTAssertTrue([managed.anyObjE containsObject:@"a"]);
    XCTAssertTrue([managed.anyObjF containsObject:data(1)]);
    XCTAssertTrue([managed.anyObjG containsObject:date(1)]);
    XCTAssertTrue([managed.anyObjH containsObject:decimal128(1)]);
    XCTAssertTrue([managed.anyObjI containsObject:objectId(1)]);
    XCTAssertTrue([managed.anyObjJ containsObject:uuid(@"00000000-0000-0000-0000-000000000000")]);
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
    [unmanaged.anyObjA addObject:@NO];
    [unmanaged.anyObjB addObject:@2];
    [unmanaged.anyObjC addObject:@2.2f];
    [unmanaged.anyObjD addObject:@2.2];
    [unmanaged.anyObjE addObject:@"a"];
    [unmanaged.anyObjF addObject:data(1)];
    [unmanaged.anyObjG addObject:date(1)];
    [unmanaged.anyObjH addObject:decimal128(1)];
    [unmanaged.anyObjI addObject:objectId(1)];
    [unmanaged.anyObjJ addObject:uuid(@"00000000-0000-0000-0000-000000000000")];
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
    [managed.anyObjA addObject:@NO];
    [managed.anyObjB addObject:@2];
    [managed.anyObjC addObject:@2.2f];
    [managed.anyObjD addObject:@2.2];
    [managed.anyObjE addObject:@"a"];
    [managed.anyObjF addObject:data(1)];
    [managed.anyObjG addObject:date(1)];
    [managed.anyObjH addObject:decimal128(1)];
    [managed.anyObjI addObject:objectId(1)];
    [managed.anyObjJ addObject:uuid(@"00000000-0000-0000-0000-000000000000")];
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
    XCTAssertTrue([unmanaged.anyObjA containsObject:@NO]);
    XCTAssertTrue([unmanaged.anyObjB containsObject:@2]);
    XCTAssertTrue([unmanaged.anyObjC containsObject:@2.2f]);
    XCTAssertTrue([unmanaged.anyObjD containsObject:@2.2]);
    XCTAssertTrue([unmanaged.anyObjE containsObject:@"a"]);
    XCTAssertTrue([unmanaged.anyObjF containsObject:data(1)]);
    XCTAssertTrue([unmanaged.anyObjG containsObject:date(1)]);
    XCTAssertTrue([unmanaged.anyObjH containsObject:decimal128(1)]);
    XCTAssertTrue([unmanaged.anyObjI containsObject:objectId(1)]);
    XCTAssertTrue([unmanaged.anyObjJ containsObject:uuid(@"00000000-0000-0000-0000-000000000000")]);
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
    XCTAssertTrue([managed.anyObjA containsObject:@NO]);
    XCTAssertTrue([managed.anyObjB containsObject:@2]);
    XCTAssertTrue([managed.anyObjC containsObject:@2.2f]);
    XCTAssertTrue([managed.anyObjD containsObject:@2.2]);
    XCTAssertTrue([managed.anyObjE containsObject:@"a"]);
    XCTAssertTrue([managed.anyObjF containsObject:data(1)]);
    XCTAssertTrue([managed.anyObjG containsObject:date(1)]);
    XCTAssertTrue([managed.anyObjH containsObject:decimal128(1)]);
    XCTAssertTrue([managed.anyObjI containsObject:objectId(1)]);
    XCTAssertTrue([managed.anyObjJ containsObject:uuid(@"00000000-0000-0000-0000-000000000000")]);
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
    XCTAssertTrue([unmanaged.anyObjA containsObject:@NO]);
    XCTAssertTrue([unmanaged.anyObjB containsObject:@2]);
    XCTAssertTrue([unmanaged.anyObjC containsObject:@2.2f]);
    XCTAssertTrue([unmanaged.anyObjD containsObject:@2.2]);
    XCTAssertTrue([unmanaged.anyObjE containsObject:@"a"]);
    XCTAssertTrue([unmanaged.anyObjF containsObject:data(1)]);
    XCTAssertTrue([unmanaged.anyObjG containsObject:date(1)]);
    XCTAssertTrue([unmanaged.anyObjH containsObject:decimal128(1)]);
    XCTAssertTrue([unmanaged.anyObjI containsObject:objectId(1)]);
    XCTAssertTrue([unmanaged.anyObjJ containsObject:uuid(@"00000000-0000-0000-0000-000000000000")]);
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
    XCTAssertTrue([managed.anyObjA containsObject:@NO]);
    XCTAssertTrue([managed.anyObjB containsObject:@2]);
    XCTAssertTrue([managed.anyObjC containsObject:@2.2f]);
    XCTAssertTrue([managed.anyObjD containsObject:@2.2]);
    XCTAssertTrue([managed.anyObjE containsObject:@"a"]);
    XCTAssertTrue([managed.anyObjF containsObject:data(1)]);
    XCTAssertTrue([managed.anyObjG containsObject:date(1)]);
    XCTAssertTrue([managed.anyObjH containsObject:decimal128(1)]);
    XCTAssertTrue([managed.anyObjI containsObject:objectId(1)]);
    XCTAssertTrue([managed.anyObjJ containsObject:uuid(@"00000000-0000-0000-0000-000000000000")]);
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
    XCTAssertTrue([unmanaged.anyObjA containsObject:@YES]);
    XCTAssertTrue([unmanaged.anyObjB containsObject:@3]);
    XCTAssertTrue([unmanaged.anyObjC containsObject:@3.3f]);
    XCTAssertTrue([unmanaged.anyObjD containsObject:@3.3]);
    XCTAssertTrue([unmanaged.anyObjE containsObject:@"b"]);
    XCTAssertTrue([unmanaged.anyObjF containsObject:data(2)]);
    XCTAssertTrue([unmanaged.anyObjG containsObject:date(2)]);
    XCTAssertTrue([unmanaged.anyObjH containsObject:decimal128(2)]);
    XCTAssertTrue([unmanaged.anyObjI containsObject:objectId(2)]);
    XCTAssertTrue([unmanaged.anyObjJ containsObject:uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")]);
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
    XCTAssertTrue([managed.anyObjA containsObject:@YES]);
    XCTAssertTrue([managed.anyObjB containsObject:@3]);
    XCTAssertTrue([managed.anyObjC containsObject:@3.3f]);
    XCTAssertTrue([managed.anyObjD containsObject:@3.3]);
    XCTAssertTrue([managed.anyObjE containsObject:@"b"]);
    XCTAssertTrue([managed.anyObjF containsObject:data(2)]);
    XCTAssertTrue([managed.anyObjG containsObject:date(2)]);
    XCTAssertTrue([managed.anyObjH containsObject:decimal128(2)]);
    XCTAssertTrue([managed.anyObjI containsObject:objectId(2)]);
    XCTAssertTrue([managed.anyObjJ containsObject:uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")]);
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
    XCTAssertEqual(unmanaged.anyObjA.count, 2U);
    XCTAssertEqual(unmanaged.anyObjB.count, 2U);
    XCTAssertEqual(unmanaged.anyObjC.count, 2U);
    XCTAssertEqual(unmanaged.anyObjD.count, 2U);
    XCTAssertEqual(unmanaged.anyObjE.count, 2U);
    XCTAssertEqual(unmanaged.anyObjF.count, 2U);
    XCTAssertEqual(unmanaged.anyObjG.count, 2U);
    XCTAssertEqual(unmanaged.anyObjH.count, 2U);
    XCTAssertEqual(unmanaged.anyObjI.count, 2U);
    XCTAssertEqual(unmanaged.anyObjJ.count, 2U);
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
    XCTAssertEqual(managed.anyObjA.count, 2U);
    XCTAssertEqual(managed.anyObjB.count, 2U);
    XCTAssertEqual(managed.anyObjC.count, 2U);
    XCTAssertEqual(managed.anyObjD.count, 2U);
    XCTAssertEqual(managed.anyObjE.count, 2U);
    XCTAssertEqual(managed.anyObjF.count, 2U);
    XCTAssertEqual(managed.anyObjG.count, 2U);
    XCTAssertEqual(managed.anyObjH.count, 2U);
    XCTAssertEqual(managed.anyObjI.count, 2U);
    XCTAssertEqual(managed.anyObjJ.count, 2U);
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
    XCTAssertEqual(unmanaged.anyObjA.count, 1U);
    XCTAssertEqual(unmanaged.anyObjB.count, 1U);
    XCTAssertEqual(unmanaged.anyObjC.count, 1U);
    XCTAssertEqual(unmanaged.anyObjD.count, 1U);
    XCTAssertEqual(unmanaged.anyObjE.count, 1U);
    XCTAssertEqual(unmanaged.anyObjF.count, 1U);
    XCTAssertEqual(unmanaged.anyObjG.count, 1U);
    XCTAssertEqual(unmanaged.anyObjH.count, 1U);
    XCTAssertEqual(unmanaged.anyObjI.count, 1U);
    XCTAssertEqual(unmanaged.anyObjJ.count, 1U);
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
    XCTAssertEqual(managed.anyObjA.count, 1U);
    XCTAssertEqual(managed.anyObjB.count, 1U);
    XCTAssertEqual(managed.anyObjC.count, 1U);
    XCTAssertEqual(managed.anyObjD.count, 1U);
    XCTAssertEqual(managed.anyObjE.count, 1U);
    XCTAssertEqual(managed.anyObjF.count, 1U);
    XCTAssertEqual(managed.anyObjG.count, 1U);
    XCTAssertEqual(managed.anyObjH.count, 1U);
    XCTAssertEqual(managed.anyObjI.count, 1U);
    XCTAssertEqual(managed.anyObjJ.count, 1U);
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
    [managed.anyObjA addObjects:@[@NO, @YES, @NO, @YES]];
    [managed.anyObjB addObjects:@[@2, @3, @2, @3]];
    [managed.anyObjC addObjects:@[@2.2f, @3.3f, @2.2f, @3.3f]];
    [managed.anyObjD addObjects:@[@2.2, @3.3, @2.2, @3.3]];
    [managed.anyObjE addObjects:@[@"a", @"b", @"a", @"b"]];
    [managed.anyObjF addObjects:@[data(1), data(2), data(1), data(2)]];
    [managed.anyObjG addObjects:@[date(1), date(2), date(1), date(2)]];
    [managed.anyObjH addObjects:@[decimal128(1), decimal128(2), decimal128(1), decimal128(2)]];
    [managed.anyObjI addObjects:@[objectId(1), objectId(2), objectId(1), objectId(2)]];
    [managed.anyObjJ addObjects:@[uuid(@"00000000-0000-0000-0000-000000000000"), uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"), uuid(@"00000000-0000-0000-0000-000000000000"), uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")]];
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
    XCTAssertTrue([[managed.anyObjA sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:@YES] == 0U || 
                  [[managed.anyObjA sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:@YES] == 1U);
    XCTAssertTrue([[managed.anyObjB sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:@3] == 0U || 
                  [[managed.anyObjB sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:@3] == 1U);
    XCTAssertTrue([[managed.anyObjC sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:@3.3f] == 0U || 
                  [[managed.anyObjC sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:@3.3f] == 1U);
    XCTAssertTrue([[managed.anyObjD sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:@3.3] == 0U || 
                  [[managed.anyObjD sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:@3.3] == 1U);
    XCTAssertTrue([[managed.anyObjE sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:@"b"] == 0U || 
                  [[managed.anyObjE sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:@"b"] == 1U);
    XCTAssertTrue([[managed.anyObjF sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:data(2)] == 0U || 
                  [[managed.anyObjF sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:data(2)] == 1U);
    XCTAssertTrue([[managed.anyObjG sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:date(2)] == 0U || 
                  [[managed.anyObjG sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:date(2)] == 1U);
    XCTAssertTrue([[managed.anyObjH sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:decimal128(2)] == 0U || 
                  [[managed.anyObjH sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:decimal128(2)] == 1U);
    XCTAssertTrue([[managed.anyObjI sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:objectId(2)] == 0U || 
                  [[managed.anyObjI sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:objectId(2)] == 1U);
    XCTAssertTrue([[managed.anyObjJ sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")] == 0U || 
                  [[managed.anyObjJ sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")] == 1U);
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
    XCTAssertTrue([[managed.anyObjA sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:@NO] == 0U || 
                  [[managed.anyObjA sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:@NO] == 1U);
    XCTAssertTrue([[managed.anyObjB sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:@2] == 0U || 
                  [[managed.anyObjB sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:@2] == 1U);
    XCTAssertTrue([[managed.anyObjC sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:@2.2f] == 0U || 
                  [[managed.anyObjC sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:@2.2f] == 1U);
    XCTAssertTrue([[managed.anyObjD sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:@2.2] == 0U || 
                  [[managed.anyObjD sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:@2.2] == 1U);
    XCTAssertTrue([[managed.anyObjE sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:@"a"] == 0U || 
                  [[managed.anyObjE sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:@"a"] == 1U);
    XCTAssertTrue([[managed.anyObjF sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:data(1)] == 0U || 
                  [[managed.anyObjF sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:data(1)] == 1U);
    XCTAssertTrue([[managed.anyObjG sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:date(1)] == 0U || 
                  [[managed.anyObjG sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:date(1)] == 1U);
    XCTAssertTrue([[managed.anyObjH sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:decimal128(1)] == 0U || 
                  [[managed.anyObjH sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:decimal128(1)] == 1U);
    XCTAssertTrue([[managed.anyObjI sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:objectId(1)] == 0U || 
                  [[managed.anyObjI sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:objectId(1)] == 1U);
    XCTAssertTrue([[managed.anyObjJ sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:uuid(@"00000000-0000-0000-0000-000000000000")] == 0U || 
                  [[managed.anyObjJ sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:uuid(@"00000000-0000-0000-0000-000000000000")] == 1U);

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
    [managed.anyObjA addObjects:@[@NO, @NO, @YES]];
    [managed.anyObjB addObjects:@[@2, @2, @3]];
    [managed.anyObjC addObjects:@[@2.2f, @2.2f, @3.3f]];
    [managed.anyObjD addObjects:@[@2.2, @2.2, @3.3]];
    [managed.anyObjE addObjects:@[@"a", @"a", @"b"]];
    [managed.anyObjF addObjects:@[data(1), data(1), data(2)]];
    [managed.anyObjG addObjects:@[date(1), date(1), date(2)]];
    [managed.anyObjH addObjects:@[decimal128(1), decimal128(1), decimal128(2)]];
    [managed.anyObjI addObjects:@[objectId(1), objectId(1), objectId(2)]];
    [managed.anyObjJ addObjects:@[uuid(@"00000000-0000-0000-0000-000000000000"), uuid(@"00000000-0000-0000-0000-000000000000"), uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")]];
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
    XCTAssertTrue([[managed.anyObjA distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:@NO] == 0U || 
                  [[managed.anyObjA distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:@NO] == 1U);
    XCTAssertTrue([[managed.anyObjB distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:@2] == 0U || 
                  [[managed.anyObjB distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:@2] == 1U);
    XCTAssertTrue([[managed.anyObjC distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:@2.2f] == 0U || 
                  [[managed.anyObjC distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:@2.2f] == 1U);
    XCTAssertTrue([[managed.anyObjD distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:@2.2] == 0U || 
                  [[managed.anyObjD distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:@2.2] == 1U);
    XCTAssertTrue([[managed.anyObjE distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:@"a"] == 0U || 
                  [[managed.anyObjE distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:@"a"] == 1U);
    XCTAssertTrue([[managed.anyObjF distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:data(1)] == 0U || 
                  [[managed.anyObjF distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:data(1)] == 1U);
    XCTAssertTrue([[managed.anyObjG distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:date(1)] == 0U || 
                  [[managed.anyObjG distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:date(1)] == 1U);
    XCTAssertTrue([[managed.anyObjH distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:decimal128(1)] == 0U || 
                  [[managed.anyObjH distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:decimal128(1)] == 1U);
    XCTAssertTrue([[managed.anyObjI distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:objectId(1)] == 0U || 
                  [[managed.anyObjI distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:objectId(1)] == 1U);
    XCTAssertTrue([[managed.anyObjJ distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:uuid(@"00000000-0000-0000-0000-000000000000")] == 0U || 
                  [[managed.anyObjJ distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:uuid(@"00000000-0000-0000-0000-000000000000")] == 1U);
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
    XCTAssertTrue([[managed.anyObjA distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:@YES] == 0U || 
                  [[managed.anyObjA distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:@YES] == 1U);
    XCTAssertTrue([[managed.anyObjB distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:@3] == 0U || 
                  [[managed.anyObjB distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:@3] == 1U);
    XCTAssertTrue([[managed.anyObjC distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:@3.3f] == 0U || 
                  [[managed.anyObjC distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:@3.3f] == 1U);
    XCTAssertTrue([[managed.anyObjD distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:@3.3] == 0U || 
                  [[managed.anyObjD distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:@3.3] == 1U);
    XCTAssertTrue([[managed.anyObjE distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:@"b"] == 0U || 
                  [[managed.anyObjE distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:@"b"] == 1U);
    XCTAssertTrue([[managed.anyObjF distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:data(2)] == 0U || 
                  [[managed.anyObjF distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:data(2)] == 1U);
    XCTAssertTrue([[managed.anyObjG distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:date(2)] == 0U || 
                  [[managed.anyObjG distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:date(2)] == 1U);
    XCTAssertTrue([[managed.anyObjH distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:decimal128(2)] == 0U || 
                  [[managed.anyObjH distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:decimal128(2)] == 1U);
    XCTAssertTrue([[managed.anyObjI distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:objectId(2)] == 0U || 
                  [[managed.anyObjI distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:objectId(2)] == 1U);
    XCTAssertTrue([[managed.anyObjJ distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")] == 0U || 
                  [[managed.anyObjJ distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")] == 1U);

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
    RLMAssertThrowsWithReason([unmanaged.anyObjA sortedResultsUsingKeyPath:@"self" ascending:NO], 
                              @"This method may only be called on RLMSet instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.anyObjB sortedResultsUsingKeyPath:@"self" ascending:NO], 
                              @"This method may only be called on RLMSet instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.anyObjC sortedResultsUsingKeyPath:@"self" ascending:NO], 
                              @"This method may only be called on RLMSet instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.anyObjD sortedResultsUsingKeyPath:@"self" ascending:NO], 
                              @"This method may only be called on RLMSet instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.anyObjE sortedResultsUsingKeyPath:@"self" ascending:NO], 
                              @"This method may only be called on RLMSet instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.anyObjF sortedResultsUsingKeyPath:@"self" ascending:NO], 
                              @"This method may only be called on RLMSet instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.anyObjG sortedResultsUsingKeyPath:@"self" ascending:NO], 
                              @"This method may only be called on RLMSet instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.anyObjH sortedResultsUsingKeyPath:@"self" ascending:NO], 
                              @"This method may only be called on RLMSet instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.anyObjI sortedResultsUsingKeyPath:@"self" ascending:NO], 
                              @"This method may only be called on RLMSet instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.anyObjJ sortedResultsUsingKeyPath:@"self" ascending:NO], 
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
    RLMAssertThrowsWithReason([unmanaged.anyObjA sortedResultsUsingDescriptors:@[]], 
                              @"This method may only be called on RLMSet instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.anyObjB sortedResultsUsingDescriptors:@[]], 
                              @"This method may only be called on RLMSet instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.anyObjC sortedResultsUsingDescriptors:@[]], 
                              @"This method may only be called on RLMSet instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.anyObjD sortedResultsUsingDescriptors:@[]], 
                              @"This method may only be called on RLMSet instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.anyObjE sortedResultsUsingDescriptors:@[]], 
                              @"This method may only be called on RLMSet instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.anyObjF sortedResultsUsingDescriptors:@[]], 
                              @"This method may only be called on RLMSet instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.anyObjG sortedResultsUsingDescriptors:@[]], 
                              @"This method may only be called on RLMSet instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.anyObjH sortedResultsUsingDescriptors:@[]], 
                              @"This method may only be called on RLMSet instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.anyObjI sortedResultsUsingDescriptors:@[]], 
                              @"This method may only be called on RLMSet instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.anyObjJ sortedResultsUsingDescriptors:@[]], 
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
    RLMAssertThrowsWithReason([managed.anyObjA sortedResultsUsingKeyPath:@"not self" ascending:NO], 
                              @"can only be sorted on 'self'");
    RLMAssertThrowsWithReason([managed.anyObjB sortedResultsUsingKeyPath:@"not self" ascending:NO], 
                              @"can only be sorted on 'self'");
    RLMAssertThrowsWithReason([managed.anyObjC sortedResultsUsingKeyPath:@"not self" ascending:NO], 
                              @"can only be sorted on 'self'");
    RLMAssertThrowsWithReason([managed.anyObjD sortedResultsUsingKeyPath:@"not self" ascending:NO], 
                              @"can only be sorted on 'self'");
    RLMAssertThrowsWithReason([managed.anyObjE sortedResultsUsingKeyPath:@"not self" ascending:NO], 
                              @"can only be sorted on 'self'");
    RLMAssertThrowsWithReason([managed.anyObjF sortedResultsUsingKeyPath:@"not self" ascending:NO], 
                              @"can only be sorted on 'self'");
    RLMAssertThrowsWithReason([managed.anyObjG sortedResultsUsingKeyPath:@"not self" ascending:NO], 
                              @"can only be sorted on 'self'");
    RLMAssertThrowsWithReason([managed.anyObjH sortedResultsUsingKeyPath:@"not self" ascending:NO], 
                              @"can only be sorted on 'self'");
    RLMAssertThrowsWithReason([managed.anyObjI sortedResultsUsingKeyPath:@"not self" ascending:NO], 
                              @"can only be sorted on 'self'");
    RLMAssertThrowsWithReason([managed.anyObjJ sortedResultsUsingKeyPath:@"not self" ascending:NO], 
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
    [managed.anyObjA addObjects:@[@NO, @YES, @NO]];
    [managed.anyObjB addObjects:@[@2, @3, @2]];
    [managed.anyObjC addObjects:@[@2.2f, @3.3f, @2.2f]];
    [managed.anyObjD addObjects:@[@2.2, @3.3, @2.2]];
    [managed.anyObjE addObjects:@[@"a", @"b", @"a"]];
    [managed.anyObjF addObjects:@[data(1), data(2), data(1)]];
    [managed.anyObjG addObjects:@[date(1), date(2), date(1)]];
    [managed.anyObjH addObjects:@[decimal128(1), decimal128(2), decimal128(1)]];
    [managed.anyObjI addObjects:@[objectId(1), objectId(2), objectId(1)]];
    [managed.anyObjJ addObjects:@[uuid(@"00000000-0000-0000-0000-000000000000"), uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"), uuid(@"00000000-0000-0000-0000-000000000000")]];
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
    XCTAssertEqualObjects([NSSet setWithArray:[[[managed.anyObjA sortedResultsUsingDescriptors:@[]] valueForKey:@"self"] allObjects]], 
                          ([NSSet setWithArray:@[@NO, @YES]]));
    XCTAssertEqualObjects([NSSet setWithArray:[[[managed.anyObjB sortedResultsUsingDescriptors:@[]] valueForKey:@"self"] allObjects]], 
                          ([NSSet setWithArray:@[@2, @3]]));
    XCTAssertEqualObjects([NSSet setWithArray:[[[managed.anyObjC sortedResultsUsingDescriptors:@[]] valueForKey:@"self"] allObjects]], 
                          ([NSSet setWithArray:@[@2.2f, @3.3f]]));
    XCTAssertEqualObjects([NSSet setWithArray:[[[managed.anyObjD sortedResultsUsingDescriptors:@[]] valueForKey:@"self"] allObjects]], 
                          ([NSSet setWithArray:@[@2.2, @3.3]]));
    XCTAssertEqualObjects([NSSet setWithArray:[[[managed.anyObjE sortedResultsUsingDescriptors:@[]] valueForKey:@"self"] allObjects]], 
                          ([NSSet setWithArray:@[@"a", @"b"]]));
    XCTAssertEqualObjects([NSSet setWithArray:[[[managed.anyObjF sortedResultsUsingDescriptors:@[]] valueForKey:@"self"] allObjects]], 
                          ([NSSet setWithArray:@[data(1), data(2)]]));
    XCTAssertEqualObjects([NSSet setWithArray:[[[managed.anyObjG sortedResultsUsingDescriptors:@[]] valueForKey:@"self"] allObjects]], 
                          ([NSSet setWithArray:@[date(1), date(2)]]));
    XCTAssertEqualObjects([NSSet setWithArray:[[[managed.anyObjH sortedResultsUsingDescriptors:@[]] valueForKey:@"self"] allObjects]], 
                          ([NSSet setWithArray:@[decimal128(1), decimal128(2)]]));
    XCTAssertEqualObjects([NSSet setWithArray:[[[managed.anyObjI sortedResultsUsingDescriptors:@[]] valueForKey:@"self"] allObjects]], 
                          ([NSSet setWithArray:@[objectId(1), objectId(2)]]));
    XCTAssertEqualObjects([NSSet setWithArray:[[[managed.anyObjJ sortedResultsUsingDescriptors:@[]] valueForKey:@"self"] allObjects]], 
                          ([NSSet setWithArray:@[uuid(@"00000000-0000-0000-0000-000000000000"), uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")]]));
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
    XCTAssertEqualObjects([NSSet setWithArray:[[[managed.anyObjA sortedResultsUsingKeyPath:@"self" ascending:NO] valueForKey:@"self"] allObjects]], 
                          ([NSSet setWithArray:@[@YES, @NO]]));
    XCTAssertEqualObjects([NSSet setWithArray:[[[managed.anyObjB sortedResultsUsingKeyPath:@"self" ascending:NO] valueForKey:@"self"] allObjects]], 
                          ([NSSet setWithArray:@[@3, @2]]));
    XCTAssertEqualObjects([NSSet setWithArray:[[[managed.anyObjC sortedResultsUsingKeyPath:@"self" ascending:NO] valueForKey:@"self"] allObjects]], 
                          ([NSSet setWithArray:@[@3.3f, @2.2f]]));
    XCTAssertEqualObjects([NSSet setWithArray:[[[managed.anyObjD sortedResultsUsingKeyPath:@"self" ascending:NO] valueForKey:@"self"] allObjects]], 
                          ([NSSet setWithArray:@[@3.3, @2.2]]));
    XCTAssertEqualObjects([NSSet setWithArray:[[[managed.anyObjE sortedResultsUsingKeyPath:@"self" ascending:NO] valueForKey:@"self"] allObjects]], 
                          ([NSSet setWithArray:@[@"b", @"a"]]));
    XCTAssertEqualObjects([NSSet setWithArray:[[[managed.anyObjF sortedResultsUsingKeyPath:@"self" ascending:NO] valueForKey:@"self"] allObjects]], 
                          ([NSSet setWithArray:@[data(2), data(1)]]));
    XCTAssertEqualObjects([NSSet setWithArray:[[[managed.anyObjG sortedResultsUsingKeyPath:@"self" ascending:NO] valueForKey:@"self"] allObjects]], 
                          ([NSSet setWithArray:@[date(2), date(1)]]));
    XCTAssertEqualObjects([NSSet setWithArray:[[[managed.anyObjH sortedResultsUsingKeyPath:@"self" ascending:NO] valueForKey:@"self"] allObjects]], 
                          ([NSSet setWithArray:@[decimal128(2), decimal128(1)]]));
    XCTAssertEqualObjects([NSSet setWithArray:[[[managed.anyObjI sortedResultsUsingKeyPath:@"self" ascending:NO] valueForKey:@"self"] allObjects]], 
                          ([NSSet setWithArray:@[objectId(2), objectId(1)]]));
    XCTAssertEqualObjects([NSSet setWithArray:[[[managed.anyObjJ sortedResultsUsingKeyPath:@"self" ascending:NO] valueForKey:@"self"] allObjects]], 
                          ([NSSet setWithArray:@[uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"), uuid(@"00000000-0000-0000-0000-000000000000")]]));
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
    XCTAssertEqualObjects([NSSet setWithArray:[[[managed.anyObjA sortedResultsUsingKeyPath:@"self" ascending:YES] valueForKey:@"self"] allObjects]], 
                          ([NSSet setWithArray:@[@NO, @YES]]));
    XCTAssertEqualObjects([NSSet setWithArray:[[[managed.anyObjB sortedResultsUsingKeyPath:@"self" ascending:YES] valueForKey:@"self"] allObjects]], 
                          ([NSSet setWithArray:@[@2, @3]]));
    XCTAssertEqualObjects([NSSet setWithArray:[[[managed.anyObjC sortedResultsUsingKeyPath:@"self" ascending:YES] valueForKey:@"self"] allObjects]], 
                          ([NSSet setWithArray:@[@2.2f, @3.3f]]));
    XCTAssertEqualObjects([NSSet setWithArray:[[[managed.anyObjD sortedResultsUsingKeyPath:@"self" ascending:YES] valueForKey:@"self"] allObjects]], 
                          ([NSSet setWithArray:@[@2.2, @3.3]]));
    XCTAssertEqualObjects([NSSet setWithArray:[[[managed.anyObjE sortedResultsUsingKeyPath:@"self" ascending:YES] valueForKey:@"self"] allObjects]], 
                          ([NSSet setWithArray:@[@"a", @"b"]]));
    XCTAssertEqualObjects([NSSet setWithArray:[[[managed.anyObjF sortedResultsUsingKeyPath:@"self" ascending:YES] valueForKey:@"self"] allObjects]], 
                          ([NSSet setWithArray:@[data(1), data(2)]]));
    XCTAssertEqualObjects([NSSet setWithArray:[[[managed.anyObjG sortedResultsUsingKeyPath:@"self" ascending:YES] valueForKey:@"self"] allObjects]], 
                          ([NSSet setWithArray:@[date(1), date(2)]]));
    XCTAssertEqualObjects([NSSet setWithArray:[[[managed.anyObjH sortedResultsUsingKeyPath:@"self" ascending:YES] valueForKey:@"self"] allObjects]], 
                          ([NSSet setWithArray:@[decimal128(1), decimal128(2)]]));
    XCTAssertEqualObjects([NSSet setWithArray:[[[managed.anyObjI sortedResultsUsingKeyPath:@"self" ascending:YES] valueForKey:@"self"] allObjects]], 
                          ([NSSet setWithArray:@[objectId(1), objectId(2)]]));
    XCTAssertEqualObjects([NSSet setWithArray:[[[managed.anyObjJ sortedResultsUsingKeyPath:@"self" ascending:YES] valueForKey:@"self"] allObjects]], 
                          ([NSSet setWithArray:@[uuid(@"00000000-0000-0000-0000-000000000000"), uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")]]));
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
    RLMAssertThrowsWithReason([unmanaged.anyObjA objectsWhere:@"TRUEPREDICATE"], 
                              @"This method may only be called on RLMSet instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.anyObjB objectsWhere:@"TRUEPREDICATE"], 
                              @"This method may only be called on RLMSet instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.anyObjC objectsWhere:@"TRUEPREDICATE"], 
                              @"This method may only be called on RLMSet instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.anyObjD objectsWhere:@"TRUEPREDICATE"], 
                              @"This method may only be called on RLMSet instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.anyObjE objectsWhere:@"TRUEPREDICATE"], 
                              @"This method may only be called on RLMSet instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.anyObjF objectsWhere:@"TRUEPREDICATE"], 
                              @"This method may only be called on RLMSet instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.anyObjG objectsWhere:@"TRUEPREDICATE"], 
                              @"This method may only be called on RLMSet instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.anyObjH objectsWhere:@"TRUEPREDICATE"], 
                              @"This method may only be called on RLMSet instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.anyObjI objectsWhere:@"TRUEPREDICATE"], 
                              @"This method may only be called on RLMSet instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.anyObjJ objectsWhere:@"TRUEPREDICATE"], 
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
    RLMAssertThrowsWithReason([unmanaged.anyObjA objectsWithPredicate:[NSPredicate predicateWithValue:YES]], 
                              @"This method may only be called on RLMSet instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.anyObjB objectsWithPredicate:[NSPredicate predicateWithValue:YES]], 
                              @"This method may only be called on RLMSet instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.anyObjC objectsWithPredicate:[NSPredicate predicateWithValue:YES]], 
                              @"This method may only be called on RLMSet instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.anyObjD objectsWithPredicate:[NSPredicate predicateWithValue:YES]], 
                              @"This method may only be called on RLMSet instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.anyObjE objectsWithPredicate:[NSPredicate predicateWithValue:YES]], 
                              @"This method may only be called on RLMSet instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.anyObjF objectsWithPredicate:[NSPredicate predicateWithValue:YES]], 
                              @"This method may only be called on RLMSet instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.anyObjG objectsWithPredicate:[NSPredicate predicateWithValue:YES]], 
                              @"This method may only be called on RLMSet instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.anyObjH objectsWithPredicate:[NSPredicate predicateWithValue:YES]], 
                              @"This method may only be called on RLMSet instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.anyObjI objectsWithPredicate:[NSPredicate predicateWithValue:YES]], 
                              @"This method may only be called on RLMSet instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.anyObjJ objectsWithPredicate:[NSPredicate predicateWithValue:YES]], 
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
    RLMAssertThrowsWithReason([managed.anyObjA objectsWhere:@"TRUEPREDICATE"], 
                              @"implemented");
    RLMAssertThrowsWithReason([managed.anyObjB objectsWhere:@"TRUEPREDICATE"], 
                              @"implemented");
    RLMAssertThrowsWithReason([managed.anyObjC objectsWhere:@"TRUEPREDICATE"], 
                              @"implemented");
    RLMAssertThrowsWithReason([managed.anyObjD objectsWhere:@"TRUEPREDICATE"], 
                              @"implemented");
    RLMAssertThrowsWithReason([managed.anyObjE objectsWhere:@"TRUEPREDICATE"], 
                              @"implemented");
    RLMAssertThrowsWithReason([managed.anyObjF objectsWhere:@"TRUEPREDICATE"], 
                              @"implemented");
    RLMAssertThrowsWithReason([managed.anyObjG objectsWhere:@"TRUEPREDICATE"], 
                              @"implemented");
    RLMAssertThrowsWithReason([managed.anyObjH objectsWhere:@"TRUEPREDICATE"], 
                              @"implemented");
    RLMAssertThrowsWithReason([managed.anyObjI objectsWhere:@"TRUEPREDICATE"], 
                              @"implemented");
    RLMAssertThrowsWithReason([managed.anyObjJ objectsWhere:@"TRUEPREDICATE"], 
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
    RLMAssertThrowsWithReason([managed.anyObjA objectsWithPredicate:[NSPredicate predicateWithValue:YES]], 
                              @"implemented");
    RLMAssertThrowsWithReason([managed.anyObjB objectsWithPredicate:[NSPredicate predicateWithValue:YES]], 
                              @"implemented");
    RLMAssertThrowsWithReason([managed.anyObjC objectsWithPredicate:[NSPredicate predicateWithValue:YES]], 
                              @"implemented");
    RLMAssertThrowsWithReason([managed.anyObjD objectsWithPredicate:[NSPredicate predicateWithValue:YES]], 
                              @"implemented");
    RLMAssertThrowsWithReason([managed.anyObjE objectsWithPredicate:[NSPredicate predicateWithValue:YES]], 
                              @"implemented");
    RLMAssertThrowsWithReason([managed.anyObjF objectsWithPredicate:[NSPredicate predicateWithValue:YES]], 
                              @"implemented");
    RLMAssertThrowsWithReason([managed.anyObjG objectsWithPredicate:[NSPredicate predicateWithValue:YES]], 
                              @"implemented");
    RLMAssertThrowsWithReason([managed.anyObjH objectsWithPredicate:[NSPredicate predicateWithValue:YES]], 
                              @"implemented");
    RLMAssertThrowsWithReason([managed.anyObjI objectsWithPredicate:[NSPredicate predicateWithValue:YES]], 
                              @"implemented");
    RLMAssertThrowsWithReason([managed.anyObjJ objectsWithPredicate:[NSPredicate predicateWithValue:YES]], 
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
    RLMAssertThrowsWithReason([[managed.anyObjA sortedResultsUsingKeyPath:@"self" ascending:NO] 
                               objectsWhere:@"TRUEPREDICATE"], @"implemented");
    RLMAssertThrowsWithReason([[managed.anyObjB sortedResultsUsingKeyPath:@"self" ascending:NO] 
                               objectsWhere:@"TRUEPREDICATE"], @"implemented");
    RLMAssertThrowsWithReason([[managed.anyObjC sortedResultsUsingKeyPath:@"self" ascending:NO] 
                               objectsWhere:@"TRUEPREDICATE"], @"implemented");
    RLMAssertThrowsWithReason([[managed.anyObjD sortedResultsUsingKeyPath:@"self" ascending:NO] 
                               objectsWhere:@"TRUEPREDICATE"], @"implemented");
    RLMAssertThrowsWithReason([[managed.anyObjE sortedResultsUsingKeyPath:@"self" ascending:NO] 
                               objectsWhere:@"TRUEPREDICATE"], @"implemented");
    RLMAssertThrowsWithReason([[managed.anyObjF sortedResultsUsingKeyPath:@"self" ascending:NO] 
                               objectsWhere:@"TRUEPREDICATE"], @"implemented");
    RLMAssertThrowsWithReason([[managed.anyObjG sortedResultsUsingKeyPath:@"self" ascending:NO] 
                               objectsWhere:@"TRUEPREDICATE"], @"implemented");
    RLMAssertThrowsWithReason([[managed.anyObjH sortedResultsUsingKeyPath:@"self" ascending:NO] 
                               objectsWhere:@"TRUEPREDICATE"], @"implemented");
    RLMAssertThrowsWithReason([[managed.anyObjI sortedResultsUsingKeyPath:@"self" ascending:NO] 
                               objectsWhere:@"TRUEPREDICATE"], @"implemented");
    RLMAssertThrowsWithReason([[managed.anyObjJ sortedResultsUsingKeyPath:@"self" ascending:NO] 
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
    RLMAssertThrowsWithReason([[managed.anyObjA sortedResultsUsingKeyPath:@"self" ascending:NO] 
                               objectsWithPredicate:[NSPredicate predicateWithValue:YES]], @"implemented");
    RLMAssertThrowsWithReason([[managed.anyObjB sortedResultsUsingKeyPath:@"self" ascending:NO] 
                               objectsWithPredicate:[NSPredicate predicateWithValue:YES]], @"implemented");
    RLMAssertThrowsWithReason([[managed.anyObjC sortedResultsUsingKeyPath:@"self" ascending:NO] 
                               objectsWithPredicate:[NSPredicate predicateWithValue:YES]], @"implemented");
    RLMAssertThrowsWithReason([[managed.anyObjD sortedResultsUsingKeyPath:@"self" ascending:NO] 
                               objectsWithPredicate:[NSPredicate predicateWithValue:YES]], @"implemented");
    RLMAssertThrowsWithReason([[managed.anyObjE sortedResultsUsingKeyPath:@"self" ascending:NO] 
                               objectsWithPredicate:[NSPredicate predicateWithValue:YES]], @"implemented");
    RLMAssertThrowsWithReason([[managed.anyObjF sortedResultsUsingKeyPath:@"self" ascending:NO] 
                               objectsWithPredicate:[NSPredicate predicateWithValue:YES]], @"implemented");
    RLMAssertThrowsWithReason([[managed.anyObjG sortedResultsUsingKeyPath:@"self" ascending:NO] 
                               objectsWithPredicate:[NSPredicate predicateWithValue:YES]], @"implemented");
    RLMAssertThrowsWithReason([[managed.anyObjH sortedResultsUsingKeyPath:@"self" ascending:NO] 
                               objectsWithPredicate:[NSPredicate predicateWithValue:YES]], @"implemented");
    RLMAssertThrowsWithReason([[managed.anyObjI sortedResultsUsingKeyPath:@"self" ascending:NO] 
                               objectsWithPredicate:[NSPredicate predicateWithValue:YES]], @"implemented");
    RLMAssertThrowsWithReason([[managed.anyObjJ sortedResultsUsingKeyPath:@"self" ascending:NO] 
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
    RLMAssertThrowsWithReason([unmanaged.anyObjA addNotificationBlock:^(__unused id a, __unused id c, __unused id e) { }], 
                              @"This method may only be called on RLMSet instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.anyObjB addNotificationBlock:^(__unused id a, __unused id c, __unused id e) { }], 
                              @"This method may only be called on RLMSet instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.anyObjC addNotificationBlock:^(__unused id a, __unused id c, __unused id e) { }], 
                              @"This method may only be called on RLMSet instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.anyObjD addNotificationBlock:^(__unused id a, __unused id c, __unused id e) { }], 
                              @"This method may only be called on RLMSet instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.anyObjE addNotificationBlock:^(__unused id a, __unused id c, __unused id e) { }], 
                              @"This method may only be called on RLMSet instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.anyObjF addNotificationBlock:^(__unused id a, __unused id c, __unused id e) { }], 
                              @"This method may only be called on RLMSet instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.anyObjG addNotificationBlock:^(__unused id a, __unused id c, __unused id e) { }], 
                              @"This method may only be called on RLMSet instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.anyObjH addNotificationBlock:^(__unused id a, __unused id c, __unused id e) { }], 
                              @"This method may only be called on RLMSet instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.anyObjI addNotificationBlock:^(__unused id a, __unused id c, __unused id e) { }], 
                              @"This method may only be called on RLMSet instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.anyObjJ addNotificationBlock:^(__unused id a, __unused id c, __unused id e) { }], 
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
    [managed.anyObjA addObjects:@[@NO, @YES]];
    [managed.anyObjB addObjects:@[@2, @3]];
    [managed.anyObjC addObjects:@[@2.2f, @3.3f]];
    [managed.anyObjD addObjects:@[@2.2, @3.3]];
    [managed.anyObjE addObjects:@[@"a", @"b"]];
    [managed.anyObjF addObjects:@[data(1), data(2)]];
    [managed.anyObjG addObjects:@[date(1), date(2)]];
    [managed.anyObjH addObjects:@[decimal128(1), decimal128(2)]];
    [managed.anyObjI addObjects:@[objectId(1), objectId(2)]];
    [managed.anyObjJ addObjects:@[uuid(@"00000000-0000-0000-0000-000000000000"), uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")]];
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
    [managed.anyObjA2 addObjects:@[@NO, @YES]];
    [managed.anyObjB2 addObjects:@[@2, @4]];
    [managed.anyObjC2 addObjects:@[@2.2f, @4.4f]];
    [managed.anyObjD2 addObjects:@[@2.2, @4.4]];
    [managed.anyObjE2 addObjects:@[@"a", @"d"]];
    [managed.anyObjF2 addObjects:@[data(1), data(3)]];
    [managed.anyObjG2 addObjects:@[date(1), date(3)]];
    [managed.anyObjH2 addObjects:@[decimal128(1), decimal128(3)]];
    [managed.anyObjI2 addObjects:@[objectId(1), objectId(3)]];
    [managed.anyObjJ2 addObjects:@[uuid(@"00000000-0000-0000-0000-000000000000"), uuid(@"123DECC8-B300-4954-A233-F89909F4FD89")]];
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
    [unmanaged.anyObjA addObjects:@[@NO, @YES]];
    [unmanaged.anyObjB addObjects:@[@2, @3]];
    [unmanaged.anyObjC addObjects:@[@2.2f, @3.3f]];
    [unmanaged.anyObjD addObjects:@[@2.2, @3.3]];
    [unmanaged.anyObjE addObjects:@[@"a", @"b"]];
    [unmanaged.anyObjF addObjects:@[data(1), data(2)]];
    [unmanaged.anyObjG addObjects:@[date(1), date(2)]];
    [unmanaged.anyObjH addObjects:@[decimal128(1), decimal128(2)]];
    [unmanaged.anyObjI addObjects:@[objectId(1), objectId(2)]];
    [unmanaged.anyObjJ addObjects:@[uuid(@"00000000-0000-0000-0000-000000000000"), uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")]];
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
    [unmanaged.anyObjA2 addObjects:@[@NO, @YES]];
    [unmanaged.anyObjB2 addObjects:@[@2, @4]];
    [unmanaged.anyObjC2 addObjects:@[@4.4f, @3.3f]];
    [unmanaged.anyObjD2 addObjects:@[@2.2, @4.4]];
    [unmanaged.anyObjE2 addObjects:@[@"a", @"d"]];
    [unmanaged.anyObjF2 addObjects:@[data(1), data(3)]];
    [unmanaged.anyObjG2 addObjects:@[date(1), date(4)]];
    [unmanaged.anyObjH2 addObjects:@[decimal128(1), decimal128(3)]];
    [unmanaged.anyObjI2 addObjects:@[objectId(1), objectId(3)]];
    [unmanaged.anyObjJ2 addObjects:@[uuid(@"00000000-0000-0000-0000-000000000000"), uuid(@"123DECC8-B300-4954-A233-F89909F4FD89")]];
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
    [unmanaged.anyObjA setSet:unmanaged.anyObjA2];
    [unmanaged.anyObjB setSet:unmanaged.anyObjB2];
    [unmanaged.anyObjC setSet:unmanaged.anyObjC2];
    [unmanaged.anyObjD setSet:unmanaged.anyObjD2];
    [unmanaged.anyObjE setSet:unmanaged.anyObjE2];
    [unmanaged.anyObjF setSet:unmanaged.anyObjF2];
    [unmanaged.anyObjG setSet:unmanaged.anyObjG2];
    [unmanaged.anyObjH setSet:unmanaged.anyObjH2];
    [unmanaged.anyObjI setSet:unmanaged.anyObjI2];
    [unmanaged.anyObjJ setSet:unmanaged.anyObjJ2];
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
    [managed.anyObjA setSet:managed.anyObjA2];
    [managed.anyObjB setSet:managed.anyObjB2];
    [managed.anyObjC setSet:managed.anyObjC2];
    [managed.anyObjD setSet:managed.anyObjD2];
    [managed.anyObjE setSet:managed.anyObjE2];
    [managed.anyObjF setSet:managed.anyObjF2];
    [managed.anyObjG setSet:managed.anyObjG2];
    [managed.anyObjH setSet:managed.anyObjH2];
    [managed.anyObjI setSet:managed.anyObjI2];
    [managed.anyObjJ setSet:managed.anyObjJ2];
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
    XCTAssertEqual(managed.boolObj.count, 2U);
    XCTAssertEqualObjects([NSSet setWithArray:managed.boolObj.allObjects], ([NSSet setWithArray:@[@NO, @YES]]));
    XCTAssertEqual(optManaged.boolObj.count, 3U);
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
    [managed.anyObjA addObjects:@[@NO, @YES]];
    [managed.anyObjB addObjects:@[@2, @3]];
    [managed.anyObjC addObjects:@[@2.2f, @3.3f]];
    [managed.anyObjD addObjects:@[@2.2, @3.3]];
    [managed.anyObjE addObjects:@[@"a", @"b"]];
    [managed.anyObjF addObjects:@[data(1), data(2)]];
    [managed.anyObjG addObjects:@[date(1), date(2)]];
    [managed.anyObjH addObjects:@[decimal128(1), decimal128(2)]];
    [managed.anyObjI addObjects:@[objectId(1), objectId(2)]];
    [managed.anyObjJ addObjects:@[uuid(@"00000000-0000-0000-0000-000000000000"), uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")]];
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
    [managed.anyObjA2 addObjects:@[@NO, @YES]];
    [managed.anyObjB2 addObjects:@[@2, @4]];
    [managed.anyObjC2 addObjects:@[@2.2f, @4.4f]];
    [managed.anyObjD2 addObjects:@[@2.2, @4.4]];
    [managed.anyObjE2 addObjects:@[@"a", @"d"]];
    [managed.anyObjF2 addObjects:@[data(1), data(3)]];
    [managed.anyObjG2 addObjects:@[date(1), date(3)]];
    [managed.anyObjH2 addObjects:@[decimal128(1), decimal128(3)]];
    [managed.anyObjI2 addObjects:@[objectId(1), objectId(3)]];
    [managed.anyObjJ2 addObjects:@[uuid(@"00000000-0000-0000-0000-000000000000"), uuid(@"123DECC8-B300-4954-A233-F89909F4FD89")]];
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
    [unmanaged.anyObjA addObjects:@[@NO, @YES]];
    [unmanaged.anyObjB addObjects:@[@2, @3]];
    [unmanaged.anyObjC addObjects:@[@2.2f, @3.3f]];
    [unmanaged.anyObjD addObjects:@[@2.2, @3.3]];
    [unmanaged.anyObjE addObjects:@[@"a", @"b"]];
    [unmanaged.anyObjF addObjects:@[data(1), data(2)]];
    [unmanaged.anyObjG addObjects:@[date(1), date(2)]];
    [unmanaged.anyObjH addObjects:@[decimal128(1), decimal128(2)]];
    [unmanaged.anyObjI addObjects:@[objectId(1), objectId(2)]];
    [unmanaged.anyObjJ addObjects:@[uuid(@"00000000-0000-0000-0000-000000000000"), uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")]];
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
    [unmanaged.anyObjA2 addObjects:@[@NO, @YES]];
    [unmanaged.anyObjB2 addObjects:@[@2, @4]];
    [unmanaged.anyObjC2 addObjects:@[@4.4f, @3.3f]];
    [unmanaged.anyObjD2 addObjects:@[@2.2, @4.4]];
    [unmanaged.anyObjE2 addObjects:@[@"a", @"d"]];
    [unmanaged.anyObjF2 addObjects:@[data(1), data(3)]];
    [unmanaged.anyObjG2 addObjects:@[date(1), date(4)]];
    [unmanaged.anyObjH2 addObjects:@[decimal128(1), decimal128(3)]];
    [unmanaged.anyObjI2 addObjects:@[objectId(1), objectId(3)]];
    [unmanaged.anyObjJ2 addObjects:@[uuid(@"00000000-0000-0000-0000-000000000000"), uuid(@"123DECC8-B300-4954-A233-F89909F4FD89")]];
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
    XCTAssertThrows([managed.anyObjA unionSet:managed.anyObjA2]);
    XCTAssertThrows([managed.anyObjB unionSet:managed.anyObjB2]);
    XCTAssertThrows([managed.anyObjC unionSet:managed.anyObjC2]);
    XCTAssertThrows([managed.anyObjD unionSet:managed.anyObjD2]);
    XCTAssertThrows([managed.anyObjE unionSet:managed.anyObjE2]);
    XCTAssertThrows([managed.anyObjF unionSet:managed.anyObjF2]);
    XCTAssertThrows([managed.anyObjG unionSet:managed.anyObjG2]);
    XCTAssertThrows([managed.anyObjH unionSet:managed.anyObjH2]);
    XCTAssertThrows([managed.anyObjI unionSet:managed.anyObjI2]);
    XCTAssertThrows([managed.anyObjJ unionSet:managed.anyObjJ2]);
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
    [unmanaged.anyObjA unionSet:unmanaged.anyObjA2];
    [unmanaged.anyObjB unionSet:unmanaged.anyObjB2];
    [unmanaged.anyObjC unionSet:unmanaged.anyObjC2];
    [unmanaged.anyObjD unionSet:unmanaged.anyObjD2];
    [unmanaged.anyObjE unionSet:unmanaged.anyObjE2];
    [unmanaged.anyObjF unionSet:unmanaged.anyObjF2];
    [unmanaged.anyObjG unionSet:unmanaged.anyObjG2];
    [unmanaged.anyObjH unionSet:unmanaged.anyObjH2];
    [unmanaged.anyObjI unionSet:unmanaged.anyObjI2];
    [unmanaged.anyObjJ unionSet:unmanaged.anyObjJ2];
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
    [managed.anyObjA unionSet:managed.anyObjA2];
    [managed.anyObjB unionSet:managed.anyObjB2];
    [managed.anyObjC unionSet:managed.anyObjC2];
    [managed.anyObjD unionSet:managed.anyObjD2];
    [managed.anyObjE unionSet:managed.anyObjE2];
    [managed.anyObjF unionSet:managed.anyObjF2];
    [managed.anyObjG unionSet:managed.anyObjG2];
    [managed.anyObjH unionSet:managed.anyObjH2];
    [managed.anyObjI unionSet:managed.anyObjI2];
    [managed.anyObjJ unionSet:managed.anyObjJ2];
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
    XCTAssertEqual(managed.boolObj.count, 2U);
    XCTAssertEqualObjects([NSSet setWithArray:managed.boolObj.allObjects], ([NSSet setWithArray:@[@NO, @YES]]));
    XCTAssertEqual(optManaged.boolObj.count, 3U);
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
    [managed.anyObjA addObjects:@[@NO, @YES]];
    [managed.anyObjB addObjects:@[@2, @3]];
    [managed.anyObjC addObjects:@[@2.2f, @3.3f]];
    [managed.anyObjD addObjects:@[@2.2, @3.3]];
    [managed.anyObjE addObjects:@[@"a", @"b"]];
    [managed.anyObjF addObjects:@[data(1), data(2)]];
    [managed.anyObjG addObjects:@[date(1), date(2)]];
    [managed.anyObjH addObjects:@[decimal128(1), decimal128(2)]];
    [managed.anyObjI addObjects:@[objectId(1), objectId(2)]];
    [managed.anyObjJ addObjects:@[uuid(@"00000000-0000-0000-0000-000000000000"), uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")]];
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
    [managed.anyObjA2 addObjects:@[@NO, @YES]];
    [managed.anyObjB2 addObjects:@[@2, @4]];
    [managed.anyObjC2 addObjects:@[@2.2f, @4.4f]];
    [managed.anyObjD2 addObjects:@[@2.2, @4.4]];
    [managed.anyObjE2 addObjects:@[@"a", @"d"]];
    [managed.anyObjF2 addObjects:@[data(1), data(3)]];
    [managed.anyObjG2 addObjects:@[date(1), date(3)]];
    [managed.anyObjH2 addObjects:@[decimal128(1), decimal128(3)]];
    [managed.anyObjI2 addObjects:@[objectId(1), objectId(3)]];
    [managed.anyObjJ2 addObjects:@[uuid(@"00000000-0000-0000-0000-000000000000"), uuid(@"123DECC8-B300-4954-A233-F89909F4FD89")]];
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
    [unmanaged.anyObjA addObjects:@[@NO, @YES]];
    [unmanaged.anyObjB addObjects:@[@2, @3]];
    [unmanaged.anyObjC addObjects:@[@2.2f, @3.3f]];
    [unmanaged.anyObjD addObjects:@[@2.2, @3.3]];
    [unmanaged.anyObjE addObjects:@[@"a", @"b"]];
    [unmanaged.anyObjF addObjects:@[data(1), data(2)]];
    [unmanaged.anyObjG addObjects:@[date(1), date(2)]];
    [unmanaged.anyObjH addObjects:@[decimal128(1), decimal128(2)]];
    [unmanaged.anyObjI addObjects:@[objectId(1), objectId(2)]];
    [unmanaged.anyObjJ addObjects:@[uuid(@"00000000-0000-0000-0000-000000000000"), uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")]];
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
    [unmanaged.anyObjA2 addObjects:@[@NO, @YES]];
    [unmanaged.anyObjB2 addObjects:@[@2, @4]];
    [unmanaged.anyObjC2 addObjects:@[@4.4f, @3.3f]];
    [unmanaged.anyObjD2 addObjects:@[@2.2, @4.4]];
    [unmanaged.anyObjE2 addObjects:@[@"a", @"d"]];
    [unmanaged.anyObjF2 addObjects:@[data(1), data(3)]];
    [unmanaged.anyObjG2 addObjects:@[date(1), date(4)]];
    [unmanaged.anyObjH2 addObjects:@[decimal128(1), decimal128(3)]];
    [unmanaged.anyObjI2 addObjects:@[objectId(1), objectId(3)]];
    [unmanaged.anyObjJ2 addObjects:@[uuid(@"00000000-0000-0000-0000-000000000000"), uuid(@"123DECC8-B300-4954-A233-F89909F4FD89")]];
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
    XCTAssertThrows([managed.anyObjA intersectSet:managed.anyObjA2]);
    XCTAssertThrows([managed.anyObjB intersectSet:managed.anyObjB2]);
    XCTAssertThrows([managed.anyObjC intersectSet:managed.anyObjC2]);
    XCTAssertThrows([managed.anyObjD intersectSet:managed.anyObjD2]);
    XCTAssertThrows([managed.anyObjE intersectSet:managed.anyObjE2]);
    XCTAssertThrows([managed.anyObjF intersectSet:managed.anyObjF2]);
    XCTAssertThrows([managed.anyObjG intersectSet:managed.anyObjG2]);
    XCTAssertThrows([managed.anyObjH intersectSet:managed.anyObjH2]);
    XCTAssertThrows([managed.anyObjI intersectSet:managed.anyObjI2]);
    XCTAssertThrows([managed.anyObjJ intersectSet:managed.anyObjJ2]);
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
    XCTAssertTrue([managed.anyObjA intersectsSet:managed.anyObjA2]);
    XCTAssertTrue([managed.anyObjB intersectsSet:managed.anyObjB2]);
    XCTAssertTrue([managed.anyObjC intersectsSet:managed.anyObjC2]);
    XCTAssertTrue([managed.anyObjD intersectsSet:managed.anyObjD2]);
    XCTAssertTrue([managed.anyObjE intersectsSet:managed.anyObjE2]);
    XCTAssertTrue([managed.anyObjF intersectsSet:managed.anyObjF2]);
    XCTAssertTrue([managed.anyObjG intersectsSet:managed.anyObjG2]);
    XCTAssertTrue([managed.anyObjH intersectsSet:managed.anyObjH2]);
    XCTAssertTrue([managed.anyObjI intersectsSet:managed.anyObjI2]);
    XCTAssertTrue([managed.anyObjJ intersectsSet:managed.anyObjJ2]);
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
    XCTAssertTrue([unmanaged.anyObjA intersectsSet:unmanaged.anyObjA2]);
    XCTAssertTrue([unmanaged.anyObjB intersectsSet:unmanaged.anyObjB2]);
    XCTAssertTrue([unmanaged.anyObjC intersectsSet:unmanaged.anyObjC2]);
    XCTAssertTrue([unmanaged.anyObjD intersectsSet:unmanaged.anyObjD2]);
    XCTAssertTrue([unmanaged.anyObjE intersectsSet:unmanaged.anyObjE2]);
    XCTAssertTrue([unmanaged.anyObjF intersectsSet:unmanaged.anyObjF2]);
    XCTAssertTrue([unmanaged.anyObjG intersectsSet:unmanaged.anyObjG2]);
    XCTAssertTrue([unmanaged.anyObjH intersectsSet:unmanaged.anyObjH2]);
    XCTAssertTrue([unmanaged.anyObjI intersectsSet:unmanaged.anyObjI2]);
    XCTAssertTrue([unmanaged.anyObjJ intersectsSet:unmanaged.anyObjJ2]);
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
    [unmanaged.anyObjA intersectSet:unmanaged.anyObjA2];
    [unmanaged.anyObjB intersectSet:unmanaged.anyObjB2];
    [unmanaged.anyObjC intersectSet:unmanaged.anyObjC2];
    [unmanaged.anyObjD intersectSet:unmanaged.anyObjD2];
    [unmanaged.anyObjE intersectSet:unmanaged.anyObjE2];
    [unmanaged.anyObjF intersectSet:unmanaged.anyObjF2];
    [unmanaged.anyObjG intersectSet:unmanaged.anyObjG2];
    [unmanaged.anyObjH intersectSet:unmanaged.anyObjH2];
    [unmanaged.anyObjI intersectSet:unmanaged.anyObjI2];
    [unmanaged.anyObjJ intersectSet:unmanaged.anyObjJ2];
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
    [managed.anyObjA intersectSet:managed.anyObjA2];
    [managed.anyObjB intersectSet:managed.anyObjB2];
    [managed.anyObjC intersectSet:managed.anyObjC2];
    [managed.anyObjD intersectSet:managed.anyObjD2];
    [managed.anyObjE intersectSet:managed.anyObjE2];
    [managed.anyObjF intersectSet:managed.anyObjF2];
    [managed.anyObjG intersectSet:managed.anyObjG2];
    [managed.anyObjH intersectSet:managed.anyObjH2];
    [managed.anyObjI intersectSet:managed.anyObjI2];
    [managed.anyObjJ intersectSet:managed.anyObjJ2];
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
    XCTAssertEqual(managed.boolObj.count, 2U);
    XCTAssertEqualObjects([NSSet setWithArray:managed.boolObj.allObjects], ([NSSet setWithArray:@[@NO, @YES]]));
    XCTAssertEqual(optManaged.boolObj.count, 2U);
    XCTAssertEqualObjects([NSSet setWithArray:optManaged.boolObj.allObjects], ([NSSet setWithArray:@[NSNull.null, @NO]]));
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
    [managed.anyObjA addObjects:@[@NO, @YES]];
    [managed.anyObjB addObjects:@[@2, @3]];
    [managed.anyObjC addObjects:@[@2.2f, @3.3f]];
    [managed.anyObjD addObjects:@[@2.2, @3.3]];
    [managed.anyObjE addObjects:@[@"a", @"b"]];
    [managed.anyObjF addObjects:@[data(1), data(2)]];
    [managed.anyObjG addObjects:@[date(1), date(2)]];
    [managed.anyObjH addObjects:@[decimal128(1), decimal128(2)]];
    [managed.anyObjI addObjects:@[objectId(1), objectId(2)]];
    [managed.anyObjJ addObjects:@[uuid(@"00000000-0000-0000-0000-000000000000"), uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")]];
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
    [managed.anyObjA2 addObjects:@[@NO, @YES]];
    [managed.anyObjB2 addObjects:@[@2, @4]];
    [managed.anyObjC2 addObjects:@[@2.2f, @4.4f]];
    [managed.anyObjD2 addObjects:@[@2.2, @4.4]];
    [managed.anyObjE2 addObjects:@[@"a", @"d"]];
    [managed.anyObjF2 addObjects:@[data(1), data(3)]];
    [managed.anyObjG2 addObjects:@[date(1), date(3)]];
    [managed.anyObjH2 addObjects:@[decimal128(1), decimal128(3)]];
    [managed.anyObjI2 addObjects:@[objectId(1), objectId(3)]];
    [managed.anyObjJ2 addObjects:@[uuid(@"00000000-0000-0000-0000-000000000000"), uuid(@"123DECC8-B300-4954-A233-F89909F4FD89")]];
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
    [unmanaged.anyObjA addObjects:@[@NO, @YES]];
    [unmanaged.anyObjB addObjects:@[@2, @3]];
    [unmanaged.anyObjC addObjects:@[@2.2f, @3.3f]];
    [unmanaged.anyObjD addObjects:@[@2.2, @3.3]];
    [unmanaged.anyObjE addObjects:@[@"a", @"b"]];
    [unmanaged.anyObjF addObjects:@[data(1), data(2)]];
    [unmanaged.anyObjG addObjects:@[date(1), date(2)]];
    [unmanaged.anyObjH addObjects:@[decimal128(1), decimal128(2)]];
    [unmanaged.anyObjI addObjects:@[objectId(1), objectId(2)]];
    [unmanaged.anyObjJ addObjects:@[uuid(@"00000000-0000-0000-0000-000000000000"), uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")]];
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
    [unmanaged.anyObjA2 addObjects:@[@NO, @YES]];
    [unmanaged.anyObjB2 addObjects:@[@2, @4]];
    [unmanaged.anyObjC2 addObjects:@[@4.4f, @3.3f]];
    [unmanaged.anyObjD2 addObjects:@[@2.2, @4.4]];
    [unmanaged.anyObjE2 addObjects:@[@"a", @"d"]];
    [unmanaged.anyObjF2 addObjects:@[data(1), data(3)]];
    [unmanaged.anyObjG2 addObjects:@[date(1), date(4)]];
    [unmanaged.anyObjH2 addObjects:@[decimal128(1), decimal128(3)]];
    [unmanaged.anyObjI2 addObjects:@[objectId(1), objectId(3)]];
    [unmanaged.anyObjJ2 addObjects:@[uuid(@"00000000-0000-0000-0000-000000000000"), uuid(@"123DECC8-B300-4954-A233-F89909F4FD89")]];
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
    XCTAssertThrows([managed.anyObjA minusSet:managed.anyObjA2]);
    XCTAssertThrows([managed.anyObjB minusSet:managed.anyObjB2]);
    XCTAssertThrows([managed.anyObjC minusSet:managed.anyObjC2]);
    XCTAssertThrows([managed.anyObjD minusSet:managed.anyObjD2]);
    XCTAssertThrows([managed.anyObjE minusSet:managed.anyObjE2]);
    XCTAssertThrows([managed.anyObjF minusSet:managed.anyObjF2]);
    XCTAssertThrows([managed.anyObjG minusSet:managed.anyObjG2]);
    XCTAssertThrows([managed.anyObjH minusSet:managed.anyObjH2]);
    XCTAssertThrows([managed.anyObjI minusSet:managed.anyObjI2]);
    XCTAssertThrows([managed.anyObjJ minusSet:managed.anyObjJ2]);
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
    [unmanaged.anyObjA minusSet:unmanaged.anyObjA2];
    [unmanaged.anyObjB minusSet:unmanaged.anyObjB2];
    [unmanaged.anyObjC minusSet:unmanaged.anyObjC2];
    [unmanaged.anyObjD minusSet:unmanaged.anyObjD2];
    [unmanaged.anyObjE minusSet:unmanaged.anyObjE2];
    [unmanaged.anyObjF minusSet:unmanaged.anyObjF2];
    [unmanaged.anyObjG minusSet:unmanaged.anyObjG2];
    [unmanaged.anyObjH minusSet:unmanaged.anyObjH2];
    [unmanaged.anyObjI minusSet:unmanaged.anyObjI2];
    [unmanaged.anyObjJ minusSet:unmanaged.anyObjJ2];
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
    [managed.anyObjA minusSet:managed.anyObjA2];
    [managed.anyObjB minusSet:managed.anyObjB2];
    [managed.anyObjC minusSet:managed.anyObjC2];
    [managed.anyObjD minusSet:managed.anyObjD2];
    [managed.anyObjE minusSet:managed.anyObjE2];
    [managed.anyObjF minusSet:managed.anyObjF2];
    [managed.anyObjG minusSet:managed.anyObjG2];
    [managed.anyObjH minusSet:managed.anyObjH2];
    [managed.anyObjI minusSet:managed.anyObjI2];
    [managed.anyObjJ minusSet:managed.anyObjJ2];
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
    XCTAssertEqual(managed.boolObj.count, 0U);
    XCTAssertEqualObjects(managed.boolObj.allObjects, (@[]));
    XCTAssertEqual(optManaged.boolObj.count, 0U);
    XCTAssertEqualObjects(optManaged.boolObj.allObjects, (@[]));
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
    [managed.anyObjA addObjects:@[@NO, @YES]];
    [managed.anyObjB addObjects:@[@2, @3]];
    [managed.anyObjC addObjects:@[@2.2f, @3.3f]];
    [managed.anyObjD addObjects:@[@2.2, @3.3]];
    [managed.anyObjE addObjects:@[@"a", @"b"]];
    [managed.anyObjF addObjects:@[data(1), data(2)]];
    [managed.anyObjG addObjects:@[date(1), date(2)]];
    [managed.anyObjH addObjects:@[decimal128(1), decimal128(2)]];
    [managed.anyObjI addObjects:@[objectId(1), objectId(2)]];
    [managed.anyObjJ addObjects:@[uuid(@"00000000-0000-0000-0000-000000000000"), uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")]];
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
    [managed.anyObjA2 addObjects:@[@NO, @YES, @NO, @YES]];
    [managed.anyObjB2 addObjects:@[@2, @3, @2, @4]];
    [managed.anyObjC2 addObjects:@[@2.2f, @3.3f, @2.2f, @4.4f]];
    [managed.anyObjD2 addObjects:@[@2.2, @3.3, @2.2, @4.4]];
    [managed.anyObjE2 addObjects:@[@"a", @"b", @"a", @"d"]];
    [managed.anyObjF2 addObjects:@[data(1), data(2), data(1), data(3)]];
    [managed.anyObjG2 addObjects:@[date(1), date(2), date(1), date(3)]];
    [managed.anyObjH2 addObjects:@[decimal128(1), decimal128(2), decimal128(1), decimal128(3)]];
    [managed.anyObjI2 addObjects:@[objectId(1), objectId(2), objectId(1), objectId(3)]];
    [managed.anyObjJ2 addObjects:@[uuid(@"00000000-0000-0000-0000-000000000000"), uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"), uuid(@"00000000-0000-0000-0000-000000000000"), uuid(@"123DECC8-B300-4954-A233-F89909F4FD89")]];
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
    [unmanaged.anyObjA addObjects:@[@NO, @YES]];
    [unmanaged.anyObjB addObjects:@[@2, @3]];
    [unmanaged.anyObjC addObjects:@[@2.2f, @3.3f]];
    [unmanaged.anyObjD addObjects:@[@2.2, @3.3]];
    [unmanaged.anyObjE addObjects:@[@"a", @"b"]];
    [unmanaged.anyObjF addObjects:@[data(1), data(2)]];
    [unmanaged.anyObjG addObjects:@[date(1), date(2)]];
    [unmanaged.anyObjH addObjects:@[decimal128(1), decimal128(2)]];
    [unmanaged.anyObjI addObjects:@[objectId(1), objectId(2)]];
    [unmanaged.anyObjJ addObjects:@[uuid(@"00000000-0000-0000-0000-000000000000"), uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")]];
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
    [unmanaged.anyObjA2 addObjects:@[@NO, @YES, @NO, @YES]];
    [unmanaged.anyObjB2 addObjects:@[@2, @3, @2, @4]];
    [unmanaged.anyObjC2 addObjects:@[@2.2f, @3.3f, @4.4f, @3.3f]];
    [unmanaged.anyObjD2 addObjects:@[@2.2, @3.3, @2.2, @4.4]];
    [unmanaged.anyObjE2 addObjects:@[@"a", @"b", @"a", @"d"]];
    [unmanaged.anyObjF2 addObjects:@[data(1), data(2), data(1), data(3)]];
    [unmanaged.anyObjG2 addObjects:@[date(1), date(2), date(1), date(4)]];
    [unmanaged.anyObjH2 addObjects:@[decimal128(1), decimal128(2), decimal128(1), decimal128(3)]];
    [unmanaged.anyObjI2 addObjects:@[objectId(1), objectId(2), objectId(1), objectId(3)]];
    [unmanaged.anyObjJ2 addObjects:@[uuid(@"00000000-0000-0000-0000-000000000000"), uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"), uuid(@"00000000-0000-0000-0000-000000000000"), uuid(@"123DECC8-B300-4954-A233-F89909F4FD89")]];
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

    XCTAssertTrue([managed.boolObj isSubsetOfSet:managed.boolObj2]);
    XCTAssertTrue([unmanaged.boolObj isSubsetOfSet:unmanaged.boolObj2]);
    XCTAssertTrue([optManaged.boolObj isSubsetOfSet:optManaged.boolObj2]);

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

    XCTAssertNil([unmanaged.intObj minOfProperty:@"self"]);
    XCTAssertNil([unmanaged.floatObj minOfProperty:@"self"]);
    XCTAssertNil([unmanaged.doubleObj minOfProperty:@"self"]);
    XCTAssertNil([unmanaged.dateObj minOfProperty:@"self"]);
    XCTAssertNil([unmanaged.decimalObj minOfProperty:@"self"]);
    XCTAssertNil([unmanaged.anyObjC minOfProperty:@"self"]);
    XCTAssertNil([unmanaged.anyObjD minOfProperty:@"self"]);
    XCTAssertNil([unmanaged.anyObjG minOfProperty:@"self"]);
    XCTAssertNil([unmanaged.anyObjH minOfProperty:@"self"]);
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
    XCTAssertNil([managed.anyObjB minOfProperty:@"self"]);
    XCTAssertNil([managed.anyObjC minOfProperty:@"self"]);
    XCTAssertNil([managed.anyObjD minOfProperty:@"self"]);
    XCTAssertNil([managed.anyObjG minOfProperty:@"self"]);
    XCTAssertNil([managed.anyObjH minOfProperty:@"self"]);
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
    XCTAssertEqualObjects([unmanaged.anyObjC minOfProperty:@"self"], @2.2f);
    XCTAssertEqualObjects([unmanaged.anyObjD minOfProperty:@"self"], @2.2);
    XCTAssertEqualObjects([unmanaged.anyObjG minOfProperty:@"self"], date(1));
    XCTAssertEqualObjects([unmanaged.anyObjH minOfProperty:@"self"], decimal128(1));
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
    XCTAssertEqualObjects([managed.anyObjB minOfProperty:@"self"], @2);
    XCTAssertEqualObjects([managed.anyObjC minOfProperty:@"self"], @2.2f);
    XCTAssertEqualObjects([managed.anyObjD minOfProperty:@"self"], @2.2);
    XCTAssertEqualObjects([managed.anyObjG minOfProperty:@"self"], date(1));
    XCTAssertEqualObjects([managed.anyObjH minOfProperty:@"self"], decimal128(1));
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
    XCTAssertNil([unmanaged.anyObjC maxOfProperty:@"self"]);
    XCTAssertNil([unmanaged.anyObjD maxOfProperty:@"self"]);
    XCTAssertNil([unmanaged.anyObjG maxOfProperty:@"self"]);
    XCTAssertNil([unmanaged.anyObjH maxOfProperty:@"self"]);
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
    XCTAssertNil([managed.anyObjB maxOfProperty:@"self"]);
    XCTAssertNil([managed.anyObjC maxOfProperty:@"self"]);
    XCTAssertNil([managed.anyObjD maxOfProperty:@"self"]);
    XCTAssertNil([managed.anyObjG maxOfProperty:@"self"]);
    XCTAssertNil([managed.anyObjH maxOfProperty:@"self"]);
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
    XCTAssertEqualObjects([unmanaged.anyObjC maxOfProperty:@"self"], @3.3f);
    XCTAssertEqualObjects([unmanaged.anyObjD maxOfProperty:@"self"], @3.3);
    XCTAssertEqualObjects([unmanaged.anyObjG maxOfProperty:@"self"], date(2));
    XCTAssertEqualObjects([unmanaged.anyObjH maxOfProperty:@"self"], decimal128(2));
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
    XCTAssertEqualObjects([managed.anyObjB maxOfProperty:@"self"], @3);
    XCTAssertEqualObjects([managed.anyObjC maxOfProperty:@"self"], @3.3f);
    XCTAssertEqualObjects([managed.anyObjD maxOfProperty:@"self"], @3.3);
    XCTAssertEqualObjects([managed.anyObjG maxOfProperty:@"self"], date(2));
    XCTAssertEqualObjects([managed.anyObjH maxOfProperty:@"self"], decimal128(2));
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
    XCTAssertEqualObjects([unmanaged.anyObjB sumOfProperty:@"self"], @0);
    XCTAssertEqualObjects([unmanaged.anyObjC sumOfProperty:@"self"], @0);
    XCTAssertEqualObjects([unmanaged.anyObjD sumOfProperty:@"self"], @0);
    XCTAssertEqualObjects([unmanaged.anyObjH sumOfProperty:@"self"], @0);
    XCTAssertEqualObjects([optUnmanaged.intObj sumOfProperty:@"self"], @0);
    XCTAssertEqualObjects([optUnmanaged.floatObj sumOfProperty:@"self"], @0);
    XCTAssertEqualObjects([optUnmanaged.doubleObj sumOfProperty:@"self"], @0);
    XCTAssertEqualObjects([optUnmanaged.decimalObj sumOfProperty:@"self"], @0);
    XCTAssertEqualObjects([managed.intObj sumOfProperty:@"self"], @0);
    XCTAssertEqualObjects([managed.floatObj sumOfProperty:@"self"], @0);
    XCTAssertEqualObjects([managed.doubleObj sumOfProperty:@"self"], @0);
    XCTAssertEqualObjects([managed.decimalObj sumOfProperty:@"self"], @0);
    XCTAssertEqualObjects([managed.anyObjB sumOfProperty:@"self"], @0);
    XCTAssertEqualObjects([managed.anyObjC sumOfProperty:@"self"], @0);
    XCTAssertEqualObjects([managed.anyObjD sumOfProperty:@"self"], @0);
    XCTAssertEqualObjects([managed.anyObjH sumOfProperty:@"self"], @0);
    XCTAssertEqualObjects([optManaged.intObj sumOfProperty:@"self"], @0);
    XCTAssertEqualObjects([optManaged.floatObj sumOfProperty:@"self"], @0);
    XCTAssertEqualObjects([optManaged.doubleObj sumOfProperty:@"self"], @0);
    XCTAssertEqualObjects([optManaged.decimalObj sumOfProperty:@"self"], @0);

    [self addObjects];

    XCTAssertEqualWithAccuracy([unmanaged.intObj sumOfProperty:@"self"].doubleValue, sum(@[@2, @3]), .001);
    XCTAssertEqualWithAccuracy([unmanaged.floatObj sumOfProperty:@"self"].doubleValue, sum(@[@2.2f, @3.3f]), .001);
    XCTAssertEqualWithAccuracy([unmanaged.doubleObj sumOfProperty:@"self"].doubleValue, sum(@[@2.2, @3.3]), .001);
    XCTAssertEqualWithAccuracy([unmanaged.decimalObj sumOfProperty:@"self"].doubleValue, sum(@[decimal128(1), decimal128(2)]), .001);
    XCTAssertEqualWithAccuracy([unmanaged.anyObjB sumOfProperty:@"self"].doubleValue, sum(@[@2, @3]), .001);
    XCTAssertEqualWithAccuracy([unmanaged.anyObjC sumOfProperty:@"self"].doubleValue, sum(@[@2.2f, @3.3f]), .001);
    XCTAssertEqualWithAccuracy([unmanaged.anyObjD sumOfProperty:@"self"].doubleValue, sum(@[@2.2, @3.3]), .001);
    XCTAssertEqualWithAccuracy([unmanaged.anyObjH sumOfProperty:@"self"].doubleValue, sum(@[decimal128(1), decimal128(2)]), .001);
    XCTAssertEqualWithAccuracy([optUnmanaged.intObj sumOfProperty:@"self"].doubleValue, sum(@[NSNull.null, @2, @3]), .001);
    XCTAssertEqualWithAccuracy([optUnmanaged.floatObj sumOfProperty:@"self"].doubleValue, sum(@[NSNull.null, @2.2f, @3.3f]), .001);
    XCTAssertEqualWithAccuracy([optUnmanaged.doubleObj sumOfProperty:@"self"].doubleValue, sum(@[NSNull.null, @2.2, @3.3]), .001);
    XCTAssertEqualWithAccuracy([optUnmanaged.decimalObj sumOfProperty:@"self"].doubleValue, sum(@[NSNull.null, decimal128(1), decimal128(2)]), .001);
    XCTAssertEqualWithAccuracy([managed.intObj sumOfProperty:@"self"].doubleValue, sum(@[@2, @3]), .001);
    XCTAssertEqualWithAccuracy([managed.floatObj sumOfProperty:@"self"].doubleValue, sum(@[@2.2f, @3.3f]), .001);
    XCTAssertEqualWithAccuracy([managed.doubleObj sumOfProperty:@"self"].doubleValue, sum(@[@2.2, @3.3]), .001);
    XCTAssertEqualWithAccuracy([managed.decimalObj sumOfProperty:@"self"].doubleValue, sum(@[decimal128(1), decimal128(2)]), .001);
    XCTAssertEqualWithAccuracy([managed.anyObjB sumOfProperty:@"self"].doubleValue, sum(@[@2, @3]), .001);
    XCTAssertEqualWithAccuracy([managed.anyObjC sumOfProperty:@"self"].doubleValue, sum(@[@2.2f, @3.3f]), .001);
    XCTAssertEqualWithAccuracy([managed.anyObjD sumOfProperty:@"self"].doubleValue, sum(@[@2.2, @3.3]), .001);
    XCTAssertEqualWithAccuracy([managed.anyObjH sumOfProperty:@"self"].doubleValue, sum(@[decimal128(1), decimal128(2)]), .001);
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

    XCTAssertNil([unmanaged.intObj averageOfProperty:@"self"]);
    XCTAssertNil([unmanaged.floatObj averageOfProperty:@"self"]);
    XCTAssertNil([unmanaged.doubleObj averageOfProperty:@"self"]);
    XCTAssertNil([unmanaged.decimalObj averageOfProperty:@"self"]);
    XCTAssertNil([unmanaged.anyObjB averageOfProperty:@"self"]);
    XCTAssertNil([unmanaged.anyObjC averageOfProperty:@"self"]);
    XCTAssertNil([unmanaged.anyObjD averageOfProperty:@"self"]);
    XCTAssertNil([unmanaged.anyObjH averageOfProperty:@"self"]);
    XCTAssertNil([optUnmanaged.intObj averageOfProperty:@"self"]);
    XCTAssertNil([optUnmanaged.floatObj averageOfProperty:@"self"]);
    XCTAssertNil([optUnmanaged.doubleObj averageOfProperty:@"self"]);
    XCTAssertNil([optUnmanaged.decimalObj averageOfProperty:@"self"]);
    XCTAssertNil([managed.intObj averageOfProperty:@"self"]);
    XCTAssertNil([managed.floatObj averageOfProperty:@"self"]);
    XCTAssertNil([managed.doubleObj averageOfProperty:@"self"]);
    XCTAssertNil([managed.decimalObj averageOfProperty:@"self"]);
    XCTAssertNil([managed.anyObjB averageOfProperty:@"self"]);
    XCTAssertNil([managed.anyObjC averageOfProperty:@"self"]);
    XCTAssertNil([managed.anyObjD averageOfProperty:@"self"]);
    XCTAssertNil([managed.anyObjH averageOfProperty:@"self"]);
    XCTAssertNil([optManaged.intObj averageOfProperty:@"self"]);
    XCTAssertNil([optManaged.floatObj averageOfProperty:@"self"]);
    XCTAssertNil([optManaged.doubleObj averageOfProperty:@"self"]);
    XCTAssertNil([optManaged.decimalObj averageOfProperty:@"self"]);

    [self addObjects];

    XCTAssertEqualWithAccuracy([unmanaged.intObj averageOfProperty:@"self"].doubleValue, average(@[@2, @3]), .001);
    XCTAssertEqualWithAccuracy([unmanaged.floatObj averageOfProperty:@"self"].doubleValue, average(@[@2.2f, @3.3f]), .001);
    XCTAssertEqualWithAccuracy([unmanaged.doubleObj averageOfProperty:@"self"].doubleValue, average(@[@2.2, @3.3]), .001);
    XCTAssertEqualWithAccuracy([unmanaged.decimalObj averageOfProperty:@"self"].doubleValue, average(@[decimal128(1), decimal128(2)]), .001);
    XCTAssertEqualWithAccuracy([unmanaged.anyObjB averageOfProperty:@"self"].doubleValue, average(@[@2, @3]), .001);
    XCTAssertEqualWithAccuracy([unmanaged.anyObjC averageOfProperty:@"self"].doubleValue, average(@[@2.2f, @3.3f]), .001);
    XCTAssertEqualWithAccuracy([unmanaged.anyObjD averageOfProperty:@"self"].doubleValue, average(@[@2.2, @3.3]), .001);
    XCTAssertEqualWithAccuracy([unmanaged.anyObjH averageOfProperty:@"self"].doubleValue, average(@[decimal128(1), decimal128(2)]), .001);
    XCTAssertEqualWithAccuracy([optUnmanaged.intObj averageOfProperty:@"self"].doubleValue, average(@[NSNull.null, @2, @3]), .001);
    XCTAssertEqualWithAccuracy([optUnmanaged.floatObj averageOfProperty:@"self"].doubleValue, average(@[NSNull.null, @2.2f, @3.3f]), .001);
    XCTAssertEqualWithAccuracy([optUnmanaged.doubleObj averageOfProperty:@"self"].doubleValue, average(@[NSNull.null, @2.2, @3.3]), .001);
    XCTAssertEqualWithAccuracy([optUnmanaged.decimalObj averageOfProperty:@"self"].doubleValue, average(@[NSNull.null, decimal128(1), decimal128(2)]), .001);
    XCTAssertEqualWithAccuracy([managed.intObj averageOfProperty:@"self"].doubleValue, average(@[@2, @3]), .001);
    XCTAssertEqualWithAccuracy([managed.floatObj averageOfProperty:@"self"].doubleValue, average(@[@2.2f, @3.3f]), .001);
    XCTAssertEqualWithAccuracy([managed.doubleObj averageOfProperty:@"self"].doubleValue, average(@[@2.2, @3.3]), .001);
    XCTAssertEqualWithAccuracy([managed.decimalObj averageOfProperty:@"self"].doubleValue, average(@[decimal128(1), decimal128(2)]), .001);
    XCTAssertEqualWithAccuracy([managed.anyObjB averageOfProperty:@"self"].doubleValue, average(@[@2, @3]), .001);
    XCTAssertEqualWithAccuracy([managed.anyObjC averageOfProperty:@"self"].doubleValue, average(@[@2.2f, @3.3f]), .001);
    XCTAssertEqualWithAccuracy([managed.anyObjD averageOfProperty:@"self"].doubleValue, average(@[@2.2, @3.3]), .001);
    XCTAssertEqualWithAccuracy([managed.anyObjH averageOfProperty:@"self"].doubleValue, average(@[decimal128(1), decimal128(2)]), .001);
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
     NSArray *values = @[@NO, @YES]; 
     for (id value in unmanaged.boolObj) { 
     XCTAssertTrue([[NSSet setWithArray:values] containsObject:value]); 
     } 
     } 
    
    { 
     NSArray *values = @[@2, @3]; 
     for (id value in unmanaged.intObj) { 
     XCTAssertTrue([[NSSet setWithArray:values] containsObject:value]); 
     } 
     } 
    
    { 
     NSArray *values = @[@2.2f, @3.3f]; 
     for (id value in unmanaged.floatObj) { 
     XCTAssertTrue([[NSSet setWithArray:values] containsObject:value]); 
     } 
     } 
    
    { 
     NSArray *values = @[@2.2, @3.3]; 
     for (id value in unmanaged.doubleObj) { 
     XCTAssertTrue([[NSSet setWithArray:values] containsObject:value]); 
     } 
     } 
    
    { 
     NSArray *values = @[@"a", @"bc"]; 
     for (id value in unmanaged.stringObj) { 
     XCTAssertTrue([[NSSet setWithArray:values] containsObject:value]); 
     } 
     } 
    
    { 
     NSArray *values = @[data(1), data(2)]; 
     for (id value in unmanaged.dataObj) { 
     XCTAssertTrue([[NSSet setWithArray:values] containsObject:value]); 
     } 
     } 
    
    { 
     NSArray *values = @[date(1), date(2)]; 
     for (id value in unmanaged.dateObj) { 
     XCTAssertTrue([[NSSet setWithArray:values] containsObject:value]); 
     } 
     } 
    
    { 
     NSArray *values = @[decimal128(1), decimal128(2)]; 
     for (id value in unmanaged.decimalObj) { 
     XCTAssertTrue([[NSSet setWithArray:values] containsObject:value]); 
     } 
     } 
    
    { 
     NSArray *values = @[objectId(1), objectId(2)]; 
     for (id value in unmanaged.objectIdObj) { 
     XCTAssertTrue([[NSSet setWithArray:values] containsObject:value]); 
     } 
     } 
    
    { 
     NSArray *values = @[uuid(@"00000000-0000-0000-0000-000000000000"), uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")]; 
     for (id value in unmanaged.uuidObj) { 
     XCTAssertTrue([[NSSet setWithArray:values] containsObject:value]); 
     } 
     } 
    
    { 
     NSArray *values = @[@NO, @YES]; 
     for (id value in unmanaged.anyObjA) { 
     XCTAssertTrue([[NSSet setWithArray:values] containsObject:value]); 
     } 
     } 
    
    { 
     NSArray *values = @[@2, @3]; 
     for (id value in unmanaged.anyObjB) { 
     XCTAssertTrue([[NSSet setWithArray:values] containsObject:value]); 
     } 
     } 
    
    { 
     NSArray *values = @[@2.2f, @3.3f]; 
     for (id value in unmanaged.anyObjC) { 
     XCTAssertTrue([[NSSet setWithArray:values] containsObject:value]); 
     } 
     } 
    
    { 
     NSArray *values = @[@2.2, @3.3]; 
     for (id value in unmanaged.anyObjD) { 
     XCTAssertTrue([[NSSet setWithArray:values] containsObject:value]); 
     } 
     } 
    
    { 
     NSArray *values = @[@"a", @"b"]; 
     for (id value in unmanaged.anyObjE) { 
     XCTAssertTrue([[NSSet setWithArray:values] containsObject:value]); 
     } 
     } 
    
    { 
     NSArray *values = @[data(1), data(2)]; 
     for (id value in unmanaged.anyObjF) { 
     XCTAssertTrue([[NSSet setWithArray:values] containsObject:value]); 
     } 
     } 
    
    { 
     NSArray *values = @[date(1), date(2)]; 
     for (id value in unmanaged.anyObjG) { 
     XCTAssertTrue([[NSSet setWithArray:values] containsObject:value]); 
     } 
     } 
    
    { 
     NSArray *values = @[decimal128(1), decimal128(2)]; 
     for (id value in unmanaged.anyObjH) { 
     XCTAssertTrue([[NSSet setWithArray:values] containsObject:value]); 
     } 
     } 
    
    { 
     NSArray *values = @[objectId(1), objectId(2)]; 
     for (id value in unmanaged.anyObjI) { 
     XCTAssertTrue([[NSSet setWithArray:values] containsObject:value]); 
     } 
     } 
    
    { 
     NSArray *values = @[uuid(@"00000000-0000-0000-0000-000000000000"), uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")]; 
     for (id value in unmanaged.anyObjJ) { 
     XCTAssertTrue([[NSSet setWithArray:values] containsObject:value]); 
     } 
     } 
    
    { 
     NSArray *values = @[NSNull.null, @NO, @YES]; 
     for (id value in optUnmanaged.boolObj) { 
     XCTAssertTrue([[NSSet setWithArray:values] containsObject:value]); 
     } 
     } 
    
    { 
     NSArray *values = @[NSNull.null, @2, @3]; 
     for (id value in optUnmanaged.intObj) { 
     XCTAssertTrue([[NSSet setWithArray:values] containsObject:value]); 
     } 
     } 
    
    { 
     NSArray *values = @[NSNull.null, @2.2f, @3.3f]; 
     for (id value in optUnmanaged.floatObj) { 
     XCTAssertTrue([[NSSet setWithArray:values] containsObject:value]); 
     } 
     } 
    
    { 
     NSArray *values = @[NSNull.null, @2.2, @3.3]; 
     for (id value in optUnmanaged.doubleObj) { 
     XCTAssertTrue([[NSSet setWithArray:values] containsObject:value]); 
     } 
     } 
    
    { 
     NSArray *values = @[NSNull.null, @"a", @"bc"]; 
     for (id value in optUnmanaged.stringObj) { 
     XCTAssertTrue([[NSSet setWithArray:values] containsObject:value]); 
     } 
     } 
    
    { 
     NSArray *values = @[NSNull.null, data(1), data(2)]; 
     for (id value in optUnmanaged.dataObj) { 
     XCTAssertTrue([[NSSet setWithArray:values] containsObject:value]); 
     } 
     } 
    
    { 
     NSArray *values = @[NSNull.null, date(1), date(2)]; 
     for (id value in optUnmanaged.dateObj) { 
     XCTAssertTrue([[NSSet setWithArray:values] containsObject:value]); 
     } 
     } 
    
    { 
     NSArray *values = @[NSNull.null, decimal128(1), decimal128(2)]; 
     for (id value in optUnmanaged.decimalObj) { 
     XCTAssertTrue([[NSSet setWithArray:values] containsObject:value]); 
     } 
     } 
    
    { 
     NSArray *values = @[NSNull.null, objectId(1), objectId(2)]; 
     for (id value in optUnmanaged.objectIdObj) { 
     XCTAssertTrue([[NSSet setWithArray:values] containsObject:value]); 
     } 
     } 
    
    { 
     NSArray *values = @[NSNull.null, uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"), uuid(@"00000000-0000-0000-0000-000000000000")]; 
     for (id value in optUnmanaged.uuidObj) { 
     XCTAssertTrue([[NSSet setWithArray:values] containsObject:value]); 
     } 
     } 
    
    { 
     NSArray *values = @[@NO, @YES]; 
     for (id value in managed.boolObj) { 
     XCTAssertTrue([[NSSet setWithArray:values] containsObject:value]); 
     } 
     } 
    
    { 
     NSArray *values = @[@2, @3]; 
     for (id value in managed.intObj) { 
     XCTAssertTrue([[NSSet setWithArray:values] containsObject:value]); 
     } 
     } 
    
    { 
     NSArray *values = @[@2.2f, @3.3f]; 
     for (id value in managed.floatObj) { 
     XCTAssertTrue([[NSSet setWithArray:values] containsObject:value]); 
     } 
     } 
    
    { 
     NSArray *values = @[@2.2, @3.3]; 
     for (id value in managed.doubleObj) { 
     XCTAssertTrue([[NSSet setWithArray:values] containsObject:value]); 
     } 
     } 
    
    { 
     NSArray *values = @[@"a", @"bc"]; 
     for (id value in managed.stringObj) { 
     XCTAssertTrue([[NSSet setWithArray:values] containsObject:value]); 
     } 
     } 
    
    { 
     NSArray *values = @[data(1), data(2)]; 
     for (id value in managed.dataObj) { 
     XCTAssertTrue([[NSSet setWithArray:values] containsObject:value]); 
     } 
     } 
    
    { 
     NSArray *values = @[date(1), date(2)]; 
     for (id value in managed.dateObj) { 
     XCTAssertTrue([[NSSet setWithArray:values] containsObject:value]); 
     } 
     } 
    
    { 
     NSArray *values = @[decimal128(1), decimal128(2)]; 
     for (id value in managed.decimalObj) { 
     XCTAssertTrue([[NSSet setWithArray:values] containsObject:value]); 
     } 
     } 
    
    { 
     NSArray *values = @[objectId(1), objectId(2)]; 
     for (id value in managed.objectIdObj) { 
     XCTAssertTrue([[NSSet setWithArray:values] containsObject:value]); 
     } 
     } 
    
    { 
     NSArray *values = @[uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"), uuid(@"00000000-0000-0000-0000-000000000000")]; 
     for (id value in managed.uuidObj) { 
     XCTAssertTrue([[NSSet setWithArray:values] containsObject:value]); 
     } 
     } 
    
    { 
     NSArray *values = @[@NO, @YES]; 
     for (id value in managed.anyObjA) { 
     XCTAssertTrue([[NSSet setWithArray:values] containsObject:value]); 
     } 
     } 
    
    { 
     NSArray *values = @[@2, @3]; 
     for (id value in managed.anyObjB) { 
     XCTAssertTrue([[NSSet setWithArray:values] containsObject:value]); 
     } 
     } 
    
    { 
     NSArray *values = @[@2.2f, @3.3f]; 
     for (id value in managed.anyObjC) { 
     XCTAssertTrue([[NSSet setWithArray:values] containsObject:value]); 
     } 
     } 
    
    { 
     NSArray *values = @[@2.2, @3.3]; 
     for (id value in managed.anyObjD) { 
     XCTAssertTrue([[NSSet setWithArray:values] containsObject:value]); 
     } 
     } 
    
    { 
     NSArray *values = @[@"a", @"b"]; 
     for (id value in managed.anyObjE) { 
     XCTAssertTrue([[NSSet setWithArray:values] containsObject:value]); 
     } 
     } 
    
    { 
     NSArray *values = @[data(1), data(2)]; 
     for (id value in managed.anyObjF) { 
     XCTAssertTrue([[NSSet setWithArray:values] containsObject:value]); 
     } 
     } 
    
    { 
     NSArray *values = @[date(1), date(2)]; 
     for (id value in managed.anyObjG) { 
     XCTAssertTrue([[NSSet setWithArray:values] containsObject:value]); 
     } 
     } 
    
    { 
     NSArray *values = @[decimal128(1), decimal128(2)]; 
     for (id value in managed.anyObjH) { 
     XCTAssertTrue([[NSSet setWithArray:values] containsObject:value]); 
     } 
     } 
    
    { 
     NSArray *values = @[objectId(1), objectId(2)]; 
     for (id value in managed.anyObjI) { 
     XCTAssertTrue([[NSSet setWithArray:values] containsObject:value]); 
     } 
     } 
    
    { 
     NSArray *values = @[uuid(@"00000000-0000-0000-0000-000000000000"), uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")]; 
     for (id value in managed.anyObjJ) { 
     XCTAssertTrue([[NSSet setWithArray:values] containsObject:value]); 
     } 
     } 
    
    { 
     NSArray *values = @[NSNull.null, @NO, @YES]; 
     for (id value in optManaged.boolObj) { 
     XCTAssertTrue([[NSSet setWithArray:values] containsObject:value]); 
     } 
     } 
    
    { 
     NSArray *values = @[NSNull.null, @2, @3]; 
     for (id value in optManaged.intObj) { 
     XCTAssertTrue([[NSSet setWithArray:values] containsObject:value]); 
     } 
     } 
    
    { 
     NSArray *values = @[NSNull.null, @2.2f, @3.3f]; 
     for (id value in optManaged.floatObj) { 
     XCTAssertTrue([[NSSet setWithArray:values] containsObject:value]); 
     } 
     } 
    
    { 
     NSArray *values = @[NSNull.null, @2.2, @3.3]; 
     for (id value in optManaged.doubleObj) { 
     XCTAssertTrue([[NSSet setWithArray:values] containsObject:value]); 
     } 
     } 
    
    { 
     NSArray *values = @[NSNull.null, @"a", @"bc"]; 
     for (id value in optManaged.stringObj) { 
     XCTAssertTrue([[NSSet setWithArray:values] containsObject:value]); 
     } 
     } 
    
    { 
     NSArray *values = @[NSNull.null, data(1), data(2)]; 
     for (id value in optManaged.dataObj) { 
     XCTAssertTrue([[NSSet setWithArray:values] containsObject:value]); 
     } 
     } 
    
    { 
     NSArray *values = @[NSNull.null, date(1), date(2)]; 
     for (id value in optManaged.dateObj) { 
     XCTAssertTrue([[NSSet setWithArray:values] containsObject:value]); 
     } 
     } 
    
    { 
     NSArray *values = @[NSNull.null, decimal128(1), decimal128(2)]; 
     for (id value in optManaged.decimalObj) { 
     XCTAssertTrue([[NSSet setWithArray:values] containsObject:value]); 
     } 
     } 
    
    { 
     NSArray *values = @[NSNull.null, objectId(1), objectId(2)]; 
     for (id value in optManaged.objectIdObj) { 
     XCTAssertTrue([[NSSet setWithArray:values] containsObject:value]); 
     } 
     } 
    
    { 
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
    XCTAssertEqualObjects([NSSet setWithArray:[[unmanaged.anyObjA valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[@NO, @YES]]));
    XCTAssertEqualObjects([NSSet setWithArray:[[unmanaged.anyObjB valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[@2, @3]]));
    XCTAssertEqualObjects([NSSet setWithArray:[[unmanaged.anyObjC valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[@2.2f, @3.3f]]));
    XCTAssertEqualObjects([NSSet setWithArray:[[unmanaged.anyObjD valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[@2.2, @3.3]]));
    XCTAssertEqualObjects([NSSet setWithArray:[[unmanaged.anyObjE valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[@"a", @"b"]]));
    XCTAssertEqualObjects([NSSet setWithArray:[[unmanaged.anyObjF valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[data(1), data(2)]]));
    XCTAssertEqualObjects([NSSet setWithArray:[[unmanaged.anyObjG valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[date(1), date(2)]]));
    XCTAssertEqualObjects([NSSet setWithArray:[[unmanaged.anyObjH valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[decimal128(1), decimal128(2)]]));
    XCTAssertEqualObjects([NSSet setWithArray:[[unmanaged.anyObjI valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[objectId(1), objectId(2)]]));
    XCTAssertEqualObjects([NSSet setWithArray:[[unmanaged.anyObjJ valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[uuid(@"00000000-0000-0000-0000-000000000000"), uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")]]));
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
    XCTAssertEqualObjects([NSSet setWithArray:[[managed.anyObjA valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[@NO, @YES]]));
    XCTAssertEqualObjects([NSSet setWithArray:[[managed.anyObjB valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[@2, @3]]));
    XCTAssertEqualObjects([NSSet setWithArray:[[managed.anyObjC valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[@2.2f, @3.3f]]));
    XCTAssertEqualObjects([NSSet setWithArray:[[managed.anyObjD valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[@2.2, @3.3]]));
    XCTAssertEqualObjects([NSSet setWithArray:[[managed.anyObjE valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[@"a", @"b"]]));
    XCTAssertEqualObjects([NSSet setWithArray:[[managed.anyObjF valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[data(1), data(2)]]));
    XCTAssertEqualObjects([NSSet setWithArray:[[managed.anyObjG valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[date(1), date(2)]]));
    XCTAssertEqualObjects([NSSet setWithArray:[[managed.anyObjH valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[decimal128(1), decimal128(2)]]));
    XCTAssertEqualObjects([NSSet setWithArray:[[managed.anyObjI valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[objectId(1), objectId(2)]]));
    XCTAssertEqualObjects([NSSet setWithArray:[[managed.anyObjJ valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[uuid(@"00000000-0000-0000-0000-000000000000"), uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")]]));
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
    XCTAssertNil([unmanaged.anyObjC valueForKeyPath:@"@min.self"]);
    XCTAssertNil([unmanaged.anyObjD valueForKeyPath:@"@min.self"]);
    XCTAssertNil([unmanaged.anyObjG valueForKeyPath:@"@min.self"]);
    XCTAssertNil([unmanaged.anyObjH valueForKeyPath:@"@min.self"]);
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
    XCTAssertNil([managed.anyObjB valueForKeyPath:@"@min.self"]);
    XCTAssertNil([managed.anyObjC valueForKeyPath:@"@min.self"]);
    XCTAssertNil([managed.anyObjD valueForKeyPath:@"@min.self"]);
    XCTAssertNil([managed.anyObjG valueForKeyPath:@"@min.self"]);
    XCTAssertNil([managed.anyObjH valueForKeyPath:@"@min.self"]);
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
    XCTAssertNil([unmanaged.anyObjC valueForKeyPath:@"@max.self"]);
    XCTAssertNil([unmanaged.anyObjD valueForKeyPath:@"@max.self"]);
    XCTAssertNil([unmanaged.anyObjG valueForKeyPath:@"@max.self"]);
    XCTAssertNil([unmanaged.anyObjH valueForKeyPath:@"@max.self"]);
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
    XCTAssertNil([managed.anyObjB valueForKeyPath:@"@max.self"]);
    XCTAssertNil([managed.anyObjC valueForKeyPath:@"@max.self"]);
    XCTAssertNil([managed.anyObjD valueForKeyPath:@"@max.self"]);
    XCTAssertNil([managed.anyObjG valueForKeyPath:@"@max.self"]);
    XCTAssertNil([managed.anyObjH valueForKeyPath:@"@max.self"]);
    XCTAssertNil([optManaged.intObj valueForKeyPath:@"@max.self"]);
    XCTAssertNil([optManaged.floatObj valueForKeyPath:@"@max.self"]);
    XCTAssertNil([optManaged.doubleObj valueForKeyPath:@"@max.self"]);
    XCTAssertNil([optManaged.dateObj valueForKeyPath:@"@max.self"]);
    XCTAssertNil([optManaged.decimalObj valueForKeyPath:@"@max.self"]);
    XCTAssertEqualObjects([unmanaged.intObj valueForKeyPath:@"@sum.self"], @0);
    XCTAssertEqualObjects([unmanaged.floatObj valueForKeyPath:@"@sum.self"], @0);
    XCTAssertEqualObjects([unmanaged.doubleObj valueForKeyPath:@"@sum.self"], @0);
    XCTAssertEqualObjects([unmanaged.decimalObj valueForKeyPath:@"@sum.self"], @0);
    XCTAssertEqualObjects([unmanaged.anyObjB valueForKeyPath:@"@sum.self"], @0);
    XCTAssertEqualObjects([unmanaged.anyObjC valueForKeyPath:@"@sum.self"], @0);
    XCTAssertEqualObjects([unmanaged.anyObjD valueForKeyPath:@"@sum.self"], @0);
    XCTAssertEqualObjects([unmanaged.anyObjH valueForKeyPath:@"@sum.self"], @0);
    XCTAssertEqualObjects([optUnmanaged.intObj valueForKeyPath:@"@sum.self"], @0);
    XCTAssertEqualObjects([optUnmanaged.floatObj valueForKeyPath:@"@sum.self"], @0);
    XCTAssertEqualObjects([optUnmanaged.doubleObj valueForKeyPath:@"@sum.self"], @0);
    XCTAssertEqualObjects([optUnmanaged.decimalObj valueForKeyPath:@"@sum.self"], @0);
    XCTAssertEqualObjects([managed.intObj valueForKeyPath:@"@sum.self"], @0);
    XCTAssertEqualObjects([managed.floatObj valueForKeyPath:@"@sum.self"], @0);
    XCTAssertEqualObjects([managed.doubleObj valueForKeyPath:@"@sum.self"], @0);
    XCTAssertEqualObjects([managed.decimalObj valueForKeyPath:@"@sum.self"], @0);
    XCTAssertEqualObjects([managed.anyObjB valueForKeyPath:@"@sum.self"], @0);
    XCTAssertEqualObjects([managed.anyObjC valueForKeyPath:@"@sum.self"], @0);
    XCTAssertEqualObjects([managed.anyObjD valueForKeyPath:@"@sum.self"], @0);
    XCTAssertEqualObjects([managed.anyObjH valueForKeyPath:@"@sum.self"], @0);
    XCTAssertEqualObjects([optManaged.intObj valueForKeyPath:@"@sum.self"], @0);
    XCTAssertEqualObjects([optManaged.floatObj valueForKeyPath:@"@sum.self"], @0);
    XCTAssertEqualObjects([optManaged.doubleObj valueForKeyPath:@"@sum.self"], @0);
    XCTAssertEqualObjects([optManaged.decimalObj valueForKeyPath:@"@sum.self"], @0);
    XCTAssertNil([unmanaged.intObj valueForKeyPath:@"@avg.self"]);
    XCTAssertNil([unmanaged.floatObj valueForKeyPath:@"@avg.self"]);
    XCTAssertNil([unmanaged.doubleObj valueForKeyPath:@"@avg.self"]);
    XCTAssertNil([unmanaged.decimalObj valueForKeyPath:@"@avg.self"]);
    XCTAssertNil([unmanaged.anyObjB valueForKeyPath:@"@avg.self"]);
    XCTAssertNil([unmanaged.anyObjC valueForKeyPath:@"@avg.self"]);
    XCTAssertNil([unmanaged.anyObjD valueForKeyPath:@"@avg.self"]);
    XCTAssertNil([unmanaged.anyObjH valueForKeyPath:@"@avg.self"]);
    XCTAssertNil([optUnmanaged.intObj valueForKeyPath:@"@avg.self"]);
    XCTAssertNil([optUnmanaged.floatObj valueForKeyPath:@"@avg.self"]);
    XCTAssertNil([optUnmanaged.doubleObj valueForKeyPath:@"@avg.self"]);
    XCTAssertNil([optUnmanaged.decimalObj valueForKeyPath:@"@avg.self"]);
    XCTAssertNil([managed.intObj valueForKeyPath:@"@avg.self"]);
    XCTAssertNil([managed.floatObj valueForKeyPath:@"@avg.self"]);
    XCTAssertNil([managed.doubleObj valueForKeyPath:@"@avg.self"]);
    XCTAssertNil([managed.decimalObj valueForKeyPath:@"@avg.self"]);
    XCTAssertNil([managed.anyObjB valueForKeyPath:@"@avg.self"]);
    XCTAssertNil([managed.anyObjC valueForKeyPath:@"@avg.self"]);
    XCTAssertNil([managed.anyObjD valueForKeyPath:@"@avg.self"]);
    XCTAssertNil([managed.anyObjH valueForKeyPath:@"@avg.self"]);
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
    XCTAssertEqualObjects([unmanaged.anyObjC valueForKeyPath:@"@min.self"], @2.2f);
    XCTAssertEqualObjects([unmanaged.anyObjD valueForKeyPath:@"@min.self"], @2.2);
    XCTAssertEqualObjects([unmanaged.anyObjG valueForKeyPath:@"@min.self"], date(1));
    XCTAssertEqualObjects([unmanaged.anyObjH valueForKeyPath:@"@min.self"], decimal128(1));
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
    XCTAssertEqualObjects([managed.anyObjB valueForKeyPath:@"@min.self"], @2);
    XCTAssertEqualObjects([managed.anyObjC valueForKeyPath:@"@min.self"], @2.2f);
    XCTAssertEqualObjects([managed.anyObjD valueForKeyPath:@"@min.self"], @2.2);
    XCTAssertEqualObjects([managed.anyObjG valueForKeyPath:@"@min.self"], date(1));
    XCTAssertEqualObjects([managed.anyObjH valueForKeyPath:@"@min.self"], decimal128(1));
    XCTAssertEqualObjects([optManaged.intObj valueForKeyPath:@"@max.self"], @3);
    XCTAssertEqualObjects([optManaged.floatObj valueForKeyPath:@"@max.self"], @3.3f);
    XCTAssertEqualObjects([optManaged.doubleObj valueForKeyPath:@"@max.self"], @3.3);
    XCTAssertEqualObjects([optManaged.dateObj valueForKeyPath:@"@max.self"], date(2));
    XCTAssertEqualObjects([optManaged.decimalObj valueForKeyPath:@"@max.self"], decimal128(2));

    XCTAssertEqualWithAccuracy([[unmanaged.intObj valueForKeyPath:@"@sum.self"] doubleValue], sum(@[@2, @3]), .001);
    XCTAssertEqualWithAccuracy([[unmanaged.floatObj valueForKeyPath:@"@sum.self"] doubleValue], sum(@[@2.2f, @3.3f]), .001);
    XCTAssertEqualWithAccuracy([[unmanaged.doubleObj valueForKeyPath:@"@sum.self"] doubleValue], sum(@[@2.2, @3.3]), .001);
    XCTAssertEqualWithAccuracy([[unmanaged.decimalObj valueForKeyPath:@"@sum.self"] doubleValue], sum(@[decimal128(1), decimal128(2)]), .001);
    XCTAssertEqualWithAccuracy([[unmanaged.anyObjB valueForKeyPath:@"@sum.self"] doubleValue], sum(@[@2, @3]), .001);
    XCTAssertEqualWithAccuracy([[unmanaged.anyObjC valueForKeyPath:@"@sum.self"] doubleValue], sum(@[@2.2f, @3.3f]), .001);
    XCTAssertEqualWithAccuracy([[unmanaged.anyObjD valueForKeyPath:@"@sum.self"] doubleValue], sum(@[@2.2, @3.3]), .001);
    XCTAssertEqualWithAccuracy([[unmanaged.anyObjH valueForKeyPath:@"@sum.self"] doubleValue], sum(@[decimal128(1), decimal128(2)]), .001);
    XCTAssertEqualWithAccuracy([[optUnmanaged.intObj valueForKeyPath:@"@sum.self"] doubleValue], sum(@[NSNull.null, @2, @3]), .001);
    XCTAssertEqualWithAccuracy([[optUnmanaged.floatObj valueForKeyPath:@"@sum.self"] doubleValue], sum(@[NSNull.null, @2.2f, @3.3f]), .001);
    XCTAssertEqualWithAccuracy([[optUnmanaged.doubleObj valueForKeyPath:@"@sum.self"] doubleValue], sum(@[NSNull.null, @2.2, @3.3]), .001);
    XCTAssertEqualWithAccuracy([[optUnmanaged.decimalObj valueForKeyPath:@"@sum.self"] doubleValue], sum(@[NSNull.null, decimal128(1), decimal128(2)]), .001);
    XCTAssertEqualWithAccuracy([[managed.intObj valueForKeyPath:@"@sum.self"] doubleValue], sum(@[@2, @3]), .001);
    XCTAssertEqualWithAccuracy([[managed.floatObj valueForKeyPath:@"@sum.self"] doubleValue], sum(@[@2.2f, @3.3f]), .001);
    XCTAssertEqualWithAccuracy([[managed.doubleObj valueForKeyPath:@"@sum.self"] doubleValue], sum(@[@2.2, @3.3]), .001);
    XCTAssertEqualWithAccuracy([[managed.decimalObj valueForKeyPath:@"@sum.self"] doubleValue], sum(@[decimal128(1), decimal128(2)]), .001);
    XCTAssertEqualWithAccuracy([[managed.anyObjB valueForKeyPath:@"@sum.self"] doubleValue], sum(@[@2, @3]), .001);
    XCTAssertEqualWithAccuracy([[managed.anyObjC valueForKeyPath:@"@sum.self"] doubleValue], sum(@[@2.2f, @3.3f]), .001);
    XCTAssertEqualWithAccuracy([[managed.anyObjD valueForKeyPath:@"@sum.self"] doubleValue], sum(@[@2.2, @3.3]), .001);
    XCTAssertEqualWithAccuracy([[managed.anyObjH valueForKeyPath:@"@sum.self"] doubleValue], sum(@[decimal128(1), decimal128(2)]), .001);
    XCTAssertEqualWithAccuracy([[optManaged.intObj valueForKeyPath:@"@sum.self"] doubleValue], sum(@[NSNull.null, @2, @3]), .001);
    XCTAssertEqualWithAccuracy([[optManaged.floatObj valueForKeyPath:@"@sum.self"] doubleValue], sum(@[NSNull.null, @2.2f, @3.3f]), .001);
    XCTAssertEqualWithAccuracy([[optManaged.doubleObj valueForKeyPath:@"@sum.self"] doubleValue], sum(@[NSNull.null, @2.2, @3.3]), .001);
    XCTAssertEqualWithAccuracy([[optManaged.decimalObj valueForKeyPath:@"@sum.self"] doubleValue], sum(@[NSNull.null, decimal128(1), decimal128(2)]), .001);
    XCTAssertEqualWithAccuracy([[unmanaged.intObj valueForKeyPath:@"@avg.self"] doubleValue], average(@[@2, @3]), .001);
    XCTAssertEqualWithAccuracy([[unmanaged.floatObj valueForKeyPath:@"@avg.self"] doubleValue], average(@[@2.2f, @3.3f]), .001);
    XCTAssertEqualWithAccuracy([[unmanaged.doubleObj valueForKeyPath:@"@avg.self"] doubleValue], average(@[@2.2, @3.3]), .001);
    XCTAssertEqualWithAccuracy([[unmanaged.decimalObj valueForKeyPath:@"@avg.self"] doubleValue], average(@[decimal128(1), decimal128(2)]), .001);
    XCTAssertEqualWithAccuracy([[unmanaged.anyObjB valueForKeyPath:@"@avg.self"] doubleValue], average(@[@2, @3]), .001);
    XCTAssertEqualWithAccuracy([[unmanaged.anyObjC valueForKeyPath:@"@avg.self"] doubleValue], average(@[@2.2f, @3.3f]), .001);
    XCTAssertEqualWithAccuracy([[unmanaged.anyObjD valueForKeyPath:@"@avg.self"] doubleValue], average(@[@2.2, @3.3]), .001);
    XCTAssertEqualWithAccuracy([[unmanaged.anyObjH valueForKeyPath:@"@avg.self"] doubleValue], average(@[decimal128(1), decimal128(2)]), .001);
    XCTAssertEqualWithAccuracy([[optUnmanaged.intObj valueForKeyPath:@"@avg.self"] doubleValue], average(@[NSNull.null, @2, @3]), .001);
    XCTAssertEqualWithAccuracy([[optUnmanaged.floatObj valueForKeyPath:@"@avg.self"] doubleValue], average(@[NSNull.null, @2.2f, @3.3f]), .001);
    XCTAssertEqualWithAccuracy([[optUnmanaged.doubleObj valueForKeyPath:@"@avg.self"] doubleValue], average(@[NSNull.null, @2.2, @3.3]), .001);
    XCTAssertEqualWithAccuracy([[optUnmanaged.decimalObj valueForKeyPath:@"@avg.self"] doubleValue], average(@[NSNull.null, decimal128(1), decimal128(2)]), .001);
    XCTAssertEqualWithAccuracy([[managed.intObj valueForKeyPath:@"@avg.self"] doubleValue], average(@[@2, @3]), .001);
    XCTAssertEqualWithAccuracy([[managed.floatObj valueForKeyPath:@"@avg.self"] doubleValue], average(@[@2.2f, @3.3f]), .001);
    XCTAssertEqualWithAccuracy([[managed.doubleObj valueForKeyPath:@"@avg.self"] doubleValue], average(@[@2.2, @3.3]), .001);
    XCTAssertEqualWithAccuracy([[managed.decimalObj valueForKeyPath:@"@avg.self"] doubleValue], average(@[decimal128(1), decimal128(2)]), .001);
    XCTAssertEqualWithAccuracy([[managed.anyObjB valueForKeyPath:@"@avg.self"] doubleValue], average(@[@2, @3]), .001);
    XCTAssertEqualWithAccuracy([[managed.anyObjC valueForKeyPath:@"@avg.self"] doubleValue], average(@[@2.2f, @3.3f]), .001);
    XCTAssertEqualWithAccuracy([[managed.anyObjD valueForKeyPath:@"@avg.self"] doubleValue], average(@[@2.2, @3.3]), .001);
    XCTAssertEqualWithAccuracy([[managed.anyObjH valueForKeyPath:@"@avg.self"] doubleValue], average(@[decimal128(1), decimal128(2)]), .001);
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
    XCTAssertEqualObjects([unmanaged.anyObjE valueForKey:@"length"], ([[NSSet setWithArray:@[@"a", @"b"]] valueForKey:@"length"]));
    XCTAssertEqualObjects([optUnmanaged.stringObj valueForKey:@"length"], ([[NSSet setWithArray:@[NSNull.null, @"a", @"bc"]] valueForKey:@"length"]));
    XCTAssertEqualObjects([managed.stringObj valueForKey:@"length"], ([[NSSet setWithArray:@[@"a", @"bc"]] valueForKey:@"length"]));
    XCTAssertEqualObjects([managed.anyObjE valueForKey:@"length"], ([[NSSet setWithArray:@[@"a", @"b"]] valueForKey:@"length"]));
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
    [unmanaged.anyObjA setValue:@NO forKey:@"self"];
    [unmanaged.anyObjB setValue:@2 forKey:@"self"];
    [unmanaged.anyObjC setValue:@2.2f forKey:@"self"];
    [unmanaged.anyObjD setValue:@2.2 forKey:@"self"];
    [unmanaged.anyObjE setValue:@"a" forKey:@"self"];
    [unmanaged.anyObjF setValue:data(1) forKey:@"self"];
    [unmanaged.anyObjG setValue:date(1) forKey:@"self"];
    [unmanaged.anyObjH setValue:decimal128(1) forKey:@"self"];
    [unmanaged.anyObjI setValue:objectId(1) forKey:@"self"];
    [unmanaged.anyObjJ setValue:uuid(@"00000000-0000-0000-0000-000000000000") forKey:@"self"];
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
    [managed.anyObjA setValue:@NO forKey:@"self"];
    [managed.anyObjB setValue:@2 forKey:@"self"];
    [managed.anyObjC setValue:@2.2f forKey:@"self"];
    [managed.anyObjD setValue:@2.2 forKey:@"self"];
    [managed.anyObjE setValue:@"a" forKey:@"self"];
    [managed.anyObjF setValue:data(1) forKey:@"self"];
    [managed.anyObjG setValue:date(1) forKey:@"self"];
    [managed.anyObjH setValue:decimal128(1) forKey:@"self"];
    [managed.anyObjI setValue:objectId(1) forKey:@"self"];
    [managed.anyObjJ setValue:uuid(@"00000000-0000-0000-0000-000000000000") forKey:@"self"];
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
    RLMAssertThrowsWithReason(unmanaged.anyObjA.allObjects[1], @"index 1 beyond bounds [0 .. 0]");
    RLMAssertThrowsWithReason(unmanaged.anyObjB.allObjects[1], @"index 1 beyond bounds [0 .. 0]");
    RLMAssertThrowsWithReason(unmanaged.anyObjC.allObjects[1], @"index 1 beyond bounds [0 .. 0]");
    RLMAssertThrowsWithReason(unmanaged.anyObjD.allObjects[1], @"index 1 beyond bounds [0 .. 0]");
    RLMAssertThrowsWithReason(unmanaged.anyObjE.allObjects[1], @"index 1 beyond bounds [0 .. 0]");
    RLMAssertThrowsWithReason(unmanaged.anyObjF.allObjects[1], @"index 1 beyond bounds [0 .. 0]");
    RLMAssertThrowsWithReason(unmanaged.anyObjG.allObjects[1], @"index 1 beyond bounds [0 .. 0]");
    RLMAssertThrowsWithReason(unmanaged.anyObjH.allObjects[1], @"index 1 beyond bounds [0 .. 0]");
    RLMAssertThrowsWithReason(unmanaged.anyObjI.allObjects[1], @"index 1 beyond bounds [0 .. 0]");
    RLMAssertThrowsWithReason(unmanaged.anyObjJ.allObjects[1], @"index 1 beyond bounds [0 .. 0]");
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
    RLMAssertThrowsWithReason(managed.anyObjA.allObjects[1], @"index 1 beyond bounds [0 .. 0]");
    RLMAssertThrowsWithReason(managed.anyObjB.allObjects[1], @"index 1 beyond bounds [0 .. 0]");
    RLMAssertThrowsWithReason(managed.anyObjC.allObjects[1], @"index 1 beyond bounds [0 .. 0]");
    RLMAssertThrowsWithReason(managed.anyObjD.allObjects[1], @"index 1 beyond bounds [0 .. 0]");
    RLMAssertThrowsWithReason(managed.anyObjE.allObjects[1], @"index 1 beyond bounds [0 .. 0]");
    RLMAssertThrowsWithReason(managed.anyObjF.allObjects[1], @"index 1 beyond bounds [0 .. 0]");
    RLMAssertThrowsWithReason(managed.anyObjG.allObjects[1], @"index 1 beyond bounds [0 .. 0]");
    RLMAssertThrowsWithReason(managed.anyObjH.allObjects[1], @"index 1 beyond bounds [0 .. 0]");
    RLMAssertThrowsWithReason(managed.anyObjI.allObjects[1], @"index 1 beyond bounds [0 .. 0]");
    RLMAssertThrowsWithReason(managed.anyObjJ.allObjects[1], @"index 1 beyond bounds [0 .. 0]");
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
    XCTAssertEqualObjects(unmanaged.anyObjA.allObjects[0], @NO);
    XCTAssertEqualObjects(unmanaged.anyObjB.allObjects[0], @2);
    XCTAssertEqualObjects(unmanaged.anyObjC.allObjects[0], @2.2f);
    XCTAssertEqualObjects(unmanaged.anyObjD.allObjects[0], @2.2);
    XCTAssertEqualObjects(unmanaged.anyObjE.allObjects[0], @"a");
    XCTAssertEqualObjects(unmanaged.anyObjF.allObjects[0], data(1));
    XCTAssertEqualObjects(unmanaged.anyObjG.allObjects[0], date(1));
    XCTAssertEqualObjects(unmanaged.anyObjH.allObjects[0], decimal128(1));
    XCTAssertEqualObjects(unmanaged.anyObjI.allObjects[0], objectId(1));
    XCTAssertEqualObjects(unmanaged.anyObjJ.allObjects[0], uuid(@"00000000-0000-0000-0000-000000000000"));
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
    XCTAssertEqualObjects(managed.anyObjA.allObjects[0], @NO);
    XCTAssertEqualObjects(managed.anyObjB.allObjects[0], @2);
    XCTAssertEqualObjects(managed.anyObjC.allObjects[0], @2.2f);
    XCTAssertEqualObjects(managed.anyObjD.allObjects[0], @2.2);
    XCTAssertEqualObjects(managed.anyObjE.allObjects[0], @"a");
    XCTAssertEqualObjects(managed.anyObjF.allObjects[0], data(1));
    XCTAssertEqualObjects(managed.anyObjG.allObjects[0], date(1));
    XCTAssertEqualObjects(managed.anyObjH.allObjects[0], decimal128(1));
    XCTAssertEqualObjects(managed.anyObjI.allObjects[0], objectId(1));
    XCTAssertEqualObjects(managed.anyObjJ.allObjects[0], uuid(@"00000000-0000-0000-0000-000000000000"));
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
    unmanaged.anyObjA = (id)@[@YES]; 
     XCTAssertEqualObjects(unmanaged.anyObjA.allObjects[0], @YES);
    unmanaged.anyObjB = (id)@[@3]; 
     XCTAssertEqualObjects(unmanaged.anyObjB.allObjects[0], @3);
    unmanaged.anyObjC = (id)@[@3.3f]; 
     XCTAssertEqualObjects(unmanaged.anyObjC.allObjects[0], @3.3f);
    unmanaged.anyObjD = (id)@[@3.3]; 
     XCTAssertEqualObjects(unmanaged.anyObjD.allObjects[0], @3.3);
    unmanaged.anyObjE = (id)@[@"b"]; 
     XCTAssertEqualObjects(unmanaged.anyObjE.allObjects[0], @"b");
    unmanaged.anyObjF = (id)@[data(2)]; 
     XCTAssertEqualObjects(unmanaged.anyObjF.allObjects[0], data(2));
    unmanaged.anyObjG = (id)@[date(2)]; 
     XCTAssertEqualObjects(unmanaged.anyObjG.allObjects[0], date(2));
    unmanaged.anyObjH = (id)@[decimal128(2)]; 
     XCTAssertEqualObjects(unmanaged.anyObjH.allObjects[0], decimal128(2));
    unmanaged.anyObjI = (id)@[objectId(2)]; 
     XCTAssertEqualObjects(unmanaged.anyObjI.allObjects[0], objectId(2));
    unmanaged.anyObjJ = (id)@[uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")]; 
     XCTAssertEqualObjects(unmanaged.anyObjJ.allObjects[0], uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"));
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
    managed.anyObjA = (id)@[@YES]; 
     XCTAssertEqualObjects(managed.anyObjA.allObjects[0], @YES);
    managed.anyObjB = (id)@[@3]; 
     XCTAssertEqualObjects(managed.anyObjB.allObjects[0], @3);
    managed.anyObjC = (id)@[@3.3f]; 
     XCTAssertEqualObjects(managed.anyObjC.allObjects[0], @3.3f);
    managed.anyObjD = (id)@[@3.3]; 
     XCTAssertEqualObjects(managed.anyObjD.allObjects[0], @3.3);
    managed.anyObjE = (id)@[@"b"]; 
     XCTAssertEqualObjects(managed.anyObjE.allObjects[0], @"b");
    managed.anyObjF = (id)@[data(2)]; 
     XCTAssertEqualObjects(managed.anyObjF.allObjects[0], data(2));
    managed.anyObjG = (id)@[date(2)]; 
     XCTAssertEqualObjects(managed.anyObjG.allObjects[0], date(2));
    managed.anyObjH = (id)@[decimal128(2)]; 
     XCTAssertEqualObjects(managed.anyObjH.allObjects[0], decimal128(2));
    managed.anyObjI = (id)@[objectId(2)]; 
     XCTAssertEqualObjects(managed.anyObjI.allObjects[0], objectId(2));
    managed.anyObjJ = (id)@[uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")]; 
     XCTAssertEqualObjects(managed.anyObjJ.allObjects[0], uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"));
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
    
    unmanaged.anyObjA = (id)@[@NO, @YES]; 
     XCTAssertEqualObjects([NSSet setWithArray:[[unmanaged.anyObjA valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[@NO, @YES]])); 
    
    unmanaged.anyObjB = (id)@[@2, @3]; 
     XCTAssertEqualObjects([NSSet setWithArray:[[unmanaged.anyObjB valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[@2, @3]])); 
    
    unmanaged.anyObjC = (id)@[@2.2f, @3.3f]; 
     XCTAssertEqualObjects([NSSet setWithArray:[[unmanaged.anyObjC valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[@2.2f, @3.3f]])); 
    
    unmanaged.anyObjD = (id)@[@2.2, @3.3]; 
     XCTAssertEqualObjects([NSSet setWithArray:[[unmanaged.anyObjD valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[@2.2, @3.3]])); 
    
    unmanaged.anyObjE = (id)@[@"a", @"b"]; 
     XCTAssertEqualObjects([NSSet setWithArray:[[unmanaged.anyObjE valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[@"a", @"b"]])); 
    
    unmanaged.anyObjF = (id)@[data(1), data(2)]; 
     XCTAssertEqualObjects([NSSet setWithArray:[[unmanaged.anyObjF valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[data(1), data(2)]])); 
    
    unmanaged.anyObjG = (id)@[date(1), date(2)]; 
     XCTAssertEqualObjects([NSSet setWithArray:[[unmanaged.anyObjG valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[date(1), date(2)]])); 
    
    unmanaged.anyObjH = (id)@[decimal128(1), decimal128(2)]; 
     XCTAssertEqualObjects([NSSet setWithArray:[[unmanaged.anyObjH valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[decimal128(1), decimal128(2)]])); 
    
    unmanaged.anyObjI = (id)@[objectId(1), objectId(2)]; 
     XCTAssertEqualObjects([NSSet setWithArray:[[unmanaged.anyObjI valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[objectId(1), objectId(2)]])); 
    
    unmanaged.anyObjJ = (id)@[uuid(@"00000000-0000-0000-0000-000000000000"), uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")]; 
     XCTAssertEqualObjects([NSSet setWithArray:[[unmanaged.anyObjJ valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[uuid(@"00000000-0000-0000-0000-000000000000"), uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")]])); 
    
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
    
    managed.anyObjA = (id)@[@NO, @YES]; 
     XCTAssertEqualObjects([NSSet setWithArray:[[managed.anyObjA valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[@NO, @YES]])); 
    
    managed.anyObjB = (id)@[@2, @3]; 
     XCTAssertEqualObjects([NSSet setWithArray:[[managed.anyObjB valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[@2, @3]])); 
    
    managed.anyObjC = (id)@[@2.2f, @3.3f]; 
     XCTAssertEqualObjects([NSSet setWithArray:[[managed.anyObjC valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[@2.2f, @3.3f]])); 
    
    managed.anyObjD = (id)@[@2.2, @3.3]; 
     XCTAssertEqualObjects([NSSet setWithArray:[[managed.anyObjD valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[@2.2, @3.3]])); 
    
    managed.anyObjE = (id)@[@"a", @"b"]; 
     XCTAssertEqualObjects([NSSet setWithArray:[[managed.anyObjE valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[@"a", @"b"]])); 
    
    managed.anyObjF = (id)@[data(1), data(2)]; 
     XCTAssertEqualObjects([NSSet setWithArray:[[managed.anyObjF valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[data(1), data(2)]])); 
    
    managed.anyObjG = (id)@[date(1), date(2)]; 
     XCTAssertEqualObjects([NSSet setWithArray:[[managed.anyObjG valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[date(1), date(2)]])); 
    
    managed.anyObjH = (id)@[decimal128(1), decimal128(2)]; 
     XCTAssertEqualObjects([NSSet setWithArray:[[managed.anyObjH valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[decimal128(1), decimal128(2)]])); 
    
    managed.anyObjI = (id)@[objectId(1), objectId(2)]; 
     XCTAssertEqualObjects([NSSet setWithArray:[[managed.anyObjI valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[objectId(1), objectId(2)]])); 
    
    managed.anyObjJ = (id)@[uuid(@"00000000-0000-0000-0000-000000000000"), uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")]; 
     XCTAssertEqualObjects([NSSet setWithArray:[[managed.anyObjJ valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[uuid(@"00000000-0000-0000-0000-000000000000"), uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")]])); 
    
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
    
    unmanaged.anyObjA = unmanaged.anyObjA; 
     XCTAssertEqualObjects([NSSet setWithArray:[[unmanaged.anyObjA valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[@NO, @YES]])); 
    
    unmanaged.anyObjB = unmanaged.anyObjB; 
     XCTAssertEqualObjects([NSSet setWithArray:[[unmanaged.anyObjB valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[@2, @3]])); 
    
    unmanaged.anyObjC = unmanaged.anyObjC; 
     XCTAssertEqualObjects([NSSet setWithArray:[[unmanaged.anyObjC valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[@2.2f, @3.3f]])); 
    
    unmanaged.anyObjD = unmanaged.anyObjD; 
     XCTAssertEqualObjects([NSSet setWithArray:[[unmanaged.anyObjD valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[@2.2, @3.3]])); 
    
    unmanaged.anyObjE = unmanaged.anyObjE; 
     XCTAssertEqualObjects([NSSet setWithArray:[[unmanaged.anyObjE valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[@"a", @"b"]])); 
    
    unmanaged.anyObjF = unmanaged.anyObjF; 
     XCTAssertEqualObjects([NSSet setWithArray:[[unmanaged.anyObjF valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[data(1), data(2)]])); 
    
    unmanaged.anyObjG = unmanaged.anyObjG; 
     XCTAssertEqualObjects([NSSet setWithArray:[[unmanaged.anyObjG valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[date(1), date(2)]])); 
    
    unmanaged.anyObjH = unmanaged.anyObjH; 
     XCTAssertEqualObjects([NSSet setWithArray:[[unmanaged.anyObjH valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[decimal128(1), decimal128(2)]])); 
    
    unmanaged.anyObjI = unmanaged.anyObjI; 
     XCTAssertEqualObjects([NSSet setWithArray:[[unmanaged.anyObjI valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[objectId(1), objectId(2)]])); 
    
    unmanaged.anyObjJ = unmanaged.anyObjJ; 
     XCTAssertEqualObjects([NSSet setWithArray:[[unmanaged.anyObjJ valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[uuid(@"00000000-0000-0000-0000-000000000000"), uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")]])); 
    
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
    
    managed.anyObjA = managed.anyObjA; 
     XCTAssertEqualObjects([NSSet setWithArray:[[managed.anyObjA valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[@NO, @YES]])); 
    
    managed.anyObjB = managed.anyObjB; 
     XCTAssertEqualObjects([NSSet setWithArray:[[managed.anyObjB valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[@2, @3]])); 
    
    managed.anyObjC = managed.anyObjC; 
     XCTAssertEqualObjects([NSSet setWithArray:[[managed.anyObjC valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[@2.2f, @3.3f]])); 
    
    managed.anyObjD = managed.anyObjD; 
     XCTAssertEqualObjects([NSSet setWithArray:[[managed.anyObjD valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[@2.2, @3.3]])); 
    
    managed.anyObjE = managed.anyObjE; 
     XCTAssertEqualObjects([NSSet setWithArray:[[managed.anyObjE valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[@"a", @"b"]])); 
    
    managed.anyObjF = managed.anyObjF; 
     XCTAssertEqualObjects([NSSet setWithArray:[[managed.anyObjF valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[data(1), data(2)]])); 
    
    managed.anyObjG = managed.anyObjG; 
     XCTAssertEqualObjects([NSSet setWithArray:[[managed.anyObjG valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[date(1), date(2)]])); 
    
    managed.anyObjH = managed.anyObjH; 
     XCTAssertEqualObjects([NSSet setWithArray:[[managed.anyObjH valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[decimal128(1), decimal128(2)]])); 
    
    managed.anyObjI = managed.anyObjI; 
     XCTAssertEqualObjects([NSSet setWithArray:[[managed.anyObjI valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[objectId(1), objectId(2)]])); 
    
    managed.anyObjJ = managed.anyObjJ; 
     XCTAssertEqualObjects([NSSet setWithArray:[[managed.anyObjJ valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[uuid(@"00000000-0000-0000-0000-000000000000"), uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")]])); 
    
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
    unmanaged[@"anyObjA"] = (id)@[@YES]; 
     XCTAssertEqualObjects(((RLMSet *)unmanaged[@"anyObjA"]).allObjects[0], @YES);
    unmanaged[@"anyObjB"] = (id)@[@3]; 
     XCTAssertEqualObjects(((RLMSet *)unmanaged[@"anyObjB"]).allObjects[0], @3);
    unmanaged[@"anyObjC"] = (id)@[@3.3f]; 
     XCTAssertEqualObjects(((RLMSet *)unmanaged[@"anyObjC"]).allObjects[0], @3.3f);
    unmanaged[@"anyObjD"] = (id)@[@3.3]; 
     XCTAssertEqualObjects(((RLMSet *)unmanaged[@"anyObjD"]).allObjects[0], @3.3);
    unmanaged[@"anyObjE"] = (id)@[@"b"]; 
     XCTAssertEqualObjects(((RLMSet *)unmanaged[@"anyObjE"]).allObjects[0], @"b");
    unmanaged[@"anyObjF"] = (id)@[data(2)]; 
     XCTAssertEqualObjects(((RLMSet *)unmanaged[@"anyObjF"]).allObjects[0], data(2));
    unmanaged[@"anyObjG"] = (id)@[date(2)]; 
     XCTAssertEqualObjects(((RLMSet *)unmanaged[@"anyObjG"]).allObjects[0], date(2));
    unmanaged[@"anyObjH"] = (id)@[decimal128(2)]; 
     XCTAssertEqualObjects(((RLMSet *)unmanaged[@"anyObjH"]).allObjects[0], decimal128(2));
    unmanaged[@"anyObjI"] = (id)@[objectId(2)]; 
     XCTAssertEqualObjects(((RLMSet *)unmanaged[@"anyObjI"]).allObjects[0], objectId(2));
    unmanaged[@"anyObjJ"] = (id)@[uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")]; 
     XCTAssertEqualObjects(((RLMSet *)unmanaged[@"anyObjJ"]).allObjects[0], uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"));
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
    managed[@"anyObjA"] = (id)@[@YES]; 
     XCTAssertEqualObjects(((RLMSet *)managed[@"anyObjA"]).allObjects[0], @YES);
    managed[@"anyObjB"] = (id)@[@3]; 
     XCTAssertEqualObjects(((RLMSet *)managed[@"anyObjB"]).allObjects[0], @3);
    managed[@"anyObjC"] = (id)@[@3.3f]; 
     XCTAssertEqualObjects(((RLMSet *)managed[@"anyObjC"]).allObjects[0], @3.3f);
    managed[@"anyObjD"] = (id)@[@3.3]; 
     XCTAssertEqualObjects(((RLMSet *)managed[@"anyObjD"]).allObjects[0], @3.3);
    managed[@"anyObjE"] = (id)@[@"b"]; 
     XCTAssertEqualObjects(((RLMSet *)managed[@"anyObjE"]).allObjects[0], @"b");
    managed[@"anyObjF"] = (id)@[data(2)]; 
     XCTAssertEqualObjects(((RLMSet *)managed[@"anyObjF"]).allObjects[0], data(2));
    managed[@"anyObjG"] = (id)@[date(2)]; 
     XCTAssertEqualObjects(((RLMSet *)managed[@"anyObjG"]).allObjects[0], date(2));
    managed[@"anyObjH"] = (id)@[decimal128(2)]; 
     XCTAssertEqualObjects(((RLMSet *)managed[@"anyObjH"]).allObjects[0], decimal128(2));
    managed[@"anyObjI"] = (id)@[objectId(2)]; 
     XCTAssertEqualObjects(((RLMSet *)managed[@"anyObjI"]).allObjects[0], objectId(2));
    managed[@"anyObjJ"] = (id)@[uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")]; 
     XCTAssertEqualObjects(((RLMSet *)managed[@"anyObjJ"]).allObjects[0], uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"));
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
    
    unmanaged[@"anyObjA"] = (id)@[@NO, @YES]; 
     XCTAssertEqualObjects([NSSet setWithArray:[[unmanaged[@"anyObjA"] valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[@NO, @YES]])); 
    
    unmanaged[@"anyObjB"] = (id)@[@2, @3]; 
     XCTAssertEqualObjects([NSSet setWithArray:[[unmanaged[@"anyObjB"] valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[@2, @3]])); 
    
    unmanaged[@"anyObjC"] = (id)@[@2.2f, @3.3f]; 
     XCTAssertEqualObjects([NSSet setWithArray:[[unmanaged[@"anyObjC"] valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[@2.2f, @3.3f]])); 
    
    unmanaged[@"anyObjD"] = (id)@[@2.2, @3.3]; 
     XCTAssertEqualObjects([NSSet setWithArray:[[unmanaged[@"anyObjD"] valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[@2.2, @3.3]])); 
    
    unmanaged[@"anyObjE"] = (id)@[@"a", @"b"]; 
     XCTAssertEqualObjects([NSSet setWithArray:[[unmanaged[@"anyObjE"] valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[@"a", @"b"]])); 
    
    unmanaged[@"anyObjF"] = (id)@[data(1), data(2)]; 
     XCTAssertEqualObjects([NSSet setWithArray:[[unmanaged[@"anyObjF"] valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[data(1), data(2)]])); 
    
    unmanaged[@"anyObjG"] = (id)@[date(1), date(2)]; 
     XCTAssertEqualObjects([NSSet setWithArray:[[unmanaged[@"anyObjG"] valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[date(1), date(2)]])); 
    
    unmanaged[@"anyObjH"] = (id)@[decimal128(1), decimal128(2)]; 
     XCTAssertEqualObjects([NSSet setWithArray:[[unmanaged[@"anyObjH"] valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[decimal128(1), decimal128(2)]])); 
    
    unmanaged[@"anyObjI"] = (id)@[objectId(1), objectId(2)]; 
     XCTAssertEqualObjects([NSSet setWithArray:[[unmanaged[@"anyObjI"] valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[objectId(1), objectId(2)]])); 
    
    unmanaged[@"anyObjJ"] = (id)@[uuid(@"00000000-0000-0000-0000-000000000000"), uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")]; 
     XCTAssertEqualObjects([NSSet setWithArray:[[unmanaged[@"anyObjJ"] valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[uuid(@"00000000-0000-0000-0000-000000000000"), uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")]])); 
    
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
    
    managed[@"anyObjA"] = (id)@[@NO, @YES]; 
     XCTAssertEqualObjects([NSSet setWithArray:[[managed[@"anyObjA"] valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[@NO, @YES]])); 
    
    managed[@"anyObjB"] = (id)@[@2, @3]; 
     XCTAssertEqualObjects([NSSet setWithArray:[[managed[@"anyObjB"] valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[@2, @3]])); 
    
    managed[@"anyObjC"] = (id)@[@2.2f, @3.3f]; 
     XCTAssertEqualObjects([NSSet setWithArray:[[managed[@"anyObjC"] valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[@2.2f, @3.3f]])); 
    
    managed[@"anyObjD"] = (id)@[@2.2, @3.3]; 
     XCTAssertEqualObjects([NSSet setWithArray:[[managed[@"anyObjD"] valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[@2.2, @3.3]])); 
    
    managed[@"anyObjE"] = (id)@[@"a", @"b"]; 
     XCTAssertEqualObjects([NSSet setWithArray:[[managed[@"anyObjE"] valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[@"a", @"b"]])); 
    
    managed[@"anyObjF"] = (id)@[data(1), data(2)]; 
     XCTAssertEqualObjects([NSSet setWithArray:[[managed[@"anyObjF"] valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[data(1), data(2)]])); 
    
    managed[@"anyObjG"] = (id)@[date(1), date(2)]; 
     XCTAssertEqualObjects([NSSet setWithArray:[[managed[@"anyObjG"] valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[date(1), date(2)]])); 
    
    managed[@"anyObjH"] = (id)@[decimal128(1), decimal128(2)]; 
     XCTAssertEqualObjects([NSSet setWithArray:[[managed[@"anyObjH"] valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[decimal128(1), decimal128(2)]])); 
    
    managed[@"anyObjI"] = (id)@[objectId(1), objectId(2)]; 
     XCTAssertEqualObjects([NSSet setWithArray:[[managed[@"anyObjI"] valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[objectId(1), objectId(2)]])); 
    
    managed[@"anyObjJ"] = (id)@[uuid(@"00000000-0000-0000-0000-000000000000"), uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")]; 
     XCTAssertEqualObjects([NSSet setWithArray:[[managed[@"anyObjJ"] valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[uuid(@"00000000-0000-0000-0000-000000000000"), uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")]])); 
    
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
    
    unmanaged[@"anyObjA"] = unmanaged[@"anyObjA"]; 
     XCTAssertEqualObjects([NSSet setWithArray:[[unmanaged[@"anyObjA"] valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[@NO, @YES]])); 
    
    unmanaged[@"anyObjB"] = unmanaged[@"anyObjB"]; 
     XCTAssertEqualObjects([NSSet setWithArray:[[unmanaged[@"anyObjB"] valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[@2, @3]])); 
    
    unmanaged[@"anyObjC"] = unmanaged[@"anyObjC"]; 
     XCTAssertEqualObjects([NSSet setWithArray:[[unmanaged[@"anyObjC"] valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[@2.2f, @3.3f]])); 
    
    unmanaged[@"anyObjD"] = unmanaged[@"anyObjD"]; 
     XCTAssertEqualObjects([NSSet setWithArray:[[unmanaged[@"anyObjD"] valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[@2.2, @3.3]])); 
    
    unmanaged[@"anyObjE"] = unmanaged[@"anyObjE"]; 
     XCTAssertEqualObjects([NSSet setWithArray:[[unmanaged[@"anyObjE"] valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[@"a", @"b"]])); 
    
    unmanaged[@"anyObjF"] = unmanaged[@"anyObjF"]; 
     XCTAssertEqualObjects([NSSet setWithArray:[[unmanaged[@"anyObjF"] valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[data(1), data(2)]])); 
    
    unmanaged[@"anyObjG"] = unmanaged[@"anyObjG"]; 
     XCTAssertEqualObjects([NSSet setWithArray:[[unmanaged[@"anyObjG"] valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[date(1), date(2)]])); 
    
    unmanaged[@"anyObjH"] = unmanaged[@"anyObjH"]; 
     XCTAssertEqualObjects([NSSet setWithArray:[[unmanaged[@"anyObjH"] valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[decimal128(1), decimal128(2)]])); 
    
    unmanaged[@"anyObjI"] = unmanaged[@"anyObjI"]; 
     XCTAssertEqualObjects([NSSet setWithArray:[[unmanaged[@"anyObjI"] valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[objectId(1), objectId(2)]])); 
    
    unmanaged[@"anyObjJ"] = unmanaged[@"anyObjJ"]; 
     XCTAssertEqualObjects([NSSet setWithArray:[[unmanaged[@"anyObjJ"] valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[uuid(@"00000000-0000-0000-0000-000000000000"), uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")]])); 
    
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
    
    managed[@"anyObjA"] = managed[@"anyObjA"]; 
     XCTAssertEqualObjects([NSSet setWithArray:[[managed[@"anyObjA"] valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[@NO, @YES]])); 
    
    managed[@"anyObjB"] = managed[@"anyObjB"]; 
     XCTAssertEqualObjects([NSSet setWithArray:[[managed[@"anyObjB"] valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[@2, @3]])); 
    
    managed[@"anyObjC"] = managed[@"anyObjC"]; 
     XCTAssertEqualObjects([NSSet setWithArray:[[managed[@"anyObjC"] valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[@2.2f, @3.3f]])); 
    
    managed[@"anyObjD"] = managed[@"anyObjD"]; 
     XCTAssertEqualObjects([NSSet setWithArray:[[managed[@"anyObjD"] valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[@2.2, @3.3]])); 
    
    managed[@"anyObjE"] = managed[@"anyObjE"]; 
     XCTAssertEqualObjects([NSSet setWithArray:[[managed[@"anyObjE"] valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[@"a", @"b"]])); 
    
    managed[@"anyObjF"] = managed[@"anyObjF"]; 
     XCTAssertEqualObjects([NSSet setWithArray:[[managed[@"anyObjF"] valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[data(1), data(2)]])); 
    
    managed[@"anyObjG"] = managed[@"anyObjG"]; 
     XCTAssertEqualObjects([NSSet setWithArray:[[managed[@"anyObjG"] valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[date(1), date(2)]])); 
    
    managed[@"anyObjH"] = managed[@"anyObjH"]; 
     XCTAssertEqualObjects([NSSet setWithArray:[[managed[@"anyObjH"] valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[decimal128(1), decimal128(2)]])); 
    
    managed[@"anyObjI"] = managed[@"anyObjI"]; 
     XCTAssertEqualObjects([NSSet setWithArray:[[managed[@"anyObjI"] valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[objectId(1), objectId(2)]])); 
    
    managed[@"anyObjJ"] = managed[@"anyObjJ"]; 
     XCTAssertEqualObjects([NSSet setWithArray:[[managed[@"anyObjJ"] valueForKey:@"self"] allObjects]], ([NSSet setWithArray:@[uuid(@"00000000-0000-0000-0000-000000000000"), uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")]])); 
    
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

#pragma mark - Queries

#define RLMAssertCount(cls, expectedCount, ...) \
    XCTAssertEqual(expectedCount, ([cls objectsInRealm:realm where:__VA_ARGS__].count))

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
        @"anyObjA": [@[@NO, @YES] subarrayWithRange:range],
        @"anyObjB": [@[@2, @3] subarrayWithRange:range],
        @"anyObjC": [@[@2.2f, @3.3f] subarrayWithRange:range],
        @"anyObjD": [@[@2.2, @3.3] subarrayWithRange:range],
        @"anyObjE": [@[@"a", @"b"] subarrayWithRange:range],
        @"anyObjF": [@[data(1), data(2)] subarrayWithRange:range],
        @"anyObjG": [@[date(1), date(2)] subarrayWithRange:range],
        @"anyObjH": [@[decimal128(1), decimal128(2)] subarrayWithRange:range],
        @"anyObjI": [@[objectId(1), objectId(2)] subarrayWithRange:range],
        @"anyObjJ": [@[uuid(@"00000000-0000-0000-0000-000000000000"), uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")] subarrayWithRange:range],
        @"anyObjA": [@[@NO, @YES] subarrayWithRange:range],
        @"anyObjB": [@[@2, @3] subarrayWithRange:range],
        @"anyObjC": [@[@2.2f, @3.3f] subarrayWithRange:range],
        @"anyObjD": [@[@2.2, @3.3] subarrayWithRange:range],
        @"anyObjE": [@[@"a", @"b"] subarrayWithRange:range],
        @"anyObjF": [@[data(1), data(2)] subarrayWithRange:range],
        @"anyObjG": [@[date(1), date(2)] subarrayWithRange:range],
        @"anyObjH": [@[decimal128(1), decimal128(2)] subarrayWithRange:range],
        @"anyObjI": [@[objectId(1), objectId(2)] subarrayWithRange:range],
        @"anyObjJ": [@[uuid(@"00000000-0000-0000-0000-000000000000"), uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")] subarrayWithRange:range],
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
    RLMAssertCount(AllPrimitiveSets, 0, @"ANY anyObjA = %@", @NO);
    RLMAssertCount(AllPrimitiveSets, 0, @"ANY anyObjB = %@", @2);
    RLMAssertCount(AllPrimitiveSets, 0, @"ANY anyObjC = %@", @2.2f);
    RLMAssertCount(AllPrimitiveSets, 0, @"ANY anyObjD = %@", @2.2);
    RLMAssertCount(AllPrimitiveSets, 0, @"ANY anyObjE = %@", @"a");
    RLMAssertCount(AllPrimitiveSets, 0, @"ANY anyObjF = %@", data(1));
    RLMAssertCount(AllPrimitiveSets, 0, @"ANY anyObjG = %@", date(1));
    RLMAssertCount(AllPrimitiveSets, 0, @"ANY anyObjH = %@", decimal128(1));
    RLMAssertCount(AllPrimitiveSets, 0, @"ANY anyObjI = %@", objectId(1));
    RLMAssertCount(AllPrimitiveSets, 0, @"ANY anyObjJ = %@", uuid(@"00000000-0000-0000-0000-000000000000"));
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
    RLMAssertCount(AllPrimitiveSets, 0, @"ANY anyObjA != %@", @NO);
    RLMAssertCount(AllPrimitiveSets, 0, @"ANY anyObjB != %@", @2);
    RLMAssertCount(AllPrimitiveSets, 0, @"ANY anyObjC != %@", @2.2f);
    RLMAssertCount(AllPrimitiveSets, 0, @"ANY anyObjD != %@", @2.2);
    RLMAssertCount(AllPrimitiveSets, 0, @"ANY anyObjE != %@", @"a");
    RLMAssertCount(AllPrimitiveSets, 0, @"ANY anyObjF != %@", data(1));
    RLMAssertCount(AllPrimitiveSets, 0, @"ANY anyObjG != %@", date(1));
    RLMAssertCount(AllPrimitiveSets, 0, @"ANY anyObjH != %@", decimal128(1));
    RLMAssertCount(AllPrimitiveSets, 0, @"ANY anyObjI != %@", objectId(1));
    RLMAssertCount(AllPrimitiveSets, 0, @"ANY anyObjJ != %@", uuid(@"00000000-0000-0000-0000-000000000000"));
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
    RLMAssertCount(AllPrimitiveSets, 0, @"ANY anyObjB > %@", @2);
    RLMAssertCount(AllPrimitiveSets, 0, @"ANY anyObjC > %@", @2.2f);
    RLMAssertCount(AllPrimitiveSets, 0, @"ANY anyObjD > %@", @2.2);
    RLMAssertCount(AllPrimitiveSets, 0, @"ANY anyObjG > %@", date(1));
    RLMAssertCount(AllPrimitiveSets, 0, @"ANY anyObjH > %@", decimal128(1));
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
    RLMAssertCount(AllPrimitiveSets, 0, @"ANY anyObjB >= %@", @2);
    RLMAssertCount(AllPrimitiveSets, 0, @"ANY anyObjC >= %@", @2.2f);
    RLMAssertCount(AllPrimitiveSets, 0, @"ANY anyObjD >= %@", @2.2);
    RLMAssertCount(AllPrimitiveSets, 0, @"ANY anyObjG >= %@", date(1));
    RLMAssertCount(AllPrimitiveSets, 0, @"ANY anyObjH >= %@", decimal128(1));
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
    RLMAssertCount(AllPrimitiveSets, 0, @"ANY anyObjB < %@", @2);
    RLMAssertCount(AllPrimitiveSets, 0, @"ANY anyObjC < %@", @2.2f);
    RLMAssertCount(AllPrimitiveSets, 0, @"ANY anyObjD < %@", @2.2);
    RLMAssertCount(AllPrimitiveSets, 0, @"ANY anyObjG < %@", date(1));
    RLMAssertCount(AllPrimitiveSets, 0, @"ANY anyObjH < %@", decimal128(1));
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
    RLMAssertCount(AllPrimitiveSets, 0, @"ANY anyObjB <= %@", @2);
    RLMAssertCount(AllPrimitiveSets, 0, @"ANY anyObjC <= %@", @2.2f);
    RLMAssertCount(AllPrimitiveSets, 0, @"ANY anyObjD <= %@", @2.2);
    RLMAssertCount(AllPrimitiveSets, 0, @"ANY anyObjG <= %@", date(1));
    RLMAssertCount(AllPrimitiveSets, 0, @"ANY anyObjH <= %@", decimal128(1));
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
    RLMAssertCount(AllPrimitiveSets, 0, @"ANY anyObjA = %@", @YES);
    RLMAssertCount(AllPrimitiveSets, 0, @"ANY anyObjB = %@", @3);
    RLMAssertCount(AllPrimitiveSets, 0, @"ANY anyObjC = %@", @3.3f);
    RLMAssertCount(AllPrimitiveSets, 0, @"ANY anyObjD = %@", @3.3);
    RLMAssertCount(AllPrimitiveSets, 0, @"ANY anyObjE = %@", @"b");
    RLMAssertCount(AllPrimitiveSets, 0, @"ANY anyObjF = %@", data(2));
    RLMAssertCount(AllPrimitiveSets, 0, @"ANY anyObjG = %@", date(2));
    RLMAssertCount(AllPrimitiveSets, 0, @"ANY anyObjH = %@", decimal128(2));
    RLMAssertCount(AllPrimitiveSets, 0, @"ANY anyObjI = %@", objectId(2));
    RLMAssertCount(AllPrimitiveSets, 0, @"ANY anyObjJ = %@", uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"));
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
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY anyObjA = %@", @NO);
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY anyObjB = %@", @2);
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY anyObjC = %@", @2.2f);
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY anyObjD = %@", @2.2);
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY anyObjE = %@", @"a");
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY anyObjF = %@", data(1));
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY anyObjG = %@", date(1));
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY anyObjH = %@", decimal128(1));
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY anyObjI = %@", objectId(1));
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY anyObjJ = %@", uuid(@"00000000-0000-0000-0000-000000000000"));
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
    RLMAssertCount(AllPrimitiveSets, 0, @"ANY anyObjA != %@", @NO);
    RLMAssertCount(AllPrimitiveSets, 0, @"ANY anyObjB != %@", @2);
    RLMAssertCount(AllPrimitiveSets, 0, @"ANY anyObjC != %@", @2.2f);
    RLMAssertCount(AllPrimitiveSets, 0, @"ANY anyObjD != %@", @2.2);
    RLMAssertCount(AllPrimitiveSets, 0, @"ANY anyObjE != %@", @"a");
    RLMAssertCount(AllPrimitiveSets, 0, @"ANY anyObjF != %@", data(1));
    RLMAssertCount(AllPrimitiveSets, 0, @"ANY anyObjG != %@", date(1));
    RLMAssertCount(AllPrimitiveSets, 0, @"ANY anyObjH != %@", decimal128(1));
    RLMAssertCount(AllPrimitiveSets, 0, @"ANY anyObjI != %@", objectId(1));
    RLMAssertCount(AllPrimitiveSets, 0, @"ANY anyObjJ != %@", uuid(@"00000000-0000-0000-0000-000000000000"));
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
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY anyObjA != %@", @YES);
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY anyObjB != %@", @3);
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY anyObjC != %@", @3.3f);
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY anyObjD != %@", @3.3);
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY anyObjE != %@", @"b");
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY anyObjF != %@", data(2));
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY anyObjG != %@", date(2));
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY anyObjH != %@", decimal128(2));
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY anyObjI != %@", objectId(2));
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY anyObjJ != %@", uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"));
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
    RLMAssertCount(AllPrimitiveSets, 0, @"ANY anyObjB > %@", @2);
    RLMAssertCount(AllPrimitiveSets, 0, @"ANY anyObjC > %@", @2.2f);
    RLMAssertCount(AllPrimitiveSets, 0, @"ANY anyObjD > %@", @2.2);
    RLMAssertCount(AllPrimitiveSets, 0, @"ANY anyObjG > %@", date(1));
    RLMAssertCount(AllPrimitiveSets, 0, @"ANY anyObjH > %@", decimal128(1));
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
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY anyObjB >= %@", @2);
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY anyObjC >= %@", @2.2f);
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY anyObjD >= %@", @2.2);
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY anyObjG >= %@", date(1));
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY anyObjH >= %@", decimal128(1));
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
    RLMAssertCount(AllPrimitiveSets, 0, @"ANY anyObjB < %@", @2);
    RLMAssertCount(AllPrimitiveSets, 0, @"ANY anyObjC < %@", @2.2f);
    RLMAssertCount(AllPrimitiveSets, 0, @"ANY anyObjD < %@", @2.2);
    RLMAssertCount(AllPrimitiveSets, 0, @"ANY anyObjG < %@", date(1));
    RLMAssertCount(AllPrimitiveSets, 0, @"ANY anyObjH < %@", decimal128(1));
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
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY anyObjB < %@", @3);
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY anyObjC < %@", @3.3f);
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY anyObjD < %@", @3.3);
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY anyObjG < %@", date(2));
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY anyObjH < %@", decimal128(2));
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
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY anyObjB <= %@", @2);
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY anyObjC <= %@", @2.2f);
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY anyObjD <= %@", @2.2);
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY anyObjG <= %@", date(1));
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY anyObjH <= %@", decimal128(1));
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
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY anyObjA = %@", @NO);
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY anyObjB = %@", @2);
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY anyObjC = %@", @2.2f);
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY anyObjD = %@", @2.2);
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY anyObjE = %@", @"a");
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY anyObjF = %@", data(1));
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY anyObjG = %@", date(1));
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY anyObjH = %@", decimal128(1));
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY anyObjI = %@", objectId(1));
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY anyObjJ = %@", uuid(@"00000000-0000-0000-0000-000000000000"));
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
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY anyObjA = %@", @YES);
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY anyObjB = %@", @3);
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY anyObjC = %@", @3.3f);
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY anyObjD = %@", @3.3);
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY anyObjE = %@", @"b");
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY anyObjF = %@", data(2));
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY anyObjG = %@", date(2));
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY anyObjH = %@", decimal128(2));
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY anyObjI = %@", objectId(2));
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY anyObjJ = %@", uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"));
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
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY anyObjA != %@", @NO);
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY anyObjB != %@", @2);
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY anyObjC != %@", @2.2f);
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY anyObjD != %@", @2.2);
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY anyObjE != %@", @"a");
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY anyObjF != %@", data(1));
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY anyObjG != %@", date(1));
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY anyObjH != %@", decimal128(1));
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY anyObjI != %@", objectId(1));
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY anyObjJ != %@", uuid(@"00000000-0000-0000-0000-000000000000"));
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
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY anyObjA != %@", @YES);
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY anyObjB != %@", @3);
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY anyObjC != %@", @3.3f);
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY anyObjD != %@", @3.3);
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY anyObjE != %@", @"b");
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY anyObjF != %@", data(2));
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY anyObjG != %@", date(2));
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY anyObjH != %@", decimal128(2));
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY anyObjI != %@", objectId(2));
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY anyObjJ != %@", uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"));
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
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY anyObjB > %@", @2);
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY anyObjC > %@", @2.2f);
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY anyObjD > %@", @2.2);
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY anyObjG > %@", date(1));
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY anyObjH > %@", decimal128(1));
    RLMAssertCount(AllPrimitiveSets, 2, @"ANY intObj >= %@", @2);
    RLMAssertCount(AllPrimitiveSets, 2, @"ANY floatObj >= %@", @2.2f);
    RLMAssertCount(AllPrimitiveSets, 2, @"ANY doubleObj >= %@", @2.2);
    RLMAssertCount(AllPrimitiveSets, 2, @"ANY dateObj >= %@", date(1));
    RLMAssertCount(AllPrimitiveSets, 2, @"ANY decimalObj >= %@", decimal128(1));
    RLMAssertCount(AllPrimitiveSets, 2, @"ANY anyObjB >= %@", @2);
    RLMAssertCount(AllPrimitiveSets, 2, @"ANY anyObjC >= %@", @2.2f);
    RLMAssertCount(AllPrimitiveSets, 2, @"ANY anyObjD >= %@", @2.2);
    RLMAssertCount(AllPrimitiveSets, 2, @"ANY anyObjG >= %@", date(1));
    RLMAssertCount(AllPrimitiveSets, 2, @"ANY anyObjH >= %@", decimal128(1));
    RLMAssertCount(AllPrimitiveSets, 0, @"ANY intObj < %@", @2);
    RLMAssertCount(AllPrimitiveSets, 0, @"ANY floatObj < %@", @2.2f);
    RLMAssertCount(AllPrimitiveSets, 0, @"ANY doubleObj < %@", @2.2);
    RLMAssertCount(AllPrimitiveSets, 0, @"ANY dateObj < %@", date(1));
    RLMAssertCount(AllPrimitiveSets, 0, @"ANY decimalObj < %@", decimal128(1));
    RLMAssertCount(AllPrimitiveSets, 0, @"ANY anyObjB < %@", @2);
    RLMAssertCount(AllPrimitiveSets, 0, @"ANY anyObjC < %@", @2.2f);
    RLMAssertCount(AllPrimitiveSets, 0, @"ANY anyObjD < %@", @2.2);
    RLMAssertCount(AllPrimitiveSets, 0, @"ANY anyObjG < %@", date(1));
    RLMAssertCount(AllPrimitiveSets, 0, @"ANY anyObjH < %@", decimal128(1));
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY intObj < %@", @3);
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY floatObj < %@", @3.3f);
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY doubleObj < %@", @3.3);
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY dateObj < %@", date(2));
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY decimalObj < %@", decimal128(2));
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY anyObjB < %@", @3);
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY anyObjC < %@", @3.3f);
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY anyObjD < %@", @3.3);
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY anyObjG < %@", date(2));
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY anyObjH < %@", decimal128(2));
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY intObj <= %@", @2);
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY floatObj <= %@", @2.2f);
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY doubleObj <= %@", @2.2);
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY dateObj <= %@", date(1));
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY decimalObj <= %@", decimal128(1));
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY anyObjB <= %@", @2);
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY anyObjC <= %@", @2.2f);
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY anyObjD <= %@", @2.2);
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY anyObjG <= %@", date(1));
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY anyObjH <= %@", decimal128(1));
    RLMAssertCount(AllPrimitiveSets, 2, @"ANY intObj <= %@", @3);
    RLMAssertCount(AllPrimitiveSets, 2, @"ANY floatObj <= %@", @3.3f);
    RLMAssertCount(AllPrimitiveSets, 2, @"ANY doubleObj <= %@", @3.3);
    RLMAssertCount(AllPrimitiveSets, 2, @"ANY dateObj <= %@", date(2));
    RLMAssertCount(AllPrimitiveSets, 2, @"ANY decimalObj <= %@", decimal128(2));
    RLMAssertCount(AllPrimitiveSets, 2, @"ANY anyObjB <= %@", @3);
    RLMAssertCount(AllPrimitiveSets, 2, @"ANY anyObjC <= %@", @3.3f);
    RLMAssertCount(AllPrimitiveSets, 2, @"ANY anyObjD <= %@", @3.3);
    RLMAssertCount(AllPrimitiveSets, 2, @"ANY anyObjG <= %@", date(2));
    RLMAssertCount(AllPrimitiveSets, 2, @"ANY anyObjH <= %@", decimal128(2));

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
    RLMAssertCount(AllPrimitiveSets, 0, @"ANY anyObjB BETWEEN %@", @[@2, @3]);
    RLMAssertCount(AllPrimitiveSets, 0, @"ANY anyObjC BETWEEN %@", @[@2.2f, @3.3f]);
    RLMAssertCount(AllPrimitiveSets, 0, @"ANY anyObjD BETWEEN %@", @[@2.2, @3.3]);
    RLMAssertCount(AllPrimitiveSets, 0, @"ANY anyObjG BETWEEN %@", @[date(1), date(2)]);
    RLMAssertCount(AllPrimitiveSets, 0, @"ANY anyObjH BETWEEN %@", @[decimal128(1), decimal128(2)]);
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
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY anyObjB BETWEEN %@", @[@3, @3]);
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY anyObjC BETWEEN %@", @[@3.3f, @3.3f]);
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY anyObjD BETWEEN %@", @[@3.3, @3.3]);
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY anyObjG BETWEEN %@", @[date(2), date(2)]);
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY anyObjH BETWEEN %@", @[decimal128(2), decimal128(2)]);
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY intObj BETWEEN %@", @[@2, @3]);
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY floatObj BETWEEN %@", @[@2.2f, @3.3f]);
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY doubleObj BETWEEN %@", @[@2.2, @3.3]);
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY dateObj BETWEEN %@", @[date(1), date(2)]);
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY decimalObj BETWEEN %@", @[decimal128(1), decimal128(2)]);
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY anyObjB BETWEEN %@", @[@2, @3]);
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY anyObjC BETWEEN %@", @[@2.2f, @3.3f]);
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY anyObjD BETWEEN %@", @[@2.2, @3.3]);
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY anyObjG BETWEEN %@", @[date(1), date(2)]);
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY anyObjH BETWEEN %@", @[decimal128(1), decimal128(2)]);
    RLMAssertCount(AllPrimitiveSets, 0, @"ANY intObj BETWEEN %@", @[@2, @2]);
    RLMAssertCount(AllPrimitiveSets, 0, @"ANY floatObj BETWEEN %@", @[@2.2f, @2.2f]);
    RLMAssertCount(AllPrimitiveSets, 0, @"ANY doubleObj BETWEEN %@", @[@2.2, @2.2]);
    RLMAssertCount(AllPrimitiveSets, 0, @"ANY dateObj BETWEEN %@", @[date(1), date(1)]);
    RLMAssertCount(AllPrimitiveSets, 0, @"ANY decimalObj BETWEEN %@", @[decimal128(1), decimal128(1)]);
    RLMAssertCount(AllPrimitiveSets, 0, @"ANY anyObjB BETWEEN %@", @[@2, @2]);
    RLMAssertCount(AllPrimitiveSets, 0, @"ANY anyObjC BETWEEN %@", @[@2.2f, @2.2f]);
    RLMAssertCount(AllPrimitiveSets, 0, @"ANY anyObjD BETWEEN %@", @[@2.2, @2.2]);
    RLMAssertCount(AllPrimitiveSets, 0, @"ANY anyObjG BETWEEN %@", @[date(1), date(1)]);
    RLMAssertCount(AllPrimitiveSets, 0, @"ANY anyObjH BETWEEN %@", @[decimal128(1), decimal128(1)]);

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
    RLMAssertCount(AllPrimitiveSets, 0, @"ANY anyObjA IN %@", @[@NO, @YES]);
    RLMAssertCount(AllPrimitiveSets, 0, @"ANY anyObjB IN %@", @[@2, @3]);
    RLMAssertCount(AllPrimitiveSets, 0, @"ANY anyObjC IN %@", @[@2.2f, @3.3f]);
    RLMAssertCount(AllPrimitiveSets, 0, @"ANY anyObjD IN %@", @[@2.2, @3.3]);
    RLMAssertCount(AllPrimitiveSets, 0, @"ANY anyObjE IN %@", @[@"a", @"b"]);
    RLMAssertCount(AllPrimitiveSets, 0, @"ANY anyObjF IN %@", @[data(1), data(2)]);
    RLMAssertCount(AllPrimitiveSets, 0, @"ANY anyObjG IN %@", @[date(1), date(2)]);
    RLMAssertCount(AllPrimitiveSets, 0, @"ANY anyObjH IN %@", @[decimal128(1), decimal128(2)]);
    RLMAssertCount(AllPrimitiveSets, 0, @"ANY anyObjI IN %@", @[objectId(1), objectId(2)]);
    RLMAssertCount(AllPrimitiveSets, 0, @"ANY anyObjJ IN %@", @[uuid(@"00000000-0000-0000-0000-000000000000"), uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")]);
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
    RLMAssertCount(AllPrimitiveSets, 0, @"ANY anyObjA IN %@", @[@YES]);
    RLMAssertCount(AllPrimitiveSets, 0, @"ANY anyObjB IN %@", @[@3]);
    RLMAssertCount(AllPrimitiveSets, 0, @"ANY anyObjC IN %@", @[@3.3f]);
    RLMAssertCount(AllPrimitiveSets, 0, @"ANY anyObjD IN %@", @[@3.3]);
    RLMAssertCount(AllPrimitiveSets, 0, @"ANY anyObjE IN %@", @[@"b"]);
    RLMAssertCount(AllPrimitiveSets, 0, @"ANY anyObjF IN %@", @[data(2)]);
    RLMAssertCount(AllPrimitiveSets, 0, @"ANY anyObjG IN %@", @[date(2)]);
    RLMAssertCount(AllPrimitiveSets, 0, @"ANY anyObjH IN %@", @[decimal128(2)]);
    RLMAssertCount(AllPrimitiveSets, 0, @"ANY anyObjI IN %@", @[objectId(2)]);
    RLMAssertCount(AllPrimitiveSets, 0, @"ANY anyObjJ IN %@", @[uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")]);
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
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY anyObjA IN %@", @[@NO, @YES]);
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY anyObjB IN %@", @[@2, @3]);
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY anyObjC IN %@", @[@2.2f, @3.3f]);
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY anyObjD IN %@", @[@2.2, @3.3]);
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY anyObjE IN %@", @[@"a", @"b"]);
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY anyObjF IN %@", @[data(1), data(2)]);
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY anyObjG IN %@", @[date(1), date(2)]);
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY anyObjH IN %@", @[decimal128(1), decimal128(2)]);
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY anyObjI IN %@", @[objectId(1), objectId(2)]);
    RLMAssertCount(AllPrimitiveSets, 1, @"ANY anyObjJ IN %@", @[uuid(@"00000000-0000-0000-0000-000000000000"), uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")]);
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
        @"anyObjA": @[@NO, @YES],
        @"anyObjB": @[@2, @3],
        @"anyObjC": @[@2.2f, @3.3f],
        @"anyObjD": @[@2.2, @3.3],
        @"anyObjE": @[@"a", @"b"],
        @"anyObjF": @[data(1), data(2)],
        @"anyObjG": @[date(1), date(2)],
        @"anyObjH": @[decimal128(1), decimal128(2)],
        @"anyObjI": @[objectId(1), objectId(2)],
        @"anyObjJ": @[uuid(@"00000000-0000-0000-0000-000000000000"), uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")],
        @"anyObjA": @[@NO, @YES],
        @"anyObjB": @[@2, @3],
        @"anyObjC": @[@2.2f, @3.3f],
        @"anyObjD": @[@2.2, @3.3],
        @"anyObjE": @[@"a", @"b"],
        @"anyObjF": @[data(1), data(2)],
        @"anyObjG": @[date(1), date(2)],
        @"anyObjH": @[decimal128(1), decimal128(2)],
        @"anyObjI": @[objectId(1), objectId(2)],
        @"anyObjJ": @[uuid(@"00000000-0000-0000-0000-000000000000"), uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")],
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
    RLMAssertCount(AllPrimitiveSets, 1U, @"anyObjA.@count == %@", @(2));
    RLMAssertCount(AllPrimitiveSets, 1U, @"anyObjB.@count == %@", @(2));
    RLMAssertCount(AllPrimitiveSets, 1U, @"anyObjC.@count == %@", @(2));
    RLMAssertCount(AllPrimitiveSets, 1U, @"anyObjD.@count == %@", @(2));
    RLMAssertCount(AllPrimitiveSets, 1U, @"anyObjE.@count == %@", @(2));
    RLMAssertCount(AllPrimitiveSets, 1U, @"anyObjF.@count == %@", @(2));
    RLMAssertCount(AllPrimitiveSets, 1U, @"anyObjG.@count == %@", @(2));
    RLMAssertCount(AllPrimitiveSets, 1U, @"anyObjH.@count == %@", @(2));
    RLMAssertCount(AllPrimitiveSets, 1U, @"anyObjI.@count == %@", @(2));
    RLMAssertCount(AllPrimitiveSets, 1U, @"anyObjJ.@count == %@", @(2));
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
    RLMAssertCount(AllPrimitiveSets, 0U, @"anyObjA.@count != %@", @(2));
    RLMAssertCount(AllPrimitiveSets, 0U, @"anyObjB.@count != %@", @(2));
    RLMAssertCount(AllPrimitiveSets, 0U, @"anyObjC.@count != %@", @(2));
    RLMAssertCount(AllPrimitiveSets, 0U, @"anyObjD.@count != %@", @(2));
    RLMAssertCount(AllPrimitiveSets, 0U, @"anyObjE.@count != %@", @(2));
    RLMAssertCount(AllPrimitiveSets, 0U, @"anyObjF.@count != %@", @(2));
    RLMAssertCount(AllPrimitiveSets, 0U, @"anyObjG.@count != %@", @(2));
    RLMAssertCount(AllPrimitiveSets, 0U, @"anyObjH.@count != %@", @(2));
    RLMAssertCount(AllPrimitiveSets, 0U, @"anyObjI.@count != %@", @(2));
    RLMAssertCount(AllPrimitiveSets, 0U, @"anyObjJ.@count != %@", @(2));
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
    RLMAssertCount(AllPrimitiveSets, 0, @"anyObjA.@count > %@", @(2));
    RLMAssertCount(AllPrimitiveSets, 0, @"anyObjB.@count > %@", @(2));
    RLMAssertCount(AllPrimitiveSets, 0, @"anyObjC.@count > %@", @(2));
    RLMAssertCount(AllPrimitiveSets, 0, @"anyObjD.@count > %@", @(2));
    RLMAssertCount(AllPrimitiveSets, 0, @"anyObjE.@count > %@", @(2));
    RLMAssertCount(AllPrimitiveSets, 0, @"anyObjF.@count > %@", @(2));
    RLMAssertCount(AllPrimitiveSets, 0, @"anyObjG.@count > %@", @(2));
    RLMAssertCount(AllPrimitiveSets, 0, @"anyObjH.@count > %@", @(2));
    RLMAssertCount(AllPrimitiveSets, 0, @"anyObjI.@count > %@", @(2));
    RLMAssertCount(AllPrimitiveSets, 0, @"anyObjJ.@count > %@", @(2));
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
    RLMAssertCount(AllPrimitiveSets, 1, @"anyObjA.@count >= %@", @(2));
    RLMAssertCount(AllPrimitiveSets, 1, @"anyObjB.@count >= %@", @(2));
    RLMAssertCount(AllPrimitiveSets, 1, @"anyObjC.@count >= %@", @(2));
    RLMAssertCount(AllPrimitiveSets, 1, @"anyObjD.@count >= %@", @(2));
    RLMAssertCount(AllPrimitiveSets, 1, @"anyObjE.@count >= %@", @(2));
    RLMAssertCount(AllPrimitiveSets, 1, @"anyObjF.@count >= %@", @(2));
    RLMAssertCount(AllPrimitiveSets, 1, @"anyObjG.@count >= %@", @(2));
    RLMAssertCount(AllPrimitiveSets, 1, @"anyObjH.@count >= %@", @(2));
    RLMAssertCount(AllPrimitiveSets, 1, @"anyObjI.@count >= %@", @(2));
    RLMAssertCount(AllPrimitiveSets, 1, @"anyObjJ.@count >= %@", @(2));
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
    RLMAssertCount(AllPrimitiveSets, 0, @"anyObjA.@count < %@", @(2));
    RLMAssertCount(AllPrimitiveSets, 0, @"anyObjB.@count < %@", @(2));
    RLMAssertCount(AllPrimitiveSets, 0, @"anyObjC.@count < %@", @(2));
    RLMAssertCount(AllPrimitiveSets, 0, @"anyObjD.@count < %@", @(2));
    RLMAssertCount(AllPrimitiveSets, 0, @"anyObjE.@count < %@", @(2));
    RLMAssertCount(AllPrimitiveSets, 0, @"anyObjF.@count < %@", @(2));
    RLMAssertCount(AllPrimitiveSets, 0, @"anyObjG.@count < %@", @(2));
    RLMAssertCount(AllPrimitiveSets, 0, @"anyObjH.@count < %@", @(2));
    RLMAssertCount(AllPrimitiveSets, 0, @"anyObjI.@count < %@", @(2));
    RLMAssertCount(AllPrimitiveSets, 0, @"anyObjJ.@count < %@", @(2));
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
    RLMAssertCount(AllPrimitiveSets, 1, @"anyObjA.@count <= %@", @(2));
    RLMAssertCount(AllPrimitiveSets, 1, @"anyObjB.@count <= %@", @(2));
    RLMAssertCount(AllPrimitiveSets, 1, @"anyObjC.@count <= %@", @(2));
    RLMAssertCount(AllPrimitiveSets, 1, @"anyObjD.@count <= %@", @(2));
    RLMAssertCount(AllPrimitiveSets, 1, @"anyObjE.@count <= %@", @(2));
    RLMAssertCount(AllPrimitiveSets, 1, @"anyObjF.@count <= %@", @(2));
    RLMAssertCount(AllPrimitiveSets, 1, @"anyObjG.@count <= %@", @(2));
    RLMAssertCount(AllPrimitiveSets, 1, @"anyObjH.@count <= %@", @(2));
    RLMAssertCount(AllPrimitiveSets, 1, @"anyObjI.@count <= %@", @(2));
    RLMAssertCount(AllPrimitiveSets, 1, @"anyObjJ.@count <= %@", @(2));
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
                              @"@sum can only be applied to a numeric property.");
    RLMAssertThrowsWithReason(([AllPrimitiveSets objectsInRealm:realm where:@"stringObj.@sum = %@", @"a"]), 
                              @"@sum can only be applied to a numeric property.");
    RLMAssertThrowsWithReason(([AllPrimitiveSets objectsInRealm:realm where:@"dataObj.@sum = %@", data(1)]), 
                              @"@sum can only be applied to a numeric property.");
    RLMAssertThrowsWithReason(([AllPrimitiveSets objectsInRealm:realm where:@"objectIdObj.@sum = %@", objectId(1)]), 
                              @"@sum can only be applied to a numeric property.");
    RLMAssertThrowsWithReason(([AllPrimitiveSets objectsInRealm:realm where:@"uuidObj.@sum = %@", uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")]), 
                              @"@sum can only be applied to a numeric property.");
    RLMAssertThrowsWithReason(([AllOptionalPrimitiveSets objectsInRealm:realm where:@"boolObj.@sum = %@", NSNull.null]), 
                              @"@sum can only be applied to a numeric property.");
    RLMAssertThrowsWithReason(([AllOptionalPrimitiveSets objectsInRealm:realm where:@"stringObj.@sum = %@", NSNull.null]), 
                              @"@sum can only be applied to a numeric property.");
    RLMAssertThrowsWithReason(([AllOptionalPrimitiveSets objectsInRealm:realm where:@"dataObj.@sum = %@", NSNull.null]), 
                              @"@sum can only be applied to a numeric property.");
    RLMAssertThrowsWithReason(([AllOptionalPrimitiveSets objectsInRealm:realm where:@"objectIdObj.@sum = %@", NSNull.null]), 
                              @"@sum can only be applied to a numeric property.");
    RLMAssertThrowsWithReason(([AllOptionalPrimitiveSets objectsInRealm:realm where:@"uuidObj.@sum = %@", NSNull.null]), 
                              @"@sum can only be applied to a numeric property.");
    RLMAssertThrowsWithReason(([AllPrimitiveSets objectsInRealm:realm where:@"dateObj.@sum = %@", date(2)]), 
                              @"Cannot sum or average date properties");
    RLMAssertThrowsWithReason(([AllOptionalPrimitiveSets objectsInRealm:realm where:@"dateObj.@sum = %@", date(1)]), 
                              @"Cannot sum or average date properties");
    RLMAssertThrowsWithReason(([AllPrimitiveSets objectsInRealm:realm where:@"anyObjG.@sum = %@", date(2)]), 
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
                              @"Property 'intObj' is not a link in object of type 'AllPrimitiveSets'");
    RLMAssertThrowsWithReason(([AllPrimitiveSets objectsInRealm:realm where:@"floatObj.@sum.prop = %@", @"a"]), 
                              @"Property 'floatObj' is not a link in object of type 'AllPrimitiveSets'");
    RLMAssertThrowsWithReason(([AllPrimitiveSets objectsInRealm:realm where:@"doubleObj.@sum.prop = %@", @"a"]), 
                              @"Property 'doubleObj' is not a link in object of type 'AllPrimitiveSets'");
    RLMAssertThrowsWithReason(([AllPrimitiveSets objectsInRealm:realm where:@"decimalObj.@sum.prop = %@", @"a"]), 
                              @"Property 'decimalObj' is not a link in object of type 'AllPrimitiveSets'");
    RLMAssertThrowsWithReason(([AllPrimitiveSets objectsInRealm:realm where:@"anyObjB.@sum.prop = %@", @"a"]), 
                              @"Property 'anyObjB' is not a link in object of type 'AllPrimitiveSets'");
    RLMAssertThrowsWithReason(([AllPrimitiveSets objectsInRealm:realm where:@"anyObjC.@sum.prop = %@", @"a"]), 
                              @"Property 'anyObjC' is not a link in object of type 'AllPrimitiveSets'");
    RLMAssertThrowsWithReason(([AllPrimitiveSets objectsInRealm:realm where:@"anyObjD.@sum.prop = %@", @"a"]), 
                              @"Property 'anyObjD' is not a link in object of type 'AllPrimitiveSets'");
    RLMAssertThrowsWithReason(([AllPrimitiveSets objectsInRealm:realm where:@"anyObjH.@sum.prop = %@", @"a"]), 
                              @"Property 'anyObjH' is not a link in object of type 'AllPrimitiveSets'");
    RLMAssertThrowsWithReason(([AllOptionalPrimitiveSets objectsInRealm:realm where:@"intObj.@sum.prop = %@", @"a"]), 
                              @"Property 'intObj' is not a link in object of type 'AllOptionalPrimitiveSets'");
    RLMAssertThrowsWithReason(([AllOptionalPrimitiveSets objectsInRealm:realm where:@"floatObj.@sum.prop = %@", @"a"]), 
                              @"Property 'floatObj' is not a link in object of type 'AllOptionalPrimitiveSets'");
    RLMAssertThrowsWithReason(([AllOptionalPrimitiveSets objectsInRealm:realm where:@"doubleObj.@sum.prop = %@", @"a"]), 
                              @"Property 'doubleObj' is not a link in object of type 'AllOptionalPrimitiveSets'");
    RLMAssertThrowsWithReason(([AllOptionalPrimitiveSets objectsInRealm:realm where:@"decimalObj.@sum.prop = %@", @"a"]), 
                              @"Property 'decimalObj' is not a link in object of type 'AllOptionalPrimitiveSets'");
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
        @"anyObjB": @[],
        @"anyObjC": @[],
        @"anyObjD": @[],
        @"anyObjH": @[],
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
        @"anyObjB": @[@2],
        @"anyObjC": @[@2.2f],
        @"anyObjD": @[@2.2],
        @"anyObjH": @[decimal128(1)],
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
        @"anyObjB": @[@2, @2],
        @"anyObjC": @[@2.2f, @2.2f],
        @"anyObjD": @[@2.2, @2.2],
        @"anyObjH": @[decimal128(1), decimal128(1)],
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
        @"anyObjB": @[@3, @3, @3],
        @"anyObjC": @[@3.3f, @3.3f, @3.3f],
        @"anyObjD": @[@3.3, @3.3, @3.3],
        @"anyObjH": @[decimal128(2), decimal128(2), decimal128(2)],
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
    RLMAssertCount(AllPrimitiveSets, 1U, @"anyObjB.@sum == %@", @0);
    RLMAssertCount(AllPrimitiveSets, 1U, @"anyObjC.@sum == %@", @0);
    RLMAssertCount(AllPrimitiveSets, 1U, @"anyObjD.@sum == %@", @0);
    RLMAssertCount(AllPrimitiveSets, 1U, @"anyObjH.@sum == %@", @0);
    RLMAssertCount(AllPrimitiveSets, 2U, @"intObj.@sum == %@", @2);
    RLMAssertCount(AllPrimitiveSets, 2U, @"floatObj.@sum == %@", @2.2f);
    RLMAssertCount(AllPrimitiveSets, 2U, @"doubleObj.@sum == %@", @2.2);
    RLMAssertCount(AllPrimitiveSets, 2U, @"decimalObj.@sum == %@", decimal128(1));
    RLMAssertCount(AllPrimitiveSets, 2U, @"anyObjB.@sum == %@", @2);
    RLMAssertCount(AllPrimitiveSets, 2U, @"anyObjC.@sum == %@", @2.2f);
    RLMAssertCount(AllPrimitiveSets, 2U, @"anyObjD.@sum == %@", @2.2);
    RLMAssertCount(AllPrimitiveSets, 2U, @"anyObjH.@sum == %@", decimal128(1));
    RLMAssertCount(AllPrimitiveSets, 3U, @"intObj.@sum != %@", @3);
    RLMAssertCount(AllPrimitiveSets, 3U, @"floatObj.@sum != %@", @3.3f);
    RLMAssertCount(AllPrimitiveSets, 3U, @"doubleObj.@sum != %@", @3.3);
    RLMAssertCount(AllPrimitiveSets, 3U, @"decimalObj.@sum != %@", decimal128(2));
    RLMAssertCount(AllPrimitiveSets, 3U, @"anyObjB.@sum != %@", @3);
    RLMAssertCount(AllPrimitiveSets, 3U, @"anyObjC.@sum != %@", @3.3f);
    RLMAssertCount(AllPrimitiveSets, 3U, @"anyObjD.@sum != %@", @3.3);
    RLMAssertCount(AllPrimitiveSets, 3U, @"anyObjH.@sum != %@", decimal128(2));
    RLMAssertCount(AllPrimitiveSets, 3U, @"intObj.@sum >= %@", @2);
    RLMAssertCount(AllPrimitiveSets, 3U, @"floatObj.@sum >= %@", @2.2f);
    RLMAssertCount(AllPrimitiveSets, 3U, @"doubleObj.@sum >= %@", @2.2);
    RLMAssertCount(AllPrimitiveSets, 3U, @"decimalObj.@sum >= %@", decimal128(1));
    RLMAssertCount(AllPrimitiveSets, 3U, @"anyObjB.@sum >= %@", @2);
    RLMAssertCount(AllPrimitiveSets, 3U, @"anyObjC.@sum >= %@", @2.2f);
    RLMAssertCount(AllPrimitiveSets, 3U, @"anyObjD.@sum >= %@", @2.2);
    RLMAssertCount(AllPrimitiveSets, 3U, @"anyObjH.@sum >= %@", decimal128(1));
    RLMAssertCount(AllPrimitiveSets, 1U, @"intObj.@sum > %@", @2);
    RLMAssertCount(AllPrimitiveSets, 1U, @"floatObj.@sum > %@", @2.2f);
    RLMAssertCount(AllPrimitiveSets, 1U, @"doubleObj.@sum > %@", @2.2);
    RLMAssertCount(AllPrimitiveSets, 1U, @"decimalObj.@sum > %@", decimal128(1));
    RLMAssertCount(AllPrimitiveSets, 1U, @"anyObjB.@sum > %@", @2);
    RLMAssertCount(AllPrimitiveSets, 1U, @"anyObjC.@sum > %@", @2.2f);
    RLMAssertCount(AllPrimitiveSets, 1U, @"anyObjD.@sum > %@", @2.2);
    RLMAssertCount(AllPrimitiveSets, 1U, @"anyObjH.@sum > %@", decimal128(1));
    RLMAssertCount(AllPrimitiveSets, 3U, @"intObj.@sum < %@", @3);
    RLMAssertCount(AllPrimitiveSets, 3U, @"floatObj.@sum < %@", @3.3f);
    RLMAssertCount(AllPrimitiveSets, 3U, @"doubleObj.@sum < %@", @3.3);
    RLMAssertCount(AllPrimitiveSets, 3U, @"decimalObj.@sum < %@", decimal128(2));
    RLMAssertCount(AllPrimitiveSets, 3U, @"anyObjB.@sum < %@", @3);
    RLMAssertCount(AllPrimitiveSets, 3U, @"anyObjC.@sum < %@", @3.3f);
    RLMAssertCount(AllPrimitiveSets, 3U, @"anyObjD.@sum < %@", @3.3);
    RLMAssertCount(AllPrimitiveSets, 3U, @"anyObjH.@sum < %@", decimal128(2));
    RLMAssertCount(AllPrimitiveSets, 4U, @"intObj.@sum <= %@", @3);
    RLMAssertCount(AllPrimitiveSets, 4U, @"floatObj.@sum <= %@", @3.3f);
    RLMAssertCount(AllPrimitiveSets, 4U, @"doubleObj.@sum <= %@", @3.3);
    RLMAssertCount(AllPrimitiveSets, 4U, @"decimalObj.@sum <= %@", decimal128(2));
    RLMAssertCount(AllPrimitiveSets, 4U, @"anyObjB.@sum <= %@", @3);
    RLMAssertCount(AllPrimitiveSets, 4U, @"anyObjC.@sum <= %@", @3.3f);
    RLMAssertCount(AllPrimitiveSets, 4U, @"anyObjD.@sum <= %@", @3.3);
    RLMAssertCount(AllPrimitiveSets, 4U, @"anyObjH.@sum <= %@", decimal128(2));

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
                              @"@avg can only be applied to a numeric property.");
    RLMAssertThrowsWithReason(([AllPrimitiveSets objectsInRealm:realm where:@"stringObj.@avg = %@", @"a"]), 
                              @"@avg can only be applied to a numeric property.");
    RLMAssertThrowsWithReason(([AllPrimitiveSets objectsInRealm:realm where:@"dataObj.@avg = %@", data(1)]), 
                              @"@avg can only be applied to a numeric property.");
    RLMAssertThrowsWithReason(([AllPrimitiveSets objectsInRealm:realm where:@"objectIdObj.@avg = %@", objectId(1)]), 
                              @"@avg can only be applied to a numeric property.");
    RLMAssertThrowsWithReason(([AllPrimitiveSets objectsInRealm:realm where:@"uuidObj.@avg = %@", uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")]), 
                              @"@avg can only be applied to a numeric property.");
    RLMAssertThrowsWithReason(([AllOptionalPrimitiveSets objectsInRealm:realm where:@"boolObj.@avg = %@", NSNull.null]), 
                              @"@avg can only be applied to a numeric property.");
    RLMAssertThrowsWithReason(([AllOptionalPrimitiveSets objectsInRealm:realm where:@"stringObj.@avg = %@", NSNull.null]), 
                              @"@avg can only be applied to a numeric property.");
    RLMAssertThrowsWithReason(([AllOptionalPrimitiveSets objectsInRealm:realm where:@"dataObj.@avg = %@", NSNull.null]), 
                              @"@avg can only be applied to a numeric property.");
    RLMAssertThrowsWithReason(([AllOptionalPrimitiveSets objectsInRealm:realm where:@"objectIdObj.@avg = %@", NSNull.null]), 
                              @"@avg can only be applied to a numeric property.");
    RLMAssertThrowsWithReason(([AllOptionalPrimitiveSets objectsInRealm:realm where:@"uuidObj.@avg = %@", NSNull.null]), 
                              @"@avg can only be applied to a numeric property.");
    RLMAssertThrowsWithReason(([AllPrimitiveSets objectsInRealm:realm where:@"dateObj.@avg = %@", date(1)]), 
                              @"Cannot sum or average date properties");
    RLMAssertThrowsWithReason(([AllOptionalPrimitiveSets objectsInRealm:realm where:@"dateObj.@avg = %@", NSNull.null]), 
                              @"Cannot sum or average date properties");
    RLMAssertThrowsWithReason(([AllPrimitiveSets objectsInRealm:realm where:@"anyObjA.@avg = %@", @NO]), 
                              @"Unsupported comparision value type for mixed. Value must be numeric.");
    RLMAssertThrowsWithReason(([AllPrimitiveSets objectsInRealm:realm where:@"anyObjE.@avg = %@", @"a"]), 
                              @"Unsupported comparision value type for mixed. Value must be numeric.");
    RLMAssertThrowsWithReason(([AllPrimitiveSets objectsInRealm:realm where:@"anyObjF.@avg = %@", data(1)]), 
                              @"Unsupported comparision value type for mixed. Value must be numeric.");
    RLMAssertThrowsWithReason(([AllPrimitiveSets objectsInRealm:realm where:@"anyObjI.@avg = %@", objectId(1)]), 
                              @"Unsupported comparision value type for mixed. Value must be numeric.");
    RLMAssertThrowsWithReason(([AllPrimitiveSets objectsInRealm:realm where:@"anyObjJ.@avg = %@", uuid(@"00000000-0000-0000-0000-000000000000")]), 
                              @"Unsupported comparision value type for mixed. Value must be numeric.");
    RLMAssertThrowsWithReason(([AllPrimitiveSets objectsInRealm:realm where:@"anyObjG.@avg = %@", date(1)]), 
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
                              @"Property 'intObj' is not a link in object of type 'AllPrimitiveSets'");
    RLMAssertThrowsWithReason(([AllPrimitiveSets objectsInRealm:realm where:@"floatObj.@avg.prop = %@", @"a"]), 
                              @"Property 'floatObj' is not a link in object of type 'AllPrimitiveSets'");
    RLMAssertThrowsWithReason(([AllPrimitiveSets objectsInRealm:realm where:@"doubleObj.@avg.prop = %@", @"a"]), 
                              @"Property 'doubleObj' is not a link in object of type 'AllPrimitiveSets'");
    RLMAssertThrowsWithReason(([AllPrimitiveSets objectsInRealm:realm where:@"decimalObj.@avg.prop = %@", @"a"]), 
                              @"Property 'decimalObj' is not a link in object of type 'AllPrimitiveSets'");
    RLMAssertThrowsWithReason(([AllOptionalPrimitiveSets objectsInRealm:realm where:@"intObj.@avg.prop = %@", @"a"]), 
                              @"Property 'intObj' is not a link in object of type 'AllOptionalPrimitiveSets'");
    RLMAssertThrowsWithReason(([AllOptionalPrimitiveSets objectsInRealm:realm where:@"floatObj.@avg.prop = %@", @"a"]), 
                              @"Property 'floatObj' is not a link in object of type 'AllOptionalPrimitiveSets'");
    RLMAssertThrowsWithReason(([AllOptionalPrimitiveSets objectsInRealm:realm where:@"doubleObj.@avg.prop = %@", @"a"]), 
                              @"Property 'doubleObj' is not a link in object of type 'AllOptionalPrimitiveSets'");
    RLMAssertThrowsWithReason(([AllOptionalPrimitiveSets objectsInRealm:realm where:@"decimalObj.@avg.prop = %@", @"a"]), 
                              @"Property 'decimalObj' is not a link in object of type 'AllOptionalPrimitiveSets'");

    [AllPrimitiveSets createInRealm:realm withValue:@{
        @"intObj": @[],
        @"floatObj": @[],
        @"doubleObj": @[],
        @"decimalObj": @[],
        @"anyObjB": @[],
        @"anyObjC": @[],
        @"anyObjD": @[],
        @"anyObjH": @[],
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
        @"anyObjB": @[@3],
        @"anyObjC": @[@3.3f],
        @"anyObjD": @[@3.3],
        @"anyObjH": @[decimal128(2)],
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
        @"anyObjB": @[@2, @3],
        @"anyObjC": @[@2.2f, @3.3f],
        @"anyObjD": @[@2.2, @3.3],
        @"anyObjH": @[decimal128(1), decimal128(2)],
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
        @"anyObjB": @[@3],
        @"anyObjC": @[@3.3f],
        @"anyObjD": @[@3.3],
        @"anyObjH": @[decimal128(2)],
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
    RLMAssertCount(AllPrimitiveSets, 1U, @"anyObjB.@avg == %@", NSNull.null);
    RLMAssertCount(AllPrimitiveSets, 1U, @"anyObjC.@avg == %@", NSNull.null);
    RLMAssertCount(AllPrimitiveSets, 1U, @"anyObjD.@avg == %@", NSNull.null);
    RLMAssertCount(AllPrimitiveSets, 1U, @"anyObjH.@avg == %@", NSNull.null);
    RLMAssertCount(AllOptionalPrimitiveSets, 1U, @"intObj.@avg == %@", NSNull.null);
    RLMAssertCount(AllOptionalPrimitiveSets, 1U, @"floatObj.@avg == %@", NSNull.null);
    RLMAssertCount(AllOptionalPrimitiveSets, 1U, @"doubleObj.@avg == %@", NSNull.null);
    RLMAssertCount(AllOptionalPrimitiveSets, 1U, @"decimalObj.@avg == %@", NSNull.null);
    RLMAssertCount(AllPrimitiveSets, 2U, @"intObj.@avg == %@", @3);
    RLMAssertCount(AllPrimitiveSets, 2U, @"floatObj.@avg == %@", @3.3f);
    RLMAssertCount(AllPrimitiveSets, 2U, @"doubleObj.@avg == %@", @3.3);
    RLMAssertCount(AllPrimitiveSets, 2U, @"decimalObj.@avg == %@", decimal128(2));
    RLMAssertCount(AllPrimitiveSets, 2U, @"anyObjB.@avg == %@", @3);
    RLMAssertCount(AllPrimitiveSets, 2U, @"anyObjC.@avg == %@", @3.3f);
    RLMAssertCount(AllPrimitiveSets, 2U, @"anyObjD.@avg == %@", @3.3);
    RLMAssertCount(AllPrimitiveSets, 2U, @"anyObjH.@avg == %@", decimal128(2));
    RLMAssertCount(AllOptionalPrimitiveSets, 2U, @"intObj.@avg == %@", @3);
    RLMAssertCount(AllOptionalPrimitiveSets, 2U, @"floatObj.@avg == %@", @3.3f);
    RLMAssertCount(AllOptionalPrimitiveSets, 2U, @"doubleObj.@avg == %@", @3.3);
    RLMAssertCount(AllOptionalPrimitiveSets, 2U, @"decimalObj.@avg == %@", decimal128(2));
    RLMAssertCount(AllPrimitiveSets, 2U, @"intObj.@avg != %@", @3);
    RLMAssertCount(AllPrimitiveSets, 2U, @"floatObj.@avg != %@", @3.3f);
    RLMAssertCount(AllPrimitiveSets, 2U, @"doubleObj.@avg != %@", @3.3);
    RLMAssertCount(AllPrimitiveSets, 2U, @"decimalObj.@avg != %@", decimal128(2));
    RLMAssertCount(AllPrimitiveSets, 2U, @"anyObjB.@avg != %@", @3);
    RLMAssertCount(AllPrimitiveSets, 2U, @"anyObjC.@avg != %@", @3.3f);
    RLMAssertCount(AllPrimitiveSets, 2U, @"anyObjD.@avg != %@", @3.3);
    RLMAssertCount(AllPrimitiveSets, 2U, @"anyObjH.@avg != %@", decimal128(2));
    RLMAssertCount(AllOptionalPrimitiveSets, 2U, @"intObj.@avg != %@", @3);
    RLMAssertCount(AllOptionalPrimitiveSets, 2U, @"floatObj.@avg != %@", @3.3f);
    RLMAssertCount(AllOptionalPrimitiveSets, 2U, @"doubleObj.@avg != %@", @3.3);
    RLMAssertCount(AllOptionalPrimitiveSets, 2U, @"decimalObj.@avg != %@", decimal128(2));
    RLMAssertCount(AllPrimitiveSets, 2U, @"intObj.@avg >= %@", @3);
    RLMAssertCount(AllPrimitiveSets, 2U, @"floatObj.@avg >= %@", @3.3f);
    RLMAssertCount(AllPrimitiveSets, 2U, @"doubleObj.@avg >= %@", @3.3);
    RLMAssertCount(AllPrimitiveSets, 2U, @"decimalObj.@avg >= %@", decimal128(2));
    RLMAssertCount(AllPrimitiveSets, 2U, @"anyObjB.@avg >= %@", @3);
    RLMAssertCount(AllPrimitiveSets, 2U, @"anyObjC.@avg >= %@", @3.3f);
    RLMAssertCount(AllPrimitiveSets, 2U, @"anyObjD.@avg >= %@", @3.3);
    RLMAssertCount(AllPrimitiveSets, 2U, @"anyObjH.@avg >= %@", decimal128(2));
    RLMAssertCount(AllOptionalPrimitiveSets, 2U, @"intObj.@avg >= %@", @3);
    RLMAssertCount(AllOptionalPrimitiveSets, 2U, @"floatObj.@avg >= %@", @3.3f);
    RLMAssertCount(AllOptionalPrimitiveSets, 2U, @"doubleObj.@avg >= %@", @3.3);
    RLMAssertCount(AllOptionalPrimitiveSets, 2U, @"decimalObj.@avg >= %@", decimal128(2));
    RLMAssertCount(AllPrimitiveSets, 3U, @"intObj.@avg > %@", @2);
    RLMAssertCount(AllPrimitiveSets, 3U, @"floatObj.@avg > %@", @2.2f);
    RLMAssertCount(AllPrimitiveSets, 3U, @"doubleObj.@avg > %@", @2.2);
    RLMAssertCount(AllPrimitiveSets, 3U, @"decimalObj.@avg > %@", decimal128(1));
    RLMAssertCount(AllPrimitiveSets, 3U, @"anyObjB.@avg > %@", @2);
    RLMAssertCount(AllPrimitiveSets, 3U, @"anyObjC.@avg > %@", @2.2f);
    RLMAssertCount(AllPrimitiveSets, 3U, @"anyObjD.@avg > %@", @2.2);
    RLMAssertCount(AllPrimitiveSets, 3U, @"anyObjH.@avg > %@", decimal128(1));
    RLMAssertCount(AllOptionalPrimitiveSets, 3U, @"intObj.@avg > %@", @2);
    RLMAssertCount(AllOptionalPrimitiveSets, 3U, @"floatObj.@avg > %@", @2.2f);
    RLMAssertCount(AllOptionalPrimitiveSets, 3U, @"doubleObj.@avg > %@", @2.2);
    RLMAssertCount(AllOptionalPrimitiveSets, 3U, @"decimalObj.@avg > %@", decimal128(1));
    RLMAssertCount(AllPrimitiveSets, 1U, @"intObj.@avg < %@", @3);
    RLMAssertCount(AllPrimitiveSets, 1U, @"floatObj.@avg < %@", @3.3f);
    RLMAssertCount(AllPrimitiveSets, 1U, @"doubleObj.@avg < %@", @3.3);
    RLMAssertCount(AllPrimitiveSets, 1U, @"decimalObj.@avg < %@", decimal128(2));
    RLMAssertCount(AllPrimitiveSets, 1U, @"anyObjB.@avg < %@", @3);
    RLMAssertCount(AllPrimitiveSets, 1U, @"anyObjC.@avg < %@", @3.3f);
    RLMAssertCount(AllPrimitiveSets, 1U, @"anyObjD.@avg < %@", @3.3);
    RLMAssertCount(AllPrimitiveSets, 1U, @"anyObjH.@avg < %@", decimal128(2));
    RLMAssertCount(AllOptionalPrimitiveSets, 1U, @"intObj.@avg < %@", @3);
    RLMAssertCount(AllOptionalPrimitiveSets, 1U, @"floatObj.@avg < %@", @3.3f);
    RLMAssertCount(AllOptionalPrimitiveSets, 1U, @"doubleObj.@avg < %@", @3.3);
    RLMAssertCount(AllOptionalPrimitiveSets, 1U, @"decimalObj.@avg < %@", decimal128(2));
    RLMAssertCount(AllPrimitiveSets, 3U, @"intObj.@avg <= %@", @3);
    RLMAssertCount(AllPrimitiveSets, 3U, @"floatObj.@avg <= %@", @3.3f);
    RLMAssertCount(AllPrimitiveSets, 3U, @"doubleObj.@avg <= %@", @3.3);
    RLMAssertCount(AllPrimitiveSets, 3U, @"decimalObj.@avg <= %@", decimal128(2));
    RLMAssertCount(AllPrimitiveSets, 3U, @"anyObjB.@avg <= %@", @3);
    RLMAssertCount(AllPrimitiveSets, 3U, @"anyObjC.@avg <= %@", @3.3f);
    RLMAssertCount(AllPrimitiveSets, 3U, @"anyObjD.@avg <= %@", @3.3);
    RLMAssertCount(AllPrimitiveSets, 3U, @"anyObjH.@avg <= %@", decimal128(2));
    RLMAssertCount(AllOptionalPrimitiveSets, 3U, @"intObj.@avg <= %@", @3);
    RLMAssertCount(AllOptionalPrimitiveSets, 3U, @"floatObj.@avg <= %@", @3.3f);
    RLMAssertCount(AllOptionalPrimitiveSets, 3U, @"doubleObj.@avg <= %@", @3.3);
    RLMAssertCount(AllOptionalPrimitiveSets, 3U, @"decimalObj.@avg <= %@", decimal128(2));
}

- (void)testQueryMin {
    [realm deleteAllObjects];

    RLMAssertThrowsWithReason(([AllPrimitiveSets objectsInRealm:realm where:@"boolObj.@min = %@", @NO]), 
                              @"@min can only be applied to a numeric property.");
    RLMAssertThrowsWithReason(([AllPrimitiveSets objectsInRealm:realm where:@"stringObj.@min = %@", @"a"]), 
                              @"@min can only be applied to a numeric property.");
    RLMAssertThrowsWithReason(([AllPrimitiveSets objectsInRealm:realm where:@"dataObj.@min = %@", data(1)]), 
                              @"@min can only be applied to a numeric property.");
    RLMAssertThrowsWithReason(([AllPrimitiveSets objectsInRealm:realm where:@"objectIdObj.@min = %@", objectId(1)]), 
                              @"@min can only be applied to a numeric property.");
    RLMAssertThrowsWithReason(([AllPrimitiveSets objectsInRealm:realm where:@"uuidObj.@min = %@", uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")]), 
                              @"@min can only be applied to a numeric property.");
    RLMAssertThrowsWithReason(([AllOptionalPrimitiveSets objectsInRealm:realm where:@"boolObj.@min = %@", NSNull.null]), 
                              @"@min can only be applied to a numeric property.");
    RLMAssertThrowsWithReason(([AllOptionalPrimitiveSets objectsInRealm:realm where:@"stringObj.@min = %@", NSNull.null]), 
                              @"@min can only be applied to a numeric property.");
    RLMAssertThrowsWithReason(([AllOptionalPrimitiveSets objectsInRealm:realm where:@"dataObj.@min = %@", NSNull.null]), 
                              @"@min can only be applied to a numeric property.");
    RLMAssertThrowsWithReason(([AllOptionalPrimitiveSets objectsInRealm:realm where:@"objectIdObj.@min = %@", NSNull.null]), 
                              @"@min can only be applied to a numeric property.");
    RLMAssertThrowsWithReason(([AllOptionalPrimitiveSets objectsInRealm:realm where:@"uuidObj.@min = %@", NSNull.null]), 
                              @"@min can only be applied to a numeric property.");
    RLMAssertThrowsWithReason(([AllPrimitiveSets objectsInRealm:realm where:@"anyObjA.@min = %@", @NO]), 
                              @"Unsupported comparision value type for mixed. Value must be numeric.");
    RLMAssertThrowsWithReason(([AllPrimitiveSets objectsInRealm:realm where:@"anyObjE.@min = %@", @"a"]), 
                              @"Unsupported comparision value type for mixed. Value must be numeric.");
    RLMAssertThrowsWithReason(([AllPrimitiveSets objectsInRealm:realm where:@"anyObjF.@min = %@", data(1)]), 
                              @"Unsupported comparision value type for mixed. Value must be numeric.");
    RLMAssertThrowsWithReason(([AllPrimitiveSets objectsInRealm:realm where:@"anyObjI.@min = %@", objectId(1)]), 
                              @"Unsupported comparision value type for mixed. Value must be numeric.");
    RLMAssertThrowsWithReason(([AllPrimitiveSets objectsInRealm:realm where:@"anyObjJ.@min = %@", uuid(@"00000000-0000-0000-0000-000000000000")]), 
                              @"Unsupported comparision value type for mixed. Value must be numeric.");
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
    RLMAssertThrowsWithReason(([AllPrimitiveSets objectsInRealm:realm where:@"anyObjB.@min = %@", @"a"]), 
                              @"Unsupported comparision value type for mixed. Value must be numeric.");
    RLMAssertThrowsWithReason(([AllPrimitiveSets objectsInRealm:realm where:@"anyObjC.@min = %@", @"a"]), 
                              @"Unsupported comparision value type for mixed. Value must be numeric.");
    RLMAssertThrowsWithReason(([AllPrimitiveSets objectsInRealm:realm where:@"anyObjD.@min = %@", @"a"]), 
                              @"Unsupported comparision value type for mixed. Value must be numeric.");
    RLMAssertThrowsWithReason(([AllPrimitiveSets objectsInRealm:realm where:@"anyObjG.@min = %@", @"a"]), 
                              @"Unsupported comparision value type for mixed. Value must be numeric.");
    RLMAssertThrowsWithReason(([AllPrimitiveSets objectsInRealm:realm where:@"anyObjH.@min = %@", @"a"]), 
                              @"Unsupported comparision value type for mixed. Value must be numeric.");
    RLMAssertThrowsWithReason(([AllPrimitiveSets objectsInRealm:realm where:@"intObj.@min.prop = %@", @"a"]), 
                              @"Property 'intObj' is not a link in object of type 'AllPrimitiveSets'");
    RLMAssertThrowsWithReason(([AllPrimitiveSets objectsInRealm:realm where:@"floatObj.@min.prop = %@", @"a"]), 
                              @"Property 'floatObj' is not a link in object of type 'AllPrimitiveSets'");
    RLMAssertThrowsWithReason(([AllPrimitiveSets objectsInRealm:realm where:@"doubleObj.@min.prop = %@", @"a"]), 
                              @"Property 'doubleObj' is not a link in object of type 'AllPrimitiveSets'");
    RLMAssertThrowsWithReason(([AllPrimitiveSets objectsInRealm:realm where:@"dateObj.@min.prop = %@", @"a"]), 
                              @"Property 'dateObj' is not a link in object of type 'AllPrimitiveSets'");
    RLMAssertThrowsWithReason(([AllPrimitiveSets objectsInRealm:realm where:@"decimalObj.@min.prop = %@", @"a"]), 
                              @"Property 'decimalObj' is not a link in object of type 'AllPrimitiveSets'");
    RLMAssertThrowsWithReason(([AllPrimitiveSets objectsInRealm:realm where:@"anyObjB.@min.prop = %@", @"a"]), 
                              @"Property 'anyObjB' is not a link in object of type 'AllPrimitiveSets'");
    RLMAssertThrowsWithReason(([AllPrimitiveSets objectsInRealm:realm where:@"anyObjC.@min.prop = %@", @"a"]), 
                              @"Property 'anyObjC' is not a link in object of type 'AllPrimitiveSets'");
    RLMAssertThrowsWithReason(([AllPrimitiveSets objectsInRealm:realm where:@"anyObjD.@min.prop = %@", @"a"]), 
                              @"Property 'anyObjD' is not a link in object of type 'AllPrimitiveSets'");
    RLMAssertThrowsWithReason(([AllPrimitiveSets objectsInRealm:realm where:@"anyObjG.@min.prop = %@", @"a"]), 
                              @"Property 'anyObjG' is not a link in object of type 'AllPrimitiveSets'");
    RLMAssertThrowsWithReason(([AllPrimitiveSets objectsInRealm:realm where:@"anyObjH.@min.prop = %@", @"a"]), 
                              @"Property 'anyObjH' is not a link in object of type 'AllPrimitiveSets'");
    RLMAssertThrowsWithReason(([AllOptionalPrimitiveSets objectsInRealm:realm where:@"intObj.@min.prop = %@", @"a"]), 
                              @"Property 'intObj' is not a link in object of type 'AllOptionalPrimitiveSets'");
    RLMAssertThrowsWithReason(([AllOptionalPrimitiveSets objectsInRealm:realm where:@"floatObj.@min.prop = %@", @"a"]), 
                              @"Property 'floatObj' is not a link in object of type 'AllOptionalPrimitiveSets'");
    RLMAssertThrowsWithReason(([AllOptionalPrimitiveSets objectsInRealm:realm where:@"doubleObj.@min.prop = %@", @"a"]), 
                              @"Property 'doubleObj' is not a link in object of type 'AllOptionalPrimitiveSets'");
    RLMAssertThrowsWithReason(([AllOptionalPrimitiveSets objectsInRealm:realm where:@"dateObj.@min.prop = %@", @"a"]), 
                              @"Property 'dateObj' is not a link in object of type 'AllOptionalPrimitiveSets'");
    RLMAssertThrowsWithReason(([AllOptionalPrimitiveSets objectsInRealm:realm where:@"decimalObj.@min.prop = %@", @"a"]), 
                              @"Property 'decimalObj' is not a link in object of type 'AllOptionalPrimitiveSets'");

    // No objects, so count is zero
    RLMAssertCount(AllPrimitiveSets, 0U, @"intObj.@min == %@", @2);
    RLMAssertCount(AllPrimitiveSets, 0U, @"floatObj.@min == %@", @2.2f);
    RLMAssertCount(AllPrimitiveSets, 0U, @"doubleObj.@min == %@", @2.2);
    RLMAssertCount(AllPrimitiveSets, 0U, @"dateObj.@min == %@", date(1));
    RLMAssertCount(AllPrimitiveSets, 0U, @"decimalObj.@min == %@", decimal128(1));
    RLMAssertCount(AllPrimitiveSets, 0U, @"anyObjB.@min == %@", @2);
    RLMAssertCount(AllPrimitiveSets, 0U, @"anyObjC.@min == %@", @2.2f);
    RLMAssertCount(AllPrimitiveSets, 0U, @"anyObjD.@min == %@", @2.2);
    RLMAssertCount(AllPrimitiveSets, 0U, @"anyObjG.@min == %@", date(1));
    RLMAssertCount(AllPrimitiveSets, 0U, @"anyObjH.@min == %@", decimal128(1));
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
    RLMAssertCount(AllPrimitiveSets, 0U, @"anyObjB.@min == %@", @2);
    RLMAssertCount(AllPrimitiveSets, 0U, @"anyObjC.@min == %@", @2.2f);
    RLMAssertCount(AllPrimitiveSets, 0U, @"anyObjD.@min == %@", @2.2);
    RLMAssertCount(AllPrimitiveSets, 0U, @"anyObjG.@min == %@", date(1));
    RLMAssertCount(AllPrimitiveSets, 0U, @"anyObjH.@min == %@", decimal128(1));
    RLMAssertCount(AllPrimitiveSets, 0U, @"intObj.@min == %@", @3);
    RLMAssertCount(AllPrimitiveSets, 0U, @"floatObj.@min == %@", @3.3f);
    RLMAssertCount(AllPrimitiveSets, 0U, @"doubleObj.@min == %@", @3.3);
    RLMAssertCount(AllPrimitiveSets, 0U, @"dateObj.@min == %@", date(2));
    RLMAssertCount(AllPrimitiveSets, 0U, @"decimalObj.@min == %@", decimal128(2));
    RLMAssertCount(AllPrimitiveSets, 0U, @"anyObjB.@min == %@", @3);
    RLMAssertCount(AllPrimitiveSets, 0U, @"anyObjC.@min == %@", @3.3f);
    RLMAssertCount(AllPrimitiveSets, 0U, @"anyObjD.@min == %@", @3.3);
    RLMAssertCount(AllPrimitiveSets, 0U, @"anyObjG.@min == %@", date(2));
    RLMAssertCount(AllPrimitiveSets, 0U, @"anyObjH.@min == %@", decimal128(2));

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
    RLMAssertCount(AllPrimitiveSets, 1U, @"anyObjB.@min == %@", @3);
    RLMAssertCount(AllPrimitiveSets, 1U, @"anyObjC.@min == %@", @3.3f);
    RLMAssertCount(AllPrimitiveSets, 1U, @"anyObjD.@min == %@", @3.3);
    RLMAssertCount(AllPrimitiveSets, 1U, @"anyObjG.@min == %@", date(2));
    RLMAssertCount(AllPrimitiveSets, 1U, @"anyObjH.@min == %@", decimal128(2));
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
    RLMAssertCount(AllPrimitiveSets, 0U, @"anyObjB.@min == %@", @2);
    RLMAssertCount(AllPrimitiveSets, 0U, @"anyObjC.@min == %@", @2.2f);
    RLMAssertCount(AllPrimitiveSets, 0U, @"anyObjD.@min == %@", @2.2);
    RLMAssertCount(AllPrimitiveSets, 0U, @"anyObjG.@min == %@", date(1));
    RLMAssertCount(AllPrimitiveSets, 0U, @"anyObjH.@min == %@", decimal128(1));
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
        @"anyObjB": @[@3, @2],
        @"anyObjC": @[@3.3f, @2.2f],
        @"anyObjD": @[@3.3, @2.2],
        @"anyObjG": @[date(2), date(1)],
        @"anyObjH": @[decimal128(2), decimal128(1)],
        @"anyObjB": @[@3, @2],
        @"anyObjC": @[@3.3f, @2.2f],
        @"anyObjD": @[@3.3, @2.2],
        @"anyObjG": @[date(2), date(1)],
        @"anyObjH": @[decimal128(2), decimal128(1)],
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
    RLMAssertCount(AllPrimitiveSets, 1U, @"anyObjB.@min == %@", @2);
    RLMAssertCount(AllPrimitiveSets, 1U, @"anyObjC.@min == %@", @2.2f);
    RLMAssertCount(AllPrimitiveSets, 1U, @"anyObjD.@min == %@", @2.2);
    RLMAssertCount(AllPrimitiveSets, 1U, @"anyObjG.@min == %@", date(1));
    RLMAssertCount(AllPrimitiveSets, 1U, @"anyObjH.@min == %@", decimal128(1));
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
    RLMAssertCount(AllPrimitiveSets, 1U, @"anyObjB.@min == %@", @2);
    RLMAssertCount(AllPrimitiveSets, 1U, @"anyObjC.@min == %@", @2.2f);
    RLMAssertCount(AllPrimitiveSets, 1U, @"anyObjD.@min == %@", @2.2);
    RLMAssertCount(AllPrimitiveSets, 1U, @"anyObjG.@min == %@", date(1));
    RLMAssertCount(AllPrimitiveSets, 1U, @"anyObjH.@min == %@", decimal128(1));
    RLMAssertCount(AllOptionalPrimitiveSets, 2U, @"intObj.@min == %@", @2);
    RLMAssertCount(AllOptionalPrimitiveSets, 2U, @"floatObj.@min == %@", @2.2f);
    RLMAssertCount(AllOptionalPrimitiveSets, 2U, @"doubleObj.@min == %@", @2.2);
    RLMAssertCount(AllOptionalPrimitiveSets, 2U, @"dateObj.@min == %@", date(1));
    RLMAssertCount(AllOptionalPrimitiveSets, 2U, @"decimalObj.@min == %@", decimal128(1));
}

- (void)testQueryMax {
    [realm deleteAllObjects];

    RLMAssertThrowsWithReason(([AllPrimitiveSets objectsInRealm:realm where:@"boolObj.@max = %@", @NO]), 
                              @"@max can only be applied to a numeric property.");
    RLMAssertThrowsWithReason(([AllPrimitiveSets objectsInRealm:realm where:@"stringObj.@max = %@", @"a"]), 
                              @"@max can only be applied to a numeric property.");
    RLMAssertThrowsWithReason(([AllPrimitiveSets objectsInRealm:realm where:@"dataObj.@max = %@", data(1)]), 
                              @"@max can only be applied to a numeric property.");
    RLMAssertThrowsWithReason(([AllPrimitiveSets objectsInRealm:realm where:@"objectIdObj.@max = %@", objectId(1)]), 
                              @"@max can only be applied to a numeric property.");
    RLMAssertThrowsWithReason(([AllPrimitiveSets objectsInRealm:realm where:@"uuidObj.@max = %@", uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")]), 
                              @"@max can only be applied to a numeric property.");
    RLMAssertThrowsWithReason(([AllOptionalPrimitiveSets objectsInRealm:realm where:@"boolObj.@max = %@", NSNull.null]), 
                              @"@max can only be applied to a numeric property.");
    RLMAssertThrowsWithReason(([AllOptionalPrimitiveSets objectsInRealm:realm where:@"stringObj.@max = %@", NSNull.null]), 
                              @"@max can only be applied to a numeric property.");
    RLMAssertThrowsWithReason(([AllOptionalPrimitiveSets objectsInRealm:realm where:@"dataObj.@max = %@", NSNull.null]), 
                              @"@max can only be applied to a numeric property.");
    RLMAssertThrowsWithReason(([AllOptionalPrimitiveSets objectsInRealm:realm where:@"objectIdObj.@max = %@", NSNull.null]), 
                              @"@max can only be applied to a numeric property.");
    RLMAssertThrowsWithReason(([AllOptionalPrimitiveSets objectsInRealm:realm where:@"uuidObj.@max = %@", NSNull.null]), 
                              @"@max can only be applied to a numeric property.");
    RLMAssertThrowsWithReason(([AllPrimitiveSets objectsInRealm:realm where:@"anyObjA.@max = %@", @NO]), 
                              @"Unsupported comparision value type for mixed. Value must be numeric.");
    RLMAssertThrowsWithReason(([AllPrimitiveSets objectsInRealm:realm where:@"anyObjE.@max = %@", @"a"]), 
                              @"Unsupported comparision value type for mixed. Value must be numeric.");
    RLMAssertThrowsWithReason(([AllPrimitiveSets objectsInRealm:realm where:@"anyObjF.@max = %@", data(1)]), 
                              @"Unsupported comparision value type for mixed. Value must be numeric.");
    RLMAssertThrowsWithReason(([AllPrimitiveSets objectsInRealm:realm where:@"anyObjI.@max = %@", objectId(1)]), 
                              @"Unsupported comparision value type for mixed. Value must be numeric.");
    RLMAssertThrowsWithReason(([AllPrimitiveSets objectsInRealm:realm where:@"anyObjJ.@max = %@", uuid(@"00000000-0000-0000-0000-000000000000")]), 
                              @"Unsupported comparision value type for mixed. Value must be numeric.");
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
    RLMAssertThrowsWithReason(([AllPrimitiveSets objectsInRealm:realm where:@"anyObjB.@max = %@", @"a"]), 
                              @"Unsupported comparision value type for mixed. Value must be numeric.");
    RLMAssertThrowsWithReason(([AllPrimitiveSets objectsInRealm:realm where:@"anyObjC.@max = %@", @"a"]), 
                              @"Unsupported comparision value type for mixed. Value must be numeric.");
    RLMAssertThrowsWithReason(([AllPrimitiveSets objectsInRealm:realm where:@"anyObjD.@max = %@", @"a"]), 
                              @"Unsupported comparision value type for mixed. Value must be numeric.");
    RLMAssertThrowsWithReason(([AllPrimitiveSets objectsInRealm:realm where:@"anyObjG.@max = %@", @"a"]), 
                              @"Unsupported comparision value type for mixed. Value must be numeric.");
    RLMAssertThrowsWithReason(([AllPrimitiveSets objectsInRealm:realm where:@"anyObjH.@max = %@", @"a"]), 
                              @"Unsupported comparision value type for mixed. Value must be numeric.");
    RLMAssertThrowsWithReason(([AllPrimitiveSets objectsInRealm:realm where:@"intObj.@max.prop = %@", @"a"]), 
                              @"Property 'intObj' is not a link in object of type 'AllPrimitiveSets'");
    RLMAssertThrowsWithReason(([AllPrimitiveSets objectsInRealm:realm where:@"floatObj.@max.prop = %@", @"a"]), 
                              @"Property 'floatObj' is not a link in object of type 'AllPrimitiveSets'");
    RLMAssertThrowsWithReason(([AllPrimitiveSets objectsInRealm:realm where:@"doubleObj.@max.prop = %@", @"a"]), 
                              @"Property 'doubleObj' is not a link in object of type 'AllPrimitiveSets'");
    RLMAssertThrowsWithReason(([AllPrimitiveSets objectsInRealm:realm where:@"dateObj.@max.prop = %@", @"a"]), 
                              @"Property 'dateObj' is not a link in object of type 'AllPrimitiveSets'");
    RLMAssertThrowsWithReason(([AllPrimitiveSets objectsInRealm:realm where:@"decimalObj.@max.prop = %@", @"a"]), 
                              @"Property 'decimalObj' is not a link in object of type 'AllPrimitiveSets'");
    RLMAssertThrowsWithReason(([AllPrimitiveSets objectsInRealm:realm where:@"anyObjB.@max.prop = %@", @"a"]), 
                              @"Property 'anyObjB' is not a link in object of type 'AllPrimitiveSets'");
    RLMAssertThrowsWithReason(([AllPrimitiveSets objectsInRealm:realm where:@"anyObjC.@max.prop = %@", @"a"]), 
                              @"Property 'anyObjC' is not a link in object of type 'AllPrimitiveSets'");
    RLMAssertThrowsWithReason(([AllPrimitiveSets objectsInRealm:realm where:@"anyObjD.@max.prop = %@", @"a"]), 
                              @"Property 'anyObjD' is not a link in object of type 'AllPrimitiveSets'");
    RLMAssertThrowsWithReason(([AllPrimitiveSets objectsInRealm:realm where:@"anyObjG.@max.prop = %@", @"a"]), 
                              @"Property 'anyObjG' is not a link in object of type 'AllPrimitiveSets'");
    RLMAssertThrowsWithReason(([AllPrimitiveSets objectsInRealm:realm where:@"anyObjH.@max.prop = %@", @"a"]), 
                              @"Property 'anyObjH' is not a link in object of type 'AllPrimitiveSets'");
    RLMAssertThrowsWithReason(([AllOptionalPrimitiveSets objectsInRealm:realm where:@"intObj.@max.prop = %@", @"a"]), 
                              @"Property 'intObj' is not a link in object of type 'AllOptionalPrimitiveSets'");
    RLMAssertThrowsWithReason(([AllOptionalPrimitiveSets objectsInRealm:realm where:@"floatObj.@max.prop = %@", @"a"]), 
                              @"Property 'floatObj' is not a link in object of type 'AllOptionalPrimitiveSets'");
    RLMAssertThrowsWithReason(([AllOptionalPrimitiveSets objectsInRealm:realm where:@"doubleObj.@max.prop = %@", @"a"]), 
                              @"Property 'doubleObj' is not a link in object of type 'AllOptionalPrimitiveSets'");
    RLMAssertThrowsWithReason(([AllOptionalPrimitiveSets objectsInRealm:realm where:@"dateObj.@max.prop = %@", @"a"]), 
                              @"Property 'dateObj' is not a link in object of type 'AllOptionalPrimitiveSets'");
    RLMAssertThrowsWithReason(([AllOptionalPrimitiveSets objectsInRealm:realm where:@"decimalObj.@max.prop = %@", @"a"]), 
                              @"Property 'decimalObj' is not a link in object of type 'AllOptionalPrimitiveSets'");

    // No objects, so count is zero
    RLMAssertCount(AllPrimitiveSets, 0U, @"intObj.@max == %@", @2);
    RLMAssertCount(AllPrimitiveSets, 0U, @"floatObj.@max == %@", @2.2f);
    RLMAssertCount(AllPrimitiveSets, 0U, @"doubleObj.@max == %@", @2.2);
    RLMAssertCount(AllPrimitiveSets, 0U, @"dateObj.@max == %@", date(1));
    RLMAssertCount(AllPrimitiveSets, 0U, @"decimalObj.@max == %@", decimal128(1));
    RLMAssertCount(AllPrimitiveSets, 0U, @"anyObjB.@max == %@", @2);
    RLMAssertCount(AllPrimitiveSets, 0U, @"anyObjC.@max == %@", @2.2f);
    RLMAssertCount(AllPrimitiveSets, 0U, @"anyObjD.@max == %@", @2.2);
    RLMAssertCount(AllPrimitiveSets, 0U, @"anyObjG.@max == %@", date(1));
    RLMAssertCount(AllPrimitiveSets, 0U, @"anyObjH.@max == %@", decimal128(1));
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
    RLMAssertCount(AllPrimitiveSets, 0U, @"anyObjB.@max == %@", @2);
    RLMAssertCount(AllPrimitiveSets, 0U, @"anyObjC.@max == %@", @2.2f);
    RLMAssertCount(AllPrimitiveSets, 0U, @"anyObjD.@max == %@", @2.2);
    RLMAssertCount(AllPrimitiveSets, 0U, @"anyObjG.@max == %@", date(1));
    RLMAssertCount(AllPrimitiveSets, 0U, @"anyObjH.@max == %@", decimal128(1));
    RLMAssertCount(AllPrimitiveSets, 0U, @"intObj.@max == %@", @3);
    RLMAssertCount(AllPrimitiveSets, 0U, @"floatObj.@max == %@", @3.3f);
    RLMAssertCount(AllPrimitiveSets, 0U, @"doubleObj.@max == %@", @3.3);
    RLMAssertCount(AllPrimitiveSets, 0U, @"dateObj.@max == %@", date(2));
    RLMAssertCount(AllPrimitiveSets, 0U, @"decimalObj.@max == %@", decimal128(2));
    RLMAssertCount(AllPrimitiveSets, 0U, @"anyObjB.@max == %@", @3);
    RLMAssertCount(AllPrimitiveSets, 0U, @"anyObjC.@max == %@", @3.3f);
    RLMAssertCount(AllPrimitiveSets, 0U, @"anyObjD.@max == %@", @3.3);
    RLMAssertCount(AllPrimitiveSets, 0U, @"anyObjG.@max == %@", date(2));
    RLMAssertCount(AllPrimitiveSets, 0U, @"anyObjH.@max == %@", decimal128(2));

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
    RLMAssertCount(AllPrimitiveSets, 1U, @"anyObjB.@max == nil");
    RLMAssertCount(AllPrimitiveSets, 1U, @"anyObjC.@max == nil");
    RLMAssertCount(AllPrimitiveSets, 1U, @"anyObjD.@max == nil");
    RLMAssertCount(AllPrimitiveSets, 1U, @"anyObjG.@max == nil");
    RLMAssertCount(AllPrimitiveSets, 1U, @"anyObjH.@max == nil");
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
    RLMAssertCount(AllPrimitiveSets, 1U, @"anyObjB.@max == %@", NSNull.null);
    RLMAssertCount(AllPrimitiveSets, 1U, @"anyObjC.@max == %@", NSNull.null);
    RLMAssertCount(AllPrimitiveSets, 1U, @"anyObjD.@max == %@", NSNull.null);
    RLMAssertCount(AllPrimitiveSets, 1U, @"anyObjG.@max == %@", NSNull.null);
    RLMAssertCount(AllPrimitiveSets, 1U, @"anyObjH.@max == %@", NSNull.null);
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
    RLMAssertCount(AllPrimitiveSets, 1U, @"anyObjB.@max == %@", @3);
    RLMAssertCount(AllPrimitiveSets, 1U, @"anyObjC.@max == %@", @3.3f);
    RLMAssertCount(AllPrimitiveSets, 1U, @"anyObjD.@max == %@", @3.3);
    RLMAssertCount(AllPrimitiveSets, 1U, @"anyObjG.@max == %@", date(2));
    RLMAssertCount(AllPrimitiveSets, 1U, @"anyObjH.@max == %@", decimal128(2));
    RLMAssertCount(AllPrimitiveSets, 0U, @"intObj.@max == %@", @2);
    RLMAssertCount(AllPrimitiveSets, 0U, @"floatObj.@max == %@", @2.2f);
    RLMAssertCount(AllPrimitiveSets, 0U, @"doubleObj.@max == %@", @2.2);
    RLMAssertCount(AllPrimitiveSets, 0U, @"dateObj.@max == %@", date(1));
    RLMAssertCount(AllPrimitiveSets, 0U, @"decimalObj.@max == %@", decimal128(1));
    RLMAssertCount(AllPrimitiveSets, 0U, @"anyObjB.@max == %@", @2);
    RLMAssertCount(AllPrimitiveSets, 0U, @"anyObjC.@max == %@", @2.2f);
    RLMAssertCount(AllPrimitiveSets, 0U, @"anyObjD.@max == %@", @2.2);
    RLMAssertCount(AllPrimitiveSets, 0U, @"anyObjG.@max == %@", date(1));
    RLMAssertCount(AllPrimitiveSets, 0U, @"anyObjH.@max == %@", decimal128(1));

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
        @"anyObjB": @[@2],
        @"anyObjC": @[@2.2f],
        @"anyObjD": @[@2.2],
        @"anyObjG": @[date(1)],
        @"anyObjH": @[decimal128(1)],
        @"anyObjB": @[@2],
        @"anyObjC": @[@2.2f],
        @"anyObjD": @[@2.2],
        @"anyObjG": @[date(1)],
        @"anyObjH": @[decimal128(1)],
    }];

    [AllPrimitiveSets createInRealm:realm withValue:@{
        @"intObj": @[@3, @2],
        @"floatObj": @[@3.3f, @2.2f],
        @"doubleObj": @[@3.3, @2.2],
        @"dateObj": @[date(2), date(1)],
        @"decimalObj": @[decimal128(2), decimal128(1)],
        @"anyObjB": @[@3, @2],
        @"anyObjC": @[@3.3f, @2.2f],
        @"anyObjD": @[@3.3, @2.2],
        @"anyObjG": @[date(2), date(1)],
        @"anyObjH": @[decimal128(2), decimal128(1)],
        @"anyObjB": @[@3, @2],
        @"anyObjC": @[@3.3f, @2.2f],
        @"anyObjD": @[@3.3, @2.2],
        @"anyObjG": @[date(2), date(1)],
        @"anyObjH": @[decimal128(2), decimal128(1)],
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

    RLMAssertCount(AllPrimitiveSets, 1U, @"anyObjB.@max == %@", @2);
    RLMAssertCount(AllPrimitiveSets, 1U, @"anyObjC.@max == %@", @2.2f);
    RLMAssertCount(AllPrimitiveSets, 1U, @"anyObjD.@max == %@", @2.2);
    RLMAssertCount(AllPrimitiveSets, 1U, @"anyObjG.@max == %@", date(1));
    RLMAssertCount(AllPrimitiveSets, 1U, @"anyObjH.@max == %@", decimal128(1));
    RLMAssertCount(AllPrimitiveSets, 2U, @"anyObjB.@max == %@", @3);
    RLMAssertCount(AllPrimitiveSets, 2U, @"anyObjC.@max == %@", @3.3f);
    RLMAssertCount(AllPrimitiveSets, 2U, @"anyObjD.@max == %@", @3.3);
    RLMAssertCount(AllPrimitiveSets, 2U, @"anyObjG.@max == %@", date(2));
    RLMAssertCount(AllPrimitiveSets, 2U, @"anyObjH.@max == %@", decimal128(2));
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
    RLMAssertCount(LinkToAllPrimitiveSets, 0, @"ANY link.anyObjA = %@", @NO);
    RLMAssertCount(LinkToAllPrimitiveSets, 0, @"ANY link.anyObjB = %@", @2);
    RLMAssertCount(LinkToAllPrimitiveSets, 0, @"ANY link.anyObjC = %@", @2.2f);
    RLMAssertCount(LinkToAllPrimitiveSets, 0, @"ANY link.anyObjD = %@", @2.2);
    RLMAssertCount(LinkToAllPrimitiveSets, 0, @"ANY link.anyObjE = %@", @"a");
    RLMAssertCount(LinkToAllPrimitiveSets, 0, @"ANY link.anyObjF = %@", data(1));
    RLMAssertCount(LinkToAllPrimitiveSets, 0, @"ANY link.anyObjG = %@", date(1));
    RLMAssertCount(LinkToAllPrimitiveSets, 0, @"ANY link.anyObjH = %@", decimal128(1));
    RLMAssertCount(LinkToAllPrimitiveSets, 0, @"ANY link.anyObjI = %@", objectId(1));
    RLMAssertCount(LinkToAllPrimitiveSets, 0, @"ANY link.anyObjJ = %@", uuid(@"00000000-0000-0000-0000-000000000000"));
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
    RLMAssertCount(LinkToAllPrimitiveSets, 0, @"ANY link.anyObjA != %@", @NO);
    RLMAssertCount(LinkToAllPrimitiveSets, 0, @"ANY link.anyObjB != %@", @2);
    RLMAssertCount(LinkToAllPrimitiveSets, 0, @"ANY link.anyObjC != %@", @2.2f);
    RLMAssertCount(LinkToAllPrimitiveSets, 0, @"ANY link.anyObjD != %@", @2.2);
    RLMAssertCount(LinkToAllPrimitiveSets, 0, @"ANY link.anyObjE != %@", @"a");
    RLMAssertCount(LinkToAllPrimitiveSets, 0, @"ANY link.anyObjF != %@", data(1));
    RLMAssertCount(LinkToAllPrimitiveSets, 0, @"ANY link.anyObjG != %@", date(1));
    RLMAssertCount(LinkToAllPrimitiveSets, 0, @"ANY link.anyObjH != %@", decimal128(1));
    RLMAssertCount(LinkToAllPrimitiveSets, 0, @"ANY link.anyObjI != %@", objectId(1));
    RLMAssertCount(LinkToAllPrimitiveSets, 0, @"ANY link.anyObjJ != %@", uuid(@"00000000-0000-0000-0000-000000000000"));
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
    RLMAssertCount(LinkToAllPrimitiveSets, 0, @"ANY link.anyObjB > %@", @2);
    RLMAssertCount(LinkToAllPrimitiveSets, 0, @"ANY link.anyObjC > %@", @2.2f);
    RLMAssertCount(LinkToAllPrimitiveSets, 0, @"ANY link.anyObjD > %@", @2.2);
    RLMAssertCount(LinkToAllPrimitiveSets, 0, @"ANY link.anyObjG > %@", date(1));
    RLMAssertCount(LinkToAllPrimitiveSets, 0, @"ANY link.anyObjH > %@", decimal128(1));
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
    RLMAssertCount(LinkToAllPrimitiveSets, 0, @"ANY link.anyObjB >= %@", @2);
    RLMAssertCount(LinkToAllPrimitiveSets, 0, @"ANY link.anyObjC >= %@", @2.2f);
    RLMAssertCount(LinkToAllPrimitiveSets, 0, @"ANY link.anyObjD >= %@", @2.2);
    RLMAssertCount(LinkToAllPrimitiveSets, 0, @"ANY link.anyObjG >= %@", date(1));
    RLMAssertCount(LinkToAllPrimitiveSets, 0, @"ANY link.anyObjH >= %@", decimal128(1));
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
    RLMAssertCount(LinkToAllPrimitiveSets, 0, @"ANY link.anyObjB < %@", @2);
    RLMAssertCount(LinkToAllPrimitiveSets, 0, @"ANY link.anyObjC < %@", @2.2f);
    RLMAssertCount(LinkToAllPrimitiveSets, 0, @"ANY link.anyObjD < %@", @2.2);
    RLMAssertCount(LinkToAllPrimitiveSets, 0, @"ANY link.anyObjG < %@", date(1));
    RLMAssertCount(LinkToAllPrimitiveSets, 0, @"ANY link.anyObjH < %@", decimal128(1));
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
    RLMAssertCount(LinkToAllPrimitiveSets, 0, @"ANY link.anyObjB <= %@", @2);
    RLMAssertCount(LinkToAllPrimitiveSets, 0, @"ANY link.anyObjC <= %@", @2.2f);
    RLMAssertCount(LinkToAllPrimitiveSets, 0, @"ANY link.anyObjD <= %@", @2.2);
    RLMAssertCount(LinkToAllPrimitiveSets, 0, @"ANY link.anyObjG <= %@", date(1));
    RLMAssertCount(LinkToAllPrimitiveSets, 0, @"ANY link.anyObjH <= %@", decimal128(1));
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
    RLMAssertCount(LinkToAllPrimitiveSets, 1, @"ANY link.anyObjA = %@", @YES);
    RLMAssertCount(LinkToAllPrimitiveSets, 1, @"ANY link.anyObjB = %@", @3);
    RLMAssertCount(LinkToAllPrimitiveSets, 1, @"ANY link.anyObjC = %@", @3.3f);
    RLMAssertCount(LinkToAllPrimitiveSets, 1, @"ANY link.anyObjD = %@", @3.3);
    RLMAssertCount(LinkToAllPrimitiveSets, 1, @"ANY link.anyObjE = %@", @"b");
    RLMAssertCount(LinkToAllPrimitiveSets, 1, @"ANY link.anyObjF = %@", data(2));
    RLMAssertCount(LinkToAllPrimitiveSets, 1, @"ANY link.anyObjG = %@", date(2));
    RLMAssertCount(LinkToAllPrimitiveSets, 1, @"ANY link.anyObjH = %@", decimal128(2));
    RLMAssertCount(LinkToAllPrimitiveSets, 1, @"ANY link.anyObjI = %@", objectId(2));
    RLMAssertCount(LinkToAllPrimitiveSets, 1, @"ANY link.anyObjJ = %@", uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"));
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
    RLMAssertCount(LinkToAllPrimitiveSets, 1, @"ANY link.anyObjA != %@", @NO);
    RLMAssertCount(LinkToAllPrimitiveSets, 1, @"ANY link.anyObjB != %@", @2);
    RLMAssertCount(LinkToAllPrimitiveSets, 1, @"ANY link.anyObjC != %@", @2.2f);
    RLMAssertCount(LinkToAllPrimitiveSets, 1, @"ANY link.anyObjD != %@", @2.2);
    RLMAssertCount(LinkToAllPrimitiveSets, 1, @"ANY link.anyObjE != %@", @"a");
    RLMAssertCount(LinkToAllPrimitiveSets, 1, @"ANY link.anyObjF != %@", data(1));
    RLMAssertCount(LinkToAllPrimitiveSets, 1, @"ANY link.anyObjG != %@", date(1));
    RLMAssertCount(LinkToAllPrimitiveSets, 1, @"ANY link.anyObjH != %@", decimal128(1));
    RLMAssertCount(LinkToAllPrimitiveSets, 1, @"ANY link.anyObjI != %@", objectId(1));
    RLMAssertCount(LinkToAllPrimitiveSets, 1, @"ANY link.anyObjJ != %@", uuid(@"00000000-0000-0000-0000-000000000000"));
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
    RLMAssertCount(LinkToAllPrimitiveSets, 1, @"ANY link.anyObjB > %@", @2);
    RLMAssertCount(LinkToAllPrimitiveSets, 1, @"ANY link.anyObjC > %@", @2.2f);
    RLMAssertCount(LinkToAllPrimitiveSets, 1, @"ANY link.anyObjD > %@", @2.2);
    RLMAssertCount(LinkToAllPrimitiveSets, 1, @"ANY link.anyObjG > %@", date(1));
    RLMAssertCount(LinkToAllPrimitiveSets, 1, @"ANY link.anyObjH > %@", decimal128(1));
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
    RLMAssertCount(LinkToAllPrimitiveSets, 1, @"ANY link.anyObjB >= %@", @2);
    RLMAssertCount(LinkToAllPrimitiveSets, 1, @"ANY link.anyObjC >= %@", @2.2f);
    RLMAssertCount(LinkToAllPrimitiveSets, 1, @"ANY link.anyObjD >= %@", @2.2);
    RLMAssertCount(LinkToAllPrimitiveSets, 1, @"ANY link.anyObjG >= %@", date(1));
    RLMAssertCount(LinkToAllPrimitiveSets, 1, @"ANY link.anyObjH >= %@", decimal128(1));
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
    RLMAssertCount(LinkToAllPrimitiveSets, 0, @"ANY link.anyObjB < %@", @2);
    RLMAssertCount(LinkToAllPrimitiveSets, 0, @"ANY link.anyObjC < %@", @2.2f);
    RLMAssertCount(LinkToAllPrimitiveSets, 0, @"ANY link.anyObjD < %@", @2.2);
    RLMAssertCount(LinkToAllPrimitiveSets, 0, @"ANY link.anyObjG < %@", date(1));
    RLMAssertCount(LinkToAllPrimitiveSets, 0, @"ANY link.anyObjH < %@", decimal128(1));
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
    RLMAssertCount(LinkToAllPrimitiveSets, 1, @"ANY link.anyObjB < %@", @4);
    RLMAssertCount(LinkToAllPrimitiveSets, 1, @"ANY link.anyObjC < %@", @4.4f);
    RLMAssertCount(LinkToAllPrimitiveSets, 1, @"ANY link.anyObjD < %@", @4.4);
    RLMAssertCount(LinkToAllPrimitiveSets, 1, @"ANY link.anyObjG < %@", date(3));
    RLMAssertCount(LinkToAllPrimitiveSets, 1, @"ANY link.anyObjH < %@", decimal128(3));
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
    RLMAssertCount(LinkToAllPrimitiveSets, 1, @"ANY link.anyObjB <= %@", @3);
    RLMAssertCount(LinkToAllPrimitiveSets, 1, @"ANY link.anyObjC <= %@", @3.3f);
    RLMAssertCount(LinkToAllPrimitiveSets, 1, @"ANY link.anyObjD <= %@", @3.3);
    RLMAssertCount(LinkToAllPrimitiveSets, 1, @"ANY link.anyObjG <= %@", date(2));
    RLMAssertCount(LinkToAllPrimitiveSets, 1, @"ANY link.anyObjH <= %@", decimal128(2));
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
    RLMAssertThrowsWithReason(([LinkToAllPrimitiveSets objectsInRealm:realm where:@"ANY link.anyObjA > %@", @NO]), 
                              @"Operator '>' not supported for type 'mixed'");
    RLMAssertThrowsWithReason(([LinkToAllPrimitiveSets objectsInRealm:realm where:@"ANY link.anyObjE > %@", @"a"]), 
                              @"Operator '>' not supported for type 'mixed'");
    RLMAssertThrowsWithReason(([LinkToAllPrimitiveSets objectsInRealm:realm where:@"ANY link.anyObjF > %@", data(1)]), 
                              @"Operator '>' not supported for type 'mixed'");
    RLMAssertThrowsWithReason(([LinkToAllPrimitiveSets objectsInRealm:realm where:@"ANY link.anyObjI > %@", objectId(1)]), 
                              @"Operator '>' not supported for type 'mixed'");
    RLMAssertThrowsWithReason(([LinkToAllPrimitiveSets objectsInRealm:realm where:@"ANY link.anyObjJ > %@", uuid(@"00000000-0000-0000-0000-000000000000")]), 
                              @"Operator '>' not supported for type 'mixed'");
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
