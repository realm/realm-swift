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

#import <tightdb/objc/TightdbFast.h>

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

-(void)testGetColumnCount
{
    TDBTable *t = [[TDBTable alloc] init];
    TDBQuery *q = [t where];
    TDBView *v = [q findAllRows];
    
    STAssertEquals((size_t)0, [v columnCount], @"no columns added yet");
    
    [t addColumnWithName:@"col0" type:TDBIntType];
    STAssertEquals([v columnCount],(size_t)1,  @"1 column added to table");
    
    for (int i=0;i<10;i++) {
        [t addColumnWithName:@"name" type:TDBIntType];
    }
    STAssertEquals([v columnCount],(size_t)11,  @"10 more columns added to table");
    
    [t removeColumnWithIndex:0];
    STAssertEquals([v columnCount],(size_t)10, @"1 column removed from table");
}

- (void)testColumnTypesOnView
{
    TDBTable *t = [[TDBTable alloc] init];
    
    NSUInteger boolCol      = [t addColumnWithName:@"boolCol" type:TDBBoolType];
    NSUInteger binaryCol    = [t addColumnWithName:@"binaryCol" type:TDBBinaryType];
    NSUInteger dateCol      = [t addColumnWithName:@"dateCol" type:TDBDateType];
    NSUInteger doubleCol    = [t addColumnWithName:@"doubleCol" type:TDBDoubleType];
    NSUInteger floatCol     = [t addColumnWithName:@"floatCol" type:TDBFloatType];
    NSUInteger intCol       = [t addColumnWithName:@"intCol" type:TDBIntType];
    NSUInteger mixedCol     = [t addColumnWithName:@"MixedCol" type:TDBMixedType];
    NSUInteger stringCol    = [t addColumnWithName:@"stringCol" type:TDBStringType];
    NSUInteger tableCol     = [t addColumnWithName:@"tableCol" type:TDBTableType];
    
    
    TDBQuery *q = [t where];
    TDBView *v = [q findAllRows];
    
    STAssertTrue([v columnTypeOfColumn:boolCol]      == TDBBoolType, @"Column types matches");
    STAssertTrue([v columnTypeOfColumn:binaryCol]    == TDBBinaryType, @"Column types matches");
    STAssertTrue([v columnTypeOfColumn:dateCol]      == TDBDateType, @"Column types matches");
    STAssertTrue([v columnTypeOfColumn:doubleCol]    == TDBDoubleType, @"Column types matches");
    STAssertTrue([v columnTypeOfColumn:floatCol]     == TDBFloatType, @"Column types matches");
    STAssertTrue([v columnTypeOfColumn:intCol]       == TDBIntType, @"Column types matches");
    STAssertTrue([v columnTypeOfColumn:mixedCol]     == TDBMixedType, @"Column types matches");
    STAssertTrue([v columnTypeOfColumn:stringCol]    == TDBStringType, @"Column types matches");
    STAssertTrue([v columnTypeOfColumn:tableCol]     == TDBTableType, @"Column types matches");
    
    STAssertThrows([v columnTypeOfColumn:[v columnCount] + 1], @"Out of bounds");
    STAssertThrows([v columnTypeOfColumn:100], @"Out of bounds");
    STAssertThrows([v columnTypeOfColumn:-1], @"Out of bounds");
}

- (void)testSortOnViewIntColumn
{
    TDBTable *t = [[TDBTable alloc] init];
    NSUInteger intCol = [t addColumnWithName:@"intCol" type:TDBIntType];
    
    NSUInteger rowIndex = [t addRow:nil];
    TDBRow *row = [t rowAtIndex:rowIndex];
    [row setInt:2 inColumnWithIndex:intCol];
    
    rowIndex = [t addRow:nil];
    row = [t rowAtIndex:rowIndex];
    [row setInt:1 inColumnWithIndex:intCol];
    
    rowIndex = [t addRow:nil];
    row = [t rowAtIndex:rowIndex];
    [row setInt:0 inColumnWithIndex:intCol];
    
    TDBQuery *q = [t where];
    TDBView *v = [q findAllRows];
    
    // Not yet sorted
    STAssertTrue([v TDB_intInColumnWithIndex:intCol atRowIndex:0] == 2, @"matcing value after no sort");
    STAssertTrue([v TDB_intInColumnWithIndex:intCol atRowIndex:1] == 1, @"matcing value after no sort");
    STAssertTrue([v TDB_intInColumnWithIndex:intCol atRowIndex:2] == 0, @"matcing value after no sort");
    
    // Sort same way without order specified. Ascending default
    [v sortUsingColumnWithIndex:intCol];
    STAssertTrue([v TDB_intInColumnWithIndex:intCol atRowIndex:0] == 0, @"matcing value after default sort");
    STAssertTrue([v TDB_intInColumnWithIndex:intCol atRowIndex:1] == 1, @"matcing value after default sort");
    STAssertTrue([v TDB_intInColumnWithIndex:intCol atRowIndex:2] == 2, @"matcing value after default sort");
    
    // Sort same way
    [v sortUsingColumnWithIndex:intCol inOrder:TDBAscending];
    STAssertTrue([v TDB_intInColumnWithIndex:intCol atRowIndex:0] == 0, @"matcing value after ascending sort");
    STAssertTrue([v TDB_intInColumnWithIndex:intCol atRowIndex:1] == 1, @"matcing value after ascending sort");
    STAssertTrue([v TDB_intInColumnWithIndex:intCol atRowIndex:2] == 2, @"matcing value after ascending sort");
    
    // Sort descending
    [v sortUsingColumnWithIndex:intCol inOrder: TDBDescending];
    STAssertTrue([v TDB_intInColumnWithIndex:intCol atRowIndex:0] == 2, @"matcing value after descending sort");
    STAssertTrue([v TDB_intInColumnWithIndex:intCol atRowIndex:1] == 1, @"matcing value after descending sort");
    STAssertTrue([v TDB_intInColumnWithIndex:intCol atRowIndex:2] == 0, @"matcing value after descending sort");
}

- (void)testSortOnViewBoolColumn
{
    TDBTable *t = [[TDBTable alloc] init];
    NSUInteger boolCol = [t addColumnWithName:@"boolCol" type:TDBBoolType];
    
    TDBRow *row = [t rowAtIndex:[t addRow:nil]];
    [row setBool:YES inColumnWithIndex:boolCol];
    
    row = [t rowAtIndex:[t addRow:nil]];
    [row setBool:YES inColumnWithIndex:boolCol];
    
    row = [t rowAtIndex:[t addRow:nil]];
    [row setBool:NO inColumnWithIndex:boolCol];
    
    TDBQuery *q = [t where];
    TDBView *v = [q findAllRows];
    
    // Not yet sorted
    STAssertTrue([v TDB_boolInColumnWithIndex:boolCol atRowIndex:0] == YES, @"matcing value after no sort");
    STAssertTrue([v TDB_boolInColumnWithIndex:boolCol atRowIndex:1] == YES, @"matcing value after no sort");
    STAssertTrue([v TDB_boolInColumnWithIndex:boolCol atRowIndex:2] == NO, @"matcing value after no sort");
    
    // Sort same way without order specified. Ascending default
    [v sortUsingColumnWithIndex:boolCol];
    STAssertTrue([v TDB_boolInColumnWithIndex:boolCol atRowIndex:0] == NO, @"matcing value after default sort");
    STAssertTrue([v TDB_boolInColumnWithIndex:boolCol atRowIndex:1] == YES, @"matcing value after default sort");
    STAssertTrue([v TDB_boolInColumnWithIndex:boolCol atRowIndex:2] == YES, @"matcing value after default sort");
    
    // Sort same way
    [v sortUsingColumnWithIndex:boolCol inOrder:TDBAscending];
    STAssertTrue([v TDB_boolInColumnWithIndex:boolCol atRowIndex:0] == NO, @"matcing value after ascending sort");
    STAssertTrue([v TDB_boolInColumnWithIndex:boolCol atRowIndex:1] == YES, @"matcing value after ascending sort");
    STAssertTrue([v TDB_boolInColumnWithIndex:boolCol atRowIndex:2] == YES, @"matcing value after ascending sort");
    
    // Sort descending
    [v sortUsingColumnWithIndex:boolCol inOrder: TDBDescending];
    STAssertTrue([v TDB_boolInColumnWithIndex:boolCol atRowIndex:0] == YES, @"matcing value after descending sort");
    STAssertTrue([v TDB_boolInColumnWithIndex:boolCol atRowIndex:1] == YES, @"matcing value after descending sort");
    STAssertTrue([v TDB_boolInColumnWithIndex:boolCol atRowIndex:2] == NO, @"matcing value after descending sort");
}


- (void)testSortOnViewDateColumn
{
    TDBTable *t = [[TDBTable alloc] init];
    NSUInteger dateCol = [t addColumnWithName:@"dateCol" type:TDBDateType];
    
    
    NSDateFormatter *formatter = [[NSDateFormatter alloc]init];
    [formatter setDateFormat:@"MM/dd/yyyy hh:mm a"];
    
    NSDate *dateFirst   = [formatter dateFromString:@"01/01/2014 10:10 PM"];
    NSDate *dateMiddle  = [formatter dateFromString:@"02/01/2014 10:10 PM"];
    NSDate *dateLast    = [formatter dateFromString:@"03/01/2014 10:10 PM"];
    
    NSUInteger rowIndex = [t addRow:nil];
    TDBRow *row = [t rowAtIndex:rowIndex];
    [row setDate:dateLast inColumnWithIndex:dateCol];
    
    rowIndex = [t addRow:nil];
    row = [t rowAtIndex:rowIndex];
    [row setDate:dateMiddle inColumnWithIndex:dateCol];
    
    rowIndex = [t addRow:nil];
    row = [t rowAtIndex:rowIndex];
    [row setDate:dateFirst inColumnWithIndex:dateCol];
    
    TDBQuery *q = [t where];
    TDBView *v = [q findAllRows];
    
    // Not yet sorted
    STAssertTrue([v TDB_dateInColumnWithIndex:dateCol atRowIndex:0] == dateLast, @"matcing value after no sort");
    STAssertTrue([v TDB_dateInColumnWithIndex:dateCol atRowIndex:1] == dateMiddle, @"matcing value after no sort");
    STAssertTrue([v TDB_dateInColumnWithIndex:dateCol atRowIndex:2] == dateFirst, @"matcing value after no sort");
    
    // Sort same way without order specified. Ascending default
    [v sortUsingColumnWithIndex:dateCol];
    STAssertTrue([v TDB_dateInColumnWithIndex:dateCol atRowIndex:0] == dateFirst, @"matcing value after default sort");
    STAssertTrue([v TDB_dateInColumnWithIndex:dateCol atRowIndex:1] == dateMiddle, @"matcing value after default sort");
    STAssertTrue([v TDB_dateInColumnWithIndex:dateCol atRowIndex:2] == dateLast, @"matcing value after default sort");
    
    // Sort same way
    [v sortUsingColumnWithIndex:dateCol inOrder:TDBAscending];
    STAssertTrue([v TDB_dateInColumnWithIndex:dateCol atRowIndex:0] == dateFirst, @"matcing value after ascending sort");
    STAssertTrue([v TDB_dateInColumnWithIndex:dateCol atRowIndex:1] == dateMiddle, @"matcing value after ascending sort");
    STAssertTrue([v TDB_dateInColumnWithIndex:dateCol atRowIndex:2] == dateLast, @"matcing value after ascending sort");
    
    // Sort descending
    [v sortUsingColumnWithIndex:dateCol inOrder: TDBDescending];
    STAssertTrue([v TDB_dateInColumnWithIndex:dateCol atRowIndex:0] == dateLast, @"matcing value after descending sort");
    STAssertTrue([v TDB_dateInColumnWithIndex:dateCol atRowIndex:1] == dateMiddle, @"matcing value after descending sort");
    STAssertTrue([v TDB_dateInColumnWithIndex:dateCol atRowIndex:2] == dateFirst, @"matcing value after descending sort");
}


- (void)testSortOnAllColumnTypes
{
    TDBTable *t = [[TDBTable alloc] init];
    
    NSUInteger boolCol      = [t addColumnWithName:@"boolCol" type:TDBBoolType];
    NSUInteger binaryCol    = [t addColumnWithName:@"binaryCol" type:TDBBinaryType];
    NSUInteger dateCol      = [t addColumnWithName:@"dateCol" type:TDBDateType];
    NSUInteger doubleCol    = [t addColumnWithName:@"doubleCol" type:TDBDoubleType];
    NSUInteger floatCol     = [t addColumnWithName:@"floatCol" type:TDBFloatType];
    NSUInteger intCol       = [t addColumnWithName:@"intCol" type:TDBIntType];
    NSUInteger mixedCol     = [t addColumnWithName:@"MixedCol" type:TDBMixedType];
    NSUInteger stringCol    = [t addColumnWithName:@"stringCol" type:TDBStringType];
    NSUInteger tableCol     = [t addColumnWithName:@"tableCol" type:TDBTableType];
    
    TDBQuery *q = [t where];
    TDBView *v = [q findAllRows];
    
    [v sortUsingColumnWithIndex:boolCol]; // bool is supported
    STAssertThrows([v sortUsingColumnWithIndex:binaryCol], @"Not supported on binary column");
    [v sortUsingColumnWithIndex:dateCol]; // bool is supported
    STAssertThrows([v sortUsingColumnWithIndex:doubleCol], @"Not supported on double column");
    STAssertThrows([v sortUsingColumnWithIndex:floatCol], @"Not supported on float column");
    [v sortUsingColumnWithIndex:intCol]; // int is supported
    STAssertThrows([v sortUsingColumnWithIndex:mixedCol], @"Not supported on mixed column");
    STAssertThrows([v sortUsingColumnWithIndex:stringCol], @"Not supported on string column");
    STAssertThrows([v sortUsingColumnWithIndex:tableCol], @"Not supported on table column");
}

- (void)testFirstLastRow
{
    TDBTable *t = [[TDBTable alloc] init];
    NSUInteger col0 = [t addColumnWithName:@"col" type:TDBStringType];
    NSUInteger col1 = [t addColumnWithName:@"col" type:TDBIntType];
    
    TDBView *v = [[t where] findAllRows];
    
    STAssertNil([v firstRow], @"Table is empty");
    STAssertNil([v lastRow], @"Table is empty");
    
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
    
    STAssertEqualObjects(value0, [[v firstRow] stringInColumnWithIndex:col0], nil);
    STAssertEqualObjects(value1, [[v lastRow] stringInColumnWithIndex:col0], nil);
}

- (void)testViewSubscripting
{
    TDBTable* table = [[TDBTable alloc]init];
    [table addColumnWithName:@"IntCol" type:TDBIntType];
    
    [table addRow:@[@10]];
    [table addRow:@[@42]];
    [table addRow:@[@27]];
    [table addRow:@[@31]];
    [table addRow:@[@8]];
    [table addRow:@[@39]];
    
    TDBView* view = [[[table where] intIsLessThanOrEqualTo:30 inColumnWithIndex:0] findAllRows];
    
    STAssertEquals(view.rowCount, (NSUInteger)3, @"found 3 matches");
    
    STAssertTrue([view[0][0] isEqual:@10], @"row 0 -> 0");
    STAssertTrue([view[1][0] isEqual:@27], @"row 1 -> 2");
    STAssertTrue([view[2][0] isEqual:@8],  @"row 2 -> 4");
}

@end
