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
    uncheckedAssertNil(managed.boolObj[@"key1"]);
    uncheckedAssertNil(managed.intObj[@"key1"]);
    uncheckedAssertNil(managed.stringObj[@"key1"]);
    uncheckedAssertNil(managed.dateObj[@"key1"]);
    uncheckedAssertNil(managed.anyBoolObj[@"key1"]);
    uncheckedAssertNil(managed.anyIntObj[@"key1"]);
    uncheckedAssertNil(managed.anyFloatObj[@"key1"]);
    uncheckedAssertNil(managed.anyDoubleObj[@"key1"]);
    uncheckedAssertNil(managed.anyStringObj[@"key1"]);
    uncheckedAssertNil(managed.anyDataObj[@"key1"]);
    uncheckedAssertNil(managed.anyDateObj[@"key1"]);
    uncheckedAssertNil(managed.anyDecimalObj[@"key1"]);
    uncheckedAssertNil(managed.anyUUIDObj[@"key1"]);
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
    uncheckedAssertEqualObjects(managed.boolObj[@"key1"], @NO);
    uncheckedAssertEqualObjects(managed.intObj[@"key1"], @2);
    uncheckedAssertEqualObjects(managed.stringObj[@"key1"], @"bar");
    uncheckedAssertEqualObjects(managed.dateObj[@"key1"], date(1));
    uncheckedAssertEqualObjects(managed.anyBoolObj[@"key1"], @NO);
    uncheckedAssertEqualObjects(managed.anyIntObj[@"key1"], @2);
    uncheckedAssertEqualObjects(managed.anyFloatObj[@"key1"], @2.2f);
    uncheckedAssertEqualObjects(managed.anyDoubleObj[@"key1"], @2.2);
    uncheckedAssertEqualObjects(managed.anyStringObj[@"key1"], @"a");
    uncheckedAssertEqualObjects(managed.anyDataObj[@"key1"], data(1));
    uncheckedAssertEqualObjects(managed.anyDateObj[@"key1"], date(1));
    uncheckedAssertEqualObjects(managed.anyDecimalObj[@"key1"], decimal128(2));
    uncheckedAssertEqualObjects(managed.anyUUIDObj[@"key1"], uuid(@"00000000-0000-0000-0000-000000000000"));
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
    uncheckedAssertNil(managed.boolObj[@"key1"]);
    uncheckedAssertNil(managed.intObj[@"key1"]);
    uncheckedAssertNil(managed.stringObj[@"key1"]);
    uncheckedAssertNil(managed.dateObj[@"key1"]);
    uncheckedAssertNil(managed.anyBoolObj[@"key1"]);
    uncheckedAssertNil(managed.anyIntObj[@"key1"]);
    uncheckedAssertNil(managed.anyFloatObj[@"key1"]);
    uncheckedAssertNil(managed.anyDoubleObj[@"key1"]);
    uncheckedAssertNil(managed.anyStringObj[@"key1"]);
    uncheckedAssertNil(managed.anyDataObj[@"key1"]);
    uncheckedAssertNil(managed.anyDateObj[@"key1"]);
    uncheckedAssertNil(managed.anyDecimalObj[@"key1"]);
    uncheckedAssertNil(managed.anyUUIDObj[@"key1"]);

    // Managed optional
    uncheckedAssertNil(optManaged.boolObj[@"key1"]);
    uncheckedAssertNil(optManaged.intObj[@"key1"]);
    uncheckedAssertNil(optManaged.stringObj[@"key1"]);
    uncheckedAssertNil(optManaged.dateObj[@"key1"]);
    XCTAssertNoThrow(optManaged.boolObj[@"key1"] = @NO);
    XCTAssertNoThrow(optManaged.intObj[@"key1"] = @2);
    XCTAssertNoThrow(optManaged.stringObj[@"key1"] = @"bar");
    XCTAssertNoThrow(optManaged.dateObj[@"key1"] = date(1));
    uncheckedAssertEqualObjects(optManaged.boolObj[@"key1"], @NO);
    uncheckedAssertEqualObjects(optManaged.intObj[@"key1"], @2);
    uncheckedAssertEqualObjects(optManaged.stringObj[@"key1"], @"bar");
    uncheckedAssertEqualObjects(optManaged.dateObj[@"key1"], date(1));
    XCTAssertNoThrow(optManaged.boolObj[@"key1"] = (id)NSNull.null);
    XCTAssertNoThrow(optManaged.intObj[@"key1"] = (id)NSNull.null);
    XCTAssertNoThrow(optManaged.stringObj[@"key1"] = (id)NSNull.null);
    XCTAssertNoThrow(optManaged.dateObj[@"key1"] = (id)NSNull.null);
    uncheckedAssertEqualObjects(optManaged.boolObj[@"key1"], (id)NSNull.null);
    uncheckedAssertEqualObjects(optManaged.intObj[@"key1"], (id)NSNull.null);
    uncheckedAssertEqualObjects(optManaged.stringObj[@"key1"], (id)NSNull.null);
    uncheckedAssertEqualObjects(optManaged.dateObj[@"key1"], (id)NSNull.null);
    XCTAssertNoThrow(optManaged.boolObj[@"key1"] = nil);
    XCTAssertNoThrow(optManaged.intObj[@"key1"] = nil);
    XCTAssertNoThrow(optManaged.stringObj[@"key1"] = nil);
    XCTAssertNoThrow(optManaged.dateObj[@"key1"] = nil);
    uncheckedAssertNil(optManaged.boolObj[@"key1"]);
    uncheckedAssertNil(optManaged.intObj[@"key1"]);
    uncheckedAssertNil(optManaged.stringObj[@"key1"]);
    uncheckedAssertNil(optManaged.dateObj[@"key1"]);

    // Unmanaged non-optional
    uncheckedAssertNil(unmanaged.boolObj[@"key1"]);
    uncheckedAssertNil(unmanaged.intObj[@"key1"]);
    uncheckedAssertNil(unmanaged.stringObj[@"key1"]);
    uncheckedAssertNil(unmanaged.dateObj[@"key1"]);
    uncheckedAssertNil(unmanaged.floatObj[@"key1"]);
    uncheckedAssertNil(unmanaged.doubleObj[@"key1"]);
    uncheckedAssertNil(unmanaged.dataObj[@"key1"]);
    uncheckedAssertNil(unmanaged.decimalObj[@"key1"]);
    uncheckedAssertNil(unmanaged.objectIdObj[@"key1"]);
    uncheckedAssertNil(unmanaged.uuidObj[@"key1"]);
    uncheckedAssertNil(unmanaged.anyBoolObj[@"key1"]);
    uncheckedAssertNil(unmanaged.anyIntObj[@"key1"]);
    uncheckedAssertNil(unmanaged.anyFloatObj[@"key1"]);
    uncheckedAssertNil(unmanaged.anyDoubleObj[@"key1"]);
    uncheckedAssertNil(unmanaged.anyStringObj[@"key1"]);
    uncheckedAssertNil(unmanaged.anyDataObj[@"key1"]);
    uncheckedAssertNil(unmanaged.anyDateObj[@"key1"]);
    uncheckedAssertNil(unmanaged.anyDecimalObj[@"key1"]);
    uncheckedAssertNil(unmanaged.anyObjectIdObj[@"key1"]);
    uncheckedAssertNil(unmanaged.anyUUIDObj[@"key1"]);
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
    uncheckedAssertEqualObjects(unmanaged.boolObj[@"key1"], @NO);
    uncheckedAssertEqualObjects(unmanaged.intObj[@"key1"], @2);
    uncheckedAssertEqualObjects(unmanaged.stringObj[@"key1"], @"bar");
    uncheckedAssertEqualObjects(unmanaged.dateObj[@"key1"], date(1));
    uncheckedAssertEqualObjects(unmanaged.floatObj[@"key1"], @2.2f);
    uncheckedAssertEqualObjects(unmanaged.doubleObj[@"key1"], @2.2);
    uncheckedAssertEqualObjects(unmanaged.dataObj[@"key1"], data(1));
    uncheckedAssertEqualObjects(unmanaged.decimalObj[@"key1"], decimal128(2));
    uncheckedAssertEqualObjects(unmanaged.objectIdObj[@"key1"], objectId(1));
    uncheckedAssertEqualObjects(unmanaged.uuidObj[@"key1"], uuid(@"00000000-0000-0000-0000-000000000000"));
    uncheckedAssertEqualObjects(unmanaged.anyBoolObj[@"key1"], @NO);
    uncheckedAssertEqualObjects(unmanaged.anyIntObj[@"key1"], @2);
    uncheckedAssertEqualObjects(unmanaged.anyFloatObj[@"key1"], @2.2f);
    uncheckedAssertEqualObjects(unmanaged.anyDoubleObj[@"key1"], @2.2);
    uncheckedAssertEqualObjects(unmanaged.anyStringObj[@"key1"], @"a");
    uncheckedAssertEqualObjects(unmanaged.anyDataObj[@"key1"], data(1));
    uncheckedAssertEqualObjects(unmanaged.anyDateObj[@"key1"], date(1));
    uncheckedAssertEqualObjects(unmanaged.anyDecimalObj[@"key1"], decimal128(2));
    uncheckedAssertEqualObjects(unmanaged.anyObjectIdObj[@"key1"], objectId(1));
    uncheckedAssertEqualObjects(unmanaged.anyUUIDObj[@"key1"], uuid(@"00000000-0000-0000-0000-000000000000"));
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
    uncheckedAssertNil(unmanaged.boolObj[@"key1"]);
    uncheckedAssertNil(unmanaged.intObj[@"key1"]);
    uncheckedAssertNil(unmanaged.stringObj[@"key1"]);
    uncheckedAssertNil(unmanaged.dateObj[@"key1"]);
    uncheckedAssertNil(unmanaged.floatObj[@"key1"]);
    uncheckedAssertNil(unmanaged.doubleObj[@"key1"]);
    uncheckedAssertNil(unmanaged.dataObj[@"key1"]);
    uncheckedAssertNil(unmanaged.decimalObj[@"key1"]);
    uncheckedAssertNil(unmanaged.objectIdObj[@"key1"]);
    uncheckedAssertNil(unmanaged.uuidObj[@"key1"]);
    uncheckedAssertNil(unmanaged.anyBoolObj[@"key1"]);
    uncheckedAssertNil(unmanaged.anyIntObj[@"key1"]);
    uncheckedAssertNil(unmanaged.anyFloatObj[@"key1"]);
    uncheckedAssertNil(unmanaged.anyDoubleObj[@"key1"]);
    uncheckedAssertNil(unmanaged.anyStringObj[@"key1"]);
    uncheckedAssertNil(unmanaged.anyDataObj[@"key1"]);
    uncheckedAssertNil(unmanaged.anyDateObj[@"key1"]);
    uncheckedAssertNil(unmanaged.anyDecimalObj[@"key1"]);
    uncheckedAssertNil(unmanaged.anyObjectIdObj[@"key1"]);
    uncheckedAssertNil(unmanaged.anyUUIDObj[@"key1"]);

    // Unmanaged optional
    uncheckedAssertNil(optUnmanaged.boolObj[@"key1"]);
    uncheckedAssertNil(optUnmanaged.intObj[@"key1"]);
    uncheckedAssertNil(optUnmanaged.stringObj[@"key1"]);
    uncheckedAssertNil(optUnmanaged.dateObj[@"key1"]);
    uncheckedAssertNil(optUnmanaged.floatObj[@"key1"]);
    uncheckedAssertNil(optUnmanaged.doubleObj[@"key1"]);
    uncheckedAssertNil(optUnmanaged.dataObj[@"key1"]);
    uncheckedAssertNil(optUnmanaged.decimalObj[@"key1"]);
    uncheckedAssertNil(optUnmanaged.objectIdObj[@"key1"]);
    uncheckedAssertNil(optUnmanaged.uuidObj[@"key1"]);
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
    uncheckedAssertEqualObjects(optUnmanaged.boolObj[@"key1"], @NO);
    uncheckedAssertEqualObjects(optUnmanaged.intObj[@"key1"], @2);
    uncheckedAssertEqualObjects(optUnmanaged.stringObj[@"key1"], @"bar");
    uncheckedAssertEqualObjects(optUnmanaged.dateObj[@"key1"], date(1));
    uncheckedAssertEqualObjects(optUnmanaged.floatObj[@"key1"], @2.2f);
    uncheckedAssertEqualObjects(optUnmanaged.doubleObj[@"key1"], @2.2);
    uncheckedAssertEqualObjects(optUnmanaged.dataObj[@"key1"], data(1));
    uncheckedAssertEqualObjects(optUnmanaged.decimalObj[@"key1"], decimal128(2));
    uncheckedAssertEqualObjects(optUnmanaged.objectIdObj[@"key1"], objectId(1));
    uncheckedAssertEqualObjects(optUnmanaged.uuidObj[@"key1"], uuid(@"00000000-0000-0000-0000-000000000000"));
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
    uncheckedAssertEqual(optUnmanaged.boolObj[@"key1"], (id)NSNull.null);
    uncheckedAssertEqual(optUnmanaged.intObj[@"key1"], (id)NSNull.null);
    uncheckedAssertEqual(optUnmanaged.stringObj[@"key1"], (id)NSNull.null);
    uncheckedAssertEqual(optUnmanaged.dateObj[@"key1"], (id)NSNull.null);
    uncheckedAssertEqual(optUnmanaged.floatObj[@"key1"], (id)NSNull.null);
    uncheckedAssertEqual(optUnmanaged.doubleObj[@"key1"], (id)NSNull.null);
    uncheckedAssertEqual(optUnmanaged.dataObj[@"key1"], (id)NSNull.null);
    uncheckedAssertEqual(optUnmanaged.decimalObj[@"key1"], (id)NSNull.null);
    uncheckedAssertEqual(optUnmanaged.objectIdObj[@"key1"], (id)NSNull.null);
    uncheckedAssertEqual(optUnmanaged.uuidObj[@"key1"], (id)NSNull.null);
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
    uncheckedAssertNil(optUnmanaged.boolObj[@"key1"]);
    uncheckedAssertNil(optUnmanaged.intObj[@"key1"]);
    uncheckedAssertNil(optUnmanaged.stringObj[@"key1"]);
    uncheckedAssertNil(optUnmanaged.dateObj[@"key1"]);
    uncheckedAssertNil(optUnmanaged.floatObj[@"key1"]);
    uncheckedAssertNil(optUnmanaged.doubleObj[@"key1"]);
    uncheckedAssertNil(optUnmanaged.dataObj[@"key1"]);
    uncheckedAssertNil(optUnmanaged.decimalObj[@"key1"]);
    uncheckedAssertNil(optUnmanaged.objectIdObj[@"key1"]);
    uncheckedAssertNil(optUnmanaged.uuidObj[@"key1"]);

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
                              @"Invalid value 'a' of type '" RLMConstantString "' for expected type 'bool'");
    RLMAssertThrowsWithReason([optUnmanaged.boolObj setObject:(id)@"a" forKey:@"key1"],
                              @"Invalid value 'a' of type '" RLMConstantString "' for expected type 'bool?'");
    RLMAssertThrowsWithReason([managed.boolObj setObject:(id)@"a" forKey:@"key1"],
                              @"Invalid value 'a' of type '" RLMConstantString "' for expected type 'bool'");
    RLMAssertThrowsWithReason([optManaged.boolObj setObject:(id)@"a" forKey:@"key1"],
                              @"Invalid value 'a' of type '" RLMConstantString "' for expected type 'bool?'");
    RLMAssertThrowsWithReason([unmanaged.intObj setObject:(id)@"a" forKey:@"key1"],
                              @"Invalid value 'a' of type '" RLMConstantString "' for expected type 'int'");
    RLMAssertThrowsWithReason([optUnmanaged.intObj setObject:(id)@"a" forKey:@"key1"],
                              @"Invalid value 'a' of type '" RLMConstantString "' for expected type 'int?'");
    RLMAssertThrowsWithReason([managed.intObj setObject:(id)@"a" forKey:@"key1"],
                              @"Invalid value 'a' of type '" RLMConstantString "' for expected type 'int'");
    RLMAssertThrowsWithReason([optManaged.intObj setObject:(id)@"a" forKey:@"key1"],
                              @"Invalid value 'a' of type '" RLMConstantString "' for expected type 'int?'");
    RLMAssertThrowsWithReason([unmanaged.stringObj setObject:(id)@2 forKey:@"key1"],
                              @"Invalid value '2' of type '" RLMConstantInt "' for expected type 'string'");
    RLMAssertThrowsWithReason([optUnmanaged.stringObj setObject:(id)@2 forKey:@"key1"],
                              @"Invalid value '2' of type '" RLMConstantInt "' for expected type 'string?'");
    RLMAssertThrowsWithReason([managed.stringObj setObject:(id)@2 forKey:@"key1"],
                              @"Invalid value '2' of type '" RLMConstantInt "' for expected type 'string'");
    RLMAssertThrowsWithReason([optManaged.stringObj setObject:(id)@2 forKey:@"key1"],
                              @"Invalid value '2' of type '" RLMConstantInt "' for expected type 'string?'");
    RLMAssertThrowsWithReason([unmanaged.dateObj setObject:(id)@"a" forKey:@"key1"],
                              @"Invalid value 'a' of type '" RLMConstantString "' for expected type 'date'");
    RLMAssertThrowsWithReason([optUnmanaged.dateObj setObject:(id)@"a" forKey:@"key1"],
                              @"Invalid value 'a' of type '" RLMConstantString "' for expected type 'date?'");
    RLMAssertThrowsWithReason([managed.dateObj setObject:(id)@"a" forKey:@"key1"],
                              @"Invalid value 'a' of type '" RLMConstantString "' for expected type 'date'");
    RLMAssertThrowsWithReason([optManaged.dateObj setObject:(id)@"a" forKey:@"key1"],
                              @"Invalid value 'a' of type '" RLMConstantString "' for expected type 'date?'");
    RLMAssertThrowsWithReason([unmanaged.floatObj setObject:(id)@"a" forKey:@"key1"],
                              @"Invalid value 'a' of type '" RLMConstantString "' for expected type 'float'");
    RLMAssertThrowsWithReason([optUnmanaged.floatObj setObject:(id)@"a" forKey:@"key1"],
                              @"Invalid value 'a' of type '" RLMConstantString "' for expected type 'float?'");
    RLMAssertThrowsWithReason([managed.floatObj setObject:(id)@"a" forKey:@"key1"],
                              @"Invalid value 'a' of type '" RLMConstantString "' for expected type 'float'");
    RLMAssertThrowsWithReason([optManaged.floatObj setObject:(id)@"a" forKey:@"key1"],
                              @"Invalid value 'a' of type '" RLMConstantString "' for expected type 'float?'");
    RLMAssertThrowsWithReason([unmanaged.doubleObj setObject:(id)@"a" forKey:@"key1"],
                              @"Invalid value 'a' of type '" RLMConstantString "' for expected type 'double'");
    RLMAssertThrowsWithReason([optUnmanaged.doubleObj setObject:(id)@"a" forKey:@"key1"],
                              @"Invalid value 'a' of type '" RLMConstantString "' for expected type 'double?'");
    RLMAssertThrowsWithReason([managed.doubleObj setObject:(id)@"a" forKey:@"key1"],
                              @"Invalid value 'a' of type '" RLMConstantString "' for expected type 'double'");
    RLMAssertThrowsWithReason([optManaged.doubleObj setObject:(id)@"a" forKey:@"key1"],
                              @"Invalid value 'a' of type '" RLMConstantString "' for expected type 'double?'");
    RLMAssertThrowsWithReason([unmanaged.dataObj setObject:(id)@"a" forKey:@"key1"],
                              @"Invalid value 'a' of type '" RLMConstantString "' for expected type 'data'");
    RLMAssertThrowsWithReason([optUnmanaged.dataObj setObject:(id)@"a" forKey:@"key1"],
                              @"Invalid value 'a' of type '" RLMConstantString "' for expected type 'data?'");
    RLMAssertThrowsWithReason([managed.dataObj setObject:(id)@"a" forKey:@"key1"],
                              @"Invalid value 'a' of type '" RLMConstantString "' for expected type 'data'");
    RLMAssertThrowsWithReason([optManaged.dataObj setObject:(id)@"a" forKey:@"key1"],
                              @"Invalid value 'a' of type '" RLMConstantString "' for expected type 'data?'");
    RLMAssertThrowsWithReason([unmanaged.decimalObj setObject:(id)@"a" forKey:@"key1"],
                              @"Invalid value 'a' of type '" RLMConstantString "' for expected type 'decimal128'");
    RLMAssertThrowsWithReason([optUnmanaged.decimalObj setObject:(id)@"a" forKey:@"key1"],
                              @"Invalid value 'a' of type '" RLMConstantString "' for expected type 'decimal128?'");
    RLMAssertThrowsWithReason([managed.decimalObj setObject:(id)@"a" forKey:@"key1"],
                              @"Invalid value 'a' of type '" RLMConstantString "' for expected type 'decimal128'");
    RLMAssertThrowsWithReason([optManaged.decimalObj setObject:(id)@"a" forKey:@"key1"],
                              @"Invalid value 'a' of type '" RLMConstantString "' for expected type 'decimal128?'");
    RLMAssertThrowsWithReason([unmanaged.objectIdObj setObject:(id)@"a" forKey:@"key1"],
                              @"Invalid value 'a' of type '" RLMConstantString "' for expected type 'object id'");
    RLMAssertThrowsWithReason([optUnmanaged.objectIdObj setObject:(id)@"a" forKey:@"key1"],
                              @"Invalid value 'a' of type '" RLMConstantString "' for expected type 'object id?'");
    RLMAssertThrowsWithReason([managed.objectIdObj setObject:(id)@"a" forKey:@"key1"],
                              @"Invalid value 'a' of type '" RLMConstantString "' for expected type 'object id'");
    RLMAssertThrowsWithReason([optManaged.objectIdObj setObject:(id)@"a" forKey:@"key1"],
                              @"Invalid value 'a' of type '" RLMConstantString "' for expected type 'object id?'");
    RLMAssertThrowsWithReason([unmanaged.uuidObj setObject:(id)@"a" forKey:@"key1"],
                              @"Invalid value 'a' of type '" RLMConstantString "' for expected type 'uuid'");
    RLMAssertThrowsWithReason([optUnmanaged.uuidObj setObject:(id)@"a" forKey:@"key1"],
                              @"Invalid value 'a' of type '" RLMConstantString "' for expected type 'uuid?'");
    RLMAssertThrowsWithReason([managed.uuidObj setObject:(id)@"a" forKey:@"key1"],
                              @"Invalid value 'a' of type '" RLMConstantString "' for expected type 'uuid'");
    RLMAssertThrowsWithReason([optManaged.uuidObj setObject:(id)@"a" forKey:@"key1"],
                              @"Invalid value 'a' of type '" RLMConstantString "' for expected type 'uuid?'");
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
    uncheckedAssertEqualObjects(unmanaged.boolObj[@"key1"], @NO);
    uncheckedAssertEqualObjects(optUnmanaged.boolObj[@"key1"], @NO);
    uncheckedAssertEqualObjects(managed.boolObj[@"key1"], @NO);
    uncheckedAssertEqualObjects(optManaged.boolObj[@"key1"], @NO);
    uncheckedAssertEqualObjects(unmanaged.intObj[@"key1"], @2);
    uncheckedAssertEqualObjects(optUnmanaged.intObj[@"key1"], @2);
    uncheckedAssertEqualObjects(managed.intObj[@"key1"], @2);
    uncheckedAssertEqualObjects(optManaged.intObj[@"key1"], @2);
    uncheckedAssertEqualObjects(unmanaged.stringObj[@"key1"], @"bar");
    uncheckedAssertEqualObjects(optUnmanaged.stringObj[@"key1"], @"bar");
    uncheckedAssertEqualObjects(managed.stringObj[@"key1"], @"bar");
    uncheckedAssertEqualObjects(optManaged.stringObj[@"key1"], @"bar");
    uncheckedAssertEqualObjects(unmanaged.dateObj[@"key1"], date(1));
    uncheckedAssertEqualObjects(optUnmanaged.dateObj[@"key1"], date(1));
    uncheckedAssertEqualObjects(managed.dateObj[@"key1"], date(1));
    uncheckedAssertEqualObjects(optManaged.dateObj[@"key1"], date(1));
    uncheckedAssertEqualObjects(unmanaged.floatObj[@"key1"], @2.2f);
    uncheckedAssertEqualObjects(optUnmanaged.floatObj[@"key1"], @2.2f);
    uncheckedAssertEqualObjects(managed.floatObj[@"key1"], @2.2f);
    uncheckedAssertEqualObjects(optManaged.floatObj[@"key1"], @2.2f);
    uncheckedAssertEqualObjects(unmanaged.doubleObj[@"key1"], @2.2);
    uncheckedAssertEqualObjects(optUnmanaged.doubleObj[@"key1"], @2.2);
    uncheckedAssertEqualObjects(managed.doubleObj[@"key1"], @2.2);
    uncheckedAssertEqualObjects(optManaged.doubleObj[@"key1"], @2.2);
    uncheckedAssertEqualObjects(unmanaged.dataObj[@"key1"], data(1));
    uncheckedAssertEqualObjects(optUnmanaged.dataObj[@"key1"], data(1));
    uncheckedAssertEqualObjects(managed.dataObj[@"key1"], data(1));
    uncheckedAssertEqualObjects(optManaged.dataObj[@"key1"], data(1));
    uncheckedAssertEqualObjects(unmanaged.decimalObj[@"key1"], decimal128(2));
    uncheckedAssertEqualObjects(optUnmanaged.decimalObj[@"key1"], decimal128(2));
    uncheckedAssertEqualObjects(managed.decimalObj[@"key1"], decimal128(2));
    uncheckedAssertEqualObjects(optManaged.decimalObj[@"key1"], decimal128(2));
    uncheckedAssertEqualObjects(unmanaged.objectIdObj[@"key1"], objectId(1));
    uncheckedAssertEqualObjects(optUnmanaged.objectIdObj[@"key1"], objectId(1));
    uncheckedAssertEqualObjects(managed.objectIdObj[@"key1"], objectId(1));
    uncheckedAssertEqualObjects(optManaged.objectIdObj[@"key1"], objectId(1));
    uncheckedAssertEqualObjects(unmanaged.uuidObj[@"key1"], uuid(@"00000000-0000-0000-0000-000000000000"));
    uncheckedAssertEqualObjects(optUnmanaged.uuidObj[@"key1"], uuid(@"00000000-0000-0000-0000-000000000000"));
    uncheckedAssertEqualObjects(managed.uuidObj[@"key1"], uuid(@"00000000-0000-0000-0000-000000000000"));
    uncheckedAssertEqualObjects(optManaged.uuidObj[@"key1"], uuid(@"00000000-0000-0000-0000-000000000000"));
    uncheckedAssertEqualObjects(unmanaged.anyBoolObj[@"key1"], @NO);
    uncheckedAssertEqualObjects(unmanaged.anyIntObj[@"key1"], @2);
    uncheckedAssertEqualObjects(unmanaged.anyFloatObj[@"key1"], @2.2f);
    uncheckedAssertEqualObjects(unmanaged.anyDoubleObj[@"key1"], @2.2);
    uncheckedAssertEqualObjects(unmanaged.anyStringObj[@"key1"], @"a");
    uncheckedAssertEqualObjects(unmanaged.anyDataObj[@"key1"], data(1));
    uncheckedAssertEqualObjects(unmanaged.anyDateObj[@"key1"], date(1));
    uncheckedAssertEqualObjects(unmanaged.anyDecimalObj[@"key1"], decimal128(2));
    uncheckedAssertEqualObjects(unmanaged.anyObjectIdObj[@"key1"], objectId(1));
    uncheckedAssertEqualObjects(unmanaged.anyUUIDObj[@"key1"], uuid(@"00000000-0000-0000-0000-000000000000"));
    uncheckedAssertEqualObjects(managed.anyBoolObj[@"key1"], @NO);
    uncheckedAssertEqualObjects(managed.anyIntObj[@"key1"], @2);
    uncheckedAssertEqualObjects(managed.anyFloatObj[@"key1"], @2.2f);
    uncheckedAssertEqualObjects(managed.anyDoubleObj[@"key1"], @2.2);
    uncheckedAssertEqualObjects(managed.anyStringObj[@"key1"], @"a");
    uncheckedAssertEqualObjects(managed.anyDataObj[@"key1"], data(1));
    uncheckedAssertEqualObjects(managed.anyDateObj[@"key1"], date(1));
    uncheckedAssertEqualObjects(managed.anyDecimalObj[@"key1"], decimal128(2));
    uncheckedAssertEqualObjects(managed.anyObjectIdObj[@"key1"], objectId(1));
    uncheckedAssertEqualObjects(managed.anyUUIDObj[@"key1"], uuid(@"00000000-0000-0000-0000-000000000000"));

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
    uncheckedAssertEqualObjects(optUnmanaged.boolObj[@"key1"], (id)NSNull.null);
    uncheckedAssertEqualObjects(optManaged.boolObj[@"key1"], (id)NSNull.null);
    uncheckedAssertEqualObjects(optUnmanaged.intObj[@"key1"], (id)NSNull.null);
    uncheckedAssertEqualObjects(optManaged.intObj[@"key1"], (id)NSNull.null);
    uncheckedAssertEqualObjects(optUnmanaged.stringObj[@"key1"], (id)NSNull.null);
    uncheckedAssertEqualObjects(optManaged.stringObj[@"key1"], (id)NSNull.null);
    uncheckedAssertEqualObjects(optUnmanaged.dateObj[@"key1"], (id)NSNull.null);
    uncheckedAssertEqualObjects(optManaged.dateObj[@"key1"], (id)NSNull.null);
    uncheckedAssertEqualObjects(optUnmanaged.floatObj[@"key1"], (id)NSNull.null);
    uncheckedAssertEqualObjects(optManaged.floatObj[@"key1"], (id)NSNull.null);
    uncheckedAssertEqualObjects(optUnmanaged.doubleObj[@"key1"], (id)NSNull.null);
    uncheckedAssertEqualObjects(optManaged.doubleObj[@"key1"], (id)NSNull.null);
    uncheckedAssertEqualObjects(optUnmanaged.dataObj[@"key1"], (id)NSNull.null);
    uncheckedAssertEqualObjects(optManaged.dataObj[@"key1"], (id)NSNull.null);
    uncheckedAssertEqualObjects(optUnmanaged.decimalObj[@"key1"], (id)NSNull.null);
    uncheckedAssertEqualObjects(optManaged.decimalObj[@"key1"], (id)NSNull.null);
    uncheckedAssertEqualObjects(optUnmanaged.objectIdObj[@"key1"], (id)NSNull.null);
    uncheckedAssertEqualObjects(optManaged.objectIdObj[@"key1"], (id)NSNull.null);
    uncheckedAssertEqualObjects(optUnmanaged.uuidObj[@"key1"], (id)NSNull.null);
    uncheckedAssertEqualObjects(optManaged.uuidObj[@"key1"], (id)NSNull.null);
}
#pragma clang diagnostic pop

- (void)testAddObjects {
    RLMAssertThrowsWithReason([unmanaged.boolObj addEntriesFromDictionary:@{@"key1": @"a"}],
                              @"Invalid value 'a' of type '" RLMConstantString "' for expected type 'bool'");
    RLMAssertThrowsWithReason([optUnmanaged.boolObj addEntriesFromDictionary:@{@"key1": @"a"}],
                              @"Invalid value 'a' of type '" RLMConstantString "' for expected type 'bool?'");
    RLMAssertThrowsWithReason([managed.boolObj addEntriesFromDictionary:@{@"key1": @"a"}],
                              @"Invalid value 'a' of type '" RLMConstantString "' for expected type 'bool'");
    RLMAssertThrowsWithReason([optManaged.boolObj addEntriesFromDictionary:@{@"key1": @"a"}],
                              @"Invalid value 'a' of type '" RLMConstantString "' for expected type 'bool?'");
    RLMAssertThrowsWithReason([unmanaged.intObj addEntriesFromDictionary:@{@"key1": @"a"}],
                              @"Invalid value 'a' of type '" RLMConstantString "' for expected type 'int'");
    RLMAssertThrowsWithReason([optUnmanaged.intObj addEntriesFromDictionary:@{@"key1": @"a"}],
                              @"Invalid value 'a' of type '" RLMConstantString "' for expected type 'int?'");
    RLMAssertThrowsWithReason([managed.intObj addEntriesFromDictionary:@{@"key1": @"a"}],
                              @"Invalid value 'a' of type '" RLMConstantString "' for expected type 'int'");
    RLMAssertThrowsWithReason([optManaged.intObj addEntriesFromDictionary:@{@"key1": @"a"}],
                              @"Invalid value 'a' of type '" RLMConstantString "' for expected type 'int?'");
    RLMAssertThrowsWithReason([unmanaged.stringObj addEntriesFromDictionary:@{@"key1": @2}],
                              @"Invalid value '2' of type '" RLMConstantInt "' for expected type 'string'");
    RLMAssertThrowsWithReason([optUnmanaged.stringObj addEntriesFromDictionary:@{@"key1": @2}],
                              @"Invalid value '2' of type '" RLMConstantInt "' for expected type 'string?'");
    RLMAssertThrowsWithReason([managed.stringObj addEntriesFromDictionary:@{@"key1": @2}],
                              @"Invalid value '2' of type '" RLMConstantInt "' for expected type 'string'");
    RLMAssertThrowsWithReason([optManaged.stringObj addEntriesFromDictionary:@{@"key1": @2}],
                              @"Invalid value '2' of type '" RLMConstantInt "' for expected type 'string?'");
    RLMAssertThrowsWithReason([unmanaged.dateObj addEntriesFromDictionary:@{@"key1": @"a"}],
                              @"Invalid value 'a' of type '" RLMConstantString "' for expected type 'date'");
    RLMAssertThrowsWithReason([optUnmanaged.dateObj addEntriesFromDictionary:@{@"key1": @"a"}],
                              @"Invalid value 'a' of type '" RLMConstantString "' for expected type 'date?'");
    RLMAssertThrowsWithReason([managed.dateObj addEntriesFromDictionary:@{@"key1": @"a"}],
                              @"Invalid value 'a' of type '" RLMConstantString "' for expected type 'date'");
    RLMAssertThrowsWithReason([optManaged.dateObj addEntriesFromDictionary:@{@"key1": @"a"}],
                              @"Invalid value 'a' of type '" RLMConstantString "' for expected type 'date?'");
    RLMAssertThrowsWithReason([unmanaged.floatObj addEntriesFromDictionary:@{@"key1": @"a"}],
                              @"Invalid value 'a' of type '" RLMConstantString "' for expected type 'float'");
    RLMAssertThrowsWithReason([optUnmanaged.floatObj addEntriesFromDictionary:@{@"key1": @"a"}],
                              @"Invalid value 'a' of type '" RLMConstantString "' for expected type 'float?'");
    RLMAssertThrowsWithReason([managed.floatObj addEntriesFromDictionary:@{@"key1": @"a"}],
                              @"Invalid value 'a' of type '" RLMConstantString "' for expected type 'float'");
    RLMAssertThrowsWithReason([optManaged.floatObj addEntriesFromDictionary:@{@"key1": @"a"}],
                              @"Invalid value 'a' of type '" RLMConstantString "' for expected type 'float?'");
    RLMAssertThrowsWithReason([unmanaged.doubleObj addEntriesFromDictionary:@{@"key1": @"a"}],
                              @"Invalid value 'a' of type '" RLMConstantString "' for expected type 'double'");
    RLMAssertThrowsWithReason([optUnmanaged.doubleObj addEntriesFromDictionary:@{@"key1": @"a"}],
                              @"Invalid value 'a' of type '" RLMConstantString "' for expected type 'double?'");
    RLMAssertThrowsWithReason([managed.doubleObj addEntriesFromDictionary:@{@"key1": @"a"}],
                              @"Invalid value 'a' of type '" RLMConstantString "' for expected type 'double'");
    RLMAssertThrowsWithReason([optManaged.doubleObj addEntriesFromDictionary:@{@"key1": @"a"}],
                              @"Invalid value 'a' of type '" RLMConstantString "' for expected type 'double?'");
    RLMAssertThrowsWithReason([unmanaged.dataObj addEntriesFromDictionary:@{@"key1": @"a"}],
                              @"Invalid value 'a' of type '" RLMConstantString "' for expected type 'data'");
    RLMAssertThrowsWithReason([optUnmanaged.dataObj addEntriesFromDictionary:@{@"key1": @"a"}],
                              @"Invalid value 'a' of type '" RLMConstantString "' for expected type 'data?'");
    RLMAssertThrowsWithReason([managed.dataObj addEntriesFromDictionary:@{@"key1": @"a"}],
                              @"Invalid value 'a' of type '" RLMConstantString "' for expected type 'data'");
    RLMAssertThrowsWithReason([optManaged.dataObj addEntriesFromDictionary:@{@"key1": @"a"}],
                              @"Invalid value 'a' of type '" RLMConstantString "' for expected type 'data?'");
    RLMAssertThrowsWithReason([unmanaged.decimalObj addEntriesFromDictionary:@{@"key1": @"a"}],
                              @"Invalid value 'a' of type '" RLMConstantString "' for expected type 'decimal128'");
    RLMAssertThrowsWithReason([optUnmanaged.decimalObj addEntriesFromDictionary:@{@"key1": @"a"}],
                              @"Invalid value 'a' of type '" RLMConstantString "' for expected type 'decimal128?'");
    RLMAssertThrowsWithReason([managed.decimalObj addEntriesFromDictionary:@{@"key1": @"a"}],
                              @"Invalid value 'a' of type '" RLMConstantString "' for expected type 'decimal128'");
    RLMAssertThrowsWithReason([optManaged.decimalObj addEntriesFromDictionary:@{@"key1": @"a"}],
                              @"Invalid value 'a' of type '" RLMConstantString "' for expected type 'decimal128?'");
    RLMAssertThrowsWithReason([unmanaged.objectIdObj addEntriesFromDictionary:@{@"key1": @"a"}],
                              @"Invalid value 'a' of type '" RLMConstantString "' for expected type 'object id'");
    RLMAssertThrowsWithReason([optUnmanaged.objectIdObj addEntriesFromDictionary:@{@"key1": @"a"}],
                              @"Invalid value 'a' of type '" RLMConstantString "' for expected type 'object id?'");
    RLMAssertThrowsWithReason([managed.objectIdObj addEntriesFromDictionary:@{@"key1": @"a"}],
                              @"Invalid value 'a' of type '" RLMConstantString "' for expected type 'object id'");
    RLMAssertThrowsWithReason([optManaged.objectIdObj addEntriesFromDictionary:@{@"key1": @"a"}],
                              @"Invalid value 'a' of type '" RLMConstantString "' for expected type 'object id?'");
    RLMAssertThrowsWithReason([unmanaged.uuidObj addEntriesFromDictionary:@{@"key1": @"a"}],
                              @"Invalid value 'a' of type '" RLMConstantString "' for expected type 'uuid'");
    RLMAssertThrowsWithReason([optUnmanaged.uuidObj addEntriesFromDictionary:@{@"key1": @"a"}],
                              @"Invalid value 'a' of type '" RLMConstantString "' for expected type 'uuid?'");
    RLMAssertThrowsWithReason([managed.uuidObj addEntriesFromDictionary:@{@"key1": @"a"}],
                              @"Invalid value 'a' of type '" RLMConstantString "' for expected type 'uuid'");
    RLMAssertThrowsWithReason([optManaged.uuidObj addEntriesFromDictionary:@{@"key1": @"a"}],
                              @"Invalid value 'a' of type '" RLMConstantString "' for expected type 'uuid?'");
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
    uncheckedAssertEqualObjects(unmanaged.boolObj[@"key1"], @NO);
    uncheckedAssertEqualObjects(optUnmanaged.boolObj[@"key1"], @NO);
    uncheckedAssertEqualObjects(managed.boolObj[@"key1"], @NO);
    uncheckedAssertEqualObjects(optManaged.boolObj[@"key1"], @NO);
    uncheckedAssertEqualObjects(unmanaged.intObj[@"key1"], @2);
    uncheckedAssertEqualObjects(optUnmanaged.intObj[@"key1"], @2);
    uncheckedAssertEqualObjects(managed.intObj[@"key1"], @2);
    uncheckedAssertEqualObjects(optManaged.intObj[@"key1"], @2);
    uncheckedAssertEqualObjects(unmanaged.stringObj[@"key1"], @"bar");
    uncheckedAssertEqualObjects(optUnmanaged.stringObj[@"key1"], @"bar");
    uncheckedAssertEqualObjects(managed.stringObj[@"key1"], @"bar");
    uncheckedAssertEqualObjects(optManaged.stringObj[@"key1"], @"bar");
    uncheckedAssertEqualObjects(unmanaged.dateObj[@"key1"], date(1));
    uncheckedAssertEqualObjects(optUnmanaged.dateObj[@"key1"], date(1));
    uncheckedAssertEqualObjects(managed.dateObj[@"key1"], date(1));
    uncheckedAssertEqualObjects(optManaged.dateObj[@"key1"], date(1));
    uncheckedAssertEqualObjects(unmanaged.floatObj[@"key1"], @2.2f);
    uncheckedAssertEqualObjects(optUnmanaged.floatObj[@"key1"], @2.2f);
    uncheckedAssertEqualObjects(managed.floatObj[@"key1"], @2.2f);
    uncheckedAssertEqualObjects(optManaged.floatObj[@"key1"], @2.2f);
    uncheckedAssertEqualObjects(unmanaged.doubleObj[@"key1"], @2.2);
    uncheckedAssertEqualObjects(optUnmanaged.doubleObj[@"key1"], @2.2);
    uncheckedAssertEqualObjects(managed.doubleObj[@"key1"], @2.2);
    uncheckedAssertEqualObjects(optManaged.doubleObj[@"key1"], @2.2);
    uncheckedAssertEqualObjects(unmanaged.dataObj[@"key1"], data(1));
    uncheckedAssertEqualObjects(optUnmanaged.dataObj[@"key1"], data(1));
    uncheckedAssertEqualObjects(managed.dataObj[@"key1"], data(1));
    uncheckedAssertEqualObjects(optManaged.dataObj[@"key1"], data(1));
    uncheckedAssertEqualObjects(unmanaged.decimalObj[@"key1"], decimal128(2));
    uncheckedAssertEqualObjects(optUnmanaged.decimalObj[@"key1"], decimal128(2));
    uncheckedAssertEqualObjects(managed.decimalObj[@"key1"], decimal128(2));
    uncheckedAssertEqualObjects(optManaged.decimalObj[@"key1"], decimal128(2));
    uncheckedAssertEqualObjects(unmanaged.objectIdObj[@"key1"], objectId(1));
    uncheckedAssertEqualObjects(optUnmanaged.objectIdObj[@"key1"], objectId(1));
    uncheckedAssertEqualObjects(managed.objectIdObj[@"key1"], objectId(1));
    uncheckedAssertEqualObjects(optManaged.objectIdObj[@"key1"], objectId(1));
    uncheckedAssertEqualObjects(unmanaged.uuidObj[@"key1"], uuid(@"00000000-0000-0000-0000-000000000000"));
    uncheckedAssertEqualObjects(optUnmanaged.uuidObj[@"key1"], uuid(@"00000000-0000-0000-0000-000000000000"));
    uncheckedAssertEqualObjects(managed.uuidObj[@"key1"], uuid(@"00000000-0000-0000-0000-000000000000"));
    uncheckedAssertEqualObjects(optManaged.uuidObj[@"key1"], uuid(@"00000000-0000-0000-0000-000000000000"));
    uncheckedAssertEqualObjects(unmanaged.anyBoolObj[@"key1"], @NO);
    uncheckedAssertEqualObjects(unmanaged.anyIntObj[@"key1"], @2);
    uncheckedAssertEqualObjects(unmanaged.anyFloatObj[@"key1"], @2.2f);
    uncheckedAssertEqualObjects(unmanaged.anyDoubleObj[@"key1"], @2.2);
    uncheckedAssertEqualObjects(unmanaged.anyStringObj[@"key1"], @"a");
    uncheckedAssertEqualObjects(unmanaged.anyDataObj[@"key1"], data(1));
    uncheckedAssertEqualObjects(unmanaged.anyDateObj[@"key1"], date(1));
    uncheckedAssertEqualObjects(unmanaged.anyDecimalObj[@"key1"], decimal128(2));
    uncheckedAssertEqualObjects(unmanaged.anyObjectIdObj[@"key1"], objectId(1));
    uncheckedAssertEqualObjects(unmanaged.anyUUIDObj[@"key1"], uuid(@"00000000-0000-0000-0000-000000000000"));
    uncheckedAssertEqualObjects(managed.anyBoolObj[@"key1"], @NO);
    uncheckedAssertEqualObjects(managed.anyIntObj[@"key1"], @2);
    uncheckedAssertEqualObjects(managed.anyFloatObj[@"key1"], @2.2f);
    uncheckedAssertEqualObjects(managed.anyDoubleObj[@"key1"], @2.2);
    uncheckedAssertEqualObjects(managed.anyStringObj[@"key1"], @"a");
    uncheckedAssertEqualObjects(managed.anyDataObj[@"key1"], data(1));
    uncheckedAssertEqualObjects(managed.anyDateObj[@"key1"], date(1));
    uncheckedAssertEqualObjects(managed.anyDecimalObj[@"key1"], decimal128(2));
    uncheckedAssertEqualObjects(managed.anyObjectIdObj[@"key1"], objectId(1));
    uncheckedAssertEqualObjects(managed.anyUUIDObj[@"key1"], uuid(@"00000000-0000-0000-0000-000000000000"));
    uncheckedAssertEqualObjects(unmanaged.boolObj[@"key2"], @YES);
    uncheckedAssertEqualObjects(optUnmanaged.boolObj[@"key2"], NSNull.null);
    uncheckedAssertEqualObjects(managed.boolObj[@"key2"], @YES);
    uncheckedAssertEqualObjects(optManaged.boolObj[@"key2"], NSNull.null);
    uncheckedAssertEqualObjects(unmanaged.intObj[@"key2"], @3);
    uncheckedAssertEqualObjects(optUnmanaged.intObj[@"key2"], NSNull.null);
    uncheckedAssertEqualObjects(managed.intObj[@"key2"], @3);
    uncheckedAssertEqualObjects(optManaged.intObj[@"key2"], NSNull.null);
    uncheckedAssertEqualObjects(unmanaged.stringObj[@"key2"], @"foo");
    uncheckedAssertEqualObjects(optUnmanaged.stringObj[@"key2"], NSNull.null);
    uncheckedAssertEqualObjects(managed.stringObj[@"key2"], @"foo");
    uncheckedAssertEqualObjects(optManaged.stringObj[@"key2"], NSNull.null);
    uncheckedAssertEqualObjects(unmanaged.dateObj[@"key2"], date(2));
    uncheckedAssertEqualObjects(optUnmanaged.dateObj[@"key2"], NSNull.null);
    uncheckedAssertEqualObjects(managed.dateObj[@"key2"], date(2));
    uncheckedAssertEqualObjects(optManaged.dateObj[@"key2"], NSNull.null);
    uncheckedAssertEqualObjects(unmanaged.floatObj[@"key2"], @3.3f);
    uncheckedAssertEqualObjects(optUnmanaged.floatObj[@"key2"], NSNull.null);
    uncheckedAssertEqualObjects(managed.floatObj[@"key2"], @3.3f);
    uncheckedAssertEqualObjects(optManaged.floatObj[@"key2"], NSNull.null);
    uncheckedAssertEqualObjects(unmanaged.doubleObj[@"key2"], @3.3);
    uncheckedAssertEqualObjects(optUnmanaged.doubleObj[@"key2"], NSNull.null);
    uncheckedAssertEqualObjects(managed.doubleObj[@"key2"], @3.3);
    uncheckedAssertEqualObjects(optManaged.doubleObj[@"key2"], NSNull.null);
    uncheckedAssertEqualObjects(unmanaged.dataObj[@"key2"], data(2));
    uncheckedAssertEqualObjects(optUnmanaged.dataObj[@"key2"], NSNull.null);
    uncheckedAssertEqualObjects(managed.dataObj[@"key2"], data(2));
    uncheckedAssertEqualObjects(optManaged.dataObj[@"key2"], NSNull.null);
    uncheckedAssertEqualObjects(unmanaged.decimalObj[@"key2"], decimal128(3));
    uncheckedAssertEqualObjects(optUnmanaged.decimalObj[@"key2"], NSNull.null);
    uncheckedAssertEqualObjects(managed.decimalObj[@"key2"], decimal128(3));
    uncheckedAssertEqualObjects(optManaged.decimalObj[@"key2"], NSNull.null);
    uncheckedAssertEqualObjects(unmanaged.objectIdObj[@"key2"], objectId(2));
    uncheckedAssertEqualObjects(optUnmanaged.objectIdObj[@"key2"], NSNull.null);
    uncheckedAssertEqualObjects(managed.objectIdObj[@"key2"], objectId(2));
    uncheckedAssertEqualObjects(optManaged.objectIdObj[@"key2"], NSNull.null);
    uncheckedAssertEqualObjects(unmanaged.uuidObj[@"key2"], uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"));
    uncheckedAssertEqualObjects(optUnmanaged.uuidObj[@"key2"], NSNull.null);
    uncheckedAssertEqualObjects(managed.uuidObj[@"key2"], uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"));
    uncheckedAssertEqualObjects(optManaged.uuidObj[@"key2"], NSNull.null);
    uncheckedAssertEqualObjects(unmanaged.anyBoolObj[@"key2"], @YES);
    uncheckedAssertEqualObjects(unmanaged.anyIntObj[@"key2"], @3);
    uncheckedAssertEqualObjects(unmanaged.anyFloatObj[@"key2"], @3.3f);
    uncheckedAssertEqualObjects(unmanaged.anyDoubleObj[@"key2"], @3.3);
    uncheckedAssertEqualObjects(unmanaged.anyStringObj[@"key2"], @"b");
    uncheckedAssertEqualObjects(unmanaged.anyDataObj[@"key2"], data(2));
    uncheckedAssertEqualObjects(unmanaged.anyDateObj[@"key2"], date(2));
    uncheckedAssertEqualObjects(unmanaged.anyDecimalObj[@"key2"], decimal128(3));
    uncheckedAssertEqualObjects(unmanaged.anyObjectIdObj[@"key2"], objectId(2));
    uncheckedAssertEqualObjects(unmanaged.anyUUIDObj[@"key2"], uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"));
    uncheckedAssertEqualObjects(managed.anyBoolObj[@"key2"], @YES);
    uncheckedAssertEqualObjects(managed.anyIntObj[@"key2"], @3);
    uncheckedAssertEqualObjects(managed.anyFloatObj[@"key2"], @3.3f);
    uncheckedAssertEqualObjects(managed.anyDoubleObj[@"key2"], @3.3);
    uncheckedAssertEqualObjects(managed.anyStringObj[@"key2"], @"b");
    uncheckedAssertEqualObjects(managed.anyDataObj[@"key2"], data(2));
    uncheckedAssertEqualObjects(managed.anyDateObj[@"key2"], date(2));
    uncheckedAssertEqualObjects(managed.anyDecimalObj[@"key2"], decimal128(3));
    uncheckedAssertEqualObjects(managed.anyObjectIdObj[@"key2"], objectId(2));
    uncheckedAssertEqualObjects(managed.anyUUIDObj[@"key2"], uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"));
    uncheckedAssertEqualObjects(optUnmanaged.boolObj[@"key2"], (id)NSNull.null);
    uncheckedAssertEqualObjects(optManaged.boolObj[@"key2"], (id)NSNull.null);
    uncheckedAssertEqualObjects(optUnmanaged.intObj[@"key2"], (id)NSNull.null);
    uncheckedAssertEqualObjects(optManaged.intObj[@"key2"], (id)NSNull.null);
    uncheckedAssertEqualObjects(optUnmanaged.stringObj[@"key2"], (id)NSNull.null);
    uncheckedAssertEqualObjects(optManaged.stringObj[@"key2"], (id)NSNull.null);
    uncheckedAssertEqualObjects(optUnmanaged.dateObj[@"key2"], (id)NSNull.null);
    uncheckedAssertEqualObjects(optManaged.dateObj[@"key2"], (id)NSNull.null);
    uncheckedAssertEqualObjects(optUnmanaged.floatObj[@"key2"], (id)NSNull.null);
    uncheckedAssertEqualObjects(optManaged.floatObj[@"key2"], (id)NSNull.null);
    uncheckedAssertEqualObjects(optUnmanaged.doubleObj[@"key2"], (id)NSNull.null);
    uncheckedAssertEqualObjects(optManaged.doubleObj[@"key2"], (id)NSNull.null);
    uncheckedAssertEqualObjects(optUnmanaged.dataObj[@"key2"], (id)NSNull.null);
    uncheckedAssertEqualObjects(optManaged.dataObj[@"key2"], (id)NSNull.null);
    uncheckedAssertEqualObjects(optUnmanaged.decimalObj[@"key2"], (id)NSNull.null);
    uncheckedAssertEqualObjects(optManaged.decimalObj[@"key2"], (id)NSNull.null);
    uncheckedAssertEqualObjects(optUnmanaged.objectIdObj[@"key2"], (id)NSNull.null);
    uncheckedAssertEqualObjects(optManaged.objectIdObj[@"key2"], (id)NSNull.null);
    uncheckedAssertEqualObjects(optUnmanaged.uuidObj[@"key2"], (id)NSNull.null);
    uncheckedAssertEqualObjects(optManaged.uuidObj[@"key2"], (id)NSNull.null);
}

- (void)testRemoveObject {
    [self addObjects];
    uncheckedAssertEqual(unmanaged.boolObj.count, 2U);
    uncheckedAssertEqual(managed.boolObj.count, 2U);
    uncheckedAssertEqual(unmanaged.intObj.count, 2U);
    uncheckedAssertEqual(managed.intObj.count, 2U);
    uncheckedAssertEqual(unmanaged.stringObj.count, 2U);
    uncheckedAssertEqual(managed.stringObj.count, 2U);
    uncheckedAssertEqual(unmanaged.dateObj.count, 2U);
    uncheckedAssertEqual(managed.dateObj.count, 2U);
    uncheckedAssertEqual(unmanaged.floatObj.count, 2U);
    uncheckedAssertEqual(managed.floatObj.count, 2U);
    uncheckedAssertEqual(unmanaged.doubleObj.count, 2U);
    uncheckedAssertEqual(managed.doubleObj.count, 2U);
    uncheckedAssertEqual(unmanaged.dataObj.count, 2U);
    uncheckedAssertEqual(managed.dataObj.count, 2U);
    uncheckedAssertEqual(unmanaged.decimalObj.count, 2U);
    uncheckedAssertEqual(managed.decimalObj.count, 2U);
    uncheckedAssertEqual(unmanaged.objectIdObj.count, 2U);
    uncheckedAssertEqual(managed.objectIdObj.count, 2U);
    uncheckedAssertEqual(unmanaged.uuidObj.count, 2U);
    uncheckedAssertEqual(managed.uuidObj.count, 2U);
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
    uncheckedAssertEqual(optUnmanaged.boolObj.count, 2U);
    uncheckedAssertEqual(optManaged.boolObj.count, 2U);
    uncheckedAssertEqual(optUnmanaged.intObj.count, 2U);
    uncheckedAssertEqual(optManaged.intObj.count, 2U);
    uncheckedAssertEqual(optUnmanaged.stringObj.count, 2U);
    uncheckedAssertEqual(optManaged.stringObj.count, 2U);
    uncheckedAssertEqual(optUnmanaged.dateObj.count, 2U);
    uncheckedAssertEqual(optManaged.dateObj.count, 2U);
    uncheckedAssertEqual(optUnmanaged.floatObj.count, 2U);
    uncheckedAssertEqual(optManaged.floatObj.count, 2U);
    uncheckedAssertEqual(optUnmanaged.doubleObj.count, 2U);
    uncheckedAssertEqual(optManaged.doubleObj.count, 2U);
    uncheckedAssertEqual(optUnmanaged.dataObj.count, 2U);
    uncheckedAssertEqual(optManaged.dataObj.count, 2U);
    uncheckedAssertEqual(optUnmanaged.decimalObj.count, 2U);
    uncheckedAssertEqual(optManaged.decimalObj.count, 2U);
    uncheckedAssertEqual(optUnmanaged.objectIdObj.count, 2U);
    uncheckedAssertEqual(optManaged.objectIdObj.count, 2U);
    uncheckedAssertEqual(optUnmanaged.uuidObj.count, 2U);
    uncheckedAssertEqual(optManaged.uuidObj.count, 2U);

    uncheckedAssertEqualObjects(unmanaged.boolObj[@"key1"], @NO);
    uncheckedAssertEqualObjects(optUnmanaged.boolObj[@"key1"], @NO);
    uncheckedAssertEqualObjects(managed.boolObj[@"key1"], @NO);
    uncheckedAssertEqualObjects(optManaged.boolObj[@"key1"], @NO);
    uncheckedAssertEqualObjects(unmanaged.intObj[@"key1"], @2);
    uncheckedAssertEqualObjects(optUnmanaged.intObj[@"key1"], @2);
    uncheckedAssertEqualObjects(managed.intObj[@"key1"], @2);
    uncheckedAssertEqualObjects(optManaged.intObj[@"key1"], @2);
    uncheckedAssertEqualObjects(unmanaged.stringObj[@"key1"], @"bar");
    uncheckedAssertEqualObjects(optUnmanaged.stringObj[@"key1"], @"bar");
    uncheckedAssertEqualObjects(managed.stringObj[@"key1"], @"bar");
    uncheckedAssertEqualObjects(optManaged.stringObj[@"key1"], @"bar");
    uncheckedAssertEqualObjects(unmanaged.dateObj[@"key1"], date(1));
    uncheckedAssertEqualObjects(optUnmanaged.dateObj[@"key1"], date(1));
    uncheckedAssertEqualObjects(managed.dateObj[@"key1"], date(1));
    uncheckedAssertEqualObjects(optManaged.dateObj[@"key1"], date(1));
    uncheckedAssertEqualObjects(unmanaged.floatObj[@"key1"], @2.2f);
    uncheckedAssertEqualObjects(optUnmanaged.floatObj[@"key1"], @2.2f);
    uncheckedAssertEqualObjects(managed.floatObj[@"key1"], @2.2f);
    uncheckedAssertEqualObjects(optManaged.floatObj[@"key1"], @2.2f);
    uncheckedAssertEqualObjects(unmanaged.doubleObj[@"key1"], @2.2);
    uncheckedAssertEqualObjects(optUnmanaged.doubleObj[@"key1"], @2.2);
    uncheckedAssertEqualObjects(managed.doubleObj[@"key1"], @2.2);
    uncheckedAssertEqualObjects(optManaged.doubleObj[@"key1"], @2.2);
    uncheckedAssertEqualObjects(unmanaged.dataObj[@"key1"], data(1));
    uncheckedAssertEqualObjects(optUnmanaged.dataObj[@"key1"], data(1));
    uncheckedAssertEqualObjects(managed.dataObj[@"key1"], data(1));
    uncheckedAssertEqualObjects(optManaged.dataObj[@"key1"], data(1));
    uncheckedAssertEqualObjects(unmanaged.decimalObj[@"key1"], decimal128(2));
    uncheckedAssertEqualObjects(optUnmanaged.decimalObj[@"key1"], decimal128(2));
    uncheckedAssertEqualObjects(managed.decimalObj[@"key1"], decimal128(2));
    uncheckedAssertEqualObjects(optManaged.decimalObj[@"key1"], decimal128(2));
    uncheckedAssertEqualObjects(unmanaged.objectIdObj[@"key1"], objectId(1));
    uncheckedAssertEqualObjects(optUnmanaged.objectIdObj[@"key1"], objectId(1));
    uncheckedAssertEqualObjects(managed.objectIdObj[@"key1"], objectId(1));
    uncheckedAssertEqualObjects(optManaged.objectIdObj[@"key1"], objectId(1));
    uncheckedAssertEqualObjects(unmanaged.uuidObj[@"key1"], uuid(@"00000000-0000-0000-0000-000000000000"));
    uncheckedAssertEqualObjects(optUnmanaged.uuidObj[@"key1"], uuid(@"00000000-0000-0000-0000-000000000000"));
    uncheckedAssertEqualObjects(managed.uuidObj[@"key1"], uuid(@"00000000-0000-0000-0000-000000000000"));
    uncheckedAssertEqualObjects(optManaged.uuidObj[@"key1"], uuid(@"00000000-0000-0000-0000-000000000000"));
    uncheckedAssertEqualObjects(unmanaged.anyBoolObj[@"key1"], @NO);
    uncheckedAssertEqualObjects(unmanaged.anyIntObj[@"key1"], @2);
    uncheckedAssertEqualObjects(unmanaged.anyFloatObj[@"key1"], @2.2f);
    uncheckedAssertEqualObjects(unmanaged.anyDoubleObj[@"key1"], @2.2);
    uncheckedAssertEqualObjects(unmanaged.anyStringObj[@"key1"], @"a");
    uncheckedAssertEqualObjects(unmanaged.anyDataObj[@"key1"], data(1));
    uncheckedAssertEqualObjects(unmanaged.anyDateObj[@"key1"], date(1));
    uncheckedAssertEqualObjects(unmanaged.anyDecimalObj[@"key1"], decimal128(2));
    uncheckedAssertEqualObjects(unmanaged.anyObjectIdObj[@"key1"], objectId(1));
    uncheckedAssertEqualObjects(unmanaged.anyUUIDObj[@"key1"], uuid(@"00000000-0000-0000-0000-000000000000"));
    uncheckedAssertEqualObjects(managed.anyBoolObj[@"key1"], @NO);
    uncheckedAssertEqualObjects(managed.anyIntObj[@"key1"], @2);
    uncheckedAssertEqualObjects(managed.anyFloatObj[@"key1"], @2.2f);
    uncheckedAssertEqualObjects(managed.anyDoubleObj[@"key1"], @2.2);
    uncheckedAssertEqualObjects(managed.anyStringObj[@"key1"], @"a");
    uncheckedAssertEqualObjects(managed.anyDataObj[@"key1"], data(1));
    uncheckedAssertEqualObjects(managed.anyDateObj[@"key1"], date(1));
    uncheckedAssertEqualObjects(managed.anyDecimalObj[@"key1"], decimal128(2));
    uncheckedAssertEqualObjects(managed.anyObjectIdObj[@"key1"], objectId(1));
    uncheckedAssertEqualObjects(managed.anyUUIDObj[@"key1"], uuid(@"00000000-0000-0000-0000-000000000000"));

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

    uncheckedAssertEqual(unmanaged.boolObj.count, 1U);
    uncheckedAssertEqual(managed.boolObj.count, 1U);
    uncheckedAssertEqual(unmanaged.intObj.count, 1U);
    uncheckedAssertEqual(managed.intObj.count, 1U);
    uncheckedAssertEqual(unmanaged.stringObj.count, 1U);
    uncheckedAssertEqual(managed.stringObj.count, 1U);
    uncheckedAssertEqual(unmanaged.dateObj.count, 1U);
    uncheckedAssertEqual(managed.dateObj.count, 1U);
    uncheckedAssertEqual(unmanaged.floatObj.count, 1U);
    uncheckedAssertEqual(managed.floatObj.count, 1U);
    uncheckedAssertEqual(unmanaged.doubleObj.count, 1U);
    uncheckedAssertEqual(managed.doubleObj.count, 1U);
    uncheckedAssertEqual(unmanaged.dataObj.count, 1U);
    uncheckedAssertEqual(managed.dataObj.count, 1U);
    uncheckedAssertEqual(unmanaged.decimalObj.count, 1U);
    uncheckedAssertEqual(managed.decimalObj.count, 1U);
    uncheckedAssertEqual(unmanaged.objectIdObj.count, 1U);
    uncheckedAssertEqual(managed.objectIdObj.count, 1U);
    uncheckedAssertEqual(unmanaged.uuidObj.count, 1U);
    uncheckedAssertEqual(managed.uuidObj.count, 1U);
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
    uncheckedAssertEqual(optUnmanaged.boolObj.count, 1U);
    uncheckedAssertEqual(optManaged.boolObj.count, 1U);
    uncheckedAssertEqual(optUnmanaged.intObj.count, 1U);
    uncheckedAssertEqual(optManaged.intObj.count, 1U);
    uncheckedAssertEqual(optUnmanaged.stringObj.count, 1U);
    uncheckedAssertEqual(optManaged.stringObj.count, 1U);
    uncheckedAssertEqual(optUnmanaged.dateObj.count, 1U);
    uncheckedAssertEqual(optManaged.dateObj.count, 1U);
    uncheckedAssertEqual(optUnmanaged.floatObj.count, 1U);
    uncheckedAssertEqual(optManaged.floatObj.count, 1U);
    uncheckedAssertEqual(optUnmanaged.doubleObj.count, 1U);
    uncheckedAssertEqual(optManaged.doubleObj.count, 1U);
    uncheckedAssertEqual(optUnmanaged.dataObj.count, 1U);
    uncheckedAssertEqual(optManaged.dataObj.count, 1U);
    uncheckedAssertEqual(optUnmanaged.decimalObj.count, 1U);
    uncheckedAssertEqual(optManaged.decimalObj.count, 1U);
    uncheckedAssertEqual(optUnmanaged.objectIdObj.count, 1U);
    uncheckedAssertEqual(optManaged.objectIdObj.count, 1U);
    uncheckedAssertEqual(optUnmanaged.uuidObj.count, 1U);
    uncheckedAssertEqual(optManaged.uuidObj.count, 1U);

    uncheckedAssertNil(unmanaged.boolObj[@"key1"]);
    uncheckedAssertNil(optUnmanaged.boolObj[@"key1"]);
    uncheckedAssertNil(managed.boolObj[@"key1"]);
    uncheckedAssertNil(optManaged.boolObj[@"key1"]);
    uncheckedAssertNil(unmanaged.intObj[@"key1"]);
    uncheckedAssertNil(optUnmanaged.intObj[@"key1"]);
    uncheckedAssertNil(managed.intObj[@"key1"]);
    uncheckedAssertNil(optManaged.intObj[@"key1"]);
    uncheckedAssertNil(unmanaged.stringObj[@"key1"]);
    uncheckedAssertNil(optUnmanaged.stringObj[@"key1"]);
    uncheckedAssertNil(managed.stringObj[@"key1"]);
    uncheckedAssertNil(optManaged.stringObj[@"key1"]);
    uncheckedAssertNil(unmanaged.dateObj[@"key1"]);
    uncheckedAssertNil(optUnmanaged.dateObj[@"key1"]);
    uncheckedAssertNil(managed.dateObj[@"key1"]);
    uncheckedAssertNil(optManaged.dateObj[@"key1"]);
    uncheckedAssertNil(unmanaged.floatObj[@"key1"]);
    uncheckedAssertNil(optUnmanaged.floatObj[@"key1"]);
    uncheckedAssertNil(managed.floatObj[@"key1"]);
    uncheckedAssertNil(optManaged.floatObj[@"key1"]);
    uncheckedAssertNil(unmanaged.doubleObj[@"key1"]);
    uncheckedAssertNil(optUnmanaged.doubleObj[@"key1"]);
    uncheckedAssertNil(managed.doubleObj[@"key1"]);
    uncheckedAssertNil(optManaged.doubleObj[@"key1"]);
    uncheckedAssertNil(unmanaged.dataObj[@"key1"]);
    uncheckedAssertNil(optUnmanaged.dataObj[@"key1"]);
    uncheckedAssertNil(managed.dataObj[@"key1"]);
    uncheckedAssertNil(optManaged.dataObj[@"key1"]);
    uncheckedAssertNil(unmanaged.decimalObj[@"key1"]);
    uncheckedAssertNil(optUnmanaged.decimalObj[@"key1"]);
    uncheckedAssertNil(managed.decimalObj[@"key1"]);
    uncheckedAssertNil(optManaged.decimalObj[@"key1"]);
    uncheckedAssertNil(unmanaged.objectIdObj[@"key1"]);
    uncheckedAssertNil(optUnmanaged.objectIdObj[@"key1"]);
    uncheckedAssertNil(managed.objectIdObj[@"key1"]);
    uncheckedAssertNil(optManaged.objectIdObj[@"key1"]);
    uncheckedAssertNil(unmanaged.uuidObj[@"key1"]);
    uncheckedAssertNil(optUnmanaged.uuidObj[@"key1"]);
    uncheckedAssertNil(managed.uuidObj[@"key1"]);
    uncheckedAssertNil(optManaged.uuidObj[@"key1"]);
    uncheckedAssertNil(unmanaged.anyBoolObj[@"key1"]);
    uncheckedAssertNil(unmanaged.anyIntObj[@"key1"]);
    uncheckedAssertNil(unmanaged.anyFloatObj[@"key1"]);
    uncheckedAssertNil(unmanaged.anyDoubleObj[@"key1"]);
    uncheckedAssertNil(unmanaged.anyStringObj[@"key1"]);
    uncheckedAssertNil(unmanaged.anyDataObj[@"key1"]);
    uncheckedAssertNil(unmanaged.anyDateObj[@"key1"]);
    uncheckedAssertNil(unmanaged.anyDecimalObj[@"key1"]);
    uncheckedAssertNil(unmanaged.anyObjectIdObj[@"key1"]);
    uncheckedAssertNil(unmanaged.anyUUIDObj[@"key1"]);
    uncheckedAssertNil(managed.anyBoolObj[@"key1"]);
    uncheckedAssertNil(managed.anyIntObj[@"key1"]);
    uncheckedAssertNil(managed.anyFloatObj[@"key1"]);
    uncheckedAssertNil(managed.anyDoubleObj[@"key1"]);
    uncheckedAssertNil(managed.anyStringObj[@"key1"]);
    uncheckedAssertNil(managed.anyDataObj[@"key1"]);
    uncheckedAssertNil(managed.anyDateObj[@"key1"]);
    uncheckedAssertNil(managed.anyDecimalObj[@"key1"]);
    uncheckedAssertNil(managed.anyObjectIdObj[@"key1"]);
    uncheckedAssertNil(managed.anyUUIDObj[@"key1"]);
}

- (void)testRemoveObjects {
    [self addObjects];
    uncheckedAssertEqual(unmanaged.boolObj.count, 2U);
    uncheckedAssertEqual(optUnmanaged.boolObj.count, 2U);
    uncheckedAssertEqual(managed.boolObj.count, 2U);
    uncheckedAssertEqual(optManaged.boolObj.count, 2U);
    uncheckedAssertEqual(unmanaged.intObj.count, 2U);
    uncheckedAssertEqual(optUnmanaged.intObj.count, 2U);
    uncheckedAssertEqual(managed.intObj.count, 2U);
    uncheckedAssertEqual(optManaged.intObj.count, 2U);
    uncheckedAssertEqual(unmanaged.stringObj.count, 2U);
    uncheckedAssertEqual(optUnmanaged.stringObj.count, 2U);
    uncheckedAssertEqual(managed.stringObj.count, 2U);
    uncheckedAssertEqual(optManaged.stringObj.count, 2U);
    uncheckedAssertEqual(unmanaged.dateObj.count, 2U);
    uncheckedAssertEqual(optUnmanaged.dateObj.count, 2U);
    uncheckedAssertEqual(managed.dateObj.count, 2U);
    uncheckedAssertEqual(optManaged.dateObj.count, 2U);
    uncheckedAssertEqual(unmanaged.floatObj.count, 2U);
    uncheckedAssertEqual(optUnmanaged.floatObj.count, 2U);
    uncheckedAssertEqual(managed.floatObj.count, 2U);
    uncheckedAssertEqual(optManaged.floatObj.count, 2U);
    uncheckedAssertEqual(unmanaged.doubleObj.count, 2U);
    uncheckedAssertEqual(optUnmanaged.doubleObj.count, 2U);
    uncheckedAssertEqual(managed.doubleObj.count, 2U);
    uncheckedAssertEqual(optManaged.doubleObj.count, 2U);
    uncheckedAssertEqual(unmanaged.dataObj.count, 2U);
    uncheckedAssertEqual(optUnmanaged.dataObj.count, 2U);
    uncheckedAssertEqual(managed.dataObj.count, 2U);
    uncheckedAssertEqual(optManaged.dataObj.count, 2U);
    uncheckedAssertEqual(unmanaged.decimalObj.count, 2U);
    uncheckedAssertEqual(optUnmanaged.decimalObj.count, 2U);
    uncheckedAssertEqual(managed.decimalObj.count, 2U);
    uncheckedAssertEqual(optManaged.decimalObj.count, 2U);
    uncheckedAssertEqual(unmanaged.objectIdObj.count, 2U);
    uncheckedAssertEqual(optUnmanaged.objectIdObj.count, 2U);
    uncheckedAssertEqual(managed.objectIdObj.count, 2U);
    uncheckedAssertEqual(optManaged.objectIdObj.count, 2U);
    uncheckedAssertEqual(unmanaged.uuidObj.count, 2U);
    uncheckedAssertEqual(optUnmanaged.uuidObj.count, 2U);
    uncheckedAssertEqual(managed.uuidObj.count, 2U);
    uncheckedAssertEqual(optManaged.uuidObj.count, 2U);
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

    uncheckedAssertEqualObjects(unmanaged.boolObj[@"key1"], @NO);
    uncheckedAssertEqualObjects(optUnmanaged.boolObj[@"key1"], @NO);
    uncheckedAssertEqualObjects(managed.boolObj[@"key1"], @NO);
    uncheckedAssertEqualObjects(optManaged.boolObj[@"key1"], @NO);
    uncheckedAssertEqualObjects(unmanaged.intObj[@"key1"], @2);
    uncheckedAssertEqualObjects(optUnmanaged.intObj[@"key1"], @2);
    uncheckedAssertEqualObjects(managed.intObj[@"key1"], @2);
    uncheckedAssertEqualObjects(optManaged.intObj[@"key1"], @2);
    uncheckedAssertEqualObjects(unmanaged.stringObj[@"key1"], @"bar");
    uncheckedAssertEqualObjects(optUnmanaged.stringObj[@"key1"], @"bar");
    uncheckedAssertEqualObjects(managed.stringObj[@"key1"], @"bar");
    uncheckedAssertEqualObjects(optManaged.stringObj[@"key1"], @"bar");
    uncheckedAssertEqualObjects(unmanaged.dateObj[@"key1"], date(1));
    uncheckedAssertEqualObjects(optUnmanaged.dateObj[@"key1"], date(1));
    uncheckedAssertEqualObjects(managed.dateObj[@"key1"], date(1));
    uncheckedAssertEqualObjects(optManaged.dateObj[@"key1"], date(1));
    uncheckedAssertEqualObjects(unmanaged.floatObj[@"key1"], @2.2f);
    uncheckedAssertEqualObjects(optUnmanaged.floatObj[@"key1"], @2.2f);
    uncheckedAssertEqualObjects(managed.floatObj[@"key1"], @2.2f);
    uncheckedAssertEqualObjects(optManaged.floatObj[@"key1"], @2.2f);
    uncheckedAssertEqualObjects(unmanaged.doubleObj[@"key1"], @2.2);
    uncheckedAssertEqualObjects(optUnmanaged.doubleObj[@"key1"], @2.2);
    uncheckedAssertEqualObjects(managed.doubleObj[@"key1"], @2.2);
    uncheckedAssertEqualObjects(optManaged.doubleObj[@"key1"], @2.2);
    uncheckedAssertEqualObjects(unmanaged.dataObj[@"key1"], data(1));
    uncheckedAssertEqualObjects(optUnmanaged.dataObj[@"key1"], data(1));
    uncheckedAssertEqualObjects(managed.dataObj[@"key1"], data(1));
    uncheckedAssertEqualObjects(optManaged.dataObj[@"key1"], data(1));
    uncheckedAssertEqualObjects(unmanaged.decimalObj[@"key1"], decimal128(2));
    uncheckedAssertEqualObjects(optUnmanaged.decimalObj[@"key1"], decimal128(2));
    uncheckedAssertEqualObjects(managed.decimalObj[@"key1"], decimal128(2));
    uncheckedAssertEqualObjects(optManaged.decimalObj[@"key1"], decimal128(2));
    uncheckedAssertEqualObjects(unmanaged.objectIdObj[@"key1"], objectId(1));
    uncheckedAssertEqualObjects(optUnmanaged.objectIdObj[@"key1"], objectId(1));
    uncheckedAssertEqualObjects(managed.objectIdObj[@"key1"], objectId(1));
    uncheckedAssertEqualObjects(optManaged.objectIdObj[@"key1"], objectId(1));
    uncheckedAssertEqualObjects(unmanaged.uuidObj[@"key1"], uuid(@"00000000-0000-0000-0000-000000000000"));
    uncheckedAssertEqualObjects(optUnmanaged.uuidObj[@"key1"], uuid(@"00000000-0000-0000-0000-000000000000"));
    uncheckedAssertEqualObjects(managed.uuidObj[@"key1"], uuid(@"00000000-0000-0000-0000-000000000000"));
    uncheckedAssertEqualObjects(optManaged.uuidObj[@"key1"], uuid(@"00000000-0000-0000-0000-000000000000"));
    uncheckedAssertEqualObjects(unmanaged.anyBoolObj[@"key1"], @NO);
    uncheckedAssertEqualObjects(unmanaged.anyIntObj[@"key1"], @2);
    uncheckedAssertEqualObjects(unmanaged.anyFloatObj[@"key1"], @2.2f);
    uncheckedAssertEqualObjects(unmanaged.anyDoubleObj[@"key1"], @2.2);
    uncheckedAssertEqualObjects(unmanaged.anyStringObj[@"key1"], @"a");
    uncheckedAssertEqualObjects(unmanaged.anyDataObj[@"key1"], data(1));
    uncheckedAssertEqualObjects(unmanaged.anyDateObj[@"key1"], date(1));
    uncheckedAssertEqualObjects(unmanaged.anyDecimalObj[@"key1"], decimal128(2));
    uncheckedAssertEqualObjects(unmanaged.anyObjectIdObj[@"key1"], objectId(1));
    uncheckedAssertEqualObjects(unmanaged.anyUUIDObj[@"key1"], uuid(@"00000000-0000-0000-0000-000000000000"));
    uncheckedAssertEqualObjects(managed.anyBoolObj[@"key1"], @NO);
    uncheckedAssertEqualObjects(managed.anyIntObj[@"key1"], @2);
    uncheckedAssertEqualObjects(managed.anyFloatObj[@"key1"], @2.2f);
    uncheckedAssertEqualObjects(managed.anyDoubleObj[@"key1"], @2.2);
    uncheckedAssertEqualObjects(managed.anyStringObj[@"key1"], @"a");
    uncheckedAssertEqualObjects(managed.anyDataObj[@"key1"], data(1));
    uncheckedAssertEqualObjects(managed.anyDateObj[@"key1"], date(1));
    uncheckedAssertEqualObjects(managed.anyDecimalObj[@"key1"], decimal128(2));
    uncheckedAssertEqualObjects(managed.anyObjectIdObj[@"key1"], objectId(1));
    uncheckedAssertEqualObjects(managed.anyUUIDObj[@"key1"], uuid(@"00000000-0000-0000-0000-000000000000"));

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

    uncheckedAssertEqual(unmanaged.boolObj.count, 0U);
    uncheckedAssertEqual(optUnmanaged.boolObj.count, 0U);
    uncheckedAssertEqual(managed.boolObj.count, 0U);
    uncheckedAssertEqual(optManaged.boolObj.count, 0U);
    uncheckedAssertEqual(unmanaged.intObj.count, 0U);
    uncheckedAssertEqual(optUnmanaged.intObj.count, 0U);
    uncheckedAssertEqual(managed.intObj.count, 0U);
    uncheckedAssertEqual(optManaged.intObj.count, 0U);
    uncheckedAssertEqual(unmanaged.stringObj.count, 0U);
    uncheckedAssertEqual(optUnmanaged.stringObj.count, 0U);
    uncheckedAssertEqual(managed.stringObj.count, 0U);
    uncheckedAssertEqual(optManaged.stringObj.count, 0U);
    uncheckedAssertEqual(unmanaged.dateObj.count, 0U);
    uncheckedAssertEqual(optUnmanaged.dateObj.count, 0U);
    uncheckedAssertEqual(managed.dateObj.count, 0U);
    uncheckedAssertEqual(optManaged.dateObj.count, 0U);
    uncheckedAssertEqual(unmanaged.floatObj.count, 0U);
    uncheckedAssertEqual(optUnmanaged.floatObj.count, 0U);
    uncheckedAssertEqual(managed.floatObj.count, 0U);
    uncheckedAssertEqual(optManaged.floatObj.count, 0U);
    uncheckedAssertEqual(unmanaged.doubleObj.count, 0U);
    uncheckedAssertEqual(optUnmanaged.doubleObj.count, 0U);
    uncheckedAssertEqual(managed.doubleObj.count, 0U);
    uncheckedAssertEqual(optManaged.doubleObj.count, 0U);
    uncheckedAssertEqual(unmanaged.dataObj.count, 0U);
    uncheckedAssertEqual(optUnmanaged.dataObj.count, 0U);
    uncheckedAssertEqual(managed.dataObj.count, 0U);
    uncheckedAssertEqual(optManaged.dataObj.count, 0U);
    uncheckedAssertEqual(unmanaged.decimalObj.count, 0U);
    uncheckedAssertEqual(optUnmanaged.decimalObj.count, 0U);
    uncheckedAssertEqual(managed.decimalObj.count, 0U);
    uncheckedAssertEqual(optManaged.decimalObj.count, 0U);
    uncheckedAssertEqual(unmanaged.objectIdObj.count, 0U);
    uncheckedAssertEqual(optUnmanaged.objectIdObj.count, 0U);
    uncheckedAssertEqual(managed.objectIdObj.count, 0U);
    uncheckedAssertEqual(optManaged.objectIdObj.count, 0U);
    uncheckedAssertEqual(unmanaged.uuidObj.count, 0U);
    uncheckedAssertEqual(optUnmanaged.uuidObj.count, 0U);
    uncheckedAssertEqual(managed.uuidObj.count, 0U);
    uncheckedAssertEqual(optManaged.uuidObj.count, 0U);
    uncheckedAssertEqual(unmanaged.anyBoolObj.count, 0U);
    uncheckedAssertEqual(unmanaged.anyIntObj.count, 0U);
    uncheckedAssertEqual(unmanaged.anyFloatObj.count, 0U);
    uncheckedAssertEqual(unmanaged.anyDoubleObj.count, 0U);
    uncheckedAssertEqual(unmanaged.anyStringObj.count, 0U);
    uncheckedAssertEqual(unmanaged.anyDataObj.count, 0U);
    uncheckedAssertEqual(unmanaged.anyDateObj.count, 0U);
    uncheckedAssertEqual(unmanaged.anyDecimalObj.count, 0U);
    uncheckedAssertEqual(unmanaged.anyObjectIdObj.count, 0U);
    uncheckedAssertEqual(unmanaged.anyUUIDObj.count, 0U);
    uncheckedAssertEqual(managed.anyBoolObj.count, 0U);
    uncheckedAssertEqual(managed.anyIntObj.count, 0U);
    uncheckedAssertEqual(managed.anyFloatObj.count, 0U);
    uncheckedAssertEqual(managed.anyDoubleObj.count, 0U);
    uncheckedAssertEqual(managed.anyStringObj.count, 0U);
    uncheckedAssertEqual(managed.anyDataObj.count, 0U);
    uncheckedAssertEqual(managed.anyDateObj.count, 0U);
    uncheckedAssertEqual(managed.anyDecimalObj.count, 0U);
    uncheckedAssertEqual(managed.anyObjectIdObj.count, 0U);
    uncheckedAssertEqual(managed.anyUUIDObj.count, 0U);
    uncheckedAssertNil(unmanaged.boolObj[@"key1"]);
    uncheckedAssertNil(optUnmanaged.boolObj[@"key1"]);
    uncheckedAssertNil(managed.boolObj[@"key1"]);
    uncheckedAssertNil(optManaged.boolObj[@"key1"]);
    uncheckedAssertNil(unmanaged.intObj[@"key1"]);
    uncheckedAssertNil(optUnmanaged.intObj[@"key1"]);
    uncheckedAssertNil(managed.intObj[@"key1"]);
    uncheckedAssertNil(optManaged.intObj[@"key1"]);
    uncheckedAssertNil(unmanaged.stringObj[@"key1"]);
    uncheckedAssertNil(optUnmanaged.stringObj[@"key1"]);
    uncheckedAssertNil(managed.stringObj[@"key1"]);
    uncheckedAssertNil(optManaged.stringObj[@"key1"]);
    uncheckedAssertNil(unmanaged.dateObj[@"key1"]);
    uncheckedAssertNil(optUnmanaged.dateObj[@"key1"]);
    uncheckedAssertNil(managed.dateObj[@"key1"]);
    uncheckedAssertNil(optManaged.dateObj[@"key1"]);
    uncheckedAssertNil(unmanaged.floatObj[@"key1"]);
    uncheckedAssertNil(optUnmanaged.floatObj[@"key1"]);
    uncheckedAssertNil(managed.floatObj[@"key1"]);
    uncheckedAssertNil(optManaged.floatObj[@"key1"]);
    uncheckedAssertNil(unmanaged.doubleObj[@"key1"]);
    uncheckedAssertNil(optUnmanaged.doubleObj[@"key1"]);
    uncheckedAssertNil(managed.doubleObj[@"key1"]);
    uncheckedAssertNil(optManaged.doubleObj[@"key1"]);
    uncheckedAssertNil(unmanaged.dataObj[@"key1"]);
    uncheckedAssertNil(optUnmanaged.dataObj[@"key1"]);
    uncheckedAssertNil(managed.dataObj[@"key1"]);
    uncheckedAssertNil(optManaged.dataObj[@"key1"]);
    uncheckedAssertNil(unmanaged.decimalObj[@"key1"]);
    uncheckedAssertNil(optUnmanaged.decimalObj[@"key1"]);
    uncheckedAssertNil(managed.decimalObj[@"key1"]);
    uncheckedAssertNil(optManaged.decimalObj[@"key1"]);
    uncheckedAssertNil(unmanaged.objectIdObj[@"key1"]);
    uncheckedAssertNil(optUnmanaged.objectIdObj[@"key1"]);
    uncheckedAssertNil(managed.objectIdObj[@"key1"]);
    uncheckedAssertNil(optManaged.objectIdObj[@"key1"]);
    uncheckedAssertNil(unmanaged.uuidObj[@"key1"]);
    uncheckedAssertNil(optUnmanaged.uuidObj[@"key1"]);
    uncheckedAssertNil(managed.uuidObj[@"key1"]);
    uncheckedAssertNil(optManaged.uuidObj[@"key1"]);
    uncheckedAssertNil(unmanaged.anyBoolObj[@"key1"]);
    uncheckedAssertNil(unmanaged.anyIntObj[@"key1"]);
    uncheckedAssertNil(unmanaged.anyFloatObj[@"key1"]);
    uncheckedAssertNil(unmanaged.anyDoubleObj[@"key1"]);
    uncheckedAssertNil(unmanaged.anyStringObj[@"key1"]);
    uncheckedAssertNil(unmanaged.anyDataObj[@"key1"]);
    uncheckedAssertNil(unmanaged.anyDateObj[@"key1"]);
    uncheckedAssertNil(unmanaged.anyDecimalObj[@"key1"]);
    uncheckedAssertNil(unmanaged.anyObjectIdObj[@"key1"]);
    uncheckedAssertNil(unmanaged.anyUUIDObj[@"key1"]);
    uncheckedAssertNil(managed.anyBoolObj[@"key1"]);
    uncheckedAssertNil(managed.anyIntObj[@"key1"]);
    uncheckedAssertNil(managed.anyFloatObj[@"key1"]);
    uncheckedAssertNil(managed.anyDoubleObj[@"key1"]);
    uncheckedAssertNil(managed.anyStringObj[@"key1"]);
    uncheckedAssertNil(managed.anyDataObj[@"key1"]);
    uncheckedAssertNil(managed.anyDateObj[@"key1"]);
    uncheckedAssertNil(managed.anyDecimalObj[@"key1"]);
    uncheckedAssertNil(managed.anyObjectIdObj[@"key1"]);
    uncheckedAssertNil(managed.anyUUIDObj[@"key1"]);
}

- (void)testUpdateObjects {
    [self addObjects];
    uncheckedAssertEqual(unmanaged.boolObj.count, 2U);
    uncheckedAssertEqual(optUnmanaged.boolObj.count, 2U);
    uncheckedAssertEqual(managed.boolObj.count, 2U);
    uncheckedAssertEqual(optManaged.boolObj.count, 2U);
    uncheckedAssertEqual(unmanaged.intObj.count, 2U);
    uncheckedAssertEqual(optUnmanaged.intObj.count, 2U);
    uncheckedAssertEqual(managed.intObj.count, 2U);
    uncheckedAssertEqual(optManaged.intObj.count, 2U);
    uncheckedAssertEqual(unmanaged.stringObj.count, 2U);
    uncheckedAssertEqual(optUnmanaged.stringObj.count, 2U);
    uncheckedAssertEqual(managed.stringObj.count, 2U);
    uncheckedAssertEqual(optManaged.stringObj.count, 2U);
    uncheckedAssertEqual(unmanaged.dateObj.count, 2U);
    uncheckedAssertEqual(optUnmanaged.dateObj.count, 2U);
    uncheckedAssertEqual(managed.dateObj.count, 2U);
    uncheckedAssertEqual(optManaged.dateObj.count, 2U);
    uncheckedAssertEqual(unmanaged.floatObj.count, 2U);
    uncheckedAssertEqual(optUnmanaged.floatObj.count, 2U);
    uncheckedAssertEqual(managed.floatObj.count, 2U);
    uncheckedAssertEqual(optManaged.floatObj.count, 2U);
    uncheckedAssertEqual(unmanaged.doubleObj.count, 2U);
    uncheckedAssertEqual(optUnmanaged.doubleObj.count, 2U);
    uncheckedAssertEqual(managed.doubleObj.count, 2U);
    uncheckedAssertEqual(optManaged.doubleObj.count, 2U);
    uncheckedAssertEqual(unmanaged.dataObj.count, 2U);
    uncheckedAssertEqual(optUnmanaged.dataObj.count, 2U);
    uncheckedAssertEqual(managed.dataObj.count, 2U);
    uncheckedAssertEqual(optManaged.dataObj.count, 2U);
    uncheckedAssertEqual(unmanaged.decimalObj.count, 2U);
    uncheckedAssertEqual(optUnmanaged.decimalObj.count, 2U);
    uncheckedAssertEqual(managed.decimalObj.count, 2U);
    uncheckedAssertEqual(optManaged.decimalObj.count, 2U);
    uncheckedAssertEqual(unmanaged.objectIdObj.count, 2U);
    uncheckedAssertEqual(optUnmanaged.objectIdObj.count, 2U);
    uncheckedAssertEqual(managed.objectIdObj.count, 2U);
    uncheckedAssertEqual(optManaged.objectIdObj.count, 2U);
    uncheckedAssertEqual(unmanaged.uuidObj.count, 2U);
    uncheckedAssertEqual(optUnmanaged.uuidObj.count, 2U);
    uncheckedAssertEqual(managed.uuidObj.count, 2U);
    uncheckedAssertEqual(optManaged.uuidObj.count, 2U);
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

    uncheckedAssertEqualObjects(unmanaged.boolObj[@"key1"], @NO);
    uncheckedAssertEqualObjects(optUnmanaged.boolObj[@"key1"], @NO);
    uncheckedAssertEqualObjects(managed.boolObj[@"key1"], @NO);
    uncheckedAssertEqualObjects(optManaged.boolObj[@"key1"], @NO);
    uncheckedAssertEqualObjects(unmanaged.intObj[@"key1"], @2);
    uncheckedAssertEqualObjects(optUnmanaged.intObj[@"key1"], @2);
    uncheckedAssertEqualObjects(managed.intObj[@"key1"], @2);
    uncheckedAssertEqualObjects(optManaged.intObj[@"key1"], @2);
    uncheckedAssertEqualObjects(unmanaged.stringObj[@"key1"], @"bar");
    uncheckedAssertEqualObjects(optUnmanaged.stringObj[@"key1"], @"bar");
    uncheckedAssertEqualObjects(managed.stringObj[@"key1"], @"bar");
    uncheckedAssertEqualObjects(optManaged.stringObj[@"key1"], @"bar");
    uncheckedAssertEqualObjects(unmanaged.dateObj[@"key1"], date(1));
    uncheckedAssertEqualObjects(optUnmanaged.dateObj[@"key1"], date(1));
    uncheckedAssertEqualObjects(managed.dateObj[@"key1"], date(1));
    uncheckedAssertEqualObjects(optManaged.dateObj[@"key1"], date(1));
    uncheckedAssertEqualObjects(unmanaged.floatObj[@"key1"], @2.2f);
    uncheckedAssertEqualObjects(optUnmanaged.floatObj[@"key1"], @2.2f);
    uncheckedAssertEqualObjects(managed.floatObj[@"key1"], @2.2f);
    uncheckedAssertEqualObjects(optManaged.floatObj[@"key1"], @2.2f);
    uncheckedAssertEqualObjects(unmanaged.doubleObj[@"key1"], @2.2);
    uncheckedAssertEqualObjects(optUnmanaged.doubleObj[@"key1"], @2.2);
    uncheckedAssertEqualObjects(managed.doubleObj[@"key1"], @2.2);
    uncheckedAssertEqualObjects(optManaged.doubleObj[@"key1"], @2.2);
    uncheckedAssertEqualObjects(unmanaged.dataObj[@"key1"], data(1));
    uncheckedAssertEqualObjects(optUnmanaged.dataObj[@"key1"], data(1));
    uncheckedAssertEqualObjects(managed.dataObj[@"key1"], data(1));
    uncheckedAssertEqualObjects(optManaged.dataObj[@"key1"], data(1));
    uncheckedAssertEqualObjects(unmanaged.decimalObj[@"key1"], decimal128(2));
    uncheckedAssertEqualObjects(optUnmanaged.decimalObj[@"key1"], decimal128(2));
    uncheckedAssertEqualObjects(managed.decimalObj[@"key1"], decimal128(2));
    uncheckedAssertEqualObjects(optManaged.decimalObj[@"key1"], decimal128(2));
    uncheckedAssertEqualObjects(unmanaged.objectIdObj[@"key1"], objectId(1));
    uncheckedAssertEqualObjects(optUnmanaged.objectIdObj[@"key1"], objectId(1));
    uncheckedAssertEqualObjects(managed.objectIdObj[@"key1"], objectId(1));
    uncheckedAssertEqualObjects(optManaged.objectIdObj[@"key1"], objectId(1));
    uncheckedAssertEqualObjects(unmanaged.uuidObj[@"key1"], uuid(@"00000000-0000-0000-0000-000000000000"));
    uncheckedAssertEqualObjects(optUnmanaged.uuidObj[@"key1"], uuid(@"00000000-0000-0000-0000-000000000000"));
    uncheckedAssertEqualObjects(managed.uuidObj[@"key1"], uuid(@"00000000-0000-0000-0000-000000000000"));
    uncheckedAssertEqualObjects(optManaged.uuidObj[@"key1"], uuid(@"00000000-0000-0000-0000-000000000000"));
    uncheckedAssertEqualObjects(unmanaged.anyBoolObj[@"key1"], @NO);
    uncheckedAssertEqualObjects(unmanaged.anyIntObj[@"key1"], @2);
    uncheckedAssertEqualObjects(unmanaged.anyFloatObj[@"key1"], @2.2f);
    uncheckedAssertEqualObjects(unmanaged.anyDoubleObj[@"key1"], @2.2);
    uncheckedAssertEqualObjects(unmanaged.anyStringObj[@"key1"], @"a");
    uncheckedAssertEqualObjects(unmanaged.anyDataObj[@"key1"], data(1));
    uncheckedAssertEqualObjects(unmanaged.anyDateObj[@"key1"], date(1));
    uncheckedAssertEqualObjects(unmanaged.anyDecimalObj[@"key1"], decimal128(2));
    uncheckedAssertEqualObjects(unmanaged.anyObjectIdObj[@"key1"], objectId(1));
    uncheckedAssertEqualObjects(unmanaged.anyUUIDObj[@"key1"], uuid(@"00000000-0000-0000-0000-000000000000"));
    uncheckedAssertEqualObjects(managed.anyBoolObj[@"key1"], @NO);
    uncheckedAssertEqualObjects(managed.anyIntObj[@"key1"], @2);
    uncheckedAssertEqualObjects(managed.anyFloatObj[@"key1"], @2.2f);
    uncheckedAssertEqualObjects(managed.anyDoubleObj[@"key1"], @2.2);
    uncheckedAssertEqualObjects(managed.anyStringObj[@"key1"], @"a");
    uncheckedAssertEqualObjects(managed.anyDataObj[@"key1"], data(1));
    uncheckedAssertEqualObjects(managed.anyDateObj[@"key1"], date(1));
    uncheckedAssertEqualObjects(managed.anyDecimalObj[@"key1"], decimal128(2));
    uncheckedAssertEqualObjects(managed.anyObjectIdObj[@"key1"], objectId(1));
    uncheckedAssertEqualObjects(managed.anyUUIDObj[@"key1"], uuid(@"00000000-0000-0000-0000-000000000000"));
    uncheckedAssertEqualObjects(unmanaged.boolObj[@"key2"], @YES);
    uncheckedAssertEqualObjects(optUnmanaged.boolObj[@"key2"], NSNull.null);
    uncheckedAssertEqualObjects(managed.boolObj[@"key2"], @YES);
    uncheckedAssertEqualObjects(optManaged.boolObj[@"key2"], NSNull.null);
    uncheckedAssertEqualObjects(unmanaged.intObj[@"key2"], @3);
    uncheckedAssertEqualObjects(optUnmanaged.intObj[@"key2"], NSNull.null);
    uncheckedAssertEqualObjects(managed.intObj[@"key2"], @3);
    uncheckedAssertEqualObjects(optManaged.intObj[@"key2"], NSNull.null);
    uncheckedAssertEqualObjects(unmanaged.stringObj[@"key2"], @"foo");
    uncheckedAssertEqualObjects(optUnmanaged.stringObj[@"key2"], NSNull.null);
    uncheckedAssertEqualObjects(managed.stringObj[@"key2"], @"foo");
    uncheckedAssertEqualObjects(optManaged.stringObj[@"key2"], NSNull.null);
    uncheckedAssertEqualObjects(unmanaged.dateObj[@"key2"], date(2));
    uncheckedAssertEqualObjects(optUnmanaged.dateObj[@"key2"], NSNull.null);
    uncheckedAssertEqualObjects(managed.dateObj[@"key2"], date(2));
    uncheckedAssertEqualObjects(optManaged.dateObj[@"key2"], NSNull.null);
    uncheckedAssertEqualObjects(unmanaged.floatObj[@"key2"], @3.3f);
    uncheckedAssertEqualObjects(optUnmanaged.floatObj[@"key2"], NSNull.null);
    uncheckedAssertEqualObjects(managed.floatObj[@"key2"], @3.3f);
    uncheckedAssertEqualObjects(optManaged.floatObj[@"key2"], NSNull.null);
    uncheckedAssertEqualObjects(unmanaged.doubleObj[@"key2"], @3.3);
    uncheckedAssertEqualObjects(optUnmanaged.doubleObj[@"key2"], NSNull.null);
    uncheckedAssertEqualObjects(managed.doubleObj[@"key2"], @3.3);
    uncheckedAssertEqualObjects(optManaged.doubleObj[@"key2"], NSNull.null);
    uncheckedAssertEqualObjects(unmanaged.dataObj[@"key2"], data(2));
    uncheckedAssertEqualObjects(optUnmanaged.dataObj[@"key2"], NSNull.null);
    uncheckedAssertEqualObjects(managed.dataObj[@"key2"], data(2));
    uncheckedAssertEqualObjects(optManaged.dataObj[@"key2"], NSNull.null);
    uncheckedAssertEqualObjects(unmanaged.decimalObj[@"key2"], decimal128(3));
    uncheckedAssertEqualObjects(optUnmanaged.decimalObj[@"key2"], NSNull.null);
    uncheckedAssertEqualObjects(managed.decimalObj[@"key2"], decimal128(3));
    uncheckedAssertEqualObjects(optManaged.decimalObj[@"key2"], NSNull.null);
    uncheckedAssertEqualObjects(unmanaged.objectIdObj[@"key2"], objectId(2));
    uncheckedAssertEqualObjects(optUnmanaged.objectIdObj[@"key2"], NSNull.null);
    uncheckedAssertEqualObjects(managed.objectIdObj[@"key2"], objectId(2));
    uncheckedAssertEqualObjects(optManaged.objectIdObj[@"key2"], NSNull.null);
    uncheckedAssertEqualObjects(unmanaged.uuidObj[@"key2"], uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"));
    uncheckedAssertEqualObjects(optUnmanaged.uuidObj[@"key2"], NSNull.null);
    uncheckedAssertEqualObjects(managed.uuidObj[@"key2"], uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"));
    uncheckedAssertEqualObjects(optManaged.uuidObj[@"key2"], NSNull.null);
    uncheckedAssertEqualObjects(unmanaged.anyBoolObj[@"key2"], @YES);
    uncheckedAssertEqualObjects(unmanaged.anyIntObj[@"key2"], @3);
    uncheckedAssertEqualObjects(unmanaged.anyFloatObj[@"key2"], @3.3f);
    uncheckedAssertEqualObjects(unmanaged.anyDoubleObj[@"key2"], @3.3);
    uncheckedAssertEqualObjects(unmanaged.anyStringObj[@"key2"], @"b");
    uncheckedAssertEqualObjects(unmanaged.anyDataObj[@"key2"], data(2));
    uncheckedAssertEqualObjects(unmanaged.anyDateObj[@"key2"], date(2));
    uncheckedAssertEqualObjects(unmanaged.anyDecimalObj[@"key2"], decimal128(3));
    uncheckedAssertEqualObjects(unmanaged.anyObjectIdObj[@"key2"], objectId(2));
    uncheckedAssertEqualObjects(unmanaged.anyUUIDObj[@"key2"], uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"));
    uncheckedAssertEqualObjects(managed.anyBoolObj[@"key2"], @YES);
    uncheckedAssertEqualObjects(managed.anyIntObj[@"key2"], @3);
    uncheckedAssertEqualObjects(managed.anyFloatObj[@"key2"], @3.3f);
    uncheckedAssertEqualObjects(managed.anyDoubleObj[@"key2"], @3.3);
    uncheckedAssertEqualObjects(managed.anyStringObj[@"key2"], @"b");
    uncheckedAssertEqualObjects(managed.anyDataObj[@"key2"], data(2));
    uncheckedAssertEqualObjects(managed.anyDateObj[@"key2"], date(2));
    uncheckedAssertEqualObjects(managed.anyDecimalObj[@"key2"], decimal128(3));
    uncheckedAssertEqualObjects(managed.anyObjectIdObj[@"key2"], objectId(2));
    uncheckedAssertEqualObjects(managed.anyUUIDObj[@"key2"], uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"));

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

    uncheckedAssertEqualObjects(unmanaged.boolObj[@"key2"], @NO);
    uncheckedAssertEqualObjects(optUnmanaged.boolObj[@"key2"], @NO);
    uncheckedAssertEqualObjects(managed.boolObj[@"key2"], @NO);
    uncheckedAssertEqualObjects(optManaged.boolObj[@"key2"], @NO);
    uncheckedAssertEqualObjects(unmanaged.intObj[@"key2"], @2);
    uncheckedAssertEqualObjects(optUnmanaged.intObj[@"key2"], @2);
    uncheckedAssertEqualObjects(managed.intObj[@"key2"], @2);
    uncheckedAssertEqualObjects(optManaged.intObj[@"key2"], @2);
    uncheckedAssertEqualObjects(unmanaged.stringObj[@"key2"], @"bar");
    uncheckedAssertEqualObjects(optUnmanaged.stringObj[@"key2"], @"bar");
    uncheckedAssertEqualObjects(managed.stringObj[@"key2"], @"bar");
    uncheckedAssertEqualObjects(optManaged.stringObj[@"key2"], @"bar");
    uncheckedAssertEqualObjects(unmanaged.dateObj[@"key2"], date(1));
    uncheckedAssertEqualObjects(optUnmanaged.dateObj[@"key2"], date(1));
    uncheckedAssertEqualObjects(managed.dateObj[@"key2"], date(1));
    uncheckedAssertEqualObjects(optManaged.dateObj[@"key2"], date(1));
    uncheckedAssertEqualObjects(unmanaged.floatObj[@"key2"], @2.2f);
    uncheckedAssertEqualObjects(optUnmanaged.floatObj[@"key2"], @2.2f);
    uncheckedAssertEqualObjects(managed.floatObj[@"key2"], @2.2f);
    uncheckedAssertEqualObjects(optManaged.floatObj[@"key2"], @2.2f);
    uncheckedAssertEqualObjects(unmanaged.doubleObj[@"key2"], @2.2);
    uncheckedAssertEqualObjects(optUnmanaged.doubleObj[@"key2"], @2.2);
    uncheckedAssertEqualObjects(managed.doubleObj[@"key2"], @2.2);
    uncheckedAssertEqualObjects(optManaged.doubleObj[@"key2"], @2.2);
    uncheckedAssertEqualObjects(unmanaged.dataObj[@"key2"], data(1));
    uncheckedAssertEqualObjects(optUnmanaged.dataObj[@"key2"], data(1));
    uncheckedAssertEqualObjects(managed.dataObj[@"key2"], data(1));
    uncheckedAssertEqualObjects(optManaged.dataObj[@"key2"], data(1));
    uncheckedAssertEqualObjects(unmanaged.decimalObj[@"key2"], decimal128(2));
    uncheckedAssertEqualObjects(optUnmanaged.decimalObj[@"key2"], decimal128(2));
    uncheckedAssertEqualObjects(managed.decimalObj[@"key2"], decimal128(2));
    uncheckedAssertEqualObjects(optManaged.decimalObj[@"key2"], decimal128(2));
    uncheckedAssertEqualObjects(unmanaged.objectIdObj[@"key2"], objectId(1));
    uncheckedAssertEqualObjects(optUnmanaged.objectIdObj[@"key2"], objectId(1));
    uncheckedAssertEqualObjects(managed.objectIdObj[@"key2"], objectId(1));
    uncheckedAssertEqualObjects(optManaged.objectIdObj[@"key2"], objectId(1));
    uncheckedAssertEqualObjects(unmanaged.uuidObj[@"key2"], uuid(@"00000000-0000-0000-0000-000000000000"));
    uncheckedAssertEqualObjects(optUnmanaged.uuidObj[@"key2"], uuid(@"00000000-0000-0000-0000-000000000000"));
    uncheckedAssertEqualObjects(managed.uuidObj[@"key2"], uuid(@"00000000-0000-0000-0000-000000000000"));
    uncheckedAssertEqualObjects(optManaged.uuidObj[@"key2"], uuid(@"00000000-0000-0000-0000-000000000000"));
    uncheckedAssertEqualObjects(unmanaged.anyBoolObj[@"key2"], @NO);
    uncheckedAssertEqualObjects(unmanaged.anyIntObj[@"key2"], @2);
    uncheckedAssertEqualObjects(unmanaged.anyFloatObj[@"key2"], @2.2f);
    uncheckedAssertEqualObjects(unmanaged.anyDoubleObj[@"key2"], @2.2);
    uncheckedAssertEqualObjects(unmanaged.anyStringObj[@"key2"], @"a");
    uncheckedAssertEqualObjects(unmanaged.anyDataObj[@"key2"], data(1));
    uncheckedAssertEqualObjects(unmanaged.anyDateObj[@"key2"], date(1));
    uncheckedAssertEqualObjects(unmanaged.anyDecimalObj[@"key2"], decimal128(2));
    uncheckedAssertEqualObjects(unmanaged.anyObjectIdObj[@"key2"], objectId(1));
    uncheckedAssertEqualObjects(unmanaged.anyUUIDObj[@"key2"], uuid(@"00000000-0000-0000-0000-000000000000"));
    uncheckedAssertEqualObjects(managed.anyBoolObj[@"key2"], @NO);
    uncheckedAssertEqualObjects(managed.anyIntObj[@"key2"], @2);
    uncheckedAssertEqualObjects(managed.anyFloatObj[@"key2"], @2.2f);
    uncheckedAssertEqualObjects(managed.anyDoubleObj[@"key2"], @2.2);
    uncheckedAssertEqualObjects(managed.anyStringObj[@"key2"], @"a");
    uncheckedAssertEqualObjects(managed.anyDataObj[@"key2"], data(1));
    uncheckedAssertEqualObjects(managed.anyDateObj[@"key2"], date(1));
    uncheckedAssertEqualObjects(managed.anyDecimalObj[@"key2"], decimal128(2));
    uncheckedAssertEqualObjects(managed.anyObjectIdObj[@"key2"], objectId(1));
    uncheckedAssertEqualObjects(managed.anyUUIDObj[@"key2"], uuid(@"00000000-0000-0000-0000-000000000000"));
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

    uncheckedAssertEqual(0U, [[optManaged.boolObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:@NO]);
    uncheckedAssertEqual(0U, [[optManaged.intObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:@2]);
    uncheckedAssertEqual(0U, [[optManaged.stringObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:@"bar"]);
    uncheckedAssertEqual(0U, [[optManaged.dateObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:date(1)]);
    uncheckedAssertEqual(1U, [[optManaged.boolObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:(id)NSNull.null]);
    uncheckedAssertEqual(1U, [[optManaged.intObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:(id)NSNull.null]);
    uncheckedAssertEqual(1U, [[optManaged.stringObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:(id)NSNull.null]);
    uncheckedAssertEqual(1U, [[optManaged.dateObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:(id)NSNull.null]);
    uncheckedAssertEqual(1U, [[managed.boolObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:@NO]);
    uncheckedAssertEqual(1U, [[managed.intObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:@2]);
    uncheckedAssertEqual(1U, [[managed.stringObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:@"bar"]);
    uncheckedAssertEqual(1U, [[managed.dateObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:date(1)]);
    uncheckedAssertEqual(1U, [[managed.anyBoolObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:@NO]);
    uncheckedAssertEqual(1U, [[managed.anyIntObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:@2]);
    uncheckedAssertEqual(1U, [[managed.anyFloatObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:@2.2f]);
    uncheckedAssertEqual(1U, [[managed.anyDoubleObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:@2.2]);
    uncheckedAssertEqual(1U, [[managed.anyStringObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:@"a"]);
    uncheckedAssertEqual(1U, [[managed.anyDataObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:data(1)]);
    uncheckedAssertEqual(1U, [[managed.anyDateObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:date(1)]);
    uncheckedAssertEqual(1U, [[managed.anyDecimalObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:decimal128(2)]);
    uncheckedAssertEqual(1U, [[managed.anyUUIDObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:uuid(@"00000000-0000-0000-0000-000000000000")]);
    uncheckedAssertEqual(0U, [[managed.boolObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:@YES]);
    uncheckedAssertEqual(0U, [[managed.intObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:@3]);
    uncheckedAssertEqual(0U, [[managed.stringObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:@"foo"]);
    uncheckedAssertEqual(0U, [[managed.dateObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:date(2)]);
    uncheckedAssertEqual(0U, [[managed.anyBoolObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:@YES]);
    uncheckedAssertEqual(0U, [[managed.anyIntObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:@3]);
    uncheckedAssertEqual(0U, [[managed.anyFloatObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:@3.3f]);
    uncheckedAssertEqual(0U, [[managed.anyDoubleObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:@3.3]);
    uncheckedAssertEqual(0U, [[managed.anyStringObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:@"b"]);
    uncheckedAssertEqual(0U, [[managed.anyDataObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:data(2)]);
    uncheckedAssertEqual(0U, [[managed.anyDateObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:date(2)]);
    uncheckedAssertEqual(0U, [[managed.anyDecimalObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:decimal128(3)]);
    uncheckedAssertEqual(0U, [[managed.anyUUIDObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")]);

    uncheckedAssertEqual(1U, [[optManaged.boolObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:(id)NSNull.null]);
    uncheckedAssertEqual(1U, [[optManaged.intObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:(id)NSNull.null]);
    uncheckedAssertEqual(1U, [[optManaged.stringObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:(id)NSNull.null]);
    uncheckedAssertEqual(1U, [[optManaged.dateObj sortedResultsUsingKeyPath:@"self" ascending:NO] indexOfObject:(id)NSNull.null]);
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

    uncheckedAssertEqual(1U, [[managed.boolObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:@NO]);
    uncheckedAssertEqual(1U, [[managed.intObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:@2]);
    uncheckedAssertEqual(1U, [[managed.stringObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:@"bar"]);
    uncheckedAssertEqual(1U, [[managed.dateObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:date(1)]);
    uncheckedAssertEqual(1U, [[managed.anyBoolObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:@NO]);
    uncheckedAssertEqual(1U, [[managed.anyIntObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:@2]);
    uncheckedAssertEqual(1U, [[managed.anyFloatObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:@2.2f]);
    uncheckedAssertEqual(1U, [[managed.anyDoubleObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:@2.2]);
    uncheckedAssertEqual(1U, [[managed.anyStringObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:@"a"]);
    uncheckedAssertEqual(1U, [[managed.anyDataObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:data(1)]);
    uncheckedAssertEqual(1U, [[managed.anyDateObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:date(1)]);
    uncheckedAssertEqual(1U, [[managed.anyDecimalObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:decimal128(2)]);
    uncheckedAssertEqual(1U, [[managed.anyUUIDObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:uuid(@"00000000-0000-0000-0000-000000000000")]);
    uncheckedAssertEqual(0U, [[managed.boolObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:@YES]);
    uncheckedAssertEqual(0U, [[managed.intObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:@3]);
    uncheckedAssertEqual(0U, [[managed.stringObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:@"foo"]);
    uncheckedAssertEqual(0U, [[managed.dateObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:date(2)]);
    uncheckedAssertEqual(0U, [[managed.anyBoolObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:@YES]);
    uncheckedAssertEqual(0U, [[managed.anyIntObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:@3]);
    uncheckedAssertEqual(0U, [[managed.anyFloatObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:@3.3f]);
    uncheckedAssertEqual(0U, [[managed.anyDoubleObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:@3.3]);
    uncheckedAssertEqual(0U, [[managed.anyStringObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:@"b"]);
    uncheckedAssertEqual(0U, [[managed.anyDataObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:data(2)]);
    uncheckedAssertEqual(0U, [[managed.anyDateObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:date(2)]);
    uncheckedAssertEqual(0U, [[managed.anyDecimalObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:decimal128(3)]);
    uncheckedAssertEqual(0U, [[managed.anyUUIDObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")]);

    uncheckedAssertEqual(1U, [[optManaged.boolObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:@NO]);
    uncheckedAssertEqual(1U, [[optManaged.intObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:@2]);
    uncheckedAssertEqual(1U, [[optManaged.stringObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:@"bar"]);
    uncheckedAssertEqual(1U, [[optManaged.dateObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:date(1)]);
    uncheckedAssertEqual(0U, [[optManaged.boolObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:(id)NSNull.null]);
    uncheckedAssertEqual(0U, [[optManaged.intObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:(id)NSNull.null]);
    uncheckedAssertEqual(0U, [[optManaged.stringObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:(id)NSNull.null]);
    uncheckedAssertEqual(0U, [[optManaged.dateObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:(id)NSNull.null]);
    uncheckedAssertEqual(0U, [[optManaged.boolObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:(id)NSNull.null]);
    uncheckedAssertEqual(0U, [[optManaged.intObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:(id)NSNull.null]);
    uncheckedAssertEqual(0U, [[optManaged.stringObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:(id)NSNull.null]);
    uncheckedAssertEqual(0U, [[optManaged.dateObj distinctResultsUsingKeyPaths:@[@"self"]] indexOfObject:(id)NSNull.null]);
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

    uncheckedAssertEqualObjects([[managed.boolObj sortedResultsUsingDescriptors:@[]] valueForKey:@"self"],
                                (@[@YES, @NO]));
    uncheckedAssertEqualObjects([[optManaged.boolObj sortedResultsUsingDescriptors:@[]] valueForKey:@"self"],
                                (@[NSNull.null, @NO]));
    uncheckedAssertEqualObjects([[managed.intObj sortedResultsUsingDescriptors:@[]] valueForKey:@"self"],
                                (@[@3, @2]));
    uncheckedAssertEqualObjects([[optManaged.intObj sortedResultsUsingDescriptors:@[]] valueForKey:@"self"],
                                (@[NSNull.null, @2]));
    uncheckedAssertEqualObjects([[managed.stringObj sortedResultsUsingDescriptors:@[]] valueForKey:@"self"],
                                (@[@"foo", @"bar"]));
    uncheckedAssertEqualObjects([[optManaged.stringObj sortedResultsUsingDescriptors:@[]] valueForKey:@"self"],
                                (@[NSNull.null, @"bar"]));
    uncheckedAssertEqualObjects([[managed.dateObj sortedResultsUsingDescriptors:@[]] valueForKey:@"self"],
                                (@[date(2), date(1)]));
    uncheckedAssertEqualObjects([[optManaged.dateObj sortedResultsUsingDescriptors:@[]] valueForKey:@"self"],
                                (@[NSNull.null, date(1)]));
    uncheckedAssertEqualObjects([[managed.anyBoolObj sortedResultsUsingDescriptors:@[]] valueForKey:@"self"],
                                (@[@YES, @NO]));
    uncheckedAssertEqualObjects([[managed.anyIntObj sortedResultsUsingDescriptors:@[]] valueForKey:@"self"],
                                (@[@3, @2]));
    uncheckedAssertEqualObjects([[managed.anyFloatObj sortedResultsUsingDescriptors:@[]] valueForKey:@"self"],
                                (@[@3.3f, @2.2f]));
    uncheckedAssertEqualObjects([[managed.anyDoubleObj sortedResultsUsingDescriptors:@[]] valueForKey:@"self"],
                                (@[@3.3, @2.2]));
    uncheckedAssertEqualObjects([[managed.anyStringObj sortedResultsUsingDescriptors:@[]] valueForKey:@"self"],
                                (@[@"b", @"a"]));
    uncheckedAssertEqualObjects([[managed.anyDataObj sortedResultsUsingDescriptors:@[]] valueForKey:@"self"],
                                (@[data(2), data(1)]));
    uncheckedAssertEqualObjects([[managed.anyDateObj sortedResultsUsingDescriptors:@[]] valueForKey:@"self"],
                                (@[date(2), date(1)]));
    uncheckedAssertEqualObjects([[managed.anyDecimalObj sortedResultsUsingDescriptors:@[]] valueForKey:@"self"],
                                (@[decimal128(3), decimal128(2)]));
    uncheckedAssertEqualObjects([[managed.anyUUIDObj sortedResultsUsingDescriptors:@[]] valueForKey:@"self"],
                                (@[uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"), uuid(@"00000000-0000-0000-0000-000000000000")]));

    uncheckedAssertEqualObjects([[managed.boolObj sortedResultsUsingKeyPath:@"self" ascending:NO] valueForKey:@"self"],
                                (@[@YES, @NO]));
    uncheckedAssertEqualObjects([[managed.intObj sortedResultsUsingKeyPath:@"self" ascending:NO] valueForKey:@"self"],
                                (@[@3, @2]));
    uncheckedAssertEqualObjects([[managed.stringObj sortedResultsUsingKeyPath:@"self" ascending:NO] valueForKey:@"self"],
                                (@[@"foo", @"bar"]));
    uncheckedAssertEqualObjects([[managed.dateObj sortedResultsUsingKeyPath:@"self" ascending:NO] valueForKey:@"self"],
                                (@[date(2), date(1)]));
    uncheckedAssertEqualObjects([[managed.anyBoolObj sortedResultsUsingKeyPath:@"self" ascending:NO] valueForKey:@"self"],
                                (@[@YES, @NO]));
    uncheckedAssertEqualObjects([[managed.anyIntObj sortedResultsUsingKeyPath:@"self" ascending:NO] valueForKey:@"self"],
                                (@[@3, @2]));
    uncheckedAssertEqualObjects([[managed.anyFloatObj sortedResultsUsingKeyPath:@"self" ascending:NO] valueForKey:@"self"],
                                (@[@3.3f, @2.2f]));
    uncheckedAssertEqualObjects([[managed.anyDoubleObj sortedResultsUsingKeyPath:@"self" ascending:NO] valueForKey:@"self"],
                                (@[@3.3, @2.2]));
    uncheckedAssertEqualObjects([[managed.anyStringObj sortedResultsUsingKeyPath:@"self" ascending:NO] valueForKey:@"self"],
                                (@[@"b", @"a"]));
    uncheckedAssertEqualObjects([[managed.anyDataObj sortedResultsUsingKeyPath:@"self" ascending:NO] valueForKey:@"self"],
                                (@[data(2), data(1)]));
    uncheckedAssertEqualObjects([[managed.anyDateObj sortedResultsUsingKeyPath:@"self" ascending:NO] valueForKey:@"self"],
                                (@[date(2), date(1)]));
    uncheckedAssertEqualObjects([[managed.anyDecimalObj sortedResultsUsingKeyPath:@"self" ascending:NO] valueForKey:@"self"],
                                (@[decimal128(3), decimal128(2)]));
    uncheckedAssertEqualObjects([[managed.anyUUIDObj sortedResultsUsingKeyPath:@"self" ascending:NO] valueForKey:@"self"],
                                (@[uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"), uuid(@"00000000-0000-0000-0000-000000000000")]));
    uncheckedAssertEqualObjects([[optManaged.boolObj sortedResultsUsingKeyPath:@"self" ascending:NO] valueForKey:@"self"],
                                (@[@NO, NSNull.null]));
    uncheckedAssertEqualObjects([[optManaged.intObj sortedResultsUsingKeyPath:@"self" ascending:NO] valueForKey:@"self"],
                                (@[@2, NSNull.null]));
    uncheckedAssertEqualObjects([[optManaged.stringObj sortedResultsUsingKeyPath:@"self" ascending:NO] valueForKey:@"self"],
                                (@[@"bar", NSNull.null]));
    uncheckedAssertEqualObjects([[optManaged.dateObj sortedResultsUsingKeyPath:@"self" ascending:NO] valueForKey:@"self"],
                                (@[date(1), NSNull.null]));

    uncheckedAssertEqualObjects([[managed.boolObj sortedResultsUsingKeyPath:@"self" ascending:YES] valueForKey:@"self"],
                                (@[@NO, @YES]));
    uncheckedAssertEqualObjects([[managed.intObj sortedResultsUsingKeyPath:@"self" ascending:YES] valueForKey:@"self"],
                                (@[@2, @3]));
    uncheckedAssertEqualObjects([[managed.stringObj sortedResultsUsingKeyPath:@"self" ascending:YES] valueForKey:@"self"],
                                (@[@"bar", @"foo"]));
    uncheckedAssertEqualObjects([[managed.dateObj sortedResultsUsingKeyPath:@"self" ascending:YES] valueForKey:@"self"],
                                (@[date(1), date(2)]));
    uncheckedAssertEqualObjects([[managed.anyBoolObj sortedResultsUsingKeyPath:@"self" ascending:YES] valueForKey:@"self"],
                                (@[@NO, @YES]));
    uncheckedAssertEqualObjects([[managed.anyIntObj sortedResultsUsingKeyPath:@"self" ascending:YES] valueForKey:@"self"],
                                (@[@2, @3]));
    uncheckedAssertEqualObjects([[managed.anyFloatObj sortedResultsUsingKeyPath:@"self" ascending:YES] valueForKey:@"self"],
                                (@[@2.2f, @3.3f]));
    uncheckedAssertEqualObjects([[managed.anyDoubleObj sortedResultsUsingKeyPath:@"self" ascending:YES] valueForKey:@"self"],
                                (@[@2.2, @3.3]));
    uncheckedAssertEqualObjects([[managed.anyStringObj sortedResultsUsingKeyPath:@"self" ascending:YES] valueForKey:@"self"],
                                (@[@"a", @"b"]));
    uncheckedAssertEqualObjects([[managed.anyDataObj sortedResultsUsingKeyPath:@"self" ascending:YES] valueForKey:@"self"],
                                (@[data(1), data(2)]));
    uncheckedAssertEqualObjects([[managed.anyDateObj sortedResultsUsingKeyPath:@"self" ascending:YES] valueForKey:@"self"],
                                (@[date(1), date(2)]));
    uncheckedAssertEqualObjects([[managed.anyDecimalObj sortedResultsUsingKeyPath:@"self" ascending:YES] valueForKey:@"self"],
                                (@[decimal128(2), decimal128(3)]));
    uncheckedAssertEqualObjects([[managed.anyUUIDObj sortedResultsUsingKeyPath:@"self" ascending:YES] valueForKey:@"self"],
                                (@[uuid(@"00000000-0000-0000-0000-000000000000"), uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")]));
    uncheckedAssertEqualObjects([[optManaged.boolObj sortedResultsUsingKeyPath:@"self" ascending:YES] valueForKey:@"self"],
                                (@[NSNull.null, @NO]));
    uncheckedAssertEqualObjects([[optManaged.intObj sortedResultsUsingKeyPath:@"self" ascending:YES] valueForKey:@"self"],
                                (@[NSNull.null, @2]));
    uncheckedAssertEqualObjects([[optManaged.stringObj sortedResultsUsingKeyPath:@"self" ascending:YES] valueForKey:@"self"],
                                (@[NSNull.null, @"bar"]));
    uncheckedAssertEqualObjects([[optManaged.dateObj sortedResultsUsingKeyPath:@"self" ascending:YES] valueForKey:@"self"],
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

    uncheckedAssertNil([unmanaged.intObj minOfProperty:@"self"]);
    uncheckedAssertNil([optUnmanaged.intObj minOfProperty:@"self"]);
    uncheckedAssertNil([managed.intObj minOfProperty:@"self"]);
    uncheckedAssertNil([optManaged.intObj minOfProperty:@"self"]);
    uncheckedAssertNil([unmanaged.dateObj minOfProperty:@"self"]);
    uncheckedAssertNil([optUnmanaged.dateObj minOfProperty:@"self"]);
    uncheckedAssertNil([managed.dateObj minOfProperty:@"self"]);
    uncheckedAssertNil([optManaged.dateObj minOfProperty:@"self"]);
    uncheckedAssertNil([unmanaged.floatObj minOfProperty:@"self"]);
    uncheckedAssertNil([optUnmanaged.floatObj minOfProperty:@"self"]);
    uncheckedAssertNil([managed.floatObj minOfProperty:@"self"]);
    uncheckedAssertNil([optManaged.floatObj minOfProperty:@"self"]);
    uncheckedAssertNil([unmanaged.doubleObj minOfProperty:@"self"]);
    uncheckedAssertNil([optUnmanaged.doubleObj minOfProperty:@"self"]);
    uncheckedAssertNil([managed.doubleObj minOfProperty:@"self"]);
    uncheckedAssertNil([optManaged.doubleObj minOfProperty:@"self"]);
    uncheckedAssertNil([unmanaged.decimalObj minOfProperty:@"self"]);
    uncheckedAssertNil([optUnmanaged.decimalObj minOfProperty:@"self"]);
    uncheckedAssertNil([managed.decimalObj minOfProperty:@"self"]);
    uncheckedAssertNil([optManaged.decimalObj minOfProperty:@"self"]);
    uncheckedAssertNil([unmanaged.anyFloatObj minOfProperty:@"self"]);
    uncheckedAssertNil([unmanaged.anyDoubleObj minOfProperty:@"self"]);
    uncheckedAssertNil([unmanaged.anyDateObj minOfProperty:@"self"]);
    uncheckedAssertNil([unmanaged.anyDecimalObj minOfProperty:@"self"]);
    uncheckedAssertNil([managed.anyFloatObj minOfProperty:@"self"]);
    uncheckedAssertNil([managed.anyDoubleObj minOfProperty:@"self"]);
    uncheckedAssertNil([managed.anyDecimalObj minOfProperty:@"self"]);

    [self addObjects];

    uncheckedAssertEqualObjects([unmanaged.intObj minOfProperty:@"self"], @2);
    uncheckedAssertEqualObjects([optUnmanaged.intObj minOfProperty:@"self"], @2);
    uncheckedAssertEqualObjects([managed.intObj minOfProperty:@"self"], @2);
    uncheckedAssertEqualObjects([optManaged.intObj minOfProperty:@"self"], @2);
    uncheckedAssertEqualObjects([unmanaged.dateObj minOfProperty:@"self"], date(1));
    uncheckedAssertEqualObjects([optUnmanaged.dateObj minOfProperty:@"self"], date(1));
    uncheckedAssertEqualObjects([managed.dateObj minOfProperty:@"self"], date(1));
    uncheckedAssertEqualObjects([optManaged.dateObj minOfProperty:@"self"], date(1));
    uncheckedAssertEqualObjects([unmanaged.floatObj minOfProperty:@"self"], @2.2f);
    uncheckedAssertEqualObjects([optUnmanaged.floatObj minOfProperty:@"self"], @2.2f);
    uncheckedAssertEqualObjects([managed.floatObj minOfProperty:@"self"], @2.2f);
    uncheckedAssertEqualObjects([optManaged.floatObj minOfProperty:@"self"], @2.2f);
    uncheckedAssertEqualObjects([unmanaged.doubleObj minOfProperty:@"self"], @2.2);
    uncheckedAssertEqualObjects([optUnmanaged.doubleObj minOfProperty:@"self"], @2.2);
    uncheckedAssertEqualObjects([managed.doubleObj minOfProperty:@"self"], @2.2);
    uncheckedAssertEqualObjects([optManaged.doubleObj minOfProperty:@"self"], @2.2);
    uncheckedAssertEqualObjects([unmanaged.decimalObj minOfProperty:@"self"], decimal128(2));
    uncheckedAssertEqualObjects([optUnmanaged.decimalObj minOfProperty:@"self"], decimal128(2));
    uncheckedAssertEqualObjects([managed.decimalObj minOfProperty:@"self"], decimal128(2));
    uncheckedAssertEqualObjects([optManaged.decimalObj minOfProperty:@"self"], decimal128(2));
    uncheckedAssertEqualObjects([unmanaged.anyFloatObj minOfProperty:@"self"], @2.2f);
    uncheckedAssertEqualObjects([unmanaged.anyDoubleObj minOfProperty:@"self"], @2.2);
    uncheckedAssertEqualObjects([unmanaged.anyDateObj minOfProperty:@"self"], date(1));
    uncheckedAssertEqualObjects([unmanaged.anyDecimalObj minOfProperty:@"self"], decimal128(2));
    uncheckedAssertEqualObjects([managed.anyFloatObj minOfProperty:@"self"], @2.2f);
    uncheckedAssertEqualObjects([managed.anyDoubleObj minOfProperty:@"self"], @2.2);
    uncheckedAssertEqualObjects([managed.anyDecimalObj minOfProperty:@"self"], decimal128(2));
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

    uncheckedAssertNil([unmanaged.intObj maxOfProperty:@"self"]);
    uncheckedAssertNil([optUnmanaged.intObj maxOfProperty:@"self"]);
    uncheckedAssertNil([managed.intObj maxOfProperty:@"self"]);
    uncheckedAssertNil([optManaged.intObj maxOfProperty:@"self"]);
    uncheckedAssertNil([unmanaged.dateObj maxOfProperty:@"self"]);
    uncheckedAssertNil([optUnmanaged.dateObj maxOfProperty:@"self"]);
    uncheckedAssertNil([managed.dateObj maxOfProperty:@"self"]);
    uncheckedAssertNil([optManaged.dateObj maxOfProperty:@"self"]);
    uncheckedAssertNil([unmanaged.floatObj maxOfProperty:@"self"]);
    uncheckedAssertNil([optUnmanaged.floatObj maxOfProperty:@"self"]);
    uncheckedAssertNil([managed.floatObj maxOfProperty:@"self"]);
    uncheckedAssertNil([optManaged.floatObj maxOfProperty:@"self"]);
    uncheckedAssertNil([unmanaged.doubleObj maxOfProperty:@"self"]);
    uncheckedAssertNil([optUnmanaged.doubleObj maxOfProperty:@"self"]);
    uncheckedAssertNil([managed.doubleObj maxOfProperty:@"self"]);
    uncheckedAssertNil([optManaged.doubleObj maxOfProperty:@"self"]);
    uncheckedAssertNil([unmanaged.decimalObj maxOfProperty:@"self"]);
    uncheckedAssertNil([optUnmanaged.decimalObj maxOfProperty:@"self"]);
    uncheckedAssertNil([managed.decimalObj maxOfProperty:@"self"]);
    uncheckedAssertNil([optManaged.decimalObj maxOfProperty:@"self"]);
    uncheckedAssertNil([unmanaged.anyFloatObj maxOfProperty:@"self"]);
    uncheckedAssertNil([unmanaged.anyDoubleObj maxOfProperty:@"self"]);
    uncheckedAssertNil([unmanaged.anyDateObj maxOfProperty:@"self"]);
    uncheckedAssertNil([unmanaged.anyDecimalObj maxOfProperty:@"self"]);
    uncheckedAssertNil([managed.anyFloatObj maxOfProperty:@"self"]);
    uncheckedAssertNil([managed.anyDoubleObj maxOfProperty:@"self"]);
    uncheckedAssertNil([managed.anyDecimalObj maxOfProperty:@"self"]);

    [self addObjects];

    uncheckedAssertEqualObjects([unmanaged.intObj maxOfProperty:@"self"], @3);
    uncheckedAssertEqualObjects([managed.intObj maxOfProperty:@"self"], @3);
    uncheckedAssertEqualObjects([unmanaged.dateObj maxOfProperty:@"self"], date(2));
    uncheckedAssertEqualObjects([managed.dateObj maxOfProperty:@"self"], date(2));
    uncheckedAssertEqualObjects([unmanaged.floatObj maxOfProperty:@"self"], @3.3f);
    uncheckedAssertEqualObjects([managed.floatObj maxOfProperty:@"self"], @3.3f);
    uncheckedAssertEqualObjects([unmanaged.doubleObj maxOfProperty:@"self"], @3.3);
    uncheckedAssertEqualObjects([managed.doubleObj maxOfProperty:@"self"], @3.3);
    uncheckedAssertEqualObjects([unmanaged.decimalObj maxOfProperty:@"self"], decimal128(3));
    uncheckedAssertEqualObjects([managed.decimalObj maxOfProperty:@"self"], decimal128(3));
    uncheckedAssertEqualObjects([unmanaged.anyFloatObj maxOfProperty:@"self"], @3.3f);
    uncheckedAssertEqualObjects([unmanaged.anyDoubleObj maxOfProperty:@"self"], @3.3);
    uncheckedAssertEqualObjects([unmanaged.anyDateObj maxOfProperty:@"self"], date(2));
    uncheckedAssertEqualObjects([unmanaged.anyDecimalObj maxOfProperty:@"self"], decimal128(3));
    uncheckedAssertEqualObjects([managed.anyFloatObj maxOfProperty:@"self"], @3.3f);
    uncheckedAssertEqualObjects([managed.anyDoubleObj maxOfProperty:@"self"], @3.3);
    uncheckedAssertEqualObjects([managed.anyDecimalObj maxOfProperty:@"self"], decimal128(3));
    uncheckedAssertEqualObjects([optUnmanaged.intObj maxOfProperty:@"self"], @2);
    uncheckedAssertEqualObjects([optManaged.intObj maxOfProperty:@"self"], @2);
    uncheckedAssertEqualObjects([optUnmanaged.dateObj maxOfProperty:@"self"], date(1));
    uncheckedAssertEqualObjects([optManaged.dateObj maxOfProperty:@"self"], date(1));
    uncheckedAssertEqualObjects([optUnmanaged.floatObj maxOfProperty:@"self"], @2.2f);
    uncheckedAssertEqualObjects([optManaged.floatObj maxOfProperty:@"self"], @2.2f);
    uncheckedAssertEqualObjects([optUnmanaged.doubleObj maxOfProperty:@"self"], @2.2);
    uncheckedAssertEqualObjects([optManaged.doubleObj maxOfProperty:@"self"], @2.2);
    uncheckedAssertEqualObjects([optUnmanaged.decimalObj maxOfProperty:@"self"], decimal128(2));
    uncheckedAssertEqualObjects([optManaged.decimalObj maxOfProperty:@"self"], decimal128(2));
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

    uncheckedAssertEqualObjects([unmanaged.intObj sumOfProperty:@"self"], @0);
    uncheckedAssertEqualObjects([optUnmanaged.intObj sumOfProperty:@"self"], @0);
    uncheckedAssertEqualObjects([managed.intObj sumOfProperty:@"self"], @0);
    uncheckedAssertEqualObjects([optManaged.intObj sumOfProperty:@"self"], @0);
    uncheckedAssertEqualObjects([unmanaged.floatObj sumOfProperty:@"self"], @0);
    uncheckedAssertEqualObjects([optUnmanaged.floatObj sumOfProperty:@"self"], @0);
    uncheckedAssertEqualObjects([managed.floatObj sumOfProperty:@"self"], @0);
    uncheckedAssertEqualObjects([optManaged.floatObj sumOfProperty:@"self"], @0);
    uncheckedAssertEqualObjects([unmanaged.doubleObj sumOfProperty:@"self"], @0);
    uncheckedAssertEqualObjects([optUnmanaged.doubleObj sumOfProperty:@"self"], @0);
    uncheckedAssertEqualObjects([managed.doubleObj sumOfProperty:@"self"], @0);
    uncheckedAssertEqualObjects([optManaged.doubleObj sumOfProperty:@"self"], @0);
    uncheckedAssertEqualObjects([unmanaged.decimalObj sumOfProperty:@"self"], @0);
    uncheckedAssertEqualObjects([optUnmanaged.decimalObj sumOfProperty:@"self"], @0);
    uncheckedAssertEqualObjects([managed.decimalObj sumOfProperty:@"self"], @0);
    uncheckedAssertEqualObjects([optManaged.decimalObj sumOfProperty:@"self"], @0);
    uncheckedAssertEqualObjects([unmanaged.anyIntObj sumOfProperty:@"self"], @0);
    uncheckedAssertEqualObjects([unmanaged.anyFloatObj sumOfProperty:@"self"], @0);
    uncheckedAssertEqualObjects([unmanaged.anyDoubleObj sumOfProperty:@"self"], @0);
    uncheckedAssertEqualObjects([unmanaged.anyDecimalObj sumOfProperty:@"self"], @0);
    uncheckedAssertEqualObjects([managed.anyIntObj sumOfProperty:@"self"], @0);
    uncheckedAssertEqualObjects([managed.anyFloatObj sumOfProperty:@"self"], @0);
    uncheckedAssertEqualObjects([managed.anyDoubleObj sumOfProperty:@"self"], @0);
    uncheckedAssertEqualObjects([managed.anyDecimalObj sumOfProperty:@"self"], @0);

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

    uncheckedAssertNil([unmanaged.intObj averageOfProperty:@"self"]);
    uncheckedAssertNil([optUnmanaged.intObj averageOfProperty:@"self"]);
    uncheckedAssertNil([managed.intObj averageOfProperty:@"self"]);
    uncheckedAssertNil([optManaged.intObj averageOfProperty:@"self"]);
    uncheckedAssertNil([unmanaged.floatObj averageOfProperty:@"self"]);
    uncheckedAssertNil([optUnmanaged.floatObj averageOfProperty:@"self"]);
    uncheckedAssertNil([managed.floatObj averageOfProperty:@"self"]);
    uncheckedAssertNil([optManaged.floatObj averageOfProperty:@"self"]);
    uncheckedAssertNil([unmanaged.doubleObj averageOfProperty:@"self"]);
    uncheckedAssertNil([optUnmanaged.doubleObj averageOfProperty:@"self"]);
    uncheckedAssertNil([managed.doubleObj averageOfProperty:@"self"]);
    uncheckedAssertNil([optManaged.doubleObj averageOfProperty:@"self"]);
    uncheckedAssertNil([unmanaged.decimalObj averageOfProperty:@"self"]);
    uncheckedAssertNil([optUnmanaged.decimalObj averageOfProperty:@"self"]);
    uncheckedAssertNil([managed.decimalObj averageOfProperty:@"self"]);
    uncheckedAssertNil([optManaged.decimalObj averageOfProperty:@"self"]);
    uncheckedAssertNil([unmanaged.anyIntObj averageOfProperty:@"self"]);
    uncheckedAssertNil([unmanaged.anyFloatObj averageOfProperty:@"self"]);
    uncheckedAssertNil([unmanaged.anyDoubleObj averageOfProperty:@"self"]);
    uncheckedAssertNil([unmanaged.anyDecimalObj averageOfProperty:@"self"]);
    uncheckedAssertNil([managed.anyIntObj averageOfProperty:@"self"]);
    uncheckedAssertNil([managed.anyFloatObj averageOfProperty:@"self"]);
    uncheckedAssertNil([managed.anyDoubleObj averageOfProperty:@"self"]);
    uncheckedAssertNil([managed.anyDecimalObj averageOfProperty:@"self"]);

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

    // This is wrapped in a block to work around a compiler bug in Xcode 12.5:
    // in release builds, reads on `values` will read the wrong local variable,
    // resulting in a crash when it tries to send a message to some unitialized
    // stack space. Putting them in separate obj-c blocks prevents this
    // incorrect optimization.
    ^{
    NSDictionary *values = @{ @"key1": @NO, @"key2": @YES };
    for (id key in unmanaged.boolObj) {
        id value = unmanaged.boolObj[key];
        uncheckedAssertEqualObjects(values[key], value);
    }
    uncheckedAssertEqual(values.count, unmanaged.boolObj.count);
    }();
    
    ^{
    NSDictionary *values = @{ @"key1": @NO, @"key2": NSNull.null };
    for (id key in optUnmanaged.boolObj) {
        id value = optUnmanaged.boolObj[key];
        uncheckedAssertEqualObjects(values[key], value);
    }
    uncheckedAssertEqual(values.count, optUnmanaged.boolObj.count);
    }();
    
    ^{
    NSDictionary *values = @{ @"key1": @NO, @"key2": @YES };
    for (id key in managed.boolObj) {
        id value = managed.boolObj[key];
        uncheckedAssertEqualObjects(values[key], value);
    }
    uncheckedAssertEqual(values.count, managed.boolObj.count);
    }();
    
    ^{
    NSDictionary *values = @{ @"key1": @NO, @"key2": NSNull.null };
    for (id key in optManaged.boolObj) {
        id value = optManaged.boolObj[key];
        uncheckedAssertEqualObjects(values[key], value);
    }
    uncheckedAssertEqual(values.count, optManaged.boolObj.count);
    }();
    
    ^{
    NSDictionary *values = @{ @"key1": @2, @"key2": @3 };
    for (id key in unmanaged.intObj) {
        id value = unmanaged.intObj[key];
        uncheckedAssertEqualObjects(values[key], value);
    }
    uncheckedAssertEqual(values.count, unmanaged.intObj.count);
    }();
    
    ^{
    NSDictionary *values = @{ @"key1": @2, @"key2": NSNull.null };
    for (id key in optUnmanaged.intObj) {
        id value = optUnmanaged.intObj[key];
        uncheckedAssertEqualObjects(values[key], value);
    }
    uncheckedAssertEqual(values.count, optUnmanaged.intObj.count);
    }();
    
    ^{
    NSDictionary *values = @{ @"key1": @2, @"key2": @3 };
    for (id key in managed.intObj) {
        id value = managed.intObj[key];
        uncheckedAssertEqualObjects(values[key], value);
    }
    uncheckedAssertEqual(values.count, managed.intObj.count);
    }();
    
    ^{
    NSDictionary *values = @{ @"key1": @2, @"key2": NSNull.null };
    for (id key in optManaged.intObj) {
        id value = optManaged.intObj[key];
        uncheckedAssertEqualObjects(values[key], value);
    }
    uncheckedAssertEqual(values.count, optManaged.intObj.count);
    }();
    
    ^{
    NSDictionary *values = @{ @"key1": @"bar", @"key2": @"foo" };
    for (id key in unmanaged.stringObj) {
        id value = unmanaged.stringObj[key];
        uncheckedAssertEqualObjects(values[key], value);
    }
    uncheckedAssertEqual(values.count, unmanaged.stringObj.count);
    }();
    
    ^{
    NSDictionary *values = @{ @"key1": @"bar", @"key2": NSNull.null };
    for (id key in optUnmanaged.stringObj) {
        id value = optUnmanaged.stringObj[key];
        uncheckedAssertEqualObjects(values[key], value);
    }
    uncheckedAssertEqual(values.count, optUnmanaged.stringObj.count);
    }();
    
    ^{
    NSDictionary *values = @{ @"key1": @"bar", @"key2": @"foo" };
    for (id key in managed.stringObj) {
        id value = managed.stringObj[key];
        uncheckedAssertEqualObjects(values[key], value);
    }
    uncheckedAssertEqual(values.count, managed.stringObj.count);
    }();
    
    ^{
    NSDictionary *values = @{ @"key1": @"bar", @"key2": NSNull.null };
    for (id key in optManaged.stringObj) {
        id value = optManaged.stringObj[key];
        uncheckedAssertEqualObjects(values[key], value);
    }
    uncheckedAssertEqual(values.count, optManaged.stringObj.count);
    }();
    
    ^{
    NSDictionary *values = @{ @"key1": date(1), @"key2": date(2) };
    for (id key in unmanaged.dateObj) {
        id value = unmanaged.dateObj[key];
        uncheckedAssertEqualObjects(values[key], value);
    }
    uncheckedAssertEqual(values.count, unmanaged.dateObj.count);
    }();
    
    ^{
    NSDictionary *values = @{ @"key1": date(1), @"key2": NSNull.null };
    for (id key in optUnmanaged.dateObj) {
        id value = optUnmanaged.dateObj[key];
        uncheckedAssertEqualObjects(values[key], value);
    }
    uncheckedAssertEqual(values.count, optUnmanaged.dateObj.count);
    }();
    
    ^{
    NSDictionary *values = @{ @"key1": date(1), @"key2": date(2) };
    for (id key in managed.dateObj) {
        id value = managed.dateObj[key];
        uncheckedAssertEqualObjects(values[key], value);
    }
    uncheckedAssertEqual(values.count, managed.dateObj.count);
    }();
    
    ^{
    NSDictionary *values = @{ @"key1": date(1), @"key2": NSNull.null };
    for (id key in optManaged.dateObj) {
        id value = optManaged.dateObj[key];
        uncheckedAssertEqualObjects(values[key], value);
    }
    uncheckedAssertEqual(values.count, optManaged.dateObj.count);
    }();
    
    ^{
    NSDictionary *values = @{ @"key1": @2.2f, @"key2": @3.3f };
    for (id key in unmanaged.floatObj) {
        id value = unmanaged.floatObj[key];
        uncheckedAssertEqualObjects(values[key], value);
    }
    uncheckedAssertEqual(values.count, unmanaged.floatObj.count);
    }();
    
    ^{
    NSDictionary *values = @{ @"key1": @2.2f, @"key2": NSNull.null };
    for (id key in optUnmanaged.floatObj) {
        id value = optUnmanaged.floatObj[key];
        uncheckedAssertEqualObjects(values[key], value);
    }
    uncheckedAssertEqual(values.count, optUnmanaged.floatObj.count);
    }();
    
    ^{
    NSDictionary *values = @{ @"key1": @2.2f, @"key2": @3.3f };
    for (id key in managed.floatObj) {
        id value = managed.floatObj[key];
        uncheckedAssertEqualObjects(values[key], value);
    }
    uncheckedAssertEqual(values.count, managed.floatObj.count);
    }();
    
    ^{
    NSDictionary *values = @{ @"key1": @2.2f, @"key2": NSNull.null };
    for (id key in optManaged.floatObj) {
        id value = optManaged.floatObj[key];
        uncheckedAssertEqualObjects(values[key], value);
    }
    uncheckedAssertEqual(values.count, optManaged.floatObj.count);
    }();
    
    ^{
    NSDictionary *values = @{ @"key1": @2.2, @"key2": @3.3 };
    for (id key in unmanaged.doubleObj) {
        id value = unmanaged.doubleObj[key];
        uncheckedAssertEqualObjects(values[key], value);
    }
    uncheckedAssertEqual(values.count, unmanaged.doubleObj.count);
    }();
    
    ^{
    NSDictionary *values = @{ @"key1": @2.2, @"key2": NSNull.null };
    for (id key in optUnmanaged.doubleObj) {
        id value = optUnmanaged.doubleObj[key];
        uncheckedAssertEqualObjects(values[key], value);
    }
    uncheckedAssertEqual(values.count, optUnmanaged.doubleObj.count);
    }();
    
    ^{
    NSDictionary *values = @{ @"key1": @2.2, @"key2": @3.3 };
    for (id key in managed.doubleObj) {
        id value = managed.doubleObj[key];
        uncheckedAssertEqualObjects(values[key], value);
    }
    uncheckedAssertEqual(values.count, managed.doubleObj.count);
    }();
    
    ^{
    NSDictionary *values = @{ @"key1": @2.2, @"key2": NSNull.null };
    for (id key in optManaged.doubleObj) {
        id value = optManaged.doubleObj[key];
        uncheckedAssertEqualObjects(values[key], value);
    }
    uncheckedAssertEqual(values.count, optManaged.doubleObj.count);
    }();
    
    ^{
    NSDictionary *values = @{ @"key1": data(1), @"key2": data(2) };
    for (id key in unmanaged.dataObj) {
        id value = unmanaged.dataObj[key];
        uncheckedAssertEqualObjects(values[key], value);
    }
    uncheckedAssertEqual(values.count, unmanaged.dataObj.count);
    }();
    
    ^{
    NSDictionary *values = @{ @"key1": data(1), @"key2": NSNull.null };
    for (id key in optUnmanaged.dataObj) {
        id value = optUnmanaged.dataObj[key];
        uncheckedAssertEqualObjects(values[key], value);
    }
    uncheckedAssertEqual(values.count, optUnmanaged.dataObj.count);
    }();
    
    ^{
    NSDictionary *values = @{ @"key1": data(1), @"key2": data(2) };
    for (id key in managed.dataObj) {
        id value = managed.dataObj[key];
        uncheckedAssertEqualObjects(values[key], value);
    }
    uncheckedAssertEqual(values.count, managed.dataObj.count);
    }();
    
    ^{
    NSDictionary *values = @{ @"key1": data(1), @"key2": NSNull.null };
    for (id key in optManaged.dataObj) {
        id value = optManaged.dataObj[key];
        uncheckedAssertEqualObjects(values[key], value);
    }
    uncheckedAssertEqual(values.count, optManaged.dataObj.count);
    }();
    
    ^{
    NSDictionary *values = @{ @"key1": decimal128(2), @"key2": decimal128(3) };
    for (id key in unmanaged.decimalObj) {
        id value = unmanaged.decimalObj[key];
        uncheckedAssertEqualObjects(values[key], value);
    }
    uncheckedAssertEqual(values.count, unmanaged.decimalObj.count);
    }();
    
    ^{
    NSDictionary *values = @{ @"key1": decimal128(2), @"key2": NSNull.null };
    for (id key in optUnmanaged.decimalObj) {
        id value = optUnmanaged.decimalObj[key];
        uncheckedAssertEqualObjects(values[key], value);
    }
    uncheckedAssertEqual(values.count, optUnmanaged.decimalObj.count);
    }();
    
    ^{
    NSDictionary *values = @{ @"key1": decimal128(2), @"key2": decimal128(3) };
    for (id key in managed.decimalObj) {
        id value = managed.decimalObj[key];
        uncheckedAssertEqualObjects(values[key], value);
    }
    uncheckedAssertEqual(values.count, managed.decimalObj.count);
    }();
    
    ^{
    NSDictionary *values = @{ @"key1": decimal128(2), @"key2": NSNull.null };
    for (id key in optManaged.decimalObj) {
        id value = optManaged.decimalObj[key];
        uncheckedAssertEqualObjects(values[key], value);
    }
    uncheckedAssertEqual(values.count, optManaged.decimalObj.count);
    }();
    
    ^{
    NSDictionary *values = @{ @"key1": objectId(1), @"key2": objectId(2) };
    for (id key in unmanaged.objectIdObj) {
        id value = unmanaged.objectIdObj[key];
        uncheckedAssertEqualObjects(values[key], value);
    }
    uncheckedAssertEqual(values.count, unmanaged.objectIdObj.count);
    }();
    
    ^{
    NSDictionary *values = @{ @"key1": objectId(1), @"key2": NSNull.null };
    for (id key in optUnmanaged.objectIdObj) {
        id value = optUnmanaged.objectIdObj[key];
        uncheckedAssertEqualObjects(values[key], value);
    }
    uncheckedAssertEqual(values.count, optUnmanaged.objectIdObj.count);
    }();
    
    ^{
    NSDictionary *values = @{ @"key1": objectId(1), @"key2": objectId(2) };
    for (id key in managed.objectIdObj) {
        id value = managed.objectIdObj[key];
        uncheckedAssertEqualObjects(values[key], value);
    }
    uncheckedAssertEqual(values.count, managed.objectIdObj.count);
    }();
    
    ^{
    NSDictionary *values = @{ @"key1": objectId(1), @"key2": NSNull.null };
    for (id key in optManaged.objectIdObj) {
        id value = optManaged.objectIdObj[key];
        uncheckedAssertEqualObjects(values[key], value);
    }
    uncheckedAssertEqual(values.count, optManaged.objectIdObj.count);
    }();
    
    ^{
    NSDictionary *values = @{ @"key1": uuid(@"00000000-0000-0000-0000-000000000000"), @"key2": uuid(@"137DECC8-B300-4954-A233-F89909F4FD89") };
    for (id key in unmanaged.uuidObj) {
        id value = unmanaged.uuidObj[key];
        uncheckedAssertEqualObjects(values[key], value);
    }
    uncheckedAssertEqual(values.count, unmanaged.uuidObj.count);
    }();
    
    ^{
    NSDictionary *values = @{ @"key1": uuid(@"00000000-0000-0000-0000-000000000000"), @"key2": NSNull.null };
    for (id key in optUnmanaged.uuidObj) {
        id value = optUnmanaged.uuidObj[key];
        uncheckedAssertEqualObjects(values[key], value);
    }
    uncheckedAssertEqual(values.count, optUnmanaged.uuidObj.count);
    }();
    
    ^{
    NSDictionary *values = @{ @"key1": uuid(@"00000000-0000-0000-0000-000000000000"), @"key2": uuid(@"137DECC8-B300-4954-A233-F89909F4FD89") };
    for (id key in managed.uuidObj) {
        id value = managed.uuidObj[key];
        uncheckedAssertEqualObjects(values[key], value);
    }
    uncheckedAssertEqual(values.count, managed.uuidObj.count);
    }();
    
    ^{
    NSDictionary *values = @{ @"key1": uuid(@"00000000-0000-0000-0000-000000000000"), @"key2": NSNull.null };
    for (id key in optManaged.uuidObj) {
        id value = optManaged.uuidObj[key];
        uncheckedAssertEqualObjects(values[key], value);
    }
    uncheckedAssertEqual(values.count, optManaged.uuidObj.count);
    }();
    
    ^{
    NSDictionary *values = @{ @"key1": @NO, @"key2": @YES };
    for (id key in unmanaged.anyBoolObj) {
        id value = unmanaged.anyBoolObj[key];
        uncheckedAssertEqualObjects(values[key], value);
    }
    uncheckedAssertEqual(values.count, unmanaged.anyBoolObj.count);
    }();
    
    ^{
    NSDictionary *values = @{ @"key1": @2, @"key2": @3 };
    for (id key in unmanaged.anyIntObj) {
        id value = unmanaged.anyIntObj[key];
        uncheckedAssertEqualObjects(values[key], value);
    }
    uncheckedAssertEqual(values.count, unmanaged.anyIntObj.count);
    }();
    
    ^{
    NSDictionary *values = @{ @"key1": @2.2f, @"key2": @3.3f };
    for (id key in unmanaged.anyFloatObj) {
        id value = unmanaged.anyFloatObj[key];
        uncheckedAssertEqualObjects(values[key], value);
    }
    uncheckedAssertEqual(values.count, unmanaged.anyFloatObj.count);
    }();
    
    ^{
    NSDictionary *values = @{ @"key1": @2.2, @"key2": @3.3 };
    for (id key in unmanaged.anyDoubleObj) {
        id value = unmanaged.anyDoubleObj[key];
        uncheckedAssertEqualObjects(values[key], value);
    }
    uncheckedAssertEqual(values.count, unmanaged.anyDoubleObj.count);
    }();
    
    ^{
    NSDictionary *values = @{ @"key1": @"a", @"key2": @"b" };
    for (id key in unmanaged.anyStringObj) {
        id value = unmanaged.anyStringObj[key];
        uncheckedAssertEqualObjects(values[key], value);
    }
    uncheckedAssertEqual(values.count, unmanaged.anyStringObj.count);
    }();
    
    ^{
    NSDictionary *values = @{ @"key1": data(1), @"key2": data(2) };
    for (id key in unmanaged.anyDataObj) {
        id value = unmanaged.anyDataObj[key];
        uncheckedAssertEqualObjects(values[key], value);
    }
    uncheckedAssertEqual(values.count, unmanaged.anyDataObj.count);
    }();
    
    ^{
    NSDictionary *values = @{ @"key1": date(1), @"key2": date(2) };
    for (id key in unmanaged.anyDateObj) {
        id value = unmanaged.anyDateObj[key];
        uncheckedAssertEqualObjects(values[key], value);
    }
    uncheckedAssertEqual(values.count, unmanaged.anyDateObj.count);
    }();
    
    ^{
    NSDictionary *values = @{ @"key1": decimal128(2), @"key2": decimal128(3) };
    for (id key in unmanaged.anyDecimalObj) {
        id value = unmanaged.anyDecimalObj[key];
        uncheckedAssertEqualObjects(values[key], value);
    }
    uncheckedAssertEqual(values.count, unmanaged.anyDecimalObj.count);
    }();
    
    ^{
    NSDictionary *values = @{ @"key1": objectId(1), @"key2": objectId(2) };
    for (id key in unmanaged.anyObjectIdObj) {
        id value = unmanaged.anyObjectIdObj[key];
        uncheckedAssertEqualObjects(values[key], value);
    }
    uncheckedAssertEqual(values.count, unmanaged.anyObjectIdObj.count);
    }();
    
    ^{
    NSDictionary *values = @{ @"key1": uuid(@"00000000-0000-0000-0000-000000000000"), @"key2": uuid(@"137DECC8-B300-4954-A233-F89909F4FD89") };
    for (id key in unmanaged.anyUUIDObj) {
        id value = unmanaged.anyUUIDObj[key];
        uncheckedAssertEqualObjects(values[key], value);
    }
    uncheckedAssertEqual(values.count, unmanaged.anyUUIDObj.count);
    }();
    
    ^{
    NSDictionary *values = @{ @"key1": @NO, @"key2": @YES };
    for (id key in managed.anyBoolObj) {
        id value = managed.anyBoolObj[key];
        uncheckedAssertEqualObjects(values[key], value);
    }
    uncheckedAssertEqual(values.count, managed.anyBoolObj.count);
    }();
    
    ^{
    NSDictionary *values = @{ @"key1": @2, @"key2": @3 };
    for (id key in managed.anyIntObj) {
        id value = managed.anyIntObj[key];
        uncheckedAssertEqualObjects(values[key], value);
    }
    uncheckedAssertEqual(values.count, managed.anyIntObj.count);
    }();
    
    ^{
    NSDictionary *values = @{ @"key1": @2.2f, @"key2": @3.3f };
    for (id key in managed.anyFloatObj) {
        id value = managed.anyFloatObj[key];
        uncheckedAssertEqualObjects(values[key], value);
    }
    uncheckedAssertEqual(values.count, managed.anyFloatObj.count);
    }();
    
    ^{
    NSDictionary *values = @{ @"key1": @2.2, @"key2": @3.3 };
    for (id key in managed.anyDoubleObj) {
        id value = managed.anyDoubleObj[key];
        uncheckedAssertEqualObjects(values[key], value);
    }
    uncheckedAssertEqual(values.count, managed.anyDoubleObj.count);
    }();
    
    ^{
    NSDictionary *values = @{ @"key1": @"a", @"key2": @"b" };
    for (id key in managed.anyStringObj) {
        id value = managed.anyStringObj[key];
        uncheckedAssertEqualObjects(values[key], value);
    }
    uncheckedAssertEqual(values.count, managed.anyStringObj.count);
    }();
    
    ^{
    NSDictionary *values = @{ @"key1": data(1), @"key2": data(2) };
    for (id key in managed.anyDataObj) {
        id value = managed.anyDataObj[key];
        uncheckedAssertEqualObjects(values[key], value);
    }
    uncheckedAssertEqual(values.count, managed.anyDataObj.count);
    }();
    
    ^{
    NSDictionary *values = @{ @"key1": date(1), @"key2": date(2) };
    for (id key in managed.anyDateObj) {
        id value = managed.anyDateObj[key];
        uncheckedAssertEqualObjects(values[key], value);
    }
    uncheckedAssertEqual(values.count, managed.anyDateObj.count);
    }();
    
    ^{
    NSDictionary *values = @{ @"key1": decimal128(2), @"key2": decimal128(3) };
    for (id key in managed.anyDecimalObj) {
        id value = managed.anyDecimalObj[key];
        uncheckedAssertEqualObjects(values[key], value);
    }
    uncheckedAssertEqual(values.count, managed.anyDecimalObj.count);
    }();
    
    ^{
    NSDictionary *values = @{ @"key1": objectId(1), @"key2": objectId(2) };
    for (id key in managed.anyObjectIdObj) {
        id value = managed.anyObjectIdObj[key];
        uncheckedAssertEqualObjects(values[key], value);
    }
    uncheckedAssertEqual(values.count, managed.anyObjectIdObj.count);
    }();
    
    ^{
    NSDictionary *values = @{ @"key1": uuid(@"00000000-0000-0000-0000-000000000000"), @"key2": uuid(@"137DECC8-B300-4954-A233-F89909F4FD89") };
    for (id key in managed.anyUUIDObj) {
        id value = managed.anyUUIDObj[key];
        uncheckedAssertEqualObjects(values[key], value);
    }
    uncheckedAssertEqual(values.count, managed.anyUUIDObj.count);
    }();
    
}

- (void)testValueForKeyNumericAggregates {
    uncheckedAssertNil([unmanaged.intObj valueForKeyPath:@"@min.self"]);
    uncheckedAssertNil([optUnmanaged.intObj valueForKeyPath:@"@min.self"]);
    uncheckedAssertNil([managed.intObj valueForKeyPath:@"@min.self"]);
    uncheckedAssertNil([optManaged.intObj valueForKeyPath:@"@min.self"]);
    uncheckedAssertNil([unmanaged.dateObj valueForKeyPath:@"@min.self"]);
    uncheckedAssertNil([optUnmanaged.dateObj valueForKeyPath:@"@min.self"]);
    uncheckedAssertNil([managed.dateObj valueForKeyPath:@"@min.self"]);
    uncheckedAssertNil([optManaged.dateObj valueForKeyPath:@"@min.self"]);
    uncheckedAssertNil([unmanaged.floatObj valueForKeyPath:@"@min.self"]);
    uncheckedAssertNil([optUnmanaged.floatObj valueForKeyPath:@"@min.self"]);
    uncheckedAssertNil([managed.floatObj valueForKeyPath:@"@min.self"]);
    uncheckedAssertNil([optManaged.floatObj valueForKeyPath:@"@min.self"]);
    uncheckedAssertNil([unmanaged.doubleObj valueForKeyPath:@"@min.self"]);
    uncheckedAssertNil([optUnmanaged.doubleObj valueForKeyPath:@"@min.self"]);
    uncheckedAssertNil([managed.doubleObj valueForKeyPath:@"@min.self"]);
    uncheckedAssertNil([optManaged.doubleObj valueForKeyPath:@"@min.self"]);
    uncheckedAssertNil([unmanaged.decimalObj valueForKeyPath:@"@min.self"]);
    uncheckedAssertNil([optUnmanaged.decimalObj valueForKeyPath:@"@min.self"]);
    uncheckedAssertNil([managed.decimalObj valueForKeyPath:@"@min.self"]);
    uncheckedAssertNil([optManaged.decimalObj valueForKeyPath:@"@min.self"]);
    uncheckedAssertNil([unmanaged.anyFloatObj valueForKeyPath:@"@min.self"]);
    uncheckedAssertNil([unmanaged.anyDoubleObj valueForKeyPath:@"@min.self"]);
    uncheckedAssertNil([unmanaged.anyDateObj valueForKeyPath:@"@min.self"]);
    uncheckedAssertNil([unmanaged.anyDecimalObj valueForKeyPath:@"@min.self"]);
    uncheckedAssertNil([managed.anyFloatObj valueForKeyPath:@"@min.self"]);
    uncheckedAssertNil([managed.anyDoubleObj valueForKeyPath:@"@min.self"]);
    uncheckedAssertNil([managed.anyDecimalObj valueForKeyPath:@"@min.self"]);
    uncheckedAssertNil([unmanaged.intObj valueForKeyPath:@"@max.self"]);
    uncheckedAssertNil([optUnmanaged.intObj valueForKeyPath:@"@max.self"]);
    uncheckedAssertNil([managed.intObj valueForKeyPath:@"@max.self"]);
    uncheckedAssertNil([optManaged.intObj valueForKeyPath:@"@max.self"]);
    uncheckedAssertNil([unmanaged.dateObj valueForKeyPath:@"@max.self"]);
    uncheckedAssertNil([optUnmanaged.dateObj valueForKeyPath:@"@max.self"]);
    uncheckedAssertNil([managed.dateObj valueForKeyPath:@"@max.self"]);
    uncheckedAssertNil([optManaged.dateObj valueForKeyPath:@"@max.self"]);
    uncheckedAssertNil([unmanaged.floatObj valueForKeyPath:@"@max.self"]);
    uncheckedAssertNil([optUnmanaged.floatObj valueForKeyPath:@"@max.self"]);
    uncheckedAssertNil([managed.floatObj valueForKeyPath:@"@max.self"]);
    uncheckedAssertNil([optManaged.floatObj valueForKeyPath:@"@max.self"]);
    uncheckedAssertNil([unmanaged.doubleObj valueForKeyPath:@"@max.self"]);
    uncheckedAssertNil([optUnmanaged.doubleObj valueForKeyPath:@"@max.self"]);
    uncheckedAssertNil([managed.doubleObj valueForKeyPath:@"@max.self"]);
    uncheckedAssertNil([optManaged.doubleObj valueForKeyPath:@"@max.self"]);
    uncheckedAssertNil([unmanaged.decimalObj valueForKeyPath:@"@max.self"]);
    uncheckedAssertNil([optUnmanaged.decimalObj valueForKeyPath:@"@max.self"]);
    uncheckedAssertNil([managed.decimalObj valueForKeyPath:@"@max.self"]);
    uncheckedAssertNil([optManaged.decimalObj valueForKeyPath:@"@max.self"]);
    uncheckedAssertNil([unmanaged.anyFloatObj valueForKeyPath:@"@max.self"]);
    uncheckedAssertNil([unmanaged.anyDoubleObj valueForKeyPath:@"@max.self"]);
    uncheckedAssertNil([unmanaged.anyDateObj valueForKeyPath:@"@max.self"]);
    uncheckedAssertNil([unmanaged.anyDecimalObj valueForKeyPath:@"@max.self"]);
    uncheckedAssertNil([managed.anyFloatObj valueForKeyPath:@"@max.self"]);
    uncheckedAssertNil([managed.anyDoubleObj valueForKeyPath:@"@max.self"]);
    uncheckedAssertNil([managed.anyDecimalObj valueForKeyPath:@"@max.self"]);
    uncheckedAssertEqualObjects([unmanaged.intObj valueForKeyPath:@"@sum.self"], @0);
    uncheckedAssertEqualObjects([optUnmanaged.intObj valueForKeyPath:@"@sum.self"], @0);
    uncheckedAssertEqualObjects([managed.intObj valueForKeyPath:@"@sum.self"], @0);
    uncheckedAssertEqualObjects([optManaged.intObj valueForKeyPath:@"@sum.self"], @0);
    uncheckedAssertEqualObjects([unmanaged.floatObj valueForKeyPath:@"@sum.self"], @0);
    uncheckedAssertEqualObjects([optUnmanaged.floatObj valueForKeyPath:@"@sum.self"], @0);
    uncheckedAssertEqualObjects([managed.floatObj valueForKeyPath:@"@sum.self"], @0);
    uncheckedAssertEqualObjects([optManaged.floatObj valueForKeyPath:@"@sum.self"], @0);
    uncheckedAssertEqualObjects([unmanaged.doubleObj valueForKeyPath:@"@sum.self"], @0);
    uncheckedAssertEqualObjects([optUnmanaged.doubleObj valueForKeyPath:@"@sum.self"], @0);
    uncheckedAssertEqualObjects([managed.doubleObj valueForKeyPath:@"@sum.self"], @0);
    uncheckedAssertEqualObjects([optManaged.doubleObj valueForKeyPath:@"@sum.self"], @0);
    uncheckedAssertEqualObjects([unmanaged.decimalObj valueForKeyPath:@"@sum.self"], @0);
    uncheckedAssertEqualObjects([optUnmanaged.decimalObj valueForKeyPath:@"@sum.self"], @0);
    uncheckedAssertEqualObjects([managed.decimalObj valueForKeyPath:@"@sum.self"], @0);
    uncheckedAssertEqualObjects([optManaged.decimalObj valueForKeyPath:@"@sum.self"], @0);
    uncheckedAssertEqualObjects([unmanaged.anyIntObj valueForKeyPath:@"@sum.self"], @0);
    uncheckedAssertEqualObjects([unmanaged.anyFloatObj valueForKeyPath:@"@sum.self"], @0);
    uncheckedAssertEqualObjects([unmanaged.anyDoubleObj valueForKeyPath:@"@sum.self"], @0);
    uncheckedAssertEqualObjects([unmanaged.anyDecimalObj valueForKeyPath:@"@sum.self"], @0);
    uncheckedAssertEqualObjects([managed.anyIntObj valueForKeyPath:@"@sum.self"], @0);
    uncheckedAssertEqualObjects([managed.anyFloatObj valueForKeyPath:@"@sum.self"], @0);
    uncheckedAssertEqualObjects([managed.anyDoubleObj valueForKeyPath:@"@sum.self"], @0);
    uncheckedAssertEqualObjects([managed.anyDecimalObj valueForKeyPath:@"@sum.self"], @0);
    uncheckedAssertNil([unmanaged.intObj valueForKeyPath:@"@avg.self"]);
    uncheckedAssertNil([optUnmanaged.intObj valueForKeyPath:@"@avg.self"]);
    uncheckedAssertNil([managed.intObj valueForKeyPath:@"@avg.self"]);
    uncheckedAssertNil([optManaged.intObj valueForKeyPath:@"@avg.self"]);
    uncheckedAssertNil([unmanaged.floatObj valueForKeyPath:@"@avg.self"]);
    uncheckedAssertNil([optUnmanaged.floatObj valueForKeyPath:@"@avg.self"]);
    uncheckedAssertNil([managed.floatObj valueForKeyPath:@"@avg.self"]);
    uncheckedAssertNil([optManaged.floatObj valueForKeyPath:@"@avg.self"]);
    uncheckedAssertNil([unmanaged.doubleObj valueForKeyPath:@"@avg.self"]);
    uncheckedAssertNil([optUnmanaged.doubleObj valueForKeyPath:@"@avg.self"]);
    uncheckedAssertNil([managed.doubleObj valueForKeyPath:@"@avg.self"]);
    uncheckedAssertNil([optManaged.doubleObj valueForKeyPath:@"@avg.self"]);
    uncheckedAssertNil([unmanaged.decimalObj valueForKeyPath:@"@avg.self"]);
    uncheckedAssertNil([optUnmanaged.decimalObj valueForKeyPath:@"@avg.self"]);
    uncheckedAssertNil([managed.decimalObj valueForKeyPath:@"@avg.self"]);
    uncheckedAssertNil([optManaged.decimalObj valueForKeyPath:@"@avg.self"]);
    uncheckedAssertNil([unmanaged.anyIntObj valueForKeyPath:@"@avg.self"]);
    uncheckedAssertNil([unmanaged.anyFloatObj valueForKeyPath:@"@avg.self"]);
    uncheckedAssertNil([unmanaged.anyDoubleObj valueForKeyPath:@"@avg.self"]);
    uncheckedAssertNil([unmanaged.anyDecimalObj valueForKeyPath:@"@avg.self"]);
    uncheckedAssertNil([managed.anyIntObj valueForKeyPath:@"@avg.self"]);
    uncheckedAssertNil([managed.anyFloatObj valueForKeyPath:@"@avg.self"]);
    uncheckedAssertNil([managed.anyDoubleObj valueForKeyPath:@"@avg.self"]);
    uncheckedAssertNil([managed.anyDecimalObj valueForKeyPath:@"@avg.self"]);

    [self addObjects];

    uncheckedAssertEqualObjects([unmanaged.intObj valueForKeyPath:@"@min.self"], @2);
    uncheckedAssertEqualObjects([optUnmanaged.intObj valueForKeyPath:@"@min.self"], @2);
    uncheckedAssertEqualObjects([managed.intObj valueForKeyPath:@"@min.self"], @2);
    uncheckedAssertEqualObjects([optManaged.intObj valueForKeyPath:@"@min.self"], @2);
    uncheckedAssertEqualObjects([unmanaged.dateObj valueForKeyPath:@"@min.self"], date(1));
    uncheckedAssertEqualObjects([optUnmanaged.dateObj valueForKeyPath:@"@min.self"], date(1));
    uncheckedAssertEqualObjects([managed.dateObj valueForKeyPath:@"@min.self"], date(1));
    uncheckedAssertEqualObjects([optManaged.dateObj valueForKeyPath:@"@min.self"], date(1));
    uncheckedAssertEqualObjects([unmanaged.floatObj valueForKeyPath:@"@min.self"], @2.2f);
    uncheckedAssertEqualObjects([optUnmanaged.floatObj valueForKeyPath:@"@min.self"], @2.2f);
    uncheckedAssertEqualObjects([managed.floatObj valueForKeyPath:@"@min.self"], @2.2f);
    uncheckedAssertEqualObjects([optManaged.floatObj valueForKeyPath:@"@min.self"], @2.2f);
    uncheckedAssertEqualObjects([unmanaged.doubleObj valueForKeyPath:@"@min.self"], @2.2);
    uncheckedAssertEqualObjects([optUnmanaged.doubleObj valueForKeyPath:@"@min.self"], @2.2);
    uncheckedAssertEqualObjects([managed.doubleObj valueForKeyPath:@"@min.self"], @2.2);
    uncheckedAssertEqualObjects([optManaged.doubleObj valueForKeyPath:@"@min.self"], @2.2);
    uncheckedAssertEqualObjects([unmanaged.decimalObj valueForKeyPath:@"@min.self"], decimal128(2));
    uncheckedAssertEqualObjects([optUnmanaged.decimalObj valueForKeyPath:@"@min.self"], decimal128(2));
    uncheckedAssertEqualObjects([managed.decimalObj valueForKeyPath:@"@min.self"], decimal128(2));
    uncheckedAssertEqualObjects([optManaged.decimalObj valueForKeyPath:@"@min.self"], decimal128(2));
    uncheckedAssertEqualObjects([unmanaged.anyFloatObj valueForKeyPath:@"@min.self"], @2.2f);
    uncheckedAssertEqualObjects([unmanaged.anyDoubleObj valueForKeyPath:@"@min.self"], @2.2);
    uncheckedAssertEqualObjects([unmanaged.anyDateObj valueForKeyPath:@"@min.self"], date(1));
    uncheckedAssertEqualObjects([unmanaged.anyDecimalObj valueForKeyPath:@"@min.self"], decimal128(2));
    uncheckedAssertEqualObjects([managed.anyFloatObj valueForKeyPath:@"@min.self"], @2.2f);
    uncheckedAssertEqualObjects([managed.anyDoubleObj valueForKeyPath:@"@min.self"], @2.2);
    uncheckedAssertEqualObjects([managed.anyDecimalObj valueForKeyPath:@"@min.self"], decimal128(2));
    uncheckedAssertEqualObjects([unmanaged.intObj valueForKeyPath:@"@max.self"], @3);
    uncheckedAssertEqualObjects([managed.intObj valueForKeyPath:@"@max.self"], @3);
    uncheckedAssertEqualObjects([unmanaged.dateObj valueForKeyPath:@"@max.self"], date(2));
    uncheckedAssertEqualObjects([managed.dateObj valueForKeyPath:@"@max.self"], date(2));
    uncheckedAssertEqualObjects([unmanaged.floatObj valueForKeyPath:@"@max.self"], @3.3f);
    uncheckedAssertEqualObjects([managed.floatObj valueForKeyPath:@"@max.self"], @3.3f);
    uncheckedAssertEqualObjects([unmanaged.doubleObj valueForKeyPath:@"@max.self"], @3.3);
    uncheckedAssertEqualObjects([managed.doubleObj valueForKeyPath:@"@max.self"], @3.3);
    uncheckedAssertEqualObjects([unmanaged.decimalObj valueForKeyPath:@"@max.self"], decimal128(3));
    uncheckedAssertEqualObjects([managed.decimalObj valueForKeyPath:@"@max.self"], decimal128(3));
    uncheckedAssertEqualObjects([unmanaged.anyFloatObj valueForKeyPath:@"@max.self"], @3.3f);
    uncheckedAssertEqualObjects([unmanaged.anyDoubleObj valueForKeyPath:@"@max.self"], @3.3);
    uncheckedAssertEqualObjects([unmanaged.anyDateObj valueForKeyPath:@"@max.self"], date(2));
    uncheckedAssertEqualObjects([unmanaged.anyDecimalObj valueForKeyPath:@"@max.self"], decimal128(3));
    uncheckedAssertEqualObjects([managed.anyFloatObj valueForKeyPath:@"@max.self"], @3.3f);
    uncheckedAssertEqualObjects([managed.anyDoubleObj valueForKeyPath:@"@max.self"], @3.3);
    uncheckedAssertEqualObjects([managed.anyDecimalObj valueForKeyPath:@"@max.self"], decimal128(3));
    uncheckedAssertEqualObjects([optUnmanaged.intObj valueForKeyPath:@"@max.self"], @2);
    uncheckedAssertEqualObjects([optManaged.intObj valueForKeyPath:@"@max.self"], @2);
    uncheckedAssertEqualObjects([optUnmanaged.dateObj valueForKeyPath:@"@max.self"], date(1));
    uncheckedAssertEqualObjects([optManaged.dateObj valueForKeyPath:@"@max.self"], date(1));
    uncheckedAssertEqualObjects([optUnmanaged.floatObj valueForKeyPath:@"@max.self"], @2.2f);
    uncheckedAssertEqualObjects([optManaged.floatObj valueForKeyPath:@"@max.self"], @2.2f);
    uncheckedAssertEqualObjects([optUnmanaged.doubleObj valueForKeyPath:@"@max.self"], @2.2);
    uncheckedAssertEqualObjects([optManaged.doubleObj valueForKeyPath:@"@max.self"], @2.2);
    uncheckedAssertEqualObjects([optUnmanaged.decimalObj valueForKeyPath:@"@max.self"], decimal128(2));
    uncheckedAssertEqualObjects([optManaged.decimalObj valueForKeyPath:@"@max.self"], decimal128(2));
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
                              @"Invalid value 'a' of type '" RLMConstantString "' for expected type 'bool'");
    RLMAssertThrowsWithReason([optUnmanaged.boolObj setValue:@"a" forKey:@"key1"],
                              @"Invalid value 'a' of type '" RLMConstantString "' for expected type 'bool?'");
    RLMAssertThrowsWithReason([managed.boolObj setValue:@"a" forKey:@"key1"],
                              @"Invalid value 'a' of type '" RLMConstantString "' for expected type 'bool'");
    RLMAssertThrowsWithReason([optManaged.boolObj setValue:@"a" forKey:@"key1"],
                              @"Invalid value 'a' of type '" RLMConstantString "' for expected type 'bool?'");
    RLMAssertThrowsWithReason([unmanaged.intObj setValue:@"a" forKey:@"key1"],
                              @"Invalid value 'a' of type '" RLMConstantString "' for expected type 'int'");
    RLMAssertThrowsWithReason([optUnmanaged.intObj setValue:@"a" forKey:@"key1"],
                              @"Invalid value 'a' of type '" RLMConstantString "' for expected type 'int?'");
    RLMAssertThrowsWithReason([managed.intObj setValue:@"a" forKey:@"key1"],
                              @"Invalid value 'a' of type '" RLMConstantString "' for expected type 'int'");
    RLMAssertThrowsWithReason([optManaged.intObj setValue:@"a" forKey:@"key1"],
                              @"Invalid value 'a' of type '" RLMConstantString "' for expected type 'int?'");
    RLMAssertThrowsWithReason([unmanaged.stringObj setValue:@2 forKey:@"key1"],
                              @"Invalid value '2' of type '" RLMConstantInt "' for expected type 'string'");
    RLMAssertThrowsWithReason([optUnmanaged.stringObj setValue:@2 forKey:@"key1"],
                              @"Invalid value '2' of type '" RLMConstantInt "' for expected type 'string?'");
    RLMAssertThrowsWithReason([managed.stringObj setValue:@2 forKey:@"key1"],
                              @"Invalid value '2' of type '" RLMConstantInt "' for expected type 'string'");
    RLMAssertThrowsWithReason([optManaged.stringObj setValue:@2 forKey:@"key1"],
                              @"Invalid value '2' of type '" RLMConstantInt "' for expected type 'string?'");
    RLMAssertThrowsWithReason([unmanaged.dateObj setValue:@"a" forKey:@"key1"],
                              @"Invalid value 'a' of type '" RLMConstantString "' for expected type 'date'");
    RLMAssertThrowsWithReason([optUnmanaged.dateObj setValue:@"a" forKey:@"key1"],
                              @"Invalid value 'a' of type '" RLMConstantString "' for expected type 'date?'");
    RLMAssertThrowsWithReason([managed.dateObj setValue:@"a" forKey:@"key1"],
                              @"Invalid value 'a' of type '" RLMConstantString "' for expected type 'date'");
    RLMAssertThrowsWithReason([optManaged.dateObj setValue:@"a" forKey:@"key1"],
                              @"Invalid value 'a' of type '" RLMConstantString "' for expected type 'date?'");
    RLMAssertThrowsWithReason([unmanaged.floatObj setValue:@"a" forKey:@"key1"],
                              @"Invalid value 'a' of type '" RLMConstantString "' for expected type 'float'");
    RLMAssertThrowsWithReason([optUnmanaged.floatObj setValue:@"a" forKey:@"key1"],
                              @"Invalid value 'a' of type '" RLMConstantString "' for expected type 'float?'");
    RLMAssertThrowsWithReason([managed.floatObj setValue:@"a" forKey:@"key1"],
                              @"Invalid value 'a' of type '" RLMConstantString "' for expected type 'float'");
    RLMAssertThrowsWithReason([optManaged.floatObj setValue:@"a" forKey:@"key1"],
                              @"Invalid value 'a' of type '" RLMConstantString "' for expected type 'float?'");
    RLMAssertThrowsWithReason([unmanaged.doubleObj setValue:@"a" forKey:@"key1"],
                              @"Invalid value 'a' of type '" RLMConstantString "' for expected type 'double'");
    RLMAssertThrowsWithReason([optUnmanaged.doubleObj setValue:@"a" forKey:@"key1"],
                              @"Invalid value 'a' of type '" RLMConstantString "' for expected type 'double?'");
    RLMAssertThrowsWithReason([managed.doubleObj setValue:@"a" forKey:@"key1"],
                              @"Invalid value 'a' of type '" RLMConstantString "' for expected type 'double'");
    RLMAssertThrowsWithReason([optManaged.doubleObj setValue:@"a" forKey:@"key1"],
                              @"Invalid value 'a' of type '" RLMConstantString "' for expected type 'double?'");
    RLMAssertThrowsWithReason([unmanaged.dataObj setValue:@"a" forKey:@"key1"],
                              @"Invalid value 'a' of type '" RLMConstantString "' for expected type 'data'");
    RLMAssertThrowsWithReason([optUnmanaged.dataObj setValue:@"a" forKey:@"key1"],
                              @"Invalid value 'a' of type '" RLMConstantString "' for expected type 'data?'");
    RLMAssertThrowsWithReason([managed.dataObj setValue:@"a" forKey:@"key1"],
                              @"Invalid value 'a' of type '" RLMConstantString "' for expected type 'data'");
    RLMAssertThrowsWithReason([optManaged.dataObj setValue:@"a" forKey:@"key1"],
                              @"Invalid value 'a' of type '" RLMConstantString "' for expected type 'data?'");
    RLMAssertThrowsWithReason([unmanaged.decimalObj setValue:@"a" forKey:@"key1"],
                              @"Invalid value 'a' of type '" RLMConstantString "' for expected type 'decimal128'");
    RLMAssertThrowsWithReason([optUnmanaged.decimalObj setValue:@"a" forKey:@"key1"],
                              @"Invalid value 'a' of type '" RLMConstantString "' for expected type 'decimal128?'");
    RLMAssertThrowsWithReason([managed.decimalObj setValue:@"a" forKey:@"key1"],
                              @"Invalid value 'a' of type '" RLMConstantString "' for expected type 'decimal128'");
    RLMAssertThrowsWithReason([optManaged.decimalObj setValue:@"a" forKey:@"key1"],
                              @"Invalid value 'a' of type '" RLMConstantString "' for expected type 'decimal128?'");
    RLMAssertThrowsWithReason([unmanaged.objectIdObj setValue:@"a" forKey:@"key1"],
                              @"Invalid value 'a' of type '" RLMConstantString "' for expected type 'object id'");
    RLMAssertThrowsWithReason([optUnmanaged.objectIdObj setValue:@"a" forKey:@"key1"],
                              @"Invalid value 'a' of type '" RLMConstantString "' for expected type 'object id?'");
    RLMAssertThrowsWithReason([managed.objectIdObj setValue:@"a" forKey:@"key1"],
                              @"Invalid value 'a' of type '" RLMConstantString "' for expected type 'object id'");
    RLMAssertThrowsWithReason([optManaged.objectIdObj setValue:@"a" forKey:@"key1"],
                              @"Invalid value 'a' of type '" RLMConstantString "' for expected type 'object id?'");
    RLMAssertThrowsWithReason([unmanaged.uuidObj setValue:@"a" forKey:@"key1"],
                              @"Invalid value 'a' of type '" RLMConstantString "' for expected type 'uuid'");
    RLMAssertThrowsWithReason([optUnmanaged.uuidObj setValue:@"a" forKey:@"key1"],
                              @"Invalid value 'a' of type '" RLMConstantString "' for expected type 'uuid?'");
    RLMAssertThrowsWithReason([managed.uuidObj setValue:@"a" forKey:@"key1"],
                              @"Invalid value 'a' of type '" RLMConstantString "' for expected type 'uuid'");
    RLMAssertThrowsWithReason([optManaged.uuidObj setValue:@"a" forKey:@"key1"],
                              @"Invalid value 'a' of type '" RLMConstantString "' for expected type 'uuid?'");
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

    uncheckedAssertEqualObjects(unmanaged.boolObj[@"key1"], @NO);
    uncheckedAssertEqualObjects(optUnmanaged.boolObj[@"key1"], @NO);
    uncheckedAssertEqualObjects(managed.boolObj[@"key1"], @NO);
    uncheckedAssertEqualObjects(optManaged.boolObj[@"key1"], @NO);
    uncheckedAssertEqualObjects(unmanaged.intObj[@"key1"], @2);
    uncheckedAssertEqualObjects(optUnmanaged.intObj[@"key1"], @2);
    uncheckedAssertEqualObjects(managed.intObj[@"key1"], @2);
    uncheckedAssertEqualObjects(optManaged.intObj[@"key1"], @2);
    uncheckedAssertEqualObjects(unmanaged.stringObj[@"key1"], @"bar");
    uncheckedAssertEqualObjects(optUnmanaged.stringObj[@"key1"], @"bar");
    uncheckedAssertEqualObjects(managed.stringObj[@"key1"], @"bar");
    uncheckedAssertEqualObjects(optManaged.stringObj[@"key1"], @"bar");
    uncheckedAssertEqualObjects(unmanaged.dateObj[@"key1"], date(1));
    uncheckedAssertEqualObjects(optUnmanaged.dateObj[@"key1"], date(1));
    uncheckedAssertEqualObjects(managed.dateObj[@"key1"], date(1));
    uncheckedAssertEqualObjects(optManaged.dateObj[@"key1"], date(1));
    uncheckedAssertEqualObjects(unmanaged.floatObj[@"key1"], @2.2f);
    uncheckedAssertEqualObjects(optUnmanaged.floatObj[@"key1"], @2.2f);
    uncheckedAssertEqualObjects(managed.floatObj[@"key1"], @2.2f);
    uncheckedAssertEqualObjects(optManaged.floatObj[@"key1"], @2.2f);
    uncheckedAssertEqualObjects(unmanaged.doubleObj[@"key1"], @2.2);
    uncheckedAssertEqualObjects(optUnmanaged.doubleObj[@"key1"], @2.2);
    uncheckedAssertEqualObjects(managed.doubleObj[@"key1"], @2.2);
    uncheckedAssertEqualObjects(optManaged.doubleObj[@"key1"], @2.2);
    uncheckedAssertEqualObjects(unmanaged.dataObj[@"key1"], data(1));
    uncheckedAssertEqualObjects(optUnmanaged.dataObj[@"key1"], data(1));
    uncheckedAssertEqualObjects(managed.dataObj[@"key1"], data(1));
    uncheckedAssertEqualObjects(optManaged.dataObj[@"key1"], data(1));
    uncheckedAssertEqualObjects(unmanaged.decimalObj[@"key1"], decimal128(2));
    uncheckedAssertEqualObjects(optUnmanaged.decimalObj[@"key1"], decimal128(2));
    uncheckedAssertEqualObjects(managed.decimalObj[@"key1"], decimal128(2));
    uncheckedAssertEqualObjects(optManaged.decimalObj[@"key1"], decimal128(2));
    uncheckedAssertEqualObjects(unmanaged.objectIdObj[@"key1"], objectId(1));
    uncheckedAssertEqualObjects(optUnmanaged.objectIdObj[@"key1"], objectId(1));
    uncheckedAssertEqualObjects(managed.objectIdObj[@"key1"], objectId(1));
    uncheckedAssertEqualObjects(optManaged.objectIdObj[@"key1"], objectId(1));
    uncheckedAssertEqualObjects(unmanaged.uuidObj[@"key1"], uuid(@"00000000-0000-0000-0000-000000000000"));
    uncheckedAssertEqualObjects(optUnmanaged.uuidObj[@"key1"], uuid(@"00000000-0000-0000-0000-000000000000"));
    uncheckedAssertEqualObjects(managed.uuidObj[@"key1"], uuid(@"00000000-0000-0000-0000-000000000000"));
    uncheckedAssertEqualObjects(optManaged.uuidObj[@"key1"], uuid(@"00000000-0000-0000-0000-000000000000"));
    uncheckedAssertEqualObjects(unmanaged.anyBoolObj[@"key1"], @NO);
    uncheckedAssertEqualObjects(unmanaged.anyIntObj[@"key1"], @2);
    uncheckedAssertEqualObjects(unmanaged.anyFloatObj[@"key1"], @2.2f);
    uncheckedAssertEqualObjects(unmanaged.anyDoubleObj[@"key1"], @2.2);
    uncheckedAssertEqualObjects(unmanaged.anyStringObj[@"key1"], @"a");
    uncheckedAssertEqualObjects(unmanaged.anyDataObj[@"key1"], data(1));
    uncheckedAssertEqualObjects(unmanaged.anyDateObj[@"key1"], date(1));
    uncheckedAssertEqualObjects(unmanaged.anyDecimalObj[@"key1"], decimal128(2));
    uncheckedAssertEqualObjects(unmanaged.anyObjectIdObj[@"key1"], objectId(1));
    uncheckedAssertEqualObjects(unmanaged.anyUUIDObj[@"key1"], uuid(@"00000000-0000-0000-0000-000000000000"));
    uncheckedAssertEqualObjects(managed.anyBoolObj[@"key1"], @NO);
    uncheckedAssertEqualObjects(managed.anyIntObj[@"key1"], @2);
    uncheckedAssertEqualObjects(managed.anyFloatObj[@"key1"], @2.2f);
    uncheckedAssertEqualObjects(managed.anyDoubleObj[@"key1"], @2.2);
    uncheckedAssertEqualObjects(managed.anyStringObj[@"key1"], @"a");
    uncheckedAssertEqualObjects(managed.anyDataObj[@"key1"], data(1));
    uncheckedAssertEqualObjects(managed.anyDateObj[@"key1"], date(1));
    uncheckedAssertEqualObjects(managed.anyDecimalObj[@"key1"], decimal128(2));
    uncheckedAssertEqualObjects(managed.anyObjectIdObj[@"key1"], objectId(1));
    uncheckedAssertEqualObjects(managed.anyUUIDObj[@"key1"], uuid(@"00000000-0000-0000-0000-000000000000"));

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
    uncheckedAssertEqualObjects(optUnmanaged.boolObj[@"key1"], (id)NSNull.null);
    uncheckedAssertEqualObjects(optManaged.boolObj[@"key1"], (id)NSNull.null);
    uncheckedAssertEqualObjects(optUnmanaged.intObj[@"key1"], (id)NSNull.null);
    uncheckedAssertEqualObjects(optManaged.intObj[@"key1"], (id)NSNull.null);
    uncheckedAssertEqualObjects(optUnmanaged.stringObj[@"key1"], (id)NSNull.null);
    uncheckedAssertEqualObjects(optManaged.stringObj[@"key1"], (id)NSNull.null);
    uncheckedAssertEqualObjects(optUnmanaged.dateObj[@"key1"], (id)NSNull.null);
    uncheckedAssertEqualObjects(optManaged.dateObj[@"key1"], (id)NSNull.null);
    uncheckedAssertEqualObjects(optUnmanaged.floatObj[@"key1"], (id)NSNull.null);
    uncheckedAssertEqualObjects(optManaged.floatObj[@"key1"], (id)NSNull.null);
    uncheckedAssertEqualObjects(optUnmanaged.doubleObj[@"key1"], (id)NSNull.null);
    uncheckedAssertEqualObjects(optManaged.doubleObj[@"key1"], (id)NSNull.null);
    uncheckedAssertEqualObjects(optUnmanaged.dataObj[@"key1"], (id)NSNull.null);
    uncheckedAssertEqualObjects(optManaged.dataObj[@"key1"], (id)NSNull.null);
    uncheckedAssertEqualObjects(optUnmanaged.decimalObj[@"key1"], (id)NSNull.null);
    uncheckedAssertEqualObjects(optManaged.decimalObj[@"key1"], (id)NSNull.null);
    uncheckedAssertEqualObjects(optUnmanaged.objectIdObj[@"key1"], (id)NSNull.null);
    uncheckedAssertEqualObjects(optManaged.objectIdObj[@"key1"], (id)NSNull.null);
    uncheckedAssertEqualObjects(optUnmanaged.uuidObj[@"key1"], (id)NSNull.null);
    uncheckedAssertEqualObjects(optManaged.uuidObj[@"key1"], (id)NSNull.null);
}

- (void)testAssignment {
    unmanaged.boolObj = (id)@{@"key2": @YES};
    uncheckedAssertEqualObjects(unmanaged.boolObj[@"key2"], @YES);
    optUnmanaged.boolObj = (id)@{@"key2": NSNull.null};
    uncheckedAssertEqualObjects(optUnmanaged.boolObj[@"key2"], NSNull.null);
    managed.boolObj = (id)@{@"key2": @YES};
    uncheckedAssertEqualObjects(managed.boolObj[@"key2"], @YES);
    optManaged.boolObj = (id)@{@"key2": NSNull.null};
    uncheckedAssertEqualObjects(optManaged.boolObj[@"key2"], NSNull.null);
    unmanaged.intObj = (id)@{@"key2": @3};
    uncheckedAssertEqualObjects(unmanaged.intObj[@"key2"], @3);
    optUnmanaged.intObj = (id)@{@"key2": NSNull.null};
    uncheckedAssertEqualObjects(optUnmanaged.intObj[@"key2"], NSNull.null);
    managed.intObj = (id)@{@"key2": @3};
    uncheckedAssertEqualObjects(managed.intObj[@"key2"], @3);
    optManaged.intObj = (id)@{@"key2": NSNull.null};
    uncheckedAssertEqualObjects(optManaged.intObj[@"key2"], NSNull.null);
    unmanaged.stringObj = (id)@{@"key2": @"foo"};
    uncheckedAssertEqualObjects(unmanaged.stringObj[@"key2"], @"foo");
    optUnmanaged.stringObj = (id)@{@"key2": NSNull.null};
    uncheckedAssertEqualObjects(optUnmanaged.stringObj[@"key2"], NSNull.null);
    managed.stringObj = (id)@{@"key2": @"foo"};
    uncheckedAssertEqualObjects(managed.stringObj[@"key2"], @"foo");
    optManaged.stringObj = (id)@{@"key2": NSNull.null};
    uncheckedAssertEqualObjects(optManaged.stringObj[@"key2"], NSNull.null);
    unmanaged.dateObj = (id)@{@"key2": date(2)};
    uncheckedAssertEqualObjects(unmanaged.dateObj[@"key2"], date(2));
    optUnmanaged.dateObj = (id)@{@"key2": NSNull.null};
    uncheckedAssertEqualObjects(optUnmanaged.dateObj[@"key2"], NSNull.null);
    managed.dateObj = (id)@{@"key2": date(2)};
    uncheckedAssertEqualObjects(managed.dateObj[@"key2"], date(2));
    optManaged.dateObj = (id)@{@"key2": NSNull.null};
    uncheckedAssertEqualObjects(optManaged.dateObj[@"key2"], NSNull.null);
    unmanaged.floatObj = (id)@{@"key2": @3.3f};
    uncheckedAssertEqualObjects(unmanaged.floatObj[@"key2"], @3.3f);
    optUnmanaged.floatObj = (id)@{@"key2": NSNull.null};
    uncheckedAssertEqualObjects(optUnmanaged.floatObj[@"key2"], NSNull.null);
    managed.floatObj = (id)@{@"key2": @3.3f};
    uncheckedAssertEqualObjects(managed.floatObj[@"key2"], @3.3f);
    optManaged.floatObj = (id)@{@"key2": NSNull.null};
    uncheckedAssertEqualObjects(optManaged.floatObj[@"key2"], NSNull.null);
    unmanaged.doubleObj = (id)@{@"key2": @3.3};
    uncheckedAssertEqualObjects(unmanaged.doubleObj[@"key2"], @3.3);
    optUnmanaged.doubleObj = (id)@{@"key2": NSNull.null};
    uncheckedAssertEqualObjects(optUnmanaged.doubleObj[@"key2"], NSNull.null);
    managed.doubleObj = (id)@{@"key2": @3.3};
    uncheckedAssertEqualObjects(managed.doubleObj[@"key2"], @3.3);
    optManaged.doubleObj = (id)@{@"key2": NSNull.null};
    uncheckedAssertEqualObjects(optManaged.doubleObj[@"key2"], NSNull.null);
    unmanaged.dataObj = (id)@{@"key2": data(2)};
    uncheckedAssertEqualObjects(unmanaged.dataObj[@"key2"], data(2));
    optUnmanaged.dataObj = (id)@{@"key2": NSNull.null};
    uncheckedAssertEqualObjects(optUnmanaged.dataObj[@"key2"], NSNull.null);
    managed.dataObj = (id)@{@"key2": data(2)};
    uncheckedAssertEqualObjects(managed.dataObj[@"key2"], data(2));
    optManaged.dataObj = (id)@{@"key2": NSNull.null};
    uncheckedAssertEqualObjects(optManaged.dataObj[@"key2"], NSNull.null);
    unmanaged.decimalObj = (id)@{@"key2": decimal128(3)};
    uncheckedAssertEqualObjects(unmanaged.decimalObj[@"key2"], decimal128(3));
    optUnmanaged.decimalObj = (id)@{@"key2": NSNull.null};
    uncheckedAssertEqualObjects(optUnmanaged.decimalObj[@"key2"], NSNull.null);
    managed.decimalObj = (id)@{@"key2": decimal128(3)};
    uncheckedAssertEqualObjects(managed.decimalObj[@"key2"], decimal128(3));
    optManaged.decimalObj = (id)@{@"key2": NSNull.null};
    uncheckedAssertEqualObjects(optManaged.decimalObj[@"key2"], NSNull.null);
    unmanaged.objectIdObj = (id)@{@"key2": objectId(2)};
    uncheckedAssertEqualObjects(unmanaged.objectIdObj[@"key2"], objectId(2));
    optUnmanaged.objectIdObj = (id)@{@"key2": NSNull.null};
    uncheckedAssertEqualObjects(optUnmanaged.objectIdObj[@"key2"], NSNull.null);
    managed.objectIdObj = (id)@{@"key2": objectId(2)};
    uncheckedAssertEqualObjects(managed.objectIdObj[@"key2"], objectId(2));
    optManaged.objectIdObj = (id)@{@"key2": NSNull.null};
    uncheckedAssertEqualObjects(optManaged.objectIdObj[@"key2"], NSNull.null);
    unmanaged.uuidObj = (id)@{@"key2": uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")};
    uncheckedAssertEqualObjects(unmanaged.uuidObj[@"key2"], uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"));
    optUnmanaged.uuidObj = (id)@{@"key2": NSNull.null};
    uncheckedAssertEqualObjects(optUnmanaged.uuidObj[@"key2"], NSNull.null);
    managed.uuidObj = (id)@{@"key2": uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")};
    uncheckedAssertEqualObjects(managed.uuidObj[@"key2"], uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"));
    optManaged.uuidObj = (id)@{@"key2": NSNull.null};
    uncheckedAssertEqualObjects(optManaged.uuidObj[@"key2"], NSNull.null);
    unmanaged.anyBoolObj = (id)@{@"key2": @YES};
    uncheckedAssertEqualObjects(unmanaged.anyBoolObj[@"key2"], @YES);
    unmanaged.anyIntObj = (id)@{@"key2": @3};
    uncheckedAssertEqualObjects(unmanaged.anyIntObj[@"key2"], @3);
    unmanaged.anyFloatObj = (id)@{@"key2": @3.3f};
    uncheckedAssertEqualObjects(unmanaged.anyFloatObj[@"key2"], @3.3f);
    unmanaged.anyDoubleObj = (id)@{@"key2": @3.3};
    uncheckedAssertEqualObjects(unmanaged.anyDoubleObj[@"key2"], @3.3);
    unmanaged.anyStringObj = (id)@{@"key2": @"b"};
    uncheckedAssertEqualObjects(unmanaged.anyStringObj[@"key2"], @"b");
    unmanaged.anyDataObj = (id)@{@"key2": data(2)};
    uncheckedAssertEqualObjects(unmanaged.anyDataObj[@"key2"], data(2));
    unmanaged.anyDateObj = (id)@{@"key2": date(2)};
    uncheckedAssertEqualObjects(unmanaged.anyDateObj[@"key2"], date(2));
    unmanaged.anyDecimalObj = (id)@{@"key2": decimal128(3)};
    uncheckedAssertEqualObjects(unmanaged.anyDecimalObj[@"key2"], decimal128(3));
    unmanaged.anyObjectIdObj = (id)@{@"key2": objectId(2)};
    uncheckedAssertEqualObjects(unmanaged.anyObjectIdObj[@"key2"], objectId(2));
    unmanaged.anyUUIDObj = (id)@{@"key2": uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")};
    uncheckedAssertEqualObjects(unmanaged.anyUUIDObj[@"key2"], uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"));
    managed.anyBoolObj = (id)@{@"key2": @YES};
    uncheckedAssertEqualObjects(managed.anyBoolObj[@"key2"], @YES);
    managed.anyIntObj = (id)@{@"key2": @3};
    uncheckedAssertEqualObjects(managed.anyIntObj[@"key2"], @3);
    managed.anyFloatObj = (id)@{@"key2": @3.3f};
    uncheckedAssertEqualObjects(managed.anyFloatObj[@"key2"], @3.3f);
    managed.anyDoubleObj = (id)@{@"key2": @3.3};
    uncheckedAssertEqualObjects(managed.anyDoubleObj[@"key2"], @3.3);
    managed.anyStringObj = (id)@{@"key2": @"b"};
    uncheckedAssertEqualObjects(managed.anyStringObj[@"key2"], @"b");
    managed.anyDataObj = (id)@{@"key2": data(2)};
    uncheckedAssertEqualObjects(managed.anyDataObj[@"key2"], data(2));
    managed.anyDateObj = (id)@{@"key2": date(2)};
    uncheckedAssertEqualObjects(managed.anyDateObj[@"key2"], date(2));
    managed.anyDecimalObj = (id)@{@"key2": decimal128(3)};
    uncheckedAssertEqualObjects(managed.anyDecimalObj[@"key2"], decimal128(3));
    managed.anyObjectIdObj = (id)@{@"key2": objectId(2)};
    uncheckedAssertEqualObjects(managed.anyObjectIdObj[@"key2"], objectId(2));
    managed.anyUUIDObj = (id)@{@"key2": uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")};
    uncheckedAssertEqualObjects(managed.anyUUIDObj[@"key2"], uuid(@"137DECC8-B300-4954-A233-F89909F4FD89"));

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
                              @"Invalid keypath 'boolObj.@sum': @sum can only be applied to a collection of numeric values.");
    RLMAssertThrowsWithReason(([AllOptionalPrimitiveDictionaries objectsInRealm:realm where:@"boolObj.@sum = %@", @NO]),
                              @"Invalid keypath 'boolObj.@sum': @sum can only be applied to a collection of numeric values.");
    RLMAssertThrowsWithReason(([AllPrimitiveDictionaries objectsInRealm:realm where:@"stringObj.@sum = %@", @"bar"]),
                              @"Invalid keypath 'stringObj.@sum': @sum can only be applied to a collection of numeric values.");
    RLMAssertThrowsWithReason(([AllOptionalPrimitiveDictionaries objectsInRealm:realm where:@"stringObj.@sum = %@", @"bar"]),
                              @"Invalid keypath 'stringObj.@sum': @sum can only be applied to a collection of numeric values.");
    RLMAssertThrowsWithReason(([AllPrimitiveDictionaries objectsInRealm:realm where:@"dateObj.@sum = %@", date(1)]),
                              @"Cannot sum or average date properties");
    RLMAssertThrowsWithReason(([AllOptionalPrimitiveDictionaries objectsInRealm:realm where:@"dateObj.@sum = %@", date(1)]),
                              @"Cannot sum or average date properties");

    RLMAssertThrowsWithReason(([AllPrimitiveDictionaries objectsInRealm:realm where:@"intObj.@sum = %@", @"a"]),
                              @"@sum on a property of type int cannot be compared with 'a'");
    RLMAssertThrowsWithReason(([AllOptionalPrimitiveDictionaries objectsInRealm:realm where:@"intObj.@sum = %@", @"a"]),
                              @"@sum on a property of type int cannot be compared with 'a'");
    RLMAssertThrowsWithReason(([AllPrimitiveDictionaries objectsInRealm:realm where:@"intObj.@sum.prop = %@", @"a"]),
                              @"Invalid keypath 'intObj.@sum.prop': @sum on a collection of values must appear at the end of a keypath.");
    RLMAssertThrowsWithReason(([AllOptionalPrimitiveDictionaries objectsInRealm:realm where:@"intObj.@sum.prop = %@", @"a"]),
                              @"Invalid keypath 'intObj.@sum.prop': @sum on a collection of values must appear at the end of a keypath.");
    RLMAssertThrowsWithReason(([AllPrimitiveDictionaries objectsInRealm:realm where:@"anyIntObj.@sum.prop = %@", @"a"]),
                              @"Invalid keypath 'anyIntObj.@sum.prop': @sum on a collection of values must appear at the end of a keypath.");
    RLMAssertThrowsWithReason(([AllPrimitiveDictionaries objectsInRealm:realm where:@"anyFloatObj.@sum.prop = %@", @"a"]),
                              @"Invalid keypath 'anyFloatObj.@sum.prop': @sum on a collection of values must appear at the end of a keypath.");
    RLMAssertThrowsWithReason(([AllPrimitiveDictionaries objectsInRealm:realm where:@"anyDoubleObj.@sum.prop = %@", @"a"]),
                              @"Invalid keypath 'anyDoubleObj.@sum.prop': @sum on a collection of values must appear at the end of a keypath.");
    RLMAssertThrowsWithReason(([AllPrimitiveDictionaries objectsInRealm:realm where:@"anyDecimalObj.@sum.prop = %@", @"a"]),
                              @"Invalid keypath 'anyDecimalObj.@sum.prop': @sum on a collection of values must appear at the end of a keypath.");
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
                              @"Invalid keypath 'boolObj.@avg': @avg can only be applied to a collection of numeric values.");
    RLMAssertThrowsWithReason(([AllOptionalPrimitiveDictionaries objectsInRealm:realm where:@"boolObj.@avg = %@", @NO]),
                              @"Invalid keypath 'boolObj.@avg': @avg can only be applied to a collection of numeric values.");
    RLMAssertThrowsWithReason(([AllPrimitiveDictionaries objectsInRealm:realm where:@"stringObj.@avg = %@", @"bar"]),
                              @"Invalid keypath 'stringObj.@avg': @avg can only be applied to a collection of numeric values.");
    RLMAssertThrowsWithReason(([AllOptionalPrimitiveDictionaries objectsInRealm:realm where:@"stringObj.@avg = %@", @"bar"]),
                              @"Invalid keypath 'stringObj.@avg': @avg can only be applied to a collection of numeric values.");
    RLMAssertThrowsWithReason(([AllPrimitiveDictionaries objectsInRealm:realm where:@"dateObj.@avg = %@", date(1)]),
                              @"Cannot sum or average date properties");
    RLMAssertThrowsWithReason(([AllOptionalPrimitiveDictionaries objectsInRealm:realm where:@"dateObj.@avg = %@", date(1)]),
                              @"Cannot sum or average date properties");

    RLMAssertThrowsWithReason(([AllPrimitiveDictionaries objectsInRealm:realm where:@"intObj.@avg = %@", @"a"]),
                              @"@avg on a property of type int cannot be compared with 'a'");
    RLMAssertThrowsWithReason(([AllOptionalPrimitiveDictionaries objectsInRealm:realm where:@"intObj.@avg = %@", @"a"]),
                              @"@avg on a property of type int cannot be compared with 'a'");
    RLMAssertThrowsWithReason(([AllPrimitiveDictionaries objectsInRealm:realm where:@"intObj.@avg.prop = %@", @"a"]),
                              @"Invalid keypath 'intObj.@avg.prop': @avg on a collection of values must appear at the end of a keypath.");
    RLMAssertThrowsWithReason(([AllOptionalPrimitiveDictionaries objectsInRealm:realm where:@"intObj.@avg.prop = %@", @"a"]),
                              @"Invalid keypath 'intObj.@avg.prop': @avg on a collection of values must appear at the end of a keypath.");
    RLMAssertThrowsWithReason(([AllPrimitiveDictionaries objectsInRealm:realm where:@"anyIntObj.@avg.prop = %@", @"a"]),
                              @"Invalid keypath 'anyIntObj.@avg.prop': @avg on a collection of values must appear at the end of a keypath.");
    RLMAssertThrowsWithReason(([AllPrimitiveDictionaries objectsInRealm:realm where:@"anyFloatObj.@avg.prop = %@", @"a"]),
                              @"Invalid keypath 'anyFloatObj.@avg.prop': @avg on a collection of values must appear at the end of a keypath.");
    RLMAssertThrowsWithReason(([AllPrimitiveDictionaries objectsInRealm:realm where:@"anyDoubleObj.@avg.prop = %@", @"a"]),
                              @"Invalid keypath 'anyDoubleObj.@avg.prop': @avg on a collection of values must appear at the end of a keypath.");
    RLMAssertThrowsWithReason(([AllPrimitiveDictionaries objectsInRealm:realm where:@"anyDecimalObj.@avg.prop = %@", @"a"]),
                              @"Invalid keypath 'anyDecimalObj.@avg.prop': @avg on a collection of values must appear at the end of a keypath.");

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
                              @"Invalid keypath 'boolObj.@min': @min can only be applied to a collection of numeric values.");
    RLMAssertThrowsWithReason(([AllOptionalPrimitiveDictionaries objectsInRealm:realm where:@"boolObj.@min = %@", @NO]),
                              @"Invalid keypath 'boolObj.@min': @min can only be applied to a collection of numeric values.");
    RLMAssertThrowsWithReason(([AllPrimitiveDictionaries objectsInRealm:realm where:@"stringObj.@min = %@", @"bar"]),
                              @"Invalid keypath 'stringObj.@min': @min can only be applied to a collection of numeric values.");
    RLMAssertThrowsWithReason(([AllOptionalPrimitiveDictionaries objectsInRealm:realm where:@"stringObj.@min = %@", @"bar"]),
                              @"Invalid keypath 'stringObj.@min': @min can only be applied to a collection of numeric values.");
    RLMAssertThrowsWithReason(([AllPrimitiveDictionaries objectsInRealm:realm where:@"intObj.@min = %@", @"a"]),
                              @"@min on a property of type int cannot be compared with 'a'");
    RLMAssertThrowsWithReason(([AllOptionalPrimitiveDictionaries objectsInRealm:realm where:@"intObj.@min = %@", @"a"]),
                              @"@min on a property of type int cannot be compared with 'a'");
    RLMAssertThrowsWithReason(([AllPrimitiveDictionaries objectsInRealm:realm where:@"dateObj.@min = %@", @"a"]),
                              @"@min on a property of type date cannot be compared with 'a'");
    RLMAssertThrowsWithReason(([AllOptionalPrimitiveDictionaries objectsInRealm:realm where:@"dateObj.@min = %@", @"a"]),
                              @"@min on a property of type date cannot be compared with 'a'");
    RLMAssertThrowsWithReason(([AllPrimitiveDictionaries objectsInRealm:realm where:@"intObj.@min.prop = %@", @"a"]),
                              @"Invalid keypath 'intObj.@min.prop': @min on a collection of values must appear at the end of a keypath.");
    RLMAssertThrowsWithReason(([AllOptionalPrimitiveDictionaries objectsInRealm:realm where:@"intObj.@min.prop = %@", @"a"]),
                              @"Invalid keypath 'intObj.@min.prop': @min on a collection of values must appear at the end of a keypath.");
    RLMAssertThrowsWithReason(([AllPrimitiveDictionaries objectsInRealm:realm where:@"dateObj.@min.prop = %@", @"a"]),
                              @"Invalid keypath 'dateObj.@min.prop': @min on a collection of values must appear at the end of a keypath.");
    RLMAssertThrowsWithReason(([AllOptionalPrimitiveDictionaries objectsInRealm:realm where:@"dateObj.@min.prop = %@", @"a"]),
                              @"Invalid keypath 'dateObj.@min.prop': @min on a collection of values must appear at the end of a keypath.");
    RLMAssertThrowsWithReason(([AllPrimitiveDictionaries objectsInRealm:realm where:@"anyFloatObj.@min.prop = %@", @"a"]),
                              @"Invalid keypath 'anyFloatObj.@min.prop': @min on a collection of values must appear at the end of a keypath.");
    RLMAssertThrowsWithReason(([AllPrimitiveDictionaries objectsInRealm:realm where:@"anyDoubleObj.@min.prop = %@", @"a"]),
                              @"Invalid keypath 'anyDoubleObj.@min.prop': @min on a collection of values must appear at the end of a keypath.");
    RLMAssertThrowsWithReason(([AllPrimitiveDictionaries objectsInRealm:realm where:@"anyDecimalObj.@min.prop = %@", @"a"]),
                              @"Invalid keypath 'anyDecimalObj.@min.prop': @min on a collection of values must appear at the end of a keypath.");

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
                              @"Invalid keypath 'boolObj.@max': @max can only be applied to a collection of numeric values.");
    RLMAssertThrowsWithReason(([AllOptionalPrimitiveDictionaries objectsInRealm:realm where:@"boolObj.@max = %@", @NO]),
                              @"Invalid keypath 'boolObj.@max': @max can only be applied to a collection of numeric values.");
    RLMAssertThrowsWithReason(([AllPrimitiveDictionaries objectsInRealm:realm where:@"stringObj.@max = %@", @"bar"]),
                              @"Invalid keypath 'stringObj.@max': @max can only be applied to a collection of numeric values.");
    RLMAssertThrowsWithReason(([AllOptionalPrimitiveDictionaries objectsInRealm:realm where:@"stringObj.@max = %@", @"bar"]),
                              @"Invalid keypath 'stringObj.@max': @max can only be applied to a collection of numeric values.");
    RLMAssertThrowsWithReason(([AllPrimitiveDictionaries objectsInRealm:realm where:@"intObj.@max = %@", @"a"]),
                              @"@max on a property of type int cannot be compared with 'a'");
    RLMAssertThrowsWithReason(([AllOptionalPrimitiveDictionaries objectsInRealm:realm where:@"intObj.@max = %@", @"a"]),
                              @"@max on a property of type int cannot be compared with 'a'");
    RLMAssertThrowsWithReason(([AllPrimitiveDictionaries objectsInRealm:realm where:@"dateObj.@max = %@", @"a"]),
                              @"@max on a property of type date cannot be compared with 'a'");
    RLMAssertThrowsWithReason(([AllOptionalPrimitiveDictionaries objectsInRealm:realm where:@"dateObj.@max = %@", @"a"]),
                              @"@max on a property of type date cannot be compared with 'a'");
    RLMAssertThrowsWithReason(([AllPrimitiveDictionaries objectsInRealm:realm where:@"intObj.@max.prop = %@", @"a"]),
                              @"Invalid keypath 'intObj.@max.prop': @max on a collection of values must appear at the end of a keypath.");
    RLMAssertThrowsWithReason(([AllOptionalPrimitiveDictionaries objectsInRealm:realm where:@"intObj.@max.prop = %@", @"a"]),
                              @"Invalid keypath 'intObj.@max.prop': @max on a collection of values must appear at the end of a keypath.");
    RLMAssertThrowsWithReason(([AllPrimitiveDictionaries objectsInRealm:realm where:@"dateObj.@max.prop = %@", @"a"]),
                              @"Invalid keypath 'dateObj.@max.prop': @max on a collection of values must appear at the end of a keypath.");
    RLMAssertThrowsWithReason(([AllOptionalPrimitiveDictionaries objectsInRealm:realm where:@"dateObj.@max.prop = %@", @"a"]),
                              @"Invalid keypath 'dateObj.@max.prop': @max on a collection of values must appear at the end of a keypath.");
    RLMAssertThrowsWithReason(([AllPrimitiveDictionaries objectsInRealm:realm where:@"anyFloatObj.@max.prop = %@", @"a"]),
                              @"Invalid keypath 'anyFloatObj.@max.prop': @max on a collection of values must appear at the end of a keypath.");
    RLMAssertThrowsWithReason(([AllPrimitiveDictionaries objectsInRealm:realm where:@"anyDoubleObj.@max.prop = %@", @"a"]),
                              @"Invalid keypath 'anyDoubleObj.@max.prop': @max on a collection of values must appear at the end of a keypath.");
    RLMAssertThrowsWithReason(([AllPrimitiveDictionaries objectsInRealm:realm where:@"anyDecimalObj.@max.prop = %@", @"a"]),
                              @"Invalid keypath 'anyDecimalObj.@max.prop': @max on a collection of values must appear at the end of a keypath.");

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
                                  @"Cannot compare value '(null)' of type '(null)' to property 'stringObj' of type 'string'");
        RLMAssertCount(AllOptionalPrimitiveDictionaries, count, query, NSNull.null);
        query = [NSString stringWithFormat:@"ANY link.stringObj %@ nil", operator];
        RLMAssertThrowsWithReason([LinkToAllPrimitiveDictionaries objectsInRealm:realm where:query],
                                  @"Cannot compare value '(null)' of type '(null)' to property 'stringObj' of type 'string'");
        RLMAssertCount(LinkToAllOptionalPrimitiveDictionaries, count, query, NSNull.null);

        query = [NSString stringWithFormat:@"ANY dataObj %@ nil", operator];
        RLMAssertThrowsWithReason([AllPrimitiveDictionaries objectsInRealm:realm where:query],
                                  @"Cannot compare value '(null)' of type '(null)' to property 'dataObj' of type 'data'");
        RLMAssertCount(AllOptionalPrimitiveDictionaries, count, query, NSNull.null);

        query = [NSString stringWithFormat:@"ANY link.dataObj %@ nil", operator];
        RLMAssertThrowsWithReason([LinkToAllPrimitiveDictionaries objectsInRealm:realm where:query],
                                  @"Cannot compare value '(null)' of type '(null)' to property 'dataObj' of type 'data'");
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
