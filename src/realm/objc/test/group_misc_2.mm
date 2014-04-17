//
//  group_misc_2.m
//  TightDB
//
// Demo code for short tutorial using Objective-C interface
//

#import <XCTest/XCTest.h>

#import <realm/objc/Realm.h>
#import <realm/objc/RLMTransaction.h>
#import <realm/objc/group.h>
#import <realm/objc/PrivateRLM.h>

REALM_TABLE_DEF_4(MyTable,
                    Name,  String,
                    Age,   Int,
                    Hired, Bool,
                    Spare, Int)

REALM_TABLE_DEF_2(MyTable2,
                    Hired, Bool,
                    Age,   Int)

REALM_TABLE_IMPL_4(MyTable,
                     Name,  String,
                     Age,   Int,
                     Hired, Bool,
                     Spare, Int)

REALM_TABLE_IMPL_2(MyTable2,
                     Hired, Bool,
                     Age,   Int)

REALM_TABLE_2(QueryTable,
                First,  Int,
                Second, String)

@interface MACTestGroupMisc2: XCTestCase
@end
@implementation MACTestGroupMisc2

- (void)testGroup_Misc2
{
    NSUInteger rowIndex;
    RLMTransaction * group = [RLMTransaction group];
    NSLog(@"HasTable: %i", [group hasTableWithName:@"employees"] );
    // Create new table in group
    MyTable* table = [group createTableWithName:@"employees" asTableClass:[MyTable class]];
    NSLog(@"Table: %@", table);
    NSLog(@"HasTable: %i", [group hasTableWithName:@"employees"] );

    // Add some rows
    [table addName:@"John" Age:20 Hired:YES Spare:0];
    [table addName:@"Mary" Age:21 Hired:NO Spare:0];
    [table addName:@"Lars" Age:21 Hired:YES Spare:0];
    [table addName:@"Phil" Age:43 Hired:NO Spare:0];
    [table addName:@"Anni" Age:54 Hired:YES Spare:0];

    NSLog(@"MyTable Size: %lu", table.rowCount);

    //------------------------------------------------------

    rowIndex = [table.Name find:@"Philip"];    // row = NSNotFound
    XCTAssertEqual(rowIndex, (NSUInteger)NSNotFound, @"Philip should not be there");
    rowIndex = [table.Name find:@"Mary"];
    XCTAssertEqual(rowIndex, (size_t)1,@"Mary should have been there");

    MyTableView *view = [[[table where].Age columnIsEqualTo:21] findAll];
    size_t cnt = view.rowCount;            // cnt = 2
    XCTAssertEqual(cnt, (size_t)2,@"Should be two rows in view");

    //------------------------------------------------------

    MyTable2* table2 = [[MyTable2 alloc] init];

    // Add some rows
    [table2 addHired:YES Age:20];
    [table2 addHired:NO Age:21];
    [table2 addHired:YES Age:22];
    [table2 addHired:NO Age:43];
    [table2 addHired:YES Age:54];

    // Create query (current employees between 20 and 30 years old)
    MyTable2Query* q = [[[table2 where].Hired columnIsEqualTo:YES].Age columnIsBetween:20 :30];

    // Get number of matching entries
    NSLog(@"Query count: %zu", [q countRows]);
    XCTAssertEqual([q countRows], (size_t)2,@"Expected 2 rows in query");

     // Get the average age - currently only a low-level interface!
    double avg = [q.Age avg];
    NSLog(@"Average: %f", avg);
    XCTAssertEqual(avg, 21.0,@"Expected 20.5 average");

    // Execute the query and return a table (view)
    RLMView* res = [q findAll];
    for (size_t i = 0; i < [res rowCount]; i++) {
        // cursor missing. Only low-level interface!
        NSLog(@"%zu: is %lld years old",i , [res RLM_intInColumnWithIndex:1 atRowIndex:i]);
    }

    //------------------------------------------------------

    NSFileManager* fm = [NSFileManager defaultManager];

    // Write to disk
    [fm removeItemAtPath:@"employees.tightdb" error:nil];
    [group writeContextToFile:@"employees.tightdb" error:nil];

    // Load a group from disk (and print contents)
    RLMTransaction * fromDisk = [RLMTransaction groupWithFile:@"employees.tightdb" error:nil];
    MyTable* diskTable = [fromDisk tableWithName:@"employees" asTableClass:[MyTable class]];

    [diskTable addName:@"Anni" Age:54 Hired:YES Spare:0];
//    [diskTable insertAtIndex:2 Name:@"Thomas" Age:41 Hired:NO Spare:1];
    NSLog(@"Disktable size: %zu", diskTable.rowCount);
    for (size_t i = 0; i < diskTable.rowCount; i++) {
        MyTableRow* cursor = [diskTable rowAtIndex:i];
        NSLog(@"%zu: %@", i, cursor.Name);
        NSLog(@"%zu: %@", i, [diskTable RLM_stringInColumnWithIndex:0 atRowIndex:i]);
    }

    // Write same group to memory buffer
    NSData* buffer = [group writeContextToBuffer];

    // Load a group from memory (and print contents)
    RLMTransaction * fromMem = [RLMTransaction groupWithBuffer:buffer error:nil];
    MyTable* memTable = [fromMem tableWithName:@"employees" asTableClass:[MyTable class]];
    for (size_t i = 0; i < [memTable rowCount]; i++) {
        // ??? cursor
        NSLog(@"%zu: %@", i, memTable.Name);
    }
}


- (void)testQuery
{
    RLMTransaction * group = [RLMTransaction group];
    QueryTable* table = [group createTableWithName:@"Query table" asTableClass:[QueryTable class]];

    // Add some rows
    [table addFirst:2 Second:@"a"];
    [table addFirst:4 Second:@"a"];
    [table addFirst:5 Second:@"b"];
    [table addFirst:8 Second:@"The quick brown fox"];

    {
        QueryTableQuery* q = [[table where].First columnIsBetween:3 :7]; // Between
        XCTAssertEqual((size_t)2,   [q countRows], @"count != 2");
//        XCTAssertEqual(9,   [q.First sum]); // Sum
        XCTAssertEqual(4.5, [q.First avg], @"Avg!=4.5"); // Average
//        XCTAssertEqual(4,   [q.First min]); // Minimum
//        XCTAssertEqual(5,   [q.First max]); // Maximum
    }
    {
        QueryTableQuery* q = [[table where].Second columnContains:@"quick" caseSensitive:NO]; // String contains
        XCTAssertEqual((size_t)1, [q countRows], @"count != 1");
    }
    {
        QueryTableQuery* q = [[table where].Second columnBeginsWith:@"The" caseSensitive:NO]; // String prefix
        XCTAssertEqual((size_t)1, [q countRows], @"count != 1");
    }
    {
        QueryTableQuery* q = [[table where].Second columnEndsWith:@"The" caseSensitive:NO]; // String suffix
        XCTAssertEqual((size_t)0, [q countRows], @"count != 1");
    }
    {
        QueryTableQuery* q = [[[table where].Second columnIsNotEqualTo:@"a" caseSensitive:NO].Second columnIsNotEqualTo:@"b" caseSensitive:NO]; // And
        XCTAssertEqual((size_t)1, [q countRows], @"count != 1");
    }
    {
        QueryTableQuery* q = [[[[table where].Second columnIsNotEqualTo:@"a" caseSensitive:NO] Or].Second columnIsNotEqualTo:@"b" caseSensitive:NO]; // Or
        XCTAssertEqual((size_t)4, [q countRows], @"count != 1");
    }
    {
        QueryTableQuery* q = [[[[[[[table where].Second columnIsEqualTo:@"a" caseSensitive:NO] group].First columnIsLessThan:3] Or].First columnIsGreaterThan:5] endGroup]; // Parentheses
        XCTAssertEqual((size_t)1, [q countRows], @"count != 1");
    }
    {
        QueryTableQuery* q = [[[[[table where].Second columnIsEqualTo:@"a" caseSensitive:NO].First columnIsLessThan:3] Or].First columnIsGreaterThan:5]; // No parenthesis
        XCTAssertEqual((size_t)2, [q countRows], @"count != 2");
        RLMView* tv = [q findAll];
        XCTAssertEqual((size_t)2, [tv rowCount], @"count != 2");
        XCTAssertEqual((int64_t)8, [tv RLM_intInColumnWithIndex:0 atRowIndex:1], @"First != 8");
    }
}

/*
 * Tables can contain other tables, however this is not yet supported
 * by the high level API. The following illustrates how to do it
 * through the low level API.
 */
- (void)testSubtables
{
    RLMTransaction * group = [RLMTransaction group];
    RLMTable* table = [group createTableWithName:@"table" asTableClass:[RLMTable class]];

    // Specify the table type
    {
        RLMDescriptor * desc = table.descriptor;
        [desc addColumnWithName:@"int" type:RLMTypeInt];
        {
            RLMDescriptor * subdesc = [desc addColumnTable:@"tab"];
            [subdesc addColumnWithName:@"int" type:RLMTypeInt];
        }
        [desc addColumnWithName:@"mix" type:RLMTypeMixed];
    }

    int COL_TABLE_INT = 0;
    int COL_TABLE_TAB = 1;
    int COL_TABLE_MIX = 2;
    int COL_SUBTABLE_INT = 0;

    // Add a row to the top level table
    [table addRow:nil];
    [table RLM_setInt:700 inColumnWithIndex:COL_TABLE_INT atRowIndex:0];

    // Add two rows to the subtable
    RLMTable* subtable = [table RLM_tableInColumnWithIndex:COL_TABLE_TAB atRowIndex:0];
    [subtable addRow:nil];

    [subtable RLM_setInt:800 inColumnWithIndex:COL_SUBTABLE_INT atRowIndex:0];
    [subtable addRow:nil];
    [subtable RLM_setInt:801 inColumnWithIndex:COL_SUBTABLE_INT atRowIndex:1];

    // Make the mixed values column contain another subtable
    [table RLM_setMixed:[[RLMTable alloc] init] inColumnWithIndex:COL_TABLE_MIX atRowIndex:0];
    
/* Fails!!!
    // Specify its type
    OCTopLevelTable* subtable2 = [table getTopLevelTable:COL_TABLE_MIX ndx:0];
    {
        RLMDescriptor* desc = [subtable2 getDescriptor];
        [desc addColumnWithType:RLMTypeInt andName:@"int"];
    }
    // Add a row to it
    [subtable2 addEmptyRow];
    [subtable2 set:COL_SUBTABLE_INT ndx:0 value:900];
*/
}

@end
