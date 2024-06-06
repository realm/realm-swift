////////////////////////////////////////////////////////////////////////////
//
// Copyright 2022 Realm Inc.
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

#import <Realm/RLMSectionedResults.h>

@interface SectionedResultsTests : RLMTestCase
@end

@implementation SectionedResultsTests

- (void)createObjects {
    RLMRealm *realm = self.realmWithTestPath;
    [realm transactionWithBlock:^{
        StringObject *strObj1 = [[StringObject alloc] initWithValue:@[@"foo"]];
        StringObject *strObj2 = [[StringObject alloc] initWithValue:@[@"bar"]];
        StringObject *strObj3 = [[StringObject alloc] initWithValue:@[@"apple"]];
        StringObject *strObj4 = [[StringObject alloc] initWithValue:@[@"apples"]];
        StringObject *strObj5 = [[StringObject alloc] initWithValue:@[@"zebra"]];

        [AllTypesObject createInRealm:realm withValue:[AllTypesObject values:1 stringObject:strObj5]];
        [AllTypesObject createInRealm:realm withValue:[AllTypesObject values:1 stringObject:strObj5]];
        [AllTypesObject createInRealm:realm withValue:[AllTypesObject values:1 stringObject:strObj5]];
        [AllTypesObject createInRealm:realm withValue:[AllTypesObject values:2 stringObject:strObj4]];
        [AllTypesObject createInRealm:realm withValue:[AllTypesObject values:2 stringObject:strObj4]];
        [AllTypesObject createInRealm:realm withValue:[AllTypesObject values:2 stringObject:strObj3]];
        [AllTypesObject createInRealm:realm withValue:[AllTypesObject values:3 stringObject:strObj2]];
        [AllTypesObject createInRealm:realm withValue:[AllTypesObject values:3 stringObject:strObj1]];
        [AllTypesObject createInRealm:realm withValue:[AllTypesObject values:3 stringObject:strObj1]];
    }];
}

- (void)createPrimitiveObject {
    RLMRealm *realm = self.realmWithTestPath;
    [realm transactionWithBlock:^{
        AllPrimitiveArrays *arrObj = [AllPrimitiveArrays new];
        [arrObj.stringObj addObject:@"foo"];
        [arrObj.stringObj addObject:@"fab"];
        [arrObj.stringObj addObject:@"bar"];
        [arrObj.stringObj addObject:@"baz"];
        [realm addObject:arrObj];
    }];
}

- (void)testCreationFromResults {
    [self createObjects];
    RLMRealm *realm = self.realmWithTestPath;

    RLMResults<AllTypesObject *> *results = [AllTypesObject allObjectsInRealm:realm];
    RLMSectionedResults<NSString *, AllTypesObject *> *sr = [results sectionedResultsSortedUsingKeyPath:@"objectCol.stringCol"
                                                                                              ascending:YES
                                                                                               keyBlock:^id<RLMValue>(AllTypesObject *value) {
        return [value.objectCol.stringCol substringToIndex:1];
    }];

    XCTAssertNotNil(sr);
    XCTAssertEqual(sr.count, 4);
    XCTAssertEqual(sr[0].count, 3);
    XCTAssertEqual(sr[1].count, 1);
    XCTAssertEqual(sr[2].count, 2);
    XCTAssertEqual(sr[3].count, 3);
}

- (void)testCreationFromPrimitiveResults {
    [self createPrimitiveObject];
    RLMRealm *realm = self.realmWithTestPath;

    AllPrimitiveArrays *obj = [AllPrimitiveArrays allObjectsInRealm:realm][0];
    RLMSectionedResults *sr = [obj.stringObj sectionedResultsSortedUsingKeyPath:@"self"
                                                                      ascending:YES
                                                                       keyBlock:^id<RLMValue> (NSString* value) {
        return [value substringToIndex:1];
    }];
    XCTAssertEqual(sr.count, 2);

    [realm transactionWithBlock:^{
        [obj.stringObj addObject:@"hello"];

    }];
    XCTAssertEqual(sr.count, 3);

    [realm transactionWithBlock:^{
        [obj.stringObj addObject:@"zebra"];
    }];
    XCTAssertEqual(sr.count, 4);
}

- (NSDictionary *)keyPathsAndValues {
    return @{
        @"intCol": @{
            @1: @[@1, @1, @1, @3, @3, @3],
            @0: @[@2, @2, @2]
        },
        @"longCol": @{
            @0: @[@((long long)1 * INT_MAX + 1), @((long long)1 * INT_MAX + 1), @((long long)1 * INT_MAX + 1),
                  @((long long)3 * INT_MAX + 1), @((long long)3 * INT_MAX + 1), @((long long)3 * INT_MAX + 1)],
            @-1: @[@((long long)2 * INT_MAX + 1), @((long long)2 * INT_MAX + 1), @((long long)2 * INT_MAX + 1)]
        },
        @"boolCol": @{
            @NO: @[@NO, @NO, @NO],
            @YES: @[@YES, @YES, @YES, @YES, @YES, @YES]
        },
        @"cBoolCol": @{
            @NO: @[@NO, @NO, @NO],
            @YES: @[@YES, @YES, @YES, @YES, @YES, @YES]
        },
        @"floatCol": @{
            @(1.1f): @[@(1.1f * 1), @(1.1f * 1), @(1.1f * 1)],
            @(2.2f): @[@(1.1f * 2), @(1.1f * 2), @(1.1f * 2), @(1.1f * 3), @(1.1f * 3), @(1.1f * 3)]
        },
        @"doubleCol": @{
            @(1.11): @[@(1.11 * 1), @(1.11 * 1), @(1.11 * 1)],
            @(2.2): @[@(1.11 * 2), @(1.11 * 2), @(1.11 * 2), @(1.11 * 3), @(1.11 * 3), @(1.11 * 3)]
        },
        @"stringCol": @{
            @"a": @[@"a", @"a", @"a"],
            @"b": @[@"b", @"b", @"b"],
            @"c": @[@"c", @"c", @"c"]
        },
        @"objectCol.stringCol": @{
            @"a": @[@"apple", @"apples", @"apples"],
            @"b": @[@"bar"],
            @"f": @[@"foo", @"foo"],
            @"z": @[@"zebra", @"zebra", @"zebra"]
        },
        @"dateCol": @{
            @5: @[[NSDate dateWithTimeIntervalSince1970:1], [NSDate dateWithTimeIntervalSince1970:1], [NSDate dateWithTimeIntervalSince1970:1],
                  [NSDate dateWithTimeIntervalSince1970:2], [NSDate dateWithTimeIntervalSince1970:2], [NSDate dateWithTimeIntervalSince1970:2],
                  [NSDate dateWithTimeIntervalSince1970:3], [NSDate dateWithTimeIntervalSince1970:3], [NSDate dateWithTimeIntervalSince1970:3]]
        },
        @"decimalCol": @{
            @"one": @[[[RLMDecimal128 alloc] initWithNumber:@(1)], [[RLMDecimal128 alloc] initWithNumber:@(1)], [[RLMDecimal128 alloc] initWithNumber:@(1)]],
            @"two": @[[[RLMDecimal128 alloc] initWithNumber:@(2)], [[RLMDecimal128 alloc] initWithNumber:@(2)], [[RLMDecimal128 alloc] initWithNumber:@(2)]],
            @"three": @[[[RLMDecimal128 alloc] initWithNumber:@(3)], [[RLMDecimal128 alloc] initWithNumber:@(3)], [[RLMDecimal128 alloc] initWithNumber:@(3)]]
        },
        @"uuidCol": @{
            @"a": @[[[NSUUID alloc] initWithUUIDString:@"00000000-0000-0000-0000-000000000000"],
                    [[NSUUID alloc] initWithUUIDString:@"00000000-0000-0000-0000-000000000000"],
                    [[NSUUID alloc] initWithUUIDString:@"00000000-0000-0000-0000-000000000000"]],
            @"b": @[[[NSUUID alloc] initWithUUIDString:@"137DECC8-B300-4954-A233-F89909F4FD89"],
                    [[NSUUID alloc] initWithUUIDString:@"137DECC8-B300-4954-A233-F89909F4FD89"],
                    [[NSUUID alloc] initWithUUIDString:@"137DECC8-B300-4954-A233-F89909F4FD89"]],
            @"c": @[[[NSUUID alloc] initWithUUIDString:@"b84e8912-a7c2-41cd-8385-86d200d7b31e"],
                    [[NSUUID alloc] initWithUUIDString:@"b84e8912-a7c2-41cd-8385-86d200d7b31e"],
                    [[NSUUID alloc] initWithUUIDString:@"b84e8912-a7c2-41cd-8385-86d200d7b31e"]]
        },
        @"anyCol": @{
            @1: @[@3, @3, @3],
            @0: @[@2, @2, @2, @4, @4, @4]
        }
    };
}

- (id<RLMValue>)sectionKeyForValue:(id<RLMValue>)value {
    switch (value.rlm_anyValueType) {
        case RLMAnyValueTypeInt:
            return [NSNumber numberWithInt:(((NSNumber *)value).intValue % 2)];
        case RLMAnyValueTypeBool:
            return value;
        case RLMAnyValueTypeFloat:
            return [(NSNumber *)value isEqualToNumber:@(1.1f * 1)] ? @(1.1f) : @(2.2f);
        case RLMAnyValueTypeDouble:
            return [(NSNumber *)value isEqualToNumber:@(1.11 * 1)] ? @(1.11) : @(2.2);
        case RLMAnyValueTypeString:
            return [(NSString *)value substringToIndex:1];
        case RLMAnyValueTypeDate: {
            NSCalendar *calendar = [NSCalendar currentCalendar];
            [calendar setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
            NSDateComponents *comp = [calendar components:NSCalendarUnitWeekday fromDate:(NSDate *)value];
            return [NSNumber numberWithInteger:(NSInteger)comp.weekday];
        }
        case RLMAnyValueTypeDecimal128:
            switch ((int)((RLMDecimal128 *)value).doubleValue) {
                case 1:
                    return @"one";
                case 2:
                    return @"two";
                case 3:
                    return @"three";
                default:
                    XCTFail();
            }
        case RLMAnyValueTypeUUID:
            if ([(NSUUID *)value isEqual:[[NSUUID alloc] initWithUUIDString:@"00000000-0000-0000-0000-000000000000"]]) {
                return @"a";
            } else if ([(NSUUID *)value isEqual:[[NSUUID alloc] initWithUUIDString:@"137DECC8-B300-4954-A233-F89909F4FD89"]]) {
                return @"b";
            } else if ([(NSUUID *)value isEqual:[[NSUUID alloc] initWithUUIDString:@"b84e8912-a7c2-41cd-8385-86d200d7b31e"]]) {
                return @"c";
            }
        case RLMAnyValueTypeAny:
            return [NSNumber numberWithInt:(((NSNumber *)value).intValue % 2)];;
        default:
            XCTFail();
            return nil;
    }
}

- (void)testAllSupportedTypes {
    [self createObjects];
    RLMRealm *realm = self.realmWithTestPath;
    RLMResults<AllTypesObject *> *results = [AllTypesObject allObjectsInRealm:realm];

    void(^testBlock)(NSString *) = ^(NSString *keyPath) {
        __block int algoRunCount = 0;
        RLMSectionedResults<id<RLMValue>, AllTypesObject *> *sr = [results sectionedResultsSortedUsingKeyPath:keyPath
                                                                                                    ascending:YES
                                                                                                     keyBlock:^id<RLMValue>(id value) {
            algoRunCount++;
            return [self sectionKeyForValue:[value valueForKeyPath:keyPath]];
        }];

        NSDictionary *values = [self keyPathsAndValues][keyPath];
        for (RLMSection *section in sr) {
            NSArray *a = values[section.key];
            for (NSUInteger i = 0; i < section.count; i++) {
                XCTAssertEqualObjects(a[i], [section[i] valueForKeyPath:keyPath]);
            }
        }
        XCTAssertEqual(algoRunCount, 9);
    };

    testBlock(@"intCol");
    testBlock(@"boolCol");
    testBlock(@"floatCol");
    testBlock(@"doubleCol");
    testBlock(@"stringCol");
    testBlock(@"objectCol.stringCol");
    testBlock(@"dateCol");
    testBlock(@"cBoolCol");
    testBlock(@"longCol");
    testBlock(@"decimalCol");
    testBlock(@"uuidCol");
    testBlock(@"anyCol");
}

- (void)testAllSupportedOptionalTypes {
    NSDictionary *values = @{
        @"intObj": @1,
        @"floatObj": @1.0f,
        @"doubleObj": @1.0,
        @"boolObj": @YES,
        @"string": @"foo",
        @"date": [NSDate dateWithTimeIntervalSince1970:1],
        @"decimal": [[RLMDecimal128 alloc] initWithNumber:@1],
        @"uuidCol": [[NSUUID alloc] initWithUUIDString:@"85d4fbee-6ec6-47df-bfa1-615931903d7e"]
    };
    RLMRealm *realm = self.realmWithTestPath;
    [realm transactionWithBlock:^{
        [AllOptionalTypes createInRealm:realm withValue:values];
        [realm addObject:[AllOptionalTypes new]];
    }];

    RLMResults<AllOptionalTypes *> *results = [AllOptionalTypes allObjectsInRealm:realm];

    void(^testBlock)(NSString *) = ^(NSString *keyPath) {
        __block int algoRunCount = 0;
        RLMSectionedResults<id<RLMValue>, AllOptionalTypes *> *sr = [results sectionedResultsSortedUsingKeyPath:keyPath
                                                                                                      ascending:YES
                                                                                                       keyBlock:^id<RLMValue>(AllOptionalTypes *value) {
            algoRunCount++;
            if ([value valueForKeyPath:keyPath]) {
                return @"Not null";
            } else {
                return nil;
            }
        }];

        RLMSection *nullSection = sr[0];
        XCTAssertEqualObjects(nullSection.key, NSNull.null);
        XCTAssertNil([nullSection[0] valueForKeyPath:keyPath]);

        RLMSection *nonNullSection = sr[1];
        XCTAssertEqualObjects(nonNullSection.key, @"Not null");
        XCTAssertEqualObjects([nonNullSection[0] valueForKeyPath:keyPath], values[keyPath]);

        XCTAssertEqual(algoRunCount, 2);
    };

    testBlock(@"intObj");
    testBlock(@"floatObj");
    testBlock(@"doubleObj");
    testBlock(@"boolObj");
    testBlock(@"string");
    testBlock(@"date");
    testBlock(@"decimal");
    testBlock(@"uuidCol");
}

- (void)testObjectIdCol {
    RLMRealm *realm = self.realmWithTestPath;
    __block RLMObjectId *oid1;
    __block RLMObjectId *oid2;

    [realm transactionWithBlock:^{
        NSDictionary *ato1Values = [AllTypesObject values:0 stringObject:nil];
        oid1 = ato1Values[@"objectIdCol"];
        [AllTypesObject createInRealm:realm withValue:ato1Values];
        NSDictionary *ato2Values = [AllTypesObject values:0 stringObject:nil];
        oid2 = ato2Values[@"objectIdCol"];
        [AllTypesObject createInRealm:realm withValue:ato2Values];

        AllOptionalTypes *ot1 = [AllOptionalTypes new];
        ot1.objectId = oid1;
        AllOptionalTypes *ot2 = [AllOptionalTypes new];
        [realm addObjects:@[ot1, ot2]];
    }];

    RLMResults<AllTypesObject *> *results = [AllTypesObject allObjectsInRealm:realm];
    RLMResults<AllOptionalTypes *> *resultsOpt = [AllOptionalTypes allObjectsInRealm:realm];
    __block int sectionAlgoCount = 0;

    RLMSectionedResults<NSString *, AllTypesObject *> *sr = [results sectionedResultsSortedUsingKeyPath:@"objectIdCol"
                                                                                              ascending:YES
                                                                                               keyBlock:^id<RLMValue>(id value) {
        id v = [value valueForKeyPath:@"objectIdCol"];
        sectionAlgoCount++;
        return [((RLMObjectId *)v) isEqual:oid1] ? @"a" : @"b";
    }];

    NSDictionary *values = @{@"a": oid1, @"b": oid2};
    for (RLMSection *section in sr) {
        RLMObjectId *oid = values[section.key];
        for (NSUInteger i = 0; i < section.count; i++) {
            XCTAssertEqualObjects(oid, [section[i] valueForKeyPath:@"objectIdCol"]);
        }
    }
    XCTAssertEqual(sectionAlgoCount, 2);

    sectionAlgoCount = 0;
    RLMSectionedResults<NSString  *, AllOptionalTypes *> *srOpt = [resultsOpt sectionedResultsSortedUsingKeyPath:@"objectId"
                                                                                                       ascending:YES
                                                                                                        keyBlock:^id<RLMValue>(id value) {
        sectionAlgoCount++;
        id v = [value valueForKeyPath:@"objectId"];
        return !v ? @"b" : @"a";
    }];

    values = @{@"a": oid1, @"b": NSNull.null};
    for (RLMSection *section in srOpt) {
        RLMObjectId *oid = values[section.key];
        for (NSUInteger i = 0; i < section.count; i++) {
            id v = [section[i] valueForKeyPath:@"objectId"];
            if ([((NSString *)section.key) isEqualToString:@"b"]) {
                XCTAssertNil(v);
            } else {
                XCTAssertEqualObjects(oid, v);
            }
        }
    }
    XCTAssertEqual(sectionAlgoCount, 2);
}

- (void)testBinaryCol {
    RLMRealm *realm = self.realmWithTestPath;
    __block NSData *d1;
    __block NSData *d2;

    [realm transactionWithBlock:^{
        NSDictionary *ato1Values = [AllTypesObject values:0 stringObject:nil];
        d1 = ato1Values[@"binaryCol"];
        [AllTypesObject createInRealm:realm withValue:ato1Values];
        NSDictionary *ato2Values = [AllTypesObject values:0 stringObject:nil];
        d2 = ato2Values[@"binaryCol"];
        [AllTypesObject createInRealm:realm withValue:ato2Values];

        AllOptionalTypes *ot1 = [AllOptionalTypes new];
        ot1.data = d1;
        AllOptionalTypes *ot2 = [AllOptionalTypes new];
        [realm addObjects:@[ot1, ot2]];
    }];

    RLMResults<AllTypesObject *> *results = [AllTypesObject allObjectsInRealm:realm];
    RLMResults<AllOptionalTypes *> *resultsOpt = [AllOptionalTypes allObjectsInRealm:realm];
    __block int sectionAlgoCount = 0;

    // Sorting on binary col is unsupported
    RLMSectionedResults<NSString *, AllTypesObject *> *sr = [results sectionedResultsSortedUsingKeyPath:@"intCol"
                                                                                              ascending:YES
                                                                                               keyBlock:^id<RLMValue>(id value) {
        id v = [value valueForKeyPath:@"binaryCol"];
        sectionAlgoCount++;
        return [((NSData *)v) isEqual:d1] ? @"a" : @"b";
    }];

    NSDictionary *values = @{@"a": d1, @"b": d2};
    for (RLMSection *section in sr) {
        RLMObjectId *oid = values[section.key];
        for (NSUInteger i = 0; i < section.count; i++) {
            XCTAssertEqualObjects(oid, [section[i] valueForKeyPath:@"binaryCol"]);
        }
    }
    XCTAssertEqual(sectionAlgoCount, 2);

    sectionAlgoCount = 0;
    RLMSectionedResults<NSString *, AllOptionalTypes *> *srOpt = [resultsOpt sectionedResultsSortedUsingKeyPath:@"intObj"
                                                                                                      ascending:YES
                                                                                                       keyBlock:^id<RLMValue>(id value) {
        sectionAlgoCount++;
        id v = [value valueForKeyPath:@"data"];
        return !v ? @"b" : @"a";
    }];

    values = @{@"a": d1, @"b": NSNull.null};
    for (RLMSection *section in srOpt) {
        NSData *d = values[section.key];
        for (NSUInteger i = 0; i < section.count; i++) {
            id v = [section[i] valueForKeyPath:@"data"];
            if ([((NSString *)section.key) isEqualToString:@"b"]) {
                XCTAssertNil(v);
            } else {
                XCTAssertEqualObjects(d, v);
            }
        }
    }
    XCTAssertEqual(sectionAlgoCount, 2);
}

- (void)testAllKeys {
    RLMRealm *realm = self.realmWithTestPath;

    [realm transactionWithBlock:^{
        [StringObject createInRealm:realm withValue:@[@"apple"]];
        [StringObject createInRealm:realm withValue:@[@"any"]];
        [StringObject createInRealm:realm withValue:@[@"banana"]];
    }];

    RLMResults<StringObject *> *results = [StringObject allObjectsInRealm:realm];
    RLMSectionedResults<NSString *, AllTypesObject *> *sr = [results sectionedResultsSortedUsingKeyPath:@"stringCol"
                                                                                              ascending:YES
                                                                                               keyBlock:^id<RLMValue>(StringObject *value) {
        return value.firstLetter;
    }];

    XCTAssertEqualObjects(sr.allKeys, (@[@"a", @"b"]));
}

- (void)testDescription {
    RLMRealm *realm = self.realmWithTestPath;

    [realm transactionWithBlock:^{
        [StringObject createInRealm:realm withValue:@[@"apple"]];
        [StringObject createInRealm:realm withValue:@[@"any"]];
        [StringObject createInRealm:realm withValue:@[@"banana"]];
    }];

    RLMResults<StringObject *> *results = [StringObject allObjectsInRealm:realm];
    RLMSectionedResults<NSString *, AllTypesObject *> *sr = [results sectionedResultsSortedUsingKeyPath:@"stringCol"
                                                                                              ascending:YES
                                                                                               keyBlock:^id<RLMValue>(StringObject *value) {
        return value.firstLetter;
    }];

    NSString *expDesc =
    @"(?s)RLMSectionedResults\\<StringObject\\> \\<0x[a-z0-9]+\\> \\(\n"
    @"\t\\[a\\] RLMSection \\<0x[a-z0-9]+\\> \\(\n"
    @"\t\t\\[0\\] StringObject \\{\n"
    @"\t\t\tstringCol = any;\n"
    @"\t\t\\},\n"
    @"\t\t\\[1\\] StringObject \\{\n"
    @"\t\t\tstringCol = apple;\n"
    @"\t\t\\}\n"
    @"\t\\),\n"
    @"\t\\[b\\] RLMSection \\<0x[a-z0-9]+\\> \\(\n"
    @"\t\t\\[0\\] StringObject \\{\n"
    @"\t\t\tstringCol = banana;\n"
    @"\t\t\\}\n"
    @"\t\\)\n"
    @"\\)";
    RLMAssertMatches(sr.description, expDesc);

    expDesc =
    @"RLMSection \\<0x[a-z0-9]+\\> \\(\n"
    @"\t\\[0\\] StringObject \\{\n"
    @"\t\tstringCol = any;\n"
    @"\t\\},\n"
    @"\t\\[1\\] StringObject \\{\n"
    @"\t\tstringCol = apple;\n"
    @"\t\\}\n"
    @"\\)";
    RLMAssertMatches(sr[0].description, expDesc);
}

- (void)testFastEnumeration {
    for (int i = 0; i < 10; i++) {
        [self createObjects];
    }
    RLMRealm *realm = self.realmWithTestPath;

    __block NSUInteger algoRunCount = 0;
    __block NSUInteger forLoopCount = 0;

    RLMResults<AllTypesObject *> *results = [AllTypesObject allObjectsInRealm:realm];
    RLMSectionedResults<NSString *, AllTypesObject *> *sr = [results sectionedResultsSortedUsingKeyPath:@"objectCol.stringCol"
                                                                                              ascending:YES
                                                                                               keyBlock:^id<RLMValue>(AllTypesObject *value) {
        algoRunCount++;
        return value.stringCol;
    }];

    for (RLMSection *section in sr) {
        for (AllTypesObject *o __unused in section) {
            forLoopCount++;
        }
    }
    XCTAssertEqual(algoRunCount, results.count);
    XCTAssertEqual(forLoopCount, results.count);
    forLoopCount = 0;
    [self createObjects];
    algoRunCount = 0;

    for (RLMSection *section in sr) {
        for (AllTypesObject *o __unused in section) {
            forLoopCount++;
        }
    }
    XCTAssertEqual(algoRunCount, results.count);
    XCTAssertEqual(forLoopCount, results.count);
    forLoopCount = 0;
    algoRunCount = 0;
    NSUInteger originalCount = results.count;

    for (RLMSection *section in sr) {
        for (AllTypesObject *o __unused in section) {
            forLoopCount++;
        }
        [self createObjects];
    }
    // transaction inside the 'for in' should not invoke the section key
    // callback until the next access of the SectionedResults collection.
    XCTAssertEqual(algoRunCount, 0);
    XCTAssertEqual(forLoopCount, originalCount);
}

static RLMSectionedResultsChange *getChange(SectionedResultsTests *self, void (^block)(RLMRealm *)) {
    __block RLMSectionedResultsChange *changes;
    RLMRealm *realm = [RLMRealm defaultRealm];
    RLMResults<StringObject *> *results = [StringObject allObjectsInRealm:realm];
    RLMSectionedResults<NSString *, StringObject *> *sr = [results sectionedResultsSortedUsingKeyPath:@"stringCol"
                                                                                            ascending:YES
                                                                                             keyBlock:^id<RLMValue>(StringObject *value) {
        return value.firstLetter;
    }];

    id token = [sr addNotificationBlock:^(RLMSectionedResults *sr,
                                          RLMSectionedResultsChange *c) {
        changes = c;
        XCTAssertNotNil(sr);
        CFRunLoopStop(CFRunLoopGetCurrent());
    }];
    
    CFRunLoopRun();

    [self waitForNotification:RLMRealmDidChangeNotification realm:RLMRealm.defaultRealm block:^{
        RLMRealm *realm = [RLMRealm defaultRealm];
        [realm transactionWithBlock:^{
            block(realm);
        }];
    }];

    [(RLMNotificationToken *)token invalidate];
    token = nil;

    return changes;
}

static void ExpectChange(id self,
                         NSArray<NSIndexPath *> *insertions,
                         NSArray<NSIndexPath *> *deletions,
                         NSArray<NSIndexPath *> *modifications,
                         NSArray<NSNumber *> *sectionsToInsert,
                         NSArray<NSNumber *> *sectionsToRemove,
                         void (^block)(RLMRealm *)) {
    RLMSectionedResultsChange *changes = getChange(self, block);
    XCTAssertNotNil(changes);
    if (!changes) {
        return;
    }

    XCTAssertEqualObjects(insertions, changes.insertions);
    XCTAssertEqualObjects(deletions, changes.deletions);
    XCTAssertEqualObjects(modifications, changes.modifications);
    XCTAssertEqual(sectionsToInsert.count, changes.sectionsToInsert.count);
    XCTAssertEqual(sectionsToRemove.count, changes.sectionsToRemove.count);

    for (NSIndexPath *insertion in insertions) {
        NSArray *filtered = [insertions filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"section == %d", insertion.section]];
        XCTAssertEqualObjects(filtered, [changes insertionsInSection:insertion.section]);
    }

    for (NSIndexPath *deletion in deletions) {
        NSArray *filtered = [deletions filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"section == %d", deletion.section]];
        XCTAssertEqualObjects(filtered, [changes deletionsInSection:deletion.section]);
    }

    for (NSIndexPath *modification in modifications) {
        NSArray *filtered = [modifications filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"section == %d", modification.section]];
        XCTAssertEqualObjects(filtered, [changes modificationsInSection:modification.section]);
    }

    for (NSNumber *i in sectionsToInsert) {
        XCTAssertTrue([changes.sectionsToInsert containsIndex:i.unsignedIntegerValue]);
    }
    for (NSNumber *i in sectionsToRemove) {
        XCTAssertTrue([changes.sectionsToRemove containsIndex:i.unsignedIntegerValue]);
    }
}

- (void)testNotifications {
    StringObject *o1 = [[StringObject alloc] initWithValue:@[@"any"]];
    StringObject *o2 = [[StringObject alloc] initWithValue:@[@"zebra"]];
    StringObject *o3 = [[StringObject alloc] initWithValue:@[@"apple"]];
    StringObject *o4 = [[StringObject alloc] initWithValue:@[@"zulu"]];
    StringObject *o5 = [[StringObject alloc] initWithValue:@[@"banana"]];
    StringObject *o6 = [[StringObject alloc] initWithValue:@[@"beans"]];

    // Insertions
    ExpectChange(self,
                 @[[NSIndexPath indexPathForItem:0 inSection:0],
                   [NSIndexPath indexPathForItem:1 inSection:0],
                   [NSIndexPath indexPathForItem:0 inSection:1],
                   [NSIndexPath indexPathForItem:0 inSection:2],
                   [NSIndexPath indexPathForItem:1 inSection:2]],
                 @[], @[], @[@0, @1, @2], @[], ^(RLMRealm *realm) {
        [realm addObjects:@[o1, o2, o3, o4, o5]];
    });

    ExpectChange(self,
                 @[[NSIndexPath indexPathForItem:1 inSection:1]],
                 @[], @[], @[], @[], ^(RLMRealm *realm) {
        [realm addObject:o6];
    });

    // Deletions
    ExpectChange(self,
                 @[], @[[NSIndexPath indexPathForItem:0 inSection:1]],
                 @[], @[], @[], ^(RLMRealm *realm) {
        StringObject *o = [[[StringObject allObjectsInRealm:realm] objectsWhere:@"stringCol = 'banana'"] firstObject];
        [realm deleteObject:o]; // o5 will now be invalidated.
    });

    // Modifications
    ExpectChange(self,
                 @[], @[],
                 @[[NSIndexPath indexPathForItem:0 inSection:1]],
                 @[], @[], ^(RLMRealm *realm) {
        StringObject *o = [[[StringObject allObjectsInRealm:realm] objectsWhere:@"stringCol = 'beans'"] firstObject];
        o.stringCol = @"breakfast";
    });

    // Move object from one section to another
    ExpectChange(self,
                 @[[NSIndexPath indexPathForItem:0 inSection:0]],
                 @[],
                 @[],
                 @[], @[@1], ^(RLMRealm *realm) {
        StringObject *o = [[[StringObject allObjectsInRealm:realm] objectsWhere:@"stringCol = 'breakfast'"] firstObject];
        o.stringCol = @"all";
    });

    // Move object from one section to a new section
    ExpectChange(self,
                 @[[NSIndexPath indexPathForItem:0 inSection:0],
                   [NSIndexPath indexPathForItem:1 inSection:0],
                   [NSIndexPath indexPathForItem:2 inSection:0]],
                 @[],
                 @[],
                 @[@0], @[@0], ^(RLMRealm *realm) {
        RLMResults<StringObject *> *objs = [[StringObject allObjectsInRealm:realm] objectsWhere:@"stringCol BEGINSWITH 'a'"];
        for(StringObject *o in objs) {
            o.stringCol = @"max";
        }
    });
}

- (void)testNotificationsOnSection {
    __block RLMSectionedResultsChange *changes;
    RLMRealm *realm = self.realmWithTestPath;
    [self createObjects];
    RLMResults<StringObject *> *results = [StringObject allObjectsInRealm:realm];
    RLMSectionedResults<NSString *, StringObject *> *sr = [results sectionedResultsSortedUsingKeyPath:@"stringCol"
                                                                                            ascending:YES
                                                                                             keyBlock:^id<RLMValue>(StringObject *value) {
        return value.firstLetter;
    }];

    RLMSection<NSString *, StringObject *> *section = sr[0];

    RLMNotificationToken *token = [section addNotificationBlock:^(RLMSection *r, RLMSectionedResultsChange *c) {
        changes = c;
        XCTAssertNotNil(r);
        CFRunLoopStop(CFRunLoopGetCurrent());
    }
                                    keyPaths:@[@"stringCol"]];

    CFRunLoopRun();
    [self waitForNotification:RLMRealmDidChangeNotification realm:self.realmWithTestPath block:^{
        RLMRealm *r = self.realmWithTestPath;
        [r transactionWithBlock:^{
            StringObject *o = [StringObject allObjectsInRealm:r][0];
            o.stringCol = @"app";
        }];
    }];

    XCTAssertEqualObjects(changes.insertions, @[[NSIndexPath indexPathForItem:0 inSection:0]]);
    XCTAssertEqualObjects(changes.modifications, @[]);
    XCTAssertEqualObjects(changes.deletions, @[]);
    XCTAssertEqual(changes.sectionsToInsert.count, 0);
    XCTAssertEqual(changes.sectionsToRemove.count, 0);
    [token invalidate];
}

static RLMSectionedResultsChange *getChangePrimitive(SectionedResultsTests *self, void (^block)(RLMRealm *)) {
    __block RLMSectionedResultsChange *changes;
    RLMRealm *realm = [RLMRealm defaultRealm];

    AllPrimitiveArrays *obj = [AllPrimitiveArrays allObjectsInRealm:realm][0];
    RLMSectionedResults *sr = [obj.stringObj sectionedResultsSortedUsingKeyPath:@"self"
                                                                      ascending:YES
                                                                       keyBlock:^id<RLMValue> (id value) {
        return [value substringToIndex:1];
    }];

    id token = [sr addNotificationBlock:^(RLMSectionedResults *sr,
                                          RLMSectionedResultsChange *c) {
        changes = c;
        XCTAssertNotNil(sr);
        CFRunLoopStop(CFRunLoopGetCurrent());
    }];

    CFRunLoopRun();

    [self waitForNotification:RLMRealmDidChangeNotification realm:RLMRealm.defaultRealm block:^{
        RLMRealm *realm = [RLMRealm defaultRealm];
        [realm transactionWithBlock:^{
            block(realm);
        }];
    }];

    [(RLMNotificationToken *)token invalidate];
    token = nil;

    return changes;
}

static void ExpectChangePrimitive(id self,
                                  NSArray<NSIndexPath *> *insertions,
                                  NSArray<NSIndexPath *> *deletions,
                                  NSArray<NSIndexPath *> *modifications,
                                  NSArray<NSNumber *> *sectionsToInsert,
                                  NSArray<NSNumber *> *sectionsToRemove,
                                  void (^block)(RLMRealm *)) {
    RLMSectionedResultsChange *changes = getChangePrimitive(self, block);
    XCTAssertNotNil(changes);
    if (!changes) {
        return;
    }

    XCTAssertEqualObjects(insertions, changes.insertions);
    XCTAssertEqualObjects(deletions, changes.deletions);
    XCTAssertEqualObjects(modifications, changes.modifications);
    XCTAssertEqual(sectionsToInsert.count, changes.sectionsToInsert.count);
    XCTAssertEqual(sectionsToRemove.count, changes.sectionsToRemove.count);

    for (NSNumber *i in sectionsToInsert) {
        XCTAssertTrue([changes.sectionsToInsert containsIndex:i.unsignedIntegerValue]);
    }
    for (NSNumber *i in sectionsToRemove) {
        XCTAssertTrue([changes.sectionsToRemove containsIndex:i.unsignedIntegerValue]);
    }
}

- (void)testNotificationsPrimitive {
    RLMRealm *realm = [RLMRealm defaultRealm];
    [realm transactionWithBlock:^{
        AllPrimitiveArrays *arrObj = [AllPrimitiveArrays new];
        [realm addObject:arrObj];
    }];

    // Insertions
    ExpectChangePrimitive(self,
                          @[[NSIndexPath indexPathForItem:0 inSection:0],
                            [NSIndexPath indexPathForItem:0 inSection:1],
                            [NSIndexPath indexPathForItem:0 inSection:2]],
                          @[], @[], @[@0, @1, @2], @[], ^(RLMRealm *r) {
        AllPrimitiveArrays *o = [AllPrimitiveArrays allObjectsInRealm:r][0];
        [o.stringObj addObjects:@[@"apple", @"banana", @"orange"]];
    });

    // Deletions
    ExpectChangePrimitive(self,
                          @[], @[],
                          @[], @[], @[@0], ^(RLMRealm *r) {
        AllPrimitiveArrays *o = [AllPrimitiveArrays allObjectsInRealm:r][0];
        [o.stringObj removeObjectAtIndex:0];
    });

    // Modifications
    ExpectChangePrimitive(self,
                          @[], @[],
                          @[[NSIndexPath indexPathForItem:0 inSection:0]], @[], @[], ^(RLMRealm *r) {
        AllPrimitiveArrays *o = [AllPrimitiveArrays allObjectsInRealm:r][0];
        o.stringObj[0] = @"box"; // banana -> box
    });

    // Remove elements from one section, insert into another.
    ExpectChangePrimitive(self,
                          @[[NSIndexPath indexPathForItem:0 inSection:1]],
                          @[],
                          @[], @[@1], @[@0], ^(RLMRealm *r) {
        AllPrimitiveArrays *o = [AllPrimitiveArrays allObjectsInRealm:r][0];
        o.stringObj[0] = @"zebra"; // open -> zebra
    });
}

- (void)testSortDescriptors {
    RLMRealm *realm = self.realmWithTestPath;
    [realm transactionWithBlock:^{
        AggregateArrayObject *o1 = [AggregateArrayObject new];
        AggregateSetObject *o2 = [AggregateSetObject new];
        AggregateObject *aggObj1 = [AggregateObject new];
        aggObj1.intCol = 1;
        aggObj1.anyCol = @9;

        AggregateObject *aggObj2 = [AggregateObject new];
        aggObj2.intCol = 1;
        aggObj2.anyCol = @10;

        AggregateObject *aggObj3 = [AggregateObject new];
        aggObj3.intCol = 1;
        aggObj3.anyCol = @2;

        AggregateObject *aggObj4 = [AggregateObject new];
        aggObj4.intCol = 2;
        aggObj4.anyCol = @1;

        [o1.array addObjects:@[aggObj1, aggObj2, aggObj3, aggObj4]];
        [o2.set addObjects:@[aggObj1, aggObj2, aggObj3, aggObj4]];

        [realm addObjects:@[o1, o2]];
    }];

    NSMutableArray *sortDescriptors = [NSMutableArray new];
    [sortDescriptors addObject:[RLMSortDescriptor sortDescriptorWithKeyPath:@"intCol" ascending:YES]];
    [sortDescriptors addObject:[RLMSortDescriptor sortDescriptorWithKeyPath:@"anyCol" ascending:NO]];

    AggregateArrayObject *arrayObj = [AggregateArrayObject allObjectsInRealm:realm][0];
    AggregateSetObject *setObj = [AggregateSetObject allObjectsInRealm:realm][0];

    void(^run)(id<RLMCollection> collection) = ^(id<RLMCollection> collection) {
        RLMSectionedResults<NSNumber *, AggregateObject *> *sr = [collection sectionedResultsUsingSortDescriptors:sortDescriptors
                                                                                                         keyBlock:^id<RLMValue>(AggregateObject *value) {
            return @(value.intCol);
        }];

        XCTAssertNotNil(sr);
        XCTAssertEqual(sr.count, 2);
        XCTAssertEqual(sr[0].count, 3);
        XCTAssertEqual(sr[1].count, 1);
        XCTAssertEqualObjects(sr[0].key, @1);
        XCTAssertEqual(sr[0][0].intCol, 1);
        XCTAssertEqualObjects(sr[0][0].anyCol, @10);
        XCTAssertEqual(sr[0][1].intCol, 1);
        XCTAssertEqualObjects(sr[0][1].anyCol, @9);
        XCTAssertEqualObjects(sr[1].key, @2);
        XCTAssertEqual(sr[1][0].intCol, 2);
        XCTAssertEqualObjects(sr[1][0].anyCol, @1);
    };

    run(arrayObj.array);
    run(setObj.set);
    run([AggregateObject allObjectsInRealm:realm]);
}

- (void)testFrozenFromResults {
    [self createObjects];
    RLMRealm *realm = self.realmWithTestPath;
    // Test creation from frozen RLMResults
    RLMResults<AllTypesObject *> *results = [[AllTypesObject allObjectsInRealm:realm] freeze];
    RLMSectionedResults<NSString *, AllTypesObject *> *sr = [results sectionedResultsSortedUsingKeyPath:@"objectCol.stringCol"
                                                                                              ascending:YES
                                                                                               keyBlock:^id<RLMValue>(AllTypesObject *value) {
        return [value.objectCol.stringCol substringToIndex:1];
    }];

    [self createObjects];

    XCTAssertNotNil(sr);
    XCTAssertEqual(sr.count, 4);
    XCTAssertEqual(sr[0].count, 3);
    XCTAssertEqual(sr[1].count, 1);
    XCTAssertEqual(sr[2].count, 2);
    XCTAssertEqual(sr[3].count, 3);

    XCTAssertTrue(sr[0][0].isFrozen);
    XCTAssertTrue(sr.isFrozen);

    RLMSectionedResults<NSString *, AllTypesObject *> *thawed = [sr thaw];
    XCTAssertNotNil(thawed);
    XCTAssertEqual(thawed.count, 4);
    XCTAssertEqual(thawed[0].count, 6);
    XCTAssertEqual(thawed[1].count, 2);
    XCTAssertEqual(thawed[2].count, 4);
    XCTAssertEqual(thawed[3].count, 6);

    XCTAssertFalse(thawed[0][0].isFrozen);
    XCTAssertFalse(thawed.isFrozen);
}

- (void)testFrozenSectionedResults {
    [self createObjects];
    RLMRealm *realm = self.realmWithTestPath;
    // Test creation from frozen RLMResults
    RLMResults<AllTypesObject *> *results = [AllTypesObject allObjectsInRealm:realm];
    RLMSectionedResults<NSString *, AllTypesObject *> *sr = [results sectionedResultsSortedUsingKeyPath:@"objectCol.stringCol"
                                                                                              ascending:YES
                                                                                               keyBlock:^id<RLMValue>(AllTypesObject *value) {
        return [value.objectCol.stringCol substringToIndex:1];
    }];

    RLMSectionedResults<NSString *, AllTypesObject *> *frozen = [sr freeze];
    XCTAssertEqual(frozen, [frozen freeze]); // should return self
    [self createObjects];

    XCTAssertNotNil(frozen);
    XCTAssertEqual(frozen.count, 4);
    XCTAssertEqual(frozen[0].count, 3);
    XCTAssertEqual(frozen[1].count, 1);
    XCTAssertEqual(frozen[2].count, 2);
    XCTAssertEqual(frozen[3].count, 3);

    XCTAssertTrue(frozen[0][0].isFrozen);
    XCTAssertTrue(frozen.isFrozen);

    RLMSectionedResults<NSString *, AllTypesObject *> *thawed = [frozen thaw];
    XCTAssertEqual(thawed, [thawed thaw]); // should return self
    XCTAssertNotNil(thawed);
    XCTAssertEqual(thawed.count, 4);
    XCTAssertEqual(thawed[0].count, 6);
    XCTAssertEqual(thawed[1].count, 2);
    XCTAssertEqual(thawed[2].count, 4);
    XCTAssertEqual(thawed[3].count, 6);

    XCTAssertFalse(thawed[0][0].isFrozen);
    XCTAssertFalse(thawed.isFrozen);
}

- (void)testFrozenSection {
    [self createObjects];
    RLMRealm *realm = self.realmWithTestPath;
    // Test creation from frozen RLMResults
    RLMResults<AllTypesObject *> *results = [AllTypesObject allObjectsInRealm:realm];
    RLMSectionedResults<NSString *, AllTypesObject *> *sr = [results sectionedResultsSortedUsingKeyPath:@"objectCol.stringCol"
                                                                                              ascending:YES
                                                                                               keyBlock:^id<RLMValue>(AllTypesObject *value) {
        return [value.objectCol.stringCol substringToIndex:1];
    }];

    RLMSection<NSString *, AllTypesObject *> *frozen = [sr[0] freeze];
    XCTAssertEqual(frozen, [frozen freeze]); // should return self
    [self createObjects];

    XCTAssertNotNil(frozen);
    XCTAssertEqual(frozen.count, 3);
    XCTAssertTrue(frozen[0].isFrozen);
    XCTAssertTrue(frozen.isFrozen);

    RLMSection<NSString *, AllTypesObject *> *thawed = [frozen thaw];
    XCTAssertEqual(thawed, [thawed thaw]); // should return self
    XCTAssertNotNil(thawed);
    XCTAssertEqual(thawed.count, 6);

    XCTAssertFalse(thawed[0].isFrozen);
    XCTAssertFalse(thawed.isFrozen);
}

- (void)testInitFromRLMArray {
    RLMRealm *realm = self.realmWithTestPath;
    [realm transactionWithBlock:^{
        [MixedObject createInRealm:realm withValue:@[NSNull.null, @[@5, @3, @2, @4]]];
    }];

    MixedObject *obj = [MixedObject allObjectsInRealm:realm][0];
    RLMSectionedResults<NSNumber *, MixedObject *> *sr = [obj.anyArray sectionedResultsSortedUsingKeyPath:@"self"
                                                                                                ascending:YES
                                                                                                 keyBlock:^id<RLMValue>(id<RLMValue> value) {
        return @(((NSNumber *)value).intValue % 2);
    }];

    XCTAssertNotNil(sr);
    XCTAssertEqual(sr.count, 2);
    XCTAssertEqual(sr[0].count, 2);
    XCTAssertEqual(sr[1].count, 2);
    XCTAssertEqualObjects(sr[0].key, @0);
    XCTAssertEqualObjects(sr[0][0], @2);
    XCTAssertEqualObjects(sr[0][1], @4);
    XCTAssertEqualObjects(sr[1].key, @1);
    XCTAssertEqualObjects(sr[1][0], @3);
    XCTAssertEqualObjects(sr[1][1], @5);

    // Descending
    sr = [obj.anyArray sectionedResultsSortedUsingKeyPath:@"self"
                                                ascending:NO
                                                 keyBlock:^id<RLMValue>(id<RLMValue> value) {
        return @(((NSNumber *)value).intValue % 2);
    }];

    XCTAssertNotNil(sr);
    XCTAssertEqual(sr.count, 2);
    XCTAssertEqual(sr[0].count, 2);
    XCTAssertEqual(sr[1].count, 2);
    XCTAssertEqualObjects(sr[0].key, @1);
    XCTAssertEqualObjects(sr[0][0], @5);
    XCTAssertEqualObjects(sr[0][1], @3);
    XCTAssertEqualObjects(sr[1].key, @0);
    XCTAssertEqualObjects(sr[1][0], @4);
    XCTAssertEqualObjects(sr[1][1], @2);
}

- (void)testInitFromRLMSet {
    RLMRealm *realm = self.realmWithTestPath;
    [realm transactionWithBlock:^{
        AllPrimitiveSets *o = [AllPrimitiveSets new];
        [o.intObj addObject:@5];
        [o.intObj addObject:@4];
        [o.intObj addObject:@1];
        [o.intObj addObject:@2];
        [realm addObject:o];
    }];

    AllPrimitiveSets *obj = [AllPrimitiveSets allObjectsInRealm:realm][0];
    RLMSectionedResults<NSNumber *, AllPrimitiveSets *> *sr = [obj.intObj sectionedResultsSortedUsingKeyPath:@"self"
                                                                                                   ascending:YES
                                                                                                    keyBlock:^id<RLMValue>(id<RLMValue> value) {
        return @(((NSNumber *)value).intValue % 2);
    }];

    XCTAssertNotNil(sr);
    XCTAssertEqual(sr.count, 2);
    XCTAssertEqual(sr[0].count, 2);
    XCTAssertEqual(sr[1].count, 2);
    XCTAssertEqualObjects(sr[0].key, @1);
    XCTAssertEqualObjects(sr[0][0], @1);
    XCTAssertEqualObjects(sr[0][1], @5);
    XCTAssertEqualObjects(sr[1].key, @0);
    XCTAssertEqualObjects(sr[1][0], @2);
    XCTAssertEqualObjects(sr[1][1], @4);

    // Descending
    sr = [obj.intObj sectionedResultsSortedUsingKeyPath:@"self"
                                              ascending:NO
                                               keyBlock:^id<RLMValue>(id<RLMValue> value) {
        return @(((NSNumber *)value).intValue % 2);
    }];

    XCTAssertNotNil(sr);
    XCTAssertEqual(sr.count, 2);
    XCTAssertEqual(sr[0].count, 2);
    XCTAssertEqual(sr[1].count, 2);
    XCTAssertEqualObjects(sr[0].key, @1);
    XCTAssertEqualObjects(sr[0][0], @5);
    XCTAssertEqualObjects(sr[0][1], @1);
    XCTAssertEqualObjects(sr[1].key, @0);
    XCTAssertEqualObjects(sr[1][0], @4);
    XCTAssertEqualObjects(sr[1][1], @2);
}

@end
