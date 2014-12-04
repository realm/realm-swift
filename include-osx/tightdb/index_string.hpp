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
#ifndef TIGHTDB_INDEX_STRING_HPP
#define TIGHTDB_INDEX_STRING_HPP

#include <iostream>

#include <tightdb/column.hpp>
#include <tightdb/column_string.hpp>

namespace tightdb {

// to_str() is used by the integer index. The existing StringIndex is re-used for this
// by making Column convert its integers to strings by calling to_str().
template <class T> inline StringData to_str(T& value)
{
    TIGHTDB_STATIC_ASSERT((util::SameType<T, int64_t>::value), "");
    const char* c = reinterpret_cast<const char*>(&value);
    return StringData(c, sizeof(T));
}

inline StringData to_str(StringData& input)
{
    return input;
}

inline StringData to_str(const char* value)
{
    return StringData(value);
}

typedef StringData (*StringGetter)(void*, std::size_t, char*);

class StringIndex: public Column {
public:
    StringIndex(void* target_column, StringGetter get_func, Allocator&);
    StringIndex(ref_type, ArrayParent*, std::size_t ndx_in_parent, void* target_column,
                StringGetter get_func, bool allow_duplicate_values, Allocator&);
    ~StringIndex() TIGHTDB_NOEXCEPT TIGHTDB_OVERRIDE {}
    void set_target(void* target_column, StringGetter get_func) TIGHTDB_NOEXCEPT;

    bool is_empty() const;

    template <class T> void insert(size_t row_ndx, T value, size_t num_rows, bool is_append);
    template <class T> void set(size_t row_ndx, T new_value);
    template <class T> void erase(size_t row_ndx, bool is_last);

    template <class T> size_t find_first(T value) const
    {
        // Use direct access method
        return m_array->IndexStringFindFirst(to_str(value), m_target_column, m_get_func);
    }

    template <class T> void find_all(Column& result, T value) const
    {
        // Use direct access method
        return m_array->IndexStringFindAll(result, to_str(value), m_target_column, m_get_func);
    }

    template <class T> FindRes find_all(T value, size_t& ref) const
    {
        // Use direct access method
        return m_array->IndexStringFindAllNoCopy(to_str(value), ref, m_target_column, m_get_func);
    }

    template <class T> size_t count(T value) const
    {
        // Use direct access method
        return m_array->IndexStringCount(to_str(value), m_target_column, m_get_func);
    }

    template <class T> void update_ref(T value, size_t old_row_ndx, size_t new_row_ndx)
    {
        do_update_ref(to_str(value), old_row_ndx, new_row_ndx, 0);
    }

    void clear() TIGHTDB_OVERRIDE;
    void distinct(Column& result) const;
    bool has_duplicate_values() const TIGHTDB_NOEXCEPT;

    /// By default, duplicate values are allowed.
    void set_allow_duplicate_values(bool) TIGHTDB_NOEXCEPT;

#ifdef TIGHTDB_DEBUG
    void Verify() const TIGHTDB_OVERRIDE;
    void verify_entries(const AdaptiveStringColumn& column) const;
    void do_dump_node_structure(std::ostream&, int) const TIGHTDB_OVERRIDE;
    void to_dot() const { to_dot(std::cerr); }
    void to_dot(std::ostream&, StringData title = StringData()) const;
#endif

    typedef int32_t key_type;

    static key_type create_key(StringData) TIGHTDB_NOEXCEPT;

private:
    void* m_target_column;
    StringGetter m_get_func;
    bool m_deny_duplicate_values;

    using Column::insert;
    using Column::erase;

    struct inner_node_tag {};
    StringIndex(inner_node_tag, Allocator&);

    static Array* create_node(Allocator&, bool is_leaf);

    void insert_with_offset(size_t row_ndx, StringData value, size_t offset);
    void InsertRowList(size_t ref, size_t offset, StringData value);
    key_type GetLastKey() const;

    /// Add small signed \a diff to all elements that are greater than, or equal
    /// to \a min_row_ndx.
    void adjust_row_indexes(size_t min_row_ndx, int diff);

    struct NodeChange {
        size_t ref1;
        size_t ref2;
        enum ChangeType { none, insert_before, insert_after, split } type;
        NodeChange(ChangeType t, size_t r1=0, size_t r2=0) : ref1(r1), ref2(r2), type(t) {}
        NodeChange() : ref1(0), ref2(0), type(none) {}
    };

    // B-Tree functions
    void TreeInsert(size_t row_ndx, key_type, size_t offset, StringData value);
    NodeChange DoInsert(size_t ndx, key_type, size_t offset, StringData value);
    /// Returns true if there is room or it can join existing entries
    bool LeafInsert(size_t row_ndx, key_type, size_t offset, StringData value, bool noextend=false);
    void NodeInsertSplit(size_t ndx, size_t new_ref);
    void NodeInsert(size_t ndx, size_t ref);
    void DoDelete(size_t ndx, StringData, size_t offset);
    void do_update_ref(StringData value, size_t row_ndx, size_t new_row_ndx, size_t offset);

    StringData get(size_t ndx, char* buffer) {return (*m_get_func)(m_target_column, ndx, buffer);}

    void NodeAddKey(ref_type ref);

#ifdef TIGHTDB_DEBUG
    static void dump_node_structure(const Array& node, std::ostream&, int level);
    void to_dot_2(std::ostream&, StringData title = StringData()) const;
    static void array_to_dot(std::ostream&, const Array&);
    static void keys_to_dot(std::ostream&, const Array&, StringData title = StringData());
#endif
};




// Implementation:

inline StringIndex::StringIndex(void* target_column, StringGetter get_func, Allocator& alloc):
    Column(create_node(alloc, true)), // Throws
    m_target_column(target_column),
    m_get_func(get_func),
    m_deny_duplicate_values(false)
{
}

inline StringIndex::StringIndex(ref_type ref, ArrayParent* parent, std::size_t ndx_in_parent,
                                void* target_column, StringGetter get_func,
                                bool deny_duplicate_values, Allocator& alloc):
    Column(alloc, ref),
    m_target_column(target_column),
    m_get_func(get_func),
    m_deny_duplicate_values(deny_duplicate_values)
{
    TIGHTDB_ASSERT(Array::get_context_flag_from_header(alloc.translate(ref)));
    set_parent(parent, ndx_in_parent);
}

inline StringIndex::StringIndex(inner_node_tag, Allocator& alloc):
    Column(create_node(alloc, false)), // Throws
    m_target_column(0),
    m_get_func(0),
    m_deny_duplicate_values(false)
{
}

inline void StringIndex::set_allow_duplicate_values(bool allow) TIGHTDB_NOEXCEPT
{
    m_deny_duplicate_values = !allow;
}

// Byte order of the key is *reversed*, so that for the integer index, the least significant
// byte comes first, so that it fits little-endian machines. That way we can perform fast 
// range-lookups and iterate in order, etc, as future features. This, however, makes the same
// features slower for string indexes. Todo, we should reverse the order conditionally, depending
// on the column type.
inline StringIndex::key_type StringIndex::create_key(StringData str) TIGHTDB_NOEXCEPT
{
    key_type key = 0;

    if (str.size() >= 4) goto four;
    if (str.size() < 2) {
        if (str.size() == 0) goto none;
        goto one;
    }
    if (str.size() == 2) goto two;
    goto three;

    // Create 4 byte index key
    // (encoded like this to allow literal comparisons
    // independently of endianness)
  four:
    key |= (key_type(static_cast<unsigned char>(str[3])) <<  0);
  three:
    key |= (key_type(static_cast<unsigned char>(str[2])) <<  8);
  two:
    key |= (key_type(static_cast<unsigned char>(str[1])) << 16);
  one:
    key |= (key_type(static_cast<unsigned char>(str[0])) << 24);
  none:
    return key;
}

template <class T> void StringIndex::insert(size_t row_ndx, T value, size_t num_rows, bool is_append)
{
    // If the new row is inserted after the last row in the table, we don't need
    // to adjust any row indexes.
    if (!is_append) {
        for (size_t i = 0; i < num_rows; ++i) {
            size_t row_ndx_2 = row_ndx + i;
            adjust_row_indexes(row_ndx_2, 1); // Throws
        }
    }

    for (size_t i = 0; i < num_rows; ++i) {
        size_t row_ndx_2 = row_ndx + i;
        size_t offset = 0; // First key from beginning of string
        insert_with_offset(row_ndx_2, to_str(value), offset); // Throws
    }
}

template <class T> void StringIndex::set(size_t row_ndx, T new_value)
{
    char buffer[sizeof(T)];
    T old_value = get(row_ndx, buffer);
    StringData new_value2 = to_str(new_value);

    // Note that insert_with_offset() throws UniqueConstraintViolation.

    if (TIGHTDB_LIKELY(new_value2 != old_value)) {
        size_t offset = 0; // First key from beginning of string
        insert_with_offset(row_ndx, new_value2, offset); // Throws

        bool is_last = true; // To avoid updating refs
        erase<T>(row_ndx, is_last); // Throws
    }
}

template <class T> void StringIndex::erase(size_t row_ndx, bool is_last)
{
    char buffer[sizeof(T)];
    T value = get(row_ndx, buffer);

    DoDelete(row_ndx, to_str(value), 0);

    // Collapse top nodes with single item
    while (!root_is_leaf()) {
        TIGHTDB_ASSERT(m_array->size() > 1); // node cannot be empty
        if (m_array->size() > 2)
            break;

        ref_type ref = m_array->get_as_ref(1);
        m_array->set(1, 1); // avoid destruction of the extracted ref
        m_array->destroy_deep();
        m_array->init_from_ref(ref);
        m_array->update_parent();
    }

    // If it is last item in column, we don't have to update refs
    if (!is_last)
        adjust_row_indexes(row_ndx, -1);
}

} //namespace tightdb

#endif // TIGHTDB_INDEX_STRING_HPP
