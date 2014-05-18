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
#import "XCTestCase+AsyncTesting.h"

@interface PersonQueryObject : RLMObject
@property (nonatomic, copy) NSString *name;
@property (nonatomic, assign) NSInteger age;
@end

@implementation PersonQueryObject
@end

@interface TestQueryObject : RLMObject
@property (nonatomic, copy) NSString *recordTag;
@property (nonatomic, assign) NSInteger int1;
@property (nonatomic, assign) NSInteger int2;
@property (nonatomic, assign) float float1;
@property (nonatomic, assign) float float2;
@property (nonatomic, assign) double double1;
@property (nonatomic, assign) double double2;
@end

@implementation TestQueryObject
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

- (void)testTwoColumnComparisonQuery {
    RLMRealm *realm = [self realmWithTestPath];
    
    [realm beginWriteTransaction];
    
    [TestQueryObject createInRealm:realm withObject:@[@"Instance 0", @1, @2, @23.0, @1.7,  @0.0,  @5.55]];
    [TestQueryObject createInRealm:realm withObject:@[@"Instance 1", @1, @3, @-5.3, @4.21, @1.0,  @4.44]];
    [TestQueryObject createInRealm:realm withObject:@[@"Instance 2", @2, @2, @1.0,  @3.55, @99.9, @6.66]];
    [TestQueryObject createInRealm:realm withObject:@[@"Instance 3", @3, @6, @4.21, @1.0,  @1.0,  @7.77]];
    [TestQueryObject createInRealm:realm withObject:@[@"Instance 2", @4, @5, @23.0, @23.0, @7.4,  @8.88]];
    [TestQueryObject createInRealm:realm withObject:@[@"Instance 3", @15, @8, @1.0,  @66.0, @1.01, @9.99]];
    
    [realm commitWriteTransaction];
    
    RLMArray *queryResult;
    
    queryResult = [TestQueryObject objectsWhere:@"int1 == int2"];
    XCTAssertEqual(queryResult.count, 1, @"Expecting 1 result");
    
    queryResult = [TestQueryObject objectsWhere:@"int1 != int2"];
    XCTAssertEqual(queryResult.count, 5, @"Expecting 5 result");
    
    queryResult = [TestQueryObject objectsWhere:@"int1 > int2"];
    XCTAssertEqual(queryResult.count, 1, @"Expecting 1 result");
    
    queryResult = [TestQueryObject objectsWhere:@"int1 < int2"];
    XCTAssertEqual(queryResult.count, 4, @"Expecting 4 result");
    
    queryResult = [TestQueryObject objectsWhere:@"int1 >= int2"];
    XCTAssertEqual(queryResult.count, 2, @"Expecting 2 result");
    
    queryResult = [TestQueryObject objectsWhere:@"int1 <= int2"];
    XCTAssertEqual(queryResult.count, 5, @"Expecting 5 result");

    queryResult = [TestQueryObject objectsWhere:@"float1 == int2"];
    queryResult = [TestQueryObject objectsWhere:@"float1 != int2"];
    queryResult = [TestQueryObject objectsWhere:@"float1 > int2"];
    queryResult = [TestQueryObject objectsWhere:@"float1 < int2"];
    queryResult = [TestQueryObject objectsWhere:@"float1 >= int2"];
    queryResult = [TestQueryObject objectsWhere:@"float1 <= int2"];

    queryResult = [TestQueryObject objectsWhere:@"double1 == double2"];
    queryResult = [TestQueryObject objectsWhere:@"double1 != double2"];
    queryResult = [TestQueryObject objectsWhere:@"double1 > double2"];
    queryResult = [TestQueryObject objectsWhere:@"double1 < double2"];
    queryResult = [TestQueryObject objectsWhere:@"double1 >= double2"];
    queryResult = [TestQueryObject objectsWhere:@"double1 <= double2"];

}

@end

