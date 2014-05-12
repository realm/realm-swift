//
//  realm.mm
//  TightDB
//
//  Run tests on RLMRealm
//

#import "RLMTestCase.h"
#import <realm/objc/Realm.h>
#import "XCTestCase+AsyncTesting.h"

@interface RLMTestObject : RLMRow

@property (nonatomic, copy) NSString *column;

@end

@implementation RLMTestObject

@end

RLM_TABLE_TYPE_FOR_OBJECT_TYPE(RLMTestTable, RLMTestObject);

@interface RLMRealmTests : RLMTestCase

@end

@interface JSONRealmTestType : RLMRow

@property BOOL      boolColumn;
@property int       intColumn;
@property float     floatColumn;
@property double    doubleColumn;
@property NSString  *stringColumn;
@property NSData    *binaryColumn;
@property NSDate    *dateColumn;
@property id        mixedColumn;

@end

@implementation JSONRealmTestType
@end

RLM_TABLE_TYPE_FOR_OBJECT_TYPE(JSONRealmTestTable, JSONRealmTestType)

@implementation RLMRealmTests

#pragma mark - Tests

- (void)testRealmExists {
    RLMRealm *realm = [self realmWithTestPath];
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
    
    RLMRealm *realm = [self realmWithTestPath];
    RLMTable *table = [realm tableWithName:tableName];
    
    XCTAssertNotNil(table, @"pre-existing table read from RLMRealm should not be nil");
    XCTAssertEqual([table class], [RLMTable class], @"pre-existing table read from \
                   RLMRealm should be of class RLMTable");
}

- (void)testCanReadPreviouslyCreatedTypedTable {
    NSString *tableName = @"table";
    
    [[self realmWithTestPath] writeUsingBlock:^(RLMRealm *realm) {
        [RLMTestTable tableInRealm:realm named:tableName];
    }];
    
    RLMRealm *realm = [self realmWithTestPath];
    RLMTestTable *table = [RLMTestTable tableInRealm:realm named:tableName];
    
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

    [self waitForTimeout:2.0f];
    
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
    
    [self waitForStatus:XCTAsyncTestCaseStatusSucceeded timeout:2.0f];
    
    XCTAssertTrue(notificationFired, @"A notification should have fired after a table was created");
    
    RLMTable *table = [realm tableWithName:tableName];
    XCTAssertNotNil(table, @"The RLMRealm should be able to read a newly \
                    created table after a RLMRealmDidChangeNotification was sent");
}

- (void)testRealmIsUpdatedImmediatelyAfterBackgroundUpdate {
    NSString *realmFilePath = @"async.bg.fast.realm";
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
    
    // this should complete very fast before the timer
    [self waitForStatus:XCTAsyncTestCaseStatusSucceeded timeout:2.0f];
    
    XCTAssertTrue(notificationFired, @"A notification should have fired immediately a table was created in the background");
    
    RLMTable *table = [realm tableWithName:tableName];
    XCTAssertNotNil(table, @"The RLMRealm should be able to read a newly \
                    created table after a RLMRealmDidChangeNotification was sent");
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

- (void)testRealmOnMainThreadDoesntThrow {
    XCTAssertNoThrow([self realmWithTestPath], @"Calling \
                     +realmWithPath on the main thread shouldn't throw an exception.");
}

- (void)testRealmOnDifferentThreadDoesntThrow {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        XCTAssertNoThrow([self realmWithTestPath], @"Calling \
                        +realmWithPath on a thread with a runloop \
                        should not throw an exception.");
        [self notify:XCTAsyncTestCaseStatusSucceeded];
    });
    [self waitForStatus:XCTAsyncTestCaseStatusSucceeded timeout:2.0f];
}


- (void)testRealmWithArgumentsOnDifferentThreadDoesntThrow {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        XCTAssertNoThrow([RLMRealm realmWithPath:RLMTestRealmPath],
                         @"Calling +realmWithPath:runLoop:notificationCenter:error: \
                         on a thread other than the main thread \
                         shouldn't throw an exception.");
        [self notify:XCTAsyncTestCaseStatusSucceeded];
    });
    [self waitForStatus:XCTAsyncTestCaseStatusSucceeded timeout:2.0f];
}

- (void)testHasTableWithName {
    NSString *tableName = @"test";
    RLMRealm *realm = [self realmWithTestPath];
    
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
    
    RLMRealm *realm2 = [self realmWithTestPath];
    XCTAssertTrue([realm2 hasTableWithName:tableName], @"Table 'test' should exist \
                  after being created");
    XCTAssertNotNil([realm2 tableWithName:tableName], @"Table 'test' shouldn't be nil");
}

- (void)testToJSONString {
    
    RLMRealm *realm = [self realmWithTestPath];
    
    [realm writeUsingBlock:^(RLMRealm *realm) {
        JSONRealmTestTable *table = [JSONRealmTestTable tableInRealm:realm
                                                               named:@"test"];
        
        const char bin[4] = { 0, 1, 2, 3 };
        NSData *binary = [[NSData alloc] initWithBytes:bin length:sizeof bin];
        
        NSDate *date = (NSDate *)[NSDate dateWithString:@"2014-05-17 13:15:10 +0100"];
        [table addRow:@[@YES, @1234, @((float)12.34), @1234.5678, @"I'm just a String", binary, @((int)[date timeIntervalSince1970]), @"I'm also a string in a mixed column"]];
        
        NSString *result = [realm toJSONString];
        
        XCTAssertEqualObjects(result, @"{\"test\":[{\"boolColumn\":true,\"intColumn\":1234,\"floatColumn\":1.2340000e+01,\"doubleColumn\":1.2345678000000000e+03,\"stringColumn\":\"I'm just a String\",\"binaryColumn\":\"00010203\",\"dateColumn\":\"2014-05-17 12:15:10\",\"mixedColumn\":\"I'm also a string in a mixed column\"}]}");
    }];
}

@end
