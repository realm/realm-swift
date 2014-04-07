//
//  query.m
//  TightDB
//

#import <XCTest/XCTest.h>

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

@interface MACtestQuery: XCTestCase
@end
@implementation MACtestQuery

- (void)testQuery
{
    TestQueryAllTypes *table = [[TestQueryAllTypes alloc] init];
    NSLog(@"Table: %@", table);
    XCTAssertNotNil(table, @"Table is nil");

    const char bin[4] = { 0, 1, 2, 3 };
    NSData *bin1 = [[NSData alloc] initWithBytes:bin length:sizeof bin / 2];
    NSData *bin2 = [[NSData alloc] initWithBytes:bin length:sizeof bin];
//    TestQuerySub *subtab1 = [[TestQuerySub alloc] init];
    TestQuerySub *subtab2 = [[TestQuerySub alloc] init];
    [subtab2 addAge:100];
    NSNumber *mixInt1   = [NSNumber numberWithLongLong:1];
    //TDBMixed *mixSubtab = [TDBMixed mixedWithTable:subtab2];

    [table addBoolCol:NO   IntCol:54       FloatCol:0.7     DoubleCol:0.8       StringCol:@"foo"
            BinaryCol:bin1 DateCol:0       TableCol:nil     MixedCol:mixInt1];

    [table addBoolCol:YES  IntCol:506      FloatCol:7.7     DoubleCol:8.8       StringCol:@"banach"
            BinaryCol:bin2 DateCol:[NSDate date] TableCol:subtab2 MixedCol:subtab2];

    XCTAssertEqual([[[table where].BoolCol   columnIsEqualTo:NO]      countRows], (NSUInteger)1, @"BoolCol equal");
    XCTAssertEqual([[[table where].IntCol    columnIsEqualTo:54]      countRows], (NSUInteger)1, @"IntCol equal");
    XCTAssertEqual([[[table where].FloatCol  columnIsEqualTo:0.7f]    countRows], (NSUInteger)1, @"FloatCol equal");
    XCTAssertEqual([[[table where].DoubleCol columnIsEqualTo:0.8]     countRows], (NSUInteger)1, @"DoubleCol equal");
    XCTAssertEqual([[[table where].StringCol columnIsEqualTo:@"foo"]  countRows], (NSUInteger)1, @"StringCol equal");
    XCTAssertEqual([[[table where].BinaryCol columnIsEqualTo:bin1]    countRows], (NSUInteger)1, @"BinaryCol equal");
    XCTAssertEqual([[[table where].DateCol   columnIsEqualTo:0]       countRows], (NSUInteger)1, @"DateCol equal");
// These are not yet implemented
//    XCTAssertEqual([[[table where].TableCol  columnIsEqualTo:subtab1] count], (size_t)1, @"TableCol equal");
//    XCTAssertEqual([[[table where].MixedCol  columnIsEqualTo:mixInt1] count], (size_t)1, @"MixedCol equal");

    TestQueryAllTypesQuery *query = [[table where].BoolCol   columnIsEqualTo:NO];

    XCTAssertEqual([query.IntCol min], (int64_t)54,    @"IntCol min");
    XCTAssertEqual([query.IntCol max], (int64_t)54,    @"IntCol max");
    XCTAssertEqual([query.IntCol sum], (int64_t)54,    @"IntCol sum");
    XCTAssertEqual([query.IntCol avg] , 54.0,           @"IntCol avg");

    XCTAssertEqual([query.FloatCol min], 0.7f,         @"FloatCol min");
    XCTAssertEqual([query.FloatCol max], 0.7f,         @"FloatCol max");
    XCTAssertEqual([query.FloatCol sum], (double)0.7f, @"FloatCol sum");
    XCTAssertEqual([query.FloatCol avg], (double)0.7f, @"FloatCol avg");

    XCTAssertEqual([query.DoubleCol min], 0.8,         @"DoubleCol min");
    XCTAssertEqual([query.DoubleCol max], 0.8,         @"DoubleCol max");
    XCTAssertEqual([query.DoubleCol sum], 0.8,         @"DoubleCol sum");
    XCTAssertEqual([query.DoubleCol avg], 0.8,         @"DoubleCol avg");

    // Check that all column conditions return query objects of the
    // right type
    [[[table where].BoolCol columnIsEqualTo:NO].BoolCol columnIsEqualTo:NO];

    [[[table where].IntCol columnIsEqualTo:0].BoolCol columnIsEqualTo:NO];
    [[[table where].IntCol columnIsNotEqualTo:0].BoolCol columnIsEqualTo:NO];
    [[[table where].IntCol columnIsLessThan:0].BoolCol columnIsEqualTo:NO];
    [[[table where].IntCol columnIsLessThanOrEqualTo:0].BoolCol columnIsEqualTo:NO];
    [[[table where].IntCol columnIsGreaterThan:0].BoolCol columnIsEqualTo:NO];
    [[[table where].IntCol columnIsGreaterThanOrEqualTo:0].BoolCol columnIsEqualTo:NO];
    [[[table where].IntCol columnIsBetween:0 :0].BoolCol columnIsEqualTo:NO];

    [[[table where].FloatCol columnIsEqualTo:0].BoolCol columnIsEqualTo:NO];
    [[[table where].FloatCol columnIsNotEqualTo:0].BoolCol columnIsEqualTo:NO];
    [[[table where].FloatCol columnIsLessThan:0].BoolCol columnIsEqualTo:NO];
    [[[table where].FloatCol columnIsLessThanOrEqualTo:0].BoolCol columnIsEqualTo:NO];
    [[[table where].FloatCol columnIsGreaterThan:0].BoolCol columnIsEqualTo:NO];
    [[[table where].FloatCol columnIsGreaterThanOrEqualTo:0].BoolCol columnIsEqualTo:NO];
    [[[table where].FloatCol columnIsBetween:0 :0].BoolCol columnIsEqualTo:NO];

    [[[table where].DoubleCol columnIsEqualTo:0].BoolCol columnIsEqualTo:NO];
    [[[table where].DoubleCol columnIsNotEqualTo:0].BoolCol columnIsEqualTo:NO];
    [[[table where].DoubleCol columnIsLessThan:0].BoolCol columnIsEqualTo:NO];
    [[[table where].DoubleCol columnIsLessThanOrEqualTo:0].BoolCol columnIsEqualTo:NO];
    [[[table where].DoubleCol columnIsGreaterThan:0].BoolCol columnIsEqualTo:NO];
    [[[table where].DoubleCol columnIsGreaterThanOrEqualTo:0].BoolCol columnIsEqualTo:NO];
    [[[table where].DoubleCol columnIsBetween:0 :0].BoolCol columnIsEqualTo:NO];

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
    [[[table where].DateCol columnIsBetween:0 :0].BoolCol columnIsEqualTo:NO];

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
    
    [table addColumnWithName:@"BoolCol" type:TDBBoolType];
    [table addColumnWithName:@"IntCol" type:TDBIntType];
    [table addColumnWithName:@"FloatCol" type:TDBFloatType];
    [table addColumnWithName:@"DoubleCol" type:TDBDoubleType];
    [table addColumnWithName:@"StringCol" type:TDBStringType];
    [table addColumnWithName:@"BinaryCol" type:TDBBinaryType];
    [table addColumnWithName:@"DateCol" type:TDBDateType];
    [table addColumnWithName:@"MixedCol" type:TDBMixedType];
    // TODO: add Enum<T> and Subtable<T> when possible.
    
    const char bin[4] = { 0, 1, 2, 3 };
    NSNumber *mixInt1   = [NSNumber numberWithLongLong:1];
    NSString *mixString = [NSString stringWithUTF8String:"foo"];
    NSData *bin1 = [[NSData alloc] initWithBytes:bin length:sizeof bin / 2];
    NSData *bin2 = [[NSData alloc] initWithBytes:bin length:sizeof bin];
    
    // Using private method just for the sake of testing the setters below.
    [table TDB_addEmptyRows:2];
    
    [table TDB_setBool:YES inColumnWithIndex:BOOL_COL atRowIndex:0];
    [table TDB_setBool:NO inColumnWithIndex:BOOL_COL atRowIndex:1];
    
    [table TDB_setInt:0 inColumnWithIndex:INT_COL atRowIndex:0];
    [table TDB_setInt:860 inColumnWithIndex:INT_COL atRowIndex:1];
    
    [table TDB_setFloat:0 inColumnWithIndex:FLOAT_COL atRowIndex:0];
    [table TDB_setFloat:5.6 inColumnWithIndex:FLOAT_COL atRowIndex:1];
    
    [table TDB_setDouble:0 inColumnWithIndex:DOUBLE_COL atRowIndex:0];
    [table TDB_setDouble:5.6 inColumnWithIndex:DOUBLE_COL atRowIndex:1];
    
    [table TDB_setString:@"" inColumnWithIndex:STRING_COL atRowIndex:0];
    [table TDB_setString:@"foo" inColumnWithIndex:STRING_COL atRowIndex:1];
    
    [table TDB_setBinary:bin1 inColumnWithIndex:BINARY_COL atRowIndex:0];
    [table TDB_setBinary:bin2 inColumnWithIndex:BINARY_COL atRowIndex:1];
    
    NSDate *date1 = [NSDate date];
    NSDate *date2 = [date1 dateByAddingTimeInterval:1];
    [table TDB_setDate:date1 inColumnWithIndex:DATE_COL atRowIndex:0];
    [table TDB_setDate:date2 inColumnWithIndex:DATE_COL atRowIndex:1];
    
    [table TDB_setMixed:mixInt1 inColumnWithIndex:MIXED_COL atRowIndex:0];
    [table TDB_setMixed:mixString inColumnWithIndex:MIXED_COL atRowIndex:1];
    
    // Conditions (note that count is invoked to get the number of matches)
    
    XCTAssertEqual([[[table where] intIsBetween:859 :861 inColumnWithIndex:INT_COL ] countRows], (NSUInteger)1, @"betweenInt");
    XCTAssertEqual([[[table where] floatIsBetween:5.5 :5.7 inColumnWithIndex:FLOAT_COL ] countRows], (NSUInteger)1, @"betweenFloat");
    XCTAssertEqual([[[table where] doubleIsBetween:5.5 :5.7 inColumnWithIndex:DOUBLE_COL] countRows], (NSUInteger)1, @"betweenDouble");
    XCTAssertEqual([[[table where] dateIsBetween:date1 :date2 inColumnWithIndex :DATE_COL ] countRows], (NSUInteger)2, @"betweenDate");
    
    XCTAssertEqual([[[table where] boolIsEqualTo:YES inColumnWithIndex:BOOL_COL ] countRows], (NSUInteger)1, @"isEqualToBool");
    XCTAssertEqual([[[table where] intIsEqualTo:860 inColumnWithIndex:INT_COL] countRows], (NSUInteger)1, @"isEqualToInt");
    XCTAssertEqual([[[table where] floatIsEqualTo:5.6 inColumnWithIndex:FLOAT_COL] countRows], (NSUInteger)1, @"isEqualToFloat");
    XCTAssertEqual([[[table where] doubleIsEqualTo:5.6 inColumnWithIndex:DOUBLE_COL] countRows], (NSUInteger)1, @"isEqualToDouble");
    XCTAssertEqual([[[table where] stringIsEqualTo:@"foo" inColumnWithIndex:STRING_COL ] countRows], (NSUInteger)1, @"isEqualToString");
    XCTAssertEqual([[[table where] stringIsCaseInsensitiveEqualTo:@"Foo" inColumnWithIndex:STRING_COL] countRows], (NSUInteger)1, @"isEqualToStringCaseNO");
    //XCTAssertEqual([[[table where] column:STRING_COL isEqualToString:@"Foo" caseSensitive:YES] countRows], (NSUInteger)0, @"isEqualToStringCaseYES");
    XCTAssertEqual([[[table where] dateIsEqualTo:[NSDate date] inColumnWithIndex:DATE_COL] countRows], (NSUInteger)1, @"isEqualToDate");
    XCTAssertEqual([[[table where] binaryIsEqualTo:bin1 inColumnWithIndex:BINARY_COL] countRows], (NSUInteger)1, @"isEqualToBinary");
    
    XCTAssertEqual([[[table where] intIsNotEqualTo:860 inColumnWithIndex:INT_COL] countRows], (NSUInteger)1, @"isEqualToInt");
    XCTAssertEqual([[[table where] floatIsNotEqualTo:5.6 inColumnWithIndex:FLOAT_COL] countRows], (NSUInteger)1, @"isEqualToFloat");
    XCTAssertEqual([[[table where] doubleIsNotEqualTo:5.6 inColumnWithIndex:DOUBLE_COL] countRows], (NSUInteger)1, @"isEqualToDouble");
    XCTAssertEqual([[[table where] stringIsNotEqualTo:@"foo" inColumnWithIndex:STRING_COL] countRows], (NSUInteger)1, @"isEqualToString");
    XCTAssertEqual([[[table where] stringIsNotCaseInsensitiveEqualTo:@"Foo" inColumnWithIndex:STRING_COL] countRows], (NSUInteger)1, @"isEqualToStringCaseNO");
    //XCTAssertEqual([[[table where] column:STRING_COL isNotEqualToString:@"Foo" caseSensitive:YES] countRows], (NSUInteger)2, @"isEqualToStringCaseYES");
    XCTAssertEqual([[[table where] dateIsNotEqualTo:[NSDate date] inColumnWithIndex:DATE_COL] countRows], (NSUInteger)1, @"isEqualToDate");
    XCTAssertEqual([[[table where] binaryIsNotEqualTo:bin1 inColumnWithIndex:BINARY_COL] countRows], (NSUInteger)1, @"isEqualToBinary");
    
    XCTAssertEqual([[[table where] intIsGreaterThan:859 inColumnWithIndex:INT_COL] countRows], (NSUInteger)1, @"isGreaterThanInt");
    XCTAssertEqual([[[table where] floatIsGreaterThan:5.5 inColumnWithIndex:FLOAT_COL] countRows], (NSUInteger)1, @"isGreaterThanFloat");
    XCTAssertEqual([[[table where] doubleIsGreaterThan:5.5 inColumnWithIndex:DOUBLE_COL] countRows], (NSUInteger)1, @"isGreaterThanDouble");
    XCTAssertEqual([[[table where] dateIsGreaterThan:date1 inColumnWithIndex:DATE_COL] countRows], (NSUInteger)1, @"isGreaterThanDate");
    
    XCTAssertEqual([[[table where] intIsGreaterThanOrEqualTo:860 inColumnWithIndex:INT_COL] countRows], (NSUInteger)1, @"isGreaterThanInt");
    XCTAssertEqual([[[table where] floatIsGreaterThanOrEqualTo:5.6 inColumnWithIndex:FLOAT_COL] countRows], (NSUInteger)1, @"isGreaterThanFloat");
    XCTAssertEqual([[[table where] doubleIsGreaterThanOrEqualTo:5.6 inColumnWithIndex:DOUBLE_COL] countRows], (NSUInteger)1, @"isGreaterThanDouble");
    XCTAssertEqual([[[table where] dateIsGreaterThanOrEqualTo:date1 inColumnWithIndex:DATE_COL] countRows], (NSUInteger)2, @"isGreaterThanDate");
    
    XCTAssertEqual([[[table where] intIsLessThan:860 inColumnWithIndex:INT_COL] countRows], (NSUInteger)1, @"isLessThanInt");
    XCTAssertEqual([[[table where] floatIsLessThan:5.6 inColumnWithIndex:FLOAT_COL] countRows], (NSUInteger)1, @"isLessThanFloat");
    XCTAssertEqual([[[table where] doubleIsLessThan:5.6 inColumnWithIndex:DOUBLE_COL] countRows], (NSUInteger)1, @"isLessThanDouble");
    XCTAssertEqual([[[table where] dateIsLessThan:date2 inColumnWithIndex:DATE_COL] countRows], (NSUInteger)1, @"isLessThanDate");
    
    XCTAssertEqual([[[table where] intIsLessThanOrEqualTo:860 inColumnWithIndex:INT_COL] countRows], (NSUInteger)2, @"isLessThanOrEqualToInt");
    XCTAssertEqual([[[table where] floatIsLessThanOrEqualTo:5.6 inColumnWithIndex:FLOAT_COL] countRows], (NSUInteger)2, @"isLessThanOrEqualToFloat");
    XCTAssertEqual([[[table where] doubleIsLessThanOrEqualTo:5.6 inColumnWithIndex:DOUBLE_COL] countRows], (NSUInteger)2, @"isLessThanOrEqualToDouble");
    XCTAssertEqual([[[table where] dateIsLessThanOrEqualTo:date2 inColumnWithIndex:DATE_COL] countRows], (NSUInteger)2, @"isLessThanOrEqualToDate");
    
    //XCTAssertEqual([[[table where] column:INT_COL isBetweenInt:859 and_:861] find:0], (size_t) 1, @"find");
    
    // XCTAssertEqual([[[[table where] column:INT_COL isBetweenInt:859 and_:861] findAll] class], [TDBView class], @"findAll");
    
    XCTAssertEqual([[table where] minIntInColumnWithIndex:INT_COL], (int64_t)0, @"minIntInColumn");
    XCTAssertEqual([[table where] sumIntColumnWithIndex:INT_COL], (int64_t)860, @"IntCol max");
    XCTAssertEqualWithAccuracy([[[table where] minDateInColumnWithIndex:DATE_COL] timeIntervalSince1970], [date1 timeIntervalSince1970], 0.99, @"MinDateInColumn");
    XCTAssertEqualWithAccuracy([[[table where] maxDateInColumnWithIndex:DATE_COL] timeIntervalSince1970], [date2 timeIntervalSince1970], 0.99, @"MaxDateInColumn");
    
    /// TODO: Tests missing....

}


- (void)testFind
{
    TDBTable* table = [[TDBTable alloc]init];
    [table addColumnWithName:@"IntCol" type:TDBIntType];
    [table TDB_addEmptyRows:6];

    [table TDB_setInt:10 inColumnWithIndex:0 atRowIndex:0];
    [table TDB_setInt:42 inColumnWithIndex:0 atRowIndex:1];
    [table TDB_setInt:27 inColumnWithIndex:0 atRowIndex:2];
    [table TDB_setInt:31 inColumnWithIndex:0 atRowIndex:3];
    [table TDB_setInt:8  inColumnWithIndex:0 atRowIndex:4];
    [table TDB_setInt:39 inColumnWithIndex:0 atRowIndex:5];
    
    XCTAssertEqual((NSUInteger)1, [[[table where ] intIsGreaterThan:10 inColumnWithIndex:0 ] indexOfFirstMatchingRow], @"Row 1 is greater than 10");
    XCTAssertEqual(NSNotFound, [[[table where ] intIsGreaterThan:100 inColumnWithIndex:0 ] indexOfFirstMatchingRow], @"No rows are greater than 100");

    XCTAssertEqual([[[table where] intIsBetween:20 :40 inColumnWithIndex:0] indexOfFirstMatchingRowFromIndex:0], (NSUInteger)2,  @"find");
    XCTAssertEqual([[[table where] intIsBetween:20 :40 inColumnWithIndex:0] indexOfFirstMatchingRowFromIndex:3], (NSUInteger)3,  @"find");
    XCTAssertEqual([[[table where] intIsBetween:20 :40 inColumnWithIndex:0] indexOfFirstMatchingRowFromIndex:4], (NSUInteger)5,  @"find");
    XCTAssertEqual([[[table where] intIsBetween:20 :40 inColumnWithIndex:0] indexOfFirstMatchingRowFromIndex:6], (NSUInteger)NSNotFound, @"find");
    XCTAssertEqual([[[table where] intIsBetween:20 :40 inColumnWithIndex:0] indexOfFirstMatchingRowFromIndex:3], (NSUInteger)3,  @"find");
    // jjepsen: disabled this test, perhaps it's not relevant after query sematics update.
    //XCTAssertEqual([[[table where] column:0 isBetweenInt:20 and_:40] find:-1], (size_t)-1, @"find");
    
    [table removeAllRows];
    XCTAssertEqual([[table where] indexOfFirstMatchingRow], NSNotFound, @"");
    XCTAssertEqual([[table where] indexOfFirstMatchingRowFromIndex:0], NSNotFound, @"");
}

- (void) testSubtableQuery
{
    TDBTable *t = [[TDBTable alloc] init];
    
    TDBDescriptor *d = t.descriptor;
    TDBDescriptor *subDesc = [d addColumnTable:@"subtable"];
    [subDesc addColumnWithName:@"subCol" type:TDBBoolType];
    [t addRow:nil];
    XCTAssertEqual(t.rowCount, (NSUInteger)1,@"one row added");
    
    TDBTable * subTable = [t TDB_tableInColumnWithIndex:0 atRowIndex:0];
    [subTable addRow:nil];
    [subTable TDB_setBool:YES inColumnWithIndex:0 atRowIndex:0];
    TDBQuery *q = [t where];
    
    TDBView *v = [[[[q subtableInColumnWithIndex:0] boolIsEqualTo:YES inColumnWithIndex:0] parent] findAllRows];
    XCTAssertEqual(v.rowCount, (NSUInteger)1,@"one match");
}

-(void) testQueryEnumeratorNoCondition
{
    TDBTable *table = [[TDBTable alloc] init];
    [table addColumnWithName:@"first" type:TDBIntType];
    for(int i=0; i<10; ++i)
        [table addRow:@[[NSNumber numberWithInt:i]]];
    TDBQuery *query = [table where];
    int i = 0;
    for(TDBRow *row in query) {
        XCTAssertEqual((int64_t)i, [(NSNumber *)row[@"first"] longLongValue], @"Wrong value");
        ++i;
    }
}

-(void) testQueryEnumeratorWithCondition
{
    TDBTable *table = [[TDBTable alloc] init];
    [table addColumnWithName:@"first" type:TDBIntType];
    for(int i=0; i<10; ++i)
        [table addRow:@[[NSNumber numberWithInt:i]]];
    TDBQuery *query = [[table where] intIsGreaterThan:-1 inColumnWithIndex:0];
    int i = 0;
    for(TDBRow *row in query) {
        XCTAssertEqual((int64_t)i, [(NSNumber *)row[@"first"] longLongValue], @"Wrong value");
        ++i;
    }
}

@end
