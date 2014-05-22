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

#include <RealmCore/tightdb/util/unique_ptr.hpp>
#include <RealmCore/tightdb/array_string.hpp>
#include <RealmCore/tightdb/array_string_long.hpp>
#include <RealmCore/tightdb/array_blobs_big.hpp>
#include <RealmCore/tightdb/column.hpp>

namespace tightdb {

// Pre-declarations
class StringIndex;

class AdaptiveStringColumn: public ColumnBase {
public:
    typedef StringData value_type;

    explicit AdaptiveStringColumn(Allocator& = Allocator::get_default());
    explicit AdaptiveStringColumn(ref_type, ArrayParent* = 0, std::size_t ndx_in_parent = 0,
                                  Allocator& = Allocator::get_default());
    ~AdaptiveStringColumn() TIGHTDB_NOEXCEPT TIGHTDB_OVERRIDE;

    void destroy() TIGHTDB_NOEXCEPT TIGHTDB_OVERRIDE;

    std::size_t size() const TIGHTDB_NOEXCEPT;
    bool is_empty() const TIGHTDB_NOEXCEPT { return size() == 0; }

    StringData get(std::size_t ndx) const TIGHTDB_NOEXCEPT;
    void add() TIGHTDB_OVERRIDE { return add(StringData()); }
    void add(StringData);
    void set(std::size_t ndx, StringData);
    void insert(std::size_t ndx) TIGHTDB_OVERRIDE { insert(ndx, StringData()); }
    void insert(std::size_t ndx, StringData);
    void erase(std::size_t ndx, bool is_last) TIGHTDB_OVERRIDE;
    void clear() TIGHTDB_OVERRIDE;
    void move_last_over(std::size_t ndx) TIGHTDB_OVERRIDE;

    std::size_t count(StringData value) const;
    std::size_t find_first(StringData value, std::size_t begin = 0,
                           std::size_t end = npos) const;
    void find_all(Array& result, StringData value, std::size_t begin = 0,
                  std::size_t end = npos) const;

    //@{
    /// Find the lower/upper bound for the specified value assuming
    /// that the elements are already sorted in ascending order
    /// according to StringData::operator<().
    std::size_t lower_bound_string(StringData value) const TIGHTDB_NOEXCEPT;
    std::size_t upper_bound_string(StringData value) const TIGHTDB_NOEXCEPT;
    //@}

    FindRes find_all_indexref(StringData value, std::size_t& dst) const;

    // Index
    bool has_index() const TIGHTDB_NOEXCEPT TIGHTDB_OVERRIDE { return m_index != 0; }
    void set_index_ref(ref_type, ArrayParent*, std::size_t ndx_in_parent) TIGHTDB_OVERRIDE;
    const StringIndex& get_index() const { return *m_index; }
    StringIndex* release_index() TIGHTDB_NOEXCEPT;
    StringIndex& create_index();

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

    static ref_type create(std::size_t size, Allocator&);

    static std::size_t get_size_from_ref(ref_type root_ref, Allocator&) TIGHTDB_NOEXCEPT;

    // Overrriding method in ColumnBase
    ref_type write(std::size_t, std::size_t, std::size_t,
                   _impl::OutputStream&) const TIGHTDB_OVERRIDE;

    void update_from_parent(std::size_t old_baseline) TIGHTDB_NOEXCEPT TIGHTDB_OVERRIDE;
#ifdef TIGHTDB_DEBUG
    void Verify() const TIGHTDB_OVERRIDE;
    void to_dot(std::ostream&, StringData title) const TIGHTDB_OVERRIDE;
    void dump_node_structure(std::ostream&, int level) const TIGHTDB_OVERRIDE;
    using ColumnBase::dump_node_structure;
#endif

private:
    StringIndex* m_index;

    std::size_t do_get_size() const TIGHTDB_NOEXCEPT TIGHTDB_OVERRIDE { return size(); }

    void do_insert(std::size_t ndx, StringData value);

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
    do_insert(npos, value);
}

inline void AdaptiveStringColumn::insert(size_t ndx, StringData value)
{
    TIGHTDB_ASSERT(ndx <= size());
    if (size() <= ndx)
        ndx = npos;
    do_insert(ndx, value);
}

inline StringIndex* AdaptiveStringColumn::release_index() TIGHTDB_NOEXCEPT
{
    StringIndex* i = m_index;
    m_index = 0;
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

inline void AdaptiveStringColumn::update_from_parent(std::size_t old_baseline) TIGHTDB_NOEXCEPT
{
    if (root_is_leaf()) {
        bool long_strings = m_array->has_refs();
        if (!long_strings) {
            // Small strings root leaf
            ArrayString* leaf = static_cast<ArrayString*>(m_array);
            leaf->update_from_parent(old_baseline);
            return;
        }
        bool is_big = m_array->get_context_flag();
        if (!is_big) {
            // Medium strings root leaf
            ArrayStringLong* leaf = static_cast<ArrayStringLong*>(m_array);
            leaf->update_from_parent(old_baseline);
            return;
        }
        // Big strings root leaf
        ArrayBigBlobs* leaf = static_cast<ArrayBigBlobs*>(m_array);
        leaf->update_from_parent(old_baseline);
        return;
    }
    // Non-leaf root
    m_array->update_from_parent(old_baseline);
}

} // namespace tightdb

#endif // TIGHTDB_COLUMN_STRING_HPP
