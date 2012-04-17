#include "Group.h"
#include "tightdb.h"
#include <UnitTest++.h>

enum Days {
	Mon,
	Tue,
	Wed,
	Thu,
	Fri,
	Sat,
	Sun
};

TDB_TABLE_4(TestTableGroup,
			String,     first,
			Int,        second,
			Bool,       third,
			Enum<Days>, fourth)

// Windows version of serialization is not implemented yet
#if 1 //_MSC_VER

TEST(Group_Invalid1) {
	// Delete old file if there
	remove("table_test.tbl");

	// Try to open non-existing file
	Group fromDisk("table_test.tbl");
	CHECK(!fromDisk.IsValid());
}

TEST(Group_Invalid2) {
	// Try to open buffer with invalid data
	const char* const buffer = "invalid data";
	Group fromMen(buffer, strlen(buffer));
	CHECK(!fromMen.IsValid());
}

TEST(Group_Serialize0) {
	// Create empty group and serialize to disk
	Group toDisk;
	toDisk.Write("table_test.tbl");

	// Load the group
	Group fromDisk("table_test.tbl");
	CHECK(fromDisk.IsValid());

	// Create new table in group
	TestTableGroup& t = fromDisk.GetTable<TestTableGroup>("test");

	CHECK_EQUAL(4, t.GetColumnCount());
	CHECK_EQUAL(0, t.GetSize());

	// Modify table
	t.Add("Test",  1, true, Wed);

	CHECK_EQUAL("Test", (const char*)t[0].first);
	CHECK_EQUAL(1,      t[0].second);
	CHECK_EQUAL(true,   t[0].third);
	CHECK_EQUAL(Wed,    t[0].fourth);
}

TEST(Group_Read0) {
	// Load the group and let it clean up without loading
	// any tables
	Group fromDisk("table_test.tbl");
	CHECK(fromDisk.IsValid());
}

TEST(Group_Serialize1) {
	// Create group with one table
	Group toDisk;
	TestTableGroup& table = toDisk.GetTable<TestTableGroup>("test");
	table.Add("",  1, true, Wed);
	table.Add("", 15, true, Wed);
	table.Add("", 10, true, Wed);
	table.Add("", 20, true, Wed);
	table.Add("", 11, true, Wed);
	table.Add("", 45, true, Wed);
	table.Add("", 10, true, Wed);
	table.Add("",  0, true, Wed);
	table.Add("", 30, true, Wed);
	table.Add("",  9, true, Wed);

#ifdef _DEBUG
	toDisk.Verify();
#endif //_DEBUG

	// Delete old file if there
	remove("table_test.tbl");

	// Serialize to disk
	toDisk.Write("table_test.tbl");

	// Load the table
	Group fromDisk("table_test.tbl");
	CHECK(fromDisk.IsValid());
	TestTableGroup& t = fromDisk.GetTable<TestTableGroup>("test");

	CHECK_EQUAL(4, t.GetColumnCount());
	CHECK_EQUAL(10, t.GetSize());

#ifdef _DEBUG
	// Verify that original values are there
	CHECK(table.Compare(t));
#endif

	// Modify both tables
	table[0].first = "test";
	t[0].first = "test";
	table.Insert(5, "hello", 100, false, Mon);
	t.Insert(5, "hello", 100, false, Mon);
	table.DeleteRow(1);
	t.DeleteRow(1);

#ifdef _DEBUG
	// Verify that both changed correctly
	CHECK(table.Compare(t));
	toDisk.Verify();
	fromDisk.Verify();
#endif //_DEBUG
}

TEST(Group_Read1) {
	// Load the group and let it clean up without loading
	// any tables
	Group fromDisk("table_test.tbl");
	CHECK(fromDisk.IsValid());
}

TEST(Group_Serialize2) {
	// Create group with two tables
	Group toDisk;
	TestTableGroup& table1 = toDisk.GetTable<TestTableGroup>("test1");
	table1.Add("",  1, true, Wed);
	table1.Add("", 15, true, Wed);
	table1.Add("", 10, true, Wed);

	TestTableGroup& table2 = toDisk.GetTable<TestTableGroup>("test2");
	table2.Add("hey",  0, true, Tue);
	table2.Add("hello", 3232, false, Sun);

#ifdef _DEBUG
	toDisk.Verify();
#endif //_DEBUG

	// Delete old file if there
	remove("table_test.tbl");

	// Serialize to disk
	toDisk.Write("table_test.tbl");

	// Load the tables
	Group fromDisk("table_test.tbl");
	CHECK(fromDisk.IsValid());
	TestTableGroup& t1 = fromDisk.GetTable<TestTableGroup>("test1");
	TestTableGroup& t2 = fromDisk.GetTable<TestTableGroup>("test2");
	(void)t2;
	(void)t1;

#ifdef _DEBUG
	// Verify that original values are there
	CHECK(table1.Compare(t1));
	CHECK(table2.Compare(t2));
	toDisk.Verify();
	fromDisk.Verify();
#endif //_DEBUG
}

TEST(Group_Serialize3) {
	// Create group with one table (including long strings
	Group toDisk;
	TestTableGroup& table = toDisk.GetTable<TestTableGroup>("test");
	table.Add("1 xxxxxxxx xxxxxxxx xxxxxxxx xxxxxxxx xxxxxxxx xxxxxxxx xxxxxxxx xxxxxxxx 1",  1, true, Wed);
	table.Add("2 xxxxxxxx xxxxxxxx xxxxxxxx xxxxxxxx xxxxxxxx xxxxxxxx xxxxxxxx xxxxxxxx 2", 15, true, Wed);

#ifdef _DEBUG
	toDisk.Verify();
#endif //_DEBUG

	// Delete old file if there
	remove("table_test.tbl");

	// Serialize to disk
	toDisk.Write("table_test.tbl");

	// Load the table
	Group fromDisk("table_test.tbl");
	CHECK(fromDisk.IsValid());
	TestTableGroup& t = fromDisk.GetTable<TestTableGroup>("test");
	(void)t;


#ifdef _DEBUG
	// Verify that original values are there
	CHECK(table.Compare(t));
	toDisk.Verify();
	fromDisk.Verify();
#endif //_DEBUG}
}

TEST(Group_Serialize_Men) {
	// Create group with one table
	Group toMem;
	TestTableGroup& table = toMem.GetTable<TestTableGroup>("test");
	table.Add("",  1, true, Wed);
	table.Add("", 15, true, Wed);
	table.Add("", 10, true, Wed);
	table.Add("", 20, true, Wed);
	table.Add("", 11, true, Wed);
	table.Add("", 45, true, Wed);
	table.Add("", 10, true, Wed);
	table.Add("",  0, true, Wed);
	table.Add("", 30, true, Wed);
	table.Add("",  9, true, Wed);

#ifdef _DEBUG
	toMem.Verify();
#endif //_DEBUG

	// Serialize to memory (we now own the buffer)
	size_t len;
	const char* const buffer = toMem.WriteToMem(len);

	// Load the table
	Group fromMem(buffer, len);
	CHECK(fromMem.IsValid());
	TestTableGroup& t = fromMem.GetTable<TestTableGroup>("test");

	CHECK_EQUAL(4, t.GetColumnCount());
	CHECK_EQUAL(10, t.GetSize());


#ifdef _DEBUG
	// Verify that original values are there
	CHECK(table.Compare(t));
	toMem.Verify();
	fromMem.Verify();
#endif //_DEBUG
}

TEST(Group_Serialize_Optimized) {
	// Create group with one table
	Group toMem;
	TestTableGroup& table = toMem.GetTable<TestTableGroup>("test");

	for (size_t i = 0; i < 5; ++i) {
		table.Add("abd",     1, true, Mon);
		table.Add("eftg",    2, true, Tue);
		table.Add("hijkl",   5, true, Wed);
		table.Add("mnopqr",  8, true, Thu);
		table.Add("stuvxyz", 9, true, Fri);
	}

	table.Optimize();

#ifdef _DEBUG
	toMem.Verify();
#endif //_DEBUG

	// Serialize to memory (we now own the buffer)
	size_t len;
	const char* const buffer = toMem.WriteToMem(len);

	// Load the table
	Group fromMem(buffer, len);
	CHECK(fromMem.IsValid());
	TestTableGroup& t = fromMem.GetTable<TestTableGroup>("test");

	CHECK_EQUAL(4, t.GetColumnCount());

	// Verify that original values are there
#ifdef _DEBUG
	CHECK(table.Compare(t));
#endif

	// Add a row with a known (but unique) value
	table.Add("search_target", 9, true, Fri);

	const size_t res = table.first.Find("search_target");
	CHECK_EQUAL(table.GetSize()-1, res);

#ifdef _DEBUG
	toMem.Verify();
	fromMem.Verify();
#endif //_DEBUG
}

TEST(Group_Serialize_All) {
	// Create group with one table
	Group toMem;
	Table& table = toMem.GetTable("test");
	
	table.RegisterColumn(COLUMN_TYPE_INT,    "int");
	table.RegisterColumn(COLUMN_TYPE_BOOL,   "bool");
	table.RegisterColumn(COLUMN_TYPE_DATE,   "date");
	table.RegisterColumn(COLUMN_TYPE_STRING, "string");
	table.RegisterColumn(COLUMN_TYPE_BINARY, "binary");
	table.RegisterColumn(COLUMN_TYPE_MIXED,  "mixed");
	
	table.InsertInt(0, 0, 12);
	table.InsertBool(1, 0, true);
	table.InsertDate(2, 0, 12345);
	table.InsertString(3, 0, "test");
	table.InsertBinary(4, 0, "binary", 7);
	table.InsertMixed(5, 0, false);
	table.InsertDone();
	
	// Serialize to memory (we now own the buffer)
	size_t len;
	const char* const buffer = toMem.WriteToMem(len);
	
	// Load the table
	Group fromMem(buffer, len);
	CHECK(fromMem.IsValid());
	Table& t = fromMem.GetTable("test");
	
	CHECK_EQUAL(6, t.GetColumnCount());
	CHECK_EQUAL(1, t.GetSize());
}


TEST(Group_Subtable) {
	int n = 150;

	Group g;
	TopLevelTable &table = g.GetTable("test");
	Spec s = table.GetSpec();
	s.AddColumn(COLUMN_TYPE_INT, "foo");
	Spec sub = s.AddColumnTable("sub");
	sub.AddColumn(COLUMN_TYPE_INT, "bar");
	s.AddColumn(COLUMN_TYPE_MIXED, "baz");
	table.UpdateFromSpec(s.GetRef());

	for (int i=0; i<n; ++i) {
		table.AddRow();
		table.Set(0, i, 100+i);
		if (i%2 == 0) {
			Table st = table.GetTable(1, i);
			st.AddRow();
			st.Set(0, 0, 200+i);
		}
		if (i%3 == 1) {
			table.SetMixed(2, i, Mixed(COLUMN_TYPE_TABLE));
			TopLevelTable st = table.GetMixedTable(2, i);
			st.RegisterColumn(COLUMN_TYPE_INT, "banach");
			st.AddRow();
			st.Set(0, 0, 700+i);
		}
	}

	CHECK_EQUAL(table.GetSize(), n);

	for (int i=0; i<n; ++i) {
		CHECK_EQUAL(table.Get(0, i), 100+i);
		{
			Table st = table.GetTable(1, i);
			CHECK_EQUAL(st.GetSize(), i%2 == 0 ? 1 : 0);
			if (i%2 == 0) CHECK_EQUAL(st.Get(0,0), 200+i);
			if (i%3 == 0) {
				st.AddRow();
				st.Set(0, st.GetSize()-1, 300+i);
			}
		}
		CHECK_EQUAL(table.GetMixedType(2,i), i%3 == 1 ? COLUMN_TYPE_TABLE : COLUMN_TYPE_INT);
		if (i%3 == 1) {
			TopLevelTable st = table.GetMixedTable(2, i);
			CHECK_EQUAL(st.GetSize(), 1);
			CHECK_EQUAL(st.Get(0,0), 700+i);
		}
		if (i%8 == 3) {
			if (i%3 != 1) table.SetMixed(2, i, Mixed(COLUMN_TYPE_TABLE));
			TopLevelTable st = table.GetMixedTable(2, i);
			if (i%3 != 1) st.RegisterColumn(COLUMN_TYPE_INT, "banach");
			st.AddRow();
			st.Set(0, st.GetSize()-1, 800+i);
		}
	}

	for (int i=0; i<n; ++i) {
		CHECK_EQUAL(table.Get(0, i), 100+i);
		{
			Table st = table.GetTable(1, i);
			size_t expected_size = (i%2 == 0 ? 1 : 0) + (i%3 == 0 ? 1 : 0);
			CHECK_EQUAL(st.GetSize(), expected_size);
			size_t idx = 0;
			if (i%2 == 0) {
				CHECK_EQUAL(st.Get(0, idx), 200+i);
				++idx;
			}
			if (i%3 == 0) {
				CHECK_EQUAL(st.Get(0, idx), 300+i);
				++idx;
			}
		}
		CHECK_EQUAL(table.GetMixedType(2,i), i%3 == 1 || i%8 == 3 ? COLUMN_TYPE_TABLE : COLUMN_TYPE_INT);
		if (i%3 == 1 || i%8 == 3) {
			TopLevelTable st = table.GetMixedTable(2, i);
			size_t expected_size = (i%3 == 1 ? 1 : 0) + (i%8 == 3 ? 1 : 0);
			CHECK_EQUAL(st.GetSize(), expected_size);
			size_t idx = 0;
			if (i%3 == 1) {
				CHECK_EQUAL(st.Get(0, idx), 700+i);
				++idx;
			}
			if (i%8 == 3) {
				CHECK_EQUAL(st.Get(0, idx), 800+i);
				++idx;
			}
		}
	}

	g.Write("subtables.tdb");

	// Read back tables
	Group g2("subtables.tdb");
	TopLevelTable &table2 = g2.GetTable("test");

	for (int i=0; i<n; ++i) {
		CHECK_EQUAL(table2.Get(0, i), 100+i);
		{
			Table st = table2.GetTable(1, i);
			size_t expected_size = (i%2 == 0 ? 1 : 0) + (i%3 == 0 ? 1 : 0);
			CHECK_EQUAL(st.GetSize(), expected_size);
			size_t idx = 0;
			if (i%2 == 0) {
				CHECK_EQUAL(st.Get(0, idx), 200+i);
				++idx;
			}
			if (i%3 == 0) {
				CHECK_EQUAL(st.Get(0, idx), 300+i);
				++idx;
			}
			if (i%5 == 0) {
				st.AddRow();
				st.Set(0, st.GetSize()-1, 400+i);
			}
		}
		CHECK_EQUAL(table2.GetMixedType(2,i), i%3 == 1 || i%8 == 3 ? COLUMN_TYPE_TABLE : COLUMN_TYPE_INT);
		if (i%3 == 1 || i%8 == 3) {
			TopLevelTable st = table2.GetMixedTable(2, i);
			size_t expected_size = (i%3 == 1 ? 1 : 0) + (i%8 == 3 ? 1 : 0);
			CHECK_EQUAL(st.GetSize(), expected_size);
			size_t idx = 0;
			if (i%3 == 1) {
				CHECK_EQUAL(st.Get(0, idx), 700+i);
				++idx;
			}
			if (i%8 == 3) {
				CHECK_EQUAL(st.Get(0, idx), 800+i);
				++idx;
			}
		}
		if (i%7 == 4) {
			if (i%3 != 1 && i%8 != 3) table2.SetMixed(2, i, Mixed(COLUMN_TYPE_TABLE));
			TopLevelTable st = table2.GetMixedTable(2, i);
			if (i%3 != 1 && i%8 != 3) st.RegisterColumn(COLUMN_TYPE_INT, "banach");
			st.AddRow();
			st.Set(0, st.GetSize()-1, 900+i);
		}
	}

	for (int i=0; i<n; ++i) {
		CHECK_EQUAL(table2.Get(0, i), 100+i);
		{
			Table st = table2.GetTable(1, i);
			size_t expected_size = (i%2 == 0 ? 1 : 0) + (i%3 == 0 ? 1 : 0) + (i%5 == 0 ? 1 : 0);
			CHECK_EQUAL(st.GetSize(), expected_size);
			size_t idx = 0;
			if (i%2 == 0) {
				CHECK_EQUAL(st.Get(0, idx), 200+i);
				++idx;
			}
			if (i%3 == 0) {
				CHECK_EQUAL(st.Get(0, idx), 300+i);
				++idx;
			}
			if (i%5 == 0) {
				CHECK_EQUAL(st.Get(0, idx), 400+i);
				++idx;
			}
		}
		CHECK_EQUAL(table2.GetMixedType(2,i), i%3 == 1 || i%8 == 3 || i%7 == 4 ? COLUMN_TYPE_TABLE : COLUMN_TYPE_INT);
		if (i%3 == 1 || i%8 == 3 || i%7 == 4) {
			TopLevelTable st = table2.GetMixedTable(2, i);
			size_t expected_size = (i%3 == 1 ? 1 : 0) + (i%8 == 3 ? 1 : 0) + (i%7 == 4 ? 1 : 0);
			CHECK_EQUAL(st.GetSize(), expected_size);
			size_t idx = 0;
			if (i%3 == 1) {
				CHECK_EQUAL(st.Get(0, idx), 700+i);
				++idx;
			}
			if (i%8 == 3) {
				CHECK_EQUAL(st.Get(0, idx), 800+i);
				++idx;
			}
			if (i%7 == 4) {
				CHECK_EQUAL(st.Get(0, idx), 900+i);
				++idx;
			}
		}
	}

	g2.Write("subtables2.tdb");

	// Read back tables
	Group g3("subtables2.tdb");
	TopLevelTable &table3 = g2.GetTable("test");

	for (int i=0; i<n; ++i) {
		CHECK_EQUAL(table3.Get(0, i), 100+i);
		{
			Table st = table3.GetTable(1, i);
			size_t expected_size = (i%2 == 0 ? 1 : 0) + (i%3 == 0 ? 1 : 0) + (i%5 == 0 ? 1 : 0);
			CHECK_EQUAL(st.GetSize(), expected_size);
			size_t idx = 0;
			if (i%2 == 0) {
				CHECK_EQUAL(st.Get(0, idx), 200+i);
				++idx;
			}
			if (i%3 == 0) {
				CHECK_EQUAL(st.Get(0, idx), 300+i);
				++idx;
			}
			if (i%5 == 0) {
				CHECK_EQUAL(st.Get(0, idx), 400+i);
				++idx;
			}
		}
		CHECK_EQUAL(table3.GetMixedType(2,i), i%3 == 1 || i%8 == 3 || i%7 == 4 ? COLUMN_TYPE_TABLE : COLUMN_TYPE_INT);
		if (i%3 == 1 || i%8 == 3 || i%7 == 4) {
			TopLevelTable st = table3.GetMixedTable(2, i);
			size_t expected_size = (i%3 == 1 ? 1 : 0) + (i%8 == 3 ? 1 : 0) + (i%7 == 4 ? 1 : 0);
			CHECK_EQUAL(st.GetSize(), expected_size);
			size_t idx = 0;
			if (i%3 == 1) {
				CHECK_EQUAL(st.Get(0, idx), 700+i);
				++idx;
			}
			if (i%8 == 3) {
				CHECK_EQUAL(st.Get(0, idx), 800+i);
				++idx;
			}
			if (i%7 == 4) {
				CHECK_EQUAL(st.Get(0, idx), 900+i);
				++idx;
			}
		}
	}
}


#ifdef _DEBUG
#ifdef TIGHTDB_TO_DOT

#include <fstream>
TEST(Group_ToDot) {
	// Create group with one table
	Group mygroup;
	
	// Create table with all column types
	TopLevelTable& table = mygroup.GetTable("test");
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
			// To mixed column
			table.SetMixed(7, i, Mixed(COLUMN_TYPE_TABLE));
			TopLevelTable subtable = table.GetMixedTable(7, i);
			
			Spec s = subtable.GetSpec();
			s.AddColumn(COLUMN_TYPE_INT,    "first");
			s.AddColumn(COLUMN_TYPE_STRING, "second");
			subtable.UpdateFromSpec(s.GetRef());
			
			subtable.InsertInt(0, 0, 42);
			subtable.InsertString(1, 0, "meaning");
			subtable.InsertDone();
			
			// To table column
			Table subtable2 = table.GetTable(8, i);
			subtable2.InsertInt(0, 0, 42);
			subtable2.InsertString(1, 0, "meaning");
			subtable2.InsertDone();
		}
	}
	
	// We also want ColumnStringEnum's
	table.Optimize();
	
#if 1
	// Write array graph to cout
	std::stringstream ss;
	mygroup.ToDot(ss);
	cout << ss.str() << endl;
#endif
	
	// Write array graph to file in dot format
	std::ofstream fs("tightdb_graph.dot", ios::out | ios::binary);
	if (!fs.is_open()) cout << "file open error " << strerror << endl;
	mygroup.ToDot(fs);
	fs.close();
}

#endif //TIGHTDB_TO_DOT
#endif //_DEBUG
#endif
