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

@interface PrimitiveRLMValuePropertyTests : RLMTestCase
@end

@implementation PrimitiveRLMValuePropertyTests {
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
    [allMixed addObjects:@[
        $rlmValue,
    ]];
}

- (void)tearDown {
    if (realm.inWriteTransaction) {
        [realm cancelWriteTransaction];
    }
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
    XCTAssertEqual(unmanaged.boolVal.rlm_anyValueType, RLMAnyValueTypeBool);
    XCTAssertEqual(unmanaged.intVal.rlm_anyValueType, RLMAnyValueTypeInt);
    XCTAssertEqual(unmanaged.floatVal.rlm_anyValueType, RLMAnyValueTypeFloat);
    XCTAssertEqual(unmanaged.doubleVal.rlm_anyValueType, RLMAnyValueTypeDouble);
    XCTAssertEqual(unmanaged.stringVal.rlm_anyValueType, RLMAnyValueTypeString);
    XCTAssertEqual(unmanaged.dataVal.rlm_anyValueType, RLMAnyValueTypeData);
    XCTAssertEqual(unmanaged.dateVal.rlm_anyValueType, RLMAnyValueTypeDate);
    XCTAssertEqual(managed.boolVal.rlm_anyValueType, RLMAnyValueTypeBool);
    XCTAssertEqual(managed.intVal.rlm_anyValueType, RLMAnyValueTypeInt);
    XCTAssertEqual(managed.floatVal.rlm_anyValueType, RLMAnyValueTypeFloat);
    XCTAssertEqual(managed.doubleVal.rlm_anyValueType, RLMAnyValueTypeDouble);
    XCTAssertEqual(managed.stringVal.rlm_anyValueType, RLMAnyValueTypeString);
    XCTAssertEqual(managed.dataVal.rlm_anyValueType, RLMAnyValueTypeData);
    XCTAssertEqual(managed.dateVal.rlm_anyValueType, RLMAnyValueTypeDate);
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
    XCTAssertEqual($rlmValue.rlm_anyValueType, RLMAnyValueTypeBool);
}

- (void)testUpdateIntType {
    $rlmValue = @2;
    XCTAssert([(NSNumber *)$rlmValue isEqual:@2]);
    XCTAssertEqual($rlmValue.rlm_anyValueType, RLMAnyValueTypeInt);
}

- (void)testUpdateFloatType {
    $rlmValue = @2.2f;
    XCTAssert([(NSNumber *)$rlmValue isEqual:@2.2f]);
    XCTAssertEqual($rlmValue.rlm_anyValueType, RLMAnyValueTypeFloat);
}

- (void)testUpdateDoubleType {
    $rlmValue = @3.3;
    XCTAssert([(NSNumber *)$rlmValue isEqual:@3.3]);
    XCTAssertEqual($rlmValue.rlm_anyValueType, RLMAnyValueTypeDouble);
}

- (void)testUpdateStringType {
    $rlmValue = @"four";
    XCTAssert([(NSNumber *)$rlmValue isEqual:@"four"]);
    XCTAssertEqual($rlmValue.rlm_anyValueType, RLMAnyValueTypeString);
}

- (void)testUpdateDataType {
    $rlmValue = data(5);
    XCTAssert([(NSNumber *)$rlmValue isEqual:data(5)]);
    XCTAssertEqual($rlmValue.rlm_anyValueType, RLMAnyValueTypeData);
}

- (void)testUpdateDateType {
    $rlmValue = date(6);
    XCTAssert([(NSNumber *)$rlmValue isEqual:date(6)]);
    XCTAssertEqual($rlmValue.rlm_anyValueType, RLMAnyValueTypeDate);
}

- (void)testUpdateDecimal {
    $rlmValue = decimal128(7);
    XCTAssert([(NSNumber *)$rlmValue isEqual:decimal128(7)]);
    XCTAssertEqual($rlmValue.rlm_anyValueType, RLMAnyValueTypeDecimal128);
}

- (void)testUpdateObjectIdType {
    $rlmValue = objectId(8);
    XCTAssert([(NSUUID *)$rlmValue isEqual:objectId(8)]);
    XCTAssertEqual($rlmValue.rlm_anyValueType, RLMAnyValueTypeObjectId);
}

- (void)testUpdateUuidType {
    $rlmValue = uuid(@"137DECC8-B300-4954-A233-F89909F4FD89");
    XCTAssert([(NSUUID *)$rlmValue isEqual:uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")]);
    XCTAssertEqual($rlmValue.rlm_anyValueType, RLMAnyValueTypeUUID);
}

@end
