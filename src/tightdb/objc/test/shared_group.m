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

TIGHTDB_TABLE_DEF_2(SharedTable2,
                    Bool,   Hired,
                    Int,    Age)


TIGHTDB_TABLE_IMPL_2(SharedTable2,
                     Bool,   Hired,
                     Int,    Age)


@interface MACTestSharedGroup : SenTestCase
@end
@implementation MACTestSharedGroup

- (void)testSharedGroup
{
    Group *group = [Group group];
    // Create new table in group
    SharedTable2 *table = [group getTable:@"employees" withClass:[SharedTable2 class]];
    NSLog(@"Table: %@", table);
    // Add some rows
    [table addHired:YES Age:50];
    [table addHired:YES Age:52];
    [table addHired:YES Age:53];
    [table addHired:YES Age:54];
    
    NSLog(@"MyTable Size: %lu", [table count]);
    
    
    // Write to disk
    [group write:@"employees.tightdb"];
    
    // Read only shared group
    SharedGroup *fromDisk = [SharedGroup groupWithFilename:@"employees.tightdb"];
    @try {
        [fromDisk readTransaction:^(Group *group) {
            SharedTable2 *diskTable = [group getTable:@"employees" withClass:[SharedTable2 class]];
            NSLog(@"Disktable size: %zu", [diskTable count]);
            for (size_t i = 0; i < [diskTable count]; i++) {
                SharedTable2_Cursor *cursor = [diskTable objectAtIndex:i];
                NSLog(@"%zu: %lld", i, [cursor Age]);
                NSLog(@"%zu: %lld", i, cursor.Age);
                NSLog(@"%zu: %i", i, [diskTable getBool:0 ndx:i]);
            }
            [diskTable addHired:YES Age:54];
        }];
    }
    @catch (NSException *exception) {
        NSLog(@"Exception caught: %@", exception);
    }

    // Write shared group and commit
//    SharedGroup *fromDisk = [SharedGroup groupWithFilename:@"employees.tightdb"];
    [fromDisk writeTransaction:^(Group *group) {
        SharedTable2 *diskTable = [group getTable:@"employees" withClass:[SharedTable2 class]];
        NSLog(@"Disktable size: %zu", [diskTable count]);
        for (size_t i = 0; i < 50; i++) {
            [diskTable addHired:YES Age:i];
        }
        return YES; // Commit
    }];
    // Write shared group and rollback
//    SharedGroup *fromDisk = [SharedGroup groupWithFilename:@"employees.tightdb"];
    [fromDisk writeTransaction:^(Group *group) {
        SharedTable2 *diskTable = [group getTable:@"employees" withClass:[SharedTable2 class]];
        NSLog(@"Disktable size: %zu", [diskTable count]);
        for (size_t i = 0; i < 50; i++) {
            [diskTable addHired:YES Age:i];
        }
        return NO; // rollback
    }];
    // Write and fail with exception in block (Should rollback)
//    SharedGroup *fromDisk = [SharedGroup groupWithFilename:@"employees.tightdb"];
    @try {
        [fromDisk writeTransaction:^(Group *group) {
            SharedTable2 *diskTable = [group getTable:@"employees" withClass:[SharedTable2 class]];
            NSLog(@"Disktable size: %zu", [diskTable count]);
            for (size_t i = 0; i < 50; i++) {
                [diskTable addHired:YES Age:i];
            }
            [NSException raise:@"Test exception" format:@"Program went ballistic"];
            return YES; // commit
        }];
    }
    @catch (NSException *exception) {
        NSLog(@"Exception caught: %@", exception);
    }
    
    
    [fromDisk readTransaction:^(Group *group) {
        SharedTable2 *diskTable = [group getTable:@"employees" withClass:[SharedTable2 class]];
        NSLog(@"Disktable size: %zu", [diskTable count]);
    }];

}


@end



