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
@property (nonatomic, copy) NSString   *recordTag;
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
    XCTAssertEqual([realm objects:[PersonObject className] withPredicateFormat:@"age > 28"].count, (NSUInteger)2, @"Expecting 2 results");
    
    // query on realm with order
    RLMArray *results = [[realm objects:[PersonObject className] withPredicateFormat:@"age > 28"] arraySortedByProperty:@"age" ascending:YES];
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
    [AllTypesObject createInRealm:realm withObject:@[@YES, @1, @1.0f, @1.0, @"a", [@"a" dataUsingEncoding:NSUTF8StringEncoding], date1, @YES, @((long)1), @1, stringObj]];
    [AllTypesObject createInRealm:realm withObject:@[@YES, @2, @2.0f, @2.0, @"b", [@"b" dataUsingEncoding:NSUTF8StringEncoding], date2, @YES, @((long)2), @"mixed", stringObj]];
    [AllTypesObject createInRealm:realm withObject:@[@NO, @3, @3.0f, @3.0, @"c", [@"c" dataUsingEncoding:NSUTF8StringEncoding], date3, @YES, @((long)3), @"mixed", stringObj]];
    [AllTypesObject createInRealm:realm withObject:@[@NO, @33, @3.3f, @3.3, @"cc", [@"cc" dataUsingEncoding:NSUTF8StringEncoding], date33, @NO, @((long)3.3), @"mixed", stringObj]];
    [realm commitWriteTransaction];
    
    RLMArray *betweenArray = [AllTypesObject objectsWithPredicate:[NSPredicate predicateWithFormat:@"intCol BETWEEN %@", @[@2, @3]]];
    XCTAssertEqual(betweenArray.count, (NSUInteger)2, @"Should equal 52");
    betweenArray = [AllTypesObject objectsWithPredicate:[NSPredicate predicateWithFormat:@"floatCol BETWEEN %@", @[@1.0f, @4.0f]]];
    XCTAssertEqual(betweenArray.count, (NSUInteger)4, @"Should equal 4");
    betweenArray = [AllTypesObject objectsWithPredicate:[NSPredicate predicateWithFormat:@"doubleCol BETWEEN %@", @[@3.0, @7.0f]]];
    XCTAssertEqual(betweenArray.count, (NSUInteger)2, @"Should equal 2");
    betweenArray = [AllTypesObject objectsWithPredicate:[NSPredicate predicateWithFormat:@"dateCol BETWEEN %@", @[date2,date3]]];
    XCTAssertEqual(betweenArray.count, (NSUInteger)2, @"Should equal 2");
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
    [AllTypesObject createInRealm:realm withObject:@[@YES, @1, @1.0f, @1.0, @"a", [@"a" dataUsingEncoding:NSUTF8StringEncoding], date1, @YES, @((long)1), @1, stringObj]];
    [AllTypesObject createInRealm:realm withObject:@[@YES, @2, @2.0f, @2.0, @"b", [@"b" dataUsingEncoding:NSUTF8StringEncoding], date2, @YES, @((long)2), @"mixed", stringObj]];
    [AllTypesObject createInRealm:realm withObject:@[@NO, @3, @3.0f, @3.0, @"c", [@"c" dataUsingEncoding:NSUTF8StringEncoding], date3, @YES, @((long)3), @"mixed", stringObj]];
    [realm commitWriteTransaction];
    
    RLMArray *dateArray = [AllTypesObject objectsWithPredicate:[NSPredicate predicateWithFormat:@"dateCol < %@", date3]];
    XCTAssertEqual(dateArray.count, (NSUInteger)2, @"2 dates smaller");
    dateArray = [AllTypesObject objectsWithPredicate:[NSPredicate predicateWithFormat:@"dateCol =< %@", date3]];
    XCTAssertEqual(dateArray.count, (NSUInteger)3, @"3 dates smaller or equal");
    dateArray = [AllTypesObject objectsWithPredicate:[NSPredicate predicateWithFormat:@"dateCol > %@", date1]];
    XCTAssertEqual(dateArray.count, (NSUInteger)2, @"2 dates greater");
    dateArray = [AllTypesObject objectsWithPredicate:[NSPredicate predicateWithFormat:@"dateCol => %@", date1]];
    XCTAssertEqual(dateArray.count, (NSUInteger)3, @"3 dates greater or equal");
    dateArray = [AllTypesObject objectsWithPredicate:[NSPredicate predicateWithFormat:@"dateCol == %@", date1]];
    XCTAssertEqual(dateArray.count, (NSUInteger)1, @"1 date equal to");
    dateArray = [AllTypesObject objectsWithPredicate:[NSPredicate predicateWithFormat:@"dateCol != %@", date1]];
    XCTAssertEqual(dateArray.count, (NSUInteger)2, @"2 dates not equal to");
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

    RLMArray *results = [PersonObject objectsWithPredicateFormat:@"age == 27"];
    XCTAssertEqual(results.count, (NSUInteger)1, @"Expecting 1 results");
    
    // with order
    results = [[PersonObject objectsWithPredicateFormat:@"age > 28"] arraySortedByProperty:@"age" ascending:YES];
    PersonObject *tim = results[0];
    XCTAssertEqualObjects(tim.name, @"Tim", @"Tim should be first results");
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
    
    RLMArray *some = [[PersonObject objectsWithPredicateFormat:@"age > 28"] arraySortedByProperty:@"age" ascending:YES];
    
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
    StringObject *stringObj = [StringObject new];
    stringObj.stringCol = @"string";
    [AllTypesObject createInRealm:realm withObject:@[@YES, @1, @1.0f, @1.0, @"a", [@"a" dataUsingEncoding:NSUTF8StringEncoding], date1, @YES, @((long)1), @1, stringObj]];
    [AllTypesObject createInRealm:realm withObject:@[@YES, @2, @2.0f, @2.0, @"b", [@"b" dataUsingEncoding:NSUTF8StringEncoding], date2, @YES, @((long)2), @"mixed", stringObj]];
    [AllTypesObject createInRealm:realm withObject:@[@NO, @3, @3.0f, @3.0, @"c", [@"c" dataUsingEncoding:NSUTF8StringEncoding], date3, @YES, @((long)3), @"mixed", stringObj]];
    [AllTypesObject createInRealm:realm withObject:@[@NO, @33, @3.3f, @3.3, @"cc", [@"cc" dataUsingEncoding:NSUTF8StringEncoding], date33, @NO, @((long)3.3), @"mixed", stringObj]];
    [realm commitWriteTransaction];
    
    
    //////////// sort by boolCol
    RLMArray *results = [[AllTypesObject objectsWithPredicate:nil] arraySortedByProperty:@"boolCol" ascending:YES];
    AllTypesObject *o = results[0];
    XCTAssertEqual(o.boolCol, NO, @"Should be NO");
    
    results = [[AllTypesObject objectsWithPredicate:nil] arraySortedByProperty:@"boolCol" ascending:NO];
    o = results[0];
    XCTAssertEqual(o.boolCol, YES, @"Should be YES");
    
    
    //////////// sort by intCol
    results = [[AllTypesObject objectsWithPredicate:nil] arraySortedByProperty:@"intCol" ascending:YES];
    o = results[0];
    XCTAssertEqual(o.intCol, 1, @"Should be 1");
    
    results = [[AllTypesObject objectsWithPredicate:nil] arraySortedByProperty:@"intCol" ascending:NO];
    o = results[0];
    XCTAssertEqual(o.intCol, 33, @"Should be 33");
    
    
    //////////// sort by dateCol
    results = [[AllTypesObject objectsWithPredicate:nil] arraySortedByProperty:@"dateCol" ascending:YES];
    o = results[0];
    XCTAssertEqualWithAccuracy(o.dateCol.timeIntervalSince1970, date1.timeIntervalSince1970, 1, @"Should be date1");
    
    results = [[AllTypesObject objectsWithPredicate:nil] arraySortedByProperty:@"dateCol" ascending:NO];
    o = results[0];
    XCTAssertEqualWithAccuracy(o.dateCol.timeIntervalSince1970, date33.timeIntervalSince1970, 1, @"Should be date33");
    
    
    //////////// sort by doubleCol
    results = [[AllTypesObject objectsWithPredicate:nil] arraySortedByProperty:@"doubleCol" ascending:YES];
    o = results[0];
    XCTAssertEqual(o.doubleCol, 1.0, @"Should be 1.0");
    
    results = [[AllTypesObject objectsWithPredicate:nil] arraySortedByProperty:@"doubleCol" ascending:NO];
    o = results[0];
    XCTAssertEqualWithAccuracy(o.doubleCol, 3.3, 0.0000001, @"Should be 3.3");
    
    
    //////////// sort by floatCol
    results = [[AllTypesObject objectsWithPredicate:nil] arraySortedByProperty:@"floatCol" ascending:YES];
    o = results[0];
    XCTAssertEqual(o.floatCol, 1.0, @"Should be 1.0");
    
    results = [[AllTypesObject objectsWithPredicate:nil] arraySortedByProperty:@"floatCol" ascending:NO];
    o = results[0];
    XCTAssertEqualWithAccuracy(o.floatCol, 3.3, 0.0000001, @"Should be 3.3");
    
    
    //////////// sort by stringCol
    results = [[AllTypesObject objectsWithPredicate:nil] arraySortedByProperty:@"stringCol" ascending:YES];
    o = results[0];
    XCTAssertEqualObjects(o.stringCol, @"a", @"Should be a");
    
    results = [[AllTypesObject objectsWithPredicate:nil] arraySortedByProperty:@"stringCol" ascending:NO];
    o = results[0];
    XCTAssertEqualObjects(o.stringCol, @"cc", @"Should be cc");
    
    
    // sort by mixed column
    XCTAssertThrows([[AllTypesObject objectsWithPredicate:nil] arraySortedByProperty:@"mixedCol" ascending:YES], @"Sort on mixed col not supported");
    XCTAssertThrows([[AllTypesObject objectsWithPredicate:nil] arraySortedByProperty:@"mixedCol" ascending:NO], @"Sort on mixed col not supported");
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
    
    NSString *className = AllTypesObject.className;
    
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
    XCTAssertNoThrow([realm objects:className withPredicateFormat:@"stringCol == 'test'"], @"==");
    XCTAssertNoThrow([realm objects:className withPredicateFormat:@"stringCol != 'test'"], @"!=");
    
    // ANY
    XCTAssertNoThrow([realm objects:className withPredicateFormat:@"ANY intCol > 5"], @"ANY int > constant");
    
    // ALL
    XCTAssertNoThrow([realm objects:className withPredicateFormat:@"ALL intCol > 5"], @"ALL int > constant");
}

- (void)testPredicateNotSupported
{
    RLMRealm *realm = [RLMRealm defaultRealm];
    
    NSString *className = PersonObject.className;
    
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
    
    NSString *className = PersonObject.className;
    
    // invalid column/property name
    XCTAssertThrows([realm objects:className withPredicateFormat:@"height > 72"], @"invalid column");
    
    // wrong/invalid data types
    XCTAssertThrows([realm objects:className withPredicateFormat:@"age != xyz"], @"invalid type");
    XCTAssertThrows([realm objects:className withPredicateFormat:@"name == 3"], @"invalid type");
    
    className = AllTypesObject.className;
    
    XCTAssertThrows([realm objects:className withPredicateFormat:@"boolCol == Foo"], @"invalid type");
    XCTAssertThrows([realm objects:className withPredicateFormat:@"dateCol == 7"], @"invalid type");
    XCTAssertThrows([realm objects:className withPredicateFormat:@"doubleCol == The"], @"invalid type");
    XCTAssertThrows([realm objects:className withPredicateFormat:@"floatCol == Bar"], @"invalid type");
    XCTAssertThrows([realm objects:className withPredicateFormat:@"intCol == Baz"], @"invalid type");
    
    className = PersonObject.className;
    
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

- (void)testTwoColumnComparison
{
    RLMRealm *realm = [RLMRealm defaultRealm];

    [realm beginWriteTransaction];

    [QueryObject createInRealm:realm withObject:@[@YES, @YES, @1, @2, @23.0f, @1.7f,  @0.0,  @5.55, @"Instance 0"]];
    [QueryObject createInRealm:realm withObject:@[@YES, @NO,  @1, @3, @-5.3f, @4.21f, @1.0,  @4.44, @"Instance 1"]];
    [QueryObject createInRealm:realm withObject:@[@NO,  @NO,  @2, @2, @1.0f,  @3.55f, @99.9, @6.66, @"Instance 2"]];
    [QueryObject createInRealm:realm withObject:@[@NO,  @YES, @3, @6, @4.21f, @1.0f,  @1.0,  @7.77, @"Instance 3"]];
    [QueryObject createInRealm:realm withObject:@[@YES, @YES, @4, @5, @23.0f, @23.0f, @7.4,  @8.88, @"Instance 4"]];
    [QueryObject createInRealm:realm withObject:@[@YES, @NO,  @15, @8, @1.0f,  @66.0f, @1.01, @9.99, @"Instance 5"]];
    [QueryObject createInRealm:realm withObject:@[@NO,  @YES, @15, @15, @1.0f,  @66.0f, @1.01, @9.99, @"Instance 6"]];

    [realm commitWriteTransaction];

    [self executeTwoColumnKeypathRealmComparisonQueryWithClass:[QueryObject class] predicate:@"bool1 == bool1" expectedCount:7];
    [self executeTwoColumnKeypathRealmComparisonQueryWithClass:[QueryObject class] predicate:@"bool1 == bool2" expectedCount:3];
    [self executeTwoColumnKeypathRealmComparisonQueryWithClass:[QueryObject class] predicate:@"bool1 != bool2" expectedCount:4];

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
                                                   predicate:@"int1 == float1"
                                              expectedReason:@"Property type mismatch between int and float"];
    
    [self executeInvalidTwoColumnKeypathRealmComparisonQuery:[QueryObject class]
                                                   predicate:@"float2 >= double1"
                                              expectedReason:@"Property type mismatch between float and double"];
    
    [self executeInvalidTwoColumnKeypathRealmComparisonQuery:[QueryObject class]
                                                   predicate:@"double2 <= int2"
                                              expectedReason:@"Property type mismatch between double and int"];
    
    [self executeInvalidTwoColumnKeypathRealmComparisonQuery:[QueryObject class]
                                                   predicate:@"int2 != recordTag"
                                              expectedReason:@"Property type mismatch between int and string"];
    
    [self executeInvalidTwoColumnKeypathRealmComparisonQuery:[QueryObject class]
                                                   predicate:@"float1 > recordTag"
                                              expectedReason:@"Property type mismatch between float and string"];
    
    [self executeInvalidTwoColumnKeypathRealmComparisonQuery:[QueryObject class]
                                                   predicate:@"double1 < recordTag"
                                              expectedReason:@"Property type mismatch between double and string"];
}

- (void)testValidOperatorsInNumericComparison:(NSString *) comparisonType
                              withProposition:(BOOL(^)(NSPredicateOperatorType)) proposition
{
    NSPredicateOperatorType validOps[] = {
        NSLessThanPredicateOperatorType,
        NSLessThanOrEqualToPredicateOperatorType,
        NSGreaterThanPredicateOperatorType,
        NSGreaterThanOrEqualToPredicateOperatorType,
        NSEqualToPredicateOperatorType,
        NSNotEqualToPredicateOperatorType
    };

    for (NSUInteger i = 0; i < sizeof(validOps) / sizeof(NSPredicateOperatorType); ++i)
    {
        XCTAssert(proposition(validOps[i]),
                  @"%@ operator in %@ comparison.",
                  [RLMPredicateUtil predicateOperatorTypeString:validOps[i]],
                  comparisonType);
    }
}

- (void)testValidOperatorsInNumericComparison
{
    [self testValidOperatorsInNumericComparison:@"integer"
                                withProposition:[RLMPredicateUtil isEmptyIntColPredicate]];
    [self testValidOperatorsInNumericComparison:@"float"
                                withProposition:[RLMPredicateUtil isEmptyFloatColPredicate]];
    [self testValidOperatorsInNumericComparison:@"double"
                                withProposition:[RLMPredicateUtil isEmptyDoubleColPredicate]];
    [self testValidOperatorsInNumericComparison:@"date"
                                withProposition:[RLMPredicateUtil isEmptyDateColPredicate]];
}

- (void)testInvalidOperatorsInNumericComparison:(NSString *) comparisonType
                                withProposition:(BOOL(^)(NSPredicateOperatorType)) proposition
{
    NSPredicateOperatorType invalidOps[] = {
        NSMatchesPredicateOperatorType,
        NSLikePredicateOperatorType,
        NSBeginsWithPredicateOperatorType,
        NSEndsWithPredicateOperatorType,
        NSInPredicateOperatorType,
        NSContainsPredicateOperatorType
    };

    for (NSUInteger i = 0; i < sizeof(invalidOps) / sizeof(NSPredicateOperatorType); ++i)
    {
        XCTAssertThrowsSpecificNamed(proposition(invalidOps[i]), NSException,
                                     @"filterWithPredicate:orderedBy: - Invalid operator type",
                                     @"%@ operator invalid in %@ comparison.",
                                     [RLMPredicateUtil predicateOperatorTypeString:invalidOps[i]],
                                     comparisonType);
    }
}

- (void)testInvalidOperatorsInNumericComparison
{
    [self testInvalidOperatorsInNumericComparison:@"integer"
                                  withProposition:[RLMPredicateUtil isEmptyIntColPredicate]];
    [self testInvalidOperatorsInNumericComparison:@"float"
                                  withProposition:[RLMPredicateUtil isEmptyFloatColPredicate]];
    [self testInvalidOperatorsInNumericComparison:@"double"
                                  withProposition:[RLMPredicateUtil isEmptyDoubleColPredicate]];
    [self testInvalidOperatorsInNumericComparison:@"date"
                                  withProposition:[RLMPredicateUtil isEmptyDateColPredicate]];
}

- (void)testCustomSelectorsInNumericComparison:(NSString *) comparisonType
                               withProposition:(BOOL(^)()) proposition
{
    XCTAssertThrowsSpecificNamed(proposition(), NSException,
                                 @"filterWithPredicate:orderedBy: - Invalid operator type",
                                 @"Custom selector invalid in %@ comparison.", comparisonType);
}

- (void)testCustomSelectorsInNumericComparison
{
    BOOL (^isEmpty)();

    isEmpty = [RLMPredicateUtil alwaysEmptyIntColSelectorPredicate];
    [self testCustomSelectorsInNumericComparison:@"integer" withProposition:isEmpty];

    isEmpty = [RLMPredicateUtil alwaysEmptyFloatColSelectorPredicate];
    [self testCustomSelectorsInNumericComparison:@"float" withProposition:isEmpty];

    isEmpty = [RLMPredicateUtil alwaysEmptyDoubleColSelectorPredicate];
    [self testCustomSelectorsInNumericComparison:@"double" withProposition:isEmpty];

    isEmpty = [RLMPredicateUtil alwaysEmptyDateColSelectorPredicate];
    [self testCustomSelectorsInNumericComparison:@"date" withProposition:isEmpty];
}

- (void)testBooleanPredicate
{
    XCTAssertEqual([BoolObject objectsWithPredicateFormat:@"boolCol == TRUE"].count,
                   (NSUInteger)0, @"== operator in bool predicate.");
    XCTAssertEqual([BoolObject objectsWithPredicateFormat:@"boolCol != TRUE"].count,
                   (NSUInteger)0, @"== operator in bool predicate.");

    XCTAssertThrowsSpecificNamed([BoolObject objectsWithPredicateFormat:@"boolCol >= TRUE"],
                                 NSException,
                                 @"filterWithPredicate:orderedBy: - Invalid operator type",
                                 @"Invalid operator in bool predicate.");
}

- (void)testStringComparisonInPredicate
{
    // First, supported operators and options.
    // Make sure that case-sensitivity is handled the right way round.
    RLMRealm *realm = [RLMRealm defaultRealm];

    [realm beginWriteTransaction];
    [StringObject createInRealm:realm withObject:(@[@"a"])];
    [realm commitWriteTransaction];

    NSExpression *alpha = [NSExpression expressionForConstantValue:@"A"];

    NSUInteger (^count)(NSPredicateOperatorType, NSComparisonPredicateOptions) =
    ^(NSPredicateOperatorType type, NSComparisonPredicateOptions options) {
        NSPredicate * pred = [RLMPredicateUtil comparisonWithKeyPath: @"stringCol"
                                                          expression: alpha
                                                        operatorType: type
                                                             options: options];
        return [StringObject objectsWithPredicate: pred].count;
    };

    XCTAssertEqual(count(NSBeginsWithPredicateOperatorType, 0),
                   (NSUInteger)0, @"Case-sensitive BEGINSWITH operator in string comparison.");
    XCTAssertEqual(count(NSBeginsWithPredicateOperatorType, NSCaseInsensitivePredicateOption),
                   (NSUInteger)1, @"Case-insensitive BEGINSWITH operator in string comparison.");

    XCTAssertEqual(count(NSEndsWithPredicateOperatorType, 0),
                   (NSUInteger)0, @"Case-sensitive ENDSWITH operator in string comparison.");
    XCTAssertEqual(count(NSEndsWithPredicateOperatorType, NSCaseInsensitivePredicateOption),
                   (NSUInteger)1, @"Case-insensitive ENDSWITH operator in string comparison.");

    XCTAssertEqual(count(NSContainsPredicateOperatorType, 0),
                   (NSUInteger)0, @"Case-sensitive CONTAINS operator in string comparison.");
    XCTAssertEqual(count(NSContainsPredicateOperatorType, NSCaseInsensitivePredicateOption),
                   (NSUInteger)1, @"Case-insensitive CONTAINS operator in string comparison.");

    XCTAssertEqual(count(NSEqualToPredicateOperatorType, 0),
                   (NSUInteger)0, @"Case-sensitive = or == operator in string comparison.");
    XCTAssertEqual(count(NSEqualToPredicateOperatorType, NSCaseInsensitivePredicateOption),
                   (NSUInteger)1, @"Case-insensitive = or == operator in string comparison.");

    XCTAssertEqual(count(NSNotEqualToPredicateOperatorType, 0),
                   (NSUInteger)1, @"Case-sensitive != or <> operator in string comparison.");
    XCTAssertEqual(count(NSNotEqualToPredicateOperatorType, NSCaseInsensitivePredicateOption),
                   (NSUInteger)0, @"Case-insensitive != or <> operator in string comparison.");

    // Unsupported (but valid) modifiers.
    XCTAssertThrowsSpecificNamed(count(NSBeginsWithPredicateOperatorType,
                                       NSDiacriticInsensitivePredicateOption), NSException,
                                 @"filterWithPredicate:orderedBy: - Invalid predicate option",
                                 @"Diachritic insensitivity is not supported.");

    // Unsupported (but valid) operators.
    XCTAssertThrowsSpecificNamed(count(NSLikePredicateOperatorType, 0), NSException,
                                 @"filterWithPredicate:orderedBy: - Invalid operator type",
                                 @"LIKE not supported for string comparison.");
    XCTAssertThrowsSpecificNamed(count(NSMatchesPredicateOperatorType, 0), NSException,
                                 @"filterWithPredicate:orderedBy: - Invalid operator type",
                                 @"MATCHES not supported in string comparison.");

    // Invalid operators.
    XCTAssertThrowsSpecificNamed(count(NSLessThanPredicateOperatorType, 0), NSException,
                                 @"filterWithPredicate:orderedBy: - Invalid operator type",
                                 @"Invalid operator in string comparison.");
}

- (void)testBinaryComparisonInPredicate
{
    NSExpression *binary = [NSExpression expressionForConstantValue:[[NSData alloc] init]];

    NSUInteger (^count)(NSPredicateOperatorType) = ^(NSPredicateOperatorType type) {
        NSPredicate * pred = [RLMPredicateUtil comparisonWithKeyPath: @"binaryCol"
                                                          expression: binary
                                                        operatorType: type];
        return [BinaryObject objectsWithPredicate: pred].count;
    };

    XCTAssertEqual(count(NSBeginsWithPredicateOperatorType), (NSUInteger)0,
                   @"BEGINSWITH operator in binary comparison.");
    XCTAssertEqual(count(NSEndsWithPredicateOperatorType), (NSUInteger)0,
                   @"ENDSWITH operator in binary comparison.");
    XCTAssertEqual(count(NSContainsPredicateOperatorType), (NSUInteger)0,
                   @"CONTAINS operator in binary comparison.");
    XCTAssertEqual(count(NSEqualToPredicateOperatorType), (NSUInteger)0,
                   @"= or == operator in binary comparison.");
    XCTAssertEqual(count(NSNotEqualToPredicateOperatorType), (NSUInteger)0,
                   @"!= or <> operator in binary comparison.");

    // Invalid operators.
    XCTAssertThrowsSpecificNamed(count(NSLessThanPredicateOperatorType), NSException,
                                 @"filterWithPredicate:orderedBy: - Invalid operator type",
                                 @"Invalid operator in binary comparison.");
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
    RLMArray *queryResult = [QueryObject objectsWithPredicateFormat:predicate];
    NSUInteger actualCount = queryResult.count;
    XCTAssertEqual(actualCount, expectedCount, @"Predicate: %@, Expecting %zd result(s), found %zd",
                   predicate, expectedCount, actualCount);
}

- (void)executeInvalidTwoColumnKeypathRealmComparisonQuery:(Class)class
                                                 predicate:(NSString *)predicate
                                            expectedReason:(NSString *)expectedReason
{
    RLMRealm *realm = [RLMRealm defaultRealm];
    @try {
        RLMArray *queryResult = [realm objects:NSStringFromClass(class)
                           withPredicateFormat:predicate];
        NSUInteger actualCount = queryResult.count;
#pragma unused(actualCount)
        
        XCTFail(@"Predicate: %@ - exception expected.", predicate);
    }
    @catch (NSException *exception) {
        if (![expectedReason isEqualToString:exception.reason]) {
            XCTFail(@"Exception reason: expected \"%@\" received @\"%@\"", expectedReason, exception.reason);
        }
        realm = nil;
    }
}

@end
