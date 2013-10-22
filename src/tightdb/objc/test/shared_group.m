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
            // Outdated test: This test attempts to write to a read only table (see below). With error
            // handling "v1.0" (done by Thomas) the method calls insert methods which returns
            // NO in case of read only situation and performs a NO-OP. As a result, the clint code was
            // never informed that the operation failed unless he activly cheked the return value,
            // which is not done by this test. With error handling "v2.0" the general idea is that writing
            // to a read only table is a program error (in the client code) which must be dealt with
            // before shipping the product to the end user. Therefore we throw a read only 
            // exception from setters when they are called on read only tables. The client program
            // crashes with an informative exception in the console. If this principle still applies
            // within transaction is to be agreed. If it does, read only exceptions are categorized as
            // a result of mis-use of the API, even in transaction blocks, and the clint program should 
            // experience an exception (after the transaction is properly closed). On the other hand,
            // expected problems, such as file access should be handled using NSError objects.
            //
            // [diskTable addHired:YES Age:54];



        }];
    }
    @catch (NSException *exception) {
        NSLog(@"Exception caught: %@", exception);
    }

    // Write shared group and commit
//    TightdbSharedGroup *fromDisk = [TightdbSharedGroup groupWithFilename:@"employees.tightdb"];
    [fromDisk writeTransaction:^(TightdbGroup *group) {
        SharedTable2 *diskTable = [group getTable:@"employees" withClass:[SharedTable2 class]];
        NSLog(@"Disktable size: %zu", [diskTable count]);
        for (size_t i = 0; i < 50; i++) {
            [diskTable addHired:YES Age:i];
        }
        return YES; // Commit
    }];
    // Write shared group and rollback
//    TightdbSharedGroup *fromDisk = [TightdbSharedGroup groupWithFilename:@"employees.tightdb"];
    [fromDisk writeTransaction:^(TightdbGroup *group) {
        SharedTable2 *diskTable = [group getTable:@"employees" withClass:[SharedTable2 class]];
        NSLog(@"Disktable size: %zu", [diskTable count]);
        for (size_t i = 0; i < 50; i++) {
            [diskTable addHired:YES Age:i];
        }
        return NO; // rollback
    }];
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
        }];
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



