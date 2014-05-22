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

class ColumnStringEnum: public Column {
public:
    typedef StringData value_type;

    ColumnStringEnum(ref_type keys, ref_type values, ArrayParent* column_parent = 0,
                     size_t column_ndx_in_parent = 0, ArrayParent* keys_parent = 0,
                     size_t keys_ndx_in_parent = 0, Allocator& = Allocator::get_default());
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
    void find_all(Array& res, StringData value,
                  std::size_t begin = 0, std::size_t end = npos) const;
    FindRes find_all_indexref(StringData value, std::size_t& dst) const;

    std::size_t count(std::size_t key_index) const;
    std::size_t find_first(std::size_t key_index, std::size_t begin=0, std::size_t end=-1) const;
    void find_all(Array& res, std::size_t key_index, std::size_t begin=0, std::size_t end=-1) const;

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
    bool has_index() const TIGHTDB_NOEXCEPT TIGHTDB_OVERRIDE { return m_index != 0; }
    void set_index_ref(ref_type, ArrayParent*, std::size_t ndx_in_parent) TIGHTDB_OVERRIDE;
    const StringIndex& get_index() const { return *m_index; }
    StringIndex& create_index();
    void install_index(StringIndex*) TIGHTDB_NOEXCEPT;

    // Compare two string columns for equality
    bool compare_string(const AdaptiveStringColumn&) const;
    bool compare_string(const ColumnStringEnum&) const;

    const Array* get_enum_root_array() const TIGHTDB_NOEXCEPT { return m_keys.get_root_array(); }

#ifdef TIGHTDB_DEBUG
    void Verify() const TIGHTDB_OVERRIDE; // Must be upper case to avoid conflict with macro in ObjC
    void to_dot(std::ostream&, StringData title) const TIGHTDB_OVERRIDE;
    void dump_node_structure(std::ostream&, int level) const TIGHTDB_OVERRIDE;
    using Column::dump_node_structure;
#endif

    std::size_t GetKeyNdx(StringData value) const;
    std::size_t GetKeyNdxOrAdd(StringData value);

    const AdaptiveStringColumn& get_keys() const {return m_keys;}

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


} // namespace tightdb

#endif // TIGHTDB_COLUMN_STRING_ENUM_HPP
