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

#include <tightdb/util/unique_ptr.hpp>
#include <tightdb/array.hpp>
#include <tightdb/column_type.hpp>
#include <tightdb/spec.hpp>
#include <tightdb/impl/output_stream.hpp>
#include <tightdb/query_conditions.hpp>

namespace tightdb {


// Pre-definitions
class Column;

struct ColumnTemplateBase
{
    virtual int compare_values(size_t row1, size_t row2) const = 0;
};

template <class T> struct ColumnTemplate : public ColumnTemplateBase
{
    // Overridden in column_string.* because == operator of StringData isn't yet locale aware; todo
    virtual int compare_values(size_t row1, size_t row2) const
    {
        T a = get_val(row1);
        T b = get_val(row2);
        return a == b ? 0 : a < b ? 1 : -1;
    }

    // We cannot use already-existing get() methods because ColumnStringEnum and LinkList inherit from
    // Column and overload get() with different return type than int64_t. Todo, find a way to simplify
    virtual T get_val(size_t row) const = 0;
};

/// Base class for all column types.
class ColumnBase {
public:
    /// Get the number of entries in this column. This operation is relatively
    /// slow.
    std::size_t size() const TIGHTDB_NOEXCEPT;

    /// \throw LogicError Thrown if this column is not string valued.
    virtual void set_string(std::size_t row_ndx, StringData value);

    /// Insert the specified number of default values into this column starting
    /// at the specified row index. Set `is_append` to true if, and only if
    /// `row_ndx` is equal to the size of the column (before insertion).
    virtual void insert(std::size_t row_ndx, std::size_t num_rows, bool is_append) = 0;

    /// Remove all entries from this column.
    virtual void clear() = 0;

    /// Remove the specified entry from this column. Set \a is_last to
    /// true when deleting the last element. This is important to
    /// avoid conversion to to general form of inner nodes of the
    /// B+-tree.
    virtual void erase(std::size_t ndx, bool is_last) = 0;

    /// Move the last element to the specified target index. This reduces the
    /// number of elements by one. The specified last row index must always be
    /// one less than the number of rows in the column. The target index must
    /// always be strictly less that the last index.
    virtual void move_last_over(std::size_t target_row_ndx, std::size_t last_row_ndx) = 0;

    virtual bool IsIntColumn() const TIGHTDB_NOEXCEPT { return false; }

    // Returns true if, and only if this column is an AdaptiveStringColumn.
    virtual bool is_string_col() const TIGHTDB_NOEXCEPT;

    virtual void destroy() TIGHTDB_NOEXCEPT;

    virtual ~ColumnBase() TIGHTDB_NOEXCEPT {};

    // Search index
    virtual bool has_search_index() const TIGHTDB_NOEXCEPT;
    virtual void set_search_index_ref(ref_type, ArrayParent*, std::size_t ndx_in_parent,
                                      bool allow_duplicate_values);
    virtual void set_search_index_allow_duplicate_values(bool) TIGHTDB_NOEXCEPT;

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
    inline bool is_attached(void) const TIGHTDB_NOEXCEPT;

    static std::size_t get_size_from_type_and_ref(ColumnType, ref_type, Allocator&) TIGHTDB_NOEXCEPT;

    // These assume that the right column compile-time type has been
    // figured out.
    static std::size_t get_size_from_ref(ref_type root_ref, Allocator&);
    static std::size_t get_size_from_ref(ref_type spec_ref, ref_type columns_ref, Allocator&);

    /// Write a slice of this column to the specified output stream.
    virtual ref_type write(std::size_t slice_offset, std::size_t slice_size,
                           std::size_t table_size, _impl::OutputStream&) const = 0;

    void set_parent(ArrayParent*, std::size_t ndx_in_parent) TIGHTDB_NOEXCEPT;

    /// Called in the context of Group::commit() and
    /// SharedGroup::commit_and_continue_as_read()() to ensure that attached
    /// table and link list accessors stay valid across a commit.
    virtual void update_from_parent(std::size_t old_baseline) TIGHTDB_NOEXCEPT;

    void discard_child_accessors() TIGHTDB_NOEXCEPT;

    /// For columns that are able to contain subtables, this function returns
    /// the pointer to the subtable accessor at the specified row index if it
    /// exists, otherwise it returns null. For other column types, this function
    /// returns null.
    virtual Table* get_subtable_accessor(std::size_t row_ndx) const TIGHTDB_NOEXCEPT;

    /// Detach and remove the subtable accessor at the specified row if it
    /// exists. For column types that are unable to contain subtable, this
    /// function does nothing.
    virtual void discard_subtable_accessor(std::size_t row_ndx) TIGHTDB_NOEXCEPT;

    virtual void adj_accessors_insert_rows(std::size_t row_ndx,
                                           std::size_t num_rows) TIGHTDB_NOEXCEPT;
    virtual void adj_accessors_erase_row(std::size_t row_ndx) TIGHTDB_NOEXCEPT;

    // This function assumes that a row has moved from \a origin_ndx to \a target_ndx,
    // and it updates the column accessor, and all its subordinate accessors (subtables, rows)
    // accordingly.
    // Subordinate accessors that are already associated with \a target_ndx will be detached.
    // Link-adjacent table accessors will be marked (dirty).
    //
    // It is used as part of Table::refresh_accessor_tree() to bring the state of the accessors
    // from Minimal Consistency into Structural Correspondence, so it must be able to execute
    // without accessing the underlying array nodes.
    virtual void adj_accessors_move(std::size_t target_row_ndx,
                                    std::size_t source_row_ndx) TIGHTDB_NOEXCEPT;
    virtual void adj_acc_clear_root_table() TIGHTDB_NOEXCEPT;

    enum {
        mark_Recursive   = 0x01,
        mark_LinkTargets = 0x02,
        mark_LinkOrigins = 0x04
    };

    virtual void mark(int type) TIGHTDB_NOEXCEPT;

    virtual void bump_link_origin_table_version() TIGHTDB_NOEXCEPT;

    /// Refresh the dirty part of the accessor subtree rooted at this column
    /// accessor.
    ///
    /// The following conditions are necessary and sufficient for the proper
    /// operation of this function:
    ///
    ///  - The parent table accessor (excluding its column accessors) is in a
    ///    valid state (already refreshed).
    ///
    ///  - Every subtable accessor in the subtree is marked dirty if it needs to
    ///    be refreshed, or if it has a descendant accessor that needs to be
    ///    refreshed.
    ///
    ///  - This column accessor, as well as all its descendant accessors, are in
    ///    structural correspondence with the underlying node hierarchy whose
    ///    root ref is stored in the parent (`Table::m_columns`) (see
    ///    AccessorConsistencyLevels).
    ///
    ///  - The 'index in parent' property of the cached root array
    ///    (`m_array->m_ndx_in_parent`) is valid.
    virtual void refresh_accessor_tree(std::size_t new_col_ndx, const Spec&) = 0;

#ifdef TIGHTDB_DEBUG
    // Must be upper case to avoid conflict with macro in Objective-C
    virtual void Verify() const = 0;
    virtual void Verify(const Table&, std::size_t col_ndx) const;
    virtual void to_dot(std::ostream&, StringData title = StringData()) const = 0;
    void dump_node_structure() const; // To std::cerr (for GDB)
    virtual void do_dump_node_structure(std::ostream&, int level) const = 0;
#endif

protected:
    // FIXME: This should not be mutable, the problem is again the
    // const-violating moving copy constructor.
    mutable Array* m_array;

    ColumnBase(Array* root = 0) TIGHTDB_NOEXCEPT;

    virtual std::size_t do_get_size() const TIGHTDB_NOEXCEPT = 0;

    // Must not assume more than minimal consistency (see
    // AccessorConsistencyLevels).
    virtual void do_discard_child_accessors() TIGHTDB_NOEXCEPT {}

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
    R aggregate(T target, std::size_t start, std::size_t end, size_t limit = size_t(-1),
                size_t* return_ndx = null_ptr) const;

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

    static ref_type create(Allocator&, std::size_t size, CreateHandler&);

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
    void replace_root(Array* leaf); // Ownership passed
private:
    ColumnBase& m_column;
};



/// An integer column (Column) is a single B+-tree, and the root of
/// the column is the root of the B+-tree. All leaf nodes are single
/// arrays of type Array.
///
/// FIXME: Rename Column to IntegerColumn.
class Column: public ColumnBase, public ColumnTemplate<int64_t> {
public:
    typedef int64_t value_type;

    int64_t get_val(size_t row) const { return get(row); }

    Column(Allocator&, ref_type);
    inline bool has_search_index() const TIGHTDB_NOEXCEPT;
    struct unattached_root_tag {};
    Column(unattached_root_tag, Allocator&);

    struct move_tag {};
    Column(move_tag, Column&) TIGHTDB_NOEXCEPT;

    ~Column() TIGHTDB_NOEXCEPT TIGHTDB_OVERRIDE;
    void destroy() TIGHTDB_NOEXCEPT;
    void move_assign(Column&);
    bool IsIntColumn() const TIGHTDB_NOEXCEPT { return true; }

    std::size_t size() const TIGHTDB_NOEXCEPT;
    bool is_empty() const TIGHTDB_NOEXCEPT { return size() == 0; }

    // Getting and setting values
    int_fast64_t get(std::size_t ndx) const TIGHTDB_NOEXCEPT;
    ref_type get_as_ref(std::size_t ndx) const TIGHTDB_NOEXCEPT;
    int_fast64_t back() const TIGHTDB_NOEXCEPT { return get(size()-1); }
    void set(std::size_t ndx, int_fast64_t value);
    void adjust(std::size_t ndx, int_fast64_t diff);
    void add(int_fast64_t value = 0);
    void insert(std::size_t ndx, int_fast64_t value = 0);

    std::size_t count(int64_t target) const;
    int64_t sum(std::size_t start = 0, std::size_t end = -1, size_t limit = size_t(-1),
                size_t* return_ndx = null_ptr) const;

    int64_t maximum(std::size_t start = 0, std::size_t end = -1, size_t limit = size_t(-1),
                    size_t* return_ndx = null_ptr) const;

    int64_t minimum(std::size_t start = 0, std::size_t end = -1, size_t limit = size_t(-1),
                    size_t* return_ndx = null_ptr) const;

    double  average(std::size_t start = 0, std::size_t end = -1, size_t limit = size_t(-1),
                    size_t* return_ndx = null_ptr) const;

    /// If any element points to an array node, this function recursively
    /// destroys that array node. Note that the same is **not** true for
    /// Column::erase() and Column::move_last_over().
    ///
    /// FIXME: Be careful, clear() currently forgets if the leaf type is
    /// Array::type_HasRefs.
    void clear() TIGHTDB_OVERRIDE;

    void insert(std::size_t, std::size_t, bool) TIGHTDB_OVERRIDE;
    void erase(std::size_t ndx, bool is_last) TIGHTDB_OVERRIDE;
    void move_last_over(std::size_t, std::size_t) TIGHTDB_OVERRIDE;
    void destroy_subtree(size_t ndx, bool clear_value);

    void adjust(int_fast64_t diff);
    void adjust_ge(int_fast64_t limit, int_fast64_t diff);

    size_t find_first(int64_t value, std::size_t begin = 0, std::size_t end = npos) const;
    void find_all(Column& result, int64_t value,
                  std::size_t begin = 0, std::size_t end = npos) const;

    void set_search_index_ref(ref_type ref, ArrayParent* parent, size_t ndx_in_parent, bool allow_duplicate_valaues);
    void create_search_index();
    void* get_search_index() TIGHTDB_NOEXCEPT;

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
    bool compare_int(const Column&) const TIGHTDB_NOEXCEPT;

    static ref_type create(Allocator&, Array::Type leaf_type = Array::type_Normal,
                           std::size_t size = 0, int_fast64_t value = 0);

    // Overrriding method in ColumnBase
    ref_type write(std::size_t, std::size_t, std::size_t,
                   _impl::OutputStream&) const TIGHTDB_OVERRIDE;

    /// \param row_ndx Must be `tightdb::npos` if appending.
    void do_insert(std::size_t row_ndx, int_fast64_t value, std::size_t num_rows);

    void refresh_accessor_tree(std::size_t, const Spec&) TIGHTDB_OVERRIDE;

#ifdef TIGHTDB_DEBUG
    void Verify() const TIGHTDB_OVERRIDE;
    using ColumnBase::Verify;
    void to_dot(std::ostream&, StringData title) const TIGHTDB_OVERRIDE;
    MemStats stats() const;
    void do_dump_node_structure(std::ostream&, int) const TIGHTDB_OVERRIDE;
#endif

    // todo, make private, and correct type
    void* m_search_index;

protected:
    Column(Array* root = 0) TIGHTDB_NOEXCEPT;

    std::size_t do_get_size() const TIGHTDB_NOEXCEPT TIGHTDB_OVERRIDE { return size(); }

#ifdef TIGHTDB_DEBUG
    void leaf_to_dot(MemRef, ArrayParent*, std::size_t ndx_in_parent,
                     std::ostream&) const TIGHTDB_OVERRIDE;
    static void dump_node_structure(const Array& root, std::ostream&, int level);
#endif

private:
    Column(const Column&); // not allowed
    Column &operator=(const Column&); // not allowed

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

inline std::size_t ColumnBase::size() const TIGHTDB_NOEXCEPT
{
    return do_get_size();
}

inline ColumnBase::ColumnBase(Array* root) TIGHTDB_NOEXCEPT:
    m_array(root)
{
}

inline void ColumnBase::detach()
{
    m_array->detach();
}

inline bool ColumnBase::is_attached() const TIGHTDB_NOEXCEPT
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

inline bool ColumnBase::has_search_index() const TIGHTDB_NOEXCEPT
{
    return false;
}

inline void ColumnBase::set_search_index_ref(ref_type, ArrayParent*, std::size_t, bool)
{
}

inline void ColumnBase::set_search_index_allow_duplicate_values(bool) TIGHTDB_NOEXCEPT
{
}

inline void ColumnBase::discard_child_accessors() TIGHTDB_NOEXCEPT
{
    do_discard_child_accessors();
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

inline void ColumnBase::adj_accessors_move(std::size_t, std::size_t) TIGHTDB_NOEXCEPT
{
    // Noop
}

inline void ColumnBase::adj_acc_clear_root_table() TIGHTDB_NOEXCEPT
{
    // Noop
}

inline void ColumnBase::mark(int) TIGHTDB_NOEXCEPT
{
    // Noop
}

inline void ColumnBase::bump_link_origin_table_version() TIGHTDB_NOEXCEPT
{
    // Noop
}

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

inline void ColumnBase::EraseHandlerBase::replace_root(Array* leaf)
{
    util::UniquePtr<Array> leaf_2(leaf);
    ArrayParent* parent = m_column.m_array->get_parent();
    std::size_t ndx_in_parent = m_column.m_array->get_ndx_in_parent();
    leaf_2->set_parent(parent, ndx_in_parent);
    leaf_2->update_parent(); // Throws
    delete m_column.m_array;
    m_column.m_array = leaf_2.release();
}

inline ref_type ColumnBase::create(Allocator& alloc, std::size_t size, CreateHandler& handler)
{
    std::size_t rest_size = size;
    std::size_t fixed_height = 0; // Not fixed
    return build(&rest_size, fixed_height, alloc, handler);
}

inline bool Column::has_search_index() const TIGHTDB_NOEXCEPT
{
    return m_search_index;
}

// fixme, must m_search_index be copied here?
inline Column::Column(Allocator& alloc, ref_type ref) : m_search_index(null_ptr)
{
    m_array = new Array(alloc); // Throws
    m_array->init_from_ref(ref);
}

inline Column::Column(unattached_root_tag, Allocator& alloc) : m_search_index(null_ptr)
{
    m_array = new Array(alloc); // Throws

}

inline Column::Column(move_tag, Column& col) TIGHTDB_NOEXCEPT
{
    m_array = col.m_array;
    col.m_array = 0;
    m_search_index = col.m_search_index;
    col.m_search_index = 0;
}

inline Column::Column(Array* root) TIGHTDB_NOEXCEPT:
    ColumnBase(root), m_search_index(null_ptr)
{
}

inline std::size_t Column::size() const TIGHTDB_NOEXCEPT
{
    if (root_is_leaf())
        return m_array->size();
    return m_array->get_bptree_size();
}

inline int_fast64_t Column::get(std::size_t ndx) const TIGHTDB_NOEXCEPT
{
    TIGHTDB_ASSERT(ndx < size());
    if (!m_array->is_inner_bptree_node())
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

inline void Column::add(int_fast64_t value)
{
    std::size_t row_ndx = tightdb::npos;
    std::size_t num_rows = 1;
    do_insert(row_ndx, value, num_rows); // Throws
}

inline void Column::insert(std::size_t row_ndx, int_fast64_t value)
{
    std::size_t size = this->size(); // Slow
    TIGHTDB_ASSERT(row_ndx <= size);
    std::size_t row_ndx_2 = row_ndx == size ? tightdb::npos : row_ndx;
    std::size_t num_rows = 1;
    do_insert(row_ndx_2, value, num_rows); // Throws
}

// Implementing pure virtual method of ColumnBase.
inline void Column::insert(std::size_t row_ndx, std::size_t num_rows, bool is_append)
{
    std::size_t row_ndx_2 = is_append ? tightdb::npos : row_ndx;
    int_fast64_t value = 0;
    do_insert(row_ndx_2, value, num_rows); // Throws
}

TIGHTDB_FORCEINLINE
ref_type Column::leaf_insert(MemRef leaf_mem, ArrayParent& parent, std::size_t ndx_in_parent,
                             Allocator& alloc, std::size_t insert_ndx,
                             Array::TreeInsert<Column>& state)
{
    Array leaf(alloc);
    leaf.init_from_mem(leaf_mem);
    leaf.set_parent(&parent, ndx_in_parent);
    return leaf.bptree_leaf_insert(insert_ndx, state.m_value, state); // Throws
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
#include <tightdb/column_tpl.hpp>

#endif // TIGHTDB_COLUMN_HPP
