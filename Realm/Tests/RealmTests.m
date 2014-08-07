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

#import <libkern/OSAtomic.h>

@interface RLMRealm ()

+ (BOOL)isCoreDebug;

@end

@interface RealmTests : RLMTestCase
@end

@implementation RealmTests

#pragma mark - Tests

- (void)testCoreDebug {
#if DEBUG
    XCTAssertTrue([RLMRealm isCoreDebug], @"Debug version of Realm should use libtightdb{-ios}-dbg");
#else
    XCTAssertFalse([RLMRealm isCoreDebug], @"Release version of Realm should use libtightdb{-ios}");
#endif
}

- (void)testRealmExists {
    RLMRealm *realm = [self realmWithTestPath];
    XCTAssertNotNil(realm, @"realm should not be nil");
    XCTAssertEqual([realm class], [RLMRealm class], @"realm should be of class RLMRealm");
}

- (void)testRealmFailure
{
    XCTAssertThrows([RLMRealm realmWithPath:@"/dev/null"], @"Shouldn't exist");
}

- (void)testDefaultRealmPath
{
    XCTAssertEqualObjects([[RLMRealm defaultRealm] path], [RLMRealm defaultRealmPath], @"Default Realm path should be correct.");
}

- (void)testRealmPath
{
    RLMRealm *defaultRealm = [RLMRealm defaultRealm];
    XCTAssertEqualObjects(defaultRealm.path, RLMDefaultRealmPath(), @"Default path");
    RLMRealm *testRealm = [self realmWithTestPath];
    XCTAssertEqualObjects(testRealm.path, RLMTestRealmPath(), @"Test path");
}

- (void)testRealmAddAndRemoveObjects {
    RLMRealm *realm = [self realmWithTestPath];
    [realm beginWriteTransaction];
    [StringObject createInRealm:realm withObject:@[@"a"]];
    [StringObject createInRealm:realm withObject:@[@"b"]];
    [StringObject createInRealm:realm withObject:@[@"c"]];
    XCTAssertEqual([StringObject objectsInRealm:realm withPredicate:nil].count, (NSUInteger)3, @"Expecting 3 objects");
    [realm commitWriteTransaction];
    
    // test again after write transaction
    RLMArray *objects = [StringObject allObjectsInRealm:realm];
    XCTAssertEqual(objects.count, (NSUInteger)3, @"Expecting 3 objects");
    XCTAssertEqualObjects([objects.firstObject stringCol], @"a", @"Expecting column to be 'a'");

    [realm beginWriteTransaction];
    [realm deleteObject:objects[2]];
    [realm deleteObject:objects[0]];
    XCTAssertEqual([StringObject objectsInRealm:realm withPredicate:nil].count, (NSUInteger)1, @"Expecting 1 object");
    [realm commitWriteTransaction];
    
    objects = [StringObject allObjectsInRealm:realm];
    XCTAssertEqual(objects.count, (NSUInteger)1, @"Expecting 1 object");
    XCTAssertEqualObjects([objects.firstObject stringCol], @"b", @"Expecting column to be 'b'");
}

- (void)testRealmBatchRemoveObjects {
    RLMRealm *realm = [self realmWithTestPath];
    [realm beginWriteTransaction];
    StringObject *strObj = [StringObject createInRealm:realm withObject:@[@"a"]];
    [StringObject createInRealm:realm withObject:@[@"b"]];
    [StringObject createInRealm:realm withObject:@[@"c"]];
    [realm commitWriteTransaction];

    // delete objects
    RLMArray *objects = [StringObject allObjectsInRealm:realm];
    XCTAssertEqual(objects.count, (NSUInteger)3, @"Expecting 3 objects");
    [realm beginWriteTransaction];
    [realm deleteObjects:objects];
    XCTAssertEqual([[StringObject allObjectsInRealm:realm] count], (NSUInteger)0, @"Expecting 0 objects");
    [realm commitWriteTransaction];

    XCTAssertEqual([[StringObject allObjectsInRealm:realm] count], (NSUInteger)0, @"Expecting 0 objects");
    XCTAssertThrows(strObj.stringCol, @"Object should be invalidated");

    // add objects to linkView
    [realm beginWriteTransaction];
    ArrayPropertyObject *obj = [ArrayPropertyObject createInRealm:realm withObject:@[@"name", @[@[@"a"], @[@"b"], @[@"c"]], @[]]];
    [StringObject createInRealm:realm withObject:@[@"d"]];
    [realm commitWriteTransaction];

    XCTAssertEqual([[StringObject allObjectsInRealm:realm] count], (NSUInteger)4, @"Expecting 4 objects");

    // remove from linkView
    [realm beginWriteTransaction];
    [realm deleteObjects:obj.array];
    [realm commitWriteTransaction];

    XCTAssertEqual([[StringObject allObjectsInRealm:realm] count], (NSUInteger)1, @"Expecting 1 object");
    XCTAssertEqual(obj.array.count, (NSUInteger)0, @"Expecting 0 objects");
    
    // remove NSArray
    NSArray *arrayOfLastObject = @[[[StringObject allObjectsInRealm:realm] lastObject]];
    [realm beginWriteTransaction];
    [realm deleteObjects:arrayOfLastObject];
    [realm commitWriteTransaction];
    XCTAssertEqual(objects.count, (NSUInteger)0, @"Expecting 0 objects");
    
    // add objects to linkView
    [realm beginWriteTransaction];
    [obj.array addObject:[StringObject createInRealm:realm withObject:@[@"a"]]];
    [obj.array addObject:[[StringObject alloc] initWithObject:@[@"b"]]];
    [realm commitWriteTransaction];
    
    // remove objects from realm
    XCTAssertEqual(obj.array.count, (NSUInteger)2, @"Expecting 2 objects");
    [realm beginWriteTransaction];
    [realm deleteObjects:[StringObject allObjectsInRealm:realm]];
    [realm commitWriteTransaction];
    XCTAssertEqual(obj.array.count, (NSUInteger)0, @"Expecting 0 objects");
}

- (void)testRealmTransactionBlock {
    RLMRealm *realm = [self realmWithTestPath];
    [realm transactionWithBlock:^{
        [StringObject createInRealm:realm withObject:@[@"b"]];
    }];
    RLMArray *objects = [StringObject allObjectsInRealm:realm];
    XCTAssertEqual(objects.count, (NSUInteger)1, @"Expecting 1 object");
    XCTAssertEqualObjects([objects.firstObject stringCol], @"b", @"Expecting column to be 'b'");
}


- (void)testRealmIsUpdatedAfterBackgroundUpdate {
    RLMRealm *realm = [self realmWithTestPath];

    // we have two notifications, one for opening the realm, and a second when performing our transaction
    __block NSUInteger noteCount = 0;
    XCTestExpectation *notificationFired = [self expectationWithDescription:@"notification fired"];
    RLMNotificationToken *token = [realm addNotificationBlock:^(__unused NSString *note, RLMRealm * realm) {
        XCTAssertNotNil(realm, @"Realm should not be nil");
        if (++noteCount == 2) {
            [notificationFired fulfill];
        }
    }];
    
    dispatch_queue_t queue = dispatch_queue_create("background", 0);
    dispatch_async(queue, ^{
        RLMRealm *realm = [self realmWithTestPath];
        [realm beginWriteTransaction];
        [StringObject createInRealm:realm withObject:@[@"string"]];
        [realm commitWriteTransaction];
    });
    
    [self waitForExpectationsWithTimeout:2.0 handler:nil];
    [realm removeNotification:token];

    // get object
    RLMArray *objects = [StringObject objectsInRealm:realm withPredicate:nil];
    XCTAssertTrue(objects.count == 1, @"There should be 1 object of type StringObject");
    XCTAssertEqualObjects([objects[0] stringCol], @"string", @"Value of first column should be 'string'");
}

// FIXME: Re-enable once we find out why this fails intermittently on iOS in Xcode6
// Asana: https://app.asana.com/0/861870036984/14552787865017
#ifndef REALM_SWIFT
- (void)testRealmIsUpdatedImmediatelyAfterBackgroundUpdate {
    RLMRealm *realm = [self realmWithTestPath];

    // we have two notifications, one for opening the realm, and a second when performing our transaction
    __block NSUInteger noteCount = 0;
    XCTestExpectation *notificationFired = [self expectationWithDescription:@"notification fired"];
    RLMNotificationToken *token = [realm addNotificationBlock:^(__unused NSString *note, RLMRealm * realm) {
        XCTAssertNotNil(realm, @"Realm should not be nil");
        if (++noteCount == 2) {
            [notificationFired fulfill];
        }
     }];
    
    dispatch_queue_t queue = dispatch_queue_create("background", 0);
    dispatch_async(queue, ^{
        RLMRealm *realm = [self realmWithTestPath];
        StringObject *obj = [[StringObject alloc] initWithObject:@[@"string"]];
        [realm beginWriteTransaction];
        [realm addObject:obj];
        [realm commitWriteTransaction];

        RLMArray *objects = [StringObject objectsInRealm:realm withPredicate:nil];
        XCTAssertTrue(objects.count == 1, @"There should be 1 object of type StringObject");
        XCTAssertEqualObjects([objects[0] stringCol], @"string", @"Value of first column should be 'string'");
    });
    
    // this should complete very fast before the timer
    [self waitForExpectationsWithTimeout:0.01 handler:nil];
    [realm removeNotification:token];
        
    // get object
    RLMArray *objects = [StringObject objectsInRealm:realm withPredicate:nil];
    XCTAssertTrue(objects.count == 1, @"There should be 1 object of type StringObject");
    StringObject *obj = objects.firstObject;
    XCTAssertEqualObjects(obj.stringCol, @"string", @"Value of first column should be 'string'");
}
#endif


- (void)testAutoUpdate {
    RLMRealm *realm = [self realmWithTestPath];
    
    // turn autorefresh off
    realm.autorefresh = NO;
    
    // we have two notifications, one for opening the realm, and a second when performing our transaction
    __block NSUInteger noteCount = 0;
    __block XCTestExpectation *notificationFired = [self expectationWithDescription:@"notification fired"];
    RLMNotificationToken *token = [realm addNotificationBlock:^(__unused NSString *note, RLMRealm * realm) {
        XCTAssertNotNil(realm, @"Realm should not be nil");
        if (++noteCount == 2) {
            [notificationFired fulfill];
        }
    }];
    
    dispatch_queue_t queue = dispatch_queue_create("background", 0);
    dispatch_async(queue, ^{
        RLMRealm *realm = [self realmWithTestPath];
        [realm beginWriteTransaction];
        [StringObject createInRealm:realm withObject:@[@"string"]];
        [realm commitWriteTransaction];
    });
    
    [self waitForExpectationsWithTimeout:2.0 handler:nil];
    
    // should have only one object
    RLMArray *objects = [StringObject objectsInRealm:realm withPredicate:nil];
    XCTAssertEqual(objects.count, 0U, @"There should be 0 objects of type StringObject");
    
    // call refresh
    [realm refresh];
    objects = [StringObject objectsInRealm:realm withPredicate:nil];
    XCTAssertEqual(objects.count, 1U, @"There should be 1 objects of type StringObject");
    
    // reset count and create new expectation
    noteCount = 0;
    notificationFired = [self expectationWithDescription:@"notification fired"];
    
    // turn on autorefresh
    realm.autorefresh = YES;
    dispatch_async(queue, ^{
        RLMRealm *realm = [self realmWithTestPath];
        [realm beginWriteTransaction];
        [StringObject createInRealm:realm withObject:@[@"another string"]];
        [realm commitWriteTransaction];
    });
    
    [self waitForExpectationsWithTimeout:2.0 handler:nil];
    
    // refresh should have been called automatically
    objects = [StringObject objectsInRealm:realm withPredicate:nil];
    XCTAssertEqual(objects.count, 2U, @"There should be 2 objects of type StringObject");
    
    [realm removeNotification:token];
}


/* FIXME: disabled until we have per file compile options
 - (void)testRealmWriteImplicitCommit
 {
 RLMRealm * realm = [self realmWithTestPath];
 [realm beginWriteTransaction];
 RLMTable *table = [realm createTableWithName:@"table"];
 [table addColumnWithName:@"col0" type:RLMPropertyTypeInt];
 [realm commitWriteTransaction];
 
 @autoreleasepool {
 [realm beginWriteTransaction];
 [table addRow:@[@10]];
 
 // make sure we can see the new row on the write thread
 XCTAssertTrue([table rowCount] == 1, @"Rows were added");
 
 // make sure we can't see the new row in another thread
 dispatch_async(dispatch_get_global_queue(0, 0), ^{
 RLMRealm *bgrealm = [self realmWithTestPath];
 RLMTable *table = [bgrealm tableWithName:@"table"];
 XCTAssertTrue([table rowCount] == 0, @"Don't see the new row");
 [self notify:XCTAsyncTestCaseStatusSucceeded];
 });
 
 [self waitForStatus:XCTAsyncTestCaseStatusSucceeded timeout:2.0f];
 }
 
 // make sure implicit commit took place
 dispatch_async(dispatch_get_global_queue(0, 0), ^{
 RLMRealm *bgrealm = [self realmWithTestPath];
 RLMTable *table = [bgrealm tableWithName:@"table"];
 XCTAssertTrue([table rowCount] == 1, @"See the new row");
 [self notify:XCTAsyncTestCaseStatusSucceeded];
 });
 
 [self waitForStatus:XCTAsyncTestCaseStatusSucceeded timeout:2.0f];
 }
 */

- (void)testRealmInMemory
{
    RLMRealm *realmWithFile = [RLMRealm defaultRealm];
    [realmWithFile beginWriteTransaction];
    [StringObject createInRealm:realmWithFile withObject:@[@"a"]];
    [realmWithFile commitWriteTransaction];
    XCTAssertThrows([RLMRealm useInMemoryDefaultRealm], @"Realm instances already created");
}

- (void)testRealmInMemory2
{
    [RLMRealm useInMemoryDefaultRealm];
    
    RLMRealm *realmInMemory = [RLMRealm defaultRealm];
    [realmInMemory beginWriteTransaction];
    [StringObject createInRealm:realmInMemory withObject:@[@"a"]];
    [StringObject createInRealm:realmInMemory withObject:@[@"b"]];
    [StringObject createInRealm:realmInMemory withObject:@[@"c"]];
    XCTAssertEqual([StringObject objectsInRealm:realmInMemory withPredicate:nil].count, (NSUInteger)3, @"Expecting 3 objects");
    [realmInMemory commitWriteTransaction];
}

- (void)testRealmFileAccess
{
    XCTAssertThrows([RLMRealm realmWithPath:nil], @"nil path");
    XCTAssertThrows([RLMRealm realmWithPath:@""], @"empty path");    
    
    NSString *content = @"Some content";
    NSData *fileContents = [content dataUsingEncoding:NSUTF8StringEncoding];
    NSString *filePath = RLMRealmPathForFile(@"filename.realm");
    [[NSFileManager defaultManager] createFileAtPath:filePath contents:fileContents attributes:nil];
    
    NSError *error;
    XCTAssertNil([RLMRealm realmWithPath:filePath readOnly:NO error:&error], @"Invalid database");
    XCTAssertNotNil(error, @"Should populate error object");
}

- (void)testCrossThreadAccess
{
    RLMRealm *realm = RLMRealm.defaultRealm;

    // Using dispatch_async to ensure it actually lands on another thread
    __block OSSpinLock spinlock = OS_SPINLOCK_INIT;
    OSSpinLockLock(&spinlock);
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        XCTAssertThrows([realm beginWriteTransaction]);
        XCTAssertThrows([realm allObjects:@"IntObject"]);
        XCTAssertThrows([realm objects:@"IntObject" where:@"intCol = 0"]);
        OSSpinLockUnlock(&spinlock);
    });
    OSSpinLockLock(&spinlock);
}

@end
