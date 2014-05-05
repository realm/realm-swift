//
//  group_misc_2.m
//  TightDB
//
// Demo code for short tutorial using Objective-C interface
//

#import "RLMTestCase.h"

#import <realm/objc/Realm.h>
#import <realm/objc/RLMRealm.h>
#import <realm/objc/RLMPrivate.h>
#import <realm/objc/RLMPrivateTableMacrosFast.h>

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

REALM_TABLE_FAST(MyTable)

REALM_TABLE_FAST(MyTable2)

REALM_TABLE_FAST(QueryTable)

@interface MACTestRealmMisc2 : RLMTestCase

@end

@implementation MACTestRealmMisc2

- (void)testRealm_Misc2
{
    [[self managerWithTestPath] writeUsingBlock:^(RLMRealm *realm) {
        NSUInteger rowIndex;
        NSLog(@"HasTable: %i", [realm hasTableWithName:@"employees"] );
        // Create new table in realm
        MyTable *table = [realm createTableWithName:@"employees" asTableClass:[MyTable class]];
        NSLog(@"Table: %@", table);
        NSLog(@"HasTable: %i", [realm hasTableWithName:@"employees"] );
        
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
        XCTAssertEqual(rowIndex, (NSUInteger)1,@"Mary should have been there");
        
        MyTableView *view = [[[table where].Age columnIsEqualTo:21] findAll];
        NSUInteger cnt = view.rowCount;            // cnt = 2
        XCTAssertEqual(cnt, (NSUInteger)2,@"Should be two rows in view");
    
        //------------------------------------------------------
        
        MyTable2* table2 = [realm createTableWithName:@"table2" asTableClass:MyTable2.class];
        
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
        XCTAssertEqual([q countRows], (NSUInteger)2,@"Expected 2 rows in query");
        
        // Get the average age - currently only a low-level interface!
        double avg = [q.Age avg];
        NSLog(@"Average: %f", avg);
        XCTAssertEqual(avg, 21.0,@"Expected 21 average");
        
        // Execute the query and return a table (view)
        RLMView* res = [q findAll];
        for (NSUInteger i = 0; i < [res rowCount]; i++) {
            // cursor missing. Only low-level interface!
            NSLog(@"%zu: is %lld years old",i , [res RLM_intInColumnWithIndex:1 atRowIndex:i]);
        }
        
        //------------------------------------------------------
        
        // Load a realm from disk (and print contents)
        RLMRealm * fromDisk = [self realmPersistedAtTestPath];
        MyTable* diskTable = [fromDisk tableWithName:@"employees" asTableClass:[MyTable class]];
        
        NSLog(@"Disktable size: %zu", diskTable.rowCount);
        for (NSUInteger i = 0; i < diskTable.rowCount; i++) {
            MyTableRow* cursor = [diskTable rowAtIndex:i];
            NSLog(@"%zu: %@", i, cursor.Name);
            NSLog(@"%zu: %@", i, [diskTable RLM_stringInColumnWithIndex:0 atRowIndex:i]);
        }
    }];
}

- (void)testQuery
{
    [[self managerWithTestPath] writeUsingBlock:^(RLMRealm *realm) {
        QueryTable *table = [realm createTableWithName:@"Query table" asTableClass:[QueryTable class]];
        
        // Add some rows
        [table addFirst:2 Second:@"a"];
        [table addFirst:4 Second:@"a"];
        [table addFirst:5 Second:@"b"];
        [table addFirst:8 Second:@"The quick brown fox"];
    }];
    
    QueryTable *table = [[self realmPersistedAtTestPath] tableWithName:@"Query table" asTableClass:[QueryTable class]];

    {
        QueryTableQuery* q = [[table where].First columnIsBetween:3 :7]; // Between
        XCTAssertEqual((NSUInteger)2,   [q countRows], @"count != 2");
        XCTAssertEqual(4.5, [q.First avg], @"Avg!=4.5"); // Average
    }
    {
        QueryTableQuery* q = [[table where].Second columnContains:@"quick" caseSensitive:NO]; // String contains
        XCTAssertEqual((NSUInteger)1, [q countRows], @"count != 1");
    }
    {
        QueryTableQuery* q = [[table where].Second columnBeginsWith:@"The" caseSensitive:NO]; // String prefix
        XCTAssertEqual((NSUInteger)1, [q countRows], @"count != 1");
    }
    {
        QueryTableQuery* q = [[table where].Second columnEndsWith:@"The" caseSensitive:NO]; // String suffix
        XCTAssertEqual((NSUInteger)0, [q countRows], @"count != 1");
    }
    {
        QueryTableQuery* q = [[[table where].Second columnIsNotEqualTo:@"a" caseSensitive:NO].Second columnIsNotEqualTo:@"b" caseSensitive:NO]; // And
        XCTAssertEqual((NSUInteger)1, [q countRows], @"count != 1");
    }
    {
        QueryTableQuery* q = [[[[table where].Second columnIsNotEqualTo:@"a" caseSensitive:NO] Or].Second columnIsNotEqualTo:@"b" caseSensitive:NO]; // Or
        XCTAssertEqual((NSUInteger)4, [q countRows], @"count != 1");
    }
    {
        QueryTableQuery* q = [[[[[[[table where].Second columnIsEqualTo:@"a" caseSensitive:NO] group].First columnIsLessThan:3] Or].First columnIsGreaterThan:5] endGroup]; // Parentheses
        XCTAssertEqual((NSUInteger)1, [q countRows], @"count != 1");
    }
    {
        QueryTableQuery* q = [[[[[table where].Second columnIsEqualTo:@"a" caseSensitive:NO].First columnIsLessThan:3] Or].First columnIsGreaterThan:5]; // No parenthesis
        XCTAssertEqual((NSUInteger)2, [q countRows], @"count != 2");
        RLMView* tv = [q findAll];
        XCTAssertEqual((NSUInteger)2, [tv rowCount], @"count != 2");
        XCTAssertEqual((int64_t)8, [tv RLM_intInColumnWithIndex:0 atRowIndex:1], @"First != 8");
    }
}

// Tables can contain other tables, however this is not yet supported
// by the high level API. The following illustrates how to do it
// through the low level API.
- (void)testSubtables
{
    [[self managerWithTestPath] writeUsingBlock:^(RLMRealm *realm) {
        RLMTable *table = [realm createTableWithName:@"table"];
        
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
        RLMTable *subtable2 = [realm createTableWithName:@"subtable2"];
        [table RLM_setMixed:subtable2 inColumnWithIndex:COL_TABLE_MIX atRowIndex:0];
    }];
    
//    Fails!!!
//    // Specify its type
//    OCTopLevelTable* subtable2 = [table getTopLevelTable:COL_TABLE_MIX ndx:0];
//    {
//        RLMDescriptor* desc = [subtable2 getDescriptor];
//        [desc addColumnWithType:RLMTypeInt andName:@"int"];
//    }
//    // Add a row to it
//    [subtable2 addEmptyRow];
//    [subtable2 set:COL_SUBTABLE_INT ndx:0 value:900];
}

@end
