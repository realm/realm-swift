//
//  group.m
//  TightDB
//
//  Test save/load on disk of a realm with one table
//

#import "RLMTestCase.h"

#import <realm/objc/Realm.h>
#import <realm/objc/RLMRealm.h>
#import <realm/objc/RLMContext.h>

REALM_TABLE_2(TestTableRealm,
              First,  String,
              Second, Int)

@interface MACTestRealm : RLMTestCase

@end

@implementation MACTestRealm

- (void)testRealm {
    RLMContext *context = [self contextPersistedAtTestPath];
    [context writeUsingBlock:^BOOL(RLMRealm *realm) {
        // Empty realm
        XCTAssertNotNil(realm, @"parameter must be used");
        return YES;
    } error:nil];

    // Load the realm
    RLMRealm *fromDisk = [self realmPersistedAtTestPath];
    XCTAssertTrue(fromDisk, @"Realm from disk should be valid");

    // Create new table in realm
    [context writeUsingBlock:^BOOL(RLMRealm *realm) {
        [realm createTableWithName:@"test" asTableClass:[TestTableRealm class]];
        return YES;
    } error:nil];

    RLMRealm *realm = [self realmPersistedAtTestPath];
    TestTableRealm *t = [realm tableWithName:@"test" asTableClass:[TestTableRealm class]];
    
    // Verify
    XCTAssertEqual(t.columnCount, (NSUInteger)2, @"Should have 2 columns");
    XCTAssertEqual(t.rowCount, (NSUInteger)0, @"Should have 0 rows");

    // Modify table
    [context writeUsingBlock:^BOOL(RLMRealm *realm) {
        TestTableRealm *t = [realm tableWithName:@"test" asTableClass:[TestTableRealm class]];
        [t addFirst:@"Test" Second:YES];
        return YES;
    } error:nil];

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
    [[self contextPersistedAtTestPath] writeUsingBlock:^BOOL(RLMRealm *realm) {
        [realm createTableWithName:@"tableName"];
        return YES;
    } error:nil];
    XCTAssertEqual([[self realmPersistedAtTestPath] tableCount], (NSUInteger)1, @"1 table added");
}

@end
