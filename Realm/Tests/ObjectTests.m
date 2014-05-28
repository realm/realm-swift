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
#import "RLMTestObjects.h"

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

@interface InvalidSubclassObject : AgeObject
@property NSString *invalid;
@end

@implementation InvalidSubclassObject
@end


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
@property int intCol;
@property float floatCol;
@property double doubleCol;
@property BOOL boolCol;
@property NSDate *dateCol;
@end

@implementation AggregateObject
@end


@interface DefaultObject : RLMObject
@property int intCol;
@property float floatCol;
@property double doubleCol;
@property BOOL boolCol;
@property NSDate *dateCol;
@property NSString *stringCol;
@property NSData *binaryCol;
@property id mixedCol;
@end

@implementation DefaultObject

+ (NSDictionary *)defaultPropertyValues
{
    NSString *binaryString = @"binary";
    NSData *binaryData = [binaryString dataUsingEncoding:NSUTF8StringEncoding];
    
    return @{@"intCol" : @12,
             @"floatCol" : @88.9f,
             @"doubleCol" : @1002.892,
             @"boolCol" : @YES,
             @"dateCol" : [NSDate dateWithTimeIntervalSince1970:999999],
             @"stringCol" : @"potato",
             @"binaryCol" : binaryData,
             @"mixedCol" : @"foo"};
}

@end

@interface NoDefaultObject : RLMObject
@property NSString *stringCol;
@property int intCol;

@end

@implementation NoDefaultObject
@end


@interface RLMObjectTests : RLMTestCase
@end

@implementation RLMObjectTests

-(void)testObjectInit
{
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

- (void)testCustomAccessors
{
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
    RLMRealm *realm = [RLMRealm defaultRealm];
    
    [realm beginWriteTransaction];
    
    NSDate *dateMinInput = [NSDate date];
    NSDate *dateMaxInput = [dateMinInput dateByAddingTimeInterval:1000];
    
    [AggregateObject createInRealm:realm withObject:@[@0, @1.2f, @0.0, @YES, dateMinInput]];
    [AggregateObject createInRealm:realm withObject:@[@1, @0.0f, @2.5, @NO, dateMaxInput]];
    [AggregateObject createInRealm:realm withObject:@[@0, @1.2f, @0.0, @YES, dateMinInput]];
    [AggregateObject createInRealm:realm withObject:@[@1, @0.0f, @2.5, @NO, dateMaxInput]];
    [AggregateObject createInRealm:realm withObject:@[@0, @1.2f, @0.0, @YES, dateMinInput]];
    [AggregateObject createInRealm:realm withObject:@[@1, @0.0f, @2.5, @NO, dateMaxInput]];
    [AggregateObject createInRealm:realm withObject:@[@0, @1.2f, @0.0, @YES, dateMinInput]];
    [AggregateObject createInRealm:realm withObject:@[@1, @0.0f, @2.5, @NO, dateMaxInput]];
    [AggregateObject createInRealm:realm withObject:@[@0, @1.2f, @0.0, @YES, dateMinInput]];
    [AggregateObject createInRealm:realm withObject:@[@0, @1.2f, @0.0, @YES, dateMinInput]];
    
    [realm commitWriteTransaction];
        
    RLMArray *noArray = [AggregateObject objectsWhere:@"boolCol == NO"];
    RLMArray *yesArray = [AggregateObject objectsWhere:@"boolCol == YES"];
    
    // SUM ::::::::::::::::::::::::::::::::::::::::::::::
    // Test int sum
    XCTAssertEqual([noArray sumOfProperty:@"intCol"].integerValue, (NSInteger)4, @"Sum should be 4");
    XCTAssertEqual([yesArray sumOfProperty:@"intCol"].integerValue, (NSInteger)0, @"Sum should be 0");
        
    // Test float sum
    XCTAssertEqualWithAccuracy([noArray sumOfProperty:@"floatCol"].floatValue, (float)0.0f, 0.1f, @"Sum should be 0.0");
    XCTAssertEqualWithAccuracy([yesArray sumOfProperty:@"floatCol"].floatValue, (float)7.2f, 0.1f, @"Sum should be 7.2");
        
    // Test double sum
    XCTAssertEqualWithAccuracy([noArray sumOfProperty:@"doubleCol"].doubleValue, (double)10.0, 0.1f, @"Sum should be 10.0");
    XCTAssertEqualWithAccuracy([yesArray sumOfProperty:@"doubleCol"].doubleValue, (double)0.0, 0.1f, @"Sum should be 0.0");
        
    // Test invalid column name
    XCTAssertThrows([yesArray sumOfProperty:@"foo"], @"Should throw exception");
        
    // Test operation not supported
    XCTAssertThrows([yesArray sumOfProperty:@"boolCol"], @"Should throw exception");
    
    
    // Average ::::::::::::::::::::::::::::::::::::::::::::::
    // Test int average
    XCTAssertEqualWithAccuracy([noArray averageOfProperty:@"intCol"].doubleValue, (double)1.0, 0.1f, @"Average should be 1.0");
    XCTAssertEqualWithAccuracy([yesArray averageOfProperty:@"intCol"].doubleValue, (double)0.0, 0.1f, @"Average should be 0.0");
    
    // Test float average
    XCTAssertEqualWithAccuracy([noArray averageOfProperty:@"floatCol"].doubleValue, (double)0.0f, 0.1f, @"Average should be 0.0");
    XCTAssertEqualWithAccuracy([yesArray averageOfProperty:@"floatCol"].doubleValue, (double)1.2f, 0.1f, @"Average should be 1.2");
    
    // Test double average
    XCTAssertEqualWithAccuracy([noArray averageOfProperty:@"doubleCol"].doubleValue, (double)2.5, 0.1f, @"Average should be 2.5");
    XCTAssertEqualWithAccuracy([yesArray averageOfProperty:@"doubleCol"].doubleValue, (double)0.0, 0.1f, @"Average should be 0.0");
    
    // Test invalid column name
    XCTAssertThrows([yesArray averageOfProperty:@"foo"], @"Should throw exception");
    
    // Test operation not supported
    XCTAssertThrows([yesArray averageOfProperty:@"boolCol"], @"Should throw exception");
    
    // MIN ::::::::::::::::::::::::::::::::::::::::::::::
    // Test int min
    NSNumber *min = [noArray minOfProperty:@"intCol"];
    XCTAssertEqual(min.intValue, (NSInteger)1, @"Minimum should be 1");
    min = [yesArray minOfProperty:@"intCol"];
    XCTAssertEqual(min.intValue, (NSInteger)0, @"Minimum should be 0");
    
    // Test float min
    min = [noArray minOfProperty:@"floatCol"];
    XCTAssertEqualWithAccuracy(min.floatValue, (float)0.0f, 0.1f, @"Minimum should be 0.0f");
    min = [yesArray minOfProperty:@"floatCol"];
    XCTAssertEqualWithAccuracy(min.floatValue, (float)1.2f, 0.1f, @"Minimum should be 1.2f");
    
    // Test double min
    min = [noArray minOfProperty:@"doubleCol"];
    XCTAssertEqualWithAccuracy(min.doubleValue, (double)2.5, 0.1f, @"Minimum should be 1.5");
    min = [yesArray minOfProperty:@"doubleCol"];
    XCTAssertEqualWithAccuracy(min.doubleValue, (double)0.0, 0.1f, @"Minimum should be 0.0");
    
    // Test date min
    NSDate *dateMinOutput = [noArray minOfProperty:@"dateCol"];
    XCTAssertEqualWithAccuracy(dateMinOutput.timeIntervalSince1970, dateMaxInput.timeIntervalSince1970, 1, @"Minimum should be dateMaxInput");
    dateMinOutput = [yesArray minOfProperty:@"dateCol"];
    XCTAssertEqualWithAccuracy(dateMinOutput.timeIntervalSince1970, dateMinInput.timeIntervalSince1970, 1, @"Minimum should be dateMinInput");
    
    // Test invalid column name
    XCTAssertThrows([noArray minOfProperty:@"foo"], @"Should throw exception");
    
    // Test operation not supported
    XCTAssertThrows([noArray minOfProperty:@"boolCol"], @"Should throw exception");
    
    
    // MAX ::::::::::::::::::::::::::::::::::::::::::::::
    // Test int max
    NSNumber *max = [noArray maxOfProperty:@"intCol"];
    XCTAssertEqual(max.integerValue, (NSInteger)1, @"Maximum should be 8");
    max = [yesArray maxOfProperty:@"intCol"];
    XCTAssertEqual(max.integerValue, (NSInteger)0, @"Maximum should be 10");
    
    // Test float max
    max = [noArray maxOfProperty:@"floatCol"];
    XCTAssertEqualWithAccuracy(max.floatValue, (float)0.0f, 0.1f, @"Maximum should be 0.0f");
    max = [yesArray maxOfProperty:@"floatCol"];
    XCTAssertEqualWithAccuracy(max.floatValue, (float)1.2f, 0.1f, @"Maximum should be 1.2f");
    
    // Test double max
    max = [noArray maxOfProperty:@"doubleCol"];
    XCTAssertEqualWithAccuracy(max.doubleValue, (double)2.5, 0.1f, @"Maximum should be 3.5");
    max = [yesArray maxOfProperty:@"doubleCol"];
    XCTAssertEqualWithAccuracy(max.doubleValue, (double)0.0, 0.1f, @"Maximum should be 0.0");
    
    // Test date max
    NSDate *dateMaxOutput = [noArray maxOfProperty:@"dateCol"];
    XCTAssertEqualWithAccuracy(dateMaxOutput.timeIntervalSince1970, dateMaxInput.timeIntervalSince1970, 1, @"Maximum should be dateMaxInput");
    dateMaxOutput = [yesArray maxOfProperty:@"dateCol"];
    XCTAssertEqualWithAccuracy(dateMaxOutput.timeIntervalSince1970, dateMinInput.timeIntervalSince1970, 1, @"Maximum should be dateMinInput");
    
    // Test invalid column name
    XCTAssertThrows([noArray maxOfProperty:@"foo"], @"Should throw exception");
    
    // Test operation not supported
    XCTAssertThrows([noArray maxOfProperty:@"boolCol"], @"Should throw exception");
}

- (void)testObjectSubclass
{
    RLMRealm *realm = [RLMRealm defaultRealm];
    
    [realm beginWriteTransaction];
    NSArray *obj = @[@1, @"throw"];
    XCTAssertThrows([InvalidSubclassObject createInRealm:realm withObject:obj],
                    @"Adding invalid object should throw");
    [realm commitWriteTransaction];
}

- (void)testDataTypes
{
    RLMRealm *realm = [RLMRealm defaultRealm];
    [realm beginWriteTransaction];
    
    const char bin[4] = { 0, 1, 2, 3 };
    NSData* bin1 = [[NSData alloc] initWithBytes:bin length:sizeof bin / 2];
    NSData* bin2 = [[NSData alloc] initWithBytes:bin length:sizeof bin];
    NSDate *timeNow = [NSDate dateWithTimeIntervalSince1970:1000000];
    NSDate *timeZero = [NSDate dateWithTimeIntervalSince1970:0];

    AllTypesObject *c = [[AllTypesObject alloc] init];

    c.BoolCol   = NO;
    c.IntCol  = 54;
    c.FloatCol = 0.7f;
    c.DoubleCol = 0.8;
    c.StringCol = @"foo";
    c.BinaryCol = bin1;
    c.DateCol = timeZero;
    c.cBoolCol = false;
    c.longCol = 99;
    c.mixedCol = @"string";
    
    [realm addObject:c];

    [AllTypesObject createInRealm:realm withObject:@[@YES, @506, @7.7f, @8.8, @"banach", bin2,
                                                     timeNow, @YES, @(-20), @2]];
    [realm commitWriteTransaction];
    
    AllTypesObject* row1 = [AllTypesObject allObjects][0];
    AllTypesObject* row2 = [AllTypesObject allObjects][1];

    XCTAssertEqual(row1.boolCol, NO,                    @"row1.BoolCol");
    XCTAssertEqual(row2.boolCol, YES,                   @"row2.BoolCol");
    XCTAssertEqual(row1.intCol, 54,                     @"row1.IntCol");
    XCTAssertEqual(row2.intCol, 506,                    @"row2.IntCol");
    XCTAssertEqual(row1.floatCol, 0.7f,                 @"row1.FloatCol");
    XCTAssertEqual(row2.floatCol, 7.7f,                 @"row2.FloatCol");
    XCTAssertEqual(row1.doubleCol, 0.8,                 @"row1.DoubleCol");
    XCTAssertEqual(row2.doubleCol, 8.8,                 @"row2.DoubleCol");
    XCTAssertTrue([row1.stringCol isEqual:@"foo"],      @"row1.StringCol");
    XCTAssertTrue([row2.stringCol isEqual:@"banach"],   @"row2.StringCol");
    XCTAssertTrue([row1.binaryCol isEqual:bin1],        @"row1.BinaryCol");
    XCTAssertTrue([row2.binaryCol isEqual:bin2],        @"row2.BinaryCol");
    XCTAssertTrue(([row1.dateCol isEqual:timeZero]),    @"row1.DateCol");
    XCTAssertTrue(([row2.dateCol isEqual:timeNow]),     @"row2.DateCol");
    XCTAssertEqual(row1.cBoolCol, (bool)false,          @"row1.cBoolCol");
    XCTAssertEqual(row2.cBoolCol, (bool)true,           @"row2.cBoolCol");
    XCTAssertEqual(row1.longCol, 99L,                   @"row1.IntCol");
    XCTAssertEqual(row2.longCol, -20L,                  @"row2.IntCol");

    XCTAssertTrue([row1.mixedCol isEqual:@"string"],    @"row1.mixedCol");
    XCTAssertEqualObjects(row2.mixedCol, @2,            @"row2.mixedCol");
}

- (void)testNoDefaultPropertyValues
{
    // Test alloc init does not crash for no defaultPropertyValues implementation
    XCTAssertNoThrow(([[SimpleObject alloc] init]), @"Not implementing defaultPropertyValues should not crash");
}

- (void)testNoDefaultAdd
{
    RLMRealm *realm = [RLMRealm defaultRealm];
    
    [realm beginWriteTransaction];
    
    // Test #1
    SimpleObject *simpleObject = [[SimpleObject alloc] init];
    XCTAssertThrows(([realm addObject:simpleObject]), @"Adding object with no values specified for NSObject properties should throw exception if NSObject property is nil");
    
    // Test #2
    NoDefaultObject *noDefaultObject = [[NoDefaultObject alloc] init];
    XCTAssertThrows(([realm addObject:noDefaultObject]), @"Adding object with no values specified for NSObject properties should throw exception if NSObject property is nil");
    
    // Test #3
    noDefaultObject.stringCol = @"foo";
    XCTAssertNoThrow(([realm addObject:noDefaultObject]), @"Having values in all NSObject properties should not throw exception when being added to realm");
    
    [realm commitWriteTransaction];
}

- (void)testDefaultValues
{
    RLMRealm *realm = [RLMRealm defaultRealm];
    
    [realm beginWriteTransaction];
    
    const int inputInt = 98;
    const float inputFloat = 231.0f;
    const double inputDouble = 123732.9231;
    const BOOL inputBool = NO;
    NSDate * const inputDate = [NSDate dateWithTimeIntervalSince1970:454321];
    NSString * const inputString = @"Westeros";
    NSData * const inputData = [@"inputData" dataUsingEncoding:NSUTF8StringEncoding];
    id inputMixed = @"Tyrion";
    
    NSDictionary * const inputKeyPathsAndValues = @{@"intCol" : @(inputInt), @"floatCol" : @(inputFloat), @"doubleCol" : @(inputDouble), @"boolCol" : @(inputBool), @"dateCol" : inputDate, @"stringCol" : inputString, @"binaryCol" : inputData, @"mixedCol" : inputMixed};
    NSArray * const keyPaths = inputKeyPathsAndValues.allKeys;
    
    for (NSInteger i = 0; i < keyPaths.count; i++) {
        NSString *keyToDefault = keyPaths[i];
        NSMutableDictionary *dict = [inputKeyPathsAndValues mutableCopy];
        [dict removeObjectForKey:keyToDefault];
        
        [DefaultObject createInRealm:realm withObject:dict];
    }
    
    [realm commitWriteTransaction];

    // Test allObject for DefaultObject
    NSDictionary * const defaultKeyPathsAndValues = [DefaultObject defaultPropertyValues];
    for (NSInteger i = 0; i < keyPaths.count; i++) {
        NSString *keyToDefault = keyPaths[i];
        DefaultObject *object = [DefaultObject allObjects][i];
        
        for (NSInteger j = 0; j < keyPaths.count; j++) {
            NSString *key = keyPaths[j];
            if ([key isEqualToString:keyToDefault]) {
                XCTAssertEqualObjects([object valueForKey:keyToDefault], defaultKeyPathsAndValues[keyToDefault], @"Value should match value in defaultPropertyValues method");
            }
            else {
                XCTAssertEqualObjects([object valueForKey:key], inputKeyPathsAndValues[key], @"Value should match value that object was initialized with");
            }
        }        
    }
}

@end
