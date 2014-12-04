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
#ifndef TIGHTDB_ARRAY_STRING_HPP
#define TIGHTDB_ARRAY_STRING_HPP

#include <tightdb/array.hpp>

namespace tightdb {

class ArrayString: public Array {
public:
    typedef StringData value_type;

    explicit ArrayString(Allocator&) TIGHTDB_NOEXCEPT;
    explicit ArrayString(no_prealloc_tag) TIGHTDB_NOEXCEPT;
    ~ArrayString() TIGHTDB_NOEXCEPT TIGHTDB_OVERRIDE {}

    StringData get(std::size_t ndx) const TIGHTDB_NOEXCEPT;
    void add();
    void add(StringData value);
    void set(std::size_t ndx, StringData value);
    void insert(std::size_t ndx, StringData value);
    void erase(std::size_t ndx);

    std::size_t count(StringData value, std::size_t begin = 0,
                      std::size_t end = npos) const TIGHTDB_NOEXCEPT;
    std::size_t find_first(StringData value, std::size_t begin = 0,
                           std::size_t end = npos) const TIGHTDB_NOEXCEPT;
    void find_all(Column& result, StringData value, std::size_t add_offset = 0,
                  std::size_t begin = 0, std::size_t end = npos);

    /// Compare two string arrays for equality.
    bool compare_string(const ArrayString&) const TIGHTDB_NOEXCEPT;

    /// Get the specified element without the cost of constructing an
    /// array instance. If an array instance is already available, or
    /// you need to get multiple values, then this method will be
    /// slower.
    static StringData get(const char* header, std::size_t ndx) TIGHTDB_NOEXCEPT;

    ref_type bptree_leaf_insert(std::size_t ndx, StringData, TreeInsertBase& state);

    /// Construct a string array of the specified size and return just
    /// the reference to the underlying memory. All elements will be
    /// initialized to the empty string.
    static MemRef create_array(std::size_t size, Allocator&);

    /// Create a new empty string array and attach this accessor to
    /// it. This does not modify the parent reference information of
    /// this accessor.
    ///
    /// Note that the caller assumes ownership of the allocated
    /// underlying node. It is not owned by the accessor.
    void create();

    /// Construct a copy of the specified slice of this string array
    /// using the specified target allocator.
    MemRef slice(std::size_t offset, std::size_t size, Allocator& target_alloc) const;

#ifdef TIGHTDB_DEBUG
    void string_stats() const;
    void to_dot(std::ostream&, StringData title = StringData()) const;
#endif

private:
    std::size_t CalcByteLen(std::size_t count, std::size_t width) const TIGHTDB_OVERRIDE;
    std::size_t CalcItemCount(std::size_t bytes,
                              std::size_t width) const TIGHTDB_NOEXCEPT TIGHTDB_OVERRIDE;
    WidthType GetWidthType() const TIGHTDB_OVERRIDE { return wtype_Multiply; }
};



// Implementation:

// Creates new array (but invalid, call init_from_ref() to init)
inline ArrayString::ArrayString(Allocator& alloc) TIGHTDB_NOEXCEPT:
    Array(alloc)
{
}

// Fastest way to instantiate an Array. For use with GetDirect() that only fills out m_width, m_data
// and a few other basic things needed for read-only access. Or for use if you just want a way to call
// some methods written in ArrayString.*
inline ArrayString::ArrayString(no_prealloc_tag) TIGHTDB_NOEXCEPT:
    Array(*static_cast<Allocator*>(0))
{
}

inline void ArrayString::create()
{
    std::size_t size = 0;
    MemRef mem = create_array(size, get_alloc()); // Throws
    init_from_mem(mem);
}

inline MemRef ArrayString::create_array(std::size_t size, Allocator& alloc)
{
    bool context_flag = false;
    int_fast64_t value = 0;
    return Array::create(type_Normal, context_flag, wtype_Multiply, size, value, alloc); // Throws
}

inline StringData ArrayString::get(std::size_t ndx) const TIGHTDB_NOEXCEPT
{
    TIGHTDB_ASSERT(ndx < m_size);
    if (m_width == 0)
        return StringData("", 0);
    const char* data = m_data + (ndx * m_width);
    std::size_t size = (m_width-1) - data[m_width-1];
    return StringData(data, size);
}

inline void ArrayString::add(StringData value)
{
    insert(m_size, value); // Throws
}

inline void ArrayString::add()
{
    add(StringData()); // Throws
}

inline StringData ArrayString::get(const char* header, std::size_t ndx) TIGHTDB_NOEXCEPT
{
    TIGHTDB_ASSERT(ndx < get_size_from_header(header));
    std::size_t width = get_width_from_header(header);
    if (width == 0)
        return StringData("", 0);
    const char* data = get_data_from_header(header) + (ndx * width);
    std::size_t size = (width-1) - data[width-1];
    return StringData(data, size);
}


} // namespace tightdb

#endif // TIGHTDB_ARRAY_STRING_HPP
