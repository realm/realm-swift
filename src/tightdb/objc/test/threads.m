//
//  threads.m
//  TightDb
//

#import <SenTestingKit/SenTestingKit.h>
#import "TestHelper.h"

#import <tightdb/objc/tightdb.h>
#import <tightdb/objc/group.h>


TIGHTDB_TABLE_2(TestThreadTableGroup,
                First,  String,
                Second, Int)

TIGHTDB_TABLE_3(EnumPeopleThreadTable,
                Name,  String,
                Age,   Int,
                Hired, Bool)

TIGHTDB_TABLE_2(EnumPeopleThreadTable2,
                Hired, Bool,
                Age,   Int)

TIGHTDB_TABLE_DEF_3(PeopleTable,
                    Name,  String,
                    Age,   Int,
                    Hired, Bool)

@interface MacTightDbTestsThreads: SenTestCase
@end
@implementation MacTightDbTestsThreads

- (void)setUp
{
    [super setUp];
    
    // Set-up code here.
}

- (void)tearDown
{
    // Tear-down code here.
    
    [super tearDown];
    
    // Workaround for problem when executing test in xcode. Remove if do not care. :)
    sleep(1);   // Workaround for bug in xcode - sometimes it says test did not finish even though it did. This should be a possible workaround. Unfortunately it slows the execution down.
}

- (void)testThreads
{
    int runCount = 10;
    while(--runCount>0) {
        dispatch_semaphore_t sema = dispatch_semaphore_create(0);
        __block int doneCount = 0;
        int actualThreads = 0;
        
        ++actualThreads;
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            @autoreleasepool {
                TightdbGroup *fromDisk = [TightdbGroup groupWithFilename:@"employees.tightdb"];
                PeopleTable *diskTable = [fromDisk getTable:@"employees" withClass:[PeopleTable class]];
                
                [diskTable addName:@"Thread1" Age:1 Hired:YES];
                
                NSLog(@"Disktable size: %zu", [diskTable count]);
                
                for (size_t i = 0; i < [diskTable count]; i++) {
                    PeopleTable_Cursor *cursor = [diskTable objectAtIndex:i];
                    NSLog(@"%zu: %@", i, [cursor Name]);
                }
            }
            ++doneCount;
            dispatch_semaphore_signal(sema);
        });
        ++actualThreads;
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            @autoreleasepool {
                TightdbGroup *fromDisk = [TightdbGroup groupWithFilename:@"employees.tightdb"];
                PeopleTable *diskTable = [fromDisk getTable:@"employees" withClass:[PeopleTable class]];
                
                [diskTable addName:@"Thread2" Age:2 Hired:YES];
                
                NSLog(@"Disktable size: %zu", [diskTable count]);
                
                for (size_t i = 0; i < [diskTable count]; i++) {
                    PeopleTable_Cursor *cursor = [diskTable objectAtIndex:i];
                    NSLog(@"%zu: %@", i, [cursor Name]);
                }
            }
            ++doneCount;
            dispatch_semaphore_signal(sema);
        });
        ++actualThreads;
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            @autoreleasepool {
                NSFileManager *fm = [NSFileManager defaultManager];
                
                // Create empty group and serialize to disk
                TightdbGroup *toDisk = [TightdbGroup group];
                [fm removeItemAtPath:@"table_test.tightdb" error:NULL];
                [toDisk write:@"table_test.tightdb"];
                
                // Load the group
                TightdbGroup *fromDisk = [TightdbGroup groupWithFilename:@"table_test.tightdb"];
                if (!fromDisk)
                    STFail(@"From disk not valid");
                
                // Create new table in group
                TestThreadTableGroup *t = (TestThreadTableGroup *)[fromDisk getTable:@"test" withClass:[TestThreadTableGroup class]];
                
                // Verify
                NSLog(@"Columns: %zu", [t getColumnCount]);
                if ([t getColumnCount] != 2)
                    STFail(@"Should have been 2 columns");
                if ([t count] != 0)
                    STFail(@"Should have been empty");
                
                // Modify table
                [t addFirst:@"Test" Second:YES];
                NSLog(@"Size: %lu", [t count]);
                
                // Verify
                if ([t count] != 1)
                    STFail(@"Should have been one row");
                
                t = nil;
            }
            ++doneCount;
            dispatch_semaphore_signal(sema);
        });
        ++actualThreads;
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            @autoreleasepool {
                TightdbGroup *group = [TightdbGroup group];
                TightdbTable *table = [group getTable:@"table" withClass:[TightdbTable class]];
                
                // Specify the table schema
                {
                    TightdbSpec *s = [table getSpec];
                    [s addColumn:tightdb_Int name:@"int"];
                    {
                        TightdbSpec *sub = [s addColumnTable:@"tab"];
                        [sub addColumn:tightdb_Int name:@"int"];
                    }
                    [s addColumn:tightdb_Mixed name:@"mix"];
                    [table updateFromSpec];
                }
                
                int COL_TABLE_INT = 0;
                int COL_TABLE_TAB = 1;
                int COL_TABLE_MIX = 2;
                int COL_SUBTABLE_INT = 0;
                
                // Add a row to the top level table
                [table addRow];
                [table set:COL_TABLE_INT ndx:0 value:700];
                
                // Add two rows to the subtable
                TightdbTable *subtable = [table getSubtable:COL_TABLE_TAB ndx:0];
                [subtable addRow];
                [subtable set:COL_SUBTABLE_INT ndx:0 value:800];
                [subtable addRow];
                [subtable set:COL_SUBTABLE_INT ndx:1 value:801];
                
                // Make the mixed values column contain another subtable
                [table setMixed:COL_TABLE_MIX ndx:0 value: [TightdbMixed mixedWithTable:nil]];
            }
            ++doneCount;
            dispatch_semaphore_signal(sema);
        });
        ++actualThreads;
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            @autoreleasepool {
                //------------------------------------------------------
                NSLog(@"--- Creating tables ---");
                //------------------------------------------------------
                TightdbGroup *group = [TightdbGroup group];
                // Create new table in group
                EnumPeopleThreadTable *people = [group getTable:@"employees" withClass:[EnumPeopleThreadTable class]];
                
                // Add some rows
                [people addName:@"John" Age:20 Hired:YES];
                [people addName:@"Mary" Age:21 Hired:NO];
                [people addName:@"Lars" Age:21 Hired:YES];
                [people addName:@"Phil" Age:43 Hired:NO];
                [people addName:@"Anni" Age:54 Hired:YES];
                
                //------------------------------------------------------
                NSLog(@"--- Iterators ---");
                //------------------------------------------------------
                
                // 1: Iterate over table
                for (EnumPeopleThreadTable_Cursor *row in people) {
                    NSLog(@"(Enum)%@ is %lld years old.", row.Name, row.Age);
                }
                
                // Do a query, and get all matches as TableView
                EnumPeopleThreadTable_View *res = [[[[people where].Hired equal:YES].Age between:20 to:30] findAll];
                NSLog(@"View count: %zu", [res count]);
                // 2: Iterate over the resulting TableView
                for (EnumPeopleThreadTable_Cursor *row in res) {
                    NSLog(@"(Enum2) %@ is %lld years old.", row.Name, row.Age);
                }
                
                // 3: Iterate over query (lazy)
                
                EnumPeopleThreadTable_Query *q = [[people where].Age equal:21];
                NSLog(@"Query lazy count: %zu", [[q count] unsignedLongValue] );
                for (EnumPeopleThreadTable_Cursor *row in q) {
                    NSLog(@"(Enum3) %@ is %lld years old.", row.Name, row.Age);
                    if (row.Name == nil)
                        break;
                }
            }
            ++doneCount;
            dispatch_semaphore_signal(sema);
        });
        NSLog(@"Wait for background tasks...");
        while(doneCount<actualThreads) {
            dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
            NSLog(@"A task finished...");
        }
        NSLog(@"All done...%d=%d", doneCount, actualThreads);
    }
    TEST_CHECK_ALLOC;
}

@end
