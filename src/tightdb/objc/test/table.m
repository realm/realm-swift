//
//  table.m
//  TightDB
//

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

@interface MACtestTable: SenTestCase
@end
@implementation MACtestTable

- (void)testTable
{
    TightdbTable *_table = [[TightdbTable alloc] init];
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

    TightdbCursor *cursor = [_table addRow];
    size_t ndx = [cursor index];
    [cursor setInt:0 inColumn:0];
    [cursor setInt:10 inColumn:1];


    // Verify
    if ([_table get:0 ndx:ndx] != 0)
        STFail(@"First not zero");
    if ([_table get:1 ndx:ndx] != 10)
        STFail(@"Second not 10");


}

- (void)testDataTypes
{
    TestTableAllTypes *table = [[TestTableAllTypes alloc] init];
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
    TightdbBinary *bin1 = [[TightdbBinary alloc] initWithData:bin size:sizeof bin / 2];
    TightdbBinary *bin2 = [[TightdbBinary alloc] initWithData:bin size:sizeof bin];
    time_t timeNow = [[NSDate date] timeIntervalSince1970];
    //TestTableSub *subtab1 = [[TestTableSub alloc] init];
    TestTableSub *subtab2 = [[TestTableSub alloc] init];
    [subtab2 addAge:100];
    TightdbMixed *mixInt1   = [TightdbMixed mixedWithInt64:1];
    TightdbMixed *mixSubtab = [TightdbMixed mixedWithTable:subtab2];

    /* jjepsen: this method for adding rows is obsolete, see curser based method below.
    
    [table addBoolCol:NO   IntCol:54       FloatCol:0.7     DoubleCol:0.8       StringCol:@"foo"
            BinaryCol:bin1 DateCol:0       TableCol:nil     MixedCol:mixInt1];

    [table addBoolCol:YES  IntCol:506      FloatCol:7.7     DoubleCol:8.8       StringCol:@"banach"
            BinaryCol:bin2 DateCol:timeNow TableCol:subtab2 MixedCol:mixSubtab];

    */


    // Subtable is omitted because the setter implementation is missing.

    TestTableAllTypes_Cursor *c;

    c = [table addRow];

        c.BoolCol   = NO   ; c.IntCol  = 54 ; c.FloatCol = 0.7     ; c.DoubleCol = 0.8     ; c.StringCol = @"foo";
        c.BinaryCol = bin1 ; c.DateCol = 0  ; /*c.TableCol = nil*/ ; c.MixedCol  = mixInt1 ;

    c = [table addRow];

        c.BoolCol   = YES  ; c.IntCol  = 506     ; c.FloatCol = 7.7         ; c.DoubleCol = 8.8       ; c.StringCol = @"banach";
        c.BinaryCol = bin2 ; c.DateCol = timeNow ; /*c.TableCol = subtab2*/ ; c.MixedCol  = mixSubtab ;

    TestTableAllTypes_Cursor *row1 = [table cursorAtIndex:0];
    TestTableAllTypes_Cursor *row2 = [table cursorAtIndex:1];

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
    //STAssertTrue([row1.TableCol isEqual:subtab1],    @"row1.TableCol");
    //STAssertTrue([row2.TableCol isEqual:subtab2],    @"row2.TableCol");
    STAssertTrue([row1.MixedCol isEqual:mixInt1],    @"row1.MixedCol");
    STAssertTrue([row2.MixedCol isEqual:mixSubtab],  @"row2.MixedCol");

    STAssertEquals([table.IntCol min], (int64_t)54,                 @"IntCol min");
    STAssertEquals([table.IntCol max], (int64_t)506,                @"IntCol max");
    STAssertEquals([table.IntCol sum], (int64_t)560,                @"IntCol sum");
    STAssertEquals([table.IntCol avg], 280.0,                       @"IntCol avg");

    STAssertEquals([table.FloatCol min], 0.7f,                      @"FloatCol min");
    STAssertEquals([table.FloatCol max], 7.7f,                      @"FloatCol max");
    STAssertEquals([table.FloatCol sum], (double)0.7f + 7.7f,       @"FloatCol sum");
    STAssertEquals([table.FloatCol avg], ((double)0.7f + 7.7f) / 2, @"FloatCol avg");

    STAssertEquals([table.DoubleCol min], 0.8,                      @"DoubleCol min");
    STAssertEquals([table.DoubleCol max], 8.8,                      @"DoubleCol max");
    STAssertEquals([table.DoubleCol sum], 0.8 + 8.8,                @"DoubleCol sum");
    STAssertEquals([table.DoubleCol avg], (0.8 + 8.8) / 2,          @"DoubleCol avg");
}

@end
