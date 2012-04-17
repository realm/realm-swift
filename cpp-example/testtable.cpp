#include "tightdb.h"
#include <UnitTest++.h>

TEST(Table1) {
	Table table;
	table.RegisterColumn(COLUMN_TYPE_INT, "first");
	table.RegisterColumn(COLUMN_TYPE_INT, "second");

	CHECK_EQUAL(COLUMN_TYPE_INT, table.GetColumnType(0));
	CHECK_EQUAL(COLUMN_TYPE_INT, table.GetColumnType(1));
	CHECK_EQUAL("first", table.GetColumnName(0));
	CHECK_EQUAL("second", table.GetColumnName(1));

	const size_t ndx = table.AddRow();
	table.Set(0, ndx, 0);
	table.Set(1, ndx, 10);

	CHECK_EQUAL(0, table.Get(0, ndx));
	CHECK_EQUAL(10, table.Get(1, ndx));

#ifdef _DEBUG
	table.Verify();
#endif //_DEBUG
}

enum Days {
	Mon,
	Tue,
	Wed,
	Thu,
	Fri,
	Sat,
	Sun
};

TDB_TABLE_4(TestTable,
			Int,        first,
			Int,        second,
			Bool,       third,
			Enum<Days>, fourth)

TEST(Table2) {
	TestTable table;

	table.Add(0, 10, true, Wed);
	const TestTable::Cursor r = table[-1]; // last item

	CHECK_EQUAL(0, r.first);
	CHECK_EQUAL(10, r.second);
	CHECK_EQUAL(true, r.third);
	CHECK_EQUAL(Wed, r.fourth);

#ifdef _DEBUG
	table.Verify();
#endif //_DEBUG
}

TEST(Table3) {
	TestTable table;

	for (size_t i = 0; i < 100; ++i) {
		table.Add(0, 10, true, Wed);
	}

	// Test column searching
	CHECK_EQUAL((size_t)0, table.first.Find(0));
	CHECK_EQUAL((size_t)-1, table.first.Find(1));
	CHECK_EQUAL((size_t)0, table.second.Find(10));
	CHECK_EQUAL((size_t)-1, table.second.Find(100));
	CHECK_EQUAL((size_t)0, table.third.Find(true));
	CHECK_EQUAL((size_t)-1, table.third.Find(false));
	CHECK_EQUAL((size_t)0, table.fourth.Find(Wed));
	CHECK_EQUAL((size_t)-1, table.fourth.Find(Mon));

	// Test column incrementing
	table.first += 3;
	CHECK_EQUAL(3, table[0].first);
	CHECK_EQUAL(3, table[99].first);

#ifdef _DEBUG
	table.Verify();
#endif //_DEBUG
}

TDB_TABLE_2(TestTableEnum,
			Enum<Days>, first,
			String, second)

TEST(Table4) {
	TestTableEnum table;

	table.Add(Mon, "Hello");
	table.Add(Mon, "HelloHelloHelloHelloHelloHelloHelloHelloHelloHelloHelloHelloHelloHelloHello");
	const TestTableEnum::Cursor r = table[-1]; // last item

	CHECK_EQUAL(Mon, r.first);
	CHECK_EQUAL("HelloHelloHelloHelloHelloHelloHelloHelloHelloHelloHelloHelloHelloHelloHello", (const char*)r.second);

	// Test string column searching
	CHECK_EQUAL((size_t)1, table.second.Find("HelloHelloHelloHelloHelloHelloHelloHelloHelloHelloHelloHelloHelloHelloHello"));
	CHECK_EQUAL((size_t)-1, table.second.Find("Foo"));

#ifdef _DEBUG
	table.Verify();
#endif //_DEBUG
}

TEST(Table_Delete) {
	TestTable table;

	for (size_t i = 0; i < 10; ++i) {
		table.Add(0, i, true, Wed);
	}

	table.DeleteRow(0);
	table.DeleteRow(4);
	table.DeleteRow(7);

	CHECK_EQUAL(1, table[0].second);
	CHECK_EQUAL(2, table[1].second);
	CHECK_EQUAL(3, table[2].second);
	CHECK_EQUAL(4, table[3].second);
	CHECK_EQUAL(6, table[4].second);
	CHECK_EQUAL(7, table[5].second);
	CHECK_EQUAL(8, table[6].second);

#ifdef _DEBUG
	table.Verify();
#endif //_DEBUG

	// Delete all items one at a time
	for (size_t i = 0; i < 7; ++i) {
		table.DeleteRow(0);
	}

	CHECK(table.IsEmpty());
	CHECK_EQUAL(0, table.GetSize());

#ifdef _DEBUG
	table.Verify();
#endif //_DEBUG
}

TEST(Table_Delete_All_Types) {
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
			Table subtable = table.GetTable(8, i);
			subtable.InsertInt(0, 0, 42);
			subtable.InsertString(1, 0, "meaning");
			subtable.InsertDone();
		}
	}
	
	// We also want a ColumnStringEnum
	table.Optimize();
	
	// Test Deletes
	table.DeleteRow(14);
	table.DeleteRow(0);
	table.DeleteRow(5);
	
	CHECK_EQUAL(12, table.GetSize());
	
#ifdef _DEBUG
	table.Verify();
#endif //_DEBUG
	
	// Test Clear
	table.Clear();
	CHECK_EQUAL(0, table.GetSize());
	
#ifdef _DEBUG
	table.Verify();
#endif //_DEBUG
}

TEST(Table_Find_Int) {
	TestTable table;

	for (int i = 1000; i >= 0; --i) {
		table.Add(0, i, true, Wed);
	}

	CHECK_EQUAL((size_t)0, table.second.Find(1000));
	CHECK_EQUAL((size_t)1000, table.second.Find(0));
	CHECK_EQUAL((size_t)-1, table.second.Find(1001));

#ifdef _DEBUG
	table.Verify();
#endif //_DEBUG
}

TEST(Table6) {
	TestTableEnum table;

	TDB_QUERY(TestQuery, TestTableEnum) {
	//	first.between(Mon, Thu);
		second == "Hello" || (second == "Hey" && first == Mon);
	}};

	TDB_QUERY_OPT(TestQuery2, TestTableEnum) (Days a, Days b, const char* str) {
		(void)b;
		(void)a;
		//first.between(a, b);
		second == str || second.MatchRegEx(".*");
	}};

	//TestTableEnum result = table.FindAll(TestQuery2(Mon, Tue, "Hello")).Sort().Limit(10);
	//size_t result2 = table.Range(10, 200).Find(TestQuery());
	//CHECK_EQUAL((size_t)-1, result2);

#ifdef _DEBUG
	table.Verify();
#endif //_DEBUG
}



TEST(Table_FindAll_Int) {
	TestTable table;

	table.Add(0, 10, true, Wed);
	table.Add(0, 20, true, Wed);
	table.Add(0, 10, true, Wed);
	table.Add(0, 20, true, Wed);
	table.Add(0, 10, true, Wed);
	table.Add(0, 20, true, Wed);
	table.Add(0, 10, true, Wed);
	table.Add(0, 20, true, Wed);
	table.Add(0, 10, true, Wed);
	table.Add(0, 20, true, Wed);

	// Search for a value that does not exits
	const TableView v0 = table.second.FindAll(5);
	CHECK_EQUAL(0, v0.GetSize());

	// Search for a value with several matches
	const TableView v = table.second.FindAll(20);

	CHECK_EQUAL(5, v.GetSize());
	CHECK_EQUAL(1, v.GetRef(0));
	CHECK_EQUAL(3, v.GetRef(1));
	CHECK_EQUAL(5, v.GetRef(2));
	CHECK_EQUAL(7, v.GetRef(3));
	CHECK_EQUAL(9, v.GetRef(4));

#ifdef _DEBUG
	table.Verify();
#endif //_DEBUG
}

TEST(Table_Index_Int) {
	TestTable table;

	table.Add(0,  1, true, Wed);
	table.Add(0, 15, true, Wed);
	table.Add(0, 10, true, Wed);
	table.Add(0, 20, true, Wed);
	table.Add(0, 11, true, Wed);
	table.Add(0, 45, true, Wed);
	table.Add(0, 10, true, Wed);
	table.Add(0,  0, true, Wed);
	table.Add(0, 30, true, Wed);
	table.Add(0,  9, true, Wed);

	// Create index for column two
	table.SetIndex(1);

	// Search for a value that does not exits
	const size_t r1 = table.second.Find(2);
	CHECK_EQUAL(-1, r1);

	// Find existing values
	CHECK_EQUAL(0, table.second.Find(1));
	CHECK_EQUAL(1, table.second.Find(15));
	CHECK_EQUAL(2, table.second.Find(10));
	CHECK_EQUAL(3, table.second.Find(20));
	CHECK_EQUAL(4, table.second.Find(11));
	CHECK_EQUAL(5, table.second.Find(45)); 
	//CHECK_EQUAL(6, table.second.Find(10)); // only finds first match
	CHECK_EQUAL(7, table.second.Find(0));
	CHECK_EQUAL(8, table.second.Find(30));
	CHECK_EQUAL(9, table.second.Find(9));

	// Change some values
	table[2].second = 13;
	table[9].second = 100;

	CHECK_EQUAL(0, table.second.Find(1));
	CHECK_EQUAL(1, table.second.Find(15));
	CHECK_EQUAL(2, table.second.Find(13));
	CHECK_EQUAL(3, table.second.Find(20));
	CHECK_EQUAL(4, table.second.Find(11));
	CHECK_EQUAL(5, table.second.Find(45)); 
	CHECK_EQUAL(6, table.second.Find(10));
	CHECK_EQUAL(7, table.second.Find(0));
	CHECK_EQUAL(8, table.second.Find(30));
	CHECK_EQUAL(9, table.second.Find(100));

	// Insert values
	table.Add(0, 29, true, Wed);
	//TODO: More than add

	CHECK_EQUAL(0, table.second.Find(1));
	CHECK_EQUAL(1, table.second.Find(15));
	CHECK_EQUAL(2, table.second.Find(13));
	CHECK_EQUAL(3, table.second.Find(20));
	CHECK_EQUAL(4, table.second.Find(11));
	CHECK_EQUAL(5, table.second.Find(45)); 
	CHECK_EQUAL(6, table.second.Find(10));
	CHECK_EQUAL(7, table.second.Find(0));
	CHECK_EQUAL(8, table.second.Find(30));
	CHECK_EQUAL(9, table.second.Find(100));
	CHECK_EQUAL(10, table.second.Find(29));

	// Delete some values
	table.DeleteRow(0);
	table.DeleteRow(5);
	table.DeleteRow(8);

	CHECK_EQUAL(0, table.second.Find(15));
	CHECK_EQUAL(1, table.second.Find(13));
	CHECK_EQUAL(2, table.second.Find(20));
	CHECK_EQUAL(3, table.second.Find(11));
	CHECK_EQUAL(4, table.second.Find(45)); 
	CHECK_EQUAL(5, table.second.Find(0));
	CHECK_EQUAL(6, table.second.Find(30));
	CHECK_EQUAL(7, table.second.Find(100));

#ifdef _DEBUG
	table.Verify();
#endif //_DEBUG
}

TDB_TABLE_4(TestTableAE,
			Int,        first,
			String,     second,
			Bool,       third,
			Enum<Days>, fourth)

TEST(TableAutoEnumeration) {
	TestTableAE table;

	for (size_t i = 0; i < 5; ++i) {
		table.Add(1, "abd",     true, Mon);
		table.Add(2, "eftg",    true, Tue);
		table.Add(5, "hijkl",   true, Wed);
		table.Add(8, "mnopqr",  true, Thu);
		table.Add(9, "stuvxyz", true, Fri);
	}

	table.Optimize();

	for (size_t i = 0; i < 5; ++i) {
		const size_t n = i * 5;
		CHECK_EQUAL(1, table[0+n].first);
		CHECK_EQUAL(2, table[1+n].first);
		CHECK_EQUAL(5, table[2+n].first);
		CHECK_EQUAL(8, table[3+n].first);
		CHECK_EQUAL(9, table[4+n].first);

		CHECK_EQUAL("abd",     (const char*)table[0+n].second);
		CHECK_EQUAL("eftg",    (const char*)table[1+n].second);
		CHECK_EQUAL("hijkl",   (const char*)table[2+n].second);
		CHECK_EQUAL("mnopqr",  (const char*)table[3+n].second);
		CHECK_EQUAL("stuvxyz", (const char*)table[4+n].second);

		CHECK_EQUAL(true, table[0+n].third);
		CHECK_EQUAL(true, table[1+n].third);
		CHECK_EQUAL(true, table[2+n].third);
		CHECK_EQUAL(true, table[3+n].third);
		CHECK_EQUAL(true, table[4+n].third);

		CHECK_EQUAL(Mon, table[0+n].fourth);
		CHECK_EQUAL(Tue, table[1+n].fourth);
		CHECK_EQUAL(Wed, table[2+n].fourth);
		CHECK_EQUAL(Thu, table[3+n].fourth);
		CHECK_EQUAL(Fri, table[4+n].fourth);
	}


}


TEST(TableAutoEnumerationFindFindAll) {
	TestTableAE table;

	for (size_t i = 0; i < 5; ++i) {
		table.Add(1, "abd",     true, Mon);
		table.Add(2, "eftg",    true, Tue);
		table.Add(5, "hijkl",   true, Wed);
		table.Add(8, "mnopqr",  true, Thu);
		table.Add(9, "stuvxyz", true, Fri);
	}

	table.Optimize();

	size_t t = table.second.Find("eftg");
	CHECK_EQUAL(1, t);

	TableView tv = table.second.FindAll("eftg");
	CHECK_EQUAL(5, tv.GetSize());
	CHECK_EQUAL("eftg", tv.GetString(1, 0));
	CHECK_EQUAL("eftg", tv.GetString(1, 1));
	CHECK_EQUAL("eftg", tv.GetString(1, 2));
	CHECK_EQUAL("eftg", tv.GetString(1, 3));
	CHECK_EQUAL("eftg", tv.GetString(1, 4));
}

#include "AllocSlab.h"
TEST(Table_SlabAlloc) {
	SlabAlloc alloc;
	TestTable table(alloc);

	table.Add(0, 10, true, Wed);
	const TestTable::Cursor r = table[-1]; // last item

	CHECK_EQUAL(   0, r.first);
	CHECK_EQUAL(  10, r.second);
	CHECK_EQUAL(true, r.third);
	CHECK_EQUAL( Wed, r.fourth);

	// Add some more rows
	table.Add(1, 10, true, Wed);
	table.Add(2, 20, true, Wed);
	table.Add(3, 10, true, Wed);
	table.Add(4, 20, true, Wed);
	table.Add(5, 10, true, Wed);

	// Delete some rows
	table.DeleteRow(2);
	table.DeleteRow(4);

#ifdef _DEBUG
	table.Verify();
#endif //_DEBUG
}

#include "Group.h"
TEST(Table_Spec) {
	Group group;
	TopLevelTable& table = group.GetTable("test");

	// Create specification with sub-table
	Spec s = table.GetSpec();
	s.AddColumn(COLUMN_TYPE_INT,    "first");
	s.AddColumn(COLUMN_TYPE_STRING, "second");
	Spec sub = s.AddColumnTable(    "third");
		sub.AddColumn(COLUMN_TYPE_INT,    "sub_first");
		sub.AddColumn(COLUMN_TYPE_STRING, "sub_second");
	table.UpdateFromSpec(s.GetRef());

	CHECK_EQUAL(3, table.GetColumnCount());

	// Add a row
	table.InsertInt(0, 0, 4);
	table.InsertString(1, 0, "Hello");
	table.InsertTable(2, 0);
	table.InsertDone();

	CHECK_EQUAL(0, table.GetTableSize(2, 0));

	// Get the sub-table
	{
		Table subtable = table.GetTable(2, 0);
		CHECK(subtable.IsEmpty());

		subtable.InsertInt(0, 0, 42);
		subtable.InsertString(1, 0, "test");
		subtable.InsertDone();

		CHECK_EQUAL(42,     subtable.Get(0, 0));
		CHECK_EQUAL("test", subtable.GetString(1, 0));
	}

	// Get the sub-table again and see if the values
	// still match.
	{
		const Table subtable = table.GetTable(2, 0);

		CHECK_EQUAL(1,      subtable.GetSize());
		CHECK_EQUAL(42,     subtable.Get(0, 0));
		CHECK_EQUAL("test", subtable.GetString(1, 0));
	}

	// Write the group to disk
	group.Write("subtables.tightdb");

	// Read back tables
	Group fromDisk("subtables.tightdb");
	TopLevelTable& fromDiskTable = fromDisk.GetTable("test");

	const Table subtable2 = fromDiskTable.GetTable(2, 0);

	CHECK_EQUAL(1,      subtable2.GetSize());
	CHECK_EQUAL(42,     subtable2.Get(0, 0));
	CHECK_EQUAL("test", subtable2.GetString(1, 0));
}

TEST(Table_Mixed) {
	Table table;
	table.RegisterColumn(COLUMN_TYPE_INT, "first");
	table.RegisterColumn(COLUMN_TYPE_MIXED, "second");
	
	CHECK_EQUAL(COLUMN_TYPE_INT, table.GetColumnType(0));
	CHECK_EQUAL(COLUMN_TYPE_MIXED, table.GetColumnType(1));
	CHECK_EQUAL("first", table.GetColumnName(0));
	CHECK_EQUAL("second", table.GetColumnName(1));
	
	const size_t ndx = table.AddRow();
	table.Set(0, ndx, 0);
	table.SetMixed(1, ndx, true);
	
	CHECK_EQUAL(0, table.Get(0, 0));
	CHECK_EQUAL(COLUMN_TYPE_BOOL, table.GetMixed(1, 0).GetType());
	CHECK_EQUAL(true, table.GetMixed(1, 0).GetBool());
	
	table.InsertInt(0, 1, 43);
	table.InsertMixed(1, 1, (int64_t)12);
	table.InsertDone();
	
	CHECK_EQUAL(0,  table.Get(0, ndx));
	CHECK_EQUAL(43, table.Get(0, 1));
	CHECK_EQUAL(COLUMN_TYPE_BOOL, table.GetMixed(1, 0).GetType());
	CHECK_EQUAL(COLUMN_TYPE_INT,  table.GetMixed(1, 1).GetType());
	CHECK_EQUAL(true, table.GetMixed(1, 0).GetBool());
	CHECK_EQUAL(12,   table.GetMixed(1, 1).GetInt());
	
	table.InsertInt(0, 2, 100);
	table.InsertMixed(1, 2, "test");
	table.InsertDone();
	
	CHECK_EQUAL(0,  table.Get(0, 0));
	CHECK_EQUAL(43, table.Get(0, 1));
	CHECK_EQUAL(COLUMN_TYPE_BOOL,   table.GetMixed(1, 0).GetType());
	CHECK_EQUAL(COLUMN_TYPE_INT,    table.GetMixed(1, 1).GetType());
	CHECK_EQUAL(COLUMN_TYPE_STRING, table.GetMixed(1, 2).GetType());
	CHECK_EQUAL(true,   table.GetMixed(1, 0).GetBool());
	CHECK_EQUAL(12,     table.GetMixed(1, 1).GetInt());
	CHECK_EQUAL("test", table.GetMixed(1, 2).GetString());
	
	table.InsertInt(0, 3, 0);
	table.InsertMixed(1, 3, Date(324234));
	table.InsertDone();
	
	CHECK_EQUAL(0,  table.Get(0, 0));
	CHECK_EQUAL(43, table.Get(0, 1));
	CHECK_EQUAL(0,  table.Get(0, 3));
	CHECK_EQUAL(COLUMN_TYPE_BOOL,   table.GetMixed(1, 0).GetType());
	CHECK_EQUAL(COLUMN_TYPE_INT,    table.GetMixed(1, 1).GetType());
	CHECK_EQUAL(COLUMN_TYPE_STRING, table.GetMixed(1, 2).GetType());
	CHECK_EQUAL(COLUMN_TYPE_DATE,   table.GetMixed(1, 3).GetType());
	CHECK_EQUAL(true,   table.GetMixed(1, 0).GetBool());
	CHECK_EQUAL(12,     table.GetMixed(1, 1).GetInt());
	CHECK_EQUAL("test", table.GetMixed(1, 2).GetString());
	CHECK_EQUAL(324234, table.GetMixed(1, 3).GetDate());
	
	table.InsertInt(0, 4, 43);
	table.InsertMixed(1, 4, Mixed("binary", 7));
	table.InsertDone();
	
	CHECK_EQUAL(0,  table.Get(0, 0));
	CHECK_EQUAL(43, table.Get(0, 1));
	CHECK_EQUAL(0,  table.Get(0, 3));
	CHECK_EQUAL(43, table.Get(0, 4));
	CHECK_EQUAL(COLUMN_TYPE_BOOL,   table.GetMixed(1, 0).GetType());
	CHECK_EQUAL(COLUMN_TYPE_INT,    table.GetMixed(1, 1).GetType());
	CHECK_EQUAL(COLUMN_TYPE_STRING, table.GetMixed(1, 2).GetType());
	CHECK_EQUAL(COLUMN_TYPE_DATE,   table.GetMixed(1, 3).GetType());
	CHECK_EQUAL(COLUMN_TYPE_BINARY, table.GetMixed(1, 4).GetType());
	CHECK_EQUAL(true,   table.GetMixed(1, 0).GetBool());
	CHECK_EQUAL(12,     table.GetMixed(1, 1).GetInt());
	CHECK_EQUAL("test", table.GetMixed(1, 2).GetString());
	CHECK_EQUAL(324234, table.GetMixed(1, 3).GetDate());
	CHECK_EQUAL("binary", (const char*)table.GetMixed(1, 4).GetBinary().pointer);
	CHECK_EQUAL(7,      table.GetMixed(1, 4).GetBinary().len);
	
	table.InsertInt(0, 5, 0);
	table.InsertMixed(1, 5, Mixed(COLUMN_TYPE_TABLE));
	table.InsertDone();
	
	CHECK_EQUAL(0,  table.Get(0, 0));
	CHECK_EQUAL(43, table.Get(0, 1));
	CHECK_EQUAL(0,  table.Get(0, 3));
	CHECK_EQUAL(43, table.Get(0, 4));
	CHECK_EQUAL(0,  table.Get(0, 5));
	CHECK_EQUAL(COLUMN_TYPE_BOOL,   table.GetMixed(1, 0).GetType());
	CHECK_EQUAL(COLUMN_TYPE_INT,    table.GetMixed(1, 1).GetType());
	CHECK_EQUAL(COLUMN_TYPE_STRING, table.GetMixed(1, 2).GetType());
	CHECK_EQUAL(COLUMN_TYPE_DATE,   table.GetMixed(1, 3).GetType());
	CHECK_EQUAL(COLUMN_TYPE_BINARY, table.GetMixed(1, 4).GetType());
	CHECK_EQUAL(COLUMN_TYPE_TABLE,  table.GetMixed(1, 5).GetType());
	CHECK_EQUAL(true,   table.GetMixed(1, 0).GetBool());
	CHECK_EQUAL(12,     table.GetMixed(1, 1).GetInt());
	CHECK_EQUAL("test", table.GetMixed(1, 2).GetString());
	CHECK_EQUAL(324234, table.GetMixed(1, 3).GetDate());
	CHECK_EQUAL("binary", (const char*)table.GetMixed(1, 4).GetBinary().pointer);
	CHECK_EQUAL(7,      table.GetMixed(1, 4).GetBinary().len);
	
	// Get table from mixed column and add schema and some values
	Table* const subtable = table.GetTablePtr(1, 5);
	subtable->RegisterColumn(COLUMN_TYPE_STRING, "name");
	subtable->RegisterColumn(COLUMN_TYPE_INT,    "age");
	
	subtable->InsertString(0, 0, "John");
	subtable->InsertInt(1, 0, 40);
	delete subtable;
	
	// Get same table again and verify values
	Table* const subtable2 = table.GetTablePtr(1, 5);
	CHECK_EQUAL(1, subtable2->GetSize());
	CHECK_EQUAL("John", subtable2->GetString(0, 0));
	CHECK_EQUAL(40, subtable2->Get(1, 0));
	delete subtable2;
#ifdef _DEBUG
	table.Verify();
#endif //_DEBUG
}

TDB_TABLE_1(TestTableMX,
			Mixed,  first)


TEST(Table_Mixed2) {
	TestTableMX table;
	
	table.Add((int64_t)1);
	table.Add(true);
	table.Add(Date(1234));
	table.Add("test");

	CHECK_EQUAL(COLUMN_TYPE_INT,    table[0].first.GetType());
	CHECK_EQUAL(COLUMN_TYPE_BOOL,   table[1].first.GetType());
	CHECK_EQUAL(COLUMN_TYPE_DATE,   table[2].first.GetType());
	CHECK_EQUAL(COLUMN_TYPE_STRING, table[3].first.GetType());
	
	CHECK_EQUAL(1,            table[0].first.GetInt());
	CHECK_EQUAL(true,         table[1].first.GetBool());
	CHECK_EQUAL((time_t)1234, table[2].first.GetDate());
	CHECK_EQUAL("test",       table[3].first.GetString());
}
