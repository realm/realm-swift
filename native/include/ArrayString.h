#ifndef __TDB_ARRAY_STRING__
#define __TDB_ARRAY_STRING__

#include "Array.h"

class ArrayString : public Array {
public:
	ArrayString(ArrayParent *parent=NULL, size_t pndx=0, Allocator& alloc=GetDefaultAllocator());
	ArrayString(size_t ref, const ArrayParent *parent, size_t pndx, Allocator& alloc=GetDefaultAllocator());
	ArrayString(Allocator& alloc);
	~ArrayString();

	const char* Get(size_t ndx) const;
	bool Add();
	bool Add(const char* value);
	bool Set(size_t ndx, const char* value);
	bool Set(size_t ndx, const char* value, size_t len);
	bool Insert(size_t ndx, const char* value);
	bool Insert(size_t ndx, const char* value, size_t len);
	void Delete(size_t ndx);

	size_t Find(const char* value, size_t start=0 , size_t end=-1) const;
	void FindAll(Array& result, const char* value, size_t add_offset = 0, size_t start = 0, size_t end = -1);

#ifdef _DEBUG
	bool Compare(const ArrayString& c) const;
	void StringStats() const;
	//void ToDot(FILE* f) const;
	void ToDot(std::ostream& out, const char* title=NULL) const;
#endif //_DEBUG

private:
	size_t FindWithLen(const char* value, size_t len, size_t start , size_t end) const;
	virtual size_t CalcByteLen(size_t count, size_t width) const;
	virtual size_t CalcItemCount(size_t bytes, size_t width) const;
	virtual WidthType GetWidthType() const {return TDB_MULTIPLY;}
};

#endif //__TDB_ARRAY__
