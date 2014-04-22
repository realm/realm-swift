//
//  realm.mm
//  TightDB
//
//  Run tests on RLMRealm
//

#import "RLMTestCase.h"
#import <realm/objc/Realm.h>
#import "XCTestCase+AsyncTesting.h"

REALM_TABLE_1(RLMTestTable,
              column, String)

@interface RLMRealmTests : RLMTestCase

@end

@implementation RLMRealmTests

#pragma mark - Tests

- (void)testRealmExists {
    RLMRealm *realm = [self realmPersistedAtTestPath];
    XCTAssertNotNil(realm, @"realm should not be nil");
    XCTAssertEqual([realm class], [RLMRealm class], @"realm should be of class RLMRealm");
}

- (void)testCanReadPreviouslyCreatedTable {
    NSString *tableName = @"table";
    
    NSError *error = nil;
    
    [[self contextPersistedAtTestPath] writeUsingBlock:^BOOL(RLMRealm *realm) {
        [realm createTableWithName:tableName];
        return YES;
    } error:&error];
    
    XCTAssertNil(error, @"RLMContext error should be nil after write block");
    
    RLMRealm *realm = [self realmPersistedAtTestPath];
    RLMTable *table = [realm tableWithName:tableName];
    
    XCTAssertNotNil(table, @"pre-existing table read from RLMRealm should not be nil");
    XCTAssertEqual([table class], [RLMTable class], @"pre-existing table read from \
                   RLMRealm should be of class RLMTable");
}

- (void)testCanReadPreviouslyCreatedTypedTable {
    NSString *tableName = @"table";
    
    NSError *error = nil;
    
    [[self contextPersistedAtTestPath] writeUsingBlock:^BOOL(RLMRealm *realm) {
        [realm createTableWithName:tableName asTableClass:[RLMTestTable class]];
        return YES;
    } error:&error];
    
    XCTAssertNil(error, @"RLMContext error should be nil after write block");
    
    RLMRealm *realm = [self realmPersistedAtTestPath];
    RLMTestTable *table = [realm tableWithName:tableName asTableClass:[RLMTestTable class]];
    
    XCTAssertNotNil(table, @"pre-existing typed table read from RLMRealm should not be nil");
    XCTAssertEqual([table class],
                   [RLMTestTable class],
                   @"pre-existing typed table read from RLMRealm should be of class RLMTestTable");
}

- (void)testTableCreatedAfterStandaloneRealmStarted {
    NSString *realmFilePath = @"async.realm";
    [[NSFileManager defaultManager] removeItemAtPath:realmFilePath error:nil];
    NSString *tableName = @"table";
    
    RLMRealm *realm = [RLMRealm realmWithPersistenceToFile:realmFilePath];
    
    NSError *error = nil;
    
    [[RLMContext contextPersistedAtPath:realmFilePath error:nil] writeUsingBlock:^BOOL(RLMRealm *realm) {
        [realm createTableWithName:tableName];
        return YES;
    } error:&error];
    
    XCTAssertNil(error, @"RLMContext error should be nil after write block");
    
    __block RLMTable *table = [realm tableWithName:tableName];
    
    XCTAssertNil(table, @"RLMRealm should not immediately be able to see a \
                 table that was created after the realm started");
    
    __block BOOL notificationFired = NO;
    
    [[NSNotificationCenter defaultCenter] addObserverForName:RLMContextDidChangeNotification
                                                      object:nil
                                                       queue:[NSOperationQueue mainQueue]
                                                  usingBlock:^(NSNotification *note) {
                                                      XCTAssertNotNil(note, @"Must use parameter");
                                                      notificationFired = YES;
                                                      table = [realm tableWithName:tableName];
                                                      [self notify:XCTAsyncTestCaseStatusSucceeded];
                                                  }];
    
    [self waitForTimeout:1.0f];
    
    XCTAssertTrue(notificationFired, @"A notification should have fired after a table was created");
    XCTAssertNotNil(table, @"The RLMRealm should be able to read a newly \
                    created table after a RLMContextDidChangeNotification was sent");
    XCTAssertEqual([table class], [RLMTable class], @"a newly created table read from \
                   RLMRealm should be of class RLMTable");
}

@end
