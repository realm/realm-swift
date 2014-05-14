////////////////////////////////////////////////////////////////////////////
//
// TIGHTDB CONFIDENTIAL
// __________________
//
//  [2011] - [2014] TightDB Inc
//  All Rights Reserved.
//
// NOTICE:  All information contained herein is, and remains
// the property of TightDB Incorporated and its suppliers,
// if any.  The intellectual and technical concepts contained
// herein are proprietary to TightDB Incorporated
// and its suppliers and may be covered by U.S. and Foreign Patents,
// patents in process, and are protected by trade secret or copyright law.
// Dissemination of this information or reproduction of this material
// is strictly forbidden unless prior written permission is obtained
// from TightDB Incorporated.
//
////////////////////////////////////////////////////////////////////////////

#import "RLMTestCase.h"

#import <Realm/Realm.h>

@interface AgeObject : RLMObject
@property int age;
@end

@implementation AgeObject
@end


//@interface AllTypes : RLMObject
//@property BOOL           boolCol;
//@property int            intCol;
//@property float          floatCol;
//@property double         doubleCol;
//@property NSString      *stringCol;
//@property NSData        *binaryCol;
//@property NSDate        *dateCol;
//@property AgeTable      *tableCol;
//@property bool           cBoolCol;
//@property long           longCol;
//@property id             mixedCol;
//@end
//
//@implementation AllTypes
//@end
//
//RLM_TABLE_TYPE_FOR_OBJECT_TYPE(AllTypesTable, AllTypes)
//
//@interface InvalidType : RLMObject
//@property NSDictionary *dict;
//@end
//
//@implementation InvalidType
//@end
//
//RLM_TABLE_TYPE_FOR_OBJECT_TYPE(InvalidTable, InvalidType)
//
//@interface InvalidProperty : RLMObject
//@property NSUInteger noUnsigned;
//@end
//
//@implementation InvalidProperty
//@end
//
//@interface RLMTypedTableTests: RLMTestCase
//  // Intentionally left blank.
//  // No new public instance methods need be defined.
//@end
//
@interface KeyedObject : RLMObject
@property NSString * name;
@property int objID;
@end

@implementation KeyedObject
@end

//@interface CustomAccessors : RLMObject
//@property (getter = getThatName) NSString * name;
//@property (setter = setTheInt:) int age;
//@end
//
//@implementation CustomAccessors
//@end
//
//
//RLM_TABLE_TYPE_FOR_OBJECT_TYPE(KeyedTable, KeyedObject)

@interface AggregateObject : RLMObject
@property int IntCol;
@property float FloatCol;
@property double DoubleCol;
@property BOOL BoolCol;
@end

@implementation AggregateObject
@end

//@interface JSONTableTestType : RLMObject
//
//@property BOOL      boolColumn;
//@property int       intColumn;
//@property float     floatColumn;
//@property double    doubleColumn;
//@property NSString  *stringColumn;
//@property NSData    *binaryColumn;
//@property NSDate    *dateColumn;
//@property id        mixedColumn;
//
//@end
//
//@implementation JSONTableTestType
//@end
//
//RLM_TABLE_TYPE_FOR_OBJECT_TYPE(JSONTableTestTable, JSONTableTestType)

@interface RLMTypedTableTests : RLMTestCase

@end

@implementation RLMTypedTableTests

//- (void)testDataTypes_Typed
//{
//    [self.realmWithTestPath writeUsingBlock:^(RLMRealm *realm) {
//        // create table and set object class
//        AllTypesTable *table = [AllTypesTable tableInRealm:realm named:@"table"];
//        
//        NSLog(@"Table: %@", table);
//        XCTAssertNotNil(table, @"Table is nil");
//
//        // Verify column types
//        XCTAssertEqual(RLMTypeBool,   [table columnTypeOfColumnWithIndex:0], @"First column not bool");
//        XCTAssertEqual(RLMTypeInt,    [table columnTypeOfColumnWithIndex:1], @"Second column not int");
//        XCTAssertEqual(RLMTypeFloat,  [table columnTypeOfColumnWithIndex:2], @"Third column not float");
//        XCTAssertEqual(RLMTypeDouble, [table columnTypeOfColumnWithIndex:3], @"Fourth column not double");
//        XCTAssertEqual(RLMTypeString, [table columnTypeOfColumnWithIndex:4], @"Fifth column not string");
//        XCTAssertEqual(RLMTypeBinary, [table columnTypeOfColumnWithIndex:5], @"Sixth column not binary");
//        XCTAssertEqual(RLMTypeDate,   [table columnTypeOfColumnWithIndex:6], @"Seventh column not date");
//        XCTAssertEqual(RLMTypeTable,  [table columnTypeOfColumnWithIndex:7], @"Eighth column not table");
//        XCTAssertEqual(RLMTypeBool,   [table columnTypeOfColumnWithIndex:8], @"Ninth column not bool");
//        XCTAssertEqual(RLMTypeInt,    [table columnTypeOfColumnWithIndex:9], @"Tenth column not long");
//        XCTAssertEqual(RLMTypeMixed,    [table columnTypeOfColumnWithIndex:10], @"Eleventh column not mixed");
//
//        const char bin[4] = { 0, 1, 2, 3 };
//        NSData* bin1 = [[NSData alloc] initWithBytes:bin length:sizeof bin / 2];
//        NSData* bin2 = [[NSData alloc] initWithBytes:bin length:sizeof bin];
//        NSDate *timeNow = [NSDate dateWithTimeIntervalSince1970:1000000];
//        NSDate *timeZero = [NSDate dateWithTimeIntervalSince1970:0];
//
//        AgeTable *subtab1 = [AgeTable tableInRealm:realm named:@"subtab1"];
//        AgeTable *subtab2 = [AgeTable tableInRealm:realm named:@"subtab2"];
//
//        [subtab1 addRow:@[@200]]; // NOTE: the name is simply add+name of first column!
//        [subtab2 addRow:@[@100]];
//
//        AllTypes * c;
//
//        // addEmptyRow not supported yet
//        [table addRow:nil];
//        c = table.lastRow;
//        
//        c.BoolCol   = NO   ; c.IntCol  = 54 ; c.FloatCol = 0.7     ; c.DoubleCol = 0.8     ; c.StringCol = @"foo";
//        c.BinaryCol = bin1 ; c.DateCol = timeZero  ; c.TableCol = subtab1     ; c.cBoolCol = false; c.longCol = 99;
//        NSString *string = @"string";
//        c.mixedCol = @"string";
//        
//        [table addRow:nil];
//        c = table.lastRow; 
//        
//        c.BoolCol   = YES  ; c.IntCol  = 506     ; c.FloatCol = 7.7         ; c.DoubleCol = 8.8       ; c.StringCol = @"banach";
//        c.BinaryCol = bin2 ; c.DateCol = timeNow ; c.TableCol = subtab2     ; c.cBoolCol = true;    c.longCol = -20;
//        c.mixedCol = @2;
//        
//        //AllTypes* row1 = [table rowAtIndex:0];
//        //AllTypes* row2 = [table rowAtIndex:1];
//        AllTypes* row1 = table[0];
//        AllTypes* row2 = table[1];
//
//        XCTAssertEqual(row1.boolCol, NO,                 @"row1.BoolCol");
//        XCTAssertEqual(row2.boolCol, YES,                @"row2.BoolCol");
//        XCTAssertEqual(row1.intCol, 54,             @"row1.IntCol");
//        XCTAssertEqual(row2.intCol, 506,            @"row2.IntCol");
//        XCTAssertEqual(row1.floatCol, 0.7f,              @"row1.FloatCol");
//        XCTAssertEqual(row2.floatCol, 7.7f,              @"row2.FloatCol");
//        XCTAssertEqual(row1.doubleCol, 0.8,              @"row1.DoubleCol");
//        XCTAssertEqual(row2.doubleCol, 8.8,              @"row2.DoubleCol");
//        XCTAssertTrue([row1.stringCol isEqual:@"foo"],    @"row1.StringCol");
//        XCTAssertTrue([row2.stringCol isEqual:@"banach"], @"row2.StringCol");
//        XCTAssertTrue([row1.binaryCol isEqual:bin1],      @"row1.BinaryCol");
//        XCTAssertTrue([row2.binaryCol isEqual:bin2],      @"row2.BinaryCol");
//        XCTAssertTrue(([row1.dateCol isEqual:timeZero]),  @"row1.DateCol");
//        XCTAssertTrue(([row2.dateCol isEqual:timeNow]),   @"row2.DateCol");
//        XCTAssertTrue([row1.tableCol isEqual:subtab1],    @"row1.TableCol");
//        XCTAssertTrue([row2.tableCol isEqual:subtab2],    @"row2.TableCol");
//        XCTAssertEqual(row1.cBoolCol, (bool)false,        @"row1.cBoolCol");
//        XCTAssertEqual(row2.cBoolCol, (bool)true,         @"row2.cBoolCol");
//        XCTAssertEqual(row1.longCol, 99L,                 @"row1.IntCol");
//        XCTAssertEqual(row2.longCol, -20L,                @"row2.IntCol");
//        
//        XCTAssertTrue([row1.mixedCol isEqualToString:string], @"row1.mixedCol");
//        XCTAssertEqualObjects(row2.mixedCol, @2,          @"row2.mixedCol");
//    }];
//}

- (void)testTableTyped_Subscripting
{
    [[NSFileManager defaultManager] removeItemAtPath:RLMDefaultRealmPath() error:nil];

    RLMRealm *realm = [RLMRealm defaultRealm];
    
    [realm beginWriteTransaction];
    [AgeObject createInRealm:realm withObject:@[@10]];
    [AgeObject createInRealm:realm withObject:@[@20]];
    [realm commitWriteTransaction];

    // Get all objects
    RLMArray *objects = [AgeObject allObjects];
    AgeObject *obj0 = objects[0];
    XCTAssertEqual(obj0.age, 10,  @"Should be 10    ");
    AgeObject *obj1 = objects[1];
    XCTAssertEqual(obj1.age, 20, @"table[1].age");

    [realm beginWriteTransaction];
    obj0.age = 7;
    [realm commitWriteTransaction];

    XCTAssertEqual(obj0.age, 7,  @"table[0].age");
}

- (void)testTableTyped_KeyedSubscripting
{
    RLMRealm *realm = [RLMRealm defaultRealm];
    [realm beginWriteTransaction];
    [KeyedObject createInRealm:realm withObject:@{@"name" : @"Test1", @"objID" : @24}];
    [KeyedObject createInRealm:realm withObject:@{@"name" : @"Test2", @"objID" : @25}];
    [realm commitWriteTransaction];
    
//    RLMArray *array = [KeyedObject allObjects];
//    XCTAssertNil(array[@"foo"], @"table[\"foo\"] should be nil");
//        
//        AgeTable* errTable = [AgeTable tableInRealm:realm named:@"errTable"];
//        [errTable setObjectClass:Sub.class];
//        
//        [errTable addRow:@{@"age" : @987289}];
//        XCTAssertThrows(errTable[@"X"], @"Accessing RLMRow via keyed subscript on a column that is not of type RLMTypeString should throw exception");
//        
//        // Test keyed subscripting setters
//        
//        // No exisiting for table
//        NSUInteger previousRowCount = [table rowCount];
//        NSString* nonExistingKey = @"Test10123903784293";
//        table[nonExistingKey] = @{@"name" : nonExistingKey, @"objID" : @1};
//        
//        XCTAssertEqual(previousRowCount, [table rowCount], @"Row count should be equal to previous row after inserting a non-existing RLMRow");
//        // Commenting out until set row method transitioned from update row
//        //XCTAssertNotNil(table[nonExistingKey], @"table[nonExistingKey] should not be nil");
//        //XCTAssertEqual(table[nonExistingKey].objID, 1, @"table[nonExistingKey]objID should be equal to 1");
//        //XCTAssertEqualObjects(table[nonExistingKey].name, nonExistingKey, @"table[nonExistingKey].name should be equal to nonExistingKey");
//        
//        // Set non-existing row to nil for table
//        previousRowCount = [table rowCount];
//        NSString* anotherNonExistingKey = @"sdalfjhadskfja";
//        table[anotherNonExistingKey] = nil;
//        
//        XCTAssertEqual(previousRowCount, [table rowCount], @"previousRowCount should equal current rowCount");
//        XCTAssertNil(table[anotherNonExistingKey], @"table[anotherNonExistingKey] should be nil");
//        
//        // Has existing for table
//        previousRowCount = [table rowCount];
//        table[@"Test2"] = @{@"name" : @"Test3" , @"objID" : @123};
//        
//        XCTAssertEqual(previousRowCount, [table rowCount], @"Row count should still equal previous row count after inserting an existing RLMRow");
//        XCTAssertNil(table[@"Test2"], @"table[@\"Test2\"] should be nil");
//        XCTAssertNotNil(table[@"Test3"], @"table[@\"Test3\"] should not be nil");
//        XCTAssertEqual((int)table[@"Test3"].objID, 123, @"table[\"Test3\"].objID should be equal to 123");
//        XCTAssertEqualObjects(table[@"Test3"].name, @"Test3", @"table[\"Test3\"].name should be equal to @\"Test3\"");
//        
//        // Set existing row to nil for table
//        previousRowCount = [table rowCount];
//        table[@"Test3"] = nil;
//        
//        XCTAssertEqual(previousRowCount, [table rowCount], @"[table rowCount] should be equal to previousRowCount");
//        XCTAssertNotNil(table[@"Test3"], @"table[\"Test3\"] should not be nil");
//        
//        // No existing for errTable
//        previousRowCount = [errTable rowCount];
//        XCTAssertThrows((errTable[@"SomeKey"] = @{@"id" : @821763}), @"Calling keyed subscriptor on errTable should throw exception");
//        XCTAssertEqual(previousRowCount, [errTable rowCount], @"errTable should have same count as previous");
    
}

//- (void)testCustomAccessors {
//    [self.realmWithTestPath writeUsingBlock:^(RLMRealm *realm) {
//        RLMTable *table = [realm createTableWithName:@"Test" objectClass:[CustomAccessors class]];
//        [table addRow:@[@"name", @2]];
//        
//        XCTAssertEqualObjects([table[0] getThatName], @"name", @"name property should be name.");
//        
//        [table[0] setTheInt:99];
//        XCTAssertEqual((int)[table[0] age], (int)99, @"age property should be 99");
//    }];
//}
//
- (void)testObjectCount
{
    [[NSFileManager defaultManager] removeItemAtPath:RLMDefaultRealmPath() error:nil];

    RLMRealm *realm = [RLMRealm defaultRealm];
    
    [realm beginWriteTransaction];
    [AgeObject createInRealm:realm withObject:(@[@23])];
    [AgeObject createInRealm:realm withObject:(@[@23])];
    [AgeObject createInRealm:realm withObject:(@[@22])];
    [AgeObject createInRealm:realm withObject:(@[@29])];
    [AgeObject createInRealm:realm withObject:(@[@2])];
    [AgeObject createInRealm:realm withObject:(@[@24])];
    [AgeObject createInRealm:realm withObject:(@[@21])];
    [realm commitWriteTransaction];
  
    XCTAssertEqual([AgeObject objectsWhere:@"age == 23"].count, (NSUInteger)2, @"count should return 2");
    XCTAssertEqual([AgeObject objectsWhere:@"age >= 10"].count, (NSUInteger)6, @"count should return 6");
    XCTAssertEqual([AgeObject objectsWhere:@"age == 1"].count, (NSUInteger)0, @"count should return 0");
    XCTAssertEqual([AgeObject objectsWhere:@"age == 2"].count, (NSUInteger)1, @"count should return 1");
    XCTAssertEqual([AgeObject objectsWhere:@"age < 30"].count, (NSUInteger)7, @"count should return 7");
    
}

- (void)testObjectAggregate
{
    [[NSFileManager defaultManager] removeItemAtPath:RLMDefaultRealmPath() error:nil];
    
    RLMRealm *realm = [RLMRealm defaultRealm];
    
    [realm beginWriteTransaction];
    
    [AggregateObject createInRealm:realm withObject:@[@0, @1.2f, @0.0, @YES]];
    [AggregateObject createInRealm:realm withObject:@[@1, @0.0f, @2.5, @NO]];
    [AggregateObject createInRealm:realm withObject:@[@0, @1.2f, @0.0, @YES]];
    [AggregateObject createInRealm:realm withObject:@[@1, @0.0f, @2.5, @NO]];
    [AggregateObject createInRealm:realm withObject:@[@0, @1.2f, @0.0, @YES]];
    [AggregateObject createInRealm:realm withObject:@[@1, @0.0f, @2.5, @NO]];
    [AggregateObject createInRealm:realm withObject:@[@0, @1.2f, @0.0, @YES]];
    [AggregateObject createInRealm:realm withObject:@[@1, @0.0f, @2.5, @NO]];
    [AggregateObject createInRealm:realm withObject:@[@0, @1.2f, @0.0, @YES]];
    [AggregateObject createInRealm:realm withObject:@[@0, @1.2f, @0.0, @YES]];
        
    RLMArray *noArray = [AggregateObject objectsWhere:@"BoolCol == NO"];
    RLMArray *yesArray = [AggregateObject objectsWhere:@"BoolCol == YES"];
    
    // SUM ::::::::::::::::::::::::::::::::::::::::::::::
    // Test int sum
    XCTAssertEqual([noArray sumOfProperty:@"IntCol"].integerValue, (NSInteger)4, @"Sum should be 4");
    XCTAssertEqual([yesArray sumOfProperty:@"IntCol"].integerValue, (NSInteger)0, @"Sum should be 0");
        
    // Test float sum
    XCTAssertEqualWithAccuracy([noArray sumOfProperty:@"FloatCol"].floatValue, (float)0.0f, 0.1f, @"Sum should be 4");
    XCTAssertEqualWithAccuracy([yesArray sumOfProperty:@"FloatCol"].floatValue, (float)7.2f, 0.1f, @"Sum should be 7.2");
        
    // Test double sum
    XCTAssertEqualWithAccuracy([noArray sumOfProperty:@"DoubleCol"].doubleValue, (double)10.0, 0.1f, @"Sum should be 10.0");
    XCTAssertEqualWithAccuracy([yesArray sumOfProperty:@"DoubleCol"].doubleValue, (double)0.0, 0.1f, @"Sum should be 0.0");
        
    // Test invalid column name
    XCTAssertThrows([yesArray sumOfProperty:@"foo"], @"Should throw exception");
        
    // Test operation not supported
    XCTAssertThrows([yesArray sumOfProperty:@"BoolCol"], @"Should throw exception");
    
    
    // Average ::::::::::::::::::::::::::::::::::::::::::::::
    // Test int average
    XCTAssertEqualWithAccuracy([noArray averageOfProperty:@"IntCol"].doubleValue, (double)1.0, 0.1f, @"Average should be 1.0");
    XCTAssertEqualWithAccuracy([yesArray averageOfProperty:@"IntCol"].doubleValue, (double)0.0, 0.1f, @"Average should be 0.0");
    
    // Test float average
    XCTAssertEqualWithAccuracy([noArray averageOfProperty:@"FloatCol"].doubleValue, (double)0.0f, 0.1f, @"Average should be 0.0");
    XCTAssertEqualWithAccuracy([yesArray averageOfProperty:@"FloatCol"].doubleValue, (double)1.2f, 0.1f, @"Average should be 1.2");
    
    // Test double average
    XCTAssertEqualWithAccuracy([noArray averageOfProperty:@"DoubleCol"].doubleValue, (double)2.5, 0.1f, @"Average should be 2.5");
    XCTAssertEqualWithAccuracy([yesArray averageOfProperty:@"DoubleCol"].doubleValue, (double)0.0, 0.1f, @"Average should be 0.0");
    
    // Test invalid column name
    XCTAssertThrows([yesArray averageOfProperty:@"foo"], @"Should throw exception");
    
    // Test operation not supported
    XCTAssertThrows([yesArray averageOfProperty:@"BoolCol"], @"Should throw exception");
    
    // MIN ::::::::::::::::::::::::::::::::::::::::::::::
    // Test int min
    NSNumber *min = [noArray minOfProperty:@"IntCol"];
    XCTAssertEqual(min.intValue, (NSInteger)2, @"Minimum should be 2");
    min = [yesArray minOfProperty:@"IntCol"];
    XCTAssertEqual(min.intValue, (NSInteger)1, @"Minimum should be 1");
    
    // Test float min
    min = [noArray minOfProperty:@"FloatCol"];
    XCTAssertEqualWithAccuracy(min.floatValue, (float)1.2f, 0.1f, @"Minimum should be 1.2f");
    min = [yesArray minOfProperty:@"FloatCol"];
    XCTAssertEqualWithAccuracy(min.floatValue, (float)1.1f, 0.1f, @"Minimum should be 1.1f");
    
    // Test double min
    min = [noArray minOfProperty:@"DoubleCol"];
    XCTAssertEqualWithAccuracy(min.doubleValue, (double)1.5, 0.1f, @"Minimum should be 1.5");
    min = [yesArray minOfProperty:@"DoubleCol"];
    XCTAssertEqualWithAccuracy(min.doubleValue, (double)0.0, 0.1f, @"Minimum should be 0.0");
    
    // Test invalid column name
    XCTAssertThrows([noArray minOfProperty:@"foo"], @"Should throw exception");
    
    // Test operation not supported
    XCTAssertThrows([noArray minOfProperty:@"BoolCol"], @"Should throw exception");
    
    
    // MAX ::::::::::::::::::::::::::::::::::::::::::::::
    // Test int max
    NSNumber *max = [noArray maxOfProperty:@"IntCol"];
    XCTAssertEqual(max.integerValue, (NSInteger)8, @"Maximum should be 8");
    max = [yesArray maxOfProperty:@"IntCol"];
    XCTAssertEqual(max.integerValue, (NSInteger)10, @"Maximum should be 10");
    
    // Test float max
    max = [noArray maxOfProperty:@"FloatCol"];
    XCTAssertEqualWithAccuracy(max.floatValue, (float)1.8f, 0.1f, @"Maximum should be 1.8f");
    max = [yesArray maxOfProperty:@"FloatCol"];
    XCTAssertEqualWithAccuracy(max.floatValue, (float)2.0f, 0.1f, @"Maximum should be 2.0f");
    
    // Test double max
    max = [noArray maxOfProperty:@"DoubleCol"];
    XCTAssertEqualWithAccuracy(max.doubleValue, (double)10.5, 0.1f, @"Maximum should be 10.5");
    max = [yesArray maxOfProperty:@"DoubleCol"];
    XCTAssertEqualWithAccuracy(max.doubleValue, (double)13.5, 0.1f, @"Maximum should be 13.5");
    
    // Test invalid column name
    XCTAssertThrows([noArray maxOfProperty:@"foo"], @"Should throw exception");
    
    // Test operation not supported
    XCTAssertThrows([noArray maxOfProperty:@"BoolCol"], @"Should throw exception");
}


//
//- (void)testTableTyped_minInColumn
//{
//    [[self realmWithTestPath] writeUsingBlock:^(RLMRealm *realm) {
//        AggregateTable *table = [AggregateTable tableInRealm:realm named:@"Table"];
//        
//        [table addRow:@[@1, @1.1f, @0.0, @YES]];
//        [table addRow:@[@2, @1.2f, @1.5, @NO]];
//        [table addRow:@[@3, @1.3f, @3.0, @YES]];
//        [table addRow:@[@4, @1.4f, @4.5, @NO]];
//        [table addRow:@[@5, @1.5f, @6.0, @YES]];
//        [table addRow:@[@6, @1.6f, @7.5, @NO]];
//        [table addRow:@[@7, @1.7f, @9.0, @YES]];
//        [table addRow:@[@8, @1.8f, @10.5, @NO]];
//        [table addRow:@[@9, @1.9f, @12.0, @YES]];
//        [table addRow:@[@10, @2.0f, @13.5, @YES]];
//        
//    }];
//}









@end
