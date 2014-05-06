//
//  query.m
//  TightDB
//

#import "RLMTestCase.h"

#import <realm/objc/Realm.h>
#import <realm/objc/RLMQueryFast.h>
#import <realm/objc/RLMTableFast.h>

@interface TestQueryObj : RLMRow

@property (nonatomic, assign) NSInteger age;

@end

@implementation TestQueryObj
@end

RLM_TABLE_TYPE_FOR_OBJECT_TYPE(TestQueryTable2, TestQueryObj);

@interface TestQueryAllObj : RLMRow

@property (nonatomic, assign) BOOL      BoolCol;
@property (nonatomic, assign) NSInteger IntCol;
@property (nonatomic, assign) float     FloatCol;
@property (nonatomic, assign) double    DoubleCol;
@property (nonatomic, copy)   NSString *StringCol;
@property (nonatomic, strong) NSData   *BinaryCol;
@property (nonatomic, strong) NSDate   *DateCol;
//@property (nonatomic, strong) TestQueryTable2 *TableCol; // FIXME
@property (nonatomic, strong) id        MixedCol;

@end

@implementation TestQueryAllObj
@end

RLM_TABLE_TYPE_FOR_OBJECT_TYPE(TestQueryAllTable2, TestQueryAllObj);

@interface MACtestQuery: RLMTestCase

@end

@implementation MACtestQuery

- (void)testQuery {
    
    [self.realmWithTestPath writeUsingBlock:^(RLMRealm *realm) {
        TestQueryAllTable2 *table = [TestQueryAllTable2 tableInRealm:realm named:@"table"];
        NSLog(@"Table: %@", table);
        XCTAssertNotNil(table, @"Table is nil");
        
        const char bin[4] = { 0, 1, 2, 3 };
        NSData *bin1 = [[NSData alloc] initWithBytes:bin length:sizeof bin / 2];
        NSData *bin2 = [[NSData alloc] initWithBytes:bin length:sizeof bin];
        
        TestQueryTable2 *subtable = [TestQueryTable2 tableInRealm:realm named:@"subtable"];
        [subtable addRow:@[@22]];
        
        NSDate *zeroDate = [NSDate dateWithTimeIntervalSince1970:0];
        [table addRow:@[@NO, @54, @(0.7f), @0.8, @"foo", bin1, zeroDate, @2]];
        [table addRow:@[@YES, @506, @(7.7f), @8.8, @"banach", bin2, [NSDate date], @"bar"]];
        
        XCTAssertEqual([[table allWhere:@"BoolCol == NO"] rowCount], (NSUInteger)1, @"BoolCol equal");
        XCTAssertEqual([[table allWhere:@"IntCol == 54"] rowCount], (NSUInteger)1, @"IntCol equal");
        NSUInteger floatCount = [[table allWhere:@"FloatCol == %@", @(0.7f)] rowCount];
        XCTAssertEqual(floatCount, (NSUInteger)1, @"FloatCol equal");
        XCTAssertEqual([[table allWhere:@"DoubleCol == 0.8"] rowCount], (NSUInteger)1, @"DoubleCol equal");
        XCTAssertEqual([[table allWhere:@"StringCol == 'foo'"] rowCount], (NSUInteger)1, @"StringCol equal");
        NSUInteger binaryCount = [[table allWhere:@"BinaryCol == %@", bin1] rowCount];
        XCTAssertEqual(binaryCount, (NSUInteger)1, @"BinaryCol equal");
        NSUInteger dateCount = [[table allWhere:@"DateCol == %@", zeroDate] rowCount];
        XCTAssertEqual(dateCount, (NSUInteger)1, @"DateCol equal");
        // These are not yet implemented
        // NSUInteger subtableCount = [[table allWhere:@"TableCol == %@", subtable] rowCount];
        // XCTAssertEqual(subtableCount, (NSUInteger)1, @"TableCol equal");
        // NSUInteger mixedCount = [[table allWhere:@"MixedCol == %@", @"bar"] rowCount];
        // XCTAssertEqual(mixedCount, (NSUInteger)1, @"MixedCol equal");
        
        NSString *predicate = @"BoolCol == NO";
        
        XCTAssertEqual([[table minOfProperty:@"IntCol" where:predicate] integerValue], (NSUInteger)54, @"IntCol min");
        XCTAssertEqual([[table maxOfProperty:@"IntCol" where:predicate] integerValue], (NSUInteger)54, @"IntCol max");
        XCTAssertEqual([[table sumOfProperty:@"IntCol" where:predicate] integerValue], (NSUInteger)54, @"IntCol sum");
        XCTAssertEqual([[table averageOfProperty:@"IntCol" where:predicate] integerValue], (NSUInteger)54, @"IntCol avg");
        
        XCTAssertEqual([[table minOfProperty:@"FloatCol" where:predicate] floatValue], (float)0.7f, @"FloatCol min");
        XCTAssertEqual([[table maxOfProperty:@"FloatCol" where:predicate] floatValue], (float)0.7f, @"FloatCol max");
        XCTAssertEqual([[table sumOfProperty:@"FloatCol" where:predicate] floatValue], (float)0.7f, @"FloatCol sum");
        XCTAssertEqual([[table averageOfProperty:@"FloatCol" where:predicate] floatValue], (float)0.7f, @"FloatCol avg");
        
        XCTAssertEqual([[table minOfProperty:@"DoubleCol" where:predicate] doubleValue], (double)0.8, @"DoubleCol min");
        XCTAssertEqual([[table maxOfProperty:@"DoubleCol" where:predicate] doubleValue], (double)0.8, @"DoubleCol max");
        XCTAssertEqual([[table sumOfProperty:@"DoubleCol" where:predicate] doubleValue], (double)0.8, @"DoubleCol sum");
        XCTAssertEqual([[table averageOfProperty:@"DoubleCol" where:predicate] doubleValue], (double)0.8, @"DoubleCol avg");
    }];

}

#define BOOL_COL   0
#define INT_COL    1
#define FLOAT_COL  2
#define DOUBLE_COL 3
#define STRING_COL 4
#define BINARY_COL 5
#define DATE_COL   6
#define MIXED_COL  7

- (void)testDynamic {
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
        
        // Conditions
        NSUInteger betweenCount = [table countWhere:@"IntCol between %@", @[@859, @861]];
        XCTAssertEqual(betweenCount, (NSUInteger)1, @"betweenInt");
        betweenCount = [table countWhere:@"FloatCol between %@", @[@(5.5f), @(5.7f)]];
        XCTAssertEqual(betweenCount, (NSUInteger)1, @"betweenFloat");
        betweenCount = [table countWhere:@"DoubleCol between %@", @[@5.5, @5.7]];
        XCTAssertEqual(betweenCount, (NSUInteger)1, @"betweenDouble");
        betweenCount = [table countWhere:@"DateCol between %@", @[date1, date2]];
        XCTAssertEqual(betweenCount, (NSUInteger)2, @"betweenDate");
        
        {
            XCTAssertEqual([table countWhere:@"BoolCol == YES"], (NSUInteger)1, @"isEqualToBool");
            XCTAssertEqual([table countWhere:@"IntCol == 860"], (NSUInteger)1, @"isEqualToInt");
            NSUInteger floatCount = [table countWhere:@"FloatCol == %f", 5.6];
            XCTAssertEqual(floatCount, (NSUInteger)1, @"isEqualToFloat");
            XCTAssertEqual([table countWhere:@"DoubleCol == 5.6"], (NSUInteger)1, @"isEqualToDouble");
            XCTAssertEqual([table countWhere:@"StringCol == 'foo'"], (NSUInteger)1, @"isEqualToString");
            XCTAssertEqual([table countWhere:@"StringCol ==[c] 'Foo'"], (NSUInteger)1, @"isEqualToStringCaseNo");
            NSUInteger dateCount = [table countWhere:@"DateCol == %@", date1];
            XCTAssertEqual(dateCount, (NSUInteger)1, @"isEqualToDate");
            NSUInteger binCount = [table countWhere:@"BinaryCol == %@", bin1];
            XCTAssertEqual(binCount, (NSUInteger)1, @"isEqualToBinary");
        }
        
        {
            XCTAssertEqual([table countWhere:@"BoolCol != YES"], (NSUInteger)1, @"isNotEqualToBool");
            XCTAssertEqual([table countWhere:@"IntCol != 860"], (NSUInteger)1, @"isNotEqualToInt");
            NSUInteger floatCount = [table countWhere:@"FloatCol != %f", 5.6];
            XCTAssertEqual(floatCount, (NSUInteger)1, @"isEqualToFloat");
            XCTAssertEqual([table countWhere:@"DoubleCol != 5.6"], (NSUInteger)1, @"isNotEqualToDouble");
            XCTAssertEqual([table countWhere:@"StringCol != 'foo'"], (NSUInteger)1, @"isNotEqualToString");
            XCTAssertEqual([table countWhere:@"StringCol !=[c] 'Foo'"], (NSUInteger)1, @"isNotEqualToStringCaseNo");
            NSUInteger dateCount = [table countWhere:@"DateCol != %@", date1];
            XCTAssertEqual(dateCount, (NSUInteger)1, @"isNotEqualToDate");
            NSUInteger binCount = [table countWhere:@"BinaryCol != %@", bin1];
            XCTAssertEqual(binCount, (NSUInteger)1, @"isNotEqualToBinary");
        }
        
        {
            XCTAssertEqual([table countWhere:@"IntCol > 859"], (NSUInteger)1, @"isGreaterThanInt");
            NSUInteger floatCount = [table countWhere:@"FloatCol > %f", 5.5];
            XCTAssertEqual(floatCount, (NSUInteger)1, @"isGreaterThanFloat");
            XCTAssertEqual([table countWhere:@"DoubleCol > 5.5"], (NSUInteger)1, @"isGreaterThanDouble");
            NSUInteger dateCount = [table countWhere:@"DateCol > %@", date1];
            XCTAssertEqual(dateCount, (NSUInteger)1, @"isGreaterThanDate");
        }
        
        {
            XCTAssertEqual([table countWhere:@"IntCol >= 860"], (NSUInteger)1, @"isGreaterThanOrEqualToInt");
            NSUInteger floatCount = [table countWhere:@"FloatCol >= %f", 5.6];
            XCTAssertEqual(floatCount, (NSUInteger)1, @"isGreaterThanOrEqualToFloat");
            XCTAssertEqual([table countWhere:@"DoubleCol >= 5.6"], (NSUInteger)1, @"isGreaterThanOrEqualToDouble");
            NSUInteger dateCount = [table countWhere:@"DateCol >= %@", date1];
            XCTAssertEqual(dateCount, (NSUInteger)2, @"isGreaterThanOrEqualToDate");
        }
        
        {
            XCTAssertEqual([table countWhere:@"IntCol < 860"], (NSUInteger)1, @"isLessThanInt");
            NSUInteger floatCount = [table countWhere:@"FloatCol < %f", 5.6];
            XCTAssertEqual(floatCount, (NSUInteger)1, @"isLessThanFloat");
            XCTAssertEqual([table countWhere:@"DoubleCol < 5.6"], (NSUInteger)1, @"isLessThanDouble");
            NSUInteger dateCount = [table countWhere:@"DateCol < %@", date2];
            XCTAssertEqual(dateCount, (NSUInteger)1, @"isLessThanDate");
        }
        
        {
            XCTAssertEqual([table countWhere:@"IntCol <= 860"], (NSUInteger)2, @"isLessThanOrEqualToInt");
            NSUInteger floatCount = [table countWhere:@"FloatCol <= %f", 5.6];
            XCTAssertEqual(floatCount, (NSUInteger)2, @"isLessThanOrEqualToFloat");
            XCTAssertEqual([table countWhere:@"DoubleCol <= 5.6"], (NSUInteger)2, @"isLessThanOrEqualToDouble");
            NSUInteger dateCount = [table countWhere:@"DateCol <= %@", date2];
            XCTAssertEqual(dateCount, (NSUInteger)2, @"isLessThanOrEqualToDate");
        }
        
        XCTAssertEqualObjects([table minOfProperty:@"IntCol" where:nil], @0, @"IntCol min");
        XCTAssertEqualObjects([table maxOfProperty:@"IntCol" where:nil], @860, @"IntCol max");
        XCTAssertEqualObjects([table sumOfProperty:@"IntCol" where:nil], @860, @"IntCol sum");
        XCTAssertEqualObjects([table averageOfProperty:@"IntCol" where:nil], @430, @"IntCol avg");
        
        // FIXME: Support min/max on dates
        // Realm/tightdb has whole second precision for time stamps so we need to truncate the time stamps
        // XCTAssertEqual((time_t)[[table minOfProperty:@"DateCol" where:nil] timeIntervalSince1970], (time_t)[date1 timeIntervalSince1970], @"MinDateInColumn");
        // XCTAssertEqual((time_t)[[table maxOfProperty:@"DateCol" where:nil] timeIntervalSince1970], (time_t)[date2 timeIntervalSince1970], @"MaxDateInColumn");
    }];
}

- (void)testMathOperations {
    [self createTestTableWithWriteBlock:^(RLMTable *table) {
        [table addColumnWithName:@"IntCol" type:RLMTypeInt];
        [table addColumnWithName:@"FloatCol" type:RLMTypeFloat];
        [table addColumnWithName:@"DoubleCol" type:RLMTypeDouble];
        [table addColumnWithName:@"DateCol" type:RLMTypeDate];
        
        //======== Zero rows added ========//
        
        // Min
        XCTAssertEqual([[table minOfProperty:@"IntCol" where:nil] integerValue], NSIntegerMax);
        XCTAssertEqual([[table minOfProperty:@"FloatCol" where:nil] floatValue], (float)INFINITY);
        XCTAssertEqual([[table minOfProperty:@"DoubleCol" where:nil] doubleValue], (double)INFINITY);
        // FIXME: Support min/max on dates
        // XCTAssertNil([table minOfProperty:@"DateCol" where:nil]);
        
        // Max
        XCTAssertEqual([[table maxOfProperty:@"IntCol" where:nil] integerValue], NSIntegerMin);
        XCTAssertEqual([[table maxOfProperty:@"FloatCol" where:nil] floatValue], (float)-INFINITY);
        XCTAssertEqual([[table maxOfProperty:@"DoubleCol" where:nil] doubleValue], (double)-INFINITY);
        // FIXME: Support min/max on dates
        // XCTAssertNil([table maxOfProperty:@"DateCol" where:nil]);
        
        // Sum
        XCTAssertEqual([[table sumOfProperty:@"IntCol" where:nil] integerValue], (NSInteger)0);
        XCTAssertEqual([[table sumOfProperty:@"FloatCol" where:nil] floatValue], (float)0);
        XCTAssertEqual([[table sumOfProperty:@"DoubleCol" where:nil] doubleValue], (double)0);
        
        // Average
        XCTAssertEqual([[table averageOfProperty:@"IntCol" where:nil] integerValue], (NSInteger)0);
        XCTAssertEqual([[table averageOfProperty:@"FloatCol" where:nil] floatValue], (float)0);
        XCTAssertEqual([[table averageOfProperty:@"DoubleCol" where:nil] doubleValue], (double)0);
        
        //======== Add rows with values ========//
        
        NSDate *date3 = [NSDate date];
        NSDate *date33 = [date3 dateByAddingTimeInterval:1];
        NSDate *date333 = [date33 dateByAddingTimeInterval:1];
        
        [table addRow:@[@3, @3.3f, @3.3, date3]];
        [table addRow:@[@33, @33.33f, @33.33, date33]];
        [table addRow:@[@333, @333.333f, @333.333, date333]];
        
        // Min
        XCTAssertEqual([[table minOfProperty:@"IntCol" where:nil] integerValue], (NSInteger)3);
        XCTAssertEqualWithAccuracy([[table minOfProperty:@"FloatCol" where:nil] floatValue], (float)3.3, 0.1);
        XCTAssertEqualWithAccuracy([[table minOfProperty:@"DoubleCol" where:nil] doubleValue], (double)3.3, 0.1);
        // FIXME: Support min/max on dates
        // XCTAssertEqualWithAccuracy([(NSDate *)[table minOfProperty:@"DateCol" where:nil] timeIntervalSince1970], date3.timeIntervalSince1970, 0.999);
        
        // Max
        XCTAssertEqual([[table maxOfProperty:@"IntCol" where:nil] integerValue], (NSInteger)333);
        XCTAssertEqualWithAccuracy([[table maxOfProperty:@"FloatCol" where:nil] floatValue], (float)333.333, 0.1);
        XCTAssertEqualWithAccuracy([[table maxOfProperty:@"DoubleCol" where:nil] doubleValue], (double)333.333, 0.1);
        // FIXME: Support min/max on dates
        // XCTAssertEqualWithAccuracy([(NSDate *)[table maxOfProperty:@"DateCol" where:nil] timeIntervalSince1970], date333.timeIntervalSince1970, 0.999);
        
        // Sum
        XCTAssertEqual([[table sumOfProperty:@"IntCol" where:nil] integerValue], (NSInteger)369);
        XCTAssertEqualWithAccuracy([[table sumOfProperty:@"FloatCol" where:nil] floatValue], (float)369.963, 0.1);
        XCTAssertEqualWithAccuracy([[table sumOfProperty:@"DoubleCol" where:nil] doubleValue], (double)369.963, 0.1);
        
        // Average
        XCTAssertEqual([[table averageOfProperty:@"IntCol" where:nil] doubleValue], (double)123);
        XCTAssertEqualWithAccuracy([[table averageOfProperty:@"FloatCol" where:nil] doubleValue], (double)123.321, 0.1);
        XCTAssertEqualWithAccuracy([[table averageOfProperty:@"DoubleCol" where:nil] doubleValue], (double)123.321, 0.1);
    }];
}

- (void)testFind {
    [self createTestTableWithWriteBlock:^(RLMTable *table) {
        [table addColumnWithName:@"IntCol" type:RLMTypeInt];
        // Add 6 empty rows
        for (NSUInteger index = 0; index < 6; index++) {
            [table addRow:nil];
        }
        table[0][@"IntCol"] = @10;
        table[1][@"IntCol"] = @42;
        table[2][@"IntCol"] = @27;
        table[3][@"IntCol"] = @31;
        table[4][@"IntCol"] = @8;
        table[5][@"IntCol"] = @39;
        
        XCTAssertEqualObjects([table firstWhere:@"IntCol > 10"][@"IntCol"], @42, @"Row 1 is greater than 10");
        XCTAssertNil([table firstWhere:@"IntCol > 100"], @"No rows are greater than 100");
        RLMView *view = [table allWhere:@"IntCol between %@", @[@20, @40]];
        XCTAssertEqualObjects(view.firstRow[@"IntCol"], @27, @"The first row in the table with IntCol between 20 and 40 is 27");
        
        [table removeAllRows];
        XCTAssertNil([table firstWhere:nil]);
    }];
}

- (void)testSubtableQuery {
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

- (void)testQueryEnumeratorNoCondition {
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

- (void)testQueryEnumeratorWithCondition {
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

- (void)testIntegerPredicates {
    [self createTestTableWithWriteBlock:^(RLMTable *table) {
        [table addColumnWithName:@"int" type:RLMTypeInt];
        NSArray *ints = @[@0, @1, @2, @3];
        for (NSNumber *intNum in ints) {
            [table addRow:@[intNum]];
        }
        
        NSNumber *intNum = ints[1];
        
        // Lesser than
        [self testPredicate:[NSPredicate predicateWithFormat:@"int < %@", intNum]
                    onTable:table
                withResults:[ints subarrayWithRange:NSMakeRange(0, 1)]
                       name:@"lesser than"
                     column:@"int"];
        
        // Lesser than or equal
        [self testPredicate:[NSPredicate predicateWithFormat:@"int <= %@", intNum]
                    onTable:table
                withResults:[ints subarrayWithRange:NSMakeRange(0, 2)]
                       name:@"lesser than or equal"
                     column:@"int"];
        
        // Equal
        [self testPredicate:[NSPredicate predicateWithFormat:@"int == %@", intNum]
                    onTable:table
                withResults:[ints subarrayWithRange:NSMakeRange(1, 1)]
                       name:@"equal"
                     column:@"int"];

        // Greater than or equal
        [self testPredicate:[NSPredicate predicateWithFormat:@"int >= %@", intNum]
                    onTable:table
                withResults:[ints subarrayWithRange:NSMakeRange(1, 3)]
                       name:@"greater than or equal"
                     column:@"int"];

        // Greater than
        [self testPredicate:[NSPredicate predicateWithFormat:@"int > %@", intNum]
                    onTable:table
                withResults:[ints subarrayWithRange:NSMakeRange(2, 2)]
                       name:@"greater than"
                     column:@"int"];
        
        // Not equal
        [self testPredicate:[NSPredicate predicateWithFormat:@"int != %@", intNum]
                    onTable:table
                withResults:@[ints[0], ints[2], ints[3]]
                       name:@"not equal"
                     column:@"int"];
        
        // Between
        [self testPredicate:[NSPredicate predicateWithFormat:@"int between %@", @[intNum, ints.lastObject]]
                    onTable:table
                withResults:[ints subarrayWithRange:NSMakeRange(1, 3)]
                       name:@"between"
                     column:@"int"];
        
        // Between (inverse)
        [self testPredicate:[NSPredicate predicateWithFormat:@"int between %@", @[ints.lastObject, intNum]]
                    onTable:table
                withResults:@[]
                       name:@"between (inverse)"
                     column:@"int"];
        
        // AND
        [self testPredicate:[NSPredicate predicateWithFormat:@"int >= %@ && int <= %@", intNum, ints.lastObject]
                    onTable:table
                withResults:[ints subarrayWithRange:NSMakeRange(1, 3)]
                       name:@"AND"
                     column:@"int"];
        
        // OR
        [self testPredicate:[NSPredicate predicateWithFormat:@"int <= %@ || int >= %@", ints.firstObject, ints.lastObject]
                    onTable:table
                withResults:@[ints.firstObject, ints.lastObject]
                       name:@"OR"
                     column:@"int"];
    }];
}

- (void)testFloatPredicates {
    [self createTestTableWithWriteBlock:^(RLMTable *table) {
        [table addColumnWithName:@"float" type:RLMTypeFloat];
        NSArray *floats = @[@0, @1, @2, @3];
        for (NSNumber *floatNum in floats) {
            [table addRow:@[floatNum]];
        }
        
        NSNumber *floatNum = floats[1];
        
        // Lesser than
        [self testPredicate:[NSPredicate predicateWithFormat:@"float < %@", floatNum]
                    onTable:table
                withResults:[floats subarrayWithRange:NSMakeRange(0, 1)]
                       name:@"lesser than"
                     column:@"float"];
        
        // Lesser than or equal
        [self testPredicate:[NSPredicate predicateWithFormat:@"float <= %@", floatNum]
                    onTable:table
                withResults:[floats subarrayWithRange:NSMakeRange(0, 2)]
                       name:@"lesser than or equal"
                     column:@"float"];
        
        // Equal
        [self testPredicate:[NSPredicate predicateWithFormat:@"float == %@", floatNum]
                    onTable:table
                withResults:[floats subarrayWithRange:NSMakeRange(1, 1)]
                       name:@"equal"
                     column:@"float"];
        
        // Greater than or equal
        [self testPredicate:[NSPredicate predicateWithFormat:@"float >= %@", floatNum]
                    onTable:table
                withResults:[floats subarrayWithRange:NSMakeRange(1, 3)]
                       name:@"greater than or equal"
                     column:@"float"];
        
        // Greater than
        [self testPredicate:[NSPredicate predicateWithFormat:@"float > %@", floatNum]
                    onTable:table
                withResults:[floats subarrayWithRange:NSMakeRange(2, 2)]
                       name:@"greater than"
                     column:@"float"];
        
        // Not equal
        [self testPredicate:[NSPredicate predicateWithFormat:@"float != %@", floatNum]
                    onTable:table
                withResults:@[floats[0], floats[2], floats[3]]
                       name:@"not equal"
                     column:@"float"];
        
        // Between
        [self testPredicate:[NSPredicate predicateWithFormat:@"float between %@", @[floatNum, floats.lastObject]]
                    onTable:table
                withResults:[floats subarrayWithRange:NSMakeRange(1, 3)]
                       name:@"between"
                     column:@"float"];
        
        // Between (inverse)
        [self testPredicate:[NSPredicate predicateWithFormat:@"float between %@", @[floats.lastObject, floatNum]]
                    onTable:table
                withResults:@[]
                       name:@"between (inverse)"
                     column:@"float"];
        
        // AND
        [self testPredicate:[NSPredicate predicateWithFormat:@"float >= %@ && float <= %@", floatNum, floats.lastObject]
                    onTable:table
                withResults:[floats subarrayWithRange:NSMakeRange(1, 3)]
                       name:@"AND"
                     column:@"float"];
        
        // OR
        [self testPredicate:[NSPredicate predicateWithFormat:@"float <= %@ || float >= %@", floats.firstObject, floats.lastObject]
                    onTable:table
                withResults:@[floats.firstObject, floats.lastObject]
                       name:@"OR"
                     column:@"float"];
    }];
}

- (void)testDoublePredicates {
    [self createTestTableWithWriteBlock:^(RLMTable *table) {
        [table addColumnWithName:@"double" type:RLMTypeDouble];
        NSArray *doubles = @[@0, @1, @2, @3];
        for (NSNumber *doubleNum in doubles) {
            [table addRow:@[doubleNum]];
        }
        
        NSNumber *doubleNum = doubles[1];
        
        // Lesser than
        [self testPredicate:[NSPredicate predicateWithFormat:@"double < %@", doubleNum]
                    onTable:table
                withResults:[doubles subarrayWithRange:NSMakeRange(0, 1)]
                       name:@"lesser than"
                     column:@"double"];
        
        // Lesser than or equal
        [self testPredicate:[NSPredicate predicateWithFormat:@"double <= %@", doubleNum]
                    onTable:table
                withResults:[doubles subarrayWithRange:NSMakeRange(0, 2)]
                       name:@"lesser than or equal"
                     column:@"double"];
        
        // Equal
        [self testPredicate:[NSPredicate predicateWithFormat:@"double == %@", doubleNum]
                    onTable:table
                withResults:[doubles subarrayWithRange:NSMakeRange(1, 1)]
                       name:@"equal"
                     column:@"double"];
        
        // Greater than or equal
        [self testPredicate:[NSPredicate predicateWithFormat:@"double >= %@", doubleNum]
                    onTable:table
                withResults:[doubles subarrayWithRange:NSMakeRange(1, 3)]
                       name:@"greater than or equal"
                     column:@"double"];
        
        // Greater than
        [self testPredicate:[NSPredicate predicateWithFormat:@"double > %@", doubleNum]
                    onTable:table
                withResults:[doubles subarrayWithRange:NSMakeRange(2, 2)]
                       name:@"greater than"
                     column:@"double"];
        
        // Not equal
        [self testPredicate:[NSPredicate predicateWithFormat:@"double != %@", doubleNum]
                    onTable:table
                withResults:@[doubles[0], doubles[2], doubles[3]]
                       name:@"not equal"
                     column:@"double"];
        
        // Between
        [self testPredicate:[NSPredicate predicateWithFormat:@"double between %@", @[doubleNum, doubles.lastObject]]
                    onTable:table
                withResults:[doubles subarrayWithRange:NSMakeRange(1, 3)]
                       name:@"between"
                     column:@"double"];
        
        // Between (inverse)
        [self testPredicate:[NSPredicate predicateWithFormat:@"double between %@", @[doubles.lastObject, doubleNum]]
                    onTable:table
                withResults:@[]
                       name:@"between (inverse)"
                     column:@"double"];
        
        // AND
        [self testPredicate:[NSPredicate predicateWithFormat:@"double >= %@ && double <= %@", doubleNum, doubles.lastObject]
                    onTable:table
                withResults:[doubles subarrayWithRange:NSMakeRange(1, 3)]
                       name:@"AND"
                     column:@"double"];
        
        // OR
        [self testPredicate:[NSPredicate predicateWithFormat:@"double <= %@ || double >= %@", doubles.firstObject, doubles.lastObject]
                    onTable:table
                withResults:@[doubles.firstObject, doubles.lastObject]
                       name:@"OR"
                     column:@"double"];
    }];
}

- (void)testDatePredicates {
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
        
        // Between
        [self testPredicate:[NSPredicate predicateWithFormat:@"date between %@", @[date, dates.lastObject]]
                    onTable:table
                withResults:[dates subarrayWithRange:NSMakeRange(1, 3)]
                       name:@"between"
                     column:@"date"];
        
        // Between (inverse)
        [self testPredicate:[NSPredicate predicateWithFormat:@"date between %@", @[dates.lastObject, date]]
                    onTable:table
                withResults:@[]
                       name:@"between (inverse)"
                     column:@"date"];
        
        // AND
        [self testPredicate:[NSPredicate predicateWithFormat:@"date >= %@ && date <= %@", date, dates.lastObject]
                    onTable:table
                withResults:[dates subarrayWithRange:NSMakeRange(1, 3)]
                       name:@"AND"
                     column:@"date"];
        
        // OR
        [self testPredicate:[NSPredicate predicateWithFormat:@"date <= %@ || date >= %@", dates.firstObject, dates.lastObject]
                    onTable:table
                withResults:@[dates.firstObject, dates.lastObject]
                       name:@"OR"
                     column:@"date"];
    }];
}

- (void)testStringPredicates {
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
            XCTAssertThrows([table allWhere:predicate],
                            @"String predicate with diacritic insensitive option should throw");
        }
        
        // AND
        [self testPredicate:@"string contains 'c' && string contains 'd'"
                    onTable:table
                withResults:@[@"abcd"]
                       name:@"AND"
                     column:@"string"];
        
        // OR
        [self testPredicate:@"string contains 'c' || string contains 'd'"
                    onTable:table
                withResults:@[@"abc", @"abcd"]
                       name:@"OR"
                     column:@"string"];
        
        // Complex
        [self testPredicate:@"(string contains 'b' || string contains 'c') && string endswith[c] 'D'"
                    onTable:table
                withResults:@[@"abcd"]
                       name:@"complex"
                     column:@"string"];
    }];
}

- (void)testBinaryPredicates {
    [self createTestTableWithWriteBlock:^(RLMTable *table) {
        [table addColumnWithName:@"data" type:RLMTypeBinary];
        NSArray *dataArray = @[[@"a" dataUsingEncoding:NSUTF8StringEncoding],
                               [@"ab" dataUsingEncoding:NSUTF8StringEncoding],
                               [@"abc" dataUsingEncoding:NSUTF8StringEncoding],
                               [@"abcd" dataUsingEncoding:NSUTF8StringEncoding]];
        for (NSData *data in dataArray) {
            [table addRow:@[data]];
        }
        
        // Equal
        [self testPredicate:[NSPredicate predicateWithFormat:@"data == %@", dataArray.lastObject]
                    onTable:table
                withResults:@[dataArray.lastObject]
                       name:@"equal"
                     column:@"data"];
        
        // Not equal
        [self testPredicate:[NSPredicate predicateWithFormat:@"data != %@", dataArray.firstObject]
                    onTable:table
                withResults:[dataArray subarrayWithRange:NSMakeRange(1, 3)]
                       name:@"not equal"
                     column:@"data"];
        
        // Begins with
        [self testPredicate:[NSPredicate predicateWithFormat:@"data beginswith %@", dataArray[1]]
                    onTable:table
                withResults:[dataArray subarrayWithRange:NSMakeRange(1, 3)]
                       name:@"beginswith"
                     column:@"data"];
        
        // Contains
        [self testPredicate:[NSPredicate predicateWithFormat:@"data contains %@",
                             [@"bc" dataUsingEncoding:NSUTF8StringEncoding]]
                    onTable:table
                withResults:[dataArray subarrayWithRange:NSMakeRange(2, 2)]
                       name:@"contains"
                     column:@"data"];
        
        // Ends with
        [self testPredicate:[NSPredicate predicateWithFormat:@"data endswith %@",
                             [@"cd" dataUsingEncoding:NSUTF8StringEncoding]]
                    onTable:table
                withResults:@[dataArray.lastObject]
                       name:@"endswith"
                     column:@"data"];
    }];
}

#pragma mark - Variadic

- (void)testVariadicPredicateFormat {
    [self createTestTableWithWriteBlock:^(RLMTable *table) {
        [table addColumnWithName:@"int" type:RLMTypeInt];
        NSArray *ints = @[@0, @1, @2, @3];
        for (NSNumber *intNum in ints) {
            [table addRow:@[intNum]];
        }
        
        // Variadic firstWhere
        RLMRow *row = [table firstWhere:@"int <= %@", @1];
        XCTAssertEqualObjects(@0,
                              row[@"int"],
                              @"Variadic firstWhere predicate should return correct result");
        
        // Variadic allWhere
        RLMView *view = [table allWhere:@"int <= %@", @1];
        NSArray *results = @[@0, @1];
        XCTAssertEqual(view.rowCount,
                       results.count,
                       @"Variadic allWhere predicate should return correct count");
        for (NSUInteger i = 0; i < results.count; i++) {
            XCTAssertEqualObjects(results[i],
                                  view[i][@"int"],
                                  @"Variadic allWhere predicate should return correct results");
        }
    }];
}

#pragma mark - Predicate Helpers

- (void)testPredicate:(id)predicate
              onTable:(RLMTable *)table
          withResults:(NSArray *)results
                 name:(NSString *)name
               column:(NSString *)column
{
    RLMView *view = [table allWhere:predicate];
    XCTAssertEqual(view.rowCount,
                   results.count,
                   @"%@ predicate should return correct count", name);
    for (NSUInteger i = 0; i < results.count; i++) {
        XCTAssertEqualObjects(results[i],
                              view[i][column],
                              @"%@ predicate should return correct results", name);
    }
}

@end
