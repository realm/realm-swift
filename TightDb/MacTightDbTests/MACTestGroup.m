//
//  MACTestGroup.m
//  TightDB
//
//  Test save/load on disk of a group with one table
//

#import "MACTestGroup.h"
#import "OCGroup.h"

TDB_TABLE_2(TestTableGroup,
			String,     First,
			Int,        Second)


@implementation MACTestGroup
{
    OCGroup *_group;
}

- (void)setUp
{
    [super setUp];
    
	// _group = [OCGroup group];
	// NSLog(@"Group: %@", _group);
    // STAssertNotNil(_group, @"OCGroup is nil");
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
    OCGroup *toDisk = [OCGroup group];
    [toDisk write:@"table_test.tbl"];

	// Load the group
    OCGroup *fromDisk = [OCGroup groupWithFilename:@"table_test.tbl"];
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


