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

TIGHTDB_TABLE_1(TestTableSub,
                Age,  Int)

TIGHTDB_TABLE_9(TestTableAllTypes,
                BoolCol,   Bool,
                IntCol,    Int,
                FloatCol,  Float,
                DoubleCol, Double,
                StringCol, String,
                BinaryCol, Binary,
                DateCol,   Date,
                TableCol,  TestTableSub,
                MixedCol,  Mixed)

@interface MACTestTable: SenTestCase
  // Intentionally left blank.
  // No new public instance methods need be defined.
@end

@implementation MACTestTable

- (void)testTable
{
    TightdbTable* _table = [[TightdbTable alloc] init];
    NSLog(@"Table: %@", _table);
    STAssertNotNil(_table, @"Table is nil");

    // 1. Add two columns
    [_table addColumnWithType:tightdb_Int andName:@"first"];
    [_table addColumnWithType:tightdb_Int andName:@"second"];

    // Verify
    STAssertEquals(tightdb_Int, [_table getColumnType:0], @"First column not int");
    STAssertEquals(tightdb_Int, [_table getColumnType:1], @"Second column not int");
    if (![[_table getColumnName:0] isEqualToString:@"first"])
        STFail(@"First not equal to first");
    if (![[_table getColumnName:1] isEqualToString:@"second"])
        STFail(@"Second not equal to second");

    // 2. Add a row with data

    //const size_t ndx = [_table addRow];
    //[_table set:0 ndx:ndx value:0];
    //[_table set:1 ndx:ndx value:10];

    TightdbCursor* cursor = [_table addRow];
    size_t ndx = [cursor index];
    [cursor setInt:0 inColumn:0];
    [cursor setInt:10 inColumn:1];


    // Verify
    if ([_table get:0 ndx:ndx] != 0)
        STFail(@"First not zero");
    if ([_table get:1 ndx:ndx] != 10)
        STFail(@"Second not 10");


}

- (void)testDataTypes_Typed
{
    TestTableAllTypes* table = [[TestTableAllTypes alloc] init];
    NSLog(@"Table: %@", table);
    STAssertNotNil(table, @"Table is nil");

    // Verify column types
    STAssertEquals(tightdb_Bool,   [table getColumnType:0], @"First column not bool");
    STAssertEquals(tightdb_Int,    [table getColumnType:1], @"Second column not int");
    STAssertEquals(tightdb_Float,  [table getColumnType:2], @"Third column not float");
    STAssertEquals(tightdb_Double, [table getColumnType:3], @"Fourth column not double");
    STAssertEquals(tightdb_String, [table getColumnType:4], @"Fifth column not string");
    STAssertEquals(tightdb_Binary, [table getColumnType:5], @"Sixth column not binary");
    STAssertEquals(tightdb_Date,   [table getColumnType:6], @"Seventh column not date");
    STAssertEquals(tightdb_Table,  [table getColumnType:7], @"Eighth column not table");
    STAssertEquals(tightdb_Mixed,  [table getColumnType:8], @"Ninth column not mixed");

    const char bin[4] = { 0, 1, 2, 3 };
    TightdbBinary* bin1 = [[TightdbBinary alloc] initWithData:bin size:sizeof bin / 2];
    TightdbBinary* bin2 = [[TightdbBinary alloc] initWithData:bin size:sizeof bin];
    time_t timeNow = [[NSDate date] timeIntervalSince1970];
    TestTableSub* subtab1 = [[TestTableSub alloc] init];
    TestTableSub* subtab2 = [[TestTableSub alloc] init];
    [subtab1 addAge:200];
    [subtab2 addAge:100];
    TightdbMixed* mixInt1   = [TightdbMixed mixedWithInt64:1];
    TightdbMixed* mixSubtab = [TightdbMixed mixedWithTable:subtab2];

    TestTableAllTypes_Cursor* c;

    c = [table addRow];

        c.BoolCol   = NO   ; c.IntCol  = 54 ; c.FloatCol = 0.7     ; c.DoubleCol = 0.8     ; c.StringCol = @"foo";
        c.BinaryCol = bin1 ; c.DateCol = 0  ; c.TableCol = subtab1     ; c.MixedCol  = mixInt1 ;

    c = [table addRow];

        c.BoolCol   = YES  ; c.IntCol  = 506     ; c.FloatCol = 7.7         ; c.DoubleCol = 8.8       ; c.StringCol = @"banach";
        c.BinaryCol = bin2 ; c.DateCol = timeNow ; c.TableCol = subtab2     ; c.MixedCol  = mixSubtab ;

    TestTableAllTypes_Cursor* row1 = [table cursorAtIndex:0];
    TestTableAllTypes_Cursor* row2 = [table cursorAtIndex:1];

    STAssertEquals(row1.BoolCol, NO,                 @"row1.BoolCol");
    STAssertEquals(row2.BoolCol, YES,                @"row2.BoolCol");
    STAssertEquals(row1.IntCol, (int64_t)54,         @"row1.IntCol");
    STAssertEquals(row2.IntCol, (int64_t)506,        @"row2.IntCol");
    STAssertEquals(row1.FloatCol, 0.7f,              @"row1.FloatCol");
    STAssertEquals(row2.FloatCol, 7.7f,              @"row2.FloatCol");
    STAssertEquals(row1.DoubleCol, 0.8,              @"row1.DoubleCol");
    STAssertEquals(row2.DoubleCol, 8.8,              @"row2.DoubleCol");
    STAssertTrue([row1.StringCol isEqual:@"foo"],    @"row1.StringCol");
    STAssertTrue([row2.StringCol isEqual:@"banach"], @"row2.StringCol");
    STAssertTrue([row1.BinaryCol isEqual:bin1],      @"row1.BinaryCol");
    STAssertTrue([row2.BinaryCol isEqual:bin2],      @"row2.BinaryCol");
    STAssertEquals(row1.DateCol, (time_t)0,          @"row1.DateCol");
    STAssertEquals(row2.DateCol, timeNow,            @"row2.DateCol");
    STAssertTrue([row1.TableCol isEqual:subtab1],    @"row1.TableCol");
    STAssertTrue([row2.TableCol isEqual:subtab2],    @"row2.TableCol");
    STAssertTrue([row1.MixedCol isEqual:mixInt1],    @"row1.MixedCol");
    STAssertTrue([row2.MixedCol isEqual:mixSubtab],  @"row2.MixedCol");

    STAssertEquals([table.IntCol minimum], (int64_t)54,                 @"IntCol min");
    STAssertEquals([table.IntCol maximum], (int64_t)506,                @"IntCol max");
    STAssertEquals([table.IntCol sum], (int64_t)560,                @"IntCol sum");
    STAssertEquals([table.IntCol average], 280.0,                       @"IntCol avg");

    STAssertEquals([table.FloatCol minimum], 0.7f,                      @"FloatCol min");
    STAssertEquals([table.FloatCol maximum], 7.7f,                      @"FloatCol max");
    STAssertEquals([table.FloatCol sum], (double)0.7f + 7.7f,       @"FloatCol sum");
    STAssertEquals([table.FloatCol average], ((double)0.7f + 7.7f) / 2, @"FloatCol avg");

    STAssertEquals([table.DoubleCol minimum], 0.8,                      @"DoubleCol min");
    STAssertEquals([table.DoubleCol maximum], 8.8,                      @"DoubleCol max");
    STAssertEquals([table.DoubleCol sum], 0.8 + 8.8,                @"DoubleCol sum");
    STAssertEquals([table.DoubleCol average], (0.8 + 8.8) / 2,          @"DoubleCol avg");
}

- (void)testDataTypes_Dynamic
{
    TightdbTable* table = [[TightdbTable alloc] init];
    NSLog(@"Table: %@", table);
    STAssertNotNil(table, @"Table is nil");

    TightdbDescriptor* desc = [table getDescriptor];

    [desc addColumnWithType:tightdb_Bool   andName:@"BoolCol"];    const size_t BoolCol = 0;
    [desc addColumnWithType:tightdb_Int    andName:@"IntCol"];     const size_t IntCol = 1;
    [desc addColumnWithType:tightdb_Float  andName:@"FloatCol"];   const size_t FloatCol = 2;
    [desc addColumnWithType:tightdb_Double andName:@"DoubleCol"];  const size_t DoubleCol = 3;
    [desc addColumnWithType:tightdb_String andName:@"StringCol"];  const size_t StringCol = 4;
    [desc addColumnWithType:tightdb_Binary andName:@"BinaryCol"];  const size_t BinaryCol = 5;
    [desc addColumnWithType:tightdb_Date   andName:@"DateCol"];    const size_t DateCol = 6;
    TightdbDescriptor* subdesc = [desc addColumnTable:@"TableCol"]; const size_t TableCol = 7;
    [desc addColumnWithType:tightdb_Mixed  andName:@"MixedCol"];   const size_t MixedCol = 8;

    [subdesc addColumnWithType:tightdb_Int andName:@"TableCol_IntCol"];

    // Verify column types
    STAssertEquals(tightdb_Bool,   [table getColumnType:0], @"First column not bool");
    STAssertEquals(tightdb_Int,    [table getColumnType:1], @"Second column not int");
    STAssertEquals(tightdb_Float,  [table getColumnType:2], @"Third column not float");
    STAssertEquals(tightdb_Double, [table getColumnType:3], @"Fourth column not double");
    STAssertEquals(tightdb_String, [table getColumnType:4], @"Fifth column not string");
    STAssertEquals(tightdb_Binary, [table getColumnType:5], @"Sixth column not binary");
    STAssertEquals(tightdb_Date,   [table getColumnType:6], @"Seventh column not date");
    STAssertEquals(tightdb_Table,  [table getColumnType:7], @"Eighth column not table");
    STAssertEquals(tightdb_Mixed,  [table getColumnType:8], @"Ninth column not mixed");


    const char bin[4] = { 0, 1, 2, 3 };
    TightdbBinary* bin1 = [[TightdbBinary alloc] initWithData:bin size:sizeof bin / 2];
    TightdbBinary* bin2 = [[TightdbBinary alloc] initWithData:bin size:sizeof bin];
    time_t timeNow = [[NSDate date] timeIntervalSince1970];



    TightdbTable* subtab1 = [[TightdbTable alloc] init];
    [subtab1 addColumnWithType:tightdb_Int andName:@"TableCol_IntCol"];

    TightdbTable* subtab2 = [[TightdbTable alloc] init];
    [subtab2 addColumnWithType:tightdb_Int andName:@"TableCol_IntCol"];


    TightdbCursor* cursor;



    cursor = [subtab1 addRow];
    [cursor setInt:200 inColumn:0];



    cursor = [subtab2 addRow];
    [cursor setInt:100 inColumn:0];



    TightdbMixed* mixInt1   = [TightdbMixed mixedWithInt64:1];
    TightdbMixed* mixSubtab = [TightdbMixed mixedWithTable:subtab2];

    TightdbCursor* c;



    c = [table addRow];



    [c setBool:    NO        inColumn:BoolCol];
    [c setInt:     54        inColumn:IntCol];
    [c setFloat:   0.7       inColumn:FloatCol];
    [c setDouble:  0.8       inColumn:DoubleCol];
    [c setString:  @"foo"    inColumn:StringCol];
    [c setBinary:  bin1      inColumn:BinaryCol];
    [c setDate:    0         inColumn:DateCol];
    [c setTable:   subtab1   inColumn:TableCol];
    [c setMixed:   mixInt1   inColumn:MixedCol];

    c = [table addRow];

    [c setBool:    YES       inColumn:BoolCol];
    [c setInt:     506       inColumn:IntCol];
    [c setFloat:   7.7       inColumn:FloatCol];
    [c setDouble:  8.8       inColumn:DoubleCol];
    [c setString:  @"banach" inColumn:StringCol];
    [c setBinary:  bin2      inColumn:BinaryCol];
    [c setDate:    timeNow   inColumn:DateCol];
    [c setTable:   subtab2   inColumn:TableCol];
    [c setMixed:   mixSubtab inColumn:MixedCol];

    TightdbCursor* row1 = [table cursorAtIndex:0];
    TightdbCursor* row2 = [table cursorAtIndex:1];

    STAssertEquals([row1 getBoolInColumn:BoolCol], NO, @"row1.BoolCol");
    STAssertEquals([row2 getBoolInColumn:BoolCol], YES,                @"row2.BoolCol");
    STAssertEquals([row1 getIntInColumn:IntCol], (int64_t)54,         @"row1.IntCol");
    STAssertEquals([row2 getIntInColumn:IntCol], (int64_t)506,        @"row2.IntCol");
    STAssertEquals([row1 getFloatInColumn:FloatCol], 0.7f,              @"row1.FloatCol");
    STAssertEquals([row2 getFloatInColumn:FloatCol], 7.7f,              @"row2.FloatCol");
    STAssertEquals([row1 getDoubleInColumn:DoubleCol], 0.8,              @"row1.DoubleCol");
    STAssertEquals([row2 getDoubleInColumn:DoubleCol], 8.8,              @"row2.DoubleCol");
    STAssertTrue([[row1 getStringInColumn:StringCol] isEqual:@"foo"],    @"row1.StringCol");
    STAssertTrue([[row2 getStringInColumn:StringCol] isEqual:@"banach"], @"row2.StringCol");
    STAssertTrue([[row1 getBinaryInColumn:BinaryCol] isEqual:bin1],      @"row1.BinaryCol");
    STAssertTrue([[row2 getBinaryInColumn:BinaryCol] isEqual:bin2],      @"row2.BinaryCol");
    STAssertEquals([row1 getDateInColumn:DateCol], (time_t)0,          @"row1.DateCol");
    STAssertEquals([row2 getDateInColumn:DateCol], timeNow,            @"row2.DateCol");
    STAssertTrue([[row1 getTableInColumn:TableCol] isEqual:subtab1],    @"row1.TableCol");
    STAssertTrue([[row2 getTableInColumn:TableCol] isEqual:subtab2],    @"row2.TableCol");
    STAssertTrue([[row1 getMixedInColumn:MixedCol] isEqual:mixInt1],    @"row1.MixedCol");
    STAssertTrue([[row2 getMixedInColumn:MixedCol] isEqual:mixSubtab],  @"row2.MixedCol");

    STAssertEquals([table minimumWithIntColumn:IntCol], (int64_t)54,                 @"IntCol min");
    STAssertEquals([table maximumWithIntColumn:IntCol], (int64_t)506,                @"IntCol max");
    STAssertEquals([table sumWithIntColumn:IntCol], (int64_t)560,                @"IntCol sum");
    STAssertEquals([table averageWithIntColumn:IntCol], 280.0,                       @"IntCol avg");

    STAssertEquals([table minimumWithFloatColumn:FloatCol], 0.7f,                      @"FloatCol min");
    STAssertEquals([table maximumWithFloatColumn:FloatCol], 7.7f,                      @"FloatCol max");
    STAssertEquals([table sumWithFloatColumn:FloatCol], (double)0.7f + 7.7f,       @"FloatCol sum");
    STAssertEquals([table averageWithFloatColumn:FloatCol], ((double)0.7f + 7.7f) / 2, @"FloatCol avg");

    STAssertEquals([table minimumWithDoubleColumn:DoubleCol], 0.8,                      @"DoubleCol min");
    STAssertEquals([table maximumWithDoubleColumn:DoubleCol], 8.8,                      @"DoubleCol max");
    STAssertEquals([table sumWithDoubleColumn:DoubleCol], 0.8 + 8.8,                @"DoubleCol sum");
    STAssertEquals([table averageWithDoubleColumn:DoubleCol], (0.8 + 8.8) / 2,          @"DoubleCol avg");


}

@end
