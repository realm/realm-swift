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

#import "RLMSyncTestCase.h"

#if TARGET_OS_OSX

// Each of these test suites compares either Person or non-realm-object values
#define RLMAssertEqual(lft, rgt) do { \
    if (isObject) { \
        XCTAssertEqualObjects(lft.firstName, \
                              ((Person *)rgt).firstName); \
    } else { \
        XCTAssertEqualObjects(lft, rgt); \
    } \
} while (0)

#pragma mark RLMSet Sync Tests

@interface RLMSetObjectServerTests : RLMSyncTestCase
@end

@implementation RLMSetObjectServerTests

- (void)roundTripWithPropertyGetter:(RLMSet *(^)(id))propertyGetter
                             values:(NSArray *)values
                otherPropertyGetter:(RLMSet *(^)(id))otherPropertyGetter
                        otherValues:(NSArray *)otherValues
                           isObject:(BOOL)isObject
                         callerName:(NSString *)callerName {
    RLMUser *readUser = [self logInUserForCredentials:[self basicCredentialsWithName:callerName
                                                                            register:YES]];
    RLMUser *writeUser = [self logInUserForCredentials:[self basicCredentialsWithName:[callerName stringByAppendingString:@"Writer"]
                                                                            register:YES]];

    RLMRealm *readRealm = [self openRealmForPartitionValue:callerName user:readUser];
    RLMRealm *writeRealm = [self openRealmForPartitionValue:callerName user:writeUser];
    auto write = [&](auto fn) {
        [writeRealm transactionWithBlock:^{
            fn();
        }];
        [self waitForUploadsForRealm:writeRealm];
        [self waitForDownloadsForRealm:readRealm];
    };

    CHECK_COUNT(0, RLMSetSyncObject, readRealm);

    __block RLMSetSyncObject *writeObj;
    write(^{
        writeObj = [RLMSetSyncObject createInRealm:writeRealm
                                         withValue:@{@"_id": [RLMObjectId objectId]}];
    });
    CHECK_COUNT(1, RLMSetSyncObject, readRealm);

    write(^{
        [propertyGetter(writeObj) addObjects:values];
        [otherPropertyGetter(writeObj) addObjects:otherValues];
    });
    CHECK_COUNT(1, RLMSetSyncObject, readRealm);
    RLMResults<RLMSetSyncObject *> *results = [RLMSetSyncObject allObjectsInRealm:readRealm];
    RLMSetSyncObject *obj = results.firstObject;
    RLMSet<Person *> *set = propertyGetter(obj);
    RLMSet<Person *> *otherSet = otherPropertyGetter(obj);
    XCTAssertEqual(set.count, values.count);
    XCTAssertEqual(otherSet.count, otherValues.count);

    write(^{
        if (isObject) {
            [propertyGetter(writeObj) removeAllObjects];
            [propertyGetter(writeObj) addObject:values[0]];
        } else {
            [propertyGetter(writeObj) intersectSet:otherPropertyGetter(writeObj)];
        }
    });
    CHECK_COUNT(1, RLMSetSyncObject, readRealm);
    if (!isObject) {
        XCTAssertTrue([propertyGetter(obj) intersectsSet:propertyGetter(obj)]);
        XCTAssertEqual(propertyGetter(obj).count, 1U);
    }

    write(^{
        [propertyGetter(writeObj) removeAllObjects];
        [otherPropertyGetter(writeObj) removeAllObjects];
    });
    XCTAssertEqual(propertyGetter(obj).count, 0U);
    XCTAssertEqual(otherPropertyGetter(obj).count, 0U);
}

- (void)testIntSet {
    [self roundTripWithPropertyGetter:^RLMSet *(RLMSetSyncObject *obj) { return obj.intSet; }
                               values:@[@123, @234, @345]
                  otherPropertyGetter:^RLMSet *(RLMSetSyncObject *obj) { return obj.otherIntSet; }
                          otherValues:@[@345, @567, @789]
                             isObject:NO
                           callerName:NSStringFromSelector(_cmd)];
}

- (void)testStringSet {
    [self roundTripWithPropertyGetter:^RLMSet *(RLMSetSyncObject *obj) { return obj.stringSet; }
                               values:@[@"Who", @"What", @"When"]
                  otherPropertyGetter:^RLMSet *(RLMSetSyncObject *obj) { return obj.otherStringSet; }
                          otherValues:@[@"When", @"Strings", @"Collide"]
                             isObject:NO
                           callerName:NSStringFromSelector(_cmd)];
}

- (void)testDataSet {
    NSData* (^createData)(size_t) = ^(size_t size) {
        void *buffer = malloc(size);
        arc4random_buf(buffer, size);
        return [NSData dataWithBytesNoCopy:buffer length:size freeWhenDone:YES];
    };

    NSData *duplicateData = createData(1024U);
    [self roundTripWithPropertyGetter:^RLMSet *(RLMSetSyncObject *obj) { return obj.dataSet; }
                               values:@[duplicateData, createData(1024U), createData(1024U)]
                  otherPropertyGetter:^RLMSet *(RLMSetSyncObject *obj) { return obj.otherDataSet; }
                          otherValues:@[duplicateData, createData(1024U), createData(1024U)]
                             isObject:NO
                           callerName:NSStringFromSelector(_cmd)];
}

- (void)testDoubleSet {
    [self roundTripWithPropertyGetter:^RLMSet *(RLMSetSyncObject *obj) { return obj.doubleSet; }
                               values:@[@123.456, @234.456, @345.567]
                  otherPropertyGetter:^RLMSet *(RLMSetSyncObject *obj) { return obj.otherDoubleSet; }
                          otherValues:@[@123.456, @434.456, @545.567]
                             isObject:NO
                           callerName:NSStringFromSelector(_cmd)];
}

- (void)testObjectIdSet {
    [self roundTripWithPropertyGetter:^RLMSet *(RLMSetSyncObject *obj) { return obj.objectIdSet; }
                               values:@[[[RLMObjectId alloc] initWithString:@"6058f12b957ba06156586a7c" error:nil],
                                        [[RLMObjectId alloc] initWithString:@"6058f12682b2fbb1f334ef1d" error:nil],
                                        [[RLMObjectId alloc] initWithString:@"6058f12d42e5a393e67538d0" error:nil]]
                  otherPropertyGetter:^RLMSet *(RLMSetSyncObject *obj) { return obj.otherObjectIdSet; }
                          otherValues:@[[[RLMObjectId alloc] initWithString:@"6058f12b957ba06156586a7c" error:nil],
                                        [[RLMObjectId alloc] initWithString:@"6058f12682b2fbb1f334ef1e" error:nil],
                                        [[RLMObjectId alloc] initWithString:@"6058f12d42e5a393e67538df" error:nil]]
                             isObject:NO
                           callerName:NSStringFromSelector(_cmd)];
}

- (void)testDecimalSet {
    [self roundTripWithPropertyGetter:^RLMSet *(RLMSetSyncObject *obj) { return obj.decimalSet; }
                               values:@[[[RLMDecimal128 alloc] initWithNumber:@123.456],
                                        [[RLMDecimal128 alloc] initWithNumber:@223.456],
                                        [[RLMDecimal128 alloc] initWithNumber:@323.456]]
                  otherPropertyGetter:^RLMSet *(RLMSetSyncObject *obj) { return obj.otherDecimalSet; }
                          otherValues:@[[[RLMDecimal128 alloc] initWithNumber:@123.456],
                                        [[RLMDecimal128 alloc] initWithNumber:@423.456],
                                        [[RLMDecimal128 alloc] initWithNumber:@523.456]]
                             isObject:NO
                           callerName:NSStringFromSelector(_cmd)];
}

- (void)testUUIDSet {
    [self roundTripWithPropertyGetter:^RLMSet *(RLMSetSyncObject *obj) { return obj.uuidSet; }
                               values:@[[[NSUUID alloc] initWithUUIDString:@"6b28ec45-b29a-4b0a-bd6a-343c7f6d90fd"],
                                        [[NSUUID alloc] initWithUUIDString:@"6b28ec45-b29a-4b0a-bd6a-343c7f6d90fe"],
                                        [[NSUUID alloc] initWithUUIDString:@"6b28ec45-b29a-4b0a-bd6a-343c7f6d90ff"]]
                  otherPropertyGetter:^RLMSet *(RLMSetSyncObject *obj) { return obj.otherUuidSet; }
                          otherValues:@[[[NSUUID alloc] initWithUUIDString:@"6b28ec45-b29a-4b0a-bd6a-343c7f6d90fd"],
                                        [[NSUUID alloc] initWithUUIDString:@"6b28ec45-b29a-4b0a-bd6a-343c7f6d90ae"],
                                        [[NSUUID alloc] initWithUUIDString:@"6b28ec45-b29a-4b0a-bd6a-343c7f6d90bf"]]
                             isObject:NO
                           callerName:NSStringFromSelector(_cmd)];
}

- (void)testObjectSet {
    [self roundTripWithPropertyGetter:^RLMSet *(RLMSetSyncObject *obj) { return obj.objectSet; }
                               values:@[[Person john], [Person paul], [Person ringo]]
                  otherPropertyGetter:^RLMSet *(RLMSetSyncObject *obj) { return obj.otherObjectSet; }
                          otherValues:@[[Person john], [Person paul], [Person ringo]]
                             isObject:YES
                           callerName:NSStringFromSelector(_cmd)];
}

- (void)testAnySet {
    [self roundTripWithPropertyGetter:^RLMSet *(RLMSetSyncObject *obj) { return obj.anySet; }
                               values:@[@123, @"Hey", NSNull.null]
                  otherPropertyGetter:^RLMSet *(RLMSetSyncObject *obj) { return obj.otherAnySet; }
                          otherValues:@[[[NSUUID alloc] initWithUUIDString:@"6b28ec45-b29a-4b0a-bd6a-343c7f6d90fd"],
                                        @123,
                                        [[RLMObjectId alloc] initWithString:@"6058f12682b2fbb1f334ef1d" error:nil]]
                             isObject:NO
                           callerName:NSStringFromSelector(_cmd)];
}

@end

#pragma mark RLMArray Sync Tests

@interface RLMArrayObjectServerTests : RLMSyncTestCase
@end

@implementation RLMArrayObjectServerTests

- (void)roundTripWithPropertyGetter:(RLMArray *(^)(id))propertyGetter
                             values:(NSArray *)values
                           isObject:(BOOL)isObject
                         callerName:(NSString *)callerName {
    RLMUser *readUser = [self logInUserForCredentials:[self basicCredentialsWithName:callerName
                                                                            register:YES]];
    RLMUser *writeUser = [self logInUserForCredentials:[self basicCredentialsWithName:[callerName stringByAppendingString:@"Writer"]
                                                                            register:YES]];

    RLMRealm *readRealm = [self openRealmForPartitionValue:callerName user:readUser];
    RLMRealm *writeRealm = [self openRealmForPartitionValue:callerName user:writeUser];
    auto write = [&](auto fn) {
        [writeRealm transactionWithBlock:^{
            fn();
        }];
        [self waitForUploadsForRealm:writeRealm];
        [self waitForDownloadsForRealm:readRealm];
    };

    CHECK_COUNT(0, RLMArraySyncObject, readRealm);
    __block RLMArraySyncObject *writeObj;
    write(^{
        writeObj = [RLMArraySyncObject createInRealm:writeRealm
                                           withValue:@{@"_id": [RLMObjectId objectId]}];
    });
    CHECK_COUNT(1, RLMArraySyncObject, readRealm);

    write(^{
        [propertyGetter(writeObj) addObjects:values];
        [propertyGetter(writeObj) addObjects:values];
    });
    CHECK_COUNT(1, RLMArraySyncObject, readRealm);
    RLMResults<RLMArraySyncObject *> *results = [RLMArraySyncObject allObjectsInRealm:readRealm];
    RLMArraySyncObject *obj = results.firstObject;
    RLMArray<Person *> *array = propertyGetter(obj);
    XCTAssertEqual(array.count, values.count*2);
    for (NSUInteger i = 0; i < values.count; i++) {
        RLMAssertEqual(array[i], values[i]);
    }

    write(^{
        [propertyGetter(writeObj) removeLastObject];
        [propertyGetter(writeObj) removeLastObject];
        [propertyGetter(writeObj) removeLastObject];
    });
    XCTAssertEqual(propertyGetter(obj).count, values.count);

    write(^{
        [propertyGetter(writeObj) replaceObjectAtIndex:0
                                            withObject:values[1]];
    });
    RLMAssertEqual(array[0], values[1]);
}

- (void)testIntArray {
    [self roundTripWithPropertyGetter:^RLMArray *(RLMArraySyncObject *obj) { return obj.intArray; }
                               values:@[@123, @234, @345]
                             isObject:NO
                           callerName:NSStringFromSelector(_cmd)];
}

- (void)testBoolArray {
    [self roundTripWithPropertyGetter:^RLMArray *(RLMArraySyncObject *obj) { return obj.boolArray; }
                               values:@[@YES, @NO, @YES]
                             isObject:NO
                           callerName:NSStringFromSelector(_cmd)];
}

- (void)testStringArray {
    [self roundTripWithPropertyGetter:^RLMArray *(RLMArraySyncObject *obj) { return obj.stringArray; }
                               values:@[@"Hello...", @"It's", @"Me"]
                             isObject:NO
                           callerName:NSStringFromSelector(_cmd)];
}

- (void)testDataArray {
    [self roundTripWithPropertyGetter:^RLMArray *(RLMArraySyncObject *obj) { return obj.dataArray; }
                               values:@[[NSData dataWithBytes:(unsigned char[]){0x0a}
                                                       length:1],
                                        [NSData dataWithBytes:(unsigned char[]){0x0b}
                                                       length:1],
                                        [NSData dataWithBytes:(unsigned char[]){0x0c}
                                                       length:1]]
                             isObject:NO
                           callerName:NSStringFromSelector(_cmd)];
}

- (void)testDoubleArray {
    [self roundTripWithPropertyGetter:^RLMArray *(RLMArraySyncObject *obj) { return obj.doubleArray; }
                               values:@[@123.456, @789.456, @987.344]
                             isObject:NO
                           callerName:NSStringFromSelector(_cmd)];
}

- (void)testObjectIdArray {
    [self roundTripWithPropertyGetter:^RLMArray *(RLMArraySyncObject *obj) { return obj.objectIdArray; }
                               values:@[[[RLMObjectId alloc] initWithString:@"6058f12b957ba06156586a7c" error:nil],
                                        [[RLMObjectId alloc] initWithString:@"6058f12682b2fbb1f334ef1d" error:nil],
                                        [[RLMObjectId alloc] initWithString:@"6058f12d42e5a393e67538d0" error:nil]]
                             isObject:NO
                           callerName:NSStringFromSelector(_cmd)];
}

- (void)testDecimalArray {
    [self roundTripWithPropertyGetter:^RLMArray *(RLMArraySyncObject *obj) { return obj.decimalArray; }
                               values:@[[[RLMDecimal128 alloc] initWithNumber:@123.456],
                                        [[RLMDecimal128 alloc] initWithNumber:@456.456],
                                        [[RLMDecimal128 alloc] initWithNumber:@789.456]]
                             isObject:NO
                           callerName:NSStringFromSelector(_cmd)];
}

- (void)testUUIDArray {
    [self roundTripWithPropertyGetter:^RLMArray *(RLMArraySyncObject *obj) { return obj.uuidArray; }
                               values:@[[[NSUUID alloc] initWithUUIDString:@"6b28ec45-b29a-4b0a-bd6a-343c7f6d90fd"],
                                        [[NSUUID alloc] initWithUUIDString:@"6b28ec45-b29a-4b0a-bd6a-343c7f6d90fe"],
                                        [[NSUUID alloc] initWithUUIDString:@"6b28ec45-b29a-4b0a-bd6a-343c7f6d90ff"]]
                             isObject:NO
                           callerName:NSStringFromSelector(_cmd)];
}

- (void)testObjectArray {
    [self roundTripWithPropertyGetter:^RLMArray *(RLMArraySyncObject *obj) { return obj.objectArray; }
                               values:@[[Person john], [Person paul], [Person ringo]]
                             isObject:YES
                           callerName:NSStringFromSelector(_cmd)];
}

- (void)testAnyArray {
    [self roundTripWithPropertyGetter:^RLMArray *(RLMArraySyncObject *obj) { return obj.anyArray; }
                               values:@[@1234, @"I'm a String", NSNull.null]
                             isObject:NO
                           callerName:NSStringFromSelector(_cmd)];
}

@end

#pragma mark RLMDictionary Sync Tests

@interface RLMDictionaryObjectServerTests : RLMSyncTestCase
@end

@implementation RLMDictionaryObjectServerTests

- (void)roundTripWithPropertyGetter:(RLMDictionary *(^)(id))propertyGetter
                             values:(NSDictionary *)values
                           isObject:(BOOL)isObject
                         callerName:(NSString *)callerName {
    RLMUser *readUser = [self logInUserForCredentials:[self basicCredentialsWithName:callerName
                                                                            register:YES]];
    RLMUser *writeUser = [self logInUserForCredentials:[self basicCredentialsWithName:[callerName stringByAppendingString:@"Writer"]
                                                                            register:YES]];

    RLMRealm *readRealm = [self openRealmForPartitionValue:callerName user:readUser];
    RLMRealm *writeRealm = [self openRealmForPartitionValue:callerName user:writeUser];
    auto write = [&](auto fn) {
        [writeRealm transactionWithBlock:^{
            fn();
        }];
        [self waitForUploadsForRealm:writeRealm];
        [self waitForDownloadsForRealm:readRealm];
    };

    CHECK_COUNT(0, RLMDictionarySyncObject, readRealm);

    __block RLMDictionarySyncObject *writeObj;
    write(^{
        writeObj = [RLMDictionarySyncObject createInRealm:writeRealm
                                                withValue:@{@"_id": [RLMObjectId objectId]}];
    });
    CHECK_COUNT(1, RLMDictionarySyncObject, readRealm);

    write(^{
        [propertyGetter(writeObj) addEntriesFromDictionary:values];
    });
    CHECK_COUNT(1, RLMDictionarySyncObject, readRealm);
    RLMResults<RLMDictionarySyncObject *> *results = [RLMDictionarySyncObject allObjectsInRealm:readRealm];
    RLMDictionarySyncObject *obj = results.firstObject;
    RLMDictionary<NSString *, Person *> *dict = propertyGetter(obj);
    XCTAssertEqual(dict.count, values.count);
    for (NSString *key in values) {
        RLMAssertEqual(dict[key], values[key]);
    }

    write(^{
        int i = 0;
        RLMDictionary *dict = propertyGetter(writeObj);
        for (NSString *key in dict) {
            dict[key] = nil;
            if (++i >= 3) {
                break;
            }
        }
    });
    CHECK_COUNT(1, RLMDictionarySyncObject, readRealm);
    XCTAssertEqual(dict.count, 2U);

    write(^{
        RLMDictionary *dict = propertyGetter(writeObj);
        NSArray *keys = dict.allKeys;
        dict[keys[0]] = dict[keys[1]];
    });
    CHECK_COUNT(1, RLMDictionarySyncObject, readRealm);
    XCTAssertEqual(dict.count, 2U);
    NSArray *keys = dict.allKeys;
    RLMAssertEqual(dict[keys[0]], dict[keys[1]]);
}

- (void)testIntDictionary {
    [self roundTripWithPropertyGetter:^RLMDictionary *(RLMDictionarySyncObject *obj) { return obj.intDictionary; }
                               values:@{@"0": @123, @"1": @234, @"2": @345, @"3": @567, @"4": @789}
                             isObject:NO
                           callerName:NSStringFromSelector(_cmd)];
}
- (void)testStringDictionary {
    [self roundTripWithPropertyGetter:^RLMDictionary *(RLMDictionarySyncObject *obj) { return obj.stringDictionary; }
                               values:@{@"0": @"Who", @"1": @"What", @"2": @"When", @"3": @"Strings", @"4": @"Collide"}
                             isObject:NO
                           callerName:NSStringFromSelector(_cmd)];
}

- (void)testDataDictionary {
    [self roundTripWithPropertyGetter:^RLMDictionary *(RLMDictionarySyncObject *obj) { return obj.dataDictionary; }
                               values:@{@"0": [NSData dataWithBytes:(unsigned char[]){0x0a} length:1],
                                        @"1": [NSData dataWithBytes:(unsigned char[]){0x0b} length:1],
                                        @"2": [NSData dataWithBytes:(unsigned char[]){0x0c} length:1],
                                        @"3": [NSData dataWithBytes:(unsigned char[]){0x0d} length:1],
                                        @"4": [NSData dataWithBytes:(unsigned char[]){0x0e} length:1]}
                             isObject:NO
                           callerName:NSStringFromSelector(_cmd)];
}

- (void)testDoubleDictionary {
    [self roundTripWithPropertyGetter:^RLMDictionary *(RLMDictionarySyncObject *obj) { return obj.doubleDictionary; }
                               values:@{@"0": @123.456, @"1": @234.456, @"2": @345.567, @"3": @434.456, @"4": @545.567}
                             isObject:NO
                           callerName:NSStringFromSelector(_cmd)];
}

- (void)testObjectIdDictionary {
    [self roundTripWithPropertyGetter:^RLMDictionary *(RLMDictionarySyncObject *obj) { return obj.objectIdDictionary; }
                               values:@{@"0": [[RLMObjectId alloc] initWithString:@"6058f12b957ba06156586a7c" error:nil],
                                        @"1": [[RLMObjectId alloc] initWithString:@"6058f12682b2fbb1f334ef1d" error:nil],
                                        @"2": [[RLMObjectId alloc] initWithString:@"6058f12d42e5a393e67538d0" error:nil],
                                        @"3": [[RLMObjectId alloc] initWithString:@"6058f12682b2fbb1f334ef1e" error:nil],
                                        @"4": [[RLMObjectId alloc] initWithString:@"6058f12d42e5a393e67538df" error:nil]}
                             isObject:NO
                           callerName:NSStringFromSelector(_cmd)];
}

- (void)testDecimalDictionary {
    [self roundTripWithPropertyGetter:^RLMDictionary *(RLMDictionarySyncObject *obj) { return obj.decimalDictionary; }
                               values:@{@"0": [[RLMDecimal128 alloc] initWithNumber:@123.456],
                                        @"1": [[RLMDecimal128 alloc] initWithNumber:@223.456],
                                        @"2": [[RLMDecimal128 alloc] initWithNumber:@323.456],
                                        @"3": [[RLMDecimal128 alloc] initWithNumber:@423.456],
                                        @"4": [[RLMDecimal128 alloc] initWithNumber:@523.456]}
                             isObject:NO
                           callerName:NSStringFromSelector(_cmd)];
}

- (void)testUUIDDictionary {
    [self roundTripWithPropertyGetter:^RLMDictionary *(RLMDictionarySyncObject *obj) { return obj.uuidDictionary; }
                               values:@{@"0": [[NSUUID alloc] initWithUUIDString:@"6b28ec45-b29a-4b0a-bd6a-343c7f6d90fd"],
                                        @"1": [[NSUUID alloc] initWithUUIDString:@"6b28ec45-b29a-4b0a-bd6a-343c7f6d90fe"],
                                        @"2": [[NSUUID alloc] initWithUUIDString:@"6b28ec45-b29a-4b0a-bd6a-343c7f6d90ff"],
                                        @"3": [[NSUUID alloc] initWithUUIDString:@"6b28ec45-b29a-4b0a-bd6a-343c7f6d90ae"],
                                        @"4": [[NSUUID alloc] initWithUUIDString:@"6b28ec45-b29a-4b0a-bd6a-343c7f6d90bf"]}
                             isObject:NO
                           callerName:NSStringFromSelector(_cmd)];
}

- (void)testObjectDictionary {
    [self roundTripWithPropertyGetter:^RLMDictionary *(RLMDictionarySyncObject *obj) { return obj.objectDictionary; }
                               values:@{@"0": [Person john],
                                        @"1": [Person paul],
                                        @"2": [Person ringo],
                                        @"3": [Person george],
                                        @"4": [Person stuart]}
                             isObject:YES
                           callerName:NSStringFromSelector(_cmd)];
}

- (void)testAnyDictionary {
    [self roundTripWithPropertyGetter:^RLMDictionary *(RLMDictionarySyncObject *obj) { return obj.anyDictionary; }
                               values:@{@"0": @123,
                                        @"1": @"Hey",
                                        @"2": NSNull.null,
                                        @"3": [[NSUUID alloc] initWithUUIDString:@"6b28ec45-b29a-4b0a-bd6a-343c7f6d90fd"],
                                        @"4": [[RLMObjectId alloc] initWithString:@"6058f12682b2fbb1f334ef1d" error:nil]}
                             isObject:NO
                           callerName:NSStringFromSelector(_cmd)];
}
@end

#endif // TARGET_OS_OSX
