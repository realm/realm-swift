//
//  shared_group.m
//  TightDB
//
// Demo code for short tutorial using Objective-C interface
//

#import <SenTestingKit/SenTestingKit.h>

#import <tightdb/objc/tightdb.h>
#import <tightdb/objc/transaction.h>
#import <tightdb/objc/group.h>
#import <tightdb/objc/context.h>

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
    SharedTable2 *table = [group getOrCreateTableWithName:@"employees" asTableClass:[SharedTable2 class]];
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
    [group writeContextToFile:@"employees.tightdb" withError:nil];

    // Read only shared group
    TDBContext* fromDisk = [TDBContext initWithFile:@"employees.tightdb" withError:nil];

    [fromDisk readWithBlock:^(TDBTransaction* group) {
            SharedTable2* diskTable = [group getOrCreateTableWithName:@"employees" asTableClass:[SharedTable2 class]];
            NSLog(@"Disktable size: %zu", [diskTable rowCount]);
            for (size_t i = 0; i < [diskTable rowCount]; i++) {
                SharedTable2_Row *cursor = [diskTable rowAtIndex:i];
                NSLog(@"%zu: %lld", i, [cursor Age]);
                NSLog(@"%zu: %lld", i, cursor.Age);
                NSLog(@"%zu: %i", i, [diskTable boolInColumnWithIndex: 0 atRowIndex:i]);
            }
        }];


    [fromDisk writeWithBlock:^(TDBTransaction* group) {
            SharedTable2* diskTable = [group getOrCreateTableWithName:@"employees" asTableClass:[SharedTable2 class]];
            NSLog(@"Disktable size: %zu", [diskTable rowCount]);
            for (size_t i = 0; i < 50; i++) {
                [diskTable addHired:YES Age:i];
            }
            return YES; // Commit
        } withError:nil];


    [fromDisk writeWithBlock:^(TDBTransaction* group) {
            SharedTable2* diskTable = [group getOrCreateTableWithName:@"employees" asTableClass:[SharedTable2 class]];
            NSLog(@"Disktable size: %zu", [diskTable rowCount]);
            for (size_t i = 0; i < 50; i++) {
                [diskTable addHired:YES Age:i];
            }
            return NO; // rollback
        } withError:nil];


    [fromDisk writeWithBlock:^(TDBTransaction* group) {
            SharedTable2* diskTable = [group getOrCreateTableWithName:@"employees" asTableClass:[SharedTable2 class]];
            NSLog(@"Disktable size: %zu", [diskTable rowCount]);
            for (size_t i = 0; i < 50; i++) {
                [diskTable addHired:YES Age:i];
            }
        
            STAssertNil([group getTableWithName:@"Does not exist"], @"Table does not exist");

            return YES; // commit
        } withError:nil];

    [fromDisk readWithBlock:^(TDBTransaction* group) {
            SharedTable2* diskTable = [group getOrCreateTableWithName:@"employees" asTableClass:[SharedTable2 class]];
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
    
    TDBContext* fromDisk = [TDBContext initWithFile:@"readonlyTest.tightdb" withError:nil];
    
    [fromDisk writeWithBlock:^(TDBTransaction *group) {
        TDBTable *t = [group getOrCreateTableWithName:@"table"];
        
        [t addColumnWithName:@"col0" andType:TDBIntType];
        TDBRow *row = [t addEmptyRow];
        [row setInt:10 inColumnWithIndex:0 ];
         
        return YES;
        
    } withError:nil];
    
    [fromDisk readWithBlock:^(TDBTransaction* group) {
        TDBTable *t = [group getOrCreateTableWithName:@"table"];
       
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
    
    TDBContext *sg = [TDBContext initWithFile:@"hasChanged.tightdb" withError:nil];
    
    STAssertFalse([sg hasChangedSinceLastTransaction], @"SharedGroup has not changed");
    
    [sg writeWithBlock:^(TDBTransaction* group) {
        [group getOrCreateTableWithName:@"t"];
        return YES;
    } withError:nil];
    
    STAssertFalse([sg hasChangedSinceLastTransaction], @"SharedGroup has not been changed by another process");

    
    [sg writeWithBlock:^(TDBTransaction* group) {
        TDBTable *t = [group getOrCreateTableWithName:@"t"];
        [t addColumnWithName:@"col" andType:TDBBoolType];
        TDBRow *row = [t addEmptyRow];
        [row setBool:YES inColumnWithIndex:0];
        return YES;
    } withError:nil];
    
    STAssertFalse([sg hasChangedSinceLastTransaction], @"SharedGroup has not been changed by another process");
    
    
    // OTHER sharedgroup
    TDBContext *sg2 = [TDBContext initWithFile:@"hasChanged.tightdb" withError:nil];
    
    
    [sg2 writeWithBlock:^(TDBTransaction* group) {
        TDBTable *t = [group getOrCreateTableWithName:@"t"];
        [t addEmptyRow]; /* Adding a row */
        return YES;
    } withError:nil];

    STAssertTrue([sg hasChangedSinceLastTransaction], @"SharedGroup HAS been changed by another process");


}

@end



