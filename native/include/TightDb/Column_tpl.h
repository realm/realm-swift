#ifndef __TDB_COLUMN_TEMPLATES__
#define __TDB_COLUMN_TEMPLATES__

#include <assert.h>

#include "Array.h"
#include "Column.h"

#include <cstdlib>
#include "query/conditions.h"

// Has to be define to allow overload from build settings
#ifndef MAX_LIST_SIZE
#define MAX_LIST_SIZE 1000
#endif

namespace tightdb {

template<class T> T GetColumnFromRef(Array &parent, size_t ndx) {
	//assert(parent.HasRefs());
	//assert(ndx < parent.Size());
	return T((size_t)parent.Get(ndx), &parent, ndx, parent.GetAllocator());
}

template<class T> const T GetColumnFromRef(const Array &parent, size_t ndx) {
	//assert(parent.HasRefs());
	//assert(ndx < parent.Size());
	return T((size_t)parent.Get(ndx), &parent, ndx, parent.GetAllocator());
}

template<typename T, class C> T ColumnBase::TreeGet(size_t ndx) const {
	if (IsNode()) {
		// Get subnode table
		const Array offsets = NodeGetOffsets();
		const Array refs = NodeGetRefs();

		// Find the subnode containing the item
		const size_t node_ndx = offsets.FindPos(ndx);

		// Calc index in subnode
		const size_t offset = node_ndx ? (size_t)offsets.Get(node_ndx-1) : 0;
		const size_t local_ndx = ndx - offset;

		// Get item
		const C target = GetColumnFromRef<C>(refs, node_ndx);
		return target.TreeGet<T,C>(local_ndx);
	}
	else {
		return static_cast<const C*>(this)->LeafGet(ndx);
	}
}

template<typename T, class C> bool ColumnBase::TreeSet(size_t ndx, T value) {
	//const T oldVal = m_index ? Get(ndx) : 0; // cache oldval for index

	if (IsNode()) {
		// Get subnode table
		const Array offsets = NodeGetOffsets();
		Array refs = NodeGetRefs();

		// Find the subnode containing the item
		const size_t node_ndx = offsets.FindPos(ndx);

		// Calc index in subnode
		const size_t offset = node_ndx ? (size_t)offsets.Get(node_ndx-1) : 0;
		const size_t local_ndx = ndx - offset;

		// Set item
		C target = GetColumnFromRef<C>(refs, node_ndx);
		if (!target.Set(local_ndx, value)) return false;
	}
	else if (!static_cast<C*>(this)->LeafSet(ndx, value)) return false;

	// Update index
	//if (m_index) m_index->Set(ndx, oldVal, value);

	return true;
}

template<typename T, class C> bool ColumnBase::TreeInsert(size_t ndx, T value) {
	const NodeChange nc = DoInsert<T,C>(ndx, value);

	switch (nc.type) {
	case NodeChange::CT_ERROR:
		return false; // allocation error
	case NodeChange::CT_NONE:
		break;
	case NodeChange::CT_INSERT_BEFORE:
	{
		Column newNode(COLUMN_NODE, m_array->GetAllocator());
		newNode.NodeAdd<C>(nc.ref1);
		newNode.NodeAdd<C>(GetRef());
		static_cast<C*>(this)->UpdateRef(newNode.GetRef());
		break;
	}
	case NodeChange::CT_INSERT_AFTER:
	{
		Column newNode(COLUMN_NODE, m_array->GetAllocator());
		newNode.NodeAdd<C>(GetRef());
		newNode.NodeAdd<C>(nc.ref1);
		static_cast<C*>(this)->UpdateRef(newNode.GetRef());
		break;
	}
	case NodeChange::CT_SPLIT:
	{
		Column newNode(COLUMN_NODE, m_array->GetAllocator());
		newNode.NodeAdd<C>(nc.ref1);
		newNode.NodeAdd<C>(nc.ref2);
		static_cast<C*>(this)->UpdateRef(newNode.GetRef());
		break;
	}
	default:
		assert(false);
		return false;
	}

	return true;
}

template<typename T, class C> Column::NodeChange ColumnBase::DoInsert(size_t ndx, T value) {
	if (IsNode()) {
		// Get subnode table
		Array offsets = NodeGetOffsets();
		Array refs = NodeGetRefs();

		// Find the subnode containing the item
		size_t node_ndx = offsets.FindPos(ndx);
		if (node_ndx == (size_t)-1) {
			// node can never be empty, so try to fit in last item
			node_ndx = offsets.Size()-1;
		}

		// Calc index in subnode
		const size_t offset = node_ndx ? (size_t)offsets.Get(node_ndx-1) : 0;
		const size_t local_ndx = ndx - offset;

		// Get sublist
		C target = GetColumnFromRef<C>(refs, node_ndx);

		// Insert item
		const NodeChange nc = target.DoInsert<T, C>(local_ndx, value);
		if (nc.type ==  NodeChange::CT_ERROR) return NodeChange(NodeChange::CT_ERROR); // allocation error
		else if (nc.type ==  NodeChange::CT_NONE) {
			offsets.Increment(1, node_ndx);  // update offsets
			return NodeChange(NodeChange::CT_NONE); // no new nodes
		}

		if (nc.type == NodeChange::CT_INSERT_AFTER) ++node_ndx;

		// If there is room, just update node directly
		if (offsets.Size() < MAX_LIST_SIZE) {
			if (nc.type == NodeChange::CT_SPLIT) return NodeInsertSplit<C>(node_ndx, nc.ref2);
			else return NodeInsert<C>(node_ndx, nc.ref1); // ::INSERT_BEFORE/AFTER
		}

		// Else create new node
		Column newNode(COLUMN_NODE, m_array->GetAllocator());
		if (nc.type == NodeChange::CT_SPLIT) {
			// update offset for left node
			const size_t newsize = target.Size();
			const size_t preoffset = node_ndx ? offsets.GetAsRef(node_ndx-1) : 0;
			offsets.Set(node_ndx, preoffset + newsize);

			newNode.NodeAdd<C>(nc.ref2);
			++node_ndx;
		}
		else newNode.NodeAdd<C>(nc.ref1);

		switch (node_ndx) {
		case 0:	            // insert before
			return NodeChange(NodeChange::CT_INSERT_BEFORE, newNode.GetRef());
		case MAX_LIST_SIZE:	// insert after
			if (nc.type == NodeChange::CT_SPLIT)
				return NodeChange(NodeChange::CT_SPLIT, GetRef(), newNode.GetRef());
			else return NodeChange(NodeChange::CT_INSERT_AFTER, newNode.GetRef());
		default:            // split
			// Move items after split to new node
			const size_t len = refs.Size();
			for (size_t i = node_ndx; i < len; ++i) {
				const size_t ref = refs.GetAsRef(i);
				newNode.NodeAdd<C>(ref);
			}
			offsets.Resize(node_ndx);
			refs.Resize(node_ndx);
			return NodeChange(NodeChange::CT_SPLIT, GetRef(), newNode.GetRef());
		}
	}
	else {
		// Is there room in the list?
		const size_t count = static_cast<C*>(this)->Size();
		if (count < MAX_LIST_SIZE) {
			return static_cast<C*>(this)->LeafInsert(ndx, value);
		}

		// Create new list for item
		C newList(m_array->GetAllocator());
		if (m_array->HasRefs()) newList.SetHasRefs(); // all leafs should have same type
		
		if (!newList.Add(value)) return NodeChange(NodeChange::CT_ERROR);

		switch (ndx) {
		case 0:	            // insert before
			return NodeChange(NodeChange::CT_INSERT_BEFORE, newList.GetRef());
		case MAX_LIST_SIZE:	// insert below
			return NodeChange(NodeChange::CT_INSERT_AFTER, newList.GetRef());
		default:            // split
			// Move items after split to new list
			for (size_t i = ndx; i < count; ++i) {
				newList.Add(static_cast<C*>(this)->LeafGet(i));
			}
			static_cast<C*>(this)->Resize(ndx);

			return NodeChange(NodeChange::CT_SPLIT, GetRef(), newList.GetRef());
		}
	}
}

template<class C> bool ColumnBase::NodeInsertSplit(size_t ndx, size_t new_ref) {
	assert(IsNode());
	assert(new_ref);

	Array offsets = NodeGetOffsets();
	Array refs = NodeGetRefs();

	assert(ndx < offsets.Size());
	assert(offsets.Size() < MAX_LIST_SIZE);

	// Get sublists
	const C orig_col = GetColumnFromRef<C>(refs, ndx);
	const C new_col(new_ref, (const Array*)NULL, 0, m_array->GetAllocator());

	// Update original size
	const size_t offset = ndx ? offsets.GetAsRef(ndx-1) : 0;
	const size_t newSize = orig_col.Size();
	const size_t newOffset = offset + newSize;
#ifdef _DEBUG
	const size_t oldSize = offsets.GetAsRef(ndx) - offset;
#endif
	offsets.Set(ndx, newOffset);

	// Insert new ref
	const size_t refSize = new_col.Size();
	offsets.Insert(ndx+1, newOffset + refSize);
	refs.Insert(ndx+1, new_ref);

#ifdef _DEBUG
	assert((newSize + refSize) - oldSize == 1); // insert should only add one item
#endif

	// Update following offsets
	if (offsets.Size() > ndx+2)
		offsets.Increment(1, ndx+2);

	return true;
}

template<class C> bool ColumnBase::NodeInsert(size_t ndx, size_t ref) {
	assert(ref);
	assert(IsNode());

	Array offsets = NodeGetOffsets();
	Array refs = NodeGetRefs();

	assert(ndx <= offsets.Size());
	assert(offsets.Size() < MAX_LIST_SIZE);

	const C col(ref, (Array*)NULL, 0, m_array->GetAllocator());
	const size_t refSize = col.Size();
	const int64_t newOffset = (ndx ? offsets.Get(ndx-1) : 0) + refSize;

	if (!offsets.Insert(ndx, newOffset)) return false;
	if (ndx+1 < offsets.Size()) {
		if (!offsets.Increment(refSize, ndx+1)) return false;
	}
	return refs.Insert(ndx, ref);
}

template<class C> bool ColumnBase::NodeAdd(size_t ref) {
	assert(ref);
	assert(IsNode());

	Array offsets = NodeGetOffsets();
	Array refs = NodeGetRefs();
	const C col(ref, (Array*)NULL, 0, m_array->GetAllocator());

	assert(offsets.Size() < MAX_LIST_SIZE);

	const int64_t newOffset = (offsets.IsEmpty() ? 0 : offsets.Back()) + col.Size();
	if (!offsets.Add(newOffset)) return false;
	return refs.Add(ref);
}

template<typename T, class C> void ColumnBase::TreeDelete(size_t ndx) {
	if (!IsNode()) {
		static_cast<C*>(this)->LeafDelete(ndx);
	}
	else {
		// Get subnode table
		Array offsets = NodeGetOffsets();
		Array refs = NodeGetRefs();

		// Find the subnode containing the item
		const size_t node_ndx = offsets.FindPos(ndx);
		assert(node_ndx != (size_t)-1);

		// Calc index in subnode
		const size_t offset = node_ndx ? (size_t)offsets.Get(node_ndx-1) : 0;
		const size_t local_ndx = ndx - offset;

		// Get sublist
		C target = GetColumnFromRef<C>(refs, node_ndx);
		target.TreeDelete<T,C>(local_ndx);

		// Remove ref in node
		if (target.IsEmpty()) {
			offsets.Delete(node_ndx);
			refs.Delete(node_ndx);
			target.Destroy();
		}

		if (offsets.IsEmpty()) {
			// All items deleted, we can revert to being array
			static_cast<C*>(this)->Clear();
		}
		else {
			// Update lower offsets
			if (node_ndx < offsets.Size()) offsets.Increment(-1, node_ndx);
		}
	}
}

template<typename T, class C, class F> size_t ColumnBase::TreeFind(T value, size_t start, size_t end) const {
	// Use index if possible
	/*if (m_index && start == 0 && end == -1) {
	 return FindWithIndex(value);
	 }*/
//	F function;
	if (!IsNode()) {
		const C* c = static_cast<const C*>(this);
		return c->template LeafFind<F>(value, start, end);
	}
	else {
		// Get subnode table
		const Array offsets = NodeGetOffsets();
		const Array refs = NodeGetRefs();
		const size_t count = refs.Size();

		if (start == 0 && end == (size_t)-1) {
			for (size_t i = 0; i < count; ++i) {
				const C col((size_t)refs.Get(i), (const Array*)NULL, 0, m_array->GetAllocator());
				const size_t ndx = col.TreeFind<T, C, F>(value, 0, (size_t)-1);
				if (ndx != (size_t)-1) {
					const size_t offset = i ? (size_t)offsets.Get(i-1) : 0;
					return offset + ndx;
				}
			}
		}
		else {
			// partial search
			size_t i = offsets.FindPos(start);
			size_t offset = i ? (size_t)offsets.Get(i-1) : 0;
			size_t s = start - offset;
			size_t e = (end == (size_t)-1 || (int)end >= offsets.Get(i)) ? -1 : end - offset;

			for (;;) {
				const C col((size_t)refs.Get(i), (const Array*)NULL, 0, m_array->GetAllocator());

				const size_t ndx = col.TreeFind<T, C, F>(value, s, e);
				if (ndx != (size_t)-1) {
					const size_t offset = i ? (size_t)offsets.Get(i-1) : 0;
					return offset + ndx;
				}

				++i;
				if (i >= count) break;

				s = 0;
				if (end != (size_t)-1) {
					if (end >= (size_t)offsets.Get(i))
						e = (size_t)-1;
					else {
						offset = (size_t)offsets.Get(i-1);
						if(offset >= end)
							break;
						e = end - offset;
					}
				}
			}
		}

		return (size_t)-1; // not found
	}
}



template<typename T, class C> void ColumnBase::TreeFindAll(Array &result, T value, size_t add_offset, size_t start, size_t end) const {
	if (!IsNode()) {
		return static_cast<const C*>(this)->LeafFindAll(result, value, add_offset, start, end);
	}
	else {
		// Get subnode table
		const Array offsets = NodeGetOffsets();
		const Array refs = NodeGetRefs();
		const size_t count = refs.Size();
		size_t i = offsets.FindPos(start);
		size_t offset = i ? (size_t)offsets.Get(i-1) : 0;
		size_t s = start - offset;
		size_t e = (end == (size_t)-1 || (int)end >= offsets.Get(i)) ? -1 : end - offset;

		for (;;) {
			const size_t ref = refs.GetAsRef(i);
			const C col(ref, (const Array*)NULL, 0, m_array->GetAllocator());

			size_t add = i ? (size_t)offsets.Get(i-1) : 0;
			add += add_offset;
			col.TreeFindAll<T, C>(result, value, add, s, e);
			++i;
			if (i >= count) break;

			s = 0;
			if (end != (size_t)-1) {
				if (end >= (size_t)offsets.Get(i)) e = (size_t)-1;
				else {
					offset = (size_t)offsets.Get(i-1);
					if(offset >= end)
						return;
					e = end - offset;
				}
			}
		}
	}
}



template<typename T, class C> void ColumnBase::TreeVisitLeafs(size_t start, size_t end, size_t caller_offset, bool (*call)(T *arr, size_t start, size_t end, size_t caller_offset, void *state), void *state) const {
	if (!IsNode()) {
		if(end == (size_t)-1) 
			end = m_array->Size();
		if(m_array->Size() > 0)
			call(m_array, start, end, caller_offset, state);
	}
	else {
		const Array offsets = NodeGetOffsets();
		const Array refs = NodeGetRefs();
		const size_t count = refs.Size();
		size_t i = offsets.FindPos(start);
		size_t offset = i ? (size_t)offsets.Get(i-1) : 0;
		size_t s = start - offset;
		size_t e = (end == (size_t)-1 || (int)end >= offsets.Get(i)) ? (size_t)-1 : end - offset;

		for (;;) {
			const size_t ref = refs.GetAsRef(i);
			const C col(ref, (const Array*)NULL, 0, m_array->GetAllocator());

			size_t add = i ? (size_t)offsets.Get(i-1) : 0;
			add += caller_offset;
			col.TreeVisitLeafs<T, C>(s, e, add, call, state);
			++i;
			if (i >= count) break;

			s = 0;
			if (end != (size_t)-1) {
				if (end >= (size_t)offsets.Get(i)) e = (size_t)-1;
				else {
					offset = (size_t)offsets.Get(i-1);
					if(offset >= end)
						return;
					e = end - offset;
				}
			}
		}
	}
	return;
}

}

#endif //__TDB_COLUMN_TEMPLATES__
