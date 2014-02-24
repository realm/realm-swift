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


    TightdbGroup* group = [TightdbGroup group];
    // Create new table in group
    SharedTable2 *table = [group getTable:@"employees" withClass:[SharedTable2 class] error:nil];
    NSLog(@"Table: %@", table);
    // Add some rows
    [table addHired:YES Age:50];
    [table addHired:YES Age:52];
    [table addHired:YES Age:53];
    [table addHired:YES Age:54];

    NSLog(@"MyTable Size: %lu", [table count]);


    NSFileManager* fm = [NSFileManager defaultManager];

    // Write to disk
    [fm removeItemAtPath:@"employees.tightdb" error:nil];
    [fm removeItemAtPath:@"employees.tightdb.lock" error:nil];
    [group writeToFile:@"employees.tightdb" withError:nil];

    // Read only shared group
    TightdbSharedGroup* fromDisk = [TightdbSharedGroup sharedGroupWithFilename:@"employees.tightdb" withError:nil];

    [fromDisk readTransactionWithBlock:^(TightdbGroup* group) {
            SharedTable2* diskTable = [group getTable:@"employees" withClass:[SharedTable2 class] error:nil];
            NSLog(@"Disktable size: %zu", [diskTable count]);
            for (size_t i = 0; i < [diskTable count]; i++) {
                SharedTable2_Cursor *cursor = [diskTable cursorAtIndex:i];
                NSLog(@"%zu: %lld", i, [cursor Age]);
                NSLog(@"%zu: %lld", i, cursor.Age);
                NSLog(@"%zu: %i", i, [diskTable getBoolInColumn:0 atRow:i]);
            }
        }];


    [fromDisk writeTransactionWithError:nil withBlock:^(TightdbGroup* group) {
            SharedTable2* diskTable = [group getTable:@"employees" withClass:[SharedTable2 class] error:nil];
            NSLog(@"Disktable size: %zu", [diskTable count]);
            for (size_t i = 0; i < 50; i++) {
                [diskTable addHired:YES Age:i];
            }
            return YES; // Commit
        }];


    [fromDisk writeTransactionWithError:nil withBlock:^(TightdbGroup* group) {
            SharedTable2* diskTable = [group getTable:@"employees" withClass:[SharedTable2 class] error:nil];
            NSLog(@"Disktable size: %zu", [diskTable count]);
            for (size_t i = 0; i < 50; i++) {
                [diskTable addHired:YES Age:i];
            }
            return NO; // rollback
        }];


    [fromDisk writeTransactionWithError:nil withBlock:^(TightdbGroup* group) {
            SharedTable2* diskTable = [group getTable:@"employees" withClass:[SharedTable2 class] error:nil];
            NSLog(@"Disktable size: %zu", [diskTable count]);
            for (size_t i = 0; i < 50; i++) {
                [diskTable addHired:YES Age:i];
            }
            return YES; // commit
        }];

    [fromDisk readTransactionWithBlock:^(TightdbGroup* group) {
            SharedTable2* diskTable = [group getTable:@"employees" withClass:[SharedTable2 class] error:nil];
            NSLog(@"Disktable size: %zu", [diskTable count]);
        }];
}

@end



