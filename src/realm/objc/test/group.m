//
//  group.m
//  TightDB
//
//  Test save/load on disk of a group with one table
//

#import <XCTest/XCTest.h>

#import <realm/objc/Realm.h>
#import <realm/objc/RLMTransaction.h>
#import <realm/objc/RLMContext.h>
#import <realm/objc/group.h>

REALM_TABLE_2(TestTableGroup,
                First,  String,
                Second, Int)

@interface MACTestGroup: XCTestCase
@end
@implementation MACTestGroup
{
    RLMTransaction *_group;
}

- (void)setUp
{
    [super setUp];

    // _group = [RLMTransaction group];
    // NSLog(@"RLMTransaction: %@", _group);
    // XCTAssertNotNil(_group, @"Group is nil");
}

- (void)tearDown
{
    // Tear-down code here.

    //  [super tearDown];
    //  _group = nil;
}

- (void)testGroup
{
    NSFileManager *fm = [NSFileManager defaultManager];

    // Create empty group and serialize to disk
    RLMTransaction *toDisk = [RLMTransaction group];
    [fm removeItemAtPath:@"table_test.tightdb" error:NULL];
    [toDisk writeContextToFile:@"table_test.tightdb" error:nil];

    // Load the group
    RLMTransaction *fromDisk = [RLMTransaction groupWithFile:@"table_test.tightdb" error:nil];
    if (!fromDisk)
        XCTFail(@"From disk not valid");

    // Create new table in group
    TestTableGroup *t = (TestTableGroup *)[fromDisk createTableWithName:@"test" asTableClass:[TestTableGroup class]];

    // Verify
    NSLog(@"Columns: %zu", t.columnCount);
    if (t.columnCount != 2)
        XCTFail(@"Should have been 2 columns");
    if (t.rowCount != 0)
        XCTFail(@"Should have been empty");

    // Modify table
    [t addFirst:@"Test" Second:YES];
    NSLog(@"Size: %lu", t.rowCount);

    // Verify
    if (t.rowCount != 1)
        XCTFail(@"Should have been one row");

    t = nil;
}

- (void)testGetTable
{
    RLMTransaction *g = [RLMTransaction group];
    XCTAssertNil([g tableWithName:@"noTable"], @"Table does not exist");
}

- (void)testGroupTableCount
{
    RLMTransaction *t = [RLMTransaction group];
    XCTAssertEqual(t.tableCount, (NSUInteger)0, @"No tables added");
    [t createTableWithName:@"tableName"];
    XCTAssertEqual(t.tableCount, (NSUInteger)1, @"1 table added");
}

@end


