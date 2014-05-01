//
//  query.m
//  TightDB
//

#import "RLMTestCase.h"

#import <realm/objc/Realm.h>
#import <realm/objc/RLMQueryFast.h>

REALM_TABLE_1(TestQuerySub,
                Age,  Int)

REALM_TABLE_9(TestQueryAllTypes,
                BoolCol,   Bool,
                IntCol,    Int,
                FloatCol,  Float,
                DoubleCol, Double,
                StringCol, String,
                BinaryCol, Binary,
                DateCol,   Date,
                TableCol,  TestQuerySub,
                MixedCol,  Mixed)

@interface MACtestQuery: RLMTestCase
@end
@implementation MACtestQuery

- (void)testQuery
{
    [self.contextPersistedAtTestPath writeUsingBlock:^(RLMRealm *realm) {
        TestQueryAllTypes *table = [realm createTableWithName:@"table" asTableClass:TestQueryAllTypes.class];
        NSLog(@"Table: %@", table);
        XCTAssertNotNil(table, @"Table is nil");
        
        const char bin[4] = { 0, 1, 2, 3 };
        NSData *bin1 = [[NSData alloc] initWithBytes:bin length:sizeof bin / 2];
        NSData *bin2 = [[NSData alloc] initWithBytes:bin length:sizeof bin];
        //    TestQuerySub *subtab1 = [[TestQuerySub alloc] init];
        TestQuerySub *subtab2 = [realm createTableWithName:@"subtab2" asTableClass:TestQuerySub.class];
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
        //    XCTAssertEqual([[[table where].TableCol  columnIsEqualTo:subtab1] count], (NSUInteger)1, @"TableCol equal");
        //    XCTAssertEqual([[[table where].MixedCol  columnIsEqualTo:mixInt1] count], (NSUInteger)1, @"MixedCol equal");
        
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
    }];
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
    [self createTestTableWithWriteBlock:^(RLMTable *table) {
        [table addColumnWithName:@"BoolCol" type:RLMTypeBool];
        [table addColumnWithName:@"IntCol" type:RLMTypeInt];
        [table addColumnWithName:@"FloatCol" type:RLMTypeFloat];
        [table addColumnWithName:@"DoubleCol" type:RLMTypeDouble];
        [table addColumnWithName:@"StringCol" type:RLMTypeString];
        [table addColumnWithName:@"BinaryCol" type:RLMTypeBinary];
        [table addColumnWithName:@"DateCol" type:RLMTypeDate];
        [table addColumnWithName:@"MixedCol" type:RLMTypeMixed];
        // TODO: add Enum<T> and Subtable<T> when possible.
        
        const char bin[4] = { 0, 1, 2, 3 };
        NSNumber *mixInt1   = [NSNumber numberWithLongLong:1];
        NSString *mixString = [NSString stringWithUTF8String:"foo"];
        NSData *bin1 = [[NSData alloc] initWithBytes:bin length:sizeof bin / 2];
        NSData *bin2 = [[NSData alloc] initWithBytes:bin length:sizeof bin];
        
        // Using private method just for the sake of testing the setters below.
        [table RLM_addEmptyRows:2];
        
        [table RLM_setBool:YES inColumnWithIndex:BOOL_COL atRowIndex:0];
        [table RLM_setBool:NO inColumnWithIndex:BOOL_COL atRowIndex:1];
        
        [table RLM_setInt:0 inColumnWithIndex:INT_COL atRowIndex:0];
        [table RLM_setInt:860 inColumnWithIndex:INT_COL atRowIndex:1];
        
        [table RLM_setFloat:0 inColumnWithIndex:FLOAT_COL atRowIndex:0];
        [table RLM_setFloat:5.6 inColumnWithIndex:FLOAT_COL atRowIndex:1];
        
        [table RLM_setDouble:0 inColumnWithIndex:DOUBLE_COL atRowIndex:0];
        [table RLM_setDouble:5.6 inColumnWithIndex:DOUBLE_COL atRowIndex:1];
        
        [table RLM_setString:@"" inColumnWithIndex:STRING_COL atRowIndex:0];
        [table RLM_setString:@"foo" inColumnWithIndex:STRING_COL atRowIndex:1];
        
        [table RLM_setBinary:bin1 inColumnWithIndex:BINARY_COL atRowIndex:0];
        [table RLM_setBinary:bin2 inColumnWithIndex:BINARY_COL atRowIndex:1];
        
        NSDate *date1 = [NSDate date];
        NSDate *date2 = [date1 dateByAddingTimeInterval:1];
        [table RLM_setDate:date1 inColumnWithIndex:DATE_COL atRowIndex:0];
        [table RLM_setDate:date2 inColumnWithIndex:DATE_COL atRowIndex:1];
        
        [table RLM_setMixed:mixInt1 inColumnWithIndex:MIXED_COL atRowIndex:0];
        [table RLM_setMixed:mixString inColumnWithIndex:MIXED_COL atRowIndex:1];
        
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
        
        //XCTAssertEqual([[[table where] column:INT_COL isBetweenInt:859 and_:861] find:0], (NSUInteger) 1, @"find");
        
        // XCTAssertEqual([[[[table where] column:INT_COL isBetweenInt:859 and_:861] findAll] class], [RLMView class], @"findAll");
        
        XCTAssertEqual([[table where] minIntInColumnWithIndex:INT_COL], (int64_t)0, @"minIntInColumn");
        XCTAssertEqual([[table where] sumIntColumnWithIndex:INT_COL], (int64_t)860, @"IntCol max");
        
        // Realm/tightdb has whole second precision for time stamps so we need to truncate the time stamps
        XCTAssertEqual((time_t)[[[table where] minDateInColumnWithIndex:DATE_COL] timeIntervalSince1970], (time_t)[date1 timeIntervalSince1970], @"MinDateInColumn");
        XCTAssertEqual((time_t)[[[table where] maxDateInColumnWithIndex:DATE_COL] timeIntervalSince1970], (time_t)[date2 timeIntervalSince1970], @"MaxDateInColumn");
        
        /// TODO: Tests missing....
    }];
}

- (void)testMathOperations
{
    [self createTestTableWithWriteBlock:^(RLMTable *table) {
        NSUInteger intCol = [table addColumnWithName:@"IntCol" type:RLMTypeInt];
        NSUInteger floatCol = [table addColumnWithName:@"FloatCol" type:RLMTypeFloat];
        NSUInteger doubleCol = [table addColumnWithName:@"DoubleCol" type:RLMTypeDouble];
        NSUInteger dateCol = [table addColumnWithName:@"DateCol" type:RLMTypeDate];
        
        ////////// Zero rows added ///////////
        
        // Using specific column type operations MIN
        XCTAssertEqual([[table where] minIntInColumnWithIndex:intCol], NSIntegerMax);
        XCTAssertEqual([[table where] minFloatInColumnWithIndex:floatCol], (float)INFINITY);
        XCTAssertEqual([[table where] minDoubleInColumnWithIndex:doubleCol], (double)INFINITY);
        XCTAssertNil([[table where] minDateInColumnWithIndex:dateCol]);
        
        // Using generic column type operations MIN
        XCTAssertEqualObjects([[table where] minInColumnWithIndex:intCol], @NSIntegerMax);
        XCTAssertEqual([[[table where] minInColumnWithIndex:floatCol] floatValue], (float)INFINITY);
        XCTAssertEqual([[[table where] minInColumnWithIndex:doubleCol] doubleValue], (double)INFINITY);
        XCTAssertNil([[table where] minInColumnWithIndex:dateCol]);
        
        // Using specific column type operations MAX
        XCTAssertEqual([[table where] maxIntInColumnWithIndex:intCol], NSIntegerMin);
        XCTAssertEqual([[table where] maxFloatInColumnWithIndex:floatCol], (float)-INFINITY);
        XCTAssertEqual([[table where] maxDoubleInColumnWithIndex:doubleCol], (double)-INFINITY);
        XCTAssertNil([[table where] maxDateInColumnWithIndex:dateCol]);
        
        // Using generic column type operations MAX
        XCTAssertEqualObjects([[table where] maxInColumnWithIndex:intCol], @NSIntegerMin);
        XCTAssertEqual([[[table where] maxInColumnWithIndex:floatCol] floatValue], (float)-INFINITY);
        XCTAssertEqual([[[table where] maxInColumnWithIndex:doubleCol] doubleValue], (double)-INFINITY);
        XCTAssertNil([[table where] maxInColumnWithIndex:dateCol]);
        
        // Using specific column type operations SUM
        XCTAssertEqual([[table where] sumIntColumnWithIndex:intCol], (int64_t)0);
        XCTAssertEqual([[table where] sumFloatColumnWithIndex:floatCol], (double)0);
        XCTAssertEqual([[table where] sumDoubleColumnWithIndex:doubleCol], (double)0);
        
        // Using generic column type operations SUM
        XCTAssertEqualObjects([[table where] sumColumnWithIndex:intCol], @0);
        XCTAssertEqual([[[table where] sumColumnWithIndex:floatCol] doubleValue], (double)0);
        XCTAssertEqual([[[table where] sumColumnWithIndex:doubleCol] doubleValue], (double)0);
        
        // Using specific column type operations AVG
        XCTAssertEqual([[table where] avgIntColumnWithIndex:intCol], (double)0);
        XCTAssertEqual([[table where] avgFloatColumnWithIndex:floatCol], (double)0);
        XCTAssertEqual([[table where] avgDoubleColumnWithIndex:doubleCol], (double)0);
        
        // Using generic column type operations AVG
        XCTAssertEqualObjects([[table where] avgColumnWithIndex:intCol], @0);
        XCTAssertEqual([[[table where] avgColumnWithIndex:floatCol] doubleValue], (double)0);
        XCTAssertEqual([[[table where] avgColumnWithIndex:doubleCol] doubleValue], (double)0);
        
        ////////// Add rows with values ///////////
        
        NSDate *date3 = [NSDate date];
        NSDate *date33 = [date3 dateByAddingTimeInterval:1];
        NSDate *date333 = [date33 dateByAddingTimeInterval:1];
        
        [table addRow:@[@3, @3.3f, @3.3, date3]];
        [table addRow:@[@33, @33.33f, @33.33, date33]];
        [table addRow:@[@333, @333.333f, @333.333, date333]];
        
        // Using specific column type operations MIN
        XCTAssertEqual([[table where] minIntInColumnWithIndex:intCol], (int64_t)3);
        XCTAssertEqualWithAccuracy([[table where] minFloatInColumnWithIndex:floatCol], (float)3.3, 0.1);
        XCTAssertEqualWithAccuracy([[table where] minDoubleInColumnWithIndex:doubleCol], (double)3.3, 0.1);
        XCTAssertEqualWithAccuracy([[table where] minDateInColumnWithIndex:dateCol].timeIntervalSince1970, date3.timeIntervalSince1970, 0.999);
        
        // Using generic column type operations MIN
        XCTAssertEqualObjects([[table where] minInColumnWithIndex:intCol], @3);
        XCTAssertEqual([[[table where] minInColumnWithIndex:floatCol] floatValue], (float)3.3);
        XCTAssertEqual([[[table where] minInColumnWithIndex:doubleCol] doubleValue], (double)3.3);
        NSDate *minOutDate = [[table where] minInColumnWithIndex:dateCol];
        XCTAssertEqualWithAccuracy(minOutDate.timeIntervalSince1970, date3.timeIntervalSince1970, 0.999);
        
        // Using specific column type operations MAX
        XCTAssertEqual([[table where] maxIntInColumnWithIndex:intCol], (int64_t)333);
        XCTAssertEqualWithAccuracy([[table where] maxFloatInColumnWithIndex:floatCol], (float)333.333, 0.1);
        XCTAssertEqualWithAccuracy([[table where] maxDoubleInColumnWithIndex:doubleCol], (double)333.333, 0.1);
        XCTAssertEqualWithAccuracy([[table where] maxDateInColumnWithIndex:dateCol].timeIntervalSince1970, date333.timeIntervalSince1970, 0.999);
        
        // Using generic column type operations MAX
        XCTAssertEqualObjects([[table where] maxInColumnWithIndex:intCol], @333);
        XCTAssertEqual([[[table where] maxInColumnWithIndex:floatCol] floatValue], (float)333.333);
        XCTAssertEqual([[[table where] maxInColumnWithIndex:doubleCol] doubleValue], (double)333.333);
        NSDate *maxOutDate = [[table where] maxInColumnWithIndex:dateCol];
        XCTAssertEqualWithAccuracy(maxOutDate.timeIntervalSince1970, date333.timeIntervalSince1970, 0.999);
        
        // Using specific column type operations SUM
        XCTAssertEqual([[table where] sumIntColumnWithIndex:intCol], (int64_t)369);
        XCTAssertEqualWithAccuracy([[table where] sumFloatColumnWithIndex:floatCol], (double)369.963, 0.1);
        XCTAssertEqualWithAccuracy([[table where] sumDoubleColumnWithIndex:doubleCol], (double)369.963, 0.1);
        
        // Using generic column type operations SUM
        XCTAssertEqualObjects([[table where] sumColumnWithIndex:intCol], @369);
        XCTAssertEqualWithAccuracy([[[table where] sumColumnWithIndex:floatCol] doubleValue], (double)369.963, 0.1);
        XCTAssertEqualWithAccuracy([[[table where] sumColumnWithIndex:doubleCol] doubleValue], (double)369.963, 0.1);
        
        // Using specific column type operations AVG
        XCTAssertEqual([[table where] avgIntColumnWithIndex:intCol], (double)123);
        XCTAssertEqualWithAccuracy([[table where] avgFloatColumnWithIndex:floatCol], (double)123.321, 0.1);
        XCTAssertEqualWithAccuracy([[table where] avgDoubleColumnWithIndex:doubleCol], (double)123.321, 0.1);
        
        // Using generic column type operations AVG
        XCTAssertEqualObjects([[table where] avgColumnWithIndex:intCol], @123);
        XCTAssertEqualWithAccuracy([[[table where] avgColumnWithIndex:floatCol] doubleValue], (double)123.321, 0.1);
        XCTAssertEqualWithAccuracy([[[table where] avgColumnWithIndex:doubleCol] doubleValue], (double)123.321, 0.1);
    }];
}


- (void)testFind
{
    [self createTestTableWithWriteBlock:^(RLMTable *table) {
        [table addColumnWithName:@"IntCol" type:RLMTypeInt];
        [table RLM_addEmptyRows:6];
        
        [table RLM_setInt:10 inColumnWithIndex:0 atRowIndex:0];
        [table RLM_setInt:42 inColumnWithIndex:0 atRowIndex:1];
        [table RLM_setInt:27 inColumnWithIndex:0 atRowIndex:2];
        [table RLM_setInt:31 inColumnWithIndex:0 atRowIndex:3];
        [table RLM_setInt:8  inColumnWithIndex:0 atRowIndex:4];
        [table RLM_setInt:39 inColumnWithIndex:0 atRowIndex:5];
        
        XCTAssertEqual((NSUInteger)1, [[[table where ] intIsGreaterThan:10 inColumnWithIndex:0 ] indexOfFirstMatchingRow], @"Row 1 is greater than 10");
        XCTAssertEqual(NSNotFound, [[[table where ] intIsGreaterThan:100 inColumnWithIndex:0 ] indexOfFirstMatchingRow], @"No rows are greater than 100");
        
        XCTAssertEqual([[[table where] intIsBetween:20 :40 inColumnWithIndex:0] indexOfFirstMatchingRowFromIndex:0], (NSUInteger)2,  @"find");
        XCTAssertEqual([[[table where] intIsBetween:20 :40 inColumnWithIndex:0] indexOfFirstMatchingRowFromIndex:3], (NSUInteger)3,  @"find");
        XCTAssertEqual([[[table where] intIsBetween:20 :40 inColumnWithIndex:0] indexOfFirstMatchingRowFromIndex:4], (NSUInteger)5,  @"find");
        XCTAssertEqual([[[table where] intIsBetween:20 :40 inColumnWithIndex:0] indexOfFirstMatchingRowFromIndex:6], (NSUInteger)NSNotFound, @"find");
        XCTAssertEqual([[[table where] intIsBetween:20 :40 inColumnWithIndex:0] indexOfFirstMatchingRowFromIndex:3], (NSUInteger)3,  @"find");
        // jjepsen: disabled this test, perhaps it's not relevant after query sematics update.
        //XCTAssertEqual([[[table where] column:0 isBetweenInt:20 and_:40] find:-1], (NSUInteger)-1, @"find");
        
        [table removeAllRows];
        XCTAssertEqual([[table where] indexOfFirstMatchingRow], NSNotFound, @"");
        XCTAssertEqual([[table where] indexOfFirstMatchingRowFromIndex:0], NSNotFound, @"");
    }];
}

- (void) testSubtableQuery
{
    [self createTestTableWithWriteBlock:^(RLMTable *table) {
        RLMDescriptor *d = table.descriptor;
        RLMDescriptor *subDesc = [d addColumnTable:@"subtable"];
        [subDesc addColumnWithName:@"subCol" type:RLMTypeBool];
        [table addRow:nil];
        XCTAssertEqual(table.rowCount, (NSUInteger)1,@"one row added");
        
        RLMTable * subTable = [table RLM_tableInColumnWithIndex:0 atRowIndex:0];
        [subTable addRow:nil];
        [subTable RLM_setBool:YES inColumnWithIndex:0 atRowIndex:0];
        RLMQuery *q = [table where];
        
        RLMView *v = [[[[q subtableInColumnWithIndex:0] boolIsEqualTo:YES inColumnWithIndex:0] parent] findAllRows];
        XCTAssertEqual(v.rowCount, (NSUInteger)1,@"one match");
    }];
}

-(void) testQueryEnumeratorNoCondition
{
    [self createTestTableWithWriteBlock:^(RLMTable *table) {
        [table addColumnWithName:@"first" type:RLMTypeInt];
        for(int i=0; i<10; ++i)
            [table addRow:@[[NSNumber numberWithInt:i]]];
        RLMQuery *query = [table where];
        int i = 0;
        for(RLMRow *row in query) {
            XCTAssertEqual((int64_t)i, [(NSNumber *)row[@"first"] longLongValue], @"Wrong value");
            ++i;
        }
    }];
}

-(void) testQueryEnumeratorWithCondition
{
    [self createTestTableWithWriteBlock:^(RLMTable *table) {
        [table addColumnWithName:@"first" type:RLMTypeInt];
        for(int i=0; i<10; ++i)
            [table addRow:@[[NSNumber numberWithInt:i]]];
        RLMQuery *query = [[table where] intIsGreaterThan:-1 inColumnWithIndex:0];
        int i = 0;
        for(RLMRow *row in query) {
            XCTAssertEqual((int64_t)i, [(NSNumber *)row[@"first"] longLongValue], @"Wrong value");
            ++i;
        }
    }];
}

#pragma mark - Predicates

- (void)testDatePredicates
{
    [self createTestTableWithWriteBlock:^(RLMTable *table) {
        [table addColumnWithName:@"date" type:RLMTypeDate];
        NSArray *dates = @[[NSDate dateWithTimeIntervalSince1970:0],
                           [NSDate dateWithTimeIntervalSince1970:1],
                           [NSDate dateWithTimeIntervalSince1970:2],
                           [NSDate dateWithTimeIntervalSince1970:3]];
        for (NSDate *date in dates) {
            [table addRow:@[date]];
        }
        
        NSDate *date = dates[1];
        
        // Lesser than
        [self testPredicate:[NSPredicate predicateWithFormat:@"date < %@", date]
                    onTable:table
                withResults:[dates subarrayWithRange:NSMakeRange(0, 1)]
                       name:@"lesser than"
                     column:@"date"];
        
        // Lesser than or equal
        [self testPredicate:[NSPredicate predicateWithFormat:@"date <= %@", date]
                    onTable:table
                withResults:[dates subarrayWithRange:NSMakeRange(0, 2)]
                       name:@"lesser than or equal"
                     column:@"date"];
        
        // Equal (single '=')
        [self testPredicate:[NSPredicate predicateWithFormat:@"date = %@", date]
                    onTable:table
                withResults:[dates subarrayWithRange:NSMakeRange(1, 1)]
                       name:@"equal(1)"
                     column:@"date"];
        
        // Equal (double '=')
        [self testPredicate:[NSPredicate predicateWithFormat:@"date == %@", date]
                    onTable:table
                withResults:[dates subarrayWithRange:NSMakeRange(1, 1)]
                       name:@"equal(2)"
                     column:@"date"];
        
        // Greater than or equal
        [self testPredicate:[NSPredicate predicateWithFormat:@"date >= %@", date]
                    onTable:table
                withResults:[dates subarrayWithRange:NSMakeRange(1, 3)]
                       name:@"greater than or equal"
                     column:@"date"];
        
        // Greater than
        [self testPredicate:[NSPredicate predicateWithFormat:@"date > %@", date]
                    onTable:table
                withResults:[dates subarrayWithRange:NSMakeRange(2, 2)]
                       name:@"greater than"
                     column:@"date"];
        
        // Not equal
        [self testPredicate:[NSPredicate predicateWithFormat:@"date != %@", date]
                    onTable:table
                withResults:@[dates[0], dates[2], dates[3]]
                       name:@"not equal"
                     column:@"date"];
    }];
}

- (void)testStringPredicates
{
    [self createTestTableWithWriteBlock:^(RLMTable *table) {
        [table addColumnWithName:@"string" type:RLMTypeString];
        NSArray *strings = @[@"a",
                             @"ab",
                             @"abc",
                             @"abcd"];
        for (NSString *string in strings) {
            [table addRow:@[string]];
        }
        
        // Equal
        [self testPredicate:[NSPredicate predicateWithFormat:@"string == %@", @"a"]
                    onTable:table
                withResults:[strings subarrayWithRange:NSMakeRange(0, 1)]
                       name:@"equal"
                     column:@"string"];
        
        // Equal (fail)
        [self testPredicate:[NSPredicate predicateWithFormat:@"string == %@", @"A"]
                    onTable:table
                withResults:@[]
                       name:@"equal (fail)"
                     column:@"string"];
        
        // Not equal
        [self testPredicate:[NSPredicate predicateWithFormat:@"string != %@", @"a"]
                    onTable:table
                withResults:[strings subarrayWithRange:NSMakeRange(1, 3)]
                       name:@"not equal"
                     column:@"string"];
        
        // Begins with
        [self testPredicate:[NSPredicate predicateWithFormat:@"string beginswith %@", @"ab"]
                    onTable:table
                withResults:[strings subarrayWithRange:NSMakeRange(1, 3)]
                       name:@"beginswith"
                     column:@"string"];
        
        // Begins with (fail)
        [self testPredicate:[NSPredicate predicateWithFormat:@"string beginswith %@", @"A"]
                    onTable:table
                withResults:@[]
                       name:@"beginswith (fail)"
                     column:@"string"];
        
        // Contains
        [self testPredicate:[NSPredicate predicateWithFormat:@"string contains %@", @"bc"]
                    onTable:table
                withResults:[strings subarrayWithRange:NSMakeRange(2, 2)]
                       name:@"contains"
                     column:@"string"];
        
        // Ends with
        [self testPredicate:[NSPredicate predicateWithFormat:@"string endswith %@", @"cd"]
                    onTable:table
                withResults:@[strings.lastObject]
                       name:@"endswith"
                     column:@"string"];
        
        // NSCaseInsensitivePredicateOption
        [self testPredicate:[NSPredicate predicateWithFormat:@"string contains[c] %@", @"C"]
                    onTable:table
                withResults:[strings subarrayWithRange:NSMakeRange(2, 2)]
                       name:@"NSCaseInsensitivePredicateOption"
                     column:@"string"];
        
        // NSDiacriticInsensitivePredicateOption
        {
            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"string contains[d] %@", @"ç"];
            XCTAssertThrows([table where:predicate],
                            @"String predicate with diacritic insensitive option should throw");
        }
    }];
}

#pragma mark - Predicate Helpers

- (void)testPredicate:(NSPredicate *)predicate
              onTable:(RLMTable *)table
          withResults:(NSArray *)results
                 name:(NSString *)name
               column:(NSString *)column
{
    RLMView *view = [table where:predicate];
    XCTAssertEqual(view.rowCount,
                   results.count,
                   @"%@ predicate should return correct count", name);
    for (NSInteger i = 0; i < results.count; i++) {
        XCTAssertEqualObjects(results[i],
                              view[i][column],
                              @"%@ predicate should return correct results", name);
    }
}

@end
