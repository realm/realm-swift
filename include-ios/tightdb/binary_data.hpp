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
#ifndef TIGHTDB_BINARY_DATA_HPP
#define TIGHTDB_BINARY_DATA_HPP

#include <cstddef>
#include <algorithm>
#include <string>
#include <ostream>

#include <tightdb/util/features.h>
#include <tightdb/utilities.hpp>

namespace tightdb {

/// A reference to a chunk of binary data.
///
/// This class does not own the referenced memory, nor does it in any
/// other way attempt to manage the lifetime of it.
///
/// \sa StringData
class BinaryData {
public:
    BinaryData() TIGHTDB_NOEXCEPT: m_data(0), m_size(0) {}
    BinaryData(const char* data, std::size_t size) TIGHTDB_NOEXCEPT: m_data(data), m_size(size) {}
    template<std::size_t N> explicit BinaryData(const char (&data)[N]): m_data(data), m_size(N) {}
    template<class T, class A> explicit BinaryData(const std::basic_string<char, T, A>&);

#if TIGHTDB_HAVE_CXX11_EXPLICIT_CONV_OPERATORS
    template<class T, class A> explicit operator std::basic_string<char, T, A>() const;
#endif

    ~BinaryData() TIGHTDB_NOEXCEPT {}

    char operator[](std::size_t i) const TIGHTDB_NOEXCEPT { return m_data[i]; }

    const char* data() const TIGHTDB_NOEXCEPT { return m_data; }
    std::size_t size() const TIGHTDB_NOEXCEPT { return m_size; }

    friend bool operator==(const BinaryData&, const BinaryData&) TIGHTDB_NOEXCEPT;
    friend bool operator!=(const BinaryData&, const BinaryData&) TIGHTDB_NOEXCEPT;

    //@{
    /// Trivial bytewise lexicographical comparison.
    friend bool operator<(const BinaryData&, const BinaryData&) TIGHTDB_NOEXCEPT;
    friend bool operator>(const BinaryData&, const BinaryData&) TIGHTDB_NOEXCEPT;
    friend bool operator<=(const BinaryData&, const BinaryData&) TIGHTDB_NOEXCEPT;
    friend bool operator>=(const BinaryData&, const BinaryData&) TIGHTDB_NOEXCEPT;
    //@}

    bool begins_with(BinaryData) const TIGHTDB_NOEXCEPT;
    bool ends_with(BinaryData) const TIGHTDB_NOEXCEPT;
    bool contains(BinaryData) const TIGHTDB_NOEXCEPT;

    template<class C, class T>
    friend std::basic_ostream<C,T>& operator<<(std::basic_ostream<C,T>&, const BinaryData&);

private:
    const char* m_data;
    std::size_t m_size;
};



// Implementation:

template<class T, class A> inline BinaryData::BinaryData(const std::basic_string<char, T, A>& s):
    m_data(s.data()),
    m_size(s.size())
{
}

#if TIGHTDB_HAVE_CXX11_EXPLICIT_CONV_OPERATORS

template<class T, class A> inline BinaryData::operator std::basic_string<char, T, A>() const
{
    return std::basic_string<char, T, A>(m_data, m_size);
}

#endif

inline bool operator==(const BinaryData& a, const BinaryData& b) TIGHTDB_NOEXCEPT
{
    return a.m_size == b.m_size && safe_equal(a.m_data, a.m_data + a.m_size, b.m_data);
}

inline bool operator!=(const BinaryData& a, const BinaryData& b) TIGHTDB_NOEXCEPT
{
    return !(a == b);
}

inline bool operator<(const BinaryData& a, const BinaryData& b) TIGHTDB_NOEXCEPT
{
    return std::lexicographical_compare(a.m_data, a.m_data + a.m_size,
                                        b.m_data, b.m_data + b.m_size);
}

inline bool operator>(const BinaryData& a, const BinaryData& b) TIGHTDB_NOEXCEPT
{
    return b < a;
}

inline bool operator<=(const BinaryData& a, const BinaryData& b) TIGHTDB_NOEXCEPT
{
    return !(b < a);
}

inline bool operator>=(const BinaryData& a, const BinaryData& b) TIGHTDB_NOEXCEPT
{
    return !(a < b);
}

inline bool BinaryData::begins_with(BinaryData d) const TIGHTDB_NOEXCEPT
{
    return d.m_size <= m_size && safe_equal(m_data, m_data + d.m_size, d.m_data);
}

inline bool BinaryData::ends_with(BinaryData d) const TIGHTDB_NOEXCEPT
{
    return d.m_size <= m_size && safe_equal(m_data + m_size - d.m_size, m_data + m_size, d.m_data);
}

inline bool BinaryData::contains(BinaryData d) const TIGHTDB_NOEXCEPT
{
    return d.m_size == 0 ||
        std::search(m_data, m_data + m_size, d.m_data, d.m_data + d.m_size) != m_data + m_size;
}

template<class C, class T>
inline std::basic_ostream<C,T>& operator<<(std::basic_ostream<C,T>& out, const BinaryData& d)
{
    out << "BinaryData("<<static_cast<const void*>(d.m_data)<<", "<<d.m_size<<")";
    return out;
}

} // namespace tightdb

#endif // TIGHTDB_BINARY_DATA_HPP
