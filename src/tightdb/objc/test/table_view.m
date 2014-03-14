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

-(void)testGetColumnCount
{
    TDBTable *t = [[TDBTable alloc] init];
    TDBQuery *q = [t where];
    TDBView *v = [q findAllRows];
    
    STAssertEquals((size_t)0, [v columnCount], @"no columns added yet");
    
    [t addColumnWithName:@"col0" andType:TDBIntType];
    STAssertEquals([v columnCount],(size_t)1,  @"1 column added to table");
    
    for (int i=0;i<10;i++) {
        [t addColumnWithName:@"name" andType:TDBIntType];
    }
    STAssertEquals([v columnCount],(size_t)11,  @"10 more columns added to table");
    
    [t removeColumnWithIndex:0];
    STAssertEquals([v columnCount],(size_t)10, @"1 column removed from table");
}

- (void)testColumnTypesOnView
{
    TDBTable *t = [[TDBTable alloc] init];
    
    NSUInteger boolCol      = [t addColumnWithName:@"boolCol" andType:TDBBoolType];
    NSUInteger binaryCol    = [t addColumnWithName:@"binaryCol" andType:TDBBinaryType];
    NSUInteger dateCol      = [t addColumnWithName:@"dateCol" andType:TDBDateType];
    NSUInteger doubleCol    = [t addColumnWithName:@"doubleCol" andType:TDBDoubleType];
    NSUInteger floatCol     = [t addColumnWithName:@"floatCol" andType:TDBFloatType];
    NSUInteger intCol       = [t addColumnWithName:@"intCol" andType:TDBIntType];
    NSUInteger mixedCol     = [t addColumnWithName:@"MixedCol" andType:TDBMixedType];
    NSUInteger stringCol    = [t addColumnWithName:@"stringCol" andType:TDBStringType];
    NSUInteger tableCol     = [t addColumnWithName:@"tableCol" andType:TDBTableType];
    
    
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
    NSUInteger intCol = [t addColumnWithName:@"intCol" andType:TDBIntType];
    
    TDBRow *row = [t addEmptyRow];
    [row setInt:2 inColumnWithIndex:intCol];
    
    row = [t addEmptyRow];
    [row setInt:1 inColumnWithIndex:intCol];
    
    row = [t addEmptyRow];
    [row setInt:0 inColumnWithIndex:intCol];
    
    TDBQuery *q = [t where];
    TDBView *v = [q findAllRows];
    
    // Not yet sorted
    STAssertTrue([v intInColumnWithIndex:intCol atRowIndex:0] == 2, @"matcing value after no sort");
    STAssertTrue([v intInColumnWithIndex:intCol atRowIndex:1] == 1, @"matcing value after no sort");
    STAssertTrue([v intInColumnWithIndex:intCol atRowIndex:2] == 0, @"matcing value after no sort");
    
    // Sort same way without order specified. Ascending default
    [v sortUsingColumnWithIndex:intCol];
    STAssertTrue([v intInColumnWithIndex:intCol atRowIndex:0] == 0, @"matcing value after default sort");
    STAssertTrue([v intInColumnWithIndex:intCol atRowIndex:1] == 1, @"matcing value after default sort");
    STAssertTrue([v intInColumnWithIndex:intCol atRowIndex:2] == 2, @"matcing value after default sort");
    
    // Sort same way
    [v sortUsingColumnWithIndex:intCol inOrder:TDBAscending];
    STAssertTrue([v intInColumnWithIndex:intCol atRowIndex:0] == 0, @"matcing value after ascending sort");
    STAssertTrue([v intInColumnWithIndex:intCol atRowIndex:1] == 1, @"matcing value after ascending sort");
    STAssertTrue([v intInColumnWithIndex:intCol atRowIndex:2] == 2, @"matcing value after ascending sort");
    
    // Sort descending
    [v sortUsingColumnWithIndex:intCol inOrder: TDBDescending];
    STAssertTrue([v intInColumnWithIndex:intCol atRowIndex:0] == 2, @"matcing value after descending sort");
    STAssertTrue([v intInColumnWithIndex:intCol atRowIndex:1] == 1, @"matcing value after descending sort");
    STAssertTrue([v intInColumnWithIndex:intCol atRowIndex:2] == 0, @"matcing value after descending sort");
}

- (void)testSortOnViewBoolColumn
{
    TDBTable *t = [[TDBTable alloc] init];
    NSUInteger boolCol = [t addColumnWithName:@"boolCol" andType:TDBBoolType];
    
    TDBRow *row = [t addEmptyRow];
    [row setBool:YES inColumnWithIndex:boolCol];
    
    row = [t addEmptyRow];
    [row setBool:YES inColumnWithIndex:boolCol];
    
    row = [t addEmptyRow];
    [row setBool:NO inColumnWithIndex:boolCol];
    
    TDBQuery *q = [t where];
    TDBView *v = [q findAllRows];
    
    // Not yet sorted
    STAssertTrue([v boolInColumnWithIndex:boolCol atRowIndex:0] == YES, @"matcing value after no sort");
    STAssertTrue([v boolInColumnWithIndex:boolCol atRowIndex:1] == YES, @"matcing value after no sort");
    STAssertTrue([v boolInColumnWithIndex:boolCol atRowIndex:2] == NO, @"matcing value after no sort");
    
    // Sort same way without order specified. Ascending default
    [v sortUsingColumnWithIndex:boolCol];
    STAssertTrue([v boolInColumnWithIndex:boolCol atRowIndex:0] == NO, @"matcing value after default sort");
    STAssertTrue([v boolInColumnWithIndex:boolCol atRowIndex:1] == YES, @"matcing value after default sort");
    STAssertTrue([v boolInColumnWithIndex:boolCol atRowIndex:2] == YES, @"matcing value after default sort");
    
    // Sort same way
    [v sortUsingColumnWithIndex:boolCol inOrder:TDBAscending];
    STAssertTrue([v boolInColumnWithIndex:boolCol atRowIndex:0] == NO, @"matcing value after ascending sort");
    STAssertTrue([v boolInColumnWithIndex:boolCol atRowIndex:1] == YES, @"matcing value after ascending sort");
    STAssertTrue([v boolInColumnWithIndex:boolCol atRowIndex:2] == YES, @"matcing value after ascending sort");
    
    // Sort descending
    [v sortUsingColumnWithIndex:boolCol inOrder: TDBDescending];
    STAssertTrue([v boolInColumnWithIndex:boolCol atRowIndex:0] == YES, @"matcing value after descending sort");
    STAssertTrue([v boolInColumnWithIndex:boolCol atRowIndex:1] == YES, @"matcing value after descending sort");
    STAssertTrue([v boolInColumnWithIndex:boolCol atRowIndex:2] == NO, @"matcing value after descending sort");
}


- (void)testSortOnViewDateColumn
{
    TDBTable *t = [[TDBTable alloc] init];
    NSUInteger dateCol = [t addColumnWithName:@"dateCol" andType:TDBDateType];
    
    
    NSDateFormatter *formatter = [[NSDateFormatter alloc]init];
    [formatter setDateFormat:@"MM/dd/yyyy hh:mm a"];
    
    NSDate *dateFirst   = [formatter dateFromString:@"01/01/2014 10:10 PM"];
    NSDate *dateMiddle  = [formatter dateFromString:@"02/01/2014 10:10 PM"];
    NSDate *dateLast    = [formatter dateFromString:@"03/01/2014 10:10 PM"];
    
    TDBRow *row = [t addEmptyRow];
    [row setDate:[dateLast timeIntervalSince1970] inColumnWithIndex:dateCol];
    
    row = [t addEmptyRow];
    [row setDate:[dateMiddle timeIntervalSince1970] inColumnWithIndex:dateCol];
    
    row = [t addEmptyRow];
    [row setDate:[dateFirst timeIntervalSince1970] inColumnWithIndex:dateCol];
    
    TDBQuery *q = [t where];
    TDBView *v = [q findAllRows];
    
    // Not yet sorted
    STAssertTrue([v dateInColumnWithIndex:dateCol atRowIndex:0] == [dateLast timeIntervalSince1970], @"matcing value after no sort");
    STAssertTrue([v dateInColumnWithIndex:dateCol atRowIndex:1] == [dateMiddle timeIntervalSince1970], @"matcing value after no sort");
    STAssertTrue([v dateInColumnWithIndex:dateCol atRowIndex:2] == [dateFirst timeIntervalSince1970], @"matcing value after no sort");
    
    // Sort same way without order specified. Ascending default
    [v sortUsingColumnWithIndex:dateCol];
    STAssertTrue([v dateInColumnWithIndex:dateCol atRowIndex:0] == [dateFirst timeIntervalSince1970], @"matcing value after default sort");
    STAssertTrue([v dateInColumnWithIndex:dateCol atRowIndex:1] == [dateMiddle timeIntervalSince1970], @"matcing value after default sort");
    STAssertTrue([v dateInColumnWithIndex:dateCol atRowIndex:2] == [dateLast timeIntervalSince1970], @"matcing value after default sort");
    
    // Sort same way
    [v sortUsingColumnWithIndex:dateCol inOrder:TDBAscending];
    STAssertTrue([v dateInColumnWithIndex:dateCol atRowIndex:0] == [dateFirst timeIntervalSince1970], @"matcing value after ascending sort");
    STAssertTrue([v dateInColumnWithIndex:dateCol atRowIndex:1] == [dateMiddle timeIntervalSince1970], @"matcing value after ascending sort");
    STAssertTrue([v dateInColumnWithIndex:dateCol atRowIndex:2] == [dateLast timeIntervalSince1970], @"matcing value after ascending sort");
    
    // Sort descending
    [v sortUsingColumnWithIndex:dateCol inOrder: TDBDescending];
    STAssertTrue([v dateInColumnWithIndex:dateCol atRowIndex:0] == [dateLast timeIntervalSince1970], @"matcing value after descending sort");
    STAssertTrue([v dateInColumnWithIndex:dateCol atRowIndex:1] == [dateMiddle timeIntervalSince1970], @"matcing value after descending sort");
    STAssertTrue([v dateInColumnWithIndex:dateCol atRowIndex:2] == [dateFirst timeIntervalSince1970], @"matcing value after descending sort");
}


- (void)testSortOnAllColumnTypes
{
    TDBTable *t = [[TDBTable alloc] init];
    
    NSUInteger boolCol      = [t addColumnWithName:@"boolCol" andType:TDBBoolType];
    NSUInteger binaryCol    = [t addColumnWithName:@"binaryCol" andType:TDBBinaryType];
    NSUInteger dateCol      = [t addColumnWithName:@"dateCol" andType:TDBDateType];
    NSUInteger doubleCol    = [t addColumnWithName:@"doubleCol" andType:TDBDoubleType];
    NSUInteger floatCol     = [t addColumnWithName:@"floatCol" andType:TDBFloatType];
    NSUInteger intCol       = [t addColumnWithName:@"intCol" andType:TDBIntType];
    NSUInteger mixedCol     = [t addColumnWithName:@"MixedCol" andType:TDBMixedType];
    NSUInteger stringCol    = [t addColumnWithName:@"stringCol" andType:TDBStringType];
    NSUInteger tableCol     = [t addColumnWithName:@"tableCol" andType:TDBTableType];
    
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

@end
