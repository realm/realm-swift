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
#import <Realm/RLMValue.h>

@interface RLMValueTests : RLMTestCase
@end

@implementation RLMValueTests

#pragma mark - Initialization

- (void)testNumberInitialization {
    id<RLMValue> v = @123;
    XCTAssertEqual(v, @123);
    XCTAssertEqual(v.valueType, RLMPropertyTypeInt);
    v = @456;
    XCTAssertEqual(v, @456);
    XCTAssertEqual(v.valueType, RLMPropertyTypeInt);
}

- (void)testStringInitialization {
    id<RLMValue> v = @"hello";
    XCTAssertEqual(v, @"hello");
    XCTAssertEqual(v.valueType, RLMPropertyTypeString);
    v = @"there";
    XCTAssertEqual(v, @"there");
    XCTAssertEqual(v.valueType, RLMPropertyTypeString);
}

- (void)testDataInitialization {
    NSData *d = [NSData dataWithBytes:"hey" length:3];
    id<RLMValue> v = d;
    XCTAssertEqual(v, d);
    XCTAssertEqual(v.valueType, RLMPropertyTypeData);
    d = [NSData dataWithBytes:"there" length:5];
    v = d;
    XCTAssertEqual(v, d);
    XCTAssertEqual(v.valueType, RLMPropertyTypeData);
}

- (void)testDateInitialization {
    NSDate *d = [NSDate now];
    id<RLMValue> v = d;
    XCTAssertEqual(v, d);
    XCTAssertEqual(v.valueType, RLMPropertyTypeDate);
    d = [NSDate now];
    v = d;
    XCTAssertEqual(v, d);
    XCTAssertEqual(v.valueType, RLMPropertyTypeDate);
}

- (void)testObjectInitialization {
    StringObject *so = [[StringObject alloc] init];
    id<RLMValue> v = so;
    XCTAssertEqual(v, so);
    XCTAssertEqual(v.valueType, RLMPropertyTypeObject);
    so = [[StringObject alloc] init];
    v = so;
    XCTAssertEqual(v, so);
    XCTAssertEqual(v.valueType, RLMPropertyTypeObject);
}

- (void)testObjectIdInitialization {
    RLMObjectId *oid = [RLMObjectId objectId];
    id<RLMValue> v = oid;
    XCTAssertEqual(v, oid);
    XCTAssertEqual(v.valueType, RLMPropertyTypeObjectId);
    oid = [RLMObjectId objectId];
    v = oid;
    XCTAssertEqual(v, oid);
    XCTAssertEqual(v.valueType, RLMPropertyTypeObjectId);
}

- (void)testDecimal128Initialization {
    RLMDecimal128 *d = [RLMDecimal128 decimalWithNumber:@123.456];
    id<RLMValue> v = d;
    XCTAssertEqual(v, d);
    XCTAssertEqual(v.valueType, RLMPropertyTypeDecimal128);
    d = [RLMDecimal128 decimalWithNumber:@456.123];
    v = d;
    XCTAssertEqual(v, d);
    XCTAssertEqual(v.valueType, RLMPropertyTypeDecimal128);
}

#pragma mark - Comparison

- (void)testNumberEquals {
    id<RLMValue> v1 = @123;
    id<RLMValue> v2 = @123;

    XCTAssertEqual(v1, v2);
    XCTAssertEqual(v1.valueType, RLMPropertyTypeInt);
    XCTAssertEqual(v2.valueType, RLMPropertyTypeInt);
    XCTAssertNotEqual(v2, @456);
}

- (void)testStringEquals {
    id<RLMValue> v1 = @"hello";
    id<RLMValue> v2 = @"hello";

    XCTAssertEqual(v1, v2);
    XCTAssertEqual(v1.valueType, RLMPropertyTypeString);
    XCTAssertEqual(v2.valueType, RLMPropertyTypeString);
    XCTAssertNotEqual(v2, @"there");
}

- (void)testDataEquals {
    NSData *d = [NSData dataWithBytes:"hey" length:3];
    id<RLMValue> v1 = [d copy];
    id<RLMValue> v2 = [d copy];
    XCTAssertEqual(v1, v2);
    XCTAssertEqual(v1.valueType, RLMPropertyTypeData);
    XCTAssertEqual(v2.valueType, RLMPropertyTypeData);
    XCTAssertNotEqual(v1, [NSData dataWithBytes:"there" length:5]);
}

- (void)testDateEquals {
    NSDate *d = [NSDate now];
    id<RLMValue> v1 = [d copy];
    id<RLMValue> v2 = [d copy];
    XCTAssertEqual(v1, v2);
    XCTAssertEqual(v1.valueType, RLMPropertyTypeDate);
    XCTAssertEqual(v2.valueType, RLMPropertyTypeDate);
    XCTAssertNotEqual(v1, [NSDate now]);
}

- (void)testObjectEquals {
    StringObject *so = [[StringObject alloc] init];
    id<RLMValue> v1 = so;
    id<RLMValue> v2 = so;
    XCTAssertEqual(v1, so);
    XCTAssertEqual(v2, so);
    XCTAssertEqual(v1.valueType, RLMPropertyTypeObject);
    XCTAssertEqual(v2.valueType, RLMPropertyTypeObject);
    XCTAssertEqual(v1, v2);
    XCTAssertNotEqual(v1, [[StringObject alloc] init]);
}

- (void)testObjectIdEquals {
    RLMObjectId *oid = [RLMObjectId objectId];
    id<RLMValue> v1 = oid;
    id<RLMValue> v2 = oid;
    XCTAssertEqual(v1, oid);
    XCTAssertEqual(v2, oid);
    XCTAssertEqual(v1.valueType, RLMPropertyTypeObjectId);
    XCTAssertEqual(v2.valueType, RLMPropertyTypeObjectId);
    XCTAssertEqual(v1, v2);
    XCTAssertNotEqual(v1, [RLMObjectId objectId]);
}

- (void)testDecimal128Equals {
    RLMDecimal128 *d = [RLMDecimal128 decimalWithNumber:@123.456];
    id<RLMValue> v1 = d;
    id<RLMValue> v2 = d;
    XCTAssertEqual(v1, d);
    XCTAssertEqual(v2, d);
    XCTAssertEqual(v1.valueType, RLMPropertyTypeDecimal128);
    XCTAssertEqual(v2.valueType, RLMPropertyTypeDecimal128);
    XCTAssertEqual(v1, v2);
    XCTAssertNotEqual(v1, [RLMDecimal128 decimalWithNumber:@456.123]);
}

#pragma mark - Miscellaneous

- (void)testManagedObject {
    RLMRealm *r = [self realmWithTestPath];
    [r beginWriteTransaction];
    StringObject *so = [StringObject createInRealm:r withValue:@[@"hello"]];
    MixedObject *mo = [MixedObject createInRealm:r withValue:@[so, @[]]];
    [r commitWriteTransaction];

    XCTAssertEqual(mo.anyCol, so);
    XCTAssertEqual(mo.anyCol.valueType, RLMPropertyTypeObject);
}

@end
