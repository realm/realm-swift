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
#ifndef TIGHTDB_COLUMN_STRING_HPP
#define TIGHTDB_COLUMN_STRING_HPP

#include <tightdb/util/unique_ptr.hpp>
#include <tightdb/array_string.hpp>
#include <tightdb/array_string_long.hpp>
#include <tightdb/array_blobs_big.hpp>
#include <tightdb/column.hpp>

namespace tightdb {

// Pre-declarations
class StringIndex;


/// A string column (AdaptiveStringColumn) is a single B+-tree, and
/// the root of the column is the root of the B+-tree. Leaf nodes are
/// either of type ArrayString (array of small strings),
/// ArrayStringLong (array of medium strings), or ArrayBigBlobs (array
/// of big strings).
///
/// A string column can optionally be equipped with a search index. If
/// it is, then the root ref of the index is stored in
/// Table::m_columns immediately after the root ref of the string
/// column.
///
/// FIXME: Rename AdaptiveStringColumn to StringColumn
class AdaptiveStringColumn: public ColumnBase, public ColumnTemplate<StringData> {
public:
    typedef StringData value_type;

    AdaptiveStringColumn(Allocator&, ref_type);
    ~AdaptiveStringColumn() TIGHTDB_NOEXCEPT TIGHTDB_OVERRIDE;

    void destroy() TIGHTDB_NOEXCEPT TIGHTDB_OVERRIDE;

    std::size_t size() const TIGHTDB_NOEXCEPT;
    bool is_empty() const TIGHTDB_NOEXCEPT { return size() == 0; }

    StringData get(std::size_t ndx) const TIGHTDB_NOEXCEPT;
    void set(std::size_t ndx, StringData);
    void add(StringData value = StringData());
    void insert(std::size_t ndx, StringData value = StringData());

    void insert(std::size_t, std::size_t, bool) TIGHTDB_OVERRIDE;
    void erase(std::size_t ndx, bool is_last) TIGHTDB_OVERRIDE;
    void move_last_over(std::size_t, std::size_t) TIGHTDB_OVERRIDE;
    void clear() TIGHTDB_OVERRIDE;

    std::size_t count(StringData value) const;
    std::size_t find_first(StringData value, std::size_t begin = 0,
                           std::size_t end = npos) const;
    void find_all(Column& result, StringData value, std::size_t begin = 0,
                  std::size_t end = npos) const;

    int compare_values(std::size_t, std::size_t) const TIGHTDB_OVERRIDE;

    //@{
    /// Find the lower/upper bound for the specified value assuming
    /// that the elements are already sorted in ascending order
    /// according to StringData::operator<().
    std::size_t lower_bound_string(StringData value) const TIGHTDB_NOEXCEPT;
    std::size_t upper_bound_string(StringData value) const TIGHTDB_NOEXCEPT;
    //@}

    void set_string(std::size_t, StringData) TIGHTDB_OVERRIDE;

    FindRes find_all_indexref(StringData value, std::size_t& dst) const;

    // Search index
    bool has_search_index() const TIGHTDB_NOEXCEPT TIGHTDB_OVERRIDE;
    void set_search_index_ref(ref_type, ArrayParent*, std::size_t, bool) TIGHTDB_OVERRIDE;
    void set_search_index_allow_duplicate_values(bool) TIGHTDB_NOEXCEPT TIGHTDB_OVERRIDE;
    StringIndex& get_search_index() TIGHTDB_NOEXCEPT;
    const StringIndex& get_search_index() const TIGHTDB_NOEXCEPT;
    StringIndex* release_search_index() TIGHTDB_NOEXCEPT;
    StringIndex& create_search_index();

    // Optimizing data layout
    bool auto_enumerate(ref_type& keys, ref_type& values) const;

    /// Compare two string columns for equality.
    bool compare_string(const AdaptiveStringColumn&) const;

    enum LeafType {
        leaf_type_Small,  ///< ArrayString
        leaf_type_Medium, ///< ArrayStringLong
        leaf_type_Big     ///< ArrayBigBlobs
    };

    LeafType GetBlock(std::size_t ndx, ArrayParent**, std::size_t& off,
                      bool use_retval = false) const;

    static ref_type create(Allocator&, std::size_t size = 0);

    static std::size_t get_size_from_ref(ref_type root_ref, Allocator&) TIGHTDB_NOEXCEPT;

    // Overrriding method in ColumnBase
    ref_type write(std::size_t, std::size_t, std::size_t,
                   _impl::OutputStream&) const TIGHTDB_OVERRIDE;

    void update_from_parent(std::size_t old_baseline) TIGHTDB_NOEXCEPT TIGHTDB_OVERRIDE;

    bool is_string_col() const TIGHTDB_NOEXCEPT TIGHTDB_OVERRIDE;

    void refresh_accessor_tree(std::size_t, const Spec&) TIGHTDB_OVERRIDE;

#ifdef TIGHTDB_DEBUG
    void Verify() const TIGHTDB_OVERRIDE;
    void Verify(const Table&, std::size_t) const TIGHTDB_OVERRIDE;
    void to_dot(std::ostream&, StringData title) const TIGHTDB_OVERRIDE;
    void do_dump_node_structure(std::ostream&, int) const TIGHTDB_OVERRIDE;
#endif

protected:
    StringData get_val(std::size_t row) const { return get(row); }

private:
    StringIndex* m_search_index;

    std::size_t do_get_size() const TIGHTDB_NOEXCEPT TIGHTDB_OVERRIDE { return size(); }

    /// If you are appending and have the size of the column readily available,
    /// call the 4 argument version instead. If you are not appending, either
    /// one is fine.
    ///
    /// \param row_ndx Must be `tightdb::npos` if appending.
    void do_insert(std::size_t row_ndx, StringData value, std::size_t num_rows);

    /// If you are appending and you do not have the size of the column readily
    /// available, call the 3 argument version instead. If you are not
    /// appending, either one is fine.
    ///
    /// \param is_append Must be true if, and only if `row_ndx` is equal to the
    /// size of the column (before insertion).
    void do_insert(std::size_t row_ndx, StringData value, std::size_t num_rows, bool is_append);

    /// \param row_ndx Must be `tightdb::npos` if appending.
    void bptree_insert(std::size_t row_ndx, StringData value, std::size_t num_rows);

    // Called by Array::bptree_insert().
    static ref_type leaf_insert(MemRef leaf_mem, ArrayParent&, std::size_t ndx_in_parent,
                                Allocator&, std::size_t insert_ndx,
                                Array::TreeInsert<AdaptiveStringColumn>& state);

    class EraseLeafElem;
    class CreateHandler;
    class SliceHandler;

    /// Root must be a leaf. Upgrades the root leaf as
    /// necessary. Returns the type of the root leaf as it is upon
    /// return.
    LeafType upgrade_root_leaf(std::size_t value_size);

    void refresh_root_accessor();

#ifdef TIGHTDB_DEBUG
    void leaf_to_dot(MemRef, ArrayParent*, std::size_t ndx_in_parent,
                     std::ostream&) const TIGHTDB_OVERRIDE;
#endif

    friend class Array;
    friend class ColumnBase;
};





// Implementation:

inline std::size_t AdaptiveStringColumn::size() const TIGHTDB_NOEXCEPT
{
    if (root_is_leaf()) {
        bool long_strings = m_array->has_refs();
        if (!long_strings) {
            // Small strings root leaf
            ArrayString* leaf = static_cast<ArrayString*>(m_array);
            return leaf->size();
        }
        bool is_big = m_array->get_context_flag();
        if (!is_big) {
            // Medium strings root leaf
            ArrayStringLong* leaf = static_cast<ArrayStringLong*>(m_array);
            return leaf->size();
        }
        // Big strings root leaf
        ArrayBigBlobs* leaf = static_cast<ArrayBigBlobs*>(m_array);
        return leaf->size();
    }
    // Non-leaf root
    return m_array->get_bptree_size();
}

inline void AdaptiveStringColumn::add(StringData value)
{
    std::size_t row_ndx = tightdb::npos;
    std::size_t num_rows = 1;
    do_insert(row_ndx, value, num_rows); // Throws
}

inline void AdaptiveStringColumn::insert(std::size_t row_ndx, StringData value)
{
    std::size_t size = this->size();
    TIGHTDB_ASSERT(row_ndx <= size);
    std::size_t num_rows = 1;
    bool is_append = row_ndx == size;
    do_insert(row_ndx, value, num_rows, is_append); // Throws
}

// Implementing pure virtual method of ColumnBase.
inline void AdaptiveStringColumn::insert(std::size_t row_ndx, std::size_t num_rows, bool is_append)
{
    StringData value = StringData();
    do_insert(row_ndx, value, num_rows, is_append); // Throws
}

inline int AdaptiveStringColumn::compare_values(std::size_t row1, std::size_t row2) const
{
    StringData a = get(row1);
    StringData b = get(row2);
    if (a == b)
        return 0;
    return utf8_compare(a, b) ? 1 : -1;
}

inline void AdaptiveStringColumn::set_string(std::size_t row_ndx, StringData value)
{
    set(row_ndx, value); // Throws
}

inline bool AdaptiveStringColumn::has_search_index() const TIGHTDB_NOEXCEPT
{
    return m_search_index != 0;
}

inline StringIndex& AdaptiveStringColumn::get_search_index() TIGHTDB_NOEXCEPT
{
    return *m_search_index;
}

inline const StringIndex& AdaptiveStringColumn::get_search_index() const TIGHTDB_NOEXCEPT
{
    return *m_search_index;
}

inline StringIndex* AdaptiveStringColumn::release_search_index() TIGHTDB_NOEXCEPT
{
    StringIndex* i = m_search_index;
    m_search_index = 0;
    return i;
}

inline std::size_t AdaptiveStringColumn::get_size_from_ref(ref_type root_ref,
                                                           Allocator& alloc) TIGHTDB_NOEXCEPT
{
    const char* root_header = alloc.translate(root_ref);
    bool root_is_leaf = !Array::get_is_inner_bptree_node_from_header(root_header);
    if (root_is_leaf) {
        bool long_strings = Array::get_hasrefs_from_header(root_header);
        if (!long_strings) {
            // Small strings leaf
            return ArrayString::get_size_from_header(root_header);
        }
        bool is_big = Array::get_context_flag_from_header(root_header);
        if (!is_big) {
            // Medium strings leaf
            return ArrayStringLong::get_size_from_header(root_header, alloc);
        }
        // Big strings leaf
        return ArrayBigBlobs::get_size_from_header(root_header);
    }
    return Array::get_bptree_size_from_header(root_header);
}

inline bool AdaptiveStringColumn::is_string_col() const TIGHTDB_NOEXCEPT
{
    return true;
}

} // namespace tightdb

#endif // TIGHTDB_COLUMN_STRING_HPP
