//
//  shared_group.m
//  TightDB
//
// Demo code for short tutorial using Objective-C interface
//

#import <SenTestingKit/SenTestingKit.h>

#import <tightdb/objc/Tightdb.h>
#import <tightdb/objc/TDBTransaction.h>
#import <tightdb/objc/group.h>

TIGHTDB_TABLE_2(SharedTable2,
                Hired, Bool,
                Age,   Int)


@interface MACTestSharedGroup: SenTestCase
@end
@implementation MACTestSharedGroup

- (void)testSharedGroup
{

    // TODO: Update test to include more ASSERTS


    TDBTransaction* group = [TDBTransaction group];
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
    TDBContext* fromDisk = [TDBContext contextWithPersistenceToFile:@"employees.tightdb" error:nil];

    [fromDisk readWithBlock:^(TDBTransaction* group) {
            SharedTable2* diskTable = [group getTableWithName:@"employees" asTableClass:[SharedTable2 class]];
            NSLog(@"Disktable size: %zu", [diskTable rowCount]);
            for (size_t i = 0; i < [diskTable rowCount]; i++) {
                SharedTable2Row *cursor = [diskTable rowAtIndex:i];
                NSLog(@"%zu: %lld", i, [cursor Age]);
                NSLog(@"%zu: %lld", i, cursor.Age);
                NSLog(@"%zu: %i", i, [diskTable TDB_boolInColumnWithIndex: 0 atRowIndex:i]);
            }
        }];


    [fromDisk writeWithBlock:^(TDBTransaction* group) {
            SharedTable2* diskTable = [group getTableWithName:@"employees" asTableClass:[SharedTable2 class]];
            NSLog(@"Disktable size: %zu", [diskTable rowCount]);
            for (size_t i = 0; i < 50; i++) {
                [diskTable addHired:YES Age:i];
            }
            return YES; // Commit
        } error:nil];


    [fromDisk writeWithBlock:^(TDBTransaction* group) {
            SharedTable2* diskTable = [group getTableWithName:@"employees" asTableClass:[SharedTable2 class]];
            NSLog(@"Disktable size: %zu", [diskTable rowCount]);
            for (size_t i = 0; i < 50; i++) {
                [diskTable addHired:YES Age:i];
            }
            return NO; // rollback
        } error:nil];


    [fromDisk writeWithBlock:^(TDBTransaction* group) {
            SharedTable2* diskTable = [group getTableWithName:@"employees" asTableClass:[SharedTable2 class]];
            NSLog(@"Disktable size: %zu", [diskTable rowCount]);
            for (size_t i = 0; i < 50; i++) {
                [diskTable addHired:YES Age:i];
            }
        
            STAssertNil([group getTableWithName:@"Does not exist"], @"Table does not exist");

            return YES; // commit
        } error:nil];

    [fromDisk readWithBlock:^(TDBTransaction* group) {
            SharedTable2* diskTable = [group getTableWithName:@"employees" asTableClass:[SharedTable2 class]];
            NSLog(@"Disktable size: %zu", [diskTable rowCount]);
        
        STAssertThrows([diskTable removeAllRows], @"Not allowed in readtransaction");

        }];
}

- (void) testReadTransaction
{
    
    NSFileManager* fm = [NSFileManager defaultManager];
    
    // Write to disk
    [fm removeItemAtPath:@"readonlyTest.tightdb" error:nil];
    [fm removeItemAtPath:@"readonlyTest.tightdb.lock" error:nil];
    
    TDBContext* fromDisk = [TDBContext contextWithPersistenceToFile:@"readonlyTest.tightdb" error:nil];
    
    [fromDisk writeWithBlock:^(TDBTransaction *group) {
        TDBTable *t = [group createTableWithName:@"table"];
        
        [t addColumnWithName:@"col0" andType:TDBIntType];
        NSUInteger rowIndex = [t addRow:nil];
        TDBRow *row = [t rowAtIndex:rowIndex];
        [row setInt:10 inColumnWithIndex:0 ];
         
        return YES;
        
    } error:nil];
    
    [fromDisk readWithBlock:^(TDBTransaction* group) {
        TDBTable *t = [group getTableWithName:@"table"];
       
        TDBQuery *q = [t where];
        
        TDBView *v = [q findAllRows];
        
        // Should not be allowed!
        STAssertThrows([v removeAllRows], @"Is in readTransaction");
        
        STAssertTrue([t rowCount] == 1, @"No rows have been removed");
        STAssertTrue([q countRows] == 1, @"No rows have been removed");
        STAssertTrue([v rowCount] == 1, @"No rows have been removed");
        
        STAssertNil([group getTableWithName:@"Does not exist"], @"Table does not exist");
    }];
}

- (void) testHasChanged
{
    
    NSFileManager* fm = [NSFileManager defaultManager];
    
    // Write to disk
    [fm removeItemAtPath:@"hasChanged.tightdb" error:nil];
    [fm removeItemAtPath:@"hasChanged.tightdb.lock" error:nil];
    
    TDBContext *sg = [TDBContext contextWithPersistenceToFile:@"hasChanged.tightdb" error:nil];
    
    STAssertFalse([sg hasChangedSinceLastTransaction], @"SharedGroup has not changed");
    
    [sg writeWithBlock:^(TDBTransaction* group) {
        [group createTableWithName:@"t"];
        return YES;
    } error:nil];
    
    STAssertFalse([sg hasChangedSinceLastTransaction], @"SharedGroup has not been changed by another process");

    
    [sg writeWithBlock:^(TDBTransaction* group) {
        TDBTable *t = [group getTableWithName:@"t"];
        [t addColumnWithName:@"col" andType:TDBBoolType];
        NSUInteger rowIndex = [t addRow:nil];
        TDBRow *row = [t rowAtIndex:rowIndex];
        [row setBool:YES inColumnWithIndex:0];
        return YES;
    } error:nil];
    
    STAssertFalse([sg hasChangedSinceLastTransaction], @"SharedGroup has not been changed by another process");
    
    
    // OTHER sharedgroup
    TDBContext *sg2 = [TDBContext contextWithPersistenceToFile:@"hasChanged.tightdb" error:nil];
    
    
    [sg2 writeWithBlock:^(TDBTransaction* group) {
        TDBTable *t = [group getTableWithName:@"t"];
        [t addRow:nil]; /* Adding an empty row */
        return YES;
    } error:nil];

    STAssertTrue([sg hasChangedSinceLastTransaction], @"SharedGroup HAS been changed by another process");
}


- (void)testContextExceptions
{
    NSString *contextPath = @"contextTest.tightdb";
    NSFileManager* fm = [NSFileManager defaultManager];
        [fm removeItemAtPath:contextPath error:nil];
    [fm removeItemAtPath:[contextPath stringByAppendingString:@".lock"] error:nil];
    
    TDBContext *c = [TDBContext contextWithPersistenceToFile:contextPath error:nil];
    
    [c writeWithBlock:^BOOL(TDBTransaction *transaction) {
        
        STAssertThrows([transaction createTableWithName:nil], @"name is nil");
        STAssertThrows([transaction createTableWithName:@""], @"name is empty");

        [transaction createTableWithName:@"name"];
        STAssertThrows([transaction createTableWithName:@"name"], @"name already exists");
        
        return YES;
    } error:nil];
    
    [c readWithBlock:^(TDBTransaction *transaction) {
        
        STAssertThrows([transaction getTableWithName:nil], @"name is nil");
        STAssertThrows([transaction getTableWithName:@""], @"name is empty");
        STAssertThrows([transaction createTableWithName:@"same name"], @"creating table not allowed in read transaction");
        STAssertThrows([transaction createTableWithName:@"name"], @"creating table not allowed in read transaction");
        STAssertNil([transaction getTableWithName:@"weird name"], @"get table that does not exists return nil");
    }];
}

-(void)testPinnedTransactions
{
    NSString *contextPath = @"pinnedTransactions.tightdb";
    NSFileManager* fm = [NSFileManager defaultManager];
    [fm removeItemAtPath:contextPath error:nil];
    [fm removeItemAtPath:[contextPath stringByAppendingString:@".lock"] error:nil];
   
    TDBContext *context1 = [TDBContext contextWithPersistenceToFile:contextPath error:nil];
    TDBContext *context2 = [TDBContext contextWithPersistenceToFile:contextPath error:nil];
    
    {
        // initially, always say that the db has changed
        BOOL changed = [context2 pinReadTransactions];
        STAssertTrue(changed, nil);
        [context2 unpinReadTransactions];
        // asking again - this time there is no change
        changed = [context2 pinReadTransactions];
        STAssertFalse(changed, nil);

        [context2 unpinReadTransactions];
    }
    {   // add something to the db to play with
        [context1 writeWithBlock:^BOOL(TDBTransaction *transaction) {
            TDBTable *t1 = [transaction createTableWithName:@"test"];
            [t1 addColumnWithName:@"col0" andType:TDBBoolType];
            [t1 addRow:@[@YES]];
            //t1->add(0, 2, false, "test");
            return YES;
        } error:nil];
        
    }
    {   // validate that we can see previous commit from within a new pinned transaction
        BOOL changed = [context2 pinReadTransactions];
        STAssertTrue(changed, nil);
        [context2 readWithBlock:^(TDBTransaction *transaction) {
            TDBTable *t = [transaction getTableWithName:@"test"];
            STAssertEquals([[t rowAtIndex:0] boolInColumnWithIndex:0], YES, nil);
        }];
        
    }
    {   // commit new data in another context, without unpinning
        [context1 writeWithBlock:^BOOL(TDBTransaction *transaction) {
            TDBTable *t = [transaction getTableWithName:@"test"];
            [t addRow:@[@NO]];
            return YES;
        } error:nil];
        
    }
    {   // validate that we can see previous commit if we're not pinned
        [context1 readWithBlock:^(TDBTransaction *transaction) {
            TDBTable *t = [transaction getTableWithName:@"test"];
            STAssertEquals([[t rowAtIndex:1] boolInColumnWithIndex:0], NO, nil);
        }];
        
    }
     /*{   // validate that we can NOT see previous commit from within a pinned transaction
        ReadTransaction rt(sg2);
        TestTableShared::ConstRef t1 = rt.get_table<TestTableShared>("test");
        CHECK_EQUAL(2, t1[0].second);
    }
    {   // unpin, pin again and validate that we can now see previous commit
        sg2.unpin_read_transactions();
        bool changed = sg2.pin_read_transactions();
        CHECK(changed);
        ReadTransaction rt(sg2);
        TestTableShared::ConstRef t1 = rt.get_table<TestTableShared>("test");
        CHECK_EQUAL(5, t1[0].second);
    }
    {   // can't pin if already pinned
        bool is_ok = false;
        try {
            sg2.pin_read_transactions();
        } catch (runtime_error&) {
            is_ok = true;
        }
        CHECK(is_ok);
        sg2.unpin_read_transactions();
    }
    {   // can't unpin if already unpinned
        bool is_ok = false;
        try {
            sg2.unpin_read_transactions();
        } catch (runtime_error&) {
            is_ok = true;
        }
        CHECK(is_ok);
    }
    {   // can't pin while we're inside a transaction
        ReadTransaction rt(sg1);
        bool is_ok = false;
        try {
            sg1.pin_read_transactions();
        } catch (runtime_error&) {
            is_ok = true;
        }
        CHECK(is_ok);
    }
    {   // can't unpin while we're inside a transaction
        sg1.pin_read_transactions();
        {
            ReadTransaction rt(sg1);
            bool is_ok = false;
            try {
                sg1.unpin_read_transactions();
            } catch (runtime_error&) {
                is_ok = true;
            }
            CHECK(is_ok);
        }
        sg1.unpin_read_transactions();
    }
    {   // can't start a write transaction while pinned
        sg1.pin_read_transactions();
        bool is_ok = false;
        try {
            WriteTransaction rt(sg1);
        } catch (runtime_error&) {
            is_ok = true;
        }
        CHECK(is_ok);
        sg1.unpin_read_transactions();
    }*/
}

@end



