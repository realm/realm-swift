//
//  group.m
//  TightDB
//
//  Test save/load on disk of a realm with one table
//

#import "RLMTestCase.h"

#import <realm/objc/Realm.h>
#import <realm/objc/RLMRealm.h>
#import <realm/objc/RLMTransactionManager.h>

@interface RLMTestObj2 : RLMRow

@property (nonatomic, copy) NSString *first;
@property (nonatomic, assign) NSInteger second;

@end

@implementation RLMTestObj2
@end

RLM_TABLE_TYPE_FOR_OBJECT_TYPE(RLMTestTable2, RLMTestObj2);

@interface MACTestRealm : RLMTestCase

@end

@implementation MACTestRealm

- (void)testRealm {
    RLMTransactionManager *manager = [self managerWithTestPath];
    [manager writeUsingBlock:^(RLMRealm *realm) {
        // Empty realm
        XCTAssertNotNil(realm, @"parameter must be used");
    }];

    // Load the realm
    RLMRealm *fromDisk = [self realmPersistedAtTestPath];
    XCTAssertTrue(fromDisk, @"Realm from disk should be valid");

    // Create new table in realm
    [manager writeUsingBlock:^(RLMRealm *realm) {
        [RLMTestTable2 tableInRealm:realm named:@"test"];
    }];

    RLMRealm *realm = [self realmPersistedAtTestPath];
    RLMTestTable2 *t = [RLMTestTable2 tableInRealm:realm named:@"test"];
    
    // Verify
    XCTAssertEqual(t.columnCount, (NSUInteger)2, @"Should have 2 columns");
    XCTAssertEqual(t.rowCount, (NSUInteger)0, @"Should have 0 rows");

    // Modify table
    [manager writeUsingBlock:^(RLMRealm *realm) {
        RLMTestTable2 *t = [RLMTestTable2 tableInRealm:realm named:@"test"];
        [t addRow:@[@"Test", @23]];
    }];

    // Verify
    RLMRealm *realm2 = [self realmPersistedAtTestPath];
    RLMTestTable2 *t2 = [RLMTestTable2 tableInRealm:realm2 named:@"test"];
    XCTAssertEqual(t2.rowCount, (NSUInteger)1, @"test table should have one row");
}

- (void)testGetTable {
    XCTAssertNil([[self realmPersistedAtTestPath] tableWithName:@"noTable"], @"Table does not exist");
}

- (void)testRealmTableCount {
    XCTAssertEqual([[self realmPersistedAtTestPath] tableCount], (NSUInteger)0, @"No tables added");
    [[self managerWithTestPath] writeUsingBlock:^(RLMRealm *realm) {
        [realm createTableWithName:@"tableName"];
    }];
    XCTAssertEqual([[self realmPersistedAtTestPath] tableCount], (NSUInteger)1, @"1 table added");
}

@end
