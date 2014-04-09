//
//  shared_group.m
//  TightDB
//
// Demo code for short tutorial using Objective-C interface
//

#import <SenTestingKit/SenTestingKit.h>

#import <tightdb/objc/TightdbFast.h>
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
            SharedTable2* diskTable = [group tableWithName:@"employees" asTableClass:[SharedTable2 class]];
            NSLog(@"Disktable size: %zu", [diskTable rowCount]);
            for (size_t i = 0; i < [diskTable rowCount]; i++) {
                SharedTable2Row *cursor = [diskTable rowAtIndex:i];
                NSLog(@"%zu: %lld", i, cursor.Age);
                NSLog(@"%zu: %i", i, [diskTable TDB_boolInColumnWithIndex: 0 atRowIndex:i]);
            }
        }];


    [fromDisk writeWithBlock:^(TDBTransaction* group) {
            SharedTable2* diskTable = [group tableWithName:@"employees" asTableClass:[SharedTable2 class]];
            NSLog(@"Disktable size: %zu", [diskTable rowCount]);
            for (size_t i = 0; i < 50; i++) {
                [diskTable addHired:YES Age:i];
            }
            return YES; // Commit
        } error:nil];


    [fromDisk writeWithBlock:^(TDBTransaction* group) {
            SharedTable2* diskTable = [group tableWithName:@"employees" asTableClass:[SharedTable2 class]];
            NSLog(@"Disktable size: %zu", [diskTable rowCount]);
            for (size_t i = 0; i < 50; i++) {
                [diskTable addHired:YES Age:i];
            }
            return NO; // rollback
        } error:nil];


    [fromDisk writeWithBlock:^(TDBTransaction* group) {
            SharedTable2* diskTable = [group tableWithName:@"employees" asTableClass:[SharedTable2 class]];
            NSLog(@"Disktable size: %zu", [diskTable rowCount]);
            for (size_t i = 0; i < 50; i++) {
                [diskTable addHired:YES Age:i];
            }
        
            STAssertNil([group tableWithName:@"Does not exist"], @"Table does not exist");

            return YES; // commit
        } error:nil];

    [fromDisk readWithBlock:^(TDBTransaction* group) {
            SharedTable2* diskTable = [group tableWithName:@"employees" asTableClass:[SharedTable2 class]];
            NSLog(@"Disktable size: %zu", [diskTable rowCount]);
        
        STAssertThrows([diskTable removeAllRows], @"Not allowed in readtransaction");

    }];
}


-(void)testContextAtDefaultPath
{
    // Delete existing files
    NSArray* paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString* documentsDirectory = [paths objectAtIndex:0];
    NSString *path = [documentsDirectory stringByAppendingPathComponent:@"default.tightdb"];
    
    NSFileManager* fm = [NSFileManager defaultManager];
    [fm removeItemAtPath:path error:nil];
    [fm removeItemAtPath:[path stringByAppendingString:@".lock"] error:nil];
    
    // Create a new context at default location
    TDBContext *context = [TDBContext contextAtDefaultPathWithError:nil];
    
    [context writeWithBlock:^(TDBTransaction *transaction) {
        TDBTable *t = [transaction createTableWithName:@"table"];
        
        [t addColumnWithName:@"col0" type:TDBIntType];
        [t addRow:@[@10]];
        
        return YES;
        
    } error:nil];
    
    [context readWithBlock:^(TDBTransaction* transaction) {
        TDBTable *t = [transaction tableWithName:@"table"];
        STAssertEqualObjects(t[0][0], @10, nil);
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
        
        [t addColumnWithName:@"col0" type:TDBIntType];
        [t addRow:@[@10]];
         
        return YES;
        
    } error:nil];
    
    [fromDisk readWithBlock:^(TDBTransaction* group) {
        TDBTable *t = [group tableWithName:@"table"];
        
        STAssertThrows([t addRow:nil], @"Is in readTransaction");
        STAssertThrows([t addRow:@[@1]], @"Is in readTransaction");
       
        TDBQuery *q = [t where];
        STAssertThrows([q removeRows], @"Is in readTransaction");

        TDBView *v = [q findAllRows];
        
        STAssertThrows([v removeAllRows], @"Is in readTransaction");
        STAssertThrows([[v where] removeRows], @"Is in readTransaction");
        
        STAssertEquals(t.rowCount,      (NSUInteger)1, @"No rows have been removed");
        STAssertEquals([q countRows],   (NSUInteger)1, @"No rows have been removed");
        STAssertEquals(v.rowCount,      (NSUInteger)1, @"No rows have been removed");
        
        STAssertNil([group tableWithName:@"Does not exist"], @"Table does not exist");
    }];
}

- (void) testSingleTableTransactions
{
    NSFileManager* fm = [NSFileManager defaultManager];

    // Write to disk
    [fm removeItemAtPath:@"singleTest.tightdb" error:nil];
    [fm removeItemAtPath:@"singleTest.tightdb.lock" error:nil];

    TDBContext* ctx = [TDBContext contextWithPersistenceToFile:@"singleTest.tightdb" error:nil];

    [ctx writeWithBlock:^(TDBTransaction *trx) {
        TDBTable *t = [trx createTableWithName:@"table"];
        [t addColumnWithName:@"col0" type:TDBIntType];
        [t addRow:@[@10]];
        return YES;
    } error:nil];

    [ctx readTable:@"table" withBlock:^(TDBTable* table) {
        STAssertTrue([table rowCount] == 1, @"No rows have been removed");
    }];

    [ctx writeTable:@"table" withBlock:^(TDBTable* table) {
        [table addRow:@[@10]];
        return YES;
    } error:nil];

    [ctx readTable:@"table" withBlock:^(TDBTable* table) {
        STAssertTrue([table rowCount] == 2, @"Rows were added");
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
        TDBTable *t = [group tableWithName:@"t"];
        [t addColumnWithName:@"col" type:TDBBoolType];
        [t addRow:nil];
        TDBRow *row = [t lastRow];
        [row setBool:YES inColumnWithIndex:0];
        return YES;
    } error:nil];
    
    STAssertFalse([sg hasChangedSinceLastTransaction], @"SharedGroup has not been changed by another process");
    
    
    // OTHER sharedgroup
    TDBContext *sg2 = [TDBContext contextWithPersistenceToFile:@"hasChanged.tightdb" error:nil];
    
    
    [sg2 writeWithBlock:^(TDBTransaction* group) {
        TDBTable *t = [group tableWithName:@"t"];
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
        
        STAssertThrows([transaction tableWithName:nil], @"name is nil");
        STAssertThrows([transaction tableWithName:@""], @"name is empty");
        STAssertThrows([transaction createTableWithName:@"same name"], @"creating table not allowed in read transaction");
        STAssertThrows([transaction createTableWithName:@"name"], @"creating table not allowed in read transaction");
        STAssertNil([transaction tableWithName:@"weird name"], @"get table that does not exists return nil");
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
            [t1 addColumnWithName:@"col0" type:TDBBoolType];
            [t1 addRow:@[@YES]];
            //t1->add(0, 2, false, "test");
            return YES;
        } error:nil];
    }
    {   // validate that we can see previous commit from within a new pinned transaction
        BOOL changed = [context2 pinReadTransactions];
        STAssertTrue(changed, nil);
        [context2 readWithBlock:^(TDBTransaction *transaction) {
            TDBTable *t = [transaction tableWithName:@"test"];
            STAssertEquals([[t rowAtIndex:0] boolInColumnWithIndex:0], YES, nil);
        }];
    }
    {   // commit new data in another context, without unpinning
        [context1 writeWithBlock:^BOOL(TDBTransaction *transaction) {
            TDBTable *t = [transaction tableWithName:@"test"];
            [t addRow:@[@NO]];
            return YES;
        } error:nil];
        
    }
    {   // validate that we can see previous commit if we're not pinned
        [context1 readWithBlock:^(TDBTransaction *transaction) {
            TDBTable *t = [transaction tableWithName:@"test"];
            STAssertEquals([[t rowAtIndex:1] boolInColumnWithIndex:0], NO, nil);
        }];
        
    }
     {   // validate that we can NOT see previous commit from within a pinned transaction
        [context2 readWithBlock:^(TDBTransaction *transaction) {
            TDBTable *t = [transaction tableWithName:@"test"];
            STAssertEquals(t.rowCount, (NSUInteger)1, @"Still only 1 row");
        }];
        
    }
    {   // unpin, pin again and validate that we can now see previous commit
        [context2 unpinReadTransactions];
        BOOL changed = [context2 pinReadTransactions];
        STAssertTrue(changed, @"changes since last transaction");
        [context2 readWithBlock:^(TDBTransaction *transaction) {
            TDBTable *t = [transaction tableWithName:@"test"];
            STAssertEquals(t.rowCount, (NSUInteger)2, @"Now we see 2 rows");
            STAssertEquals([[t rowAtIndex:1] boolInColumnWithIndex:0], NO, nil);
        }];
    }
    {   // can't pin if already pinned
        STAssertThrows([context2 pinReadTransactions], @"Already pinned");
    }
    {   // can't unpin if already unpinned
        [context2 unpinReadTransactions];
        STAssertThrows([context2 unpinReadTransactions], @"Already unpinned");

    }
    {   // can't pin while we're inside a transaction
        [context1 readWithBlock:^(TDBTransaction *transaction) {
            STAssertThrows([context1 pinReadTransactions], @"Can't pin inside transaction");
            STAssertNotNil(transaction, @"Parameter must be used");
        }];
    }
    
    {   // can't unpin while we're inside a transaction
        [context1 pinReadTransactions];
        [context1 readWithBlock:^(TDBTransaction *transaction) {
            STAssertThrows([context1 unpinReadTransactions], @"Can't unpin inside transaction");
            STAssertNotNil(transaction, @"Parameter must be used");
        }];
        [context1 unpinReadTransactions];
    }
    {   // can't start a write transaction while pinned
        [context1 pinReadTransactions];
        STAssertThrows([context1 writeWithBlock:^BOOL(TDBTransaction *transaction) {
            STAssertNotNil(transaction, @"Parameter must be used");
            return YES;
        } error:nil], @"Can't start write transaction while pinned");
        [context1 unpinReadTransactions];
    }
}

@end



