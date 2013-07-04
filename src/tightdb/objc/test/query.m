//
//  query.m
//  TightDB
//

#import <SenTestingKit/SenTestingKit.h>

#import "TestHelper.h"

#import <tightdb/objc/tightdb.h>

TIGHTDB_TABLE_1(TestQuerySub,
                age,  Int)

TIGHTDB_TABLE_9(TestQueryAllTypes,
                boolCol,   Bool,
                intCol,    Int,
                floatCol,  Float,
                doubleCol, Double,
                stringCol, String,
                binaryCol, Binary,
                dateCol,   Date,
                tableCol,  TestQuerySub,
                mixedCol,  Mixed)

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
        [subtab2 addage:100];
        TightdbMixed *mixInt1   = [TightdbMixed mixedWithInt64:1];
        TightdbMixed *mixSubtab = [TightdbMixed mixedWithTable:subtab2];
        
        [table addboolCol:NO   intCol:54       floatCol:0.7     doubleCol:0.8       stringCol:@"foo"
                binaryCol:bin1 dateCol:0       tableCol:nil     mixedCol:mixInt1];
        
        [table addboolCol:YES  intCol:506      floatCol:7.7     doubleCol:8.8       stringCol:@"banach"
                binaryCol:bin2 dateCol:timeNow tableCol:subtab2 mixedCol:mixSubtab];
        
        STAssertEquals([[[[table where].boolCol   equal:NO]      count] unsignedLongValue], (size_t)1, @"boolCol equal");
        STAssertEquals([[[[table where].intCol    equal:54]      count] unsignedLongValue], (size_t)1, @"intCol equal");
        STAssertEquals([[[[table where].floatCol  equal:0.7f]    count] unsignedLongValue], (size_t)1, @"floatCol equal");
        STAssertEquals([[[[table where].doubleCol equal:0.8]     count] unsignedLongValue], (size_t)1, @"doubleCol equal");
        STAssertEquals([[[[table where].stringCol equal:@"foo"]  count] unsignedLongValue], (size_t)1, @"stringCol equal");
        STAssertEquals([[[[table where].binaryCol equal:bin1]    count] unsignedLongValue], (size_t)1, @"binaryCol equal");
        STAssertEquals([[[[table where].dateCol   equal:0]       count] unsignedLongValue], (size_t)1, @"dateCol equal");
        // These are not yet implemented
        //    STAssertEquals([[[table where].tableCol  equal:subtab1] count], (size_t)1, @"tableCol equal");
        //    STAssertEquals([[[table where].mixedCol  equal:mixInt1] count], (size_t)1, @"mixedCol equal");
        
        TestQueryAllTypes_Query *query = [[table where].boolCol   equal:NO];
        
        STAssertEquals([[query.intCol min] longLongValue], (int64_t)54,    @"intCol min");
        STAssertEquals([[query.intCol max] longLongValue], (int64_t)54,    @"intCol max");
        STAssertEquals([[query.intCol sum] longLongValue], (int64_t)54,    @"intCol sum");
        STAssertEquals([[query.intCol avg] doubleValue], 54.0,           @"intCol avg");
        
        STAssertEquals([[query.floatCol min] floatValue], 0.7f,         @"floatCol min");
        STAssertEquals([[query.floatCol max] floatValue], 0.7f,         @"floatCol max");
        STAssertEquals([[query.floatCol sum] floatValue], 0.7f, @"floatCol sum");
        STAssertEquals([[query.floatCol avg] doubleValue], (double)0.7f, @"floatCol avg");
        
        STAssertEquals([[query.doubleCol min] doubleValue], 0.8,         @"doubleCol min");
        STAssertEquals([[query.doubleCol max] doubleValue], 0.8,         @"doubleCol max");
        STAssertEquals([[query.doubleCol sum] doubleValue], 0.8,         @"doubleCol sum");
        STAssertEquals([[query.doubleCol avg] doubleValue], 0.8,         @"doubleCol avg");
        
        // Check that all column conditions return query objects of the
        // right type
        [[[table where].boolCol equal:NO].boolCol equal:NO];
        
        [[[table where].intCol equal:0].boolCol equal:NO];
        [[[table where].intCol notEqual:0].boolCol equal:NO];
        [[[table where].intCol less:0].boolCol equal:NO];
        [[[table where].intCol lessEqual:0].boolCol equal:NO];
        [[[table where].intCol greater:0].boolCol equal:NO];
        [[[table where].intCol greaterEqual:0].boolCol equal:NO];
        [[[table where].intCol between:0 to:0].boolCol equal:NO];
        
        [[[table where].floatCol equal:0].boolCol equal:NO];
        [[[table where].floatCol notEqual:0].boolCol equal:NO];
        [[[table where].floatCol less:0].boolCol equal:NO];
        [[[table where].floatCol lessEqual:0].boolCol equal:NO];
        [[[table where].floatCol greater:0].boolCol equal:NO];
        [[[table where].floatCol greaterEqual:0].boolCol equal:NO];
        [[[table where].floatCol between:0 to:0].boolCol equal:NO];
        
        [[[table where].doubleCol equal:0].boolCol equal:NO];
        [[[table where].doubleCol notEqual:0].boolCol equal:NO];
        [[[table where].doubleCol less:0].boolCol equal:NO];
        [[[table where].doubleCol lessEqual:0].boolCol equal:NO];
        [[[table where].doubleCol greater:0].boolCol equal:NO];
        [[[table where].doubleCol greaterEqual:0].boolCol equal:NO];
        [[[table where].doubleCol between:0 to:0].boolCol equal:NO];
        
        [[[table where].stringCol equal:@""].boolCol equal:NO];
        [[[table where].stringCol equal:@"" caseSensitive:NO].boolCol equal:NO];
        [[[table where].stringCol notEqual:@""].boolCol equal:NO];
        [[[table where].stringCol notEqual:@"" caseSensitive:NO].boolCol equal:NO];
        [[[table where].stringCol beginsWith:@""].boolCol equal:NO];
        [[[table where].stringCol beginsWith:@"" caseSensitive:NO].boolCol equal:NO];
        [[[table where].stringCol endsWith:@""].boolCol equal:NO];
        [[[table where].stringCol endsWith:@"" caseSensitive:NO].boolCol equal:NO];
        [[[table where].stringCol contains:@""].boolCol equal:NO];
        [[[table where].stringCol contains:@"" caseSensitive:NO].boolCol equal:NO];
        
        [[[table where].binaryCol equal:bin1].boolCol equal:NO];
        [[[table where].binaryCol notEqual:bin1].boolCol equal:NO];
        [[[table where].binaryCol beginsWith:bin1].boolCol equal:NO];
        [[[table where].binaryCol endsWith:bin1].boolCol equal:NO];
        [[[table where].binaryCol contains:bin1].boolCol equal:NO];
        
        [[[table where].dateCol equal:0].boolCol equal:NO];
        [[[table where].dateCol notEqual:0].boolCol equal:NO];
        [[[table where].dateCol less:0].boolCol equal:NO];
        [[[table where].dateCol lessEqual:0].boolCol equal:NO];
        [[[table where].dateCol greater:0].boolCol equal:NO];
        [[[table where].dateCol greaterEqual:0].boolCol equal:NO];
        [[[table where].dateCol between:0 to:0].boolCol equal:NO];
        
        // These are not yet implemented
        //    [[[table where].tableCol equal:nil].boolCol equal:NO];
        //    [[[table where].tableCol notEqual:nil].boolCol equal:NO];
        
        //    [[[table where].mixedCol equal:mixInt1].boolCol equal:NO];
        //    [[[table where].mixedCol notEqual:mixInt1].boolCol equal:NO];
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
        
        [table addColumn:tightdb_Bool name:@"boolCol"];
        [table addColumn:tightdb_Int name:@"intCol"];
        [table addColumn:tightdb_Float name:@"floatCol"];
        [table addColumn:tightdb_Double name:@"doubleCol"];
        [table addColumn:tightdb_String name:@"stringCol"];
        [table addColumn:tightdb_Binary name:@"binaryCol"];
        [table addColumn:tightdb_Date name:@"dateCol"];
        [table addColumn:tightdb_Mixed name:@"mixedCol"];
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
        
        STAssertEquals([[[table where] sumInt:INT_COL] longLongValue], (int64_t)860, @"intCol max");
    }
    TEST_CHECK_ALLOC;
}

@end
