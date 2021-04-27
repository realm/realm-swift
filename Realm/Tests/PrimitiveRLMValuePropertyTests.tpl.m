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
    XCTAssertEqual(unmanaged.boolVal.rlm_valueType, RLMPropertyTypeBool);
    XCTAssertEqual(unmanaged.intVal.rlm_valueType, RLMPropertyTypeInt);
    XCTAssertEqual(unmanaged.floatVal.rlm_valueType, RLMPropertyTypeFloat);
    XCTAssertEqual(unmanaged.doubleVal.rlm_valueType, RLMPropertyTypeDouble);
    XCTAssertEqual(unmanaged.stringVal.rlm_valueType, RLMPropertyTypeString);
    XCTAssertEqual(unmanaged.dataVal.rlm_valueType, RLMPropertyTypeData);
    XCTAssertEqual(unmanaged.dateVal.rlm_valueType, RLMPropertyTypeDate);
    XCTAssertEqual(managed.boolVal.rlm_valueType, RLMPropertyTypeBool);
    XCTAssertEqual(managed.intVal.rlm_valueType, RLMPropertyTypeInt);
    XCTAssertEqual(managed.floatVal.rlm_valueType, RLMPropertyTypeFloat);
    XCTAssertEqual(managed.doubleVal.rlm_valueType, RLMPropertyTypeDouble);
    XCTAssertEqual(managed.stringVal.rlm_valueType, RLMPropertyTypeString);
    XCTAssertEqual(managed.dataVal.rlm_valueType, RLMPropertyTypeData);
    XCTAssertEqual(managed.dateVal.rlm_valueType, RLMPropertyTypeDate);
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
    XCTAssertEqual($rlmValue.rlm_valueType, RLMPropertyTypeBool);
}

- (void)testUpdateIntType {
    $rlmValue = @2;
    XCTAssert([(NSNumber *)$rlmValue isEqual:@2]);
    XCTAssertEqual($rlmValue.rlm_valueType, RLMPropertyTypeInt);
}

- (void)testUpdateFloatType {
    $rlmValue = @2.2f;
    XCTAssert([(NSNumber *)$rlmValue isEqual:@2.2f]);
    XCTAssertEqual($rlmValue.rlm_valueType, RLMPropertyTypeFloat);
}

- (void)testUpdateDoubleType {
    $rlmValue = @3.3;
    XCTAssert([(NSNumber *)$rlmValue isEqual:@3.3]);
    XCTAssertEqual($rlmValue.rlm_valueType, RLMPropertyTypeDouble);
}

- (void)testUpdateStringType {
    $rlmValue = @"four";
    XCTAssert([(NSNumber *)$rlmValue isEqual:@"four"]);
    XCTAssertEqual($rlmValue.rlm_valueType, RLMPropertyTypeString);
}

- (void)testUpdateDataType {
    $rlmValue = data(5);
    XCTAssert([(NSNumber *)$rlmValue isEqual:data(5)]);
    XCTAssertEqual($rlmValue.rlm_valueType, RLMPropertyTypeData);
}

- (void)testUpdateDateType {
    $rlmValue = date(6);
    XCTAssert([(NSNumber *)$rlmValue isEqual:date(6)]);
    XCTAssertEqual($rlmValue.rlm_valueType, RLMPropertyTypeDate);
}

- (void)testUpdateDecimal {
    $rlmValue = decimal128(7);
    XCTAssert([(NSNumber *)$rlmValue isEqual:decimal128(7)]);
    XCTAssertEqual($rlmValue.rlm_valueType, RLMPropertyTypeDecimal128);
}

- (void)testUpdateObjectIdType {
    $rlmValue = objectId(8);
    XCTAssert([(NSUUID *)$rlmValue isEqual:objectId(8)]);
    XCTAssertEqual($rlmValue.rlm_valueType, RLMPropertyTypeObjectId);
}

- (void)testUpdateUuidType {
    $rlmValue = uuid(@"137DECC8-B300-4954-A233-F89909F4FD89");
    XCTAssert([(NSUUID *)$rlmValue isEqual:uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")]);
    XCTAssertEqual($rlmValue.rlm_valueType, RLMPropertyTypeUUID);
}

@end
