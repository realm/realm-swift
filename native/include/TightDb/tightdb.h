#ifndef __TIGHTDB_H__
#define __TIGHTDB_H__

#include "Table.h"
#include <vector>

#include "query/QueryInterface.h"

using namespace std;

#define TDB_QUERY(QueryName, TableName) \
class QueryName : public TableName##Query { \
public: \
QueryName()

#define TDB_QUERY_OPT(QueryName, TableName) \
class QueryName : public TableName##Query { \
public: \
QueryName

#define TDB_QUERY_END }; \



#define TDB_TABLE_1(TableName, CType1, CName1) \
class TableName##Query { \
protected: \
	QueryAccessor##CType1 CName1; \
}; \
\
class TableName : public TopLevelTable { \
public: \
	TableName(Allocator& alloc=GetDefaultAllocator()) : TopLevelTable(alloc) { \
		RegisterColumn(Accessor##CType1::type, #CName1); \
\
		CName1.Create(this, 0); \
	}; \
\
	class TestQuery : public Query { \
	public: \
		TestQuery() : CName1(0) { \
			CName1.SetQuery(this); \
		} \
\
		TestQuery(const TestQuery& copy) : Query(copy), CName1(0) { \
			CName1.SetQuery(this); \
		} \
\
		class TestQueryQueryAccessorInt : private XQueryAccessorInt { \
		public: \
			TestQueryQueryAccessorInt(size_t column_id) : XQueryAccessorInt(column_id) {} \
			void SetQuery(Query* query) {m_query = query;} \
\
			TestQuery& Equal(int64_t value) {return static_cast<TestQuery &>(XQueryAccessorInt::Equal(value));} \
			TestQuery& NotEqual(int64_t value) {return static_cast<TestQuery &>(XQueryAccessorInt::NotEqual(value));} \
			TestQuery& Greater(int64_t value) {return static_cast<TestQuery &>(XQueryAccessorInt::Greater(value));} \
			TestQuery& Less(int64_t value) {return static_cast<TestQuery &>(XQueryAccessorInt::Less(value));} \
			TestQuery& Between(int64_t from, int64_t to) {return static_cast<TestQuery &>(XQueryAccessorInt::Between(from, to));} \
		}; \
\
		template <class T> class TestQueryQueryAccessorEnum : public TestQueryQueryAccessorInt { \
		public: \
			TestQueryQueryAccessorEnum<T>(size_t column_id) : TestQueryQueryAccessorInt(column_id) {} \
		}; \
\
		class TestQueryQueryAccessorString : private XQueryAccessorString { \
		public: \
			TestQueryQueryAccessorString(size_t column_id) : XQueryAccessorString(column_id) {} \
			void SetQuery(Query* query) {m_query = query;} \
\
			TestQuery& Equal(const char *value, bool CaseSensitive = true) {return static_cast<TestQuery &>(XQueryAccessorString::Equal(value, CaseSensitive));} \
			TestQuery& NotEqual(const char *value, bool CaseSensitive = true) {return static_cast<TestQuery &>(XQueryAccessorString::NotEqual(value, CaseSensitive));} \
			TestQuery& BeginsWith(const char *value, bool CaseSensitive = true) {return static_cast<TestQuery &>(XQueryAccessorString::BeginsWith(value, CaseSensitive));} \
			TestQuery& EndsWith(const char *value, bool CaseSensitive = true) {return static_cast<TestQuery &>(XQueryAccessorString::EndsWith(value, CaseSensitive));} \
			TestQuery& Contains(const char *value, bool CaseSensitive = true) {return static_cast<TestQuery &>(XQueryAccessorString::Contains(value, CaseSensitive));} \
		}; \
\
		class TestQueryQueryAccessorBool : private XQueryAccessorBool { \
		public: \
			TestQueryQueryAccessorBool(size_t column_id) : XQueryAccessorBool(column_id) {} \
			void SetQuery(Query* query) {m_query = query;} \
\
			TestQuery& Equal(bool value) {return static_cast<TestQuery &>(XQueryAccessorBool::Equal(value));} \
		}; \
\
		class TestQueryQueryAccessorMixed : private XQueryAccessorMixed { \
		public: \
			TestQueryQueryAccessorMixed(size_t column_id) : XQueryAccessorMixed(column_id) {} \
			void SetQuery(Query* query) {m_query = query;} \
		}; \
\
		TestQueryQueryAccessor##CType1 CName1; \
\
		TestQuery& LeftParan(void) {Query::LeftParan(); return *this;}; \
		TestQuery& Or(void) {Query::Or(); return *this;}; \
		TestQuery& RightParan(void) {Query::RightParan(); return *this;}; \
		TestQuery& Subtable(size_t column) {Query::Subtable(column); return *this;}; \
		TestQuery& Parent() {Query::Parent(); return *this;}; \
	}; \
\
	TestQuery GetQuery() {return TestQuery();} \
\
	class Cursor : public CursorBase { \
	public: \
		Cursor(TableName& table, size_t ndx) : CursorBase(table, ndx) { \
			CName1.Create(this, 0); \
		} \
		Cursor(const TableName& table, size_t ndx) : CursorBase(const_cast<TableName&>(table), ndx) { \
			CName1.Create(this, 0); \
		} \
		Cursor(const Cursor& v) : CursorBase(v) { \
			CName1.Create(this, 0); \
		} \
		Accessor##CType1 CName1; \
	}; \
\
	void Add(tdbType##CType1 CName1) { \
		const size_t ndx = GetSize(); \
		Insert##CType1 (0, ndx, CName1); \
		InsertDone(); \
	} \
\
	void Insert(size_t ndx, tdbType##CType1 CName1) { \
		Insert##CType1 (0, ndx, CName1); \
		InsertDone(); \
	} \
\
	Cursor Add() {return Cursor(*this, AddRow());} \
	Cursor Get(size_t ndx) {return Cursor(*this, ndx);} \
	Cursor operator[](size_t ndx) {return Cursor(*this, ndx);} \
	const Cursor operator[](size_t ndx) const {return Cursor(*this, ndx);} \
	Cursor operator[](int ndx) {return Cursor(*this, (ndx < 0) ? GetSize() + ndx : ndx);} \
	Cursor Back() {return Cursor(*this, m_size-1);} \
	const Cursor Back() const {return Cursor(*this, m_size-1);} \
\
	size_t Find(const TableName##Query&) const {return (size_t)-1;} \
	TableName FindAll(const TableName##Query&) const {return TableName();} \
	TableName Sort() const {return TableName();} \
	TableName Range(int, int) const {return TableName();} \
	TableName Limit(size_t) const {return TableName();} \
\
	ColumnProxy##CType1 CName1; \
\
private: \
	friend class Group; \
	TableName(Allocator& alloc, size_t ref, Parent *parent, size_t ndx_in_parent): \
		TopLevelTable(alloc, ref, parent, ndx_in_parent) {} \
	TableName(const TableName &); /* Disable */ \
	TableName& operator=(const TableName &); /* Disable */ \
};



#define TDB_TABLE_2(TableName, CType1, CName1, CType2, CName2) \
class TableName##Query { \
protected: \
	QueryAccessor##CType1 CName1; \
	QueryAccessor##CType2 CName2; \
}; \
\
class TableName : public TopLevelTable { \
public: \
	TableName(Allocator& alloc=GetDefaultAllocator()) : TopLevelTable(alloc) { \
		RegisterColumn(Accessor##CType1::type, #CName1); \
		RegisterColumn(Accessor##CType2::type, #CName2); \
\
		CName1.Create(this, 0); \
		CName2.Create(this, 1); \
	}; \
\
	class TestQuery : public Query { \
	public: \
		TestQuery() : CName1(0), CName2(1) { \
			CName1.SetQuery(this); \
			CName2.SetQuery(this); \
		} \
\
		TestQuery(const TestQuery& copy) : Query(copy), CName1(0), CName2(1) { \
			CName1.SetQuery(this); \
			CName2.SetQuery(this); \
		} \
\
		class TestQueryQueryAccessorInt : private XQueryAccessorInt { \
		public: \
			TestQueryQueryAccessorInt(size_t column_id) : XQueryAccessorInt(column_id) {} \
			void SetQuery(Query* query) {m_query = query;} \
\
			TestQuery& Equal(int64_t value) {return static_cast<TestQuery &>(XQueryAccessorInt::Equal(value));} \
			TestQuery& NotEqual(int64_t value) {return static_cast<TestQuery &>(XQueryAccessorInt::NotEqual(value));} \
			TestQuery& Greater(int64_t value) {return static_cast<TestQuery &>(XQueryAccessorInt::Greater(value));} \
			TestQuery& Less(int64_t value) {return static_cast<TestQuery &>(XQueryAccessorInt::Less(value));} \
			TestQuery& Between(int64_t from, int64_t to) {return static_cast<TestQuery &>(XQueryAccessorInt::Between(from, to));} \
		}; \
\
		template <class T> class TestQueryQueryAccessorEnum : public TestQueryQueryAccessorInt { \
		public: \
			TestQueryQueryAccessorEnum<T>(size_t column_id) : TestQueryQueryAccessorInt(column_id) {} \
		}; \
\
		class TestQueryQueryAccessorString : private XQueryAccessorString { \
		public: \
			TestQueryQueryAccessorString(size_t column_id) : XQueryAccessorString(column_id) {} \
			void SetQuery(Query* query) {m_query = query;} \
\
			TestQuery& Equal(const char *value, bool CaseSensitive = true) {return static_cast<TestQuery &>(XQueryAccessorString::Equal(value, CaseSensitive));} \
			TestQuery& NotEqual(const char *value, bool CaseSensitive = true) {return static_cast<TestQuery &>(XQueryAccessorString::NotEqual(value, CaseSensitive));} \
			TestQuery& BeginsWith(const char *value, bool CaseSensitive = true) {return static_cast<TestQuery &>(XQueryAccessorString::BeginsWith(value, CaseSensitive));} \
			TestQuery& EndsWith(const char *value, bool CaseSensitive = true) {return static_cast<TestQuery &>(XQueryAccessorString::EndsWith(value, CaseSensitive));} \
			TestQuery& Contains(const char *value, bool CaseSensitive = true) {return static_cast<TestQuery &>(XQueryAccessorString::Contains(value, CaseSensitive));} \
		}; \
\
		class TestQueryQueryAccessorBool : private XQueryAccessorBool { \
		public: \
			TestQueryQueryAccessorBool(size_t column_id) : XQueryAccessorBool(column_id) {} \
			void SetQuery(Query* query) {m_query = query;} \
\
			TestQuery& Equal(bool value) {return static_cast<TestQuery &>(XQueryAccessorBool::Equal(value));} \
		}; \
\
		class TestQueryQueryAccessorMixed : private XQueryAccessorMixed { \
		public: \
			TestQueryQueryAccessorMixed(size_t column_id) : XQueryAccessorMixed(column_id) {} \
			void SetQuery(Query* query) {m_query = query;} \
		}; \
\
		TestQueryQueryAccessor##CType1 CName1; \
		TestQueryQueryAccessor##CType2 CName2; \
\
		TestQuery& LeftParan(void) {Query::LeftParan(); return *this;}; \
		TestQuery& Or(void) {Query::Or(); return *this;}; \
		TestQuery& RightParan(void) {Query::RightParan(); return *this;}; \
		TestQuery& Subtable(size_t column) {Query::Subtable(column); return *this;}; \
		TestQuery& Parent() {Query::Parent(); return *this;}; \
	}; \
\
	TestQuery GetQuery() {return TestQuery();} \
\
	class Cursor : public CursorBase { \
	public: \
		Cursor(TableName& table, size_t ndx) : CursorBase(table, ndx) { \
			CName1.Create(this, 0); \
			CName2.Create(this, 1); \
		} \
		Cursor(const TableName& table, size_t ndx) : CursorBase(const_cast<TableName&>(table), ndx) { \
			CName1.Create(this, 0); \
			CName2.Create(this, 1); \
		} \
		Cursor(const Cursor& v) : CursorBase(v) { \
			CName1.Create(this, 0); \
			CName2.Create(this, 1); \
		} \
		Accessor##CType1 CName1; \
		Accessor##CType2 CName2; \
	}; \
\
	void Add(tdbType##CType1 CName1, tdbType##CType2 CName2) { \
		const size_t ndx = GetSize(); \
		Insert##CType1 (0, ndx, CName1); \
		Insert##CType2 (1, ndx, CName2); \
		InsertDone(); \
	} \
\
	void Insert(size_t ndx, tdbType##CType1 CName1, tdbType##CType2 CName2) { \
		Insert##CType1 (0, ndx, CName1); \
		Insert##CType2 (1, ndx, CName2); \
		InsertDone(); \
	} \
\
	Cursor Add() {return Cursor(*this, AddRow());} \
	Cursor Get(size_t ndx) {return Cursor(*this, ndx);} \
	Cursor operator[](size_t ndx) {return Cursor(*this, ndx);} \
	const Cursor operator[](size_t ndx) const {return Cursor(*this, ndx);} \
	Cursor operator[](int ndx) {return Cursor(*this, (ndx < 0) ? GetSize() + ndx : ndx);} \
	Cursor Back() {return Cursor(*this, m_size-1);} \
	const Cursor Back() const {return Cursor(*this, m_size-1);} \
\
	size_t Find(const TableName##Query&) const {return (size_t)-1;} \
	TableName FindAll(const TableName##Query&) const {return TableName();} \
	TableName Sort() const {return TableName();} \
	TableName Range(int, int) const {return TableName();} \
	TableName Limit(size_t) const {return TableName();} \
\
	ColumnProxy##CType1 CName1; \
	ColumnProxy##CType2 CName2; \
\
private: \
	friend class Group; \
	TableName(Allocator& alloc, size_t ref, Parent *parent, size_t ndx_in_parent): \
		TopLevelTable(alloc, ref, parent, ndx_in_parent) {} \
	TableName(const TableName &); /* Disable */ \
	TableName& operator=(const TableName &); /* Disable */ \
};



#define TDB_TABLE_3(TableName, CType1, CName1, CType2, CName2, CType3, CName3) \
class TableName##Query { \
protected: \
	QueryAccessor##CType1 CName1; \
	QueryAccessor##CType2 CName2; \
	QueryAccessor##CType3 CName3; \
}; \
\
class TableName : public TopLevelTable { \
public: \
	TableName(Allocator& alloc=GetDefaultAllocator()) : TopLevelTable(alloc) { \
		RegisterColumn(Accessor##CType1::type, #CName1); \
		RegisterColumn(Accessor##CType2::type, #CName2); \
		RegisterColumn(Accessor##CType3::type, #CName3); \
\
		CName1.Create(this, 0); \
		CName2.Create(this, 1); \
		CName3.Create(this, 2); \
	}; \
\
	class TestQuery : public Query { \
	public: \
		TestQuery() : CName1(0), CName2(1), CName3(2) { \
			CName1.SetQuery(this); \
			CName2.SetQuery(this); \
			CName3.SetQuery(this); \
		} \
\
		TestQuery(const TestQuery& copy) : Query(copy), CName1(0), CName2(1), CName3(2) { \
			CName1.SetQuery(this); \
			CName2.SetQuery(this); \
			CName3.SetQuery(this); \
		} \
\
		class TestQueryQueryAccessorInt : private XQueryAccessorInt { \
		public: \
			TestQueryQueryAccessorInt(size_t column_id) : XQueryAccessorInt(column_id) {} \
			void SetQuery(Query* query) {m_query = query;} \
\
			TestQuery& Equal(int64_t value) {return static_cast<TestQuery &>(XQueryAccessorInt::Equal(value));} \
			TestQuery& NotEqual(int64_t value) {return static_cast<TestQuery &>(XQueryAccessorInt::NotEqual(value));} \
			TestQuery& Greater(int64_t value) {return static_cast<TestQuery &>(XQueryAccessorInt::Greater(value));} \
			TestQuery& Less(int64_t value) {return static_cast<TestQuery &>(XQueryAccessorInt::Less(value));} \
			TestQuery& Between(int64_t from, int64_t to) {return static_cast<TestQuery &>(XQueryAccessorInt::Between(from, to));} \
		}; \
\
		template <class T> class TestQueryQueryAccessorEnum : public TestQueryQueryAccessorInt { \
		public: \
			TestQueryQueryAccessorEnum<T>(size_t column_id) : TestQueryQueryAccessorInt(column_id) {} \
		}; \
\
		class TestQueryQueryAccessorString : private XQueryAccessorString { \
		public: \
			TestQueryQueryAccessorString(size_t column_id) : XQueryAccessorString(column_id) {} \
			void SetQuery(Query* query) {m_query = query;} \
\
			TestQuery& Equal(const char *value, bool CaseSensitive = true) {return static_cast<TestQuery &>(XQueryAccessorString::Equal(value, CaseSensitive));} \
			TestQuery& NotEqual(const char *value, bool CaseSensitive = true) {return static_cast<TestQuery &>(XQueryAccessorString::NotEqual(value, CaseSensitive));} \
			TestQuery& BeginsWith(const char *value, bool CaseSensitive = true) {return static_cast<TestQuery &>(XQueryAccessorString::BeginsWith(value, CaseSensitive));} \
			TestQuery& EndsWith(const char *value, bool CaseSensitive = true) {return static_cast<TestQuery &>(XQueryAccessorString::EndsWith(value, CaseSensitive));} \
			TestQuery& Contains(const char *value, bool CaseSensitive = true) {return static_cast<TestQuery &>(XQueryAccessorString::Contains(value, CaseSensitive));} \
		}; \
\
		class TestQueryQueryAccessorBool : private XQueryAccessorBool { \
		public: \
			TestQueryQueryAccessorBool(size_t column_id) : XQueryAccessorBool(column_id) {} \
			void SetQuery(Query* query) {m_query = query;} \
\
			TestQuery& Equal(bool value) {return static_cast<TestQuery &>(XQueryAccessorBool::Equal(value));} \
		}; \
\
		class TestQueryQueryAccessorMixed : private XQueryAccessorMixed { \
		public: \
			TestQueryQueryAccessorMixed(size_t column_id) : XQueryAccessorMixed(column_id) {} \
			void SetQuery(Query* query) {m_query = query;} \
		}; \
\
		TestQueryQueryAccessor##CType1 CName1; \
		TestQueryQueryAccessor##CType2 CName2; \
		TestQueryQueryAccessor##CType3 CName3; \
\
		TestQuery& LeftParan(void) {Query::LeftParan(); return *this;}; \
		TestQuery& Or(void) {Query::Or(); return *this;}; \
		TestQuery& RightParan(void) {Query::RightParan(); return *this;}; \
		TestQuery& Subtable(size_t column) {Query::Subtable(column); return *this;}; \
		TestQuery& Parent() {Query::Parent(); return *this;}; \
	}; \
\
	TestQuery GetQuery() {return TestQuery();} \
\
	class Cursor : public CursorBase { \
	public: \
		Cursor(TableName& table, size_t ndx) : CursorBase(table, ndx) { \
			CName1.Create(this, 0); \
			CName2.Create(this, 1); \
			CName3.Create(this, 2); \
		} \
		Cursor(const TableName& table, size_t ndx) : CursorBase(const_cast<TableName&>(table), ndx) { \
			CName1.Create(this, 0); \
			CName2.Create(this, 1); \
			CName3.Create(this, 2); \
		} \
		Cursor(const Cursor& v) : CursorBase(v) { \
			CName1.Create(this, 0); \
			CName2.Create(this, 1); \
			CName3.Create(this, 2); \
		} \
		Accessor##CType1 CName1; \
		Accessor##CType2 CName2; \
		Accessor##CType3 CName3; \
	}; \
\
	void Add(tdbType##CType1 CName1, tdbType##CType2 CName2, tdbType##CType3 CName3) { \
		const size_t ndx = GetSize(); \
		Insert##CType1 (0, ndx, CName1); \
		Insert##CType2 (1, ndx, CName2); \
		Insert##CType3 (2, ndx, CName3); \
		InsertDone(); \
	} \
\
	void Insert(size_t ndx, tdbType##CType1 CName1, tdbType##CType2 CName2, tdbType##CType3 CName3) { \
		Insert##CType1 (0, ndx, CName1); \
		Insert##CType2 (1, ndx, CName2); \
		Insert##CType3 (2, ndx, CName3); \
		InsertDone(); \
	} \
\
	Cursor Add() {return Cursor(*this, AddRow());} \
	Cursor Get(size_t ndx) {return Cursor(*this, ndx);} \
	Cursor operator[](size_t ndx) {return Cursor(*this, ndx);} \
	const Cursor operator[](size_t ndx) const {return Cursor(*this, ndx);} \
	Cursor operator[](int ndx) {return Cursor(*this, (ndx < 0) ? GetSize() + ndx : ndx);} \
	Cursor Back() {return Cursor(*this, m_size-1);} \
	const Cursor Back() const {return Cursor(*this, m_size-1);} \
\
	size_t Find(const TableName##Query&) const {return (size_t)-1;} \
	TableName FindAll(const TableName##Query&) const {return TableName();} \
	TableName Sort() const {return TableName();} \
	TableName Range(int, int) const {return TableName();} \
	TableName Limit(size_t) const {return TableName();} \
\
	ColumnProxy##CType1 CName1; \
	ColumnProxy##CType2 CName2; \
	ColumnProxy##CType3 CName3; \
\
private: \
	friend class Group; \
	TableName(Allocator& alloc, size_t ref, Parent *parent, size_t ndx_in_parent): \
		TopLevelTable(alloc, ref, parent, ndx_in_parent) {} \
	TableName(const TableName &); /* Disable */ \
	TableName& operator=(const TableName &); /* Disable */ \
};



#define TDB_TABLE_4(TableName, CType1, CName1, CType2, CName2, CType3, CName3, CType4, CName4) \
class TableName##Query { \
protected: \
	QueryAccessor##CType1 CName1; \
	QueryAccessor##CType2 CName2; \
	QueryAccessor##CType3 CName3; \
	QueryAccessor##CType4 CName4; \
}; \
\
class TableName : public TopLevelTable { \
public: \
	TableName(Allocator& alloc=GetDefaultAllocator()) : TopLevelTable(alloc) { \
		RegisterColumn(Accessor##CType1::type, #CName1); \
		RegisterColumn(Accessor##CType2::type, #CName2); \
		RegisterColumn(Accessor##CType3::type, #CName3); \
		RegisterColumn(Accessor##CType4::type, #CName4); \
\
		CName1.Create(this, 0); \
		CName2.Create(this, 1); \
		CName3.Create(this, 2); \
		CName4.Create(this, 3); \
	}; \
\
	class TestQuery : public Query { \
	public: \
		TestQuery() : CName1(0), CName2(1), CName3(2), CName4(3) { \
			CName1.SetQuery(this); \
			CName2.SetQuery(this); \
			CName3.SetQuery(this); \
			CName4.SetQuery(this); \
		} \
\
		TestQuery(const TestQuery& copy) : Query(copy), CName1(0), CName2(1), CName3(2), CName4(3) { \
			CName1.SetQuery(this); \
			CName2.SetQuery(this); \
			CName3.SetQuery(this); \
			CName4.SetQuery(this); \
		} \
\
		class TestQueryQueryAccessorInt : private XQueryAccessorInt { \
		public: \
			TestQueryQueryAccessorInt(size_t column_id) : XQueryAccessorInt(column_id) {} \
			void SetQuery(Query* query) {m_query = query;} \
\
			TestQuery& Equal(int64_t value) {return static_cast<TestQuery &>(XQueryAccessorInt::Equal(value));} \
			TestQuery& NotEqual(int64_t value) {return static_cast<TestQuery &>(XQueryAccessorInt::NotEqual(value));} \
			TestQuery& Greater(int64_t value) {return static_cast<TestQuery &>(XQueryAccessorInt::Greater(value));} \
			TestQuery& Less(int64_t value) {return static_cast<TestQuery &>(XQueryAccessorInt::Less(value));} \
			TestQuery& Between(int64_t from, int64_t to) {return static_cast<TestQuery &>(XQueryAccessorInt::Between(from, to));} \
		}; \
\
		template <class T> class TestQueryQueryAccessorEnum : public TestQueryQueryAccessorInt { \
		public: \
			TestQueryQueryAccessorEnum<T>(size_t column_id) : TestQueryQueryAccessorInt(column_id) {} \
		}; \
\
		class TestQueryQueryAccessorString : private XQueryAccessorString { \
		public: \
			TestQueryQueryAccessorString(size_t column_id) : XQueryAccessorString(column_id) {} \
			void SetQuery(Query* query) {m_query = query;} \
\
			TestQuery& Equal(const char *value, bool CaseSensitive = true) {return static_cast<TestQuery &>(XQueryAccessorString::Equal(value, CaseSensitive));} \
			TestQuery& NotEqual(const char *value, bool CaseSensitive = true) {return static_cast<TestQuery &>(XQueryAccessorString::NotEqual(value, CaseSensitive));} \
			TestQuery& BeginsWith(const char *value, bool CaseSensitive = true) {return static_cast<TestQuery &>(XQueryAccessorString::BeginsWith(value, CaseSensitive));} \
			TestQuery& EndsWith(const char *value, bool CaseSensitive = true) {return static_cast<TestQuery &>(XQueryAccessorString::EndsWith(value, CaseSensitive));} \
			TestQuery& Contains(const char *value, bool CaseSensitive = true) {return static_cast<TestQuery &>(XQueryAccessorString::Contains(value, CaseSensitive));} \
		}; \
\
		class TestQueryQueryAccessorBool : private XQueryAccessorBool { \
		public: \
			TestQueryQueryAccessorBool(size_t column_id) : XQueryAccessorBool(column_id) {} \
			void SetQuery(Query* query) {m_query = query;} \
\
			TestQuery& Equal(bool value) {return static_cast<TestQuery &>(XQueryAccessorBool::Equal(value));} \
		}; \
\
		class TestQueryQueryAccessorMixed : private XQueryAccessorMixed { \
		public: \
			TestQueryQueryAccessorMixed(size_t column_id) : XQueryAccessorMixed(column_id) {} \
			void SetQuery(Query* query) {m_query = query;} \
		}; \
\
		TestQueryQueryAccessor##CType1 CName1; \
		TestQueryQueryAccessor##CType2 CName2; \
		TestQueryQueryAccessor##CType3 CName3; \
		TestQueryQueryAccessor##CType4 CName4; \
\
		TestQuery& LeftParan(void) {Query::LeftParan(); return *this;}; \
		TestQuery& Or(void) {Query::Or(); return *this;}; \
		TestQuery& RightParan(void) {Query::RightParan(); return *this;}; \
		TestQuery& Subtable(size_t column) {Query::Subtable(column); return *this;}; \
		TestQuery& Parent() {Query::Parent(); return *this;}; \
	}; \
\
	TestQuery GetQuery() {return TestQuery();} \
\
	class Cursor : public CursorBase { \
	public: \
		Cursor(TableName& table, size_t ndx) : CursorBase(table, ndx) { \
			CName1.Create(this, 0); \
			CName2.Create(this, 1); \
			CName3.Create(this, 2); \
			CName4.Create(this, 3); \
		} \
		Cursor(const TableName& table, size_t ndx) : CursorBase(const_cast<TableName&>(table), ndx) { \
			CName1.Create(this, 0); \
			CName2.Create(this, 1); \
			CName3.Create(this, 2); \
			CName4.Create(this, 3); \
		} \
		Cursor(const Cursor& v) : CursorBase(v) { \
			CName1.Create(this, 0); \
			CName2.Create(this, 1); \
			CName3.Create(this, 2); \
			CName4.Create(this, 3); \
		} \
		Accessor##CType1 CName1; \
		Accessor##CType2 CName2; \
		Accessor##CType3 CName3; \
		Accessor##CType4 CName4; \
	}; \
\
	void Add(tdbType##CType1 CName1, tdbType##CType2 CName2, tdbType##CType3 CName3, tdbType##CType4 CName4) { \
		const size_t ndx = GetSize(); \
		Insert##CType1 (0, ndx, CName1); \
		Insert##CType2 (1, ndx, CName2); \
		Insert##CType3 (2, ndx, CName3); \
		Insert##CType4 (3, ndx, CName4); \
		InsertDone(); \
	} \
\
	void Insert(size_t ndx, tdbType##CType1 CName1, tdbType##CType2 CName2, tdbType##CType3 CName3, tdbType##CType4 CName4) { \
		Insert##CType1 (0, ndx, CName1); \
		Insert##CType2 (1, ndx, CName2); \
		Insert##CType3 (2, ndx, CName3); \
		Insert##CType4 (3, ndx, CName4); \
		InsertDone(); \
	} \
\
	Cursor Add() {return Cursor(*this, AddRow());} \
	Cursor Get(size_t ndx) {return Cursor(*this, ndx);} \
	Cursor operator[](size_t ndx) {return Cursor(*this, ndx);} \
	const Cursor operator[](size_t ndx) const {return Cursor(*this, ndx);} \
	Cursor operator[](int ndx) {return Cursor(*this, (ndx < 0) ? GetSize() + ndx : ndx);} \
	Cursor Back() {return Cursor(*this, m_size-1);} \
	const Cursor Back() const {return Cursor(*this, m_size-1);} \
\
	size_t Find(const TableName##Query&) const {return (size_t)-1;} \
	TableName FindAll(const TableName##Query&) const {return TableName();} \
	TableName Sort() const {return TableName();} \
	TableName Range(int, int) const {return TableName();} \
	TableName Limit(size_t) const {return TableName();} \
\
	ColumnProxy##CType1 CName1; \
	ColumnProxy##CType2 CName2; \
	ColumnProxy##CType3 CName3; \
	ColumnProxy##CType4 CName4; \
\
private: \
	friend class Group; \
	TableName(Allocator& alloc, size_t ref, Parent *parent, size_t ndx_in_parent): \
		TopLevelTable(alloc, ref, parent, ndx_in_parent) {} \
	TableName(const TableName &); /* Disable */ \
	TableName& operator=(const TableName &); /* Disable */ \
};



#define TDB_TABLE_5(TableName, CType1, CName1, CType2, CName2, CType3, CName3, CType4, CName4, CType5, CName5) \
class TableName##Query { \
protected: \
	QueryAccessor##CType1 CName1; \
	QueryAccessor##CType2 CName2; \
	QueryAccessor##CType3 CName3; \
	QueryAccessor##CType4 CName4; \
	QueryAccessor##CType5 CName5; \
}; \
\
class TableName : public TopLevelTable { \
public: \
	TableName(Allocator& alloc=GetDefaultAllocator()) : TopLevelTable(alloc) { \
		RegisterColumn(Accessor##CType1::type, #CName1); \
		RegisterColumn(Accessor##CType2::type, #CName2); \
		RegisterColumn(Accessor##CType3::type, #CName3); \
		RegisterColumn(Accessor##CType4::type, #CName4); \
		RegisterColumn(Accessor##CType5::type, #CName5); \
\
		CName1.Create(this, 0); \
		CName2.Create(this, 1); \
		CName3.Create(this, 2); \
		CName4.Create(this, 3); \
		CName5.Create(this, 4); \
	}; \
\
	class TestQuery : public Query { \
	public: \
		TestQuery() : CName1(0), CName2(1), CName3(2), CName4(3), CName5(4) { \
			CName1.SetQuery(this); \
			CName2.SetQuery(this); \
			CName3.SetQuery(this); \
			CName4.SetQuery(this); \
			CName5.SetQuery(this); \
		} \
\
		TestQuery(const TestQuery& copy) : Query(copy), CName1(0), CName2(1), CName3(2), CName4(3), CName5(4) { \
			CName1.SetQuery(this); \
			CName2.SetQuery(this); \
			CName3.SetQuery(this); \
			CName4.SetQuery(this); \
			CName5.SetQuery(this); \
		} \
\
		class TestQueryQueryAccessorInt : private XQueryAccessorInt { \
		public: \
			TestQueryQueryAccessorInt(size_t column_id) : XQueryAccessorInt(column_id) {} \
			void SetQuery(Query* query) {m_query = query;} \
\
			TestQuery& Equal(int64_t value) {return static_cast<TestQuery &>(XQueryAccessorInt::Equal(value));} \
			TestQuery& NotEqual(int64_t value) {return static_cast<TestQuery &>(XQueryAccessorInt::NotEqual(value));} \
			TestQuery& Greater(int64_t value) {return static_cast<TestQuery &>(XQueryAccessorInt::Greater(value));} \
			TestQuery& Less(int64_t value) {return static_cast<TestQuery &>(XQueryAccessorInt::Less(value));} \
			TestQuery& Between(int64_t from, int64_t to) {return static_cast<TestQuery &>(XQueryAccessorInt::Between(from, to));} \
		}; \
\
		template <class T> class TestQueryQueryAccessorEnum : public TestQueryQueryAccessorInt { \
		public: \
			TestQueryQueryAccessorEnum<T>(size_t column_id) : TestQueryQueryAccessorInt(column_id) {} \
		}; \
\
		class TestQueryQueryAccessorString : private XQueryAccessorString { \
		public: \
			TestQueryQueryAccessorString(size_t column_id) : XQueryAccessorString(column_id) {} \
			void SetQuery(Query* query) {m_query = query;} \
\
			TestQuery& Equal(const char *value, bool CaseSensitive = true) {return static_cast<TestQuery &>(XQueryAccessorString::Equal(value, CaseSensitive));} \
			TestQuery& NotEqual(const char *value, bool CaseSensitive = true) {return static_cast<TestQuery &>(XQueryAccessorString::NotEqual(value, CaseSensitive));} \
			TestQuery& BeginsWith(const char *value, bool CaseSensitive = true) {return static_cast<TestQuery &>(XQueryAccessorString::BeginsWith(value, CaseSensitive));} \
			TestQuery& EndsWith(const char *value, bool CaseSensitive = true) {return static_cast<TestQuery &>(XQueryAccessorString::EndsWith(value, CaseSensitive));} \
			TestQuery& Contains(const char *value, bool CaseSensitive = true) {return static_cast<TestQuery &>(XQueryAccessorString::Contains(value, CaseSensitive));} \
		}; \
\
		class TestQueryQueryAccessorBool : private XQueryAccessorBool { \
		public: \
			TestQueryQueryAccessorBool(size_t column_id) : XQueryAccessorBool(column_id) {} \
			void SetQuery(Query* query) {m_query = query;} \
\
			TestQuery& Equal(bool value) {return static_cast<TestQuery &>(XQueryAccessorBool::Equal(value));} \
		}; \
\
		class TestQueryQueryAccessorMixed : private XQueryAccessorMixed { \
		public: \
			TestQueryQueryAccessorMixed(size_t column_id) : XQueryAccessorMixed(column_id) {} \
			void SetQuery(Query* query) {m_query = query;} \
		}; \
\
		TestQueryQueryAccessor##CType1 CName1; \
		TestQueryQueryAccessor##CType2 CName2; \
		TestQueryQueryAccessor##CType3 CName3; \
		TestQueryQueryAccessor##CType4 CName4; \
		TestQueryQueryAccessor##CType5 CName5; \
\
		TestQuery& LeftParan(void) {Query::LeftParan(); return *this;}; \
		TestQuery& Or(void) {Query::Or(); return *this;}; \
		TestQuery& RightParan(void) {Query::RightParan(); return *this;}; \
		TestQuery& Subtable(size_t column) {Query::Subtable(column); return *this;}; \
		TestQuery& Parent() {Query::Parent(); return *this;}; \
	}; \
\
	TestQuery GetQuery() {return TestQuery();} \
\
	class Cursor : public CursorBase { \
	public: \
		Cursor(TableName& table, size_t ndx) : CursorBase(table, ndx) { \
			CName1.Create(this, 0); \
			CName2.Create(this, 1); \
			CName3.Create(this, 2); \
			CName4.Create(this, 3); \
			CName5.Create(this, 4); \
		} \
		Cursor(const TableName& table, size_t ndx) : CursorBase(const_cast<TableName&>(table), ndx) { \
			CName1.Create(this, 0); \
			CName2.Create(this, 1); \
			CName3.Create(this, 2); \
			CName4.Create(this, 3); \
			CName5.Create(this, 4); \
		} \
		Cursor(const Cursor& v) : CursorBase(v) { \
			CName1.Create(this, 0); \
			CName2.Create(this, 1); \
			CName3.Create(this, 2); \
			CName4.Create(this, 3); \
			CName5.Create(this, 4); \
		} \
		Accessor##CType1 CName1; \
		Accessor##CType2 CName2; \
		Accessor##CType3 CName3; \
		Accessor##CType4 CName4; \
		Accessor##CType5 CName5; \
	}; \
\
	void Add(tdbType##CType1 CName1, tdbType##CType2 CName2, tdbType##CType3 CName3, tdbType##CType4 CName4, tdbType##CType5 CName5) { \
		const size_t ndx = GetSize(); \
		Insert##CType1 (0, ndx, CName1); \
		Insert##CType2 (1, ndx, CName2); \
		Insert##CType3 (2, ndx, CName3); \
		Insert##CType4 (3, ndx, CName4); \
		Insert##CType5 (4, ndx, CName5); \
		InsertDone(); \
	} \
\
	void Insert(size_t ndx, tdbType##CType1 CName1, tdbType##CType2 CName2, tdbType##CType3 CName3, tdbType##CType4 CName4, tdbType##CType5 CName5) { \
		Insert##CType1 (0, ndx, CName1); \
		Insert##CType2 (1, ndx, CName2); \
		Insert##CType3 (2, ndx, CName3); \
		Insert##CType4 (3, ndx, CName4); \
		Insert##CType5 (4, ndx, CName5); \
		InsertDone(); \
	} \
\
	Cursor Add() {return Cursor(*this, AddRow());} \
	Cursor Get(size_t ndx) {return Cursor(*this, ndx);} \
	Cursor operator[](size_t ndx) {return Cursor(*this, ndx);} \
	const Cursor operator[](size_t ndx) const {return Cursor(*this, ndx);} \
	Cursor operator[](int ndx) {return Cursor(*this, (ndx < 0) ? GetSize() + ndx : ndx);} \
	Cursor Back() {return Cursor(*this, m_size-1);} \
	const Cursor Back() const {return Cursor(*this, m_size-1);} \
\
	size_t Find(const TableName##Query&) const {return (size_t)-1;} \
	TableName FindAll(const TableName##Query&) const {return TableName();} \
	TableName Sort() const {return TableName();} \
	TableName Range(int, int) const {return TableName();} \
	TableName Limit(size_t) const {return TableName();} \
\
	ColumnProxy##CType1 CName1; \
	ColumnProxy##CType2 CName2; \
	ColumnProxy##CType3 CName3; \
	ColumnProxy##CType4 CName4; \
	ColumnProxy##CType5 CName5; \
\
private: \
	friend class Group; \
	TableName(Allocator& alloc, size_t ref, Parent *parent, size_t ndx_in_parent): \
		TopLevelTable(alloc, ref, parent, ndx_in_parent) {} \
	TableName(const TableName &); /* Disable */ \
	TableName& operator=(const TableName &); /* Disable */ \
};



#define TDB_TABLE_6(TableName, CType1, CName1, CType2, CName2, CType3, CName3, CType4, CName4, CType5, CName5, CType6, CName6) \
class TableName##Query { \
protected: \
	QueryAccessor##CType1 CName1; \
	QueryAccessor##CType2 CName2; \
	QueryAccessor##CType3 CName3; \
	QueryAccessor##CType4 CName4; \
	QueryAccessor##CType5 CName5; \
	QueryAccessor##CType6 CName6; \
}; \
\
class TableName : public TopLevelTable { \
public: \
	TableName(Allocator& alloc=GetDefaultAllocator()) : TopLevelTable(alloc) { \
		RegisterColumn(Accessor##CType1::type, #CName1); \
		RegisterColumn(Accessor##CType2::type, #CName2); \
		RegisterColumn(Accessor##CType3::type, #CName3); \
		RegisterColumn(Accessor##CType4::type, #CName4); \
		RegisterColumn(Accessor##CType5::type, #CName5); \
		RegisterColumn(Accessor##CType6::type, #CName6); \
\
		CName1.Create(this, 0); \
		CName2.Create(this, 1); \
		CName3.Create(this, 2); \
		CName4.Create(this, 3); \
		CName5.Create(this, 4); \
		CName6.Create(this, 5); \
	}; \
\
	class TestQuery : public Query { \
	public: \
		TestQuery() : CName1(0), CName2(1), CName3(2), CName4(3), CName5(4), CName6(5) { \
			CName1.SetQuery(this); \
			CName2.SetQuery(this); \
			CName3.SetQuery(this); \
			CName4.SetQuery(this); \
			CName5.SetQuery(this); \
			CName6.SetQuery(this); \
		} \
\
		TestQuery(const TestQuery& copy) : Query(copy), CName1(0), CName2(1), CName3(2), CName4(3), CName5(4), CName6(5) { \
			CName1.SetQuery(this); \
			CName2.SetQuery(this); \
			CName3.SetQuery(this); \
			CName4.SetQuery(this); \
			CName5.SetQuery(this); \
			CName6.SetQuery(this); \
		} \
\
		class TestQueryQueryAccessorInt : private XQueryAccessorInt { \
		public: \
			TestQueryQueryAccessorInt(size_t column_id) : XQueryAccessorInt(column_id) {} \
			void SetQuery(Query* query) {m_query = query;} \
\
			TestQuery& Equal(int64_t value) {return static_cast<TestQuery &>(XQueryAccessorInt::Equal(value));} \
			TestQuery& NotEqual(int64_t value) {return static_cast<TestQuery &>(XQueryAccessorInt::NotEqual(value));} \
			TestQuery& Greater(int64_t value) {return static_cast<TestQuery &>(XQueryAccessorInt::Greater(value));} \
			TestQuery& Less(int64_t value) {return static_cast<TestQuery &>(XQueryAccessorInt::Less(value));} \
			TestQuery& Between(int64_t from, int64_t to) {return static_cast<TestQuery &>(XQueryAccessorInt::Between(from, to));} \
		}; \
\
		template <class T> class TestQueryQueryAccessorEnum : public TestQueryQueryAccessorInt { \
		public: \
			TestQueryQueryAccessorEnum<T>(size_t column_id) : TestQueryQueryAccessorInt(column_id) {} \
		}; \
\
		class TestQueryQueryAccessorString : private XQueryAccessorString { \
		public: \
			TestQueryQueryAccessorString(size_t column_id) : XQueryAccessorString(column_id) {} \
			void SetQuery(Query* query) {m_query = query;} \
\
			TestQuery& Equal(const char *value, bool CaseSensitive = true) {return static_cast<TestQuery &>(XQueryAccessorString::Equal(value, CaseSensitive));} \
			TestQuery& NotEqual(const char *value, bool CaseSensitive = true) {return static_cast<TestQuery &>(XQueryAccessorString::NotEqual(value, CaseSensitive));} \
			TestQuery& BeginsWith(const char *value, bool CaseSensitive = true) {return static_cast<TestQuery &>(XQueryAccessorString::BeginsWith(value, CaseSensitive));} \
			TestQuery& EndsWith(const char *value, bool CaseSensitive = true) {return static_cast<TestQuery &>(XQueryAccessorString::EndsWith(value, CaseSensitive));} \
			TestQuery& Contains(const char *value, bool CaseSensitive = true) {return static_cast<TestQuery &>(XQueryAccessorString::Contains(value, CaseSensitive));} \
		}; \
\
		class TestQueryQueryAccessorBool : private XQueryAccessorBool { \
		public: \
			TestQueryQueryAccessorBool(size_t column_id) : XQueryAccessorBool(column_id) {} \
			void SetQuery(Query* query) {m_query = query;} \
\
			TestQuery& Equal(bool value) {return static_cast<TestQuery &>(XQueryAccessorBool::Equal(value));} \
		}; \
\
		class TestQueryQueryAccessorMixed : private XQueryAccessorMixed { \
		public: \
			TestQueryQueryAccessorMixed(size_t column_id) : XQueryAccessorMixed(column_id) {} \
			void SetQuery(Query* query) {m_query = query;} \
		}; \
\
		TestQueryQueryAccessor##CType1 CName1; \
		TestQueryQueryAccessor##CType2 CName2; \
		TestQueryQueryAccessor##CType3 CName3; \
		TestQueryQueryAccessor##CType4 CName4; \
		TestQueryQueryAccessor##CType5 CName5; \
		TestQueryQueryAccessor##CType6 CName6; \
\
		TestQuery& LeftParan(void) {Query::LeftParan(); return *this;}; \
		TestQuery& Or(void) {Query::Or(); return *this;}; \
		TestQuery& RightParan(void) {Query::RightParan(); return *this;}; \
		TestQuery& Subtable(size_t column) {Query::Subtable(column); return *this;}; \
		TestQuery& Parent() {Query::Parent(); return *this;}; \
	}; \
\
	TestQuery GetQuery() {return TestQuery();} \
\
	class Cursor : public CursorBase { \
	public: \
		Cursor(TableName& table, size_t ndx) : CursorBase(table, ndx) { \
			CName1.Create(this, 0); \
			CName2.Create(this, 1); \
			CName3.Create(this, 2); \
			CName4.Create(this, 3); \
			CName5.Create(this, 4); \
			CName6.Create(this, 5); \
		} \
		Cursor(const TableName& table, size_t ndx) : CursorBase(const_cast<TableName&>(table), ndx) { \
			CName1.Create(this, 0); \
			CName2.Create(this, 1); \
			CName3.Create(this, 2); \
			CName4.Create(this, 3); \
			CName5.Create(this, 4); \
			CName6.Create(this, 5); \
		} \
		Cursor(const Cursor& v) : CursorBase(v) { \
			CName1.Create(this, 0); \
			CName2.Create(this, 1); \
			CName3.Create(this, 2); \
			CName4.Create(this, 3); \
			CName5.Create(this, 4); \
			CName6.Create(this, 5); \
		} \
		Accessor##CType1 CName1; \
		Accessor##CType2 CName2; \
		Accessor##CType3 CName3; \
		Accessor##CType4 CName4; \
		Accessor##CType5 CName5; \
		Accessor##CType6 CName6; \
	}; \
\
	void Add(tdbType##CType1 CName1, tdbType##CType2 CName2, tdbType##CType3 CName3, tdbType##CType4 CName4, tdbType##CType5 CName5, tdbType##CType6 CName6) { \
		const size_t ndx = GetSize(); \
		Insert##CType1 (0, ndx, CName1); \
		Insert##CType2 (1, ndx, CName2); \
		Insert##CType3 (2, ndx, CName3); \
		Insert##CType4 (3, ndx, CName4); \
		Insert##CType5 (4, ndx, CName5); \
		Insert##CType6 (5, ndx, CName6); \
		InsertDone(); \
	} \
\
	void Insert(size_t ndx, tdbType##CType1 CName1, tdbType##CType2 CName2, tdbType##CType3 CName3, tdbType##CType4 CName4, tdbType##CType5 CName5, tdbType##CType6 CName6) { \
		Insert##CType1 (0, ndx, CName1); \
		Insert##CType2 (1, ndx, CName2); \
		Insert##CType3 (2, ndx, CName3); \
		Insert##CType4 (3, ndx, CName4); \
		Insert##CType5 (4, ndx, CName5); \
		Insert##CType6 (5, ndx, CName6); \
		InsertDone(); \
	} \
\
	Cursor Add() {return Cursor(*this, AddRow());} \
	Cursor Get(size_t ndx) {return Cursor(*this, ndx);} \
	Cursor operator[](size_t ndx) {return Cursor(*this, ndx);} \
	const Cursor operator[](size_t ndx) const {return Cursor(*this, ndx);} \
	Cursor operator[](int ndx) {return Cursor(*this, (ndx < 0) ? GetSize() + ndx : ndx);} \
	Cursor Back() {return Cursor(*this, m_size-1);} \
	const Cursor Back() const {return Cursor(*this, m_size-1);} \
\
	size_t Find(const TableName##Query&) const {return (size_t)-1;} \
	TableName FindAll(const TableName##Query&) const {return TableName();} \
	TableName Sort() const {return TableName();} \
	TableName Range(int, int) const {return TableName();} \
	TableName Limit(size_t) const {return TableName();} \
\
	ColumnProxy##CType1 CName1; \
	ColumnProxy##CType2 CName2; \
	ColumnProxy##CType3 CName3; \
	ColumnProxy##CType4 CName4; \
	ColumnProxy##CType5 CName5; \
	ColumnProxy##CType6 CName6; \
\
private: \
	friend class Group; \
	TableName(Allocator& alloc, size_t ref, Parent *parent, size_t ndx_in_parent): \
		TopLevelTable(alloc, ref, parent, ndx_in_parent) {} \
	TableName(const TableName &); /* Disable */ \
	TableName& operator=(const TableName &); /* Disable */ \
};



#define TDB_TABLE_7(TableName, CType1, CName1, CType2, CName2, CType3, CName3, CType4, CName4, CType5, CName5, CType6, CName6, CType7, CName7) \
class TableName##Query { \
protected: \
	QueryAccessor##CType1 CName1; \
	QueryAccessor##CType2 CName2; \
	QueryAccessor##CType3 CName3; \
	QueryAccessor##CType4 CName4; \
	QueryAccessor##CType5 CName5; \
	QueryAccessor##CType6 CName6; \
	QueryAccessor##CType7 CName7; \
}; \
\
class TableName : public TopLevelTable { \
public: \
	TableName(Allocator& alloc=GetDefaultAllocator()) : TopLevelTable(alloc) { \
		RegisterColumn(Accessor##CType1::type, #CName1); \
		RegisterColumn(Accessor##CType2::type, #CName2); \
		RegisterColumn(Accessor##CType3::type, #CName3); \
		RegisterColumn(Accessor##CType4::type, #CName4); \
		RegisterColumn(Accessor##CType5::type, #CName5); \
		RegisterColumn(Accessor##CType6::type, #CName6); \
		RegisterColumn(Accessor##CType7::type, #CName7); \
\
		CName1.Create(this, 0); \
		CName2.Create(this, 1); \
		CName3.Create(this, 2); \
		CName4.Create(this, 3); \
		CName5.Create(this, 4); \
		CName6.Create(this, 5); \
		CName7.Create(this, 6); \
	}; \
\
	class TestQuery : public Query { \
	public: \
		TestQuery() : CName1(0), CName2(1), CName3(2), CName4(3), CName5(4), CName6(5), CName7(6) { \
			CName1.SetQuery(this); \
			CName2.SetQuery(this); \
			CName3.SetQuery(this); \
			CName4.SetQuery(this); \
			CName5.SetQuery(this); \
			CName6.SetQuery(this); \
			CName7.SetQuery(this); \
		} \
\
		TestQuery(const TestQuery& copy) : Query(copy), CName1(0), CName2(1), CName3(2), CName4(3), CName5(4), CName6(5), CName7(6) { \
			CName1.SetQuery(this); \
			CName2.SetQuery(this); \
			CName3.SetQuery(this); \
			CName4.SetQuery(this); \
			CName5.SetQuery(this); \
			CName6.SetQuery(this); \
			CName7.SetQuery(this); \
		} \
\
		class TestQueryQueryAccessorInt : private XQueryAccessorInt { \
		public: \
			TestQueryQueryAccessorInt(size_t column_id) : XQueryAccessorInt(column_id) {} \
			void SetQuery(Query* query) {m_query = query;} \
\
			TestQuery& Equal(int64_t value) {return static_cast<TestQuery &>(XQueryAccessorInt::Equal(value));} \
			TestQuery& NotEqual(int64_t value) {return static_cast<TestQuery &>(XQueryAccessorInt::NotEqual(value));} \
			TestQuery& Greater(int64_t value) {return static_cast<TestQuery &>(XQueryAccessorInt::Greater(value));} \
			TestQuery& Less(int64_t value) {return static_cast<TestQuery &>(XQueryAccessorInt::Less(value));} \
			TestQuery& Between(int64_t from, int64_t to) {return static_cast<TestQuery &>(XQueryAccessorInt::Between(from, to));} \
		}; \
\
		template <class T> class TestQueryQueryAccessorEnum : public TestQueryQueryAccessorInt { \
		public: \
			TestQueryQueryAccessorEnum<T>(size_t column_id) : TestQueryQueryAccessorInt(column_id) {} \
		}; \
\
		class TestQueryQueryAccessorString : private XQueryAccessorString { \
		public: \
			TestQueryQueryAccessorString(size_t column_id) : XQueryAccessorString(column_id) {} \
			void SetQuery(Query* query) {m_query = query;} \
\
			TestQuery& Equal(const char *value, bool CaseSensitive = true) {return static_cast<TestQuery &>(XQueryAccessorString::Equal(value, CaseSensitive));} \
			TestQuery& NotEqual(const char *value, bool CaseSensitive = true) {return static_cast<TestQuery &>(XQueryAccessorString::NotEqual(value, CaseSensitive));} \
			TestQuery& BeginsWith(const char *value, bool CaseSensitive = true) {return static_cast<TestQuery &>(XQueryAccessorString::BeginsWith(value, CaseSensitive));} \
			TestQuery& EndsWith(const char *value, bool CaseSensitive = true) {return static_cast<TestQuery &>(XQueryAccessorString::EndsWith(value, CaseSensitive));} \
			TestQuery& Contains(const char *value, bool CaseSensitive = true) {return static_cast<TestQuery &>(XQueryAccessorString::Contains(value, CaseSensitive));} \
		}; \
\
		class TestQueryQueryAccessorBool : private XQueryAccessorBool { \
		public: \
			TestQueryQueryAccessorBool(size_t column_id) : XQueryAccessorBool(column_id) {} \
			void SetQuery(Query* query) {m_query = query;} \
\
			TestQuery& Equal(bool value) {return static_cast<TestQuery &>(XQueryAccessorBool::Equal(value));} \
		}; \
\
		class TestQueryQueryAccessorMixed : private XQueryAccessorMixed { \
		public: \
			TestQueryQueryAccessorMixed(size_t column_id) : XQueryAccessorMixed(column_id) {} \
			void SetQuery(Query* query) {m_query = query;} \
		}; \
\
		TestQueryQueryAccessor##CType1 CName1; \
		TestQueryQueryAccessor##CType2 CName2; \
		TestQueryQueryAccessor##CType3 CName3; \
		TestQueryQueryAccessor##CType4 CName4; \
		TestQueryQueryAccessor##CType5 CName5; \
		TestQueryQueryAccessor##CType6 CName6; \
		TestQueryQueryAccessor##CType7 CName7; \
\
		TestQuery& LeftParan(void) {Query::LeftParan(); return *this;}; \
		TestQuery& Or(void) {Query::Or(); return *this;}; \
		TestQuery& RightParan(void) {Query::RightParan(); return *this;}; \
		TestQuery& Subtable(size_t column) {Query::Subtable(column); return *this;}; \
		TestQuery& Parent() {Query::Parent(); return *this;}; \
	}; \
\
	TestQuery GetQuery() {return TestQuery();} \
\
	class Cursor : public CursorBase { \
	public: \
		Cursor(TableName& table, size_t ndx) : CursorBase(table, ndx) { \
			CName1.Create(this, 0); \
			CName2.Create(this, 1); \
			CName3.Create(this, 2); \
			CName4.Create(this, 3); \
			CName5.Create(this, 4); \
			CName6.Create(this, 5); \
			CName7.Create(this, 6); \
		} \
		Cursor(const TableName& table, size_t ndx) : CursorBase(const_cast<TableName&>(table), ndx) { \
			CName1.Create(this, 0); \
			CName2.Create(this, 1); \
			CName3.Create(this, 2); \
			CName4.Create(this, 3); \
			CName5.Create(this, 4); \
			CName6.Create(this, 5); \
			CName7.Create(this, 6); \
		} \
		Cursor(const Cursor& v) : CursorBase(v) { \
			CName1.Create(this, 0); \
			CName2.Create(this, 1); \
			CName3.Create(this, 2); \
			CName4.Create(this, 3); \
			CName5.Create(this, 4); \
			CName6.Create(this, 5); \
			CName7.Create(this, 6); \
		} \
		Accessor##CType1 CName1; \
		Accessor##CType2 CName2; \
		Accessor##CType3 CName3; \
		Accessor##CType4 CName4; \
		Accessor##CType5 CName5; \
		Accessor##CType6 CName6; \
		Accessor##CType7 CName7; \
	}; \
\
	void Add(tdbType##CType1 CName1, tdbType##CType2 CName2, tdbType##CType3 CName3, tdbType##CType4 CName4, tdbType##CType5 CName5, tdbType##CType6 CName6, tdbType##CType7 CName7) { \
		const size_t ndx = GetSize(); \
		Insert##CType1 (0, ndx, CName1); \
		Insert##CType2 (1, ndx, CName2); \
		Insert##CType3 (2, ndx, CName3); \
		Insert##CType4 (3, ndx, CName4); \
		Insert##CType5 (4, ndx, CName5); \
		Insert##CType6 (5, ndx, CName6); \
		Insert##CType7 (6, ndx, CName7); \
		InsertDone(); \
	} \
\
	void Insert(size_t ndx, tdbType##CType1 CName1, tdbType##CType2 CName2, tdbType##CType3 CName3, tdbType##CType4 CName4, tdbType##CType5 CName5, tdbType##CType6 CName6, tdbType##CType7 CName7) { \
		Insert##CType1 (0, ndx, CName1); \
		Insert##CType2 (1, ndx, CName2); \
		Insert##CType3 (2, ndx, CName3); \
		Insert##CType4 (3, ndx, CName4); \
		Insert##CType5 (4, ndx, CName5); \
		Insert##CType6 (5, ndx, CName6); \
		Insert##CType7 (6, ndx, CName7); \
		InsertDone(); \
	} \
\
	Cursor Add() {return Cursor(*this, AddRow());} \
	Cursor Get(size_t ndx) {return Cursor(*this, ndx);} \
	Cursor operator[](size_t ndx) {return Cursor(*this, ndx);} \
	const Cursor operator[](size_t ndx) const {return Cursor(*this, ndx);} \
	Cursor operator[](int ndx) {return Cursor(*this, (ndx < 0) ? GetSize() + ndx : ndx);} \
	Cursor Back() {return Cursor(*this, m_size-1);} \
	const Cursor Back() const {return Cursor(*this, m_size-1);} \
\
	size_t Find(const TableName##Query&) const {return (size_t)-1;} \
	TableName FindAll(const TableName##Query&) const {return TableName();} \
	TableName Sort() const {return TableName();} \
	TableName Range(int, int) const {return TableName();} \
	TableName Limit(size_t) const {return TableName();} \
\
	ColumnProxy##CType1 CName1; \
	ColumnProxy##CType2 CName2; \
	ColumnProxy##CType3 CName3; \
	ColumnProxy##CType4 CName4; \
	ColumnProxy##CType5 CName5; \
	ColumnProxy##CType6 CName6; \
	ColumnProxy##CType7 CName7; \
\
private: \
	friend class Group; \
	TableName(Allocator& alloc, size_t ref, Parent *parent, size_t ndx_in_parent): \
		TopLevelTable(alloc, ref, parent, ndx_in_parent) {} \
	TableName(const TableName &); /* Disable */ \
	TableName& operator=(const TableName &); /* Disable */ \
};



#define TDB_TABLE_8(TableName, CType1, CName1, CType2, CName2, CType3, CName3, CType4, CName4, CType5, CName5, CType6, CName6, CType7, CName7, CType8, CName8) \
class TableName##Query { \
protected: \
	QueryAccessor##CType1 CName1; \
	QueryAccessor##CType2 CName2; \
	QueryAccessor##CType3 CName3; \
	QueryAccessor##CType4 CName4; \
	QueryAccessor##CType5 CName5; \
	QueryAccessor##CType6 CName6; \
	QueryAccessor##CType7 CName7; \
	QueryAccessor##CType8 CName8; \
}; \
\
class TableName : public TopLevelTable { \
public: \
	TableName(Allocator& alloc=GetDefaultAllocator()) : TopLevelTable(alloc) { \
		RegisterColumn(Accessor##CType1::type, #CName1); \
		RegisterColumn(Accessor##CType2::type, #CName2); \
		RegisterColumn(Accessor##CType3::type, #CName3); \
		RegisterColumn(Accessor##CType4::type, #CName4); \
		RegisterColumn(Accessor##CType5::type, #CName5); \
		RegisterColumn(Accessor##CType6::type, #CName6); \
		RegisterColumn(Accessor##CType7::type, #CName7); \
		RegisterColumn(Accessor##CType8::type, #CName8); \
\
		CName1.Create(this, 0); \
		CName2.Create(this, 1); \
		CName3.Create(this, 2); \
		CName4.Create(this, 3); \
		CName5.Create(this, 4); \
		CName6.Create(this, 5); \
		CName7.Create(this, 6); \
		CName8.Create(this, 7); \
	}; \
\
	class TestQuery : public Query { \
	public: \
		TestQuery() : CName1(0), CName2(1), CName3(2), CName4(3), CName5(4), CName6(5), CName7(6), CName8(7) { \
			CName1.SetQuery(this); \
			CName2.SetQuery(this); \
			CName3.SetQuery(this); \
			CName4.SetQuery(this); \
			CName5.SetQuery(this); \
			CName6.SetQuery(this); \
			CName7.SetQuery(this); \
			CName8.SetQuery(this); \
		} \
\
		TestQuery(const TestQuery& copy) : Query(copy), CName1(0), CName2(1), CName3(2), CName4(3), CName5(4), CName6(5), CName7(6), CName8(7) { \
			CName1.SetQuery(this); \
			CName2.SetQuery(this); \
			CName3.SetQuery(this); \
			CName4.SetQuery(this); \
			CName5.SetQuery(this); \
			CName6.SetQuery(this); \
			CName7.SetQuery(this); \
			CName8.SetQuery(this); \
		} \
\
		class TestQueryQueryAccessorInt : private XQueryAccessorInt { \
		public: \
			TestQueryQueryAccessorInt(size_t column_id) : XQueryAccessorInt(column_id) {} \
			void SetQuery(Query* query) {m_query = query;} \
\
			TestQuery& Equal(int64_t value) {return static_cast<TestQuery &>(XQueryAccessorInt::Equal(value));} \
			TestQuery& NotEqual(int64_t value) {return static_cast<TestQuery &>(XQueryAccessorInt::NotEqual(value));} \
			TestQuery& Greater(int64_t value) {return static_cast<TestQuery &>(XQueryAccessorInt::Greater(value));} \
			TestQuery& Less(int64_t value) {return static_cast<TestQuery &>(XQueryAccessorInt::Less(value));} \
			TestQuery& Between(int64_t from, int64_t to) {return static_cast<TestQuery &>(XQueryAccessorInt::Between(from, to));} \
		}; \
\
		template <class T> class TestQueryQueryAccessorEnum : public TestQueryQueryAccessorInt { \
		public: \
			TestQueryQueryAccessorEnum<T>(size_t column_id) : TestQueryQueryAccessorInt(column_id) {} \
		}; \
\
		class TestQueryQueryAccessorString : private XQueryAccessorString { \
		public: \
			TestQueryQueryAccessorString(size_t column_id) : XQueryAccessorString(column_id) {} \
			void SetQuery(Query* query) {m_query = query;} \
\
			TestQuery& Equal(const char *value, bool CaseSensitive = true) {return static_cast<TestQuery &>(XQueryAccessorString::Equal(value, CaseSensitive));} \
			TestQuery& NotEqual(const char *value, bool CaseSensitive = true) {return static_cast<TestQuery &>(XQueryAccessorString::NotEqual(value, CaseSensitive));} \
			TestQuery& BeginsWith(const char *value, bool CaseSensitive = true) {return static_cast<TestQuery &>(XQueryAccessorString::BeginsWith(value, CaseSensitive));} \
			TestQuery& EndsWith(const char *value, bool CaseSensitive = true) {return static_cast<TestQuery &>(XQueryAccessorString::EndsWith(value, CaseSensitive));} \
			TestQuery& Contains(const char *value, bool CaseSensitive = true) {return static_cast<TestQuery &>(XQueryAccessorString::Contains(value, CaseSensitive));} \
		}; \
\
		class TestQueryQueryAccessorBool : private XQueryAccessorBool { \
		public: \
			TestQueryQueryAccessorBool(size_t column_id) : XQueryAccessorBool(column_id) {} \
			void SetQuery(Query* query) {m_query = query;} \
\
			TestQuery& Equal(bool value) {return static_cast<TestQuery &>(XQueryAccessorBool::Equal(value));} \
		}; \
\
		class TestQueryQueryAccessorMixed : private XQueryAccessorMixed { \
		public: \
			TestQueryQueryAccessorMixed(size_t column_id) : XQueryAccessorMixed(column_id) {} \
			void SetQuery(Query* query) {m_query = query;} \
		}; \
\
		TestQueryQueryAccessor##CType1 CName1; \
		TestQueryQueryAccessor##CType2 CName2; \
		TestQueryQueryAccessor##CType3 CName3; \
		TestQueryQueryAccessor##CType4 CName4; \
		TestQueryQueryAccessor##CType5 CName5; \
		TestQueryQueryAccessor##CType6 CName6; \
		TestQueryQueryAccessor##CType7 CName7; \
		TestQueryQueryAccessor##CType8 CName8; \
\
		TestQuery& LeftParan(void) {Query::LeftParan(); return *this;}; \
		TestQuery& Or(void) {Query::Or(); return *this;}; \
		TestQuery& RightParan(void) {Query::RightParan(); return *this;}; \
		TestQuery& Subtable(size_t column) {Query::Subtable(column); return *this;}; \
		TestQuery& Parent() {Query::Parent(); return *this;}; \
	}; \
\
	TestQuery GetQuery() {return TestQuery();} \
\
	class Cursor : public CursorBase { \
	public: \
		Cursor(TableName& table, size_t ndx) : CursorBase(table, ndx) { \
			CName1.Create(this, 0); \
			CName2.Create(this, 1); \
			CName3.Create(this, 2); \
			CName4.Create(this, 3); \
			CName5.Create(this, 4); \
			CName6.Create(this, 5); \
			CName7.Create(this, 6); \
			CName8.Create(this, 7); \
		} \
		Cursor(const TableName& table, size_t ndx) : CursorBase(const_cast<TableName&>(table), ndx) { \
			CName1.Create(this, 0); \
			CName2.Create(this, 1); \
			CName3.Create(this, 2); \
			CName4.Create(this, 3); \
			CName5.Create(this, 4); \
			CName6.Create(this, 5); \
			CName7.Create(this, 6); \
			CName8.Create(this, 7); \
		} \
		Cursor(const Cursor& v) : CursorBase(v) { \
			CName1.Create(this, 0); \
			CName2.Create(this, 1); \
			CName3.Create(this, 2); \
			CName4.Create(this, 3); \
			CName5.Create(this, 4); \
			CName6.Create(this, 5); \
			CName7.Create(this, 6); \
			CName8.Create(this, 7); \
		} \
		Accessor##CType1 CName1; \
		Accessor##CType2 CName2; \
		Accessor##CType3 CName3; \
		Accessor##CType4 CName4; \
		Accessor##CType5 CName5; \
		Accessor##CType6 CName6; \
		Accessor##CType7 CName7; \
		Accessor##CType8 CName8; \
	}; \
\
	void Add(tdbType##CType1 CName1, tdbType##CType2 CName2, tdbType##CType3 CName3, tdbType##CType4 CName4, tdbType##CType5 CName5, tdbType##CType6 CName6, tdbType##CType7 CName7, tdbType##CType8 CName8) { \
		const size_t ndx = GetSize(); \
		Insert##CType1 (0, ndx, CName1); \
		Insert##CType2 (1, ndx, CName2); \
		Insert##CType3 (2, ndx, CName3); \
		Insert##CType4 (3, ndx, CName4); \
		Insert##CType5 (4, ndx, CName5); \
		Insert##CType6 (5, ndx, CName6); \
		Insert##CType7 (6, ndx, CName7); \
		Insert##CType8 (7, ndx, CName8); \
		InsertDone(); \
	} \
\
	void Insert(size_t ndx, tdbType##CType1 CName1, tdbType##CType2 CName2, tdbType##CType3 CName3, tdbType##CType4 CName4, tdbType##CType5 CName5, tdbType##CType6 CName6, tdbType##CType7 CName7, tdbType##CType8 CName8) { \
		Insert##CType1 (0, ndx, CName1); \
		Insert##CType2 (1, ndx, CName2); \
		Insert##CType3 (2, ndx, CName3); \
		Insert##CType4 (3, ndx, CName4); \
		Insert##CType5 (4, ndx, CName5); \
		Insert##CType6 (5, ndx, CName6); \
		Insert##CType7 (6, ndx, CName7); \
		Insert##CType8 (7, ndx, CName8); \
		InsertDone(); \
	} \
\
	Cursor Add() {return Cursor(*this, AddRow());} \
	Cursor Get(size_t ndx) {return Cursor(*this, ndx);} \
	Cursor operator[](size_t ndx) {return Cursor(*this, ndx);} \
	const Cursor operator[](size_t ndx) const {return Cursor(*this, ndx);} \
	Cursor operator[](int ndx) {return Cursor(*this, (ndx < 0) ? GetSize() + ndx : ndx);} \
	Cursor Back() {return Cursor(*this, m_size-1);} \
	const Cursor Back() const {return Cursor(*this, m_size-1);} \
\
	size_t Find(const TableName##Query&) const {return (size_t)-1;} \
	TableName FindAll(const TableName##Query&) const {return TableName();} \
	TableName Sort() const {return TableName();} \
	TableName Range(int, int) const {return TableName();} \
	TableName Limit(size_t) const {return TableName();} \
\
	ColumnProxy##CType1 CName1; \
	ColumnProxy##CType2 CName2; \
	ColumnProxy##CType3 CName3; \
	ColumnProxy##CType4 CName4; \
	ColumnProxy##CType5 CName5; \
	ColumnProxy##CType6 CName6; \
	ColumnProxy##CType7 CName7; \
	ColumnProxy##CType8 CName8; \
\
private: \
	friend class Group; \
	TableName(Allocator& alloc, size_t ref, Parent *parent, size_t ndx_in_parent): \
		TopLevelTable(alloc, ref, parent, ndx_in_parent) {} \
	TableName(const TableName &); /* Disable */ \
	TableName& operator=(const TableName &); /* Disable */ \
};

#endif //__TIGHTDB_H__
