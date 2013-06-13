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
    TightdbGroup *_group;
}

- (void)setUp
{
    [super setUp];

    // _group = [TightdbGroup group];
    // NSLog(@"TightdbGroup: %@", _group);
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
    TightdbGroup *toDisk = [TightdbGroup group];
    [fm removeItemAtPath:@"table_test.tightdb" error:NULL];
    [toDisk write:@"table_test.tightdb"];

    // Load the group
    TightdbGroup *fromDisk = [TightdbGroup groupWithFilename:@"table_test.tightdb"];
    if (!fromDisk)
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


