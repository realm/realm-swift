//
//  shared_group.m
//  TightDB
//
// Demo code for short tutorial using Objective-C interface
//

#import <XCTest/XCTest.h>

#import <realm/objc/RLMFast.h>
#import <realm/objc/RLMRealm.h>

REALM_TABLE_2(SharedTable2,
              Hired, Bool,
              Age,   Int)

@interface MACTestSharedGroup: XCTestCase

@end

@implementation MACTestSharedGroup

- (void)testContext {

    // TODO: Update test to include more ASSERTS
    
    NSFileManager* fm = [NSFileManager defaultManager];
    
    // Delete file
    [fm removeItemAtPath:@"employees.realm" error:nil];
    [fm removeItemAtPath:@"employees.realm.lock" error:nil];
    
    RLMContext *context = [RLMContext contextPersistedAtPath:@"employees.realm"
                                                       error:nil];
    
    [context writeUsingBlock:^BOOL(RLMRealm *realm) {
        // Create new table in realm
        SharedTable2 *table = [realm createTableWithName:@"employees" asTableClass:[SharedTable2 class]];
        NSLog(@"Table: %@", table);
        // Add some rows
        [table addHired:YES Age:50];
        [table addHired:YES Age:52];
        [table addHired:YES Age:53];
        [table addHired:YES Age:54];
        
        NSLog(@"MyTable Size: %lu", [table rowCount]);
        return YES;
    } error:nil];
    
    // Read-only realm
    RLMContext *fromDisk = [RLMContext contextPersistedAtPath:@"employees.realm" error:nil];
    
    [fromDisk readUsingBlock:^(RLMRealm *realm) {
        SharedTable2* diskTable = [realm tableWithName:@"employees" asTableClass:[SharedTable2 class]];
        NSLog(@"Disktable size: %zu", [diskTable rowCount]);
        for (size_t i = 0; i < [diskTable rowCount]; i++) {
            SharedTable2Row *cursor = [diskTable rowAtIndex:i];
            NSLog(@"%zu: %lld", i, cursor.Age);
            NSLog(@"%zu: %i", i, [diskTable RLM_boolInColumnWithIndex: 0 atRowIndex:i]);
        }
    }];
    
    [fromDisk writeUsingBlock:^(RLMRealm *realm) {
        SharedTable2* diskTable = [realm tableWithName:@"employees" asTableClass:[SharedTable2 class]];
        NSLog(@"Disktable size: %zu", [diskTable rowCount]);
        for (size_t i = 0; i < 50; i++) {
            [diskTable addHired:YES Age:i];
        }
        return YES; // Commit
    } error:nil];
    
    [fromDisk writeUsingBlock:^(RLMRealm *realm) {
        SharedTable2* diskTable = [realm tableWithName:@"employees" asTableClass:[SharedTable2 class]];
        NSLog(@"Disktable size: %zu", [diskTable rowCount]);
        for (size_t i = 0; i < 50; i++) {
            [diskTable addHired:YES Age:i];
        }
        return NO; // rollback
    } error:nil];
    
    [fromDisk writeUsingBlock:^(RLMRealm *realm) {
        SharedTable2* diskTable = [realm tableWithName:@"employees" asTableClass:[SharedTable2 class]];
        NSLog(@"Disktable size: %zu", [diskTable rowCount]);
        for (size_t i = 0; i < 50; i++) {
            [diskTable addHired:YES Age:i];
        }
        
        XCTAssertNil([realm tableWithName:@"Does not exist"], @"Table does not exist");
        return YES; // commit
    } error:nil];

    [fromDisk readUsingBlock:^(RLMRealm * realm) {
        SharedTable2* diskTable = [realm tableWithName:@"employees" asTableClass:[SharedTable2 class]];
        NSLog(@"Disktable size: %zu", [diskTable rowCount]);
        
        XCTAssertThrows([diskTable removeAllRows], @"Not allowed in read realm");
    }];
}

- (void)testContextAtDefaultPath
{
    // Delete existing files

    NSString *defaultPath = [RLMContext defaultPath];
    
    NSFileManager* fm = [NSFileManager defaultManager];
    [fm removeItemAtPath:defaultPath error:nil];
    [fm removeItemAtPath:[defaultPath stringByAppendingString:@".lock"] error:nil];
    
    // Create a new context at default location
    RLMContext *context = [RLMContext contextWithDefaultPersistence];
    
    [context writeUsingBlock:^(RLMRealm *realm) {
        RLMTable *t = [realm createTableWithName:@"table"];
        
        [t addColumnWithName:@"col0" type:RLMTypeInt];
        [t addRow:@[@10]];
        
        return YES;
        
    } error:nil];
    
    [context readUsingBlock:^(RLMRealm * realm) {
        RLMTable *t = [realm tableWithName:@"table"];
        XCTAssertEqualObjects(t[0][0], @10);
    }];
}

- (void)testRealmCreateTableWithColumns
{
    RLMContext *context = [RLMContext contextWithDefaultPersistence];
    
    [context writeUsingBlock:^BOOL(RLMRealm *realm) {
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
    } error:nil];
}

- (void)testReadRealm
{
    
    NSFileManager* fm = [NSFileManager defaultManager];
    
    // Write to disk
    [fm removeItemAtPath:@"readonlyTest.realm" error:nil];
    [fm removeItemAtPath:@"readonlyTest.realm.lock" error:nil];
    
    RLMContext * fromDisk = [RLMContext contextPersistedAtPath:@"readonlyTest.realm" error:nil];
    
    [fromDisk writeUsingBlock:^(RLMRealm *realm) {
        RLMTable *t = [realm createTableWithName:@"table"];
        
        [t addColumnWithName:@"col0" type:RLMTypeInt];
        [t addRow:@[@10]];
         
        return YES;
    } error:nil];
    
    [fromDisk readUsingBlock:^(RLMRealm * realm) {
        RLMTable *t = [realm tableWithName:@"table"];
        
        XCTAssertThrows([t addRow:nil], @"Is in read realm");
        XCTAssertThrows([t addRow:@[@1]], @"Is in read realm");
       
        RLMQuery *q = [t where];
        XCTAssertThrows([q removeRows], @"Is in read realm");

        RLMView *v = [q findAllRows];
        
        XCTAssertThrows([v removeAllRows], @"Is in read realm");
        XCTAssertThrows([[v where] removeRows], @"Is in read realm");
        
        XCTAssertEqual(t.rowCount,      (NSUInteger)1, @"No rows have been removed");
        XCTAssertEqual([q countRows],   (NSUInteger)1, @"No rows have been removed");
        XCTAssertEqual(v.rowCount,      (NSUInteger)1, @"No rows have been removed");
        
        XCTAssertNil([realm tableWithName:@"Does not exist"], @"Table does not exist");
    }];
}

- (void)testSingleTableTransactions
{
    NSFileManager* fm = [NSFileManager defaultManager];

    // Write to disk
    [fm removeItemAtPath:@"singleTest.realm" error:nil];
    [fm removeItemAtPath:@"singleTest.realm.lock" error:nil];

    RLMContext * ctx = [RLMContext contextPersistedAtPath:@"singleTest.realm" error:nil];

    [ctx writeUsingBlock:^(RLMRealm *realm) {
        RLMTable *t = [realm createTableWithName:@"table"];
        [t addColumnWithName:@"col0" type:RLMTypeInt];
        [t addRow:@[@10]];
        return YES;
    } error:nil];

    [ctx readTable:@"table" usingBlock:^(RLMTable* table) {
        XCTAssertTrue([table rowCount] == 1, @"No rows have been removed");
    }];

    [ctx writeTable:@"table" usingBlock:^(RLMTable* table) {
        [table addRow:@[@10]];
        return YES;
    } error:nil];

    [ctx readTable:@"table" usingBlock:^(RLMTable* table) {
        XCTAssertTrue([table rowCount] == 2, @"Rows were added");
    }];
}

- (void)testHasChanged
{
    
    NSFileManager* fm = [NSFileManager defaultManager];
    
    // Write to disk
    [fm removeItemAtPath:@"hasChanged.realm" error:nil];
    [fm removeItemAtPath:@"hasChanged.realm.lock" error:nil];
    
    RLMContext *sg = [RLMContext contextPersistedAtPath:@"hasChanged.realm" error:nil];
    
    XCTAssertFalse([sg hasChangedSinceLastTransaction], @"Context has not changed");
    
    [sg writeUsingBlock:^(RLMRealm *realm) {
        [realm createTableWithName:@"t"];
        return YES;
    } error:nil];
    
    XCTAssertFalse([sg hasChangedSinceLastTransaction], @"Context has not been changed by another process");

    
    [sg writeUsingBlock:^(RLMRealm *realm) {
        RLMTable *t = [realm tableWithName:@"t"];
        [t addColumnWithName:@"col" type:RLMTypeBool];
        [t addRow:nil];
        RLMRow *row = [t lastRow];
        [row setBool:YES inColumnWithIndex:0];
        return YES;
    } error:nil];
    
    XCTAssertFalse([sg hasChangedSinceLastTransaction], @"Context has not been changed by another process");
    
    
    // OTHER context
    RLMContext *sg2 = [RLMContext contextPersistedAtPath:@"hasChanged.realm" error:nil];
    
    
    [sg2 writeUsingBlock:^(RLMRealm *realm) {
        RLMTable *t = [realm tableWithName:@"t"];
        [t addRow:nil]; /* Adding an empty row */
        return YES;
    } error:nil];

    XCTAssertTrue([sg hasChangedSinceLastTransaction], @"Context HAS been changed by another process");
}

- (void)testContextExceptions
{
    NSString *contextPath = @"contextTest.realm";
    NSFileManager* fm = [NSFileManager defaultManager];
        [fm removeItemAtPath:contextPath error:nil];
    [fm removeItemAtPath:[contextPath stringByAppendingString:@".lock"] error:nil];
    
    RLMContext *c = [RLMContext contextPersistedAtPath:contextPath error:nil];
    
    [c writeUsingBlock:^BOOL(RLMRealm *realm) {
        
        XCTAssertThrows([realm createTableWithName:nil], @"name is nil");
        XCTAssertThrows([realm createTableWithName:@""], @"name is empty");

        [realm createTableWithName:@"name"];
        XCTAssertThrows([realm createTableWithName:@"name"], @"name already exists");
        
        return YES;
    } error:nil];
    
    [c readUsingBlock:^(RLMRealm *realm) {
        
        XCTAssertThrows([realm tableWithName:nil], @"name is nil");
        XCTAssertThrows([realm tableWithName:@""], @"name is empty");
        XCTAssertThrows([realm createTableWithName:@"same name"], @"creating table not allowed in read realm");
        XCTAssertThrows([realm createTableWithName:@"name"], @"creating table not allowed in read realm");
        XCTAssertNil([realm tableWithName:@"weird name"], @"get table that does not exists return nil");
    }];
}

- (void)testPinnedTransactions
{
    NSString *contextPath = @"pinnedTransactions.realm";
    NSFileManager* fm = [NSFileManager defaultManager];
    [fm removeItemAtPath:contextPath error:nil];
    [fm removeItemAtPath:[contextPath stringByAppendingString:@".lock"] error:nil];
   
    __block RLMContext *context1 = [RLMContext contextPersistedAtPath:contextPath error:nil];
    __block RLMContext *context2 = [RLMContext contextPersistedAtPath:contextPath error:nil];
    
    {
        // initially, always say that the db has changed
        BOOL changed = [context2 pinReadTransactions];
        XCTAssertTrue(changed, @"");
        [context2 unpinReadTransactions];
        // asking again - this time there is no change
        changed = [context2 pinReadTransactions];
        XCTAssertFalse(changed, @"");

        [context2 unpinReadTransactions];
    }
    {   // add something to the db to play with
        [context1 writeUsingBlock:^BOOL(RLMRealm *realm) {
            RLMTable *t1 = [realm createTableWithName:@"test"];
            [t1 addColumnWithName:@"col0" type:RLMTypeBool];
            [t1 addRow:@[@YES]];
            //t1->add(0, 2, false, "test");
            return YES;
        } error:nil];
    }
    {   // validate that we can see previous commit from within a new pinned transaction
        BOOL changed = [context2 pinReadTransactions];
        XCTAssertTrue(changed, @"");
        [context2 readUsingBlock:^(RLMRealm *realm) {
            RLMTable *t = [realm tableWithName:@"test"];
            XCTAssertEqual([[t rowAtIndex:0] boolInColumnWithIndex:0], YES, @"");
        }];
    }
    {   // commit new data in another context, without unpinning
        [context1 writeUsingBlock:^BOOL(RLMRealm *realm) {
            RLMTable *t = [realm tableWithName:@"test"];
            [t addRow:@[@NO]];
            return YES;
        } error:nil];
        
    }
    {   // validate that we can see previous commit if we're not pinned
        [context1 readUsingBlock:^(RLMRealm *realm) {
            RLMTable *t = [realm tableWithName:@"test"];
            XCTAssertEqual([[t rowAtIndex:1] boolInColumnWithIndex:0], NO, @"");
        }];
        
    }
     {   // validate that we can NOT see previous commit from within a pinned transaction
        [context2 readUsingBlock:^(RLMRealm *realm) {
            RLMTable *t = [realm tableWithName:@"test"];
            XCTAssertEqual(t.rowCount, (NSUInteger)1, @"Still only 1 row");
        }];
        
    }
    {   // unpin, pin again and validate that we can now see previous commit
        [context2 unpinReadTransactions];
        BOOL changed = [context2 pinReadTransactions];
        XCTAssertTrue(changed, @"changes since last transaction");
        [context2 readUsingBlock:^(RLMRealm *realm) {
            RLMTable *t = [realm tableWithName:@"test"];
            XCTAssertEqual(t.rowCount, (NSUInteger)2, @"Now we see 2 rows");
            XCTAssertEqual([[t rowAtIndex:1] boolInColumnWithIndex:0], NO, @"");
        }];
    }
    {   // can't pin if already pinned
        XCTAssertThrows([context2 pinReadTransactions], @"Already pinned");
    }
    {   // can't unpin if already unpinned
        [context2 unpinReadTransactions];
        XCTAssertThrows([context2 unpinReadTransactions], @"Already unpinned");

    }
    {   // can't pin while we're inside a realm
        [context1 readUsingBlock:^(RLMRealm *realm) {
            XCTAssertThrows([context1 pinReadTransactions], @"Can't pin inside realm");
            XCTAssertNotNil(realm, @"Parameter must be used");
        }];
    }
    
    {   // can't unpin while we're inside a realm
        [context1 pinReadTransactions];
        [context1 readUsingBlock:^(RLMRealm *realm) {
            XCTAssertThrows([context1 unpinReadTransactions], @"Can't unpin inside realm");
            XCTAssertNotNil(realm, @"Parameter must be used");
        }];
        [context1 unpinReadTransactions];
    }
    {   // can't start a write realm while pinned
        [context1 pinReadTransactions];
        XCTAssertThrows([context1 writeUsingBlock:^BOOL(RLMRealm *realm) {
            XCTAssertNotNil(realm, @"Parameter must be used");
            return YES;
        } error:nil], @"Can't start write realm while pinned");
        [context1 unpinReadTransactions];
    }
}

@end
