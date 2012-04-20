#ifndef __TDB_COLUMN_BINARY__
#define __TDB_COLUMN_BINARY__

#include "Column.h"
#include "ColumnType.h" // BinaryData
#include "ArrayBinary.h"

namespace tightdb {

class ColumnBinary : public ColumnBase {
public:
	ColumnBinary(Allocator& alloc=GetDefaultAllocator());
	ColumnBinary(size_t ref, ArrayParent *parent=NULL, size_t pndx=0, Allocator& alloc=GetDefaultAllocator());
	ColumnBinary(size_t ref, const ArrayParent *parent, size_t pndx, Allocator& alloc=GetDefaultAllocator());
	~ColumnBinary();

	void Destroy();

	bool IsBinaryColumn() const {return true;}

	size_t Size() const;
	bool IsEmpty() const;

	BinaryData Get(size_t ndx) const;
	const void* GetData(size_t ndx) const;
	size_t GetLen(size_t ndx) const;

	bool Add() {Add(NULL, 0); return true;}
	void Add(const void* value, size_t len);
	void Set(size_t ndx, const void* value, size_t len);
	void Insert(size_t ndx, const void* value, size_t len);
	void Delete(size_t ndx);
	void Resize(size_t ndx);
	void Clear();

	// Index
	bool HasIndex() const {return false;}
	void BuildIndex(Index&) {}
	void ClearIndex() {}
	size_t FindWithIndex(int64_t) const {return (size_t)-1;}

	size_t GetRef() const {return m_array->GetRef();}
	void SetParent(ArrayParent *parent, size_t pndx) {m_array->SetParent(parent, pndx);}
	void UpdateParentNdx(int diff) {m_array->UpdateParentNdx(diff);}

#ifdef _DEBUG
	void Verify() const {};
#endif //_DEBUG

protected:
	friend class ColumnBase;

	bool Add(BinaryData bin);
	bool Set(size_t ndx, BinaryData bin);
	bool Insert(size_t ndx, BinaryData bin);

	void UpdateRef(size_t ref);

	BinaryData LeafGet(size_t ndx) const;
	bool LeafSet(size_t ndx, BinaryData value);
	bool LeafInsert(size_t ndx, BinaryData value);
	void LeafDelete(size_t ndx);
	
#ifdef _DEBUG
	virtual void LeafToDot(std::ostream& out, const Array& array) const;
#endif //_DEBUG
};

}

#endif //__TDB_COLUMN_BINARY__

