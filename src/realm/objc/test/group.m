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
#import <realm/objc/group.h>

REALM_TABLE_2(TestTableRealm,
              First,  String,
              Second, Int)

@interface MACTestRealm : XCTestCase

@end

@implementation MACTestRealm

- (void)testRealm {
    NSFileManager *fm = [NSFileManager defaultManager];

    // Create empty realm and serialize to disk
    RLMRealm *toDisk = [RLMRealm group];
    [fm removeItemAtPath:@"table_test.realm" error:NULL];
    [toDisk writeContextToFile:@"table_test.realm" error:nil];

    // Load the realm
    RLMRealm *fromDisk = [RLMRealm groupWithFile:@"table_test.realm" error:nil];
    if (!fromDisk)
        XCTFail(@"From disk not valid");

    // Create new table in realm
    TestTableRealm *t = (TestTableRealm *)[fromDisk createTableWithName:@"test" asTableClass:[TestTableRealm class]];

    // Verify
    NSLog(@"Columns: %zu", t.columnCount);
    if (t.columnCount != 2)
        XCTFail(@"Should have been 2 columns");
    if (t.rowCount != 0)
        XCTFail(@"Should have been empty");

    // Modify table
    [t addFirst:@"Test" Second:YES];
    NSLog(@"Size: %lu", t.rowCount);

    // Verify
    if (t.rowCount != 1)
        XCTFail(@"Should have been one row");

    t = nil;
}

- (void)testGetTable {
    RLMRealm *realm = [RLMRealm group];
    XCTAssertNil([realm tableWithName:@"noTable"], @"Table does not exist");
}

- (void)testRealmTableCount {
    RLMRealm *realm = [RLMRealm group];
    XCTAssertEqual(realm.tableCount, (NSUInteger)0, @"No tables added");
    [realm createTableWithName:@"tableName"];
    XCTAssertEqual(realm.tableCount, (NSUInteger)1, @"1 table added");
}

@end
