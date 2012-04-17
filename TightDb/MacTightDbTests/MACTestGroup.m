//
//  MACTestGroup.m
//  TightDb
//
//  Created by Thomas Andersen on 17/04/12.
//  Copyright (c) 2012 InvulgoSoft. All rights reserved.
//

#import "MACTestGroup.h"
#import "OCGroup.h"

#define TIGHT_IMPL
#include "TightDb.h"

TDB_TABLE_2(TestTableGroup,
			String,     First,
			Int,        Second)


TDB_TABLE_4(MyTable,
String, Name,
Int,    Age,
Bool,   Hired,
Int,	 Spare)

TDB_TABLE_2(MyTable2,
            Bool,   Hired,
            Int,    Age)

@implementation MACTestGroup
{
    OCGroup *_group;
}

- (void)setUp
{
    [super setUp];
    
    _group = [OCGroup group];
    NSLog(@"Group: %@", _group);
    STAssertNotNil(_group, @"OCGroup is nil");
}

- (void)tearDown
{
    // Tear-down code here.
    
    [super tearDown];
    _group = nil;
}

- (void)testGroup
{
    // Create empty group and serialize to disk
    OCGroup *toDisk = [OCGroup group];
    [toDisk write:@"table_test.tbl"];

	// Load the group
    OCGroup *fromDisk = [OCGroup groupWithFilename:@"table_test.tbl"];
    if (![fromDisk isValid])
        STFail(@"From disk not valid");
    
	// Create new table in group
	TestTableGroup *t = (TestTableGroup *)[fromDisk getTable:@"test" withClass:[TestTableGroup class]];
    
    NSLog(@"Columns: %zu", [t getColumnCount]);
    if ([t getColumnCount] != 2)
        STFail(@"Should have been 2 columns");
    if ([t getSize] != 0)
        STFail(@"Should have been empty");
	// Modify table
    [t add:@"Test" col2:YES];
    NSLog(@"Size: %lu", [t getSize]);
    
    if ([t getSize] != 1)
        STFail(@"Should have been one row");
}

//
// Demo code for short tutorial:
//


- (void)testGroup_Misc2
{
    OCGroup *group = [OCGroup group];
	// Create new table in group
	MyTable *table = [group getTable:@"My great table" withClass:[MyTable class]];
    
    // Add some rows
    [table add:@"John" col2:20 col3:YES col4:0];
    [table add:@"Mary" col2:21 col3:NO col4:0];
    [table add:@"Lars" col2:21 col3:YES col4:0];
    [table add:@"Phil" col2:43 col3:NO col4:0];
    [table add:@"Anni" col2:54 col3:YES col4:0];
    
    //------------------------------------------------------
    
    size_t row; 
    row = [table.Name find:@"Philip"];		    	// row = (size_t)-1
    STAssertEquals(row, -1,@"Philip should not be there");
    row = [table.Name find:@"Mary"];		
    STAssertEquals(row, 1,@"Mary should have been there");
/*    
    TableView view = table.age.FindAll(21);   
    size_t cnt = view.GetSize();  				// cnt = 2
    assert(cnt==2);
    
    //------------------------------------------------------
    
    MyTable2 table2;
    
    // Add some rows
    table2.Add(true, 20);
    table2.Add(false, 21);
    table2.Add(true, 21);
    table2.Add(false, 43);
    table2.Add(true, 54);
    
	// Create query (current employees between 20 and 30 years old)
    Query q = table2.GetQuery().hired.Equal(true).age.Between(20, 30);
    
    // Get number of matching entries
    cout << q.Count(table2);                                         // => 2
    assert(q.Count(table2)==2);
    
    // Get the average age
    double avg = q.Avg(table2, 1, &cnt);
    cout << avg;						                               // => 20,5
    
    // Execute the query and return a table (view)
    TableView res = q.FindAll(table2);
    for (size_t i = 0; i < res.GetSize(); i++) {
		cout << i << ": " << " is " << res.Get(1, i) << " years old." << endl;
    }
    
    //------------------------------------------------------
    
    // Write to disk
    group.Write("employees.tightdb");
	
    // Load a group from disk (and print contents)
    Group fromDisk("employees.tightdb");
    MyTable& diskTable = fromDisk.GetTable<MyTable>("employees");
    for (size_t i = 0; i < diskTable.GetSize(); i++) {
		cout << i << ": " << diskTable[i].name << endl;
    }
    
    // Write same group to memory buffer
    size_t len;
    const char* const buffer = group.WriteToMem(len);
    
    // Load a group from memory (and print contents)
    Group fromMem(buffer, len);
    MyTable& memTable = fromMem.GetTable<MyTable>("employees");
    for (size_t i = 0; i < memTable.GetSize(); i++) {
		cout << i << ": " << memTable[i].name << endl;
    }
 */
}



@end


