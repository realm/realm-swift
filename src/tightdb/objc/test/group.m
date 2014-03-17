//
//  group.m
//  TightDB
//
//  Test save/load on disk of a group with one table
//

#import <SenTestingKit/SenTestingKit.h>

#import <tightdb/objc/tightdb.h>
#import <tightdb/objc/group.h>

TIGHTDB_TABLE_2(TestTableGroup,
                First,  String,
                Second, Int)

@interface MACTestGroup: SenTestCase
@end
@implementation MACTestGroup
{
    TDBGroup *_group;
}

- (void)setUp
{
    [super setUp];

    // _group = [TDBGroup group];
    // NSLog(@"TDBGroup: %@", _group);
    // STAssertNotNil(_group, @"Group is nil");
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
    TDBGroup *toDisk = [TDBGroup group];
    [fm removeItemAtPath:@"table_test.tightdb" error:NULL];
    [toDisk writeToFile:@"table_test.tightdb" withError:nil];

    // Load the group
    TDBGroup *fromDisk = [TDBGroup groupWithFile:@"table_test.tightdb" withError:nil];
    if (!fromDisk)
        STFail(@"From disk not valid");

    // Create new table in group
    TestTableGroup *t = (TestTableGroup *)[fromDisk getOrCreateTableWithName:@"test" asTableClass:[TestTableGroup class] error:nil];

    // Verify
    NSLog(@"Columns: %zu", t.columnCount);
    if (t.columnCount != 2)
        STFail(@"Should have been 2 columns");
    if (t.rowCount != 0)
        STFail(@"Should have been empty");

    // Modify table
    [t addFirst:@"Test" Second:YES];
    NSLog(@"Size: %lu", t.rowCount);

    // Verify
    if (t.rowCount != 1)
        STFail(@"Should have been one row");

    t = nil;
}

- (void)testGetTable
{
    TDBGroup *g = [TDBGroup group];
    STAssertNil([g getTableWithName:@"noTable"], @"Table does not exist");
}

@end


