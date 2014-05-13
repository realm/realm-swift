//
//  realm.mm
//  TightDB
//
//  Run tests on RLMRealm
//

#import "RLMTestCase.h"
#import "XCTestCase+AsyncTesting.h"

@interface RLMTestObject : RLMObject
@property (nonatomic, copy) NSString *column;
@end

@implementation RLMTestObject
@end

@interface RLMRealmTests : RLMTestCase
@end

@implementation RLMRealmTests

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
    XCTAssertEqual([realm objects:RLMTestObject.class where:nil].count, 3, @"Expecting 3 objects");
    [realm commitWriteTransaction];
    
    // test again after write transaction
    RLMArray *objects = [realm objects:RLMTestObject.class where:nil];
    XCTAssertEqual(objects.count, 3, @"Expecting 3 objects");
    
    [realm beginWriteTransaction];
    [realm deleteObject:objects[0] cascade:NO];
    [realm deleteObject:objects[1] cascade:NO];
    XCTAssertEqual([realm objects:RLMTestObject.class where:nil].count, 1, @"Expecting 1 object");
    [realm commitWriteTransaction];
    
    objects = [realm objects:RLMTestObject.class where:nil];
    XCTAssertEqual(objects.count, 1, @"Expecting 1 object");
    XCTAssertEqualObjects([objects.firstObject column], @"b", @"Expecting column to be 'b'");
}

- (void)testRealmIsUpdatedAfterBackgroundUpdate {
    NSString *realmFilePath = RLMRealmPathForFile(@"async.bg.realm");
    [[NSFileManager defaultManager] removeItemAtPath:realmFilePath error:nil];
    
    RLMRealm *realm = [RLMRealm realmWithPath:realmFilePath];
    __block BOOL notificationFired = NO;
    [realm addNotificationBlock:^(NSString *note, RLMRealm * realm) {
        XCTAssertNotNil(realm, @"Realm should not be nil");
        notificationFired = YES;
        [self notify:XCTAsyncTestCaseStatusSucceeded];
    }];
    
    dispatch_queue_t queue = dispatch_queue_create("background", 0);
    dispatch_async(queue, ^{
        RLMRealm *realm = [RLMRealm realmWithPath:realmFilePath];
        [realm beginWriteTransaction];
        [RLMTestObject createInRealm:realm withObject:@[@"string"]];
        [realm commitWriteTransaction];
    });
    
    [self waitForStatus:XCTAsyncTestCaseStatusSucceeded timeout:2.0f];
    
    XCTAssertTrue(notificationFired, @"A notification should have fired after a table was created");
}

- (void)testRealmIsUpdatedImmediatelyAfterBackgroundUpdate {
    NSString *realmFilePath = RLMRealmPathForFile(@"async.bg.fast.realm");
    [[NSFileManager defaultManager] removeItemAtPath:realmFilePath error:nil];
    
    RLMRealm *realm = [RLMRealm realmWithPath:realmFilePath];
    __block BOOL notificationFired = NO;
    [realm addNotificationBlock:^(NSString *note, RLMRealm * realm) {
        XCTAssertNotNil(realm, @"Realm should not be nil");
        notificationFired = YES;
        [self notify:XCTAsyncTestCaseStatusSucceeded];
    }];
    
    dispatch_queue_t queue = dispatch_queue_create("background", 0);
    dispatch_async(queue, ^{
        RLMRealm *realm = [RLMRealm realmWithPath:realmFilePath];
        RLMTestObject *obj = [[RLMTestObject alloc] init];
        obj.column = @"string";
        [realm beginWriteTransaction];
        [realm addObject:obj];
        [realm commitWriteTransaction];
    });
    
    // this should complete very fast before the timer
    [self waitForStatus:XCTAsyncTestCaseStatusSucceeded timeout:0.0001f];
    
    XCTAssertTrue(notificationFired, @"A notification should have fired immediately a table was created in the background");
    
    // get object
    RLMArray *objects = [realm objects:RLMTestObject.class where:nil];
    XCTAssertTrue(objects.count == 1, @"There should be 1 object of type RLMTestObject");
    XCTAssertEqualObjects([objects[0] column], @"string", @"Value of first column should be 'string'");
}

/* FIXME: disabled until we have per file compile options
 - (void)testRealmWriteImplicitCommit
 {
 RLMRealm * realm = [self realmWithTestPath];
 [realm beginWriteTransaction];
 RLMTable *table = [realm createTableWithName:@"table"];
 [table addColumnWithName:@"col0" type:RLMTypeInt];
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
