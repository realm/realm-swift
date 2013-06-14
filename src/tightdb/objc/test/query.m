//
//  query.m
//  TightDB
//

#import <SenTestingKit/SenTestingKit.h>

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

    STAssertEquals([[[table where].BoolCol   equal:NO]      count], (size_t)1, @"BoolCol equal");
    STAssertEquals([[[table where].IntCol    equal:54]      count], (size_t)1, @"IntCol equal");
    STAssertEquals([[[table where].FloatCol  equal:0.7f]    count], (size_t)1, @"FloatCol equal");
    STAssertEquals([[[table where].DoubleCol equal:0.8]     count], (size_t)1, @"DoubleCol equal");
    STAssertEquals([[[table where].StringCol equal:@"foo"]  count], (size_t)1, @"StringCol equal");
    STAssertEquals([[[table where].BinaryCol equal:bin1]    count], (size_t)1, @"BinaryCol equal");
    STAssertEquals([[[table where].DateCol   equal:0]       count], (size_t)1, @"DateCol equal");
// These are not yet implemented
//    STAssertEquals([[[table where].TableCol  equal:subtab1] count], (size_t)1, @"TableCol equal");
//    STAssertEquals([[[table where].MixedCol  equal:mixInt1] count], (size_t)1, @"MixedCol equal");

    TestQueryAllTypes_Query *query = [[table where].BoolCol   equal:NO];

    STAssertEquals([query.IntCol min], (int64_t)54,    @"IntCol min");
    STAssertEquals([query.IntCol max], (int64_t)54,    @"IntCol max");
    STAssertEquals([query.IntCol sum], (int64_t)54,    @"IntCol sum");
    STAssertEquals([query.IntCol avg], 54.0,           @"IntCol avg");

    STAssertEquals([query.FloatCol min], 0.7f,         @"FloatCol min");
    STAssertEquals([query.FloatCol max], 0.7f,         @"FloatCol max");
    STAssertEquals([query.FloatCol sum], (double)0.7f, @"FloatCol sum");
    STAssertEquals([query.FloatCol avg], (double)0.7f, @"FloatCol avg");

    STAssertEquals([query.DoubleCol min], 0.8,         @"DoubleCol min");
    STAssertEquals([query.DoubleCol max], 0.8,         @"DoubleCol max");
    STAssertEquals([query.DoubleCol sum], 0.8,         @"DoubleCol sum");
    STAssertEquals([query.DoubleCol avg], 0.8,         @"DoubleCol avg");

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

@end
