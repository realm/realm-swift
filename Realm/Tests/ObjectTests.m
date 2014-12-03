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

@class CycleObject;
RLM_ARRAY_TYPE(CycleObject)
@interface CycleObject :RLMObject
@property RLMArray<CycleObject> *objects;
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
@property RLMArray<PrimaryIntObject> *primaryIntArray;
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

@interface StringLinkObject : RLMObject
@property StringObject *stringObjectCol;
@property RLMArray<StringObject> *stringObjectArrayCol;
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
    
    RLMResults *all = [EmployeeObject allObjects];
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
    
    RLMResults *all = [EmployeeObject allObjects];
    EmployeeObject *fromRealm = all.firstObject;
    
    XCTAssertEqualObjects(fromRealm.name, @"Susi", @"Names should be equal");
    XCTAssertEqual(fromRealm.age, 25, @"Age should be equal");
    XCTAssertEqual(fromRealm.hired, YES, @"Hired should be equal");
    
    XCTAssertThrows([[EmployeeObject alloc] initWithObject:@{}], @"Initialization with missing values should throw");
    XCTAssertNoThrow([[DefaultObject alloc] initWithObject:@{@"intCol": @1}],
                     "Overriding some default values at initialization should not throw");
}

-(void)testObjectInitWithObjectTypeObject
{
    DogExtraObject *dogExt = [[DogExtraObject alloc] initWithObject:@[@"Fido", @12, @"Poodle"]];

    // initialize second object with first object
    DogObject *dog = [[DogObject alloc] initWithObject:dogExt];
    XCTAssertEqualObjects(dog.dogName, @"Fido", @"Names should be equal");
    XCTAssertEqual(dog.age, 12, @"Age should be equal");

    // missing properties should throw
    XCTAssertThrows([[DogExtraObject alloc] initWithObject:dog], @"Initialization with missing values should throw");

    // nested objects should work
    XCTAssertNoThrow([[OwnerObject alloc] initWithObject:(@[@"Alex", dogExt])], @"Should not throw");
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

    OwnerObject *owner = [[OwnerObject alloc] initWithObject:@[@"Brian", @{@"dogName": @"Brido", @"age": @0}]];
    XCTAssertEqualObjects(owner.dog.dogName, @"Brido");

    OwnerObject *ownerArrayDog = [[OwnerObject alloc] initWithObject:@[@"JP", @[@"PJ", @0]]];
    XCTAssertEqualObjects(ownerArrayDog.dog.dogName, @"PJ");
}

- (void)testInitFromDictionaryMissingPropertyKey {
    CompanyObject *co = nil;
    XCTAssertThrows([[CompanyObject alloc] initWithObject:@{}]);
    XCTAssertNoThrow(co = [[CompanyObject alloc] initWithObject:@{@"name": @"a"}]);
    XCTAssertEqualObjects(co.name, @"a");
    XCTAssertEqual(co.employees.count, 0U);

    OwnerObject *oo = nil;
    XCTAssertNoThrow(oo = [[OwnerObject alloc] initWithObject:@{@"name": @"a"}]);
    XCTAssertEqualObjects(oo.name, @"a");
    XCTAssertNil(oo.dog);
}

- (void)testInitFromDictionaryPropertyKey {
    CompanyObject *co = nil;
    XCTAssertNoThrow((co = [[CompanyObject alloc] initWithObject:@{@"name": @"a", @"employees": NSNull.null}]));
    XCTAssertEqualObjects(co.name, @"a");
    XCTAssertEqual(co.employees.count, 0U);

    OwnerObject *oo = nil;
    XCTAssertNoThrow((oo = [[OwnerObject alloc] initWithObject:@{@"name": @"a", @"employees": NSNull.null}]));
    XCTAssertEqualObjects(oo.name, @"a");
    XCTAssertNil(oo.dog);
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
    NSData *bin1 = [[NSData alloc] initWithBytes:bin length:sizeof bin / 2];
    NSData *bin2 = [[NSData alloc] initWithBytes:bin length:sizeof bin];
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
}

- (void)testObjectSubclass {
    RLMRealm *realm = [RLMRealm defaultRealm];
    [realm beginWriteTransaction];
    [StringObject createInDefaultRealmWithObject:@[@"string"]];
    StringSubclassObject *obj = [StringSubclassObject createInDefaultRealmWithObject:@[@"string", @"string2"]];

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
    StringLinkObject *linkObject = [StringLinkObject createInDefaultRealmWithObject:@[NSNull.null, @[]]];
    XCTAssertThrows(linkObject.stringObjectCol = obj);
    XCTAssertThrows([linkObject.stringObjectArrayCol addObject:obj]);
    [realm commitWriteTransaction];
}

- (void)testDataSizeLimits {
    RLMRealm *realm = [RLMRealm defaultRealm];

    // Allocation must be < 16 MB, with an 8-byte header and the allcation size
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
    stringObject = [[StringObject alloc] init];
    stringObject.stringCol = @"";
    XCTAssertNoThrow(([realm addObject:stringObject]), @"Having values in all NSObject properties should not throw exception when being added to realm");
    
    // Test #3
//    FIXME: Test should pass
//    IntObject *intObj = [[IntObject alloc] init];
//    XCTAssertThrows(([realm addObject:intObj]), @"Adding object with no values specified for NSObject properties should throw exception if NSObject property is nil");
    
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
        [DefaultObject createInRealm:realm withObject:dict];
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
        if (prop.type == RLMPropertyTypeArray || prop.type == RLMPropertyTypeObject) {
            [realm beginWriteTransaction];
            [DefaultObject createInRealm:realm withObject:dict];
            [realm commitWriteTransaction];

            DefaultObject *object = DefaultObject.allObjects.lastObject;
            for (NSUInteger j = 0; j < keys.count; ++j) {
                NSString *key2 = keys[j];
                if ([key isEqualToString:key2]) {
                    XCTAssertEqualObjects(object[key2], defaultValues[key2]);
                }
                else {
                    XCTAssertEqualObjects(object[key2], inputValues[key2]);
                }
            }
        }
        else {
            [realm beginWriteTransaction];
            XCTAssertThrows([DefaultObject createInRealm:realm withObject:dict]);
            [realm commitWriteTransaction];
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
    NSData *bin1 = [[NSData alloc] initWithBytes:bin length:sizeof bin / 2];
    NSDate *timeNow = [NSDate dateWithTimeIntervalSince1970:1000000];
    NSArray *const arrayValidAllTypes = @[@NO, @54, @0.7f, @0.8, @"foo", bin1, timeNow, @NO, @(99), @"mixed", to];
    
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

    [OwnerObject createInDefaultRealmWithObject:@[@"Brian", @{@"dogName": @"Brido", @"age": @0}]];
    [OwnerObject createInDefaultRealmWithObject:@[@"JP", @[@"PJ", @0]]];

    [realm commitWriteTransaction];

    // verify object literals
    OwnerObject *brian = OwnerObject.allObjects[0], *jp = OwnerObject.allObjects[1];
    XCTAssertEqualObjects(brian.dog.dogName, @"Brido");
    XCTAssertEqualObjects(jp.dog.dogName, @"PJ");

    // verify with kvc objects
    // create DogExtraObject
    DogExtraObject *dogExt = [[DogExtraObject alloc] initWithObject:@[@"Fido", @12, @"Poodle"]];

    [realm beginWriteTransaction];

    // create second object with DogExtraObject object
    DogObject *dog = [DogObject createInDefaultRealmWithObject:dogExt];

    // missing properties
    XCTAssertThrows([DogExtraObject createInDefaultRealmWithObject:dog], @"Initialization with missing values should throw");

    // nested objects should work
    XCTAssertNoThrow([OwnerObject createInDefaultRealmWithObject:(@[@"Alex", dogExt])], @"Should not throw");

    [realm commitWriteTransaction];
}

- (void)testCreateInRealmReusesExistingObjects {
    RLMRealm *realm = [RLMRealm defaultRealm];
    [realm beginWriteTransaction];

    DogObject *dog = [DogObject createInDefaultRealmWithObject:@[@"Fido", @5]];
    OwnerObject *owner = [OwnerObject createInDefaultRealmWithObject:@[@"name", dog]];
    XCTAssertTrue([owner.dog isEqualToObject:dog]);
    XCTAssertEqual(1U, DogObject.allObjects.count);

    DogArrayObject *dogArray = [DogArrayObject createInDefaultRealmWithObject:@[@[dog]]];
    XCTAssertTrue([dogArray.dogs[0] isEqualToObject:dog]);
    XCTAssertEqual(1U, DogObject.allObjects.count);

    [realm commitWriteTransaction];
}

- (void)testCreateInRealmCopiesFromOtherRealm {
    RLMRealm *realm1 = [RLMRealm defaultRealm];
    RLMRealm *realm2 = [self realmWithTestPath];
    [realm1 beginWriteTransaction];
    [realm2 beginWriteTransaction];

    DogObject *dog = [DogObject createInDefaultRealmWithObject:@[@"Fido", @5]];
    OwnerObject *owner = [OwnerObject createInRealm:realm2 withObject:@[@"name", dog]];
    XCTAssertFalse([owner.dog isEqualToObject:dog]);
    XCTAssertEqual(1U, DogObject.allObjects.count);
    XCTAssertEqual(1U, [DogObject allObjectsInRealm:realm2].count);

    DogArrayObject *dogArray = [DogArrayObject createInRealm:realm2 withObject:@[@[dog]]];
    XCTAssertFalse([dogArray.dogs[0] isEqualToObject:dog]);
    XCTAssertEqual(1U, DogObject.allObjects.count);
    XCTAssertEqual(2U, [DogObject allObjectsInRealm:realm2].count);

    [realm1 commitWriteTransaction];
    [realm2 commitWriteTransaction];
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

- (void)testDeletedObjectDescription
{
    RLMRealm *realm = [RLMRealm defaultRealm];

    [realm beginWriteTransaction];
    EmployeeObject *obj = [EmployeeObject createInRealm:realm withObject:@[@"Peter", @30, @YES]];
    [realm deleteObject:obj];
    [realm commitWriteTransaction];

    XCTAssertNoThrow(obj.description);
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

    RLMRealm *realm = [RLMRealm defaultRealm];
    RLMRealm *otherRealm = [self realmWithTestPath];

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

- (void)testIsDeleted {
    StringObject *obj1 = [[StringObject alloc] initWithObject:@[@"a"]];
    XCTAssertEqual(obj1.invalidated, NO);

    RLMRealm *realm = [self realmWithTestPath];
    [realm beginWriteTransaction];
    [realm addObject:obj1];
    StringObject *obj2 = [StringObject createInRealm:realm withObject:@[@"b"]];

    XCTAssertEqual([obj1 isInvalidated], NO);
    XCTAssertEqual(obj2.invalidated, NO);

    [realm commitWriteTransaction];

    // delete
    [realm beginWriteTransaction];
    [realm deleteObject:obj1];
    [realm deleteObject:obj2];

    XCTAssertEqual(obj1.invalidated, YES);
    XCTAssertEqual(obj2.invalidated, YES);

    XCTAssertThrows([realm addObject:obj1], @"Adding deleted object should throw");
    
    [realm commitWriteTransaction];

    XCTAssertEqual(obj1.invalidated, YES);
    XCTAssertNil(obj1.realm, @"Realm should be nil after deletion");
}

- (void)testPrimaryKey {
    [[RLMRealm defaultRealm] beginWriteTransaction];

    [PrimaryStringObject createInDefaultRealmWithObject:(@[@"string", @1])];
    PrimaryStringObject *obj = [PrimaryStringObject createInDefaultRealmWithObject:(@[@"string2", @1])];
    XCTAssertThrows([PrimaryStringObject createInDefaultRealmWithObject:(@[@"string", @1])], @"Duplicate primary key should throw");
    XCTAssertThrows(obj.stringCol = @"string2", @"Setting primary key should throw");

    [PrimaryIntObject createInDefaultRealmWithObject:(@[@1])];
    PrimaryIntObject *obj1 = [PrimaryIntObject createInDefaultRealmWithObject:(@{@"intCol": @2})];
    XCTAssertThrows([PrimaryIntObject createInDefaultRealmWithObject:(@[@1])], @"Duplicate primary key should throw");
    XCTAssertThrows(obj1.intCol = 2, @"Setting primary key should throw");

    [PrimaryInt64Object createInDefaultRealmWithObject:(@[@(1LL << 40)])];
    PrimaryInt64Object *obj2 = [PrimaryInt64Object createInDefaultRealmWithObject:(@[@(1LL << 41)])];
    XCTAssertThrows([PrimaryInt64Object createInDefaultRealmWithObject:(@[@(1LL << 40)])], @"Duplicate primary key should throw");
    XCTAssertThrows(obj2.int64Col = 1LL << 41, @"Setting primary key should throw");

    [[RLMRealm defaultRealm] commitWriteTransaction];
}

- (void)testCreateOrUpdate {
    RLMRealm *realm = [RLMRealm defaultRealm];
    [realm beginWriteTransaction];

    [PrimaryStringObject createOrUpdateInDefaultRealmWithObject:@[@"string", @1]];
    RLMResults *objects = [PrimaryStringObject allObjects];
    XCTAssertEqual([objects count], 1U, @"Should have 1 object");
    XCTAssertEqual([(PrimaryStringObject *)objects[0] intCol], 1, @"Value should be 1");

    [PrimaryStringObject createOrUpdateInRealm:realm withObject:@{@"stringCol": @"string2", @"intCol": @2}];
    XCTAssertEqual([objects count], 2U, @"Should have 2 objects");

    // upsert with new secondary property
    [PrimaryStringObject createOrUpdateInDefaultRealmWithObject:@[@"string", @3]];
    XCTAssertEqual([objects count], 2U, @"Should have 2 objects");
    XCTAssertEqual([(PrimaryStringObject *)objects[0] intCol], 3, @"Value should be 3");

    // upsert on non-primary key object shoudld throw
    XCTAssertThrows([StringObject createOrUpdateInDefaultRealmWithObject:@[@"string"]]);

    [realm commitWriteTransaction];
}

- (void)testCreateOrUpdateNestedObjects {
    RLMRealm *realm = [RLMRealm defaultRealm];
    [realm beginWriteTransaction];

    [PrimaryNestedObject createOrUpdateInDefaultRealmWithObject:@[@0, @[@"string", @1], @[@[@"string", @1]], @[@"string"], @[@[@1]], @""]];
    XCTAssertEqual([[PrimaryNestedObject allObjects] count], 1U, @"Should have 1 object");
    XCTAssertEqual([[PrimaryStringObject allObjects] count], 1U, @"Should have 1 object");
    XCTAssertEqual([[PrimaryIntObject allObjects] count], 1U, @"Should have 1 object");

    // update parent and nested object
    [PrimaryNestedObject createOrUpdateInDefaultRealmWithObject:@{@"primaryCol": @0,
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
    [PrimaryNestedObject createOrUpdateInDefaultRealmWithObject:@{@"primaryCol": @0,
                                                                  @"stringCol": @"updated",
                                                                  @"stringObject": NSNull.null,
                                                                  @"primaryIntArray": NSNull.null}];
    PrimaryNestedObject *obj = PrimaryNestedObject.allObjects.lastObject;
    XCTAssertEqual(2, obj.primaryStringObject.intCol, @"primaryStringObject should not have changed");
    XCTAssertEqualObjects(obj.stringCol, @"updated", @"stringCol should have been updated");
    XCTAssertEqual(0U, obj.primaryIntArray.count, @"intArray should not have been emptied");
    XCTAssertNil(obj.stringObject, @"stringObject should be nil");

    // inserting new object should update nested
    obj = [PrimaryNestedObject createOrUpdateInDefaultRealmWithObject:@[@1, @[@"string", @3], @[@[@"string", @3]], @[@"string"], @[], @""]];
    XCTAssertEqual([[PrimaryNestedObject allObjects] count], 2U, @"Should have 2 objects");
    XCTAssertEqual([[PrimaryStringObject allObjects] count], 1U, @"Should have 1 object");
    XCTAssertEqual([(PrimaryStringObject *)[[PrimaryStringObject allObjects] lastObject] intCol], 3, @"intCol should be 3");

    // test addOrUpdateObject
    obj.primaryStringObject = [PrimaryStringObject createInDefaultRealmWithObject:@[@"string2", @1]];
    PrimaryNestedObject *obj1 = [[PrimaryNestedObject alloc] initWithObject:@[@1, @[@"string2", @4], @[@[@"string2", @4]], @[@"string"], @[@[@1], @[@2]], @""]];
    [realm addOrUpdateObject:obj1];
    XCTAssertEqual([[PrimaryNestedObject allObjects] count], 2U, @"Should have 2 objects");
    XCTAssertEqual([[PrimaryStringObject allObjects] count], 2U, @"Should have 2 objects");
    XCTAssertEqual([[PrimaryIntObject allObjects] count], 2U, @"Should have 2 objects");
    XCTAssertEqual([(PrimaryStringObject *)[[PrimaryStringObject allObjects] lastObject] intCol], 4, @"intCol should be 4");

    // creating new object with same primary key should throw
    XCTAssertThrows([PrimaryStringObject createInDefaultRealmWithObject:(@[@"string", @1])]);

    [realm commitWriteTransaction];
}


- (void)testObjectInSet {
    [[RLMRealm defaultRealm] beginWriteTransaction];

    // set object with primary and non primary keys as they both override isEqual and hash
    PrimaryStringObject *obj = [PrimaryStringObject createInDefaultRealmWithObject:(@[@"string2", @1])];
    StringObject *strObj = [StringObject createInDefaultRealmWithObject:@[@"string"]];
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
    PrimaryStringObject *strObj = [PrimaryStringObject createInDefaultRealmWithObject:@[@"key", @0]];
    PrimaryIntObject *intObj = [PrimaryIntObject createInDefaultRealmWithObject:@[@0]];
    [RLMRealm.defaultRealm commitWriteTransaction];

    // no PK
    XCTAssertThrows([StringObject objectForPrimaryKey:@""]);
    XCTAssertThrows([IntObject objectForPrimaryKey:@0]);

    // wrong PK type
    XCTAssertThrows([PrimaryStringObject objectForPrimaryKey:@0]);
    XCTAssertThrows([PrimaryIntObject objectForPrimaryKey:@""]);

    // no object with key
    XCTAssertNil([PrimaryStringObject objectForPrimaryKey:@"bad key"]);
    XCTAssertNil([PrimaryIntObject objectForPrimaryKey:@1]);

    // object with key exists
    XCTAssertEqualObjects(strObj, [PrimaryStringObject objectForPrimaryKey:@"key"]);
    XCTAssertEqualObjects(intObj, [PrimaryIntObject objectForPrimaryKey:@0]);
}

- (void)testBacklinks {
    StringObject *obj = [[StringObject alloc] initWithObject:@[@"string"]];

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
        StringLinkObject *lObj = [StringLinkObject createInDefaultRealmWithObject:@[obj, @[]]];
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
