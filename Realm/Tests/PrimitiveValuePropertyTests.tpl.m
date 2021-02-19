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
    AllPrimitiveRLMValues *unmanaged;
    AllPrimitiveRLMValues *managed;
    RLMRealm *realm;
    RLMArray<RLMValue> *allValues;
}

- (void)setUp {
    realm = [RLMRealm defaultRealm];
    [realm beginWriteTransaction];
    [self initValues];
//    [self assignValues];
//    [allValues addObjects:@[
//        $rlmValue,
//    ]];
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

- (void)testUpdateValueDifferentType {
    
}

// Update value to null
- (void)testUpdateValueNull {
    $rlmValue = [NSNull null];
    
    XCTAssertNil($rlmValue);
    
    // @Lee - unmanaged don't have valueType selector, managed are set to "0" == RLMPropertyTypeInt
    XCTAssertEqual($rlmValue.valueType, $valueType);
}

//- (void)testUpdateValueDifferentType


@end
