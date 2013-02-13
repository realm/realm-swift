//
//  table.m
//  TightDB
//
// Using lowlevel interface, test creation of creating two columns with two rows
//

#import <SenTestingKit/SenTestingKit.h>

#import <tightdb/objc/table.h>

@interface MACtestTable : SenTestCase
@end
@implementation MACtestTable
{
    Table *_table;
}

- (void)setUp
{
    [super setUp];

    _table = [[Table alloc] init];
    NSLog(@"Table: %@", _table);
    STAssertNotNil(_table, @"Table is nil");
}

- (void)tearDown
{
    // Tear-down code here.

    [super tearDown];
    _table = nil;
}

- (void)testTable
{
    // 1. Add two columns
    [_table addColumn:tightdb_Int name:@"first"];
    [_table addColumn:tightdb_Int name:@"second"];

    // Verify
    STAssertEquals(tightdb_Int, [_table getColumnType:0], @"First column not int");
    STAssertEquals(tightdb_Int, [_table getColumnType:1], @"Second column not int");
    if (![[_table getColumnName:0] isEqualToString:@"first"])
        STFail(@"First not equal to first");
    if (![[_table getColumnName:1] isEqualToString:@"second"])
        STFail(@"Second not equal to second");

    // 2. Add a row with data
    const size_t ndx = [_table addRow];
    [_table set:0 ndx:ndx value:0];
    [_table set:1 ndx:ndx value:10];

    // Verify
    if ([_table get:0 ndx:ndx] != 0)
        STFail(@"First not zero");
    if ([_table get:1 ndx:ndx] != 10)
        STFail(@"Second not 10");
}

@end
