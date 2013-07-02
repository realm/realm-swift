//
//  query.m
//  TightDB
//

#import <SenTestingKit/SenTestingKit.h>

#import "TestHelper.h"

#import <tightdb/objc/tightdb.h>

TIGHTDB_TABLE_1(TestQuerySub,
                Age,  Int)

TIGHTDB_TABLE_9(TestQueryAllTypes,
                BoolCol,   Bool,
                IntCol,    Int,
                FloatCol,  Float,
                DoubleCol, Double,
                StringCol, String,
                BinaryCol, Binary,
                DateCol,   Date,
                TableCol,  TestQuerySub,
                MixedCol,  Mixed)

@interface MACtestQuery: SenTestCase
@end
@implementation MACtestQuery

- (void)testQuery
{
    @autoreleasepool {
    TestQueryAllTypes *table = [[TestQueryAllTypes alloc] init];
    NSLog(@"Table: %@", table);
    STAssertNotNil(table, @"Table is nil");

    const char bin[4] = { 0, 1, 2, 3 };
    TightdbBinary *bin1 = [[TightdbBinary alloc] initWithData:bin size:sizeof bin / 2];
    TightdbBinary *bin2 = [[TightdbBinary alloc] initWithData:bin size:sizeof bin];
    time_t timeNow = [[NSDate date] timeIntervalSince1970];
//    TestQuerySub *subtab1 = [[TestQuerySub alloc] init];
    TestQuerySub *subtab2 = [[TestQuerySub alloc] init];
    [subtab2 addAge:100];
    TightdbMixed *mixInt1   = [TightdbMixed mixedWithInt64:1];
    TightdbMixed *mixSubtab = [TightdbMixed mixedWithTable:subtab2];

    [table addBoolCol:NO   IntCol:54       FloatCol:0.7     DoubleCol:0.8       StringCol:@"foo"
            BinaryCol:bin1 DateCol:0       TableCol:nil     MixedCol:mixInt1];

    [table addBoolCol:YES  IntCol:506      FloatCol:7.7     DoubleCol:8.8       StringCol:@"banach"
            BinaryCol:bin2 DateCol:timeNow TableCol:subtab2 MixedCol:mixSubtab];

    STAssertEquals([[[[table where].BoolCol   equal:NO]      count] unsignedLongValue], (size_t)1, @"BoolCol equal");
    STAssertEquals([[[[table where].IntCol    equal:54]      count] unsignedLongValue], (size_t)1, @"IntCol equal");
    STAssertEquals([[[[table where].FloatCol  equal:0.7f]    count] unsignedLongValue], (size_t)1, @"FloatCol equal");
    STAssertEquals([[[[table where].DoubleCol equal:0.8]     count] unsignedLongValue], (size_t)1, @"DoubleCol equal");
    STAssertEquals([[[[table where].StringCol equal:@"foo"]  count] unsignedLongValue], (size_t)1, @"StringCol equal");
    STAssertEquals([[[[table where].BinaryCol equal:bin1]    count] unsignedLongValue], (size_t)1, @"BinaryCol equal");
    STAssertEquals([[[[table where].DateCol   equal:0]       count] unsignedLongValue], (size_t)1, @"DateCol equal");
// These are not yet implemented
//    STAssertEquals([[[table where].TableCol  equal:subtab1] count], (size_t)1, @"TableCol equal");
//    STAssertEquals([[[table where].MixedCol  equal:mixInt1] count], (size_t)1, @"MixedCol equal");

    TestQueryAllTypes_Query *query = [[table where].BoolCol   equal:NO];

    STAssertEquals([[query.IntCol min] longLongValue], (int64_t)54,    @"IntCol min");
    STAssertEquals([[query.IntCol max] longLongValue], (int64_t)54,    @"IntCol max");
    STAssertEquals([[query.IntCol sum] longLongValue], (int64_t)54,    @"IntCol sum");
    STAssertEquals([[query.IntCol avg] doubleValue], 54.0,           @"IntCol avg");

    STAssertEquals([[query.FloatCol min] floatValue], 0.7f,         @"FloatCol min");
    STAssertEquals([[query.FloatCol max] floatValue], 0.7f,         @"FloatCol max");
    STAssertEquals([[query.FloatCol sum] floatValue], 0.7f, @"FloatCol sum");
    STAssertEquals([[query.FloatCol avg] doubleValue], (double)0.7f, @"FloatCol avg");

    STAssertEquals([[query.DoubleCol min] doubleValue], 0.8,         @"DoubleCol min");
    STAssertEquals([[query.DoubleCol max] doubleValue], 0.8,         @"DoubleCol max");
    STAssertEquals([[query.DoubleCol sum] doubleValue], 0.8,         @"DoubleCol sum");
    STAssertEquals([[query.DoubleCol avg] doubleValue], 0.8,         @"DoubleCol avg");

    // Check that all column conditions return query objects of the
    // right type
    [[[table where].BoolCol equal:NO].BoolCol equal:NO];

    [[[table where].IntCol equal:0].BoolCol equal:NO];
    [[[table where].IntCol notEqual:0].BoolCol equal:NO];
    [[[table where].IntCol less:0].BoolCol equal:NO];
    [[[table where].IntCol lessEqual:0].BoolCol equal:NO];
    [[[table where].IntCol greater:0].BoolCol equal:NO];
    [[[table where].IntCol greaterEqual:0].BoolCol equal:NO];
    [[[table where].IntCol between:0 to:0].BoolCol equal:NO];

    [[[table where].FloatCol equal:0].BoolCol equal:NO];
    [[[table where].FloatCol notEqual:0].BoolCol equal:NO];
    [[[table where].FloatCol less:0].BoolCol equal:NO];
    [[[table where].FloatCol lessEqual:0].BoolCol equal:NO];
    [[[table where].FloatCol greater:0].BoolCol equal:NO];
    [[[table where].FloatCol greaterEqual:0].BoolCol equal:NO];
    [[[table where].FloatCol between:0 to:0].BoolCol equal:NO];

    [[[table where].DoubleCol equal:0].BoolCol equal:NO];
    [[[table where].DoubleCol notEqual:0].BoolCol equal:NO];
    [[[table where].DoubleCol less:0].BoolCol equal:NO];
    [[[table where].DoubleCol lessEqual:0].BoolCol equal:NO];
    [[[table where].DoubleCol greater:0].BoolCol equal:NO];
    [[[table where].DoubleCol greaterEqual:0].BoolCol equal:NO];
    [[[table where].DoubleCol between:0 to:0].BoolCol equal:NO];

    [[[table where].StringCol equal:@""].BoolCol equal:NO];
    [[[table where].StringCol equal:@"" caseSensitive:NO].BoolCol equal:NO];
    [[[table where].StringCol notEqual:@""].BoolCol equal:NO];
    [[[table where].StringCol notEqual:@"" caseSensitive:NO].BoolCol equal:NO];
    [[[table where].StringCol beginsWith:@""].BoolCol equal:NO];
    [[[table where].StringCol beginsWith:@"" caseSensitive:NO].BoolCol equal:NO];
    [[[table where].StringCol endsWith:@""].BoolCol equal:NO];
    [[[table where].StringCol endsWith:@"" caseSensitive:NO].BoolCol equal:NO];
    [[[table where].StringCol contains:@""].BoolCol equal:NO];
    [[[table where].StringCol contains:@"" caseSensitive:NO].BoolCol equal:NO];

    [[[table where].BinaryCol equal:bin1].BoolCol equal:NO];
    [[[table where].BinaryCol notEqual:bin1].BoolCol equal:NO];
    [[[table where].BinaryCol beginsWith:bin1].BoolCol equal:NO];
    [[[table where].BinaryCol endsWith:bin1].BoolCol equal:NO];
    [[[table where].BinaryCol contains:bin1].BoolCol equal:NO];

    [[[table where].DateCol equal:0].BoolCol equal:NO];
    [[[table where].DateCol notEqual:0].BoolCol equal:NO];
    [[[table where].DateCol less:0].BoolCol equal:NO];
    [[[table where].DateCol lessEqual:0].BoolCol equal:NO];
    [[[table where].DateCol greater:0].BoolCol equal:NO];
    [[[table where].DateCol greaterEqual:0].BoolCol equal:NO];
    [[[table where].DateCol between:0 to:0].BoolCol equal:NO];

// These are not yet implemented
//    [[[table where].TableCol equal:nil].BoolCol equal:NO];
//    [[[table where].TableCol notEqual:nil].BoolCol equal:NO];

//    [[[table where].MixedCol equal:mixInt1].BoolCol equal:NO];
//    [[[table where].MixedCol notEqual:mixInt1].BoolCol equal:NO];
    }
    TEST_CHECK_ALLOC;
}

#define BOOL_COL 0
#define INT_COL 1
#define FLOAT_COL 2
#define DOUBLE_COL 3
#define STRING_COL 4
#define BINARY_COL 5
#define DATE_COL 6
#define MIXED_COL 7

- (void) testDynamic 
{
    @autoreleasepool {
        TightdbTable *table = [[TightdbTable alloc]init];
  
        [table addColumn:tightdb_Bool name:@"BoolCol"];
        [table addColumn:tightdb_Int name:@"IntCol"];
        [table addColumn:tightdb_Float name:@"FloatCol"];
        [table addColumn:tightdb_Double name:@"DoubleCol"];
        [table addColumn:tightdb_String name:@"StringCol"];
        [table addColumn:tightdb_Binary name:@"BinaryCol"];
        [table addColumn:tightdb_Date name:@"DateCol"];
        [table addColumn:tightdb_Mixed name:@"MixedCol"];
        // TODO: add Enum<T> and Subtable<T> when possible.      
 
        const char bin[4] = { 0, 1, 2, 3 };
        time_t timeNow = [[NSDate date] timeIntervalSince1970];
        TightdbMixed *mixInt1   = [TightdbMixed mixedWithInt64:1];
        TightdbMixed *mixString   = [TightdbMixed mixedWithString:@"foo"];
        TightdbBinary *bin1 = [[TightdbBinary alloc] initWithData:bin size:sizeof bin / 2];
        TightdbBinary *bin2 = [[TightdbBinary alloc] initWithData:bin size:sizeof bin];
        
        [table addRows:2];

        [table setBool:BOOL_COL ndx:0 value:YES];
        [table setBool:BOOL_COL ndx:1 value:NO];

        [table set:INT_COL ndx:0 value:0];
        [table set:INT_COL ndx:1 value:860];

        [table setFloat:FLOAT_COL ndx:0 value:0];
        [table setFloat:FLOAT_COL ndx:1 value:5.6];

        [table setDouble:DOUBLE_COL ndx:0 value:0];
        [table setDouble:DOUBLE_COL ndx:1 value:5.6];

        [table setString:STRING_COL ndx:0 value:@""];
        [table setString:STRING_COL ndx:1 value:@"foo"];

        [table setBinary:BINARY_COL ndx:0 value:bin1];
        [table setBinary:BINARY_COL ndx:1 value:bin2];

        [table setDate:DATE_COL ndx:0 value:0];
        [table setDate:DATE_COL ndx:1 value:timeNow];

        [table setMixed:MIXED_COL ndx:0 value:mixInt1];
        [table setMixed:MIXED_COL ndx:1 value:mixString];

        // Conditions (note that count is invoked to get the number of matches)

        STAssertEquals([[[table where] betweenInt:859 to:861 colNdx:INT_COL] count], [NSNumber numberWithLongLong:1], @"betweenInt");
        STAssertEquals([[[table where] betweenFloat:5.5 to:5.7 colNdx:FLOAT_COL] count], [NSNumber numberWithLongLong:1], @"betweenFloat");
        STAssertEquals([[[table where] betweenDouble:5.5 to:5.7 colNdx:DOUBLE_COL] count], [NSNumber numberWithLongLong:1], @"betweenDouble");

        STAssertEquals([[[table where] equalBool:YES colNdx:BOOL_COL] count], [NSNumber numberWithLongLong:1], @"equalBool");
        STAssertEquals([[[table where] equalInt:860 colNdx:INT_COL] count], [NSNumber numberWithLongLong:1], @"equalInt");
        STAssertEquals([[[table where] equalFloat:5.6 colNdx:FLOAT_COL] count], [NSNumber numberWithLongLong:1], @"equalFloat");
        STAssertEquals([[[table where] equalDouble:5.6 colNdx:DOUBLE_COL] count], [NSNumber numberWithLongLong:1], @"equalDouble");
        STAssertEquals([[[table where] equalString:@"foo" colNdx:STRING_COL] count], [NSNumber numberWithLongLong:1], @"equalString");        
        STAssertEquals([[[table where] equalString:@"Foo" colNdx:STRING_COL caseSensitive:NO] count], [NSNumber numberWithLongLong:1], @"equalStringCaseNo");
        STAssertEquals([[[table where] equalString:@"Foo" colNdx:STRING_COL caseSensitive:YES] count], [NSNumber numberWithLongLong:0], @"equalStringCaseYes");
        STAssertEquals([[[table where] equalDate:timeNow colNdx:DATE_COL] count], [NSNumber numberWithLongLong:1], @"equalDate");
        STAssertEquals([[[table where] equalBinary:bin1 colNdx:BINARY_COL] count], [NSNumber numberWithLongLong:1], @"equalBinary");

        STAssertEquals([[[table where] notEqualInt:860 colNdx:INT_COL] count], [NSNumber numberWithLongLong:1], @"notEqualInt");
        STAssertEquals([[[table where] notEqualFloat:5.6 colNdx:FLOAT_COL] count], [NSNumber numberWithLongLong:1], @"notEqualFloat");
        STAssertEquals([[[table where] notEqualDouble:5.6 colNdx:DOUBLE_COL] count], [NSNumber numberWithLongLong:1], @"notEqualDouble");
        STAssertEquals([[[table where] notEqualString:@"foo" colNdx:STRING_COL] count], [NSNumber numberWithLongLong:1], @"notEqualString");        
        STAssertEquals([[[table where] notEqualString:@"Foo" colNdx:STRING_COL caseSensitive:NO] count], [NSNumber numberWithLongLong:1], @"notEqualStringCaseNo");
        STAssertEquals([[[table where] notEqualString:@"Foo" colNdx:STRING_COL caseSensitive:YES] count], [NSNumber numberWithLongLong:2], @"notEqualStringCaseYes");
        STAssertEquals([[[table where] notEqualDate:timeNow colNdx:DATE_COL] count], [NSNumber numberWithLongLong:1], @"notEqualDate");
        STAssertEquals([[[table where] notEqualBinary:bin1 colNdx:BINARY_COL] count], [NSNumber numberWithLongLong:1], @"notEqualBinary");

        STAssertEquals([[[table where] greaterInt:859 colNdx:INT_COL] count], [NSNumber numberWithLongLong:1], @"greaterInt");
        STAssertEquals([[[table where] greaterFloat:5.5 colNdx:FLOAT_COL] count], [NSNumber numberWithLongLong:1], @"greaterFloat");
        STAssertEquals([[[table where] greaterDouble:5.5 colNdx:DOUBLE_COL] count], [NSNumber numberWithLongLong:1], @"greaterDouble");
        STAssertEquals([[[table where] greaterDate:0 colNdx:DATE_COL] count], [NSNumber numberWithLongLong:1], @"greaterDate");

        STAssertEquals([[[table where] greaterEqualInt:860 colNdx:INT_COL] count], [NSNumber numberWithLongLong:1], @"notEqualInt");
        STAssertEquals([[[table where] greaterEqualFloat:5.6 colNdx:FLOAT_COL] count], [NSNumber numberWithLongLong:1], @"notEqualFloat");
        STAssertEquals([[[table where] greaterEqualDouble:5.6 colNdx:DOUBLE_COL] count], [NSNumber numberWithLongLong:1], @"notEqualDouble");
        STAssertEquals([[[table where] greaterEqualDate:timeNow colNdx:DATE_COL] count], [NSNumber numberWithLongLong:1], @"notEqualDate");

        STAssertEquals([[[table where] sumInt:INT_COL] longLongValue], (int64_t)860, @"IntCol max");
    }
    TEST_CHECK_ALLOC;
}

@end
