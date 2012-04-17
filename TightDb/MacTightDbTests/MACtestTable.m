//
//  MACtestTable.m
//  TightDb
//
//  Created by Thomas Andersen on 17/04/12.
//  Copyright (c) 2012 InvulgoSoft. All rights reserved.
//

#import "MACtestTable.h"
#import "OCTable.h"


@implementation MACtestTable
{
    OCTable *_table;
}

- (void)setUp
{
    [super setUp];
    
    _table = [[OCTable alloc] init];
    NSLog(@"Table: %@", _table);
    STAssertNotNil(_table, @"OCTable is nil");
}

- (void)tearDown
{
    // Tear-down code here.
    
    [super tearDown];
    _table = nil;
}

- (void)testTable
{
    [_table registerColumn:COLUMN_TYPE_INT name:@"first"];
    [_table registerColumn:COLUMN_TYPE_INT name:@"second"];

    STAssertEquals(COLUMN_TYPE_INT, [_table getColumnType:0], @"First column not int");
    STAssertEquals(COLUMN_TYPE_INT, [_table getColumnType:1], @"Second column not int");
    if (![[_table getColumnName:0] isEqualToString:@"first"])
        STFail(@"First not equal to first");
    if (![[_table getColumnName:1] isEqualToString:@"second"])
        STFail(@"Second not equal to second");

	const size_t ndx = [_table addRow];
	[_table set:0 ndx:ndx value:0];
	[_table set:1 ndx:ndx value:10];
    if ([_table get:0 ndx:ndx] != 0)
        STFail(@"First not zero");
    if ([_table get:1 ndx:ndx] != 10)
        STFail(@"Second not 10");
}

@end
