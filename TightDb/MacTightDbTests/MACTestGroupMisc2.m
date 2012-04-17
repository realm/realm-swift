//
//  MACTestGroupMisc2.m
//  TightDb
//
//  Created by Thomas Andersen on 17/04/12.
//  Copyright (c) 2012 InvulgoSoft. All rights reserved.
//

#import "MACTestGroupMisc2.h"
#import "OCGroup.h"
#import "OCTable.h"

#define TIGHT_IMPL
#include "TightDb.h"

TDB_TABLE_4(MyTable,
String, Name,
Int,    Age,
Bool,   Hired,
Int,	 Spare)

TDB_TABLE_2(MyTable2,
            Bool,   Hired,
            Int,    Age)

@implementation MACTestGroupMisc2


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
    
    NSLog(@"MyTable Size: %lu", [table getSize]);
    
    //------------------------------------------------------
    
    size_t row; 
    row = [table.Name find:@"Philip"];		    	// row = (size_t)-1
    NSLog(@"Philip: %zu", row);
    STAssertEquals(row, (size_t)-1,@"Philip should not be there");
    row = [table.Name find:@"Mary"];		
    NSLog(@"Mary: %zu", row);
    STAssertEquals(row, (size_t)1,@"Mary should have been there");
    /*
    OCTableView *view = [table.Age findAll:21];
    size_t cnt = [view getSize];  				// cnt = 2
    STAssertEquals(cnt, 2,@"Should be two rows in view");
     
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
    
    // Clean
    group = nil;
    table = nil;
}

@end
