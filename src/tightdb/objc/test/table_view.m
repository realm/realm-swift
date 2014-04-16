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

#import <XCTest/XCTest.h>

#import <tightdb/objc/TightdbFast.h>

@interface table_view : XCTestCase

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

-(void)testGetColumnCount
{
    RLMTable *t = [[RLMTable alloc] init];
    RLMQuery *q = [t where];
    TDBView *v = [q findAllRows];
    
    XCTAssertEqual((size_t)0, [v columnCount], @"no columns added yet");
    
    [t addColumnWithName:@"col0" type:RLMTypeInt];
    XCTAssertEqual([v columnCount],(size_t)1,  @"1 column added to table");
    
    for (int i=0;i<10;i++) {
        [t addColumnWithName:@"name" type:RLMTypeInt];
    }
    XCTAssertEqual([v columnCount],(size_t)11,  @"10 more columns added to table");
    
    [t removeColumnWithIndex:0];
    XCTAssertEqual([v columnCount],(size_t)10, @"1 column removed from table");
}

- (void)testColumnTypesOnView
{
    RLMTable *t = [[RLMTable alloc] init];
    
    NSUInteger boolCol      = [t addColumnWithName:@"boolCol" type:RLMTypeBool];
    NSUInteger binaryCol    = [t addColumnWithName:@"binaryCol" type:RLMTypeBinary];
    NSUInteger dateCol      = [t addColumnWithName:@"dateCol" type:RLMTypeDate];
    NSUInteger doubleCol    = [t addColumnWithName:@"doubleCol" type:RLMTypeDouble];
    NSUInteger floatCol     = [t addColumnWithName:@"floatCol" type:RLMTypeFloat];
    NSUInteger intCol       = [t addColumnWithName:@"intCol" type:RLMTypeInt];
    NSUInteger mixedCol     = [t addColumnWithName:@"MixedCol" type:RLMTypeMixed];
    NSUInteger stringCol    = [t addColumnWithName:@"stringCol" type:RLMTypeString];
    NSUInteger tableCol     = [t addColumnWithName:@"tableCol" type:RLMTypeTable];
    
    
    RLMQuery *q = [t where];
    TDBView *v = [q findAllRows];
    
    XCTAssertTrue([v columnTypeOfColumnWithIndex:boolCol]      == RLMTypeBool, @"Column types matches");
    XCTAssertTrue([v columnTypeOfColumnWithIndex:binaryCol]    == RLMTypeBinary, @"Column types matches");
    XCTAssertTrue([v columnTypeOfColumnWithIndex:dateCol]      == RLMTypeDate, @"Column types matches");
    XCTAssertTrue([v columnTypeOfColumnWithIndex:doubleCol]    == RLMTypeDouble, @"Column types matches");
    XCTAssertTrue([v columnTypeOfColumnWithIndex:floatCol]     == RLMTypeFloat, @"Column types matches");
    XCTAssertTrue([v columnTypeOfColumnWithIndex:intCol]       == RLMTypeInt, @"Column types matches");
    XCTAssertTrue([v columnTypeOfColumnWithIndex:mixedCol]     == RLMTypeMixed, @"Column types matches");
    XCTAssertTrue([v columnTypeOfColumnWithIndex:stringCol]    == RLMTypeString, @"Column types matches");
    XCTAssertTrue([v columnTypeOfColumnWithIndex:tableCol]     == RLMTypeTable, @"Column types matches");
    
    XCTAssertThrows([v columnTypeOfColumnWithIndex:[v columnCount] + 1], @"Out of bounds");
    XCTAssertThrows([v columnTypeOfColumnWithIndex:100], @"Out of bounds");
    XCTAssertThrows([v columnTypeOfColumnWithIndex:-1], @"Out of bounds");
}

- (void)testSortOnViewIntColumn
{
    RLMTable *t = [[RLMTable alloc] init];
    NSUInteger intCol = [t addColumnWithName:@"intCol" type:RLMTypeInt];
    
    [t addRow:nil];
    RLMRow *row = [t lastRow];
    [row setInt:2 inColumnWithIndex:intCol];
    
    [t addRow:nil];
    row = [t lastRow];
    [row setInt:1 inColumnWithIndex:intCol];
    
    [t addRow:nil];
    row = [t lastRow];
    [row setInt:0 inColumnWithIndex:intCol];
    
    RLMQuery *q = [t where];
    TDBView *v = [q findAllRows];
    
    // Not yet sorted
    XCTAssertTrue([v TDB_intInColumnWithIndex:intCol atRowIndex:0] == 2, @"matcing value after no sort");
    XCTAssertTrue([v TDB_intInColumnWithIndex:intCol atRowIndex:1] == 1, @"matcing value after no sort");
    XCTAssertTrue([v TDB_intInColumnWithIndex:intCol atRowIndex:2] == 0, @"matcing value after no sort");
    
    // Sort same way without order specified. Ascending default
    [v sortUsingColumnWithIndex:intCol];
    XCTAssertTrue([v TDB_intInColumnWithIndex:intCol atRowIndex:0] == 0, @"matcing value after default sort");
    XCTAssertTrue([v TDB_intInColumnWithIndex:intCol atRowIndex:1] == 1, @"matcing value after default sort");
    XCTAssertTrue([v TDB_intInColumnWithIndex:intCol atRowIndex:2] == 2, @"matcing value after default sort");
    
    // Sort same way
    [v sortUsingColumnWithIndex:intCol inOrder:RLMSortOrderAscending];
    XCTAssertTrue([v TDB_intInColumnWithIndex:intCol atRowIndex:0] == 0, @"matcing value after ascending sort");
    XCTAssertTrue([v TDB_intInColumnWithIndex:intCol atRowIndex:1] == 1, @"matcing value after ascending sort");
    XCTAssertTrue([v TDB_intInColumnWithIndex:intCol atRowIndex:2] == 2, @"matcing value after ascending sort");
    
    // Sort descending
    [v sortUsingColumnWithIndex:intCol inOrder: RLMSortOrderDescending];
    XCTAssertTrue([v TDB_intInColumnWithIndex:intCol atRowIndex:0] == 2, @"matcing value after descending sort");
    XCTAssertTrue([v TDB_intInColumnWithIndex:intCol atRowIndex:1] == 1, @"matcing value after descending sort");
    XCTAssertTrue([v TDB_intInColumnWithIndex:intCol atRowIndex:2] == 0, @"matcing value after descending sort");
}

- (void)testSortOnViewBoolColumn
{
    RLMTable *t = [[RLMTable alloc] init];
    NSUInteger boolCol = [t addColumnWithName:@"boolCol" type:RLMTypeBool];

    [t addRow:nil];
    RLMRow *row = [t lastRow];
    [row setBool:YES inColumnWithIndex:boolCol];

    [t addRow:nil];
    row = [t lastRow];
    [row setBool:YES inColumnWithIndex:boolCol];

    [t addRow:nil];
    row = [t lastRow];
    [row setBool:NO inColumnWithIndex:boolCol];
    
    RLMQuery *q = [t where];
    TDBView *v = [q findAllRows];
    
    // Not yet sorted
    XCTAssertTrue([v TDB_boolInColumnWithIndex:boolCol atRowIndex:0] == YES, @"matcing value after no sort");
    XCTAssertTrue([v TDB_boolInColumnWithIndex:boolCol atRowIndex:1] == YES, @"matcing value after no sort");
    XCTAssertTrue([v TDB_boolInColumnWithIndex:boolCol atRowIndex:2] == NO, @"matcing value after no sort");
    
    // Sort same way without order specified. Ascending default
    [v sortUsingColumnWithIndex:boolCol];
    XCTAssertTrue([v TDB_boolInColumnWithIndex:boolCol atRowIndex:0] == NO, @"matcing value after default sort");
    XCTAssertTrue([v TDB_boolInColumnWithIndex:boolCol atRowIndex:1] == YES, @"matcing value after default sort");
    XCTAssertTrue([v TDB_boolInColumnWithIndex:boolCol atRowIndex:2] == YES, @"matcing value after default sort");
    
    // Sort same way
    [v sortUsingColumnWithIndex:boolCol inOrder:RLMSortOrderAscending];
    XCTAssertTrue([v TDB_boolInColumnWithIndex:boolCol atRowIndex:0] == NO, @"matcing value after ascending sort");
    XCTAssertTrue([v TDB_boolInColumnWithIndex:boolCol atRowIndex:1] == YES, @"matcing value after ascending sort");
    XCTAssertTrue([v TDB_boolInColumnWithIndex:boolCol atRowIndex:2] == YES, @"matcing value after ascending sort");
    
    // Sort descending
    [v sortUsingColumnWithIndex:boolCol inOrder: RLMSortOrderDescending];
    XCTAssertTrue([v TDB_boolInColumnWithIndex:boolCol atRowIndex:0] == YES, @"matcing value after descending sort");
    XCTAssertTrue([v TDB_boolInColumnWithIndex:boolCol atRowIndex:1] == YES, @"matcing value after descending sort");
    XCTAssertTrue([v TDB_boolInColumnWithIndex:boolCol atRowIndex:2] == NO, @"matcing value after descending sort");
}


- (void)testSortOnViewDateColumn
{
    RLMTable *t = [[RLMTable alloc] init];
    NSUInteger dateCol = [t addColumnWithName:@"dateCol" type:RLMTypeDate];
    
    
    NSDateFormatter *formatter = [[NSDateFormatter alloc]init];
    [formatter setDateFormat:@"MM/dd/yyyy hh:mm a"];
    
    NSDate *dateFirst   = [formatter dateFromString:@"01/01/2014 10:10 PM"];
    NSDate *dateMiddle  = [formatter dateFromString:@"02/01/2014 10:10 PM"];
    NSDate *dateLast    = [formatter dateFromString:@"03/01/2014 10:10 PM"];
    
    [t addRow:nil];
    RLMRow *row = [t lastRow];
    [row setDate:dateLast inColumnWithIndex:dateCol];
    
    [t addRow:nil];
    row = [t lastRow];
    [row setDate:dateMiddle inColumnWithIndex:dateCol];
    
    [t addRow:nil];
    row = [t lastRow];
    [row setDate:dateFirst inColumnWithIndex:dateCol];
    
    RLMQuery *q = [t where];
    TDBView *v = [q findAllRows];
    
    // Not yet sorted
    XCTAssertTrue([v TDB_dateInColumnWithIndex:dateCol atRowIndex:0] == dateLast, @"matcing value after no sort");
    XCTAssertTrue([v TDB_dateInColumnWithIndex:dateCol atRowIndex:1] == dateMiddle, @"matcing value after no sort");
    XCTAssertTrue([v TDB_dateInColumnWithIndex:dateCol atRowIndex:2] == dateFirst, @"matcing value after no sort");
    
    // Sort same way without order specified. Ascending default
    [v sortUsingColumnWithIndex:dateCol];
    XCTAssertTrue([v TDB_dateInColumnWithIndex:dateCol atRowIndex:0] == dateFirst, @"matcing value after default sort");
    XCTAssertTrue([v TDB_dateInColumnWithIndex:dateCol atRowIndex:1] == dateMiddle, @"matcing value after default sort");
    XCTAssertTrue([v TDB_dateInColumnWithIndex:dateCol atRowIndex:2] == dateLast, @"matcing value after default sort");
    
    // Sort same way
    [v sortUsingColumnWithIndex:dateCol inOrder:RLMSortOrderAscending];
    XCTAssertTrue([v TDB_dateInColumnWithIndex:dateCol atRowIndex:0] == dateFirst, @"matcing value after ascending sort");
    XCTAssertTrue([v TDB_dateInColumnWithIndex:dateCol atRowIndex:1] == dateMiddle, @"matcing value after ascending sort");
    XCTAssertTrue([v TDB_dateInColumnWithIndex:dateCol atRowIndex:2] == dateLast, @"matcing value after ascending sort");
    
    // Sort descending
    [v sortUsingColumnWithIndex:dateCol inOrder: RLMSortOrderDescending];
    XCTAssertTrue([v TDB_dateInColumnWithIndex:dateCol atRowIndex:0] == dateLast, @"matcing value after descending sort");
    XCTAssertTrue([v TDB_dateInColumnWithIndex:dateCol atRowIndex:1] == dateMiddle, @"matcing value after descending sort");
    XCTAssertTrue([v TDB_dateInColumnWithIndex:dateCol atRowIndex:2] == dateFirst, @"matcing value after descending sort");
}


- (void)testSortOnAllColumnTypes
{
    RLMTable *t = [[RLMTable alloc] init];
    
    NSUInteger boolCol      = [t addColumnWithName:@"boolCol" type:RLMTypeBool];
    NSUInteger binaryCol    = [t addColumnWithName:@"binaryCol" type:RLMTypeBinary];
    NSUInteger dateCol      = [t addColumnWithName:@"dateCol" type:RLMTypeDate];
    NSUInteger doubleCol    = [t addColumnWithName:@"doubleCol" type:RLMTypeDouble];
    NSUInteger floatCol     = [t addColumnWithName:@"floatCol" type:RLMTypeFloat];
    NSUInteger intCol       = [t addColumnWithName:@"intCol" type:RLMTypeInt];
    NSUInteger mixedCol     = [t addColumnWithName:@"MixedCol" type:RLMTypeMixed];
    NSUInteger stringCol    = [t addColumnWithName:@"stringCol" type:RLMTypeString];
    NSUInteger tableCol     = [t addColumnWithName:@"tableCol" type:RLMTypeTable];
    
    RLMQuery *q = [t where];
    TDBView *v = [q findAllRows];
    
    [v sortUsingColumnWithIndex:boolCol]; // bool is supported
    XCTAssertThrows([v sortUsingColumnWithIndex:binaryCol], @"Not supported on binary column");
    [v sortUsingColumnWithIndex:dateCol]; // bool is supported
    XCTAssertThrows([v sortUsingColumnWithIndex:doubleCol], @"Not supported on double column");
    XCTAssertThrows([v sortUsingColumnWithIndex:floatCol], @"Not supported on float column");
    [v sortUsingColumnWithIndex:intCol]; // int is supported
    XCTAssertThrows([v sortUsingColumnWithIndex:mixedCol], @"Not supported on mixed column");
    XCTAssertThrows([v sortUsingColumnWithIndex:stringCol], @"Not supported on string column");
    XCTAssertThrows([v sortUsingColumnWithIndex:tableCol], @"Not supported on table column");
}

- (void)testFirstLastRow
{
    RLMTable *t = [[RLMTable alloc] init];
    NSUInteger col0 = [t addColumnWithName:@"col" type:RLMTypeString];
    NSUInteger col1 = [t addColumnWithName:@"col" type:RLMTypeInt];
    
    TDBView *v = [[t where] findAllRows];
    
    XCTAssertNil([v firstRow], @"Table is empty");
    XCTAssertNil([v lastRow], @"Table is empty");
    
    // add empty rows before to filter out
    [t addRow:nil];
    [t addRow:nil];
    [t addRow:nil];
    
    NSString *value0 = @"value0";
    [t addRow:@[value0, @1]];
    
    NSString *value1 = @"value1";
    [t addRow:@[value1, @1]];
    
    // add empty rows after to filter out
    [t addRow:nil];
    [t addRow:nil];
    [t addRow:nil];
    
    v = [[[t where] intIsEqualTo:1 inColumnWithIndex:col1] findAllRows];
    
    XCTAssertEqualObjects(value0, [[v firstRow] stringInColumnWithIndex:col0], @"");
    XCTAssertEqualObjects(value1, [[v lastRow] stringInColumnWithIndex:col0], @"");
}

- (void)testViewSubscripting
{
    RLMTable* table = [[RLMTable alloc]init];
    [table addColumnWithName:@"IntCol" type:RLMTypeInt];
    
    [table addRow:@[@10]];
    [table addRow:@[@42]];
    [table addRow:@[@27]];
    [table addRow:@[@31]];
    [table addRow:@[@8]];
    [table addRow:@[@39]];
    
    TDBView* view = [[[table where] intIsLessThanOrEqualTo:30 inColumnWithIndex:0] findAllRows];
    
    XCTAssertEqual(view.rowCount, (NSUInteger)3, @"found 3 matches");
    
    XCTAssertTrue([view[0][0] isEqual:@10], @"row 0 -> 0");
    XCTAssertTrue([view[1][0] isEqual:@27], @"row 1 -> 2");
    XCTAssertTrue([view[2][0] isEqual:@8],  @"row 2 -> 4");
}

- (void)testQueryOnView
{
    RLMTable *table = [[RLMTable alloc] init];
    
    // Specify the column types and names
    [table addColumnWithName:@"firstName" type:RLMTypeString];
    [table addColumnWithName:@"lastName" type:RLMTypeString];
    [table addColumnWithName:@"salary" type:RLMTypeInt];
    
    // Add data to the table
    [table addRow:@[@"John", @"Lee", @10000]];
    [table addRow:@[@"Jane", @"Lee", @15000]];
    [table addRow:@[@"John", @"Anderson", @20000]];
    [table addRow:@[@"Erik", @"Lee", @30000]];
    [table addRow:@[@"Henry", @"Anderson", @10000]];
    
    
    TDBView *view = [[table where] findAllRows];
    XCTAssertEqual(view.rowCount, (NSUInteger)5, @"All 5 rows still here");

    TDBView *view2 = [[[view where ] stringIsCaseInsensitiveEqualTo:@"John" inColumnWithIndex:0 ] findAllRows];
    XCTAssertEqual(view2.rowCount, (NSUInteger)2, @"2 rows match");
    
    TDBView *view3 = [[[view2 where] stringIsCaseInsensitiveEqualTo:@"Anderson" inColumnWithIndex:1 ] findAllRows];
    XCTAssertEqual(view3.rowCount, (NSUInteger)1, @"Only 1 row left");
}

@end
