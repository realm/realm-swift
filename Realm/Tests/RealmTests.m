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

-(void)testRealmFailure
{
    XCTAssertThrows([RLMRealm realmWithPath:@"/dev/null"], @"Shouldn't exist");

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
    XCTAssertEqual([realm objects:[StringObject className] withPredicate:nil].count, (NSUInteger)3, @"Expecting 3 objects");
    [realm commitWriteTransaction];
    
    // test again after write transaction
    RLMArray *objects = [realm allObjects:StringObject.className];
    XCTAssertEqual(objects.count, (NSUInteger)3, @"Expecting 3 objects");
    XCTAssertEqualObjects([objects.firstObject stringCol], @"a", @"Expecting column to be 'a'");

    [realm beginWriteTransaction];
    [realm deleteObject:objects[2]];
    [realm deleteObject:objects[0]];
    XCTAssertEqual([realm objects:[StringObject className] withPredicate:nil].count, (NSUInteger)1, @"Expecting 1 object");
    [realm commitWriteTransaction];
    
    objects = [realm allObjects:[StringObject className]];
    XCTAssertEqual(objects.count, (NSUInteger)1, @"Expecting 1 object");
    XCTAssertEqualObjects([objects.firstObject stringCol], @"b", @"Expecting column to be 'b'");
}


- (void)testRealmIsUpdatedAfterBackgroundUpdate {
    RLMRealm *realm = [self realmWithTestPath];

    XCTestExpectation *notificationFired = [self expectationWithDescription:@"notification fired"];
    RLMNotificationToken *token = [realm addNotificationBlock:^(__unused NSString *note, RLMRealm * realm) {
        XCTAssertNotNil(realm, @"Realm should not be nil");
        [notificationFired fulfill];
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
    RLMArray *objects = [realm objects:StringObject.className withPredicate:nil];
    XCTAssertTrue(objects.count == 1, @"There should be 1 object of type StringObject");
    XCTAssertEqualObjects([objects[0] stringCol], @"string", @"Value of first column should be 'string'");
}

- (void)testRealmIsUpdatedImmediatelyAfterBackgroundUpdate {
    RLMRealm *realm = [self realmWithTestPath];

    XCTestExpectation *notificationFired = [self expectationWithDescription:@"notification fired"];
    RLMNotificationToken *token = [realm addNotificationBlock:^(__unused NSString *note, RLMRealm * realm) {
        XCTAssertNotNil(realm, @"Realm should not be nil");
        [notificationFired fulfill];
     }];
    
    dispatch_queue_t queue = dispatch_queue_create("background", 0);
    dispatch_async(queue, ^{
        RLMRealm *realm = [self realmWithTestPath];
        [realm beginWriteTransaction];
        [StringObject createInRealm:realm withObject:@[@"string"]];
        [realm commitWriteTransaction];

        RLMArray *objects = [realm objects:StringObject.className withPredicate:nil];
        XCTAssertTrue(objects.count == 1, @"There should be 1 object of type StringObject");
        XCTAssertEqualObjects([objects[0] stringCol], @"string", @"Value of first column should be 'string'");
    });
    
    // this should complete very fast before the timer
    [self waitForExpectationsWithTimeout:2.0 handler:nil];
    [realm removeNotification:token];
        
    // get object
    RLMArray *objects = [realm objects:StringObject.className withPredicate:nil];
    XCTAssertTrue(objects.count == 1, @"There should be 1 object of type StringObject");
    StringObject *obj = objects.firstObject;
    XCTAssertEqualObjects(obj.stringCol, @"string", @"Value of first column should be 'string'");
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
    XCTAssertEqual([realmInMemory objects:[StringObject className] withPredicate:nil].count, (NSUInteger)3, @"Expecting 3 objects");
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

@end
