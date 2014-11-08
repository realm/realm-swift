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
#ifndef TIGHTDB_UTIL_TERMINATE_HPP
#define TIGHTDB_UTIL_TERMINATE_HPP

#include <cstdlib>
#include <string>

#include <tightdb/util/features.h>

#ifdef TIGHTDB_DEBUG
#  define TIGHTDB_TERMINATE(msg) tightdb::util::terminate((msg), __FILE__, __LINE__)
#else
#  define TIGHTDB_TERMINATE(msg) (static_cast<void>(msg), std::abort())
#endif

namespace tightdb {
namespace util {


TIGHTDB_NORETURN void terminate(std::string message, const char* file, long line) TIGHTDB_NOEXCEPT;


} // namespace util
} // namespace tightdb

#endif // TIGHTDB_UTIL_TERMINATE_HPP
