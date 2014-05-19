////////////////////////////////////////////////////////////////////////////
//
// TIGHTDB CONFIDENTIAL
// __________________
//
//  [2011] - [2014] TightDB Inc
//  All Rights Reserved.
//
// NOTICE:  All information contained herein is, and remains
// the property of TightDB Incorporated and its suppliers,
// if any.  The intellectual and technical concepts contained
// herein are proprietary to TightDB Incorporated
// and its suppliers and may be covered by U.S. and Foreign Patents,
// patents in process, and are protected by trade secret or copyright law.
// Dissemination of this information or reproduction of this material
// is strictly forbidden unless prior written permission is obtained
// from TightDB Incorporated.
//
////////////////////////////////////////////////////////////////////////////

#import "RLMTestCase.h"
#import "Realm.h"
#import "XCTestCase+AsyncTesting.h"
#import "RLMUtil.h"

@interface PersonQueryObject : RLMObject
@property (nonatomic, copy) NSString *name;
@property (nonatomic, assign) NSInteger age;
@end

@implementation PersonQueryObject
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

- (NSString *)description
{
    return [NSString stringWithFormat:@"int1 = %lu, int2 = %lu", self.int1, self.int2];
}

- (NSString *)debugDescription
{
    return [self description];
}

@end

@interface RLMQueryTests : RLMTestCase
@end

@implementation RLMQueryTests

#pragma mark - Tests

- (void)testBasicQuery {
    RLMRealm *realm = [self realmWithTestPath];

    [realm beginWriteTransaction];
    [PersonQueryObject createInRealm:realm withObject:@[@"Fiel", @27]];
    [PersonQueryObject createInRealm:realm withObject:@[@"Ari", @33]];
    [PersonQueryObject createInRealm:realm withObject:@[@"Tim", @29]];
    [realm commitWriteTransaction];
    
    // query on realm
    XCTAssertEqual([realm objects:PersonQueryObject.class where:@"age > 28"].count, 2, @"Expecting 2 results");
    
    // query on realm with order
    RLMArray *results = [realm objects:PersonQueryObject.class orderedBy:@"age" where:@"age > 28"];
    XCTAssertEqualObjects([results[0] name], @"Tim", @"Tim should be first results");
}

- (void)testDefaultRealmQuery {
    // delete default realm file
    [[NSFileManager defaultManager] removeItemAtPath:RLMDefaultRealmPath() error:nil];
    
    RLMRealm *realm = [RLMRealm defaultRealm];
    
    [realm beginWriteTransaction];
    [PersonQueryObject createInRealm:realm withObject:@[@"Fiel", @27]];
    [PersonQueryObject createInRealm:realm withObject:@[@"Tim", @29]];
    [PersonQueryObject createInRealm:realm withObject:@[@"Ari", @33]];
    [realm commitWriteTransaction];
    
    // query on class
    RLMArray *all = [PersonQueryObject allObjects];
    XCTAssertEqual(all.count, 3, @"Expecting 3 results");
    XCTAssertEqual([PersonQueryObject objectsWhere:@"age == 27"].count, 1, @"Expecting 1 results");
    
    // with order
    RLMArray *results = [PersonQueryObject objectsOrderedBy:@"age" where:@"age > 28"];
    XCTAssertEqualObjects([results[0] name], @"Tim", @"Tim should be first results");
}

- (void)testArrayQuery {
    // delete default realm file
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *defaultRealmPath = [documentsDirectory stringByAppendingPathComponent:@"default.realm"];
    [[NSFileManager defaultManager] removeItemAtPath:defaultRealmPath error:nil];
    
    RLMRealm *realm = [RLMRealm defaultRealm];
    
    [realm beginWriteTransaction];
    [PersonQueryObject createInRealm:realm withObject:@[@"Fiel", @27]];
    [PersonQueryObject createInRealm:realm withObject:@[@"Tim", @29]];
    [PersonQueryObject createInRealm:realm withObject:@[@"Ari", @33]];
    [realm commitWriteTransaction];
    
    // query on class
    RLMArray *all = [PersonQueryObject allObjects];
    RLMArray *some = [PersonQueryObject objectsOrderedBy:@"age" where:@"age > 28"];
    
    // query/order on array
    XCTAssertEqual([all objectsWhere:@"age == 27"].count, 1, @"Expecting 1 result");
    XCTAssertEqual([all objectsWhere:@"age == 28"].count, 0, @"Expecting 0 results");
    some = [some objectsOrderedBy:[NSSortDescriptor sortDescriptorWithKey:@"age" ascending:NO] where:nil];
    XCTAssertEqualObjects([some[0] name], @"Ari", @"Ari should be first results");
}

- (void)testTwoColumnComparisonQuery
{
    [[NSFileManager defaultManager] removeItemAtPath:RLMDefaultRealmPath()
                                               error:nil];
    RLMRealm *realm = [RLMRealm defaultRealm];
    
    [realm beginWriteTransaction];
    
    [TestQueryObject createInRealm:realm withObject:@[@1, @2, @23.0, @1.7,  @0.0,  @5.55, @"Instance 0"]];
    [TestQueryObject createInRealm:realm withObject:@[@1, @3, @-5.3, @4.21, @1.0,  @4.44, @"Instance 1"]];
    [TestQueryObject createInRealm:realm withObject:@[@2, @2, @1.0,  @3.55, @99.9, @6.66, @"Instance 2"]];
    [TestQueryObject createInRealm:realm withObject:@[@3, @6, @4.21, @1.0,  @1.0,  @7.77, @"Instance 3"]];
    [TestQueryObject createInRealm:realm withObject:@[@4, @5, @23.0, @23.0, @7.4,  @8.88, @"Instance 4"]];
    [TestQueryObject createInRealm:realm withObject:@[@15, @8, @1.0,  @66.0, @1.01, @9.99, @"Instance 5"]];
    [TestQueryObject createInRealm:realm withObject:@[@15, @15, @1.0,  @66.0, @1.01, @9.99, @"Instance 6"]];
    
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
/*
    [self executeInvalidTwoColumnKeypathRealmComparisonQuery:[TestQueryObject class] predicate:@"int1 == float1" expectedCount:0];
    [self executeInvalidTwoColumnKeypathRealmComparisonQuery:[TestQueryObject class] predicate:@"float2 >= double1" expectedCount:0];
    [self executeInvalidTwoColumnKeypathRealmComparisonQuery:[TestQueryObject class] predicate:@"double2 <= int2" expectedCount:0];
    [self executeInvalidTwoColumnKeypathRealmComparisonQuery:[TestQueryObject class] predicate:@"int2 != recordTag" expectedCount:0];
    [self executeInvalidTwoColumnKeypathRealmComparisonQuery:[TestQueryObject class] predicate:@"float1 > recordTag" expectedCount:0];
    [self executeInvalidTwoColumnKeypathRealmComparisonQuery:[TestQueryObject class] predicate:@"double1 < recordTag" expectedCount:0];
*/
}

- (void)executeTwoColumnKeypathRealmComparisonQueryWithClass:(Class)class predicate:(NSString *)predicate expectedCount:(NSUInteger)expectedCount
{
    RLMRealm *realm = [RLMRealm defaultRealm];
    
    RLMArray *queryResult = [realm objects:class
                                     where:predicate];
    NSUInteger actualCount = queryResult.count;
    XCTAssertEqual(actualCount, expectedCount, @"Predicate: %@, Expecting %lu result(s), found %lu", predicate, expectedCount, actualCount);
}

- (void)executeTwoColumnKeypathComparisonQueryWithPredicate:(NSString *)predicate expectedCount:(NSUInteger)expectedCount
{
    RLMArray *queryResult = [TestQueryObject objectsWhere:predicate];
    NSUInteger actualCount = queryResult.count;
    XCTAssertEqual(actualCount, expectedCount, @"Predicate: %@, Expecting %lu result(s), found %lu", predicate, expectedCount, actualCount);
}

- (void)executeInvalidTwoColumnKeypathRealmComparisonQuery:(Class)class predicate:(NSString *)predicate expectedCount:(NSUInteger)expectedCount
{
    @try {
        RLMRealm *realm = [RLMRealm defaultRealm];
        
        RLMArray *queryResult = [realm objects:class
                                         where:predicate];
        NSUInteger actualCount = queryResult.count;
#pragma unused(actualCount)
        
        XCTFail(@"Predicate: %@ - exception expected.", predicate);
    }
    @catch (NSException *exception) {
        
    }
}

@end

