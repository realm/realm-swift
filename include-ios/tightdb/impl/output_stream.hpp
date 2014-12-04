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
#ifndef TIGHTDB_IMPL_OUTPUT_STREAM_HPP
#define TIGHTDB_IMPL_OUTPUT_STREAM_HPP

#include <cstddef>
#include <ostream>

#include <stdint.h>

#include <tightdb/util/features.h>

namespace tightdb {
namespace _impl {


class OutputStream {
public:
    OutputStream(std::ostream&);
    ~OutputStream() TIGHTDB_NOEXCEPT;

    size_t get_pos() const TIGHTDB_NOEXCEPT;

    void write(const char* data, size_t size);

    size_t write_array(const char* data, size_t size, uint_fast32_t checksum);

private:
    std::size_t m_pos;
    std::ostream& m_out;
};





// Implementation:

inline OutputStream::OutputStream(std::ostream& out):
    m_pos(0),
    m_out(out)
{
}

inline OutputStream::~OutputStream() TIGHTDB_NOEXCEPT
{
}

inline std::size_t OutputStream::get_pos() const TIGHTDB_NOEXCEPT
{
    return m_pos;
}


} // namespace _impl
} // namespace tightdb

#endif // TIGHTDB_IMPL_OUTPUT_STREAM_HPP
