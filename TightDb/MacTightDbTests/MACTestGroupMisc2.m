//
//  MACTestGroupMisc2.m
//  TightDB
//
//
// Demo code for short tutorial using Objective-C interface
//

#import "MACTestGroupMisc2.h"
#import "Group.h"
#import "Table.h"

TDB_TABLE_IMPL_4(MyTable,
			String, Name,
			Int,    Age,
			Bool,   Hired,
			Int,	Spare)

TDB_TABLE_IMPL_2(MyTable2,
            Bool,   Hired,
            Int,    Age)

@implementation MACTestGroupMisc2

- (void)testGroup_Misc2
{
    Group *group = [Group group];
	// Create new table in group
	MyTable *table = [group getTable:@"employees" withClass:[MyTable class]];
    
    // Add some rows
    [table addName:@"John" Age:20 Hired:YES Spare:0];
    [table addName:@"Mary" Age:21 Hired:NO Spare:0];
    [table addName:@"Lars" Age:21 Hired:YES Spare:0];
    [table addName:@"Phil" Age:43 Hired:NO Spare:0];
    [table addName:@"Anni" Age:54 Hired:YES Spare:0];
    
    NSLog(@"MyTable Size: %lu", [table count]);
    
    //------------------------------------------------------
    
    size_t row; 
    row = [table.Name find:@"Philip"];		    	// row = (size_t)-1
    NSLog(@"Philip: %zu", row);
    STAssertEquals(row, (size_t)-1,@"Philip should not be there");
    row = [table.Name find:@"Mary"];		
    NSLog(@"Mary: %zu", row);
    STAssertEquals(row, (size_t)1,@"Mary should have been there");

    TableView *view = [table.Age findAll:21];
    size_t cnt = [view count];  					// cnt = 2
    STAssertEquals(cnt, (size_t)2,@"Should be two rows in view");
     
    //------------------------------------------------------
     
    MyTable2 *table2 = [[MyTable2 alloc] init];
     
    // Add some rows
    [table2 addHired:YES Age:20];
    [table2 addHired:NO Age:21];
    [table2 addHired:YES Age:22];
    [table2 addHired:NO Age:43];
    [table2 addHired:YES Age:54];
     
    // Create query (current employees between 20 and 30 years old)
    Query *q = [[[table2 getQuery].Hired equal:YES].Age between:20 to:30];

    // Get number of matching entries
    NSLog(@"Query count: %zu", [q count:table2]);
    STAssertEquals([q count:table2], (size_t)2,@"Expected 2 rows in query");
     
     // Get the average age - currently only a low-level interface!
    double avg = [q avg:table2 column:1 resultCount:&cnt];
    NSLog(@"Average: %f", avg);
    STAssertEquals(avg, 21.0,@"Expected 20.5 average");
     
    // Execute the query and return a table (view)
    TableView *res = [q findAll:table2];
    for (size_t i = 0; i < [res count]; i++) {
		// cursor missing. Only low-level interface!
        NSLog(@"%zu: is %lld years old",i , [res get:1 ndx:i]);
    }
     
    //------------------------------------------------------
     
    // Write to disk
    [group write:@"employees.tightdb"];
     
    // Load a group from disk (and print contents)
    Group *fromDisk = [Group groupWithFilename:@"employees.tightdb"];
    MyTable *diskTable = [fromDisk getTable:@"employees" withClass:[MyTable class]];
    
    [diskTable addName:@"Anni" Age:54 Hired:YES Spare:0];
//    [diskTable insertAtIndex:2 Name:@"Thomas" Age:41 Hired:NO Spare:1];
    NSLog(@"Disktable size: %zu", [diskTable count]);
    for (size_t i = 0; i < [diskTable count]; i++) {
        MyTable_Cursor *cursor = [diskTable objectAtIndex:i];
        NSLog(@"%zu: %@", i, [cursor Name]);
        NSLog(@"%zu: %@", i, cursor.Name);
        NSLog(@"%zu: %@", i, [diskTable getString:0 ndx:i]);
    }
     
    // Write same group to memory buffer
    size_t len;
    const char* const buffer = [group writeToMem:&len];
     
    // Load a group from memory (and print contents)
    Group *fromMem = [Group groupWithBuffer:buffer len:len];
    MyTable *memTable = [fromMem getTable:@"employees" withClass:[MyTable class]];
    for (size_t i = 0; i < [memTable count]; i++) {
        // ??? cursor
		NSLog(@"%zu: %@", i, memTable.Name);
    }
}


TDB_TABLE_2(QueryTable,
	Int, First,
	String, Second)

- (void)testQuery
{
    OCGroup *group = [OCGroup group];
    QueryTable *table = [group getTable:@"Query table" withClass:[QueryTable class]];

    // Add some rows
    [table addFirst:2 Second:@"a"];
    [table addFirst:4 Second:@"a"];
    [table addFirst:5 Second:@"b"];
    [table addFirst:8 Second:@"The quick brown fox"];

    {
        QueryTable_Query *q = [[table getQuery].First between:3 to:7]; // Between
        STAssertEquals(2,   [q count]);
        STAssertEquals(9,   [q.First sum]); // Sum
        STAssertEquals(4.5, [q.First avg]); // Average
        STAssertEquals(4,   [q.First min]); // Minimum
        STAssertEquals(5,   [q.First max]); // Maximum
    }
    {
        QueryTable_Query *q = [[table getQuery].Second contains:@"quick"]; // String contains
        STAssertEquals(1, [q count]);
    }
    {
        QueryTable_Query *q = [[table getQuery].Second beginsWith:@"The"]; // String prefix
        STAssertEquals(1, [q count]);
    }
    {
        QueryTable_Query *q = [[table getQuery].Second endsWith:@"The"]; // String suffix
        STAssertEquals(1, [q count]);
    }
    {
        QueryTable_Query *q = [[[table getQuery].Second notEqual:@"a"].Second notEqual:@"b"]; // And
        STAssertEquals(1, [q count]);
    }
    {
        QueryTable_Query *q = [[[[table getQuery].Second notEqual:@"a"] or].Second notEqual:@"b"]; // Or
        STAssertEquals(3, [q count]);
    }
    {
        QueryTable_Query *q = [[[[[[[table getQuery].Second equal:@"a"] group].First less:3] or].First greater:5] endgroup]; // Parentheses
        STAssertEquals(1, [q count]);
    }
    {
        QueryTable_Query *q = [[[[[table getQuery].Second equal:@"a"].First less:3] or].First greater:5]; // No parenthesis
        STAssertEquals(2, [q count]);
        QueryTable_View *tv = [q findAll];
        STAssertEquals(2, [tv count]);
        STAssertEquals(8, [tv objectAtIndex:1].First);
    }
}

@end
