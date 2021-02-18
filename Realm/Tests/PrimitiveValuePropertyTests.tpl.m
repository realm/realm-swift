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

@interface RLMValuePropertyTests : RLMTestCase
@end

@implementation RLMValuePropertyTests {
    AllPrimitiveValues *unmanaged;
    AllPrimitiveValues *managed;
    AllOptionalPrimitiveValues *optUnmanaged;
    AllOptionalPrimitiveValues *optManaged;
    RLMRealm *realm;
    RLMArray<RLMValue> *allValues;
//    NSArray<RLMValue> *allValues;
}

- (void)setUp {
    unmanaged = [[AllPrimitiveValues alloc] init];
    optUnmanaged = [[AllOptionalPrimitiveValues alloc] init];
    realm = [RLMRealm defaultRealm];
    [realm beginWriteTransaction];
    managed = [AllPrimitiveValues createInRealm:realm withValue:@[]];
    optManaged = [AllOptionalPrimitiveValues createInRealm:realm withValue:@[]];
    [self assignValues];
//    anyarray = @[
//        $rlmValue,
//    ];
    [allValues addObjects:@[
        $rlmValue,
    ]];
}

- (void)tearDown {
    if (realm.inWriteTransaction) {
        [realm cancelWriteTransaction];
    }
}

- (void)assignValues {
    $rlmValue = $value0;
}

// !!! don't forget to add count of rlmValue in array tests

// Dummy test
- (void)testTrue {
    XCTAssert(true);
}

- (void)testType {
    XCTAssertEqual(unmanaged.boolObj.valueType, RLMPropertyTypeBool);
    XCTAssertEqual(unmanaged.intObj.valueType, RLMPropertyTypeInt);
    XCTAssertEqual(unmanaged.floatObj.valueType, RLMPropertyTypeFloat);
    XCTAssertEqual(unmanaged.doubleObj.valueType, RLMPropertyTypeDouble);
    XCTAssertEqual(unmanaged.stringObj.valueType, RLMPropertyTypeString);
    XCTAssertEqual(unmanaged.dataObj.valueType, RLMPropertyTypeData);
    XCTAssertEqual(unmanaged.dateObj.valueType, RLMPropertyTypeDate);
    XCTAssertEqual(optUnmanaged.boolObj.valueType, RLMPropertyTypeBool);
    XCTAssertEqual(optUnmanaged.intObj.valueType, RLMPropertyTypeInt);
    XCTAssertEqual(optUnmanaged.floatObj.valueType, RLMPropertyTypeFloat);
    XCTAssertEqual(optUnmanaged.doubleObj.valueType, RLMPropertyTypeDouble);
    XCTAssertEqual(optUnmanaged.stringObj.valueType, RLMPropertyTypeString);
    XCTAssertEqual(optUnmanaged.dataObj.valueType, RLMPropertyTypeData);
    XCTAssertEqual(optUnmanaged.dateObj.valueType, RLMPropertyTypeDate);
}

// @Lee How is nullability with RLMValue supposed to work?
//- (void)testOptional {
//    XCTAssertFalse(unmanaged.boolObj.optional);
//    XCTAssertFalse(unmanaged.intObj.optional);
//    XCTAssertFalse(unmanaged.floatObj.optional);
//    XCTAssertFalse(unmanaged.doubleObj.optional);
//    XCTAssertFalse(unmanaged.stringObj.optional);
//    XCTAssertFalse(unmanaged.dataObj.optional);
//    XCTAssertFalse(unmanaged.dateObj.optional);
//    XCTAssertTrue(optUnmanaged.boolObj.optional);
//    XCTAssertTrue(optUnmanaged.intObj.optional);
//    XCTAssertTrue(optUnmanaged.floatObj.optional);
//    XCTAssertTrue(optUnmanaged.doubleObj.optional);
//    XCTAssertTrue(optUnmanaged.stringObj.optional);
//    XCTAssertTrue(optUnmanaged.dataObj.optional);
//    XCTAssertTrue(optUnmanaged.dateObj.optional);
//}

// @Lee, I need to double that the concept of "invlaidation" doesn't extend to RLMValue?
//- (void)testInvalidated {
//    id<RLMValue> *value;
//    @autoreleasepool {
//        AllPrimitiveValues *obj = [[AllPrimitiveValues alloc] init];
//        value = obj.intObj;
//        XCTAssertFalse(value.invalidated); // Property 'invalidated' not found on object of type '__strong id<RLMValue>'
//    }
//    XCTAssertFalse(value.invalidated); // Property 'invalidated' not found on object of type '__strong id<RLMValue>'
//}

- (void)testUpdateValue {
    %b XCTAssert([(NSNumber *)$rlmValue.boolValue isEqual:$value0]);
    %n XCTAssert([(NSNumber *)$rlmValue isEqual:$value0]);
    
    $rlmValue = $value1);
    
    %b XCTAssert([$rlmValue isEqual:$value0]);
    %n XCTAssert([(NSNumber *)$rlmValue isEqual:$value1]);
}

//- (void)testContainsValue {
//    XCTAssertFalse($value == $v0);
//    $value = $v0;
//    XCTAssertTrue($value == $v0);
//}
//

@end
