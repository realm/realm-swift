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
#ifndef TIGHTDB_COLUMN_STRING_ENUM_HPP
#define TIGHTDB_COLUMN_STRING_ENUM_HPP

#include <RealmCore/tightdb/column_string.hpp>

namespace tightdb {

// Pre-declarations
class StringIndex;


/// From the point of view of the application, an enumerated strings column
/// (ColumnStringEnum) is like a string column (AdaptiveStringColumn), yet it
/// manages its stings in such a way that each unique string is stored only
/// once. In fact, an enumerated strings column is a combination of two
/// subcolumns; a regular string column (AdaptiveStringColumn) that stores the
/// unique strings, and an integer column that stores one unique string index
/// for each entry in the enumerated strings column.
///
/// In terms of the underlying node structure, the subcolumn containing the
/// unique strings is not a true part of the enumerated strings column. Instead
/// it is a part of the spec structure that describes the table of which the
/// enumerated strings column is a part. This way, the unique strings can be
/// shared across enumerated strings columns of multiple subtables. This also
/// means that the root of an enumerated strings column coincides with the root
/// of the integer subcolumn, and in some sense, an enumerated strings column is
/// just the integer subcolumn.
///
/// An enumerated strings column can optionally be equipped with a
/// search index. If it is, then the root ref of the index is stored
/// in Table::m_columns immediately after the root ref of the
/// enumerated strings column.
class ColumnStringEnum: public Column {
public:
    typedef StringData value_type;

    ColumnStringEnum(ref_type keys, ref_type values, ArrayParent* values_parent = 0,
                     std::size_t values_ndx_in_parent = 0, ArrayParent* keys_parent = 0,
                     std::size_t keys_ndx_in_parent = 0, Allocator& = Allocator::get_default());
    ~ColumnStringEnum() TIGHTDB_NOEXCEPT TIGHTDB_OVERRIDE;
    void destroy() TIGHTDB_NOEXCEPT TIGHTDB_OVERRIDE;

    StringData get(std::size_t ndx) const TIGHTDB_NOEXCEPT;
    void add(StringData value);
    void set(std::size_t ndx, StringData value);
    void insert(std::size_t ndx, StringData value);
    void erase(std::size_t ndx, bool is_last) TIGHTDB_OVERRIDE;
    void clear() TIGHTDB_OVERRIDE;

    using Column::move_last_over;
    using Column::add;
    using Column::insert;

    std::size_t count(StringData value) const;
    size_t find_first(StringData value, std::size_t begin = 0, std::size_t end = npos) const;
    void find_all(Column& res, StringData value,
                  std::size_t begin = 0, std::size_t end = npos) const;
    FindRes find_all_indexref(StringData value, std::size_t& dst) const;

    std::size_t count(std::size_t key_index) const;
    std::size_t find_first(std::size_t key_index, std::size_t begin=0, std::size_t end=-1) const;
    void find_all(Column& res, std::size_t key_index, std::size_t begin = 0, std::size_t end = -1) const;

    //@{
    /// Find the lower/upper bound for the specified value assuming
    /// that the elements are already sorted in ascending order
    /// according to StringData::operator<().
    std::size_t lower_bound_string(StringData value) const TIGHTDB_NOEXCEPT;
    std::size_t upper_bound_string(StringData value) const TIGHTDB_NOEXCEPT;
    //@}

    void adjust_keys_ndx_in_parent(int diff) TIGHTDB_NOEXCEPT;
    void update_from_parent(std::size_t old_baseline) TIGHTDB_NOEXCEPT TIGHTDB_OVERRIDE;

    // Index
    bool has_index() const TIGHTDB_NOEXCEPT TIGHTDB_OVERRIDE;
    void set_index_ref(ref_type, ArrayParent*, std::size_t ndx_in_parent) TIGHTDB_OVERRIDE;
    const StringIndex& get_index() const TIGHTDB_NOEXCEPT;
    StringIndex& create_index();
    void install_index(StringIndex*) TIGHTDB_NOEXCEPT;

    // Compare two string columns for equality
    bool compare_string(const AdaptiveStringColumn&) const;
    bool compare_string(const ColumnStringEnum&) const;

    const Array* get_enum_root_array() const TIGHTDB_NOEXCEPT;

    void update_column_index(std::size_t, const Spec&) TIGHTDB_NOEXCEPT TIGHTDB_OVERRIDE;

#ifdef TIGHTDB_ENABLE_REPLICATION
    void refresh_after_advance_transact(std::size_t, const Spec&) TIGHTDB_OVERRIDE;
#endif

#ifdef TIGHTDB_DEBUG
    void Verify() const TIGHTDB_OVERRIDE; // Must be upper case to avoid conflict with macro in ObjC
    void to_dot(std::ostream&, StringData title) const TIGHTDB_OVERRIDE;
    void dump_node_structure(std::ostream&, int level) const TIGHTDB_OVERRIDE;
    using Column::dump_node_structure;
#endif

    std::size_t GetKeyNdx(StringData value) const;
    std::size_t GetKeyNdxOrAdd(StringData value);

    const AdaptiveStringColumn& get_keys() const;

private:
    // Member variables
    AdaptiveStringColumn m_keys;
    StringIndex* m_index;
};





// Implementation:

inline StringData ColumnStringEnum::get(std::size_t ndx) const TIGHTDB_NOEXCEPT
{
    TIGHTDB_ASSERT(ndx < Column::size());
    std::size_t key_ndx = to_size_t(Column::get(ndx));
    return m_keys.get(key_ndx);
}


inline std::size_t ColumnStringEnum::lower_bound_string(StringData value) const TIGHTDB_NOEXCEPT
{
    return ColumnBase::lower_bound(*this, value);
}

inline std::size_t ColumnStringEnum::upper_bound_string(StringData value) const TIGHTDB_NOEXCEPT
{
    return ColumnBase::upper_bound(*this, value);
}

inline bool ColumnStringEnum::has_index() const TIGHTDB_NOEXCEPT
{
    return m_index != 0;
}

inline const StringIndex& ColumnStringEnum::get_index() const TIGHTDB_NOEXCEPT
{
    return *m_index;
}

inline const Array* ColumnStringEnum::get_enum_root_array() const TIGHTDB_NOEXCEPT
{
    return m_keys.get_root_array();
}

inline const AdaptiveStringColumn& ColumnStringEnum::get_keys() const
{
    return m_keys;
}


} // namespace tightdb

#endif // TIGHTDB_COLUMN_STRING_ENUM_HPP
