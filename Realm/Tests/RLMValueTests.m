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

#pragma mark - Type Checking

- (void)testIntType {
    id<RLMValue> v = @123;
    XCTAssertEqual(v.rlm_valueType, RLMPropertyTypeInt);
}

- (void)testFloatType {
    id<RLMValue> v = @123.456f;
    XCTAssertEqual(v.rlm_valueType, RLMPropertyTypeFloat);
}

- (void)testStringType {
    id<RLMValue> v = @"hello";
    XCTAssertEqual(v.rlm_valueType, RLMPropertyTypeString);
}

- (void)testDataType {
    id<RLMValue> v = [NSData dataWithBytes:"hey" length:3];
    XCTAssertEqual(v.rlm_valueType, RLMPropertyTypeData);
}

- (void)testDateType {
    id<RLMValue> v = [NSDate date];
    XCTAssertEqual(v.rlm_valueType, RLMPropertyTypeDate);
}

- (void)testObjectType {
    id<RLMValue> v = [[StringObject alloc] init];
    XCTAssertEqual(v.rlm_valueType, RLMPropertyTypeObject);
}

- (void)testObjectIdType {
    id<RLMValue> v = [RLMObjectId objectId];
    XCTAssertEqual(v.rlm_valueType, RLMPropertyTypeObjectId);
}

- (void)testDecimal128Type {
    id<RLMValue> v = [RLMDecimal128 decimalWithNumber:@123.456];
    XCTAssertEqual(v.rlm_valueType, RLMPropertyTypeDecimal128);
}

#pragma mark - Comparison

- (void)testNumberEquals {
    id<RLMValue> v1 = @123;
    id<RLMValue> v2 = @123;

    XCTAssertEqual(v1, v2);
    XCTAssertEqual(v1.rlm_valueType, RLMPropertyTypeInt);
    XCTAssertEqual(v2.rlm_valueType, RLMPropertyTypeInt);
    XCTAssertNotEqual(v2, @456);
}

- (void)testStringEquals {
    id<RLMValue> v1 = @"hello";
    id<RLMValue> v2 = @"hello";

    XCTAssertEqual(v1, v2);
    XCTAssertEqual(v1.rlm_valueType, RLMPropertyTypeString);
    XCTAssertEqual(v2.rlm_valueType, RLMPropertyTypeString);
    XCTAssertNotEqual(v2, @"there");
}

- (void)testDataEquals {
    NSData *d = [NSData dataWithBytes:"hey" length:3];
    id<RLMValue> v1 = [d copy];
    id<RLMValue> v2 = [d copy];
    XCTAssertEqual(v1, v2);
    XCTAssertEqual(v1.rlm_valueType, RLMPropertyTypeData);
    XCTAssertEqual(v2.rlm_valueType, RLMPropertyTypeData);
    XCTAssertNotEqual(v1, [NSData dataWithBytes:"there" length:5]);
}

- (void)testDateEquals {
    NSDate *d = [NSDate date];
    id<RLMValue> v1 = [d copy];
    id<RLMValue> v2 = [d copy];
    XCTAssertEqual(v1, v2);
    XCTAssertEqual(v1.rlm_valueType, RLMPropertyTypeDate);
    XCTAssertEqual(v2.rlm_valueType, RLMPropertyTypeDate);
    XCTAssertNotEqual(v1, [NSDate dateWithTimeIntervalSince1970:0]);
}

- (void)testObjectEquals {
    StringObject *so = [[StringObject alloc] init];
    id<RLMValue> v1 = so;
    id<RLMValue> v2 = so;
    XCTAssertEqual(v1, so);
    XCTAssertEqual(v2, so);
    XCTAssertEqual(v1.rlm_valueType, RLMPropertyTypeObject);
    XCTAssertEqual(v2.rlm_valueType, RLMPropertyTypeObject);
    XCTAssertEqual(v1, v2);
    XCTAssertNotEqual(v1, [[StringObject alloc] init]);
}

- (void)testObjectIdEquals {
    RLMObjectId *oid = [RLMObjectId objectId];
    id<RLMValue> v1 = oid;
    id<RLMValue> v2 = oid;
    XCTAssertEqual(v1, oid);
    XCTAssertEqual(v2, oid);
    XCTAssertEqual(v1.rlm_valueType, RLMPropertyTypeObjectId);
    XCTAssertEqual(v2.rlm_valueType, RLMPropertyTypeObjectId);
    XCTAssertEqual(v1, v2);
    XCTAssertNotEqual(v1, [RLMObjectId objectId]);
}

- (void)testDecimal128Equals {
    RLMDecimal128 *d = [RLMDecimal128 decimalWithNumber:@123.456];
    id<RLMValue> v1 = d;
    id<RLMValue> v2 = d;
    XCTAssertEqual(v1, d);
    XCTAssertEqual(v2, d);
    XCTAssertEqual(v1.rlm_valueType, RLMPropertyTypeDecimal128);
    XCTAssertEqual(v2.rlm_valueType, RLMPropertyTypeDecimal128);
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
    MixedObject *mo0 = [MixedObject createInRealm:r withValue:@[so, @[so]]];
    
    MixedObject *mo1 = [[MixedObject alloc] init];
    mo1.anyCol = so;
    [mo1.anyArray addObject:so];
    [r commitWriteTransaction];
    
    XCTAssertNotNil(mo0.anyCol);
    XCTAssertTrue([((StringObject *)mo0.anyCol).stringCol isEqualToString:so.stringCol]);
    XCTAssertEqual(mo0.anyCol.rlm_valueType, RLMPropertyTypeObject);
    XCTAssertTrue([((StringObject *)mo0.anyArray.firstObject).stringCol isEqualToString:so.stringCol]);

    XCTAssertNotNil(mo1.anyCol);
    XCTAssertTrue([((StringObject *)mo1.anyCol).stringCol isEqualToString:so.stringCol]);
    XCTAssertEqual(mo1.anyCol.rlm_valueType, RLMPropertyTypeObject);
    XCTAssertTrue([((StringObject *)mo1.anyArray.firstObject).stringCol isEqualToString:so.stringCol]);
}

- (void)testCreateManagedObjectUnmanagedChild {
    StringObject *so = [[StringObject alloc] init];
    so.stringCol = @"hello";

    StringObject *so1 = [[StringObject alloc] init];
    so1.stringCol = @"hello2";
    
    RLMRealm *r = [self realmWithTestPath];
    [r beginWriteTransaction];
    MixedObject *mo0 = [MixedObject createInRealm:r withValue:@[so, @[so]]];
    
    MixedObject *mo1 = [[MixedObject alloc] init];
    [mo1.anyArray addObject:so];
    [r addObject:mo1];
    [r commitWriteTransaction];

    XCTAssertThrows(mo1.anyCol = so1);
    [r beginWriteTransaction];
    mo1.anyCol = so1;
    
    XCTAssertNotNil(mo0.anyCol);
    XCTAssertTrue([((StringObject *)mo0.anyCol).stringCol isEqualToString:so.stringCol]);
    XCTAssertEqual(mo0.anyCol.rlm_valueType, RLMPropertyTypeObject);
    XCTAssertTrue([((StringObject *)mo0.anyArray[0]).stringCol isEqualToString:so.stringCol]);

    XCTAssertNotNil(mo1.anyCol);
    XCTAssertTrue([((StringObject *)mo1.anyCol).stringCol isEqualToString:so1.stringCol]);
    XCTAssertEqual(mo1.anyCol.rlm_valueType, RLMPropertyTypeObject);
    XCTAssertTrue([((StringObject *)mo1.anyArray[0]).stringCol isEqualToString:so.stringCol]);
}

// difference between adding object and not!
- (void)testCreateManagedObject {
    RLMRealm *r = [self realmWithTestPath];
    [r beginWriteTransaction];
    StringObject *so = [StringObject createInRealm:r withValue:@[@"hello"]];
    MixedObject *mo = [MixedObject createInRealm:r withValue:@[so, @[]]];
    [r commitWriteTransaction];
    XCTAssertTrue([((StringObject *)mo.anyCol).stringCol isEqualToString:so.stringCol]);
    XCTAssertEqual(mo.anyCol.rlm_valueType, RLMPropertyTypeObject);
}

- (void)testCreateManagedInt {
    RLMRealm *r = [self realmWithTestPath];
    [r beginWriteTransaction];
    MixedObject *mo = [MixedObject createInRealm:r withValue:@[@123456789, @[@123456, @67890]]];
    [r commitWriteTransaction];
    XCTAssertTrue([(NSNumber *)mo.anyCol isEqualToNumber:@123456789]);
    XCTAssertTrue([mo.anyArray[0] isEqualToNumber:@123456]);
    XCTAssertTrue([mo.anyArray[1] isEqualToNumber:@67890]);
    XCTAssertEqual(mo.anyCol.rlm_valueType, RLMPropertyTypeInt);
}

- (void)testCreateManagedFloat {
    RLMRealm *r = [self realmWithTestPath];
    [r beginWriteTransaction];
    MixedObject *mo = [MixedObject createInRealm:r withValue:@[@1234.5f, @[@12345.6f, @678.9f]]];
    [r commitWriteTransaction];
    XCTAssertTrue([(NSNumber *)mo.anyCol isEqualToNumber:@1234.5f]);
    XCTAssertTrue([mo.anyArray[0] isEqualToNumber:[NSNumber numberWithFloat:12345.6f]]);
    XCTAssertTrue([mo.anyArray[1] isEqualToNumber:[NSNumber numberWithFloat:678.9f]]);
    XCTAssertEqual(mo.anyCol.rlm_valueType, RLMPropertyTypeFloat);
}

- (void)testCreateManagedDouble {
    RLMRealm *r = [self realmWithTestPath];
    [r beginWriteTransaction];
    MixedObject *mo = [MixedObject createInRealm:r withValue:@[@1234.5, @[@12345.6, @678.9]]];
    [r commitWriteTransaction];
    XCTAssertTrue([(NSNumber *)mo.anyCol isEqualToNumber:@1234.5]);
    XCTAssertTrue([mo.anyArray[0] isEqualToNumber:[NSNumber numberWithDouble:12345.6]]);
    XCTAssertTrue([mo.anyArray[1] isEqualToNumber:[NSNumber numberWithDouble:678.9]]);
    XCTAssertEqual(mo.anyCol.rlm_valueType, RLMPropertyTypeDouble);
}

- (void)testCreateManagedString {
    RLMRealm *r = [self realmWithTestPath];
    [r beginWriteTransaction];
    MixedObject *mo = [MixedObject createInRealm:r withValue:@[@"hello", @[@"over", @"there"]]];
    [r commitWriteTransaction];
    XCTAssertTrue([(NSString *)mo.anyCol isEqualToString:@"hello"]);
    XCTAssertTrue([mo.anyArray[0] isEqualToString:@"over"]);
    XCTAssertTrue([mo.anyArray[1] isEqualToString:@"there"]);
    XCTAssertEqual(mo.anyCol.rlm_valueType, RLMPropertyTypeString);
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
    XCTAssertEqual(mo.anyCol.rlm_valueType, RLMPropertyTypeData);
}

- (void)testCreateManagedDate {
    RLMRealm *r = [self realmWithTestPath];
    NSDate *d1 = [NSDate date];
    NSDate *d2 = [NSDate date];

    [r beginWriteTransaction];
    MixedObject *mo = [MixedObject createInRealm:r withValue:@[d1, @[d1, d2]]];
    [r commitWriteTransaction];

    // handle lossy margin of error.
    XCTAssertEqualWithAccuracy(d1.timeIntervalSince1970, ((NSDate *)mo.anyCol).timeIntervalSince1970, 1);
    XCTAssertEqualWithAccuracy(d1.timeIntervalSince1970, ((NSDate *)mo.anyArray[0]).timeIntervalSince1970, 1);
    XCTAssertEqualWithAccuracy(d2.timeIntervalSince1970, ((NSDate *)mo.anyArray[1]).timeIntervalSince1970, 1);
    XCTAssertEqual(mo.anyCol.rlm_valueType, RLMPropertyTypeDate);
}

- (void)testCreateManagedObjectId {
    RLMRealm *r = [self realmWithTestPath];
    RLMObjectId *oid1 = [RLMObjectId objectId];
    RLMObjectId *oid2 = [RLMObjectId objectId];

    [r beginWriteTransaction];
    MixedObject *mo = [MixedObject createInRealm:r withValue:@[oid1, @[oid1, oid2]]];
    [r commitWriteTransaction];

    XCTAssertTrue([(RLMObjectId *)mo.anyCol isEqual:oid1]);
    XCTAssertTrue([(RLMObjectId *)mo.anyArray[0] isEqual:oid1]);
    XCTAssertTrue([(RLMObjectId *)mo.anyArray[1] isEqual:oid2]);
    XCTAssertEqual(mo.anyCol.rlm_valueType, RLMPropertyTypeObjectId);
}

- (void)testCreateManagedDecimal128 {
    RLMRealm *r = [self realmWithTestPath];
    RLMDecimal128 *d1 = [RLMDecimal128 decimalWithNumber:@123.456];
    RLMDecimal128 *d2 = [RLMDecimal128 decimalWithNumber:@890.456];

    [r beginWriteTransaction];
    MixedObject *mo = [MixedObject createInRealm:r withValue:@[d1, @[d1, d2]]];
    [r commitWriteTransaction];

    XCTAssertTrue([(RLMDecimal128 *)mo.anyCol isEqual:d1]);
    XCTAssertTrue([(RLMDecimal128 *)mo.anyArray[0] isEqual:d1]);
    XCTAssertTrue([(RLMDecimal128 *)mo.anyArray[1] isEqual:d2]);
    XCTAssertEqual(mo.anyCol.rlm_valueType, RLMPropertyTypeDecimal128);
}

#pragma mark - Add Managed Values

- (void)testAddManagedObject {
    StringObject *so = [[StringObject alloc] init];
    so.stringCol = @"hello";
    MixedObject *mo1 = [[MixedObject alloc] init];
    mo1.anyCol = so;
    [mo1.anyArray addObject:so];
    
    RLMRealm *r = [self realmWithTestPath];
    [r beginWriteTransaction];
    [r addObject:so];
    [r addObject:mo1];
    [r commitWriteTransaction];
    
    XCTAssertNotNil(mo1.anyCol);
    XCTAssertTrue([((StringObject *)mo1.anyCol).stringCol isEqualToString:so.stringCol]);
    XCTAssertEqual(mo1.anyCol.rlm_valueType, RLMPropertyTypeObject);
}

- (void)testAddManagedInt {
    MixedObject *mo = [[MixedObject alloc] init];
    mo.anyCol = @123456789;
    [mo.anyArray addObjects:@[@123456, @67890]];
    
    RLMRealm *r = [self realmWithTestPath];
    [r beginWriteTransaction];
    [r addObject:mo];
    [r commitWriteTransaction];
    
    XCTAssertTrue([(NSNumber *)mo.anyCol isEqualToNumber:@123456789]);
    XCTAssertTrue([mo.anyArray[0] isEqualToNumber:@123456]);
    XCTAssertTrue([mo.anyArray[1] isEqualToNumber:@67890]);
    XCTAssertEqual(mo.anyCol.rlm_valueType, RLMPropertyTypeInt);
}

- (void)testAddManagedFloat {
    MixedObject *mo = [[MixedObject alloc] init];
    mo.anyCol = @1234.5f;
    [mo.anyArray addObjects:@[@12345.6f, @678.9f]];
    
    RLMRealm *r = [self realmWithTestPath];
    [r beginWriteTransaction];
    [r addObject:mo];
    [r commitWriteTransaction];
    XCTAssertTrue([(NSNumber *)mo.anyCol isEqualToNumber:@1234.5f]);
    XCTAssertTrue([mo.anyArray[0] isEqualToNumber:[NSNumber numberWithFloat:12345.6f]]);
    XCTAssertTrue([mo.anyArray[1] isEqualToNumber:[NSNumber numberWithFloat:678.9f]]);
    XCTAssertEqual(mo.anyCol.rlm_valueType, RLMPropertyTypeFloat);
}

- (void)testAddManagedString {
    MixedObject *mo = [[MixedObject alloc] init];
    mo.anyCol = @"hello";
    [mo.anyArray addObjects:@[@"over", @"there"]];
    
    RLMRealm *r = [self realmWithTestPath];
    [r beginWriteTransaction];
    [r addObject:mo];
    [r commitWriteTransaction];
    XCTAssertTrue([(NSString *)mo.anyCol isEqualToString:@"hello"]);
    XCTAssertTrue([mo.anyArray[0] isEqualToString:@"over"]);
    XCTAssertTrue([mo.anyArray[1] isEqualToString:@"there"]);
    XCTAssertEqual(mo.anyCol.rlm_valueType, RLMPropertyTypeString);
}

- (void)testAddManagedData {
    NSData *d1 = [NSData dataWithBytes:"hey" length:3];
    NSData *d2 = [NSData dataWithBytes:"you" length:3];
    MixedObject *mo = [[MixedObject alloc] init];
    mo.anyCol = d1;
    [mo.anyArray addObjects:@[d1, d2]];
    
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
    XCTAssertEqual(mo.anyCol.rlm_valueType, RLMPropertyTypeData);
}

- (void)testAddManagedDate {
    NSDate *d1 = [NSDate date];
    NSDate *d2 = [NSDate date];
    MixedObject *mo = [[MixedObject alloc] init];
    mo.anyCol = d1;
    [mo.anyArray addObjects:@[d1, d2]];
    
    RLMRealm *r = [self realmWithTestPath];
    [r beginWriteTransaction];
    [r addObject:mo];
    [r commitWriteTransaction];

    // handle lossy margin of error.
    XCTAssertEqualWithAccuracy(d1.timeIntervalSince1970, ((NSDate *)mo.anyCol).timeIntervalSince1970, 1.0);
    XCTAssertEqualWithAccuracy(d1.timeIntervalSince1970, ((NSDate *)mo.anyArray[0]).timeIntervalSince1970, 1.0);
    XCTAssertEqualWithAccuracy(d2.timeIntervalSince1970, ((NSDate *)mo.anyArray[1]).timeIntervalSince1970, 1.0);
    XCTAssertEqual(mo.anyCol.rlm_valueType, RLMPropertyTypeDate);
}

- (void)testAddManagedObjectId {
    RLMObjectId *oid1 = [RLMObjectId objectId];
    RLMObjectId *oid2 = [RLMObjectId objectId];
    MixedObject *mo = [[MixedObject alloc] init];
    mo.anyCol = oid1;
    [mo.anyArray addObjects:@[oid1, oid2]];
    
    RLMRealm *r = [self realmWithTestPath];
    [r beginWriteTransaction];
    [r addObject:mo];
    [r commitWriteTransaction];

    XCTAssertTrue([(RLMObjectId *)mo.anyCol isEqual:oid1]);
    XCTAssertTrue([(RLMObjectId *)mo.anyArray[0] isEqual:oid1]);
    XCTAssertTrue([(RLMObjectId *)mo.anyArray[1] isEqual:oid2]);
    XCTAssertEqual(mo.anyCol.rlm_valueType, RLMPropertyTypeObjectId);
}

- (void)testAddManagedDecimal128 {
    RLMDecimal128 *d1 = [RLMDecimal128 decimalWithNumber:@123.456];
    RLMDecimal128 *d2 = [RLMDecimal128 decimalWithNumber:@890.456];
    MixedObject *mo = [[MixedObject alloc] init];
    mo.anyCol = d1;
    [mo.anyArray addObjects:@[d1, d2]];
    
    RLMRealm *r = [self realmWithTestPath];
    [r beginWriteTransaction];
    [r addObject:mo];
    [r commitWriteTransaction];

    XCTAssertTrue([(RLMDecimal128 *)mo.anyCol isEqual:d1]);
    XCTAssertTrue([(RLMDecimal128 *)mo.anyArray[0] isEqual:d1]);
    XCTAssertTrue([(RLMDecimal128 *)mo.anyArray[1] isEqual:d2]);
    XCTAssertEqual(mo.anyCol.rlm_valueType, RLMPropertyTypeDecimal128);
}

#pragma mark - Dynamic Object Accessor

- (void)testDynamicObjectAccessor {
    @autoreleasepool {
        RLMRealmConfiguration *configuration = [RLMRealmConfiguration defaultConfiguration];
        configuration.objectClasses = @[MixedObject.class, StringObject.class];
        configuration.fileURL = RLMTestRealmURL();
        RLMRealm *r = [RLMRealm realmWithConfiguration:configuration error:nil];
        [r transactionWithBlock:^{
            StringObject *so = [StringObject new];
            so.stringCol = @"some string...";
            [MixedObject createInRealm:r withValue:@{@"anyCol": so}];
        }];
        XCTAssertEqual([StringObject allObjectsInRealm:r].count, 1U);
    }

    RLMRealmConfiguration *configuration = [RLMRealmConfiguration defaultConfiguration];
    configuration.objectClasses = @[MixedObject.class];
    configuration.fileURL = RLMTestRealmURL();
    RLMRealm *r = [RLMRealm realmWithConfiguration:configuration error:nil];
    for (RLMObjectSchema *os in r.schema.objectSchema) {
        XCTAssertFalse([os.className isEqualToString:@"StringObject"]);
    }
    XCTAssertEqual([MixedObject allObjectsInRealm:r].count, 1U);
    MixedObject *o = [MixedObject allObjectsInRealm:r][0];
    XCTAssertTrue([o[@"anyCol"][@"stringCol"] isEqualToString:@"some string..."]);
}

// Tests that the `RLMSchemaInfo::clone` and `RLMSchemaInfo::operator[]` correctly
// skip class names that are not present in the source schema. If such an event were
// to occur an OOB exception would be thrown.
- (void)testDynamicSchema {
    @autoreleasepool {
        RLMRealmConfiguration *config = [RLMRealmConfiguration new];
        config.objectClasses = @[MixedObject.class, IntObject.class];
        RLMRealm *realm = [RLMRealm realmWithConfiguration:config error:nil];
        [realm beginWriteTransaction];
        [MixedObject createInRealm:realm withValue:@[[IntObject new]]];
        [realm commitWriteTransaction];
    }
    RLMRealmConfiguration *config = [RLMRealmConfiguration new];
    config.objectClasses = @[MixedObject.class];
    XCTestExpectation *ex = [self expectationWithDescription:@""];
    __block RLMRealm *realm2;
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        @autoreleasepool {
            RLMRealm *realm1 = [RLMRealm realmWithConfiguration:config error:nil];
            (void)[[MixedObject allObjectsInRealm:realm1].firstObject anyCol];
            dispatch_sync(dispatch_get_main_queue(), ^{
                realm2 = [RLMRealm realmWithConfiguration:config error:nil];
            });
        }
        [ex fulfill];
    });
    [self waitForExpectations:@[ex] timeout:1.0];
    (void)[[MixedObject allObjectsInRealm:realm2].firstObject anyCol];
}

@end
