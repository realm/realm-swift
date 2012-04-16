#ifndef __TDB_ARRAY_BINARY__
#define __TDB_ARRAY_BINARY__

#include "ArrayBlob.h"

class ArrayBinary : public Array {
public:
	ArrayBinary(ArrayParent *parent=NULL, size_t pndx=0, Allocator& alloc=GetDefaultAllocator());
	ArrayBinary(size_t ref, const ArrayParent *parent, size_t pndx, Allocator& alloc=GetDefaultAllocator());
	//ArrayBinary(Allocator& alloc);
	~ArrayBinary();

	bool IsEmpty() const;
	size_t Size() const;

	const void* Get(size_t ndx) const;
	size_t GetLen(size_t ndx) const;

	void Add(const void* value, size_t len);
	void Set(size_t ndx, const void* value, size_t len);
	void Insert(size_t ndx, const void* value, size_t len);
	void Delete(size_t ndx);
	void Resize(size_t ndx);
	void Clear();
	
#ifdef _DEBUG
	void ToDot(std::ostream& out, const char* title=NULL) const;
#endif //_DEBUG

private:
	Array m_offsets;
	ArrayBlob m_blob;
};

#endif //__TDB_ARRAY_BINARY__
