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
    RLMAssertThrowsWithReason([realm deleteObjects:unmanaged.boolObj], @"Cannot delete objects from RLMArray");
    RLMAssertThrowsWithReason([realm deleteObjects:unmanaged.intObj], @"Cannot delete objects from RLMArray");
    RLMAssertThrowsWithReason([realm deleteObjects:unmanaged.floatObj], @"Cannot delete objects from RLMArray");
    RLMAssertThrowsWithReason([realm deleteObjects:unmanaged.doubleObj], @"Cannot delete objects from RLMArray");
    RLMAssertThrowsWithReason([realm deleteObjects:unmanaged.stringObj], @"Cannot delete objects from RLMArray");
    RLMAssertThrowsWithReason([realm deleteObjects:unmanaged.dataObj], @"Cannot delete objects from RLMArray");
    RLMAssertThrowsWithReason([realm deleteObjects:unmanaged.dateObj], @"Cannot delete objects from RLMArray");
    RLMAssertThrowsWithReason([realm deleteObjects:optUnmanaged.boolObj], @"Cannot delete objects from RLMArray");
    RLMAssertThrowsWithReason([realm deleteObjects:optUnmanaged.intObj], @"Cannot delete objects from RLMArray");
    RLMAssertThrowsWithReason([realm deleteObjects:optUnmanaged.floatObj], @"Cannot delete objects from RLMArray");
    RLMAssertThrowsWithReason([realm deleteObjects:optUnmanaged.doubleObj], @"Cannot delete objects from RLMArray");
    RLMAssertThrowsWithReason([realm deleteObjects:optUnmanaged.stringObj], @"Cannot delete objects from RLMArray");
    RLMAssertThrowsWithReason([realm deleteObjects:optUnmanaged.dataObj], @"Cannot delete objects from RLMArray");
    RLMAssertThrowsWithReason([realm deleteObjects:optUnmanaged.dateObj], @"Cannot delete objects from RLMArray");
    RLMAssertThrowsWithReason([realm deleteObjects:managed.boolObj], @"Cannot delete objects from RLMArray");
    RLMAssertThrowsWithReason([realm deleteObjects:managed.intObj], @"Cannot delete objects from RLMArray");
    RLMAssertThrowsWithReason([realm deleteObjects:managed.floatObj], @"Cannot delete objects from RLMArray");
    RLMAssertThrowsWithReason([realm deleteObjects:managed.doubleObj], @"Cannot delete objects from RLMArray");
    RLMAssertThrowsWithReason([realm deleteObjects:managed.stringObj], @"Cannot delete objects from RLMArray");
    RLMAssertThrowsWithReason([realm deleteObjects:managed.dataObj], @"Cannot delete objects from RLMArray");
    RLMAssertThrowsWithReason([realm deleteObjects:managed.dateObj], @"Cannot delete objects from RLMArray");
    RLMAssertThrowsWithReason([realm deleteObjects:optManaged.boolObj], @"Cannot delete objects from RLMArray");
    RLMAssertThrowsWithReason([realm deleteObjects:optManaged.intObj], @"Cannot delete objects from RLMArray");
    RLMAssertThrowsWithReason([realm deleteObjects:optManaged.floatObj], @"Cannot delete objects from RLMArray");
    RLMAssertThrowsWithReason([realm deleteObjects:optManaged.doubleObj], @"Cannot delete objects from RLMArray");
    RLMAssertThrowsWithReason([realm deleteObjects:optManaged.stringObj], @"Cannot delete objects from RLMArray");
    RLMAssertThrowsWithReason([realm deleteObjects:optManaged.dataObj], @"Cannot delete objects from RLMArray");
    RLMAssertThrowsWithReason([realm deleteObjects:optManaged.dateObj], @"Cannot delete objects from RLMArray");
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
    XCTAssertNil(unmanaged.boolObj.firstObject);
    XCTAssertNil(unmanaged.intObj.firstObject);
    XCTAssertNil(unmanaged.floatObj.firstObject);
    XCTAssertNil(unmanaged.doubleObj.firstObject);
    XCTAssertNil(unmanaged.stringObj.firstObject);
    XCTAssertNil(unmanaged.dataObj.firstObject);
    XCTAssertNil(unmanaged.dateObj.firstObject);
    XCTAssertNil(optUnmanaged.boolObj.firstObject);
    XCTAssertNil(optUnmanaged.intObj.firstObject);
    XCTAssertNil(optUnmanaged.floatObj.firstObject);
    XCTAssertNil(optUnmanaged.doubleObj.firstObject);
    XCTAssertNil(optUnmanaged.stringObj.firstObject);
    XCTAssertNil(optUnmanaged.dataObj.firstObject);
    XCTAssertNil(optUnmanaged.dateObj.firstObject);
    XCTAssertNil(managed.boolObj.firstObject);
    XCTAssertNil(managed.intObj.firstObject);
    XCTAssertNil(managed.floatObj.firstObject);
    XCTAssertNil(managed.doubleObj.firstObject);
    XCTAssertNil(managed.stringObj.firstObject);
    XCTAssertNil(managed.dataObj.firstObject);
    XCTAssertNil(managed.dateObj.firstObject);
    XCTAssertNil(optManaged.boolObj.firstObject);
    XCTAssertNil(optManaged.intObj.firstObject);
    XCTAssertNil(optManaged.floatObj.firstObject);
    XCTAssertNil(optManaged.doubleObj.firstObject);
    XCTAssertNil(optManaged.stringObj.firstObject);
    XCTAssertNil(optManaged.dataObj.firstObject);
    XCTAssertNil(optManaged.dateObj.firstObject);

    [unmanaged.boolObj addObjects:@[@NO, @YES]];
    [unmanaged.intObj addObjects:@[@2, @3]];
    [unmanaged.floatObj addObjects:@[@2.2f, @3.3f]];
    [unmanaged.doubleObj addObjects:@[@2.2, @3.3]];
    [unmanaged.stringObj addObjects:@[@"a", @"b"]];
    [unmanaged.dataObj addObjects:@[data(1), data(2)]];
    [unmanaged.dateObj addObjects:@[date(1), date(2)]];
    [managed.boolObj addObjects:@[@NO, @YES]];
    [managed.intObj addObjects:@[@2, @3]];
    [managed.floatObj addObjects:@[@2.2f, @3.3f]];
    [managed.doubleObj addObjects:@[@2.2, @3.3]];
    [managed.stringObj addObjects:@[@"a", @"b"]];
    [managed.dataObj addObjects:@[data(1), data(2)]];
    [managed.dateObj addObjects:@[date(1), date(2)]];
    XCTAssertEqualObjects(unmanaged.boolObj.firstObject, @NO);
    XCTAssertEqualObjects(unmanaged.intObj.firstObject, @2);
    XCTAssertEqualObjects(unmanaged.floatObj.firstObject, @2.2f);
    XCTAssertEqualObjects(unmanaged.doubleObj.firstObject, @2.2);
    XCTAssertEqualObjects(unmanaged.stringObj.firstObject, @"a");
    XCTAssertEqualObjects(unmanaged.dataObj.firstObject, data(1));
    XCTAssertEqualObjects(unmanaged.dateObj.firstObject, date(1));
    XCTAssertEqualObjects(managed.boolObj.firstObject, @NO);
    XCTAssertEqualObjects(managed.intObj.firstObject, @2);
    XCTAssertEqualObjects(managed.floatObj.firstObject, @2.2f);
    XCTAssertEqualObjects(managed.doubleObj.firstObject, @2.2);
    XCTAssertEqualObjects(managed.stringObj.firstObject, @"a");
    XCTAssertEqualObjects(managed.dataObj.firstObject, data(1));
    XCTAssertEqualObjects(managed.dateObj.firstObject, date(1));

    [optUnmanaged.boolObj addObject:NSNull.null];
    [optUnmanaged.intObj addObject:NSNull.null];
    [optUnmanaged.floatObj addObject:NSNull.null];
    [optUnmanaged.doubleObj addObject:NSNull.null];
    [optUnmanaged.stringObj addObject:NSNull.null];
    [optUnmanaged.dataObj addObject:NSNull.null];
    [optUnmanaged.dateObj addObject:NSNull.null];
    [optManaged.boolObj addObject:NSNull.null];
    [optManaged.intObj addObject:NSNull.null];
    [optManaged.floatObj addObject:NSNull.null];
    [optManaged.doubleObj addObject:NSNull.null];
    [optManaged.stringObj addObject:NSNull.null];
    [optManaged.dataObj addObject:NSNull.null];
    [optManaged.dateObj addObject:NSNull.null];
    XCTAssertEqualObjects(optUnmanaged.boolObj.firstObject, NSNull.null);
    XCTAssertEqualObjects(optUnmanaged.intObj.firstObject, NSNull.null);
    XCTAssertEqualObjects(optUnmanaged.floatObj.firstObject, NSNull.null);
    XCTAssertEqualObjects(optUnmanaged.doubleObj.firstObject, NSNull.null);
    XCTAssertEqualObjects(optUnmanaged.stringObj.firstObject, NSNull.null);
    XCTAssertEqualObjects(optUnmanaged.dataObj.firstObject, NSNull.null);
    XCTAssertEqualObjects(optUnmanaged.dateObj.firstObject, NSNull.null);
    XCTAssertEqualObjects(optManaged.boolObj.firstObject, NSNull.null);
    XCTAssertEqualObjects(optManaged.intObj.firstObject, NSNull.null);
    XCTAssertEqualObjects(optManaged.floatObj.firstObject, NSNull.null);
    XCTAssertEqualObjects(optManaged.doubleObj.firstObject, NSNull.null);
    XCTAssertEqualObjects(optManaged.stringObj.firstObject, NSNull.null);
    XCTAssertEqualObjects(optManaged.dataObj.firstObject, NSNull.null);
    XCTAssertEqualObjects(optManaged.dateObj.firstObject, NSNull.null);

    [optUnmanaged.boolObj removeAllObjects];
    [optUnmanaged.intObj removeAllObjects];
    [optUnmanaged.floatObj removeAllObjects];
    [optUnmanaged.doubleObj removeAllObjects];
    [optUnmanaged.stringObj removeAllObjects];
    [optUnmanaged.dataObj removeAllObjects];
    [optUnmanaged.dateObj removeAllObjects];
    [optManaged.boolObj removeAllObjects];
    [optManaged.intObj removeAllObjects];
    [optManaged.floatObj removeAllObjects];
    [optManaged.doubleObj removeAllObjects];
    [optManaged.stringObj removeAllObjects];
    [optManaged.dataObj removeAllObjects];
    [optManaged.dateObj removeAllObjects];

    [optUnmanaged.boolObj addObjects:@[@NO, @YES, NSNull.null]];
    [optUnmanaged.intObj addObjects:@[@2, @3, NSNull.null]];
    [optUnmanaged.floatObj addObjects:@[@2.2f, @3.3f, NSNull.null]];
    [optUnmanaged.doubleObj addObjects:@[@2.2, @3.3, NSNull.null]];
    [optUnmanaged.stringObj addObjects:@[@"a", @"b", NSNull.null]];
    [optUnmanaged.dataObj addObjects:@[data(1), data(2), NSNull.null]];
    [optUnmanaged.dateObj addObjects:@[date(1), date(2), NSNull.null]];
    [optManaged.boolObj addObjects:@[@NO, @YES, NSNull.null]];
    [optManaged.intObj addObjects:@[@2, @3, NSNull.null]];
    [optManaged.floatObj addObjects:@[@2.2f, @3.3f, NSNull.null]];
    [optManaged.doubleObj addObjects:@[@2.2, @3.3, NSNull.null]];
    [optManaged.stringObj addObjects:@[@"a", @"b", NSNull.null]];
    [optManaged.dataObj addObjects:@[data(1), data(2), NSNull.null]];
    [optManaged.dateObj addObjects:@[date(1), date(2), NSNull.null]];
    XCTAssertEqualObjects(optUnmanaged.boolObj.firstObject, @NO);
    XCTAssertEqualObjects(optUnmanaged.intObj.firstObject, @2);
    XCTAssertEqualObjects(optUnmanaged.floatObj.firstObject, @2.2f);
    XCTAssertEqualObjects(optUnmanaged.doubleObj.firstObject, @2.2);
    XCTAssertEqualObjects(optUnmanaged.stringObj.firstObject, @"a");
    XCTAssertEqualObjects(optUnmanaged.dataObj.firstObject, data(1));
    XCTAssertEqualObjects(optUnmanaged.dateObj.firstObject, date(1));
    XCTAssertEqualObjects(optManaged.boolObj.firstObject, @NO);
    XCTAssertEqualObjects(optManaged.intObj.firstObject, @2);
    XCTAssertEqualObjects(optManaged.floatObj.firstObject, @2.2f);
    XCTAssertEqualObjects(optManaged.doubleObj.firstObject, @2.2);
    XCTAssertEqualObjects(optManaged.stringObj.firstObject, @"a");
    XCTAssertEqualObjects(optManaged.dataObj.firstObject, data(1));
    XCTAssertEqualObjects(optManaged.dateObj.firstObject, date(1));
}

- (void)testLastObject {
    XCTAssertNil(unmanaged.boolObj.lastObject);
    XCTAssertNil(unmanaged.intObj.lastObject);
    XCTAssertNil(unmanaged.floatObj.lastObject);
    XCTAssertNil(unmanaged.doubleObj.lastObject);
    XCTAssertNil(unmanaged.stringObj.lastObject);
    XCTAssertNil(unmanaged.dataObj.lastObject);
    XCTAssertNil(unmanaged.dateObj.lastObject);
    XCTAssertNil(optUnmanaged.boolObj.lastObject);
    XCTAssertNil(optUnmanaged.intObj.lastObject);
    XCTAssertNil(optUnmanaged.floatObj.lastObject);
    XCTAssertNil(optUnmanaged.doubleObj.lastObject);
    XCTAssertNil(optUnmanaged.stringObj.lastObject);
    XCTAssertNil(optUnmanaged.dataObj.lastObject);
    XCTAssertNil(optUnmanaged.dateObj.lastObject);
    XCTAssertNil(managed.boolObj.lastObject);
    XCTAssertNil(managed.intObj.lastObject);
    XCTAssertNil(managed.floatObj.lastObject);
    XCTAssertNil(managed.doubleObj.lastObject);
    XCTAssertNil(managed.stringObj.lastObject);
    XCTAssertNil(managed.dataObj.lastObject);
    XCTAssertNil(managed.dateObj.lastObject);
    XCTAssertNil(optManaged.boolObj.lastObject);
    XCTAssertNil(optManaged.intObj.lastObject);
    XCTAssertNil(optManaged.floatObj.lastObject);
    XCTAssertNil(optManaged.doubleObj.lastObject);
    XCTAssertNil(optManaged.stringObj.lastObject);
    XCTAssertNil(optManaged.dataObj.lastObject);
    XCTAssertNil(optManaged.dateObj.lastObject);

    [unmanaged.boolObj addObjects:@[@NO, @YES]];
    [unmanaged.intObj addObjects:@[@2, @3]];
    [unmanaged.floatObj addObjects:@[@2.2f, @3.3f]];
    [unmanaged.doubleObj addObjects:@[@2.2, @3.3]];
    [unmanaged.stringObj addObjects:@[@"a", @"b"]];
    [unmanaged.dataObj addObjects:@[data(1), data(2)]];
    [unmanaged.dateObj addObjects:@[date(1), date(2)]];
    [optUnmanaged.boolObj addObjects:@[@NO, @YES, NSNull.null]];
    [optUnmanaged.intObj addObjects:@[@2, @3, NSNull.null]];
    [optUnmanaged.floatObj addObjects:@[@2.2f, @3.3f, NSNull.null]];
    [optUnmanaged.doubleObj addObjects:@[@2.2, @3.3, NSNull.null]];
    [optUnmanaged.stringObj addObjects:@[@"a", @"b", NSNull.null]];
    [optUnmanaged.dataObj addObjects:@[data(1), data(2), NSNull.null]];
    [optUnmanaged.dateObj addObjects:@[date(1), date(2), NSNull.null]];
    [managed.boolObj addObjects:@[@NO, @YES]];
    [managed.intObj addObjects:@[@2, @3]];
    [managed.floatObj addObjects:@[@2.2f, @3.3f]];
    [managed.doubleObj addObjects:@[@2.2, @3.3]];
    [managed.stringObj addObjects:@[@"a", @"b"]];
    [managed.dataObj addObjects:@[data(1), data(2)]];
    [managed.dateObj addObjects:@[date(1), date(2)]];
    [optManaged.boolObj addObjects:@[@NO, @YES, NSNull.null]];
    [optManaged.intObj addObjects:@[@2, @3, NSNull.null]];
    [optManaged.floatObj addObjects:@[@2.2f, @3.3f, NSNull.null]];
    [optManaged.doubleObj addObjects:@[@2.2, @3.3, NSNull.null]];
    [optManaged.stringObj addObjects:@[@"a", @"b", NSNull.null]];
    [optManaged.dataObj addObjects:@[data(1), data(2), NSNull.null]];
    [optManaged.dateObj addObjects:@[date(1), date(2), NSNull.null]];
    XCTAssertEqualObjects(unmanaged.boolObj.lastObject, @YES);
    XCTAssertEqualObjects(unmanaged.intObj.lastObject, @3);
    XCTAssertEqualObjects(unmanaged.floatObj.lastObject, @3.3f);
    XCTAssertEqualObjects(unmanaged.doubleObj.lastObject, @3.3);
    XCTAssertEqualObjects(unmanaged.stringObj.lastObject, @"b");
    XCTAssertEqualObjects(unmanaged.dataObj.lastObject, data(2));
    XCTAssertEqualObjects(unmanaged.dateObj.lastObject, date(2));
    XCTAssertEqualObjects(optUnmanaged.boolObj.lastObject, NSNull.null);
    XCTAssertEqualObjects(optUnmanaged.intObj.lastObject, NSNull.null);
    XCTAssertEqualObjects(optUnmanaged.floatObj.lastObject, NSNull.null);
    XCTAssertEqualObjects(optUnmanaged.doubleObj.lastObject, NSNull.null);
    XCTAssertEqualObjects(optUnmanaged.stringObj.lastObject, NSNull.null);
    XCTAssertEqualObjects(optUnmanaged.dataObj.lastObject, NSNull.null);
    XCTAssertEqualObjects(optUnmanaged.dateObj.lastObject, NSNull.null);
    XCTAssertEqualObjects(managed.boolObj.lastObject, @YES);
    XCTAssertEqualObjects(managed.intObj.lastObject, @3);
    XCTAssertEqualObjects(managed.floatObj.lastObject, @3.3f);
    XCTAssertEqualObjects(managed.doubleObj.lastObject, @3.3);
    XCTAssertEqualObjects(managed.stringObj.lastObject, @"b");
    XCTAssertEqualObjects(managed.dataObj.lastObject, data(2));
    XCTAssertEqualObjects(managed.dateObj.lastObject, date(2));
    XCTAssertEqualObjects(optManaged.boolObj.lastObject, NSNull.null);
    XCTAssertEqualObjects(optManaged.intObj.lastObject, NSNull.null);
    XCTAssertEqualObjects(optManaged.floatObj.lastObject, NSNull.null);
    XCTAssertEqualObjects(optManaged.doubleObj.lastObject, NSNull.null);
    XCTAssertEqualObjects(optManaged.stringObj.lastObject, NSNull.null);
    XCTAssertEqualObjects(optManaged.dataObj.lastObject, NSNull.null);
    XCTAssertEqualObjects(optManaged.dateObj.lastObject, NSNull.null);

    [optUnmanaged.boolObj removeLastObject];
    [optUnmanaged.intObj removeLastObject];
    [optUnmanaged.floatObj removeLastObject];
    [optUnmanaged.doubleObj removeLastObject];
    [optUnmanaged.stringObj removeLastObject];
    [optUnmanaged.dataObj removeLastObject];
    [optUnmanaged.dateObj removeLastObject];
    [optManaged.boolObj removeLastObject];
    [optManaged.intObj removeLastObject];
    [optManaged.floatObj removeLastObject];
    [optManaged.doubleObj removeLastObject];
    [optManaged.stringObj removeLastObject];
    [optManaged.dataObj removeLastObject];
    [optManaged.dateObj removeLastObject];
    XCTAssertEqualObjects(optUnmanaged.boolObj.lastObject, @YES);
    XCTAssertEqualObjects(optUnmanaged.intObj.lastObject, @3);
    XCTAssertEqualObjects(optUnmanaged.floatObj.lastObject, @3.3f);
    XCTAssertEqualObjects(optUnmanaged.doubleObj.lastObject, @3.3);
    XCTAssertEqualObjects(optUnmanaged.stringObj.lastObject, @"b");
    XCTAssertEqualObjects(optUnmanaged.dataObj.lastObject, data(2));
    XCTAssertEqualObjects(optUnmanaged.dateObj.lastObject, date(2));
    XCTAssertEqualObjects(optManaged.boolObj.lastObject, @YES);
    XCTAssertEqualObjects(optManaged.intObj.lastObject, @3);
    XCTAssertEqualObjects(optManaged.floatObj.lastObject, @3.3f);
    XCTAssertEqualObjects(optManaged.doubleObj.lastObject, @3.3);
    XCTAssertEqualObjects(optManaged.stringObj.lastObject, @"b");
    XCTAssertEqualObjects(optManaged.dataObj.lastObject, data(2));
    XCTAssertEqualObjects(optManaged.dateObj.lastObject, date(2));
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

    [unmanaged.boolObj addObject:@NO];
    [unmanaged.intObj addObject:@2];
    [unmanaged.floatObj addObject:@2.2f];
    [unmanaged.doubleObj addObject:@2.2];
    [unmanaged.stringObj addObject:@"a"];
    [unmanaged.dataObj addObject:data(1)];
    [unmanaged.dateObj addObject:date(1)];
    [optUnmanaged.boolObj addObject:@NO];
    [optUnmanaged.intObj addObject:@2];
    [optUnmanaged.floatObj addObject:@2.2f];
    [optUnmanaged.doubleObj addObject:@2.2];
    [optUnmanaged.stringObj addObject:@"a"];
    [optUnmanaged.dataObj addObject:data(1)];
    [optUnmanaged.dateObj addObject:date(1)];
    [managed.boolObj addObject:@NO];
    [managed.intObj addObject:@2];
    [managed.floatObj addObject:@2.2f];
    [managed.doubleObj addObject:@2.2];
    [managed.stringObj addObject:@"a"];
    [managed.dataObj addObject:data(1)];
    [managed.dateObj addObject:date(1)];
    [optManaged.boolObj addObject:@NO];
    [optManaged.intObj addObject:@2];
    [optManaged.floatObj addObject:@2.2f];
    [optManaged.doubleObj addObject:@2.2];
    [optManaged.stringObj addObject:@"a"];
    [optManaged.dataObj addObject:data(1)];
    [optManaged.dateObj addObject:date(1)];
    XCTAssertEqualObjects(unmanaged.boolObj[0], @NO);
    XCTAssertEqualObjects(unmanaged.intObj[0], @2);
    XCTAssertEqualObjects(unmanaged.floatObj[0], @2.2f);
    XCTAssertEqualObjects(unmanaged.doubleObj[0], @2.2);
    XCTAssertEqualObjects(unmanaged.stringObj[0], @"a");
    XCTAssertEqualObjects(unmanaged.dataObj[0], data(1));
    XCTAssertEqualObjects(unmanaged.dateObj[0], date(1));
    XCTAssertEqualObjects(optUnmanaged.boolObj[0], @NO);
    XCTAssertEqualObjects(optUnmanaged.intObj[0], @2);
    XCTAssertEqualObjects(optUnmanaged.floatObj[0], @2.2f);
    XCTAssertEqualObjects(optUnmanaged.doubleObj[0], @2.2);
    XCTAssertEqualObjects(optUnmanaged.stringObj[0], @"a");
    XCTAssertEqualObjects(optUnmanaged.dataObj[0], data(1));
    XCTAssertEqualObjects(optUnmanaged.dateObj[0], date(1));
    XCTAssertEqualObjects(managed.boolObj[0], @NO);
    XCTAssertEqualObjects(managed.intObj[0], @2);
    XCTAssertEqualObjects(managed.floatObj[0], @2.2f);
    XCTAssertEqualObjects(managed.doubleObj[0], @2.2);
    XCTAssertEqualObjects(managed.stringObj[0], @"a");
    XCTAssertEqualObjects(managed.dataObj[0], data(1));
    XCTAssertEqualObjects(managed.dateObj[0], date(1));
    XCTAssertEqualObjects(optManaged.boolObj[0], @NO);
    XCTAssertEqualObjects(optManaged.intObj[0], @2);
    XCTAssertEqualObjects(optManaged.floatObj[0], @2.2f);
    XCTAssertEqualObjects(optManaged.doubleObj[0], @2.2);
    XCTAssertEqualObjects(optManaged.stringObj[0], @"a");
    XCTAssertEqualObjects(optManaged.dataObj[0], data(1));
    XCTAssertEqualObjects(optManaged.dateObj[0], date(1));

    [optUnmanaged.boolObj addObject:NSNull.null];
    [optUnmanaged.intObj addObject:NSNull.null];
    [optUnmanaged.floatObj addObject:NSNull.null];
    [optUnmanaged.doubleObj addObject:NSNull.null];
    [optUnmanaged.stringObj addObject:NSNull.null];
    [optUnmanaged.dataObj addObject:NSNull.null];
    [optUnmanaged.dateObj addObject:NSNull.null];
    [optManaged.boolObj addObject:NSNull.null];
    [optManaged.intObj addObject:NSNull.null];
    [optManaged.floatObj addObject:NSNull.null];
    [optManaged.doubleObj addObject:NSNull.null];
    [optManaged.stringObj addObject:NSNull.null];
    [optManaged.dataObj addObject:NSNull.null];
    [optManaged.dateObj addObject:NSNull.null];
    XCTAssertEqualObjects(optUnmanaged.boolObj[1], NSNull.null);
    XCTAssertEqualObjects(optUnmanaged.intObj[1], NSNull.null);
    XCTAssertEqualObjects(optUnmanaged.floatObj[1], NSNull.null);
    XCTAssertEqualObjects(optUnmanaged.doubleObj[1], NSNull.null);
    XCTAssertEqualObjects(optUnmanaged.stringObj[1], NSNull.null);
    XCTAssertEqualObjects(optUnmanaged.dataObj[1], NSNull.null);
    XCTAssertEqualObjects(optUnmanaged.dateObj[1], NSNull.null);
    XCTAssertEqualObjects(optManaged.boolObj[1], NSNull.null);
    XCTAssertEqualObjects(optManaged.intObj[1], NSNull.null);
    XCTAssertEqualObjects(optManaged.floatObj[1], NSNull.null);
    XCTAssertEqualObjects(optManaged.doubleObj[1], NSNull.null);
    XCTAssertEqualObjects(optManaged.stringObj[1], NSNull.null);
    XCTAssertEqualObjects(optManaged.dataObj[1], NSNull.null);
    XCTAssertEqualObjects(optManaged.dateObj[1], NSNull.null);
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

    [unmanaged.boolObj addObjects:@[@NO, @YES]];
    [unmanaged.intObj addObjects:@[@2, @3]];
    [unmanaged.floatObj addObjects:@[@2.2f, @3.3f]];
    [unmanaged.doubleObj addObjects:@[@2.2, @3.3]];
    [unmanaged.stringObj addObjects:@[@"a", @"b"]];
    [unmanaged.dataObj addObjects:@[data(1), data(2)]];
    [unmanaged.dateObj addObjects:@[date(1), date(2)]];
    [optUnmanaged.boolObj addObjects:@[@NO, @YES, NSNull.null]];
    [optUnmanaged.intObj addObjects:@[@2, @3, NSNull.null]];
    [optUnmanaged.floatObj addObjects:@[@2.2f, @3.3f, NSNull.null]];
    [optUnmanaged.doubleObj addObjects:@[@2.2, @3.3, NSNull.null]];
    [optUnmanaged.stringObj addObjects:@[@"a", @"b", NSNull.null]];
    [optUnmanaged.dataObj addObjects:@[data(1), data(2), NSNull.null]];
    [optUnmanaged.dateObj addObjects:@[date(1), date(2), NSNull.null]];
    [managed.boolObj addObjects:@[@NO, @YES]];
    [managed.intObj addObjects:@[@2, @3]];
    [managed.floatObj addObjects:@[@2.2f, @3.3f]];
    [managed.doubleObj addObjects:@[@2.2, @3.3]];
    [managed.stringObj addObjects:@[@"a", @"b"]];
    [managed.dataObj addObjects:@[data(1), data(2)]];
    [managed.dateObj addObjects:@[date(1), date(2)]];
    [optManaged.boolObj addObjects:@[@NO, @YES, NSNull.null]];
    [optManaged.intObj addObjects:@[@2, @3, NSNull.null]];
    [optManaged.floatObj addObjects:@[@2.2f, @3.3f, NSNull.null]];
    [optManaged.doubleObj addObjects:@[@2.2, @3.3, NSNull.null]];
    [optManaged.stringObj addObjects:@[@"a", @"b", NSNull.null]];
    [optManaged.dataObj addObjects:@[data(1), data(2), NSNull.null]];
    [optManaged.dateObj addObjects:@[date(1), date(2), NSNull.null]];
    XCTAssertEqualObjects(unmanaged.boolObj[0], @NO);
    XCTAssertEqualObjects(unmanaged.intObj[0], @2);
    XCTAssertEqualObjects(unmanaged.floatObj[0], @2.2f);
    XCTAssertEqualObjects(unmanaged.doubleObj[0], @2.2);
    XCTAssertEqualObjects(unmanaged.stringObj[0], @"a");
    XCTAssertEqualObjects(unmanaged.dataObj[0], data(1));
    XCTAssertEqualObjects(unmanaged.dateObj[0], date(1));
    XCTAssertEqualObjects(optUnmanaged.boolObj[0], @NO);
    XCTAssertEqualObjects(optUnmanaged.intObj[0], @2);
    XCTAssertEqualObjects(optUnmanaged.floatObj[0], @2.2f);
    XCTAssertEqualObjects(optUnmanaged.doubleObj[0], @2.2);
    XCTAssertEqualObjects(optUnmanaged.stringObj[0], @"a");
    XCTAssertEqualObjects(optUnmanaged.dataObj[0], data(1));
    XCTAssertEqualObjects(optUnmanaged.dateObj[0], date(1));
    XCTAssertEqualObjects(managed.boolObj[0], @NO);
    XCTAssertEqualObjects(managed.intObj[0], @2);
    XCTAssertEqualObjects(managed.floatObj[0], @2.2f);
    XCTAssertEqualObjects(managed.doubleObj[0], @2.2);
    XCTAssertEqualObjects(managed.stringObj[0], @"a");
    XCTAssertEqualObjects(managed.dataObj[0], data(1));
    XCTAssertEqualObjects(managed.dateObj[0], date(1));
    XCTAssertEqualObjects(optManaged.boolObj[0], @NO);
    XCTAssertEqualObjects(optManaged.intObj[0], @2);
    XCTAssertEqualObjects(optManaged.floatObj[0], @2.2f);
    XCTAssertEqualObjects(optManaged.doubleObj[0], @2.2);
    XCTAssertEqualObjects(optManaged.stringObj[0], @"a");
    XCTAssertEqualObjects(optManaged.dataObj[0], data(1));
    XCTAssertEqualObjects(optManaged.dateObj[0], date(1));
    XCTAssertEqualObjects(unmanaged.boolObj[1], @YES);
    XCTAssertEqualObjects(unmanaged.intObj[1], @3);
    XCTAssertEqualObjects(unmanaged.floatObj[1], @3.3f);
    XCTAssertEqualObjects(unmanaged.doubleObj[1], @3.3);
    XCTAssertEqualObjects(unmanaged.stringObj[1], @"b");
    XCTAssertEqualObjects(unmanaged.dataObj[1], data(2));
    XCTAssertEqualObjects(unmanaged.dateObj[1], date(2));
    XCTAssertEqualObjects(optUnmanaged.boolObj[1], @YES);
    XCTAssertEqualObjects(optUnmanaged.intObj[1], @3);
    XCTAssertEqualObjects(optUnmanaged.floatObj[1], @3.3f);
    XCTAssertEqualObjects(optUnmanaged.doubleObj[1], @3.3);
    XCTAssertEqualObjects(optUnmanaged.stringObj[1], @"b");
    XCTAssertEqualObjects(optUnmanaged.dataObj[1], data(2));
    XCTAssertEqualObjects(optUnmanaged.dateObj[1], date(2));
    XCTAssertEqualObjects(managed.boolObj[1], @YES);
    XCTAssertEqualObjects(managed.intObj[1], @3);
    XCTAssertEqualObjects(managed.floatObj[1], @3.3f);
    XCTAssertEqualObjects(managed.doubleObj[1], @3.3);
    XCTAssertEqualObjects(managed.stringObj[1], @"b");
    XCTAssertEqualObjects(managed.dataObj[1], data(2));
    XCTAssertEqualObjects(managed.dateObj[1], date(2));
    XCTAssertEqualObjects(optManaged.boolObj[1], @YES);
    XCTAssertEqualObjects(optManaged.intObj[1], @3);
    XCTAssertEqualObjects(optManaged.floatObj[1], @3.3f);
    XCTAssertEqualObjects(optManaged.doubleObj[1], @3.3);
    XCTAssertEqualObjects(optManaged.stringObj[1], @"b");
    XCTAssertEqualObjects(optManaged.dataObj[1], data(2));
    XCTAssertEqualObjects(optManaged.dateObj[1], date(2));
    XCTAssertEqualObjects(optUnmanaged.boolObj[2], NSNull.null);
    XCTAssertEqualObjects(optUnmanaged.intObj[2], NSNull.null);
    XCTAssertEqualObjects(optUnmanaged.floatObj[2], NSNull.null);
    XCTAssertEqualObjects(optUnmanaged.doubleObj[2], NSNull.null);
    XCTAssertEqualObjects(optUnmanaged.stringObj[2], NSNull.null);
    XCTAssertEqualObjects(optUnmanaged.dataObj[2], NSNull.null);
    XCTAssertEqualObjects(optUnmanaged.dateObj[2], NSNull.null);
    XCTAssertEqualObjects(optManaged.boolObj[2], NSNull.null);
    XCTAssertEqualObjects(optManaged.intObj[2], NSNull.null);
    XCTAssertEqualObjects(optManaged.floatObj[2], NSNull.null);
    XCTAssertEqualObjects(optManaged.doubleObj[2], NSNull.null);
    XCTAssertEqualObjects(optManaged.stringObj[2], NSNull.null);
    XCTAssertEqualObjects(optManaged.dataObj[2], NSNull.null);
    XCTAssertEqualObjects(optManaged.dateObj[2], NSNull.null);
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

    [unmanaged.boolObj insertObject:@NO atIndex:0];
    [unmanaged.intObj insertObject:@2 atIndex:0];
    [unmanaged.floatObj insertObject:@2.2f atIndex:0];
    [unmanaged.doubleObj insertObject:@2.2 atIndex:0];
    [unmanaged.stringObj insertObject:@"a" atIndex:0];
    [unmanaged.dataObj insertObject:data(1) atIndex:0];
    [unmanaged.dateObj insertObject:date(1) atIndex:0];
    [optUnmanaged.boolObj insertObject:@NO atIndex:0];
    [optUnmanaged.intObj insertObject:@2 atIndex:0];
    [optUnmanaged.floatObj insertObject:@2.2f atIndex:0];
    [optUnmanaged.doubleObj insertObject:@2.2 atIndex:0];
    [optUnmanaged.stringObj insertObject:@"a" atIndex:0];
    [optUnmanaged.dataObj insertObject:data(1) atIndex:0];
    [optUnmanaged.dateObj insertObject:date(1) atIndex:0];
    [managed.boolObj insertObject:@NO atIndex:0];
    [managed.intObj insertObject:@2 atIndex:0];
    [managed.floatObj insertObject:@2.2f atIndex:0];
    [managed.doubleObj insertObject:@2.2 atIndex:0];
    [managed.stringObj insertObject:@"a" atIndex:0];
    [managed.dataObj insertObject:data(1) atIndex:0];
    [managed.dateObj insertObject:date(1) atIndex:0];
    [optManaged.boolObj insertObject:@NO atIndex:0];
    [optManaged.intObj insertObject:@2 atIndex:0];
    [optManaged.floatObj insertObject:@2.2f atIndex:0];
    [optManaged.doubleObj insertObject:@2.2 atIndex:0];
    [optManaged.stringObj insertObject:@"a" atIndex:0];
    [optManaged.dataObj insertObject:data(1) atIndex:0];
    [optManaged.dateObj insertObject:date(1) atIndex:0];
    XCTAssertEqualObjects(unmanaged.boolObj[0], @NO);
    XCTAssertEqualObjects(unmanaged.intObj[0], @2);
    XCTAssertEqualObjects(unmanaged.floatObj[0], @2.2f);
    XCTAssertEqualObjects(unmanaged.doubleObj[0], @2.2);
    XCTAssertEqualObjects(unmanaged.stringObj[0], @"a");
    XCTAssertEqualObjects(unmanaged.dataObj[0], data(1));
    XCTAssertEqualObjects(unmanaged.dateObj[0], date(1));
    XCTAssertEqualObjects(optUnmanaged.boolObj[0], @NO);
    XCTAssertEqualObjects(optUnmanaged.intObj[0], @2);
    XCTAssertEqualObjects(optUnmanaged.floatObj[0], @2.2f);
    XCTAssertEqualObjects(optUnmanaged.doubleObj[0], @2.2);
    XCTAssertEqualObjects(optUnmanaged.stringObj[0], @"a");
    XCTAssertEqualObjects(optUnmanaged.dataObj[0], data(1));
    XCTAssertEqualObjects(optUnmanaged.dateObj[0], date(1));
    XCTAssertEqualObjects(managed.boolObj[0], @NO);
    XCTAssertEqualObjects(managed.intObj[0], @2);
    XCTAssertEqualObjects(managed.floatObj[0], @2.2f);
    XCTAssertEqualObjects(managed.doubleObj[0], @2.2);
    XCTAssertEqualObjects(managed.stringObj[0], @"a");
    XCTAssertEqualObjects(managed.dataObj[0], data(1));
    XCTAssertEqualObjects(managed.dateObj[0], date(1));
    XCTAssertEqualObjects(optManaged.boolObj[0], @NO);
    XCTAssertEqualObjects(optManaged.intObj[0], @2);
    XCTAssertEqualObjects(optManaged.floatObj[0], @2.2f);
    XCTAssertEqualObjects(optManaged.doubleObj[0], @2.2);
    XCTAssertEqualObjects(optManaged.stringObj[0], @"a");
    XCTAssertEqualObjects(optManaged.dataObj[0], data(1));
    XCTAssertEqualObjects(optManaged.dateObj[0], date(1));

    [unmanaged.boolObj insertObject:@YES atIndex:0];
    [unmanaged.intObj insertObject:@3 atIndex:0];
    [unmanaged.floatObj insertObject:@3.3f atIndex:0];
    [unmanaged.doubleObj insertObject:@3.3 atIndex:0];
    [unmanaged.stringObj insertObject:@"b" atIndex:0];
    [unmanaged.dataObj insertObject:data(2) atIndex:0];
    [unmanaged.dateObj insertObject:date(2) atIndex:0];
    [optUnmanaged.boolObj insertObject:@YES atIndex:0];
    [optUnmanaged.intObj insertObject:@3 atIndex:0];
    [optUnmanaged.floatObj insertObject:@3.3f atIndex:0];
    [optUnmanaged.doubleObj insertObject:@3.3 atIndex:0];
    [optUnmanaged.stringObj insertObject:@"b" atIndex:0];
    [optUnmanaged.dataObj insertObject:data(2) atIndex:0];
    [optUnmanaged.dateObj insertObject:date(2) atIndex:0];
    [managed.boolObj insertObject:@YES atIndex:0];
    [managed.intObj insertObject:@3 atIndex:0];
    [managed.floatObj insertObject:@3.3f atIndex:0];
    [managed.doubleObj insertObject:@3.3 atIndex:0];
    [managed.stringObj insertObject:@"b" atIndex:0];
    [managed.dataObj insertObject:data(2) atIndex:0];
    [managed.dateObj insertObject:date(2) atIndex:0];
    [optManaged.boolObj insertObject:@YES atIndex:0];
    [optManaged.intObj insertObject:@3 atIndex:0];
    [optManaged.floatObj insertObject:@3.3f atIndex:0];
    [optManaged.doubleObj insertObject:@3.3 atIndex:0];
    [optManaged.stringObj insertObject:@"b" atIndex:0];
    [optManaged.dataObj insertObject:data(2) atIndex:0];
    [optManaged.dateObj insertObject:date(2) atIndex:0];
    XCTAssertEqualObjects(unmanaged.boolObj[0], @YES);
    XCTAssertEqualObjects(unmanaged.intObj[0], @3);
    XCTAssertEqualObjects(unmanaged.floatObj[0], @3.3f);
    XCTAssertEqualObjects(unmanaged.doubleObj[0], @3.3);
    XCTAssertEqualObjects(unmanaged.stringObj[0], @"b");
    XCTAssertEqualObjects(unmanaged.dataObj[0], data(2));
    XCTAssertEqualObjects(unmanaged.dateObj[0], date(2));
    XCTAssertEqualObjects(optUnmanaged.boolObj[0], @YES);
    XCTAssertEqualObjects(optUnmanaged.intObj[0], @3);
    XCTAssertEqualObjects(optUnmanaged.floatObj[0], @3.3f);
    XCTAssertEqualObjects(optUnmanaged.doubleObj[0], @3.3);
    XCTAssertEqualObjects(optUnmanaged.stringObj[0], @"b");
    XCTAssertEqualObjects(optUnmanaged.dataObj[0], data(2));
    XCTAssertEqualObjects(optUnmanaged.dateObj[0], date(2));
    XCTAssertEqualObjects(managed.boolObj[0], @YES);
    XCTAssertEqualObjects(managed.intObj[0], @3);
    XCTAssertEqualObjects(managed.floatObj[0], @3.3f);
    XCTAssertEqualObjects(managed.doubleObj[0], @3.3);
    XCTAssertEqualObjects(managed.stringObj[0], @"b");
    XCTAssertEqualObjects(managed.dataObj[0], data(2));
    XCTAssertEqualObjects(managed.dateObj[0], date(2));
    XCTAssertEqualObjects(optManaged.boolObj[0], @YES);
    XCTAssertEqualObjects(optManaged.intObj[0], @3);
    XCTAssertEqualObjects(optManaged.floatObj[0], @3.3f);
    XCTAssertEqualObjects(optManaged.doubleObj[0], @3.3);
    XCTAssertEqualObjects(optManaged.stringObj[0], @"b");
    XCTAssertEqualObjects(optManaged.dataObj[0], data(2));
    XCTAssertEqualObjects(optManaged.dateObj[0], date(2));
    XCTAssertEqualObjects(unmanaged.boolObj[1], @NO);
    XCTAssertEqualObjects(unmanaged.intObj[1], @2);
    XCTAssertEqualObjects(unmanaged.floatObj[1], @2.2f);
    XCTAssertEqualObjects(unmanaged.doubleObj[1], @2.2);
    XCTAssertEqualObjects(unmanaged.stringObj[1], @"a");
    XCTAssertEqualObjects(unmanaged.dataObj[1], data(1));
    XCTAssertEqualObjects(unmanaged.dateObj[1], date(1));
    XCTAssertEqualObjects(optUnmanaged.boolObj[1], @NO);
    XCTAssertEqualObjects(optUnmanaged.intObj[1], @2);
    XCTAssertEqualObjects(optUnmanaged.floatObj[1], @2.2f);
    XCTAssertEqualObjects(optUnmanaged.doubleObj[1], @2.2);
    XCTAssertEqualObjects(optUnmanaged.stringObj[1], @"a");
    XCTAssertEqualObjects(optUnmanaged.dataObj[1], data(1));
    XCTAssertEqualObjects(optUnmanaged.dateObj[1], date(1));
    XCTAssertEqualObjects(managed.boolObj[1], @NO);
    XCTAssertEqualObjects(managed.intObj[1], @2);
    XCTAssertEqualObjects(managed.floatObj[1], @2.2f);
    XCTAssertEqualObjects(managed.doubleObj[1], @2.2);
    XCTAssertEqualObjects(managed.stringObj[1], @"a");
    XCTAssertEqualObjects(managed.dataObj[1], data(1));
    XCTAssertEqualObjects(managed.dateObj[1], date(1));
    XCTAssertEqualObjects(optManaged.boolObj[1], @NO);
    XCTAssertEqualObjects(optManaged.intObj[1], @2);
    XCTAssertEqualObjects(optManaged.floatObj[1], @2.2f);
    XCTAssertEqualObjects(optManaged.doubleObj[1], @2.2);
    XCTAssertEqualObjects(optManaged.stringObj[1], @"a");
    XCTAssertEqualObjects(optManaged.dataObj[1], data(1));
    XCTAssertEqualObjects(optManaged.dateObj[1], date(1));

    [optUnmanaged.boolObj insertObject:NSNull.null atIndex:1];
    [optUnmanaged.intObj insertObject:NSNull.null atIndex:1];
    [optUnmanaged.floatObj insertObject:NSNull.null atIndex:1];
    [optUnmanaged.doubleObj insertObject:NSNull.null atIndex:1];
    [optUnmanaged.stringObj insertObject:NSNull.null atIndex:1];
    [optUnmanaged.dataObj insertObject:NSNull.null atIndex:1];
    [optUnmanaged.dateObj insertObject:NSNull.null atIndex:1];
    [optManaged.boolObj insertObject:NSNull.null atIndex:1];
    [optManaged.intObj insertObject:NSNull.null atIndex:1];
    [optManaged.floatObj insertObject:NSNull.null atIndex:1];
    [optManaged.doubleObj insertObject:NSNull.null atIndex:1];
    [optManaged.stringObj insertObject:NSNull.null atIndex:1];
    [optManaged.dataObj insertObject:NSNull.null atIndex:1];
    [optManaged.dateObj insertObject:NSNull.null atIndex:1];
    XCTAssertEqualObjects(optUnmanaged.boolObj[0], @YES);
    XCTAssertEqualObjects(optUnmanaged.intObj[0], @3);
    XCTAssertEqualObjects(optUnmanaged.floatObj[0], @3.3f);
    XCTAssertEqualObjects(optUnmanaged.doubleObj[0], @3.3);
    XCTAssertEqualObjects(optUnmanaged.stringObj[0], @"b");
    XCTAssertEqualObjects(optUnmanaged.dataObj[0], data(2));
    XCTAssertEqualObjects(optUnmanaged.dateObj[0], date(2));
    XCTAssertEqualObjects(optManaged.boolObj[0], @YES);
    XCTAssertEqualObjects(optManaged.intObj[0], @3);
    XCTAssertEqualObjects(optManaged.floatObj[0], @3.3f);
    XCTAssertEqualObjects(optManaged.doubleObj[0], @3.3);
    XCTAssertEqualObjects(optManaged.stringObj[0], @"b");
    XCTAssertEqualObjects(optManaged.dataObj[0], data(2));
    XCTAssertEqualObjects(optManaged.dateObj[0], date(2));
    XCTAssertEqualObjects(optUnmanaged.boolObj[1], NSNull.null);
    XCTAssertEqualObjects(optUnmanaged.intObj[1], NSNull.null);
    XCTAssertEqualObjects(optUnmanaged.floatObj[1], NSNull.null);
    XCTAssertEqualObjects(optUnmanaged.doubleObj[1], NSNull.null);
    XCTAssertEqualObjects(optUnmanaged.stringObj[1], NSNull.null);
    XCTAssertEqualObjects(optUnmanaged.dataObj[1], NSNull.null);
    XCTAssertEqualObjects(optUnmanaged.dateObj[1], NSNull.null);
    XCTAssertEqualObjects(optManaged.boolObj[1], NSNull.null);
    XCTAssertEqualObjects(optManaged.intObj[1], NSNull.null);
    XCTAssertEqualObjects(optManaged.floatObj[1], NSNull.null);
    XCTAssertEqualObjects(optManaged.doubleObj[1], NSNull.null);
    XCTAssertEqualObjects(optManaged.stringObj[1], NSNull.null);
    XCTAssertEqualObjects(optManaged.dataObj[1], NSNull.null);
    XCTAssertEqualObjects(optManaged.dateObj[1], NSNull.null);
    XCTAssertEqualObjects(optUnmanaged.boolObj[2], @NO);
    XCTAssertEqualObjects(optUnmanaged.intObj[2], @2);
    XCTAssertEqualObjects(optUnmanaged.floatObj[2], @2.2f);
    XCTAssertEqualObjects(optUnmanaged.doubleObj[2], @2.2);
    XCTAssertEqualObjects(optUnmanaged.stringObj[2], @"a");
    XCTAssertEqualObjects(optUnmanaged.dataObj[2], data(1));
    XCTAssertEqualObjects(optUnmanaged.dateObj[2], date(1));
    XCTAssertEqualObjects(optManaged.boolObj[2], @NO);
    XCTAssertEqualObjects(optManaged.intObj[2], @2);
    XCTAssertEqualObjects(optManaged.floatObj[2], @2.2f);
    XCTAssertEqualObjects(optManaged.doubleObj[2], @2.2);
    XCTAssertEqualObjects(optManaged.stringObj[2], @"a");
    XCTAssertEqualObjects(optManaged.dataObj[2], data(1));
    XCTAssertEqualObjects(optManaged.dateObj[2], date(1));
}

- (void)testRemoveObject {
    RLMAssertThrowsWithReason([unmanaged.boolObj removeObjectAtIndex:0],
                              @"Index 0 is out of bounds (must be less than 0).");
    RLMAssertThrowsWithReason([unmanaged.intObj removeObjectAtIndex:0],
                              @"Index 0 is out of bounds (must be less than 0).");
    RLMAssertThrowsWithReason([unmanaged.floatObj removeObjectAtIndex:0],
                              @"Index 0 is out of bounds (must be less than 0).");
    RLMAssertThrowsWithReason([unmanaged.doubleObj removeObjectAtIndex:0],
                              @"Index 0 is out of bounds (must be less than 0).");
    RLMAssertThrowsWithReason([unmanaged.stringObj removeObjectAtIndex:0],
                              @"Index 0 is out of bounds (must be less than 0).");
    RLMAssertThrowsWithReason([unmanaged.dataObj removeObjectAtIndex:0],
                              @"Index 0 is out of bounds (must be less than 0).");
    RLMAssertThrowsWithReason([unmanaged.dateObj removeObjectAtIndex:0],
                              @"Index 0 is out of bounds (must be less than 0).");
    RLMAssertThrowsWithReason([optUnmanaged.boolObj removeObjectAtIndex:0],
                              @"Index 0 is out of bounds (must be less than 0).");
    RLMAssertThrowsWithReason([optUnmanaged.intObj removeObjectAtIndex:0],
                              @"Index 0 is out of bounds (must be less than 0).");
    RLMAssertThrowsWithReason([optUnmanaged.floatObj removeObjectAtIndex:0],
                              @"Index 0 is out of bounds (must be less than 0).");
    RLMAssertThrowsWithReason([optUnmanaged.doubleObj removeObjectAtIndex:0],
                              @"Index 0 is out of bounds (must be less than 0).");
    RLMAssertThrowsWithReason([optUnmanaged.stringObj removeObjectAtIndex:0],
                              @"Index 0 is out of bounds (must be less than 0).");
    RLMAssertThrowsWithReason([optUnmanaged.dataObj removeObjectAtIndex:0],
                              @"Index 0 is out of bounds (must be less than 0).");
    RLMAssertThrowsWithReason([optUnmanaged.dateObj removeObjectAtIndex:0],
                              @"Index 0 is out of bounds (must be less than 0).");
    RLMAssertThrowsWithReason([managed.boolObj removeObjectAtIndex:0],
                              @"Index 0 is out of bounds (must be less than 0).");
    RLMAssertThrowsWithReason([managed.intObj removeObjectAtIndex:0],
                              @"Index 0 is out of bounds (must be less than 0).");
    RLMAssertThrowsWithReason([managed.floatObj removeObjectAtIndex:0],
                              @"Index 0 is out of bounds (must be less than 0).");
    RLMAssertThrowsWithReason([managed.doubleObj removeObjectAtIndex:0],
                              @"Index 0 is out of bounds (must be less than 0).");
    RLMAssertThrowsWithReason([managed.stringObj removeObjectAtIndex:0],
                              @"Index 0 is out of bounds (must be less than 0).");
    RLMAssertThrowsWithReason([managed.dataObj removeObjectAtIndex:0],
                              @"Index 0 is out of bounds (must be less than 0).");
    RLMAssertThrowsWithReason([managed.dateObj removeObjectAtIndex:0],
                              @"Index 0 is out of bounds (must be less than 0).");
    RLMAssertThrowsWithReason([optManaged.boolObj removeObjectAtIndex:0],
                              @"Index 0 is out of bounds (must be less than 0).");
    RLMAssertThrowsWithReason([optManaged.intObj removeObjectAtIndex:0],
                              @"Index 0 is out of bounds (must be less than 0).");
    RLMAssertThrowsWithReason([optManaged.floatObj removeObjectAtIndex:0],
                              @"Index 0 is out of bounds (must be less than 0).");
    RLMAssertThrowsWithReason([optManaged.doubleObj removeObjectAtIndex:0],
                              @"Index 0 is out of bounds (must be less than 0).");
    RLMAssertThrowsWithReason([optManaged.stringObj removeObjectAtIndex:0],
                              @"Index 0 is out of bounds (must be less than 0).");
    RLMAssertThrowsWithReason([optManaged.dataObj removeObjectAtIndex:0],
                              @"Index 0 is out of bounds (must be less than 0).");
    RLMAssertThrowsWithReason([optManaged.dateObj removeObjectAtIndex:0],
                              @"Index 0 is out of bounds (must be less than 0).");

    [unmanaged.boolObj addObjects:@[@NO, @YES]];
    [unmanaged.intObj addObjects:@[@2, @3]];
    [unmanaged.floatObj addObjects:@[@2.2f, @3.3f]];
    [unmanaged.doubleObj addObjects:@[@2.2, @3.3]];
    [unmanaged.stringObj addObjects:@[@"a", @"b"]];
    [unmanaged.dataObj addObjects:@[data(1), data(2)]];
    [unmanaged.dateObj addObjects:@[date(1), date(2)]];
    [optUnmanaged.boolObj addObjects:@[@NO, @YES, NSNull.null]];
    [optUnmanaged.intObj addObjects:@[@2, @3, NSNull.null]];
    [optUnmanaged.floatObj addObjects:@[@2.2f, @3.3f, NSNull.null]];
    [optUnmanaged.doubleObj addObjects:@[@2.2, @3.3, NSNull.null]];
    [optUnmanaged.stringObj addObjects:@[@"a", @"b", NSNull.null]];
    [optUnmanaged.dataObj addObjects:@[data(1), data(2), NSNull.null]];
    [optUnmanaged.dateObj addObjects:@[date(1), date(2), NSNull.null]];
    [managed.boolObj addObjects:@[@NO, @YES]];
    [managed.intObj addObjects:@[@2, @3]];
    [managed.floatObj addObjects:@[@2.2f, @3.3f]];
    [managed.doubleObj addObjects:@[@2.2, @3.3]];
    [managed.stringObj addObjects:@[@"a", @"b"]];
    [managed.dataObj addObjects:@[data(1), data(2)]];
    [managed.dateObj addObjects:@[date(1), date(2)]];
    [optManaged.boolObj addObjects:@[@NO, @YES, NSNull.null]];
    [optManaged.intObj addObjects:@[@2, @3, NSNull.null]];
    [optManaged.floatObj addObjects:@[@2.2f, @3.3f, NSNull.null]];
    [optManaged.doubleObj addObjects:@[@2.2, @3.3, NSNull.null]];
    [optManaged.stringObj addObjects:@[@"a", @"b", NSNull.null]];
    [optManaged.dataObj addObjects:@[data(1), data(2), NSNull.null]];
    [optManaged.dateObj addObjects:@[date(1), date(2), NSNull.null]];
    XCTAssertEqual(unmanaged.boolObj.count, 2U);
    XCTAssertEqual(unmanaged.intObj.count, 2U);
    XCTAssertEqual(unmanaged.floatObj.count, 2U);
    XCTAssertEqual(unmanaged.doubleObj.count, 2U);
    XCTAssertEqual(unmanaged.stringObj.count, 2U);
    XCTAssertEqual(unmanaged.dataObj.count, 2U);
    XCTAssertEqual(unmanaged.dateObj.count, 2U);
    XCTAssertEqual(managed.boolObj.count, 2U);
    XCTAssertEqual(managed.intObj.count, 2U);
    XCTAssertEqual(managed.floatObj.count, 2U);
    XCTAssertEqual(managed.doubleObj.count, 2U);
    XCTAssertEqual(managed.stringObj.count, 2U);
    XCTAssertEqual(managed.dataObj.count, 2U);
    XCTAssertEqual(managed.dateObj.count, 2U);
    XCTAssertEqual(optUnmanaged.boolObj.count, 3U);
    XCTAssertEqual(optUnmanaged.intObj.count, 3U);
    XCTAssertEqual(optUnmanaged.floatObj.count, 3U);
    XCTAssertEqual(optUnmanaged.doubleObj.count, 3U);
    XCTAssertEqual(optUnmanaged.stringObj.count, 3U);
    XCTAssertEqual(optUnmanaged.dataObj.count, 3U);
    XCTAssertEqual(optUnmanaged.dateObj.count, 3U);
    XCTAssertEqual(optManaged.boolObj.count, 3U);
    XCTAssertEqual(optManaged.intObj.count, 3U);
    XCTAssertEqual(optManaged.floatObj.count, 3U);
    XCTAssertEqual(optManaged.doubleObj.count, 3U);
    XCTAssertEqual(optManaged.stringObj.count, 3U);
    XCTAssertEqual(optManaged.dataObj.count, 3U);
    XCTAssertEqual(optManaged.dateObj.count, 3U);

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

    [unmanaged.boolObj removeObjectAtIndex:0];
    [unmanaged.intObj removeObjectAtIndex:0];
    [unmanaged.floatObj removeObjectAtIndex:0];
    [unmanaged.doubleObj removeObjectAtIndex:0];
    [unmanaged.stringObj removeObjectAtIndex:0];
    [unmanaged.dataObj removeObjectAtIndex:0];
    [unmanaged.dateObj removeObjectAtIndex:0];
    [optUnmanaged.boolObj removeObjectAtIndex:0];
    [optUnmanaged.intObj removeObjectAtIndex:0];
    [optUnmanaged.floatObj removeObjectAtIndex:0];
    [optUnmanaged.doubleObj removeObjectAtIndex:0];
    [optUnmanaged.stringObj removeObjectAtIndex:0];
    [optUnmanaged.dataObj removeObjectAtIndex:0];
    [optUnmanaged.dateObj removeObjectAtIndex:0];
    [managed.boolObj removeObjectAtIndex:0];
    [managed.intObj removeObjectAtIndex:0];
    [managed.floatObj removeObjectAtIndex:0];
    [managed.doubleObj removeObjectAtIndex:0];
    [managed.stringObj removeObjectAtIndex:0];
    [managed.dataObj removeObjectAtIndex:0];
    [managed.dateObj removeObjectAtIndex:0];
    [optManaged.boolObj removeObjectAtIndex:0];
    [optManaged.intObj removeObjectAtIndex:0];
    [optManaged.floatObj removeObjectAtIndex:0];
    [optManaged.doubleObj removeObjectAtIndex:0];
    [optManaged.stringObj removeObjectAtIndex:0];
    [optManaged.dataObj removeObjectAtIndex:0];
    [optManaged.dateObj removeObjectAtIndex:0];
    XCTAssertEqual(unmanaged.boolObj.count, 1U);
    XCTAssertEqual(unmanaged.intObj.count, 1U);
    XCTAssertEqual(unmanaged.floatObj.count, 1U);
    XCTAssertEqual(unmanaged.doubleObj.count, 1U);
    XCTAssertEqual(unmanaged.stringObj.count, 1U);
    XCTAssertEqual(unmanaged.dataObj.count, 1U);
    XCTAssertEqual(unmanaged.dateObj.count, 1U);
    XCTAssertEqual(managed.boolObj.count, 1U);
    XCTAssertEqual(managed.intObj.count, 1U);
    XCTAssertEqual(managed.floatObj.count, 1U);
    XCTAssertEqual(managed.doubleObj.count, 1U);
    XCTAssertEqual(managed.stringObj.count, 1U);
    XCTAssertEqual(managed.dataObj.count, 1U);
    XCTAssertEqual(managed.dateObj.count, 1U);
    XCTAssertEqual(optUnmanaged.boolObj.count, 2U);
    XCTAssertEqual(optUnmanaged.intObj.count, 2U);
    XCTAssertEqual(optUnmanaged.floatObj.count, 2U);
    XCTAssertEqual(optUnmanaged.doubleObj.count, 2U);
    XCTAssertEqual(optUnmanaged.stringObj.count, 2U);
    XCTAssertEqual(optUnmanaged.dataObj.count, 2U);
    XCTAssertEqual(optUnmanaged.dateObj.count, 2U);
    XCTAssertEqual(optManaged.boolObj.count, 2U);
    XCTAssertEqual(optManaged.intObj.count, 2U);
    XCTAssertEqual(optManaged.floatObj.count, 2U);
    XCTAssertEqual(optManaged.doubleObj.count, 2U);
    XCTAssertEqual(optManaged.stringObj.count, 2U);
    XCTAssertEqual(optManaged.dataObj.count, 2U);
    XCTAssertEqual(optManaged.dateObj.count, 2U);

    XCTAssertEqualObjects(unmanaged.boolObj[0], @YES);
    XCTAssertEqualObjects(unmanaged.intObj[0], @3);
    XCTAssertEqualObjects(unmanaged.floatObj[0], @3.3f);
    XCTAssertEqualObjects(unmanaged.doubleObj[0], @3.3);
    XCTAssertEqualObjects(unmanaged.stringObj[0], @"b");
    XCTAssertEqualObjects(unmanaged.dataObj[0], data(2));
    XCTAssertEqualObjects(unmanaged.dateObj[0], date(2));
    XCTAssertEqualObjects(optUnmanaged.boolObj[0], @YES);
    XCTAssertEqualObjects(optUnmanaged.intObj[0], @3);
    XCTAssertEqualObjects(optUnmanaged.floatObj[0], @3.3f);
    XCTAssertEqualObjects(optUnmanaged.doubleObj[0], @3.3);
    XCTAssertEqualObjects(optUnmanaged.stringObj[0], @"b");
    XCTAssertEqualObjects(optUnmanaged.dataObj[0], data(2));
    XCTAssertEqualObjects(optUnmanaged.dateObj[0], date(2));
    XCTAssertEqualObjects(managed.boolObj[0], @YES);
    XCTAssertEqualObjects(managed.intObj[0], @3);
    XCTAssertEqualObjects(managed.floatObj[0], @3.3f);
    XCTAssertEqualObjects(managed.doubleObj[0], @3.3);
    XCTAssertEqualObjects(managed.stringObj[0], @"b");
    XCTAssertEqualObjects(managed.dataObj[0], data(2));
    XCTAssertEqualObjects(managed.dateObj[0], date(2));
    XCTAssertEqualObjects(optManaged.boolObj[0], @YES);
    XCTAssertEqualObjects(optManaged.intObj[0], @3);
    XCTAssertEqualObjects(optManaged.floatObj[0], @3.3f);
    XCTAssertEqualObjects(optManaged.doubleObj[0], @3.3);
    XCTAssertEqualObjects(optManaged.stringObj[0], @"b");
    XCTAssertEqualObjects(optManaged.dataObj[0], data(2));
    XCTAssertEqualObjects(optManaged.dateObj[0], date(2));
    XCTAssertEqualObjects(optUnmanaged.boolObj[1], NSNull.null);
    XCTAssertEqualObjects(optUnmanaged.intObj[1], NSNull.null);
    XCTAssertEqualObjects(optUnmanaged.floatObj[1], NSNull.null);
    XCTAssertEqualObjects(optUnmanaged.doubleObj[1], NSNull.null);
    XCTAssertEqualObjects(optUnmanaged.stringObj[1], NSNull.null);
    XCTAssertEqualObjects(optUnmanaged.dataObj[1], NSNull.null);
    XCTAssertEqualObjects(optUnmanaged.dateObj[1], NSNull.null);
    XCTAssertEqualObjects(optManaged.boolObj[1], NSNull.null);
    XCTAssertEqualObjects(optManaged.intObj[1], NSNull.null);
    XCTAssertEqualObjects(optManaged.floatObj[1], NSNull.null);
    XCTAssertEqualObjects(optManaged.doubleObj[1], NSNull.null);
    XCTAssertEqualObjects(optManaged.stringObj[1], NSNull.null);
    XCTAssertEqualObjects(optManaged.dataObj[1], NSNull.null);
    XCTAssertEqualObjects(optManaged.dateObj[1], NSNull.null);
}

- (void)testRemoveLastObject {
    XCTAssertNoThrow([unmanaged.boolObj removeLastObject]);
    XCTAssertNoThrow([unmanaged.intObj removeLastObject]);
    XCTAssertNoThrow([unmanaged.floatObj removeLastObject]);
    XCTAssertNoThrow([unmanaged.doubleObj removeLastObject]);
    XCTAssertNoThrow([unmanaged.stringObj removeLastObject]);
    XCTAssertNoThrow([unmanaged.dataObj removeLastObject]);
    XCTAssertNoThrow([unmanaged.dateObj removeLastObject]);
    XCTAssertNoThrow([optUnmanaged.boolObj removeLastObject]);
    XCTAssertNoThrow([optUnmanaged.intObj removeLastObject]);
    XCTAssertNoThrow([optUnmanaged.floatObj removeLastObject]);
    XCTAssertNoThrow([optUnmanaged.doubleObj removeLastObject]);
    XCTAssertNoThrow([optUnmanaged.stringObj removeLastObject]);
    XCTAssertNoThrow([optUnmanaged.dataObj removeLastObject]);
    XCTAssertNoThrow([optUnmanaged.dateObj removeLastObject]);
    XCTAssertNoThrow([managed.boolObj removeLastObject]);
    XCTAssertNoThrow([managed.intObj removeLastObject]);
    XCTAssertNoThrow([managed.floatObj removeLastObject]);
    XCTAssertNoThrow([managed.doubleObj removeLastObject]);
    XCTAssertNoThrow([managed.stringObj removeLastObject]);
    XCTAssertNoThrow([managed.dataObj removeLastObject]);
    XCTAssertNoThrow([managed.dateObj removeLastObject]);
    XCTAssertNoThrow([optManaged.boolObj removeLastObject]);
    XCTAssertNoThrow([optManaged.intObj removeLastObject]);
    XCTAssertNoThrow([optManaged.floatObj removeLastObject]);
    XCTAssertNoThrow([optManaged.doubleObj removeLastObject]);
    XCTAssertNoThrow([optManaged.stringObj removeLastObject]);
    XCTAssertNoThrow([optManaged.dataObj removeLastObject]);
    XCTAssertNoThrow([optManaged.dateObj removeLastObject]);

    [unmanaged.boolObj addObjects:@[@NO, @YES]];
    [unmanaged.intObj addObjects:@[@2, @3]];
    [unmanaged.floatObj addObjects:@[@2.2f, @3.3f]];
    [unmanaged.doubleObj addObjects:@[@2.2, @3.3]];
    [unmanaged.stringObj addObjects:@[@"a", @"b"]];
    [unmanaged.dataObj addObjects:@[data(1), data(2)]];
    [unmanaged.dateObj addObjects:@[date(1), date(2)]];
    [optUnmanaged.boolObj addObjects:@[@NO, @YES, NSNull.null]];
    [optUnmanaged.intObj addObjects:@[@2, @3, NSNull.null]];
    [optUnmanaged.floatObj addObjects:@[@2.2f, @3.3f, NSNull.null]];
    [optUnmanaged.doubleObj addObjects:@[@2.2, @3.3, NSNull.null]];
    [optUnmanaged.stringObj addObjects:@[@"a", @"b", NSNull.null]];
    [optUnmanaged.dataObj addObjects:@[data(1), data(2), NSNull.null]];
    [optUnmanaged.dateObj addObjects:@[date(1), date(2), NSNull.null]];
    [managed.boolObj addObjects:@[@NO, @YES]];
    [managed.intObj addObjects:@[@2, @3]];
    [managed.floatObj addObjects:@[@2.2f, @3.3f]];
    [managed.doubleObj addObjects:@[@2.2, @3.3]];
    [managed.stringObj addObjects:@[@"a", @"b"]];
    [managed.dataObj addObjects:@[data(1), data(2)]];
    [managed.dateObj addObjects:@[date(1), date(2)]];
    [optManaged.boolObj addObjects:@[@NO, @YES, NSNull.null]];
    [optManaged.intObj addObjects:@[@2, @3, NSNull.null]];
    [optManaged.floatObj addObjects:@[@2.2f, @3.3f, NSNull.null]];
    [optManaged.doubleObj addObjects:@[@2.2, @3.3, NSNull.null]];
    [optManaged.stringObj addObjects:@[@"a", @"b", NSNull.null]];
    [optManaged.dataObj addObjects:@[data(1), data(2), NSNull.null]];
    [optManaged.dateObj addObjects:@[date(1), date(2), NSNull.null]];
    XCTAssertEqual(unmanaged.boolObj.count, 2U);
    XCTAssertEqual(unmanaged.intObj.count, 2U);
    XCTAssertEqual(unmanaged.floatObj.count, 2U);
    XCTAssertEqual(unmanaged.doubleObj.count, 2U);
    XCTAssertEqual(unmanaged.stringObj.count, 2U);
    XCTAssertEqual(unmanaged.dataObj.count, 2U);
    XCTAssertEqual(unmanaged.dateObj.count, 2U);
    XCTAssertEqual(managed.boolObj.count, 2U);
    XCTAssertEqual(managed.intObj.count, 2U);
    XCTAssertEqual(managed.floatObj.count, 2U);
    XCTAssertEqual(managed.doubleObj.count, 2U);
    XCTAssertEqual(managed.stringObj.count, 2U);
    XCTAssertEqual(managed.dataObj.count, 2U);
    XCTAssertEqual(managed.dateObj.count, 2U);
    XCTAssertEqual(optUnmanaged.boolObj.count, 3U);
    XCTAssertEqual(optUnmanaged.intObj.count, 3U);
    XCTAssertEqual(optUnmanaged.floatObj.count, 3U);
    XCTAssertEqual(optUnmanaged.doubleObj.count, 3U);
    XCTAssertEqual(optUnmanaged.stringObj.count, 3U);
    XCTAssertEqual(optUnmanaged.dataObj.count, 3U);
    XCTAssertEqual(optUnmanaged.dateObj.count, 3U);
    XCTAssertEqual(optManaged.boolObj.count, 3U);
    XCTAssertEqual(optManaged.intObj.count, 3U);
    XCTAssertEqual(optManaged.floatObj.count, 3U);
    XCTAssertEqual(optManaged.doubleObj.count, 3U);
    XCTAssertEqual(optManaged.stringObj.count, 3U);
    XCTAssertEqual(optManaged.dataObj.count, 3U);
    XCTAssertEqual(optManaged.dateObj.count, 3U);

    [unmanaged.boolObj removeLastObject];
    [unmanaged.intObj removeLastObject];
    [unmanaged.floatObj removeLastObject];
    [unmanaged.doubleObj removeLastObject];
    [unmanaged.stringObj removeLastObject];
    [unmanaged.dataObj removeLastObject];
    [unmanaged.dateObj removeLastObject];
    [optUnmanaged.boolObj removeLastObject];
    [optUnmanaged.intObj removeLastObject];
    [optUnmanaged.floatObj removeLastObject];
    [optUnmanaged.doubleObj removeLastObject];
    [optUnmanaged.stringObj removeLastObject];
    [optUnmanaged.dataObj removeLastObject];
    [optUnmanaged.dateObj removeLastObject];
    [managed.boolObj removeLastObject];
    [managed.intObj removeLastObject];
    [managed.floatObj removeLastObject];
    [managed.doubleObj removeLastObject];
    [managed.stringObj removeLastObject];
    [managed.dataObj removeLastObject];
    [managed.dateObj removeLastObject];
    [optManaged.boolObj removeLastObject];
    [optManaged.intObj removeLastObject];
    [optManaged.floatObj removeLastObject];
    [optManaged.doubleObj removeLastObject];
    [optManaged.stringObj removeLastObject];
    [optManaged.dataObj removeLastObject];
    [optManaged.dateObj removeLastObject];
    XCTAssertEqual(unmanaged.boolObj.count, 1U);
    XCTAssertEqual(unmanaged.intObj.count, 1U);
    XCTAssertEqual(unmanaged.floatObj.count, 1U);
    XCTAssertEqual(unmanaged.doubleObj.count, 1U);
    XCTAssertEqual(unmanaged.stringObj.count, 1U);
    XCTAssertEqual(unmanaged.dataObj.count, 1U);
    XCTAssertEqual(unmanaged.dateObj.count, 1U);
    XCTAssertEqual(managed.boolObj.count, 1U);
    XCTAssertEqual(managed.intObj.count, 1U);
    XCTAssertEqual(managed.floatObj.count, 1U);
    XCTAssertEqual(managed.doubleObj.count, 1U);
    XCTAssertEqual(managed.stringObj.count, 1U);
    XCTAssertEqual(managed.dataObj.count, 1U);
    XCTAssertEqual(managed.dateObj.count, 1U);
    XCTAssertEqual(optUnmanaged.boolObj.count, 2U);
    XCTAssertEqual(optUnmanaged.intObj.count, 2U);
    XCTAssertEqual(optUnmanaged.floatObj.count, 2U);
    XCTAssertEqual(optUnmanaged.doubleObj.count, 2U);
    XCTAssertEqual(optUnmanaged.stringObj.count, 2U);
    XCTAssertEqual(optUnmanaged.dataObj.count, 2U);
    XCTAssertEqual(optUnmanaged.dateObj.count, 2U);
    XCTAssertEqual(optManaged.boolObj.count, 2U);
    XCTAssertEqual(optManaged.intObj.count, 2U);
    XCTAssertEqual(optManaged.floatObj.count, 2U);
    XCTAssertEqual(optManaged.doubleObj.count, 2U);
    XCTAssertEqual(optManaged.stringObj.count, 2U);
    XCTAssertEqual(optManaged.dataObj.count, 2U);
    XCTAssertEqual(optManaged.dateObj.count, 2U);

    XCTAssertEqualObjects(unmanaged.boolObj[0], @NO);
    XCTAssertEqualObjects(unmanaged.intObj[0], @2);
    XCTAssertEqualObjects(unmanaged.floatObj[0], @2.2f);
    XCTAssertEqualObjects(unmanaged.doubleObj[0], @2.2);
    XCTAssertEqualObjects(unmanaged.stringObj[0], @"a");
    XCTAssertEqualObjects(unmanaged.dataObj[0], data(1));
    XCTAssertEqualObjects(unmanaged.dateObj[0], date(1));
    XCTAssertEqualObjects(optUnmanaged.boolObj[0], @NO);
    XCTAssertEqualObjects(optUnmanaged.intObj[0], @2);
    XCTAssertEqualObjects(optUnmanaged.floatObj[0], @2.2f);
    XCTAssertEqualObjects(optUnmanaged.doubleObj[0], @2.2);
    XCTAssertEqualObjects(optUnmanaged.stringObj[0], @"a");
    XCTAssertEqualObjects(optUnmanaged.dataObj[0], data(1));
    XCTAssertEqualObjects(optUnmanaged.dateObj[0], date(1));
    XCTAssertEqualObjects(managed.boolObj[0], @NO);
    XCTAssertEqualObjects(managed.intObj[0], @2);
    XCTAssertEqualObjects(managed.floatObj[0], @2.2f);
    XCTAssertEqualObjects(managed.doubleObj[0], @2.2);
    XCTAssertEqualObjects(managed.stringObj[0], @"a");
    XCTAssertEqualObjects(managed.dataObj[0], data(1));
    XCTAssertEqualObjects(managed.dateObj[0], date(1));
    XCTAssertEqualObjects(optManaged.boolObj[0], @NO);
    XCTAssertEqualObjects(optManaged.intObj[0], @2);
    XCTAssertEqualObjects(optManaged.floatObj[0], @2.2f);
    XCTAssertEqualObjects(optManaged.doubleObj[0], @2.2);
    XCTAssertEqualObjects(optManaged.stringObj[0], @"a");
    XCTAssertEqualObjects(optManaged.dataObj[0], data(1));
    XCTAssertEqualObjects(optManaged.dateObj[0], date(1));
    XCTAssertEqualObjects(optUnmanaged.boolObj[1], @YES);
    XCTAssertEqualObjects(optUnmanaged.intObj[1], @3);
    XCTAssertEqualObjects(optUnmanaged.floatObj[1], @3.3f);
    XCTAssertEqualObjects(optUnmanaged.doubleObj[1], @3.3);
    XCTAssertEqualObjects(optUnmanaged.stringObj[1], @"b");
    XCTAssertEqualObjects(optUnmanaged.dataObj[1], data(2));
    XCTAssertEqualObjects(optUnmanaged.dateObj[1], date(2));
    XCTAssertEqualObjects(optManaged.boolObj[1], @YES);
    XCTAssertEqualObjects(optManaged.intObj[1], @3);
    XCTAssertEqualObjects(optManaged.floatObj[1], @3.3f);
    XCTAssertEqualObjects(optManaged.doubleObj[1], @3.3);
    XCTAssertEqualObjects(optManaged.stringObj[1], @"b");
    XCTAssertEqualObjects(optManaged.dataObj[1], data(2));
    XCTAssertEqualObjects(optManaged.dateObj[1], date(2));
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
}

- (void)testMove {
    RLMAssertThrowsWithReason([unmanaged.boolObj moveObjectAtIndex:0 toIndex:1],
                              @"Index 0 is out of bounds (must be less than 0).");
    RLMAssertThrowsWithReason([unmanaged.intObj moveObjectAtIndex:0 toIndex:1],
                              @"Index 0 is out of bounds (must be less than 0).");
    RLMAssertThrowsWithReason([unmanaged.floatObj moveObjectAtIndex:0 toIndex:1],
                              @"Index 0 is out of bounds (must be less than 0).");
    RLMAssertThrowsWithReason([unmanaged.doubleObj moveObjectAtIndex:0 toIndex:1],
                              @"Index 0 is out of bounds (must be less than 0).");
    RLMAssertThrowsWithReason([unmanaged.stringObj moveObjectAtIndex:0 toIndex:1],
                              @"Index 0 is out of bounds (must be less than 0).");
    RLMAssertThrowsWithReason([unmanaged.dataObj moveObjectAtIndex:0 toIndex:1],
                              @"Index 0 is out of bounds (must be less than 0).");
    RLMAssertThrowsWithReason([unmanaged.dateObj moveObjectAtIndex:0 toIndex:1],
                              @"Index 0 is out of bounds (must be less than 0).");
    RLMAssertThrowsWithReason([optUnmanaged.boolObj moveObjectAtIndex:0 toIndex:1],
                              @"Index 0 is out of bounds (must be less than 0).");
    RLMAssertThrowsWithReason([optUnmanaged.intObj moveObjectAtIndex:0 toIndex:1],
                              @"Index 0 is out of bounds (must be less than 0).");
    RLMAssertThrowsWithReason([optUnmanaged.floatObj moveObjectAtIndex:0 toIndex:1],
                              @"Index 0 is out of bounds (must be less than 0).");
    RLMAssertThrowsWithReason([optUnmanaged.doubleObj moveObjectAtIndex:0 toIndex:1],
                              @"Index 0 is out of bounds (must be less than 0).");
    RLMAssertThrowsWithReason([optUnmanaged.stringObj moveObjectAtIndex:0 toIndex:1],
                              @"Index 0 is out of bounds (must be less than 0).");
    RLMAssertThrowsWithReason([optUnmanaged.dataObj moveObjectAtIndex:0 toIndex:1],
                              @"Index 0 is out of bounds (must be less than 0).");
    RLMAssertThrowsWithReason([optUnmanaged.dateObj moveObjectAtIndex:0 toIndex:1],
                              @"Index 0 is out of bounds (must be less than 0).");
    RLMAssertThrowsWithReason([managed.boolObj moveObjectAtIndex:0 toIndex:1],
                              @"Index 0 is out of bounds (must be less than 0).");
    RLMAssertThrowsWithReason([managed.intObj moveObjectAtIndex:0 toIndex:1],
                              @"Index 0 is out of bounds (must be less than 0).");
    RLMAssertThrowsWithReason([managed.floatObj moveObjectAtIndex:0 toIndex:1],
                              @"Index 0 is out of bounds (must be less than 0).");
    RLMAssertThrowsWithReason([managed.doubleObj moveObjectAtIndex:0 toIndex:1],
                              @"Index 0 is out of bounds (must be less than 0).");
    RLMAssertThrowsWithReason([managed.stringObj moveObjectAtIndex:0 toIndex:1],
                              @"Index 0 is out of bounds (must be less than 0).");
    RLMAssertThrowsWithReason([managed.dataObj moveObjectAtIndex:0 toIndex:1],
                              @"Index 0 is out of bounds (must be less than 0).");
    RLMAssertThrowsWithReason([managed.dateObj moveObjectAtIndex:0 toIndex:1],
                              @"Index 0 is out of bounds (must be less than 0).");
    RLMAssertThrowsWithReason([optManaged.boolObj moveObjectAtIndex:0 toIndex:1],
                              @"Index 0 is out of bounds (must be less than 0).");
    RLMAssertThrowsWithReason([optManaged.intObj moveObjectAtIndex:0 toIndex:1],
                              @"Index 0 is out of bounds (must be less than 0).");
    RLMAssertThrowsWithReason([optManaged.floatObj moveObjectAtIndex:0 toIndex:1],
                              @"Index 0 is out of bounds (must be less than 0).");
    RLMAssertThrowsWithReason([optManaged.doubleObj moveObjectAtIndex:0 toIndex:1],
                              @"Index 0 is out of bounds (must be less than 0).");
    RLMAssertThrowsWithReason([optManaged.stringObj moveObjectAtIndex:0 toIndex:1],
                              @"Index 0 is out of bounds (must be less than 0).");
    RLMAssertThrowsWithReason([optManaged.dataObj moveObjectAtIndex:0 toIndex:1],
                              @"Index 0 is out of bounds (must be less than 0).");
    RLMAssertThrowsWithReason([optManaged.dateObj moveObjectAtIndex:0 toIndex:1],
                              @"Index 0 is out of bounds (must be less than 0).");
    RLMAssertThrowsWithReason([unmanaged.boolObj moveObjectAtIndex:1 toIndex:0],
                              @"Index 1 is out of bounds (must be less than 0).");
    RLMAssertThrowsWithReason([unmanaged.intObj moveObjectAtIndex:1 toIndex:0],
                              @"Index 1 is out of bounds (must be less than 0).");
    RLMAssertThrowsWithReason([unmanaged.floatObj moveObjectAtIndex:1 toIndex:0],
                              @"Index 1 is out of bounds (must be less than 0).");
    RLMAssertThrowsWithReason([unmanaged.doubleObj moveObjectAtIndex:1 toIndex:0],
                              @"Index 1 is out of bounds (must be less than 0).");
    RLMAssertThrowsWithReason([unmanaged.stringObj moveObjectAtIndex:1 toIndex:0],
                              @"Index 1 is out of bounds (must be less than 0).");
    RLMAssertThrowsWithReason([unmanaged.dataObj moveObjectAtIndex:1 toIndex:0],
                              @"Index 1 is out of bounds (must be less than 0).");
    RLMAssertThrowsWithReason([unmanaged.dateObj moveObjectAtIndex:1 toIndex:0],
                              @"Index 1 is out of bounds (must be less than 0).");
    RLMAssertThrowsWithReason([optUnmanaged.boolObj moveObjectAtIndex:1 toIndex:0],
                              @"Index 1 is out of bounds (must be less than 0).");
    RLMAssertThrowsWithReason([optUnmanaged.intObj moveObjectAtIndex:1 toIndex:0],
                              @"Index 1 is out of bounds (must be less than 0).");
    RLMAssertThrowsWithReason([optUnmanaged.floatObj moveObjectAtIndex:1 toIndex:0],
                              @"Index 1 is out of bounds (must be less than 0).");
    RLMAssertThrowsWithReason([optUnmanaged.doubleObj moveObjectAtIndex:1 toIndex:0],
                              @"Index 1 is out of bounds (must be less than 0).");
    RLMAssertThrowsWithReason([optUnmanaged.stringObj moveObjectAtIndex:1 toIndex:0],
                              @"Index 1 is out of bounds (must be less than 0).");
    RLMAssertThrowsWithReason([optUnmanaged.dataObj moveObjectAtIndex:1 toIndex:0],
                              @"Index 1 is out of bounds (must be less than 0).");
    RLMAssertThrowsWithReason([optUnmanaged.dateObj moveObjectAtIndex:1 toIndex:0],
                              @"Index 1 is out of bounds (must be less than 0).");
    RLMAssertThrowsWithReason([managed.boolObj moveObjectAtIndex:1 toIndex:0],
                              @"Index 1 is out of bounds (must be less than 0).");
    RLMAssertThrowsWithReason([managed.intObj moveObjectAtIndex:1 toIndex:0],
                              @"Index 1 is out of bounds (must be less than 0).");
    RLMAssertThrowsWithReason([managed.floatObj moveObjectAtIndex:1 toIndex:0],
                              @"Index 1 is out of bounds (must be less than 0).");
    RLMAssertThrowsWithReason([managed.doubleObj moveObjectAtIndex:1 toIndex:0],
                              @"Index 1 is out of bounds (must be less than 0).");
    RLMAssertThrowsWithReason([managed.stringObj moveObjectAtIndex:1 toIndex:0],
                              @"Index 1 is out of bounds (must be less than 0).");
    RLMAssertThrowsWithReason([managed.dataObj moveObjectAtIndex:1 toIndex:0],
                              @"Index 1 is out of bounds (must be less than 0).");
    RLMAssertThrowsWithReason([managed.dateObj moveObjectAtIndex:1 toIndex:0],
                              @"Index 1 is out of bounds (must be less than 0).");
    RLMAssertThrowsWithReason([optManaged.boolObj moveObjectAtIndex:1 toIndex:0],
                              @"Index 1 is out of bounds (must be less than 0).");
    RLMAssertThrowsWithReason([optManaged.intObj moveObjectAtIndex:1 toIndex:0],
                              @"Index 1 is out of bounds (must be less than 0).");
    RLMAssertThrowsWithReason([optManaged.floatObj moveObjectAtIndex:1 toIndex:0],
                              @"Index 1 is out of bounds (must be less than 0).");
    RLMAssertThrowsWithReason([optManaged.doubleObj moveObjectAtIndex:1 toIndex:0],
                              @"Index 1 is out of bounds (must be less than 0).");
    RLMAssertThrowsWithReason([optManaged.stringObj moveObjectAtIndex:1 toIndex:0],
                              @"Index 1 is out of bounds (must be less than 0).");
    RLMAssertThrowsWithReason([optManaged.dataObj moveObjectAtIndex:1 toIndex:0],
                              @"Index 1 is out of bounds (must be less than 0).");
    RLMAssertThrowsWithReason([optManaged.dateObj moveObjectAtIndex:1 toIndex:0],
                              @"Index 1 is out of bounds (must be less than 0).");

    [unmanaged.boolObj addObjects:@[@NO, @YES, @NO, @YES]];
    [unmanaged.intObj addObjects:@[@2, @3, @2, @3]];
    [unmanaged.floatObj addObjects:@[@2.2f, @3.3f, @2.2f, @3.3f]];
    [unmanaged.doubleObj addObjects:@[@2.2, @3.3, @2.2, @3.3]];
    [unmanaged.stringObj addObjects:@[@"a", @"b", @"a", @"b"]];
    [unmanaged.dataObj addObjects:@[data(1), data(2), data(1), data(2)]];
    [unmanaged.dateObj addObjects:@[date(1), date(2), date(1), date(2)]];
    [optUnmanaged.boolObj addObjects:@[@NO, @YES, @NO, @YES]];
    [optUnmanaged.intObj addObjects:@[@2, @3, @2, @3]];
    [optUnmanaged.floatObj addObjects:@[@2.2f, @3.3f, @2.2f, @3.3f]];
    [optUnmanaged.doubleObj addObjects:@[@2.2, @3.3, @2.2, @3.3]];
    [optUnmanaged.stringObj addObjects:@[@"a", @"b", @"a", @"b"]];
    [optUnmanaged.dataObj addObjects:@[data(1), data(2), data(1), data(2)]];
    [optUnmanaged.dateObj addObjects:@[date(1), date(2), date(1), date(2)]];
    [managed.boolObj addObjects:@[@NO, @YES, @NO, @YES]];
    [managed.intObj addObjects:@[@2, @3, @2, @3]];
    [managed.floatObj addObjects:@[@2.2f, @3.3f, @2.2f, @3.3f]];
    [managed.doubleObj addObjects:@[@2.2, @3.3, @2.2, @3.3]];
    [managed.stringObj addObjects:@[@"a", @"b", @"a", @"b"]];
    [managed.dataObj addObjects:@[data(1), data(2), data(1), data(2)]];
    [managed.dateObj addObjects:@[date(1), date(2), date(1), date(2)]];
    [optManaged.boolObj addObjects:@[@NO, @YES, @NO, @YES]];
    [optManaged.intObj addObjects:@[@2, @3, @2, @3]];
    [optManaged.floatObj addObjects:@[@2.2f, @3.3f, @2.2f, @3.3f]];
    [optManaged.doubleObj addObjects:@[@2.2, @3.3, @2.2, @3.3]];
    [optManaged.stringObj addObjects:@[@"a", @"b", @"a", @"b"]];
    [optManaged.dataObj addObjects:@[data(1), data(2), data(1), data(2)]];
    [optManaged.dateObj addObjects:@[date(1), date(2), date(1), date(2)]];

    [unmanaged.boolObj moveObjectAtIndex:2 toIndex:0];
    [unmanaged.intObj moveObjectAtIndex:2 toIndex:0];
    [unmanaged.floatObj moveObjectAtIndex:2 toIndex:0];
    [unmanaged.doubleObj moveObjectAtIndex:2 toIndex:0];
    [unmanaged.stringObj moveObjectAtIndex:2 toIndex:0];
    [unmanaged.dataObj moveObjectAtIndex:2 toIndex:0];
    [unmanaged.dateObj moveObjectAtIndex:2 toIndex:0];
    [optUnmanaged.boolObj moveObjectAtIndex:2 toIndex:0];
    [optUnmanaged.intObj moveObjectAtIndex:2 toIndex:0];
    [optUnmanaged.floatObj moveObjectAtIndex:2 toIndex:0];
    [optUnmanaged.doubleObj moveObjectAtIndex:2 toIndex:0];
    [optUnmanaged.stringObj moveObjectAtIndex:2 toIndex:0];
    [optUnmanaged.dataObj moveObjectAtIndex:2 toIndex:0];
    [optUnmanaged.dateObj moveObjectAtIndex:2 toIndex:0];
    [managed.boolObj moveObjectAtIndex:2 toIndex:0];
    [managed.intObj moveObjectAtIndex:2 toIndex:0];
    [managed.floatObj moveObjectAtIndex:2 toIndex:0];
    [managed.doubleObj moveObjectAtIndex:2 toIndex:0];
    [managed.stringObj moveObjectAtIndex:2 toIndex:0];
    [managed.dataObj moveObjectAtIndex:2 toIndex:0];
    [managed.dateObj moveObjectAtIndex:2 toIndex:0];
    [optManaged.boolObj moveObjectAtIndex:2 toIndex:0];
    [optManaged.intObj moveObjectAtIndex:2 toIndex:0];
    [optManaged.floatObj moveObjectAtIndex:2 toIndex:0];
    [optManaged.doubleObj moveObjectAtIndex:2 toIndex:0];
    [optManaged.stringObj moveObjectAtIndex:2 toIndex:0];
    [optManaged.dataObj moveObjectAtIndex:2 toIndex:0];
    [optManaged.dateObj moveObjectAtIndex:2 toIndex:0];

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
}

- (void)testExchange {
    RLMAssertThrowsWithReason([unmanaged.boolObj exchangeObjectAtIndex:0 withObjectAtIndex:1],
                              @"Index 0 is out of bounds (must be less than 0).");
    RLMAssertThrowsWithReason([unmanaged.intObj exchangeObjectAtIndex:0 withObjectAtIndex:1],
                              @"Index 0 is out of bounds (must be less than 0).");
    RLMAssertThrowsWithReason([unmanaged.floatObj exchangeObjectAtIndex:0 withObjectAtIndex:1],
                              @"Index 0 is out of bounds (must be less than 0).");
    RLMAssertThrowsWithReason([unmanaged.doubleObj exchangeObjectAtIndex:0 withObjectAtIndex:1],
                              @"Index 0 is out of bounds (must be less than 0).");
    RLMAssertThrowsWithReason([unmanaged.stringObj exchangeObjectAtIndex:0 withObjectAtIndex:1],
                              @"Index 0 is out of bounds (must be less than 0).");
    RLMAssertThrowsWithReason([unmanaged.dataObj exchangeObjectAtIndex:0 withObjectAtIndex:1],
                              @"Index 0 is out of bounds (must be less than 0).");
    RLMAssertThrowsWithReason([unmanaged.dateObj exchangeObjectAtIndex:0 withObjectAtIndex:1],
                              @"Index 0 is out of bounds (must be less than 0).");
    RLMAssertThrowsWithReason([optUnmanaged.boolObj exchangeObjectAtIndex:0 withObjectAtIndex:1],
                              @"Index 0 is out of bounds (must be less than 0).");
    RLMAssertThrowsWithReason([optUnmanaged.intObj exchangeObjectAtIndex:0 withObjectAtIndex:1],
                              @"Index 0 is out of bounds (must be less than 0).");
    RLMAssertThrowsWithReason([optUnmanaged.floatObj exchangeObjectAtIndex:0 withObjectAtIndex:1],
                              @"Index 0 is out of bounds (must be less than 0).");
    RLMAssertThrowsWithReason([optUnmanaged.doubleObj exchangeObjectAtIndex:0 withObjectAtIndex:1],
                              @"Index 0 is out of bounds (must be less than 0).");
    RLMAssertThrowsWithReason([optUnmanaged.stringObj exchangeObjectAtIndex:0 withObjectAtIndex:1],
                              @"Index 0 is out of bounds (must be less than 0).");
    RLMAssertThrowsWithReason([optUnmanaged.dataObj exchangeObjectAtIndex:0 withObjectAtIndex:1],
                              @"Index 0 is out of bounds (must be less than 0).");
    RLMAssertThrowsWithReason([optUnmanaged.dateObj exchangeObjectAtIndex:0 withObjectAtIndex:1],
                              @"Index 0 is out of bounds (must be less than 0).");
    RLMAssertThrowsWithReason([managed.boolObj exchangeObjectAtIndex:0 withObjectAtIndex:1],
                              @"Index 0 is out of bounds (must be less than 0).");
    RLMAssertThrowsWithReason([managed.intObj exchangeObjectAtIndex:0 withObjectAtIndex:1],
                              @"Index 0 is out of bounds (must be less than 0).");
    RLMAssertThrowsWithReason([managed.floatObj exchangeObjectAtIndex:0 withObjectAtIndex:1],
                              @"Index 0 is out of bounds (must be less than 0).");
    RLMAssertThrowsWithReason([managed.doubleObj exchangeObjectAtIndex:0 withObjectAtIndex:1],
                              @"Index 0 is out of bounds (must be less than 0).");
    RLMAssertThrowsWithReason([managed.stringObj exchangeObjectAtIndex:0 withObjectAtIndex:1],
                              @"Index 0 is out of bounds (must be less than 0).");
    RLMAssertThrowsWithReason([managed.dataObj exchangeObjectAtIndex:0 withObjectAtIndex:1],
                              @"Index 0 is out of bounds (must be less than 0).");
    RLMAssertThrowsWithReason([managed.dateObj exchangeObjectAtIndex:0 withObjectAtIndex:1],
                              @"Index 0 is out of bounds (must be less than 0).");
    RLMAssertThrowsWithReason([optManaged.boolObj exchangeObjectAtIndex:0 withObjectAtIndex:1],
                              @"Index 0 is out of bounds (must be less than 0).");
    RLMAssertThrowsWithReason([optManaged.intObj exchangeObjectAtIndex:0 withObjectAtIndex:1],
                              @"Index 0 is out of bounds (must be less than 0).");
    RLMAssertThrowsWithReason([optManaged.floatObj exchangeObjectAtIndex:0 withObjectAtIndex:1],
                              @"Index 0 is out of bounds (must be less than 0).");
    RLMAssertThrowsWithReason([optManaged.doubleObj exchangeObjectAtIndex:0 withObjectAtIndex:1],
                              @"Index 0 is out of bounds (must be less than 0).");
    RLMAssertThrowsWithReason([optManaged.stringObj exchangeObjectAtIndex:0 withObjectAtIndex:1],
                              @"Index 0 is out of bounds (must be less than 0).");
    RLMAssertThrowsWithReason([optManaged.dataObj exchangeObjectAtIndex:0 withObjectAtIndex:1],
                              @"Index 0 is out of bounds (must be less than 0).");
    RLMAssertThrowsWithReason([optManaged.dateObj exchangeObjectAtIndex:0 withObjectAtIndex:1],
                              @"Index 0 is out of bounds (must be less than 0).");
    RLMAssertThrowsWithReason([unmanaged.boolObj exchangeObjectAtIndex:1 withObjectAtIndex:0],
                              @"Index 1 is out of bounds (must be less than 0).");
    RLMAssertThrowsWithReason([unmanaged.intObj exchangeObjectAtIndex:1 withObjectAtIndex:0],
                              @"Index 1 is out of bounds (must be less than 0).");
    RLMAssertThrowsWithReason([unmanaged.floatObj exchangeObjectAtIndex:1 withObjectAtIndex:0],
                              @"Index 1 is out of bounds (must be less than 0).");
    RLMAssertThrowsWithReason([unmanaged.doubleObj exchangeObjectAtIndex:1 withObjectAtIndex:0],
                              @"Index 1 is out of bounds (must be less than 0).");
    RLMAssertThrowsWithReason([unmanaged.stringObj exchangeObjectAtIndex:1 withObjectAtIndex:0],
                              @"Index 1 is out of bounds (must be less than 0).");
    RLMAssertThrowsWithReason([unmanaged.dataObj exchangeObjectAtIndex:1 withObjectAtIndex:0],
                              @"Index 1 is out of bounds (must be less than 0).");
    RLMAssertThrowsWithReason([unmanaged.dateObj exchangeObjectAtIndex:1 withObjectAtIndex:0],
                              @"Index 1 is out of bounds (must be less than 0).");
    RLMAssertThrowsWithReason([optUnmanaged.boolObj exchangeObjectAtIndex:1 withObjectAtIndex:0],
                              @"Index 1 is out of bounds (must be less than 0).");
    RLMAssertThrowsWithReason([optUnmanaged.intObj exchangeObjectAtIndex:1 withObjectAtIndex:0],
                              @"Index 1 is out of bounds (must be less than 0).");
    RLMAssertThrowsWithReason([optUnmanaged.floatObj exchangeObjectAtIndex:1 withObjectAtIndex:0],
                              @"Index 1 is out of bounds (must be less than 0).");
    RLMAssertThrowsWithReason([optUnmanaged.doubleObj exchangeObjectAtIndex:1 withObjectAtIndex:0],
                              @"Index 1 is out of bounds (must be less than 0).");
    RLMAssertThrowsWithReason([optUnmanaged.stringObj exchangeObjectAtIndex:1 withObjectAtIndex:0],
                              @"Index 1 is out of bounds (must be less than 0).");
    RLMAssertThrowsWithReason([optUnmanaged.dataObj exchangeObjectAtIndex:1 withObjectAtIndex:0],
                              @"Index 1 is out of bounds (must be less than 0).");
    RLMAssertThrowsWithReason([optUnmanaged.dateObj exchangeObjectAtIndex:1 withObjectAtIndex:0],
                              @"Index 1 is out of bounds (must be less than 0).");
    RLMAssertThrowsWithReason([managed.boolObj exchangeObjectAtIndex:1 withObjectAtIndex:0],
                              @"Index 1 is out of bounds (must be less than 0).");
    RLMAssertThrowsWithReason([managed.intObj exchangeObjectAtIndex:1 withObjectAtIndex:0],
                              @"Index 1 is out of bounds (must be less than 0).");
    RLMAssertThrowsWithReason([managed.floatObj exchangeObjectAtIndex:1 withObjectAtIndex:0],
                              @"Index 1 is out of bounds (must be less than 0).");
    RLMAssertThrowsWithReason([managed.doubleObj exchangeObjectAtIndex:1 withObjectAtIndex:0],
                              @"Index 1 is out of bounds (must be less than 0).");
    RLMAssertThrowsWithReason([managed.stringObj exchangeObjectAtIndex:1 withObjectAtIndex:0],
                              @"Index 1 is out of bounds (must be less than 0).");
    RLMAssertThrowsWithReason([managed.dataObj exchangeObjectAtIndex:1 withObjectAtIndex:0],
                              @"Index 1 is out of bounds (must be less than 0).");
    RLMAssertThrowsWithReason([managed.dateObj exchangeObjectAtIndex:1 withObjectAtIndex:0],
                              @"Index 1 is out of bounds (must be less than 0).");
    RLMAssertThrowsWithReason([optManaged.boolObj exchangeObjectAtIndex:1 withObjectAtIndex:0],
                              @"Index 1 is out of bounds (must be less than 0).");
    RLMAssertThrowsWithReason([optManaged.intObj exchangeObjectAtIndex:1 withObjectAtIndex:0],
                              @"Index 1 is out of bounds (must be less than 0).");
    RLMAssertThrowsWithReason([optManaged.floatObj exchangeObjectAtIndex:1 withObjectAtIndex:0],
                              @"Index 1 is out of bounds (must be less than 0).");
    RLMAssertThrowsWithReason([optManaged.doubleObj exchangeObjectAtIndex:1 withObjectAtIndex:0],
                              @"Index 1 is out of bounds (must be less than 0).");
    RLMAssertThrowsWithReason([optManaged.stringObj exchangeObjectAtIndex:1 withObjectAtIndex:0],
                              @"Index 1 is out of bounds (must be less than 0).");
    RLMAssertThrowsWithReason([optManaged.dataObj exchangeObjectAtIndex:1 withObjectAtIndex:0],
                              @"Index 1 is out of bounds (must be less than 0).");
    RLMAssertThrowsWithReason([optManaged.dateObj exchangeObjectAtIndex:1 withObjectAtIndex:0],
                              @"Index 1 is out of bounds (must be less than 0).");

    [unmanaged.boolObj addObjects:@[@NO, @YES, @NO, @YES]];
    [unmanaged.intObj addObjects:@[@2, @3, @2, @3]];
    [unmanaged.floatObj addObjects:@[@2.2f, @3.3f, @2.2f, @3.3f]];
    [unmanaged.doubleObj addObjects:@[@2.2, @3.3, @2.2, @3.3]];
    [unmanaged.stringObj addObjects:@[@"a", @"b", @"a", @"b"]];
    [unmanaged.dataObj addObjects:@[data(1), data(2), data(1), data(2)]];
    [unmanaged.dateObj addObjects:@[date(1), date(2), date(1), date(2)]];
    [optUnmanaged.boolObj addObjects:@[@NO, @YES, @NO, @YES]];
    [optUnmanaged.intObj addObjects:@[@2, @3, @2, @3]];
    [optUnmanaged.floatObj addObjects:@[@2.2f, @3.3f, @2.2f, @3.3f]];
    [optUnmanaged.doubleObj addObjects:@[@2.2, @3.3, @2.2, @3.3]];
    [optUnmanaged.stringObj addObjects:@[@"a", @"b", @"a", @"b"]];
    [optUnmanaged.dataObj addObjects:@[data(1), data(2), data(1), data(2)]];
    [optUnmanaged.dateObj addObjects:@[date(1), date(2), date(1), date(2)]];
    [managed.boolObj addObjects:@[@NO, @YES, @NO, @YES]];
    [managed.intObj addObjects:@[@2, @3, @2, @3]];
    [managed.floatObj addObjects:@[@2.2f, @3.3f, @2.2f, @3.3f]];
    [managed.doubleObj addObjects:@[@2.2, @3.3, @2.2, @3.3]];
    [managed.stringObj addObjects:@[@"a", @"b", @"a", @"b"]];
    [managed.dataObj addObjects:@[data(1), data(2), data(1), data(2)]];
    [managed.dateObj addObjects:@[date(1), date(2), date(1), date(2)]];
    [optManaged.boolObj addObjects:@[@NO, @YES, @NO, @YES]];
    [optManaged.intObj addObjects:@[@2, @3, @2, @3]];
    [optManaged.floatObj addObjects:@[@2.2f, @3.3f, @2.2f, @3.3f]];
    [optManaged.doubleObj addObjects:@[@2.2, @3.3, @2.2, @3.3]];
    [optManaged.stringObj addObjects:@[@"a", @"b", @"a", @"b"]];
    [optManaged.dataObj addObjects:@[data(1), data(2), data(1), data(2)]];
    [optManaged.dateObj addObjects:@[date(1), date(2), date(1), date(2)]];

    [unmanaged.boolObj exchangeObjectAtIndex:2 withObjectAtIndex:1];
    [unmanaged.intObj exchangeObjectAtIndex:2 withObjectAtIndex:1];
    [unmanaged.floatObj exchangeObjectAtIndex:2 withObjectAtIndex:1];
    [unmanaged.doubleObj exchangeObjectAtIndex:2 withObjectAtIndex:1];
    [unmanaged.stringObj exchangeObjectAtIndex:2 withObjectAtIndex:1];
    [unmanaged.dataObj exchangeObjectAtIndex:2 withObjectAtIndex:1];
    [unmanaged.dateObj exchangeObjectAtIndex:2 withObjectAtIndex:1];
    [optUnmanaged.boolObj exchangeObjectAtIndex:2 withObjectAtIndex:1];
    [optUnmanaged.intObj exchangeObjectAtIndex:2 withObjectAtIndex:1];
    [optUnmanaged.floatObj exchangeObjectAtIndex:2 withObjectAtIndex:1];
    [optUnmanaged.doubleObj exchangeObjectAtIndex:2 withObjectAtIndex:1];
    [optUnmanaged.stringObj exchangeObjectAtIndex:2 withObjectAtIndex:1];
    [optUnmanaged.dataObj exchangeObjectAtIndex:2 withObjectAtIndex:1];
    [optUnmanaged.dateObj exchangeObjectAtIndex:2 withObjectAtIndex:1];
    [managed.boolObj exchangeObjectAtIndex:2 withObjectAtIndex:1];
    [managed.intObj exchangeObjectAtIndex:2 withObjectAtIndex:1];
    [managed.floatObj exchangeObjectAtIndex:2 withObjectAtIndex:1];
    [managed.doubleObj exchangeObjectAtIndex:2 withObjectAtIndex:1];
    [managed.stringObj exchangeObjectAtIndex:2 withObjectAtIndex:1];
    [managed.dataObj exchangeObjectAtIndex:2 withObjectAtIndex:1];
    [managed.dateObj exchangeObjectAtIndex:2 withObjectAtIndex:1];
    [optManaged.boolObj exchangeObjectAtIndex:2 withObjectAtIndex:1];
    [optManaged.intObj exchangeObjectAtIndex:2 withObjectAtIndex:1];
    [optManaged.floatObj exchangeObjectAtIndex:2 withObjectAtIndex:1];
    [optManaged.doubleObj exchangeObjectAtIndex:2 withObjectAtIndex:1];
    [optManaged.stringObj exchangeObjectAtIndex:2 withObjectAtIndex:1];
    [optManaged.dataObj exchangeObjectAtIndex:2 withObjectAtIndex:1];
    [optManaged.dateObj exchangeObjectAtIndex:2 withObjectAtIndex:1];

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
}

- (void)testIndexOfObject {
    XCTAssertEqual(NSNotFound, [unmanaged.boolObj indexOfObject:@NO]);
    XCTAssertEqual(NSNotFound, [unmanaged.intObj indexOfObject:@2]);
    XCTAssertEqual(NSNotFound, [unmanaged.floatObj indexOfObject:@2.2f]);
    XCTAssertEqual(NSNotFound, [unmanaged.doubleObj indexOfObject:@2.2]);
    XCTAssertEqual(NSNotFound, [unmanaged.stringObj indexOfObject:@"a"]);
    XCTAssertEqual(NSNotFound, [unmanaged.dataObj indexOfObject:data(1)]);
    XCTAssertEqual(NSNotFound, [unmanaged.dateObj indexOfObject:date(1)]);
    XCTAssertEqual(NSNotFound, [optUnmanaged.boolObj indexOfObject:@NO]);
    XCTAssertEqual(NSNotFound, [optUnmanaged.intObj indexOfObject:@2]);
    XCTAssertEqual(NSNotFound, [optUnmanaged.floatObj indexOfObject:@2.2f]);
    XCTAssertEqual(NSNotFound, [optUnmanaged.doubleObj indexOfObject:@2.2]);
    XCTAssertEqual(NSNotFound, [optUnmanaged.stringObj indexOfObject:@"a"]);
    XCTAssertEqual(NSNotFound, [optUnmanaged.dataObj indexOfObject:data(1)]);
    XCTAssertEqual(NSNotFound, [optUnmanaged.dateObj indexOfObject:date(1)]);
    XCTAssertEqual(NSNotFound, [managed.boolObj indexOfObject:@NO]);
    XCTAssertEqual(NSNotFound, [managed.intObj indexOfObject:@2]);
    XCTAssertEqual(NSNotFound, [managed.floatObj indexOfObject:@2.2f]);
    XCTAssertEqual(NSNotFound, [managed.doubleObj indexOfObject:@2.2]);
    XCTAssertEqual(NSNotFound, [managed.stringObj indexOfObject:@"a"]);
    XCTAssertEqual(NSNotFound, [managed.dataObj indexOfObject:data(1)]);
    XCTAssertEqual(NSNotFound, [managed.dateObj indexOfObject:date(1)]);
    XCTAssertEqual(NSNotFound, [optManaged.boolObj indexOfObject:@NO]);
    XCTAssertEqual(NSNotFound, [optManaged.intObj indexOfObject:@2]);
    XCTAssertEqual(NSNotFound, [optManaged.floatObj indexOfObject:@2.2f]);
    XCTAssertEqual(NSNotFound, [optManaged.doubleObj indexOfObject:@2.2]);
    XCTAssertEqual(NSNotFound, [optManaged.stringObj indexOfObject:@"a"]);
    XCTAssertEqual(NSNotFound, [optManaged.dataObj indexOfObject:data(1)]);
    XCTAssertEqual(NSNotFound, [optManaged.dateObj indexOfObject:date(1)]);

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
    XCTAssertEqual(NSNotFound, [optUnmanaged.boolObj indexOfObject:NSNull.null]);
    XCTAssertEqual(NSNotFound, [optUnmanaged.intObj indexOfObject:NSNull.null]);
    XCTAssertEqual(NSNotFound, [optUnmanaged.floatObj indexOfObject:NSNull.null]);
    XCTAssertEqual(NSNotFound, [optUnmanaged.doubleObj indexOfObject:NSNull.null]);
    XCTAssertEqual(NSNotFound, [optUnmanaged.stringObj indexOfObject:NSNull.null]);
    XCTAssertEqual(NSNotFound, [optUnmanaged.dataObj indexOfObject:NSNull.null]);
    XCTAssertEqual(NSNotFound, [optUnmanaged.dateObj indexOfObject:NSNull.null]);
    XCTAssertEqual(NSNotFound, [optManaged.boolObj indexOfObject:NSNull.null]);
    XCTAssertEqual(NSNotFound, [optManaged.intObj indexOfObject:NSNull.null]);
    XCTAssertEqual(NSNotFound, [optManaged.floatObj indexOfObject:NSNull.null]);
    XCTAssertEqual(NSNotFound, [optManaged.doubleObj indexOfObject:NSNull.null]);
    XCTAssertEqual(NSNotFound, [optManaged.stringObj indexOfObject:NSNull.null]);
    XCTAssertEqual(NSNotFound, [optManaged.dataObj indexOfObject:NSNull.null]);
    XCTAssertEqual(NSNotFound, [optManaged.dateObj indexOfObject:NSNull.null]);

    [unmanaged.boolObj addObjects:@[@NO, @YES]];
    [unmanaged.intObj addObjects:@[@2, @3]];
    [unmanaged.floatObj addObjects:@[@2.2f, @3.3f]];
    [unmanaged.doubleObj addObjects:@[@2.2, @3.3]];
    [unmanaged.stringObj addObjects:@[@"a", @"b"]];
    [unmanaged.dataObj addObjects:@[data(1), data(2)]];
    [unmanaged.dateObj addObjects:@[date(1), date(2)]];
    [optUnmanaged.boolObj addObjects:@[@NO, @YES, NSNull.null]];
    [optUnmanaged.intObj addObjects:@[@2, @3, NSNull.null]];
    [optUnmanaged.floatObj addObjects:@[@2.2f, @3.3f, NSNull.null]];
    [optUnmanaged.doubleObj addObjects:@[@2.2, @3.3, NSNull.null]];
    [optUnmanaged.stringObj addObjects:@[@"a", @"b", NSNull.null]];
    [optUnmanaged.dataObj addObjects:@[data(1), data(2), NSNull.null]];
    [optUnmanaged.dateObj addObjects:@[date(1), date(2), NSNull.null]];
    [managed.boolObj addObjects:@[@NO, @YES]];
    [managed.intObj addObjects:@[@2, @3]];
    [managed.floatObj addObjects:@[@2.2f, @3.3f]];
    [managed.doubleObj addObjects:@[@2.2, @3.3]];
    [managed.stringObj addObjects:@[@"a", @"b"]];
    [managed.dataObj addObjects:@[data(1), data(2)]];
    [managed.dateObj addObjects:@[date(1), date(2)]];
    [optManaged.boolObj addObjects:@[@NO, @YES, NSNull.null]];
    [optManaged.intObj addObjects:@[@2, @3, NSNull.null]];
    [optManaged.floatObj addObjects:@[@2.2f, @3.3f, NSNull.null]];
    [optManaged.doubleObj addObjects:@[@2.2, @3.3, NSNull.null]];
    [optManaged.stringObj addObjects:@[@"a", @"b", NSNull.null]];
    [optManaged.dataObj addObjects:@[data(1), data(2), NSNull.null]];
    [optManaged.dateObj addObjects:@[date(1), date(2), NSNull.null]];

    XCTAssertEqual(1U, [unmanaged.boolObj indexOfObject:@YES]);
    XCTAssertEqual(1U, [unmanaged.intObj indexOfObject:@3]);
    XCTAssertEqual(1U, [unmanaged.floatObj indexOfObject:@3.3f]);
    XCTAssertEqual(1U, [unmanaged.doubleObj indexOfObject:@3.3]);
    XCTAssertEqual(1U, [unmanaged.stringObj indexOfObject:@"b"]);
    XCTAssertEqual(1U, [unmanaged.dataObj indexOfObject:data(2)]);
    XCTAssertEqual(1U, [unmanaged.dateObj indexOfObject:date(2)]);
    XCTAssertEqual(1U, [optUnmanaged.boolObj indexOfObject:@YES]);
    XCTAssertEqual(1U, [optUnmanaged.intObj indexOfObject:@3]);
    XCTAssertEqual(1U, [optUnmanaged.floatObj indexOfObject:@3.3f]);
    XCTAssertEqual(1U, [optUnmanaged.doubleObj indexOfObject:@3.3]);
    XCTAssertEqual(1U, [optUnmanaged.stringObj indexOfObject:@"b"]);
    XCTAssertEqual(1U, [optUnmanaged.dataObj indexOfObject:data(2)]);
    XCTAssertEqual(1U, [optUnmanaged.dateObj indexOfObject:date(2)]);
    XCTAssertEqual(1U, [managed.boolObj indexOfObject:@YES]);
    XCTAssertEqual(1U, [managed.intObj indexOfObject:@3]);
    XCTAssertEqual(1U, [managed.floatObj indexOfObject:@3.3f]);
    XCTAssertEqual(1U, [managed.doubleObj indexOfObject:@3.3]);
    XCTAssertEqual(1U, [managed.stringObj indexOfObject:@"b"]);
    XCTAssertEqual(1U, [managed.dataObj indexOfObject:data(2)]);
    XCTAssertEqual(1U, [managed.dateObj indexOfObject:date(2)]);
    XCTAssertEqual(1U, [optManaged.boolObj indexOfObject:@YES]);
    XCTAssertEqual(1U, [optManaged.intObj indexOfObject:@3]);
    XCTAssertEqual(1U, [optManaged.floatObj indexOfObject:@3.3f]);
    XCTAssertEqual(1U, [optManaged.doubleObj indexOfObject:@3.3]);
    XCTAssertEqual(1U, [optManaged.stringObj indexOfObject:@"b"]);
    XCTAssertEqual(1U, [optManaged.dataObj indexOfObject:data(2)]);
    XCTAssertEqual(1U, [optManaged.dateObj indexOfObject:date(2)]);
}

- (void)testIndexOfObjectWhere {
    RLMAssertThrowsWithReason([managed.boolObj indexOfObjectWhere:@"TRUEPREDICATE"], @"implemented");
    RLMAssertThrowsWithReason([managed.intObj indexOfObjectWhere:@"TRUEPREDICATE"], @"implemented");
    RLMAssertThrowsWithReason([managed.floatObj indexOfObjectWhere:@"TRUEPREDICATE"], @"implemented");
    RLMAssertThrowsWithReason([managed.doubleObj indexOfObjectWhere:@"TRUEPREDICATE"], @"implemented");
    RLMAssertThrowsWithReason([managed.stringObj indexOfObjectWhere:@"TRUEPREDICATE"], @"implemented");
    RLMAssertThrowsWithReason([managed.dataObj indexOfObjectWhere:@"TRUEPREDICATE"], @"implemented");
    RLMAssertThrowsWithReason([managed.dateObj indexOfObjectWhere:@"TRUEPREDICATE"], @"implemented");
    RLMAssertThrowsWithReason([optManaged.boolObj indexOfObjectWhere:@"TRUEPREDICATE"], @"implemented");
    RLMAssertThrowsWithReason([optManaged.intObj indexOfObjectWhere:@"TRUEPREDICATE"], @"implemented");
    RLMAssertThrowsWithReason([optManaged.floatObj indexOfObjectWhere:@"TRUEPREDICATE"], @"implemented");
    RLMAssertThrowsWithReason([optManaged.doubleObj indexOfObjectWhere:@"TRUEPREDICATE"], @"implemented");
    RLMAssertThrowsWithReason([optManaged.stringObj indexOfObjectWhere:@"TRUEPREDICATE"], @"implemented");
    RLMAssertThrowsWithReason([optManaged.dataObj indexOfObjectWhere:@"TRUEPREDICATE"], @"implemented");
    RLMAssertThrowsWithReason([optManaged.dateObj indexOfObjectWhere:@"TRUEPREDICATE"], @"implemented");
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

    XCTAssertEqual(NSNotFound, [unmanaged.boolObj indexOfObjectWhere:@"TRUEPREDICATE"]);
    XCTAssertEqual(NSNotFound, [unmanaged.intObj indexOfObjectWhere:@"TRUEPREDICATE"]);
    XCTAssertEqual(NSNotFound, [unmanaged.floatObj indexOfObjectWhere:@"TRUEPREDICATE"]);
    XCTAssertEqual(NSNotFound, [unmanaged.doubleObj indexOfObjectWhere:@"TRUEPREDICATE"]);
    XCTAssertEqual(NSNotFound, [unmanaged.stringObj indexOfObjectWhere:@"TRUEPREDICATE"]);
    XCTAssertEqual(NSNotFound, [unmanaged.dataObj indexOfObjectWhere:@"TRUEPREDICATE"]);
    XCTAssertEqual(NSNotFound, [unmanaged.dateObj indexOfObjectWhere:@"TRUEPREDICATE"]);
    XCTAssertEqual(NSNotFound, [optUnmanaged.boolObj indexOfObjectWhere:@"TRUEPREDICATE"]);
    XCTAssertEqual(NSNotFound, [optUnmanaged.intObj indexOfObjectWhere:@"TRUEPREDICATE"]);
    XCTAssertEqual(NSNotFound, [optUnmanaged.floatObj indexOfObjectWhere:@"TRUEPREDICATE"]);
    XCTAssertEqual(NSNotFound, [optUnmanaged.doubleObj indexOfObjectWhere:@"TRUEPREDICATE"]);
    XCTAssertEqual(NSNotFound, [optUnmanaged.stringObj indexOfObjectWhere:@"TRUEPREDICATE"]);
    XCTAssertEqual(NSNotFound, [optUnmanaged.dataObj indexOfObjectWhere:@"TRUEPREDICATE"]);
    XCTAssertEqual(NSNotFound, [optUnmanaged.dateObj indexOfObjectWhere:@"TRUEPREDICATE"]);

    [unmanaged.boolObj addObjects:@[@NO, @YES]];
    [unmanaged.intObj addObjects:@[@2, @3]];
    [unmanaged.floatObj addObjects:@[@2.2f, @3.3f]];
    [unmanaged.doubleObj addObjects:@[@2.2, @3.3]];
    [unmanaged.stringObj addObjects:@[@"a", @"b"]];
    [unmanaged.dataObj addObjects:@[data(1), data(2)]];
    [unmanaged.dateObj addObjects:@[date(1), date(2)]];
    [optUnmanaged.boolObj addObjects:@[@NO, @YES, NSNull.null]];
    [optUnmanaged.intObj addObjects:@[@2, @3, NSNull.null]];
    [optUnmanaged.floatObj addObjects:@[@2.2f, @3.3f, NSNull.null]];
    [optUnmanaged.doubleObj addObjects:@[@2.2, @3.3, NSNull.null]];
    [optUnmanaged.stringObj addObjects:@[@"a", @"b", NSNull.null]];
    [optUnmanaged.dataObj addObjects:@[data(1), data(2), NSNull.null]];
    [optUnmanaged.dateObj addObjects:@[date(1), date(2), NSNull.null]];

    XCTAssertEqual(0U, [unmanaged.boolObj indexOfObjectWhere:@"TRUEPREDICATE"]);
    XCTAssertEqual(0U, [unmanaged.intObj indexOfObjectWhere:@"TRUEPREDICATE"]);
    XCTAssertEqual(0U, [unmanaged.floatObj indexOfObjectWhere:@"TRUEPREDICATE"]);
    XCTAssertEqual(0U, [unmanaged.doubleObj indexOfObjectWhere:@"TRUEPREDICATE"]);
    XCTAssertEqual(0U, [unmanaged.stringObj indexOfObjectWhere:@"TRUEPREDICATE"]);
    XCTAssertEqual(0U, [unmanaged.dataObj indexOfObjectWhere:@"TRUEPREDICATE"]);
    XCTAssertEqual(0U, [unmanaged.dateObj indexOfObjectWhere:@"TRUEPREDICATE"]);
    XCTAssertEqual(0U, [optUnmanaged.boolObj indexOfObjectWhere:@"TRUEPREDICATE"]);
    XCTAssertEqual(0U, [optUnmanaged.intObj indexOfObjectWhere:@"TRUEPREDICATE"]);
    XCTAssertEqual(0U, [optUnmanaged.floatObj indexOfObjectWhere:@"TRUEPREDICATE"]);
    XCTAssertEqual(0U, [optUnmanaged.doubleObj indexOfObjectWhere:@"TRUEPREDICATE"]);
    XCTAssertEqual(0U, [optUnmanaged.stringObj indexOfObjectWhere:@"TRUEPREDICATE"]);
    XCTAssertEqual(0U, [optUnmanaged.dataObj indexOfObjectWhere:@"TRUEPREDICATE"]);
    XCTAssertEqual(0U, [optUnmanaged.dateObj indexOfObjectWhere:@"TRUEPREDICATE"]);
    XCTAssertEqual(NSNotFound, [unmanaged.boolObj indexOfObjectWhere:@"FALSEPREDICATE"]);
    XCTAssertEqual(NSNotFound, [unmanaged.intObj indexOfObjectWhere:@"FALSEPREDICATE"]);
    XCTAssertEqual(NSNotFound, [unmanaged.floatObj indexOfObjectWhere:@"FALSEPREDICATE"]);
    XCTAssertEqual(NSNotFound, [unmanaged.doubleObj indexOfObjectWhere:@"FALSEPREDICATE"]);
    XCTAssertEqual(NSNotFound, [unmanaged.stringObj indexOfObjectWhere:@"FALSEPREDICATE"]);
    XCTAssertEqual(NSNotFound, [unmanaged.dataObj indexOfObjectWhere:@"FALSEPREDICATE"]);
    XCTAssertEqual(NSNotFound, [unmanaged.dateObj indexOfObjectWhere:@"FALSEPREDICATE"]);
    XCTAssertEqual(NSNotFound, [optUnmanaged.boolObj indexOfObjectWhere:@"FALSEPREDICATE"]);
    XCTAssertEqual(NSNotFound, [optUnmanaged.intObj indexOfObjectWhere:@"FALSEPREDICATE"]);
    XCTAssertEqual(NSNotFound, [optUnmanaged.floatObj indexOfObjectWhere:@"FALSEPREDICATE"]);
    XCTAssertEqual(NSNotFound, [optUnmanaged.doubleObj indexOfObjectWhere:@"FALSEPREDICATE"]);
    XCTAssertEqual(NSNotFound, [optUnmanaged.stringObj indexOfObjectWhere:@"FALSEPREDICATE"]);
    XCTAssertEqual(NSNotFound, [optUnmanaged.dataObj indexOfObjectWhere:@"FALSEPREDICATE"]);
    XCTAssertEqual(NSNotFound, [optUnmanaged.dateObj indexOfObjectWhere:@"FALSEPREDICATE"]);
}

- (void)testIndexOfObjectWithPredicate {
    RLMAssertThrowsWithReason([managed.boolObj indexOfObjectWithPredicate:[NSPredicate predicateWithValue:YES]], @"implemented");
    RLMAssertThrowsWithReason([managed.intObj indexOfObjectWithPredicate:[NSPredicate predicateWithValue:YES]], @"implemented");
    RLMAssertThrowsWithReason([managed.floatObj indexOfObjectWithPredicate:[NSPredicate predicateWithValue:YES]], @"implemented");
    RLMAssertThrowsWithReason([managed.doubleObj indexOfObjectWithPredicate:[NSPredicate predicateWithValue:YES]], @"implemented");
    RLMAssertThrowsWithReason([managed.stringObj indexOfObjectWithPredicate:[NSPredicate predicateWithValue:YES]], @"implemented");
    RLMAssertThrowsWithReason([managed.dataObj indexOfObjectWithPredicate:[NSPredicate predicateWithValue:YES]], @"implemented");
    RLMAssertThrowsWithReason([managed.dateObj indexOfObjectWithPredicate:[NSPredicate predicateWithValue:YES]], @"implemented");
    RLMAssertThrowsWithReason([optManaged.boolObj indexOfObjectWithPredicate:[NSPredicate predicateWithValue:YES]], @"implemented");
    RLMAssertThrowsWithReason([optManaged.intObj indexOfObjectWithPredicate:[NSPredicate predicateWithValue:YES]], @"implemented");
    RLMAssertThrowsWithReason([optManaged.floatObj indexOfObjectWithPredicate:[NSPredicate predicateWithValue:YES]], @"implemented");
    RLMAssertThrowsWithReason([optManaged.doubleObj indexOfObjectWithPredicate:[NSPredicate predicateWithValue:YES]], @"implemented");
    RLMAssertThrowsWithReason([optManaged.stringObj indexOfObjectWithPredicate:[NSPredicate predicateWithValue:YES]], @"implemented");
    RLMAssertThrowsWithReason([optManaged.dataObj indexOfObjectWithPredicate:[NSPredicate predicateWithValue:YES]], @"implemented");
    RLMAssertThrowsWithReason([optManaged.dateObj indexOfObjectWithPredicate:[NSPredicate predicateWithValue:YES]], @"implemented");
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

    XCTAssertEqual(NSNotFound, [unmanaged.boolObj indexOfObjectWithPredicate:[NSPredicate predicateWithValue:YES]]);
    XCTAssertEqual(NSNotFound, [unmanaged.intObj indexOfObjectWithPredicate:[NSPredicate predicateWithValue:YES]]);
    XCTAssertEqual(NSNotFound, [unmanaged.floatObj indexOfObjectWithPredicate:[NSPredicate predicateWithValue:YES]]);
    XCTAssertEqual(NSNotFound, [unmanaged.doubleObj indexOfObjectWithPredicate:[NSPredicate predicateWithValue:YES]]);
    XCTAssertEqual(NSNotFound, [unmanaged.stringObj indexOfObjectWithPredicate:[NSPredicate predicateWithValue:YES]]);
    XCTAssertEqual(NSNotFound, [unmanaged.dataObj indexOfObjectWithPredicate:[NSPredicate predicateWithValue:YES]]);
    XCTAssertEqual(NSNotFound, [unmanaged.dateObj indexOfObjectWithPredicate:[NSPredicate predicateWithValue:YES]]);
    XCTAssertEqual(NSNotFound, [optUnmanaged.boolObj indexOfObjectWithPredicate:[NSPredicate predicateWithValue:YES]]);
    XCTAssertEqual(NSNotFound, [optUnmanaged.intObj indexOfObjectWithPredicate:[NSPredicate predicateWithValue:YES]]);
    XCTAssertEqual(NSNotFound, [optUnmanaged.floatObj indexOfObjectWithPredicate:[NSPredicate predicateWithValue:YES]]);
    XCTAssertEqual(NSNotFound, [optUnmanaged.doubleObj indexOfObjectWithPredicate:[NSPredicate predicateWithValue:YES]]);
    XCTAssertEqual(NSNotFound, [optUnmanaged.stringObj indexOfObjectWithPredicate:[NSPredicate predicateWithValue:YES]]);
    XCTAssertEqual(NSNotFound, [optUnmanaged.dataObj indexOfObjectWithPredicate:[NSPredicate predicateWithValue:YES]]);
    XCTAssertEqual(NSNotFound, [optUnmanaged.dateObj indexOfObjectWithPredicate:[NSPredicate predicateWithValue:YES]]);

    [unmanaged.boolObj addObjects:@[@NO, @YES]];
    [unmanaged.intObj addObjects:@[@2, @3]];
    [unmanaged.floatObj addObjects:@[@2.2f, @3.3f]];
    [unmanaged.doubleObj addObjects:@[@2.2, @3.3]];
    [unmanaged.stringObj addObjects:@[@"a", @"b"]];
    [unmanaged.dataObj addObjects:@[data(1), data(2)]];
    [unmanaged.dateObj addObjects:@[date(1), date(2)]];
    [optUnmanaged.boolObj addObjects:@[@NO, @YES, NSNull.null]];
    [optUnmanaged.intObj addObjects:@[@2, @3, NSNull.null]];
    [optUnmanaged.floatObj addObjects:@[@2.2f, @3.3f, NSNull.null]];
    [optUnmanaged.doubleObj addObjects:@[@2.2, @3.3, NSNull.null]];
    [optUnmanaged.stringObj addObjects:@[@"a", @"b", NSNull.null]];
    [optUnmanaged.dataObj addObjects:@[data(1), data(2), NSNull.null]];
    [optUnmanaged.dateObj addObjects:@[date(1), date(2), NSNull.null]];

    XCTAssertEqual(0U, [unmanaged.boolObj indexOfObjectWithPredicate:[NSPredicate predicateWithValue:YES]]);
    XCTAssertEqual(0U, [unmanaged.intObj indexOfObjectWithPredicate:[NSPredicate predicateWithValue:YES]]);
    XCTAssertEqual(0U, [unmanaged.floatObj indexOfObjectWithPredicate:[NSPredicate predicateWithValue:YES]]);
    XCTAssertEqual(0U, [unmanaged.doubleObj indexOfObjectWithPredicate:[NSPredicate predicateWithValue:YES]]);
    XCTAssertEqual(0U, [unmanaged.stringObj indexOfObjectWithPredicate:[NSPredicate predicateWithValue:YES]]);
    XCTAssertEqual(0U, [unmanaged.dataObj indexOfObjectWithPredicate:[NSPredicate predicateWithValue:YES]]);
    XCTAssertEqual(0U, [unmanaged.dateObj indexOfObjectWithPredicate:[NSPredicate predicateWithValue:YES]]);
    XCTAssertEqual(0U, [optUnmanaged.boolObj indexOfObjectWithPredicate:[NSPredicate predicateWithValue:YES]]);
    XCTAssertEqual(0U, [optUnmanaged.intObj indexOfObjectWithPredicate:[NSPredicate predicateWithValue:YES]]);
    XCTAssertEqual(0U, [optUnmanaged.floatObj indexOfObjectWithPredicate:[NSPredicate predicateWithValue:YES]]);
    XCTAssertEqual(0U, [optUnmanaged.doubleObj indexOfObjectWithPredicate:[NSPredicate predicateWithValue:YES]]);
    XCTAssertEqual(0U, [optUnmanaged.stringObj indexOfObjectWithPredicate:[NSPredicate predicateWithValue:YES]]);
    XCTAssertEqual(0U, [optUnmanaged.dataObj indexOfObjectWithPredicate:[NSPredicate predicateWithValue:YES]]);
    XCTAssertEqual(0U, [optUnmanaged.dateObj indexOfObjectWithPredicate:[NSPredicate predicateWithValue:YES]]);
    XCTAssertEqual(NSNotFound, [unmanaged.boolObj indexOfObjectWithPredicate:[NSPredicate predicateWithValue:NO]]);
    XCTAssertEqual(NSNotFound, [unmanaged.intObj indexOfObjectWithPredicate:[NSPredicate predicateWithValue:NO]]);
    XCTAssertEqual(NSNotFound, [unmanaged.floatObj indexOfObjectWithPredicate:[NSPredicate predicateWithValue:NO]]);
    XCTAssertEqual(NSNotFound, [unmanaged.doubleObj indexOfObjectWithPredicate:[NSPredicate predicateWithValue:NO]]);
    XCTAssertEqual(NSNotFound, [unmanaged.stringObj indexOfObjectWithPredicate:[NSPredicate predicateWithValue:NO]]);
    XCTAssertEqual(NSNotFound, [unmanaged.dataObj indexOfObjectWithPredicate:[NSPredicate predicateWithValue:NO]]);
    XCTAssertEqual(NSNotFound, [unmanaged.dateObj indexOfObjectWithPredicate:[NSPredicate predicateWithValue:NO]]);
    XCTAssertEqual(NSNotFound, [optUnmanaged.boolObj indexOfObjectWithPredicate:[NSPredicate predicateWithValue:NO]]);
    XCTAssertEqual(NSNotFound, [optUnmanaged.intObj indexOfObjectWithPredicate:[NSPredicate predicateWithValue:NO]]);
    XCTAssertEqual(NSNotFound, [optUnmanaged.floatObj indexOfObjectWithPredicate:[NSPredicate predicateWithValue:NO]]);
    XCTAssertEqual(NSNotFound, [optUnmanaged.doubleObj indexOfObjectWithPredicate:[NSPredicate predicateWithValue:NO]]);
    XCTAssertEqual(NSNotFound, [optUnmanaged.stringObj indexOfObjectWithPredicate:[NSPredicate predicateWithValue:NO]]);
    XCTAssertEqual(NSNotFound, [optUnmanaged.dataObj indexOfObjectWithPredicate:[NSPredicate predicateWithValue:NO]]);
    XCTAssertEqual(NSNotFound, [optUnmanaged.dateObj indexOfObjectWithPredicate:[NSPredicate predicateWithValue:NO]]);
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

    [managed.boolObj addObjects:@[@NO, @YES, @NO]];
    [managed.intObj addObjects:@[@2, @3, @2]];
    [managed.floatObj addObjects:@[@2.2f, @3.3f, @2.2f]];
    [managed.doubleObj addObjects:@[@2.2, @3.3, @2.2]];
    [managed.stringObj addObjects:@[@"a", @"b", @"a"]];
    [managed.dataObj addObjects:@[data(1), data(2), data(1)]];
    [managed.dateObj addObjects:@[date(1), date(2), date(1)]];
    [optManaged.boolObj addObjects:@[@NO, @YES, NSNull.null, @YES, @NO]];
    [optManaged.intObj addObjects:@[@2, @3, NSNull.null, @3, @2]];
    [optManaged.floatObj addObjects:@[@2.2f, @3.3f, NSNull.null, @3.3f, @2.2f]];
    [optManaged.doubleObj addObjects:@[@2.2, @3.3, NSNull.null, @3.3, @2.2]];
    [optManaged.stringObj addObjects:@[@"a", @"b", NSNull.null, @"b", @"a"]];
    [optManaged.dataObj addObjects:@[data(1), data(2), NSNull.null, data(2), data(1)]];
    [optManaged.dateObj addObjects:@[date(1), date(2), NSNull.null, date(2), date(1)]];

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
}

- (void)testMin {
    RLMAssertThrowsWithReason([unmanaged.boolObj minOfProperty:@"self"],
                              @"minOfProperty: is not supported for bool array");
    RLMAssertThrowsWithReason([unmanaged.stringObj minOfProperty:@"self"],
                              @"minOfProperty: is not supported for string array");
    RLMAssertThrowsWithReason([unmanaged.dataObj minOfProperty:@"self"],
                              @"minOfProperty: is not supported for data array");
    RLMAssertThrowsWithReason([optUnmanaged.boolObj minOfProperty:@"self"],
                              @"minOfProperty: is not supported for bool? array");
    RLMAssertThrowsWithReason([optUnmanaged.stringObj minOfProperty:@"self"],
                              @"minOfProperty: is not supported for string? array");
    RLMAssertThrowsWithReason([optUnmanaged.dataObj minOfProperty:@"self"],
                              @"minOfProperty: is not supported for data? array");
    RLMAssertThrowsWithReason([managed.boolObj minOfProperty:@"self"],
                              @"minOfProperty: is not supported for bool array 'AllPrimitiveArrays.boolObj'");
    RLMAssertThrowsWithReason([managed.stringObj minOfProperty:@"self"],
                              @"minOfProperty: is not supported for string array 'AllPrimitiveArrays.stringObj'");
    RLMAssertThrowsWithReason([managed.dataObj minOfProperty:@"self"],
                              @"minOfProperty: is not supported for data array 'AllPrimitiveArrays.dataObj'");
    RLMAssertThrowsWithReason([optManaged.boolObj minOfProperty:@"self"],
                              @"minOfProperty: is not supported for bool? array 'AllOptionalPrimitiveArrays.boolObj'");
    RLMAssertThrowsWithReason([optManaged.stringObj minOfProperty:@"self"],
                              @"minOfProperty: is not supported for string? array 'AllOptionalPrimitiveArrays.stringObj'");
    RLMAssertThrowsWithReason([optManaged.dataObj minOfProperty:@"self"],
                              @"minOfProperty: is not supported for data? array 'AllOptionalPrimitiveArrays.dataObj'");

    XCTAssertNil([unmanaged.intObj minOfProperty:@"self"]);
    XCTAssertNil([unmanaged.floatObj minOfProperty:@"self"]);
    XCTAssertNil([unmanaged.doubleObj minOfProperty:@"self"]);
    XCTAssertNil([unmanaged.dateObj minOfProperty:@"self"]);
    XCTAssertNil([optUnmanaged.intObj minOfProperty:@"self"]);
    XCTAssertNil([optUnmanaged.floatObj minOfProperty:@"self"]);
    XCTAssertNil([optUnmanaged.doubleObj minOfProperty:@"self"]);
    XCTAssertNil([optUnmanaged.dateObj minOfProperty:@"self"]);
    XCTAssertNil([managed.intObj minOfProperty:@"self"]);
    XCTAssertNil([managed.floatObj minOfProperty:@"self"]);
    XCTAssertNil([managed.doubleObj minOfProperty:@"self"]);
    XCTAssertNil([managed.dateObj minOfProperty:@"self"]);
    XCTAssertNil([optManaged.intObj minOfProperty:@"self"]);
    XCTAssertNil([optManaged.floatObj minOfProperty:@"self"]);
    XCTAssertNil([optManaged.doubleObj minOfProperty:@"self"]);
    XCTAssertNil([optManaged.dateObj minOfProperty:@"self"]);

    [unmanaged.intObj addObjects:@[@2, @3]];
    [unmanaged.floatObj addObjects:@[@2.2f, @3.3f]];
    [unmanaged.doubleObj addObjects:@[@2.2, @3.3]];
    [unmanaged.dateObj addObjects:@[date(1), date(2)]];
    [optUnmanaged.intObj addObjects:@[@2, @3, NSNull.null]];
    [optUnmanaged.floatObj addObjects:@[@2.2f, @3.3f, NSNull.null]];
    [optUnmanaged.doubleObj addObjects:@[@2.2, @3.3, NSNull.null]];
    [optUnmanaged.dateObj addObjects:@[date(1), date(2), NSNull.null]];
    [managed.intObj addObjects:@[@2, @3]];
    [managed.floatObj addObjects:@[@2.2f, @3.3f]];
    [managed.doubleObj addObjects:@[@2.2, @3.3]];
    [managed.dateObj addObjects:@[date(1), date(2)]];
    [optManaged.intObj addObjects:@[@2, @3, NSNull.null]];
    [optManaged.floatObj addObjects:@[@2.2f, @3.3f, NSNull.null]];
    [optManaged.doubleObj addObjects:@[@2.2, @3.3, NSNull.null]];
    [optManaged.dateObj addObjects:@[date(1), date(2), NSNull.null]];

    XCTAssertEqualObjects([unmanaged.intObj minOfProperty:@"self"], @2);
    XCTAssertEqualObjects([unmanaged.floatObj minOfProperty:@"self"], @2.2f);
    XCTAssertEqualObjects([unmanaged.doubleObj minOfProperty:@"self"], @2.2);
    XCTAssertEqualObjects([unmanaged.dateObj minOfProperty:@"self"], date(1));
    XCTAssertEqualObjects([optUnmanaged.intObj minOfProperty:@"self"], @2);
    XCTAssertEqualObjects([optUnmanaged.floatObj minOfProperty:@"self"], @2.2f);
    XCTAssertEqualObjects([optUnmanaged.doubleObj minOfProperty:@"self"], @2.2);
    XCTAssertEqualObjects([optUnmanaged.dateObj minOfProperty:@"self"], date(1));
    XCTAssertEqualObjects([managed.intObj minOfProperty:@"self"], @2);
    XCTAssertEqualObjects([managed.floatObj minOfProperty:@"self"], @2.2f);
    XCTAssertEqualObjects([managed.doubleObj minOfProperty:@"self"], @2.2);
    XCTAssertEqualObjects([managed.dateObj minOfProperty:@"self"], date(1));
    XCTAssertEqualObjects([optManaged.intObj minOfProperty:@"self"], @2);
    XCTAssertEqualObjects([optManaged.floatObj minOfProperty:@"self"], @2.2f);
    XCTAssertEqualObjects([optManaged.doubleObj minOfProperty:@"self"], @2.2);
    XCTAssertEqualObjects([optManaged.dateObj minOfProperty:@"self"], date(1));
}

- (void)testMax {
    RLMAssertThrowsWithReason([unmanaged.boolObj maxOfProperty:@"self"],
                              @"maxOfProperty: is not supported for bool array");
    RLMAssertThrowsWithReason([unmanaged.stringObj maxOfProperty:@"self"],
                              @"maxOfProperty: is not supported for string array");
    RLMAssertThrowsWithReason([unmanaged.dataObj maxOfProperty:@"self"],
                              @"maxOfProperty: is not supported for data array");
    RLMAssertThrowsWithReason([optUnmanaged.boolObj maxOfProperty:@"self"],
                              @"maxOfProperty: is not supported for bool? array");
    RLMAssertThrowsWithReason([optUnmanaged.stringObj maxOfProperty:@"self"],
                              @"maxOfProperty: is not supported for string? array");
    RLMAssertThrowsWithReason([optUnmanaged.dataObj maxOfProperty:@"self"],
                              @"maxOfProperty: is not supported for data? array");
    RLMAssertThrowsWithReason([managed.boolObj maxOfProperty:@"self"],
                              @"maxOfProperty: is not supported for bool array 'AllPrimitiveArrays.boolObj'");
    RLMAssertThrowsWithReason([managed.stringObj maxOfProperty:@"self"],
                              @"maxOfProperty: is not supported for string array 'AllPrimitiveArrays.stringObj'");
    RLMAssertThrowsWithReason([managed.dataObj maxOfProperty:@"self"],
                              @"maxOfProperty: is not supported for data array 'AllPrimitiveArrays.dataObj'");
    RLMAssertThrowsWithReason([optManaged.boolObj maxOfProperty:@"self"],
                              @"maxOfProperty: is not supported for bool? array 'AllOptionalPrimitiveArrays.boolObj'");
    RLMAssertThrowsWithReason([optManaged.stringObj maxOfProperty:@"self"],
                              @"maxOfProperty: is not supported for string? array 'AllOptionalPrimitiveArrays.stringObj'");
    RLMAssertThrowsWithReason([optManaged.dataObj maxOfProperty:@"self"],
                              @"maxOfProperty: is not supported for data? array 'AllOptionalPrimitiveArrays.dataObj'");

    XCTAssertNil([unmanaged.intObj maxOfProperty:@"self"]);
    XCTAssertNil([unmanaged.floatObj maxOfProperty:@"self"]);
    XCTAssertNil([unmanaged.doubleObj maxOfProperty:@"self"]);
    XCTAssertNil([unmanaged.dateObj maxOfProperty:@"self"]);
    XCTAssertNil([optUnmanaged.intObj maxOfProperty:@"self"]);
    XCTAssertNil([optUnmanaged.floatObj maxOfProperty:@"self"]);
    XCTAssertNil([optUnmanaged.doubleObj maxOfProperty:@"self"]);
    XCTAssertNil([optUnmanaged.dateObj maxOfProperty:@"self"]);
    XCTAssertNil([managed.intObj maxOfProperty:@"self"]);
    XCTAssertNil([managed.floatObj maxOfProperty:@"self"]);
    XCTAssertNil([managed.doubleObj maxOfProperty:@"self"]);
    XCTAssertNil([managed.dateObj maxOfProperty:@"self"]);
    XCTAssertNil([optManaged.intObj maxOfProperty:@"self"]);
    XCTAssertNil([optManaged.floatObj maxOfProperty:@"self"]);
    XCTAssertNil([optManaged.doubleObj maxOfProperty:@"self"]);
    XCTAssertNil([optManaged.dateObj maxOfProperty:@"self"]);

    [unmanaged.intObj addObjects:@[@2, @3]];
    [unmanaged.floatObj addObjects:@[@2.2f, @3.3f]];
    [unmanaged.doubleObj addObjects:@[@2.2, @3.3]];
    [unmanaged.dateObj addObjects:@[date(1), date(2)]];
    [optUnmanaged.intObj addObjects:@[@2, @3, NSNull.null]];
    [optUnmanaged.floatObj addObjects:@[@2.2f, @3.3f, NSNull.null]];
    [optUnmanaged.doubleObj addObjects:@[@2.2, @3.3, NSNull.null]];
    [optUnmanaged.dateObj addObjects:@[date(1), date(2), NSNull.null]];
    [managed.intObj addObjects:@[@2, @3]];
    [managed.floatObj addObjects:@[@2.2f, @3.3f]];
    [managed.doubleObj addObjects:@[@2.2, @3.3]];
    [managed.dateObj addObjects:@[date(1), date(2)]];
    [optManaged.intObj addObjects:@[@2, @3, NSNull.null]];
    [optManaged.floatObj addObjects:@[@2.2f, @3.3f, NSNull.null]];
    [optManaged.doubleObj addObjects:@[@2.2, @3.3, NSNull.null]];
    [optManaged.dateObj addObjects:@[date(1), date(2), NSNull.null]];

    XCTAssertEqualObjects([unmanaged.intObj maxOfProperty:@"self"], @3);
    XCTAssertEqualObjects([unmanaged.floatObj maxOfProperty:@"self"], @3.3f);
    XCTAssertEqualObjects([unmanaged.doubleObj maxOfProperty:@"self"], @3.3);
    XCTAssertEqualObjects([unmanaged.dateObj maxOfProperty:@"self"], date(2));
    XCTAssertEqualObjects([optUnmanaged.intObj maxOfProperty:@"self"], @3);
    XCTAssertEqualObjects([optUnmanaged.floatObj maxOfProperty:@"self"], @3.3f);
    XCTAssertEqualObjects([optUnmanaged.doubleObj maxOfProperty:@"self"], @3.3);
    XCTAssertEqualObjects([optUnmanaged.dateObj maxOfProperty:@"self"], date(2));
    XCTAssertEqualObjects([managed.intObj maxOfProperty:@"self"], @3);
    XCTAssertEqualObjects([managed.floatObj maxOfProperty:@"self"], @3.3f);
    XCTAssertEqualObjects([managed.doubleObj maxOfProperty:@"self"], @3.3);
    XCTAssertEqualObjects([managed.dateObj maxOfProperty:@"self"], date(2));
    XCTAssertEqualObjects([optManaged.intObj maxOfProperty:@"self"], @3);
    XCTAssertEqualObjects([optManaged.floatObj maxOfProperty:@"self"], @3.3f);
    XCTAssertEqualObjects([optManaged.doubleObj maxOfProperty:@"self"], @3.3);
    XCTAssertEqualObjects([optManaged.dateObj maxOfProperty:@"self"], date(2));
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
    RLMAssertThrowsWithReason([optUnmanaged.boolObj sumOfProperty:@"self"],
                              @"sumOfProperty: is not supported for bool? array");
    RLMAssertThrowsWithReason([optUnmanaged.stringObj sumOfProperty:@"self"],
                              @"sumOfProperty: is not supported for string? array");
    RLMAssertThrowsWithReason([optUnmanaged.dataObj sumOfProperty:@"self"],
                              @"sumOfProperty: is not supported for data? array");
    RLMAssertThrowsWithReason([optUnmanaged.dateObj sumOfProperty:@"self"],
                              @"sumOfProperty: is not supported for date? array");
    RLMAssertThrowsWithReason([managed.boolObj sumOfProperty:@"self"],
                              @"sumOfProperty: is not supported for bool array 'AllPrimitiveArrays.boolObj'");
    RLMAssertThrowsWithReason([managed.stringObj sumOfProperty:@"self"],
                              @"sumOfProperty: is not supported for string array 'AllPrimitiveArrays.stringObj'");
    RLMAssertThrowsWithReason([managed.dataObj sumOfProperty:@"self"],
                              @"sumOfProperty: is not supported for data array 'AllPrimitiveArrays.dataObj'");
    RLMAssertThrowsWithReason([managed.dateObj sumOfProperty:@"self"],
                              @"sumOfProperty: is not supported for date array 'AllPrimitiveArrays.dateObj'");
    RLMAssertThrowsWithReason([optManaged.boolObj sumOfProperty:@"self"],
                              @"sumOfProperty: is not supported for bool? array 'AllOptionalPrimitiveArrays.boolObj'");
    RLMAssertThrowsWithReason([optManaged.stringObj sumOfProperty:@"self"],
                              @"sumOfProperty: is not supported for string? array 'AllOptionalPrimitiveArrays.stringObj'");
    RLMAssertThrowsWithReason([optManaged.dataObj sumOfProperty:@"self"],
                              @"sumOfProperty: is not supported for data? array 'AllOptionalPrimitiveArrays.dataObj'");
    RLMAssertThrowsWithReason([optManaged.dateObj sumOfProperty:@"self"],
                              @"sumOfProperty: is not supported for date? array 'AllOptionalPrimitiveArrays.dateObj'");

    XCTAssertEqualObjects([unmanaged.intObj sumOfProperty:@"self"], @0);
    XCTAssertEqualObjects([unmanaged.floatObj sumOfProperty:@"self"], @0);
    XCTAssertEqualObjects([unmanaged.doubleObj sumOfProperty:@"self"], @0);
    XCTAssertEqualObjects([optUnmanaged.intObj sumOfProperty:@"self"], @0);
    XCTAssertEqualObjects([optUnmanaged.floatObj sumOfProperty:@"self"], @0);
    XCTAssertEqualObjects([optUnmanaged.doubleObj sumOfProperty:@"self"], @0);
    XCTAssertEqualObjects([managed.intObj sumOfProperty:@"self"], @0);
    XCTAssertEqualObjects([managed.floatObj sumOfProperty:@"self"], @0);
    XCTAssertEqualObjects([managed.doubleObj sumOfProperty:@"self"], @0);
    XCTAssertEqualObjects([optManaged.intObj sumOfProperty:@"self"], @0);
    XCTAssertEqualObjects([optManaged.floatObj sumOfProperty:@"self"], @0);
    XCTAssertEqualObjects([optManaged.doubleObj sumOfProperty:@"self"], @0);

    [unmanaged.intObj addObjects:@[@2, @3]];
    [unmanaged.floatObj addObjects:@[@2.2f, @3.3f]];
    [unmanaged.doubleObj addObjects:@[@2.2, @3.3]];
    [optUnmanaged.intObj addObjects:@[@2, @3, NSNull.null]];
    [optUnmanaged.floatObj addObjects:@[@2.2f, @3.3f, NSNull.null]];
    [optUnmanaged.doubleObj addObjects:@[@2.2, @3.3, NSNull.null]];
    [managed.intObj addObjects:@[@2, @3]];
    [managed.floatObj addObjects:@[@2.2f, @3.3f]];
    [managed.doubleObj addObjects:@[@2.2, @3.3]];
    [optManaged.intObj addObjects:@[@2, @3, NSNull.null]];
    [optManaged.floatObj addObjects:@[@2.2f, @3.3f, NSNull.null]];
    [optManaged.doubleObj addObjects:@[@2.2, @3.3, NSNull.null]];

    XCTAssertEqualObjects([unmanaged.intObj sumOfProperty:@"self"], @(2 + 3));
    XCTAssertEqualObjects([unmanaged.floatObj sumOfProperty:@"self"], @(2.2f + 3.3f));
    XCTAssertEqualObjects([unmanaged.doubleObj sumOfProperty:@"self"], @(2.2 + 3.3));
    XCTAssertEqualObjects([optUnmanaged.intObj sumOfProperty:@"self"], @(2 + 3));
    XCTAssertEqualObjects([optUnmanaged.floatObj sumOfProperty:@"self"], @(2.2f + 3.3f));
    XCTAssertEqualObjects([optUnmanaged.doubleObj sumOfProperty:@"self"], @(2.2 + 3.3));
    XCTAssertEqualObjects([managed.intObj sumOfProperty:@"self"], @(2 + 3));
    XCTAssertEqualObjects([managed.floatObj sumOfProperty:@"self"], @(2.2f + 3.3f));
    XCTAssertEqualObjects([managed.doubleObj sumOfProperty:@"self"], @(2.2 + 3.3));
    XCTAssertEqualObjects([optManaged.intObj sumOfProperty:@"self"], @(2 + 3));
    XCTAssertEqualObjects([optManaged.floatObj sumOfProperty:@"self"], @(2.2f + 3.3f));
    XCTAssertEqualObjects([optManaged.doubleObj sumOfProperty:@"self"], @(2.2 + 3.3));
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
    RLMAssertThrowsWithReason([optUnmanaged.boolObj averageOfProperty:@"self"],
                              @"averageOfProperty: is not supported for bool? array");
    RLMAssertThrowsWithReason([optUnmanaged.stringObj averageOfProperty:@"self"],
                              @"averageOfProperty: is not supported for string? array");
    RLMAssertThrowsWithReason([optUnmanaged.dataObj averageOfProperty:@"self"],
                              @"averageOfProperty: is not supported for data? array");
    RLMAssertThrowsWithReason([optUnmanaged.dateObj averageOfProperty:@"self"],
                              @"averageOfProperty: is not supported for date? array");
    RLMAssertThrowsWithReason([managed.boolObj averageOfProperty:@"self"],
                              @"averageOfProperty: is not supported for bool array 'AllPrimitiveArrays.boolObj'");
    RLMAssertThrowsWithReason([managed.stringObj averageOfProperty:@"self"],
                              @"averageOfProperty: is not supported for string array 'AllPrimitiveArrays.stringObj'");
    RLMAssertThrowsWithReason([managed.dataObj averageOfProperty:@"self"],
                              @"averageOfProperty: is not supported for data array 'AllPrimitiveArrays.dataObj'");
    RLMAssertThrowsWithReason([managed.dateObj averageOfProperty:@"self"],
                              @"averageOfProperty: is not supported for date array 'AllPrimitiveArrays.dateObj'");
    RLMAssertThrowsWithReason([optManaged.boolObj averageOfProperty:@"self"],
                              @"averageOfProperty: is not supported for bool? array 'AllOptionalPrimitiveArrays.boolObj'");
    RLMAssertThrowsWithReason([optManaged.stringObj averageOfProperty:@"self"],
                              @"averageOfProperty: is not supported for string? array 'AllOptionalPrimitiveArrays.stringObj'");
    RLMAssertThrowsWithReason([optManaged.dataObj averageOfProperty:@"self"],
                              @"averageOfProperty: is not supported for data? array 'AllOptionalPrimitiveArrays.dataObj'");
    RLMAssertThrowsWithReason([optManaged.dateObj averageOfProperty:@"self"],
                              @"averageOfProperty: is not supported for date? array 'AllOptionalPrimitiveArrays.dateObj'");

    XCTAssertNil([unmanaged.intObj averageOfProperty:@"self"]);
    XCTAssertNil([unmanaged.floatObj averageOfProperty:@"self"]);
    XCTAssertNil([unmanaged.doubleObj averageOfProperty:@"self"]);
    XCTAssertNil([optUnmanaged.intObj averageOfProperty:@"self"]);
    XCTAssertNil([optUnmanaged.floatObj averageOfProperty:@"self"]);
    XCTAssertNil([optUnmanaged.doubleObj averageOfProperty:@"self"]);
    XCTAssertNil([managed.intObj averageOfProperty:@"self"]);
    XCTAssertNil([managed.floatObj averageOfProperty:@"self"]);
    XCTAssertNil([managed.doubleObj averageOfProperty:@"self"]);
    XCTAssertNil([optManaged.intObj averageOfProperty:@"self"]);
    XCTAssertNil([optManaged.floatObj averageOfProperty:@"self"]);
    XCTAssertNil([optManaged.doubleObj averageOfProperty:@"self"]);

    [unmanaged.intObj addObjects:@[@2, @3]];
    [unmanaged.floatObj addObjects:@[@2.2f, @3.3f]];
    [unmanaged.doubleObj addObjects:@[@2.2, @3.3]];
    [optUnmanaged.intObj addObjects:@[@2, @3, NSNull.null]];
    [optUnmanaged.floatObj addObjects:@[@2.2f, @3.3f, NSNull.null]];
    [optUnmanaged.doubleObj addObjects:@[@2.2, @3.3, NSNull.null]];
    [managed.intObj addObjects:@[@2, @3]];
    [managed.floatObj addObjects:@[@2.2f, @3.3f]];
    [managed.doubleObj addObjects:@[@2.2, @3.3]];
    [optManaged.intObj addObjects:@[@2, @3, NSNull.null]];
    [optManaged.floatObj addObjects:@[@2.2f, @3.3f, NSNull.null]];
    [optManaged.doubleObj addObjects:@[@2.2, @3.3, NSNull.null]];

    XCTAssertEqualWithAccuracy([unmanaged.intObj averageOfProperty:@"self"].doubleValue, (2 + 3) / 2.0, .001);
    XCTAssertEqualWithAccuracy([unmanaged.floatObj averageOfProperty:@"self"].doubleValue, (2.2f + 3.3f) / 2.0, .001);
    XCTAssertEqualWithAccuracy([unmanaged.doubleObj averageOfProperty:@"self"].doubleValue, (2.2 + 3.3) / 2.0, .001);
    XCTAssertEqualWithAccuracy([optUnmanaged.intObj averageOfProperty:@"self"].doubleValue, (2 + 3) / 2.0, .001);
    XCTAssertEqualWithAccuracy([optUnmanaged.floatObj averageOfProperty:@"self"].doubleValue, (2.2f + 3.3f) / 2.0, .001);
    XCTAssertEqualWithAccuracy([optUnmanaged.doubleObj averageOfProperty:@"self"].doubleValue, (2.2 + 3.3) / 2.0, .001);
    XCTAssertEqualWithAccuracy([managed.intObj averageOfProperty:@"self"].doubleValue, (2 + 3) / 2.0, .001);
    XCTAssertEqualWithAccuracy([managed.floatObj averageOfProperty:@"self"].doubleValue, (2.2f + 3.3f) / 2.0, .001);
    XCTAssertEqualWithAccuracy([managed.doubleObj averageOfProperty:@"self"].doubleValue, (2.2 + 3.3) / 2.0, .001);
    XCTAssertEqualWithAccuracy([optManaged.intObj averageOfProperty:@"self"].doubleValue, (2 + 3) / 2.0, .001);
    XCTAssertEqualWithAccuracy([optManaged.floatObj averageOfProperty:@"self"].doubleValue, (2.2f + 3.3f) / 2.0, .001);
    XCTAssertEqualWithAccuracy([optManaged.doubleObj averageOfProperty:@"self"].doubleValue, (2.2 + 3.3) / 2.0, .001);
}

- (void)testFastEnumeration {
    for (int i = 0; i < 10; ++i) {
        [unmanaged.boolObj addObjects:@[@NO, @YES]];
        [unmanaged.intObj addObjects:@[@2, @3]];
        [unmanaged.floatObj addObjects:@[@2.2f, @3.3f]];
        [unmanaged.doubleObj addObjects:@[@2.2, @3.3]];
        [unmanaged.stringObj addObjects:@[@"a", @"b"]];
        [unmanaged.dataObj addObjects:@[data(1), data(2)]];
        [unmanaged.dateObj addObjects:@[date(1), date(2)]];
        [optUnmanaged.boolObj addObjects:@[@NO, @YES, NSNull.null]];
        [optUnmanaged.intObj addObjects:@[@2, @3, NSNull.null]];
        [optUnmanaged.floatObj addObjects:@[@2.2f, @3.3f, NSNull.null]];
        [optUnmanaged.doubleObj addObjects:@[@2.2, @3.3, NSNull.null]];
        [optUnmanaged.stringObj addObjects:@[@"a", @"b", NSNull.null]];
        [optUnmanaged.dataObj addObjects:@[data(1), data(2), NSNull.null]];
        [optUnmanaged.dateObj addObjects:@[date(1), date(2), NSNull.null]];
        [managed.boolObj addObjects:@[@NO, @YES]];
        [managed.intObj addObjects:@[@2, @3]];
        [managed.floatObj addObjects:@[@2.2f, @3.3f]];
        [managed.doubleObj addObjects:@[@2.2, @3.3]];
        [managed.stringObj addObjects:@[@"a", @"b"]];
        [managed.dataObj addObjects:@[data(1), data(2)]];
        [managed.dateObj addObjects:@[date(1), date(2)]];
        [optManaged.boolObj addObjects:@[@NO, @YES, NSNull.null]];
        [optManaged.intObj addObjects:@[@2, @3, NSNull.null]];
        [optManaged.floatObj addObjects:@[@2.2f, @3.3f, NSNull.null]];
        [optManaged.doubleObj addObjects:@[@2.2, @3.3, NSNull.null]];
        [optManaged.stringObj addObjects:@[@"a", @"b", NSNull.null]];
        [optManaged.dataObj addObjects:@[data(1), data(2), NSNull.null]];
        [optManaged.dateObj addObjects:@[date(1), date(2), NSNull.null]];
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
    
}

- (void)testValueForKeySelf {
    XCTAssertEqualObjects([unmanaged.boolObj valueForKey:@"self"], @[]);
    XCTAssertEqualObjects([unmanaged.intObj valueForKey:@"self"], @[]);
    XCTAssertEqualObjects([unmanaged.floatObj valueForKey:@"self"], @[]);
    XCTAssertEqualObjects([unmanaged.doubleObj valueForKey:@"self"], @[]);
    XCTAssertEqualObjects([unmanaged.stringObj valueForKey:@"self"], @[]);
    XCTAssertEqualObjects([unmanaged.dataObj valueForKey:@"self"], @[]);
    XCTAssertEqualObjects([unmanaged.dateObj valueForKey:@"self"], @[]);
    XCTAssertEqualObjects([optUnmanaged.boolObj valueForKey:@"self"], @[]);
    XCTAssertEqualObjects([optUnmanaged.intObj valueForKey:@"self"], @[]);
    XCTAssertEqualObjects([optUnmanaged.floatObj valueForKey:@"self"], @[]);
    XCTAssertEqualObjects([optUnmanaged.doubleObj valueForKey:@"self"], @[]);
    XCTAssertEqualObjects([optUnmanaged.stringObj valueForKey:@"self"], @[]);
    XCTAssertEqualObjects([optUnmanaged.dataObj valueForKey:@"self"], @[]);
    XCTAssertEqualObjects([optUnmanaged.dateObj valueForKey:@"self"], @[]);
    XCTAssertEqualObjects([managed.boolObj valueForKey:@"self"], @[]);
    XCTAssertEqualObjects([managed.intObj valueForKey:@"self"], @[]);
    XCTAssertEqualObjects([managed.floatObj valueForKey:@"self"], @[]);
    XCTAssertEqualObjects([managed.doubleObj valueForKey:@"self"], @[]);
    XCTAssertEqualObjects([managed.stringObj valueForKey:@"self"], @[]);
    XCTAssertEqualObjects([managed.dataObj valueForKey:@"self"], @[]);
    XCTAssertEqualObjects([managed.dateObj valueForKey:@"self"], @[]);
    XCTAssertEqualObjects([optManaged.boolObj valueForKey:@"self"], @[]);
    XCTAssertEqualObjects([optManaged.intObj valueForKey:@"self"], @[]);
    XCTAssertEqualObjects([optManaged.floatObj valueForKey:@"self"], @[]);
    XCTAssertEqualObjects([optManaged.doubleObj valueForKey:@"self"], @[]);
    XCTAssertEqualObjects([optManaged.stringObj valueForKey:@"self"], @[]);
    XCTAssertEqualObjects([optManaged.dataObj valueForKey:@"self"], @[]);
    XCTAssertEqualObjects([optManaged.dateObj valueForKey:@"self"], @[]);

    [unmanaged.boolObj addObjects:@[@NO, @YES]];
    [unmanaged.intObj addObjects:@[@2, @3]];
    [unmanaged.floatObj addObjects:@[@2.2f, @3.3f]];
    [unmanaged.doubleObj addObjects:@[@2.2, @3.3]];
    [unmanaged.stringObj addObjects:@[@"a", @"b"]];
    [unmanaged.dataObj addObjects:@[data(1), data(2)]];
    [unmanaged.dateObj addObjects:@[date(1), date(2)]];
    [optUnmanaged.boolObj addObjects:@[@NO, @YES, NSNull.null]];
    [optUnmanaged.intObj addObjects:@[@2, @3, NSNull.null]];
    [optUnmanaged.floatObj addObjects:@[@2.2f, @3.3f, NSNull.null]];
    [optUnmanaged.doubleObj addObjects:@[@2.2, @3.3, NSNull.null]];
    [optUnmanaged.stringObj addObjects:@[@"a", @"b", NSNull.null]];
    [optUnmanaged.dataObj addObjects:@[data(1), data(2), NSNull.null]];
    [optUnmanaged.dateObj addObjects:@[date(1), date(2), NSNull.null]];
    [managed.boolObj addObjects:@[@NO, @YES]];
    [managed.intObj addObjects:@[@2, @3]];
    [managed.floatObj addObjects:@[@2.2f, @3.3f]];
    [managed.doubleObj addObjects:@[@2.2, @3.3]];
    [managed.stringObj addObjects:@[@"a", @"b"]];
    [managed.dataObj addObjects:@[data(1), data(2)]];
    [managed.dateObj addObjects:@[date(1), date(2)]];
    [optManaged.boolObj addObjects:@[@NO, @YES, NSNull.null]];
    [optManaged.intObj addObjects:@[@2, @3, NSNull.null]];
    [optManaged.floatObj addObjects:@[@2.2f, @3.3f, NSNull.null]];
    [optManaged.doubleObj addObjects:@[@2.2, @3.3, NSNull.null]];
    [optManaged.stringObj addObjects:@[@"a", @"b", NSNull.null]];
    [optManaged.dataObj addObjects:@[data(1), data(2), NSNull.null]];
    [optManaged.dateObj addObjects:@[date(1), date(2), NSNull.null]];

    XCTAssertEqualObjects([unmanaged.boolObj valueForKey:@"self"], (@[@NO, @YES]));
    XCTAssertEqualObjects([unmanaged.intObj valueForKey:@"self"], (@[@2, @3]));
    XCTAssertEqualObjects([unmanaged.floatObj valueForKey:@"self"], (@[@2.2f, @3.3f]));
    XCTAssertEqualObjects([unmanaged.doubleObj valueForKey:@"self"], (@[@2.2, @3.3]));
    XCTAssertEqualObjects([unmanaged.stringObj valueForKey:@"self"], (@[@"a", @"b"]));
    XCTAssertEqualObjects([unmanaged.dataObj valueForKey:@"self"], (@[data(1), data(2)]));
    XCTAssertEqualObjects([unmanaged.dateObj valueForKey:@"self"], (@[date(1), date(2)]));
    XCTAssertEqualObjects([optUnmanaged.boolObj valueForKey:@"self"], (@[@NO, @YES, NSNull.null]));
    XCTAssertEqualObjects([optUnmanaged.intObj valueForKey:@"self"], (@[@2, @3, NSNull.null]));
    XCTAssertEqualObjects([optUnmanaged.floatObj valueForKey:@"self"], (@[@2.2f, @3.3f, NSNull.null]));
    XCTAssertEqualObjects([optUnmanaged.doubleObj valueForKey:@"self"], (@[@2.2, @3.3, NSNull.null]));
    XCTAssertEqualObjects([optUnmanaged.stringObj valueForKey:@"self"], (@[@"a", @"b", NSNull.null]));
    XCTAssertEqualObjects([optUnmanaged.dataObj valueForKey:@"self"], (@[data(1), data(2), NSNull.null]));
    XCTAssertEqualObjects([optUnmanaged.dateObj valueForKey:@"self"], (@[date(1), date(2), NSNull.null]));
    XCTAssertEqualObjects([managed.boolObj valueForKey:@"self"], (@[@NO, @YES]));
    XCTAssertEqualObjects([managed.intObj valueForKey:@"self"], (@[@2, @3]));
    XCTAssertEqualObjects([managed.floatObj valueForKey:@"self"], (@[@2.2f, @3.3f]));
    XCTAssertEqualObjects([managed.doubleObj valueForKey:@"self"], (@[@2.2, @3.3]));
    XCTAssertEqualObjects([managed.stringObj valueForKey:@"self"], (@[@"a", @"b"]));
    XCTAssertEqualObjects([managed.dataObj valueForKey:@"self"], (@[data(1), data(2)]));
    XCTAssertEqualObjects([managed.dateObj valueForKey:@"self"], (@[date(1), date(2)]));
    XCTAssertEqualObjects([optManaged.boolObj valueForKey:@"self"], (@[@NO, @YES, NSNull.null]));
    XCTAssertEqualObjects([optManaged.intObj valueForKey:@"self"], (@[@2, @3, NSNull.null]));
    XCTAssertEqualObjects([optManaged.floatObj valueForKey:@"self"], (@[@2.2f, @3.3f, NSNull.null]));
    XCTAssertEqualObjects([optManaged.doubleObj valueForKey:@"self"], (@[@2.2, @3.3, NSNull.null]));
    XCTAssertEqualObjects([optManaged.stringObj valueForKey:@"self"], (@[@"a", @"b", NSNull.null]));
    XCTAssertEqualObjects([optManaged.dataObj valueForKey:@"self"], (@[data(1), data(2), NSNull.null]));
    XCTAssertEqualObjects([optManaged.dateObj valueForKey:@"self"], (@[date(1), date(2), NSNull.null]));
}

- (void)testValueForKeyNumericAggregates {
    XCTAssertNil([unmanaged.intObj valueForKeyPath:@"@min.self"]);
    XCTAssertNil([unmanaged.floatObj valueForKeyPath:@"@min.self"]);
    XCTAssertNil([unmanaged.doubleObj valueForKeyPath:@"@min.self"]);
    XCTAssertNil([unmanaged.dateObj valueForKeyPath:@"@min.self"]);
    XCTAssertNil([optUnmanaged.intObj valueForKeyPath:@"@min.self"]);
    XCTAssertNil([optUnmanaged.floatObj valueForKeyPath:@"@min.self"]);
    XCTAssertNil([optUnmanaged.doubleObj valueForKeyPath:@"@min.self"]);
    XCTAssertNil([optUnmanaged.dateObj valueForKeyPath:@"@min.self"]);
    XCTAssertNil([managed.intObj valueForKeyPath:@"@min.self"]);
    XCTAssertNil([managed.floatObj valueForKeyPath:@"@min.self"]);
    XCTAssertNil([managed.doubleObj valueForKeyPath:@"@min.self"]);
    XCTAssertNil([managed.dateObj valueForKeyPath:@"@min.self"]);
    XCTAssertNil([optManaged.intObj valueForKeyPath:@"@min.self"]);
    XCTAssertNil([optManaged.floatObj valueForKeyPath:@"@min.self"]);
    XCTAssertNil([optManaged.doubleObj valueForKeyPath:@"@min.self"]);
    XCTAssertNil([optManaged.dateObj valueForKeyPath:@"@min.self"]);
    XCTAssertNil([unmanaged.intObj valueForKeyPath:@"@max.self"]);
    XCTAssertNil([unmanaged.floatObj valueForKeyPath:@"@max.self"]);
    XCTAssertNil([unmanaged.doubleObj valueForKeyPath:@"@max.self"]);
    XCTAssertNil([unmanaged.dateObj valueForKeyPath:@"@max.self"]);
    XCTAssertNil([optUnmanaged.intObj valueForKeyPath:@"@max.self"]);
    XCTAssertNil([optUnmanaged.floatObj valueForKeyPath:@"@max.self"]);
    XCTAssertNil([optUnmanaged.doubleObj valueForKeyPath:@"@max.self"]);
    XCTAssertNil([optUnmanaged.dateObj valueForKeyPath:@"@max.self"]);
    XCTAssertNil([managed.intObj valueForKeyPath:@"@max.self"]);
    XCTAssertNil([managed.floatObj valueForKeyPath:@"@max.self"]);
    XCTAssertNil([managed.doubleObj valueForKeyPath:@"@max.self"]);
    XCTAssertNil([managed.dateObj valueForKeyPath:@"@max.self"]);
    XCTAssertNil([optManaged.intObj valueForKeyPath:@"@max.self"]);
    XCTAssertNil([optManaged.floatObj valueForKeyPath:@"@max.self"]);
    XCTAssertNil([optManaged.doubleObj valueForKeyPath:@"@max.self"]);
    XCTAssertNil([optManaged.dateObj valueForKeyPath:@"@max.self"]);
    XCTAssertEqualObjects([unmanaged.intObj valueForKeyPath:@"@sum.self"], @0);
    XCTAssertEqualObjects([unmanaged.floatObj valueForKeyPath:@"@sum.self"], @0);
    XCTAssertEqualObjects([unmanaged.doubleObj valueForKeyPath:@"@sum.self"], @0);
    XCTAssertEqualObjects([optUnmanaged.intObj valueForKeyPath:@"@sum.self"], @0);
    XCTAssertEqualObjects([optUnmanaged.floatObj valueForKeyPath:@"@sum.self"], @0);
    XCTAssertEqualObjects([optUnmanaged.doubleObj valueForKeyPath:@"@sum.self"], @0);
    XCTAssertEqualObjects([managed.intObj valueForKeyPath:@"@sum.self"], @0);
    XCTAssertEqualObjects([managed.floatObj valueForKeyPath:@"@sum.self"], @0);
    XCTAssertEqualObjects([managed.doubleObj valueForKeyPath:@"@sum.self"], @0);
    XCTAssertEqualObjects([optManaged.intObj valueForKeyPath:@"@sum.self"], @0);
    XCTAssertEqualObjects([optManaged.floatObj valueForKeyPath:@"@sum.self"], @0);
    XCTAssertEqualObjects([optManaged.doubleObj valueForKeyPath:@"@sum.self"], @0);
    XCTAssertNil([unmanaged.intObj valueForKeyPath:@"@avg.self"]);
    XCTAssertNil([unmanaged.floatObj valueForKeyPath:@"@avg.self"]);
    XCTAssertNil([unmanaged.doubleObj valueForKeyPath:@"@avg.self"]);
    XCTAssertNil([optUnmanaged.intObj valueForKeyPath:@"@avg.self"]);
    XCTAssertNil([optUnmanaged.floatObj valueForKeyPath:@"@avg.self"]);
    XCTAssertNil([optUnmanaged.doubleObj valueForKeyPath:@"@avg.self"]);
    XCTAssertNil([managed.intObj valueForKeyPath:@"@avg.self"]);
    XCTAssertNil([managed.floatObj valueForKeyPath:@"@avg.self"]);
    XCTAssertNil([managed.doubleObj valueForKeyPath:@"@avg.self"]);
    XCTAssertNil([optManaged.intObj valueForKeyPath:@"@avg.self"]);
    XCTAssertNil([optManaged.floatObj valueForKeyPath:@"@avg.self"]);
    XCTAssertNil([optManaged.doubleObj valueForKeyPath:@"@avg.self"]);

    [unmanaged.boolObj addObjects:@[@NO, @YES]];
    [unmanaged.intObj addObjects:@[@2, @3]];
    [unmanaged.floatObj addObjects:@[@2.2f, @3.3f]];
    [unmanaged.doubleObj addObjects:@[@2.2, @3.3]];
    [unmanaged.stringObj addObjects:@[@"a", @"b"]];
    [unmanaged.dataObj addObjects:@[data(1), data(2)]];
    [unmanaged.dateObj addObjects:@[date(1), date(2)]];
    [optUnmanaged.boolObj addObjects:@[@NO, @YES, NSNull.null]];
    [optUnmanaged.intObj addObjects:@[@2, @3, NSNull.null]];
    [optUnmanaged.floatObj addObjects:@[@2.2f, @3.3f, NSNull.null]];
    [optUnmanaged.doubleObj addObjects:@[@2.2, @3.3, NSNull.null]];
    [optUnmanaged.stringObj addObjects:@[@"a", @"b", NSNull.null]];
    [optUnmanaged.dataObj addObjects:@[data(1), data(2), NSNull.null]];
    [optUnmanaged.dateObj addObjects:@[date(1), date(2), NSNull.null]];
    [managed.boolObj addObjects:@[@NO, @YES]];
    [managed.intObj addObjects:@[@2, @3]];
    [managed.floatObj addObjects:@[@2.2f, @3.3f]];
    [managed.doubleObj addObjects:@[@2.2, @3.3]];
    [managed.stringObj addObjects:@[@"a", @"b"]];
    [managed.dataObj addObjects:@[data(1), data(2)]];
    [managed.dateObj addObjects:@[date(1), date(2)]];
    [optManaged.boolObj addObjects:@[@NO, @YES, NSNull.null]];
    [optManaged.intObj addObjects:@[@2, @3, NSNull.null]];
    [optManaged.floatObj addObjects:@[@2.2f, @3.3f, NSNull.null]];
    [optManaged.doubleObj addObjects:@[@2.2, @3.3, NSNull.null]];
    [optManaged.stringObj addObjects:@[@"a", @"b", NSNull.null]];
    [optManaged.dataObj addObjects:@[data(1), data(2), NSNull.null]];
    [optManaged.dateObj addObjects:@[date(1), date(2), NSNull.null]];

    XCTAssertEqualObjects([unmanaged.intObj valueForKeyPath:@"@min.self"], @2);
    XCTAssertEqualObjects([unmanaged.floatObj valueForKeyPath:@"@min.self"], @2.2f);
    XCTAssertEqualObjects([unmanaged.doubleObj valueForKeyPath:@"@min.self"], @2.2);
    XCTAssertEqualObjects([unmanaged.dateObj valueForKeyPath:@"@min.self"], date(1));
    XCTAssertEqualObjects([optUnmanaged.intObj valueForKeyPath:@"@min.self"], @2);
    XCTAssertEqualObjects([optUnmanaged.floatObj valueForKeyPath:@"@min.self"], @2.2f);
    XCTAssertEqualObjects([optUnmanaged.doubleObj valueForKeyPath:@"@min.self"], @2.2);
    XCTAssertEqualObjects([optUnmanaged.dateObj valueForKeyPath:@"@min.self"], date(1));
    XCTAssertEqualObjects([managed.intObj valueForKeyPath:@"@min.self"], @2);
    XCTAssertEqualObjects([managed.floatObj valueForKeyPath:@"@min.self"], @2.2f);
    XCTAssertEqualObjects([managed.doubleObj valueForKeyPath:@"@min.self"], @2.2);
    XCTAssertEqualObjects([managed.dateObj valueForKeyPath:@"@min.self"], date(1));
    XCTAssertEqualObjects([optManaged.intObj valueForKeyPath:@"@min.self"], @2);
    XCTAssertEqualObjects([optManaged.floatObj valueForKeyPath:@"@min.self"], @2.2f);
    XCTAssertEqualObjects([optManaged.doubleObj valueForKeyPath:@"@min.self"], @2.2);
    XCTAssertEqualObjects([optManaged.dateObj valueForKeyPath:@"@min.self"], date(1));
    XCTAssertEqualObjects([unmanaged.intObj valueForKeyPath:@"@max.self"], @3);
    XCTAssertEqualObjects([unmanaged.floatObj valueForKeyPath:@"@max.self"], @3.3f);
    XCTAssertEqualObjects([unmanaged.doubleObj valueForKeyPath:@"@max.self"], @3.3);
    XCTAssertEqualObjects([unmanaged.dateObj valueForKeyPath:@"@max.self"], date(2));
    XCTAssertEqualObjects([optUnmanaged.intObj valueForKeyPath:@"@max.self"], @3);
    XCTAssertEqualObjects([optUnmanaged.floatObj valueForKeyPath:@"@max.self"], @3.3f);
    XCTAssertEqualObjects([optUnmanaged.doubleObj valueForKeyPath:@"@max.self"], @3.3);
    XCTAssertEqualObjects([optUnmanaged.dateObj valueForKeyPath:@"@max.self"], date(2));
    XCTAssertEqualObjects([managed.intObj valueForKeyPath:@"@max.self"], @3);
    XCTAssertEqualObjects([managed.floatObj valueForKeyPath:@"@max.self"], @3.3f);
    XCTAssertEqualObjects([managed.doubleObj valueForKeyPath:@"@max.self"], @3.3);
    XCTAssertEqualObjects([managed.dateObj valueForKeyPath:@"@max.self"], date(2));
    XCTAssertEqualObjects([optManaged.intObj valueForKeyPath:@"@max.self"], @3);
    XCTAssertEqualObjects([optManaged.floatObj valueForKeyPath:@"@max.self"], @3.3f);
    XCTAssertEqualObjects([optManaged.doubleObj valueForKeyPath:@"@max.self"], @3.3);
    XCTAssertEqualObjects([optManaged.dateObj valueForKeyPath:@"@max.self"], date(2));
    XCTAssertEqualObjects([unmanaged.intObj valueForKeyPath:@"@sum.self"], @(2 + 3));
    XCTAssertEqualObjects([unmanaged.floatObj valueForKeyPath:@"@sum.self"], @(2.2f + 3.3f));
    XCTAssertEqualObjects([unmanaged.doubleObj valueForKeyPath:@"@sum.self"], @(2.2 + 3.3));
    XCTAssertEqualObjects([optUnmanaged.intObj valueForKeyPath:@"@sum.self"], @(2 + 3));
    XCTAssertEqualObjects([optUnmanaged.floatObj valueForKeyPath:@"@sum.self"], @(2.2f + 3.3f));
    XCTAssertEqualObjects([optUnmanaged.doubleObj valueForKeyPath:@"@sum.self"], @(2.2 + 3.3));
    XCTAssertEqualObjects([managed.intObj valueForKeyPath:@"@sum.self"], @(2 + 3));
    XCTAssertEqualObjects([managed.floatObj valueForKeyPath:@"@sum.self"], @(2.2f + 3.3f));
    XCTAssertEqualObjects([managed.doubleObj valueForKeyPath:@"@sum.self"], @(2.2 + 3.3));
    XCTAssertEqualObjects([optManaged.intObj valueForKeyPath:@"@sum.self"], @(2 + 3));
    XCTAssertEqualObjects([optManaged.floatObj valueForKeyPath:@"@sum.self"], @(2.2f + 3.3f));
    XCTAssertEqualObjects([optManaged.doubleObj valueForKeyPath:@"@sum.self"], @(2.2 + 3.3));
    XCTAssertEqualWithAccuracy([[unmanaged.intObj valueForKeyPath:@"@avg.self"] doubleValue], (2 + 3) / 2.0, .001);
    XCTAssertEqualWithAccuracy([[unmanaged.floatObj valueForKeyPath:@"@avg.self"] doubleValue], (2.2f + 3.3f) / 2.0, .001);
    XCTAssertEqualWithAccuracy([[unmanaged.doubleObj valueForKeyPath:@"@avg.self"] doubleValue], (2.2 + 3.3) / 2.0, .001);
    XCTAssertEqualWithAccuracy([[optUnmanaged.intObj valueForKeyPath:@"@avg.self"] doubleValue], (2 + 3) / 2.0, .001);
    XCTAssertEqualWithAccuracy([[optUnmanaged.floatObj valueForKeyPath:@"@avg.self"] doubleValue], (2.2f + 3.3f) / 2.0, .001);
    XCTAssertEqualWithAccuracy([[optUnmanaged.doubleObj valueForKeyPath:@"@avg.self"] doubleValue], (2.2 + 3.3) / 2.0, .001);
    XCTAssertEqualWithAccuracy([[managed.intObj valueForKeyPath:@"@avg.self"] doubleValue], (2 + 3) / 2.0, .001);
    XCTAssertEqualWithAccuracy([[managed.floatObj valueForKeyPath:@"@avg.self"] doubleValue], (2.2f + 3.3f) / 2.0, .001);
    XCTAssertEqualWithAccuracy([[managed.doubleObj valueForKeyPath:@"@avg.self"] doubleValue], (2.2 + 3.3) / 2.0, .001);
    XCTAssertEqualWithAccuracy([[optManaged.intObj valueForKeyPath:@"@avg.self"] doubleValue], (2 + 3) / 2.0, .001);
    XCTAssertEqualWithAccuracy([[optManaged.floatObj valueForKeyPath:@"@avg.self"] doubleValue], (2.2f + 3.3f) / 2.0, .001);
    XCTAssertEqualWithAccuracy([[optManaged.doubleObj valueForKeyPath:@"@avg.self"] doubleValue], (2.2 + 3.3) / 2.0, .001);
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
    XCTAssertEqualObjects([unmanaged.boolObj valueForKeyPath:@"@unionOfObjects.self"], @[]);
    XCTAssertEqualObjects([unmanaged.intObj valueForKeyPath:@"@unionOfObjects.self"], @[]);
    XCTAssertEqualObjects([unmanaged.floatObj valueForKeyPath:@"@unionOfObjects.self"], @[]);
    XCTAssertEqualObjects([unmanaged.doubleObj valueForKeyPath:@"@unionOfObjects.self"], @[]);
    XCTAssertEqualObjects([unmanaged.stringObj valueForKeyPath:@"@unionOfObjects.self"], @[]);
    XCTAssertEqualObjects([unmanaged.dataObj valueForKeyPath:@"@unionOfObjects.self"], @[]);
    XCTAssertEqualObjects([unmanaged.dateObj valueForKeyPath:@"@unionOfObjects.self"], @[]);
    XCTAssertEqualObjects([optUnmanaged.boolObj valueForKeyPath:@"@unionOfObjects.self"], @[]);
    XCTAssertEqualObjects([optUnmanaged.intObj valueForKeyPath:@"@unionOfObjects.self"], @[]);
    XCTAssertEqualObjects([optUnmanaged.floatObj valueForKeyPath:@"@unionOfObjects.self"], @[]);
    XCTAssertEqualObjects([optUnmanaged.doubleObj valueForKeyPath:@"@unionOfObjects.self"], @[]);
    XCTAssertEqualObjects([optUnmanaged.stringObj valueForKeyPath:@"@unionOfObjects.self"], @[]);
    XCTAssertEqualObjects([optUnmanaged.dataObj valueForKeyPath:@"@unionOfObjects.self"], @[]);
    XCTAssertEqualObjects([optUnmanaged.dateObj valueForKeyPath:@"@unionOfObjects.self"], @[]);
    XCTAssertEqualObjects([managed.boolObj valueForKeyPath:@"@unionOfObjects.self"], @[]);
    XCTAssertEqualObjects([managed.intObj valueForKeyPath:@"@unionOfObjects.self"], @[]);
    XCTAssertEqualObjects([managed.floatObj valueForKeyPath:@"@unionOfObjects.self"], @[]);
    XCTAssertEqualObjects([managed.doubleObj valueForKeyPath:@"@unionOfObjects.self"], @[]);
    XCTAssertEqualObjects([managed.stringObj valueForKeyPath:@"@unionOfObjects.self"], @[]);
    XCTAssertEqualObjects([managed.dataObj valueForKeyPath:@"@unionOfObjects.self"], @[]);
    XCTAssertEqualObjects([managed.dateObj valueForKeyPath:@"@unionOfObjects.self"], @[]);
    XCTAssertEqualObjects([optManaged.boolObj valueForKeyPath:@"@unionOfObjects.self"], @[]);
    XCTAssertEqualObjects([optManaged.intObj valueForKeyPath:@"@unionOfObjects.self"], @[]);
    XCTAssertEqualObjects([optManaged.floatObj valueForKeyPath:@"@unionOfObjects.self"], @[]);
    XCTAssertEqualObjects([optManaged.doubleObj valueForKeyPath:@"@unionOfObjects.self"], @[]);
    XCTAssertEqualObjects([optManaged.stringObj valueForKeyPath:@"@unionOfObjects.self"], @[]);
    XCTAssertEqualObjects([optManaged.dataObj valueForKeyPath:@"@unionOfObjects.self"], @[]);
    XCTAssertEqualObjects([optManaged.dateObj valueForKeyPath:@"@unionOfObjects.self"], @[]);
    XCTAssertEqualObjects([unmanaged.boolObj valueForKeyPath:@"@distinctUnionOfObjects.self"], @[]);
    XCTAssertEqualObjects([unmanaged.intObj valueForKeyPath:@"@distinctUnionOfObjects.self"], @[]);
    XCTAssertEqualObjects([unmanaged.floatObj valueForKeyPath:@"@distinctUnionOfObjects.self"], @[]);
    XCTAssertEqualObjects([unmanaged.doubleObj valueForKeyPath:@"@distinctUnionOfObjects.self"], @[]);
    XCTAssertEqualObjects([unmanaged.stringObj valueForKeyPath:@"@distinctUnionOfObjects.self"], @[]);
    XCTAssertEqualObjects([unmanaged.dataObj valueForKeyPath:@"@distinctUnionOfObjects.self"], @[]);
    XCTAssertEqualObjects([unmanaged.dateObj valueForKeyPath:@"@distinctUnionOfObjects.self"], @[]);
    XCTAssertEqualObjects([optUnmanaged.boolObj valueForKeyPath:@"@distinctUnionOfObjects.self"], @[]);
    XCTAssertEqualObjects([optUnmanaged.intObj valueForKeyPath:@"@distinctUnionOfObjects.self"], @[]);
    XCTAssertEqualObjects([optUnmanaged.floatObj valueForKeyPath:@"@distinctUnionOfObjects.self"], @[]);
    XCTAssertEqualObjects([optUnmanaged.doubleObj valueForKeyPath:@"@distinctUnionOfObjects.self"], @[]);
    XCTAssertEqualObjects([optUnmanaged.stringObj valueForKeyPath:@"@distinctUnionOfObjects.self"], @[]);
    XCTAssertEqualObjects([optUnmanaged.dataObj valueForKeyPath:@"@distinctUnionOfObjects.self"], @[]);
    XCTAssertEqualObjects([optUnmanaged.dateObj valueForKeyPath:@"@distinctUnionOfObjects.self"], @[]);
    XCTAssertEqualObjects([managed.boolObj valueForKeyPath:@"@distinctUnionOfObjects.self"], @[]);
    XCTAssertEqualObjects([managed.intObj valueForKeyPath:@"@distinctUnionOfObjects.self"], @[]);
    XCTAssertEqualObjects([managed.floatObj valueForKeyPath:@"@distinctUnionOfObjects.self"], @[]);
    XCTAssertEqualObjects([managed.doubleObj valueForKeyPath:@"@distinctUnionOfObjects.self"], @[]);
    XCTAssertEqualObjects([managed.stringObj valueForKeyPath:@"@distinctUnionOfObjects.self"], @[]);
    XCTAssertEqualObjects([managed.dataObj valueForKeyPath:@"@distinctUnionOfObjects.self"], @[]);
    XCTAssertEqualObjects([managed.dateObj valueForKeyPath:@"@distinctUnionOfObjects.self"], @[]);
    XCTAssertEqualObjects([optManaged.boolObj valueForKeyPath:@"@distinctUnionOfObjects.self"], @[]);
    XCTAssertEqualObjects([optManaged.intObj valueForKeyPath:@"@distinctUnionOfObjects.self"], @[]);
    XCTAssertEqualObjects([optManaged.floatObj valueForKeyPath:@"@distinctUnionOfObjects.self"], @[]);
    XCTAssertEqualObjects([optManaged.doubleObj valueForKeyPath:@"@distinctUnionOfObjects.self"], @[]);
    XCTAssertEqualObjects([optManaged.stringObj valueForKeyPath:@"@distinctUnionOfObjects.self"], @[]);
    XCTAssertEqualObjects([optManaged.dataObj valueForKeyPath:@"@distinctUnionOfObjects.self"], @[]);
    XCTAssertEqualObjects([optManaged.dateObj valueForKeyPath:@"@distinctUnionOfObjects.self"], @[]);

    [unmanaged.boolObj addObjects:@[@NO, @YES, @NO, @YES]];
    [unmanaged.intObj addObjects:@[@2, @3, @2, @3]];
    [unmanaged.floatObj addObjects:@[@2.2f, @3.3f, @2.2f, @3.3f]];
    [unmanaged.doubleObj addObjects:@[@2.2, @3.3, @2.2, @3.3]];
    [unmanaged.stringObj addObjects:@[@"a", @"b", @"a", @"b"]];
    [unmanaged.dataObj addObjects:@[data(1), data(2), data(1), data(2)]];
    [unmanaged.dateObj addObjects:@[date(1), date(2), date(1), date(2)]];
    [optUnmanaged.boolObj addObjects:@[@NO, @YES, NSNull.null, @NO, @YES, NSNull.null]];
    [optUnmanaged.intObj addObjects:@[@2, @3, NSNull.null, @2, @3, NSNull.null]];
    [optUnmanaged.floatObj addObjects:@[@2.2f, @3.3f, NSNull.null, @2.2f, @3.3f, NSNull.null]];
    [optUnmanaged.doubleObj addObjects:@[@2.2, @3.3, NSNull.null, @2.2, @3.3, NSNull.null]];
    [optUnmanaged.stringObj addObjects:@[@"a", @"b", NSNull.null, @"a", @"b", NSNull.null]];
    [optUnmanaged.dataObj addObjects:@[data(1), data(2), NSNull.null, data(1), data(2), NSNull.null]];
    [optUnmanaged.dateObj addObjects:@[date(1), date(2), NSNull.null, date(1), date(2), NSNull.null]];
    [managed.boolObj addObjects:@[@NO, @YES, @NO, @YES]];
    [managed.intObj addObjects:@[@2, @3, @2, @3]];
    [managed.floatObj addObjects:@[@2.2f, @3.3f, @2.2f, @3.3f]];
    [managed.doubleObj addObjects:@[@2.2, @3.3, @2.2, @3.3]];
    [managed.stringObj addObjects:@[@"a", @"b", @"a", @"b"]];
    [managed.dataObj addObjects:@[data(1), data(2), data(1), data(2)]];
    [managed.dateObj addObjects:@[date(1), date(2), date(1), date(2)]];
    [optManaged.boolObj addObjects:@[@NO, @YES, NSNull.null, @NO, @YES, NSNull.null]];
    [optManaged.intObj addObjects:@[@2, @3, NSNull.null, @2, @3, NSNull.null]];
    [optManaged.floatObj addObjects:@[@2.2f, @3.3f, NSNull.null, @2.2f, @3.3f, NSNull.null]];
    [optManaged.doubleObj addObjects:@[@2.2, @3.3, NSNull.null, @2.2, @3.3, NSNull.null]];
    [optManaged.stringObj addObjects:@[@"a", @"b", NSNull.null, @"a", @"b", NSNull.null]];
    [optManaged.dataObj addObjects:@[data(1), data(2), NSNull.null, data(1), data(2), NSNull.null]];
    [optManaged.dateObj addObjects:@[date(1), date(2), NSNull.null, date(1), date(2), NSNull.null]];

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
    XCTAssertEqualObjects([allOptional valueForKeyPath:@"@unionOfArrays.boolObj"], @[]);
    XCTAssertEqualObjects([allOptional valueForKeyPath:@"@unionOfArrays.intObj"], @[]);
    XCTAssertEqualObjects([allOptional valueForKeyPath:@"@unionOfArrays.floatObj"], @[]);
    XCTAssertEqualObjects([allOptional valueForKeyPath:@"@unionOfArrays.doubleObj"], @[]);
    XCTAssertEqualObjects([allOptional valueForKeyPath:@"@unionOfArrays.stringObj"], @[]);
    XCTAssertEqualObjects([allOptional valueForKeyPath:@"@unionOfArrays.dataObj"], @[]);
    XCTAssertEqualObjects([allOptional valueForKeyPath:@"@unionOfArrays.dateObj"], @[]);
    XCTAssertEqualObjects([allRequired valueForKeyPath:@"@distinctUnionOfArrays.boolObj"], @[]);
    XCTAssertEqualObjects([allRequired valueForKeyPath:@"@distinctUnionOfArrays.intObj"], @[]);
    XCTAssertEqualObjects([allRequired valueForKeyPath:@"@distinctUnionOfArrays.floatObj"], @[]);
    XCTAssertEqualObjects([allRequired valueForKeyPath:@"@distinctUnionOfArrays.doubleObj"], @[]);
    XCTAssertEqualObjects([allRequired valueForKeyPath:@"@distinctUnionOfArrays.stringObj"], @[]);
    XCTAssertEqualObjects([allRequired valueForKeyPath:@"@distinctUnionOfArrays.dataObj"], @[]);
    XCTAssertEqualObjects([allRequired valueForKeyPath:@"@distinctUnionOfArrays.dateObj"], @[]);
    XCTAssertEqualObjects([allOptional valueForKeyPath:@"@distinctUnionOfArrays.boolObj"], @[]);
    XCTAssertEqualObjects([allOptional valueForKeyPath:@"@distinctUnionOfArrays.intObj"], @[]);
    XCTAssertEqualObjects([allOptional valueForKeyPath:@"@distinctUnionOfArrays.floatObj"], @[]);
    XCTAssertEqualObjects([allOptional valueForKeyPath:@"@distinctUnionOfArrays.doubleObj"], @[]);
    XCTAssertEqualObjects([allOptional valueForKeyPath:@"@distinctUnionOfArrays.stringObj"], @[]);
    XCTAssertEqualObjects([allOptional valueForKeyPath:@"@distinctUnionOfArrays.dataObj"], @[]);
    XCTAssertEqualObjects([allOptional valueForKeyPath:@"@distinctUnionOfArrays.dateObj"], @[]);

    [unmanaged.boolObj addObjects:@[@NO, @YES]];
    [unmanaged.intObj addObjects:@[@2, @3]];
    [unmanaged.floatObj addObjects:@[@2.2f, @3.3f]];
    [unmanaged.doubleObj addObjects:@[@2.2, @3.3]];
    [unmanaged.stringObj addObjects:@[@"a", @"b"]];
    [unmanaged.dataObj addObjects:@[data(1), data(2)]];
    [unmanaged.dateObj addObjects:@[date(1), date(2)]];
    [optUnmanaged.boolObj addObjects:@[@NO, @YES, NSNull.null]];
    [optUnmanaged.intObj addObjects:@[@2, @3, NSNull.null]];
    [optUnmanaged.floatObj addObjects:@[@2.2f, @3.3f, NSNull.null]];
    [optUnmanaged.doubleObj addObjects:@[@2.2, @3.3, NSNull.null]];
    [optUnmanaged.stringObj addObjects:@[@"a", @"b", NSNull.null]];
    [optUnmanaged.dataObj addObjects:@[data(1), data(2), NSNull.null]];
    [optUnmanaged.dateObj addObjects:@[date(1), date(2), NSNull.null]];
    [managed.boolObj addObjects:@[@NO, @YES]];
    [managed.intObj addObjects:@[@2, @3]];
    [managed.floatObj addObjects:@[@2.2f, @3.3f]];
    [managed.doubleObj addObjects:@[@2.2, @3.3]];
    [managed.stringObj addObjects:@[@"a", @"b"]];
    [managed.dataObj addObjects:@[data(1), data(2)]];
    [managed.dateObj addObjects:@[date(1), date(2)]];
    [optManaged.boolObj addObjects:@[@NO, @YES, NSNull.null]];
    [optManaged.intObj addObjects:@[@2, @3, NSNull.null]];
    [optManaged.floatObj addObjects:@[@2.2f, @3.3f, NSNull.null]];
    [optManaged.doubleObj addObjects:@[@2.2, @3.3, NSNull.null]];
    [optManaged.stringObj addObjects:@[@"a", @"b", NSNull.null]];
    [optManaged.dataObj addObjects:@[data(1), data(2), NSNull.null]];
    [optManaged.dateObj addObjects:@[date(1), date(2), NSNull.null]];

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
}

- (void)testSetValueForKey {
    RLMAssertThrowsWithReason([unmanaged.boolObj setValue:@0 forKey:@"not self"],
                              @"this class is not key value coding-compliant for the key not self.");
    RLMAssertThrowsWithReason([unmanaged.intObj setValue:@0 forKey:@"not self"],
                              @"this class is not key value coding-compliant for the key not self.");
    RLMAssertThrowsWithReason([unmanaged.floatObj setValue:@0 forKey:@"not self"],
                              @"this class is not key value coding-compliant for the key not self.");
    RLMAssertThrowsWithReason([unmanaged.doubleObj setValue:@0 forKey:@"not self"],
                              @"this class is not key value coding-compliant for the key not self.");
    RLMAssertThrowsWithReason([unmanaged.stringObj setValue:@0 forKey:@"not self"],
                              @"this class is not key value coding-compliant for the key not self.");
    RLMAssertThrowsWithReason([unmanaged.dataObj setValue:@0 forKey:@"not self"],
                              @"this class is not key value coding-compliant for the key not self.");
    RLMAssertThrowsWithReason([unmanaged.dateObj setValue:@0 forKey:@"not self"],
                              @"this class is not key value coding-compliant for the key not self.");
    RLMAssertThrowsWithReason([optUnmanaged.boolObj setValue:@0 forKey:@"not self"],
                              @"this class is not key value coding-compliant for the key not self.");
    RLMAssertThrowsWithReason([optUnmanaged.intObj setValue:@0 forKey:@"not self"],
                              @"this class is not key value coding-compliant for the key not self.");
    RLMAssertThrowsWithReason([optUnmanaged.floatObj setValue:@0 forKey:@"not self"],
                              @"this class is not key value coding-compliant for the key not self.");
    RLMAssertThrowsWithReason([optUnmanaged.doubleObj setValue:@0 forKey:@"not self"],
                              @"this class is not key value coding-compliant for the key not self.");
    RLMAssertThrowsWithReason([optUnmanaged.stringObj setValue:@0 forKey:@"not self"],
                              @"this class is not key value coding-compliant for the key not self.");
    RLMAssertThrowsWithReason([optUnmanaged.dataObj setValue:@0 forKey:@"not self"],
                              @"this class is not key value coding-compliant for the key not self.");
    RLMAssertThrowsWithReason([optUnmanaged.dateObj setValue:@0 forKey:@"not self"],
                              @"this class is not key value coding-compliant for the key not self.");
    RLMAssertThrowsWithReason([managed.boolObj setValue:@0 forKey:@"not self"],
                              @"this class is not key value coding-compliant for the key not self.");
    RLMAssertThrowsWithReason([managed.intObj setValue:@0 forKey:@"not self"],
                              @"this class is not key value coding-compliant for the key not self.");
    RLMAssertThrowsWithReason([managed.floatObj setValue:@0 forKey:@"not self"],
                              @"this class is not key value coding-compliant for the key not self.");
    RLMAssertThrowsWithReason([managed.doubleObj setValue:@0 forKey:@"not self"],
                              @"this class is not key value coding-compliant for the key not self.");
    RLMAssertThrowsWithReason([managed.stringObj setValue:@0 forKey:@"not self"],
                              @"this class is not key value coding-compliant for the key not self.");
    RLMAssertThrowsWithReason([managed.dataObj setValue:@0 forKey:@"not self"],
                              @"this class is not key value coding-compliant for the key not self.");
    RLMAssertThrowsWithReason([managed.dateObj setValue:@0 forKey:@"not self"],
                              @"this class is not key value coding-compliant for the key not self.");
    RLMAssertThrowsWithReason([optManaged.boolObj setValue:@0 forKey:@"not self"],
                              @"this class is not key value coding-compliant for the key not self.");
    RLMAssertThrowsWithReason([optManaged.intObj setValue:@0 forKey:@"not self"],
                              @"this class is not key value coding-compliant for the key not self.");
    RLMAssertThrowsWithReason([optManaged.floatObj setValue:@0 forKey:@"not self"],
                              @"this class is not key value coding-compliant for the key not self.");
    RLMAssertThrowsWithReason([optManaged.doubleObj setValue:@0 forKey:@"not self"],
                              @"this class is not key value coding-compliant for the key not self.");
    RLMAssertThrowsWithReason([optManaged.stringObj setValue:@0 forKey:@"not self"],
                              @"this class is not key value coding-compliant for the key not self.");
    RLMAssertThrowsWithReason([optManaged.dataObj setValue:@0 forKey:@"not self"],
                              @"this class is not key value coding-compliant for the key not self.");
    RLMAssertThrowsWithReason([optManaged.dateObj setValue:@0 forKey:@"not self"],
                              @"this class is not key value coding-compliant for the key not self.");
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

    [unmanaged.boolObj addObjects:@[@NO, @YES]];
    [unmanaged.intObj addObjects:@[@2, @3]];
    [unmanaged.floatObj addObjects:@[@2.2f, @3.3f]];
    [unmanaged.doubleObj addObjects:@[@2.2, @3.3]];
    [unmanaged.stringObj addObjects:@[@"a", @"b"]];
    [unmanaged.dataObj addObjects:@[data(1), data(2)]];
    [unmanaged.dateObj addObjects:@[date(1), date(2)]];
    [optUnmanaged.boolObj addObjects:@[@NO, @YES, NSNull.null]];
    [optUnmanaged.intObj addObjects:@[@2, @3, NSNull.null]];
    [optUnmanaged.floatObj addObjects:@[@2.2f, @3.3f, NSNull.null]];
    [optUnmanaged.doubleObj addObjects:@[@2.2, @3.3, NSNull.null]];
    [optUnmanaged.stringObj addObjects:@[@"a", @"b", NSNull.null]];
    [optUnmanaged.dataObj addObjects:@[data(1), data(2), NSNull.null]];
    [optUnmanaged.dateObj addObjects:@[date(1), date(2), NSNull.null]];
    [managed.boolObj addObjects:@[@NO, @YES]];
    [managed.intObj addObjects:@[@2, @3]];
    [managed.floatObj addObjects:@[@2.2f, @3.3f]];
    [managed.doubleObj addObjects:@[@2.2, @3.3]];
    [managed.stringObj addObjects:@[@"a", @"b"]];
    [managed.dataObj addObjects:@[data(1), data(2)]];
    [managed.dateObj addObjects:@[date(1), date(2)]];
    [optManaged.boolObj addObjects:@[@NO, @YES, NSNull.null]];
    [optManaged.intObj addObjects:@[@2, @3, NSNull.null]];
    [optManaged.floatObj addObjects:@[@2.2f, @3.3f, NSNull.null]];
    [optManaged.doubleObj addObjects:@[@2.2, @3.3, NSNull.null]];
    [optManaged.stringObj addObjects:@[@"a", @"b", NSNull.null]];
    [optManaged.dataObj addObjects:@[data(1), data(2), NSNull.null]];
    [optManaged.dateObj addObjects:@[date(1), date(2), NSNull.null]];

    [unmanaged.boolObj setValue:@NO forKey:@"self"];
    [unmanaged.intObj setValue:@2 forKey:@"self"];
    [unmanaged.floatObj setValue:@2.2f forKey:@"self"];
    [unmanaged.doubleObj setValue:@2.2 forKey:@"self"];
    [unmanaged.stringObj setValue:@"a" forKey:@"self"];
    [unmanaged.dataObj setValue:data(1) forKey:@"self"];
    [unmanaged.dateObj setValue:date(1) forKey:@"self"];
    [optUnmanaged.boolObj setValue:@NO forKey:@"self"];
    [optUnmanaged.intObj setValue:@2 forKey:@"self"];
    [optUnmanaged.floatObj setValue:@2.2f forKey:@"self"];
    [optUnmanaged.doubleObj setValue:@2.2 forKey:@"self"];
    [optUnmanaged.stringObj setValue:@"a" forKey:@"self"];
    [optUnmanaged.dataObj setValue:data(1) forKey:@"self"];
    [optUnmanaged.dateObj setValue:date(1) forKey:@"self"];
    [managed.boolObj setValue:@NO forKey:@"self"];
    [managed.intObj setValue:@2 forKey:@"self"];
    [managed.floatObj setValue:@2.2f forKey:@"self"];
    [managed.doubleObj setValue:@2.2 forKey:@"self"];
    [managed.stringObj setValue:@"a" forKey:@"self"];
    [managed.dataObj setValue:data(1) forKey:@"self"];
    [managed.dateObj setValue:date(1) forKey:@"self"];
    [optManaged.boolObj setValue:@NO forKey:@"self"];
    [optManaged.intObj setValue:@2 forKey:@"self"];
    [optManaged.floatObj setValue:@2.2f forKey:@"self"];
    [optManaged.doubleObj setValue:@2.2 forKey:@"self"];
    [optManaged.stringObj setValue:@"a" forKey:@"self"];
    [optManaged.dataObj setValue:data(1) forKey:@"self"];
    [optManaged.dateObj setValue:date(1) forKey:@"self"];

    XCTAssertEqualObjects(unmanaged.boolObj[0], @NO);
    XCTAssertEqualObjects(unmanaged.intObj[0], @2);
    XCTAssertEqualObjects(unmanaged.floatObj[0], @2.2f);
    XCTAssertEqualObjects(unmanaged.doubleObj[0], @2.2);
    XCTAssertEqualObjects(unmanaged.stringObj[0], @"a");
    XCTAssertEqualObjects(unmanaged.dataObj[0], data(1));
    XCTAssertEqualObjects(unmanaged.dateObj[0], date(1));
    XCTAssertEqualObjects(optUnmanaged.boolObj[0], @NO);
    XCTAssertEqualObjects(optUnmanaged.intObj[0], @2);
    XCTAssertEqualObjects(optUnmanaged.floatObj[0], @2.2f);
    XCTAssertEqualObjects(optUnmanaged.doubleObj[0], @2.2);
    XCTAssertEqualObjects(optUnmanaged.stringObj[0], @"a");
    XCTAssertEqualObjects(optUnmanaged.dataObj[0], data(1));
    XCTAssertEqualObjects(optUnmanaged.dateObj[0], date(1));
    XCTAssertEqualObjects(managed.boolObj[0], @NO);
    XCTAssertEqualObjects(managed.intObj[0], @2);
    XCTAssertEqualObjects(managed.floatObj[0], @2.2f);
    XCTAssertEqualObjects(managed.doubleObj[0], @2.2);
    XCTAssertEqualObjects(managed.stringObj[0], @"a");
    XCTAssertEqualObjects(managed.dataObj[0], data(1));
    XCTAssertEqualObjects(managed.dateObj[0], date(1));
    XCTAssertEqualObjects(optManaged.boolObj[0], @NO);
    XCTAssertEqualObjects(optManaged.intObj[0], @2);
    XCTAssertEqualObjects(optManaged.floatObj[0], @2.2f);
    XCTAssertEqualObjects(optManaged.doubleObj[0], @2.2);
    XCTAssertEqualObjects(optManaged.stringObj[0], @"a");
    XCTAssertEqualObjects(optManaged.dataObj[0], data(1));
    XCTAssertEqualObjects(optManaged.dateObj[0], date(1));
    XCTAssertEqualObjects(unmanaged.boolObj[1], @NO);
    XCTAssertEqualObjects(unmanaged.intObj[1], @2);
    XCTAssertEqualObjects(unmanaged.floatObj[1], @2.2f);
    XCTAssertEqualObjects(unmanaged.doubleObj[1], @2.2);
    XCTAssertEqualObjects(unmanaged.stringObj[1], @"a");
    XCTAssertEqualObjects(unmanaged.dataObj[1], data(1));
    XCTAssertEqualObjects(unmanaged.dateObj[1], date(1));
    XCTAssertEqualObjects(optUnmanaged.boolObj[1], @NO);
    XCTAssertEqualObjects(optUnmanaged.intObj[1], @2);
    XCTAssertEqualObjects(optUnmanaged.floatObj[1], @2.2f);
    XCTAssertEqualObjects(optUnmanaged.doubleObj[1], @2.2);
    XCTAssertEqualObjects(optUnmanaged.stringObj[1], @"a");
    XCTAssertEqualObjects(optUnmanaged.dataObj[1], data(1));
    XCTAssertEqualObjects(optUnmanaged.dateObj[1], date(1));
    XCTAssertEqualObjects(managed.boolObj[1], @NO);
    XCTAssertEqualObjects(managed.intObj[1], @2);
    XCTAssertEqualObjects(managed.floatObj[1], @2.2f);
    XCTAssertEqualObjects(managed.doubleObj[1], @2.2);
    XCTAssertEqualObjects(managed.stringObj[1], @"a");
    XCTAssertEqualObjects(managed.dataObj[1], data(1));
    XCTAssertEqualObjects(managed.dateObj[1], date(1));
    XCTAssertEqualObjects(optManaged.boolObj[1], @NO);
    XCTAssertEqualObjects(optManaged.intObj[1], @2);
    XCTAssertEqualObjects(optManaged.floatObj[1], @2.2f);
    XCTAssertEqualObjects(optManaged.doubleObj[1], @2.2);
    XCTAssertEqualObjects(optManaged.stringObj[1], @"a");
    XCTAssertEqualObjects(optManaged.dataObj[1], data(1));
    XCTAssertEqualObjects(optManaged.dateObj[1], date(1));
    XCTAssertEqualObjects(optUnmanaged.boolObj[2], @NO);
    XCTAssertEqualObjects(optUnmanaged.intObj[2], @2);
    XCTAssertEqualObjects(optUnmanaged.floatObj[2], @2.2f);
    XCTAssertEqualObjects(optUnmanaged.doubleObj[2], @2.2);
    XCTAssertEqualObjects(optUnmanaged.stringObj[2], @"a");
    XCTAssertEqualObjects(optUnmanaged.dataObj[2], data(1));
    XCTAssertEqualObjects(optUnmanaged.dateObj[2], date(1));
    XCTAssertEqualObjects(optManaged.boolObj[2], @NO);
    XCTAssertEqualObjects(optManaged.intObj[2], @2);
    XCTAssertEqualObjects(optManaged.floatObj[2], @2.2f);
    XCTAssertEqualObjects(optManaged.doubleObj[2], @2.2);
    XCTAssertEqualObjects(optManaged.stringObj[2], @"a");
    XCTAssertEqualObjects(optManaged.dataObj[2], data(1));
    XCTAssertEqualObjects(optManaged.dateObj[2], date(1));

    [optUnmanaged.boolObj setValue:NSNull.null forKey:@"self"];
    [optUnmanaged.intObj setValue:NSNull.null forKey:@"self"];
    [optUnmanaged.floatObj setValue:NSNull.null forKey:@"self"];
    [optUnmanaged.doubleObj setValue:NSNull.null forKey:@"self"];
    [optUnmanaged.stringObj setValue:NSNull.null forKey:@"self"];
    [optUnmanaged.dataObj setValue:NSNull.null forKey:@"self"];
    [optUnmanaged.dateObj setValue:NSNull.null forKey:@"self"];
    [optManaged.boolObj setValue:NSNull.null forKey:@"self"];
    [optManaged.intObj setValue:NSNull.null forKey:@"self"];
    [optManaged.floatObj setValue:NSNull.null forKey:@"self"];
    [optManaged.doubleObj setValue:NSNull.null forKey:@"self"];
    [optManaged.stringObj setValue:NSNull.null forKey:@"self"];
    [optManaged.dataObj setValue:NSNull.null forKey:@"self"];
    [optManaged.dateObj setValue:NSNull.null forKey:@"self"];
    XCTAssertEqualObjects(optUnmanaged.boolObj[0], NSNull.null);
    XCTAssertEqualObjects(optUnmanaged.intObj[0], NSNull.null);
    XCTAssertEqualObjects(optUnmanaged.floatObj[0], NSNull.null);
    XCTAssertEqualObjects(optUnmanaged.doubleObj[0], NSNull.null);
    XCTAssertEqualObjects(optUnmanaged.stringObj[0], NSNull.null);
    XCTAssertEqualObjects(optUnmanaged.dataObj[0], NSNull.null);
    XCTAssertEqualObjects(optUnmanaged.dateObj[0], NSNull.null);
    XCTAssertEqualObjects(optManaged.boolObj[0], NSNull.null);
    XCTAssertEqualObjects(optManaged.intObj[0], NSNull.null);
    XCTAssertEqualObjects(optManaged.floatObj[0], NSNull.null);
    XCTAssertEqualObjects(optManaged.doubleObj[0], NSNull.null);
    XCTAssertEqualObjects(optManaged.stringObj[0], NSNull.null);
    XCTAssertEqualObjects(optManaged.dataObj[0], NSNull.null);
    XCTAssertEqualObjects(optManaged.dateObj[0], NSNull.null);
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
