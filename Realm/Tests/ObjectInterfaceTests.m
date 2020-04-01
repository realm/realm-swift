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

- (void)testRenamedProperties {
    RenamedProperties1 *obj1 = [[RenamedProperties1 alloc] initWithValue:@{@"propA": @5, @"propB": @"a"}];
    XCTAssertEqual(obj1.propA, 5);
    XCTAssertEqualObjects(obj1.propB, @"a");
    XCTAssertEqualObjects(obj1[@"propA"], @5);
    XCTAssertEqualObjects(obj1[@"propB"], @"a");
    XCTAssertEqualObjects([obj1 valueForKey:@"propA"], @5);
    XCTAssertEqualObjects([obj1 valueForKey:@"propB"], @"a");

    RLMRealm *realm = [RLMRealm defaultRealm];
    [realm beginWriteTransaction];
    [realm addObject:obj1];
    XCTAssertEqual(obj1.propA, 5);
    XCTAssertEqualObjects(obj1.propB, @"a");
    XCTAssertEqualObjects(obj1[@"propA"], @5);
    XCTAssertEqualObjects(obj1[@"propB"], @"a");
    XCTAssertEqualObjects([obj1 valueForKey:@"propA"], @5);
    XCTAssertEqualObjects([obj1 valueForKey:@"propB"], @"a");

    RenamedProperties2 *obj2 = [RenamedProperties2 createInRealm:realm withValue:@{@"propC": @6, @"propD": @"b"}];
    XCTAssertEqual(obj2.propC, 6);
    XCTAssertEqualObjects(obj2.propD, @"b");
    XCTAssertEqualObjects(obj2[@"propC"], @6);
    XCTAssertEqualObjects(obj2[@"propD"], @"b");
    XCTAssertEqualObjects([obj2 valueForKey:@"propC"], @6);
    XCTAssertEqualObjects([obj2 valueForKey:@"propD"], @"b");

    RLMResults<RenamedProperties1 *> *results1 = [RenamedProperties1 allObjectsInRealm:realm];
    RLMResults<RenamedProperties2 *> *results2 = [RenamedProperties2 allObjectsInRealm:realm];
    XCTAssertTrue([results1[0] isEqualToObject:results2[0]]);
    XCTAssertTrue([results1[1] isEqualToObject:results2[1]]);

    LinkToRenamedProperties1 *link1 = [LinkToRenamedProperties1 createInRealm:realm withValue:@[obj1, obj2, @[obj1, results1[1]]]];
    LinkToRenamedProperties2 *link2 = [LinkToRenamedProperties2 createInRealm:realm withValue:@[obj2, obj1, @[obj2, results2[0]]]];

    XCTAssertTrue([link1.linkA isKindOfClass:[RenamedProperties1 class]]);
    XCTAssertTrue([link1.linkB isKindOfClass:[RenamedProperties2 class]]);
    XCTAssertTrue([link1.array[0] isKindOfClass:[RenamedProperties1 class]]);
    XCTAssertTrue([link1.array[1] isKindOfClass:[RenamedProperties1 class]]);

    XCTAssertTrue([link2.linkC isKindOfClass:[RenamedProperties2 class]]);
    XCTAssertTrue([link2.linkD isKindOfClass:[RenamedProperties1 class]]);
    XCTAssertTrue([link2.array[0] isKindOfClass:[RenamedProperties2 class]]);
    XCTAssertTrue([link2.array[1] isKindOfClass:[RenamedProperties2 class]]);

    XCTAssertTrue([link1.linkA isEqualToObject:results1[0]]);
    XCTAssertTrue([link1.linkB isEqualToObject:results1[1]]);
    XCTAssertTrue([link1.linkA isEqualToObject:results2[0]]);
    XCTAssertTrue([link1.linkB isEqualToObject:results2[1]]);

    XCTAssertTrue([link2.linkC isEqualToObject:results1[1]]);
    XCTAssertTrue([link2.linkD isEqualToObject:results1[0]]);
    XCTAssertTrue([link2.linkC isEqualToObject:results2[1]]);
    XCTAssertTrue([link2.linkD isEqualToObject:results2[0]]);

    XCTAssertEqualObjects([link1.array valueForKey:@"propB"], (@[@"a", @"b"]));
    XCTAssertEqualObjects([link2.array valueForKey:@"propD"], (@[@"b", @"a"]));

    XCTAssertTrue([obj1.linking1[0] isEqualToObject:link1]);
    XCTAssertTrue([obj1.linking2[0] isEqualToObject:link2]);
    XCTAssertTrue([obj2.linking1[0] isEqualToObject:link2]);
    XCTAssertTrue([obj2.linking2[0] isEqualToObject:link1]);

    [realm cancelWriteTransaction];
}

- (void)testAllMethodsCheckThread {
    RLMRealm *realm = [RLMRealm defaultRealm];
    __block AllTypesObject *obj;
    __block StringObject *stringObj;
    NSDictionary *values = [AllTypesObject values:1 stringObject:nil];
    [realm transactionWithBlock:^{
        obj = [AllTypesObject createInRealm:realm withValue:values];
        stringObj = [StringObject createInRealm:realm withValue:@[@""]];
    }];
    [realm beginWriteTransaction];

    NSArray<NSString *> *propertyNames = [obj.objectSchema.properties valueForKey:@"name"];
    [self dispatchAsyncAndWait:^{
        // Getters
        for (NSString *prop in propertyNames) {
            RLMAssertThrowsWithReasonMatching(obj[prop], @"thread");
            RLMAssertThrowsWithReasonMatching([obj valueForKey:prop], @"thread");
        }
        RLMAssertThrowsWithReasonMatching(obj.boolCol, @"thread");
        RLMAssertThrowsWithReasonMatching(obj.intCol, @"thread");
        RLMAssertThrowsWithReasonMatching(obj.floatCol, @"thread");
        RLMAssertThrowsWithReasonMatching(obj.doubleCol, @"thread");
        RLMAssertThrowsWithReasonMatching(obj.stringCol, @"thread");
        RLMAssertThrowsWithReasonMatching(obj.binaryCol, @"thread");
        RLMAssertThrowsWithReasonMatching(obj.dateCol, @"thread");
        RLMAssertThrowsWithReasonMatching(obj.cBoolCol, @"thread");
        RLMAssertThrowsWithReasonMatching(obj.longCol, @"thread");
        RLMAssertThrowsWithReasonMatching(obj.objectIdCol, @"thread");
        RLMAssertThrowsWithReasonMatching(obj.decimalCol, @"thread");
        RLMAssertThrowsWithReasonMatching(obj.objectCol, @"thread");
        RLMAssertThrowsWithReasonMatching(obj.linkingObjectsCol, @"thread");

        // Setters
        for (NSString *prop in propertyNames) {
            RLMAssertThrowsWithReasonMatching(obj[prop] = values[prop], @"thread");
            RLMAssertThrowsWithReasonMatching([obj setValue:values[prop] forKey:prop], @"thread");
        }
        RLMAssertThrowsWithReasonMatching(obj.boolCol = 0, @"thread");
        RLMAssertThrowsWithReasonMatching(obj.intCol = 0, @"thread");
        RLMAssertThrowsWithReasonMatching(obj.floatCol = 0, @"thread");
        RLMAssertThrowsWithReasonMatching(obj.doubleCol = 0, @"thread");
        RLMAssertThrowsWithReasonMatching(obj.stringCol = nil, @"thread");
        RLMAssertThrowsWithReasonMatching(obj.binaryCol = nil, @"thread");
        RLMAssertThrowsWithReasonMatching(obj.dateCol = nil, @"thread");
        RLMAssertThrowsWithReasonMatching(obj.cBoolCol = 0, @"thread");
        RLMAssertThrowsWithReasonMatching(obj.longCol = 0, @"thread");
        RLMAssertThrowsWithReasonMatching(obj.objectIdCol = nil, @"thread");
        RLMAssertThrowsWithReasonMatching(obj.decimalCol = nil, @"thread");
        RLMAssertThrowsWithReasonMatching(obj.objectCol = nil, @"thread");
        RLMAssertThrowsWithReasonMatching(obj.objectCol = [StringObject new], @"thread");
        RLMAssertThrowsWithReasonMatching(obj.objectCol = stringObj, @"thread");
    }];
    [realm cancelWriteTransaction];
}

- (void)testAllMethodsCheckForInvalidation {
    RLMRealm *realm = [RLMRealm defaultRealm];
    __block StringObject *stringObj;
    NSDictionary *values = [AllTypesObject values:1 stringObject:nil];
    [realm transactionWithBlock:^{
        [AllTypesObject createInRealm:realm withValue:values];
        stringObj = [StringObject createInRealm:realm withValue:@[@""]];
    }];

    for (int i = 0; i < 2; ++i) {
        AllTypesObject *obj = [[AllTypesObject allObjectsInRealm:realm] firstObject];
        [realm beginWriteTransaction];
        // Deleting the object directly and indirectly leave the managed
        // accessor in different states, so test both
        if (i == 0) {
            [realm deleteObject:obj];
        }
        else {
            [realm deleteObjects:[AllTypesObject allObjectsInRealm:realm]];
        }

        NSArray<NSString *> *propertyNames = [obj.objectSchema.properties valueForKey:@"name"];
        // Getters
        for (NSString *prop in propertyNames) {
            RLMAssertThrowsWithReasonMatching(obj[prop], @"invalidated");
            RLMAssertThrowsWithReasonMatching([obj valueForKey:prop], @"invalidated");
        }
        RLMAssertThrowsWithReasonMatching(obj.boolCol, @"invalidated");
        RLMAssertThrowsWithReasonMatching(obj.intCol, @"invalidated");
        RLMAssertThrowsWithReasonMatching(obj.floatCol, @"invalidated");
        RLMAssertThrowsWithReasonMatching(obj.doubleCol, @"invalidated");
        RLMAssertThrowsWithReasonMatching(obj.stringCol, @"invalidated");
        RLMAssertThrowsWithReasonMatching(obj.binaryCol, @"invalidated");
        RLMAssertThrowsWithReasonMatching(obj.dateCol, @"invalidated");
        RLMAssertThrowsWithReasonMatching(obj.cBoolCol, @"invalidated");
        RLMAssertThrowsWithReasonMatching(obj.longCol, @"invalidated");
        RLMAssertThrowsWithReasonMatching(obj.objectIdCol, @"invalidated");
        RLMAssertThrowsWithReasonMatching(obj.decimalCol, @"invalidated");
        RLMAssertThrowsWithReasonMatching(obj.objectCol, @"invalidated");
        RLMAssertThrowsWithReasonMatching(obj.linkingObjectsCol, @"invalidated");

        // Setters
        for (NSString *prop in propertyNames) {
            RLMAssertThrowsWithReasonMatching(obj[prop] = values[prop], @"invalidated");
            RLMAssertThrowsWithReasonMatching([obj setValue:values[prop] forKey:prop], @"invalidated");
        }
        RLMAssertThrowsWithReasonMatching(obj.boolCol = 0, @"invalidated");
        RLMAssertThrowsWithReasonMatching(obj.intCol = 0, @"invalidated");
        RLMAssertThrowsWithReasonMatching(obj.floatCol = 0, @"invalidated");
        RLMAssertThrowsWithReasonMatching(obj.doubleCol = 0, @"invalidated");
        RLMAssertThrowsWithReasonMatching(obj.stringCol = nil, @"invalidated");
        RLMAssertThrowsWithReasonMatching(obj.binaryCol = nil, @"invalidated");
        RLMAssertThrowsWithReasonMatching(obj.dateCol = nil, @"invalidated");
        RLMAssertThrowsWithReasonMatching(obj.cBoolCol = 0, @"invalidated");
        RLMAssertThrowsWithReasonMatching(obj.longCol = 0, @"invalidated");
        RLMAssertThrowsWithReasonMatching(obj.objectIdCol = nil, @"invalidated");
        RLMAssertThrowsWithReasonMatching(obj.decimalCol = nil, @"invalidated");
        RLMAssertThrowsWithReasonMatching(obj.objectCol = nil, @"invalidated");
        RLMAssertThrowsWithReasonMatching(obj.objectCol = [StringObject new], @"invalidated");
        RLMAssertThrowsWithReasonMatching(obj.objectCol = stringObj, @"invalidated");
        [realm cancelWriteTransaction];
    }
}

@end
