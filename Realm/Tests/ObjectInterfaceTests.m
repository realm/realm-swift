////////////////////////////////////////////////////////////////////////////
//
// Copyright 2014 Realm Inc.
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

#pragma mark - Test Objects

@interface PrimaryKeyWithLinkObject : RLMObject
@property NSString *primaryKey;
@property StringObject *string;
@end

@implementation PrimaryKeyWithLinkObject
+ (NSString *)primaryKey {
    return @"primaryKey";
}
@end

#pragma mark - Tests

@interface ObjectInterfaceTests : RLMTestCase
@end

@implementation ObjectInterfaceTests

- (void)testCustomAccessorsObject {
    RLMRealm *realm = [RLMRealm defaultRealm];

    [realm beginWriteTransaction];
    CustomAccessorsObject *ca = [CustomAccessorsObject createInRealm:realm withValue:@[@"name", @2]];
    XCTAssertEqualObjects(ca.name, @"name");
    XCTAssertEqualObjects([ca getThatName], @"name");
    XCTAssertEqual(ca.age, 2);
    XCTAssertEqual([ca age], 2);

    [ca setTheInt:99];
    XCTAssertEqual(ca.age, 99);
    XCTAssertEqual([ca age], 99);
    [realm cancelWriteTransaction];
}

- (void)testClassExtension {
    RLMRealm *realm = [RLMRealm defaultRealm];

    [realm beginWriteTransaction];
    BaseClassStringObject *bObject = [[BaseClassStringObject alloc ] init];
    bObject.intCol = 1;
    bObject.stringCol = @"stringVal";
    [realm addObject:bObject];
    [realm commitWriteTransaction];

    BaseClassStringObject *objectFromRealm = [BaseClassStringObject allObjects][0];
    XCTAssertEqual(1, objectFromRealm.intCol, @"Should be 1");
    XCTAssertEqualObjects(@"stringVal", objectFromRealm.stringCol, @"Should be stringVal");
}

- (void)testNSNumberProperties {
    NumberObject *obj = [NumberObject new];
    obj.intObj = @20;
    obj.floatObj = @0.7f;
    obj.doubleObj = @33.3;
    obj.boolObj = @YES;
    XCTAssertEqualObjects(@20, obj.intObj);
    XCTAssertEqualObjects(@0.7f, obj.floatObj);
    XCTAssertEqualObjects(@33.3, obj.doubleObj);
    XCTAssertEqualObjects(@YES, obj.boolObj);

    RLMRealm *realm = [RLMRealm defaultRealm];
    [realm beginWriteTransaction];
    [realm addObject:obj];
    [realm commitWriteTransaction];

    XCTAssertEqualObjects(@20, obj.intObj);
    XCTAssertEqualObjects(@0.7f, obj.floatObj);
    XCTAssertEqualObjects(@33.3, obj.doubleObj);
    XCTAssertEqualObjects(@YES, obj.boolObj);
}

- (void)testOptionalStringProperties {
    RLMRealm *realm = [RLMRealm defaultRealm];
    StringObject *so = [[StringObject alloc] init];

    XCTAssertNil(so.stringCol);
    XCTAssertNil([so valueForKey:@"stringCol"]);
    XCTAssertNil(so[@"stringCol"]);

    so.stringCol = @"a";
    XCTAssertEqualObjects(so.stringCol, @"a");
    XCTAssertEqualObjects([so valueForKey:@"stringCol"], @"a");
    XCTAssertEqualObjects(so[@"stringCol"], @"a");

    [so setValue:nil forKey:@"stringCol"];
    XCTAssertNil(so.stringCol);
    XCTAssertNil([so valueForKey:@"stringCol"]);
    XCTAssertNil(so[@"stringCol"]);

    [realm transactionWithBlock:^{
        [realm addObject:so];
        XCTAssertNil(so.stringCol);
        XCTAssertNil([so valueForKey:@"stringCol"]);
        XCTAssertNil(so[@"stringCol"]);
    }];

    so = [StringObject allObjectsInRealm:realm].firstObject;

    XCTAssertNil(so.stringCol);
    XCTAssertNil([so valueForKey:@"stringCol"]);
    XCTAssertNil(so[@"stringCol"]);

    [realm transactionWithBlock:^{
        so.stringCol = @"b";
    }];
    XCTAssertEqualObjects(so.stringCol, @"b");
    XCTAssertEqualObjects([so valueForKey:@"stringCol"], @"b");
    XCTAssertEqualObjects(so[@"stringCol"], @"b");

    [realm transactionWithBlock:^{
        so.stringCol = @"";
    }];
    XCTAssertEqualObjects(so.stringCol, @"");
    XCTAssertEqualObjects([so valueForKey:@"stringCol"], @"");
    XCTAssertEqualObjects(so[@"stringCol"], @"");
}

- (void)testOptionalBinaryProperties {
    RLMRealm *realm = [RLMRealm defaultRealm];
    BinaryObject *bo = [[BinaryObject alloc] init];

    XCTAssertNil(bo.binaryCol);
    XCTAssertNil([bo valueForKey:@"binaryCol"]);
    XCTAssertNil(bo[@"binaryCol"]);

    NSData *aData = [@"a" dataUsingEncoding:NSUTF8StringEncoding];
    bo.binaryCol = aData;
    XCTAssertEqualObjects(bo.binaryCol, aData);
    XCTAssertEqualObjects([bo valueForKey:@"binaryCol"], aData);
    XCTAssertEqualObjects(bo[@"binaryCol"], aData);

    [bo setValue:nil forKey:@"binaryCol"];
    XCTAssertNil(bo.binaryCol);
    XCTAssertNil([bo valueForKey:@"binaryCol"]);
    XCTAssertNil(bo[@"binaryCol"]);

    [realm transactionWithBlock:^{
        [realm addObject:bo];
        XCTAssertNil(bo.binaryCol);
        XCTAssertNil([bo valueForKey:@"binaryCol"]);
        XCTAssertNil(bo[@"binaryCol"]);
    }];

    bo = [BinaryObject allObjectsInRealm:realm].firstObject;

    XCTAssertNil(bo.binaryCol);
    XCTAssertNil([bo valueForKey:@"binaryCol"]);
    XCTAssertNil(bo[@"binaryCol"]);

    NSData *bData = [@"b" dataUsingEncoding:NSUTF8StringEncoding];
    [realm transactionWithBlock:^{
        bo.binaryCol = bData;
    }];
    XCTAssertEqualObjects(bo.binaryCol, bData);
    XCTAssertEqualObjects([bo valueForKey:@"binaryCol"], bData);
    XCTAssertEqualObjects(bo[@"binaryCol"], bData);

    NSData *emptyData = [NSData data];
    [realm transactionWithBlock:^{
        bo.binaryCol = emptyData;
    }];
    XCTAssertEqualObjects(bo.binaryCol, emptyData);
    XCTAssertEqualObjects([bo valueForKey:@"binaryCol"], emptyData);
    XCTAssertEqualObjects(bo[@"binaryCol"], emptyData);
}

- (void)testOptionalNumberProperties {
    void (^assertNullProperties)(NumberObject *) = ^(NumberObject *no){
        XCTAssertNil(no.intObj);
        XCTAssertNil(no.doubleObj);
        XCTAssertNil(no.floatObj);
        XCTAssertNil(no.boolObj);

        XCTAssertNil([no valueForKey:@"intObj"]);
        XCTAssertNil([no valueForKey:@"doubleObj"]);
        XCTAssertNil([no valueForKey:@"floatObj"]);
        XCTAssertNil([no valueForKey:@"boolObj"]);

        XCTAssertNil(no[@"intObj"]);
        XCTAssertNil(no[@"doubleObj"]);
        XCTAssertNil(no[@"floatObj"]);
        XCTAssertNil(no[@"boolObj"]);
    };

    void (^assertNonNullProperties)(NumberObject *) = ^(NumberObject *no){
        XCTAssertEqualObjects(no.intObj, @1);
        XCTAssertEqualObjects(no.doubleObj, @1.1);
        XCTAssertEqualObjects(no.floatObj, @2.2f);
        XCTAssertEqualObjects(no.boolObj, @YES);

        XCTAssertEqualObjects([no valueForKey:@"intObj"], @1);
        XCTAssertEqualObjects([no valueForKey:@"doubleObj"], @1.1);
        XCTAssertEqualObjects([no valueForKey:@"floatObj"], @2.2f);
        XCTAssertEqualObjects([no valueForKey:@"boolObj"], @YES);

        XCTAssertEqualObjects(no[@"intObj"], @1);
        XCTAssertEqualObjects(no[@"doubleObj"], @1.1);
        XCTAssertEqualObjects(no[@"floatObj"], @2.2f);
        XCTAssertEqualObjects(no[@"boolObj"], @YES);
    };

    RLMRealm *realm = [RLMRealm defaultRealm];
    NumberObject *no = [[NumberObject alloc] init];

    assertNullProperties(no);

    no.intObj = @1;
    no.doubleObj = @1.1;
    no.floatObj = @2.2f;
    no.boolObj = @YES;

    assertNonNullProperties(no);

    no.intObj = nil;
    no.doubleObj = nil;
    no.floatObj = nil;
    no.boolObj = nil;

    assertNullProperties(no);

    no[@"intObj"] = @1;
    no[@"doubleObj"] = @1.1;
    no[@"floatObj"] = @2.2f;
    no[@"boolObj"] = @YES;

    assertNonNullProperties(no);

    no.intObj = nil;
    no.doubleObj = nil;
    no.floatObj = nil;
    no.boolObj = nil;

    [realm transactionWithBlock:^{
        [realm addObject:no];
        assertNullProperties(no);
    }];

    no = [NumberObject allObjectsInRealm:realm].firstObject;
    assertNullProperties(no);

    [realm transactionWithBlock:^{
        no.intObj = @1;
        no.doubleObj = @1.1;
        no.floatObj = @2.2f;
        no.boolObj = @YES;
    }];
    assertNonNullProperties(no);
}

- (void)testRequiredNumberProperties {
    RLMRealm *realm = [RLMRealm defaultRealm];
    [realm beginWriteTransaction];
    RequiredNumberObject *obj = [RequiredNumberObject createInRealm:realm withValue:@[@0, @0, @0, @0]];

    RLMAssertThrowsWithReason(obj.intObj = nil, @"insert null into non-nullable");
    RLMAssertThrowsWithReason(obj.floatObj = nil, @"insert null into non-nullable");
    RLMAssertThrowsWithReason(obj.doubleObj = nil, @"insert null into non-nullable");
    RLMAssertThrowsWithReason(obj.boolObj = nil, @"insert null into non-nullable");

    obj.intObj = @1;
    XCTAssertEqualObjects(obj.intObj, @1);
    obj.floatObj = @2.2f;
    XCTAssertEqualObjects(obj.floatObj, @2.2f);
    obj.doubleObj = @3.3;
    XCTAssertEqualObjects(obj.doubleObj, @3.3);
    obj.boolObj = @YES;
    XCTAssertEqualObjects(obj.boolObj, @YES);

    [realm cancelWriteTransaction];
}

- (void)testSettingNonOptionalPropertiesToNil {
    RequiredPropertiesObject *ro = [[RequiredPropertiesObject alloc] init];

    ro.stringCol = nil;
    ro.binaryCol = nil;

    XCTAssertNil(ro.stringCol);
    XCTAssertNil(ro.binaryCol);

    ro.stringCol = @"a";
    ro.binaryCol = [@"a" dataUsingEncoding:NSUTF8StringEncoding];

    RLMRealm *realm = [RLMRealm defaultRealm];
    [realm beginWriteTransaction];
    [realm addObject:ro];
    RLMAssertThrowsWithReasonMatching(ro.stringCol = nil, @"null into non-nullable column");
    RLMAssertThrowsWithReasonMatching(ro.binaryCol = nil, @"null into non-nullable column");
    [realm cancelWriteTransaction];
}


- (void)testIntSizes {
    RLMRealm *realm = [self realmWithTestPath];

    int16_t v16 = 1 << 12;
    int32_t v32 = 1 << 30;
    int64_t v64 = 1LL << 40;

    AllIntSizesObject *obj = [AllIntSizesObject new];

    // Test unmanaged
    obj[@"int16"] = @(v16);
    XCTAssertEqual([obj[@"int16"] shortValue], v16);
    obj[@"int16"] = @(v32);
    XCTAssertNotEqual([obj[@"int16"] intValue], v32, @"should truncate");

    obj.int16 = 0;
    obj.int16 = v16;
    XCTAssertEqual(obj.int16, v16);

    obj[@"int32"] = @(v32);
    XCTAssertEqual([obj[@"int32"] intValue], v32);
    obj[@"int32"] = @(v64);
    XCTAssertNotEqual([obj[@"int32"] longLongValue], v64, @"should truncate");

    obj.int32 = 0;
    obj.int32 = v32;
    XCTAssertEqual(obj.int32, v32);

    obj[@"int64"] = @(v64);
    XCTAssertEqual([obj[@"int64"] longLongValue], v64);
    obj.int64 = 0;
    obj.int64 = v64;
    XCTAssertEqual(obj.int64, v64);

    // Test in realm
    [realm beginWriteTransaction];
    [realm addObject:obj];

    XCTAssertEqual(obj.int16, v16);
    XCTAssertEqual(obj.int32, v32);
    XCTAssertEqual(obj.int64, v64);

    obj.int16 = 0;
    obj.int32 = 0;
    obj.int64 = 0;

    obj[@"int16"] = @(v16);
    XCTAssertEqual([obj[@"int16"] shortValue], v16);

    obj.int16 = 0;
    obj.int16 = v16;
    XCTAssertEqual(obj.int16, v16);

    obj[@"int32"] = @(v32);
    XCTAssertEqual([obj[@"int32"] intValue], v32);

    obj.int32 = 0;
    obj.int32 = v32;
    XCTAssertEqual(obj.int32, v32);

    obj[@"int64"] = @(v64);
    XCTAssertEqual([obj[@"int64"] longLongValue], v64);
    obj.int64 = 0;
    obj.int64 = v64;
    XCTAssertEqual(obj.int64, v64);

    [realm commitWriteTransaction];
}

@end
