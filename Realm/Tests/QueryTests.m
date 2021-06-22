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

#import "RLMObjectSchema_Private.h"
#import "RLMRealmConfiguration_Private.h"
#import "RLMRealm_Dynamic.h"
#import "RLMSchema_Private.h"

#pragma mark - Test Objects

@class LinkChain2, LinkChain3;

@interface LinkChain1 : RLMObject
@property int value;
@property LinkChain2 *next;
@end

@interface LinkChain2 : RLMObject
@property LinkChain3 *next;
@property (readonly) RLMLinkingObjects *prev;
@end

@interface LinkChain3 : RLMObject
@property (readonly) RLMLinkingObjects *prev;
@end

@implementation LinkChain1
@end

@implementation LinkChain2
+ (NSDictionary *)linkingObjectsProperties {
    return @{@"prev": [RLMPropertyDescriptor descriptorWithClass:LinkChain1.class propertyName:@"next"]};
}
@end

@implementation LinkChain3
+ (NSDictionary *)linkingObjectsProperties {
    return @{@"prev": [RLMPropertyDescriptor descriptorWithClass:LinkChain2.class propertyName:@"next"]};
}
@end

#pragma mark NonRealmEmployeeObject

@interface NonRealmEmployeeObject : NSObject
@property NSString *name;
@property NSInteger age;
@end

@implementation NonRealmEmployeeObject
@end

@interface PersonLinkObject : RLMObject
@property PersonObject *person;
@end

@implementation PersonLinkObject
@end

#pragma mark QueryObject

@interface QueryObject : RLMObject
@property (nonatomic, assign) BOOL         bool1;
@property (nonatomic, assign) BOOL         bool2;
@property (nonatomic, assign) NSInteger    int1;
@property (nonatomic, assign) NSInteger    int2;
@property (nonatomic, assign) float        float1;
@property (nonatomic, assign) float        float2;
@property (nonatomic, assign) double       double1;
@property (nonatomic, assign) double       double2;
@property (nonatomic, copy) NSString      *string1;
@property (nonatomic, copy) NSString      *string2;
@property (nonatomic, copy) NSData        *data1;
@property (nonatomic, copy) NSData        *data2;
@property (nonatomic, copy) RLMDecimal128 *decimal1;
@property (nonatomic, copy) RLMDecimal128 *decimal2;
@property (nonatomic, copy) RLMObjectId   *objectId1;
@property (nonatomic, copy) RLMObjectId   *objectId2;
@property (nonatomic, copy) id<RLMValue>   any1;
@property (nonatomic, copy) id<RLMValue>   any2;
@property (nonatomic, copy) QueryObject   *object1;
@property (nonatomic, copy) QueryObject   *object2;
@end

@implementation QueryObject
+ (NSArray *)requiredProperties {
    return @[@"string1", @"string2", @"data1", @"data2", @"objectId1", @"objectId2", @"decimal1", @"decimal2"];
}
@end

@interface NullQueryObject : RLMObject
@property (nonatomic, copy) NSNumber<RLMBool>   *bool1;
@property (nonatomic, copy) NSNumber<RLMBool>   *bool2;
@property (nonatomic, copy) NSNumber<RLMInt>    *int1;
@property (nonatomic, copy) NSNumber<RLMInt>    *int2;
@property (nonatomic, copy) NSNumber<RLMFloat>  *float1;
@property (nonatomic, copy) NSNumber<RLMFloat>  *float2;
@property (nonatomic, copy) NSNumber<RLMDouble> *double1;
@property (nonatomic, copy) NSNumber<RLMDouble> *double2;
@property (nonatomic, copy) NSString            *string1;
@property (nonatomic, copy) NSString            *string2;
@property (nonatomic, copy) NSData              *data1;
@property (nonatomic, copy) NSData              *data2;
@property (nonatomic, copy) RLMDecimal128       *decimal1;
@property (nonatomic, copy) RLMDecimal128       *decimal2;
@property (nonatomic, copy) RLMObjectId         *objectId1;
@property (nonatomic, copy) RLMObjectId         *objectId2;
@property (nonatomic, copy) id<RLMValue>        any1;
@property (nonatomic, copy) id<RLMValue>        any2;
@property (nonatomic, copy) NullQueryObject     *object1;
@property (nonatomic, copy) NullQueryObject     *object2;
@end

@implementation NullQueryObject
@end

#pragma mark - Tests

#define RLMAssertCount(cls, expectedCount, ...) \
    XCTAssertEqual(expectedCount, ([self evaluate:[cls objectsWhere:__VA_ARGS__]].count))

@interface QueryConstructionTests : RLMTestCase
@end

@implementation QueryConstructionTests
- (RLMResults *)evaluate:(RLMResults *)results {
    return results;
}

- (void)testQueryingNilRealmThrows {
    XCTAssertThrows([PersonObject allObjectsInRealm:self.nonLiteralNil]);
}

- (void)testDynamicQueryInvalidClass
{
    RLMRealm *realm = [RLMRealm defaultRealm];

    // class not derived from RLMObject
    XCTAssertThrows([realm objects:@"NonRealmPersonObject" where:@"age > 25"], @"invalid object type");
    XCTAssertThrows([[realm objects:@"NonRealmPersonObject" where:@"age > 25"] sortedResultsUsingKeyPath:@"age" ascending:YES], @"invalid object type");

    // empty string for class name
    XCTAssertThrows([realm objects:@"" where:@"age > 25"], @"missing class name");
    XCTAssertThrows([[realm objects:@"" where:@"age > 25"] sortedResultsUsingKeyPath:@"age" ascending:YES], @"missing class name");

    // nil class name
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wnonnull"
    XCTAssertThrows([realm objects:nil where:@"age > 25"], @"nil class name");
    XCTAssertThrows([[realm objects:nil where:@"age > 25"] sortedResultsUsingKeyPath:@"age" ascending:YES], @"nil class name");
#pragma clang diagnostic pop
}

- (void)testPredicateValidUse
{
    RLMRealm *realm = [RLMRealm defaultRealm];

    // boolean false
    XCTAssertNoThrow([AllTypesObject objectsInRealm:realm where:@"boolCol == no"], @"== no");
    XCTAssertNoThrow([AllTypesObject objectsInRealm:realm where:@"boolCol == No"], @"== No");
    XCTAssertNoThrow([AllTypesObject objectsInRealm:realm where:@"boolCol == NO"], @"== NO");
    XCTAssertNoThrow([AllTypesObject objectsInRealm:realm where:@"boolCol == false"], @"== false");
    XCTAssertNoThrow([AllTypesObject objectsInRealm:realm where:@"boolCol == False"], @"== False");
    XCTAssertNoThrow([AllTypesObject objectsInRealm:realm where:@"boolCol == FALSE"], @"== FALSE");
    XCTAssertNoThrow([AllTypesObject objectsInRealm:realm where:@"boolCol == 0"], @"== 0");

    // boolean true
    XCTAssertNoThrow([AllTypesObject objectsInRealm:realm where:@"boolCol == yes"], @"== yes");
    XCTAssertNoThrow([AllTypesObject objectsInRealm:realm where:@"boolCol == Yes"], @"== Yes");
    XCTAssertNoThrow([AllTypesObject objectsInRealm:realm where:@"boolCol == YES"], @"== YES");
    XCTAssertNoThrow([AllTypesObject objectsInRealm:realm where:@"boolCol == true"], @"== true");
    XCTAssertNoThrow([AllTypesObject objectsInRealm:realm where:@"boolCol == True"], @"== True");
    XCTAssertNoThrow([AllTypesObject objectsInRealm:realm where:@"boolCol == TRUE"], @"== TRUE");
    XCTAssertNoThrow([AllTypesObject objectsInRealm:realm where:@"boolCol == 1"], @"== 1");

    // inequality
    XCTAssertNoThrow([AllTypesObject objectsInRealm:realm where:@"boolCol != YES"], @"!= YES");
    XCTAssertNoThrow([AllTypesObject objectsInRealm:realm where:@"boolCol <> YES"], @"<> YES");
}

- (void)testPredicateNotSupported
{
    // These are things which are valid predicates, but which we do not support

    // Aggregate operators on non-arrays
    RLMAssertThrowsWithReasonMatching([PersonObject objectsWhere:@"ANY age > 5"], @"Aggregate operations can only.*array property");
    RLMAssertThrowsWithReasonMatching([PersonObject objectsWhere:@"ALL age > 5"], @"ALL modifier not supported");
    RLMAssertThrowsWithReasonMatching([PersonObject objectsWhere:@"SOME age > 5"], @"Aggregate operations can only.*array property");
    RLMAssertThrowsWithReasonMatching([PersonObject objectsWhere:@"NONE age > 5"], @"Aggregate operations can only.*array property");
    RLMAssertThrowsWithReasonMatching([PersonLinkObject objectsWhere:@"ANY person.age > 5"], @"Aggregate operations can only.*array property");
    RLMAssertThrowsWithReasonMatching([PersonLinkObject objectsWhere:@"ALL person.age > 5"], @"ALL modifier not supported");
    RLMAssertThrowsWithReasonMatching([PersonLinkObject objectsWhere:@"SOME person.age > 5"], @"Aggregate operations can only.*array property");
    RLMAssertThrowsWithReasonMatching([PersonLinkObject objectsWhere:@"NONE person.age > 5"], @"Aggregate operations can only.*array property");
    RLMAssertThrowsWithReasonMatching([PersonObject objectsWhere:@"age.@count > 5"], @"Aggregate operations can only.*array property");
    RLMAssertThrowsWithReasonMatching([PersonObject objectsWhere:@"age.@sum > 5"], @"Aggregate operations can only.*array property");

    // comparing two constants
    RLMAssertThrowsWithReason([PersonObject objectsWhere:@"5 = 5"],
                              @"Predicate expressions must compare a keypath and another keypath or a constant value");
    RLMAssertThrowsWithReason([PersonObject objectsWhere:@"nil = nil"],
                              @"Predicate expressions must compare a keypath and another keypath or a constant value");

    // substring operations with constant on LHS
    RLMAssertThrowsWithReason(([AllOptionalTypes objectsWhere:@"%@ CONTAINS data", [NSData data]]),
                              @"Operator 'CONTAINS' requires a keypath on the left side");

    // LinkList equality is unsupport since the semantics are unclear
    XCTAssertThrows(([ArrayOfAllTypesObject objectsWhere:@"ANY array = array"]));

    // Unsupported variants of subqueries.
    RLMAssertThrowsWithReasonMatching(([ArrayOfAllTypesObject objectsWhere:@"SUBQUERY(array, $obj, $obj.intCol = 5).@count == array.@count"]), @"SUBQUERY.*compared with a constant number");
    RLMAssertThrowsWithReasonMatching(([ArrayOfAllTypesObject objectsWhere:@"SUBQUERY(array, $obj, $obj.intCol = 5) == 0"]), @"SUBQUERY.*immediately followed by .@count");
    RLMAssertThrowsWithReasonMatching(([ArrayOfAllTypesObject objectsWhere:@"SELF IN SUBQUERY(array, $obj, $obj.intCol = 5)"]), @"Predicate with IN operator must compare.*aggregate$");

    // Nonexistent aggregate operators
    RLMAssertThrowsWithReason([PersonObject objectsWhere:@"children.@average.age == 5"],
                              @"Unsupported collection operation '@average'");

    // block-based predicate
    NSPredicate *pred = [NSPredicate predicateWithBlock:^BOOL (__unused id obj, __unused NSDictionary *bindings) {
        return true;
    }];
    XCTAssertThrows([IntObject objectsWithPredicate:pred]);
}

- (void)testPredicateMisuse
{
    RLMRealm *realm = [RLMRealm defaultRealm];

    NSString *className = PersonObject.className;

    // invalid column/property name
    RLMAssertThrowsWithReason([realm objects:className where:@"height > 72"],
                              @"Property 'height' not found in object of type 'PersonObject'");

    // wrong/invalid data types
    RLMAssertThrowsWithReasonMatching([realm objects:className where:@"age != xyz"],
                                      @"'xyz' not found in .* 'PersonObject'");
    RLMAssertThrowsWithReasonMatching([realm objects:className where:@"name == 3"],
                                      @"type string .* property 'name' .* 'PersonObject'.*: 3");
    RLMAssertThrowsWithReasonMatching([realm objects:className where:@"age IN {'xyz'}"],
                                      @"type int .* property 'age' .* 'PersonObject'.*: xyz");
    XCTAssertThrows([realm objects:className where:@"name IN {3}"], @"invalid type");

    className = AllTypesObject.className;

    // compare columns to incorrect type of constant value
    RLMAssertThrowsWithReason([realm objects:className where:@"boolCol == 'Foo'"],
                              @"Expected object of type bool");
    RLMAssertThrowsWithReason([realm objects:className where:@"boolCol == 2"],
                              @"Expected object of type bool");
    RLMAssertThrowsWithReason([realm objects:className where:@"dateCol == 7"],
                              @"Expected object of type date");
    RLMAssertThrowsWithReason([realm objects:className where:@"doubleCol == 'The'"],
                              @"Expected object of type double");
    RLMAssertThrowsWithReason([realm objects:className where:@"floatCol == 'Bar'"],
                              @"Expected object of type float");
    RLMAssertThrowsWithReason([realm objects:className where:@"intCol == 'Baz'"],
                              @"Expected object of type int");

    className = PersonObject.className;

    // compare two constants
    XCTAssertThrows([realm objects:className where:@"3 == 3"], @"comparing 2 constants");

    // invalid strings
    RLMAssertThrowsWithReason([realm objects:className where:@""],
                              @"Unable to parse the format string");
    RLMAssertThrowsWithReason([realm objects:className where:@"age"],
                              @"Unable to parse the format string");
    RLMAssertThrowsWithReason([realm objects:className where:@"sdlfjasdflj"],
                              @"Unable to parse the format string");
    RLMAssertThrowsWithReason([realm objects:className where:@"age * 25"],
                              @"Unable to parse the format string");
    RLMAssertThrowsWithReason([realm objects:className where:@"age === 25"],
                              @"Unable to parse the format string");
    RLMAssertThrowsWithReason([realm objects:className where:@","],
                              @"Unable to parse the format string");
    RLMAssertThrowsWithReason([realm objects:className where:@"()"],
                              @"Unable to parse the format string");

    // Misspelled keypath (should be %K)
    RLMAssertThrowsWithReason([realm objects:className where:@"@K == YES"], @"'@K' is not a valid key path'");

    NSPredicate *(^predicateWithKeyPath)(NSString *) = ^(NSString *keyPath) {
        return  [NSComparisonPredicate predicateWithLeftExpression:[NSExpression expressionForKeyPath:keyPath]
                                                   rightExpression:[NSExpression expressionForConstantValue:@0]
                                                          modifier:0
                                                              type:NSEqualToPredicateOperatorType
                                                           options:0];
    };

    // malformed keypath operators
    RLMAssertThrowsWithReason([realm objects:className where:@"@count == 0"],
                              @"'@count' is not a valid key path");
    NSPredicate *pred = [NSComparisonPredicate predicateWithLeftExpression:[NSExpression expressionForKeyPath:@"name.@"] rightExpression:[NSExpression expressionForConstantValue:@0] modifier:0 type:NSEqualToPredicateOperatorType options:0];
    RLMAssertThrowsWithReason([realm objects:className withPredicate:predicateWithKeyPath(@"name.@")],
                              @"'name.@' is not a valid key path");
    RLMAssertThrowsWithReason([realm objects:className withPredicate:predicateWithKeyPath(@"name@")],
                              @"'name@' is not a valid key path");
    RLMAssertThrowsWithReason([realm objects:className withPredicate:predicateWithKeyPath(@"name@length")],
                              @"'name@length' is not a valid key path");
    RLMAssertThrowsWithReason([realm objects:className withPredicate:predicateWithKeyPath(@".name")],
                              @"Property '' not found in object of type 'PersonObject'");
    RLMAssertThrowsWithReason([realm objects:className withPredicate:predicateWithKeyPath(@"children.")],
                              @"Property '' not found in object of type 'PersonObject'");

    // not a link column
    RLMAssertThrowsWithReason([realm objects:className where:@"age.age == 25"],
                              @"Property 'age' is not a link in object of type 'PersonObject'");
    RLMAssertThrowsWithReason([realm objects:className where:@"age.age.age == 25"],
                              @"Property 'age' is not a link in object of type 'PersonObject'");

    // abuse of BETWEEN
    RLMAssertThrowsWithReason([realm objects:className where:@"age BETWEEN 25"], @"type NSArray for BETWEEN");
    RLMAssertThrowsWithReason([realm objects:className where:@"age BETWEEN Foo"], @"BETWEEN operator must compare a KeyPath with an aggregate");
    RLMAssertThrowsWithReason([realm objects:className where:@"age BETWEEN {age, age}"], @"must be constant values");
    RLMAssertThrowsWithReason([realm objects:className where:@"age BETWEEN {age, 0}"], @"must be constant values");
    RLMAssertThrowsWithReason([realm objects:className where:@"age BETWEEN {0, age}"], @"must be constant values");
    RLMAssertThrowsWithReason([realm objects:className where:@"age BETWEEN {0, {1, 10}}"], @"must be constant values");

    pred = [NSPredicate predicateWithFormat:@"age BETWEEN %@", @[@1]];
    RLMAssertThrowsWithReason([realm objects:className withPredicate:pred], @"exactly two objects");

    pred = [NSPredicate predicateWithFormat:@"age BETWEEN %@", @[@1, @2, @3]];
    RLMAssertThrowsWithReason([realm objects:className withPredicate:pred], @"exactly two objects");

    pred = [NSPredicate predicateWithFormat:@"age BETWEEN %@", @[@"Foo", @"Bar"]];
    RLMAssertThrowsWithReason([realm objects:className withPredicate:pred], @"type int for BETWEEN");

    pred = [NSPredicate predicateWithFormat:@"age BETWEEN %@", @[@1.5, @2.5]];
    RLMAssertThrowsWithReason([realm objects:className withPredicate:pred], @"type int for BETWEEN");

    pred = [NSPredicate predicateWithFormat:@"age BETWEEN %@", @[@1, @[@2, @3]]];
    RLMAssertThrowsWithReason([realm objects:className withPredicate:pred], @"type int for BETWEEN");

    pred = [NSPredicate predicateWithFormat:@"age BETWEEN %@", @{@25: @35}];
    RLMAssertThrowsWithReason([realm objects:className withPredicate:pred], @"type NSArray for BETWEEN");

    pred = [NSPredicate predicateWithFormat:@"height BETWEEN %@", @[@25, @35]];
    RLMAssertThrowsWithReason([realm objects:className withPredicate:pred],
                              @"Property 'height' not found in object of type 'PersonObject'");

    // bad type in link IN
    RLMAssertThrowsWithReason([PersonLinkObject objectsInRealm:realm where:@"person.age IN {'Tim'}"],
                              @"Expected object of type int in IN clause for property 'person.age' on object of type 'PersonLinkObject'");
}

- (void)testStringUnsupportedOperations
{
    XCTAssertThrows([StringObject objectsWhere:@"stringCol MATCHES 'abc'"]);
    XCTAssertThrows([StringObject objectsWhere:@"stringCol BETWEEN {'a', 'b'}"]);
    XCTAssertThrows([StringObject objectsWhere:@"stringCol < 'abc'"]);

    XCTAssertThrows([AllTypesObject objectsWhere:@"objectCol.stringCol MATCHES 'abc'"]);
    XCTAssertThrows([AllTypesObject objectsWhere:@"objectCol.stringCol BETWEEN {'a', 'b'}"]);
    XCTAssertThrows([AllTypesObject objectsWhere:@"objectCol.stringCol < 'abc'"]);
}

- (void)testBinaryComparisonInPredicate {
    NSData *data = [NSData data];
    RLMAssertCount(BinaryObject, 0U, @"binaryCol BEGINSWITH %@", data);
    RLMAssertCount(BinaryObject, 0U, @"binaryCol ENDSWITH %@", data);
    RLMAssertCount(BinaryObject, 0U, @"binaryCol CONTAINS %@", data);

    RLMAssertCount(BinaryObject, 0U, @"binaryCol BEGINSWITH NULL");
    RLMAssertCount(BinaryObject, 0U, @"binaryCol ENDSWITH NULL");
    RLMAssertCount(BinaryObject, 0U, @"binaryCol CONTAINS NULL");

    RLMAssertCount(BinaryObject, 0U, @"binaryCol = %@", data);
    RLMAssertCount(BinaryObject, 0U, @"binaryCol != %@", data);

    XCTAssertThrows(([BinaryObject objectsWhere:@"binaryCol < %@", data]));
    XCTAssertThrows(([BinaryObject objectsWhere:@"binaryCol <= %@", data]));
    XCTAssertThrows(([BinaryObject objectsWhere:@"binaryCol > %@", data]));
    XCTAssertThrows(([BinaryObject objectsWhere:@"binaryCol >= %@", data]));

    XCTAssertThrows(([BinaryObject objectsWhere:@"binaryCol MATCHES %@", data]));
}

- (void)testLinkQueryInvalid {
    XCTAssertThrows([LinkToAllTypesObject objectsWhere:@"allTypesCol.binaryCol = 'a'"], @"Binary data not supported");
    XCTAssertThrows([LinkToAllTypesObject objectsWhere:@"allTypesCol.invalidCol = 'a'"], @"Invalid column name should throw");

    XCTAssertThrows([LinkToAllTypesObject objectsWhere:@"allTypesCol.longCol = 'a'"], @"Wrong data type should throw");

    RLMAssertThrowsWithReasonMatching([ArrayPropertyObject objectsWhere:@"intArray.intCol > 5"], @"Key paths that include a collection property must use aggregate operations");
    RLMAssertThrowsWithReasonMatching([SetPropertyObject objectsWhere:@"intSet.intCol > 5"], @"Key paths that include a collection property must use aggregate operations");
    RLMAssertThrowsWithReasonMatching([LinkToCompanyObject objectsWhere:@"company.employees.age > 5"], @"Key paths that include a collection property must use aggregate operations");

    RLMAssertThrowsWithReasonMatching([LinkToAllTypesObject objectsWhere:@"allTypesCol.intCol = allTypesCol.doubleCol"], @"Property type mismatch");
}

- (void)testNumericOperatorsOnClass:(Class)class property:(NSString *)property value:(id)value {
    NSArray *operators = @[@"<", @"<=", @">", @">=", @"==", @"!="];
    for (NSString *operator in operators) {
        NSString *fmt = [@[property, operator, @"%@"] componentsJoinedByString:@" "];
        RLMAssertCount(class, 0U, fmt, value);
    }
}

- (void)testValidOperatorsInNumericComparison {
    [self testNumericOperatorsOnClass:[IntObject class] property:@"intCol" value:@0];
    [self testNumericOperatorsOnClass:[FloatObject class] property:@"floatCol" value:@0];
    [self testNumericOperatorsOnClass:[DoubleObject class] property:@"doubleCol" value:@0];
    [self testNumericOperatorsOnClass:[DateObject class] property:@"dateCol" value:NSDate.date];
    [self testNumericOperatorsOnClass:[DecimalObject class] property:@"decimalCol" value:[RLMDecimal128 decimalWithNumber:@0]];
    [self testNumericOperatorsOnClass:[MixedObject class] property:@"anyCol" value:@0];
}

- (void)testStringOperatorsOnClass:(Class)class property:(NSString *)property value:(id)value {
    NSArray *operators = @[@"BEGINSWITH", @"ENDSWITH", @"CONTAINS", @"LIKE", @"MATCHES"];
    for (NSString *operator in operators) {
        NSString *fmt = [@[property, operator, @"%@"] componentsJoinedByString:@" "];
        RLMAssertThrowsWithReasonMatching(([class objectsWhere:fmt, value]),
                                          @"not supported for type");
    }
}

- (void)testInvalidOperatorsInNumericComparison {
    [self testStringOperatorsOnClass:[IntObject class] property:@"intCol" value:@0];
    [self testStringOperatorsOnClass:[FloatObject class] property:@"floatCol" value:@0];
    [self testStringOperatorsOnClass:[DoubleObject class] property:@"doubleCol" value:@0];
    [self testStringOperatorsOnClass:[DateObject class] property:@"dateCol" value:NSDate.date];
    [self testStringOperatorsOnClass:[DecimalObject class] property:@"decimalCol" value:[RLMDecimal128 decimalWithNumber:@0]];
}
@end

@interface QueryTests : RLMTestCase
- (Class)queryObjectClass;
@end

@implementation QueryTests

- (Class)queryObjectClass {
    return [QueryObject class];
}

- (RLMResults *)evaluate:(RLMResults *)results {
    return results;
}

- (RLMRealm *)realm {
    return [RLMRealm defaultRealm];
}

- (void)testBasicQuery {
    RLMRealm *realm = [self realm];

    [realm beginWriteTransaction];
    [PersonObject createInRealm:realm withValue:@[@"Fiel", @27]];
    [PersonObject createInRealm:realm withValue:@[@"Ari", @33]];
    [PersonObject createInRealm:realm withValue:@[@"Tim", @29]];
    [realm commitWriteTransaction];

    // query on realm
    RLMAssertCount(PersonObject, 2U, @"age > 28");

    // query on realm with order
    RLMResults *results = [[PersonObject objectsInRealm:realm where:@"age > 28"] sortedResultsUsingKeyPath:@"age" ascending:YES];
    XCTAssertEqualObjects([results[0] name], @"Tim", @"Tim should be first results");

    // query on sorted results
    results = [[[PersonObject allObjectsInRealm:realm] sortedResultsUsingKeyPath:@"age" ascending:YES] objectsWhere:@"age > 28"];
    XCTAssertEqualObjects([results[0] name], @"Tim", @"Tim should be first results");
}

- (void)testQueryBetween {
    RLMRealm *realm = [self realm];

    [realm beginWriteTransaction];
    AllTypesObject *a = [AllTypesObject createInRealm:realm withValue:[AllTypesObject values:1 stringObject:nil]];
    AllTypesObject *b = [AllTypesObject createInRealm:realm withValue:[AllTypesObject values:2 stringObject:nil]];
    AllTypesObject *c = [AllTypesObject createInRealm:realm withValue:[AllTypesObject values:3 stringObject:nil]];
    AllTypesObject *d = [AllTypesObject createInRealm:realm withValue:[AllTypesObject values:4 stringObject:nil]];

    [ArrayOfAllTypesObject createInRealm:realm withValue:@[@[a, c]]];
    [ArrayOfAllTypesObject createInRealm:realm withValue:@[@[b, d]]];
    [DictionaryOfAllTypesObject createInRealm:realm withValue:@[@{@"1": a, @"3": c}]];
    [DictionaryOfAllTypesObject createInRealm:realm withValue:@[@{@"2": b, @"4": d}]];
    [SetOfAllTypesObject createInRealm:realm withValue:@[@[a, c]]];
    [SetOfAllTypesObject createInRealm:realm withValue:@[@[b, d]]];

    [realm commitWriteTransaction];

    RLMAssertCount(AllTypesObject, 4U, @"intCol BETWEEN %@", @[@0, @5]);
    RLMAssertCount(AllTypesObject, 2U, @"intCol BETWEEN %@", @[@2, @3]);
    RLMAssertCount(AllTypesObject, 2U, @"intCol BETWEEN {2, 3}");
    RLMAssertCount(ArrayOfAllTypesObject, 1U, @"ANY array.intCol BETWEEN %@", @[@4, @5]);
    RLMAssertCount(SetOfAllTypesObject, 1U, @"ANY set.intCol BETWEEN %@", @[@4, @5]);
    RLMAssertCount(DictionaryOfAllTypesObject, 1U, @"ANY dictionary.intCol BETWEEN %@", @[@4, @5]);

    RLMAssertCount(AllTypesObject, 4U, @"floatCol BETWEEN %@", @[@1.0f, @5.0f]);
    RLMAssertCount(AllTypesObject, 2U, @"floatCol BETWEEN %@", @[@2.0f, @4.0f]);
    RLMAssertCount(AllTypesObject, 2U, @"floatCol BETWEEN {2, 4}");
    RLMAssertCount(ArrayOfAllTypesObject, 0U, @"ANY array.floatCol BETWEEN %@", @[@3.1, @3.2]);
    RLMAssertCount(SetOfAllTypesObject, 0U, @"ANY set.floatCol BETWEEN %@", @[@3.1, @3.2]);
    RLMAssertCount(DictionaryOfAllTypesObject, 0U, @"ANY dictionary.floatCol BETWEEN %@", @[@3.1, @3.2]);

    RLMAssertCount(AllTypesObject, 4U, @"doubleCol BETWEEN %@", @[@1.0, @5.0]);
    RLMAssertCount(AllTypesObject, 2U, @"doubleCol BETWEEN %@", @[@2.0, @4.0]);
    RLMAssertCount(AllTypesObject, 2U, @"doubleCol BETWEEN {3.0, 7.0}");
    RLMAssertCount(ArrayOfAllTypesObject, 0U, @"ANY array.doubleCol BETWEEN %@", @[@3.1, @3.2]);
    RLMAssertCount(SetOfAllTypesObject, 0U, @"ANY set.doubleCol BETWEEN %@", @[@3.1, @3.2]);
    RLMAssertCount(DictionaryOfAllTypesObject, 0U, @"ANY dictionary.doubleCol BETWEEN %@", @[@3.1, @3.2]);

    RLMAssertCount(AllTypesObject, 2U, @"dateCol BETWEEN %@", @[[b dateCol], [c dateCol]]);
    RLMAssertCount(ArrayOfAllTypesObject, 2U, @"ANY array.dateCol BETWEEN %@", @[[b dateCol], [c dateCol]]);
    RLMAssertCount(SetOfAllTypesObject, 2U, @"ANY set.dateCol BETWEEN %@", @[[b dateCol], [c dateCol]]);
    RLMAssertCount(DictionaryOfAllTypesObject, 2U, @"ANY dictionary.dateCol BETWEEN %@", @[[b dateCol], [c dateCol]]);

    RLMAssertCount(AllTypesObject, 1U, @"longCol BETWEEN %@", @[@5000000000LL, @7000000000LL]);
    RLMAssertCount(AllTypesObject, 1U, @"longCol BETWEEN {5000000000, 7000000000}");
    RLMAssertCount(ArrayOfAllTypesObject, 1U, @"ANY array.longCol BETWEEN %@", @[@5000000000LL, @7000000000LL]);
    RLMAssertCount(SetOfAllTypesObject, 1U, @"ANY set.longCol BETWEEN %@", @[@5000000000LL, @7000000000LL]);
    RLMAssertCount(DictionaryOfAllTypesObject, 1U, @"ANY dictionary.longCol BETWEEN %@", @[@5000000000LL, @7000000000LL]);

    RLMAssertCount(AllTypesObject, 4U, @"decimalCol BETWEEN %@", @[@0, @5]);
    RLMAssertCount(AllTypesObject, 4U, @"decimalCol BETWEEN %@", @[[[RLMDecimal128 alloc] initWithNumber:@0],
                                                                   [[RLMDecimal128 alloc] initWithNumber:@5]]);
    RLMAssertCount(AllTypesObject, 4U, @"decimalCol BETWEEN {0, 5}");
    RLMAssertCount(AllTypesObject, 3U, @"decimalCol BETWEEN {'0e1', '30e-1'}");

    RLMAssertCount(AllTypesObject, 4U, @"anyCol BETWEEN %@", @[@0, @5]);
    RLMAssertCount(AllTypesObject, 2U, @"anyCol BETWEEN %@", @[@2, @3]);
    RLMAssertCount(AllTypesObject, 2U, @"anyCol BETWEEN {2, 3}");
    RLMAssertCount(ArrayOfAllTypesObject, 2U, @"ANY array.anyCol BETWEEN %@", @[@4, @5]);
    RLMAssertCount(SetOfAllTypesObject, 2U, @"ANY set.anyCol BETWEEN %@", @[@4, @5]);
    RLMAssertCount(DictionaryOfAllTypesObject, 2U, @"ANY dictionary.anyCol BETWEEN %@", @[@4, @5]);

    RLMResults *allObjects = [AllTypesObject allObjectsInRealm:realm];
    RLMAssertThrowsWithReason([allObjects objectsWhere:@"boolCol BETWEEN {true, false}"],
                              @"Operator 'BETWEEN' not supported for type 'bool'");
    RLMAssertThrowsWithReason([allObjects objectsWhere:@"stringCol BETWEEN {'', ''}"],
                              @"Operator 'BETWEEN' not supported for type 'string'");
    RLMAssertThrowsWithReason(([allObjects objectsWhere:@"binaryCol BETWEEN %@", @[NSData.data, NSData.data]]),
                              @"Operator 'BETWEEN' not supported for type 'data'");
    RLMAssertThrowsWithReason([allObjects objectsWhere:@"cBoolCol BETWEEN {true, false}"],
                              @"Operator 'BETWEEN' not supported for type 'bool'");
    RLMAssertThrowsWithReason(([allObjects objectsWhere:@"objectIdCol BETWEEN %@",
                                @[[RLMObjectId objectId], [RLMObjectId objectId]]]),
                              @"Operator 'BETWEEN' not supported for type 'object id'");
}

- (void)testQueryWithDates {
    RLMRealm *realm = [self realm];
    [realm beginWriteTransaction];
    AllTypesObject *all0 = [AllTypesObject createInRealm:realm withValue:[AllTypesObject values:1 stringObject:nil]];
    AllTypesObject *all1 = [AllTypesObject createInRealm:realm withValue:[AllTypesObject values:2 stringObject:nil]];
    AllTypesObject *all2 = [AllTypesObject createInRealm:realm withValue:[AllTypesObject values:3 stringObject:nil]];
    all0.anyCol = all0.dateCol;
    all1.anyCol = all1.dateCol;
    all2.anyCol = all2.dateCol;

    [realm commitWriteTransaction];

    NSArray<NSDate *> *dates = [[AllTypesObject allObjectsInRealm:realm] valueForKey:@"dateCol"];

    RLMAssertCount(AllTypesObject, 2U, @"dateCol < %@", dates[2]);
    RLMAssertCount(AllTypesObject, 3U, @"dateCol <= %@", dates[2]);
    RLMAssertCount(AllTypesObject, 2U, @"dateCol > %@", dates[0]);
    RLMAssertCount(AllTypesObject, 3U, @"dateCol >= %@", dates[0]);
    RLMAssertCount(AllTypesObject, 1U, @"dateCol == %@", dates[0]);
    RLMAssertCount(AllTypesObject, 2U, @"dateCol != %@", dates[0]);

    RLMAssertCount(AllTypesObject, 2U, @"%@ < dateCol", dates[0]);
    RLMAssertCount(AllTypesObject, 3U, @"%@ <= dateCol", dates[0]);
    RLMAssertCount(AllTypesObject, 2U, @"%@ > dateCol", dates[2]);
    RLMAssertCount(AllTypesObject, 3U, @"%@ >= dateCol", dates[2]);
    RLMAssertCount(AllTypesObject, 1U, @"%@ == dateCol", dates[0]);
    RLMAssertCount(AllTypesObject, 2U, @"%@ != dateCol", dates[0]);

    RLMAssertCount(AllTypesObject, 2U, @"anyCol < %@", dates[2]);
    RLMAssertCount(AllTypesObject, 3U, @"anyCol <= %@", dates[2]);
    RLMAssertCount(AllTypesObject, 2U, @"anyCol > %@", dates[0]);
    RLMAssertCount(AllTypesObject, 3U, @"anyCol >= %@", dates[0]);
    RLMAssertCount(AllTypesObject, 1U, @"anyCol == %@", dates[0]);
    RLMAssertCount(AllTypesObject, 2U, @"anyCol != %@", dates[0]);

    RLMAssertCount(AllTypesObject, 2U, @"%@ < anyCol", dates[0]);
    RLMAssertCount(AllTypesObject, 3U, @"%@ <= anyCol", dates[0]);
    RLMAssertCount(AllTypesObject, 2U, @"%@ > anyCol", dates[2]);
    RLMAssertCount(AllTypesObject, 3U, @"%@ >= anyCol", dates[2]);
    RLMAssertCount(AllTypesObject, 1U, @"%@ == anyCol", dates[0]);
    RLMAssertCount(AllTypesObject, 2U, @"%@ != anyCol", dates[0]);
}

- (void)testDefaultRealmQuery {
    RLMRealm *realm = [self realm];

    [realm beginWriteTransaction];
    [PersonObject createInRealm:realm withValue:@[@"Fiel", @27]];
    [PersonObject createInRealm:realm withValue:@[@"Tim", @29]];
    [PersonObject createInRealm:realm withValue:@[@"Ari", @33]];
    [realm commitWriteTransaction];

    // query on class
    XCTAssertEqual([PersonObject allObjects].count, 3U);
    RLMAssertCount(PersonObject, 1U, @"age == 27");

    // with order
    RLMResults *results = [[PersonObject objectsWhere:@"age > 28"] sortedResultsUsingKeyPath:@"age" ascending:YES];
    PersonObject *tim = results[0];
    XCTAssertEqualObjects(tim.name, @"Tim", @"Tim should be first results");
}

- (void)testUuidRealmQuery {
    RLMRealm *realm = [self realm];

    [realm beginWriteTransaction];
    [UuidObject createInRealm:realm withValue:@[[[NSUUID alloc] initWithUUIDString:@"00000000-0000-0000-0000-000000000000"]]];
    [UuidObject createInRealm:realm withValue:@[[[NSUUID alloc] initWithUUIDString:@"137DECC8-B300-4954-A233-F89909F4FD89"]]];

    [MixedObject createInRealm:realm withValue:@[[[NSUUID alloc] initWithUUIDString:@"00000000-0000-0000-0000-000000000000"]]];
    [MixedObject createInRealm:realm withValue:@[[[NSUUID alloc] initWithUUIDString:@"137DECC8-B300-4954-A233-F89909F4FD89"]]];
    [realm commitWriteTransaction];

    // query on class
    XCTAssertEqual([UuidObject allObjects].count, 2U);
    RLMAssertCount(UuidObject, 1U, @"uuidCol == %@", [[NSUUID alloc] initWithUUIDString:@"137DECC8-B300-4954-A233-F89909F4FD89"]);
    XCTAssertEqual([MixedObject allObjects].count, 2U);
    RLMAssertCount(MixedObject, 1U, @"anyCol == %@", [[NSUUID alloc] initWithUUIDString:@"137DECC8-B300-4954-A233-F89909F4FD89"]);
}

- (void)testRLMValueQuery {
    RLMRealm *realm = [self realm];
    [realm beginWriteTransaction];

    NSArray *allValues = @[@YES,
                           @NO,
                           @true,
                           @false,
                           @TRUE,
                           @FALSE,
                           @"0",
                           @"1",
                           @0,
                           @1,
                           @0.0,
                           @1.0,
                           @0.0f,
                           @1.0f,
                           [[RLMDecimal128 alloc] initWithNumber:@(0)],
                           [[RLMDecimal128 alloc] initWithNumber:@(1)],
                           [NSData dataWithBytes:"0" length:1],
                           [NSData dataWithBytes:"1" length:1],
                           [NSDate dateWithTimeIntervalSince1970:0],
                           [NSDate dateWithTimeIntervalSince1970:1],
                           [RLMObjectId objectId],
                           [[NSUUID alloc] initWithUUIDString:@"85d4fbee-6ec6-47df-bfa1-615931903d7e"],
                           NSNull.null,
    ];

    StringObject *stringObj = [StringObject new];
    stringObj.stringCol = @"required-string";
    ArrayOfAllTypesObject *arrayOfAll = [ArrayOfAllTypesObject createInRealm:realm withValue:@{}];

    for (int i = 0; i < (int)allValues.count; i++) {
        AllTypesObject *obj = [AllTypesObject createInRealm:realm withValue:[AllTypesObject values:i stringObject:stringObj]];
        obj.anyCol = allValues[i];
        [arrayOfAll.array addObject:obj];
    }
    [realm commitWriteTransaction];

    // Numeric based comparability
    RLMAssertCount(AllTypesObject, 6U, @"anyCol BETWEEN %@", @[@1, @2]);
    RLMAssertCount(AllTypesObject, 6U, @"anyCol BETWEEN {1, 2}");
    RLMAssertCount(AllTypesObject, 1U, @"anyCol == FALSE");
    RLMAssertCount(AllTypesObject, 6U, @"anyCol == 0");
    RLMAssertCount(AllTypesObject, 22, @"anyCol != false");
    RLMAssertCount(AllTypesObject, 22, @"anyCol != FALSE");
    RLMAssertCount(AllTypesObject, 22, @"anyCol != NO");
    RLMAssertCount(AllTypesObject, 17, @"anyCol != 0");
    RLMAssertCount(AllTypesObject, 6U, @"anyCol < 1");
    RLMAssertCount(AllTypesObject, 0U, @"anyCol > 1");
    RLMAssertCount(AllTypesObject, 6U, @"anyCol >= 1");
    RLMAssertCount(AllTypesObject, 12U, @"anyCol <= 1");

    XCTAssertThrowsSpecificNamed([AllTypesObject objectsWhere:@"anyCol BETWEEN TRUE"],
                                 NSException,
                                 @"Invalid value",
                                 @"object must be of type NSArray for BETWEEN operations");

    // Binary based comparability
    RLMAssertCount(AllTypesObject, 2U, @"anyCol == '0'");
    RLMAssertCount(AllTypesObject, allValues.count-2, @"anyCol != '0'");
    RLMAssertCount(AllTypesObject, 2U, @"anyCol BEGINSWITH '1'");
    RLMAssertCount(AllTypesObject, 0U, @"anyCol BEGINSWITH 'a'");
    RLMAssertCount(AllTypesObject, 2U, @"anyCol ENDSWITH '1'");
    RLMAssertCount(AllTypesObject, 0U, @"anyCol ENDSWITH 'a'");
    RLMAssertCount(AllTypesObject, 2U, @"anyCol CONTAINS '1'");
    RLMAssertCount(AllTypesObject, 0U, @"anyCol CONTAINS 'a'");

    XCTAssertThrowsSpecificNamed([AllTypesObject objectsWhere:@"anyCol CONATINS 0"],
                                 NSException,
                                 NSInvalidArgumentException,
                                 @"Unable to parse the format string \"anyCol CONATINS 0\"");

    RLMAssertCount(AllTypesObject, 0U, @"anyCol BEGINSWITH '%@'", @0);
    RLMAssertCount(AllTypesObject, 0U, @"anyCol ENDSWITH '%@'", @0);

    RLMAssertCount(AllTypesObject, 1U, @"anyCol == %@", [NSDate dateWithTimeIntervalSince1970:0]);
    RLMAssertCount(AllTypesObject, allValues.count, @"anyCol != %@", [NSDate dateWithTimeIntervalSince1970:123]);

    RLMAssertCount(AllTypesObject, 1U, @"anyCol == %@", [[NSUUID alloc] initWithUUIDString:@"85d4fbee-6ec6-47df-bfa1-615931903d7e"]);
    RLMAssertCount(AllTypesObject, allValues.count-1, @"anyCol != %@", [[NSUUID alloc] initWithUUIDString:@"85d4fbee-6ec6-47df-bfa1-615931903d7e"]);

    XCTAssertThrowsSpecificNamed([AllTypesObject objectsWhere:@"anyCol BETWEEN '85d4fbee-6ec6-47df-bfa1-615931903d7e'"],
                                 NSException,
                                 @"Invalid value",
                                 @"object must be of type NSArray for BETWEEN operations");

    RLMAssertCount(AllTypesObject, 1U, @"anyCol == NULL");
    RLMAssertCount(AllTypesObject, allValues.count-1, @"anyCol != NULL");
}

- (void)testArrayQuery
{
    RLMRealm *realm = [self realm];

    [realm beginWriteTransaction];
    [PersonObject createInRealm:realm withValue:@[@"Fiel", @27]];
    [PersonObject createInRealm:realm withValue:@[@"Tim", @29]];
    [PersonObject createInRealm:realm withValue:@[@"Ari", @33]];
    [realm commitWriteTransaction];

    // query on class
    RLMResults *all = [PersonObject allObjects];
    XCTAssertEqual(all.count, 3U, @"Expecting 3 results");

    RLMResults *some = [[PersonObject objectsWhere:@"age > 28"] sortedResultsUsingKeyPath:@"age" ascending:YES];

    // query/order on array
    RLMAssertCount(all, 1U, @"age == 27");
    RLMAssertCount(all, 0U, @"age == 28");
    some = [some sortedResultsUsingKeyPath:@"age" ascending:NO];
    XCTAssertEqualObjects([some[0] name], @"Ari", @"Ari should be first results");
}

- (void)verifySort:(RLMRealm *)realm column:(NSString *)column ascending:(BOOL)ascending expected:(id)val {
    RLMResults *results = [[AllTypesObject allObjectsInRealm:realm] sortedResultsUsingKeyPath:column ascending:ascending];
    AllTypesObject *obj = results[0];
    XCTAssertEqualObjects(obj[column], val, @"%@", column);

    RLMArray *ar = [(ArrayPropertyObject *)[[ArrayOfAllTypesObject allObjectsInRealm:realm] firstObject] array];
    results = [ar sortedResultsUsingKeyPath:column ascending:ascending];
    obj = results[0];
    XCTAssertEqualObjects(obj[column], val, @"%@", column);
}

- (void)testEmbeddedObjectQuery {
    RLMRealm *realm = [self realm];
    [realm beginWriteTransaction];
    EmbeddedIntParentObject *obj0 = [EmbeddedIntParentObject createInRealm:realm withValue:@[@1, @[@2], @[@[@3]]]];
    EmbeddedIntParentObject *obj1 = [EmbeddedIntParentObject createInRealm:realm withValue:@[@4, @[@5], @[@[@6]]]];
    EmbeddedIntParentObject *obj2 = [EmbeddedIntParentObject createInRealm:realm withValue:@[@7, @[@8], @[@[@9]]]];
    [realm commitWriteTransaction];

    // Query parent objects based on property of embedded object
    RLMResults *r0 = [EmbeddedIntParentObject objectsWhere:@"object.intCol = 2"];
    XCTAssertEqualObjects(r0[0], obj0);
    XCTAssert(r0.count == 1);

    // Query parent objects based on array of embedded objects
    RLMResults *r1 = [EmbeddedIntParentObject objectsWhere:@"ANY array.intCol > 4"];
    XCTAssertEqualObjects(r1[0], obj1);
    XCTAssertEqualObjects(r1[1], obj2);
    XCTAssert(r1.count == 2);

    // Compound query using two different embedded object properties
    RLMResults *r2 = [EmbeddedIntParentObject objectsWhere:@"ANY array.intCol > 4 and object.intCol = 5"];
    XCTAssertEqualObjects(r2[0], obj1);
    XCTAssert(r2.count == 1);

    // Aggregate query on embedded object array, sort using embedded object key path
    RLMResults *r3 = [[EmbeddedIntParentObject objectsWhere:@"array.@max.intCol < 9"]
                      sortedResultsUsingKeyPath:@"object.intCol" ascending:NO];
    XCTAssertEqualObjects(r3[0], obj1);
    XCTAssertEqualObjects(r3[1], obj0);
    XCTAssert(r3.count == 2);
}

- (void)testQuerySorting
{
    RLMRealm *realm = [self realm];

    [realm beginWriteTransaction];
    StringObject *stringObj = [StringObject new];
    stringObj.stringCol = @"string";

    ArrayOfAllTypesObject *arrayOfAll = [ArrayOfAllTypesObject createInRealm:realm withValue:@{}];
    DictionaryOfAllTypesObject *dictionaryOfAll = [DictionaryOfAllTypesObject createInRealm:realm withValue:
                                                   @{@"dictionary": @{
                                                             @"1": [AllTypesObject values:1 stringObject:stringObj],
                                                             @"2": [AllTypesObject values:2 stringObject:stringObj],
                                                             @"3": [AllTypesObject values:3 stringObject:stringObj],
                                                             @"4": [AllTypesObject values:4 stringObject:stringObj],
                                                   }}];
    SetOfAllTypesObject *setOfAll = [SetOfAllTypesObject createInRealm:realm withValue:@{}];

    [arrayOfAll.array addObjects:@[
        [AllTypesObject values:1 stringObject:stringObj],
        [AllTypesObject values:2 stringObject:stringObj],
        [AllTypesObject values:3 stringObject:stringObj],
        [AllTypesObject values:4 stringObject:stringObj],
    ]];
    [setOfAll.set addObjects:@[
        [AllTypesObject values:1 stringObject:stringObj],
        [AllTypesObject values:2 stringObject:stringObj],
        [AllTypesObject values:3 stringObject:stringObj],
        [AllTypesObject values:4 stringObject:stringObj],
    ]];
    arrayOfAll.array[0].anyCol = @NO;
    arrayOfAll.array[1].anyCol = [NSNull null];
    arrayOfAll.array[2].anyCol = @1;
    arrayOfAll.array[3].anyCol = [[NSUUID alloc] initWithUUIDString:@"B9D325B0-3058-4838-8473-8F1AAAE410DB"];
    [realm commitWriteTransaction];

    //////////// sort by boolCol
    [self verifySort:realm column:@"boolCol" ascending:YES expected:@NO];
    [self verifySort:realm column:@"boolCol" ascending:NO expected:@YES];

    //////////// sort by intCol
    [self verifySort:realm column:@"intCol" ascending:YES expected:@1];
    [self verifySort:realm column:@"intCol" ascending:NO expected:@4];

    //////////// sort by dateCol
    [self verifySort:realm column:@"dateCol" ascending:YES expected:arrayOfAll.array[0].dateCol];
    [self verifySort:realm column:@"dateCol" ascending:NO expected:arrayOfAll.array[3].dateCol];

    //////////// sort by doubleCol
    [self verifySort:realm column:@"doubleCol" ascending:YES expected:@1.11];
    [self verifySort:realm column:@"doubleCol" ascending:NO expected:@4.44];

    //////////// sort by floatCol
    [self verifySort:realm column:@"floatCol" ascending:YES expected:@1.1f];
    [self verifySort:realm column:@"floatCol" ascending:NO expected:@4.4f];

    //////////// sort by stringCol
    [self verifySort:realm column:@"stringCol" ascending:YES expected:@"a"];
    [self verifySort:realm column:@"stringCol" ascending:NO expected:@"d"];

    //////////// sort by decimalCol
    [self verifySort:realm column:@"decimalCol" ascending:YES expected:[RLMDecimal128 decimalWithNumber:@1]];
    [self verifySort:realm column:@"decimalCol" ascending:NO expected:[RLMDecimal128 decimalWithNumber:@4]];

    //////////// sort by uuidCol
    [self verifySort:realm column:@"uuidCol" ascending:YES expected:[[NSUUID alloc] initWithUUIDString:@"00000000-0000-0000-0000-000000000000"]];
    [self verifySort:realm column:@"uuidCol" ascending:NO expected:[[NSUUID alloc] initWithUUIDString:@"B9D325B0-3058-4838-8473-8F1AAAE410DB"]];

    //////////// sort by anyCol
    //////////// nulls < strings, binaries < numerics < timestamps < objectId < uuid.
    [self verifySort:realm column:@"anyCol" ascending:YES expected:nil];
    [self verifySort:realm column:@"anyCol" ascending:NO expected:[[NSUUID alloc] initWithUUIDString:@"B9D325B0-3058-4838-8473-8F1AAAE410DB"]];

    // sort invalid name
    RLMAssertThrowsWithReason([[AllTypesObject allObjects] sortedResultsUsingKeyPath:@"invalidCol" ascending:YES],
                              @"Cannot sort on key path 'invalidCol': property 'AllTypesObject.invalidCol' does not exist.");
    RLMAssertThrowsWithReason([arrayOfAll.array sortedResultsUsingKeyPath:@"invalidCol" ascending:NO],
                              @"Cannot sort on key path 'invalidCol': property 'AllTypesObject.invalidCol' does not exist.");
    RLMAssertThrowsWithReason([setOfAll.set sortedResultsUsingKeyPath:@"invalidCol" ascending:NO],
                              @"Cannot sort on key path 'invalidCol': property 'AllTypesObject.invalidCol' does not exist.");
    RLMAssertThrowsWithReason([dictionaryOfAll.dictionary sortedResultsUsingKeyPath:@"invalidCol" ascending:NO],
                              @"Cannot sort on key path 'invalidCol': property 'AllTypesObject.invalidCol' does not exist.");
}

- (void)testSortByNoColumns {
    RLMRealm *realm = [RLMRealm defaultRealm];
    [realm beginWriteTransaction];
    DogObject *a2 = [DogObject createInDefaultRealmWithValue:@[@"a", @2]];
    DogObject *b1 = [DogObject createInDefaultRealmWithValue:@[@"b", @1]];
    DogObject *a1 = [DogObject createInDefaultRealmWithValue:@[@"a", @1]];
    DogObject *b2 = [DogObject createInDefaultRealmWithValue:@[@"b", @2]];
    [realm commitWriteTransaction];

    RLMResults *notActuallySorted = [DogObject.allObjects sortedResultsUsingDescriptors:@[]];
    XCTAssertTrue([a2 isEqualToObject:notActuallySorted[0]]);
    XCTAssertTrue([b1 isEqualToObject:notActuallySorted[1]]);
    XCTAssertTrue([a1 isEqualToObject:notActuallySorted[2]]);
    XCTAssertTrue([b2 isEqualToObject:notActuallySorted[3]]);
}

- (void)testSortByMultipleColumns {
    RLMRealm *realm = [self realm];
    [realm beginWriteTransaction];
    DogObject *a1 = [DogObject createInDefaultRealmWithValue:@[@"a", @1]];
    DogObject *a2 = [DogObject createInDefaultRealmWithValue:@[@"a", @2]];
    DogObject *b1 = [DogObject createInDefaultRealmWithValue:@[@"b", @1]];
    DogObject *b2 = [DogObject createInDefaultRealmWithValue:@[@"b", @2]];
    [realm commitWriteTransaction];

    bool (^checkOrder)(NSArray *, NSArray *, NSArray *) = ^bool(NSArray *properties, NSArray *ascending, NSArray *dogs) {
        NSArray *sort = @[[RLMSortDescriptor sortDescriptorWithKeyPath:properties[0] ascending:[ascending[0] boolValue]],
                          [RLMSortDescriptor sortDescriptorWithKeyPath:properties[1] ascending:[ascending[1] boolValue]]];
        RLMResults *actual = [DogObject.allObjects sortedResultsUsingDescriptors:sort];
        return [actual[0] isEqualToObject:dogs[0]]
            && [actual[1] isEqualToObject:dogs[1]]
            && [actual[2] isEqualToObject:dogs[2]]
            && [actual[3] isEqualToObject:dogs[3]];
    };

    // Check each valid sort
    XCTAssertTrue(checkOrder(@[@"dogName", @"age"], @[@YES, @YES], @[a1, a2, b1, b2]));
    XCTAssertTrue(checkOrder(@[@"dogName", @"age"], @[@YES, @NO], @[a2, a1, b2, b1]));
    XCTAssertTrue(checkOrder(@[@"dogName", @"age"], @[@NO, @YES], @[b1, b2, a1, a2]));
    XCTAssertTrue(checkOrder(@[@"dogName", @"age"], @[@NO, @NO], @[b2, b1, a2, a1]));
    XCTAssertTrue(checkOrder(@[@"age", @"dogName"], @[@YES, @YES], @[a1, b1, a2, b2]));
    XCTAssertTrue(checkOrder(@[@"age", @"dogName"], @[@YES, @NO], @[b1, a1, b2, a2]));
    XCTAssertTrue(checkOrder(@[@"age", @"dogName"], @[@NO, @YES], @[a2, b2, a1, b1]));
    XCTAssertTrue(checkOrder(@[@"age", @"dogName"], @[@NO, @NO], @[b2, a2, b1, a1]));
}

- (void)testSortByKeyPath {
    RLMRealm *realm = [self realm];

    [realm beginWriteTransaction];
    DogObject *lucy = [DogObject createInDefaultRealmWithValue:@[@"Lucy", @7]];
    DogObject *freyja = [DogObject createInDefaultRealmWithValue:@[@"Freyja", @6]];
    DogObject *ziggy = [DogObject createInDefaultRealmWithValue:@[@"Ziggy", @9]];

    OwnerObject *mark = [OwnerObject createInDefaultRealmWithValue:@[@"Mark", freyja]];
    OwnerObject *diane = [OwnerObject createInDefaultRealmWithValue:@[@"Diane", lucy]];
    OwnerObject *hannah = [OwnerObject createInDefaultRealmWithValue:@[@"Hannah"]];
    OwnerObject *don = [OwnerObject createInDefaultRealmWithValue:@[@"Don", ziggy]];
    OwnerObject *diane_sr = [OwnerObject createInDefaultRealmWithValue:@[@"Diane Sr", ziggy]];

    [realm commitWriteTransaction];

    NSArray *(^asArray)(RLMResults *) = ^(RLMResults *results) {
        return [[self evaluate:results] valueForKeyPath:@"self"];
    };

    RLMResults *r1 = [OwnerObject.allObjects sortedResultsUsingKeyPath:@"dog.age" ascending:YES];
    XCTAssertEqualObjects(asArray(r1), (@[ mark, diane, don, diane_sr, hannah ]));

    RLMResults *r2 = [OwnerObject.allObjects sortedResultsUsingKeyPath:@"dog.age" ascending:NO];
    XCTAssertEqualObjects(asArray(r2), (@[ hannah, don, diane_sr, diane, mark ]));

    RLMResults *r3 = [OwnerObject.allObjects sortedResultsUsingDescriptors:@[
                         [RLMSortDescriptor sortDescriptorWithKeyPath:@"dog.age" ascending:YES],
                         [RLMSortDescriptor sortDescriptorWithKeyPath:@"name" ascending:YES]
    ]];
    XCTAssertEqualObjects(asArray(r3), (@[ mark, diane, diane_sr, don, hannah ]));

    RLMResults *r4 = [OwnerObject.allObjects sortedResultsUsingDescriptors:@[
                         [RLMSortDescriptor sortDescriptorWithKeyPath:@"dog.age" ascending:NO],
                         [RLMSortDescriptor sortDescriptorWithKeyPath:@"name" ascending:YES]
    ]];
    XCTAssertEqualObjects(asArray(r4), (@[ hannah, diane_sr, don, diane, mark ]));
}

- (void)testSortByUnspportedKeyPath {
    // Array property
    RLMAssertThrowsWithReason([DogArrayObject.allObjects sortedResultsUsingKeyPath:@"dogs.age" ascending:YES],
                              @"Cannot sort on key path 'dogs.age': property 'DogArrayObject.dogs' is of unsupported type 'array'.");

    // Backlinks property
    RLMAssertThrowsWithReason([DogObject.allObjects sortedResultsUsingKeyPath:@"owners.name" ascending:YES],
                              @"Cannot sort on key path 'owners.name': property 'DogObject.owners' is of unsupported type 'linking objects'.");

    // Collection operator
    RLMAssertThrowsWithReason([DogArrayObject.allObjects sortedResultsUsingKeyPath:@"dogs.@count" ascending:YES],
                              @"Cannot sort on key path 'dogs.@count': KVC collection operators are not supported.");
}

- (void)testSortedLinkViewWithDeletion {
    RLMRealm *realm = [self realm];

    [realm beginWriteTransaction];

    StringObject *stringObj = [StringObject new];
    stringObj.stringCol = @"string";

    ArrayOfAllTypesObject *arrayOfAll = [ArrayOfAllTypesObject createInRealm:realm withValue:@{}];
    SetOfAllTypesObject *setOfAll = [SetOfAllTypesObject createInRealm:realm withValue:@{}];
    DictionaryOfAllTypesObject *dictOfAll = [DictionaryOfAllTypesObject createInRealm:realm withValue:
                                             @{@"dictionary": @{
                                                       @"1": [AllTypesObject values:1 stringObject:stringObj],
                                                       @"2": [AllTypesObject values:2 stringObject:stringObj],
                                                       @"3": [AllTypesObject values:3 stringObject:stringObj],
                                                       @"4": [AllTypesObject values:4 stringObject:stringObj],
                                             }}];
    [arrayOfAll.array addObjects:@[
        [AllTypesObject values:1 stringObject:stringObj],
        [AllTypesObject values:2 stringObject:stringObj],
        [AllTypesObject values:3 stringObject:stringObj],
        [AllTypesObject values:4 stringObject:stringObj],
    ]];

    [setOfAll.set addObjects:@[
        [AllTypesObject values:1 stringObject:stringObj],
        [AllTypesObject values:2 stringObject:stringObj],
        [AllTypesObject values:3 stringObject:stringObj],
        [AllTypesObject values:4 stringObject:stringObj],
    ]];

    [realm commitWriteTransaction];

    RLMResults *results = [arrayOfAll.array sortedResultsUsingKeyPath:@"stringCol" ascending:NO];
    XCTAssertEqualObjects([results[0] stringCol], @"d");

    RLMResults *results2 = [setOfAll.set sortedResultsUsingKeyPath:@"stringCol" ascending:NO];
    XCTAssertEqualObjects([results2[0] stringCol], @"d");

    RLMResults *results3 = [dictOfAll.dictionary sortedResultsUsingKeyPath:@"stringCol" ascending:NO];
    XCTAssertEqualObjects([results3[0] stringCol], @"d");

    // delete d, add e results should update
    [realm transactionWithBlock:^{
        [arrayOfAll.array removeObjectAtIndex:3];
        [setOfAll.set removeObject:setOfAll.set.allObjects[3]];
        [dictOfAll.dictionary removeObjectForKey:@"4"];
        [arrayOfAll.array addObject:(id)[AllTypesObject values:5 stringObject:stringObj]];
        [setOfAll.set addObject:(id)[AllTypesObject values:5 stringObject:stringObj]];
        dictOfAll.dictionary[@"5"] = [[AllTypesObject alloc] initWithValue:[AllTypesObject values:5 stringObject:stringObj]];
    }];
    XCTAssertEqualObjects([results[0] stringCol], @"e");
    XCTAssertEqualObjects([results[1] stringCol], @"c");
    XCTAssertEqualObjects([results2[0] stringCol], @"e");
    XCTAssertEqualObjects([results2[1] stringCol], @"c");
    XCTAssertEqualObjects([results3[0] stringCol], @"e");
    XCTAssertEqualObjects([results3[1] stringCol], @"c");

    // delete from realm should be removed from results
    [realm transactionWithBlock:^{
        [realm deleteObject:arrayOfAll.array.lastObject];
        [realm deleteObject:setOfAll.set.allObjects.lastObject];
    }];
    XCTAssertEqualObjects([results[0] stringCol], @"c");
    XCTAssertEqualObjects([results2[0] stringCol], @"c");
}

- (void)testQueryingSortedQueryPreservesOrder {
    RLMRealm *realm = [self realm];

    [realm beginWriteTransaction];
    for (int i = 0; i < 5; ++i) {
        [IntObject createInRealm:realm withValue:@[@(i)]];
    }

    ArrayPropertyObject *array = [ArrayPropertyObject createInRealm:realm withValue:@[@"name", @[], [IntObject allObjects]]];
    SetPropertyObject *set = [SetPropertyObject createInRealm:realm withValue:@[@"name", @[], [IntObject allObjects]]];
    DictionaryPropertyObject *dict = [DictionaryPropertyObject createInRealm:realm withValue:@{}];
    for (IntObject *io in [IntObject allObjects]) {
        dict.intObjDictionary[[NSUUID UUID].UUIDString] = io;
    }
    [realm commitWriteTransaction];

    RLMResults *asc = [IntObject.allObjects sortedResultsUsingKeyPath:@"intCol" ascending:YES];
    RLMResults *desc = [IntObject.allObjects sortedResultsUsingKeyPath:@"intCol" ascending:NO];

    // sanity check; would work even without sort order being preserved
    XCTAssertEqual(2, [[[asc objectsWhere:@"intCol >= 2"] firstObject] intCol]);

    // check query on allObjects and query on query
    XCTAssertEqual(4, [[[desc objectsWhere:@"intCol >= 2"] firstObject] intCol]);
    XCTAssertEqual(3, [[[[desc objectsWhere:@"intCol >= 2"] objectsWhere:@"intCol < 4"] firstObject] intCol]);

    // same thing but on an linkview
    asc = [array.intArray sortedResultsUsingKeyPath:@"intCol" ascending:YES];
    desc = [array.intArray sortedResultsUsingKeyPath:@"intCol" ascending:NO];

    XCTAssertEqual(2, [[[asc objectsWhere:@"intCol >= 2"] firstObject] intCol]);
    XCTAssertEqual(4, [[[desc objectsWhere:@"intCol >= 2"] firstObject] intCol]);
    XCTAssertEqual(3, [[[[desc objectsWhere:@"intCol >= 2"] objectsWhere:@"intCol < 4"] firstObject] intCol]);

    asc = [set.intSet sortedResultsUsingKeyPath:@"intCol" ascending:YES];
    desc = [set.intSet sortedResultsUsingKeyPath:@"intCol" ascending:NO];

    XCTAssertEqual(2, [[[asc objectsWhere:@"intCol >= 2"] firstObject] intCol]);
    XCTAssertEqual(4, [[[desc objectsWhere:@"intCol >= 2"] firstObject] intCol]);
    XCTAssertEqual(3, [[[[desc objectsWhere:@"intCol >= 2"] objectsWhere:@"intCol < 4"] firstObject] intCol]);

    asc = [dict.intObjDictionary sortedResultsUsingKeyPath:@"intCol" ascending:YES];
    desc = [dict.intObjDictionary sortedResultsUsingKeyPath:@"intCol" ascending:NO];

    XCTAssertEqual(2, [[[asc objectsWhere:@"intCol >= 2"] firstObject] intCol]);
    XCTAssertEqual(4, [[[desc objectsWhere:@"intCol >= 2"] firstObject] intCol]);
    XCTAssertEqual(3, [[[[desc objectsWhere:@"intCol >= 2"] objectsWhere:@"intCol < 4"] firstObject] intCol]);
}

- (void)testTwoColumnComparison
{
    RLMRealm *realm = [self realm];

    [realm beginWriteTransaction];

    NSArray<NSArray *> *values = [self queryObjectClassValues];
    for (id value in values) {
        [self.queryObjectClass createInRealm:realm withValue:value];
    }
    QueryObject *first = [[self.queryObjectClass allObjectsInRealm:realm] firstObject];
    first.object1 = first;

    [realm commitWriteTransaction];

    RLMAssertCount(self.queryObjectClass, 7U, @"bool1 == bool1");
    RLMAssertCount(self.queryObjectClass, 3U, @"bool1 == bool2");
    RLMAssertCount(self.queryObjectClass, 4U, @"bool1 != bool2");

    RLMAssertCount(self.queryObjectClass, 7U, @"int1 == int1");
    RLMAssertCount(self.queryObjectClass, 2U, @"int1 == int2");
    RLMAssertCount(self.queryObjectClass, 5U, @"int1 != int2");
    RLMAssertCount(self.queryObjectClass, 1U, @"int1 > int2");
    RLMAssertCount(self.queryObjectClass, 4U, @"int1 < int2");
    RLMAssertCount(self.queryObjectClass, 3U, @"int1 >= int2");
    RLMAssertCount(self.queryObjectClass, 6U, @"int1 <= int2");

    RLMAssertCount(self.queryObjectClass, 7U, @"float1 == float1");
    RLMAssertCount(self.queryObjectClass, 1U, @"float1 == float2");
    RLMAssertCount(self.queryObjectClass, 6U, @"float1 != float2");
    RLMAssertCount(self.queryObjectClass, 2U, @"float1 > float2");
    RLMAssertCount(self.queryObjectClass, 4U, @"float1 < float2");
    RLMAssertCount(self.queryObjectClass, 3U, @"float1 >= float2");
    RLMAssertCount(self.queryObjectClass, 5U, @"float1 <= float2");

    RLMAssertCount(self.queryObjectClass, 7U, @"double1 == double1");
    RLMAssertCount(self.queryObjectClass, 0U, @"double1 == double2");
    RLMAssertCount(self.queryObjectClass, 7U, @"double1 != double2");
    RLMAssertCount(self.queryObjectClass, 1U, @"double1 > double2");
    RLMAssertCount(self.queryObjectClass, 6U, @"double1 < double2");
    RLMAssertCount(self.queryObjectClass, 1U, @"double1 >= double2");
    RLMAssertCount(self.queryObjectClass, 6U, @"double1 <= double2");

    RLMAssertCount(self.queryObjectClass, 7U, @"string1 == string1");
    RLMAssertCount(self.queryObjectClass, 1U, @"string1 == string2");
    RLMAssertCount(self.queryObjectClass, 6U, @"string1 != string2");
    RLMAssertCount(self.queryObjectClass, 7U, @"string1 CONTAINS string1");
    RLMAssertCount(self.queryObjectClass, 1U, @"string1 CONTAINS string2");
    RLMAssertCount(self.queryObjectClass, 3U, @"string2 CONTAINS string1");
    RLMAssertCount(self.queryObjectClass, 7U, @"string1 BEGINSWITH string1");
    RLMAssertCount(self.queryObjectClass, 1U, @"string1 BEGINSWITH string2");
    RLMAssertCount(self.queryObjectClass, 2U, @"string2 BEGINSWITH string1");
    RLMAssertCount(self.queryObjectClass, 7U, @"string1 ENDSWITH string1");
    RLMAssertCount(self.queryObjectClass, 1U, @"string1 ENDSWITH string2");
    RLMAssertCount(self.queryObjectClass, 2U, @"string2 ENDSWITH string1");
    RLMAssertCount(self.queryObjectClass, 7U, @"string1 LIKE string1");
    RLMAssertCount(self.queryObjectClass, 1U, @"string1 LIKE string2");
    RLMAssertCount(self.queryObjectClass, 1U, @"string2 LIKE string1");

    RLMAssertCount(self.queryObjectClass, 7U, @"string1 ==[c] string1");
    RLMAssertCount(self.queryObjectClass, 2U, @"string1 ==[c] string2");
    RLMAssertCount(self.queryObjectClass, 5U, @"string1 !=[c] string2");
    RLMAssertCount(self.queryObjectClass, 7U, @"string1 CONTAINS[c] string1");
    RLMAssertCount(self.queryObjectClass, 2U, @"string1 CONTAINS[c] string2");
    RLMAssertCount(self.queryObjectClass, 6U, @"string2 CONTAINS[c] string1");
    RLMAssertCount(self.queryObjectClass, 7U, @"string1 BEGINSWITH[c] string1");
    RLMAssertCount(self.queryObjectClass, 2U, @"string1 BEGINSWITH[c] string2");
    RLMAssertCount(self.queryObjectClass, 4U, @"string2 BEGINSWITH[c] string1");
    RLMAssertCount(self.queryObjectClass, 7U, @"string1 ENDSWITH[c] string1");
    RLMAssertCount(self.queryObjectClass, 2U, @"string1 ENDSWITH[c] string2");
    RLMAssertCount(self.queryObjectClass, 4U, @"string2 ENDSWITH[c] string1");
    RLMAssertCount(self.queryObjectClass, 7U, @"string1 LIKE[c] string1");
    RLMAssertCount(self.queryObjectClass, 2U, @"string1 LIKE[c] string2");
    RLMAssertCount(self.queryObjectClass, 2U, @"string2 LIKE[c] string1");

    RLMAssertCount(self.queryObjectClass, 7U, @"data1 == data1");
    RLMAssertCount(self.queryObjectClass, 1U, @"data1 == data2");
    RLMAssertCount(self.queryObjectClass, 6U, @"data1 != data2");
    RLMAssertCount(self.queryObjectClass, 7U, @"data1 CONTAINS data1");
    RLMAssertCount(self.queryObjectClass, 1U, @"data1 CONTAINS data2");
    RLMAssertCount(self.queryObjectClass, 3U, @"data2 CONTAINS data1");
    RLMAssertCount(self.queryObjectClass, 7U, @"data1 BEGINSWITH data1");
    RLMAssertCount(self.queryObjectClass, 1U, @"data1 BEGINSWITH data2");
    RLMAssertCount(self.queryObjectClass, 2U, @"data2 BEGINSWITH data1");
    RLMAssertCount(self.queryObjectClass, 7U, @"data1 ENDSWITH data1");
    RLMAssertCount(self.queryObjectClass, 1U, @"data1 ENDSWITH data2");
    RLMAssertCount(self.queryObjectClass, 2U, @"data2 ENDSWITH data1");
    RLMAssertCount(self.queryObjectClass, 7U, @"data1 LIKE data1");
    RLMAssertCount(self.queryObjectClass, 1U, @"data1 LIKE data2");
    RLMAssertCount(self.queryObjectClass, 1U, @"data2 LIKE data1");

    RLMAssertCount(self.queryObjectClass, 7U, @"data1 ==[c] data1");
    RLMAssertCount(self.queryObjectClass, 2U, @"data1 ==[c] data2");
    RLMAssertCount(self.queryObjectClass, 5U, @"data1 !=[c] data2");
    RLMAssertCount(self.queryObjectClass, 7U, @"data1 CONTAINS[c] data1");
    RLMAssertCount(self.queryObjectClass, 2U, @"data1 CONTAINS[c] data2");
    RLMAssertCount(self.queryObjectClass, 6U, @"data2 CONTAINS[c] data1");
    RLMAssertCount(self.queryObjectClass, 7U, @"data1 BEGINSWITH[c] data1");
    RLMAssertCount(self.queryObjectClass, 2U, @"data1 BEGINSWITH[c] data2");
    RLMAssertCount(self.queryObjectClass, 4U, @"data2 BEGINSWITH[c] data1");
    RLMAssertCount(self.queryObjectClass, 7U, @"data1 ENDSWITH[c] data1");
    RLMAssertCount(self.queryObjectClass, 2U, @"data1 ENDSWITH[c] data2");
    RLMAssertCount(self.queryObjectClass, 4U, @"data2 ENDSWITH[c] data1");
    RLMAssertCount(self.queryObjectClass, 7U, @"data1 LIKE[c] data1");
    RLMAssertCount(self.queryObjectClass, 2U, @"data1 LIKE[c] data2");
    RLMAssertCount(self.queryObjectClass, 2U, @"data2 LIKE[c] data1");

    RLMAssertCount(self.queryObjectClass, 7U, @"decimal1 == decimal1");
    RLMAssertCount(self.queryObjectClass, 2U, @"decimal1 == decimal2");
    RLMAssertCount(self.queryObjectClass, 5U, @"decimal1 != decimal2");
    RLMAssertCount(self.queryObjectClass, 1U, @"decimal1 > decimal2");
    RLMAssertCount(self.queryObjectClass, 4U, @"decimal1 < decimal2");
    RLMAssertCount(self.queryObjectClass, 3U, @"decimal1 >= decimal2");
    RLMAssertCount(self.queryObjectClass, 6U, @"decimal1 <= decimal2");

    RLMAssertCount(self.queryObjectClass, 7U, @"objectId1 == objectId1");
    RLMAssertCount(self.queryObjectClass, 3U, @"objectId1 == objectId2");
    RLMAssertCount(self.queryObjectClass, 4U, @"objectId1 != objectId2");

    RLMAssertCount(self.queryObjectClass, 7U, @"object1 == object1");
    RLMAssertCount(self.queryObjectClass, 6U, @"object1 == object2");
    RLMAssertCount(self.queryObjectClass, 1U, @"object1 != object2");

    RLMAssertCount(self.queryObjectClass, 7U, @"any1 == any1");
    RLMAssertCount(self.queryObjectClass, 0U, @"any1 == any2");
    RLMAssertCount(self.queryObjectClass, 7U, @"any1 != any2");

    RLMAssertCount(self.queryObjectClass, 7U, @"any1 ==[c] any1");
    RLMAssertCount(self.queryObjectClass, 0U, @"any1 ==[c] any2");
    RLMAssertCount(self.queryObjectClass, 0U, @"any1 !=[c] any1");

    RLMAssertThrowsWithReasonMatching([self.queryObjectClass objectsWhere:@"int1 == float1"],
                                      @"Property type mismatch between int and float");
    RLMAssertThrowsWithReasonMatching([self.queryObjectClass objectsWhere:@"float2 >= double1"],
                                      @"Property type mismatch between float and double");
    RLMAssertThrowsWithReasonMatching([self.queryObjectClass objectsWhere:@"double2 <= int2"],
                                      @"Property type mismatch between double and int");
    RLMAssertThrowsWithReasonMatching([self.queryObjectClass objectsWhere:@"int2 != string1"],
                                      @"Property type mismatch between int and string");
    RLMAssertThrowsWithReasonMatching([self.queryObjectClass objectsWhere:@"float1 > string1"],
                                      @"Property type mismatch between float and string");
    RLMAssertThrowsWithReasonMatching([self.queryObjectClass objectsWhere:@"double1 < string1"],
                                      @"Property type mismatch between double and string");
    RLMAssertThrowsWithReasonMatching([self.queryObjectClass objectsWhere:@"double1 LIKE string1"],
                                      @"Property type mismatch between double and string");
    RLMAssertThrowsWithReasonMatching([self.queryObjectClass objectsWhere:@"string1 LIKE double1"],
                                      @"Property type mismatch between string and double");
}

- (void)testBooleanPredicate
{
    RLMAssertCount(BoolObject, 0U, @"boolCol == TRUE");
    RLMAssertCount(BoolObject, 0U, @"boolCol != TRUE");

    XCTAssertThrows([BoolObject objectsWhere:@"boolCol == NULL"]);
    XCTAssertThrows([BoolObject objectsWhere:@"boolCol != NULL"]);

    XCTAssertThrowsSpecificNamed([BoolObject objectsWhere:@"boolCol >= TRUE"],
                                 NSException,
                                 @"Invalid operator type",
                                 @"Invalid operator in bool predicate.");
}

- (void)testStringBeginsWith
{
    RLMRealm *realm = [self realm];

    [realm beginWriteTransaction];
    StringObject *so = [StringObject createInRealm:realm withValue:@[@"abc"]];
    [StringObject createInRealm:realm withValue:@[@"üvw"]];
    [StringObject createInRealm:realm withValue:@[@"ûvw"]];
    [StringObject createInRealm:realm withValue:@[@"uvw"]];
    [StringObject createInRealm:realm withValue:@[@"stü"]];
    AllTypesObject *ato = [AllTypesObject createInRealm:realm
                                              withValue:[AllTypesObject values:1 stringObject:so]];
    ato.anyCol = @"abc"; // overwrite int
    ato.mixedObjectCol = [MixedObject createInRealm:realm withValue:@[@"abc"]];
    [MixedObject createInRealm:realm withValue:@[@"üvw"]];
    [MixedObject createInRealm:realm withValue:@[@"ûvw"]];
    [MixedObject createInRealm:realm withValue:@[@"uvw"]];
    [MixedObject createInRealm:realm withValue:@[@"stü"]];
    [realm commitWriteTransaction];

    void (^testBlock)(NSString *, NSString *, Class) = ^(NSString * objectCol, NSString *colName, Class cls) {
        RLMAssertCount(cls, 1U, [NSString stringWithFormat:@"%@ BEGINSWITH 'a'", colName]);
        RLMAssertCount(cls, 1U, [NSString stringWithFormat:@"%@ BEGINSWITH 'ab'", colName]);
        RLMAssertCount(cls, 1U, [NSString stringWithFormat:@"%@ BEGINSWITH 'abc'", colName]);
        RLMAssertCount(cls, 0U, [NSString stringWithFormat:@"%@ BEGINSWITH 'abcd'", colName]);
        RLMAssertCount(cls, 0U, [NSString stringWithFormat:@"%@ BEGINSWITH 'abd'", colName]);
        RLMAssertCount(cls, 0U, [NSString stringWithFormat:@"%@ BEGINSWITH 'c'", colName]);
        RLMAssertCount(cls, 0U, [NSString stringWithFormat:@"%@ BEGINSWITH 'A'", colName]);
        RLMAssertCount(cls, 0U, [NSString stringWithFormat:@"%@ BEGINSWITH ''", colName]);
        RLMAssertCount(cls, 1U, [NSString stringWithFormat:@"%@ BEGINSWITH[c] 'a'", colName]);
        RLMAssertCount(cls, 1U, [NSString stringWithFormat:@"%@ BEGINSWITH[c] 'A'", colName]);
        RLMAssertCount(cls, 0U, [NSString stringWithFormat:@"%@ BEGINSWITH[c] ''", colName]);
        RLMAssertCount(cls, 0U, [NSString stringWithFormat:@"%@ BEGINSWITH[d] ''", colName]);
        RLMAssertCount(cls, 0U, [NSString stringWithFormat:@"%@ BEGINSWITH[cd] ''", colName]);

        RLMAssertCount(cls, 1U, [NSString stringWithFormat:@"%@ BEGINSWITH 'u'", colName]);
        RLMAssertCount(cls, 1U, [NSString stringWithFormat:@"%@ BEGINSWITH[c] 'U'", colName]);
        RLMAssertCount(cls, 3U, [NSString stringWithFormat:@"%@ BEGINSWITH[d] 'u'", colName]);
        RLMAssertCount(cls, 3U, [NSString stringWithFormat:@"%@ BEGINSWITH[cd] 'U'", colName]);

        RLMAssertCount(cls, 1U, [NSString stringWithFormat:@"%@ BEGINSWITH 'ü'", colName]);
        RLMAssertCount(cls, 0U, [NSString stringWithFormat:@"%@ BEGINSWITH[c] 'Ü'", colName]);
        RLMAssertCount(cls, 3U, [NSString stringWithFormat:@"%@ BEGINSWITH[d] 'ü'", colName]);
        RLMAssertCount(cls, 3U, [NSString stringWithFormat:@"%@ BEGINSWITH[cd] 'Ü'", colName]);

        RLMAssertCount(cls, 0U, [NSString stringWithFormat:@"%@ BEGINSWITH NULL", colName]);
        RLMAssertCount(cls, 0U, [NSString stringWithFormat:@"%@ BEGINSWITH[c] NULL", colName]);
        RLMAssertCount(cls, 0U, [NSString stringWithFormat:@"%@ BEGINSWITH[d] NULL", colName]);
        RLMAssertCount(cls, 0U, [NSString stringWithFormat:@"%@ BEGINSWITH[cd] NULL", colName]);

        RLMAssertCount(AllTypesObject, 1U, [NSString stringWithFormat:@"%@.%@ BEGINSWITH 'a'", objectCol, colName]);
        RLMAssertCount(AllTypesObject, 0U, [NSString stringWithFormat:@"%@.%@ BEGINSWITH 'c'", objectCol, colName]);
        RLMAssertCount(AllTypesObject, 0U, [NSString stringWithFormat:@"%@.%@ BEGINSWITH 'A'", objectCol, colName]);
        RLMAssertCount(AllTypesObject, 0U, [NSString stringWithFormat:@"%@.%@ BEGINSWITH ''", objectCol, colName]);
        RLMAssertCount(AllTypesObject, 1U, [NSString stringWithFormat:@"%@.%@ BEGINSWITH[c] 'a'", objectCol, colName]);
        RLMAssertCount(AllTypesObject, 1U, [NSString stringWithFormat:@"%@.%@ BEGINSWITH[c] 'A'", objectCol, colName]);
        RLMAssertCount(AllTypesObject, 0U, [NSString stringWithFormat:@"%@.%@ BEGINSWITH[c] ''", objectCol, colName]);
        RLMAssertCount(AllTypesObject, 0U, [NSString stringWithFormat:@"%@.%@ BEGINSWITH[d] ''", objectCol, colName]);
        RLMAssertCount(AllTypesObject, 0U, [NSString stringWithFormat:@"%@.%@ BEGINSWITH[cd] ''", objectCol, colName]);

        RLMAssertCount(AllTypesObject, 0U, [NSString stringWithFormat:@"%@.%@ BEGINSWITH NULL", objectCol, colName]);
        RLMAssertCount(AllTypesObject, 0U, [NSString stringWithFormat:@"%@.%@ BEGINSWITH[c] NULL", objectCol, colName]);
        RLMAssertCount(AllTypesObject, 0U, [NSString stringWithFormat:@"%@.%@ BEGINSWITH[d] NULL", objectCol, colName]);
        RLMAssertCount(AllTypesObject, 0U, [NSString stringWithFormat:@"%@.%@ BEGINSWITH[cd] NULL", objectCol, colName]);
    };

    testBlock(@"objectCol", @"stringCol", [StringObject class]);
    testBlock(@"mixedObjectCol", @"anyCol", [MixedObject class]);
}

- (void)testStringEndsWith
{
    RLMRealm *realm = [self realm];

    [realm beginWriteTransaction];
    StringObject *so = [StringObject createInRealm:realm withValue:@[@"abc"]];
    [StringObject createInRealm:realm withValue:@[@"üvw"]];
    [StringObject createInRealm:realm withValue:@[@"ûvw"]];
    [StringObject createInRealm:realm withValue:@[@"uvü"]];
    [StringObject createInRealm:realm withValue:@[@"stu"]];
    AllTypesObject *ato = [AllTypesObject createInRealm:realm
                                              withValue:[AllTypesObject values:1 stringObject:so]];
    ato.anyCol = @"abc"; // overwrite int
    ato.mixedObjectCol = [MixedObject createInRealm:realm withValue:@[@"abc"]];
    [MixedObject createInRealm:realm withValue:@[@"üvw"]];
    [MixedObject createInRealm:realm withValue:@[@"ûvw"]];
    [MixedObject createInRealm:realm withValue:@[@"uvü"]];
    [MixedObject createInRealm:realm withValue:@[@"stu"]];
    [realm commitWriteTransaction];

    void (^testBlock)(NSString *, NSString *, Class) = ^(NSString *objectCol, NSString *colName, Class cls) {
        RLMAssertCount(cls, 1U, [NSString stringWithFormat:@"%@ ENDSWITH 'c'", colName]);
        RLMAssertCount(cls, 1U, [NSString stringWithFormat:@"%@ ENDSWITH 'bc'", colName]);
        RLMAssertCount(cls, 1U, [NSString stringWithFormat:@"%@ ENDSWITH 'abc'", colName]);
        RLMAssertCount(cls, 0U, [NSString stringWithFormat:@"%@ ENDSWITH 'aabc'", colName]);
        RLMAssertCount(cls, 0U, [NSString stringWithFormat:@"%@ ENDSWITH 'bbc'", colName]);
        RLMAssertCount(cls, 0U, [NSString stringWithFormat:@"%@ ENDSWITH 'a'", colName]);
        RLMAssertCount(cls, 0U, [NSString stringWithFormat:@"%@ ENDSWITH 'C'", colName]);
        RLMAssertCount(cls, 0U, [NSString stringWithFormat:@"%@ ENDSWITH ''", colName]);
        RLMAssertCount(cls, 1U, [NSString stringWithFormat:@"%@ ENDSWITH[c] 'c'", colName]);
        RLMAssertCount(cls, 1U, [NSString stringWithFormat:@"%@ ENDSWITH[c] 'C'", colName]);
        RLMAssertCount(cls, 0U, [NSString stringWithFormat:@"%@ ENDSWITH[c] ''", colName]);
        RLMAssertCount(cls, 0U, [NSString stringWithFormat:@"%@ ENDSWITH[d] ''", colName]);
        RLMAssertCount(cls, 0U, [NSString stringWithFormat:@"%@ ENDSWITH[cd] ''", colName]);

        RLMAssertCount(cls, 1U, [NSString stringWithFormat:@"%@ ENDSWITH 'u'", colName]);
        RLMAssertCount(cls, 1U, [NSString stringWithFormat:@"%@ ENDSWITH[c] 'U'", colName]);
        RLMAssertCount(cls, 2U, [NSString stringWithFormat:@"%@ ENDSWITH[d] 'u'", colName]);
        RLMAssertCount(cls, 2U, [NSString stringWithFormat:@"%@ ENDSWITH[cd] 'U'", colName]);

        RLMAssertCount(cls, 1U, [NSString stringWithFormat:@"%@ ENDSWITH 'ü'", colName]);
        RLMAssertCount(cls, 0U, [NSString stringWithFormat:@"%@ ENDSWITH[c] 'Ü'", colName]);
        RLMAssertCount(cls, 2U, [NSString stringWithFormat:@"%@ ENDSWITH[d] 'ü'", colName]);
        RLMAssertCount(cls, 2U, [NSString stringWithFormat:@"%@ ENDSWITH[cd] 'Ü'", colName]);

        RLMAssertCount(cls, 0U, [NSString stringWithFormat:@"%@ ENDSWITH NULL", colName]);
        RLMAssertCount(cls, 0U, [NSString stringWithFormat:@"%@ ENDSWITH[c] NULL", colName]);
        RLMAssertCount(cls, 0U, [NSString stringWithFormat:@"%@ ENDSWITH[d] NULL", colName]);
        RLMAssertCount(cls, 0U, [NSString stringWithFormat:@"%@ ENDSWITH[cd] NULL", colName]);

        RLMAssertCount(AllTypesObject, 1U, [NSString stringWithFormat:@"%@.%@ ENDSWITH 'c'", objectCol, colName]);
        RLMAssertCount(AllTypesObject, 0U, [NSString stringWithFormat:@"%@.%@ ENDSWITH 'a'", objectCol, colName]);
        RLMAssertCount(AllTypesObject, 0U, [NSString stringWithFormat:@"%@.%@ ENDSWITH 'C'", objectCol, colName]);
        RLMAssertCount(AllTypesObject, 0U, [NSString stringWithFormat:@"%@.%@ ENDSWITH ''", objectCol, colName]);
        RLMAssertCount(AllTypesObject, 1U, [NSString stringWithFormat:@"%@.%@ ENDSWITH[c] 'c'", objectCol, colName]);
        RLMAssertCount(AllTypesObject, 1U, [NSString stringWithFormat:@"%@.%@ ENDSWITH[c] 'C'", objectCol, colName]);
        RLMAssertCount(AllTypesObject, 0U, [NSString stringWithFormat:@"%@.%@ ENDSWITH[c] ''", objectCol, colName]);
        RLMAssertCount(AllTypesObject, 0U, [NSString stringWithFormat:@"%@.%@ ENDSWITH[d] ''", objectCol, colName]);
        RLMAssertCount(AllTypesObject, 0U, [NSString stringWithFormat:@"%@.%@ ENDSWITH[cd] ''", objectCol, colName]);

        RLMAssertCount(AllTypesObject, 0U, [NSString stringWithFormat:@"%@.%@ ENDSWITH NULL", objectCol, colName]);
        RLMAssertCount(AllTypesObject, 0U, [NSString stringWithFormat:@"%@.%@ ENDSWITH[c] NULL", objectCol, colName]);
        RLMAssertCount(AllTypesObject, 0U, [NSString stringWithFormat:@"%@.%@ ENDSWITH[d] NULL", objectCol, colName]);
        RLMAssertCount(AllTypesObject, 0U, [NSString stringWithFormat:@"%@.%@ ENDSWITH[cd] NULL", objectCol, colName]);
    };
    testBlock(@"objectCol", @"stringCol", [StringObject class]);
    testBlock(@"mixedObjectCol", @"anyCol", [MixedObject class]);
}

- (void)testStringContains
{
    RLMRealm *realm = [self realm];

    [realm beginWriteTransaction];
    StringObject *so = [StringObject createInRealm:realm withValue:@[@"abc"]];
    [StringObject createInRealm:realm withValue:@[@"tüv"]];
    [StringObject createInRealm:realm withValue:@[@"tûv"]];
    [StringObject createInRealm:realm withValue:@[@"tuv"]];
    AllTypesObject *ato = [AllTypesObject createInRealm:realm
                                              withValue:[AllTypesObject values:1 stringObject:so]];
    ato.anyCol = @"abc"; // overwrite int
    ato.mixedObjectCol = [MixedObject createInRealm:realm withValue:@[@"abc"]];
    [MixedObject createInRealm:realm withValue:@[@"tüv"]];
    [MixedObject createInRealm:realm withValue:@[@"tûv"]];
    [MixedObject createInRealm:realm withValue:@[@"tuv"]];
    [realm commitWriteTransaction];

    void (^testBlock)(NSString *, NSString *, Class) = ^(NSString *objectCol, NSString *colName, Class cls) {
        RLMAssertCount(cls, 1U, [NSString stringWithFormat:@"%@ CONTAINS 'a'", colName]);
        RLMAssertCount(cls, 1U, [NSString stringWithFormat:@"%@ CONTAINS 'b'", colName]);
        RLMAssertCount(cls, 1U, [NSString stringWithFormat:@"%@ CONTAINS 'c'", colName]);
        RLMAssertCount(cls, 1U, [NSString stringWithFormat:@"%@ CONTAINS 'ab'", colName]);
        RLMAssertCount(cls, 1U, [NSString stringWithFormat:@"%@ CONTAINS 'bc'", colName]);
        RLMAssertCount(cls, 1U, [NSString stringWithFormat:@"%@ CONTAINS 'abc'", colName]);
        RLMAssertCount(cls, 0U, [NSString stringWithFormat:@"%@ CONTAINS 'd'", colName]);
        RLMAssertCount(cls, 0U, [NSString stringWithFormat:@"%@ CONTAINS 'aabc'", colName]);
        RLMAssertCount(cls, 0U, [NSString stringWithFormat:@"%@ CONTAINS 'bbc'", colName]);
        RLMAssertCount(cls, 0U, [NSString stringWithFormat:@"%@ CONTAINS ''", colName]);

        RLMAssertCount(cls, 0U, [NSString stringWithFormat:@"%@ CONTAINS 'C'", colName]);
        RLMAssertCount(cls, 1U, [NSString stringWithFormat:@"%@ CONTAINS[c] 'c'", colName]);
        RLMAssertCount(cls, 1U, [NSString stringWithFormat:@"%@ CONTAINS[c] 'C'", colName]);
        RLMAssertCount(cls, 0U, [NSString stringWithFormat:@"%@ CONTAINS[c] ''", colName]);

        RLMAssertCount(cls, 1U, [NSString stringWithFormat:@"%@ CONTAINS 'u'", colName]);
        RLMAssertCount(cls, 1U, [NSString stringWithFormat:@"%@ CONTAINS[c] 'U'", colName]);
        RLMAssertCount(cls, 3U, [NSString stringWithFormat:@"%@ CONTAINS[d] 'u'", colName]);
        RLMAssertCount(cls, 3U, [NSString stringWithFormat:@"%@ CONTAINS[cd] 'U'", colName]);
        RLMAssertCount(cls, 0U, [NSString stringWithFormat:@"%@ CONTAINS[d] ''", colName]);
        RLMAssertCount(cls, 0U, [NSString stringWithFormat:@"%@ CONTAINS[cd] ''", colName]);

        RLMAssertCount(cls, 1U, [NSString stringWithFormat:@"%@ CONTAINS 'ü'", colName]);
        RLMAssertCount(cls, 0U, [NSString stringWithFormat:@"%@ CONTAINS[c] 'Ü'", colName]);
        RLMAssertCount(cls, 3U, [NSString stringWithFormat:@"%@ CONTAINS[d] 'ü'", colName]);
        RLMAssertCount(cls, 3U, [NSString stringWithFormat:@"%@ CONTAINS[cd] 'Ü'", colName]);

        RLMAssertCount(cls, 0U, [NSString stringWithFormat:@"%@ CONTAINS NULL", colName]);
        RLMAssertCount(cls, 0U, [NSString stringWithFormat:@"%@ CONTAINS[c] NULL", colName]);
        RLMAssertCount(cls, 0U, [NSString stringWithFormat:@"%@ CONTAINS[d] NULL", colName]);
        RLMAssertCount(cls, 0U, [NSString stringWithFormat:@"%@ CONTAINS[cd] NULL", colName]);

        RLMAssertCount(AllTypesObject, 0U, [NSString stringWithFormat:@"%@.%@ CONTAINS 'd'", objectCol, colName]);
        RLMAssertCount(AllTypesObject, 1U, [NSString stringWithFormat:@"%@.%@ CONTAINS 'c'", objectCol, colName]);
        RLMAssertCount(AllTypesObject, 0U, [NSString stringWithFormat:@"%@.%@ CONTAINS 'C'", objectCol, colName]);
        RLMAssertCount(AllTypesObject, 0U, [NSString stringWithFormat:@"%@.%@ CONTAINS ''", objectCol, colName]);
        RLMAssertCount(AllTypesObject, 1U, [NSString stringWithFormat:@"%@.%@ CONTAINS[c] 'c'", objectCol, colName]);
        RLMAssertCount(AllTypesObject, 1U, [NSString stringWithFormat:@"%@.%@ CONTAINS[c] 'C'", objectCol, colName]);
        RLMAssertCount(AllTypesObject, 0U, [NSString stringWithFormat:@"%@.%@ CONTAINS[c] ''", objectCol, colName]);
        RLMAssertCount(AllTypesObject, 0U, [NSString stringWithFormat:@"%@.%@ CONTAINS[d] ''", objectCol, colName]);
        RLMAssertCount(AllTypesObject, 0U, [NSString stringWithFormat:@"%@.%@ CONTAINS[cd] ''", objectCol, colName]);

        RLMAssertCount(AllTypesObject, 0U, [NSString stringWithFormat:@"%@.%@ CONTAINS NULL", objectCol, colName]);
        RLMAssertCount(AllTypesObject, 0U, [NSString stringWithFormat:@"%@.%@ CONTAINS[c] NULL", objectCol, colName]);
        RLMAssertCount(AllTypesObject, 0U, [NSString stringWithFormat:@"%@.%@ CONTAINS[d] NULL", objectCol, colName]);
        RLMAssertCount(AllTypesObject, 0U, [NSString stringWithFormat:@"%@.%@ CONTAINS[cd] NULL", objectCol, colName]);
    };

    testBlock(@"objectCol", @"stringCol", [StringObject class]);
    testBlock(@"mixedObjectCol", @"anyCol", [MixedObject class]);
}

- (void)testStringLike
{
    RLMRealm *realm = [self realm];

    [realm beginWriteTransaction];
    StringObject *so = [StringObject createInRealm:realm withValue:(@[@"abc"])];
    AllTypesObject *ato = [AllTypesObject createInRealm:realm withValue:[AllTypesObject values:1 stringObject:so]];
    ato.mixedObjectCol = [MixedObject createInRealm:realm withValue:@[@"abc"]];
    [realm commitWriteTransaction];

    void (^testBlock)(NSString *, NSString *, Class) = ^(NSString *objectCol, NSString *colName, Class cls) {
        RLMAssertCount(cls, 1U, [NSString stringWithFormat:@"%@ LIKE '*a*'", colName]);
        RLMAssertCount(cls, 1U, [NSString stringWithFormat:@"%@ LIKE '*b*'", colName]);
        RLMAssertCount(cls, 1U, [NSString stringWithFormat:@"%@ LIKE '*c'", colName]);
        RLMAssertCount(cls, 1U, [NSString stringWithFormat:@"%@ LIKE 'ab*'", colName]);
        RLMAssertCount(cls, 1U, [NSString stringWithFormat:@"%@ LIKE '*bc'", colName]);
        RLMAssertCount(cls, 1U, [NSString stringWithFormat:@"%@ LIKE 'a*bc'", colName]);
        RLMAssertCount(cls, 1U, [NSString stringWithFormat:@"%@ LIKE '*abc*'", colName]);
        RLMAssertCount(cls, 0U, [NSString stringWithFormat:@"%@ LIKE '*d*'", colName]);
        RLMAssertCount(cls, 0U, [NSString stringWithFormat:@"%@ LIKE 'aabc'", colName]);
        RLMAssertCount(cls, 0U, [NSString stringWithFormat:@"%@ LIKE 'b*bc'", colName]);

        RLMAssertCount(cls, 1U, [NSString stringWithFormat:@"%@ LIKE 'a?" "?'", colName]);
        RLMAssertCount(cls, 1U, [NSString stringWithFormat:@"%@ LIKE '?b?'", colName]);
        RLMAssertCount(cls, 1U, [NSString stringWithFormat:@"%@ LIKE '*?c'", colName]);
        RLMAssertCount(cls, 1U, [NSString stringWithFormat:@"%@ LIKE 'ab?'", colName]);
        RLMAssertCount(cls, 1U, [NSString stringWithFormat:@"%@ LIKE '?bc'", colName]);
        RLMAssertCount(cls, 0U, [NSString stringWithFormat:@"%@ LIKE '?d?'", colName]);
        RLMAssertCount(cls, 0U, [NSString stringWithFormat:@"%@ LIKE '?abc'", colName]);
        RLMAssertCount(cls, 0U, [NSString stringWithFormat:@"%@ LIKE 'b?bc'", colName]);

        RLMAssertCount(cls, 0U, [NSString stringWithFormat:@"%@ LIKE '*C*'", colName]);
        RLMAssertCount(cls, 1U, [NSString stringWithFormat:@"%@ LIKE[c] '*c*'", colName]);
        RLMAssertCount(cls, 1U, [NSString stringWithFormat:@"%@ LIKE[c] '*C*'", colName]);

        RLMAssertCount(AllTypesObject, 0U, [NSString stringWithFormat:@"%@.%@ LIKE '*d*'", objectCol, colName]);
        RLMAssertCount(AllTypesObject, 1U, [NSString stringWithFormat:@"%@.%@ LIKE '*c*'", objectCol, colName]);
        RLMAssertCount(AllTypesObject, 0U, [NSString stringWithFormat:@"%@.%@ LIKE '*C*'", objectCol, colName]);
        RLMAssertCount(AllTypesObject, 1U, [NSString stringWithFormat:@"%@.%@ LIKE[c] '*c*'", objectCol, colName]);
        RLMAssertCount(AllTypesObject, 1U, [NSString stringWithFormat:@"%@.%@ LIKE[c] '*C*'", objectCol, colName]);

        NSString *queryStr = [NSString stringWithFormat:@"%@ LIKE[d] '*'", colName];
        RLMAssertThrowsWithReasonMatching([cls objectsWhere:queryStr],
                                          @"'LIKE' not supported .* diacritic-insensitive");
        queryStr = [NSString stringWithFormat:@"%@ LIKE[cd] '*'", colName];
        RLMAssertThrowsWithReasonMatching([cls objectsWhere:queryStr],
                                          @"'LIKE' not supported .* diacritic-insensitive");
    };

    testBlock(@"objectCol", @"stringCol", [StringObject class]);
    testBlock(@"mixedObjectCol", @"anyCol", [MixedObject class]);
}

- (void)testStringEquality
{
    RLMRealm *realm = [self realm];

    [realm beginWriteTransaction];
    StringObject *so = [StringObject createInRealm:realm withValue:@[@"abc"]];
    [StringObject createInRealm:realm withValue:@[@"tüv"]];
    [StringObject createInRealm:realm withValue:@[@"tûv"]];
    [StringObject createInRealm:realm withValue:@[@"tuv"]];
    AllTypesObject *ato = [AllTypesObject createInRealm:realm
                                              withValue:[AllTypesObject values:1 stringObject:so]];
    ato.anyCol = @"abc"; // overwrite int
    ato.mixedObjectCol = [MixedObject createInRealm:realm withValue:@[@"abc"]];
    [MixedObject createInRealm:realm withValue:@[@"tüv"]];
    [MixedObject createInRealm:realm withValue:@[@"tûv"]];
    [MixedObject createInRealm:realm withValue:@[@"tuv"]];
    [realm commitWriteTransaction];

    void (^testBlock)(NSString *, NSString *, Class) = ^(NSString *objectCol, NSString *colName, Class cls) {
        RLMAssertCount(cls, 1U, [NSString stringWithFormat:@"%@ == 'abc'", colName]);
        RLMAssertCount(cls, 4U, [NSString stringWithFormat:@"%@ != 'def'", colName]);
        RLMAssertCount(cls, 1U, [NSString stringWithFormat:@"%@ ==[c] 'abc'", colName]);
        RLMAssertCount(cls, 1U, [NSString stringWithFormat:@"%@ ==[c] 'ABC'", colName]);

        RLMAssertCount(cls, 3U, [NSString stringWithFormat:@"%@ != 'abc'", colName]);
        RLMAssertCount(cls, 0U, [NSString stringWithFormat:@"%@ == 'def'", colName]);
        RLMAssertCount(cls, 0U, [NSString stringWithFormat:@"%@ == 'ABC'", colName]);

        RLMAssertCount(cls, 1U, [NSString stringWithFormat:@"%@ == 'tuv'", colName]);
        RLMAssertCount(cls, 1U, [NSString stringWithFormat:@"%@ ==[c] 'TUV'", colName]);
        RLMAssertCount(cls, 3U, [NSString stringWithFormat:@"%@ ==[d] 'tuv'", colName]);
        RLMAssertCount(cls, 3U, [NSString stringWithFormat:@"%@ ==[cd] 'TUV'", colName]);

        RLMAssertCount(cls, 3U, [NSString stringWithFormat:@"%@ != 'tuv'", colName]);
        RLMAssertCount(cls, 3U, [NSString stringWithFormat:@"%@ !=[c] 'TUV'", colName]);
        RLMAssertCount(cls, 1U, [NSString stringWithFormat:@"%@ !=[d] 'tuv'", colName]);
        RLMAssertCount(cls, 1U, [NSString stringWithFormat:@"%@ !=[cd] 'TUV'", colName]);

        RLMAssertCount(AllTypesObject, 1U, [NSString stringWithFormat:@"%@.%@ == 'abc'", objectCol, colName]);
        RLMAssertCount(AllTypesObject, 1U, [NSString stringWithFormat:@"%@.%@ != 'def'", objectCol, colName]);

        RLMAssertCount(AllTypesObject, 1U, [NSString stringWithFormat:@"%@.%@ ==[c] 'abc'", objectCol, colName]);
        RLMAssertCount(AllTypesObject, 1U, [NSString stringWithFormat:@"%@.%@ ==[c] 'ABC'", objectCol, colName]);

        RLMAssertCount(AllTypesObject, 0U, [NSString stringWithFormat:@"%@.%@ != 'abc'", objectCol, colName]);
        RLMAssertCount(AllTypesObject, 0U, [NSString stringWithFormat:@"%@.%@ == 'def'", objectCol, colName]);
        RLMAssertCount(AllTypesObject, 0U, [NSString stringWithFormat:@"%@.%@ == 'ABC'", objectCol, colName]);
    };

    testBlock(@"objectCol", @"stringCol", [StringObject class]);
    testBlock(@"mixedObjectCol", @"anyCol", [MixedObject class]);
}

- (void)testFloatQuery
{
    RLMRealm *realm = [self realm];

    [realm beginWriteTransaction];
    [FloatObject createInRealm:realm withValue:@[@1.7f]];
    [MixedObject createInRealm:realm withValue:@[@1.7f]];
    [realm commitWriteTransaction];

    RLMAssertCount(FloatObject, 1U, @"floatCol > 1");
    RLMAssertCount(FloatObject, 1U, @"floatCol > %d", 1);
    RLMAssertCount(FloatObject, 1U, @"floatCol = 1.7");
    RLMAssertCount(FloatObject, 1U, @"floatCol = %f", 1.7f);
    RLMAssertCount(FloatObject, 1U, @"floatCol > 1.0");
    RLMAssertCount(FloatObject, 1U, @"floatCol >= 1.0");
    RLMAssertCount(FloatObject, 0U, @"floatCol < 1.0");
    RLMAssertCount(FloatObject, 0U, @"floatCol <= 1.0");
    RLMAssertCount(FloatObject, 1U, @"floatCol = %e", 1.7);
    RLMAssertCount(FloatObject, 0U, @"floatCol == %f", FLT_MAX);
    RLMAssertCount(FloatObject, 1U, @"floatCol BETWEEN %@", @[@1.0, @2.0]);

    // Mixed requires you to specify floats explicitly.
    RLMAssertCount(MixedObject, 1U, @"anyCol > 1");
    RLMAssertCount(MixedObject, 1U, @"anyCol > %lf", 1.0f);
    RLMAssertCount(MixedObject, 1U, @"anyCol = %@", @1.7f);
    RLMAssertCount(MixedObject, 1U, @"anyCol = %f", 1.7f);
    RLMAssertCount(MixedObject, 1U, @"anyCol > 1.0");
    RLMAssertCount(MixedObject, 1U, @"anyCol >= 1.0");
    RLMAssertCount(MixedObject, 0U, @"anyCol < 1.0");
    RLMAssertCount(MixedObject, 0U, @"anyCol <= 1.0");
    RLMAssertCount(MixedObject, 1U, @"anyCol = %e", 1.7f);
    RLMAssertCount(MixedObject, 0U, @"anyCol == %f", FLT_MAX);
    RLMAssertCount(MixedObject, 1U, @"anyCol BETWEEN %@", @[@1.0, @2.0]);

    XCTAssertThrows([FloatObject objectsInRealm:realm where:@"floatCol = 3.5e+38"],
                    @"Too large to be a float");
    XCTAssertThrows([FloatObject objectsInRealm:realm where:@"floatCol = -3.5e+38"],
                    @"Too small to be a float");
}

- (void)testDecimalQuery {
    RLMRealm *realm = [self realm];

    [realm beginWriteTransaction];
    [DecimalObject createInRealm:realm withValue:@[@"-Inf"]];
    [DecimalObject createInRealm:realm withValue:@[@"Inf"]];
    [DecimalObject createInRealm:realm withValue:@[@"123456789.123456789e1234"]];
    [realm commitWriteTransaction];

    RLMAssertCount(DecimalObject, 0U, @"decimalCol >  'Inf'");
    RLMAssertCount(DecimalObject, 1U, @"decimalCol >= 'Inf'");
    RLMAssertCount(DecimalObject, 1U, @"decimalCol == 'Inf'");
    RLMAssertCount(DecimalObject, 3U, @"decimalCol <= 'Inf'");
    RLMAssertCount(DecimalObject, 2U, @"decimalCol <  'Inf'");

    RLMAssertCount(DecimalObject, 2U, @"decimalCol >  '-Inf'");
    RLMAssertCount(DecimalObject, 3U, @"decimalCol >= '-Inf'");
    RLMAssertCount(DecimalObject, 1U, @"decimalCol == '-Inf'");
    RLMAssertCount(DecimalObject, 1U, @"decimalCol <= '-Inf'");
    RLMAssertCount(DecimalObject, 0U, @"decimalCol <  '-Inf'");

    RLMAssertCount(DecimalObject, 1U, @"decimalCol >  '123456789.123456789e1234'");
    RLMAssertCount(DecimalObject, 2U, @"decimalCol >= '123456789.123456789e1234'");
    RLMAssertCount(DecimalObject, 1U, @"decimalCol == '123456789.123456789e1234'");
    RLMAssertCount(DecimalObject, 2U, @"decimalCol <= '123456789.123456789e1234'");
    RLMAssertCount(DecimalObject, 1U, @"decimalCol <  '123456789.123456789e1234'");
}

- (void)testLiveQueriesInsideTransaction
{
    RLMRealm *realm = [self realm];

    NSMutableArray *values = [@[@YES, @YES, @1, @2, @23.0f, @1.7f,  @0.0,  @5.55, @"", @"", data(""), data("")] mutableCopy];

    [realm beginWriteTransaction];
    [self.queryObjectClass createInRealm:realm withValue:values];

    RLMResults *resultsQuery = [self.queryObjectClass objectsWhere:@"bool1 = YES"];
    RLMResults *resultsTableView = [self.queryObjectClass objectsWhere:@"bool1 = YES"];

    // Force resultsTableView to form the TableView to verify that it syncs
    // correctly, and don't call anything but count on resultsQuery so that
    // it always reruns the query count method
    (void)[resultsTableView firstObject];

    XCTAssertEqual(resultsQuery.count, 1U);
    XCTAssertEqual(resultsTableView.count, 1U);

    // Delete the (only) object in result set
    [realm deleteObject:[resultsTableView lastObject]];
    XCTAssertEqual(resultsQuery.count, 0U);
    XCTAssertEqual(resultsTableView.count, 0U);

    // Add an object that does not match query
    values[0] = @NO;
    QueryObject *q1 = [self.queryObjectClass createInRealm:realm withValue:values];
    XCTAssertEqual(resultsQuery.count, 0U);
    XCTAssertEqual(resultsTableView.count, 0U);

    // Change object to match query
    q1[@"bool1"] = @YES;
    XCTAssertEqual(resultsQuery.count, 1U);
    XCTAssertEqual(resultsTableView.count, 1U);

    // Add another object that matches
    values[0] = @YES;
    [self.queryObjectClass createInRealm:realm withValue:values];
    XCTAssertEqual(resultsQuery.count, 2U);
    XCTAssertEqual(resultsTableView.count, 2U);
    [realm commitWriteTransaction];
}

- (void)testLiveQueriesBetweenTransactions
{
    RLMRealm *realm = [self realm];

    NSMutableArray *values = [@[@YES, @YES, @1, @2, @23.0f, @1.7f,  @0.0,  @5.55, @"", @"", data(""), data("")] mutableCopy];

    [realm beginWriteTransaction];
    [self.queryObjectClass createInRealm:realm withValue:values];
    [realm commitWriteTransaction];

    RLMResults *resultsQuery = [self.queryObjectClass objectsWhere:@"bool1 = YES"];
    RLMResults *resultsTableView = [self.queryObjectClass objectsWhere:@"bool1 = YES"];

    // Force resultsTableView to form the TableView to verify that it syncs
    // correctly, and don't call anything but count on resultsQuery so that
    // it always reruns the query count method
    (void)[resultsTableView firstObject];

    XCTAssertEqual(resultsQuery.count, 1U);
    XCTAssertEqual(resultsTableView.count, 1U);

    // Delete the (only) object in result set
    [realm beginWriteTransaction];
    [realm deleteObject:[resultsTableView lastObject]];
    [realm commitWriteTransaction];

    XCTAssertEqual(resultsQuery.count, 0U);
    XCTAssertEqual(resultsTableView.count, 0U);

    // Add an object that does not match query
    [realm beginWriteTransaction];
    values[0] = @NO;
    QueryObject *q1 = [self.queryObjectClass createInRealm:realm withValue:values];
    [realm commitWriteTransaction];

    XCTAssertEqual(resultsQuery.count, 0U);
    XCTAssertEqual(resultsTableView.count, 0U);

    // Change object to match query
    [realm beginWriteTransaction];
    q1[@"bool1"] = @YES;
    [realm commitWriteTransaction];

    XCTAssertEqual(resultsQuery.count, 1U);
    XCTAssertEqual(resultsTableView.count, 1U);

    // Add another object that matches
    [realm beginWriteTransaction];
    values[0] = @YES;
    [self.queryObjectClass createInRealm:realm withValue:values];
    [realm commitWriteTransaction];

    XCTAssertEqual(resultsQuery.count, 2U);
    XCTAssertEqual(resultsTableView.count, 2U);
}

- (void)makeDogWithName:(NSString *)name owner:(NSString *)ownerName {
    RLMRealm *realm = [self realm];

    OwnerObject *owner = [[OwnerObject alloc] init];
    owner.name = ownerName;
    owner.dog = [[DogObject alloc] init];
    owner.dog.dogName = name;

    [realm beginWriteTransaction];
    [realm addObject:owner];
    [realm commitWriteTransaction];
}

- (void)makeDogWithAge:(int)age owner:(NSString *)ownerName {
    RLMRealm *realm = [self realm];

    OwnerObject *owner = [[OwnerObject alloc] init];
    owner.name = ownerName;
    owner.dog = [[DogObject alloc] init];
    owner.dog.dogName = @"";
    owner.dog.age = age;

    [realm beginWriteTransaction];
    [realm addObject:owner];
    [realm commitWriteTransaction];
}

- (void)testLinkQueryNewObjectCausesEmptyResults
{
    [self makeDogWithName:@"Harvie" owner:@"Tim"];
    DogObject *newDogObject = [[DogObject alloc] init];
    RLMAssertCount(OwnerObject, 0U, @"dog = %@", newDogObject);
    RLMAssertCount(OwnerObject, 1U, @"dog != %@", newDogObject);
}

- (void)testLinkQueryDifferentRealmsThrows
{
    RLMRealm *testRealm = [self realmWithTestPath];
    [self makeDogWithName:@"Harvie" owner:@"Tim"];

    RLMRealm *defaultRealm = [self realm];
    DogObject *dog = [[DogObject alloc] init];
    dog.dogName = @"Fido";
    [defaultRealm beginWriteTransaction];
    [defaultRealm addObject:dog];
    [defaultRealm commitWriteTransaction];

    XCTAssertThrows(([OwnerObject objectsInRealm:testRealm where:@"dog = %@", dog]));
}

- (void)testLinkQueryString
{
    RLMRealm *realm = [self realm];

    [self makeDogWithName:@"Harvie" owner:@"Tim"];
    RLMAssertCount(OwnerObject, 1U, @"dog.dogName  = 'Harvie'");
    RLMAssertCount(OwnerObject, 0U, @"dog.dogName != 'Harvie'");
    RLMAssertCount(OwnerObject, 0U, @"dog.dogName  = 'eivraH'");
    RLMAssertCount(OwnerObject, 0U, @"dog.dogName  = 'Fido'");
    RLMAssertCount(OwnerObject, 1U, @"dog.dogName IN {'Fido', 'Harvie'}");
    RLMAssertCount(OwnerObject, 0U, @"dog.dogName IN {'Fido', 'eivraH'}");

    [self makeDogWithName:@"Harvie" owner:@"Joe"];
    RLMAssertCount(OwnerObject, 2U, @"dog.dogName  = 'Harvie'");
    RLMAssertCount(OwnerObject, 0U, @"dog.dogName != 'Harvie'");
    RLMAssertCount(OwnerObject, 0U, @"dog.dogName  = 'eivraH'");
    RLMAssertCount(OwnerObject, 0U, @"dog.dogName  = 'Fido'");
    RLMAssertCount(OwnerObject, 2U, @"dog.dogName IN {'Fido', 'Harvie'}");
    RLMAssertCount(OwnerObject, 0U, @"dog.dogName IN {'Fido', 'eivraH'}");

    [self makeDogWithName:@"Fido" owner:@"Jim"];
    RLMAssertCount(OwnerObject, 2U, @"dog.dogName  = 'Harvie'");
    RLMAssertCount(OwnerObject, 1U, @"dog.dogName != 'Harvie'");
    RLMAssertCount(OwnerObject, 0U, @"dog.dogName  = 'eivraH'");
    RLMAssertCount(OwnerObject, 1U, @"dog.dogName  = 'Fido'");
    RLMAssertCount(OwnerObject, 3U, @"dog.dogName IN {'Fido', 'Harvie'}");
    RLMAssertCount(OwnerObject, 1U, @"dog.dogName IN {'Fido', 'eivraH'}");

    RLMAssertCount(OwnerObject, 1U, @"dog.dogName = 'Harvie' and name = 'Tim'");
    RLMAssertCount(OwnerObject, 0U, @"dog.dogName = 'Harvie' and name = 'Jim'");

    [self makeDogWithName:@"Rex" owner:@"Rex"];
    RLMAssertCount(OwnerObject, 1U, @"dog.dogName = name");
    RLMAssertCount(OwnerObject, 1U, @"name = dog.dogName");
    RLMAssertCount(OwnerObject, 3U, @"dog.dogName != name");
    RLMAssertCount(OwnerObject, 3U, @"name != dog.dogName");
    RLMAssertCount(OwnerObject, 4U, @"dog.dogName == dog.dogName");
    RLMAssertCount(OwnerObject, 0U, @"dog.dogName != dog.dogName");

    // test invalid operators
    XCTAssertThrows([OwnerObject objectsInRealm:realm where:@"dog.dogName > 'Harvie'"], @"Invalid operator should throw");
}

- (void)testLinkQueryInt
{
    [self makeDogWithAge:5 owner:@"Tim"];
    RLMAssertCount(OwnerObject, 1U, @"dog.age  = 5");
    RLMAssertCount(OwnerObject, 0U, @"dog.age != 5");
    RLMAssertCount(OwnerObject, 0U, @"dog.age  = 10");
    RLMAssertCount(OwnerObject, 0U, @"dog.age  = 8");
    RLMAssertCount(OwnerObject, 1U, @"dog.age IN {5, 8}");
    RLMAssertCount(OwnerObject, 0U, @"dog.age IN {8, 10}");
    RLMAssertCount(OwnerObject, 1U, @"dog.age BETWEEN {0, 10}");
    RLMAssertCount(OwnerObject, 1U, @"dog.age BETWEEN {0, 7}");

    [self makeDogWithAge:5 owner:@"Joe"];
    RLMAssertCount(OwnerObject, 2U, @"dog.age  = 5");
    RLMAssertCount(OwnerObject, 0U, @"dog.age != 5");
    RLMAssertCount(OwnerObject, 0U, @"dog.age  = 10");
    RLMAssertCount(OwnerObject, 0U, @"dog.age  = 8");
    RLMAssertCount(OwnerObject, 2U, @"dog.age IN {5, 8}");
    RLMAssertCount(OwnerObject, 0U, @"dog.age IN {8, 10}");
    RLMAssertCount(OwnerObject, 2U, @"dog.age BETWEEN {0, 10}");
    RLMAssertCount(OwnerObject, 2U, @"dog.age BETWEEN {0, 7}");

    [self makeDogWithAge:8 owner:@"Jim"];
    RLMAssertCount(OwnerObject, 2U, @"dog.age  = 5");
    RLMAssertCount(OwnerObject, 1U, @"dog.age != 5");
    RLMAssertCount(OwnerObject, 0U, @"dog.age  = 10");
    RLMAssertCount(OwnerObject, 1U, @"dog.age  = 8");
    RLMAssertCount(OwnerObject, 3U, @"dog.age IN {5, 8}");
    RLMAssertCount(OwnerObject, 1U, @"dog.age IN {8, 10}");
    RLMAssertCount(OwnerObject, 3U, @"dog.age BETWEEN {0, 10}");
    RLMAssertCount(OwnerObject, 2U, @"dog.age BETWEEN {0, 7}");
}

- (void)testLinkQueryAllTypes {
    RLMRealm *realm = [self realm];

    LinkToAllTypesObject *linkToAllTypes = [[LinkToAllTypesObject alloc] init];
    linkToAllTypes.allTypesCol = [[AllTypesObject alloc] initWithValue:[AllTypesObject values:1 stringObject:nil]];
    StringObject *obj = [[StringObject alloc] initWithValue:@[@"string"]];
    linkToAllTypes.allTypesCol.objectCol = obj;

    [realm beginWriteTransaction];
    [realm addObject:linkToAllTypes];
    [realm commitWriteTransaction];

    RLMAssertCount(LinkToAllTypesObject, 1U, @"allTypesCol.boolCol = YES");
    RLMAssertCount(LinkToAllTypesObject, 0U, @"allTypesCol.boolCol = NO");

    RLMAssertCount(LinkToAllTypesObject, 1U, @"allTypesCol.intCol = 1");
    RLMAssertCount(LinkToAllTypesObject, 0U, @"allTypesCol.intCol != 1");
    RLMAssertCount(LinkToAllTypesObject, 1U, @"allTypesCol.intCol > 0");
    RLMAssertCount(LinkToAllTypesObject, 0U, @"allTypesCol.intCol > 1");

    RLMAssertCount(LinkToAllTypesObject, 1U, @"allTypesCol.floatCol = %f", 1.1);
    RLMAssertCount(LinkToAllTypesObject, 1U, @"allTypesCol.floatCol <= %f", 1.1);
    RLMAssertCount(LinkToAllTypesObject, 0U, @"allTypesCol.floatCol < %f", 1.1);

    RLMAssertCount(LinkToAllTypesObject, 1U, @"allTypesCol.doubleCol = 1.11");
    RLMAssertCount(LinkToAllTypesObject, 1U, @"allTypesCol.doubleCol >= 1.11");
    RLMAssertCount(LinkToAllTypesObject, 0U, @"allTypesCol.doubleCol > 1.11");

    RLMAssertCount(LinkToAllTypesObject, 1U, @"allTypesCol.longCol = 2147483648");
    RLMAssertCount(LinkToAllTypesObject, 0U, @"allTypesCol.longCol != 2147483648");

    RLMAssertCount(LinkToAllTypesObject, 1U, @"allTypesCol.dateCol = %@", linkToAllTypes.allTypesCol.dateCol);
    RLMAssertCount(LinkToAllTypesObject, 0U, @"allTypesCol.dateCol != %@", linkToAllTypes.allTypesCol.dateCol);
}

- (void)testLinkQueryManyArray
{
    RLMRealm *realm = [self realm];

    ArrayPropertyObject *arrPropObj1 = [[ArrayPropertyObject alloc] init];
    arrPropObj1.name = @"Test";
    for(NSUInteger i=0; i<10; i++) {
        StringObject *sobj = [[StringObject alloc] init];
        sobj.stringCol = [NSString stringWithFormat:@"%lu", (unsigned long)i];
        [arrPropObj1.array addObject:sobj];
        IntObject *iobj = [[IntObject alloc] init];
        iobj.intCol = (int)i;
        [arrPropObj1.intArray addObject:iobj];
    }
    [realm beginWriteTransaction];
    [realm addObject:arrPropObj1];
    [realm commitWriteTransaction];

    RLMAssertCount(ArrayPropertyObject, 0U, @"ANY intArray.intCol > 10");
    RLMAssertCount(ArrayPropertyObject, 1U, @"ANY intArray.intCol > 5");
    RLMAssertCount(ArrayPropertyObject, 1U, @"ANY array.stringCol = '1'");
    RLMAssertCount(ArrayPropertyObject, 0U, @"NONE intArray.intCol == 5");
    RLMAssertCount(ArrayPropertyObject, 1U, @"NONE intArray.intCol > 10");

    ArrayPropertyObject *arrPropObj2 = [[ArrayPropertyObject alloc] init];
    arrPropObj2.name = @"Test";
    for(NSUInteger i=0; i<4; i++) {
        StringObject *sobj = [[StringObject alloc] init];
        sobj.stringCol = [NSString stringWithFormat:@"%lu", (unsigned long)i];
        [arrPropObj2.array addObject:sobj];
        IntObject *iobj = [[IntObject alloc] init];
        iobj.intCol = (int)i;
        [arrPropObj2.intArray addObject:iobj];
    }
    [realm beginWriteTransaction];
    [realm addObject:arrPropObj2];
    [realm commitWriteTransaction];
    RLMAssertCount(ArrayPropertyObject, 0U, @"ANY intArray.intCol > 10");
    RLMAssertCount(ArrayPropertyObject, 1U, @"ANY intArray.intCol > 5");
    RLMAssertCount(ArrayPropertyObject, 2U, @"ANY intArray.intCol > 2");
    RLMAssertCount(ArrayPropertyObject, 1U, @"NONE intArray.intCol == 5");
    RLMAssertCount(ArrayPropertyObject, 2U, @"NONE intArray.intCol > 10");
}

- (void)testLinkQueryManySet
{
    RLMRealm *realm = [self realm];

    SetPropertyObject *setPropObj1 = [[SetPropertyObject alloc] init];
    setPropObj1.name = @"Test";
    for(NSUInteger i=0; i<10; i++) {
        StringObject *sobj = [[StringObject alloc] init];
        sobj.stringCol = [NSString stringWithFormat:@"%lu", (unsigned long)i];
        [setPropObj1.set addObject:sobj];
        IntObject *iobj = [[IntObject alloc] init];
        iobj.intCol = (int)i;
        [setPropObj1.intSet addObject:iobj];
    }
    [realm beginWriteTransaction];
    [realm addObject:setPropObj1];
    [realm commitWriteTransaction];

    RLMAssertCount(SetPropertyObject, 0U, @"ANY intSet.intCol > 10");
    RLMAssertCount(SetPropertyObject, 0U, @"ANY intSet.intCol > 10");
    RLMAssertCount(SetPropertyObject, 1U, @"ANY intSet.intCol > 5");
    RLMAssertCount(SetPropertyObject, 1U, @"ANY set.stringCol = '1'");
    RLMAssertCount(SetPropertyObject, 0U, @"NONE intSet.intCol == 5");
    RLMAssertCount(SetPropertyObject, 1U, @"NONE intSet.intCol > 10");

    SetPropertyObject *setPropObj2 = [[SetPropertyObject alloc] init];
    setPropObj2.name = @"Test";
    for(NSUInteger i=0; i<4; i++) {
        StringObject *sobj = [[StringObject alloc] init];
        sobj.stringCol = [NSString stringWithFormat:@"%lu", (unsigned long)i];
        [setPropObj2.set addObject:sobj];
        IntObject *iobj = [[IntObject alloc] init];
        iobj.intCol = (int)i;
        [setPropObj2.intSet addObject:iobj];
    }
    [realm beginWriteTransaction];
    [realm addObject:setPropObj2];
    [realm commitWriteTransaction];
    RLMAssertCount(SetPropertyObject, 0U, @"ANY intSet.intCol > 10");
    RLMAssertCount(SetPropertyObject, 1U, @"ANY intSet.intCol > 5");
    RLMAssertCount(SetPropertyObject, 2U, @"ANY intSet.intCol > 2");
    RLMAssertCount(SetPropertyObject, 1U, @"NONE intSet.intCol == 5");
    RLMAssertCount(SetPropertyObject, 2U, @"NONE intSet.intCol > 10");
}

- (void)testLinkQueryManyDictionaries {
    RLMRealm *realm = [self realm];

    DictionaryPropertyObject *dpo1 = [[DictionaryPropertyObject alloc] init];
    for(NSUInteger i=0; i<10; i++) {
        StringObject *sobj = [[StringObject alloc] init];
        sobj.stringCol = [NSString stringWithFormat:@"%lu", (unsigned long)i];
        dpo1.stringDictionary[sobj.stringCol] = sobj;
        IntObject *iobj = [[IntObject alloc] init];
        iobj.intCol = (int)i;
        dpo1.intObjDictionary[sobj.stringCol] = iobj;
    }
    [realm beginWriteTransaction];
    [realm addObject:dpo1];
    [realm commitWriteTransaction];

    RLMAssertCount(DictionaryPropertyObject, 0U, @"ANY intObjDictionary.intCol > 10");
    RLMAssertCount(DictionaryPropertyObject, 1U, @"ANY intObjDictionary.intCol > 5");
    RLMAssertCount(DictionaryPropertyObject, 1U, @"ANY stringDictionary.stringCol = '1'");
    RLMAssertCount(DictionaryPropertyObject, 0U, @"NONE intObjDictionary.intCol == 5");
    RLMAssertCount(DictionaryPropertyObject, 1U, @"NONE intObjDictionary.intCol > 10");

    DictionaryPropertyObject *dpo2 = [[DictionaryPropertyObject alloc] init];
    for(NSUInteger i=0; i<4; i++) {
        StringObject *sobj = [[StringObject alloc] init];
        sobj.stringCol = [NSString stringWithFormat:@"%lu", (unsigned long)i];
        dpo2.stringDictionary[sobj.stringCol] = sobj;
        IntObject *iobj = [[IntObject alloc] init];
        iobj.intCol = (int)i;
        dpo2.intObjDictionary[sobj.stringCol] = iobj;
    }
    [realm beginWriteTransaction];
    [realm addObject:dpo2];
    [realm commitWriteTransaction];
    RLMAssertCount(DictionaryPropertyObject, 0U, @"ANY intObjDictionary.intCol > 10");
    RLMAssertCount(DictionaryPropertyObject, 1U, @"ANY intObjDictionary.intCol > 5");
    RLMAssertCount(DictionaryPropertyObject, 2U, @"ANY intObjDictionary.intCol > 2");
    RLMAssertCount(DictionaryPropertyObject, 1U, @"NONE intObjDictionary.intCol == 5");
    RLMAssertCount(DictionaryPropertyObject, 2U, @"NONE intObjDictionary.intCol > 10");
}

- (void)testMultiLevelLinkQuery
{
    RLMRealm *realm = [self realm];

    [realm beginWriteTransaction];
    CircleObject *circle = nil;
    for (int i = 0; i < 5; ++i) {
        circle = [CircleObject createInRealm:realm withValue:@{@"data": [NSString stringWithFormat:@"%d", i],
                                                                @"next": circle ?: NSNull.null}];
    }
    [realm commitWriteTransaction];

    XCTAssertTrue([circle isEqualToObject:[CircleObject objectsInRealm:realm where:@"data = '4'"].firstObject]);
    XCTAssertTrue([circle isEqualToObject:[CircleObject objectsInRealm:realm where:@"next.data = '3'"].firstObject]);
    XCTAssertTrue([circle isEqualToObject:[CircleObject objectsInRealm:realm where:@"next.next.data = '2'"].firstObject]);
    XCTAssertTrue([circle isEqualToObject:[CircleObject objectsInRealm:realm where:@"next.next.next.data = '1'"].firstObject]);
    XCTAssertTrue([circle isEqualToObject:[CircleObject objectsInRealm:realm where:@"next.next.next.next.data = '0'"].firstObject]);
    XCTAssertTrue([circle.next isEqualToObject:[CircleObject objectsInRealm:realm where:@"next.next.next.data = '0'"].firstObject]);
    XCTAssertTrue([circle.next.next isEqualToObject:[CircleObject objectsInRealm:realm where:@"next.next.data = '0'"].firstObject]);

    XCTAssertNoThrow(([CircleObject objectsInRealm:realm where:@"next = %@", circle]));
    XCTAssertNoThrow(([CircleObject objectsInRealm:realm where:@"next.next = %@", circle]));
    XCTAssertTrue([circle.next.next.next.next isEqualToObject:[CircleObject objectsInRealm:realm where:@"next = nil"].firstObject]);
    XCTAssertTrue([circle.next.next.next isEqualToObject:[CircleObject objectsInRealm:realm where:@"next != nil AND next.next = nil"].firstObject]);
    XCTAssertTrue([circle.next.next isEqualToObject:[CircleObject objectsInRealm:realm where:@"next.next != nil AND next.next.next = nil"].firstObject]);
}

- (void)testArrayMultiLevelLinkQuery
{
    RLMRealm *realm = [self realm];

    [realm beginWriteTransaction];
    CircleObject *circle = nil;
    for (int i = 0; i < 5; ++i) {
        circle = [CircleObject createInRealm:realm withValue:@{@"data": [NSString stringWithFormat:@"%d", i],
                                                                @"next": circle ?: NSNull.null}];
    }
    [CircleArrayObject createInRealm:realm withValue:@[[CircleObject allObjectsInRealm:realm]]];
    [realm commitWriteTransaction];

    RLMAssertCount(CircleArrayObject, 1U, @"ANY circles.data = '4'");
    RLMAssertCount(CircleArrayObject, 0U, @"ANY circles.next.data = '4'");
    RLMAssertCount(CircleArrayObject, 1U, @"ANY circles.next.data = '3'");
    RLMAssertCount(CircleArrayObject, 1U, @"ANY circles.data = '3'");
    RLMAssertCount(CircleArrayObject, 1U, @"NONE circles.next.data = '4'");

    RLMAssertCount(CircleArrayObject, 0U, @"ANY circles.next.next.data = '3'");
    RLMAssertCount(CircleArrayObject, 1U, @"ANY circles.next.next.data = '2'");
    RLMAssertCount(CircleArrayObject, 1U, @"ANY circles.next.data = '2'");
    RLMAssertCount(CircleArrayObject, 1U, @"ANY circles.data = '2'");
    RLMAssertCount(CircleArrayObject, 1U, @"NONE circles.next.next.data = '3'");

    XCTAssertThrows([CircleArrayObject objectsInRealm:realm where:@"ANY data = '2'"]);
    XCTAssertThrows([CircleArrayObject objectsInRealm:realm where:@"ANY circles.next = '2'"]);
    XCTAssertThrows([CircleArrayObject objectsInRealm:realm where:@"ANY data.circles = '2'"]);
    XCTAssertThrows([CircleArrayObject objectsInRealm:realm where:@"circles.data = '2'"]);
    XCTAssertThrows([CircleArrayObject objectsInRealm:realm where:@"NONE data.circles = '2'"]);
}

- (void)testSetMultiLevelLinkQuery
{
    RLMRealm *realm = [self realm];

    [realm beginWriteTransaction];
    CircleObject *circle = nil;
    for (int i = 0; i < 5; ++i) {
        circle = [CircleObject createInRealm:realm withValue:@{@"data": [NSString stringWithFormat:@"%d", i],
                                                                @"next": circle ?: NSNull.null}];
    }
    [CircleSetObject createInRealm:realm withValue:@[[CircleObject allObjectsInRealm:realm]]];
    [realm commitWriteTransaction];

    RLMAssertCount(CircleSetObject, 1U, @"ANY circles.data = '4'");
    RLMAssertCount(CircleSetObject, 0U, @"ANY circles.next.data = '4'");
    RLMAssertCount(CircleSetObject, 1U, @"ANY circles.next.data = '3'");
    RLMAssertCount(CircleSetObject, 1U, @"ANY circles.data = '3'");
    RLMAssertCount(CircleSetObject, 1U, @"NONE circles.next.data = '4'");

    RLMAssertCount(CircleSetObject, 0U, @"ANY circles.next.next.data = '3'");
    RLMAssertCount(CircleSetObject, 1U, @"ANY circles.next.next.data = '2'");
    RLMAssertCount(CircleSetObject, 1U, @"ANY circles.next.data = '2'");
    RLMAssertCount(CircleSetObject, 1U, @"ANY circles.data = '2'");
    RLMAssertCount(CircleSetObject, 1U, @"NONE circles.next.next.data = '3'");

    XCTAssertThrows([CircleSetObject objectsInRealm:realm where:@"ANY data = '2'"]);
    XCTAssertThrows([CircleSetObject objectsInRealm:realm where:@"ANY circles.next = '2'"]);
    XCTAssertThrows([CircleSetObject objectsInRealm:realm where:@"ANY data.circles = '2'"]);
    XCTAssertThrows([CircleSetObject objectsInRealm:realm where:@"circles.data = '2'"]);
    XCTAssertThrows([CircleSetObject objectsInRealm:realm where:@"NONE data.circles = '2'"]);
}

- (void)testDictionaryMultiLevelLinkQuery {
    RLMRealm *realm = [self realm];

    [realm beginWriteTransaction];
    CircleObject *circle = nil;
    for (int i = 0; i < 5; ++i) {
        circle = [CircleObject createInRealm:realm withValue:@{@"data": [NSString stringWithFormat:@"%d", i],
                                                                @"next": circle ?: NSNull.null}];
    }
    CircleDictionaryObject *cdo = [CircleDictionaryObject createInRealm:realm withValue:@{}];
    for (CircleObject *co in [CircleObject allObjectsInRealm:realm]) {
        cdo.circles[co.data] = co;
    }
    [realm commitWriteTransaction];

    RLMAssertCount(CircleDictionaryObject, 1U, @"ANY circles.data = '4'");
    RLMAssertCount(CircleDictionaryObject, 0U, @"ANY circles.next.data = '4'");
    RLMAssertCount(CircleDictionaryObject, 1U, @"ANY circles.next.data = '3'");
    RLMAssertCount(CircleDictionaryObject, 1U, @"ANY circles.data = '3'");
    RLMAssertCount(CircleDictionaryObject, 1U, @"NONE circles.next.data = '4'");

    RLMAssertCount(CircleDictionaryObject, 0U, @"ANY circles.next.next.data = '3'");
    RLMAssertCount(CircleDictionaryObject, 1U, @"ANY circles.next.next.data = '2'");
    RLMAssertCount(CircleDictionaryObject, 1U, @"ANY circles.next.data = '2'");
    RLMAssertCount(CircleDictionaryObject, 1U, @"ANY circles.data = '2'");
    RLMAssertCount(CircleDictionaryObject, 1U, @"NONE circles.next.next.data = '3'");

    XCTAssertThrows([CircleDictionaryObject objectsInRealm:realm where:@"ANY data = '2'"]);
    XCTAssertThrows([CircleDictionaryObject objectsInRealm:realm where:@"ANY circles.next = '2'"]);
    XCTAssertThrows([CircleDictionaryObject objectsInRealm:realm where:@"ANY data.circles = '2'"]);
    XCTAssertThrows([CircleDictionaryObject objectsInRealm:realm where:@"circles.data = '2'"]);
    XCTAssertThrows([CircleDictionaryObject objectsInRealm:realm where:@"NONE data.circles = '2'"]);
}

- (void)testMultiLevelBackLinkQuery
{
    RLMRealm *realm = [self realm];

    [realm beginWriteTransaction];
    LinkChain1 *root1 = [LinkChain1 createInRealm:realm withValue:@{@"value": @1, @"next": @[@[]]}];
    LinkChain1 *root2 = [LinkChain1 createInRealm:realm withValue:@{@"value": @2, @"next": @[@[]]}];
    [realm commitWriteTransaction];

    RLMResults *results = [LinkChain3 objectsInRealm:realm where:@"ANY prev.prev.value = 1"];
    XCTAssertEqual(1U, results.count);
    XCTAssertTrue([root1.next.next isEqualToObject:results.firstObject]);

    results = [LinkChain3 objectsInRealm:realm where:@"ANY prev.prev.value = 2"];
    XCTAssertEqual(1U, results.count);
    XCTAssertTrue([root2.next.next isEqualToObject:results.firstObject]);

    results = [LinkChain3 objectsInRealm:realm where:@"ANY prev.prev.value = 3"];
    XCTAssertEqual(0U, results.count);
}

- (void)testQueryWithObjects {
    RLMRealm *realm = [self realm];

    [realm beginWriteTransaction];

    StringObject *stringObj0 = [StringObject createInRealm:realm withValue:@[@"string0"]];
    StringObject *stringObj1 = [StringObject createInRealm:realm withValue:@[@"string1"]];
    StringObject *stringObj2 = [StringObject createInRealm:realm withValue:@[@"string2"]];

    AllTypesObject *obj0 = [AllTypesObject createInRealm:realm withValue:[AllTypesObject values:1 stringObject:stringObj0]];
    AllTypesObject *obj1 = [AllTypesObject createInRealm:realm withValue:[AllTypesObject values:2 stringObject:stringObj1]];
    AllTypesObject *obj2 = [AllTypesObject createInRealm:realm withValue:[AllTypesObject values:3 stringObject:stringObj0]];
    AllTypesObject *obj3 = [AllTypesObject createInRealm:realm withValue:[AllTypesObject values:4 stringObject:stringObj2]];
    AllTypesObject *obj4 = [AllTypesObject createInRealm:realm withValue:[AllTypesObject values:5 stringObject:nil]];

    [ArrayOfAllTypesObject createInDefaultRealmWithValue:@[@[obj0, obj1]]];
    [ArrayOfAllTypesObject createInDefaultRealmWithValue:@[@[obj1]]];
    [ArrayOfAllTypesObject createInDefaultRealmWithValue:@[@[obj0, obj2, obj3]]];
    [ArrayOfAllTypesObject createInDefaultRealmWithValue:@[@[obj4]]];

    [SetOfAllTypesObject createInDefaultRealmWithValue:@[@[obj0, obj1]]];
    [SetOfAllTypesObject createInDefaultRealmWithValue:@[@[obj1]]];
    [SetOfAllTypesObject createInDefaultRealmWithValue:@[@[obj0, obj2, obj3]]];
    [SetOfAllTypesObject createInDefaultRealmWithValue:@[@[obj4]]];

    [DictionaryOfAllTypesObject createInDefaultRealmWithValue:@[@{@"0": obj0, @"1": obj1}]];
    [DictionaryOfAllTypesObject createInDefaultRealmWithValue:@[@{@"1": obj1}]];
    [DictionaryOfAllTypesObject createInDefaultRealmWithValue:@[@{@"0": obj0, @"2": obj2, @"3": obj3}]];
    [DictionaryOfAllTypesObject createInDefaultRealmWithValue:@[@{@"4": obj4}]];

    [realm commitWriteTransaction];

    // simple queries
    RLMAssertCount(AllTypesObject, 2U, @"objectCol = %@", stringObj0);
    RLMAssertCount(AllTypesObject, 1U, @"objectCol = %@", stringObj1);
    RLMAssertCount(AllTypesObject, 1U, @"objectCol = nil");
    RLMAssertCount(AllTypesObject, 4U, @"objectCol != nil");
    RLMAssertCount(AllTypesObject, 3U, @"objectCol != %@", stringObj0);

    // check for ANY object in array
    RLMAssertCount(ArrayOfAllTypesObject, 2U, @"ANY array = %@", obj0);
    RLMAssertCount(ArrayOfAllTypesObject, 3U, @"ANY array != %@", obj1);
    RLMAssertCount(ArrayOfAllTypesObject, 2U, @"NONE array = %@", obj0);
    RLMAssertCount(ArrayOfAllTypesObject, 1U, @"NONE array != %@", obj1);
    XCTAssertThrows(([ArrayOfAllTypesObject objectsWhere:@"array = %@", obj0].count));
    XCTAssertThrows(([ArrayOfAllTypesObject objectsWhere:@"array != %@", obj0].count));

    // check for ANY object in set
    RLMAssertCount(SetOfAllTypesObject, 2U, @"ANY set = %@", obj0);
    RLMAssertCount(SetOfAllTypesObject, 3U, @"ANY set != %@", obj1);
    RLMAssertCount(SetOfAllTypesObject, 2U, @"NONE set = %@", obj0);
    RLMAssertCount(SetOfAllTypesObject, 1U, @"NONE set != %@", obj1);
    XCTAssertThrows(([SetOfAllTypesObject objectsWhere:@"set = %@", obj0].count));
    XCTAssertThrows(([SetOfAllTypesObject objectsWhere:@"set != %@", obj0].count));

    // check for ANY object in dictionary
    RLMAssertCount(DictionaryOfAllTypesObject, 2U, @"ANY dictionary = %@", obj0);
    RLMAssertCount(DictionaryOfAllTypesObject, 3U, @"ANY dictionary != %@", obj1);
    RLMAssertCount(DictionaryOfAllTypesObject, 2U, @"NONE dictionary = %@", obj0);
    RLMAssertCount(DictionaryOfAllTypesObject, 1U, @"NONE dictionary != %@", obj1);
    XCTAssertThrows(([DictionaryOfAllTypesObject objectsWhere:@"dictionary = %@", obj0].count));
    XCTAssertThrows(([DictionaryOfAllTypesObject objectsWhere:@"dictionary != %@", obj0].count));
}

- (void)testCompoundOrQuery {
    RLMRealm *realm = [self realm];

    [realm beginWriteTransaction];
    [PersonObject createInRealm:realm withValue:@[@"Tim", @29]];
    [PersonObject createInRealm:realm withValue:@[@"Ari", @33]];
    [realm commitWriteTransaction];

    RLMAssertCount(PersonObject, 2U, @"name == 'Ari' or age < 30");
    RLMAssertCount(PersonObject, 1U, @"name == 'Ari' or age > 40");
}

- (void)testCompoundAndQuery {
    RLMRealm *realm = [self realm];

    [realm beginWriteTransaction];
    [PersonObject createInRealm:realm withValue:@[@"Tim", @29]];
    [PersonObject createInRealm:realm withValue:@[@"Ari", @33]];
    [realm commitWriteTransaction];

    RLMAssertCount(PersonObject, 1U, @"name == 'Ari' and age > 30");
    RLMAssertCount(PersonObject, 0U, @"name == 'Ari' and age > 40");
}

- (void)testClass:(Class)class
  withNormalCount:(NSUInteger)normalCount
         notCount:(NSUInteger)notCount
            where:(NSString *)predicateFormat, ...
{
    va_list args;
    va_start(args, predicateFormat);
    NSPredicate *predicate = [NSPredicate predicateWithFormat:predicateFormat arguments:args];
    va_end(args);

    XCTAssertEqual(normalCount, [[self evaluate:[class objectsWithPredicate:predicate]] count],
                   @"%@", predicateFormat);

    predicate = [NSCompoundPredicate notPredicateWithSubpredicate:predicate];
    XCTAssertEqual(notCount, [[self evaluate:[class objectsWithPredicate:predicate]] count],
                   @"%@", predicateFormat);

}

- (void)testINPredicate {
    RLMRealm *realm = [self realm];

    [realm beginWriteTransaction];
    StringObject *so = [StringObject createInRealm:realm withValue:(@[@"abc"])];
    AllTypesObject *obj = [AllTypesObject createInRealm:realm withValue:[AllTypesObject values:1 stringObject:so]];
    [realm commitWriteTransaction];

    // Tests for each type always follow: none, some, more

    ////////////////////////
    // Literal Predicates
    ////////////////////////

    // BOOL
    [self testClass:[AllTypesObject class] withNormalCount:0 notCount:1 where:@"boolCol IN {NO}"];
    [self testClass:[AllTypesObject class] withNormalCount:1 notCount:0 where:@"boolCol IN {YES}"];
    [self testClass:[AllTypesObject class] withNormalCount:1 notCount:0 where:@"boolCol IN {NO, YES}"];

    // int
    [self testClass:[AllTypesObject class] withNormalCount:0 notCount:1 where:@"intCol IN {0, 2, 3}"];
    [self testClass:[AllTypesObject class] withNormalCount:1 notCount:0 where:@"intCol IN {1}"];
    [self testClass:[AllTypesObject class] withNormalCount:1 notCount:0 where:@"intCol IN {1, 2}"];

    // float
    [self testClass:[AllTypesObject class] withNormalCount:0 notCount:1 where:@"floatCol IN {0, 2, 3}"];
    [self testClass:[AllTypesObject class] withNormalCount:1 notCount:0 where:@"floatCol IN {1.1}"];
    [self testClass:[AllTypesObject class] withNormalCount:1 notCount:0 where:@"floatCol IN {1.1, 2.2}"];

    // double
    [self testClass:[AllTypesObject class] withNormalCount:0 notCount:1 where:@"doubleCol IN {0, 2, 3}"];
    [self testClass:[AllTypesObject class] withNormalCount:1 notCount:0 where:@"doubleCol IN {1.11}"];
    [self testClass:[AllTypesObject class] withNormalCount:1 notCount:0 where:@"doubleCol IN {1.11, 2.22}"];

    // NSString
    [self testClass:[AllTypesObject class] withNormalCount:1 notCount:0 where:@"stringCol IN {'a'}"];
    [self testClass:[AllTypesObject class] withNormalCount:0 notCount:1 where:@"stringCol IN {'b'}"];
    [self testClass:[AllTypesObject class] withNormalCount:0 notCount:1 where:@"stringCol IN {'A'}"];
    [self testClass:[AllTypesObject class] withNormalCount:1 notCount:0 where:@"stringCol IN[c] {'a'}"];
    [self testClass:[AllTypesObject class] withNormalCount:1 notCount:0 where:@"stringCol IN[c] {'A'}"];

    // NSData
    // Can't represent NSData with NSPredicate literal. See format predicates below

    // NSDate
    // Can't represent NSDate with NSPredicate literal. See format predicates below

    // bool
    [self testClass:[AllTypesObject class] withNormalCount:0 notCount:1 where:@"cBoolCol IN {NO}"];
    [self testClass:[AllTypesObject class] withNormalCount:1 notCount:0 where:@"cBoolCol IN {YES}"];
    [self testClass:[AllTypesObject class] withNormalCount:1 notCount:0 where:@"cBoolCol IN {NO, YES}"];

    // int64_t
    [self testClass:[AllTypesObject class] withNormalCount:0 notCount:1 where:@"longCol IN {0, 2, 3}"];
    [self testClass:[AllTypesObject class] withNormalCount:1 notCount:0 where:@"longCol IN {2147483648}"];
    [self testClass:[AllTypesObject class] withNormalCount:1 notCount:0 where:@"longCol IN {100, 2147483648}"];

    // string subobject
    [self testClass:[AllTypesObject class] withNormalCount:1 notCount:0 where:@"objectCol.stringCol IN {'abc'}"];
    [self testClass:[AllTypesObject class] withNormalCount:0 notCount:1 where:@"objectCol.stringCol IN {'def'}"];
    [self testClass:[AllTypesObject class] withNormalCount:0 notCount:1 where:@"objectCol.stringCol IN {'ABC'}"];
    [self testClass:[AllTypesObject class] withNormalCount:1 notCount:0 where:@"objectCol.stringCol IN[c] {'abc'}"];
    [self testClass:[AllTypesObject class] withNormalCount:1 notCount:0 where:@"objectCol.stringCol IN[c] {'ABC'}"];

    // RLMDecimal128
    [self testClass:[AllTypesObject class] withNormalCount:0 notCount:1 where:@"decimalCol IN {0, 2, 3}"];
    [self testClass:[AllTypesObject class] withNormalCount:1 notCount:0 where:@"decimalCol IN {1}"];
    [self testClass:[AllTypesObject class] withNormalCount:1 notCount:0 where:@"decimalCol IN {1, 2}"];
    [self testClass:[AllTypesObject class] withNormalCount:1 notCount:0 where:@"decimalCol IN {'1', '2'}"];

    // RLMValue
    [self testClass:[AllTypesObject class] withNormalCount:0 notCount:1 where:@"anyCol IN {0, 1, 3}"];
    [self testClass:[AllTypesObject class] withNormalCount:1 notCount:0 where:@"anyCol IN {2}"];
    [self testClass:[AllTypesObject class] withNormalCount:1 notCount:0 where:@"anyCol IN {1, 2}"];
    [self testClass:[AllTypesObject class] withNormalCount:0 notCount:1 where:@"anyCol IN {'1', '2'}"];

    // RLMObjectId
    // Can't represent RLMObjectId with NSPredicate literal. See format predicates below

    ////////////////////////
    // Format Predicates
    ////////////////////////

    // BOOL
    [self testClass:[AllTypesObject class] withNormalCount:0U notCount:1U where:@"boolCol IN %@", @[@NO]];
    [self testClass:[AllTypesObject class] withNormalCount:1U notCount:0U where:@"boolCol IN %@", @[@YES]];
    [self testClass:[AllTypesObject class] withNormalCount:1U notCount:0U where:@"boolCol IN %@", @[@NO, @YES]];

    // int
    [self testClass:[AllTypesObject class] withNormalCount:0U notCount:1U where:@"intCol IN %@", @[@0, @2, @3]];
    [self testClass:[AllTypesObject class] withNormalCount:1U notCount:0U where:@"intCol IN %@", @[@1]];
    [self testClass:[AllTypesObject class] withNormalCount:1U notCount:0U where:@"intCol IN %@", @[@1, @2]];

    // float
    [self testClass:[AllTypesObject class] withNormalCount:0U notCount:1U where:@"floatCol IN %@", @[@0, @2, @3]];
    [self testClass:[AllTypesObject class] withNormalCount:1U notCount:0U where:@"floatCol IN %@", @[@1.1f]];
    [self testClass:[AllTypesObject class] withNormalCount:1U notCount:0U where:@"floatCol IN %@", @[@1.1f, @2]];

    // double
    [self testClass:[AllTypesObject class] withNormalCount:0U notCount:1U where:@"doubleCol IN %@", @[@0, @2, @3]];
    [self testClass:[AllTypesObject class] withNormalCount:1U notCount:0U where:@"doubleCol IN %@", @[@1.11]];
    [self testClass:[AllTypesObject class] withNormalCount:1U notCount:0U where:@"doubleCol IN %@", @[@1.11, @2]];

    // NSString
    [self testClass:[AllTypesObject class] withNormalCount:1U notCount:0U where:@"stringCol IN %@", @[@"a"]];
    [self testClass:[AllTypesObject class] withNormalCount:0U notCount:1U where:@"stringCol IN %@", @[@"b"]];
    [self testClass:[AllTypesObject class] withNormalCount:0U notCount:1U where:@"stringCol IN %@", @[@"A"]];
    [self testClass:[AllTypesObject class] withNormalCount:1U notCount:0U where:@"stringCol IN[c] %@", @[@"a"]];
    [self testClass:[AllTypesObject class] withNormalCount:1U notCount:0U where:@"stringCol IN[c] %@", @[@"A"]];

    // NSData
    [self testClass:[AllTypesObject class] withNormalCount:0U notCount:1U where:@"binaryCol IN %@", @[[@"" dataUsingEncoding:NSUTF8StringEncoding]]];
    [self testClass:[AllTypesObject class] withNormalCount:1U notCount:0U where:@"binaryCol IN %@", @[[@"a" dataUsingEncoding:NSUTF8StringEncoding]]];
    [self testClass:[AllTypesObject class] withNormalCount:1U notCount:0U where:@"binaryCol IN %@", @[[@"a" dataUsingEncoding:NSUTF8StringEncoding], [@"b" dataUsingEncoding:NSUTF8StringEncoding]]];

    // NSDate
    [self testClass:[AllTypesObject class] withNormalCount:0U notCount:1U where:@"dateCol IN %@", @[[NSDate dateWithTimeIntervalSince1970:0]]];
    [self testClass:[AllTypesObject class] withNormalCount:1U notCount:0U where:@"dateCol IN %@", @[[NSDate dateWithTimeIntervalSince1970:1]]];
    [self testClass:[AllTypesObject class] withNormalCount:1U notCount:0U where:@"dateCol IN %@", @[[NSDate dateWithTimeIntervalSince1970:0], [NSDate dateWithTimeIntervalSince1970:1]]];

    // bool
    [self testClass:[AllTypesObject class] withNormalCount:0U notCount:1U where:@"cBoolCol IN %@", @[@NO]];
    [self testClass:[AllTypesObject class] withNormalCount:1U notCount:0U where:@"cBoolCol IN %@", @[@YES]];
    [self testClass:[AllTypesObject class] withNormalCount:1U notCount:0U where:@"cBoolCol IN %@", @[@NO, @YES]];

    // int64_t
    [self testClass:[AllTypesObject class] withNormalCount:0U notCount:1U where:@"longCol IN %@", @[@0, @2, @3]];
    [self testClass:[AllTypesObject class] withNormalCount:1U notCount:0U where:@"longCol IN %@", @[@(INT_MAX + 1LL)]];
    [self testClass:[AllTypesObject class] withNormalCount:1U notCount:0U where:@"longCol IN %@", @[@(INT_MAX + 1LL), @2]];

    // string subobject
    [self testClass:[AllTypesObject class] withNormalCount:1U notCount:0U where:@"objectCol.stringCol IN %@", @[@"abc"]];
    [self testClass:[AllTypesObject class] withNormalCount:0U notCount:1U where:@"objectCol.stringCol IN %@", @[@"def"]];
    [self testClass:[AllTypesObject class] withNormalCount:0U notCount:1U where:@"objectCol.stringCol IN %@", @[@"ABC"]];
    [self testClass:[AllTypesObject class] withNormalCount:1U notCount:0U where:@"objectCol.stringCol IN[c] %@", @[@"abc"]];
    [self testClass:[AllTypesObject class] withNormalCount:1U notCount:0U where:@"objectCol.stringCol IN[c] %@", @[@"ABC"]];

    // RLMDecimal128
    [self testClass:[AllTypesObject class] withNormalCount:0 notCount:1 where:@"decimalCol IN %@", @[@0, @2, @3]];
    [self testClass:[AllTypesObject class] withNormalCount:0 notCount:1 where:@"decimalCol IN %@", @[@"0", @"2", @"3"]];
    [self testClass:[AllTypesObject class] withNormalCount:1 notCount:0 where:@"decimalCol IN %@", @[@1]];
    [self testClass:[AllTypesObject class] withNormalCount:1 notCount:0 where:@"decimalCol IN %@", @[@1, @2]];
    [self testClass:[AllTypesObject class] withNormalCount:1 notCount:0 where:@"decimalCol IN %@", @[@"1", @"2"]];

    // RLMObjectId
    RLMObjectId *objectId = obj.objectIdCol;
    RLMObjectId *otherId = [RLMObjectId objectId];
    [self testClass:[AllTypesObject class] withNormalCount:0 notCount:1 where:@"objectIdCol IN %@", @[otherId]];
    [self testClass:[AllTypesObject class] withNormalCount:1 notCount:0 where:@"objectIdCol IN %@", @[objectId]];
    [self testClass:[AllTypesObject class] withNormalCount:1 notCount:0 where:@"objectIdCol IN %@", @[objectId, otherId]];

    // RLMValue
    [self testClass:[AllTypesObject class] withNormalCount:0U notCount:1U where:@"anyCol IN %@", @[@0, @1, @3]];
    [self testClass:[AllTypesObject class] withNormalCount:1U notCount:0U where:@"anyCol IN %@", @[@2]];
    [self testClass:[AllTypesObject class] withNormalCount:1U notCount:0U where:@"anyCol IN %@", @[@1, @2]];
}

- (void)testArrayIn {
    RLMRealm *realm = [self realm];
    [realm beginWriteTransaction];

    ArrayPropertyObject *arr = [ArrayPropertyObject createInRealm:realm withValue:@[@"name", @[], @[]]];
    [arr.array addObject:[StringObject createInRealm:realm withValue:@[@"value"]]];
    StringObject *otherStringObject = [StringObject createInRealm:realm withValue:@[@"some other value"]];
    [realm commitWriteTransaction];


    RLMAssertCount(ArrayPropertyObject, 0U, @"ANY array.stringCol IN %@", @[@"missing"]);
    RLMAssertCount(ArrayPropertyObject, 1U, @"ANY array.stringCol IN %@", @[@"value"]);
    RLMAssertCount(ArrayPropertyObject, 1U, @"NONE array.stringCol IN %@", @[@"missing"]);
    RLMAssertCount(ArrayPropertyObject, 0U, @"NONE array.stringCol IN %@", @[@"value"]);

    RLMAssertCount(ArrayPropertyObject, 0U, @"ANY array IN %@", [StringObject objectsWhere:@"stringCol = 'missing'"]);
    RLMAssertCount(ArrayPropertyObject, 1U, @"ANY array IN %@", [StringObject objectsWhere:@"stringCol = 'value'"]);
    RLMAssertCount(ArrayPropertyObject, 1U, @"NONE array IN %@", [StringObject objectsWhere:@"stringCol = 'missing'"]);
    RLMAssertCount(ArrayPropertyObject, 0U, @"NONE array IN %@", [StringObject objectsWhere:@"stringCol = 'value'"]);

    StringObject *stringObject = [[StringObject allObjectsInRealm:realm] firstObject];
    RLMAssertCount(ArrayPropertyObject, 1U, @"%@ IN array", stringObject);
    RLMAssertCount(ArrayPropertyObject, 0U, @"%@ IN array", otherStringObject);
}

- (void)testSetIn {
    RLMRealm *realm = [self realm];
    [realm beginWriteTransaction];

    SetPropertyObject *s = [SetPropertyObject createInRealm:realm withValue:@[@"name", @[], @[]]];
    [s.set addObject:[StringObject createInRealm:realm withValue:@[@"value"]]];
    StringObject *otherStringObject = [StringObject createInRealm:realm withValue:@[@"some other value"]];
    [realm commitWriteTransaction];


    RLMAssertCount(SetPropertyObject, 0U, @"ANY set.stringCol IN %@", @[@"missing"]);
    RLMAssertCount(SetPropertyObject, 1U, @"ANY set.stringCol IN %@", @[@"value"]);
    RLMAssertCount(SetPropertyObject, 1U, @"NONE set.stringCol IN %@", @[@"missing"]);
    RLMAssertCount(SetPropertyObject, 0U, @"NONE set.stringCol IN %@", @[@"value"]);

    RLMAssertCount(SetPropertyObject, 0U, @"ANY set IN %@", [StringObject objectsWhere:@"stringCol = 'missing'"]);
    RLMAssertCount(SetPropertyObject, 1U, @"ANY set IN %@", [StringObject objectsWhere:@"stringCol = 'value'"]);
    RLMAssertCount(SetPropertyObject, 1U, @"NONE set IN %@", [StringObject objectsWhere:@"stringCol = 'missing'"]);
    RLMAssertCount(SetPropertyObject, 0U, @"NONE set IN %@", [StringObject objectsWhere:@"stringCol = 'value'"]);

    StringObject *stringObject = [[StringObject allObjectsInRealm:realm] firstObject];
    RLMAssertCount(SetPropertyObject, 1U, @"%@ IN set", stringObject);
    RLMAssertCount(SetPropertyObject, 0U, @"%@ IN set", otherStringObject);
}

- (void)testDictionaryIn {
    RLMRealm *realm = [self realm];
    [realm beginWriteTransaction];

    DictionaryPropertyObject *dict = [DictionaryPropertyObject createInRealm:realm withValue:@[]];
    dict.stringDictionary[@"value"] = [StringObject createInRealm:realm withValue:@[@"value"]];
    StringObject *otherStringObject = [StringObject createInRealm:realm withValue:@[@"some other value"]];
    [realm commitWriteTransaction];


    RLMAssertCount(DictionaryPropertyObject, 0U, @"ANY stringDictionary.stringCol IN %@", @[@"missing"]);
    RLMAssertCount(DictionaryPropertyObject, 1U, @"ANY stringDictionary.stringCol IN %@", @[@"value"]);
    RLMAssertCount(DictionaryPropertyObject, 1U, @"NONE stringDictionary.stringCol IN %@", @[@"missing"]);
    RLMAssertCount(DictionaryPropertyObject, 0U, @"NONE stringDictionary.stringCol IN %@", @[@"value"]);

    RLMAssertCount(DictionaryPropertyObject, 0U, @"ANY stringDictionary IN %@", [StringObject objectsWhere:@"stringCol = 'missing'"]);
    RLMAssertCount(DictionaryPropertyObject, 1U, @"ANY stringDictionary IN %@", [StringObject objectsWhere:@"stringCol = 'value'"]);
    RLMAssertCount(DictionaryPropertyObject, 1U, @"NONE stringDictionary IN %@", [StringObject objectsWhere:@"stringCol = 'missing'"]);
    RLMAssertCount(DictionaryPropertyObject, 0U, @"NONE stringDictionary IN %@", [StringObject objectsWhere:@"stringCol = 'value'"]);

    StringObject *stringObject = [[StringObject allObjectsInRealm:realm] firstObject];
    RLMAssertCount(DictionaryPropertyObject, 1U, @"%@ IN stringDictionary", stringObject);
    RLMAssertCount(DictionaryPropertyObject, 0U, @"%@ IN stringDictionary", otherStringObject);
}

- (void)testQueryChaining {
    RLMRealm *realm = [self realm];

    [realm beginWriteTransaction];
    [PersonObject createInRealm:realm withValue:@[@"Tim", @29]];
    [PersonObject createInRealm:realm withValue:@[@"Ari", @33]];
    [realm commitWriteTransaction];

    RLMAssertCount(PersonObject, 1U, @"name == 'Ari'");
    RLMAssertCount(PersonObject, 0U, @"name == 'Ari' and age == 29");
    XCTAssertEqual(0U, [[[PersonObject objectsWhere:@"name == 'Ari'"] objectsWhere:@"age == 29"] count]);
}

- (void)testLinkViewQuery {
    RLMRealm *realm = [self realm];

    [realm beginWriteTransaction];
    NSArray *employees = @[@{@"name": @"John", @"age": @30, @"hired": @NO},
                           @{@"name": @"Joe",  @"age": @40, @"hired": @YES},
                           @{@"name": @"Jill",  @"age": @50, @"hired": @YES}];
    CompanyObject *company = [CompanyObject createInRealm:realm
                                                withValue:@[@"company name", employees, employees, @{}]];
    for (NSDictionary *eData in employees) {
        company.employeeDict[eData[@"name"]] = [[EmployeeObject alloc] initWithValue:eData];
    }
    [realm commitWriteTransaction];

    CompanyObject *co = [CompanyObject allObjects][0];
    RLMAssertCount(co.employees, 1U, @"hired = NO");
    RLMAssertCount(co.employees, 2U, @"hired = YES");
    RLMAssertCount(co.employees, 1U, @"hired = YES AND age = 40");
    RLMAssertCount(co.employees, 0U, @"hired = YES AND age = 30");
    RLMAssertCount(co.employees, 3U, @"hired = YES OR age = 30");
    RLMAssertCount([co.employees, 1U, @"hired = YES"] objectsWhere:@"name = 'Joe'");
    RLMAssertCount(co.employeeSet, 1U, @"hired = NO");
    RLMAssertCount(co.employeeSet, 2U, @"hired = YES");
    RLMAssertCount(co.employeeSet, 1U, @"hired = YES AND age = 40");
    RLMAssertCount(co.employeeSet, 0U, @"hired = YES AND age = 30");
    RLMAssertCount(co.employeeSet, 3U, @"hired = YES OR age = 30");
    RLMAssertCount([co.employeeSet, 1U, @"hired = YES"] objectsWhere:@"name = 'Joe'");
    RLMAssertCount(co.employeeDict, 1U, @"hired = NO");
    RLMAssertCount(co.employeeDict, 2U, @"hired = YES");
    RLMAssertCount(co.employeeDict, 1U, @"hired = YES AND age = 40");
    RLMAssertCount(co.employeeDict, 0U, @"hired = YES AND age = 30");
    RLMAssertCount(co.employeeDict, 3U, @"hired = YES OR age = 30");
    RLMAssertCount([co.employeeDict, 1U, @"hired = YES"] objectsWhere:@"name = 'Joe'");
}

- (void)testLinkViewQueryLifetime {
    RLMRealm *realm = [self realm];

    [realm beginWriteTransaction];
    NSArray *employees = @[@{@"name": @"John", @"age": @30, @"hired": @NO},
                           @{@"name": @"Jill",  @"age": @50, @"hired": @YES}];
    CompanyObject *company = [CompanyObject createInRealm:realm
                                                withValue:@[@"company name", employees, employees]];
    for (NSDictionary *eData in employees) {
        company.employeeDict[eData[@"name"]] = [[EmployeeObject alloc] initWithValue:eData];
    }
    [EmployeeObject createInRealm:realm withValue:@{@"name": @"Joe",  @"age": @40, @"hired": @YES}];
    [realm commitWriteTransaction];

    RLMResults<EmployeeObject *> *subarray = nil;
    RLMResults<EmployeeObject *> *subarray2 = nil;
    RLMResults<EmployeeObject *> *subarray3 = nil;
    @autoreleasepool {
        __attribute((objc_precise_lifetime)) CompanyObject *co = [CompanyObject allObjects][0];
        subarray = [co.employees objectsWhere:@"age = 40"];
        subarray2 = [co.employeeSet objectsWhere:@"age = 40"];
        subarray3 = [co.employeeDict objectsWhere:@"age = 40"];
        XCTAssertEqual(0U, subarray.count);
        XCTAssertEqual(0U, subarray2.count);
        XCTAssertEqual(0U, subarray3.count);
    }

    [realm beginWriteTransaction];
    @autoreleasepool {
        __attribute((objc_precise_lifetime)) CompanyObject *co = [CompanyObject allObjects][0];
        [co.employees addObject:[EmployeeObject createInRealm:realm withValue:@{@"name": @"Joe",  @"age": @40, @"hired": @YES}]];
        [co.employeeSet addObject:[EmployeeObject createInRealm:realm withValue:@{@"name": @"Joe",  @"age": @40, @"hired": @YES}]];
        co.employeeDict[@"Joe"] = [EmployeeObject createInRealm:realm withValue:@{@"name": @"Joe",  @"age": @40, @"hired": @YES}];
    }
    [realm commitWriteTransaction];

    XCTAssertEqual(1U, subarray.count);
    XCTAssertEqualObjects(@"Joe", subarray[0][@"name"]);
    XCTAssertEqual(1U, subarray2.count);
    XCTAssertEqualObjects(@"Joe", subarray2[0][@"name"]);
    XCTAssertEqual(1U, subarray3.count);
    XCTAssertEqualObjects(@"Joe", subarray3[0][@"name"]);
}

- (void)testLinkViewQueryLiveUpdate {
    RLMRealm *realm = [self realm];

    [realm beginWriteTransaction];
    NSArray *employees = @[@{@"name": @"John", @"age": @30, @"hired": @NO},
                           @{@"name": @"Jill",  @"age": @40, @"hired": @YES}];
    CompanyObject *company = [CompanyObject createInRealm:realm
                                                withValue:@[@"company name", employees, employees]];
    for (NSDictionary *eData in employees) {
        company.employeeDict[eData[@"name"]] = [[EmployeeObject alloc] initWithValue:eData];
    }
    EmployeeObject *eo = [EmployeeObject createInRealm:realm withValue:@{@"name": @"Joe",  @"age": @40, @"hired": @YES}];
    [realm commitWriteTransaction];

    CompanyObject *co = CompanyObject.allObjects.firstObject;
    RLMResults *basic = [co.employees objectsWhere:@"age = 40"];
    RLMResults *sort = [co.employees sortedResultsUsingKeyPath:@"name" ascending:YES];
    RLMResults *sortQuery = [[co.employees sortedResultsUsingKeyPath:@"name" ascending:YES] objectsWhere:@"age = 40"];
    RLMResults *querySort = [[co.employees objectsWhere:@"age = 40"] sortedResultsUsingKeyPath:@"name" ascending:YES];
    RLMResults *basic2 = [co.employeeSet objectsWhere:@"age = 40"];
    RLMResults *sort2 = [co.employeeSet sortedResultsUsingKeyPath:@"name" ascending:YES];
    RLMResults *sortQuery2 = [[co.employeeSet sortedResultsUsingKeyPath:@"name" ascending:YES] objectsWhere:@"age = 40"];
    RLMResults *querySort2 = [[co.employeeSet objectsWhere:@"age = 40"] sortedResultsUsingKeyPath:@"name" ascending:YES];
    RLMResults *basic3 = [co.employeeDict objectsWhere:@"age = 40"];
    RLMResults *sort3 = [co.employeeDict sortedResultsUsingKeyPath:@"name" ascending:YES];
    RLMResults *sortQuery3 = [[co.employeeDict sortedResultsUsingKeyPath:@"name" ascending:YES] objectsWhere:@"age = 40"];
    RLMResults *querySort3 = [[co.employeeDict objectsWhere:@"age = 40"] sortedResultsUsingKeyPath:@"name" ascending:YES];

    XCTAssertEqual(1U, basic.count);
    XCTAssertEqual(2U, sort.count);
    XCTAssertEqual(1U, sortQuery.count);
    XCTAssertEqual(1U, querySort.count);

    XCTAssertEqual(1U, basic2.count);
    XCTAssertEqual(2U, sort2.count);
    XCTAssertEqual(1U, sortQuery2.count);
    XCTAssertEqual(1U, querySort2.count);

    XCTAssertEqual(1U, basic3.count);
    XCTAssertEqual(2U, sort3.count);
    XCTAssertEqual(1U, sortQuery3.count);
    XCTAssertEqual(1U, querySort3.count);

    XCTAssertEqualObjects(@"Jill", [[basic lastObject] name]);
    XCTAssertEqualObjects(@"Jill", [[sortQuery lastObject] name]);
    XCTAssertEqualObjects(@"Jill", [[querySort lastObject] name]);

    XCTAssertEqualObjects(@"Jill", [[basic2 lastObject] name]);
    XCTAssertEqualObjects(@"Jill", [[sortQuery2 lastObject] name]);
    XCTAssertEqualObjects(@"Jill", [[querySort2 lastObject] name]);

    XCTAssertEqualObjects(@"Jill", [[basic3 lastObject] name]);
    XCTAssertEqualObjects(@"Jill", [[sortQuery3 lastObject] name]);
    XCTAssertEqualObjects(@"Jill", [[querySort3 lastObject] name]);

    [realm beginWriteTransaction];
    [co.employees addObject:eo];
    [co.employeeSet addObject:eo];
    co.employeeDict[eo.name] = eo;
    [realm commitWriteTransaction];

    XCTAssertEqual(2U, basic.count);
    XCTAssertEqual(3U, sort.count);
    XCTAssertEqual(2U, sortQuery.count);
    XCTAssertEqual(2U, querySort.count);

    XCTAssertEqual(2U, basic2.count);
    XCTAssertEqual(3U, sort2.count);
    XCTAssertEqual(2U, sortQuery2.count);
    XCTAssertEqual(2U, querySort2.count);

    XCTAssertEqual(2U, basic3.count);
    XCTAssertEqual(3U, sort3.count);
    XCTAssertEqual(2U, sortQuery3.count);
    XCTAssertEqual(2U, querySort3.count);

    XCTAssertEqualObjects(@"Joe", [[basic lastObject] name]);
    XCTAssertEqualObjects(@"Joe", [[sortQuery lastObject] name]);
    XCTAssertEqualObjects(@"Joe", [[querySort lastObject] name]);

    XCTAssertEqualObjects(@"Joe", [[basic2 lastObject] name]);
    XCTAssertEqualObjects(@"Joe", [[sortQuery2 lastObject] name]);
    XCTAssertEqualObjects(@"Joe", [[querySort2 lastObject] name]);

    XCTAssertEqualObjects(@"Joe", [[basic3 lastObject] name]);
    XCTAssertEqualObjects(@"Joe", [[sortQuery3 lastObject] name]);
    XCTAssertEqualObjects(@"Joe", [[querySort3 lastObject] name]);
}

- (void)testConstantPredicates
{
    RLMRealm *realm = [self realm];

    [realm beginWriteTransaction];
    [PersonObject createInRealm:realm withValue:@[@"Fiel", @27]];
    [PersonObject createInRealm:realm withValue:@[@"Tim", @29]];
    [PersonObject createInRealm:realm withValue:@[@"Ari", @33]];
    [realm commitWriteTransaction];

    RLMResults *all = [PersonObject objectsWithPredicate:[NSPredicate predicateWithValue:YES]];
    XCTAssertEqual(all.count, 3U, @"Expecting 3 results");

    RLMResults *none = [PersonObject objectsWithPredicate:[NSPredicate predicateWithValue:NO]];
    XCTAssertEqual(none.count, 0U, @"Expecting 0 results");
}

- (void)testEmptyCompoundPredicates
{
    RLMRealm *realm = [self realm];

    [realm beginWriteTransaction];
    [PersonObject createInRealm:realm withValue:@[@"Fiel", @27]];
    [PersonObject createInRealm:realm withValue:@[@"Tim", @29]];
    [PersonObject createInRealm:realm withValue:@[@"Ari", @33]];
    [realm commitWriteTransaction];

    RLMResults *all = [PersonObject objectsWithPredicate:[NSCompoundPredicate andPredicateWithSubpredicates:@[]]];
    XCTAssertEqual(all.count, 3U, @"Expecting 3 results");

    RLMResults *none = [PersonObject objectsWithPredicate:[NSCompoundPredicate orPredicateWithSubpredicates:@[]]];
    XCTAssertEqual(none.count, 0U, @"Expecting 0 results");
}

static NSData *data(const char *str) {
    return [NSData dataWithBytes:str length:strlen(str)];
}

- (NSArray<NSArray *> *)queryObjectClassValues {
    RLMObjectId *oid1 = [RLMObjectId objectId];
    RLMObjectId *oid2 = [RLMObjectId objectId];
    return @[
        @[@YES, @YES, @1, @2, @23.0f, @1.7f,  @0.0,  @5.55, @"a", @"a", data("a"), data("a"), @1, @2, oid1, oid1, @YES, @NO],
        @[@YES, @NO,  @1, @3, @-5.3f, @4.21f, @1.0,  @4.44, @"a", @"A", data("a"), data("A"), @1, @3, oid1, oid2, @1, @2],
        @[@NO,  @NO,  @2, @2, @1.0f,  @3.55f, @99.9, @6.66, @"a", @"ab", data("a"), data("ab"), @2, @2, oid2, oid2, @1.0f, @2.0f],
        @[@NO,  @YES, @3, @6, @4.21f, @1.0f,  @1.0,  @7.77, @"a", @"AB", data("a"), data("AB"), @3, @6, oid2, oid1, @"one", @"two"],
        @[@YES, @YES, @4, @5, @23.0f, @23.0f, @7.4,  @8.88, @"a", @"b", data("a"), data("b"), @4, @5, oid1, oid1, @"two", @"three"],
        @[@YES, @NO,  @15, @8, @1.0f,  @66.0f, @1.01, @9.99, @"a", @"ba", data("a"), data("ba"), @15, @8, oid1, oid2, data("a"), data("b")],
        @[@NO,  @YES, @15, @15, @1.0f,  @66.0f, @1.01, @9.99, @"a", @"BA", data("a"), data("BA"), @15, @15, oid2, oid1, oid1, oid2],
    ];
}

- (void)testComparisonsWithKeyPathOnRHS
{
    RLMRealm *realm = [self realm];

    [realm beginWriteTransaction];
    NSArray<NSArray *> *values = [self queryObjectClassValues];
    RLMObjectId *oid1 = values[0][14];
    for (id value in values) {
        [self.queryObjectClass createInRealm:realm withValue:value];
    }
    [realm commitWriteTransaction];

    RLMAssertCount(self.queryObjectClass, 4U, @"TRUE == bool1");
    RLMAssertCount(self.queryObjectClass, 3U, @"TRUE != bool2");

    RLMAssertCount(self.queryObjectClass, 2U, @"1 == int1");
    RLMAssertCount(self.queryObjectClass, 5U, @"2 != int2");
    RLMAssertCount(self.queryObjectClass, 2U, @"2 > int1");
    RLMAssertCount(self.queryObjectClass, 4U, @"2 < int1");
    RLMAssertCount(self.queryObjectClass, 3U, @"2 >= int1");
    RLMAssertCount(self.queryObjectClass, 5U, @"2 <= int1");

    RLMAssertCount(self.queryObjectClass, 3U, @"1.0 == float1");
    RLMAssertCount(self.queryObjectClass, 6U, @"1.0 != float2");
    RLMAssertCount(self.queryObjectClass, 1U, @"1.0 > float1");
    RLMAssertCount(self.queryObjectClass, 6U, @"1.0 < float2");
    RLMAssertCount(self.queryObjectClass, 4U, @"1.0 >= float1");
    RLMAssertCount(self.queryObjectClass, 7U, @"1.0 <= float2");

    RLMAssertCount(self.queryObjectClass, 2U, @"1.0 == double1");
    RLMAssertCount(self.queryObjectClass, 5U, @"1.0 != double1");
    RLMAssertCount(self.queryObjectClass, 1U, @"5.0 > double2");
    RLMAssertCount(self.queryObjectClass, 6U, @"5.0 < double2");
    RLMAssertCount(self.queryObjectClass, 2U, @"5.55 >= double2");
    RLMAssertCount(self.queryObjectClass, 6U, @"5.55 <= double2");

    RLMAssertCount(self.queryObjectClass, 1U, @"'a' == string2");
    RLMAssertCount(self.queryObjectClass, 6U, @"'a' != string2");

    RLMAssertCount(self.queryObjectClass, 1U, @"%@ == data2", data("a"));
    RLMAssertCount(self.queryObjectClass, 6U, @"%@ != data2", data("a"));

    RLMAssertCount(self.queryObjectClass, 2U, @"1 == decimal1");
    RLMAssertCount(self.queryObjectClass, 5U, @"2 != decimal2");
    RLMAssertCount(self.queryObjectClass, 2U, @"2 > decimal1");
    RLMAssertCount(self.queryObjectClass, 4U, @"2 < decimal1");
    RLMAssertCount(self.queryObjectClass, 3U, @"2 >= decimal1");
    RLMAssertCount(self.queryObjectClass, 5U, @"2 <= decimal1");

    RLMAssertCount(self.queryObjectClass, 2U, @"1 == any1");
    RLMAssertCount(self.queryObjectClass, 2U, @"1.0 == any1");
    RLMAssertCount(self.queryObjectClass, 1U, @"'one' == any1");
    RLMAssertCount(self.queryObjectClass, 6U, @"'one' != any1");
    RLMAssertCount(self.queryObjectClass, 1U, @"TRUE == any1");
    RLMAssertCount(self.queryObjectClass, 6U, @"TRUE != any1");
    RLMAssertCount(self.queryObjectClass, 1U, @"%@ == any1", oid1);
    RLMAssertCount(self.queryObjectClass, 6U, @"%@ != any1", oid1);
    RLMAssertCount(self.queryObjectClass, 5U, @"2 != any2");
    RLMAssertCount(self.queryObjectClass, 2U, @"2 > any1");
    RLMAssertCount(self.queryObjectClass, 0U, @"2 < any1");
    RLMAssertCount(self.queryObjectClass, 2U, @"2 >= any1");
    RLMAssertCount(self.queryObjectClass, 0U, @"2 <= any1");

    RLMAssertCount(self.queryObjectClass, 4U, @"%@ == objectId1", oid1);
    RLMAssertCount(self.queryObjectClass, 3U, @"%@ != objectId2", oid1);

    RLMAssertThrowsWithReasonMatching([self.queryObjectClass objectsWhere:@"'Realm' CONTAINS string1"].count,
                                      @"Operator 'CONTAINS' requires a keypath on the left side.");
    RLMAssertThrowsWithReasonMatching([self.queryObjectClass objectsWhere:@"'Amazon' BEGINSWITH string2"].count,
                                      @"Operator 'BEGINSWITH' requires a keypath on the left side.");
    RLMAssertThrowsWithReasonMatching([self.queryObjectClass objectsWhere:@"'Tuba' ENDSWITH string1"].count,
                                      @"Operator 'ENDSWITH' requires a keypath on the left side.");
    RLMAssertThrowsWithReasonMatching([self.queryObjectClass objectsWhere:@"'Tuba' LIKE string1"].count,
                                      @"Operator 'LIKE' requires a keypath on the left side.");
}

- (void)testLinksToDeletedOrMovedObject
{
    RLMRealm *realm = [self realm];
    [realm beginWriteTransaction];

    DogObject *fido = [DogObject createInRealm:realm withValue:@[ @"Fido", @3 ]];
    [OwnerObject createInRealm:realm withValue:@[ @"Fido's owner", fido ]];

    DogObject *rex = [DogObject createInRealm:realm withValue:@[ @"Rex", @2 ]];
    [OwnerObject createInRealm:realm withValue:@[ @"Rex's owner", rex ]];

    DogObject *spot = [DogObject createInRealm:realm withValue:@[ @"Spot", @2 ]];
    [OwnerObject createInRealm:realm withValue:@[ @"Spot's owner", spot ]];

    [realm commitWriteTransaction];

    RLMResults *fidoQuery = [OwnerObject objectsInRealm:realm where:@"dog == %@", fido];
    RLMResults *rexQuery = [OwnerObject objectsInRealm:realm where:@"dog == %@", rex];
    RLMResults *spotQuery = [OwnerObject objectsInRealm:realm where:@"dog == %@", spot];

    [realm beginWriteTransaction];
    [realm deleteObject:fido];
    [realm commitWriteTransaction];

    // Fido was removed, so we should not find his owner.
    XCTAssertEqual(0u, fidoQuery.count);

    // Rex's owner should be found as the row was not touched.
    XCTAssertEqual(1u, rexQuery.count);
    XCTAssertEqualObjects(@"Rex's owner", [rexQuery.firstObject name]);

    // Spot's owner should be found, despite Spot's row having moved.
    XCTAssertEqual(1u, spotQuery.count);
    XCTAssertEqualObjects(@"Spot's owner", [spotQuery.firstObject name]);
}

- (void)testQueryOnDeletedArrayProperty
{
    RLMRealm *realm = [self realm];
    [realm beginWriteTransaction];
    IntObject *io = [IntObject createInRealm:realm withValue:@[@0]];
    ArrayPropertyObject *array = [ArrayPropertyObject createInRealm:realm withValue:@[@"", @[], @[io]]];
    [realm commitWriteTransaction];

    RLMResults *results = [array.intArray objectsWhere:@"TRUEPREDICATE"];
    XCTAssertEqual(1U, results.count);

    [realm beginWriteTransaction];
    [realm deleteObject:array];
    [realm commitWriteTransaction];

    XCTAssertEqual(0U, results.count);
    XCTAssertNil(results.firstObject);
}

- (void)testQueryOnDeletedSetProperty
{
    RLMRealm *realm = [self realm];
    [realm beginWriteTransaction];
    IntObject *io = [IntObject createInRealm:realm withValue:@[@0]];
    SetPropertyObject *set = [SetPropertyObject createInRealm:realm withValue:@[@"", @[], @[io]]];
    [realm commitWriteTransaction];

    RLMResults *results = [set.intSet objectsWhere:@"TRUEPREDICATE"];
    XCTAssertEqual(1U, results.count);

    [realm beginWriteTransaction];
    [realm deleteObject:set];
    [realm commitWriteTransaction];

    XCTAssertEqual(0U, results.count);
    XCTAssertNil(results.firstObject);
}

- (void)testQueryOnDeletedDictionaryProperty
{
    RLMRealm *realm = [self realm];
    [realm beginWriteTransaction];
    IntObject *io = [IntObject createInRealm:realm withValue:@[@0]];
    DictionaryPropertyObject *dpo = [DictionaryPropertyObject createInRealm:realm withValue:@{@"intObjDictionary": @{@"0": io}}];
    [realm commitWriteTransaction];

    RLMResults *results = [dpo.intObjDictionary objectsWhere:@"TRUEPREDICATE"];
    XCTAssertEqual(1U, results.count);

    [realm beginWriteTransaction];
    [realm deleteObject:dpo];
    [realm commitWriteTransaction];

    XCTAssertEqual(0U, results.count);
    XCTAssertNil(results.firstObject);
}

- (void)testSubqueries
{
    RLMRealm *realm = [self realm];

    [realm beginWriteTransaction];

    NSArray *employees = @[@{@"name": @"John", @"age": @30, @"hired": @NO},
                           @{@"name": @"Jill",  @"age": @40, @"hired": @YES},
                           @{@"name": @"Joe",  @"age": @40, @"hired": @YES}];

    NSArray *employees2 = @[@{@"name": @"Bill", @"age": @35, @"hired": @YES},
                            @{@"name": @"Don",  @"age": @45, @"hired": @NO},
                            @{@"name": @"Tim",  @"age": @60, @"hired": @NO}];
    CompanyObject *first = [CompanyObject createInRealm:realm
                                              withValue:@[@"first company", employees, employees]];
    for (NSDictionary *eData in employees) {
        first.employeeDict[eData[@"name"]] = [[EmployeeObject alloc] initWithValue:eData];
    }
    CompanyObject *second = [CompanyObject createInRealm:realm
                                               withValue:@[@"second company", employees2, employees2]];
    for (NSDictionary *eData in employees2) {
        second.employeeDict[eData[@"name"]] = [[EmployeeObject alloc] initWithValue:eData];
    }

    [LinkToCompanyObject createInRealm:realm withValue:@[ first ]];
    [LinkToCompanyObject createInRealm:realm withValue:@[ second ]];
    [realm commitWriteTransaction];

    RLMAssertCount(CompanyObject, 1U, @"SUBQUERY(employees, $employee, $employee.age > 30 AND $employee.hired = FALSE).@count > 0");
    RLMAssertCount(CompanyObject, 2U, @"SUBQUERY(employees, $employee, $employee.age < 30 AND $employee.hired = TRUE).@count == 0");
    RLMAssertCount(CompanyObject, 1U, @"SUBQUERY(employeeSet, $employee, $employee.age > 30 AND $employee.hired = FALSE).@count > 0");
    RLMAssertCount(CompanyObject, 2U, @"SUBQUERY(employeeSet, $employee, $employee.age < 30 AND $employee.hired = TRUE).@count == 0");

    RLMAssertCount(LinkToCompanyObject, 1U, @"SUBQUERY(company.employees, $employee, $employee.age > 30 AND $employee.hired = FALSE).@count > 0");
    RLMAssertCount(LinkToCompanyObject, 2U, @"SUBQUERY(company.employees, $employee, $employee.age < 30 AND $employee.hired = TRUE).@count == 0");

    RLMAssertCount(LinkToCompanyObject, 1U, @"SUBQUERY(company.employeeSet, $employee, $employee.age > 30 AND $employee.hired = FALSE).@count > 0");
    RLMAssertCount(LinkToCompanyObject, 2U, @"SUBQUERY(company.employeeSet, $employee, $employee.age < 30 AND $employee.hired = TRUE).@count == 0");

    RLMAssertCount(LinkToCompanyObject, 1U, @"SUBQUERY(company.employeeDict, $employee, $employee.age > 30 AND $employee.hired = FALSE).@count > 0");
    RLMAssertCount(LinkToCompanyObject, 2U, @"SUBQUERY(company.employeeDict, $employee, $employee.age < 30 AND $employee.hired = TRUE).@count == 0");
}

- (void)testLinkingObjects {
    RLMRealm *realm = [self realm];

    [realm beginWriteTransaction];

    PersonObject *hannah   = [PersonObject createInRealm:realm withValue:@[ @"Hannah",   @0 ]];
    PersonObject *elijah   = [PersonObject createInRealm:realm withValue:@[ @"Elijah",   @3 ]];

    PersonObject *mark     = [PersonObject createInRealm:realm withValue:@[ @"Mark",     @30, @[ hannah ]]];
    PersonObject *jason    = [PersonObject createInRealm:realm withValue:@[ @"Jason",    @31, @[ elijah ]]];

    PersonObject *diane    = [PersonObject createInRealm:realm withValue:@[ @"Diane",    @29, @[ hannah ]]];
    PersonObject *carol    = [PersonObject createInRealm:realm withValue:@[ @"Carol",    @31 ]];

    PersonObject *michael  = [PersonObject createInRealm:realm withValue:@[ @"Michael",  @57, @[ jason, mark ]]];
    PersonObject *raewynne = [PersonObject createInRealm:realm withValue:@[ @"Raewynne", @57, @[ jason, mark ]]];

    PersonObject *don      = [PersonObject createInRealm:realm withValue:@[ @"Don",      @64, @[ carol, diane ]]];
    PersonObject *diane_sr = [PersonObject createInRealm:realm withValue:@[ @"Diane",    @60, @[ carol, diane ]]];

    [realm commitWriteTransaction];

    NSArray *(^asArray)(RLMResults *) = ^(RLMResults *results) {
        return [[self evaluate:results] valueForKeyPath:@"self"];
    };

    // People that have a parent with a name that starts with 'M'.
    RLMResults *r1 = [PersonObject objectsWhere:@"ANY parents.name BEGINSWITH 'M'"];
    XCTAssertEqualObjects(asArray(r1), (@[ hannah, mark, jason ]));

    // People that have a grandparent with a name that starts with 'M'.
    RLMResults *r2 = [PersonObject objectsWhere:@"ANY parents.parents.name BEGINSWITH 'M'"];
    XCTAssertEqualObjects(asArray(r2), (@[ hannah, elijah ]));

    // People that have children that have a parent named Diane.
    RLMResults *r3 = [PersonObject objectsWhere:@"ANY children.parents.name == 'Diane'"];
    XCTAssertEqualObjects(asArray(r3), (@[ mark, diane, don, diane_sr ]));

    // People that have children that have a grandparent named Don.
    RLMResults *r4 = [PersonObject objectsWhere:@"ANY children.parents.parents.name == 'Don'"];
    XCTAssertEqualObjects(asArray(r4), (@[ mark, diane ]));

    // People whose parents have an average age of < 60.
    RLMResults *r5 = [PersonObject objectsWhere:@"parents.@avg.age < 60"];
    XCTAssertEqualObjects(asArray(r5), (@[ hannah, elijah, mark, jason ]));

    // People that have at least one sibling.
    RLMResults *r6 = [PersonObject objectsWhere:@"SUBQUERY(parents, $parent, $parent.children.@count > 1).@count > 0"];
    XCTAssertEqualObjects(asArray(r6), (@[ mark, jason, diane, carol ]));

    // People that have Raewynne as a parent.
    RLMResults *r7 = [PersonObject objectsWhere:@"ANY parents == %@", raewynne];
    XCTAssertEqualObjects(asArray(r7), (@[ mark, jason ]));

    // People that have Mark as a child.
    RLMResults *r8 = [PersonObject objectsWhere:@"ANY children == %@", mark];
    XCTAssertEqualObjects(asArray(r8), (@[ michael, raewynne ]));

    // People that have Michael as a grandparent.
    RLMResults *r9 = [PersonObject objectsWhere:@"ANY parents.parents == %@", michael];
    XCTAssertEqualObjects(asArray(r9), (@[ hannah, elijah ]));

    // People that have Hannah as a grandchild.
    RLMResults *r10 = [PersonObject objectsWhere:@"ANY children.children == %@", hannah];
    XCTAssertEqualObjects(asArray(r10), (@[ michael, raewynne, don, diane_sr ]));

    // People that have no listed parents.
    RLMResults *r11 = [PersonObject objectsWhere:@"parents.@count == 0"];
    XCTAssertEqualObjects(asArray(r11), (@[ michael, raewynne, don, diane_sr ]));

    // No links are equal to a detached row accessor.
    RLMResults *r12 = [PersonObject objectsWhere:@"ANY parents == %@", [PersonObject new]];
    XCTAssertEqualObjects(asArray(r12), (@[ ]));

    // All links are not equal to a detached row accessor so this will match all rows that are linked to.
    RLMResults *r13 = [PersonObject objectsWhere:@"ANY parents != %@", [PersonObject new]];
    XCTAssertEqualObjects(asArray(r13), (@[ hannah, elijah, mark, jason, diane, carol ]));

    // Linking objects cannot contain null so their members cannot be compared with null.
    XCTAssertThrows([PersonObject objectsWhere:@"ANY parents == NULL"]);

    // People that have a parent under the age of 31 where that parent has a parent over the age of 35 whose name is Michael.
    RLMResults *r14 = [PersonObject objectsWhere:@"SUBQUERY(parents, $p1, $p1.age < 31 AND SUBQUERY($p1.parents, $p2, $p2.age > 35 AND $p2.name == 'Michael').@count > 0).@count > 0"];
    XCTAssertEqualObjects(asArray(r14), (@[ hannah ]));


    // Add a new link and verify that the existing results update as expected.
    __block PersonObject *mackenzie;
    [realm transactionWithBlock:^{
        mackenzie = [PersonObject createInRealm:realm withValue:@[ @"Mackenzie", @0 ]];
        [jason.children addObject:mackenzie];
    }];


    // People that have a parent with a name that starts with 'M'.
    XCTAssertEqualObjects(asArray(r1), (@[ hannah, mark, jason ]));

    // People that have a grandparent with a name that starts with 'M'.
    XCTAssertEqualObjects(asArray(r2), (@[ hannah, elijah, mackenzie ]));

    // People that have children that have a parent named Diane.
    XCTAssertEqualObjects(asArray(r3), (@[ mark, diane, don, diane_sr ]));

    // People that have children that have a grandparent named Don.
    XCTAssertEqualObjects(asArray(r4), (@[ mark, diane ]));

    // People whose parents have an average age of < 60.
    XCTAssertEqualObjects(asArray(r5), (@[ hannah, elijah, mark, jason, mackenzie ]));

    // People that have at least one sibling.
    XCTAssertEqualObjects(asArray(r6), (@[ elijah, mark, jason, diane, carol, mackenzie ]));

    // People that have Raewynne as a parent.
    XCTAssertEqualObjects(asArray(r7), (@[ mark, jason ]));

    // People that have Mark as a child.
    XCTAssertEqualObjects(asArray(r8), (@[ michael, raewynne ]));

    // People that have Michael as a grandparent.
    XCTAssertEqualObjects(asArray(r9), (@[ hannah, elijah, mackenzie ]));

    // People that have Hannah as a grandchild.
    XCTAssertEqualObjects(asArray(r10), (@[ michael, raewynne, don, diane_sr ]));

    // People that have no listed parents.
    XCTAssertEqualObjects(asArray(r11), (@[ michael, raewynne, don, diane_sr ]));

    // No links are equal to a detached row accessor.
    XCTAssertEqualObjects(asArray(r12), (@[ ]));

    // All links are not equal to a detached row accessor so this will match all rows that are linked to.
    XCTAssertEqualObjects(asArray(r13), (@[ hannah, elijah, mark, jason, diane, carol, mackenzie ]));

    // People that have a parent under the age of 31 where that parent has a parent over the age of 35 whose name is Michael.
    XCTAssertEqualObjects(asArray(r14), (@[ hannah ]));
}

- (void)testCountOnArrayCollection {
    RLMRealm *realm = [self realm];
    [realm beginWriteTransaction];

    IntegerArrayPropertyObject *arr = [IntegerArrayPropertyObject createInRealm:realm withValue:@[ @1, @[]]];
    [arr.array addObject:[IntObject createInRealm:realm withValue:@[ @456 ]]];

    arr = [IntegerArrayPropertyObject createInRealm:realm withValue:@[ @2, @[]]];
    [arr.array addObject:[IntObject createInRealm:realm withValue:@[ @1 ]]];
    [arr.array addObject:[IntObject createInRealm:realm withValue:@[ @2 ]]];
    [arr.array addObject:[IntObject createInRealm:realm withValue:@[ @3 ]]];

    arr = [IntegerArrayPropertyObject createInRealm:realm withValue:@[ @0, @[]]];

    [realm commitWriteTransaction];

    RLMAssertCount(IntegerArrayPropertyObject, 2U, @"array.@count > 0");
    RLMAssertCount(IntegerArrayPropertyObject, 1U, @"array.@count == 3");
    RLMAssertCount(IntegerArrayPropertyObject, 1U, @"array.@count < 1");
    RLMAssertCount(IntegerArrayPropertyObject, 2U, @"0 < array.@count");
    RLMAssertCount(IntegerArrayPropertyObject, 1U, @"3 == array.@count");
    RLMAssertCount(IntegerArrayPropertyObject, 1U, @"1 >  array.@count");

    RLMAssertCount(IntegerArrayPropertyObject, 2U, @"array.@count == number");
    RLMAssertCount(IntegerArrayPropertyObject, 1U, @"array.@count > number");
    RLMAssertCount(IntegerArrayPropertyObject, 1U, @"number < array.@count");

    // We do not yet handle collection operations on both sides of the comparison.
    RLMAssertThrowsWithReasonMatching(([IntegerArrayPropertyObject objectsWhere:@"array.@count == array.@count"]),
                                      @"aggregate operations cannot be compared with other aggregate operations");

    RLMAssertThrowsWithReasonMatching(([IntegerArrayPropertyObject objectsWhere:@"array.@count.foo.bar != 0"]),
                                      @"single level key");
    RLMAssertThrowsWithReasonMatching(([IntegerArrayPropertyObject objectsWhere:@"array.@count.intCol > 0"]),
                                      @"@count does not have any properties");
    RLMAssertThrowsWithReasonMatching(([IntegerArrayPropertyObject objectsWhere:@"array.@count != 'Hello'"]),
                                      @"@count can only be compared with a numeric value");
}

- (void)testCountOnSetCollection {
    RLMRealm *realm = [self realm];
    [realm beginWriteTransaction];

    IntegerSetPropertyObject *set = [IntegerSetPropertyObject createInRealm:realm withValue:@[ @1, @[]]];
    [set.set addObject:[IntObject createInRealm:realm withValue:@[ @456 ]]];

    set = [IntegerSetPropertyObject createInRealm:realm withValue:@[ @2, @[]]];
    [set.set addObject:[IntObject createInRealm:realm withValue:@[ @1 ]]];
    [set.set addObject:[IntObject createInRealm:realm withValue:@[ @2 ]]];
    [set.set addObject:[IntObject createInRealm:realm withValue:@[ @3 ]]];

    set = [IntegerSetPropertyObject createInRealm:realm withValue:@[ @0, @[]]];

    [realm commitWriteTransaction];

    RLMAssertCount(IntegerSetPropertyObject, 2U, @"set.@count > 0");
    RLMAssertCount(IntegerSetPropertyObject, 1U, @"set.@count == 3");
    RLMAssertCount(IntegerSetPropertyObject, 1U, @"set.@count < 1");
    RLMAssertCount(IntegerSetPropertyObject, 2U, @"0 < set.@count");
    RLMAssertCount(IntegerSetPropertyObject, 1U, @"3 == set.@count");
    RLMAssertCount(IntegerSetPropertyObject, 1U, @"1 >  set.@count");

    RLMAssertCount(IntegerSetPropertyObject, 2U, @"set.@count == number");
    RLMAssertCount(IntegerSetPropertyObject, 1U, @"set.@count > number");
    RLMAssertCount(IntegerSetPropertyObject, 1U, @"number < set.@count");

    // We do not yet handle collection operations on both sides of the comparison.
    RLMAssertThrowsWithReasonMatching(([IntegerSetPropertyObject objectsWhere:@"set.@count == set.@count"]),
                                      @"aggregate operations cannot be compared with other aggregate operations");

    RLMAssertThrowsWithReasonMatching(([IntegerSetPropertyObject objectsWhere:@"set.@count.foo.bar != 0"]),
                                      @"single level key");
    RLMAssertThrowsWithReasonMatching(([IntegerSetPropertyObject objectsWhere:@"set.@count.intCol > 0"]),
                                      @"@count does not have any properties");
    RLMAssertThrowsWithReasonMatching(([IntegerSetPropertyObject objectsWhere:@"set.@count != 'Hello'"]),
                                      @"@count can only be compared with a numeric value");
}

- (void)testCountOnDictionaryCollection {
    RLMRealm *realm = [self realm];
    [realm beginWriteTransaction];

    IntegerDictionaryPropertyObject *idpo = [IntegerDictionaryPropertyObject createInRealm:realm withValue:@[ @1, @[]]];
    idpo.dictionary[@"456"] = [IntObject createInRealm:realm withValue:@[ @456 ]];

    idpo = [IntegerDictionaryPropertyObject createInRealm:realm withValue:@[ @2, @[]]];
    idpo.dictionary[@"1"] = [IntObject createInRealm:realm withValue:@[ @1 ]];
    idpo.dictionary[@"2"] = [IntObject createInRealm:realm withValue:@[ @2 ]];
    idpo.dictionary[@"3"] = [IntObject createInRealm:realm withValue:@[ @3 ]];

    idpo = [IntegerDictionaryPropertyObject createInRealm:realm withValue:@[ @0, @[]]];

    [realm commitWriteTransaction];

    RLMAssertCount(IntegerDictionaryPropertyObject, 2U, @"dictionary.@count > 0");
    RLMAssertCount(IntegerDictionaryPropertyObject, 1U, @"dictionary.@count == 3");
    RLMAssertCount(IntegerDictionaryPropertyObject, 1U, @"dictionary.@count < 1");
    RLMAssertCount(IntegerDictionaryPropertyObject, 2U, @"0 < dictionary.@count");
    RLMAssertCount(IntegerDictionaryPropertyObject, 1U, @"3 == dictionary.@count");
    RLMAssertCount(IntegerDictionaryPropertyObject, 1U, @"1 >  dictionary.@count");

    RLMAssertCount(IntegerDictionaryPropertyObject, 2U, @"dictionary.@count == number");
    RLMAssertCount(IntegerDictionaryPropertyObject, 1U, @"dictionary.@count > number");
    RLMAssertCount(IntegerDictionaryPropertyObject, 1U, @"number < dictionary.@count");

    // We do not yet handle collection operations on both sides of the comparison.
    RLMAssertThrowsWithReasonMatching(([IntegerDictionaryPropertyObject objectsWhere:@"dictionary.@count == dictionary.@count"]),
                                      @"aggregate operations cannot be compared with other aggregate operations");

    RLMAssertThrowsWithReasonMatching(([IntegerDictionaryPropertyObject objectsWhere:@"dictionary.@count.foo.bar != 0"]),
                                      @"single level key");
    RLMAssertThrowsWithReasonMatching(([IntegerDictionaryPropertyObject objectsWhere:@"dictionary.@count.intCol > 0"]),
                                      @"@count does not have any properties");
    RLMAssertThrowsWithReasonMatching(([IntegerDictionaryPropertyObject objectsWhere:@"dictionary.@count != 'Hello'"]),
                                      @"@count can only be compared with a numeric value");
}

- (void)testAggregateArrayCollectionOperators {
    RLMRealm *realm = [self realm];
    [realm beginWriteTransaction];

    IntegerArrayPropertyObject *arr = [IntegerArrayPropertyObject createInRealm:realm withValue:@[ @1111, @[] ]];
    [arr.array addObject:[IntObject createInRealm:realm withValue:@[ @1234 ]]];
    [arr.array addObject:[IntObject createInRealm:realm withValue:@[ @2 ]]];
    [arr.array addObject:[IntObject createInRealm:realm withValue:@[ @-12345 ]]];

    arr = [IntegerArrayPropertyObject createInRealm:realm withValue:@[ @2222, @[] ]];
    [arr.array addObject:[IntObject createInRealm:realm withValue:@[ @100 ]]];

    arr = [IntegerArrayPropertyObject createInRealm:realm withValue:@[ @3333, @[] ]];

    [realm commitWriteTransaction];

    RLMAssertCount(IntegerArrayPropertyObject, 1U, @"array.@min.intCol == -12345");
    RLMAssertCount(IntegerArrayPropertyObject, 1U, @"array.@min.intCol == 100");
    RLMAssertCount(IntegerArrayPropertyObject, 2U, @"array.@min.intCol < 1000");
    RLMAssertCount(IntegerArrayPropertyObject, 1U, @"array.@min.intCol > -1000");

    RLMAssertCount(IntegerArrayPropertyObject, 1U, @"array.@max.intCol == 1234");
    RLMAssertCount(IntegerArrayPropertyObject, 1U, @"array.@max.intCol == 100");
    RLMAssertCount(IntegerArrayPropertyObject, 2U, @"array.@max.intCol > -1000");
    RLMAssertCount(IntegerArrayPropertyObject, 1U, @"array.@max.intCol > 1000");

    RLMAssertCount(IntegerArrayPropertyObject, 1U, @"array.@sum.intCol == 100");
    RLMAssertCount(IntegerArrayPropertyObject, 1U, @"array.@sum.intCol == -11109");
    RLMAssertCount(IntegerArrayPropertyObject, 1U, @"array.@sum.intCol == 0");
    RLMAssertCount(IntegerArrayPropertyObject, 2U, @"array.@sum.intCol > -50");
    RLMAssertCount(IntegerArrayPropertyObject, 2U, @"array.@sum.intCol < 50");

    RLMAssertCount(IntegerArrayPropertyObject, 1U, @"array.@avg.intCol == 100");
    RLMAssertCount(IntegerArrayPropertyObject, 1U, @"array.@avg.intCol == -3703");
    RLMAssertCount(IntegerArrayPropertyObject, 0U, @"array.@avg.intCol == 0");
    RLMAssertCount(IntegerArrayPropertyObject, 1U, @"array.@avg.intCol < -50");
    RLMAssertCount(IntegerArrayPropertyObject, 1U, @"array.@avg.intCol > 50");

    RLMAssertCount(IntegerArrayPropertyObject, 2U, @"array.@min.intCol < number");
    RLMAssertCount(IntegerArrayPropertyObject, 2U, @"number > array.@min.intCol");

    RLMAssertCount(IntegerArrayPropertyObject, 1U, @"array.@max.intCol < number");
    RLMAssertCount(IntegerArrayPropertyObject, 1U, @"number > array.@max.intCol");

    RLMAssertCount(IntegerArrayPropertyObject, 2U, @"array.@avg.intCol < number");
    RLMAssertCount(IntegerArrayPropertyObject, 2U, @"number > array.@avg.intCol");

    // We do not yet handle collection operations on both sides of the comparison.
    RLMAssertThrowsWithReasonMatching(([IntegerArrayPropertyObject objectsWhere:@"array.@min.intCol == array.@min.intCol"]), @"aggregate operations cannot be compared with other aggregate operations");

    RLMAssertThrowsWithReasonMatching(([IntegerArrayPropertyObject objectsWhere:@"array.@min.intCol.foo.bar == 1.23"]), @"single level key");
    RLMAssertThrowsWithReasonMatching(([IntegerArrayPropertyObject objectsWhere:@"array.@max.intCol.foo.bar == 1.23"]), @"single level key");
    RLMAssertThrowsWithReasonMatching(([IntegerArrayPropertyObject objectsWhere:@"array.@sum.intCol.foo.bar == 1.23"]), @"single level key");
    RLMAssertThrowsWithReasonMatching(([IntegerArrayPropertyObject objectsWhere:@"array.@avg.intCol.foo.bar == 1.23"]), @"single level key");

    // Average is omitted from this test as its result is always a double.
    RLMAssertThrowsWithReasonMatching(([IntegerArrayPropertyObject objectsWhere:@"array.@min.intCol == 1.23"]), @"@min.*type int cannot be compared");
    RLMAssertThrowsWithReasonMatching(([IntegerArrayPropertyObject objectsWhere:@"array.@max.intCol == 1.23"]), @"@max.*type int cannot be compared");
    RLMAssertThrowsWithReasonMatching(([IntegerArrayPropertyObject objectsWhere:@"array.@sum.intCol == 1.23"]), @"@sum.*type int cannot be compared");
}

- (void)testAggregateSetCollectionOperators {
    RLMRealm *realm = [self realm];
    [realm beginWriteTransaction];

    IntegerSetPropertyObject *set = [IntegerSetPropertyObject createInRealm:realm withValue:@[ @1111, @[] ]];
    [set.set addObject:[IntObject createInRealm:realm withValue:@[ @1234 ]]];
    [set.set addObject:[IntObject createInRealm:realm withValue:@[ @2 ]]];
    [set.set addObject:[IntObject createInRealm:realm withValue:@[ @-12345 ]]];

    set = [IntegerSetPropertyObject createInRealm:realm withValue:@[ @2222, @[] ]];
    [set.set addObject:[IntObject createInRealm:realm withValue:@[ @100 ]]];

    set = [IntegerSetPropertyObject createInRealm:realm withValue:@[ @3333, @[] ]];

    [realm commitWriteTransaction];

    RLMAssertCount(IntegerSetPropertyObject, 1U, @"set.@min.intCol == -12345");
    RLMAssertCount(IntegerSetPropertyObject, 1U, @"set.@min.intCol == 100");
    RLMAssertCount(IntegerSetPropertyObject, 2U, @"set.@min.intCol < 1000");
    RLMAssertCount(IntegerSetPropertyObject, 1U, @"set.@min.intCol > -1000");

    RLMAssertCount(IntegerSetPropertyObject, 1U, @"set.@max.intCol == 1234");
    RLMAssertCount(IntegerSetPropertyObject, 1U, @"set.@max.intCol == 100");
    RLMAssertCount(IntegerSetPropertyObject, 2U, @"set.@max.intCol > -1000");
    RLMAssertCount(IntegerSetPropertyObject, 1U, @"set.@max.intCol > 1000");

    RLMAssertCount(IntegerSetPropertyObject, 1U, @"set.@sum.intCol == 100");
    RLMAssertCount(IntegerSetPropertyObject, 1U, @"set.@sum.intCol == -11109");
    RLMAssertCount(IntegerSetPropertyObject, 1U, @"set.@sum.intCol == 0");
    RLMAssertCount(IntegerSetPropertyObject, 2U, @"set.@sum.intCol > -50");
    RLMAssertCount(IntegerSetPropertyObject, 2U, @"set.@sum.intCol < 50");

    RLMAssertCount(IntegerSetPropertyObject, 1U, @"set.@avg.intCol == 100");
    RLMAssertCount(IntegerSetPropertyObject, 1U, @"set.@avg.intCol == -3703");
    RLMAssertCount(IntegerSetPropertyObject, 0U, @"set.@avg.intCol == 0");
    RLMAssertCount(IntegerSetPropertyObject, 1U, @"set.@avg.intCol < -50");
    RLMAssertCount(IntegerSetPropertyObject, 1U, @"set.@avg.intCol > 50");

    RLMAssertCount(IntegerSetPropertyObject, 2U, @"set.@min.intCol < number");
    RLMAssertCount(IntegerSetPropertyObject, 2U, @"number > set.@min.intCol");

    RLMAssertCount(IntegerSetPropertyObject, 1U, @"set.@max.intCol < number");
    RLMAssertCount(IntegerSetPropertyObject, 1U, @"number > set.@max.intCol");

    RLMAssertCount(IntegerSetPropertyObject, 2U, @"set.@avg.intCol < number");
    RLMAssertCount(IntegerSetPropertyObject, 2U, @"number > set.@avg.intCol");

    // We do not yet handle collection operations on both sides of the comparison.
    RLMAssertThrowsWithReasonMatching(([IntegerSetPropertyObject objectsWhere:@"set.@min.intCol == set.@min.intCol"]), @"aggregate operations cannot be compared with other aggregate operations");

    RLMAssertThrowsWithReasonMatching(([IntegerSetPropertyObject objectsWhere:@"set.@min.intCol.foo.bar == 1.23"]), @"single level key");
    RLMAssertThrowsWithReasonMatching(([IntegerSetPropertyObject objectsWhere:@"set.@max.intCol.foo.bar == 1.23"]), @"single level key");
    RLMAssertThrowsWithReasonMatching(([IntegerSetPropertyObject objectsWhere:@"set.@sum.intCol.foo.bar == 1.23"]), @"single level key");
    RLMAssertThrowsWithReasonMatching(([IntegerSetPropertyObject objectsWhere:@"set.@avg.intCol.foo.bar == 1.23"]), @"single level key");

    // Average is omitted from this test as its result is always a double.
    RLMAssertThrowsWithReasonMatching(([IntegerSetPropertyObject objectsWhere:@"set.@min.intCol == 1.23"]), @"@min.*type int cannot be compared");
    RLMAssertThrowsWithReasonMatching(([IntegerSetPropertyObject objectsWhere:@"set.@max.intCol == 1.23"]), @"@max.*type int cannot be compared");
    RLMAssertThrowsWithReasonMatching(([IntegerSetPropertyObject objectsWhere:@"set.@sum.intCol == 1.23"]), @"@sum.*type int cannot be compared");
}

- (void)testAggregateDictionaryCollectionOperators {
    RLMRealm *realm = [self realm];
    [realm beginWriteTransaction];

    IntegerDictionaryPropertyObject *idpo = [IntegerDictionaryPropertyObject createInRealm:realm withValue:@[ @1111, @[] ]];
    idpo.dictionary[@"0"] = [IntObject createInRealm:realm withValue:@[ @1234 ]];
    idpo.dictionary[@"1"] = [IntObject createInRealm:realm withValue:@[ @2 ]];
    idpo.dictionary[@"2"] = [IntObject createInRealm:realm withValue:@[ @-12345 ]];

    idpo = [IntegerDictionaryPropertyObject createInRealm:realm withValue:@[ @2222, @[] ]];
    idpo.dictionary[@"3"] = [IntObject createInRealm:realm withValue:@[ @100 ]];

    idpo = [IntegerDictionaryPropertyObject createInRealm:realm withValue:@[ @3333, @[] ]];

    [realm commitWriteTransaction];

    RLMAssertCount(IntegerDictionaryPropertyObject, 1U, @"dictionary.@min.intCol == -12345");
    RLMAssertCount(IntegerDictionaryPropertyObject, 1U, @"dictionary.@min.intCol == 100");
    RLMAssertCount(IntegerDictionaryPropertyObject, 2U, @"dictionary.@min.intCol < 1000");
    RLMAssertCount(IntegerDictionaryPropertyObject, 1U, @"dictionary.@min.intCol > -1000");

    RLMAssertCount(IntegerDictionaryPropertyObject, 1U, @"dictionary.@max.intCol == 1234");
    RLMAssertCount(IntegerDictionaryPropertyObject, 1U, @"dictionary.@max.intCol == 100");
    RLMAssertCount(IntegerDictionaryPropertyObject, 2U, @"dictionary.@max.intCol > -1000");
    RLMAssertCount(IntegerDictionaryPropertyObject, 1U, @"dictionary.@max.intCol > 1000");

    RLMAssertCount(IntegerDictionaryPropertyObject, 1U, @"dictionary.@sum.intCol == 100");
    RLMAssertCount(IntegerDictionaryPropertyObject, 1U, @"dictionary.@sum.intCol == -11109");
    RLMAssertCount(IntegerDictionaryPropertyObject, 1U, @"dictionary.@sum.intCol == 0");
    RLMAssertCount(IntegerDictionaryPropertyObject, 2U, @"dictionary.@sum.intCol > -50");
    RLMAssertCount(IntegerDictionaryPropertyObject, 2U, @"dictionary.@sum.intCol < 50");

    RLMAssertCount(IntegerDictionaryPropertyObject, 1U, @"dictionary.@avg.intCol == 100");
    RLMAssertCount(IntegerDictionaryPropertyObject, 1U, @"dictionary.@avg.intCol == -3703");
    RLMAssertCount(IntegerDictionaryPropertyObject, 0U, @"dictionary.@avg.intCol == 0");
    RLMAssertCount(IntegerDictionaryPropertyObject, 1U, @"dictionary.@avg.intCol < -50");
    RLMAssertCount(IntegerDictionaryPropertyObject, 1U, @"dictionary.@avg.intCol > 50");

    RLMAssertCount(IntegerDictionaryPropertyObject, 2U, @"dictionary.@min.intCol < number");
    RLMAssertCount(IntegerDictionaryPropertyObject, 2U, @"number > dictionary.@min.intCol");

    RLMAssertCount(IntegerDictionaryPropertyObject, 1U, @"dictionary.@max.intCol < number");
    RLMAssertCount(IntegerDictionaryPropertyObject, 1U, @"number > dictionary.@max.intCol");

    RLMAssertCount(IntegerDictionaryPropertyObject, 2U, @"dictionary.@avg.intCol < number");
    RLMAssertCount(IntegerDictionaryPropertyObject, 2U, @"number > dictionary.@avg.intCol");

    // We do not yet handle collection operations on both sides of the comparison.
    RLMAssertThrowsWithReasonMatching(([IntegerDictionaryPropertyObject objectsWhere:@"dictionary.@min.intCol == dictionary.@min.intCol"]), @"aggregate operations cannot be compared with other aggregate operations");

    RLMAssertThrowsWithReasonMatching(([IntegerDictionaryPropertyObject objectsWhere:@"dictionary.@min.intCol.foo.bar == 1.23"]), @"single level key");
    RLMAssertThrowsWithReasonMatching(([IntegerDictionaryPropertyObject objectsWhere:@"dictionary.@max.intCol.foo.bar == 1.23"]), @"single level key");
    RLMAssertThrowsWithReasonMatching(([IntegerDictionaryPropertyObject objectsWhere:@"dictionary.@sum.intCol.foo.bar == 1.23"]), @"single level key");
    RLMAssertThrowsWithReasonMatching(([IntegerDictionaryPropertyObject objectsWhere:@"dictionary.@avg.intCol.foo.bar == 1.23"]), @"single level key");

    // Average is omitted from this test as its result is always a double.
    RLMAssertThrowsWithReasonMatching(([IntegerDictionaryPropertyObject objectsWhere:@"dictionary.@min.intCol == 1.23"]), @"@min.*type int cannot be compared");
    RLMAssertThrowsWithReasonMatching(([IntegerDictionaryPropertyObject objectsWhere:@"dictionary.@max.intCol == 1.23"]), @"@max.*type int cannot be compared");
    RLMAssertThrowsWithReasonMatching(([IntegerDictionaryPropertyObject objectsWhere:@"dictionary.@sum.intCol == 1.23"]), @"@sum.*type int cannot be compared");
}

- (void)testDictionaryQueryAllKeys {
    void (^test)(NSString *, id) = ^(NSString *property, id value) {
        RLMRealm *realm = [self realm];
        [realm beginWriteTransaction];
        [AllDictionariesObject createInRealm:realm withValue:@{property: @{@"key1": value}}];
        [AllDictionariesObject createInRealm:realm withValue:@{property: @{@"key2": value}}];
        [AllDictionariesObject createInRealm:realm withValue:@{property: @{@"key3": value}}];
        [AllDictionariesObject createInRealm:realm withValue:@{property: @{@"key1": value}}];
        [AllDictionariesObject createInRealm:realm withValue:@{property: @{@"KEY3": value}}];
        [AllDictionariesObject createInRealm:realm withValue:@{property: @{@"kêÿ2": value}}];
        [AllDictionariesObject createInRealm:realm withValue:@{property: @{@"KEY2": value}}];
        [AllDictionariesObject createInRealm:realm withValue:@{property: @{@"lock1": value}}];
        [realm commitWriteTransaction];

        RLMAssertCount(AllDictionariesObject, 0U, [NSString stringWithFormat:@"%@.@allKeys = 'key'", property]);
        RLMAssertCount(AllDictionariesObject, 2U, [NSString stringWithFormat:@"%@.@allKeys = 'key1'", property]);
        RLMAssertCount(AllDictionariesObject, 1U, [NSString stringWithFormat:@"ANY %@.@allKeys = 'key3'", property]);
        RLMAssertCount(AllDictionariesObject, 7U, [NSString stringWithFormat:@"ANY %@.@allKeys != 'key3'", property]);
        RLMAssertCount(AllDictionariesObject, 2U, [NSString stringWithFormat:@"ANY %@.@allKeys =[c] 'key3'", property]);
        RLMAssertCount(AllDictionariesObject, 6U, [NSString stringWithFormat:@"ANY %@.@allKeys !=[c] 'key3'", property]);
        RLMAssertCount(AllDictionariesObject, 2U, [NSString stringWithFormat:@"ANY %@.@allKeys =[cd] 'key3'", property]);
        RLMAssertCount(AllDictionariesObject, 6U, [NSString stringWithFormat:@"ANY %@.@allKeys !=[cd] 'key3'", property]);
        RLMAssertCount(AllDictionariesObject, 2U, [NSString stringWithFormat:@"NOT %@.@allKeys !=[cd] 'key3'", property]);
        // BEGINSWITH
        RLMAssertCount(AllDictionariesObject, 4U, [NSString stringWithFormat:@"%@.@allKeys BEGINSWITH 'ke'", property]);
        RLMAssertCount(AllDictionariesObject, 4U, [NSString stringWithFormat:@"NOT %@.@allKeys BEGINSWITH 'ke'", property]);
        RLMAssertCount(AllDictionariesObject, 6U, [NSString stringWithFormat:@"%@.@allKeys BEGINSWITH[c] 'ke'", property]);
        RLMAssertCount(AllDictionariesObject, 7U, [NSString stringWithFormat:@"%@.@allKeys BEGINSWITH[cd] 'ke'", property]);
        RLMAssertCount(AllDictionariesObject, 0U, [NSString stringWithFormat:@"%@.@allKeys BEGINSWITH NULL", property]);
        // CONTAINS
        RLMAssertCount(AllDictionariesObject, 4U, [NSString stringWithFormat:@"%@.@allKeys CONTAINS 'ey'", property]);
        RLMAssertCount(AllDictionariesObject, 6U, [NSString stringWithFormat:@"%@.@allKeys CONTAINS[c] 'ey'", property]);
        RLMAssertCount(AllDictionariesObject, 7U, [NSString stringWithFormat:@"%@.@allKeys CONTAINS[cd] 'ey'", property]);
        RLMAssertCount(AllDictionariesObject, 0U, [NSString stringWithFormat:@"%@.@allKeys CONTAINS NULL", property]);
        // ENDSWITH
        RLMAssertCount(AllDictionariesObject, 1U, [NSString stringWithFormat:@"%@.@allKeys ENDSWITH 'y2'", property]);
        RLMAssertCount(AllDictionariesObject, 2U, [NSString stringWithFormat:@"%@.@allKeys ENDSWITH[c] 'y2'", property]);
        RLMAssertCount(AllDictionariesObject, 3U, [NSString stringWithFormat:@"%@.@allKeys ENDSWITH[cd] 'y2'", property]);
        RLMAssertCount(AllDictionariesObject, 0U, [NSString stringWithFormat:@"%@.@allKeys ENDSWITH NULL", property]);
        // LIKE
        RLMAssertCount(AllDictionariesObject, 4U, [NSString stringWithFormat:@"%@.@allKeys LIKE 'key*'", property]);
        RLMAssertCount(AllDictionariesObject, 6U, [NSString stringWithFormat:@"%@.@allKeys LIKE[c] 'key*'", property]);
        RLMAssertCount(AllDictionariesObject, 0U, [NSString stringWithFormat:@"%@.@allKeys LIKE NULL", property]);
        RLMAssertCount(AllDictionariesObject, 4U, [NSString stringWithFormat:@"NOT %@.@allKeys LIKE 'key*'", property]);
        RLMAssertCount(AllDictionariesObject, 2U, [NSString stringWithFormat:@"NOT %@.@allKeys LIKE[c] 'key*'", property]);
        RLMAssertCount(AllDictionariesObject, 8U, [NSString stringWithFormat:@"NOT %@.@allKeys LIKE NULL", property]);
        RLMAssertThrowsWithReasonMatching(([realm objects:@"AllDictionariesObject" where:[NSString stringWithFormat:@"%@.@allKeys LIKE[cd] 'key*'", property]]), @"not supported");
        
        [realm beginWriteTransaction];
        [realm deleteAllObjects];
        [realm commitWriteTransaction];
    };
    test(@"intDict", @123);
    test(@"floatDict", @789.123);
    test(@"doubleDict", @789.123);
    test(@"boolDict", @YES);
    test(@"stringDict", @"Hello");
    test(@"dataDict", [@"123" dataUsingEncoding:NSUTF8StringEncoding]);
    test(@"dateDict", [NSDate dateWithTimeIntervalSince1970:100]);
    test(@"decimalDict", [RLMDecimal128 decimalWithNumber:@123.456]);
    test(@"objectIdDict", [RLMObjectId objectId]);
    test(@"uuidDict", [[NSUUID alloc] initWithUUIDString:@"00000000-0000-0000-0000-000000000000"]);
    test(@"stringObjDict", [[StringObject alloc] initWithValue:@[@"hi"]]);
}

- (void)testDictionaryQueryAllValues_RLMObject {
    void (^testObject)(NSString *, NSArray *) = ^(NSString *property, NSArray *values) {
        RLMRealm *realm = [self realm];
        [realm beginWriteTransaction];
        [AllDictionariesObject createInRealm:realm withValue:@{property: @{@"aKey": values[0]}}];
        [AllDictionariesObject createInRealm:realm withValue:@{property: @{@"aKey2": values[1]}}];
        [AllDictionariesObject createInRealm:realm withValue:@{property: @{@"aKey3": values[2]}}];
        [realm commitWriteTransaction];

        StringObject *obj = [[StringObject objectsInRealm:realm where:@"stringCol = %@", [values[0] stringCol]] firstObject];
        RLMAssertCount(AllDictionariesObject, 1U, @"ANY %K.@allValues = %@", property, obj);
        RLMAssertCount(AllDictionariesObject, 2U, @"ANY %K.@allValues != %@", property, obj);

        RLMAssertThrowsWithReasonMatching(([realm objects:@"AllDictionariesObject" where:[NSString stringWithFormat:@"%@.@allValues IN %@", property, @[obj]]]), @"not supported");
        RLMAssertThrowsWithReasonMatching(([realm objects:@"AllDictionariesObject" where:[NSString stringWithFormat:@"%@.@allValues BETWEEN %@", property, @[obj]]]), @"not supported");
        RLMAssertThrowsWithReasonMatching(([realm objects:@"AllDictionariesObject" where:[NSString stringWithFormat:@"%@.@allValues BEGINSWITH 'he'", property]]), @"not supported");
        RLMAssertThrowsWithReasonMatching(([realm objects:@"AllDictionariesObject" where:[NSString stringWithFormat:@"%@.@allValues CONTAINS 'el'", property]]), @"not supported");
        RLMAssertThrowsWithReasonMatching(([realm objects:@"AllDictionariesObject" where:[NSString stringWithFormat:@"%@.@allValues ENDSWITH 'lo'", property]]), @"not supported");
        RLMAssertThrowsWithReasonMatching(([realm objects:@"AllDictionariesObject" where:[NSString stringWithFormat:@"%@.@allValues LIKE 'hel*'", property]]), @"not supported");
        [realm beginWriteTransaction];
        [realm deleteAllObjects];
        [realm commitWriteTransaction];
    };

    testObject(@"stringObjDict", @[[[StringObject alloc] initWithValue:@[@"hello"]],
                                   [[StringObject alloc] initWithValue:@[@"Héllo"]],
                                   [[StringObject alloc] initWithValue:@[@"HELLO"]]]);
}

- (void)testDictionaryQueryAllValues_NSString {
    void (^test)(NSString *, NSArray *) = ^(NSString *property, NSArray *values) {
        RLMRealm *realm = [self realm];
        [realm beginWriteTransaction];
        [AllDictionariesObject createInRealm:realm withValue:@{property: @{@"aKey": values[0]}}];
        [AllDictionariesObject createInRealm:realm withValue:@{property: @{@"aKey2": values[1]}}];
        [AllDictionariesObject createInRealm:realm withValue:@{property: @{@"aKey3": values[2]}}];
        [realm commitWriteTransaction];

        RLMAssertCount(AllDictionariesObject, 1U, @"ANY %K.@allValues = %@", property, values[0]);
        RLMAssertCount(AllDictionariesObject, 2U, @"ANY %K.@allValues != %@", property, values[0]);
        RLMAssertCount(AllDictionariesObject, 2U, @"ANY %K.@allValues =[c] %@", property, values[0]);
        RLMAssertCount(AllDictionariesObject, 1U, @"ANY %K.@allValues !=[c] %@", property, values[0]);
        RLMAssertCount(AllDictionariesObject, 3U, @"ANY %K.@allValues =[cd] %@", property, values[0]);
        RLMAssertCount(AllDictionariesObject, 0U, @"ANY %K.@allValues !=[cd] %@", property, values[0]);
        // BEGINSWITH
        RLMAssertCount(AllDictionariesObject, 1U, @"%K.@allValues BEGINSWITH 'he'", property);
        RLMAssertCount(AllDictionariesObject, 2U, @"NOT %K.@allValues BEGINSWITH 'he'", property);
        RLMAssertCount(AllDictionariesObject, 2U, @"%K.@allValues BEGINSWITH[c] 'he'", property);
        RLMAssertCount(AllDictionariesObject, 3U, @"%K.@allValues BEGINSWITH[cd] 'he'", property);
        RLMAssertCount(AllDictionariesObject, 0U, @"%K.@allValues BEGINSWITH NULL", property);
        // CONTAINS
        RLMAssertCount(AllDictionariesObject, 1U, @"%K.@allValues CONTAINS 'el'", property);
        RLMAssertCount(AllDictionariesObject, 2U, @"%K.@allValues CONTAINS[c] 'el'", property);
        RLMAssertCount(AllDictionariesObject, 3U, @"%K.@allValues CONTAINS[cd] 'el'", property);
        RLMAssertCount(AllDictionariesObject, 0U, @"%K.@allValues CONTAINS NULL", property);
        // ENDSWITH
        RLMAssertCount(AllDictionariesObject, 2U, @"%K.@allValues ENDSWITH 'lo'", property);
        RLMAssertCount(AllDictionariesObject, 3U, @"%K.@allValues ENDSWITH[c] 'lo'", property);
        RLMAssertCount(AllDictionariesObject, 3U, @"%K.@allValues ENDSWITH[cd] 'lo'", property);
        RLMAssertCount(AllDictionariesObject, 0U, @"%K.@allValues ENDSWITH NULL", property);
        // LIKE
        RLMAssertCount(AllDictionariesObject, 1U, @"%K.@allValues LIKE 'hel*'", property);
        RLMAssertCount(AllDictionariesObject, 2U, @"%K.@allValues LIKE[c] 'hel*'", property);
        RLMAssertCount(AllDictionariesObject, 0U, @"%K.@allValues LIKE NULL", property);
        RLMAssertCount(AllDictionariesObject, 2U, @"NOT %K.@allValues LIKE 'hel*'", property);
        RLMAssertCount(AllDictionariesObject, 1U, @"NOT %K.@allValues LIKE[c] 'hel*'", property);
        RLMAssertCount(AllDictionariesObject, 3U, @"NOT %K.@allValues LIKE NULL", property);
        RLMAssertThrowsWithReasonMatching(([realm objects:@"AllDictionariesObject" where:@"%K.@allValues LIKE[cd] 'hel*'", property]), @"not supported");

        [realm beginWriteTransaction];
        [realm deleteAllObjects];
        [realm commitWriteTransaction];
    };
    test(@"stringDict", @[@"hello", @"Héllo", @"HELLO"]);
}

- (void)testDictionaryQueryAllValues_ObjectId {
    void (^test)(NSString *, NSArray *) = ^(NSString *property, NSArray *values) {
        RLMRealm *realm = [self realm];
        [realm beginWriteTransaction];
        [AllDictionariesObject createInRealm:realm withValue:@{property: @{@"aKey": values[0]}}];
        [AllDictionariesObject createInRealm:realm withValue:@{property: @{@"aKey2": values[1]}}];
        [AllDictionariesObject createInRealm:realm withValue:@{property: @{@"aKey3": values[2]}}];
        [realm commitWriteTransaction];

        RLMAssertCount(AllDictionariesObject, 1U, @"%K.@allValues = %@", property, values[0]);
        RLMAssertCount(AllDictionariesObject, 2U, @"%K.@allValues != %@", property, values[0]);
        RLMAssertCount(AllDictionariesObject, 1U, @"%K.@allValues =[c] %@", property, values[0]);
        RLMAssertCount(AllDictionariesObject, 1U, @"%K.@allValues =[cd] %@", property, values[0]);
        // Unsupported
        RLMAssertThrowsWithReasonMatching(([realm objects:@"AllDictionariesObject" where:@"%K.@allValues LIKE '*a'", property]), @"not supported");
        RLMAssertThrowsWithReasonMatching(([realm objects:@"AllDictionariesObject" where:@"%K.@allValues BEGINSWITH 'a'", property]), @"not supported");
        RLMAssertThrowsWithReasonMatching(([realm objects:@"AllDictionariesObject" where:@"%K.@allValues CONTAINS 'a'", property]), @"not supported");
        RLMAssertThrowsWithReasonMatching(([realm objects:@"AllDictionariesObject" where:@"%K.@allValues ENDSWITH 'a'", property]), @"not supported");
        RLMAssertThrowsWithReasonMatching(([realm objects:@"AllDictionariesObject" where:@"%K.@allValues < %@", property, values[0]]), @"not supported");
        RLMAssertThrowsWithReasonMatching(([realm objects:@"AllDictionariesObject" where:@"%K.@allValues > %@", property, values[0]]), @"not supported");

        [realm beginWriteTransaction];
        [realm deleteAllObjects];
        [realm commitWriteTransaction];
    };

    test(@"objectIdDict", @[[[RLMObjectId alloc] initWithString:@"60425fff91d7a195d5ddac1b" error:nil],
                            [[RLMObjectId alloc] initWithString:@"60425fff91d7a195d5ddac1a" error:nil],
                            [[RLMObjectId alloc] initWithString:@"60425fff91d7a195d5ddac1c" error:nil]]);
}

- (void)testDictionaryQueryAllValues_UUID {
    void (^test)(NSString *, NSArray *) = ^(NSString *property, NSArray *values) {
        RLMRealm *realm = [self realm];
        [realm beginWriteTransaction];
        [AllDictionariesObject createInRealm:realm withValue:@{property: @{@"aKey": values[0]}}];
        [AllDictionariesObject createInRealm:realm withValue:@{property: @{@"aKey2": values[1]}}];
        [AllDictionariesObject createInRealm:realm withValue:@{property: @{@"aKey3": values[2]}}];
        [realm commitWriteTransaction];

        RLMAssertCount(AllDictionariesObject, 1U, @"ANY %K.@allValues = %@", property, values[0]);
        RLMAssertCount(AllDictionariesObject, 1U, @"%K.@allValues = %@", property, values[0]);
        RLMAssertCount(AllDictionariesObject, 2U, @"ANY %K.@allValues != %@", property, values[0]);
        RLMAssertCount(AllDictionariesObject, 1U, @"ANY %K.@allValues =[c] %@", property, values[0]);
        RLMAssertCount(AllDictionariesObject, 2U, @"ANY %K.@allValues !=[c] %@", property, values[0]);
        RLMAssertCount(AllDictionariesObject, 2U, @"%K.@allValues !=[c] %@", property, values[0]);
        RLMAssertCount(AllDictionariesObject, 1U, @"ANY %K.@allValues =[cd] %@", property, values[0]);
        RLMAssertCount(AllDictionariesObject, 2U, @"ANY %K.@allValues !=[cd] %@", property, values[0]);

        // Unsupported
        RLMAssertThrowsWithReasonMatching(([realm objects:@"AllDictionariesObject" where:@"ANY %K.@allValues > %@", property, values[0]]), @"not supported");
        RLMAssertThrowsWithReasonMatching(([realm objects:@"AllDictionariesObject" where:@"ANY %K.@allValues < %@", property, values[0]]), @"not supported");
        RLMAssertThrowsWithReasonMatching(([realm objects:@"AllDictionariesObject" where:@"%K.@allValues LIKE %@", property, values[0]]), @"not supported");
        RLMAssertThrowsWithReasonMatching(([realm objects:@"AllDictionariesObject" where:@"%K.@allValues BEGINSWITH %@", property, values[0]]), @"not supported");
        RLMAssertThrowsWithReasonMatching(([realm objects:@"AllDictionariesObject" where:@"%K.@allValues CONTAINS %@", property, values[0]]), @"not supported");
        RLMAssertThrowsWithReasonMatching(([realm objects:@"AllDictionariesObject" where:@"%K.@allValues ENDSWITH %@", property, values[0]]), @"not supported");

        [realm beginWriteTransaction];
        [realm deleteAllObjects];
        [realm commitWriteTransaction];
    };
    test(@"uuidDict", @[[[NSUUID alloc] initWithUUIDString:@"137DECC8-B300-4954-A233-F89909F4FD88"],
                        [[NSUUID alloc] initWithUUIDString:@"137DECC8-B300-4954-A233-F89909F4FD87"],
                        [[NSUUID alloc] initWithUUIDString:@"137DECC8-B300-4954-A233-F89909F4FD89"]]);
}

- (void)testDictionaryQueryAllValues_Data {
    void (^test)(NSString *, NSArray *) = ^(NSString *property, NSArray *values) {
        RLMRealm *realm = [self realm];
        [realm beginWriteTransaction];
        [AllDictionariesObject createInRealm:realm withValue:@{property: @{@"aKey": values[0]}}];
        [AllDictionariesObject createInRealm:realm withValue:@{property: @{@"aKey2": values[1]}}];
        [AllDictionariesObject createInRealm:realm withValue:@{property: @{@"aKey3": values[2]}}];
        [realm commitWriteTransaction];

        RLMAssertCount(AllDictionariesObject, 1U, @"ANY %K.@allValues = %@", property, values[0]);
        RLMAssertCount(AllDictionariesObject, 1U, @"%K.@allValues = %@", property, values[0]);
        RLMAssertCount(AllDictionariesObject, 2U, @"ANY %K.@allValues != %@", property, values[0]);
        RLMAssertCount(AllDictionariesObject, 1U, @"ANY %K.@allValues =[c] %@", property, values[0]);
        RLMAssertCount(AllDictionariesObject, 2U, @"ANY %K.@allValues !=[c] %@", property, values[0]);
        RLMAssertCount(AllDictionariesObject, 2U, @"%K.@allValues !=[c] %@", property, values[0]);
        RLMAssertCount(AllDictionariesObject, 1U, @"ANY %K.@allValues =[cd] %@", property, values[0]);
        RLMAssertCount(AllDictionariesObject, 2U, @"ANY %K.@allValues !=[cd] %@", property, values[0]);
        
        RLMAssertCount(AllDictionariesObject, 1U, @"%K.@allValues LIKE %@", property, [NSData dataWithBytes:"hello" length:5]);
        RLMAssertCount(AllDictionariesObject, 2U, @"%K.@allValues LIKE %@", property, [NSData dataWithBytes:"he*" length:3]);
        RLMAssertCount(AllDictionariesObject, 2U, @"%K.@allValues BEGINSWITH %@", property, [NSData dataWithBytes:"he" length:2]);
        RLMAssertCount(AllDictionariesObject, 1U, @"%K.@allValues CONTAINS %@", property, [NSData dataWithBytes:"ell" length:3]);
        RLMAssertCount(AllDictionariesObject, 1U, @"%K.@allValues ENDSWITH %@", property, [NSData dataWithBytes:"lo" length:2]);

        // Unsupported
        RLMAssertThrowsWithReasonMatching(([realm objects:@"AllDictionariesObject" where:@"ANY %K.@allValues > %@", property, values[0]]), @"not supported");
        RLMAssertThrowsWithReasonMatching(([realm objects:@"AllDictionariesObject" where:@"ANY %K.@allValues < %@", property, values[0]]), @"not supported");

        [realm beginWriteTransaction];
        [realm deleteAllObjects];
        [realm commitWriteTransaction];
    };
    test(@"dataDict", @[[NSData dataWithBytes:"hey" length:3],
                        [NSData dataWithBytes:"hi" length:2],
                        [NSData dataWithBytes:"hello" length:5]]);
}

- (void)testDictionaryQueryAllValues {
    void (^test)(NSString *, NSArray *) = ^(NSString *property, NSArray *values) {
        RLMRealm *realm = [self realm];
        [realm beginWriteTransaction];
        [AllDictionariesObject createInRealm:realm withValue:@{property: @{@"aKey": values[0]}}];
        [AllDictionariesObject createInRealm:realm withValue:@{property: @{@"aKey2": values[1]}}];
        [AllDictionariesObject createInRealm:realm withValue:@{property: @{@"aKey3": values[2]}}];
        [realm commitWriteTransaction];

        if ([property isEqualToString:@"boolDict"]) {
            RLMAssertCount(AllDictionariesObject, 2U, @"ANY %K.@allValues = %@", property, values[0]);
            RLMAssertCount(AllDictionariesObject, 1U, @"ANY %K.@allValues != %@", property, values[0]);
            RLMAssertCount(AllDictionariesObject, 2U, @"ANY %K.@allValues =[c] %@", property, values[0]);
            RLMAssertCount(AllDictionariesObject, 1U, @"ANY %K.@allValues !=[c] %@", property, values[0]);
            RLMAssertCount(AllDictionariesObject, 2U, @"ANY %K.@allValues =[cd] %@", property, values[0]);
            RLMAssertCount(AllDictionariesObject, 1U, @"ANY %K.@allValues !=[cd] %@", property, values[0]);
            // Unsupported
            RLMAssertThrowsWithReasonMatching(([realm objects:@"AllDictionariesObject" where:@"ANY %K.@allValues > %@", property, values[0]]), @"not supported");
            RLMAssertThrowsWithReasonMatching(([realm objects:@"AllDictionariesObject" where:@"ANY %K.@allValues < %@", property, values[0]]), @"not supported");
            RLMAssertThrowsWithReasonMatching(([realm objects:@"AllDictionariesObject" where:@"%K.@allValues BEGINSWITH 1", property]), @"not supported");
            RLMAssertThrowsWithReasonMatching(([realm objects:@"AllDictionariesObject" where:@"%K.@allValues CONTAINS 1", property]), @"not supported");
            RLMAssertThrowsWithReasonMatching(([realm objects:@"AllDictionariesObject" where:@"%K.@allValues ENDSWITH 1", property]), @"not supported");
            RLMAssertThrowsWithReasonMatching(([realm objects:@"AllDictionariesObject" where:@"%K.@allValues LIKE 'key*'", property]), @"not supported");
        } else {
            RLMAssertCount(AllDictionariesObject, 1U, @"ANY %K.@allValues = %@", property, values[0]);
            RLMAssertCount(AllDictionariesObject, 1U, @"%K.@allValues = %@", property, values[0]);
            RLMAssertCount(AllDictionariesObject, 2U, @"ANY %K.@allValues != %@", property, values[0]);
            RLMAssertCount(AllDictionariesObject, 1U, @"ANY %K.@allValues =[c] %@", property, values[0]);
            RLMAssertCount(AllDictionariesObject, 2U, @"ANY %K.@allValues !=[c] %@", property, values[0]);
            RLMAssertCount(AllDictionariesObject, 2U, @"%K.@allValues !=[c] %@", property, values[0]);
            RLMAssertCount(AllDictionariesObject, 1U, @"ANY %K.@allValues =[cd] %@", property, values[0]);
            RLMAssertCount(AllDictionariesObject, 2U, @"ANY %K.@allValues !=[cd] %@", property, values[0]);

            RLMAssertCount(AllDictionariesObject, 1U, @"ANY %K.@allValues > %@", property, values[0]);
            RLMAssertCount(AllDictionariesObject, 1U, @"%K.@allValues > %@", property, values[0]);
            RLMAssertCount(AllDictionariesObject, 2U, @"NOT ANY %K.@allValues > %@", property, values[0]);
            RLMAssertCount(AllDictionariesObject, 2U, @"NOT %K.@allValues > %@", property, values[0]);
            RLMAssertCount(AllDictionariesObject, 1U, @"ANY %K.@allValues >[c] %@", property, values[0]);
            RLMAssertCount(AllDictionariesObject, 1U, @"ANY %K.@allValues >[cd] %@", property, values[0]);

            RLMAssertCount(AllDictionariesObject, 1U, @"ANY %K.@allValues < %@", property, values[0]);
            RLMAssertCount(AllDictionariesObject, 1U, @"%K.@allValues < %@", property, values[0]);
            RLMAssertCount(AllDictionariesObject, 2U, @"NOT ANY %K.@allValues < %@", property, values[0]);
            RLMAssertCount(AllDictionariesObject, 2U, @"NOT %K.@allValues < %@", property, values[0]);
            RLMAssertCount(AllDictionariesObject, 1U, @"ANY %K.@allValues <[c] %@", property, values[0]);
            RLMAssertCount(AllDictionariesObject, 1U, @"ANY %K.@allValues <[cd] %@", property, values[0]);

            // Unsupported
            RLMAssertThrowsWithReasonMatching(([realm objects:@"AllDictionariesObject" where:@"%K.@allValues LIKE '*1'", property]), @"not supported");
            RLMAssertThrowsWithReasonMatching(([realm objects:@"AllDictionariesObject" where:@"%K.@allValues BEGINSWITH 1", property]), @"not supported");
            RLMAssertThrowsWithReasonMatching(([realm objects:@"AllDictionariesObject" where:@"%K.@allValues CONTAINS 1", property]), @"not supported");
            RLMAssertThrowsWithReasonMatching(([realm objects:@"AllDictionariesObject" where:@"%K.@allValues ENDSWITH 1", property]), @"not supported");
        }
        [realm beginWriteTransaction];
        [realm deleteAllObjects];
        [realm commitWriteTransaction];
    };
    test(@"intDict", @[@456, @123, @789]);
    test(@"doubleDict", @[@456.123, @123.123, @789.123]);
    test(@"boolDict", @[@NO, @NO, @YES]);
    test(@"decimalDict", @[[RLMDecimal128 decimalWithNumber:@456.123], [RLMDecimal128 decimalWithNumber:@123.123], [RLMDecimal128 decimalWithNumber:@789.123]]);
    test(@"dateDict", @[[NSDate dateWithTimeIntervalSince1970:4000], [NSDate dateWithTimeIntervalSince1970:2000], [NSDate dateWithTimeIntervalSince1970:8000]]);
}

- (void)testCollectionsQueryAllValuesAllKeys {
    RLMRealm *realm = [self realm];
    [realm beginWriteTransaction];
    StringObject *so1 = [StringObject createInRealm:realm withValue:@[@"value1"]];
    RLMAssertThrowsWithReasonMatching(([realm objects:@"ArrayPropertyObject" where:@"ANY array.@allValues = %@", so1]), @"@allValues is only valid for dictionary");
    RLMAssertThrowsWithReasonMatching(([realm objects:@"ArrayPropertyObject" where:@"ANY array.@allKeys = %@", so1]), @"@allKeys is only valid for dictionary");
    RLMAssertThrowsWithReasonMatching(([realm objects:@"SetPropertyObject" where:@"ANY set.@allValues = %@", so1]), @"@allValues is only valid for dictionary");
    RLMAssertThrowsWithReasonMatching(([realm objects:@"SetPropertyObject" where:@"ANY set.@allKeys = %@", so1]), @"@allKeys is only valid for dictionary");
    [realm cancelWriteTransaction];
}

@end

@interface NullQueryTests : QueryTests
@end

@implementation NullQueryTests
- (Class)queryObjectClass {
    return [NullQueryObject class];
}

- (void)testQueryOnNullableStringColumn {
    void (^testWithStringClass)(Class) = ^(Class stringObjectClass) {
        RLMRealm *realm = [self realm];
        [realm transactionWithBlock:^{
            [stringObjectClass createInRealm:realm withValue:@[@"a"]];
            [stringObjectClass createInRealm:realm withValue:@[NSNull.null]];
            [stringObjectClass createInRealm:realm withValue:@[@"b"]];
            [stringObjectClass createInRealm:realm withValue:@[NSNull.null]];
            [stringObjectClass createInRealm:realm withValue:@[@""]];
        }];

        RLMResults *allObjects = [stringObjectClass allObjectsInRealm:realm];
        XCTAssertEqual(5U, allObjects.count);

        RLMResults *nilStrings = [stringObjectClass objectsInRealm:realm where:@"stringCol = NULL"];
        XCTAssertEqual(2U, nilStrings.count);
        XCTAssertEqualObjects((@[NSNull.null, NSNull.null]), [nilStrings valueForKey:@"stringCol"]);

        RLMResults *nilLikeStrings = [stringObjectClass objectsInRealm:realm where:@"stringCol LIKE NULL"];
        XCTAssertEqual(2U, nilLikeStrings.count);
        XCTAssertEqualObjects((@[NSNull.null, NSNull.null]), [nilLikeStrings valueForKey:@"stringCol"]);

        RLMResults *nonNilStrings = [stringObjectClass objectsInRealm:realm where:@"stringCol != NULL"];
        XCTAssertEqual(3U, nonNilStrings.count);
        XCTAssertEqualObjects((@[@"a", @"b", @""]), [nonNilStrings valueForKey:@"stringCol"]);

        RLMResults *nonNilLikeStrings = [stringObjectClass objectsInRealm:realm where:@"NOT stringCol LIKE NULL"];
        XCTAssertEqual(3U, nonNilLikeStrings.count);
        XCTAssertEqualObjects((@[@"a", @"b", @""]), [nonNilLikeStrings valueForKey:@"stringCol"]);

        RLMAssertCount(stringObjectClass, 3U, @"stringCol IN {NULL, 'a'}");

        RLMAssertCount(stringObjectClass, 1U, @"stringCol CONTAINS 'a'");
        RLMAssertCount(stringObjectClass, 1U, @"stringCol BEGINSWITH 'a'");
        RLMAssertCount(stringObjectClass, 1U, @"stringCol ENDSWITH 'a'");
        RLMAssertCount(stringObjectClass, 1U, @"stringCol LIKE 'a'");

        RLMAssertCount(stringObjectClass, 0U, @"stringCol CONTAINS 'z'");
        RLMAssertCount(stringObjectClass, 0U, @"stringCol LIKE 'z'");

        RLMAssertCount(stringObjectClass, 1U, @"stringCol = ''");

        RLMResults *sorted = [[stringObjectClass allObjectsInRealm:realm] sortedResultsUsingKeyPath:@"stringCol" ascending:YES];
        XCTAssertEqualObjects((@[NSNull.null, NSNull.null, @"", @"a", @"b"]), [sorted valueForKey:@"stringCol"]);
        XCTAssertEqualObjects((@[@"b", @"a", @"", NSNull.null, NSNull.null]), [[sorted sortedResultsUsingKeyPath:@"stringCol" ascending:NO] valueForKey:@"stringCol"]);

        [realm transactionWithBlock:^{
            [realm deleteObject:[stringObjectClass allObjectsInRealm:realm].firstObject];
        }];

        XCTAssertEqual(2U, nilStrings.count);
        XCTAssertEqual(2U, nonNilStrings.count);

        XCTAssertEqualObjects(@[], [[stringObjectClass objectsInRealm:realm where:@"stringCol CONTAINS ''"] valueForKey:@"stringCol"]);
        XCTAssertEqualObjects(@[], [[stringObjectClass objectsInRealm:realm where:@"stringCol BEGINSWITH ''"] valueForKey:@"stringCol"]);
        XCTAssertEqualObjects(@[], [[stringObjectClass objectsInRealm:realm where:@"stringCol ENDSWITH ''"] valueForKey:@"stringCol"]);
        XCTAssertEqualObjects([nonNilStrings valueForKey:@"stringCol"],
                              [[stringObjectClass objectsInRealm:realm where:@"stringCol LIKE '*'"] valueForKey:@"stringCol"]);
        XCTAssertEqualObjects(@[], [[stringObjectClass objectsInRealm:realm where:@"stringCol CONTAINS[c] ''"] valueForKey:@"stringCol"]);
        XCTAssertEqualObjects(@[], [[stringObjectClass objectsInRealm:realm where:@"stringCol BEGINSWITH[c] ''"] valueForKey:@"stringCol"]);
        XCTAssertEqualObjects(@[], [[stringObjectClass objectsInRealm:realm where:@"stringCol ENDSWITH[c] ''"] valueForKey:@"stringCol"]);
        XCTAssertEqualObjects([nonNilStrings valueForKey:@"stringCol"],
                              [[stringObjectClass objectsInRealm:realm where:@"stringCol LIKE[c] '*'"] valueForKey:@"stringCol"]);

        XCTAssertEqualObjects(@[], [[stringObjectClass objectsInRealm:realm where:@"stringCol CONTAINS[d] ''"] valueForKey:@"stringCol"]);
        XCTAssertEqualObjects(@[], [[stringObjectClass objectsInRealm:realm where:@"stringCol BEGINSWITH[d] ''"] valueForKey:@"stringCol"]);
        XCTAssertEqualObjects(@[], [[stringObjectClass objectsInRealm:realm where:@"stringCol ENDSWITH[d] ''"] valueForKey:@"stringCol"]);
        XCTAssertEqualObjects(@[], [[stringObjectClass objectsInRealm:realm where:@"stringCol CONTAINS[cd] ''"] valueForKey:@"stringCol"]);
        XCTAssertEqualObjects(@[], [[stringObjectClass objectsInRealm:realm where:@"stringCol BEGINSWITH[cd] ''"] valueForKey:@"stringCol"]);
        XCTAssertEqualObjects(@[], [[stringObjectClass objectsInRealm:realm where:@"stringCol ENDSWITH[cd] ''"] valueForKey:@"stringCol"]);

        XCTAssertEqualObjects(@[], ([[stringObjectClass objectsInRealm:realm where:@"stringCol CONTAINS %@", @"\0"] valueForKey:@"self"]));
        XCTAssertEqualObjects(@[], ([[stringObjectClass objectsInRealm:realm where:@"stringCol CONTAINS NULL"] valueForKey:@"stringCol"]));
        XCTAssertEqualObjects(@[], ([[stringObjectClass objectsInRealm:realm where:@"stringCol CONTAINS[c] NULL"] valueForKey:@"stringCol"]));
        XCTAssertEqualObjects(@[], ([[stringObjectClass objectsInRealm:realm where:@"stringCol CONTAINS[d] NULL"] valueForKey:@"stringCol"]));
        XCTAssertEqualObjects(@[], ([[stringObjectClass objectsInRealm:realm where:@"stringCol CONTAINS[cd] NULL"] valueForKey:@"stringCol"]));
    };
    testWithStringClass([StringObject class]);
    testWithStringClass([IndexedStringObject class]);
}

- (void)testQueryingOnLinkToNullableStringColumn {
    void (^testWithStringClass)(Class, Class) = ^(Class stringLinkClass, Class stringObjectClass) {
        RLMRealm *realm = [self realm];
        [realm transactionWithBlock:^{
            [stringLinkClass createInRealm:realm withValue:@[[stringObjectClass createInRealm:realm withValue:@[@"a"]]]];
            [stringLinkClass createInRealm:realm withValue:@[[stringObjectClass createInRealm:realm withValue:@[NSNull.null]]]];
            [stringLinkClass createInRealm:realm withValue:@[[stringObjectClass createInRealm:realm withValue:@[@"b"]]]];
            [stringLinkClass createInRealm:realm withValue:@[[stringObjectClass createInRealm:realm withValue:@[NSNull.null]]]];
            [stringLinkClass createInRealm:realm withValue:@[[stringObjectClass createInRealm:realm withValue:@[@""]]]];
        }];

        RLMResults *nilStrings = [stringLinkClass objectsInRealm:realm where:@"objectCol.stringCol = NULL"];
        XCTAssertEqual(2U, nilStrings.count);
        XCTAssertEqualObjects((@[NSNull.null, NSNull.null]), [nilStrings valueForKeyPath:@"objectCol.stringCol"]);

        RLMResults *nilLikeStrings = [stringLinkClass objectsInRealm:realm where:@"objectCol.stringCol LIKE NULL"];
        XCTAssertEqual(2U, nilLikeStrings.count);
        XCTAssertEqualObjects((@[NSNull.null, NSNull.null]), [nilLikeStrings valueForKeyPath:@"objectCol.stringCol"]);

        RLMResults *nonNilStrings = [stringLinkClass objectsInRealm:realm where:@"objectCol.stringCol != NULL"];
        XCTAssertEqual(3U, nonNilStrings.count);
        XCTAssertEqualObjects((@[@"a", @"b", @""]), [nonNilStrings valueForKeyPath:@"objectCol.stringCol"]);

        RLMResults *nonNilLikeStrings = [stringLinkClass objectsInRealm:realm where:@"NOT objectCol.stringCol LIKE NULL"];
        XCTAssertEqual(3U, nonNilLikeStrings.count);
        XCTAssertEqualObjects((@[@"a", @"b", @""]), [nonNilLikeStrings valueForKeyPath:@"objectCol.stringCol"]);

        RLMAssertCount(stringLinkClass, 3U, @"objectCol.stringCol IN {NULL, 'a'}");

        RLMAssertCount(stringLinkClass, 1U, @"objectCol.stringCol CONTAINS 'a'");
        RLMAssertCount(stringLinkClass, 1U, @"objectCol.stringCol BEGINSWITH 'a'");
        RLMAssertCount(stringLinkClass, 1U, @"objectCol.stringCol ENDSWITH 'a'");
        RLMAssertCount(stringLinkClass, 1U, @"objectCol.stringCol LIKE 'a'");
        RLMAssertCount(stringLinkClass, 0U, @"objectCol.stringCol LIKE 'c'");

        RLMAssertCount(stringLinkClass, 0U, @"objectCol.stringCol CONTAINS 'z'");

        RLMAssertCount(stringLinkClass, 1U, @"objectCol.stringCol = ''");
    };

    testWithStringClass([LinkStringObject class], [StringObject class]);
    testWithStringClass([LinkIndexedStringObject class], [IndexedStringObject class]);
}

- (void)testSortingColumnsWithNull {
    RLMRealm *realm = [self realm];
    [realm beginWriteTransaction];

    {
        NumberObject *no1 = [NumberObject createInRealm:realm withValue:@[@1, @1.1f, @1.1, @YES]];
        NumberObject *noNull = [NumberObject createInRealm:realm withValue:@[NSNull.null, NSNull.null, NSNull.null, NSNull.null]];
        NumberObject *no0 = [NumberObject createInRealm:realm withValue:@[@0, @0.0f, @0.0, @NO]];
        for (RLMProperty *property in [[NumberObject alloc] init].objectSchema.properties) {
            NSString *name = property.name;
            RLMResults *ascending = [[NumberObject allObjectsInRealm:realm] sortedResultsUsingKeyPath:name ascending:YES];
            XCTAssertEqualObjects([ascending valueForKey:name], ([@[noNull, no0, no1] valueForKey:name]));

            RLMResults *descending = [[NumberObject allObjectsInRealm:realm] sortedResultsUsingKeyPath:name ascending:NO];
            XCTAssertEqualObjects([descending valueForKey:name], ([@[no1, no0, noNull] valueForKey:name]));
        }
    }

    {
        DateObject *doPositive = [DateObject createInRealm:realm withValue:@[[NSDate dateWithTimeIntervalSince1970:100]]];
        DateObject *doNegative = [DateObject createInRealm:realm withValue:@[[NSDate dateWithTimeIntervalSince1970:-100]]];
        DateObject *doZero = [DateObject createInRealm:realm withValue:@[[NSDate dateWithTimeIntervalSince1970:0]]];
        DateObject *doNull = [DateObject createInRealm:realm withValue:@[NSNull.null]];

        RLMResults *ascending = [[DateObject allObjectsInRealm:realm] sortedResultsUsingKeyPath:@"dateCol" ascending:YES];
        XCTAssertEqualObjects([ascending valueForKey:@"dateCol"], ([@[doNull, doNegative, doZero, doPositive] valueForKey:@"dateCol"]));

        RLMResults *descending = [[DateObject allObjectsInRealm:realm] sortedResultsUsingKeyPath:@"dateCol" ascending:NO];
        XCTAssertEqualObjects([descending valueForKey:@"dateCol"], ([@[doPositive, doZero, doNegative, doNull] valueForKey:@"dateCol"]));
    }

    {
        StringObject *soA = [StringObject createInRealm:realm withValue:@[@"A"]];
        StringObject *soEmpty = [StringObject createInRealm:realm withValue:@[@""]];
        StringObject *soB = [StringObject createInRealm:realm withValue:@[@"B"]];
        StringObject *soNull = [StringObject createInRealm:realm withValue:@[NSNull.null]];
        StringObject *soAB = [StringObject createInRealm:realm withValue:@[@"AB"]];

        RLMResults *ascending = [[StringObject allObjectsInRealm:realm] sortedResultsUsingKeyPath:@"stringCol" ascending:YES];
        XCTAssertEqualObjects([ascending valueForKey:@"stringCol"], ([@[soNull, soEmpty, soA, soAB, soB] valueForKey:@"stringCol"]));

        RLMResults *descending = [[StringObject allObjectsInRealm:realm] sortedResultsUsingKeyPath:@"stringCol" ascending:NO];
        XCTAssertEqualObjects([descending valueForKey:@"stringCol"], ([@[soB, soAB, soA, soEmpty, soNull] valueForKey:@"stringCol"]));
    }

    [realm cancelWriteTransaction];
}

struct NullTestData {
    __unsafe_unretained NSString *propertyName;
    __unsafe_unretained NSString *nonMatchingStr;
    __unsafe_unretained NSString *matchingStr;
    __unsafe_unretained id nonMatchingValue;
    __unsafe_unretained id matchingValue;
    bool orderable;
    bool substringOperations;
};

- (void)testPrimitiveOperatorsOnAllNullablePropertyTypes {
    RLMRealm *realm = [self realm];

    // These need to be stored in variables because the struct does not retain them
    NSData *matchingData = [@"" dataUsingEncoding:NSUTF8StringEncoding];
    NSData *notMatchingData = [@"a" dataUsingEncoding:NSUTF8StringEncoding];
    NSDate *matchingDate = [NSDate dateWithTimeIntervalSince1970:1];
    NSDate *notMatchingDate = [NSDate dateWithTimeIntervalSince1970:2];
    RLMDecimal128 *matchingDecimal = [RLMDecimal128 decimalWithNumber:@1];
    RLMDecimal128 *notMatchingDecimal = [RLMDecimal128 decimalWithNumber:@2];
    RLMObjectId *matchingObjectId = [RLMObjectId objectId];
    RLMObjectId *notMatchingObjectId = [RLMObjectId objectId];

    struct NullTestData data[] = {
        {@"boolObj", @"YES", @"NO", @YES, @NO},
        {@"intObj", @"1", @"0", @1, @0, true},
        {@"floatObj", @"1", @"0", @1, @0, true},
        {@"doubleObj", @"1", @"0", @1, @0, true},
        {@"string", @"'a'", @"''", @"a", @"", false, true},
        {@"data", nil, nil, notMatchingData, matchingData, false, true},
        {@"date", nil, nil, notMatchingDate, matchingDate, true},
        {@"decimal", nil, nil, notMatchingDecimal, matchingDecimal, true},
        {@"objectId", nil, nil, notMatchingObjectId, matchingObjectId, false},
    };

    // Assert that the query "prop op value" gives expectedCount results when
    // assembled via string formatting
#define RLMAssertCountWithString(expectedCount, op, prop, value) \
    do { \
        NSString *queryStr = [NSString stringWithFormat:@"%@ " #op " %@", prop, value]; \
        NSUInteger actual = [AllOptionalTypes objectsWhere:queryStr].count; \
        XCTAssertEqual(expectedCount, actual, @"%@: expected %@, got %@", queryStr, @(expectedCount), @(actual)); \
    } while (0)

    // Assert that the query "prop op value" gives expectedCount results when
    // assembled via predicateWithFormat
#define RLMAssertCountWithPredicate(expectedCount, op, prop, value) \
    do { \
        NSPredicate *query = [NSPredicate predicateWithFormat:@"%K " #op " %@", prop, value]; \
        NSUInteger actual = [AllOptionalTypes objectsWithPredicate:query].count; \
        XCTAssertEqual(expectedCount, actual, @"%@ " #op " %@: expected %@, got %@", prop, value, @(expectedCount), @(actual)); \
    } while (0)

    // Assert that the given operator gives the expected count for each of the
    // stored value, a different value, and nil
#define RLMAssertOperator(op, matchingCount, notMatchingCount, nilCount) \
    do { \
        if (d.matchingStr) { \
            RLMAssertCountWithString(matchingCount, op, d.propertyName, d.matchingStr); \
            RLMAssertCountWithString(notMatchingCount, op, d.propertyName, d.nonMatchingStr); \
        } \
        RLMAssertCountWithString(nilCount, op, d.propertyName, nil); \
 \
        RLMAssertCountWithPredicate(matchingCount, op, d.propertyName, d.matchingValue); \
        RLMAssertCountWithPredicate(notMatchingCount, op, d.propertyName, d.nonMatchingValue); \
        RLMAssertCountWithPredicate(nilCount, op, d.propertyName, nil); \
    } while (0)

    // First test with the `matchingValue` stored in each property

    [realm beginWriteTransaction];
    [AllOptionalTypes createInRealm:realm withValue:@[@NO, @0, @0, @0, @"", matchingData, matchingDate, matchingDecimal, matchingObjectId]];
    [realm commitWriteTransaction];

    for (size_t i = 0; i < sizeof(data) / sizeof(data[0]); ++i) {
        struct NullTestData d = data[i];
        RLMAssertOperator(=,  1U, 0U, 0U);
        RLMAssertOperator(!=, 0U, 1U, 1U);

        if (d.orderable) {
            RLMAssertOperator(<,  0U, 1U, 0U);
            RLMAssertOperator(<=, 1U, 1U, 0U);
            RLMAssertOperator(>,  0U, 0U, 0U);
            RLMAssertOperator(>=, 1U, 0U, 0U);
        }
        if (d.substringOperations) {
            RLMAssertOperator(BEGINSWITH, 0U, 0U, 0U);
            RLMAssertOperator(ENDSWITH, 0U, 0U, 0U);
            RLMAssertOperator(CONTAINS, 0U, 0U, 0U);
        }
    }

    // Retest with all properties nil

    [realm beginWriteTransaction];
    [realm deleteAllObjects];
    [AllOptionalTypes createInRealm:realm withValue:@[NSNull.null, NSNull.null,
                                                      NSNull.null, NSNull.null,
                                                      NSNull.null, NSNull.null,
                                                      NSNull.null]];
    [realm commitWriteTransaction];

    for (size_t i = 0; i < sizeof(data) / sizeof(data[0]); ++i) {
        struct NullTestData d = data[i];
        RLMAssertOperator(=, 0U, 0U, 1U);
        RLMAssertOperator(!=, 1U, 1U, 0U);

        if (d.orderable) {
            RLMAssertOperator(<,  0U, 0U, 0U);
            RLMAssertOperator(<=, 0U, 0U, 1U);
            RLMAssertOperator(>,  0U, 0U, 0U);
            RLMAssertOperator(>=, 0U, 0U, 1U);
        }
        if (d.substringOperations) {
            RLMAssertOperator(BEGINSWITH, 0U, 0U, 0U);
            RLMAssertOperator(ENDSWITH, 0U, 0U, 0U);
            RLMAssertOperator(CONTAINS, 0U, 0U, 0U);
        }
    }

#undef RLMAssertCountWithString
#undef RLMAssertCountWithPredicate
#undef RLMAssertOperator
}

- (void)testPrimitiveOperatorsOnAllNullablePropertyTypesKeypathOnRHS {
    RLMRealm *realm = [self realm];

    // These need to be stored in variables because the struct does not retain them
    NSData *matchingData = [@"" dataUsingEncoding:NSUTF8StringEncoding];
    NSData *notMatchingData = [@"a" dataUsingEncoding:NSUTF8StringEncoding];
    NSDate *matchingDate = [NSDate dateWithTimeIntervalSince1970:1];
    NSDate *notMatchingDate = [NSDate dateWithTimeIntervalSince1970:2];
    RLMDecimal128 *matchingDecimal = [RLMDecimal128 decimalWithNumber:@1];
    RLMDecimal128 *notMatchingDecimal = [RLMDecimal128 decimalWithNumber:@2];
    RLMObjectId *matchingObjectId = [RLMObjectId objectId];
    RLMObjectId *notMatchingObjectId = [RLMObjectId objectId];

    struct NullTestData data[] = {
        {@"boolObj", @"YES", @"NO", @YES, @NO},
        {@"intObj", @"1", @"0", @1, @0, true},
        {@"floatObj", @"1", @"0", @1, @0, true},
        {@"doubleObj", @"1", @"0", @1, @0, true},
        {@"string", @"'a'", @"''", @"a", @"", false, true},
        {@"data", nil, nil, notMatchingData, matchingData, false, true},
        {@"date", nil, nil, notMatchingDate, matchingDate, true},
        {@"decimal", nil, nil, notMatchingDecimal, matchingDecimal, true},
        {@"objectId", nil, nil, notMatchingObjectId, matchingObjectId, false},
    };

    // Assert that the query "prop op value" gives expectedCount results when
    // assembled via string formatting
#define RLMAssertCountWithString(expectedCount, op, prop, value) \
    do { \
        NSString *queryStr = [NSString stringWithFormat:@"%@ " #op " %@", value, prop]; \
        NSUInteger actual = [AllOptionalTypes objectsWhere:queryStr].count; \
        XCTAssertEqual(expectedCount, actual, @"%@: expected %@, got %@", queryStr, @(expectedCount), @(actual)); \
        queryStr = [NSString stringWithFormat:@"%@ " #op " %@", value, prop]; \
        actual = [AllOptionalTypes objectsWhere:queryStr].count; \
        XCTAssertEqual(expectedCount, actual, @"%@: expected %@, got %@", queryStr, @(expectedCount), @(actual)); \
    } while (0)

    // Assert that the query "prop op value" gives expectedCount results when
    // assembled via predicateWithFormat
#define RLMAssertCountWithPredicate(expectedCount, op, prop, value) \
    do { \
        NSPredicate *query = [NSPredicate predicateWithFormat:@ "%@ " #op " %K", value, prop]; \
        NSUInteger actual = [AllOptionalTypes objectsWithPredicate:query].count; \
        XCTAssertEqual(expectedCount, actual, @"%@ " #op " %@: expected %@, got %@", prop, value, @(expectedCount), @(actual)); \
    } while (0)

    // Assert that the given operator gives the expected count for each of the
    // stored value, a different value, and nil
#define RLMAssertOperator(op, matchingCount, notMatchingCount, nilCount) \
    do { \
        if (d.matchingStr) { \
            RLMAssertCountWithString(matchingCount, op, d.propertyName, d.matchingStr); \
            RLMAssertCountWithString(notMatchingCount, op, d.propertyName, d.nonMatchingStr); \
        } \
        RLMAssertCountWithString(nilCount, op, d.propertyName, nil); \
 \
        RLMAssertCountWithPredicate(matchingCount, op, d.propertyName, d.matchingValue); \
        RLMAssertCountWithPredicate(notMatchingCount, op, d.propertyName, d.nonMatchingValue); \
        RLMAssertCountWithPredicate(nilCount, op, d.propertyName, nil); \
    } while (0)

    // First test with the `matchingValue` stored in each property

    [realm beginWriteTransaction];
    [AllOptionalTypes createInRealm:realm withValue:@[@NO, @0, @0, @0, @"", matchingData, matchingDate, matchingDecimal, matchingObjectId]];
    [realm commitWriteTransaction];

    for (size_t i = 0; i < sizeof(data) / sizeof(data[0]); ++i) {
        struct NullTestData d = data[i];
        RLMAssertOperator(=,  1U, 0U, 0U);
        RLMAssertOperator(!=, 0U, 1U, 1U);

        if (d.orderable) {
            RLMAssertOperator(>,  0U, 1U, 0U);
            RLMAssertOperator(>=, 1U, 1U, 0U);
            RLMAssertOperator(<,  0U, 0U, 0U);
            RLMAssertOperator(<=, 1U, 0U, 0U);
        }
    }

    // Retest with all properties nil

    [realm beginWriteTransaction];
    [realm deleteAllObjects];
    [AllOptionalTypes createInRealm:realm withValue:@[NSNull.null, NSNull.null,
                                                      NSNull.null, NSNull.null,
                                                      NSNull.null, NSNull.null,
                                                      NSNull.null]];
    [realm commitWriteTransaction];

    for (size_t i = 0; i < sizeof(data) / sizeof(data[0]); ++i) {
        struct NullTestData d = data[i];
        RLMAssertOperator(=, 0U, 0U, 1U);
        RLMAssertOperator(!=, 1U, 1U, 0U);

        if (d.orderable) {
            RLMAssertOperator(>,  0U, 0U, 0U);
            RLMAssertOperator(>=, 0U, 0U, 1U);
            RLMAssertOperator(<,  0U, 0U, 0U);
            RLMAssertOperator(<=, 0U, 0U, 1U);
        }
    }

#undef RLMAssertCountWithString
#undef RLMAssertCountWithPredicate
#undef RLMAssertOperator
}

- (void)testINPredicateOnNullWithNonNullValues
{
    RLMRealm *realm = [self realm];

    [realm beginWriteTransaction];
    RLMObjectId *objectId = [RLMObjectId objectId];
    [AllOptionalTypes createInRealm:realm withValue:@[@YES, @1, @1, @1, @"abc",
                                                      [@"a" dataUsingEncoding:NSUTF8StringEncoding],
                                                      [NSDate dateWithTimeIntervalSince1970:1],
                                                      @1, objectId]];
    [realm commitWriteTransaction];

    ////////////////////////
    // Literal Predicates
    ////////////////////////

    // BOOL
    [self testClass:[AllOptionalTypes class] withNormalCount:0 notCount:1 where:@"boolObj IN {NULL}"];
    [self testClass:[AllOptionalTypes class] withNormalCount:1 notCount:0 where:@"boolObj IN {YES}"];

    // int
    [self testClass:[AllOptionalTypes class] withNormalCount:0 notCount:1 where:@"intObj IN {NULL}"];
    [self testClass:[AllOptionalTypes class] withNormalCount:1 notCount:0 where:@"intObj IN {1}"];

    // float
    [self testClass:[AllOptionalTypes class] withNormalCount:0 notCount:1 where:@"floatObj IN {NULL}"];
    [self testClass:[AllOptionalTypes class] withNormalCount:1 notCount:0 where:@"floatObj IN {1}"];

    // double
    [self testClass:[AllOptionalTypes class] withNormalCount:0 notCount:1 where:@"doubleObj IN {NULL}"];
    [self testClass:[AllOptionalTypes class] withNormalCount:1 notCount:0 where:@"doubleObj IN {1}"];

    // NSString
    [self testClass:[AllOptionalTypes class] withNormalCount:0 notCount:1 where:@"string IN {NULL}"];
    [self testClass:[AllOptionalTypes class] withNormalCount:1 notCount:0 where:@"string IN {'abc'}"];

    // RLMDecimal128
    [self testClass:[AllOptionalTypes class] withNormalCount:0 notCount:1 where:@"decimal IN {NULL}"];
    [self testClass:[AllOptionalTypes class] withNormalCount:1 notCount:0 where:@"decimal IN {'1'}"];

    // NSData
    // Can't represent NSData with NSPredicate literal. See format predicates below

    // NSDate
    // Can't represent NSDate with NSPredicate literal. See format predicates below

    ////////////////////////
    // Format Predicates
    ////////////////////////

    // BOOL
    [self testClass:[AllOptionalTypes class] withNormalCount:0U notCount:1U where:@"boolObj IN %@", @[NSNull.null]];
    [self testClass:[AllOptionalTypes class] withNormalCount:1U notCount:0U where:@"boolObj IN %@", @[@YES]];

    // int
    [self testClass:[AllOptionalTypes class] withNormalCount:0U notCount:1U where:@"intObj IN %@", @[NSNull.null]];
    [self testClass:[AllOptionalTypes class] withNormalCount:1U notCount:0U where:@"intObj IN %@", @[@1]];

    // float
    [self testClass:[AllOptionalTypes class] withNormalCount:0U notCount:1U where:@"floatObj IN %@", @[NSNull.null]];
    [self testClass:[AllOptionalTypes class] withNormalCount:1U notCount:0U where:@"floatObj IN %@", @[@1]];

    // double
    [self testClass:[AllOptionalTypes class] withNormalCount:0U notCount:1U where:@"doubleObj IN %@", @[NSNull.null]];
    [self testClass:[AllOptionalTypes class] withNormalCount:1U notCount:0U where:@"doubleObj IN %@", @[@1]];

    // NSString
    [self testClass:[AllOptionalTypes class] withNormalCount:1U notCount:0U where:@"string IN %@", @[@"abc"]];
    [self testClass:[AllOptionalTypes class] withNormalCount:0U notCount:1U where:@"string IN %@", @[NSNull.null]];

    // NSData
    [self testClass:[AllOptionalTypes class] withNormalCount:0U notCount:1U where:@"data IN %@", @[NSNull.null]];
    [self testClass:[AllOptionalTypes class] withNormalCount:1U notCount:0U where:@"data IN %@", @[[@"a" dataUsingEncoding:NSUTF8StringEncoding]]];

    // NSDate
    [self testClass:[AllOptionalTypes class] withNormalCount:0U notCount:1U where:@"date IN %@", @[NSNull.null]];
    [self testClass:[AllOptionalTypes class] withNormalCount:1U notCount:0U where:@"date IN %@", @[[NSDate dateWithTimeIntervalSince1970:1]]];

    // RLMDecimal128
    [self testClass:[AllOptionalTypes class] withNormalCount:0 notCount:1 where:@"decimal IN %@", @[NSNull.null]];
    [self testClass:[AllOptionalTypes class] withNormalCount:1 notCount:0 where:@"decimal IN %@", @[@1]];

     // RLMObjectId
     [self testClass:[AllOptionalTypes class] withNormalCount:0 notCount:1 where:@"objectId IN %@", @[NSNull.null]];
     [self testClass:[AllOptionalTypes class] withNormalCount:1 notCount:0 where:@"objectId IN %@", @[objectId]];
}

- (void)testINPredicateOnNullWithNullValues
{
    RLMRealm *realm = [self realm];

    [realm beginWriteTransaction];
    [AllOptionalTypes createInRealm:realm withValue:@[NSNull.null, NSNull.null,
                                                      NSNull.null, NSNull.null,
                                                      NSNull.null, NSNull.null,
                                                      NSNull.null]];
    [realm commitWriteTransaction];

    ////////////////////////
    // Literal Predicates
    ////////////////////////

    // BOOL
    [self testClass:[AllOptionalTypes class] withNormalCount:1 notCount:0 where:@"boolObj IN {NULL}"];
    [self testClass:[AllOptionalTypes class] withNormalCount:0 notCount:1 where:@"boolObj IN {YES}"];

    // int
    [self testClass:[AllOptionalTypes class] withNormalCount:1 notCount:0 where:@"intObj IN {NULL}"];
    [self testClass:[AllOptionalTypes class] withNormalCount:0 notCount:1 where:@"intObj IN {1}"];

    // float
    [self testClass:[AllOptionalTypes class] withNormalCount:1 notCount:0 where:@"floatObj IN {NULL}"];
    [self testClass:[AllOptionalTypes class] withNormalCount:0 notCount:1 where:@"floatObj IN {1}"];

    // double
    [self testClass:[AllOptionalTypes class] withNormalCount:1 notCount:0 where:@"doubleObj IN {NULL}"];
    [self testClass:[AllOptionalTypes class] withNormalCount:0 notCount:1 where:@"doubleObj IN {1}"];

    // NSString
    [self testClass:[AllOptionalTypes class] withNormalCount:1 notCount:0 where:@"string IN {NULL}"];
    [self testClass:[AllOptionalTypes class] withNormalCount:0 notCount:1 where:@"string IN {'abc'}"];

    // RLMDecimal128
    [self testClass:[AllOptionalTypes class] withNormalCount:1 notCount:0 where:@"decimal IN {NULL}"];
    [self testClass:[AllOptionalTypes class] withNormalCount:0 notCount:1 where:@"decimal IN {'1'}"];

    // NSData
    // Can't represent NSData with NSPredicate literal. See format predicates below

    // NSDate
    // Can't represent NSDate with NSPredicate literal. See format predicates below

    ////////////////////////
    // Format Predicates
    ////////////////////////

    // BOOL
    [self testClass:[AllOptionalTypes class] withNormalCount:1U notCount:0U where:@"boolObj IN %@", @[NSNull.null]];
    [self testClass:[AllOptionalTypes class] withNormalCount:0U notCount:1U where:@"boolObj IN %@", @[@YES]];

    // int
    [self testClass:[AllOptionalTypes class] withNormalCount:1U notCount:0U where:@"intObj IN %@", @[NSNull.null]];
    [self testClass:[AllOptionalTypes class] withNormalCount:0U notCount:1U where:@"intObj IN %@", @[@1]];

    // float
    [self testClass:[AllOptionalTypes class] withNormalCount:1U notCount:0U where:@"floatObj IN %@", @[NSNull.null]];
    [self testClass:[AllOptionalTypes class] withNormalCount:0U notCount:1U where:@"floatObj IN %@", @[@1]];

    // double
    [self testClass:[AllOptionalTypes class] withNormalCount:1U notCount:0U where:@"doubleObj IN %@", @[NSNull.null]];
    [self testClass:[AllOptionalTypes class] withNormalCount:0U notCount:1U where:@"doubleObj IN %@", @[@1]];

    // NSString
    [self testClass:[AllOptionalTypes class] withNormalCount:0U notCount:1U where:@"string IN %@", @[@"abc"]];
    [self testClass:[AllOptionalTypes class] withNormalCount:1U notCount:0U where:@"string IN %@", @[NSNull.null]];

    // NSData
    [self testClass:[AllOptionalTypes class] withNormalCount:1U notCount:0U where:@"data IN %@", @[NSNull.null]];
    [self testClass:[AllOptionalTypes class] withNormalCount:0U notCount:1U where:@"data IN %@", @[[@"a" dataUsingEncoding:NSUTF8StringEncoding]]];

    // NSDate
    [self testClass:[AllOptionalTypes class] withNormalCount:1U notCount:0U where:@"date IN %@", @[NSNull.null]];
    [self testClass:[AllOptionalTypes class] withNormalCount:0U notCount:1U where:@"date IN %@", @[[NSDate dateWithTimeIntervalSince1970:1]]];

    // RLMDecimal128
    [self testClass:[AllOptionalTypes class] withNormalCount:1 notCount:0 where:@"decimal IN %@", @[NSNull.null]];
    [self testClass:[AllOptionalTypes class] withNormalCount:0 notCount:1 where:@"decimal IN %@", @[@1]];

     // RLMObjectId
     [self testClass:[AllOptionalTypes class] withNormalCount:1 notCount:0 where:@"objectId IN %@", @[NSNull.null]];
     [self testClass:[AllOptionalTypes class] withNormalCount:0 notCount:1 where:@"objectId IN %@", @[RLMObjectId.objectId]];
}

- (void)testQueryOnRenamedProperties {
    RLMRealm *realm = [self realm];
    [realm beginWriteTransaction];
    [RenamedProperties1 createInRealm:realm withValue:@[@1, @"a"]];
    [RenamedProperties2 createInRealm:realm withValue:@[@2, @"b"]];
    [realm commitWriteTransaction];

    [self testClass:[RenamedProperties1 class] withNormalCount:2 notCount:0 where:@"propA != 0"];
    [self testClass:[RenamedProperties1 class] withNormalCount:1 notCount:1 where:@"propA = 1"];
    [self testClass:[RenamedProperties1 class] withNormalCount:1 notCount:1 where:@"propA = 2"];
    [self testClass:[RenamedProperties1 class] withNormalCount:0 notCount:2 where:@"propA = 3"];

    [self testClass:[RenamedProperties2 class] withNormalCount:2 notCount:0 where:@"propC != 0"];
    [self testClass:[RenamedProperties2 class] withNormalCount:1 notCount:1 where:@"propC = 1"];
    [self testClass:[RenamedProperties2 class] withNormalCount:1 notCount:1 where:@"propC = 2"];
    [self testClass:[RenamedProperties2 class] withNormalCount:0 notCount:2 where:@"propC = 3"];
}

- (void)testQueryOverRenamedLinks {
    RLMRealm *realm = [self realm];
    [realm beginWriteTransaction];
    id obj1 = [RenamedProperties1 createInRealm:realm withValue:@[@1, @"a"]];
    id obj2 = [RenamedProperties2 createInRealm:realm withValue:@[@2, @"b"]];
    [LinkToRenamedProperties1 createInRealm:realm withValue:@[obj1, NSNull.null, @[obj1], @[obj1]]];
    [LinkToRenamedProperties2 createInRealm:realm withValue:@[obj2, NSNull.null, @[obj2], @[obj2]]];
    [realm commitWriteTransaction];

    [self testClass:[LinkToRenamedProperties1 class] withNormalCount:2 notCount:0 where:@"linkA.propA != 0"];
    [self testClass:[LinkToRenamedProperties1 class] withNormalCount:1 notCount:1 where:@"linkA.propA = 1"];
    [self testClass:[LinkToRenamedProperties1 class] withNormalCount:1 notCount:1 where:@"linkA.propA = 2"];
    [self testClass:[LinkToRenamedProperties1 class] withNormalCount:0 notCount:2 where:@"linkA.propA = 3"];

    [self testClass:[LinkToRenamedProperties2 class] withNormalCount:2 notCount:0 where:@"linkC.propC != 0"];
    [self testClass:[LinkToRenamedProperties2 class] withNormalCount:1 notCount:1 where:@"linkC.propC = 1"];
    [self testClass:[LinkToRenamedProperties2 class] withNormalCount:1 notCount:1 where:@"linkC.propC = 2"];
    [self testClass:[LinkToRenamedProperties2 class] withNormalCount:0 notCount:2 where:@"linkC.propC = 3"];

    [self testClass:[LinkToRenamedProperties1 class] withNormalCount:2 notCount:0 where:@"ANY array.propA != 0"];
    [self testClass:[LinkToRenamedProperties1 class] withNormalCount:1 notCount:1 where:@"ANY array.propA = 1"];
    [self testClass:[LinkToRenamedProperties1 class] withNormalCount:1 notCount:1 where:@"ANY array.propA = 2"];
    [self testClass:[LinkToRenamedProperties1 class] withNormalCount:0 notCount:2 where:@"ANY array.propA = 3"];

    [self testClass:[LinkToRenamedProperties2 class] withNormalCount:2 notCount:0 where:@"ANY array.propC != 0"];
    [self testClass:[LinkToRenamedProperties2 class] withNormalCount:1 notCount:1 where:@"ANY array.propC = 1"];
    [self testClass:[LinkToRenamedProperties2 class] withNormalCount:1 notCount:1 where:@"ANY array.propC = 2"];
    [self testClass:[LinkToRenamedProperties2 class] withNormalCount:0 notCount:2 where:@"ANY array.propC = 3"];

    [self testClass:[LinkToRenamedProperties1 class] withNormalCount:2 notCount:0 where:@"ANY set.propA != 0"];
    [self testClass:[LinkToRenamedProperties1 class] withNormalCount:1 notCount:1 where:@"ANY set.propA = 1"];
    [self testClass:[LinkToRenamedProperties1 class] withNormalCount:1 notCount:1 where:@"ANY set.propA = 2"];
    [self testClass:[LinkToRenamedProperties1 class] withNormalCount:0 notCount:2 where:@"ANY set.propA = 3"];

    [self testClass:[LinkToRenamedProperties2 class] withNormalCount:2 notCount:0 where:@"ANY set.propC != 0"];
    [self testClass:[LinkToRenamedProperties2 class] withNormalCount:1 notCount:1 where:@"ANY set.propC = 1"];
    [self testClass:[LinkToRenamedProperties2 class] withNormalCount:1 notCount:1 where:@"ANY set.propC = 2"];
    [self testClass:[LinkToRenamedProperties2 class] withNormalCount:0 notCount:2 where:@"ANY set.propC = 3"];
}

- (void)testQueryOverRenamedBacklinks {
    RLMRealm *realm = [self realm];
    [realm beginWriteTransaction];
    id obj1 = [RenamedProperties1 createInRealm:realm withValue:@[@1, @"a"]];
    id obj2 = [RenamedProperties2 createInRealm:realm withValue:@[@2, @"b"]];
    [LinkToRenamedProperties1 createInRealm:realm withValue:@[obj1, NSNull.null, @[obj1]]];
    [LinkToRenamedProperties2 createInRealm:realm withValue:@[obj2, NSNull.null, @[obj2]]];
    [realm commitWriteTransaction];

    [self testClass:[RenamedProperties1 class] withNormalCount:2 notCount:0 where:@"ANY linking1.linkA.propA != 0"];
    [self testClass:[RenamedProperties1 class] withNormalCount:1 notCount:1 where:@"ANY linking1.linkA.propA = 1"];
    [self testClass:[RenamedProperties1 class] withNormalCount:1 notCount:1 where:@"ANY linking1.linkA.propA = 2"];
    [self testClass:[RenamedProperties1 class] withNormalCount:0 notCount:2 where:@"ANY linking1.linkA.propA = 3"];
}

@end

@interface AsyncQueryTests : QueryTests
@end

@implementation AsyncQueryTests
- (RLMResults *)evaluate:(RLMResults *)results {
    id token = [results addNotificationBlock:^(RLMResults *r, __unused RLMCollectionChange *changed, NSError *e) {
        XCTAssertNil(e);
        XCTAssertNotNil(r);
        CFRunLoopStop(CFRunLoopGetCurrent());
    }];
    CFRunLoopRun();
    [(RLMNotificationToken *)token invalidate];
    return results;
}
@end

@interface QueryWithReversedColumnOrderTests : QueryTests
@end

@implementation QueryWithReversedColumnOrderTests
- (RLMRealm *)realm {
    @autoreleasepool {
        NSSet *classNames = [NSSet setWithArray:@[@"AllTypesObject", @"QueryObject", @"PersonObject", @"DogObject",
                                                  @"EmployeeObject", @"CompanyObject", @"OwnerObject"]];
        RLMSchema *schema = [RLMSchema.sharedSchema copy];
        NSMutableArray *objectSchemas = [schema.objectSchema mutableCopy];
        for (NSUInteger i = 0; i < objectSchemas.count; i++) {
            RLMObjectSchema *objectSchema = objectSchemas[i];
            if ([classNames member:objectSchema.className]) {
                objectSchemas[i] = [self reverseProperties:objectSchema];
            }
        }
        schema.objectSchema = objectSchemas;
        RLMRealmConfiguration *config = [RLMRealmConfiguration defaultConfiguration];
        config.customSchema = schema;
        [RLMRealm realmWithConfiguration:config error:nil];
    }

    return RLMRealm.defaultRealm;
}

- (RLMObjectSchema *)reverseProperties:(RLMObjectSchema *)source {
    RLMObjectSchema *objectSchema = [source copy];
    objectSchema.properties = objectSchema.properties.reverseObjectEnumerator.allObjects;
    return objectSchema;
}
@end
