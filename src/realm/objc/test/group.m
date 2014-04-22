//
//  group.m
//  TightDB
//
//  Test save/load on disk of a realm with one table
//

#import <XCTest/XCTest.h>

#import <realm/objc/Realm.h>
#import <realm/objc/RLMRealm.h>
#import <realm/objc/RLMContext.h>

REALM_TABLE_2(TestTableRealm,
              First,  String,
              Second, Int)

@interface MACTestRealm : XCTestCase

@end

@implementation MACTestRealm

- (void)testRealm {
    NSFileManager *fm = [NSFileManager defaultManager];

    // Create empty realm and serialize to disk
    [fm removeItemAtPath:@"table_test.realm" error:NULL];
    RLMContext *context = [RLMContext contextPersistedAtPath:@"table_test.realm"
                                                       error:nil];
    [context writeUsingBlock:^BOOL(RLMRealm *realm) {
        // Empty realm
        XCTAssertNotNil(realm, @"parameter must be used");
        return YES;
    } error:nil];

    // Load the realm
    RLMRealm *fromDisk = [RLMRealm realmWithPersistenceToFile:@"table_test.realm"];
    XCTAssertTrue(fromDisk, @"Realm from disk should be valid");

    // Create new table in realm
    [context writeUsingBlock:^BOOL(RLMRealm *realm) {
        [realm createTableWithName:@"test" asTableClass:[TestTableRealm class]];
        return YES;
    } error:nil];

    RLMRealm *realm = [RLMRealm realmWithPersistenceToFile:@"table_test.realm"];
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
    RLMRealm *realm2 = [RLMRealm realmWithPersistenceToFile:@"table_test.realm"];
    TestTableRealm *t2 = [realm2 tableWithName:@"test" asTableClass:[TestTableRealm class]];
    XCTAssertEqual(t2.rowCount, (NSUInteger)1, @"test table should have one row");
}

- (void)testGetTable {
    NSFileManager* fm = [NSFileManager defaultManager];
    
    // Delete realm file
    [fm removeItemAtPath:[RLMContext defaultPath] error:nil];
    RLMRealm *realm = [RLMRealm realmWithDefaultPersistence];
    XCTAssertNil([realm tableWithName:@"noTable"], @"Table does not exist");
}

- (void)testRealmTableCount {
    NSFileManager* fm = [NSFileManager defaultManager];
    
    // Delete realm file
    [fm removeItemAtPath:[RLMContext defaultPath] error:nil];
    XCTAssertEqual([[RLMRealm realmWithDefaultPersistence] tableCount], (NSUInteger)0, @"No tables added");
    [[RLMContext contextWithDefaultPersistence] writeUsingBlock:^BOOL(RLMRealm *realm) {
        [realm createTableWithName:@"tableName"];
        return YES;
    } error:nil];
    XCTAssertEqual([[RLMRealm realmWithDefaultPersistence] tableCount], (NSUInteger)1, @"1 table added");
}

@end
