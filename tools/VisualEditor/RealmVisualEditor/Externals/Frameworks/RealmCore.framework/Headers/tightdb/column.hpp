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
#ifndef TIGHTDB_COLUMN_HPP
#define TIGHTDB_COLUMN_HPP

#include <stdint.h> // unint8_t etc
#include <cstdlib> // std::size_t

#include <RealmCore/tightdb/util/unique_ptr.hpp>
#include <RealmCore/tightdb/array.hpp>
#include <RealmCore/tightdb/column_type.hpp>
#include <RealmCore/tightdb/spec.hpp>
#include <RealmCore/tightdb/impl/output_stream.hpp>
#include <RealmCore/tightdb/query_conditions.hpp>

namespace tightdb {


// Pre-definitions
class Column;


/// Base class for all column types.
class ColumnBase {
public:
    /// Get the number of entries in this column.
    std::size_t size() const TIGHTDB_NOEXCEPT { return do_get_size(); }

    /// True if size is zero.
    bool is_empty() const TIGHTDB_NOEXCEPT { return size() == 0; }

    /// Add an entry to this column using the columns default value.
    virtual void add() = 0;

    /// Insert an entry into this column using the columns default
    /// value.
    virtual void insert(std::size_t ndx) = 0;

    /// Remove all entries from this column.
    virtual void clear() = 0;

    /// Remove the specified entry from this column. Set \a is_last to
    /// true when deleting the last element. This is important to
    /// avoid conversion to to general form of inner nodes of the
    /// B+-tree.
    virtual void erase(std::size_t ndx, bool is_last) = 0;

    /// Move the last element to the specified index. This reduces the
    /// number of elements by one.
    virtual void move_last_over(std::size_t ndx) = 0;

    virtual bool IsIntColumn() const TIGHTDB_NOEXCEPT { return false; }

    // Returns true if, and only if this column is an AdaptiveStringColumn.
    virtual bool is_string_col() const TIGHTDB_NOEXCEPT;

    virtual void destroy() TIGHTDB_NOEXCEPT;

    virtual ~ColumnBase() TIGHTDB_NOEXCEPT {};

    // Indexing
    virtual bool has_index() const TIGHTDB_NOEXCEPT { return false; }
    virtual void set_index_ref(ref_type, ArrayParent*, std::size_t) {}

    Allocator& get_alloc() const TIGHTDB_NOEXCEPT { return m_array->get_alloc(); }

    /// Returns the 'ref' of the root array.
    ref_type get_ref() const TIGHTDB_NOEXCEPT { return m_array->get_ref(); }

    //@{
    /// Returns the array node at the root of this column, but note
    /// that there is no guarantee that this node is an inner B+-tree
    /// node or a leaf. This is the case for a MixedColumn in
    /// particular.
    Array* get_root_array() TIGHTDB_NOEXCEPT { return m_array; }
    const Array* get_root_array() const TIGHTDB_NOEXCEPT { return m_array; }
    //@}

    /// Provides access to the leaf that contains the element at the
    /// specified index. Upon return \a ndx_in_leaf will be set to the
    /// corresponding index relative to the beginning of the leaf.
    ///
    /// When the root is a leaf, this function returns a pointer to
    /// the array accessor cached inside this column
    /// accessor. Otherwise this function attaches the specified
    /// fallback accessor to the identified leaf, and returns a
    /// pointer to the fallback accessor.
    ///
    /// This function cannot be used for modifying operations as it
    /// does not ensure the presence of an unbroken chain of parent
    /// accessors. For this reason, the identified leaf should always
    /// be accessed through the returned const-qualified reference,
    /// and never directly through the specfied fallback accessor.
    const Array& get_leaf(std::size_t ndx, std::size_t& ndx_in_leaf,
                          Array& fallback) const TIGHTDB_NOEXCEPT;

    // FIXME: Is almost identical to get_leaf(), but uses ill-defined
    // aspects of the Array API. Should be eliminated.
    const Array* GetBlock(std::size_t ndx, Array& arr, std::size_t& off,
                          bool use_retval = false) const TIGHTDB_NOEXCEPT;

    inline void detach(void);
    inline bool is_attached(void);

    static std::size_t get_size_from_type_and_ref(ColumnType, ref_type, Allocator&) TIGHTDB_NOEXCEPT;

    // These assume that the right column compile-time type has been
    // figured out.
    static std::size_t get_size_from_ref(ref_type root_ref, Allocator&);
    static std::size_t get_size_from_ref(ref_type spec_ref, ref_type columns_ref, Allocator&);

    /// Write a slice of this column to the specified output stream.
    virtual ref_type write(std::size_t slice_offset, std::size_t slice_size,
                           std::size_t table_size, _impl::OutputStream&) const = 0;

    void set_parent(ArrayParent*, std::size_t ndx_in_parent) TIGHTDB_NOEXCEPT;

    /// Called when the table-level index of this column has changed. Column
    /// classes that cache information pertaning to their position must override
    /// this function.
    virtual void update_column_index(std::size_t new_col_ndx, const Spec&) TIGHTDB_NOEXCEPT;

    /// Called in the context of Group::commit() to ensure that
    /// attached table accessors stay valid across a commit. Please
    /// note that this works only for non-transactional commits. Table
    /// accessors obtained during a transaction are always detached
    /// when the transaction ends.
    virtual void update_from_parent(std::size_t old_baseline) TIGHTDB_NOEXCEPT;

    void detach_subtable_accessors() TIGHTDB_NOEXCEPT;

    /// For columns that are able to contain subtables, this function returns
    /// the pointer to the subtable accessor at the specified row index if it
    /// exists, otherwise it returns null. For other column types, this function
    /// returns null.
    virtual Table* get_subtable_accessor(std::size_t row_ndx) const TIGHTDB_NOEXCEPT;

    /// Detach and remove the subtable accessor at the specified row if it
    /// exists. For column types that are unable to contain subtable, this
    /// function does nothing.
    virtual void discard_subtable_accessor(std::size_t row_ndx) TIGHTDB_NOEXCEPT;

    virtual void adj_accessors_insert_rows(std::size_t row_ndx, std::size_t num_rows)
        TIGHTDB_NOEXCEPT;
    virtual void adj_accessors_erase_row(std::size_t row_ndx) TIGHTDB_NOEXCEPT;
    virtual void adj_accessors_move_last_over(std::size_t target_row_ndx, std::size_t last_row_ndx)
        TIGHTDB_NOEXCEPT;

#ifdef TIGHTDB_ENABLE_REPLICATION
    virtual void recursive_mark_table_accessors_dirty() TIGHTDB_NOEXCEPT;
    virtual void refresh_after_advance_transact(std::size_t new_col_ndx, const Spec&) = 0;
#endif

#ifdef TIGHTDB_DEBUG
    // Must be upper case to avoid conflict with macro in Objective-C
    virtual void Verify() const = 0;
    virtual void to_dot(std::ostream&, StringData title = StringData()) const = 0;
    void dump_node_structure() const; // To std::cerr (for GDB)
    virtual void dump_node_structure(std::ostream&, int level) const = 0;
#endif

protected:
    // FIXME: This should not be mutable, the problem is again the
    // const-violating moving copy constructor.
    mutable Array* m_array;

    ColumnBase() TIGHTDB_NOEXCEPT {}
    ColumnBase(Array* root) TIGHTDB_NOEXCEPT: m_array(root) {}

    virtual std::size_t do_get_size() const TIGHTDB_NOEXCEPT = 0;

    // Must be able to operate with only the Minimal Accessor Hierarchy
    // Consistency Guarantee.
    virtual void do_detach_subtable_accessors() TIGHTDB_NOEXCEPT {}

    //@{
    /// \tparam L Any type with an appropriate `value_type`, %size(),
    /// and %get() members.
    template<class L, class T>
    std::size_t lower_bound(const L& list, T value) const TIGHTDB_NOEXCEPT;
    template<class L, class T>
    std::size_t upper_bound(const L& list, T value) const TIGHTDB_NOEXCEPT;
    //@}

    // Node functions
    bool root_is_leaf() const TIGHTDB_NOEXCEPT { return !m_array->is_inner_bptree_node(); }

    template <class T, class R, Action action, class condition>
    R aggregate(T target, std::size_t start, std::size_t end, size_t limit = size_t(-1)) const;

    /// Introduce a new root node which increments the height of the
    /// tree by one.
    void introduce_new_root(ref_type new_sibling_ref, Array::TreeInsertBase& state,
                            bool is_append);

    class EraseHandlerBase;

    class CreateHandler {
    public:
        virtual ref_type create_leaf(std::size_t size) = 0;
        ~CreateHandler() TIGHTDB_NOEXCEPT {}
    };

    static ref_type create(std::size_t size, Allocator&, CreateHandler&);

    class SliceHandler {
    public:
        virtual MemRef slice_leaf(MemRef leaf_mem, std::size_t offset, std::size_t size,
                                  Allocator& target_alloc) = 0;
        ~SliceHandler() TIGHTDB_NOEXCEPT {}
    };

    static ref_type write(const Array* root, std::size_t slice_offset, std::size_t slice_size,
                          std::size_t table_size, SliceHandler&, _impl::OutputStream&);

#ifdef TIGHTDB_DEBUG
    class LeafToDot;
    virtual void leaf_to_dot(MemRef, ArrayParent*, std::size_t ndx_in_parent,
                             std::ostream&) const = 0;
    void tree_to_dot(std::ostream&) const;
#endif

private:
    class WriteSliceHandler;

    static ref_type build(std::size_t* rest_size_ptr, std::size_t fixed_height,
                          Allocator&, CreateHandler&);

    friend class StringIndex;
};


class ColumnBase::EraseHandlerBase: public Array::EraseHandler {
protected:
    EraseHandlerBase(ColumnBase& column) TIGHTDB_NOEXCEPT: m_column(column) {}
    ~EraseHandlerBase() TIGHTDB_NOEXCEPT TIGHTDB_OVERRIDE {}
    Allocator& get_alloc() TIGHTDB_NOEXCEPT;
    void replace_root(util::UniquePtr<Array>& leaf);
private:
    ColumnBase& m_column;
};



/// An integer column (Column) is a single B+-tree, and the root of
/// the column is the root of the B+-tree. All leaf nodes are single
/// arrays of type Array.
///
/// FIXME: Rename Column to IntegerColumn.
class Column: public ColumnBase {
public:
    typedef int64_t value_type;

    explicit Column(Allocator&);
    Column(Array::Type, Allocator&);
    explicit Column(Array::Type = Array::type_Normal, ArrayParent* = 0,
                    std::size_t ndx_in_parent = 0, Allocator& = Allocator::get_default());
    explicit Column(ref_type, ArrayParent* = 0, std::size_t ndx_in_parent = 0,
                    Allocator& = Allocator::get_default());
    Column(ArrayParent*, std::size_t ndx_in_parent, Allocator&); // Unattached
    Column(const Column&); // FIXME: Constness violation
    ~Column() TIGHTDB_NOEXCEPT TIGHTDB_OVERRIDE;

    // 'this' and 'column' must use same allocator
    void move_assign(Column& column);
    bool IsIntColumn() const TIGHTDB_NOEXCEPT{ return true; }

    std::size_t size() const TIGHTDB_NOEXCEPT;
    bool is_empty() const TIGHTDB_NOEXCEPT { return size() == 0; }

    // Getting and setting values
    int64_t get(std::size_t ndx) const TIGHTDB_NOEXCEPT;
    ref_type get_as_ref(std::size_t ndx) const TIGHTDB_NOEXCEPT;
    int64_t back() const TIGHTDB_NOEXCEPT { return get(size()-1); }
    void set(std::size_t ndx, int64_t value);
    void adjust(std::size_t ndx, int64_t diff);
    void insert(std::size_t ndx) TIGHTDB_OVERRIDE { insert(ndx, 0); }
    void insert(std::size_t ndx, int64_t value);
    void add() TIGHTDB_OVERRIDE { add(0); }
    void add(int64_t value);

    std::size_t count(int64_t target) const;
    int64_t sum(std::size_t start = 0, std::size_t end = -1, size_t limit = size_t(-1)) const;
    int64_t maximum(std::size_t start = 0, std::size_t end = -1, size_t limit = size_t(-1)) const;
    int64_t minimum(std::size_t start = 0, std::size_t end = -1, size_t limit = size_t(-1)) const;
    double  average(std::size_t start = 0, std::size_t end = -1, size_t limit = size_t(-1)) const;

    // FIXME: Be careful, clear() currently forgets if the leaf type
    // is Array::type_HasRefs.
    void clear() TIGHTDB_OVERRIDE;

    void erase(std::size_t ndx, bool is_last) TIGHTDB_OVERRIDE;
    void move_last_over(std::size_t ndx) TIGHTDB_OVERRIDE;

    void adjust(int_fast64_t diff);
    void adjust_ge(int_fast64_t limit, int_fast64_t diff);

    size_t find_first(int64_t value, std::size_t begin = 0, std::size_t end = npos) const;
    void find_all(Column& result, int64_t value,
                  std::size_t begin = 0, std::size_t end = npos) const;

    //@{
    /// Find the lower/upper bound for the specified value assuming
    /// that the elements are already sorted in ascending order
    /// according to ordinary integer comparison.
    std::size_t lower_bound_int(int64_t value) const TIGHTDB_NOEXCEPT;
    std::size_t upper_bound_int(int64_t value) const TIGHTDB_NOEXCEPT;
    //@}

    // return first element E for which E >= target or return -1 if none. Array must be sorted
    size_t find_gte(int64_t target, size_t start) const;

    /// Compare two columns for equality.
    bool compare_int(const Column&) const;

    static ref_type create(Array::Type leaf_type, std::size_t size, int_fast64_t value,
                           Allocator&);

    // Overrriding method in ColumnBase
    ref_type write(std::size_t, std::size_t, std::size_t,
                   _impl::OutputStream&) const TIGHTDB_OVERRIDE;

#ifdef TIGHTDB_ENABLE_REPLICATION
    void refresh_after_advance_transact(std::size_t, const Spec&) TIGHTDB_OVERRIDE;
#endif

#ifdef TIGHTDB_DEBUG
    virtual void Verify() const TIGHTDB_OVERRIDE;
    void to_dot(std::ostream&, StringData title) const TIGHTDB_OVERRIDE;
    MemStats stats() const;
    void dump_node_structure(std::ostream&, int level) const TIGHTDB_OVERRIDE;
    using ColumnBase::dump_node_structure;
#endif

protected:
    Column(Array* root);

    std::size_t do_get_size() const TIGHTDB_NOEXCEPT TIGHTDB_OVERRIDE { return size(); }

#ifdef TIGHTDB_DEBUG
    void leaf_to_dot(MemRef, ArrayParent*, std::size_t ndx_in_parent,
                     std::ostream&) const TIGHTDB_OVERRIDE;
#endif

private:
    Column &operator=(const Column&); // not allowed

    void do_insert(std::size_t ndx, int64_t value);

    // Called by Array::bptree_insert().
    static ref_type leaf_insert(MemRef leaf_mem, ArrayParent&, std::size_t ndx_in_parent,
                                Allocator&, std::size_t insert_ndx, Array::TreeInsert<Column>&);

    class EraseLeafElem;
    class CreateHandler;
    class SliceHandler;

    friend class Array;
    friend class ColumnBase;
};




// Implementation:

inline void ColumnBase::detach()
{
    m_array->detach();
}

inline bool ColumnBase::is_attached()
{
    return m_array->is_attached();
}

inline bool ColumnBase::is_string_col() const TIGHTDB_NOEXCEPT
{
    return false;
}

inline void ColumnBase::destroy() TIGHTDB_NOEXCEPT
{
    if (m_array)
        m_array->destroy_deep();
}

inline void ColumnBase::update_column_index(std::size_t, const Spec&) TIGHTDB_NOEXCEPT
{
    // Noop
}

inline void ColumnBase::detach_subtable_accessors() TIGHTDB_NOEXCEPT
{
    do_detach_subtable_accessors();
}

inline Table* ColumnBase::get_subtable_accessor(std::size_t) const TIGHTDB_NOEXCEPT
{
    return 0;
}

inline void ColumnBase::discard_subtable_accessor(std::size_t) TIGHTDB_NOEXCEPT
{
    // Noop
}

inline void ColumnBase::adj_accessors_insert_rows(std::size_t, std::size_t) TIGHTDB_NOEXCEPT
{
    // Noop
}

inline void ColumnBase::adj_accessors_erase_row(std::size_t) TIGHTDB_NOEXCEPT
{
    // Noop
}

inline void ColumnBase::adj_accessors_move_last_over(std::size_t, std::size_t) TIGHTDB_NOEXCEPT
{
    // Noop
}

#ifdef TIGHTDB_ENABLE_REPLICATION

inline void ColumnBase::recursive_mark_table_accessors_dirty() TIGHTDB_NOEXCEPT
{
    // Noop
}

#endif

inline void ColumnBase::set_parent(ArrayParent* parent, std::size_t ndx_in_parent) TIGHTDB_NOEXCEPT
{
    m_array->set_parent(parent, ndx_in_parent);
}

inline const Array& ColumnBase::get_leaf(std::size_t ndx, std::size_t& ndx_in_leaf,
                                         Array& fallback) const TIGHTDB_NOEXCEPT
{
    if (!m_array->is_inner_bptree_node()) {
        ndx_in_leaf = ndx;
        return *m_array;
    }
    std::pair<MemRef, std::size_t> p = m_array->get_bptree_leaf(ndx);
    fallback.init_from_mem(p.first);
    ndx_in_leaf = p.second;
    return fallback;
}

inline const Array* ColumnBase::GetBlock(std::size_t ndx, Array& arr, std::size_t& off,
                                         bool use_retval) const TIGHTDB_NOEXCEPT
{
    return m_array->GetBlock(ndx, arr, off, use_retval);
}

inline std::size_t ColumnBase::get_size_from_ref(ref_type root_ref, Allocator& alloc)
{
    const char* root_header = alloc.translate(root_ref);
    bool root_is_leaf = !Array::get_is_inner_bptree_node_from_header(root_header);
    if (root_is_leaf)
        return Array::get_size_from_header(root_header);
    return Array::get_bptree_size_from_header(root_header);
}

template<class L, class T>
std::size_t ColumnBase::lower_bound(const L& list, T value) const TIGHTDB_NOEXCEPT
{
    std::size_t i = 0;
    std::size_t size = list.size();
    while (0 < size) {
        std::size_t half = size / 2;
        std::size_t mid = i + half;
        typename L::value_type probe = list.get(mid);
        if (probe < value) {
            i = mid + 1;
            size -= half + 1;
        }
        else {
            size = half;
        }
    }
    return i;
}

template<class L, class T>
std::size_t ColumnBase::upper_bound(const L& list, T value) const TIGHTDB_NOEXCEPT
{
    size_t i = 0;
    size_t size = list.size();
    while (0 < size) {
        size_t half = size / 2;
        size_t mid = i + half;
        typename L::value_type probe = list.get(mid);
        if (!(value < probe)) {
            i = mid + 1;
            size -= half + 1;
        }
        else {
            size = half;
        }
    }
    return i;
}


inline Allocator& ColumnBase::EraseHandlerBase::get_alloc() TIGHTDB_NOEXCEPT
{
    return m_column.m_array->get_alloc();
}

inline void ColumnBase::EraseHandlerBase::replace_root(util::UniquePtr<Array>& leaf)
{
    ArrayParent* parent = m_column.m_array->get_parent();
    std::size_t ndx_in_parent = m_column.m_array->get_ndx_in_parent();
    leaf->set_parent(parent, ndx_in_parent);
    leaf->update_parent(); // Throws
    delete m_column.m_array;
    m_column.m_array = leaf.release();
}

inline ref_type ColumnBase::create(std::size_t size, Allocator& alloc, CreateHandler& handler)
{
    std::size_t rest_size = size;
    std::size_t fixed_height = 0; // Not fixed
    return build(&rest_size, fixed_height, alloc, handler);
}

inline Column::Column(Allocator& alloc):
    ColumnBase(new Array(Array::type_Normal, null_ptr, 0, alloc))
{
}

inline Column::Column(Array::Type type, Allocator& alloc):
    ColumnBase(new Array(type, null_ptr, 0, alloc))
{
    TIGHTDB_ASSERT(root_is_leaf());
}

inline Column::Column(Array::Type type, ArrayParent* parent, std::size_t ndx_in_parent,
                      Allocator& alloc):
    ColumnBase(new Array(type, parent, ndx_in_parent, alloc))
{
    TIGHTDB_ASSERT(root_is_leaf());
}

inline Column::Column(ref_type ref, ArrayParent* parent, std::size_t ndx_in_parent,
                      Allocator& alloc):
    ColumnBase(new Array(ref, parent, ndx_in_parent, alloc)) {}

inline Column::Column(const Column& column): ColumnBase(column.m_array)
{
    // FIXME: Unfortunate hidden constness violation here
    // we now own array
    column.m_array = 0;       // so detach source
}

inline Column::Column(Array* root): ColumnBase(root) {}

inline Column::~Column() TIGHTDB_NOEXCEPT
{
    delete m_array;
}

inline std::size_t Column::size() const TIGHTDB_NOEXCEPT
{
    if (root_is_leaf())
        return m_array->size();
    return m_array->get_bptree_size();
}

inline int64_t Column::get(std::size_t ndx) const TIGHTDB_NOEXCEPT
{
    TIGHTDB_ASSERT(ndx < size());
    if (root_is_leaf())
        return m_array->get(ndx);

    std::pair<MemRef, std::size_t> p = m_array->get_bptree_leaf(ndx);
    const char* leaf_header = p.first.m_addr;
    std::size_t ndx_in_leaf = p.second;
    return Array::get(leaf_header, ndx_in_leaf);
}

inline ref_type Column::get_as_ref(std::size_t ndx) const TIGHTDB_NOEXCEPT
{
    return to_ref(get(ndx));
}

inline void Column::add(int64_t value)
{
    do_insert(npos, value);
}

inline void Column::insert(std::size_t ndx, int64_t value)
{
    TIGHTDB_ASSERT(ndx <= size());
    if (size() <= ndx)
        ndx = npos;
    do_insert(ndx, value);
}

TIGHTDB_FORCEINLINE
ref_type Column::leaf_insert(MemRef leaf_mem, ArrayParent& parent, std::size_t ndx_in_parent,
                             Allocator& alloc, std::size_t insert_ndx,
                             Array::TreeInsert<Column>& state)
{
    Array leaf(leaf_mem, &parent, ndx_in_parent, alloc);
    return leaf.bptree_leaf_insert(insert_ndx, state.m_value, state);
}


inline std::size_t Column::lower_bound_int(int64_t value) const TIGHTDB_NOEXCEPT
{
    if (root_is_leaf()) {
        return m_array->lower_bound_int(value);
    }
    return ColumnBase::lower_bound(*this, value);
}

inline std::size_t Column::upper_bound_int(int64_t value) const TIGHTDB_NOEXCEPT
{
    if (root_is_leaf()) {
        return m_array->upper_bound_int(value);
    }
    return ColumnBase::upper_bound(*this, value);
}

// For a *sorted* Column, return first element E for which E >= target or return -1 if none
inline size_t Column::find_gte(int64_t target, size_t start) const
{
    // fixme: slow reference implementation. See Array::FindGTE for faster version
    size_t ref = 0;
    size_t idx;
    for (idx = start; idx < size(); ++idx) {
        if (get(idx) >= target) {
            ref = idx;
            break;
        }
    }
    if (idx == size())
        ref = not_found;

    return ref;
}

} // namespace tightdb

// Templates
#include <RealmCore/tightdb/column_tpl.hpp>

#endif // TIGHTDB_COLUMN_HPP
