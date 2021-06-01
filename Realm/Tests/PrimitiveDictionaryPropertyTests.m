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
        unmanaged.boolObj,
        optUnmanaged.boolObj,
        managed.boolObj,
        optManaged.boolObj,
        unmanaged.intObj,
        optUnmanaged.intObj,
        managed.intObj,
        optManaged.intObj,
        unmanaged.stringObj,
        optUnmanaged.stringObj,
        managed.stringObj,
        optManaged.stringObj,
        unmanaged.dateObj,
        optUnmanaged.dateObj,
        managed.dateObj,
        optManaged.dateObj,
        unmanaged.floatObj,
        optUnmanaged.floatObj,
        managed.floatObj,
        optManaged.floatObj,
        unmanaged.doubleObj,
        optUnmanaged.doubleObj,
        managed.doubleObj,
        optManaged.doubleObj,
        unmanaged.dataObj,
        optUnmanaged.dataObj,
        managed.dataObj,
        optManaged.dataObj,
        unmanaged.decimalObj,
        optUnmanaged.decimalObj,
        managed.decimalObj,
        optManaged.decimalObj,
        unmanaged.objectIdObj,
        optUnmanaged.objectIdObj,
        managed.objectIdObj,
        optManaged.objectIdObj,
        unmanaged.uuidObj,
        optUnmanaged.uuidObj,
        managed.uuidObj,
        optManaged.uuidObj,
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
    ];
}

- (void)tearDown {
    if (realm.inWriteTransaction) {
        [realm cancelWriteTransaction];
    }
}

- (void)addObjects {
    [unmanaged.boolObj addEntriesFromDictionary:@{ @"key1": @NO, @"key2": @YES }];
    [optUnmanaged.boolObj addEntriesFromDictionary:@{ @"key1": @NO, @"key2": NSNull.null }];
    [managed.boolObj addEntriesFromDictionary:@{ @"key1": @NO, @"key2": @YES }];
    [optManaged.boolObj addEntriesFromDictionary:@{ @"key1": @NO, @"key2": NSNull.null }];
    [unmanaged.intObj addEntriesFromDictionary:@{ @"key1": @2, @"key2": @3 }];
    [optUnmanaged.intObj addEntriesFromDictionary:@{ @"key1": @2, @"key2": NSNull.null }];
    [managed.intObj addEntriesFromDictionary:@{ @"key1": @2, @"key2": @3 }];
    [optManaged.intObj addEntriesFromDictionary:@{ @"key1": @2, @"key2": NSNull.null }];
    [unmanaged.stringObj addEntriesFromDictionary:@{ @"key1": @"bar", @"key2": @"foo" }];
    [optUnmanaged.stringObj addEntriesFromDictionary:@{ @"key1": @"bar", @"key2": NSNull.null }];
    [managed.stringObj addEntriesFromDictionary:@{ @"key1": @"bar", @"key2": @"foo" }];
    [optManaged.stringObj addEntriesFromDictionary:@{ @"key1": @"bar", @"key2": NSNull.null }];
    [unmanaged.dateObj addEntriesFromDictionary:@{ @"key1": date(1), @"key2": date(2) }];
    [optUnmanaged.dateObj addEntriesFromDictionary:@{ @"key1": date(1), @"key2": NSNull.null }];
    [managed.dateObj addEntriesFromDictionary:@{ @"key1": date(1), @"key2": date(2) }];
    [optManaged.dateObj addEntriesFromDictionary:@{ @"key1": date(1), @"key2": NSNull.null }];
    [unmanaged.floatObj addEntriesFromDictionary:@{ @"key1": @2.2f, @"key2": @3.3f }];
    [optUnmanaged.floatObj addEntriesFromDictionary:@{ @"key1": @2.2f, @"key2": NSNull.null }];
    [managed.floatObj addEntriesFromDictionary:@{ @"key1": @2.2f, @"key2": @3.3f }];
    [optManaged.floatObj addEntriesFromDictionary:@{ @"key1": @2.2f, @"key2": NSNull.null }];
    [unmanaged.doubleObj addEntriesFromDictionary:@{ @"key1": @2.2, @"key2": @3.3 }];
    [optUnmanaged.doubleObj addEntriesFromDictionary:@{ @"key1": @2.2, @"key2": NSNull.null }];
    [managed.doubleObj addEntriesFromDictionary:@{ @"key1": @2.2, @"key2": @3.3 }];
    [optManaged.doubleObj addEntriesFromDictionary:@{ @"key1": @2.2, @"key2": NSNull.null }];
    [unmanaged.dataObj addEntriesFromDictionary:@{ @"key1": data(1), @"key2": data(2) }];
    [optUnmanaged.dataObj addEntriesFromDictionary:@{ @"key1": data(1), @"key2": NSNull.null }];
    [managed.dataObj addEntriesFromDictionary:@{ @"key1": data(1), @"key2": data(2) }];
    [optManaged.dataObj addEntriesFromDictionary:@{ @"key1": data(1), @"key2": NSNull.null }];
    [unmanaged.decimalObj addEntriesFromDictionary:@{ @"key1": decimal128(2), @"key2": decimal128(3) }];
    [optUnmanaged.decimalObj addEntriesFromDictionary:@{ @"key1": decimal128(2), @"key2": NSNull.null }];
    [managed.decimalObj addEntriesFromDictionary:@{ @"key1": decimal128(2), @"key2": decimal128(3) }];
    [optManaged.decimalObj addEntriesFromDictionary:@{ @"key1": decimal128(2), @"key2": NSNull.null }];
    [unmanaged.objectIdObj addEntriesFromDictionary:@{ @"key1": objectId(1), @"key2": objectId(2) }];
    [optUnmanaged.objectIdObj addEntriesFromDictionary:@{ @"key1": objectId(1), @"key2": NSNull.null }];
    [managed.objectIdObj addEntriesFromDictionary:@{ @"key1": objectId(1), @"key2": objectId(2) }];
    [optManaged.objectIdObj addEntriesFromDictionary:@{ @"key1": objectId(1), @"key2": NSNull.null }];
    [unmanaged.uuidObj addEntriesFromDictionary:@{ @"key1": uuid(@"00000000-0000-0000-0000-000000000000"), @"key2": uuid(@"137DECC8-B300-4954-A233-F89909F4FD89") }];
    [optUnmanaged.uuidObj addEntriesFromDictionary:@{ @"key1": uuid(@"00000000-0000-0000-0000-000000000000"), @"key2": NSNull.null }];
    [managed.uuidObj addEntriesFromDictionary:@{ @"key1": uuid(@"00000000-0000-0000-0000-000000000000"), @"key2": uuid(@"137DECC8-B300-4954-A233-F89909F4FD89") }];
    [optManaged.uuidObj addEntriesFromDictionary:@{ @"key1": uuid(@"00000000-0000-0000-0000-000000000000"), @"key2": NSNull.null }];
    [unmanaged.anyBoolObj addEntriesFromDictionary:@{ @"key1": @NO, @"key2": @YES }];
    [unmanaged.anyIntObj addEntriesFromDictionary:@{ @"key1": @2, @"key2": @3 }];
    [unmanaged.anyFloatObj addEntriesFromDictionary:@{ @"key1": @2.2f, @"key2": @3.3f }];
    [unmanaged.anyDoubleObj addEntriesFromDictionary:@{ @"key1": @2.2, @"key2": @3.3 }];
    [unmanaged.anyStringObj addEntriesFromDictionary:@{ @"key1": @"a", @"key2": @"b" }];
    [unmanaged.anyDataObj addEntriesFromDictionary:@{ @"key1": data(1), @"key2": data(2) }];
    [unmanaged.anyDateObj addEntriesFromDictionary:@{ @"key1": date(1), @"key2": date(2) }];
    [unmanaged.anyDecimalObj addEntriesFromDictionary:@{ @"key1": decimal128(2), @"key2": decimal128(3) }];
    [unmanaged.anyObjectIdObj addEntriesFromDictionary:@{ @"key1": objectId(1), @"key2": objectId(2) }];
    [unmanaged.anyUUIDObj addEntriesFromDictionary:@{ @"key1": uuid(@"00000000-0000-0000-0000-000000000000"), @"key2": uuid(@"137DECC8-B300-4954-A233-F89909F4FD89") }];
    [managed.anyBoolObj addEntriesFromDictionary:@{ @"key1": @NO, @"key2": @YES }];
    [managed.anyIntObj addEntriesFromDictionary:@{ @"key1": @2, @"key2": @3 }];
    [managed.anyFloatObj addEntriesFromDictionary:@{ @"key1": @2.2f, @"key2": @3.3f }];
    [managed.anyDoubleObj addEntriesFromDictionary:@{ @"key1": @2.2, @"key2": @3.3 }];
    [managed.anyStringObj addEntriesFromDictionary:@{ @"key1": @"a", @"key2": @"b" }];
    [managed.anyDataObj addEntriesFromDictionary:@{ @"key1": data(1), @"key2": data(2) }];
    [managed.anyDateObj addEntriesFromDictionary:@{ @"key1": date(1), @"key2": date(2) }];
    [managed.anyDecimalObj addEntriesFromDictionary:@{ @"key1": decimal128(2), @"key2": decimal128(3) }];
    [managed.anyObjectIdObj addEntriesFromDictionary:@{ @"key1": objectId(1), @"key2": objectId(2) }];
    [managed.anyUUIDObj addEntriesFromDictionary:@{ @"key1": uuid(@"00000000-0000-0000-0000-000000000000"), @"key2": uuid(@"137DECC8-B300-4954-A233-F89909F4FD89") }];
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
    RLMAssertThrowsWithReason([realm deleteObjects:unmanaged.boolObj], @"Cannot delete objects from RLMDictionary");
    RLMAssertThrowsWithReason([realm deleteObjects:optUnmanaged.boolObj], @"Cannot delete objects from RLMDictionary");
    RLMAssertThrowsWithReason([realm deleteObjects:unmanaged.intObj], @"Cannot delete objects from RLMDictionary");
    RLMAssertThrowsWithReason([realm deleteObjects:optUnmanaged.intObj], @"Cannot delete objects from RLMDictionary");
    RLMAssertThrowsWithReason([realm deleteObjects:unmanaged.stringObj], @"Cannot delete objects from RLMDictionary");
    RLMAssertThrowsWithReason([realm deleteObjects:optUnmanaged.stringObj], @"Cannot delete objects from RLMDictionary");
    RLMAssertThrowsWithReason([realm deleteObjects:unmanaged.dateObj], @"Cannot delete objects from RLMDictionary");
    RLMAssertThrowsWithReason([realm deleteObjects:optUnmanaged.dateObj], @"Cannot delete objects from RLMDictionary");
    RLMAssertThrowsWithReason([realm deleteObjects:unmanaged.floatObj], @"Cannot delete objects from RLMDictionary");
    RLMAssertThrowsWithReason([realm deleteObjects:optUnmanaged.floatObj], @"Cannot delete objects from RLMDictionary");
    RLMAssertThrowsWithReason([realm deleteObjects:unmanaged.doubleObj], @"Cannot delete objects from RLMDictionary");
    RLMAssertThrowsWithReason([realm deleteObjects:optUnmanaged.doubleObj], @"Cannot delete objects from RLMDictionary");
    RLMAssertThrowsWithReason([realm deleteObjects:unmanaged.dataObj], @"Cannot delete objects from RLMDictionary");
    RLMAssertThrowsWithReason([realm deleteObjects:optUnmanaged.dataObj], @"Cannot delete objects from RLMDictionary");
    RLMAssertThrowsWithReason([realm deleteObjects:unmanaged.decimalObj], @"Cannot delete objects from RLMDictionary");
    RLMAssertThrowsWithReason([realm deleteObjects:optUnmanaged.decimalObj], @"Cannot delete objects from RLMDictionary");
    RLMAssertThrowsWithReason([realm deleteObjects:unmanaged.objectIdObj], @"Cannot delete objects from RLMDictionary");
    RLMAssertThrowsWithReason([realm deleteObjects:optUnmanaged.objectIdObj], @"Cannot delete objects from RLMDictionary");
    RLMAssertThrowsWithReason([realm deleteObjects:unmanaged.uuidObj], @"Cannot delete objects from RLMDictionary");
    RLMAssertThrowsWithReason([realm deleteObjects:optUnmanaged.uuidObj], @"Cannot delete objects from RLMDictionary");
    RLMAssertThrowsWithReason([realm deleteObjects:unmanaged.anyBoolObj], @"Cannot delete objects from RLMDictionary");
    RLMAssertThrowsWithReason([realm deleteObjects:unmanaged.anyIntObj], @"Cannot delete objects from RLMDictionary");
    RLMAssertThrowsWithReason([realm deleteObjects:unmanaged.anyFloatObj], @"Cannot delete objects from RLMDictionary");
    RLMAssertThrowsWithReason([realm deleteObjects:unmanaged.anyDoubleObj], @"Cannot delete objects from RLMDictionary");
    RLMAssertThrowsWithReason([realm deleteObjects:unmanaged.anyStringObj], @"Cannot delete objects from RLMDictionary");
    RLMAssertThrowsWithReason([realm deleteObjects:unmanaged.anyDataObj], @"Cannot delete objects from RLMDictionary");
    RLMAssertThrowsWithReason([realm deleteObjects:unmanaged.anyDateObj], @"Cannot delete objects from RLMDictionary");
    RLMAssertThrowsWithReason([realm deleteObjects:unmanaged.anyDecimalObj], @"Cannot delete objects from RLMDictionary");
    RLMAssertThrowsWithReason([realm deleteObjects:unmanaged.anyObjectIdObj], @"Cannot delete objects from RLMDictionary");
    RLMAssertThrowsWithReason([realm deleteObjects:unmanaged.anyUUIDObj], @"Cannot delete objects from RLMDictionary");
    RLMAssertThrowsWithReason([realm deleteObjects:managed.boolObj], @"Cannot delete objects from RLMManagedDictionary<RLMString, bool>: only RLMObjects can be deleted.");
    RLMAssertThrowsWithReason([realm deleteObjects:optManaged.boolObj], @"Cannot delete objects from RLMManagedDictionary<RLMString, bool?>: only RLMObjects can be deleted.");
    RLMAssertThrowsWithReason([realm deleteObjects:managed.intObj], @"Cannot delete objects from RLMManagedDictionary<RLMString, int>: only RLMObjects can be deleted.");
    RLMAssertThrowsWithReason([realm deleteObjects:optManaged.intObj], @"Cannot delete objects from RLMManagedDictionary<RLMString, int?>: only RLMObjects can be deleted.");
    RLMAssertThrowsWithReason([realm deleteObjects:managed.stringObj], @"Cannot delete objects from RLMManagedDictionary<RLMString, string>: only RLMObjects can be deleted.");
    RLMAssertThrowsWithReason([realm deleteObjects:optManaged.stringObj], @"Cannot delete objects from RLMManagedDictionary<RLMString, string?>: only RLMObjects can be deleted.");
    RLMAssertThrowsWithReason([realm deleteObjects:managed.dateObj], @"Cannot delete objects from RLMManagedDictionary<RLMString, date>: only RLMObjects can be deleted.");
    RLMAssertThrowsWithReason([realm deleteObjects:optManaged.dateObj], @"Cannot delete objects from RLMManagedDictionary<RLMString, date?>: only RLMObjects can be deleted.");
    RLMAssertThrowsWithReason([realm deleteObjects:managed.anyBoolObj], @"Cannot delete objects from RLMManagedDictionary<RLMString, mixed>: only RLMObjects can be deleted.");
    RLMAssertThrowsWithReason([realm deleteObjects:managed.anyIntObj], @"Cannot delete objects from RLMManagedDictionary<RLMString, mixed>: only RLMObjects can be deleted.");
    RLMAssertThrowsWithReason([realm deleteObjects:managed.anyFloatObj], @"Cannot delete objects from RLMManagedDictionary<RLMString, mixed>: only RLMObjects can be deleted.");
    RLMAssertThrowsWithReason([realm deleteObjects:managed.anyDoubleObj], @"Cannot delete objects from RLMManagedDictionary<RLMString, mixed>: only RLMObjects can be deleted.");
    RLMAssertThrowsWithReason([realm deleteObjects:managed.anyStringObj], @"Cannot delete objects from RLMManagedDictionary<RLMString, mixed>: only RLMObjects can be deleted.");
    RLMAssertThrowsWithReason([realm deleteObjects:managed.anyDataObj], @"Cannot delete objects from RLMManagedDictionary<RLMString, mixed>: only RLMObjects can be deleted.");
    RLMAssertThrowsWithReason([realm deleteObjects:managed.anyDateObj], @"Cannot delete objects from RLMManagedDictionary<RLMString, mixed>: only RLMObjects can be deleted.");
    RLMAssertThrowsWithReason([realm deleteObjects:managed.anyDecimalObj], @"Cannot delete objects from RLMManagedDictionary<RLMString, mixed>: only RLMObjects can be deleted.");
    RLMAssertThrowsWithReason([realm deleteObjects:managed.anyUUIDObj], @"Cannot delete objects from RLMManagedDictionary<RLMString, mixed>: only RLMObjects can be deleted.");
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wnonnull"

- (void)testSetObject {
    // Managed non-optional
    XCTAssertNil(managed.boolObj[@"key1"]);
    XCTAssertNil(managed.intObj[@"key1"]);
    XCTAssertNil(managed.stringObj[@"key1"]);
    XCTAssertNil(managed.dateObj[@"key1"]);
    XCTAssertNil(managed.anyBoolObj[@"key1"]);
    XCTAssertNil(managed.anyIntObj[@"key1"]);
    XCTAssertNil(managed.anyFloatObj[@"key1"]);
    XCTAssertNil(managed.anyDoubleObj[@"key1"]);
    XCTAssertNil(managed.anyStringObj[@"key1"]);
    XCTAssertNil(managed.anyDataObj[@"key1"]);
    XCTAssertNil(managed.anyDateObj[@"key1"]);
    XCTAssertNil(managed.anyDecimalObj[@"key1"]);
    XCTAssertNil(managed.anyUUIDObj[@"key1"]);
    XCTAssertNoThrow(managed.boolObj[@"key1"] = @NO);
    XCTAssertNoThrow(managed.intObj[@"key1"] = @2);
    XCTAssertNoThrow(managed.stringObj[@"key1"] = @"bar");
    XCTAssertNoThrow(managed.dateObj[@"key1"] = date(1));
    XCTAssertNoThrow(managed.anyBoolObj[@"key1"] = @NO);
    XCTAssertNoThrow(managed.anyIntObj[@"key1"] = @2);
    XCTAssertNoThrow(managed.anyFloatObj[@"key1"] = @2.2f);
    XCTAssertNoThrow(managed.anyDoubleObj[@"key1"] = @2.2);
    XCTAssertNoThrow(managed.anyStringObj[@"key1"] = @"a");
    XCTAssertNoThrow(managed.anyDataObj[@"key1"] = data(1));
    XCTAssertNoThrow(managed.anyDateObj[@"key1"] = date(1));
    XCTAssertNoThrow(managed.anyDecimalObj[@"key1"] = decimal128(2));
    XCTAssertNoThrow(managed.anyUUIDObj[@"key1"] = uuid(@"00000000-0000-0000-0000-000000000000"));
    XCTAssertEqualObjects(managed.boolObj[@"key1"], @NO);
    XCTAssertEqualObjects(managed.intObj[@"key1"], @2);
    XCTAssertEqualObjects(managed.stringObj[@"key1"], @"bar");
    XCTAssertEqualObjects(managed.dateObj[@"key1"], date(1));
    XCTAssertEqualObjects(managed.anyBoolObj[@"key1"], @NO);
    XCTAssertEqualObjects(managed.anyIntObj[@"key1"], @2);
    XCTAssertEqualObjects(managed.anyFloatObj[@"key1"], @2.2f);
    XCTAssertEqualObjects(managed.anyDoubleObj[@"key1"], @2.2);
    XCTAssertEqualObjects(managed.anyStringObj[@"key1"], @"a");
    XCTAssertEqualObjects(managed.anyDataObj[@"key1"], data(1));
    XCTAssertEqualObjects(managed.anyDateObj[@"key1"], date(1));
    XCTAssertEqualObjects(managed.anyDecimalObj[@"key1"], decimal128(2));
    XCTAssertEqualObjects(managed.anyUUIDObj[@"key1"], uuid(@"00000000-0000-0000-0000-000000000000"));
    RLMAssertThrowsWithReason(managed.boolObj[@"key1"] = (id)NSNull.null, @"Invalid value '<null>' of type 'NSNull' for expected type 'bool'.");
    RLMAssertThrowsWithReason(managed.intObj[@"key1"] = (id)NSNull.null, @"Invalid value '<null>' of type 'NSNull' for expected type 'int'.");
    RLMAssertThrowsWithReason(managed.stringObj[@"key1"] = (id)NSNull.null, @"Invalid value '<null>' of type 'NSNull' for expected type 'string'.");
    RLMAssertThrowsWithReason(managed.dateObj[@"key1"] = (id)NSNull.null, @"Invalid value '<null>' of type 'NSNull' for expected type 'date'.");
    XCTAssertNoThrow(managed.boolObj[@"key1"] = nil);
    XCTAssertNoThrow(managed.intObj[@"key1"] = nil);
    XCTAssertNoThrow(managed.stringObj[@"key1"] = nil);
    XCTAssertNoThrow(managed.dateObj[@"key1"] = nil);
    XCTAssertNoThrow(managed.anyBoolObj[@"key1"] = nil);
    XCTAssertNoThrow(managed.anyIntObj[@"key1"] = nil);
    XCTAssertNoThrow(managed.anyFloatObj[@"key1"] = nil);
    XCTAssertNoThrow(managed.anyDoubleObj[@"key1"] = nil);
    XCTAssertNoThrow(managed.anyStringObj[@"key1"] = nil);
    XCTAssertNoThrow(managed.anyDataObj[@"key1"] = nil);
    XCTAssertNoThrow(managed.anyDateObj[@"key1"] = nil);
    XCTAssertNoThrow(managed.anyDecimalObj[@"key1"] = nil);
    XCTAssertNoThrow(managed.anyUUIDObj[@"key1"] = nil);
    XCTAssertNil(managed.boolObj[@"key1"]);
    XCTAssertNil(managed.intObj[@"key1"]);
    XCTAssertNil(managed.stringObj[@"key1"]);
    XCTAssertNil(managed.dateObj[@"key1"]);
    XCTAssertNil(managed.anyBoolObj[@"key1"]);
    XCTAssertNil(managed.anyIntObj[@"key1"]);
    XCTAssertNil(managed.anyFloatObj[@"key1"]);
    XCTAssertNil(managed.anyDoubleObj[@"key1"]);
    XCTAssertNil(managed.anyStringObj[@"key1"]);
    XCTAssertNil(managed.anyDataObj[@"key1"]);
    XCTAssertNil(managed.anyDateObj[@"key1"]);
    XCTAssertNil(managed.anyDecimalObj[@"key1"]);
    XCTAssertNil(managed.anyUUIDObj[@"key1"]);

    // Managed optional
    XCTAssertNil(optManaged.boolObj[@"key1"]);
    XCTAssertNil(optManaged.intObj[@"key1"]);
    XCTAssertNil(optManaged.stringObj[@"key1"]);
    XCTAssertNil(optManaged.dateObj[@"key1"]);
    XCTAssertNoThrow(optManaged.boolObj[@"key1"] = @NO);
    XCTAssertNoThrow(optManaged.intObj[@"key1"] = @2);
    XCTAssertNoThrow(optManaged.stringObj[@"key1"] = @"bar");
    XCTAssertNoThrow(optManaged.dateObj[@"key1"] = date(1));
    XCTAssertEqualObjects(optManaged.boolObj[@"key1"], @NO);
    XCTAssertEqualObjects(optManaged.intObj[@"key1"], @2);
    XCTAssertEqualObjects(optManaged.stringObj[@"key1"], @"bar");
    XCTAssertEqualObjects(optManaged.dateObj[@"key1"], date(1));
    XCTAssertNoThrow(optManaged.boolObj[@"key1"] = (id)NSNull.null);
    XCTAssertNoThrow(optManaged.intObj[@"key1"] = (id)NSNull.null);
    XCTAssertNoThrow(optManaged.stringObj[@"key1"] = (id)NSNull.null);
    XCTAssertNoThrow(optManaged.dateObj[@"key1"] = (id)NSNull.null);
    XCTAssertEqualObjects(optManaged.boolObj[@"key1"], (id)NSNull.null);
    XCTAssertEqualObjects(optManaged.intObj[@"key1"], (id)NSNull.null);
    XCTAssertEqualObjects(optManaged.stringObj[@"key1"], (id)NSNull.null);
    XCTAssertEqualObjects(optManaged.dateObj[@"key1"], (id)NSNull.null);
    XCTAssertNoThrow(optManaged.boolObj[@"key1"] = nil);
    XCTAssertNoThrow(optManaged.intObj[@"key1"] = nil);
    XCTAssertNoThrow(optManaged.stringObj[@"key1"] = nil);
    XCTAssertNoThrow(optManaged.dateObj[@"key1"] = nil);
    XCTAssertNil(optManaged.boolObj[@"key1"]);
    XCTAssertNil(optManaged.intObj[@"key1"]);
    XCTAssertNil(optManaged.stringObj[@"key1"]);
    XCTAssertNil(optManaged.dateObj[@"key1"]);

    // Unmanaged non-optional
    XCTAssertNil(unmanaged.boolObj[@"key1"]);
    XCTAssertNil(unmanaged.intObj[@"key1"]);
    XCTAssertNil(unmanaged.stringObj[@"key1"]);
    XCTAssertNil(unmanaged.dateObj[@"key1"]);
    XCTAssertNil(unmanaged.floatObj[@"key1"]);
    XCTAssertNil(unmanaged.doubleObj[@"key1"]);
    XCTAssertNil(unmanaged.dataObj[@"key1"]);
    XCTAssertNil(unmanaged.decimalObj[@"key1"]);
    XCTAssertNil(unmanaged.objectIdObj[@"key1"]);
    XCTAssertNil(unmanaged.uuidObj[@"key1"]);
    XCTAssertNil(unmanaged.anyBoolObj[@"key1"]);
    XCTAssertNil(unmanaged.anyIntObj[@"key1"]);
    XCTAssertNil(unmanaged.anyFloatObj[@"key1"]);
    XCTAssertNil(unmanaged.anyDoubleObj[@"key1"]);
    XCTAssertNil(unmanaged.anyStringObj[@"key1"]);
    XCTAssertNil(unmanaged.anyDataObj[@"key1"]);
    XCTAssertNil(unmanaged.anyDateObj[@"key1"]);
    XCTAssertNil(unmanaged.anyDecimalObj[@"key1"]);
    XCTAssertNil(unmanaged.anyObjectIdObj[@"key1"]);
    XCTAssertNil(unmanaged.anyUUIDObj[@"key1"]);
    XCTAssertNoThrow(unmanaged.boolObj[@"key1"] = @NO);
    XCTAssertNoThrow(unmanaged.intObj[@"key1"] = @2);
    XCTAssertNoThrow(unmanaged.stringObj[@"key1"] = @"bar");
    XCTAssertNoThrow(unmanaged.dateObj[@"key1"] = date(1));
    XCTAssertNoThrow(unmanaged.floatObj[@"key1"] = @2.2f);
    XCTAssertNoThrow(unmanaged.doubleObj[@"key1"] = @2.2);
    XCTAssertNoThrow(unmanaged.dataObj[@"key1"] = data(1));
    XCTAssertNoThrow(unmanaged.decimalObj[@"key1"] = decimal128(2));
    XCTAssertNoThrow(unmanaged.objectIdObj[@"key1"] = objectId(1));
    XCTAssertNoThrow(unmanaged.uuidObj[@"key1"] = uuid(@"00000000-0000-0000-0000-000000000000"));
    XCTAssertNoThrow(unmanaged.anyBoolObj[@"key1"] = @NO);
    XCTAssertNoThrow(unmanaged.anyIntObj[@"key1"] = @2);
    XCTAssertNoThrow(unmanaged.anyFloatObj[@"key1"] = @2.2f);
    XCTAssertNoThrow(unmanaged.anyDoubleObj[@"key1"] = @2.2);
    XCTAssertNoThrow(unmanaged.anyStringObj[@"key1"] = @"a");
    XCTAssertNoThrow(unmanaged.anyDataObj[@"key1"] = data(1));
    XCTAssertNoThrow(unmanaged.anyDateObj[@"key1"] = date(1));
    XCTAssertNoThrow(unmanaged.anyDecimalObj[@"key1"] = decimal128(2));
    XCTAssertNoThrow(unmanaged.anyObjectIdObj[@"key1"] = objectId(1));
    XCTAssertNoThrow(unmanaged.anyUUIDObj[@"key1"] = uuid(@"00000000-0000-0000-0000-000000000000"));
    XCTAssertEqualObjects(unmanaged.boolObj[@"key1"], @NO);
    XCTAssertEqualObjects(unmanaged.intObj[@"key1"], @2);
    XCTAssertEqualObjects(unmanaged.stringObj[@"key1"], @"bar");
    XCTAssertEqualObjects(unmanaged.dateObj[@"key1"], date(1));
    XCTAssertEqualObjects(unmanaged.floatObj[@"key1"], @2.2f);
    XCTAssertEqualObjects(unmanaged.doubleObj[@"key1"], @2.2);
    XCTAssertEqualObjects(unmanaged.dataObj[@"key1"], data(1));
    XCTAssertEqualObjects(unmanaged.decimalObj[@"key1"], decimal128(2));
    XCTAssertEqualObjects(unmanaged.objectIdObj[@"key1"], objectId(1));
    XCTAssertEqualObjects(unmanaged.uuidObj[@"key1"], uuid(@"00000000-0000-0000-0000-000000000000"));
    XCTAssertEqualObjects(unmanaged.anyBoolObj[@"key1"], @NO);
    XCTAssertEqualObjects(unmanaged.anyIntObj[@"key1"], @2);
    XCTAssertEqualObjects(unmanaged.anyFloatObj[@"key1"], @2.2f);
    XCTAssertEqualObjects(unmanaged.anyDoubleObj[@"key1"], @2.2);
    XCTAssertEqualObjects(unmanaged.anyStringObj[@"key1"], @"a");
    XCTAssertEqualObjects(unmanaged.anyDataObj[@"key1"], data(1));
    XCTAssertEqualObjects(unmanaged.anyDateObj[@"key1"], date(1));
    XCTAssertEqualObjects(unmanaged.anyDecimalObj[@"key1"], decimal128(2));
    XCTAssertEqualObjects(unmanaged.anyObjectIdObj[@"key1"], objectId(1));
    XCTAssertEqualObjects(unmanaged.anyUUIDObj[@"key1"], uuid(@"00000000-0000-0000-0000-000000000000"));
    RLMAssertThrowsWithReason(unmanaged.boolObj[@"key1"] = (id)NSNull.null, @"Invalid value '<null>' of type 'NSNull' for expected type 'bool'.");
    RLMAssertThrowsWithReason(unmanaged.intObj[@"key1"] = (id)NSNull.null, @"Invalid value '<null>' of type 'NSNull' for expected type 'int'.");
    RLMAssertThrowsWithReason(unmanaged.stringObj[@"key1"] = (id)NSNull.null, @"Invalid value '<null>' of type 'NSNull' for expected type 'string'.");
    RLMAssertThrowsWithReason(unmanaged.dateObj[@"key1"] = (id)NSNull.null, @"Invalid value '<null>' of type 'NSNull' for expected type 'date'.");
    RLMAssertThrowsWithReason(unmanaged.floatObj[@"key1"] = (id)NSNull.null, @"Invalid value '<null>' of type 'NSNull' for expected type 'float'.");
    RLMAssertThrowsWithReason(unmanaged.doubleObj[@"key1"] = (id)NSNull.null, @"Invalid value '<null>' of type 'NSNull' for expected type 'double'.");
    RLMAssertThrowsWithReason(unmanaged.dataObj[@"key1"] = (id)NSNull.null, @"Invalid value '<null>' of type 'NSNull' for expected type 'data'.");
    RLMAssertThrowsWithReason(unmanaged.decimalObj[@"key1"] = (id)NSNull.null, @"Invalid value '<null>' of type 'NSNull' for expected type 'decimal128'.");
    RLMAssertThrowsWithReason(unmanaged.objectIdObj[@"key1"] = (id)NSNull.null, @"Invalid value '<null>' of type 'NSNull' for expected type 'object id'.");
    RLMAssertThrowsWithReason(unmanaged.uuidObj[@"key1"] = (id)NSNull.null, @"Invalid value '<null>' of type 'NSNull' for expected type 'uuid'.");
    XCTAssertNoThrow(unmanaged.boolObj[@"key1"] = nil);
    XCTAssertNoThrow(unmanaged.intObj[@"key1"] = nil);
    XCTAssertNoThrow(unmanaged.stringObj[@"key1"] = nil);
    XCTAssertNoThrow(unmanaged.dateObj[@"key1"] = nil);
    XCTAssertNoThrow(unmanaged.floatObj[@"key1"] = nil);
    XCTAssertNoThrow(unmanaged.doubleObj[@"key1"] = nil);
    XCTAssertNoThrow(unmanaged.dataObj[@"key1"] = nil);
    XCTAssertNoThrow(unmanaged.decimalObj[@"key1"] = nil);
    XCTAssertNoThrow(unmanaged.objectIdObj[@"key1"] = nil);
    XCTAssertNoThrow(unmanaged.uuidObj[@"key1"] = nil);
    XCTAssertNoThrow(unmanaged.anyBoolObj[@"key1"] = nil);
    XCTAssertNoThrow(unmanaged.anyIntObj[@"key1"] = nil);
    XCTAssertNoThrow(unmanaged.anyFloatObj[@"key1"] = nil);
    XCTAssertNoThrow(unmanaged.anyDoubleObj[@"key1"] = nil);
    XCTAssertNoThrow(unmanaged.anyStringObj[@"key1"] = nil);
    XCTAssertNoThrow(unmanaged.anyDataObj[@"key1"] = nil);
    XCTAssertNoThrow(unmanaged.anyDateObj[@"key1"] = nil);
    XCTAssertNoThrow(unmanaged.anyDecimalObj[@"key1"] = nil);
    XCTAssertNoThrow(unmanaged.anyObjectIdObj[@"key1"] = nil);
    XCTAssertNoThrow(unmanaged.anyUUIDObj[@"key1"] = nil);
    XCTAssertNil(unmanaged.boolObj[@"key1"]);
    XCTAssertNil(unmanaged.intObj[@"key1"]);
    XCTAssertNil(unmanaged.stringObj[@"key1"]);
    XCTAssertNil(unmanaged.dateObj[@"key1"]);
    XCTAssertNil(unmanaged.floatObj[@"key1"]);
    XCTAssertNil(unmanaged.doubleObj[@"key1"]);
    XCTAssertNil(unmanaged.dataObj[@"key1"]);
    XCTAssertNil(unmanaged.decimalObj[@"key1"]);
    XCTAssertNil(unmanaged.objectIdObj[@"key1"]);
    XCTAssertNil(unmanaged.uuidObj[@"key1"]);
    XCTAssertNil(unmanaged.anyBoolObj[@"key1"]);
    XCTAssertNil(unmanaged.anyIntObj[@"key1"]);
    XCTAssertNil(unmanaged.anyFloatObj[@"key1"]);
    XCTAssertNil(unmanaged.anyDoubleObj[@"key1"]);
    XCTAssertNil(unmanaged.anyStringObj[@"key1"]);
    XCTAssertNil(unmanaged.anyDataObj[@"key1"]);
    XCTAssertNil(unmanaged.anyDateObj[@"key1"]);
    XCTAssertNil(unmanaged.anyDecimalObj[@"key1"]);
    XCTAssertNil(unmanaged.anyObjectIdObj[@"key1"]);
    XCTAssertNil(unmanaged.anyUUIDObj[@"key1"]);

    // Unmanaged optional
    XCTAssertNil(optUnmanaged.boolObj[@"key1"]);
    XCTAssertNil(optUnmanaged.intObj[@"key1"]);
    XCTAssertNil(optUnmanaged.stringObj[@"key1"]);
    XCTAssertNil(optUnmanaged.dateObj[@"key1"]);
    XCTAssertNil(optUnmanaged.floatObj[@"key1"]);
    XCTAssertNil(optUnmanaged.doubleObj[@"key1"]);
    XCTAssertNil(optUnmanaged.dataObj[@"key1"]);
    XCTAssertNil(optUnmanaged.decimalObj[@"key1"]);
    XCTAssertNil(optUnmanaged.objectIdObj[@"key1"]);
    XCTAssertNil(optUnmanaged.uuidObj[@"key1"]);
    XCTAssertNoThrow(optUnmanaged.boolObj[@"key1"] = @NO);
    XCTAssertNoThrow(optUnmanaged.intObj[@"key1"] = @2);
    XCTAssertNoThrow(optUnmanaged.stringObj[@"key1"] = @"bar");
    XCTAssertNoThrow(optUnmanaged.dateObj[@"key1"] = date(1));
    XCTAssertNoThrow(optUnmanaged.floatObj[@"key1"] = @2.2f);
    XCTAssertNoThrow(optUnmanaged.doubleObj[@"key1"] = @2.2);
    XCTAssertNoThrow(optUnmanaged.dataObj[@"key1"] = data(1));
    XCTAssertNoThrow(optUnmanaged.decimalObj[@"key1"] = decimal128(2));
    XCTAssertNoThrow(optUnmanaged.objectIdObj[@"key1"] = objectId(1));
    XCTAssertNoThrow(optUnmanaged.uuidObj[@"key1"] = uuid(@"00000000-0000-0000-0000-000000000000"));
    XCTAssertEqualObjects(optUnmanaged.boolObj[@"key1"], @NO);
    XCTAssertEqualObjects(optUnmanaged.intObj[@"key1"], @2);
    XCTAssertEqualObjects(optUnmanaged.stringObj[@"key1"], @"bar");
    XCTAssertEqualObjects(optUnmanaged.dateObj[@"key1"], date(1));
    XCTAssertEqualObjects(optUnmanaged.floatObj[@"key1"], @2.2f);
    XCTAssertEqualObjects(optUnmanaged.doubleObj[@"key1"], @2.2);
    XCTAssertEqualObjects(optUnmanaged.dataObj[@"key1"], data(1));
    XCTAssertEqualObjects(optUnmanaged.decimalObj[@"key1"], decimal128(2));
    XCTAssertEqualObjects(optUnmanaged.objectIdObj[@"key1"], objectId(1));
    XCTAssertEqualObjects(optUnmanaged.uuidObj[@"key1"], uuid(@"00000000-0000-0000-0000-000000000000"));
    XCTAssertNoThrow(optUnmanaged.boolObj[@"key1"] = (id)NSNull.null);
    XCTAssertNoThrow(optUnmanaged.intObj[@"key1"] = (id)NSNull.null);
    XCTAssertNoThrow(optUnmanaged.stringObj[@"key1"] = (id)NSNull.null);
    XCTAssertNoThrow(optUnmanaged.dateObj[@"key1"] = (id)NSNull.null);
    XCTAssertNoThrow(optUnmanaged.floatObj[@"key1"] = (id)NSNull.null);
    XCTAssertNoThrow(optUnmanaged.doubleObj[@"key1"] = (id)NSNull.null);
    XCTAssertNoThrow(optUnmanaged.dataObj[@"key1"] = (id)NSNull.null);
    XCTAssertNoThrow(optUnmanaged.decimalObj[@"key1"] = (id)NSNull.null);
    XCTAssertNoThrow(optUnmanaged.objectIdObj[@"key1"] = (id)NSNull.null);
    XCTAssertNoThrow(optUnmanaged.uuidObj[@"key1"] = (id)NSNull.null);
    XCTAssertEqual(optUnmanaged.boolObj[@"key1"], (id)NSNull.null);
    XCTAssertEqual(optUnmanaged.intObj[@"key1"], (id)NSNull.null);
    XCTAssertEqual(optUnmanaged.stringObj[@"key1"], (id)NSNull.null);
    XCTAssertEqual(optUnmanaged.dateObj[@"key1"], (id)NSNull.null);
    XCTAssertEqual(optUnmanaged.floatObj[@"key1"], (id)NSNull.null);
    XCTAssertEqual(optUnmanaged.doubleObj[@"key1"], (id)NSNull.null);
    XCTAssertEqual(optUnmanaged.dataObj[@"key1"], (id)NSNull.null);
    XCTAssertEqual(optUnmanaged.decimalObj[@"key1"], (id)NSNull.null);
    XCTAssertEqual(optUnmanaged.objectIdObj[@"key1"], (id)NSNull.null);
    XCTAssertEqual(optUnmanaged.uuidObj[@"key1"], (id)NSNull.null);
    XCTAssertNoThrow(optUnmanaged.boolObj[@"key1"] = nil);
    XCTAssertNoThrow(optUnmanaged.intObj[@"key1"] = nil);
    XCTAssertNoThrow(optUnmanaged.stringObj[@"key1"] = nil);
    XCTAssertNoThrow(optUnmanaged.dateObj[@"key1"] = nil);
    XCTAssertNoThrow(optUnmanaged.floatObj[@"key1"] = nil);
    XCTAssertNoThrow(optUnmanaged.doubleObj[@"key1"] = nil);
    XCTAssertNoThrow(optUnmanaged.dataObj[@"key1"] = nil);
    XCTAssertNoThrow(optUnmanaged.decimalObj[@"key1"] = nil);
    XCTAssertNoThrow(optUnmanaged.objectIdObj[@"key1"] = nil);
    XCTAssertNoThrow(optUnmanaged.uuidObj[@"key1"] = nil);
    XCTAssertNil(optUnmanaged.boolObj[@"key1"]);
    XCTAssertNil(optUnmanaged.intObj[@"key1"]);
    XCTAssertNil(optUnmanaged.stringObj[@"key1"]);
    XCTAssertNil(optUnmanaged.dateObj[@"key1"]);
    XCTAssertNil(optUnmanaged.floatObj[@"key1"]);
    XCTAssertNil(optUnmanaged.doubleObj[@"key1"]);
    XCTAssertNil(optUnmanaged.dataObj[@"key1"]);
    XCTAssertNil(optUnmanaged.decimalObj[@"key1"]);
    XCTAssertNil(optUnmanaged.objectIdObj[@"key1"]);
    XCTAssertNil(optUnmanaged.uuidObj[@"key1"]);

    // Fail with nil key
    RLMAssertThrowsWithReason([unmanaged.boolObj setObject:@NO forKey:nil],
                              @"Invalid nil key for dictionary expecting key of type 'string'.");
    RLMAssertThrowsWithReason([optUnmanaged.boolObj setObject:@NO forKey:nil],
                              @"Invalid nil key for dictionary expecting key of type 'string'.");
    RLMAssertThrowsWithReason([managed.boolObj setObject:@NO forKey:nil],
                              @"Invalid nil key for dictionary expecting key of type 'string'.");
    RLMAssertThrowsWithReason([optManaged.boolObj setObject:@NO forKey:nil],
                              @"Invalid nil key for dictionary expecting key of type 'string'.");
    RLMAssertThrowsWithReason([unmanaged.intObj setObject:@2 forKey:nil],
                              @"Invalid nil key for dictionary expecting key of type 'string'.");
    RLMAssertThrowsWithReason([optUnmanaged.intObj setObject:@2 forKey:nil],
                              @"Invalid nil key for dictionary expecting key of type 'string'.");
    RLMAssertThrowsWithReason([managed.intObj setObject:@2 forKey:nil],
                              @"Invalid nil key for dictionary expecting key of type 'string'.");
    RLMAssertThrowsWithReason([optManaged.intObj setObject:@2 forKey:nil],
                              @"Invalid nil key for dictionary expecting key of type 'string'.");
    RLMAssertThrowsWithReason([unmanaged.stringObj setObject:@"bar" forKey:nil],
                              @"Invalid nil key for dictionary expecting key of type 'string'.");
    RLMAssertThrowsWithReason([optUnmanaged.stringObj setObject:@"bar" forKey:nil],
                              @"Invalid nil key for dictionary expecting key of type 'string'.");
    RLMAssertThrowsWithReason([managed.stringObj setObject:@"bar" forKey:nil],
                              @"Invalid nil key for dictionary expecting key of type 'string'.");
    RLMAssertThrowsWithReason([optManaged.stringObj setObject:@"bar" forKey:nil],
                              @"Invalid nil key for dictionary expecting key of type 'string'.");
    RLMAssertThrowsWithReason([unmanaged.dateObj setObject:date(1) forKey:nil],
                              @"Invalid nil key for dictionary expecting key of type 'string'.");
    RLMAssertThrowsWithReason([optUnmanaged.dateObj setObject:date(1) forKey:nil],
                              @"Invalid nil key for dictionary expecting key of type 'string'.");
    RLMAssertThrowsWithReason([managed.dateObj setObject:date(1) forKey:nil],
                              @"Invalid nil key for dictionary expecting key of type 'string'.");
    RLMAssertThrowsWithReason([optManaged.dateObj setObject:date(1) forKey:nil],
                              @"Invalid nil key for dictionary expecting key of type 'string'.");
    RLMAssertThrowsWithReason([unmanaged.floatObj setObject:@2.2f forKey:nil],
                              @"Invalid nil key for dictionary expecting key of type 'string'.");
    RLMAssertThrowsWithReason([optUnmanaged.floatObj setObject:@2.2f forKey:nil],
                              @"Invalid nil key for dictionary expecting key of type 'string'.");
    RLMAssertThrowsWithReason([managed.floatObj setObject:@2.2f forKey:nil],
                              @"Invalid nil key for dictionary expecting key of type 'string'.");
    RLMAssertThrowsWithReason([optManaged.floatObj setObject:@2.2f forKey:nil],
                              @"Invalid nil key for dictionary expecting key of type 'string'.");
    RLMAssertThrowsWithReason([unmanaged.doubleObj setObject:@2.2 forKey:nil],
                              @"Invalid nil key for dictionary expecting key of type 'string'.");
    RLMAssertThrowsWithReason([optUnmanaged.doubleObj setObject:@2.2 forKey:nil],
                              @"Invalid nil key for dictionary expecting key of type 'string'.");
    RLMAssertThrowsWithReason([managed.doubleObj setObject:@2.2 forKey:nil],
                              @"Invalid nil key for dictionary expecting key of type 'string'.");
    RLMAssertThrowsWithReason([optManaged.doubleObj setObject:@2.2 forKey:nil],
                              @"Invalid nil key for dictionary expecting key of type 'string'.");
    RLMAssertThrowsWithReason([unmanaged.dataObj setObject:data(1) forKey:nil],
                              @"Invalid nil key for dictionary expecting key of type 'string'.");
    RLMAssertThrowsWithReason([optUnmanaged.dataObj setObject:data(1) forKey:nil],
                              @"Invalid nil key for dictionary expecting key of type 'string'.");
    RLMAssertThrowsWithReason([managed.dataObj setObject:data(1) forKey:nil],
                              @"Invalid nil key for dictionary expecting key of type 'string'.");
    RLMAssertThrowsWithReason([optManaged.dataObj setObject:data(1) forKey:nil],
                              @"Invalid nil key for dictionary expecting key of type 'string'.");
    RLMAssertThrowsWithReason([unmanaged.decimalObj setObject:decimal128(2) forKey:nil],
                              @"Invalid nil key for dictionary expecting key of type 'string'.");
    RLMAssertThrowsWithReason([optUnmanaged.decimalObj setObject:decimal128(2) forKey:nil],
                              @"Invalid nil key for dictionary expecting key of type 'string'.");
    RLMAssertThrowsWithReason([managed.decimalObj setObject:decimal128(2) forKey:nil],
                              @"Invalid nil key for dictionary expecting key of type 'string'.");
    RLMAssertThrowsWithReason([optManaged.decimalObj setObject:decimal128(2) forKey:nil],
                              @"Invalid nil key for dictionary expecting key of type 'string'.");
    RLMAssertThrowsWithReason([unmanaged.objectIdObj setObject:objectId(1) forKey:nil],
                              @"Invalid nil key for dictionary expecting key of type 'string'.");
    RLMAssertThrowsWithReason([optUnmanaged.objectIdObj setObject:objectId(1) forKey:nil],
                              @"Invalid nil key for dictionary expecting key of type 'string'.");
    RLMAssertThrowsWithReason([managed.objectIdObj setObject:objectId(1) forKey:nil],
                              @"Invalid nil key for dictionary expecting key of type 'string'.");
    RLMAssertThrowsWithReason([optManaged.objectIdObj setObject:objectId(1) forKey:nil],
                              @"Invalid nil key for dictionary expecting key of type 'string'.");
    RLMAssertThrowsWithReason([unmanaged.uuidObj setObject:uuid(@"00000000-0000-0000-0000-000000000000") forKey:nil],
                              @"Invalid nil key for dictionary expecting key of type 'string'.");
    RLMAssertThrowsWithReason([optUnmanaged.uuidObj setObject:uuid(@"00000000-0000-0000-0000-000000000000") forKey:nil],
                              @"Invalid nil key for dictionary expecting key of type 'string'.");
    RLMAssertThrowsWithReason([managed.uuidObj setObject:uuid(@"00000000-0000-0000-0000-000000000000") forKey:nil],
                              @"Invalid nil key for dictionary expecting key of type 'string'.");
    RLMAssertThrowsWithReason([optManaged.uuidObj setObject:uuid(@"00000000-0000-0000-0000-000000000000") forKey:nil],
                              @"Invalid nil key for dictionary expecting key of type 'string'.");
    RLMAssertThrowsWithReason([unmanaged.anyBoolObj setObject:@NO forKey:nil],
                              @"Invalid nil key for dictionary expecting key of type 'string'.");
    RLMAssertThrowsWithReason([unmanaged.anyIntObj setObject:@2 forKey:nil],
                              @"Invalid nil key for dictionary expecting key of type 'string'.");
    RLMAssertThrowsWithReason([unmanaged.anyFloatObj setObject:@2.2f forKey:nil],
                              @"Invalid nil key for dictionary expecting key of type 'string'.");
    RLMAssertThrowsWithReason([unmanaged.anyDoubleObj setObject:@2.2 forKey:nil],
                              @"Invalid nil key for dictionary expecting key of type 'string'.");
    RLMAssertThrowsWithReason([unmanaged.anyStringObj setObject:@"a" forKey:nil],
                              @"Invalid nil key for dictionary expecting key of type 'string'.");
    RLMAssertThrowsWithReason([unmanaged.anyDataObj setObject:data(1) forKey:nil],
                              @"Invalid nil key for dictionary expecting key of type 'string'.");
    RLMAssertThrowsWithReason([unmanaged.anyDateObj setObject:date(1) forKey:nil],
                              @"Invalid nil key for dictionary expecting key of type 'string'.");
    RLMAssertThrowsWithReason([unmanaged.anyDecimalObj setObject:decimal128(2) forKey:nil],
                              @"Invalid nil key for dictionary expecting key of type 'string'.");
    RLMAssertThrowsWithReason([unmanaged.anyObjectIdObj setObject:objectId(1) forKey:nil],
                              @"Invalid nil key for dictionary expecting key of type 'string'.");
    RLMAssertThrowsWithReason([unmanaged.anyUUIDObj setObject:uuid(@"00000000-0000-0000-0000-000000000000") forKey:nil],
                              @"Invalid nil key for dictionary expecting key of type 'string'.");
    RLMAssertThrowsWithReason([managed.anyBoolObj setObject:@NO forKey:nil],
                              @"Invalid nil key for dictionary expecting key of type 'string'.");
    RLMAssertThrowsWithReason([managed.anyIntObj setObject:@2 forKey:nil],
                              @"Invalid nil key for dictionary expecting key of type 'string'.");
    RLMAssertThrowsWithReason([managed.anyFloatObj setObject:@2.2f forKey:nil],
                              @"Invalid nil key for dictionary expecting key of type 'string'.");
    RLMAssertThrowsWithReason([managed.anyDoubleObj setObject:@2.2 forKey:nil],
                              @"Invalid nil key for dictionary expecting key of type 'string'.");
    RLMAssertThrowsWithReason([managed.anyStringObj setObject:@"a" forKey:nil],
                              @"Invalid nil key for dictionary expecting key of type 'string'.");
    RLMAssertThrowsWithReason([managed.anyDataObj setObject:data(1) forKey:nil],
                              @"Invalid nil key for dictionary expecting key of type 'string'.");
    RLMAssertThrowsWithReason([managed.anyDateObj setObject:date(1) forKey:nil],
                              @"Invalid nil key for dictionary expecting key of type 'string'.");
    RLMAssertThrowsWithReason([managed.anyDecimalObj setObject:decimal128(2) forKey:nil],
                              @"Invalid nil key for dictionary expecting key of type 'string'.");
    RLMAssertThrowsWithReason([managed.anyObjectIdObj setObject:objectId(1) forKey:nil],
                              @"Invalid nil key for dictionary expecting key of type 'string'.");
    RLMAssertThrowsWithReason([managed.anyUUIDObj setObject:uuid(@"00000000-0000-0000-0000-000000000000") forKey:nil],
                              @"Invalid nil key for dictionary expecting key of type 'string'.");
    // Fail on set nil for non-optional
    RLMAssertThrowsWithReason([unmanaged.boolObj setObject:(id)NSNull.null forKey:@"key1"],
                              @"Invalid value '<null>' of type 'NSNull' for expected type 'bool'");
    RLMAssertThrowsWithReason([managed.boolObj setObject:(id)NSNull.null forKey:@"key1"],
                              @"Invalid value '<null>' of type 'NSNull' for expected type 'bool'");
    RLMAssertThrowsWithReason([unmanaged.intObj setObject:(id)NSNull.null forKey:@"key1"],
                              @"Invalid value '<null>' of type 'NSNull' for expected type 'int'");
    RLMAssertThrowsWithReason([managed.intObj setObject:(id)NSNull.null forKey:@"key1"],
                              @"Invalid value '<null>' of type 'NSNull' for expected type 'int'");
    RLMAssertThrowsWithReason([unmanaged.stringObj setObject:(id)NSNull.null forKey:@"key1"],
                              @"Invalid value '<null>' of type 'NSNull' for expected type 'string'");
    RLMAssertThrowsWithReason([managed.stringObj setObject:(id)NSNull.null forKey:@"key1"],
                              @"Invalid value '<null>' of type 'NSNull' for expected type 'string'");
    RLMAssertThrowsWithReason([unmanaged.dateObj setObject:(id)NSNull.null forKey:@"key1"],
                              @"Invalid value '<null>' of type 'NSNull' for expected type 'date'");
    RLMAssertThrowsWithReason([managed.dateObj setObject:(id)NSNull.null forKey:@"key1"],
                              @"Invalid value '<null>' of type 'NSNull' for expected type 'date'");
    RLMAssertThrowsWithReason([unmanaged.floatObj setObject:(id)NSNull.null forKey:@"key1"],
                              @"Invalid value '<null>' of type 'NSNull' for expected type 'float'");
    RLMAssertThrowsWithReason([managed.floatObj setObject:(id)NSNull.null forKey:@"key1"],
                              @"Invalid value '<null>' of type 'NSNull' for expected type 'float'");
    RLMAssertThrowsWithReason([unmanaged.doubleObj setObject:(id)NSNull.null forKey:@"key1"],
                              @"Invalid value '<null>' of type 'NSNull' for expected type 'double'");
    RLMAssertThrowsWithReason([managed.doubleObj setObject:(id)NSNull.null forKey:@"key1"],
                              @"Invalid value '<null>' of type 'NSNull' for expected type 'double'");
    RLMAssertThrowsWithReason([unmanaged.dataObj setObject:(id)NSNull.null forKey:@"key1"],
                              @"Invalid value '<null>' of type 'NSNull' for expected type 'data'");
    RLMAssertThrowsWithReason([managed.dataObj setObject:(id)NSNull.null forKey:@"key1"],
                              @"Invalid value '<null>' of type 'NSNull' for expected type 'data'");
    RLMAssertThrowsWithReason([unmanaged.decimalObj setObject:(id)NSNull.null forKey:@"key1"],
                              @"Invalid value '<null>' of type 'NSNull' for expected type 'decimal128'");
    RLMAssertThrowsWithReason([managed.decimalObj setObject:(id)NSNull.null forKey:@"key1"],
                              @"Invalid value '<null>' of type 'NSNull' for expected type 'decimal128'");
    RLMAssertThrowsWithReason([unmanaged.objectIdObj setObject:(id)NSNull.null forKey:@"key1"],
                              @"Invalid value '<null>' of type 'NSNull' for expected type 'object id'");
    RLMAssertThrowsWithReason([managed.objectIdObj setObject:(id)NSNull.null forKey:@"key1"],
                              @"Invalid value '<null>' of type 'NSNull' for expected type 'object id'");
    RLMAssertThrowsWithReason([unmanaged.uuidObj setObject:(id)NSNull.null forKey:@"key1"],
                              @"Invalid value '<null>' of type 'NSNull' for expected type 'uuid'");
    RLMAssertThrowsWithReason([managed.uuidObj setObject:(id)NSNull.null forKey:@"key1"],
                              @"Invalid value '<null>' of type 'NSNull' for expected type 'uuid'");

    RLMAssertThrowsWithReason([unmanaged.boolObj setObject:(id)@"a" forKey:@"key1"],
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'bool'");
    RLMAssertThrowsWithReason([optUnmanaged.boolObj setObject:(id)@"a" forKey:@"key1"],
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'bool?'");
    RLMAssertThrowsWithReason([managed.boolObj setObject:(id)@"a" forKey:@"key1"],
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'bool'");
    RLMAssertThrowsWithReason([optManaged.boolObj setObject:(id)@"a" forKey:@"key1"],
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'bool?'");
    RLMAssertThrowsWithReason([unmanaged.intObj setObject:(id)@"a" forKey:@"key1"],
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'int'");
    RLMAssertThrowsWithReason([optUnmanaged.intObj setObject:(id)@"a" forKey:@"key1"],
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'int?'");
    RLMAssertThrowsWithReason([managed.intObj setObject:(id)@"a" forKey:@"key1"],
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'int'");
    RLMAssertThrowsWithReason([optManaged.intObj setObject:(id)@"a" forKey:@"key1"],
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'int?'");
    RLMAssertThrowsWithReason([unmanaged.stringObj setObject:(id)@2 forKey:@"key1"],
                              @"Invalid value '2' of type '__NSCFNumber' for expected type 'string'");
    RLMAssertThrowsWithReason([optUnmanaged.stringObj setObject:(id)@2 forKey:@"key1"],
                              @"Invalid value '2' of type '__NSCFNumber' for expected type 'string?'");
    RLMAssertThrowsWithReason([managed.stringObj setObject:(id)@2 forKey:@"key1"],
                              @"Invalid value '2' of type '__NSCFNumber' for expected type 'string'");
    RLMAssertThrowsWithReason([optManaged.stringObj setObject:(id)@2 forKey:@"key1"],
                              @"Invalid value '2' of type '__NSCFNumber' for expected type 'string?'");
    RLMAssertThrowsWithReason([unmanaged.dateObj setObject:(id)@"a" forKey:@"key1"],
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'date'");
    RLMAssertThrowsWithReason([optUnmanaged.dateObj setObject:(id)@"a" forKey:@"key1"],
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'date?'");
    RLMAssertThrowsWithReason([managed.dateObj setObject:(id)@"a" forKey:@"key1"],
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'date'");
    RLMAssertThrowsWithReason([optManaged.dateObj setObject:(id)@"a" forKey:@"key1"],
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'date?'");
    RLMAssertThrowsWithReason([unmanaged.floatObj setObject:(id)@"a" forKey:@"key1"],
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'float'");
    RLMAssertThrowsWithReason([optUnmanaged.floatObj setObject:(id)@"a" forKey:@"key1"],
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'float?'");
    RLMAssertThrowsWithReason([managed.floatObj setObject:(id)@"a" forKey:@"key1"],
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'float'");
    RLMAssertThrowsWithReason([optManaged.floatObj setObject:(id)@"a" forKey:@"key1"],
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'float?'");
    RLMAssertThrowsWithReason([unmanaged.doubleObj setObject:(id)@"a" forKey:@"key1"],
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'double'");
    RLMAssertThrowsWithReason([optUnmanaged.doubleObj setObject:(id)@"a" forKey:@"key1"],
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'double?'");
    RLMAssertThrowsWithReason([managed.doubleObj setObject:(id)@"a" forKey:@"key1"],
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'double'");
    RLMAssertThrowsWithReason([optManaged.doubleObj setObject:(id)@"a" forKey:@"key1"],
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'double?'");
    RLMAssertThrowsWithReason([unmanaged.dataObj setObject:(id)@"a" forKey:@"key1"],
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'data'");
    RLMAssertThrowsWithReason([optUnmanaged.dataObj setObject:(id)@"a" forKey:@"key1"],
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'data?'");
    RLMAssertThrowsWithReason([managed.dataObj setObject:(id)@"a" forKey:@"key1"],
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'data'");
    RLMAssertThrowsWithReason([optManaged.dataObj setObject:(id)@"a" forKey:@"key1"],
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'data?'");
    RLMAssertThrowsWithReason([unmanaged.decimalObj setObject:(id)@"a" forKey:@"key1"],
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'decimal128'");
    RLMAssertThrowsWithReason([optUnmanaged.decimalObj setObject:(id)@"a" forKey:@"key1"],
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'decimal128?'");
    RLMAssertThrowsWithReason([managed.decimalObj setObject:(id)@"a" forKey:@"key1"],
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'decimal128'");
    RLMAssertThrowsWithReason([optManaged.decimalObj setObject:(id)@"a" forKey:@"key1"],
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'decimal128?'");
    RLMAssertThrowsWithReason([unmanaged.objectIdObj setObject:(id)@"a" forKey:@"key1"],
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'object id'");
    RLMAssertThrowsWithReason([optUnmanaged.objectIdObj setObject:(id)@"a" forKey:@"key1"],
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'object id?'");
    RLMAssertThrowsWithReason([managed.objectIdObj setObject:(id)@"a" forKey:@"key1"],
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'object id'");
    RLMAssertThrowsWithReason([optManaged.objectIdObj setObject:(id)@"a" forKey:@"key1"],
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'object id?'");
    RLMAssertThrowsWithReason([unmanaged.uuidObj setObject:(id)@"a" forKey:@"key1"],
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'uuid'");
    RLMAssertThrowsWithReason([optUnmanaged.uuidObj setObject:(id)@"a" forKey:@"key1"],
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'uuid?'");
    RLMAssertThrowsWithReason([managed.uuidObj setObject:(id)@"a" forKey:@"key1"],
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'uuid'");
    RLMAssertThrowsWithReason([optManaged.uuidObj setObject:(id)@"a" forKey:@"key1"],
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'uuid?'");
    RLMAssertThrowsWithReason([unmanaged.boolObj setObject:(id)NSNull.null forKey:@"key1"],
                              @"Invalid value '<null>' of type 'NSNull' for expected type 'bool'");
    RLMAssertThrowsWithReason([managed.boolObj setObject:(id)NSNull.null forKey:@"key1"],
                              @"Invalid value '<null>' of type 'NSNull' for expected type 'bool'");
    RLMAssertThrowsWithReason([unmanaged.intObj setObject:(id)NSNull.null forKey:@"key1"],
                              @"Invalid value '<null>' of type 'NSNull' for expected type 'int'");
    RLMAssertThrowsWithReason([managed.intObj setObject:(id)NSNull.null forKey:@"key1"],
                              @"Invalid value '<null>' of type 'NSNull' for expected type 'int'");
    RLMAssertThrowsWithReason([unmanaged.stringObj setObject:(id)NSNull.null forKey:@"key1"],
                              @"Invalid value '<null>' of type 'NSNull' for expected type 'string'");
    RLMAssertThrowsWithReason([managed.stringObj setObject:(id)NSNull.null forKey:@"key1"],
                              @"Invalid value '<null>' of type 'NSNull' for expected type 'string'");
    RLMAssertThrowsWithReason([unmanaged.dateObj setObject:(id)NSNull.null forKey:@"key1"],
                              @"Invalid value '<null>' of type 'NSNull' for expected type 'date'");
    RLMAssertThrowsWithReason([managed.dateObj setObject:(id)NSNull.null forKey:@"key1"],
                              @"Invalid value '<null>' of type 'NSNull' for expected type 'date'");
    RLMAssertThrowsWithReason([unmanaged.floatObj setObject:(id)NSNull.null forKey:@"key1"],
                              @"Invalid value '<null>' of type 'NSNull' for expected type 'float'");
    RLMAssertThrowsWithReason([managed.floatObj setObject:(id)NSNull.null forKey:@"key1"],
                              @"Invalid value '<null>' of type 'NSNull' for expected type 'float'");
    RLMAssertThrowsWithReason([unmanaged.doubleObj setObject:(id)NSNull.null forKey:@"key1"],
                              @"Invalid value '<null>' of type 'NSNull' for expected type 'double'");
    RLMAssertThrowsWithReason([managed.doubleObj setObject:(id)NSNull.null forKey:@"key1"],
                              @"Invalid value '<null>' of type 'NSNull' for expected type 'double'");
    RLMAssertThrowsWithReason([unmanaged.dataObj setObject:(id)NSNull.null forKey:@"key1"],
                              @"Invalid value '<null>' of type 'NSNull' for expected type 'data'");
    RLMAssertThrowsWithReason([managed.dataObj setObject:(id)NSNull.null forKey:@"key1"],
                              @"Invalid value '<null>' of type 'NSNull' for expected type 'data'");
    RLMAssertThrowsWithReason([unmanaged.decimalObj setObject:(id)NSNull.null forKey:@"key1"],
                              @"Invalid value '<null>' of type 'NSNull' for expected type 'decimal128'");
    RLMAssertThrowsWithReason([managed.decimalObj setObject:(id)NSNull.null forKey:@"key1"],
                              @"Invalid value '<null>' of type 'NSNull' for expected type 'decimal128'");
    RLMAssertThrowsWithReason([unmanaged.objectIdObj setObject:(id)NSNull.null forKey:@"key1"],
                              @"Invalid value '<null>' of type 'NSNull' for expected type 'object id'");
    RLMAssertThrowsWithReason([managed.objectIdObj setObject:(id)NSNull.null forKey:@"key1"],
                              @"Invalid value '<null>' of type 'NSNull' for expected type 'object id'");
    RLMAssertThrowsWithReason([unmanaged.uuidObj setObject:(id)NSNull.null forKey:@"key1"],
                              @"Invalid value '<null>' of type 'NSNull' for expected type 'uuid'");
    RLMAssertThrowsWithReason([managed.uuidObj setObject:(id)NSNull.null forKey:@"key1"],
                              @"Invalid value '<null>' of type 'NSNull' for expected type 'uuid'");

    unmanaged.boolObj[@"key1"] = @NO;
    optUnmanaged.boolObj[@"key1"] = @NO;
    managed.boolObj[@"key1"] = @NO;
    optManaged.boolObj[@"key1"] = @NO;
    unmanaged.intObj[@"key1"] = @2;
    optUnmanaged.intObj[@"key1"] = @2;
    managed.intObj[@"key1"] = @2;
    optManaged.intObj[@"key1"] = @2;
    unmanaged.stringObj[@"key1"] = @"bar";
    optUnmanaged.stringObj[@"key1"] = @"bar";
    managed.stringObj[@"key1"] = @"bar";
    optManaged.stringObj[@"key1"] = @"bar";
    unmanaged.dateObj[@"key1"] = date(1);
    optUnmanaged.dateObj[@"key1"] = date(1);
    managed.dateObj[@"key1"] = date(1);
    optManaged.dateObj[@"key1"] = date(1);
    unmanaged.floatObj[@"key1"] = @2.2f;
    optUnmanaged.floatObj[@"key1"] = @2.2f;
    managed.floatObj[@"key1"] = @2.2f;
    optManaged.floatObj[@"key1"] = @2.2f;
    unmanaged.doubleObj[@"key1"] = @2.2;
    optUnmanaged.doubleObj[@"key1"] = @2.2;
    managed.doubleObj[@"key1"] = @2.2;
    optManaged.doubleObj[@"key1"] = @2.2;
    unmanaged.dataObj[@"key1"] = data(1);
    optUnmanaged.dataObj[@"key1"] = data(1);
    managed.dataObj[@"key1"] = data(1);
    optManaged.dataObj[@"key1"] = data(1);
    unmanaged.decimalObj[@"key1"] = decimal128(2);
    optUnmanaged.decimalObj[@"key1"] = decimal128(2);
    managed.decimalObj[@"key1"] = decimal128(2);
    optManaged.decimalObj[@"key1"] = decimal128(2);
    unmanaged.objectIdObj[@"key1"] = objectId(1);
    optUnmanaged.objectIdObj[@"key1"] = objectId(1);
    managed.objectIdObj[@"key1"] = objectId(1);
    optManaged.objectIdObj[@"key1"] = objectId(1);
    unmanaged.uuidObj[@"key1"] = uuid(@"00000000-0000-0000-0000-000000000000");
    optUnmanaged.uuidObj[@"key1"] = uuid(@"00000000-0000-0000-0000-000000000000");
    managed.uuidObj[@"key1"] = uuid(@"00000000-0000-0000-0000-000000000000");
    optManaged.uuidObj[@"key1"] = uuid(@"00000000-0000-0000-0000-000000000000");
    unmanaged.anyBoolObj[@"key1"] = @NO;
    unmanaged.anyIntObj[@"key1"] = @2;
    unmanaged.anyFloatObj[@"key1"] = @2.2f;
    unmanaged.anyDoubleObj[@"key1"] = @2.2;
    unmanaged.anyStringObj[@"key1"] = @"a";
    unmanaged.anyDataObj[@"key1"] = data(1);
    unmanaged.anyDateObj[@"key1"] = date(1);
    unmanaged.anyDecimalObj[@"key1"] = decimal128(2);
    unmanaged.anyObjectIdObj[@"key1"] = objectId(1);
    unmanaged.anyUUIDObj[@"key1"] = uuid(@"00000000-0000-0000-0000-000000000000");
    managed.anyBoolObj[@"key1"] = @NO;
    managed.anyIntObj[@"key1"] = @2;
    managed.anyFloatObj[@"key1"] = @2.2f;
    managed.anyDoubleObj[@"key1"] = @2.2;
    managed.anyStringObj[@"key1"] = @"a";
    managed.anyDataObj[@"key1"] = data(1);
    managed.anyDateObj[@"key1"] = date(1);
    managed.anyDecimalObj[@"key1"] = decimal128(2);
    managed.anyObjectIdObj[@"key1"] = objectId(1);
    managed.anyUUIDObj[@"key1"] = uuid(@"00000000-0000-0000-0000-000000000000");
    XCTAssertEqualObjects(unmanaged.boolObj[@"key1"], @NO);
    XCTAssertEqualObjects(optUnmanaged.boolObj[@"key1"], @NO);
    XCTAssertEqualObjects(managed.boolObj[@"key1"], @NO);
    XCTAssertEqualObjects(optManaged.boolObj[@"key1"], @NO);
    XCTAssertEqualObjects(unmanaged.intObj[@"key1"], @2);
    XCTAssertEqualObjects(optUnmanaged.intObj[@"key1"], @2);
    XCTAssertEqualObjects(managed.intObj[@"key1"], @2);
    XCTAssertEqualObjects(optManaged.intObj[@"key1"], @2);
    XCTAssertEqualObjects(unmanaged.stringObj[@"key1"], @"bar");
    XCTAssertEqualObjects(optUnmanaged.stringObj[@"key1"], @"bar");
    XCTAssertEqualObjects(managed.stringObj[@"key1"], @"bar");
    XCTAssertEqualObjects(optManaged.stringObj[@"key1"], @"bar");
    XCTAssertEqualObjects(unmanaged.dateObj[@"key1"], date(1));
    XCTAssertEqualObjects(optUnmanaged.dateObj[@"key1"], date(1));
    XCTAssertEqualObjects(managed.dateObj[@"key1"], date(1));
    XCTAssertEqualObjects(optManaged.dateObj[@"key1"], date(1));
    XCTAssertEqualObjects(unmanaged.floatObj[@"key1"], @2.2f);
    XCTAssertEqualObjects(optUnmanaged.floatObj[@"key1"], @2.2f);
    XCTAssertEqualObjects(managed.floatObj[@"key1"], @2.2f);
    XCTAssertEqualObjects(optManaged.floatObj[@"key1"], @2.2f);
    XCTAssertEqualObjects(unmanaged.doubleObj[@"key1"], @2.2);
    XCTAssertEqualObjects(optUnmanaged.doubleObj[@"key1"], @2.2);
    XCTAssertEqualObjects(managed.doubleObj[@"key1"], @2.2);
    XCTAssertEqualObjects(optManaged.doubleObj[@"key1"], @2.2);
    XCTAssertEqualObjects(unmanaged.dataObj[@"key1"], data(1));
    XCTAssertEqualObjects(optUnmanaged.dataObj[@"key1"], data(1));
    XCTAssertEqualObjects(managed.dataObj[@"key1"], data(1));
    XCTAssertEqualObjects(optManaged.dataObj[@"key1"], data(1));
    XCTAssertEqualObjects(unmanaged.decimalObj[@"key1"], decimal128(2));
    XCTAssertEqualObjects(optUnmanaged.decimalObj[@"key1"], decimal128(2));
    XCTAssertEqualObjects(managed.decimalObj[@"key1"], decimal128(2));
    XCTAssertEqualObjects(optManaged.decimalObj[@"key1"], decimal128(2));
    XCTAssertEqualObjects(unmanaged.objectIdObj[@"key1"], objectId(1));
    XCTAssertEqualObjects(optUnmanaged.objectIdObj[@"key1"], objectId(1));
    XCTAssertEqualObjects(managed.objectIdObj[@"key1"], objectId(1));
    XCTAssertEqualObjects(optManaged.objectIdObj[@"key1"], objectId(1));
    XCTAssertEqualObjects(unmanaged.uuidObj[@"key1"], uuid(@"00000000-0000-0000-0000-000000000000"));
    XCTAssertEqualObjects(optUnmanaged.uuidObj[@"key1"], uuid(@"00000000-0000-0000-0000-000000000000"));
    XCTAssertEqualObjects(managed.uuidObj[@"key1"], uuid(@"00000000-0000-0000-0000-000000000000"));
    XCTAssertEqualObjects(optManaged.uuidObj[@"key1"], uuid(@"00000000-0000-0000-0000-000000000000"));
    XCTAssertEqualObjects(unmanaged.anyBoolObj[@"key1"], @NO);
    XCTAssertEqualObjects(unmanaged.anyIntObj[@"key1"], @2);
    XCTAssertEqualObjects(unmanaged.anyFloatObj[@"key1"], @2.2f);
    XCTAssertEqualObjects(unmanaged.anyDoubleObj[@"key1"], @2.2);
    XCTAssertEqualObjects(unmanaged.anyStringObj[@"key1"], @"a");
    XCTAssertEqualObjects(unmanaged.anyDataObj[@"key1"], data(1));
    XCTAssertEqualObjects(unmanaged.anyDateObj[@"key1"], date(1));
    XCTAssertEqualObjects(unmanaged.anyDecimalObj[@"key1"], decimal128(2));
    XCTAssertEqualObjects(unmanaged.anyObjectIdObj[@"key1"], objectId(1));
    XCTAssertEqualObjects(unmanaged.anyUUIDObj[@"key1"], uuid(@"00000000-0000-0000-0000-000000000000"));
    XCTAssertEqualObjects(managed.anyBoolObj[@"key1"], @NO);
    XCTAssertEqualObjects(managed.anyIntObj[@"key1"], @2);
    XCTAssertEqualObjects(managed.anyFloatObj[@"key1"], @2.2f);
    XCTAssertEqualObjects(managed.anyDoubleObj[@"key1"], @2.2);
    XCTAssertEqualObjects(managed.anyStringObj[@"key1"], @"a");
    XCTAssertEqualObjects(managed.anyDataObj[@"key1"], data(1));
    XCTAssertEqualObjects(managed.anyDateObj[@"key1"], date(1));
    XCTAssertEqualObjects(managed.anyDecimalObj[@"key1"], decimal128(2));
    XCTAssertEqualObjects(managed.anyObjectIdObj[@"key1"], objectId(1));
    XCTAssertEqualObjects(managed.anyUUIDObj[@"key1"], uuid(@"00000000-0000-0000-0000-000000000000"));

    optUnmanaged.boolObj[@"key1"] = (id)NSNull.null;
    optManaged.boolObj[@"key1"] = (id)NSNull.null;
    optUnmanaged.intObj[@"key1"] = (id)NSNull.null;
    optManaged.intObj[@"key1"] = (id)NSNull.null;
    optUnmanaged.stringObj[@"key1"] = (id)NSNull.null;
    optManaged.stringObj[@"key1"] = (id)NSNull.null;
    optUnmanaged.dateObj[@"key1"] = (id)NSNull.null;
    optManaged.dateObj[@"key1"] = (id)NSNull.null;
    optUnmanaged.floatObj[@"key1"] = (id)NSNull.null;
    optManaged.floatObj[@"key1"] = (id)NSNull.null;
    optUnmanaged.doubleObj[@"key1"] = (id)NSNull.null;
    optManaged.doubleObj[@"key1"] = (id)NSNull.null;
    optUnmanaged.dataObj[@"key1"] = (id)NSNull.null;
    optManaged.dataObj[@"key1"] = (id)NSNull.null;
    optUnmanaged.decimalObj[@"key1"] = (id)NSNull.null;
    optManaged.decimalObj[@"key1"] = (id)NSNull.null;
    optUnmanaged.objectIdObj[@"key1"] = (id)NSNull.null;
    optManaged.objectIdObj[@"key1"] = (id)NSNull.null;
    optUnmanaged.uuidObj[@"key1"] = (id)NSNull.null;
    optManaged.uuidObj[@"key1"] = (id)NSNull.null;
    XCTAssertEqualObjects(optUnmanaged.boolObj[@"key1"], (id)NSNull.null);
    XCTAssertEqualObjects(optManaged.boolObj[@"key1"], (id)NSNull.null);
    XCTAssertEqualObjects(optUnmanaged.intObj[@"key1"], (id)NSNull.null);
    XCTAssertEqualObjects(optManaged.intObj[@"key1"], (id)NSNull.null);
    XCTAssertEqualObjects(optUnmanaged.stringObj[@"key1"], (id)NSNull.null);
    XCTAssertEqualObjects(optManaged.stringObj[@"key1"], (id)NSNull.null);
    XCTAssertEqualObjects(optUnmanaged.dateObj[@"key1"], (id)NSNull.null);
    XCTAssertEqualObjects(optManaged.dateObj[@"key1"], (id)NSNull.null);
    XCTAssertEqualObjects(optUnmanaged.floatObj[@"key1"], (id)NSNull.null);
    XCTAssertEqualObjects(optManaged.floatObj[@"key1"], (id)NSNull.null);
    XCTAssertEqualObjects(optUnmanaged.doubleObj[@"key1"], (id)NSNull.null);
    XCTAssertEqualObjects(optManaged.doubleObj[@"key1"], (id)NSNull.null);
    XCTAssertEqualObjects(optUnmanaged.dataObj[@"key1"], (id)NSNull.null);
    XCTAssertEqualObjects(optManaged.dataObj[@"key1"], (id)NSNull.null);
    XCTAssertEqualObjects(optUnmanaged.decimalObj[@"key1"], (id)NSNull.null);
    XCTAssertEqualObjects(optManaged.decimalObj[@"key1"], (id)NSNull.null);
    XCTAssertEqualObjects(optUnmanaged.objectIdObj[@"key1"], (id)NSNull.null);
    XCTAssertEqualObjects(optManaged.objectIdObj[@"key1"], (id)NSNull.null);
    XCTAssertEqualObjects(optUnmanaged.uuidObj[@"key1"], (id)NSNull.null);
    XCTAssertEqualObjects(optManaged.uuidObj[@"key1"], (id)NSNull.null);
}
#pragma clang diagnostic pop

- (void)testAddObjects {
    RLMAssertThrowsWithReason([unmanaged.boolObj addEntriesFromDictionary:@{@"key1": @"a"}],
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'bool'");
    RLMAssertThrowsWithReason([optUnmanaged.boolObj addEntriesFromDictionary:@{@"key1": @"a"}],
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'bool?'");
    RLMAssertThrowsWithReason([managed.boolObj addEntriesFromDictionary:@{@"key1": @"a"}],
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'bool'");
    RLMAssertThrowsWithReason([optManaged.boolObj addEntriesFromDictionary:@{@"key1": @"a"}],
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'bool?'");
    RLMAssertThrowsWithReason([unmanaged.intObj addEntriesFromDictionary:@{@"key1": @"a"}],
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'int'");
    RLMAssertThrowsWithReason([optUnmanaged.intObj addEntriesFromDictionary:@{@"key1": @"a"}],
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'int?'");
    RLMAssertThrowsWithReason([managed.intObj addEntriesFromDictionary:@{@"key1": @"a"}],
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'int'");
    RLMAssertThrowsWithReason([optManaged.intObj addEntriesFromDictionary:@{@"key1": @"a"}],
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'int?'");
    RLMAssertThrowsWithReason([unmanaged.stringObj addEntriesFromDictionary:@{@"key1": @2}],
                              @"Invalid value '2' of type '__NSCFNumber' for expected type 'string'");
    RLMAssertThrowsWithReason([optUnmanaged.stringObj addEntriesFromDictionary:@{@"key1": @2}],
                              @"Invalid value '2' of type '__NSCFNumber' for expected type 'string?'");
    RLMAssertThrowsWithReason([managed.stringObj addEntriesFromDictionary:@{@"key1": @2}],
                              @"Invalid value '2' of type '__NSCFNumber' for expected type 'string'");
    RLMAssertThrowsWithReason([optManaged.stringObj addEntriesFromDictionary:@{@"key1": @2}],
                              @"Invalid value '2' of type '__NSCFNumber' for expected type 'string?'");
    RLMAssertThrowsWithReason([unmanaged.dateObj addEntriesFromDictionary:@{@"key1": @"a"}],
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'date'");
    RLMAssertThrowsWithReason([optUnmanaged.dateObj addEntriesFromDictionary:@{@"key1": @"a"}],
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'date?'");
    RLMAssertThrowsWithReason([managed.dateObj addEntriesFromDictionary:@{@"key1": @"a"}],
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'date'");
    RLMAssertThrowsWithReason([optManaged.dateObj addEntriesFromDictionary:@{@"key1": @"a"}],
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'date?'");
    RLMAssertThrowsWithReason([unmanaged.floatObj addEntriesFromDictionary:@{@"key1": @"a"}],
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'float'");
    RLMAssertThrowsWithReason([optUnmanaged.floatObj addEntriesFromDictionary:@{@"key1": @"a"}],
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'float?'");
    RLMAssertThrowsWithReason([managed.floatObj addEntriesFromDictionary:@{@"key1": @"a"}],
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'float'");
    RLMAssertThrowsWithReason([optManaged.floatObj addEntriesFromDictionary:@{@"key1": @"a"}],
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'float?'");
    RLMAssertThrowsWithReason([unmanaged.doubleObj addEntriesFromDictionary:@{@"key1": @"a"}],
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'double'");
    RLMAssertThrowsWithReason([optUnmanaged.doubleObj addEntriesFromDictionary:@{@"key1": @"a"}],
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'double?'");
    RLMAssertThrowsWithReason([managed.doubleObj addEntriesFromDictionary:@{@"key1": @"a"}],
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'double'");
    RLMAssertThrowsWithReason([optManaged.doubleObj addEntriesFromDictionary:@{@"key1": @"a"}],
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'double?'");
    RLMAssertThrowsWithReason([unmanaged.dataObj addEntriesFromDictionary:@{@"key1": @"a"}],
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'data'");
    RLMAssertThrowsWithReason([optUnmanaged.dataObj addEntriesFromDictionary:@{@"key1": @"a"}],
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'data?'");
    RLMAssertThrowsWithReason([managed.dataObj addEntriesFromDictionary:@{@"key1": @"a"}],
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'data'");
    RLMAssertThrowsWithReason([optManaged.dataObj addEntriesFromDictionary:@{@"key1": @"a"}],
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'data?'");
    RLMAssertThrowsWithReason([unmanaged.decimalObj addEntriesFromDictionary:@{@"key1": @"a"}],
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'decimal128'");
    RLMAssertThrowsWithReason([optUnmanaged.decimalObj addEntriesFromDictionary:@{@"key1": @"a"}],
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'decimal128?'");
    RLMAssertThrowsWithReason([managed.decimalObj addEntriesFromDictionary:@{@"key1": @"a"}],
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'decimal128'");
    RLMAssertThrowsWithReason([optManaged.decimalObj addEntriesFromDictionary:@{@"key1": @"a"}],
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'decimal128?'");
    RLMAssertThrowsWithReason([unmanaged.objectIdObj addEntriesFromDictionary:@{@"key1": @"a"}],
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'object id'");
    RLMAssertThrowsWithReason([optUnmanaged.objectIdObj addEntriesFromDictionary:@{@"key1": @"a"}],
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'object id?'");
    RLMAssertThrowsWithReason([managed.objectIdObj addEntriesFromDictionary:@{@"key1": @"a"}],
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'object id'");
    RLMAssertThrowsWithReason([optManaged.objectIdObj addEntriesFromDictionary:@{@"key1": @"a"}],
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'object id?'");
    RLMAssertThrowsWithReason([unmanaged.uuidObj addEntriesFromDictionary:@{@"key1": @"a"}],
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'uuid'");
    RLMAssertThrowsWithReason([optUnmanaged.uuidObj addEntriesFromDictionary:@{@"key1": @"a"}],
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'uuid?'");
    RLMAssertThrowsWithReason([managed.uuidObj addEntriesFromDictionary:@{@"key1": @"a"}],
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'uuid'");
    RLMAssertThrowsWithReason([optManaged.uuidObj addEntriesFromDictionary:@{@"key1": @"a"}],
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'uuid?'");
    RLMAssertThrowsWithReason([unmanaged.boolObj addEntriesFromDictionary:@{@"key1": (id)NSNull.null}],
                              @"Invalid value '<null>' of type 'NSNull' for expected type 'bool'");
    RLMAssertThrowsWithReason([managed.boolObj addEntriesFromDictionary:@{@"key1": (id)NSNull.null}],
                              @"Invalid value '<null>' of type 'NSNull' for expected type 'bool'");
    RLMAssertThrowsWithReason([unmanaged.intObj addEntriesFromDictionary:@{@"key1": (id)NSNull.null}],
                              @"Invalid value '<null>' of type 'NSNull' for expected type 'int'");
    RLMAssertThrowsWithReason([managed.intObj addEntriesFromDictionary:@{@"key1": (id)NSNull.null}],
                              @"Invalid value '<null>' of type 'NSNull' for expected type 'int'");
    RLMAssertThrowsWithReason([unmanaged.stringObj addEntriesFromDictionary:@{@"key1": (id)NSNull.null}],
                              @"Invalid value '<null>' of type 'NSNull' for expected type 'string'");
    RLMAssertThrowsWithReason([managed.stringObj addEntriesFromDictionary:@{@"key1": (id)NSNull.null}],
                              @"Invalid value '<null>' of type 'NSNull' for expected type 'string'");
    RLMAssertThrowsWithReason([unmanaged.dateObj addEntriesFromDictionary:@{@"key1": (id)NSNull.null}],
                              @"Invalid value '<null>' of type 'NSNull' for expected type 'date'");
    RLMAssertThrowsWithReason([managed.dateObj addEntriesFromDictionary:@{@"key1": (id)NSNull.null}],
                              @"Invalid value '<null>' of type 'NSNull' for expected type 'date'");
    RLMAssertThrowsWithReason([unmanaged.floatObj addEntriesFromDictionary:@{@"key1": (id)NSNull.null}],
                              @"Invalid value '<null>' of type 'NSNull' for expected type 'float'");
    RLMAssertThrowsWithReason([managed.floatObj addEntriesFromDictionary:@{@"key1": (id)NSNull.null}],
                              @"Invalid value '<null>' of type 'NSNull' for expected type 'float'");
    RLMAssertThrowsWithReason([unmanaged.doubleObj addEntriesFromDictionary:@{@"key1": (id)NSNull.null}],
                              @"Invalid value '<null>' of type 'NSNull' for expected type 'double'");
    RLMAssertThrowsWithReason([managed.doubleObj addEntriesFromDictionary:@{@"key1": (id)NSNull.null}],
                              @"Invalid value '<null>' of type 'NSNull' for expected type 'double'");
    RLMAssertThrowsWithReason([unmanaged.dataObj addEntriesFromDictionary:@{@"key1": (id)NSNull.null}],
                              @"Invalid value '<null>' of type 'NSNull' for expected type 'data'");
    RLMAssertThrowsWithReason([managed.dataObj addEntriesFromDictionary:@{@"key1": (id)NSNull.null}],
                              @"Invalid value '<null>' of type 'NSNull' for expected type 'data'");
    RLMAssertThrowsWithReason([unmanaged.decimalObj addEntriesFromDictionary:@{@"key1": (id)NSNull.null}],
                              @"Invalid value '<null>' of type 'NSNull' for expected type 'decimal128'");
    RLMAssertThrowsWithReason([managed.decimalObj addEntriesFromDictionary:@{@"key1": (id)NSNull.null}],
                              @"Invalid value '<null>' of type 'NSNull' for expected type 'decimal128'");
    RLMAssertThrowsWithReason([unmanaged.objectIdObj addEntriesFromDictionary:@{@"key1": (id)NSNull.null}],
                              @"Invalid value '<null>' of type 'NSNull' for expected type 'object id'");
    RLMAssertThrowsWithReason([managed.objectIdObj addEntriesFromDictionary:@{@"key1": (id)NSNull.null}],
                              @"Invalid value '<null>' of type 'NSNull' for expected type 'object id'");
    RLMAssertThrowsWithReason([unmanaged.uuidObj addEntriesFromDictionary:@{@"key1": (id)NSNull.null}],
                              @"Invalid value '<null>' of type 'NSNull' for expected type 'uuid'");
    RLMAssertThrowsWithReason([managed.uuidObj addEntriesFromDictionary:@{@"key1": (id)NSNull.null}],
                              @"Invalid value '<null>' of type 'NSNull' for expected type 'uuid'");

    [self addObjects];
    XCTAssertEqualObjects(unmanaged.boolObj[@"key1"], @NO);
    XCTAssertEqualObjects(optUnmanaged.boolObj[@"key1"], @NO);
    XCTAssertEqualObjects(managed.boolObj[@"key1"], @NO);
    XCTAssertEqualObjects(optManaged.boolObj[@"key1"], @NO);
    XCTAssertEqualObjects(unmanaged.intObj[@"key1"], @2);
    XCTAssertEqualObjects(optUnmanaged.intObj[@"key1"], @2);
    XCTAssertEqualObjects(managed.intObj[@"key1"], @2);
    XCTAssertEqualObjects(optManaged.intObj[@"key1"], @2);
    XCTAssertEqualObjects(unmanaged.stringObj[@"key1"], @"bar");
    XCTAssertEqualObjects(optUnmanaged.stringObj[@"key1"], @"bar");
    XCTAssertEqualObjects(managed.stringObj[@"key1"], @"bar");
    XCTAssertEqualObjects(optManaged.stringObj[@"key1"], @"bar");
    XCTAssertEqualObjects(unmanaged.dateObj[@"key1"], date(1));
    XCTAssertEqualObjects(optUnmanaged.dateObj[@"key1"], date(1));
    XCTAssertEqualObjects(managed.dateObj[@"key1"], date(1));
    XCTAssertEqualObjects(optManaged.dateObj[@"key1"], date(1));
    XCTAssertEqualObjects(unmanaged.floatObj[@"key1"], @2.2f);
    XCTAssertEqualObjects(optUnmanaged.floatObj[@"key1"], @2.2f);
    XCTAssertEqualObjects(managed.floatObj[@"key1"], @2.2f);
    XCTAssertEqualObjects(optManaged.floatObj[@"key1"], @2.2f);
    XCTAssertEqualObjects(unmanaged.doubleObj[@"key1"], @2.2);
    XCTAssertEqualObjects(optUnmanaged.doubleObj[@"key1"], @2.2);
    XCTAssertEqualObjects(managed.doubleObj[@"key1"], @2.2);
    XCTAssertEqualObjects(optManaged.doubleObj[@"key1"], @2.2);
    XCTAssertEqualObjects(unmanaged.dataObj[@"key1"], data(1));
    XCTAssertEqualObjects(optUnmanaged.dataObj[@"key1"], data(1));
    XCTAssertEqualObjects(managed.dataObj[@"key1"], data(1));
    XCTAssertEqualObjects(optManaged.dataObj[@"key1"], data(1));
    XCTAssertEqualObjects(unmanaged.decimalObj[@"key1"], decimal128(2));
    XCTAssertEqualObjects(optUnmanaged.decimalObj[@"key1"], decimal128(2));
    XCTAssertEqualObjects(managed.decimalObj[@"key1"], decimal128(2));
    XCTAssertEqualObjects(optManaged.decimalObj[@"key1"], decimal128(2));
    XCTAssertEqualObjects(unmanaged.objectIdObj[@"key1"], objectId(1));
    XCTAssertEqualObjects(optUnmanaged.objectIdObj[@"key1"], objectId(1));
    XCTAssertEqualObjects(managed.objectIdObj[@"key1"], objectId(1));
    XCTAssertEqualObjects(optManaged.objectIdObj[@"key1"], objectId(1));
    XCTAssertEqualObjects(unmanaged.uuidObj[@"key1"], uuid(@"00000000-0000-0000-0000-000000000000"));
    XCTAssertEqualObjects(optUnmanaged.uuidObj[@"key1"], uuid(@"00000000-0000-0000-0000-000000000000"));
    XCTAssertEqualObjects(managed.uuidObj[@"key1"], uuid(@"00000000-0000-0000-0000-000000000000"));
    XCTAssertEqualObjects(optManaged.uuidObj[@"key1"], uuid(@"00000000-0000-0000-0000-000000000000"));
    XCTAssertEqualObjects(unmanaged.anyBoolObj[@"key1"], @NO);
    XCTAssertEqualObjects(unmanaged.anyIntObj[@"key1"], @2);
    XCTAssertEqualObjects(unmanaged.anyFloatObj[@"key1"], @2.2f);
    XCTAssertEqualObjects(unmanaged.anyDoubleObj[@"key1"], @2.2);
    XCTAssertEqualObjects(unmanaged.anyStringObj[@"key1"], @"a");
    XCTAssertEqualObjects(unmanaged.anyDataObj[@"key1"], data(1));
    XCTAssertEqualObjects(unmanaged.anyDateObj[@"key1"], date(1));
    XCTAssertEqualObjects(unmanaged.anyDecimalObj[@"key1"], decimal128(2));
    XCTAssertEqualObjects(unmanaged.anyObjectIdObj[@"key1"], objectId(1));
    XCTAssertEqualObjects(unmanaged.anyUUIDObj[@"key1"], uuid(@"00000000-0000-0000-0000-000000000000"));
    XCTAssertEqualObjects(managed.anyBoolObj[@"key1"], @NO);
    XCTAssertEqualObjects(managed.anyIntObj[@"key1"], @2);
    XCTAssertEqualObjects(managed.anyFloatObj[@"key1"], @2.2f);
    XCTAssertEqualObjects(managed.anyDoubleObj[@"key1"], @2.2);
    XCTAssertEqualObjects(managed.anyStringObj[@"key1"], @"a");
    XCTAssertEqualObjects(managed.anyDataObj[@"key1"], data(1));
    XCTAssertEqualObjects(managed.anyDateObj[@"key1"], date(1));
    XCTAssertEqualObjects(managed.anyDecimalObj[@"key1"], decimal128(2));
    XCTAssertEqualObjects(managed.anyObjectIdObj[@"key1"], objectId(1));
    XCTAssertEqualObjects(managed.anyUUIDObj[@"key1"], uuid(@"00000000-0000-0000-0000-000000000000"));
    XCTAssertEqualObjects(unmanaged.boolObj[@"key2"], @YES);
    XCTAssertEqualObjects(optUnmanaged.boolObj[@"key2"], NSNull.null);
    XCTAssertEqualObjects(managed.boolObj[@"key2"], @YES);
    XCTAssertEqualObjects(optManaged.boolObj[@"key2"], NSNull.null);
    XCTAssertEqualObjects(unmanaged.intObj[@"key2"], @3);
    XCTAssertEqualObjects(optUnmanaged.intObj[@"key2"], NSNull.null);
    XCTAssertEqualObjects(managed.intObj[@"key2"], @3);
    XCTAssertEqualObjects(optManaged.intObj[@"key2"], NSNull.null);
    XCTAssertEqualObjects(unmanaged.stringObj[@"key2"], @"foo");
    XCTAssertEqualObjects(optUnmanaged.stringObj[@"key2"], NSNull.null);
    XCTAssertEqualObjects(managed.stringObj[@"key2"], @"foo");
    XCTAssertEqualObjects(optManaged.stringObj[@"key2"], NSNull.null);
    XCTAssertEqualObjects(unmanaged.dateObj[@"key2"], date(2));
    XCTAssertEqualObjects(optUnmanaged.dateObj[@"key2"], NSNull.null);
    XCTAssertEqualObjects(managed.dateObj[@"key2"], date(2));
    XCTAssertEqualObjects(optManaged.dateObj[@"key2"], NSNull.null);
    XCTAssertEqualObjects(unmanaged.floatObj[@"key2"], @3.3f);
    XCTAssertEqualObjects(optUnmanaged.floatObj[@"key2"], NSNull.null);
    XCTAssertEqualObjects(managed.floatObj[@"key2"], @3.3f);
    XCTAssertEqualObjects(optManaged.floatObj[@"key2"], NSNull.null);
    XCTAssertEqualObjects(unmanaged.doubleObj[@"key2"], @3.3);
    XCTAssertEqualObjects(optUnmanaged.doubleObj[@"key2"], NSNull.null);
    XCTAssertEqualObjects(managed.doubleObj[@"key2"], @3.3);
    XCTAssertEqualObjects(optManaged.doubleObj[@"key2"], NSNull.null);
    XCTAssertEqualObjects(unmanaged.dataObj[@"key2"], data(2));
    XCTAssertEqualObjects(optUnmanaged.dataObj[@"key2"], NSNull.null);
    XCTAssertEqualObjects(managed.dataObj[@"key2"], data(2));
    XCTAssertEqualObjects(optManaged.dataObj[@"key2"], NSNull.null);
    XCTAssertEqualObjects(unmanaged.decimalObj[@"key2"], decimal128(3));
    XCTAssertEqualObjects(optUnmanaged.decimalObj[@"key2"], NSNull.null);
    XCTAssertEqualObjects(managed.decimalObj[@"key2"], decimal128(3));
    XCTAssertEqualObjects(optManaged.decimalObj[@"key2"], NSNull.null);
    XCTAssertEqualObjects(unmanaged.objectIdObj[@"key2"], objectId(2));
    XCTAssertEqualObjects(optUnmanaged.objectIdObj[@"key2"], NSNull.null);
    XCTAssertEqualObjects(managed.objectIdObj[@"key2"], objectId(2));
    XCTAssertEqualObjects(optManaged.objectIdObj[@"key2"], NSNull.null);
    XCTAssertEqualObjects(unmanaged.uuidObj[@"key2"], uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"));
    XCTAssertEqualObjects(optUnmanaged.uuidObj[@"key2"], NSNull.null);
    XCTAssertEqualObjects(managed.uuidObj[@"key2"], uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"));
    XCTAssertEqualObjects(optManaged.uuidObj[@"key2"], NSNull.null);
    XCTAssertEqualObjects(unmanaged.anyBoolObj[@"key2"], @YES);
    XCTAssertEqualObjects(unmanaged.anyIntObj[@"key2"], @3);
    XCTAssertEqualObjects(unmanaged.anyFloatObj[@"key2"], @3.3f);
    XCTAssertEqualObjects(unmanaged.anyDoubleObj[@"key2"], @3.3);
    XCTAssertEqualObjects(unmanaged.anyStringObj[@"key2"], @"b");
    XCTAssertEqualObjects(unmanaged.anyDataObj[@"key2"], data(2));
    XCTAssertEqualObjects(unmanaged.anyDateObj[@"key2"], date(2));
    XCTAssertEqualObjects(unmanaged.anyDecimalObj[@"key2"], decimal128(3));
    XCTAssertEqualObjects(unmanaged.anyObjectIdObj[@"key2"], objectId(2));
    XCTAssertEqualObjects(unmanaged.anyUUIDObj[@"key2"], uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"));
    XCTAssertEqualObjects(managed.anyBoolObj[@"key2"], @YES);
    XCTAssertEqualObjects(managed.anyIntObj[@"key2"], @3);
    XCTAssertEqualObjects(managed.anyFloatObj[@"key2"], @3.3f);
    XCTAssertEqualObjects(managed.anyDoubleObj[@"key2"], @3.3);
    XCTAssertEqualObjects(managed.anyStringObj[@"key2"], @"b");
    XCTAssertEqualObjects(managed.anyDataObj[@"key2"], data(2));
    XCTAssertEqualObjects(managed.anyDateObj[@"key2"], date(2));
    XCTAssertEqualObjects(managed.anyDecimalObj[@"key2"], decimal128(3));
    XCTAssertEqualObjects(managed.anyObjectIdObj[@"key2"], objectId(2));
    XCTAssertEqualObjects(managed.anyUUIDObj[@"key2"], uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"));
    XCTAssertEqualObjects(optUnmanaged.boolObj[@"key2"], (id)NSNull.null);
    XCTAssertEqualObjects(optManaged.boolObj[@"key2"], (id)NSNull.null);
    XCTAssertEqualObjects(optUnmanaged.intObj[@"key2"], (id)NSNull.null);
    XCTAssertEqualObjects(optManaged.intObj[@"key2"], (id)NSNull.null);
    XCTAssertEqualObjects(optUnmanaged.stringObj[@"key2"], (id)NSNull.null);
    XCTAssertEqualObjects(optManaged.stringObj[@"key2"], (id)NSNull.null);
    XCTAssertEqualObjects(optUnmanaged.dateObj[@"key2"], (id)NSNull.null);
    XCTAssertEqualObjects(optManaged.dateObj[@"key2"], (id)NSNull.null);
    XCTAssertEqualObjects(optUnmanaged.floatObj[@"key2"], (id)NSNull.null);
    XCTAssertEqualObjects(optManaged.floatObj[@"key2"], (id)NSNull.null);
    XCTAssertEqualObjects(optUnmanaged.doubleObj[@"key2"], (id)NSNull.null);
    XCTAssertEqualObjects(optManaged.doubleObj[@"key2"], (id)NSNull.null);
    XCTAssertEqualObjects(optUnmanaged.dataObj[@"key2"], (id)NSNull.null);
    XCTAssertEqualObjects(optManaged.dataObj[@"key2"], (id)NSNull.null);
    XCTAssertEqualObjects(optUnmanaged.decimalObj[@"key2"], (id)NSNull.null);
    XCTAssertEqualObjects(optManaged.decimalObj[@"key2"], (id)NSNull.null);
    XCTAssertEqualObjects(optUnmanaged.objectIdObj[@"key2"], (id)NSNull.null);
    XCTAssertEqualObjects(optManaged.objectIdObj[@"key2"], (id)NSNull.null);
    XCTAssertEqualObjects(optUnmanaged.uuidObj[@"key2"], (id)NSNull.null);
    XCTAssertEqualObjects(optManaged.uuidObj[@"key2"], (id)NSNull.null);
}

- (void)testRemoveObject {
    [self addObjects];
    XCTAssertEqual(unmanaged.boolObj.count, 2U);
    XCTAssertEqual(managed.boolObj.count, 2U);
    XCTAssertEqual(unmanaged.intObj.count, 2U);
    XCTAssertEqual(managed.intObj.count, 2U);
    XCTAssertEqual(unmanaged.stringObj.count, 2U);
    XCTAssertEqual(managed.stringObj.count, 2U);
    XCTAssertEqual(unmanaged.dateObj.count, 2U);
    XCTAssertEqual(managed.dateObj.count, 2U);
    XCTAssertEqual(unmanaged.floatObj.count, 2U);
    XCTAssertEqual(managed.floatObj.count, 2U);
    XCTAssertEqual(unmanaged.doubleObj.count, 2U);
    XCTAssertEqual(managed.doubleObj.count, 2U);
    XCTAssertEqual(unmanaged.dataObj.count, 2U);
    XCTAssertEqual(managed.dataObj.count, 2U);
    XCTAssertEqual(unmanaged.decimalObj.count, 2U);
    XCTAssertEqual(managed.decimalObj.count, 2U);
    XCTAssertEqual(unmanaged.objectIdObj.count, 2U);
    XCTAssertEqual(managed.objectIdObj.count, 2U);
    XCTAssertEqual(unmanaged.uuidObj.count, 2U);
    XCTAssertEqual(managed.uuidObj.count, 2U);
    XCTAssertEqual(unmanaged.anyBoolObj.count, 2U);
    XCTAssertEqual(unmanaged.anyIntObj.count, 2U);
    XCTAssertEqual(unmanaged.anyFloatObj.count, 2U);
    XCTAssertEqual(unmanaged.anyDoubleObj.count, 2U);
    XCTAssertEqual(unmanaged.anyStringObj.count, 2U);
    XCTAssertEqual(unmanaged.anyDataObj.count, 2U);
    XCTAssertEqual(unmanaged.anyDateObj.count, 2U);
    XCTAssertEqual(unmanaged.anyDecimalObj.count, 2U);
    XCTAssertEqual(unmanaged.anyObjectIdObj.count, 2U);
    XCTAssertEqual(unmanaged.anyUUIDObj.count, 2U);
    XCTAssertEqual(managed.anyBoolObj.count, 2U);
    XCTAssertEqual(managed.anyIntObj.count, 2U);
    XCTAssertEqual(managed.anyFloatObj.count, 2U);
    XCTAssertEqual(managed.anyDoubleObj.count, 2U);
    XCTAssertEqual(managed.anyStringObj.count, 2U);
    XCTAssertEqual(managed.anyDataObj.count, 2U);
    XCTAssertEqual(managed.anyDateObj.count, 2U);
    XCTAssertEqual(managed.anyDecimalObj.count, 2U);
    XCTAssertEqual(managed.anyObjectIdObj.count, 2U);
    XCTAssertEqual(managed.anyUUIDObj.count, 2U);
    XCTAssertEqual(optUnmanaged.boolObj.count, 2U);
    XCTAssertEqual(optManaged.boolObj.count, 2U);
    XCTAssertEqual(optUnmanaged.intObj.count, 2U);
    XCTAssertEqual(optManaged.intObj.count, 2U);
    XCTAssertEqual(optUnmanaged.stringObj.count, 2U);
    XCTAssertEqual(optManaged.stringObj.count, 2U);
    XCTAssertEqual(optUnmanaged.dateObj.count, 2U);
    XCTAssertEqual(optManaged.dateObj.count, 2U);
    XCTAssertEqual(optUnmanaged.floatObj.count, 2U);
    XCTAssertEqual(optManaged.floatObj.count, 2U);
    XCTAssertEqual(optUnmanaged.doubleObj.count, 2U);
    XCTAssertEqual(optManaged.doubleObj.count, 2U);
    XCTAssertEqual(optUnmanaged.dataObj.count, 2U);
    XCTAssertEqual(optManaged.dataObj.count, 2U);
    XCTAssertEqual(optUnmanaged.decimalObj.count, 2U);
    XCTAssertEqual(optManaged.decimalObj.count, 2U);
    XCTAssertEqual(optUnmanaged.objectIdObj.count, 2U);
    XCTAssertEqual(optManaged.objectIdObj.count, 2U);
    XCTAssertEqual(optUnmanaged.uuidObj.count, 2U);
    XCTAssertEqual(optManaged.uuidObj.count, 2U);

    XCTAssertEqualObjects(unmanaged.boolObj[@"key1"], @NO);
    XCTAssertEqualObjects(optUnmanaged.boolObj[@"key1"], @NO);
    XCTAssertEqualObjects(managed.boolObj[@"key1"], @NO);
    XCTAssertEqualObjects(optManaged.boolObj[@"key1"], @NO);
    XCTAssertEqualObjects(unmanaged.intObj[@"key1"], @2);
    XCTAssertEqualObjects(optUnmanaged.intObj[@"key1"], @2);
    XCTAssertEqualObjects(managed.intObj[@"key1"], @2);
    XCTAssertEqualObjects(optManaged.intObj[@"key1"], @2);
    XCTAssertEqualObjects(unmanaged.stringObj[@"key1"], @"bar");
    XCTAssertEqualObjects(optUnmanaged.stringObj[@"key1"], @"bar");
    XCTAssertEqualObjects(managed.stringObj[@"key1"], @"bar");
    XCTAssertEqualObjects(optManaged.stringObj[@"key1"], @"bar");
    XCTAssertEqualObjects(unmanaged.dateObj[@"key1"], date(1));
    XCTAssertEqualObjects(optUnmanaged.dateObj[@"key1"], date(1));
    XCTAssertEqualObjects(managed.dateObj[@"key1"], date(1));
    XCTAssertEqualObjects(optManaged.dateObj[@"key1"], date(1));
    XCTAssertEqualObjects(unmanaged.floatObj[@"key1"], @2.2f);
    XCTAssertEqualObjects(optUnmanaged.floatObj[@"key1"], @2.2f);
    XCTAssertEqualObjects(managed.floatObj[@"key1"], @2.2f);
    XCTAssertEqualObjects(optManaged.floatObj[@"key1"], @2.2f);
    XCTAssertEqualObjects(unmanaged.doubleObj[@"key1"], @2.2);
    XCTAssertEqualObjects(optUnmanaged.doubleObj[@"key1"], @2.2);
    XCTAssertEqualObjects(managed.doubleObj[@"key1"], @2.2);
    XCTAssertEqualObjects(optManaged.doubleObj[@"key1"], @2.2);
    XCTAssertEqualObjects(unmanaged.dataObj[@"key1"], data(1));
    XCTAssertEqualObjects(optUnmanaged.dataObj[@"key1"], data(1));
    XCTAssertEqualObjects(managed.dataObj[@"key1"], data(1));
    XCTAssertEqualObjects(optManaged.dataObj[@"key1"], data(1));
    XCTAssertEqualObjects(unmanaged.decimalObj[@"key1"], decimal128(2));
    XCTAssertEqualObjects(optUnmanaged.decimalObj[@"key1"], decimal128(2));
    XCTAssertEqualObjects(managed.decimalObj[@"key1"], decimal128(2));
    XCTAssertEqualObjects(optManaged.decimalObj[@"key1"], decimal128(2));
    XCTAssertEqualObjects(unmanaged.objectIdObj[@"key1"], objectId(1));
    XCTAssertEqualObjects(optUnmanaged.objectIdObj[@"key1"], objectId(1));
    XCTAssertEqualObjects(managed.objectIdObj[@"key1"], objectId(1));
    XCTAssertEqualObjects(optManaged.objectIdObj[@"key1"], objectId(1));
    XCTAssertEqualObjects(unmanaged.uuidObj[@"key1"], uuid(@"00000000-0000-0000-0000-000000000000"));
    XCTAssertEqualObjects(optUnmanaged.uuidObj[@"key1"], uuid(@"00000000-0000-0000-0000-000000000000"));
    XCTAssertEqualObjects(managed.uuidObj[@"key1"], uuid(@"00000000-0000-0000-0000-000000000000"));
    XCTAssertEqualObjects(optManaged.uuidObj[@"key1"], uuid(@"00000000-0000-0000-0000-000000000000"));
    XCTAssertEqualObjects(unmanaged.anyBoolObj[@"key1"], @NO);
    XCTAssertEqualObjects(unmanaged.anyIntObj[@"key1"], @2);
    XCTAssertEqualObjects(unmanaged.anyFloatObj[@"key1"], @2.2f);
    XCTAssertEqualObjects(unmanaged.anyDoubleObj[@"key1"], @2.2);
    XCTAssertEqualObjects(unmanaged.anyStringObj[@"key1"], @"a");
    XCTAssertEqualObjects(unmanaged.anyDataObj[@"key1"], data(1));
    XCTAssertEqualObjects(unmanaged.anyDateObj[@"key1"], date(1));
    XCTAssertEqualObjects(unmanaged.anyDecimalObj[@"key1"], decimal128(2));
    XCTAssertEqualObjects(unmanaged.anyObjectIdObj[@"key1"], objectId(1));
    XCTAssertEqualObjects(unmanaged.anyUUIDObj[@"key1"], uuid(@"00000000-0000-0000-0000-000000000000"));
    XCTAssertEqualObjects(managed.anyBoolObj[@"key1"], @NO);
    XCTAssertEqualObjects(managed.anyIntObj[@"key1"], @2);
    XCTAssertEqualObjects(managed.anyFloatObj[@"key1"], @2.2f);
    XCTAssertEqualObjects(managed.anyDoubleObj[@"key1"], @2.2);
    XCTAssertEqualObjects(managed.anyStringObj[@"key1"], @"a");
    XCTAssertEqualObjects(managed.anyDataObj[@"key1"], data(1));
    XCTAssertEqualObjects(managed.anyDateObj[@"key1"], date(1));
    XCTAssertEqualObjects(managed.anyDecimalObj[@"key1"], decimal128(2));
    XCTAssertEqualObjects(managed.anyObjectIdObj[@"key1"], objectId(1));
    XCTAssertEqualObjects(managed.anyUUIDObj[@"key1"], uuid(@"00000000-0000-0000-0000-000000000000"));

    [unmanaged.boolObj removeObjectForKey:@"key1"];
    [optUnmanaged.boolObj removeObjectForKey:@"key1"];
    [managed.boolObj removeObjectForKey:@"key1"];
    [optManaged.boolObj removeObjectForKey:@"key1"];
    [unmanaged.intObj removeObjectForKey:@"key1"];
    [optUnmanaged.intObj removeObjectForKey:@"key1"];
    [managed.intObj removeObjectForKey:@"key1"];
    [optManaged.intObj removeObjectForKey:@"key1"];
    [unmanaged.stringObj removeObjectForKey:@"key1"];
    [optUnmanaged.stringObj removeObjectForKey:@"key1"];
    [managed.stringObj removeObjectForKey:@"key1"];
    [optManaged.stringObj removeObjectForKey:@"key1"];
    [unmanaged.dateObj removeObjectForKey:@"key1"];
    [optUnmanaged.dateObj removeObjectForKey:@"key1"];
    [managed.dateObj removeObjectForKey:@"key1"];
    [optManaged.dateObj removeObjectForKey:@"key1"];
    [unmanaged.floatObj removeObjectForKey:@"key1"];
    [optUnmanaged.floatObj removeObjectForKey:@"key1"];
    [managed.floatObj removeObjectForKey:@"key1"];
    [optManaged.floatObj removeObjectForKey:@"key1"];
    [unmanaged.doubleObj removeObjectForKey:@"key1"];
    [optUnmanaged.doubleObj removeObjectForKey:@"key1"];
    [managed.doubleObj removeObjectForKey:@"key1"];
    [optManaged.doubleObj removeObjectForKey:@"key1"];
    [unmanaged.dataObj removeObjectForKey:@"key1"];
    [optUnmanaged.dataObj removeObjectForKey:@"key1"];
    [managed.dataObj removeObjectForKey:@"key1"];
    [optManaged.dataObj removeObjectForKey:@"key1"];
    [unmanaged.decimalObj removeObjectForKey:@"key1"];
    [optUnmanaged.decimalObj removeObjectForKey:@"key1"];
    [managed.decimalObj removeObjectForKey:@"key1"];
    [optManaged.decimalObj removeObjectForKey:@"key1"];
    [unmanaged.objectIdObj removeObjectForKey:@"key1"];
    [optUnmanaged.objectIdObj removeObjectForKey:@"key1"];
    [managed.objectIdObj removeObjectForKey:@"key1"];
    [optManaged.objectIdObj removeObjectForKey:@"key1"];
    [unmanaged.uuidObj removeObjectForKey:@"key1"];
    [optUnmanaged.uuidObj removeObjectForKey:@"key1"];
    [managed.uuidObj removeObjectForKey:@"key1"];
    [optManaged.uuidObj removeObjectForKey:@"key1"];
    [unmanaged.anyBoolObj removeObjectForKey:@"key1"];
    [unmanaged.anyIntObj removeObjectForKey:@"key1"];
    [unmanaged.anyFloatObj removeObjectForKey:@"key1"];
    [unmanaged.anyDoubleObj removeObjectForKey:@"key1"];
    [unmanaged.anyStringObj removeObjectForKey:@"key1"];
    [unmanaged.anyDataObj removeObjectForKey:@"key1"];
    [unmanaged.anyDateObj removeObjectForKey:@"key1"];
    [unmanaged.anyDecimalObj removeObjectForKey:@"key1"];
    [unmanaged.anyObjectIdObj removeObjectForKey:@"key1"];
    [unmanaged.anyUUIDObj removeObjectForKey:@"key1"];
    [managed.anyBoolObj removeObjectForKey:@"key1"];
    [managed.anyIntObj removeObjectForKey:@"key1"];
    [managed.anyFloatObj removeObjectForKey:@"key1"];
    [managed.anyDoubleObj removeObjectForKey:@"key1"];
    [managed.anyStringObj removeObjectForKey:@"key1"];
    [managed.anyDataObj removeObjectForKey:@"key1"];
    [managed.anyDateObj removeObjectForKey:@"key1"];
    [managed.anyDecimalObj removeObjectForKey:@"key1"];
    [managed.anyObjectIdObj removeObjectForKey:@"key1"];
    [managed.anyUUIDObj removeObjectForKey:@"key1"];

    XCTAssertEqual(unmanaged.boolObj.count, 1U);
    XCTAssertEqual(managed.boolObj.count, 1U);
    XCTAssertEqual(unmanaged.intObj.count, 1U);
    XCTAssertEqual(managed.intObj.count, 1U);
    XCTAssertEqual(unmanaged.stringObj.count, 1U);
    XCTAssertEqual(managed.stringObj.count, 1U);
    XCTAssertEqual(unmanaged.dateObj.count, 1U);
    XCTAssertEqual(managed.dateObj.count, 1U);
    XCTAssertEqual(unmanaged.floatObj.count, 1U);
    XCTAssertEqual(managed.floatObj.count, 1U);
    XCTAssertEqual(unmanaged.doubleObj.count, 1U);
    XCTAssertEqual(managed.doubleObj.count, 1U);
    XCTAssertEqual(unmanaged.dataObj.count, 1U);
    XCTAssertEqual(managed.dataObj.count, 1U);
    XCTAssertEqual(unmanaged.decimalObj.count, 1U);
    XCTAssertEqual(managed.decimalObj.count, 1U);
    XCTAssertEqual(unmanaged.objectIdObj.count, 1U);
    XCTAssertEqual(managed.objectIdObj.count, 1U);
    XCTAssertEqual(unmanaged.uuidObj.count, 1U);
    XCTAssertEqual(managed.uuidObj.count, 1U);
    XCTAssertEqual(unmanaged.anyBoolObj.count, 1U);
    XCTAssertEqual(unmanaged.anyIntObj.count, 1U);
    XCTAssertEqual(unmanaged.anyFloatObj.count, 1U);
    XCTAssertEqual(unmanaged.anyDoubleObj.count, 1U);
    XCTAssertEqual(unmanaged.anyStringObj.count, 1U);
    XCTAssertEqual(unmanaged.anyDataObj.count, 1U);
    XCTAssertEqual(unmanaged.anyDateObj.count, 1U);
    XCTAssertEqual(unmanaged.anyDecimalObj.count, 1U);
    XCTAssertEqual(unmanaged.anyObjectIdObj.count, 1U);
    XCTAssertEqual(unmanaged.anyUUIDObj.count, 1U);
    XCTAssertEqual(managed.anyBoolObj.count, 1U);
    XCTAssertEqual(managed.anyIntObj.count, 1U);
    XCTAssertEqual(managed.anyFloatObj.count, 1U);
    XCTAssertEqual(managed.anyDoubleObj.count, 1U);
    XCTAssertEqual(managed.anyStringObj.count, 1U);
    XCTAssertEqual(managed.anyDataObj.count, 1U);
    XCTAssertEqual(managed.anyDateObj.count, 1U);
    XCTAssertEqual(managed.anyDecimalObj.count, 1U);
    XCTAssertEqual(managed.anyObjectIdObj.count, 1U);
    XCTAssertEqual(managed.anyUUIDObj.count, 1U);
    XCTAssertEqual(optUnmanaged.boolObj.count, 1U);
    XCTAssertEqual(optManaged.boolObj.count, 1U);
    XCTAssertEqual(optUnmanaged.intObj.count, 1U);
    XCTAssertEqual(optManaged.intObj.count, 1U);
    XCTAssertEqual(optUnmanaged.stringObj.count, 1U);
    XCTAssertEqual(optManaged.stringObj.count, 1U);
    XCTAssertEqual(optUnmanaged.dateObj.count, 1U);
    XCTAssertEqual(optManaged.dateObj.count, 1U);
    XCTAssertEqual(optUnmanaged.floatObj.count, 1U);
    XCTAssertEqual(optManaged.floatObj.count, 1U);
    XCTAssertEqual(optUnmanaged.doubleObj.count, 1U);
    XCTAssertEqual(optManaged.doubleObj.count, 1U);
    XCTAssertEqual(optUnmanaged.dataObj.count, 1U);
    XCTAssertEqual(optManaged.dataObj.count, 1U);
    XCTAssertEqual(optUnmanaged.decimalObj.count, 1U);
    XCTAssertEqual(optManaged.decimalObj.count, 1U);
    XCTAssertEqual(optUnmanaged.objectIdObj.count, 1U);
    XCTAssertEqual(optManaged.objectIdObj.count, 1U);
    XCTAssertEqual(optUnmanaged.uuidObj.count, 1U);
    XCTAssertEqual(optManaged.uuidObj.count, 1U);

    XCTAssertNil(unmanaged.boolObj[@"key1"]);
    XCTAssertNil(optUnmanaged.boolObj[@"key1"]);
    XCTAssertNil(managed.boolObj[@"key1"]);
    XCTAssertNil(optManaged.boolObj[@"key1"]);
    XCTAssertNil(unmanaged.intObj[@"key1"]);
    XCTAssertNil(optUnmanaged.intObj[@"key1"]);
    XCTAssertNil(managed.intObj[@"key1"]);
    XCTAssertNil(optManaged.intObj[@"key1"]);
    XCTAssertNil(unmanaged.stringObj[@"key1"]);
    XCTAssertNil(optUnmanaged.stringObj[@"key1"]);
    XCTAssertNil(managed.stringObj[@"key1"]);
    XCTAssertNil(optManaged.stringObj[@"key1"]);
    XCTAssertNil(unmanaged.dateObj[@"key1"]);
    XCTAssertNil(optUnmanaged.dateObj[@"key1"]);
    XCTAssertNil(managed.dateObj[@"key1"]);
    XCTAssertNil(optManaged.dateObj[@"key1"]);
    XCTAssertNil(unmanaged.floatObj[@"key1"]);
    XCTAssertNil(optUnmanaged.floatObj[@"key1"]);
    XCTAssertNil(managed.floatObj[@"key1"]);
    XCTAssertNil(optManaged.floatObj[@"key1"]);
    XCTAssertNil(unmanaged.doubleObj[@"key1"]);
    XCTAssertNil(optUnmanaged.doubleObj[@"key1"]);
    XCTAssertNil(managed.doubleObj[@"key1"]);
    XCTAssertNil(optManaged.doubleObj[@"key1"]);
    XCTAssertNil(unmanaged.dataObj[@"key1"]);
    XCTAssertNil(optUnmanaged.dataObj[@"key1"]);
    XCTAssertNil(managed.dataObj[@"key1"]);
    XCTAssertNil(optManaged.dataObj[@"key1"]);
    XCTAssertNil(unmanaged.decimalObj[@"key1"]);
    XCTAssertNil(optUnmanaged.decimalObj[@"key1"]);
    XCTAssertNil(managed.decimalObj[@"key1"]);
    XCTAssertNil(optManaged.decimalObj[@"key1"]);
    XCTAssertNil(unmanaged.objectIdObj[@"key1"]);
    XCTAssertNil(optUnmanaged.objectIdObj[@"key1"]);
    XCTAssertNil(managed.objectIdObj[@"key1"]);
    XCTAssertNil(optManaged.objectIdObj[@"key1"]);
    XCTAssertNil(unmanaged.uuidObj[@"key1"]);
    XCTAssertNil(optUnmanaged.uuidObj[@"key1"]);
    XCTAssertNil(managed.uuidObj[@"key1"]);
    XCTAssertNil(optManaged.uuidObj[@"key1"]);
    XCTAssertNil(unmanaged.anyBoolObj[@"key1"]);
    XCTAssertNil(unmanaged.anyIntObj[@"key1"]);
    XCTAssertNil(unmanaged.anyFloatObj[@"key1"]);
    XCTAssertNil(unmanaged.anyDoubleObj[@"key1"]);
    XCTAssertNil(unmanaged.anyStringObj[@"key1"]);
    XCTAssertNil(unmanaged.anyDataObj[@"key1"]);
    XCTAssertNil(unmanaged.anyDateObj[@"key1"]);
    XCTAssertNil(unmanaged.anyDecimalObj[@"key1"]);
    XCTAssertNil(unmanaged.anyObjectIdObj[@"key1"]);
    XCTAssertNil(unmanaged.anyUUIDObj[@"key1"]);
    XCTAssertNil(managed.anyBoolObj[@"key1"]);
    XCTAssertNil(managed.anyIntObj[@"key1"]);
    XCTAssertNil(managed.anyFloatObj[@"key1"]);
    XCTAssertNil(managed.anyDoubleObj[@"key1"]);
    XCTAssertNil(managed.anyStringObj[@"key1"]);
    XCTAssertNil(managed.anyDataObj[@"key1"]);
    XCTAssertNil(managed.anyDateObj[@"key1"]);
    XCTAssertNil(managed.anyDecimalObj[@"key1"]);
    XCTAssertNil(managed.anyObjectIdObj[@"key1"]);
    XCTAssertNil(managed.anyUUIDObj[@"key1"]);
}

- (void)testRemoveObjects {
    [self addObjects];
    XCTAssertEqual(unmanaged.boolObj.count, 2U);
    XCTAssertEqual(optUnmanaged.boolObj.count, 2U);
    XCTAssertEqual(managed.boolObj.count, 2U);
    XCTAssertEqual(optManaged.boolObj.count, 2U);
    XCTAssertEqual(unmanaged.intObj.count, 2U);
    XCTAssertEqual(optUnmanaged.intObj.count, 2U);
    XCTAssertEqual(managed.intObj.count, 2U);
    XCTAssertEqual(optManaged.intObj.count, 2U);
    XCTAssertEqual(unmanaged.stringObj.count, 2U);
    XCTAssertEqual(optUnmanaged.stringObj.count, 2U);
    XCTAssertEqual(managed.stringObj.count, 2U);
    XCTAssertEqual(optManaged.stringObj.count, 2U);
    XCTAssertEqual(unmanaged.dateObj.count, 2U);
    XCTAssertEqual(optUnmanaged.dateObj.count, 2U);
    XCTAssertEqual(managed.dateObj.count, 2U);
    XCTAssertEqual(optManaged.dateObj.count, 2U);
    XCTAssertEqual(unmanaged.floatObj.count, 2U);
    XCTAssertEqual(optUnmanaged.floatObj.count, 2U);
    XCTAssertEqual(managed.floatObj.count, 2U);
    XCTAssertEqual(optManaged.floatObj.count, 2U);
    XCTAssertEqual(unmanaged.doubleObj.count, 2U);
    XCTAssertEqual(optUnmanaged.doubleObj.count, 2U);
    XCTAssertEqual(managed.doubleObj.count, 2U);
    XCTAssertEqual(optManaged.doubleObj.count, 2U);
    XCTAssertEqual(unmanaged.dataObj.count, 2U);
    XCTAssertEqual(optUnmanaged.dataObj.count, 2U);
    XCTAssertEqual(managed.dataObj.count, 2U);
    XCTAssertEqual(optManaged.dataObj.count, 2U);
    XCTAssertEqual(unmanaged.decimalObj.count, 2U);
    XCTAssertEqual(optUnmanaged.decimalObj.count, 2U);
    XCTAssertEqual(managed.decimalObj.count, 2U);
    XCTAssertEqual(optManaged.decimalObj.count, 2U);
    XCTAssertEqual(unmanaged.objectIdObj.count, 2U);
    XCTAssertEqual(optUnmanaged.objectIdObj.count, 2U);
    XCTAssertEqual(managed.objectIdObj.count, 2U);
    XCTAssertEqual(optManaged.objectIdObj.count, 2U);
    XCTAssertEqual(unmanaged.uuidObj.count, 2U);
    XCTAssertEqual(optUnmanaged.uuidObj.count, 2U);
    XCTAssertEqual(managed.uuidObj.count, 2U);
    XCTAssertEqual(optManaged.uuidObj.count, 2U);
    XCTAssertEqual(unmanaged.anyBoolObj.count, 2U);
    XCTAssertEqual(unmanaged.anyIntObj.count, 2U);
    XCTAssertEqual(unmanaged.anyFloatObj.count, 2U);
    XCTAssertEqual(unmanaged.anyDoubleObj.count, 2U);
    XCTAssertEqual(unmanaged.anyStringObj.count, 2U);
    XCTAssertEqual(unmanaged.anyDataObj.count, 2U);
    XCTAssertEqual(unmanaged.anyDateObj.count, 2U);
    XCTAssertEqual(unmanaged.anyDecimalObj.count, 2U);
    XCTAssertEqual(unmanaged.anyObjectIdObj.count, 2U);
    XCTAssertEqual(unmanaged.anyUUIDObj.count, 2U);
    XCTAssertEqual(managed.anyBoolObj.count, 2U);
    XCTAssertEqual(managed.anyIntObj.count, 2U);
    XCTAssertEqual(managed.anyFloatObj.count, 2U);
    XCTAssertEqual(managed.anyDoubleObj.count, 2U);
    XCTAssertEqual(managed.anyStringObj.count, 2U);
    XCTAssertEqual(managed.anyDataObj.count, 2U);
    XCTAssertEqual(managed.anyDateObj.count, 2U);
    XCTAssertEqual(managed.anyDecimalObj.count, 2U);
    XCTAssertEqual(managed.anyObjectIdObj.count, 2U);
    XCTAssertEqual(managed.anyUUIDObj.count, 2U);

    XCTAssertEqualObjects(unmanaged.boolObj[@"key1"], @NO);
    XCTAssertEqualObjects(optUnmanaged.boolObj[@"key1"], @NO);
    XCTAssertEqualObjects(managed.boolObj[@"key1"], @NO);
    XCTAssertEqualObjects(optManaged.boolObj[@"key1"], @NO);
    XCTAssertEqualObjects(unmanaged.intObj[@"key1"], @2);
    XCTAssertEqualObjects(optUnmanaged.intObj[@"key1"], @2);
    XCTAssertEqualObjects(managed.intObj[@"key1"], @2);
    XCTAssertEqualObjects(optManaged.intObj[@"key1"], @2);
    XCTAssertEqualObjects(unmanaged.stringObj[@"key1"], @"bar");
    XCTAssertEqualObjects(optUnmanaged.stringObj[@"key1"], @"bar");
    XCTAssertEqualObjects(managed.stringObj[@"key1"], @"bar");
    XCTAssertEqualObjects(optManaged.stringObj[@"key1"], @"bar");
    XCTAssertEqualObjects(unmanaged.dateObj[@"key1"], date(1));
    XCTAssertEqualObjects(optUnmanaged.dateObj[@"key1"], date(1));
    XCTAssertEqualObjects(managed.dateObj[@"key1"], date(1));
    XCTAssertEqualObjects(optManaged.dateObj[@"key1"], date(1));
    XCTAssertEqualObjects(unmanaged.floatObj[@"key1"], @2.2f);
    XCTAssertEqualObjects(optUnmanaged.floatObj[@"key1"], @2.2f);
    XCTAssertEqualObjects(managed.floatObj[@"key1"], @2.2f);
    XCTAssertEqualObjects(optManaged.floatObj[@"key1"], @2.2f);
    XCTAssertEqualObjects(unmanaged.doubleObj[@"key1"], @2.2);
    XCTAssertEqualObjects(optUnmanaged.doubleObj[@"key1"], @2.2);
    XCTAssertEqualObjects(managed.doubleObj[@"key1"], @2.2);
    XCTAssertEqualObjects(optManaged.doubleObj[@"key1"], @2.2);
    XCTAssertEqualObjects(unmanaged.dataObj[@"key1"], data(1));
    XCTAssertEqualObjects(optUnmanaged.dataObj[@"key1"], data(1));
    XCTAssertEqualObjects(managed.dataObj[@"key1"], data(1));
    XCTAssertEqualObjects(optManaged.dataObj[@"key1"], data(1));
    XCTAssertEqualObjects(unmanaged.decimalObj[@"key1"], decimal128(2));
    XCTAssertEqualObjects(optUnmanaged.decimalObj[@"key1"], decimal128(2));
    XCTAssertEqualObjects(managed.decimalObj[@"key1"], decimal128(2));
    XCTAssertEqualObjects(optManaged.decimalObj[@"key1"], decimal128(2));
    XCTAssertEqualObjects(unmanaged.objectIdObj[@"key1"], objectId(1));
    XCTAssertEqualObjects(optUnmanaged.objectIdObj[@"key1"], objectId(1));
    XCTAssertEqualObjects(managed.objectIdObj[@"key1"], objectId(1));
    XCTAssertEqualObjects(optManaged.objectIdObj[@"key1"], objectId(1));
    XCTAssertEqualObjects(unmanaged.uuidObj[@"key1"], uuid(@"00000000-0000-0000-0000-000000000000"));
    XCTAssertEqualObjects(optUnmanaged.uuidObj[@"key1"], uuid(@"00000000-0000-0000-0000-000000000000"));
    XCTAssertEqualObjects(managed.uuidObj[@"key1"], uuid(@"00000000-0000-0000-0000-000000000000"));
    XCTAssertEqualObjects(optManaged.uuidObj[@"key1"], uuid(@"00000000-0000-0000-0000-000000000000"));
    XCTAssertEqualObjects(unmanaged.anyBoolObj[@"key1"], @NO);
    XCTAssertEqualObjects(unmanaged.anyIntObj[@"key1"], @2);
    XCTAssertEqualObjects(unmanaged.anyFloatObj[@"key1"], @2.2f);
    XCTAssertEqualObjects(unmanaged.anyDoubleObj[@"key1"], @2.2);
    XCTAssertEqualObjects(unmanaged.anyStringObj[@"key1"], @"a");
    XCTAssertEqualObjects(unmanaged.anyDataObj[@"key1"], data(1));
    XCTAssertEqualObjects(unmanaged.anyDateObj[@"key1"], date(1));
    XCTAssertEqualObjects(unmanaged.anyDecimalObj[@"key1"], decimal128(2));
    XCTAssertEqualObjects(unmanaged.anyObjectIdObj[@"key1"], objectId(1));
    XCTAssertEqualObjects(unmanaged.anyUUIDObj[@"key1"], uuid(@"00000000-0000-0000-0000-000000000000"));
    XCTAssertEqualObjects(managed.anyBoolObj[@"key1"], @NO);
    XCTAssertEqualObjects(managed.anyIntObj[@"key1"], @2);
    XCTAssertEqualObjects(managed.anyFloatObj[@"key1"], @2.2f);
    XCTAssertEqualObjects(managed.anyDoubleObj[@"key1"], @2.2);
    XCTAssertEqualObjects(managed.anyStringObj[@"key1"], @"a");
    XCTAssertEqualObjects(managed.anyDataObj[@"key1"], data(1));
    XCTAssertEqualObjects(managed.anyDateObj[@"key1"], date(1));
    XCTAssertEqualObjects(managed.anyDecimalObj[@"key1"], decimal128(2));
    XCTAssertEqualObjects(managed.anyObjectIdObj[@"key1"], objectId(1));
    XCTAssertEqualObjects(managed.anyUUIDObj[@"key1"], uuid(@"00000000-0000-0000-0000-000000000000"));

    [unmanaged.boolObj removeObjectsForKeys:@[@"key1", @"key2"]];
    [optUnmanaged.boolObj removeObjectsForKeys:@[@"key1", @"key2"]];
    [managed.boolObj removeObjectsForKeys:@[@"key1", @"key2"]];
    [optManaged.boolObj removeObjectsForKeys:@[@"key1", @"key2"]];
    [unmanaged.intObj removeObjectsForKeys:@[@"key1", @"key2"]];
    [optUnmanaged.intObj removeObjectsForKeys:@[@"key1", @"key2"]];
    [managed.intObj removeObjectsForKeys:@[@"key1", @"key2"]];
    [optManaged.intObj removeObjectsForKeys:@[@"key1", @"key2"]];
    [unmanaged.stringObj removeObjectsForKeys:@[@"key1", @"key2"]];
    [optUnmanaged.stringObj removeObjectsForKeys:@[@"key1", @"key2"]];
    [managed.stringObj removeObjectsForKeys:@[@"key1", @"key2"]];
    [optManaged.stringObj removeObjectsForKeys:@[@"key1", @"key2"]];
    [unmanaged.dateObj removeObjectsForKeys:@[@"key1", @"key2"]];
    [optUnmanaged.dateObj removeObjectsForKeys:@[@"key1", @"key2"]];
    [managed.dateObj removeObjectsForKeys:@[@"key1", @"key2"]];
    [optManaged.dateObj removeObjectsForKeys:@[@"key1", @"key2"]];
    [unmanaged.floatObj removeObjectsForKeys:@[@"key1", @"key2"]];
    [optUnmanaged.floatObj removeObjectsForKeys:@[@"key1", @"key2"]];
    [managed.floatObj removeObjectsForKeys:@[@"key1", @"key2"]];
    [optManaged.floatObj removeObjectsForKeys:@[@"key1", @"key2"]];
    [unmanaged.doubleObj removeObjectsForKeys:@[@"key1", @"key2"]];
    [optUnmanaged.doubleObj removeObjectsForKeys:@[@"key1", @"key2"]];
    [managed.doubleObj removeObjectsForKeys:@[@"key1", @"key2"]];
    [optManaged.doubleObj removeObjectsForKeys:@[@"key1", @"key2"]];
    [unmanaged.dataObj removeObjectsForKeys:@[@"key1", @"key2"]];
    [optUnmanaged.dataObj removeObjectsForKeys:@[@"key1", @"key2"]];
    [managed.dataObj removeObjectsForKeys:@[@"key1", @"key2"]];
    [optManaged.dataObj removeObjectsForKeys:@[@"key1", @"key2"]];
    [unmanaged.decimalObj removeObjectsForKeys:@[@"key1", @"key2"]];
    [optUnmanaged.decimalObj removeObjectsForKeys:@[@"key1", @"key2"]];
    [managed.decimalObj removeObjectsForKeys:@[@"key1", @"key2"]];
    [optManaged.decimalObj removeObjectsForKeys:@[@"key1", @"key2"]];
    [unmanaged.objectIdObj removeObjectsForKeys:@[@"key1", @"key2"]];
    [optUnmanaged.objectIdObj removeObjectsForKeys:@[@"key1", @"key2"]];
    [managed.objectIdObj removeObjectsForKeys:@[@"key1", @"key2"]];
    [optManaged.objectIdObj removeObjectsForKeys:@[@"key1", @"key2"]];
    [unmanaged.uuidObj removeObjectsForKeys:@[@"key1", @"key2"]];
    [optUnmanaged.uuidObj removeObjectsForKeys:@[@"key1", @"key2"]];
    [managed.uuidObj removeObjectsForKeys:@[@"key1", @"key2"]];
    [optManaged.uuidObj removeObjectsForKeys:@[@"key1", @"key2"]];
    [unmanaged.anyBoolObj removeObjectsForKeys:@[@"key1", @"key2"]];
    [unmanaged.anyIntObj removeObjectsForKeys:@[@"key1", @"key2"]];
    [unmanaged.anyFloatObj removeObjectsForKeys:@[@"key1", @"key2"]];
    [unmanaged.anyDoubleObj removeObjectsForKeys:@[@"key1", @"key2"]];
    [unmanaged.anyStringObj removeObjectsForKeys:@[@"key1", @"key2"]];
    [unmanaged.anyDataObj removeObjectsForKeys:@[@"key1", @"key2"]];
    [unmanaged.anyDateObj removeObjectsForKeys:@[@"key1", @"key2"]];
    [unmanaged.anyDecimalObj removeObjectsForKeys:@[@"key1", @"key2"]];
    [unmanaged.anyObjectIdObj removeObjectsForKeys:@[@"key1", @"key2"]];
    [unmanaged.anyUUIDObj removeObjectsForKeys:@[@"key1", @"key2"]];
    [managed.anyBoolObj removeObjectsForKeys:@[@"key1", @"key2"]];
    [managed.anyIntObj removeObjectsForKeys:@[@"key1", @"key2"]];
    [managed.anyFloatObj removeObjectsForKeys:@[@"key1", @"key2"]];
    [managed.anyDoubleObj removeObjectsForKeys:@[@"key1", @"key2"]];
    [managed.anyStringObj removeObjectsForKeys:@[@"key1", @"key2"]];
    [managed.anyDataObj removeObjectsForKeys:@[@"key1", @"key2"]];
    [managed.anyDateObj removeObjectsForKeys:@[@"key1", @"key2"]];
    [managed.anyDecimalObj removeObjectsForKeys:@[@"key1", @"key2"]];
    [managed.anyObjectIdObj removeObjectsForKeys:@[@"key1", @"key2"]];
    [managed.anyUUIDObj removeObjectsForKeys:@[@"key1", @"key2"]];

    XCTAssertEqual(unmanaged.boolObj.count, 0U);
    XCTAssertEqual(optUnmanaged.boolObj.count, 0U);
    XCTAssertEqual(managed.boolObj.count, 0U);
    XCTAssertEqual(optManaged.boolObj.count, 0U);
    XCTAssertEqual(unmanaged.intObj.count, 0U);
    XCTAssertEqual(optUnmanaged.intObj.count, 0U);
    XCTAssertEqual(managed.intObj.count, 0U);
    XCTAssertEqual(optManaged.intObj.count, 0U);
    XCTAssertEqual(unmanaged.stringObj.count, 0U);
    XCTAssertEqual(optUnmanaged.stringObj.count, 0U);
    XCTAssertEqual(managed.stringObj.count, 0U);
    XCTAssertEqual(optManaged.stringObj.count, 0U);
    XCTAssertEqual(unmanaged.dateObj.count, 0U);
    XCTAssertEqual(optUnmanaged.dateObj.count, 0U);
    XCTAssertEqual(managed.dateObj.count, 0U);
    XCTAssertEqual(optManaged.dateObj.count, 0U);
    XCTAssertEqual(unmanaged.floatObj.count, 0U);
    XCTAssertEqual(optUnmanaged.floatObj.count, 0U);
    XCTAssertEqual(managed.floatObj.count, 0U);
    XCTAssertEqual(optManaged.floatObj.count, 0U);
    XCTAssertEqual(unmanaged.doubleObj.count, 0U);
    XCTAssertEqual(optUnmanaged.doubleObj.count, 0U);
    XCTAssertEqual(managed.doubleObj.count, 0U);
    XCTAssertEqual(optManaged.doubleObj.count, 0U);
    XCTAssertEqual(unmanaged.dataObj.count, 0U);
    XCTAssertEqual(optUnmanaged.dataObj.count, 0U);
    XCTAssertEqual(managed.dataObj.count, 0U);
    XCTAssertEqual(optManaged.dataObj.count, 0U);
    XCTAssertEqual(unmanaged.decimalObj.count, 0U);
    XCTAssertEqual(optUnmanaged.decimalObj.count, 0U);
    XCTAssertEqual(managed.decimalObj.count, 0U);
    XCTAssertEqual(optManaged.decimalObj.count, 0U);
    XCTAssertEqual(unmanaged.objectIdObj.count, 0U);
    XCTAssertEqual(optUnmanaged.objectIdObj.count, 0U);
    XCTAssertEqual(managed.objectIdObj.count, 0U);
    XCTAssertEqual(optManaged.objectIdObj.count, 0U);
    XCTAssertEqual(unmanaged.uuidObj.count, 0U);
    XCTAssertEqual(optUnmanaged.uuidObj.count, 0U);
    XCTAssertEqual(managed.uuidObj.count, 0U);
    XCTAssertEqual(optManaged.uuidObj.count, 0U);
    XCTAssertEqual(unmanaged.anyBoolObj.count, 0U);
    XCTAssertEqual(unmanaged.anyIntObj.count, 0U);
    XCTAssertEqual(unmanaged.anyFloatObj.count, 0U);
    XCTAssertEqual(unmanaged.anyDoubleObj.count, 0U);
    XCTAssertEqual(unmanaged.anyStringObj.count, 0U);
    XCTAssertEqual(unmanaged.anyDataObj.count, 0U);
    XCTAssertEqual(unmanaged.anyDateObj.count, 0U);
    XCTAssertEqual(unmanaged.anyDecimalObj.count, 0U);
    XCTAssertEqual(unmanaged.anyObjectIdObj.count, 0U);
    XCTAssertEqual(unmanaged.anyUUIDObj.count, 0U);
    XCTAssertEqual(managed.anyBoolObj.count, 0U);
    XCTAssertEqual(managed.anyIntObj.count, 0U);
    XCTAssertEqual(managed.anyFloatObj.count, 0U);
    XCTAssertEqual(managed.anyDoubleObj.count, 0U);
    XCTAssertEqual(managed.anyStringObj.count, 0U);
    XCTAssertEqual(managed.anyDataObj.count, 0U);
    XCTAssertEqual(managed.anyDateObj.count, 0U);
    XCTAssertEqual(managed.anyDecimalObj.count, 0U);
    XCTAssertEqual(managed.anyObjectIdObj.count, 0U);
    XCTAssertEqual(managed.anyUUIDObj.count, 0U);
    XCTAssertNil(unmanaged.boolObj[@"key1"]);
    XCTAssertNil(optUnmanaged.boolObj[@"key1"]);
    XCTAssertNil(managed.boolObj[@"key1"]);
    XCTAssertNil(optManaged.boolObj[@"key1"]);
    XCTAssertNil(unmanaged.intObj[@"key1"]);
    XCTAssertNil(optUnmanaged.intObj[@"key1"]);
    XCTAssertNil(managed.intObj[@"key1"]);
    XCTAssertNil(optManaged.intObj[@"key1"]);
    XCTAssertNil(unmanaged.stringObj[@"key1"]);
    XCTAssertNil(optUnmanaged.stringObj[@"key1"]);
    XCTAssertNil(managed.stringObj[@"key1"]);
    XCTAssertNil(optManaged.stringObj[@"key1"]);
    XCTAssertNil(unmanaged.dateObj[@"key1"]);
    XCTAssertNil(optUnmanaged.dateObj[@"key1"]);
    XCTAssertNil(managed.dateObj[@"key1"]);
    XCTAssertNil(optManaged.dateObj[@"key1"]);
    XCTAssertNil(unmanaged.floatObj[@"key1"]);
    XCTAssertNil(optUnmanaged.floatObj[@"key1"]);
    XCTAssertNil(managed.floatObj[@"key1"]);
    XCTAssertNil(optManaged.floatObj[@"key1"]);
    XCTAssertNil(unmanaged.doubleObj[@"key1"]);
    XCTAssertNil(optUnmanaged.doubleObj[@"key1"]);
    XCTAssertNil(managed.doubleObj[@"key1"]);
    XCTAssertNil(optManaged.doubleObj[@"key1"]);
    XCTAssertNil(unmanaged.dataObj[@"key1"]);
    XCTAssertNil(optUnmanaged.dataObj[@"key1"]);
    XCTAssertNil(managed.dataObj[@"key1"]);
    XCTAssertNil(optManaged.dataObj[@"key1"]);
    XCTAssertNil(unmanaged.decimalObj[@"key1"]);
    XCTAssertNil(optUnmanaged.decimalObj[@"key1"]);
    XCTAssertNil(managed.decimalObj[@"key1"]);
    XCTAssertNil(optManaged.decimalObj[@"key1"]);
    XCTAssertNil(unmanaged.objectIdObj[@"key1"]);
    XCTAssertNil(optUnmanaged.objectIdObj[@"key1"]);
    XCTAssertNil(managed.objectIdObj[@"key1"]);
    XCTAssertNil(optManaged.objectIdObj[@"key1"]);
    XCTAssertNil(unmanaged.uuidObj[@"key1"]);
    XCTAssertNil(optUnmanaged.uuidObj[@"key1"]);
    XCTAssertNil(managed.uuidObj[@"key1"]);
    XCTAssertNil(optManaged.uuidObj[@"key1"]);
    XCTAssertNil(unmanaged.anyBoolObj[@"key1"]);
    XCTAssertNil(unmanaged.anyIntObj[@"key1"]);
    XCTAssertNil(unmanaged.anyFloatObj[@"key1"]);
    XCTAssertNil(unmanaged.anyDoubleObj[@"key1"]);
    XCTAssertNil(unmanaged.anyStringObj[@"key1"]);
    XCTAssertNil(unmanaged.anyDataObj[@"key1"]);
    XCTAssertNil(unmanaged.anyDateObj[@"key1"]);
    XCTAssertNil(unmanaged.anyDecimalObj[@"key1"]);
    XCTAssertNil(unmanaged.anyObjectIdObj[@"key1"]);
    XCTAssertNil(unmanaged.anyUUIDObj[@"key1"]);
    XCTAssertNil(managed.anyBoolObj[@"key1"]);
    XCTAssertNil(managed.anyIntObj[@"key1"]);
    XCTAssertNil(managed.anyFloatObj[@"key1"]);
    XCTAssertNil(managed.anyDoubleObj[@"key1"]);
    XCTAssertNil(managed.anyStringObj[@"key1"]);
    XCTAssertNil(managed.anyDataObj[@"key1"]);
    XCTAssertNil(managed.anyDateObj[@"key1"]);
    XCTAssertNil(managed.anyDecimalObj[@"key1"]);
    XCTAssertNil(managed.anyObjectIdObj[@"key1"]);
    XCTAssertNil(managed.anyUUIDObj[@"key1"]);
}

- (void)testUpdateObjects {
    [self addObjects];
    XCTAssertEqual(unmanaged.boolObj.count, 2U);
    XCTAssertEqual(optUnmanaged.boolObj.count, 2U);
    XCTAssertEqual(managed.boolObj.count, 2U);
    XCTAssertEqual(optManaged.boolObj.count, 2U);
    XCTAssertEqual(unmanaged.intObj.count, 2U);
    XCTAssertEqual(optUnmanaged.intObj.count, 2U);
    XCTAssertEqual(managed.intObj.count, 2U);
    XCTAssertEqual(optManaged.intObj.count, 2U);
    XCTAssertEqual(unmanaged.stringObj.count, 2U);
    XCTAssertEqual(optUnmanaged.stringObj.count, 2U);
    XCTAssertEqual(managed.stringObj.count, 2U);
    XCTAssertEqual(optManaged.stringObj.count, 2U);
    XCTAssertEqual(unmanaged.dateObj.count, 2U);
    XCTAssertEqual(optUnmanaged.dateObj.count, 2U);
    XCTAssertEqual(managed.dateObj.count, 2U);
    XCTAssertEqual(optManaged.dateObj.count, 2U);
    XCTAssertEqual(unmanaged.floatObj.count, 2U);
    XCTAssertEqual(optUnmanaged.floatObj.count, 2U);
    XCTAssertEqual(managed.floatObj.count, 2U);
    XCTAssertEqual(optManaged.floatObj.count, 2U);
    XCTAssertEqual(unmanaged.doubleObj.count, 2U);
    XCTAssertEqual(optUnmanaged.doubleObj.count, 2U);
    XCTAssertEqual(managed.doubleObj.count, 2U);
    XCTAssertEqual(optManaged.doubleObj.count, 2U);
    XCTAssertEqual(unmanaged.dataObj.count, 2U);
    XCTAssertEqual(optUnmanaged.dataObj.count, 2U);
    XCTAssertEqual(managed.dataObj.count, 2U);
    XCTAssertEqual(optManaged.dataObj.count, 2U);
    XCTAssertEqual(unmanaged.decimalObj.count, 2U);
    XCTAssertEqual(optUnmanaged.decimalObj.count, 2U);
    XCTAssertEqual(managed.decimalObj.count, 2U);
    XCTAssertEqual(optManaged.decimalObj.count, 2U);
    XCTAssertEqual(unmanaged.objectIdObj.count, 2U);
    XCTAssertEqual(optUnmanaged.objectIdObj.count, 2U);
    XCTAssertEqual(managed.objectIdObj.count, 2U);
    XCTAssertEqual(optManaged.objectIdObj.count, 2U);
    XCTAssertEqual(unmanaged.uuidObj.count, 2U);
    XCTAssertEqual(optUnmanaged.uuidObj.count, 2U);
    XCTAssertEqual(managed.uuidObj.count, 2U);
    XCTAssertEqual(optManaged.uuidObj.count, 2U);
    XCTAssertEqual(unmanaged.anyBoolObj.count, 2U);
    XCTAssertEqual(unmanaged.anyIntObj.count, 2U);
    XCTAssertEqual(unmanaged.anyFloatObj.count, 2U);
    XCTAssertEqual(unmanaged.anyDoubleObj.count, 2U);
    XCTAssertEqual(unmanaged.anyStringObj.count, 2U);
    XCTAssertEqual(unmanaged.anyDataObj.count, 2U);
    XCTAssertEqual(unmanaged.anyDateObj.count, 2U);
    XCTAssertEqual(unmanaged.anyDecimalObj.count, 2U);
    XCTAssertEqual(unmanaged.anyObjectIdObj.count, 2U);
    XCTAssertEqual(unmanaged.anyUUIDObj.count, 2U);
    XCTAssertEqual(managed.anyBoolObj.count, 2U);
    XCTAssertEqual(managed.anyIntObj.count, 2U);
    XCTAssertEqual(managed.anyFloatObj.count, 2U);
    XCTAssertEqual(managed.anyDoubleObj.count, 2U);
    XCTAssertEqual(managed.anyStringObj.count, 2U);
    XCTAssertEqual(managed.anyDataObj.count, 2U);
    XCTAssertEqual(managed.anyDateObj.count, 2U);
    XCTAssertEqual(managed.anyDecimalObj.count, 2U);
    XCTAssertEqual(managed.anyObjectIdObj.count, 2U);
    XCTAssertEqual(managed.anyUUIDObj.count, 2U);

    XCTAssertEqualObjects(unmanaged.boolObj[@"key1"], @NO);
    XCTAssertEqualObjects(optUnmanaged.boolObj[@"key1"], @NO);
    XCTAssertEqualObjects(managed.boolObj[@"key1"], @NO);
    XCTAssertEqualObjects(optManaged.boolObj[@"key1"], @NO);
    XCTAssertEqualObjects(unmanaged.intObj[@"key1"], @2);
    XCTAssertEqualObjects(optUnmanaged.intObj[@"key1"], @2);
    XCTAssertEqualObjects(managed.intObj[@"key1"], @2);
    XCTAssertEqualObjects(optManaged.intObj[@"key1"], @2);
    XCTAssertEqualObjects(unmanaged.stringObj[@"key1"], @"bar");
    XCTAssertEqualObjects(optUnmanaged.stringObj[@"key1"], @"bar");
    XCTAssertEqualObjects(managed.stringObj[@"key1"], @"bar");
    XCTAssertEqualObjects(optManaged.stringObj[@"key1"], @"bar");
    XCTAssertEqualObjects(unmanaged.dateObj[@"key1"], date(1));
    XCTAssertEqualObjects(optUnmanaged.dateObj[@"key1"], date(1));
    XCTAssertEqualObjects(managed.dateObj[@"key1"], date(1));
    XCTAssertEqualObjects(optManaged.dateObj[@"key1"], date(1));
    XCTAssertEqualObjects(unmanaged.floatObj[@"key1"], @2.2f);
    XCTAssertEqualObjects(optUnmanaged.floatObj[@"key1"], @2.2f);
    XCTAssertEqualObjects(managed.floatObj[@"key1"], @2.2f);
    XCTAssertEqualObjects(optManaged.floatObj[@"key1"], @2.2f);
    XCTAssertEqualObjects(unmanaged.doubleObj[@"key1"], @2.2);
    XCTAssertEqualObjects(optUnmanaged.doubleObj[@"key1"], @2.2);
    XCTAssertEqualObjects(managed.doubleObj[@"key1"], @2.2);
    XCTAssertEqualObjects(optManaged.doubleObj[@"key1"], @2.2);
    XCTAssertEqualObjects(unmanaged.dataObj[@"key1"], data(1));
    XCTAssertEqualObjects(optUnmanaged.dataObj[@"key1"], data(1));
    XCTAssertEqualObjects(managed.dataObj[@"key1"], data(1));
    XCTAssertEqualObjects(optManaged.dataObj[@"key1"], data(1));
    XCTAssertEqualObjects(unmanaged.decimalObj[@"key1"], decimal128(2));
    XCTAssertEqualObjects(optUnmanaged.decimalObj[@"key1"], decimal128(2));
    XCTAssertEqualObjects(managed.decimalObj[@"key1"], decimal128(2));
    XCTAssertEqualObjects(optManaged.decimalObj[@"key1"], decimal128(2));
    XCTAssertEqualObjects(unmanaged.objectIdObj[@"key1"], objectId(1));
    XCTAssertEqualObjects(optUnmanaged.objectIdObj[@"key1"], objectId(1));
    XCTAssertEqualObjects(managed.objectIdObj[@"key1"], objectId(1));
    XCTAssertEqualObjects(optManaged.objectIdObj[@"key1"], objectId(1));
    XCTAssertEqualObjects(unmanaged.uuidObj[@"key1"], uuid(@"00000000-0000-0000-0000-000000000000"));
    XCTAssertEqualObjects(optUnmanaged.uuidObj[@"key1"], uuid(@"00000000-0000-0000-0000-000000000000"));
    XCTAssertEqualObjects(managed.uuidObj[@"key1"], uuid(@"00000000-0000-0000-0000-000000000000"));
    XCTAssertEqualObjects(optManaged.uuidObj[@"key1"], uuid(@"00000000-0000-0000-0000-000000000000"));
    XCTAssertEqualObjects(unmanaged.anyBoolObj[@"key1"], @NO);
    XCTAssertEqualObjects(unmanaged.anyIntObj[@"key1"], @2);
    XCTAssertEqualObjects(unmanaged.anyFloatObj[@"key1"], @2.2f);
    XCTAssertEqualObjects(unmanaged.anyDoubleObj[@"key1"], @2.2);
    XCTAssertEqualObjects(unmanaged.anyStringObj[@"key1"], @"a");
    XCTAssertEqualObjects(unmanaged.anyDataObj[@"key1"], data(1));
    XCTAssertEqualObjects(unmanaged.anyDateObj[@"key1"], date(1));
    XCTAssertEqualObjects(unmanaged.anyDecimalObj[@"key1"], decimal128(2));
    XCTAssertEqualObjects(unmanaged.anyObjectIdObj[@"key1"], objectId(1));
    XCTAssertEqualObjects(unmanaged.anyUUIDObj[@"key1"], uuid(@"00000000-0000-0000-0000-000000000000"));
    XCTAssertEqualObjects(managed.anyBoolObj[@"key1"], @NO);
    XCTAssertEqualObjects(managed.anyIntObj[@"key1"], @2);
    XCTAssertEqualObjects(managed.anyFloatObj[@"key1"], @2.2f);
    XCTAssertEqualObjects(managed.anyDoubleObj[@"key1"], @2.2);
    XCTAssertEqualObjects(managed.anyStringObj[@"key1"], @"a");
    XCTAssertEqualObjects(managed.anyDataObj[@"key1"], data(1));
    XCTAssertEqualObjects(managed.anyDateObj[@"key1"], date(1));
    XCTAssertEqualObjects(managed.anyDecimalObj[@"key1"], decimal128(2));
    XCTAssertEqualObjects(managed.anyObjectIdObj[@"key1"], objectId(1));
    XCTAssertEqualObjects(managed.anyUUIDObj[@"key1"], uuid(@"00000000-0000-0000-0000-000000000000"));
    XCTAssertEqualObjects(unmanaged.boolObj[@"key2"], @YES);
    XCTAssertEqualObjects(optUnmanaged.boolObj[@"key2"], NSNull.null);
    XCTAssertEqualObjects(managed.boolObj[@"key2"], @YES);
    XCTAssertEqualObjects(optManaged.boolObj[@"key2"], NSNull.null);
    XCTAssertEqualObjects(unmanaged.intObj[@"key2"], @3);
    XCTAssertEqualObjects(optUnmanaged.intObj[@"key2"], NSNull.null);
    XCTAssertEqualObjects(managed.intObj[@"key2"], @3);
    XCTAssertEqualObjects(optManaged.intObj[@"key2"], NSNull.null);
    XCTAssertEqualObjects(unmanaged.stringObj[@"key2"], @"foo");
    XCTAssertEqualObjects(optUnmanaged.stringObj[@"key2"], NSNull.null);
    XCTAssertEqualObjects(managed.stringObj[@"key2"], @"foo");
    XCTAssertEqualObjects(optManaged.stringObj[@"key2"], NSNull.null);
    XCTAssertEqualObjects(unmanaged.dateObj[@"key2"], date(2));
    XCTAssertEqualObjects(optUnmanaged.dateObj[@"key2"], NSNull.null);
    XCTAssertEqualObjects(managed.dateObj[@"key2"], date(2));
    XCTAssertEqualObjects(optManaged.dateObj[@"key2"], NSNull.null);
    XCTAssertEqualObjects(unmanaged.floatObj[@"key2"], @3.3f);
    XCTAssertEqualObjects(optUnmanaged.floatObj[@"key2"], NSNull.null);
    XCTAssertEqualObjects(managed.floatObj[@"key2"], @3.3f);
    XCTAssertEqualObjects(optManaged.floatObj[@"key2"], NSNull.null);
    XCTAssertEqualObjects(unmanaged.doubleObj[@"key2"], @3.3);
    XCTAssertEqualObjects(optUnmanaged.doubleObj[@"key2"], NSNull.null);
    XCTAssertEqualObjects(managed.doubleObj[@"key2"], @3.3);
    XCTAssertEqualObjects(optManaged.doubleObj[@"key2"], NSNull.null);
    XCTAssertEqualObjects(unmanaged.dataObj[@"key2"], data(2));
    XCTAssertEqualObjects(optUnmanaged.dataObj[@"key2"], NSNull.null);
    XCTAssertEqualObjects(managed.dataObj[@"key2"], data(2));
    XCTAssertEqualObjects(optManaged.dataObj[@"key2"], NSNull.null);
    XCTAssertEqualObjects(unmanaged.decimalObj[@"key2"], decimal128(3));
    XCTAssertEqualObjects(optUnmanaged.decimalObj[@"key2"], NSNull.null);
    XCTAssertEqualObjects(managed.decimalObj[@"key2"], decimal128(3));
    XCTAssertEqualObjects(optManaged.decimalObj[@"key2"], NSNull.null);
    XCTAssertEqualObjects(unmanaged.objectIdObj[@"key2"], objectId(2));
    XCTAssertEqualObjects(optUnmanaged.objectIdObj[@"key2"], NSNull.null);
    XCTAssertEqualObjects(managed.objectIdObj[@"key2"], objectId(2));
    XCTAssertEqualObjects(optManaged.objectIdObj[@"key2"], NSNull.null);
    XCTAssertEqualObjects(unmanaged.uuidObj[@"key2"], uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"));
    XCTAssertEqualObjects(optUnmanaged.uuidObj[@"key2"], NSNull.null);
    XCTAssertEqualObjects(managed.uuidObj[@"key2"], uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"));
    XCTAssertEqualObjects(optManaged.uuidObj[@"key2"], NSNull.null);
    XCTAssertEqualObjects(unmanaged.anyBoolObj[@"key2"], @YES);
    XCTAssertEqualObjects(unmanaged.anyIntObj[@"key2"], @3);
    XCTAssertEqualObjects(unmanaged.anyFloatObj[@"key2"], @3.3f);
    XCTAssertEqualObjects(unmanaged.anyDoubleObj[@"key2"], @3.3);
    XCTAssertEqualObjects(unmanaged.anyStringObj[@"key2"], @"b");
    XCTAssertEqualObjects(unmanaged.anyDataObj[@"key2"], data(2));
    XCTAssertEqualObjects(unmanaged.anyDateObj[@"key2"], date(2));
    XCTAssertEqualObjects(unmanaged.anyDecimalObj[@"key2"], decimal128(3));
    XCTAssertEqualObjects(unmanaged.anyObjectIdObj[@"key2"], objectId(2));
    XCTAssertEqualObjects(unmanaged.anyUUIDObj[@"key2"], uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"));
    XCTAssertEqualObjects(managed.anyBoolObj[@"key2"], @YES);
    XCTAssertEqualObjects(managed.anyIntObj[@"key2"], @3);
    XCTAssertEqualObjects(managed.anyFloatObj[@"key2"], @3.3f);
    XCTAssertEqualObjects(managed.anyDoubleObj[@"key2"], @3.3);
    XCTAssertEqualObjects(managed.anyStringObj[@"key2"], @"b");
    XCTAssertEqualObjects(managed.anyDataObj[@"key2"], data(2));
    XCTAssertEqualObjects(managed.anyDateObj[@"key2"], date(2));
    XCTAssertEqualObjects(managed.anyDecimalObj[@"key2"], decimal128(3));
    XCTAssertEqualObjects(managed.anyObjectIdObj[@"key2"], objectId(2));
    XCTAssertEqualObjects(managed.anyUUIDObj[@"key2"], uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"));

    unmanaged.boolObj[@"key2"] = unmanaged.boolObj[@"key1"];
    optUnmanaged.boolObj[@"key2"] = optUnmanaged.boolObj[@"key1"];
    managed.boolObj[@"key2"] = managed.boolObj[@"key1"];
    optManaged.boolObj[@"key2"] = optManaged.boolObj[@"key1"];
    unmanaged.intObj[@"key2"] = unmanaged.intObj[@"key1"];
    optUnmanaged.intObj[@"key2"] = optUnmanaged.intObj[@"key1"];
    managed.intObj[@"key2"] = managed.intObj[@"key1"];
    optManaged.intObj[@"key2"] = optManaged.intObj[@"key1"];
    unmanaged.stringObj[@"key2"] = unmanaged.stringObj[@"key1"];
    optUnmanaged.stringObj[@"key2"] = optUnmanaged.stringObj[@"key1"];
    managed.stringObj[@"key2"] = managed.stringObj[@"key1"];
    optManaged.stringObj[@"key2"] = optManaged.stringObj[@"key1"];
    unmanaged.dateObj[@"key2"] = unmanaged.dateObj[@"key1"];
    optUnmanaged.dateObj[@"key2"] = optUnmanaged.dateObj[@"key1"];
    managed.dateObj[@"key2"] = managed.dateObj[@"key1"];
    optManaged.dateObj[@"key2"] = optManaged.dateObj[@"key1"];
    unmanaged.floatObj[@"key2"] = unmanaged.floatObj[@"key1"];
    optUnmanaged.floatObj[@"key2"] = optUnmanaged.floatObj[@"key1"];
    managed.floatObj[@"key2"] = managed.floatObj[@"key1"];
    optManaged.floatObj[@"key2"] = optManaged.floatObj[@"key1"];
    unmanaged.doubleObj[@"key2"] = unmanaged.doubleObj[@"key1"];
    optUnmanaged.doubleObj[@"key2"] = optUnmanaged.doubleObj[@"key1"];
    managed.doubleObj[@"key2"] = managed.doubleObj[@"key1"];
    optManaged.doubleObj[@"key2"] = optManaged.doubleObj[@"key1"];
    unmanaged.dataObj[@"key2"] = unmanaged.dataObj[@"key1"];
    optUnmanaged.dataObj[@"key2"] = optUnmanaged.dataObj[@"key1"];
    managed.dataObj[@"key2"] = managed.dataObj[@"key1"];
    optManaged.dataObj[@"key2"] = optManaged.dataObj[@"key1"];
    unmanaged.decimalObj[@"key2"] = unmanaged.decimalObj[@"key1"];
    optUnmanaged.decimalObj[@"key2"] = optUnmanaged.decimalObj[@"key1"];
    managed.decimalObj[@"key2"] = managed.decimalObj[@"key1"];
    optManaged.decimalObj[@"key2"] = optManaged.decimalObj[@"key1"];
    unmanaged.objectIdObj[@"key2"] = unmanaged.objectIdObj[@"key1"];
    optUnmanaged.objectIdObj[@"key2"] = optUnmanaged.objectIdObj[@"key1"];
    managed.objectIdObj[@"key2"] = managed.objectIdObj[@"key1"];
    optManaged.objectIdObj[@"key2"] = optManaged.objectIdObj[@"key1"];
    unmanaged.uuidObj[@"key2"] = unmanaged.uuidObj[@"key1"];
    optUnmanaged.uuidObj[@"key2"] = optUnmanaged.uuidObj[@"key1"];
    managed.uuidObj[@"key2"] = managed.uuidObj[@"key1"];
    optManaged.uuidObj[@"key2"] = optManaged.uuidObj[@"key1"];
    unmanaged.anyBoolObj[@"key2"] = unmanaged.anyBoolObj[@"key1"];
    unmanaged.anyIntObj[@"key2"] = unmanaged.anyIntObj[@"key1"];
    unmanaged.anyFloatObj[@"key2"] = unmanaged.anyFloatObj[@"key1"];
    unmanaged.anyDoubleObj[@"key2"] = unmanaged.anyDoubleObj[@"key1"];
    unmanaged.anyStringObj[@"key2"] = unmanaged.anyStringObj[@"key1"];
    unmanaged.anyDataObj[@"key2"] = unmanaged.anyDataObj[@"key1"];
    unmanaged.anyDateObj[@"key2"] = unmanaged.anyDateObj[@"key1"];
    unmanaged.anyDecimalObj[@"key2"] = unmanaged.anyDecimalObj[@"key1"];
    unmanaged.anyObjectIdObj[@"key2"] = unmanaged.anyObjectIdObj[@"key1"];
    unmanaged.anyUUIDObj[@"key2"] = unmanaged.anyUUIDObj[@"key1"];
    managed.anyBoolObj[@"key2"] = managed.anyBoolObj[@"key1"];
    managed.anyIntObj[@"key2"] = managed.anyIntObj[@"key1"];
    managed.anyFloatObj[@"key2"] = managed.anyFloatObj[@"key1"];
    managed.anyDoubleObj[@"key2"] = managed.anyDoubleObj[@"key1"];
    managed.anyStringObj[@"key2"] = managed.anyStringObj[@"key1"];
    managed.anyDataObj[@"key2"] = managed.anyDataObj[@"key1"];
    managed.anyDateObj[@"key2"] = managed.anyDateObj[@"key1"];
    managed.anyDecimalObj[@"key2"] = managed.anyDecimalObj[@"key1"];
    managed.anyObjectIdObj[@"key2"] = managed.anyObjectIdObj[@"key1"];
    managed.anyUUIDObj[@"key2"] = managed.anyUUIDObj[@"key1"];
    unmanaged.boolObj[@"key1"] = unmanaged.boolObj[@"key2"];
    optUnmanaged.boolObj[@"key1"] = optUnmanaged.boolObj[@"key2"];
    managed.boolObj[@"key1"] = managed.boolObj[@"key2"];
    optManaged.boolObj[@"key1"] = optManaged.boolObj[@"key2"];
    unmanaged.intObj[@"key1"] = unmanaged.intObj[@"key2"];
    optUnmanaged.intObj[@"key1"] = optUnmanaged.intObj[@"key2"];
    managed.intObj[@"key1"] = managed.intObj[@"key2"];
    optManaged.intObj[@"key1"] = optManaged.intObj[@"key2"];
    unmanaged.stringObj[@"key1"] = unmanaged.stringObj[@"key2"];
    optUnmanaged.stringObj[@"key1"] = optUnmanaged.stringObj[@"key2"];
    managed.stringObj[@"key1"] = managed.stringObj[@"key2"];
    optManaged.stringObj[@"key1"] = optManaged.stringObj[@"key2"];
    unmanaged.dateObj[@"key1"] = unmanaged.dateObj[@"key2"];
    optUnmanaged.dateObj[@"key1"] = optUnmanaged.dateObj[@"key2"];
    managed.dateObj[@"key1"] = managed.dateObj[@"key2"];
    optManaged.dateObj[@"key1"] = optManaged.dateObj[@"key2"];
    unmanaged.floatObj[@"key1"] = unmanaged.floatObj[@"key2"];
    optUnmanaged.floatObj[@"key1"] = optUnmanaged.floatObj[@"key2"];
    managed.floatObj[@"key1"] = managed.floatObj[@"key2"];
    optManaged.floatObj[@"key1"] = optManaged.floatObj[@"key2"];
    unmanaged.doubleObj[@"key1"] = unmanaged.doubleObj[@"key2"];
    optUnmanaged.doubleObj[@"key1"] = optUnmanaged.doubleObj[@"key2"];
    managed.doubleObj[@"key1"] = managed.doubleObj[@"key2"];
    optManaged.doubleObj[@"key1"] = optManaged.doubleObj[@"key2"];
    unmanaged.dataObj[@"key1"] = unmanaged.dataObj[@"key2"];
    optUnmanaged.dataObj[@"key1"] = optUnmanaged.dataObj[@"key2"];
    managed.dataObj[@"key1"] = managed.dataObj[@"key2"];
    optManaged.dataObj[@"key1"] = optManaged.dataObj[@"key2"];
    unmanaged.decimalObj[@"key1"] = unmanaged.decimalObj[@"key2"];
    optUnmanaged.decimalObj[@"key1"] = optUnmanaged.decimalObj[@"key2"];
    managed.decimalObj[@"key1"] = managed.decimalObj[@"key2"];
    optManaged.decimalObj[@"key1"] = optManaged.decimalObj[@"key2"];
    unmanaged.objectIdObj[@"key1"] = unmanaged.objectIdObj[@"key2"];
    optUnmanaged.objectIdObj[@"key1"] = optUnmanaged.objectIdObj[@"key2"];
    managed.objectIdObj[@"key1"] = managed.objectIdObj[@"key2"];
    optManaged.objectIdObj[@"key1"] = optManaged.objectIdObj[@"key2"];
    unmanaged.uuidObj[@"key1"] = unmanaged.uuidObj[@"key2"];
    optUnmanaged.uuidObj[@"key1"] = optUnmanaged.uuidObj[@"key2"];
    managed.uuidObj[@"key1"] = managed.uuidObj[@"key2"];
    optManaged.uuidObj[@"key1"] = optManaged.uuidObj[@"key2"];
    unmanaged.anyBoolObj[@"key1"] = unmanaged.anyBoolObj[@"key2"];
    unmanaged.anyIntObj[@"key1"] = unmanaged.anyIntObj[@"key2"];
    unmanaged.anyFloatObj[@"key1"] = unmanaged.anyFloatObj[@"key2"];
    unmanaged.anyDoubleObj[@"key1"] = unmanaged.anyDoubleObj[@"key2"];
    unmanaged.anyStringObj[@"key1"] = unmanaged.anyStringObj[@"key2"];
    unmanaged.anyDataObj[@"key1"] = unmanaged.anyDataObj[@"key2"];
    unmanaged.anyDateObj[@"key1"] = unmanaged.anyDateObj[@"key2"];
    unmanaged.anyDecimalObj[@"key1"] = unmanaged.anyDecimalObj[@"key2"];
    unmanaged.anyObjectIdObj[@"key1"] = unmanaged.anyObjectIdObj[@"key2"];
    unmanaged.anyUUIDObj[@"key1"] = unmanaged.anyUUIDObj[@"key2"];
    managed.anyBoolObj[@"key1"] = managed.anyBoolObj[@"key2"];
    managed.anyIntObj[@"key1"] = managed.anyIntObj[@"key2"];
    managed.anyFloatObj[@"key1"] = managed.anyFloatObj[@"key2"];
    managed.anyDoubleObj[@"key1"] = managed.anyDoubleObj[@"key2"];
    managed.anyStringObj[@"key1"] = managed.anyStringObj[@"key2"];
    managed.anyDataObj[@"key1"] = managed.anyDataObj[@"key2"];
    managed.anyDateObj[@"key1"] = managed.anyDateObj[@"key2"];
    managed.anyDecimalObj[@"key1"] = managed.anyDecimalObj[@"key2"];
    managed.anyObjectIdObj[@"key1"] = managed.anyObjectIdObj[@"key2"];
    managed.anyUUIDObj[@"key1"] = managed.anyUUIDObj[@"key2"];

    XCTAssertEqualObjects(unmanaged.boolObj[@"key2"], @NO);
    XCTAssertEqualObjects(optUnmanaged.boolObj[@"key2"], @NO);
    XCTAssertEqualObjects(managed.boolObj[@"key2"], @NO);
    XCTAssertEqualObjects(optManaged.boolObj[@"key2"], @NO);
    XCTAssertEqualObjects(unmanaged.intObj[@"key2"], @2);
    XCTAssertEqualObjects(optUnmanaged.intObj[@"key2"], @2);
    XCTAssertEqualObjects(managed.intObj[@"key2"], @2);
    XCTAssertEqualObjects(optManaged.intObj[@"key2"], @2);
    XCTAssertEqualObjects(unmanaged.stringObj[@"key2"], @"bar");
    XCTAssertEqualObjects(optUnmanaged.stringObj[@"key2"], @"bar");
    XCTAssertEqualObjects(managed.stringObj[@"key2"], @"bar");
    XCTAssertEqualObjects(optManaged.stringObj[@"key2"], @"bar");
    XCTAssertEqualObjects(unmanaged.dateObj[@"key2"], date(1));
    XCTAssertEqualObjects(optUnmanaged.dateObj[@"key2"], date(1));
    XCTAssertEqualObjects(managed.dateObj[@"key2"], date(1));
    XCTAssertEqualObjects(optManaged.dateObj[@"key2"], date(1));
    XCTAssertEqualObjects(unmanaged.floatObj[@"key2"], @2.2f);
    XCTAssertEqualObjects(optUnmanaged.floatObj[@"key2"], @2.2f);
    XCTAssertEqualObjects(managed.floatObj[@"key2"], @2.2f);
    XCTAssertEqualObjects(optManaged.floatObj[@"key2"], @2.2f);
    XCTAssertEqualObjects(unmanaged.doubleObj[@"key2"], @2.2);
    XCTAssertEqualObjects(optUnmanaged.doubleObj[@"key2"], @2.2);
    XCTAssertEqualObjects(managed.doubleObj[@"key2"], @2.2);
    XCTAssertEqualObjects(optManaged.doubleObj[@"key2"], @2.2);
    XCTAssertEqualObjects(unmanaged.dataObj[@"key2"], data(1));
    XCTAssertEqualObjects(optUnmanaged.dataObj[@"key2"], data(1));
    XCTAssertEqualObjects(managed.dataObj[@"key2"], data(1));
    XCTAssertEqualObjects(optManaged.dataObj[@"key2"], data(1));
    XCTAssertEqualObjects(unmanaged.decimalObj[@"key2"], decimal128(2));
    XCTAssertEqualObjects(optUnmanaged.decimalObj[@"key2"], decimal128(2));
    XCTAssertEqualObjects(managed.decimalObj[@"key2"], decimal128(2));
    XCTAssertEqualObjects(optManaged.decimalObj[@"key2"], decimal128(2));
    XCTAssertEqualObjects(unmanaged.objectIdObj[@"key2"], objectId(1));
    XCTAssertEqualObjects(optUnmanaged.objectIdObj[@"key2"], objectId(1));
    XCTAssertEqualObjects(managed.objectIdObj[@"key2"], objectId(1));
    XCTAssertEqualObjects(optManaged.objectIdObj[@"key2"], objectId(1));
    XCTAssertEqualObjects(unmanaged.uuidObj[@"key2"], uuid(@"00000000-0000-0000-0000-000000000000"));
    XCTAssertEqualObjects(optUnmanaged.uuidObj[@"key2"], uuid(@"00000000-0000-0000-0000-000000000000"));
    XCTAssertEqualObjects(managed.uuidObj[@"key2"], uuid(@"00000000-0000-0000-0000-000000000000"));
    XCTAssertEqualObjects(optManaged.uuidObj[@"key2"], uuid(@"00000000-0000-0000-0000-000000000000"));
    XCTAssertEqualObjects(unmanaged.anyBoolObj[@"key2"], @NO);
    XCTAssertEqualObjects(unmanaged.anyIntObj[@"key2"], @2);
    XCTAssertEqualObjects(unmanaged.anyFloatObj[@"key2"], @2.2f);
    XCTAssertEqualObjects(unmanaged.anyDoubleObj[@"key2"], @2.2);
    XCTAssertEqualObjects(unmanaged.anyStringObj[@"key2"], @"a");
    XCTAssertEqualObjects(unmanaged.anyDataObj[@"key2"], data(1));
    XCTAssertEqualObjects(unmanaged.anyDateObj[@"key2"], date(1));
    XCTAssertEqualObjects(unmanaged.anyDecimalObj[@"key2"], decimal128(2));
    XCTAssertEqualObjects(unmanaged.anyObjectIdObj[@"key2"], objectId(1));
    XCTAssertEqualObjects(unmanaged.anyUUIDObj[@"key2"], uuid(@"00000000-0000-0000-0000-000000000000"));
    XCTAssertEqualObjects(managed.anyBoolObj[@"key2"], @NO);
    XCTAssertEqualObjects(managed.anyIntObj[@"key2"], @2);
    XCTAssertEqualObjects(managed.anyFloatObj[@"key2"], @2.2f);
    XCTAssertEqualObjects(managed.anyDoubleObj[@"key2"], @2.2);
    XCTAssertEqualObjects(managed.anyStringObj[@"key2"], @"a");
    XCTAssertEqualObjects(managed.anyDataObj[@"key2"], data(1));
    XCTAssertEqualObjects(managed.anyDateObj[@"key2"], date(1));
    XCTAssertEqualObjects(managed.anyDecimalObj[@"key2"], decimal128(2));
    XCTAssertEqualObjects(managed.anyObjectIdObj[@"key2"], objectId(1));
    XCTAssertEqualObjects(managed.anyUUIDObj[@"key2"], uuid(@"00000000-0000-0000-0000-000000000000"));
}

- (void)testIndexOfObjectSorted {
    [unmanaged.boolObj addEntriesFromDictionary:@{ @"key1": @NO, @"key2": @YES }];
    [optUnmanaged.boolObj addEntriesFromDictionary:@{ @"key1": @NO, @"key2": NSNull.null }];
    [managed.boolObj addEntriesFromDictionary:@{ @"key1": @NO, @"key2": @YES }];
    [optManaged.boolObj addEntriesFromDictionary:@{ @"key1": @NO, @"key2": NSNull.null }];
    [unmanaged.intObj addEntriesFromDictionary:@{ @"key1": @2, @"key2": @3 }];
    [optUnmanaged.intObj addEntriesFromDictionary:@{ @"key1": @2, @"key2": NSNull.null }];
    [managed.intObj addEntriesFromDictionary:@{ @"key1": @2, @"key2": @3 }];
    [optManaged.intObj addEntriesFromDictionary:@{ @"key1": @2, @"key2": NSNull.null }];
    [unmanaged.stringObj addEntriesFromDictionary:@{ @"key1": @"bar", @"key2": @"foo" }];
    [optUnmanaged.stringObj addEntriesFromDictionary:@{ @"key1": @"bar", @"key2": NSNull.null }];
    [managed.stringObj addEntriesFromDictionary:@{ @"key1": @"bar", @"key2": @"foo" }];
    [optManaged.stringObj addEntriesFromDictionary:@{ @"key1": @"bar", @"key2": NSNull.null }];
    [unmanaged.dateObj addEntriesFromDictionary:@{ @"key1": date(1), @"key2": date(2) }];
    [optUnmanaged.dateObj addEntriesFromDictionary:@{ @"key1": date(1), @"key2": NSNull.null }];
    [managed.dateObj addEntriesFromDictionary:@{ @"key1": date(1), @"key2": date(2) }];
    [optManaged.dateObj addEntriesFromDictionary:@{ @"key1": date(1), @"key2": NSNull.null }];
    [unmanaged.floatObj addEntriesFromDictionary:@{ @"key1": @2.2f, @"key2": @3.3f }];
    [optUnmanaged.floatObj addEntriesFromDictionary:@{ @"key1": @2.2f, @"key2": NSNull.null }];
    [managed.floatObj addEntriesFromDictionary:@{ @"key1": @2.2f, @"key2": @3.3f }];
    [optManaged.floatObj addEntriesFromDictionary:@{ @"key1": @2.2f, @"key2": NSNull.null }];
    [unmanaged.doubleObj addEntriesFromDictionary:@{ @"key1": @2.2, @"key2": @3.3 }];
    [optUnmanaged.doubleObj addEntriesFromDictionary:@{ @"key1": @2.2, @"key2": NSNull.null }];
    [managed.doubleObj addEntriesFromDictionary:@{ @"key1": @2.2, @"key2": @3.3 }];
    [optManaged.doubleObj addEntriesFromDictionary:@{ @"key1": @2.2, @"key2": NSNull.null }];
    [unmanaged.dataObj addEntriesFromDictionary:@{ @"key1": data(1), @"key2": data(2) }];
    [optUnmanaged.dataObj addEntriesFromDictionary:@{ @"key1": data(1), @"key2": NSNull.null }];
    [managed.dataObj addEntriesFromDictionary:@{ @"key1": data(1), @"key2": data(2) }];
    [optManaged.dataObj addEntriesFromDictionary:@{ @"key1": data(1), @"key2": NSNull.null }];
    [unmanaged.decimalObj addEntriesFromDictionary:@{ @"key1": decimal128(2), @"key2": decimal128(3) }];
    [optUnmanaged.decimalObj addEntriesFromDictionary:@{ @"key1": decimal128(2), @"key2": NSNull.null }];
    [managed.decimalObj addEntriesFromDictionary:@{ @"key1": decimal128(2), @"key2": decimal128(3) }];
    [optManaged.decimalObj addEntriesFromDictionary:@{ @"key1": decimal128(2), @"key2": NSNull.null }];
    [unmanaged.objectIdObj addEntriesFromDictionary:@{ @"key1": objectId(1), @"key2": objectId(2) }];
    [optUnmanaged.objectIdObj addEntriesFromDictionary:@{ @"key1": objectId(1), @"key2": NSNull.null }];
    [managed.objectIdObj addEntriesFromDictionary:@{ @"key1": objectId(1), @"key2": objectId(2) }];
    [optManaged.objectIdObj addEntriesFromDictionary:@{ @"key1": objectId(1), @"key2": NSNull.null }];
    [unmanaged.uuidObj addEntriesFromDictionary:@{ @"key1": uuid(@"00000000-0000-0000-0000-000000000000"), @"key2": uuid(@"137DECC8-B300-4954-A233-F89909F4FD89") }];
    [optUnmanaged.uuidObj addEntriesFromDictionary:@{ @"key1": uuid(@"00000000-0000-0000-0000-000000000000"), @"key2": NSNull.null }];
    [managed.uuidObj addEntriesFromDictionary:@{ @"key1": uuid(@"00000000-0000-0000-0000-000000000000"), @"key2": uuid(@"137DECC8-B300-4954-A233-F89909F4FD89") }];
    [optManaged.uuidObj addEntriesFromDictionary:@{ @"key1": uuid(@"00000000-0000-0000-0000-000000000000"), @"key2": NSNull.null }];
    [unmanaged.anyBoolObj addEntriesFromDictionary:@{ @"key1": @NO, @"key2": @YES }];
    [unmanaged.anyIntObj addEntriesFromDictionary:@{ @"key1": @2, @"key2": @3 }];
    [unmanaged.anyFloatObj addEntriesFromDictionary:@{ @"key1": @2.2f, @"key2": @3.3f }];
    [unmanaged.anyDoubleObj addEntriesFromDictionary:@{ @"key1": @2.2, @"key2": @3.3 }];
    [unmanaged.anyStringObj addEntriesFromDictionary:@{ @"key1": @"a", @"key2": @"b" }];
    [unmanaged.anyDataObj addEntriesFromDictionary:@{ @"key1": data(1), @"key2": data(2) }];
    [unmanaged.anyDateObj addEntriesFromDictionary:@{ @"key1": date(1), @"key2": date(2) }];
    [unmanaged.anyDecimalObj addEntriesFromDictionary:@{ @"key1": decimal128(2), @"key2": decimal128(3) }];
    [unmanaged.anyObjectIdObj addEntriesFromDictionary:@{ @"key1": objectId(1), @"key2": objectId(2) }];
    [unmanaged.anyUUIDObj addEntriesFromDictionary:@{ @"key1": uuid(@"00000000-0000-0000-0000-000000000000"), @"key2": uuid(@"137DECC8-B300-4954-A233-F89909F4FD89") }];
    [managed.anyBoolObj addEntriesFromDictionary:@{ @"key1": @NO, @"key2": @YES }];
    [managed.anyIntObj addEntriesFromDictionary:@{ @"key1": @2, @"key2": @3 }];
    [managed.anyFloatObj addEntriesFromDictionary:@{ @"key1": @2.2f, @"key2": @3.3f }];
    [managed.anyDoubleObj addEntriesFromDictionary:@{ @"key1": @2.2, @"key2": @3.3 }];
    [managed.anyStringObj addEntriesFromDictionary:@{ @"key1": @"a", @"key2": @"b" }];
    [managed.anyDataObj addEntriesFromDictionary:@{ @"key1": data(1), @"key2": data(2) }];
    [managed.anyDateObj addEntriesFromDictionary:@{ @"key1": date(1), @"key2": date(2) }];
    [managed.anyDecimalObj addEntriesFromDictionary:@{ @"key1": decimal128(2), @"key2": decimal128(3) }];
    [managed.anyObjectIdObj addEntriesFromDictionary:@{ @"key1": objectId(1), @"key2": objectId(2) }];
    [managed.anyUUIDObj addEntriesFromDictionary:@{ @"key1": uuid(@"00000000-0000-0000-0000-000000000000"), @"key2": uuid(@"137DECC8-B300-4954-A233-F89909F4FD89") }];

    XCTAssertEqual(0U, [[optManaged.boolObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:@NO]);
    XCTAssertEqual(0U, [[optManaged.intObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:@2]);
    XCTAssertEqual(0U, [[optManaged.stringObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:@"bar"]);
    XCTAssertEqual(0U, [[optManaged.dateObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:date(1)]);
    XCTAssertEqual(1U, [[optManaged.boolObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:(id)NSNull.null]);
    XCTAssertEqual(1U, [[optManaged.intObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:(id)NSNull.null]);
    XCTAssertEqual(1U, [[optManaged.stringObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:(id)NSNull.null]);
    XCTAssertEqual(1U, [[optManaged.dateObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:(id)NSNull.null]);
    XCTAssertEqual(1U, [[managed.boolObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:@NO]);
    XCTAssertEqual(1U, [[managed.intObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:@2]);
    XCTAssertEqual(1U, [[managed.stringObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:@"bar"]);
    XCTAssertEqual(1U, [[managed.dateObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:date(1)]);
    XCTAssertEqual(1U, [[managed.anyBoolObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:@NO]);
    XCTAssertEqual(1U, [[managed.anyIntObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:@2]);
    XCTAssertEqual(1U, [[managed.anyFloatObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:@2.2f]);
    XCTAssertEqual(1U, [[managed.anyDoubleObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:@2.2]);
    XCTAssertEqual(1U, [[managed.anyStringObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:@"a"]);
    XCTAssertEqual(1U, [[managed.anyDataObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:data(1)]);
    XCTAssertEqual(1U, [[managed.anyDateObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:date(1)]);
    XCTAssertEqual(1U, [[managed.anyDecimalObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:decimal128(2)]);
    XCTAssertEqual(1U, [[managed.anyUUIDObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:uuid(@"00000000-0000-0000-0000-000000000000")]);
    XCTAssertEqual(0U, [[managed.boolObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:@YES]);
    XCTAssertEqual(0U, [[managed.intObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:@3]);
    XCTAssertEqual(0U, [[managed.stringObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:@"foo"]);
    XCTAssertEqual(0U, [[managed.dateObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:date(2)]);
    XCTAssertEqual(0U, [[managed.anyBoolObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:@YES]);
    XCTAssertEqual(0U, [[managed.anyIntObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:@3]);
    XCTAssertEqual(0U, [[managed.anyFloatObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:@3.3f]);
    XCTAssertEqual(0U, [[managed.anyDoubleObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:@3.3]);
    XCTAssertEqual(0U, [[managed.anyStringObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:@"b"]);
    XCTAssertEqual(0U, [[managed.anyDataObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:data(2)]);
    XCTAssertEqual(0U, [[managed.anyDateObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:date(2)]);
    XCTAssertEqual(0U, [[managed.anyDecimalObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:decimal128(3)]);
    XCTAssertEqual(0U, [[managed.anyUUIDObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")]);

    XCTAssertEqual(1U, [[optManaged.boolObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:(id)NSNull.null]);
    XCTAssertEqual(1U, [[optManaged.intObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:(id)NSNull.null]);
    XCTAssertEqual(1U, [[optManaged.stringObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:(id)NSNull.null]);
    XCTAssertEqual(1U, [[optManaged.dateObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:(id)NSNull.null]);
}

- (void)testIndexOfObjectDistinct {
    [unmanaged.boolObj addEntriesFromDictionary:@{ @"key1": @NO, @"key2": @YES }];
    [optUnmanaged.boolObj addEntriesFromDictionary:@{ @"key1": @NO, @"key2": NSNull.null }];
    [managed.boolObj addEntriesFromDictionary:@{ @"key1": @NO, @"key2": @YES }];
    [optManaged.boolObj addEntriesFromDictionary:@{ @"key1": @NO, @"key2": NSNull.null }];
    [unmanaged.intObj addEntriesFromDictionary:@{ @"key1": @2, @"key2": @3 }];
    [optUnmanaged.intObj addEntriesFromDictionary:@{ @"key1": @2, @"key2": NSNull.null }];
    [managed.intObj addEntriesFromDictionary:@{ @"key1": @2, @"key2": @3 }];
    [optManaged.intObj addEntriesFromDictionary:@{ @"key1": @2, @"key2": NSNull.null }];
    [unmanaged.stringObj addEntriesFromDictionary:@{ @"key1": @"bar", @"key2": @"foo" }];
    [optUnmanaged.stringObj addEntriesFromDictionary:@{ @"key1": @"bar", @"key2": NSNull.null }];
    [managed.stringObj addEntriesFromDictionary:@{ @"key1": @"bar", @"key2": @"foo" }];
    [optManaged.stringObj addEntriesFromDictionary:@{ @"key1": @"bar", @"key2": NSNull.null }];
    [unmanaged.dateObj addEntriesFromDictionary:@{ @"key1": date(1), @"key2": date(2) }];
    [optUnmanaged.dateObj addEntriesFromDictionary:@{ @"key1": date(1), @"key2": NSNull.null }];
    [managed.dateObj addEntriesFromDictionary:@{ @"key1": date(1), @"key2": date(2) }];
    [optManaged.dateObj addEntriesFromDictionary:@{ @"key1": date(1), @"key2": NSNull.null }];
    [unmanaged.floatObj addEntriesFromDictionary:@{ @"key1": @2.2f, @"key2": @3.3f }];
    [optUnmanaged.floatObj addEntriesFromDictionary:@{ @"key1": @2.2f, @"key2": NSNull.null }];
    [managed.floatObj addEntriesFromDictionary:@{ @"key1": @2.2f, @"key2": @3.3f }];
    [optManaged.floatObj addEntriesFromDictionary:@{ @"key1": @2.2f, @"key2": NSNull.null }];
    [unmanaged.doubleObj addEntriesFromDictionary:@{ @"key1": @2.2, @"key2": @3.3 }];
    [optUnmanaged.doubleObj addEntriesFromDictionary:@{ @"key1": @2.2, @"key2": NSNull.null }];
    [managed.doubleObj addEntriesFromDictionary:@{ @"key1": @2.2, @"key2": @3.3 }];
    [optManaged.doubleObj addEntriesFromDictionary:@{ @"key1": @2.2, @"key2": NSNull.null }];
    [unmanaged.dataObj addEntriesFromDictionary:@{ @"key1": data(1), @"key2": data(2) }];
    [optUnmanaged.dataObj addEntriesFromDictionary:@{ @"key1": data(1), @"key2": NSNull.null }];
    [managed.dataObj addEntriesFromDictionary:@{ @"key1": data(1), @"key2": data(2) }];
    [optManaged.dataObj addEntriesFromDictionary:@{ @"key1": data(1), @"key2": NSNull.null }];
    [unmanaged.decimalObj addEntriesFromDictionary:@{ @"key1": decimal128(2), @"key2": decimal128(3) }];
    [optUnmanaged.decimalObj addEntriesFromDictionary:@{ @"key1": decimal128(2), @"key2": NSNull.null }];
    [managed.decimalObj addEntriesFromDictionary:@{ @"key1": decimal128(2), @"key2": decimal128(3) }];
    [optManaged.decimalObj addEntriesFromDictionary:@{ @"key1": decimal128(2), @"key2": NSNull.null }];
    [unmanaged.objectIdObj addEntriesFromDictionary:@{ @"key1": objectId(1), @"key2": objectId(2) }];
    [optUnmanaged.objectIdObj addEntriesFromDictionary:@{ @"key1": objectId(1), @"key2": NSNull.null }];
    [managed.objectIdObj addEntriesFromDictionary:@{ @"key1": objectId(1), @"key2": objectId(2) }];
    [optManaged.objectIdObj addEntriesFromDictionary:@{ @"key1": objectId(1), @"key2": NSNull.null }];
    [unmanaged.uuidObj addEntriesFromDictionary:@{ @"key1": uuid(@"00000000-0000-0000-0000-000000000000"), @"key2": uuid(@"137DECC8-B300-4954-A233-F89909F4FD89") }];
    [optUnmanaged.uuidObj addEntriesFromDictionary:@{ @"key1": uuid(@"00000000-0000-0000-0000-000000000000"), @"key2": NSNull.null }];
    [managed.uuidObj addEntriesFromDictionary:@{ @"key1": uuid(@"00000000-0000-0000-0000-000000000000"), @"key2": uuid(@"137DECC8-B300-4954-A233-F89909F4FD89") }];
    [optManaged.uuidObj addEntriesFromDictionary:@{ @"key1": uuid(@"00000000-0000-0000-0000-000000000000"), @"key2": NSNull.null }];
    [unmanaged.anyBoolObj addEntriesFromDictionary:@{ @"key1": @NO, @"key2": @YES }];
    [unmanaged.anyIntObj addEntriesFromDictionary:@{ @"key1": @2, @"key2": @3 }];
    [unmanaged.anyFloatObj addEntriesFromDictionary:@{ @"key1": @2.2f, @"key2": @3.3f }];
    [unmanaged.anyDoubleObj addEntriesFromDictionary:@{ @"key1": @2.2, @"key2": @3.3 }];
    [unmanaged.anyStringObj addEntriesFromDictionary:@{ @"key1": @"a", @"key2": @"b" }];
    [unmanaged.anyDataObj addEntriesFromDictionary:@{ @"key1": data(1), @"key2": data(2) }];
    [unmanaged.anyDateObj addEntriesFromDictionary:@{ @"key1": date(1), @"key2": date(2) }];
    [unmanaged.anyDecimalObj addEntriesFromDictionary:@{ @"key1": decimal128(2), @"key2": decimal128(3) }];
    [unmanaged.anyObjectIdObj addEntriesFromDictionary:@{ @"key1": objectId(1), @"key2": objectId(2) }];
    [unmanaged.anyUUIDObj addEntriesFromDictionary:@{ @"key1": uuid(@"00000000-0000-0000-0000-000000000000"), @"key2": uuid(@"137DECC8-B300-4954-A233-F89909F4FD89") }];
    [managed.anyBoolObj addEntriesFromDictionary:@{ @"key1": @NO, @"key2": @YES }];
    [managed.anyIntObj addEntriesFromDictionary:@{ @"key1": @2, @"key2": @3 }];
    [managed.anyFloatObj addEntriesFromDictionary:@{ @"key1": @2.2f, @"key2": @3.3f }];
    [managed.anyDoubleObj addEntriesFromDictionary:@{ @"key1": @2.2, @"key2": @3.3 }];
    [managed.anyStringObj addEntriesFromDictionary:@{ @"key1": @"a", @"key2": @"b" }];
    [managed.anyDataObj addEntriesFromDictionary:@{ @"key1": data(1), @"key2": data(2) }];
    [managed.anyDateObj addEntriesFromDictionary:@{ @"key1": date(1), @"key2": date(2) }];
    [managed.anyDecimalObj addEntriesFromDictionary:@{ @"key1": decimal128(2), @"key2": decimal128(3) }];
    [managed.anyObjectIdObj addEntriesFromDictionary:@{ @"key1": objectId(1), @"key2": objectId(2) }];
    [managed.anyUUIDObj addEntriesFromDictionary:@{ @"key1": uuid(@"00000000-0000-0000-0000-000000000000"), @"key2": uuid(@"137DECC8-B300-4954-A233-F89909F4FD89") }];

    XCTAssertEqual(1U, [[managed.boolObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:@NO]);
    XCTAssertEqual(1U, [[managed.intObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:@2]);
    XCTAssertEqual(1U, [[managed.stringObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:@"bar"]);
    XCTAssertEqual(1U, [[managed.dateObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:date(1)]);
    XCTAssertEqual(1U, [[managed.anyBoolObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:@NO]);
    XCTAssertEqual(1U, [[managed.anyIntObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:@2]);
    XCTAssertEqual(1U, [[managed.anyFloatObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:@2.2f]);
    XCTAssertEqual(1U, [[managed.anyDoubleObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:@2.2]);
    XCTAssertEqual(1U, [[managed.anyStringObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:@"a"]);
    XCTAssertEqual(1U, [[managed.anyDataObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:data(1)]);
    XCTAssertEqual(1U, [[managed.anyDateObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:date(1)]);
    XCTAssertEqual(1U, [[managed.anyDecimalObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:decimal128(2)]);
    XCTAssertEqual(1U, [[managed.anyUUIDObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:uuid(@"00000000-0000-0000-0000-000000000000")]);
    XCTAssertEqual(0U, [[managed.boolObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:@YES]);
    XCTAssertEqual(0U, [[managed.intObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:@3]);
    XCTAssertEqual(0U, [[managed.stringObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:@"foo"]);
    XCTAssertEqual(0U, [[managed.dateObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:date(2)]);
    XCTAssertEqual(0U, [[managed.anyBoolObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:@YES]);
    XCTAssertEqual(0U, [[managed.anyIntObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:@3]);
    XCTAssertEqual(0U, [[managed.anyFloatObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:@3.3f]);
    XCTAssertEqual(0U, [[managed.anyDoubleObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:@3.3]);
    XCTAssertEqual(0U, [[managed.anyStringObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:@"b"]);
    XCTAssertEqual(0U, [[managed.anyDataObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:data(2)]);
    XCTAssertEqual(0U, [[managed.anyDateObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:date(2)]);
    XCTAssertEqual(0U, [[managed.anyDecimalObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:decimal128(3)]);
    XCTAssertEqual(0U, [[managed.anyUUIDObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")]);

    XCTAssertEqual(1U, [[optManaged.boolObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:@NO]);
    XCTAssertEqual(1U, [[optManaged.intObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:@2]);
    XCTAssertEqual(1U, [[optManaged.stringObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:@"bar"]);
    XCTAssertEqual(1U, [[optManaged.dateObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:date(1)]);
    XCTAssertEqual(0U, [[optManaged.boolObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:(id)NSNull.null]);
    XCTAssertEqual(0U, [[optManaged.intObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:(id)NSNull.null]);
    XCTAssertEqual(0U, [[optManaged.stringObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:(id)NSNull.null]);
    XCTAssertEqual(0U, [[optManaged.dateObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:(id)NSNull.null]);
    XCTAssertEqual(0U, [[optManaged.boolObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:(id)NSNull.null]);
    XCTAssertEqual(0U, [[optManaged.intObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:(id)NSNull.null]);
    XCTAssertEqual(0U, [[optManaged.stringObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:(id)NSNull.null]);
    XCTAssertEqual(0U, [[optManaged.dateObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:(id)NSNull.null]);
}

- (void)testSort {
    RLMAssertThrowsWithReason([unmanaged.boolObj sortedResultsUsingKeyPath:@"self" ascending:NO],
                              @"This method may only be called on RLMDictionary instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([optUnmanaged.boolObj sortedResultsUsingKeyPath:@"self" ascending:NO],
                              @"This method may only be called on RLMDictionary instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.intObj sortedResultsUsingKeyPath:@"self" ascending:NO],
                              @"This method may only be called on RLMDictionary instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([optUnmanaged.intObj sortedResultsUsingKeyPath:@"self" ascending:NO],
                              @"This method may only be called on RLMDictionary instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.stringObj sortedResultsUsingKeyPath:@"self" ascending:NO],
                              @"This method may only be called on RLMDictionary instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([optUnmanaged.stringObj sortedResultsUsingKeyPath:@"self" ascending:NO],
                              @"This method may only be called on RLMDictionary instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.dateObj sortedResultsUsingKeyPath:@"self" ascending:NO],
                              @"This method may only be called on RLMDictionary instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([optUnmanaged.dateObj sortedResultsUsingKeyPath:@"self" ascending:NO],
                              @"This method may only be called on RLMDictionary instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.floatObj sortedResultsUsingKeyPath:@"self" ascending:NO],
                              @"This method may only be called on RLMDictionary instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([optUnmanaged.floatObj sortedResultsUsingKeyPath:@"self" ascending:NO],
                              @"This method may only be called on RLMDictionary instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.doubleObj sortedResultsUsingKeyPath:@"self" ascending:NO],
                              @"This method may only be called on RLMDictionary instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([optUnmanaged.doubleObj sortedResultsUsingKeyPath:@"self" ascending:NO],
                              @"This method may only be called on RLMDictionary instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.dataObj sortedResultsUsingKeyPath:@"self" ascending:NO],
                              @"This method may only be called on RLMDictionary instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([optUnmanaged.dataObj sortedResultsUsingKeyPath:@"self" ascending:NO],
                              @"This method may only be called on RLMDictionary instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.decimalObj sortedResultsUsingKeyPath:@"self" ascending:NO],
                              @"This method may only be called on RLMDictionary instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([optUnmanaged.decimalObj sortedResultsUsingKeyPath:@"self" ascending:NO],
                              @"This method may only be called on RLMDictionary instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.objectIdObj sortedResultsUsingKeyPath:@"self" ascending:NO],
                              @"This method may only be called on RLMDictionary instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([optUnmanaged.objectIdObj sortedResultsUsingKeyPath:@"self" ascending:NO],
                              @"This method may only be called on RLMDictionary instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.uuidObj sortedResultsUsingKeyPath:@"self" ascending:NO],
                              @"This method may only be called on RLMDictionary instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([optUnmanaged.uuidObj sortedResultsUsingKeyPath:@"self" ascending:NO],
                              @"This method may only be called on RLMDictionary instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.anyBoolObj sortedResultsUsingKeyPath:@"self" ascending:NO],
                              @"This method may only be called on RLMDictionary instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.anyIntObj sortedResultsUsingKeyPath:@"self" ascending:NO],
                              @"This method may only be called on RLMDictionary instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.anyFloatObj sortedResultsUsingKeyPath:@"self" ascending:NO],
                              @"This method may only be called on RLMDictionary instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.anyDoubleObj sortedResultsUsingKeyPath:@"self" ascending:NO],
                              @"This method may only be called on RLMDictionary instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.anyStringObj sortedResultsUsingKeyPath:@"self" ascending:NO],
                              @"This method may only be called on RLMDictionary instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.anyDataObj sortedResultsUsingKeyPath:@"self" ascending:NO],
                              @"This method may only be called on RLMDictionary instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.anyDateObj sortedResultsUsingKeyPath:@"self" ascending:NO],
                              @"This method may only be called on RLMDictionary instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.anyDecimalObj sortedResultsUsingKeyPath:@"self" ascending:NO],
                              @"This method may only be called on RLMDictionary instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.anyObjectIdObj sortedResultsUsingKeyPath:@"self" ascending:NO],
                              @"This method may only be called on RLMDictionary instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.anyUUIDObj sortedResultsUsingKeyPath:@"self" ascending:NO],
                              @"This method may only be called on RLMDictionary instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.boolObj sortedResultsUsingDescriptors:@[]],
                              @"This method may only be called on RLMDictionary instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([optUnmanaged.boolObj sortedResultsUsingDescriptors:@[]],
                              @"This method may only be called on RLMDictionary instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.intObj sortedResultsUsingDescriptors:@[]],
                              @"This method may only be called on RLMDictionary instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([optUnmanaged.intObj sortedResultsUsingDescriptors:@[]],
                              @"This method may only be called on RLMDictionary instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.stringObj sortedResultsUsingDescriptors:@[]],
                              @"This method may only be called on RLMDictionary instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([optUnmanaged.stringObj sortedResultsUsingDescriptors:@[]],
                              @"This method may only be called on RLMDictionary instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.dateObj sortedResultsUsingDescriptors:@[]],
                              @"This method may only be called on RLMDictionary instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([optUnmanaged.dateObj sortedResultsUsingDescriptors:@[]],
                              @"This method may only be called on RLMDictionary instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.floatObj sortedResultsUsingDescriptors:@[]],
                              @"This method may only be called on RLMDictionary instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([optUnmanaged.floatObj sortedResultsUsingDescriptors:@[]],
                              @"This method may only be called on RLMDictionary instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.doubleObj sortedResultsUsingDescriptors:@[]],
                              @"This method may only be called on RLMDictionary instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([optUnmanaged.doubleObj sortedResultsUsingDescriptors:@[]],
                              @"This method may only be called on RLMDictionary instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.dataObj sortedResultsUsingDescriptors:@[]],
                              @"This method may only be called on RLMDictionary instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([optUnmanaged.dataObj sortedResultsUsingDescriptors:@[]],
                              @"This method may only be called on RLMDictionary instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.decimalObj sortedResultsUsingDescriptors:@[]],
                              @"This method may only be called on RLMDictionary instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([optUnmanaged.decimalObj sortedResultsUsingDescriptors:@[]],
                              @"This method may only be called on RLMDictionary instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.objectIdObj sortedResultsUsingDescriptors:@[]],
                              @"This method may only be called on RLMDictionary instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([optUnmanaged.objectIdObj sortedResultsUsingDescriptors:@[]],
                              @"This method may only be called on RLMDictionary instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.uuidObj sortedResultsUsingDescriptors:@[]],
                              @"This method may only be called on RLMDictionary instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([optUnmanaged.uuidObj sortedResultsUsingDescriptors:@[]],
                              @"This method may only be called on RLMDictionary instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.anyBoolObj sortedResultsUsingDescriptors:@[]],
                              @"This method may only be called on RLMDictionary instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.anyIntObj sortedResultsUsingDescriptors:@[]],
                              @"This method may only be called on RLMDictionary instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.anyFloatObj sortedResultsUsingDescriptors:@[]],
                              @"This method may only be called on RLMDictionary instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.anyDoubleObj sortedResultsUsingDescriptors:@[]],
                              @"This method may only be called on RLMDictionary instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.anyStringObj sortedResultsUsingDescriptors:@[]],
                              @"This method may only be called on RLMDictionary instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.anyDataObj sortedResultsUsingDescriptors:@[]],
                              @"This method may only be called on RLMDictionary instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.anyDateObj sortedResultsUsingDescriptors:@[]],
                              @"This method may only be called on RLMDictionary instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.anyDecimalObj sortedResultsUsingDescriptors:@[]],
                              @"This method may only be called on RLMDictionary instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.anyObjectIdObj sortedResultsUsingDescriptors:@[]],
                              @"This method may only be called on RLMDictionary instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.anyUUIDObj sortedResultsUsingDescriptors:@[]],
                              @"This method may only be called on RLMDictionary instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([managed.boolObj sortedResultsUsingKeyPath:@"not self" ascending:NO],
                              @"can only be sorted on 'self'");
    RLMAssertThrowsWithReason([optManaged.boolObj sortedResultsUsingKeyPath:@"not self" ascending:NO],
                              @"can only be sorted on 'self'");
    RLMAssertThrowsWithReason([managed.intObj sortedResultsUsingKeyPath:@"not self" ascending:NO],
                              @"can only be sorted on 'self'");
    RLMAssertThrowsWithReason([optManaged.intObj sortedResultsUsingKeyPath:@"not self" ascending:NO],
                              @"can only be sorted on 'self'");
    RLMAssertThrowsWithReason([managed.stringObj sortedResultsUsingKeyPath:@"not self" ascending:NO],
                              @"can only be sorted on 'self'");
    RLMAssertThrowsWithReason([optManaged.stringObj sortedResultsUsingKeyPath:@"not self" ascending:NO],
                              @"can only be sorted on 'self'");
    RLMAssertThrowsWithReason([managed.dateObj sortedResultsUsingKeyPath:@"not self" ascending:NO],
                              @"can only be sorted on 'self'");
    RLMAssertThrowsWithReason([optManaged.dateObj sortedResultsUsingKeyPath:@"not self" ascending:NO],
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
    RLMAssertThrowsWithReason([managed.anyUUIDObj sortedResultsUsingKeyPath:@"not self" ascending:NO],
                              @"can only be sorted on 'self'");

    [unmanaged.boolObj addEntriesFromDictionary:@{ @"key1": @NO, @"key2": @YES }];
    [optUnmanaged.boolObj addEntriesFromDictionary:@{ @"key1": @NO, @"key2": NSNull.null }];
    [managed.boolObj addEntriesFromDictionary:@{ @"key1": @NO, @"key2": @YES }];
    [optManaged.boolObj addEntriesFromDictionary:@{ @"key1": @NO, @"key2": NSNull.null }];
    [unmanaged.intObj addEntriesFromDictionary:@{ @"key1": @2, @"key2": @3 }];
    [optUnmanaged.intObj addEntriesFromDictionary:@{ @"key1": @2, @"key2": NSNull.null }];
    [managed.intObj addEntriesFromDictionary:@{ @"key1": @2, @"key2": @3 }];
    [optManaged.intObj addEntriesFromDictionary:@{ @"key1": @2, @"key2": NSNull.null }];
    [unmanaged.stringObj addEntriesFromDictionary:@{ @"key1": @"bar", @"key2": @"foo" }];
    [optUnmanaged.stringObj addEntriesFromDictionary:@{ @"key1": @"bar", @"key2": NSNull.null }];
    [managed.stringObj addEntriesFromDictionary:@{ @"key1": @"bar", @"key2": @"foo" }];
    [optManaged.stringObj addEntriesFromDictionary:@{ @"key1": @"bar", @"key2": NSNull.null }];
    [unmanaged.dateObj addEntriesFromDictionary:@{ @"key1": date(1), @"key2": date(2) }];
    [optUnmanaged.dateObj addEntriesFromDictionary:@{ @"key1": date(1), @"key2": NSNull.null }];
    [managed.dateObj addEntriesFromDictionary:@{ @"key1": date(1), @"key2": date(2) }];
    [optManaged.dateObj addEntriesFromDictionary:@{ @"key1": date(1), @"key2": NSNull.null }];
    [unmanaged.floatObj addEntriesFromDictionary:@{ @"key1": @2.2f, @"key2": @3.3f }];
    [optUnmanaged.floatObj addEntriesFromDictionary:@{ @"key1": @2.2f, @"key2": NSNull.null }];
    [managed.floatObj addEntriesFromDictionary:@{ @"key1": @2.2f, @"key2": @3.3f }];
    [optManaged.floatObj addEntriesFromDictionary:@{ @"key1": @2.2f, @"key2": NSNull.null }];
    [unmanaged.doubleObj addEntriesFromDictionary:@{ @"key1": @2.2, @"key2": @3.3 }];
    [optUnmanaged.doubleObj addEntriesFromDictionary:@{ @"key1": @2.2, @"key2": NSNull.null }];
    [managed.doubleObj addEntriesFromDictionary:@{ @"key1": @2.2, @"key2": @3.3 }];
    [optManaged.doubleObj addEntriesFromDictionary:@{ @"key1": @2.2, @"key2": NSNull.null }];
    [unmanaged.dataObj addEntriesFromDictionary:@{ @"key1": data(1), @"key2": data(2) }];
    [optUnmanaged.dataObj addEntriesFromDictionary:@{ @"key1": data(1), @"key2": NSNull.null }];
    [managed.dataObj addEntriesFromDictionary:@{ @"key1": data(1), @"key2": data(2) }];
    [optManaged.dataObj addEntriesFromDictionary:@{ @"key1": data(1), @"key2": NSNull.null }];
    [unmanaged.decimalObj addEntriesFromDictionary:@{ @"key1": decimal128(2), @"key2": decimal128(3) }];
    [optUnmanaged.decimalObj addEntriesFromDictionary:@{ @"key1": decimal128(2), @"key2": NSNull.null }];
    [managed.decimalObj addEntriesFromDictionary:@{ @"key1": decimal128(2), @"key2": decimal128(3) }];
    [optManaged.decimalObj addEntriesFromDictionary:@{ @"key1": decimal128(2), @"key2": NSNull.null }];
    [unmanaged.objectIdObj addEntriesFromDictionary:@{ @"key1": objectId(1), @"key2": objectId(2) }];
    [optUnmanaged.objectIdObj addEntriesFromDictionary:@{ @"key1": objectId(1), @"key2": NSNull.null }];
    [managed.objectIdObj addEntriesFromDictionary:@{ @"key1": objectId(1), @"key2": objectId(2) }];
    [optManaged.objectIdObj addEntriesFromDictionary:@{ @"key1": objectId(1), @"key2": NSNull.null }];
    [unmanaged.uuidObj addEntriesFromDictionary:@{ @"key1": uuid(@"00000000-0000-0000-0000-000000000000"), @"key2": uuid(@"137DECC8-B300-4954-A233-F89909F4FD89") }];
    [optUnmanaged.uuidObj addEntriesFromDictionary:@{ @"key1": uuid(@"00000000-0000-0000-0000-000000000000"), @"key2": NSNull.null }];
    [managed.uuidObj addEntriesFromDictionary:@{ @"key1": uuid(@"00000000-0000-0000-0000-000000000000"), @"key2": uuid(@"137DECC8-B300-4954-A233-F89909F4FD89") }];
    [optManaged.uuidObj addEntriesFromDictionary:@{ @"key1": uuid(@"00000000-0000-0000-0000-000000000000"), @"key2": NSNull.null }];
    [unmanaged.anyBoolObj addEntriesFromDictionary:@{ @"key1": @NO, @"key2": @YES }];
    [unmanaged.anyIntObj addEntriesFromDictionary:@{ @"key1": @2, @"key2": @3 }];
    [unmanaged.anyFloatObj addEntriesFromDictionary:@{ @"key1": @2.2f, @"key2": @3.3f }];
    [unmanaged.anyDoubleObj addEntriesFromDictionary:@{ @"key1": @2.2, @"key2": @3.3 }];
    [unmanaged.anyStringObj addEntriesFromDictionary:@{ @"key1": @"a", @"key2": @"b" }];
    [unmanaged.anyDataObj addEntriesFromDictionary:@{ @"key1": data(1), @"key2": data(2) }];
    [unmanaged.anyDateObj addEntriesFromDictionary:@{ @"key1": date(1), @"key2": date(2) }];
    [unmanaged.anyDecimalObj addEntriesFromDictionary:@{ @"key1": decimal128(2), @"key2": decimal128(3) }];
    [unmanaged.anyObjectIdObj addEntriesFromDictionary:@{ @"key1": objectId(1), @"key2": objectId(2) }];
    [unmanaged.anyUUIDObj addEntriesFromDictionary:@{ @"key1": uuid(@"00000000-0000-0000-0000-000000000000"), @"key2": uuid(@"137DECC8-B300-4954-A233-F89909F4FD89") }];
    [managed.anyBoolObj addEntriesFromDictionary:@{ @"key1": @NO, @"key2": @YES }];
    [managed.anyIntObj addEntriesFromDictionary:@{ @"key1": @2, @"key2": @3 }];
    [managed.anyFloatObj addEntriesFromDictionary:@{ @"key1": @2.2f, @"key2": @3.3f }];
    [managed.anyDoubleObj addEntriesFromDictionary:@{ @"key1": @2.2, @"key2": @3.3 }];
    [managed.anyStringObj addEntriesFromDictionary:@{ @"key1": @"a", @"key2": @"b" }];
    [managed.anyDataObj addEntriesFromDictionary:@{ @"key1": data(1), @"key2": data(2) }];
    [managed.anyDateObj addEntriesFromDictionary:@{ @"key1": date(1), @"key2": date(2) }];
    [managed.anyDecimalObj addEntriesFromDictionary:@{ @"key1": decimal128(2), @"key2": decimal128(3) }];
    [managed.anyObjectIdObj addEntriesFromDictionary:@{ @"key1": objectId(1), @"key2": objectId(2) }];
    [managed.anyUUIDObj addEntriesFromDictionary:@{ @"key1": uuid(@"00000000-0000-0000-0000-000000000000"), @"key2": uuid(@"137DECC8-B300-4954-A233-F89909F4FD89") }];

    XCTAssertEqualObjects([[managed.boolObj sortedResultsUsingDescriptors:@[]] valueForKey:@"self"],
                          (@[@YES, @NO]));
    XCTAssertEqualObjects([[optManaged.boolObj sortedResultsUsingDescriptors:@[]] valueForKey:@"self"],
                          (@[NSNull.null, @NO]));
    XCTAssertEqualObjects([[managed.intObj sortedResultsUsingDescriptors:@[]] valueForKey:@"self"],
                          (@[@3, @2]));
    XCTAssertEqualObjects([[optManaged.intObj sortedResultsUsingDescriptors:@[]] valueForKey:@"self"],
                          (@[NSNull.null, @2]));
    XCTAssertEqualObjects([[managed.stringObj sortedResultsUsingDescriptors:@[]] valueForKey:@"self"],
                          (@[@"foo", @"bar"]));
    XCTAssertEqualObjects([[optManaged.stringObj sortedResultsUsingDescriptors:@[]] valueForKey:@"self"],
                          (@[NSNull.null, @"bar"]));
    XCTAssertEqualObjects([[managed.dateObj sortedResultsUsingDescriptors:@[]] valueForKey:@"self"],
                          (@[date(2), date(1)]));
    XCTAssertEqualObjects([[optManaged.dateObj sortedResultsUsingDescriptors:@[]] valueForKey:@"self"],
                          (@[NSNull.null, date(1)]));
    XCTAssertEqualObjects([[managed.anyBoolObj sortedResultsUsingDescriptors:@[]] valueForKey:@"self"],
                          (@[@YES, @NO]));
    XCTAssertEqualObjects([[managed.anyIntObj sortedResultsUsingDescriptors:@[]] valueForKey:@"self"],
                          (@[@3, @2]));
    XCTAssertEqualObjects([[managed.anyFloatObj sortedResultsUsingDescriptors:@[]] valueForKey:@"self"],
                          (@[@3.3f, @2.2f]));
    XCTAssertEqualObjects([[managed.anyDoubleObj sortedResultsUsingDescriptors:@[]] valueForKey:@"self"],
                          (@[@3.3, @2.2]));
    XCTAssertEqualObjects([[managed.anyStringObj sortedResultsUsingDescriptors:@[]] valueForKey:@"self"],
                          (@[@"b", @"a"]));
    XCTAssertEqualObjects([[managed.anyDataObj sortedResultsUsingDescriptors:@[]] valueForKey:@"self"],
                          (@[data(2), data(1)]));
    XCTAssertEqualObjects([[managed.anyDateObj sortedResultsUsingDescriptors:@[]] valueForKey:@"self"],
                          (@[date(2), date(1)]));
    XCTAssertEqualObjects([[managed.anyDecimalObj sortedResultsUsingDescriptors:@[]] valueForKey:@"self"],
                          (@[decimal128(3), decimal128(2)]));
    XCTAssertEqualObjects([[managed.anyUUIDObj sortedResultsUsingDescriptors:@[]] valueForKey:@"self"],
                          (@[uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"), uuid(@"00000000-0000-0000-0000-000000000000")]));

    XCTAssertEqualObjects([[managed.boolObj sortedResultsUsingKeyPath:@"self" ascending:NO] valueForKey:@"self"],
                          (@[@YES, @NO]));
    XCTAssertEqualObjects([[managed.intObj sortedResultsUsingKeyPath:@"self" ascending:NO] valueForKey:@"self"],
                          (@[@3, @2]));
    XCTAssertEqualObjects([[managed.stringObj sortedResultsUsingKeyPath:@"self" ascending:NO] valueForKey:@"self"],
                          (@[@"foo", @"bar"]));
    XCTAssertEqualObjects([[managed.dateObj sortedResultsUsingKeyPath:@"self" ascending:NO] valueForKey:@"self"],
                          (@[date(2), date(1)]));
    XCTAssertEqualObjects([[managed.anyBoolObj sortedResultsUsingKeyPath:@"self" ascending:NO] valueForKey:@"self"],
                          (@[@YES, @NO]));
    XCTAssertEqualObjects([[managed.anyIntObj sortedResultsUsingKeyPath:@"self" ascending:NO] valueForKey:@"self"],
                          (@[@3, @2]));
    XCTAssertEqualObjects([[managed.anyFloatObj sortedResultsUsingKeyPath:@"self" ascending:NO] valueForKey:@"self"],
                          (@[@3.3f, @2.2f]));
    XCTAssertEqualObjects([[managed.anyDoubleObj sortedResultsUsingKeyPath:@"self" ascending:NO] valueForKey:@"self"],
                          (@[@3.3, @2.2]));
    XCTAssertEqualObjects([[managed.anyStringObj sortedResultsUsingKeyPath:@"self" ascending:NO] valueForKey:@"self"],
                          (@[@"b", @"a"]));
    XCTAssertEqualObjects([[managed.anyDataObj sortedResultsUsingKeyPath:@"self" ascending:NO] valueForKey:@"self"],
                          (@[data(2), data(1)]));
    XCTAssertEqualObjects([[managed.anyDateObj sortedResultsUsingKeyPath:@"self" ascending:NO] valueForKey:@"self"],
                          (@[date(2), date(1)]));
    XCTAssertEqualObjects([[managed.anyDecimalObj sortedResultsUsingKeyPath:@"self" ascending:NO] valueForKey:@"self"],
                          (@[decimal128(3), decimal128(2)]));
    XCTAssertEqualObjects([[managed.anyUUIDObj sortedResultsUsingKeyPath:@"self" ascending:NO] valueForKey:@"self"],
                          (@[uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"), uuid(@"00000000-0000-0000-0000-000000000000")]));
    XCTAssertEqualObjects([[optManaged.boolObj sortedResultsUsingKeyPath:@"self" ascending:NO] valueForKey:@"self"],
                          (@[@NO, NSNull.null]));
    XCTAssertEqualObjects([[optManaged.intObj sortedResultsUsingKeyPath:@"self" ascending:NO] valueForKey:@"self"],
                          (@[@2, NSNull.null]));
    XCTAssertEqualObjects([[optManaged.stringObj sortedResultsUsingKeyPath:@"self" ascending:NO] valueForKey:@"self"],
                          (@[@"bar", NSNull.null]));
    XCTAssertEqualObjects([[optManaged.dateObj sortedResultsUsingKeyPath:@"self" ascending:NO] valueForKey:@"self"],
                          (@[date(1), NSNull.null]));

    XCTAssertEqualObjects([[managed.boolObj sortedResultsUsingKeyPath:@"self" ascending:YES] valueForKey:@"self"],
                          (@[@NO, @YES]));
    XCTAssertEqualObjects([[managed.intObj sortedResultsUsingKeyPath:@"self" ascending:YES] valueForKey:@"self"],
                          (@[@2, @3]));
    XCTAssertEqualObjects([[managed.stringObj sortedResultsUsingKeyPath:@"self" ascending:YES] valueForKey:@"self"],
                          (@[@"bar", @"foo"]));
    XCTAssertEqualObjects([[managed.dateObj sortedResultsUsingKeyPath:@"self" ascending:YES] valueForKey:@"self"],
                          (@[date(1), date(2)]));
    XCTAssertEqualObjects([[managed.anyBoolObj sortedResultsUsingKeyPath:@"self" ascending:YES] valueForKey:@"self"],
                          (@[@NO, @YES]));
    XCTAssertEqualObjects([[managed.anyIntObj sortedResultsUsingKeyPath:@"self" ascending:YES] valueForKey:@"self"],
                          (@[@2, @3]));
    XCTAssertEqualObjects([[managed.anyFloatObj sortedResultsUsingKeyPath:@"self" ascending:YES] valueForKey:@"self"],
                          (@[@2.2f, @3.3f]));
    XCTAssertEqualObjects([[managed.anyDoubleObj sortedResultsUsingKeyPath:@"self" ascending:YES] valueForKey:@"self"],
                          (@[@2.2, @3.3]));
    XCTAssertEqualObjects([[managed.anyStringObj sortedResultsUsingKeyPath:@"self" ascending:YES] valueForKey:@"self"],
                          (@[@"a", @"b"]));
    XCTAssertEqualObjects([[managed.anyDataObj sortedResultsUsingKeyPath:@"self" ascending:YES] valueForKey:@"self"],
                          (@[data(1), data(2)]));
    XCTAssertEqualObjects([[managed.anyDateObj sortedResultsUsingKeyPath:@"self" ascending:YES] valueForKey:@"self"],
                          (@[date(1), date(2)]));
    XCTAssertEqualObjects([[managed.anyDecimalObj sortedResultsUsingKeyPath:@"self" ascending:YES] valueForKey:@"self"],
                          (@[decimal128(2), decimal128(3)]));
    XCTAssertEqualObjects([[managed.anyUUIDObj sortedResultsUsingKeyPath:@"self" ascending:YES] valueForKey:@"self"],
                          (@[uuid(@"00000000-0000-0000-0000-000000000000"), uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")]));
    XCTAssertEqualObjects([[optManaged.boolObj sortedResultsUsingKeyPath:@"self" ascending:YES] valueForKey:@"self"],
                          (@[NSNull.null, @NO]));
    XCTAssertEqualObjects([[optManaged.intObj sortedResultsUsingKeyPath:@"self" ascending:YES] valueForKey:@"self"],
                          (@[NSNull.null, @2]));
    XCTAssertEqualObjects([[optManaged.stringObj sortedResultsUsingKeyPath:@"self" ascending:YES] valueForKey:@"self"],
                          (@[NSNull.null, @"bar"]));
    XCTAssertEqualObjects([[optManaged.dateObj sortedResultsUsingKeyPath:@"self" ascending:YES] valueForKey:@"self"],
                          (@[NSNull.null, date(1)]));
}

- (void)testFilter {
    RLMAssertThrowsWithReason([unmanaged.boolObj objectsWhere:@"TRUEPREDICATE"],
                              @"This method may only be called on RLMDictionary instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([optUnmanaged.boolObj objectsWhere:@"TRUEPREDICATE"],
                              @"This method may only be called on RLMDictionary instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.intObj objectsWhere:@"TRUEPREDICATE"],
                              @"This method may only be called on RLMDictionary instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([optUnmanaged.intObj objectsWhere:@"TRUEPREDICATE"],
                              @"This method may only be called on RLMDictionary instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.stringObj objectsWhere:@"TRUEPREDICATE"],
                              @"This method may only be called on RLMDictionary instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([optUnmanaged.stringObj objectsWhere:@"TRUEPREDICATE"],
                              @"This method may only be called on RLMDictionary instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.dateObj objectsWhere:@"TRUEPREDICATE"],
                              @"This method may only be called on RLMDictionary instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([optUnmanaged.dateObj objectsWhere:@"TRUEPREDICATE"],
                              @"This method may only be called on RLMDictionary instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.floatObj objectsWhere:@"TRUEPREDICATE"],
                              @"This method may only be called on RLMDictionary instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([optUnmanaged.floatObj objectsWhere:@"TRUEPREDICATE"],
                              @"This method may only be called on RLMDictionary instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.doubleObj objectsWhere:@"TRUEPREDICATE"],
                              @"This method may only be called on RLMDictionary instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([optUnmanaged.doubleObj objectsWhere:@"TRUEPREDICATE"],
                              @"This method may only be called on RLMDictionary instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.dataObj objectsWhere:@"TRUEPREDICATE"],
                              @"This method may only be called on RLMDictionary instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([optUnmanaged.dataObj objectsWhere:@"TRUEPREDICATE"],
                              @"This method may only be called on RLMDictionary instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.decimalObj objectsWhere:@"TRUEPREDICATE"],
                              @"This method may only be called on RLMDictionary instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([optUnmanaged.decimalObj objectsWhere:@"TRUEPREDICATE"],
                              @"This method may only be called on RLMDictionary instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.objectIdObj objectsWhere:@"TRUEPREDICATE"],
                              @"This method may only be called on RLMDictionary instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([optUnmanaged.objectIdObj objectsWhere:@"TRUEPREDICATE"],
                              @"This method may only be called on RLMDictionary instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.uuidObj objectsWhere:@"TRUEPREDICATE"],
                              @"This method may only be called on RLMDictionary instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([optUnmanaged.uuidObj objectsWhere:@"TRUEPREDICATE"],
                              @"This method may only be called on RLMDictionary instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.anyBoolObj objectsWhere:@"TRUEPREDICATE"],
                              @"This method may only be called on RLMDictionary instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.anyIntObj objectsWhere:@"TRUEPREDICATE"],
                              @"This method may only be called on RLMDictionary instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.anyFloatObj objectsWhere:@"TRUEPREDICATE"],
                              @"This method may only be called on RLMDictionary instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.anyDoubleObj objectsWhere:@"TRUEPREDICATE"],
                              @"This method may only be called on RLMDictionary instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.anyStringObj objectsWhere:@"TRUEPREDICATE"],
                              @"This method may only be called on RLMDictionary instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.anyDataObj objectsWhere:@"TRUEPREDICATE"],
                              @"This method may only be called on RLMDictionary instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.anyDateObj objectsWhere:@"TRUEPREDICATE"],
                              @"This method may only be called on RLMDictionary instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.anyDecimalObj objectsWhere:@"TRUEPREDICATE"],
                              @"This method may only be called on RLMDictionary instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.anyObjectIdObj objectsWhere:@"TRUEPREDICATE"],
                              @"This method may only be called on RLMDictionary instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.anyUUIDObj objectsWhere:@"TRUEPREDICATE"],
                              @"This method may only be called on RLMDictionary instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.boolObj objectsWithPredicate:[NSPredicate predicateWithValue:YES]],
                              @"This method may only be called on RLMDictionary instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([optUnmanaged.boolObj objectsWithPredicate:[NSPredicate predicateWithValue:YES]],
                              @"This method may only be called on RLMDictionary instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.intObj objectsWithPredicate:[NSPredicate predicateWithValue:YES]],
                              @"This method may only be called on RLMDictionary instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([optUnmanaged.intObj objectsWithPredicate:[NSPredicate predicateWithValue:YES]],
                              @"This method may only be called on RLMDictionary instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.stringObj objectsWithPredicate:[NSPredicate predicateWithValue:YES]],
                              @"This method may only be called on RLMDictionary instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([optUnmanaged.stringObj objectsWithPredicate:[NSPredicate predicateWithValue:YES]],
                              @"This method may only be called on RLMDictionary instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.dateObj objectsWithPredicate:[NSPredicate predicateWithValue:YES]],
                              @"This method may only be called on RLMDictionary instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([optUnmanaged.dateObj objectsWithPredicate:[NSPredicate predicateWithValue:YES]],
                              @"This method may only be called on RLMDictionary instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.floatObj objectsWithPredicate:[NSPredicate predicateWithValue:YES]],
                              @"This method may only be called on RLMDictionary instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([optUnmanaged.floatObj objectsWithPredicate:[NSPredicate predicateWithValue:YES]],
                              @"This method may only be called on RLMDictionary instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.doubleObj objectsWithPredicate:[NSPredicate predicateWithValue:YES]],
                              @"This method may only be called on RLMDictionary instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([optUnmanaged.doubleObj objectsWithPredicate:[NSPredicate predicateWithValue:YES]],
                              @"This method may only be called on RLMDictionary instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.dataObj objectsWithPredicate:[NSPredicate predicateWithValue:YES]],
                              @"This method may only be called on RLMDictionary instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([optUnmanaged.dataObj objectsWithPredicate:[NSPredicate predicateWithValue:YES]],
                              @"This method may only be called on RLMDictionary instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.decimalObj objectsWithPredicate:[NSPredicate predicateWithValue:YES]],
                              @"This method may only be called on RLMDictionary instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([optUnmanaged.decimalObj objectsWithPredicate:[NSPredicate predicateWithValue:YES]],
                              @"This method may only be called on RLMDictionary instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.objectIdObj objectsWithPredicate:[NSPredicate predicateWithValue:YES]],
                              @"This method may only be called on RLMDictionary instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([optUnmanaged.objectIdObj objectsWithPredicate:[NSPredicate predicateWithValue:YES]],
                              @"This method may only be called on RLMDictionary instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.uuidObj objectsWithPredicate:[NSPredicate predicateWithValue:YES]],
                              @"This method may only be called on RLMDictionary instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([optUnmanaged.uuidObj objectsWithPredicate:[NSPredicate predicateWithValue:YES]],
                              @"This method may only be called on RLMDictionary instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.anyBoolObj objectsWithPredicate:[NSPredicate predicateWithValue:YES]],
                              @"This method may only be called on RLMDictionary instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.anyIntObj objectsWithPredicate:[NSPredicate predicateWithValue:YES]],
                              @"This method may only be called on RLMDictionary instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.anyFloatObj objectsWithPredicate:[NSPredicate predicateWithValue:YES]],
                              @"This method may only be called on RLMDictionary instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.anyDoubleObj objectsWithPredicate:[NSPredicate predicateWithValue:YES]],
                              @"This method may only be called on RLMDictionary instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.anyStringObj objectsWithPredicate:[NSPredicate predicateWithValue:YES]],
                              @"This method may only be called on RLMDictionary instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.anyDataObj objectsWithPredicate:[NSPredicate predicateWithValue:YES]],
                              @"This method may only be called on RLMDictionary instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.anyDateObj objectsWithPredicate:[NSPredicate predicateWithValue:YES]],
                              @"This method may only be called on RLMDictionary instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.anyDecimalObj objectsWithPredicate:[NSPredicate predicateWithValue:YES]],
                              @"This method may only be called on RLMDictionary instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.anyObjectIdObj objectsWithPredicate:[NSPredicate predicateWithValue:YES]],
                              @"This method may only be called on RLMDictionary instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.anyUUIDObj objectsWithPredicate:[NSPredicate predicateWithValue:YES]],
                              @"This method may only be called on RLMDictionary instances retrieved from an RLMRealm");

    RLMAssertThrowsWithReason([managed.boolObj objectsWhere:@"TRUEPREDICATE"],
                              @"implemented");
    RLMAssertThrowsWithReason([optManaged.boolObj objectsWhere:@"TRUEPREDICATE"],
                              @"implemented");
    RLMAssertThrowsWithReason([managed.intObj objectsWhere:@"TRUEPREDICATE"],
                              @"implemented");
    RLMAssertThrowsWithReason([optManaged.intObj objectsWhere:@"TRUEPREDICATE"],
                              @"implemented");
    RLMAssertThrowsWithReason([managed.stringObj objectsWhere:@"TRUEPREDICATE"],
                              @"implemented");
    RLMAssertThrowsWithReason([optManaged.stringObj objectsWhere:@"TRUEPREDICATE"],
                              @"implemented");
    RLMAssertThrowsWithReason([managed.dateObj objectsWhere:@"TRUEPREDICATE"],
                              @"implemented");
    RLMAssertThrowsWithReason([optManaged.dateObj objectsWhere:@"TRUEPREDICATE"],
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
    RLMAssertThrowsWithReason([managed.anyUUIDObj objectsWhere:@"TRUEPREDICATE"],
                              @"implemented");
    RLMAssertThrowsWithReason([managed.boolObj objectsWithPredicate:[NSPredicate predicateWithValue:YES]],
                              @"implemented");
    RLMAssertThrowsWithReason([optManaged.boolObj objectsWithPredicate:[NSPredicate predicateWithValue:YES]],
                              @"implemented");
    RLMAssertThrowsWithReason([managed.intObj objectsWithPredicate:[NSPredicate predicateWithValue:YES]],
                              @"implemented");
    RLMAssertThrowsWithReason([optManaged.intObj objectsWithPredicate:[NSPredicate predicateWithValue:YES]],
                              @"implemented");
    RLMAssertThrowsWithReason([managed.stringObj objectsWithPredicate:[NSPredicate predicateWithValue:YES]],
                              @"implemented");
    RLMAssertThrowsWithReason([optManaged.stringObj objectsWithPredicate:[NSPredicate predicateWithValue:YES]],
                              @"implemented");
    RLMAssertThrowsWithReason([managed.dateObj objectsWithPredicate:[NSPredicate predicateWithValue:YES]],
                              @"implemented");
    RLMAssertThrowsWithReason([optManaged.dateObj objectsWithPredicate:[NSPredicate predicateWithValue:YES]],
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
    RLMAssertThrowsWithReason([managed.anyUUIDObj objectsWithPredicate:[NSPredicate predicateWithValue:YES]],
                              @"implemented");

    RLMAssertThrowsWithReason([[managed.boolObj sortedResultsUsingKeyPath:@"self" ascending:NO]
                               objectsWhere:@"TRUEPREDICATE"], @"implemented");
    RLMAssertThrowsWithReason([[optManaged.boolObj sortedResultsUsingKeyPath:@"self" ascending:NO]
                               objectsWhere:@"TRUEPREDICATE"], @"implemented");
    RLMAssertThrowsWithReason([[managed.intObj sortedResultsUsingKeyPath:@"self" ascending:NO]
                               objectsWhere:@"TRUEPREDICATE"], @"implemented");
    RLMAssertThrowsWithReason([[optManaged.intObj sortedResultsUsingKeyPath:@"self" ascending:NO]
                               objectsWhere:@"TRUEPREDICATE"], @"implemented");
    RLMAssertThrowsWithReason([[managed.stringObj sortedResultsUsingKeyPath:@"self" ascending:NO]
                               objectsWhere:@"TRUEPREDICATE"], @"implemented");
    RLMAssertThrowsWithReason([[optManaged.stringObj sortedResultsUsingKeyPath:@"self" ascending:NO]
                               objectsWhere:@"TRUEPREDICATE"], @"implemented");
    RLMAssertThrowsWithReason([[managed.dateObj sortedResultsUsingKeyPath:@"self" ascending:NO]
                               objectsWhere:@"TRUEPREDICATE"], @"implemented");
    RLMAssertThrowsWithReason([[optManaged.dateObj sortedResultsUsingKeyPath:@"self" ascending:NO]
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
    RLMAssertThrowsWithReason([[managed.anyUUIDObj sortedResultsUsingKeyPath:@"self" ascending:NO]
                               objectsWhere:@"TRUEPREDICATE"], @"implemented");
    RLMAssertThrowsWithReason([[managed.boolObj sortedResultsUsingKeyPath:@"self" ascending:NO]
                               objectsWithPredicate:[NSPredicate predicateWithValue:YES]], @"implemented");
    RLMAssertThrowsWithReason([[optManaged.boolObj sortedResultsUsingKeyPath:@"self" ascending:NO]
                               objectsWithPredicate:[NSPredicate predicateWithValue:YES]], @"implemented");
    RLMAssertThrowsWithReason([[managed.intObj sortedResultsUsingKeyPath:@"self" ascending:NO]
                               objectsWithPredicate:[NSPredicate predicateWithValue:YES]], @"implemented");
    RLMAssertThrowsWithReason([[optManaged.intObj sortedResultsUsingKeyPath:@"self" ascending:NO]
                               objectsWithPredicate:[NSPredicate predicateWithValue:YES]], @"implemented");
    RLMAssertThrowsWithReason([[managed.stringObj sortedResultsUsingKeyPath:@"self" ascending:NO]
                               objectsWithPredicate:[NSPredicate predicateWithValue:YES]], @"implemented");
    RLMAssertThrowsWithReason([[optManaged.stringObj sortedResultsUsingKeyPath:@"self" ascending:NO]
                               objectsWithPredicate:[NSPredicate predicateWithValue:YES]], @"implemented");
    RLMAssertThrowsWithReason([[managed.dateObj sortedResultsUsingKeyPath:@"self" ascending:NO]
                               objectsWithPredicate:[NSPredicate predicateWithValue:YES]], @"implemented");
    RLMAssertThrowsWithReason([[optManaged.dateObj sortedResultsUsingKeyPath:@"self" ascending:NO]
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
    RLMAssertThrowsWithReason([[managed.anyUUIDObj sortedResultsUsingKeyPath:@"self" ascending:NO]
                               objectsWithPredicate:[NSPredicate predicateWithValue:YES]], @"implemented");
}

- (void)testNotifications {
    RLMAssertThrowsWithReason([unmanaged.boolObj addNotificationBlock:^(__unused id a, __unused id c, __unused id e) { }],
                              @"This method may only be called on RLMDictionary instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([optUnmanaged.boolObj addNotificationBlock:^(__unused id a, __unused id c, __unused id e) { }],
                              @"This method may only be called on RLMDictionary instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.intObj addNotificationBlock:^(__unused id a, __unused id c, __unused id e) { }],
                              @"This method may only be called on RLMDictionary instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([optUnmanaged.intObj addNotificationBlock:^(__unused id a, __unused id c, __unused id e) { }],
                              @"This method may only be called on RLMDictionary instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.stringObj addNotificationBlock:^(__unused id a, __unused id c, __unused id e) { }],
                              @"This method may only be called on RLMDictionary instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([optUnmanaged.stringObj addNotificationBlock:^(__unused id a, __unused id c, __unused id e) { }],
                              @"This method may only be called on RLMDictionary instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.dateObj addNotificationBlock:^(__unused id a, __unused id c, __unused id e) { }],
                              @"This method may only be called on RLMDictionary instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([optUnmanaged.dateObj addNotificationBlock:^(__unused id a, __unused id c, __unused id e) { }],
                              @"This method may only be called on RLMDictionary instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.floatObj addNotificationBlock:^(__unused id a, __unused id c, __unused id e) { }],
                              @"This method may only be called on RLMDictionary instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([optUnmanaged.floatObj addNotificationBlock:^(__unused id a, __unused id c, __unused id e) { }],
                              @"This method may only be called on RLMDictionary instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.doubleObj addNotificationBlock:^(__unused id a, __unused id c, __unused id e) { }],
                              @"This method may only be called on RLMDictionary instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([optUnmanaged.doubleObj addNotificationBlock:^(__unused id a, __unused id c, __unused id e) { }],
                              @"This method may only be called on RLMDictionary instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.dataObj addNotificationBlock:^(__unused id a, __unused id c, __unused id e) { }],
                              @"This method may only be called on RLMDictionary instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([optUnmanaged.dataObj addNotificationBlock:^(__unused id a, __unused id c, __unused id e) { }],
                              @"This method may only be called on RLMDictionary instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.decimalObj addNotificationBlock:^(__unused id a, __unused id c, __unused id e) { }],
                              @"This method may only be called on RLMDictionary instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([optUnmanaged.decimalObj addNotificationBlock:^(__unused id a, __unused id c, __unused id e) { }],
                              @"This method may only be called on RLMDictionary instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.objectIdObj addNotificationBlock:^(__unused id a, __unused id c, __unused id e) { }],
                              @"This method may only be called on RLMDictionary instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([optUnmanaged.objectIdObj addNotificationBlock:^(__unused id a, __unused id c, __unused id e) { }],
                              @"This method may only be called on RLMDictionary instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.uuidObj addNotificationBlock:^(__unused id a, __unused id c, __unused id e) { }],
                              @"This method may only be called on RLMDictionary instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([optUnmanaged.uuidObj addNotificationBlock:^(__unused id a, __unused id c, __unused id e) { }],
                              @"This method may only be called on RLMDictionary instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.anyBoolObj addNotificationBlock:^(__unused id a, __unused id c, __unused id e) { }],
                              @"This method may only be called on RLMDictionary instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.anyIntObj addNotificationBlock:^(__unused id a, __unused id c, __unused id e) { }],
                              @"This method may only be called on RLMDictionary instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.anyFloatObj addNotificationBlock:^(__unused id a, __unused id c, __unused id e) { }],
                              @"This method may only be called on RLMDictionary instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.anyDoubleObj addNotificationBlock:^(__unused id a, __unused id c, __unused id e) { }],
                              @"This method may only be called on RLMDictionary instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.anyStringObj addNotificationBlock:^(__unused id a, __unused id c, __unused id e) { }],
                              @"This method may only be called on RLMDictionary instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.anyDataObj addNotificationBlock:^(__unused id a, __unused id c, __unused id e) { }],
                              @"This method may only be called on RLMDictionary instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.anyDateObj addNotificationBlock:^(__unused id a, __unused id c, __unused id e) { }],
                              @"This method may only be called on RLMDictionary instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.anyDecimalObj addNotificationBlock:^(__unused id a, __unused id c, __unused id e) { }],
                              @"This method may only be called on RLMDictionary instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.anyObjectIdObj addNotificationBlock:^(__unused id a, __unused id c, __unused id e) { }],
                              @"This method may only be called on RLMDictionary instances retrieved from an RLMRealm");
    RLMAssertThrowsWithReason([unmanaged.anyUUIDObj addNotificationBlock:^(__unused id a, __unused id c, __unused id e) { }],
                              @"This method may only be called on RLMDictionary instances retrieved from an RLMRealm");
}

- (void)testMin {
    RLMAssertThrowsWithReason([unmanaged.boolObj minOfProperty:@"self"],
                              @"minOfProperty: is not supported for bool dictionary");
    RLMAssertThrowsWithReason([optUnmanaged.boolObj minOfProperty:@"self"],
                              @"minOfProperty: is not supported for bool? dictionary");
    RLMAssertThrowsWithReason([unmanaged.stringObj minOfProperty:@"self"],
                              @"minOfProperty: is not supported for string dictionary");
    RLMAssertThrowsWithReason([optUnmanaged.stringObj minOfProperty:@"self"],
                              @"minOfProperty: is not supported for string? dictionary");
    RLMAssertThrowsWithReason([unmanaged.dataObj minOfProperty:@"self"],
                              @"minOfProperty: is not supported for data dictionary");
    RLMAssertThrowsWithReason([optUnmanaged.dataObj minOfProperty:@"self"],
                              @"minOfProperty: is not supported for data? dictionary");
    RLMAssertThrowsWithReason([unmanaged.objectIdObj minOfProperty:@"self"],
                              @"minOfProperty: is not supported for object id dictionary");
    RLMAssertThrowsWithReason([optUnmanaged.objectIdObj minOfProperty:@"self"],
                              @"minOfProperty: is not supported for object id? dictionary");
    RLMAssertThrowsWithReason([unmanaged.uuidObj minOfProperty:@"self"],
                              @"minOfProperty: is not supported for uuid dictionary");
    RLMAssertThrowsWithReason([optUnmanaged.uuidObj minOfProperty:@"self"],
                              @"minOfProperty: is not supported for uuid? dictionary");
    RLMAssertThrowsWithReason([managed.boolObj minOfProperty:@"self"],
                              @"minOfProperty: is not supported for bool dictionary 'AllPrimitiveDictionaries.boolObj'");
    RLMAssertThrowsWithReason([optManaged.boolObj minOfProperty:@"self"],
                              @"minOfProperty: is not supported for bool? dictionary 'AllOptionalPrimitiveDictionaries.boolObj'");
    RLMAssertThrowsWithReason([managed.stringObj minOfProperty:@"self"],
                              @"minOfProperty: is not supported for string dictionary 'AllPrimitiveDictionaries.stringObj'");
    RLMAssertThrowsWithReason([optManaged.stringObj minOfProperty:@"self"],
                              @"minOfProperty: is not supported for string? dictionary 'AllOptionalPrimitiveDictionaries.stringObj'");

    XCTAssertNil([unmanaged.intObj minOfProperty:@"self"]);
    XCTAssertNil([optUnmanaged.intObj minOfProperty:@"self"]);
    XCTAssertNil([managed.intObj minOfProperty:@"self"]);
    XCTAssertNil([optManaged.intObj minOfProperty:@"self"]);
    XCTAssertNil([unmanaged.dateObj minOfProperty:@"self"]);
    XCTAssertNil([optUnmanaged.dateObj minOfProperty:@"self"]);
    XCTAssertNil([managed.dateObj minOfProperty:@"self"]);
    XCTAssertNil([optManaged.dateObj minOfProperty:@"self"]);
    XCTAssertNil([unmanaged.floatObj minOfProperty:@"self"]);
    XCTAssertNil([optUnmanaged.floatObj minOfProperty:@"self"]);
    XCTAssertNil([managed.floatObj minOfProperty:@"self"]);
    XCTAssertNil([optManaged.floatObj minOfProperty:@"self"]);
    XCTAssertNil([unmanaged.doubleObj minOfProperty:@"self"]);
    XCTAssertNil([optUnmanaged.doubleObj minOfProperty:@"self"]);
    XCTAssertNil([managed.doubleObj minOfProperty:@"self"]);
    XCTAssertNil([optManaged.doubleObj minOfProperty:@"self"]);
    XCTAssertNil([unmanaged.decimalObj minOfProperty:@"self"]);
    XCTAssertNil([optUnmanaged.decimalObj minOfProperty:@"self"]);
    XCTAssertNil([managed.decimalObj minOfProperty:@"self"]);
    XCTAssertNil([optManaged.decimalObj minOfProperty:@"self"]);
    XCTAssertNil([unmanaged.anyFloatObj minOfProperty:@"self"]);
    XCTAssertNil([unmanaged.anyDoubleObj minOfProperty:@"self"]);
    XCTAssertNil([unmanaged.anyDateObj minOfProperty:@"self"]);
    XCTAssertNil([unmanaged.anyDecimalObj minOfProperty:@"self"]);
    XCTAssertNil([managed.anyFloatObj minOfProperty:@"self"]);
    XCTAssertNil([managed.anyDoubleObj minOfProperty:@"self"]);
    XCTAssertNil([managed.anyDecimalObj minOfProperty:@"self"]);

    [self addObjects];

    XCTAssertEqualObjects([unmanaged.intObj minOfProperty:@"self"], @2);
    XCTAssertEqualObjects([optUnmanaged.intObj minOfProperty:@"self"], @2);
    XCTAssertEqualObjects([managed.intObj minOfProperty:@"self"], @2);
    XCTAssertEqualObjects([optManaged.intObj minOfProperty:@"self"], @2);
    XCTAssertEqualObjects([unmanaged.dateObj minOfProperty:@"self"], date(1));
    XCTAssertEqualObjects([optUnmanaged.dateObj minOfProperty:@"self"], date(1));
    XCTAssertEqualObjects([managed.dateObj minOfProperty:@"self"], date(1));
    XCTAssertEqualObjects([optManaged.dateObj minOfProperty:@"self"], date(1));
    XCTAssertEqualObjects([unmanaged.floatObj minOfProperty:@"self"], @2.2f);
    XCTAssertEqualObjects([optUnmanaged.floatObj minOfProperty:@"self"], @2.2f);
    XCTAssertEqualObjects([managed.floatObj minOfProperty:@"self"], @2.2f);
    XCTAssertEqualObjects([optManaged.floatObj minOfProperty:@"self"], @2.2f);
    XCTAssertEqualObjects([unmanaged.doubleObj minOfProperty:@"self"], @2.2);
    XCTAssertEqualObjects([optUnmanaged.doubleObj minOfProperty:@"self"], @2.2);
    XCTAssertEqualObjects([managed.doubleObj minOfProperty:@"self"], @2.2);
    XCTAssertEqualObjects([optManaged.doubleObj minOfProperty:@"self"], @2.2);
    XCTAssertEqualObjects([unmanaged.decimalObj minOfProperty:@"self"], decimal128(2));
    XCTAssertEqualObjects([optUnmanaged.decimalObj minOfProperty:@"self"], decimal128(2));
    XCTAssertEqualObjects([managed.decimalObj minOfProperty:@"self"], decimal128(2));
    XCTAssertEqualObjects([optManaged.decimalObj minOfProperty:@"self"], decimal128(2));
    XCTAssertEqualObjects([unmanaged.anyFloatObj minOfProperty:@"self"], @2.2f);
    XCTAssertEqualObjects([unmanaged.anyDoubleObj minOfProperty:@"self"], @2.2);
    XCTAssertEqualObjects([unmanaged.anyDateObj minOfProperty:@"self"], date(1));
    XCTAssertEqualObjects([unmanaged.anyDecimalObj minOfProperty:@"self"], decimal128(2));
    XCTAssertEqualObjects([managed.anyFloatObj minOfProperty:@"self"], @2.2f);
    XCTAssertEqualObjects([managed.anyDoubleObj minOfProperty:@"self"], @2.2);
    XCTAssertEqualObjects([managed.anyDecimalObj minOfProperty:@"self"], decimal128(2));
}

- (void)testMax {
    RLMAssertThrowsWithReason([unmanaged.boolObj maxOfProperty:@"self"],
                              @"maxOfProperty: is not supported for bool dictionary");
    RLMAssertThrowsWithReason([optUnmanaged.boolObj maxOfProperty:@"self"],
                              @"maxOfProperty: is not supported for bool? dictionary");
    RLMAssertThrowsWithReason([unmanaged.stringObj maxOfProperty:@"self"],
                              @"maxOfProperty: is not supported for string dictionary");
    RLMAssertThrowsWithReason([optUnmanaged.stringObj maxOfProperty:@"self"],
                              @"maxOfProperty: is not supported for string? dictionary");
    RLMAssertThrowsWithReason([unmanaged.dataObj maxOfProperty:@"self"],
                              @"maxOfProperty: is not supported for data dictionary");
    RLMAssertThrowsWithReason([optUnmanaged.dataObj maxOfProperty:@"self"],
                              @"maxOfProperty: is not supported for data? dictionary");
    RLMAssertThrowsWithReason([unmanaged.objectIdObj maxOfProperty:@"self"],
                              @"maxOfProperty: is not supported for object id dictionary");
    RLMAssertThrowsWithReason([optUnmanaged.objectIdObj maxOfProperty:@"self"],
                              @"maxOfProperty: is not supported for object id? dictionary");
    RLMAssertThrowsWithReason([unmanaged.uuidObj maxOfProperty:@"self"],
                              @"maxOfProperty: is not supported for uuid dictionary");
    RLMAssertThrowsWithReason([optUnmanaged.uuidObj maxOfProperty:@"self"],
                              @"maxOfProperty: is not supported for uuid? dictionary");
    RLMAssertThrowsWithReason([managed.boolObj maxOfProperty:@"self"],
                              @"maxOfProperty: is not supported for bool dictionary 'AllPrimitiveDictionaries.boolObj'");
    RLMAssertThrowsWithReason([optManaged.boolObj maxOfProperty:@"self"],
                              @"maxOfProperty: is not supported for bool? dictionary 'AllOptionalPrimitiveDictionaries.boolObj'");
    RLMAssertThrowsWithReason([managed.stringObj maxOfProperty:@"self"],
                              @"maxOfProperty: is not supported for string dictionary 'AllPrimitiveDictionaries.stringObj'");
    RLMAssertThrowsWithReason([optManaged.stringObj maxOfProperty:@"self"],
                              @"maxOfProperty: is not supported for string? dictionary 'AllOptionalPrimitiveDictionaries.stringObj'");

    XCTAssertNil([unmanaged.intObj maxOfProperty:@"self"]);
    XCTAssertNil([optUnmanaged.intObj maxOfProperty:@"self"]);
    XCTAssertNil([managed.intObj maxOfProperty:@"self"]);
    XCTAssertNil([optManaged.intObj maxOfProperty:@"self"]);
    XCTAssertNil([unmanaged.dateObj maxOfProperty:@"self"]);
    XCTAssertNil([optUnmanaged.dateObj maxOfProperty:@"self"]);
    XCTAssertNil([managed.dateObj maxOfProperty:@"self"]);
    XCTAssertNil([optManaged.dateObj maxOfProperty:@"self"]);
    XCTAssertNil([unmanaged.floatObj maxOfProperty:@"self"]);
    XCTAssertNil([optUnmanaged.floatObj maxOfProperty:@"self"]);
    XCTAssertNil([managed.floatObj maxOfProperty:@"self"]);
    XCTAssertNil([optManaged.floatObj maxOfProperty:@"self"]);
    XCTAssertNil([unmanaged.doubleObj maxOfProperty:@"self"]);
    XCTAssertNil([optUnmanaged.doubleObj maxOfProperty:@"self"]);
    XCTAssertNil([managed.doubleObj maxOfProperty:@"self"]);
    XCTAssertNil([optManaged.doubleObj maxOfProperty:@"self"]);
    XCTAssertNil([unmanaged.decimalObj maxOfProperty:@"self"]);
    XCTAssertNil([optUnmanaged.decimalObj maxOfProperty:@"self"]);
    XCTAssertNil([managed.decimalObj maxOfProperty:@"self"]);
    XCTAssertNil([optManaged.decimalObj maxOfProperty:@"self"]);
    XCTAssertNil([unmanaged.anyFloatObj maxOfProperty:@"self"]);
    XCTAssertNil([unmanaged.anyDoubleObj maxOfProperty:@"self"]);
    XCTAssertNil([unmanaged.anyDateObj maxOfProperty:@"self"]);
    XCTAssertNil([unmanaged.anyDecimalObj maxOfProperty:@"self"]);
    XCTAssertNil([managed.anyFloatObj maxOfProperty:@"self"]);
    XCTAssertNil([managed.anyDoubleObj maxOfProperty:@"self"]);
    XCTAssertNil([managed.anyDecimalObj maxOfProperty:@"self"]);

    [self addObjects];

    XCTAssertEqualObjects([unmanaged.intObj maxOfProperty:@"self"], @3);
    XCTAssertEqualObjects([managed.intObj maxOfProperty:@"self"], @3);
    XCTAssertEqualObjects([unmanaged.dateObj maxOfProperty:@"self"], date(2));
    XCTAssertEqualObjects([managed.dateObj maxOfProperty:@"self"], date(2));
    XCTAssertEqualObjects([unmanaged.floatObj maxOfProperty:@"self"], @3.3f);
    XCTAssertEqualObjects([managed.floatObj maxOfProperty:@"self"], @3.3f);
    XCTAssertEqualObjects([unmanaged.doubleObj maxOfProperty:@"self"], @3.3);
    XCTAssertEqualObjects([managed.doubleObj maxOfProperty:@"self"], @3.3);
    XCTAssertEqualObjects([unmanaged.decimalObj maxOfProperty:@"self"], decimal128(3));
    XCTAssertEqualObjects([managed.decimalObj maxOfProperty:@"self"], decimal128(3));
    XCTAssertEqualObjects([unmanaged.anyFloatObj maxOfProperty:@"self"], @3.3f);
    XCTAssertEqualObjects([unmanaged.anyDoubleObj maxOfProperty:@"self"], @3.3);
    XCTAssertEqualObjects([unmanaged.anyDateObj maxOfProperty:@"self"], date(2));
    XCTAssertEqualObjects([unmanaged.anyDecimalObj maxOfProperty:@"self"], decimal128(3));
    XCTAssertEqualObjects([managed.anyFloatObj maxOfProperty:@"self"], @3.3f);
    XCTAssertEqualObjects([managed.anyDoubleObj maxOfProperty:@"self"], @3.3);
    XCTAssertEqualObjects([managed.anyDecimalObj maxOfProperty:@"self"], decimal128(3));
    XCTAssertEqualObjects([optUnmanaged.intObj maxOfProperty:@"self"], @2);
    XCTAssertEqualObjects([optManaged.intObj maxOfProperty:@"self"], @2);
    XCTAssertEqualObjects([optUnmanaged.dateObj maxOfProperty:@"self"], date(1));
    XCTAssertEqualObjects([optManaged.dateObj maxOfProperty:@"self"], date(1));
    XCTAssertEqualObjects([optUnmanaged.floatObj maxOfProperty:@"self"], @2.2f);
    XCTAssertEqualObjects([optManaged.floatObj maxOfProperty:@"self"], @2.2f);
    XCTAssertEqualObjects([optUnmanaged.doubleObj maxOfProperty:@"self"], @2.2);
    XCTAssertEqualObjects([optManaged.doubleObj maxOfProperty:@"self"], @2.2);
    XCTAssertEqualObjects([optUnmanaged.decimalObj maxOfProperty:@"self"], decimal128(2));
    XCTAssertEqualObjects([optManaged.decimalObj maxOfProperty:@"self"], decimal128(2));
}

- (void)testSum {
    RLMAssertThrowsWithReason([unmanaged.boolObj sumOfProperty:@"self"],
                              @"sumOfProperty: is not supported for bool dictionary");
    RLMAssertThrowsWithReason([optUnmanaged.boolObj sumOfProperty:@"self"],
                              @"sumOfProperty: is not supported for bool? dictionary");
    RLMAssertThrowsWithReason([unmanaged.stringObj sumOfProperty:@"self"],
                              @"sumOfProperty: is not supported for string dictionary");
    RLMAssertThrowsWithReason([optUnmanaged.stringObj sumOfProperty:@"self"],
                              @"sumOfProperty: is not supported for string? dictionary");
    RLMAssertThrowsWithReason([unmanaged.dateObj sumOfProperty:@"self"],
                              @"sumOfProperty: is not supported for date dictionary");
    RLMAssertThrowsWithReason([optUnmanaged.dateObj sumOfProperty:@"self"],
                              @"sumOfProperty: is not supported for date? dictionary");
    RLMAssertThrowsWithReason([unmanaged.dataObj sumOfProperty:@"self"],
                              @"sumOfProperty: is not supported for data dictionary");
    RLMAssertThrowsWithReason([optUnmanaged.dataObj sumOfProperty:@"self"],
                              @"sumOfProperty: is not supported for data? dictionary");
    RLMAssertThrowsWithReason([unmanaged.objectIdObj sumOfProperty:@"self"],
                              @"sumOfProperty: is not supported for object id dictionary");
    RLMAssertThrowsWithReason([optUnmanaged.objectIdObj sumOfProperty:@"self"],
                              @"sumOfProperty: is not supported for object id? dictionary");
    RLMAssertThrowsWithReason([unmanaged.uuidObj sumOfProperty:@"self"],
                              @"sumOfProperty: is not supported for uuid dictionary");
    RLMAssertThrowsWithReason([optUnmanaged.uuidObj sumOfProperty:@"self"],
                              @"sumOfProperty: is not supported for uuid? dictionary");
    RLMAssertThrowsWithReason([managed.boolObj sumOfProperty:@"self"],
                              @"sumOfProperty: is not supported for bool dictionary 'AllPrimitiveDictionaries.boolObj'");
    RLMAssertThrowsWithReason([optManaged.boolObj sumOfProperty:@"self"],
                              @"sumOfProperty: is not supported for bool? dictionary 'AllOptionalPrimitiveDictionaries.boolObj'");
    RLMAssertThrowsWithReason([managed.stringObj sumOfProperty:@"self"],
                              @"sumOfProperty: is not supported for string dictionary 'AllPrimitiveDictionaries.stringObj'");
    RLMAssertThrowsWithReason([optManaged.stringObj sumOfProperty:@"self"],
                              @"sumOfProperty: is not supported for string? dictionary 'AllOptionalPrimitiveDictionaries.stringObj'");
    RLMAssertThrowsWithReason([managed.dateObj sumOfProperty:@"self"],
                              @"sumOfProperty: is not supported for date dictionary 'AllPrimitiveDictionaries.dateObj'");
    RLMAssertThrowsWithReason([optManaged.dateObj sumOfProperty:@"self"],
                              @"sumOfProperty: is not supported for date? dictionary 'AllOptionalPrimitiveDictionaries.dateObj'");

    XCTAssertEqualObjects([unmanaged.intObj sumOfProperty:@"self"], @0);
    XCTAssertEqualObjects([optUnmanaged.intObj sumOfProperty:@"self"], @0);
    XCTAssertEqualObjects([managed.intObj sumOfProperty:@"self"], @0);
    XCTAssertEqualObjects([optManaged.intObj sumOfProperty:@"self"], @0);
    XCTAssertEqualObjects([unmanaged.floatObj sumOfProperty:@"self"], @0);
    XCTAssertEqualObjects([optUnmanaged.floatObj sumOfProperty:@"self"], @0);
    XCTAssertEqualObjects([managed.floatObj sumOfProperty:@"self"], @0);
    XCTAssertEqualObjects([optManaged.floatObj sumOfProperty:@"self"], @0);
    XCTAssertEqualObjects([unmanaged.doubleObj sumOfProperty:@"self"], @0);
    XCTAssertEqualObjects([optUnmanaged.doubleObj sumOfProperty:@"self"], @0);
    XCTAssertEqualObjects([managed.doubleObj sumOfProperty:@"self"], @0);
    XCTAssertEqualObjects([optManaged.doubleObj sumOfProperty:@"self"], @0);
    XCTAssertEqualObjects([unmanaged.decimalObj sumOfProperty:@"self"], @0);
    XCTAssertEqualObjects([optUnmanaged.decimalObj sumOfProperty:@"self"], @0);
    XCTAssertEqualObjects([managed.decimalObj sumOfProperty:@"self"], @0);
    XCTAssertEqualObjects([optManaged.decimalObj sumOfProperty:@"self"], @0);
    XCTAssertEqualObjects([unmanaged.anyIntObj sumOfProperty:@"self"], @0);
    XCTAssertEqualObjects([unmanaged.anyFloatObj sumOfProperty:@"self"], @0);
    XCTAssertEqualObjects([unmanaged.anyDoubleObj sumOfProperty:@"self"], @0);
    XCTAssertEqualObjects([unmanaged.anyDecimalObj sumOfProperty:@"self"], @0);
    XCTAssertEqualObjects([managed.anyIntObj sumOfProperty:@"self"], @0);
    XCTAssertEqualObjects([managed.anyFloatObj sumOfProperty:@"self"], @0);
    XCTAssertEqualObjects([managed.anyDoubleObj sumOfProperty:@"self"], @0);
    XCTAssertEqualObjects([managed.anyDecimalObj sumOfProperty:@"self"], @0);

    [self addObjects];

    XCTAssertEqualWithAccuracy([unmanaged.intObj sumOfProperty:@"self"].doubleValue, sum(@{ @"key1": @2, @"key2": @3 }), .001);
    XCTAssertEqualWithAccuracy([optUnmanaged.intObj sumOfProperty:@"self"].doubleValue, sum(@{ @"key1": @2, @"key2": NSNull.null }), .001);
    XCTAssertEqualWithAccuracy([managed.intObj sumOfProperty:@"self"].doubleValue, sum(@{ @"key1": @2, @"key2": @3 }), .001);
    XCTAssertEqualWithAccuracy([optManaged.intObj sumOfProperty:@"self"].doubleValue, sum(@{ @"key1": @2, @"key2": NSNull.null }), .001);
    XCTAssertEqualWithAccuracy([unmanaged.floatObj sumOfProperty:@"self"].doubleValue, sum(@{ @"key1": @2.2f, @"key2": @3.3f }), .001);
    XCTAssertEqualWithAccuracy([optUnmanaged.floatObj sumOfProperty:@"self"].doubleValue, sum(@{ @"key1": @2.2f, @"key2": NSNull.null }), .001);
    XCTAssertEqualWithAccuracy([managed.floatObj sumOfProperty:@"self"].doubleValue, sum(@{ @"key1": @2.2f, @"key2": @3.3f }), .001);
    XCTAssertEqualWithAccuracy([optManaged.floatObj sumOfProperty:@"self"].doubleValue, sum(@{ @"key1": @2.2f, @"key2": NSNull.null }), .001);
    XCTAssertEqualWithAccuracy([unmanaged.doubleObj sumOfProperty:@"self"].doubleValue, sum(@{ @"key1": @2.2, @"key2": @3.3 }), .001);
    XCTAssertEqualWithAccuracy([optUnmanaged.doubleObj sumOfProperty:@"self"].doubleValue, sum(@{ @"key1": @2.2, @"key2": NSNull.null }), .001);
    XCTAssertEqualWithAccuracy([managed.doubleObj sumOfProperty:@"self"].doubleValue, sum(@{ @"key1": @2.2, @"key2": @3.3 }), .001);
    XCTAssertEqualWithAccuracy([optManaged.doubleObj sumOfProperty:@"self"].doubleValue, sum(@{ @"key1": @2.2, @"key2": NSNull.null }), .001);
    XCTAssertEqualWithAccuracy([unmanaged.decimalObj sumOfProperty:@"self"].doubleValue, sum(@{ @"key1": decimal128(2), @"key2": decimal128(3) }), .001);
    XCTAssertEqualWithAccuracy([optUnmanaged.decimalObj sumOfProperty:@"self"].doubleValue, sum(@{ @"key1": decimal128(2), @"key2": NSNull.null }), .001);
    XCTAssertEqualWithAccuracy([managed.decimalObj sumOfProperty:@"self"].doubleValue, sum(@{ @"key1": decimal128(2), @"key2": decimal128(3) }), .001);
    XCTAssertEqualWithAccuracy([optManaged.decimalObj sumOfProperty:@"self"].doubleValue, sum(@{ @"key1": decimal128(2), @"key2": NSNull.null }), .001);
    XCTAssertEqualWithAccuracy([unmanaged.anyIntObj sumOfProperty:@"self"].doubleValue, sum(@{ @"key1": @2, @"key2": @3 }), .001);
    XCTAssertEqualWithAccuracy([unmanaged.anyFloatObj sumOfProperty:@"self"].doubleValue, sum(@{ @"key1": @2.2f, @"key2": @3.3f }), .001);
    XCTAssertEqualWithAccuracy([unmanaged.anyDoubleObj sumOfProperty:@"self"].doubleValue, sum(@{ @"key1": @2.2, @"key2": @3.3 }), .001);
    XCTAssertEqualWithAccuracy([unmanaged.anyDecimalObj sumOfProperty:@"self"].doubleValue, sum(@{ @"key1": decimal128(2), @"key2": decimal128(3) }), .001);
    XCTAssertEqualWithAccuracy([managed.anyIntObj sumOfProperty:@"self"].doubleValue, sum(@{ @"key1": @2, @"key2": @3 }), .001);
    XCTAssertEqualWithAccuracy([managed.anyFloatObj sumOfProperty:@"self"].doubleValue, sum(@{ @"key1": @2.2f, @"key2": @3.3f }), .001);
    XCTAssertEqualWithAccuracy([managed.anyDoubleObj sumOfProperty:@"self"].doubleValue, sum(@{ @"key1": @2.2, @"key2": @3.3 }), .001);
    XCTAssertEqualWithAccuracy([managed.anyDecimalObj sumOfProperty:@"self"].doubleValue, sum(@{ @"key1": decimal128(2), @"key2": decimal128(3) }), .001);
}

- (void)testAverage {
    RLMAssertThrowsWithReason([unmanaged.boolObj averageOfProperty:@"self"],
                              @"averageOfProperty: is not supported for bool dictionary");
    RLMAssertThrowsWithReason([optUnmanaged.boolObj averageOfProperty:@"self"],
                              @"averageOfProperty: is not supported for bool? dictionary");
    RLMAssertThrowsWithReason([unmanaged.stringObj averageOfProperty:@"self"],
                              @"averageOfProperty: is not supported for string dictionary");
    RLMAssertThrowsWithReason([optUnmanaged.stringObj averageOfProperty:@"self"],
                              @"averageOfProperty: is not supported for string? dictionary");
    RLMAssertThrowsWithReason([unmanaged.dateObj averageOfProperty:@"self"],
                              @"averageOfProperty: is not supported for date dictionary");
    RLMAssertThrowsWithReason([optUnmanaged.dateObj averageOfProperty:@"self"],
                              @"averageOfProperty: is not supported for date? dictionary");
    RLMAssertThrowsWithReason([unmanaged.dataObj averageOfProperty:@"self"],
                              @"averageOfProperty: is not supported for data dictionary");
    RLMAssertThrowsWithReason([optUnmanaged.dataObj averageOfProperty:@"self"],
                              @"averageOfProperty: is not supported for data? dictionary");
    RLMAssertThrowsWithReason([unmanaged.objectIdObj averageOfProperty:@"self"],
                              @"averageOfProperty: is not supported for object id dictionary");
    RLMAssertThrowsWithReason([optUnmanaged.objectIdObj averageOfProperty:@"self"],
                              @"averageOfProperty: is not supported for object id? dictionary");
    RLMAssertThrowsWithReason([unmanaged.uuidObj averageOfProperty:@"self"],
                              @"averageOfProperty: is not supported for uuid dictionary");
    RLMAssertThrowsWithReason([optUnmanaged.uuidObj averageOfProperty:@"self"],
                              @"averageOfProperty: is not supported for uuid? dictionary");
    RLMAssertThrowsWithReason([managed.boolObj averageOfProperty:@"self"],
                              @"averageOfProperty: is not supported for bool dictionary 'AllPrimitiveDictionaries.boolObj'");
    RLMAssertThrowsWithReason([optManaged.boolObj averageOfProperty:@"self"],
                              @"averageOfProperty: is not supported for bool? dictionary 'AllOptionalPrimitiveDictionaries.boolObj'");
    RLMAssertThrowsWithReason([managed.stringObj averageOfProperty:@"self"],
                              @"averageOfProperty: is not supported for string dictionary 'AllPrimitiveDictionaries.stringObj'");
    RLMAssertThrowsWithReason([optManaged.stringObj averageOfProperty:@"self"],
                              @"averageOfProperty: is not supported for string? dictionary 'AllOptionalPrimitiveDictionaries.stringObj'");
    RLMAssertThrowsWithReason([managed.dateObj averageOfProperty:@"self"],
                              @"averageOfProperty: is not supported for date dictionary 'AllPrimitiveDictionaries.dateObj'");
    RLMAssertThrowsWithReason([optManaged.dateObj averageOfProperty:@"self"],
                              @"averageOfProperty: is not supported for date? dictionary 'AllOptionalPrimitiveDictionaries.dateObj'");

    XCTAssertNil([unmanaged.intObj averageOfProperty:@"self"]);
    XCTAssertNil([optUnmanaged.intObj averageOfProperty:@"self"]);
    XCTAssertNil([managed.intObj averageOfProperty:@"self"]);
    XCTAssertNil([optManaged.intObj averageOfProperty:@"self"]);
    XCTAssertNil([unmanaged.floatObj averageOfProperty:@"self"]);
    XCTAssertNil([optUnmanaged.floatObj averageOfProperty:@"self"]);
    XCTAssertNil([managed.floatObj averageOfProperty:@"self"]);
    XCTAssertNil([optManaged.floatObj averageOfProperty:@"self"]);
    XCTAssertNil([unmanaged.doubleObj averageOfProperty:@"self"]);
    XCTAssertNil([optUnmanaged.doubleObj averageOfProperty:@"self"]);
    XCTAssertNil([managed.doubleObj averageOfProperty:@"self"]);
    XCTAssertNil([optManaged.doubleObj averageOfProperty:@"self"]);
    XCTAssertNil([unmanaged.decimalObj averageOfProperty:@"self"]);
    XCTAssertNil([optUnmanaged.decimalObj averageOfProperty:@"self"]);
    XCTAssertNil([managed.decimalObj averageOfProperty:@"self"]);
    XCTAssertNil([optManaged.decimalObj averageOfProperty:@"self"]);
    XCTAssertNil([unmanaged.anyIntObj averageOfProperty:@"self"]);
    XCTAssertNil([unmanaged.anyFloatObj averageOfProperty:@"self"]);
    XCTAssertNil([unmanaged.anyDoubleObj averageOfProperty:@"self"]);
    XCTAssertNil([unmanaged.anyDecimalObj averageOfProperty:@"self"]);
    XCTAssertNil([managed.anyIntObj averageOfProperty:@"self"]);
    XCTAssertNil([managed.anyFloatObj averageOfProperty:@"self"]);
    XCTAssertNil([managed.anyDoubleObj averageOfProperty:@"self"]);
    XCTAssertNil([managed.anyDecimalObj averageOfProperty:@"self"]);

    [self addObjects];

    XCTAssertEqualWithAccuracy([unmanaged.intObj averageOfProperty:@"self"].doubleValue, average(@{ @"key1": @2, @"key2": @3 }), .001);
    XCTAssertEqualWithAccuracy([optUnmanaged.intObj averageOfProperty:@"self"].doubleValue, average(@{ @"key1": @2, @"key2": NSNull.null }), .001);
    XCTAssertEqualWithAccuracy([managed.intObj averageOfProperty:@"self"].doubleValue, average(@{ @"key1": @2, @"key2": @3 }), .001);
    XCTAssertEqualWithAccuracy([optManaged.intObj averageOfProperty:@"self"].doubleValue, average(@{ @"key1": @2, @"key2": NSNull.null }), .001);
    XCTAssertEqualWithAccuracy([unmanaged.floatObj averageOfProperty:@"self"].doubleValue, average(@{ @"key1": @2.2f, @"key2": @3.3f }), .001);
    XCTAssertEqualWithAccuracy([optUnmanaged.floatObj averageOfProperty:@"self"].doubleValue, average(@{ @"key1": @2.2f, @"key2": NSNull.null }), .001);
    XCTAssertEqualWithAccuracy([managed.floatObj averageOfProperty:@"self"].doubleValue, average(@{ @"key1": @2.2f, @"key2": @3.3f }), .001);
    XCTAssertEqualWithAccuracy([optManaged.floatObj averageOfProperty:@"self"].doubleValue, average(@{ @"key1": @2.2f, @"key2": NSNull.null }), .001);
    XCTAssertEqualWithAccuracy([unmanaged.doubleObj averageOfProperty:@"self"].doubleValue, average(@{ @"key1": @2.2, @"key2": @3.3 }), .001);
    XCTAssertEqualWithAccuracy([optUnmanaged.doubleObj averageOfProperty:@"self"].doubleValue, average(@{ @"key1": @2.2, @"key2": NSNull.null }), .001);
    XCTAssertEqualWithAccuracy([managed.doubleObj averageOfProperty:@"self"].doubleValue, average(@{ @"key1": @2.2, @"key2": @3.3 }), .001);
    XCTAssertEqualWithAccuracy([optManaged.doubleObj averageOfProperty:@"self"].doubleValue, average(@{ @"key1": @2.2, @"key2": NSNull.null }), .001);
    XCTAssertEqualWithAccuracy([unmanaged.decimalObj averageOfProperty:@"self"].doubleValue, average(@{ @"key1": decimal128(2), @"key2": decimal128(3) }), .001);
    XCTAssertEqualWithAccuracy([optUnmanaged.decimalObj averageOfProperty:@"self"].doubleValue, average(@{ @"key1": decimal128(2), @"key2": NSNull.null }), .001);
    XCTAssertEqualWithAccuracy([managed.decimalObj averageOfProperty:@"self"].doubleValue, average(@{ @"key1": decimal128(2), @"key2": decimal128(3) }), .001);
    XCTAssertEqualWithAccuracy([optManaged.decimalObj averageOfProperty:@"self"].doubleValue, average(@{ @"key1": decimal128(2), @"key2": NSNull.null }), .001);
    XCTAssertEqualWithAccuracy([unmanaged.anyIntObj averageOfProperty:@"self"].doubleValue, average(@{ @"key1": @2, @"key2": @3 }), .001);
    XCTAssertEqualWithAccuracy([unmanaged.anyFloatObj averageOfProperty:@"self"].doubleValue, average(@{ @"key1": @2.2f, @"key2": @3.3f }), .001);
    XCTAssertEqualWithAccuracy([unmanaged.anyDoubleObj averageOfProperty:@"self"].doubleValue, average(@{ @"key1": @2.2, @"key2": @3.3 }), .001);
    XCTAssertEqualWithAccuracy([unmanaged.anyDecimalObj averageOfProperty:@"self"].doubleValue, average(@{ @"key1": decimal128(2), @"key2": decimal128(3) }), .001);
    XCTAssertEqualWithAccuracy([managed.anyIntObj averageOfProperty:@"self"].doubleValue, average(@{ @"key1": @2, @"key2": @3 }), .001);
    XCTAssertEqualWithAccuracy([managed.anyFloatObj averageOfProperty:@"self"].doubleValue, average(@{ @"key1": @2.2f, @"key2": @3.3f }), .001);
    XCTAssertEqualWithAccuracy([managed.anyDoubleObj averageOfProperty:@"self"].doubleValue, average(@{ @"key1": @2.2, @"key2": @3.3 }), .001);
    XCTAssertEqualWithAccuracy([managed.anyDecimalObj averageOfProperty:@"self"].doubleValue, average(@{ @"key1": decimal128(2), @"key2": decimal128(3) }), .001);
}

- (void)testFastEnumeration {
    for (int i = 0; i < 10; ++i) {
        [self addObjects];
    }

    {
    NSDictionary *values = @{ @"key1": @NO, @"key2": @YES };
    for (id key in unmanaged.boolObj) {
        id value = unmanaged.boolObj[key];
        XCTAssertEqualObjects(values[key], value);
    }
    XCTAssertEqual(values.count, unmanaged.boolObj.count);
    }
    
    {
    NSDictionary *values = @{ @"key1": @NO, @"key2": NSNull.null };
    for (id key in optUnmanaged.boolObj) {
        id value = optUnmanaged.boolObj[key];
        XCTAssertEqualObjects(values[key], value);
    }
    XCTAssertEqual(values.count, optUnmanaged.boolObj.count);
    }
    
    {
    NSDictionary *values = @{ @"key1": @NO, @"key2": @YES };
    for (id key in managed.boolObj) {
        id value = managed.boolObj[key];
        XCTAssertEqualObjects(values[key], value);
    }
    XCTAssertEqual(values.count, managed.boolObj.count);
    }
    
    {
    NSDictionary *values = @{ @"key1": @NO, @"key2": NSNull.null };
    for (id key in optManaged.boolObj) {
        id value = optManaged.boolObj[key];
        XCTAssertEqualObjects(values[key], value);
    }
    XCTAssertEqual(values.count, optManaged.boolObj.count);
    }
    
    {
    NSDictionary *values = @{ @"key1": @2, @"key2": @3 };
    for (id key in unmanaged.intObj) {
        id value = unmanaged.intObj[key];
        XCTAssertEqualObjects(values[key], value);
    }
    XCTAssertEqual(values.count, unmanaged.intObj.count);
    }
    
    {
    NSDictionary *values = @{ @"key1": @2, @"key2": NSNull.null };
    for (id key in optUnmanaged.intObj) {
        id value = optUnmanaged.intObj[key];
        XCTAssertEqualObjects(values[key], value);
    }
    XCTAssertEqual(values.count, optUnmanaged.intObj.count);
    }
    
    {
    NSDictionary *values = @{ @"key1": @2, @"key2": @3 };
    for (id key in managed.intObj) {
        id value = managed.intObj[key];
        XCTAssertEqualObjects(values[key], value);
    }
    XCTAssertEqual(values.count, managed.intObj.count);
    }
    
    {
    NSDictionary *values = @{ @"key1": @2, @"key2": NSNull.null };
    for (id key in optManaged.intObj) {
        id value = optManaged.intObj[key];
        XCTAssertEqualObjects(values[key], value);
    }
    XCTAssertEqual(values.count, optManaged.intObj.count);
    }
    
    {
    NSDictionary *values = @{ @"key1": @"bar", @"key2": @"foo" };
    for (id key in unmanaged.stringObj) {
        id value = unmanaged.stringObj[key];
        XCTAssertEqualObjects(values[key], value);
    }
    XCTAssertEqual(values.count, unmanaged.stringObj.count);
    }
    
    {
    NSDictionary *values = @{ @"key1": @"bar", @"key2": NSNull.null };
    for (id key in optUnmanaged.stringObj) {
        id value = optUnmanaged.stringObj[key];
        XCTAssertEqualObjects(values[key], value);
    }
    XCTAssertEqual(values.count, optUnmanaged.stringObj.count);
    }
    
    {
    NSDictionary *values = @{ @"key1": @"bar", @"key2": @"foo" };
    for (id key in managed.stringObj) {
        id value = managed.stringObj[key];
        XCTAssertEqualObjects(values[key], value);
    }
    XCTAssertEqual(values.count, managed.stringObj.count);
    }
    
    {
    NSDictionary *values = @{ @"key1": @"bar", @"key2": NSNull.null };
    for (id key in optManaged.stringObj) {
        id value = optManaged.stringObj[key];
        XCTAssertEqualObjects(values[key], value);
    }
    XCTAssertEqual(values.count, optManaged.stringObj.count);
    }
    
    {
    NSDictionary *values = @{ @"key1": date(1), @"key2": date(2) };
    for (id key in unmanaged.dateObj) {
        id value = unmanaged.dateObj[key];
        XCTAssertEqualObjects(values[key], value);
    }
    XCTAssertEqual(values.count, unmanaged.dateObj.count);
    }
    
    {
    NSDictionary *values = @{ @"key1": date(1), @"key2": NSNull.null };
    for (id key in optUnmanaged.dateObj) {
        id value = optUnmanaged.dateObj[key];
        XCTAssertEqualObjects(values[key], value);
    }
    XCTAssertEqual(values.count, optUnmanaged.dateObj.count);
    }
    
    {
    NSDictionary *values = @{ @"key1": date(1), @"key2": date(2) };
    for (id key in managed.dateObj) {
        id value = managed.dateObj[key];
        XCTAssertEqualObjects(values[key], value);
    }
    XCTAssertEqual(values.count, managed.dateObj.count);
    }
    
    {
    NSDictionary *values = @{ @"key1": date(1), @"key2": NSNull.null };
    for (id key in optManaged.dateObj) {
        id value = optManaged.dateObj[key];
        XCTAssertEqualObjects(values[key], value);
    }
    XCTAssertEqual(values.count, optManaged.dateObj.count);
    }
    
    {
    NSDictionary *values = @{ @"key1": @2.2f, @"key2": @3.3f };
    for (id key in unmanaged.floatObj) {
        id value = unmanaged.floatObj[key];
        XCTAssertEqualObjects(values[key], value);
    }
    XCTAssertEqual(values.count, unmanaged.floatObj.count);
    }
    
    {
    NSDictionary *values = @{ @"key1": @2.2f, @"key2": NSNull.null };
    for (id key in optUnmanaged.floatObj) {
        id value = optUnmanaged.floatObj[key];
        XCTAssertEqualObjects(values[key], value);
    }
    XCTAssertEqual(values.count, optUnmanaged.floatObj.count);
    }
    
    {
    NSDictionary *values = @{ @"key1": @2.2f, @"key2": @3.3f };
    for (id key in managed.floatObj) {
        id value = managed.floatObj[key];
        XCTAssertEqualObjects(values[key], value);
    }
    XCTAssertEqual(values.count, managed.floatObj.count);
    }
    
    {
    NSDictionary *values = @{ @"key1": @2.2f, @"key2": NSNull.null };
    for (id key in optManaged.floatObj) {
        id value = optManaged.floatObj[key];
        XCTAssertEqualObjects(values[key], value);
    }
    XCTAssertEqual(values.count, optManaged.floatObj.count);
    }
    
    {
    NSDictionary *values = @{ @"key1": @2.2, @"key2": @3.3 };
    for (id key in unmanaged.doubleObj) {
        id value = unmanaged.doubleObj[key];
        XCTAssertEqualObjects(values[key], value);
    }
    XCTAssertEqual(values.count, unmanaged.doubleObj.count);
    }
    
    {
    NSDictionary *values = @{ @"key1": @2.2, @"key2": NSNull.null };
    for (id key in optUnmanaged.doubleObj) {
        id value = optUnmanaged.doubleObj[key];
        XCTAssertEqualObjects(values[key], value);
    }
    XCTAssertEqual(values.count, optUnmanaged.doubleObj.count);
    }
    
    {
    NSDictionary *values = @{ @"key1": @2.2, @"key2": @3.3 };
    for (id key in managed.doubleObj) {
        id value = managed.doubleObj[key];
        XCTAssertEqualObjects(values[key], value);
    }
    XCTAssertEqual(values.count, managed.doubleObj.count);
    }
    
    {
    NSDictionary *values = @{ @"key1": @2.2, @"key2": NSNull.null };
    for (id key in optManaged.doubleObj) {
        id value = optManaged.doubleObj[key];
        XCTAssertEqualObjects(values[key], value);
    }
    XCTAssertEqual(values.count, optManaged.doubleObj.count);
    }
    
    {
    NSDictionary *values = @{ @"key1": data(1), @"key2": data(2) };
    for (id key in unmanaged.dataObj) {
        id value = unmanaged.dataObj[key];
        XCTAssertEqualObjects(values[key], value);
    }
    XCTAssertEqual(values.count, unmanaged.dataObj.count);
    }
    
    {
    NSDictionary *values = @{ @"key1": data(1), @"key2": NSNull.null };
    for (id key in optUnmanaged.dataObj) {
        id value = optUnmanaged.dataObj[key];
        XCTAssertEqualObjects(values[key], value);
    }
    XCTAssertEqual(values.count, optUnmanaged.dataObj.count);
    }
    
    {
    NSDictionary *values = @{ @"key1": data(1), @"key2": data(2) };
    for (id key in managed.dataObj) {
        id value = managed.dataObj[key];
        XCTAssertEqualObjects(values[key], value);
    }
    XCTAssertEqual(values.count, managed.dataObj.count);
    }
    
    {
    NSDictionary *values = @{ @"key1": data(1), @"key2": NSNull.null };
    for (id key in optManaged.dataObj) {
        id value = optManaged.dataObj[key];
        XCTAssertEqualObjects(values[key], value);
    }
    XCTAssertEqual(values.count, optManaged.dataObj.count);
    }
    
    {
    NSDictionary *values = @{ @"key1": decimal128(2), @"key2": decimal128(3) };
    for (id key in unmanaged.decimalObj) {
        id value = unmanaged.decimalObj[key];
        XCTAssertEqualObjects(values[key], value);
    }
    XCTAssertEqual(values.count, unmanaged.decimalObj.count);
    }
    
    {
    NSDictionary *values = @{ @"key1": decimal128(2), @"key2": NSNull.null };
    for (id key in optUnmanaged.decimalObj) {
        id value = optUnmanaged.decimalObj[key];
        XCTAssertEqualObjects(values[key], value);
    }
    XCTAssertEqual(values.count, optUnmanaged.decimalObj.count);
    }
    
    {
    NSDictionary *values = @{ @"key1": decimal128(2), @"key2": decimal128(3) };
    for (id key in managed.decimalObj) {
        id value = managed.decimalObj[key];
        XCTAssertEqualObjects(values[key], value);
    }
    XCTAssertEqual(values.count, managed.decimalObj.count);
    }
    
    {
    NSDictionary *values = @{ @"key1": decimal128(2), @"key2": NSNull.null };
    for (id key in optManaged.decimalObj) {
        id value = optManaged.decimalObj[key];
        XCTAssertEqualObjects(values[key], value);
    }
    XCTAssertEqual(values.count, optManaged.decimalObj.count);
    }
    
    {
    NSDictionary *values = @{ @"key1": objectId(1), @"key2": objectId(2) };
    for (id key in unmanaged.objectIdObj) {
        id value = unmanaged.objectIdObj[key];
        XCTAssertEqualObjects(values[key], value);
    }
    XCTAssertEqual(values.count, unmanaged.objectIdObj.count);
    }
    
    {
    NSDictionary *values = @{ @"key1": objectId(1), @"key2": NSNull.null };
    for (id key in optUnmanaged.objectIdObj) {
        id value = optUnmanaged.objectIdObj[key];
        XCTAssertEqualObjects(values[key], value);
    }
    XCTAssertEqual(values.count, optUnmanaged.objectIdObj.count);
    }
    
    {
    NSDictionary *values = @{ @"key1": objectId(1), @"key2": objectId(2) };
    for (id key in managed.objectIdObj) {
        id value = managed.objectIdObj[key];
        XCTAssertEqualObjects(values[key], value);
    }
    XCTAssertEqual(values.count, managed.objectIdObj.count);
    }
    
    {
    NSDictionary *values = @{ @"key1": objectId(1), @"key2": NSNull.null };
    for (id key in optManaged.objectIdObj) {
        id value = optManaged.objectIdObj[key];
        XCTAssertEqualObjects(values[key], value);
    }
    XCTAssertEqual(values.count, optManaged.objectIdObj.count);
    }
    
    {
    NSDictionary *values = @{ @"key1": uuid(@"00000000-0000-0000-0000-000000000000"), @"key2": uuid(@"137DECC8-B300-4954-A233-F89909F4FD89") };
    for (id key in unmanaged.uuidObj) {
        id value = unmanaged.uuidObj[key];
        XCTAssertEqualObjects(values[key], value);
    }
    XCTAssertEqual(values.count, unmanaged.uuidObj.count);
    }
    
    {
    NSDictionary *values = @{ @"key1": uuid(@"00000000-0000-0000-0000-000000000000"), @"key2": NSNull.null };
    for (id key in optUnmanaged.uuidObj) {
        id value = optUnmanaged.uuidObj[key];
        XCTAssertEqualObjects(values[key], value);
    }
    XCTAssertEqual(values.count, optUnmanaged.uuidObj.count);
    }
    
    {
    NSDictionary *values = @{ @"key1": uuid(@"00000000-0000-0000-0000-000000000000"), @"key2": uuid(@"137DECC8-B300-4954-A233-F89909F4FD89") };
    for (id key in managed.uuidObj) {
        id value = managed.uuidObj[key];
        XCTAssertEqualObjects(values[key], value);
    }
    XCTAssertEqual(values.count, managed.uuidObj.count);
    }
    
    {
    NSDictionary *values = @{ @"key1": uuid(@"00000000-0000-0000-0000-000000000000"), @"key2": NSNull.null };
    for (id key in optManaged.uuidObj) {
        id value = optManaged.uuidObj[key];
        XCTAssertEqualObjects(values[key], value);
    }
    XCTAssertEqual(values.count, optManaged.uuidObj.count);
    }
    
    {
    NSDictionary *values = @{ @"key1": @NO, @"key2": @YES };
    for (id key in unmanaged.anyBoolObj) {
        id value = unmanaged.anyBoolObj[key];
        XCTAssertEqualObjects(values[key], value);
    }
    XCTAssertEqual(values.count, unmanaged.anyBoolObj.count);
    }
    
    {
    NSDictionary *values = @{ @"key1": @2, @"key2": @3 };
    for (id key in unmanaged.anyIntObj) {
        id value = unmanaged.anyIntObj[key];
        XCTAssertEqualObjects(values[key], value);
    }
    XCTAssertEqual(values.count, unmanaged.anyIntObj.count);
    }
    
    {
    NSDictionary *values = @{ @"key1": @2.2f, @"key2": @3.3f };
    for (id key in unmanaged.anyFloatObj) {
        id value = unmanaged.anyFloatObj[key];
        XCTAssertEqualObjects(values[key], value);
    }
    XCTAssertEqual(values.count, unmanaged.anyFloatObj.count);
    }
    
    {
    NSDictionary *values = @{ @"key1": @2.2, @"key2": @3.3 };
    for (id key in unmanaged.anyDoubleObj) {
        id value = unmanaged.anyDoubleObj[key];
        XCTAssertEqualObjects(values[key], value);
    }
    XCTAssertEqual(values.count, unmanaged.anyDoubleObj.count);
    }
    
    {
    NSDictionary *values = @{ @"key1": @"a", @"key2": @"b" };
    for (id key in unmanaged.anyStringObj) {
        id value = unmanaged.anyStringObj[key];
        XCTAssertEqualObjects(values[key], value);
    }
    XCTAssertEqual(values.count, unmanaged.anyStringObj.count);
    }
    
    {
    NSDictionary *values = @{ @"key1": data(1), @"key2": data(2) };
    for (id key in unmanaged.anyDataObj) {
        id value = unmanaged.anyDataObj[key];
        XCTAssertEqualObjects(values[key], value);
    }
    XCTAssertEqual(values.count, unmanaged.anyDataObj.count);
    }
    
    {
    NSDictionary *values = @{ @"key1": date(1), @"key2": date(2) };
    for (id key in unmanaged.anyDateObj) {
        id value = unmanaged.anyDateObj[key];
        XCTAssertEqualObjects(values[key], value);
    }
    XCTAssertEqual(values.count, unmanaged.anyDateObj.count);
    }
    
    {
    NSDictionary *values = @{ @"key1": decimal128(2), @"key2": decimal128(3) };
    for (id key in unmanaged.anyDecimalObj) {
        id value = unmanaged.anyDecimalObj[key];
        XCTAssertEqualObjects(values[key], value);
    }
    XCTAssertEqual(values.count, unmanaged.anyDecimalObj.count);
    }
    
    {
    NSDictionary *values = @{ @"key1": objectId(1), @"key2": objectId(2) };
    for (id key in unmanaged.anyObjectIdObj) {
        id value = unmanaged.anyObjectIdObj[key];
        XCTAssertEqualObjects(values[key], value);
    }
    XCTAssertEqual(values.count, unmanaged.anyObjectIdObj.count);
    }
    
    {
    NSDictionary *values = @{ @"key1": uuid(@"00000000-0000-0000-0000-000000000000"), @"key2": uuid(@"137DECC8-B300-4954-A233-F89909F4FD89") };
    for (id key in unmanaged.anyUUIDObj) {
        id value = unmanaged.anyUUIDObj[key];
        XCTAssertEqualObjects(values[key], value);
    }
    XCTAssertEqual(values.count, unmanaged.anyUUIDObj.count);
    }
    
    {
    NSDictionary *values = @{ @"key1": @NO, @"key2": @YES };
    for (id key in managed.anyBoolObj) {
        id value = managed.anyBoolObj[key];
        XCTAssertEqualObjects(values[key], value);
    }
    XCTAssertEqual(values.count, managed.anyBoolObj.count);
    }
    
    {
    NSDictionary *values = @{ @"key1": @2, @"key2": @3 };
    for (id key in managed.anyIntObj) {
        id value = managed.anyIntObj[key];
        XCTAssertEqualObjects(values[key], value);
    }
    XCTAssertEqual(values.count, managed.anyIntObj.count);
    }
    
    {
    NSDictionary *values = @{ @"key1": @2.2f, @"key2": @3.3f };
    for (id key in managed.anyFloatObj) {
        id value = managed.anyFloatObj[key];
        XCTAssertEqualObjects(values[key], value);
    }
    XCTAssertEqual(values.count, managed.anyFloatObj.count);
    }
    
    {
    NSDictionary *values = @{ @"key1": @2.2, @"key2": @3.3 };
    for (id key in managed.anyDoubleObj) {
        id value = managed.anyDoubleObj[key];
        XCTAssertEqualObjects(values[key], value);
    }
    XCTAssertEqual(values.count, managed.anyDoubleObj.count);
    }
    
    {
    NSDictionary *values = @{ @"key1": @"a", @"key2": @"b" };
    for (id key in managed.anyStringObj) {
        id value = managed.anyStringObj[key];
        XCTAssertEqualObjects(values[key], value);
    }
    XCTAssertEqual(values.count, managed.anyStringObj.count);
    }
    
    {
    NSDictionary *values = @{ @"key1": data(1), @"key2": data(2) };
    for (id key in managed.anyDataObj) {
        id value = managed.anyDataObj[key];
        XCTAssertEqualObjects(values[key], value);
    }
    XCTAssertEqual(values.count, managed.anyDataObj.count);
    }
    
    {
    NSDictionary *values = @{ @"key1": date(1), @"key2": date(2) };
    for (id key in managed.anyDateObj) {
        id value = managed.anyDateObj[key];
        XCTAssertEqualObjects(values[key], value);
    }
    XCTAssertEqual(values.count, managed.anyDateObj.count);
    }
    
    {
    NSDictionary *values = @{ @"key1": decimal128(2), @"key2": decimal128(3) };
    for (id key in managed.anyDecimalObj) {
        id value = managed.anyDecimalObj[key];
        XCTAssertEqualObjects(values[key], value);
    }
    XCTAssertEqual(values.count, managed.anyDecimalObj.count);
    }
    
    {
    NSDictionary *values = @{ @"key1": objectId(1), @"key2": objectId(2) };
    for (id key in managed.anyObjectIdObj) {
        id value = managed.anyObjectIdObj[key];
        XCTAssertEqualObjects(values[key], value);
    }
    XCTAssertEqual(values.count, managed.anyObjectIdObj.count);
    }
    
    {
    NSDictionary *values = @{ @"key1": uuid(@"00000000-0000-0000-0000-000000000000"), @"key2": uuid(@"137DECC8-B300-4954-A233-F89909F4FD89") };
    for (id key in managed.anyUUIDObj) {
        id value = managed.anyUUIDObj[key];
        XCTAssertEqualObjects(values[key], value);
    }
    XCTAssertEqual(values.count, managed.anyUUIDObj.count);
    }
    
}

- (void)testValueForKeyNumericAggregates {
    XCTAssertNil([unmanaged.intObj valueForKeyPath:@"@min.self"]);
    XCTAssertNil([optUnmanaged.intObj valueForKeyPath:@"@min.self"]);
    XCTAssertNil([managed.intObj valueForKeyPath:@"@min.self"]);
    XCTAssertNil([optManaged.intObj valueForKeyPath:@"@min.self"]);
    XCTAssertNil([unmanaged.dateObj valueForKeyPath:@"@min.self"]);
    XCTAssertNil([optUnmanaged.dateObj valueForKeyPath:@"@min.self"]);
    XCTAssertNil([managed.dateObj valueForKeyPath:@"@min.self"]);
    XCTAssertNil([optManaged.dateObj valueForKeyPath:@"@min.self"]);
    XCTAssertNil([unmanaged.floatObj valueForKeyPath:@"@min.self"]);
    XCTAssertNil([optUnmanaged.floatObj valueForKeyPath:@"@min.self"]);
    XCTAssertNil([managed.floatObj valueForKeyPath:@"@min.self"]);
    XCTAssertNil([optManaged.floatObj valueForKeyPath:@"@min.self"]);
    XCTAssertNil([unmanaged.doubleObj valueForKeyPath:@"@min.self"]);
    XCTAssertNil([optUnmanaged.doubleObj valueForKeyPath:@"@min.self"]);
    XCTAssertNil([managed.doubleObj valueForKeyPath:@"@min.self"]);
    XCTAssertNil([optManaged.doubleObj valueForKeyPath:@"@min.self"]);
    XCTAssertNil([unmanaged.decimalObj valueForKeyPath:@"@min.self"]);
    XCTAssertNil([optUnmanaged.decimalObj valueForKeyPath:@"@min.self"]);
    XCTAssertNil([managed.decimalObj valueForKeyPath:@"@min.self"]);
    XCTAssertNil([optManaged.decimalObj valueForKeyPath:@"@min.self"]);
    XCTAssertNil([unmanaged.anyFloatObj valueForKeyPath:@"@min.self"]);
    XCTAssertNil([unmanaged.anyDoubleObj valueForKeyPath:@"@min.self"]);
    XCTAssertNil([unmanaged.anyDateObj valueForKeyPath:@"@min.self"]);
    XCTAssertNil([unmanaged.anyDecimalObj valueForKeyPath:@"@min.self"]);
    XCTAssertNil([managed.anyFloatObj valueForKeyPath:@"@min.self"]);
    XCTAssertNil([managed.anyDoubleObj valueForKeyPath:@"@min.self"]);
    XCTAssertNil([managed.anyDecimalObj valueForKeyPath:@"@min.self"]);
    XCTAssertNil([unmanaged.intObj valueForKeyPath:@"@max.self"]);
    XCTAssertNil([optUnmanaged.intObj valueForKeyPath:@"@max.self"]);
    XCTAssertNil([managed.intObj valueForKeyPath:@"@max.self"]);
    XCTAssertNil([optManaged.intObj valueForKeyPath:@"@max.self"]);
    XCTAssertNil([unmanaged.dateObj valueForKeyPath:@"@max.self"]);
    XCTAssertNil([optUnmanaged.dateObj valueForKeyPath:@"@max.self"]);
    XCTAssertNil([managed.dateObj valueForKeyPath:@"@max.self"]);
    XCTAssertNil([optManaged.dateObj valueForKeyPath:@"@max.self"]);
    XCTAssertNil([unmanaged.floatObj valueForKeyPath:@"@max.self"]);
    XCTAssertNil([optUnmanaged.floatObj valueForKeyPath:@"@max.self"]);
    XCTAssertNil([managed.floatObj valueForKeyPath:@"@max.self"]);
    XCTAssertNil([optManaged.floatObj valueForKeyPath:@"@max.self"]);
    XCTAssertNil([unmanaged.doubleObj valueForKeyPath:@"@max.self"]);
    XCTAssertNil([optUnmanaged.doubleObj valueForKeyPath:@"@max.self"]);
    XCTAssertNil([managed.doubleObj valueForKeyPath:@"@max.self"]);
    XCTAssertNil([optManaged.doubleObj valueForKeyPath:@"@max.self"]);
    XCTAssertNil([unmanaged.decimalObj valueForKeyPath:@"@max.self"]);
    XCTAssertNil([optUnmanaged.decimalObj valueForKeyPath:@"@max.self"]);
    XCTAssertNil([managed.decimalObj valueForKeyPath:@"@max.self"]);
    XCTAssertNil([optManaged.decimalObj valueForKeyPath:@"@max.self"]);
    XCTAssertNil([unmanaged.anyFloatObj valueForKeyPath:@"@max.self"]);
    XCTAssertNil([unmanaged.anyDoubleObj valueForKeyPath:@"@max.self"]);
    XCTAssertNil([unmanaged.anyDateObj valueForKeyPath:@"@max.self"]);
    XCTAssertNil([unmanaged.anyDecimalObj valueForKeyPath:@"@max.self"]);
    XCTAssertNil([managed.anyFloatObj valueForKeyPath:@"@max.self"]);
    XCTAssertNil([managed.anyDoubleObj valueForKeyPath:@"@max.self"]);
    XCTAssertNil([managed.anyDecimalObj valueForKeyPath:@"@max.self"]);
    XCTAssertEqualObjects([unmanaged.intObj valueForKeyPath:@"@sum.self"], @0);
    XCTAssertEqualObjects([optUnmanaged.intObj valueForKeyPath:@"@sum.self"], @0);
    XCTAssertEqualObjects([managed.intObj valueForKeyPath:@"@sum.self"], @0);
    XCTAssertEqualObjects([optManaged.intObj valueForKeyPath:@"@sum.self"], @0);
    XCTAssertEqualObjects([unmanaged.floatObj valueForKeyPath:@"@sum.self"], @0);
    XCTAssertEqualObjects([optUnmanaged.floatObj valueForKeyPath:@"@sum.self"], @0);
    XCTAssertEqualObjects([managed.floatObj valueForKeyPath:@"@sum.self"], @0);
    XCTAssertEqualObjects([optManaged.floatObj valueForKeyPath:@"@sum.self"], @0);
    XCTAssertEqualObjects([unmanaged.doubleObj valueForKeyPath:@"@sum.self"], @0);
    XCTAssertEqualObjects([optUnmanaged.doubleObj valueForKeyPath:@"@sum.self"], @0);
    XCTAssertEqualObjects([managed.doubleObj valueForKeyPath:@"@sum.self"], @0);
    XCTAssertEqualObjects([optManaged.doubleObj valueForKeyPath:@"@sum.self"], @0);
    XCTAssertEqualObjects([unmanaged.decimalObj valueForKeyPath:@"@sum.self"], @0);
    XCTAssertEqualObjects([optUnmanaged.decimalObj valueForKeyPath:@"@sum.self"], @0);
    XCTAssertEqualObjects([managed.decimalObj valueForKeyPath:@"@sum.self"], @0);
    XCTAssertEqualObjects([optManaged.decimalObj valueForKeyPath:@"@sum.self"], @0);
    XCTAssertEqualObjects([unmanaged.anyIntObj valueForKeyPath:@"@sum.self"], @0);
    XCTAssertEqualObjects([unmanaged.anyFloatObj valueForKeyPath:@"@sum.self"], @0);
    XCTAssertEqualObjects([unmanaged.anyDoubleObj valueForKeyPath:@"@sum.self"], @0);
    XCTAssertEqualObjects([unmanaged.anyDecimalObj valueForKeyPath:@"@sum.self"], @0);
    XCTAssertEqualObjects([managed.anyIntObj valueForKeyPath:@"@sum.self"], @0);
    XCTAssertEqualObjects([managed.anyFloatObj valueForKeyPath:@"@sum.self"], @0);
    XCTAssertEqualObjects([managed.anyDoubleObj valueForKeyPath:@"@sum.self"], @0);
    XCTAssertEqualObjects([managed.anyDecimalObj valueForKeyPath:@"@sum.self"], @0);
    XCTAssertNil([unmanaged.intObj valueForKeyPath:@"@avg.self"]);
    XCTAssertNil([optUnmanaged.intObj valueForKeyPath:@"@avg.self"]);
    XCTAssertNil([managed.intObj valueForKeyPath:@"@avg.self"]);
    XCTAssertNil([optManaged.intObj valueForKeyPath:@"@avg.self"]);
    XCTAssertNil([unmanaged.floatObj valueForKeyPath:@"@avg.self"]);
    XCTAssertNil([optUnmanaged.floatObj valueForKeyPath:@"@avg.self"]);
    XCTAssertNil([managed.floatObj valueForKeyPath:@"@avg.self"]);
    XCTAssertNil([optManaged.floatObj valueForKeyPath:@"@avg.self"]);
    XCTAssertNil([unmanaged.doubleObj valueForKeyPath:@"@avg.self"]);
    XCTAssertNil([optUnmanaged.doubleObj valueForKeyPath:@"@avg.self"]);
    XCTAssertNil([managed.doubleObj valueForKeyPath:@"@avg.self"]);
    XCTAssertNil([optManaged.doubleObj valueForKeyPath:@"@avg.self"]);
    XCTAssertNil([unmanaged.decimalObj valueForKeyPath:@"@avg.self"]);
    XCTAssertNil([optUnmanaged.decimalObj valueForKeyPath:@"@avg.self"]);
    XCTAssertNil([managed.decimalObj valueForKeyPath:@"@avg.self"]);
    XCTAssertNil([optManaged.decimalObj valueForKeyPath:@"@avg.self"]);
    XCTAssertNil([unmanaged.anyIntObj valueForKeyPath:@"@avg.self"]);
    XCTAssertNil([unmanaged.anyFloatObj valueForKeyPath:@"@avg.self"]);
    XCTAssertNil([unmanaged.anyDoubleObj valueForKeyPath:@"@avg.self"]);
    XCTAssertNil([unmanaged.anyDecimalObj valueForKeyPath:@"@avg.self"]);
    XCTAssertNil([managed.anyIntObj valueForKeyPath:@"@avg.self"]);
    XCTAssertNil([managed.anyFloatObj valueForKeyPath:@"@avg.self"]);
    XCTAssertNil([managed.anyDoubleObj valueForKeyPath:@"@avg.self"]);
    XCTAssertNil([managed.anyDecimalObj valueForKeyPath:@"@avg.self"]);

    [self addObjects];

    XCTAssertEqualObjects([unmanaged.intObj valueForKeyPath:@"@min.self"], @2);
    XCTAssertEqualObjects([optUnmanaged.intObj valueForKeyPath:@"@min.self"], @2);
    XCTAssertEqualObjects([managed.intObj valueForKeyPath:@"@min.self"], @2);
    XCTAssertEqualObjects([optManaged.intObj valueForKeyPath:@"@min.self"], @2);
    XCTAssertEqualObjects([unmanaged.dateObj valueForKeyPath:@"@min.self"], date(1));
    XCTAssertEqualObjects([optUnmanaged.dateObj valueForKeyPath:@"@min.self"], date(1));
    XCTAssertEqualObjects([managed.dateObj valueForKeyPath:@"@min.self"], date(1));
    XCTAssertEqualObjects([optManaged.dateObj valueForKeyPath:@"@min.self"], date(1));
    XCTAssertEqualObjects([unmanaged.floatObj valueForKeyPath:@"@min.self"], @2.2f);
    XCTAssertEqualObjects([optUnmanaged.floatObj valueForKeyPath:@"@min.self"], @2.2f);
    XCTAssertEqualObjects([managed.floatObj valueForKeyPath:@"@min.self"], @2.2f);
    XCTAssertEqualObjects([optManaged.floatObj valueForKeyPath:@"@min.self"], @2.2f);
    XCTAssertEqualObjects([unmanaged.doubleObj valueForKeyPath:@"@min.self"], @2.2);
    XCTAssertEqualObjects([optUnmanaged.doubleObj valueForKeyPath:@"@min.self"], @2.2);
    XCTAssertEqualObjects([managed.doubleObj valueForKeyPath:@"@min.self"], @2.2);
    XCTAssertEqualObjects([optManaged.doubleObj valueForKeyPath:@"@min.self"], @2.2);
    XCTAssertEqualObjects([unmanaged.decimalObj valueForKeyPath:@"@min.self"], decimal128(2));
    XCTAssertEqualObjects([optUnmanaged.decimalObj valueForKeyPath:@"@min.self"], decimal128(2));
    XCTAssertEqualObjects([managed.decimalObj valueForKeyPath:@"@min.self"], decimal128(2));
    XCTAssertEqualObjects([optManaged.decimalObj valueForKeyPath:@"@min.self"], decimal128(2));
    XCTAssertEqualObjects([unmanaged.anyFloatObj valueForKeyPath:@"@min.self"], @2.2f);
    XCTAssertEqualObjects([unmanaged.anyDoubleObj valueForKeyPath:@"@min.self"], @2.2);
    XCTAssertEqualObjects([unmanaged.anyDateObj valueForKeyPath:@"@min.self"], date(1));
    XCTAssertEqualObjects([unmanaged.anyDecimalObj valueForKeyPath:@"@min.self"], decimal128(2));
    XCTAssertEqualObjects([managed.anyFloatObj valueForKeyPath:@"@min.self"], @2.2f);
    XCTAssertEqualObjects([managed.anyDoubleObj valueForKeyPath:@"@min.self"], @2.2);
    XCTAssertEqualObjects([managed.anyDecimalObj valueForKeyPath:@"@min.self"], decimal128(2));
    XCTAssertEqualObjects([unmanaged.intObj valueForKeyPath:@"@max.self"], @3);
    XCTAssertEqualObjects([managed.intObj valueForKeyPath:@"@max.self"], @3);
    XCTAssertEqualObjects([unmanaged.dateObj valueForKeyPath:@"@max.self"], date(2));
    XCTAssertEqualObjects([managed.dateObj valueForKeyPath:@"@max.self"], date(2));
    XCTAssertEqualObjects([unmanaged.floatObj valueForKeyPath:@"@max.self"], @3.3f);
    XCTAssertEqualObjects([managed.floatObj valueForKeyPath:@"@max.self"], @3.3f);
    XCTAssertEqualObjects([unmanaged.doubleObj valueForKeyPath:@"@max.self"], @3.3);
    XCTAssertEqualObjects([managed.doubleObj valueForKeyPath:@"@max.self"], @3.3);
    XCTAssertEqualObjects([unmanaged.decimalObj valueForKeyPath:@"@max.self"], decimal128(3));
    XCTAssertEqualObjects([managed.decimalObj valueForKeyPath:@"@max.self"], decimal128(3));
    XCTAssertEqualObjects([unmanaged.anyFloatObj valueForKeyPath:@"@max.self"], @3.3f);
    XCTAssertEqualObjects([unmanaged.anyDoubleObj valueForKeyPath:@"@max.self"], @3.3);
    XCTAssertEqualObjects([unmanaged.anyDateObj valueForKeyPath:@"@max.self"], date(2));
    XCTAssertEqualObjects([unmanaged.anyDecimalObj valueForKeyPath:@"@max.self"], decimal128(3));
    XCTAssertEqualObjects([managed.anyFloatObj valueForKeyPath:@"@max.self"], @3.3f);
    XCTAssertEqualObjects([managed.anyDoubleObj valueForKeyPath:@"@max.self"], @3.3);
    XCTAssertEqualObjects([managed.anyDecimalObj valueForKeyPath:@"@max.self"], decimal128(3));
    XCTAssertEqualObjects([optUnmanaged.intObj valueForKeyPath:@"@max.self"], @2);
    XCTAssertEqualObjects([optManaged.intObj valueForKeyPath:@"@max.self"], @2);
    XCTAssertEqualObjects([optUnmanaged.dateObj valueForKeyPath:@"@max.self"], date(1));
    XCTAssertEqualObjects([optManaged.dateObj valueForKeyPath:@"@max.self"], date(1));
    XCTAssertEqualObjects([optUnmanaged.floatObj valueForKeyPath:@"@max.self"], @2.2f);
    XCTAssertEqualObjects([optManaged.floatObj valueForKeyPath:@"@max.self"], @2.2f);
    XCTAssertEqualObjects([optUnmanaged.doubleObj valueForKeyPath:@"@max.self"], @2.2);
    XCTAssertEqualObjects([optManaged.doubleObj valueForKeyPath:@"@max.self"], @2.2);
    XCTAssertEqualObjects([optUnmanaged.decimalObj valueForKeyPath:@"@max.self"], decimal128(2));
    XCTAssertEqualObjects([optManaged.decimalObj valueForKeyPath:@"@max.self"], decimal128(2));
    XCTAssertEqualWithAccuracy([[unmanaged.intObj valueForKeyPath:@"@sum.self"] doubleValue], sum(@{ @"key1": @2, @"key2": @3 }), .001);
    XCTAssertEqualWithAccuracy([[optUnmanaged.intObj valueForKeyPath:@"@sum.self"] doubleValue], sum(@{ @"key1": @2, @"key2": NSNull.null }), .001);
    XCTAssertEqualWithAccuracy([[managed.intObj valueForKeyPath:@"@sum.self"] doubleValue], sum(@{ @"key1": @2, @"key2": @3 }), .001);
    XCTAssertEqualWithAccuracy([[optManaged.intObj valueForKeyPath:@"@sum.self"] doubleValue], sum(@{ @"key1": @2, @"key2": NSNull.null }), .001);
    XCTAssertEqualWithAccuracy([[unmanaged.floatObj valueForKeyPath:@"@sum.self"] doubleValue], sum(@{ @"key1": @2.2f, @"key2": @3.3f }), .001);
    XCTAssertEqualWithAccuracy([[optUnmanaged.floatObj valueForKeyPath:@"@sum.self"] doubleValue], sum(@{ @"key1": @2.2f, @"key2": NSNull.null }), .001);
    XCTAssertEqualWithAccuracy([[managed.floatObj valueForKeyPath:@"@sum.self"] doubleValue], sum(@{ @"key1": @2.2f, @"key2": @3.3f }), .001);
    XCTAssertEqualWithAccuracy([[optManaged.floatObj valueForKeyPath:@"@sum.self"] doubleValue], sum(@{ @"key1": @2.2f, @"key2": NSNull.null }), .001);
    XCTAssertEqualWithAccuracy([[unmanaged.doubleObj valueForKeyPath:@"@sum.self"] doubleValue], sum(@{ @"key1": @2.2, @"key2": @3.3 }), .001);
    XCTAssertEqualWithAccuracy([[optUnmanaged.doubleObj valueForKeyPath:@"@sum.self"] doubleValue], sum(@{ @"key1": @2.2, @"key2": NSNull.null }), .001);
    XCTAssertEqualWithAccuracy([[managed.doubleObj valueForKeyPath:@"@sum.self"] doubleValue], sum(@{ @"key1": @2.2, @"key2": @3.3 }), .001);
    XCTAssertEqualWithAccuracy([[optManaged.doubleObj valueForKeyPath:@"@sum.self"] doubleValue], sum(@{ @"key1": @2.2, @"key2": NSNull.null }), .001);
    XCTAssertEqualWithAccuracy([[unmanaged.decimalObj valueForKeyPath:@"@sum.self"] doubleValue], sum(@{ @"key1": decimal128(2), @"key2": decimal128(3) }), .001);
    XCTAssertEqualWithAccuracy([[optUnmanaged.decimalObj valueForKeyPath:@"@sum.self"] doubleValue], sum(@{ @"key1": decimal128(2), @"key2": NSNull.null }), .001);
    XCTAssertEqualWithAccuracy([[managed.decimalObj valueForKeyPath:@"@sum.self"] doubleValue], sum(@{ @"key1": decimal128(2), @"key2": decimal128(3) }), .001);
    XCTAssertEqualWithAccuracy([[optManaged.decimalObj valueForKeyPath:@"@sum.self"] doubleValue], sum(@{ @"key1": decimal128(2), @"key2": NSNull.null }), .001);
    XCTAssertEqualWithAccuracy([[unmanaged.anyIntObj valueForKeyPath:@"@sum.self"] doubleValue], sum(@{ @"key1": @2, @"key2": @3 }), .001);
    XCTAssertEqualWithAccuracy([[unmanaged.anyFloatObj valueForKeyPath:@"@sum.self"] doubleValue], sum(@{ @"key1": @2.2f, @"key2": @3.3f }), .001);
    XCTAssertEqualWithAccuracy([[unmanaged.anyDoubleObj valueForKeyPath:@"@sum.self"] doubleValue], sum(@{ @"key1": @2.2, @"key2": @3.3 }), .001);
    XCTAssertEqualWithAccuracy([[unmanaged.anyDecimalObj valueForKeyPath:@"@sum.self"] doubleValue], sum(@{ @"key1": decimal128(2), @"key2": decimal128(3) }), .001);
    XCTAssertEqualWithAccuracy([[managed.anyIntObj valueForKeyPath:@"@sum.self"] doubleValue], sum(@{ @"key1": @2, @"key2": @3 }), .001);
    XCTAssertEqualWithAccuracy([[managed.anyFloatObj valueForKeyPath:@"@sum.self"] doubleValue], sum(@{ @"key1": @2.2f, @"key2": @3.3f }), .001);
    XCTAssertEqualWithAccuracy([[managed.anyDoubleObj valueForKeyPath:@"@sum.self"] doubleValue], sum(@{ @"key1": @2.2, @"key2": @3.3 }), .001);
    XCTAssertEqualWithAccuracy([[managed.anyDecimalObj valueForKeyPath:@"@sum.self"] doubleValue], sum(@{ @"key1": decimal128(2), @"key2": decimal128(3) }), .001);
    XCTAssertEqualWithAccuracy([[unmanaged.intObj valueForKeyPath:@"@avg.self"] doubleValue], average(@{ @"key1": @2, @"key2": @3 }), .001);
    XCTAssertEqualWithAccuracy([[optUnmanaged.intObj valueForKeyPath:@"@avg.self"] doubleValue], average(@{ @"key1": @2, @"key2": NSNull.null }), .001);
    XCTAssertEqualWithAccuracy([[managed.intObj valueForKeyPath:@"@avg.self"] doubleValue], average(@{ @"key1": @2, @"key2": @3 }), .001);
    XCTAssertEqualWithAccuracy([[optManaged.intObj valueForKeyPath:@"@avg.self"] doubleValue], average(@{ @"key1": @2, @"key2": NSNull.null }), .001);
    XCTAssertEqualWithAccuracy([[unmanaged.floatObj valueForKeyPath:@"@avg.self"] doubleValue], average(@{ @"key1": @2.2f, @"key2": @3.3f }), .001);
    XCTAssertEqualWithAccuracy([[optUnmanaged.floatObj valueForKeyPath:@"@avg.self"] doubleValue], average(@{ @"key1": @2.2f, @"key2": NSNull.null }), .001);
    XCTAssertEqualWithAccuracy([[managed.floatObj valueForKeyPath:@"@avg.self"] doubleValue], average(@{ @"key1": @2.2f, @"key2": @3.3f }), .001);
    XCTAssertEqualWithAccuracy([[optManaged.floatObj valueForKeyPath:@"@avg.self"] doubleValue], average(@{ @"key1": @2.2f, @"key2": NSNull.null }), .001);
    XCTAssertEqualWithAccuracy([[unmanaged.doubleObj valueForKeyPath:@"@avg.self"] doubleValue], average(@{ @"key1": @2.2, @"key2": @3.3 }), .001);
    XCTAssertEqualWithAccuracy([[optUnmanaged.doubleObj valueForKeyPath:@"@avg.self"] doubleValue], average(@{ @"key1": @2.2, @"key2": NSNull.null }), .001);
    XCTAssertEqualWithAccuracy([[managed.doubleObj valueForKeyPath:@"@avg.self"] doubleValue], average(@{ @"key1": @2.2, @"key2": @3.3 }), .001);
    XCTAssertEqualWithAccuracy([[optManaged.doubleObj valueForKeyPath:@"@avg.self"] doubleValue], average(@{ @"key1": @2.2, @"key2": NSNull.null }), .001);
    XCTAssertEqualWithAccuracy([[unmanaged.decimalObj valueForKeyPath:@"@avg.self"] doubleValue], average(@{ @"key1": decimal128(2), @"key2": decimal128(3) }), .001);
    XCTAssertEqualWithAccuracy([[optUnmanaged.decimalObj valueForKeyPath:@"@avg.self"] doubleValue], average(@{ @"key1": decimal128(2), @"key2": NSNull.null }), .001);
    XCTAssertEqualWithAccuracy([[managed.decimalObj valueForKeyPath:@"@avg.self"] doubleValue], average(@{ @"key1": decimal128(2), @"key2": decimal128(3) }), .001);
    XCTAssertEqualWithAccuracy([[optManaged.decimalObj valueForKeyPath:@"@avg.self"] doubleValue], average(@{ @"key1": decimal128(2), @"key2": NSNull.null }), .001);
    XCTAssertEqualWithAccuracy([[unmanaged.anyIntObj valueForKeyPath:@"@avg.self"] doubleValue], average(@{ @"key1": @2, @"key2": @3 }), .001);
    XCTAssertEqualWithAccuracy([[unmanaged.anyFloatObj valueForKeyPath:@"@avg.self"] doubleValue], average(@{ @"key1": @2.2f, @"key2": @3.3f }), .001);
    XCTAssertEqualWithAccuracy([[unmanaged.anyDoubleObj valueForKeyPath:@"@avg.self"] doubleValue], average(@{ @"key1": @2.2, @"key2": @3.3 }), .001);
    XCTAssertEqualWithAccuracy([[unmanaged.anyDecimalObj valueForKeyPath:@"@avg.self"] doubleValue], average(@{ @"key1": decimal128(2), @"key2": decimal128(3) }), .001);
    XCTAssertEqualWithAccuracy([[managed.anyIntObj valueForKeyPath:@"@avg.self"] doubleValue], average(@{ @"key1": @2, @"key2": @3 }), .001);
    XCTAssertEqualWithAccuracy([[managed.anyFloatObj valueForKeyPath:@"@avg.self"] doubleValue], average(@{ @"key1": @2.2f, @"key2": @3.3f }), .001);
    XCTAssertEqualWithAccuracy([[managed.anyDoubleObj valueForKeyPath:@"@avg.self"] doubleValue], average(@{ @"key1": @2.2, @"key2": @3.3 }), .001);
    XCTAssertEqualWithAccuracy([[managed.anyDecimalObj valueForKeyPath:@"@avg.self"] doubleValue], average(@{ @"key1": decimal128(2), @"key2": decimal128(3) }), .001);
}

- (void)testSetValueForKey {
    RLMAssertThrowsWithReason([unmanaged.boolObj setValue:@"a" forKey:@"key1"],
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'bool'");
    RLMAssertThrowsWithReason([optUnmanaged.boolObj setValue:@"a" forKey:@"key1"],
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'bool?'");
    RLMAssertThrowsWithReason([managed.boolObj setValue:@"a" forKey:@"key1"],
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'bool'");
    RLMAssertThrowsWithReason([optManaged.boolObj setValue:@"a" forKey:@"key1"],
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'bool?'");
    RLMAssertThrowsWithReason([unmanaged.intObj setValue:@"a" forKey:@"key1"],
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'int'");
    RLMAssertThrowsWithReason([optUnmanaged.intObj setValue:@"a" forKey:@"key1"],
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'int?'");
    RLMAssertThrowsWithReason([managed.intObj setValue:@"a" forKey:@"key1"],
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'int'");
    RLMAssertThrowsWithReason([optManaged.intObj setValue:@"a" forKey:@"key1"],
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'int?'");
    RLMAssertThrowsWithReason([unmanaged.stringObj setValue:@2 forKey:@"key1"],
                              @"Invalid value '2' of type '__NSCFNumber' for expected type 'string'");
    RLMAssertThrowsWithReason([optUnmanaged.stringObj setValue:@2 forKey:@"key1"],
                              @"Invalid value '2' of type '__NSCFNumber' for expected type 'string?'");
    RLMAssertThrowsWithReason([managed.stringObj setValue:@2 forKey:@"key1"],
                              @"Invalid value '2' of type '__NSCFNumber' for expected type 'string'");
    RLMAssertThrowsWithReason([optManaged.stringObj setValue:@2 forKey:@"key1"],
                              @"Invalid value '2' of type '__NSCFNumber' for expected type 'string?'");
    RLMAssertThrowsWithReason([unmanaged.dateObj setValue:@"a" forKey:@"key1"],
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'date'");
    RLMAssertThrowsWithReason([optUnmanaged.dateObj setValue:@"a" forKey:@"key1"],
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'date?'");
    RLMAssertThrowsWithReason([managed.dateObj setValue:@"a" forKey:@"key1"],
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'date'");
    RLMAssertThrowsWithReason([optManaged.dateObj setValue:@"a" forKey:@"key1"],
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'date?'");
    RLMAssertThrowsWithReason([unmanaged.floatObj setValue:@"a" forKey:@"key1"],
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'float'");
    RLMAssertThrowsWithReason([optUnmanaged.floatObj setValue:@"a" forKey:@"key1"],
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'float?'");
    RLMAssertThrowsWithReason([managed.floatObj setValue:@"a" forKey:@"key1"],
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'float'");
    RLMAssertThrowsWithReason([optManaged.floatObj setValue:@"a" forKey:@"key1"],
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'float?'");
    RLMAssertThrowsWithReason([unmanaged.doubleObj setValue:@"a" forKey:@"key1"],
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'double'");
    RLMAssertThrowsWithReason([optUnmanaged.doubleObj setValue:@"a" forKey:@"key1"],
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'double?'");
    RLMAssertThrowsWithReason([managed.doubleObj setValue:@"a" forKey:@"key1"],
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'double'");
    RLMAssertThrowsWithReason([optManaged.doubleObj setValue:@"a" forKey:@"key1"],
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'double?'");
    RLMAssertThrowsWithReason([unmanaged.dataObj setValue:@"a" forKey:@"key1"],
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'data'");
    RLMAssertThrowsWithReason([optUnmanaged.dataObj setValue:@"a" forKey:@"key1"],
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'data?'");
    RLMAssertThrowsWithReason([managed.dataObj setValue:@"a" forKey:@"key1"],
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'data'");
    RLMAssertThrowsWithReason([optManaged.dataObj setValue:@"a" forKey:@"key1"],
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'data?'");
    RLMAssertThrowsWithReason([unmanaged.decimalObj setValue:@"a" forKey:@"key1"],
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'decimal128'");
    RLMAssertThrowsWithReason([optUnmanaged.decimalObj setValue:@"a" forKey:@"key1"],
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'decimal128?'");
    RLMAssertThrowsWithReason([managed.decimalObj setValue:@"a" forKey:@"key1"],
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'decimal128'");
    RLMAssertThrowsWithReason([optManaged.decimalObj setValue:@"a" forKey:@"key1"],
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'decimal128?'");
    RLMAssertThrowsWithReason([unmanaged.objectIdObj setValue:@"a" forKey:@"key1"],
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'object id'");
    RLMAssertThrowsWithReason([optUnmanaged.objectIdObj setValue:@"a" forKey:@"key1"],
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'object id?'");
    RLMAssertThrowsWithReason([managed.objectIdObj setValue:@"a" forKey:@"key1"],
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'object id'");
    RLMAssertThrowsWithReason([optManaged.objectIdObj setValue:@"a" forKey:@"key1"],
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'object id?'");
    RLMAssertThrowsWithReason([unmanaged.uuidObj setValue:@"a" forKey:@"key1"],
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'uuid'");
    RLMAssertThrowsWithReason([optUnmanaged.uuidObj setValue:@"a" forKey:@"key1"],
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'uuid?'");
    RLMAssertThrowsWithReason([managed.uuidObj setValue:@"a" forKey:@"key1"],
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'uuid'");
    RLMAssertThrowsWithReason([optManaged.uuidObj setValue:@"a" forKey:@"key1"],
                              @"Invalid value 'a' of type '__NSCFConstantString' for expected type 'uuid?'");
    RLMAssertThrowsWithReason([unmanaged.boolObj setValue:(id)NSNull.null forKey:@"self"],
                              @"Invalid value '<null>' of type 'NSNull' for expected type 'bool'");
    RLMAssertThrowsWithReason([managed.boolObj setValue:(id)NSNull.null forKey:@"self"],
                              @"Invalid value '<null>' of type 'NSNull' for expected type 'bool'");
    RLMAssertThrowsWithReason([unmanaged.intObj setValue:(id)NSNull.null forKey:@"self"],
                              @"Invalid value '<null>' of type 'NSNull' for expected type 'int'");
    RLMAssertThrowsWithReason([managed.intObj setValue:(id)NSNull.null forKey:@"self"],
                              @"Invalid value '<null>' of type 'NSNull' for expected type 'int'");
    RLMAssertThrowsWithReason([unmanaged.stringObj setValue:(id)NSNull.null forKey:@"self"],
                              @"Invalid value '<null>' of type 'NSNull' for expected type 'string'");
    RLMAssertThrowsWithReason([managed.stringObj setValue:(id)NSNull.null forKey:@"self"],
                              @"Invalid value '<null>' of type 'NSNull' for expected type 'string'");
    RLMAssertThrowsWithReason([unmanaged.dateObj setValue:(id)NSNull.null forKey:@"self"],
                              @"Invalid value '<null>' of type 'NSNull' for expected type 'date'");
    RLMAssertThrowsWithReason([managed.dateObj setValue:(id)NSNull.null forKey:@"self"],
                              @"Invalid value '<null>' of type 'NSNull' for expected type 'date'");
    RLMAssertThrowsWithReason([unmanaged.floatObj setValue:(id)NSNull.null forKey:@"self"],
                              @"Invalid value '<null>' of type 'NSNull' for expected type 'float'");
    RLMAssertThrowsWithReason([managed.floatObj setValue:(id)NSNull.null forKey:@"self"],
                              @"Invalid value '<null>' of type 'NSNull' for expected type 'float'");
    RLMAssertThrowsWithReason([unmanaged.doubleObj setValue:(id)NSNull.null forKey:@"self"],
                              @"Invalid value '<null>' of type 'NSNull' for expected type 'double'");
    RLMAssertThrowsWithReason([managed.doubleObj setValue:(id)NSNull.null forKey:@"self"],
                              @"Invalid value '<null>' of type 'NSNull' for expected type 'double'");
    RLMAssertThrowsWithReason([unmanaged.dataObj setValue:(id)NSNull.null forKey:@"self"],
                              @"Invalid value '<null>' of type 'NSNull' for expected type 'data'");
    RLMAssertThrowsWithReason([managed.dataObj setValue:(id)NSNull.null forKey:@"self"],
                              @"Invalid value '<null>' of type 'NSNull' for expected type 'data'");
    RLMAssertThrowsWithReason([unmanaged.decimalObj setValue:(id)NSNull.null forKey:@"self"],
                              @"Invalid value '<null>' of type 'NSNull' for expected type 'decimal128'");
    RLMAssertThrowsWithReason([managed.decimalObj setValue:(id)NSNull.null forKey:@"self"],
                              @"Invalid value '<null>' of type 'NSNull' for expected type 'decimal128'");
    RLMAssertThrowsWithReason([unmanaged.objectIdObj setValue:(id)NSNull.null forKey:@"self"],
                              @"Invalid value '<null>' of type 'NSNull' for expected type 'object id'");
    RLMAssertThrowsWithReason([managed.objectIdObj setValue:(id)NSNull.null forKey:@"self"],
                              @"Invalid value '<null>' of type 'NSNull' for expected type 'object id'");
    RLMAssertThrowsWithReason([unmanaged.uuidObj setValue:(id)NSNull.null forKey:@"self"],
                              @"Invalid value '<null>' of type 'NSNull' for expected type 'uuid'");
    RLMAssertThrowsWithReason([managed.uuidObj setValue:(id)NSNull.null forKey:@"self"],
                              @"Invalid value '<null>' of type 'NSNull' for expected type 'uuid'");

    [self addObjects];

    XCTAssertEqualObjects(unmanaged.boolObj[@"key1"], @NO);
    XCTAssertEqualObjects(optUnmanaged.boolObj[@"key1"], @NO);
    XCTAssertEqualObjects(managed.boolObj[@"key1"], @NO);
    XCTAssertEqualObjects(optManaged.boolObj[@"key1"], @NO);
    XCTAssertEqualObjects(unmanaged.intObj[@"key1"], @2);
    XCTAssertEqualObjects(optUnmanaged.intObj[@"key1"], @2);
    XCTAssertEqualObjects(managed.intObj[@"key1"], @2);
    XCTAssertEqualObjects(optManaged.intObj[@"key1"], @2);
    XCTAssertEqualObjects(unmanaged.stringObj[@"key1"], @"bar");
    XCTAssertEqualObjects(optUnmanaged.stringObj[@"key1"], @"bar");
    XCTAssertEqualObjects(managed.stringObj[@"key1"], @"bar");
    XCTAssertEqualObjects(optManaged.stringObj[@"key1"], @"bar");
    XCTAssertEqualObjects(unmanaged.dateObj[@"key1"], date(1));
    XCTAssertEqualObjects(optUnmanaged.dateObj[@"key1"], date(1));
    XCTAssertEqualObjects(managed.dateObj[@"key1"], date(1));
    XCTAssertEqualObjects(optManaged.dateObj[@"key1"], date(1));
    XCTAssertEqualObjects(unmanaged.floatObj[@"key1"], @2.2f);
    XCTAssertEqualObjects(optUnmanaged.floatObj[@"key1"], @2.2f);
    XCTAssertEqualObjects(managed.floatObj[@"key1"], @2.2f);
    XCTAssertEqualObjects(optManaged.floatObj[@"key1"], @2.2f);
    XCTAssertEqualObjects(unmanaged.doubleObj[@"key1"], @2.2);
    XCTAssertEqualObjects(optUnmanaged.doubleObj[@"key1"], @2.2);
    XCTAssertEqualObjects(managed.doubleObj[@"key1"], @2.2);
    XCTAssertEqualObjects(optManaged.doubleObj[@"key1"], @2.2);
    XCTAssertEqualObjects(unmanaged.dataObj[@"key1"], data(1));
    XCTAssertEqualObjects(optUnmanaged.dataObj[@"key1"], data(1));
    XCTAssertEqualObjects(managed.dataObj[@"key1"], data(1));
    XCTAssertEqualObjects(optManaged.dataObj[@"key1"], data(1));
    XCTAssertEqualObjects(unmanaged.decimalObj[@"key1"], decimal128(2));
    XCTAssertEqualObjects(optUnmanaged.decimalObj[@"key1"], decimal128(2));
    XCTAssertEqualObjects(managed.decimalObj[@"key1"], decimal128(2));
    XCTAssertEqualObjects(optManaged.decimalObj[@"key1"], decimal128(2));
    XCTAssertEqualObjects(unmanaged.objectIdObj[@"key1"], objectId(1));
    XCTAssertEqualObjects(optUnmanaged.objectIdObj[@"key1"], objectId(1));
    XCTAssertEqualObjects(managed.objectIdObj[@"key1"], objectId(1));
    XCTAssertEqualObjects(optManaged.objectIdObj[@"key1"], objectId(1));
    XCTAssertEqualObjects(unmanaged.uuidObj[@"key1"], uuid(@"00000000-0000-0000-0000-000000000000"));
    XCTAssertEqualObjects(optUnmanaged.uuidObj[@"key1"], uuid(@"00000000-0000-0000-0000-000000000000"));
    XCTAssertEqualObjects(managed.uuidObj[@"key1"], uuid(@"00000000-0000-0000-0000-000000000000"));
    XCTAssertEqualObjects(optManaged.uuidObj[@"key1"], uuid(@"00000000-0000-0000-0000-000000000000"));
    XCTAssertEqualObjects(unmanaged.anyBoolObj[@"key1"], @NO);
    XCTAssertEqualObjects(unmanaged.anyIntObj[@"key1"], @2);
    XCTAssertEqualObjects(unmanaged.anyFloatObj[@"key1"], @2.2f);
    XCTAssertEqualObjects(unmanaged.anyDoubleObj[@"key1"], @2.2);
    XCTAssertEqualObjects(unmanaged.anyStringObj[@"key1"], @"a");
    XCTAssertEqualObjects(unmanaged.anyDataObj[@"key1"], data(1));
    XCTAssertEqualObjects(unmanaged.anyDateObj[@"key1"], date(1));
    XCTAssertEqualObjects(unmanaged.anyDecimalObj[@"key1"], decimal128(2));
    XCTAssertEqualObjects(unmanaged.anyObjectIdObj[@"key1"], objectId(1));
    XCTAssertEqualObjects(unmanaged.anyUUIDObj[@"key1"], uuid(@"00000000-0000-0000-0000-000000000000"));
    XCTAssertEqualObjects(managed.anyBoolObj[@"key1"], @NO);
    XCTAssertEqualObjects(managed.anyIntObj[@"key1"], @2);
    XCTAssertEqualObjects(managed.anyFloatObj[@"key1"], @2.2f);
    XCTAssertEqualObjects(managed.anyDoubleObj[@"key1"], @2.2);
    XCTAssertEqualObjects(managed.anyStringObj[@"key1"], @"a");
    XCTAssertEqualObjects(managed.anyDataObj[@"key1"], data(1));
    XCTAssertEqualObjects(managed.anyDateObj[@"key1"], date(1));
    XCTAssertEqualObjects(managed.anyDecimalObj[@"key1"], decimal128(2));
    XCTAssertEqualObjects(managed.anyObjectIdObj[@"key1"], objectId(1));
    XCTAssertEqualObjects(managed.anyUUIDObj[@"key1"], uuid(@"00000000-0000-0000-0000-000000000000"));

    [optUnmanaged.boolObj setValue:(id)NSNull.null forKey:@"key1"];
    [optManaged.boolObj setValue:(id)NSNull.null forKey:@"key1"];
    [optUnmanaged.intObj setValue:(id)NSNull.null forKey:@"key1"];
    [optManaged.intObj setValue:(id)NSNull.null forKey:@"key1"];
    [optUnmanaged.stringObj setValue:(id)NSNull.null forKey:@"key1"];
    [optManaged.stringObj setValue:(id)NSNull.null forKey:@"key1"];
    [optUnmanaged.dateObj setValue:(id)NSNull.null forKey:@"key1"];
    [optManaged.dateObj setValue:(id)NSNull.null forKey:@"key1"];
    [optUnmanaged.floatObj setValue:(id)NSNull.null forKey:@"key1"];
    [optManaged.floatObj setValue:(id)NSNull.null forKey:@"key1"];
    [optUnmanaged.doubleObj setValue:(id)NSNull.null forKey:@"key1"];
    [optManaged.doubleObj setValue:(id)NSNull.null forKey:@"key1"];
    [optUnmanaged.dataObj setValue:(id)NSNull.null forKey:@"key1"];
    [optManaged.dataObj setValue:(id)NSNull.null forKey:@"key1"];
    [optUnmanaged.decimalObj setValue:(id)NSNull.null forKey:@"key1"];
    [optManaged.decimalObj setValue:(id)NSNull.null forKey:@"key1"];
    [optUnmanaged.objectIdObj setValue:(id)NSNull.null forKey:@"key1"];
    [optManaged.objectIdObj setValue:(id)NSNull.null forKey:@"key1"];
    [optUnmanaged.uuidObj setValue:(id)NSNull.null forKey:@"key1"];
    [optManaged.uuidObj setValue:(id)NSNull.null forKey:@"key1"];
    XCTAssertEqualObjects(optUnmanaged.boolObj[@"key1"], (id)NSNull.null);
    XCTAssertEqualObjects(optManaged.boolObj[@"key1"], (id)NSNull.null);
    XCTAssertEqualObjects(optUnmanaged.intObj[@"key1"], (id)NSNull.null);
    XCTAssertEqualObjects(optManaged.intObj[@"key1"], (id)NSNull.null);
    XCTAssertEqualObjects(optUnmanaged.stringObj[@"key1"], (id)NSNull.null);
    XCTAssertEqualObjects(optManaged.stringObj[@"key1"], (id)NSNull.null);
    XCTAssertEqualObjects(optUnmanaged.dateObj[@"key1"], (id)NSNull.null);
    XCTAssertEqualObjects(optManaged.dateObj[@"key1"], (id)NSNull.null);
    XCTAssertEqualObjects(optUnmanaged.floatObj[@"key1"], (id)NSNull.null);
    XCTAssertEqualObjects(optManaged.floatObj[@"key1"], (id)NSNull.null);
    XCTAssertEqualObjects(optUnmanaged.doubleObj[@"key1"], (id)NSNull.null);
    XCTAssertEqualObjects(optManaged.doubleObj[@"key1"], (id)NSNull.null);
    XCTAssertEqualObjects(optUnmanaged.dataObj[@"key1"], (id)NSNull.null);
    XCTAssertEqualObjects(optManaged.dataObj[@"key1"], (id)NSNull.null);
    XCTAssertEqualObjects(optUnmanaged.decimalObj[@"key1"], (id)NSNull.null);
    XCTAssertEqualObjects(optManaged.decimalObj[@"key1"], (id)NSNull.null);
    XCTAssertEqualObjects(optUnmanaged.objectIdObj[@"key1"], (id)NSNull.null);
    XCTAssertEqualObjects(optManaged.objectIdObj[@"key1"], (id)NSNull.null);
    XCTAssertEqualObjects(optUnmanaged.uuidObj[@"key1"], (id)NSNull.null);
    XCTAssertEqualObjects(optManaged.uuidObj[@"key1"], (id)NSNull.null);
}

- (void)testAssignment {
    unmanaged.boolObj = (id)@{@"key2": @YES};
    XCTAssertEqualObjects(unmanaged.boolObj[@"key2"], @YES);
    optUnmanaged.boolObj = (id)@{@"key2": NSNull.null};
    XCTAssertEqualObjects(optUnmanaged.boolObj[@"key2"], NSNull.null);
    managed.boolObj = (id)@{@"key2": @YES};
    XCTAssertEqualObjects(managed.boolObj[@"key2"], @YES);
    optManaged.boolObj = (id)@{@"key2": NSNull.null};
    XCTAssertEqualObjects(optManaged.boolObj[@"key2"], NSNull.null);
    unmanaged.intObj = (id)@{@"key2": @3};
    XCTAssertEqualObjects(unmanaged.intObj[@"key2"], @3);
    optUnmanaged.intObj = (id)@{@"key2": NSNull.null};
    XCTAssertEqualObjects(optUnmanaged.intObj[@"key2"], NSNull.null);
    managed.intObj = (id)@{@"key2": @3};
    XCTAssertEqualObjects(managed.intObj[@"key2"], @3);
    optManaged.intObj = (id)@{@"key2": NSNull.null};
    XCTAssertEqualObjects(optManaged.intObj[@"key2"], NSNull.null);
    unmanaged.stringObj = (id)@{@"key2": @"foo"};
    XCTAssertEqualObjects(unmanaged.stringObj[@"key2"], @"foo");
    optUnmanaged.stringObj = (id)@{@"key2": NSNull.null};
    XCTAssertEqualObjects(optUnmanaged.stringObj[@"key2"], NSNull.null);
    managed.stringObj = (id)@{@"key2": @"foo"};
    XCTAssertEqualObjects(managed.stringObj[@"key2"], @"foo");
    optManaged.stringObj = (id)@{@"key2": NSNull.null};
    XCTAssertEqualObjects(optManaged.stringObj[@"key2"], NSNull.null);
    unmanaged.dateObj = (id)@{@"key2": date(2)};
    XCTAssertEqualObjects(unmanaged.dateObj[@"key2"], date(2));
    optUnmanaged.dateObj = (id)@{@"key2": NSNull.null};
    XCTAssertEqualObjects(optUnmanaged.dateObj[@"key2"], NSNull.null);
    managed.dateObj = (id)@{@"key2": date(2)};
    XCTAssertEqualObjects(managed.dateObj[@"key2"], date(2));
    optManaged.dateObj = (id)@{@"key2": NSNull.null};
    XCTAssertEqualObjects(optManaged.dateObj[@"key2"], NSNull.null);
    unmanaged.floatObj = (id)@{@"key2": @3.3f};
    XCTAssertEqualObjects(unmanaged.floatObj[@"key2"], @3.3f);
    optUnmanaged.floatObj = (id)@{@"key2": NSNull.null};
    XCTAssertEqualObjects(optUnmanaged.floatObj[@"key2"], NSNull.null);
    managed.floatObj = (id)@{@"key2": @3.3f};
    XCTAssertEqualObjects(managed.floatObj[@"key2"], @3.3f);
    optManaged.floatObj = (id)@{@"key2": NSNull.null};
    XCTAssertEqualObjects(optManaged.floatObj[@"key2"], NSNull.null);
    unmanaged.doubleObj = (id)@{@"key2": @3.3};
    XCTAssertEqualObjects(unmanaged.doubleObj[@"key2"], @3.3);
    optUnmanaged.doubleObj = (id)@{@"key2": NSNull.null};
    XCTAssertEqualObjects(optUnmanaged.doubleObj[@"key2"], NSNull.null);
    managed.doubleObj = (id)@{@"key2": @3.3};
    XCTAssertEqualObjects(managed.doubleObj[@"key2"], @3.3);
    optManaged.doubleObj = (id)@{@"key2": NSNull.null};
    XCTAssertEqualObjects(optManaged.doubleObj[@"key2"], NSNull.null);
    unmanaged.dataObj = (id)@{@"key2": data(2)};
    XCTAssertEqualObjects(unmanaged.dataObj[@"key2"], data(2));
    optUnmanaged.dataObj = (id)@{@"key2": NSNull.null};
    XCTAssertEqualObjects(optUnmanaged.dataObj[@"key2"], NSNull.null);
    managed.dataObj = (id)@{@"key2": data(2)};
    XCTAssertEqualObjects(managed.dataObj[@"key2"], data(2));
    optManaged.dataObj = (id)@{@"key2": NSNull.null};
    XCTAssertEqualObjects(optManaged.dataObj[@"key2"], NSNull.null);
    unmanaged.decimalObj = (id)@{@"key2": decimal128(3)};
    XCTAssertEqualObjects(unmanaged.decimalObj[@"key2"], decimal128(3));
    optUnmanaged.decimalObj = (id)@{@"key2": NSNull.null};
    XCTAssertEqualObjects(optUnmanaged.decimalObj[@"key2"], NSNull.null);
    managed.decimalObj = (id)@{@"key2": decimal128(3)};
    XCTAssertEqualObjects(managed.decimalObj[@"key2"], decimal128(3));
    optManaged.decimalObj = (id)@{@"key2": NSNull.null};
    XCTAssertEqualObjects(optManaged.decimalObj[@"key2"], NSNull.null);
    unmanaged.objectIdObj = (id)@{@"key2": objectId(2)};
    XCTAssertEqualObjects(unmanaged.objectIdObj[@"key2"], objectId(2));
    optUnmanaged.objectIdObj = (id)@{@"key2": NSNull.null};
    XCTAssertEqualObjects(optUnmanaged.objectIdObj[@"key2"], NSNull.null);
    managed.objectIdObj = (id)@{@"key2": objectId(2)};
    XCTAssertEqualObjects(managed.objectIdObj[@"key2"], objectId(2));
    optManaged.objectIdObj = (id)@{@"key2": NSNull.null};
    XCTAssertEqualObjects(optManaged.objectIdObj[@"key2"], NSNull.null);
    unmanaged.uuidObj = (id)@{@"key2": uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")};
    XCTAssertEqualObjects(unmanaged.uuidObj[@"key2"], uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"));
    optUnmanaged.uuidObj = (id)@{@"key2": NSNull.null};
    XCTAssertEqualObjects(optUnmanaged.uuidObj[@"key2"], NSNull.null);
    managed.uuidObj = (id)@{@"key2": uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")};
    XCTAssertEqualObjects(managed.uuidObj[@"key2"], uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"));
    optManaged.uuidObj = (id)@{@"key2": NSNull.null};
    XCTAssertEqualObjects(optManaged.uuidObj[@"key2"], NSNull.null);
    unmanaged.anyBoolObj = (id)@{@"key2": @YES};
    XCTAssertEqualObjects(unmanaged.anyBoolObj[@"key2"], @YES);
    unmanaged.anyIntObj = (id)@{@"key2": @3};
    XCTAssertEqualObjects(unmanaged.anyIntObj[@"key2"], @3);
    unmanaged.anyFloatObj = (id)@{@"key2": @3.3f};
    XCTAssertEqualObjects(unmanaged.anyFloatObj[@"key2"], @3.3f);
    unmanaged.anyDoubleObj = (id)@{@"key2": @3.3};
    XCTAssertEqualObjects(unmanaged.anyDoubleObj[@"key2"], @3.3);
    unmanaged.anyStringObj = (id)@{@"key2": @"b"};
    XCTAssertEqualObjects(unmanaged.anyStringObj[@"key2"], @"b");
    unmanaged.anyDataObj = (id)@{@"key2": data(2)};
    XCTAssertEqualObjects(unmanaged.anyDataObj[@"key2"], data(2));
    unmanaged.anyDateObj = (id)@{@"key2": date(2)};
    XCTAssertEqualObjects(unmanaged.anyDateObj[@"key2"], date(2));
    unmanaged.anyDecimalObj = (id)@{@"key2": decimal128(3)};
    XCTAssertEqualObjects(unmanaged.anyDecimalObj[@"key2"], decimal128(3));
    unmanaged.anyObjectIdObj = (id)@{@"key2": objectId(2)};
    XCTAssertEqualObjects(unmanaged.anyObjectIdObj[@"key2"], objectId(2));
    unmanaged.anyUUIDObj = (id)@{@"key2": uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")};
    XCTAssertEqualObjects(unmanaged.anyUUIDObj[@"key2"], uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"));
    managed.anyBoolObj = (id)@{@"key2": @YES};
    XCTAssertEqualObjects(managed.anyBoolObj[@"key2"], @YES);
    managed.anyIntObj = (id)@{@"key2": @3};
    XCTAssertEqualObjects(managed.anyIntObj[@"key2"], @3);
    managed.anyFloatObj = (id)@{@"key2": @3.3f};
    XCTAssertEqualObjects(managed.anyFloatObj[@"key2"], @3.3f);
    managed.anyDoubleObj = (id)@{@"key2": @3.3};
    XCTAssertEqualObjects(managed.anyDoubleObj[@"key2"], @3.3);
    managed.anyStringObj = (id)@{@"key2": @"b"};
    XCTAssertEqualObjects(managed.anyStringObj[@"key2"], @"b");
    managed.anyDataObj = (id)@{@"key2": data(2)};
    XCTAssertEqualObjects(managed.anyDataObj[@"key2"], data(2));
    managed.anyDateObj = (id)@{@"key2": date(2)};
    XCTAssertEqualObjects(managed.anyDateObj[@"key2"], date(2));
    managed.anyDecimalObj = (id)@{@"key2": decimal128(3)};
    XCTAssertEqualObjects(managed.anyDecimalObj[@"key2"], decimal128(3));
    managed.anyObjectIdObj = (id)@{@"key2": objectId(2)};
    XCTAssertEqualObjects(managed.anyObjectIdObj[@"key2"], objectId(2));
    managed.anyUUIDObj = (id)@{@"key2": uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")};
    XCTAssertEqualObjects(managed.anyUUIDObj[@"key2"], uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"));

    [unmanaged.intObj removeAllObjects];
    unmanaged.intObj = managed.intObj;

    XCTAssertEqual(unmanaged.intObj.count, 1);
    XCTAssertEqualObjects(unmanaged.intObj.allValues, managed.intObj.allValues);

    [managed.intObj removeAllObjects];
    managed.intObj = unmanaged.intObj;

    XCTAssertEqual(managed.intObj.count, 1);
    XCTAssertEqualObjects(managed.intObj.allValues, unmanaged.intObj.allValues);
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
    XCTAssertNil(dictionary[@"0"]);
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
    XCTAssertNil([dictionary valueForKey:@"self"]);
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
    XCTAssertNoThrow(dictionary[@"0"]);
    XCTAssertNoThrow([dictionary count]);

    XCTAssertNoThrow([dictionary sortedResultsUsingKeyPath:@"self" ascending:YES]);
    XCTAssertNoThrow([dictionary sortedResultsUsingDescriptors:@[[RLMSortDescriptor sortDescriptorWithKeyPath:@"self" ascending:YES]]]);
    XCTAssertNoThrow(dictionary[@"0"]);
    XCTAssertNoThrow([dictionary valueForKey:@"self"]);
    XCTAssertNoThrow({for (__unused id obj in dictionary);});
    
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
    XCTAssertFalse(dictionary.isInvalidated);
    [realm deleteObject:managed];
    XCTAssertTrue(dictionary.isInvalidated);
}

#pragma clang diagnostic ignored "-Warc-retain-cycles"

- (void)testNotificationSentInitially {
    [realm commitWriteTransaction];

    id expectation = [self expectationWithDescription:@""];
    id token = [managed.intObj addNotificationBlock:^(RLMDictionary *dictionary, RLMDictionaryChange *change, NSError *error) {
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
    __block bool second = false;
    __block id expectation = [self expectationWithDescription:@""];
    id token = [managed.intObj addNotificationBlock:^(RLMDictionary *dictionary, RLMDictionaryChange *change, NSError *error) {
        XCTAssertNotNil(dictionary);
        XCTAssertNil(error);
        if (first) {
            XCTAssertNil(change);
        }
        else if (!second) {
            XCTAssertEqualObjects(change.insertions, @[@"testKey"]);
        } else {
            XCTAssertEqualObjects(change.deletions, @[@"testKey"]);
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
#pragma mark - Queries

#define RLMAssertCount(cls, expectedCount, ...) \
    XCTAssertEqual(expectedCount, ([cls objectsInRealm:realm where:__VA_ARGS__].count))

- (void)createObject {
    id boolObj = @{@"key1": @NO};
    id intObj = @{@"key1": @2};
    id stringObj = @{@"key1": @"bar"};
    id dateObj = @{@"key1": date(1)};
    id anyBoolObj = @{@"key1": @NO};
    id anyIntObj = @{@"key1": @2};
    id anyFloatObj = @{@"key1": @2.2f};
    id anyDoubleObj = @{@"key1": @2.2};
    id anyStringObj = @{@"key1": @"a"};
    id anyDataObj = @{@"key1": data(1)};
    id anyDateObj = @{@"key1": date(1)};
    id anyDecimalObj = @{@"key1": decimal128(2)};
    id anyUUIDObj = @{@"key1": uuid(@"00000000-0000-0000-0000-000000000000")};
    
    id obj = [AllPrimitiveDictionaries createInRealm:realm withValue: @{
        @"boolObj": boolObj,
        @"intObj": intObj,
        @"stringObj": stringObj,
        @"dateObj": dateObj,
        @"anyBoolObj": anyBoolObj,
        @"anyIntObj": anyIntObj,
        @"anyFloatObj": anyFloatObj,
        @"anyDoubleObj": anyDoubleObj,
        @"anyStringObj": anyStringObj,
        @"anyDataObj": anyDataObj,
        @"anyDateObj": anyDateObj,
        @"anyDecimalObj": anyDecimalObj,
        @"anyUUIDObj": anyUUIDObj,
    }];
    [LinkToAllPrimitiveDictionaries createInRealm:realm withValue:@[obj]];
    obj = [AllOptionalPrimitiveDictionaries createInRealm:realm withValue:@{
        @"boolObj": boolObj,
        @"intObj": intObj,
        @"stringObj": stringObj,
        @"dateObj": dateObj,
    }];
    [LinkToAllOptionalPrimitiveDictionaries createInRealm:realm withValue:@[obj]];
}

- (void)testQueryBasicOperators {
    [realm deleteAllObjects];

    RLMAssertCount(AllPrimitiveDictionaries, 0, @"ANY boolObj = %@", @NO);
    RLMAssertCount(AllOptionalPrimitiveDictionaries, 0, @"ANY boolObj = %@", @NO);
    RLMAssertCount(AllPrimitiveDictionaries, 0, @"ANY intObj = %@", @2);
    RLMAssertCount(AllOptionalPrimitiveDictionaries, 0, @"ANY intObj = %@", @2);
    RLMAssertCount(AllPrimitiveDictionaries, 0, @"ANY stringObj = %@", @"bar");
    RLMAssertCount(AllOptionalPrimitiveDictionaries, 0, @"ANY stringObj = %@", @"bar");
    RLMAssertCount(AllPrimitiveDictionaries, 0, @"ANY dateObj = %@", date(1));
    RLMAssertCount(AllOptionalPrimitiveDictionaries, 0, @"ANY dateObj = %@", date(1));
    RLMAssertCount(AllPrimitiveDictionaries, 0, @"ANY anyBoolObj = %@", @NO);
    RLMAssertCount(AllPrimitiveDictionaries, 0, @"ANY anyIntObj = %@", @2);
    RLMAssertCount(AllPrimitiveDictionaries, 0, @"ANY anyFloatObj = %@", @2.2f);
    RLMAssertCount(AllPrimitiveDictionaries, 0, @"ANY anyDoubleObj = %@", @2.2);
    RLMAssertCount(AllPrimitiveDictionaries, 0, @"ANY anyStringObj = %@", @"a");
    RLMAssertCount(AllPrimitiveDictionaries, 0, @"ANY anyDataObj = %@", data(1));
    RLMAssertCount(AllPrimitiveDictionaries, 0, @"ANY anyDateObj = %@", date(1));
    RLMAssertCount(AllPrimitiveDictionaries, 0, @"ANY anyDecimalObj = %@", decimal128(2));
    RLMAssertCount(AllPrimitiveDictionaries, 0, @"ANY anyUUIDObj = %@", uuid(@"00000000-0000-0000-0000-000000000000"));
    RLMAssertCount(AllPrimitiveDictionaries, 0, @"ANY boolObj != %@", @NO);
    RLMAssertCount(AllOptionalPrimitiveDictionaries, 0, @"ANY boolObj != %@", @NO);
    RLMAssertCount(AllPrimitiveDictionaries, 0, @"ANY intObj != %@", @2);
    RLMAssertCount(AllOptionalPrimitiveDictionaries, 0, @"ANY intObj != %@", @2);
    RLMAssertCount(AllPrimitiveDictionaries, 0, @"ANY stringObj != %@", @"bar");
    RLMAssertCount(AllOptionalPrimitiveDictionaries, 0, @"ANY stringObj != %@", @"bar");
    RLMAssertCount(AllPrimitiveDictionaries, 0, @"ANY dateObj != %@", date(1));
    RLMAssertCount(AllOptionalPrimitiveDictionaries, 0, @"ANY dateObj != %@", date(1));
    RLMAssertCount(AllPrimitiveDictionaries, 0, @"ANY anyBoolObj != %@", @NO);
    RLMAssertCount(AllPrimitiveDictionaries, 0, @"ANY anyIntObj != %@", @2);
    RLMAssertCount(AllPrimitiveDictionaries, 0, @"ANY anyFloatObj != %@", @2.2f);
    RLMAssertCount(AllPrimitiveDictionaries, 0, @"ANY anyDoubleObj != %@", @2.2);
    RLMAssertCount(AllPrimitiveDictionaries, 0, @"ANY anyStringObj != %@", @"a");
    RLMAssertCount(AllPrimitiveDictionaries, 0, @"ANY anyDataObj != %@", data(1));
    RLMAssertCount(AllPrimitiveDictionaries, 0, @"ANY anyDateObj != %@", date(1));
    RLMAssertCount(AllPrimitiveDictionaries, 0, @"ANY anyDecimalObj != %@", decimal128(2));
    RLMAssertCount(AllPrimitiveDictionaries, 0, @"ANY anyUUIDObj != %@", uuid(@"00000000-0000-0000-0000-000000000000"));
    RLMAssertCount(AllPrimitiveDictionaries, 0, @"ANY intObj > %@", @2);
    RLMAssertCount(AllOptionalPrimitiveDictionaries, 0, @"ANY intObj > %@", @2);
    RLMAssertCount(AllPrimitiveDictionaries, 0, @"ANY dateObj > %@", date(1));
    RLMAssertCount(AllOptionalPrimitiveDictionaries, 0, @"ANY dateObj > %@", date(1));
    RLMAssertCount(AllPrimitiveDictionaries, 0, @"ANY anyFloatObj > %@", @2.2f);
    RLMAssertCount(AllPrimitiveDictionaries, 0, @"ANY anyDoubleObj > %@", @2.2);
    RLMAssertCount(AllPrimitiveDictionaries, 0, @"ANY anyDecimalObj > %@", decimal128(2));
    RLMAssertCount(AllPrimitiveDictionaries, 0, @"ANY intObj >= %@", @2);
    RLMAssertCount(AllOptionalPrimitiveDictionaries, 0, @"ANY intObj >= %@", @2);
    RLMAssertCount(AllPrimitiveDictionaries, 0, @"ANY dateObj >= %@", date(1));
    RLMAssertCount(AllOptionalPrimitiveDictionaries, 0, @"ANY dateObj >= %@", date(1));
    RLMAssertCount(AllPrimitiveDictionaries, 0, @"ANY anyFloatObj >= %@", @2.2f);
    RLMAssertCount(AllPrimitiveDictionaries, 0, @"ANY anyDoubleObj >= %@", @2.2);
    RLMAssertCount(AllPrimitiveDictionaries, 0, @"ANY anyDecimalObj >= %@", decimal128(2));
    RLMAssertCount(AllPrimitiveDictionaries, 0, @"ANY intObj < %@", @2);
    RLMAssertCount(AllOptionalPrimitiveDictionaries, 0, @"ANY intObj < %@", @2);
    RLMAssertCount(AllPrimitiveDictionaries, 0, @"ANY dateObj < %@", date(1));
    RLMAssertCount(AllOptionalPrimitiveDictionaries, 0, @"ANY dateObj < %@", date(1));
    RLMAssertCount(AllPrimitiveDictionaries, 0, @"ANY anyFloatObj < %@", @2.2f);
    RLMAssertCount(AllPrimitiveDictionaries, 0, @"ANY anyDoubleObj < %@", @2.2);
    RLMAssertCount(AllPrimitiveDictionaries, 0, @"ANY anyDecimalObj < %@", decimal128(2));
    RLMAssertCount(AllPrimitiveDictionaries, 0, @"ANY intObj <= %@", @2);
    RLMAssertCount(AllOptionalPrimitiveDictionaries, 0, @"ANY intObj <= %@", @2);
    RLMAssertCount(AllPrimitiveDictionaries, 0, @"ANY dateObj <= %@", date(1));
    RLMAssertCount(AllOptionalPrimitiveDictionaries, 0, @"ANY dateObj <= %@", date(1));
    RLMAssertCount(AllPrimitiveDictionaries, 0, @"ANY anyFloatObj <= %@", @2.2f);
    RLMAssertCount(AllPrimitiveDictionaries, 0, @"ANY anyDoubleObj <= %@", @2.2);
    RLMAssertCount(AllPrimitiveDictionaries, 0, @"ANY anyDecimalObj <= %@", decimal128(2));

    [self createObject];

    RLMAssertCount(AllPrimitiveDictionaries, 0, @"ANY boolObj = %@", @YES);
    RLMAssertCount(AllOptionalPrimitiveDictionaries, 0, @"ANY boolObj = %@", NSNull.null);
    RLMAssertCount(AllPrimitiveDictionaries, 0, @"ANY intObj = %@", @3);
    RLMAssertCount(AllOptionalPrimitiveDictionaries, 0, @"ANY intObj = %@", NSNull.null);
    RLMAssertCount(AllPrimitiveDictionaries, 0, @"ANY stringObj = %@", @"foo");
    RLMAssertCount(AllOptionalPrimitiveDictionaries, 0, @"ANY stringObj = %@", NSNull.null);
    RLMAssertCount(AllPrimitiveDictionaries, 0, @"ANY dateObj = %@", date(2));
    RLMAssertCount(AllOptionalPrimitiveDictionaries, 0, @"ANY dateObj = %@", NSNull.null);
    RLMAssertCount(AllPrimitiveDictionaries, 0, @"ANY anyBoolObj = %@", @YES);
    RLMAssertCount(AllPrimitiveDictionaries, 0, @"ANY anyIntObj = %@", @3);
    RLMAssertCount(AllPrimitiveDictionaries, 0, @"ANY anyFloatObj = %@", @3.3f);
    RLMAssertCount(AllPrimitiveDictionaries, 0, @"ANY anyDoubleObj = %@", @3.3);
    RLMAssertCount(AllPrimitiveDictionaries, 0, @"ANY anyStringObj = %@", @"b");
    RLMAssertCount(AllPrimitiveDictionaries, 0, @"ANY anyDataObj = %@", data(2));
    RLMAssertCount(AllPrimitiveDictionaries, 0, @"ANY anyDateObj = %@", date(2));
    RLMAssertCount(AllPrimitiveDictionaries, 0, @"ANY anyDecimalObj = %@", decimal128(3));
    RLMAssertCount(AllPrimitiveDictionaries, 0, @"ANY anyUUIDObj = %@", uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"));
    RLMAssertCount(AllPrimitiveDictionaries, 1, @"ANY boolObj = %@", @NO);
    RLMAssertCount(AllOptionalPrimitiveDictionaries, 1, @"ANY boolObj = %@", @NO);
    RLMAssertCount(AllPrimitiveDictionaries, 1, @"ANY intObj = %@", @2);
    RLMAssertCount(AllOptionalPrimitiveDictionaries, 1, @"ANY intObj = %@", @2);
    RLMAssertCount(AllPrimitiveDictionaries, 1, @"ANY stringObj = %@", @"bar");
    RLMAssertCount(AllOptionalPrimitiveDictionaries, 1, @"ANY stringObj = %@", @"bar");
    RLMAssertCount(AllPrimitiveDictionaries, 1, @"ANY dateObj = %@", date(1));
    RLMAssertCount(AllOptionalPrimitiveDictionaries, 1, @"ANY dateObj = %@", date(1));
    RLMAssertCount(AllPrimitiveDictionaries, 1, @"ANY anyBoolObj = %@", @NO);
    RLMAssertCount(AllPrimitiveDictionaries, 1, @"ANY anyIntObj = %@", @2);
    RLMAssertCount(AllPrimitiveDictionaries, 1, @"ANY anyFloatObj = %@", @2.2f);
    RLMAssertCount(AllPrimitiveDictionaries, 1, @"ANY anyDoubleObj = %@", @2.2);
    RLMAssertCount(AllPrimitiveDictionaries, 1, @"ANY anyStringObj = %@", @"a");
    RLMAssertCount(AllPrimitiveDictionaries, 1, @"ANY anyDataObj = %@", data(1));
    RLMAssertCount(AllPrimitiveDictionaries, 1, @"ANY anyDateObj = %@", date(1));
    RLMAssertCount(AllPrimitiveDictionaries, 1, @"ANY anyDecimalObj = %@", decimal128(2));
    RLMAssertCount(AllPrimitiveDictionaries, 1, @"ANY anyUUIDObj = %@", uuid(@"00000000-0000-0000-0000-000000000000"));
    RLMAssertCount(AllPrimitiveDictionaries, 0, @"ANY boolObj != %@", @NO);
    RLMAssertCount(AllOptionalPrimitiveDictionaries, 0, @"ANY boolObj != %@", @NO);
    RLMAssertCount(AllPrimitiveDictionaries, 0, @"ANY intObj != %@", @2);
    RLMAssertCount(AllOptionalPrimitiveDictionaries, 0, @"ANY intObj != %@", @2);
    RLMAssertCount(AllPrimitiveDictionaries, 0, @"ANY stringObj != %@", @"bar");
    RLMAssertCount(AllOptionalPrimitiveDictionaries, 0, @"ANY stringObj != %@", @"bar");
    RLMAssertCount(AllPrimitiveDictionaries, 0, @"ANY dateObj != %@", date(1));
    RLMAssertCount(AllOptionalPrimitiveDictionaries, 0, @"ANY dateObj != %@", date(1));
    RLMAssertCount(AllPrimitiveDictionaries, 0, @"ANY anyBoolObj != %@", @NO);
    RLMAssertCount(AllPrimitiveDictionaries, 0, @"ANY anyIntObj != %@", @2);
    RLMAssertCount(AllPrimitiveDictionaries, 0, @"ANY anyFloatObj != %@", @2.2f);
    RLMAssertCount(AllPrimitiveDictionaries, 0, @"ANY anyDoubleObj != %@", @2.2);
    RLMAssertCount(AllPrimitiveDictionaries, 0, @"ANY anyStringObj != %@", @"a");
    RLMAssertCount(AllPrimitiveDictionaries, 0, @"ANY anyDataObj != %@", data(1));
    RLMAssertCount(AllPrimitiveDictionaries, 0, @"ANY anyDateObj != %@", date(1));
    RLMAssertCount(AllPrimitiveDictionaries, 0, @"ANY anyDecimalObj != %@", decimal128(2));
    RLMAssertCount(AllPrimitiveDictionaries, 0, @"ANY anyUUIDObj != %@", uuid(@"00000000-0000-0000-0000-000000000000"));
    RLMAssertCount(AllPrimitiveDictionaries, 1, @"ANY boolObj != %@", @YES);
    RLMAssertCount(AllOptionalPrimitiveDictionaries, 1, @"ANY boolObj != %@", NSNull.null);
    RLMAssertCount(AllPrimitiveDictionaries, 1, @"ANY intObj != %@", @3);
    RLMAssertCount(AllOptionalPrimitiveDictionaries, 1, @"ANY intObj != %@", NSNull.null);
    RLMAssertCount(AllPrimitiveDictionaries, 1, @"ANY stringObj != %@", @"foo");
    RLMAssertCount(AllOptionalPrimitiveDictionaries, 1, @"ANY stringObj != %@", NSNull.null);
    RLMAssertCount(AllPrimitiveDictionaries, 1, @"ANY dateObj != %@", date(2));
    RLMAssertCount(AllOptionalPrimitiveDictionaries, 1, @"ANY dateObj != %@", NSNull.null);
    RLMAssertCount(AllPrimitiveDictionaries, 1, @"ANY anyBoolObj != %@", @YES);
    RLMAssertCount(AllPrimitiveDictionaries, 1, @"ANY anyIntObj != %@", @3);
    RLMAssertCount(AllPrimitiveDictionaries, 1, @"ANY anyFloatObj != %@", @3.3f);
    RLMAssertCount(AllPrimitiveDictionaries, 1, @"ANY anyDoubleObj != %@", @3.3);
    RLMAssertCount(AllPrimitiveDictionaries, 1, @"ANY anyStringObj != %@", @"b");
    RLMAssertCount(AllPrimitiveDictionaries, 1, @"ANY anyDataObj != %@", data(2));
    RLMAssertCount(AllPrimitiveDictionaries, 1, @"ANY anyDateObj != %@", date(2));
    RLMAssertCount(AllPrimitiveDictionaries, 1, @"ANY anyDecimalObj != %@", decimal128(3));
    RLMAssertCount(AllPrimitiveDictionaries, 1, @"ANY anyUUIDObj != %@", uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"));
    RLMAssertCount(AllPrimitiveDictionaries, 0, @"ANY intObj > %@", @2);
    RLMAssertCount(AllOptionalPrimitiveDictionaries, 0, @"ANY intObj > %@", @2);
    RLMAssertCount(AllPrimitiveDictionaries, 0, @"ANY dateObj > %@", date(1));
    RLMAssertCount(AllOptionalPrimitiveDictionaries, 0, @"ANY dateObj > %@", date(1));
    RLMAssertCount(AllPrimitiveDictionaries, 0, @"ANY anyFloatObj > %@", @2.2f);
    RLMAssertCount(AllPrimitiveDictionaries, 0, @"ANY anyDoubleObj > %@", @2.2);
    RLMAssertCount(AllPrimitiveDictionaries, 0, @"ANY anyDecimalObj > %@", decimal128(2));
    RLMAssertCount(AllPrimitiveDictionaries, 1, @"ANY intObj >= %@", @2);
    RLMAssertCount(AllOptionalPrimitiveDictionaries, 1, @"ANY intObj >= %@", @2);
    RLMAssertCount(AllPrimitiveDictionaries, 1, @"ANY dateObj >= %@", date(1));
    RLMAssertCount(AllOptionalPrimitiveDictionaries, 1, @"ANY dateObj >= %@", date(1));
    RLMAssertCount(AllPrimitiveDictionaries, 1, @"ANY anyFloatObj >= %@", @2.2f);
    RLMAssertCount(AllPrimitiveDictionaries, 1, @"ANY anyDoubleObj >= %@", @2.2);
    RLMAssertCount(AllPrimitiveDictionaries, 1, @"ANY anyDecimalObj >= %@", decimal128(2));
    RLMAssertCount(AllPrimitiveDictionaries, 0, @"ANY intObj < %@", @2);
    RLMAssertCount(AllOptionalPrimitiveDictionaries, 0, @"ANY intObj < %@", @2);
    RLMAssertCount(AllPrimitiveDictionaries, 0, @"ANY dateObj < %@", date(1));
    RLMAssertCount(AllOptionalPrimitiveDictionaries, 0, @"ANY dateObj < %@", date(1));
    RLMAssertCount(AllPrimitiveDictionaries, 0, @"ANY anyFloatObj < %@", @2.2f);
    RLMAssertCount(AllPrimitiveDictionaries, 0, @"ANY anyDoubleObj < %@", @2.2);
    RLMAssertCount(AllPrimitiveDictionaries, 0, @"ANY anyDecimalObj < %@", decimal128(2));
    RLMAssertCount(AllPrimitiveDictionaries, 1, @"ANY intObj < %@", @3);
    RLMAssertCount(AllPrimitiveDictionaries, 1, @"ANY dateObj < %@", date(2));
    RLMAssertCount(AllPrimitiveDictionaries, 1, @"ANY anyFloatObj < %@", @3.3f);
    RLMAssertCount(AllPrimitiveDictionaries, 1, @"ANY anyDoubleObj < %@", @3.3);
    RLMAssertCount(AllPrimitiveDictionaries, 1, @"ANY anyDecimalObj < %@", decimal128(3));
    RLMAssertCount(AllOptionalPrimitiveDictionaries, 0, @"ANY intObj < %@", NSNull.null);
    RLMAssertCount(AllOptionalPrimitiveDictionaries, 0, @"ANY dateObj < %@", NSNull.null);
    RLMAssertCount(AllPrimitiveDictionaries, 1, @"ANY intObj <= %@", @2);
    RLMAssertCount(AllOptionalPrimitiveDictionaries, 1, @"ANY intObj <= %@", @2);
    RLMAssertCount(AllPrimitiveDictionaries, 1, @"ANY dateObj <= %@", date(1));
    RLMAssertCount(AllOptionalPrimitiveDictionaries, 1, @"ANY dateObj <= %@", date(1));
    RLMAssertCount(AllPrimitiveDictionaries, 1, @"ANY anyFloatObj <= %@", @2.2f);
    RLMAssertCount(AllPrimitiveDictionaries, 1, @"ANY anyDoubleObj <= %@", @2.2);
    RLMAssertCount(AllPrimitiveDictionaries, 1, @"ANY anyDecimalObj <= %@", decimal128(2));

    RLMAssertThrowsWithReason(([AllPrimitiveDictionaries objectsInRealm:realm where:@"ANY boolObj > %@", @NO]),
                              @"Operator '>' not supported for type 'bool'");
    RLMAssertThrowsWithReason(([AllOptionalPrimitiveDictionaries objectsInRealm:realm where:@"ANY boolObj > %@", @NO]),
                              @"Operator '>' not supported for type 'bool'");
    RLMAssertThrowsWithReason(([AllPrimitiveDictionaries objectsInRealm:realm where:@"ANY stringObj > %@", @"bar"]),
                              @"Operator '>' not supported for string queries on Dictionary.");
    RLMAssertThrowsWithReason(([AllOptionalPrimitiveDictionaries objectsInRealm:realm where:@"ANY stringObj > %@", @"bar"]),
                              @"Operator '>' not supported for string queries on Dictionary.");
    RLMAssertThrowsWithReason(([AllPrimitiveDictionaries objectsInRealm:realm where:@"ANY anyStringObj > %@", @"a"]),
                              @"Operator '>' not supported for string queries on Dictionary.");
}

- (void)testQueryBetween {
    [realm deleteAllObjects];

    RLMAssertThrowsWithReason(([AllPrimitiveDictionaries objectsInRealm:realm where:@"ANY boolObj BETWEEN %@", @[@NO, @YES]]),
                              @"Operator 'BETWEEN' not supported for type 'bool'");
    RLMAssertThrowsWithReason(([AllOptionalPrimitiveDictionaries objectsInRealm:realm where:@"ANY boolObj BETWEEN %@", @[@NO, NSNull.null]]),
                              @"Operator 'BETWEEN' not supported for type 'bool'");
    RLMAssertThrowsWithReason(([AllPrimitiveDictionaries objectsInRealm:realm where:@"ANY stringObj BETWEEN %@", @[@"bar", @"foo"]]),
                              @"Operator 'BETWEEN' not supported for type 'string'");
    RLMAssertThrowsWithReason(([AllOptionalPrimitiveDictionaries objectsInRealm:realm where:@"ANY stringObj BETWEEN %@", @[@"bar", NSNull.null]]),
                              @"Operator 'BETWEEN' not supported for type 'string'");

    RLMAssertCount(AllPrimitiveDictionaries, 0, @"ANY intObj BETWEEN %@", @[@2, @3]);
    RLMAssertCount(AllOptionalPrimitiveDictionaries, 0, @"ANY intObj BETWEEN %@", @[@2, NSNull.null]);
    RLMAssertCount(AllPrimitiveDictionaries, 0, @"ANY dateObj BETWEEN %@", @[date(1), date(2)]);
    RLMAssertCount(AllOptionalPrimitiveDictionaries, 0, @"ANY dateObj BETWEEN %@", @[date(1), NSNull.null]);
    RLMAssertCount(AllPrimitiveDictionaries, 0, @"ANY anyFloatObj BETWEEN %@", @[@2.2f, @3.3f]);
    RLMAssertCount(AllPrimitiveDictionaries, 0, @"ANY anyDoubleObj BETWEEN %@", @[@2.2, @3.3]);
    RLMAssertCount(AllPrimitiveDictionaries, 0, @"ANY anyDecimalObj BETWEEN %@", @[decimal128(2), decimal128(3)]);

    [self createObject];

    RLMAssertCount(AllPrimitiveDictionaries, 1, @"ANY intObj BETWEEN %@", @[@2, @2]);
    RLMAssertCount(AllPrimitiveDictionaries, 1, @"ANY dateObj BETWEEN %@", @[date(1), date(1)]);
    RLMAssertCount(AllPrimitiveDictionaries, 1, @"ANY anyFloatObj BETWEEN %@", @[@2.2f, @2.2f]);
    RLMAssertCount(AllPrimitiveDictionaries, 1, @"ANY anyDoubleObj BETWEEN %@", @[@2.2, @2.2]);
    RLMAssertCount(AllPrimitiveDictionaries, 1, @"ANY anyDecimalObj BETWEEN %@", @[decimal128(2), decimal128(2)]);
    RLMAssertCount(AllPrimitiveDictionaries, 1, @"ANY intObj BETWEEN %@", @[@2, @3]);
    RLMAssertCount(AllPrimitiveDictionaries, 1, @"ANY dateObj BETWEEN %@", @[date(1), date(2)]);
    RLMAssertCount(AllPrimitiveDictionaries, 1, @"ANY anyFloatObj BETWEEN %@", @[@2.2f, @3.3f]);
    RLMAssertCount(AllPrimitiveDictionaries, 1, @"ANY anyDoubleObj BETWEEN %@", @[@2.2, @3.3]);
    RLMAssertCount(AllPrimitiveDictionaries, 1, @"ANY anyDecimalObj BETWEEN %@", @[decimal128(2), decimal128(3)]);
    RLMAssertCount(AllPrimitiveDictionaries, 0, @"ANY intObj BETWEEN %@", @[@3, @3]);
    RLMAssertCount(AllPrimitiveDictionaries, 0, @"ANY dateObj BETWEEN %@", @[date(2), date(2)]);
    RLMAssertCount(AllPrimitiveDictionaries, 0, @"ANY anyFloatObj BETWEEN %@", @[@3.3f, @3.3f]);
    RLMAssertCount(AllPrimitiveDictionaries, 0, @"ANY anyDoubleObj BETWEEN %@", @[@3.3, @3.3]);
    RLMAssertCount(AllPrimitiveDictionaries, 0, @"ANY anyDecimalObj BETWEEN %@", @[decimal128(3), decimal128(3)]);
    RLMAssertCount(AllOptionalPrimitiveDictionaries, 1, @"ANY intObj BETWEEN %@", @[@2, @2]);
    RLMAssertCount(AllOptionalPrimitiveDictionaries, 1, @"ANY dateObj BETWEEN %@", @[date(1), date(1)]);
    RLMAssertCount(AllOptionalPrimitiveDictionaries, 0, @"ANY intObj BETWEEN %@", @[@2, NSNull.null]);
    RLMAssertCount(AllOptionalPrimitiveDictionaries, 0, @"ANY dateObj BETWEEN %@", @[date(1), NSNull.null]);
    RLMAssertCount(AllOptionalPrimitiveDictionaries, 0, @"ANY intObj BETWEEN %@", @[NSNull.null, NSNull.null]);
    RLMAssertCount(AllOptionalPrimitiveDictionaries, 0, @"ANY dateObj BETWEEN %@", @[NSNull.null, NSNull.null]);
}

- (void)testQueryIn {
    [realm deleteAllObjects];

    RLMAssertCount(AllPrimitiveDictionaries, 0, @"ANY boolObj IN %@", @[@NO, @YES]);
    RLMAssertCount(AllOptionalPrimitiveDictionaries, 0, @"ANY boolObj IN %@", @[@NO, NSNull.null]);
    RLMAssertCount(AllPrimitiveDictionaries, 0, @"ANY intObj IN %@", @[@2, @3]);
    RLMAssertCount(AllOptionalPrimitiveDictionaries, 0, @"ANY intObj IN %@", @[@2, NSNull.null]);
    RLMAssertCount(AllPrimitiveDictionaries, 0, @"ANY stringObj IN %@", @[@"bar", @"foo"]);
    RLMAssertCount(AllOptionalPrimitiveDictionaries, 0, @"ANY stringObj IN %@", @[@"bar", NSNull.null]);
    RLMAssertCount(AllPrimitiveDictionaries, 0, @"ANY dateObj IN %@", @[date(1), date(2)]);
    RLMAssertCount(AllOptionalPrimitiveDictionaries, 0, @"ANY dateObj IN %@", @[date(1), NSNull.null]);
    RLMAssertCount(AllPrimitiveDictionaries, 0, @"ANY anyBoolObj IN %@", @[@NO, @YES]);
    RLMAssertCount(AllPrimitiveDictionaries, 0, @"ANY anyIntObj IN %@", @[@2, @3]);
    RLMAssertCount(AllPrimitiveDictionaries, 0, @"ANY anyFloatObj IN %@", @[@2.2f, @3.3f]);
    RLMAssertCount(AllPrimitiveDictionaries, 0, @"ANY anyDoubleObj IN %@", @[@2.2, @3.3]);
    RLMAssertCount(AllPrimitiveDictionaries, 0, @"ANY anyStringObj IN %@", @[@"a", @"b"]);
    RLMAssertCount(AllPrimitiveDictionaries, 0, @"ANY anyDataObj IN %@", @[data(1), data(2)]);
    RLMAssertCount(AllPrimitiveDictionaries, 0, @"ANY anyDateObj IN %@", @[date(1), date(2)]);
    RLMAssertCount(AllPrimitiveDictionaries, 0, @"ANY anyDecimalObj IN %@", @[decimal128(2), decimal128(3)]);
    RLMAssertCount(AllPrimitiveDictionaries, 0, @"ANY anyUUIDObj IN %@", @[uuid(@"00000000-0000-0000-0000-000000000000"), uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")]);

    [self createObject];

    RLMAssertCount(AllPrimitiveDictionaries, 0, @"ANY boolObj IN %@", @[@YES]);
    RLMAssertCount(AllOptionalPrimitiveDictionaries, 0, @"ANY boolObj IN %@", @[NSNull.null]);
    RLMAssertCount(AllPrimitiveDictionaries, 0, @"ANY intObj IN %@", @[@3]);
    RLMAssertCount(AllOptionalPrimitiveDictionaries, 0, @"ANY intObj IN %@", @[NSNull.null]);
    RLMAssertCount(AllPrimitiveDictionaries, 0, @"ANY stringObj IN %@", @[@"foo"]);
    RLMAssertCount(AllOptionalPrimitiveDictionaries, 0, @"ANY stringObj IN %@", @[NSNull.null]);
    RLMAssertCount(AllPrimitiveDictionaries, 0, @"ANY dateObj IN %@", @[date(2)]);
    RLMAssertCount(AllOptionalPrimitiveDictionaries, 0, @"ANY dateObj IN %@", @[NSNull.null]);
    RLMAssertCount(AllPrimitiveDictionaries, 0, @"ANY anyBoolObj IN %@", @[@YES]);
    RLMAssertCount(AllPrimitiveDictionaries, 0, @"ANY anyIntObj IN %@", @[@3]);
    RLMAssertCount(AllPrimitiveDictionaries, 0, @"ANY anyFloatObj IN %@", @[@3.3f]);
    RLMAssertCount(AllPrimitiveDictionaries, 0, @"ANY anyDoubleObj IN %@", @[@3.3]);
    RLMAssertCount(AllPrimitiveDictionaries, 0, @"ANY anyStringObj IN %@", @[@"b"]);
    RLMAssertCount(AllPrimitiveDictionaries, 0, @"ANY anyDataObj IN %@", @[data(2)]);
    RLMAssertCount(AllPrimitiveDictionaries, 0, @"ANY anyDateObj IN %@", @[date(2)]);
    RLMAssertCount(AllPrimitiveDictionaries, 0, @"ANY anyDecimalObj IN %@", @[decimal128(3)]);
    RLMAssertCount(AllPrimitiveDictionaries, 0, @"ANY anyUUIDObj IN %@", @[uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")]);
    RLMAssertCount(AllPrimitiveDictionaries, 1, @"ANY boolObj IN %@", @[@NO, @YES]);
    RLMAssertCount(AllOptionalPrimitiveDictionaries, 1, @"ANY boolObj IN %@", @[@NO, NSNull.null]);
    RLMAssertCount(AllPrimitiveDictionaries, 1, @"ANY intObj IN %@", @[@2, @3]);
    RLMAssertCount(AllOptionalPrimitiveDictionaries, 1, @"ANY intObj IN %@", @[@2, NSNull.null]);
    RLMAssertCount(AllPrimitiveDictionaries, 1, @"ANY stringObj IN %@", @[@"bar", @"foo"]);
    RLMAssertCount(AllOptionalPrimitiveDictionaries, 1, @"ANY stringObj IN %@", @[@"bar", NSNull.null]);
    RLMAssertCount(AllPrimitiveDictionaries, 1, @"ANY dateObj IN %@", @[date(1), date(2)]);
    RLMAssertCount(AllOptionalPrimitiveDictionaries, 1, @"ANY dateObj IN %@", @[date(1), NSNull.null]);
    RLMAssertCount(AllPrimitiveDictionaries, 1, @"ANY anyBoolObj IN %@", @[@NO, @YES]);
    RLMAssertCount(AllPrimitiveDictionaries, 1, @"ANY anyIntObj IN %@", @[@2, @3]);
    RLMAssertCount(AllPrimitiveDictionaries, 1, @"ANY anyFloatObj IN %@", @[@2.2f, @3.3f]);
    RLMAssertCount(AllPrimitiveDictionaries, 1, @"ANY anyDoubleObj IN %@", @[@2.2, @3.3]);
    RLMAssertCount(AllPrimitiveDictionaries, 1, @"ANY anyStringObj IN %@", @[@"a", @"b"]);
    RLMAssertCount(AllPrimitiveDictionaries, 1, @"ANY anyDataObj IN %@", @[data(1), data(2)]);
    RLMAssertCount(AllPrimitiveDictionaries, 1, @"ANY anyDateObj IN %@", @[date(1), date(2)]);
    RLMAssertCount(AllPrimitiveDictionaries, 1, @"ANY anyDecimalObj IN %@", @[decimal128(2), decimal128(3)]);
    RLMAssertCount(AllPrimitiveDictionaries, 1, @"ANY anyUUIDObj IN %@", @[uuid(@"00000000-0000-0000-0000-000000000000"), uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")]);
}

- (void)testQueryCount {
    [realm deleteAllObjects];

    [AllPrimitiveDictionaries createInRealm:realm withValue:@{
        @"boolObj": @{ @"key1": @NO, @"key2": @YES },
        @"intObj": @{ @"key1": @2, @"key2": @3 },
        @"stringObj": @{ @"key1": @"bar", @"key2": @"foo" },
        @"dateObj": @{ @"key1": date(1), @"key2": date(2) },
        @"anyBoolObj": @{ @"key1": @NO, @"key2": @YES },
        @"anyIntObj": @{ @"key1": @2, @"key2": @3 },
        @"anyFloatObj": @{ @"key1": @2.2f, @"key2": @3.3f },
        @"anyDoubleObj": @{ @"key1": @2.2, @"key2": @3.3 },
        @"anyStringObj": @{ @"key1": @"a", @"key2": @"b" },
        @"anyDataObj": @{ @"key1": data(1), @"key2": data(2) },
        @"anyDateObj": @{ @"key1": date(1), @"key2": date(2) },
        @"anyDecimalObj": @{ @"key1": decimal128(2), @"key2": decimal128(3) },
        @"anyUUIDObj": @{ @"key1": uuid(@"00000000-0000-0000-0000-000000000000"), @"key2": uuid(@"137DECC8-B300-4954-A233-F89909F4FD89") },
    }];
    [AllOptionalPrimitiveDictionaries createInRealm:realm withValue:@{
        @"boolObj": @{ @"key1": @NO, @"key2": NSNull.null },
        @"intObj": @{ @"key1": @2, @"key2": NSNull.null },
        @"stringObj": @{ @"key1": @"bar", @"key2": NSNull.null },
        @"dateObj": @{ @"key1": date(1), @"key2": NSNull.null },
    }];

    RLMAssertCount(AllPrimitiveDictionaries, 1U, @"boolObj.@count == %@", @(2));
    RLMAssertCount(AllOptionalPrimitiveDictionaries, 1U, @"boolObj.@count == %@", @(2));
    RLMAssertCount(AllPrimitiveDictionaries, 1U, @"intObj.@count == %@", @(2));
    RLMAssertCount(AllOptionalPrimitiveDictionaries, 1U, @"intObj.@count == %@", @(2));
    RLMAssertCount(AllPrimitiveDictionaries, 1U, @"stringObj.@count == %@", @(2));
    RLMAssertCount(AllOptionalPrimitiveDictionaries, 1U, @"stringObj.@count == %@", @(2));
    RLMAssertCount(AllPrimitiveDictionaries, 1U, @"dateObj.@count == %@", @(2));
    RLMAssertCount(AllOptionalPrimitiveDictionaries, 1U, @"dateObj.@count == %@", @(2));
    RLMAssertCount(AllPrimitiveDictionaries, 1U, @"anyBoolObj.@count == %@", @(2));
    RLMAssertCount(AllPrimitiveDictionaries, 1U, @"anyIntObj.@count == %@", @(2));
    RLMAssertCount(AllPrimitiveDictionaries, 1U, @"anyFloatObj.@count == %@", @(2));
    RLMAssertCount(AllPrimitiveDictionaries, 1U, @"anyDoubleObj.@count == %@", @(2));
    RLMAssertCount(AllPrimitiveDictionaries, 1U, @"anyStringObj.@count == %@", @(2));
    RLMAssertCount(AllPrimitiveDictionaries, 1U, @"anyDataObj.@count == %@", @(2));
    RLMAssertCount(AllPrimitiveDictionaries, 1U, @"anyDateObj.@count == %@", @(2));
    RLMAssertCount(AllPrimitiveDictionaries, 1U, @"anyDecimalObj.@count == %@", @(2));
    RLMAssertCount(AllPrimitiveDictionaries, 1U, @"anyUUIDObj.@count == %@", @(2));
    RLMAssertCount(AllPrimitiveDictionaries, 0U, @"boolObj.@count != %@", @(2));
    RLMAssertCount(AllOptionalPrimitiveDictionaries, 0U, @"boolObj.@count != %@", @(2));
    RLMAssertCount(AllPrimitiveDictionaries, 0U, @"intObj.@count != %@", @(2));
    RLMAssertCount(AllOptionalPrimitiveDictionaries, 0U, @"intObj.@count != %@", @(2));
    RLMAssertCount(AllPrimitiveDictionaries, 0U, @"stringObj.@count != %@", @(2));
    RLMAssertCount(AllOptionalPrimitiveDictionaries, 0U, @"stringObj.@count != %@", @(2));
    RLMAssertCount(AllPrimitiveDictionaries, 0U, @"dateObj.@count != %@", @(2));
    RLMAssertCount(AllOptionalPrimitiveDictionaries, 0U, @"dateObj.@count != %@", @(2));
    RLMAssertCount(AllPrimitiveDictionaries, 0U, @"anyBoolObj.@count != %@", @(2));
    RLMAssertCount(AllPrimitiveDictionaries, 0U, @"anyIntObj.@count != %@", @(2));
    RLMAssertCount(AllPrimitiveDictionaries, 0U, @"anyFloatObj.@count != %@", @(2));
    RLMAssertCount(AllPrimitiveDictionaries, 0U, @"anyDoubleObj.@count != %@", @(2));
    RLMAssertCount(AllPrimitiveDictionaries, 0U, @"anyStringObj.@count != %@", @(2));
    RLMAssertCount(AllPrimitiveDictionaries, 0U, @"anyDataObj.@count != %@", @(2));
    RLMAssertCount(AllPrimitiveDictionaries, 0U, @"anyDateObj.@count != %@", @(2));
    RLMAssertCount(AllPrimitiveDictionaries, 0U, @"anyDecimalObj.@count != %@", @(2));
    RLMAssertCount(AllPrimitiveDictionaries, 0U, @"anyUUIDObj.@count != %@", @(2));
    RLMAssertCount(AllPrimitiveDictionaries, 0, @"boolObj.@count > %@", @(2));
    RLMAssertCount(AllOptionalPrimitiveDictionaries, 0, @"boolObj.@count > %@", @(2));
    RLMAssertCount(AllPrimitiveDictionaries, 0, @"intObj.@count > %@", @(2));
    RLMAssertCount(AllOptionalPrimitiveDictionaries, 0, @"intObj.@count > %@", @(2));
    RLMAssertCount(AllPrimitiveDictionaries, 0, @"stringObj.@count > %@", @(2));
    RLMAssertCount(AllOptionalPrimitiveDictionaries, 0, @"stringObj.@count > %@", @(2));
    RLMAssertCount(AllPrimitiveDictionaries, 0, @"dateObj.@count > %@", @(2));
    RLMAssertCount(AllOptionalPrimitiveDictionaries, 0, @"dateObj.@count > %@", @(2));
    RLMAssertCount(AllPrimitiveDictionaries, 0, @"anyBoolObj.@count > %@", @(2));
    RLMAssertCount(AllPrimitiveDictionaries, 0, @"anyIntObj.@count > %@", @(2));
    RLMAssertCount(AllPrimitiveDictionaries, 0, @"anyFloatObj.@count > %@", @(2));
    RLMAssertCount(AllPrimitiveDictionaries, 0, @"anyDoubleObj.@count > %@", @(2));
    RLMAssertCount(AllPrimitiveDictionaries, 0, @"anyStringObj.@count > %@", @(2));
    RLMAssertCount(AllPrimitiveDictionaries, 0, @"anyDataObj.@count > %@", @(2));
    RLMAssertCount(AllPrimitiveDictionaries, 0, @"anyDateObj.@count > %@", @(2));
    RLMAssertCount(AllPrimitiveDictionaries, 0, @"anyDecimalObj.@count > %@", @(2));
    RLMAssertCount(AllPrimitiveDictionaries, 0, @"anyUUIDObj.@count > %@", @(2));
    RLMAssertCount(AllPrimitiveDictionaries, 1, @"boolObj.@count >= %@", @(2));
    RLMAssertCount(AllOptionalPrimitiveDictionaries, 1, @"boolObj.@count >= %@", @(2));
    RLMAssertCount(AllPrimitiveDictionaries, 1, @"intObj.@count >= %@", @(2));
    RLMAssertCount(AllOptionalPrimitiveDictionaries, 1, @"intObj.@count >= %@", @(2));
    RLMAssertCount(AllPrimitiveDictionaries, 1, @"stringObj.@count >= %@", @(2));
    RLMAssertCount(AllOptionalPrimitiveDictionaries, 1, @"stringObj.@count >= %@", @(2));
    RLMAssertCount(AllPrimitiveDictionaries, 1, @"dateObj.@count >= %@", @(2));
    RLMAssertCount(AllOptionalPrimitiveDictionaries, 1, @"dateObj.@count >= %@", @(2));
    RLMAssertCount(AllPrimitiveDictionaries, 1, @"anyBoolObj.@count >= %@", @(2));
    RLMAssertCount(AllPrimitiveDictionaries, 1, @"anyIntObj.@count >= %@", @(2));
    RLMAssertCount(AllPrimitiveDictionaries, 1, @"anyFloatObj.@count >= %@", @(2));
    RLMAssertCount(AllPrimitiveDictionaries, 1, @"anyDoubleObj.@count >= %@", @(2));
    RLMAssertCount(AllPrimitiveDictionaries, 1, @"anyStringObj.@count >= %@", @(2));
    RLMAssertCount(AllPrimitiveDictionaries, 1, @"anyDataObj.@count >= %@", @(2));
    RLMAssertCount(AllPrimitiveDictionaries, 1, @"anyDateObj.@count >= %@", @(2));
    RLMAssertCount(AllPrimitiveDictionaries, 1, @"anyDecimalObj.@count >= %@", @(2));
    RLMAssertCount(AllPrimitiveDictionaries, 1, @"anyUUIDObj.@count >= %@", @(2));
    RLMAssertCount(AllPrimitiveDictionaries, 0, @"boolObj.@count < %@", @(2));
    RLMAssertCount(AllOptionalPrimitiveDictionaries, 0, @"boolObj.@count < %@", @(2));
    RLMAssertCount(AllPrimitiveDictionaries, 0, @"intObj.@count < %@", @(2));
    RLMAssertCount(AllOptionalPrimitiveDictionaries, 0, @"intObj.@count < %@", @(2));
    RLMAssertCount(AllPrimitiveDictionaries, 0, @"stringObj.@count < %@", @(2));
    RLMAssertCount(AllOptionalPrimitiveDictionaries, 0, @"stringObj.@count < %@", @(2));
    RLMAssertCount(AllPrimitiveDictionaries, 0, @"dateObj.@count < %@", @(2));
    RLMAssertCount(AllOptionalPrimitiveDictionaries, 0, @"dateObj.@count < %@", @(2));
    RLMAssertCount(AllPrimitiveDictionaries, 0, @"anyBoolObj.@count < %@", @(2));
    RLMAssertCount(AllPrimitiveDictionaries, 0, @"anyIntObj.@count < %@", @(2));
    RLMAssertCount(AllPrimitiveDictionaries, 0, @"anyFloatObj.@count < %@", @(2));
    RLMAssertCount(AllPrimitiveDictionaries, 0, @"anyDoubleObj.@count < %@", @(2));
    RLMAssertCount(AllPrimitiveDictionaries, 0, @"anyStringObj.@count < %@", @(2));
    RLMAssertCount(AllPrimitiveDictionaries, 0, @"anyDataObj.@count < %@", @(2));
    RLMAssertCount(AllPrimitiveDictionaries, 0, @"anyDateObj.@count < %@", @(2));
    RLMAssertCount(AllPrimitiveDictionaries, 0, @"anyDecimalObj.@count < %@", @(2));
    RLMAssertCount(AllPrimitiveDictionaries, 0, @"anyUUIDObj.@count < %@", @(2));
    RLMAssertCount(AllPrimitiveDictionaries, 1, @"boolObj.@count <= %@", @(2));
    RLMAssertCount(AllOptionalPrimitiveDictionaries, 1, @"boolObj.@count <= %@", @(2));
    RLMAssertCount(AllPrimitiveDictionaries, 1, @"intObj.@count <= %@", @(2));
    RLMAssertCount(AllOptionalPrimitiveDictionaries, 1, @"intObj.@count <= %@", @(2));
    RLMAssertCount(AllPrimitiveDictionaries, 1, @"stringObj.@count <= %@", @(2));
    RLMAssertCount(AllOptionalPrimitiveDictionaries, 1, @"stringObj.@count <= %@", @(2));
    RLMAssertCount(AllPrimitiveDictionaries, 1, @"dateObj.@count <= %@", @(2));
    RLMAssertCount(AllOptionalPrimitiveDictionaries, 1, @"dateObj.@count <= %@", @(2));
    RLMAssertCount(AllPrimitiveDictionaries, 1, @"anyBoolObj.@count <= %@", @(2));
    RLMAssertCount(AllPrimitiveDictionaries, 1, @"anyIntObj.@count <= %@", @(2));
    RLMAssertCount(AllPrimitiveDictionaries, 1, @"anyFloatObj.@count <= %@", @(2));
    RLMAssertCount(AllPrimitiveDictionaries, 1, @"anyDoubleObj.@count <= %@", @(2));
    RLMAssertCount(AllPrimitiveDictionaries, 1, @"anyStringObj.@count <= %@", @(2));
    RLMAssertCount(AllPrimitiveDictionaries, 1, @"anyDataObj.@count <= %@", @(2));
    RLMAssertCount(AllPrimitiveDictionaries, 1, @"anyDateObj.@count <= %@", @(2));
    RLMAssertCount(AllPrimitiveDictionaries, 1, @"anyDecimalObj.@count <= %@", @(2));
    RLMAssertCount(AllPrimitiveDictionaries, 1, @"anyUUIDObj.@count <= %@", @(2));
}

- (void)testQuerySum {
    [realm deleteAllObjects];

    RLMAssertThrowsWithReason(([AllPrimitiveDictionaries objectsInRealm:realm where:@"boolObj.@sum = %@", @NO]),
                              @"@sum can only be applied to a numeric property.");
    RLMAssertThrowsWithReason(([AllOptionalPrimitiveDictionaries objectsInRealm:realm where:@"boolObj.@sum = %@", @NO]),
                              @"@sum can only be applied to a numeric property.");
    RLMAssertThrowsWithReason(([AllPrimitiveDictionaries objectsInRealm:realm where:@"stringObj.@sum = %@", @"bar"]),
                              @"@sum can only be applied to a numeric property.");
    RLMAssertThrowsWithReason(([AllOptionalPrimitiveDictionaries objectsInRealm:realm where:@"stringObj.@sum = %@", @"bar"]),
                              @"@sum can only be applied to a numeric property.");
    RLMAssertThrowsWithReason(([AllPrimitiveDictionaries objectsInRealm:realm where:@"dateObj.@sum = %@", date(1)]),
                              @"Cannot sum or average date properties");
    RLMAssertThrowsWithReason(([AllOptionalPrimitiveDictionaries objectsInRealm:realm where:@"dateObj.@sum = %@", date(1)]),
                              @"Cannot sum or average date properties");

    RLMAssertThrowsWithReason(([AllPrimitiveDictionaries objectsInRealm:realm where:@"intObj.@sum = %@", @"a"]),
                              @"@sum on a property of type int cannot be compared with 'a'");
    RLMAssertThrowsWithReason(([AllOptionalPrimitiveDictionaries objectsInRealm:realm where:@"intObj.@sum = %@", @"a"]),
                              @"@sum on a property of type int cannot be compared with 'a'");
    RLMAssertThrowsWithReason(([AllPrimitiveDictionaries objectsInRealm:realm where:@"intObj.@sum.prop = %@", @"a"]),
                              @"Property 'intObj' is not a link in object of type 'AllPrimitiveDictionaries'");
    RLMAssertThrowsWithReason(([AllOptionalPrimitiveDictionaries objectsInRealm:realm where:@"intObj.@sum.prop = %@", @"a"]),
                              @"Property 'intObj' is not a link in object of type 'AllOptionalPrimitiveDictionaries'");
    RLMAssertThrowsWithReason(([AllPrimitiveDictionaries objectsInRealm:realm where:@"anyIntObj.@sum.prop = %@", @"a"]),
                              @"Property 'anyIntObj' is not a link in object of type 'AllPrimitiveDictionaries'");
    RLMAssertThrowsWithReason(([AllPrimitiveDictionaries objectsInRealm:realm where:@"anyFloatObj.@sum.prop = %@", @"a"]),
                              @"Property 'anyFloatObj' is not a link in object of type 'AllPrimitiveDictionaries'");
    RLMAssertThrowsWithReason(([AllPrimitiveDictionaries objectsInRealm:realm where:@"anyDoubleObj.@sum.prop = %@", @"a"]),
                              @"Property 'anyDoubleObj' is not a link in object of type 'AllPrimitiveDictionaries'");
    RLMAssertThrowsWithReason(([AllPrimitiveDictionaries objectsInRealm:realm where:@"anyDecimalObj.@sum.prop = %@", @"a"]),
                              @"Property 'anyDecimalObj' is not a link in object of type 'AllPrimitiveDictionaries'");
    RLMAssertThrowsWithReason(([AllPrimitiveDictionaries objectsInRealm:realm where:@"intObj.@sum = %@", (id)NSNull.null]),
                              @"@sum on a property of type int cannot be compared with '<null>'");
    RLMAssertThrowsWithReason(([AllOptionalPrimitiveDictionaries objectsInRealm:realm where:@"intObj.@sum = %@", (id)NSNull.null]),
                              @"@sum on a property of type int cannot be compared with '<null>'");
    RLMAssertThrowsWithReason(([AllPrimitiveDictionaries objectsInRealm:realm where:@"anyIntObj.@sum = %@", (id)NSNull.null]),
                              @"@sum on a property of type mixed cannot be compared with '<null>'");
    RLMAssertThrowsWithReason(([AllPrimitiveDictionaries objectsInRealm:realm where:@"anyFloatObj.@sum = %@", (id)NSNull.null]),
                              @"@sum on a property of type mixed cannot be compared with '<null>'");
    RLMAssertThrowsWithReason(([AllPrimitiveDictionaries objectsInRealm:realm where:@"anyDoubleObj.@sum = %@", (id)NSNull.null]),
                              @"@sum on a property of type mixed cannot be compared with '<null>'");
    RLMAssertThrowsWithReason(([AllPrimitiveDictionaries objectsInRealm:realm where:@"anyDecimalObj.@sum = %@", (id)NSNull.null]),
                              @"@sum on a property of type mixed cannot be compared with '<null>'");

    [AllPrimitiveDictionaries createInRealm:realm withValue:@{
        @"intObj": @{},
        @"anyIntObj": @{},
        @"anyFloatObj": @{},
        @"anyDoubleObj": @{},
        @"anyDecimalObj": @{},
    }];
    [AllOptionalPrimitiveDictionaries createInRealm:realm withValue:@{
        @"intObj": @{},
    }];
    [AllPrimitiveDictionaries createInRealm:realm withValue:@{
        @"intObj": @{@"key1": @2},
        @"anyIntObj": @{@"key1": @2},
        @"anyFloatObj": @{@"key1": @2.2f},
        @"anyDoubleObj": @{@"key1": @2.2},
        @"anyDecimalObj": @{@"key1": decimal128(2)},
    }];
    [AllOptionalPrimitiveDictionaries createInRealm:realm withValue:@{
        @"intObj": @{@"key1": @2},
    }];
    [AllPrimitiveDictionaries createInRealm:realm withValue:@{
        @"intObj": @{ @"key1": @2, @"key2": @3 },
        @"anyIntObj": @{ @"key1": @2, @"key2": @3 },
        @"anyFloatObj": @{ @"key1": @2.2f, @"key2": @3.3f },
        @"anyDoubleObj": @{ @"key1": @2.2, @"key2": @3.3 },
        @"anyDecimalObj": @{ @"key1": decimal128(2), @"key2": decimal128(3) },
    }];
    [AllOptionalPrimitiveDictionaries createInRealm:realm withValue:@{
        @"intObj": @{ @"key1": @2, @"key2": NSNull.null },
    }];
    [AllPrimitiveDictionaries createInRealm:realm withValue:@{
        @"intObj": @{ @"key1": @2, @"key2": @3 },
        @"anyIntObj": @{ @"key1": @2, @"key2": @3 },
        @"anyFloatObj": @{ @"key1": @2.2f, @"key2": @3.3f },
        @"anyDoubleObj": @{ @"key1": @2.2, @"key2": @3.3 },
        @"anyDecimalObj": @{ @"key1": decimal128(2), @"key2": decimal128(3) },
    }];
    [AllOptionalPrimitiveDictionaries createInRealm:realm withValue:@{
        @"intObj": @{ @"key1": @2, @"key2": NSNull.null },
    }];

    RLMAssertCount(AllPrimitiveDictionaries, 1U, @"intObj.@sum == %@", @0);
    RLMAssertCount(AllOptionalPrimitiveDictionaries, 1U, @"intObj.@sum == %@", @0);
    RLMAssertCount(AllPrimitiveDictionaries, 1U, @"anyIntObj.@sum == %@", @0);
    RLMAssertCount(AllPrimitiveDictionaries, 1U, @"anyFloatObj.@sum == %@", @0);
    RLMAssertCount(AllPrimitiveDictionaries, 1U, @"anyDoubleObj.@sum == %@", @0);
    RLMAssertCount(AllPrimitiveDictionaries, 1U, @"anyDecimalObj.@sum == %@", @0);
    RLMAssertCount(AllPrimitiveDictionaries, 1U, @"intObj.@sum == %@", @2);
    RLMAssertCount(AllPrimitiveDictionaries, 1U, @"anyIntObj.@sum == %@", @2);
    RLMAssertCount(AllPrimitiveDictionaries, 1U, @"anyFloatObj.@sum == %@", @2.2f);
    RLMAssertCount(AllPrimitiveDictionaries, 1U, @"anyDoubleObj.@sum == %@", @2.2);
    RLMAssertCount(AllPrimitiveDictionaries, 1U, @"anyDecimalObj.@sum == %@", decimal128(2));
    RLMAssertCount(AllOptionalPrimitiveDictionaries, 3U, @"intObj.@sum == %@", @2);
    RLMAssertCount(AllPrimitiveDictionaries, 3U, @"intObj.@sum != %@", @2);
    RLMAssertCount(AllPrimitiveDictionaries, 3U, @"anyIntObj.@sum != %@", @2);
    RLMAssertCount(AllPrimitiveDictionaries, 3U, @"anyFloatObj.@sum != %@", @2.2f);
    RLMAssertCount(AllPrimitiveDictionaries, 3U, @"anyDoubleObj.@sum != %@", @2.2);
    RLMAssertCount(AllPrimitiveDictionaries, 3U, @"anyDecimalObj.@sum != %@", decimal128(2));
    RLMAssertCount(AllOptionalPrimitiveDictionaries, 1U, @"intObj.@sum != %@", @2);
    RLMAssertCount(AllPrimitiveDictionaries, 3U, @"intObj.@sum >= %@", @2);
    RLMAssertCount(AllOptionalPrimitiveDictionaries, 3U, @"intObj.@sum >= %@", @2);
    RLMAssertCount(AllPrimitiveDictionaries, 3U, @"anyIntObj.@sum >= %@", @2);
    RLMAssertCount(AllPrimitiveDictionaries, 3U, @"anyFloatObj.@sum >= %@", @2.2f);
    RLMAssertCount(AllPrimitiveDictionaries, 3U, @"anyDoubleObj.@sum >= %@", @2.2);
    RLMAssertCount(AllPrimitiveDictionaries, 3U, @"anyDecimalObj.@sum >= %@", decimal128(2));
    RLMAssertCount(AllPrimitiveDictionaries, 2U, @"intObj.@sum > %@", @2);
    RLMAssertCount(AllPrimitiveDictionaries, 2U, @"anyIntObj.@sum > %@", @2);
    RLMAssertCount(AllPrimitiveDictionaries, 2U, @"anyFloatObj.@sum > %@", @2.2f);
    RLMAssertCount(AllPrimitiveDictionaries, 2U, @"anyDoubleObj.@sum > %@", @2.2);
    RLMAssertCount(AllPrimitiveDictionaries, 2U, @"anyDecimalObj.@sum > %@", decimal128(2));
    RLMAssertCount(AllOptionalPrimitiveDictionaries, 0U, @"intObj.@sum > %@", @2);
    RLMAssertCount(AllPrimitiveDictionaries, 2U, @"intObj.@sum < %@", @3);
    RLMAssertCount(AllPrimitiveDictionaries, 2U, @"anyIntObj.@sum < %@", @3);
    RLMAssertCount(AllPrimitiveDictionaries, 2U, @"anyFloatObj.@sum < %@", @3.3f);
    RLMAssertCount(AllPrimitiveDictionaries, 2U, @"anyDoubleObj.@sum < %@", @3.3);
    RLMAssertCount(AllPrimitiveDictionaries, 2U, @"anyDecimalObj.@sum < %@", decimal128(3));
    RLMAssertCount(AllOptionalPrimitiveDictionaries, 1U, @"intObj.@sum < %@", @2);
    RLMAssertCount(AllPrimitiveDictionaries, 2U, @"intObj.@sum <= %@", @3);
    RLMAssertCount(AllPrimitiveDictionaries, 2U, @"anyIntObj.@sum <= %@", @3);
    RLMAssertCount(AllPrimitiveDictionaries, 2U, @"anyFloatObj.@sum <= %@", @3.3f);
    RLMAssertCount(AllPrimitiveDictionaries, 2U, @"anyDoubleObj.@sum <= %@", @3.3);
    RLMAssertCount(AllPrimitiveDictionaries, 2U, @"anyDecimalObj.@sum <= %@", decimal128(3));
    RLMAssertCount(AllOptionalPrimitiveDictionaries, 4U, @"intObj.@sum <= %@", @2);
}

- (void)testQueryAverage {
    [realm deleteAllObjects];

    RLMAssertThrowsWithReason(([AllPrimitiveDictionaries objectsInRealm:realm where:@"boolObj.@avg = %@", @NO]),
                              @"@avg can only be applied to a numeric property.");
    RLMAssertThrowsWithReason(([AllOptionalPrimitiveDictionaries objectsInRealm:realm where:@"boolObj.@avg = %@", @NO]),
                              @"@avg can only be applied to a numeric property.");
    RLMAssertThrowsWithReason(([AllPrimitiveDictionaries objectsInRealm:realm where:@"stringObj.@avg = %@", @"bar"]),
                              @"@avg can only be applied to a numeric property.");
    RLMAssertThrowsWithReason(([AllOptionalPrimitiveDictionaries objectsInRealm:realm where:@"stringObj.@avg = %@", @"bar"]),
                              @"@avg can only be applied to a numeric property.");
    RLMAssertThrowsWithReason(([AllPrimitiveDictionaries objectsInRealm:realm where:@"dateObj.@avg = %@", date(1)]),
                              @"Cannot sum or average date properties");
    RLMAssertThrowsWithReason(([AllOptionalPrimitiveDictionaries objectsInRealm:realm where:@"dateObj.@avg = %@", date(1)]),
                              @"Cannot sum or average date properties");

    RLMAssertThrowsWithReason(([AllPrimitiveDictionaries objectsInRealm:realm where:@"intObj.@avg = %@", @"a"]),
                              @"@avg on a property of type int cannot be compared with 'a'");
    RLMAssertThrowsWithReason(([AllOptionalPrimitiveDictionaries objectsInRealm:realm where:@"intObj.@avg = %@", @"a"]),
                              @"@avg on a property of type int cannot be compared with 'a'");
    RLMAssertThrowsWithReason(([AllPrimitiveDictionaries objectsInRealm:realm where:@"intObj.@avg.prop = %@", @"a"]),
                              @"Property 'intObj' is not a link in object of type 'AllPrimitiveDictionaries'");
    RLMAssertThrowsWithReason(([AllOptionalPrimitiveDictionaries objectsInRealm:realm where:@"intObj.@avg.prop = %@", @"a"]),
                              @"Property 'intObj' is not a link in object of type 'AllOptionalPrimitiveDictionaries'");
    RLMAssertThrowsWithReason(([AllPrimitiveDictionaries objectsInRealm:realm where:@"anyIntObj.@avg.prop = %@", @"a"]),
                              @"Property 'anyIntObj' is not a link in object of type 'AllPrimitiveDictionaries'");
    RLMAssertThrowsWithReason(([AllPrimitiveDictionaries objectsInRealm:realm where:@"anyFloatObj.@avg.prop = %@", @"a"]),
                              @"Property 'anyFloatObj' is not a link in object of type 'AllPrimitiveDictionaries'");
    RLMAssertThrowsWithReason(([AllPrimitiveDictionaries objectsInRealm:realm where:@"anyDoubleObj.@avg.prop = %@", @"a"]),
                              @"Property 'anyDoubleObj' is not a link in object of type 'AllPrimitiveDictionaries'");
    RLMAssertThrowsWithReason(([AllPrimitiveDictionaries objectsInRealm:realm where:@"anyDecimalObj.@avg.prop = %@", @"a"]),
                              @"Property 'anyDecimalObj' is not a link in object of type 'AllPrimitiveDictionaries'");

    [AllPrimitiveDictionaries createInRealm:realm withValue:@{
        @"intObj": @{},
        @"anyIntObj": @{},
        @"anyFloatObj": @{},
        @"anyDoubleObj": @{},
        @"anyDecimalObj": @{},
    }];
    [AllOptionalPrimitiveDictionaries createInRealm:realm withValue:@{
        @"intObj": @{},
    }];
    [AllPrimitiveDictionaries createInRealm:realm withValue:@{
        @"intObj": @{@"key1": @2},
        @"anyIntObj": @{@"key1": @2},
        @"anyFloatObj": @{@"key1": @2.2f},
        @"anyDoubleObj": @{@"key1": @2.2},
        @"anyDecimalObj": @{@"key1": decimal128(2)},
    }];
    [AllOptionalPrimitiveDictionaries createInRealm:realm withValue:@{
        @"intObj": @{@"key1": @2},
    }];
    [AllPrimitiveDictionaries createInRealm:realm withValue:@{
        @"intObj": @{ @"key1": @2, @"key2": @3 },
        @"anyIntObj": @{ @"key1": @2, @"key2": @3 },
        @"anyFloatObj": @{ @"key1": @2.2f, @"key2": @3.3f },
        @"anyDoubleObj": @{ @"key1": @2.2, @"key2": @3.3 },
        @"anyDecimalObj": @{ @"key1": decimal128(2), @"key2": decimal128(3) },
    }];
    [AllOptionalPrimitiveDictionaries createInRealm:realm withValue:@{
        @"intObj": @{ @"key1": @2, @"key2": NSNull.null },
    }];
    [AllPrimitiveDictionaries createInRealm:realm withValue:@{
        @"intObj": @{@"key1": @3},
        @"anyIntObj": @{@"key1": @3},
        @"anyFloatObj": @{@"key1": @3.3f},
        @"anyDoubleObj": @{@"key1": @3.3},
        @"anyDecimalObj": @{@"key1": decimal128(3)},
    }];
    [AllOptionalPrimitiveDictionaries createInRealm:realm withValue:@{
        @"intObj": @{@"key1": @2},
    }];

    RLMAssertCount(AllPrimitiveDictionaries, 1U, @"intObj.@avg == %@", NSNull.null);
    RLMAssertCount(AllOptionalPrimitiveDictionaries, 1U, @"intObj.@avg == %@", NSNull.null);
    RLMAssertCount(AllPrimitiveDictionaries, 1U, @"anyIntObj.@avg == %@", NSNull.null);
    RLMAssertCount(AllPrimitiveDictionaries, 1U, @"anyFloatObj.@avg == %@", NSNull.null);
    RLMAssertCount(AllPrimitiveDictionaries, 1U, @"anyDoubleObj.@avg == %@", NSNull.null);
    RLMAssertCount(AllPrimitiveDictionaries, 1U, @"anyDecimalObj.@avg == %@", NSNull.null);
    RLMAssertCount(AllPrimitiveDictionaries, 1U, @"intObj.@avg == %@", @2);
    RLMAssertCount(AllPrimitiveDictionaries, 1U, @"anyIntObj.@avg == %@", @2);
    RLMAssertCount(AllPrimitiveDictionaries, 1U, @"anyFloatObj.@avg == %@", @2.2f);
    RLMAssertCount(AllPrimitiveDictionaries, 1U, @"anyDoubleObj.@avg == %@", @2.2);
    RLMAssertCount(AllPrimitiveDictionaries, 1U, @"anyDecimalObj.@avg == %@", decimal128(2));
    RLMAssertCount(AllOptionalPrimitiveDictionaries, 3U, @"intObj.@avg == %@", @2);
    RLMAssertCount(AllPrimitiveDictionaries, 3U, @"intObj.@avg != %@", @2);
    RLMAssertCount(AllPrimitiveDictionaries, 3U, @"anyIntObj.@avg != %@", @2);
    RLMAssertCount(AllPrimitiveDictionaries, 3U, @"anyFloatObj.@avg != %@", @2.2f);
    RLMAssertCount(AllPrimitiveDictionaries, 3U, @"anyDoubleObj.@avg != %@", @2.2);
    RLMAssertCount(AllPrimitiveDictionaries, 3U, @"anyDecimalObj.@avg != %@", decimal128(2));
    RLMAssertCount(AllOptionalPrimitiveDictionaries, 1U, @"intObj.@avg != %@", @2);
    RLMAssertCount(AllPrimitiveDictionaries, 3U, @"intObj.@avg >= %@", @2);
    RLMAssertCount(AllOptionalPrimitiveDictionaries, 3U, @"intObj.@avg >= %@", @2);
    RLMAssertCount(AllPrimitiveDictionaries, 3U, @"anyIntObj.@avg >= %@", @2);
    RLMAssertCount(AllPrimitiveDictionaries, 3U, @"anyFloatObj.@avg >= %@", @2.2f);
    RLMAssertCount(AllPrimitiveDictionaries, 3U, @"anyDoubleObj.@avg >= %@", @2.2);
    RLMAssertCount(AllPrimitiveDictionaries, 3U, @"anyDecimalObj.@avg >= %@", decimal128(2));
    RLMAssertCount(AllPrimitiveDictionaries, 2U, @"intObj.@avg > %@", @2);
    RLMAssertCount(AllPrimitiveDictionaries, 2U, @"anyIntObj.@avg > %@", @2);
    RLMAssertCount(AllPrimitiveDictionaries, 2U, @"anyFloatObj.@avg > %@", @2.2f);
    RLMAssertCount(AllPrimitiveDictionaries, 2U, @"anyDoubleObj.@avg > %@", @2.2);
    RLMAssertCount(AllPrimitiveDictionaries, 2U, @"anyDecimalObj.@avg > %@", decimal128(2));
    RLMAssertCount(AllOptionalPrimitiveDictionaries, 0U, @"intObj.@avg > %@", @2);
    RLMAssertCount(AllPrimitiveDictionaries, 2U, @"intObj.@avg < %@", @3);
    RLMAssertCount(AllPrimitiveDictionaries, 2U, @"anyIntObj.@avg < %@", @3);
    RLMAssertCount(AllPrimitiveDictionaries, 2U, @"anyFloatObj.@avg < %@", @3.3f);
    RLMAssertCount(AllPrimitiveDictionaries, 2U, @"anyDoubleObj.@avg < %@", @3.3);
    RLMAssertCount(AllPrimitiveDictionaries, 2U, @"anyDecimalObj.@avg < %@", decimal128(3));
    RLMAssertCount(AllOptionalPrimitiveDictionaries, 0U, @"intObj.@avg < %@", @2);
    RLMAssertCount(AllPrimitiveDictionaries, 3U, @"intObj.@avg <= %@", @3);
    RLMAssertCount(AllPrimitiveDictionaries, 3U, @"anyIntObj.@avg <= %@", @3);
    RLMAssertCount(AllPrimitiveDictionaries, 3U, @"anyFloatObj.@avg <= %@", @3.3f);
    RLMAssertCount(AllPrimitiveDictionaries, 3U, @"anyDoubleObj.@avg <= %@", @3.3);
    RLMAssertCount(AllPrimitiveDictionaries, 3U, @"anyDecimalObj.@avg <= %@", decimal128(3));
    RLMAssertCount(AllOptionalPrimitiveDictionaries, 1U, @"intObj.@avg <= %@", NSNull.null);
    RLMAssertCount(AllOptionalPrimitiveDictionaries, 3U, @"intObj.@avg <= %@", @2);
}

- (void)testQueryMin {
    [realm deleteAllObjects];

    RLMAssertThrowsWithReason(([AllPrimitiveDictionaries objectsInRealm:realm where:@"boolObj.@min = %@", @NO]),
                              @"@min can only be applied to a numeric property.");
    RLMAssertThrowsWithReason(([AllOptionalPrimitiveDictionaries objectsInRealm:realm where:@"boolObj.@min = %@", @NO]),
                              @"@min can only be applied to a numeric property.");
    RLMAssertThrowsWithReason(([AllPrimitiveDictionaries objectsInRealm:realm where:@"stringObj.@min = %@", @"bar"]),
                              @"@min can only be applied to a numeric property.");
    RLMAssertThrowsWithReason(([AllOptionalPrimitiveDictionaries objectsInRealm:realm where:@"stringObj.@min = %@", @"bar"]),
                              @"@min can only be applied to a numeric property.");
    RLMAssertThrowsWithReason(([AllPrimitiveDictionaries objectsInRealm:realm where:@"intObj.@min = %@", @"a"]),
                              @"@min on a property of type int cannot be compared with 'a'");
    RLMAssertThrowsWithReason(([AllOptionalPrimitiveDictionaries objectsInRealm:realm where:@"intObj.@min = %@", @"a"]),
                              @"@min on a property of type int cannot be compared with 'a'");
    RLMAssertThrowsWithReason(([AllPrimitiveDictionaries objectsInRealm:realm where:@"dateObj.@min = %@", @"a"]),
                              @"@min on a property of type date cannot be compared with 'a'");
    RLMAssertThrowsWithReason(([AllOptionalPrimitiveDictionaries objectsInRealm:realm where:@"dateObj.@min = %@", @"a"]),
                              @"@min on a property of type date cannot be compared with 'a'");
    RLMAssertThrowsWithReason(([AllPrimitiveDictionaries objectsInRealm:realm where:@"intObj.@min.prop = %@", @"a"]),
                              @"Property 'intObj' is not a link in object of type 'AllPrimitiveDictionaries'");
    RLMAssertThrowsWithReason(([AllOptionalPrimitiveDictionaries objectsInRealm:realm where:@"intObj.@min.prop = %@", @"a"]),
                              @"Property 'intObj' is not a link in object of type 'AllOptionalPrimitiveDictionaries'");
    RLMAssertThrowsWithReason(([AllPrimitiveDictionaries objectsInRealm:realm where:@"dateObj.@min.prop = %@", @"a"]),
                              @"Property 'dateObj' is not a link in object of type 'AllPrimitiveDictionaries'");
    RLMAssertThrowsWithReason(([AllOptionalPrimitiveDictionaries objectsInRealm:realm where:@"dateObj.@min.prop = %@", @"a"]),
                              @"Property 'dateObj' is not a link in object of type 'AllOptionalPrimitiveDictionaries'");
    RLMAssertThrowsWithReason(([AllPrimitiveDictionaries objectsInRealm:realm where:@"anyFloatObj.@min.prop = %@", @"a"]),
                              @"Property 'anyFloatObj' is not a link in object of type 'AllPrimitiveDictionaries'");
    RLMAssertThrowsWithReason(([AllPrimitiveDictionaries objectsInRealm:realm where:@"anyDoubleObj.@min.prop = %@", @"a"]),
                              @"Property 'anyDoubleObj' is not a link in object of type 'AllPrimitiveDictionaries'");
    RLMAssertThrowsWithReason(([AllPrimitiveDictionaries objectsInRealm:realm where:@"anyDecimalObj.@min.prop = %@", @"a"]),
                              @"Property 'anyDecimalObj' is not a link in object of type 'AllPrimitiveDictionaries'");

    // No objects, so count is zero
    RLMAssertCount(AllPrimitiveDictionaries, 0U, @"intObj.@min == %@", @2);
    RLMAssertCount(AllOptionalPrimitiveDictionaries, 0U, @"intObj.@min == %@", @2);
    RLMAssertCount(AllPrimitiveDictionaries, 0U, @"dateObj.@min == %@", date(1));
    RLMAssertCount(AllOptionalPrimitiveDictionaries, 0U, @"dateObj.@min == %@", date(1));
    RLMAssertCount(AllPrimitiveDictionaries, 0U, @"anyFloatObj.@min == %@", @2.2f);
    RLMAssertCount(AllPrimitiveDictionaries, 0U, @"anyDoubleObj.@min == %@", @2.2);
    RLMAssertCount(AllPrimitiveDictionaries, 0U, @"anyDecimalObj.@min == %@", decimal128(2));

    [AllPrimitiveDictionaries createInRealm:realm withValue:@{}];
    [AllOptionalPrimitiveDictionaries createInRealm:realm withValue:@{}];

    // Only empty dictionarys, so count is zero
    RLMAssertCount(AllPrimitiveDictionaries, 0U, @"intObj.@min == %@", @2);
    RLMAssertCount(AllOptionalPrimitiveDictionaries, 0U, @"intObj.@min == %@", @2);
    RLMAssertCount(AllPrimitiveDictionaries, 0U, @"dateObj.@min == %@", date(1));
    RLMAssertCount(AllOptionalPrimitiveDictionaries, 0U, @"dateObj.@min == %@", date(1));
    RLMAssertCount(AllPrimitiveDictionaries, 0U, @"anyFloatObj.@min == %@", @2.2f);
    RLMAssertCount(AllPrimitiveDictionaries, 0U, @"anyDoubleObj.@min == %@", @2.2);
    RLMAssertCount(AllPrimitiveDictionaries, 0U, @"anyDecimalObj.@min == %@", decimal128(2));
    RLMAssertCount(AllPrimitiveDictionaries, 0U, @"intObj.@min == %@", @3);
    RLMAssertCount(AllPrimitiveDictionaries, 0U, @"dateObj.@min == %@", date(2));
    RLMAssertCount(AllPrimitiveDictionaries, 0U, @"anyFloatObj.@min == %@", @3.3f);
    RLMAssertCount(AllPrimitiveDictionaries, 0U, @"anyDoubleObj.@min == %@", @3.3);
    RLMAssertCount(AllPrimitiveDictionaries, 0U, @"anyDecimalObj.@min == %@", decimal128(3));
    RLMAssertCount(AllOptionalPrimitiveDictionaries, 1U, @"intObj.@min == %@", NSNull.null);
    RLMAssertCount(AllOptionalPrimitiveDictionaries, 1U, @"dateObj.@min == %@", NSNull.null);

    RLMAssertCount(AllPrimitiveDictionaries, 1U, @"intObj.@min == nil");
    RLMAssertCount(AllOptionalPrimitiveDictionaries, 1U, @"intObj.@min == nil");
    RLMAssertCount(AllPrimitiveDictionaries, 1U, @"dateObj.@min == nil");
    RLMAssertCount(AllOptionalPrimitiveDictionaries, 1U, @"dateObj.@min == nil");
    RLMAssertCount(AllPrimitiveDictionaries, 1U, @"anyFloatObj.@min == nil");
    RLMAssertCount(AllPrimitiveDictionaries, 1U, @"anyDoubleObj.@min == nil");
    RLMAssertCount(AllPrimitiveDictionaries, 1U, @"anyDecimalObj.@min == nil");
    RLMAssertCount(AllPrimitiveDictionaries, 1U, @"intObj.@min == %@", NSNull.null);
    RLMAssertCount(AllOptionalPrimitiveDictionaries, 1U, @"intObj.@min == %@", NSNull.null);
    RLMAssertCount(AllPrimitiveDictionaries, 1U, @"dateObj.@min == %@", NSNull.null);
    RLMAssertCount(AllOptionalPrimitiveDictionaries, 1U, @"dateObj.@min == %@", NSNull.null);
    RLMAssertCount(AllPrimitiveDictionaries, 1U, @"anyFloatObj.@min == %@", NSNull.null);
    RLMAssertCount(AllPrimitiveDictionaries, 1U, @"anyDoubleObj.@min == %@", NSNull.null);
    RLMAssertCount(AllPrimitiveDictionaries, 1U, @"anyDecimalObj.@min == %@", NSNull.null);

    [self createObject];

    // One object where v0 is min and zero with v1
    RLMAssertCount(AllPrimitiveDictionaries, 1U, @"intObj.@min == %@", @2);
    RLMAssertCount(AllOptionalPrimitiveDictionaries, 1U, @"intObj.@min == %@", @2);
    RLMAssertCount(AllPrimitiveDictionaries, 1U, @"dateObj.@min == %@", date(1));
    RLMAssertCount(AllOptionalPrimitiveDictionaries, 1U, @"dateObj.@min == %@", date(1));
    RLMAssertCount(AllPrimitiveDictionaries, 1U, @"anyFloatObj.@min == %@", @2.2f);
    RLMAssertCount(AllPrimitiveDictionaries, 1U, @"anyDoubleObj.@min == %@", @2.2);
    RLMAssertCount(AllPrimitiveDictionaries, 1U, @"anyDecimalObj.@min == %@", decimal128(2));
    RLMAssertCount(AllPrimitiveDictionaries, 0U, @"intObj.@min == %@", @3);
    RLMAssertCount(AllPrimitiveDictionaries, 0U, @"dateObj.@min == %@", date(2));
    RLMAssertCount(AllPrimitiveDictionaries, 0U, @"anyFloatObj.@min == %@", @3.3f);
    RLMAssertCount(AllPrimitiveDictionaries, 0U, @"anyDoubleObj.@min == %@", @3.3);
    RLMAssertCount(AllPrimitiveDictionaries, 0U, @"anyDecimalObj.@min == %@", decimal128(3));
    RLMAssertCount(AllOptionalPrimitiveDictionaries, 1U, @"intObj.@min == %@", NSNull.null);
    RLMAssertCount(AllOptionalPrimitiveDictionaries, 1U, @"dateObj.@min == %@", NSNull.null);
}

- (void)testQueryMax {
    [realm deleteAllObjects];

    RLMAssertThrowsWithReason(([AllPrimitiveDictionaries objectsInRealm:realm where:@"boolObj.@max = %@", @NO]),
                              @"@max can only be applied to a numeric property.");
    RLMAssertThrowsWithReason(([AllOptionalPrimitiveDictionaries objectsInRealm:realm where:@"boolObj.@max = %@", @NO]),
                              @"@max can only be applied to a numeric property.");
    RLMAssertThrowsWithReason(([AllPrimitiveDictionaries objectsInRealm:realm where:@"stringObj.@max = %@", @"bar"]),
                              @"@max can only be applied to a numeric property.");
    RLMAssertThrowsWithReason(([AllOptionalPrimitiveDictionaries objectsInRealm:realm where:@"stringObj.@max = %@", @"bar"]),
                              @"@max can only be applied to a numeric property.");
    RLMAssertThrowsWithReason(([AllPrimitiveDictionaries objectsInRealm:realm where:@"intObj.@max = %@", @"a"]),
                              @"@max on a property of type int cannot be compared with 'a'");
    RLMAssertThrowsWithReason(([AllOptionalPrimitiveDictionaries objectsInRealm:realm where:@"intObj.@max = %@", @"a"]),
                              @"@max on a property of type int cannot be compared with 'a'");
    RLMAssertThrowsWithReason(([AllPrimitiveDictionaries objectsInRealm:realm where:@"dateObj.@max = %@", @"a"]),
                              @"@max on a property of type date cannot be compared with 'a'");
    RLMAssertThrowsWithReason(([AllOptionalPrimitiveDictionaries objectsInRealm:realm where:@"dateObj.@max = %@", @"a"]),
                              @"@max on a property of type date cannot be compared with 'a'");
    RLMAssertThrowsWithReason(([AllPrimitiveDictionaries objectsInRealm:realm where:@"intObj.@max.prop = %@", @"a"]),
                              @"Property 'intObj' is not a link in object of type 'AllPrimitiveDictionaries'");
    RLMAssertThrowsWithReason(([AllOptionalPrimitiveDictionaries objectsInRealm:realm where:@"intObj.@max.prop = %@", @"a"]),
                              @"Property 'intObj' is not a link in object of type 'AllOptionalPrimitiveDictionaries'");
    RLMAssertThrowsWithReason(([AllPrimitiveDictionaries objectsInRealm:realm where:@"dateObj.@max.prop = %@", @"a"]),
                              @"Property 'dateObj' is not a link in object of type 'AllPrimitiveDictionaries'");
    RLMAssertThrowsWithReason(([AllOptionalPrimitiveDictionaries objectsInRealm:realm where:@"dateObj.@max.prop = %@", @"a"]),
                              @"Property 'dateObj' is not a link in object of type 'AllOptionalPrimitiveDictionaries'");
    RLMAssertThrowsWithReason(([AllPrimitiveDictionaries objectsInRealm:realm where:@"anyFloatObj.@max.prop = %@", @"a"]),
                              @"Property 'anyFloatObj' is not a link in object of type 'AllPrimitiveDictionaries'");
    RLMAssertThrowsWithReason(([AllPrimitiveDictionaries objectsInRealm:realm where:@"anyDoubleObj.@max.prop = %@", @"a"]),
                              @"Property 'anyDoubleObj' is not a link in object of type 'AllPrimitiveDictionaries'");
    RLMAssertThrowsWithReason(([AllPrimitiveDictionaries objectsInRealm:realm where:@"anyDecimalObj.@max.prop = %@", @"a"]),
                              @"Property 'anyDecimalObj' is not a link in object of type 'AllPrimitiveDictionaries'");

    // No objects, so count is zero
    RLMAssertCount(AllPrimitiveDictionaries, 0U, @"intObj.@max == %@", @2);
    RLMAssertCount(AllOptionalPrimitiveDictionaries, 0U, @"intObj.@max == %@", @2);
    RLMAssertCount(AllPrimitiveDictionaries, 0U, @"dateObj.@max == %@", date(1));
    RLMAssertCount(AllOptionalPrimitiveDictionaries, 0U, @"dateObj.@max == %@", date(1));
    RLMAssertCount(AllPrimitiveDictionaries, 0U, @"anyFloatObj.@max == %@", @2.2f);
    RLMAssertCount(AllPrimitiveDictionaries, 0U, @"anyDoubleObj.@max == %@", @2.2);
    RLMAssertCount(AllPrimitiveDictionaries, 0U, @"anyDecimalObj.@max == %@", decimal128(2));

    [AllPrimitiveDictionaries createInRealm:realm withValue:@{}];
    [AllOptionalPrimitiveDictionaries createInRealm:realm withValue:@{}];

    // Only empty dictionarys, so count is zero.
    RLMAssertCount(AllPrimitiveDictionaries, 0U, @"intObj.@max == %@", @2);
    RLMAssertCount(AllPrimitiveDictionaries, 0U, @"dateObj.@max == %@", date(1));
    RLMAssertCount(AllPrimitiveDictionaries, 0U, @"anyFloatObj.@max == %@", @2.2f);
    RLMAssertCount(AllPrimitiveDictionaries, 0U, @"anyDoubleObj.@max == %@", @2.2);
    RLMAssertCount(AllPrimitiveDictionaries, 0U, @"anyDecimalObj.@max == %@", decimal128(2));
    RLMAssertCount(AllPrimitiveDictionaries, 0U, @"intObj.@max == %@", @3);
    RLMAssertCount(AllPrimitiveDictionaries, 0U, @"dateObj.@max == %@", date(2));
    RLMAssertCount(AllPrimitiveDictionaries, 0U, @"anyFloatObj.@max == %@", @3.3f);
    RLMAssertCount(AllPrimitiveDictionaries, 0U, @"anyDoubleObj.@max == %@", @3.3);
    RLMAssertCount(AllPrimitiveDictionaries, 0U, @"anyDecimalObj.@max == %@", decimal128(3));

    RLMAssertCount(AllOptionalPrimitiveDictionaries, 0U, @"intObj.@max == %@", @2);
    RLMAssertCount(AllOptionalPrimitiveDictionaries, 0U, @"dateObj.@max == %@", date(1));
    RLMAssertCount(AllOptionalPrimitiveDictionaries, 1U, @"intObj.@max == %@", NSNull.null);
    RLMAssertCount(AllOptionalPrimitiveDictionaries, 1U, @"dateObj.@max == %@", NSNull.null);

    RLMAssertCount(AllPrimitiveDictionaries, 1U, @"intObj.@max == nil");
    RLMAssertCount(AllOptionalPrimitiveDictionaries, 1U, @"intObj.@max == nil");
    RLMAssertCount(AllPrimitiveDictionaries, 1U, @"dateObj.@max == nil");
    RLMAssertCount(AllOptionalPrimitiveDictionaries, 1U, @"dateObj.@max == nil");
    RLMAssertCount(AllPrimitiveDictionaries, 1U, @"anyFloatObj.@max == nil");
    RLMAssertCount(AllPrimitiveDictionaries, 1U, @"anyDoubleObj.@max == nil");
    RLMAssertCount(AllPrimitiveDictionaries, 1U, @"anyDecimalObj.@max == nil");
    RLMAssertCount(AllPrimitiveDictionaries, 1U, @"intObj.@max == %@", NSNull.null);
    RLMAssertCount(AllOptionalPrimitiveDictionaries, 1U, @"intObj.@max == %@", NSNull.null);
    RLMAssertCount(AllPrimitiveDictionaries, 1U, @"dateObj.@max == %@", NSNull.null);
    RLMAssertCount(AllOptionalPrimitiveDictionaries, 1U, @"dateObj.@max == %@", NSNull.null);
    RLMAssertCount(AllPrimitiveDictionaries, 1U, @"anyFloatObj.@max == %@", NSNull.null);
    RLMAssertCount(AllPrimitiveDictionaries, 1U, @"anyDoubleObj.@max == %@", NSNull.null);
    RLMAssertCount(AllPrimitiveDictionaries, 1U, @"anyDecimalObj.@max == %@", NSNull.null);

    [self createObject];

    // One object where v0 is min and zero with v1
    RLMAssertCount(AllPrimitiveDictionaries, 1U, @"intObj.@max == %@", @2);
    RLMAssertCount(AllOptionalPrimitiveDictionaries, 1U, @"intObj.@max == %@", @2);
    RLMAssertCount(AllPrimitiveDictionaries, 1U, @"dateObj.@max == %@", date(1));
    RLMAssertCount(AllOptionalPrimitiveDictionaries, 1U, @"dateObj.@max == %@", date(1));
    RLMAssertCount(AllPrimitiveDictionaries, 1U, @"anyFloatObj.@max == %@", @2.2f);
    RLMAssertCount(AllPrimitiveDictionaries, 1U, @"anyDoubleObj.@max == %@", @2.2);
    RLMAssertCount(AllPrimitiveDictionaries, 1U, @"anyDecimalObj.@max == %@", decimal128(2));
    RLMAssertCount(AllPrimitiveDictionaries, 0U, @"intObj.@max == %@", @3);
    RLMAssertCount(AllPrimitiveDictionaries, 0U, @"dateObj.@max == %@", date(2));
    RLMAssertCount(AllPrimitiveDictionaries, 0U, @"anyFloatObj.@max == %@", @3.3f);
    RLMAssertCount(AllPrimitiveDictionaries, 0U, @"anyDoubleObj.@max == %@", @3.3);
    RLMAssertCount(AllPrimitiveDictionaries, 0U, @"anyDecimalObj.@max == %@", decimal128(3));
    RLMAssertCount(AllOptionalPrimitiveDictionaries, 1U, @"intObj.@max == %@", NSNull.null);
    RLMAssertCount(AllOptionalPrimitiveDictionaries, 1U, @"dateObj.@max == %@", NSNull.null);
}

- (void)testQueryBasicOperatorsOverLink {
    [realm deleteAllObjects];

    RLMAssertCount(LinkToAllPrimitiveDictionaries, 0, @"ANY link.boolObj = %@", @NO);
    RLMAssertCount(LinkToAllOptionalPrimitiveDictionaries, 0, @"ANY link.boolObj = %@", @NO);
    RLMAssertCount(LinkToAllPrimitiveDictionaries, 0, @"ANY link.intObj = %@", @2);
    RLMAssertCount(LinkToAllOptionalPrimitiveDictionaries, 0, @"ANY link.intObj = %@", @2);
    RLMAssertCount(LinkToAllPrimitiveDictionaries, 0, @"ANY link.stringObj = %@", @"bar");
    RLMAssertCount(LinkToAllOptionalPrimitiveDictionaries, 0, @"ANY link.stringObj = %@", @"bar");
    RLMAssertCount(LinkToAllPrimitiveDictionaries, 0, @"ANY link.dateObj = %@", date(1));
    RLMAssertCount(LinkToAllOptionalPrimitiveDictionaries, 0, @"ANY link.dateObj = %@", date(1));
    RLMAssertCount(LinkToAllPrimitiveDictionaries, 0, @"ANY link.anyBoolObj = %@", @NO);
    RLMAssertCount(LinkToAllPrimitiveDictionaries, 0, @"ANY link.anyIntObj = %@", @2);
    RLMAssertCount(LinkToAllPrimitiveDictionaries, 0, @"ANY link.anyFloatObj = %@", @2.2f);
    RLMAssertCount(LinkToAllPrimitiveDictionaries, 0, @"ANY link.anyDoubleObj = %@", @2.2);
    RLMAssertCount(LinkToAllPrimitiveDictionaries, 0, @"ANY link.anyStringObj = %@", @"a");
    RLMAssertCount(LinkToAllPrimitiveDictionaries, 0, @"ANY link.anyDataObj = %@", data(1));
    RLMAssertCount(LinkToAllPrimitiveDictionaries, 0, @"ANY link.anyDateObj = %@", date(1));
    RLMAssertCount(LinkToAllPrimitiveDictionaries, 0, @"ANY link.anyDecimalObj = %@", decimal128(2));
    RLMAssertCount(LinkToAllPrimitiveDictionaries, 0, @"ANY link.anyUUIDObj = %@", uuid(@"00000000-0000-0000-0000-000000000000"));
    RLMAssertCount(LinkToAllPrimitiveDictionaries, 0, @"ANY link.boolObj != %@", @NO);
    RLMAssertCount(LinkToAllOptionalPrimitiveDictionaries, 0, @"ANY link.boolObj != %@", @NO);
    RLMAssertCount(LinkToAllPrimitiveDictionaries, 0, @"ANY link.intObj != %@", @2);
    RLMAssertCount(LinkToAllOptionalPrimitiveDictionaries, 0, @"ANY link.intObj != %@", @2);
    RLMAssertCount(LinkToAllPrimitiveDictionaries, 0, @"ANY link.stringObj != %@", @"bar");
    RLMAssertCount(LinkToAllOptionalPrimitiveDictionaries, 0, @"ANY link.stringObj != %@", @"bar");
    RLMAssertCount(LinkToAllPrimitiveDictionaries, 0, @"ANY link.dateObj != %@", date(1));
    RLMAssertCount(LinkToAllOptionalPrimitiveDictionaries, 0, @"ANY link.dateObj != %@", date(1));
    RLMAssertCount(LinkToAllPrimitiveDictionaries, 0, @"ANY link.anyBoolObj != %@", @NO);
    RLMAssertCount(LinkToAllPrimitiveDictionaries, 0, @"ANY link.anyIntObj != %@", @2);
    RLMAssertCount(LinkToAllPrimitiveDictionaries, 0, @"ANY link.anyFloatObj != %@", @2.2f);
    RLMAssertCount(LinkToAllPrimitiveDictionaries, 0, @"ANY link.anyDoubleObj != %@", @2.2);
    RLMAssertCount(LinkToAllPrimitiveDictionaries, 0, @"ANY link.anyStringObj != %@", @"a");
    RLMAssertCount(LinkToAllPrimitiveDictionaries, 0, @"ANY link.anyDataObj != %@", data(1));
    RLMAssertCount(LinkToAllPrimitiveDictionaries, 0, @"ANY link.anyDateObj != %@", date(1));
    RLMAssertCount(LinkToAllPrimitiveDictionaries, 0, @"ANY link.anyDecimalObj != %@", decimal128(2));
    RLMAssertCount(LinkToAllPrimitiveDictionaries, 0, @"ANY link.anyUUIDObj != %@", uuid(@"00000000-0000-0000-0000-000000000000"));
    RLMAssertCount(LinkToAllPrimitiveDictionaries, 0, @"ANY link.intObj > %@", @2);
    RLMAssertCount(LinkToAllOptionalPrimitiveDictionaries, 0, @"ANY link.intObj > %@", @2);
    RLMAssertCount(LinkToAllPrimitiveDictionaries, 0, @"ANY link.dateObj > %@", date(1));
    RLMAssertCount(LinkToAllOptionalPrimitiveDictionaries, 0, @"ANY link.dateObj > %@", date(1));
    RLMAssertCount(LinkToAllPrimitiveDictionaries, 0, @"ANY link.anyFloatObj > %@", @2.2f);
    RLMAssertCount(LinkToAllPrimitiveDictionaries, 0, @"ANY link.anyDoubleObj > %@", @2.2);
    RLMAssertCount(LinkToAllPrimitiveDictionaries, 0, @"ANY link.anyDecimalObj > %@", decimal128(2));
    RLMAssertCount(LinkToAllPrimitiveDictionaries, 0, @"ANY link.intObj >= %@", @2);
    RLMAssertCount(LinkToAllOptionalPrimitiveDictionaries, 0, @"ANY link.intObj >= %@", @2);
    RLMAssertCount(LinkToAllPrimitiveDictionaries, 0, @"ANY link.dateObj >= %@", date(1));
    RLMAssertCount(LinkToAllOptionalPrimitiveDictionaries, 0, @"ANY link.dateObj >= %@", date(1));
    RLMAssertCount(LinkToAllPrimitiveDictionaries, 0, @"ANY link.anyFloatObj >= %@", @2.2f);
    RLMAssertCount(LinkToAllPrimitiveDictionaries, 0, @"ANY link.anyDoubleObj >= %@", @2.2);
    RLMAssertCount(LinkToAllPrimitiveDictionaries, 0, @"ANY link.anyDecimalObj >= %@", decimal128(2));
    RLMAssertCount(LinkToAllPrimitiveDictionaries, 0, @"ANY link.intObj < %@", @2);
    RLMAssertCount(LinkToAllOptionalPrimitiveDictionaries, 0, @"ANY link.intObj < %@", @2);
    RLMAssertCount(LinkToAllPrimitiveDictionaries, 0, @"ANY link.dateObj < %@", date(1));
    RLMAssertCount(LinkToAllOptionalPrimitiveDictionaries, 0, @"ANY link.dateObj < %@", date(1));
    RLMAssertCount(LinkToAllPrimitiveDictionaries, 0, @"ANY link.anyFloatObj < %@", @2.2f);
    RLMAssertCount(LinkToAllPrimitiveDictionaries, 0, @"ANY link.anyDoubleObj < %@", @2.2);
    RLMAssertCount(LinkToAllPrimitiveDictionaries, 0, @"ANY link.anyDecimalObj < %@", decimal128(2));
    RLMAssertCount(LinkToAllPrimitiveDictionaries, 0, @"ANY link.intObj <= %@", @2);
    RLMAssertCount(LinkToAllOptionalPrimitiveDictionaries, 0, @"ANY link.intObj <= %@", @2);
    RLMAssertCount(LinkToAllPrimitiveDictionaries, 0, @"ANY link.dateObj <= %@", date(1));
    RLMAssertCount(LinkToAllOptionalPrimitiveDictionaries, 0, @"ANY link.dateObj <= %@", date(1));
    RLMAssertCount(LinkToAllPrimitiveDictionaries, 0, @"ANY link.anyFloatObj <= %@", @2.2f);
    RLMAssertCount(LinkToAllPrimitiveDictionaries, 0, @"ANY link.anyDoubleObj <= %@", @2.2);
    RLMAssertCount(LinkToAllPrimitiveDictionaries, 0, @"ANY link.anyDecimalObj <= %@", decimal128(2));

    [self createObject];

    RLMAssertCount(LinkToAllPrimitiveDictionaries, 0, @"ANY link.boolObj = %@", @YES);
    RLMAssertCount(LinkToAllOptionalPrimitiveDictionaries, 0, @"ANY link.boolObj = %@", NSNull.null);
    RLMAssertCount(LinkToAllPrimitiveDictionaries, 0, @"ANY link.intObj = %@", @3);
    RLMAssertCount(LinkToAllOptionalPrimitiveDictionaries, 0, @"ANY link.intObj = %@", NSNull.null);
    RLMAssertCount(LinkToAllPrimitiveDictionaries, 0, @"ANY link.stringObj = %@", @"foo");
    RLMAssertCount(LinkToAllOptionalPrimitiveDictionaries, 0, @"ANY link.stringObj = %@", NSNull.null);
    RLMAssertCount(LinkToAllPrimitiveDictionaries, 0, @"ANY link.dateObj = %@", date(2));
    RLMAssertCount(LinkToAllOptionalPrimitiveDictionaries, 0, @"ANY link.dateObj = %@", NSNull.null);
    RLMAssertCount(LinkToAllPrimitiveDictionaries, 0, @"ANY link.anyBoolObj = %@", @YES);
    RLMAssertCount(LinkToAllPrimitiveDictionaries, 0, @"ANY link.anyIntObj = %@", @3);
    RLMAssertCount(LinkToAllPrimitiveDictionaries, 0, @"ANY link.anyFloatObj = %@", @3.3f);
    RLMAssertCount(LinkToAllPrimitiveDictionaries, 0, @"ANY link.anyDoubleObj = %@", @3.3);
    RLMAssertCount(LinkToAllPrimitiveDictionaries, 0, @"ANY link.anyStringObj = %@", @"b");
    RLMAssertCount(LinkToAllPrimitiveDictionaries, 0, @"ANY link.anyDataObj = %@", data(2));
    RLMAssertCount(LinkToAllPrimitiveDictionaries, 0, @"ANY link.anyDateObj = %@", date(2));
    RLMAssertCount(LinkToAllPrimitiveDictionaries, 0, @"ANY link.anyDecimalObj = %@", decimal128(3));
    RLMAssertCount(LinkToAllPrimitiveDictionaries, 0, @"ANY link.anyUUIDObj = %@", uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"));
    RLMAssertCount(LinkToAllPrimitiveDictionaries, 1, @"ANY link.boolObj = %@", @NO);
    RLMAssertCount(LinkToAllOptionalPrimitiveDictionaries, 1, @"ANY link.boolObj = %@", @NO);
    RLMAssertCount(LinkToAllPrimitiveDictionaries, 1, @"ANY link.intObj = %@", @2);
    RLMAssertCount(LinkToAllOptionalPrimitiveDictionaries, 1, @"ANY link.intObj = %@", @2);
    RLMAssertCount(LinkToAllPrimitiveDictionaries, 1, @"ANY link.stringObj = %@", @"bar");
    RLMAssertCount(LinkToAllOptionalPrimitiveDictionaries, 1, @"ANY link.stringObj = %@", @"bar");
    RLMAssertCount(LinkToAllPrimitiveDictionaries, 1, @"ANY link.dateObj = %@", date(1));
    RLMAssertCount(LinkToAllOptionalPrimitiveDictionaries, 1, @"ANY link.dateObj = %@", date(1));
    RLMAssertCount(LinkToAllPrimitiveDictionaries, 1, @"ANY link.anyBoolObj = %@", @NO);
    RLMAssertCount(LinkToAllPrimitiveDictionaries, 1, @"ANY link.anyIntObj = %@", @2);
    RLMAssertCount(LinkToAllPrimitiveDictionaries, 1, @"ANY link.anyFloatObj = %@", @2.2f);
    RLMAssertCount(LinkToAllPrimitiveDictionaries, 1, @"ANY link.anyDoubleObj = %@", @2.2);
    RLMAssertCount(LinkToAllPrimitiveDictionaries, 1, @"ANY link.anyStringObj = %@", @"a");
    RLMAssertCount(LinkToAllPrimitiveDictionaries, 1, @"ANY link.anyDataObj = %@", data(1));
    RLMAssertCount(LinkToAllPrimitiveDictionaries, 1, @"ANY link.anyDateObj = %@", date(1));
    RLMAssertCount(LinkToAllPrimitiveDictionaries, 1, @"ANY link.anyDecimalObj = %@", decimal128(2));
    RLMAssertCount(LinkToAllPrimitiveDictionaries, 1, @"ANY link.anyUUIDObj = %@", uuid(@"00000000-0000-0000-0000-000000000000"));
    RLMAssertCount(LinkToAllPrimitiveDictionaries, 0, @"ANY link.boolObj != %@", @NO);
    RLMAssertCount(LinkToAllOptionalPrimitiveDictionaries, 0, @"ANY link.boolObj != %@", @NO);
    RLMAssertCount(LinkToAllPrimitiveDictionaries, 0, @"ANY link.intObj != %@", @2);
    RLMAssertCount(LinkToAllOptionalPrimitiveDictionaries, 0, @"ANY link.intObj != %@", @2);
    RLMAssertCount(LinkToAllPrimitiveDictionaries, 0, @"ANY link.stringObj != %@", @"bar");
    RLMAssertCount(LinkToAllOptionalPrimitiveDictionaries, 0, @"ANY link.stringObj != %@", @"bar");
    RLMAssertCount(LinkToAllPrimitiveDictionaries, 0, @"ANY link.dateObj != %@", date(1));
    RLMAssertCount(LinkToAllOptionalPrimitiveDictionaries, 0, @"ANY link.dateObj != %@", date(1));
    RLMAssertCount(LinkToAllPrimitiveDictionaries, 0, @"ANY link.anyBoolObj != %@", @NO);
    RLMAssertCount(LinkToAllPrimitiveDictionaries, 0, @"ANY link.anyIntObj != %@", @2);
    RLMAssertCount(LinkToAllPrimitiveDictionaries, 0, @"ANY link.anyFloatObj != %@", @2.2f);
    RLMAssertCount(LinkToAllPrimitiveDictionaries, 0, @"ANY link.anyDoubleObj != %@", @2.2);
    RLMAssertCount(LinkToAllPrimitiveDictionaries, 0, @"ANY link.anyStringObj != %@", @"a");
    RLMAssertCount(LinkToAllPrimitiveDictionaries, 0, @"ANY link.anyDataObj != %@", data(1));
    RLMAssertCount(LinkToAllPrimitiveDictionaries, 0, @"ANY link.anyDateObj != %@", date(1));
    RLMAssertCount(LinkToAllPrimitiveDictionaries, 0, @"ANY link.anyDecimalObj != %@", decimal128(2));
    RLMAssertCount(LinkToAllPrimitiveDictionaries, 0, @"ANY link.anyUUIDObj != %@", uuid(@"00000000-0000-0000-0000-000000000000"));
    RLMAssertCount(LinkToAllPrimitiveDictionaries, 1, @"ANY link.boolObj != %@", @YES);
    RLMAssertCount(LinkToAllOptionalPrimitiveDictionaries, 1, @"ANY link.boolObj != %@", NSNull.null);
    RLMAssertCount(LinkToAllPrimitiveDictionaries, 1, @"ANY link.intObj != %@", @3);
    RLMAssertCount(LinkToAllOptionalPrimitiveDictionaries, 1, @"ANY link.intObj != %@", NSNull.null);
    RLMAssertCount(LinkToAllPrimitiveDictionaries, 1, @"ANY link.stringObj != %@", @"foo");
    RLMAssertCount(LinkToAllOptionalPrimitiveDictionaries, 1, @"ANY link.stringObj != %@", NSNull.null);
    RLMAssertCount(LinkToAllPrimitiveDictionaries, 1, @"ANY link.dateObj != %@", date(2));
    RLMAssertCount(LinkToAllOptionalPrimitiveDictionaries, 1, @"ANY link.dateObj != %@", NSNull.null);
    RLMAssertCount(LinkToAllPrimitiveDictionaries, 1, @"ANY link.anyBoolObj != %@", @YES);
    RLMAssertCount(LinkToAllPrimitiveDictionaries, 1, @"ANY link.anyIntObj != %@", @3);
    RLMAssertCount(LinkToAllPrimitiveDictionaries, 1, @"ANY link.anyFloatObj != %@", @3.3f);
    RLMAssertCount(LinkToAllPrimitiveDictionaries, 1, @"ANY link.anyDoubleObj != %@", @3.3);
    RLMAssertCount(LinkToAllPrimitiveDictionaries, 1, @"ANY link.anyStringObj != %@", @"b");
    RLMAssertCount(LinkToAllPrimitiveDictionaries, 1, @"ANY link.anyDataObj != %@", data(2));
    RLMAssertCount(LinkToAllPrimitiveDictionaries, 1, @"ANY link.anyDateObj != %@", date(2));
    RLMAssertCount(LinkToAllPrimitiveDictionaries, 1, @"ANY link.anyDecimalObj != %@", decimal128(3));
    RLMAssertCount(LinkToAllPrimitiveDictionaries, 1, @"ANY link.anyUUIDObj != %@", uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"));
    RLMAssertCount(LinkToAllPrimitiveDictionaries, 0, @"ANY link.intObj > %@", @2);
    RLMAssertCount(LinkToAllOptionalPrimitiveDictionaries, 0, @"ANY link.intObj > %@", @2);
    RLMAssertCount(LinkToAllPrimitiveDictionaries, 0, @"ANY link.dateObj > %@", date(1));
    RLMAssertCount(LinkToAllOptionalPrimitiveDictionaries, 0, @"ANY link.dateObj > %@", date(1));
    RLMAssertCount(LinkToAllPrimitiveDictionaries, 0, @"ANY link.anyFloatObj > %@", @2.2f);
    RLMAssertCount(LinkToAllPrimitiveDictionaries, 0, @"ANY link.anyDoubleObj > %@", @2.2);
    RLMAssertCount(LinkToAllPrimitiveDictionaries, 0, @"ANY link.anyDecimalObj > %@", decimal128(2));
    RLMAssertCount(LinkToAllPrimitiveDictionaries, 1, @"ANY link.intObj >= %@", @2);
    RLMAssertCount(LinkToAllOptionalPrimitiveDictionaries, 1, @"ANY link.intObj >= %@", @2);
    RLMAssertCount(LinkToAllPrimitiveDictionaries, 1, @"ANY link.dateObj >= %@", date(1));
    RLMAssertCount(LinkToAllOptionalPrimitiveDictionaries, 1, @"ANY link.dateObj >= %@", date(1));
    RLMAssertCount(LinkToAllPrimitiveDictionaries, 1, @"ANY link.anyFloatObj >= %@", @2.2f);
    RLMAssertCount(LinkToAllPrimitiveDictionaries, 1, @"ANY link.anyDoubleObj >= %@", @2.2);
    RLMAssertCount(LinkToAllPrimitiveDictionaries, 1, @"ANY link.anyDecimalObj >= %@", decimal128(2));
    RLMAssertCount(LinkToAllPrimitiveDictionaries, 0, @"ANY link.intObj < %@", @2);
    RLMAssertCount(LinkToAllOptionalPrimitiveDictionaries, 0, @"ANY link.intObj < %@", @2);
    RLMAssertCount(LinkToAllPrimitiveDictionaries, 0, @"ANY link.dateObj < %@", date(1));
    RLMAssertCount(LinkToAllOptionalPrimitiveDictionaries, 0, @"ANY link.dateObj < %@", date(1));
    RLMAssertCount(LinkToAllPrimitiveDictionaries, 0, @"ANY link.anyFloatObj < %@", @2.2f);
    RLMAssertCount(LinkToAllPrimitiveDictionaries, 0, @"ANY link.anyDoubleObj < %@", @2.2);
    RLMAssertCount(LinkToAllPrimitiveDictionaries, 0, @"ANY link.anyDecimalObj < %@", decimal128(2));
    RLMAssertCount(LinkToAllPrimitiveDictionaries, 1, @"ANY link.intObj < %@", @3);
    RLMAssertCount(LinkToAllPrimitiveDictionaries, 1, @"ANY link.dateObj < %@", date(2));
    RLMAssertCount(LinkToAllPrimitiveDictionaries, 1, @"ANY link.anyFloatObj < %@", @3.3f);
    RLMAssertCount(LinkToAllPrimitiveDictionaries, 1, @"ANY link.anyDoubleObj < %@", @3.3);
    RLMAssertCount(LinkToAllPrimitiveDictionaries, 1, @"ANY link.anyDecimalObj < %@", decimal128(3));
    RLMAssertCount(LinkToAllOptionalPrimitiveDictionaries, 0, @"ANY link.intObj < %@", NSNull.null);
    RLMAssertCount(LinkToAllOptionalPrimitiveDictionaries, 0, @"ANY link.dateObj < %@", NSNull.null);
    RLMAssertCount(LinkToAllPrimitiveDictionaries, 1, @"ANY link.intObj <= %@", @2);
    RLMAssertCount(LinkToAllOptionalPrimitiveDictionaries, 1, @"ANY link.intObj <= %@", @2);
    RLMAssertCount(LinkToAllPrimitiveDictionaries, 1, @"ANY link.dateObj <= %@", date(1));
    RLMAssertCount(LinkToAllOptionalPrimitiveDictionaries, 1, @"ANY link.dateObj <= %@", date(1));
    RLMAssertCount(LinkToAllPrimitiveDictionaries, 1, @"ANY link.anyFloatObj <= %@", @2.2f);
    RLMAssertCount(LinkToAllPrimitiveDictionaries, 1, @"ANY link.anyDoubleObj <= %@", @2.2);
    RLMAssertCount(LinkToAllPrimitiveDictionaries, 1, @"ANY link.anyDecimalObj <= %@", decimal128(2));

    RLMAssertThrowsWithReason(([LinkToAllPrimitiveDictionaries objectsInRealm:realm where:@"ANY link.boolObj > %@", @NO]),
                              @"Operator '>' not supported for type 'bool'");
    RLMAssertThrowsWithReason(([LinkToAllOptionalPrimitiveDictionaries objectsInRealm:realm where:@"ANY link.boolObj > %@", @NO]),
                              @"Operator '>' not supported for type 'bool'");
    RLMAssertThrowsWithReason(([LinkToAllPrimitiveDictionaries objectsInRealm:realm where:@"ANY link.stringObj > %@", @"bar"]),
                              @"Operator '>' not supported for string queries on Dictionary.");
    RLMAssertThrowsWithReason(([LinkToAllOptionalPrimitiveDictionaries objectsInRealm:realm where:@"ANY link.stringObj > %@", @"bar"]),
                              @"Operator '>' not supported for string queries on Dictionary.");
    RLMAssertThrowsWithReason(([LinkToAllPrimitiveDictionaries objectsInRealm:realm where:@"ANY link.anyStringObj > %@", @"a"]),
                              @"Operator '>' not supported for string queries on Dictionary.");
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
        RLMAssertCount(AllPrimitiveDictionaries, count, query, value);
        RLMAssertCount(AllOptionalPrimitiveDictionaries, count, query, value);
        RLMAssertCount(AllPrimitiveDictionaries, count, query, value);
        query = [NSString stringWithFormat:@"ANY link.stringObj %@ %%@", operator];
        RLMAssertCount(LinkToAllPrimitiveDictionaries, count, query, value);
        RLMAssertCount(LinkToAllOptionalPrimitiveDictionaries, count, query, value);
        RLMAssertCount(LinkToAllPrimitiveDictionaries, count, query, value);

        query = [NSString stringWithFormat:@"ANY dataObj %@ %%@", operator];
        RLMAssertCount(AllPrimitiveDictionaries, count, query, data);
        RLMAssertCount(AllOptionalPrimitiveDictionaries, count, query, data);
        RLMAssertCount(AllPrimitiveDictionaries, count, query, data);
        query = [NSString stringWithFormat:@"ANY link.dataObj %@ %%@", operator];
        RLMAssertCount(LinkToAllPrimitiveDictionaries, count, query, data);
        RLMAssertCount(LinkToAllOptionalPrimitiveDictionaries, count, query, data);
        RLMAssertCount(LinkToAllPrimitiveDictionaries, count, query, data);
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
