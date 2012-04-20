//
//  MACTestTutorial.m
//  TightDB
//
//
// Demo code for short tutorial using Objective-C interface
//

#import "MACTestTutorial.h"
#import "Group.h"
#import "Table.h"

TDB_TABLE_IMPL_3(PeopleTable,
			String, Name,
			Int,    Age,
			Bool,   Hired)

TDB_TABLE_IMPL_2(PeopleTable2,
            Bool,   Hired,
            Int,    Age)

@implementation MACTestTutorial

- (void)testTutorial
{
    //------------------------------------------------------
    NSLog(@"--- Creating tables ---");
	//------------------------------------------------------

	Group *group = [Group group];
	// Create new table in group
	PeopleTable *table = [group getTable:@"employees" withClass:[PeopleTable class]];
    
    // Add some rows
    [people addName:@"John" Age:20 Hired:YES Spare:0];
    [people addName:@"Mary" Age:21 Hired:NO Spare:0];
    [people addName:@"Lars" Age:22 Hired:YES Spare:0];
    [people addName:@"Phil" Age:43 Hired:NO Spare:0];
    [people addName:@"Anni" Age:54 Hired:YES Spare:0];
    
	// Insert at specific position
	[people insertAtIndex:2 Name:@"Frank" Age:34 Hired:YES];

	// Getting the size of the table
    NSLog(@"PeopleTable Size: %lu - is %s.    [6 - not empty]", [people count], 
		[people isEmpty] ? @"empty" : @"not empty");

	//------------------------------------------------------
    NSLog(@"--- Working with individual rows ---");
	//------------------------------------------------------

	// Getting values 
	const char* name = [table objectAtIndex:5].Name;   // => 'Anni'
	// Using a cursor 
	PeopleTable_Cursor myRow = [table objectAtIndex:5];
	int64_t age = myRow.Age;                           // => 54
	BOOL hired  = myRow.Hired;                         // => true

	// Setting values
	[[table objectAtIndex:5] setAge:43];               // Getting younger
	// or with dot-syntax:
	myRow.Age += 1;                                    // Happy birthday!
	NSLog(@"%s age is now %lu.   [44]", myRow.Name, myRow.Age);

	// Get last row
	const char* lastname = [people lastObject].Name;       // => "Anni"
	NSLog(@"Last name is %s.   [Anni]", lastname);

	// Change a row - not implemented yet
	// [people setAtIndex:4 Name:"Eric" Age:50 Hired:YES];

	// Delete row
	[people deleteRow:2];                                          
	NSLog(@"%lu rows after delete.  [5]", [people count]);  // 5
	STAssertEquals([people count], 5,@"rows should be 5");

	// Iterating over rows:
	for (size_t i = 0; i < [people count]; ++i) {
		PeopleTable_Cursor row = [people objectAtIndex:i];
		NSLog(@"%s is %lld years old.", row.Name, row.Age);
	}

    //------------------------------------------------------
    NSLog(@"--- Simple Searching ---");
    //------------------------------------------------------
		
    size_t row;
    row = [people.Name find:@"Philip"];		    	// row = (size_t)-1
    NSLog(@"Philip: %zu  [-1]", row);
    STAssertEquals(row, (size_t)-1,@"Philip should not be there");
    
	row = [people.Name find:@"Mary"];		
    NSLog(@"Mary: %zu", row);
    STAssertEquals(row, (size_t)1,@"Mary should have been there");

    TableView *view = [people.Age findAll:21];
    size_t cnt = [view count];  					// cnt = 2
    STAssertEquals(cnt, (size_t)2,@"Should be two rows in view");
     
    //------------------------------------------------------
    NSLog(@"--- Queries ---");
    //------------------------------------------------------
     
    // Create query (current employees between 20 and 30 years old)
	Query *q = [[[people getQuery].Hired equal:YES]            // Implicit AND
								  .Age between:20 to:30];

    // Get number of matching entries
    NSLog(@"Query count: %zu", [q count]);
    STAssertEquals([q count], (size_t)2,@"Expected 2 rows in query");
     
    // Get the average age - currently only a low-level interface!
    double avg = [q.Age avg];		
    NSLog(@"Average: %f    [21]", avg);
    STAssertEquals(avg, 21.0,@"Expected 21 average");
     
	// Execute the query and return a table (view)
	TableView *res = [q findAll];
	for (size_t i = 0; i < [res count]; ++i) {
		NSLog(@"%zu: %@ is %d years old", i, 
			[people objectAtIndex:i].Name, 
			[people objectAtIndex:i].Age);
	}

    //------------------------------------------------------
    NSLog(@"--- Serialization ---");
	//------------------------------------------------------
    
    // Write the group to disk
    [group write:@"employees.tightdb"];
     
    // Load a group from disk (and print contents)
    Group *fromDisk = [Group groupWithFilename:@"employees.tightdb"];
    PeopleTable *diskTable = [fromDisk getTable:@"employees" withClass:[PeopleTable class]];
    
    [diskTable addName:@"Anni" Age:54 Hired:YES];

    NSLog(@"Disktable size: %zu", [diskTable count]);

	for (size_t i = 0; i < [diskTable count]; i++) {
        PeopleTable_Cursor *cursor = [diskTable objectAtIndex:i];
        NSLog(@"%zu: %@", i, [cursor Name]);
        NSLog(@"%zu: %@", i, cursor.Name);
    }
     
    // Write same group to memory buffer
    size_t len;
    const char* const buffer = [group writeToMem:&len];
     
    // Load a group from memory (and print contents)
    Group *fromMem = [Group groupWithBuffer:buffer len:len];
    PeopleTable *memTable = [fromMem getTable:@"employees" withClass:[MyTable class]];
    for (size_t i = 0; i < [memTable count]; i++) {
        PeopleTable_Cursor *cursor = [memTable objectAtIndex:i];
		NSLog(@"%zu: %@", i, cursor.Name);
    }
}

@end
