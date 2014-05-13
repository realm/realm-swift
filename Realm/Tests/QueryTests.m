
#import "RLMTestCase.h"
#import "XCTestCase+AsyncTesting.h"

@interface PersonQueryObject : RLMObject
@property (nonatomic, copy) NSString *name;
@property (nonatomic, assign) NSInteger age;
@end

@implementation PersonQueryObject
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
    XCTAssertEqual(all.count, 3, @"Expecting 3 results");
    XCTAssertEqual([PersonQueryObject objectsWhere:@"age == 27"].count, 1, @"Expecting 1 results");
    
    // with order
    RLMArray *results = [PersonQueryObject objectsOrderedBy:@"age" where:@"age > 28"];
    XCTAssertEqualObjects([results[0] name], @"Tim", @"Tim should be first results");
}

//- (void)testArrayQuery {
//    // delete default realm file
//    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
//    NSString *documentsDirectory = [paths objectAtIndex:0];
//    NSString *defaultRealmPath = [documentsDirectory stringByAppendingPathComponent:@"default.realm"];
//    [[NSFileManager defaultManager] removeItemAtPath:defaultRealmPath error:nil];
//    
//    RLMRealm *realm = [RLMRealm defaultRealm];
//    
//    [realm beginWriteTransaction];
//    [PersonQueryObject createInRealm:realm withObject:@[@"Fiel", @27]];
//    [PersonQueryObject createInRealm:realm withObject:@[@"Tim", @29]];
//    [PersonQueryObject createInRealm:realm withObject:@[@"Ari", @33]];
//    [realm commitWriteTransaction];
//    
//    // query on class
//    RLMArray *all = [PersonQueryObject allObjects];
//    RLMArray *some = [PersonQueryObject objectsOrderedBy:@"age" where:@"age > 28"];
//    
//    // FIXME - these crash for now - need to keep old query or predicate and fix accessor/attachment issue
//    // query/order on array
//    XCTAssertEqual([all objectsWhere:@"age == 27"].count, 1, @"Expecting 1 results");
//    some = [some objectsOrderedBy:[NSSortDescriptor sortDescriptorWithKey:@"age" ascending:NO] where:nil];
//    XCTAssertEqualObjects([some[0] name], @"Ari", @"Ari should be first results");
//}

@end

