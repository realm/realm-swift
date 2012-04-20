#ifndef __TDB_TABLE__
#define __TDB_TABLE__

#include <cstring> // strcmp()
#include <time.h>
#include "Column.h"
#include "ColumnString.h"
#include "ColumnStringEnum.h"
#include "ColumnBinary.h"
#include "alloc.h"
#include "ColumnType.h"
#include "TableRef.hpp"

namespace tightdb {

class Accessor;
class TableView;
class Group;
class ColumnTable;
class ColumnMixed;
class Table;
class TopLevelTable;


class Date {
public:
	Date(time_t d) : m_date(d) {}
	time_t GetDate() const {return m_date;}
private:
	time_t m_date;
};



class Mixed {
public:
	explicit Mixed(ColumnType v)  {assert(v == COLUMN_TYPE_TABLE); (void)v; m_type = COLUMN_TYPE_TABLE;}
	Mixed(bool v)        {m_type = COLUMN_TYPE_BOOL;   m_bool = v;}
	Mixed(Date v)        {m_type = COLUMN_TYPE_DATE;   m_date = v.GetDate();}
	Mixed(int64_t v)     {m_type = COLUMN_TYPE_INT;    m_int  = v;}
	Mixed(const char* v) {m_type = COLUMN_TYPE_STRING; m_str  = v;}
	Mixed(BinaryData v)  {m_type = COLUMN_TYPE_BINARY; m_str = (const char*)v.pointer; m_len = v.len;}
	Mixed(const char* v, size_t len) {m_type = COLUMN_TYPE_BINARY; m_str = v; m_len = len;}

	ColumnType GetType() const {return m_type;}

	int64_t     GetInt()    const {assert(m_type == COLUMN_TYPE_INT);    return m_int;}
	bool        GetBool()   const {assert(m_type == COLUMN_TYPE_BOOL);   return m_bool;}
	time_t      GetDate()   const {assert(m_type == COLUMN_TYPE_DATE);   return m_date;}
	const char* GetString() const {assert(m_type == COLUMN_TYPE_STRING); return m_str;}
	BinaryData	GetBinary() const {assert(m_type == COLUMN_TYPE_BINARY); BinaryData b = {m_str, m_len}; return b;}

private:
	ColumnType m_type;
	union {
		int64_t m_int;
		bool    m_bool;
		time_t  m_date;
		const char* m_str;
	};
	size_t m_len;
};



class Spec {
public:
	Spec(Allocator& alloc, size_t ref, ArrayParent *parent, size_t pndx);
	Spec(const Spec& s);

	void AddColumn(ColumnType type, const char* name);
	Spec AddColumnTable(const char* name);

	Spec GetSpec(size_t column_id);
	const Spec GetSpec(size_t column_id) const;

	size_t GetColumnCount() const;
	ColumnType GetColumnType(size_t ndx) const;
	const char* GetColumnName(size_t ndx) const;
	size_t GetColumnIndex(const char* name) const;

	size_t GetRef() const {return m_specSet.GetRef();}

	// Serialization
	template<class S> size_t Write(S& out, size_t& pos) const;

#ifdef _DEBUG
	void ToDot(std::ostream& out, const char* title=NULL) const;
#endif //_DEBUG

private:
	void Create(size_t ref, ArrayParent *parent, size_t pndx);

	Array m_specSet;
	Array m_spec;
	ArrayString m_names;
	Array m_subSpecs;
};



typedef BasicTableRef<Table> TableRef;
typedef BasicTableRef<Table const> TableConstRef;

typedef BasicTableRef<TopLevelTable> TopLevelTableRef;
typedef BasicTableRef<TopLevelTable const> TopLevelTableConstRef;


class Table {
public:
	Table(Allocator& alloc=GetDefaultAllocator());
	virtual ~Table();

	TableRef GetTableRef() { return TableRef(this); }
	TableConstRef GetTableRef() const { return TableConstRef(this); }

	// Column meta info
	size_t GetColumnCount() const;
	const char* GetColumnName(size_t ndx) const;
	size_t GetColumnIndex(const char* name) const;
	ColumnType GetColumnType(size_t ndx) const;
	Spec GetSpec();
	const Spec GetSpec() const;

	bool IsEmpty() const {return m_size == 0;}
	size_t GetSize() const {return m_size;}

	size_t AddRow();
	void Clear();
	void DeleteRow(size_t ndx);
	void PopBack() {if (!IsEmpty()) DeleteRow(m_size-1);}

	// Adaptive ints
	int64_t Get(size_t column_id, size_t ndx) const;
	void Set(size_t column_id, size_t ndx, int64_t value);
	bool GetBool(size_t column_id, size_t ndx) const;
	void SetBool(size_t column_id, size_t ndx, bool value);
	time_t GetDate(size_t column_id, size_t ndx) const;
	void SetDate(size_t column_id, size_t ndx, time_t value);

	// NOTE: Low-level insert functions. Always insert in all columns at once
	// and call InsertDone after to avoid table getting un-balanced.
	void InsertInt(size_t column_id, size_t ndx, int64_t value);
	void InsertBool(size_t column_id, size_t ndx, bool value) {InsertInt(column_id, ndx, value ? 1 :0);}
	void InsertDate(size_t column_id, size_t ndx, time_t value) {InsertInt(column_id, ndx, (int64_t)value);}
	template<class T> void InsertEnum(size_t column_id, size_t ndx, T value) {
		InsertInt(column_id, ndx, (int)value);
	}
	void InsertString(size_t column_id, size_t ndx, const char* value);
	void InsertBinary(size_t column_id, size_t ndx, const void* value, size_t len);
	void InsertDone();

	// Strings
	const char* GetString(size_t column_id, size_t ndx) const;
	void SetString(size_t column_id, size_t ndx, const char* value);

	// Binary
	BinaryData GetBinary(size_t column_id, size_t ndx) const;
	void SetBinary(size_t column_id, size_t ndx, const void* value, size_t len);

	// Sub-tables
	TableRef GetTable(size_t column_id, size_t ndx);
	TableConstRef GetTable(size_t column_id, size_t ndx) const;
	TopLevelTableRef GetTopLevelTable(size_t column_id, size_t ndx); // Must be a mixed column
	TopLevelTableConstRef GetTopLevelTable(size_t column_id, size_t ndx) const; // Must be a mixed column
	size_t GetTableSize(size_t column_id, size_t ndx) const;
	void   InsertTable(size_t column_id, size_t ndx);
	void   ClearTable(size_t column_id, size_t ndx);

	// Mixed
	Mixed GetMixed(size_t column_id, size_t ndx) const;
	ColumnType GetMixedType(size_t column_id, size_t ndx) const;
	void InsertMixed(size_t column_id, size_t ndx, Mixed value);
	void SetMixed(size_t column_id, size_t ndx, Mixed value);

	size_t RegisterColumn(ColumnType type, const char* name);

	Column& GetColumn(size_t ndx);
	const Column& GetColumn(size_t ndx) const;
	AdaptiveStringColumn& GetColumnString(size_t ndx);
	const AdaptiveStringColumn& GetColumnString(size_t ndx) const;
	ColumnBinary& GetColumnBinary(size_t ndx);
	const ColumnBinary& GetColumnBinary(size_t ndx) const;
	ColumnStringEnum& GetColumnStringEnum(size_t ndx);
	const ColumnStringEnum& GetColumnStringEnum(size_t ndx) const;
	ColumnTable& GetColumnTable(size_t ndx);
	const ColumnTable& GetColumnTable(size_t ndx) const;
	ColumnMixed& GetColumnMixed(size_t ndx);
	const ColumnMixed& GetColumnMixed(size_t ndx) const;

	// Searching
	size_t Find(size_t column_id, int64_t value) const;
	size_t FindBool(size_t column_id, bool value) const;
	size_t FindString(size_t column_id, const char* value) const;
	size_t FindDate(size_t column_id, time_t value) const;
	void FindAll(TableView& tv, size_t column_id, int64_t value);
	void FindAllBool(TableView& tv, size_t column_id, bool value);
	void FindAllString(TableView& tv, size_t column_id, const char *value);
	void FindAllHamming(TableView& tv, size_t column_id, uint64_t value, size_t max);

	// Indexing
	bool HasIndex(size_t column_id) const;
	void SetIndex(size_t column_id);

	// Optimizing
	void Optimize();

	// Conversion
	void to_json(std::ostream& out);

	// Debug
#ifdef _DEBUG
	bool Compare(const Table& c) const;
	void Verify() const;
	void ToDot(std::ostream& out, const char* title=NULL) const;
	void Print() const;
	MemStats Stats() const;
#endif //_DEBUG

	// todo, note, these three functions have been protected
	const ColumnBase& GetColumnBase(size_t ndx) const;
	ColumnType GetRealColumnType(size_t ndx) const;

	class Parent;

protected:
	friend class Group;
	friend class ColumnTable;
	friend class ColumnMixed;

	class NoInitTag {};

	/**
	 * Used when constructing subtables tables, that is, tables whose
	 * lifetime is managed by reference counting, not by the
	 * application.
	 */
	class SubtableTag {};

	Table(NoInitTag, Allocator &alloc); // Construct un-initialized

	Table(NoInitTag, SubtableTag, Allocator &alloc); // Construct subtable un-initialized

	/**
	 * Construct top-level table from ref.
	 */
	Table(Allocator &alloc, size_t ref_specSet, size_t columns_ref,
		  Parent *parent, size_t ndx_in_parent);

	/**
	 * Construct subtable from ref.
	 */
	Table(SubtableTag, Allocator &alloc, size_t ref_specSet, size_t columns_ref,
		  Parent *parent, size_t ndx_in_parent);

	void Create(size_t ref_specSet, size_t ref_columns, ArrayParent *parent, size_t ndx_in_parent);
	void CreateColumns();
	void CacheColumns();
	void ClearCachedColumns();

	// Specification
	size_t GetColumnRefPos(size_t column_ndx) const;
	void UpdateColumnRefs(size_t column_ndx, int diff);

	
#ifdef _DEBUG
	void ToDotInternal(std::ostream& out) const;
#endif //_DEBUG
	
	// Member variables
	size_t m_size;
	
	// On-disk format
	Array m_specSet;
	Array m_spec;
	ArrayString m_columnNames;
	Array m_subSpecs;
	Array m_columns;

	// Cached columns
	Array m_cols;

	std::size_t get_ref_count() const { return m_ref_count; }

private:
	Table(Table const &); // Disable copy construction
	Table &operator=(Table const &); // Disable copying assignment

	template<class> friend class BasicTableRef;
	friend class ColumnSubtableParent;

	mutable std::size_t m_ref_count;
	void bind_ref() const { ++m_ref_count; }
	void unbind_ref() const { if (--m_ref_count == 0) delete this; }

	ColumnBase& GetColumnBase(size_t ndx);
	void InstantiateBeforeChange();
};



class Table::Parent: public ArrayParent
{
protected:
	friend class Table;
	friend class TopLevelTable;

	/**
	 * Must be called whenever a child Table is destroyed.
	 */
	virtual void child_destroyed(std::size_t child_ndx) = 0;
};



class TopLevelTable : public Table {
public:
	TopLevelTable(Allocator& alloc=GetDefaultAllocator());
	virtual ~TopLevelTable();

	TopLevelTableRef GetTableRef() { return TopLevelTableRef(this); }
	TopLevelTableConstRef GetTableRef() const { return TopLevelTableConstRef(this); }

	void UpdateFromSpec(size_t ref_specSet);
	size_t GetRef() const;

	// Debug
#ifdef _DEBUG
	MemStats Stats() const;
	void DumpToDot(std::ostream& out) const;
	void ToDot(std::ostream& out, const char* title=NULL) const;
#endif //_DEBUG

protected:
	// On-disk format
	Array m_top;

	/**
	 * Construct top-level table from ref.
	 */
	TopLevelTable(Allocator& alloc, size_t ref_top, Parent *parent, size_t ndx_in_parent);

private:
	friend class Group;
	friend class ColumnMixed;

	/**
	 * Construct subtable from ref.
	 */
	TopLevelTable(SubtableTag, Allocator& alloc, size_t ref_top,
				  Parent *parent, size_t ndx_in_parent);

	void SetParent(Parent *parent, size_t ndx_in_parent);
};



class TableView {
public:
	TableView(Table& source);
	TableView(const TableView& v);
	~TableView();

	Table& GetParent() {return m_table;}
	Array& GetRefColumn() {return m_refs;}
	size_t GetRef(size_t ndx) const {return m_refs.GetAsRef(ndx);}

	bool IsEmpty() const {return m_refs.IsEmpty();}
	size_t GetSize() const {return m_refs.Size();}

	// Getting values
	int64_t Get(size_t column_id, size_t ndx) const;
	bool GetBool(size_t column_id, size_t ndx) const;
	time_t GetDate(size_t column_id, size_t ndx) const;
	const char* GetString(size_t column_id, size_t ndx) const;

	// Setting values
	void Set(size_t column_id, size_t ndx, int64_t value);
	void SetBool(size_t column_id, size_t ndx, bool value);
	void SetDate(size_t column_id, size_t ndx, time_t value);
	void SetString(size_t column_id, size_t ndx, const char* value);
	void Sort(size_t column, bool Ascending = true);
	// Sub-tables
	TableRef GetTable(size_t column_id, size_t ndx); // FIXME: Const version? Two kinds of TableView, one for const, one for non-const?

	// Deleting
	void Delete(size_t ndx);
	void Clear();

	// Finding
	size_t Find(size_t column_id, int64_t value) const;
	void FindAll(TableView& tv, size_t column_id, int64_t value);
	size_t FindString(size_t column_id, const char* value) const;
	void FindAllString(TableView& tv, size_t column_id, const char *value);

	// Aggregate functions
	int64_t Sum(size_t column_id) const;
	int64_t Max(size_t column_id) const;
	int64_t Min(size_t column_id) const;

	Table *GetTable(void); // todo, temporary for tests

private:
	// Don't allow copying
	TableView& operator=(const TableView&) {return *this;}

	Table& m_table;
	Array m_refs;
};


class CursorBase {
public:
	CursorBase(Table& table, size_t ndx) : m_table(table), m_index(ndx) {};
	CursorBase(const CursorBase& v) : m_table(v.m_table), m_index(v.m_index) {};

protected:
	Table& m_table;
	size_t m_index;
	friend class Accessor;

private:
	CursorBase& operator=(const CursorBase&) {return *this;}  // non assignable
};

class Accessor {
public:
	Accessor() {};
	void Create(CursorBase* cursor, size_t column_ndx) {m_cursor = cursor; m_column = column_ndx;}
	static const ColumnType type;

protected:
	int64_t Get() const {return m_cursor->m_table.Get(m_column, m_cursor->m_index);}
	void Set(int64_t value) {m_cursor->m_table.Set(m_column, m_cursor->m_index, value);}
	bool GetBool() const {return m_cursor->m_table.GetBool(m_column, m_cursor->m_index);}
	void SetBool(bool value) {m_cursor->m_table.SetBool(m_column, m_cursor->m_index, value);}
	time_t GetDate() const {return m_cursor->m_table.GetDate(m_column, m_cursor->m_index);}
	void SetDate(time_t value) {m_cursor->m_table.SetDate(m_column, m_cursor->m_index, value);}

	const char* GetString() const {return m_cursor->m_table.GetString(m_column, m_cursor->m_index);}
	void SetString(const char* value) {m_cursor->m_table.SetString(m_column, m_cursor->m_index, value);}

	Mixed GetMixed() const {return m_cursor->m_table.GetMixed(m_column, m_cursor->m_index);}
	ColumnType GetMixedType() const {return m_cursor->m_table.GetMixedType(m_column, m_cursor->m_index);}
	void SetMixed(Mixed value) {m_cursor->m_table.SetMixed(m_column, m_cursor->m_index, value);}

	CursorBase* m_cursor;
	size_t m_column;
};

class AccessorInt : public Accessor {
public:
	operator int64_t() const {return Get();}
	void operator=(int64_t value) {Set(value);}
	void operator+=(int64_t value) {Set(Get()+value);}
};

class AccessorBool : public Accessor {
public:
	operator bool() const {return GetBool();}
	void operator=(bool value) {SetBool(value);}
	void Flip() {Set(Get() != 0 ? 0 : 1);}
	static const ColumnType type;
};

template<class T> class AccessorEnum : public Accessor {
public:
	operator T() const {return (T)Get();}
	void operator=(T value) {Set((int)value);}
};

class AccessorString : public Accessor {
public:
	operator const char*() const {return GetString();}
	void operator=(const char* value) {SetString(value);}
	bool operator==(const char* value) {return (strcmp(GetString(), value) == 0);}
	static const ColumnType type;
};

class AccessorDate : public Accessor {
public:
	operator time_t() const {return GetDate();}
	void operator=(time_t value) {SetDate(value);}
	static const ColumnType type;
};

class AccessorMixed : public Accessor {
public:
	operator Mixed() const {return GetMixed();}
	void operator=(Mixed value) {SetMixed(value);}
	ColumnType GetType() const {return GetMixedType();}
	Mixed Get() const {return GetMixed();}
	int64_t GetInt() const {return GetMixed().GetInt();}
	bool GetBool() const {return GetMixed().GetBool();}
	time_t GetDate() const {return GetMixed().GetDate();}
	const char* GetString() const {return GetMixed().GetString();}
	BinaryData GetBinary() const {return GetMixed().GetBinary();}
	static const ColumnType type;
};

class ColumnProxy {
public:
	ColumnProxy() {}
	void Create(Table* table, size_t column) {
		m_table = table;
		m_column = column;
	}
protected:
	Table* m_table;
	size_t m_column;
};

class ColumnProxyInt : public ColumnProxy {
public:
	size_t Find(int64_t value) const {return m_table->Find(m_column, value);}
	size_t FindPos(int64_t value) const {return m_table->GetColumn(m_column).FindPos(value);}
// todo, fixme: array that m_data points at becomes invalid during function exit in debug mode in VC. Added this workaround, please verify 
// or fix properly
//	TableView FindAll(int value) {TableView *tv = new TableView(*m_table); m_table->FindAll(*tv, m_column, value); return *tv;}
	TableView FindAll(int value) {TableView tv(*m_table); m_table->FindAll(tv, m_column, value); return tv;}
	
	TableView FindAllHamming(uint64_t value, size_t max) {TableView tv(*m_table); m_table->FindAllHamming(tv, m_column, value, max); return tv;}
	int operator+=(int value) {m_table->GetColumn(m_column).Increment64(value); return 0;}
};

class ColumnProxyBool : public ColumnProxy {
public:
	size_t Find(bool value) const {return m_table->FindBool(m_column, value);}
};

class ColumnProxyDate : public ColumnProxy {
public:
	size_t Find(time_t value) const {return m_table->FindDate(m_column, value);}
};

template<class T> class ColumnProxyEnum : public ColumnProxy {
public:
	size_t Find(T value) const {return m_table->Find(m_column, (int64_t)value);}
};

class ColumnProxyString : public ColumnProxy {
public:
	size_t Find(const char* value) const {return m_table->FindString(m_column, value);}
	TableView FindAll(const char *value) {TableView tv(*m_table); m_table->FindAllString(tv, m_column, value); return tv;}
	//void Stats() const {m_table->GetColumnString(m_column).Stats();}

};

class ColumnProxyMixed : public ColumnProxy {
public:
};

template<class T> class tdbTypeEnum {
public:
	tdbTypeEnum(T v) : m_value(v) {};
	operator T() const {return m_value;}
	tdbTypeEnum<T>& operator=(const tdbTypeEnum<T>& v) {m_value = v.m_value;}
private:
	const T m_value;
};
#define tdbTypeInt int64_t
#define tdbTypeBool bool
#define tdbTypeString const char*
#define tdbTypeMixed Mixed
	
// Make all enum types return int type
template<typename T> struct COLUMN_TYPE_Enum {
public:
	COLUMN_TYPE_Enum() {};
	operator ColumnType() const {return COLUMN_TYPE_INT;}
};

class QueryItem {
public:
	QueryItem operator&&(const QueryItem&) {return QueryItem();}
	QueryItem operator||(const QueryItem&) {return QueryItem();}
};

class QueryAccessorBool {
public:
	QueryItem operator==(int) {return QueryItem();}
	QueryItem operator!=(int) {return QueryItem();}
};

class QueryAccessorInt {
public:
	QueryItem operator==(int) {return QueryItem();}
	QueryItem operator!=(int) {return QueryItem();}
	QueryItem operator<(int) {return QueryItem();}
	QueryItem operator>(int) {return QueryItem();}
	QueryItem operator<=(int) {return QueryItem();}
	QueryItem operator>=(int) {return QueryItem();}
	QueryItem Between(int, int) {return QueryItem();}
};

class QueryAccessorString {
public:
	QueryItem operator==(const char*) {return QueryItem();}
	QueryItem operator!=(const char*) {return QueryItem();}
	QueryItem Contains(const char*) {return QueryItem();}
	QueryItem StartsWith(const char*) {return QueryItem();}
	QueryItem EndsWith(const char*) {return QueryItem();}
	QueryItem MatchRegEx(const char*) {return QueryItem();}
};

template<class T> class QueryAccessorEnum {
public:
	QueryItem operator==(T) {return QueryItem();}
	QueryItem operator!=(T) {return QueryItem();}
	QueryItem operator<(T) {return QueryItem();}
	QueryItem operator>(T) {return QueryItem();}
	QueryItem operator<=(T) {return QueryItem();}
	QueryItem operator>=(T) {return QueryItem();}
	QueryItem between(T, T) {return QueryItem();}
};

class QueryAccessorMixed {
public:
};

}

#endif //__TDB_TABLE__
