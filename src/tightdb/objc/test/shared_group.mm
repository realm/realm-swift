//
//  shared_group.mm
//  TightDB
//
// Demo code for short tutorial using Objective-C interface
//

#import <SenTestingKit/SenTestingKit.h>

#import "TestHelper.h"

#import <tightdb/objc/tightdb.h>
#import <tightdb/objc/group.h>
#import <tightdb/objc/group_shared.h>
#include <tightdb/table.hpp>
#import <tightdb/objc/table_priv.h>

TIGHTDB_TABLE_DEF_2(SharedTable2,
                    Hired, Bool,
                    Age,   Int)

TIGHTDB_TABLE_IMPL_2(SharedTable2,
                     Hired, Bool,
                     Age,   Int)


@interface MACTestSharedGroup: SenTestCase
@end
@implementation MACTestSharedGroup

- (void)testSharedGroup
{
    @autoreleasepool {
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
        [fromDisk readTransaction:^(TightdbGroup *group) {
            SharedTable2 *diskTable = [group getTable:@"employees" withClass:[SharedTable2 class]];
            STAssertEquals(size_t(4), [diskTable count], @"There should be 4 rows");
            for (size_t i = 0; i < [diskTable count]; i++) {
                SharedTable2_Cursor *cursor = [diskTable objectAtIndex:i];
                NSLog(@"%zu: %lld", i, [cursor Age]);
                NSLog(@"%zu: %lld", i, cursor.Age);
                NSLog(@"%zu: %i", i, [diskTable getBool:0 ndx:i]);
            }
            [diskTable addHired:YES Age:54];
        }];
        
        // Write shared group and commit
        //    TightdbSharedGroup *fromDisk = [TightdbSharedGroup groupWithFilename:@"employees.tightdb"];
        [fromDisk writeTransaction:^(TightdbGroup *group) {
            SharedTable2 *diskTable = [group getTable:@"employees" withClass:[SharedTable2 class]];
            STAssertEquals(size_t(4), [diskTable count], @"There should be 4 rows");
            for (size_t i = 0; i < 50; i++) {
                [diskTable addHired:YES Age:i];
            }
            return YES; // Commit
        } error:nil];
        // Write shared group and rollback
        //    TightdbSharedGroup *fromDisk = [TightdbSharedGroup groupWithFilename:@"employees.tightdb"];
        [fromDisk writeTransaction:^(TightdbGroup *group) {
            SharedTable2 *diskTable = [group getTable:@"employees" withClass:[SharedTable2 class]];
            STAssertEquals(size_t(54), [diskTable count], @"There should be 54 rows");
            for (size_t i = 0; i < 50; i++) {
                [diskTable addHired:YES Age:i];
            }
            return NO; // rollback
        }];
        // Write and fail with exception in block (Should rollback) - Note: Cannot simulate exception, so doing readonly instead
        //    TightdbSharedGroup *fromDisk = [TightdbSharedGroup groupWithFilename:@"employees.tightdb"];
        __block int addCount = 0;
        [fromDisk writeTransaction:^(TightdbGroup *group) {
            SharedTable2 *diskTable = [group getTable:@"employees" withClass:[SharedTable2 class]];
            // Fake readonly.
            NSLog(@"Fake readonly - should trigger an error");
            [((TightdbTable *)diskTable) setReadOnly:true];
            STAssertEquals(size_t(54), [diskTable count], @"There should be 54 rows");
            for (size_t i = 0; i < 50; i++) {
                if ([diskTable addHired:YES Age:i])
                    ++addCount;
            }
            return YES; // commit
        }];
        STAssertEquals(0, addCount, @"No rows should be added");
        
        [fromDisk readTransaction:^(TightdbGroup *group) {
            SharedTable2 *diskTable = [group getTable:@"employees" withClass:[SharedTable2 class]];
            STAssertEquals(size_t(54), [diskTable count], @"There should be 54 rows");
        }];
    }
    TEST_CHECK_ALLOC;
}


@end



