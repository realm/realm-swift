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


@interface SimpleObject : RLMObject
@property NSString *name;
@property int age;
@property BOOL hired;
@end

@implementation SimpleObject
@end

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

@interface CustomAccessors : RLMObject
@property (getter = getThatName) NSString * name;
@property (setter = setTheInt:) int age;
@end

@implementation CustomAccessors
@end


@interface AggregateObject : RLMObject
@property int IntCol;
@property float FloatCol;
@property double DoubleCol;
@property BOOL BoolCol;
@end

@implementation AggregateObject
@end



@interface RLMTypedTableTests : RLMTestCase

@end

@implementation RLMTypedTableTests

-(void)testObjectInit
{
    [[NSFileManager defaultManager] removeItemAtPath:RLMDefaultRealmPath() error:nil];
    
    RLMRealm *realm = [RLMRealm defaultRealm];
    
    [realm beginWriteTransaction];
    
    // Init object before adding to realm
    SimpleObject *soInit = [[SimpleObject alloc] init];
    soInit.name = @"Peter";
    soInit.age = 30;
    soInit.hired = YES;
    [realm addObject:soInit];
    
    // Create object while adding to realm using NSArray
    SimpleObject *soUsingArray = [SimpleObject createInRealm:realm withObject:@[@"John", @40, @NO]];
    
    // Create object while adding to realm using NSDictionary
    SimpleObject *soUsingDictionary = [SimpleObject createInRealm:realm withObject:@{@"name": @"Susi", @"age": @25, @"hired": @YES}];
    
    [realm commitWriteTransaction];
    
    XCTAssertEqualObjects(soInit.name, @"Peter", @"Name should be Peter");
    XCTAssertEqual(soInit.age, 30, @"Age should be 30");
    XCTAssertEqual(soInit.hired, YES, @"Hired should YES");
    
    XCTAssertEqualObjects(soUsingArray.name, @"John", @"Name should be John");
    XCTAssertEqual(soUsingArray.age, 40, @"Age should be 40");
    XCTAssertEqual(soUsingArray.hired, NO, @"Hired should NO");
    
    XCTAssertEqualObjects(soUsingDictionary.name, @"Susi", @"Name should be Susi");
    XCTAssertEqual(soUsingDictionary.age, 25, @"Age should be 25");
    XCTAssertEqual(soUsingDictionary.hired, YES, @"Hired should YES");
}

- (void)testObjectSubscripting
{
    [[NSFileManager defaultManager] removeItemAtPath:RLMDefaultRealmPath() error:nil];

    RLMRealm *realm = [RLMRealm defaultRealm];
    
    [realm beginWriteTransaction];
    AgeObject *obj0 = [AgeObject createInRealm:realm withObject:@[@10]];
    AgeObject *obj1 = [AgeObject createInRealm:realm withObject:@[@20]];
    [realm commitWriteTransaction];

    XCTAssertEqual(obj0.age, 10,  @"Age should be 10");
    XCTAssertEqual(obj1.age, 20, @"Age should be 20");

    [realm beginWriteTransaction];
    obj0.age = 7;
    [realm commitWriteTransaction];

    XCTAssertEqual(obj0.age, 7,  @"Age should be 7");
}

- (void)testKeyedSubscripting
{
    RLMRealm *realm = [RLMRealm defaultRealm];
    [realm beginWriteTransaction];
    KeyedObject *obj0 = [KeyedObject createInRealm:realm withObject:@{@"name" : @"Test1", @"objID" : @24}];
    KeyedObject *obj1 = [KeyedObject createInRealm:realm withObject:@{@"name" : @"Test2", @"objID" : @25}];
    [realm commitWriteTransaction];
    
    XCTAssertEqualObjects(obj0[@"name"], @"Test1",  @"Name should be Test1");
    XCTAssertEqualObjects(obj1[@"name"], @"Test2", @"Name should be Test1");
    
    [realm beginWriteTransaction];
    obj0[@"name"] = @"newName";
    [realm commitWriteTransaction];
    
    XCTAssertEqualObjects(obj0[@"name"], @"newName",  @"Name should be newName");
    

}

- (void)testCustomAccessors {
    RLMRealm *realm = [RLMRealm defaultRealm];
    
    [realm beginWriteTransaction];
    CustomAccessors *ca = [CustomAccessors createInRealm:realm withObject:@[@"name", @2]];
    XCTAssertEqualObjects([ca getThatName], @"name", @"name property should be name.");
        
    [ca setTheInt:99];
    XCTAssertEqual((int)ca.age, (int)99, @"age property should be 99");
    [realm commitWriteTransaction];
  
}

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


//- (void)testDataTypes_Typed
//{
//    [self.realmWithTestPath writeUsingBlock:^(RLMRealm *realm) {
//        // create table and set object class
//        AllTypesTable *table = [AllTypesTable tableInRealm:realm named:@"table"];
//
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

@end
