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
#ifndef TIGHTDB_ARRAY_BASIC_TPL_HPP
#define TIGHTDB_ARRAY_BASIC_TPL_HPP

#include <algorithm>
#include <limits>
#include <stdexcept>
#include <iomanip>

#include <tightdb/impl/destroy_guard.hpp>

namespace tightdb {

template<class T>
inline BasicArray<T>::BasicArray(Allocator& alloc) TIGHTDB_NOEXCEPT:
    Array(alloc)
{
}

template<class T>
inline BasicArray<T>::BasicArray(no_prealloc_tag) TIGHTDB_NOEXCEPT:
    Array(no_prealloc_tag())
{
}


template<class T>
inline MemRef BasicArray<T>::create_array(std::size_t size, Allocator& alloc)
{
    std::size_t byte_size_0 = calc_aligned_byte_size(size); // Throws
    // Adding zero to Array::initial_capacity to avoid taking the
    // address of that member
    std::size_t byte_size = std::max(byte_size_0, Array::initial_capacity+0); // Throws

    MemRef mem = alloc.alloc(byte_size); // Throws

    bool is_inner_bptree_node = false;
    bool has_refs = false;
    bool context_flag = false;
    int width = sizeof (T);
    init_header(mem.m_addr, is_inner_bptree_node, has_refs, context_flag, wtype_Multiply,
                width, size, byte_size);

    return mem;
}


template<class T>
inline void BasicArray<T>::create()
{
    std::size_t size = 0;
    MemRef mem = create_array(size, get_alloc()); // Throws
    init_from_mem(mem);
}


template<class T>
MemRef BasicArray<T>::slice(std::size_t offset, std::size_t size, Allocator& target_alloc) const
{
    TIGHTDB_ASSERT(is_attached());

    // FIXME: This can be optimized as a single contiguous copy
    // operation.
    BasicArray slice(target_alloc);
    _impl::ShallowArrayDestroyGuard dg(&slice);
    slice.create(); // Throws
    size_t begin = offset;
    size_t end   = offset + size;
    for (size_t i = begin; i != end; ++i) {
        T value = get(i);
        slice.add(value); // Throws
    }
    dg.release();
    return slice.get_mem();
}


template<class T>
inline void BasicArray<T>::add(T value)
{
    insert(m_size, value);
}


template<class T> inline T BasicArray<T>::get(std::size_t ndx) const TIGHTDB_NOEXCEPT
{
    return *(reinterpret_cast<const T*>(m_data) + ndx);
}


template<class T>
inline T BasicArray<T>::get(const char* header, std::size_t ndx) TIGHTDB_NOEXCEPT
{
    const char* data = get_data_from_header(header);
    // FIXME: This casting assumes that T can be aliged on an 8-bype
    // boundary (since data is aligned on an 8-byte boundary.) This
    // restricts portability. The same problem recurs several times in
    // the remainder of this file.
    return *(reinterpret_cast<const T*>(data) + ndx);
}


template<class T>
inline void BasicArray<T>::set(std::size_t ndx, T value)
{
    TIGHTDB_ASSERT(ndx < m_size);

    // Check if we need to copy before modifying
    copy_on_write(); // Throws

    // Set the value
    T* data = reinterpret_cast<T*>(m_data) + ndx;
    *data = value;
}

template<class T>
void BasicArray<T>::insert(std::size_t ndx, T value)
{
    TIGHTDB_ASSERT(ndx <= m_size);

    // Check if we need to copy before modifying
    copy_on_write(); // Throws

    // Make room for the new value
    alloc(m_size+1, m_width); // Throws

    // Move values below insertion
    if (ndx != m_size) {
        char* base = reinterpret_cast<char*>(m_data);
        char* src_begin = base + ndx*m_width;
        char* src_end   = base + m_size*m_width;
        char* dst_end   = src_end + m_width;
        std::copy_backward(src_begin, src_end, dst_end);
    }

    // Set the value
    T* data = reinterpret_cast<T*>(m_data) + ndx;
    *data = value;

     ++m_size;
}

template<class T>
void BasicArray<T>::erase(std::size_t ndx)
{
    TIGHTDB_ASSERT(ndx < m_size);

    // Check if we need to copy before modifying
    copy_on_write(); // Throws

    // move data under deletion up
    if (ndx < m_size-1) {
        char* base = reinterpret_cast<char*>(m_data);
        char* dst_begin = base + ndx*m_width;
        const char* src_begin = dst_begin + m_width;
        const char* src_end   = base + m_size*m_width;
        std::copy(src_begin, src_end, dst_begin);
    }

    // Update size (also in header)
    --m_size;
    set_header_size(m_size);
}

template<class T> void BasicArray<T>::truncate(std::size_t size)
{
    TIGHTDB_ASSERT(is_attached());
    TIGHTDB_ASSERT(size <= m_size);

    copy_on_write(); // Throws

    // Update size in accessor and in header. This leaves the capacity
    // unchanged.
    m_size = size;
    set_header_size(size);
}

template<class T> inline void BasicArray<T>::clear()
{
    truncate(0); // Throws
}

template<class T>
bool BasicArray<T>::compare(const BasicArray<T>& a) const
{
    size_t n = size();
    if (a.size() != n)
        return false;
    const T* data_1 = reinterpret_cast<const T*>(m_data);
    const T* data_2 = reinterpret_cast<const T*>(a.m_data);
    return std::equal(data_1, data_1+n, data_2);
}


template<class T>
std::size_t BasicArray<T>::CalcByteLen(std::size_t size, std::size_t) const
{
    // FIXME: Consider calling `calc_aligned_byte_size(size)`
    // instead. Note however, that CalcByteLen() is supposed to return
    // the unaligned byte size. It is probably the case that no harm
    // is done by returning the aligned version, and most callers of
    // CalcByteLen() will actually benefit if CalcByteLen() was
    // changed to always return the aligned byte size.
    return header_size + size * sizeof (T); // FIXME: Prone to overflow
}

template<class T>
std::size_t BasicArray<T>::CalcItemCount(std::size_t bytes, std::size_t) const TIGHTDB_NOEXCEPT
{
    // FIXME: ??? what about width = 0? return -1?

    std::size_t bytes_without_header = bytes - header_size;
    return bytes_without_header / sizeof (T);
}

template<class T>
std::size_t BasicArray<T>::find(T value, std::size_t begin, std::size_t end) const
{
    if (end == npos)
        end = m_size;
    TIGHTDB_ASSERT(begin <= m_size && end <= m_size && begin <= end);
    const T* data = reinterpret_cast<const T*>(m_data);
    const T* i = std::find(data + begin, data + end, value);
    return i == data + end ? not_found : std::size_t(i - data);
}

template<class T>
inline std::size_t BasicArray<T>::find_first(T value, std::size_t begin, std::size_t end) const
{
    return this->find(value, begin, end);
}

template<class T>
void BasicArray<T>::find_all(Column* result, T value, std::size_t add_offset,
                             std::size_t begin, std::size_t end) const
{
    std::size_t first = begin - 1;
    for (;;) {
        first = this->find(value, first + 1, end);
        if (first == not_found)
            break;            

        Array::add_to_column(result, first + add_offset);
    }
}

template<class T>
std::size_t BasicArray<T>::count(T value, std::size_t begin, std::size_t end) const
{
    if (end == npos)
        end = m_size;
    TIGHTDB_ASSERT(begin <= m_size && end <= m_size && begin <= end);
    const T* data = reinterpret_cast<const T*>(m_data);
    return std::count(data + begin, data + end, value);
}

#if 0
// currently unused
template<class T>
double BasicArray<T>::sum(std::size_t begin, std::size_t end) const
{
    if (end == npos)
        end = m_size;
    TIGHTDB_ASSERT(begin <= m_size && end <= m_size && begin <= end);
    const T* data = reinterpret_cast<const T*>(m_data);
    return std::accumulate(data + begin, data + end, double(0));
}
#endif

template<class T> template<bool find_max>
bool BasicArray<T>::minmax(T& result, std::size_t begin, std::size_t end) const
{
    if (end == npos)
        end = m_size;
    if (m_size == 0)
        return false;
    TIGHTDB_ASSERT(begin < m_size && end <= m_size && begin < end);

    T m = get(begin);
    ++begin;
    for (; begin < end; ++begin) {
        T val = get(begin);
        if (find_max ? val > m : val < m)
            m = val;
    }
    result = m;
    return true;
}

template<class T>
bool BasicArray<T>::maximum(T& result, std::size_t begin, std::size_t end) const
{
    return minmax<true>(result, begin, end);
}

template<class T>
bool BasicArray<T>::minimum(T& result, std::size_t begin, std::size_t end) const
{
    return minmax<false>(result, begin, end);
}


template<class T>
ref_type BasicArray<T>::bptree_leaf_insert(size_t ndx, T value, TreeInsertBase& state)
{
    size_t leaf_size = size();
    TIGHTDB_ASSERT(leaf_size <= TIGHTDB_MAX_BPNODE_SIZE);
    if (leaf_size < ndx)
        ndx = leaf_size;
    if (TIGHTDB_LIKELY(leaf_size < TIGHTDB_MAX_BPNODE_SIZE)) {
        insert(ndx, value);
        return 0; // Leaf was not split
    }

    // Split leaf node
    BasicArray<T> new_leaf(get_alloc());
    new_leaf.create(); // Throws
    if (ndx == leaf_size) {
        new_leaf.add(value);
        state.m_split_offset = ndx;
    }
    else {
        // FIXME: Could be optimized by first resizing the target
        // array, then copy elements with std::copy().
        for (size_t i = ndx; i != leaf_size; ++i)
            new_leaf.add(get(i));
        truncate(ndx);
        add(value);
        state.m_split_offset = ndx + 1;
    }
    state.m_split_size = leaf_size + 1;
    return new_leaf.get_ref();
}

template<class T>
inline std::size_t BasicArray<T>::lower_bound(T value) const TIGHTDB_NOEXCEPT
{
    const T* begin = reinterpret_cast<const T*>(m_data);
    const T* end = begin + size();
    return std::lower_bound(begin, end, value) - begin;
}

template<class T>
inline std::size_t BasicArray<T>::upper_bound(T value) const TIGHTDB_NOEXCEPT
{
    const T* begin = reinterpret_cast<const T*>(m_data);
    const T* end = begin + size();
    return std::upper_bound(begin, end, value) - begin;
}

template<class T>
inline std::size_t BasicArray<T>::calc_aligned_byte_size(std::size_t size)
{
    std::size_t max = std::numeric_limits<std::size_t>::max();
    std::size_t max_2 = max & ~size_t(7); // Allow for upwards 8-byte alignment
    if (size > (max_2 - header_size) / sizeof (T))
        throw std::runtime_error("Byte size overflow");
    size_t byte_size = header_size + size * sizeof (T);
    TIGHTDB_ASSERT(byte_size > 0);
    size_t aligned_byte_size = ((byte_size-1) | 7) + 1; // 8-byte alignment
    return aligned_byte_size;
}


#ifdef TIGHTDB_DEBUG

template<class T>
void BasicArray<T>::to_dot(std::ostream& out, StringData title) const
{
    ref_type ref = get_ref();
    if (title.size() != 0) {
        out << "subgraph cluster_" << ref << " {\n";
        out << " label = \"" << title << "\";\n";
        out << " color = white;\n";
    }

    out << "n" << std::hex << ref << std::dec << "[shape=none,label=<";
    out << "<TABLE BORDER=\"0\" CELLBORDER=\"1\" CELLSPACING=\"0\" CELLPADDING=\"4\"><TR>\n";

    // Header
    out << "<TD BGCOLOR=\"lightgrey\"><FONT POINT-SIZE=\"7\"> ";
    out << "0x" << std::hex << ref << std::dec << "<BR/>";
    out << "</FONT></TD>\n";

    // Values
    std::size_t n = m_size;
    for (std::size_t i = 0; i != n; ++i)
        out << "<TD>" << get(i) << "</TD>\n";

    out << "</TR></TABLE>>];\n";

    if (title.size() != 0)
        out << "}\n";

    to_dot_parent_edge(out);
}

#endif // TIGHTDB_DEBUG


} // namespace tightdb

#endif // TIGHTDB_ARRAY_BASIC_TPL_HPP
