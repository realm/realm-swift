//
//  query.m
//  TightDB
//

#import <SenTestingKit/SenTestingKit.h>

#import <tightdb/objc/Tightdb.h>

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
    NSData *bin1 = [[NSData alloc] initWithBytes:bin length:sizeof bin / 2];
    NSData *bin2 = [[NSData alloc] initWithBytes:bin length:sizeof bin];
//    TestQuerySub *subtab1 = [[TestQuerySub alloc] init];
    TestQuerySub *subtab2 = [[TestQuerySub alloc] init];
    [subtab2 addAge:100];
    TDBMixed *mixInt1   = [TDBMixed mixedWithInt64:1];
    TDBMixed *mixSubtab = [TDBMixed mixedWithTable:subtab2];

    [table addBoolCol:NO   IntCol:54       FloatCol:0.7     DoubleCol:0.8       StringCol:@"foo"
            BinaryCol:bin1 DateCol:0       TableCol:nil     MixedCol:mixInt1];

    [table addBoolCol:YES  IntCol:506      FloatCol:7.7     DoubleCol:8.8       StringCol:@"banach"
            BinaryCol:bin2 DateCol:[NSDate date] TableCol:subtab2 MixedCol:mixSubtab];

    STAssertEquals([[[table where].BoolCol   columnIsEqualTo:NO]      countRows], (NSUInteger)1, @"BoolCol equal");
    STAssertEquals([[[table where].IntCol    columnIsEqualTo:54]      countRows], (NSUInteger)1, @"IntCol equal");
    STAssertEquals([[[table where].FloatCol  columnIsEqualTo:0.7f]    countRows], (NSUInteger)1, @"FloatCol equal");
    STAssertEquals([[[table where].DoubleCol columnIsEqualTo:0.8]     countRows], (NSUInteger)1, @"DoubleCol equal");
    STAssertEquals([[[table where].StringCol columnIsEqualTo:@"foo"]  countRows], (NSUInteger)1, @"StringCol equal");
    STAssertEquals([[[table where].BinaryCol columnIsEqualTo:bin1]    countRows], (NSUInteger)1, @"BinaryCol equal");
    STAssertEquals([[[table where].DateCol   columnIsEqualTo:0]       countRows], (NSUInteger)1, @"DateCol equal");
// These are not yet implemented
//    STAssertEquals([[[table where].TableCol  columnIsEqualTo:subtab1] count], (size_t)1, @"TableCol equal");
//    STAssertEquals([[[table where].MixedCol  columnIsEqualTo:mixInt1] count], (size_t)1, @"MixedCol equal");

    TestQueryAllTypesQuery *query = [[table where].BoolCol   columnIsEqualTo:NO];

    STAssertEquals([query.IntCol min], (int64_t)54,    @"IntCol min");
    STAssertEquals([query.IntCol max], (int64_t)54,    @"IntCol max");
    STAssertEquals([query.IntCol sum], (int64_t)54,    @"IntCol sum");
    STAssertEquals([query.IntCol avg] , 54.0,           @"IntCol avg");

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
    [[[table where].BoolCol columnIsEqualTo:NO].BoolCol columnIsEqualTo:NO];

    [[[table where].IntCol columnIsEqualTo:0].BoolCol columnIsEqualTo:NO];
    [[[table where].IntCol columnIsNotEqualTo:0].BoolCol columnIsEqualTo:NO];
    [[[table where].IntCol columnIsLessThan:0].BoolCol columnIsEqualTo:NO];
    [[[table where].IntCol columnIsLessThanOrEqualTo:0].BoolCol columnIsEqualTo:NO];
    [[[table where].IntCol columnIsGreaterThan:0].BoolCol columnIsEqualTo:NO];
    [[[table where].IntCol columnIsGreaterThanOrEqualTo:0].BoolCol columnIsEqualTo:NO];
    [[[table where].IntCol columnIsBetween:0 and_:0].BoolCol columnIsEqualTo:NO];

    [[[table where].FloatCol columnIsEqualTo:0].BoolCol columnIsEqualTo:NO];
    [[[table where].FloatCol columnIsNotEqualTo:0].BoolCol columnIsEqualTo:NO];
    [[[table where].FloatCol columnIsLessThan:0].BoolCol columnIsEqualTo:NO];
    [[[table where].FloatCol columnIsLessThanOrEqualTo:0].BoolCol columnIsEqualTo:NO];
    [[[table where].FloatCol columnIsGreaterThan:0].BoolCol columnIsEqualTo:NO];
    [[[table where].FloatCol columnIsGreaterThanOrEqualTo:0].BoolCol columnIsEqualTo:NO];
    [[[table where].FloatCol columnIsBetween:0 and_:0].BoolCol columnIsEqualTo:NO];

    [[[table where].DoubleCol columnIsEqualTo:0].BoolCol columnIsEqualTo:NO];
    [[[table where].DoubleCol columnIsNotEqualTo:0].BoolCol columnIsEqualTo:NO];
    [[[table where].DoubleCol columnIsLessThan:0].BoolCol columnIsEqualTo:NO];
    [[[table where].DoubleCol columnIsLessThanOrEqualTo:0].BoolCol columnIsEqualTo:NO];
    [[[table where].DoubleCol columnIsGreaterThan:0].BoolCol columnIsEqualTo:NO];
    [[[table where].DoubleCol columnIsGreaterThanOrEqualTo:0].BoolCol columnIsEqualTo:NO];
    [[[table where].DoubleCol columnIsBetween:0 and_:0].BoolCol columnIsEqualTo:NO];

    [[[table where].StringCol columnIsEqualTo:@""].BoolCol columnIsEqualTo:NO];
    [[[table where].StringCol columnIsEqualTo:@"" caseSensitive:NO].BoolCol columnIsEqualTo:NO];
    [[[table where].StringCol columnIsNotEqualTo:@""].BoolCol columnIsEqualTo:NO];
    [[[table where].StringCol columnIsNotEqualTo:@"" caseSensitive:NO].BoolCol columnIsEqualTo:NO];
    [[[table where].StringCol columnBeginsWith:@""].BoolCol columnIsEqualTo:NO];
    [[[table where].StringCol columnBeginsWith:@"" caseSensitive:NO].BoolCol columnIsEqualTo:NO];
    [[[table where].StringCol columnEndsWith:@""].BoolCol columnIsEqualTo:NO];
    [[[table where].StringCol columnEndsWith:@"" caseSensitive:NO].BoolCol columnIsEqualTo:NO];
    [[[table where].StringCol columnContains:@""].BoolCol columnIsEqualTo:NO];
    [[[table where].StringCol columnContains:@"" caseSensitive:NO].BoolCol columnIsEqualTo:NO];

    [[[table where].BinaryCol columnIsEqualTo:bin1].BoolCol columnIsEqualTo:NO];
    [[[table where].BinaryCol columnIsNotEqualTo:bin1].BoolCol columnIsEqualTo:NO];
    [[[table where].BinaryCol columnBeginsWith:bin1].BoolCol columnIsEqualTo:NO];
    [[[table where].BinaryCol columnEndsWith:bin1].BoolCol columnIsEqualTo:NO];
    [[[table where].BinaryCol columnContains:bin1].BoolCol columnIsEqualTo:NO];

    [[[table where].DateCol columnIsEqualTo:0].BoolCol columnIsEqualTo:NO];
    [[[table where].DateCol columnIsNotEqualTo:0].BoolCol columnIsEqualTo:NO];
    [[[table where].DateCol columnIsLessThan:0].BoolCol columnIsEqualTo:NO];
    [[[table where].DateCol columnIsLessThanOrEqualTo:0].BoolCol columnIsEqualTo:NO];
    [[[table where].DateCol columnIsGreaterThan:0].BoolCol columnIsEqualTo:NO];
    [[[table where].DateCol columnIsGreaterThanOrEqualTo:0].BoolCol columnIsEqualTo:NO];
    [[[table where].DateCol columnIsBetween:0 and_:0].BoolCol columnIsEqualTo:NO];

// These are not yet implemented
//    [[[table where].TableCol columnIsEqualTo:nil].BoolCol columnIsEqualTo:NO];
//    [[[table where].TableCol columnIsNotEqualTo:nil].BoolCol columnIsEqualTo:NO];

//    [[[table where].MixedCol columnIsEqualTo:mixInt1].BoolCol columnIsEqualTo:NO];
//    [[[table where].MixedCol columnIsNotEqualTo:mixInt1].BoolCol columnIsEqualTo:NO];
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

        TDBTable *table = [[TDBTable alloc]init];

        [table addColumnWithName:@"BoolCol" andType:TDBBoolType];
        [table addColumnWithName:@"IntCol" andType:TDBIntType];
        [table addColumnWithName:@"FloatCol" andType:TDBFloatType];
        [table addColumnWithName:@"DoubleCol" andType:TDBDoubleType];
        [table addColumnWithName:@"StringCol" andType:TDBStringType];
        [table addColumnWithName:@"BinaryCol" andType:TDBBinaryType];
        [table addColumnWithName:@"DateCol" andType:TDBDateType];
        [table addColumnWithName:@"MixedCol" andType:TDBMixedType];
        // TODO: add Enum<T> and Subtable<T> when possible.

        const char bin[4] = { 0, 1, 2, 3 };
        TDBMixed *mixInt1   = [TDBMixed mixedWithInt64:1];
        TDBMixed *mixString   = [TDBMixed mixedWithString:@"foo"];
        NSData *bin1 = [[NSData alloc] initWithBytes:bin length:sizeof bin / 2];
        NSData *bin2 = [[NSData alloc] initWithBytes:bin length:sizeof bin];

        // Using private method just for the sake of testing the setters below.
        [table TDBAddEmptyRows:2];

        [table TDBsetBool:YES inColumnWithIndex:BOOL_COL atRowIndex:0];
        [table TDBsetBool:NO inColumnWithIndex:BOOL_COL atRowIndex:1];

        [table TDBsetInt:0 inColumnWithIndex:INT_COL atRowIndex:0];
        [table TDBsetInt:860 inColumnWithIndex:INT_COL atRowIndex:1];

        [table TDBsetFloat:0 inColumnWithIndex:FLOAT_COL atRowIndex:0];
        [table TDBsetFloat:5.6 inColumnWithIndex:FLOAT_COL atRowIndex:1];

        [table TDBsetDouble:0 inColumnWithIndex:DOUBLE_COL atRowIndex:0];
        [table TDBsetDouble:5.6 inColumnWithIndex:DOUBLE_COL atRowIndex:1];

        [table TDBsetString:@"" inColumnWithIndex:STRING_COL atRowIndex:0];
        [table TDBsetString:@"foo" inColumnWithIndex:STRING_COL atRowIndex:1];

        [table TDBsetBinary:bin1 inColumnWithIndex:BINARY_COL atRowIndex:0];
        [table TDBsetBinary:bin2 inColumnWithIndex:BINARY_COL atRowIndex:1];

        [table TDBsetDate:0 inColumnWithIndex:DATE_COL atRowIndex:0];
        [table TDBsetDate:[NSDate date] inColumnWithIndex:DATE_COL atRowIndex:1];

        [table TDBsetMixed:mixInt1 inColumnWithIndex:MIXED_COL atRowIndex:0];
        [table TDBsetMixed:mixString inColumnWithIndex:MIXED_COL atRowIndex:1];

        // Conditions (note that count is invoked to get the number of matches)

        //STAssertEquals([[[table where] column:INT_COL isBetweenInt:859 and_:861] count], (NSUInteger)1, @"betweenInt");
        //STAssertEquals([[[table where] column:FLOAT_COL isBetweenFloat:5.5 and_:5.7] count], (NSUInteger)1, @"betweenFloat");
        //STAssertEquals([[[table where] column:DOUBLE_COL isBetweenDouble:5.5 and_:5.7] count], (NSUInteger)1, @"betweenDouble");
        //STAssertEquals([[[table where] column:DATE_COL isBetweenDate:1 and_:timeNow] count], (NSUInteger)1, @"betweenDate");

        STAssertEquals([[[table where] boolIsEqualTo:YES inColumnWithIndex:BOOL_COL ] countRows], (NSUInteger)1, @"isEqualToBool");
        STAssertEquals([[[table where] intIsEqualTo:860 inColumnWithIndex:INT_COL] countRows], (NSUInteger)1, @"isEqualToInt");
        STAssertEquals([[[table where] floatIsEqualTo:5.6 inColumnWithIndex:FLOAT_COL] countRows], (NSUInteger)1, @"isEqualToFloat");
        STAssertEquals([[[table where] doubleIsEqualTo:5.6 inColumnWithIndex:DOUBLE_COL] countRows], (NSUInteger)1, @"isEqualToDouble");
        STAssertEquals([[[table where] stringIsEqualTo:@"foo" inColumnWithIndex:STRING_COL ] countRows], (NSUInteger)1, @"isEqualToString");
        STAssertEquals([[[table where] stringIsCaseInsensitiveEqualTo:@"Foo" inColumnWithIndex:STRING_COL] countRows], (NSUInteger)1, @"isEqualToStringCaseNO");
        //STAssertEquals([[[table where] column:STRING_COL isEqualToString:@"Foo" caseSensitive:YES] countRows], (NSUInteger)0, @"isEqualToStringCaseYES");
        STAssertEquals([[[table where] dateIsEqualTo:[NSDate date] inColumnWithIndex:DATE_COL] countRows], (NSUInteger)1, @"isEqualToDate");
        STAssertEquals([[[table where] binaryIsEqualTo:bin1 inColumnWithIndex:BINARY_COL] countRows], (NSUInteger)1, @"isEqualToBinary");

        STAssertEquals([[[table where] intIsNotEqualTo:860 inColumnWithIndex:INT_COL] countRows], (NSUInteger)1, @"isEqualToInt");
        STAssertEquals([[[table where] floatIsNotEqualTo:5.6 inColumnWithIndex:FLOAT_COL] countRows], (NSUInteger)1, @"isEqualToFloat");
        STAssertEquals([[[table where] doubleIsNotEqualTo:5.6 inColumnWithIndex:DOUBLE_COL] countRows], (NSUInteger)1, @"isEqualToDouble");
        STAssertEquals([[[table where] stringIsNotEqualTo:@"foo" inColumnWithIndex:STRING_COL] countRows], (NSUInteger)1, @"isEqualToString");
        STAssertEquals([[[table where] stringIsNotCaseInsensitiveEqualTo:@"Foo" inColumnWithIndex:STRING_COL] countRows], (NSUInteger)1, @"isEqualToStringCaseNO");
        //STAssertEquals([[[table where] column:STRING_COL isNotEqualToString:@"Foo" caseSensitive:YES] countRows], (NSUInteger)2, @"isEqualToStringCaseYES");
        STAssertEquals([[[table where] dateIsNotEqualTo:[NSDate date] inColumnWithIndex:DATE_COL] countRows], (NSUInteger)1, @"isEqualToDate");
        STAssertEquals([[[table where] binaryIsNotEqualTo:bin1 inColumnWithIndex:BINARY_COL] countRows], (NSUInteger)1, @"isEqualToBinary");

        STAssertEquals([[[table where] intIsGreaterThan:859 inColumnWithIndex:INT_COL] countRows], (NSUInteger)1, @"isGreaterThanInt");
        STAssertEquals([[[table where] floatIsGreaterThan:5.5 inColumnWithIndex:FLOAT_COL] countRows], (NSUInteger)1, @"isGreaterThanFloat");
        STAssertEquals([[[table where] doubleIsGreaterThan:5.5 inColumnWithIndex:DOUBLE_COL] countRows], (NSUInteger)1, @"isGreaterThanDouble");
        STAssertEquals([[[table where] dateIsGreaterThan:0 inColumnWithIndex:DATE_COL] countRows], (NSUInteger)1, @"isGreaterThanDate");

        STAssertEquals([[[table where] intIsGreaterThanOrEqualTo:860 inColumnWithIndex:INT_COL] countRows], (NSUInteger)1, @"isGreaterThanInt");
        STAssertEquals([[[table where] floatIsGreaterThanOrEqualTo:5.6 inColumnWithIndex:FLOAT_COL] countRows], (NSUInteger)1, @"isGreaterThanFloat");
        STAssertEquals([[[table where] doubleIsGreaterThanOrEqualTo:5.6 inColumnWithIndex:DOUBLE_COL] countRows], (NSUInteger)1, @"isGreaterThanDouble");
        STAssertEquals([[[table where] dateIsGreaterThanOrEqualTo:[NSDate date] inColumnWithIndex:DATE_COL] countRows], (NSUInteger)1, @"isGreaterThanDate");

        STAssertEquals([[[table where] intIsLessThan:860 inColumnWithIndex:INT_COL] countRows], (NSUInteger)1, @"isLessThanInt");
        STAssertEquals([[[table where] floatIsLessThan:5.6 inColumnWithIndex:FLOAT_COL] countRows], (NSUInteger)1, @"isLessThanFloat");
        STAssertEquals([[[table where] doubleIsLessThan:5.6 inColumnWithIndex:DOUBLE_COL] countRows], (NSUInteger)1, @"isLessThanDouble");
        STAssertEquals([[[table where] dateIsLessThan:[NSDate date] inColumnWithIndex:DATE_COL] countRows], (NSUInteger)1, @"isLessThanDate");

        STAssertEquals([[[table where] intIsLessThanOrEqualTo:860 inColumnWithIndex:INT_COL] countRows], (NSUInteger)2, @"isLessThanOrEqualToInt");
        STAssertEquals([[[table where] floatIsLessThanOrEqualTo:5.6 inColumnWithIndex:FLOAT_COL] countRows], (NSUInteger)2, @"isLessThanOrEqualToFloat");
        STAssertEquals([[[table where] doubleIsLessThanOrEqualTo:5.6 inColumnWithIndex:DOUBLE_COL] countRows], (NSUInteger)2, @"isLessThanOrEqualToDouble");
        STAssertEquals([[[table where] dateIsLessThanOrEqualTo:[NSDate date] inColumnWithIndex:DATE_COL] countRows], (NSUInteger)2, @"isLessThanOrEqualToDate");

        //STAssertEquals([[[table where] column:INT_COL isBetweenInt:859 and_:861] find:0], (size_t) 1, @"find");

       // STAssertEquals([[[[table where] column:INT_COL isBetweenInt:859 and_:861] findAll] class], [TDBView class], @"findAll");

        STAssertEquals([[table where] minIntInColumnWithIndex:INT_COL] , (int64_t)0, @"minimunIntOfColumn");
        STAssertEquals([[table where] sumIntColumnWithIndex:INT_COL] , (int64_t)860, @"IntCol max");
        /// TODO: Tests missing....

}


- (void)testFind
{
    TDBTable* table = [[TDBTable alloc]init];
    [table addColumnWithName:@"IntCol" andType:TDBIntType];
    [table TDBAddEmptyRows:6];

    [table TDBsetInt:10 inColumnWithIndex:0 atRowIndex:0];
    [table TDBsetInt:42 inColumnWithIndex:0 atRowIndex:1];
    [table TDBsetInt:27 inColumnWithIndex:0 atRowIndex:2];
    [table TDBsetInt:31 inColumnWithIndex:0 atRowIndex:3];
    [table TDBsetInt:8  inColumnWithIndex:0 atRowIndex:4];
    [table TDBsetInt:39 inColumnWithIndex:0 atRowIndex:5];
    
    STAssertEquals((NSUInteger)1, [[[table where ] intIsGreaterThan:10 inColumnWithIndex:0 ] findFirstRow], @"Row 1 is greater than 10");
    STAssertEquals((NSUInteger)-1, [[[table where ] intIsGreaterThan:100 inColumnWithIndex:0 ] findFirstRow], @"No rows are greater than 100");

    //STAssertEquals([[[table where] column:0 isBetweenInt:20 and_:40] find:0], (size_t)2,  @"find");
    //STAssertEquals([[[table where] column:0 isBetweenInt:20 and_:40] find:3], (size_t)3,  @"find");
    //STAssertEquals([[[table where] column:0 isBetweenInt:20 and_:40] find:4], (size_t)5,  @"find");
    //STAssertEquals([[[table where] column:0 isBetweenInt:20 and_:40] find:6], (size_t)-1, @"find");
    //STAssertEquals([[[table where] column:0 isBetweenInt:20 and_:40] find:3], (size_t)3,  @"find");
    // jjepsen: disabled this test, perhaps it's not relevant after query sematics update.
    //STAssertEquals([[[table where] column:0 isBetweenInt:20 and_:40] find:-1], (size_t)-1, @"find");
}

- (void) testSubtableQuery
{
    TDBTable *t = [[TDBTable alloc] init];
    
    TDBDescriptor *d = t.descriptor;
    TDBDescriptor *subDesc = [d addColumnTable:@"subtable"];
    [subDesc addColumnWithName:@"subCol" andType:TDBBoolType];
    [t addRow:nil];
    STAssertEquals(t.rowCount, (NSUInteger)1,@"one row added");
    
    TDBTable * subTable = [t TDBtableInColumnWithIndex:0 atRowIndex:0];
    [subTable addRow:nil];
    [subTable TDBsetBool:YES inColumnWithIndex:0 atRowIndex:0];
    TDBQuery *q = [t where];
    
    TDBView *v = [[[[q subtableInColumnWithIndex:0] boolIsEqualTo:YES inColumnWithIndex:0] parent] findAllRows];
    STAssertEquals(v.rowCount, (NSUInteger)1,@"one match");
}


@end
