//
//  MACTestGroup.m
//  TightDb
//
//  Created by Thomas Andersen on 17/04/12.
//  Copyright (c) 2012 InvulgoSoft. All rights reserved.
//

#import "MACTestGroup.h"
#import "OCGroup.h"

#define TIGHT_IMPL
#include "TightDb.h"

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
    
//    _group = [OCGroup group];
  //  NSLog(@"Group: %@", _group);
    //STAssertNotNil(_group, @"OCGroup is nil");
}

- (void)tearDown
{
    // Tear-down code here.
    
//    [super tearDown];
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
    
    NSLog(@"Columns: %zu", [t getColumnCount]);
    if ([t getColumnCount] != 2)
        STFail(@"Should have been 2 columns");
    if ([t getSize] != 0)
        STFail(@"Should have been empty");
	// Modify table
    [t add:@"Test" Second:YES];
    NSLog(@"Size: %lu", [t getSize]);
    
    if ([t getSize] != 1)
        STFail(@"Should have been one row");
    t = nil;
 
}



@end


