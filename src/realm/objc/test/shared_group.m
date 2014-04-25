//
//  shared_group.m
//  TightDB
//
// Demo code for short tutorial using Objective-C interface
//

#import "RLMTestCase.h"

#import <realm/objc/RLMFast.h>
#import <realm/objc/RLMRealm.h>

REALM_TABLE_2(SharedTable2,
              Hired, Bool,
              Age,   Int)

@interface MACTestSharedGroup: RLMTestCase

@end

@implementation MACTestSharedGroup

- (void)testTransactionManager {
    
    // TODO: Update test to include more ASSERTS
    
    [[self managerWithTestPath] writeUsingBlock:^(RLMRealm *realm) {
        // Create new table in realm
        SharedTable2 *table = [realm createTableWithName:@"employees" asTableClass:[SharedTable2 class]];
        NSLog(@"Table: %@", table);
        // Add some rows
        [table addHired:YES Age:50];
        [table addHired:YES Age:52];
        [table addHired:YES Age:53];
        [table addHired:YES Age:54];
        
        NSLog(@"MyTable Size: %lu", [table rowCount]);
    }];
    
    RLMTransactionManager *fromDisk = [self managerWithTestPath];
    
    [fromDisk readUsingBlock:^(RLMRealm *realm) {
        SharedTable2* diskTable = [realm tableWithName:@"employees" asTableClass:[SharedTable2 class]];
        NSLog(@"Disktable size: %zu", [diskTable rowCount]);
        for (NSUInteger i = 0; i < [diskTable rowCount]; i++) {
            SharedTable2Row *cursor = [diskTable rowAtIndex:i];
            NSLog(@"%zu: %lld", i, cursor.Age);
            NSLog(@"%zu: %i", i, [diskTable RLM_boolInColumnWithIndex: 0 atRowIndex:i]);
        }
    }];
    
    [fromDisk writeUsingBlock:^(RLMRealm *realm) {
        SharedTable2* diskTable = [realm tableWithName:@"employees" asTableClass:[SharedTable2 class]];
        NSLog(@"Disktable size: %zu", [diskTable rowCount]);
        for (NSUInteger i = 0; i < 50; i++) {
            [diskTable addHired:YES Age:i];
        }
    }];
    
    [fromDisk writeUsingBlockWithRollback:^(RLMRealm *realm, BOOL *rollback) {
        SharedTable2* diskTable = [realm tableWithName:@"employees" asTableClass:[SharedTable2 class]];
        NSLog(@"Disktable size: %zu", [diskTable rowCount]);
        for (NSUInteger i = 0; i < 50; i++) {
            [diskTable addHired:YES Age:i];
        }
        *rollback = YES;
    }];
    
    [fromDisk writeUsingBlock:^(RLMRealm *realm) {
        SharedTable2* diskTable = [realm tableWithName:@"employees" asTableClass:[SharedTable2 class]];
        NSLog(@"Disktable size: %zu", [diskTable rowCount]);
        for (NSUInteger i = 0; i < 50; i++) {
            [diskTable addHired:YES Age:i];
        }
        
        XCTAssertNil([realm tableWithName:@"Does not exist"], @"Table does not exist");
    }];
    
    [fromDisk readUsingBlock:^(RLMRealm * realm) {
        SharedTable2* diskTable = [realm tableWithName:@"employees" asTableClass:[SharedTable2 class]];
        NSLog(@"Disktable size: %zu", [diskTable rowCount]);
        
        XCTAssertThrows([diskTable removeAllRows], @"Not allowed in read transaction");
    }];
}

- (void)testTransactionManagerAtDefaultPath
{
    // Create a new transaction manager
    RLMTransactionManager *manager = [self managerWithTestPath];
    
    [manager writeUsingBlock:^(RLMRealm *realm) {
        RLMTable *t = [realm createTableWithName:@"table"];
        
        [t addColumnWithName:@"col0" type:RLMTypeInt];
        [t addRow:@[@10]];
    }];
    
    [manager readUsingBlock:^(RLMRealm * realm) {
        RLMTable *t = [realm tableWithName:@"table"];
        XCTAssertEqualObjects(t[0][0], @10);
    }];
}

- (void)testRealmCreateTableWithColumns
{
    [[self managerWithTestPath] writeUsingBlock:^(RLMRealm *realm) {
        // Check if method throws exception
        XCTAssertNoThrow(([realm createTableWithName:@"Test" columns:@[@"id", @"int"]]), @"Table should not throw exception");
        
        // Test adding rows for single column table
        NSString* const RLMTableNameDepartment = @"Department";
        RLMTable* departmentTable = [realm createTableWithName:RLMTableNameDepartment columns:@[@"name", @"string"]];
        XCTAssertTrue(departmentTable.columnCount == 1, @"Table should have 1 column");
        XCTAssertTrue([[departmentTable nameOfColumnWithIndex:0] isEqualToString:@"name"], @"Column at index 0 should be name");
        XCTAssertNoThrow(([departmentTable addRow:@{@"name" : @"Engineering"}]), @"Adding row should not throw exception");
        
        // Test adding rows for multi-column table
        NSString* const RLMTableNameEmployee = @"Employee";
        RLMTable* employeeTable = [realm createTableWithName:RLMTableNameEmployee columns:@[@"id", @"int", @"name", @"string", @"position", @"string"]];
        XCTAssertTrue(employeeTable.columnCount == 3, @"Table should have 3 column");
        XCTAssertTrue([[employeeTable nameOfColumnWithIndex:0] isEqualToString:@"id"], @"Column at index 0 should be id");
        XCTAssertTrue([[employeeTable nameOfColumnWithIndex:1] isEqualToString:@"name"], @"Column at index 1 should be name");
        XCTAssertTrue([[employeeTable nameOfColumnWithIndex:2] isEqualToString:@"position"], @"Column at index 0 should be position");
        XCTAssertNoThrow(([employeeTable addRow:@{@"id" : @124312, @"name" : @"Fiel Guhit", @"position" : @"iOS Engineer"}]), @"Adding row should not throw exception");
    }];
}

- (void)testReadRealm
{
    RLMTransactionManager * fromDisk = [self managerWithTestPath];
    
    [fromDisk writeUsingBlock:^(RLMRealm *realm) {
        RLMTable *t = [realm createTableWithName:@"table"];
        
        [t addColumnWithName:@"col0" type:RLMTypeInt];
        [t addRow:@[@10]];
    }];
    
    [fromDisk readUsingBlock:^(RLMRealm * realm) {
        RLMTable *t = [realm tableWithName:@"table"];
        
        XCTAssertThrows([t addRow:nil], @"Is in read transaction");
        XCTAssertThrows([t addRow:@[@1]], @"Is in read transaction");
        
        RLMQuery *q = [t where];
        XCTAssertThrows([q removeRows], @"Is in read transaction");
        
        RLMView *v = [q findAllRows];
        
        XCTAssertThrows([v removeAllRows], @"Is in read transaction");
        XCTAssertThrows([[v where] removeRows], @"Is in read transaction");
        
        XCTAssertEqual(t.rowCount,      (NSUInteger)1, @"No rows have been removed");
        XCTAssertEqual([q countRows],   (NSUInteger)1, @"No rows have been removed");
        XCTAssertEqual(v.rowCount,      (NSUInteger)1, @"No rows have been removed");
        
        XCTAssertNil([realm tableWithName:@"Does not exist"], @"Table does not exist");
    }];
}

- (void)testSingleTableTransactions
{
    RLMTransactionManager * ctx = [self managerWithTestPath];
    
    [ctx writeUsingBlock:^(RLMRealm *realm) {
        RLMTable *t = [realm createTableWithName:@"table"];
        [t addColumnWithName:@"col0" type:RLMTypeInt];
        [t addRow:@[@10]];
    }];
    
    [ctx readTable:@"table" usingBlock:^(RLMTable* table) {
        XCTAssertTrue([table rowCount] == 1, @"No rows have been removed");
    }];
    
    [ctx writeTable:@"table" usingBlock:^(RLMTable* table) {
        [table addRow:@[@10]];
    }];
    
    [ctx readTable:@"table" usingBlock:^(RLMTable* table) {
        XCTAssertTrue([table rowCount] == 2, @"Rows were added");
    }];
}

- (void)testHasChanged
{
    RLMTransactionManager *manager1 = [self managerWithTestPath];
    
    XCTAssertFalse([manager1 hasChangedSinceLastTransaction], @"Transaction manager has not changed");
    
    [manager1 writeUsingBlock:^(RLMRealm *realm) {
        [realm createTableWithName:@"t"];
    }];
    
    XCTAssertFalse([manager1 hasChangedSinceLastTransaction], @"Transaction manager has not been changed by another process");
    
    
    [manager1 writeUsingBlock:^(RLMRealm *realm) {
        RLMTable *t = [realm tableWithName:@"t"];
        [t addColumnWithName:@"col" type:RLMTypeBool];
        [t addRow:nil];
        RLMRow *row = [t lastRow];
        [row setBool:YES inColumnWithIndex:0];
    }];
    
    XCTAssertFalse([manager1 hasChangedSinceLastTransaction], @"Transaction manager has not been changed by another process");
    
    
    // OTHER Transaction Manager
    RLMTransactionManager *manager2 = [self managerWithTestPath];
    
    [manager2 writeUsingBlock:^(RLMRealm *realm) {
        RLMTable *t = [realm tableWithName:@"t"];
        [t addRow:nil]; /* Adding an empty row */
    }];
    
    XCTAssertTrue([manager1 hasChangedSinceLastTransaction], @"Transaction manager HAS been changed by another process");
}

- (void)testTransactionManagerExceptions
{
    RLMTransactionManager *manager = [self managerWithTestPath];
    
    [manager writeUsingBlock:^(RLMRealm *realm) {
        
        XCTAssertThrows([realm createTableWithName:nil], @"name is nil");
        XCTAssertThrows([realm createTableWithName:@""], @"name is empty");
        
        [realm createTableWithName:@"name"];
        XCTAssertThrows([realm createTableWithName:@"name"], @"name already exists");
    }];
    
    [manager readUsingBlock:^(RLMRealm *realm) {
        
        XCTAssertThrows([realm tableWithName:nil], @"name is nil");
        XCTAssertThrows([realm tableWithName:@""], @"name is empty");
        XCTAssertThrows([realm createTableWithName:@"same name"], @"creating table not allowed in read transaction");
        XCTAssertThrows([realm createTableWithName:@"name"], @"creating table not allowed in read transaction");
        XCTAssertNil([realm tableWithName:@"weird name"], @"get table that does not exists return nil");
    }];
}

- (void)testPinnedTransactions
{
    __block RLMTransactionManager *manager1 = [self managerWithTestPath];
    __block RLMTransactionManager *manager2 = [self managerWithTestPath];
    
    {
        // initially, always say that the db has changed
        BOOL changed = [manager2 pinReadTransactions];
        XCTAssertTrue(changed, @"");
        [manager2 unpinReadTransactions];
        // asking again - this time there is no change
        changed = [manager2 pinReadTransactions];
        XCTAssertFalse(changed, @"");
        
        [manager2 unpinReadTransactions];
    }
    {   // add something to the db to play with
        [manager1 writeUsingBlock:^(RLMRealm *realm) {
            RLMTable *t1 = [realm createTableWithName:@"test"];
            [t1 addColumnWithName:@"col0" type:RLMTypeBool];
            [t1 addRow:@[@YES]];
        }];
    }
    {   // validate that we can see previous commit from within a new pinned transaction
        BOOL changed = [manager2 pinReadTransactions];
        XCTAssertTrue(changed, @"");
        [manager2 readUsingBlock:^(RLMRealm *realm) {
            RLMTable *t = [realm tableWithName:@"test"];
            XCTAssertEqual([[t rowAtIndex:0] boolInColumnWithIndex:0], YES, @"");
        }];
    }
    {   // commit new data in another transaction manager, without unpinning
        [manager1 writeUsingBlock:^(RLMRealm *realm) {
            RLMTable *t = [realm tableWithName:@"test"];
            [t addRow:@[@NO]];
        }];
    }
    {   // validate that we can see previous commit if we're not pinned
        [manager1 readUsingBlock:^(RLMRealm *realm) {
            RLMTable *t = [realm tableWithName:@"test"];
            XCTAssertEqual([[t rowAtIndex:1] boolInColumnWithIndex:0], NO, @"");
        }];
        
    }
    {   // validate that we can NOT see previous commit from within a pinned transaction
        [manager2 readUsingBlock:^(RLMRealm *realm) {
            RLMTable *t = [realm tableWithName:@"test"];
            XCTAssertEqual(t.rowCount, (NSUInteger)1, @"Still only 1 row");
        }];
        
    }
    {   // unpin, pin again and validate that we can now see previous commit
        [manager2 unpinReadTransactions];
        BOOL changed = [manager2 pinReadTransactions];
        XCTAssertTrue(changed, @"changes since last transaction");
        [manager2 readUsingBlock:^(RLMRealm *realm) {
            RLMTable *t = [realm tableWithName:@"test"];
            XCTAssertEqual(t.rowCount, (NSUInteger)2, @"Now we see 2 rows");
            XCTAssertEqual([[t rowAtIndex:1] boolInColumnWithIndex:0], NO, @"");
        }];
    }
    {   // can't pin if already pinned
        XCTAssertThrows([manager2 pinReadTransactions], @"Already pinned");
    }
    {   // can't unpin if already unpinned
        [manager2 unpinReadTransactions];
        XCTAssertThrows([manager2 unpinReadTransactions], @"Already unpinned");
        
    }
    {   // can't pin while we're inside a realm
        [manager2 readUsingBlock:^(RLMRealm *realm) {
            XCTAssertThrows([manager2 pinReadTransactions], @"Can't pin inside realm");
            XCTAssertNotNil(realm, @"Parameter must be used");
        }];
    }
    
    {   // can't unpin while we're inside a realm
        [manager1 pinReadTransactions];
        [manager1 readUsingBlock:^(RLMRealm *realm) {
            XCTAssertThrows([manager1 unpinReadTransactions], @"Can't unpin inside realm");
            XCTAssertNotNil(realm, @"Parameter must be used");
        }];
        [manager1 unpinReadTransactions];
    }
    {   // can't start a write transaction while pinned
        [manager1 pinReadTransactions];
        XCTAssertThrows([manager1 writeUsingBlock:^(RLMRealm *realm) {
            XCTAssertNotNil(realm, @"Parameter must be used");
        }], @"Can't start write transaction while pinned");
        [manager1 unpinReadTransactions];
    }
}

@end
