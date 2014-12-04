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
#ifndef TIGHTDB_ARRAY_STRING_LONG_HPP
#define TIGHTDB_ARRAY_STRING_LONG_HPP

#include <tightdb/array_blob.hpp>

namespace tightdb {


class ArrayStringLong: public Array {
public:
    typedef StringData value_type;

    explicit ArrayStringLong(Allocator&) TIGHTDB_NOEXCEPT;
    ~ArrayStringLong() TIGHTDB_NOEXCEPT TIGHTDB_OVERRIDE {}

    /// Create a new empty long string array and attach this accessor to
    /// it. This does not modify the parent reference information of
    /// this accessor.
    ///
    /// Note that the caller assumes ownership of the allocated
    /// underlying node. It is not owned by the accessor.
    void create();

    //@{
    /// Overriding functions of Array
    void init_from_ref(ref_type) TIGHTDB_NOEXCEPT;
    void init_from_mem(MemRef) TIGHTDB_NOEXCEPT;
    void init_from_parent() TIGHTDB_NOEXCEPT;
    //@}

    bool is_empty() const TIGHTDB_NOEXCEPT;
    std::size_t size() const TIGHTDB_NOEXCEPT;

    StringData get(std::size_t ndx) const TIGHTDB_NOEXCEPT;

    void add(StringData value);
    void set(std::size_t ndx, StringData value);
    void insert(std::size_t ndx, StringData value);
    void erase(std::size_t ndx);
    void truncate(std::size_t size);
    void clear();
    void destroy();

    std::size_t count(StringData value, std::size_t begin = 0,
                      std::size_t end = npos) const TIGHTDB_NOEXCEPT;
    std::size_t find_first(StringData value, std::size_t begin = 0,
                           std::size_t end = npos) const TIGHTDB_NOEXCEPT;
    void find_all(Column &result, StringData value, std::size_t add_offset = 0,
                  std::size_t begin = 0, std::size_t end = npos) const;

    /// Get the specified element without the cost of constructing an
    /// array instance. If an array instance is already available, or
    /// you need to get multiple values, then this method will be
    /// slower.
    static StringData get(const char* header, std::size_t ndx, Allocator&) TIGHTDB_NOEXCEPT;

    ref_type bptree_leaf_insert(std::size_t ndx, StringData, TreeInsertBase&);

    static std::size_t get_size_from_header(const char*, Allocator&) TIGHTDB_NOEXCEPT;

    /// Construct a long string array of the specified size and return
    /// just the reference to the underlying memory. All elements will
    /// be initialized to zero size blobs.
    static MemRef create_array(std::size_t size, Allocator&);

    /// Construct a copy of the specified slice of this long string
    /// array using the specified target allocator.
    MemRef slice(std::size_t offset, std::size_t size, Allocator& target_alloc) const;

#ifdef TIGHTDB_DEBUG
    void to_dot(std::ostream&, StringData title = StringData()) const;
#endif

    bool update_from_parent(std::size_t old_baseline) TIGHTDB_NOEXCEPT;
private:
    Array m_offsets;
    ArrayBlob m_blob;
};




// Implementation:

inline ArrayStringLong::ArrayStringLong(Allocator& alloc) TIGHTDB_NOEXCEPT:
    Array(alloc), m_offsets(alloc), m_blob(alloc)
{
    m_offsets.set_parent(this, 0);
    m_blob.set_parent(this, 1);
}

inline void ArrayStringLong::create()
{
    std::size_t size = 0;
    MemRef mem = create_array(size, get_alloc()); // Throws
    init_from_mem(mem);
}

inline void ArrayStringLong::init_from_ref(ref_type ref) TIGHTDB_NOEXCEPT
{
    TIGHTDB_ASSERT(ref);
    char* header = get_alloc().translate(ref);
    init_from_mem(MemRef(header, ref));
}

inline void ArrayStringLong::init_from_parent() TIGHTDB_NOEXCEPT
{
    ref_type ref = get_ref_from_parent();
    init_from_ref(ref);
}

inline bool ArrayStringLong::is_empty() const TIGHTDB_NOEXCEPT
{
    return m_offsets.is_empty();
}

inline std::size_t ArrayStringLong::size() const TIGHTDB_NOEXCEPT
{
    return m_offsets.size();
}

inline StringData ArrayStringLong::get(std::size_t ndx) const TIGHTDB_NOEXCEPT
{
    TIGHTDB_ASSERT(ndx < m_offsets.size());
    std::size_t begin, end;
    if (0 < ndx) {
        // FIXME: Consider how much of a performance problem it is,
        // that we have to issue two separate calls to read two
        // consecutive values from an array.
        begin = to_size_t(m_offsets.get(ndx-1));
        end   = to_size_t(m_offsets.get(ndx));
    }
    else {
        begin = 0;
        end   = to_size_t(m_offsets.get(0));
    }
    --end; // Discount the terminating zero
    return StringData(m_blob.get(begin), end-begin);
}

inline void ArrayStringLong::truncate(std::size_t size)
{
    TIGHTDB_ASSERT(size < m_offsets.size());

    std::size_t blob_size = size ? to_size_t(m_offsets.get(size-1)) : 0;

    m_offsets.truncate(size);
    m_blob.truncate(blob_size);
}

inline void ArrayStringLong::clear()
{
    m_blob.clear();
    m_offsets.clear();
}

inline void ArrayStringLong::destroy()
{
    m_blob.destroy();
    m_offsets.destroy();
    Array::destroy();
}

inline bool ArrayStringLong::update_from_parent(size_t old_baseline) TIGHTDB_NOEXCEPT
{
    bool res = Array::update_from_parent(old_baseline);
    if (res) {
        m_blob.update_from_parent(old_baseline);
        m_offsets.update_from_parent(old_baseline);
    }
    return res;
}

inline std::size_t ArrayStringLong::get_size_from_header(const char* header,
                                                         Allocator& alloc) TIGHTDB_NOEXCEPT
{
    ref_type offsets_ref = to_ref(Array::get(header, 0));
    const char* offsets_header = alloc.translate(offsets_ref);
    return Array::get_size_from_header(offsets_header);
}


} // namespace tightdb

#endif // TIGHTDB_ARRAY_STRING_LONG_HPP
