//
//  shared_group.m
//  TightDB
//
// Demo code for short tutorial using Objective-C interface
//

#import <SenTestingKit/SenTestingKit.h>

#import <tightdb/objc/tightdb.h>
#import <tightdb/objc/group.h>
#import <tightdb/objc/group_shared.h>

TIGHTDB_TABLE_2(SharedTable2,
                Hired, Bool,
                Age,   Int)


@interface MACTestSharedGroup: SenTestCase
@end
@implementation MACTestSharedGroup

- (void)testSharedGroup
{

    // TODO: Update test to include more ASSERTS


    TDBGroup* group = [TDBGroup group];
    // Create new table in group
    SharedTable2 *table = [group getOrCreateTableWithName:@"employees" asTableClass:[SharedTable2 class] error:nil];
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
    [group writeToFile:@"employees.tightdb" withError:nil];

    // Read only shared group
    TDBSharedGroup* fromDisk = [TDBSharedGroup sharedGroupWithFile:@"employees.tightdb" withError:nil];

    [fromDisk readWithBlock:^(TDBGroup* group) {
            SharedTable2* diskTable = [group getOrCreateTableWithName:@"employees" asTableClass:[SharedTable2 class] error:nil];
            NSLog(@"Disktable size: %zu", [diskTable rowCount]);
            for (size_t i = 0; i < [diskTable rowCount]; i++) {
                SharedTable2_Cursor *cursor = [diskTable cursorAtIndex:i];
                NSLog(@"%zu: %lld", i, [cursor Age]);
                NSLog(@"%zu: %lld", i, cursor.Age);
                NSLog(@"%zu: %i", i, [diskTable boolInColumnWithIndex: 0 atRowIndex:i]);
            }
        }];


    [fromDisk writeWithBlock:^(TDBGroup* group) {
            SharedTable2* diskTable = [group getOrCreateTableWithName:@"employees" asTableClass:[SharedTable2 class] error:nil];
            NSLog(@"Disktable size: %zu", [diskTable rowCount]);
            for (size_t i = 0; i < 50; i++) {
                [diskTable addHired:YES Age:i];
            }
            return YES; // Commit
        } withError:nil];


    [fromDisk writeWithBlock:^(TDBGroup* group) {
            SharedTable2* diskTable = [group getOrCreateTableWithName:@"employees" asTableClass:[SharedTable2 class] error:nil];
            NSLog(@"Disktable size: %zu", [diskTable rowCount]);
            for (size_t i = 0; i < 50; i++) {
                [diskTable addHired:YES Age:i];
            }
            return NO; // rollback
        } withError:nil];


    [fromDisk writeWithBlock:^(TDBGroup* group) {
            SharedTable2* diskTable = [group getOrCreateTableWithName:@"employees" asTableClass:[SharedTable2 class] error:nil];
            NSLog(@"Disktable size: %zu", [diskTable rowCount]);
            for (size_t i = 0; i < 50; i++) {
                [diskTable addHired:YES Age:i];
            }
            return YES; // commit
        } withError:nil];

    [fromDisk readWithBlock:^(TDBGroup* group) {
            SharedTable2* diskTable = [group getOrCreateTableWithName:@"employees" asTableClass:[SharedTable2 class] error:nil];
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
    
    TDBSharedGroup* fromDisk = [TDBSharedGroup sharedGroupWithFile:@"readonlyTest.tightdb" withError:nil];
    
    [fromDisk writeWithBlock:^(TDBGroup *group) {
        TDBTable *t = [group getOrCreateTableWithName:@"table" error:nil];
        
        [t addColumnWithName:@"col0" andType:tightdb_Int];
        TDBRow *row = [t addEmptyRow];
        [row setInt:10 inColumnWithIndex:0 ];
         
        return YES;
        
    } withError:nil];
    
    [fromDisk readWithBlock:^(TDBGroup* group) {
        TDBTable *t = [group getOrCreateTableWithName:@"table" error:nil];
       
        TDBQuery *q = [t where];
        
        TDBView *v = [q findAllRows];
        
        // Should not be allowed!
        STAssertThrows([v removeAllRows], @"Is in readTransaction");
        
        STAssertTrue([t rowCount] == 1, @"No rows have been removed");
        STAssertTrue([q countRows] == 1, @"No rows have been removed");
        STAssertTrue([v rowCount] == 1, @"No rows have been removed");
    }];
}

@end



