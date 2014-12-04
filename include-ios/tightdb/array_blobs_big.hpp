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
#ifndef TIGHTDB_ARRAY_BIG_BLOBS_HPP
#define TIGHTDB_ARRAY_BIG_BLOBS_HPP

#include <tightdb/array_blob.hpp>

namespace tightdb {


class ArrayBigBlobs: public Array {
public:
    typedef BinaryData value_type;

    explicit ArrayBigBlobs(Allocator&) TIGHTDB_NOEXCEPT;

    BinaryData get(std::size_t ndx) const TIGHTDB_NOEXCEPT;
    void set(std::size_t ndx, BinaryData value, bool add_zero_term = false);
    void add(BinaryData value, bool add_zero_term = false);
    void insert(std::size_t ndx, BinaryData value, bool add_zero_term = false);
    void erase(std::size_t ndx);
    void truncate(std::size_t size);
    void clear();
    void destroy();

    std::size_t count(BinaryData value, bool is_string = false, std::size_t begin = 0,
                      std::size_t end = npos) const TIGHTDB_NOEXCEPT;
    std::size_t find_first(BinaryData value, bool is_string = false, std::size_t begin = 0,
                           std::size_t end = npos) const TIGHTDB_NOEXCEPT;
    void find_all(Column& result, BinaryData value, bool is_string = false,
                  std::size_t add_offset = 0,
                  std::size_t begin = 0, std::size_t end = npos);

    /// Get the specified element without the cost of constructing an
    /// array instance. If an array instance is already available, or
    /// you need to get multiple values, then this method will be
    /// slower.
    static BinaryData get(const char* header, std::size_t ndx, Allocator&) TIGHTDB_NOEXCEPT;

    ref_type bptree_leaf_insert(std::size_t ndx, BinaryData, bool add_zero_term,
                                TreeInsertBase& state);

    //@{
    /// Those that return a string, discard the terminating zero from
    /// the stored value. Those that accept a string argument, add a
    /// terminating zero before storing the value.
    StringData get_string(std::size_t ndx) const TIGHTDB_NOEXCEPT;
    void add_string(StringData value);
    void set_string(std::size_t ndx, StringData value);
    void insert_string(std::size_t ndx, StringData value);
    static StringData get_string(const char* header, std::size_t ndx, Allocator&) TIGHTDB_NOEXCEPT;
    ref_type bptree_leaf_insert_string(std::size_t ndx, StringData, TreeInsertBase& state);
    //@}

    /// Create a new empty big blobs array and attach this accessor to
    /// it. This does not modify the parent reference information of
    /// this accessor.
    ///
    /// Note that the caller assumes ownership of the allocated
    /// underlying node. It is not owned by the accessor.
    void create();

    /// Construct a copy of the specified slice of this big blobs
    /// array using the specified target allocator.
    MemRef slice(std::size_t offset, std::size_t size, Allocator& target_alloc) const;

#ifdef TIGHTDB_DEBUG
    void Verify() const;
    void to_dot(std::ostream&, bool is_strings, StringData title = StringData()) const;
#endif
};



// Implementation:

inline ArrayBigBlobs::ArrayBigBlobs(Allocator& alloc) TIGHTDB_NOEXCEPT:
    Array(alloc)
{
}

inline BinaryData ArrayBigBlobs::get(std::size_t ndx) const TIGHTDB_NOEXCEPT
{
    ref_type ref = get_as_ref(ndx);
    const char* blob_header = get_alloc().translate(ref);
    const char* value = ArrayBlob::get(blob_header, 0);
    size_t size = get_size_from_header(blob_header);
    return BinaryData(value, size);
}

inline BinaryData ArrayBigBlobs::get(const char* header, size_t ndx,
                                     Allocator& alloc) TIGHTDB_NOEXCEPT
{
    ref_type blob_ref = to_ref(Array::get(header, ndx));
    const char* blob_header = alloc.translate(blob_ref);
    const char* blob_data = Array::get_data_from_header(blob_header);
    size_t blob_size = Array::get_size_from_header(blob_header);
    return BinaryData(blob_data, blob_size);
}

inline void ArrayBigBlobs::erase(std::size_t ndx)
{
    ref_type blob_ref = Array::get_as_ref(ndx);
    Array::destroy(blob_ref, get_alloc()); // Shallow
    Array::erase(ndx);
}

inline void ArrayBigBlobs::truncate(std::size_t size)
{
    Array::truncate_and_destroy_children(size);
}

inline void ArrayBigBlobs::clear()
{
    Array::clear_and_destroy_children();
}

inline void ArrayBigBlobs::destroy()
{
    Array::destroy_deep();
}

inline StringData ArrayBigBlobs::get_string(std::size_t ndx) const TIGHTDB_NOEXCEPT
{
    BinaryData bin = get(ndx);
    return StringData(bin.data(), bin.size()-1); // Do not include terminating zero
}

inline void ArrayBigBlobs::set_string(std::size_t ndx, StringData value)
{
    BinaryData bin(value.data(), value.size());
    bool add_zero_term = true;
    set(ndx, bin, add_zero_term);
}

inline void ArrayBigBlobs::add_string(StringData value)
{
    BinaryData bin(value.data(), value.size());
    bool add_zero_term = true;
    add(bin, add_zero_term);
}

inline void ArrayBigBlobs::insert_string(std::size_t ndx, StringData value)
{
    BinaryData bin(value.data(), value.size());
    bool add_zero_term = true;
    insert(ndx, bin, add_zero_term);
}

inline StringData ArrayBigBlobs::get_string(const char* header, size_t ndx,
                                            Allocator& alloc) TIGHTDB_NOEXCEPT
{
    BinaryData bin = get(header, ndx, alloc);
    return StringData(bin.data(), bin.size()-1); // Do not include terminating zero
}

inline ref_type ArrayBigBlobs::bptree_leaf_insert_string(std::size_t ndx, StringData value,
                                                         TreeInsertBase& state)
{
    BinaryData bin(value.data(), value.size());
    bool add_zero_term = true;
    return bptree_leaf_insert(ndx, bin, add_zero_term, state);
}

inline void ArrayBigBlobs::create()
{
    bool context_flag = true;
    Array::create(type_HasRefs, context_flag); // Throws
}

inline MemRef ArrayBigBlobs::slice(std::size_t offset, std::size_t size,
                                   Allocator& target_alloc) const
{
    return slice_and_clone_children(offset, size, target_alloc);
}


} // namespace tightdb

#endif // TIGHTDB_ARRAY_BIG_BLOBS_HPP
