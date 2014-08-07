////////////////////////////////////////////////////////////////////////////
//
// Copyright 2014 Realm Inc.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//
////////////////////////////////////////////////////////////////////////////

#import "RLMTestCase.h"
#import "RLMPredicateUtil.h"

#import <libkern/OSAtomic.h>

#pragma mark - Test Objects

#pragma mark DefaultObject

@interface DefaultObject : RLMObject
@property int       intCol;
@property float     floatCol;
@property double    doubleCol;
@property BOOL      boolCol;
@property NSDate   *dateCol;
@property NSString *stringCol;
@property NSData   *binaryCol;
@property id        mixedCol;
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

#pragma mark IgnoredURLObject

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

#pragma mark IndexedObject

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

#pragma mark - Private

@interface RLMRealm ()
@property (nonatomic) RLMSchema *schema;
@end

#pragma mark - Tests

@interface ObjectTests : RLMTestCase
@end

@implementation ObjectTests

-(void)testObjectInit
{
    RLMRealm *realm = [RLMRealm defaultRealm];
    
    [realm beginWriteTransaction];
    
    // Init object before adding to realm
    EmployeeObject *soInit = [[EmployeeObject alloc] init];
    soInit.name = @"Peter";
    soInit.age = 30;
    soInit.hired = YES;
    [realm addObject:soInit];
    
    // Create object while adding to realm using NSArray
    EmployeeObject *soUsingArray = [EmployeeObject createInRealm:realm withObject:@[@"John", @40, @NO]];
    
    // Create object while adding to realm using NSDictionary
    EmployeeObject *soUsingDictionary = [EmployeeObject createInRealm:realm withObject:@{@"name": @"Susi", @"age": @25, @"hired": @YES}];
    
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
    
    XCTAssertThrowsSpecificNamed([soInit JSONString], NSException, @"RLMNotImplementedException", @"Not yet implemented");
}

-(void)testObjectInitWithObjectTypeArray
{
    EmployeeObject *obj1 = [[EmployeeObject alloc] initWithObject:@[@"Peter", @30, @YES]];
    
    XCTAssertEqualObjects(obj1.name, @"Peter", @"Names should be equal");
    XCTAssertEqual(obj1.age, 30, @"Age should be equal");
    XCTAssertEqual(obj1.hired, YES, @"Hired should be equal");
    
    // Add to realm
    RLMRealm *realm = [RLMRealm defaultRealm];
    [realm beginWriteTransaction];
    [realm addObject:obj1];
    [realm commitWriteTransaction];
    
    RLMArray *all = [EmployeeObject allObjects];
    EmployeeObject *fromRealm = all.firstObject;
    
    XCTAssertEqualObjects(fromRealm.name, @"Peter", @"Names should be equal");
    XCTAssertEqual(fromRealm.age, 30, @"Age should be equal");
    XCTAssertEqual(fromRealm.hired, YES, @"Hired should be equal");
    
    XCTAssertThrows(([[EmployeeObject alloc] initWithObject:@[@"Peter", @30]]), @"To few arguments");
    XCTAssertThrows(([[EmployeeObject alloc] initWithObject:@[@YES, @"Peter", @30]]), @"Wrong arguments");
    XCTAssertThrows(([[EmployeeObject alloc] initWithObject:@[]]), @"empty arguments");
}

-(void)testObjectInitWithObjectTypeDictionary
{
    EmployeeObject *obj1 = [[EmployeeObject alloc] initWithObject:@{@"name": @"Susi", @"age": @25, @"hired": @YES}];
    
    XCTAssertEqualObjects(obj1.name, @"Susi", @"Names should be equal");
    XCTAssertEqual(obj1.age, 25, @"Age should be equal");
    XCTAssertEqual(obj1.hired, YES, @"Hired should be equal");
    
    // Add to realm
    RLMRealm *realm = [RLMRealm defaultRealm];
    [realm beginWriteTransaction];
    [realm addObject:obj1];
    [realm commitWriteTransaction];
    
    RLMArray *all = [EmployeeObject allObjects];
    EmployeeObject *fromRealm = all.firstObject;
    
    XCTAssertEqualObjects(fromRealm.name, @"Susi", @"Names should be equal");
    XCTAssertEqual(fromRealm.age, 25, @"Age should be equal");
    XCTAssertEqual(fromRealm.hired, YES, @"Hired should be equal");
    
    XCTAssertThrows([[EmployeeObject alloc] initWithObject:@{}], @"Initialization with missing values should throw");
    XCTAssertNoThrow([[DefaultObject alloc] initWithObject:@{@"intCol": @1}],
                     "Overriding some default values at initialization should not throw");
}

-(void)testObjectInitWithObjectLiterals {
    NSArray *array = @[@"company", @[@[@"Alex", @29, @YES]]];
    CompanyObject *company = [[CompanyObject alloc] initWithObject:array];
    XCTAssertEqualObjects(company.name, array[0], @"Company name should be set");
    XCTAssertEqualObjects([company.employees[0] name], array[1][0][0], @"First employee should be Alex");

    NSDictionary *dict = @{@"name": @"dictionaryCompany", @"employees": @[@{@"name": @"Bjarne", @"age": @32, @"hired": @NO}]};
    CompanyObject *dictCompany = [[CompanyObject alloc] initWithObject:dict];
    XCTAssertEqualObjects(dictCompany.name, dict[@"name"], @"Company name should be set");
    XCTAssertEqualObjects([dictCompany.employees[0] name], dict[@"employees"][0][@"name"], @"First employee should be Bjarne");

    NSArray *invalidArray = @[@"company", @[@[@"Alex", @29, @2]]];
    XCTAssertThrows([[CompanyObject alloc] initWithObject:invalidArray], @"Invalid sub-literal should throw");
    NSDictionary *invalidDict= @{@"employees": @[@[@"Alex", @29, @2]]};
    XCTAssertThrows([[CompanyObject alloc] initWithObject:invalidDict], @"Dictionary missing properties should throw");

    OwnerObject *owner = [[OwnerObject alloc] initWithObject:@[@"Brian", @{@"dogName": @"Brido"}]];
    XCTAssertEqualObjects(owner.dog.dogName, @"Brido");

    OwnerObject *ownerArrayDog = [[OwnerObject alloc] initWithObject:@[@"JP", @[@"PJ"]]];
    XCTAssertEqualObjects(ownerArrayDog.dog.dogName, @"PJ");
}


-(void)testObjectInitWithObjectTypeOther
{
    XCTAssertThrows([[EmployeeObject alloc] initWithObject:@"StringObject"], @"Not an array or dictionary");
    XCTAssertThrows([[EmployeeObject alloc] initWithObject:nil], @"Not an array or dictionary");
}


- (void)testObjectSubscripting
{
    RLMRealm *realm = [RLMRealm defaultRealm];

    [realm beginWriteTransaction];
    IntObject *obj0 = [IntObject createInRealm:realm withObject:@[@10]];
    IntObject *obj1 = [IntObject createInRealm:realm withObject:@[@20]];
    [realm commitWriteTransaction];

    XCTAssertEqual(obj0.intCol, 10,  @"integer should be 10");
    XCTAssertEqual(obj1.intCol, 20, @"integer should be 20");

    [realm beginWriteTransaction];
    obj0.intCol = 7;
    [realm commitWriteTransaction];

    XCTAssertEqual(obj0.intCol, 7,  @"integer should be 7");
}

- (void)testKeyedSubscripting
{
    // standalone
    EmployeeObject *objs = [[EmployeeObject alloc] initWithObject:@{@"name" : @"Test0", @"age" : @23, @"hired": @NO}];
    XCTAssertEqualObjects(objs[@"name"], @"Test0",  @"Name should be Test0");
    XCTAssertEqualObjects(objs[@"age"], @23,  @"age should be 23");
    XCTAssertEqualObjects(objs[@"hired"], @NO,  @"hired should be NO");
    objs[@"name"] = @"Test1";
    XCTAssertEqualObjects(objs.name, @"Test1",  @"Name should be Test1");

    RLMRealm *realm = [RLMRealm defaultRealm];
    [realm beginWriteTransaction];
    EmployeeObject *obj0 = [EmployeeObject createInRealm:realm withObject:@{@"name" : @"Test1", @"age" : @24, @"hired": @NO}];
    EmployeeObject *obj1 = [EmployeeObject createInRealm:realm withObject:@{@"name" : @"Test2", @"age" : @25, @"hired": @YES}];
    [realm commitWriteTransaction];
    
    XCTAssertEqualObjects(obj0[@"name"], @"Test1",  @"Name should be Test1");
    XCTAssertEqualObjects(obj1[@"name"], @"Test2", @"Name should be Test1");
    
    [realm beginWriteTransaction];
    obj0[@"name"] = @"newName";
    [realm commitWriteTransaction];
    
    XCTAssertEqualObjects(obj0[@"name"], @"newName",  @"Name should be newName");
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
    c.objectCol = [[StringObject alloc] init];
    c.objectCol.stringCol = @"c";
    
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
    XCTAssertTrue([row1.objectCol.stringCol isEqual:@"c"], @"row1.objectCol");
    XCTAssertNil(row2.objectCol,                        @"row2.objectCol");

    XCTAssertTrue([row1.mixedCol isEqual:@"string"],    @"row1.mixedCol");
    XCTAssertEqualObjects(row2.mixedCol, @2,            @"row2.mixedCol");
}

#pragma mark - Default Property Values

- (void)testNoDefaultPropertyValues
{
    // Test alloc init does not crash for no defaultPropertyValues implementation
    XCTAssertNoThrow(([[EmployeeObject alloc] init]), @"Not implementing defaultPropertyValues should not crash");
}

- (void)testNoDefaultAdd
{
    RLMRealm *realm = [RLMRealm defaultRealm];
    
    [realm beginWriteTransaction];
    
    // Test #1
    StringObject *stringObject = [[StringObject alloc] init];
    XCTAssertThrows(([realm addObject:stringObject]), @"Adding object with no values specified for NSObject properties should throw exception if NSObject property is nil");
    
    // Test #2
    stringObject.stringCol = @"";
    XCTAssertNoThrow(([realm addObject:stringObject]), @"Having values in all NSObject properties should not throw exception when being added to realm");
    
    // Test #3
//    FIXME: Test should pass
//    IntObject *intObj = [[IntObject alloc] init];
//    XCTAssertThrows(([realm addObject:intObj]), @"Adding object with no values specified for NSObject properties should throw exception if NSObject property is nil");
    
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
    
    IgnoredURLObject *obj2 = [[IgnoredURLObject objectsWithPredicate:nil] firstObject];
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
    StringObject *to = [StringObject createInRealm:realm withObject:@[@"c"]];
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

-(void)testCreateInRealmWithObjectLiterals {
    RLMRealm *realm = [RLMRealm defaultRealm];

    // create with array literals
    [realm beginWriteTransaction];

    NSArray *array = @[@"company", @[@[@"Alex", @29, @YES]]];
    [CompanyObject createInDefaultRealmWithObject:array];

    NSDictionary *dict = @{@"name": @"dictionaryCompany", @"employees": @[@{@"name": @"Bjarne", @"age": @32, @"hired": @NO}]};
    [CompanyObject createInDefaultRealmWithObject:dict];

    NSArray *invalidArray = @[@"company", @[@[@"Alex", @29, @2]]];
    XCTAssertThrows([CompanyObject createInDefaultRealmWithObject:invalidArray], @"Invalid sub-literal should throw");

    [realm commitWriteTransaction];

    // verify array literals
    CompanyObject *company = CompanyObject.allObjects[0];
    XCTAssertEqualObjects(company.name, array[0], @"Company name should be set");
    XCTAssertEqualObjects([company.employees[0] name], array[1][0][0], @"First employee should be Alex");

    CompanyObject *dictCompany = CompanyObject.allObjects[1];
    XCTAssertEqualObjects(dictCompany.name, dict[@"name"], @"Company name should be set");
    XCTAssertEqualObjects([dictCompany.employees[0] name], dict[@"employees"][0][@"name"], @"First employee should be Bjarne");

    // create with object literals
    [realm beginWriteTransaction];

    [OwnerObject createInDefaultRealmWithObject:@[@"Brian", @{@"dogName": @"Brido"}]];
    [OwnerObject createInDefaultRealmWithObject:@[@"JP", @[@"PJ"]]];

    [realm commitWriteTransaction];

    // verify object literals
    OwnerObject *brian = OwnerObject.allObjects[0], *jp = OwnerObject.allObjects[1];
    XCTAssertEqualObjects(brian.dog.dogName, @"Brido");
    XCTAssertEqualObjects(jp.dog.dogName, @"PJ");
}


- (void)testCreateInRealmWithMissingValue
{
    RLMRealm *realm = [RLMRealm defaultRealm];
    
    [realm beginWriteTransaction];
    
    // This exception only gets thrown when there is no default vaule and it is for an NSObject property
    XCTAssertThrows(([EmployeeObject createInRealm:realm withObject:@{@"age" : @27, @"hired" : @YES}]), @"Missing values in NSDictionary should throw default value exception");
    
    // This exception gets thrown when count of array does not match with object schema
    XCTAssertThrows(([EmployeeObject createInRealm:realm withObject:@[@27, @YES]]), @"Missing values in NSDictionary should throw default value exception");
    
    [realm commitWriteTransaction];
}

- (void)testObjectDescription
{
    RLMRealm *realm = [RLMRealm defaultRealm];
    
    [realm beginWriteTransaction];
    
    // Init object before adding to realm
    EmployeeObject *soInit = [[EmployeeObject alloc] init];
    soInit.name = @"Peter";
    soInit.age = 30;
    soInit.hired = YES;
    [realm addObject:soInit];
    
    // description asserts block
    void(^descriptionAsserts)(NSString *) = ^(NSString *description) {
        XCTAssertTrue([description rangeOfString:@"name"].location != NSNotFound, @"column names should be displayed when calling \"description\" on RLMObject subclasses");
        XCTAssertTrue([description rangeOfString:@"Peter"].location != NSNotFound, @"column values should be displayed when calling \"description\" on RLMObject subclasses");
        
        XCTAssertTrue([description rangeOfString:@"age"].location != NSNotFound, @"column names should be displayed when calling \"description\" on RLMObject subclasses");
        XCTAssertTrue([description rangeOfString:[@30 description]].location != NSNotFound, @"column values should be displayed when calling \"description\" on RLMObject subclasses");
        
        XCTAssertTrue([description rangeOfString:@"hired"].location != NSNotFound, @"column names should be displayed when calling \"description\" on RLMObject subclasses");
        XCTAssertTrue([description rangeOfString:[@YES description]].location != NSNotFound, @"column values should be displayed when calling \"description\" on RLMObject subclasses");
    };
    
    // Test description in write block
    descriptionAsserts(soInit.description);
    
    [realm commitWriteTransaction];
    
    // Test description in read block
    NSString *objDescription = [[[EmployeeObject objectsWithPredicate:nil] firstObject] description];
    descriptionAsserts(objDescription);
}

#pragma mark - Indexing Tests

- (void)testIndex
{
    RLMProperty *nameProperty = [[RLMRealm defaultRealm] schema][IndexedObject.className][@"name"];
    XCTAssertTrue(nameProperty.attributes & RLMPropertyAttributeIndexed, @"indexed property should have an index");
    
    RLMProperty *ageProperty = [[RLMRealm defaultRealm] schema][IndexedObject.className][@"age"];
    XCTAssertFalse(ageProperty.attributes & RLMPropertyAttributeIndexed, @"non-indexed property shouldn't have an index");
}

- (void)testRetainedRealmObjectUnknownKey
{
    IntObject *obj = [[IntObject alloc] init];
    RLMRealm *realm = [RLMRealm defaultRealm];
    [realm beginWriteTransaction];
    [realm addObject:obj];
    [realm commitWriteTransaction];
    XCTAssertThrowsSpecificNamed([obj objectForKeyedSubscript:@""], NSException,
                                 @"RLMException", "Invalid property name");
    XCTAssertThrowsSpecificNamed([obj setObject:@0 forKeyedSubscript:@""], NSException,
                                 @"RLMException", "Invalid property name");
}

- (void)testUnretainedRealmObjectUnknownKey
{
    IntObject *obj = [[IntObject alloc] init];
    XCTAssertThrowsSpecificNamed([obj objectForKeyedSubscript:@""], NSException,
                                 @"NSUnknownKeyException");
    XCTAssertThrowsSpecificNamed([obj setObject:@0 forKeyedSubscript:@""], NSException,
                                 @"NSUnknownKeyException");
}

- (void)testEquality
{
    IntObject *obj = [[IntObject alloc] init];
    IntObject *otherObj = [[IntObject alloc] init];
    BoolObject *boolObj = [[BoolObject alloc] init];

    RLMRealm *realm = [RLMRealm defaultRealm];
    RLMRealm *otherRealm = [self realmWithTestPath];

    XCTAssertTrue([obj isEqual:obj], @"Same instance.");
    XCTAssertFalse([obj isEqual:otherObj], @"Comparison outside of realm.");

    [realm beginWriteTransaction];
    [realm addObject: obj];
    [realm commitWriteTransaction];

    XCTAssertFalse([obj isEqual:otherObj], @"One in realm, the other is not.");
    XCTAssertTrue([obj isEqual:[IntObject allObjects][0]], @"Same table and index.");

    [otherRealm beginWriteTransaction];
    [otherRealm addObject: otherObj];
    [otherRealm commitWriteTransaction];

    XCTAssertFalse([obj isEqual:otherObj], @"Different realms.");

    [realm beginWriteTransaction];
    [realm addObject: otherObj];
    [realm addObject: boolObj];
    [realm commitWriteTransaction];

    XCTAssertFalse([obj isEqual:[IntObject allObjects][1]], @"Same table, different index.");
    XCTAssertFalse([obj isEqual:[BoolObject allObjects][0]], @"Different tables.");
}

- (void)testCrossThreadAccess
{
    IntObject *obj = [[IntObject alloc] init];

    // Standalone can be accessed from other threads
    // Using dispatch_async to ensure it actually lands on another thread
    __block OSSpinLock spinlock = OS_SPINLOCK_INIT;
    OSSpinLockLock(&spinlock);
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        XCTAssertNoThrow(obj.intCol = 5);
        OSSpinLockUnlock(&spinlock);
    });
    OSSpinLockLock(&spinlock);

    [RLMRealm.defaultRealm beginWriteTransaction];
    [RLMRealm.defaultRealm addObject:obj];
    [RLMRealm.defaultRealm commitWriteTransaction];

    XCTAssertNoThrow(obj.intCol);
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        XCTAssertThrows(obj.intCol);
        OSSpinLockUnlock(&spinlock);
    });
    OSSpinLockLock(&spinlock);
}

@end
