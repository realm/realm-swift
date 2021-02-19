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
#include <objc/runtime.h>

#define objc_dynamic_cast(obj, cls) \
    ([obj isKindOfClass:(Class)objc_getClass(#cls)] ? (cls *)obj : NULL)

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

static NSArray *shiftArray(NSArray *array, NSInteger pos)
{
    NSInteger length = [array count];
    NSArray *post = [array subarrayWithRange:(NSRange){ .location = length - pos, .length = pos }];
    NSArray *pre = [array subarrayWithRange:(NSRange){ .location = 0, .length = length - pos}];
    return [post arrayByAddingObjectsFromArray:pre];
}

@interface RLMValuePropertyTests : RLMTestCase
@end

@implementation RLMValuePropertyTests {
    AllPrimitiveRLMValues *unmanaged;
    AllPrimitiveRLMValues *managed;
    RLMRealm *realm;
    RLMArray<RLMValue> *allMixed;
    NSArray *allVals;
}

- (void)setUp {
    realm = [RLMRealm defaultRealm];
    [realm beginWriteTransaction];
    [self initValues];
//    [self assignValues];
    [allMixed addObjects:@[
        $rlmValue,
    ]];
}

- (void)tearDown {
    if (realm.inWriteTransaction) {
        [realm cancelWriteTransaction];
    }
}

- (void)assignValue:(id)value {
    $rlmValue = value;
}

- (void)resetValues:(AllPrimitiveRLMValues *)mixed {
    $rlmValue = $value0;
    
    XCTAssert([$cast$rlmValue isEqual:$value0]);
    XCTAssert([$cast$rlmValue isEqual:$value0]);
}

// !!! don't forget to add count of rlmValue in array tests

// Dummy test
- (void)testTrue {
    XCTAssert(true);
}

- (void)initValues {
    unmanaged = [[AllPrimitiveRLMValues alloc] initWithValue:@{
        %unman @"$member": $value0,
    }];
    XCTAssertNil(unmanaged.realm);
    
    managed = [AllPrimitiveRLMValues createInRealm:realm withValue:@{
        %man @"$member": $value0,
    }];
    XCTAssertNotNil(managed.realm);
    
    %unman XCTAssert([$cast$rlmValue isEqual:$value0]);
    %man XCTAssert([$cast$rlmValue isEqual:$value0]);
}

- (void)testType {
    XCTAssertEqual(unmanaged.boolVal.valueType, RLMPropertyTypeBool);
    XCTAssertEqual(unmanaged.intVal.valueType, RLMPropertyTypeInt);
    XCTAssertEqual(unmanaged.floatVal.valueType, RLMPropertyTypeFloat);
    XCTAssertEqual(unmanaged.doubleVal.valueType, RLMPropertyTypeDouble);
    XCTAssertEqual(unmanaged.stringVal.valueType, RLMPropertyTypeString);
    XCTAssertEqual(unmanaged.dataVal.valueType, RLMPropertyTypeData);
    XCTAssertEqual(unmanaged.dateVal.valueType, RLMPropertyTypeDate);
    XCTAssertEqual(managed.boolVal.valueType, RLMPropertyTypeBool);
    XCTAssertEqual(managed.intVal.valueType, RLMPropertyTypeInt);
    XCTAssertEqual(managed.floatVal.valueType, RLMPropertyTypeFloat);
    XCTAssertEqual(managed.doubleVal.valueType, RLMPropertyTypeDouble);
    XCTAssertEqual(managed.stringVal.valueType, RLMPropertyTypeString);
    XCTAssertEqual(managed.dataVal.valueType, RLMPropertyTypeData);
    XCTAssertEqual(managed.dateVal.valueType, RLMPropertyTypeDate);
}

- (void)testInitNull {
    AllPrimitiveRLMValues *unman = [[AllPrimitiveRLMValues alloc] init];
    AllPrimitiveRLMValues *man = [AllPrimitiveRLMValues createInRealm:realm withValue:@[]];
    
    %unman XCTAssertNil(unman.$member, @"RLMValue should be able to initialize as null");
    %man XCTAssertNil(man.$member, @"RLMValue should be able to initialize as null");
    
    // @Lee, nil initialized RLMValues are all valueType "0" == RLMPropertyTypeInt
    XCTAssertEqual(unman.$member.valueType, $valueType);
}

- (void)testUpdateValueSameType {
    $rlmValue = $value1;

    XCTAssert([$cast$rlmValue isEqual:$value1]);
}

- (void)testUpdateBoolType {
    $rlmValue = @YES;
    XCTAssertEqual((NSNumber *)$rlmValue, @YES);
    XCTAssertEqual($rlmValue.valueType, RLMPropertyTypeBool);
}

- (void)testUpdateIntType {
    $rlmValue = @1;
    XCTAssert([(NSNumber *)$rlmValue isEqual:@1]);
    XCTAssertEqual($rlmValue.valueType, RLMPropertyTypeInt);
}

- (void)testUpdateFloatType {
    $rlmValue = @2.2f;
    XCTAssertEqual((NSNumber *)$rlmValue, @2.2f);
    XCTAssertEqual($rlmValue.valueType, RLMPropertyTypeFloat);
}

- (void)testUpdateDoubleType {
    $rlmValue = @3.3;
    XCTAssertEqual((NSNumber *)$rlmValue, @3.3f);
    XCTAssertEqual($rlmValue.valueType, RLMPropertyTypeDouble);
}
- (void)testUpdateStringType {
    $rlmValue = @"four";
    XCTAssertEqual((NSNumber *)$rlmValue, @"four");
    XCTAssertEqual($rlmValue.valueType, RLMPropertyTypeString);
}
- (void)testUpdateDataType {
    $rlmValue = data(5);
    XCTAssertEqual((NSNumber *)$rlmValue, data(5));
    XCTAssertEqual($rlmValue.valueType, RLMPropertyTypeData);
}
- (void)testUpdateDateType {
    $rlmValue = date(6);
    XCTAssertEqual((NSNumber *)$rlmValue, date(6));
    XCTAssertEqual($rlmValue.valueType, RLMPropertyTypeDate);
}
- (void)testUpdateDecimal {
    $rlmValue = decimal128(7);
    XCTAssertEqual((NSNumber *)$rlmValue, decimal128(7));
    XCTAssertEqual($rlmValue.valueType, RLMPropertyTypeDecimal128);
}
- (void)testUpdateUuidType {
    XCTAssert(false);
}
- (void)testUpdateObjectIdType {
    XCTAssert(false);
}

// Update value to null
- (void)testUpdateValueNull {
    $rlmValue = [NSNull null];
    
    XCTAssertNil($rlmValue);
    
    // @Lee - unmanaged don't have valueType selector, managed are set to "0" == RLMPropertyTypeInt
    XCTAssertEqual($rlmValue.valueType, $valueType);
}

@end
