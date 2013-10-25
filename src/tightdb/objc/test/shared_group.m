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

/*TIGHTDB_TABLE_DEF_2(SharedTable2,
                    Hired, Bool,
                    Age,   Int)

TIGHTDB_TABLE_IMPL_2(SharedTable2,
                     Hired, Bool,
                     Age,   Int)*/

TIGHTDB_TABLE_2(SharedTable2,
                Hired, Bool,
                Age,   Int)


@interface MACTestSharedGroup: SenTestCase
@end
@implementation MACTestSharedGroup

- (void)testSharedGroup
{
    TightdbGroup *group = [TightdbGroup group];
    // Create new table in group
    SharedTable2 *table = [group getTable:@"employees" withClass:[SharedTable2 class]];
    NSLog(@"Table: %@", table);
    // Add some rows
    [table addHired:YES Age:50];
    [table addHired:YES Age:52];
    [table addHired:YES Age:53];
    [table addHired:YES Age:54];

    NSLog(@"MyTable Size: %lu", [table count]);


    NSFileManager *fm = [NSFileManager defaultManager];

    // Write to disk
    [fm removeItemAtPath:@"employees.tightdb" error:NULL];
    [group write:@"employees.tightdb"];

    // Read only shared group
    TightdbSharedGroup *fromDisk = [TightdbSharedGroup groupWithFilename:@"employees.tightdb"];
    @try {
        [fromDisk readTransaction:^(TightdbGroup *group) {
            SharedTable2 *diskTable = [group getTable:@"employees" withClass:[SharedTable2 class]];
            NSLog(@"Disktable size: %zu", [diskTable count]);
            for (size_t i = 0; i < [diskTable count]; i++) {
                SharedTable2_Cursor *cursor = [diskTable cursorAtIndex:i];
                NSLog(@"%zu: %lld", i, [cursor Age]);
                NSLog(@"%zu: %lld", i, cursor.Age);
                NSLog(@"%zu: %i", i, [diskTable getBoolInColumn:0 atRow:i]);
            }

            NSLog(@"BOOL = %@\n", ([diskTable isReadOnly] ? @"YES" : @"NO"));
            [diskTable addHired:YES Age:54];


            [diskTable addRow];
            NSLog(@"Disktable size now: %zu", [diskTable count]);
        }];
    }
    @catch (NSException *exception) {
        NSLog(@"Exception caught 1: %@", exception);
    }

    // Write shared group and commit
    ///TightdbSharedGroup *fromDisk = [TightdbSharedGroup groupWithFilename:@"employees.tightdb"];

    NSError* error = nil;
    [fromDisk writeTransaction:^(TightdbGroup *group) {
        SharedTable2 *diskTable = [group getTable:@"employees" withClass:[SharedTable2 class]];
        NSLog(@"Disktable size: %zu", [diskTable count]);
        for (size_t i = 0; i < 50; i++) {
            [diskTable addHired:YES Age:i];
        }
        return YES; // Commit
    
    } withError:&error];
    
    // Write shared group and rollback
//    TightdbSharedGroup *fromDisk = [TightdbSharedGroup groupWithFilename:@"employees.tightdb"];
    [fromDisk writeTransaction:^(TightdbGroup *group) {
        SharedTable2 *diskTable = [group getTable:@"employees" withClass:[SharedTable2 class]];
        NSLog(@"Disktable size: %zu", [diskTable count]);
        for (size_t i = 0; i < 50; i++) {
            [diskTable addHired:YES Age:i];
        }
        return NO; // rollback
        
    } withError:&error];
    
    // Write and fail with exception in block (Should rollback)
//    TightdbSharedGroup *fromDisk = [TightdbSharedGroup groupWithFilename:@"employees.tightdb"];
    @try {
        [fromDisk writeTransaction:^(TightdbGroup *group) {
            SharedTable2 *diskTable = [group getTable:@"employees" withClass:[SharedTable2 class]];
            NSLog(@"Disktable size: %zu", [diskTable count]);
            for (size_t i = 0; i < 50; i++) {
                [diskTable addHired:YES Age:i];
            }
            [NSException raise:@"Test exception" format:@"Program went ballistic"];
            return YES; // commit
        } withError:&error];
    }
    @catch (NSException *exception) {
        NSLog(@"Exception caught: %@", exception);
    }
    
    
    [fromDisk readTransaction:^(TightdbGroup *group) {
        SharedTable2 *diskTable = [group getTable:@"employees" withClass:[SharedTable2 class]];
        NSLog(@"Disktable size: %zu", [diskTable count]);
    }];

}


@end



