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
#import "XCTestCase+AsyncTesting.h"


@interface NonRealmPersonObject : NSObject
@property (nonatomic, copy) NSString *name;
@property (nonatomic, assign) NSInteger age;
@end

@implementation NonRealmPersonObject
@end


@interface PersonQueryObject : RLMObject
@property (nonatomic, copy) NSString *name;
@property (nonatomic, assign) NSInteger age;
@end

@implementation PersonQueryObject
@end


@interface AllPropertyTypesObject : RLMObject
@property (nonatomic, assign) BOOL boolCol;
@property (nonatomic, copy) NSDate *dateCol;
@property (nonatomic, assign) double doubleCol;
@property (nonatomic, assign) float floatCol;
@property (nonatomic, assign) NSInteger intCol;
@property (nonatomic, copy) NSString *stringCol;
@property (nonatomic, copy) id mixedCol;
@end

@implementation AllPropertyTypesObject
@end

@interface TestQueryObject : RLMObject
@property (nonatomic, assign) NSInteger int1;
@property (nonatomic, assign) NSInteger int2;
@property (nonatomic, assign) float float1;
@property (nonatomic, assign) float float2;
@property (nonatomic, assign) double double1;
@property (nonatomic, assign) double double2;
@property (nonatomic, copy) NSString *recordTag;
@end

@implementation TestQueryObject
@end

@interface QueryTests : RLMTestCase
@end

@implementation QueryTests

#pragma mark - Tests

- (void)testBasicQuery
{
    RLMRealm *realm = [self realmWithTestPath];

    [realm beginWriteTransaction];
    [PersonQueryObject createInRealm:realm withObject:@[@"Fiel", @27]];
    [PersonQueryObject createInRealm:realm withObject:@[@"Ari", @33]];
    [PersonQueryObject createInRealm:realm withObject:@[@"Tim", @29]];
    [realm commitWriteTransaction];
    
    // query on realm
    XCTAssertEqual([realm objects:[PersonQueryObject className] withPredicateFormat:@"age > 28"].count, (NSUInteger)2, @"Expecting 2 results");
    
    // query on realm with order
    RLMArray *results = [[realm objects:[PersonQueryObject className] withPredicateFormat:@"age > 28"] arraySortedByProperty:@"age" ascending:YES];
    XCTAssertEqualObjects([results[0] name], @"Tim", @"Tim should be first results");
}

- (void)testDefaultRealmQuery
{
    RLMRealm *realm = [RLMRealm defaultRealm];
    
    [realm beginWriteTransaction];
    [PersonQueryObject createInRealm:realm withObject:@[@"Fiel", @27]];
    [PersonQueryObject createInRealm:realm withObject:@[@"Tim", @29]];
    [PersonQueryObject createInRealm:realm withObject:@[@"Ari", @33]];
    [realm commitWriteTransaction];
    
    // query on class
    RLMArray *all = [PersonQueryObject allObjects];
    XCTAssertEqual(all.count, (NSUInteger)3, @"Expecting 3 results");
    XCTAssertEqual([PersonQueryObject objectsWithPredicateFormat:@"age == 27"].count, (NSUInteger)1, @"Expecting 1 results");
    
    // with order
    RLMArray *results = [[PersonQueryObject objectsWithPredicateFormat:@"age > 28"] arraySortedByProperty:@"age" ascending:YES];
    XCTAssertEqualObjects([results[0] name], @"Tim", @"Tim should be first results");
}

- (void)testArrayQuery
{
    RLMRealm *realm = [RLMRealm defaultRealm];
    
    [realm beginWriteTransaction];
    [PersonQueryObject createInRealm:realm withObject:@[@"Fiel", @27]];
    [PersonQueryObject createInRealm:realm withObject:@[@"Tim", @29]];
    [PersonQueryObject createInRealm:realm withObject:@[@"Ari", @33]];
    [realm commitWriteTransaction];
    
    // query on class
    RLMArray *all = [PersonQueryObject allObjects];
    XCTAssertEqual(all.count, (NSUInteger)3, @"Expecting 3 results");

    RLMArray *some = [[PersonQueryObject objectsWithPredicateFormat:@"age > 28"] arraySortedByProperty:@"age" ascending:YES];
    
    // query/order on array
    XCTAssertEqual([all objectsWithPredicateFormat:@"age == 27"].count, (NSUInteger)1, @"Expecting 1 result");
    XCTAssertEqual([all objectsWithPredicateFormat:@"age == 28"].count, (NSUInteger)0, @"Expecting 0 results");
    some = [some arraySortedByProperty:@"age" ascending:NO];
    XCTAssertEqualObjects([some[0] name], @"Ari", @"Ari should be first results");
}

- (void)testQuerySorting
{
    RLMRealm *realm = [RLMRealm defaultRealm];
    
    NSDate *date1 = [NSDate date];
    NSDate *date2 = [date1 dateByAddingTimeInterval:1];
    NSDate *date3 = [date2 dateByAddingTimeInterval:1];
    NSDate *date33 = [date3 dateByAddingTimeInterval:1];
    
    [realm beginWriteTransaction];
    [AllPropertyTypesObject createInRealm:realm withObject:@[@YES, date1, @1.0, @1.0f, @1, @"a", @"mixed"]];
    [AllPropertyTypesObject createInRealm:realm withObject:@[@YES, date2, @2.0, @2.0f, @2, @"b", @"mixed"]];
    [AllPropertyTypesObject createInRealm:realm withObject:@[@NO, date3, @3.0, @3.0f, @3, @"c", @"mixed"]];
    [AllPropertyTypesObject createInRealm:realm withObject:@[@NO, date33, @3.3, @3.3f, @33, @"cc", @"mixed"]];
    [realm commitWriteTransaction];
    
    
    //////////// sort by boolCol
    RLMArray *results = [[AllPropertyTypesObject objectsWithPredicate:nil] arraySortedByProperty:@"boolCol" ascending:YES];
    AllPropertyTypesObject *o = results[0];
    XCTAssertEqual(o.boolCol, NO, @"Should be NO");
    
    results = [[AllPropertyTypesObject objectsWithPredicate:nil] arraySortedByProperty:@"boolCol" ascending:NO];
    o = results[0];
    XCTAssertEqual(o.boolCol, YES, @"Should be YES");
    
    
    //////////// sort by intCol
    results = [[AllPropertyTypesObject objectsWithPredicate:nil] arraySortedByProperty:@"intCol" ascending:YES];
    o = results[0];
    XCTAssertEqual(o.intCol, 1, @"Should be 1");
    
    results = [[AllPropertyTypesObject objectsWithPredicate:nil] arraySortedByProperty:@"intCol" ascending:NO];
    o = results[0];
    XCTAssertEqual(o.intCol, 33, @"Should be 33");
    
    
    //////////// sort by dateCol
    results = [[AllPropertyTypesObject objectsWithPredicate:nil] arraySortedByProperty:@"dateCol" ascending:YES];
    o = results[0];
    XCTAssertEqualWithAccuracy(o.dateCol.timeIntervalSince1970, date1.timeIntervalSince1970, 1, @"Should be date1");
    
    results = [[AllPropertyTypesObject objectsWithPredicate:nil] arraySortedByProperty:@"dateCol" ascending:NO];
    o = results[0];
    XCTAssertEqualWithAccuracy(o.dateCol.timeIntervalSince1970, date33.timeIntervalSince1970, 1, @"Should be date33");
    
    
    //////////// sort by doubleCol
    results = [[AllPropertyTypesObject objectsWithPredicate:nil] arraySortedByProperty:@"doubleCol" ascending:YES];
    o = results[0];
    XCTAssertEqual(o.doubleCol, 1.0, @"Should be 1.0");
    
    results = [[AllPropertyTypesObject objectsWithPredicate:nil] arraySortedByProperty:@"doubleCol" ascending:NO];
    o = results[0];
    XCTAssertEqualWithAccuracy(o.doubleCol, 3.3, 0.0000001, @"Should be 3.3");
    
    
    //////////// sort by floatCol
    results = [[AllPropertyTypesObject objectsWithPredicate:nil] arraySortedByProperty:@"floatCol" ascending:YES];
    o = results[0];
    XCTAssertEqual(o.floatCol, 1.0, @"Should be 1.0");
    
    results = [[AllPropertyTypesObject objectsWithPredicate:nil] arraySortedByProperty:@"floatCol" ascending:NO];
    o = results[0];
    XCTAssertEqualWithAccuracy(o.floatCol, 3.3, 0.0000001, @"Should be 3.3");
    
    
    //////////// sort by stringCol
    results = [[AllPropertyTypesObject objectsWithPredicate:nil] arraySortedByProperty:@"stringCol" ascending:YES];
    o = results[0];
    XCTAssertEqualObjects(o.stringCol, @"a", @"Should be a");
    
    results = [[AllPropertyTypesObject objectsWithPredicate:nil] arraySortedByProperty:@"stringCol" ascending:NO];
    o = results[0];
    XCTAssertEqualObjects(o.stringCol, @"cc", @"Should be cc");
    
    
    // sort by mixed column
    XCTAssertThrows([[AllPropertyTypesObject objectsWithPredicate:nil] arraySortedByProperty:@"mixedCol" ascending:YES], @"Sort on mixed col not supported");
    XCTAssertThrows([[AllPropertyTypesObject objectsWithPredicate:nil] arraySortedByProperty:@"mixedCol" ascending:NO], @"Sort on mixed col not supported");
}

- (void)testClassMisuse
{
    RLMRealm *realm = [RLMRealm defaultRealm];

    // class not derived from RLMObject
    XCTAssertThrows([realm objects:@"NonRealmPersonObject" withPredicateFormat:@"age > 25"], @"invalid object type");
    XCTAssertThrows([[realm objects:@"NonRealmPersonObject" withPredicateFormat:@"age > 25"] arraySortedByProperty:@"age" ascending:YES], @"invalid object type");

    // empty string for class name
    XCTAssertThrows([realm objects:@"" withPredicateFormat:@"age > 25"], @"missing class name");
    XCTAssertThrows([[realm objects:@"" withPredicateFormat:@"age > 25"] arraySortedByProperty:@"age" ascending:YES], @"missing class name");

    // nil class name
    XCTAssertThrows([realm objects:nil withPredicateFormat:@"age > 25"], @"nil class name");
    XCTAssertThrows([[realm objects:nil withPredicateFormat:@"age > 25"] arraySortedByProperty:@"age" ascending:YES], @"nil class name");
}

- (void)testPredicateValidUse
{
    RLMRealm *realm = [RLMRealm defaultRealm];

    NSString *className = AllPropertyTypesObject.className;
    
    // boolean false
    XCTAssertNoThrow([realm objects:className withPredicateFormat:@"boolCol == no"], @"== no");
    XCTAssertNoThrow([realm objects:className withPredicateFormat:@"boolCol == No"], @"== No");
    XCTAssertNoThrow([realm objects:className withPredicateFormat:@"boolCol == NO"], @"== NO");
    XCTAssertNoThrow([realm objects:className withPredicateFormat:@"boolCol == false"], @"== false");
    XCTAssertNoThrow([realm objects:className withPredicateFormat:@"boolCol == False"], @"== False");
    XCTAssertNoThrow([realm objects:className withPredicateFormat:@"boolCol == FALSE"], @"== FALSE");

    // boolean true
    XCTAssertNoThrow([realm objects:className withPredicateFormat:@"boolCol == yes"], @"== yes");
    XCTAssertNoThrow([realm objects:className withPredicateFormat:@"boolCol == Yes"], @"== Yes");
    XCTAssertNoThrow([realm objects:className withPredicateFormat:@"boolCol == YES"], @"== YES");
    XCTAssertNoThrow([realm objects:className withPredicateFormat:@"boolCol == true"], @"== true");
    XCTAssertNoThrow([realm objects:className withPredicateFormat:@"boolCol == True"], @"== True");
    XCTAssertNoThrow([realm objects:className withPredicateFormat:@"boolCol == TRUE"], @"== TRUE");
    
    // inequality
    XCTAssertNoThrow([realm objects:className withPredicateFormat:@"boolCol != YES"], @"!= YES");
    XCTAssertNoThrow([realm objects:className withPredicateFormat:@"boolCol <> YES"], @"<> YES");
    
    // string comparisons
    XCTAssertNoThrow([realm objects:className withPredicateFormat:@"stringCol BEGINSWITH 'test'"], @"BEGINSWITH");
    XCTAssertNoThrow([realm objects:className withPredicateFormat:@"stringCol CONTAINS 'test'"], @"CONTAINS");
    XCTAssertNoThrow([realm objects:className withPredicateFormat:@"stringCol ENDSWITH 'test'"], @"ENDSWITH");

    // ANY
    XCTAssertNoThrow([realm objects:className withPredicateFormat:@"ANY intCol > 5"], @"ANY int > constant");

    // ALL
    XCTAssertNoThrow([realm objects:className withPredicateFormat:@"ALL intCol > 5"], @"ALL int > constant");
}

- (void)testPredicateNotSupported
{
    RLMRealm *realm = [RLMRealm defaultRealm];
    
    NSString *className = PersonQueryObject.className;

    // LIKE
    XCTAssertThrows([realm objects:className withPredicateFormat:@"name LIKE 'Smith'"], @"LIKE");

    // IN
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"stringCol IN %@",
                              @[@"Moe", @"Larry", @"Curly"]];
    XCTAssertThrows([realm objects:className withPredicate:predicate], @"IN array");
    
    // testing for null
    XCTAssertThrows([realm objects:className withPredicateFormat:@"stringCol = nil"], @"test for nil");
}

- (void)testPredicateMisuse
{
    RLMRealm *realm = [RLMRealm defaultRealm];

    NSString *className = PersonQueryObject.className;
    
    // invalid column/property name
    XCTAssertThrows([realm objects:className withPredicateFormat:@"height > 72"], @"invalid column");
    
    // wrong/invalid data types
    XCTAssertThrows([realm objects:className withPredicateFormat:@"age != xyz"], @"invalid type");
    XCTAssertThrows([realm objects:className withPredicateFormat:@"name == 3"], @"invalid type");
    
    className = AllPropertyTypesObject.className;
    
    XCTAssertThrows([realm objects:className withPredicateFormat:@"boolCol == Foo"], @"invalid type");
    XCTAssertThrows([realm objects:className withPredicateFormat:@"dateCol == 7"], @"invalid type");
    XCTAssertThrows([realm objects:className withPredicateFormat:@"doubleCol == The"], @"invalid type");
    XCTAssertThrows([realm objects:className withPredicateFormat:@"floatCol == Bar"], @"invalid type");
    XCTAssertThrows([realm objects:className withPredicateFormat:@"intCol == Baz"], @"invalid type");
    
    className = PersonQueryObject.className;
    
    // compare two constants
    XCTAssertThrows([realm objects:className withPredicateFormat:@"3 == 3"], @"comparing 2 constants");

    // invalid strings
    XCTAssertThrows([realm objects:className withPredicateFormat:@""], @"empty string");
    XCTAssertThrows([realm objects:className withPredicateFormat:@"age"], @"column name only");
    XCTAssertThrows([realm objects:className withPredicateFormat:@"sdlfjasdflj"], @"gibberish");
    XCTAssertThrows([realm objects:className withPredicateFormat:@"age * 25"], @"invalid operator");
    XCTAssertThrows([realm objects:className withPredicateFormat:@"age === 25"], @"invalid operator");
    XCTAssertThrows([realm objects:className withPredicateFormat:@","], @"comma");
    XCTAssertThrows([realm objects:className withPredicateFormat:@"()"], @"parens");


    // abuse of BETWEEN
    XCTAssertThrows([realm objects:className withPredicateFormat:@"age BETWEEN 25"], @"between with a scalar");
    XCTAssertThrows([realm objects:className withPredicateFormat:@"age BETWEEN Foo"], @"between with a string");

    NSPredicate *pred = [NSPredicate predicateWithFormat:@"age BETWEEN %@", @[@1]];
    XCTAssertThrows([realm objects:className withPredicate:pred], @"between with array of 1 item");

    pred = [NSPredicate predicateWithFormat:@"age BETWEEN %@", @[@1, @2, @3]];
    XCTAssertThrows([realm objects:className withPredicate:pred], @"between with array of 3 items");

    pred = [NSPredicate predicateWithFormat:@"age BETWEEN %@", @[@"Foo", @"Bar"]];
    XCTAssertThrows([realm objects:className withPredicate:pred], @"between with array of 3 items");

    pred = [NSPredicate predicateWithFormat:@"age BETWEEN %@", @{@25 : @35}];
    XCTAssertThrows([realm objects:className withPredicate:pred], @"between with dictionary");
    
    pred = [NSPredicate predicateWithFormat:@"height BETWEEN %@", @[@25, @35]];
    XCTAssertThrows([realm objects:className withPredicate:pred], @"invalid property/column");
    

}

- (void)testTwoColumnComparisonQuery
{
    RLMRealm *realm = [RLMRealm defaultRealm];
    
    [realm beginWriteTransaction];
    
    [TestQueryObject createInRealm:realm withObject:@[@1, @2, @23.0f, @1.7f,  @0.0,  @5.55, @"Instance 0"]];
    [TestQueryObject createInRealm:realm withObject:@[@1, @3, @-5.3f, @4.21f, @1.0,  @4.44, @"Instance 1"]];
    [TestQueryObject createInRealm:realm withObject:@[@2, @2, @1.0f,  @3.55f, @99.9, @6.66, @"Instance 2"]];
    [TestQueryObject createInRealm:realm withObject:@[@3, @6, @4.21f, @1.0f,  @1.0,  @7.77, @"Instance 3"]];
    [TestQueryObject createInRealm:realm withObject:@[@4, @5, @23.0f, @23.0f, @7.4,  @8.88, @"Instance 4"]];
    [TestQueryObject createInRealm:realm withObject:@[@15, @8, @1.0f,  @66.0f, @1.01, @9.99, @"Instance 5"]];
    [TestQueryObject createInRealm:realm withObject:@[@15, @15, @1.0f,  @66.0f, @1.01, @9.99, @"Instance 6"]];
    
    [realm commitWriteTransaction];

    [self executeTwoColumnKeypathRealmComparisonQueryWithClass:[TestQueryObject class] predicate:@"int1 == int1"  expectedCount:7];
    [self executeTwoColumnKeypathRealmComparisonQueryWithClass:[TestQueryObject class] predicate:@"int1 == int2"  expectedCount:2];
    [self executeTwoColumnKeypathRealmComparisonQueryWithClass:[TestQueryObject class] predicate:@"int1 != int2"  expectedCount:5];
    [self executeTwoColumnKeypathRealmComparisonQueryWithClass:[TestQueryObject class] predicate:@"int1 > int2"   expectedCount:1];
    [self executeTwoColumnKeypathRealmComparisonQueryWithClass:[TestQueryObject class] predicate:@"int1 < int2"   expectedCount:4];
    [self executeTwoColumnKeypathRealmComparisonQueryWithClass:[TestQueryObject class] predicate:@"int1 >= int2"  expectedCount:3];
    [self executeTwoColumnKeypathRealmComparisonQueryWithClass:[TestQueryObject class] predicate:@"int1 <= int2"  expectedCount:6];
    
    [self executeTwoColumnKeypathRealmComparisonQueryWithClass:[TestQueryObject class] predicate:@"float1 == float1"  expectedCount:7];
    [self executeTwoColumnKeypathRealmComparisonQueryWithClass:[TestQueryObject class] predicate:@"float1 == float2"  expectedCount:1];
    [self executeTwoColumnKeypathRealmComparisonQueryWithClass:[TestQueryObject class] predicate:@"float1 != float2"  expectedCount:6];
    [self executeTwoColumnKeypathRealmComparisonQueryWithClass:[TestQueryObject class] predicate:@"float1 > float2"   expectedCount:2];
    [self executeTwoColumnKeypathRealmComparisonQueryWithClass:[TestQueryObject class] predicate:@"float1 < float2"   expectedCount:4];
    [self executeTwoColumnKeypathRealmComparisonQueryWithClass:[TestQueryObject class] predicate:@"float1 >= float2"  expectedCount:3];
    [self executeTwoColumnKeypathRealmComparisonQueryWithClass:[TestQueryObject class] predicate:@"float1 <= float2"  expectedCount:5];
    
    [self executeTwoColumnKeypathRealmComparisonQueryWithClass:[TestQueryObject class] predicate:@"double1 == double1" expectedCount:7];
    [self executeTwoColumnKeypathRealmComparisonQueryWithClass:[TestQueryObject class] predicate:@"double1 == double2" expectedCount:0];
    [self executeTwoColumnKeypathRealmComparisonQueryWithClass:[TestQueryObject class] predicate:@"double1 != double2" expectedCount:7];
    [self executeTwoColumnKeypathRealmComparisonQueryWithClass:[TestQueryObject class] predicate:@"double1 > double2" expectedCount:1];
    [self executeTwoColumnKeypathRealmComparisonQueryWithClass:[TestQueryObject class] predicate:@"double1 < double2" expectedCount:6];
    [self executeTwoColumnKeypathRealmComparisonQueryWithClass:[TestQueryObject class] predicate:@"double1 >= double2" expectedCount:1];
    [self executeTwoColumnKeypathRealmComparisonQueryWithClass:[TestQueryObject class] predicate:@"double1 <= double2" expectedCount:6];
                
    [self executeTwoColumnKeypathComparisonQueryWithPredicate:@"int1 == int1"  expectedCount:7];
    [self executeTwoColumnKeypathComparisonQueryWithPredicate:@"int1 == int2"  expectedCount:2];
    [self executeTwoColumnKeypathComparisonQueryWithPredicate:@"int1 != int2"  expectedCount:5];
    [self executeTwoColumnKeypathComparisonQueryWithPredicate:@"int1 > int2"   expectedCount:1];
    [self executeTwoColumnKeypathComparisonQueryWithPredicate:@"int1 < int2"   expectedCount:4];
    [self executeTwoColumnKeypathComparisonQueryWithPredicate:@"int1 >= int2"  expectedCount:3];
    [self executeTwoColumnKeypathComparisonQueryWithPredicate:@"int1 <= int2"  expectedCount:6];

    [self executeTwoColumnKeypathComparisonQueryWithPredicate:@"float1 == float1"  expectedCount:7];
    [self executeTwoColumnKeypathComparisonQueryWithPredicate:@"float1 == float2"  expectedCount:1];
    [self executeTwoColumnKeypathComparisonQueryWithPredicate:@"float1 != float2"  expectedCount:6];
    [self executeTwoColumnKeypathComparisonQueryWithPredicate:@"float1 > float2"   expectedCount:2];
    [self executeTwoColumnKeypathComparisonQueryWithPredicate:@"float1 < float2"   expectedCount:4];
    [self executeTwoColumnKeypathComparisonQueryWithPredicate:@"float1 >= float2"  expectedCount:3];
    [self executeTwoColumnKeypathComparisonQueryWithPredicate:@"float1 <= float2"  expectedCount:5];

    [self executeTwoColumnKeypathComparisonQueryWithPredicate:@"double1 == double1" expectedCount:7];
    [self executeTwoColumnKeypathComparisonQueryWithPredicate:@"double1 == double2" expectedCount:0];
    [self executeTwoColumnKeypathComparisonQueryWithPredicate:@"double1 != double2" expectedCount:7];
    [self executeTwoColumnKeypathComparisonQueryWithPredicate:@"double1 > double2" expectedCount:1];
    [self executeTwoColumnKeypathComparisonQueryWithPredicate:@"double1 < double2" expectedCount:6];
    [self executeTwoColumnKeypathComparisonQueryWithPredicate:@"double1 >= double2" expectedCount:1];
    [self executeTwoColumnKeypathComparisonQueryWithPredicate:@"double1 <= double2" expectedCount:6];

    [self executeInvalidTwoColumnKeypathRealmComparisonQuery:[TestQueryObject class]
                                                   predicate:@"int1 == float1"];
    
    [self executeInvalidTwoColumnKeypathRealmComparisonQuery:[TestQueryObject class]
                                                   predicate:@"float2 >= double1"];
    
    [self executeInvalidTwoColumnKeypathRealmComparisonQuery:[TestQueryObject class]
                                                   predicate:@"double2 <= int2"];
    
    [self executeInvalidTwoColumnKeypathRealmComparisonQuery:[TestQueryObject class]
                                                   predicate:@"int2 != recordTag"];
    
    [self executeInvalidTwoColumnKeypathRealmComparisonQuery:[TestQueryObject class]
                                                   predicate:@"float1 > recordTag"];
    
    [self executeInvalidTwoColumnKeypathRealmComparisonQuery:[TestQueryObject class]
                                                   predicate:@"double1 < recordTag"];
}

- (void)executeTwoColumnKeypathRealmComparisonQueryWithClass:(Class)class
                                                   predicate:(NSString *)predicate
                                               expectedCount:(NSUInteger)expectedCount
{
    RLMRealm *realm = [RLMRealm defaultRealm];
    
    RLMArray *queryResult = [realm objects:NSStringFromClass(class)
                       withPredicateFormat:predicate];
    NSUInteger actualCount = queryResult.count;
    XCTAssertEqual(actualCount, expectedCount, @"Predicate: %@, Expecting %zd result(s), found %zd",
                   predicate, expectedCount, actualCount);
}

- (void)executeTwoColumnKeypathComparisonQueryWithPredicate:(NSString *)predicate
                                              expectedCount:(NSUInteger)expectedCount
{
    RLMArray *queryResult = [TestQueryObject objectsWithPredicateFormat:predicate];
    NSUInteger actualCount = queryResult.count;
    XCTAssertEqual(actualCount, expectedCount, @"Predicate: %@, Expecting %zd result(s), found %zd",
                   predicate, expectedCount, actualCount);
}

- (void)executeInvalidTwoColumnKeypathRealmComparisonQuery:(Class)class
                                                 predicate:(NSString *)predicate
{
    RLMRealm *realm = [RLMRealm defaultRealm];
    XCTAssertThrows([realm objects:NSStringFromClass(class) withPredicateFormat:predicate], @"Invalid predicate should throw");
}

@end
