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
}

- (void)testUpdateBoolType {
    $rlmValue = @NO;
    XCTAssert([(NSNumber *)$rlmValue isEqual:@NO]);
    XCTAssertEqual($rlmValue.valueType, RLMPropertyTypeBool);
}

- (void)testUpdateIntType {
    $rlmValue = @2;
    XCTAssert([(NSNumber *)$rlmValue isEqual:@2]);
    XCTAssertEqual($rlmValue.valueType, RLMPropertyTypeInt);
}

- (void)testUpdateFloatType {
    $rlmValue = @2.2f;
    XCTAssert([(NSNumber *)$rlmValue isEqual:@2.2f]);
    XCTAssertEqual($rlmValue.valueType, RLMPropertyTypeFloat);
}

- (void)testUpdateDoubleType {
    $rlmValue = @3.3;
    XCTAssert([(NSNumber *)$rlmValue isEqual:@3.3]);
    XCTAssertEqual($rlmValue.valueType, RLMPropertyTypeDouble);
}

- (void)testUpdateStringType {
    $rlmValue = @"four";
    XCTAssert([(NSNumber *)$rlmValue isEqual:@"four"]);
    XCTAssertEqual($rlmValue.valueType, RLMPropertyTypeString);
}

- (void)testUpdateDataType {
    $rlmValue = data(5);
    XCTAssert([(NSNumber *)$rlmValue isEqual:data(5)]);
    XCTAssertEqual($rlmValue.valueType, RLMPropertyTypeData);
}

- (void)testUpdateDateType {
    $rlmValue = date(6);
    XCTAssert([(NSNumber *)$rlmValue isEqual:date(6)]);
    XCTAssertEqual($rlmValue.valueType, RLMPropertyTypeDate);
}

- (void)testUpdateDecimal {
    $rlmValue = decimal128(7);
    XCTAssert([(NSNumber *)$rlmValue isEqual:decimal128(7)]);
    XCTAssertEqual($rlmValue.valueType, RLMPropertyTypeDecimal128);
}

- (void)testUpdateObjectIdType {
    $rlmValue = objectId(8);
    XCTAssert([(NSUUID *)$rlmValue isEqual:objectId(8)]);
    XCTAssertEqual($rlmValue.valueType, RLMPropertyTypeObjectId);
}

- (void)testUpdateUuidType {
    $rlmValue = uuid(@"137DECC8-B300-4954-A233-F89909F4FD89");
    XCTAssert([(NSUUID *)$rlmValue isEqual:uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")]);
    XCTAssertEqual($rlmValue.valueType, RLMPropertyTypeUUID);
}

@end
