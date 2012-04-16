#ifndef __TDB_ARRAY_STRING_LONG__
#define __TDB_ARRAY_STRING_LONG__

#include "ArrayBlob.h"

class ArrayStringLong : public Array {
public:
	ArrayStringLong(ArrayParent *parent=NULL, size_t pndx=0, Allocator& alloc=GetDefaultAllocator());
	ArrayStringLong(size_t ref, const ArrayParent *parent, size_t pndx, Allocator& alloc=GetDefaultAllocator());
	//ArrayStringLong(Allocator& alloc);
	~ArrayStringLong();

	bool IsEmpty() const;
	size_t Size() const;

	const char* Get(size_t ndx) const;
	void Add(const char* value);
	void Add(const char* value, size_t len);
	void Set(size_t ndx, const char* value);
	void Set(size_t ndx, const char* value, size_t len);
	void Insert(size_t ndx, const char* value);
	void Insert(size_t ndx, const char* value, size_t len);
	void Delete(size_t ndx);
	void Resize(size_t ndx);
	void Clear();

	size_t Find(const char* value, size_t start=0 , size_t end=-1) const;
	void FindAll(Array &result, const char* value, size_t add_offset = 0, size_t start = 0, size_t end = -1) const;
	
#ifdef _DEBUG
	void ToDot(std::ostream& out, const char* title=NULL) const;
#endif //_DEBUG

private:
	size_t FindWithLen(const char* value, size_t len, size_t start , size_t end) const;

	// Member variables
	Array m_offsets;
	ArrayBlob m_blob;
};

#endif //__TDB_ARRAY_STRING_LONG__
