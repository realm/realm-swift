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


@interface AllPropertyTypesObject : RLMObject
@property (nonatomic, assign) BOOL boolCol;
@property (nonatomic, copy) NSDate *dateCol;
@property (nonatomic, assign) double doubleCol;
@property (nonatomic, assign) float floatCol;
@property (nonatomic, assign) NSInteger intCol;
@property (nonatomic, copy) NSString *stringCol;
@end

@implementation AllPropertyTypesObject
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

- (void)testQuerySorting
{
    RLMRealm *realm = [RLMRealm defaultRealm];
    
    NSDate *date1 = [NSDate date];
    NSDate *date2 = [date1 dateByAddingTimeInterval:1];
    NSDate *date3 = [date2 dateByAddingTimeInterval:1];
    NSDate *date33 = [date3 dateByAddingTimeInterval:1];
    
    [realm beginWriteTransaction];
    [AllPropertyTypesObject createInRealm:realm withObject:@[@YES, date1, @1.0, @1.0f, @1, @"a"]];
    [AllPropertyTypesObject createInRealm:realm withObject:@[@YES, date2, @2.0, @2.0f, @2, @"b"]];
    [AllPropertyTypesObject createInRealm:realm withObject:@[@NO, date3, @3.0, @3.0f, @3, @"c"]];
    [AllPropertyTypesObject createInRealm:realm withObject:@[@NO, date33, @3.3, @3.3f, @33, @"cc"]];
    [realm commitWriteTransaction];
    
    
    //////////// sort by boolCol
    RLMArray *results = [AllPropertyTypesObject objectsOrderedBy:@"boolCol" where:nil];
    AllPropertyTypesObject *o = results[0];
    XCTAssertEqual(o.boolCol, NO, @"Should be NO");
    
    NSSortDescriptor *sortDesc = [NSSortDescriptor sortDescriptorWithKey:@"boolCol" ascending:YES];
    results = [AllPropertyTypesObject objectsOrderedBy:sortDesc where:nil];
    o = results[0];
    XCTAssertEqual(o.boolCol, NO, @"Should be NO");
    
    sortDesc = [NSSortDescriptor sortDescriptorWithKey:@"boolCol" ascending:NO];
    results = [AllPropertyTypesObject objectsOrderedBy:sortDesc where:nil];
    o = results[0];
    XCTAssertEqual(o.boolCol, YES, @"Should be YES");
    
    
    //////////// sort by intCol
    results = [AllPropertyTypesObject objectsOrderedBy:@"intCol" where:nil];
    o = results[0];
    XCTAssertEqual(o.intCol, 1, @"Should be 1");
    
    sortDesc = [NSSortDescriptor sortDescriptorWithKey:@"intCol" ascending:YES];
    results = [AllPropertyTypesObject objectsOrderedBy:sortDesc where:nil];
    o = results[0];
    XCTAssertEqual(o.intCol, 1, @"Should be 1");
    
    sortDesc = [NSSortDescriptor sortDescriptorWithKey:@"intCol" ascending:NO];
    results = [AllPropertyTypesObject objectsOrderedBy:sortDesc where:nil];
    o = results[0];
    XCTAssertEqual(o.intCol, 33, @"Should be 33");
    
    
    //////////// sort by dateCol
    results = [AllPropertyTypesObject objectsOrderedBy:@"dateCol" where:nil];
    o = results[0];
    XCTAssertEqualWithAccuracy(o.dateCol.timeIntervalSince1970, date1.timeIntervalSince1970, 1, @"Should be date1");
    
    sortDesc = [NSSortDescriptor sortDescriptorWithKey:@"dateCol" ascending:YES];
    results = [AllPropertyTypesObject objectsOrderedBy:sortDesc where:nil];
    o = results[0];
    XCTAssertEqualWithAccuracy(o.dateCol.timeIntervalSince1970, date1.timeIntervalSince1970, 1, @"Should be date1");
    
    sortDesc = [NSSortDescriptor sortDescriptorWithKey:@"dateCol" ascending:NO];
    results = [AllPropertyTypesObject objectsOrderedBy:sortDesc where:nil];
    o = results[0];
    XCTAssertEqualWithAccuracy(o.dateCol.timeIntervalSince1970, date33.timeIntervalSince1970, 1, @"Should be date33");
    
    
    //////////// sort by doubleCol
    results = [AllPropertyTypesObject objectsOrderedBy:@"doubleCol" where:nil];
    o = results[0];
    XCTAssertEqual(o.doubleCol, 1.0, @"Should be 1.0");
    
    sortDesc = [NSSortDescriptor sortDescriptorWithKey:@"doubleCol" ascending:YES];
    results = [AllPropertyTypesObject objectsOrderedBy:sortDesc where:nil];
    o = results[0];
    XCTAssertEqual(o.doubleCol, 1.0, @"Should be 1.0");
    
    sortDesc = [NSSortDescriptor sortDescriptorWithKey:@"doubleCol" ascending:NO];
    results = [AllPropertyTypesObject objectsOrderedBy:sortDesc where:nil];
    o = results[0];
    XCTAssertEqualWithAccuracy(o.doubleCol, 3.3, 0.0000001, @"Should be 3.3");
    
    
    //////////// sort by floatCol
    results = [AllPropertyTypesObject objectsOrderedBy:@"floatCol" where:nil];
    o = results[0];
    XCTAssertEqual(o.floatCol, 1.0, @"Should be 1.0");
    
    sortDesc = [NSSortDescriptor sortDescriptorWithKey:@"floatCol" ascending:YES];
    results = [AllPropertyTypesObject objectsOrderedBy:sortDesc where:nil];
    o = results[0];
    XCTAssertEqual(o.floatCol, 1.0, @"Should be 1.0");
    
    sortDesc = [NSSortDescriptor sortDescriptorWithKey:@"floatCol" ascending:NO];
    results = [AllPropertyTypesObject objectsOrderedBy:sortDesc where:nil];
    o = results[0];
    XCTAssertEqualWithAccuracy(o.floatCol, 3.3, 0.0000001, @"Should be 3.3");
    
    
    //////////// sort by stringCol
    results = [AllPropertyTypesObject objectsOrderedBy:@"stringCol" where:nil];
    o = results[0];
    XCTAssertEqualObjects(o.stringCol, @"a", @"Should be a");
    
    sortDesc = [NSSortDescriptor sortDescriptorWithKey:@"stringCol" ascending:YES];
    results = [AllPropertyTypesObject objectsOrderedBy:sortDesc where:nil];
    o = results[0];
    XCTAssertEqualObjects(o.stringCol, @"a", @"Should be a");
    
    sortDesc = [NSSortDescriptor sortDescriptorWithKey:@"stringCol" ascending:NO];
    results = [AllPropertyTypesObject objectsOrderedBy:sortDesc where:nil];
    o = results[0];
    XCTAssertEqualObjects(o.stringCol, @"cc", @"Should be cc");
}

@end

