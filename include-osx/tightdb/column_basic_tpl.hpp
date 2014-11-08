/*************************************************************************
 *
 * TIGHTDB CONFIDENTIAL
 * __________________
 *
 *  [2011] - [2012] TightDB Inc
 *  All Rights Reserved.
 *
 * NOTICE:  All information contained herein is, and remains
 * the property of TightDB Incorporated and its suppliers,
 * if any.  The intellectual and technical concepts contained
 * herein are proprietary to TightDB Incorporated
 * and its suppliers and may be covered by U.S. and Foreign Patents,
 * patents in process, and are protected by trade secret or copyright law.
 * Dissemination of this information or reproduction of this material
 * is strictly forbidden unless prior written permission is obtained
 * from TightDB Incorporated.
 *
 **************************************************************************/
#ifndef TIGHTDB_COLUMN_BASIC_TPL_HPP
#define TIGHTDB_COLUMN_BASIC_TPL_HPP

// Todo: It's bad design (headers are entangled) that a Column uses query_engine.hpp which again uses Column.
// It's the aggregate() method that calls query_engine, and a quick fix (still not optimal) could be to create
// the call and include inside float and double's .cpp files.
#include <tightdb/query_engine.hpp>

namespace tightdb {

// Predeclarations from query_engine.hpp
class ParentNode;
template<class T, class F> class FloatDoubleNode;
template<class T> class SequentialGetter;


template<class T>
BasicColumn<T>::BasicColumn(Allocator& alloc, ref_type ref)
{
    char* header = alloc.translate(ref);
    bool root_is_leaf = !Array::get_is_inner_bptree_node_from_header(header);
    if (root_is_leaf) {
        BasicArray<T>* root = new BasicArray<T>(alloc); // Throws
        root->init_from_mem(MemRef(header, ref));
        m_array = root;
    }
    else {
        Array* root = new Array(alloc); // Throws
        root->init_from_mem(MemRef(header, ref));
        m_array = root;
    }
}

template<class T>
BasicColumn<T>::~BasicColumn() TIGHTDB_NOEXCEPT
{
    if (root_is_leaf()) {
        delete static_cast<BasicArray<T>*>(m_array);
    }
    else {
        delete m_array;
    }
}

template<class T>
inline std::size_t BasicColumn<T>::size() const TIGHTDB_NOEXCEPT
{
    if (root_is_leaf())
        return m_array->size();
    return m_array->get_bptree_size();
}

template<class T>
void BasicColumn<T>::clear()
{
    if (!m_array->is_inner_bptree_node()) {
        static_cast<BasicArray<T>*>(m_array)->clear(); // Throws
        return;
    }

    // Revert to generic array
    util::UniquePtr<BasicArray<T> > array;
    array.reset(new BasicArray<T>(m_array->get_alloc())); // Throws
    array->create(); // Throws
    array->set_parent(m_array->get_parent(), m_array->get_ndx_in_parent());
    array->update_parent(); // Throws

    // Remove original node
    m_array->destroy_deep();
    delete m_array;

    m_array = array.release();
}

template<class T>
void BasicColumn<T>::move_last_over(std::size_t target_row_ndx, std::size_t last_row_ndx)
{
    TIGHTDB_ASSERT(target_row_ndx < last_row_ndx);
    TIGHTDB_ASSERT(last_row_ndx + 1 == size());

    T value = get(last_row_ndx);
    set(target_row_ndx, value); // Throws

    bool is_last = true;
    erase(last_row_ndx, is_last); // Throws
}


template<class T>
T BasicColumn<T>::get(std::size_t ndx) const TIGHTDB_NOEXCEPT
{
    TIGHTDB_ASSERT(ndx < size());
    if (root_is_leaf())
        return static_cast<const BasicArray<T>*>(m_array)->get(ndx);

    std::pair<MemRef, std::size_t> p = m_array->get_bptree_leaf(ndx);
    const char* leaf_header = p.first.m_addr;
    std::size_t ndx_in_leaf = p.second;
    return BasicArray<T>::get(leaf_header, ndx_in_leaf);
}


template<class T>
class BasicColumn<T>::SetLeafElem: public Array::UpdateHandler {
public:
    Allocator& m_alloc;
    const T m_value;
    SetLeafElem(Allocator& alloc, T value) TIGHTDB_NOEXCEPT: m_alloc(alloc), m_value(value) {}
    void update(MemRef mem, ArrayParent* parent, std::size_t ndx_in_parent,
                std::size_t elem_ndx_in_leaf) TIGHTDB_OVERRIDE
    {
        BasicArray<T> leaf(m_alloc);
        leaf.init_from_mem(mem);
        leaf.set_parent(parent, ndx_in_parent);
        leaf.set(elem_ndx_in_leaf, m_value); // Throws
    }
};

template<class T>
void BasicColumn<T>::set(std::size_t ndx, T value)
{
    if (!m_array->is_inner_bptree_node()) {
        static_cast<BasicArray<T>*>(m_array)->set(ndx, value); // Throws
        return;
    }

    SetLeafElem set_leaf_elem(m_array->get_alloc(), value);
    m_array->update_bptree_elem(ndx, set_leaf_elem); // Throws
}

template<class T> inline void BasicColumn<T>::add(T value)
{
    std::size_t row_ndx = tightdb::npos;
    std::size_t num_rows = 1;
    do_insert(row_ndx, value, num_rows); // Throws
}

template<class T> inline void BasicColumn<T>::insert(std::size_t row_ndx, T value)
{
    std::size_t size = this->size(); // Slow
    TIGHTDB_ASSERT(row_ndx <= size);
    std::size_t row_ndx_2 = row_ndx == size ? tightdb::npos : row_ndx;
    std::size_t num_rows = 1;
    do_insert(row_ndx_2, value, num_rows); // Throws
}

// Implementing pure virtual method of ColumnBase.
template<class T>
inline void BasicColumn<T>::insert(std::size_t row_ndx, std::size_t num_rows, bool is_append)
{
    std::size_t row_ndx_2 = is_append ? tightdb::npos : row_ndx;
    T value = T();
    do_insert(row_ndx_2, value, num_rows); // Throws
}

template<class T>
bool BasicColumn<T>::compare(const BasicColumn& c) const
{
    std::size_t n = size();
    if (c.size() != n)
        return false;
    for (std::size_t i = 0; i != n; ++i) {
        T v_1 = get(i);
        T v_2 = c.get(i);
        if (v_1 != v_2)
            return false;
    }
    return true;
}


template<class T>
class BasicColumn<T>::EraseLeafElem: public ColumnBase::EraseHandlerBase {
public:
    EraseLeafElem(BasicColumn<T>& column) TIGHTDB_NOEXCEPT:
        EraseHandlerBase(column) {}
    bool erase_leaf_elem(MemRef leaf_mem, ArrayParent* parent,
                         std::size_t leaf_ndx_in_parent,
                         std::size_t elem_ndx_in_leaf) TIGHTDB_OVERRIDE
    {
        BasicArray<T> leaf(get_alloc());
        leaf.init_from_mem(leaf_mem);
        leaf.set_parent(parent, leaf_ndx_in_parent);
        TIGHTDB_ASSERT(leaf.size() >= 1);
        std::size_t last_ndx = leaf.size() - 1;
        if (last_ndx == 0)
            return true;
        std::size_t ndx = elem_ndx_in_leaf;
        if (ndx == npos)
            ndx = last_ndx;
        leaf.erase(ndx); // Throws
        return false;
    }
    void destroy_leaf(MemRef leaf_mem) TIGHTDB_NOEXCEPT TIGHTDB_OVERRIDE
    {
        Array::destroy(leaf_mem, get_alloc()); // Shallow
    }
    void replace_root_by_leaf(MemRef leaf_mem) TIGHTDB_OVERRIDE
    {
        BasicArray<T>* leaf = new BasicArray<T>(get_alloc()); // Throws
        leaf->init_from_mem(leaf_mem);
        replace_root(leaf); // Throws, but accessor ownership is passed to callee
    }
    void replace_root_by_empty_leaf() TIGHTDB_OVERRIDE
    {
        util::UniquePtr<BasicArray<T> > leaf;
        leaf.reset(new BasicArray<T>(get_alloc())); // Throws
        leaf->create(); // Throws
        replace_root(leaf.release()); // Throws, but accessor ownership is passed to callee
    }
};

template<class T>
void BasicColumn<T>::erase(std::size_t ndx, bool is_last)
{
    TIGHTDB_ASSERT(ndx < size());
    TIGHTDB_ASSERT(is_last == (ndx == size()-1));

    if (!m_array->is_inner_bptree_node()) {
        static_cast<BasicArray<T>*>(m_array)->erase(ndx); // Throws
        return;
    }

    size_t ndx_2 = is_last ? npos : ndx;
    EraseLeafElem erase_leaf_elem(*this);
    Array::erase_bptree_elem(m_array, ndx_2, erase_leaf_elem); // Throws
}


template<class T> class BasicColumn<T>::CreateHandler: public ColumnBase::CreateHandler {
public:
    CreateHandler(Allocator& alloc): m_alloc(alloc) {}
    ref_type create_leaf(std::size_t size) TIGHTDB_OVERRIDE
    {
        MemRef mem = BasicArray<T>::create_array(size, m_alloc); // Throws
        T* tp = reinterpret_cast<T*>(Array::get_data_from_header(mem.m_addr));
        std::fill(tp, tp + size, T());
        return mem.m_ref;
    }
private:
    Allocator& m_alloc;
};

template<class T> ref_type BasicColumn<T>::create(Allocator& alloc, std::size_t size)
{
    CreateHandler handler(alloc);
    return ColumnBase::create(alloc, size, handler);
}


template<class T> class BasicColumn<T>::SliceHandler: public ColumnBase::SliceHandler {
public:
    SliceHandler(Allocator& alloc): m_leaf(alloc) {}
    MemRef slice_leaf(MemRef leaf_mem, size_t offset, size_t size,
                      Allocator& target_alloc) TIGHTDB_OVERRIDE
    {
        m_leaf.init_from_mem(leaf_mem);
        return m_leaf.slice(offset, size, target_alloc); // Throws
    }
private:
    BasicArray<T> m_leaf;
};

template<class T> ref_type BasicColumn<T>::write(size_t slice_offset, size_t slice_size,
                                                 size_t table_size, _impl::OutputStream& out) const
{
    ref_type ref;
    if (root_is_leaf()) {
        Allocator& alloc = Allocator::get_default();
        BasicArray<T>* leaf = static_cast<BasicArray<T>*>(m_array);
        MemRef mem = leaf->slice(slice_offset, slice_size, alloc); // Throws
        Array slice(alloc);
        _impl::DeepArrayDestroyGuard dg(&slice);
        slice.init_from_mem(mem);
        size_t pos = slice.write(out); // Throws
        ref = pos;
    }
    else {
        SliceHandler handler(get_alloc());
        ref = ColumnBase::write(m_array, slice_offset, slice_size,
                                table_size, handler, out); // Throws
    }
    return ref;
}


template<class T> void BasicColumn<T>::refresh_accessor_tree(std::size_t, const Spec&)
{
    // The type of the cached root array accessor may no longer match the
    // underlying root node. In that case we need to replace it. Note that when
    // the root node is an inner B+-tree node, then only the top array accessor
    // of that node is cached. The top array accessor of an inner B+-tree node
    // is of type Array.

    ref_type root_ref = m_array->get_ref_from_parent();
    MemRef root_mem(root_ref, m_array->get_alloc());
    bool new_root_is_leaf = !Array::get_is_inner_bptree_node_from_header(root_mem.m_addr);
    bool old_root_is_leaf = !m_array->is_inner_bptree_node();

    bool root_type_changed = old_root_is_leaf != new_root_is_leaf;
    if (!root_type_changed) {
        // Keep, but refresh old root accessor
        if (old_root_is_leaf) {
            // Root is leaf
            BasicArray<T>* root = static_cast<BasicArray<T>*>(m_array);
            root->init_from_parent();
            return;
        }
        // Root is inner node
        Array* root = m_array;
        root->init_from_parent();
        return;
    }

    // Create new root accessor
    Array* new_root;
    Allocator& alloc = m_array->get_alloc();
    if (new_root_is_leaf) {
        // New root is leaf
        BasicArray<T>* root = new BasicArray<T>(alloc); // Throws
        root->init_from_mem(root_mem);
        new_root = root;
    }
    else {
        // New root is inner node
        Array* root = new Array(alloc); // Throws
        root->init_from_mem(root_mem);
        new_root = root;
    }
    new_root->set_parent(m_array->get_parent(), m_array->get_ndx_in_parent());

    // Destroy old root accessor
    if (old_root_is_leaf) {
        // Old root is leaf
        BasicArray<T>* old_root = static_cast<BasicArray<T>*>(m_array);
        delete old_root;
    }
    else {
        // Old root is inner node
        Array* old_root = m_array;
        delete old_root;
    }

    // Instate new root
    m_array = new_root;
}


#ifdef TIGHTDB_DEBUG

template<class T>
std::size_t BasicColumn<T>::verify_leaf(MemRef mem, Allocator& alloc)
{
    BasicArray<T> leaf(alloc);
    leaf.init_from_mem(mem);
    leaf.Verify();
    return leaf.size();
}

template<class T>
void BasicColumn<T>::Verify() const
{
    if (root_is_leaf()) {
        static_cast<BasicArray<T>*>(m_array)->Verify();
        return;
    }

    m_array->verify_bptree(&BasicColumn<T>::verify_leaf);
}


template<class T>
void BasicColumn<T>::to_dot(std::ostream& out, StringData title) const
{
    ref_type ref = m_array->get_ref();
    out << "subgraph cluster_basic_column" << ref << " {\n";
    out << " label = \"Basic column";
    if (title.size() != 0)
        out << "\\n'" << title << "'";
    out << "\";\n";
    tree_to_dot(out);
    out << "}\n";
}

template<class T>
void BasicColumn<T>::leaf_to_dot(MemRef leaf_mem, ArrayParent* parent, std::size_t ndx_in_parent,
                                 std::ostream& out) const
{
    BasicArray<T> leaf(m_array->get_alloc());
    leaf.init_from_mem(leaf_mem);
    leaf.set_parent(parent, ndx_in_parent);
    leaf.to_dot(out);
}

template<class T>
inline void BasicColumn<T>::leaf_dumper(MemRef mem, Allocator& alloc, std::ostream& out, int level)
{
    BasicArray<T> leaf(alloc);
    leaf.init_from_mem(mem);
    int indent = level * 2;
    out << std::setw(indent) << "" << "Basic leaf (size: "<<leaf.size()<<")\n";
}

template<class T>
inline void BasicColumn<T>::do_dump_node_structure(std::ostream& out, int level) const
{
    m_array->dump_bptree_structure(out, level, &leaf_dumper);
}

#endif // TIGHTDB_DEBUG


template<class T>
std::size_t BasicColumn<T>::find_first(T value, std::size_t begin, std::size_t end) const
{
    TIGHTDB_ASSERT(begin <= size());
    TIGHTDB_ASSERT(end == npos || (begin <= end && end <= size()));

    if (root_is_leaf())
        return static_cast<BasicArray<T>*>(m_array)->
            find_first(value, begin, end); // Throws (maybe)

    // FIXME: It would be better to always require that 'end' is
    // specified explicitely, since Table has the size readily
    // available, and Array::get_bptree_size() is deprecated.
    if (end == npos)
        end = m_array->get_bptree_size();

    std::size_t ndx_in_tree = begin;
    while (ndx_in_tree < end) {
        std::pair<MemRef, std::size_t> p = m_array->get_bptree_leaf(ndx_in_tree);
        BasicArray<T> leaf(m_array->get_alloc());
        leaf.init_from_mem(p.first);
        std::size_t ndx_in_leaf = p.second;
        std::size_t leaf_offset = ndx_in_tree - ndx_in_leaf;
        std::size_t end_in_leaf = std::min(leaf.size(), end - leaf_offset);
        std::size_t ndx = leaf.find_first(value, ndx_in_leaf, end_in_leaf); // Throws (maybe)
        if (ndx != not_found)
            return leaf_offset + ndx;
        ndx_in_tree = leaf_offset + end_in_leaf;
    }

    return not_found;
}

template<class T>
void BasicColumn<T>::find_all(Column &result, T value, std::size_t begin, std::size_t end) const
{
    TIGHTDB_ASSERT(begin <= size());
    TIGHTDB_ASSERT(end == npos || (begin <= end && end <= size()));

    if (root_is_leaf()) {
        std::size_t leaf_offset = 0;
        static_cast<BasicArray<T>*>(m_array)->find_all(&result, value, leaf_offset, begin, end); // Throws
        return;
    }

    // FIXME: It would be better to always require that 'end' is
    // specified explicitely, since Table has the size readily
    // available, and Array::get_bptree_size() is deprecated.
    if (end == npos)
        end = m_array->get_bptree_size();

    std::size_t ndx_in_tree = begin;
    while (ndx_in_tree < end) {
        std::pair<MemRef, std::size_t> p = m_array->get_bptree_leaf(ndx_in_tree);
        BasicArray<T> leaf(m_array->get_alloc());
        leaf.init_from_mem(p.first);
        std::size_t ndx_in_leaf = p.second;
        std::size_t leaf_offset = ndx_in_tree - ndx_in_leaf;
        std::size_t end_in_leaf = std::min(leaf.size(), end - leaf_offset);
        leaf.find_all(&result, value, leaf_offset, ndx_in_leaf, end_in_leaf); // Throws
        ndx_in_tree = leaf_offset + end_in_leaf;
    }
}

template<class T> std::size_t BasicColumn<T>::count(T target) const
{
    return std::size_t(ColumnBase::aggregate<T, int64_t, act_Count, Equal>(target, 0, size()));
}

template<class T>
typename BasicColumn<T>::SumType BasicColumn<T>::sum(std::size_t begin, std::size_t end,
    std::size_t limit, std::size_t* return_ndx) const
{
    return ColumnBase::aggregate<T, SumType, act_Sum, None>(0, begin, end, limit, return_ndx);
}
template<class T>
T BasicColumn<T>::minimum(std::size_t begin, std::size_t end, std::size_t limit, size_t* return_ndx) const
{
    return ColumnBase::aggregate<T, T, act_Min, None>(0, begin, end, limit, return_ndx);
}

template<class T>
T BasicColumn<T>::maximum(std::size_t begin, std::size_t end, std::size_t limit, size_t* return_ndx) const
{
    return ColumnBase::aggregate<T, T, act_Max, None>(0, begin, end, limit, return_ndx);
}

template<class T>
double BasicColumn<T>::average(std::size_t begin, std::size_t end, std::size_t limit, size_t* /*return_ndx*/) const
{
    if (end == npos)
        end = size();

    if(limit != npos && begin + limit < end)
        end = begin + limit;

    std::size_t size = end - begin;
    double sum1 = sum(begin, end);
    double avg = sum1 / ( size == 0 ? 1 : size );
    return avg;
}

template<class T> void BasicColumn<T>::do_insert(std::size_t row_ndx, T value, std::size_t num_rows)
{
    TIGHTDB_ASSERT(row_ndx == tightdb::npos || row_ndx < size());
    ref_type new_sibling_ref;
    Array::TreeInsert<BasicColumn<T> > state;
    for (std::size_t i = 0; i != num_rows; ++i) {
        std::size_t row_ndx_2 = row_ndx == tightdb::npos ? tightdb::npos : row_ndx + i;
        if (root_is_leaf()) {
            TIGHTDB_ASSERT(row_ndx_2 == tightdb::npos || row_ndx_2 < TIGHTDB_MAX_BPNODE_SIZE);
            BasicArray<T>* leaf = static_cast<BasicArray<T>*>(m_array);
            new_sibling_ref = leaf->bptree_leaf_insert(row_ndx_2, value, state);
        }
        else {
            state.m_value = value;
            if (row_ndx_2 == tightdb::npos) {
                new_sibling_ref = m_array->bptree_append(state); // Throws
            }
            else {
                new_sibling_ref = m_array->bptree_insert(row_ndx_2, state); // Throws
            }
        }
        if (TIGHTDB_UNLIKELY(new_sibling_ref)) {
            bool is_append = row_ndx_2 == tightdb::npos;
            introduce_new_root(new_sibling_ref, state, is_append); // Throws
        }
    }
}

template<class T> TIGHTDB_FORCEINLINE
ref_type BasicColumn<T>::leaf_insert(MemRef leaf_mem, ArrayParent& parent,
                                     std::size_t ndx_in_parent,
                                     Allocator& alloc, std::size_t insert_ndx,
                                     Array::TreeInsert<BasicColumn<T> >& state)
{
    BasicArray<T> leaf(alloc);
    leaf.init_from_mem(leaf_mem);
    leaf.set_parent(&parent, ndx_in_parent);
    return leaf.bptree_leaf_insert(insert_ndx, state.m_value, state);
}


template<class T> inline std::size_t BasicColumn<T>::lower_bound(T value) const TIGHTDB_NOEXCEPT
{
    if (root_is_leaf()) {
        return static_cast<const BasicArray<T>*>(m_array)->lower_bound(value);
    }
    return ColumnBase::lower_bound(*this, value);
}

template<class T> inline std::size_t BasicColumn<T>::upper_bound(T value) const TIGHTDB_NOEXCEPT
{
    if (root_is_leaf()) {
        return static_cast<const BasicArray<T>*>(m_array)->upper_bound(value);
    }
    return ColumnBase::upper_bound(*this, value);
}


} // namespace tightdb

#endif // TIGHTDB_COLUMN_BASIC_TPL_HPP
