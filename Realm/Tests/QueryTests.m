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
#import "RLMRealm_Dynamic.h"

#pragma mark - Test Objects

#pragma mark NonRealmEmployeeObject

@interface NonRealmEmployeeObject : NSObject
@property NSString *name;
@property NSInteger age;
@end

@implementation NonRealmEmployeeObject
@end

#pragma mark PersonObject

@interface PersonObject : RLMObject
@property NSString *name;
@property NSInteger age;
@end

@implementation PersonObject
@end

@interface PersonLinkObject : RLMObject
@property PersonObject *person;
@end

@implementation PersonLinkObject
@end

#pragma mark QueryObject

@interface QueryObject : RLMObject
@property (nonatomic, assign) BOOL      bool1;
@property (nonatomic, assign) BOOL      bool2;
@property (nonatomic, assign) NSInteger int1;
@property (nonatomic, assign) NSInteger int2;
@property (nonatomic, assign) float     float1;
@property (nonatomic, assign) float     float2;
@property (nonatomic, assign) double    double1;
@property (nonatomic, assign) double    double2;
@property (nonatomic, copy) NSString   *string1;
@property (nonatomic, copy) NSString   *string2;
@end

@implementation QueryObject
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
    XCTAssertThrows([[realm objects:@"NonRealmPersonObject" where:@"age > 25"] sortedResultsUsingProperty:@"age" ascending:YES], @"invalid object type");

    // empty string for class name
    XCTAssertThrows([realm objects:@"" where:@"age > 25"], @"missing class name");
    XCTAssertThrows([[realm objects:@"" where:@"age > 25"] sortedResultsUsingProperty:@"age" ascending:YES], @"missing class name");

    // nil class name
    XCTAssertThrows([realm objects:nil where:@"age > 25"], @"nil class name");
    XCTAssertThrows([[realm objects:nil where:@"age > 25"] sortedResultsUsingProperty:@"age" ascending:YES], @"nil class name");
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

    // nil on LHS of comparison with nullable property
    XCTAssertThrows([AllOptionalTypes objectsWhere:@"nil = boolObj"]);
    XCTAssertThrows([AllOptionalTypes objectsWhere:@"nil = intObj"]);
    XCTAssertThrows([AllOptionalTypes objectsWhere:@"nil = floatObj"]);
    XCTAssertThrows([AllOptionalTypes objectsWhere:@"nil = doubleObj"]);
    XCTAssertThrows([AllOptionalTypes objectsWhere:@"nil = string"]);
    XCTAssertThrows([AllOptionalTypes objectsWhere:@"nil = data"]);
    XCTAssertThrows([AllOptionalTypes objectsWhere:@"nil = date"]);

    // comparing two constants
    XCTAssertThrows([PersonObject objectsWhere:@"5 = 5"]);
    XCTAssertThrows([PersonObject objectsWhere:@"nil = nil"]);

    // substring operations with constant on LHS
    XCTAssertThrows([AllOptionalTypes objectsWhere:@"'' CONTAINS string"]);
    XCTAssertThrows([AllOptionalTypes objectsWhere:@"'' BEGINSWITH string"]);
    XCTAssertThrows([AllOptionalTypes objectsWhere:@"'' ENDSWITH string"]);
    XCTAssertThrows(([AllOptionalTypes objectsWhere:@"%@ CONTAINS data", [NSData data]]));

    // data is missing stuff
    XCTAssertThrows([AllOptionalTypes objectsWhere:@"data = data"]);
    XCTAssertThrows(([LinkToAllTypesObject objectsWhere:@"%@ = allTypesCol.binaryCol", [NSData data]]));
    XCTAssertThrows(([LinkToAllTypesObject objectsWhere:@"allTypesCol.binaryCol CONTAINS %@", [NSData data]]));

    // LinkList equality is unsupport since the semantics are unclear
    XCTAssertThrows(([ArrayOfAllTypesObject objectsWhere:@"ANY array = array"]));

    // Unsupported variants of subqueries.
    RLMAssertThrowsWithReasonMatching(([ArrayOfAllTypesObject objectsWhere:@"SUBQUERY(array, $obj, $obj.intCol = 5).@count == array.@count"]), @"SUBQUERY.*compared with a constant number");
    RLMAssertThrowsWithReasonMatching(([ArrayOfAllTypesObject objectsWhere:@"SUBQUERY(array, $obj, $obj.intCol = 5) == 0"]), @"SUBQUERY.*immediately followed by .@count");
    RLMAssertThrowsWithReasonMatching(([ArrayOfAllTypesObject objectsWhere:@"SELF IN SUBQUERY(array, $obj, $obj.intCol = 5)"]), @"Predicate with IN operator must compare.*aggregate$");

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
    RLMAssertThrowsWithReasonMatching([realm objects:className where:@"height > 72"], @"'height' not found in .* 'PersonObject'");

    // wrong/invalid data types
    RLMAssertThrowsWithReasonMatching([realm objects:className where:@"age != xyz"], @"'xyz' not found in .* 'PersonObject'");
    RLMAssertThrowsWithReasonMatching([realm objects:className where:@"name == 3"], @"type string .* property 'name' .* 'PersonObject'.*: 3");
    RLMAssertThrowsWithReasonMatching([realm objects:className where:@"age IN {'xyz'}"], @"type int .* property 'age' .* 'PersonObject'.*: xyz");
    XCTAssertThrows([realm objects:className where:@"name IN {3}"], @"invalid type");

    className = AllTypesObject.className;

    XCTAssertThrows([realm objects:className where:@"boolCol == Foo"], @"invalid type");
    XCTAssertThrows([realm objects:className where:@"boolCol == 2"], @"invalid type");
    XCTAssertThrows([realm objects:className where:@"dateCol == 7"], @"invalid type");
    XCTAssertThrows([realm objects:className where:@"doubleCol == The"], @"invalid type");
    XCTAssertThrows([realm objects:className where:@"floatCol == Bar"], @"invalid type");
    XCTAssertThrows([realm objects:className where:@"intCol == Baz"], @"invalid type");

    className = PersonObject.className;

    // compare two constants
    XCTAssertThrows([realm objects:className where:@"3 == 3"], @"comparing 2 constants");

    // invalid strings
    RLMAssertThrowsWithReasonMatching([realm objects:className where:@""], @"Unable to parse");
    XCTAssertThrows([realm objects:className where:@"age"], @"column name only");
    XCTAssertThrows([realm objects:className where:@"sdlfjasdflj"], @"gibberish");
    XCTAssertThrows([realm objects:className where:@"age * 25"], @"invalid operator");
    XCTAssertThrows([realm objects:className where:@"age === 25"], @"invalid operator");
    XCTAssertThrows([realm objects:className where:@","], @"comma");
    XCTAssertThrows([realm objects:className where:@"()"], @"parens");

    // Misspelled keypath (should be %K)
    RLMAssertThrowsWithReasonMatching([realm objects:className where:@"@K == YES"], @"'@K' is not a valid key path'");

    // not a link column
    RLMAssertThrowsWithReasonMatching([realm objects:className where:@"age.age == 25"], @"'age' is not a link .* 'PersonObject'");
    XCTAssertThrows([realm objects:className where:@"age.age.age == 25"]);

    // abuse of BETWEEN
    RLMAssertThrowsWithReasonMatching([realm objects:className where:@"age BETWEEN 25"], @"type NSArray for BETWEEN");
    RLMAssertThrowsWithReasonMatching([realm objects:className where:@"age BETWEEN Foo"], @"BETWEEN operator must compare a KeyPath with an aggregate");
    RLMAssertThrowsWithReasonMatching([realm objects:className where:@"age BETWEEN {age, age}"], @"must be constant values");
    RLMAssertThrowsWithReasonMatching([realm objects:className where:@"age BETWEEN {age, 0}"], @"must be constant values");
    RLMAssertThrowsWithReasonMatching([realm objects:className where:@"age BETWEEN {0, age}"], @"must be constant values");
    RLMAssertThrowsWithReasonMatching([realm objects:className where:@"age BETWEEN {0, {1, 10}}"], @"must be constant values");

    NSPredicate *pred = [NSPredicate predicateWithFormat:@"age BETWEEN %@", @[@1]];
    RLMAssertThrowsWithReasonMatching([realm objects:className withPredicate:pred], @"exactly two objects");

    pred = [NSPredicate predicateWithFormat:@"age BETWEEN %@", @[@1, @2, @3]];
    RLMAssertThrowsWithReasonMatching([realm objects:className withPredicate:pred], @"exactly two objects");

    pred = [NSPredicate predicateWithFormat:@"age BETWEEN %@", @[@"Foo", @"Bar"]];
    RLMAssertThrowsWithReasonMatching([realm objects:className withPredicate:pred], @"type int for BETWEEN");

    pred = [NSPredicate predicateWithFormat:@"age BETWEEN %@", @[@1.5, @2.5]];
    RLMAssertThrowsWithReasonMatching([realm objects:className withPredicate:pred], @"type int for BETWEEN");

    pred = [NSPredicate predicateWithFormat:@"age BETWEEN %@", @[@1, @[@2, @3]]];
    RLMAssertThrowsWithReasonMatching([realm objects:className withPredicate:pred], @"type int for BETWEEN");

    pred = [NSPredicate predicateWithFormat:@"age BETWEEN %@", @{@25 : @35}];
    RLMAssertThrowsWithReasonMatching([realm objects:className withPredicate:pred], @"type NSArray for BETWEEN");

    pred = [NSPredicate predicateWithFormat:@"height BETWEEN %@", @[@25, @35]];
    RLMAssertThrowsWithReasonMatching([realm objects:className withPredicate:pred], @"'height' not found .* 'PersonObject'");

    // bad type in link IN
    XCTAssertThrows([PersonLinkObject objectsInRealm:realm where:@"person.age IN {'Tim'}"]);
}

- (void)testStringUnsupportedOperations
{
    XCTAssertThrows([StringObject objectsWhere:@"stringCol LIKE 'abc'"]);
    XCTAssertThrows([StringObject objectsWhere:@"stringCol MATCHES 'abc'"]);
    XCTAssertThrows([StringObject objectsWhere:@"stringCol BETWEEN {'a', 'b'}"]);
    XCTAssertThrows([StringObject objectsWhere:@"stringCol < 'abc'"]);

    XCTAssertThrows([AllTypesObject objectsWhere:@"objectCol.stringCol LIKE 'abc'"]);
    XCTAssertThrows([AllTypesObject objectsWhere:@"objectCol.stringCol MATCHES 'abc'"]);
    XCTAssertThrows([AllTypesObject objectsWhere:@"objectCol.stringCol BETWEEN {'a', 'b'}"]);
    XCTAssertThrows([AllTypesObject objectsWhere:@"objectCol.stringCol < 'abc'"]);
}

- (void)testBinaryComparisonInPredicate {
    NSData *data = [NSData data];
    RLMAssertCount(BinaryObject, 0U, @"binaryCol BEGINSWITH %@", data);
    RLMAssertCount(BinaryObject, 0U, @"binaryCol ENDSWITH %@", data);
    RLMAssertCount(BinaryObject, 0U, @"binaryCol CONTAINS %@", data);
    RLMAssertCount(BinaryObject, 0U, @"binaryCol = %@", data);
    RLMAssertCount(BinaryObject, 0U, @"binaryCol != %@", data);

    XCTAssertThrows(([BinaryObject objectsWhere:@"binaryCol < %@", data]));
    XCTAssertThrows(([BinaryObject objectsWhere:@"binaryCol <= %@", data]));
    XCTAssertThrows(([BinaryObject objectsWhere:@"binaryCol > %@", data]));
    XCTAssertThrows(([BinaryObject objectsWhere:@"binaryCol >= %@", data]));

    XCTAssertThrows(([BinaryObject objectsWhere:@"binaryCol LIKE %@", data]));
    XCTAssertThrows(([BinaryObject objectsWhere:@"binaryCol MATCHES %@", data]));
}

- (void)testLinkQueryInvalid {
    XCTAssertThrows([LinkToAllTypesObject objectsWhere:@"allTypesCol.binaryCol = 'a'"], @"Binary data not supported");
    XCTAssertThrows([LinkToAllTypesObject objectsWhere:@"allTypesCol.mixedCol = 'a'"], @"Mixed data not supported");
    XCTAssertThrows([LinkToAllTypesObject objectsWhere:@"allTypesCol.invalidCol = 'a'"], @"Invalid column name should throw");

    XCTAssertThrows([LinkToAllTypesObject objectsWhere:@"allTypesCol.longCol = 'a'"], @"Wrong data type should throw");

    RLMAssertThrowsWithReasonMatching([ArrayPropertyObject objectsWhere:@"intArray.intCol > 5"], @"Key paths.*array property.*aggregate operations");
    RLMAssertThrowsWithReasonMatching([LinkToCompanyObject objectsWhere:@"company.employees.age > 5"], @"Key paths.*array property.*aggregate operations");

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
}
@end

@interface QueryTests : RLMTestCase
- (Class)queryObjectClass;
- (BOOL)isNull;
@end

@implementation QueryTests

- (Class)queryObjectClass {
    return [QueryObject class];
}

- (BOOL)isNull {
    return NO;
}

- (RLMResults *)evaluate:(RLMResults *)results {
    return results;
}

- (void)testBasicQuery
{
    RLMRealm *realm = [RLMRealm defaultRealm];

    [realm beginWriteTransaction];
    [PersonObject createInRealm:realm withValue:@[@"Fiel", @27]];
    [PersonObject createInRealm:realm withValue:@[@"Ari", @33]];
    [PersonObject createInRealm:realm withValue:@[@"Tim", @29]];
    [realm commitWriteTransaction];

    // query on realm
    RLMAssertCount(PersonObject, 2U, @"age > 28");

    // query on realm with order
    RLMResults *results = [[PersonObject objectsInRealm:realm where:@"age > 28"] sortedResultsUsingProperty:@"age" ascending:YES];
    XCTAssertEqualObjects([results[0] name], @"Tim", @"Tim should be first results");

    // query on sorted results
    results = [[[PersonObject allObjectsInRealm:realm] sortedResultsUsingProperty:@"age" ascending:YES] objectsWhere:@"age > 28"];
    XCTAssertEqualObjects([results[0] name], @"Tim", @"Tim should be first results");
}

-(void)testQueryBetween
{
    RLMRealm *realm = [RLMRealm defaultRealm];

    NSDate *date1 = [NSDate date];
    NSDate *date2 = [date1 dateByAddingTimeInterval:1];
    NSDate *date3 = [date2 dateByAddingTimeInterval:1];
    NSDate *date33 = [date3 dateByAddingTimeInterval:1];

    StringObject *stringObj = [StringObject new];
    stringObj.stringCol = @"string";

    [realm beginWriteTransaction];
    [AllTypesObject createInRealm:realm withValue:@[@YES, @1, @1.0f, @1.0, @"a", [@"a" dataUsingEncoding:NSUTF8StringEncoding], date1, @YES, @((long)1), @1, stringObj]];
    [AllTypesObject createInRealm:realm withValue:@[@YES, @2, @2.0f, @2.0, @"b", [@"b" dataUsingEncoding:NSUTF8StringEncoding], date2, @YES, @((long)2), @"mixed", stringObj]];
    [AllTypesObject createInRealm:realm withValue:@[@NO, @3, @3.0f, @3.0, @"c", [@"c" dataUsingEncoding:NSUTF8StringEncoding], date3, @YES, @((long)3), @"mixed", stringObj]];
    [AllTypesObject createInRealm:realm withValue:@[@NO, @33, @3.3f, @3.3, @"cc", [@"cc" dataUsingEncoding:NSUTF8StringEncoding], date33, @NO, @((long)3.3), @"mixed", stringObj]];
    [realm commitWriteTransaction];

    RLMAssertCount(AllTypesObject, 2U, @"intCol BETWEEN %@", @[@2, @3]);
    RLMAssertCount(AllTypesObject, 4U, @"floatCol BETWEEN %@", @[@1.0f, @4.0f]);
    RLMAssertCount(AllTypesObject, 2U, @"doubleCol BETWEEN %@", @[@3.0, @7.0]);
    RLMAssertCount(AllTypesObject, 2U, @"dateCol BETWEEN %@", @[date2, date3]);

    RLMAssertCount(AllTypesObject, 2U, @"intCol BETWEEN {2, 3}");
    RLMAssertCount(AllTypesObject, 2U, @"doubleCol BETWEEN {3.0, 7.0}");

    RLMAssertCount(AllTypesObject.allObjects, 2U, @"intCol BETWEEN {2, 3}");
    RLMAssertCount(AllTypesObject.allObjects, 2U, @"doubleCol BETWEEN {3.0, 7.0}");
}

- (void)testQueryWithDates
{
    RLMRealm *realm = [RLMRealm defaultRealm];

    NSDate *date1 = [NSDate date];
    NSDate *date2 = [date1 dateByAddingTimeInterval:1];
    NSDate *date3 = [date2 dateByAddingTimeInterval:1];

    StringObject *stringObj = [StringObject new];
    stringObj.stringCol = @"string";

    [realm beginWriteTransaction];
    [AllTypesObject createInRealm:realm withValue:@[@YES, @1, @1.0f, @1.0, @"a", [@"a" dataUsingEncoding:NSUTF8StringEncoding], date1, @YES, @((long)1), @1, stringObj]];
    [AllTypesObject createInRealm:realm withValue:@[@YES, @2, @2.0f, @2.0, @"b", [@"b" dataUsingEncoding:NSUTF8StringEncoding], date2, @YES, @((long)2), @"mixed", stringObj]];
    [AllTypesObject createInRealm:realm withValue:@[@NO, @3, @3.0f, @3.0, @"c", [@"c" dataUsingEncoding:NSUTF8StringEncoding], date3, @YES, @((long)3), @"mixed", stringObj]];
    [realm commitWriteTransaction];

    RLMAssertCount(AllTypesObject, 2U, @"dateCol < %@", date3);
    RLMAssertCount(AllTypesObject, 3U, @"dateCol <= %@", date3);
    RLMAssertCount(AllTypesObject, 2U, @"dateCol > %@", date1);
    RLMAssertCount(AllTypesObject, 3U, @"dateCol >= %@", date1);
    RLMAssertCount(AllTypesObject, 1U, @"dateCol == %@", date1);
    RLMAssertCount(AllTypesObject, 2U, @"dateCol != %@", date1);
}

- (void)testDefaultRealmQuery
{
    RLMRealm *realm = [RLMRealm defaultRealm];

    [realm beginWriteTransaction];
    [PersonObject createInRealm:realm withValue:@[@"Fiel", @27]];
    [PersonObject createInRealm:realm withValue:@[@"Tim", @29]];
    [PersonObject createInRealm:realm withValue:@[@"Ari", @33]];
    [realm commitWriteTransaction];

    // query on class
    XCTAssertEqual([PersonObject allObjects].count, 3U);
    RLMAssertCount(PersonObject, 1U, @"age == 27");

    // with order
    RLMResults *results = [[PersonObject objectsWhere:@"age > 28"] sortedResultsUsingProperty:@"age" ascending:YES];
    PersonObject *tim = results[0];
    XCTAssertEqualObjects(tim.name, @"Tim", @"Tim should be first results");
}

- (void)testArrayQuery
{
    RLMRealm *realm = [RLMRealm defaultRealm];

    [realm beginWriteTransaction];
    [PersonObject createInRealm:realm withValue:@[@"Fiel", @27]];
    [PersonObject createInRealm:realm withValue:@[@"Tim", @29]];
    [PersonObject createInRealm:realm withValue:@[@"Ari", @33]];
    [realm commitWriteTransaction];

    // query on class
    RLMResults *all = [PersonObject allObjects];
    XCTAssertEqual(all.count, 3U, @"Expecting 3 results");

    RLMResults *some = [[PersonObject objectsWhere:@"age > 28"] sortedResultsUsingProperty:@"age" ascending:YES];

    // query/order on array
    RLMAssertCount(all, 1U, @"age == 27");
    RLMAssertCount(all, 0U, @"age == 28");
    some = [some sortedResultsUsingProperty:@"age" ascending:NO];
    XCTAssertEqualObjects([some[0] name], @"Ari", @"Ari should be first results");
}

- (void)verifySort:(RLMRealm *)realm column:(NSString *)column ascending:(BOOL)ascending expected:(id)val {
    RLMResults *results = [[AllTypesObject allObjectsInRealm:realm] sortedResultsUsingProperty:column ascending:ascending];
    AllTypesObject *obj = results[0];
    XCTAssertEqualObjects(obj[column], val, @"Array not sorted as expected - %@ != %@", obj[column], val);

    RLMArray *ar = (RLMArray *)[[[ArrayOfAllTypesObject allObjectsInRealm:realm] firstObject] array];
    results = [ar sortedResultsUsingProperty:column ascending:ascending];
    obj = results[0];
    XCTAssertEqualObjects(obj[column], val, @"Array not sorted as expected - %@ != %@", obj[column], val);
}

- (void)verifySortWithAccuracy:(RLMRealm *)realm column:(NSString *)column ascending:(BOOL)ascending getter:(double(^)(id))getter expected:(double)val accuracy:(double)accuracy {
    // test TableView query
    RLMResults *results = [[AllTypesObject allObjectsInRealm:realm] sortedResultsUsingProperty:column ascending:ascending];
    XCTAssertEqualWithAccuracy(getter(results[0][column]), val, accuracy, @"Array not sorted as expected");

    // test LinkView query
    RLMArray *ar = (RLMArray *)[[[ArrayOfAllTypesObject allObjectsInRealm:realm] firstObject] array];
    results = [ar sortedResultsUsingProperty:column ascending:ascending];
    XCTAssertEqualWithAccuracy(getter(results[0][column]), val, accuracy, @"Array not sorted as expected");
}

- (void)testQuerySorting
{
    RLMRealm *realm = [RLMRealm defaultRealm];

    NSDate *date1 = [NSDate date];
    NSDate *date2 = [date1 dateByAddingTimeInterval:1];
    NSDate *date3 = [date2 dateByAddingTimeInterval:1];
    NSDate *date33 = [date3 dateByAddingTimeInterval:1];

    [realm beginWriteTransaction];
    ArrayOfAllTypesObject *arrayOfAll = [ArrayOfAllTypesObject createInRealm:realm withValue:@{}];

    StringObject *stringObj = [StringObject new];
    stringObj.stringCol = @"string";

    [arrayOfAll.array addObject:[AllTypesObject createInRealm:realm withValue:@[@YES, @1, @1.0f, @1.0, @"a", [@"a" dataUsingEncoding:NSUTF8StringEncoding], date1, @YES, @1, @1, stringObj]]];
    [arrayOfAll.array addObject:[AllTypesObject createInRealm:realm withValue:@[@YES, @2, @2.0f, @2.0, @"b", [@"b" dataUsingEncoding:NSUTF8StringEncoding], date2, @YES, @2, @"mixed", stringObj]]];
    [arrayOfAll.array addObject:[AllTypesObject createInRealm:realm withValue:@[@NO, @3, @3.0f, @3.0, @"c", [@"c" dataUsingEncoding:NSUTF8StringEncoding], date3, @YES, @3, @"mixed", stringObj]]];
    [arrayOfAll.array addObject:[AllTypesObject createInRealm:realm withValue:@[@NO, @33, @3.3f, @3.3, @"cc", [@"cc" dataUsingEncoding:NSUTF8StringEncoding], date33, @NO, @3, @"mixed", stringObj]]];

    [realm commitWriteTransaction];


    //////////// sort by boolCol
    [self verifySort:realm column:@"boolCol" ascending:YES expected:@NO];
    [self verifySort:realm column:@"boolCol" ascending:NO expected:@YES];

    //////////// sort by intCol
    [self verifySort:realm column:@"intCol" ascending:YES expected:@1];
    [self verifySort:realm column:@"intCol" ascending:NO expected:@33];

    //////////// sort by dateCol
    double (^dateGetter)(id) = ^(NSDate *d) { return d.timeIntervalSince1970; };
    [self verifySortWithAccuracy:realm column:@"dateCol" ascending:YES getter:dateGetter expected:date1.timeIntervalSince1970 accuracy:1];
    [self verifySortWithAccuracy:realm column:@"dateCol" ascending:NO getter:dateGetter expected:date33.timeIntervalSince1970 accuracy:1];

    //////////// sort by doubleCol
    double (^doubleGetter)(id) = ^(NSNumber *n) { return n.doubleValue; };
    [self verifySortWithAccuracy:realm column:@"doubleCol" ascending:YES getter:doubleGetter expected:1.0 accuracy:0.0000001];
    [self verifySortWithAccuracy:realm column:@"doubleCol" ascending:NO getter:doubleGetter expected:3.3 accuracy:0.0000001];

    //////////// sort by floatCol
    [self verifySortWithAccuracy:realm column:@"floatCol" ascending:YES getter:doubleGetter expected:1.0 accuracy:0.0000001];
    [self verifySortWithAccuracy:realm column:@"floatCol" ascending:NO getter:doubleGetter expected:3.3 accuracy:0.0000001];

    //////////// sort by stringCol
    [self verifySort:realm column:@"stringCol" ascending:YES expected:@"a"];
    [self verifySort:realm column:@"stringCol" ascending:NO expected:@"cc"];

    // sort by mixed column
    RLMAssertThrowsWithReasonMatching([[AllTypesObject allObjects] sortedResultsUsingProperty:@"mixedCol" ascending:YES], @"'mixedCol' .* 'AllTypesObject': sorting is only supported .* type any");
    XCTAssertThrows([arrayOfAll.array sortedResultsUsingProperty:@"mixedCol" ascending:NO]);

    // sort invalid name
    RLMAssertThrowsWithReasonMatching([[AllTypesObject allObjects] sortedResultsUsingProperty:@"invalidCol" ascending:YES], @"'invalidCol'.* 'AllTypesObject'.* not found");
    XCTAssertThrows([arrayOfAll.array sortedResultsUsingProperty:@"invalidCol" ascending:NO]);

    // sort on key path
    RLMAssertThrowsWithReasonMatching([[AllTypesObject allObjects] sortedResultsUsingProperty:@"key.path" ascending:YES], @"key paths is not supported");
    XCTAssertThrows([arrayOfAll.array sortedResultsUsingProperty:@"key.path" ascending:NO]);
}

- (void)testSortByMultipleColumns {
    RLMRealm *realm = [RLMRealm defaultRealm];
    [realm beginWriteTransaction];
    DogObject *a1 = [DogObject createInDefaultRealmWithValue:@[@"a", @1]];
    DogObject *a2 = [DogObject createInDefaultRealmWithValue:@[@"a", @2]];
    DogObject *b1 = [DogObject createInDefaultRealmWithValue:@[@"b", @1]];
    DogObject *b2 = [DogObject createInDefaultRealmWithValue:@[@"b", @2]];
    [realm commitWriteTransaction];

    bool (^checkOrder)(NSArray *, NSArray *, NSArray *) = ^bool(NSArray *properties, NSArray *ascending, NSArray *dogs) {
        NSArray *sort = @[[RLMSortDescriptor sortDescriptorWithProperty:properties[0] ascending:[ascending[0] boolValue]],
                          [RLMSortDescriptor sortDescriptorWithProperty:properties[1] ascending:[ascending[1] boolValue]]];
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

- (void)testSortedLinkViewWithDeletion {
    RLMRealm *realm = [RLMRealm defaultRealm];

    NSDate *date1 = [NSDate date];
    NSDate *date2 = [date1 dateByAddingTimeInterval:1];
    NSDate *date3 = [date2 dateByAddingTimeInterval:1];
    NSDate *date33 = [date3 dateByAddingTimeInterval:1];

    [realm beginWriteTransaction];
    ArrayOfAllTypesObject *arrayOfAll = [ArrayOfAllTypesObject createInRealm:realm withValue:@{}];

    StringObject *stringObj = [StringObject new];
    stringObj.stringCol = @"string";

    [arrayOfAll.array addObject:[AllTypesObject createInRealm:realm withValue:@[@YES, @1, @1.0f, @1.0, @"a", [@"a" dataUsingEncoding:NSUTF8StringEncoding], date1, @YES, @1, @1, stringObj]]];
    [arrayOfAll.array addObject:[AllTypesObject createInRealm:realm withValue:@[@YES, @2, @2.0f, @2.0, @"b", [@"b" dataUsingEncoding:NSUTF8StringEncoding], date2, @YES, @2, @"mixed", stringObj]]];
    [arrayOfAll.array addObject:[AllTypesObject createInRealm:realm withValue:@[@NO, @3, @3.0f, @3.0, @"c", [@"c" dataUsingEncoding:NSUTF8StringEncoding], date3, @YES, @3, @"mixed", stringObj]]];
    [arrayOfAll.array addObject:[AllTypesObject createInRealm:realm withValue:@[@NO, @33, @3.3f, @3.3, @"cc", [@"cc" dataUsingEncoding:NSUTF8StringEncoding], date33, @NO, @3, @"mixed", stringObj]]];

    [realm commitWriteTransaction];

    RLMResults *results = [arrayOfAll.array sortedResultsUsingProperty:@"stringCol" ascending:NO];
    XCTAssertEqualObjects([results[0] stringCol], @"cc");

    // delete cc, add d results should update
    [realm transactionWithBlock:^{
        [arrayOfAll.array removeObjectAtIndex:3];

        // create extra alltypesobject
        [arrayOfAll.array addObject:[AllTypesObject createInRealm:realm withValue:@[@YES, @1, @1.0f, @1.0, @"d", [@"d" dataUsingEncoding:NSUTF8StringEncoding], date1, @YES, @((long)1), @1, stringObj]]];
    }];
    XCTAssertEqualObjects([results[0] stringCol], @"d");
    XCTAssertEqualObjects([results[1] stringCol], @"c");

    // delete from realm should be removed from results
    [realm transactionWithBlock:^{
        [realm deleteObject:arrayOfAll.array.lastObject];
    }];
    XCTAssertEqualObjects([results[0] stringCol], @"c");
}

- (void)testQueryingSortedQueryPreservesOrder {
    RLMRealm *realm = [RLMRealm defaultRealm];

    [realm beginWriteTransaction];
    for (int i = 0; i < 5; ++i) {
        [IntObject createInRealm:realm withValue:@[@(i)]];
    }

    ArrayPropertyObject *array = [ArrayPropertyObject createInRealm:realm withValue:@[@"name", @[], [IntObject allObjects]]];
    [realm commitWriteTransaction];

    RLMResults *asc = [IntObject.allObjects sortedResultsUsingProperty:@"intCol" ascending:YES];
    RLMResults *desc = [IntObject.allObjects sortedResultsUsingProperty:@"intCol" ascending:NO];

    // sanity check; would work even without sort order being preserved
    XCTAssertEqual(2, [[[asc objectsWhere:@"intCol >= 2"] firstObject] intCol]);

    // check query on allObjects and query on query
    XCTAssertEqual(4, [[[desc objectsWhere:@"intCol >= 2"] firstObject] intCol]);
    XCTAssertEqual(3, [[[[desc objectsWhere:@"intCol >= 2"] objectsWhere:@"intCol < 4"] firstObject] intCol]);

    // same thing but on an linkview
    asc = [array.intArray sortedResultsUsingProperty:@"intCol" ascending:YES];
    desc = [array.intArray sortedResultsUsingProperty:@"intCol" ascending:NO];

    XCTAssertEqual(2, [[[asc objectsWhere:@"intCol >= 2"] firstObject] intCol]);
    XCTAssertEqual(4, [[[desc objectsWhere:@"intCol >= 2"] firstObject] intCol]);
    XCTAssertEqual(3, [[[[desc objectsWhere:@"intCol >= 2"] objectsWhere:@"intCol < 4"] firstObject] intCol]);
}

- (void)testTwoColumnComparison
{
    RLMRealm *realm = [RLMRealm defaultRealm];

    [realm beginWriteTransaction];

    [self.queryObjectClass createInRealm:realm withValue:@[@YES, @YES, @1, @2, @23.0f, @1.7f,  @0.0,  @5.55, @"a", @"a"]];
    [self.queryObjectClass createInRealm:realm withValue:@[@YES, @NO,  @1, @3, @-5.3f, @4.21f, @1.0,  @4.44, @"a", @"A"]];
    [self.queryObjectClass createInRealm:realm withValue:@[@NO,  @NO,  @2, @2, @1.0f,  @3.55f, @99.9, @6.66, @"a", @"ab"]];
    [self.queryObjectClass createInRealm:realm withValue:@[@NO,  @YES, @3, @6, @4.21f, @1.0f,  @1.0,  @7.77, @"a", @"AB"]];
    [self.queryObjectClass createInRealm:realm withValue:@[@YES, @YES, @4, @5, @23.0f, @23.0f, @7.4,  @8.88, @"a", @"b"]];
    [self.queryObjectClass createInRealm:realm withValue:@[@YES, @NO,  @15, @8, @1.0f,  @66.0f, @1.01, @9.99, @"a", @"ba"]];
    [self.queryObjectClass createInRealm:realm withValue:@[@NO,  @YES, @15, @15, @1.0f,  @66.0f, @1.01, @9.99, @"a", @"BA"]];

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
}

- (void)testBooleanPredicate
{
    RLMAssertCount(BoolObject, 0U, @"boolCol == TRUE");
    RLMAssertCount(BoolObject, 0U, @"boolCol != TRUE");

    if (self.isNull) {
        RLMAssertCount(BoolObject, 0U, @"boolCol == NULL");
        RLMAssertCount(BoolObject, 0U, @"boolCol != NULL");
    }
    else {
        XCTAssertThrows([BoolObject objectsWhere:@"boolCol == NULL"]);
        XCTAssertThrows([BoolObject objectsWhere:@"boolCol != NULL"]);
    }

    XCTAssertThrowsSpecificNamed([BoolObject objectsWhere:@"boolCol >= TRUE"],
                                 NSException,
                                 @"Invalid operator type",
                                 @"Invalid operator in bool predicate.");
}

- (void)testStringBeginsWith
{
    RLMRealm *realm = [RLMRealm defaultRealm];

    [realm beginWriteTransaction];
    StringObject *so = [StringObject createInRealm:realm withValue:(@[@"abc"])];
    [AllTypesObject createInRealm:realm withValue:@[@YES, @1, @1.0f, @1.0, @"a", [@"a" dataUsingEncoding:NSUTF8StringEncoding], NSDate.date, @YES, @1LL, @1, so]];
    if (self.isNull) {
        so = [StringObject createInRealm:realm withValue:@[NSNull.null]];
        [AllTypesObject createInRealm:realm withValue:@[@YES, @1, @1.0f, @1.0, @"a", [@"a" dataUsingEncoding:NSUTF8StringEncoding], NSDate.date, @YES, @1LL, @1, so]];
    }
    [realm commitWriteTransaction];

    RLMAssertCount(StringObject, 1U, @"stringCol BEGINSWITH 'a'");
    RLMAssertCount(StringObject, 1U, @"stringCol BEGINSWITH 'ab'");
    RLMAssertCount(StringObject, 1U, @"stringCol BEGINSWITH 'abc'");
    RLMAssertCount(StringObject, 0U, @"stringCol BEGINSWITH 'abcd'");
    RLMAssertCount(StringObject, 0U, @"stringCol BEGINSWITH 'abd'");
    RLMAssertCount(StringObject, 0U, @"stringCol BEGINSWITH 'c'");
    RLMAssertCount(StringObject, 0U, @"stringCol BEGINSWITH 'A'");
    RLMAssertCount(StringObject, 1U, @"stringCol BEGINSWITH[c] 'a'");
    RLMAssertCount(StringObject, 1U, @"stringCol BEGINSWITH[c] 'A'");

    RLMAssertCount(AllTypesObject, 1U, @"objectCol.stringCol BEGINSWITH 'a'");
    RLMAssertCount(AllTypesObject, 0U, @"objectCol.stringCol BEGINSWITH 'c'");
    RLMAssertCount(AllTypesObject, 0U, @"objectCol.stringCol BEGINSWITH 'A'");
    RLMAssertCount(AllTypesObject, 1U, @"objectCol.stringCol BEGINSWITH[c] 'a'");
    RLMAssertCount(AllTypesObject, 1U, @"objectCol.stringCol BEGINSWITH[c] 'A'");
}

- (void)testStringEndsWith
{
    RLMRealm *realm = [RLMRealm defaultRealm];

    [realm beginWriteTransaction];
    StringObject *so = [StringObject createInRealm:realm withValue:(@[@"abc"])];
    [AllTypesObject createInRealm:realm withValue:@[@YES, @1, @1.0f, @1.0, @"a", [@"a" dataUsingEncoding:NSUTF8StringEncoding], NSDate.date, @YES, @1LL, @1, so]];
    if (self.isNull) {
        so = [StringObject createInRealm:realm withValue:@[NSNull.null]];
        [AllTypesObject createInRealm:realm withValue:@[@YES, @1, @1.0f, @1.0, @"a", [@"a" dataUsingEncoding:NSUTF8StringEncoding], NSDate.date, @YES, @1LL, @1, so]];
    }
    [realm commitWriteTransaction];

    RLMAssertCount(StringObject, 1U, @"stringCol ENDSWITH 'c'");
    RLMAssertCount(StringObject, 1U, @"stringCol ENDSWITH 'bc'");
    RLMAssertCount(StringObject, 1U, @"stringCol ENDSWITH 'abc'");
    RLMAssertCount(StringObject, 0U, @"stringCol ENDSWITH 'aabc'");
    RLMAssertCount(StringObject, 0U, @"stringCol ENDSWITH 'bbc'");
    RLMAssertCount(StringObject, 0U, @"stringCol ENDSWITH 'a'");
    RLMAssertCount(StringObject, 0U, @"stringCol ENDSWITH 'C'");
    RLMAssertCount(StringObject, 1U, @"stringCol ENDSWITH[c] 'c'");
    RLMAssertCount(StringObject, 1U, @"stringCol ENDSWITH[c] 'C'");

    RLMAssertCount(AllTypesObject, 1U, @"objectCol.stringCol ENDSWITH 'c'");
    RLMAssertCount(AllTypesObject, 0U, @"objectCol.stringCol ENDSWITH 'a'");
    RLMAssertCount(AllTypesObject, 0U, @"objectCol.stringCol ENDSWITH 'C'");
    RLMAssertCount(AllTypesObject, 1U, @"objectCol.stringCol ENDSWITH[c] 'c'");
    RLMAssertCount(AllTypesObject, 1U, @"objectCol.stringCol ENDSWITH[c] 'C'");
}

- (void)testStringContains
{
    RLMRealm *realm = [RLMRealm defaultRealm];

    [realm beginWriteTransaction];
    StringObject *so = [StringObject createInRealm:realm withValue:(@[@"abc"])];
    [AllTypesObject createInRealm:realm withValue:@[@YES, @1, @1.0f, @1.0, @"a", [@"a" dataUsingEncoding:NSUTF8StringEncoding], NSDate.date, @YES, @1LL, @1, so]];
    if (self.isNull) {
        so = [StringObject createInRealm:realm withValue:@[NSNull.null]];
        [AllTypesObject createInRealm:realm withValue:@[@YES, @1, @1.0f, @1.0, @"a", [@"a" dataUsingEncoding:NSUTF8StringEncoding], NSDate.date, @YES, @1LL, @1, so]];
    }
    [realm commitWriteTransaction];

    RLMAssertCount(StringObject, 1U, @"stringCol CONTAINS 'a'");
    RLMAssertCount(StringObject, 1U, @"stringCol CONTAINS 'b'");
    RLMAssertCount(StringObject, 1U, @"stringCol CONTAINS 'c'");
    RLMAssertCount(StringObject, 1U, @"stringCol CONTAINS 'ab'");
    RLMAssertCount(StringObject, 1U, @"stringCol CONTAINS 'bc'");
    RLMAssertCount(StringObject, 1U, @"stringCol CONTAINS 'abc'");
    RLMAssertCount(StringObject, 0U, @"stringCol CONTAINS 'd'");
    RLMAssertCount(StringObject, 0U, @"stringCol CONTAINS 'aabc'");
    RLMAssertCount(StringObject, 0U, @"stringCol CONTAINS 'bbc'");

    RLMAssertCount(StringObject, 0U, @"stringCol CONTAINS 'C'");
    RLMAssertCount(StringObject, 1U, @"stringCol CONTAINS[c] 'c'");
    RLMAssertCount(StringObject, 1U, @"stringCol CONTAINS[c] 'C'");

    RLMAssertCount(AllTypesObject, 0U, @"objectCol.stringCol CONTAINS 'd'");
    RLMAssertCount(AllTypesObject, 1U, @"objectCol.stringCol CONTAINS 'c'");
    RLMAssertCount(AllTypesObject, 0U, @"objectCol.stringCol CONTAINS 'C'");
    RLMAssertCount(AllTypesObject, 1U, @"objectCol.stringCol CONTAINS[c] 'c'");
    RLMAssertCount(AllTypesObject, 1U, @"objectCol.stringCol CONTAINS[c] 'C'");
}

- (void)testStringEquality
{
    RLMRealm *realm = [RLMRealm defaultRealm];

    [realm beginWriteTransaction];
    StringObject *so = [StringObject createInRealm:realm withValue:(@[@"abc"])];
    [AllTypesObject createInRealm:realm withValue:@[@YES, @1, @1.0f, @1.0, @"a", [@"a" dataUsingEncoding:NSUTF8StringEncoding], NSDate.date, @YES, @1LL, @1, so]];
    [realm commitWriteTransaction];

    RLMAssertCount(StringObject, 1U, @"stringCol == 'abc'");
    RLMAssertCount(StringObject, 1U, @"stringCol != 'def'");
    RLMAssertCount(StringObject, 1U, @"stringCol ==[c] 'abc'");
    RLMAssertCount(StringObject, 1U, @"stringCol ==[c] 'ABC'");

    RLMAssertCount(StringObject, 0U, @"stringCol != 'abc'");
    RLMAssertCount(StringObject, 0U, @"stringCol == 'def'");
    RLMAssertCount(StringObject, 0U, @"stringCol == 'ABC'");

    RLMAssertCount(AllTypesObject, 1U, @"objectCol.stringCol == 'abc'");
    RLMAssertCount(AllTypesObject, 1U, @"objectCol.stringCol != 'def'");

    RLMAssertCount(AllTypesObject, 1U, @"objectCol.stringCol ==[c] 'abc'");
    RLMAssertCount(AllTypesObject, 1U, @"objectCol.stringCol ==[c] 'ABC'");

    RLMAssertCount(AllTypesObject, 0U, @"objectCol.stringCol != 'abc'");
    RLMAssertCount(AllTypesObject, 0U, @"objectCol.stringCol == 'def'");
    RLMAssertCount(AllTypesObject, 0U, @"objectCol.stringCol == 'ABC'");
}

- (void)testFloatQuery
{
    RLMRealm *realm = [RLMRealm defaultRealm];

    [realm beginWriteTransaction];
    [FloatObject createInRealm:realm withValue:@[@1.7f]];
    [realm commitWriteTransaction];

    RLMAssertCount(FloatObject, 1U, @"floatCol > 1");
    RLMAssertCount(FloatObject, 1U, @"floatCol > %d", 1);
    RLMAssertCount(FloatObject, 1U, @"floatCol = 1.7");
    RLMAssertCount(FloatObject, 1U, @"floatCol = %f", 1.7f);
    RLMAssertCount(FloatObject, 1U, @"floatCol > 1.0");
    RLMAssertCount(FloatObject, 1U, @"floatCol >= 1.0");
    RLMAssertCount(FloatObject, 0U, @"floatCol < 1.0");
    RLMAssertCount(FloatObject, 0U, @"floatCol <= 1.0");
    RLMAssertCount(FloatObject, 1U, @"floatCol BETWEEN %@", @[@1.0, @2.0]);
    RLMAssertCount(FloatObject, 1U, @"floatCol = %e", 1.7);
    RLMAssertCount(FloatObject, 0U, @"floatCol == %f", FLT_MAX);
    XCTAssertThrows([FloatObject objectsInRealm:realm where:@"floatCol = 3.5e+38"], @"Too large to be a float");
    XCTAssertThrows([FloatObject objectsInRealm:realm where:@"floatCol = -3.5e+38"], @"Too small to be a float");
}

- (void)testLiveQueriesInsideTransaction
{
    RLMRealm *realm = [RLMRealm defaultRealm];

    [realm beginWriteTransaction];
    {
        [self.queryObjectClass createInRealm:realm withValue:@[@YES, @YES, @1, @2, @23.0f, @1.7f,  @0.0,  @5.55, @"", @""]];

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
        QueryObject *q1 = [self.queryObjectClass createInRealm:realm withValue:@[@NO, @YES, @1, @2, @23.0f, @1.7f,  @0.0,  @5.55, @"", @""]];
        XCTAssertEqual(resultsQuery.count, 0U);
        XCTAssertEqual(resultsTableView.count, 0U);

        // Change object to match query
        q1[@"bool1"] = @YES;
        XCTAssertEqual(resultsQuery.count, 1U);
        XCTAssertEqual(resultsTableView.count, 1U);

        // Add another object that matches
        [self.queryObjectClass createInRealm:realm withValue:@[@YES, @NO,  @1, @3, @-5.3f, @4.21f, @1.0,  @4.44, @"", @""]];
        XCTAssertEqual(resultsQuery.count, 2U);
        XCTAssertEqual(resultsTableView.count, 2U);
    }
    [realm commitWriteTransaction];
}

- (void)testLiveQueriesBetweenTransactions
{
    RLMRealm *realm = [RLMRealm defaultRealm];

    [realm beginWriteTransaction];
    [self.queryObjectClass createInRealm:realm withValue:@[@YES, @YES, @1, @2, @23.0f, @1.7f,  @0.0,  @5.55, @"", @""]];
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
    QueryObject *q1 = [self.queryObjectClass createInRealm:realm withValue:@[@NO, @YES, @1, @2, @23.0f, @1.7f,  @0.0,  @5.55, @"", @""]];
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
    [self.queryObjectClass createInRealm:realm withValue:@[@YES, @NO,  @1, @3, @-5.3f, @4.21f, @1.0,  @4.44, @"", @""]];
    [realm commitWriteTransaction];

    XCTAssertEqual(resultsQuery.count, 2U);
    XCTAssertEqual(resultsTableView.count, 2U);
}

- (void)makeDogWithName:(NSString *)name owner:(NSString *)ownerName {
    RLMRealm *realm = [RLMRealm defaultRealm];

    OwnerObject *owner = [[OwnerObject alloc] init];
    owner.name = ownerName;
    owner.dog = [[DogObject alloc] init];
    owner.dog.dogName = name;

    [realm beginWriteTransaction];
    [realm addObject:owner];
    [realm commitWriteTransaction];
}

- (void)makeDogWithAge:(int)age owner:(NSString *)ownerName {
    RLMRealm *realm = [RLMRealm defaultRealm];

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
}

- (void)testLinkQueryDifferentRealmsThrows
{
    RLMRealm *testRealm = [self realmWithTestPath];
    [self makeDogWithName:@"Harvie" owner:@"Tim"];

    RLMRealm *defaultRealm = [RLMRealm defaultRealm];
    DogObject *dog = [[DogObject alloc] init];
    dog.dogName = @"Fido";
    [defaultRealm beginWriteTransaction];
    [defaultRealm addObject:dog];
    [defaultRealm commitWriteTransaction];

    XCTAssertThrows(([OwnerObject objectsInRealm:testRealm where:@"dog = %@", dog]));
}

- (void)testLinkQueryString
{
    RLMRealm *realm = [RLMRealm defaultRealm];

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

- (void)testLinkQueryAllTypes
{
    RLMRealm *realm = [RLMRealm defaultRealm];

    NSDate *now = [NSDate dateWithTimeIntervalSince1970:100000];

    LinkToAllTypesObject *linkToAllTypes = [[LinkToAllTypesObject alloc] init];
    linkToAllTypes.allTypesCol = [[AllTypesObject alloc] init];
    linkToAllTypes.allTypesCol.boolCol = YES;
    linkToAllTypes.allTypesCol.intCol = 1;
    linkToAllTypes.allTypesCol.floatCol = 1.1f;
    linkToAllTypes.allTypesCol.doubleCol = 1.11;
    linkToAllTypes.allTypesCol.stringCol = @"string";
    linkToAllTypes.allTypesCol.binaryCol = [NSData dataWithBytes:"a" length:1];
    linkToAllTypes.allTypesCol.dateCol = now;
    linkToAllTypes.allTypesCol.cBoolCol = YES;
    linkToAllTypes.allTypesCol.longCol = 11;
    linkToAllTypes.allTypesCol.mixedCol = @0;
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

    RLMAssertCount(LinkToAllTypesObject, 1U, @"allTypesCol.longCol = 11");
    RLMAssertCount(LinkToAllTypesObject, 0U, @"allTypesCol.longCol != 11");

    RLMAssertCount(LinkToAllTypesObject, 1U, @"allTypesCol.dateCol = %@", now);
    RLMAssertCount(LinkToAllTypesObject, 0U, @"allTypesCol.dateCol != %@", now);
}

- (void)testLinkQueryMany
{
    RLMRealm *realm = [RLMRealm defaultRealm];

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

- (void)testMultiLevelLinkQuery
{
    RLMRealm *realm = [RLMRealm defaultRealm];

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
    XCTAssertThrows(([CircleObject objectsInRealm:realm where:@"next.next = %@", circle]));
    XCTAssertTrue([circle.next.next.next.next isEqualToObject:[CircleObject objectsInRealm:realm where:@"next = nil"].firstObject]);
}

- (void)testArrayMultiLevelLinkQuery
{
    RLMRealm *realm = [RLMRealm defaultRealm];

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

- (void)testQueryWithObjects
{
    RLMRealm *realm = [RLMRealm defaultRealm];

    NSDate *date1 = [NSDate date];
    NSDate *date2 = [date1 dateByAddingTimeInterval:1];
    NSDate *date3 = [date2 dateByAddingTimeInterval:1];

    [realm beginWriteTransaction];

    StringObject *stringObj0 = [StringObject createInRealm:realm withValue:@[@"string0"]];
    StringObject *stringObj1 = [StringObject createInRealm:realm withValue:@[@"string1"]];
    StringObject *stringObj2 = [StringObject createInRealm:realm withValue:@[@"string2"]];

    AllTypesObject *obj0 = [AllTypesObject createInRealm:realm withValue:@[@YES, @1, @1.0f, @1.0, @"a", [@"a" dataUsingEncoding:NSUTF8StringEncoding], date1, @YES, @1LL, @1, stringObj0]];
    AllTypesObject *obj1 = [AllTypesObject createInRealm:realm withValue:@[@YES, @2, @2.0f, @2.0, @"b", [@"b" dataUsingEncoding:NSUTF8StringEncoding], date2, @YES, @2LL, @"mixed", stringObj1]];
    AllTypesObject *obj2 = [AllTypesObject createInRealm:realm withValue:@[@NO, @3, @3.0f, @3.0, @"c", [@"c" dataUsingEncoding:NSUTF8StringEncoding], date3, @YES, @3LL, @"mixed", stringObj0]];
    AllTypesObject *obj3 = [AllTypesObject createInRealm:realm withValue:@[@NO, @3, @3.0f, @3.0, @"c", [@"c" dataUsingEncoding:NSUTF8StringEncoding], date3, @YES, @3LL, @"mixed", stringObj2]];
    AllTypesObject *obj4 = [AllTypesObject createInRealm:realm withValue:@[@NO, @3, @3.0f, @3.0, @"c", [@"c" dataUsingEncoding:NSUTF8StringEncoding], date3, @YES, @34359738368LL, @"mixed", NSNull.null]];

    [ArrayOfAllTypesObject createInDefaultRealmWithValue:@[@[obj0, obj1]]];
    [ArrayOfAllTypesObject createInDefaultRealmWithValue:@[@[obj1]]];
    [ArrayOfAllTypesObject createInDefaultRealmWithValue:@[@[obj0, obj2, obj3]]];
    [ArrayOfAllTypesObject createInDefaultRealmWithValue:@[@[obj4]]];

    [realm commitWriteTransaction];

    // simple queries
    RLMAssertCount(AllTypesObject, 2U, @"objectCol = %@", stringObj0);
    RLMAssertCount(AllTypesObject, 1U, @"objectCol = %@", stringObj1);
    RLMAssertCount(AllTypesObject, 1U, @"objectCol = nil");
    RLMAssertCount(AllTypesObject, 4U, @"objectCol != nil");
    RLMAssertCount(AllTypesObject, 3U, @"objectCol != %@", stringObj0);

    RLMAssertCount(AllTypesObject, 1U, @"longCol = %lli", 34359738368);

    RLMAssertCount(AllTypesObject, 1U, @"longCol BETWEEN %@", @[@34359738367LL, @34359738369LL]);

    // check for ANY object in array
    RLMAssertCount(ArrayOfAllTypesObject, 2U, @"ANY array = %@", obj0);
    RLMAssertCount(ArrayOfAllTypesObject, 2U, @"ANY array != %@", obj1);
    RLMAssertCount(ArrayOfAllTypesObject, 2U, @"NONE array = %@", obj0);
    RLMAssertCount(ArrayOfAllTypesObject, 2U, @"NONE array != %@", obj1);
    XCTAssertThrows(([ArrayOfAllTypesObject objectsWhere:@"array = %@", obj0].count));
    XCTAssertThrows(([ArrayOfAllTypesObject objectsWhere:@"array != %@", obj0].count));
}

- (void)testCompoundOrQuery {
    RLMRealm *realm = [RLMRealm defaultRealm];

    [realm beginWriteTransaction];
    [PersonObject createInRealm:realm withValue:@[@"Tim", @29]];
    [PersonObject createInRealm:realm withValue:@[@"Ari", @33]];
    [realm commitWriteTransaction];

    RLMAssertCount(PersonObject, 2U, @"name == 'Ari' or age < 30");
    RLMAssertCount(PersonObject, 1U, @"name == 'Ari' or age > 40");
}

- (void)testCompoundAndQuery {
    RLMRealm *realm = [RLMRealm defaultRealm];

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

    XCTAssertEqual(normalCount, [[self evaluate:[class objectsWithPredicate:predicate]] count]);

    predicate = [NSCompoundPredicate notPredicateWithSubpredicate:predicate];
    XCTAssertEqual(notCount, [[self evaluate:[class objectsWithPredicate:predicate]] count]);
}

- (void)testINPredicate
{
    RLMRealm *realm = [RLMRealm defaultRealm];

    [realm beginWriteTransaction];
    StringObject *so = [StringObject createInRealm:realm withValue:(@[@"abc"])];
    [AllTypesObject createInRealm:realm withValue:@[@YES, @1, @1.0f, @1.0, @"abc", [@"a" dataUsingEncoding:NSUTF8StringEncoding], [NSDate dateWithTimeIntervalSince1970:1], @YES, @1LL, @1, so]];
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
    [self testClass:[AllTypesObject class] withNormalCount:1 notCount:0 where:@"floatCol IN {1}"];
    [self testClass:[AllTypesObject class] withNormalCount:1 notCount:0 where:@"floatCol IN {1, 2}"];

    // double
    [self testClass:[AllTypesObject class] withNormalCount:0 notCount:1 where:@"doubleCol IN {0, 2, 3}"];
    [self testClass:[AllTypesObject class] withNormalCount:1 notCount:0 where:@"doubleCol IN {1}"];
    [self testClass:[AllTypesObject class] withNormalCount:1 notCount:0 where:@"doubleCol IN {1, 2}"];

    // NSString
    [self testClass:[AllTypesObject class] withNormalCount:1 notCount:0 where:@"stringCol IN {'abc'}"];
    [self testClass:[AllTypesObject class] withNormalCount:0 notCount:1 where:@"stringCol IN {'def'}"];
    [self testClass:[AllTypesObject class] withNormalCount:0 notCount:1 where:@"stringCol IN {'ABC'}"];
    [self testClass:[AllTypesObject class] withNormalCount:1 notCount:0 where:@"stringCol IN[c] {'abc'}"];
    [self testClass:[AllTypesObject class] withNormalCount:1 notCount:0 where:@"stringCol IN[c] {'ABC'}"];

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
    [self testClass:[AllTypesObject class] withNormalCount:1 notCount:0 where:@"longCol IN {1}"];
    [self testClass:[AllTypesObject class] withNormalCount:1 notCount:0 where:@"longCol IN {1, 2}"];

    // mixed
    // FIXME: Support IN predicates with mixed properties
    XCTAssertThrows([AllTypesObject objectsWhere:@"mixedCol IN {0, 2, 3}"]);
    XCTAssertThrows([AllTypesObject objectsWhere:@"NOT(mixedCol IN {0, 2, 3})"]);

    // string subobject
    [self testClass:[AllTypesObject class] withNormalCount:1 notCount:0 where:@"objectCol.stringCol IN {'abc'}"];
    [self testClass:[AllTypesObject class] withNormalCount:0 notCount:1 where:@"objectCol.stringCol IN {'def'}"];
    [self testClass:[AllTypesObject class] withNormalCount:0 notCount:1 where:@"objectCol.stringCol IN {'ABC'}"];
    [self testClass:[AllTypesObject class] withNormalCount:1 notCount:0 where:@"objectCol.stringCol IN[c] {'abc'}"];
    [self testClass:[AllTypesObject class] withNormalCount:1 notCount:0 where:@"objectCol.stringCol IN[c] {'ABC'}"];

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
    [self testClass:[AllTypesObject class] withNormalCount:1U notCount:0U where:@"floatCol IN %@", @[@1]];
    [self testClass:[AllTypesObject class] withNormalCount:1U notCount:0U where:@"floatCol IN %@", @[@1, @2]];

    // double
    [self testClass:[AllTypesObject class] withNormalCount:0U notCount:1U where:@"doubleCol IN %@", @[@0, @2, @3]];
    [self testClass:[AllTypesObject class] withNormalCount:1U notCount:0U where:@"doubleCol IN %@", @[@1]];
    [self testClass:[AllTypesObject class] withNormalCount:1U notCount:0U where:@"doubleCol IN %@", @[@1, @2]];

    // NSString
    [self testClass:[AllTypesObject class] withNormalCount:1U notCount:0U where:@"stringCol IN %@", @[@"abc"]];
    [self testClass:[AllTypesObject class] withNormalCount:0U notCount:1U where:@"stringCol IN %@", @[@"def"]];
    [self testClass:[AllTypesObject class] withNormalCount:0U notCount:1U where:@"stringCol IN %@", @[@"ABC"]];
    [self testClass:[AllTypesObject class] withNormalCount:1U notCount:0U where:@"stringCol IN[c] %@", @[@"abc"]];
    [self testClass:[AllTypesObject class] withNormalCount:1U notCount:0U where:@"stringCol IN[c] %@", @[@"ABC"]];

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
    [self testClass:[AllTypesObject class] withNormalCount:1U notCount:0U where:@"longCol IN %@", @[@1]];
    [self testClass:[AllTypesObject class] withNormalCount:1U notCount:0U where:@"longCol IN %@", @[@1, @2]];

    // mixed
    // FIXME: Support IN predicates with mixed properties
    XCTAssertThrows(([AllTypesObject objectsWhere:@"mixedCol IN %@", @[@0, @2, @3]]));
    XCTAssertThrows(([AllTypesObject objectsWhere:@"NOT(mixedCol IN %@)", @[@0, @2, @3]]));

    // string subobject
    [self testClass:[AllTypesObject class] withNormalCount:1U notCount:0U where:@"objectCol.stringCol IN %@", @[@"abc"]];
    [self testClass:[AllTypesObject class] withNormalCount:0U notCount:1U where:@"objectCol.stringCol IN %@", @[@"def"]];
    [self testClass:[AllTypesObject class] withNormalCount:0U notCount:1U where:@"objectCol.stringCol IN %@", @[@"ABC"]];
    [self testClass:[AllTypesObject class] withNormalCount:1U notCount:0U where:@"objectCol.stringCol IN[c] %@", @[@"abc"]];
    [self testClass:[AllTypesObject class] withNormalCount:1U notCount:0U where:@"objectCol.stringCol IN[c] %@", @[@"ABC"]];
}

- (void)testArrayIn
{
    RLMRealm *realm = [RLMRealm defaultRealm];
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

- (void)testQueryChaining {
    RLMRealm *realm = [RLMRealm defaultRealm];

    [realm beginWriteTransaction];
    [PersonObject createInRealm:realm withValue:@[@"Tim", @29]];
    [PersonObject createInRealm:realm withValue:@[@"Ari", @33]];
    [realm commitWriteTransaction];

    RLMAssertCount(PersonObject, 1U, @"name == 'Ari'");
    RLMAssertCount(PersonObject, 0U, @"name == 'Ari' and age == 29");
    XCTAssertEqual(0U, [[[PersonObject objectsWhere:@"name == 'Ari'"] objectsWhere:@"age == 29"] count]);
}

- (void)testLinkViewQuery {
    RLMRealm *realm = [RLMRealm defaultRealm];

    [realm beginWriteTransaction];
    [CompanyObject createInRealm:realm
                      withValue:@[@"company name", @[@{@"name": @"John", @"age": @30, @"hired": @NO},
                                                      @{@"name": @"Joe",  @"age": @40, @"hired": @YES},
                                                      @{@"name": @"Jill",  @"age": @50, @"hired": @YES}]]];
    [realm commitWriteTransaction];

    CompanyObject *co = [CompanyObject allObjects][0];
    RLMAssertCount(co.employees, 1U, @"hired = NO");
    RLMAssertCount(co.employees, 2U, @"hired = YES");
    RLMAssertCount(co.employees, 1U, @"hired = YES AND age = 40");
    RLMAssertCount(co.employees, 0U, @"hired = YES AND age = 30");
    RLMAssertCount(co.employees, 3U, @"hired = YES OR age = 30");
    RLMAssertCount([co.employees, 1U, @"hired = YES"] objectsWhere:@"name = 'Joe'");
}

- (void)testLinkViewQueryLifetime {
    RLMRealm *realm = [RLMRealm defaultRealm];

    [realm beginWriteTransaction];
    [CompanyObject createInRealm:realm
                      withValue:@[@"company name", @[@{@"name": @"John", @"age": @30, @"hired": @NO},
                                                      @{@"name": @"Jill",  @"age": @50, @"hired": @YES}]]];
    [EmployeeObject createInRealm:realm withValue:@{@"name": @"Joe",  @"age": @40, @"hired": @YES}];
    [realm commitWriteTransaction];

    RLMResults *subarray = nil;
    @autoreleasepool {
        __attribute((objc_precise_lifetime)) CompanyObject *co = [CompanyObject allObjects][0];
        subarray = [co.employees objectsWhere:@"age = 40"];
        XCTAssertEqual(0U, subarray.count);
    }

    [realm beginWriteTransaction];
    @autoreleasepool {
        __attribute((objc_precise_lifetime)) CompanyObject *co = [CompanyObject allObjects][0];
        [co.employees addObject:[EmployeeObject createInRealm:realm withValue:@{@"name": @"Joe",  @"age": @40, @"hired": @YES}]];
    }
    [realm commitWriteTransaction];

    XCTAssertEqual(1U, subarray.count);
    XCTAssertEqualObjects(@"Joe", subarray[0][@"name"]);
}

- (void)testLinkViewQueryLiveUpdate {
    RLMRealm *realm = [RLMRealm defaultRealm];

    [realm beginWriteTransaction];
    [CompanyObject createInRealm:realm
                      withValue:@[@"company name", @[@{@"name": @"John", @"age": @30, @"hired": @NO},
                                                      @{@"name": @"Jill",  @"age": @40, @"hired": @YES}]]];
    EmployeeObject *eo = [EmployeeObject createInRealm:realm withValue:@{@"name": @"Joe",  @"age": @40, @"hired": @YES}];
    [realm commitWriteTransaction];

    CompanyObject *co = CompanyObject.allObjects.firstObject;
    RLMResults *basic = [co.employees objectsWhere:@"age = 40"];
    RLMResults *sort = [co.employees sortedResultsUsingProperty:@"name" ascending:YES];
    RLMResults *sortQuery = [[co.employees sortedResultsUsingProperty:@"name" ascending:YES] objectsWhere:@"age = 40"];
    RLMResults *querySort = [[co.employees objectsWhere:@"age = 40"] sortedResultsUsingProperty:@"name" ascending:YES];

    XCTAssertEqual(1U, basic.count);
    XCTAssertEqual(2U, sort.count);
    XCTAssertEqual(1U, sortQuery.count);
    XCTAssertEqual(1U, querySort.count);

    XCTAssertEqualObjects(@"Jill", [[basic lastObject] name]);
    XCTAssertEqualObjects(@"Jill", [[sortQuery lastObject] name]);
    XCTAssertEqualObjects(@"Jill", [[querySort lastObject] name]);

    [realm beginWriteTransaction];
    [co.employees addObject:eo];
    [realm commitWriteTransaction];

    XCTAssertEqual(2U, basic.count);
    XCTAssertEqual(3U, sort.count);
    XCTAssertEqual(2U, sortQuery.count);
    XCTAssertEqual(2U, querySort.count);

    XCTAssertEqualObjects(@"Joe", [[basic lastObject] name]);
    XCTAssertEqualObjects(@"Joe", [[sortQuery lastObject] name]);
    XCTAssertEqualObjects(@"Joe", [[querySort lastObject] name]);
}

- (void)testConstantPredicates
{
    RLMRealm *realm = [RLMRealm defaultRealm];

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
    RLMRealm *realm = [RLMRealm defaultRealm];

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

- (void)testComparisonsWithKeyPathOnRHS
{
    RLMRealm *realm = [RLMRealm defaultRealm];

    [realm beginWriteTransaction];

    [self.queryObjectClass createInRealm:realm withValue:@[@YES, @YES, @1, @2, @23.0f, @1.7f,  @0.0,  @5.55, @"a", @"a"]];
    [self.queryObjectClass createInRealm:realm withValue:@[@YES, @NO,  @1, @3, @-5.3f, @4.21f, @1.0,  @4.44, @"a", @"A"]];
    [self.queryObjectClass createInRealm:realm withValue:@[@NO,  @NO,  @2, @2, @1.0f,  @3.55f, @99.9, @6.66, @"a", @"ab"]];
    [self.queryObjectClass createInRealm:realm withValue:@[@NO,  @YES, @3, @6, @4.21f, @1.0f,  @1.0,  @7.77, @"a", @"AB"]];
    [self.queryObjectClass createInRealm:realm withValue:@[@YES, @YES, @4, @5, @23.0f, @23.0f, @7.4,  @8.88, @"a", @"b"]];
    [self.queryObjectClass createInRealm:realm withValue:@[@YES, @NO,  @15, @8, @1.0f,  @66.0f, @1.01, @9.99, @"a", @"ba"]];
    [self.queryObjectClass createInRealm:realm withValue:@[@NO,  @YES, @15, @15, @1.0f,  @66.0f, @1.01, @9.99, @"a", @"BA"]];

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

    RLMAssertThrowsWithReasonMatching([self.queryObjectClass objectsWhere:@"'Realm' CONTAINS string1"].count,
                                      @"Operator 'CONTAINS' is not supported .* right side");
    RLMAssertThrowsWithReasonMatching([self.queryObjectClass objectsWhere:@"'Amazon' BEGINSWITH string2"].count,
                                      @"Operator 'BEGINSWITH' is not supported .* right side");
    RLMAssertThrowsWithReasonMatching([self.queryObjectClass objectsWhere:@"'Tuba' ENDSWITH string1"].count,
                                      @"Operator 'ENDSWITH' is not supported .* right side");
}

- (void)testLinksToDeletedOrMovedObject
{
    RLMRealm *realm = [RLMRealm defaultRealm];
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
    RLMRealm *realm = [RLMRealm defaultRealm];
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

- (void)testSubqueries
{
    RLMRealm *realm = [RLMRealm defaultRealm];

    [realm beginWriteTransaction];
    CompanyObject *first = [CompanyObject createInRealm:realm
                                              withValue:@[@"first company", @[@{@"name": @"John", @"age": @30, @"hired": @NO},
                                                                              @{@"name": @"Jill",  @"age": @40, @"hired": @YES},
                                                                              @{@"name": @"Joe",  @"age": @40, @"hired": @YES}]]];
    CompanyObject *second = [CompanyObject createInRealm:realm
                                               withValue:@[@"second company", @[@{@"name": @"Bill", @"age": @35, @"hired": @YES},
                                                                                @{@"name": @"Don",  @"age": @45, @"hired": @NO},
                                                                                @{@"name": @"Tim",  @"age": @60, @"hired": @NO}]]];

    [LinkToCompanyObject createInRealm:realm withValue:@[ first ]];
    [LinkToCompanyObject createInRealm:realm withValue:@[ second ]];
    [realm commitWriteTransaction];

    RLMAssertCount(CompanyObject, 1U, @"SUBQUERY(employees, $employee, $employee.age > 30 AND $employee.hired = FALSE).@count > 0");
    RLMAssertCount(CompanyObject, 2U, @"SUBQUERY(employees, $employee, $employee.age < 30 AND $employee.hired = TRUE).@count == 0");

    RLMAssertCount(LinkToCompanyObject, 1U, @"SUBQUERY(company.employees, $employee, $employee.age > 30 AND $employee.hired = FALSE).@count > 0");
    RLMAssertCount(LinkToCompanyObject, 2U, @"SUBQUERY(company.employees, $employee, $employee.age < 30 AND $employee.hired = TRUE).@count == 0");
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
        RLMRealm *realm = [RLMRealm defaultRealm];
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

        RLMResults *nonNilStrings = [stringObjectClass objectsInRealm:realm where:@"stringCol != NULL"];
        XCTAssertEqual(3U, nonNilStrings.count);
        XCTAssertEqualObjects((@[@"a", @"b", @""]), [nonNilStrings valueForKey:@"stringCol"]);

        RLMAssertCount(stringObjectClass, 3U, @"stringCol IN {NULL, 'a'}");

        RLMAssertCount(stringObjectClass, 1U, @"stringCol CONTAINS 'a'");
        RLMAssertCount(stringObjectClass, 1U, @"stringCol BEGINSWITH 'a'");
        RLMAssertCount(stringObjectClass, 1U, @"stringCol ENDSWITH 'a'");

        RLMAssertCount(stringObjectClass, 0U, @"stringCol CONTAINS 'z'");

        RLMAssertCount(stringObjectClass, 1U, @"stringCol = ''");

        RLMResults *sorted = [[stringObjectClass allObjectsInRealm:realm] sortedResultsUsingProperty:@"stringCol" ascending:YES];
        XCTAssertEqualObjects((@[NSNull.null, NSNull.null, @"", @"a", @"b"]), [sorted valueForKey:@"stringCol"]);
        XCTAssertEqualObjects((@[@"b", @"a", @"", NSNull.null, NSNull.null]), [[sorted sortedResultsUsingProperty:@"stringCol" ascending:NO] valueForKey:@"stringCol"]);

        [realm transactionWithBlock:^{
            [realm deleteObject:[stringObjectClass allObjectsInRealm:realm].firstObject];
        }];

        XCTAssertEqual(2U, nilStrings.count);
        XCTAssertEqual(2U, nonNilStrings.count);

        XCTAssertEqualObjects([nonNilStrings valueForKey:@"stringCol"], [[stringObjectClass objectsInRealm:realm where:@"stringCol CONTAINS ''"] valueForKey:@"stringCol"]);
        XCTAssertEqualObjects([nonNilStrings valueForKey:@"stringCol"], [[stringObjectClass objectsInRealm:realm where:@"stringCol BEGINSWITH ''"] valueForKey:@"stringCol"]);
        XCTAssertEqualObjects([nonNilStrings valueForKey:@"stringCol"], [[stringObjectClass objectsInRealm:realm where:@"stringCol ENDSWITH ''"] valueForKey:@"stringCol"]);
        XCTAssertEqualObjects([nonNilStrings valueForKey:@"stringCol"], [[stringObjectClass objectsInRealm:realm where:@"stringCol CONTAINS[c] ''"] valueForKey:@"stringCol"]);
        XCTAssertEqualObjects([nonNilStrings valueForKey:@"stringCol"], [[stringObjectClass objectsInRealm:realm where:@"stringCol BEGINSWITH[c] ''"] valueForKey:@"stringCol"]);
        XCTAssertEqualObjects([nonNilStrings valueForKey:@"stringCol"], [[stringObjectClass objectsInRealm:realm where:@"stringCol ENDSWITH[c] ''"] valueForKey:@"stringCol"]);

        XCTAssertEqualObjects(@[], ([[stringObjectClass objectsInRealm:realm where:@"stringCol CONTAINS %@", @"\0"] valueForKey:@"self"]));
        XCTAssertEqualObjects([[stringObjectClass allObjectsInRealm:realm] valueForKey:@"stringCol"], ([[StringObject objectsInRealm:realm where:@"stringCol CONTAINS NULL"] valueForKey:@"stringCol"]));
    };
    testWithStringClass([StringObject class]);
    testWithStringClass([IndexedStringObject class]);
}

- (void)testQueryingOnLinkToNullableStringColumn {
    void (^testWithStringClass)(Class, Class) = ^(Class stringLinkClass, Class stringObjectClass) {
        RLMRealm *realm = [RLMRealm defaultRealm];
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

        RLMResults *nonNilStrings = [stringLinkClass objectsInRealm:realm where:@"objectCol.stringCol != NULL"];
        XCTAssertEqual(3U, nonNilStrings.count);
        XCTAssertEqualObjects((@[@"a", @"b", @""]), [nonNilStrings valueForKeyPath:@"objectCol.stringCol"]);

        RLMAssertCount(stringLinkClass, 3U, @"objectCol.stringCol IN {NULL, 'a'}");

        RLMAssertCount(stringLinkClass, 1U, @"objectCol.stringCol CONTAINS 'a'");
        RLMAssertCount(stringLinkClass, 1U, @"objectCol.stringCol BEGINSWITH 'a'");
        RLMAssertCount(stringLinkClass, 1U, @"objectCol.stringCol ENDSWITH 'a'");

        RLMAssertCount(stringLinkClass, 0U, @"objectCol.stringCol CONTAINS 'z'");

        RLMAssertCount(stringLinkClass, 1U, @"objectCol.stringCol = ''");
    };

    testWithStringClass([LinkStringObject class], [StringObject class]);
    testWithStringClass([LinkIndexedStringObject class], [IndexedStringObject class]);
}

- (void)testSortingColumnsWithNull {
    RLMRealm *realm = [RLMRealm defaultRealm];
    [realm beginWriteTransaction];

    {
        NumberObject *no1 = [NumberObject createInRealm:realm withValue:@[@1, @1.1f, @1.1, @YES]];
        NumberObject *noNull = [NumberObject createInRealm:realm withValue:@[NSNull.null, NSNull.null, NSNull.null, NSNull.null]];
        NumberObject *no0 = [NumberObject createInRealm:realm withValue:@[@0, @0.0f, @0.0, @NO]];
        for (RLMProperty *property in [[NumberObject alloc] init].objectSchema.properties) {
            NSString *name = property.name;
            RLMResults *ascending = [[NumberObject allObjectsInRealm:realm] sortedResultsUsingProperty:name ascending:YES];
            XCTAssertEqualObjects([ascending valueForKey:name], ([@[noNull, no0, no1] valueForKey:name]));

            RLMResults *descending = [[NumberObject allObjectsInRealm:realm] sortedResultsUsingProperty:name ascending:NO];
            XCTAssertEqualObjects([descending valueForKey:name], ([@[no1, no0, noNull] valueForKey:name]));
        }
    }

    {
        DateObject *doPositive = [DateObject createInRealm:realm withValue:@[[NSDate dateWithTimeIntervalSince1970:100]]];
        DateObject *doNegative = [DateObject createInRealm:realm withValue:@[[NSDate dateWithTimeIntervalSince1970:-100]]];
        DateObject *doZero = [DateObject createInRealm:realm withValue:@[[NSDate dateWithTimeIntervalSince1970:0]]];
        DateObject *doNull = [DateObject createInRealm:realm withValue:@[NSNull.null]];

        RLMResults *ascending = [[DateObject allObjectsInRealm:realm] sortedResultsUsingProperty:@"dateCol" ascending:YES];
        XCTAssertEqualObjects([ascending valueForKey:@"dateCol"], ([@[doNull, doNegative, doZero, doPositive] valueForKey:@"dateCol"]));

        RLMResults *descending = [[DateObject allObjectsInRealm:realm] sortedResultsUsingProperty:@"dateCol" ascending:NO];
        XCTAssertEqualObjects([descending valueForKey:@"dateCol"], ([@[doPositive, doZero, doNegative, doNull] valueForKey:@"dateCol"]));
    }

    {
        StringObject *soA = [StringObject createInRealm:realm withValue:@[@"A"]];
        StringObject *soEmpty = [StringObject createInRealm:realm withValue:@[@""]];
        StringObject *soB = [StringObject createInRealm:realm withValue:@[@"B"]];
        StringObject *soNull = [StringObject createInRealm:realm withValue:@[NSNull.null]];
        StringObject *soAB = [StringObject createInRealm:realm withValue:@[@"AB"]];

        RLMResults *ascending = [[StringObject allObjectsInRealm:realm] sortedResultsUsingProperty:@"stringCol" ascending:YES];
        XCTAssertEqualObjects([ascending valueForKey:@"stringCol"], ([@[soNull, soEmpty, soA, soAB, soB] valueForKey:@"stringCol"]));

        RLMResults *descending = [[StringObject allObjectsInRealm:realm] sortedResultsUsingProperty:@"stringCol" ascending:NO];
        XCTAssertEqualObjects([descending valueForKey:@"stringCol"], ([@[soB, soAB, soA, soEmpty, soNull] valueForKey:@"stringCol"]));
    }

    [realm cancelWriteTransaction];
}

- (void)testCountOnCollection {
    RLMRealm *realm = [RLMRealm defaultRealm];
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

- (void)testAggregateCollectionOperators {
    RLMRealm *realm = [RLMRealm defaultRealm];
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
    RLMAssertCount(IntegerArrayPropertyObject, 1U, @"array.@avg.intCol == -3703.0");
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
    RLMRealm *realm = [RLMRealm defaultRealm];

    // nil on LHS is currently not supported by core
    XCTAssertThrows([AllOptionalTypes objectsWhere:@"nil = boolObj"]);

    // These need to be stored in variables because the struct does not retain them
    NSData *matchingData = [@"" dataUsingEncoding:NSUTF8StringEncoding];
    NSData *notMatchingData = [@"a" dataUsingEncoding:NSUTF8StringEncoding];
    NSDate *matchingDate = [NSDate dateWithTimeIntervalSince1970:1];
    NSDate *notMatchingDate = [NSDate dateWithTimeIntervalSince1970:2];

    struct NullTestData data[] = {
        {@"boolObj", @"YES", @"NO", @YES, @NO},
        {@"intObj", @"1", @"0", @1, @0, true},
        {@"floatObj", @"1", @"0", @1, @0, true},
        {@"doubleObj", @"1", @"0", @1, @0, true},
        {@"string", @"'a'", @"''", @"a", @"", false, true},
        {@"data", nil, nil, notMatchingData, matchingData},
        {@"date", nil, nil, notMatchingDate, matchingDate, true},
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
    [AllOptionalTypes createInRealm:realm withValue:@[@NO, @0, @0, @0, @"", matchingData, matchingDate]];
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
            RLMAssertOperator(BEGINSWITH, 1U, 0U, 1U);
            RLMAssertOperator(ENDSWITH, 1U, 0U, 1U);
            RLMAssertOperator(CONTAINS, 1U, 0U, 1U);
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
            RLMAssertOperator(BEGINSWITH, 0U, 0U, 1U);
            RLMAssertOperator(ENDSWITH, 0U, 0U, 1U);
            RLMAssertOperator(CONTAINS, 0U, 0U, 1U);
        }
    }
}

- (void)testINPredicateOnNullWithNonNullValues
{
    RLMRealm *realm = [RLMRealm defaultRealm];

    [realm beginWriteTransaction];
    [AllOptionalTypes createInRealm:realm withValue:@[@YES, @1, @1, @1, @"abc",
                                                      [@"a" dataUsingEncoding:NSUTF8StringEncoding],
                                                      [NSDate dateWithTimeIntervalSince1970:1]]];
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
}

- (void)testINPredicateOnNullWithNullValues
{
    RLMRealm *realm = [RLMRealm defaultRealm];

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
}

@end

@interface AsyncQueryTests : QueryTests
@end

@implementation AsyncQueryTests
- (RLMResults *)evaluate:(RLMResults *)results {
    id token = [results addNotificationBlock:^(RLMResults *r, NSError *e) {
        XCTAssertNil(e);
        XCTAssertNotNil(r);
        CFRunLoopStop(CFRunLoopGetCurrent());
    }];
    CFRunLoopRun();
    [token stop];
    return results;
}
@end
