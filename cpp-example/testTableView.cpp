#include "tightdb.h"
#include <UnitTest++.h>

TDB_TABLE_1(TestTableInt,
			Int,        first
)


TEST(GetSetInteger) {
	TestTableInt table;

	table.Add(1);
	table.Add(2);
	table.Add(3);
	table.Add(1);
	table.Add(2);
	
	TableView v = table.first.FindAll(2);

	CHECK_EQUAL(2, v.GetSize());

	// Test of Get
	CHECK_EQUAL(2, v.Get(0, 0));
	CHECK_EQUAL(2, v.Get(0, 1));
	
	// Test of Set
	v.Set(0, 0, 123);
	CHECK_EQUAL(123, v.Get(0, 0));

	//v.Destroy();
}


TEST(TableViewSum) {
	TestTableInt table;

	table.Add(2);
	table.Add(2);
	table.Add(2);
	table.Add(2);
	table.Add(2);
	
	TableView v = table.first.FindAll(2);
	CHECK_EQUAL(5, v.GetSize());

	int64_t sum = v.Sum(0);
	CHECK_EQUAL(10, sum);
	
	//v.Destroy();
}

TEST(TableViewSumNegative) {
	TestTableInt table;

	table.Add(0);
	table.Add(0);
	table.Add(0);

	TableView v = table.first.FindAll(0);
	v.Set(0, 0, 11);
	v.Set(0, 2, -20);
	
	int64_t sum = v.Sum(0);
	CHECK_EQUAL(-9, sum);
	
	//v.Destroy();
}

TEST(TableViewMax) {
	TestTableInt table;

	table.Add(0);
	table.Add(0);
	table.Add(0);

	TableView v = table.first.FindAll(0);
	v.Set(0, 0, -1);
	v.Set(0, 1, 2);
	v.Set(0, 2, 1);
	
	int64_t max = v.Max(0);
	CHECK_EQUAL(2, max);
	//v.Destroy();
}



TEST(TableViewMax2) {
	TestTableInt table;

	table.Add(0);
	table.Add(0);
	table.Add(0);
	
	TableView v = table.first.FindAll(0);
	v.Set(0, 0, -1);
	v.Set(0, 1, -2);
	v.Set(0, 2, -3);
	
	int64_t max = v.Max(0);
	CHECK_EQUAL(-1, max);
	//v.Destroy();
}


TEST(TableViewMin) {
	TestTableInt table;

	table.Add(0);
	table.Add(0);
	table.Add(0);

	TableView v = table.first.FindAll(0);
	v.Set(0, 0, -1);
	v.Set(0, 1, 2);
	v.Set(0, 2, 1);
	
	int64_t min = v.Min(0);
	CHECK_EQUAL(-1, min);
	//v.Destroy();
}


TEST(TableViewMin2) {
	TestTableInt table;

	table.Add(0);
	table.Add(0);
	table.Add(0);

	TableView v = table.first.FindAll(0);
	v.Set(0, 0, -1);
	v.Set(0, 1, -2);
	v.Set(0, 2, -3);
	
	int64_t min = v.Min(0);
	CHECK_EQUAL(-3, min);
	//v.Destroy();
}



TEST(TableViewFind) {
	TestTableInt table;

	table.Add(0);
	table.Add(0);
	table.Add(0);

	TableView v = table.first.FindAll(0);
	v.Set(0, 0, 5);
	v.Set(0, 1, 4);
	v.Set(0, 2, 4);
	
	size_t r = v.Find(0, 4);
	CHECK_EQUAL(1, r);
	//v.Destroy();
}


TEST(TableViewFindAll) {
	TestTableInt table;

	table.Add(0);
	table.Add(0);
	table.Add(0);

	TableView v = table.first.FindAll(0);
	v.Set(0, 0, 5);
	v.Set(0, 1, 4); // match
	v.Set(0, 2, 4); // match

	// todo, add creation to wrapper function in table.h
	TableView *v2 = new TableView(*v.GetTable());
	v.FindAll(*v2, 0, 4);
	CHECK_EQUAL(1, v2->GetRef(0));
	CHECK_EQUAL(2, v2->GetRef(1));
	//v.Destroy();
}

TDB_TABLE_1(TestTableString,
			String,        first
)

TEST(TableViewFindAllString) {
	TestTableString table;

	table.Add("a");
	table.Add("a");
	table.Add("a");
	
	TableView v = table.first.FindAll("a");
	v.SetString(0, 0, "foo");
	v.SetString(0, 1, "bar"); // match
	v.SetString(0, 2, "bar"); // match

	// todo, add creation to wrapper function in table.h
	TableView *v2 = new TableView(*v.GetTable());
	v.FindAllString(*v2, 0, "bar");
	CHECK_EQUAL(1, v2->GetRef(0));
	CHECK_EQUAL(2, v2->GetRef(1));
	//v.Destroy();
}

TEST(TableViewDelete) {
	TestTableInt table;
	
	table.Add(1);
	table.Add(2);
	table.Add(1);
	table.Add(3);
	table.Add(1);
	
	TableView v = table.first.FindAll(1);
	CHECK_EQUAL(3, v.GetSize());
	
	v.Delete(1);
	CHECK_EQUAL(2, v.GetSize());
	CHECK_EQUAL(0, v.GetRef(0));
	CHECK_EQUAL(3, v.GetRef(1));
	
	CHECK_EQUAL(4, table.GetSize());
	CHECK_EQUAL(1, table[0].first);
	CHECK_EQUAL(2, table[1].first);
	CHECK_EQUAL(3, table[2].first);
	CHECK_EQUAL(1, table[3].first);
	
	v.Delete(0);
	CHECK_EQUAL(1, v.GetSize());
	CHECK_EQUAL(2, v.GetRef(0));
	
	CHECK_EQUAL(3, table.GetSize());
	CHECK_EQUAL(2, table[0].first);
	CHECK_EQUAL(3, table[1].first);
	CHECK_EQUAL(1, table[2].first);
	
	v.Delete(0);
	CHECK_EQUAL(0, v.GetSize());
	
	CHECK_EQUAL(2, table.GetSize());
	CHECK_EQUAL(2, table[0].first);
	CHECK_EQUAL(3, table[1].first);
}

TEST(TableViewClear) {
	TestTableInt table;
	
	table.Add(1);
	table.Add(2);
	table.Add(1);
	table.Add(3);
	table.Add(1);
	
	TableView v = table.first.FindAll(1);
	CHECK_EQUAL(3, v.GetSize());
	
	v.Clear();
	CHECK_EQUAL(0, v.GetSize());
	
	CHECK_EQUAL(2, table.GetSize());
	CHECK_EQUAL(2, table[0].first);
	CHECK_EQUAL(3, table[1].first);
}


TEST(TableViewClearNone) {
	TestTableInt table;
	
	TableView v = table.first.FindAll(1);
	CHECK_EQUAL(0, v.GetSize());
	
	v.Clear();

}
