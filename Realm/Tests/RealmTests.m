////////////////////////////////////////////////////////////////////////////
//
// TIGHTDB CONFIDENTIAL
// __________________
//
//  [2011] - [2014] TightDB Inc
//  All Rights Reserved.
//
// NOTICE:  All information contained herein is, and remains
// the property of TightDB Incorporated and its suppliers,
// if any.  The intellectual and technical concepts contained
// herein are proprietary to TightDB Incorporated
// and its suppliers and may be covered by U.S. and Foreign Patents,
// patents in process, and are protected by trade secret or copyright law.
// Dissemination of this information or reproduction of this material
// is strictly forbidden unless prior written permission is obtained
// from TightDB Incorporated.
//
////////////////////////////////////////////////////////////////////////////

#import "RLMTestCase.h"
#import "RLMTestObjects.h"
#import "XCTestCase+AsyncTesting.h"

@interface RealmTests : RLMTestCase
@end

@implementation RealmTests

#pragma mark - Tests

- (void)testRealmExists {
    RLMRealm *realm = [self realmWithTestPath];
    XCTAssertNotNil(realm, @"realm should not be nil");
    XCTAssertEqual([realm class], [RLMRealm class], @"realm should be of class RLMRealm");
}

- (void)testRealmAddAndRemoveObjects {
    RLMRealm *realm = [self realmWithTestPath];
    [realm beginWriteTransaction];
    [RLMTestObject createInRealm:realm withObject:@[@"a"]];
    [RLMTestObject createInRealm:realm withObject:@[@"b"]];
    [RLMTestObject createInRealm:realm withObject:@[@"c"]];
    XCTAssertEqual([realm objects:[RLMTestObject className] where:nil].count, (NSUInteger)3, @"Expecting 3 objects");
    [realm commitWriteTransaction];
    
    // test again after write transaction
    RLMArray *objects = [realm allObjects:RLMTestObject.className];
    XCTAssertEqual(objects.count, (NSUInteger)3, @"Expecting 3 objects");
    XCTAssertEqualObjects([objects.firstObject column], @"a", @"Expecting column to be 'a'");

    [realm beginWriteTransaction];
    [realm deleteObject:objects[2]];
    [realm deleteObject:objects[0]];
    XCTAssertEqual([realm objects:[RLMTestObject className] where:nil].count, (NSUInteger)1, @"Expecting 1 object");
    [realm commitWriteTransaction];
    
    objects = [realm allObjects:[RLMTestObject className]];
    XCTAssertEqual(objects.count, (NSUInteger)1, @"Expecting 1 object");
    XCTAssertEqualObjects([objects.firstObject column], @"b", @"Expecting column to be 'b'");
}

- (void)testRealmIsUpdatedAfterBackgroundUpdate {
    __block RLMNotificationToken *token = nil;
    [self testBefore:^(RLMRealm *realm) {
        token = [realm addNotificationBlock:^(__unused NSString *note, RLMRealm * realm) {
            XCTAssertNotNil(realm, @"Realm should not be nil");
            [self notify:XCTAsyncTestCaseStatusSucceeded];
        }];
    } async:^(RLMRealm *realm) {
        [realm beginWriteTransaction];
        [RLMTestObject createInRealm:realm withObject:@[@"string"]];
        [realm commitWriteTransaction];
    } completion:^(RLMRealm *realm) {
        [realm removeNotification:token];
    }];
}

- (void)testRealmIsUpdatedImmediatelyAfterBackgroundUpdate {
    __block RLMNotificationToken *token = nil;
    [self testBefore:^(RLMRealm *realm) {
         token = [realm addNotificationBlock:^(__unused NSString *note, RLMRealm * realm) {
            XCTAssertNotNil(realm, @"Realm should not be nil");
            [self notify:XCTAsyncTestCaseStatusSucceeded];
        }];
    } async:^(RLMRealm *realm) {
        RLMTestObject *obj = [[RLMTestObject alloc] init];
        obj.column = @"string";
        [realm beginWriteTransaction];
        [realm addObject:obj];
        [realm commitWriteTransaction];
    } completion:^(RLMRealm *realm) {
        [realm removeNotification:token];
        
        // get object
        RLMArray *objects = [realm objects:RLMTestObject.className where:nil];
        XCTAssertTrue(objects.count == 1, @"There should be 1 object of type RLMTestObject");
        XCTAssertEqualObjects([objects[0] column], @"string", @"Value of first column should be 'string'");
    }];
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

@end
