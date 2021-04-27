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
        unmanaged.boolVal,
        unmanaged.intVal,
        unmanaged.floatVal,
        unmanaged.doubleVal,
        unmanaged.stringVal,
        unmanaged.dataVal,
        unmanaged.dateVal,
        unmanaged.decimalVal,
        unmanaged.objectIdVal,
        unmanaged.uuidVal,
        managed.boolVal,
        managed.intVal,
        managed.floatVal,
        managed.doubleVal,
        managed.stringVal,
        managed.dataVal,
        managed.dateVal,
        managed.decimalVal,
        managed.objectIdVal,
        managed.uuidVal,
    ]];
}

- (void)tearDown {
    if (realm.inWriteTransaction) {
        [realm cancelWriteTransaction];
    }
}

- (void)initValues {
    unmanaged = [[AllPrimitiveRLMValues alloc] initWithValue:@{
        @"boolVal": @NO,
        @"intVal": @2,
        @"floatVal": @2.2f,
        @"doubleVal": @2.2,
        @"stringVal": @"a",
        @"dataVal": data(1),
        @"dateVal": date(1),
        @"decimalVal": decimal128(2),
        @"objectIdVal": objectId(1),
        @"uuidVal": uuid(@"00000000-0000-0000-0000-000000000000"),
    }];
    XCTAssertNil(unmanaged.realm);
    
    managed = [AllPrimitiveRLMValues createInRealm:realm withValue:@{
        @"boolVal": @NO,
        @"intVal": @2,
        @"floatVal": @2.2f,
        @"doubleVal": @2.2,
        @"stringVal": @"a",
        @"dataVal": data(1),
        @"dateVal": date(1),
        @"decimalVal": decimal128(2),
        @"objectIdVal": objectId(1),
        @"uuidVal": uuid(@"00000000-0000-0000-0000-000000000000"),
    }];
    XCTAssertNotNil(managed.realm);
    
    XCTAssert([(NSNumber *)unmanaged.boolVal isEqual:@NO]);
    XCTAssert([(NSNumber *)unmanaged.intVal isEqual:@2]);
    XCTAssert([(NSNumber *)unmanaged.floatVal isEqual:@2.2f]);
    XCTAssert([(NSNumber *)unmanaged.doubleVal isEqual:@2.2]);
    XCTAssert([(NSString *)unmanaged.stringVal isEqual:@"a"]);
    XCTAssert([(NSData *)unmanaged.dataVal isEqual:data(1)]);
    XCTAssert([(NSDate *)unmanaged.dateVal isEqual:date(1)]);
    XCTAssert([(RLMDecimal128 *)unmanaged.decimalVal isEqual:decimal128(2)]);
    XCTAssert([(RLMObjectId *)unmanaged.objectIdVal isEqual:objectId(1)]);
    XCTAssert([(NSUUID *)unmanaged.uuidVal isEqual:uuid(@"00000000-0000-0000-0000-000000000000")]);
    XCTAssert([(NSNumber *)managed.boolVal isEqual:@NO]);
    XCTAssert([(NSNumber *)managed.intVal isEqual:@2]);
    XCTAssert([(NSNumber *)managed.floatVal isEqual:@2.2f]);
    XCTAssert([(NSNumber *)managed.doubleVal isEqual:@2.2]);
    XCTAssert([(NSString *)managed.stringVal isEqual:@"a"]);
    XCTAssert([(NSData *)managed.dataVal isEqual:data(1)]);
    XCTAssert([(NSDate *)managed.dateVal isEqual:date(1)]);
    XCTAssert([(RLMDecimal128 *)managed.decimalVal isEqual:decimal128(2)]);
    XCTAssert([(RLMObjectId *)managed.objectIdVal isEqual:objectId(1)]);
    XCTAssert([(NSUUID *)managed.uuidVal isEqual:uuid(@"00000000-0000-0000-0000-000000000000")]);
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
    
    XCTAssertNil(unman.boolVal, @"RLMValue should be able to initialize as null");
    XCTAssertNil(unman.intVal, @"RLMValue should be able to initialize as null");
    XCTAssertNil(unman.floatVal, @"RLMValue should be able to initialize as null");
    XCTAssertNil(unman.doubleVal, @"RLMValue should be able to initialize as null");
    XCTAssertNil(unman.stringVal, @"RLMValue should be able to initialize as null");
    XCTAssertNil(unman.dataVal, @"RLMValue should be able to initialize as null");
    XCTAssertNil(unman.dateVal, @"RLMValue should be able to initialize as null");
    XCTAssertNil(unman.decimalVal, @"RLMValue should be able to initialize as null");
    XCTAssertNil(unman.objectIdVal, @"RLMValue should be able to initialize as null");
    XCTAssertNil(unman.uuidVal, @"RLMValue should be able to initialize as null");
    XCTAssertNil(man.boolVal, @"RLMValue should be able to initialize as null");
    XCTAssertNil(man.intVal, @"RLMValue should be able to initialize as null");
    XCTAssertNil(man.floatVal, @"RLMValue should be able to initialize as null");
    XCTAssertNil(man.doubleVal, @"RLMValue should be able to initialize as null");
    XCTAssertNil(man.stringVal, @"RLMValue should be able to initialize as null");
    XCTAssertNil(man.dataVal, @"RLMValue should be able to initialize as null");
    XCTAssertNil(man.dateVal, @"RLMValue should be able to initialize as null");
    XCTAssertNil(man.decimalVal, @"RLMValue should be able to initialize as null");
    XCTAssertNil(man.objectIdVal, @"RLMValue should be able to initialize as null");
    XCTAssertNil(man.uuidVal, @"RLMValue should be able to initialize as null");
}

- (void)testUpdateBoolType {
    unmanaged.boolVal = @NO;
    unmanaged.intVal = @NO;
    unmanaged.floatVal = @NO;
    unmanaged.doubleVal = @NO;
    unmanaged.stringVal = @NO;
    unmanaged.dataVal = @NO;
    unmanaged.dateVal = @NO;
    unmanaged.decimalVal = @NO;
    unmanaged.objectIdVal = @NO;
    unmanaged.uuidVal = @NO;
    managed.boolVal = @NO;
    managed.intVal = @NO;
    managed.floatVal = @NO;
    managed.doubleVal = @NO;
    managed.stringVal = @NO;
    managed.dataVal = @NO;
    managed.dateVal = @NO;
    managed.decimalVal = @NO;
    managed.objectIdVal = @NO;
    managed.uuidVal = @NO;
    XCTAssert([(NSNumber *)unmanaged.boolVal isEqual:@NO]);
    XCTAssert([(NSNumber *)unmanaged.intVal isEqual:@NO]);
    XCTAssert([(NSNumber *)unmanaged.floatVal isEqual:@NO]);
    XCTAssert([(NSNumber *)unmanaged.doubleVal isEqual:@NO]);
    XCTAssert([(NSNumber *)unmanaged.stringVal isEqual:@NO]);
    XCTAssert([(NSNumber *)unmanaged.dataVal isEqual:@NO]);
    XCTAssert([(NSNumber *)unmanaged.dateVal isEqual:@NO]);
    XCTAssert([(NSNumber *)unmanaged.decimalVal isEqual:@NO]);
    XCTAssert([(NSNumber *)unmanaged.objectIdVal isEqual:@NO]);
    XCTAssert([(NSNumber *)unmanaged.uuidVal isEqual:@NO]);
    XCTAssert([(NSNumber *)managed.boolVal isEqual:@NO]);
    XCTAssert([(NSNumber *)managed.intVal isEqual:@NO]);
    XCTAssert([(NSNumber *)managed.floatVal isEqual:@NO]);
    XCTAssert([(NSNumber *)managed.doubleVal isEqual:@NO]);
    XCTAssert([(NSNumber *)managed.stringVal isEqual:@NO]);
    XCTAssert([(NSNumber *)managed.dataVal isEqual:@NO]);
    XCTAssert([(NSNumber *)managed.dateVal isEqual:@NO]);
    XCTAssert([(NSNumber *)managed.decimalVal isEqual:@NO]);
    XCTAssert([(NSNumber *)managed.objectIdVal isEqual:@NO]);
    XCTAssert([(NSNumber *)managed.uuidVal isEqual:@NO]);
    XCTAssertEqual(unmanaged.boolVal.rlm_valueType, RLMPropertyTypeBool);
    XCTAssertEqual(unmanaged.intVal.rlm_valueType, RLMPropertyTypeBool);
    XCTAssertEqual(unmanaged.floatVal.rlm_valueType, RLMPropertyTypeBool);
    XCTAssertEqual(unmanaged.doubleVal.rlm_valueType, RLMPropertyTypeBool);
    XCTAssertEqual(unmanaged.stringVal.rlm_valueType, RLMPropertyTypeBool);
    XCTAssertEqual(unmanaged.dataVal.rlm_valueType, RLMPropertyTypeBool);
    XCTAssertEqual(unmanaged.dateVal.rlm_valueType, RLMPropertyTypeBool);
    XCTAssertEqual(unmanaged.decimalVal.rlm_valueType, RLMPropertyTypeBool);
    XCTAssertEqual(unmanaged.objectIdVal.rlm_valueType, RLMPropertyTypeBool);
    XCTAssertEqual(unmanaged.uuidVal.rlm_valueType, RLMPropertyTypeBool);
    XCTAssertEqual(managed.boolVal.rlm_valueType, RLMPropertyTypeBool);
    XCTAssertEqual(managed.intVal.rlm_valueType, RLMPropertyTypeBool);
    XCTAssertEqual(managed.floatVal.rlm_valueType, RLMPropertyTypeBool);
    XCTAssertEqual(managed.doubleVal.rlm_valueType, RLMPropertyTypeBool);
    XCTAssertEqual(managed.stringVal.rlm_valueType, RLMPropertyTypeBool);
    XCTAssertEqual(managed.dataVal.rlm_valueType, RLMPropertyTypeBool);
    XCTAssertEqual(managed.dateVal.rlm_valueType, RLMPropertyTypeBool);
    XCTAssertEqual(managed.decimalVal.rlm_valueType, RLMPropertyTypeBool);
    XCTAssertEqual(managed.objectIdVal.rlm_valueType, RLMPropertyTypeBool);
    XCTAssertEqual(managed.uuidVal.rlm_valueType, RLMPropertyTypeBool);
}

- (void)testUpdateIntType {
    unmanaged.boolVal = @2;
    unmanaged.intVal = @2;
    unmanaged.floatVal = @2;
    unmanaged.doubleVal = @2;
    unmanaged.stringVal = @2;
    unmanaged.dataVal = @2;
    unmanaged.dateVal = @2;
    unmanaged.decimalVal = @2;
    unmanaged.objectIdVal = @2;
    unmanaged.uuidVal = @2;
    managed.boolVal = @2;
    managed.intVal = @2;
    managed.floatVal = @2;
    managed.doubleVal = @2;
    managed.stringVal = @2;
    managed.dataVal = @2;
    managed.dateVal = @2;
    managed.decimalVal = @2;
    managed.objectIdVal = @2;
    managed.uuidVal = @2;
    XCTAssert([(NSNumber *)unmanaged.boolVal isEqual:@2]);
    XCTAssert([(NSNumber *)unmanaged.intVal isEqual:@2]);
    XCTAssert([(NSNumber *)unmanaged.floatVal isEqual:@2]);
    XCTAssert([(NSNumber *)unmanaged.doubleVal isEqual:@2]);
    XCTAssert([(NSNumber *)unmanaged.stringVal isEqual:@2]);
    XCTAssert([(NSNumber *)unmanaged.dataVal isEqual:@2]);
    XCTAssert([(NSNumber *)unmanaged.dateVal isEqual:@2]);
    XCTAssert([(NSNumber *)unmanaged.decimalVal isEqual:@2]);
    XCTAssert([(NSNumber *)unmanaged.objectIdVal isEqual:@2]);
    XCTAssert([(NSNumber *)unmanaged.uuidVal isEqual:@2]);
    XCTAssert([(NSNumber *)managed.boolVal isEqual:@2]);
    XCTAssert([(NSNumber *)managed.intVal isEqual:@2]);
    XCTAssert([(NSNumber *)managed.floatVal isEqual:@2]);
    XCTAssert([(NSNumber *)managed.doubleVal isEqual:@2]);
    XCTAssert([(NSNumber *)managed.stringVal isEqual:@2]);
    XCTAssert([(NSNumber *)managed.dataVal isEqual:@2]);
    XCTAssert([(NSNumber *)managed.dateVal isEqual:@2]);
    XCTAssert([(NSNumber *)managed.decimalVal isEqual:@2]);
    XCTAssert([(NSNumber *)managed.objectIdVal isEqual:@2]);
    XCTAssert([(NSNumber *)managed.uuidVal isEqual:@2]);
    XCTAssertEqual(unmanaged.boolVal.rlm_valueType, RLMPropertyTypeInt);
    XCTAssertEqual(unmanaged.intVal.rlm_valueType, RLMPropertyTypeInt);
    XCTAssertEqual(unmanaged.floatVal.rlm_valueType, RLMPropertyTypeInt);
    XCTAssertEqual(unmanaged.doubleVal.rlm_valueType, RLMPropertyTypeInt);
    XCTAssertEqual(unmanaged.stringVal.rlm_valueType, RLMPropertyTypeInt);
    XCTAssertEqual(unmanaged.dataVal.rlm_valueType, RLMPropertyTypeInt);
    XCTAssertEqual(unmanaged.dateVal.rlm_valueType, RLMPropertyTypeInt);
    XCTAssertEqual(unmanaged.decimalVal.rlm_valueType, RLMPropertyTypeInt);
    XCTAssertEqual(unmanaged.objectIdVal.rlm_valueType, RLMPropertyTypeInt);
    XCTAssertEqual(unmanaged.uuidVal.rlm_valueType, RLMPropertyTypeInt);
    XCTAssertEqual(managed.boolVal.rlm_valueType, RLMPropertyTypeInt);
    XCTAssertEqual(managed.intVal.rlm_valueType, RLMPropertyTypeInt);
    XCTAssertEqual(managed.floatVal.rlm_valueType, RLMPropertyTypeInt);
    XCTAssertEqual(managed.doubleVal.rlm_valueType, RLMPropertyTypeInt);
    XCTAssertEqual(managed.stringVal.rlm_valueType, RLMPropertyTypeInt);
    XCTAssertEqual(managed.dataVal.rlm_valueType, RLMPropertyTypeInt);
    XCTAssertEqual(managed.dateVal.rlm_valueType, RLMPropertyTypeInt);
    XCTAssertEqual(managed.decimalVal.rlm_valueType, RLMPropertyTypeInt);
    XCTAssertEqual(managed.objectIdVal.rlm_valueType, RLMPropertyTypeInt);
    XCTAssertEqual(managed.uuidVal.rlm_valueType, RLMPropertyTypeInt);
}

- (void)testUpdateFloatType {
    unmanaged.boolVal = @2.2f;
    unmanaged.intVal = @2.2f;
    unmanaged.floatVal = @2.2f;
    unmanaged.doubleVal = @2.2f;
    unmanaged.stringVal = @2.2f;
    unmanaged.dataVal = @2.2f;
    unmanaged.dateVal = @2.2f;
    unmanaged.decimalVal = @2.2f;
    unmanaged.objectIdVal = @2.2f;
    unmanaged.uuidVal = @2.2f;
    managed.boolVal = @2.2f;
    managed.intVal = @2.2f;
    managed.floatVal = @2.2f;
    managed.doubleVal = @2.2f;
    managed.stringVal = @2.2f;
    managed.dataVal = @2.2f;
    managed.dateVal = @2.2f;
    managed.decimalVal = @2.2f;
    managed.objectIdVal = @2.2f;
    managed.uuidVal = @2.2f;
    XCTAssert([(NSNumber *)unmanaged.boolVal isEqual:@2.2f]);
    XCTAssert([(NSNumber *)unmanaged.intVal isEqual:@2.2f]);
    XCTAssert([(NSNumber *)unmanaged.floatVal isEqual:@2.2f]);
    XCTAssert([(NSNumber *)unmanaged.doubleVal isEqual:@2.2f]);
    XCTAssert([(NSNumber *)unmanaged.stringVal isEqual:@2.2f]);
    XCTAssert([(NSNumber *)unmanaged.dataVal isEqual:@2.2f]);
    XCTAssert([(NSNumber *)unmanaged.dateVal isEqual:@2.2f]);
    XCTAssert([(NSNumber *)unmanaged.decimalVal isEqual:@2.2f]);
    XCTAssert([(NSNumber *)unmanaged.objectIdVal isEqual:@2.2f]);
    XCTAssert([(NSNumber *)unmanaged.uuidVal isEqual:@2.2f]);
    XCTAssert([(NSNumber *)managed.boolVal isEqual:@2.2f]);
    XCTAssert([(NSNumber *)managed.intVal isEqual:@2.2f]);
    XCTAssert([(NSNumber *)managed.floatVal isEqual:@2.2f]);
    XCTAssert([(NSNumber *)managed.doubleVal isEqual:@2.2f]);
    XCTAssert([(NSNumber *)managed.stringVal isEqual:@2.2f]);
    XCTAssert([(NSNumber *)managed.dataVal isEqual:@2.2f]);
    XCTAssert([(NSNumber *)managed.dateVal isEqual:@2.2f]);
    XCTAssert([(NSNumber *)managed.decimalVal isEqual:@2.2f]);
    XCTAssert([(NSNumber *)managed.objectIdVal isEqual:@2.2f]);
    XCTAssert([(NSNumber *)managed.uuidVal isEqual:@2.2f]);
    XCTAssertEqual(unmanaged.boolVal.rlm_valueType, RLMPropertyTypeFloat);
    XCTAssertEqual(unmanaged.intVal.rlm_valueType, RLMPropertyTypeFloat);
    XCTAssertEqual(unmanaged.floatVal.rlm_valueType, RLMPropertyTypeFloat);
    XCTAssertEqual(unmanaged.doubleVal.rlm_valueType, RLMPropertyTypeFloat);
    XCTAssertEqual(unmanaged.stringVal.rlm_valueType, RLMPropertyTypeFloat);
    XCTAssertEqual(unmanaged.dataVal.rlm_valueType, RLMPropertyTypeFloat);
    XCTAssertEqual(unmanaged.dateVal.rlm_valueType, RLMPropertyTypeFloat);
    XCTAssertEqual(unmanaged.decimalVal.rlm_valueType, RLMPropertyTypeFloat);
    XCTAssertEqual(unmanaged.objectIdVal.rlm_valueType, RLMPropertyTypeFloat);
    XCTAssertEqual(unmanaged.uuidVal.rlm_valueType, RLMPropertyTypeFloat);
    XCTAssertEqual(managed.boolVal.rlm_valueType, RLMPropertyTypeFloat);
    XCTAssertEqual(managed.intVal.rlm_valueType, RLMPropertyTypeFloat);
    XCTAssertEqual(managed.floatVal.rlm_valueType, RLMPropertyTypeFloat);
    XCTAssertEqual(managed.doubleVal.rlm_valueType, RLMPropertyTypeFloat);
    XCTAssertEqual(managed.stringVal.rlm_valueType, RLMPropertyTypeFloat);
    XCTAssertEqual(managed.dataVal.rlm_valueType, RLMPropertyTypeFloat);
    XCTAssertEqual(managed.dateVal.rlm_valueType, RLMPropertyTypeFloat);
    XCTAssertEqual(managed.decimalVal.rlm_valueType, RLMPropertyTypeFloat);
    XCTAssertEqual(managed.objectIdVal.rlm_valueType, RLMPropertyTypeFloat);
    XCTAssertEqual(managed.uuidVal.rlm_valueType, RLMPropertyTypeFloat);
}

- (void)testUpdateDoubleType {
    unmanaged.boolVal = @3.3;
    unmanaged.intVal = @3.3;
    unmanaged.floatVal = @3.3;
    unmanaged.doubleVal = @3.3;
    unmanaged.stringVal = @3.3;
    unmanaged.dataVal = @3.3;
    unmanaged.dateVal = @3.3;
    unmanaged.decimalVal = @3.3;
    unmanaged.objectIdVal = @3.3;
    unmanaged.uuidVal = @3.3;
    managed.boolVal = @3.3;
    managed.intVal = @3.3;
    managed.floatVal = @3.3;
    managed.doubleVal = @3.3;
    managed.stringVal = @3.3;
    managed.dataVal = @3.3;
    managed.dateVal = @3.3;
    managed.decimalVal = @3.3;
    managed.objectIdVal = @3.3;
    managed.uuidVal = @3.3;
    XCTAssert([(NSNumber *)unmanaged.boolVal isEqual:@3.3]);
    XCTAssert([(NSNumber *)unmanaged.intVal isEqual:@3.3]);
    XCTAssert([(NSNumber *)unmanaged.floatVal isEqual:@3.3]);
    XCTAssert([(NSNumber *)unmanaged.doubleVal isEqual:@3.3]);
    XCTAssert([(NSNumber *)unmanaged.stringVal isEqual:@3.3]);
    XCTAssert([(NSNumber *)unmanaged.dataVal isEqual:@3.3]);
    XCTAssert([(NSNumber *)unmanaged.dateVal isEqual:@3.3]);
    XCTAssert([(NSNumber *)unmanaged.decimalVal isEqual:@3.3]);
    XCTAssert([(NSNumber *)unmanaged.objectIdVal isEqual:@3.3]);
    XCTAssert([(NSNumber *)unmanaged.uuidVal isEqual:@3.3]);
    XCTAssert([(NSNumber *)managed.boolVal isEqual:@3.3]);
    XCTAssert([(NSNumber *)managed.intVal isEqual:@3.3]);
    XCTAssert([(NSNumber *)managed.floatVal isEqual:@3.3]);
    XCTAssert([(NSNumber *)managed.doubleVal isEqual:@3.3]);
    XCTAssert([(NSNumber *)managed.stringVal isEqual:@3.3]);
    XCTAssert([(NSNumber *)managed.dataVal isEqual:@3.3]);
    XCTAssert([(NSNumber *)managed.dateVal isEqual:@3.3]);
    XCTAssert([(NSNumber *)managed.decimalVal isEqual:@3.3]);
    XCTAssert([(NSNumber *)managed.objectIdVal isEqual:@3.3]);
    XCTAssert([(NSNumber *)managed.uuidVal isEqual:@3.3]);
    XCTAssertEqual(unmanaged.boolVal.rlm_valueType, RLMPropertyTypeDouble);
    XCTAssertEqual(unmanaged.intVal.rlm_valueType, RLMPropertyTypeDouble);
    XCTAssertEqual(unmanaged.floatVal.rlm_valueType, RLMPropertyTypeDouble);
    XCTAssertEqual(unmanaged.doubleVal.rlm_valueType, RLMPropertyTypeDouble);
    XCTAssertEqual(unmanaged.stringVal.rlm_valueType, RLMPropertyTypeDouble);
    XCTAssertEqual(unmanaged.dataVal.rlm_valueType, RLMPropertyTypeDouble);
    XCTAssertEqual(unmanaged.dateVal.rlm_valueType, RLMPropertyTypeDouble);
    XCTAssertEqual(unmanaged.decimalVal.rlm_valueType, RLMPropertyTypeDouble);
    XCTAssertEqual(unmanaged.objectIdVal.rlm_valueType, RLMPropertyTypeDouble);
    XCTAssertEqual(unmanaged.uuidVal.rlm_valueType, RLMPropertyTypeDouble);
    XCTAssertEqual(managed.boolVal.rlm_valueType, RLMPropertyTypeDouble);
    XCTAssertEqual(managed.intVal.rlm_valueType, RLMPropertyTypeDouble);
    XCTAssertEqual(managed.floatVal.rlm_valueType, RLMPropertyTypeDouble);
    XCTAssertEqual(managed.doubleVal.rlm_valueType, RLMPropertyTypeDouble);
    XCTAssertEqual(managed.stringVal.rlm_valueType, RLMPropertyTypeDouble);
    XCTAssertEqual(managed.dataVal.rlm_valueType, RLMPropertyTypeDouble);
    XCTAssertEqual(managed.dateVal.rlm_valueType, RLMPropertyTypeDouble);
    XCTAssertEqual(managed.decimalVal.rlm_valueType, RLMPropertyTypeDouble);
    XCTAssertEqual(managed.objectIdVal.rlm_valueType, RLMPropertyTypeDouble);
    XCTAssertEqual(managed.uuidVal.rlm_valueType, RLMPropertyTypeDouble);
}

- (void)testUpdateStringType {
    unmanaged.boolVal = @"four";
    unmanaged.intVal = @"four";
    unmanaged.floatVal = @"four";
    unmanaged.doubleVal = @"four";
    unmanaged.stringVal = @"four";
    unmanaged.dataVal = @"four";
    unmanaged.dateVal = @"four";
    unmanaged.decimalVal = @"four";
    unmanaged.objectIdVal = @"four";
    unmanaged.uuidVal = @"four";
    managed.boolVal = @"four";
    managed.intVal = @"four";
    managed.floatVal = @"four";
    managed.doubleVal = @"four";
    managed.stringVal = @"four";
    managed.dataVal = @"four";
    managed.dateVal = @"four";
    managed.decimalVal = @"four";
    managed.objectIdVal = @"four";
    managed.uuidVal = @"four";
    XCTAssert([(NSNumber *)unmanaged.boolVal isEqual:@"four"]);
    XCTAssert([(NSNumber *)unmanaged.intVal isEqual:@"four"]);
    XCTAssert([(NSNumber *)unmanaged.floatVal isEqual:@"four"]);
    XCTAssert([(NSNumber *)unmanaged.doubleVal isEqual:@"four"]);
    XCTAssert([(NSNumber *)unmanaged.stringVal isEqual:@"four"]);
    XCTAssert([(NSNumber *)unmanaged.dataVal isEqual:@"four"]);
    XCTAssert([(NSNumber *)unmanaged.dateVal isEqual:@"four"]);
    XCTAssert([(NSNumber *)unmanaged.decimalVal isEqual:@"four"]);
    XCTAssert([(NSNumber *)unmanaged.objectIdVal isEqual:@"four"]);
    XCTAssert([(NSNumber *)unmanaged.uuidVal isEqual:@"four"]);
    XCTAssert([(NSNumber *)managed.boolVal isEqual:@"four"]);
    XCTAssert([(NSNumber *)managed.intVal isEqual:@"four"]);
    XCTAssert([(NSNumber *)managed.floatVal isEqual:@"four"]);
    XCTAssert([(NSNumber *)managed.doubleVal isEqual:@"four"]);
    XCTAssert([(NSNumber *)managed.stringVal isEqual:@"four"]);
    XCTAssert([(NSNumber *)managed.dataVal isEqual:@"four"]);
    XCTAssert([(NSNumber *)managed.dateVal isEqual:@"four"]);
    XCTAssert([(NSNumber *)managed.decimalVal isEqual:@"four"]);
    XCTAssert([(NSNumber *)managed.objectIdVal isEqual:@"four"]);
    XCTAssert([(NSNumber *)managed.uuidVal isEqual:@"four"]);
    XCTAssertEqual(unmanaged.boolVal.rlm_valueType, RLMPropertyTypeString);
    XCTAssertEqual(unmanaged.intVal.rlm_valueType, RLMPropertyTypeString);
    XCTAssertEqual(unmanaged.floatVal.rlm_valueType, RLMPropertyTypeString);
    XCTAssertEqual(unmanaged.doubleVal.rlm_valueType, RLMPropertyTypeString);
    XCTAssertEqual(unmanaged.stringVal.rlm_valueType, RLMPropertyTypeString);
    XCTAssertEqual(unmanaged.dataVal.rlm_valueType, RLMPropertyTypeString);
    XCTAssertEqual(unmanaged.dateVal.rlm_valueType, RLMPropertyTypeString);
    XCTAssertEqual(unmanaged.decimalVal.rlm_valueType, RLMPropertyTypeString);
    XCTAssertEqual(unmanaged.objectIdVal.rlm_valueType, RLMPropertyTypeString);
    XCTAssertEqual(unmanaged.uuidVal.rlm_valueType, RLMPropertyTypeString);
    XCTAssertEqual(managed.boolVal.rlm_valueType, RLMPropertyTypeString);
    XCTAssertEqual(managed.intVal.rlm_valueType, RLMPropertyTypeString);
    XCTAssertEqual(managed.floatVal.rlm_valueType, RLMPropertyTypeString);
    XCTAssertEqual(managed.doubleVal.rlm_valueType, RLMPropertyTypeString);
    XCTAssertEqual(managed.stringVal.rlm_valueType, RLMPropertyTypeString);
    XCTAssertEqual(managed.dataVal.rlm_valueType, RLMPropertyTypeString);
    XCTAssertEqual(managed.dateVal.rlm_valueType, RLMPropertyTypeString);
    XCTAssertEqual(managed.decimalVal.rlm_valueType, RLMPropertyTypeString);
    XCTAssertEqual(managed.objectIdVal.rlm_valueType, RLMPropertyTypeString);
    XCTAssertEqual(managed.uuidVal.rlm_valueType, RLMPropertyTypeString);
}

- (void)testUpdateDataType {
    unmanaged.boolVal = data(5);
    unmanaged.intVal = data(5);
    unmanaged.floatVal = data(5);
    unmanaged.doubleVal = data(5);
    unmanaged.stringVal = data(5);
    unmanaged.dataVal = data(5);
    unmanaged.dateVal = data(5);
    unmanaged.decimalVal = data(5);
    unmanaged.objectIdVal = data(5);
    unmanaged.uuidVal = data(5);
    managed.boolVal = data(5);
    managed.intVal = data(5);
    managed.floatVal = data(5);
    managed.doubleVal = data(5);
    managed.stringVal = data(5);
    managed.dataVal = data(5);
    managed.dateVal = data(5);
    managed.decimalVal = data(5);
    managed.objectIdVal = data(5);
    managed.uuidVal = data(5);
    XCTAssert([(NSNumber *)unmanaged.boolVal isEqual:data(5)]);
    XCTAssert([(NSNumber *)unmanaged.intVal isEqual:data(5)]);
    XCTAssert([(NSNumber *)unmanaged.floatVal isEqual:data(5)]);
    XCTAssert([(NSNumber *)unmanaged.doubleVal isEqual:data(5)]);
    XCTAssert([(NSNumber *)unmanaged.stringVal isEqual:data(5)]);
    XCTAssert([(NSNumber *)unmanaged.dataVal isEqual:data(5)]);
    XCTAssert([(NSNumber *)unmanaged.dateVal isEqual:data(5)]);
    XCTAssert([(NSNumber *)unmanaged.decimalVal isEqual:data(5)]);
    XCTAssert([(NSNumber *)unmanaged.objectIdVal isEqual:data(5)]);
    XCTAssert([(NSNumber *)unmanaged.uuidVal isEqual:data(5)]);
    XCTAssert([(NSNumber *)managed.boolVal isEqual:data(5)]);
    XCTAssert([(NSNumber *)managed.intVal isEqual:data(5)]);
    XCTAssert([(NSNumber *)managed.floatVal isEqual:data(5)]);
    XCTAssert([(NSNumber *)managed.doubleVal isEqual:data(5)]);
    XCTAssert([(NSNumber *)managed.stringVal isEqual:data(5)]);
    XCTAssert([(NSNumber *)managed.dataVal isEqual:data(5)]);
    XCTAssert([(NSNumber *)managed.dateVal isEqual:data(5)]);
    XCTAssert([(NSNumber *)managed.decimalVal isEqual:data(5)]);
    XCTAssert([(NSNumber *)managed.objectIdVal isEqual:data(5)]);
    XCTAssert([(NSNumber *)managed.uuidVal isEqual:data(5)]);
    XCTAssertEqual(unmanaged.boolVal.rlm_valueType, RLMPropertyTypeData);
    XCTAssertEqual(unmanaged.intVal.rlm_valueType, RLMPropertyTypeData);
    XCTAssertEqual(unmanaged.floatVal.rlm_valueType, RLMPropertyTypeData);
    XCTAssertEqual(unmanaged.doubleVal.rlm_valueType, RLMPropertyTypeData);
    XCTAssertEqual(unmanaged.stringVal.rlm_valueType, RLMPropertyTypeData);
    XCTAssertEqual(unmanaged.dataVal.rlm_valueType, RLMPropertyTypeData);
    XCTAssertEqual(unmanaged.dateVal.rlm_valueType, RLMPropertyTypeData);
    XCTAssertEqual(unmanaged.decimalVal.rlm_valueType, RLMPropertyTypeData);
    XCTAssertEqual(unmanaged.objectIdVal.rlm_valueType, RLMPropertyTypeData);
    XCTAssertEqual(unmanaged.uuidVal.rlm_valueType, RLMPropertyTypeData);
    XCTAssertEqual(managed.boolVal.rlm_valueType, RLMPropertyTypeData);
    XCTAssertEqual(managed.intVal.rlm_valueType, RLMPropertyTypeData);
    XCTAssertEqual(managed.floatVal.rlm_valueType, RLMPropertyTypeData);
    XCTAssertEqual(managed.doubleVal.rlm_valueType, RLMPropertyTypeData);
    XCTAssertEqual(managed.stringVal.rlm_valueType, RLMPropertyTypeData);
    XCTAssertEqual(managed.dataVal.rlm_valueType, RLMPropertyTypeData);
    XCTAssertEqual(managed.dateVal.rlm_valueType, RLMPropertyTypeData);
    XCTAssertEqual(managed.decimalVal.rlm_valueType, RLMPropertyTypeData);
    XCTAssertEqual(managed.objectIdVal.rlm_valueType, RLMPropertyTypeData);
    XCTAssertEqual(managed.uuidVal.rlm_valueType, RLMPropertyTypeData);
}

- (void)testUpdateDateType {
    unmanaged.boolVal = date(6);
    unmanaged.intVal = date(6);
    unmanaged.floatVal = date(6);
    unmanaged.doubleVal = date(6);
    unmanaged.stringVal = date(6);
    unmanaged.dataVal = date(6);
    unmanaged.dateVal = date(6);
    unmanaged.decimalVal = date(6);
    unmanaged.objectIdVal = date(6);
    unmanaged.uuidVal = date(6);
    managed.boolVal = date(6);
    managed.intVal = date(6);
    managed.floatVal = date(6);
    managed.doubleVal = date(6);
    managed.stringVal = date(6);
    managed.dataVal = date(6);
    managed.dateVal = date(6);
    managed.decimalVal = date(6);
    managed.objectIdVal = date(6);
    managed.uuidVal = date(6);
    XCTAssert([(NSNumber *)unmanaged.boolVal isEqual:date(6)]);
    XCTAssert([(NSNumber *)unmanaged.intVal isEqual:date(6)]);
    XCTAssert([(NSNumber *)unmanaged.floatVal isEqual:date(6)]);
    XCTAssert([(NSNumber *)unmanaged.doubleVal isEqual:date(6)]);
    XCTAssert([(NSNumber *)unmanaged.stringVal isEqual:date(6)]);
    XCTAssert([(NSNumber *)unmanaged.dataVal isEqual:date(6)]);
    XCTAssert([(NSNumber *)unmanaged.dateVal isEqual:date(6)]);
    XCTAssert([(NSNumber *)unmanaged.decimalVal isEqual:date(6)]);
    XCTAssert([(NSNumber *)unmanaged.objectIdVal isEqual:date(6)]);
    XCTAssert([(NSNumber *)unmanaged.uuidVal isEqual:date(6)]);
    XCTAssert([(NSNumber *)managed.boolVal isEqual:date(6)]);
    XCTAssert([(NSNumber *)managed.intVal isEqual:date(6)]);
    XCTAssert([(NSNumber *)managed.floatVal isEqual:date(6)]);
    XCTAssert([(NSNumber *)managed.doubleVal isEqual:date(6)]);
    XCTAssert([(NSNumber *)managed.stringVal isEqual:date(6)]);
    XCTAssert([(NSNumber *)managed.dataVal isEqual:date(6)]);
    XCTAssert([(NSNumber *)managed.dateVal isEqual:date(6)]);
    XCTAssert([(NSNumber *)managed.decimalVal isEqual:date(6)]);
    XCTAssert([(NSNumber *)managed.objectIdVal isEqual:date(6)]);
    XCTAssert([(NSNumber *)managed.uuidVal isEqual:date(6)]);
    XCTAssertEqual(unmanaged.boolVal.rlm_valueType, RLMPropertyTypeDate);
    XCTAssertEqual(unmanaged.intVal.rlm_valueType, RLMPropertyTypeDate);
    XCTAssertEqual(unmanaged.floatVal.rlm_valueType, RLMPropertyTypeDate);
    XCTAssertEqual(unmanaged.doubleVal.rlm_valueType, RLMPropertyTypeDate);
    XCTAssertEqual(unmanaged.stringVal.rlm_valueType, RLMPropertyTypeDate);
    XCTAssertEqual(unmanaged.dataVal.rlm_valueType, RLMPropertyTypeDate);
    XCTAssertEqual(unmanaged.dateVal.rlm_valueType, RLMPropertyTypeDate);
    XCTAssertEqual(unmanaged.decimalVal.rlm_valueType, RLMPropertyTypeDate);
    XCTAssertEqual(unmanaged.objectIdVal.rlm_valueType, RLMPropertyTypeDate);
    XCTAssertEqual(unmanaged.uuidVal.rlm_valueType, RLMPropertyTypeDate);
    XCTAssertEqual(managed.boolVal.rlm_valueType, RLMPropertyTypeDate);
    XCTAssertEqual(managed.intVal.rlm_valueType, RLMPropertyTypeDate);
    XCTAssertEqual(managed.floatVal.rlm_valueType, RLMPropertyTypeDate);
    XCTAssertEqual(managed.doubleVal.rlm_valueType, RLMPropertyTypeDate);
    XCTAssertEqual(managed.stringVal.rlm_valueType, RLMPropertyTypeDate);
    XCTAssertEqual(managed.dataVal.rlm_valueType, RLMPropertyTypeDate);
    XCTAssertEqual(managed.dateVal.rlm_valueType, RLMPropertyTypeDate);
    XCTAssertEqual(managed.decimalVal.rlm_valueType, RLMPropertyTypeDate);
    XCTAssertEqual(managed.objectIdVal.rlm_valueType, RLMPropertyTypeDate);
    XCTAssertEqual(managed.uuidVal.rlm_valueType, RLMPropertyTypeDate);
}

- (void)testUpdateDecimal {
    unmanaged.boolVal = decimal128(7);
    unmanaged.intVal = decimal128(7);
    unmanaged.floatVal = decimal128(7);
    unmanaged.doubleVal = decimal128(7);
    unmanaged.stringVal = decimal128(7);
    unmanaged.dataVal = decimal128(7);
    unmanaged.dateVal = decimal128(7);
    unmanaged.decimalVal = decimal128(7);
    unmanaged.objectIdVal = decimal128(7);
    unmanaged.uuidVal = decimal128(7);
    managed.boolVal = decimal128(7);
    managed.intVal = decimal128(7);
    managed.floatVal = decimal128(7);
    managed.doubleVal = decimal128(7);
    managed.stringVal = decimal128(7);
    managed.dataVal = decimal128(7);
    managed.dateVal = decimal128(7);
    managed.decimalVal = decimal128(7);
    managed.objectIdVal = decimal128(7);
    managed.uuidVal = decimal128(7);
    XCTAssert([(NSNumber *)unmanaged.boolVal isEqual:decimal128(7)]);
    XCTAssert([(NSNumber *)unmanaged.intVal isEqual:decimal128(7)]);
    XCTAssert([(NSNumber *)unmanaged.floatVal isEqual:decimal128(7)]);
    XCTAssert([(NSNumber *)unmanaged.doubleVal isEqual:decimal128(7)]);
    XCTAssert([(NSNumber *)unmanaged.stringVal isEqual:decimal128(7)]);
    XCTAssert([(NSNumber *)unmanaged.dataVal isEqual:decimal128(7)]);
    XCTAssert([(NSNumber *)unmanaged.dateVal isEqual:decimal128(7)]);
    XCTAssert([(NSNumber *)unmanaged.decimalVal isEqual:decimal128(7)]);
    XCTAssert([(NSNumber *)unmanaged.objectIdVal isEqual:decimal128(7)]);
    XCTAssert([(NSNumber *)unmanaged.uuidVal isEqual:decimal128(7)]);
    XCTAssert([(NSNumber *)managed.boolVal isEqual:decimal128(7)]);
    XCTAssert([(NSNumber *)managed.intVal isEqual:decimal128(7)]);
    XCTAssert([(NSNumber *)managed.floatVal isEqual:decimal128(7)]);
    XCTAssert([(NSNumber *)managed.doubleVal isEqual:decimal128(7)]);
    XCTAssert([(NSNumber *)managed.stringVal isEqual:decimal128(7)]);
    XCTAssert([(NSNumber *)managed.dataVal isEqual:decimal128(7)]);
    XCTAssert([(NSNumber *)managed.dateVal isEqual:decimal128(7)]);
    XCTAssert([(NSNumber *)managed.decimalVal isEqual:decimal128(7)]);
    XCTAssert([(NSNumber *)managed.objectIdVal isEqual:decimal128(7)]);
    XCTAssert([(NSNumber *)managed.uuidVal isEqual:decimal128(7)]);
    XCTAssertEqual(unmanaged.boolVal.rlm_valueType, RLMPropertyTypeDecimal128);
    XCTAssertEqual(unmanaged.intVal.rlm_valueType, RLMPropertyTypeDecimal128);
    XCTAssertEqual(unmanaged.floatVal.rlm_valueType, RLMPropertyTypeDecimal128);
    XCTAssertEqual(unmanaged.doubleVal.rlm_valueType, RLMPropertyTypeDecimal128);
    XCTAssertEqual(unmanaged.stringVal.rlm_valueType, RLMPropertyTypeDecimal128);
    XCTAssertEqual(unmanaged.dataVal.rlm_valueType, RLMPropertyTypeDecimal128);
    XCTAssertEqual(unmanaged.dateVal.rlm_valueType, RLMPropertyTypeDecimal128);
    XCTAssertEqual(unmanaged.decimalVal.rlm_valueType, RLMPropertyTypeDecimal128);
    XCTAssertEqual(unmanaged.objectIdVal.rlm_valueType, RLMPropertyTypeDecimal128);
    XCTAssertEqual(unmanaged.uuidVal.rlm_valueType, RLMPropertyTypeDecimal128);
    XCTAssertEqual(managed.boolVal.rlm_valueType, RLMPropertyTypeDecimal128);
    XCTAssertEqual(managed.intVal.rlm_valueType, RLMPropertyTypeDecimal128);
    XCTAssertEqual(managed.floatVal.rlm_valueType, RLMPropertyTypeDecimal128);
    XCTAssertEqual(managed.doubleVal.rlm_valueType, RLMPropertyTypeDecimal128);
    XCTAssertEqual(managed.stringVal.rlm_valueType, RLMPropertyTypeDecimal128);
    XCTAssertEqual(managed.dataVal.rlm_valueType, RLMPropertyTypeDecimal128);
    XCTAssertEqual(managed.dateVal.rlm_valueType, RLMPropertyTypeDecimal128);
    XCTAssertEqual(managed.decimalVal.rlm_valueType, RLMPropertyTypeDecimal128);
    XCTAssertEqual(managed.objectIdVal.rlm_valueType, RLMPropertyTypeDecimal128);
    XCTAssertEqual(managed.uuidVal.rlm_valueType, RLMPropertyTypeDecimal128);
}

- (void)testUpdateObjectIdType {
    unmanaged.boolVal = objectId(8);
    unmanaged.intVal = objectId(8);
    unmanaged.floatVal = objectId(8);
    unmanaged.doubleVal = objectId(8);
    unmanaged.stringVal = objectId(8);
    unmanaged.dataVal = objectId(8);
    unmanaged.dateVal = objectId(8);
    unmanaged.decimalVal = objectId(8);
    unmanaged.objectIdVal = objectId(8);
    unmanaged.uuidVal = objectId(8);
    managed.boolVal = objectId(8);
    managed.intVal = objectId(8);
    managed.floatVal = objectId(8);
    managed.doubleVal = objectId(8);
    managed.stringVal = objectId(8);
    managed.dataVal = objectId(8);
    managed.dateVal = objectId(8);
    managed.decimalVal = objectId(8);
    managed.objectIdVal = objectId(8);
    managed.uuidVal = objectId(8);
    XCTAssert([(NSUUID *)unmanaged.boolVal isEqual:objectId(8)]);
    XCTAssert([(NSUUID *)unmanaged.intVal isEqual:objectId(8)]);
    XCTAssert([(NSUUID *)unmanaged.floatVal isEqual:objectId(8)]);
    XCTAssert([(NSUUID *)unmanaged.doubleVal isEqual:objectId(8)]);
    XCTAssert([(NSUUID *)unmanaged.stringVal isEqual:objectId(8)]);
    XCTAssert([(NSUUID *)unmanaged.dataVal isEqual:objectId(8)]);
    XCTAssert([(NSUUID *)unmanaged.dateVal isEqual:objectId(8)]);
    XCTAssert([(NSUUID *)unmanaged.decimalVal isEqual:objectId(8)]);
    XCTAssert([(NSUUID *)unmanaged.objectIdVal isEqual:objectId(8)]);
    XCTAssert([(NSUUID *)unmanaged.uuidVal isEqual:objectId(8)]);
    XCTAssert([(NSUUID *)managed.boolVal isEqual:objectId(8)]);
    XCTAssert([(NSUUID *)managed.intVal isEqual:objectId(8)]);
    XCTAssert([(NSUUID *)managed.floatVal isEqual:objectId(8)]);
    XCTAssert([(NSUUID *)managed.doubleVal isEqual:objectId(8)]);
    XCTAssert([(NSUUID *)managed.stringVal isEqual:objectId(8)]);
    XCTAssert([(NSUUID *)managed.dataVal isEqual:objectId(8)]);
    XCTAssert([(NSUUID *)managed.dateVal isEqual:objectId(8)]);
    XCTAssert([(NSUUID *)managed.decimalVal isEqual:objectId(8)]);
    XCTAssert([(NSUUID *)managed.objectIdVal isEqual:objectId(8)]);
    XCTAssert([(NSUUID *)managed.uuidVal isEqual:objectId(8)]);
    XCTAssertEqual(unmanaged.boolVal.rlm_valueType, RLMPropertyTypeObjectId);
    XCTAssertEqual(unmanaged.intVal.rlm_valueType, RLMPropertyTypeObjectId);
    XCTAssertEqual(unmanaged.floatVal.rlm_valueType, RLMPropertyTypeObjectId);
    XCTAssertEqual(unmanaged.doubleVal.rlm_valueType, RLMPropertyTypeObjectId);
    XCTAssertEqual(unmanaged.stringVal.rlm_valueType, RLMPropertyTypeObjectId);
    XCTAssertEqual(unmanaged.dataVal.rlm_valueType, RLMPropertyTypeObjectId);
    XCTAssertEqual(unmanaged.dateVal.rlm_valueType, RLMPropertyTypeObjectId);
    XCTAssertEqual(unmanaged.decimalVal.rlm_valueType, RLMPropertyTypeObjectId);
    XCTAssertEqual(unmanaged.objectIdVal.rlm_valueType, RLMPropertyTypeObjectId);
    XCTAssertEqual(unmanaged.uuidVal.rlm_valueType, RLMPropertyTypeObjectId);
    XCTAssertEqual(managed.boolVal.rlm_valueType, RLMPropertyTypeObjectId);
    XCTAssertEqual(managed.intVal.rlm_valueType, RLMPropertyTypeObjectId);
    XCTAssertEqual(managed.floatVal.rlm_valueType, RLMPropertyTypeObjectId);
    XCTAssertEqual(managed.doubleVal.rlm_valueType, RLMPropertyTypeObjectId);
    XCTAssertEqual(managed.stringVal.rlm_valueType, RLMPropertyTypeObjectId);
    XCTAssertEqual(managed.dataVal.rlm_valueType, RLMPropertyTypeObjectId);
    XCTAssertEqual(managed.dateVal.rlm_valueType, RLMPropertyTypeObjectId);
    XCTAssertEqual(managed.decimalVal.rlm_valueType, RLMPropertyTypeObjectId);
    XCTAssertEqual(managed.objectIdVal.rlm_valueType, RLMPropertyTypeObjectId);
    XCTAssertEqual(managed.uuidVal.rlm_valueType, RLMPropertyTypeObjectId);
}

- (void)testUpdateUuidType {
    unmanaged.boolVal = uuid(@"137DECC8-B300-4954-A233-F89909F4FD89");
    unmanaged.intVal = uuid(@"137DECC8-B300-4954-A233-F89909F4FD89");
    unmanaged.floatVal = uuid(@"137DECC8-B300-4954-A233-F89909F4FD89");
    unmanaged.doubleVal = uuid(@"137DECC8-B300-4954-A233-F89909F4FD89");
    unmanaged.stringVal = uuid(@"137DECC8-B300-4954-A233-F89909F4FD89");
    unmanaged.dataVal = uuid(@"137DECC8-B300-4954-A233-F89909F4FD89");
    unmanaged.dateVal = uuid(@"137DECC8-B300-4954-A233-F89909F4FD89");
    unmanaged.decimalVal = uuid(@"137DECC8-B300-4954-A233-F89909F4FD89");
    unmanaged.objectIdVal = uuid(@"137DECC8-B300-4954-A233-F89909F4FD89");
    unmanaged.uuidVal = uuid(@"137DECC8-B300-4954-A233-F89909F4FD89");
    managed.boolVal = uuid(@"137DECC8-B300-4954-A233-F89909F4FD89");
    managed.intVal = uuid(@"137DECC8-B300-4954-A233-F89909F4FD89");
    managed.floatVal = uuid(@"137DECC8-B300-4954-A233-F89909F4FD89");
    managed.doubleVal = uuid(@"137DECC8-B300-4954-A233-F89909F4FD89");
    managed.stringVal = uuid(@"137DECC8-B300-4954-A233-F89909F4FD89");
    managed.dataVal = uuid(@"137DECC8-B300-4954-A233-F89909F4FD89");
    managed.dateVal = uuid(@"137DECC8-B300-4954-A233-F89909F4FD89");
    managed.decimalVal = uuid(@"137DECC8-B300-4954-A233-F89909F4FD89");
    managed.objectIdVal = uuid(@"137DECC8-B300-4954-A233-F89909F4FD89");
    managed.uuidVal = uuid(@"137DECC8-B300-4954-A233-F89909F4FD89");
    XCTAssert([(NSUUID *)unmanaged.boolVal isEqual:uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")]);
    XCTAssert([(NSUUID *)unmanaged.intVal isEqual:uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")]);
    XCTAssert([(NSUUID *)unmanaged.floatVal isEqual:uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")]);
    XCTAssert([(NSUUID *)unmanaged.doubleVal isEqual:uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")]);
    XCTAssert([(NSUUID *)unmanaged.stringVal isEqual:uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")]);
    XCTAssert([(NSUUID *)unmanaged.dataVal isEqual:uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")]);
    XCTAssert([(NSUUID *)unmanaged.dateVal isEqual:uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")]);
    XCTAssert([(NSUUID *)unmanaged.decimalVal isEqual:uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")]);
    XCTAssert([(NSUUID *)unmanaged.objectIdVal isEqual:uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")]);
    XCTAssert([(NSUUID *)unmanaged.uuidVal isEqual:uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")]);
    XCTAssert([(NSUUID *)managed.boolVal isEqual:uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")]);
    XCTAssert([(NSUUID *)managed.intVal isEqual:uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")]);
    XCTAssert([(NSUUID *)managed.floatVal isEqual:uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")]);
    XCTAssert([(NSUUID *)managed.doubleVal isEqual:uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")]);
    XCTAssert([(NSUUID *)managed.stringVal isEqual:uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")]);
    XCTAssert([(NSUUID *)managed.dataVal isEqual:uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")]);
    XCTAssert([(NSUUID *)managed.dateVal isEqual:uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")]);
    XCTAssert([(NSUUID *)managed.decimalVal isEqual:uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")]);
    XCTAssert([(NSUUID *)managed.objectIdVal isEqual:uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")]);
    XCTAssert([(NSUUID *)managed.uuidVal isEqual:uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")]);
    XCTAssertEqual(unmanaged.boolVal.rlm_valueType, RLMPropertyTypeUUID);
    XCTAssertEqual(unmanaged.intVal.rlm_valueType, RLMPropertyTypeUUID);
    XCTAssertEqual(unmanaged.floatVal.rlm_valueType, RLMPropertyTypeUUID);
    XCTAssertEqual(unmanaged.doubleVal.rlm_valueType, RLMPropertyTypeUUID);
    XCTAssertEqual(unmanaged.stringVal.rlm_valueType, RLMPropertyTypeUUID);
    XCTAssertEqual(unmanaged.dataVal.rlm_valueType, RLMPropertyTypeUUID);
    XCTAssertEqual(unmanaged.dateVal.rlm_valueType, RLMPropertyTypeUUID);
    XCTAssertEqual(unmanaged.decimalVal.rlm_valueType, RLMPropertyTypeUUID);
    XCTAssertEqual(unmanaged.objectIdVal.rlm_valueType, RLMPropertyTypeUUID);
    XCTAssertEqual(unmanaged.uuidVal.rlm_valueType, RLMPropertyTypeUUID);
    XCTAssertEqual(managed.boolVal.rlm_valueType, RLMPropertyTypeUUID);
    XCTAssertEqual(managed.intVal.rlm_valueType, RLMPropertyTypeUUID);
    XCTAssertEqual(managed.floatVal.rlm_valueType, RLMPropertyTypeUUID);
    XCTAssertEqual(managed.doubleVal.rlm_valueType, RLMPropertyTypeUUID);
    XCTAssertEqual(managed.stringVal.rlm_valueType, RLMPropertyTypeUUID);
    XCTAssertEqual(managed.dataVal.rlm_valueType, RLMPropertyTypeUUID);
    XCTAssertEqual(managed.dateVal.rlm_valueType, RLMPropertyTypeUUID);
    XCTAssertEqual(managed.decimalVal.rlm_valueType, RLMPropertyTypeUUID);
    XCTAssertEqual(managed.objectIdVal.rlm_valueType, RLMPropertyTypeUUID);
    XCTAssertEqual(managed.uuidVal.rlm_valueType, RLMPropertyTypeUUID);
}

@end
