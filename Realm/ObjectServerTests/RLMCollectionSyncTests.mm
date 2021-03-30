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

- (void)roundTripWithKeyPath:(NSString *)keyPath
                      values:(NSArray *)values
                otherKeyPath:(NSString *)otherKeyPath
                 otherValues:(NSArray *)otherValues
                    isObject:(BOOL)isObject
                  callerName:(NSString *)callerName {
    try {
        RLMUser *user = [self logInUserForCredentials:[self basicCredentialsWithName:callerName
                                                                            register:self.isParent]];
        RLMRealm *realm = [self openRealmForPartitionValue:callerName user:user];

        if (self.isParent) {
            [self waitForDownloadsForRealm:realm];
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

            XCTAssertEqual(((RLMSet *)obj[keyPath]).count, values.count);
            XCTAssertEqual(((RLMSet *)obj[otherKeyPath]).count, otherValues.count);
            // Run the child again to intersect the values
            RLMRunChildAndWait();
            [self waitForDownloadsForRealm:realm];
            CHECK_COUNT(1, RLMSetSyncObject, realm);

            if (!isObject) {
                XCTAssertTrue([((RLMSet *)obj[keyPath]) intersectsSet:((RLMSet *)obj[otherKeyPath])]);
                XCTAssertEqual(((RLMSet *)obj[keyPath]).count, 1U);
            }
            // Run the child again to delete the objects in the sets.
            RLMRunChildAndWait();
            [self waitForDownloadsForRealm:realm];
            XCTAssertEqual(((RLMSet *)obj[keyPath]).count, 0U);
            XCTAssertEqual(((RLMSet *)obj[otherKeyPath]).count, 0U);
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
                if (((RLMSet *)obj[keyPath]).count == 0) {
                    [realm transactionWithBlock:^{
                        [((RLMSet *)obj[keyPath]) addObjects:values];
                        [((RLMSet *)obj[otherKeyPath]) addObjects:otherValues];
                    }];
                } else if (((RLMSet *)obj[keyPath]).count == 3
                           && ((RLMSet *)obj[otherKeyPath]).count == 3) {
                    if (isObject) {
                        [realm transactionWithBlock:^{
                            [((RLMSet *)obj[keyPath]) removeAllObjects];
                            [((RLMSet *)obj[keyPath]) addObject:values[0]];
                        }];
                    } else {
                        [realm transactionWithBlock:^{
                            [((RLMSet *)obj[keyPath]) intersectSet:((RLMSet *)obj[otherKeyPath])];
                        }];
                    }
                    XCTAssertEqual(((RLMSet *)obj[keyPath]).count, 1U);
                    XCTAssertEqual(((RLMSet *)obj[otherKeyPath]).count, otherValues.count);
                } else {
                    [realm transactionWithBlock:^{
                        [((RLMSet *)obj[keyPath]) removeAllObjects];
                        [((RLMSet *)obj[otherKeyPath]) removeAllObjects];
                    }];
                    XCTAssertEqual(((RLMSet *)obj[keyPath]).count, 0U);
                    XCTAssertEqual(((RLMSet *)obj[otherKeyPath]).count, 0U);
                }
            } else {
                [realm transactionWithBlock:^{
                    [realm addObject:[RLMSetSyncObject new]];
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
    [self roundTripWithKeyPath:@"intSet"
                        values:@[@123, @234, @345]
                  otherKeyPath:@"otherIntSet"
                   otherValues:@[@345, @567, @789]
                      isObject:NO
                    callerName:NSStringFromSelector(_cmd)];
}

- (void)testStringSet {
    [self roundTripWithKeyPath:@"stringSet"
                        values:@[@"Who", @"What", @"When"]
                  otherKeyPath:@"otherStringSet"
                   otherValues:@[@"When", @"Strings", @"Collide"]
                      isObject:NO
                    callerName:NSStringFromSelector(_cmd)];
}

- (void)testDataSet {
    NSData* (^createData)(size_t) = ^(size_t size) {
        NSMutableData* data = [NSMutableData dataWithCapacity:size];
        for( unsigned int i = 0 ; i < size/4 ; ++i )
        {
            u_int64_t randomBits = arc4random();
            [data appendBytes:(void*)&randomBits length:4];
        }
        return data;
    };

    NSData *duplicateData = createData(1024U);
    [self roundTripWithKeyPath:@"dataSet"
                        values:@[duplicateData, createData(1024U), createData(1024U)]
                  otherKeyPath:@"otherDataSet"
                   otherValues:@[duplicateData, createData(1024U), createData(1024U)]
                      isObject:NO
                    callerName:NSStringFromSelector(_cmd)];
}

- (void)testDoubleSet {
    [self roundTripWithKeyPath:@"doubleSet"
                        values:@[@123.456, @234.456, @345.567]
                  otherKeyPath:@"otherDoubleSet"
                   otherValues:@[@123.456, @434.456, @545.567]
                      isObject:NO
                    callerName:NSStringFromSelector(_cmd)];
}

- (void)testObjectIdSet {
    [self roundTripWithKeyPath:@"objectIdSet"
                        values:@[[[RLMObjectId alloc] initWithString:@"6058f12b957ba06156586a7c" error:nil],
                                 [[RLMObjectId alloc] initWithString:@"6058f12682b2fbb1f334ef1d" error:nil],
                                 [[RLMObjectId alloc] initWithString:@"6058f12d42e5a393e67538d0" error:nil]]
                  otherKeyPath:@"otherObjectIdSet"
                   otherValues:@[[[RLMObjectId alloc] initWithString:@"6058f12b957ba06156586a7c" error:nil],
                                 [[RLMObjectId alloc] initWithString:@"6058f12682b2fbb1f334ef1e" error:nil],
                                 [[RLMObjectId alloc] initWithString:@"6058f12d42e5a393e67538df" error:nil]]
                      isObject:NO
                    callerName:NSStringFromSelector(_cmd)];
}

- (void)testDecimalSet {
    [self roundTripWithKeyPath:@"decimalSet"
                        values:@[[[RLMDecimal128 alloc] initWithNumber:@123.456],
                                 [[RLMDecimal128 alloc] initWithNumber:@223.456],
                                 [[RLMDecimal128 alloc] initWithNumber:@323.456]]
                  otherKeyPath:@"otherDecimalSet"
                   otherValues:@[[[RLMDecimal128 alloc] initWithNumber:@123.456],
                                 [[RLMDecimal128 alloc] initWithNumber:@423.456],
                                 [[RLMDecimal128 alloc] initWithNumber:@523.456]]
                      isObject:NO
                    callerName:NSStringFromSelector(_cmd)];
}

- (void)testUUIDSet {
    [self roundTripWithKeyPath:@"uuidSet"
                        values:@[[[NSUUID alloc] initWithUUIDString:@"6b28ec45-b29a-4b0a-bd6a-343c7f6d90fd"],
                                 [[NSUUID alloc] initWithUUIDString:@"6b28ec45-b29a-4b0a-bd6a-343c7f6d90fe"],
                                 [[NSUUID alloc] initWithUUIDString:@"6b28ec45-b29a-4b0a-bd6a-343c7f6d90ff"]]
                  otherKeyPath:@"otherUuidSet"
                   otherValues:@[[[NSUUID alloc] initWithUUIDString:@"6b28ec45-b29a-4b0a-bd6a-343c7f6d90fd"],
                                 [[NSUUID alloc] initWithUUIDString:@"6b28ec45-b29a-4b0a-bd6a-343c7f6d90ae"],
                                 [[NSUUID alloc] initWithUUIDString:@"6b28ec45-b29a-4b0a-bd6a-343c7f6d90bf"]]
                      isObject:NO
                    callerName:NSStringFromSelector(_cmd)];
}

- (void)testObjectSet {
    [self roundTripWithKeyPath:@"objectSet"
                        values:@[[Person john], [Person paul], [Person ringo]]
                  otherKeyPath:@"otherObjectSet"
                   otherValues:@[[Person john], [Person paul], [Person ringo]]
                      isObject:YES
                    callerName:NSStringFromSelector(_cmd)];
}

@end

#pragma mark RLMArray Sync Tests

@interface RLMArrayObjectServerTests : RLMSyncTestCase
@end

@implementation RLMArrayObjectServerTests

- (void)roundTripWithKeyPath:(NSString *)keyPath
                      values:(NSArray *)values
                    isObject:(BOOL)isObject
                  callerName:(NSString *)callerName {
    try {
        RLMUser *user = [self logInUserForCredentials:[self basicCredentialsWithName:callerName
                                                                            register:self.isParent]];
        RLMRealm *realm = [self openRealmForPartitionValue:callerName user:user];

        if (self.isParent) {
            [self waitForDownloadsForRealm:realm];
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
            XCTAssertEqual(((RLMArray *)obj[keyPath]).count, values.count*2);
            for (int i = 0; i < values.count; i++) {
                if (isObject) {
                    XCTAssertTrue([((Person *)results[0][keyPath][i]).firstName
                                   isEqual:((Person *)values[i]).firstName]);
                } else {
                    XCTAssertTrue([results[0][keyPath][i] isEqual:values[i]]);
                }
            }
            // Run the child again to delete the last 3 objects
            RLMRunChildAndWait();
            [self waitForDownloadsForRealm:realm];
            XCTAssertEqual(((RLMArray *)obj[keyPath]).count, values.count);
            // Run the child again to modify the first element
            RLMRunChildAndWait();
            [self waitForDownloadsForRealm:realm];
            if (isObject) {
                XCTAssertTrue([((Person *)((RLMArray *)obj[keyPath])[0]).firstName
                               isEqual:((Person *)values[1]).firstName]);
            } else {
                XCTAssertTrue([((RLMArray *)obj[keyPath])[0] isEqual:values[1]]);
            }
        } else {
            RLMResults<RLMArraySyncObject *> *results
                = [RLMArraySyncObject allObjectsInRealm:realm];
            if (RLMArraySyncObject *obj = results.firstObject) {
                if (((RLMArray *)obj[keyPath]).count == 0) {
                    [realm transactionWithBlock:^{
                        [((RLMArray *)obj[keyPath]) addObjects:values];
                        [((RLMArray *)obj[keyPath]) addObjects:values];
                    }];
                } else if (((RLMArray *)obj[keyPath]).count == 6) {
                    [realm transactionWithBlock:^{
                        [((RLMArray *)obj[keyPath]) removeLastObject];
                        [((RLMArray *)obj[keyPath]) removeLastObject];
                        [((RLMArray *)obj[keyPath]) removeLastObject];
                    }];
                    XCTAssertEqual(((RLMArray *)obj[keyPath]).count, values.count);
                } else {
                    [realm transactionWithBlock:^{
                        [((RLMArray *)obj[keyPath]) replaceObjectAtIndex:0
                                                              withObject:values[1]];
                    }];
                    XCTAssertTrue([((RLMArray *)obj[keyPath]).firstObject isEqual:values[1]]);
                }
            } else {
                [realm transactionWithBlock:^{
                    [realm addObject:[RLMArraySyncObject new]];
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
    [self roundTripWithKeyPath:@"intArray"
                        values:@[@123, @234, @345]
                      isObject:NO
                    callerName:NSStringFromSelector(_cmd)];
}

- (void)testBoolArray {
    [self roundTripWithKeyPath:@"boolArray"
                        values:@[@YES, @NO, @YES]
                      isObject:NO
                    callerName:NSStringFromSelector(_cmd)];
}

- (void)testStringArray {
    [self roundTripWithKeyPath:@"stringArray"
                        values:@[@"Hello...", @"It's", @"Me"]
                      isObject:NO
                    callerName:NSStringFromSelector(_cmd)];
}

- (void)testDataArray {
    [self roundTripWithKeyPath:@"dataArray"
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
    [self roundTripWithKeyPath:@"doubleArray"
                        values:@[@123.456, @789.456, @987.344]
                      isObject:NO
                    callerName:NSStringFromSelector(_cmd)];
}

- (void)testObjectIdArray {
    [self roundTripWithKeyPath:@"objectIdArray"
                        values:@[[[RLMObjectId alloc] initWithString:@"6058f12b957ba06156586a7c" error:nil],
                                 [[RLMObjectId alloc] initWithString:@"6058f12682b2fbb1f334ef1d" error:nil],
                                 [[RLMObjectId alloc] initWithString:@"6058f12d42e5a393e67538d0" error:nil]]
                      isObject:NO
                    callerName:NSStringFromSelector(_cmd)];
}

- (void)testDecimalArray {
    [self roundTripWithKeyPath:@"decimalArray"
                        values:@[[[RLMDecimal128 alloc] initWithNumber:@123.456],
                                 [[RLMDecimal128 alloc] initWithNumber:@456.456],
                                 [[RLMDecimal128 alloc] initWithNumber:@789.456]]
                      isObject:NO
                    callerName:NSStringFromSelector(_cmd)];
}

- (void)testUUIDArray {
    [self roundTripWithKeyPath:@"uuidArray"
                        values:@[[[NSUUID alloc] initWithUUIDString:@"6b28ec45-b29a-4b0a-bd6a-343c7f6d90fd"],
                                 [[NSUUID alloc] initWithUUIDString:@"6b28ec45-b29a-4b0a-bd6a-343c7f6d90fe"],
                                 [[NSUUID alloc] initWithUUIDString:@"6b28ec45-b29a-4b0a-bd6a-343c7f6d90ff"]]
                      isObject:NO
                    callerName:NSStringFromSelector(_cmd)];
}

- (void)testObjectArray {
    [self roundTripWithKeyPath:@"objectArray"
                        values:@[[Person john], [Person paul], [Person ringo]]
                      isObject:YES
                    callerName:NSStringFromSelector(_cmd)];
}

@end

#endif // TARGET_OS_OSX
