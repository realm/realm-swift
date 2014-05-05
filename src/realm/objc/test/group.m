//
//  group.m
//  TightDB
//
//  Test save/load on disk of a realm with one table
//

#import "RLMTestCase.h"

#import <realm/objc/Realm.h>
#import <realm/objc/RLMRealm.h>

REALM_TABLE_2(TestTableRealm,
              First,  String,
              Second, Int)

@interface MACTestRealm : RLMTestCase

@end

@implementation MACTestRealm

- (void)testRealm {
    // Load the realm
    RLMRealm *realm = [self realmPersistedAtTestPath];
    XCTAssertTrue(realm, @"Realm from disk should be valid");

    // Create new table in realm
    [realm beginWriteTransaction];
    [realm createTableWithName:@"test" asTableClass:[TestTableRealm class]];
    TestTableRealm *t = [realm tableWithName:@"test" asTableClass:[TestTableRealm class]];

    // Verify
    XCTAssertEqual(t.columnCount, (NSUInteger)2, @"Should have 2 columns");
    XCTAssertEqual(t.rowCount, (NSUInteger)0, @"Should have 0 rows");

    // Modify table
    t = [realm tableWithName:@"test" asTableClass:[TestTableRealm class]];
    [t addFirst:@"Test" Second:YES];
    [realm commitWriteTransaction];
    
    // Verify
    RLMRealm *realm2 = [self realmPersistedAtTestPath];
    TestTableRealm *t2 = [realm2 tableWithName:@"test" asTableClass:[TestTableRealm class]];
    XCTAssertEqual(t2.rowCount, (NSUInteger)1, @"test table should have one row");
}

- (void)testGetTable {
    XCTAssertNil([[self realmPersistedAtTestPath] tableWithName:@"noTable"], @"Table does not exist");
}

- (void)testRealmTableCount {
    XCTAssertEqual([[self realmPersistedAtTestPath] tableCount], (NSUInteger)0, @"No tables added");
    [[self realmWithTestPath] writeUsingBlock:^(RLMRealm *realm) {
        [realm createTableWithName:@"tableName"];
    }];
    XCTAssertEqual([[self realmPersistedAtTestPath] tableCount], (NSUInteger)1, @"1 table added");
}

@end
