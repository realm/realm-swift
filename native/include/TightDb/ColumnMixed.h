#ifndef __TDB_COLUMN_MIXED__
#define __TDB_COLUMN_MIXED__

#include "Column.h"
#include "ColumnType.h"
#include "ColumnTable.h"
#include "Table.h"
#include "Index.h"

namespace tightdb {

// Pre-declarations
class ColumnBinary;

class ColumnMixed : public ColumnBase {
public:
	/**
	 * Create a freestanding mixed column.
	 */
	ColumnMixed();

	/**
	 * Create a mixed column and have it instantiate a new array
	 * structure.
	 *
	 * \param tab If this column is used as part of a table you must
	 * pass a pointer to that table. Otherwise you may pass null.
	 */
	ColumnMixed(Allocator &alloc, Table const *tab);

	/**
	 * Create a mixed column and attach it to an already existing
	 * array structure.
	 *
	 * \param tab If this column is used as part of a table you must
	 * pass a pointer to that table. Otherwise you may pass null.
	 */
	ColumnMixed(size_t ref, ArrayParent *parent, size_t pndx, Allocator &alloc, Table const *tab);

	~ColumnMixed();
	void Destroy();

	void SetParent(ArrayParent *parent, size_t pndx);

	ColumnType GetType(size_t ndx) const;
	size_t Size() const {return m_types->Size();}
	bool IsEmpty() const {return m_types->IsEmpty();}

	int64_t GetInt(size_t ndx) const;
	bool GetBool(size_t ndx) const;
	time_t GetDate(size_t ndx) const;
	const char* GetString(size_t ndx) const;
	BinaryData GetBinary(size_t ndx) const;

	/**
	 * The returned table pointer must always end up being wrapped in
	 * an instance of BasicTableRef.
	 */
	TopLevelTable *get_subtable_ptr(size_t ndx) const;

	void SetInt(size_t ndx, int64_t value);
	void SetBool(size_t ndx, bool value);
	void SetDate(size_t ndx, time_t value);
	void SetString(size_t ndx, const char* value);
	void SetBinary(size_t ndx, const char* value, size_t len);
	void SetTable(size_t ndx);
	
	void InsertInt(size_t ndx, int64_t value);
	void InsertBool(size_t ndx, bool value);
	void InsertDate(size_t ndx, time_t value);
	void InsertString(size_t ndx, const char* value);
	void InsertBinary(size_t ndx, const char* value, size_t len);
	void InsertTable(size_t ndx);
	
	bool Add();
	void Clear();
	void Delete(size_t ndx);
	
	// Indexing
	bool HasIndex() const {return false;}
	void BuildIndex(Index& index) {(void)index;}
	void ClearIndex() {}
	
	size_t GetRef() const {return m_array->GetRef();}

#ifdef _DEBUG
	void Verify() const;
	void ToDot(std::ostream& out, const char* title) const;
#endif //_DEBUG
	
private:
	void Create(Allocator &alloc, Table const *tab);
	void Create(size_t ref, ArrayParent *parent, size_t pndx, Allocator &alloc, Table const *tab);
	void InitDataColumn();
	
	void ClearValue(size_t ndx, ColumnType newtype);

	class RefsColumn;
	
	// Member variables
	Column*       m_types;
	RefsColumn*   m_refs;
	ColumnBinary* m_data;
};


class ColumnMixed::RefsColumn: public ColumnSubtableParent
{
public:
	RefsColumn(Allocator &alloc, Table const *tab):
		ColumnSubtableParent(NULL, 0, alloc, tab) {}
	RefsColumn(size_t ref, ArrayParent *parent, size_t pndx, Allocator &alloc, Table const *tab):
		ColumnSubtableParent(ref, parent, pndx, alloc, tab) {}
	void insert_table(size_t ndx);
	void set_table(size_t ndx);
	TopLevelTable *get_subtable_ptr(size_t ndx);
#ifdef _DEBUG
	void verify(size_t ndx) const;
	void to_dot(size_t ndx, std::ostream &) const;
#endif //_DEBUG
};


inline ColumnMixed::ColumnMixed(): m_data(NULL)
{
	Create(GetDefaultAllocator(), 0);
}

inline ColumnMixed::ColumnMixed(Allocator &alloc, Table const *tab): m_data(NULL)
{
	Create(alloc, tab);
}

inline ColumnMixed::ColumnMixed(size_t ref, ArrayParent *parent, size_t pndx,
								Allocator &alloc, Table const *tab): m_data(NULL)
{
	Create(ref, parent, pndx, alloc, tab);
}

inline void ColumnMixed::InsertTable(size_t ndx)
{
	assert(ndx <= m_types->Size());
	m_types->Insert(ndx, COLUMN_TYPE_TABLE);
	m_refs->insert_table(ndx);
}

inline void ColumnMixed::SetTable(size_t ndx)
{
	assert(ndx < m_types->Size());
	ClearValue(ndx, COLUMN_TYPE_TABLE); // Remove refs or binary data
	m_refs->set_table(ndx);
}

inline TopLevelTable *ColumnMixed::get_subtable_ptr(size_t ndx) const
{
	assert(ndx < m_types->Size());
	assert(m_types->Get(ndx) == COLUMN_TYPE_TABLE);
	return m_refs->get_subtable_ptr(ndx);
}

}

#endif //__TDB_COLUMN_MIXED__
