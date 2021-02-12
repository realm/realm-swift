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

- (void)testIntInitialization {
    id<RLMValue> v = @123;
    XCTAssertEqual(v, @123);
    XCTAssertEqual(v.valueType, RLMPropertyTypeInt);
    v = @456;
    XCTAssertEqual(v, @456);
    XCTAssertEqual(v.valueType, RLMPropertyTypeInt);
}

- (void)testFloatInitialization {
    id<RLMValue> v = @123.456;
    XCTAssertTrue([(NSNumber *)v isEqualToNumber:@123.456]);
    XCTAssertEqual(v.valueType, RLMPropertyTypeFloat);
    v = @456.789;
    XCTAssertTrue([(NSNumber *)v isEqualToNumber:@456.789]);
    XCTAssertEqual(v.valueType, RLMPropertyTypeFloat);
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

#pragma mark - Managed Values

- (void)testCreateManagedObjectManagedChild {
    StringObject *so = [[StringObject alloc] init];
    so.stringCol = @"hello";
    
    RLMRealm *r = [self realmWithTestPath];
    [r beginWriteTransaction];
    [r addObject:so];
    MixedObject *mo0 = [MixedObject createInRealm:r withValue:@[so, @[so]]]; // ???: No warning, see mo0.anyArray.
    
    MixedObject *mo1 = [[MixedObject alloc] init];
    mo1.anyCol = so;
    mo1.anyArray = @[so]; // ???: Incompatible pointer types assigning to 'RLMArray<RLMValue> *' from 'NSArray *', expect no warning on array literal?
    [r commitWriteTransaction];
    
    XCTAssertNotNil(mo0.anyCol);
    XCTAssertNotNil(mo1.anyCol);
    XCTAssertTrue([((StringObject *)mo0.anyCol).stringCol isEqualToString:so.stringCol]);
    XCTAssertTrue([((StringObject *)mo1.anyCol).stringCol isEqualToString:so.stringCol]);
    XCTAssertEqual(mo0.anyCol.valueType, RLMPropertyTypeObject);
    XCTAssertEqual(mo1.anyCol.valueType, RLMPropertyTypeObject);
    
    // ???: First object has no stringCol
//    XCTAssertTrue([mo0.anyArray.firstObject.stringCol isEqualToString:so.stringCol]);
//    XCTAssertTrue([mo1.anyArray.firstObject.stringCol isEqualToString:so.stringCol]);
}

// Different behavior
- (void)testCreateManagedObjectUnmanagedChild {
    StringObject *so = [[StringObject alloc] init];
    so.stringCol = @"hello";
    
    RLMRealm *r = [self realmWithTestPath];
    [r beginWriteTransaction];
    MixedObject *mo0 = [MixedObject createInRealm:r withValue:@[so, @[so]]]; // ???: No warning, see mo0.anyArray.
    
    MixedObject *mo1 = [[MixedObject alloc] init];
    mo1.anyCol = so;
    mo1.anyArray = @[so]; // ???: Incompatible pointer types assigning to 'RLMArray<RLMValue> *' from 'NSArray *', expect no warning on array literal?
    [r commitWriteTransaction];
    
    XCTAssertNotNil(mo0.anyCol); // Fails when the parent is managed, but property is unmanaged. Not sure what the expectation should be, but I'm surprised it's inconsistent with the other managed Parent. Perhaps an exception in the write transaction when attempting to write with unmanaged child?
    XCTAssertNotNil(mo1.anyCol);
    XCTAssertTrue([((StringObject *)mo0.anyCol).stringCol isEqualToString:so.stringCol]); // Fails when the parent is managed, but property is unmanaged. Not sure what the expectation should be, but I'm surprised it's inconsistent with the other managed Parent.
    XCTAssertTrue([((StringObject *)mo1.anyCol).stringCol isEqualToString:so.stringCol]);
    XCTAssertEqual(mo0.anyCol.valueType, RLMPropertyTypeObject); // Fails when the parent is managed, but property is unmanaged
    XCTAssertEqual(mo1.anyCol.valueType, RLMPropertyTypeObject);
    
    // ???: Subscripted so has no stringCol
//    XCTAssertTrue([mo0.anyArray[0].stringCol isEqualToString:so.stringCol]);
//    XCTAssertTrue([mo1.anyArray[0].stringCol isEqualToString:so.stringCol]);
}

// difference between adding object and not!
- (void)testCreateManagedObject {
    RLMRealm *r = [self realmWithTestPath];
    [r beginWriteTransaction];
    StringObject *so = [StringObject createInRealm:r withValue:@[@"hello"]];
    MixedObject *mo = [MixedObject createInRealm:r withValue:@[so, @[]]];
    [r commitWriteTransaction];
    XCTAssertTrue([((StringObject *)mo.anyCol).stringCol isEqualToString:so.stringCol]);
    XCTAssertEqual(mo.anyCol.valueType, RLMPropertyTypeObject);
}

- (void)testCreateManagedInt {
    RLMRealm *r = [self realmWithTestPath];
    [r beginWriteTransaction];
    MixedObject *mo = [MixedObject createInRealm:r withValue:@[@123456789, @[@123456, @67890]]];
    [r commitWriteTransaction];
    XCTAssertTrue([(NSNumber *)mo.anyCol isEqualToNumber:@123456789]);
    XCTAssertTrue([mo.anyArray[0] isEqualToNumber:@123456]);
    XCTAssertTrue([mo.anyArray[1] isEqualToNumber:@67890]);
    XCTAssertEqual(mo.anyCol.valueType, RLMPropertyTypeInt);
}

- (void)testCreateManagedFloat {
    RLMRealm *r = [self realmWithTestPath];
    [r beginWriteTransaction];
    MixedObject *mo = [MixedObject createInRealm:r withValue:@[@1234.5, @[@12345.6, @678.9]]];
    [r commitWriteTransaction];
    XCTAssertTrue([(NSNumber *)mo.anyCol isEqualToNumber:@1234.5]);
    XCTAssertTrue([mo.anyArray[0] isEqualToNumber:[NSNumber numberWithFloat:12345.6]]);
    XCTAssertTrue([mo.anyArray[1] isEqualToNumber:[NSNumber numberWithFloat:678.9]]);
    XCTAssertEqual(mo.anyCol.valueType, RLMPropertyTypeFloat);
}

- (void)testCreateManagedString {
    RLMRealm *r = [self realmWithTestPath];
    [r beginWriteTransaction];
    MixedObject *mo = [MixedObject createInRealm:r withValue:@[@"hello", @[@"over", @"there"]]];
    [r commitWriteTransaction];
    XCTAssertTrue([(NSString *)mo.anyCol isEqualToString:@"hello"]);
    XCTAssertTrue([mo.anyArray[0] isEqualToString:@"over"]);
    XCTAssertTrue([mo.anyArray[1] isEqualToString:@"there"]);
    XCTAssertEqual(mo.anyCol.valueType, RLMPropertyTypeString);
}

- (void)testCreateManagedData {
    RLMRealm *r = [self realmWithTestPath];
    NSData *d1 = [NSData dataWithBytes:"hey" length:3];
    NSData *d2 = [NSData dataWithBytes:"you" length:3];

    [r beginWriteTransaction];
    MixedObject *mo = [MixedObject createInRealm:r withValue:@[d1, @[d1, d2]]];
    [r commitWriteTransaction];

    XCTAssertTrue([[[NSString alloc] initWithData:(NSData *)mo.anyCol
                                         encoding:NSUTF8StringEncoding] isEqualToString:@"hey"]);
    XCTAssertTrue([[[NSString alloc] initWithData:mo.anyArray[0]
                                         encoding:NSUTF8StringEncoding] isEqualToString:@"hey"]);
    XCTAssertTrue([[[NSString alloc] initWithData:mo.anyArray[1]
                                         encoding:NSUTF8StringEncoding] isEqualToString:@"you"]);
    XCTAssertEqual(mo.anyCol.valueType, RLMPropertyTypeData);
}

- (void)testCreateManagedDate {
    RLMRealm *r = [self realmWithTestPath];
    NSDate *d1 = [NSDate now];
    NSDate *d2 = [NSDate now];

    [r beginWriteTransaction];
    MixedObject *mo = [MixedObject createInRealm:r withValue:@[d1, @[d1, d2]]];
    [r commitWriteTransaction];

    // handle lossy margin of error.
    XCTAssertNotEqualWithAccuracy(d1.timeIntervalSince1970, ((NSDate *)mo.anyCol).timeIntervalSince1970, .1);
    XCTAssertNotEqualWithAccuracy(d1.timeIntervalSince1970, ((NSDate *)mo.anyArray[0]).timeIntervalSince1970, .1);
    XCTAssertNotEqualWithAccuracy(d2.timeIntervalSince1970, ((NSDate *)mo.anyArray[1]).timeIntervalSince1970, .1);
    XCTAssertEqual(mo.anyCol.valueType, RLMPropertyTypeDate);
}

- (void)testCreateManagedObjectId {
    RLMRealm *r = [self realmWithTestPath];
    RLMObjectId *oid1 = [RLMObjectId objectId];
    RLMObjectId *oid2 = [RLMObjectId objectId];

    [r beginWriteTransaction];
    MixedObject *mo = [MixedObject createInRealm:r withValue:@[oid1, @[oid1, oid2]]];
    [r commitWriteTransaction];

    XCTAssertTrue([(RLMObjectId *)mo.anyCol isEqualTo:oid1]);
    XCTAssertTrue([(RLMObjectId *)mo.anyArray[0] isEqualTo:oid1]);
    XCTAssertTrue([(RLMObjectId *)mo.anyArray[1] isEqualTo:oid2]);
    XCTAssertEqual(mo.anyCol.valueType, RLMPropertyTypeObjectId);
}

- (void)testCreateManagedDecimal128 {
    RLMRealm *r = [self realmWithTestPath];
    RLMDecimal128 *d1 = [RLMDecimal128 decimalWithNumber:@123.456];
    RLMDecimal128 *d2 = [RLMDecimal128 decimalWithNumber:@890.456];

    [r beginWriteTransaction];
    MixedObject *mo = [MixedObject createInRealm:r withValue:@[d1, @[d1, d2]]];
    [r commitWriteTransaction];

    XCTAssertTrue([(RLMDecimal128 *)mo.anyCol isEqualTo:d1]);
    XCTAssertTrue([(RLMDecimal128 *)mo.anyArray[0] isEqualTo:d1]);
    XCTAssertTrue([(RLMDecimal128 *)mo.anyArray[1] isEqualTo:d2]);
    XCTAssertEqual(mo.anyCol.valueType, RLMPropertyTypeDecimal128);
}

#pragma mark - Add Managed Values

- (void)testAddManagedObject {
    StringObject *so = [[StringObject alloc] init];
    so.stringCol = @"hello";
    MixedObject *mo1 = [[MixedObject alloc] init];
    mo1.anyCol = so;
    mo1.anyArray = @[so]; // ???: Incompatible pointer types assigning to 'RLMArray<RLMValue> *' from 'NSArray *'
    
    RLMRealm *r = [self realmWithTestPath];
    [r beginWriteTransaction];
    [r addObject:so];
    [r addObject:mo1];
    [r commitWriteTransaction];
    
    XCTAssertNotNil(mo1.anyCol);
    XCTAssertTrue([((StringObject *)mo1.anyCol).stringCol isEqualToString:so.stringCol]);
    XCTAssertEqual(mo1.anyCol.valueType, RLMPropertyTypeObject);
}

- (void)testAddManagedInt {
    MixedObject *mo = [[MixedObject alloc] init];
    mo.anyCol = @123456789;
    mo.anyArray = @[@123456, @67890]; // ???: Incompatible pointer types assigning to 'RLMArray<RLMValue> *' from 'NSArray *'
    
    RLMRealm *r = [self realmWithTestPath];
    [r beginWriteTransaction];
    [r addObject:mo];
    [r commitWriteTransaction];
    
    XCTAssertTrue([(NSNumber *)mo.anyCol isEqualToNumber:@123456789]);
    XCTAssertTrue([mo.anyArray[0] isEqualToNumber:@123456]);
    XCTAssertTrue([mo.anyArray[1] isEqualToNumber:@67890]);
    XCTAssertEqual(mo.anyCol.valueType, RLMPropertyTypeInt);
}

- (void)testAddManagedFloat {
    MixedObject *mo = [[MixedObject alloc] init];
    mo.anyCol = @1234.5;
    mo.anyArray = @[@12345.6, @678.9]; // ???: Incompatible pointer types assigning to 'RLMArray<RLMValue> *' from 'NSArray *'
    
    RLMRealm *r = [self realmWithTestPath];
    [r beginWriteTransaction];
    [r addObject:mo];
    [r commitWriteTransaction];
    XCTAssertTrue([(NSNumber *)mo.anyCol isEqualToNumber:@1234.5]);
    XCTAssertTrue([mo.anyArray[0] isEqualToNumber:[NSNumber numberWithFloat:12345.6]]);
    XCTAssertTrue([mo.anyArray[1] isEqualToNumber:[NSNumber numberWithFloat:678.9]]);
    XCTAssertEqual(mo.anyCol.valueType, RLMPropertyTypeFloat);
}

- (void)testAddManagedString {
    MixedObject *mo = [[MixedObject alloc] init];
    mo.anyCol = @"hello";
    mo.anyArray = @[@"over", @"there"]; // ???: Incompatible pointer types assigning to 'RLMArray<RLMValue> *' from 'NSArray *'
    
    RLMRealm *r = [self realmWithTestPath];
    [r beginWriteTransaction];
    [r addObject:mo];
    [r commitWriteTransaction];
    XCTAssertTrue([(NSString *)mo.anyCol isEqualToString:@"hello"]);
    XCTAssertTrue([mo.anyArray[0] isEqualToString:@"over"]);
    XCTAssertTrue([mo.anyArray[1] isEqualToString:@"there"]);
    XCTAssertEqual(mo.anyCol.valueType, RLMPropertyTypeString);
}

- (void)testAddManagedData {
    NSData *d1 = [NSData dataWithBytes:"hey" length:3];
    NSData *d2 = [NSData dataWithBytes:"you" length:3];
    MixedObject *mo = [[MixedObject alloc] init];
    mo.anyCol = d1;
    mo.anyArray = @[d1, d2]; // ???: Incompatible pointer types assigning to 'RLMArray<RLMValue> *' from 'NSArray *'
    
    RLMRealm *r = [self realmWithTestPath];
    [r beginWriteTransaction];
    [r addObject:mo];
    [r commitWriteTransaction];

    XCTAssertTrue([[[NSString alloc] initWithData:(NSData *)mo.anyCol
                                         encoding:NSUTF8StringEncoding] isEqualToString:@"hey"]);
    XCTAssertTrue([[[NSString alloc] initWithData:mo.anyArray[0]
                                         encoding:NSUTF8StringEncoding] isEqualToString:@"hey"]);
    XCTAssertTrue([[[NSString alloc] initWithData:mo.anyArray[1]
                                         encoding:NSUTF8StringEncoding] isEqualToString:@"you"]);
    XCTAssertEqual(mo.anyCol.valueType, RLMPropertyTypeData);
}

- (void)testAddManagedDate {
    NSDate *d1 = [NSDate now];
    NSDate *d2 = [NSDate now];
    MixedObject *mo = [[MixedObject alloc] init];
    mo.anyCol = d1;
    mo.anyArray = @[d1, d2]; // ???: Incompatible pointer types assigning to 'RLMArray<RLMValue> *' from 'NSArray *'
    
    RLMRealm *r = [self realmWithTestPath];
    [r beginWriteTransaction];
    [r addObject:mo];
    [r commitWriteTransaction];

    // handle lossy margin of error.
    XCTAssertNotEqualWithAccuracy(d1.timeIntervalSince1970, ((NSDate *)mo.anyCol).timeIntervalSince1970, .1);
    XCTAssertNotEqualWithAccuracy(d1.timeIntervalSince1970, ((NSDate *)mo.anyArray[0]).timeIntervalSince1970, .1);
    XCTAssertNotEqualWithAccuracy(d2.timeIntervalSince1970, ((NSDate *)mo.anyArray[1]).timeIntervalSince1970, .1);
    XCTAssertEqual(mo.anyCol.valueType, RLMPropertyTypeDate);
}

- (void)testAddManagedObjectId {
    RLMObjectId *oid1 = [RLMObjectId objectId];
    RLMObjectId *oid2 = [RLMObjectId objectId];
    MixedObject *mo = [[MixedObject alloc] init];
    mo.anyCol = oid1;
    mo.anyArray = @[oid1, oid2]; // ???: Incompatible pointer types assigning to 'RLMArray<RLMValue> *' from 'NSArray *'
    
    RLMRealm *r = [self realmWithTestPath];
    [r beginWriteTransaction];
    [r addObject:mo];
    [r commitWriteTransaction];

    XCTAssertTrue([(RLMObjectId *)mo.anyCol isEqualTo:oid1]);
    XCTAssertTrue([(RLMObjectId *)mo.anyArray[0] isEqualTo:oid1]);
    XCTAssertTrue([(RLMObjectId *)mo.anyArray[1] isEqualTo:oid2]);
    XCTAssertEqual(mo.anyCol.valueType, RLMPropertyTypeObjectId);
}

- (void)testAddManagedDecimal128 {
    RLMDecimal128 *d1 = [RLMDecimal128 decimalWithNumber:@123.456];
    RLMDecimal128 *d2 = [RLMDecimal128 decimalWithNumber:@890.456];
    MixedObject *mo = [[MixedObject alloc] init];
    mo.anyCol = d1;
    mo.anyArray = @[d1, d2]; // ???: Incompatible pointer types assigning to 'RLMArray<RLMValue> *' from 'NSArray *'
    
    RLMRealm *r = [self realmWithTestPath];
    [r beginWriteTransaction];
    [r addObject:mo];
    [r commitWriteTransaction];

    XCTAssertTrue([(RLMDecimal128 *)mo.anyCol isEqualTo:d1]);
    XCTAssertTrue([(RLMDecimal128 *)mo.anyArray[0] isEqualTo:d1]);
    XCTAssertTrue([(RLMDecimal128 *)mo.anyArray[1] isEqualTo:d2]);
    XCTAssertEqual(mo.anyCol.valueType, RLMPropertyTypeDecimal128);
}


#pragma mark - change managed value types

@end
