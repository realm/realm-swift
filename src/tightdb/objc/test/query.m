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
}

@end
