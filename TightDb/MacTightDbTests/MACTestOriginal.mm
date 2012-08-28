//
//  MACTestOriginal.m
//  TightDB
//
// 
//  Demo code for short tutorial using C++ interface to TightDB
//


#import "MACTestOriginal.h"
#include <tightdb/group.hpp>
#include <tightdb.hpp>

using namespace tightdb;

@implementation MACTestOriginal

TIGHTDB_TABLE_4(MyTable,
            name,  String,
            age,   Int,
            hired, Bool,
            spare, Int)

TIGHTDB_TABLE_2(MyTable2,
			hired, Bool,
			age, Int)


-(void)testOriginal
{
    // Create Table in Group
    Group group;
    MyTable::Ref table = group.get_table<MyTable>("My great table");
    
    // Add some rows
    table->add("John", 20, true, 0);
    table->add("Mary", 21, false, 0);
    table->add("Lars", 21, true, 0);
    table->add("Phil", 43, false, 0);
    table->add("Anni", 54, true, 0);
    
    //------------------------------------------------------
    
    size_t row; 
    row = table->column().name.find_first("Philip");		    // row = (size_t)-1
    assert(row == (size_t)-1);
    row = table->column().name.find_first("Mary");
    assert(row == 1);
    
    MyTable::View view = table->column().age.find_all(21);
    const size_t cnt = view.size();  				// cnt = 2
    assert(cnt==2);
    
    //------------------------------------------------------
    
    MyTable2 table2;
    
    // Add some rows
    table2.add(true, 20);
    table2.add(false, 21);
    table2.add(true, 21);
    table2.add(false, 43);
    table2.add(true, 54);
    
	// Create query (current employees between 20 and 30 years old)
    MyTable2::Query q = table2.where().hired.equal(true).age.between(20, 30);
    
    // Get number of matching entries
    std::cout << q.count(table2);					// => 2
    assert(q.count(table2) == 2);
    
    // Get the average age
    double avg = q.age.average(table2);
    std::cout << avg;						        // => 20,5
    
    // Execute the query and return a table (view)
    MyTable2::View res = q.find_all(table2);
    for (size_t i = 0; i < res.size(); ++i) {
        std::cout << i << ": " << " is " << res[i].age << " years old." << std::endl;
    }
    
    //------------------------------------------------------
    
    // Write to disk
    group.write("employees.tightdb");
	
    // Load a group from disk (and print contents)
    Group fromDisk("employees.tightdb");
    MyTable::Ref diskTable = fromDisk.get_table<MyTable>("employees");
    for (size_t i = 0; i < diskTable->size(); ++i) {
        std::cout << i << ": " << diskTable[i].name << std::endl;
    }
    
    // Write same group to memory buffer
    size_t len;
    const char* const buffer = group.write_to_mem(len);
    
    // Load a group from memory (and print contents)
    Group fromMem(buffer, len);
    MyTable::Ref memTable = fromMem.get_table<MyTable>("employees");
    for (size_t i = 0; i < memTable->size(); ++i) {
        std::cout << i << ": " << memTable[i].name << std::endl;
    }
}
@end
