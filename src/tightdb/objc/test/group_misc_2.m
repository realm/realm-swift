//
//  group_misc_2.m
//  TightDB
//
// Demo code for short tutorial using Objective-C interface
//

#import <SenTestingKit/SenTestingKit.h>

#import <tightdb/objc/tightdb.h>
#import <tightdb/objc/group.h>

TIGHTDB_TABLE_DEF_4(MyTable,
                    Name,  String,
                    Age,   Int,
                    Hired, Bool,
                    Spare, Int)

TIGHTDB_TABLE_DEF_2(MyTable2,
                    Hired, Bool,
                    Age,   Int)

TIGHTDB_TABLE_IMPL_4(MyTable,
                     Name,  String,
                     Age,   Int,
                     Hired, Bool,
                     Spare, Int)

TIGHTDB_TABLE_IMPL_2(MyTable2,
                     Hired, Bool,
                     Age,   Int)

TIGHTDB_TABLE_2(QueryTable,
                First,  Int,
                Second, String)

@interface MACTestGroupMisc2: SenTestCase
@end
@implementation MACTestGroupMisc2

- (void)testGroup_Misc2
{
    size_t row;
    TightdbGroup* group = [TightdbGroup group];
    NSLog(@"HasTable: %i", [group hasTableWithName:@"employees" withTableClass:[MyTable class]] );
    // Create new table in group
    MyTable* table = [group getOrCreateTableWithName:@"employees" asTableClass:[MyTable class] error:nil];
    NSLog(@"Table: %@", table);
    NSLog(@"HasTable: %i", [group hasTableWithName:@"employees" withTableClass:[MyTable class]] );

    // Add some rows
    [table addName:@"John" Age:20 Hired:YES Spare:0];
    [table addName:@"Mary" Age:21 Hired:NO Spare:0];
    [table addName:@"Lars" Age:21 Hired:YES Spare:0];
    [table addName:@"Phil" Age:43 Hired:NO Spare:0];
    [table addName:@"Anni" Age:54 Hired:YES Spare:0];

    NSLog(@"MyTable Size: %lu", table.rowCount);

    //------------------------------------------------------

    row = [table.Name find:@"Philip"];    // row = (size_t)-1
    NSLog(@"Philip: %zu", row);
    STAssertEquals(row, (size_t)-1,@"Philip should not be there");
    row = [table.Name find:@"Mary"];
    NSLog(@"Mary: %zu", row);
    STAssertEquals(row, (size_t)1,@"Mary should have been there");

    MyTable_View *view = [[[table where].Age columnIsEqualTo:21] findAll];
    size_t cnt = view.rowCount;            // cnt = 2
    STAssertEquals(cnt, (size_t)2,@"Should be two rows in view");

    //------------------------------------------------------

    MyTable2* table2 = [[MyTable2 alloc] init];

    // Add some rows
    [table2 addHired:YES Age:20];
    [table2 addHired:NO Age:21];
    [table2 addHired:YES Age:22];
    [table2 addHired:NO Age:43];
    [table2 addHired:YES Age:54];

    // Create query (current employees between 20 and 30 years old)
    MyTable2_Query* q = [[[table2 where].Hired columnIsEqualTo:YES].Age columnIsBetween:20 and_:30];

    // Get number of matching entries
    NSLog(@"Query count: %zu", [q countRows]);
    STAssertEquals([q countRows], (size_t)2,@"Expected 2 rows in query");

     // Get the average age - currently only a low-level interface!
    double avg = [q.Age average];
    NSLog(@"Average: %f", avg);
    STAssertEquals(avg, 21.0,@"Expected 20.5 average");

    // Execute the query and return a table (view)
    TightdbView* res = [q findAll];
    for (size_t i = 0; i < [res rowCount]; i++) {
        // cursor missing. Only low-level interface!
        NSLog(@"%zu: is %lld years old",i , [res intInColumnWithIndex:1 atRowIndex:i]);
    }

    //------------------------------------------------------

    NSFileManager* fm = [NSFileManager defaultManager];

    // Write to disk
    [fm removeItemAtPath:@"employees.tightdb" error:nil];
    [group writeToFile:@"employees.tightdb" withError:nil];

    // Load a group from disk (and print contents)
    TightdbGroup* fromDisk = [TightdbGroup groupWithFile:@"employees.tightdb" withError:nil];
    MyTable* diskTable = [fromDisk getOrCreateTableWithName:@"employees" asTableClass:[MyTable class] error:nil];

    [diskTable addName:@"Anni" Age:54 Hired:YES Spare:0];
//    [diskTable insertAtIndex:2 Name:@"Thomas" Age:41 Hired:NO Spare:1];
    NSLog(@"Disktable size: %zu", diskTable.rowCount);
    for (size_t i = 0; i < diskTable.rowCount; i++) {
        MyTable_Cursor* cursor = [diskTable cursorAtIndex:i];
        NSLog(@"%zu: %@", i, [cursor Name]);
        NSLog(@"%zu: %@", i, cursor.Name);
        NSLog(@"%zu: %@", i, [diskTable stringInColumnWithIndex:0 atRowIndex:i]);
    }

    // Write same group to memory buffer
    TightdbBinary* buffer = [group writeToBuffer];

    // Load a group from memory (and print contents)
    TightdbGroup* fromMem = [TightdbGroup groupWithBuffer:buffer withError:nil];
    MyTable* memTable = [fromMem getOrCreateTableWithName:@"employees" asTableClass:[MyTable class] error:nil];
    for (size_t i = 0; i < [memTable rowCount]; i++) {
        // ??? cursor
        NSLog(@"%zu: %@", i, memTable.Name);
    }
}


- (void)testQuery
{
    TightdbGroup* group = [TightdbGroup group];
    QueryTable* table = [group getOrCreateTableWithName:@"Query table" asTableClass:[QueryTable class] error:nil];

    // Add some rows
    [table addFirst:2 Second:@"a"];
    [table addFirst:4 Second:@"a"];
    [table addFirst:5 Second:@"b"];
    [table addFirst:8 Second:@"The quick brown fox"];

    {
        QueryTable_Query* q = [[table where].First columnIsBetween:3 and_:7]; // Between
        STAssertEquals((size_t)2,   [q countRows], @"count != 2");
//        STAssertEquals(9,   [q.First sum]); // Sum
        STAssertEquals(4.5, [q.First average], @"Avg!=4.5"); // Average
//        STAssertEquals(4,   [q.First min]); // Minimum
//        STAssertEquals(5,   [q.First max]); // Maximum
    }
    {
        QueryTable_Query* q = [[table where].Second columnContains:@"quick" caseSensitive:NO]; // String contains
        STAssertEquals((size_t)1, [q countRows], @"count != 1");
    }
    {
        QueryTable_Query* q = [[table where].Second columnBeginsWith:@"The" caseSensitive:NO]; // String prefix
        STAssertEquals((size_t)1, [q countRows], @"count != 1");
    }
    {
        QueryTable_Query* q = [[table where].Second columnEndsWith:@"The" caseSensitive:NO]; // String suffix
        STAssertEquals((size_t)0, [q countRows], @"count != 1");
    }
    {
        QueryTable_Query* q = [[[table where].Second columnIsNotEqualTo:@"a" caseSensitive:NO].Second columnIsNotEqualTo:@"b" caseSensitive:NO]; // And
        STAssertEquals((size_t)1, [q countRows], @"count != 1");
    }
    {
        QueryTable_Query* q = [[[[table where].Second columnIsNotEqualTo:@"a" caseSensitive:NO] Or].Second columnIsNotEqualTo:@"b" caseSensitive:NO]; // Or
        STAssertEquals((size_t)4, [q countRows], @"count != 1");
    }
    {
        QueryTable_Query* q = [[[[[[[table where].Second columnIsEqualTo:@"a" caseSensitive:NO] group].First columnIsLessThan:3] Or].First columnIsGreaterThan:5] endGroup]; // Parentheses
        STAssertEquals((size_t)1, [q countRows], @"count != 1");
    }
    {
        QueryTable_Query* q = [[[[[table where].Second columnIsEqualTo:@"a" caseSensitive:NO].First columnIsLessThan:3] Or].First columnIsGreaterThan:5]; // No parenthesis
        STAssertEquals((size_t)2, [q countRows], @"count != 2");
        TightdbView* tv = [q findAll];
        STAssertEquals((size_t)2, [tv rowCount], @"count != 2");
        STAssertEquals((int64_t)8, [tv intInColumnWithIndex:0 atRowIndex:1], @"First != 8");
    }
}

/*
 * Tables can contain other tables, however this is not yet supported
 * by the high level API. The following illustrates how to do it
 * through the low level API.
 */
- (void)testSubtables
{
    TightdbGroup* group = [TightdbGroup group];
    TightdbTable* table = [group getOrCreateTableWithName:@"table" asTableClass:[TightdbTable class] error:nil];

    // Specify the table type
    {
        TightdbDescriptor* desc = table.descriptor;
        [desc addColumnWithType:tightdb_Int andName:@"int"];
        {
            TightdbDescriptor* subdesc = [desc addColumnTable:@"tab"];
            [subdesc addColumnWithType:tightdb_Int andName:@"int"];
        }
        [desc addColumnWithType:tightdb_Mixed andName:@"mix"];
    }

    int COL_TABLE_INT = 0;
    int COL_TABLE_TAB = 1;
    int COL_TABLE_MIX = 2;
    int COL_SUBTABLE_INT = 0;

    // Add a row to the top level table
    [table addEmptyRow];
    [table setInt:700 inColumnWithIndex:COL_TABLE_INT atRowIndex:0];

    // Add two rows to the subtable
    TightdbTable* subtable = [table tableInColumnWithIndex:COL_TABLE_TAB atRowIndex:0];
    [subtable addEmptyRow];

    [subtable setInt:800 inColumnWithIndex:COL_SUBTABLE_INT atRowIndex:0];
    [subtable addEmptyRow];
    [subtable setInt:801 inColumnWithIndex:COL_SUBTABLE_INT atRowIndex:1];

    // Make the mixed values column contain another subtable
    [table setMixed:[TightdbMixed mixedWithTable:nil] inColumnWithIndex:COL_TABLE_MIX atRowIndex:0];

/* Fails!!!
    // Specify its type
    OCTopLevelTable* subtable2 = [table getTopLevelTable:COL_TABLE_MIX ndx:0];
    {
        TightdbDescriptor* desc = [subtable2 getDescriptor];
        [desc addColumnWithType:tightdb_Int andName:@"int"];
    }
    // Add a row to it
    [subtable2 addEmptyRow];
    [subtable2 set:COL_SUBTABLE_INT ndx:0 value:900];
*/
}

@end
