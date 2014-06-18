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

#pragma mark Thing

@interface QueryObject : RLMObject
@property NSInteger int1;
@property NSInteger int2;
@property float     float1;
@property float     float2;
@property double    double1;
@property double    double2;
@property NSString *recordTag;
@end

@implementation QueryObject
@end

#pragma mark - Tests

@interface QueryTests : RLMTestCase
@end

@implementation QueryTests

- (void)testBasicQuery
{
    RLMRealm *realm = [self realmWithTestPath];

    [realm beginWriteTransaction];
    [PersonObject createInRealm:realm withObject:@[@"Fiel", @27]];
    [PersonObject createInRealm:realm withObject:@[@"Ari", @33]];
    [PersonObject createInRealm:realm withObject:@[@"Tim", @29]];
    [realm commitWriteTransaction];
    
    // query on realm
    XCTAssertEqual([realm objects:[PersonObject className] where:@"age > 28"].count, (NSUInteger)2, @"Expecting 2 results");
    
    // query on realm with order
    RLMArray *results = [realm objects:[PersonObject className] orderedBy:@"age" where:@"age > 28"];
    XCTAssertEqualObjects([results[0] name], @"Tim", @"Tim should be first results");
}

- (void)testDefaultRealmQuery
{
    RLMRealm *realm = [RLMRealm defaultRealm];
    
    [realm beginWriteTransaction];
    [PersonObject createInRealm:realm withObject:@[@"Fiel", @27]];
    [PersonObject createInRealm:realm withObject:@[@"Tim", @29]];
    [PersonObject createInRealm:realm withObject:@[@"Ari", @33]];
    [realm commitWriteTransaction];
    
    // query on class
    RLMArray *all = [PersonObject allObjects];
    XCTAssertEqual(all.count, (NSUInteger)3, @"Expecting 3 results");
    XCTAssertEqual([PersonObject objectsWhere:@"age == 27"].count, (NSUInteger)1, @"Expecting 1 results");
    
    // with order
    RLMArray *results = [PersonObject objectsOrderedBy:@"age" where:@"age > 28"];
    XCTAssertEqualObjects([results[0] name], @"Tim", @"Tim should be first results");
}

- (void)testArrayQuery
{
    RLMRealm *realm = [RLMRealm defaultRealm];
    
    [realm beginWriteTransaction];
    [PersonObject createInRealm:realm withObject:@[@"Fiel", @27]];
    [PersonObject createInRealm:realm withObject:@[@"Tim", @29]];
    [PersonObject createInRealm:realm withObject:@[@"Ari", @33]];
    [realm commitWriteTransaction];
    
    // query on class
    RLMArray *all = [PersonObject allObjects];
    XCTAssertEqual(all.count, (NSUInteger)3, @"Expecting 3 results");

    RLMArray *some = [PersonObject objectsOrderedBy:@"age" where:@"age > 28"];
    
    // query/order on array
    XCTAssertEqual([all objectsWhere:@"age == 27"].count, (NSUInteger)1, @"Expecting 1 result");
    XCTAssertEqual([all objectsWhere:@"age == 28"].count, (NSUInteger)0, @"Expecting 0 results");
    some = [some objectsOrderedBy:[NSSortDescriptor sortDescriptorWithKey:@"age" ascending:NO] where:nil];
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
    StringObject *stringObj = [StringObject new];
    stringObj.string = @"string";
    [AllTypesObject createInRealm:realm withObject:@[@YES, @1, @1.0f, @1.0, @"a", [@"a" dataUsingEncoding:NSUTF8StringEncoding], date1, @YES, @((long)1), @1, stringObj]];
    [AllTypesObject createInRealm:realm withObject:@[@YES, @2, @2.0f, @2.0, @"b", [@"b" dataUsingEncoding:NSUTF8StringEncoding], date2, @YES, @((long)2), @"mixed", stringObj]];
    [AllTypesObject createInRealm:realm withObject:@[@NO, @3, @3.0f, @3.0, @"c", [@"c" dataUsingEncoding:NSUTF8StringEncoding], date3, @YES, @((long)3), @"mixed", stringObj]];
    [AllTypesObject createInRealm:realm withObject:@[@NO, @33, @3.3f, @3.3, @"cc", [@"cc" dataUsingEncoding:NSUTF8StringEncoding], date33, @NO, @((long)3.3), @"mixed", stringObj]];
    [realm commitWriteTransaction];
    
    
    //////////// sort by boolCol
    RLMArray *results = [AllTypesObject objectsOrderedBy:@"boolCol" where:nil];
    AllTypesObject *o = results[0];
    XCTAssertEqual(o.boolCol, NO, @"Should be NO");
    
    NSSortDescriptor *sortDesc = [NSSortDescriptor sortDescriptorWithKey:@"boolCol" ascending:YES];
    results = [AllTypesObject objectsOrderedBy:sortDesc where:nil];
    o = results[0];
    XCTAssertEqual(o.boolCol, NO, @"Should be NO");
    
    sortDesc = [NSSortDescriptor sortDescriptorWithKey:@"boolCol" ascending:NO];
    results = [AllTypesObject objectsOrderedBy:sortDesc where:nil];
    o = results[0];
    XCTAssertEqual(o.boolCol, YES, @"Should be YES");
    
    
    //////////// sort by intCol
    results = [AllTypesObject objectsOrderedBy:@"intCol" where:nil];
    o = results[0];
    XCTAssertEqual(o.intCol, 1, @"Should be 1");
    
    sortDesc = [NSSortDescriptor sortDescriptorWithKey:@"intCol" ascending:YES];
    results = [AllTypesObject objectsOrderedBy:sortDesc where:nil];
    o = results[0];
    XCTAssertEqual(o.intCol, 1, @"Should be 1");
    
    sortDesc = [NSSortDescriptor sortDescriptorWithKey:@"intCol" ascending:NO];
    results = [AllTypesObject objectsOrderedBy:sortDesc where:nil];
    o = results[0];
    XCTAssertEqual(o.intCol, 33, @"Should be 33");
    
    //////////// sort by dateCol
    results = [AllTypesObject objectsOrderedBy:@"dateCol" where:nil];
    o = results[0];
    XCTAssertEqualWithAccuracy(o.dateCol.timeIntervalSince1970, date1.timeIntervalSince1970, 1, @"Should be date1");
    
    sortDesc = [NSSortDescriptor sortDescriptorWithKey:@"dateCol" ascending:YES];
    results = [AllTypesObject objectsOrderedBy:sortDesc where:nil];
    o = results[0];
    XCTAssertEqualWithAccuracy(o.dateCol.timeIntervalSince1970, date1.timeIntervalSince1970, 1, @"Should be date1");
    
    sortDesc = [NSSortDescriptor sortDescriptorWithKey:@"dateCol" ascending:NO];
    results = [AllTypesObject objectsOrderedBy:sortDesc where:nil];
    o = results[0];
    XCTAssertEqualWithAccuracy(o.dateCol.timeIntervalSince1970, date33.timeIntervalSince1970, 1, @"Should be date33");
    
    
    //////////// sort by doubleCol
    results = [AllTypesObject objectsOrderedBy:@"doubleCol" where:nil];
    o = results[0];
    XCTAssertEqual(o.doubleCol, 1.0, @"Should be 1.0");
    
    sortDesc = [NSSortDescriptor sortDescriptorWithKey:@"doubleCol" ascending:YES];
    results = [AllTypesObject objectsOrderedBy:sortDesc where:nil];
    o = results[0];
    XCTAssertEqual(o.doubleCol, 1.0, @"Should be 1.0");
    
    sortDesc = [NSSortDescriptor sortDescriptorWithKey:@"doubleCol" ascending:NO];
    results = [AllTypesObject objectsOrderedBy:sortDesc where:nil];
    o = results[0];
    XCTAssertEqualWithAccuracy(o.doubleCol, 3.3, 0.0000001, @"Should be 3.3");
    
    
    //////////// sort by floatCol
    results = [AllTypesObject objectsOrderedBy:@"floatCol" where:nil];
    o = results[0];
    XCTAssertEqual(o.floatCol, 1.0, @"Should be 1.0");
    
    sortDesc = [NSSortDescriptor sortDescriptorWithKey:@"floatCol" ascending:YES];
    results = [AllTypesObject objectsOrderedBy:sortDesc where:nil];
    o = results[0];
    XCTAssertEqual(o.floatCol, 1.0, @"Should be 1.0");
    
    sortDesc = [NSSortDescriptor sortDescriptorWithKey:@"floatCol" ascending:NO];
    results = [AllTypesObject objectsOrderedBy:sortDesc where:nil];
    o = results[0];
    XCTAssertEqualWithAccuracy(o.floatCol, 3.3, 0.0000001, @"Should be 3.3");
    
    
    //////////// sort by stringCol
    results = [AllTypesObject objectsOrderedBy:@"stringCol" where:nil];
    o = results[0];
    XCTAssertEqualObjects(o.stringCol, @"a", @"Should be a");
    
    sortDesc = [NSSortDescriptor sortDescriptorWithKey:@"stringCol" ascending:YES];
    results = [AllTypesObject objectsOrderedBy:sortDesc where:nil];
    o = results[0];
    XCTAssertEqualObjects(o.stringCol, @"a", @"Should be a");
    
    sortDesc = [NSSortDescriptor sortDescriptorWithKey:@"stringCol" ascending:NO];
    results = [AllTypesObject objectsOrderedBy:sortDesc where:nil];
    o = results[0];
    XCTAssertEqualObjects(o.stringCol, @"cc", @"Should be cc");
    
    
    // sort by mixed column
    XCTAssertThrows([AllTypesObject objectsOrderedBy:@"mixedCol" where:nil], @"Sort on mixed col not supported");
    sortDesc = [NSSortDescriptor sortDescriptorWithKey:@"mixedCol" ascending:YES];
    XCTAssertThrows([AllTypesObject objectsOrderedBy:sortDesc where:nil], @"Sort on mixed col not supported");
    sortDesc = [NSSortDescriptor sortDescriptorWithKey:@"mixedCol" ascending:NO];
    XCTAssertThrows([AllTypesObject objectsOrderedBy:sortDesc where:nil], @"Sort on mixed col not supported");
}

- (void)testClassMisuse
{
    RLMRealm *realm = [RLMRealm defaultRealm];

    // class not derived from RLMObject
    XCTAssertThrows([realm objects:@"NonRealmEmployeeObject" where:@"age > 25"], @"invalid object type");
    XCTAssertThrows([realm objects:@"NonRealmEmployeeObject" orderedBy:@"age" where:@"age > 25"], @"invalid object type");

    // empty string for class name
    XCTAssertThrows([realm objects:@"" where:@"age > 25"], @"missing class name");
    XCTAssertThrows([realm objects:@"" orderedBy:@"age" where:@"age > 25"], @"missing class name");

    // nil class name
    XCTAssertThrows([realm objects:nil where:@"age > 25"], @"nil class name");
    XCTAssertThrows([realm objects:nil orderedBy:@"age" where:@"age > 25"], @"nil class name");
}

- (void)testPredicateValidUse
{
    RLMRealm *realm = [RLMRealm defaultRealm];

    NSString *className = AllTypesObject.className;
    
    // boolean false
    XCTAssertNoThrow([realm objects:className where:@"boolCol == no"], @"== no");
    XCTAssertNoThrow([realm objects:className where:@"boolCol == No"], @"== No");
    XCTAssertNoThrow([realm objects:className where:@"boolCol == NO"], @"== NO");
    XCTAssertNoThrow([realm objects:className where:@"boolCol == false"], @"== false");
    XCTAssertNoThrow([realm objects:className where:@"boolCol == False"], @"== False");
    XCTAssertNoThrow([realm objects:className where:@"boolCol == FALSE"], @"== FALSE");

    // boolean true
    XCTAssertNoThrow([realm objects:className where:@"boolCol == yes"], @"== yes");
    XCTAssertNoThrow([realm objects:className where:@"boolCol == Yes"], @"== Yes");
    XCTAssertNoThrow([realm objects:className where:@"boolCol == YES"], @"== YES");
    XCTAssertNoThrow([realm objects:className where:@"boolCol == true"], @"== true");
    XCTAssertNoThrow([realm objects:className where:@"boolCol == True"], @"== True");
    XCTAssertNoThrow([realm objects:className where:@"boolCol == TRUE"], @"== TRUE");
    
    // inequality
    XCTAssertNoThrow([realm objects:className where:@"boolCol != YES"], @"!= YES");
    XCTAssertNoThrow([realm objects:className where:@"boolCol <> YES"], @"<> YES");
    
    // string comparisons
    XCTAssertNoThrow([realm objects:className where:@"stringCol BEGINSWITH 'test'"], @"BEGINSWITH");
    XCTAssertNoThrow([realm objects:className where:@"stringCol CONTAINS 'test'"], @"CONTAINS");
    XCTAssertNoThrow([realm objects:className where:@"stringCol ENDSWITH 'test'"], @"ENDSWITH");

    // ANY
    XCTAssertNoThrow([realm objects:className where:@"ANY intCol > 5"], @"ANY int > constant");

    // ALL
    XCTAssertNoThrow([realm objects:className where:@"ALL intCol > 5"], @"ALL int > constant");
}

- (void)testPredicateNotSupported
{
    RLMRealm *realm = [RLMRealm defaultRealm];
    
    NSString *className = PersonObject.className;

    // LIKE
    XCTAssertThrows([realm objects:className where:@"name LIKE 'Smith'"], @"LIKE");

    // IN
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"stringCol IN %@",
                              @[@"Moe", @"Larry", @"Curly"]];
    XCTAssertThrows([realm objects:className where:predicate], @"IN array");
    
    // testing for null
    XCTAssertThrows([realm objects:className where:@"stringCol = nil"], @"test for nil");
}

- (void)testPredicateMisuse
{
    RLMRealm *realm = [RLMRealm defaultRealm];

    NSString *className = PersonObject.className;
    
    // invalid column/property name
    XCTAssertThrows([realm objects:className where:@"height > 72"], @"invalid column");
    
    // wrong/invalid data types
    XCTAssertThrows([realm objects:className where:@"age != xyz"], @"invalid type");
    XCTAssertThrows([realm objects:className where:@"name == 3"], @"invalid type");
    
    className = AllTypesObject.className;
    
    XCTAssertThrows([realm objects:className where:@"boolCol == Foo"], @"invalid type");
    XCTAssertThrows([realm objects:className where:@"dateCol == 7"], @"invalid type");
    XCTAssertThrows([realm objects:className where:@"doubleCol == The"], @"invalid type");
    XCTAssertThrows([realm objects:className where:@"floatCol == Bar"], @"invalid type");
    XCTAssertThrows([realm objects:className where:@"intCol == Baz"], @"invalid type");
    
    className = PersonObject.className;
    
    // compare two constants
    XCTAssertThrows([realm objects:className where:@"3 == 3"], @"comparing 2 constants");

    // invalid strings
    XCTAssertThrows([realm objects:className where:@""], @"empty string");
    XCTAssertThrows([realm objects:className where:@"age"], @"column name only");
    XCTAssertThrows([realm objects:className where:@"sdlfjasdflj"], @"gibberish");
    XCTAssertThrows([realm objects:className where:@"age * 25"], @"invalid operator");
    XCTAssertThrows([realm objects:className where:@"age === 25"], @"invalid operator");
    XCTAssertThrows([realm objects:className where:@","], @"comma");
    XCTAssertThrows([realm objects:className where:@"()"], @"parens");


    // abuse of BETWEEN
    XCTAssertThrows([realm objects:className where:@"age BETWEEN 25"], @"between with a scalar");
    XCTAssertThrows([realm objects:className where:@"age BETWEEN Foo"], @"between with a string");

    NSPredicate *pred = [NSPredicate predicateWithFormat:@"age BETWEEN %@", @[@1]];
    XCTAssertThrows([realm objects:className where:pred], @"between with array of 1 item");

    pred = [NSPredicate predicateWithFormat:@"age BETWEEN %@", @[@1, @2, @3]];
    XCTAssertThrows([realm objects:className where:pred], @"between with array of 3 items");

    pred = [NSPredicate predicateWithFormat:@"age BETWEEN %@", @[@"Foo", @"Bar"]];
    XCTAssertThrows([realm objects:className where:pred], @"between with array of 3 items");

    pred = [NSPredicate predicateWithFormat:@"age BETWEEN %@", @{@25 : @35}];
    XCTAssertThrows([realm objects:className where:pred], @"between with dictionary");
    
    pred = [NSPredicate predicateWithFormat:@"height BETWEEN %@", @[@25, @35]];
    XCTAssertThrows([realm objects:className where:pred], @"invalid property/column");
    

}

- (void)testTwoColumnComparisonQuery
{
    RLMRealm *realm = [RLMRealm defaultRealm];
    
    [realm beginWriteTransaction];
    
    [QueryObject createInRealm:realm withObject:@[@1, @2, @23.0f, @1.7f,  @0.0,  @5.55, @"Instance 0"]];
    [QueryObject createInRealm:realm withObject:@[@1, @3, @-5.3f, @4.21f, @1.0,  @4.44, @"Instance 1"]];
    [QueryObject createInRealm:realm withObject:@[@2, @2, @1.0f,  @3.55f, @99.9, @6.66, @"Instance 2"]];
    [QueryObject createInRealm:realm withObject:@[@3, @6, @4.21f, @1.0f,  @1.0,  @7.77, @"Instance 3"]];
    [QueryObject createInRealm:realm withObject:@[@4, @5, @23.0f, @23.0f, @7.4,  @8.88, @"Instance 4"]];
    [QueryObject createInRealm:realm withObject:@[@15, @8, @1.0f,  @66.0f, @1.01, @9.99, @"Instance 5"]];
    [QueryObject createInRealm:realm withObject:@[@15, @15, @1.0f,  @66.0f, @1.01, @9.99, @"Instance 6"]];
    
    [realm commitWriteTransaction];

    [self executeTwoColumnKeypathRealmComparisonQueryWithClass:[QueryObject class] predicate:@"int1 == int1"  expectedCount:7];
    [self executeTwoColumnKeypathRealmComparisonQueryWithClass:[QueryObject class] predicate:@"int1 == int2"  expectedCount:2];
    [self executeTwoColumnKeypathRealmComparisonQueryWithClass:[QueryObject class] predicate:@"int1 != int2"  expectedCount:5];
    [self executeTwoColumnKeypathRealmComparisonQueryWithClass:[QueryObject class] predicate:@"int1 > int2"   expectedCount:1];
    [self executeTwoColumnKeypathRealmComparisonQueryWithClass:[QueryObject class] predicate:@"int1 < int2"   expectedCount:4];
    [self executeTwoColumnKeypathRealmComparisonQueryWithClass:[QueryObject class] predicate:@"int1 >= int2"  expectedCount:3];
    [self executeTwoColumnKeypathRealmComparisonQueryWithClass:[QueryObject class] predicate:@"int1 <= int2"  expectedCount:6];
    
    [self executeTwoColumnKeypathRealmComparisonQueryWithClass:[QueryObject class] predicate:@"float1 == float1"  expectedCount:7];
    [self executeTwoColumnKeypathRealmComparisonQueryWithClass:[QueryObject class] predicate:@"float1 == float2"  expectedCount:1];
    [self executeTwoColumnKeypathRealmComparisonQueryWithClass:[QueryObject class] predicate:@"float1 != float2"  expectedCount:6];
    [self executeTwoColumnKeypathRealmComparisonQueryWithClass:[QueryObject class] predicate:@"float1 > float2"   expectedCount:2];
    [self executeTwoColumnKeypathRealmComparisonQueryWithClass:[QueryObject class] predicate:@"float1 < float2"   expectedCount:4];
    [self executeTwoColumnKeypathRealmComparisonQueryWithClass:[QueryObject class] predicate:@"float1 >= float2"  expectedCount:3];
    [self executeTwoColumnKeypathRealmComparisonQueryWithClass:[QueryObject class] predicate:@"float1 <= float2"  expectedCount:5];
    
    [self executeTwoColumnKeypathRealmComparisonQueryWithClass:[QueryObject class] predicate:@"double1 == double1" expectedCount:7];
    [self executeTwoColumnKeypathRealmComparisonQueryWithClass:[QueryObject class] predicate:@"double1 == double2" expectedCount:0];
    [self executeTwoColumnKeypathRealmComparisonQueryWithClass:[QueryObject class] predicate:@"double1 != double2" expectedCount:7];
    [self executeTwoColumnKeypathRealmComparisonQueryWithClass:[QueryObject class] predicate:@"double1 > double2" expectedCount:1];
    [self executeTwoColumnKeypathRealmComparisonQueryWithClass:[QueryObject class] predicate:@"double1 < double2" expectedCount:6];
    [self executeTwoColumnKeypathRealmComparisonQueryWithClass:[QueryObject class] predicate:@"double1 >= double2" expectedCount:1];
    [self executeTwoColumnKeypathRealmComparisonQueryWithClass:[QueryObject class] predicate:@"double1 <= double2" expectedCount:6];
                
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

    [self executeInvalidTwoColumnKeypathRealmComparisonQuery:[QueryObject class]
                                                   predicate:@"int1 == float1"];
    
    [self executeInvalidTwoColumnKeypathRealmComparisonQuery:[QueryObject class]
                                                   predicate:@"float2 >= double1"];
    
    [self executeInvalidTwoColumnKeypathRealmComparisonQuery:[QueryObject class]
                                                   predicate:@"double2 <= int2"];
    
    [self executeInvalidTwoColumnKeypathRealmComparisonQuery:[QueryObject class]
                                                   predicate:@"int2 != recordTag"];
    
    [self executeInvalidTwoColumnKeypathRealmComparisonQuery:[QueryObject class]
                                                   predicate:@"float1 > recordTag"];
    
    [self executeInvalidTwoColumnKeypathRealmComparisonQuery:[QueryObject class]
                                                   predicate:@"double1 < recordTag"];
}

- (void)executeTwoColumnKeypathRealmComparisonQueryWithClass:(Class)class
                                                   predicate:(NSString *)predicate
                                               expectedCount:(NSUInteger)expectedCount
{
    RLMRealm *realm = [RLMRealm defaultRealm];
    
    RLMArray *queryResult = [realm objects:NSStringFromClass(class)
                                     where:predicate];
    NSUInteger actualCount = queryResult.count;
    XCTAssertEqual(actualCount, expectedCount, @"Predicate: %@, Expecting %zd result(s), found %zd",
                   predicate, expectedCount, actualCount);
}

- (void)executeTwoColumnKeypathComparisonQueryWithPredicate:(NSString *)predicate
                                              expectedCount:(NSUInteger)expectedCount
{
    RLMArray *queryResult = [QueryObject objectsWhere:predicate];
    NSUInteger actualCount = queryResult.count;
    XCTAssertEqual(actualCount, expectedCount, @"Predicate: %@, Expecting %zd result(s), found %zd",
                   predicate, expectedCount, actualCount);
}

- (void)executeInvalidTwoColumnKeypathRealmComparisonQuery:(Class)class
                                                 predicate:(NSString *)predicate
{
    RLMRealm *realm = [RLMRealm defaultRealm];
    XCTAssertThrows([realm objects:NSStringFromClass(class) where:predicate], @"Invalid predicate should throw");
}

@end
