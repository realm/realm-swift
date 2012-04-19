import sys
from Cheetah.Template import Template

templateDef = """#slurp
#compiler-settings
commentStartToken = %%
directiveStartToken = %
#end compiler-settings
#ifndef __TIGHTDB_H__
#define __TIGHTDB_H__

#include "Table.h"
#include <vector>

#include "query/QueryInterface.h"

using namespace std;

#define TDB_QUERY(QueryName, TableName) \\
class QueryName : public TableName##Query { \\
public: \\
QueryName()

#define TDB_QUERY_OPT(QueryName, TableName) \\
class QueryName : public TableName##Query { \\
public: \\
QueryName

#define TDB_QUERY_END }; \\
%for $i in range($max_cols)
%set $num_cols = $i + 1



#define TDB_TABLE_${num_cols}(TableName%slurp
%for $j in range($num_cols)
, CType${j+1}, CName${j+1}%slurp
%end for
) \\
class TableName##Query { \\
protected: \\
%for $j in range($num_cols)
	QueryAccessor##CType${j+1} CName${j+1}; \\
%end for
}; \\
\\
class TableName : public TopLevelTable { \\
public: \\
	TableName(Allocator& alloc=GetDefaultAllocator()) : TopLevelTable(alloc) { \\
%for $j in range($num_cols)
		RegisterColumn(Accessor##CType${j+1}::type, #CName${j+1}); \\
%end for
\\
%for $j in range($num_cols)
		CName${j+1}.Create(this, $j); \\
%end for
	}; \\
\\
	class TestQuery : public Query { \\
	public: \\
		TestQuery() : %slurp
%for $j in range($num_cols)
%if 0 < $j
, %slurp
%end if
CName${j+1}%slurp
($j)%slurp
%end for
 { \\
%for $j in range($num_cols)
			CName${j+1}.SetQuery(this); \\
%end for
		} \\
\\
		TestQuery(const TestQuery& copy) : Query(copy)%slurp
%for $j in range($num_cols)
, CName${j+1}%slurp
($j)%slurp
%end for
 { \\
%for $j in range($num_cols)
			CName${j+1}.SetQuery(this); \\
%end for
		} \\
\\
		class TestQueryQueryAccessorInt : private XQueryAccessorInt { \\
		public: \\
			TestQueryQueryAccessorInt(size_t column_id) : XQueryAccessorInt(column_id) {} \\
			void SetQuery(Query* query) {m_query = query;} \\
\\
			TestQuery& Equal(int64_t value) {return static_cast<TestQuery &>(XQueryAccessorInt::Equal(value));} \\
			TestQuery& NotEqual(int64_t value) {return static_cast<TestQuery &>(XQueryAccessorInt::NotEqual(value));} \\
			TestQuery& Greater(int64_t value) {return static_cast<TestQuery &>(XQueryAccessorInt::Greater(value));} \\
			TestQuery& Less(int64_t value) {return static_cast<TestQuery &>(XQueryAccessorInt::Less(value));} \\
			TestQuery& Between(int64_t from, int64_t to) {return static_cast<TestQuery &>(XQueryAccessorInt::Between(from, to));} \\
		}; \\
\\
		template <class T> class TestQueryQueryAccessorEnum : public TestQueryQueryAccessorInt { \\
		public: \\
			TestQueryQueryAccessorEnum<T>(size_t column_id) : TestQueryQueryAccessorInt(column_id) {} \\
		}; \\
\\
		class TestQueryQueryAccessorString : private XQueryAccessorString { \\
		public: \\
			TestQueryQueryAccessorString(size_t column_id) : XQueryAccessorString(column_id) {} \\
			void SetQuery(Query* query) {m_query = query;} \\
\\
			TestQuery& Equal(const char *value, bool CaseSensitive = true) {return static_cast<TestQuery &>(XQueryAccessorString::Equal(value, CaseSensitive));} \\
			TestQuery& NotEqual(const char *value, bool CaseSensitive = true) {return static_cast<TestQuery &>(XQueryAccessorString::NotEqual(value, CaseSensitive));} \\
			TestQuery& BeginsWith(const char *value, bool CaseSensitive = true) {return static_cast<TestQuery &>(XQueryAccessorString::BeginsWith(value, CaseSensitive));} \\
			TestQuery& EndsWith(const char *value, bool CaseSensitive = true) {return static_cast<TestQuery &>(XQueryAccessorString::EndsWith(value, CaseSensitive));} \\
			TestQuery& Contains(const char *value, bool CaseSensitive = true) {return static_cast<TestQuery &>(XQueryAccessorString::Contains(value, CaseSensitive));} \\
		}; \\
\\
		class TestQueryQueryAccessorBool : private XQueryAccessorBool { \\
		public: \\
			TestQueryQueryAccessorBool(size_t column_id) : XQueryAccessorBool(column_id) {} \\
			void SetQuery(Query* query) {m_query = query;} \\
\\
			TestQuery& Equal(bool value) {return static_cast<TestQuery &>(XQueryAccessorBool::Equal(value));} \\
		}; \\
\\
		class TestQueryQueryAccessorMixed : private XQueryAccessorMixed { \\
		public: \\
			TestQueryQueryAccessorMixed(size_t column_id) : XQueryAccessorMixed(column_id) {} \\
			void SetQuery(Query* query) {m_query = query;} \\
		}; \\
\\
%for $j in range($num_cols)
		TestQueryQueryAccessor##CType${j+1} CName${j+1}; \\
%end for
\\
		TestQuery& LeftParan(void) {Query::LeftParan(); return *this;}; \\
		TestQuery& Or(void) {Query::Or(); return *this;}; \\
		TestQuery& RightParan(void) {Query::RightParan(); return *this;}; \\
		TestQuery& Subtable(size_t column) {Query::Subtable(column); return *this;}; \\
		TestQuery& Parent() {Query::Parent(); return *this;}; \\
	}; \\
\\
	TestQuery GetQuery() {return TestQuery();} \\
\\
	class Cursor : public CursorBase { \\
	public: \\
		Cursor(TableName& table, size_t ndx) : CursorBase(table, ndx) { \\
%for $j in range($num_cols)
			CName${j+1}.Create(this, $j); \\
%end for
		} \\
		Cursor(const TableName& table, size_t ndx) : CursorBase(const_cast<TableName&>(table), ndx) { \\
%for $j in range($num_cols)
			CName${j+1}.Create(this, $j); \\
%end for
		} \\
		Cursor(const Cursor& v) : CursorBase(v) { \\
%for $j in range($num_cols)
			CName${j+1}.Create(this, $j); \\
%end for
		} \\
%for $j in range($num_cols)
		Accessor##CType${j+1} CName${j+1}; \\
%end for
	}; \\
\\
	void Add(%slurp
%for $j in range($num_cols)
%if 0 < $j
, %slurp
%end if
tdbType##CType${j+1} CName${j+1}%slurp
%end for
) { \\
		const size_t ndx = GetSize(); \\
%for $j in range($num_cols)
		Insert##CType${j+1} ($j, ndx, CName${j+1}); \\
%end for
		InsertDone(); \\
	} \\
\\
	void Insert(size_t ndx%slurp
%for $j in range($num_cols)
, tdbType##CType${j+1} CName${j+1}%slurp
%end for
) { \\
%for $j in range($num_cols)
		Insert##CType${j+1} ($j, ndx, CName${j+1}); \\
%end for
		InsertDone(); \\
	} \\
\\
	Cursor Add() {return Cursor(*this, AddRow());} \\
	Cursor Get(size_t ndx) {return Cursor(*this, ndx);} \\
	Cursor operator[](size_t ndx) {return Cursor(*this, ndx);} \\
	const Cursor operator[](size_t ndx) const {return Cursor(*this, ndx);} \\
	Cursor operator[](int ndx) {return Cursor(*this, (ndx < 0) ? GetSize() + ndx : ndx);} \\
	Cursor Back() {return Cursor(*this, m_size-1);} \\
	const Cursor Back() const {return Cursor(*this, m_size-1);} \\
\\
	size_t Find(const TableName##Query&) const {return (size_t)-1;} \\
	TableName FindAll(const TableName##Query&) const {return TableName();} \\
	TableName Sort() const {return TableName();} \\
	TableName Range(int, int) const {return TableName();} \\
	TableName Limit(size_t) const {return TableName();} \\
\\
%for $j in range($num_cols)
	ColumnProxy##CType${j+1} CName${j+1}; \\
%end for
\\
private: \\
	friend class Group; \\
	TableName(Allocator& alloc, size_t ref, Parent *parent, size_t ndx_in_parent): \\
		TopLevelTable(alloc, ref, parent, ndx_in_parent) {} \\
	TableName(const TableName &); /* Disable */ \\
	TableName& operator=(const TableName &); /* Disable */ \\
};
%end for

#endif //__TIGHTDB_H__
"""

args = sys.argv[1:]
if len(args) != 1:
	sys.stderr.write("Please specify the maximum number of table columns\n")
	sys.exit(1)
max_cols = int(args[0])
t = Template(templateDef, searchList=[{'max_cols': max_cols}])
sys.stdout.write(str(t))
