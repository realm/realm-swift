//
//  table.m
//  TightDB
//

#import <SenTestingKit/SenTestingKit.h>

#import "TestHelper.h"

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
    @autoreleasepool {
        TightdbTable *_table = [[TightdbTable alloc] init];
        NSLog(@"Table: %@", _table);
        STAssertNotNil(_table, @"Table is nil");
        
        // 1. Add two columns
        [_table addColumn:tightdb_Int name:@"first"];
        [_table addColumn:tightdb_Int name:@"second"];
        
        // Verify
        STAssertEquals(tightdb_Int, [_table getColumnType:0], @"First column not int");
        STAssertEquals(tightdb_Int, [_table getColumnType:1], @"Second column not int");
        if (![[_table getColumnName:0] isEqualToString:@"first"])
            STFail(@"First not equal to first");
        if (![[_table getColumnName:1] isEqualToString:@"second"])
            STFail(@"Second not equal to second");
        
        // 2. Add a row with data
        const size_t ndx = [_table addRow];
        [_table set:0 ndx:ndx value:0];
        [_table set:1 ndx:ndx value:10];
        
        // Verify
        if ([[_table get:0 ndx:ndx] longLongValue] != 0)
            STFail(@"First not zero");
        if ([[_table get:1 ndx:ndx] longLongValue] != 10)
            STFail(@"Second not 10");
    }
    TEST_CHECK_ALLOC;
}

- (void)testDataTypes
{
    @autoreleasepool {
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
        TestTableSub *subtab1 = [[TestTableSub alloc] init];
        TestTableSub *subtab2 = [[TestTableSub alloc] init];
        [subtab2 addAge:100];
        TightdbMixed *mixInt1   = [TightdbMixed mixedWithInt64:1];
        TightdbMixed *mixSubtab = [TightdbMixed mixedWithTable:subtab2];
        
        [table addBoolCol:NO   IntCol:54       FloatCol:0.7     DoubleCol:0.8       StringCol:@"foo"
                BinaryCol:bin1 DateCol:0       TableCol:nil     MixedCol:mixInt1];
        
        [table addBoolCol:YES  IntCol:506      FloatCol:7.7     DoubleCol:8.8       StringCol:@"banach"
                BinaryCol:bin2 DateCol:timeNow TableCol:subtab2 MixedCol:mixSubtab];
        
        TestTableAllTypes_Cursor *row1 = [table objectAtIndex:0];
        TestTableAllTypes_Cursor *row2 = [table objectAtIndex:1];
        
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
    TEST_CHECK_ALLOC;
}

- (void)testTableInsertMultiple
{
    @autoreleasepool {
        NSError *error;
        TightdbTable *_table = [[TightdbTable alloc] initWithError:&error];
        NSLog(@"Table: %@", _table);
        STAssertNotNil(_table, @"Table is nil");
        
        // Create columns
        [_table addColumn:tightdb_Bool name:@"boolCol" error:&error];
        [_table addColumn:tightdb_Int name:@"intCol" error:&error];
        [_table addColumn:tightdb_Float name:@"floatCol" error:&error];
        [_table addColumn:tightdb_Double name:@"doubleCol" error:&error];
        [_table addColumn:tightdb_String name:@"stringCol" error:&error];
        
        // Insert values.
        for(int i=0;i<100;++i) {
            if (![_table insertRowAtIndex:0 error:&error, YES, 10+i, 88.44f+(float)i, 909.99+ (double)i, [NSString stringWithFormat:@"Hello kitty: %d", i]]) {
                NSLog(@"%@", [error localizedDescription]);
                STFail(@"Insert row failed");
            }
        }
        
        for(int i=99, row = 0;i>=0;--i, ++row) {
            STAssertEquals([[_table getBool:0 ndx:row] boolValue], YES, @"Column 1 bool = YES");
            STAssertEquals([[_table get:1 ndx:row] longLongValue], (int64_t)10+i, @"Column 2 int = 10");
            STAssertEquals([[_table getFloat:2 ndx:row] floatValue], 88.44f+(float)i, @"Column 3 float = 88.44");
            STAssertEquals([[_table getDouble:3 ndx:row] doubleValue], 909.99+(double)i, @"Column 4 double = 909.99");
            NSString *str = [NSString stringWithFormat:@"Hello kitty: %d", i];
            STAssertEqualObjects([_table getString:4 ndx:row], str, @"Column 5 string = Hello kitty");
        }
        
        // Test out of bounds:
        STAssertEquals([[_table getBool:0 ndx:100] boolValue], NO, @"Row 100 out of bounds");
        STAssertEquals([[_table getBool:5 ndx:0] boolValue], NO, @"Column 5 out of bounds");
        
    }
    TEST_CHECK_ALLOC;
}

@end
