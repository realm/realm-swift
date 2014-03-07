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

@interface TightdbDynamicTableTests: SenTestCase
  // Intentionally left blank.
  // No new public instance methods need be defined.
@end

@implementation TightdbDynamicTableTests

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

    //const size_t ndx = [_table addEmptyRow];
    //[_table set:0 ndx:ndx value:0];
    //[_table set:1 ndx:ndx value:10];

    TightdbCursor* cursor = [_table addEmptyRow];
    size_t ndx = [cursor index];
    [cursor setInt:0 inColumn:0];
    [cursor setInt:10 inColumn:1];

    // Verify
    if ([_table getIntInColumn:0 atRow:ndx] != 0)
        STFail(@"First not zero");
    if ([_table getIntInColumn:1 atRow:ndx] != 10)
        STFail(@"Second not 10");
 
    // Add row using object literate
    TightdbTable* _table2 = [[TightdbTable alloc] init];
    [_table2 addColumnWithType:tightdb_Int andName:@"first"];
    if (![_table2 appendRow:@[ @1 ]])
        STFail(@"Impossible!");
    if ([_table2 count] != 1)
        STFail(@"Excepted 1 row");
    if (![_table2 appendRow:@[ @2 ]])
        STFail(@"Impossible!");
    if ([_table2 count] != 2)
        STFail(@"Excepted 2 rows");
    if ([_table2 getIntInColumn:0 atRow:0] != 1)
        STFail(@"Value 1 excepted");
    if ([_table2 getIntInColumn:0 atRow:1] != 2)
        STFail(@"Value 2 excepted");
    if ([_table2 appendRow:@[@"Hello"]])
        STFail(@"Wrong type");
    if ([_table2 appendRow:@[@1, @"Hello"]])
        STFail(@"Wrong number of columns");

    TightdbTable* _table3 = [[TightdbTable alloc] init];
    [_table3 addColumnWithType:tightdb_Int andName:@"first"];
    [_table3 addColumnWithType:tightdb_String andName:@"second"];
    if (![_table3 appendRow:@[@1, @"Hello"]])
        STFail(@"appendRow 1");
    if ([_table3 count] != 1)
        STFail(@"1 row expected");
    if ([_table3 getIntInColumn:0 atRow:0] != 1)
        STFail(@"Value 1 excepted");
    if (![[_table3 getStringInColumn:1 atRow:0] isEqualToString:@"Hello"])
        STFail(@"Value 'Hello' excepted");
    if ([_table3 appendRow:@[@1, @2]])
        STFail(@"appendRow 2");

    TightdbTable* _table4 = [[TightdbTable alloc] init];
    [_table4 addColumnWithType:tightdb_Double andName:@"first"];
    if (![_table4 appendRow:@[@3.14]])  /* double is default */
        STFail(@"Cannot insert 'double'");
    if ([_table4 count] != 1)
        STFail(@"1 row excepted");

    TightdbTable* _table5 = [[TightdbTable alloc] init];
    [_table5 addColumnWithType:tightdb_Float andName:@"first"];
    if (![_table5 appendRow:@[@3.14F]])  /* F == float */
        STFail(@"Cannot insert 'float'");
    if ([_table5 count] != 1)
        STFail(@"1 row excepted");

    TightdbTable* _table6 = [[TightdbTable alloc] init];
    [_table6 addColumnWithType:tightdb_Date andName:@"first"];
    if (![_table6 appendRow:@[@1000000000]])  /* 2001-09-09 01:46:40 */
        STFail(@"Cannot insert 'time_t'");
    if ([_table6 count] != 1)
        STFail(@"1 row excepted");
    NSDate *d = [[NSDate alloc] initWithString:@"2001-09-09 01:46:40 +0000"];
    if (![_table6 appendRow:@[d]])
        STFail(@"Cannot insert 'NSDate'");
    if ([_table6 count] != 2)
        STFail(@"2 rows excepted");

    const char bin[4] = { 0, 1, 2, 3 };
    TightdbBinary* bin2 = [[TightdbBinary alloc] initWithData:bin size:sizeof bin];
    TightdbTable* _table7 = [[TightdbTable alloc] init];
    [_table7 addColumnWithType:tightdb_Binary andName:@"first"];
    if (![_table7 appendRow:@[bin2]])
        STFail(@"Cannot insert 'binary'");
    if ([_table7 count] != 1)
        STFail(@"1 row excepted");
    NSData *nsd = [NSData dataWithBytes:(const void *)bin length:4];
    if (![_table7 appendRow:@[nsd]])
        STFail(@"Cannot insert 'NSData'");
    if ([_table7 count] != 2)
        STFail(@"2 rows excepted");

    TightdbTable* _table8 = [[TightdbTable alloc] init];
    [_table8 addColumnWithType:tightdb_Int andName:@"first"];
    TightdbDescriptor* _descr8 = [_table8 getDescriptor];
    TightdbDescriptor* _subdescr8 = [_descr8 addColumnTable:@"second"];
    [_subdescr8 addColumnWithType:tightdb_Int andName:@"TableCol_IntCol"];
    if (![_table8 appendRow:@[@1, @[]]])
        STFail(@"Cannot insert empty subtable");
    if ([_table8 count] != 1)
        STFail(@"1 row excepted");
    if (![_table8 appendRow:@[@2, @[@[@3]]]])
        STFail(@"Cannot insert subtable");
    if ([_table8 count] != 2)
        STFail(@"2 rows excepted");

    TightdbTable* _table9 = [[TightdbTable alloc] init];
    [_table9 addColumnWithType:tightdb_Mixed andName:@"first"];
    if (![_table9 appendRow:@[@1]])
        STFail(@"Cannot insert 'int'");
    if ([_table9 count] != 1)
        STFail(@"1 row excepted");
    if (![_table9 appendRow:@[@"Hello"]])
        STFail(@"Cannot insert 'string'");
    if ([_table9 count] != 2)
        STFail(@"2 rows excepted");
    if (![_table9 appendRow:@[@3.14f]])
        STFail(@"Cannot insert 'float'");
    if ([_table9 count] != 3)
        STFail(@"3 rows excepted");
    if (![_table9 appendRow:@[@3.14]])
        STFail(@"Cannot insert 'double'");
    if ([_table9 count] != 4)
        STFail(@"4 rows excepted");
    if (![_table9 appendRow:@[@YES]])
        STFail(@"Cannot insert 'bool'");
    if ([_table9 count] != 5)
        STFail(@"5 rows excepted");
    if (![_table9 appendRow:@[bin2]])
        STFail(@"Cannot insert 'binary'");
    if ([_table9 count] != 6)
        STFail(@"6 rows excepted");

    TightdbTable* _table10 = [[TightdbTable alloc] init];
    [_table10 addColumnWithType:tightdb_Bool andName:@"first"];
    if (![_table10 appendRow:@[@YES]])
        STFail(@"Cannot insert 'bool'");
    if ([_table10 count] != 1)
        STFail(@"1 row excepted");
}

-(void)testRemoveColumns
{
    
    TightdbTable *t = [[TightdbTable alloc] init];
    [t addColumnWithType:tightdb_Int andName:@"col0"];
    STAssertTrue([t getColumnCount] == 1,@"1 column added" );
    
    [t removeColumnWithIndex:0];
    STAssertTrue([t getColumnCount] == 0, @"Colum removed");
    
    for (int i=0;i<10;i++) {
        [t addColumnWithType:tightdb_Int andName:@"name"];
    }
    
    STAssertThrows([t removeColumnWithIndex:10], @"Out of bounds");
    STAssertThrows([t removeColumnWithIndex:-1], @"Less than zero colIndex");

    STAssertTrue([t getColumnCount] == 10, @"10 columns added");

    for (int i=0;i<10;i++) {
        [t removeColumnWithIndex:0];
    }
    
    STAssertTrue([t getColumnCount] == 0, @"Colums removed");
    
    STAssertThrows([t removeColumnWithIndex:1], @"No columns added");
    STAssertThrows([t removeColumnWithIndex:-1], @"Less than zero colIndex");

    
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



    cursor = [subtab1 addEmptyRow];
    [cursor setInt:200 inColumn:0];



    cursor = [subtab2 addEmptyRow];
    [cursor setInt:100 inColumn:0];



    TightdbMixed* mixInt1   = [TightdbMixed mixedWithInt64:1];
    TightdbMixed* mixSubtab = [TightdbMixed mixedWithTable:subtab2];

    TightdbCursor* c;



    c = [table addEmptyRow];



    [c setBool:    NO        inColumn:BoolCol];
    [c setInt:     54        inColumn:IntCol];
    [c setFloat:   0.7       inColumn:FloatCol];
    [c setDouble:  0.8       inColumn:DoubleCol];
    [c setString:  @"foo"    inColumn:StringCol];
    [c setBinary:  bin1      inColumn:BinaryCol];
    [c setDate:    0         inColumn:DateCol];
    [c setTable:   subtab1   inColumn:TableCol];
    [c setMixed:   mixInt1   inColumn:MixedCol];

    c = [table addEmptyRow];

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

- (void)testTableDynamic_Subscripting
{
    TightdbTable* _table = [[TightdbTable alloc] init];
    STAssertNotNil(_table, @"Table is nil");

    // 1. Add two columns
    [_table addColumnWithType:tightdb_Int andName:@"first"];
    [_table addColumnWithType:tightdb_String andName:@"second"];

    TightdbCursor* c;

    // Add some rows
    c = [_table addEmptyRow];
    [c setInt: 506 inColumn:0];
    [c setString: @"test" inColumn:1];

    c = [_table addEmptyRow];
    [c setInt: 4 inColumn:0];
    [c setString: @"more test" inColumn:1];

    // Get cursor by object subscripting
    c = _table[0];
    STAssertEquals([c getIntInColumn:0], (int64_t)506, @"table[0].first");
    STAssertTrue([[c getStringInColumn:1] isEqual:@"test"], @"table[0].second");

    // Same but used directly
    STAssertEquals([_table[0] getIntInColumn:0], (int64_t)506, @"table[0].first");
    STAssertTrue([[_table[0] getStringInColumn:1] isEqual:@"test"], @"table[0].second");


}

@end
