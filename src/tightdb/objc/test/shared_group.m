//
//  shared_group.m
//  TightDB
//
// Demo code for short tutorial using Objective-C interface
//

#import <XCTest/XCTest.h>

#import <tightdb/objc/RLMFast.h>
#import <tightdb/objc/RLMTransaction.h>
#import <tightdb/objc/group.h>

TIGHTDB_TABLE_2(SharedTable2,
                Hired, Bool,
                Age,   Int)


@interface MACTestSharedGroup: XCTestCase
@end
@implementation MACTestSharedGroup

- (void)testSharedGroup
{

    // TODO: Update test to include more ASSERTS


    RLMTransaction * group = [RLMTransaction group];
    // Create new table in group
    SharedTable2 *table = [group createTableWithName:@"employees" asTableClass:[SharedTable2 class]];
    NSLog(@"Table: %@", table);
    // Add some rows
    [table addHired:YES Age:50];
    [table addHired:YES Age:52];
    [table addHired:YES Age:53];
    [table addHired:YES Age:54];

    NSLog(@"MyTable Size: %lu", [table rowCount]);


    NSFileManager* fm = [NSFileManager defaultManager];

    // Write to disk
    [fm removeItemAtPath:@"employees.tightdb" error:nil];
    [fm removeItemAtPath:@"employees.tightdb.lock" error:nil];
    [group writeContextToFile:@"employees.tightdb" error:nil];

    // Read only shared group
    RLMContext * fromDisk = [RLMContext contextPersistedAtPath:@"employees.tightdb" error:nil];

    [fromDisk readUsingBlock:^(RLMTransaction * group) {
            SharedTable2* diskTable = [group tableWithName:@"employees" asTableClass:[SharedTable2 class]];
            NSLog(@"Disktable size: %zu", [diskTable rowCount]);
            for (size_t i = 0; i < [diskTable rowCount]; i++) {
                SharedTable2Row *cursor = [diskTable rowAtIndex:i];
                NSLog(@"%zu: %lld", i, cursor.Age);
                NSLog(@"%zu: %i", i, [diskTable RLM_boolInColumnWithIndex: 0 atRowIndex:i]);
            }
        }];


    [fromDisk writeUsingBlock:^(RLMTransaction * group) {
            SharedTable2* diskTable = [group tableWithName:@"employees" asTableClass:[SharedTable2 class]];
            NSLog(@"Disktable size: %zu", [diskTable rowCount]);
            for (size_t i = 0; i < 50; i++) {
                [diskTable addHired:YES Age:i];
            }
            return YES; // Commit
        } error:nil];


    [fromDisk writeUsingBlock:^(RLMTransaction * group) {
            SharedTable2* diskTable = [group tableWithName:@"employees" asTableClass:[SharedTable2 class]];
            NSLog(@"Disktable size: %zu", [diskTable rowCount]);
            for (size_t i = 0; i < 50; i++) {
                [diskTable addHired:YES Age:i];
            }
            return NO; // rollback
        } error:nil];


    [fromDisk writeUsingBlock:^(RLMTransaction * group) {
            SharedTable2* diskTable = [group tableWithName:@"employees" asTableClass:[SharedTable2 class]];
            NSLog(@"Disktable size: %zu", [diskTable rowCount]);
            for (size_t i = 0; i < 50; i++) {
                [diskTable addHired:YES Age:i];
            }
        
            XCTAssertNil([group tableWithName:@"Does not exist"], @"Table does not exist");

            return YES; // commit
        } error:nil];

    [fromDisk readUsingBlock:^(RLMTransaction * group) {
            SharedTable2* diskTable = [group tableWithName:@"employees" asTableClass:[SharedTable2 class]];
            NSLog(@"Disktable size: %zu", [diskTable rowCount]);
        
        XCTAssertThrows([diskTable removeAllRows], @"Not allowed in readtransaction");

    }];
}


-(void)testContextAtDefaultPath
{
    // Delete existing files

    NSString *defaultPath = [RLMContext defaultPath];
    
    NSFileManager* fm = [NSFileManager defaultManager];
    [fm removeItemAtPath:defaultPath error:nil];
    [fm removeItemAtPath:[defaultPath stringByAppendingString:@".lock"] error:nil];
    
    // Create a new context at default location
    RLMContext *context = [RLMContext contextWithDefaultPersistence];
    
    [context writeUsingBlock:^(RLMTransaction *transaction) {
        RLMTable *t = [transaction createTableWithName:@"table"];
        
        [t addColumnWithName:@"col0" type:RLMTypeInt];
        [t addRow:@[@10]];
        
        return YES;
        
    } error:nil];
    
    [context readUsingBlock:^(RLMTransaction * transaction) {
        RLMTable *t = [transaction tableWithName:@"table"];
        XCTAssertEqualObjects(t[0][0], @10);
    }];
}

- (void)testSharedGroupCreateTableWithColumns
{
    RLMTransaction * transaction = [RLMTransaction group];
    
    // Check if method throws exception
    XCTAssertNoThrow(([transaction createTableWithName:@"Test" columns:@[@"id", @"int"]]), @"Table should not throw exception");
    
    // Test adding rows for single column table
    NSString* const RLMTableNameDepartment = @"Department";
    RLMTable* departmentTable = [transaction createTableWithName:RLMTableNameDepartment columns:@[@"name", @"string"]];
    XCTAssertTrue(departmentTable.columnCount == 1, @"Table should have 1 column");
    XCTAssertTrue([[departmentTable nameOfColumnWithIndex:0] isEqualToString:@"name"], @"Column at index 0 should be name");
    XCTAssertNoThrow(([departmentTable addRow:@{@"name" : @"Engineering"}]), @"Adding row should not throw exception");
    
    // Test adding rows for multi-column table
    NSString* const RLMTableNameEmployee = @"Employee";
    RLMTable* employeeTable = [transaction createTableWithName:RLMTableNameEmployee columns:@[@"id", @"int", @"name", @"string", @"position", @"string"]];
    XCTAssertTrue(employeeTable.columnCount == 3, @"Table should have 3 column");
    XCTAssertTrue([[employeeTable nameOfColumnWithIndex:0] isEqualToString:@"id"], @"Column at index 0 should be id");
    XCTAssertTrue([[employeeTable nameOfColumnWithIndex:1] isEqualToString:@"name"], @"Column at index 1 should be name");
    XCTAssertTrue([[employeeTable nameOfColumnWithIndex:2] isEqualToString:@"position"], @"Column at index 0 should be position");
    XCTAssertNoThrow(([employeeTable addRow:@{@"id" : @124312, @"name" : @"Fiel Guhit", @"position" : @"iOS Engineer"}]), @"Adding row should not throw exception");
}

- (void) testReadTransaction
{
    
    NSFileManager* fm = [NSFileManager defaultManager];
    
    // Write to disk
    [fm removeItemAtPath:@"readonlyTest.tightdb" error:nil];
    [fm removeItemAtPath:@"readonlyTest.tightdb.lock" error:nil];
    
    RLMContext * fromDisk = [RLMContext contextPersistedAtPath:@"readonlyTest.tightdb" error:nil];
    
    [fromDisk writeUsingBlock:^(RLMTransaction *group) {
        RLMTable *t = [group createTableWithName:@"table"];
        
        [t addColumnWithName:@"col0" type:RLMTypeInt];
        [t addRow:@[@10]];
         
        return YES;
    } error:nil];
    
    [fromDisk readUsingBlock:^(RLMTransaction * group) {
        RLMTable *t = [group tableWithName:@"table"];
        
        XCTAssertThrows([t addRow:nil], @"Is in readTransaction");
        XCTAssertThrows([t addRow:@[@1]], @"Is in readTransaction");
       
        RLMQuery *q = [t where];
        XCTAssertThrows([q removeRows], @"Is in readTransaction");

        RLMView *v = [q findAllRows];
        
        XCTAssertThrows([v removeAllRows], @"Is in readTransaction");
        XCTAssertThrows([[v where] removeRows], @"Is in readTransaction");
        
        XCTAssertEqual(t.rowCount,      (NSUInteger)1, @"No rows have been removed");
        XCTAssertEqual([q countRows],   (NSUInteger)1, @"No rows have been removed");
        XCTAssertEqual(v.rowCount,      (NSUInteger)1, @"No rows have been removed");
        
        XCTAssertNil([group tableWithName:@"Does not exist"], @"Table does not exist");
    }];
}

- (void) testSingleTableTransactions
{
    NSFileManager* fm = [NSFileManager defaultManager];

    // Write to disk
    [fm removeItemAtPath:@"singleTest.tightdb" error:nil];
    [fm removeItemAtPath:@"singleTest.tightdb.lock" error:nil];

    RLMContext * ctx = [RLMContext contextPersistedAtPath:@"singleTest.tightdb" error:nil];

    [ctx writeUsingBlock:^(RLMTransaction *trx) {
        RLMTable *t = [trx createTableWithName:@"table"];
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

- (void) testHasChanged
{
    
    NSFileManager* fm = [NSFileManager defaultManager];
    
    // Write to disk
    [fm removeItemAtPath:@"hasChanged.tightdb" error:nil];
    [fm removeItemAtPath:@"hasChanged.tightdb.lock" error:nil];
    
    RLMContext *sg = [RLMContext contextPersistedAtPath:@"hasChanged.tightdb" error:nil];
    
    XCTAssertFalse([sg hasChangedSinceLastTransaction], @"SharedGroup has not changed");
    
    [sg writeUsingBlock:^(RLMTransaction * group) {
        [group createTableWithName:@"t"];
        return YES;
    } error:nil];
    
    XCTAssertFalse([sg hasChangedSinceLastTransaction], @"SharedGroup has not been changed by another process");

    
    [sg writeUsingBlock:^(RLMTransaction * group) {
        RLMTable *t = [group tableWithName:@"t"];
        [t addColumnWithName:@"col" type:RLMTypeBool];
        [t addRow:nil];
        RLMRow *row = [t lastRow];
        [row setBool:YES inColumnWithIndex:0];
        return YES;
    } error:nil];
    
    XCTAssertFalse([sg hasChangedSinceLastTransaction], @"SharedGroup has not been changed by another process");
    
    
    // OTHER sharedgroup
    RLMContext *sg2 = [RLMContext contextPersistedAtPath:@"hasChanged.tightdb" error:nil];
    
    
    [sg2 writeUsingBlock:^(RLMTransaction * group) {
        RLMTable *t = [group tableWithName:@"t"];
        [t addRow:nil]; /* Adding an empty row */
        return YES;
    } error:nil];

    XCTAssertTrue([sg hasChangedSinceLastTransaction], @"SharedGroup HAS been changed by another process");
}


- (void)testContextExceptions
{
    NSString *contextPath = @"contextTest.tightdb";
    NSFileManager* fm = [NSFileManager defaultManager];
        [fm removeItemAtPath:contextPath error:nil];
    [fm removeItemAtPath:[contextPath stringByAppendingString:@".lock"] error:nil];
    
    RLMContext *c = [RLMContext contextPersistedAtPath:contextPath error:nil];
    
    [c writeUsingBlock:^BOOL(RLMTransaction *transaction) {
        
        XCTAssertThrows([transaction createTableWithName:nil], @"name is nil");
        XCTAssertThrows([transaction createTableWithName:@""], @"name is empty");

        [transaction createTableWithName:@"name"];
        XCTAssertThrows([transaction createTableWithName:@"name"], @"name already exists");
        
        return YES;
    } error:nil];
    
    [c readUsingBlock:^(RLMTransaction *transaction) {
        
        XCTAssertThrows([transaction tableWithName:nil], @"name is nil");
        XCTAssertThrows([transaction tableWithName:@""], @"name is empty");
        XCTAssertThrows([transaction createTableWithName:@"same name"], @"creating table not allowed in read transaction");
        XCTAssertThrows([transaction createTableWithName:@"name"], @"creating table not allowed in read transaction");
        XCTAssertNil([transaction tableWithName:@"weird name"], @"get table that does not exists return nil");
    }];
}

-(void)testPinnedTransactions
{
    NSString *contextPath = @"pinnedTransactions.tightdb";
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
        [context1 writeUsingBlock:^BOOL(RLMTransaction *transaction) {
            RLMTable *t1 = [transaction createTableWithName:@"test"];
            [t1 addColumnWithName:@"col0" type:RLMTypeBool];
            [t1 addRow:@[@YES]];
            //t1->add(0, 2, false, "test");
            return YES;
        } error:nil];
    }
    {   // validate that we can see previous commit from within a new pinned transaction
        BOOL changed = [context2 pinReadTransactions];
        XCTAssertTrue(changed, @"");
        [context2 readUsingBlock:^(RLMTransaction *transaction) {
            RLMTable *t = [transaction tableWithName:@"test"];
            XCTAssertEqual([[t rowAtIndex:0] boolInColumnWithIndex:0], YES, @"");
        }];
    }
    {   // commit new data in another context, without unpinning
        [context1 writeUsingBlock:^BOOL(RLMTransaction *transaction) {
            RLMTable *t = [transaction tableWithName:@"test"];
            [t addRow:@[@NO]];
            return YES;
        } error:nil];
        
    }
    {   // validate that we can see previous commit if we're not pinned
        [context1 readUsingBlock:^(RLMTransaction *transaction) {
            RLMTable *t = [transaction tableWithName:@"test"];
            XCTAssertEqual([[t rowAtIndex:1] boolInColumnWithIndex:0], NO, @"");
        }];
        
    }
     {   // validate that we can NOT see previous commit from within a pinned transaction
        [context2 readUsingBlock:^(RLMTransaction *transaction) {
            RLMTable *t = [transaction tableWithName:@"test"];
            XCTAssertEqual(t.rowCount, (NSUInteger)1, @"Still only 1 row");
        }];
        
    }
    {   // unpin, pin again and validate that we can now see previous commit
        [context2 unpinReadTransactions];
        BOOL changed = [context2 pinReadTransactions];
        XCTAssertTrue(changed, @"changes since last transaction");
        [context2 readUsingBlock:^(RLMTransaction *transaction) {
            RLMTable *t = [transaction tableWithName:@"test"];
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
    {   // can't pin while we're inside a transaction
        [context1 readUsingBlock:^(RLMTransaction *transaction) {
            XCTAssertThrows([context1 pinReadTransactions], @"Can't pin inside transaction");
            XCTAssertNotNil(transaction, @"Parameter must be used");
        }];
    }
    
    {   // can't unpin while we're inside a transaction
        [context1 pinReadTransactions];
        [context1 readUsingBlock:^(RLMTransaction *transaction) {
            XCTAssertThrows([context1 unpinReadTransactions], @"Can't unpin inside transaction");
            XCTAssertNotNil(transaction, @"Parameter must be used");
        }];
        [context1 unpinReadTransactions];
    }
    {   // can't start a write transaction while pinned
        [context1 pinReadTransactions];
        XCTAssertThrows([context1 writeUsingBlock:^BOOL(RLMTransaction *transaction) {
            XCTAssertNotNil(transaction, @"Parameter must be used");
            return YES;
        } error:nil], @"Can't start write transaction while pinned");
        [context1 unpinReadTransactions];
    }
}

@end



