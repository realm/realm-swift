#ifndef __TDB_ARRAY__
#define __TDB_ARRAY__

#ifdef _MSC_VER
#include "win32/stdint.h"
#else
#include <stdint.h> // unint8_t etc
#endif
//#include <climits> // size_t
#include <cstdlib> // size_t
#include <cstring> // memmove
#include "alloc.h"
#include <iostream>
#include "utilities.h"
#include <vector>
#include <assert.h>

#define TEMPEX(fun, arg) \
	if(m_width == 0) {fun<0> arg;} \
	else if (m_width == 1) {fun<1> arg;} \
	else if (m_width == 2) {fun<2> arg;} \
	else if (m_width == 4) {fun<4> arg;} \
	else if (m_width == 8) {fun<8> arg;} \
	else if (m_width == 16) {fun<16> arg;} \
	else if (m_width == 32) {fun<32> arg;} \
	else if (m_width == 64) {fun<64> arg;}

#ifdef USE_SSE42
/*
    MMX: mmintrin.h
    SSE: xmmintrin.h
    SSE2: emmintrin.h
    SSE3: pmmintrin.h
    SSSE3: tmmintrin.h
    SSE4A: ammintrin.h
    SSE4.1: smmintrin.h
    SSE4.2: nmmintrin.h
*/
	#include <nmmintrin.h> // __SSE42__
#elif defined (USE_SSE3)
	#include <pmmintrin.h> // __SSE3__
#endif

#ifdef _DEBUG
#include <stdio.h>
#endif

// Pre-definitions
class Array;

#ifdef _DEBUG
class MemStats {
public:
	MemStats() : allocated(0), used(0), array_count(0) {}
	MemStats(size_t allocated, size_t used, size_t array_count)
	: allocated(allocated), used(used), array_count(array_count) {}
	MemStats(const MemStats& m) {
		allocated = m.allocated;
		used = m.used;
		array_count = m.array_count;
	}
	void Add(const MemStats& m) {
		allocated += m.allocated;
		used += m.used;
		array_count += m.array_count;
	}
	size_t allocated;
	size_t used;
	size_t array_count;
};
#endif

enum ColumnDef {
	COLUMN_NORMAL,
	COLUMN_NODE,
	COLUMN_HASREFS
};


class ArrayParent
{
public:
	virtual ~ArrayParent() {}

protected:
	friend class Array;
public: // FIXME: Must be protected. Solve problem by having the Array constructor, that creates a new array, call it.
	virtual void update_child_ref(size_t subtable_ndx, size_t new_ref) = 0;
protected:
#ifdef _DEBUG
	virtual size_t get_child_ref_for_verify(size_t subtable_ndx) const = 0;
#endif
};


class Array: public ArrayParent {
public:
	Array(size_t ref, ArrayParent *parent=NULL, size_t pndx=0, Allocator& alloc=GetDefaultAllocator());
	Array(size_t ref, const ArrayParent *parent, size_t pndx, Allocator& alloc=GetDefaultAllocator());
	Array(ColumnDef type=COLUMN_NORMAL, ArrayParent *parent=NULL, size_t pndx=0, Allocator& alloc=GetDefaultAllocator());
	Array(Allocator& alloc);
	Array(const Array& a);
	virtual ~Array();

	bool operator==(const Array& a) const;

	void SetType(ColumnDef type);
	bool HasParent() const {return m_parent != NULL;}
	void SetParent(ArrayParent *parent, size_t pndx);
	void UpdateParentNdx(int diff) {m_parentNdx += diff;}
	ArrayParent *GetParent() const {return m_parent;}
	size_t GetParentNdx() const {return m_parentNdx;}
	void UpdateRef(size_t ref);

	bool IsValid() const {return m_data != NULL;}
	void Invalidate() const {m_data = NULL;}

	virtual size_t Size() const {return m_len;}
	bool IsEmpty() const {return m_len == 0;}

	bool Insert(size_t ndx, int64_t value);
	bool Add(int64_t value);
	bool Set(size_t ndx, int64_t value);
	template <size_t w> void Set(size_t ndx, int64_t value);
	int64_t Get(size_t ndx) const;
	size_t GetAsRef(size_t ndx) const;
	template <size_t w>int64_t Get(size_t ndx) const;
	int64_t operator[](size_t ndx) const {return Get(ndx);}
	int64_t Back() const;
	void Delete(size_t ndx);
	void Clear();
	
	// Direct access methods
	int64_t ColumnGet(size_t ndx) const;

	bool Increment(int64_t value, size_t start=0, size_t end=(size_t)-1);
	bool IncrementIf(int64_t limit, int64_t value);
	void Adjust(size_t start, int64_t diff);

	size_t FindPos(int64_t value) const;
	size_t FindPos2(int64_t value) const;
	size_t Find(int64_t value, size_t start=0, size_t end=(size_t)-1) const;

	template <class F> size_t Find(F function_, int64_t value, size_t start, size_t end) const {
		const F function = {};
		if(end == (size_t)-1)
			end = m_len;
		for(size_t s = start; s < end; s++) {
			if(function(value, Get(s)))
				return s;
		}
		return (size_t)-1;
	}
	void Preset(int64_t min, int64_t max, size_t count);
	void Preset(size_t bitwidth, size_t count); 
	void FindAll(Array& result, int64_t value, size_t offset=0, size_t start=0, size_t end=(size_t)-1) const;
	void FindAllHamming(Array& result, uint64_t value, size_t maxdist, size_t offset=0) const;
	int64_t Sum(size_t start = 0, size_t end = (size_t)-1) const;
	bool Max(int64_t& result, size_t start = 0, size_t end = (size_t)-1) const;
	bool Min(int64_t& result, size_t start = 0, size_t end = (size_t)-1) const;
	template <class F> size_t Query(int64_t value, size_t start, size_t end);

	void Sort(void);
	void ReferenceSort(Array &ref);
	void Resize(size_t count);

	bool IsNode() const {return m_isNode;}
	bool HasRefs() const {return m_hasRefs;}
	Array GetSubArray(size_t ndx);
	const Array GetSubArray(size_t ndx) const;
	size_t GetRef() const {return m_ref;};
	void Destroy();

	Allocator& GetAllocator() const {return m_alloc;}

	// Serialization
	template<class S> size_t Write(S& target, size_t& pos, bool recurse=true) const;
	std::vector<int64_t> ToVector(void);
	// Debug
	size_t GetBitWidth() const {return m_width;}
#ifdef _DEBUG
	bool Compare(const Array& c) const;
	void Print() const;
	void Verify() const;
	void ToDot(std::ostream& out, const char* title=NULL) const;
	MemStats Stats() const;
#endif //_DEBUG
	mutable unsigned char* m_data;

private:
	template <size_t w>bool MinMax(size_t from, size_t to, uint64_t maxdiff, int64_t *min, int64_t *max);
	Array& operator=(const Array&) {return *this;} // not allowed
	void SetBounds(size_t width);
	template <size_t w>void QuickSort(size_t lo, size_t hi);
	void QuickSort(size_t lo, size_t hi);
	void ReferenceQuickSort(Array &ref);
	template <size_t w>void ReferenceQuickSort(size_t lo, size_t hi, Array &ref);
#if defined(USE_SSE42) || defined(USE_SSE3)
	size_t FindSSE(int64_t value, __m128i *data, size_t bytewidth, size_t items) const;
#endif //USE_SSE
	template <bool eq>size_t CompareEquality(int64_t value, size_t start, size_t end) const;
	template <bool gt>size_t CompareRelation(int64_t value, size_t start, size_t end) const;
	template <size_t w> void Sort();
	template <size_t w>void ReferenceSort(Array &ref);
	void update_ref_in_parent(size_t ref);

protected:
	bool AddPositiveLocal(int64_t value);

	void Create(size_t ref);

	// Getters and Setters for adaptive-packed arrays
	typedef int64_t(Array::*Getter)(size_t) const;
	typedef void(Array::*Setter)(size_t, int64_t);
	int64_t Get_0b(size_t ndx) const;
	int64_t Get_1b(size_t ndx) const;
	int64_t Get_2b(size_t ndx) const;
	int64_t Get_4b(size_t ndx) const;
	int64_t Get_8b(size_t ndx) const;
	int64_t Get_16b(size_t ndx) const;
	int64_t Get_32b(size_t ndx) const;
	int64_t Get_64b(size_t ndx) const;
	void Set_0b(size_t ndx, int64_t value);
	void Set_1b(size_t ndx, int64_t value);
	void Set_2b(size_t ndx, int64_t value);
	void Set_4b(size_t ndx, int64_t value);
	void Set_8b(size_t ndx, int64_t value);
	void Set_16b(size_t ndx, int64_t value);
	void Set_32b(size_t ndx, int64_t value);
	void Set_64b(size_t ndx, int64_t value);

	enum WidthType {
		TDB_BITS     = 0,
		TDB_MULTIPLY = 1,
		TDB_IGNORE   = 2
	};

	virtual size_t CalcByteLen(size_t count, size_t width) const;
	virtual size_t CalcItemCount(size_t bytes, size_t width) const;
	virtual WidthType GetWidthType() const {return TDB_BITS;}

	void set_header_isnode(bool value, void* header=NULL);
	void set_header_hasrefs(bool value, void* header=NULL);
	void set_header_wtype(WidthType value, void* header=NULL);
	void set_header_width(size_t value, void* header=NULL);
	void set_header_len(size_t value, void* header=NULL);
	void set_header_capacity(size_t value, void* header=NULL);
	bool get_header_isnode(const void* header=NULL) const;
	bool get_header_hasrefs(const void* header=NULL) const;
	WidthType get_header_wtype(const void* header=NULL) const;
	size_t get_header_width(const void* header=NULL) const;
	size_t get_header_len(const void* header=NULL) const;
	size_t get_header_capacity(const void* header=NULL) const;

	void SetWidth(size_t width);
	bool Alloc(size_t count, size_t width);
	bool CopyOnWrite();

	// Member variables
	Getter m_getter;
	Setter m_setter;

private:
	size_t m_ref;

protected:
	size_t m_len;
	size_t m_capacity;
	size_t m_width;
	bool m_isNode;
	bool m_hasRefs;

private:
	ArrayParent *m_parent;
	size_t m_parentNdx;

	Allocator& m_alloc;

protected:
	int64_t m_lbound;
	int64_t m_ubound;

	// Overriding methods in ArrayParent
	virtual void update_child_ref(size_t subtable_ndx, size_t new_ref);
#ifdef _DEBUG
	virtual size_t get_child_ref_for_verify(size_t subtable_ndx) const;
#endif
};



// Templates

template<class S>
size_t Array::Write(S& out, size_t& pos, bool recurse) const {
	// parse header
	size_t len          = get_header_len();
	const WidthType wt  = get_header_wtype();
	
	// Adjust length to number of bytes
	if (wt == TDB_BITS) {
		const size_t bits = (len * m_width);
		len = bits / 8;
		if (bits & 0x7) ++len; // include partial bytes
	}
	else if (wt == TDB_MULTIPLY) {
		len *= m_width;
	}
	
	if (recurse && m_hasRefs) {
		// Temp array for updated refs
		Array newRefs(m_isNode ? COLUMN_NODE : COLUMN_HASREFS);
		
		// First write out all sub-arrays
		for (size_t i = 0; i < Size(); ++i) {
			const size_t ref = GetAsRef(i);
			if (ref == 0 || ref & 0x1) {
				// zero-refs and refs that are not 64-aligned do not point to sub-trees
				newRefs.Add(ref);
			}
			else {
				const Array sub(ref, (const Array*)NULL, 0, GetAllocator());
				const size_t sub_pos = sub.Write(out, pos);
				newRefs.Add(sub_pos);
			}
		}
		
		// Write out the replacement array
		// (but don't write sub-tree as it has alredy been written)
		const size_t refs_pos = newRefs.Write(out, pos, false);
		
		// Clean-up
		newRefs.SetType(COLUMN_NORMAL); // avoid recursive del
		newRefs.Destroy();
		
		return refs_pos; // Return position
	}
	else {
		const size_t array_pos = pos;
		
		// TODO: replace capacity with checksum
		
		// Calculate complete size
		len += 8; // include header in total
		const size_t rest = (~len & 0x7)+1; // CHECK
		if (rest < 8) len += rest; // Add padding for 64bit alignment
		
		// Write array
		out.write((const char*)m_data-8, len);
		pos += len;
		
		return array_pos; // Return position of this array
	}
}


inline void Array::update_ref_in_parent(size_t ref)
{
  if (!m_parent) return;
  m_parent->update_child_ref(m_parentNdx, ref);
}


inline void Array::update_child_ref(size_t subtable_ndx, size_t new_ref)
{
	Set(subtable_ndx, new_ref);
}

#ifdef _DEBUG
inline size_t Array::get_child_ref_for_verify(size_t subtable_ndx) const
{
	return GetAsRef(subtable_ndx);
}
#endif // _DEBUG

#endif //__TDB_ARRAY__
