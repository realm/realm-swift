//
//  realm.mm
//  TightDB
//
//  Run tests on RLMRealm
//

#import "RLMTestCase.h"
#import <realm/objc/Realm.h>
#import "XCTestCase+AsyncTesting.h"

REALM_TABLE_1(RLMTestTable,
              column, String)

@interface RLMRealmTests : RLMTestCase

@end

@implementation RLMRealmTests

#pragma mark - Tests

- (void)testRealmExists {
    RLMRealm *realm = [self realmPersistedAtTestPath];
    XCTAssertNotNil(realm, @"realm should not be nil");
    XCTAssertEqual([realm class], [RLMRealm class], @"realm should be of class RLMRealm");
}

- (void)testCanReadPreviouslyCreatedTable {
    NSString *tableName = @"table";
    
    NSError *error = nil;
    
    [[self realmWithTestPath] writeUsingBlock:^(RLMRealm *realm) {
        [realm createTableWithName:tableName];
    }];
    
    XCTAssertNil(error, @"RLMRealm error should be nil after write block");
    
    RLMRealm *realm = [self realmPersistedAtTestPath];
    RLMTable *table = [realm tableWithName:tableName];
    
    XCTAssertNotNil(table, @"pre-existing table read from RLMRealm should not be nil");
    XCTAssertEqual([table class], [RLMTable class], @"pre-existing table read from \
                   RLMRealm should be of class RLMTable");
}

- (void)testCanReadPreviouslyCreatedTypedTable {
    NSString *tableName = @"table";
    
    [[self realmWithTestPath] writeUsingBlock:^(RLMRealm *realm) {
        [realm createTableWithName:tableName asTableClass:[RLMTestTable class]];
    }];
    
    RLMRealm *realm = [self realmPersistedAtTestPath];
    RLMTestTable *table = [realm tableWithName:tableName asTableClass:[RLMTestTable class]];
    
    XCTAssertNotNil(table, @"pre-existing typed table read from RLMRealm should not be nil");
    XCTAssertEqual([table class],
                   [RLMTestTable class],
                   @"pre-existing typed table read from RLMRealm should be of class RLMTestTable");
}

- (void)testTableCreatedAfterStandaloneRealmStarted {
    NSString *realmFilePath = @"async.realm";
    [[NSFileManager defaultManager] removeItemAtPath:realmFilePath error:nil];
    NSString *tableName = @"table";
    
    
    __block BOOL notificationFired = NO;
    __block RLMTable *table = nil;
    RLMRealm *realm = [RLMRealm realmWithPath:realmFilePath];
    [realm addNotification:^(NSString *note, RLMRealm * realm) {
        XCTAssertEqualObjects(note, RLMRealmDidChangeNotification, @"Notification type");
        notificationFired = YES;
        table = [realm tableWithName:tableName];
        [self notify:XCTAsyncTestCaseStatusSucceeded];
    }];
    
    [realm writeUsingBlock:^(RLMRealm *realm) {
        [realm createTableWithName:tableName];
    }];

    [self waitForTimeout:1.0f];
    
    XCTAssertTrue(notificationFired, @"A notification should have fired after a table was created");
    XCTAssertNotNil(table, @"The RLMRealm should be able to read a newly \
                    created table after a RLMRealmDidChangeNotification was sent");
    XCTAssertEqual([table class], [RLMTable class], @"a newly created table read from \
                   RLMRealm should be of class RLMTable");
}

- (void)testRealmIsUpdatedAfterBackgroundUpdate {
    NSString *realmFilePath = @"async.bg.realm";
    [[NSFileManager defaultManager] removeItemAtPath:realmFilePath error:nil];
    NSString *tableName = @"table";
    
    RLMRealm *realm = [RLMRealm realmWithPath:realmFilePath];
    __block BOOL notificationFired = NO;
    [realm addNotification:^(NSString *note, RLMRealm * realm) {
        XCTAssertNotNil(realm, @"Realm should not be nil");
        XCTAssertEqualObjects(note, RLMRealmDidChangeNotification, @"Notification type");
        notificationFired = YES;
        [self notify:XCTAsyncTestCaseStatusSucceeded];
    }];

    dispatch_queue_t queue = dispatch_queue_create("background", 0);
    dispatch_async(queue, ^{
        [[RLMRealm realmWithPath:realmFilePath error:nil] writeUsingBlock:^(RLMRealm *realm) {
            [realm createTableWithName:tableName];
        }];
    });
    
    [self waitForTimeout:2.0f];
    
    XCTAssertTrue(notificationFired, @"A notification should have fired after a table was created");
    
    RLMTable *table = [realm tableWithName:tableName];
    XCTAssertNotNil(table, @"The RLMRealm should be able to read a newly \
                    created table after a RLMRealmDidChangeNotification was sent");
}

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
        
        [self waitForTimeout:1.0f];
    }
    
    // make sure implicit commit took place
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        RLMRealm *bgrealm = [self realmWithTestPath];
        RLMTable *table = [bgrealm tableWithName:@"table"];
        XCTAssertTrue([table rowCount] == 1, @"See the new row");
        [self notify:XCTAsyncTestCaseStatusSucceeded];
    });
    
    [self waitForTimeout:1.0f];
}

- (void)testRealmOnMainThreadDoesntThrow {
    XCTAssertNoThrow([self realmPersistedAtTestPath], @"Calling \
                     +realmWithPath on the main thread shouldn't throw an exception.");
}

- (void)testRealmOnDifferentThreadDoesntThrow {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        XCTAssertNoThrow([self realmPersistedAtTestPath], @"Calling \
                        +realmWithPath on a thread with a runloop \
                        should not throw an exception.");
        [self notify:XCTAsyncTestCaseStatusSucceeded];
    });
    [self waitForStatus:XCTAsyncTestCaseStatusSucceeded timeout:1.0f];
}


- (void)testRealmWithArgumentsOnDifferentThreadDoesntThrow {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        XCTAssertNoThrow([RLMRealm realmWithPath:RLMTestRealmPath],
                         @"Calling +realmWithPath:runLoop:notificationCenter:error: \
                         on a thread other than the main thread \
                         shouldn't throw an exception.");
        [self notify:XCTAsyncTestCaseStatusSucceeded];
    });
    [self waitForStatus:XCTAsyncTestCaseStatusSucceeded timeout:1.0f];
}

- (void)testHasTableWithName {
    NSString *tableName = @"test";
    RLMRealm *realm = [self realmPersistedAtTestPath];
    
    // Tables shouldn't exist until they are created
    XCTAssertFalse([realm hasTableWithName:tableName], @"Table 'test' shouldn't exist");
    XCTAssertFalse([realm hasTableWithName:tableName], @"Table 'test' still shouldn't exist \
                   after checking for its existence");
    XCTAssertNil([realm tableWithName:tableName], @"Table 'test' should be nil \
                 if requested from the realm");
    
    // Tables should exist after being created
    [[self realmWithTestPath] writeUsingBlock:^(RLMRealm *realm) {
        [realm createTableWithName:tableName];
    }];
    
    RLMRealm *realm2 = [self realmPersistedAtTestPath];
    XCTAssertTrue([realm2 hasTableWithName:tableName], @"Table 'test' should exist \
                  after being created");
    XCTAssertNotNil([realm2 tableWithName:tableName], @"Table 'test' shouldn't be nil");
}

@end
