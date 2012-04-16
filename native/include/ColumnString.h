#ifndef __TDB_COLUMN_STRING__
#define __TDB_COLUMN_STRING__

#include "Column.h"
#include "ArrayString.h"
#include "ArrayStringLong.h"

class AdaptiveStringColumn : public ColumnBase {
public:
	AdaptiveStringColumn(Allocator& alloc=GetDefaultAllocator());
	AdaptiveStringColumn(size_t ref, ArrayParent *parent=NULL, size_t pndx=0, Allocator& alloc=GetDefaultAllocator());
	AdaptiveStringColumn(size_t ref, const ArrayParent *parent, size_t pndx, Allocator& alloc=GetDefaultAllocator());
	~AdaptiveStringColumn();

	void Destroy();

	bool IsStringColumn() const {return true;}

	size_t Size() const;
	bool IsEmpty() const;

	const char* Get(size_t ndx) const;
	bool Add() {return Add("");}
	bool Add(const char* value);
	bool Set(size_t ndx, const char* value);
	bool Insert(size_t ndx, const char* value);
	void Delete(size_t ndx);
	void Clear();
	void Resize(size_t ndx);

	size_t Find(const char* value, size_t start=0 , size_t end=-1) const;
	void FindAll(Array &result, const char* value, size_t start = 0, size_t end = -1) const;

	// Index
	bool HasIndex() const {return false;}
	void BuildIndex(Index&) {}
	void ClearIndex() {}
	size_t FindWithIndex(int64_t) const {return (size_t)-1;}

	size_t GetRef() const {return m_array->GetRef();}
	void SetParent(ArrayParent *parent, size_t pndx) {m_array->SetParent(parent, pndx);}

	// Optimizing data layout
	bool AutoEnumerate(size_t& ref_keys, size_t& ref_values) const;

#ifdef _DEBUG
	bool Compare(const AdaptiveStringColumn& c) const;
	void Verify() const {};
	MemStats Stats() const;
#endif //_DEBUG

protected:
	friend class ColumnBase;
	void UpdateRef(size_t ref);

	const char* LeafGet(size_t ndx) const;
	bool LeafSet(size_t ndx, const char* value);
	bool LeafInsert(size_t ndx, const char* value);
	template<class F> size_t LeafFind(const char* value, size_t start, size_t end) const;
	void LeafFindAll(Array &result, const char* value, size_t add_offset = 0, size_t start = 0, size_t end = -1) const;

	void LeafDelete(size_t ndx);

	bool IsLongStrings() const {return m_array->HasRefs();} // HasRefs indicates long string array

	bool FindKeyPos(const char* target, size_t& pos) const;
	
#ifdef _DEBUG
	virtual void LeafToDot(std::ostream& out, const Array& array) const;
#endif //_DEBUG
};

#endif //__TDB_COLUMN_STRING__
