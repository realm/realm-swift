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

#import "RLMTestCase.h"

#import <realm/objc/Realm.h>

REALM_TABLE_1(TestTableSub,
              age,  Int)

REALM_TABLE_9(TestTableAllTypes,
              BoolCol,   Bool,
              IntCol,    Int,
              FloatCol,  Float,
              DoubleCol, Double,
              StringCol, String,
              BinaryCol, Binary,
              DateCol,   Date,
              TableCol,  TestTableSub,
              MixedCol,  Mixed)

REALM_TABLE_2(TestTableKeyedSubscript,
              name, String,
              objID, Int)

REALM_TABLE_1(TestTableKeyedSubscriptError,
              objID, Int)

@interface RLMTypedTableTests: RLMTestCase

@end

@implementation RLMTypedTableTests

- (void)testDataTypes_Typed
{
    TestTableAllTypes* table = [[TestTableAllTypes alloc] init];
    NSLog(@"Table: %@", table);
    XCTAssertNotNil(table, @"Table is nil");

    // Verify column types
    XCTAssertEqual(RLMTypeBool,   [table columnTypeOfColumnWithIndex:0], @"First column not bool");
    XCTAssertEqual(RLMTypeInt,    [table columnTypeOfColumnWithIndex:1], @"Second column not int");
    XCTAssertEqual(RLMTypeFloat,  [table columnTypeOfColumnWithIndex:2], @"Third column not float");
    XCTAssertEqual(RLMTypeDouble, [table columnTypeOfColumnWithIndex:3], @"Fourth column not double");
    XCTAssertEqual(RLMTypeString, [table columnTypeOfColumnWithIndex:4], @"Fifth column not string");
    XCTAssertEqual(RLMTypeBinary, [table columnTypeOfColumnWithIndex:5], @"Sixth column not binary");
    XCTAssertEqual(RLMTypeDate,   [table columnTypeOfColumnWithIndex:6], @"Seventh column not date");
    XCTAssertEqual(RLMTypeTable,  [table columnTypeOfColumnWithIndex:7], @"Eighth column not table");
    XCTAssertEqual(RLMTypeMixed,  [table columnTypeOfColumnWithIndex:8], @"Ninth column not mixed");

    const char bin[4] = { 0, 1, 2, 3 };
    NSData* bin1 = [[NSData alloc] initWithBytes:bin length:sizeof bin / 2];
    NSData* bin2 = [[NSData alloc] initWithBytes:bin length:sizeof bin];
    NSDate *timeNow = [NSDate dateWithTimeIntervalSince1970:1000000];
    NSDate *timeZero = [NSDate dateWithTimeIntervalSince1970:0];
    TestTableSub* subtab1 = [[TestTableSub alloc] init];
    TestTableSub* subtab2 = [[TestTableSub alloc] init];
    [subtab1 addage:200]; // NOTE: the name is simply add+name of first column!
    [subtab2 addage:100];
    NSNumber* mixInt1   = [NSNumber numberWithLongLong:1];

    TestTableAllTypesRow* c;

    c = [table addEmptyRow];

        c.BoolCol   = NO   ; c.IntCol  = 54 ; c.FloatCol = 0.7     ; c.DoubleCol = 0.8     ; c.StringCol = @"foo";
        c.BinaryCol = bin1 ; c.DateCol = 0  ; c.TableCol = subtab1     ; c.MixedCol  = mixInt1 ;

    c = [table addEmptyRow];

        c.BoolCol   = YES  ; c.IntCol  = 506     ; c.FloatCol = 7.7         ; c.DoubleCol = 8.8       ; c.StringCol = @"banach";
        c.BinaryCol = bin2 ; c.DateCol = timeNow ; c.TableCol = subtab2     ; c.MixedCol  = subtab2 ;

    TestTableAllTypesRow* row1 = [table rowAtIndex:0];
    TestTableAllTypesRow* row2 = [table rowAtIndex:1];

    XCTAssertEqual(row1.BoolCol, NO,                 @"row1.BoolCol");
    XCTAssertEqual(row2.BoolCol, YES,                @"row2.BoolCol");
    XCTAssertEqual(row1.IntCol, (int64_t)54,         @"row1.IntCol");
    XCTAssertEqual(row2.IntCol, (int64_t)506,        @"row2.IntCol");
    XCTAssertEqual(row1.FloatCol, 0.7f,              @"row1.FloatCol");
    XCTAssertEqual(row2.FloatCol, 7.7f,              @"row2.FloatCol");
    XCTAssertEqual(row1.DoubleCol, 0.8,              @"row1.DoubleCol");
    XCTAssertEqual(row2.DoubleCol, 8.8,              @"row2.DoubleCol");
    XCTAssertTrue([row1.StringCol isEqual:@"foo"],    @"row1.StringCol");
    XCTAssertTrue([row2.StringCol isEqual:@"banach"], @"row2.StringCol");
    XCTAssertTrue([row1.BinaryCol isEqual:bin1],      @"row1.BinaryCol");
    XCTAssertTrue([row2.BinaryCol isEqual:bin2],      @"row2.BinaryCol");
    XCTAssertTrue(([row1.DateCol isEqual:timeZero]),  @"row1.DateCol");
    XCTAssertTrue(([row2.DateCol isEqual:timeNow]),   @"row2.DateCol");
    XCTAssertTrue([row1.TableCol isEqual:subtab1],    @"row1.TableCol");
    XCTAssertTrue([row2.TableCol isEqual:subtab2],    @"row2.TableCol");
    XCTAssertTrue([row1.MixedCol isEqual:mixInt1],    @"row1.MixedCol");
    XCTAssertTrue([row2.MixedCol isEqual:subtab2],    @"row2.MixedCol");

    XCTAssertEqual([table.IntCol minimum], (int64_t)54,                 @"IntCol min");
    XCTAssertEqual([table.IntCol maximum], (int64_t)506,                @"IntCol max");
    XCTAssertEqual([table.IntCol sum], (int64_t)560,                @"IntCol sum");
    XCTAssertEqual([table.IntCol average], 280.0,                       @"IntCol avg");

    XCTAssertEqual([table.FloatCol minimum], 0.7f,                      @"FloatCol min");
    XCTAssertEqual([table.FloatCol maximum], 7.7f,                      @"FloatCol max");
    XCTAssertEqual([table.FloatCol sum], (double)0.7f + 7.7f,       @"FloatCol sum");
    XCTAssertEqual([table.FloatCol average], ((double)0.7f + 7.7f) / 2, @"FloatCol avg");

    XCTAssertEqual([table.DoubleCol minimum], 0.8,                      @"DoubleCol min");
    XCTAssertEqual([table.DoubleCol maximum], 8.8,                      @"DoubleCol max");
    XCTAssertEqual([table.DoubleCol sum], 0.8 + 8.8,                @"DoubleCol sum");
    XCTAssertEqual([table.DoubleCol average], (0.8 + 8.8) / 2,          @"DoubleCol avg");
    
    
}

- (void)testTableTyped_Subscripting
{
    TestTableSub *table = [[TestTableSub alloc] init];

    // Add some rows
    [table addage: 10];
    [table addage:20];

    table[0].age = 7;
    
    // Verify that you can access rows with object subscripting
    XCTAssertEqual(table[0].age, (int64_t)7, @"table[0].age");
    XCTAssertEqual(table[1].age, (int64_t)20, @"table[1].age");
}

- (void)testTableTyped_KeyedSubscripting
{
    TestTableKeyedSubscript* table = [[TestTableKeyedSubscript alloc] init];
    
    [table addRow:@{@"name" : @"Test1", @"objID" : @24}];
    [table addRow:@{@"name" : @"Test2", @"objID" : @25}];
    
    XCTAssertNotNil(table[@"Test1"], @"table[@\"Test1\"] should not be nil");
    XCTAssertEqualObjects(table[@"Test1"].name, @"Test1", @"table[@\"Test24\"].name should be equal to Test1");
    XCTAssertEqual((int)table[@"Test1"].objID, 24, @"table[@\"Test24\"].objID should be equal to @24");
    
    XCTAssertNotNil(table[@"Test2"], @"table[@\"Test2\"] should not be nil");
    XCTAssertEqualObjects(table[@"Test2"].name, @"Test2", @"table[@\"Test24\"].name should be equal to Test2");
    XCTAssertEqual((int)table[@"Test2"].objID, 25, @"table[@\"Test24\"].objID should be equal to 25");
    
    XCTAssertNil(table[@"foo"], @"table[\"foo\"] should be nil");
    
    TestTableKeyedSubscriptError* errTable = [[TestTableKeyedSubscriptError alloc] init];
    [errTable addRow:@{@"id" : @987289}];
    XCTAssertThrows(errTable[@"X"], @"Accessing RLMRow via keyed subscript on a column that is not of type RLMTypeString should throw exception");
    
    // Test keyed subscripting setters
    
    // No exisiting for table
    NSUInteger previousRowCount = [table rowCount];
    NSString* nonExistingKey = @"Test10123903784293";
    table[nonExistingKey] = @{@"name" : nonExistingKey, @"objID" : @1};
    
    XCTAssertEqual(previousRowCount, [table rowCount], @"Row count should be equal to previous row after inserting a non-existing RLMRow");
    // Commenting out until set row method transitioned from update row
    //XCTAssertNotNil(table[nonExistingKey], @"table[nonExistingKey] should not be nil");
    //XCTAssertEqual(table[nonExistingKey].objID, 1, @"table[nonExistingKey]objID should be equal to 1");
    //XCTAssertEqualObjects(table[nonExistingKey].name, nonExistingKey, @"table[nonExistingKey].name should be equal to nonExistingKey");
    
    // Set non-existing row to nil for table
    previousRowCount = [table rowCount];
    NSString* anotherNonExistingKey = @"sdalfjhadskfja";
    table[anotherNonExistingKey] = nil;
    
    XCTAssertEqual(previousRowCount, [table rowCount], @"previousRowCount should equal current rowCount");
    XCTAssertNil(table[anotherNonExistingKey], @"table[anotherNonExistingKey] should be nil");
    
    // Has existing for table
    previousRowCount = [table rowCount];
    table[@"Test2"] = @{@"name" : @"Test3" , @"objID" : @123};
    
    XCTAssertEqual(previousRowCount, [table rowCount], @"Row count should still equal previous row count after inserting an existing RLMRow");
    XCTAssertNil(table[@"Test2"], @"table[@\"Test2\"] should be nil");
    XCTAssertNotNil(table[@"Test3"], @"table[@\"Test3\"] should not be nil");
    XCTAssertEqual((int)table[@"Test3"].objID, 123, @"table[\"Test3\"].objID should be equal to 123");
    XCTAssertEqualObjects(table[@"Test3"].name, @"Test3", @"table[\"Test3\"].name should be equal to @\"Test3\"");
    
    // Set existing row to nil for table
    previousRowCount = [table rowCount];
    table[@"Test3"] = nil;
    
    XCTAssertEqual(previousRowCount, [table rowCount], @"[table rowCount] should be equal to previousRowCount");
    XCTAssertNotNil(table[@"Test3"], @"table[\"Test3\"] should not be nil");
    
    // No existing for errTable
    previousRowCount = [errTable rowCount];
    XCTAssertThrows((errTable[@"SomeKey"] = @{@"id" : @821763}), @"Calling keyed subscriptor on errTable should throw exception");
    XCTAssertEqual(previousRowCount, [errTable rowCount], @"errTable should have same count as previous");
}

- (void)testTableTyped_init_exception
{
    XCTAssertThrows(([[TestTableAllTypes alloc] init]), @"Initializing table outside of context should throw exception");
}

@end
