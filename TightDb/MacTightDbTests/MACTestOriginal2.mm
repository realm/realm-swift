//
//  MACTestOriginal2.mm
//  TightDB
//
// 
//  Test code for all coulumn types and subtables using C++ interface to TightDB
//

#import "MACTestOriginal2.h"
#include "../../native/include/Group.h"
#include "../../native/include/tightdb.h"
#include <string>
#include <iostream>
#include <sstream>

using namespace tightdb;
@implementation MACTestOriginal2

-(void)testOriginalTable
{
	// Create table with all column types
	TopLevelTable table;
	Spec s = table.GetSpec();
	s.AddColumn(COLUMN_TYPE_INT,    "int");
	s.AddColumn(COLUMN_TYPE_BOOL,   "bool");
	s.AddColumn(COLUMN_TYPE_DATE,   "date");
	s.AddColumn(COLUMN_TYPE_STRING, "string");
	s.AddColumn(COLUMN_TYPE_STRING, "string_long");
	s.AddColumn(COLUMN_TYPE_STRING, "string_enum"); // becomes ColumnStringEnum
	s.AddColumn(COLUMN_TYPE_BINARY, "binary");
	s.AddColumn(COLUMN_TYPE_MIXED,  "mixed");
	Spec sub = s.AddColumnTable(    "tables");
	sub.AddColumn(COLUMN_TYPE_INT,    "sub_first");
	sub.AddColumn(COLUMN_TYPE_STRING, "sub_second");
	table.UpdateFromSpec(s.GetRef());
	
	// Add some rows
	for (size_t i = 0; i < 15; ++i) {
		table.InsertInt(0, i, i);
		table.InsertBool(1, i, (i % 2 ? true : false));
		table.InsertDate(2, i, 12345);
		
		std::stringstream ss;
		ss << "string" << i;
		table.InsertString(3, i, ss.str().c_str());
		
		ss << " very long string.........";
		table.InsertString(4, i, ss.str().c_str());
		
		switch (i % 3) {
			case 0:
				table.InsertString(5, i, "test1");
				break;
			case 1:
				table.InsertString(5, i, "test2");
				break;
			case 2:
				table.InsertString(5, i, "test3");
				break;
		}
		
		table.InsertBinary(6, i, "binary", 7);
		
		switch (i % 3) {
			case 0:
				table.InsertMixed(7, i, false);
				break;
			case 1:
				table.InsertMixed(7, i, (int64_t)i);
				break;
			case 2:
				table.InsertMixed(7, i, "string");
				break;
		}
		
		table.InsertTable(8, i);
		table.InsertDone();
		
		// Add sub-tables
		if (i == 2) {
			TableRef subtable = table.GetTable(8, i);
			subtable->InsertInt(0, 0, 42);
			subtable->InsertString(1, 0, "meaning");
			subtable->InsertDone();
		}
	}
	
	// We also want a ColumnStringEnum
	table.Optimize();
	
	// Test Deletes
	table.DeleteRow(14);
	table.DeleteRow(0);
	table.DeleteRow(5);
	
	//CHECK_EQUAL(12, table.GetSize());
	
#ifdef _DEBUG
	table.Verify();
#endif //_DEBUG
	
	// Test Clear
	table.Clear();
	//CHECK_EQUAL(0, table.GetSize());
	
#ifdef _DEBUG
	table.Verify();
#endif //_DEBUG
}


@end
