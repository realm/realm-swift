//
//  MACTestGroupMisc2.m
//  TightDB
//
//
// Demo code for short tutorial using Objective-C interface
//

#import "MACTestGroupMisc2.h"
#import "OCGroup.h"
#import "OCTable.h"

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
    OCGroup *group = [OCGroup group];
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

    OCTableView *view = [table.Age findAll:21];
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
    OCQuery *q = [[[table2 getQuery].Hired equal:YES].Age between:20 to:30];

    // Get number of matching entries
    NSLog(@"Query count: %zu", [q count:table2]);
    STAssertEquals([q count:table2], (size_t)2,@"Expected 2 rows in query");
     
     // Get the average age - currently only a low-level interface!
    double avg = [q avg:table2 column:1 resultCount:&cnt];
    NSLog(@"Average: %f", avg);
    STAssertEquals(avg, 21.0,@"Expected 20.5 average");
     
    // Execute the query and return a table (view)
    OCTableView *res = [q findAll:table2];
    for (size_t i = 0; i < [res count]; i++) {
		// cursor missing. Only low-level interface!
        NSLog(@"%zu: is %lld years old",i , [res get:1 ndx:i]);
    }
     
    //------------------------------------------------------
     
    // Write to disk
    [group write:@"employees.tightdb"];
     
    // Load a group from disk (and print contents)
    OCGroup *fromDisk = [OCGroup groupWithFilename:@"employees.tightdb"];
    MyTable *diskTable = [fromDisk getTable:@"employees" withClass:[MyTable class]];
    
//    [diskTable addName:@"Anni" Age:54 Hired:YES Spare:0];
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
    OCGroup *fromMem = [OCGroup groupWithBuffer:buffer len:len];
    MyTable *memTable = [fromMem getTable:@"employees" withClass:[MyTable class]];
    for (size_t i = 0; i < [memTable count]; i++) {
        // ??? cursor
		NSLog(@"%zu: %@", i, memTable.Name);
    }
}

@end
