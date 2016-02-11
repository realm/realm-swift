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

#import <libkern/OSAtomic.h>
#import <objc/runtime.h>
#import <stdalign.h>

#pragma mark - Test Objects

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
@property NSString *stringCol;
@property NSInteger integerCol;
@property int intCol;
@property long longCol;
@property long long longlongCol;
@property BOOL boolCol;
@property NSDate *dateCol;
@property NSNumber<RLMInt> *optionalIntCol;
@property NSNumber<RLMBool> *optionalBoolCol;

@property float floatCol;
@property double doubleCol;
@property NSData *dataCol;
@property NSNumber<RLMFloat> *optionalFloatCol;
@property NSNumber<RLMDouble> *optionalDoubleCol;
@end

@implementation IndexedObject
+ (NSArray *)indexedProperties
{
    return @[@"stringCol", @"integerCol", @"intCol", @"longCol", @"longlongCol", @"boolCol", @"dateCol", @"optionalIntCol", @"optionalBoolCol"];
}
@end

@class CycleObject;
RLM_ARRAY_TYPE(CycleObject)
@interface CycleObject : RLMObject
@property RLM_GENERIC_ARRAY(CycleObject) *objects;
@end

@implementation CycleObject
@end

@interface DogExtraObject : RLMObject
@property NSString *dogName;
@property int age;
@property NSString *breed;
@end

@implementation DogExtraObject
@end

@interface PrimaryIntObject : RLMObject
@property int intCol;
@end
RLM_ARRAY_TYPE(PrimaryIntObject);

@implementation PrimaryIntObject
+ (NSString *)primaryKey {
    return @"intCol";
}
@end

@interface PrimaryInt64Object : RLMObject
@property int64_t int64Col;
@end

@implementation PrimaryInt64Object
+ (NSString *)primaryKey {
    return @"int64Col";
}
@end

@interface PrimaryNullableIntObject : RLMObject
@property NSNumber<RLMInt> *optIntCol;
@end

@implementation PrimaryNullableIntObject
+ (NSString *)primaryKey {
    return @"optIntCol";
}
@end

@interface PrimaryStringObjectWrapper : RLMObject
@property PrimaryStringObject *primaryStringObject;
@end

@implementation PrimaryStringObjectWrapper
@end

@interface PrimaryNestedObject : RLMObject
@property int primaryCol;
@property PrimaryStringObject *primaryStringObject;
@property PrimaryStringObjectWrapper *primaryStringObjectWrapper;
@property StringObject *stringObject;
@property RLM_GENERIC_ARRAY(PrimaryIntObject) *primaryIntArray;
@property NSString *stringCol;
@end

@implementation PrimaryNestedObject
+ (NSString *)primaryKey {
    return @"primaryCol";
}
+ (NSDictionary *)defaultPropertyValues {
    return @{@"stringCol" : @"default"};
}
@end

@interface StringSubclassObject : StringObject
@property NSString *stringCol2;
@end

@implementation StringSubclassObject
@end

@interface StringObjectNoThrow : StringObject
@end

@implementation StringObjectNoThrow
- (id)valueForUndefinedKey:(__unused NSString *)key {
    return nil;
}
@end

@interface StringSubclassObjectWithDefaults : StringObjectNoThrow
@property NSString *stringCol2;
@end

@implementation StringSubclassObjectWithDefaults
+(NSDictionary *)defaultPropertyValues {
    return @{@"stringCol2": @"default"};
}
@end

@interface StringLinkObject : RLMObject
@property StringObject *stringObjectCol;
@property RLM_GENERIC_ARRAY(StringObject) *stringObjectArrayCol;
@end

@implementation StringLinkObject
@end

@interface ReadOnlyPropertyObject ()
@property (readwrite) int readOnlyPropertyMadeReadWriteInClassExtension;
@end

@interface DataObject : RLMObject
@property NSData *data1;
@property NSData *data2;
@end

@implementation DataObject
@end

@interface PrimaryEmployeeObject : EmployeeObject
@end

@implementation PrimaryEmployeeObject
+ (NSString *)primaryKey {
    return @"name";
}
@end

@interface LinkToPrimaryEmployeeObject : RLMObject
@property PrimaryEmployeeObject *wrapped;
@end

@implementation LinkToPrimaryEmployeeObject
@end

RLM_ARRAY_TYPE(PrimaryEmployeeObject);

@interface PrimaryCompanyObject : RLMObject
@property NSString *name;
@property RLM_GENERIC_ARRAY(PrimaryEmployeeObject) *employees;
@property PrimaryEmployeeObject *intern;
@property LinkToPrimaryEmployeeObject *wrappedIntern;
@end

@implementation PrimaryCompanyObject
+ (NSString *)primaryKey {
    return @"name";
}
@end

@interface DateObjectNoThrow : DateObject
@property NSDate *date2;
@end

@implementation DateObjectNoThrow
- (id)valueForUndefinedKey:(__unused NSString *)key {
    return nil;
}
@end

@interface DateSubclassObject : DateObjectNoThrow
@property NSDate *date3;
@end

@implementation DateSubclassObject
@end

@interface DateDefaultsObject : DateObjectNoThrow
@property NSDate *date3;
@end

@implementation DateDefaultsObject
+ (NSDictionary *)defaultPropertyValues {
    return @{
             @"date3": [NSDate date],
             };
}
@end

@interface SubclassDateObject : NSObject
@property NSDate *dateCol;
@property (getter=customGetter) NSDate *date2;
@property (setter=customSetter:) NSDate *date3;
@end

@implementation SubclassDateObject
@end

#pragma mark - Tests

@interface ObjectTests : RLMTestCase
@end

@implementation ObjectTests

- (void)testObjectInit
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
    EmployeeObject *soUsingArray = [EmployeeObject createInRealm:realm withValue:@[@"John", @40, @NO]];
    
    // Create object while adding to realm using NSDictionary
    EmployeeObject *soUsingDictionary = [EmployeeObject createInRealm:realm withValue:@{@"name": @"Susi", @"age": @25, @"hired": @YES}];
    
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

    [realm beginWriteTransaction];
    soInit = [[EmployeeObject alloc] init];
    soInit.name = nil;
    [realm addObject:soInit];

    soUsingArray = [EmployeeObject createInRealm:realm withValue:@[NSNull.null, @40, @NO]];
    soUsingDictionary = [EmployeeObject createInRealm:realm withValue:@{@"name": NSNull.null, @"age": @25, @"hired": @YES}];

    [realm commitWriteTransaction];

    XCTAssertNil(soInit.name);

    XCTAssertNil(soUsingArray.name, @"Name should be nil");
    XCTAssertEqual(soUsingArray.age, 40, @"Age should be 40");
    XCTAssertEqual(soUsingArray.hired, NO, @"Hired should NO");

    XCTAssertNil(soUsingDictionary.name, @"Name should be nil");
    XCTAssertEqual(soUsingDictionary.age, 25, @"Age should be 25");
    XCTAssertEqual(soUsingDictionary.hired, YES, @"Hired should YES");
}

-(void)testObjectInitWithObjectTypeArray
{
    EmployeeObject *obj1 = [[EmployeeObject alloc] initWithValue:@[@"Peter", @30, @YES]];
    
    XCTAssertEqualObjects(obj1.name, @"Peter", @"Names should be equal");
    XCTAssertEqual(obj1.age, 30, @"Age should be equal");
    XCTAssertEqual(obj1.hired, YES, @"Hired should be equal");
    
    // Add to realm
    RLMRealm *realm = [RLMRealm defaultRealm];
    [realm beginWriteTransaction];
    [realm addObject:obj1];
    [realm commitWriteTransaction];
    
    RLMResults *all = [EmployeeObject allObjects];
    EmployeeObject *fromRealm = all.firstObject;
    
    XCTAssertEqualObjects(fromRealm.name, @"Peter", @"Names should be equal");
    XCTAssertEqual(fromRealm.age, 30, @"Age should be equal");
    XCTAssertEqual(fromRealm.hired, YES, @"Hired should be equal");
    
    XCTAssertThrows(([[EmployeeObject alloc] initWithValue:@[@"Peter", @30]]), @"To few arguments");
    XCTAssertThrows(([[EmployeeObject alloc] initWithValue:@[@YES, @"Peter", @30]]), @"Wrong arguments");
    XCTAssertThrows(([[EmployeeObject alloc] initWithValue:@[]]), @"empty arguments");
}

-(void)testObjectInitWithObjectTypeDictionary
{
    EmployeeObject *obj1 = [[EmployeeObject alloc] initWithValue:@{@"name": @"Susi", @"age": @25, @"hired": @YES}];
    
    XCTAssertEqualObjects(obj1.name, @"Susi", @"Names should be equal");
    XCTAssertEqual(obj1.age, 25, @"Age should be equal");
    XCTAssertEqual(obj1.hired, YES, @"Hired should be equal");
    
    // Add to realm
    RLMRealm *realm = [RLMRealm defaultRealm];
    [realm beginWriteTransaction];
    [realm addObject:obj1];
    [realm commitWriteTransaction];
    
    RLMResults *all = [EmployeeObject allObjects];
    EmployeeObject *fromRealm = all.firstObject;
    
    XCTAssertEqualObjects(fromRealm.name, @"Susi", @"Names should be equal");
    XCTAssertEqual(fromRealm.age, 25, @"Age should be equal");
    XCTAssertEqual(fromRealm.hired, YES, @"Hired should be equal");
    
    XCTAssertThrows([[EmployeeObject alloc] initWithValue:@{}], @"Initialization with missing values should throw");
    XCTAssertNoThrow([[DefaultObject alloc] initWithValue:@{@"intCol": @1}],
                     "Overriding some default values at initialization should not throw");

    XCTAssertNil(([[EmployeeObject alloc] initWithValue:@[NSNull.null, @30, @YES]].name));
    XCTAssertNil(([[EmployeeObject alloc] initWithValue:@{@"name" : NSNull.null, @"age" : @30, @"hired" : @YES}].name));
    XCTAssertNil(([[EmployeeObject alloc] initWithValue:@{@"age" : @30, @"hired" : @YES}].name));
}

-(void)testObjectInitWithObjectTypeObject
{
    DogExtraObject *dogExt = [[DogExtraObject alloc] initWithValue:@[@"Fido", @12, @"Poodle"]];

    // initialize second object with first object
    DogObject *dog = [[DogObject alloc] initWithValue:dogExt];
    XCTAssertEqualObjects(dog.dogName, @"Fido", @"Names should be equal");
    XCTAssertEqual(dog.age, 12, @"Age should be equal");

    // missing properties should throw
    XCTAssertThrows([[DogExtraObject alloc] initWithValue:dog], @"Initialization with missing values should throw");

    // nested objects should work
    XCTAssertNoThrow([[OwnerObject alloc] initWithValue:(@[@"Alex", dogExt])], @"Should not throw");

    dogExt.dogName = nil;
    dogExt.breed = nil;
    dog = [[DogObject alloc] initWithValue:dogExt];
    XCTAssertNil(dog.dogName);
}

-(void)testObjectInitWithObjectLiterals {
    NSArray *array = @[@"company", @[@[@"Alex", @29, @YES]]];
    CompanyObject *company = [[CompanyObject alloc] initWithValue:array];
    XCTAssertEqualObjects(company.name, array[0], @"Company name should be set");
    XCTAssertEqualObjects([company.employees[0] name], array[1][0][0], @"First employee should be Alex");

    NSDictionary *dict = @{@"name": @"dictionaryCompany", @"employees": @[@{@"name": @"Bjarne", @"age": @32, @"hired": @NO}]};
    CompanyObject *dictCompany = [[CompanyObject alloc] initWithValue:dict];
    XCTAssertEqualObjects(dictCompany.name, dict[@"name"], @"Company name should be set");
    XCTAssertEqualObjects([dictCompany.employees[0] name], dict[@"employees"][0][@"name"], @"First employee should be Bjarne");

    NSArray *invalidArray = @[@"company", @[@[@"Alex", @29, @2]]];
    XCTAssertThrows([[CompanyObject alloc] initWithValue:invalidArray], @"Invalid sub-literal should throw");
    NSDictionary *invalidDict= @{@"employees": @[@[@"Alex", @29, @2]]};
    XCTAssertThrows([[CompanyObject alloc] initWithValue:invalidDict], @"Dictionary missing properties should throw");

    OwnerObject *owner = [[OwnerObject alloc] initWithValue:@[@"Brian", @{@"dogName": @"Brido", @"age": @0}]];
    XCTAssertEqualObjects(owner.dog.dogName, @"Brido");

    OwnerObject *ownerArrayDog = [[OwnerObject alloc] initWithValue:@[@"JP", @[@"PJ", @0]]];
    XCTAssertEqualObjects(ownerArrayDog.dog.dogName, @"PJ");
}

- (void)testInitFromDictionaryMissingPropertyKey {
    CompanyObject *co = nil;
    XCTAssertThrows([[DogExtraObject alloc] initWithValue:@{}]);
    XCTAssertNoThrow(co = [[CompanyObject alloc] initWithValue:@{@"name": @"a"}]);
    XCTAssertEqualObjects(co.name, @"a");
    XCTAssertEqual(co.employees.count, 0U);

    OwnerObject *oo = nil;
    XCTAssertNoThrow(oo = [[OwnerObject alloc] initWithValue:@{@"name": @"a"}]);
    XCTAssertEqualObjects(oo.name, @"a");
    XCTAssertNil(oo.dog);
}

- (void)testInitFromDictionaryPropertyKey {
    CompanyObject *co = nil;
    XCTAssertNoThrow((co = [[CompanyObject alloc] initWithValue:@{@"name": @"a", @"employees": NSNull.null}]));
    XCTAssertEqualObjects(co.name, @"a");
    XCTAssertEqual(co.employees.count, 0U);

    OwnerObject *oo = nil;
    XCTAssertNoThrow((oo = [[OwnerObject alloc] initWithValue:@{@"name": @"a", @"employees": NSNull.null}]));
    XCTAssertEqualObjects(oo.name, @"a");
    XCTAssertNil(oo.dog);
}

- (void)testObjectInitWithObjectTypeOther
{
    XCTAssertThrows([[EmployeeObject alloc] initWithValue:@"StringObject"], @"Not an array or dictionary");
    XCTAssertThrows([[EmployeeObject alloc] initWithValue:self.nonLiteralNil], @"Not an array or dictionary");
}

- (void)testCreateInNilRealm
{
    XCTAssertThrows(([EmployeeObject createInRealm:self.nonLiteralNil withValue:@[@"", @0, @NO]]));
}

- (void)testObjectSubscripting
{
    RLMRealm *realm = [RLMRealm defaultRealm];

    [realm beginWriteTransaction];
    IntObject *obj0 = [IntObject createInRealm:realm withValue:@[@10]];
    IntObject *obj1 = [IntObject createInRealm:realm withValue:@[@20]];
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
    EmployeeObject *objs = [[EmployeeObject alloc] initWithValue:@{@"name" : @"Test0", @"age" : @23, @"hired": @NO}];
    XCTAssertEqualObjects(objs[@"name"], @"Test0",  @"Name should be Test0");
    XCTAssertEqualObjects(objs[@"age"], @23,  @"age should be 23");
    XCTAssertEqualObjects(objs[@"hired"], @NO,  @"hired should be NO");
    objs[@"name"] = @"Test1";
    XCTAssertEqualObjects(objs.name, @"Test1",  @"Name should be Test1");

    RLMRealm *realm = [RLMRealm defaultRealm];
    [realm beginWriteTransaction];
    EmployeeObject *obj0 = [EmployeeObject createInRealm:realm withValue:@{@"name" : @"Test1", @"age" : @24, @"hired": @NO}];
    EmployeeObject *obj1 = [EmployeeObject createInRealm:realm withValue:@{@"name" : @"Test2", @"age" : @25, @"hired": @YES}];
    [realm commitWriteTransaction];
    
    XCTAssertEqualObjects(obj0[@"name"], @"Test1",  @"Name should be Test1");
    XCTAssertEqualObjects(obj1[@"name"], @"Test2", @"Name should be Test1");
    
    [realm beginWriteTransaction];
    obj0[@"name"] = @"newName";
    [realm commitWriteTransaction];
    
    XCTAssertEqualObjects(obj0[@"name"], @"newName",  @"Name should be newName");

    [realm beginWriteTransaction];
    obj0[@"name"] = nil;
    [realm commitWriteTransaction];

    XCTAssertNil(obj0[@"name"]);
}

- (void)testCannotUpdatePrimaryKey {
    PrimaryIntObject *intObj = [[PrimaryIntObject alloc] init];
    intObj.intCol = 1;
    XCTAssertNoThrow(intObj.intCol = 0);

    PrimaryStringObject *stringObj = [[PrimaryStringObject alloc] init];
    stringObj.stringCol = @"a";
    XCTAssertNoThrow(stringObj.stringCol = @"b");

    RLMRealm *realm = [RLMRealm defaultRealm];
    [realm beginWriteTransaction];
    [realm addObject:intObj];

    XCTAssertThrows(intObj.intCol = 1);
    XCTAssertThrows(intObj[@"intCol"] = @1);
    XCTAssertThrows([intObj setValue:@1 forKey:@"intCol"]);

    [realm addObject:stringObj];

    XCTAssertThrows(stringObj.stringCol = @"a");
    XCTAssertThrows(stringObj[@"stringCol"] = @"a");
    XCTAssertThrows([stringObj setValue:@"a" forKey:@"stringCol"]);
    [realm cancelWriteTransaction];
}

- (void)testDataTypes
{
    RLMRealm *realm = [RLMRealm defaultRealm];
    [realm beginWriteTransaction];
    
    const char bin[4] = { 0, 1, 2, 3 };
    NSData *bin1 = [[NSData alloc] initWithBytes:bin length:sizeof bin / 2];
    NSData *bin2 = [[NSData alloc] initWithBytes:bin length:sizeof bin];
    NSDate *timeNow = [NSDate dateWithTimeIntervalSince1970:1000000];
    NSDate *timeZero = [NSDate dateWithTimeIntervalSince1970:0];

    AllTypesObject *c = [[AllTypesObject alloc] init];
    
    c.boolCol   = NO;
    c.intCol  = 54;
    c.floatCol = 0.7f;
    c.doubleCol = 0.8;
    c.stringCol = @"foo";
    c.binaryCol = bin1;
    c.dateCol = timeZero;
    c.cBoolCol = false;
    c.longCol = 99;
    c.mixedCol = @"string";
    c.objectCol = [[StringObject alloc] init];
    c.objectCol.stringCol = @"c";
    
    [realm addObject:c];

    [AllTypesObject createInRealm:realm withValue:@[@YES, @506, @7.7f, @8.8, @"banach", bin2,
                                                     timeNow, @YES, @(-20), @2, NSNull.null]];
    [realm commitWriteTransaction];
    
    AllTypesObject *row1 = [AllTypesObject allObjects][0];
    AllTypesObject *row2 = [AllTypesObject allObjects][1];

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
    XCTAssertEqual(row1.cBoolCol, false,                @"row1.cBoolCol");
    XCTAssertEqual(row2.cBoolCol, true,                 @"row2.cBoolCol");
    XCTAssertEqual(row1.longCol, 99L,                   @"row1.IntCol");
    XCTAssertEqual(row2.longCol, -20L,                  @"row2.IntCol");
    XCTAssertTrue([row1.objectCol.stringCol isEqual:@"c"], @"row1.objectCol");
    XCTAssertNil(row2.objectCol,                        @"row2.objectCol");

    XCTAssertTrue([row1.mixedCol isEqual:@"string"],    @"row1.mixedCol");
    XCTAssertEqualObjects(row2.mixedCol, @2,            @"row2.mixedCol");

    [realm transactionWithBlock:^{
        row1.boolCol = NO;
        row1.cBoolCol = false;
        row1.boolCol = (BOOL)6;
        row1.cBoolCol = (BOOL)6;
    }];
    XCTAssertEqual(row1.boolCol, true);
    XCTAssertEqual(row1.cBoolCol, true);
}

- (void)testObjectSubclass {
    // test className methods
    XCTAssertEqualObjects(@"StringObject", [StringObject className]);
    XCTAssertEqualObjects(@"StringSubclassObject", [StringSubclassObject className]);

    RLMRealm *realm = [RLMRealm defaultRealm];
    [realm beginWriteTransaction];
    [StringObject createInDefaultRealmWithValue:@[@"string"]];
    StringSubclassObject *obj = [StringSubclassObject createInDefaultRealmWithValue:@[@"string", @"string2"]];

    // ensure property ordering
    XCTAssertEqualObjects([obj.objectSchema.properties[0] name], @"stringCol");
    XCTAssertEqualObjects([obj.objectSchema.properties[1] name], @"stringCol2");

    [realm commitWriteTransaction];

    // ensure creation in proper table
    RLMResults *results = StringSubclassObject.allObjects;
    XCTAssertEqual(1U, results.count);
    XCTAssertEqual(1U, StringObject.allObjects.count);

    // ensure exceptions on when using polymorphism
    [realm beginWriteTransaction];
    StringLinkObject *linkObject = [StringLinkObject createInDefaultRealmWithValue:@[NSNull.null, @[]]];
    XCTAssertThrows(linkObject.stringObjectCol = obj);
    XCTAssertThrows([linkObject.stringObjectArrayCol addObject:obj]);
    [realm commitWriteTransaction];
}

- (void)testDatePrecisionPreservation
{
    DateObject *dateObject = [[DateObject alloc] initWithValue:@[NSDate.distantFuture]];
    RLMRealm *realm = [RLMRealm defaultRealm];
    [realm beginWriteTransaction];
    [realm addObject:dateObject];
    [realm commitWriteTransaction];
    XCTAssertEqualObjects(NSDate.distantFuture, dateObject.dateCol);

    [realm beginWriteTransaction];
    NSDate *date = ({
        NSCalendarUnit units = (NSCalendarUnit)(NSCalendarUnitMonth | NSCalendarUnitYear | NSCalendarUnitDay);
        NSDateComponents *components = [[NSCalendar currentCalendar] components:units fromDate:NSDate.date];
        components.calendar = [NSCalendar currentCalendar];
        components.year += 50000;
        components.date;
    });
    dateObject.dateCol = date;
    [realm commitWriteTransaction];
    XCTAssertEqualObjects(date, dateObject.dateCol);
}

- (void)testDataSizeLimits {
    RLMRealm *realm = [RLMRealm defaultRealm];

    // Allocation must be < 16 MB, with an 8-byte header and the allocation size
    // 8-byte aligned
    static const int maxSize = 0xFFFFFF - 15;

    // Multiple 16 MB blobs should be fine
    void *buffer = malloc(maxSize);
    strcpy((char *)buffer + maxSize - sizeof("hello") - 1, "hello");
    DataObject *obj = [[DataObject alloc] init];
    obj.data1 = obj.data2 = [NSData dataWithBytesNoCopy:buffer length:maxSize freeWhenDone:YES];

    [realm beginWriteTransaction];
    [realm addObject:obj];
    [realm commitWriteTransaction];

    XCTAssertEqual(maxSize, obj.data1.length);
    XCTAssertEqual(maxSize, obj.data2.length);
    XCTAssertTrue(strcmp((const char *)obj.data1.bytes + obj.data1.length - sizeof("hello") - 1, "hello") == 0);
    XCTAssertTrue(strcmp((const char *)obj.data2.bytes + obj.data2.length - sizeof("hello") - 1, "hello") == 0);

    // A blob over 16 MB should throw (and not crash)
    [realm beginWriteTransaction];
    XCTAssertThrows(obj.data1 = [NSData dataWithBytesNoCopy:malloc(maxSize + 1) length:maxSize + 1 freeWhenDone:YES]);
    [realm commitWriteTransaction];
}

- (void)testStringSizeLimits {
    RLMRealm *realm = [RLMRealm defaultRealm];

    // Allocation must be < 16 MB, with an 8-byte header, trailing NUL,  and the
    // allocation size 8-byte aligned
    static const int maxSize = 0xFFFFFF - 16;

    void *buffer = calloc(maxSize, 1);
    strcpy((char *)buffer + maxSize - sizeof("hello") - 1, "hello");
    NSString *str = [[NSString alloc] initWithBytesNoCopy:buffer length:maxSize encoding:NSUTF8StringEncoding freeWhenDone:YES];
    StringObject *obj = [[StringObject alloc] init];
    obj.stringCol = str;

    [realm beginWriteTransaction];
    [realm addObject:obj];
    [realm commitWriteTransaction];

    XCTAssertEqualObjects(str, obj.stringCol);

    // A blob over 16 MB should throw (and not crash)
    [realm beginWriteTransaction];
    XCTAssertThrows(obj.stringCol = [[NSString alloc] initWithBytesNoCopy:calloc(maxSize + 1, 1)
                                                                   length:maxSize + 1
                                                                 encoding:NSUTF8StringEncoding
                                                             freeWhenDone:YES]);
    [realm commitWriteTransaction];
}

- (void)testAddingObjectNotInSchemaThrows {
    RLMRealmConfiguration *configuration = [RLMRealmConfiguration defaultConfiguration];
    configuration.objectClasses = @[StringObject.class];
    RLMRealm *realm = [RLMRealm realmWithConfiguration:configuration error:nil];

    [realm beginWriteTransaction];
    RLMAssertThrowsWithReasonMatching([realm addObject:[[IntObject alloc] initWithValue:@[@1]]], @"Object type 'IntObject' is not persisted in the Realm.*custom `objectClasses`");
    RLMAssertThrowsWithReasonMatching([IntObject createInRealm:realm withValue:@[@1]], @"Object type 'IntObject' is not persisted in the Realm.*custom `objectClasses`");
    XCTAssertNoThrow([realm addObject:[[StringObject alloc] initWithValue:@[@"A"]]]);
    XCTAssertNoThrow([StringObject createInRealm:realm withValue:@[@"A"]]);
    [realm cancelWriteTransaction];
}

- (void)testNSNumberProperties {
    NumberObject *obj = [NumberObject new];
    obj.intObj = @20;
    obj.floatObj = @0.7f;
    obj.doubleObj = @33.3;
    obj.boolObj = @YES;
    XCTAssertEqualObjects(@20, obj.intObj);
    XCTAssertEqualObjects(@0.7f, obj.floatObj);
    XCTAssertEqualObjects(@33.3, obj.doubleObj);
    XCTAssertEqualObjects(@YES, obj.boolObj);
    RLMRealm *realm = [RLMRealm defaultRealm];
    [realm beginWriteTransaction];
    [realm addObject:obj];
    [realm commitWriteTransaction];
    XCTAssertEqualObjects(@20, obj.intObj);
    XCTAssertEqualObjects(@0.7f, obj.floatObj);
    XCTAssertEqualObjects(@33.3, obj.doubleObj);
    XCTAssertEqualObjects(@YES, obj.boolObj);
}

- (void)testOptionalStringProperties {
    RLMRealm *realm = [RLMRealm defaultRealm];
    StringObject *so = [[StringObject alloc] init];

    XCTAssertNil(so.stringCol);
    XCTAssertNil([so valueForKey:@"stringCol"]);
    XCTAssertNil(so[@"stringCol"]);

    so.stringCol = @"a";
    XCTAssertEqualObjects(so.stringCol, @"a");
    XCTAssertEqualObjects([so valueForKey:@"stringCol"], @"a");
    XCTAssertEqualObjects(so[@"stringCol"], @"a");

    [so setValue:nil forKey:@"stringCol"];
    XCTAssertNil(so.stringCol);
    XCTAssertNil([so valueForKey:@"stringCol"]);
    XCTAssertNil(so[@"stringCol"]);

    [realm transactionWithBlock:^{
        [realm addObject:so];
        XCTAssertNil(so.stringCol);
        XCTAssertNil([so valueForKey:@"stringCol"]);
        XCTAssertNil(so[@"stringCol"]);
    }];

    so = [StringObject allObjectsInRealm:realm].firstObject;

    XCTAssertNil(so.stringCol);
    XCTAssertNil([so valueForKey:@"stringCol"]);
    XCTAssertNil(so[@"stringCol"]);

    [realm transactionWithBlock:^{
        so.stringCol = @"b";
    }];
    XCTAssertEqualObjects(so.stringCol, @"b");
    XCTAssertEqualObjects([so valueForKey:@"stringCol"], @"b");
    XCTAssertEqualObjects(so[@"stringCol"], @"b");

    [realm transactionWithBlock:^{
        so.stringCol = @"";
    }];
    XCTAssertEqualObjects(so.stringCol, @"");
    XCTAssertEqualObjects([so valueForKey:@"stringCol"], @"");
    XCTAssertEqualObjects(so[@"stringCol"], @"");
}

- (void)testOptionalBinaryProperties {
    RLMRealm *realm = [RLMRealm defaultRealm];
    BinaryObject *bo = [[BinaryObject alloc] init];

    XCTAssertNil(bo.binaryCol);
    XCTAssertNil([bo valueForKey:@"binaryCol"]);
    XCTAssertNil(bo[@"binaryCol"]);

    NSData *aData = [@"a" dataUsingEncoding:NSUTF8StringEncoding];
    bo.binaryCol = aData;
    XCTAssertEqualObjects(bo.binaryCol, aData);
    XCTAssertEqualObjects([bo valueForKey:@"binaryCol"], aData);
    XCTAssertEqualObjects(bo[@"binaryCol"], aData);

    [bo setValue:nil forKey:@"binaryCol"];
    XCTAssertNil(bo.binaryCol);
    XCTAssertNil([bo valueForKey:@"binaryCol"]);
    XCTAssertNil(bo[@"binaryCol"]);

    [realm transactionWithBlock:^{
        [realm addObject:bo];
        XCTAssertNil(bo.binaryCol);
        XCTAssertNil([bo valueForKey:@"binaryCol"]);
        XCTAssertNil(bo[@"binaryCol"]);
    }];

    bo = [BinaryObject allObjectsInRealm:realm].firstObject;

    XCTAssertNil(bo.binaryCol);
    XCTAssertNil([bo valueForKey:@"binaryCol"]);
    XCTAssertNil(bo[@"binaryCol"]);

    NSData *bData = [@"b" dataUsingEncoding:NSUTF8StringEncoding];
    [realm transactionWithBlock:^{
        bo.binaryCol = bData;
    }];
    XCTAssertEqualObjects(bo.binaryCol, bData);
    XCTAssertEqualObjects([bo valueForKey:@"binaryCol"], bData);
    XCTAssertEqualObjects(bo[@"binaryCol"], bData);

    NSData *emptyData = [NSData data];
    [realm transactionWithBlock:^{
        bo.binaryCol = emptyData;
    }];
    XCTAssertEqualObjects(bo.binaryCol, emptyData);
    XCTAssertEqualObjects([bo valueForKey:@"binaryCol"], emptyData);
    XCTAssertEqualObjects(bo[@"binaryCol"], emptyData);
}

- (void)testOptionalNumberProperties {
    void (^assertNullProperties)(NumberObject *) = ^(NumberObject *no){
        XCTAssertNil(no.intObj);
        XCTAssertNil(no.doubleObj);
        XCTAssertNil(no.floatObj);
        XCTAssertNil(no.boolObj);

        XCTAssertNil([no valueForKey:@"intObj"]);
        XCTAssertNil([no valueForKey:@"doubleObj"]);
        XCTAssertNil([no valueForKey:@"floatObj"]);
        XCTAssertNil([no valueForKey:@"boolObj"]);

        XCTAssertNil(no[@"intObj"]);
        XCTAssertNil(no[@"doubleObj"]);
        XCTAssertNil(no[@"floatObj"]);
        XCTAssertNil(no[@"boolObj"]);
    };

    void (^assertNonNullProperties)(NumberObject *) = ^(NumberObject *no){
        XCTAssertEqualObjects(no.intObj, @1);
        XCTAssertEqualObjects(no.doubleObj, @1.1);
        XCTAssertEqualObjects(no.floatObj, @2.2f);
        XCTAssertEqualObjects(no.boolObj, @YES);

        XCTAssertEqualObjects([no valueForKey:@"intObj"], @1);
        XCTAssertEqualObjects([no valueForKey:@"doubleObj"], @1.1);
        XCTAssertEqualObjects([no valueForKey:@"floatObj"], @2.2f);
        XCTAssertEqualObjects([no valueForKey:@"boolObj"], @YES);

        XCTAssertEqualObjects(no[@"intObj"], @1);
        XCTAssertEqualObjects(no[@"doubleObj"], @1.1);
        XCTAssertEqualObjects(no[@"floatObj"], @2.2f);
        XCTAssertEqualObjects(no[@"boolObj"], @YES);
    };

    RLMRealm *realm = [RLMRealm defaultRealm];
    NumberObject *no = [[NumberObject alloc] init];

    assertNullProperties(no);

    no.intObj = @1;
    no.doubleObj = @1.1;
    no.floatObj = @2.2f;
    no.boolObj = @YES;

    assertNonNullProperties(no);

    no.intObj = nil;
    no.doubleObj = nil;
    no.floatObj = nil;
    no.boolObj = nil;

    assertNullProperties(no);

    no[@"intObj"] = @1;
    no[@"doubleObj"] = @1.1;
    no[@"floatObj"] = @2.2f;
    no[@"boolObj"] = @YES;

    assertNonNullProperties(no);

    no.intObj = nil;
    no.doubleObj = nil;
    no.floatObj = nil;
    no.boolObj = nil;

    [realm transactionWithBlock:^{
        [realm addObject:no];
        assertNullProperties(no);
    }];

    no = [NumberObject allObjectsInRealm:realm].firstObject;
    assertNullProperties(no);

    [realm transactionWithBlock:^{
        no.intObj = @1;
        no.doubleObj = @1.1;
        no.floatObj = @2.2f;
        no.boolObj = @YES;
    }];
    assertNonNullProperties(no);
}

- (void)testSettingNonOptionalPropertiesToNil {
    RequiredPropertiesObject *ro = [[RequiredPropertiesObject alloc] init];

    ro.stringCol = nil;
    ro.binaryCol = nil;

    XCTAssertNil(ro.stringCol);
    XCTAssertNil(ro.binaryCol);

    ro.stringCol = @"a";
    ro.binaryCol = [@"a" dataUsingEncoding:NSUTF8StringEncoding];

    RLMRealm *realm = [RLMRealm defaultRealm];
    [realm beginWriteTransaction];
    [realm addObject:ro];
    RLMAssertThrowsWithReasonMatching(ro.stringCol = nil, @"null into non-nullable column");
    RLMAssertThrowsWithReasonMatching(ro.binaryCol = nil, @"null into non-nullable column");
    [realm cancelWriteTransaction];
}

- (void)testObjectSubclassAddedAtRuntime {
    Class objectClass = objc_allocateClassPair(RLMObject.class, "RuntimeGeneratedObject", 0);
    objc_property_attribute_t objectColAttrs[] = {
        { "T", "@\"RuntimeGeneratedObject\"" },
    };
    class_addIvar(objectClass, "objectCol", sizeof(id), alignof(id), "@\"RuntimeGeneratedObject\"");
    class_addProperty(objectClass, "objectCol", objectColAttrs, sizeof(objectColAttrs) / sizeof(objc_property_attribute_t));
    objc_property_attribute_t intColAttrs[] = {
        { "T", "i" },
    };
    class_addIvar(objectClass, "intCol", sizeof(int), alignof(int), "i");
    class_addProperty(objectClass, "intCol", intColAttrs, sizeof(intColAttrs) / sizeof(objc_property_attribute_t));
    objc_registerClassPair(objectClass);
    XCTAssertEqualObjects([objectClass className], @"RuntimeGeneratedObject");

    RLMRealmConfiguration *configuration = [RLMRealmConfiguration defaultConfiguration];
    configuration.objectClasses = @[objectClass];
    XCTAssertEqualObjects([objectClass className], @"RuntimeGeneratedObject");

    RLMRealm *realm = [RLMRealm realmWithConfiguration:configuration error:nil];
    [realm beginWriteTransaction];
    id object = [objectClass createInRealm:realm withValue:@{@"objectCol": [[objectClass alloc] init], @"intCol": @17}];
    RLMObjectSchema *schema = [object objectSchema];
    XCTAssertNotNil(schema[@"objectCol"]);
    XCTAssertNotNil(schema[@"intCol"]);
    XCTAssert([[object objectCol] isKindOfClass:objectClass]);
    XCTAssertEqual([object intCol], 17);
    [realm commitWriteTransaction];
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
    DateObject *dateObject = [[DateObject alloc] init];
    XCTAssertNoThrow(([realm addObject:dateObject]), @"Adding object with no values specified for NSObject properties shouldn't throw exception if NSObject property is nil");

    // Test #2
    dateObject = [[DateObject alloc] init];
    dateObject.dateCol = [NSDate date];
    XCTAssertNoThrow(([realm addObject:dateObject]), @"Having values in all NSObject properties should not throw exception when being added to realm");
    
    // Test #3
    IntObject *intObj = [[IntObject alloc] init];
    XCTAssertNoThrow(([realm addObject:intObj]), @"Having no NSObject properties should not throw exception when being added to realm");

    // Test #4
    StringObject *stringObject = [[StringObject alloc] init];
    XCTAssertNoThrow([realm addObject:stringObject], @"Having a nil value for a optional NSObject property should not throw");

    [realm commitWriteTransaction];
}

- (NSDictionary *)defaultValuesDictionary {
    return @{@"intCol"    : @98,
             @"floatCol"  : @231.0f,
             @"doubleCol" : @123732.9231,
             @"boolCol"   : @NO,
             @"dateCol"   : [NSDate dateWithTimeIntervalSince1970:454321],
             @"stringCol" : @"Westeros",
             @"binaryCol" : [@"inputData" dataUsingEncoding:NSUTF8StringEncoding],
             @"mixedCol"  : @"Tyrion"};
}

- (void)testDefaultValuesFromNoValuePresent
{
    RLMRealm *realm = [RLMRealm defaultRealm];

    [realm beginWriteTransaction];

    NSDictionary *inputValues = [self defaultValuesDictionary];
    NSArray *keys = [inputValues allKeys]; // To ensure iteration order is stable
    for (NSString *key in keys) {
        NSMutableDictionary *dict = [inputValues mutableCopy];
        [dict removeObjectForKey:key];
        [DefaultObject createInRealm:realm withValue:dict];
    }

    [realm commitWriteTransaction];

    // Test allObject for DefaultObject
    NSDictionary *defaultValues = [DefaultObject defaultPropertyValues];
    RLMResults *allObjects = [DefaultObject allObjectsInRealm:realm];
    for (NSUInteger i = 0; i < keys.count; ++i) {
        DefaultObject *object = allObjects[i];
        for (NSUInteger j = 0; j < keys.count; ++j) {
            NSString *key = keys[j];
            if (i == j) {
                XCTAssertEqualObjects(object[key], defaultValues[key]);
            }
            else {
                XCTAssertEqualObjects(object[key], inputValues[key]);
            }
        }
    }
}

- (void)testDefaultValuesFromNSNull
{
    RLMRealm *realm = [RLMRealm defaultRealm];

    NSDictionary *defaultValues = [DefaultObject defaultPropertyValues];
    NSDictionary *inputValues = [self defaultValuesDictionary];
    NSArray *keys = [inputValues allKeys]; // To ensure iteration order is stable
    for (NSString *key in keys) {
        NSMutableDictionary *dict = [inputValues mutableCopy];
        dict[key] = NSNull.null;
        RLMProperty *prop = realm.schema[@"DefaultObject"][key];
        if (prop.optional) {
            [realm beginWriteTransaction];
            [DefaultObject createInRealm:realm withValue:dict];
            [realm commitWriteTransaction];

            DefaultObject *object = DefaultObject.allObjects.lastObject;
            for (NSUInteger j = 0; j < keys.count; ++j) {
                NSString *key2 = keys[j];
                if ([key isEqualToString:key2]) {
                    XCTAssertEqualObjects(object[key2], prop.optional ? nil : defaultValues[key2]);
                }
                else {
                    XCTAssertEqualObjects(object[key2], inputValues[key2]);
                }
            }
        }
        else {
            [realm beginWriteTransaction];
            XCTAssertThrows([DefaultObject createInRealm:realm withValue:dict]);
            [realm commitWriteTransaction];
        }
    }
}

- (void)testDefaultNSNumberPropertyValues {
    void (^assertDefaults)(NumberObject *) = ^(NumberObject *no) {
        XCTAssertEqualObjects(no.intObj, @1);
        XCTAssertEqualObjects(no.floatObj, @2.2f);
        XCTAssertEqualObjects(no.doubleObj, @3.3);
        XCTAssertEqualObjects(no.boolObj, @NO);
    };

    assertDefaults([[NumberDefaultsObject alloc] init]);

    RLMRealm *realm = [RLMRealm defaultRealm];
    [realm beginWriteTransaction];
    assertDefaults([NumberDefaultsObject createInRealm:realm withValue:@{}]);
    [realm cancelWriteTransaction];
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

- (void)testReadOnlyPropertiesImplicitlyIgnored
{
    RLMRealm *realm = [RLMRealm defaultRealm];

    [realm beginWriteTransaction];
    ReadOnlyPropertyObject *obj = [[ReadOnlyPropertyObject alloc] init];
    obj.readOnlyPropertyMadeReadWriteInClassExtension = 5;
    [realm addObject:obj];
    [realm commitWriteTransaction];

    obj = [[ReadOnlyPropertyObject allObjectsInRealm:realm] firstObject];
    XCTAssertEqual(5, obj.readOnlyPropertyMadeReadWriteInClassExtension);
}

- (void)testCreateInRealmValidationForDictionary
{
    RLMRealm *realm = [RLMRealm defaultRealm];
    
    const char bin[4] = { 0, 1, 2, 3 };
    NSData *bin1 = [[NSData alloc] initWithBytes:bin length:sizeof bin / 2];
    NSDate *timeNow = [NSDate dateWithTimeIntervalSince1970:1000000];
    NSDictionary * const dictValidAllTypes = @{@"boolCol"   : @NO,
                                               @"intCol"    : @54,
                                               @"floatCol"  : @0.7f,
                                               @"doubleCol" : @0.8,
                                               @"stringCol" : @"foo",
                                               @"binaryCol" : bin1,
                                               @"dateCol"   : timeNow,
                                               @"cBoolCol"  : @NO,
                                               @"longCol"   : @(99),
                                               @"mixedCol"  : @"mixed",
                                               @"objectCol" : NSNull.null};
    
    [realm beginWriteTransaction];
    
    // Test NSDictonary
    XCTAssertNoThrow(([AllTypesObject createInRealm:realm withValue:dictValidAllTypes]), @"Creating object with valid value types should not throw exception");
    
    for (NSString *keyToInvalidate in dictValidAllTypes.allKeys) {
        NSMutableDictionary *invalidInput = [dictValidAllTypes mutableCopy];
        id obj = @"invalid";
        if ([keyToInvalidate isEqualToString:@"stringCol"]) {
            obj = @1;
        }
        
        invalidInput[keyToInvalidate] = obj;
        
        // Ignoring test for mixedCol since only NSObjects can go in NSDictionary
        if (![keyToInvalidate isEqualToString:@"mixedCol"]) {
            XCTAssertThrows(([AllTypesObject createInRealm:realm withValue:invalidInput]), @"Creating object with invalid value types should throw exception");
        }
    }
    
    
    [realm commitWriteTransaction];
}

- (void)testCreateInRealmValidationForArray
{
    RLMRealm *realm = [RLMRealm defaultRealm];
    
    // add test/link object to realm
    [realm beginWriteTransaction];
    StringObject *to = [StringObject createInRealm:realm withValue:@[@"c"]];
    [realm commitWriteTransaction];
    
    const char bin[4] = { 0, 1, 2, 3 };
    NSData *bin1 = [[NSData alloc] initWithBytes:bin length:sizeof bin / 2];
    NSDate *timeNow = [NSDate dateWithTimeIntervalSince1970:1000000];
    NSArray *const arrayValidAllTypes = @[@NO, @54, @0.7f, @0.8, @"foo", bin1, timeNow, @NO, @(99), @"mixed", to];
    
    [realm beginWriteTransaction];
    
    // Test NSArray
    XCTAssertNoThrow(([AllTypesObject createInRealm:realm withValue:arrayValidAllTypes]), @"Creating object with valid value types should not throw exception");
    
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
            XCTAssertThrows(([AllTypesObject createInRealm:realm withValue:invalidInput]), @"Creating object with invalid value types should throw exception");
        }
    }
    
    [realm commitWriteTransaction];
}

-(void)testCreateInRealmWithObjectLiterals {
    RLMRealm *realm = [RLMRealm defaultRealm];

    // create with array literals
    [realm beginWriteTransaction];

    NSArray *array = @[@"company", @[@[@"Alex", @29, @YES]]];
    [CompanyObject createInDefaultRealmWithValue:array];

    NSDictionary *dict = @{@"name": @"dictionaryCompany", @"employees": @[@{@"name": @"Bjarne", @"age": @32, @"hired": @NO}]};
    [CompanyObject createInDefaultRealmWithValue:dict];

    NSArray *invalidArray = @[@"company", @[@[@"Alex", @29, @2]]];
    XCTAssertThrows([CompanyObject createInDefaultRealmWithValue:invalidArray], @"Invalid sub-literal should throw");

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

    [OwnerObject createInDefaultRealmWithValue:@[@"Brian", @{@"dogName": @"Brido", @"age": @0}]];
    [OwnerObject createInDefaultRealmWithValue:@[@"JP", @[@"PJ", @0]]];

    [realm commitWriteTransaction];

    // verify object literals
    OwnerObject *brian = OwnerObject.allObjects[0], *jp = OwnerObject.allObjects[1];
    XCTAssertEqualObjects(brian.dog.dogName, @"Brido");
    XCTAssertEqualObjects(jp.dog.dogName, @"PJ");

    // verify with kvc objects
    // create DogExtraObject
    DogExtraObject *dogExt = [[DogExtraObject alloc] initWithValue:@[@"Fido", @12, @"Poodle"]];

    [realm beginWriteTransaction];

    // create second object with DogExtraObject object
    DogObject *dog = [DogObject createInDefaultRealmWithValue:dogExt];

    // missing properties
    XCTAssertThrows([DogExtraObject createInDefaultRealmWithValue:dog], @"Initialization with missing values should throw");

    // nested objects should work
    XCTAssertNoThrow([OwnerObject createInDefaultRealmWithValue:(@[@"Alex", dogExt])], @"Should not throw");

    [realm commitWriteTransaction];
}

- (void)testCreateInRealmReusesExistingObjects {
    RLMRealm *realm = [RLMRealm defaultRealm];
    [realm beginWriteTransaction];

    DogObject *dog = [DogObject createInDefaultRealmWithValue:@[@"Fido", @5]];
    OwnerObject *owner = [OwnerObject createInDefaultRealmWithValue:@[@"name", dog]];
    XCTAssertTrue([owner.dog isEqualToObject:dog]);
    XCTAssertEqual(1U, DogObject.allObjects.count);

    DogArrayObject *dogArray = [DogArrayObject createInDefaultRealmWithValue:@[@[dog]]];
    XCTAssertTrue([dogArray.dogs[0] isEqualToObject:dog]);
    XCTAssertEqual(1U, DogObject.allObjects.count);

    [realm commitWriteTransaction];
}

- (void)testCreateInRealmReusesExistingNestedObjectsByPrimaryKey {
    RLMRealm *realm = [RLMRealm defaultRealm];

    [realm beginWriteTransaction];
    PrimaryEmployeeObject *eo = [PrimaryEmployeeObject createInRealm:realm withValue:@[@"Samuel", @19, @NO]];
    PrimaryCompanyObject *co = [PrimaryCompanyObject createInRealm:realm withValue:@[@"Realm", @[eo], eo, @[eo]]];
    [realm commitWriteTransaction];

    [realm beginWriteTransaction];
    [PrimaryCompanyObject createOrUpdateInRealm:realm withValue:@{
                                                                   @"name" : @"Realm",
                                                                   @"intern" : @{@"name":@"Samuel", @"hired":@YES},
                                                                   }];
    [realm commitWriteTransaction];

    XCTAssertEqual(1U, co.employees.count);
    XCTAssertEqual(1U, [PrimaryEmployeeObject allObjectsInRealm:realm].count);
    XCTAssertEqualObjects(@"Samuel", eo.name);
    XCTAssertEqual(YES, eo.hired);
    XCTAssertEqual(19, eo.age);

    [realm beginWriteTransaction];
    [PrimaryCompanyObject createOrUpdateInRealm:realm withValue:@{
                                                                   @"name" : @"Realm",
                                                                   @"employees": @[@{@"name":@"Samuel", @"hired":@NO}],
                                                                   @"intern" : @{@"name":@"Samuel", @"age":@20},
                                                                   }];
    [realm commitWriteTransaction];

    XCTAssertEqual(1U, co.employees.count);
    XCTAssertEqual(1U, [PrimaryEmployeeObject allObjectsInRealm:realm].count);
    XCTAssertEqualObjects(@"Samuel", eo.name);
    XCTAssertEqual(NO, eo.hired);
    XCTAssertEqual(20, eo.age);

    [realm beginWriteTransaction];
    [PrimaryCompanyObject createOrUpdateInRealm:realm withValue:@{@"name" : @"Realm",
                                                                  @"wrappedIntern" : @[eo]}];
    [realm commitWriteTransaction];
    XCTAssertEqual(1U, [[PrimaryEmployeeObject allObjectsInRealm:realm] count]);
}

- (void)testCreateInRealmCopiesFromOtherRealm {
    RLMRealm *realm1 = [RLMRealm defaultRealm];
    RLMRealm *realm2 = [self realmWithTestPath];
    [realm1 beginWriteTransaction];
    [realm2 beginWriteTransaction];

    DogObject *dog = [DogObject createInDefaultRealmWithValue:@[@"Fido", @5]];
    OwnerObject *owner = [OwnerObject createInRealm:realm2 withValue:@[@"name", dog]];
    XCTAssertFalse([owner.dog isEqualToObject:dog]);
    XCTAssertEqual(1U, DogObject.allObjects.count);
    XCTAssertEqual(1U, [DogObject allObjectsInRealm:realm2].count);

    DogArrayObject *dogArray = [DogArrayObject createInRealm:realm2 withValue:@[@[dog]]];
    XCTAssertFalse([dogArray.dogs[0] isEqualToObject:dog]);
    XCTAssertEqual(1U, DogObject.allObjects.count);
    XCTAssertEqual(2U, [DogObject allObjectsInRealm:realm2].count);

    [realm1 commitWriteTransaction];
    [realm2 commitWriteTransaction];
}

- (void)testCreateInRealmWithOtherObjects {
    RLMRealm *realm = [RLMRealm defaultRealm];
    [realm beginWriteTransaction];
    DateObjectNoThrow *object = [DateObjectNoThrow createInDefaultRealmWithValue:@[NSDate.date, NSDate.date]];

    // create subclass with instance of base class with/without default objects
    XCTAssertNoThrow([DateSubclassObject createInDefaultRealmWithValue:object]);
    XCTAssertNoThrow([DateObjectNoThrow createInDefaultRealmWithValue:object]);

    // create using non-realm object with custom getter
    SubclassDateObject *obj = [SubclassDateObject new];
    obj.dateCol = [NSDate dateWithTimeIntervalSinceReferenceDate:1000];
    obj.date2 = [NSDate dateWithTimeIntervalSinceReferenceDate:2000];
    obj.date3 = [NSDate dateWithTimeIntervalSinceReferenceDate:3000];
    [DateDefaultsObject createInDefaultRealmWithValue:obj];

    XCTAssertEqual(2U, DateObjectNoThrow.allObjects.count);
    [realm commitWriteTransaction];
}

- (void)testCreateInRealmWithMissingValue
{
    RLMRealm *realm = [RLMRealm defaultRealm];
    
    [realm beginWriteTransaction];
    
    // This exception only gets thrown when there is no default vaule and it is for an NSObject property
    XCTAssertThrows(([AggregateObject createInRealm:realm withValue:@{@"boolCol" : @YES}]), @"Missing values in NSDictionary should throw default value exception");
    EmployeeObject *eo = nil;
    eo = [EmployeeObject createInRealm:realm withValue:@{@"age":@20, @"hired": @YES}];
    XCTAssertNil(eo.name);
    eo = [EmployeeObject createInRealm:realm withValue:@{@"name":NSNull.null, @"age":@20, @"hired": @YES}];
    XCTAssertNil(eo.name);
    
    // This exception gets thrown when count of array does not match with object schema
    XCTAssertThrows(([EmployeeObject createInRealm:realm withValue:@[@27, @YES]]), @"Missing values in NSDictionary should throw default value exception");
    
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
    void (^descriptionAsserts)(NSString *) = ^(NSString *description) {
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

    soInit = [[EmployeeObject alloc] init];
    soInit.age = 20;
    XCTAssert([soInit.description rangeOfString:@"(null)"].location != NSNotFound);
}

- (void)testObjectCycleDescription
{
    CycleObject *obj = [[CycleObject alloc] init];
    [RLMRealm.defaultRealm transactionWithBlock:^{
        [RLMRealm.defaultRealm addObject:obj];
        [obj.objects addObject:obj];
    }];
    XCTAssertNoThrow(obj.description);
}

- (void)testDataObjectDescription {
    RLMRealm *realm = [RLMRealm defaultRealm];

    [realm beginWriteTransaction];
    char longData[200];
    [DataObject createInRealm:realm withValue:@[[NSData dataWithBytes:&longData length:200], [NSData dataWithBytes:&longData length:2]]];
    [realm commitWriteTransaction];

    DataObject *obj = [DataObject allObjectsInRealm:realm].firstObject;
    XCTAssertTrue([obj.description rangeOfString:@"200 total bytes"].location != NSNotFound);
    XCTAssertTrue([obj.description rangeOfString:@"2 total bytes"].location != NSNotFound);
}

- (void)testDeletedObjectDescription
{
    RLMRealm *realm = [RLMRealm defaultRealm];

    [realm beginWriteTransaction];
    EmployeeObject *obj = [EmployeeObject createInRealm:realm withValue:@[@"Peter", @30, @YES]];
    [realm deleteObject:obj];
    [realm commitWriteTransaction];

    XCTAssertNoThrow(obj.description);
}

#pragma mark - Indexing Tests

- (void)testIndex
{
    RLMSchema *schema = [RLMRealm defaultRealm].schema;

    RLMProperty *stringProperty = schema[IndexedObject.className][@"stringCol"];
    XCTAssertTrue(stringProperty.indexed, @"indexed property should have an index");

    RLMProperty *integerProperty = schema[IndexedObject.className][@"integerCol"];
    XCTAssertTrue(integerProperty.indexed, @"indexed property should have an index");

    RLMProperty *intProperty = schema[IndexedObject.className][@"intCol"];
    XCTAssertTrue(intProperty.indexed, @"indexed property should have an index");

    RLMProperty *longProperty = schema[IndexedObject.className][@"longCol"];
    XCTAssertTrue(longProperty.indexed, @"indexed property should have an index");

    RLMProperty *longlongProperty = schema[IndexedObject.className][@"longlongCol"];
    XCTAssertTrue(longlongProperty.indexed, @"indexed property should have an index");

    RLMProperty *boolProperty = schema[IndexedObject.className][@"boolCol"];
    XCTAssertTrue(boolProperty.indexed, @"indexed property should have an index");

    RLMProperty *dateProperty = schema[IndexedObject.className][@"dateCol"];
    XCTAssertTrue(dateProperty.indexed, @"indexed property should have an index");

    RLMProperty *optionalIntProperty = schema[IndexedObject.className][@"optionalIntCol"];
    XCTAssertTrue(optionalIntProperty.indexed, @"indexed property should have an index");

    RLMProperty *optionalBoolProperty = schema[IndexedObject.className][@"optionalBoolCol"];
    XCTAssertTrue(optionalBoolProperty.indexed, @"indexed property should have an index");
    
    RLMProperty *floatProperty = schema[IndexedObject.className][@"floatCol"];
    XCTAssertFalse(floatProperty.indexed, @"non-indexed property shouldn't have an index");

    RLMProperty *doubleProperty = schema[IndexedObject.className][@"doubleCol"];
    XCTAssertFalse(doubleProperty.indexed, @"non-indexed property shouldn't have an index");

    RLMProperty *dataProperty = schema[IndexedObject.className][@"dataCol"];
    XCTAssertFalse(dataProperty.indexed, @"non-indexed property shouldn't have an index");

    RLMProperty *optionalFloatProperty = schema[IndexedObject.className][@"optionalFloatCol"];
    XCTAssertFalse(optionalFloatProperty.indexed, @"non-indexed property shouldn't have an index");

    RLMProperty *optionalDoubleProperty = schema[IndexedObject.className][@"optionalDoubleCol"];
    XCTAssertFalse(optionalDoubleProperty.indexed, @"non-indexed property shouldn't have an index");
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

    RLMRealm *realm = [RLMRealm defaultRealm];
    RLMRealm *otherRealm = [self realmWithTestPath];

    XCTAssertFalse([obj isEqual:[NSObject new]], @"Comparing an RLMObject to a non-RLMObject should be false.");
    XCTAssertFalse([obj isEqualToObject:(RLMObject *)[NSObject new]], @"Comparing an RLMObject to a non-RLMObject should be false.");
    XCTAssertTrue([obj isEqual:obj], @"Same instance.");
    XCTAssertTrue([obj isEqualToObject:obj], @"Same instance.");
    XCTAssertFalse([obj isEqualToObject:otherObj], @"Comparison outside of realm.");

    [realm beginWriteTransaction];
    [realm addObject:obj];
    [realm commitWriteTransaction];

    XCTAssertFalse([obj isEqualToObject:otherObj], @"One in realm, the other is not.");
    XCTAssertTrue([obj isEqualToObject:[IntObject allObjects][0]], @"Same table and index.");

    [otherRealm beginWriteTransaction];
    [otherRealm addObject:otherObj];
    [otherRealm commitWriteTransaction];

    XCTAssertFalse([obj isEqualToObject:otherObj], @"Different realms.");

    [realm beginWriteTransaction];
    [realm addObject:[[IntObject alloc] init]];
    [realm addObject:[[BoolObject alloc] init]];
    [realm commitWriteTransaction];

    XCTAssertFalse([obj isEqualToObject:[IntObject allObjects][1]], @"Same table, different index.");
    XCTAssertFalse([obj isEqualToObject:[BoolObject allObjects][0]], @"Different tables.");
}

- (void)testCrossThreadAccess
{
    IntObject *obj = [[IntObject alloc] init];

    // Standalone can be accessed from other threads
    [self dispatchAsyncAndWait:^{ XCTAssertNoThrow(obj.intCol = 5); }];

    [RLMRealm.defaultRealm beginWriteTransaction];
    [RLMRealm.defaultRealm addObject:obj];
    [RLMRealm.defaultRealm commitWriteTransaction];

    [self dispatchAsyncAndWait:^{ XCTAssertThrows(obj.intCol); }];
}

- (void)testIsDeleted {
    StringObject *obj1 = [[StringObject alloc] initWithValue:@[@"a"]];
    XCTAssertEqual(obj1.invalidated, NO);

    RLMRealm *realm = [self realmWithTestPath];
    [realm beginWriteTransaction];
    [realm addObject:obj1];
    StringObject *obj2 = [StringObject createInRealm:realm withValue:@[@"b"]];

    XCTAssertEqual([obj1 isInvalidated], NO);
    XCTAssertEqual(obj2.invalidated, NO);

    [realm commitWriteTransaction];

    // delete
    [realm beginWriteTransaction];
    // Delete directly
    [realm deleteObject:obj1];
    // Delete as result of query since then obj2's realm could point to a different instance
    [realm deleteObject:[[StringObject allObjectsInRealm:realm] firstObject]];

    XCTAssertEqual(obj1.invalidated, YES);
    XCTAssertEqual(obj2.invalidated, YES);

    XCTAssertThrows([realm addObject:obj1], @"Adding deleted object should throw");

    NSArray *propObject = @[@"", @[obj2], @[]];
    XCTAssertThrows([ArrayPropertyObject createInRealm:realm withValue:propObject], @"Adding deleted object as a link should throw");

    [realm commitWriteTransaction];

    XCTAssertEqual(obj1.invalidated, YES);
    XCTAssertNil(obj1.realm, @"Realm should be nil after deletion");
}

- (void)testPrimaryKey {
    [[RLMRealm defaultRealm] beginWriteTransaction];

    [PrimaryStringObject createInDefaultRealmWithValue:(@[@"string", @1])];
    PrimaryStringObject *obj = [PrimaryStringObject createInDefaultRealmWithValue:(@[@"string2", @1])];
    XCTAssertThrows([PrimaryStringObject createInDefaultRealmWithValue:(@[@"string", @1])], @"Duplicate primary key should throw");
    XCTAssertThrows(obj.stringCol = @"string2", @"Setting primary key should throw");

    [PrimaryIntObject createInDefaultRealmWithValue:(@[@1])];
    PrimaryIntObject *obj1 = [PrimaryIntObject createInDefaultRealmWithValue:(@{@"intCol": @2})];
    XCTAssertThrows([PrimaryIntObject createInDefaultRealmWithValue:(@[@1])], @"Duplicate primary key should throw");
    XCTAssertThrows(obj1.intCol = 2, @"Setting primary key should throw");

    [PrimaryInt64Object createInDefaultRealmWithValue:(@[@(1LL << 40)])];
    PrimaryInt64Object *obj2 = [PrimaryInt64Object createInDefaultRealmWithValue:(@[@(1LL << 41)])];
    XCTAssertThrows([PrimaryInt64Object createInDefaultRealmWithValue:(@[@(1LL << 40)])], @"Duplicate primary key should throw");
    XCTAssertThrows(obj2.int64Col = 1LL << 41, @"Setting primary key should throw");

    [PrimaryNullableIntObject createInDefaultRealmWithValue:@[@1]];
    PrimaryNullableIntObject *obj3 = [PrimaryNullableIntObject createInDefaultRealmWithValue:(@{@"optIntCol": @2})];
    XCTAssertThrows(obj3.optIntCol = @2, @"Setting primary key should throw");
    XCTAssertThrows(obj3.optIntCol = nil, @"Setting primary key should throw");
    PrimaryNullableIntObject *obj4 = [PrimaryNullableIntObject createInDefaultRealmWithValue:@[NSNull.null]];
    XCTAssertThrows(obj4.optIntCol = @2, @"Setting primary key should throw");
    XCTAssertThrows(obj4.optIntCol = nil, @"Setting primary key should throw");
    XCTAssertThrows([PrimaryNullableIntObject createInDefaultRealmWithValue:(@[@1])], @"Duplicate primary key should throw");
    XCTAssertThrows([PrimaryNullableIntObject createInDefaultRealmWithValue:(@[NSNull.null])], @"Duplicate primary key should throw");

    [[RLMRealm defaultRealm] commitWriteTransaction];
}

- (void)testCreateOrUpdate {
    RLMRealm *realm = [RLMRealm defaultRealm];
    [realm beginWriteTransaction];

    [PrimaryStringObject createOrUpdateInDefaultRealmWithValue:@[@"string", @1]];
    RLMResults *objects = [PrimaryStringObject allObjects];
    XCTAssertEqual([objects count], 1U, @"Should have 1 object");
    XCTAssertEqual([(PrimaryStringObject *)objects[0] intCol], 1, @"Value should be 1");

    [PrimaryStringObject createOrUpdateInRealm:realm withValue:@{@"stringCol": @"string2", @"intCol": @2}];
    XCTAssertEqual([objects count], 2U, @"Should have 2 objects");

    [PrimaryStringObject createOrUpdateInRealm:realm withValue:@{@"intCol": @5}];
    [PrimaryStringObject createOrUpdateInRealm:realm withValue:@{@"intCol": @7}];
    XCTAssertEqual([PrimaryStringObject objectInRealm:realm forPrimaryKey:NSNull.null].intCol, 7);
    [PrimaryStringObject createOrUpdateInRealm:realm withValue:@{@"stringCol": NSNull.null, @"intCol": @11}];
    XCTAssertEqual([PrimaryStringObject objectInRealm:realm forPrimaryKey:nil].intCol, 11);

    // upsert with new secondary property
    [PrimaryStringObject createOrUpdateInDefaultRealmWithValue:@[@"string", @3]];
    XCTAssertEqual([objects count], 3U, @"Should have 3 objects");
    XCTAssertEqual([(PrimaryStringObject *)objects[0] intCol], 3, @"Value should be 3");

    // upsert on non-primary key object should throw
    XCTAssertThrows([StringObject createOrUpdateInDefaultRealmWithValue:@[@"string"]]);
    XCTAssertThrows([StringObject createOrUpdateInRealm:realm withValue:@[@"string"]]);

    [realm commitWriteTransaction];
}

- (void)testCreateOrUpdateNestedObjects {
    RLMRealm *realm = [RLMRealm defaultRealm];
    [realm beginWriteTransaction];

    [PrimaryNestedObject createOrUpdateInDefaultRealmWithValue:@[@0, @[@"string", @1], @[@[@"string", @1]], @[@"string"], @[@[@1]], @""]];
    XCTAssertEqual([[PrimaryNestedObject allObjects] count], 1U, @"Should have 1 object");
    XCTAssertEqual([[PrimaryStringObject allObjects] count], 1U, @"Should have 1 object");
    XCTAssertEqual([[PrimaryIntObject allObjects] count], 1U, @"Should have 1 object");

    // update parent and nested object
    [PrimaryNestedObject createOrUpdateInDefaultRealmWithValue:@{@"primaryCol": @0,
                                                                  @"primaryStringObject": @[@"string", @2],
                                                                  @"primaryStringObjectWrapper": @[@[@"string", @2]],
                                                                  @"stringObject": @[@"string2"]}];
    XCTAssertEqual([[PrimaryNestedObject allObjects] count], 1U, @"Should have 1 object");
    XCTAssertEqual([[PrimaryStringObject allObjects] count], 1U, @"Should have 1 object");
    XCTAssertEqual([PrimaryStringObject.allObjects.lastObject intCol], 2, @"intCol should be 2");
    XCTAssertEqualObjects([PrimaryNestedObject.allObjects.lastObject stringCol], @"", @"stringCol should not have been updated");
    XCTAssertEqual(1U, [PrimaryNestedObject.allObjects.lastObject primaryIntArray].count, @"intArray should not have been overwritten");
    XCTAssertEqual([[StringObject allObjects] count], 2U, @"Should have 2 objects");

    // test partial update nulling out object/array properties
    [PrimaryNestedObject createOrUpdateInDefaultRealmWithValue:@{@"primaryCol": @0,
                                                                  @"stringCol": @"updated",
                                                                  @"stringObject": NSNull.null,
                                                                  @"primaryIntArray": NSNull.null}];
    PrimaryNestedObject *obj = PrimaryNestedObject.allObjects.lastObject;
    XCTAssertEqual(2, obj.primaryStringObject.intCol, @"primaryStringObject should not have changed");
    XCTAssertEqualObjects(obj.stringCol, @"updated", @"stringCol should have been updated");
    XCTAssertEqual(0U, obj.primaryIntArray.count, @"intArray should not have been emptied");
    XCTAssertNil(obj.stringObject, @"stringObject should be nil");

    // inserting new object should update nested
    obj = [PrimaryNestedObject createOrUpdateInDefaultRealmWithValue:@[@1, @[@"string", @3], @[@[@"string", @3]], @[@"string"], @[], @""]];
    XCTAssertEqual([[PrimaryNestedObject allObjects] count], 2U, @"Should have 2 objects");
    XCTAssertEqual([[PrimaryStringObject allObjects] count], 1U, @"Should have 1 object");
    XCTAssertEqual([(PrimaryStringObject *)[[PrimaryStringObject allObjects] lastObject] intCol], 3, @"intCol should be 3");

    // test addOrUpdateObject
    obj.primaryStringObject = [PrimaryStringObject createInDefaultRealmWithValue:@[@"string2", @1]];
    PrimaryNestedObject *obj1 = [[PrimaryNestedObject alloc] initWithValue:@[@1, @[@"string2", @4], @[@[@"string2", @4]], @[@"string"], @[@[@1], @[@2]], @""]];
    [realm addOrUpdateObject:obj1];
    XCTAssertEqual([[PrimaryNestedObject allObjects] count], 2U, @"Should have 2 objects");
    XCTAssertEqual([[PrimaryStringObject allObjects] count], 2U, @"Should have 2 objects");
    XCTAssertEqual([[PrimaryIntObject allObjects] count], 2U, @"Should have 2 objects");
    XCTAssertEqual([(PrimaryStringObject *)[[PrimaryStringObject allObjects] lastObject] intCol], 4, @"intCol should be 4");

    // creating new object with same primary key should throw
    XCTAssertThrows([PrimaryStringObject createInDefaultRealmWithValue:(@[@"string", @1])]);

    [realm commitWriteTransaction];
}


- (void)testObjectInSet {
    [[RLMRealm defaultRealm] beginWriteTransaction];

    // set object with primary and non primary keys as they both override isEqual and hash
    PrimaryStringObject *obj = [PrimaryStringObject createInDefaultRealmWithValue:(@[@"string2", @1])];
    StringObject *strObj = [StringObject createInDefaultRealmWithValue:@[@"string"]];
    NSMutableSet *dict = [NSMutableSet set];
    [dict addObject:obj];
    [dict addObject:strObj];

    // primary key objects should match even with duplicate instances of the same object
    XCTAssertTrue([dict containsObject:obj]);
    XCTAssertTrue([dict containsObject:[[PrimaryStringObject allObjects] firstObject]]);

    // non-primary key objects should only match when comparing identical instances
    XCTAssertTrue([dict containsObject:strObj]);
    XCTAssertFalse([dict containsObject:[[StringObject allObjects] firstObject]]);

    [[RLMRealm defaultRealm] commitWriteTransaction];
}

- (void)testObjectWithKey {
    [RLMRealm.defaultRealm beginWriteTransaction];
    PrimaryStringObject *strObj = [PrimaryStringObject createInDefaultRealmWithValue:@[@"key", @0]];
    PrimaryStringObject *nullStrObj = [PrimaryStringObject createInDefaultRealmWithValue:@[NSNull.null, @0]];
    PrimaryIntObject *intObj = [PrimaryIntObject createInDefaultRealmWithValue:@[@0]];
    PrimaryNullableIntObject *nonNullIntObj = [PrimaryNullableIntObject createInDefaultRealmWithValue:@[@0]];
    PrimaryNullableIntObject *nullIntObj = [PrimaryNullableIntObject createInDefaultRealmWithValue:@[NSNull.null]];
    [RLMRealm.defaultRealm commitWriteTransaction];

    // no PK
    XCTAssertThrows([StringObject objectForPrimaryKey:@""]);
    XCTAssertThrows([IntObject objectForPrimaryKey:@0]);
    XCTAssertThrows([StringObject objectForPrimaryKey:NSNull.null]);
    XCTAssertThrows([StringObject objectForPrimaryKey:nil]);
    XCTAssertThrows([IntObject objectForPrimaryKey:nil]);

    // wrong PK type
    XCTAssertThrows([PrimaryStringObject objectForPrimaryKey:@0]);
    XCTAssertThrows([PrimaryIntObject objectForPrimaryKey:@""]);
    XCTAssertThrows([PrimaryIntObject objectForPrimaryKey:@""]);
    XCTAssertThrows([PrimaryIntObject objectForPrimaryKey:NSNull.null]);
    XCTAssertThrows([PrimaryIntObject objectForPrimaryKey:nil]);

    // no object with key
    XCTAssertNil([PrimaryStringObject objectForPrimaryKey:@"bad key"]);
    XCTAssertNil([PrimaryIntObject objectForPrimaryKey:@1]);

    // object with key exists
    XCTAssertEqualObjects(strObj, [PrimaryStringObject objectForPrimaryKey:@"key"]);
    XCTAssertEqualObjects(nullStrObj, [PrimaryStringObject objectForPrimaryKey:NSNull.null]);
    XCTAssertEqualObjects(nullStrObj, [PrimaryStringObject objectForPrimaryKey:nil]);
    XCTAssertEqualObjects(intObj, [PrimaryIntObject objectForPrimaryKey:@0]);
    XCTAssertEqualObjects(nonNullIntObj, [PrimaryNullableIntObject objectForPrimaryKey:@0]);
    XCTAssertEqualObjects(nullIntObj, [PrimaryNullableIntObject objectForPrimaryKey:NSNull.null]);
    XCTAssertEqualObjects(nullIntObj, [PrimaryNullableIntObject objectForPrimaryKey:nil]);

    // nil realm throws
    XCTAssertThrows([PrimaryIntObject objectInRealm:self.nonLiteralNil forPrimaryKey:@0]);
}

- (void)testBacklinks {
    StringObject *obj = [[StringObject alloc] initWithValue:@[@"string"]];

    // calling on standalone should throw
    XCTAssertThrows([obj linkingObjectsOfClass:StringLinkObject.className forProperty:@"stringObjectCol"]);

    RLMRealm *realm = RLMRealm.defaultRealm;
    [realm transactionWithBlock:^{
        [realm addObject:obj];
    }];

    XCTAssertThrows([obj linkingObjectsOfClass:StringObject.className forProperty:@"stringCol"]);
    XCTAssertThrows([obj linkingObjectsOfClass:OwnerObject.className forProperty:@"dog"]);
    XCTAssertThrows([obj linkingObjectsOfClass:@"invalidClassName" forProperty:@"stringObjectCol"]);
    XCTAssertEqual(0U, [[obj linkingObjectsOfClass:StringLinkObject.className forProperty:@"stringObjectCol"] count]);

    [realm transactionWithBlock:^{
        StringLinkObject *lObj = [StringLinkObject createInDefaultRealmWithValue:@[obj, @[]]];
        XCTAssertEqual(1U, [[obj linkingObjectsOfClass:StringLinkObject.className forProperty:@"stringObjectCol"] count]);

        lObj.stringObjectCol = nil;
        XCTAssertEqual(0U, [[obj linkingObjectsOfClass:StringLinkObject.className forProperty:@"stringObjectCol"] count]);

        [lObj.stringObjectArrayCol addObject:obj];
        XCTAssertEqual(1U, [[obj linkingObjectsOfClass:StringLinkObject.className forProperty:@"stringObjectArrayCol"] count]);
        [lObj.stringObjectArrayCol addObject:obj];
        XCTAssertEqual(2U, [[obj linkingObjectsOfClass:StringLinkObject.className forProperty:@"stringObjectArrayCol"] count]);

        [realm deleteObject:obj];
        XCTAssertThrows([obj linkingObjectsOfClass:StringLinkObject.className forProperty:@"stringObjectCol"]);
    }];
}

@end
