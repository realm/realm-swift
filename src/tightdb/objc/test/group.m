//
//  group.m
//  TightDB
//
//  Test save/load on disk of a group with one table
//

#import <SenTestingKit/SenTestingKit.h>

#import <tightdb/objc/Tightdb.h>
#import <tightdb/objc/TDBTransaction.h>
#import <tightdb/objc/TDBContext.h>
#import <tightdb/objc/group.h>

TIGHTDB_TABLE_2(TestTableGroup,
                First,  String,
                Second, Int)

@interface MACTestGroup: SenTestCase
@end
@implementation MACTestGroup
{
    TDBTransaction *_group;
}

- (void)setUp
{
    [super setUp];

    // _group = [TDBTransaction group];
    // NSLog(@"TDBTransaction: %@", _group);
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
    TDBTransaction *toDisk = [TDBTransaction group];
    [fm removeItemAtPath:@"table_test.tightdb" error:NULL];
    [toDisk writeContextToFile:@"table_test.tightdb" withError:nil];

    // Load the group
    TDBTransaction *fromDisk = [TDBTransaction groupWithFile:@"table_test.tightdb" withError:nil];
    if (!fromDisk)
        STFail(@"From disk not valid");

    // Create new table in group
    TestTableGroup *t = (TestTableGroup *)[fromDisk createTableWithName:@"test" asTableClass:[TestTableGroup class]];

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
    TDBTransaction *g = [TDBTransaction group];
    STAssertNil([g getTableWithName:@"noTable"], @"Table does not exist");
}

@end


