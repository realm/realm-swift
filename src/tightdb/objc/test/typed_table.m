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

#import <tightdb/objc/Tightdb.h>

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

@interface TDBTypedTableTests: SenTestCase
  // Intentionally left blank.
  // No new public instance methods need be defined.
@end

@implementation TDBTypedTableTests

- (void)testDataTypes_Typed
{
    TestTableAllTypes* table = [[TestTableAllTypes alloc] init];
    NSLog(@"Table: %@", table);
    STAssertNotNil(table, @"Table is nil");

    // Verify column types
    STAssertEquals(TDBBoolType,   [table columnTypeOfColumn:0], @"First column not bool");
    STAssertEquals(TDBIntType,    [table columnTypeOfColumn:1], @"Second column not int");
    STAssertEquals(TDBFloatType,  [table columnTypeOfColumn:2], @"Third column not float");
    STAssertEquals(TDBDoubleType, [table columnTypeOfColumn:3], @"Fourth column not double");
    STAssertEquals(TDBStringType, [table columnTypeOfColumn:4], @"Fifth column not string");
    STAssertEquals(TDBBinaryType, [table columnTypeOfColumn:5], @"Sixth column not binary");
    STAssertEquals(TDBDateType,   [table columnTypeOfColumn:6], @"Seventh column not date");
    STAssertEquals(TDBTableType,  [table columnTypeOfColumn:7], @"Eighth column not table");
    STAssertEquals(TDBMixedType,  [table columnTypeOfColumn:8], @"Ninth column not mixed");

    const char bin[4] = { 0, 1, 2, 3 };
    NSData* bin1 = [[NSData alloc] initWithBytes:bin length:sizeof bin / 2];
    NSData* bin2 = [[NSData alloc] initWithBytes:bin length:sizeof bin];
    NSDate *timeNow = [NSDate date];
    TestTableSub* subtab1 = [[TestTableSub alloc] init];
    TestTableSub* subtab2 = [[TestTableSub alloc] init];
    [subtab1 addAge:200];
    [subtab2 addAge:100];
    TDBMixed* mixInt1   = [TDBMixed mixedWithInt64:1];
    TDBMixed* mixSubtab = [TDBMixed mixedWithTable:subtab2];

    TestTableAllTypes_Row* c;

    c = [table addEmptyRow];

        c.BoolCol   = NO   ; c.IntCol  = 54 ; c.FloatCol = 0.7     ; c.DoubleCol = 0.8     ; c.StringCol = @"foo";
        c.BinaryCol = bin1 ; c.DateCol = 0  ; c.TableCol = subtab1     ; c.MixedCol  = mixInt1 ;

    c = [table addEmptyRow];

        c.BoolCol   = YES  ; c.IntCol  = 506     ; c.FloatCol = 7.7         ; c.DoubleCol = 8.8       ; c.StringCol = @"banach";
        c.BinaryCol = bin2 ; c.DateCol = timeNow ; c.TableCol = subtab2     ; c.MixedCol  = mixSubtab ;

    TestTableAllTypes_Row* row1 = [table rowAtIndex:0];
    TestTableAllTypes_Row* row2 = [table rowAtIndex:1];

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
  //  STAssertEquals(row1.DateCol, (time_t)0,          @"row1.DateCol");
  //  STAssertEquals(row2.DateCol, timeNow,            @"row2.DateCol");
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

- (void)testTableTyped_Subscripting
{
    TestTableSub *table = [[TestTableSub alloc] init];

    // Add some rows
    [table addAge: 10];
    [table addAge: 20];

    // Verify that you can access rows with object subscripting
    STAssertEquals(table[0].Age, (int64_t)10, @"table[0].age");
    STAssertEquals(table[1].Age, (int64_t)20, @"table[1].age");
}

@end
