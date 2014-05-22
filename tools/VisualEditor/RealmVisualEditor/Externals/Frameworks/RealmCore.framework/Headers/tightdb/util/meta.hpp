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
#ifndef TIGHTDB_UTIL_META_HPP
#define TIGHTDB_UTIL_META_HPP

namespace tightdb {
namespace util {


/// A ternary operator that selects the first type if the condition
/// evaluates to true, otherwise it selects the second type.
template<bool cond, class A, class B> struct CondType   { typedef A type; };
template<class A, class B> struct CondType<false, A, B> { typedef B type; };

template<class A, class B> struct SameType { static bool const value = false; };
template<class A> struct SameType<A,A>     { static bool const value = true;  };

template<class T, class A, class B> struct EitherTypeIs { static const bool value = false; };
template<class T, class A> struct EitherTypeIs<T,T,A> { static const bool value = true; };
template<class T, class A> struct EitherTypeIs<T,A,T> { static const bool value = true; };
template<class T> struct EitherTypeIs<T,T,T> { static const bool value = true; };


} // namespace util
} // namespace tightdb

#endif // TIGHTDB_UTIL_META_HPP
