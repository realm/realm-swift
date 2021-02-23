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
    [unmanaged.boolObj addObjects:@{@"0": @NO, @"1": @YES}];
    [unmanaged.intObj addObjects:@{@"0": @2, @"1": @3}];
    [unmanaged.floatObj addObjects:@{@"0": @2.2f, @"1": @3.3f}];
    [unmanaged.doubleObj addObjects:@{@"0": @2.2, @"1": @3.3}];
    [unmanaged.stringObj addObjects:@{@"0": @"a", @"1": @"b"}];
    [unmanaged.dataObj addObjects:@{@"0": data(1), @"1": data(2)}];
    [unmanaged.dateObj addObjects:@{@"0": date(1), @"1": date(2)}];
    [unmanaged.decimalObj addObjects:@{@"0": decimal128(2), @"1": decimal128(3)}];
    [unmanaged.objectIdObj addObjects:@{@"0": objectId(1), @"1": objectId(2)}];
    [unmanaged.uuidObj addObjects:@{@"0": uuid(@"00000000-0000-0000-0000-000000000000"), @"1": uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")}];
    [optUnmanaged.boolObj addObjects:@{@"0": @NO, @"1": @YES, @"2": NSNull.null}];
    [optUnmanaged.intObj addObjects:@{@"0": @2, @"1": @3, @"2": NSNull.null}];
    [optUnmanaged.floatObj addObjects:@{@"0": @2.2f, @"1": @3.3f, @"2": NSNull.null}];
    [optUnmanaged.doubleObj addObjects:@{@"0": @2.2, @"1": @3.3, @"2": NSNull.null}];
    [optUnmanaged.stringObj addObjects:@{@"0": @"a", @"1": @"b", @"2": NSNull.null}];
    [optUnmanaged.dataObj addObjects:@{@"0": data(1), @"1": data(2), @"2": NSNull.null}];
    [optUnmanaged.dateObj addObjects:@{@"0": date(1), @"1": date(2), @"2": NSNull.null}];
    [optUnmanaged.decimalObj addObjects:@{@"0": decimal128(2), @"1": decimal128(3), @"2": NSNull.null}];
    [optUnmanaged.objectIdObj addObjects:@{@"0": objectId(1), @"1": objectId(2), @"2": NSNull.null}];
    [optUnmanaged.uuidObj addObjects:@{@"0": uuid(@"00000000-0000-0000-0000-000000000000"), @"1": uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"), @"2": NSNull.null}];
    [managed.boolObj addObjects:@{@"0": @NO, @"1": @YES}];
    [managed.intObj addObjects:@{@"0": @2, @"1": @3}];
    [managed.floatObj addObjects:@{@"0": @2.2f, @"1": @3.3f}];
    [managed.doubleObj addObjects:@{@"0": @2.2, @"1": @3.3}];
    [managed.stringObj addObjects:@{@"0": @"a", @"1": @"b"}];
    [managed.dataObj addObjects:@{@"0": data(1), @"1": data(2)}];
    [managed.dateObj addObjects:@{@"0": date(1), @"1": date(2)}];
    [managed.decimalObj addObjects:@{@"0": decimal128(2), @"1": decimal128(3)}];
    [managed.objectIdObj addObjects:@{@"0": objectId(1), @"1": objectId(2)}];
    [managed.uuidObj addObjects:@{@"0": uuid(@"00000000-0000-0000-0000-000000000000"), @"1": uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")}];
    [optManaged.boolObj addObjects:@{@"0": @NO, @"1": @YES, @"2": NSNull.null}];
    [optManaged.intObj addObjects:@{@"0": @2, @"1": @3, @"2": NSNull.null}];
    [optManaged.floatObj addObjects:@{@"0": @2.2f, @"1": @3.3f, @"2": NSNull.null}];
    [optManaged.doubleObj addObjects:@{@"0": @2.2, @"1": @3.3, @"2": NSNull.null}];
    [optManaged.stringObj addObjects:@{@"0": @"a", @"1": @"b", @"2": NSNull.null}];
    [optManaged.dataObj addObjects:@{@"0": data(1), @"1": data(2), @"2": NSNull.null}];
    [optManaged.dateObj addObjects:@{@"0": date(1), @"1": date(2), @"2": NSNull.null}];
    [optManaged.decimalObj addObjects:@{@"0": decimal128(2), @"1": decimal128(3), @"2": NSNull.null}];
    [optManaged.objectIdObj addObjects:@{@"0": objectId(1), @"1": objectId(2), @"2": NSNull.null}];
    [optManaged.uuidObj addObjects:@{@"0": uuid(@"00000000-0000-0000-0000-000000000000"), @"1": uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"), @"2": NSNull.null}];
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
    for (RLMDictionary *dictionary in allDictionaries) {
        RLMAssertThrowsWithReason([realm deleteObjects:dictionary], @"Cannot delete objects from RLMArray");
    }
}

- (void)testObjectAtIndex {
    RLMAssertThrowsWithReason([unmanaged.intObj objectAtIndex:0],
                              @"Index 0 is out of bounds (must be less than 0).");
    unmanaged.intObj[@"testVal"] = @1;
    XCTAssertEqualObjects([unmanaged.intObj objectAtIndex:0], @1);
}

- (void)testFirstObject {
    for (RLMDictionary *dictionary in allDictionaries) {
        XCTAssertNil(dictionary.firstObject);
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

    for (RLMDictionary *dictionary in allDictionaries) {
        [dictionary removeAllObjects];
    }

}
/**
- (void)testLastObject {
    for (RLMDictionary *dictionary in allDictionaries) {
        XCTAssertNil(dictionary.lastObject);
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

    for (RLMDictionary *dictionary in allDictionaries) {
        [dictionary removeLastObject];
    }
}
*/

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wnonnull"

- (void)testSetObject {
    RLMAssertThrowsWithReason([unmanaged.boolObj setObject:@NO forKey:nil],
                              @"Should fail on nil key 'a' of type '__NSCFConstantString' for expected type 'bool'");
    RLMAssertThrowsWithReason([unmanaged.intObj setObject:@2 forKey:nil],
                              @"Should fail on nil key 'a' of type '__NSCFConstantString' for expected type 'int'");
    RLMAssertThrowsWithReason([unmanaged.floatObj setObject:@2.2f forKey:nil],
                              @"Should fail on nil key 'a' of type '__NSCFConstantString' for expected type 'float'");
    RLMAssertThrowsWithReason([unmanaged.doubleObj setObject:@2.2 forKey:nil],
                              @"Should fail on nil key 'a' of type '__NSCFConstantString' for expected type 'double'");
    RLMAssertThrowsWithReason([unmanaged.stringObj setObject:@"a" forKey:nil],
                              @"Should fail on nil key 'a' of type '__NSCFConstantString' for expected type 'string'");
    RLMAssertThrowsWithReason([unmanaged.dataObj setObject:data(1) forKey:nil],
                              @"Should fail on nil key 'a' of type '__NSCFConstantString' for expected type 'data'");
    RLMAssertThrowsWithReason([unmanaged.dateObj setObject:date(1) forKey:nil],
                              @"Should fail on nil key 'a' of type '__NSCFConstantString' for expected type 'date'");
    RLMAssertThrowsWithReason([unmanaged.decimalObj setObject:decimal128(2) forKey:nil],
                              @"Should fail on nil key 'a' of type '__NSCFConstantString' for expected type 'decimal128'");
    RLMAssertThrowsWithReason([unmanaged.objectIdObj setObject:objectId(1) forKey:nil],
                              @"Should fail on nil key 'a' of type '__NSCFConstantString' for expected type 'object id'");
    RLMAssertThrowsWithReason([unmanaged.uuidObj setObject:uuid(@"00000000-0000-0000-0000-000000000000") forKey:nil],
                              @"Should fail on nil key 'a' of type '__NSCFConstantString' for expected type 'uuid'");
    RLMAssertThrowsWithReason([optUnmanaged.boolObj setObject:@NO forKey:nil],
                              @"Should fail on nil key 'a' of type '__NSCFConstantString' for expected type 'bool?'");
    RLMAssertThrowsWithReason([optUnmanaged.intObj setObject:@2 forKey:nil],
                              @"Should fail on nil key 'a' of type '__NSCFConstantString' for expected type 'int?'");
    RLMAssertThrowsWithReason([optUnmanaged.floatObj setObject:@2.2f forKey:nil],
                              @"Should fail on nil key 'a' of type '__NSCFConstantString' for expected type 'float?'");
    RLMAssertThrowsWithReason([optUnmanaged.doubleObj setObject:@2.2 forKey:nil],
                              @"Should fail on nil key 'a' of type '__NSCFConstantString' for expected type 'double?'");
    RLMAssertThrowsWithReason([optUnmanaged.stringObj setObject:@"a" forKey:nil],
                              @"Should fail on nil key 'a' of type '__NSCFConstantString' for expected type 'string?'");
    RLMAssertThrowsWithReason([optUnmanaged.dataObj setObject:data(1) forKey:nil],
                              @"Should fail on nil key 'a' of type '__NSCFConstantString' for expected type 'data?'");
    RLMAssertThrowsWithReason([optUnmanaged.dateObj setObject:date(1) forKey:nil],
                              @"Should fail on nil key 'a' of type '__NSCFConstantString' for expected type 'date?'");
    RLMAssertThrowsWithReason([optUnmanaged.decimalObj setObject:decimal128(2) forKey:nil],
                              @"Should fail on nil key 'a' of type '__NSCFConstantString' for expected type 'decimal128?'");
    RLMAssertThrowsWithReason([optUnmanaged.objectIdObj setObject:objectId(1) forKey:nil],
                              @"Should fail on nil key 'a' of type '__NSCFConstantString' for expected type 'object id?'");
    RLMAssertThrowsWithReason([optUnmanaged.uuidObj setObject:uuid(@"00000000-0000-0000-0000-000000000000") forKey:nil],
                              @"Should fail on nil key 'a' of type '__NSCFConstantString' for expected type 'uuid?'");
    RLMAssertThrowsWithReason([managed.boolObj setObject:@NO forKey:nil],
                              @"Should fail on nil key 'a' of type '__NSCFConstantString' for expected type 'bool'");
    RLMAssertThrowsWithReason([managed.intObj setObject:@2 forKey:nil],
                              @"Should fail on nil key 'a' of type '__NSCFConstantString' for expected type 'int'");
    RLMAssertThrowsWithReason([managed.floatObj setObject:@2.2f forKey:nil],
                              @"Should fail on nil key 'a' of type '__NSCFConstantString' for expected type 'float'");
    RLMAssertThrowsWithReason([managed.doubleObj setObject:@2.2 forKey:nil],
                              @"Should fail on nil key 'a' of type '__NSCFConstantString' for expected type 'double'");
    RLMAssertThrowsWithReason([managed.stringObj setObject:@"a" forKey:nil],
                              @"Should fail on nil key 'a' of type '__NSCFConstantString' for expected type 'string'");
    RLMAssertThrowsWithReason([managed.dataObj setObject:data(1) forKey:nil],
                              @"Should fail on nil key 'a' of type '__NSCFConstantString' for expected type 'data'");
    RLMAssertThrowsWithReason([managed.dateObj setObject:date(1) forKey:nil],
                              @"Should fail on nil key 'a' of type '__NSCFConstantString' for expected type 'date'");
    RLMAssertThrowsWithReason([managed.decimalObj setObject:decimal128(2) forKey:nil],
                              @"Should fail on nil key 'a' of type '__NSCFConstantString' for expected type 'decimal128'");
    RLMAssertThrowsWithReason([managed.objectIdObj setObject:objectId(1) forKey:nil],
                              @"Should fail on nil key 'a' of type '__NSCFConstantString' for expected type 'object id'");
    RLMAssertThrowsWithReason([managed.uuidObj setObject:uuid(@"00000000-0000-0000-0000-000000000000") forKey:nil],
                              @"Should fail on nil key 'a' of type '__NSCFConstantString' for expected type 'uuid'");
    RLMAssertThrowsWithReason([optManaged.boolObj setObject:@NO forKey:nil],
                              @"Should fail on nil key 'a' of type '__NSCFConstantString' for expected type 'bool?'");
    RLMAssertThrowsWithReason([optManaged.intObj setObject:@2 forKey:nil],
                              @"Should fail on nil key 'a' of type '__NSCFConstantString' for expected type 'int?'");
    RLMAssertThrowsWithReason([optManaged.floatObj setObject:@2.2f forKey:nil],
                              @"Should fail on nil key 'a' of type '__NSCFConstantString' for expected type 'float?'");
    RLMAssertThrowsWithReason([optManaged.doubleObj setObject:@2.2 forKey:nil],
                              @"Should fail on nil key 'a' of type '__NSCFConstantString' for expected type 'double?'");
    RLMAssertThrowsWithReason([optManaged.stringObj setObject:@"a" forKey:nil],
                              @"Should fail on nil key 'a' of type '__NSCFConstantString' for expected type 'string?'");
    RLMAssertThrowsWithReason([optManaged.dataObj setObject:data(1) forKey:nil],
                              @"Should fail on nil key 'a' of type '__NSCFConstantString' for expected type 'data?'");
    RLMAssertThrowsWithReason([optManaged.dateObj setObject:date(1) forKey:nil],
                              @"Should fail on nil key 'a' of type '__NSCFConstantString' for expected type 'date?'");
    RLMAssertThrowsWithReason([optManaged.decimalObj setObject:decimal128(2) forKey:nil],
                              @"Should fail on nil key 'a' of type '__NSCFConstantString' for expected type 'decimal128?'");
    RLMAssertThrowsWithReason([optManaged.objectIdObj setObject:objectId(1) forKey:nil],
                              @"Should fail on nil key 'a' of type '__NSCFConstantString' for expected type 'object id?'");
    RLMAssertThrowsWithReason([optManaged.uuidObj setObject:uuid(@"00000000-0000-0000-0000-000000000000") forKey:nil],
                              @"Should fail on nil key 'a' of type '__NSCFConstantString' for expected type 'uuid?'");

    RLMAssertThrowsWithReason([unmanaged.boolObj setObject:@"a" forKey: @"wrongVal"],
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'bool'");
    RLMAssertThrowsWithReason([unmanaged.intObj setObject:@"a" forKey: @"wrongVal"],
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'int'");
    RLMAssertThrowsWithReason([unmanaged.floatObj setObject:@"a" forKey: @"wrongVal"],
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'float'");
    RLMAssertThrowsWithReason([unmanaged.doubleObj setObject:@"a" forKey: @"wrongVal"],
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'double'");
    RLMAssertThrowsWithReason([unmanaged.stringObj setObject:@"a" forKey: @"wrongVal"],
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'string'");
    RLMAssertThrowsWithReason([unmanaged.dataObj setObject:@"a" forKey: @"wrongVal"],
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'data'");
    RLMAssertThrowsWithReason([unmanaged.dateObj setObject:@"a" forKey: @"wrongVal"],
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'date'");
    RLMAssertThrowsWithReason([unmanaged.decimalObj setObject:@"a" forKey: @"wrongVal"],
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'decimal128'");
    RLMAssertThrowsWithReason([unmanaged.objectIdObj setObject:@"a" forKey: @"wrongVal"],
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'object id'");
    RLMAssertThrowsWithReason([unmanaged.uuidObj setObject:@"a" forKey: @"wrongVal"],
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'uuid'");
    RLMAssertThrowsWithReason([optUnmanaged.boolObj setObject:@"a" forKey: @"wrongVal"],
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'bool?'");
    RLMAssertThrowsWithReason([optUnmanaged.intObj setObject:@"a" forKey: @"wrongVal"],
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'int?'");
    RLMAssertThrowsWithReason([optUnmanaged.floatObj setObject:@"a" forKey: @"wrongVal"],
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'float?'");
    RLMAssertThrowsWithReason([optUnmanaged.doubleObj setObject:@"a" forKey: @"wrongVal"],
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'double?'");
    RLMAssertThrowsWithReason([optUnmanaged.stringObj setObject:@"a" forKey: @"wrongVal"],
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'string?'");
    RLMAssertThrowsWithReason([optUnmanaged.dataObj setObject:@"a" forKey: @"wrongVal"],
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'data?'");
    RLMAssertThrowsWithReason([optUnmanaged.dateObj setObject:@"a" forKey: @"wrongVal"],
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'date?'");
    RLMAssertThrowsWithReason([optUnmanaged.decimalObj setObject:@"a" forKey: @"wrongVal"],
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'decimal128?'");
    RLMAssertThrowsWithReason([optUnmanaged.objectIdObj setObject:@"a" forKey: @"wrongVal"],
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'object id?'");
    RLMAssertThrowsWithReason([optUnmanaged.uuidObj setObject:@"a" forKey: @"wrongVal"],
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'uuid?'");
    RLMAssertThrowsWithReason([managed.boolObj setObject:@"a" forKey: @"wrongVal"],
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'bool'");
    RLMAssertThrowsWithReason([managed.intObj setObject:@"a" forKey: @"wrongVal"],
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'int'");
    RLMAssertThrowsWithReason([managed.floatObj setObject:@"a" forKey: @"wrongVal"],
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'float'");
    RLMAssertThrowsWithReason([managed.doubleObj setObject:@"a" forKey: @"wrongVal"],
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'double'");
    RLMAssertThrowsWithReason([managed.stringObj setObject:@"a" forKey: @"wrongVal"],
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'string'");
    RLMAssertThrowsWithReason([managed.dataObj setObject:@"a" forKey: @"wrongVal"],
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'data'");
    RLMAssertThrowsWithReason([managed.dateObj setObject:@"a" forKey: @"wrongVal"],
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'date'");
    RLMAssertThrowsWithReason([managed.decimalObj setObject:@"a" forKey: @"wrongVal"],
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'decimal128'");
    RLMAssertThrowsWithReason([managed.objectIdObj setObject:@"a" forKey: @"wrongVal"],
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'object id'");
    RLMAssertThrowsWithReason([managed.uuidObj setObject:@"a" forKey: @"wrongVal"],
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'uuid'");
    RLMAssertThrowsWithReason([optManaged.boolObj setObject:@"a" forKey: @"wrongVal"],
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'bool?'");
    RLMAssertThrowsWithReason([optManaged.intObj setObject:@"a" forKey: @"wrongVal"],
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'int?'");
    RLMAssertThrowsWithReason([optManaged.floatObj setObject:@"a" forKey: @"wrongVal"],
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'float?'");
    RLMAssertThrowsWithReason([optManaged.doubleObj setObject:@"a" forKey: @"wrongVal"],
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'double?'");
    RLMAssertThrowsWithReason([optManaged.stringObj setObject:@"a" forKey: @"wrongVal"],
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'string?'");
    RLMAssertThrowsWithReason([optManaged.dataObj setObject:@"a" forKey: @"wrongVal"],
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'data?'");
    RLMAssertThrowsWithReason([optManaged.dateObj setObject:@"a" forKey: @"wrongVal"],
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'date?'");
    RLMAssertThrowsWithReason([optManaged.decimalObj setObject:@"a" forKey: @"wrongVal"],
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'decimal128?'");
    RLMAssertThrowsWithReason([optManaged.objectIdObj setObject:@"a" forKey: @"wrongVal"],
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'object id?'");
    RLMAssertThrowsWithReason([optManaged.uuidObj setObject:@"a" forKey: @"wrongVal"],
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'uuid?'");

    unmanaged.boolObj[@"val"] = @NO;
    unmanaged.intObj[@"val"] = @2;
    unmanaged.floatObj[@"val"] = @2.2f;
    unmanaged.doubleObj[@"val"] = @2.2;
    unmanaged.stringObj[@"val"] = @"a";
    unmanaged.dataObj[@"val"] = data(1);
    unmanaged.dateObj[@"val"] = date(1);
    unmanaged.decimalObj[@"val"] = decimal128(2);
    unmanaged.objectIdObj[@"val"] = objectId(1);
    unmanaged.uuidObj[@"val"] = uuid(@"00000000-0000-0000-0000-000000000000");
    optUnmanaged.boolObj[@"val"] = @NO;
    optUnmanaged.intObj[@"val"] = @2;
    optUnmanaged.floatObj[@"val"] = @2.2f;
    optUnmanaged.doubleObj[@"val"] = @2.2;
    optUnmanaged.stringObj[@"val"] = @"a";
    optUnmanaged.dataObj[@"val"] = data(1);
    optUnmanaged.dateObj[@"val"] = date(1);
    optUnmanaged.decimalObj[@"val"] = decimal128(2);
    optUnmanaged.objectIdObj[@"val"] = objectId(1);
    optUnmanaged.uuidObj[@"val"] = uuid(@"00000000-0000-0000-0000-000000000000");
    managed.boolObj[@"val"] = @NO;
    managed.intObj[@"val"] = @2;
    managed.floatObj[@"val"] = @2.2f;
    managed.doubleObj[@"val"] = @2.2;
    managed.stringObj[@"val"] = @"a";
    managed.dataObj[@"val"] = data(1);
    managed.dateObj[@"val"] = date(1);
    managed.decimalObj[@"val"] = decimal128(2);
    managed.objectIdObj[@"val"] = objectId(1);
    managed.uuidObj[@"val"] = uuid(@"00000000-0000-0000-0000-000000000000");
    optManaged.boolObj[@"val"] = @NO;
    optManaged.intObj[@"val"] = @2;
    optManaged.floatObj[@"val"] = @2.2f;
    optManaged.doubleObj[@"val"] = @2.2;
    optManaged.stringObj[@"val"] = @"a";
    optManaged.dataObj[@"val"] = data(1);
    optManaged.dateObj[@"val"] = date(1);
    optManaged.decimalObj[@"val"] = decimal128(2);
    optManaged.objectIdObj[@"val"] = objectId(1);
    optManaged.uuidObj[@"val"] = uuid(@"00000000-0000-0000-0000-000000000000");
    XCTAssertEqualObjects(unmanaged.boolObj[@"val"], @NO);
    XCTAssertEqualObjects(unmanaged.intObj[@"val"], @2);
    XCTAssertEqualObjects(unmanaged.floatObj[@"val"], @2.2f);
    XCTAssertEqualObjects(unmanaged.doubleObj[@"val"], @2.2);
    XCTAssertEqualObjects(unmanaged.stringObj[@"val"], @"a");
    XCTAssertEqualObjects(unmanaged.dataObj[@"val"], data(1));
    XCTAssertEqualObjects(unmanaged.dateObj[@"val"], date(1));
    XCTAssertEqualObjects(unmanaged.decimalObj[@"val"], decimal128(2));
    XCTAssertEqualObjects(unmanaged.objectIdObj[@"val"], objectId(1));
    XCTAssertEqualObjects(unmanaged.uuidObj[@"val"], uuid(@"00000000-0000-0000-0000-000000000000"));
    XCTAssertEqualObjects(optUnmanaged.boolObj[@"val"], @NO);
    XCTAssertEqualObjects(optUnmanaged.intObj[@"val"], @2);
    XCTAssertEqualObjects(optUnmanaged.floatObj[@"val"], @2.2f);
    XCTAssertEqualObjects(optUnmanaged.doubleObj[@"val"], @2.2);
    XCTAssertEqualObjects(optUnmanaged.stringObj[@"val"], @"a");
    XCTAssertEqualObjects(optUnmanaged.dataObj[@"val"], data(1));
    XCTAssertEqualObjects(optUnmanaged.dateObj[@"val"], date(1));
    XCTAssertEqualObjects(optUnmanaged.decimalObj[@"val"], decimal128(2));
    XCTAssertEqualObjects(optUnmanaged.objectIdObj[@"val"], objectId(1));
    XCTAssertEqualObjects(optUnmanaged.uuidObj[@"val"], uuid(@"00000000-0000-0000-0000-000000000000"));
    XCTAssertEqualObjects(managed.boolObj[@"val"], @NO);
    XCTAssertEqualObjects(managed.intObj[@"val"], @2);
    XCTAssertEqualObjects(managed.floatObj[@"val"], @2.2f);
    XCTAssertEqualObjects(managed.doubleObj[@"val"], @2.2);
    XCTAssertEqualObjects(managed.stringObj[@"val"], @"a");
    XCTAssertEqualObjects(managed.dataObj[@"val"], data(1));
    XCTAssertEqualObjects(managed.dateObj[@"val"], date(1));
    XCTAssertEqualObjects(managed.decimalObj[@"val"], decimal128(2));
    XCTAssertEqualObjects(managed.objectIdObj[@"val"], objectId(1));
    XCTAssertEqualObjects(managed.uuidObj[@"val"], uuid(@"00000000-0000-0000-0000-000000000000"));
    XCTAssertEqualObjects(optManaged.boolObj[@"val"], @NO);
    XCTAssertEqualObjects(optManaged.intObj[@"val"], @2);
    XCTAssertEqualObjects(optManaged.floatObj[@"val"], @2.2f);
    XCTAssertEqualObjects(optManaged.doubleObj[@"val"], @2.2);
    XCTAssertEqualObjects(optManaged.stringObj[@"val"], @"a");
    XCTAssertEqualObjects(optManaged.dataObj[@"val"], data(1));
    XCTAssertEqualObjects(optManaged.dateObj[@"val"], date(1));
    XCTAssertEqualObjects(optManaged.decimalObj[@"val"], decimal128(2));
    XCTAssertEqualObjects(optManaged.objectIdObj[@"val"], objectId(1));
    XCTAssertEqualObjects(optManaged.uuidObj[@"val"], uuid(@"00000000-0000-0000-0000-000000000000"));

}
#pragma clang diagnostic pop

- (void)testAddObjects {
    RLMAssertThrowsWithReason([unmanaged.boolObj addObjects:@{@"wrongVal": @"a"}],
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'bool'");
    RLMAssertThrowsWithReason([unmanaged.intObj addObjects:@{@"wrongVal": @"a"}],
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'int'");
    RLMAssertThrowsWithReason([unmanaged.floatObj addObjects:@{@"wrongVal": @"a"}],
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'float'");
    RLMAssertThrowsWithReason([unmanaged.doubleObj addObjects:@{@"wrongVal": @"a"}],
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'double'");
    RLMAssertThrowsWithReason([unmanaged.stringObj addObjects:@{@"wrongVal": @"a"}],
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'string'");
    RLMAssertThrowsWithReason([unmanaged.dataObj addObjects:@{@"wrongVal": @"a"}],
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'data'");
    RLMAssertThrowsWithReason([unmanaged.dateObj addObjects:@{@"wrongVal": @"a"}],
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'date'");
    RLMAssertThrowsWithReason([unmanaged.decimalObj addObjects:@{@"wrongVal": @"a"}],
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'decimal128'");
    RLMAssertThrowsWithReason([unmanaged.objectIdObj addObjects:@{@"wrongVal": @"a"}],
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'object id'");
    RLMAssertThrowsWithReason([unmanaged.uuidObj addObjects:@{@"wrongVal": @"a"}],
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'uuid'");
    RLMAssertThrowsWithReason([optUnmanaged.boolObj addObjects:@{@"wrongVal": @"a"}],
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'bool?'");
    RLMAssertThrowsWithReason([optUnmanaged.intObj addObjects:@{@"wrongVal": @"a"}],
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'int?'");
    RLMAssertThrowsWithReason([optUnmanaged.floatObj addObjects:@{@"wrongVal": @"a"}],
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'float?'");
    RLMAssertThrowsWithReason([optUnmanaged.doubleObj addObjects:@{@"wrongVal": @"a"}],
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'double?'");
    RLMAssertThrowsWithReason([optUnmanaged.stringObj addObjects:@{@"wrongVal": @"a"}],
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'string?'");
    RLMAssertThrowsWithReason([optUnmanaged.dataObj addObjects:@{@"wrongVal": @"a"}],
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'data?'");
    RLMAssertThrowsWithReason([optUnmanaged.dateObj addObjects:@{@"wrongVal": @"a"}],
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'date?'");
    RLMAssertThrowsWithReason([optUnmanaged.decimalObj addObjects:@{@"wrongVal": @"a"}],
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'decimal128?'");
    RLMAssertThrowsWithReason([optUnmanaged.objectIdObj addObjects:@{@"wrongVal": @"a"}],
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'object id?'");
    RLMAssertThrowsWithReason([optUnmanaged.uuidObj addObjects:@{@"wrongVal": @"a"}],
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'uuid?'");
    RLMAssertThrowsWithReason([managed.boolObj addObjects:@{@"wrongVal": @"a"}],
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'bool'");
    RLMAssertThrowsWithReason([managed.intObj addObjects:@{@"wrongVal": @"a"}],
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'int'");
    RLMAssertThrowsWithReason([managed.floatObj addObjects:@{@"wrongVal": @"a"}],
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'float'");
    RLMAssertThrowsWithReason([managed.doubleObj addObjects:@{@"wrongVal": @"a"}],
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'double'");
    RLMAssertThrowsWithReason([managed.stringObj addObjects:@{@"wrongVal": @"a"}],
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'string'");
    RLMAssertThrowsWithReason([managed.dataObj addObjects:@{@"wrongVal": @"a"}],
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'data'");
    RLMAssertThrowsWithReason([managed.dateObj addObjects:@{@"wrongVal": @"a"}],
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'date'");
    RLMAssertThrowsWithReason([managed.decimalObj addObjects:@{@"wrongVal": @"a"}],
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'decimal128'");
    RLMAssertThrowsWithReason([managed.objectIdObj addObjects:@{@"wrongVal": @"a"}],
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'object id'");
    RLMAssertThrowsWithReason([managed.uuidObj addObjects:@{@"wrongVal": @"a"}],
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'uuid'");
    RLMAssertThrowsWithReason([optManaged.boolObj addObjects:@{@"wrongVal": @"a"}],
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'bool?'");
    RLMAssertThrowsWithReason([optManaged.intObj addObjects:@{@"wrongVal": @"a"}],
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'int?'");
    RLMAssertThrowsWithReason([optManaged.floatObj addObjects:@{@"wrongVal": @"a"}],
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'float?'");
    RLMAssertThrowsWithReason([optManaged.doubleObj addObjects:@{@"wrongVal": @"a"}],
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'double?'");
    RLMAssertThrowsWithReason([optManaged.stringObj addObjects:@{@"wrongVal": @"a"}],
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'string?'");
    RLMAssertThrowsWithReason([optManaged.dataObj addObjects:@{@"wrongVal": @"a"}],
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'data?'");
    RLMAssertThrowsWithReason([optManaged.dateObj addObjects:@{@"wrongVal": @"a"}],
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'date?'");
    RLMAssertThrowsWithReason([optManaged.decimalObj addObjects:@{@"wrongVal": @"a"}],
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'decimal128?'");
    RLMAssertThrowsWithReason([optManaged.objectIdObj addObjects:@{@"wrongVal": @"a"}],
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'object id?'");
    RLMAssertThrowsWithReason([optManaged.uuidObj addObjects:@{@"wrongVal": @"a"}],
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'uuid?'");

    [self addObjects];
    XCTAssertEqualObjects(unmanaged.boolObj[@"0"], @NO);
    XCTAssertEqualObjects(unmanaged.intObj[@"0"], @2);
    XCTAssertEqualObjects(unmanaged.floatObj[@"0"], @2.2f);
    XCTAssertEqualObjects(unmanaged.doubleObj[@"0"], @2.2);
    XCTAssertEqualObjects(unmanaged.stringObj[@"0"], @"a");
    XCTAssertEqualObjects(unmanaged.dataObj[@"0"], data(1));
    XCTAssertEqualObjects(unmanaged.dateObj[@"0"], date(1));
    XCTAssertEqualObjects(unmanaged.decimalObj[@"0"], decimal128(2));
    XCTAssertEqualObjects(unmanaged.objectIdObj[@"0"], objectId(1));
    XCTAssertEqualObjects(unmanaged.uuidObj[@"0"], uuid(@"00000000-0000-0000-0000-000000000000"));
    XCTAssertEqualObjects(optUnmanaged.boolObj[@"0"], @NO);
    XCTAssertEqualObjects(optUnmanaged.intObj[@"0"], @2);
    XCTAssertEqualObjects(optUnmanaged.floatObj[@"0"], @2.2f);
    XCTAssertEqualObjects(optUnmanaged.doubleObj[@"0"], @2.2);
    XCTAssertEqualObjects(optUnmanaged.stringObj[@"0"], @"a");
    XCTAssertEqualObjects(optUnmanaged.dataObj[@"0"], data(1));
    XCTAssertEqualObjects(optUnmanaged.dateObj[@"0"], date(1));
    XCTAssertEqualObjects(optUnmanaged.decimalObj[@"0"], decimal128(2));
    XCTAssertEqualObjects(optUnmanaged.objectIdObj[@"0"], objectId(1));
    XCTAssertEqualObjects(optUnmanaged.uuidObj[@"0"], uuid(@"00000000-0000-0000-0000-000000000000"));
    XCTAssertEqualObjects(managed.boolObj[@"0"], @NO);
    XCTAssertEqualObjects(managed.intObj[@"0"], @2);
    XCTAssertEqualObjects(managed.floatObj[@"0"], @2.2f);
    XCTAssertEqualObjects(managed.doubleObj[@"0"], @2.2);
    XCTAssertEqualObjects(managed.stringObj[@"0"], @"a");
    XCTAssertEqualObjects(managed.dataObj[@"0"], data(1));
    XCTAssertEqualObjects(managed.dateObj[@"0"], date(1));
    XCTAssertEqualObjects(managed.decimalObj[@"0"], decimal128(2));
    XCTAssertEqualObjects(managed.objectIdObj[@"0"], objectId(1));
    XCTAssertEqualObjects(managed.uuidObj[@"0"], uuid(@"00000000-0000-0000-0000-000000000000"));
    XCTAssertEqualObjects(optManaged.boolObj[@"0"], @NO);
    XCTAssertEqualObjects(optManaged.intObj[@"0"], @2);
    XCTAssertEqualObjects(optManaged.floatObj[@"0"], @2.2f);
    XCTAssertEqualObjects(optManaged.doubleObj[@"0"], @2.2);
    XCTAssertEqualObjects(optManaged.stringObj[@"0"], @"a");
    XCTAssertEqualObjects(optManaged.dataObj[@"0"], data(1));
    XCTAssertEqualObjects(optManaged.dateObj[@"0"], date(1));
    XCTAssertEqualObjects(optManaged.decimalObj[@"0"], decimal128(2));
    XCTAssertEqualObjects(optManaged.objectIdObj[@"0"], objectId(1));
    XCTAssertEqualObjects(optManaged.uuidObj[@"0"], uuid(@"00000000-0000-0000-0000-000000000000"));
    XCTAssertEqualObjects(unmanaged.boolObj[@"1"], @YES);
    XCTAssertEqualObjects(unmanaged.intObj[@"1"], @3);
    XCTAssertEqualObjects(unmanaged.floatObj[@"1"], @3.3f);
    XCTAssertEqualObjects(unmanaged.doubleObj[@"1"], @3.3);
    XCTAssertEqualObjects(unmanaged.stringObj[@"1"], @"b");
    XCTAssertEqualObjects(unmanaged.dataObj[@"1"], data(2));
    XCTAssertEqualObjects(unmanaged.dateObj[@"1"], date(2));
    XCTAssertEqualObjects(unmanaged.decimalObj[@"1"], decimal128(3));
    XCTAssertEqualObjects(unmanaged.objectIdObj[@"1"], objectId(2));
    XCTAssertEqualObjects(unmanaged.uuidObj[@"1"], uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"));
    XCTAssertEqualObjects(optUnmanaged.boolObj[@"1"], @YES);
    XCTAssertEqualObjects(optUnmanaged.intObj[@"1"], @3);
    XCTAssertEqualObjects(optUnmanaged.floatObj[@"1"], @3.3f);
    XCTAssertEqualObjects(optUnmanaged.doubleObj[@"1"], @3.3);
    XCTAssertEqualObjects(optUnmanaged.stringObj[@"1"], @"b");
    XCTAssertEqualObjects(optUnmanaged.dataObj[@"1"], data(2));
    XCTAssertEqualObjects(optUnmanaged.dateObj[@"1"], date(2));
    XCTAssertEqualObjects(optUnmanaged.decimalObj[@"1"], decimal128(3));
    XCTAssertEqualObjects(optUnmanaged.objectIdObj[@"1"], objectId(2));
    XCTAssertEqualObjects(optUnmanaged.uuidObj[@"1"], uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"));
    XCTAssertEqualObjects(managed.boolObj[@"1"], @YES);
    XCTAssertEqualObjects(managed.intObj[@"1"], @3);
    XCTAssertEqualObjects(managed.floatObj[@"1"], @3.3f);
    XCTAssertEqualObjects(managed.doubleObj[@"1"], @3.3);
    XCTAssertEqualObjects(managed.stringObj[@"1"], @"b");
    XCTAssertEqualObjects(managed.dataObj[@"1"], data(2));
    XCTAssertEqualObjects(managed.dateObj[@"1"], date(2));
    XCTAssertEqualObjects(managed.decimalObj[@"1"], decimal128(3));
    XCTAssertEqualObjects(managed.objectIdObj[@"1"], objectId(2));
    XCTAssertEqualObjects(managed.uuidObj[@"1"], uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"));
    XCTAssertEqualObjects(optManaged.boolObj[@"1"], @YES);
    XCTAssertEqualObjects(optManaged.intObj[@"1"], @3);
    XCTAssertEqualObjects(optManaged.floatObj[@"1"], @3.3f);
    XCTAssertEqualObjects(optManaged.doubleObj[@"1"], @3.3);
    XCTAssertEqualObjects(optManaged.stringObj[@"1"], @"b");
    XCTAssertEqualObjects(optManaged.dataObj[@"1"], data(2));
    XCTAssertEqualObjects(optManaged.dateObj[@"1"], date(2));
    XCTAssertEqualObjects(optManaged.decimalObj[@"1"], decimal128(3));
    XCTAssertEqualObjects(optManaged.objectIdObj[@"1"], objectId(2));
    XCTAssertEqualObjects(optManaged.uuidObj[@"1"], uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"));
}
/**
- (void)testInsertObject {
    RLMAssertThrowsWithReason([unmanaged.boolObj insertObject:@"a" atIndex:0],
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'bool'");
    RLMAssertThrowsWithReason([unmanaged.intObj insertObject:@"a" atIndex:0],
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'int'");
    RLMAssertThrowsWithReason([unmanaged.floatObj insertObject:@"a" atIndex:0],
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'float'");
    RLMAssertThrowsWithReason([unmanaged.doubleObj insertObject:@"a" atIndex:0],
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'double'");
    RLMAssertThrowsWithReason([unmanaged.stringObj insertObject:@"a" atIndex:0],
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'string'");
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
    RLMAssertThrowsWithReason([optUnmanaged.stringObj insertObject:@"a" atIndex:0],
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'string?'");
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
    RLMAssertThrowsWithReason([managed.stringObj insertObject:@"a" atIndex:0],
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'string'");
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
    RLMAssertThrowsWithReason([optManaged.stringObj insertObject:@"a" atIndex:0],
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'string?'");
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

}
 */
- (void)testRemoveObject {
    [self addObjects];

    for (RLMDictionary *dictionary in allDictionaries) {
        [dictionary removeObjectForKey:@"0"];
    }

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
}

- (void)testRemoveObjects {
    [self addObjects];

    for (RLMDictionary *dictionary in allDictionaries) {
        [dictionary removeObjectsForKeys:@[@"0"]];
    }

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
}

- (void)testUpdateObjects {
    [self addObjects];



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
    RLMAssertThrowsWithReason([unmanaged.stringObj indexOfObject:@"a"],
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'string'");
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
    RLMAssertThrowsWithReason([optUnmanaged.stringObj indexOfObject:@"a"],
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'string?'");
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
    RLMAssertThrowsWithReason([managed.stringObj indexOfObject:@"a"],
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'string'");
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
    RLMAssertThrowsWithReason([optManaged.stringObj indexOfObject:@"a"],
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'string?'");
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


}

- (void)testIndexOfObjectDistinct {


}

- (void)testIndexOfObjectWhere {


    [self addObjects];

}

- (void)testIndexOfObjectWithPredicate {


    [self addObjects];

}

- (void)testSort {




}

- (void)testFilter {


}

- (void)testNotifications {
}

- (void)testMin {


    [self addObjects];

}

- (void)testMax {


    [self addObjects];

}

- (void)testSum {


    [self addObjects];

}

- (void)testAverage {


    [self addObjects];

}

- (void)testFastEnumeration {
    for (int i = 0; i < 10; ++i) {
        [self addObjects];
    }

    {
    NSUInteger i = 0;
    NSDictionary *values = @{@"0": @NO, @"1": @YES};
    for (id key in unmanaged.boolObj) {
    id value = unmanaged.boolObj[key];
    XCTAssertEqualObjects(values[key], value);
    }
    XCTAssertEqual(i, unmanaged.boolObj.count);
    }
    
    {
    NSUInteger i = 0;
    NSDictionary *values = @{@"0": @2, @"1": @3};
    for (id key in unmanaged.intObj) {
    id value = unmanaged.intObj[key];
    XCTAssertEqualObjects(values[key], value);
    }
    XCTAssertEqual(i, unmanaged.intObj.count);
    }
    
    {
    NSUInteger i = 0;
    NSDictionary *values = @{@"0": @2.2f, @"1": @3.3f};
    for (id key in unmanaged.floatObj) {
    id value = unmanaged.floatObj[key];
    XCTAssertEqualObjects(values[key], value);
    }
    XCTAssertEqual(i, unmanaged.floatObj.count);
    }
    
    {
    NSUInteger i = 0;
    NSDictionary *values = @{@"0": @2.2, @"1": @3.3};
    for (id key in unmanaged.doubleObj) {
    id value = unmanaged.doubleObj[key];
    XCTAssertEqualObjects(values[key], value);
    }
    XCTAssertEqual(i, unmanaged.doubleObj.count);
    }
    
    {
    NSUInteger i = 0;
    NSDictionary *values = @{@"0": @"a", @"1": @"b"};
    for (id key in unmanaged.stringObj) {
    id value = unmanaged.stringObj[key];
    XCTAssertEqualObjects(values[key], value);
    }
    XCTAssertEqual(i, unmanaged.stringObj.count);
    }
    
    {
    NSUInteger i = 0;
    NSDictionary *values = @{@"0": data(1), @"1": data(2)};
    for (id key in unmanaged.dataObj) {
    id value = unmanaged.dataObj[key];
    XCTAssertEqualObjects(values[key], value);
    }
    XCTAssertEqual(i, unmanaged.dataObj.count);
    }
    
    {
    NSUInteger i = 0;
    NSDictionary *values = @{@"0": date(1), @"1": date(2)};
    for (id key in unmanaged.dateObj) {
    id value = unmanaged.dateObj[key];
    XCTAssertEqualObjects(values[key], value);
    }
    XCTAssertEqual(i, unmanaged.dateObj.count);
    }
    
    {
    NSUInteger i = 0;
    NSDictionary *values = @{@"0": decimal128(2), @"1": decimal128(3)};
    for (id key in unmanaged.decimalObj) {
    id value = unmanaged.decimalObj[key];
    XCTAssertEqualObjects(values[key], value);
    }
    XCTAssertEqual(i, unmanaged.decimalObj.count);
    }
    
    {
    NSUInteger i = 0;
    NSDictionary *values = @{@"0": objectId(1), @"1": objectId(2)};
    for (id key in unmanaged.objectIdObj) {
    id value = unmanaged.objectIdObj[key];
    XCTAssertEqualObjects(values[key], value);
    }
    XCTAssertEqual(i, unmanaged.objectIdObj.count);
    }
    
    {
    NSUInteger i = 0;
    NSDictionary *values = @{@"0": uuid(@"00000000-0000-0000-0000-000000000000"), @"1": uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")};
    for (id key in unmanaged.uuidObj) {
    id value = unmanaged.uuidObj[key];
    XCTAssertEqualObjects(values[key], value);
    }
    XCTAssertEqual(i, unmanaged.uuidObj.count);
    }
    
    {
    NSUInteger i = 0;
    NSDictionary *values = @{@"0": @NO, @"1": @YES, @"2": NSNull.null};
    for (id key in optUnmanaged.boolObj) {
    id value = optUnmanaged.boolObj[key];
    XCTAssertEqualObjects(values[key], value);
    }
    XCTAssertEqual(i, optUnmanaged.boolObj.count);
    }
    
    {
    NSUInteger i = 0;
    NSDictionary *values = @{@"0": @2, @"1": @3, @"2": NSNull.null};
    for (id key in optUnmanaged.intObj) {
    id value = optUnmanaged.intObj[key];
    XCTAssertEqualObjects(values[key], value);
    }
    XCTAssertEqual(i, optUnmanaged.intObj.count);
    }
    
    {
    NSUInteger i = 0;
    NSDictionary *values = @{@"0": @2.2f, @"1": @3.3f, @"2": NSNull.null};
    for (id key in optUnmanaged.floatObj) {
    id value = optUnmanaged.floatObj[key];
    XCTAssertEqualObjects(values[key], value);
    }
    XCTAssertEqual(i, optUnmanaged.floatObj.count);
    }
    
    {
    NSUInteger i = 0;
    NSDictionary *values = @{@"0": @2.2, @"1": @3.3, @"2": NSNull.null};
    for (id key in optUnmanaged.doubleObj) {
    id value = optUnmanaged.doubleObj[key];
    XCTAssertEqualObjects(values[key], value);
    }
    XCTAssertEqual(i, optUnmanaged.doubleObj.count);
    }
    
    {
    NSUInteger i = 0;
    NSDictionary *values = @{@"0": @"a", @"1": @"b", @"2": NSNull.null};
    for (id key in optUnmanaged.stringObj) {
    id value = optUnmanaged.stringObj[key];
    XCTAssertEqualObjects(values[key], value);
    }
    XCTAssertEqual(i, optUnmanaged.stringObj.count);
    }
    
    {
    NSUInteger i = 0;
    NSDictionary *values = @{@"0": data(1), @"1": data(2), @"2": NSNull.null};
    for (id key in optUnmanaged.dataObj) {
    id value = optUnmanaged.dataObj[key];
    XCTAssertEqualObjects(values[key], value);
    }
    XCTAssertEqual(i, optUnmanaged.dataObj.count);
    }
    
    {
    NSUInteger i = 0;
    NSDictionary *values = @{@"0": date(1), @"1": date(2), @"2": NSNull.null};
    for (id key in optUnmanaged.dateObj) {
    id value = optUnmanaged.dateObj[key];
    XCTAssertEqualObjects(values[key], value);
    }
    XCTAssertEqual(i, optUnmanaged.dateObj.count);
    }
    
    {
    NSUInteger i = 0;
    NSDictionary *values = @{@"0": decimal128(2), @"1": decimal128(3), @"2": NSNull.null};
    for (id key in optUnmanaged.decimalObj) {
    id value = optUnmanaged.decimalObj[key];
    XCTAssertEqualObjects(values[key], value);
    }
    XCTAssertEqual(i, optUnmanaged.decimalObj.count);
    }
    
    {
    NSUInteger i = 0;
    NSDictionary *values = @{@"0": objectId(1), @"1": objectId(2), @"2": NSNull.null};
    for (id key in optUnmanaged.objectIdObj) {
    id value = optUnmanaged.objectIdObj[key];
    XCTAssertEqualObjects(values[key], value);
    }
    XCTAssertEqual(i, optUnmanaged.objectIdObj.count);
    }
    
    {
    NSUInteger i = 0;
    NSDictionary *values = @{@"0": uuid(@"00000000-0000-0000-0000-000000000000"), @"1": uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"), @"2": NSNull.null};
    for (id key in optUnmanaged.uuidObj) {
    id value = optUnmanaged.uuidObj[key];
    XCTAssertEqualObjects(values[key], value);
    }
    XCTAssertEqual(i, optUnmanaged.uuidObj.count);
    }
    
    {
    NSUInteger i = 0;
    NSDictionary *values = @{@"0": @NO, @"1": @YES};
    for (id key in managed.boolObj) {
    id value = managed.boolObj[key];
    XCTAssertEqualObjects(values[key], value);
    }
    XCTAssertEqual(i, managed.boolObj.count);
    }
    
    {
    NSUInteger i = 0;
    NSDictionary *values = @{@"0": @2, @"1": @3};
    for (id key in managed.intObj) {
    id value = managed.intObj[key];
    XCTAssertEqualObjects(values[key], value);
    }
    XCTAssertEqual(i, managed.intObj.count);
    }
    
    {
    NSUInteger i = 0;
    NSDictionary *values = @{@"0": @2.2f, @"1": @3.3f};
    for (id key in managed.floatObj) {
    id value = managed.floatObj[key];
    XCTAssertEqualObjects(values[key], value);
    }
    XCTAssertEqual(i, managed.floatObj.count);
    }
    
    {
    NSUInteger i = 0;
    NSDictionary *values = @{@"0": @2.2, @"1": @3.3};
    for (id key in managed.doubleObj) {
    id value = managed.doubleObj[key];
    XCTAssertEqualObjects(values[key], value);
    }
    XCTAssertEqual(i, managed.doubleObj.count);
    }
    
    {
    NSUInteger i = 0;
    NSDictionary *values = @{@"0": @"a", @"1": @"b"};
    for (id key in managed.stringObj) {
    id value = managed.stringObj[key];
    XCTAssertEqualObjects(values[key], value);
    }
    XCTAssertEqual(i, managed.stringObj.count);
    }
    
    {
    NSUInteger i = 0;
    NSDictionary *values = @{@"0": data(1), @"1": data(2)};
    for (id key in managed.dataObj) {
    id value = managed.dataObj[key];
    XCTAssertEqualObjects(values[key], value);
    }
    XCTAssertEqual(i, managed.dataObj.count);
    }
    
    {
    NSUInteger i = 0;
    NSDictionary *values = @{@"0": date(1), @"1": date(2)};
    for (id key in managed.dateObj) {
    id value = managed.dateObj[key];
    XCTAssertEqualObjects(values[key], value);
    }
    XCTAssertEqual(i, managed.dateObj.count);
    }
    
    {
    NSUInteger i = 0;
    NSDictionary *values = @{@"0": decimal128(2), @"1": decimal128(3)};
    for (id key in managed.decimalObj) {
    id value = managed.decimalObj[key];
    XCTAssertEqualObjects(values[key], value);
    }
    XCTAssertEqual(i, managed.decimalObj.count);
    }
    
    {
    NSUInteger i = 0;
    NSDictionary *values = @{@"0": objectId(1), @"1": objectId(2)};
    for (id key in managed.objectIdObj) {
    id value = managed.objectIdObj[key];
    XCTAssertEqualObjects(values[key], value);
    }
    XCTAssertEqual(i, managed.objectIdObj.count);
    }
    
    {
    NSUInteger i = 0;
    NSDictionary *values = @{@"0": uuid(@"00000000-0000-0000-0000-000000000000"), @"1": uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")};
    for (id key in managed.uuidObj) {
    id value = managed.uuidObj[key];
    XCTAssertEqualObjects(values[key], value);
    }
    XCTAssertEqual(i, managed.uuidObj.count);
    }
    
    {
    NSUInteger i = 0;
    NSDictionary *values = @{@"0": @NO, @"1": @YES, @"2": NSNull.null};
    for (id key in optManaged.boolObj) {
    id value = optManaged.boolObj[key];
    XCTAssertEqualObjects(values[key], value);
    }
    XCTAssertEqual(i, optManaged.boolObj.count);
    }
    
    {
    NSUInteger i = 0;
    NSDictionary *values = @{@"0": @2, @"1": @3, @"2": NSNull.null};
    for (id key in optManaged.intObj) {
    id value = optManaged.intObj[key];
    XCTAssertEqualObjects(values[key], value);
    }
    XCTAssertEqual(i, optManaged.intObj.count);
    }
    
    {
    NSUInteger i = 0;
    NSDictionary *values = @{@"0": @2.2f, @"1": @3.3f, @"2": NSNull.null};
    for (id key in optManaged.floatObj) {
    id value = optManaged.floatObj[key];
    XCTAssertEqualObjects(values[key], value);
    }
    XCTAssertEqual(i, optManaged.floatObj.count);
    }
    
    {
    NSUInteger i = 0;
    NSDictionary *values = @{@"0": @2.2, @"1": @3.3, @"2": NSNull.null};
    for (id key in optManaged.doubleObj) {
    id value = optManaged.doubleObj[key];
    XCTAssertEqualObjects(values[key], value);
    }
    XCTAssertEqual(i, optManaged.doubleObj.count);
    }
    
    {
    NSUInteger i = 0;
    NSDictionary *values = @{@"0": @"a", @"1": @"b", @"2": NSNull.null};
    for (id key in optManaged.stringObj) {
    id value = optManaged.stringObj[key];
    XCTAssertEqualObjects(values[key], value);
    }
    XCTAssertEqual(i, optManaged.stringObj.count);
    }
    
    {
    NSUInteger i = 0;
    NSDictionary *values = @{@"0": data(1), @"1": data(2), @"2": NSNull.null};
    for (id key in optManaged.dataObj) {
    id value = optManaged.dataObj[key];
    XCTAssertEqualObjects(values[key], value);
    }
    XCTAssertEqual(i, optManaged.dataObj.count);
    }
    
    {
    NSUInteger i = 0;
    NSDictionary *values = @{@"0": date(1), @"1": date(2), @"2": NSNull.null};
    for (id key in optManaged.dateObj) {
    id value = optManaged.dateObj[key];
    XCTAssertEqualObjects(values[key], value);
    }
    XCTAssertEqual(i, optManaged.dateObj.count);
    }
    
    {
    NSUInteger i = 0;
    NSDictionary *values = @{@"0": decimal128(2), @"1": decimal128(3), @"2": NSNull.null};
    for (id key in optManaged.decimalObj) {
    id value = optManaged.decimalObj[key];
    XCTAssertEqualObjects(values[key], value);
    }
    XCTAssertEqual(i, optManaged.decimalObj.count);
    }
    
    {
    NSUInteger i = 0;
    NSDictionary *values = @{@"0": objectId(1), @"1": objectId(2), @"2": NSNull.null};
    for (id key in optManaged.objectIdObj) {
    id value = optManaged.objectIdObj[key];
    XCTAssertEqualObjects(values[key], value);
    }
    XCTAssertEqual(i, optManaged.objectIdObj.count);
    }
    
    {
    NSUInteger i = 0;
    NSDictionary *values = @{@"0": uuid(@"00000000-0000-0000-0000-000000000000"), @"1": uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"), @"2": NSNull.null};
    for (id key in optManaged.uuidObj) {
    id value = optManaged.uuidObj[key];
    XCTAssertEqualObjects(values[key], value);
    }
    XCTAssertEqual(i, optManaged.uuidObj.count);
    }
    
}

- (void)testValueForKeySelf {
    for (RLMDictionary *dictionary in allDictionaries) {
        XCTAssertEqualObjects([dictionary valueForKey:@"self"], @[]);
    }

    [self addObjects];

    XCTAssertEqualObjects([unmanaged.boolObj valueForKey:@"self"], (@{@"0": @NO, @"1": @YES}));
    XCTAssertEqualObjects([unmanaged.intObj valueForKey:@"self"], (@{@"0": @2, @"1": @3}));
    XCTAssertEqualObjects([unmanaged.floatObj valueForKey:@"self"], (@{@"0": @2.2f, @"1": @3.3f}));
    XCTAssertEqualObjects([unmanaged.doubleObj valueForKey:@"self"], (@{@"0": @2.2, @"1": @3.3}));
    XCTAssertEqualObjects([unmanaged.stringObj valueForKey:@"self"], (@{@"0": @"a", @"1": @"b"}));
    XCTAssertEqualObjects([unmanaged.dataObj valueForKey:@"self"], (@{@"0": data(1), @"1": data(2)}));
    XCTAssertEqualObjects([unmanaged.dateObj valueForKey:@"self"], (@{@"0": date(1), @"1": date(2)}));
    XCTAssertEqualObjects([unmanaged.decimalObj valueForKey:@"self"], (@{@"0": decimal128(2), @"1": decimal128(3)}));
    XCTAssertEqualObjects([unmanaged.objectIdObj valueForKey:@"self"], (@{@"0": objectId(1), @"1": objectId(2)}));
    XCTAssertEqualObjects([unmanaged.uuidObj valueForKey:@"self"], (@{@"0": uuid(@"00000000-0000-0000-0000-000000000000"), @"1": uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")}));
    XCTAssertEqualObjects([optUnmanaged.boolObj valueForKey:@"self"], (@{@"0": @NO, @"1": @YES, @"2": NSNull.null}));
    XCTAssertEqualObjects([optUnmanaged.intObj valueForKey:@"self"], (@{@"0": @2, @"1": @3, @"2": NSNull.null}));
    XCTAssertEqualObjects([optUnmanaged.floatObj valueForKey:@"self"], (@{@"0": @2.2f, @"1": @3.3f, @"2": NSNull.null}));
    XCTAssertEqualObjects([optUnmanaged.doubleObj valueForKey:@"self"], (@{@"0": @2.2, @"1": @3.3, @"2": NSNull.null}));
    XCTAssertEqualObjects([optUnmanaged.stringObj valueForKey:@"self"], (@{@"0": @"a", @"1": @"b", @"2": NSNull.null}));
    XCTAssertEqualObjects([optUnmanaged.dataObj valueForKey:@"self"], (@{@"0": data(1), @"1": data(2), @"2": NSNull.null}));
    XCTAssertEqualObjects([optUnmanaged.dateObj valueForKey:@"self"], (@{@"0": date(1), @"1": date(2), @"2": NSNull.null}));
    XCTAssertEqualObjects([optUnmanaged.decimalObj valueForKey:@"self"], (@{@"0": decimal128(2), @"1": decimal128(3), @"2": NSNull.null}));
    XCTAssertEqualObjects([optUnmanaged.objectIdObj valueForKey:@"self"], (@{@"0": objectId(1), @"1": objectId(2), @"2": NSNull.null}));
    XCTAssertEqualObjects([optUnmanaged.uuidObj valueForKey:@"self"], (@{@"0": uuid(@"00000000-0000-0000-0000-000000000000"), @"1": uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"), @"2": NSNull.null}));
    XCTAssertEqualObjects([managed.boolObj valueForKey:@"self"], (@{@"0": @NO, @"1": @YES}));
    XCTAssertEqualObjects([managed.intObj valueForKey:@"self"], (@{@"0": @2, @"1": @3}));
    XCTAssertEqualObjects([managed.floatObj valueForKey:@"self"], (@{@"0": @2.2f, @"1": @3.3f}));
    XCTAssertEqualObjects([managed.doubleObj valueForKey:@"self"], (@{@"0": @2.2, @"1": @3.3}));
    XCTAssertEqualObjects([managed.stringObj valueForKey:@"self"], (@{@"0": @"a", @"1": @"b"}));
    XCTAssertEqualObjects([managed.dataObj valueForKey:@"self"], (@{@"0": data(1), @"1": data(2)}));
    XCTAssertEqualObjects([managed.dateObj valueForKey:@"self"], (@{@"0": date(1), @"1": date(2)}));
    XCTAssertEqualObjects([managed.decimalObj valueForKey:@"self"], (@{@"0": decimal128(2), @"1": decimal128(3)}));
    XCTAssertEqualObjects([managed.objectIdObj valueForKey:@"self"], (@{@"0": objectId(1), @"1": objectId(2)}));
    XCTAssertEqualObjects([managed.uuidObj valueForKey:@"self"], (@{@"0": uuid(@"00000000-0000-0000-0000-000000000000"), @"1": uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")}));
    XCTAssertEqualObjects([optManaged.boolObj valueForKey:@"self"], (@{@"0": @NO, @"1": @YES, @"2": NSNull.null}));
    XCTAssertEqualObjects([optManaged.intObj valueForKey:@"self"], (@{@"0": @2, @"1": @3, @"2": NSNull.null}));
    XCTAssertEqualObjects([optManaged.floatObj valueForKey:@"self"], (@{@"0": @2.2f, @"1": @3.3f, @"2": NSNull.null}));
    XCTAssertEqualObjects([optManaged.doubleObj valueForKey:@"self"], (@{@"0": @2.2, @"1": @3.3, @"2": NSNull.null}));
    XCTAssertEqualObjects([optManaged.stringObj valueForKey:@"self"], (@{@"0": @"a", @"1": @"b", @"2": NSNull.null}));
    XCTAssertEqualObjects([optManaged.dataObj valueForKey:@"self"], (@{@"0": data(1), @"1": data(2), @"2": NSNull.null}));
    XCTAssertEqualObjects([optManaged.dateObj valueForKey:@"self"], (@{@"0": date(1), @"1": date(2), @"2": NSNull.null}));
    XCTAssertEqualObjects([optManaged.decimalObj valueForKey:@"self"], (@{@"0": decimal128(2), @"1": decimal128(3), @"2": NSNull.null}));
    XCTAssertEqualObjects([optManaged.objectIdObj valueForKey:@"self"], (@{@"0": objectId(1), @"1": objectId(2), @"2": NSNull.null}));
    XCTAssertEqualObjects([optManaged.uuidObj valueForKey:@"self"], (@{@"0": uuid(@"00000000-0000-0000-0000-000000000000"), @"1": uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"), @"2": NSNull.null}));
}

- (void)testValueForKeyNumericAggregates {

    [self addObjects];

}

- (void)testValueForKeyLength {
    for (RLMDictionary *dictionary in allDictionaries) {
        XCTAssertEqualObjects([dictionary valueForKey:@"length"], @[]);
    }

    [self addObjects];

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
    for (RLMDictionary *dictionary in allDictionaries) {
        XCTAssertEqualObjects([dictionary valueForKeyPath:@"@unionOfObjects.self"], @[]);
    }
    for (RLMDictionary *dictionary in allDictionaries) {
        XCTAssertEqualObjects([dictionary valueForKeyPath:@"@distinctUnionOfObjects.self"], @[]);
    }

    [self addObjects];
    [self addObjects];

    XCTAssertEqualObjects([unmanaged.boolObj valueForKeyPath:@"@unionOfObjects.self"],
                          (@{@"0": @NO, @"1": @YES}));
    XCTAssertEqualObjects([unmanaged.intObj valueForKeyPath:@"@unionOfObjects.self"],
                          (@{@"0": @2, @"1": @4}));
    XCTAssertEqualObjects([unmanaged.floatObj valueForKeyPath:@"@unionOfObjects.self"],
                          (@{@"0": @2.2f, @"1": @4.4f}));
    XCTAssertEqualObjects([unmanaged.doubleObj valueForKeyPath:@"@unionOfObjects.self"],
                          (@{@"0": @2.2, @"1": @4.4}));
    XCTAssertEqualObjects([unmanaged.stringObj valueForKeyPath:@"@unionOfObjects.self"],
                          (@{@"0": @"a", @"1": @"de"}));
    XCTAssertEqualObjects([unmanaged.dataObj valueForKeyPath:@"@unionOfObjects.self"],
                          (@{@"0": data(1), @"1": data(3)}));
    XCTAssertEqualObjects([unmanaged.dateObj valueForKeyPath:@"@unionOfObjects.self"],
                          (@{@"0": date(1), @"1": date(3)}));
    XCTAssertEqualObjects([unmanaged.decimalObj valueForKeyPath:@"@unionOfObjects.self"],
                          (@{@"0": decimal128(1), @"1": decimal128(3)}));
    XCTAssertEqualObjects([unmanaged.objectIdObj valueForKeyPath:@"@unionOfObjects.self"],
                          (@{@"0": objectId(1), @"1": objectId(3)}));
    XCTAssertEqualObjects([unmanaged.uuidObj valueForKeyPath:@"@unionOfObjects.self"],
                          (@{@"0": uuid(@"00000000-0000-0000-0000-000000000000"), @"1": uuid(@"123DECC8-B300-4954-A233-F89909F4FD89")}));
    XCTAssertEqualObjects([optUnmanaged.boolObj valueForKeyPath:@"@unionOfObjects.self"],
                          (@{@"0": @YES, @"1": @NO}));
    XCTAssertEqualObjects([optUnmanaged.intObj valueForKeyPath:@"@unionOfObjects.self"],
                          (@{@"0": @3, @"1": @4}));
    XCTAssertEqualObjects([optUnmanaged.floatObj valueForKeyPath:@"@unionOfObjects.self"],
                          (@{@"0": @3.3f, @"1": @4.4f}));
    XCTAssertEqualObjects([optUnmanaged.doubleObj valueForKeyPath:@"@unionOfObjects.self"],
                          (@{@"0": @3.3, @"1": @4.4}));
    XCTAssertEqualObjects([optUnmanaged.stringObj valueForKeyPath:@"@unionOfObjects.self"],
                          (@{@"0": @"bc", @"1": @"de"}));
    XCTAssertEqualObjects([optUnmanaged.dataObj valueForKeyPath:@"@unionOfObjects.self"],
                          (@{@"0": data(2), @"1": data(3)}));
    XCTAssertEqualObjects([optUnmanaged.dateObj valueForKeyPath:@"@unionOfObjects.self"],
                          (@{@"0": date(2), @"1": date(3)}));
    XCTAssertEqualObjects([optUnmanaged.decimalObj valueForKeyPath:@"@unionOfObjects.self"],
                          (@{@"0": decimal128(2), @"1": decimal128(4)}));
    XCTAssertEqualObjects([optUnmanaged.objectIdObj valueForKeyPath:@"@unionOfObjects.self"],
                          (@{@"0": objectId(2), @"1": objectId(4)}));
    XCTAssertEqualObjects([optUnmanaged.uuidObj valueForKeyPath:@"@unionOfObjects.self"],
                          (@{@"0": uuid(@"00000000-0000-0000-0000-000000000000"), @"1": uuid(@"123DECC8-B300-4954-A233-F89909F4FD89")}));
    XCTAssertEqualObjects([managed.boolObj valueForKeyPath:@"@unionOfObjects.self"],
                          (@{@"0": @YES, @"1": @NO}));
    XCTAssertEqualObjects([managed.intObj valueForKeyPath:@"@unionOfObjects.self"],
                          (@{@"0": @3, @"1": @4}));
    XCTAssertEqualObjects([managed.floatObj valueForKeyPath:@"@unionOfObjects.self"],
                          (@{@"0": @3.3f, @"1": @4.4f}));
    XCTAssertEqualObjects([managed.doubleObj valueForKeyPath:@"@unionOfObjects.self"],
                          (@{@"0": @3.3, @"1": @4.4}));
    XCTAssertEqualObjects([managed.stringObj valueForKeyPath:@"@unionOfObjects.self"],
                          (@{@"0": @"bc", @"1": @"de"}));
    XCTAssertEqualObjects([managed.dataObj valueForKeyPath:@"@unionOfObjects.self"],
                          (@{@"0": data(2), @"1": data(3)}));
    XCTAssertEqualObjects([managed.dateObj valueForKeyPath:@"@unionOfObjects.self"],
                          (@{@"0": date(2), @"1": date(3)}));
    XCTAssertEqualObjects([managed.decimalObj valueForKeyPath:@"@unionOfObjects.self"],
                          (@{@"0": decimal128(2), @"1": decimal128(3)}));
    XCTAssertEqualObjects([managed.objectIdObj valueForKeyPath:@"@unionOfObjects.self"],
                          (@{@"0": objectId(2), @"1": objectId(3)}));
    XCTAssertEqualObjects([managed.uuidObj valueForKeyPath:@"@unionOfObjects.self"],
                          (@{@"0": uuid(@"00000000-0000-0000-0000-000000000000"), @"1": uuid(@"123DECC8-B300-4954-A233-F89909F4FD89")}));
    XCTAssertEqualObjects([optManaged.boolObj valueForKeyPath:@"@unionOfObjects.self"],
                          (@{@"0": @YES, @"1": @NO}));
    XCTAssertEqualObjects([optManaged.intObj valueForKeyPath:@"@unionOfObjects.self"],
                          (@{@"0": @3, @"1": @4}));
    XCTAssertEqualObjects([optManaged.floatObj valueForKeyPath:@"@unionOfObjects.self"],
                          (@{@"0": @3.3f, @"1": @4.4f}));
    XCTAssertEqualObjects([optManaged.doubleObj valueForKeyPath:@"@unionOfObjects.self"],
                          (@{@"0": @3.3, @"1": @4.4}));
    XCTAssertEqualObjects([optManaged.stringObj valueForKeyPath:@"@unionOfObjects.self"],
                          (@{@"0": @"bc", @"1": @"de"}));
    XCTAssertEqualObjects([optManaged.dataObj valueForKeyPath:@"@unionOfObjects.self"],
                          (@{@"0": data(2), @"1": data(3)}));
    XCTAssertEqualObjects([optManaged.dateObj valueForKeyPath:@"@unionOfObjects.self"],
                          (@{@"0": date(2), @"1": date(3)}));
    XCTAssertEqualObjects([optManaged.decimalObj valueForKeyPath:@"@unionOfObjects.self"],
                          (@{@"0": decimal128(2), @"1": decimal128(3)}));
    XCTAssertEqualObjects([optManaged.objectIdObj valueForKeyPath:@"@unionOfObjects.self"],
                          (@{@"0": objectId(2), @"1": objectId(3)}));
    XCTAssertEqualObjects([optManaged.uuidObj valueForKeyPath:@"@unionOfObjects.self"],
                          (@{@"0": uuid(@"00000000-0000-0000-0000-000000000000"), @"1": uuid(@"123DECC8-B300-4954-A233-F89909F4FD89")}));
    XCTAssertEqualObjects(sortedDistinctUnion(unmanaged.boolObj, @"Objects", @"self"),
                          (@{@"0": @NO, @"1": @YES}));
    XCTAssertEqualObjects(sortedDistinctUnion(unmanaged.intObj, @"Objects", @"self"),
                          (@{@"0": @2, @"1": @3}));
    XCTAssertEqualObjects(sortedDistinctUnion(unmanaged.floatObj, @"Objects", @"self"),
                          (@{@"0": @2.2f, @"1": @3.3f}));
    XCTAssertEqualObjects(sortedDistinctUnion(unmanaged.doubleObj, @"Objects", @"self"),
                          (@{@"0": @2.2, @"1": @3.3}));
    XCTAssertEqualObjects(sortedDistinctUnion(unmanaged.stringObj, @"Objects", @"self"),
                          (@{@"0": @"a", @"1": @"b"}));
    XCTAssertEqualObjects(sortedDistinctUnion(unmanaged.dataObj, @"Objects", @"self"),
                          (@{@"0": data(1), @"1": data(2)}));
    XCTAssertEqualObjects(sortedDistinctUnion(unmanaged.dateObj, @"Objects", @"self"),
                          (@{@"0": date(1), @"1": date(2)}));
    XCTAssertEqualObjects(sortedDistinctUnion(unmanaged.decimalObj, @"Objects", @"self"),
                          (@{@"0": decimal128(2), @"1": decimal128(3)}));
    XCTAssertEqualObjects(sortedDistinctUnion(unmanaged.objectIdObj, @"Objects", @"self"),
                          (@{@"0": objectId(1), @"1": objectId(2)}));
    XCTAssertEqualObjects(sortedDistinctUnion(unmanaged.uuidObj, @"Objects", @"self"),
                          (@{@"0": uuid(@"00000000-0000-0000-0000-000000000000"), @"1": uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")}));
    XCTAssertEqualObjects(sortedDistinctUnion(optUnmanaged.boolObj, @"Objects", @"self"),
                          (@{@"0": @NO, @"1": @YES, @"2": NSNull.null}));
    XCTAssertEqualObjects(sortedDistinctUnion(optUnmanaged.intObj, @"Objects", @"self"),
                          (@{@"0": @2, @"1": @3, @"2": NSNull.null}));
    XCTAssertEqualObjects(sortedDistinctUnion(optUnmanaged.floatObj, @"Objects", @"self"),
                          (@{@"0": @2.2f, @"1": @3.3f, @"2": NSNull.null}));
    XCTAssertEqualObjects(sortedDistinctUnion(optUnmanaged.doubleObj, @"Objects", @"self"),
                          (@{@"0": @2.2, @"1": @3.3, @"2": NSNull.null}));
    XCTAssertEqualObjects(sortedDistinctUnion(optUnmanaged.stringObj, @"Objects", @"self"),
                          (@{@"0": @"a", @"1": @"b", @"2": NSNull.null}));
    XCTAssertEqualObjects(sortedDistinctUnion(optUnmanaged.dataObj, @"Objects", @"self"),
                          (@{@"0": data(1), @"1": data(2), @"2": NSNull.null}));
    XCTAssertEqualObjects(sortedDistinctUnion(optUnmanaged.dateObj, @"Objects", @"self"),
                          (@{@"0": date(1), @"1": date(2), @"2": NSNull.null}));
    XCTAssertEqualObjects(sortedDistinctUnion(optUnmanaged.decimalObj, @"Objects", @"self"),
                          (@{@"0": decimal128(2), @"1": decimal128(3), @"2": NSNull.null}));
    XCTAssertEqualObjects(sortedDistinctUnion(optUnmanaged.objectIdObj, @"Objects", @"self"),
                          (@{@"0": objectId(1), @"1": objectId(2), @"2": NSNull.null}));
    XCTAssertEqualObjects(sortedDistinctUnion(optUnmanaged.uuidObj, @"Objects", @"self"),
                          (@{@"0": uuid(@"00000000-0000-0000-0000-000000000000"), @"1": uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"), @"2": NSNull.null}));
    XCTAssertEqualObjects(sortedDistinctUnion(managed.boolObj, @"Objects", @"self"),
                          (@{@"0": @NO, @"1": @YES}));
    XCTAssertEqualObjects(sortedDistinctUnion(managed.intObj, @"Objects", @"self"),
                          (@{@"0": @2, @"1": @3}));
    XCTAssertEqualObjects(sortedDistinctUnion(managed.floatObj, @"Objects", @"self"),
                          (@{@"0": @2.2f, @"1": @3.3f}));
    XCTAssertEqualObjects(sortedDistinctUnion(managed.doubleObj, @"Objects", @"self"),
                          (@{@"0": @2.2, @"1": @3.3}));
    XCTAssertEqualObjects(sortedDistinctUnion(managed.stringObj, @"Objects", @"self"),
                          (@{@"0": @"a", @"1": @"b"}));
    XCTAssertEqualObjects(sortedDistinctUnion(managed.dataObj, @"Objects", @"self"),
                          (@{@"0": data(1), @"1": data(2)}));
    XCTAssertEqualObjects(sortedDistinctUnion(managed.dateObj, @"Objects", @"self"),
                          (@{@"0": date(1), @"1": date(2)}));
    XCTAssertEqualObjects(sortedDistinctUnion(managed.decimalObj, @"Objects", @"self"),
                          (@{@"0": decimal128(2), @"1": decimal128(3)}));
    XCTAssertEqualObjects(sortedDistinctUnion(managed.objectIdObj, @"Objects", @"self"),
                          (@{@"0": objectId(1), @"1": objectId(2)}));
    XCTAssertEqualObjects(sortedDistinctUnion(managed.uuidObj, @"Objects", @"self"),
                          (@{@"0": uuid(@"00000000-0000-0000-0000-000000000000"), @"1": uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")}));
    XCTAssertEqualObjects(sortedDistinctUnion(optManaged.boolObj, @"Objects", @"self"),
                          (@{@"0": @NO, @"1": @YES, @"2": NSNull.null}));
    XCTAssertEqualObjects(sortedDistinctUnion(optManaged.intObj, @"Objects", @"self"),
                          (@{@"0": @2, @"1": @3, @"2": NSNull.null}));
    XCTAssertEqualObjects(sortedDistinctUnion(optManaged.floatObj, @"Objects", @"self"),
                          (@{@"0": @2.2f, @"1": @3.3f, @"2": NSNull.null}));
    XCTAssertEqualObjects(sortedDistinctUnion(optManaged.doubleObj, @"Objects", @"self"),
                          (@{@"0": @2.2, @"1": @3.3, @"2": NSNull.null}));
    XCTAssertEqualObjects(sortedDistinctUnion(optManaged.stringObj, @"Objects", @"self"),
                          (@{@"0": @"a", @"1": @"b", @"2": NSNull.null}));
    XCTAssertEqualObjects(sortedDistinctUnion(optManaged.dataObj, @"Objects", @"self"),
                          (@{@"0": data(1), @"1": data(2), @"2": NSNull.null}));
    XCTAssertEqualObjects(sortedDistinctUnion(optManaged.dateObj, @"Objects", @"self"),
                          (@{@"0": date(1), @"1": date(2), @"2": NSNull.null}));
    XCTAssertEqualObjects(sortedDistinctUnion(optManaged.decimalObj, @"Objects", @"self"),
                          (@{@"0": decimal128(2), @"1": decimal128(3), @"2": NSNull.null}));
    XCTAssertEqualObjects(sortedDistinctUnion(optManaged.objectIdObj, @"Objects", @"self"),
                          (@{@"0": objectId(1), @"1": objectId(2), @"2": NSNull.null}));
    XCTAssertEqualObjects(sortedDistinctUnion(optManaged.uuidObj, @"Objects", @"self"),
                          (@{@"0": uuid(@"00000000-0000-0000-0000-000000000000"), @"1": uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"), @"2": NSNull.null}));
}

- (void)testUnionOfArrays {
    RLMResults *allRequired = [AllPrimitiveDictionaries allObjectsInRealm:realm];
    RLMResults *allOptional = [AllOptionalPrimitiveDictionaries allObjectsInRealm:realm];


    [self addObjects];

    [AllPrimitiveDictionaries createInRealm:realm withValue:managed];
    [AllOptionalPrimitiveDictionaries createInRealm:realm withValue:optManaged];

}

- (void)testSetValueForKey {
    for (RLMDictionary *dictionary in allDictionaries) {
        RLMAssertThrowsWithReason([dictionary setValue:@0 forKey:@"not self"],
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
    RLMAssertThrowsWithReason([unmanaged.stringObj setValue:@"a" forKey:@"self"],
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'string'");
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
    RLMAssertThrowsWithReason([optUnmanaged.stringObj setValue:@"a" forKey:@"self"],
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'string?'");
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
    RLMAssertThrowsWithReason([managed.stringObj setValue:@"a" forKey:@"self"],
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'string'");
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
    RLMAssertThrowsWithReason([optManaged.stringObj setValue:@"a" forKey:@"self"],
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'string?'");
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

}

- (void)testAssignment {
    unmanaged.boolObj = (id)@{@"testKey": @YES};
    XCTAssertEqualObjects(unmanaged.boolObj[@"testKey"], @YES);
    unmanaged.intObj = (id)@{@"testKey": @3};
    XCTAssertEqualObjects(unmanaged.intObj[@"testKey"], @3);
    unmanaged.floatObj = (id)@{@"testKey": @3.3f};
    XCTAssertEqualObjects(unmanaged.floatObj[@"testKey"], @3.3f);
    unmanaged.doubleObj = (id)@{@"testKey": @3.3};
    XCTAssertEqualObjects(unmanaged.doubleObj[@"testKey"], @3.3);
    unmanaged.stringObj = (id)@{@"testKey": @"b"};
    XCTAssertEqualObjects(unmanaged.stringObj[@"testKey"], @"b");
    unmanaged.dataObj = (id)@{@"testKey": data(2)};
    XCTAssertEqualObjects(unmanaged.dataObj[@"testKey"], data(2));
    unmanaged.dateObj = (id)@{@"testKey": date(2)};
    XCTAssertEqualObjects(unmanaged.dateObj[@"testKey"], date(2));
    unmanaged.decimalObj = (id)@{@"testKey": decimal128(3)};
    XCTAssertEqualObjects(unmanaged.decimalObj[@"testKey"], decimal128(3));
    unmanaged.objectIdObj = (id)@{@"testKey": objectId(2)};
    XCTAssertEqualObjects(unmanaged.objectIdObj[@"testKey"], objectId(2));
    unmanaged.uuidObj = (id)@{@"testKey": uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")};
    XCTAssertEqualObjects(unmanaged.uuidObj[@"testKey"], uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"));
    optUnmanaged.boolObj = (id)@{@"testKey": @YES};
    XCTAssertEqualObjects(optUnmanaged.boolObj[@"testKey"], @YES);
    optUnmanaged.intObj = (id)@{@"testKey": @3};
    XCTAssertEqualObjects(optUnmanaged.intObj[@"testKey"], @3);
    optUnmanaged.floatObj = (id)@{@"testKey": @3.3f};
    XCTAssertEqualObjects(optUnmanaged.floatObj[@"testKey"], @3.3f);
    optUnmanaged.doubleObj = (id)@{@"testKey": @3.3};
    XCTAssertEqualObjects(optUnmanaged.doubleObj[@"testKey"], @3.3);
    optUnmanaged.stringObj = (id)@{@"testKey": @"b"};
    XCTAssertEqualObjects(optUnmanaged.stringObj[@"testKey"], @"b");
    optUnmanaged.dataObj = (id)@{@"testKey": data(2)};
    XCTAssertEqualObjects(optUnmanaged.dataObj[@"testKey"], data(2));
    optUnmanaged.dateObj = (id)@{@"testKey": date(2)};
    XCTAssertEqualObjects(optUnmanaged.dateObj[@"testKey"], date(2));
    optUnmanaged.decimalObj = (id)@{@"testKey": decimal128(3)};
    XCTAssertEqualObjects(optUnmanaged.decimalObj[@"testKey"], decimal128(3));
    optUnmanaged.objectIdObj = (id)@{@"testKey": objectId(2)};
    XCTAssertEqualObjects(optUnmanaged.objectIdObj[@"testKey"], objectId(2));
    optUnmanaged.uuidObj = (id)@{@"testKey": uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")};
    XCTAssertEqualObjects(optUnmanaged.uuidObj[@"testKey"], uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"));
    managed.boolObj = (id)@{@"testKey": @YES};
    XCTAssertEqualObjects(managed.boolObj[@"testKey"], @YES);
    managed.intObj = (id)@{@"testKey": @3};
    XCTAssertEqualObjects(managed.intObj[@"testKey"], @3);
    managed.floatObj = (id)@{@"testKey": @3.3f};
    XCTAssertEqualObjects(managed.floatObj[@"testKey"], @3.3f);
    managed.doubleObj = (id)@{@"testKey": @3.3};
    XCTAssertEqualObjects(managed.doubleObj[@"testKey"], @3.3);
    managed.stringObj = (id)@{@"testKey": @"b"};
    XCTAssertEqualObjects(managed.stringObj[@"testKey"], @"b");
    managed.dataObj = (id)@{@"testKey": data(2)};
    XCTAssertEqualObjects(managed.dataObj[@"testKey"], data(2));
    managed.dateObj = (id)@{@"testKey": date(2)};
    XCTAssertEqualObjects(managed.dateObj[@"testKey"], date(2));
    managed.decimalObj = (id)@{@"testKey": decimal128(3)};
    XCTAssertEqualObjects(managed.decimalObj[@"testKey"], decimal128(3));
    managed.objectIdObj = (id)@{@"testKey": objectId(2)};
    XCTAssertEqualObjects(managed.objectIdObj[@"testKey"], objectId(2));
    managed.uuidObj = (id)@{@"testKey": uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")};
    XCTAssertEqualObjects(managed.uuidObj[@"testKey"], uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"));
    optManaged.boolObj = (id)@{@"testKey": @YES};
    XCTAssertEqualObjects(optManaged.boolObj[@"testKey"], @YES);
    optManaged.intObj = (id)@{@"testKey": @3};
    XCTAssertEqualObjects(optManaged.intObj[@"testKey"], @3);
    optManaged.floatObj = (id)@{@"testKey": @3.3f};
    XCTAssertEqualObjects(optManaged.floatObj[@"testKey"], @3.3f);
    optManaged.doubleObj = (id)@{@"testKey": @3.3};
    XCTAssertEqualObjects(optManaged.doubleObj[@"testKey"], @3.3);
    optManaged.stringObj = (id)@{@"testKey": @"b"};
    XCTAssertEqualObjects(optManaged.stringObj[@"testKey"], @"b");
    optManaged.dataObj = (id)@{@"testKey": data(2)};
    XCTAssertEqualObjects(optManaged.dataObj[@"testKey"], data(2));
    optManaged.dateObj = (id)@{@"testKey": date(2)};
    XCTAssertEqualObjects(optManaged.dateObj[@"testKey"], date(2));
    optManaged.decimalObj = (id)@{@"testKey": decimal128(3)};
    XCTAssertEqualObjects(optManaged.decimalObj[@"testKey"], decimal128(3));
    optManaged.objectIdObj = (id)@{@"testKey": objectId(2)};
    XCTAssertEqualObjects(optManaged.objectIdObj[@"testKey"], objectId(2));
    optManaged.uuidObj = (id)@{@"testKey": uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")};
    XCTAssertEqualObjects(optManaged.uuidObj[@"testKey"], uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"));

    // Should replace and not append
    unmanaged.boolObj = (id)@{@"0": @NO, @"1": @YES};
    XCTAssertEqualObjects([unmanaged.boolObj valueForKey:@"self"], (@{@"0": @NO, @"1": @YES}));
    
    unmanaged.intObj = (id)@{@"0": @2, @"1": @3};
    XCTAssertEqualObjects([unmanaged.intObj valueForKey:@"self"], (@{@"0": @2, @"1": @3}));
    
    unmanaged.floatObj = (id)@{@"0": @2.2f, @"1": @3.3f};
    XCTAssertEqualObjects([unmanaged.floatObj valueForKey:@"self"], (@{@"0": @2.2f, @"1": @3.3f}));
    
    unmanaged.doubleObj = (id)@{@"0": @2.2, @"1": @3.3};
    XCTAssertEqualObjects([unmanaged.doubleObj valueForKey:@"self"], (@{@"0": @2.2, @"1": @3.3}));
    
    unmanaged.stringObj = (id)@{@"0": @"a", @"1": @"b"};
    XCTAssertEqualObjects([unmanaged.stringObj valueForKey:@"self"], (@{@"0": @"a", @"1": @"b"}));
    
    unmanaged.dataObj = (id)@{@"0": data(1), @"1": data(2)};
    XCTAssertEqualObjects([unmanaged.dataObj valueForKey:@"self"], (@{@"0": data(1), @"1": data(2)}));
    
    unmanaged.dateObj = (id)@{@"0": date(1), @"1": date(2)};
    XCTAssertEqualObjects([unmanaged.dateObj valueForKey:@"self"], (@{@"0": date(1), @"1": date(2)}));
    
    unmanaged.decimalObj = (id)@{@"0": decimal128(2), @"1": decimal128(3)};
    XCTAssertEqualObjects([unmanaged.decimalObj valueForKey:@"self"], (@{@"0": decimal128(2), @"1": decimal128(3)}));
    
    unmanaged.objectIdObj = (id)@{@"0": objectId(1), @"1": objectId(2)};
    XCTAssertEqualObjects([unmanaged.objectIdObj valueForKey:@"self"], (@{@"0": objectId(1), @"1": objectId(2)}));
    
    unmanaged.uuidObj = (id)@{@"0": uuid(@"00000000-0000-0000-0000-000000000000"), @"1": uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")};
    XCTAssertEqualObjects([unmanaged.uuidObj valueForKey:@"self"], (@{@"0": uuid(@"00000000-0000-0000-0000-000000000000"), @"1": uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")}));
    
    optUnmanaged.boolObj = (id)@{@"0": @NO, @"1": @YES, @"2": NSNull.null};
    XCTAssertEqualObjects([optUnmanaged.boolObj valueForKey:@"self"], (@{@"0": @NO, @"1": @YES, @"2": NSNull.null}));
    
    optUnmanaged.intObj = (id)@{@"0": @2, @"1": @3, @"2": NSNull.null};
    XCTAssertEqualObjects([optUnmanaged.intObj valueForKey:@"self"], (@{@"0": @2, @"1": @3, @"2": NSNull.null}));
    
    optUnmanaged.floatObj = (id)@{@"0": @2.2f, @"1": @3.3f, @"2": NSNull.null};
    XCTAssertEqualObjects([optUnmanaged.floatObj valueForKey:@"self"], (@{@"0": @2.2f, @"1": @3.3f, @"2": NSNull.null}));
    
    optUnmanaged.doubleObj = (id)@{@"0": @2.2, @"1": @3.3, @"2": NSNull.null};
    XCTAssertEqualObjects([optUnmanaged.doubleObj valueForKey:@"self"], (@{@"0": @2.2, @"1": @3.3, @"2": NSNull.null}));
    
    optUnmanaged.stringObj = (id)@{@"0": @"a", @"1": @"b", @"2": NSNull.null};
    XCTAssertEqualObjects([optUnmanaged.stringObj valueForKey:@"self"], (@{@"0": @"a", @"1": @"b", @"2": NSNull.null}));
    
    optUnmanaged.dataObj = (id)@{@"0": data(1), @"1": data(2), @"2": NSNull.null};
    XCTAssertEqualObjects([optUnmanaged.dataObj valueForKey:@"self"], (@{@"0": data(1), @"1": data(2), @"2": NSNull.null}));
    
    optUnmanaged.dateObj = (id)@{@"0": date(1), @"1": date(2), @"2": NSNull.null};
    XCTAssertEqualObjects([optUnmanaged.dateObj valueForKey:@"self"], (@{@"0": date(1), @"1": date(2), @"2": NSNull.null}));
    
    optUnmanaged.decimalObj = (id)@{@"0": decimal128(2), @"1": decimal128(3), @"2": NSNull.null};
    XCTAssertEqualObjects([optUnmanaged.decimalObj valueForKey:@"self"], (@{@"0": decimal128(2), @"1": decimal128(3), @"2": NSNull.null}));
    
    optUnmanaged.objectIdObj = (id)@{@"0": objectId(1), @"1": objectId(2), @"2": NSNull.null};
    XCTAssertEqualObjects([optUnmanaged.objectIdObj valueForKey:@"self"], (@{@"0": objectId(1), @"1": objectId(2), @"2": NSNull.null}));
    
    optUnmanaged.uuidObj = (id)@{@"0": uuid(@"00000000-0000-0000-0000-000000000000"), @"1": uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"), @"2": NSNull.null};
    XCTAssertEqualObjects([optUnmanaged.uuidObj valueForKey:@"self"], (@{@"0": uuid(@"00000000-0000-0000-0000-000000000000"), @"1": uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"), @"2": NSNull.null}));
    
    managed.boolObj = (id)@{@"0": @NO, @"1": @YES};
    XCTAssertEqualObjects([managed.boolObj valueForKey:@"self"], (@{@"0": @NO, @"1": @YES}));
    
    managed.intObj = (id)@{@"0": @2, @"1": @3};
    XCTAssertEqualObjects([managed.intObj valueForKey:@"self"], (@{@"0": @2, @"1": @3}));
    
    managed.floatObj = (id)@{@"0": @2.2f, @"1": @3.3f};
    XCTAssertEqualObjects([managed.floatObj valueForKey:@"self"], (@{@"0": @2.2f, @"1": @3.3f}));
    
    managed.doubleObj = (id)@{@"0": @2.2, @"1": @3.3};
    XCTAssertEqualObjects([managed.doubleObj valueForKey:@"self"], (@{@"0": @2.2, @"1": @3.3}));
    
    managed.stringObj = (id)@{@"0": @"a", @"1": @"b"};
    XCTAssertEqualObjects([managed.stringObj valueForKey:@"self"], (@{@"0": @"a", @"1": @"b"}));
    
    managed.dataObj = (id)@{@"0": data(1), @"1": data(2)};
    XCTAssertEqualObjects([managed.dataObj valueForKey:@"self"], (@{@"0": data(1), @"1": data(2)}));
    
    managed.dateObj = (id)@{@"0": date(1), @"1": date(2)};
    XCTAssertEqualObjects([managed.dateObj valueForKey:@"self"], (@{@"0": date(1), @"1": date(2)}));
    
    managed.decimalObj = (id)@{@"0": decimal128(2), @"1": decimal128(3)};
    XCTAssertEqualObjects([managed.decimalObj valueForKey:@"self"], (@{@"0": decimal128(2), @"1": decimal128(3)}));
    
    managed.objectIdObj = (id)@{@"0": objectId(1), @"1": objectId(2)};
    XCTAssertEqualObjects([managed.objectIdObj valueForKey:@"self"], (@{@"0": objectId(1), @"1": objectId(2)}));
    
    managed.uuidObj = (id)@{@"0": uuid(@"00000000-0000-0000-0000-000000000000"), @"1": uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")};
    XCTAssertEqualObjects([managed.uuidObj valueForKey:@"self"], (@{@"0": uuid(@"00000000-0000-0000-0000-000000000000"), @"1": uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")}));
    
    optManaged.boolObj = (id)@{@"0": @NO, @"1": @YES, @"2": NSNull.null};
    XCTAssertEqualObjects([optManaged.boolObj valueForKey:@"self"], (@{@"0": @NO, @"1": @YES, @"2": NSNull.null}));
    
    optManaged.intObj = (id)@{@"0": @2, @"1": @3, @"2": NSNull.null};
    XCTAssertEqualObjects([optManaged.intObj valueForKey:@"self"], (@{@"0": @2, @"1": @3, @"2": NSNull.null}));
    
    optManaged.floatObj = (id)@{@"0": @2.2f, @"1": @3.3f, @"2": NSNull.null};
    XCTAssertEqualObjects([optManaged.floatObj valueForKey:@"self"], (@{@"0": @2.2f, @"1": @3.3f, @"2": NSNull.null}));
    
    optManaged.doubleObj = (id)@{@"0": @2.2, @"1": @3.3, @"2": NSNull.null};
    XCTAssertEqualObjects([optManaged.doubleObj valueForKey:@"self"], (@{@"0": @2.2, @"1": @3.3, @"2": NSNull.null}));
    
    optManaged.stringObj = (id)@{@"0": @"a", @"1": @"b", @"2": NSNull.null};
    XCTAssertEqualObjects([optManaged.stringObj valueForKey:@"self"], (@{@"0": @"a", @"1": @"b", @"2": NSNull.null}));
    
    optManaged.dataObj = (id)@{@"0": data(1), @"1": data(2), @"2": NSNull.null};
    XCTAssertEqualObjects([optManaged.dataObj valueForKey:@"self"], (@{@"0": data(1), @"1": data(2), @"2": NSNull.null}));
    
    optManaged.dateObj = (id)@{@"0": date(1), @"1": date(2), @"2": NSNull.null};
    XCTAssertEqualObjects([optManaged.dateObj valueForKey:@"self"], (@{@"0": date(1), @"1": date(2), @"2": NSNull.null}));
    
    optManaged.decimalObj = (id)@{@"0": decimal128(2), @"1": decimal128(3), @"2": NSNull.null};
    XCTAssertEqualObjects([optManaged.decimalObj valueForKey:@"self"], (@{@"0": decimal128(2), @"1": decimal128(3), @"2": NSNull.null}));
    
    optManaged.objectIdObj = (id)@{@"0": objectId(1), @"1": objectId(2), @"2": NSNull.null};
    XCTAssertEqualObjects([optManaged.objectIdObj valueForKey:@"self"], (@{@"0": objectId(1), @"1": objectId(2), @"2": NSNull.null}));
    
    optManaged.uuidObj = (id)@{@"0": uuid(@"00000000-0000-0000-0000-000000000000"), @"1": uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"), @"2": NSNull.null};
    XCTAssertEqualObjects([optManaged.uuidObj valueForKey:@"self"], (@{@"0": uuid(@"00000000-0000-0000-0000-000000000000"), @"1": uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"), @"2": NSNull.null}));
    

    // Should not clear the array
    unmanaged.boolObj = unmanaged.boolObj;
    XCTAssertEqualObjects([unmanaged.boolObj valueForKey:@"self"], (@{@"0": @NO, @"1": @YES}));
    
    unmanaged.intObj = unmanaged.intObj;
    XCTAssertEqualObjects([unmanaged.intObj valueForKey:@"self"], (@{@"0": @2, @"1": @3}));
    
    unmanaged.floatObj = unmanaged.floatObj;
    XCTAssertEqualObjects([unmanaged.floatObj valueForKey:@"self"], (@{@"0": @2.2f, @"1": @3.3f}));
    
    unmanaged.doubleObj = unmanaged.doubleObj;
    XCTAssertEqualObjects([unmanaged.doubleObj valueForKey:@"self"], (@{@"0": @2.2, @"1": @3.3}));
    
    unmanaged.stringObj = unmanaged.stringObj;
    XCTAssertEqualObjects([unmanaged.stringObj valueForKey:@"self"], (@{@"0": @"a", @"1": @"b"}));
    
    unmanaged.dataObj = unmanaged.dataObj;
    XCTAssertEqualObjects([unmanaged.dataObj valueForKey:@"self"], (@{@"0": data(1), @"1": data(2)}));
    
    unmanaged.dateObj = unmanaged.dateObj;
    XCTAssertEqualObjects([unmanaged.dateObj valueForKey:@"self"], (@{@"0": date(1), @"1": date(2)}));
    
    unmanaged.decimalObj = unmanaged.decimalObj;
    XCTAssertEqualObjects([unmanaged.decimalObj valueForKey:@"self"], (@{@"0": decimal128(2), @"1": decimal128(3)}));
    
    unmanaged.objectIdObj = unmanaged.objectIdObj;
    XCTAssertEqualObjects([unmanaged.objectIdObj valueForKey:@"self"], (@{@"0": objectId(1), @"1": objectId(2)}));
    
    unmanaged.uuidObj = unmanaged.uuidObj;
    XCTAssertEqualObjects([unmanaged.uuidObj valueForKey:@"self"], (@{@"0": uuid(@"00000000-0000-0000-0000-000000000000"), @"1": uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")}));
    
    optUnmanaged.boolObj = optUnmanaged.boolObj;
    XCTAssertEqualObjects([optUnmanaged.boolObj valueForKey:@"self"], (@{@"0": @NO, @"1": @YES, @"2": NSNull.null}));
    
    optUnmanaged.intObj = optUnmanaged.intObj;
    XCTAssertEqualObjects([optUnmanaged.intObj valueForKey:@"self"], (@{@"0": @2, @"1": @3, @"2": NSNull.null}));
    
    optUnmanaged.floatObj = optUnmanaged.floatObj;
    XCTAssertEqualObjects([optUnmanaged.floatObj valueForKey:@"self"], (@{@"0": @2.2f, @"1": @3.3f, @"2": NSNull.null}));
    
    optUnmanaged.doubleObj = optUnmanaged.doubleObj;
    XCTAssertEqualObjects([optUnmanaged.doubleObj valueForKey:@"self"], (@{@"0": @2.2, @"1": @3.3, @"2": NSNull.null}));
    
    optUnmanaged.stringObj = optUnmanaged.stringObj;
    XCTAssertEqualObjects([optUnmanaged.stringObj valueForKey:@"self"], (@{@"0": @"a", @"1": @"b", @"2": NSNull.null}));
    
    optUnmanaged.dataObj = optUnmanaged.dataObj;
    XCTAssertEqualObjects([optUnmanaged.dataObj valueForKey:@"self"], (@{@"0": data(1), @"1": data(2), @"2": NSNull.null}));
    
    optUnmanaged.dateObj = optUnmanaged.dateObj;
    XCTAssertEqualObjects([optUnmanaged.dateObj valueForKey:@"self"], (@{@"0": date(1), @"1": date(2), @"2": NSNull.null}));
    
    optUnmanaged.decimalObj = optUnmanaged.decimalObj;
    XCTAssertEqualObjects([optUnmanaged.decimalObj valueForKey:@"self"], (@{@"0": decimal128(2), @"1": decimal128(3), @"2": NSNull.null}));
    
    optUnmanaged.objectIdObj = optUnmanaged.objectIdObj;
    XCTAssertEqualObjects([optUnmanaged.objectIdObj valueForKey:@"self"], (@{@"0": objectId(1), @"1": objectId(2), @"2": NSNull.null}));
    
    optUnmanaged.uuidObj = optUnmanaged.uuidObj;
    XCTAssertEqualObjects([optUnmanaged.uuidObj valueForKey:@"self"], (@{@"0": uuid(@"00000000-0000-0000-0000-000000000000"), @"1": uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"), @"2": NSNull.null}));
    
    managed.boolObj = managed.boolObj;
    XCTAssertEqualObjects([managed.boolObj valueForKey:@"self"], (@{@"0": @NO, @"1": @YES}));
    
    managed.intObj = managed.intObj;
    XCTAssertEqualObjects([managed.intObj valueForKey:@"self"], (@{@"0": @2, @"1": @3}));
    
    managed.floatObj = managed.floatObj;
    XCTAssertEqualObjects([managed.floatObj valueForKey:@"self"], (@{@"0": @2.2f, @"1": @3.3f}));
    
    managed.doubleObj = managed.doubleObj;
    XCTAssertEqualObjects([managed.doubleObj valueForKey:@"self"], (@{@"0": @2.2, @"1": @3.3}));
    
    managed.stringObj = managed.stringObj;
    XCTAssertEqualObjects([managed.stringObj valueForKey:@"self"], (@{@"0": @"a", @"1": @"b"}));
    
    managed.dataObj = managed.dataObj;
    XCTAssertEqualObjects([managed.dataObj valueForKey:@"self"], (@{@"0": data(1), @"1": data(2)}));
    
    managed.dateObj = managed.dateObj;
    XCTAssertEqualObjects([managed.dateObj valueForKey:@"self"], (@{@"0": date(1), @"1": date(2)}));
    
    managed.decimalObj = managed.decimalObj;
    XCTAssertEqualObjects([managed.decimalObj valueForKey:@"self"], (@{@"0": decimal128(2), @"1": decimal128(3)}));
    
    managed.objectIdObj = managed.objectIdObj;
    XCTAssertEqualObjects([managed.objectIdObj valueForKey:@"self"], (@{@"0": objectId(1), @"1": objectId(2)}));
    
    managed.uuidObj = managed.uuidObj;
    XCTAssertEqualObjects([managed.uuidObj valueForKey:@"self"], (@{@"0": uuid(@"00000000-0000-0000-0000-000000000000"), @"1": uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")}));
    
    optManaged.boolObj = optManaged.boolObj;
    XCTAssertEqualObjects([optManaged.boolObj valueForKey:@"self"], (@{@"0": @NO, @"1": @YES, @"2": NSNull.null}));
    
    optManaged.intObj = optManaged.intObj;
    XCTAssertEqualObjects([optManaged.intObj valueForKey:@"self"], (@{@"0": @2, @"1": @3, @"2": NSNull.null}));
    
    optManaged.floatObj = optManaged.floatObj;
    XCTAssertEqualObjects([optManaged.floatObj valueForKey:@"self"], (@{@"0": @2.2f, @"1": @3.3f, @"2": NSNull.null}));
    
    optManaged.doubleObj = optManaged.doubleObj;
    XCTAssertEqualObjects([optManaged.doubleObj valueForKey:@"self"], (@{@"0": @2.2, @"1": @3.3, @"2": NSNull.null}));
    
    optManaged.stringObj = optManaged.stringObj;
    XCTAssertEqualObjects([optManaged.stringObj valueForKey:@"self"], (@{@"0": @"a", @"1": @"b", @"2": NSNull.null}));
    
    optManaged.dataObj = optManaged.dataObj;
    XCTAssertEqualObjects([optManaged.dataObj valueForKey:@"self"], (@{@"0": data(1), @"1": data(2), @"2": NSNull.null}));
    
    optManaged.dateObj = optManaged.dateObj;
    XCTAssertEqualObjects([optManaged.dateObj valueForKey:@"self"], (@{@"0": date(1), @"1": date(2), @"2": NSNull.null}));
    
    optManaged.decimalObj = optManaged.decimalObj;
    XCTAssertEqualObjects([optManaged.decimalObj valueForKey:@"self"], (@{@"0": decimal128(2), @"1": decimal128(3), @"2": NSNull.null}));
    
    optManaged.objectIdObj = optManaged.objectIdObj;
    XCTAssertEqualObjects([optManaged.objectIdObj valueForKey:@"self"], (@{@"0": objectId(1), @"1": objectId(2), @"2": NSNull.null}));
    
    optManaged.uuidObj = optManaged.uuidObj;
    XCTAssertEqualObjects([optManaged.uuidObj valueForKey:@"self"], (@{@"0": uuid(@"00000000-0000-0000-0000-000000000000"), @"1": uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"), @"2": NSNull.null}));
    

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
    unmanaged[@"boolObj"] = (id)@{@"0": @NO, @"1": @YES};
    XCTAssertEqualObjects([unmanaged[@"boolObj"] valueForKey:@"self"], (@{@"0": @NO, @"1": @YES}));
    
    unmanaged[@"intObj"] = (id)@{@"0": @2, @"1": @3};
    XCTAssertEqualObjects([unmanaged[@"intObj"] valueForKey:@"self"], (@{@"0": @2, @"1": @3}));
    
    unmanaged[@"floatObj"] = (id)@{@"0": @2.2f, @"1": @3.3f};
    XCTAssertEqualObjects([unmanaged[@"floatObj"] valueForKey:@"self"], (@{@"0": @2.2f, @"1": @3.3f}));
    
    unmanaged[@"doubleObj"] = (id)@{@"0": @2.2, @"1": @3.3};
    XCTAssertEqualObjects([unmanaged[@"doubleObj"] valueForKey:@"self"], (@{@"0": @2.2, @"1": @3.3}));
    
    unmanaged[@"stringObj"] = (id)@{@"0": @"a", @"1": @"b"};
    XCTAssertEqualObjects([unmanaged[@"stringObj"] valueForKey:@"self"], (@{@"0": @"a", @"1": @"b"}));
    
    unmanaged[@"dataObj"] = (id)@{@"0": data(1), @"1": data(2)};
    XCTAssertEqualObjects([unmanaged[@"dataObj"] valueForKey:@"self"], (@{@"0": data(1), @"1": data(2)}));
    
    unmanaged[@"dateObj"] = (id)@{@"0": date(1), @"1": date(2)};
    XCTAssertEqualObjects([unmanaged[@"dateObj"] valueForKey:@"self"], (@{@"0": date(1), @"1": date(2)}));
    
    unmanaged[@"decimalObj"] = (id)@{@"0": decimal128(2), @"1": decimal128(3)};
    XCTAssertEqualObjects([unmanaged[@"decimalObj"] valueForKey:@"self"], (@{@"0": decimal128(2), @"1": decimal128(3)}));
    
    unmanaged[@"objectIdObj"] = (id)@{@"0": objectId(1), @"1": objectId(2)};
    XCTAssertEqualObjects([unmanaged[@"objectIdObj"] valueForKey:@"self"], (@{@"0": objectId(1), @"1": objectId(2)}));
    
    unmanaged[@"uuidObj"] = (id)@{@"0": uuid(@"00000000-0000-0000-0000-000000000000"), @"1": uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")};
    XCTAssertEqualObjects([unmanaged[@"uuidObj"] valueForKey:@"self"], (@{@"0": uuid(@"00000000-0000-0000-0000-000000000000"), @"1": uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")}));
    
    optUnmanaged[@"boolObj"] = (id)@{@"0": @NO, @"1": @YES, @"2": NSNull.null};
    XCTAssertEqualObjects([optUnmanaged[@"boolObj"] valueForKey:@"self"], (@{@"0": @NO, @"1": @YES, @"2": NSNull.null}));
    
    optUnmanaged[@"intObj"] = (id)@{@"0": @2, @"1": @3, @"2": NSNull.null};
    XCTAssertEqualObjects([optUnmanaged[@"intObj"] valueForKey:@"self"], (@{@"0": @2, @"1": @3, @"2": NSNull.null}));
    
    optUnmanaged[@"floatObj"] = (id)@{@"0": @2.2f, @"1": @3.3f, @"2": NSNull.null};
    XCTAssertEqualObjects([optUnmanaged[@"floatObj"] valueForKey:@"self"], (@{@"0": @2.2f, @"1": @3.3f, @"2": NSNull.null}));
    
    optUnmanaged[@"doubleObj"] = (id)@{@"0": @2.2, @"1": @3.3, @"2": NSNull.null};
    XCTAssertEqualObjects([optUnmanaged[@"doubleObj"] valueForKey:@"self"], (@{@"0": @2.2, @"1": @3.3, @"2": NSNull.null}));
    
    optUnmanaged[@"stringObj"] = (id)@{@"0": @"a", @"1": @"b", @"2": NSNull.null};
    XCTAssertEqualObjects([optUnmanaged[@"stringObj"] valueForKey:@"self"], (@{@"0": @"a", @"1": @"b", @"2": NSNull.null}));
    
    optUnmanaged[@"dataObj"] = (id)@{@"0": data(1), @"1": data(2), @"2": NSNull.null};
    XCTAssertEqualObjects([optUnmanaged[@"dataObj"] valueForKey:@"self"], (@{@"0": data(1), @"1": data(2), @"2": NSNull.null}));
    
    optUnmanaged[@"dateObj"] = (id)@{@"0": date(1), @"1": date(2), @"2": NSNull.null};
    XCTAssertEqualObjects([optUnmanaged[@"dateObj"] valueForKey:@"self"], (@{@"0": date(1), @"1": date(2), @"2": NSNull.null}));
    
    optUnmanaged[@"decimalObj"] = (id)@{@"0": decimal128(2), @"1": decimal128(3), @"2": NSNull.null};
    XCTAssertEqualObjects([optUnmanaged[@"decimalObj"] valueForKey:@"self"], (@{@"0": decimal128(2), @"1": decimal128(3), @"2": NSNull.null}));
    
    optUnmanaged[@"objectIdObj"] = (id)@{@"0": objectId(1), @"1": objectId(2), @"2": NSNull.null};
    XCTAssertEqualObjects([optUnmanaged[@"objectIdObj"] valueForKey:@"self"], (@{@"0": objectId(1), @"1": objectId(2), @"2": NSNull.null}));
    
    optUnmanaged[@"uuidObj"] = (id)@{@"0": uuid(@"00000000-0000-0000-0000-000000000000"), @"1": uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"), @"2": NSNull.null};
    XCTAssertEqualObjects([optUnmanaged[@"uuidObj"] valueForKey:@"self"], (@{@"0": uuid(@"00000000-0000-0000-0000-000000000000"), @"1": uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"), @"2": NSNull.null}));
    
    managed[@"boolObj"] = (id)@{@"0": @NO, @"1": @YES};
    XCTAssertEqualObjects([managed[@"boolObj"] valueForKey:@"self"], (@{@"0": @NO, @"1": @YES}));
    
    managed[@"intObj"] = (id)@{@"0": @2, @"1": @3};
    XCTAssertEqualObjects([managed[@"intObj"] valueForKey:@"self"], (@{@"0": @2, @"1": @3}));
    
    managed[@"floatObj"] = (id)@{@"0": @2.2f, @"1": @3.3f};
    XCTAssertEqualObjects([managed[@"floatObj"] valueForKey:@"self"], (@{@"0": @2.2f, @"1": @3.3f}));
    
    managed[@"doubleObj"] = (id)@{@"0": @2.2, @"1": @3.3};
    XCTAssertEqualObjects([managed[@"doubleObj"] valueForKey:@"self"], (@{@"0": @2.2, @"1": @3.3}));
    
    managed[@"stringObj"] = (id)@{@"0": @"a", @"1": @"b"};
    XCTAssertEqualObjects([managed[@"stringObj"] valueForKey:@"self"], (@{@"0": @"a", @"1": @"b"}));
    
    managed[@"dataObj"] = (id)@{@"0": data(1), @"1": data(2)};
    XCTAssertEqualObjects([managed[@"dataObj"] valueForKey:@"self"], (@{@"0": data(1), @"1": data(2)}));
    
    managed[@"dateObj"] = (id)@{@"0": date(1), @"1": date(2)};
    XCTAssertEqualObjects([managed[@"dateObj"] valueForKey:@"self"], (@{@"0": date(1), @"1": date(2)}));
    
    managed[@"decimalObj"] = (id)@{@"0": decimal128(2), @"1": decimal128(3)};
    XCTAssertEqualObjects([managed[@"decimalObj"] valueForKey:@"self"], (@{@"0": decimal128(2), @"1": decimal128(3)}));
    
    managed[@"objectIdObj"] = (id)@{@"0": objectId(1), @"1": objectId(2)};
    XCTAssertEqualObjects([managed[@"objectIdObj"] valueForKey:@"self"], (@{@"0": objectId(1), @"1": objectId(2)}));
    
    managed[@"uuidObj"] = (id)@{@"0": uuid(@"00000000-0000-0000-0000-000000000000"), @"1": uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")};
    XCTAssertEqualObjects([managed[@"uuidObj"] valueForKey:@"self"], (@{@"0": uuid(@"00000000-0000-0000-0000-000000000000"), @"1": uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")}));
    
    optManaged[@"boolObj"] = (id)@{@"0": @NO, @"1": @YES, @"2": NSNull.null};
    XCTAssertEqualObjects([optManaged[@"boolObj"] valueForKey:@"self"], (@{@"0": @NO, @"1": @YES, @"2": NSNull.null}));
    
    optManaged[@"intObj"] = (id)@{@"0": @2, @"1": @3, @"2": NSNull.null};
    XCTAssertEqualObjects([optManaged[@"intObj"] valueForKey:@"self"], (@{@"0": @2, @"1": @3, @"2": NSNull.null}));
    
    optManaged[@"floatObj"] = (id)@{@"0": @2.2f, @"1": @3.3f, @"2": NSNull.null};
    XCTAssertEqualObjects([optManaged[@"floatObj"] valueForKey:@"self"], (@{@"0": @2.2f, @"1": @3.3f, @"2": NSNull.null}));
    
    optManaged[@"doubleObj"] = (id)@{@"0": @2.2, @"1": @3.3, @"2": NSNull.null};
    XCTAssertEqualObjects([optManaged[@"doubleObj"] valueForKey:@"self"], (@{@"0": @2.2, @"1": @3.3, @"2": NSNull.null}));
    
    optManaged[@"stringObj"] = (id)@{@"0": @"a", @"1": @"b", @"2": NSNull.null};
    XCTAssertEqualObjects([optManaged[@"stringObj"] valueForKey:@"self"], (@{@"0": @"a", @"1": @"b", @"2": NSNull.null}));
    
    optManaged[@"dataObj"] = (id)@{@"0": data(1), @"1": data(2), @"2": NSNull.null};
    XCTAssertEqualObjects([optManaged[@"dataObj"] valueForKey:@"self"], (@{@"0": data(1), @"1": data(2), @"2": NSNull.null}));
    
    optManaged[@"dateObj"] = (id)@{@"0": date(1), @"1": date(2), @"2": NSNull.null};
    XCTAssertEqualObjects([optManaged[@"dateObj"] valueForKey:@"self"], (@{@"0": date(1), @"1": date(2), @"2": NSNull.null}));
    
    optManaged[@"decimalObj"] = (id)@{@"0": decimal128(2), @"1": decimal128(3), @"2": NSNull.null};
    XCTAssertEqualObjects([optManaged[@"decimalObj"] valueForKey:@"self"], (@{@"0": decimal128(2), @"1": decimal128(3), @"2": NSNull.null}));
    
    optManaged[@"objectIdObj"] = (id)@{@"0": objectId(1), @"1": objectId(2), @"2": NSNull.null};
    XCTAssertEqualObjects([optManaged[@"objectIdObj"] valueForKey:@"self"], (@{@"0": objectId(1), @"1": objectId(2), @"2": NSNull.null}));
    
    optManaged[@"uuidObj"] = (id)@{@"0": uuid(@"00000000-0000-0000-0000-000000000000"), @"1": uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"), @"2": NSNull.null};
    XCTAssertEqualObjects([optManaged[@"uuidObj"] valueForKey:@"self"], (@{@"0": uuid(@"00000000-0000-0000-0000-000000000000"), @"1": uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"), @"2": NSNull.null}));
    

    // Should not clear the array
    unmanaged[@"boolObj"] = unmanaged[@"boolObj"];
    XCTAssertEqualObjects([unmanaged[@"boolObj"] valueForKey:@"self"], (@{@"0": @NO, @"1": @YES}));
    
    unmanaged[@"intObj"] = unmanaged[@"intObj"];
    XCTAssertEqualObjects([unmanaged[@"intObj"] valueForKey:@"self"], (@{@"0": @2, @"1": @3}));
    
    unmanaged[@"floatObj"] = unmanaged[@"floatObj"];
    XCTAssertEqualObjects([unmanaged[@"floatObj"] valueForKey:@"self"], (@{@"0": @2.2f, @"1": @3.3f}));
    
    unmanaged[@"doubleObj"] = unmanaged[@"doubleObj"];
    XCTAssertEqualObjects([unmanaged[@"doubleObj"] valueForKey:@"self"], (@{@"0": @2.2, @"1": @3.3}));
    
    unmanaged[@"stringObj"] = unmanaged[@"stringObj"];
    XCTAssertEqualObjects([unmanaged[@"stringObj"] valueForKey:@"self"], (@{@"0": @"a", @"1": @"b"}));
    
    unmanaged[@"dataObj"] = unmanaged[@"dataObj"];
    XCTAssertEqualObjects([unmanaged[@"dataObj"] valueForKey:@"self"], (@{@"0": data(1), @"1": data(2)}));
    
    unmanaged[@"dateObj"] = unmanaged[@"dateObj"];
    XCTAssertEqualObjects([unmanaged[@"dateObj"] valueForKey:@"self"], (@{@"0": date(1), @"1": date(2)}));
    
    unmanaged[@"decimalObj"] = unmanaged[@"decimalObj"];
    XCTAssertEqualObjects([unmanaged[@"decimalObj"] valueForKey:@"self"], (@{@"0": decimal128(2), @"1": decimal128(3)}));
    
    unmanaged[@"objectIdObj"] = unmanaged[@"objectIdObj"];
    XCTAssertEqualObjects([unmanaged[@"objectIdObj"] valueForKey:@"self"], (@{@"0": objectId(1), @"1": objectId(2)}));
    
    unmanaged[@"uuidObj"] = unmanaged[@"uuidObj"];
    XCTAssertEqualObjects([unmanaged[@"uuidObj"] valueForKey:@"self"], (@{@"0": uuid(@"00000000-0000-0000-0000-000000000000"), @"1": uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")}));
    
    optUnmanaged[@"boolObj"] = optUnmanaged[@"boolObj"];
    XCTAssertEqualObjects([optUnmanaged[@"boolObj"] valueForKey:@"self"], (@{@"0": @NO, @"1": @YES, @"2": NSNull.null}));
    
    optUnmanaged[@"intObj"] = optUnmanaged[@"intObj"];
    XCTAssertEqualObjects([optUnmanaged[@"intObj"] valueForKey:@"self"], (@{@"0": @2, @"1": @3, @"2": NSNull.null}));
    
    optUnmanaged[@"floatObj"] = optUnmanaged[@"floatObj"];
    XCTAssertEqualObjects([optUnmanaged[@"floatObj"] valueForKey:@"self"], (@{@"0": @2.2f, @"1": @3.3f, @"2": NSNull.null}));
    
    optUnmanaged[@"doubleObj"] = optUnmanaged[@"doubleObj"];
    XCTAssertEqualObjects([optUnmanaged[@"doubleObj"] valueForKey:@"self"], (@{@"0": @2.2, @"1": @3.3, @"2": NSNull.null}));
    
    optUnmanaged[@"stringObj"] = optUnmanaged[@"stringObj"];
    XCTAssertEqualObjects([optUnmanaged[@"stringObj"] valueForKey:@"self"], (@{@"0": @"a", @"1": @"b", @"2": NSNull.null}));
    
    optUnmanaged[@"dataObj"] = optUnmanaged[@"dataObj"];
    XCTAssertEqualObjects([optUnmanaged[@"dataObj"] valueForKey:@"self"], (@{@"0": data(1), @"1": data(2), @"2": NSNull.null}));
    
    optUnmanaged[@"dateObj"] = optUnmanaged[@"dateObj"];
    XCTAssertEqualObjects([optUnmanaged[@"dateObj"] valueForKey:@"self"], (@{@"0": date(1), @"1": date(2), @"2": NSNull.null}));
    
    optUnmanaged[@"decimalObj"] = optUnmanaged[@"decimalObj"];
    XCTAssertEqualObjects([optUnmanaged[@"decimalObj"] valueForKey:@"self"], (@{@"0": decimal128(2), @"1": decimal128(3), @"2": NSNull.null}));
    
    optUnmanaged[@"objectIdObj"] = optUnmanaged[@"objectIdObj"];
    XCTAssertEqualObjects([optUnmanaged[@"objectIdObj"] valueForKey:@"self"], (@{@"0": objectId(1), @"1": objectId(2), @"2": NSNull.null}));
    
    optUnmanaged[@"uuidObj"] = optUnmanaged[@"uuidObj"];
    XCTAssertEqualObjects([optUnmanaged[@"uuidObj"] valueForKey:@"self"], (@{@"0": uuid(@"00000000-0000-0000-0000-000000000000"), @"1": uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"), @"2": NSNull.null}));
    
    managed[@"boolObj"] = managed[@"boolObj"];
    XCTAssertEqualObjects([managed[@"boolObj"] valueForKey:@"self"], (@{@"0": @NO, @"1": @YES}));
    
    managed[@"intObj"] = managed[@"intObj"];
    XCTAssertEqualObjects([managed[@"intObj"] valueForKey:@"self"], (@{@"0": @2, @"1": @3}));
    
    managed[@"floatObj"] = managed[@"floatObj"];
    XCTAssertEqualObjects([managed[@"floatObj"] valueForKey:@"self"], (@{@"0": @2.2f, @"1": @3.3f}));
    
    managed[@"doubleObj"] = managed[@"doubleObj"];
    XCTAssertEqualObjects([managed[@"doubleObj"] valueForKey:@"self"], (@{@"0": @2.2, @"1": @3.3}));
    
    managed[@"stringObj"] = managed[@"stringObj"];
    XCTAssertEqualObjects([managed[@"stringObj"] valueForKey:@"self"], (@{@"0": @"a", @"1": @"b"}));
    
    managed[@"dataObj"] = managed[@"dataObj"];
    XCTAssertEqualObjects([managed[@"dataObj"] valueForKey:@"self"], (@{@"0": data(1), @"1": data(2)}));
    
    managed[@"dateObj"] = managed[@"dateObj"];
    XCTAssertEqualObjects([managed[@"dateObj"] valueForKey:@"self"], (@{@"0": date(1), @"1": date(2)}));
    
    managed[@"decimalObj"] = managed[@"decimalObj"];
    XCTAssertEqualObjects([managed[@"decimalObj"] valueForKey:@"self"], (@{@"0": decimal128(2), @"1": decimal128(3)}));
    
    managed[@"objectIdObj"] = managed[@"objectIdObj"];
    XCTAssertEqualObjects([managed[@"objectIdObj"] valueForKey:@"self"], (@{@"0": objectId(1), @"1": objectId(2)}));
    
    managed[@"uuidObj"] = managed[@"uuidObj"];
    XCTAssertEqualObjects([managed[@"uuidObj"] valueForKey:@"self"], (@{@"0": uuid(@"00000000-0000-0000-0000-000000000000"), @"1": uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")}));
    
    optManaged[@"boolObj"] = optManaged[@"boolObj"];
    XCTAssertEqualObjects([optManaged[@"boolObj"] valueForKey:@"self"], (@{@"0": @NO, @"1": @YES, @"2": NSNull.null}));
    
    optManaged[@"intObj"] = optManaged[@"intObj"];
    XCTAssertEqualObjects([optManaged[@"intObj"] valueForKey:@"self"], (@{@"0": @2, @"1": @3, @"2": NSNull.null}));
    
    optManaged[@"floatObj"] = optManaged[@"floatObj"];
    XCTAssertEqualObjects([optManaged[@"floatObj"] valueForKey:@"self"], (@{@"0": @2.2f, @"1": @3.3f, @"2": NSNull.null}));
    
    optManaged[@"doubleObj"] = optManaged[@"doubleObj"];
    XCTAssertEqualObjects([optManaged[@"doubleObj"] valueForKey:@"self"], (@{@"0": @2.2, @"1": @3.3, @"2": NSNull.null}));
    
    optManaged[@"stringObj"] = optManaged[@"stringObj"];
    XCTAssertEqualObjects([optManaged[@"stringObj"] valueForKey:@"self"], (@{@"0": @"a", @"1": @"b", @"2": NSNull.null}));
    
    optManaged[@"dataObj"] = optManaged[@"dataObj"];
    XCTAssertEqualObjects([optManaged[@"dataObj"] valueForKey:@"self"], (@{@"0": data(1), @"1": data(2), @"2": NSNull.null}));
    
    optManaged[@"dateObj"] = optManaged[@"dateObj"];
    XCTAssertEqualObjects([optManaged[@"dateObj"] valueForKey:@"self"], (@{@"0": date(1), @"1": date(2), @"2": NSNull.null}));
    
    optManaged[@"decimalObj"] = optManaged[@"decimalObj"];
    XCTAssertEqualObjects([optManaged[@"decimalObj"] valueForKey:@"self"], (@{@"0": decimal128(2), @"1": decimal128(3), @"2": NSNull.null}));
    
    optManaged[@"objectIdObj"] = optManaged[@"objectIdObj"];
    XCTAssertEqualObjects([optManaged[@"objectIdObj"] valueForKey:@"self"], (@{@"0": objectId(1), @"1": objectId(2), @"2": NSNull.null}));
    
    optManaged[@"uuidObj"] = optManaged[@"uuidObj"];
    XCTAssertEqualObjects([optManaged[@"uuidObj"] valueForKey:@"self"], (@{@"0": uuid(@"00000000-0000-0000-0000-000000000000"), @"1": uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"), @"2": NSNull.null}));
    

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
            [dictionary setObject:@"testKey" forKey:@0];
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
    }];
    [LinkToAllPrimitiveDictionaries createInRealm:realm withValue:@[obj]];
    obj = [AllOptionalPrimitiveDictionaries createInRealm:realm withValue:@{
    }];
    [LinkToAllOptionalPrimitiveDictionaries createInRealm:realm withValue:@[obj]];
}

- (void)testQueryBasicOperators {
    [realm deleteAllObjects];


    [self createObjectWithValueIndex:0];


    [self createObjectWithValueIndex:1];


}

- (void)testQueryBetween {
    [realm deleteAllObjects];



    [self createObjectWithValueIndex:0];

}

- (void)testQueryIn {
    [realm deleteAllObjects];


    [self createObjectWithValueIndex:0];

}

- (void)testQueryCount {
    [realm deleteAllObjects];

    [AllPrimitiveDictionaries createInRealm:realm withValue:@{
    }];
    [AllOptionalPrimitiveDictionaries createInRealm:realm withValue:@{
    }];
    [AllPrimitiveDictionaries createInRealm:realm withValue:@{
    }];
    [AllOptionalPrimitiveDictionaries createInRealm:realm withValue:@{
    }];
    [AllPrimitiveDictionaries createInRealm:realm withValue:@{
    }];
    [AllOptionalPrimitiveDictionaries createInRealm:realm withValue:@{
    }];

    for (unsigned int i = 0; i < 3; ++i) {
    }
}

- (void)testQuerySum {
    [realm deleteAllObjects];



    [AllPrimitiveDictionaries createInRealm:realm withValue:@{
    }];
    [AllOptionalPrimitiveDictionaries createInRealm:realm withValue:@{
    }];
    [AllPrimitiveDictionaries createInRealm:realm withValue:@{
    }];
    [AllOptionalPrimitiveDictionaries createInRealm:realm withValue:@{
    }];
    [AllPrimitiveDictionaries createInRealm:realm withValue:@{
    }];
    [AllOptionalPrimitiveDictionaries createInRealm:realm withValue:@{
    }];
    [AllPrimitiveDictionaries createInRealm:realm withValue:@{
    }];
    [AllOptionalPrimitiveDictionaries createInRealm:realm withValue:@{
    }];

}

- (void)testQueryAverage {
    [realm deleteAllObjects];



    [AllPrimitiveDictionaries createInRealm:realm withValue:@{
    }];
    [AllOptionalPrimitiveDictionaries createInRealm:realm withValue:@{
    }];
    [AllPrimitiveDictionaries createInRealm:realm withValue:@{
    }];
    [AllOptionalPrimitiveDictionaries createInRealm:realm withValue:@{
    }];
    [AllPrimitiveDictionaries createInRealm:realm withValue:@{
    }];
    [AllOptionalPrimitiveDictionaries createInRealm:realm withValue:@{
    }];
    [AllPrimitiveDictionaries createInRealm:realm withValue:@{
    }];
    [AllOptionalPrimitiveDictionaries createInRealm:realm withValue:@{
    }];

}

- (void)testQueryMin {
    [realm deleteAllObjects];


    // No objects, so count is zero

    [AllPrimitiveDictionaries createInRealm:realm withValue:@{}];
    [AllOptionalPrimitiveDictionaries createInRealm:realm withValue:@{}];

    // Only empty arrays, so count is zero


    [self createObjectWithValueIndex:0];

    // One object where v0 is min and zero with v1

    [self createObjectWithValueIndex:1];

    // One object where v0 is min and one with v1

    [AllPrimitiveDictionaries createInRealm:realm withValue:@{
    }];
    [AllOptionalPrimitiveDictionaries createInRealm:realm withValue:@{
    }];

    // New object with both v0 and v1 matches v0 but not v1
}

- (void)testQueryMax {
    [realm deleteAllObjects];


    // No objects, so count is zero

    [AllPrimitiveDictionaries createInRealm:realm withValue:@{}];
    [AllOptionalPrimitiveDictionaries createInRealm:realm withValue:@{}];

    // Only empty arrays, so count is zero


    [self createObjectWithValueIndex:0];

    // One object where v0 is min and zero with v1

    [self createObjectWithValueIndex:1];

    // One object where v0 is min and one with v1

    [AllPrimitiveDictionaries createInRealm:realm withValue:@{
    }];
    [AllOptionalPrimitiveDictionaries createInRealm:realm withValue:@{
    }];

    // New object with both v0 and v1 matches v1 but not v0
}

- (void)testQueryBasicOperatorsOverLink {
    [realm deleteAllObjects];


    [self createObjectWithValueIndex:0];


    [self createObjectWithValueIndex:1];


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
        query = [NSString stringWithFormat:@"ANY link.stringObj %@ %%@", operator];

        query = [NSString stringWithFormat:@"ANY dataObj %@ %%@", operator];
        query = [NSString stringWithFormat:@"ANY link.dataObj %@ %%@", operator];
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
