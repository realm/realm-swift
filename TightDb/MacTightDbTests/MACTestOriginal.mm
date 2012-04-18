//
//  MACTestOriginal.m
//  TightDb
//
//  Created by Thomas Andersen on 17/04/12.
//  Copyright (c) 2012 InvulgoSoft. All rights reserved.
//

#import "MACTestOriginal.h"
#include "../../native/include/Group.h"
#include "../../native/include/tightdb.h"

@implementation MACTestOriginal

//
// Demo code for short tutorial:
//

TDB_TABLE_4(MyTable,
            String, name,
            Int,    age,
            Bool,   hired,
            Int,	 spare)

TDB_TABLE_2(MyTable2,
Bool,   hired,
Int,    age)


-(void)testOriginal
{
    return; // Remove when wanting to test original.
    // Create Table in Group
    Group group;
    MyTable& table = group.GetTable<MyTable>("My great table");
    
    // Add some rows
    table.Add("John", 20, true, 0);
    table.Add("Mary", 21, false, 0);
    table.Add("Lars", 21, true, 0);
    table.Add("Phil", 43, false, 0);
    table.Add("Anni", 54, true, 0);
    
    //------------------------------------------------------
    
    size_t row; 
    row = table.name.Find("Philip");		    	// row = (size_t)-1
    assert(row == (size_t)-1);
    row = table.name.Find("Mary");		
    assert(row == 1);
    
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
}
@end
