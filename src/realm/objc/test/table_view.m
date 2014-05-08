////////////////////////////////////////////////////////////////////////////
//
// TIGHTDB CONFIDENTIAL
// __________________
//
//  [2011] - [2014] TightDB Inc
//  All Rights Reserved.
//
// NOTICE:  All information contained herein is, and remains
// the property of TightDB Incorporated and its suppliers,
// if any.  The intellectual and technical concepts contained
// herein are proprietary to TightDB Incorporated
// and its suppliers and may be covered by U.S. and Foreign Patents,
// patents in process, and are protected by trade secret or copyright law.
// Dissemination of this information or reproduction of this material
// is strictly forbidden unless prior written permission is obtained
// from TightDB Incorporated.
//
////////////////////////////////////////////////////////////////////////////

#import "RLMTestCase.h"

#import <realm/objc/RLMFast.h>
#import <realm/objc/RLMTableFast.h>
#import <realm/objc/RLMViewFast.h>

@interface RLMRealmTests : RLMTestCase

@end

@interface JSONTableViewTestType : RLMRow

@property BOOL      boolColumn;
@property int       intColumn;
@property float     floatColumn;
@property double    doubleColumn;
@property NSString  *stringColumn;
@property NSData    *binaryColumn;
@property NSDate    *dateColumn;
@property id        mixedColumn;

@end

@implementation JSONTableViewTestType
@end

RLM_TABLE_TYPE_FOR_OBJECT_TYPE(JSONTableViewTestTable, JSONTableViewTestType)

@interface table_view : RLMTestCase

@end

@implementation table_view

-(void)testGetColumnCount
{
    [self createTestTableWithWriteBlock:^(RLMTable *table) {
        RLMQuery *q = [table where];
        RLMView *v = [q findAllRows];
        
        XCTAssertEqual((NSUInteger)0, [v columnCount], @"no columns added yet");
        
        [table addColumnWithName:@"col0" type:RLMTypeInt];
        XCTAssertEqual([v columnCount],(NSUInteger)1,  @"1 column added to table");
        
        for (int i=0;i<10;i++) {
            [table addColumnWithName:@"name" type:RLMTypeInt];
        }
        XCTAssertEqual([v columnCount],(NSUInteger)11,  @"10 more columns added to table");
        
        [table removeColumnWithIndex:0];
        XCTAssertEqual([v columnCount],(NSUInteger)10, @"1 column removed from table");
    }];
}

- (void)testColumnTypesOnView
{
    [self createTestTableWithWriteBlock:^(RLMTable *table) {
        NSUInteger boolCol   = [table addColumnWithName:@"boolCol"   type:RLMTypeBool];
        NSUInteger binaryCol = [table addColumnWithName:@"binaryCol" type:RLMTypeBinary];
        NSUInteger dateCol   = [table addColumnWithName:@"dateCol"   type:RLMTypeDate];
        NSUInteger doubleCol = [table addColumnWithName:@"doubleCol" type:RLMTypeDouble];
        NSUInteger floatCol  = [table addColumnWithName:@"floatCol"  type:RLMTypeFloat];
        NSUInteger intCol    = [table addColumnWithName:@"intCol"    type:RLMTypeInt];
        NSUInteger mixedCol  = [table addColumnWithName:@"MixedCol"  type:RLMTypeMixed];
        NSUInteger stringCol = [table addColumnWithName:@"stringCol" type:RLMTypeString];
        NSUInteger tableCol  = [table addColumnWithName:@"tableCol"  type:RLMTypeTable];
        
        
        RLMQuery *q = [table where];
        RLMView *v = [q findAllRows];
        
        XCTAssertTrue([v columnTypeOfColumnWithIndex:boolCol]   == RLMTypeBool,   @"Column types matches");
        XCTAssertTrue([v columnTypeOfColumnWithIndex:binaryCol] == RLMTypeBinary, @"Column types matches");
        XCTAssertTrue([v columnTypeOfColumnWithIndex:dateCol]   == RLMTypeDate,   @"Column types matches");
        XCTAssertTrue([v columnTypeOfColumnWithIndex:doubleCol] == RLMTypeDouble, @"Column types matches");
        XCTAssertTrue([v columnTypeOfColumnWithIndex:floatCol]  == RLMTypeFloat,  @"Column types matches");
        XCTAssertTrue([v columnTypeOfColumnWithIndex:intCol]    == RLMTypeInt,    @"Column types matches");
        XCTAssertTrue([v columnTypeOfColumnWithIndex:mixedCol]  == RLMTypeMixed,  @"Column types matches");
        XCTAssertTrue([v columnTypeOfColumnWithIndex:stringCol] == RLMTypeString, @"Column types matches");
        XCTAssertTrue([v columnTypeOfColumnWithIndex:tableCol]  == RLMTypeTable,  @"Column types matches");
        
        XCTAssertThrows([v columnTypeOfColumnWithIndex:[v columnCount] + 1], @"Out of bounds");
        XCTAssertThrows([v columnTypeOfColumnWithIndex:100], @"Out of bounds");
        XCTAssertThrows([v columnTypeOfColumnWithIndex:-1], @"Out of bounds");
    }];
}

- (void)testSortOnViewIntColumn
{
    [self createTestTableWithWriteBlock:^(RLMTable *table) {
        NSUInteger intCol = [table addColumnWithName:@"intCol" type:RLMTypeInt];
        
        [table addRow:nil];
        RLMRow *row = [table lastRow];
        [row setInt:2 inColumnWithIndex:intCol];
        
        [table addRow:nil];
        row = [table lastRow];
        [row setInt:1 inColumnWithIndex:intCol];
        
        [table addRow:nil];
        row = [table lastRow];
        [row setInt:0 inColumnWithIndex:intCol];
        
        RLMQuery *q = [table where];
        RLMView *v = [q findAllRows];
        
        // Not yet sorted
        XCTAssertTrue([v RLM_intInColumnWithIndex:intCol atRowIndex:0] == 2, @"matcing value after no sort");
        XCTAssertTrue([v RLM_intInColumnWithIndex:intCol atRowIndex:1] == 1, @"matcing value after no sort");
        XCTAssertTrue([v RLM_intInColumnWithIndex:intCol atRowIndex:2] == 0, @"matcing value after no sort");
        
        // Sort same way without order specified. Ascending default
        [v sortUsingColumnWithIndex:intCol];
        XCTAssertTrue([v RLM_intInColumnWithIndex:intCol atRowIndex:0] == 0, @"matcing value after default sort");
        XCTAssertTrue([v RLM_intInColumnWithIndex:intCol atRowIndex:1] == 1, @"matcing value after default sort");
        XCTAssertTrue([v RLM_intInColumnWithIndex:intCol atRowIndex:2] == 2, @"matcing value after default sort");
        
        // Sort same way
        [v sortUsingColumnWithIndex:intCol inOrder:RLMSortOrderAscending];
        XCTAssertTrue([v RLM_intInColumnWithIndex:intCol atRowIndex:0] == 0, @"matcing value after ascending sort");
        XCTAssertTrue([v RLM_intInColumnWithIndex:intCol atRowIndex:1] == 1, @"matcing value after ascending sort");
        XCTAssertTrue([v RLM_intInColumnWithIndex:intCol atRowIndex:2] == 2, @"matcing value after ascending sort");
        
        // Sort descending
        [v sortUsingColumnWithIndex:intCol inOrder: RLMSortOrderDescending];
        XCTAssertTrue([v RLM_intInColumnWithIndex:intCol atRowIndex:0] == 2, @"matcing value after descending sort");
        XCTAssertTrue([v RLM_intInColumnWithIndex:intCol atRowIndex:1] == 1, @"matcing value after descending sort");
        XCTAssertTrue([v RLM_intInColumnWithIndex:intCol atRowIndex:2] == 0, @"matcing value after descending sort");
    }];
}

- (void)testSortOnViewBoolColumn
{
    [self createTestTableWithWriteBlock:^(RLMTable *table) {
        NSUInteger boolCol = [table addColumnWithName:@"boolCol" type:RLMTypeBool];
        
        [table addRow:nil];
        RLMRow *row = [table lastRow];
        [row setBool:YES inColumnWithIndex:boolCol];
        
        [table addRow:nil];
        row = [table lastRow];
        [row setBool:YES inColumnWithIndex:boolCol];
        
        [table addRow:nil];
        row = [table lastRow];
        [row setBool:NO inColumnWithIndex:boolCol];
        
        RLMQuery *q = [table where];
        RLMView *v = [q findAllRows];
        
        // Not yet sorted
        XCTAssertTrue([v RLM_boolInColumnWithIndex:boolCol atRowIndex:0] == YES, @"matcing value after no sort");
        XCTAssertTrue([v RLM_boolInColumnWithIndex:boolCol atRowIndex:1] == YES, @"matcing value after no sort");
        XCTAssertTrue([v RLM_boolInColumnWithIndex:boolCol atRowIndex:2] == NO, @"matcing value after no sort");
        
        // Sort same way without order specified. Ascending default
        [v sortUsingColumnWithIndex:boolCol];
        XCTAssertTrue([v RLM_boolInColumnWithIndex:boolCol atRowIndex:0] == NO, @"matcing value after default sort");
        XCTAssertTrue([v RLM_boolInColumnWithIndex:boolCol atRowIndex:1] == YES, @"matcing value after default sort");
        XCTAssertTrue([v RLM_boolInColumnWithIndex:boolCol atRowIndex:2] == YES, @"matcing value after default sort");
        
        // Sort same way
        [v sortUsingColumnWithIndex:boolCol inOrder:RLMSortOrderAscending];
        XCTAssertTrue([v RLM_boolInColumnWithIndex:boolCol atRowIndex:0] == NO, @"matcing value after ascending sort");
        XCTAssertTrue([v RLM_boolInColumnWithIndex:boolCol atRowIndex:1] == YES, @"matcing value after ascending sort");
        XCTAssertTrue([v RLM_boolInColumnWithIndex:boolCol atRowIndex:2] == YES, @"matcing value after ascending sort");
        
        // Sort descending
        [v sortUsingColumnWithIndex:boolCol inOrder: RLMSortOrderDescending];
        XCTAssertTrue([v RLM_boolInColumnWithIndex:boolCol atRowIndex:0] == YES, @"matcing value after descending sort");
        XCTAssertTrue([v RLM_boolInColumnWithIndex:boolCol atRowIndex:1] == YES, @"matcing value after descending sort");
        XCTAssertTrue([v RLM_boolInColumnWithIndex:boolCol atRowIndex:2] == NO, @"matcing value after descending sort");
    }];
}


- (void)testSortOnViewDateColumn
{
    [self createTestTableWithWriteBlock:^(RLMTable *table) {
        NSUInteger dateCol = [table addColumnWithName:@"dateCol" type:RLMTypeDate];
        
        NSDate *dateFirst  = [NSDate dateWithTimeIntervalSince1970:0];
        NSDate *dateMiddle = [NSDate dateWithTimeIntervalSince1970:1];
        NSDate *dateLast   = [NSDate dateWithTimeIntervalSince1970:2];
        
        [table addRow:nil];
        RLMRow *row = [table lastRow];
        [row setDate:dateLast inColumnWithIndex:dateCol];
        
        [table addRow:nil];
        row = [table lastRow];
        [row setDate:dateMiddle inColumnWithIndex:dateCol];
        
        [table addRow:nil];
        row = [table lastRow];
        [row setDate:dateFirst inColumnWithIndex:dateCol];
        
        RLMQuery *q = [table where];
        RLMView *v = [q findAllRows];
        
        // Not yet sorted
        XCTAssertTrue([v RLM_dateInColumnWithIndex:dateCol atRowIndex:0] == dateLast, @"matcing value after no sort");
        XCTAssertTrue([v RLM_dateInColumnWithIndex:dateCol atRowIndex:1] == dateMiddle, @"matcing value after no sort");
        XCTAssertTrue([v RLM_dateInColumnWithIndex:dateCol atRowIndex:2] == dateFirst, @"matcing value after no sort");
        
        // Sort same way without order specified. Ascending default
        [v sortUsingColumnWithIndex:dateCol];
        XCTAssertTrue([v RLM_dateInColumnWithIndex:dateCol atRowIndex:0] == dateFirst, @"matcing value after default sort");
        XCTAssertTrue([v RLM_dateInColumnWithIndex:dateCol atRowIndex:1] == dateMiddle, @"matcing value after default sort");
        XCTAssertTrue([v RLM_dateInColumnWithIndex:dateCol atRowIndex:2] == dateLast, @"matcing value after default sort");
        
        // Sort same way
        [v sortUsingColumnWithIndex:dateCol inOrder:RLMSortOrderAscending];
        XCTAssertTrue([v RLM_dateInColumnWithIndex:dateCol atRowIndex:0] == dateFirst, @"matcing value after ascending sort");
        XCTAssertTrue([v RLM_dateInColumnWithIndex:dateCol atRowIndex:1] == dateMiddle, @"matcing value after ascending sort");
        XCTAssertTrue([v RLM_dateInColumnWithIndex:dateCol atRowIndex:2] == dateLast, @"matcing value after ascending sort");
        
        // Sort descending
        [v sortUsingColumnWithIndex:dateCol inOrder: RLMSortOrderDescending];
        XCTAssertTrue([v RLM_dateInColumnWithIndex:dateCol atRowIndex:0] == dateLast, @"matcing value after descending sort");
        XCTAssertTrue([v RLM_dateInColumnWithIndex:dateCol atRowIndex:1] == dateMiddle, @"matcing value after descending sort");
        XCTAssertTrue([v RLM_dateInColumnWithIndex:dateCol atRowIndex:2] == dateFirst, @"matcing value after descending sort");
    }];
}


- (void)testSortOnAllColumnTypes
{
    [self createTestTableWithWriteBlock:^(RLMTable *table) {
        NSUInteger boolCol   = [table addColumnWithName:@"boolCol"   type:RLMTypeBool];
        NSUInteger binaryCol = [table addColumnWithName:@"binaryCol" type:RLMTypeBinary];
        NSUInteger dateCol   = [table addColumnWithName:@"dateCol"   type:RLMTypeDate];
        NSUInteger doubleCol = [table addColumnWithName:@"doubleCol" type:RLMTypeDouble];
        NSUInteger floatCol  = [table addColumnWithName:@"floatCol"  type:RLMTypeFloat];
        NSUInteger intCol    = [table addColumnWithName:@"intCol"    type:RLMTypeInt];
        NSUInteger mixedCol  = [table addColumnWithName:@"MixedCol"  type:RLMTypeMixed];
        NSUInteger stringCol = [table addColumnWithName:@"stringCol" type:RLMTypeString];
        NSUInteger tableCol  = [table addColumnWithName:@"tableCol"  type:RLMTypeTable];
        
        RLMQuery *q = [table where];
        RLMView *v = [q findAllRows];
        
        [v sortUsingColumnWithIndex:boolCol]; // bool is supported
        XCTAssertThrows([v sortUsingColumnWithIndex:binaryCol], @"Not supported on binary column");
        [v sortUsingColumnWithIndex:dateCol]; // bool is supported
        XCTAssertThrows([v sortUsingColumnWithIndex:doubleCol], @"Not supported on double column");
        XCTAssertThrows([v sortUsingColumnWithIndex:floatCol], @"Not supported on float column");
        [v sortUsingColumnWithIndex:intCol]; // int is supported
        XCTAssertThrows([v sortUsingColumnWithIndex:mixedCol], @"Not supported on mixed column");
        XCTAssertThrows([v sortUsingColumnWithIndex:stringCol], @"Not supported on string column");
        XCTAssertThrows([v sortUsingColumnWithIndex:tableCol], @"Not supported on table column");
    }];
}

- (void)testFirstLastRow
{
    [self createTestTableWithWriteBlock:^(RLMTable *table) {
        NSUInteger col0 = [table addColumnWithName:@"col" type:RLMTypeString];
        NSUInteger col1 = [table addColumnWithName:@"col" type:RLMTypeInt];
        
        RLMView *v = [[table where] findAllRows];
        
        XCTAssertNil([v firstRow], @"Table is empty");
        XCTAssertNil([v lastRow], @"Table is empty");
        
        // add empty rows before to filter out
        [table addRow:nil];
        [table addRow:nil];
        [table addRow:nil];
        
        NSString *value0 = @"value0";
        [table addRow:@[value0, @1]];
        
        NSString *value1 = @"value1";
        [table addRow:@[value1, @1]];
        
        // add empty rows after to filter out
        [table addRow:nil];
        [table addRow:nil];
        [table addRow:nil];
        
        v = [[[table where] intIsEqualTo:1 inColumnWithIndex:col1] findAllRows];
        
        XCTAssertEqualObjects(value0, [[v firstRow] stringInColumnWithIndex:col0], @"");
        XCTAssertEqualObjects(value1, [[v lastRow] stringInColumnWithIndex:col0], @"");
    }];
}

- (void)testViewSubscripting
{
    [self createTestTableWithWriteBlock:^(RLMTable *table) {
        [table addColumnWithName:@"IntCol" type:RLMTypeInt];
        
        [table addRow:@[@10]];
        [table addRow:@[@42]];
        [table addRow:@[@27]];
        [table addRow:@[@31]];
        [table addRow:@[@8]];
        [table addRow:@[@39]];
        
        RLMView* view = [[[table where] intIsLessThanOrEqualTo:30 inColumnWithIndex:0] findAllRows];
        
        XCTAssertEqual(view.rowCount, (NSUInteger)3, @"found 3 matches");
        
        XCTAssertTrue([view[0][0] isEqual:@10], @"row 0 -> 0");
        XCTAssertTrue([view[1][0] isEqual:@27], @"row 1 -> 2");
        XCTAssertTrue([view[2][0] isEqual:@8],  @"row 2 -> 4");
    }];
}

- (void)testQueryOnView
{
    [self createTestTableWithWriteBlock:^(RLMTable *table) {
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
        
        
        RLMView *view = [[table where] findAllRows];
        XCTAssertEqual(view.rowCount, (NSUInteger)5, @"All 5 rows still here");
        
        RLMView *view2 = [[[view where ] stringIsCaseInsensitiveEqualTo:@"John" inColumnWithIndex:0 ] findAllRows];
        XCTAssertEqual(view2.rowCount, (NSUInteger)2, @"2 rows match");
        
        RLMView *view3 = [[[view2 where] stringIsCaseInsensitiveEqualTo:@"Anderson" inColumnWithIndex:1 ] findAllRows];
        XCTAssertEqual(view3.rowCount, (NSUInteger)1, @"Only 1 row left");
    }];
}

- (void)testToJSONString {
    
    [[self realmWithTestPath] writeUsingBlock:^(RLMRealm *realm) {
        JSONTableViewTestTable *table = [JSONTableViewTestTable tableInRealm:realm
                                                                       named:@"test"];
        
        const char bin[4] = { 0, 1, 2, 3 };
        NSData *binary = [[NSData alloc] initWithBytes:bin length:sizeof bin];
        
        NSDate *date = (NSDate *)[NSDate dateWithString:@"2014-05-17 13:15:10 +0100"];
        [table addRow:@[@YES, @1234, @((float)12.34), @1234.5678, @"I'm just a String", binary, @((int)[date timeIntervalSince1970]), @"I'm also a string in a mixed column"]];
        
        RLMView *view = [[table where] findAllRows];
        
        NSString *result = [view toJSONString];
        
        XCTAssertEqualObjects(result, @"[{\"boolColumn\":true,\"intColumn\":1234,\"floatColumn\":1.2340000e+01,\"doubleColumn\":1.2345678000000000e+03,\"stringColumn\":\"I'm just a String\",\"binaryColumn\":\"00010203\",\"dateColumn\":\"2014-05-17 12:15:10\",\"mixedColumn\":\"I'm also a string in a mixed column\"}]", @"JSON string expected to one 8-column row");
    }];
}
// JSONTableViewTestTable
@end
