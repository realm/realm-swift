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

#pragma mark - Tests

@interface QueryTests : RLMTestCase
@end

@implementation QueryTests

- (void)testBasicQuery
{
    RLMRealm *realm = [self realmWithTestPath];

    [realm beginWriteTransaction];
    [PersonObject createInRealm:realm withValue:@[@"Fiel", @27]];
    [PersonObject createInRealm:realm withValue:@[@"Ari", @33]];
    [PersonObject createInRealm:realm withValue:@[@"Tim", @29]];
    [realm commitWriteTransaction];

    // query on realm
    XCTAssertEqual([PersonObject objectsInRealm:realm where:@"age > 28"].count, 2U, @"Expecting 2 results");

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

    RLMResults *betweenResults = [AllTypesObject objectsWithPredicate:[NSPredicate predicateWithFormat:@"intCol BETWEEN %@", @[@2, @3]]];
    XCTAssertEqual(betweenResults.count, 2U, @"Should equal 2");
    betweenResults = [AllTypesObject objectsWithPredicate:[NSPredicate predicateWithFormat:@"floatCol BETWEEN %@", @[@1.0f, @4.0f]]];
    XCTAssertEqual(betweenResults.count, 4U, @"Should equal 4");
    betweenResults = [AllTypesObject objectsWithPredicate:[NSPredicate predicateWithFormat:@"doubleCol BETWEEN %@", @[@3.0, @7.0f]]];
    XCTAssertEqual(betweenResults.count, 2U, @"Should equal 2");
    betweenResults = [AllTypesObject objectsWithPredicate:[NSPredicate predicateWithFormat:@"dateCol BETWEEN %@", @[date2,date3]]];
    XCTAssertEqual(betweenResults.count, 2U, @"Should equal 2");

    betweenResults = [AllTypesObject objectsWhere:@"intCol BETWEEN {2, 3}"];
    XCTAssertEqual(betweenResults.count, 2U, @"Should equal 2");
    betweenResults = [AllTypesObject objectsWhere:@"doubleCol BETWEEN {3.0, 7.0}"];
    XCTAssertEqual(betweenResults.count, 2U, @"Should equal 2");

    betweenResults = [AllTypesObject.allObjects objectsWhere:@"intCol BETWEEN {2, 3}"];
    XCTAssertEqual(betweenResults.count, 2U, @"Should equal 2");
    betweenResults = [AllTypesObject.allObjects objectsWhere:@"doubleCol BETWEEN {3.0, 7.0}"];
    XCTAssertEqual(betweenResults.count, 2U, @"Should equal 2");
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

    RLMResults *dateResults = [AllTypesObject objectsWithPredicate:[NSPredicate predicateWithFormat:@"dateCol < %@", date3]];
    XCTAssertEqual(dateResults.count, 2U, @"2 dates smaller");
    dateResults = [AllTypesObject objectsWithPredicate:[NSPredicate predicateWithFormat:@"dateCol =< %@", date3]];
    XCTAssertEqual(dateResults.count, 3U, @"3 dates smaller or equal");
    dateResults = [AllTypesObject objectsWithPredicate:[NSPredicate predicateWithFormat:@"dateCol > %@", date1]];
    XCTAssertEqual(dateResults.count, 2U, @"2 dates greater");
    dateResults = [AllTypesObject objectsWithPredicate:[NSPredicate predicateWithFormat:@"dateCol => %@", date1]];
    XCTAssertEqual(dateResults.count, 3U, @"3 dates greater or equal");
    dateResults = [AllTypesObject objectsWithPredicate:[NSPredicate predicateWithFormat:@"dateCol == %@", date1]];
    XCTAssertEqual(dateResults.count, 1U, @"1 date equal to");
    dateResults = [AllTypesObject objectsWithPredicate:[NSPredicate predicateWithFormat:@"dateCol != %@", date1]];
    XCTAssertEqual(dateResults.count, 2U, @"2 dates not equal to");
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
    RLMResults *all = [PersonObject allObjects];
    XCTAssertEqual(all.count, 3U, @"Expecting 3 results");

    RLMResults *results = [PersonObject objectsWhere:@"age == 27"];
    XCTAssertEqual(results.count, 1U, @"Expecting 1 results");

    // with order
    results = [[PersonObject objectsWhere:@"age > 28"] sortedResultsUsingProperty:@"age" ascending:YES];
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
    XCTAssertEqual([all objectsWhere:@"age == 27"].count, 1U, @"Expecting 1 result");
    XCTAssertEqual([all objectsWhere:@"age == 28"].count, 0U, @"Expecting 0 results");
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
    RLMRealm *realm = [RLMRealm defaultRealm];

    NSString *className = PersonObject.className;

    // testing for null
    XCTAssertThrows([realm objects:className where:@"stringCol = nil"], @"test for nil");

    // ANY
    XCTAssertThrows([realm objects:className where:@"ANY intCol > 5"], @"ANY int > constant");

    // ALL
    XCTAssertThrows([realm objects:className where:@"ALL intCol > 5"], @"ALL int > constant");

    // NONE
    XCTAssertThrows([realm objects:className where:@"NONE intCol > 5"], @"NONE int > constant");
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

- (void)testTwoColumnComparison
{
    RLMRealm *realm = [RLMRealm defaultRealm];

    [realm beginWriteTransaction];

    [QueryObject createInRealm:realm withValue:@[@YES, @YES, @1, @2, @23.0f, @1.7f,  @0.0,  @5.55, @"a", @"a"]];
    [QueryObject createInRealm:realm withValue:@[@YES, @NO,  @1, @3, @-5.3f, @4.21f, @1.0,  @4.44, @"a", @"A"]];
    [QueryObject createInRealm:realm withValue:@[@NO,  @NO,  @2, @2, @1.0f,  @3.55f, @99.9, @6.66, @"a", @"ab"]];
    [QueryObject createInRealm:realm withValue:@[@NO,  @YES, @3, @6, @4.21f, @1.0f,  @1.0,  @7.77, @"a", @"AB"]];
    [QueryObject createInRealm:realm withValue:@[@YES, @YES, @4, @5, @23.0f, @23.0f, @7.4,  @8.88, @"a", @"b"]];
    [QueryObject createInRealm:realm withValue:@[@YES, @NO,  @15, @8, @1.0f,  @66.0f, @1.01, @9.99, @"a", @"ba"]];
    [QueryObject createInRealm:realm withValue:@[@NO,  @YES, @15, @15, @1.0f,  @66.0f, @1.01, @9.99, @"a", @"BA"]];

    [realm commitWriteTransaction];

    XCTAssertEqual(7U, [QueryObject objectsWhere:@"bool1 == bool1"].count);
    XCTAssertEqual(3U, [QueryObject objectsWhere:@"bool1 == bool2"].count);
    XCTAssertEqual(4U, [QueryObject objectsWhere:@"bool1 != bool2"].count);

    XCTAssertEqual(7U, [QueryObject objectsWhere:@"int1 == int1"].count);
    XCTAssertEqual(2U, [QueryObject objectsWhere:@"int1 == int2"].count);
    XCTAssertEqual(5U, [QueryObject objectsWhere:@"int1 != int2"].count);
    XCTAssertEqual(1U, [QueryObject objectsWhere:@"int1 > int2"].count);
    XCTAssertEqual(4U, [QueryObject objectsWhere:@"int1 < int2"].count);
    XCTAssertEqual(3U, [QueryObject objectsWhere:@"int1 >= int2"].count);
    XCTAssertEqual(6U, [QueryObject objectsWhere:@"int1 <= int2"].count);

    XCTAssertEqual(7U, [QueryObject objectsWhere:@"float1 == float1"].count);
    XCTAssertEqual(1U, [QueryObject objectsWhere:@"float1 == float2"].count);
    XCTAssertEqual(6U, [QueryObject objectsWhere:@"float1 != float2"].count);
    XCTAssertEqual(2U, [QueryObject objectsWhere:@"float1 > float2"].count);
    XCTAssertEqual(4U, [QueryObject objectsWhere:@"float1 < float2"].count);
    XCTAssertEqual(3U, [QueryObject objectsWhere:@"float1 >= float2"].count);
    XCTAssertEqual(5U, [QueryObject objectsWhere:@"float1 <= float2"].count);

    XCTAssertEqual(7U, [QueryObject objectsWhere:@"double1 == double1"].count);
    XCTAssertEqual(0U, [QueryObject objectsWhere:@"double1 == double2"].count);
    XCTAssertEqual(7U, [QueryObject objectsWhere:@"double1 != double2"].count);
    XCTAssertEqual(1U, [QueryObject objectsWhere:@"double1 > double2"].count);
    XCTAssertEqual(6U, [QueryObject objectsWhere:@"double1 < double2"].count);
    XCTAssertEqual(1U, [QueryObject objectsWhere:@"double1 >= double2"].count);
    XCTAssertEqual(6U, [QueryObject objectsWhere:@"double1 <= double2"].count);

    XCTAssertEqual(7U, [QueryObject objectsWhere:@"string1 == string1"].count);
    XCTAssertEqual(1U, [QueryObject objectsWhere:@"string1 == string2"].count);
    XCTAssertEqual(6U, [QueryObject objectsWhere:@"string1 != string2"].count);
    XCTAssertEqual(7U, [QueryObject objectsWhere:@"string1 CONTAINS string1"].count);
    XCTAssertEqual(1U, [QueryObject objectsWhere:@"string1 CONTAINS string2"].count);
    XCTAssertEqual(3U, [QueryObject objectsWhere:@"string2 CONTAINS string1"].count);
    XCTAssertEqual(7U, [QueryObject objectsWhere:@"string1 BEGINSWITH string1"].count);
    XCTAssertEqual(1U, [QueryObject objectsWhere:@"string1 BEGINSWITH string2"].count);
    XCTAssertEqual(2U, [QueryObject objectsWhere:@"string2 BEGINSWITH string1"].count);
    XCTAssertEqual(7U, [QueryObject objectsWhere:@"string1 ENDSWITH string1"].count);
    XCTAssertEqual(1U, [QueryObject objectsWhere:@"string1 ENDSWITH string2"].count);
    XCTAssertEqual(2U, [QueryObject objectsWhere:@"string2 ENDSWITH string1"].count);

    XCTAssertEqual(7U, [QueryObject objectsWhere:@"string1 ==[c] string1"].count);
    XCTAssertEqual(2U, [QueryObject objectsWhere:@"string1 ==[c] string2"].count);
    XCTAssertEqual(5U, [QueryObject objectsWhere:@"string1 !=[c] string2"].count);
    XCTAssertEqual(7U, [QueryObject objectsWhere:@"string1 CONTAINS[c] string1"].count);
    XCTAssertEqual(2U, [QueryObject objectsWhere:@"string1 CONTAINS[c] string2"].count);
    XCTAssertEqual(6U, [QueryObject objectsWhere:@"string2 CONTAINS[c] string1"].count);
    XCTAssertEqual(7U, [QueryObject objectsWhere:@"string1 BEGINSWITH[c] string1"].count);
    XCTAssertEqual(2U, [QueryObject objectsWhere:@"string1 BEGINSWITH[c] string2"].count);
    XCTAssertEqual(4U, [QueryObject objectsWhere:@"string2 BEGINSWITH[c] string1"].count);
    XCTAssertEqual(7U, [QueryObject objectsWhere:@"string1 ENDSWITH[c] string1"].count);
    XCTAssertEqual(2U, [QueryObject objectsWhere:@"string1 ENDSWITH[c] string2"].count);
    XCTAssertEqual(4U, [QueryObject objectsWhere:@"string2 ENDSWITH[c] string1"].count);

    [self executeInvalidTwoColumnKeypathRealmComparisonQuery:[QueryObject className]
                                                   predicate:@"int1 == float1"
                                              expectedReason:@"Property type mismatch between int and float"];

    [self executeInvalidTwoColumnKeypathRealmComparisonQuery:[QueryObject className]
                                                   predicate:@"float2 >= double1"
                                              expectedReason:@"Property type mismatch between float and double"];

    [self executeInvalidTwoColumnKeypathRealmComparisonQuery:[QueryObject className]
                                                   predicate:@"double2 <= int2"
                                              expectedReason:@"Property type mismatch between double and int"];

    [self executeInvalidTwoColumnKeypathRealmComparisonQuery:[QueryObject className]
                                                   predicate:@"int2 != string1"
                                              expectedReason:@"Property type mismatch between int and string"];

    [self executeInvalidTwoColumnKeypathRealmComparisonQuery:[QueryObject className]
                                                   predicate:@"float1 > string1"
                                              expectedReason:@"Property type mismatch between float and string"];

    [self executeInvalidTwoColumnKeypathRealmComparisonQuery:[QueryObject className]
                                                   predicate:@"double1 < string1"
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
        NSContainsPredicateOperatorType
    };

    for (NSUInteger i = 0; i < sizeof(invalidOps) / sizeof(NSPredicateOperatorType); ++i)
    {
        XCTAssertThrowsSpecificNamed(proposition(invalidOps[i]), NSException,
                                     @"Invalid operator type",
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
                                 @"Invalid operator type",
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
    XCTAssertEqual([BoolObject objectsWhere:@"boolCol == TRUE"].count,
                   0U, @"== operator in bool predicate.");
    XCTAssertEqual([BoolObject objectsWhere:@"boolCol != TRUE"].count,
                   0U, @"== operator in bool predicate.");

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
    [realm commitWriteTransaction];

    XCTAssertEqual(1U, [StringObject objectsWhere:@"stringCol BEGINSWITH 'a'"].count);
    XCTAssertEqual(1U, [StringObject objectsWhere:@"stringCol BEGINSWITH 'ab'"].count);
    XCTAssertEqual(1U, [StringObject objectsWhere:@"stringCol BEGINSWITH 'abc'"].count);
    XCTAssertEqual(0U, [StringObject objectsWhere:@"stringCol BEGINSWITH 'abcd'"].count);
    XCTAssertEqual(0U, [StringObject objectsWhere:@"stringCol BEGINSWITH 'abd'"].count);
    XCTAssertEqual(0U, [StringObject objectsWhere:@"stringCol BEGINSWITH 'c'"].count);
    XCTAssertEqual(0U, [StringObject objectsWhere:@"stringCol BEGINSWITH 'A'"].count);
    XCTAssertEqual(1U, [StringObject objectsWhere:@"stringCol BEGINSWITH[c] 'a'"].count);
    XCTAssertEqual(1U, [StringObject objectsWhere:@"stringCol BEGINSWITH[c] 'A'"].count);

    XCTAssertEqual(1U, [AllTypesObject objectsWhere:@"objectCol.stringCol BEGINSWITH 'a'"].count);
    XCTAssertEqual(0U, [AllTypesObject objectsWhere:@"objectCol.stringCol BEGINSWITH 'c'"].count);
    XCTAssertEqual(0U, [AllTypesObject objectsWhere:@"objectCol.stringCol BEGINSWITH 'A'"].count);
    XCTAssertEqual(1U, [AllTypesObject objectsWhere:@"objectCol.stringCol BEGINSWITH[c] 'a'"].count);
    XCTAssertEqual(1U, [AllTypesObject objectsWhere:@"objectCol.stringCol BEGINSWITH[c] 'A'"].count);
}

- (void)testStringEndsWith
{
    RLMRealm *realm = [RLMRealm defaultRealm];

    [realm beginWriteTransaction];
    StringObject *so = [StringObject createInRealm:realm withValue:(@[@"abc"])];
    [AllTypesObject createInRealm:realm withValue:@[@YES, @1, @1.0f, @1.0, @"a", [@"a" dataUsingEncoding:NSUTF8StringEncoding], NSDate.date, @YES, @1LL, @1, so]];
    [realm commitWriteTransaction];

    XCTAssertEqual(1U, [StringObject objectsWhere:@"stringCol ENDSWITH 'c'"].count);
    XCTAssertEqual(1U, [StringObject objectsWhere:@"stringCol ENDSWITH 'bc'"].count);
    XCTAssertEqual(1U, [StringObject objectsWhere:@"stringCol ENDSWITH 'abc'"].count);
    XCTAssertEqual(0U, [StringObject objectsWhere:@"stringCol ENDSWITH 'aabc'"].count);
    XCTAssertEqual(0U, [StringObject objectsWhere:@"stringCol ENDSWITH 'bbc'"].count);
    XCTAssertEqual(0U, [StringObject objectsWhere:@"stringCol ENDSWITH 'a'"].count);
    XCTAssertEqual(0U, [StringObject objectsWhere:@"stringCol ENDSWITH 'C'"].count);
    XCTAssertEqual(1U, [StringObject objectsWhere:@"stringCol ENDSWITH[c] 'c'"].count);
    XCTAssertEqual(1U, [StringObject objectsWhere:@"stringCol ENDSWITH[c] 'C'"].count);

    XCTAssertEqual(1U, [AllTypesObject objectsWhere:@"objectCol.stringCol ENDSWITH 'c'"].count);
    XCTAssertEqual(0U, [AllTypesObject objectsWhere:@"objectCol.stringCol ENDSWITH 'a'"].count);
    XCTAssertEqual(0U, [AllTypesObject objectsWhere:@"objectCol.stringCol ENDSWITH 'C'"].count);
    XCTAssertEqual(1U, [AllTypesObject objectsWhere:@"objectCol.stringCol ENDSWITH[c] 'c'"].count);
    XCTAssertEqual(1U, [AllTypesObject objectsWhere:@"objectCol.stringCol ENDSWITH[c] 'C'"].count);
}

- (void)testStringContains
{
    RLMRealm *realm = [RLMRealm defaultRealm];

    [realm beginWriteTransaction];
    StringObject *so = [StringObject createInRealm:realm withValue:(@[@"abc"])];
    [AllTypesObject createInRealm:realm withValue:@[@YES, @1, @1.0f, @1.0, @"a", [@"a" dataUsingEncoding:NSUTF8StringEncoding], NSDate.date, @YES, @1LL, @1, so]];
    [realm commitWriteTransaction];

    XCTAssertEqual(1U, [StringObject objectsWhere:@"stringCol CONTAINS 'a'"].count);
    XCTAssertEqual(1U, [StringObject objectsWhere:@"stringCol CONTAINS 'b'"].count);
    XCTAssertEqual(1U, [StringObject objectsWhere:@"stringCol CONTAINS 'c'"].count);
    XCTAssertEqual(1U, [StringObject objectsWhere:@"stringCol CONTAINS 'ab'"].count);
    XCTAssertEqual(1U, [StringObject objectsWhere:@"stringCol CONTAINS 'bc'"].count);
    XCTAssertEqual(1U, [StringObject objectsWhere:@"stringCol CONTAINS 'abc'"].count);
    XCTAssertEqual(0U, [StringObject objectsWhere:@"stringCol CONTAINS 'd'"].count);
    XCTAssertEqual(0U, [StringObject objectsWhere:@"stringCol CONTAINS 'aabc'"].count);
    XCTAssertEqual(0U, [StringObject objectsWhere:@"stringCol CONTAINS 'bbc'"].count);

    XCTAssertEqual(0U, [StringObject objectsWhere:@"stringCol CONTAINS 'C'"].count);
    XCTAssertEqual(1U, [StringObject objectsWhere:@"stringCol CONTAINS[c] 'c'"].count);
    XCTAssertEqual(1U, [StringObject objectsWhere:@"stringCol CONTAINS[c] 'C'"].count);

    XCTAssertEqual(0U, [AllTypesObject objectsWhere:@"objectCol.stringCol CONTAINS 'd'"].count);
    XCTAssertEqual(1U, [AllTypesObject objectsWhere:@"objectCol.stringCol CONTAINS 'c'"].count);
    XCTAssertEqual(0U, [AllTypesObject objectsWhere:@"objectCol.stringCol CONTAINS 'C'"].count);
    XCTAssertEqual(1U, [AllTypesObject objectsWhere:@"objectCol.stringCol CONTAINS[c] 'c'"].count);
    XCTAssertEqual(1U, [AllTypesObject objectsWhere:@"objectCol.stringCol CONTAINS[c] 'C'"].count);
}

- (void)testStringEquality
{
    RLMRealm *realm = [RLMRealm defaultRealm];

    [realm beginWriteTransaction];
    StringObject *so = [StringObject createInRealm:realm withValue:(@[@"abc"])];
    [AllTypesObject createInRealm:realm withValue:@[@YES, @1, @1.0f, @1.0, @"a", [@"a" dataUsingEncoding:NSUTF8StringEncoding], NSDate.date, @YES, @1LL, @1, so]];
    [realm commitWriteTransaction];

    XCTAssertEqual(1U, [StringObject objectsWhere:@"stringCol == 'abc'"].count);
    XCTAssertEqual(1U, [StringObject objectsWhere:@"stringCol != 'def'"].count);
    XCTAssertEqual(1U, [StringObject objectsWhere:@"stringCol ==[c] 'abc'"].count);
    XCTAssertEqual(1U, [StringObject objectsWhere:@"stringCol ==[c] 'ABC'"].count);

    XCTAssertEqual(0U, [StringObject objectsWhere:@"stringCol != 'abc'"].count);
    XCTAssertEqual(0U, [StringObject objectsWhere:@"stringCol == 'def'"].count);
    XCTAssertEqual(0U, [StringObject objectsWhere:@"stringCol == 'ABC'"].count);

    XCTAssertEqual(1U, [AllTypesObject objectsWhere:@"objectCol.stringCol == 'abc'"].count);
    XCTAssertEqual(1U, [AllTypesObject objectsWhere:@"objectCol.stringCol != 'def'"].count);

    XCTAssertEqual(1U, [AllTypesObject objectsWhere:@"objectCol.stringCol ==[c] 'abc'"].count);
    XCTAssertEqual(1U, [AllTypesObject objectsWhere:@"objectCol.stringCol ==[c] 'ABC'"].count);

    XCTAssertEqual(0U, [AllTypesObject objectsWhere:@"objectCol.stringCol != 'abc'"].count);
    XCTAssertEqual(0U, [AllTypesObject objectsWhere:@"objectCol.stringCol == 'def'"].count);
    XCTAssertEqual(0U, [AllTypesObject objectsWhere:@"objectCol.stringCol == 'ABC'"].count);
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

- (void)testBinaryComparisonInPredicate
{
    NSExpression *binary = [NSExpression expressionForConstantValue:[[NSData alloc] init]];

    NSUInteger (^count)(NSPredicateOperatorType) = ^(NSPredicateOperatorType type) {
        NSPredicate *pred = [RLMPredicateUtil comparisonWithKeyPath: @"binaryCol"
                                                         expression: binary
                                                       operatorType: type];
        return [BinaryObject objectsWithPredicate: pred].count;
    };

    XCTAssertEqual(count(NSBeginsWithPredicateOperatorType), 0U,
                   @"BEGINSWITH operator in binary comparison.");
    XCTAssertEqual(count(NSEndsWithPredicateOperatorType), 0U,
                   @"ENDSWITH operator in binary comparison.");
    XCTAssertEqual(count(NSContainsPredicateOperatorType), 0U,
                   @"CONTAINS operator in binary comparison.");
    XCTAssertEqual(count(NSEqualToPredicateOperatorType), 0U,
                   @"= or == operator in binary comparison.");
    XCTAssertEqual(count(NSNotEqualToPredicateOperatorType), 0U,
                   @"!= or <> operator in binary comparison.");

    // Invalid operators.
    XCTAssertThrowsSpecificNamed(count(NSLessThanPredicateOperatorType), NSException,
                                 @"Invalid operator type",
                                 @"Invalid operator in binary comparison.");
}

- (void)testKeyPathLocationInComparison
{
    NSExpression *keyPath = [NSExpression expressionForKeyPath:@"intCol"];
    NSExpression *expr = [NSExpression expressionForConstantValue:@0];
    NSPredicate *predicate;

    predicate = [RLMPredicateUtil defaultPredicateGenerator](keyPath, expr);
    XCTAssert([RLMPredicateUtil isEmptyIntColWithPredicate:predicate],
              @"Key path to the left in an integer comparison.");

    predicate = [RLMPredicateUtil defaultPredicateGenerator](expr, keyPath);
    XCTAssert([RLMPredicateUtil isEmptyIntColWithPredicate:predicate],
              @"Key path to the right in an integer comparison.");

    predicate = [RLMPredicateUtil defaultPredicateGenerator](keyPath, keyPath);
    XCTAssert([RLMPredicateUtil isEmptyIntColWithPredicate:predicate],
              @"Key path in both locations in an integer comparison.");

    predicate = [RLMPredicateUtil defaultPredicateGenerator](expr, expr);
    XCTAssertThrowsSpecificNamed([RLMPredicateUtil isEmptyIntColWithPredicate:predicate],
                                 NSException, @"Invalid predicate expressions",
                                 @"Key path in absent in an integer comparison.");
}

- (void)executeTwoColumnKeypathComparisonQueryWithPredicate:(NSString *)predicate
                                              expectedCount:(NSUInteger)expectedCount
{
    RLMResults *queryResult = [QueryObject objectsWhere:predicate];
    NSUInteger actualCount = queryResult.count;
    XCTAssertEqual(actualCount, expectedCount, @"Predicate: %@, Expecting %zd result(s), found %zd",
                   predicate, expectedCount, actualCount);
}

- (void)executeInvalidTwoColumnKeypathRealmComparisonQuery:(NSString *)className
                                                 predicate:(NSString *)predicate
                                            expectedReason:(NSString *)expectedReason
{
    RLMRealm *realm = [RLMRealm defaultRealm];
    RLMAssertThrowsWithReasonMatching([realm objects:className where:predicate], expectedReason);
}


- (void)testFloatQuery
{
    RLMRealm *realm = [self realmWithTestPath];

    [realm beginWriteTransaction];
    [FloatObject createInRealm:realm withValue:@[@1.7f]];
    [realm commitWriteTransaction];

    XCTAssertEqual(([[realm objects:[FloatObject className] where:@"floatCol > 1"] count]), 1U, @"1 object expected");
    XCTAssertEqual(([[realm objects:[FloatObject className] where:@"floatCol > %d", 1] count]), 1U, @"1 object expected");
    XCTAssertEqual(([[realm objects:[FloatObject className] where:@"floatCol = 1.7"] count]), 1U, @"1 object expected");
    XCTAssertEqual(([[realm objects:[FloatObject className] where:@"floatCol = %f", 1.7f] count]), 1U, @"1 object expected");
    XCTAssertEqual(([[realm objects:[FloatObject className] where:@"floatCol > 1.0"] count]), 1U, @"1 object expected");
    XCTAssertEqual(([[realm objects:[FloatObject className] where:@"floatCol >= 1.0"] count]), 1U, @"1 object expected");
    XCTAssertEqual(([[realm objects:[FloatObject className] where:@"floatCol < 1.0"] count]), 0U, @"0 objects expected");
    XCTAssertEqual(([[realm objects:[FloatObject className] where:@"floatCol <= 1.0"] count]), 0U, @"0 objects expected");
    XCTAssertEqual(([[realm objects:[FloatObject className] where:@"floatCol BETWEEN %@", @[@1.0, @2.0]] count]), 1U, @"1 object expected");
    XCTAssertEqual(([[realm objects:[FloatObject className] where:@"floatCol = %e", 1.7] count]), 1U, @"1 object expected");
    XCTAssertEqual(([[realm objects:[FloatObject className] where:@"floatCol == %f", FLT_MAX] count]), 0U, @"0 objects expected");
    XCTAssertThrows(([[realm objects:[FloatObject className] where:@"floatCol = 3.5e+38"] count]), @"Too large to be a float");
    XCTAssertThrows(([[realm objects:[FloatObject className] where:@"floatCol = -3.5e+38"] count]), @"Too small to be a float");
}

- (void)testLiveQueriesInsideTransaction
{
    RLMRealm *realm = [RLMRealm defaultRealm];

    [realm beginWriteTransaction];
    {
        [QueryObject createInRealm:realm withValue:@[@YES, @YES, @1, @2, @23.0f, @1.7f,  @0.0,  @5.55, @"", @""]];

        RLMResults *resultsQuery = [QueryObject objectsWhere:@"bool1 = YES"];
        RLMResults *resultsTableView = [QueryObject objectsWhere:@"bool1 = YES"];

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
        QueryObject *q1 = [QueryObject createInRealm:realm withValue:@[@NO, @YES, @1, @2, @23.0f, @1.7f,  @0.0,  @5.55, @"", @""]];
        XCTAssertEqual(resultsQuery.count, 0U);
        XCTAssertEqual(resultsTableView.count, 0U);

        // Change object to match query
        q1.bool1 = YES;
        XCTAssertEqual(resultsQuery.count, 1U);
        XCTAssertEqual(resultsTableView.count, 1U);

        // Add another object that matches
        [QueryObject createInRealm:realm withValue:@[@YES, @NO,  @1, @3, @-5.3f, @4.21f, @1.0,  @4.44, @"", @""]];
        XCTAssertEqual(resultsQuery.count, 2U);
        XCTAssertEqual(resultsTableView.count, 2U);
    }
    [realm commitWriteTransaction];
}

- (void)testLiveQueriesBetweenTransactions
{
    RLMRealm *realm = [RLMRealm defaultRealm];

    [realm beginWriteTransaction];
    [QueryObject createInRealm:realm withValue:@[@YES, @YES, @1, @2, @23.0f, @1.7f,  @0.0,  @5.55, @"", @""]];
    [realm commitWriteTransaction];

    RLMResults *resultsQuery = [QueryObject objectsWhere:@"bool1 = YES"];
    RLMResults *resultsTableView = [QueryObject objectsWhere:@"bool1 = YES"];

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
    QueryObject *q1 = [QueryObject createInRealm:realm withValue:@[@NO, @YES, @1, @2, @23.0f, @1.7f,  @0.0,  @5.55, @"", @""]];
    [realm commitWriteTransaction];

    XCTAssertEqual(resultsQuery.count, 0U);
    XCTAssertEqual(resultsTableView.count, 0U);

    // Change object to match query
    [realm beginWriteTransaction];
    q1.bool1 = YES;
    [realm commitWriteTransaction];

    XCTAssertEqual(resultsQuery.count, 1U);
    XCTAssertEqual(resultsTableView.count, 1U);

    // Add another object that matches
    [realm beginWriteTransaction];
    [QueryObject createInRealm:realm withValue:@[@YES, @NO,  @1, @3, @-5.3f, @4.21f, @1.0,  @4.44, @"", @""]];
    [realm commitWriteTransaction];

    XCTAssertEqual(resultsQuery.count, 2U);
    XCTAssertEqual(resultsTableView.count, 2U);
}

- (void)makeDogWithName:(NSString *)name owner:(NSString *)ownerName {
    RLMRealm *realm = [self realmWithTestPath];

    OwnerObject *owner = [[OwnerObject alloc] init];
    owner.name = ownerName;
    owner.dog = [[DogObject alloc] init];
    owner.dog.dogName = name;

    [realm beginWriteTransaction];
    [realm addObject:owner];
    [realm commitWriteTransaction];
}

- (void)makeDogWithAge:(int)age owner:(NSString *)ownerName {
    RLMRealm *realm = [self realmWithTestPath];

    OwnerObject *owner = [[OwnerObject alloc] init];
    owner.name = ownerName;
    owner.dog = [[DogObject alloc] init];
    owner.dog.dogName = @"";
    owner.dog.age = age;

    [realm beginWriteTransaction];
    [realm addObject:owner];
    [realm commitWriteTransaction];
}

- (void)testLinkQueryString
{
    RLMRealm *realm = [self realmWithTestPath];

    [self makeDogWithName:@"Harvie" owner:@"Tim"];
    XCTAssertEqual(([OwnerObject objectsInRealm:realm where:@"dog.dogName  = 'Harvie'"].count), 1U);
    XCTAssertEqual(([OwnerObject objectsInRealm:realm where:@"dog.dogName != 'Harvie'"].count), 0U);
    XCTAssertEqual(([OwnerObject objectsInRealm:realm where:@"dog.dogName  = 'eivraH'"].count), 0U);
    XCTAssertEqual(([OwnerObject objectsInRealm:realm where:@"dog.dogName  = 'Fido'"].count), 0U);
    XCTAssertEqual(([OwnerObject objectsInRealm:realm where:@"dog.dogName IN {'Fido', 'Harvie'}"].count), 1U);
    XCTAssertEqual(([OwnerObject objectsInRealm:realm where:@"dog.dogName IN {'Fido', 'eivraH'}"].count), 0U);

    [self makeDogWithName:@"Harvie" owner:@"Joe"];
    XCTAssertEqual(([OwnerObject objectsInRealm:realm where:@"dog.dogName  = 'Harvie'"].count), 2U);
    XCTAssertEqual(([OwnerObject objectsInRealm:realm where:@"dog.dogName != 'Harvie'"].count), 0U);
    XCTAssertEqual(([OwnerObject objectsInRealm:realm where:@"dog.dogName  = 'eivraH'"].count), 0U);
    XCTAssertEqual(([OwnerObject objectsInRealm:realm where:@"dog.dogName  = 'Fido'"].count), 0U);
    XCTAssertEqual(([OwnerObject objectsInRealm:realm where:@"dog.dogName IN {'Fido', 'Harvie'}"].count), 2U);
    XCTAssertEqual(([OwnerObject objectsInRealm:realm where:@"dog.dogName IN {'Fido', 'eivraH'}"].count), 0U);

    [self makeDogWithName:@"Fido" owner:@"Jim"];
    XCTAssertEqual(([OwnerObject objectsInRealm:realm where:@"dog.dogName  = 'Harvie'"].count), 2U);
    XCTAssertEqual(([OwnerObject objectsInRealm:realm where:@"dog.dogName != 'Harvie'"].count), 1U);
    XCTAssertEqual(([OwnerObject objectsInRealm:realm where:@"dog.dogName  = 'eivraH'"].count), 0U);
    XCTAssertEqual(([OwnerObject objectsInRealm:realm where:@"dog.dogName  = 'Fido'"].count), 1U);
    XCTAssertEqual(([OwnerObject objectsInRealm:realm where:@"dog.dogName IN {'Fido', 'Harvie'}"].count), 3U);
    XCTAssertEqual(([OwnerObject objectsInRealm:realm where:@"dog.dogName IN {'Fido', 'eivraH'}"].count), 1U);

    XCTAssertEqual(([OwnerObject objectsInRealm:realm where:@"dog.dogName = 'Harvie' and name = 'Tim'"].count), 1U);
    XCTAssertEqual(([OwnerObject objectsInRealm:realm where:@"dog.dogName = 'Harvie' and name = 'Jim'"].count), 0U);

    // test invalid operators
    XCTAssertThrows([realm objects:[OwnerObject className] where:@"dog.dogName > 'Harvie'"], @"Invalid operator should throw");
}

- (void)testLinkQueryInt
{
    RLMRealm *realm = [self realmWithTestPath];

    [self makeDogWithAge:5 owner:@"Tim"];
    XCTAssertEqual(([OwnerObject objectsInRealm:realm where:@"dog.age  = 5"].count), 1U);
    XCTAssertEqual(([OwnerObject objectsInRealm:realm where:@"dog.age != 5"].count), 0U);
    XCTAssertEqual(([OwnerObject objectsInRealm:realm where:@"dog.age  = 10"].count), 0U);
    XCTAssertEqual(([OwnerObject objectsInRealm:realm where:@"dog.age  = 8"].count), 0U);
    XCTAssertEqual(([OwnerObject objectsInRealm:realm where:@"dog.age IN {5, 8}"].count), 1U);
    XCTAssertEqual(([OwnerObject objectsInRealm:realm where:@"dog.age IN {8, 10}"].count), 0U);
    XCTAssertEqual(([OwnerObject objectsInRealm:realm where:@"dog.age BETWEEN {0, 10}"].count), 1U);
    XCTAssertEqual(([OwnerObject objectsInRealm:realm where:@"dog.age BETWEEN {0, 7}"].count), 1U);

    [self makeDogWithAge:5 owner:@"Joe"];
    XCTAssertEqual(([OwnerObject objectsInRealm:realm where:@"dog.age  = 5"].count), 2U);
    XCTAssertEqual(([OwnerObject objectsInRealm:realm where:@"dog.age != 5"].count), 0U);
    XCTAssertEqual(([OwnerObject objectsInRealm:realm where:@"dog.age  = 10"].count), 0U);
    XCTAssertEqual(([OwnerObject objectsInRealm:realm where:@"dog.age  = 8"].count), 0U);
    XCTAssertEqual(([OwnerObject objectsInRealm:realm where:@"dog.age IN {5, 8}"].count), 2U);
    XCTAssertEqual(([OwnerObject objectsInRealm:realm where:@"dog.age IN {8, 10}"].count), 0U);
    XCTAssertEqual(([OwnerObject objectsInRealm:realm where:@"dog.age BETWEEN {0, 10}"].count), 2U);
    XCTAssertEqual(([OwnerObject objectsInRealm:realm where:@"dog.age BETWEEN {0, 7}"].count), 2U);

    [self makeDogWithAge:8 owner:@"Jim"];
    XCTAssertEqual(([OwnerObject objectsInRealm:realm where:@"dog.age  = 5"].count), 2U);
    XCTAssertEqual(([OwnerObject objectsInRealm:realm where:@"dog.age != 5"].count), 1U);
    XCTAssertEqual(([OwnerObject objectsInRealm:realm where:@"dog.age  = 10"].count), 0U);
    XCTAssertEqual(([OwnerObject objectsInRealm:realm where:@"dog.age  = 8"].count), 1U);
    XCTAssertEqual(([OwnerObject objectsInRealm:realm where:@"dog.age IN {5, 8}"].count), 3U);
    XCTAssertEqual(([OwnerObject objectsInRealm:realm where:@"dog.age IN {8, 10}"].count), 1U);
    XCTAssertEqual(([OwnerObject objectsInRealm:realm where:@"dog.age BETWEEN {0, 10}"].count), 3U);
    XCTAssertEqual(([OwnerObject objectsInRealm:realm where:@"dog.age BETWEEN {0, 7}"].count), 2U);
}

- (void)testLinkQueryAllTypes
{
    RLMRealm *realm = [self realmWithTestPath];

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

    XCTAssertEqual([[realm objects:[LinkToAllTypesObject className] where:@"allTypesCol.boolCol = YES"] count], 1U);
    XCTAssertEqual([[realm objects:[LinkToAllTypesObject className] where:@"allTypesCol.boolCol = NO"] count], 0U);

    XCTAssertEqual([[realm objects:[LinkToAllTypesObject className] where:@"allTypesCol.intCol = 1"] count], 1U);
    XCTAssertEqual([[realm objects:[LinkToAllTypesObject className] where:@"allTypesCol.intCol != 1"] count], 0U);
    XCTAssertEqual([[realm objects:[LinkToAllTypesObject className] where:@"allTypesCol.intCol > 0"] count], 1U);
    XCTAssertEqual([[realm objects:[LinkToAllTypesObject className] where:@"allTypesCol.intCol > 1"] count], 0U);

    NSPredicate *predEq = [NSPredicate predicateWithFormat:@"allTypesCol.floatCol = %f", 1.1];
    XCTAssertEqual([LinkToAllTypesObject objectsInRealm:realm withPredicate:predEq].count, 1U);
    NSPredicate *predLessEq = [NSPredicate predicateWithFormat:@"allTypesCol.floatCol <= %f", 1.1];
    XCTAssertEqual([LinkToAllTypesObject objectsInRealm:realm withPredicate:predLessEq].count, 1U);
    NSPredicate *predLess = [NSPredicate predicateWithFormat:@"allTypesCol.floatCol < %f", 1.1];
    XCTAssertEqual([LinkToAllTypesObject objectsInRealm:realm withPredicate:predLess].count, 0U);

    XCTAssertEqual([[realm objects:[LinkToAllTypesObject className] where:@"allTypesCol.doubleCol = 1.11"] count], 1U);
    XCTAssertEqual([[realm objects:[LinkToAllTypesObject className] where:@"allTypesCol.doubleCol >= 1.11"] count], 1U);
    XCTAssertEqual([[realm objects:[LinkToAllTypesObject className] where:@"allTypesCol.doubleCol > 1.11"] count], 0U);

    XCTAssertEqual([[realm objects:[LinkToAllTypesObject className] where:@"allTypesCol.longCol = 11"] count], 1U);
    XCTAssertEqual([[realm objects:[LinkToAllTypesObject className] where:@"allTypesCol.longCol != 11"] count], 0U);

    XCTAssertEqual(([[realm objects:[LinkToAllTypesObject className] where:@"allTypesCol.dateCol = %@", now] count]), 1U);
    XCTAssertEqual(([[realm objects:[LinkToAllTypesObject className] where:@"allTypesCol.dateCol != %@", now] count]), 0U);
}

- (void)testLinkQueryInvalid {
    XCTAssertThrows([LinkToAllTypesObject objectsWhere:@"allTypesCol.binaryCol = 'a'"], @"Binary data not supported");
    XCTAssertThrows([LinkToAllTypesObject objectsWhere:@"allTypesCol.mixedCol = 'a'"], @"Mixed data not supported");
    XCTAssertThrows([LinkToAllTypesObject objectsWhere:@"allTypesCol.invalidCol = 'a'"], @"Invalid column name should throw");

    XCTAssertThrows([LinkToAllTypesObject objectsWhere:@"allTypesCol.longCol = 'a'"], @"Wrong data type should throw");

    XCTAssertThrows([LinkToAllTypesObject objectsWhere:@"intArray.intCol > 5"], @"RLMArray query without ANY modifier should throw");
}


- (void)testLinkQueryMany
{
    RLMRealm *realm = [self realmWithTestPath];

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

    XCTAssertEqual([[realm objects:[ArrayPropertyObject className] where:@"ANY intArray.intCol > 10"] count], 0U);
    XCTAssertEqual([[realm objects:[ArrayPropertyObject className] where:@"ANY intArray.intCol > 5"] count], 1U);
    XCTAssertEqual([[realm objects:[ArrayPropertyObject className] where:@"ANY array.stringCol = '1'"] count], 1U);
    XCTAssertEqual([realm objects:[ArrayPropertyObject className] where:@"NONE intArray.intCol == 5"].count, 0U);
    XCTAssertEqual([realm objects:[ArrayPropertyObject className] where:@"NONE intArray.intCol > 10"].count, 1U);

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
    XCTAssertEqual([[realm objects:[ArrayPropertyObject className] where:@"ANY intArray.intCol > 10"] count], 0U);
    XCTAssertEqual([[realm objects:[ArrayPropertyObject className] where:@"ANY intArray.intCol > 5"] count], 1U);
    XCTAssertEqual([[realm objects:[ArrayPropertyObject className] where:@"ANY intArray.intCol > 2"] count], 2U);
    XCTAssertEqual([realm objects:[ArrayPropertyObject className] where:@"NONE intArray.intCol == 5"].count, 1U);
    XCTAssertEqual([realm objects:[ArrayPropertyObject className] where:@"NONE intArray.intCol > 10"].count, 2U);
}

- (void)testMultiLevelLinkQuery
{
    RLMRealm *realm = [self realmWithTestPath];

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
    RLMRealm *realm = [self realmWithTestPath];

    [realm beginWriteTransaction];
    CircleObject *circle = nil;
    for (int i = 0; i < 5; ++i) {
        circle = [CircleObject createInRealm:realm withValue:@{@"data": [NSString stringWithFormat:@"%d", i],
                                                                @"next": circle ?: NSNull.null}];
    }
    [CircleArrayObject createInRealm:realm withValue:@[[CircleObject allObjectsInRealm:realm]]];
    [realm commitWriteTransaction];

    XCTAssertEqual(1U, [CircleArrayObject objectsInRealm:realm where:@"ANY circles.data = '4'"].count);
    XCTAssertEqual(0U, [CircleArrayObject objectsInRealm:realm where:@"ANY circles.next.data = '4'"].count);
    XCTAssertEqual(1U, [CircleArrayObject objectsInRealm:realm where:@"ANY circles.next.data = '3'"].count);
    XCTAssertEqual(1U, [CircleArrayObject objectsInRealm:realm where:@"ANY circles.data = '3'"].count);
    XCTAssertEqual(1U, [CircleArrayObject objectsInRealm:realm where:@"NONE circles.next.data = '4'"].count);

    XCTAssertEqual(0U, [CircleArrayObject objectsInRealm:realm where:@"ANY circles.next.next.data = '3'"].count);
    XCTAssertEqual(1U, [CircleArrayObject objectsInRealm:realm where:@"ANY circles.next.next.data = '2'"].count);
    XCTAssertEqual(1U, [CircleArrayObject objectsInRealm:realm where:@"ANY circles.next.data = '2'"].count);
    XCTAssertEqual(1U, [CircleArrayObject objectsInRealm:realm where:@"ANY circles.data = '2'"].count);
    XCTAssertEqual(1U, [CircleArrayObject objectsInRealm:realm where:@"NONE circles.next.next.data = '3'"].count);

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
    XCTAssertEqual(2U, ([AllTypesObject objectsWhere:@"objectCol = %@", stringObj0].count));
    XCTAssertEqual(1U, ([AllTypesObject objectsWhere:@"objectCol = %@", stringObj1].count));
    XCTAssertEqual(1U, ([AllTypesObject objectsWhere:@"objectCol = nil"].count));
    XCTAssertEqual(4U, ([AllTypesObject objectsWhere:@"objectCol != nil"].count));
    XCTAssertEqual(3U, ([AllTypesObject objectsWhere:@"objectCol != %@", stringObj0].count));

    NSPredicate *longPred = [NSPredicate predicateWithFormat:@"longCol = %lli", 34359738368];
    XCTAssertEqual([AllTypesObject objectsWithPredicate:longPred].count, 1U, @"Count should be 1");

    NSPredicate *longBetweenPred = [NSPredicate predicateWithFormat:@"longCol BETWEEN %@", @[@34359738367LL, @34359738369LL]];
    XCTAssertEqual([AllTypesObject objectsWithPredicate:longBetweenPred].count, 1U, @"Count should be 1");

    // check for ANY object in array
    XCTAssertEqual(2U, ([ArrayOfAllTypesObject objectsWhere:@"ANY array = %@", obj0].count));
    XCTAssertEqual(2U, ([ArrayOfAllTypesObject objectsWhere:@"ANY array != %@", obj1].count));
    XCTAssertEqual(2U, ([ArrayOfAllTypesObject objectsWhere:@"NONE array = %@", obj0].count));
    XCTAssertEqual(2U, ([ArrayOfAllTypesObject objectsWhere:@"NONE array != %@", obj1].count));
    XCTAssertThrows(([ArrayOfAllTypesObject objectsWhere:@"array = %@", obj0].count));
    XCTAssertThrows(([ArrayOfAllTypesObject objectsWhere:@"array != %@", obj0].count));
}

- (void)testCompoundOrQuery {
    RLMRealm *realm = [RLMRealm defaultRealm];

    [realm beginWriteTransaction];
    [PersonObject createInRealm:realm withValue:@[@"Tim", @29]];
    [PersonObject createInRealm:realm withValue:@[@"Ari", @33]];
    [realm commitWriteTransaction];

    XCTAssertEqual(2U, [[PersonObject objectsWhere:@"name == 'Ari' or age < 30"] count]);
    XCTAssertEqual(1U, [[PersonObject objectsWhere:@"name == 'Ari' or age > 40"] count]);
}

- (void)testCompoundAndQuery {
    RLMRealm *realm = [RLMRealm defaultRealm];

    [realm beginWriteTransaction];
    [PersonObject createInRealm:realm withValue:@[@"Tim", @29]];
    [PersonObject createInRealm:realm withValue:@[@"Ari", @33]];
    [realm commitWriteTransaction];

    XCTAssertEqual(1U, [[PersonObject objectsWhere:@"name == 'Ari' and age > 30"] count]);
    XCTAssertEqual(0U, [[PersonObject objectsWhere:@"name == 'Ari' and age > 40"] count]);
}

- (void)testClass:(Class)class
  withNormalCount:(NSUInteger)normalCount
         notCount:(NSUInteger)notCount
            where:(NSString *)predicateFormat, ...
{
    va_list args;
    va_start(args, predicateFormat);
    va_end(args);
    XCTAssertEqual(normalCount, [[class objectsWithPredicate:[NSPredicate predicateWithFormat:predicateFormat arguments:args]] count]);
    predicateFormat = [NSString stringWithFormat:@"NOT(%@)", predicateFormat];
    va_start(args, predicateFormat);
    va_end(args);
    XCTAssertEqual(notCount, [[class objectsWithPredicate:[NSPredicate predicateWithFormat:predicateFormat arguments:args]] count]);
}

- (void)testINPredicate
{
    RLMRealm *realm = [RLMRealm defaultRealm];

    [realm beginWriteTransaction];
    StringObject *so = [StringObject createInRealm:realm withValue:(@[@"abc"])];
    [AllTypesObject createInRealm:realm withValue:@[@YES, @1, @1.0f, @1.0, @"a", [@"a" dataUsingEncoding:NSUTF8StringEncoding], [NSDate dateWithTimeIntervalSince1970:1], @YES, @1LL, @1, so]];
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
    [self testClass:[StringObject class] withNormalCount:1 notCount:0 where:@"stringCol IN {'abc'}"];
    [self testClass:[StringObject class] withNormalCount:0 notCount:1 where:@"stringCol IN {'def'}"];
    [self testClass:[StringObject class] withNormalCount:0 notCount:1 where:@"stringCol IN {'ABC'}"];
    [self testClass:[StringObject class] withNormalCount:1 notCount:0 where:@"stringCol IN[c] {'abc'}"];
    [self testClass:[StringObject class] withNormalCount:1 notCount:0 where:@"stringCol IN[c] {'ABC'}"];

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
    [self testClass:[StringObject class] withNormalCount:1U notCount:0U where:@"stringCol IN %@", @[@"abc"]];
    [self testClass:[StringObject class] withNormalCount:0U notCount:1U where:@"stringCol IN %@", @[@"def"]];
    [self testClass:[StringObject class] withNormalCount:0U notCount:1U where:@"stringCol IN %@", @[@"ABC"]];
    [self testClass:[StringObject class] withNormalCount:1U notCount:0U where:@"stringCol IN[c] %@", @[@"abc"]];
    [self testClass:[StringObject class] withNormalCount:1U notCount:0U where:@"stringCol IN[c] %@", @[@"ABC"]];

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
    XCTAssertThrows(([[AllTypesObject objectsWhere:@"mixedCol IN %@", @[@0, @2, @3]] count]));
    XCTAssertThrows(([[AllTypesObject objectsWhere:@"NOT(mixedCol IN %@)", @[@0, @2, @3]] count]));

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
    [realm commitWriteTransaction];


    XCTAssertEqual(0U, ([[ArrayPropertyObject objectsWhere:@"ANY array.stringCol IN %@", @[@"missing"]] count]));
    XCTAssertEqual(1U, ([[ArrayPropertyObject objectsWhere:@"ANY array.stringCol IN %@", @[@"value"]] count]));
    XCTAssertEqual(1U, ([[ArrayPropertyObject objectsWhere:@"NONE array.stringCol IN %@", @[@"missing"]] count]));
    XCTAssertEqual(0U, ([[ArrayPropertyObject objectsWhere:@"NONE array.stringCol IN %@", @[@"value"]] count]));

    XCTAssertEqual(0U, ([[ArrayPropertyObject objectsWhere:@"ANY array IN %@", [StringObject objectsWhere:@"stringCol = 'missing'"]] count]));
    XCTAssertEqual(1U, ([[ArrayPropertyObject objectsWhere:@"ANY array IN %@", [StringObject objectsWhere:@"stringCol = 'value'"]] count]));
    XCTAssertEqual(1U, ([[ArrayPropertyObject objectsWhere:@"NONE array IN %@", [StringObject objectsWhere:@"stringCol = 'missing'"]] count]));
    XCTAssertEqual(0U, ([[ArrayPropertyObject objectsWhere:@"NONE array IN %@", [StringObject objectsWhere:@"stringCol = 'value'"]] count]));
}

- (void)testQueryChaining {
    RLMRealm *realm = [RLMRealm defaultRealm];

    [realm beginWriteTransaction];
    [PersonObject createInRealm:realm withValue:@[@"Tim", @29]];
    [PersonObject createInRealm:realm withValue:@[@"Ari", @33]];
    [realm commitWriteTransaction];

    XCTAssertEqual(1U, [[PersonObject objectsWhere:@"name == 'Ari'"] count]);
    XCTAssertEqual(0U, [[PersonObject objectsWhere:@"name == 'Ari' and age == 29"] count]);
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
    XCTAssertEqual(1U, [co.employees objectsWhere:@"hired = NO"].count);
    XCTAssertEqual(2U, [co.employees objectsWhere:@"hired = YES"].count);
    XCTAssertEqual(1U, [co.employees objectsWhere:@"hired = YES AND age = 40"].count);
    XCTAssertEqual(0U, [co.employees objectsWhere:@"hired = YES AND age = 30"].count);
    XCTAssertEqual(3U, [co.employees objectsWhere:@"hired = YES OR age = 30"].count);
    XCTAssertEqual(1U, [[co.employees objectsWhere:@"hired = YES"] objectsWhere:@"name = 'Joe'"].count);
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

    [QueryObject createInRealm:realm withValue:@[@YES, @YES, @1, @2, @23.0f, @1.7f,  @0.0,  @5.55, @"a", @"a"]];
    [QueryObject createInRealm:realm withValue:@[@YES, @NO,  @1, @3, @-5.3f, @4.21f, @1.0,  @4.44, @"a", @"A"]];
    [QueryObject createInRealm:realm withValue:@[@NO,  @NO,  @2, @2, @1.0f,  @3.55f, @99.9, @6.66, @"a", @"ab"]];
    [QueryObject createInRealm:realm withValue:@[@NO,  @YES, @3, @6, @4.21f, @1.0f,  @1.0,  @7.77, @"a", @"AB"]];
    [QueryObject createInRealm:realm withValue:@[@YES, @YES, @4, @5, @23.0f, @23.0f, @7.4,  @8.88, @"a", @"b"]];
    [QueryObject createInRealm:realm withValue:@[@YES, @NO,  @15, @8, @1.0f,  @66.0f, @1.01, @9.99, @"a", @"ba"]];
    [QueryObject createInRealm:realm withValue:@[@NO,  @YES, @15, @15, @1.0f,  @66.0f, @1.01, @9.99, @"a", @"BA"]];

    [realm commitWriteTransaction];

    XCTAssertEqual(4U, [QueryObject objectsWhere:@"TRUE == bool1"].count);
    XCTAssertEqual(3U, [QueryObject objectsWhere:@"TRUE != bool2"].count);

    XCTAssertEqual(2U, [QueryObject objectsWhere:@"1 == int1"].count);
    XCTAssertEqual(5U, [QueryObject objectsWhere:@"2 != int2"].count);
    XCTAssertEqual(2U, [QueryObject objectsWhere:@"2 > int1"].count);
    XCTAssertEqual(4U, [QueryObject objectsWhere:@"2 < int1"].count);
    XCTAssertEqual(3U, [QueryObject objectsWhere:@"2 >= int1"].count);
    XCTAssertEqual(5U, [QueryObject objectsWhere:@"2 <= int1"].count);

    XCTAssertEqual(3U, [QueryObject objectsWhere:@"1.0 == float1"].count);
    XCTAssertEqual(6U, [QueryObject objectsWhere:@"1.0 != float2"].count);
    XCTAssertEqual(1U, [QueryObject objectsWhere:@"1.0 > float1"].count);
    XCTAssertEqual(6U, [QueryObject objectsWhere:@"1.0 < float2"].count);
    XCTAssertEqual(4U, [QueryObject objectsWhere:@"1.0 >= float1"].count);
    XCTAssertEqual(7U, [QueryObject objectsWhere:@"1.0 <= float2"].count);

    XCTAssertEqual(2U, [QueryObject objectsWhere:@"1.0 == double1"].count);
    XCTAssertEqual(5U, [QueryObject objectsWhere:@"1.0 != double1"].count);
    XCTAssertEqual(1U, [QueryObject objectsWhere:@"5.0 > double2"].count);
    XCTAssertEqual(6U, [QueryObject objectsWhere:@"5.0 < double2"].count);
    XCTAssertEqual(2U, [QueryObject objectsWhere:@"5.55 >= double2"].count);
    XCTAssertEqual(6U, [QueryObject objectsWhere:@"5.55 <= double2"].count);

    XCTAssertEqual(1U, [QueryObject objectsWhere:@"'a' == string2"].count);
    XCTAssertEqual(6U, [QueryObject objectsWhere:@"'a' != string2"].count);

    RLMAssertThrowsWithReasonMatching([QueryObject objectsWhere:@"'Realm' CONTAINS string1"].count,
                                      @"Operator 'CONTAINS' is not supported .* right side");
    RLMAssertThrowsWithReasonMatching([QueryObject objectsWhere:@"'Amazon' BEGINSWITH string2"].count,
                                      @"Operator 'BEGINSWITH' is not supported .* right side");
    RLMAssertThrowsWithReasonMatching([QueryObject objectsWhere:@"'Tuba' ENDSWITH string1"].count,
                                      @"Operator 'ENDSWITH' is not supported .* right side");
}

#ifdef REALM_ENABLE_NULL
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

        XCTAssertEqual(3U, [stringObjectClass objectsInRealm:realm where:@"stringCol IN {NULL, 'a'}"].count);

        XCTAssertEqual(1U, [stringObjectClass objectsInRealm:realm where:@"stringCol CONTAINS 'a'"].count);
        XCTAssertEqual(1U, [stringObjectClass objectsInRealm:realm where:@"stringCol BEGINSWITH 'a'"].count);
        XCTAssertEqual(1U, [stringObjectClass objectsInRealm:realm where:@"stringCol ENDSWITH 'a'"].count);

        XCTAssertEqual(0U, [stringObjectClass objectsInRealm:realm where:@"stringCol CONTAINS 'z'"].count);

        XCTAssertEqual(1U, [stringObjectClass objectsInRealm:realm where:@"stringCol = ''"].count);

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

        XCTAssertEqual(3U, [stringLinkClass objectsInRealm:realm where:@"objectCol.stringCol IN {NULL, 'a'}"].count);

        XCTAssertEqual(1U, [stringLinkClass objectsInRealm:realm where:@"objectCol.stringCol CONTAINS 'a'"].count);
        XCTAssertEqual(1U, [stringLinkClass objectsInRealm:realm where:@"objectCol.stringCol BEGINSWITH 'a'"].count);
        XCTAssertEqual(1U, [stringLinkClass objectsInRealm:realm where:@"objectCol.stringCol ENDSWITH 'a'"].count);

        XCTAssertEqual(0U, [stringLinkClass objectsInRealm:realm where:@"objectCol.stringCol CONTAINS 'z'"].count);

        XCTAssertEqual(1U, [stringLinkClass objectsInRealm:realm where:@"objectCol.stringCol = ''"].count);
    };

    testWithStringClass([LinkStringObject class], [StringObject class]);
    testWithStringClass([LinkIndexedStringObject class], [IndexedStringObject class]);
}
#endif

- (void)testCountOnCollection {
    RLMRealm *realm = [RLMRealm defaultRealm];
    [realm beginWriteTransaction];

    ArrayPropertyObject *arr = [ArrayPropertyObject createInRealm:realm withValue:@[@"name", @[], @[]]];
    [arr.array addObject:[StringObject createInRealm:realm withValue:@[@"value"]]];
    [realm commitWriteTransaction];


    XCTAssertEqual(1U, ([ArrayPropertyObject objectsWhere:@"array.@count > 0"].count));
    XCTAssertEqual(1U, ([ArrayPropertyObject objectsWhere:@"0 < array.@count"].count));

    // We do not yet handle collection operations with a keypath on the other side of the comparison.
    XCTAssertThrows(([ArrayPropertyObject objectsWhere:@"array.@count != name"]));

    RLMAssertThrowsWithReasonMatching(([ArrayPropertyObject objectsWhere:@"array.@count.foo.bar != 0"]), @"single level key");
    RLMAssertThrowsWithReasonMatching(([ArrayPropertyObject objectsWhere:@"array.@count.stringCol > 0"]), @"@count does not have any properties");
    RLMAssertThrowsWithReasonMatching(([ArrayPropertyObject objectsWhere:@"array.@count != 'Hello'"]), @"@count can only be compared with a numeric value");
}

@end
