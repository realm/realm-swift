////////////////////////////////////////////////////////////////////////////
//
// Copyright 2017 Realm Inc.
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

#pragma mark - Test Objects

@interface DogExtraObject : RLMObject
@property NSString *dogName;
@property int age;
@property NSString *breed;
@end

@implementation DogExtraObject
@end

@interface BizzaroDog : RLMObject
@property int dogName;
@property NSString *age;
@end

@implementation BizzaroDog
@end

@interface PrimaryKeyWithDefault : RLMObject
@property NSString *stringCol;
@property int intCol;
@end
@implementation PrimaryKeyWithDefault
+ (NSString *)primaryKey {
    return @"stringCol";
}
+ (NSDictionary *)defaultPropertyValues {
    return @{@"intCol": @10};
}
@end

@interface AllLinks : RLMObject
@property StringObject *string;
@property PrimaryStringObject *primaryString;
@property RLM_GENERIC_ARRAY(IntObject) *intArray;
@property RLM_GENERIC_ARRAY(PrimaryIntObject) *primaryIntArray;
@property RLM_GENERIC_SET(IntObject) *intSet;
@property RLM_GENERIC_SET(PrimaryIntObject) *primaryIntSet;
@end

@implementation AllLinks
@end

@interface AllLinksWithPrimary : RLMObject
@property NSString *pk;
@property StringObject *string;
@property PrimaryStringObject *primaryString;
@property RLM_GENERIC_ARRAY(IntObject) *intArray;
@property RLM_GENERIC_ARRAY(PrimaryIntObject) *primaryIntArray;
@property RLM_GENERIC_SET(IntObject) *intSet;
@property RLM_GENERIC_SET(PrimaryIntObject) *primaryIntSet;
@end

@implementation AllLinksWithPrimary
+ (NSString *)primaryKey {
    return @"pk";
}
@end

@interface PrimaryKeyAndRequiredString : RLMObject
@property int pk;
@property NSString *value;
@end
@implementation PrimaryKeyAndRequiredString
+ (NSString *)primaryKey {
    return @"pk";
}
+ (NSArray *)requiredProperties {
    return @[@"value"];
}
@end


#pragma mark - Tests

@interface ObjectCreationTests : RLMTestCase
@end

@implementation ObjectCreationTests

#pragma mark - Init With Value

- (void)testInitWithInvalidThings {
    RLMAssertThrowsWithReasonMatching([[DogObject alloc] initWithValue:self.nonLiteralNil],
                                      @"Must provide a non-nil value");
    RLMAssertThrowsWithReasonMatching([[DogObject alloc] initWithValue:NSNull.null],
                                      @"Must provide a non-nil value");
    RLMAssertThrowsWithReasonMatching([[DogObject alloc] initWithValue:@"name"],
                                      @"Invalid value 'name' to initialize object of type 'DogObject'");
}

- (void)testInitWithArray {
    auto co = [[CompanyObject alloc] initWithValue:@[]];
    XCTAssertNil(co.name);
    XCTAssertEqual(co.employees.count, 0U);

    co = [[CompanyObject alloc] initWithValue:@[@"empty company"]];
    XCTAssertEqualObjects(co.name, @"empty company");
    XCTAssertEqual(co.employees.count, 0U);

    co = [[CompanyObject alloc] initWithValue:@[@"empty company", NSNull.null]];
    XCTAssertEqualObjects(co.name, @"empty company");
    XCTAssertEqual(co.employees.count, 0U);

    co = [[CompanyObject alloc] initWithValue:@[@"empty company", @[]]];
    XCTAssertEqualObjects(co.name, @"empty company");
    XCTAssertEqual(co.employees.count, 0U);

    co = [[CompanyObject alloc] initWithValue:@[@"one employee",
                                                @[@[@"name", @2, @YES]]]];
    XCTAssertEqualObjects(co.name, @"one employee");
    XCTAssertEqual(co.employees.count, 1U);
    EmployeeObject *eo = co.employees.firstObject;
    XCTAssertEqualObjects(eo.name, @"name");
    XCTAssertEqual(eo.age, 2);
    XCTAssertEqual(eo.hired, YES);

    co = [[CompanyObject alloc] initWithValue:@[@"one employee", @[eo]]];
    XCTAssertEqualObjects(co.name, @"one employee");
    XCTAssertEqual(co.employees.count, 1U);
    eo = co.employees.firstObject;
    XCTAssertEqualObjects(eo.name, @"name");
    XCTAssertEqual(eo.age, 2);
    XCTAssertEqual(eo.hired, YES);
}

- (void)testInitWithSet {
    auto co = [[CompanyObject alloc] initWithValue:@[]];
    XCTAssertNil(co.name);
    XCTAssertEqual(co.employeeSet.count, 0U);

    co = [[CompanyObject alloc] initWithValue:@[@"empty company"]];
    XCTAssertEqualObjects(co.name, @"empty company");
    XCTAssertEqual(co.employeeSet.count, 0U);

    co = [[CompanyObject alloc] initWithValue:@[@"empty company", NSNull.null]];
    XCTAssertEqualObjects(co.name, @"empty company");
    XCTAssertEqual(co.employeeSet.count, 0U);

    co = [[CompanyObject alloc] initWithValue:@[@"empty company", @[]]];
    XCTAssertEqualObjects(co.name, @"empty company");
    XCTAssertEqual(co.employeeSet.count, 0U);

    co = [[CompanyObject alloc] initWithValue:@[@"one employee",
                                                @[@[@"name", @2, @YES]],
                                                @[@[@"name", @2, @YES]]]];
    XCTAssertEqualObjects(co.name, @"one employee");
    XCTAssertEqual(co.employeeSet.count, 1U);
    EmployeeObject *eo = co.employeeSet.allObjects[0];
    XCTAssertEqualObjects(eo.name, @"name");
    XCTAssertEqual(eo.age, 2);
    XCTAssertEqual(eo.hired, YES);

    co = [[CompanyObject alloc] initWithValue:@[@"one employee", @[eo], @[eo]]];
    XCTAssertEqualObjects(co.name, @"one employee");
    XCTAssertEqual(co.employeeSet.count, 1U);
    eo = co.employeeSet.allObjects[0];
    XCTAssertEqualObjects(eo.name, @"name");
    XCTAssertEqual(eo.age, 2);
    XCTAssertEqual(eo.hired, YES);
}

- (void)testWithNonArrayEnumerableForRLMArrayProperty {
    auto employees = @[@[@"name", @2, @YES], @[@"name 2", @3, @NO]];
    auto co = [[CompanyObject alloc] initWithValue:@[@"one employee", employees.reverseObjectEnumerator]];
    XCTAssertEqual(2U, co.employees.count);
    XCTAssertEqualObjects(@"name 2", co.employees[0].name);
    XCTAssertEqualObjects(@"name", co.employees[1].name);
}

- (void)testWithNonSetEnumerableForRLMSetProperty {
    auto employees = @[@[@"name", @2, @YES], @[@"name 2", @3, @NO]];
    auto co = [[CompanyObject alloc] initWithValue:@[@"one employee",
                                                     employees.reverseObjectEnumerator,
                                                     employees.reverseObjectEnumerator]];
    XCTAssertEqual(2U, co.employeeSet.count);

    XCTAssertTrue([[co.employeeSet valueForKey:@"name"] containsObject:@"name"]);
    XCTAssertTrue([[co.employeeSet valueForKey:@"name"] containsObject:@"name 2"]);
}

- (void)testInitWithArrayUsesDefaultValuesForMissingFields {
    auto obj = [[NumberDefaultsObject alloc] initWithValue:@[]];
    XCTAssertEqualObjects(obj.intObj, @1);
    XCTAssertEqualObjects(obj.floatObj, @2.2f);
    XCTAssertEqualObjects(obj.doubleObj, @3.3);
    XCTAssertEqualObjects(obj.boolObj, @NO);

    obj = [[NumberDefaultsObject alloc] initWithValue:@[@10, @22.2f]];
    XCTAssertEqualObjects(obj.intObj, @10);
    XCTAssertEqualObjects(obj.floatObj, @22.2f);
    XCTAssertEqualObjects(obj.doubleObj, @3.3);
    XCTAssertEqualObjects(obj.boolObj, @NO);
}

- (void)testInitWithInvalidArray {
    RLMAssertThrowsWithReason(([[DogObject alloc] initWithValue:@[@"name", @"age"]]),
                              @"Invalid value 'age' of type '__NSCFConstantString' for 'int' property 'DogObject.age'.");
    RLMAssertThrowsWithReason(([[DogObject alloc] initWithValue:@[@"name", NSNull.null]]),
                              @"Invalid value '(null)' of type '(null)' for 'int' property 'DogObject.age'.");
    RLMAssertThrowsWithReason(([[DogObject alloc] initWithValue:@[@"name", @5, @"too many values"]]),
                              @"Invalid array input: more values (3) than properties (2).");
}

- (void)testInitWithDictionary {
    auto co = [[CompanyObject alloc] initWithValue:@{}];
    XCTAssertNil(co.name);
    XCTAssertEqual(co.employees.count, 0U);

    co = [[CompanyObject alloc] initWithValue:@{@"name": NSNull.null}];
    XCTAssertNil(co.name);
    XCTAssertEqual(co.employees.count, 0U);

    co = [[CompanyObject alloc] initWithValue:@{@"name": @"empty company"}];
    XCTAssertEqualObjects(co.name, @"empty company");
    XCTAssertEqual(co.employees.count, 0U);

    co = [[CompanyObject alloc] initWithValue:@{@"name": @"empty company",
                                                @"employees": NSNull.null,
                                                @"employeeSet": NSNull.null}];
    XCTAssertEqualObjects(co.name, @"empty company");
    XCTAssertEqual(co.employees.count, 0U);
    XCTAssertEqual(co.employeeSet.count, 0U);

    co = [[CompanyObject alloc] initWithValue:@{@"name": @"empty company",
                                                @"employees": @[],
                                                @"employeeSet": @[]}];
    XCTAssertEqualObjects(co.name, @"empty company");
    XCTAssertEqual(co.employees.count, 0U);
    XCTAssertEqual(co.employeeSet.count, 0U);

    co = [[CompanyObject alloc] initWithValue:@{@"name": @"one employee",
                                                @"employees": @[@[@"name", @2, @YES]],
                                                @"employeeSet": @[@[@"name", @2, @YES]]}];
    XCTAssertEqualObjects(co.name, @"one employee");
    XCTAssertEqual(co.employees.count, 1U);
    XCTAssertEqual(co.employeeSet.count, 1U);
    EmployeeObject *eo = co.employees.firstObject;
    EmployeeObject *eo2 = co.employeeSet.allObjects[0];
    XCTAssertEqualObjects(eo.name, @"name");
    XCTAssertEqualObjects(eo2.name, @"name");
    XCTAssertEqual(eo.age, 2);
    XCTAssertEqual(eo.hired, YES);
    XCTAssertEqual(eo2.age, 2);
    XCTAssertEqual(eo2.hired, YES);

    co = [[CompanyObject alloc] initWithValue:@{@"name": @"one employee",
                                                @"employees": @[@{@"name": @"name",
                                                                  @"age": @2,
                                                                  @"hired": @YES}],
                                                @"employeeSet": @[@{@"name": @"name",
                                                                  @"age": @2,
                                                                  @"hired": @YES}]}];
    XCTAssertEqualObjects(co.name, @"one employee");
    XCTAssertEqual(co.employees.count, 1U);
    XCTAssertEqual(co.employeeSet.count, 1U);
    eo = co.employees.firstObject;
    eo2 = co.employeeSet.allObjects[0];
    XCTAssertEqualObjects(eo.name, @"name");
    XCTAssertEqual(eo.age, 2);
    XCTAssertEqual(eo.hired, YES);
    XCTAssertEqualObjects(eo2.name, @"name");
    XCTAssertEqual(eo2.age, 2);
    XCTAssertEqual(eo2.hired, YES);

    co = [[CompanyObject alloc] initWithValue:@{@"name": @"no employees",
                                                @"extra fields": @"are okay"}];
    XCTAssertEqualObjects(co.name, @"no employees");
    XCTAssertEqual(co.employees.count, 0U);
    XCTAssertEqual(co.employeeSet.count, 0U);
}

- (void)testInitWithInvalidDictionary {
    RLMAssertThrowsWithReason(([[DogObject alloc] initWithValue:@{@"name": @"a", @"age": NSNull.null}]),
                              @"Invalid value '(null)' of type '(null)' for 'int' property 'DogObject.age'");
    RLMAssertThrowsWithReasonMatching(([[DogObject alloc] initWithValue:@{@"name": @"a", @"age": NSDate.date}]),
                                      @"Invalid value '20.*' of type '.*Date' for 'int' property 'DogObject.age'");
}

- (void)testInitWithDictionaryUsesDefaultValuesForMissingFields {
    auto obj = [[NumberDefaultsObject alloc] initWithValue:@{}];
    XCTAssertEqualObjects(obj.intObj, @1);
    XCTAssertEqualObjects(obj.floatObj, @2.2f);
    XCTAssertEqualObjects(obj.doubleObj, @3.3);
    XCTAssertEqualObjects(obj.boolObj, @NO);

    obj = [[NumberDefaultsObject alloc] initWithValue:@{@"intObj": @10}];
    XCTAssertEqualObjects(obj.intObj, @10);
    XCTAssertEqualObjects(obj.floatObj, @2.2f);
    XCTAssertEqualObjects(obj.doubleObj, @3.3);
    XCTAssertEqualObjects(obj.boolObj, @NO);
}

- (void)testInitWithObject {
    auto eo = [[EmployeeObject alloc] init];
    eo.name = @"employee name";
    eo.age = 1;
    eo.hired = NO;

    auto co = [[CompanyObject alloc] init];
    co.name = @"name";
    [co.employees addObject:eo];

    auto co2 = [[CompanyObject alloc] initWithValue:co];
    XCTAssertEqualObjects(co.name, co2.name);
    XCTAssertEqual(co.employees[0], co2.employees[0]); // not EqualObjects as it's a shallow copy

    auto dogExt = [[DogExtraObject alloc] initWithValue:@[@"Fido", @12, @"Poodle"]];
    auto dog = [[DogObject alloc] initWithValue:dogExt];
    XCTAssertEqualObjects(dog.dogName, @"Fido");
    XCTAssertEqual(dog.age, 12);

    auto owner = [[OwnerObject alloc] initWithValue:@[@"Alex", dogExt]];
    XCTAssertEqualObjects(owner.dog.dogName, @"Fido");

    auto array1 = [[AllPrimitiveArrays alloc] init];
    [array1.intObj addObject:@2];
    auto array2 = [[AllPrimitiveArrays alloc] initWithValue:array1];
    XCTAssertEqual(array2.intObj.count, 1U);
    XCTAssertEqualObjects(array2.intObj.firstObject, @2);

    auto set1 = [[AllPrimitiveSets alloc] init];
    [set1.intObj addObject:@2];
    auto set2 = [[AllPrimitiveSets alloc] initWithValue:set1];
    XCTAssertEqual(set2.intObj.count, 1U);
    XCTAssertEqualObjects(set2.intObj.allObjects[0], @2);
}

- (void)testInitWithInvalidObject {
    // No overlap in properties
    auto so = [[StringObject alloc] initWithValue:@[@"str"]];
    RLMAssertThrowsWithReason([[IntObject alloc] initWithValue:so], @"missing key 'intCol'");

    // Dog has some but not all of DogExtra's properties
    auto dog = [[DogObject alloc] initWithValue:@[@"Fido", @10]];
    RLMAssertThrowsWithReason([[DogExtraObject alloc] initWithValue:dog], @"missing key 'breed'");

    // Same property names, but different types
    RLMAssertThrowsWithReason([[BizzaroDog alloc] initWithValue:dog],
                              @"Invalid value 'Fido' of type '__NSCFConstantString' for 'int' property 'BizzaroDog.dogName'");
}

- (void)testInitPrimitiveArraysWithInvalidValues {
    RLMAssertThrowsWithReason([[AllPrimitiveArrays alloc] initWithValue:@{@"intObj": @[NSNull.null]}],
                             @"Invalid value '<null>' of type 'NSNull' for 'int' array property 'AllPrimitiveArrays.intObj'.");
    RLMAssertThrowsWithReason([[AllPrimitiveArrays alloc] initWithValue:@{@"intObj": @[@1.1]}],
                             @"Invalid value '1.1' of type '" RLMConstantDouble "' for 'int' array property 'AllPrimitiveArrays.intObj'.");
    RLMAssertThrowsWithReason([[AllPrimitiveArrays alloc] initWithValue:@{@"intObj": @[@"0"]}],
                             @"Invalid value '0' of type '__NSCFConstantString' for 'int' array property 'AllPrimitiveArrays.intObj'.");
    RLMAssertThrowsWithReason([[AllPrimitiveArrays alloc] initWithValue:@{@"intObj": @1}],
                             @"Invalid value (1) for 'int' array property 'AllPrimitiveArrays.intObj': value is not enumerable.");
}

- (void)testInitPrimitiveSetsWithInvalidValues {
    RLMAssertThrowsWithReason([[AllPrimitiveSets alloc] initWithValue:@{@"intObj": @[NSNull.null]}],
                             @"Invalid value '<null>' of type 'NSNull' for 'int' set property 'AllPrimitiveSets.intObj'.");
    RLMAssertThrowsWithReason([[AllPrimitiveSets alloc] initWithValue:@{@"intObj": @[@1.1]}],
                             @"Invalid value '1.1' of type '" RLMConstantDouble "' for 'int' set property 'AllPrimitiveSets.intObj'.");
    RLMAssertThrowsWithReason([[AllPrimitiveSets alloc] initWithValue:@{@"intObj": @[@"0"]}],
                             @"Invalid value '0' of type '" RLMConstantString "' for 'int' set property 'AllPrimitiveSets.intObj'.");
    RLMAssertThrowsWithReason([[AllPrimitiveSets alloc] initWithValue:@{@"intObj": @1}],
                             @"Invalid value (1) for 'int' set property 'AllPrimitiveSets.intObj': value is not enumerable.");
}

- (void)testInitWithCustomAccessors {
    // Create with array
    auto ca = [[CustomAccessorsObject alloc] initWithValue:@[@"a", @1]];
    XCTAssertEqualObjects(ca.name, @"a");
    XCTAssertEqual(ca.age, 1);

    // Create with dictionary
    ca = [[CustomAccessorsObject alloc] initWithValue:@{@"name": @"b", @"age": @2}];
    XCTAssertEqualObjects(ca.name, @"b");
    XCTAssertEqual(ca.age, 2);

    // Create with KVC-compatible object
    ca = [[CustomAccessorsObject alloc] initWithValue:ca];
    XCTAssertEqualObjects(ca.name, @"b");
    XCTAssertEqual(ca.age, 2);
}

- (void)testInitWithRenamedColumns {
    // Create with array
    auto obj = [[RenamedProperties1 alloc] initWithValue:@[@1, @"a"]];
    XCTAssertEqual(obj.propA, 1);
    XCTAssertEqualObjects(obj.propB, @"a");

    // Create with dictionary
    obj = [[RenamedProperties1 alloc] initWithValue:@{@"propB": @"b", @"propA": @2}];
    XCTAssertEqual(obj.propA, 2);
    XCTAssertEqualObjects(obj.propB, @"b");

    // Create with KVC-compatible object
    obj = [[RenamedProperties1 alloc] initWithValue:obj];
    XCTAssertEqual(obj.propA, 2);
    XCTAssertEqualObjects(obj.propB, @"b");
}

- (void)testInitAllPropertyTypes {
    auto now = [NSDate dateWithTimeIntervalSince1970:1];
    auto bytes = [NSData dataWithBytes:"a" length:1];
    auto so = [[StringObject alloc] init];
    so.stringCol = @"string";
    auto ao = [[AllTypesObject alloc] initWithValue:[AllTypesObject values:1 stringObject:so]];
    XCTAssertEqual(ao.boolCol, YES);
    XCTAssertEqual(ao.intCol, 1);
    XCTAssertEqual(ao.floatCol, 1.1f);
    XCTAssertEqual(ao.doubleCol, 1.11);
    XCTAssertEqualObjects(ao.stringCol, @"a");
    XCTAssertEqualObjects(ao.binaryCol, bytes);
    XCTAssertEqualObjects(ao.decimalCol, [[RLMDecimal128 alloc] initWithNumber:@(1)]);
    XCTAssertEqualObjects(ao.dateCol, now);
    XCTAssertEqual(ao.cBoolCol, true);
    XCTAssertEqual(ao.longCol, INT_MAX + 1LL);
    XCTAssertEqual(ao.objectCol, so);

    auto opt = [[AllOptionalTypes alloc] initWithValue:@[NSNull.null, NSNull.null,
                                                         NSNull.null, NSNull.null,
                                                         NSNull.null, NSNull.null,
                                                         NSNull.null]];
    XCTAssertNil(opt.intObj);
    XCTAssertNil(opt.boolObj);
    XCTAssertNil(opt.floatObj);
    XCTAssertNil(opt.doubleObj);
    XCTAssertNil(opt.date);
    XCTAssertNil(opt.data);
    XCTAssertNil(opt.string);

    opt = [[AllOptionalTypes alloc] initWithValue:@[@1, @2.2f, @3.3, @YES,
                                                    @"str", bytes, now]];
    XCTAssertEqualObjects(opt.intObj, @1);
    XCTAssertEqualObjects(opt.boolObj, @YES);
    XCTAssertEqualObjects(opt.floatObj, @2.2f);
    XCTAssertEqualObjects(opt.doubleObj, @3.3);
    XCTAssertEqualObjects(opt.date, now);
    XCTAssertEqualObjects(opt.data, bytes);
    XCTAssertEqualObjects(opt.string, @"str");

    auto arrays = [[AllPrimitiveArrays alloc] initWithValue:@{@"intObj": @[@1, @2, @3],
                                                              @"boolObj": @[@YES, @NO],
                                                              @"floatObj": @[@1.1f, @2.2f],
                                                              @"doubleObj": @[@3.3, @4.4],
                                                              @"stringObj": @[@"a", @"b"],
                                                              @"dateObj": @[now],
                                                              @"dataObj": @[bytes]}];
    XCTAssertEqual(3U, arrays.intObj.count);
    XCTAssertEqual(2U, arrays.boolObj.count);
    XCTAssertEqual(2U, arrays.floatObj.count);
    XCTAssertEqual(2U, arrays.doubleObj.count);
    XCTAssertEqual(2U, arrays.stringObj.count);
    XCTAssertEqual(1U, arrays.dateObj.count);
    XCTAssertEqual(1U, arrays.dataObj.count);

    XCTAssertEqualObjects([arrays.intObj valueForKey:@"self"], (@[@1, @2, @3]));
    XCTAssertEqualObjects([arrays.boolObj valueForKey:@"self"], (@[@YES, @NO]));
    XCTAssertEqualObjects([arrays.floatObj valueForKey:@"self"], (@[@1.1f, @2.2f]));
    XCTAssertEqualObjects([arrays.doubleObj valueForKey:@"self"], (@[@3.3, @4.4]));
    XCTAssertEqualObjects([arrays.stringObj valueForKey:@"self"], (@[@"a", @"b"]));
    XCTAssertEqualObjects([arrays.dateObj valueForKey:@"self"], (@[now]));
    XCTAssertEqualObjects([arrays.dataObj valueForKey:@"self"], (@[bytes]));

    auto sets = [[AllPrimitiveSets alloc] initWithValue:@{@"intObj": @[@1, @2, @3],
                                                          @"boolObj": @[@YES, @NO],
                                                          @"floatObj": @[@1.1f, @2.2f],
                                                          @"doubleObj": @[@3.3, @4.4],
                                                          @"stringObj": @[@"a", @"b"],
                                                          @"dateObj": @[now],
                                                          @"dataObj": @[bytes]}];
    XCTAssertEqual(3U, sets.intObj.count);
    XCTAssertEqual(2U, sets.boolObj.count);
    XCTAssertEqual(2U, sets.floatObj.count);
    XCTAssertEqual(2U, sets.doubleObj.count);
    XCTAssertEqual(2U, sets.stringObj.count);
    XCTAssertEqual(1U, sets.dateObj.count);
    XCTAssertEqual(1U, sets.dataObj.count);

    XCTAssertTrue([[NSSet setWithArray:[[sets.intObj valueForKey:@"self"] allObjects]] isEqualToSet:[NSSet setWithArray:(@[@1, @2, @3])]]);
    XCTAssertTrue([[NSSet setWithArray:[[sets.boolObj valueForKey:@"self"] allObjects]] isEqualToSet:[NSSet setWithArray:(@[@YES, @NO])]]);
    XCTAssertTrue([[NSSet setWithArray:[[sets.floatObj valueForKey:@"self"] allObjects]] isEqualToSet:[NSSet setWithArray:(@[@1.1f, @2.2f])]]);
    XCTAssertTrue([[NSSet setWithArray:[[sets.doubleObj valueForKey:@"self"] allObjects]] isEqualToSet:[NSSet setWithArray:(@[@3.3, @4.4])]]);
    XCTAssertTrue([[NSSet setWithArray:[[sets.stringObj valueForKey:@"self"] allObjects]] isEqualToSet:[NSSet setWithArray:(@[@"a", @"b"])]]);
    XCTAssertTrue([[NSSet setWithArray:[[sets.dateObj valueForKey:@"self"] allObjects]] isEqualToSet:[NSSet setWithArray:(@[now])]]);
    XCTAssertTrue([[NSSet setWithArray:[[sets.dataObj valueForKey:@"self"] allObjects]] isEqualToSet:[NSSet setWithArray:(@[bytes])]]);
}

- (void)testInitValidatesNumberTypes {
    XCTAssertNoThrow(([[NumberObject alloc] initWithValue:@{}]));
    RLMAssertThrowsWithReason(([[NumberObject alloc] initWithValue:@{@"intObj": @1.1}]),
                              @"Invalid value '1.1' of type '" RLMConstantDouble "' for 'int?' property 'NumberObject.intObj'.");
    RLMAssertThrowsWithReason(([[NumberObject alloc] initWithValue:@{@"intObj": @1.1f}]),
                              @"Invalid value '1.1' of type '" RLMConstantFloat "' for 'int?' property 'NumberObject.intObj'.");

    XCTAssertNoThrow(([[NumberObject alloc] initWithValue:@{@"boolObj": @YES}]));
    XCTAssertNoThrow(([[NumberObject alloc] initWithValue:@{@"boolObj": @1}]));
    XCTAssertNoThrow(([[NumberObject alloc] initWithValue:@{@"boolObj": @0}]));
    // This error is kinda bad....
    RLMAssertThrowsWithReason(([[NumberObject alloc] initWithValue:@{@"boolObj": @1.0}]),
                              @"Invalid value '1' of type '" RLMConstantDouble "' for 'bool?' property 'NumberObject.boolObj'.");
    RLMAssertThrowsWithReason(([[NumberObject alloc] initWithValue:@{@"boolObj": @1.0f}]),
                              @"Invalid value '1' of type '" RLMConstantFloat "' for 'bool?' property 'NumberObject.boolObj'.");
    RLMAssertThrowsWithReason(([[NumberObject alloc] initWithValue:@{@"boolObj": @2}]),
                              @"Invalid value '2' of type '" RLMConstantInt "' for 'bool?' property 'NumberObject.boolObj'.");

    XCTAssertNoThrow(([[NumberObject alloc] initWithValue:@{@"floatObj": @1.1}]));
    RLMAssertThrowsWithReasonMatching(([[NumberObject alloc] initWithValue:@{@"floatObj": @DBL_MAX}]),
                                      @"Invalid value '.*' of type '" RLMConstantDouble "' for 'float\\?' property 'NumberObject.floatObj'");

    XCTAssertNoThrow(([[NumberObject alloc] initWithValue:@{@"doubleObj": @DBL_MAX}]));
}

- (void)testInitEmbeddedProperty {
    NSArray *failVal = @[@{}, @{}, @{}, @{@"one": [[IntObject alloc] init]}];
    XCTAssertThrows([[DictionaryPropertyObject alloc] initWithValue:failVal]);
    
    NSArray *passVal = @[@{}, @{}, @{}, @{@"one": [[EmbeddedIntObject alloc] init]}];
    XCTAssertNoThrow([[DictionaryPropertyObject alloc] initWithValue:passVal]);
}

#pragma mark - Create

- (void)testCreateWithArray {
    auto realm = RLMRealm.defaultRealm;
    [realm beginWriteTransaction];

    auto co = [CompanyObject createInRealm:realm withValue:@[@"empty company", NSNull.null, NSNull.null]];
    XCTAssertEqualObjects(co.name, @"empty company");
    XCTAssertEqual(co.employees.count, 0U);
    XCTAssertEqual(co.employeeSet.count, 0U);

    co = [CompanyObject createInRealm:realm withValue:@[@"empty company", @[], @[]]];
    XCTAssertEqualObjects(co.name, @"empty company");
    XCTAssertEqual(co.employees.count, 0U);
    XCTAssertEqual(co.employeeSet.count, 0U);

    co = [CompanyObject createInRealm:realm withValue:@[@"one employee",
                                                        @[@[@"name", @2, @YES]],
                                                        @[@[@"name", @2, @YES]]]];
    XCTAssertEqualObjects(co.name, @"one employee");
    XCTAssertEqual(co.employees.count, 1U);
    XCTAssertEqual(co.employeeSet.count, 1U);
    EmployeeObject *eo = co.employees.firstObject;
    XCTAssertEqualObjects(eo.name, @"name");
    XCTAssertEqual(eo.age, 2);
    XCTAssertEqual(eo.hired, YES);
    eo = co.employeeSet.allObjects[0];
    XCTAssertEqualObjects(eo.name, @"name");
    XCTAssertEqual(eo.age, 2);
    XCTAssertEqual(eo.hired, YES);

    [realm cancelWriteTransaction];
}

- (void)testCreateWithInvalidArray {
    auto realm = RLMRealm.defaultRealm;
    [realm beginWriteTransaction];

    RLMAssertThrowsWithReason(([DogObject createInRealm:realm withValue:@[@"name", @"age"]]),
                              @"Invalid value 'age' of type '__NSCFConstantString' for 'int' property 'DogObject.age'");
    RLMAssertThrowsWithReason(([DogObject createInRealm:realm withValue:@[@"name", NSNull.null]]),
                              @"Invalid value '<null>' of type 'NSNull' for 'int' property 'DogObject.age'");
    RLMAssertThrowsWithReason(([DogObject createInRealm:realm withValue:@[@"name", @5, @"too many values"]]),
                              @"Invalid array input: more values (3) than properties (2).");
    RLMAssertThrowsWithReason(([PrimaryStringObject createInRealm:realm withValue:@[]]),
                              @"Missing value for property 'PrimaryStringObject.stringCol'");

    [realm cancelWriteTransaction];
}

- (void)testCreateWithDictionary {
    auto realm = RLMRealm.defaultRealm;
    [realm beginWriteTransaction];

    auto co = [CompanyObject createInRealm:realm withValue:@{}];
    XCTAssertNil(co.name);
    XCTAssertEqual(co.employees.count, 0U);

    co = [CompanyObject createInRealm:realm withValue:@{@"name": NSNull.null}];
    XCTAssertNil(co.name);
    XCTAssertEqual(co.employees.count, 0U);

    co = [CompanyObject createInRealm:realm withValue:@{@"name": @"empty company"}];
    XCTAssertEqualObjects(co.name, @"empty company");
    XCTAssertEqual(co.employees.count, 0U);

    co = [CompanyObject createInRealm:realm withValue:@{@"name": @"empty company",
                                                        @"employees": NSNull.null,
                                                        @"employeeSet": NSNull.null}];
    XCTAssertEqualObjects(co.name, @"empty company");
    XCTAssertEqual(co.employees.count, 0U);
    XCTAssertEqual(co.employeeSet.count, 0U);

    co = [CompanyObject createInRealm:realm withValue:@{@"name": @"empty company",
                                                        @"employees": @[],
                                                        @"employeeSet": @[]}];
    XCTAssertEqualObjects(co.name, @"empty company");
    XCTAssertEqual(co.employees.count, 0U);
    XCTAssertEqual(co.employeeSet.count, 0U);

    co = [CompanyObject createInRealm:realm withValue:@{@"name": @"one employee",
                                                        @"employees": @[@[@"name", @2, @YES]],
                                                        @"employeeSet": @[@[@"name", @2, @YES]]}];
    XCTAssertEqualObjects(co.name, @"one employee");
    XCTAssertEqual(co.employees.count, 1U);
    XCTAssertEqual(co.employeeSet.count, 1U);
    EmployeeObject *eo = co.employees.firstObject;
    XCTAssertEqualObjects(eo.name, @"name");
    XCTAssertEqual(eo.age, 2);
    XCTAssertEqual(eo.hired, YES);
    eo = co.employeeSet.allObjects[0];
    XCTAssertEqualObjects(eo.name, @"name");
    XCTAssertEqual(eo.age, 2);
    XCTAssertEqual(eo.hired, YES);

    co = [CompanyObject createInRealm:realm withValue:@{@"name": @"one employee",
                                                        @"employees": @[@{@"name": @"name",
                                                                          @"age": @2,
                                                                          @"hired": @YES}],
                                                        @"employeeSet": @[@{@"name": @"name",
                                                                          @"age": @2,
                                                                          @"hired": @YES}]}];
    XCTAssertEqualObjects(co.name, @"one employee");
    XCTAssertEqual(co.employees.count, 1U);
    XCTAssertEqual(co.employeeSet.count, 1U);
    eo = co.employees.firstObject;
    XCTAssertEqualObjects(eo.name, @"name");
    XCTAssertEqual(eo.age, 2);
    XCTAssertEqual(eo.hired, YES);
    eo = co.employeeSet.allObjects[0];
    XCTAssertEqualObjects(eo.name, @"name");
    XCTAssertEqual(eo.age, 2);
    XCTAssertEqual(eo.hired, YES);

    co = [CompanyObject createInRealm:realm withValue:@{@"name": @"no employees",
                                                        @"extra fields": @"are okay"}];
    XCTAssertEqualObjects(co.name, @"no employees");
    XCTAssertEqual(co.employees.count, 0U);
    XCTAssertEqual(co.employeeSet.count, 0U);

    [realm cancelWriteTransaction];
}

- (void)testCreateWithInvalidDictionary {
    auto realm = RLMRealm.defaultRealm;
    [realm beginWriteTransaction];

    RLMAssertThrowsWithReason(([DogObject createInRealm:realm withValue:@{@"name": @"a", @"age": NSNull.null}]),
                              @"Invalid value '<null>' of type 'NSNull' for 'int' property 'DogObject.age'");
    RLMAssertThrowsWithReasonMatching(([DogObject createInRealm:realm withValue:@{@"name": @"a", @"age": NSDate.date}]),
                                      @"Invalid value '20.*' for 'int' property 'DogObject.age'");
    [realm cancelWriteTransaction];
}

- (void)testCreateWithObject {
    auto realm = RLMRealm.defaultRealm;
    [realm beginWriteTransaction];

    auto eo = [[EmployeeObject alloc] init];
    eo.name = @"employee name";
    eo.age = 1;
    eo.hired = NO;

    auto co = [[CompanyObject alloc] init];
    co.name = @"name";
    [co.employees addObject:eo];
    [co.employeeSet addObject:eo];

    auto co2 = [CompanyObject createInRealm:realm withValue:co];
    XCTAssertEqualObjects(co.name, co2.name);
    // Deep copy, so it's a different object
    XCTAssertFalse([co.employees[0] isEqualToObject:co2.employees[0]]);
    XCTAssertEqualObjects(co.employees[0].name, co2.employees[0].name);
    XCTAssertFalse([co.employeeSet.allObjects[0] isEqualToObject:co2.employeeSet.allObjects[0]]);
    XCTAssertEqualObjects(co.employeeSet.allObjects[0].name, co2.employeeSet.allObjects[0].name);

    auto dogExt = [DogExtraObject createInRealm:realm withValue:@[@"Fido", @12, @"Poodle"]];
    auto dog = [DogObject createInRealm:realm withValue:dogExt];
    XCTAssertEqualObjects(dog.dogName, @"Fido");
    XCTAssertEqual(dog.age, 12);

    auto owner = [OwnerObject createInRealm:realm withValue:@[@"Alex", dogExt]];
    XCTAssertEqualObjects(owner.dog.dogName, @"Fido");

    [realm cancelWriteTransaction];
}

- (void)testCreateWithInvalidObject {
    auto realm = RLMRealm.defaultRealm;
    [realm beginWriteTransaction];

    RLMAssertThrowsWithReasonMatching([DogObject createInRealm:realm withValue:self.nonLiteralNil],
                                      @"Must provide a non-nil value");
    RLMAssertThrowsWithReasonMatching([DogObject createInRealm:realm withValue:NSNull.null],
                                      @"Must provide a non-nil value");
    RLMAssertThrowsWithReasonMatching([DogObject createInRealm:realm withValue:@""],
                                      @"Invalid value '' to initialize object of type 'DogObject'");

    // No overlap in properties
    auto so = [StringObject createInRealm:realm withValue:@[@"str"]];
    RLMAssertThrowsWithReasonMatching([IntObject createInRealm:realm withValue:so], @"missing key 'intCol'");

    // Dog has some but not all of DogExtra's properties
    auto dog = [DogObject createInRealm:realm withValue:@[@"Fido", @10]];
    RLMAssertThrowsWithReasonMatching([DogExtraObject createInRealm:realm withValue:dog],
                                      @"missing key 'breed'");

    // Same property names, but different types
    RLMAssertThrowsWithReasonMatching([BizzaroDog createInRealm:realm withValue:dog],
                                      @"Invalid value 'Fido' of type '.*' for 'int' property 'BizzaroDog.dogName'");

    [realm cancelWriteTransaction];
}

- (void)testCreateAllPropertyTypes {
    auto realm = RLMRealm.defaultRealm;
    [realm beginWriteTransaction];

    auto now = [NSDate dateWithTimeIntervalSince1970:1];
    auto bytes = [NSData dataWithBytes:"a" length:1];
    auto so = [[StringObject alloc] init];
    so.stringCol = @"string";
    auto ao = [AllTypesObject createInRealm:realm withValue:[AllTypesObject values:1 stringObject:so]];
    XCTAssertEqual(ao.boolCol, YES);
    XCTAssertEqual(ao.intCol, 1);
    XCTAssertEqual(ao.floatCol, 1.1f);
    XCTAssertEqual(ao.doubleCol, 1.11);
    XCTAssertEqualObjects(ao.stringCol, @"a");
    XCTAssertEqualObjects(ao.binaryCol, bytes);
    XCTAssertEqualObjects(ao.dateCol, now);
    XCTAssertEqual(ao.cBoolCol, true);
    XCTAssertEqual(ao.longCol, INT_MAX + 1LL);
    XCTAssertNotEqual(ao.objectCol, so);
    XCTAssertEqualObjects(ao.objectCol.stringCol, @"string");

    auto opt = [AllOptionalTypes createInRealm:realm withValue:@[NSNull.null, NSNull.null,
                                                                 NSNull.null, NSNull.null,
                                                                 NSNull.null, NSNull.null,
                                                                 NSNull.null]];
    XCTAssertNil(opt.intObj);
    XCTAssertNil(opt.boolObj);
    XCTAssertNil(opt.floatObj);
    XCTAssertNil(opt.doubleObj);
    XCTAssertNil(opt.date);
    XCTAssertNil(opt.data);
    XCTAssertNil(opt.string);

    opt = [AllOptionalTypes createInRealm:realm withValue:@[@1, @2.2f, @3.3, @YES,
                                                            @"str", bytes, now]];
    XCTAssertEqualObjects(opt.intObj, @1);
    XCTAssertEqualObjects(opt.boolObj, @YES);
    XCTAssertEqualObjects(opt.floatObj, @2.2f);
    XCTAssertEqualObjects(opt.doubleObj, @3.3);
    XCTAssertEqualObjects(opt.date, now);
    XCTAssertEqualObjects(opt.data, bytes);
    XCTAssertEqualObjects(opt.string, @"str");

    [realm cancelWriteTransaction];
}

- (void)testCreateRequiredPrimitiveArrays {
    auto realm = RLMRealm.defaultRealm;
    [realm beginWriteTransaction];

    auto now = [NSDate date];
    auto bytes = [NSData dataWithBytes:"a" length:1];
    auto req = [AllPrimitiveArrays createInRealm:realm
                                       withValue:@{@"intObj": @[@1, @2, @3],
                                                   @"boolObj": @[@YES, @NO],
                                                   @"floatObj": @[@1.1f, @2.2f],
                                                   @"doubleObj": @[@3.3, @4.4],
                                                   @"stringObj": @[@"a", @"b"],
                                                   @"dateObj": @[now],
                                                   @"dataObj": @[bytes]}];
    XCTAssertEqual(3U, req.intObj.count);
    XCTAssertEqual(2U, req.boolObj.count);
    XCTAssertEqual(2U, req.floatObj.count);
    XCTAssertEqual(2U, req.doubleObj.count);
    XCTAssertEqual(2U, req.stringObj.count);
    XCTAssertEqual(1U, req.dateObj.count);
    XCTAssertEqual(1U, req.dataObj.count);

    XCTAssertEqualObjects([req.intObj valueForKey:@"self"], (@[@1, @2, @3]));
    XCTAssertEqualObjects([req.boolObj valueForKey:@"self"], (@[@YES, @NO]));
    XCTAssertEqualObjects([req.floatObj valueForKey:@"self"], (@[@1.1f, @2.2f]));
    XCTAssertEqualObjects([req.doubleObj valueForKey:@"self"], (@[@3.3, @4.4]));
    XCTAssertEqualObjects([req.stringObj valueForKey:@"self"], (@[@"a", @"b"]));
    XCTAssertEqualObjects([req.dateObj valueForKey:@"self"], (@[now]));
    XCTAssertEqualObjects([req.dataObj valueForKey:@"self"], (@[bytes]));

    [realm cancelWriteTransaction];
}

- (void)testCreateRequiredPrimitiveSets {
    auto realm = RLMRealm.defaultRealm;
    [realm beginWriteTransaction];

    auto now = [NSDate date];
    auto bytes = [NSData dataWithBytes:"a" length:1];
    auto req = [AllPrimitiveSets createInRealm:realm
                                     withValue:@{@"intObj": @[@1, @2, @3],
                                                 @"boolObj": @[@YES, @NO],
                                                 @"floatObj": @[@1.1f, @2.2f],
                                                 @"doubleObj": @[@3.3, @4.4],
                                                 @"stringObj": @[@"a", @"b"],
                                                 @"dateObj": @[now],
                                                 @"dataObj": @[bytes]}];
    XCTAssertEqual(3U, req.intObj.count);
    XCTAssertEqual(2U, req.boolObj.count);
    XCTAssertEqual(2U, req.floatObj.count);
    XCTAssertEqual(2U, req.doubleObj.count);
    XCTAssertEqual(2U, req.stringObj.count);
    XCTAssertEqual(1U, req.dateObj.count);
    XCTAssertEqual(1U, req.dataObj.count);

    XCTAssertEqualObjects([req.intObj valueForKey:@"self"], ([NSSet setWithArray:@[@1, @2, @3]]));
    XCTAssertEqualObjects([req.boolObj valueForKey:@"self"], ([NSSet setWithArray:@[@NO, @YES]]));
    XCTAssertEqualObjects([req.floatObj valueForKey:@"self"], ([NSSet setWithArray:@[@1.1f, @2.2f]]));
    XCTAssertEqualObjects([req.doubleObj valueForKey:@"self"], ([NSSet setWithArray:@[@3.3, @4.4]]));
    XCTAssertEqualObjects([req.stringObj valueForKey:@"self"], ([NSSet setWithArray:@[@"a", @"b"]]));
    XCTAssertEqualObjects([req.dateObj valueForKey:@"self"], ([NSSet setWithArray:@[now]]));
    XCTAssertEqualObjects([req.dataObj valueForKey:@"self"], ([NSSet setWithArray:@[bytes]]));

    [realm cancelWriteTransaction];
}

#if 0
- (void)testCreateRequiredPrimitiveArraysWithNonNSArrayEnumerable {
    auto realm = RLMRealm.defaultRealm;
    [realm beginWriteTransaction];

    auto now = [NSDate date];
    auto bytes = [NSData dataWithBytes:"a" length:1];
    auto req = [AllPrimitiveArrays createInRealm:realm
                                       withValue:@{@"intObj": @[@1, @2, @3].reverseObjectEnumerator,
                                                   @"boolObj": @[@YES, @NO].reverseObjectEnumerator,
                                                   @"floatObj": @[@1.1f, @2.2f].reverseObjectEnumerator,
                                                   @"doubleObj": @[@3.3, @4.4].reverseObjectEnumerator,
                                                   @"stringObj": @[@"a", @"b"].reverseObjectEnumerator,
                                                   @"dateObj": @[now].reverseObjectEnumerator,
                                                   @"dataObj": @[bytes].reverseObjectEnumerator}];
    XCTAssertEqual(3U, req.intObj.count);
    XCTAssertEqual(2U, req.boolObj.count);
    XCTAssertEqual(2U, req.floatObj.count);
    XCTAssertEqual(2U, req.doubleObj.count);
    XCTAssertEqual(2U, req.stringObj.count);
    XCTAssertEqual(1U, req.dateObj.count);
    XCTAssertEqual(1U, req.dataObj.count);

    XCTAssertEqualObjects([req.intObj valueForKey:@"self"], (@[@3, @2, @1]));
    XCTAssertEqualObjects([req.boolObj valueForKey:@"self"], (@[@NO, @YES]));
    XCTAssertEqualObjects([req.floatObj valueForKey:@"self"], (@[@2.2f, @1.1f]));
    XCTAssertEqualObjects([req.doubleObj valueForKey:@"self"], (@[@4.4, @3.3]));
    XCTAssertEqualObjects([req.stringObj valueForKey:@"self"], (@[@"b", @"a"]));
    XCTAssertEqualObjects([req.dateObj valueForKey:@"self"], (@[now]));
    XCTAssertEqualObjects([req.dataObj valueForKey:@"self"], (@[bytes]));

    [realm cancelWriteTransaction];
}
#endif

- (void)testCreatePrimitiveArraysWithNSNull {
    auto realm = RLMRealm.defaultRealm;
    [realm beginWriteTransaction];

    auto req = [AllPrimitiveArrays createInRealm:realm
                                       withValue:@{@"intObj": NSNull.null,
                                                   @"boolObj": NSNull.null,
                                                   @"floatObj": NSNull.null,
                                                   @"doubleObj": NSNull.null,
                                                   @"stringObj": NSNull.null,
                                                   @"dateObj": NSNull.null,
                                                   @"dataObj": NSNull.null}];
    XCTAssertEqual(0U, req.intObj.count);
    XCTAssertEqual(0U, req.boolObj.count);
    XCTAssertEqual(0U, req.floatObj.count);
    XCTAssertEqual(0U, req.doubleObj.count);
    XCTAssertEqual(0U, req.stringObj.count);
    XCTAssertEqual(0U, req.dateObj.count);
    XCTAssertEqual(0U, req.dataObj.count);
}

- (void)testCreatePrimitiveSetsWithNSNull {
    auto realm = RLMRealm.defaultRealm;
    [realm beginWriteTransaction];

    auto req = [AllPrimitiveSets createInRealm:realm
                                     withValue:@{@"intObj": NSNull.null,
                                                 @"boolObj": NSNull.null,
                                                 @"floatObj": NSNull.null,
                                                 @"doubleObj": NSNull.null,
                                                 @"stringObj": NSNull.null,
                                                 @"dateObj": NSNull.null,
                                                 @"dataObj": NSNull.null}];
    XCTAssertEqual(0U, req.intObj.count);
    XCTAssertEqual(0U, req.boolObj.count);
    XCTAssertEqual(0U, req.floatObj.count);
    XCTAssertEqual(0U, req.doubleObj.count);
    XCTAssertEqual(0U, req.stringObj.count);
    XCTAssertEqual(0U, req.dateObj.count);
    XCTAssertEqual(0U, req.dataObj.count);
}

- (void)testCreatePrimitiveArraysWithMissingKeys {
    auto realm = RLMRealm.defaultRealm;
    [realm beginWriteTransaction];

    auto req = [AllPrimitiveArrays createInRealm:realm
                                       withValue:@{@"intObj": @[@1, @2, @2],
                                                   @"dataObj": NSNull.null}];
    XCTAssertEqual(3U, req.intObj.count);
    XCTAssertEqual(0U, req.boolObj.count);
    XCTAssertEqual(0U, req.floatObj.count);
    XCTAssertEqual(0U, req.doubleObj.count);
    XCTAssertEqual(0U, req.stringObj.count);
    XCTAssertEqual(0U, req.dateObj.count);
    XCTAssertEqual(0U, req.dataObj.count);
}

- (void)testCreatePrimitiveSetsWithMissingKeys {
    auto realm = RLMRealm.defaultRealm;
    [realm beginWriteTransaction];

    auto req = [AllPrimitiveSets createInRealm:realm
                                     withValue:@{@"intObj": @[@1, @2, @2],
                                                 @"dataObj": NSNull.null}];
    XCTAssertEqual(2U, req.intObj.count);
    XCTAssertEqual(0U, req.boolObj.count);
    XCTAssertEqual(0U, req.floatObj.count);
    XCTAssertEqual(0U, req.doubleObj.count);
    XCTAssertEqual(0U, req.stringObj.count);
    XCTAssertEqual(0U, req.dateObj.count);
    XCTAssertEqual(0U, req.dataObj.count);
}

- (void)testCreateRequiredPrimitiveArraysWithInvalidValues {
    auto realm = RLMRealm.defaultRealm;
    [realm beginWriteTransaction];

    RLMAssertThrowsWithReason([AllPrimitiveArrays createInRealm:realm
                                       withValue:@{@"intObj": @[NSNull.null]}],
                             @"Invalid value '<null>' of type 'NSNull' for 'int' array property 'AllPrimitiveArrays.intObj'.");
    RLMAssertThrowsWithReason([AllPrimitiveArrays createInRealm:realm
                                       withValue:@{@"intObj": @[@1.1]}],
                             @"Invalid value '1.1' of type '" RLMConstantDouble "' for 'int' array property 'AllPrimitiveArrays.intObj'.");
    RLMAssertThrowsWithReason([AllPrimitiveArrays createInRealm:realm
                                       withValue:@{@"intObj": @[@"0"]}],
                             @"Invalid value '0' of type '__NSCFConstantString' for 'int' array property 'AllPrimitiveArrays.intObj'.");
    RLMAssertThrowsWithReason([AllPrimitiveArrays createInRealm:realm
                                       withValue:@{@"intObj": @1}],
                             @"Invalid value (1) for 'int' array property 'AllPrimitiveArrays.intObj': value is not enumerable.");

    [realm cancelWriteTransaction];
}

- (void)testCreateRequiredPrimitiveSetsWithInvalidValues {
    auto realm = RLMRealm.defaultRealm;
    [realm beginWriteTransaction];

    RLMAssertThrowsWithReason([AllPrimitiveSets createInRealm:realm
                                       withValue:@{@"intObj": @[NSNull.null]}],
                             @"Invalid value '<null>' of type 'NSNull' for 'int' set property 'AllPrimitiveSets.intObj'.");
    RLMAssertThrowsWithReason([AllPrimitiveSets createInRealm:realm
                                       withValue:@{@"intObj": @[@1.1]}],
                             @"Invalid value '1.1' of type '" RLMConstantDouble "' for 'int' set property 'AllPrimitiveSets.intObj'.");
    RLMAssertThrowsWithReason([AllPrimitiveSets createInRealm:realm
                                       withValue:@{@"intObj": @[@"0"]}],
                             @"Invalid value '0' of type '" RLMConstantString "' for 'int' set property 'AllPrimitiveSets.intObj'.");
    RLMAssertThrowsWithReason([AllPrimitiveSets createInRealm:realm
                                       withValue:@{@"intObj": @1}],
                             @"Invalid value (1) for 'int' set property 'AllPrimitiveSets.intObj': value is not enumerable.");

    [realm cancelWriteTransaction];
}

- (void)testCreateOptionalPrimitiveArrays {
    auto realm = RLMRealm.defaultRealm;
    [realm beginWriteTransaction];

    auto now = [NSDate date];
    auto bytes = [NSData dataWithBytes:"a" length:1];
    auto req = [AllOptionalPrimitiveArrays createInRealm:realm
                                               withValue:@{@"intObj": @[@1, @2, @3, NSNull.null],
                                                           @"boolObj": @[@YES, @NO, NSNull.null],
                                                           @"floatObj": @[@1.1f, @2.2f, NSNull.null],
                                                           @"doubleObj": @[@3.3, @4.4, NSNull.null],
                                                           @"stringObj": @[@"a", @"b", NSNull.null],
                                                           @"dateObj": @[now, NSNull.null],
                                                           @"dataObj": @[bytes, NSNull.null],
                                                           @"uuidObj": @[[[NSUUID alloc] initWithUUIDString:@"137decc8-b300-4954-a233-f89909f4fd89"], [[NSUUID alloc] initWithUUIDString:@"00000000-0000-0000-0000-000000000000"]]}];
    XCTAssertEqual(4U, req.intObj.count);
    XCTAssertEqual(3U, req.boolObj.count);
    XCTAssertEqual(3U, req.floatObj.count);
    XCTAssertEqual(3U, req.doubleObj.count);
    XCTAssertEqual(3U, req.stringObj.count);
    XCTAssertEqual(2U, req.dateObj.count);
    XCTAssertEqual(2U, req.dataObj.count);

    XCTAssertEqualObjects([req.intObj valueForKey:@"self"], (@[@1, @2, @3, NSNull.null]));
    XCTAssertEqualObjects([req.boolObj valueForKey:@"self"], (@[@YES, @NO, NSNull.null]));
    XCTAssertEqualObjects([req.floatObj valueForKey:@"self"], (@[@1.1f, @2.2f, NSNull.null]));
    XCTAssertEqualObjects([req.doubleObj valueForKey:@"self"], (@[@3.3, @4.4, NSNull.null]));
    XCTAssertEqualObjects([req.stringObj valueForKey:@"self"], (@[@"a", @"b", NSNull.null]));
    XCTAssertEqualObjects([req.dateObj valueForKey:@"self"], (@[now, NSNull.null]));
    XCTAssertEqualObjects([req.dataObj valueForKey:@"self"], (@[bytes, NSNull.null]));

    [realm cancelWriteTransaction];
}

- (void)testCreateOptionalPrimitiveSets {
    auto realm = RLMRealm.defaultRealm;
    [realm beginWriteTransaction];

    auto now = [NSDate date];
    auto bytes = [NSData dataWithBytes:"a" length:1];
    auto req = [AllOptionalPrimitiveSets createInRealm:realm
                                             withValue:@{@"intObj": @[@1, @2, @3, NSNull.null],
                                                         @"boolObj": @[@YES, @NO, NSNull.null],
                                                         @"floatObj": @[@1.1f, @2.2f, NSNull.null],
                                                         @"doubleObj": @[@3.3, @4.4, NSNull.null],
                                                         @"stringObj": @[@"a", @"b", NSNull.null],
                                                         @"dateObj": @[now, NSNull.null],
                                                         @"dataObj": @[bytes, NSNull.null]}];
    XCTAssertEqual(4U, req.intObj.count);
    XCTAssertEqual(3U, req.boolObj.count);
    XCTAssertEqual(3U, req.floatObj.count);
    XCTAssertEqual(3U, req.doubleObj.count);
    XCTAssertEqual(3U, req.stringObj.count);
    XCTAssertEqual(2U, req.dateObj.count);
    XCTAssertEqual(2U, req.dataObj.count);

    XCTAssertEqualObjects([req.intObj valueForKey:@"self"], ([NSSet setWithArray:@[NSNull.null, @1, @2, @3]]));
    XCTAssertEqualObjects([req.boolObj valueForKey:@"self"], ([NSSet setWithArray:@[NSNull.null, @NO, @YES]]));
    XCTAssertEqualObjects([req.floatObj valueForKey:@"self"], ([NSSet setWithArray:@[NSNull.null, @1.1f, @2.2f]]));
    XCTAssertEqualObjects([req.doubleObj valueForKey:@"self"], ([NSSet setWithArray:@[NSNull.null, @3.3, @4.4]]));
    XCTAssertEqualObjects([req.stringObj valueForKey:@"self"], ([NSSet setWithArray:@[NSNull.null, @"a", @"b"]]));
    XCTAssertEqualObjects([req.dateObj valueForKey:@"self"], ([NSSet setWithArray:@[NSNull.null, now]]));
    XCTAssertEqualObjects([req.dataObj valueForKey:@"self"], ([NSSet setWithArray:@[NSNull.null, bytes]]));

    [realm cancelWriteTransaction];
}

- (void)testCreateOptionalPrimitiveArraysWithInvalidValues {
    auto realm = RLMRealm.defaultRealm;
    [realm beginWriteTransaction];

    RLMAssertThrowsWithReasonMatching([AllOptionalPrimitiveArrays createInRealm:realm
                                                                      withValue:@{@"intObj": @[@1.1]}],
                                      @"Invalid value '1.1' of type '.*NS.*Number' for 'int\\?' array property 'AllOptionalPrimitiveArrays.intObj'.");
    RLMAssertThrowsWithReason([AllOptionalPrimitiveArrays createInRealm:realm
                                                              withValue:@{@"intObj": @[@"0"]}],
                              @"Invalid value '0' of type '__NSCFConstantString' for 'int?' array property 'AllOptionalPrimitiveArrays.intObj'.");
    RLMAssertThrowsWithReason([AllOptionalPrimitiveArrays createInRealm:realm
                                                              withValue:@{@"intObj": @1}],
                              @"Invalid value (1) for 'int?' array property 'AllOptionalPrimitiveArrays.intObj': value is not enumerable.");
}

- (void)testCreateOptionalPrimitiveSetsWithInvalidValues {
    auto realm = RLMRealm.defaultRealm;
    [realm beginWriteTransaction];

    RLMAssertThrowsWithReason([AllOptionalPrimitiveSets createInRealm:realm
                                                            withValue:@{@"intObj": @[@1.1]}],
                              @"Invalid value '1.1' of type '" RLMConstantDouble "' for 'int?' set property 'AllOptionalPrimitiveSets.intObj'.");
    RLMAssertThrowsWithReason([AllOptionalPrimitiveSets createInRealm:realm
                                                            withValue:@{@"intObj": @[@"0"]}],
                              @"Invalid value '0' of type '" RLMConstantString "' for 'int?' set property 'AllOptionalPrimitiveSets.intObj'.");
    RLMAssertThrowsWithReason([AllOptionalPrimitiveSets createInRealm:realm
                                                            withValue:@{@"intObj": @1}],
                              @"Invalid value (1) for 'int?' set property 'AllOptionalPrimitiveSets.intObj': value is not enumerable.");
}

- (void)testCreateUsesDefaultValuesForMissingDictionaryKeys {
    auto realm = [RLMRealm defaultRealm];
    [realm beginWriteTransaction];

    auto obj = [NumberDefaultsObject createInRealm:realm withValue:@{}];
    XCTAssertEqualObjects(obj.intObj, @1);
    XCTAssertEqualObjects(obj.floatObj, @2.2f);
    XCTAssertEqualObjects(obj.doubleObj, @3.3);
    XCTAssertEqualObjects(obj.boolObj, @NO);

    obj = [NumberDefaultsObject createInRealm:realm withValue:@{@"intObj": @10}];
    XCTAssertEqualObjects(obj.intObj, @10);
    XCTAssertEqualObjects(obj.floatObj, @2.2f);
    XCTAssertEqualObjects(obj.doubleObj, @3.3);
    XCTAssertEqualObjects(obj.boolObj, @NO);

    [realm cancelWriteTransaction];
}

- (void)testCreateOnManagedObjectInSameRealmShallowCopies {
    auto realm = [RLMRealm defaultRealm];
    [realm beginWriteTransaction];

    auto so = [StringObject createInRealm:realm withValue:@[@"str"]];
    auto pso = [PrimaryStringObject createInRealm:realm withValue:@[@"pk", @1]];
    auto io = [IntObject createInRealm:realm withValue:@[@2]];
    auto pio = [PrimaryIntObject createInRealm:realm withValue:@[@3]];

    auto links = [AllLinks createInRealm:realm withValue:@[so, pso, @[io, io], @[pio, pio]]];
    auto copy = [AllLinks createInRealm:realm withValue:links];

    XCTAssertEqual(2U, [AllLinks allObjectsInRealm:realm].count);
    XCTAssertEqual(1U, [StringObject allObjectsInRealm:realm].count);
    XCTAssertEqual(1U, [PrimaryStringObject allObjectsInRealm:realm].count);
    XCTAssertEqual(1U, [IntObject allObjectsInRealm:realm].count);
    XCTAssertEqual(1U, [PrimaryIntObject allObjectsInRealm:realm].count);

    XCTAssertTrue([links.string isEqualToObject:so]);
    XCTAssertTrue([copy.string isEqualToObject:so]);
    XCTAssertTrue([links.primaryString isEqualToObject:pso]);
    XCTAssertTrue([copy.primaryString isEqualToObject:pso]);

    [realm cancelWriteTransaction];
}

- (void)testCreateOnManagedObjectInDifferentRealmDeepCopies {
    auto realm = [RLMRealm defaultRealm];
    [realm beginWriteTransaction];
    auto realm2 = [self realmWithTestPath];
    [realm2 beginWriteTransaction];

    auto so = [StringObject createInRealm:realm withValue:@[@"str"]];
    auto pso = [PrimaryStringObject createInRealm:realm withValue:@[@"pk", @1]];
    auto io = [IntObject createInRealm:realm withValue:@[@2]];
    auto pio = [PrimaryIntObject createInRealm:realm withValue:@[@3]];

    auto links = [AllLinks createInRealm:realm withValue:@[so, pso, @[io, io], @[pio]]];
    [AllLinks createInRealm:realm2 withValue:links];

    XCTAssertEqual(1U, [AllLinks allObjectsInRealm:realm2].count);
    XCTAssertEqual(1U, [StringObject allObjectsInRealm:realm2].count);
    XCTAssertEqual(1U, [PrimaryStringObject allObjectsInRealm:realm2].count);
    XCTAssertEqual(2U, [IntObject allObjectsInRealm:realm2].count);
    XCTAssertEqual(1U, [PrimaryIntObject allObjectsInRealm:realm2].count);

    [realm cancelWriteTransaction];
    [realm2 cancelWriteTransaction];
}

- (void)testCreateOnManagedObjectInDifferentRealmDoesntReallyWorkUsefullyWithLinkedPKs {
    auto realm = [RLMRealm defaultRealm];
    [realm beginWriteTransaction];
    auto realm2 = [self realmWithTestPath];
    [realm2 beginWriteTransaction];

    auto pio = [PrimaryIntObject createInRealm:realm withValue:@[@3]];
    auto links = [AllLinks createInRealm:realm withValue:@[NSNull.null, NSNull.null, NSNull.null, @[pio, pio]]];
    RLMAssertThrowsWithReason([AllLinks createInRealm:realm2 withValue:links],
                              @"existing primary key value '3'");

    [realm cancelWriteTransaction];
    [realm2 cancelWriteTransaction];
}

- (void)testCreateWithInvalidatedObject {
    auto realm = [RLMRealm defaultRealm];

    [realm beginWriteTransaction];
    auto obj1 = [IntObject createInRealm:realm withValue:@[@0]];
    auto obj2 = [IntObject createInRealm:realm withValue:@[@1]];
    id obj1alias = [IntObject allObjectsInRealm:realm].firstObject;

    [realm deleteObject:obj1];
    RLMAssertThrowsWithReasonMatching([IntObject createInRealm:realm withValue:obj1],
                                      @"Object has been deleted or invalidated.");
    RLMAssertThrowsWithReasonMatching([IntObject createInRealm:realm withValue:obj1alias],
                                      @"Object has been deleted or invalidated.");

    [realm commitWriteTransaction];
    [realm invalidate];
    [realm beginWriteTransaction];
    RLMAssertThrowsWithReasonMatching([IntObject createInRealm:realm withValue:obj2],
                                      @"Object has been deleted or invalidated.");
    [realm cancelWriteTransaction];
}

- (void)testCreateOutsideWriteTransaction {
    auto realm = [RLMRealm defaultRealm];
    RLMAssertThrowsWithReasonMatching([IntObject createInRealm:realm withValue:@[@0]],
                                      @"call beginWriteTransaction");
}

- (void)testCreateInNilRealm {
    RLMAssertThrowsWithReasonMatching(([IntObject createInRealm:self.nonLiteralNil withValue:@[@0]]),
                                      @"Realm must not be nil");
}

- (void)testCreatingObjectWithoutAnyPropertiesWorks {
    @autoreleasepool {
        auto realm = [RLMRealm defaultRealm];
        [realm beginWriteTransaction];
        [AbstractObject createInRealm:realm withValue:@[]];
        [realm commitWriteTransaction];
    }
    auto realm = [RLMRealm defaultRealm];
    XCTAssertEqual(1U, [AbstractObject allObjectsInRealm:realm].count);
}

- (void)testCreateWithNonEnumerableValueForArrayProperty {
    auto realm = [RLMRealm defaultRealm];
    [realm beginWriteTransaction];
    RLMAssertThrowsWithReason(([CompanyObject createInRealm:realm withValue:@[@"one employee", @1]]),
                              @"Invalid value (1) for 'EmployeeObject' array property 'CompanyObject.employees': value is not enumerable.");
    RLMAssertThrowsWithReason(([CompanyObject createInRealm:realm withValue:@[@"one employee", @[], @1]]),
                              @"Invalid value (1) for 'EmployeeObject' set property 'CompanyObject.employeeSet': value is not enumerable.");
    [realm cancelWriteTransaction];
}

- (void)testCreateWithNonArrayEnumerableValueForArrayProperty {
    auto realm = [RLMRealm defaultRealm];
    [realm beginWriteTransaction];

    auto employees = @[@[@"name", @2, @YES], @[@"name 2", @3, @NO]];
    auto co = [CompanyObject createInRealm:realm withValue:@[@"one employee",
                                                             employees.reverseObjectEnumerator,
                                                             employees.reverseObjectEnumerator]];
    XCTAssertEqual(2U, co.employees.count);
    XCTAssertEqualObjects(@"name 2", co.employees[0].name);
    XCTAssertEqualObjects(@"name", co.employees[1].name);
    XCTAssertEqual(2U, co.employeeSet.count);
    XCTAssertTrue([[co.employeeSet valueForKey:@"name"] containsObject:@"name 2"]);
    XCTAssertTrue([[co.employeeSet valueForKey:@"name"] containsObject:@"name"]);

    [realm cancelWriteTransaction];
}

- (void)testCreateWithCustomAccessors {
    auto realm = [RLMRealm defaultRealm];
    [realm beginWriteTransaction];

    // Create with array
    auto ca = [CustomAccessorsObject createInRealm:realm withValue:@[@"a", @1]];
    XCTAssertEqualObjects(ca.name, @"a");
    XCTAssertEqual(ca.age, 1);

    // Create with dictionary
    ca = [CustomAccessorsObject createInRealm:realm withValue:@{@"name": @"b", @"age": @2}];
    XCTAssertEqualObjects(ca.name, @"b");
    XCTAssertEqual(ca.age, 2);

    // Create with KVC-compatible object
    auto ca2 = [CustomAccessorsObject createInRealm:realm withValue:ca];
    XCTAssertEqualObjects(ca2.name, @"b");
    XCTAssertEqual(ca2.age, 2);

    [realm cancelWriteTransaction];
}

- (void)testCreateWithRenamedColumns {
    auto realm = [RLMRealm defaultRealm];
    [realm beginWriteTransaction];

    // Create with array
    auto obj = [RenamedProperties1 createInRealm:realm withValue:@[@1, @"a"]];
    XCTAssertEqual(obj.propA, 1);
    XCTAssertEqualObjects(obj.propB, @"a");

    // Create with dictionary
    obj = [RenamedProperties1 createInRealm:realm withValue:@{@"propB": @"b", @"propA": @2}];
    XCTAssertEqual(obj.propA, 2);
    XCTAssertEqualObjects(obj.propB, @"b");

    // Create with KVC-compatible object
    obj = [RenamedProperties1 createInRealm:realm withValue:obj];
    XCTAssertEqual(obj.propA, 2);
    XCTAssertEqualObjects(obj.propB, @"b");

    // Verify that they're all readable via the other class
    RLMResults<RenamedProperties2 *> *results = [RenamedProperties2 allObjectsInRealm:realm];
    XCTAssertEqual(results[0].propC, 1);
    XCTAssertEqualObjects(results[0].propD, @"a");
    XCTAssertEqual(results[1].propC, 2);
    XCTAssertEqualObjects(results[1].propD, @"b");
    XCTAssertEqual(results[2].propC, 2);
    XCTAssertEqualObjects(results[2].propD, @"b");

    [realm cancelWriteTransaction];
}

#pragma mark - Create Or Update

- (void)testCreateOrUpdateWithoutPKThrows {
    auto realm = [RLMRealm defaultRealm];
    [realm beginWriteTransaction];
    RLMAssertThrowsWithReason([DogObject createOrUpdateInRealm:realm withValue:@[]],
                              @"'DogObject' does not have a primary key");
    [realm cancelWriteTransaction];
}

- (void)testCreateOrUpdateUpdatesExistingItemWithSamePK {
    auto realm = [RLMRealm defaultRealm];
    [realm beginWriteTransaction];

    auto so = [PrimaryStringObject createOrUpdateInRealm:realm withValue:@[@"pk", @2]];
    XCTAssertEqual(1U, [PrimaryStringObject allObjectsInRealm:realm].count);
    XCTAssertEqual(so.intCol, 2);

    auto so2 = [PrimaryStringObject createOrUpdateInRealm:realm withValue:@[@"pk", @3]];
    XCTAssertEqual(1U, [PrimaryStringObject allObjectsInRealm:realm].count);
    XCTAssertEqual(so.intCol, 3);
    XCTAssertEqualObjects(so, so2);

    [realm cancelWriteTransaction];
}

- (void)testCreateOrUpdateWithNullPrimaryKey {
    RLMRealm *realm = [RLMRealm defaultRealm];
    [realm beginWriteTransaction];

    [PrimaryNullableStringObject createOrUpdateInRealm:realm withValue:@{@"intCol": @5}];
    [PrimaryNullableStringObject createOrUpdateInRealm:realm withValue:@{@"intCol": @7}];
    XCTAssertEqual([PrimaryNullableStringObject objectInRealm:realm forPrimaryKey:NSNull.null].intCol, 7);
    [PrimaryNullableStringObject createOrUpdateInRealm:realm withValue:@{@"stringCol": NSNull.null, @"intCol": @11}];
    XCTAssertEqual([PrimaryNullableStringObject objectInRealm:realm forPrimaryKey:nil].intCol, 11);

    [PrimaryNullableIntObject createOrUpdateInRealm:realm withValue:@{@"value": @5}];
    [PrimaryNullableIntObject createOrUpdateInRealm:realm withValue:@{@"value": @7}];
    XCTAssertEqual([PrimaryNullableIntObject objectInRealm:realm forPrimaryKey:NSNull.null].value, 7);
    [PrimaryNullableIntObject createOrUpdateInRealm:realm withValue:@{@"optIntCol": NSNull.null, @"value": @11}];
    XCTAssertEqual([PrimaryNullableIntObject objectInRealm:realm forPrimaryKey:nil].value, 11);

    [realm cancelWriteTransaction];
}

- (void)testCreateOrUpdateDoesNotModifyKeysNotPresent {
    auto realm = [RLMRealm defaultRealm];
    [realm beginWriteTransaction];

    auto so = [PrimaryStringObject createOrUpdateInRealm:realm withValue:@[@"pk", @2]];
    auto so2 = [PrimaryStringObject createOrUpdateInRealm:realm withValue:@{@"stringCol": @"pk"}];
    XCTAssertEqual(1U, [PrimaryStringObject allObjectsInRealm:realm].count);
    XCTAssertEqual(so.intCol, 2);
    XCTAssertEqual(so2.intCol, 2);

    [realm cancelWriteTransaction];
}

- (void)testCreateOrUpdateDoesNotReplaceExistingValuesWithDefaults {
    auto realm = [RLMRealm defaultRealm];
    [realm beginWriteTransaction];

    auto so = [PrimaryKeyWithDefault createInRealm:realm withValue:@[@"pk", @2]];
    [PrimaryKeyWithDefault createOrUpdateInRealm:realm withValue:@{@"stringCol": @"pk"}];
    XCTAssertEqual(so.intCol, 2);

    [realm cancelWriteTransaction];
}

- (void)testCreateOrUpdateReplacesExistingArrayPropertiesAndDoesNotMergeThem {
    auto realm = [RLMRealm defaultRealm];
    [realm beginWriteTransaction];

    auto obj = [AllLinksWithPrimary createInRealm:realm withValue:@[@"pk", @[@"str"],
                                                                    @[@"str pk", @5],
                                                                    @[@[@1], @[@2], @[@3]]]];
    [AllLinksWithPrimary createOrUpdateInRealm:realm withValue:@[@"pk", @[@"str"],
                                                                 @[@"str pk", @6],
                                                                 @[@[@4]]]];
    XCTAssertEqual(1U, obj.intArray.count);
    XCTAssertEqual(4, obj.intArray[0].intCol);
    XCTAssertEqual(6, obj.primaryString.intCol);

    [realm cancelWriteTransaction];
}

- (void)testCreateOrUpdateReusesExistingLinkedObjectsWithPrimaryKeys {
    auto realm = [RLMRealm defaultRealm];
    [realm beginWriteTransaction];

    [AllLinksWithPrimary createInRealm:realm withValue:@[@"pk", NSNull.null,
                                                         @[@"str pk", @5]]];
    [AllLinksWithPrimary createOrUpdateInRealm:realm withValue:@[@"pk", NSNull.null,
                                                                 @{@"stringCol": @"str pk"}]];
    XCTAssertEqual(1U, [PrimaryStringObject allObjectsInRealm:realm].count);

    [realm cancelWriteTransaction];
}

- (void)testCreateOrUpdateCreatesNewLinkedObjectsWithoutPrimaryKeys {
    auto realm = [RLMRealm defaultRealm];
    [realm beginWriteTransaction];

    [AllLinksWithPrimary createInRealm:realm withValue:@[@"pk", @[@"str"]]];
    [AllLinksWithPrimary createOrUpdateInRealm:realm withValue:@[@"pk", @[@"str"]]];
    XCTAssertEqual(2U, [StringObject allObjectsInRealm:realm].count);

    [realm cancelWriteTransaction];
}

- (void)testCreateOrUpdateWithMissingValuesAndNoExistingObject {
    auto realm = [RLMRealm defaultRealm];
    [realm beginWriteTransaction];
    RLMAssertThrowsWithReason([PrimaryStringObject createOrUpdateInRealm:realm withValue:@{@"stringCol": @"pk"}],
                              @"Missing value for property 'PrimaryStringObject.intCol'");
    RLMAssertThrowsWithReason(([PrimaryStringObject createOrUpdateInRealm:realm
                                                                withValue:@{@"stringCol": @"pk",
                                                                            @"intCol": NSNull.null}]),
                              @"Invalid value '<null>' of type 'NSNull' for 'int' property 'PrimaryStringObject.intCol'");
    [realm cancelWriteTransaction];
}

- (void)testCreateOrUpdateOnManagedObjectInSameRealmReturnsExistingObjectInstance {
    auto realm = [RLMRealm defaultRealm];
    [realm beginWriteTransaction];

    auto so = [PrimaryStringObject createOrUpdateInRealm:realm withValue:@[@"pk", @2]];
    auto so2 = [PrimaryStringObject createOrUpdateInRealm:realm withValue:so];
    XCTAssertEqual(so, so2);
    XCTAssertEqual(1U, [PrimaryStringObject allObjectsInRealm:realm].count);

    [realm cancelWriteTransaction];
}

- (void)testCreateOrUpdateOnManagedObjectInDifferentRealmDeepCopies {
    auto realm = [RLMRealm defaultRealm];
    [realm beginWriteTransaction];
    auto realm2 = [self realmWithTestPath];
    [realm2 beginWriteTransaction];

    auto so = [StringObject createInRealm:realm withValue:@[@"str"]];
    auto pso = [PrimaryStringObject createInRealm:realm withValue:@[@"pk", @1]];
    auto io = [IntObject createInRealm:realm withValue:@[@2]];
    auto pio = [PrimaryIntObject createInRealm:realm withValue:@[@3]];

    auto links = [AllLinksWithPrimary createInRealm:realm withValue:@[@"pk", so, pso, @[io, io], @[pio, pio]]];
    auto copy = [AllLinksWithPrimary createOrUpdateInRealm:realm2 withValue:links];

    XCTAssertEqual(1U, [AllLinksWithPrimary allObjectsInRealm:realm2].count);
    XCTAssertEqual(1U, [StringObject allObjectsInRealm:realm2].count);
    XCTAssertEqual(1U, [PrimaryStringObject allObjectsInRealm:realm2].count);
    XCTAssertEqual(2U, [IntObject allObjectsInRealm:realm2].count);
    XCTAssertEqual(1U, [PrimaryIntObject allObjectsInRealm:realm2].count);

    XCTAssertEqualObjects(so.stringCol, copy.string.stringCol);
    XCTAssertEqualObjects(pso.stringCol, copy.primaryString.stringCol);
    XCTAssertEqual(pso.intCol, copy.primaryString.intCol);
    XCTAssertEqual(2U, copy.intArray.count);
    XCTAssertEqual(2U, copy.primaryIntArray.count);

    [realm cancelWriteTransaction];
    [realm2 cancelWriteTransaction];
}

- (void)testCreateOrUpdateWithNilValues {
    auto now = [NSDate date];
    auto bytes = [NSData dataWithBytes:"a" length:1];
    auto nonnull = [[AllOptionalTypesPK alloc] initWithValue:@[@0, @1, @2.2f, @3.3, @YES, @"a", bytes, now]];
    auto null = [[AllOptionalTypesPK alloc] initWithValue:@[@0]];

    auto realm = [RLMRealm defaultRealm];
    [realm beginWriteTransaction];

    auto obj = [AllOptionalTypesPK createInRealm:realm withValue:nonnull];
    [AllOptionalTypesPK createOrUpdateInRealm:realm withValue:null];

    XCTAssertNil(obj.intObj);
    XCTAssertNil(obj.floatObj);
    XCTAssertNil(obj.doubleObj);
    XCTAssertNil(obj.boolObj);
    XCTAssertNil(obj.string);
    XCTAssertNil(obj.data);
    XCTAssertNil(obj.date);

    [AllOptionalTypesPK createOrUpdateInRealm:realm withValue:nonnull];
    [AllOptionalTypesPK createOrUpdateInRealm:realm withValue:@[@0]];

    // No values specified, so old values should remain
    XCTAssertNotNil(obj.intObj);
    XCTAssertNotNil(obj.floatObj);
    XCTAssertNotNil(obj.doubleObj);
    XCTAssertNotNil(obj.boolObj);
    XCTAssertNotNil(obj.string);
    XCTAssertNotNil(obj.data);
    XCTAssertNotNil(obj.date);

    [AllOptionalTypesPK createOrUpdateInRealm:realm withValue:@{@"pk": @0}];
    XCTAssertNotNil(obj.intObj);
    XCTAssertNotNil(obj.floatObj);
    XCTAssertNotNil(obj.doubleObj);
    XCTAssertNotNil(obj.boolObj);
    XCTAssertNotNil(obj.string);
    XCTAssertNotNil(obj.data);
    XCTAssertNotNil(obj.date);

    [AllOptionalTypesPK createOrUpdateInRealm:realm withValue:@{@"pk": @0,
                                                                @"intObj": NSNull.null,
                                                                @"floatObj": NSNull.null,
                                                                @"doubleObj": NSNull.null,
                                                                @"boolObj": NSNull.null,
                                                                @"string": NSNull.null,
                                                                @"data": NSNull.null,
                                                                @"date": NSNull.null,
                                                                }];
    XCTAssertNil(obj.intObj);
    XCTAssertNil(obj.floatObj);
    XCTAssertNil(obj.doubleObj);
    XCTAssertNil(obj.boolObj);
    XCTAssertNil(obj.string);
    XCTAssertNil(obj.data);
    XCTAssertNil(obj.date);

    [realm cancelWriteTransaction];
}

- (void)testCreateOrUpdateWithRenamedPrimaryKey {
    auto realm = [RLMRealm defaultRealm];
    [realm beginWriteTransaction];

    auto obj = [RenamedPrimaryKey createInRealm:realm withValue:@[@1, @2]];
    [RenamedPrimaryKey createOrUpdateInRealm:realm withValue:@[@1, @3]];
    XCTAssertEqual(obj.pk, 1);
    XCTAssertEqual(obj.value, 3);

    [RenamedPrimaryKey createOrUpdateInRealm:realm withValue:@{@"pk": @1, @"value": @4}];
    XCTAssertEqual(obj.value, 4);

    [realm cancelWriteTransaction];
}

#pragma mark - Add

- (void)testAddInvalidated {
    auto realm = [RLMRealm defaultRealm];
    [realm beginWriteTransaction];

    id dog = [DogObject createInRealm:realm withValue:@[@"name", @1]];
    id dog2 = [DogObject allObjectsInRealm:realm].firstObject;
    [realm deleteObject:dog];
    RLMAssertThrowsWithReason([realm addObject:dog],
                              @"Adding a deleted or invalidated");
    RLMAssertThrowsWithReason([realm addObject:dog2],
                              @"Adding a deleted or invalidated");

    [realm cancelWriteTransaction];
}

- (void)testAddDuplicatePrimaryKey {
    auto realm = [RLMRealm defaultRealm];
    [realm beginWriteTransaction];

    [realm addObject:[[PrimaryStringObject alloc] initWithValue:@[@"pk", @1]]];
    RLMAssertThrowsWithReason(([realm addObject:[[PrimaryStringObject alloc] initWithValue:@[@"pk", @1]]]),
                              @"existing primary key value 'pk'");

    [realm cancelWriteTransaction];
}

- (void)testAddNested {
    auto realm = [RLMRealm defaultRealm];
    [realm beginWriteTransaction];

    auto co = [[CompanyObject alloc] initWithValue:@[@"one employee",
                                                     @[@[@"name", @2, @YES]]]];
    [realm addObject:co];
    XCTAssertEqual(co.realm, realm);
    XCTAssertEqualObjects(co.name, @"one employee");

    auto eo = co.employees[0];
    XCTAssertEqual(eo.realm, realm);
    XCTAssertEqualObjects(eo.name, @"name");

    eo = [[EmployeeObject alloc] initWithValue:@[@"name 2", @3, @NO]];
    co = [[CompanyObject alloc] initWithValue:@[@"one employee", @[eo]]];

    [realm addObject:co];
    XCTAssertEqual(co.realm, realm);
    XCTAssertEqual(eo.realm, realm);

    [realm cancelWriteTransaction];
}

- (void)testAddingObjectWithoutAnyPropertiesWorks {
    @autoreleasepool {
        auto realm = [RLMRealm defaultRealm];
        [realm beginWriteTransaction];
        [realm addObject:[[AbstractObject alloc] initWithValue:@[]]];
        [realm commitWriteTransaction];
    }
    auto realm = [RLMRealm defaultRealm];
    XCTAssertEqual(1U, [AbstractObject allObjectsInRealm:realm].count);
}

- (void)testAddWithCustomAccessors {
    auto realm = [RLMRealm defaultRealm];
    [realm beginWriteTransaction];

    auto ca = [[CustomAccessorsObject alloc] initWithValue:@[@"a", @1]];
    [realm addObject:ca];
    XCTAssertEqualObjects(ca.name, @"a");
    XCTAssertEqual(ca.age, 1);

    [realm cancelWriteTransaction];
}

- (void)testAddWithRenamedColumns {
    auto realm = [RLMRealm defaultRealm];
    [realm beginWriteTransaction];

    auto obj = [[RenamedProperties1 alloc] initWithValue:@[@1, @"a"]];
    [realm addObject:obj];
    XCTAssertEqual(obj.propA, 1);
    XCTAssertEqualObjects(obj.propB, @"a");

    RLMResults<RenamedProperties2 *> *results = [RenamedProperties2 allObjectsInRealm:realm];
    XCTAssertEqual(results[0].propC, 1);
    XCTAssertEqualObjects(results[0].propD, @"a");

    [realm cancelWriteTransaction];
}

- (void)testAddToCurrentRealmIsNoOp {
    DogObject *dog = [[DogObject alloc] init];

    auto realm = [RLMRealm defaultRealm];
    [realm beginWriteTransaction];

    [realm addObject:dog];
    XCTAssertEqual(dog.realm, realm);
    XCTAssertEqual(1U, [DogObject allObjectsInRealm:realm].count);

    XCTAssertNoThrow([realm addObject:dog]);
    XCTAssertEqual(dog.realm, realm);
    XCTAssertEqual(1U, [DogObject allObjectsInRealm:realm].count);

    [realm cancelWriteTransaction];
}

- (void)testAddToDifferentRealmThrows {
    auto eo = [[EmployeeObject alloc] init];

    auto realm = [RLMRealm defaultRealm];
    [realm beginWriteTransaction];
    [realm addObject:eo];

    auto realm2 = [self realmWithTestPath];
    [realm2 beginWriteTransaction];

    RLMAssertThrowsWithReason([realm2 addObject:eo],
                              @"Object is already managed by another Realm. Use create instead to copy it into this Realm.");
    XCTAssertEqual(eo.realm, realm);

    auto co = [CompanyObject new];
    [co.employees addObject:eo];
    RLMAssertThrowsWithReason([realm2 addObject:co],
                              @"Object is already managed by another Realm. Use create instead to copy it into this Realm.");
    XCTAssertEqual(co.realm, realm2);

    [realm cancelWriteTransaction];
    [realm2 cancelWriteTransaction];
}

- (void)testAddToCurrentRealmChecksForWrite {
    DogObject *dog = [[DogObject alloc] init];

    auto realm = [RLMRealm defaultRealm];
    [realm beginWriteTransaction];
    [realm addObject:dog];
    [realm commitWriteTransaction];

    RLMAssertThrowsWithReason([realm addObject:dog],
                              @"call beginWriteTransaction");
}

- (void)testAddObjectWithObserver {
    DogObject *dog = [[DogObject alloc] init];
    [dog addObserver:self forKeyPath:@"name" options:(NSKeyValueObservingOptions)0 context:0];

    auto realm = [RLMRealm defaultRealm];
    [realm beginWriteTransaction];
    RLMAssertThrowsWithReason([realm addObject:dog],
                              @"Cannot add an object with observers to a Realm");
    [realm cancelWriteTransaction];
    [dog removeObserver:self forKeyPath:@"name"];
}

- (void)testAddObjectWithNilValueForRequiredProperty {
    auto realm = [RLMRealm defaultRealm];
    [realm beginWriteTransaction];
    RLMAssertThrowsWithReason([realm addObject:[[RequiredPropertiesObject alloc] init]],
                              @"Invalid value '<null>' of type 'NSNull' for 'string' property 'RequiredPropertiesObject.stringCol'.");
    [realm cancelWriteTransaction];
}

#pragma mark - Add Or Update

- (void)testAddOrUpdateWithoutPKThrows {
    auto realm = [RLMRealm defaultRealm];
    [realm beginWriteTransaction];

    RLMAssertThrowsWithReason([realm addOrUpdateObject:[DogObject new]],
                              @"'DogObject' does not have a primary key");
    [realm cancelWriteTransaction];
}

- (void)testAddOrUpdateUpdatesExistingItemWithSamePK {
    auto realm = [RLMRealm defaultRealm];
    [realm beginWriteTransaction];
    auto so1 = [[PrimaryStringObject alloc] initWithValue:@[@"pk", @2]];
    auto so2 = [[PrimaryStringObject alloc] initWithValue:@[@"pk", @3]];

    [realm addOrUpdateObject:so1];
    XCTAssertEqual(1U, [PrimaryStringObject allObjectsInRealm:realm].count);
    XCTAssertEqual(so1.intCol, 2);

    [realm addOrUpdateObject:so2];
    XCTAssertEqual(1U, [PrimaryStringObject allObjectsInRealm:realm].count);
    XCTAssertEqual(so1.intCol, 3);
    XCTAssertEqualObjects(so1, so2);

    [realm cancelWriteTransaction];
}

- (void)testAddOrUpdateWithNullPrimaryKey {
    RLMRealm *realm = [RLMRealm defaultRealm];
    [realm beginWriteTransaction];
    auto so1 = [[PrimaryNullableStringObject alloc] initWithValue:@{@"intCol": @5}];
    auto so2 = [[PrimaryNullableStringObject alloc] initWithValue:@{@"intCol": @7}];

    XCTAssertNil([PrimaryNullableStringObject objectInRealm:realm forPrimaryKey:NSNull.null]);
    XCTAssertNil([PrimaryNullableStringObject objectInRealm:realm forPrimaryKey:nil]);

    [realm addOrUpdateObject:so1];
    XCTAssertEqual([PrimaryNullableStringObject objectInRealm:realm forPrimaryKey:NSNull.null].intCol, 5);
    XCTAssertEqual([PrimaryNullableStringObject objectInRealm:realm forPrimaryKey:nil].intCol, 5);

    [realm addOrUpdateObject:so2];
    XCTAssertEqual([PrimaryNullableStringObject objectInRealm:realm forPrimaryKey:NSNull.null].intCol, 7);
    XCTAssertEqual([PrimaryNullableStringObject objectInRealm:realm forPrimaryKey:nil].intCol, 7);

    auto io1 = [[PrimaryNullableIntObject alloc] initWithValue:@{@"value": @5}];
    auto io2 = [[PrimaryNullableIntObject alloc] initWithValue:@{@"value": @7}];

    XCTAssertNil([PrimaryNullableIntObject objectInRealm:realm forPrimaryKey:NSNull.null]);
    XCTAssertNil([PrimaryNullableIntObject objectInRealm:realm forPrimaryKey:nil]);

    [realm addOrUpdateObject:io1];
    XCTAssertEqual([PrimaryNullableIntObject objectInRealm:realm forPrimaryKey:NSNull.null].value, 5);
    XCTAssertEqual([PrimaryNullableIntObject objectInRealm:realm forPrimaryKey:nil].value, 5);

    [realm addOrUpdateObject:io2];
    XCTAssertEqual([PrimaryNullableIntObject objectInRealm:realm forPrimaryKey:NSNull.null].value, 7);
    XCTAssertEqual([PrimaryNullableIntObject objectInRealm:realm forPrimaryKey:nil].value, 7);

    [realm cancelWriteTransaction];
}

- (void)testAddOrUpdateDoesNotHaveAnyConceptOfKeysNotPresentThatShouldBeLeftAlone {
    auto realm = [RLMRealm defaultRealm];
    [realm beginWriteTransaction];

    auto obj1 = [[PrimaryKeyWithDefault alloc] initWithValue:@[@"pk", @2]];
    auto obj2 = [[PrimaryKeyWithDefault alloc] initWithValue:@[@"pk"]];
    [realm addOrUpdateObject:obj1];
    [realm addOrUpdateObject:obj2];
    XCTAssertEqual(obj1.intCol, 10);

    [realm cancelWriteTransaction];
}

- (void)testAddObjectWithNilValueForRequiredPropertyDoesNotUseExistingValue {
    auto realm = [RLMRealm defaultRealm];
    [realm beginWriteTransaction];

    [PrimaryKeyAndRequiredString createInRealm:realm withValue:@[@0, @"value"]];
    RLMAssertThrowsWithReason([realm addOrUpdateObject:[[PrimaryKeyAndRequiredString alloc] init]],
                              @"Invalid value '<null>' of type 'NSNull' for 'string' property 'PrimaryKeyAndRequiredString.value'");

    [realm cancelWriteTransaction];
}

- (void)testAddOrUpdateWithDuplicateConflictingValuesForPrimaryKeyInArrayProperty {
    auto realm = [RLMRealm defaultRealm];
    [realm beginWriteTransaction];

    auto company = [[PrimaryCompanyObject alloc] init];
    [company.employees addObject:[[PrimaryEmployeeObject alloc] initWithValue:@[@"a", @1, @NO]]];
    [company.employees addObject:[[PrimaryEmployeeObject alloc] initWithValue:@[@"a", @2, @NO]]];
    [company.employeeSet addObject:[[PrimaryEmployeeObject alloc] initWithValue:@[@"a", @1, @NO]]];
    [company.employeeSet addObject:[[PrimaryEmployeeObject alloc] initWithValue:@[@"a", @2, @NO]]];
    [realm addOrUpdateObject:company];

    XCTAssertEqual(1U, [PrimaryEmployeeObject allObjectsInRealm:realm].count);
    XCTAssertEqual(2, company.employees[0].age);
    XCTAssertEqual(2, company.employees[1].age);
    XCTAssertEqualObjects(company.employees[0], company.employees[1]);
    XCTAssertEqual(2, company.employeeSet.allObjects[0].age);
    XCTAssertEqualObjects(company.employeeSet.allObjects[0], company.employeeSet.allObjects.lastObject);
}

- (void)testAddOrUpdateReplacesExistingArrayPropertiesAndDoesNotMergeThem {
    auto realm = [RLMRealm defaultRealm];
    [realm beginWriteTransaction];

    auto obj1 = [[AllLinksWithPrimary alloc] initWithValue:@[@"pk", @[@"str"],
                                                             @[@"str pk", @5],
                                                             @[@[@1], @[@2], @[@3]],
                                                             @[],
                                                             @[@[@1], @[@2], @[@3]]]];
    auto obj2 = [[AllLinksWithPrimary alloc] initWithValue:@[@"pk", @[@"str"],
                                                             @[@"str pk", @6],
                                                             @[@[@4]],
                                                             @[],
                                                             @[@[@4]]]];
    [realm addOrUpdateObject:obj1];
    [realm addOrUpdateObject:obj2];
    XCTAssertEqual(1U, obj1.intArray.count);
    XCTAssertEqual(4, obj1.intArray[0].intCol);
    XCTAssertEqual(1U, obj1.intSet.count);
    XCTAssertEqual(4, obj1.intSet.allObjects[0].intCol);
    XCTAssertEqual(6, obj1.primaryString.intCol);

    [realm cancelWriteTransaction];
}

- (void)testAddOrUpdateReusesExistingLinkedObjectsWithPrimaryKeys {
    auto realm = [RLMRealm defaultRealm];
    [realm beginWriteTransaction];

    auto obj1 = [[AllLinksWithPrimary alloc] initWithValue:@[@"pk", NSNull.null,
                                                             @[@"str pk", @5]]];
    auto obj2 = [[AllLinksWithPrimary alloc] initWithValue:@[@"pk", NSNull.null,
                                                             @{@"stringCol": @"str pk"}]];

    [realm addOrUpdateObject:obj1];
    [realm addOrUpdateObject:obj2];
    XCTAssertEqual(1U, [PrimaryStringObject allObjectsInRealm:realm].count);

    [realm cancelWriteTransaction];
}

- (void)testAddOrUpdateAddsNewLinkedObjectsWithoutPrimaryKeys {
    auto realm = [RLMRealm defaultRealm];
    [realm beginWriteTransaction];

    auto obj1 = [[AllLinksWithPrimary alloc] initWithValue:@[@"pk", @[@"str"]]];
    auto obj2 = [[AllLinksWithPrimary alloc] initWithValue:@[@"pk", @[@"str"]]];

    [realm addOrUpdateObject:obj1];
    [realm addOrUpdateObject:obj2];
    XCTAssertEqual(2U, [StringObject allObjectsInRealm:realm].count);
    XCTAssertFalse([obj1.string isEqualToObject:[StringObject allObjectsInRealm:realm][0]]);
    XCTAssertTrue([obj1.string isEqualToObject:[StringObject allObjectsInRealm:realm][1]]);

    [realm cancelWriteTransaction];
}

- (void)testAddOrUpdateOnManagedObjectInSameRealmIsNoOp {
    auto realm = [RLMRealm defaultRealm];
    [realm beginWriteTransaction];

    auto so = [PrimaryStringObject createOrUpdateInRealm:realm withValue:@[@"pk", @2]];
    XCTAssertNoThrow([realm addOrUpdateObject:so]);
    XCTAssertEqual(1U, [PrimaryStringObject allObjectsInRealm:realm].count);

    [realm cancelWriteTransaction];
}

- (void)testAddOrUpdateOnManagedObjectInDifferentRealmThrows {
    auto eo = [[PrimaryEmployeeObject alloc] init];

    auto realm = [RLMRealm defaultRealm];
    [realm beginWriteTransaction];
    [realm addObject:eo];

    auto realm2 = [self realmWithTestPath];
    [realm2 beginWriteTransaction];

    RLMAssertThrowsWithReason([realm2 addOrUpdateObject:eo],
                              @"Object is already managed by another Realm. Use create instead to copy it into this Realm.");
    XCTAssertEqual(eo.realm, realm);

    auto co = [PrimaryCompanyObject new];
    [co.employees addObject:eo];
    RLMAssertThrowsWithReason([realm2 addOrUpdateObject:co],
                              @"Object is already managed by another Realm. Use create instead to copy it into this Realm.");
    XCTAssertEqual(co.realm, realm2);

    [realm cancelWriteTransaction];
    [realm2 cancelWriteTransaction];
}

- (void)testAddOrUpdateWithNilValues {
    auto now = [NSDate date];
    auto bytes = [NSData dataWithBytes:"a" length:1];
    auto nonnull = [[AllOptionalTypesPK alloc] initWithValue:@[@0, @1, @2.2f, @3.3, @YES, @"a", bytes, now]];
    auto null = [[AllOptionalTypesPK alloc] initWithValue:@[@0]];

    auto realm = [RLMRealm defaultRealm];
    [realm beginWriteTransaction];

    auto obj = [AllOptionalTypesPK createInRealm:realm withValue:nonnull];
    auto nullobj = [[AllOptionalTypesPK alloc] initWithValue:null];
    [realm addOrUpdateObject:nullobj];

    XCTAssertNil(obj.intObj);
    XCTAssertNil(obj.floatObj);
    XCTAssertNil(obj.doubleObj);
    XCTAssertNil(obj.boolObj);
    XCTAssertNil(obj.string);
    XCTAssertNil(obj.data);
    XCTAssertNil(obj.date);

    [realm cancelWriteTransaction];
}

@end
