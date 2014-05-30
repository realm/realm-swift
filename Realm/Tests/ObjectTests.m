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

@interface RLMRealm (Private)

- (BOOL)isPropertyIndexed:(NSString *)propertyName forClass:(NSString *)className;

@end

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

@interface KeyedObject : RLMObject
@property NSString * name;
@property int objID;
@end

@implementation KeyedObject
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

@interface IgnoredURLObject : RLMObject
@property NSString *name;
@property NSURL *url;
@end

@implementation IgnoredURLObject

+ (NSArray *)ignoredProperties
{
    return @[@"url"];
}

@end

@interface IndexedObject : RLMObject
@property NSString *name;
@property NSInteger age;
@end

@implementation IndexedObject

+ (RLMPropertyAttributes)attributesForProperty:(NSString *)propertyName
{
    RLMPropertyAttributes superAttributes = [super attributesForProperty:propertyName];
    if ([propertyName isEqualToString:@"name"]) {
        superAttributes |= RLMPropertyAttributeIndexed;
    }
    return superAttributes;
}

@end

@interface ObjectTests : RLMTestCase
@end

@implementation ObjectTests

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
    c.objectCol = [[RLMTestObject alloc] init];
    c.objectCol.column = @"c";
    
    [realm addObject:c];

    [AllTypesObject createInRealm:realm withObject:@[@YES, @506, @7.7f, @8.8, @"banach", bin2,
                                                     timeNow, @YES, @(-20), @2, NSNull.null]];
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
    XCTAssertTrue([row1.objectCol.column isEqual:@"c"], @"row1.objectCol");
    XCTAssertNil(row2.objectCol,                        @"row2.objectCol");

    XCTAssertTrue([row1.mixedCol isEqual:@"string"],    @"row1.mixedCol");
    XCTAssertEqualObjects(row2.mixedCol, @2,            @"row2.mixedCol");
}

#pragma mark - Default Property Values

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
    
    for (NSUInteger i = 0; i < keyPaths.count; i++) {
        NSString *keyToDefault = keyPaths[i];
        NSMutableDictionary *dict = [inputKeyPathsAndValues mutableCopy];
        [dict removeObjectForKey:keyToDefault];
        
        [DefaultObject createInRealm:realm withObject:dict];
    }
    
    [realm commitWriteTransaction];

    // Test allObject for DefaultObject
    NSDictionary * const defaultKeyPathsAndValues = [DefaultObject defaultPropertyValues];
    for (NSUInteger i = 0; i < keyPaths.count; i++) {
        NSString *keyToDefault = keyPaths[i];
        DefaultObject *object = [DefaultObject allObjects][i];
        
        for (NSUInteger j = 0; j < keyPaths.count; j++) {
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

#pragma mark - Ignored Properties

- (void)testIgnoredUnsupportedProperty
{
    RLMRealm *realm = [RLMRealm defaultRealm];
    
    [realm beginWriteTransaction];
    XCTAssertNoThrow([IgnoredURLObject new], @"Creating a new object with an (ignored) unsupported \
                                               property type should not throw");
    [realm rollbackWriteTransaction];
}

- (void)testCanUseIgnoredProperty
{
    NSURL *url = [NSURL URLWithString:@"http://realm.io"];
    RLMRealm *realm = [RLMRealm defaultRealm];
    
    [realm beginWriteTransaction];
    
    IgnoredURLObject *obj = [IgnoredURLObject new];
    obj.name = @"Realm";
    obj.url = url;
    [realm addObject:obj];
    XCTAssertEqual(obj.url, url, @"ignored properties should still be assignable and gettable inside a write block");
    
    [realm commitWriteTransaction];
    
    XCTAssertEqual(obj.url, url, @"ignored properties should still be assignable and gettable outside a write block");
    
    IgnoredURLObject *obj2 = [[IgnoredURLObject objectsWhere:nil] firstObject];
    XCTAssertNotNil(obj2, @"object with ignored property should still be stored and accessible through the realm");
    
    XCTAssertEqualObjects(obj2.name, obj.name, @"persisted property should be the same");
    XCTAssertNil(obj2.url, @"ignored property should be nil when getting from realm");
}

- (void)testCreateInRealmValidationForDictionary
{
    RLMRealm *realm = [RLMRealm defaultRealm];
    
    const char bin[4] = { 0, 1, 2, 3 };
    NSData* bin1 = [[NSData alloc] initWithBytes:bin length:sizeof bin / 2];
    NSDate *timeNow = [NSDate dateWithTimeIntervalSince1970:1000000];
    NSDictionary * const dictValidAllTypes = @{@"boolCol" : @NO,
                                               @"intCol" : @54,
                                               @"floatCol" : @0.7f,
                                               @"doubleCol" : @0.8,
                                               @"stringCol" : @"foo",
                                               @"binaryCol" : bin1,
                                               @"dateCol" : timeNow,
                                               @"cBoolCol" : @NO,
                                               @"longCol" : @(99),
                                               @"mixedCol" : @"mixed",
                                               @"objectCol": NSNull.null};
    
    [realm beginWriteTransaction];
    
    // Test NSDictonary
    XCTAssertNoThrow(([AllTypesObject createInRealm:realm withObject:dictValidAllTypes]), @"Creating object with valid value types should not throw exception");
    
    for (NSString *keyToInvalidate in dictValidAllTypes.allKeys) {
        NSMutableDictionary *invalidInput = [dictValidAllTypes mutableCopy];
        id obj = @"invalid";
        if ([keyToInvalidate isEqualToString:@"stringCol"]) {
            obj = @1;
        }
        
        invalidInput[keyToInvalidate] = obj;
        
        // Ignoring test for mixedCol since only NSObjects can go in NSDictionary
        if (![keyToInvalidate isEqualToString:@"mixedCol"]) {
            XCTAssertThrows(([AllTypesObject createInRealm:realm withObject:invalidInput]), @"Creating object with invalid value types should throw exception");
        }
    }
    
    
    [realm commitWriteTransaction];
}

- (void)testCreateInRealmValidationForArray
{
    RLMRealm *realm = [RLMRealm defaultRealm];
    
    // add test/link object to realm
    [realm beginWriteTransaction];
    RLMTestObject *to = [RLMTestObject createInRealm:realm withObject:@[@"c"]];
    [realm commitWriteTransaction];
    
    const char bin[4] = { 0, 1, 2, 3 };
    NSData* bin1 = [[NSData alloc] initWithBytes:bin length:sizeof bin / 2];
    NSDate *timeNow = [NSDate dateWithTimeIntervalSince1970:1000000];
    NSArray * const arrayValidAllTypes = @[@NO, @54, @0.7f, @0.8, @"foo", bin1, timeNow, @NO, @(99), @"mixed", to];
    
    [realm beginWriteTransaction];
    
    // Test NSArray
    XCTAssertNoThrow(([AllTypesObject createInRealm:realm withObject:arrayValidAllTypes]), @"Creating object with valid value types should not throw exception");
    
    const NSInteger stringColIndex = 4;
    const NSInteger mixedColIndex = 9;
    for (NSUInteger i = 0; i < arrayValidAllTypes.count; i++) {
        NSMutableArray *invalidInput = [arrayValidAllTypes mutableCopy];
        
        id obj = @"invalid";
        if (i == stringColIndex) {
            obj = @1;
        }
        
        invalidInput[i] = obj;
        
        // Ignoring test for mixedCol since only NSObjects can go in NSArray
        if (i != mixedColIndex) {
            XCTAssertThrows(([AllTypesObject createInRealm:realm withObject:invalidInput]), @"Creating object with invalid value types should throw exception");
        }
    }
    
    [realm commitWriteTransaction];
}

- (void)testCreateInRealmWithMissingValue
{
    RLMRealm *realm = [RLMRealm defaultRealm];
    
    [realm beginWriteTransaction];
    
    // This exception only gets thrown when there is no default vaule and it is for an NSObject property
    XCTAssertThrows(([SimpleObject createInRealm:realm withObject:@{@"age" : @27, @"hired" : @YES}]), @"Missing values in NSDictionary should throw default value exception");
    
    // This exception gets thrown when count of array does not match with object schema
    XCTAssertThrows(([SimpleObject createInRealm:realm withObject:@[@27, @YES]]), @"Missing values in NSDictionary should throw default value exception");
    
    [realm commitWriteTransaction];
}

#pragma mark - Indexing Tests

- (void)testIndex
{
    XCTAssertTrue([[RLMRealm defaultRealm] isPropertyIndexed:@"name" forClass:IndexedObject.className], @"indexed property should have an index");
    XCTAssertFalse([[RLMRealm defaultRealm] isPropertyIndexed:@"age" forClass:IndexedObject.className], @"non-indexed property shouldn't have an index");
}

@end
