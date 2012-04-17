#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#include <cstdio>
#include <istream>
#include <fstream>
using namespace std;

#include "Table.h"
#include "Group.h"

// =====================================================================

#ifndef INT64_MIN
#define INT64_MIN    ((int64_t)_I64_MIN)
#define INT64_MAX    _I64_MAX
#endif

enum Days {
	Mon,
	Tue,
	Wed,
	Thu,
	Fri,
	Sat,
	Sun
};

// Due to the fact that implementation cannot be in header files, I suggest the following solution.
// Also note, that in order for get,setters to work the variable name must start with capital letter.
#include "tightdb.h"
TDB_TABLE_4(TestTableGroup,
			String,     MyStrings,
			Int,        MyInts,
			Bool,       MyBools,
			Enum<Days>, MyEnums)
#define TIGHT_IMPL
#include "tightdb.h"
TDB_TABLE_4(TestTableGroup,
String,     MyStrings,
Int,        MyInts,
Bool,       MyBools,
Enum<Days>, MyEnums)


-(void)testgroup:(NSString *)filename
{

}// Create group with two tables
    TestTableGroup *toDisk = [[TestTableGroup alloc] init];
    TestTableGroup *table1 = [toDisk getTable:@"test1"];
    
    [table1 add:@"a" MyInts:[NSNumber numberWithint:1] MyBools:[NSNumber numberwithBool:YES] MyEnums:[NSNumber numberWithint:Mon]];
    TestTableGroup *table2 = [toDisk getTable:@"test2"];
    
    [table2 add:@"hey" MyInts:[NSNumber numberWithint:0] MyBools:[NSNumber numberwithBool:YES] MyEnums:[NSNumber numberWithint:Tue]];

	remove(filename); // NSFilemanager defaultmanager] delete.....
    [toDisk Write:filename];
}

void testgroup2(const char *filename) {
	Group grp;

	TestTableGroup& tbl1 = grp.GetTable<TestTableGroup>("First");
	tbl1.Add("a", 1, true, Wed);

	remove(filename);
	grp.Write(filename);
}


#define MIX 0

void testgroup3(const char *filename) {
	Group group;
	TopLevelTable& table = group.GetTable("test");

	// Create specification with sub-table
	Spec s = table.GetSpec();
#if MIX
	s.AddColumn(COLUMN_TYPE_MIXED, "mixed");
#else
	Spec sub = s.AddColumnTable(    "sub");
	sub.AddColumn(COLUMN_TYPE_INT,    "sub_first");
	sub.AddColumn(COLUMN_TYPE_STRING, "sub_second");
#endif
	s.AddColumn(COLUMN_TYPE_INT,    "first");
	s.AddColumn(COLUMN_TYPE_STRING, "second");
	table.UpdateFromSpec(s.GetRef());

	// Add rows
	const size_t max = 3;
	for (size_t i = 0; i < max; i++) {		
#if MIX
		switch (i) {
		case 0: table.InsertMixed(0, i, (int64_t)(1234)); break;
		case 1: table.InsertMixed(0, i, "hejsa"); break;
		case 2: table.InsertMixed(0, i, Mixed(COLUMN_TYPE_TABLE)); break;
		default: assert(1);
		}
#else
		table.InsertTable(0, i);
#endif
		table.InsertInt(1, i, 4*(i+1));
		table.InsertString(2, i, i ? "Hello" : "Hi");
		table.InsertDone();
	}

#if MIX
	Table* const subtable = table.GetTablePtr(0, 2);
	subtable->RegisterColumn(COLUMN_TYPE_INT,    "age");
	subtable->RegisterColumn(COLUMN_TYPE_STRING, "name");
	
	for (size_t i = 0; i < max; i++) {
		subtable->InsertInt(0, i, 42);
		subtable->InsertString(1, i, i ? "test" : "testing");
		subtable->InsertDone();
	}
	delete subtable;
#else
	// Add to the sub-tables
	for (size_t j = 0; j < max; j++) {
		Table* const subtable = table.GetTablePtr(0, j);
		for (size_t i = 0; i < max; i++) {
			subtable->InsertInt(0, i, 42+j*100);
			subtable->InsertString(1, i, i ? "test" : "testing");
			subtable->InsertDone();
		}
		delete subtable;
	}
#endif

	// Write the group to disk
	group.Write(filename);	
}

void testgroup4(const char *filename) {
	Group group;
	TopLevelTable& table = group.GetTable("test");

	table.RegisterColumn(COLUMN_TYPE_INT, "ints");
	table.RegisterColumn(COLUMN_TYPE_MIXED, "Mixed");
	
	const size_t ndx = table.AddRow();
	table.Set(0, ndx, 0);
	table.SetMixed(1, ndx, true);

	table.InsertInt(0, 1, 43);
	table.InsertMixed(1, 1, (int64_t)12);
	table.InsertDone();

	table.InsertInt(0, 2, 100);
	table.InsertMixed(1, 2, "test");
	table.InsertDone();
	
	table.InsertInt(0, 3, 0);
	table.InsertMixed(1, 3, Date(324234));
	table.InsertDone();

	table.InsertInt(0, 4, 43);
	table.InsertMixed(1, 4, Mixed("binary", 7));
	table.InsertDone();

	table.InsertInt(0, 5, 1778);
	table.InsertMixed(1, 5, Date(324234));
	table.InsertDone();

	table.InsertInt(0, 6, 1778);
	table.InsertMixed(1, 6, Mixed(COLUMN_TYPE_TABLE));
	table.InsertDone();

#if 1
	// Get table from mixed column and add schema and some values
	Table* const subtable = table.GetTablePtr(1, 6);
	subtable->RegisterColumn(COLUMN_TYPE_STRING, "name");
	subtable->RegisterColumn(COLUMN_TYPE_INT,    "age");
	
	subtable->InsertString(0, 0, "John");
	subtable->InsertInt(1, 0, 40);
	subtable->InsertDone();
	subtable->InsertString(0, 1, "Svendåge");
	subtable->InsertInt(1, 1, 113);
	subtable->InsertDone();

	delete subtable;
#endif
	// Write the group to disk
	group.Write(filename);
}

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

void testgroup_misc2()
{
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


int main() {
    testgroup_misc2();
    return 0;
}
