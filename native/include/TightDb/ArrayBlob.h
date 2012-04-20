#ifndef __TDB_ARRAY_BLOB__
#define __TDB_ARRAY_BLOB__

#include "Array.h"

namespace tightdb {

class ArrayBlob : public Array {
public:
	ArrayBlob(ArrayParent *parent=NULL, size_t pndx=0, Allocator& alloc=GetDefaultAllocator());
	ArrayBlob(size_t ref, const ArrayParent *parent, size_t pndx, Allocator& alloc=GetDefaultAllocator());
	ArrayBlob(Allocator& alloc);
	~ArrayBlob();

	const uint8_t* Get(size_t pos) const;

	void Add(void* data, size_t len);
	void Insert(size_t pos, void* data, size_t len);
	void Replace(size_t start, size_t end, void* data, size_t len);
	void Delete(size_t start, size_t end);
	void Resize(size_t len);
	void Clear();
	
#ifdef _DEBUG
	void ToDot(std::ostream& out, const char* title=NULL) const;
#endif //_DEBUG

private:
	virtual size_t CalcByteLen(size_t count, size_t width) const;
	virtual size_t CalcItemCount(size_t bytes, size_t width) const;
	virtual WidthType GetWidthType() const {return TDB_IGNORE;}
};

}

#endif //__TDB_ARRAY_BLOB__
