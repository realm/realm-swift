//
//  MACTestOriginal2.mm
//  TightDB
//
// 
//  Test code for all column types and subtables using C++ interface to TightDB
//

#import "MACTestOriginal2.h"
#include "group.hpp"
#include "tightdb.hpp"
#include <string>
#include <iostream>
#include <sstream>

using namespace tightdb;
@implementation MACTestOriginal2

-(void)testOriginalTable
{
	// Create table with all column types
	Table table;
	Spec& s = table.get_spec();
	s.add_column(COLUMN_TYPE_INT,    "int");
	s.add_column(COLUMN_TYPE_BOOL,   "bool");
	s.add_column(COLUMN_TYPE_DATE,   "date");
	s.add_column(COLUMN_TYPE_STRING, "string");
	s.add_column(COLUMN_TYPE_STRING, "string_long");
	s.add_column(COLUMN_TYPE_STRING, "string_enum"); // becomes ColumnStringEnum
	s.add_column(COLUMN_TYPE_BINARY, "binary");
	s.add_column(COLUMN_TYPE_MIXED,  "mixed");
	Spec sub = s.add_subtable_column("tables");
	sub.add_column(COLUMN_TYPE_INT,     "sub_first");
	sub.add_column(COLUMN_TYPE_STRING,  "sub_second");
	table.update_from_spec();
	
	// Add some rows
	for (size_t i = 0; i < 15; ++i) {
		table.insert_int(0, i, i);
		table.insert_int(1, i, (i % 2 ? true : false));
		table.insert_date(2, i, 12345);
		
		std::stringstream ss;
		ss << "string" << i;
		table.insert_string(3, i, ss.str().c_str());
		
		ss << " very long string.........";
		table.insert_string(4, i, ss.str().c_str());
		
		switch (i % 3) {
			case 0:
				table.insert_string(5, i, "test1");
				break;
			case 1:
				table.insert_string(5, i, "test2");
				break;
			case 2:
				table.insert_string(5, i, "test3");
				break;
		}
		
		table.insert_binary(6, i, "binary", 7);
		
		switch (i % 3) {
			case 0:
				table.insert_mixed(7, i, false);
				break;
			case 1:
				table.insert_mixed(7, i, (int64_t)i);
				break;
			case 2:
				table.insert_mixed(7, i, "string");
				break;
		}
		
		table.insert_subtable(8, i);
		table.insert_done();
		
		// Add sub-tables
		if (i == 2) {
			TableRef subtable = table.get_subtable(8, i);
			subtable->insert_int(0, 0, 42);
			subtable->insert_string(1, 0, "meaning");
			subtable->insert_done();
		}
	}
	
	// We also want a ColumnStringEnum
	table.optimize();
	
	// Test Deletes
	table.remove(14);
	table.remove(0);
	table.remove(5);
	
	//CHECK_EQUAL(12, table.GetSize());
	
#ifdef _DEBUG
	table.Verify();
#endif //_DEBUG
	
	// Test Clear
	table.clear();
	//CHECK_EQUAL(0, table.GetSize());
	
#ifdef _DEBUG
	table.Verify();
#endif //_DEBUG
}


@end
