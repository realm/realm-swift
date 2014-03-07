/*************************************************************************
 *
 * TIGHTDB CONFIDENTIAL
 * __________________
 *
 *  [2011] - [2014] TightDB Inc
 *  All Rights Reserved.
 *
 * NOTICE:  All information contained herein is, and remains
 * the property of TightDB Incorporated and its suppliers,
 * if any.  The intellectual and technical concepts contained
 * herein are proprietary to TightDB Incorporated
 * and its suppliers and may be covered by U.S. and Foreign Patents,
 * patents in process, and are protected by trade secret or copyright law.
 * Dissemination of this information or reproduction of this material
 * is strictly forbidden unless prior written permission is obtained
 * from TightDB Incorporated.
 *
 **************************************************************************/

#import <SenTestingKit/SenTestingKit.h>

#import <tightdb/objc/tightdb.h>


@interface table_view : SenTestCase

@end

@implementation table_view

- (void)setUp
{
    [super setUp];
    // Put setup code here; it will be run once, before the first test case.
}

- (void)tearDown
{
    // Put teardown code here; it will be run once, after the last test case.
    [super tearDown];
}

-(void)getColumnCount
{
    TightdbTable *t = [[TightdbTable alloc] init];
    TightdbQuery *q = [t where];
    TightdbView *v = [q findAll];
    
    STAssertEquals(0, [v getColumnCount], @"no columns added yet");
    
    [t addColumnWithType:tightdb_Int andName:@"col0"];
    STAssertEquals(1, [v getColumnCount], @"1 column added to table");
    
    for (int i=0;i<10;i++) {
        [t addColumnWithType:tightdb_Int andName:@"name"];
    }
    STAssertEquals(11, [v getColumnCount], @"10 more columns added to table");
    
    // remove column on table not yet implemented    
}

- (void)testColumnTypesOnView
{
    TightdbTable *t = [[TightdbTable alloc] init];
    
    NSUInteger boolCol      = [t addColumnWithType:tightdb_Bool andName:@"boolCol"];
    NSUInteger binaryCol    = [t addColumnWithType:tightdb_Binary andName:@"binaryCol"];
    NSUInteger dateCol      = [t addColumnWithType:tightdb_Date andName:@"dateCol"];
    NSUInteger doubleCol    = [t addColumnWithType:tightdb_Double andName:@"doubleCol"];
    NSUInteger floatCol     = [t addColumnWithType:tightdb_Float andName:@"floatCol"];
    NSUInteger intCol       = [t addColumnWithType:tightdb_Int andName:@"intCol"];
    NSUInteger mixedCol     = [t addColumnWithType:tightdb_Mixed andName:@"MixedCol"];
    NSUInteger stringCol    = [t addColumnWithType:tightdb_String andName:@"stringCol"];
    NSUInteger tableCol     = [t addColumnWithType:tightdb_Table andName:@"tableCol"];
    
    
    TightdbQuery *q = [t where];
    TightdbView *v = [q findAll];
    
    STAssertTrue([v getColumnType:boolCol]      == tightdb_Bool, @"Column types matches");
    STAssertTrue([v getColumnType:binaryCol]    == tightdb_Binary, @"Column types matches");
    STAssertTrue([v getColumnType:dateCol]      == tightdb_Date, @"Column types matches");
    STAssertTrue([v getColumnType:doubleCol]    == tightdb_Double, @"Column types matches");
    STAssertTrue([v getColumnType:floatCol]     == tightdb_Float, @"Column types matches");
    STAssertTrue([v getColumnType:intCol]       == tightdb_Int, @"Column types matches");
    STAssertTrue([v getColumnType:mixedCol]     == tightdb_Mixed, @"Column types matches");
    STAssertTrue([v getColumnType:stringCol]    == tightdb_String, @"Column types matches");
    STAssertTrue([v getColumnType:tableCol]     == tightdb_Table, @"Column types matches");
    
    STAssertThrows([v getColumnType:[v getColumnCount] + 1], @"Out of bounds");
    STAssertThrows([v getColumnType:100], @"Out of bounds");
    STAssertThrows([v getColumnType:-1], @"Out of bounds");
}

- (void)testSortOnViewIntColumn
{
    TightdbTable *t = [[TightdbTable alloc] init];
    NSUInteger intCol = [t addColumnWithType:tightdb_Int andName:@"intCol"];
    
    TightdbCursor *row = [t addEmptyRow];
    [row setInt:2 inColumn:intCol];
    
    row = [t addEmptyRow];
    [row setInt:1 inColumn:intCol];
    
    row = [t addEmptyRow];
    [row setInt:0 inColumn:intCol];
    
    TightdbQuery *q = [t where];
    TightdbView *v = [q findAll];
    
    // Not yet sorted
    STAssertTrue([v get:intCol ndx:0] == 2, @"matcing value after no sort");
    STAssertTrue([v get:intCol ndx:1] == 1, @"matcing value after no sort");
    STAssertTrue([v get:intCol ndx:2] == 0, @"matcing value after no sort");
    
    // Sort same way without order specified. Ascending default
    [v sortColumnWithIndex:intCol];
    STAssertTrue([v get:intCol ndx:0] == 0, @"matcing value after default sort");
    STAssertTrue([v get:intCol ndx:1] == 1, @"matcing value after default sort");
    STAssertTrue([v get:intCol ndx:2] == 2, @"matcing value after default sort");
    
    // Sort same way
    [v sortColumnWithIndex:intCol inOrder:tightdb_ascending];
    STAssertTrue([v get:intCol ndx:0] == 0, @"matcing value after ascending sort");
    STAssertTrue([v get:intCol ndx:1] == 1, @"matcing value after ascending sort");
    STAssertTrue([v get:intCol ndx:2] == 2, @"matcing value after ascending sort");
    
    // Sort descending
    [v sortColumnWithIndex:intCol inOrder: tightdb_descending];
    STAssertTrue([v get:intCol ndx:0] == 2, @"matcing value after descending sort");
    STAssertTrue([v get:intCol ndx:1] == 1, @"matcing value after descending sort");
    STAssertTrue([v get:intCol ndx:2] == 0, @"matcing value after descending sort");
}

- (void)testSortOnViewBoolColumn
{
    TightdbTable *t = [[TightdbTable alloc] init];
    NSUInteger boolCol = [t addColumnWithType:tightdb_Bool andName:@"boolCol"];
    
    TightdbCursor *row = [t addEmptyRow];
    [row setBool:YES inColumn:boolCol];
    
    row = [t addEmptyRow];
    [row setBool:YES inColumn:boolCol];
    
    row = [t addEmptyRow];
    [row setBool:NO inColumn:boolCol];
    
    TightdbQuery *q = [t where];
    TightdbView *v = [q findAll];
    
    // Not yet sorted
    STAssertTrue([v getBool:boolCol ndx:0] == YES, @"matcing value after no sort");
    STAssertTrue([v getBool:boolCol ndx:1] == YES, @"matcing value after no sort");
    STAssertTrue([v getBool:boolCol ndx:2] == NO, @"matcing value after no sort");
    
    // Sort same way without order specified. Ascending default
    [v sortColumnWithIndex:boolCol];
    STAssertTrue([v getBool:boolCol ndx:0] == NO, @"matcing value after default sort");
    STAssertTrue([v getBool:boolCol ndx:1] == YES, @"matcing value after default sort");
    STAssertTrue([v getBool:boolCol ndx:2] == YES, @"matcing value after default sort");
    
    // Sort same way
    [v sortColumnWithIndex:boolCol inOrder:tightdb_ascending];
    STAssertTrue([v getBool:boolCol ndx:0] == NO, @"matcing value after ascending sort");
    STAssertTrue([v getBool:boolCol ndx:1] == YES, @"matcing value after ascending sort");
    STAssertTrue([v getBool:boolCol ndx:2] == YES, @"matcing value after ascending sort");
    
    // Sort descending
    [v sortColumnWithIndex:boolCol inOrder: tightdb_descending];
    STAssertTrue([v getBool:boolCol ndx:0] == YES, @"matcing value after descending sort");
    STAssertTrue([v getBool:boolCol ndx:1] == YES, @"matcing value after descending sort");
    STAssertTrue([v getBool:boolCol ndx:2] == NO, @"matcing value after descending sort");
}


- (void)testSortOnViewDateColumn
{
    TightdbTable *t = [[TightdbTable alloc] init];
    NSUInteger dateCol = [t addColumnWithType:tightdb_Date andName:@"dateCol"];
    
    
    NSDateFormatter *formatter = [[NSDateFormatter alloc]init];
    [formatter setDateFormat:@"MM/dd/yyyy hh:mm a"];
    
    NSDate *dateFirst   = [formatter dateFromString:@"01/01/2014 10:10 PM"];
    NSDate *dateMiddle  = [formatter dateFromString:@"02/01/2014 10:10 PM"];
    NSDate *dateLast    = [formatter dateFromString:@"03/01/2014 10:10 PM"];
    
    TightdbCursor *row = [t addEmptyRow];
    [row setDate:[dateLast timeIntervalSince1970] inColumn:dateCol];
    
    row = [t addEmptyRow];
    [row setDate:[dateMiddle timeIntervalSince1970] inColumn:dateCol];
    
    row = [t addEmptyRow];
    [row setDate:[dateFirst timeIntervalSince1970] inColumn:dateCol];
    
    TightdbQuery *q = [t where];
    TightdbView *v = [q findAll];
    
    // Not yet sorted
    STAssertTrue([v getDate:dateCol ndx:0] == [dateLast timeIntervalSince1970], @"matcing value after no sort");
    STAssertTrue([v getDate:dateCol ndx:1] == [dateMiddle timeIntervalSince1970], @"matcing value after no sort");
    STAssertTrue([v getDate:dateCol ndx:2] == [dateFirst timeIntervalSince1970], @"matcing value after no sort");
    
    // Sort same way without order specified. Ascending default
    [v sortColumnWithIndex:dateCol];
    STAssertTrue([v getDate:dateCol ndx:0] == [dateFirst timeIntervalSince1970], @"matcing value after default sort");
    STAssertTrue([v getDate:dateCol ndx:1] == [dateMiddle timeIntervalSince1970], @"matcing value after default sort");
    STAssertTrue([v getDate:dateCol ndx:2] == [dateLast timeIntervalSince1970], @"matcing value after default sort");
    
    // Sort same way
    [v sortColumnWithIndex:dateCol inOrder:tightdb_ascending];
    STAssertTrue([v getDate:dateCol ndx:0] == [dateFirst timeIntervalSince1970], @"matcing value after ascending sort");
    STAssertTrue([v getDate:dateCol ndx:1] == [dateMiddle timeIntervalSince1970], @"matcing value after ascending sort");
    STAssertTrue([v getDate:dateCol ndx:2] == [dateLast timeIntervalSince1970], @"matcing value after ascending sort");
    
    // Sort descending
    [v sortColumnWithIndex:dateCol inOrder: tightdb_descending];
    STAssertTrue([v getDate:dateCol ndx:0] == [dateLast timeIntervalSince1970], @"matcing value after descending sort");
    STAssertTrue([v getDate:dateCol ndx:1] == [dateMiddle timeIntervalSince1970], @"matcing value after descending sort");
    STAssertTrue([v getDate:dateCol ndx:2] == [dateFirst timeIntervalSince1970], @"matcing value after descending sort");
}


- (void)testSortOnAllColumnTypes
{
    TightdbTable *t = [[TightdbTable alloc] init];
    
    NSUInteger boolCol      = [t addColumnWithType:tightdb_Bool andName:@"boolCol"];
    NSUInteger binaryCol    = [t addColumnWithType:tightdb_Binary andName:@"binaryCol"];
    NSUInteger dateCol      = [t addColumnWithType:tightdb_Date andName:@"dateCol"];
    NSUInteger doubleCol    = [t addColumnWithType:tightdb_Double andName:@"doubleCol"];
    NSUInteger floatCol     = [t addColumnWithType:tightdb_Float andName:@"floatCol"];
    NSUInteger intCol       = [t addColumnWithType:tightdb_Int andName:@"intCol"];
    NSUInteger mixedCol     = [t addColumnWithType:tightdb_Mixed andName:@"MixedCol"];
    NSUInteger stringCol    = [t addColumnWithType:tightdb_String andName:@"stringCol"];
    NSUInteger tableCol     = [t addColumnWithType:tightdb_Table andName:@"tableCol"];
    
    TightdbQuery *q = [t where];
    TightdbView *v = [q findAll];
    
    [v sortColumnWithIndex:boolCol]; // bool is supported
    STAssertThrows([v sortColumnWithIndex:binaryCol], @"Not supported on binary column");
    [v sortColumnWithIndex:dateCol]; // bool is supported
    STAssertThrows([v sortColumnWithIndex:doubleCol], @"Not supported on double column");
    STAssertThrows([v sortColumnWithIndex:floatCol], @"Not supported on float column");
    [v sortColumnWithIndex:intCol]; // int is supported
    STAssertThrows([v sortColumnWithIndex:mixedCol], @"Not supported on mixed column");
    STAssertThrows([v sortColumnWithIndex:stringCol], @"Not supported on string column");
    STAssertThrows([v sortColumnWithIndex:tableCol], @"Not supported on table column");
}

@end
