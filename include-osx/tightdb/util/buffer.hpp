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
#ifndef TIGHTDB_UTIL_BUFFER_HPP
#define TIGHTDB_UTIL_BUFFER_HPP

#include <cstddef>
#include <algorithm>
#include <exception>
#include <limits>
#include <utility>

#include <tightdb/util/features.h>
#include <tightdb/util/safe_int_ops.hpp>
#include <tightdb/util/unique_ptr.hpp>

namespace tightdb {
namespace util {


/// A simple buffer concept that owns a region of memory and knows its
/// size.
template<class T> class Buffer {
public:
    Buffer() TIGHTDB_NOEXCEPT: m_data(0), m_size(0) {}
    Buffer(std::size_t size);
    ~Buffer() TIGHTDB_NOEXCEPT {}

    T& operator[](std::size_t i) TIGHTDB_NOEXCEPT { return m_data[i]; }
    const T& operator[](std::size_t i) const TIGHTDB_NOEXCEPT { return m_data[i]; }

    T* data() TIGHTDB_NOEXCEPT { return m_data.get(); }
    const T* data() const TIGHTDB_NOEXCEPT { return m_data.get(); }
    std::size_t size() const TIGHTDB_NOEXCEPT { return m_size; }

    /// Discards the original contents.
    void set_size(std::size_t new_size);

    /// \param copy_begin, copy_end Specifies a range of element
    /// values to be retained. \a copy_end must be less than, or equal
    /// to size().
    ///
    /// \param copy_to Specifies where the retained range should be
    /// copied to. `\a copy_to + \a copy_end - \a copy_begin` must be
    /// less than, or equal to \a new_size.
    void resize(std::size_t new_size, std::size_t copy_begin, std::size_t copy_end,
                std::size_t copy_to);

    void reserve(std::size_t used_size, std::size_t min_capacity);

    void reserve_extra(std::size_t used_size, std::size_t min_extra_capacity);

    T* release() TIGHTDB_NOEXCEPT;

    friend void swap(Buffer&a, Buffer&b) TIGHTDB_NOEXCEPT
    {
        using std::swap;
        swap(a.m_data, b.m_data);
        swap(a.m_size, b.m_size);
    }

private:
    UniquePtr<T[]> m_data;
    std::size_t m_size;
};


/// A buffer that can be efficiently resized. It acheives this by
/// using an underlying buffer that may be larger than the logical
/// size, and is automatically expanded in progressively larger steps.
template<class T> class AppendBuffer {
public:
    AppendBuffer() TIGHTDB_NOEXCEPT;
    ~AppendBuffer() TIGHTDB_NOEXCEPT {}

    /// Returns the current size of the buffer.
    std::size_t size() const TIGHTDB_NOEXCEPT;

    /// Gives read and write access to the elements.
    T* data() TIGHTDB_NOEXCEPT;

    /// Gives read access the elements.
    const T* data() const TIGHTDB_NOEXCEPT;

    /// Append the specified elements. This increases the size of this
    /// buffer by \a size. If the caller has previously requested a
    /// minimum capacity that is greater than, or equal to the
    /// resulting size, this function is guaranteed to not throw.
    void append(const T* data, std::size_t size);

    /// If the specified size is less than the current size, then the
    /// buffer contents is truncated accordingly. If the specified
    /// size is greater than the current size, then the extra elements
    /// will have undefined values. If the caller has previously
    /// requested a minimum capacity that is greater than, or equal to
    /// the specified size, this function is guaranteed to not throw.
    void resize(std::size_t size);

    /// This operation does not change the size of the buffer as
    /// returned by size(). If the specified capacity is less than the
    /// current capacity, this operation has no effect.
    void reserve(std::size_t min_capacity);

    /// Set the size to zero. The capacity remains unchanged.
    void clear() TIGHTDB_NOEXCEPT;

private:
    util::Buffer<char> m_buffer;
    std::size_t m_size;
};




// Implementation:

class BufferSizeOverflow: public std::exception {
public:
    const char* what() const TIGHTDB_NOEXCEPT_OR_NOTHROW TIGHTDB_OVERRIDE
    {
        return "Buffer size overflow";
    }
};

template<class T> inline Buffer<T>::Buffer(std::size_t size):
    m_data(new T[size]), // Throws
    m_size(size)
{
}

template<class T> inline void Buffer<T>::set_size(std::size_t new_size)
{
    m_data.reset(new T[new_size]); // Throws
    m_size = new_size;
}

template<class T> inline void Buffer<T>::resize(std::size_t new_size, std::size_t copy_begin,
                                                std::size_t copy_end, std::size_t copy_to)
{
    UniquePtr<T[]> new_data(new T[new_size]); // Throws
    std::copy(m_data.get() + copy_begin, m_data.get() + copy_end, new_data.get() + copy_to);
    m_data.reset(new_data.release());
    m_size = new_size;
}

template<class T> inline void Buffer<T>::reserve(std::size_t used_size,
                                                 std::size_t min_capacity)
{
    std::size_t current_capacity = m_size;
    if (TIGHTDB_LIKELY(current_capacity >= min_capacity))
        return;
    std::size_t new_capacity = current_capacity;
    if (TIGHTDB_UNLIKELY(int_multiply_with_overflow_detect(new_capacity, 2)))
        new_capacity = std::numeric_limits<std::size_t>::max();
    if (TIGHTDB_UNLIKELY(new_capacity < min_capacity))
        new_capacity = min_capacity;
    resize(new_capacity, 0, used_size, 0); // Throws
}

template<class T> inline void Buffer<T>::reserve_extra(std::size_t used_size,
                                                       std::size_t min_extra_capacity)
{
    std::size_t min_capacity = used_size;
    if (TIGHTDB_UNLIKELY(int_add_with_overflow_detect(min_capacity, min_extra_capacity)))
        throw BufferSizeOverflow();
    reserve(used_size, min_capacity); // Throws
}

template<class T> inline T* Buffer<T>::release() TIGHTDB_NOEXCEPT
{
    m_size = 0;
    return m_data.release();
}


template<class T> inline AppendBuffer<T>::AppendBuffer() TIGHTDB_NOEXCEPT: m_size(0)
{
}

template<class T> inline std::size_t AppendBuffer<T>::size() const TIGHTDB_NOEXCEPT
{
    return m_size;
}

template<class T> inline T* AppendBuffer<T>::data() TIGHTDB_NOEXCEPT
{
    return m_buffer.data();
}

template<class T> inline const T* AppendBuffer<T>::data() const TIGHTDB_NOEXCEPT
{
    return m_buffer.data();
}

template<class T> inline void AppendBuffer<T>::append(const T* data, std::size_t size)
{
    m_buffer.reserve_extra(m_size, size); // Throws
    std::copy(data, data+size, m_buffer.data()+m_size);
    m_size += size;
}

template<class T> inline void AppendBuffer<T>::reserve(std::size_t min_capacity)
{
    m_buffer.reserve(m_size, min_capacity);
}

template<class T> inline void AppendBuffer<T>::resize(std::size_t size)
{
    reserve(size);
    m_size = size;
}

template<class T> inline void AppendBuffer<T>::clear() TIGHTDB_NOEXCEPT
{
    m_size = 0;
}


} // namespace util
} // namespace tightdb

#endif // TIGHTDB_UTIL_BUFFER_HPP
