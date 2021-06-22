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
    try {
        RLMUser *user = [self logInUserForCredentials:[self basicCredentialsWithName:callerName
                                                                            register:self.isParent]];
        RLMRealm *realm = [self openRealmForPartitionValue:callerName user:user];
        if (self.isParent) {
            // Add a RLMSetSyncObject to the Realm
            CHECK_COUNT(0, RLMSetSyncObject, realm);
            RLMRunChildAndWait();
            [self waitForDownloadsForRealm:realm];
            CHECK_COUNT(1, RLMSetSyncObject, realm);
            // Run the child again to add the values
            RLMRunChildAndWait();
            [self waitForDownloadsForRealm:realm];
            CHECK_COUNT(1, RLMSetSyncObject, realm);
            RLMResults<RLMSetSyncObject *> *results
                = [RLMSetSyncObject allObjectsInRealm:realm];
            RLMSetSyncObject *obj = results.firstObject;

            XCTAssertEqual(propertyGetter(obj).count, values.count);
            XCTAssertEqual(otherPropertyGetter(obj).count, otherValues.count);
            // Run the child again to intersect the values
            RLMRunChildAndWait();
            [self waitForDownloadsForRealm:realm];
            CHECK_COUNT(1, RLMSetSyncObject, realm);

            if (!isObject) {
                XCTAssertTrue([propertyGetter(obj) intersectsSet:propertyGetter(obj)]);
                XCTAssertEqual(propertyGetter(obj).count, 1U);
            }
            // Run the child again to delete the objects in the sets.
            RLMRunChildAndWait();
            [self waitForDownloadsForRealm:realm];
            XCTAssertEqual(propertyGetter(obj).count, 0U);
            XCTAssertEqual(otherPropertyGetter(obj).count, 0U);
            XCTestExpectation *expectation = [self expectationWithDescription:@"should remove user"];
            [user removeWithCompletion:^(NSError *e){
                XCTAssertNil(e);
                [expectation fulfill];
            }];
            [self waitForExpectationsWithTimeout:30.0 handler:nil];
        } else {
            RLMResults<RLMSetSyncObject *> *results
                = [RLMSetSyncObject allObjectsInRealm:realm];
            if (RLMSetSyncObject *obj = results.firstObject) {
                CHECK_COUNT(1, RLMSetSyncObject, realm);
                if (propertyGetter(obj).count == 0 && otherPropertyGetter(obj).count == 0) {
                    [realm transactionWithBlock:^{
                        [propertyGetter(obj) addObjects:values];
                        [otherPropertyGetter(obj) addObjects:otherValues];
                    }];
                } else if (propertyGetter(obj).count == 3
                           && otherPropertyGetter(obj).count == 3) {
                    if (isObject) {
                        [realm transactionWithBlock:^{
                            [propertyGetter(obj) removeAllObjects];
                            [propertyGetter(obj) addObject:values[0]];
                        }];
                    } else {
                        [realm transactionWithBlock:^{
                            [propertyGetter(obj) intersectSet:otherPropertyGetter(obj)];
                        }];
                    }
                    XCTAssertEqual(propertyGetter(obj).count, 1U);
                    XCTAssertEqual(otherPropertyGetter(obj).count, otherValues.count);
                } else {
                    [realm transactionWithBlock:^{
                        [propertyGetter(obj) removeAllObjects];
                        [otherPropertyGetter(obj) removeAllObjects];
                    }];
                    XCTAssertEqual(propertyGetter(obj).count, 0U);
                    XCTAssertEqual(otherPropertyGetter(obj).count, 0U);
                }
            } else {
                [realm transactionWithBlock:^{
                    [RLMSetSyncObject createInRealm:realm
                                          withValue:@{@"_id": [RLMObjectId objectId]}];
                }];
            }
            [self waitForUploadsForRealm:realm];
            CHECK_COUNT(1, RLMSetSyncObject, realm);
        }
    } catch(NSException *e) {
        XCTFail(@"Got an error: %@ (isParent: %d)",
                e, self.isParent);
    }
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
    try {
        RLMUser *user = [self logInUserForCredentials:[self basicCredentialsWithName:callerName
                                                                            register:self.isParent]];
        RLMRealm *realm = [self openRealmForPartitionValue:callerName user:user];
        if (self.isParent) {
            CHECK_COUNT(0, RLMArraySyncObject, realm);
            RLMRunChildAndWait();
            [self waitForDownloadsForRealm:realm];
            CHECK_COUNT(1, RLMArraySyncObject, realm);
            // Run the child again to add the values
            RLMRunChildAndWait();
            [self waitForDownloadsForRealm:realm];
            CHECK_COUNT(1, RLMArraySyncObject, realm);
            RLMResults<RLMArraySyncObject *> *results
                = [RLMArraySyncObject allObjectsInRealm:realm];
            RLMArraySyncObject *obj = results.firstObject;
            XCTAssertEqual(propertyGetter(obj).count, values.count*2);
            for (NSUInteger i = 0; i < values.count; i++) {
                if (isObject) {
                    XCTAssertTrue([((Person *)propertyGetter(results[0])[i]).firstName
                                   isEqual:((Person *)values[i]).firstName]);
                } else {
                    XCTAssertTrue([propertyGetter(results[0])[i] isEqual:values[i]]);
                }
            }
            // Run the child again to delete the last 3 objects
            RLMRunChildAndWait();
            [self waitForDownloadsForRealm:realm];
            XCTAssertEqual(propertyGetter(obj).count, values.count);
            // Run the child again to modify the first element
            RLMRunChildAndWait();
            [self waitForDownloadsForRealm:realm];
            if (isObject) {
                XCTAssertTrue([((Person *)propertyGetter(obj)[0]).firstName
                               isEqual:((Person *)values[1]).firstName]);
            } else {
                XCTAssertTrue([propertyGetter(obj)[0] isEqual:values[1]]);
            }
        } else {
            RLMResults<RLMArraySyncObject *> *results
                = [RLMArraySyncObject allObjectsInRealm:realm];
            if (RLMArraySyncObject *obj = results.firstObject) {
                if (propertyGetter(obj).count == 0) {
                    [realm transactionWithBlock:^{
                        [propertyGetter(obj) addObjects:values];
                        [propertyGetter(obj) addObjects:values];
                    }];
                } else if (propertyGetter(obj).count == 6) {
                    [realm transactionWithBlock:^{
                        [propertyGetter(obj) removeLastObject];
                        [propertyGetter(obj) removeLastObject];
                        [propertyGetter(obj) removeLastObject];
                    }];
                    XCTAssertEqual(propertyGetter(obj).count, values.count);
                } else {
                    [realm transactionWithBlock:^{
                        [propertyGetter(obj) replaceObjectAtIndex:0
                                                       withObject:values[1]];
                    }];
                    XCTAssertTrue([propertyGetter(obj).firstObject isEqual:values[1]]);
                }
            } else {
                [realm transactionWithBlock:^{
                    [RLMArraySyncObject createInRealm:realm
                                            withValue:@{@"_id": [RLMObjectId objectId]}];
                }];
            }
            [self waitForUploadsForRealm:realm];
            CHECK_COUNT(1, RLMArraySyncObject, realm);
        }
    } catch(NSException *e) {
        XCTFail(@"Got an error: %@ (isParent: %d)",
                e, self.isParent);
    }
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
    try {
        RLMUser *user = [self logInUserForCredentials:[self basicCredentialsWithName:callerName
                                                                            register:self.isParent]];
        RLMRealm *realm = [self openRealmForPartitionValue:callerName user:user];
        if (self.isParent) {
            // Add a RLMDictionarySyncObject to the Realm
            CHECK_COUNT(0, RLMDictionarySyncObject, realm);
            RLMRunChildAndWait();
            [self waitForDownloadsForRealm:realm];
            CHECK_COUNT(1, RLMDictionarySyncObject, realm);
            
            // Run the child again to add the values
            RLMRunChildAndWait();
            [self waitForDownloadsForRealm:realm];
            CHECK_COUNT(1, RLMDictionarySyncObject, realm);
            RLMResults<RLMDictionarySyncObject *> *results = [RLMDictionarySyncObject allObjectsInRealm:realm];
            RLMDictionarySyncObject *obj = results.firstObject;
            XCTAssertEqual(propertyGetter(obj).count, values.count);
            for (NSString *key in values) {
                if (isObject) {
                    XCTAssertTrue([((Person *)propertyGetter(obj)[key]).firstName
                                   isEqual:((Person *)values[key]).firstName]);
                } else {
                    XCTAssertTrue([propertyGetter(obj)[key] isEqual:values[key]]);
                }
            }

            // Run the child again to delete 3 objects
            RLMRunChildAndWait();
            [self waitForDownloadsForRealm:realm];
            CHECK_COUNT(1, RLMDictionarySyncObject, realm);
            XCTAssertEqual((int)propertyGetter(obj).count, 2);
            
            // Run the child again to modify the first element
            RLMRunChildAndWait();
            [self waitForDownloadsForRealm:realm];
            CHECK_COUNT(1, RLMDictionarySyncObject, realm);
            XCTAssertEqual((int)propertyGetter(obj).count, 2);
            id keyA = [propertyGetter(obj) allKeys][0];
            id keyB = [propertyGetter(obj) allKeys][1];
            if (isObject) {
                XCTAssertTrue([((Person *)propertyGetter(obj)[keyA]).firstName
                               isEqual:((Person *)propertyGetter(obj)[keyB]).firstName]);
            } else {
                XCTAssertTrue([propertyGetter(obj)[keyA] isEqual:propertyGetter(obj)[keyB]]);
            }
            XCTestExpectation *expectation = [self expectationWithDescription:@"should remove user"];
            [user removeWithCompletion:^(NSError *e){
                XCTAssertNil(e);
                [expectation fulfill];
            }];
            [self waitForExpectationsWithTimeout:30.0 handler:nil];
        } else {
            RLMResults<RLMDictionarySyncObject *> *results = [RLMDictionarySyncObject allObjectsInRealm:realm];
            if (RLMDictionarySyncObject *obj = results.firstObject) {
                CHECK_COUNT(1, RLMDictionarySyncObject, realm);
                if (propertyGetter(obj).count == 0) {
                    [realm transactionWithBlock:^{
                        for (NSString *key in values) {
                            propertyGetter(obj)[key] = values[key];
                        }
                    }];
                    XCTAssertEqual(propertyGetter(obj).count, values.count);
                } else if (propertyGetter(obj).count == 5) {
                    [realm transactionWithBlock:^{
                        int i = 0;
                        for (NSString *key in propertyGetter(obj)) {
                            propertyGetter(obj)[key] = nil;
                            if (++i >= 3) {
                                break;
                            }
                        }
                    }];
                    XCTAssertEqual(propertyGetter(obj).count, 2U);
                } else {
                    [realm transactionWithBlock:^{
                        id keyA = [propertyGetter(obj) allKeys][0];
                        id keyB = [propertyGetter(obj) allKeys][1];
                        propertyGetter(obj)[keyA] = propertyGetter(obj)[keyB];
                    }];
                    XCTAssertEqual(propertyGetter(obj).count, 2U);
                }
            } else {
                [realm transactionWithBlock:^{
                    [RLMDictionarySyncObject createInRealm:realm
                                                 withValue:@{@"_id": [RLMObjectId objectId]}];
                }];
            }
            [self waitForUploadsForRealm:realm];
            CHECK_COUNT(1, RLMDictionarySyncObject, realm);
        }
    } catch(NSException *e) {
        XCTFail(@"Got an error: %@ (isParent: %d)", e, self.isParent);
    }
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
