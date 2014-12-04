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
#ifndef TIGHTDB_STRING_HPP
#define TIGHTDB_STRING_HPP

#include <cstddef>
#include <algorithm>
#include <string>
#include <ostream>

#include <tightdb/util/features.h>
#include <tightdb/utilities.hpp>

namespace tightdb {

/// A reference to a chunk of character data.
///
/// An instance of this class can be thought of as a type tag on a
/// region of memory. It does not own the referenced memory, nor does
/// it in any other way attempt to manage the lifetime of it.
///
/// A null character inside the referenced region is considered a part
/// of the string by TightDB.
///
/// For compatibility with C-style strings, when a string is stored in
/// a TightDB database, it is always followed by a terminating null
/// character, regardless of whether the string itself has internal
/// null characters. This means that when a StringData object is
/// extracted from TightDB, the referenced region is guaranteed to be
/// followed immediately by an extra null character, but that null
/// character is not inside the referenced region. Therefore, all of
/// the following forms are guaranteed to return a pointer to a
/// null-terminated string:
///
/// \code{.cpp}
///
///   group.get_table_name(...).data()
///   table.get_column_name().data()
///   table.get_string(...).data()
///   table.get_mixed(...).get_string().data()
///
/// \endcode
///
/// Note that in general, no assumptions can be made about what follows a string
/// that is referenced by a StringData object, or whether anything follows it at
/// all. In particular, the receiver of a StringData object cannot assume that
/// the referenced string is followed by a null character unless there is an
/// externally provided guarantee.
///
/// This class makes it possible to distinguish between a 'null'
/// reference and a reference to the empty string (see
/// is_null()). However, most functions of the TightDB API do not care
/// about this distinction. In particular, the comparison operators of
/// this class make no distinction between a null reference and a
/// reference to the empty string. This is possible because in both
/// cases, size() returns zero.
///
/// \sa BinaryData
/// \sa Mixed
class StringData {
public:
    /// Construct a null reference.
    StringData() TIGHTDB_NOEXCEPT;

    /// If \a data is 'null', \a size must be zero.
    StringData(const char* data, std::size_t size) TIGHTDB_NOEXCEPT;

    template<class T, class A> StringData(const std::basic_string<char, T, A>&);
    template<class T, class A> operator std::basic_string<char, T, A>() const;

    /// Initialize from a zero terminated C style string. Pass null to
    /// construct a null reference.
    StringData(const char* c_str) TIGHTDB_NOEXCEPT;

    ~StringData() TIGHTDB_NOEXCEPT;

    char operator[](std::size_t i) const TIGHTDB_NOEXCEPT;

    const char* data() const TIGHTDB_NOEXCEPT;
    std::size_t size() const TIGHTDB_NOEXCEPT;

    /// Is this a null reference?
    ///
    /// An instance of StringData is a null reference when, and only
    /// when the stored size is zero (size()) and the stored pointer
    /// is the null pointer (data()).
    ///
    /// In the case of the empty string, the stored size is still
    /// zero, but the stored pointer is **not** the null pointer. It
    /// could for example point to the empty string literal. Note that
    /// the actual value of the pointer is immaterial in this case (as
    /// long as it is not zero), because when the size is zero, it is
    /// an error to dereference the pointer.
    ///
    /// Conversion of a StringData object to `bool` yields the logical
    /// negation of the result of calling this function. In other
    /// words, a StringData is converted to true if it is not the null
    /// reference, otherwise it is converted to false.
    ///
    /// It is important to understand that all of the functions and
    /// operator in this class, and most of the functions in the
    /// TightDB API in general makes no distinction between a null
    /// reference and a reference to the empty string. These functions
    /// and operators never look at the stored pointer if the stored
    /// size is zero.
    bool is_null() const TIGHTDB_NOEXCEPT;

    friend bool operator==(const StringData&, const StringData&) TIGHTDB_NOEXCEPT;
    friend bool operator!=(const StringData&, const StringData&) TIGHTDB_NOEXCEPT;

    //@{
    /// Trivial bytewise lexicographical comparison.
    friend bool operator<(const StringData&, const StringData&) TIGHTDB_NOEXCEPT;
    friend bool operator>(const StringData&, const StringData&) TIGHTDB_NOEXCEPT;
    friend bool operator<=(const StringData&, const StringData&) TIGHTDB_NOEXCEPT;
    friend bool operator>=(const StringData&, const StringData&) TIGHTDB_NOEXCEPT;
    //@}

    bool begins_with(StringData) const TIGHTDB_NOEXCEPT;
    bool ends_with(StringData) const TIGHTDB_NOEXCEPT;
    bool contains(StringData) const TIGHTDB_NOEXCEPT;

    //@{
    /// Undefined behavior if \a n, \a i, or <tt>i+n</tt> is greater
    /// than size().
    StringData prefix(std::size_t n) const TIGHTDB_NOEXCEPT;
    StringData suffix(std::size_t n) const TIGHTDB_NOEXCEPT;
    StringData substr(std::size_t i, std::size_t n) const TIGHTDB_NOEXCEPT;
    StringData substr(std::size_t i) const TIGHTDB_NOEXCEPT;
    //@}

    template<class C, class T>
    friend std::basic_ostream<C,T>& operator<<(std::basic_ostream<C,T>&, const StringData&);

#ifdef TIGHTDB_HAVE_CXX11_EXPLICIT_CONV_OPERATORS
    explicit operator bool() const TIGHTDB_NOEXCEPT;
#else
    typedef const char* StringData::*unspecified_bool_type;
    operator unspecified_bool_type() const TIGHTDB_NOEXCEPT;
#endif

private:
    const char* m_data;
    std::size_t m_size;
};



// Implementation:

inline StringData::StringData() TIGHTDB_NOEXCEPT:
    m_data(0),
    m_size(0)
{
}

inline StringData::StringData(const char* data, std::size_t size) TIGHTDB_NOEXCEPT:
    m_data(data),
    m_size(size)
{
    TIGHTDB_ASSERT(data || size == 0);
}

template<class T, class A> inline StringData::StringData(const std::basic_string<char, T, A>& s):
    m_data(s.data()),
    m_size(s.size())
{
}

template<class T, class A> inline StringData::operator std::basic_string<char, T, A>() const
{
    return std::basic_string<char, T, A>(m_data, m_size);
}

inline StringData::StringData(const char* c_str) TIGHTDB_NOEXCEPT:
    m_data(c_str),
    m_size(0)
{
    if (c_str)
        m_size = std::char_traits<char>::length(c_str);
}

inline StringData::~StringData() TIGHTDB_NOEXCEPT
{
}

inline char StringData::operator[](std::size_t i) const TIGHTDB_NOEXCEPT
{
    return m_data[i];
}

inline const char* StringData::data() const TIGHTDB_NOEXCEPT
{
    return m_data;
}

inline std::size_t StringData::size() const TIGHTDB_NOEXCEPT
{
    return m_size;
}

inline bool StringData::is_null() const TIGHTDB_NOEXCEPT
{
    return !m_data;
}

inline bool operator==(const StringData& a, const StringData& b) TIGHTDB_NOEXCEPT
{
    return a.m_size == b.m_size && safe_equal(a.m_data, a.m_data + a.m_size, b.m_data);
}

inline bool operator!=(const StringData& a, const StringData& b) TIGHTDB_NOEXCEPT
{
    return !(a == b);
}

inline bool operator<(const StringData& a, const StringData& b) TIGHTDB_NOEXCEPT
{
    return std::lexicographical_compare(a.m_data, a.m_data + a.m_size,
                                        b.m_data, b.m_data + b.m_size);
}

inline bool operator>(const StringData& a, const StringData& b) TIGHTDB_NOEXCEPT
{
    return b < a;
}

inline bool operator<=(const StringData& a, const StringData& b) TIGHTDB_NOEXCEPT
{
    return !(b < a);
}

inline bool operator>=(const StringData& a, const StringData& b) TIGHTDB_NOEXCEPT
{
    return !(a < b);
}

inline bool StringData::begins_with(StringData d) const TIGHTDB_NOEXCEPT
{
    return d.m_size <= m_size && safe_equal(m_data, m_data + d.m_size, d.m_data);
}

inline bool StringData::ends_with(StringData d) const TIGHTDB_NOEXCEPT
{
    return d.m_size <= m_size && safe_equal(m_data + m_size - d.m_size, m_data + m_size, d.m_data);
}

inline bool StringData::contains(StringData d) const TIGHTDB_NOEXCEPT
{
    return d.m_size == 0 ||
        std::search(m_data, m_data + m_size, d.m_data, d.m_data + d.m_size) != m_data + m_size;
}

inline StringData StringData::prefix(std::size_t n) const TIGHTDB_NOEXCEPT
{
    return substr(0,n);
}

inline StringData StringData::suffix(std::size_t n) const TIGHTDB_NOEXCEPT
{
    return substr(m_size - n);
}

inline StringData StringData::substr(std::size_t i, std::size_t n) const TIGHTDB_NOEXCEPT
{
    return StringData(m_data + i, n);
}

inline StringData StringData::substr(std::size_t i) const TIGHTDB_NOEXCEPT
{
    return substr(i, m_size - i);
}

template<class C, class T>
inline std::basic_ostream<C,T>& operator<<(std::basic_ostream<C,T>& out, const StringData& d)
{
    for (const char* i = d.m_data; i != d.m_data + d.m_size; ++i)
        out << *i;
    return out;
}

#ifdef TIGHTDB_HAVE_CXX11_EXPLICIT_CONV_OPERATORS
inline StringData::operator bool() const TIGHTDB_NOEXCEPT
{
    return !is_null();
}
#else
inline StringData::operator unspecified_bool_type() const TIGHTDB_NOEXCEPT
{
    return is_null() ? 0 : &StringData::m_data;
}
#endif

} // namespace tightdb

#endif // TIGHTDB_STRING_HPP
