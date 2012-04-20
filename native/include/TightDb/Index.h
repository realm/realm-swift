#ifndef __TDB_INDEX__
#define __TDB_INDEX__

#include "Column.h"

namespace tightdb {

class Index : public Column {
public:
	Index();
	Index(ColumnDef type, Array* parent=NULL, size_t pndx=0);
	Index(size_t ref);
	Index(size_t ref, Array* parent, size_t pndx);

	bool IsEmpty() const;

	void BuildIndex(const Column& c);

	bool Insert(size_t ndx, int64_t value, bool isLast=false);
	void Delete(size_t ndx, int64_t value, bool isLast=false);
	void Set(size_t ndx, int64_t oldValue, int64_t newValue);

	size_t Find(int64_t value) const;
	bool FindAll(Column& result, int64_t value) const;
	bool FindAllRange(Column& result, int64_t start, int64_t end) const;

#ifdef _DEBUG
	void Verify() const;
#endif //_DEBUG

protected:
	// B-Tree functions
	NodeChange DoInsert(size_t ndx, int64_t value);
	bool DoDelete(size_t ndx, int64_t value);

	// Node functions
	bool NodeAdd(size_t ref);

	void UpdateRefs(size_t pos, int diff);

	bool LeafInsert(size_t ref, int64_t value);

	int64_t MaxValue() const;
	size_t MaxRef() const;
};

}

#endif //__TDB_INDEX__
