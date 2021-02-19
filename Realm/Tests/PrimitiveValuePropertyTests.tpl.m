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
}

- (void)setUp {
    unmanaged = [[AllPrimitiveValues alloc] init];
    realm = [RLMRealm defaultRealm];
    [realm beginWriteTransaction];
    managed = [AllPrimitiveValues createInRealm:realm withValue:@[]];
    [self assignValues];
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

// @Lee - ask about how invalidation should work. No memeber found.
//- (void)testInvalidated {
//    AllPrimitiveValues *obj;
//    @autoreleasepool {
//        AllPrimitiveSets *obj = [[AllPrimitiveSets alloc] init];
//        XCTAssertFalse(obj.$member.invalidated);
//    }
//    XCTAssertFalse(obj.$member.invalidated);
//}

- (void)testInitNull {
    AllPrimitiveValues *unman = [[AllPrimitiveValues alloc] init];
    AllPrimitiveValues *man = [AllPrimitiveValues createInRealm:realm withValue:@[]];
    
    %unman XCTAssertNil(unman.$member, @"RLMValue should be able to initialize as null");
    %man XCTAssertNil(man.$member, @"RLMValue should be able to initialize as null");
}

// Duck *duck =  [[Duck alloc] initWithValue:@{@"animal" : @{@"age" : @(3)}, @"name" : @"Gustav" }];
- (void)testInitValue {
    AllPrimitiveValues *man = [AllPrimitiveValues createInRealm:realm withValue:@{
        @"$member": $value0,
    }];
    
    AllPrimitiveValues *unman = [[AllPrimitiveValues alloc] initWithValue:@{
        @"$member": $value0,
    }];
    
    XCTAssert([$cast$rlmValue isEqual:$value0]);
    XCTAssert([$cast$rlmValue isEqual:$value0]);
}

- (void)testUpdateValue {
    %n XCTAssert([(NSNumber *)$rlmValue isEqual:$value0]);
    %s XCTAssert([(NSString *)$rlmValue isEqual:$value0]);
    %dc XCTAssert([(RLMDecimal128 *)$rlmValue isEqual:$value0]);
    %dt XCTAssert([(NSDate *)$rlmValue isEqual:$value0]);
    %da XCTAssert([(NSData *)$rlmValue isEqual:$value0]);
    
    $rlmValue = $value1;
    
    %n XCTAssert([(NSNumber *)$rlmValue isEqual:$value1]);
    %s XCTAssert([(NSString *)$rlmValue isEqual:$value1]);
    %dc XCTAssert([(RLMDecimal128 *)$rlmValue isEqual:$value1]);
    %dt XCTAssert([(NSDate *)$rlmValue isEqual:$value1]);
    %da XCTAssert([(NSData *)$rlmValue isEqual:$value1]);
}

// Update value to null
- (void)testUpdateValueNull {
    XCTAssert([$cast$rlmValue isEqual:$value0]);

    $rlmValue = [NSNull null];
    
    XCTAssertNil($rlmValue);
    
    $rlmValue = $value0;
    
    XCTAssert([$cast$rlmValue isEqual:$value0]);
}

//- (void)testUpdateValueDifferentType


@end
