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
#ifndef TIGHTDB_UTIL_MEMORY_STREAM_HPP
#define TIGHTDB_UTIL_MEMORY_STREAM_HPP

#include <cstddef>
#include <string>
#include <istream>
#include <ostream>

#include <tightdb/util/features.h>

namespace tightdb {
namespace util {

class MemoryInputStreambuf: public std::streambuf {
public:
    MemoryInputStreambuf();
    ~MemoryInputStreambuf() TIGHTDB_NOEXCEPT;

    void set_buffer(const char *begin, const char *end) TIGHTDB_NOEXCEPT;

private:
    int_type underflow() TIGHTDB_OVERRIDE;
    int_type uflow() TIGHTDB_OVERRIDE;
    int_type pbackfail(int_type ch) TIGHTDB_OVERRIDE;
    std::streamsize showmanyc() TIGHTDB_OVERRIDE;

    const char* m_begin;
    const char* m_end;
    const char* m_curr;
};


class MemoryOutputStreambuf: public std::streambuf {
public:
    MemoryOutputStreambuf();
    ~MemoryOutputStreambuf() TIGHTDB_NOEXCEPT;

    void set_buffer(char* begin, char* end) TIGHTDB_NOEXCEPT;

    /// Returns the amount of data written to the buffer.
    std::size_t size() const TIGHTDB_NOEXCEPT;
};


class MemoryInputStream: public std::istream {
public:
    MemoryInputStream();
    ~MemoryInputStream() TIGHTDB_NOEXCEPT;

    void set_buffer(const char *begin, const char *end) TIGHTDB_NOEXCEPT;

    void set_string(const std::string&);

    void set_c_string(const char *c_str) TIGHTDB_NOEXCEPT;

private:
    MemoryInputStreambuf m_streambuf;
};


class MemoryOutputStream: public std::ostream {
public:
    MemoryOutputStream();
    ~MemoryOutputStream() TIGHTDB_NOEXCEPT;

    void set_buffer(char *begin, char *end) TIGHTDB_NOEXCEPT;

    template<std::size_t N> void set_buffer(char (&buffer)[N]) TIGHTDB_NOEXCEPT;

    /// Returns the amount of data written to the underlying buffer.
    std::size_t size() const TIGHTDB_NOEXCEPT;

private:
    MemoryOutputStreambuf m_streambuf;
};





// Implementation

inline MemoryInputStreambuf::MemoryInputStreambuf():
    m_begin(0),
    m_end(0),
    m_curr(0)
{
}

inline MemoryInputStreambuf::~MemoryInputStreambuf() TIGHTDB_NOEXCEPT
{
}

inline void MemoryInputStreambuf::set_buffer(const char *begin, const char *end) TIGHTDB_NOEXCEPT
{
    m_begin = begin;
    m_end   = end;
    m_curr  = begin;
}


inline MemoryOutputStreambuf::MemoryOutputStreambuf()
{
}

inline MemoryOutputStreambuf::~MemoryOutputStreambuf() TIGHTDB_NOEXCEPT
{
}

inline void MemoryOutputStreambuf::set_buffer(char* begin, char* end) TIGHTDB_NOEXCEPT
{
    setp(begin, end);
}

inline std::size_t MemoryOutputStreambuf::size() const TIGHTDB_NOEXCEPT
{
    return pptr() - pbase();
}


inline MemoryInputStream::MemoryInputStream():
    std::istream(&m_streambuf)
{
}

inline MemoryInputStream::~MemoryInputStream() TIGHTDB_NOEXCEPT
{
}

inline void MemoryInputStream::set_buffer(const char *begin, const char *end) TIGHTDB_NOEXCEPT
{
    m_streambuf.set_buffer(begin, end);
    clear();
}

inline void MemoryInputStream::set_string(const std::string& str)
{
    const char* begin = str.data();
    const char* end   = begin + str.size();
    set_buffer(begin, end);
}

inline void MemoryInputStream::set_c_string(const char *c_str) TIGHTDB_NOEXCEPT
{
    const char* begin = c_str;
    const char* end   = begin + traits_type::length(c_str);
    set_buffer(begin, end);
}


inline MemoryOutputStream::MemoryOutputStream():
    std::ostream(&m_streambuf)
{
}

inline MemoryOutputStream::~MemoryOutputStream() TIGHTDB_NOEXCEPT
{
}

inline void MemoryOutputStream::set_buffer(char *begin, char *end) TIGHTDB_NOEXCEPT
{
    m_streambuf.set_buffer(begin, end);
    clear();
}

template<std::size_t N>
inline void MemoryOutputStream::set_buffer(char (&buffer)[N]) TIGHTDB_NOEXCEPT
{
    set_buffer(buffer, buffer+N);
}

inline std::size_t MemoryOutputStream::size() const TIGHTDB_NOEXCEPT
{
    return m_streambuf.size();
}

} // namespace util
} // namespace tightdb

#endif // TIGHTDB_UTIL_MEMORY_STREAM_HPP
