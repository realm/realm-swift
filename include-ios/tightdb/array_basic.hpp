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
#ifndef TIGHTDB_ARRAY_BASIC_HPP
#define TIGHTDB_ARRAY_BASIC_HPP

#include <tightdb/array.hpp>

namespace tightdb {

/// A BasicArray can currently only be used for simple unstructured
/// types like float, double.
template<class T> class BasicArray: public Array {
public:
    explicit BasicArray(Allocator&) TIGHTDB_NOEXCEPT;
    explicit BasicArray(no_prealloc_tag) TIGHTDB_NOEXCEPT;
    ~BasicArray() TIGHTDB_NOEXCEPT TIGHTDB_OVERRIDE {}

    T get(std::size_t ndx) const TIGHTDB_NOEXCEPT;
    void add(T value);
    void set(std::size_t ndx, T value);
    void insert(std::size_t ndx, T value);
    void erase(std::size_t ndx);
    void truncate(std::size_t size);
    void clear();

    std::size_t find_first(T value, std::size_t begin = 0 , std::size_t end = npos) const;
    void find_all(Column* result, T value, std::size_t add_offset = 0,
                  std::size_t begin = 0, std::size_t end = npos) const;

    std::size_t count(T value, std::size_t begin = 0, std::size_t end = npos) const;
    bool maximum(T& result, std::size_t begin = 0, std::size_t end = npos) const;
    bool minimum(T& result, std::size_t begin = 0, std::size_t end = npos) const;

    /// Compare two arrays for equality.
    bool compare(const BasicArray<T>&) const;

    /// Get the specified element without the cost of constructing an
    /// array instance. If an array instance is already available, or
    /// you need to get multiple values, then this method will be
    /// slower.
    static T get(const char* header, std::size_t ndx) TIGHTDB_NOEXCEPT;

    ref_type bptree_leaf_insert(std::size_t ndx, T, TreeInsertBase& state);

    std::size_t lower_bound(T value) const TIGHTDB_NOEXCEPT;
    std::size_t upper_bound(T value) const TIGHTDB_NOEXCEPT;

    /// Construct a basic array of the specified size and return just
    /// the reference to the underlying memory. All elements will be
    /// initialized to `T()`.
    static MemRef create_array(std::size_t size, Allocator&);

    /// Create a new empty array and attach this accessor to it. This
    /// does not modify the parent reference information of this
    /// accessor.
    ///
    /// Note that the caller assumes ownership of the allocated
    /// underlying node. It is not owned by the accessor.
    void create();

    /// Construct a copy of the specified slice of this basic array
    /// using the specified target allocator.
    MemRef slice(std::size_t offset, std::size_t size, Allocator& target_alloc) const;

#ifdef TIGHTDB_DEBUG
    void to_dot(std::ostream&, StringData title = StringData()) const;
#endif

private:
    std::size_t find(T target, std::size_t begin, std::size_t end) const;

    virtual std::size_t CalcByteLen(std::size_t count, std::size_t width) const;
    virtual std::size_t CalcItemCount(std::size_t bytes, std::size_t width) const TIGHTDB_NOEXCEPT;
    virtual WidthType GetWidthType() const { return wtype_Multiply; }

    template<bool find_max> bool minmax(T& result, std::size_t begin, std::size_t end) const;

    /// Calculate the total number of bytes needed for a basic array
    /// with the specified number of elements. This includes the size
    /// of the header. The result will be upwards aligned to the
    /// closest 8-byte boundary.
    static std::size_t calc_aligned_byte_size(std::size_t size);
};


// Class typedefs for BasicArray's: ArrayFloat and ArrayDouble
typedef BasicArray<float> ArrayFloat;
typedef BasicArray<double> ArrayDouble;

} // namespace tightdb

#include <tightdb/array_basic_tpl.hpp>

#endif // TIGHTDB_ARRAY_BASIC_HPP
