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
                String, First,
                Int,    Second)

@interface MACTestGroup : SenTestCase
@end
@implementation MACTestGroup
{
    Group *_group;
}

- (void)setUp
{
    [super setUp];

    // _group = [Group group];
    // NSLog(@"Group: %@", _group);
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
    // Create empty group and serialize to disk
    Group *toDisk = [Group group];
    [toDisk write:@"table_test.tbl"];

    // Load the group
    Group *fromDisk = [Group groupWithFilename:@"table_test.tbl"];
    if (![fromDisk isValid])
        STFail(@"From disk not valid");

    // Create new table in group
    TestTableGroup *t = (TestTableGroup *)[fromDisk getTable:@"test" withClass:[TestTableGroup class]];

    // Verify
    NSLog(@"Columns: %zu", [t getColumnCount]);
    if ([t getColumnCount] != 2)
        STFail(@"Should have been 2 columns");
    if ([t count] != 0)
        STFail(@"Should have been empty");

    // Modify table
    [t addFirst:@"Test" Second:YES];
    NSLog(@"Size: %lu", [t count]);

    // Verify
    if ([t count] != 1)
        STFail(@"Should have been one row");

    t = nil;
}

@end


